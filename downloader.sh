#!/usr/bin/env bash
# Startup launcher and scheduler installation for setup_linux.sh.
# The installer functions use state from setup_linux.sh when sourced.
# shellcheck disable=SC2154

system_script=/usr/local/lib/zerohazard-startup/setup_linux.sh
user_script_relative=.local/lib/zerohazard-startup/setup_linux.sh

valid_pin() {
	[[ ${SETUP_LINUX_COMMIT:-} =~ ^[0-9a-f]{40}$ && ${SETUP_LINUX_SHA256:-} =~ ^[0-9a-f]{64}$ ]] || {
		printf 'Expected a full Git commit and SHA-256 digest in lowercase hex.\n' >&2
		return 1
	}
}

fetch_environment() {
	[[ -n ${SETUP_LINUX_COMMIT:-}${SETUP_LINUX_SHA256:-} ]] || return 0
	valid_pin || return
	printf 'Environment=SETUP_LINUX_COMMIT=%s SETUP_LINUX_SHA256=%s' "$SETUP_LINUX_COMMIT" "$SETUP_LINUX_SHA256"
}

# Replace the launcher and units atomically so active jobs can keep reading their copies.
install_script() {
	local source=$1 target=$2 temporary
	install -d -m 0755 -- "${target%/*}" || return
	temporary=$(mktemp "${target%/*}/.setup_linux.XXXXXX") || return
	if ! install -m 0755 -- "$source" "$temporary" || ! /bin/bash -n "$temporary" ||
		! mv -fT -- "$temporary" "$target"; then
		rm -f -- "$temporary"
		return 1
	fi
}

install_unit() {
	local target=$1 temporary
	temporary=$(mktemp "${target%/*}/.zerohazard.XXXXXX") || return
	if ! cat > "$temporary" || ! chmod 0644 -- "$temporary" || ! mv -fT -- "$temporary" "$target"; then
		rm -f -- "$temporary"
		return 1
	fi
}

install_login() {
	local directory=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
	local launcher=${user_script_relative%/*}/downloader.sh fetch
	fetch=$(fetch_environment) || return
	install_script "${script_path%/*}/downloader.sh" "$HOME/$launcher" &&
		install -d -m 0755 -- "$directory" || return
	install_unit "$directory/$unit_name.service" <<UNIT || return
[Unit]
Description=Zerohazard Linux logon tasks
PartOf=graphical-session.target

[Service]
Type=exec
RemainAfterExit=yes
Nice=10
ExecStart=/bin/bash "%h/$launcher"
$fetch

[Install]
WantedBy=graphical-session.target
UNIT
	systemctl --user daemon-reload && systemctl --user enable "$unit_name.service"
}

install_system() {
	local directory=/etc/systemd/system
	local launcher=${system_script%/*}/downloader.sh fetch
	fetch=$(fetch_environment) || return
	install_script "${script_path%/*}/downloader.sh" "$launcher" || return
	install_unit "$directory/$unit_name.service" <<UNIT || return
[Unit]
Description=Zerohazard Linux system maintenance
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
Nice=10
ExecStart=/bin/bash "$launcher"
$fetch
UNIT
	install_unit "$directory/$unit_name.timer" <<UNIT || return
[Unit]
Description=Run Zerohazard Linux system maintenance after boot

[Timer]
OnBootSec=2min
Unit=$unit_name.service

[Install]
WantedBy=timers.target
UNIT
	systemctl daemon-reload && systemctl enable "$unit_name.timer"
}

remove_login() {
	local unit=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$unit_name.service
	if [[ -f $unit ]]; then
		systemctl --user disable "$unit_name.service" &&
			rm -f -- "$unit" "$HOME/$user_script_relative" "$HOME/${user_script_relative%/*}/downloader.sh" &&
			systemctl --user daemon-reload
	fi
}

remove_system() {
	local prefix=/etc/systemd/system/$unit_name
	local state
	if [[ -f $prefix.timer || -f $prefix.service ]]; then
		if [[ -f $prefix.timer ]]; then
			systemctl disable --now "$unit_name.timer" || return
		fi
		# Refuse removal during an in-flight package transaction. Try again after it ends.
		lock_phase /run/zerohazard-setup-linux.lock || return
		state=$(systemctl show --property=ActiveState --value "$unit_name.service") || return
		case $state in
			active|activating|reloading|deactivating)
				warn 'The maintenance service is active. Retry after it finishes.'
				return 1 ;;
		esac
		rm -f -- "$prefix.timer" "$prefix.service" "$system_script" "${system_script%/*}/downloader.sh" && systemctl daemon-reload
	fi
}

matches_pin() {
	local digest
	[[ -r $1 ]] || return 1
	digest=$(sha256sum < "$1") || return
	[[ ${digest%% *} == "$SETUP_LINUX_SHA256" ]]
}

download_setup() {
	rm -f -- "$setup" &&
		curl --disable --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
			--retry 2 --max-time 60 --output "$setup" "$1" &&
		grep -Fxq -- '# Linux startup and maintenance instructions for downloader.sh' "$setup"
}

[[ ${BASH_SOURCE[0]} == "$0" ]] || return 0
set -uo pipefail
launcher=$(realpath -- "$0") || exit
setup=${launcher%/*}/setup_linux.sh
if (($#)); then
	case $1 in
		--install-login|--install-system|--remove-login|--remove-system)
			exec /bin/bash "$setup" "$@"
			;;
		*) printf 'Error: Unknown option %s.\n' "$1" >&2; exit 1 ;;
	esac
fi
if [[ -n ${SETUP_LINUX_COMMIT:-}${SETUP_LINUX_SHA256:-} ]]; then valid_pin || exit 1; fi
# Remove snapshots left by the earlier installer, keeping the checkout intact.
for installed in "$system_script" "${HOME:-}/$user_script_relative"; do
	if [[ $launcher -ef ${installed%/*}/downloader.sh ]]; then rm -f -- "$installed" || exit; fi
done
staging=$(mktemp -d) || exit
trap 'rm -rf -- "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
setup=$staging/setup_linux.sh
github=https://raw.githubusercontent.com/Zerohazard8x/scripts
printf '\n=== Now running: downloading setup_linux.sh ===\n'
if [[ -n ${SETUP_LINUX_COMMIT:-} ]]; then
	download_setup "$github/$SETUP_LINUX_COMMIT/setup_linux.sh" || exit 1
	if ! matches_pin "$setup"; then
		printf 'Downloaded setup_linux.sh failed SHA-256 verification.\n' >&2
		exit 1
	fi
elif ! download_setup https://codeberg.org/Zerohazard8x/scripts/raw/branch/main/setup_linux.sh &&
	! download_setup "$github/main/setup_linux.sh"; then
	printf 'Could not download a compatible setup_linux.sh.\n' >&2
	exit 1
fi
/bin/bash -n "$setup" && /bin/bash "$setup"
