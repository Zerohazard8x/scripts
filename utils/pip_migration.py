#!/usr/bin/env python3
"""Migrate packages from older registered Python installations to the newest stable Python 3."""
import argparse
import hashlib

# Encode and decode JSON for interpreter inventories, metadata, and reports.
import json

# Access operating-system information and create hard links.
import os
import platform
import re

# Filesystem utilities, including copying files and locating executables.
import shutil

# Execute external programs, including Python
import subprocess
import sys
import tempfile

# Read and create wheel archives, which use the ZIP file format.
import zipfile

from pathlib import Path

# Packages excluded from migration.
# These packages are closely associated with Python's packaging environment.
# Reinstalling or copying versions from older interpreters could interfere
# with the destination interpreter's existing packaging tools.
EXCLUDED = {'pip', 'setuptools', 'wheel', 'distribute'}

# Python program executed inside each discovered interpreter.
INFO_SCRIPT = r"""
import importlib.metadata as md, json, sys

# Collect information about every distribution visible to this interpreter.
items = []

for d in md.distributions():
    try:
        # Distribution names are taken from installed package metadata.
        # An empty or missing name is not useful for migration.
        name = d.metadata.get('Name', '').strip()
        if not name:
            continue
        
        # Convert distribution file paths to strings with forward slashes.
        files = [str(f).replace('\\', '/') for f in d.files or []]
        
        # Locate the installed .dist-info directory from the file manifest.
        # The directory contains package metadata used during wheel creation.
        #
        # next(..., None) returns the first matching item, or None if the generator produces no matching item.
        info = next((x.split('/')[0] for x in files if x.split('/')[0].endswith('.dist-info')), None)
        
        # Empty-string fallbacks avoid propagating None into later parsing.
        wheel = d.read_text('WHEEL') or ''
        direct = d.read_text('direct_url.json') or ''
        tops = (d.read_text('top_level.txt') or '').splitlines()
        items.append({'name': name, 'version': d.version, 'files': files, 'distinfo': info, 'wheel': wheel, 'direct_url': direct, 'tops': tops, 'root': str(d.locate_file(''))})
    except Exception:
        pass
print(json.dumps({'version': list(sys.version_info[:3]), 'prerelease': sys.version_info.releaselevel != 'final', 'executable': sys.executable, 'prefix': sys.prefix, 'base_prefix': sys.base_prefix, 'implementation': sys.implementation.name, 'packages': items}))
"""

def run(cmd, *, timeout=300, quiet=False):
    try:
        p = subprocess.run([str(x) for x in cmd], text=True, encoding='utf-8', errors='replace', capture_output=True, timeout=timeout, stdin=subprocess.DEVNULL)
    
    # Prevent a stalled external command from blocking indefinitely.
    # Prevent child programs from waiting for interactive input.
    # OSError covers failures such as a missing executable.
    # TimeoutExpired covers commands exceeding the specified time limit.
    except (OSError, subprocess.TimeoutExpired) as exc:
        return (999, str(exc))
    
    msg = '\n'.join((x for x in (p.stdout.strip(), p.stderr.strip()) if x))
    if msg and (not quiet):
        # Show only the final 3,000 characters to avoid flooding the terminal with long pip output.
        print(msg[-3000:])
    
    return (p.returncode, msg)

def norm(name):
    # Example: My_Package.Name becomes my-package-name.
    return re.sub('[-_.]+', '-', name).lower()

