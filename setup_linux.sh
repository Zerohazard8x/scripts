#!/usr/bin/env bash
# Linux startup and maintenance instructions for downloader.sh
set -uo pipefail

unit_name=zerohazard-setup-linux
failures=0
work_dir=

status() { printf '\n=== Now running: %s ===\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

step() {
	local label=$1
	shift
	local result
	status "$label"
	if "$@"; then
		return
	else
		result=$?
	fi
	failures=$((failures + 1))
	warn "$label failed (exit $result). Continuing with the remaining work."
}

confirm() {
	local default=${2-Y} reply deadline=$((SECONDS + 5))
	local -a timeout=()
	if [[ ! -t 0 ]]; then
		[[ $default == Y ]]
		return
	fi
	printf '%s (Y/N) ' "$1"
	if [[ -n $default ]]; then printf '(default %s in 5 seconds) ' "$default"; fi
	while :; do
		if [[ -n $default ]]; then
			(( SECONDS < deadline )) || break
			timeout=(-t "$((deadline - SECONDS))")
		fi
		read -rs -n 1 "${timeout[@]}" reply || break
		case $reply in
			[yY]) printf '\n'; return 0 ;;
			[nN]) printf '\n'; return 1 ;;
		esac
	done
	printf '\n'
	[[ $default == Y ]]
}

idle_setting() {
	local name=$1 value=$2 minimum=$3 maximum=$4
	[[ $value =~ ^[0-9]{1,6}$ ]] || die "Invalid $name value $value."
	value=$((10#$value))
	(( value >= minimum && value <= maximum )) || die "$name must be between $minimum and $maximum."
	printf '%s\n' "$value"
}

cpu_ticks() {
	local label user nice system idle iowait irq softirq steal rest
	read -r label user nice system idle iowait irq softirq steal rest < /proc/stat || return 1
	[[ $label == cpu ]] || return 1
	idle_ticks=$((idle + iowait))
	total_ticks=$((user + nice + system + idle_ticks + irq + softirq + steal))
}

wait_interval() {
	local deadline=$((SECONDS + $1)) key
	if [[ -t 0 ]]; then
		while (( SECONDS < deadline )); do
			if read -rs -n 1 -t "$((deadline - SECONDS))" key; then
				[[ $key == [nN] ]] && return 2
			else
				# A timeout ends the interval. EOF also works when launched without usable input.
				if (( SECONDS < deadline )); then sleep "$((deadline - SECONDS))" || return; fi
				break
			fi
		done
		return 0
	else
		sleep "$1"
	fi
}

wait_for_idle() {
	local maximum threshold required interval deadline delay stable=0
	local idle_ticks total_ticks previous_idle previous_total elapsed busy
	maximum=$(idle_setting SCRIPT_STARTUP_IDLE_MAX_SECONDS "${SCRIPT_STARTUP_IDLE_MAX_SECONDS:-600}" 0 999999) || return 1
	(( maximum > 0 )) || return 0
	threshold=$(idle_setting SCRIPT_STARTUP_IDLE_CPU_PERCENT "${SCRIPT_STARTUP_IDLE_CPU_PERCENT:-25}" 1 100) || return 1
	required=$(idle_setting SCRIPT_STARTUP_IDLE_STABLE_SAMPLES "${SCRIPT_STARTUP_IDLE_STABLE_SAMPLES:-3}" 1 999999) || return 1
	interval=$(idle_setting SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS "${SCRIPT_STARTUP_IDLE_SAMPLE_SECONDS:-10}" 1 999999) || return 1
	status "Waiting for CPU usage at or below $threshold% over $required samples, up to ${maximum}s"
	if [[ -t 0 ]]; then
		printf 'Press N to cancel.\n'
	fi
	cpu_ticks || { warn 'CPU statistics are unavailable. Starting now.'; return 0; }
	deadline=$((SECONDS + maximum))
	while (( SECONDS < deadline )); do
		previous_idle=$idle_ticks
		previous_total=$total_ticks
		delay=$((deadline - SECONDS))
		(( delay > interval )) && delay=$interval
		wait_interval "$delay" || return $?
		cpu_ticks || break
		elapsed=$((total_ticks - previous_total))
		busy=$((elapsed - (idle_ticks - previous_idle)))
		if (( elapsed > 0 && busy >= 0 && busy * 100 <= threshold * elapsed )); then
			stable=$((stable + 1))
			(( stable >= required )) && return 0
		else
			stable=0
		fi
	done
	return 0
}

require_root() {
	(( EUID == 0 )) || die 'Run this command with sudo.'
}

require_user() {
	(( EUID != 0 )) || die 'Run this command as your desktop user.'
}

lock_phase() {
	local lock_file=$1
	have flock || die 'flock is required to guard against overlapping runs.'
	exec 9>"$lock_file" || die "Could not open $lock_file."
	if flock -n -E 75 9; then
		return 0
	else
		(($? == 75)) || die "Could not lock $lock_file."
	fi
	printf 'Another %s run is active.\n' "$unit_name"
	return 75
}

select_package_manager() {
	if have apt-get; then manager=apt
	elif have pacman; then manager=pacman
	elif have zypper; then manager=zypper
	elif have dnf; then manager=dnf
	elif have yum; then manager=yum
	else manager=
	fi
}

refresh_system_packages() {
	case $manager in
		apt) env DEBIAN_FRONTEND=noninteractive apt-get -o APT::Update::Error-Mode=any update &&
			env DEBIAN_FRONTEND=noninteractive apt-get -y --with-new-pkgs upgrade && apt-get autoclean ;;
		pacman) pacman -Syu --noconfirm ;;
		zypper) zypper --non-interactive update ;;
		dnf|yum) "$manager" -y upgrade ;;
		*) printf 'No supported distro package manager found.\n' ;;
	esac
}

