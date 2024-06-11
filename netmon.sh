#!/bin/bash

set -x

LOG_DIR="/home/tim/usb01/log/internet"
mkdir -p "$LOG_DIR"  

log() {
	local level="$1"
	local message="$2"
	echo "$(date +'%Y-%m-%d %H:%M:%S') [$level]: $message" >> "$LOG_DIR/$(date +'%Y-%m-%d %H')_$level.log"
}

check_internet() {
	local target="${1:-8.8.8.8}"
	local iface="$2"
	local count=3

	log debug "Beginning network checks on $iface to $target"
	if ping -c "$count" -I "$iface" "$target" &> /dev/null; then
		log success "Internet connectivity on $iface to $target is working fine."
		return 0
	else
		local exit_code=$?  
		log debug "Ping command failed on $iface with exit code: $exit_code"
		if [[ $exit_code -eq 1 ]]; then
			log failure "Internet connectivity on $iface is down (ping exit code: $exit_code). Restarting networking service."
			systemctl restart networking.service &>> "$LOG_DIR/error.log"
		else
			log error "Ping command failed (exit code: $exit_code) - Check that iputils-ping is installed and you are using the correct interface."
		fi
		log error "Ping command failed (exit code: $exit_code) on interface $iface."
		log debug "Troubleshooting steps:"
		log debug "- Check if 'iputils-ping' is installed: sudo apt install iputils-ping (if using Debian/Ubuntu)"
		log debug "- Verify you are using the correct interface name (e.g., wlan0, eth0)."
		return 1
	fi
}

check_all_interfaces() {
	local interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))  
	log debug "Checking the configured interfaces: ${interfaces[*]}"
	for iface in "${interfaces[@]}"; do
		log debug "Checking $iface"
		check_internet "8.8.8.8" "$iface"
	done
}

main() {
	local sleep_interval="${1:-60}"  
	while true; do
		check_all_interfaces  
		log debug "Completed a round of checks. Pausing for $sleep_interval seconds before the next check."
		sleep "$sleep_interval"  
	done
}

trap 'log debug "Script terminated."; exit 0' SIGINT SIGTERM

main "$@"