def discover():
    # Ask for registered interpreter paths
    code, output = run(['py', '-0p'], quiet=True)

    # stop rather than guessing which installations exist
    if code:
        raise RuntimeError('Could not list Python versions using py -0p: ' + output)
    
    paths = []

    pat = re.compile('^\\s*-(?:V:)?\\S+\\s+\\*?\\s*(.+?python(?:w)?\\.exe)\\s*$', re.I)

    # Support multiple launcher output formats.
    for line in output.splitlines():
        match = pat.search(line)

        # Check that the extracted path points to an existing file.
        if match and Path(match.group(1).strip('"')).is_file():
            exe = str(Path(match.group(1).strip('"')).resolve())

            # Avoid listing the same executable more than once.
            if exe.lower() not in [p.lower() for p in paths]:
                paths.append(exe)

    # Without a verified executable path, there is no safe target or source interpreter to inspect.
    if not paths:
        raise RuntimeError('No executable paths found in py -0p output:\n' + output)
    
    result = []

    for exe in paths:
        # Run the inventory program with this particular interpreter.
        code, output = run([exe, '-c', INFO_SCRIPT], timeout=120, quiet=True)

        # Skip installations that cannot execute the inventory program.
        # Other interpreters can still be processed.
        if code:
            print('SKIP: cannot inspect', exe, output[-300:])
            continue

        try:
            details = json.loads(output)
        except ValueError:
            print('SKIP: unexpected Python inventory output from', exe)
            continue

        # Use the launcher-discovered executable path as the authoritative
        # path for subsequent subprocess calls.
        details['executable'] = exe
        result.append(details)

    return result

def cache_wheels(interpreters, wheelhouse, *, dry_run=False):
    count = 0
    seen = set()

    for runtime in interpreters:
        code, output = run([runtime['executable'], '-m', 'pip', 'cache', 'dir'], quiet=True)

        # Failure to inspect one cache should not stop migration.
        if code:
            continue

        # pip cache dir normally prints the directory path.
        cachedir = Path(output.splitlines()[-1].strip())

        # Search recursively for wheel archives in pip's wheel cache.
        for original in cachedir.glob('wheels/**/*.whl'):
            # Treat identical wheel filenames as duplicates.
            # This avoids repeatedly collecting the same named archive.
            if original.name.lower() in seen:
                continue

            seen.add(original.name.lower())
            count += 1
            if not dry_run:
                dest = wheelhouse / original.name
                if dest.exists():
                    continue
                try:
                    # It works only where the filesystem permits the link.
                    os.link(original, dest)

                except OSError:
                    # Copy when hard linking is unsupported or fails.
                    shutil.copy2(original, dest)

    return count

def isDistRepackable(pkg):
    tag = next((line[5:].strip() for line in pkg['wheel'].splitlines() if line.startswith('Tag: ')), None)
    
    # Reconstructing a wheel requires both its metadata directory name and an installed file manifest.
    if not pkg['distinfo'] or not pkg['files']:
        return (False, 'missing installed file manifest', tag)
    
    root = Path(pkg['root']).resolve()
    
    for item in pkg['files']:
        p = Path(item)
        
        if p.is_absolute() or any((part == '..' for part in p.parts)):
            return (False, 'files outside site-packages', tag)
        if '.data/' in item or item.endswith(('.pyd', '.dll', '.so', '.dylib', '.exe', '.pth')):
            return (False, 'binary, .pth, or nonstandard installation layout', tag)
        
        # Resolve the complete path, including filesystem links.
        # Checking the resolved result protects against a path that appears
        # to be inside the root but actually resolves outside it.
        resolved = (root / item).resolve()

        # A file is acceptable only when it is the root itself or lies
        # beneath that root.
        if root not in resolved.parents and root != resolved:
            return (False, 'files outside site-packages', tag)
    
    return (True, 'true wheel', tag)