install_core_packages() {
	local -a packages=(curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc)
	local -a available=()
	local package results
	case $manager in
		apt)
			if ! apt-cache show firefox 2>/dev/null | grep '^Package: ' >/dev/null; then packages[1]=firefox-esr; fi
			packages+=(python3 python3-venv)
			;;
		pacman) packages+=(python python-pip) ;;
		zypper) packages+=(python3 python3-pip) ;;
		dnf|yum) packages+=(python3 python3-pip) ;;
		*) warn 'No supported distro package manager can install the core packages.'; return 1 ;;
	esac
	for package in "${packages[@]}"; do
		case $manager in
			apt) results=$(apt-cache show "$package" 2>/dev/null | grep '^Package: ') || results= ;;
			pacman) results=$(pacman -Si -- "$package" 2>/dev/null) || results= ;;
			zypper) results=$(zypper --non-interactive --xmlout search --match-exact --type package "$package" 2>/dev/null |
				grep '<solvable ') || results= ;;
			dnf|yum) results=$("$manager" -q list --installed "$package" 2>/dev/null || "$manager" -q list --available "$package" 2>/dev/null) || results= ;;
		esac
		if [[ -n $results ]]; then
			available+=("$package")
		else
			warn "$package is unavailable in the configured repositories."
		fi
	done
	((${#available[@]})) || return 1
	case $manager in
		apt) env DEBIAN_FRONTEND=noninteractive apt-get -y install "${available[@]}" ;;
		pacman) pacman -S --needed --noconfirm -- "${available[@]}" ;;
		zypper) zypper --non-interactive install -- "${available[@]}" ;;
		dnf|yum) "$manager" -y install "${available[@]}" ;;
	esac
}

# Install NVIDIA drivers if GeForce GPU is detected
install_nvidia() {
	if have ubuntu-drivers; then
		ubuntu-drivers install
	elif [[ $manager == apt ]] && apt-cache show nvidia-driver >/dev/null 2>&1; then
		env DEBIAN_FRONTEND=noninteractive apt-get -y install nvidia-driver
	elif [[ $manager == pacman ]] && pacman -Si nvidia >/dev/null 2>&1; then
		pacman -S --needed nvidia
	else
		warn 'No supported NVIDIA driver package found in the configured repositories.'
		return 1
	fi
}

write_setting() {
	printf '%s\n' "$2" > "$1"
}

