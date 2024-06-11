#!/bin/bash

set -x

LOG_DIR="/home/tim/usb01/log/internet"
mkdir -p "$LOG_DIR"  

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

log() {
	local level="$1"
	local message="$2"
	local color="$3"
	echo -e "$(date +'%Y-%m-%d %H:%M:%S') [${color}${level}${RESET}]: ${color}${message}${RESET}" | tee -a "$LOG_DIR/$(date +'%Y-%m-%d %H')_$level.log"
}

check_internet() {
	local target="${1:-8.8.8.8}"
	local iface="$2"
	local count=3

	log debug "Beginning network checks on $iface to $target" "$BLUE"
	if ping -c "$count" -I "$iface" "$target" &> /dev/null; then
		log success "Internet connectivity on $iface to $target is working fine." "$GREEN"
		return 0
	else
		local exit_code=$?  
		log debug "Ping command failed on $iface with exit code: $exit_code" "$BLUE"
		if [[ $exit_code -eq 1 ]]; then
			log failure "Internet connectivity on $iface is down (ping exit code: $exit_code)." "$RED"
		else
			log error "Ping command failed (exit code: $exit_code) - Check that iputils-ping is installed and you are using the correct interface." "$RED"
		fi
		log error "Ping command failed (exit code: $exit_code) on interface $iface." "$RED"
		log debug "Troubleshooting steps:" "$BLUE"
		log debug "- Check if 'iputils-ping' is installed: sudo apt install iputils-ping (if using Debian/Ubuntu)" "$BLUE"
		log debug "- Verify you are using the correct interface name (e.g., wlan0, eth0)." "$BLUE"
		return 1
	fi
}

check_all_interfaces() {
	local interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))  
	log debug "Checking the configured interfaces: ${interfaces[*]}" "$BLUE"
	local success=false
	for iface in "${interfaces[@]}"; do
		log debug "Checking $iface" "$BLUE"
		if check_internet "8.8.8.8" "$iface"; then
			success=true
			break
		fi
	done

	if ! $success; then
		log error "No interfaces have internet connectivity. Restarting networking service." "$RED"
		systemctl restart networking.service &>> "$LOG_DIR/error.log"
	fi
}

main() {
	local sleep_interval="${1:-60}"  
	while true; do
		check_all_interfaces  
		log debug "Completed a round of checks. Pausing for $sleep_interval seconds before the next check." "$BLUE"
		sleep "$sleep_interval"  
	done
}


trap 'log debug "Script terminated." "$BLUE"; exit 0' SIGINT SIGTERM

main "$@"