def repackage(pkg, wheelhouse):
    # Check eligibility before writing anything to the wheel directory.
    good, reason, tag = isDistRepackable(pkg)
    if not good:
        return (None, reason)
    inf = pkg['distinfo']

    # Remove the .dist-info suffix to obtain the distribution/version stem.
    stem = inf[:-len('.dist-info')]
    
    # An ordinary dist-info directory name contains a distribution name
    # and version separated by a hyphen.
    if '-' not in stem:
        return (None, 'unusual dist-info directory name')
    
    # Construct the output wheel filename.
    # The universal tag is used only after the original installed wheel
    # metadata has passed the compatibility check.
    filename = stem + '-' + tag + '.whl'
    output = wheelhouse / filename

    # Reuse an existing local archive rather than rebuilding it.
    if output.exists():
        return (output, 'reused locally reconstructed wheel')
    root = Path(pkg['root'])
    
    try:
        with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=5) as z:
            for rel in pkg['files']:
                rel = rel.replace('\\', '/')
                if rel.endswith('/RECORD') or rel.endswith('/WHEEL') or rel.endswith('.pyc') or ('/__pycache__/' in rel):
                    continue

                src = root / rel

                # Only existing regular files are included.
                # Missing manifest entries are silently skipped.
                if src.is_file():
                    z.write(src, rel)
           
            z.writestr(inf + '/WHEEL', f'Wheel-Version: 1.0\nGenerator: local-migration\nRoot-Is-Purelib: true\nTag: {tag}\n')
            
            # pip is expected to generate a new installed RECORD.
            z.writestr(inf + '/RECORD', '')
        
        return (output, 'reconstructed from installed pure-Python files')
    
    except Exception as exc:
        # Remove a potentially incomplete archive so it cannot be mistaken for a successfully reconstructed wheel.
        # missing_ok=True avoids another exception if the file was never created or has already disappeared.
        output.unlink(missing_ok=True)
        return (None, f'local rebuild error: {exc}')

def import_names(pkg):
    # Prefer explicit top_level.txt metadata when available.
    # isidentifier() filters out strings that cannot be ordinary Python
    names = {x.strip() for x in pkg['tops'] if x.strip().isidentifier()}
    
    if names:
        return sorted(names)

    # Fall back to inferring imports from the installed file manifest.
    for path in pkg['files']:
        parts = path.replace('\\', '/').split('/')

        # A directory containing __init__.py is a traditional Python package.
        if len(parts) >= 2 and parts[1] == '__init__.py' and parts[0].isidentifier():
            names.add(parts[0])

        # A top-level .py file can also be imported as a module.
        elif len(parts) == 1 and path.endswith('.py') and parts[0][:-3].isidentifier():
            names.add(parts[0][:-3])
    return sorted(names)

def smoke(target, pkg):
    names = import_names(pkg)

    # Returning True allows migration to continue
    if not names:
        return (True, 'no importable modules identified (metadata only)')
    
    program = 'import importlib,sys\nfor name in ' + repr(names) + ':\n    importlib.import_module(name)\n'
    
    # Build a small Python program that imports each detected module
    code, msg = run([target, '-c', program], timeout=40, quiet=True)
    
    # Return a Boolean indicating import success and a short description.
    # failed and a compact module list when it succeeded.
    return (code == 0, msg[-700:] if code else 'imported ' + ', '.join(names[:7]))

def pip_install(target, wheelhouse, spec, *, local=True, force=False):
    cmd = [target, '-m', 'pip', 'install', '--disable-pip-version-check', '--no-input', '--no-deps', '--no-compile']

    if force:
        # Replace the installed distribution even if pip considers
        # the requested version already satisfied.
        cmd.append('--force-reinstall')
    
    if local:
        # --no-index prevents access to package indexes.
        # --find-links directs pip to search the local wheelhouse.
        # This branch is used first to favor locally available packages.
        cmd += ['--no-index', '--find-links', str(wheelhouse)]
   
    # spec normally has the form distribution==version.
    # Exact pinning avoids silently selecting another release.
    cmd.append(spec)

    # Installation can take longer than ordinary inspection commands.
    return run(cmd, timeout=600, quiet=True)

def managed_exes():
    code, out = run(['py', 'list', '--only-managed', '--format=exe'], quiet=True)
    
    # If the launcher does not support this command or it fails,
    # treat the managed interpreter list as unavailable.
    if code:
        return set()

    # Normalize paths for comparison with discovered interpreters.
    return {str(Path(line.strip()).resolve()).lower() for line in out.splitlines() if line.strip().lower().endswith('.exe') and Path(line.strip()).is_file()}