configure_dns() {
	local directory=/etc/systemd/resolved.conf.d file servers fallback=
	file=$directory/90-zerohazard-startup.conf
	case $1 in
		quad9)
			# Set IPv6 DNS server addresses
			servers='2620:fe::11 2620:fe::fe:11'
			# Set IPv4 DNS server addresses
			fallback=$'FallbackDNS=9.9.9.11 149.112.112.11\n'
			;;
		cloudflare) servers='1.1.1.2 1.0.0.2 2606:4700:4700::1112 2606:4700:4700::1002' ;;
	esac
	if ! systemctl is-active --quiet systemd-resolved.service; then
		warn 'DNS configuration requires an active systemd-resolved service.'
		return 1
	fi
	install -d -m 0755 -- "$directory" || return
	local temporary
	temporary=$(mktemp "$directory/.zerohazard.XXXXXX") || return
	if ! printf '[Resolve]\nDNS=%s\n%s' "$servers" "$fallback" > "$temporary" ||
		! chmod 0644 -- "$temporary" || ! mv -fT -- "$temporary" "$file"; then
		rm -f -- "$temporary"
		return 1
	fi
	systemctl restart systemd-resolved.service
}

import_wifi() (
	local profile=$1 name=${1##*/} destination temporary
	[[ $name == *.nmconnection && -f $profile ]] || { warn 'Use a local .nmconnection file.'; return 1; }
	awk '
		/^[[:space:]]*\[/ { connection = ($0 ~ /^[[:space:]]*\[connection\][[:space:]]*$/) }
		connection && /^[[:space:]]*type[[:space:]]*=[[:space:]]*(wifi|802-11-wireless)[[:space:]]*$/ { wifi = 1 }
		END { exit !wifi }
	' "$profile" || { warn 'The profile must describe a Wi-Fi connection.'; return 1; }
	destination=/etc/NetworkManager/system-connections/zerohazard-$name
	if ! nmcli general status >/dev/null; then
		warn 'Wi-Fi import requires an active NetworkManager service.'
		return 1
	fi
	if [[ ! -d ${destination%/*} ]]; then
		install -d -m 0700 -- "${destination%/*}" || return
	fi
	temporary=$(mktemp -d "${destination%/*}/.zerohazard.XXXXXX") || return
	trap 'rm -rf -- "$temporary"' EXIT
	if [[ -e $destination ]]; then
		cp -a -- "$destination" "$temporary/previous" || return
	fi
	install -m 0600 -- "$profile" "$temporary/profile" && mv -fT -- "$temporary/profile" "$destination" || return
	if nmcli connection load "$destination"; then return 0; fi
	if [[ -e $temporary/previous ]]; then
		mv -fT -- "$temporary/previous" "$destination" && nmcli connection load "$destination"
	else
		rm -f -- "$destination"
	fi
	return 1
)

# Delete empty folders (safely)
cleanup_empty_dirs() {
	local directory
	directory=$(realpath -e -- .) || return
	[[ -d $directory && $directory != / ]] || { warn 'Choose a cleanup directory below /.'; return 1; }
	find "$directory" -xdev -mindepth 1 -depth -type d -empty -delete
}

# ------------------------------------
# schedulers
# ------------------------------------
tune_governors() {
	local cpu policy driver governors governor value setting result=0
	if [[ -w /sys/kernel/gpu/gpu_governor ]] &&
		grep -qw simple_ondemand /sys/kernel/gpu/gpu_available_governors 2>/dev/null; then
		write_setting /sys/kernel/gpu/gpu_governor simple_ondemand || result=1
	fi
	for cpu in /sys/devices/system/cpu/cpu[0-9]*/online; do
		[[ -w $cpu ]] || continue
		read -r value < "$cpu" || continue
		[[ $value == 0 ]] || continue
		write_setting "$cpu" 1 || result=1
	done
	for policy in /sys/devices/system/cpu/cpufreq/policy[0-9]*; do
		[[ -w $policy/scaling_governor ]] || continue
		read -r driver < "$policy/scaling_driver" || continue
		read -r governors < "$policy/scaling_available_governors" || continue
		case " $governors " in
			*' schedutil '*) governor=schedutil ;;
			*)
				if [[ $driver == *pstate* && " $governors " == *' powersave '* ]]; then governor=powersave
				elif [[ " $governors " == *' ondemand '* ]]; then governor=ondemand
				elif [[ " $governors " == *' performance '* ]]; then governor=performance
				else continue
				fi
				;;
		esac
		for setting in min max; do
			if [[ -w $policy/scaling_${setting}_freq ]] &&
				read -r value < "$policy/cpuinfo_${setting}_freq"; then
				write_setting "$policy/scaling_${setting}_freq" "$value" || result=1
			fi
		done
		write_setting "$policy/scaling_governor" "$governor" || result=1
		if [[ -w $policy/energy_performance_preference ]] &&
			grep -qw balance_performance "$policy/energy_performance_available_preferences" 2>/dev/null; then
			write_setting "$policy/energy_performance_preference" balance_performance || result=1
		fi
	done
	return "$result"
}

system_tasks() {
	local manager upgrade_failures=$failures profile dns_provider=cloudflare
	select_package_manager
	if confirm 'Install programs?'; then
		step 'Distro package upgrades' refresh_system_packages
		if (( failures == upgrade_failures )) && confirm 'Upgrade primary packages?' N; then
			step 'Core packages' install_core_packages
		fi
		if have snap; then step 'Snap updates' snap refresh; fi
		if have flatpak; then step 'System Flatpak updates' flatpak update --system --noninteractive -y; fi
	fi
	if have lspci && lspci | awk 'tolower($0) ~ /(vga|3d|display).*nvidia/ { found=1 } END { exit !found }' &&
		confirm 'Install NVIDIA drivers?' N; then
		step 'NVIDIA driver' install_nvidia
	fi
	if confirm 'Tune CPU and GPU governors?' N; then step 'CPU and GPU governors' tune_governors; fi
	if have systemctl && systemctl is-active --quiet systemd-resolved.service && confirm 'Configure DNS?' N; then
		if confirm 'Use Quad9 DNS?' N; then dns_provider=quad9; fi
		step 'DNS configuration' configure_dns "$dns_provider"
	fi
	if have nmcli && confirm 'Run Wi-Fi import?' N && read -r -e -p 'NetworkManager profile path: ' profile; then
		step 'Wi-Fi profile import' import_wifi "$profile"
	fi
	if confirm "Clean empty folders in $PWD?" N; then step 'Empty directory cleanup' cleanup_empty_dirs; fi
	return 0
}

ensure_venv() {
	local interpreter=$1 directory=$2
	if [[ ! -x $directory/bin/python ]]; then
		"$interpreter" -I -m venv "$directory" || return
	fi
	if ! "$directory/bin/python" -I -m pip --version >/dev/null 2>&1; then
		"$directory/bin/python" -I -m ensurepip --upgrade || return
	fi
	"$directory/bin/python" -I -m pip --disable-pip-version-check --no-input install --upgrade pip setuptools
}

update_python_packages() {
	local python=$1 resolve_cuda=$2
	shift 2
	local -a pip=("$python" -I -m pip --disable-pip-version-check --no-input)
	local -a installed=() cuda_index=()
	if (( resolve_cuda )); then
		cuda_index=(--extra-index-url https://download.pytorch.org/whl/cu128)
	fi
	if [[ -z $work_dir ]]; then
		work_dir=$(mktemp -d) || return
	fi
	# Keep local builds (such as CUDA wheels) pinned during general upgrades.
	if ! "${pip[@]}" list --format=json --exclude-editable --exclude pip --exclude setuptools --exclude wheel --exclude distribute |
		"$python" -I -c '
import json
import sys

for package in json.load(sys.stdin):
    name = package["name"]
    if sys.argv[1] == "1" and name.lower() in {"torch", "torchvision", "torchaudio"}:
        continue
    version = package["version"]
    operator = "==" if "+" in version else ">="
    print(f"{name}{operator}{version}")
' "$resolve_cuda" > "$work_dir/requirements.txt"; then
		return 1
	fi
	installed=(-r "$work_dir/requirements.txt")
	"${pip[@]}" install --upgrade --upgrade-strategy eager "${cuda_index[@]}" "${installed[@]}" "$@" || return
	if (( resolve_cuda )); then
		# Resolve PyTorch and WhisperX together so their version requirements agree.
		"$python" -I -c '
from importlib.metadata import version

if not version("torch").endswith("+cu128"):
    raise SystemExit("PyTorch CUDA 12.8 wheel was unavailable")
' || return
	fi
	"${pip[@]}" check
}

primary_python() {
	have python3 || { warn 'Install Python 3 and its venv support first.'; return 1; }
	ensure_venv python3 "$user_state/python" &&
		update_python_packages "$user_state/python/bin/python" 0 'yt-dlp[default,curl-cffi]' mutagen &&
		link_python_tools "$user_state/python" yt-dlp
}

python312() {
	local interpreter=python3.12 directory=$user_state/python312 resolve_cuda=0
	local -a uv packages=(whisperx ffsubsync demucs)
	if [[ ! -x $directory/bin/python ]] && ! have "$interpreter"; then
		if have uv; then
			uv=(uv)
		elif [[ -x $user_state/python/bin/python ]]; then
			"$user_state/python/bin/python" -I -m pip --disable-pip-version-check --no-input install --upgrade uv || return
			uv=("$user_state/python/bin/python" -I -m uv)
		else
			warn 'Install Python 3.12 or uv, or repair the primary Python environment first.'
			return 1
		fi
		"${uv[@]}" python install 3.12 || return
		interpreter=$("${uv[@]}" python find --managed-python 3.12) || return
		[[ -n $interpreter && -x $interpreter ]] || { warn 'uv did not resolve an executable Python 3.12.'; return 1; }
	fi
	ensure_venv "$interpreter" "$directory" || return
	if have nvidia-smi && nvidia-smi -L >/dev/null 2>&1; then
		resolve_cuda=1
		packages+=(torch torchvision torchaudio)
	fi
	update_python_packages "$directory/bin/python" "$resolve_cuda" "${packages[@]}" &&
		link_python_tools "$directory" whisperx ffsubsync demucs
}

link_python_tools() {
	local directory=$1 bin=$HOME/.local/bin tool
	shift
	mkdir -p -- "$bin" || return
	for tool in "$@"; do
		if [[ -e $bin/$tool || -L $bin/$tool ]]; then
			if [[ $(readlink -- "$bin/$tool") != "$directory/bin/$tool" ]]; then
				warn "Keeping the existing $bin/$tool. The maintained copy is in $directory/bin."
			fi
			continue
		fi
		if [[ -x $directory/bin/$tool ]]; then
			ln -sT -- "$directory/bin/$tool" "$bin/$tool" || return
		fi
	done
}

launch_apps() {
	if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]]; then
		printf 'Desktop apps require a graphical session.\n'
		return 0
	fi
	local app proc name version have_user_systemd=0 result=0 low_priority=0
	local -a env_args=() limits=(--property=MemoryMax=8G --property=Type=exec) launch=() command=()
	local -A flatpak_apps=(
		[steam]=com.valvesoftware.Steam
		[thunderbird]=org.mozilla.Thunderbird
		[megasync]=nz.mega.MEGAsync
		[heroic]=com.heroicgameslauncher.hgl
	)
	if have systemd-run && systemctl --user show-environment >/dev/null 2>&1; then
		have_user_systemd=1
		read -r name version _ < <(systemctl --version)
		if [[ $version =~ ^[0-9]+$ ]] && (( version >= 250 )); then limits+=(--property=ExitType=cgroup); fi
		for name in DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP; do
			if [[ -v $name ]]; then env_args+=("--setenv=$name=${!name}"); fi
		done
	else
		printf 'The user systemd manager is unavailable. Launching apps without a memory cap.\n'
	fi
	if confirm 'Set processes to lowest priority?' N; then low_priority=1; fi
	if (( low_priority )); then limits+=(--property=Nice=19 --property=IOSchedulingClass=idle); fi
	for app in steam thunderbird megasync heroic; do
		if pgrep -u "$EUID" -x "$app" >/dev/null 2>&1; then continue; fi
		if proc=$(type -P "$app"); then
			command=("$proc")
		elif proc=$(type -P flatpak) && "$proc" info "${flatpak_apps[$app]}" >/dev/null 2>&1; then
			command=("$proc" run "${flatpak_apps[$app]}")
		else
			continue
		fi
		if (( have_user_systemd )); then
			systemd-run --user --quiet --collect --unit="zerohazard-$app.service" \
				"${env_args[@]}" "${limits[@]}" -- "${command[@]}" 9>&- || result=1
		else
			launch=(nohup)
			if (( low_priority )); then
				launch+=(nice -n 19)
				if have ionice; then launch+=(ionice -c 3); fi
			fi
			"${launch[@]}" "${command[@]}" </dev/null >/dev/null 2>&1 9>&- &
		fi
	done
	return "$result"
}

open_update_windows() {
	local -a updater=()
	if have gnome-software; then updater=(gnome-software --mode=updates)
	elif have plasma-discover; then updater=(plasma-discover --mode Update)
	elif have pamac-manager; then updater=(pamac-manager --updates)
	elif have update-manager; then updater=(update-manager)
	fi
	if ((${#updater[@]})); then open_desktop_command "${updater[@]}"; fi
	if have steam; then open_desktop_command steam steam://open/downloads
	elif have flatpak && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
		open_desktop_command flatpak run com.valvesoftware.Steam steam://open/downloads
	fi
}

open_desktop_command() {
	nohup "$@" </dev/null >/dev/null 2>&1 9>&- &
}

login_tasks() {
	if confirm 'Python?'; then
		step 'Python tools' primary_python
		step 'Python 3.12 media tools' python312
	fi
	if { have brew || have flatpak; } && confirm 'Install programs?'; then
		if have brew; then step 'Homebrew upgrades' brew upgrade; fi
		if have flatpak; then step 'User Flatpak updates' flatpak update --user --noninteractive -y; fi
	fi
	step 'Desktop apps' launch_apps
	if [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]] && confirm 'Open update windows?' ''; then
		step 'Update windows' open_update_windows
	fi
	return 0
}

idle_gate() {
	local result
	if wait_for_idle; then return 0; else result=$?; fi
	if (( result == 2 )); then
		printf 'Startup tasks cancelled.\n'
		exit 0
	fi
	exit "$result"
}

run_login() {
	local user_state=${XDG_DATA_HOME:-$HOME/.local/share}/zerohazard-startup
	local -x PATH="$PATH:$HOME/.local/bin:$HOME/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/bin"
	mkdir -p -- "$user_state" || die 'Could not create the user state directory.'
	lock_phase "$user_state/run.lock" || return 0
	idle_gate
	login_tasks
}

run_system() {
	lock_phase /run/zerohazard-setup-linux.lock || return 0
	idle_gate
	system_tasks
}

cleanup_work_dir() {
	if [[ -n $work_dir ]]; then rm -rf -- "$work_dir"; fi
}

main() {
	(($# <= 1)) || die "Unexpected argument $2."
	if (($#)); then
		case $1 in
			--install-login|--remove-login) require_user ;;
			--install-system|--remove-system) require_root ;;
			*) die "Unknown option $1." ;;
		esac
		script_path=$(realpath -- "${BASH_SOURCE[0]}") || die 'Could not resolve the script path.'
		# shellcheck source=downloader.sh
		source "${script_path%/*}/downloader.sh" || die 'Could not load downloader.sh.'
		case $1 in
			--install-login) install_login || die 'Could not enable the logon job.' ;;
			--install-system) install_system || die 'Could not enable the boot timer.' ;;
			--remove-login) remove_login || die 'Could not remove the logon job.' ;;
			--remove-system) remove_system || die 'Could not remove the boot timer.' ;;
		esac
		return
	fi
	trap cleanup_work_dir EXIT
	if (( EUID == 0 )); then run_system; else run_login; fi
	if (( failures > 0 )); then die "$failures maintenance step(s) failed. See the messages above."; fi
	printf '\nStartup tasks completed.\n'
}

main "$@"