def do_uninstall(runtime, all_runtimes, managed, *, dry_run=False):
    def canonical(path):
        return Path(os.path.realpath(os.path.abspath(str(path))))

    def same_path(a, b):
        return os.path.normcase(str(canonical(a))) == os.path.normcase(str(canonical(b)))

    def execute(cmd, timeout=300):
        code, output = run(cmd, timeout=timeout, quiet=True)
        return (code == 0, output)
    
    exe = canonical(runtime['executable'])
    version = tuple(runtime['version'])
    system = platform.system()
    prefix = canonical(runtime.get('base_prefix') or exe.parent)
    stable = [r for r in all_runtimes if r['version'][0] == 3 and (not r['prerelease'])]
    
    # Protect the selected destination, Python 3.12, and any interpreter belonging to the running process.
    if not stable:
        return (False, 'No stable Python 3 destination')
    
    target = max(stable, key=lambda r: (tuple(r['version']), r['executable']))
    if same_path(exe, target['executable']) or version[:2] == (3, 12) or same_path(exe, sys.executable) or same_path(prefix, sys.prefix) or same_path(prefix, sys.base_prefix):
        return (False, 'Protected Python installation')
    
    # Do not uninstall another runtime sharing this prefix.
    for other in all_runtimes:
        if other is runtime:
            continue
        if same_path(exe, other['executable']):
            return (False, 'Executable is shared with another runtime')
        if same_path(prefix, other.get('base_prefix') or Path(other['executable']).parent):
            return (False, 'Installation prefix is shared')
    
    if not exe.is_file():
        return (True, 'Python executable already absent')
    roots = [Path('/'), Path('/usr'), Path('/usr/local'), Path('/opt'), Path('/bin'), Path('/sbin'), Path('/lib'), Path('/lib64'), Path('/System'), Path('/Library'), Path.home()]
    
    # Refuse to delete system-level or ambiguous directories.
    if system == 'Windows':
        roots.extend((Path(p) for p in (os.environ.get('SystemRoot'), os.environ.get('ProgramFiles'), os.environ.get('ProgramFiles(x86)'), os.environ.get('ProgramData'), os.environ.get('USERPROFILE')) if p))
    if any((same_path(prefix, root) for root in roots)):
        return (False, 'Refusing to delete a protected directory')
    
    if not exe.is_relative_to(prefix):
        return (False, 'Executable is outside installation prefix')
    
    # Symlinked executables and prefixes can represent shared installs.
    if Path(runtime['executable']).is_symlink():
        return (False, 'Executable is a symlink')
    
    markers = [prefix / 'pyvenv.cfg', prefix / 'python.exe', prefix / 'python3.exe', prefix / 'bin' / 'python3', prefix / 'Lib' / 'os.py', prefix / 'lib' / ('python%d.%d' % version[:2])]
    if not any((p.exists() for p in markers)):
        return (False, 'Installation directory could not be verified')
    
    # Identify a standalone Python installation.
    # Ensure no other interpreter is nested in the deletion tree.
    for other in all_runtimes:
        if other is runtime:
            continue
        other_exe = canonical(other['executable'])
        if other_exe.is_relative_to(prefix):
            return (False, 'Another Python installation is inside prefix')
    if dry_run:
        return (True, f'Would uninstall {exe}, then remove {prefix} if needed')
    attempts = []

    def record(method, command):
        ok, output = execute(command)
        attempts.append(f"{method}: {('success' if ok else 'failed')}" + (f' ({output[-250:]})' if not ok and output else ''))
        return ok
    
    # 1. Python Install Manager on Windows.
    if system == 'Windows':
        managed_paths = {os.path.normcase(str(canonical(p))) for p in managed}

        if os.path.normcase(str(exe)) in managed_paths:
            tag = '.'.join(map(str, version[:2]))
            record('Python Install Manager', ['py', 'uninstall', '--yes', tag])
            
            if not exe.exists():
                return (True, 'Removed using Python Install Manager')
        # Windows registered uninstall entries.
        try:
            import winreg
            
            uninstall_keys = ['SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall', 'SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall']

            def reg_value(key, name):
                try:
                    return winreg.QueryValueEx(key, name)[0]
                except OSError:
                    return ''
            
            found = False
            
            for hive in (winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER):
                for key_path in uninstall_keys:
                    try:
                        parent = winreg.OpenKey(hive, key_path)
                    except OSError:
                        continue
                    with parent:
                        count = winreg.QueryInfoKey(parent)[0]
                        for i in range(count):
                            try:
                                sub = winreg.OpenKey(parent, winreg.EnumKey(parent, i))
                            except OSError:
                                continue

                            with sub:
                                name = reg_value(sub, 'DisplayName')
                                location = reg_value(sub, 'InstallLocation')
                                quiet = reg_value(sub, 'QuietUninstallString')
                                normal = reg_value(sub, 'UninstallString')
                                
                                if not name.lower().startswith('python '):
                                    continue

                                if not location or not same_path(location, prefix):
                                    continue

                                command = quiet or normal
                                if not command:
                                    continue

                                found = True

                                # Use Windows' command-line parser for
                                # registered uninstaller command strings.
                                import ctypes
                                
                                argc = ctypes.c_int()
                                shell32 = ctypes.windll.shell32
                                shell32.CommandLineToArgvW.restype = ctypes.POINTER(ctypes.c_wchar_p)
                                argv = shell32.CommandLineToArgvW(command, ctypes.byref(argc))
                                
                                if not argv:
                                    continue

                                try:
                                    parts = [argv[j] for j in range(argc.value)]
                                finally:
                                    ctypes.windll.kernel32.LocalFree(argv)

                                # Prefer quiet entries. Avoid interactive
                                # uninstallers with no silent option.
                                if not quiet:
                                    if parts[0].lower().endswith('msiexec.exe'):
                                        parts = ['/X' if p.upper() == '/I' else p for p in parts]
                                        parts += ['/qn', '/norestart']
                                    else:
                                        continue
                                
                                record('Windows registered uninstaller', parts)
                                
                                if not exe.exists():
                                    return (True, 'Removed using registered uninstaller')
            
            if not found:
                attempts.append('No matching registered uninstaller')
        except (ImportError, OSError) as exc:
            attempts.append(f'Registry lookup unavailable: {exc}')
    
    # 2. Homebrew on macOS or Linux.
    if system in ('Darwin', 'Linux') and shutil.which('brew'):
        ok, output = execute(['brew', '--prefix'], timeout=30)
        
        if ok:
            brew_root = canonical(output.strip())

            if prefix.is_relative_to(brew_root):
                formula = f'python@{version[0]}.{version[1]}'
                ok, formula_prefix = execute(['brew', '--prefix', formula], timeout=30)
                
                if ok and same_path(formula_prefix.strip(), prefix):
                    record('Homebrew', ['brew', 'uninstall', formula])
                    
                    if not exe.exists():
                        return (True, 'Removed using Homebrew')
    
    # 3. Filesystem fallback.
    # Avoid deleting generic Unix bin directories.
    if system in ('Linux', 'Darwin'):
        unsafe = prefix.name in ('bin', 'sbin', 'lib', 'lib64')
        if unsafe:
            return (False, '; '.join(attempts))
    
    try:
        shutil.rmtree(prefix)
        
        if exe.exists():
            return (False, 'Directory deletion completed but executable remains')
        return (True, f'Force-deleted {prefix}' + (f" after {'; '.join(attempts)}" if attempts else ''))
    
    except OSError as exc:
        return (False, f'Unable to delete {prefix}: {exc}. ' + '; '.join(attempts))

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--apply', action='store_true', help='copy/reinstall packages (default prints a plan)')
    parser.add_argument('--offline', action='store_true', help='never download packages')
    parser.add_argument('--uninstall', action='store_true', help='after successful migration, prompt to uninstall old interpreters')
    parser.add_argument('--workdir', type=Path, help='parent folder for temporary migration files (default system temp)')
    
    # Construct the command-line argument parser.
    args = parser.parse_args()
    
    if args.uninstall and (not args.apply):
        # Uninstallation must not be requested without migration being enabled.
        parser.error('--uninstall also requires --apply')
    
    # Discover interpreters before choosing a migration destination.
    runtimes = discover()
    
    if not runtimes:
        raise SystemExit('No CPython installations found')
    
    # Restrict destination candidates to stable Python 3 releases.
    # Prereleases are excluded because they may introduce additional
    # compatibility uncertainty for installed packages.
    stable = [r for r in runtimes if not r['prerelease'] and r['version'][0] == 3]
    
    if not stable:
        raise SystemExit('No stable Python 3 interpreter detected')
    
    # Choose the highest stable Python 3 version.
    # The executable path provides a deterministic tie-breaker.
    target = max(stable, key=lambda r: (tuple(r['version']), r['executable']))
    
    keep = lambda r: r is target or tuple(r['version'][:2]) == (3, 12)
    
    # All discovered runtimes not protected by keep() become migration
    # sources and potential uninstallation candidates.
    sources = [r for r in runtimes if not keep(r)]
    inventory = {r['executable']: [p for p in r['packages'] if norm(p['name']) not in EXCLUDED] for r in runtimes}
    
    # Build an inventory indexed by interpreter executable path.
    # Excluded packaging tools are removed from the migration inventory.
    # Show the complete interpreter selection before doing any work.
    print('\nDETECTED CPYTHON RUNTIMES')
    
    for r in runtimes:
        label = 'KEEP' if keep(r) else 'MIGRATE / CANDIDATE FOR REMOVAL'
        if r is target:
            label = 'DESTINATION (KEEP)'
        print(f"  {'.'.join(map(str, r['version'])):9} {label:33} {r['executable']}")
    
    # This aligns the displayed version, status, and executable path.
    print('Packages in excluded runtimes:', sum((len(inventory[r['executable']]) for r in sources)))
    
    # Count installed distributions across all migration sources.
    # No source interpreters means no migration is necessary.
    if not sources:
        print('Nothing to migrate or remove.')
        return
    
    # The dry-run branch appears before any directory creation or
    # installation work so the default mode remains observational.
    if not args.apply:
        print('\nDRY RUN only. Run with --apply to migrate, optionally --uninstall to remove.')
        print('Packages by source:')
        
        for r in sources:
            print(' ', r['executable'])
            
            for p in inventory[r['executable']]:
                good, why, tag = isDistRepackable(p)
                print(f"    {p['name']}=={p['version']} ({('copyable' if good else why)})")
        return
    
    # Use an isolated temporary wheelhouse and inventory directory.
    # Cleanup occurs even when migration fails or is cancelled.
    if args.workdir:
        args.workdir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='python-migration-', dir=args.workdir) as temporary_dir:
        wd = Path(temporary_dir)
        print('\nTemporary migration folder:', wd)
        
        # From this point onward, --apply has been explicitly supplied.
        wheelhouse = wd / 'local-wheels'
        wheelhouse.mkdir(exist_ok=True)
        
        # Save temporary interpreter inventories before changing installed packages.
        # These inventories are informational and removed on exit.
        # They are not full backups of interpreter installations.
        
        for r in runtimes:
            name = f"python-{'.'.join(map(str, r['version']))}-{hashlib.sha256(r['executable'].encode()).hexdigest()[:8]}.json"
            # Include the Python version and a short executable-path hash.
            # but different executable paths.
            (wd / name).write_text(json.dumps(r, indent=2), encoding='utf-8')
        
        # Collect local wheels before installation attempts.
        # The wheelhouse can supply packages without network access.
        print('\nCollecting locally cached wheels ...')
        
        wheels = cache_wheels(runtimes, wheelhouse)
        
        print('Found', wheels, 'wheels in pip wheel caches')
        
        # Index destination packages by normalized distribution name.
        # This makes checking whether a package already exists efficient.
        target_pkgs = {norm(p['name']): p for p in inventory[target['executable']]}
        
        # selected stores one source distribution per normalized name.
        # blockers records conditions that prevent automatic uninstallation.
        selected = {}
        blockers = []
        
        # Prefer packages from the highest-version source interpreter
        # when the same distribution exists in multiple source runtimes.
        for r in sorted(sources, key=lambda r: tuple(r['version']), reverse=True):
            for p in inventory[r['executable']]:
                key = norm(p['name'])
                
                if key in selected:
                    # If source interpreters disagree about the package
                    # version, record the conflict rather than silently
                    # treating the environments as equivalent.
                    if selected[key]['version'] != p['version']:
                        blockers.append(f"conflicting old versions of {key}: {selected[key]['version']} vs {p['version']}")
                    continue
                
                selected[key] = p
        
        # copied records packages that pass the script's validation.
        # unresolved records failed installation or import attempts.
        # pending_validation defers imports until installation finishes.
        copied = []
        unresolved = []
        pending_validation = []
        
        # Sort by normalized distribution name for predictable processing.
        for key, pkg in sorted(selected.items()):
            existing = target_pkgs.get(key)
            
            if existing:
                # An exact existing version is retained without reinstalling.
                if existing['version'] == pkg['version']:
                    print(f"KEEP existing target {pkg['name']}=={pkg['version']}")
                    continue

                msg = f"{pkg['name']}: target has {existing['version']}, source has {pkg['version']}"
                
                # Do not overwrite a different version already installed
                # in the destination interpreter.
                
                print('CONFLICT', msg)
                blockers.append(msg)
                continue
            
            # Pin the distribution to its recorded source version.
            spec = f"{pkg['name']}=={pkg['version']}"
            # Preserve a warning when the original installation records
            # a direct source URL.
            # A public-index distribution with the same name and version
            # may not contain the same code as a local or VCS installation.
            if pkg['direct_url']:
                try:
                    origin = json.loads(pkg['direct_url']).get('url', 'unknown source')
                
                except ValueError:
                    origin = 'unknown source'
                
                blockers.append(f'{spec} was installed from {origin}; manually verify its original source')
            
            # Attempt to reconstruct a local wheel if the installed package
            # passes the conservative compatibility checks.
            recreated, explanation = repackage(pkg, wheelhouse)
            print(f'\n{spec} | {explanation}')
            code, msg = pip_install(target['executable'], wheelhouse, spec)
            
            # Always try local material before permitting a network request.
            # pip searches the wheelhouse for a matching distribution/version.
            method = 'local wheel/copy'
            if code and (not args.offline):
                # If local installation fails and offline mode is disabled,
                # allow pip to consult its configured index and cache.
                print('  no usable local installation; trying pip index/cache')
                code, msg = pip_install(target['executable'], wheelhouse, spec, local=False)
                method = 'pip index/cache (download may occur)'
            if code == 0:
                pending_validation.append((spec, pkg, recreated if explanation.startswith('reconstructed') else None, method))
                # Defer imports until all selected distributions have
                # been processed.
                print('  installed via', method)
            else:
                print('  FAILED', msg[-650:])
                unresolved.append(f'{spec}: {msg[-350:]}')
        
        # Perform import checks after the entire installation phase.
        # This ordering reduces false failures caused by a package being
        # imported before another selected package has been installed.
        for spec, pkg, recreated, method in pending_validation:
            ok, validation = smoke(target['executable'], pkg)
            
            if not ok:
                print('  FAILED import after local migration:', spec, validation)
                
                # Delete the reconstructed archive after a failed import.
                # This prevents the same archive from being selected during
                # the next local installation attempt.
                if recreated is not None:
                    recreated.unlink(missing_ok=True)
                
                # Try reinstalling from remaining local wheel material.
                # distribution/version is already present.
                code, msg = pip_install(target['executable'], wheelhouse, spec, force=True)
                
                if code == 0:
                    ok, validation = smoke(target['executable'], pkg)
                    
                    if ok:
                        method = 'cached original wheel after failed copy'
                if not ok and (not args.offline):
                    print('  retrying pip index/cache after confirmed failed import:', spec)
                    code, msg = pip_install(target['executable'], wheelhouse, spec, local=False, force=True)
                    
                    # If the local recovery attempt still fails, optionally
                    # retry using the configured pip index/cache.
                    if code == 0:
                        ok, validation = smoke(target['executable'], pkg)
                        if ok:
                            method = 'pip index/cache after confirmed failed import'
                
                # An unresolved import failure prevents automatic removal
                # of the old interpreter.
                if not ok:
                    unresolved.append(f'{spec}: import test failure: {validation[-350:]}')
                    continue
            
            # Only packages that reach this point are counted as verified.
            copied.append((spec, method))
            
            # Some distributions expose no detectable importable modules.
            # They require manual verification even if pip installation worked.
            if not import_names(pkg):
                blockers.append(f'{spec}: no importable module identified; verify this package manually')
            print('  VERIFIED', spec, 'via', method, '|', validation)
        
        # Check the destination's installed dependency requirements.
        # pip check detects missing dependencies and incompatible declared
        # versions among installed distributions.
        # It does not execute the user's applications or test all imports.
        code, check_out = run([target['executable'], '-m', 'pip', 'check'], quiet=True)
        
        if code:
            blockers.append('pip check failed: ' + check_out[-1800:])

        # Display a concise migration summary.
        print('\n=== RESULT ===')
        print('Destination:', target['executable'])
        print('Packages installed:', len(copied))
        print('Unresolved:', len(unresolved), 'Conflicts/check failures:', len(blockers))
        
        # Concatenating these lists prints all reasons that automatic
        # uninstallation should be blocked.
        for x in unresolved + blockers:
            print('  BLOCKER:', x)
        
        if not code:
            print('pip check: OK')
        
        # Retain all existing Python installations unless --uninstall
        # was explicitly supplied.
        if not args.uninstall:
            print('\nExisting Python installations retained. Use --apply --uninstall after testing projects.')
            return
        
        # Automatic uninstallation is blocked when package migration
        # or validation reported unresolved problems.
        if unresolved or blockers:
            print('\nSAFETY STOP: not uninstalling any interpreters while problems remain.')
            return
        
        print('About to uninstall the following Python runtimes:')
        for r in sources:
            print(' ', r['executable'])
        
        # Require a specific confirmation phrase.
        # A full phrase is harder to enter accidentally than a single
        # character such as y.
        confirmation = input('\nType DELETE OLD PYTHONS to proceed: ').strip()
        
        if confirmation != 'DELETE OLD PYTHONS':
            print('Uninstall cancelled.')
            return
        
        # Discover manager-owned interpreters only after the user confirms.
        # This avoids unnecessary uninstall-related work during migration.
        managed = managed_exes()
        
        for r in sources:
            # do_uninstall() chooses the applicable removal mechanism
            # and performs its additional identity checks.
            ok, msg = do_uninstall(r, runtimes, managed)
            print('REMOVED' if ok else 'RETAINED', r['executable'], msg)
        
        print('Finished')

# Execute main() only when this file is run as a program.
if __name__ == '__main__':
    main()
