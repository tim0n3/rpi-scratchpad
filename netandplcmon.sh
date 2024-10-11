#!/bin/bash

#set -x

LOG_DIR="/home/tim/usb01/log/internet"
mkdir -p "$LOG_DIR"  

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

CHECK_INTERVAL=60
RESTART_THRESHOLD=1800  # 30 minutes
last_failure_time_eth0=0
last_failure_time_wlan0=0
last_failure_time_plc=0

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
                log failure "Internet connectivity on $iface is down (ping exit code: $exit_code)." "$RED"
                return 1
        fi
}

check_plc() {
        local target="192.168.1.100"  # Adjust the PLC IP address here
        local iface="eth1"
        local count=3

        log debug "Checking PLC availability on $iface at $target" "$BLUE"
        if ping -c "$count" -I "$iface" "$target" &> /dev/null; then
                log success "PLC on $iface ($target) is available." "$GREEN"
                return 0
        else
                local exit_code=$?  
                log failure "PLC on $iface ($target) is unreachable (ping exit code: $exit_code)." "$RED"
                return 1
        fi
}

restart_networking() {
        log error "Attempting to restart networking service." "$RED"
        systemctl restart networking.service &>> "$LOG_DIR/error.log"
}

check_and_handle_failures() {
        local now
        now=$(date +%s)
        
        # Check eth0
        if ! check_internet "8.8.8.8" "eth0"; then
                if [[ $((now - last_failure_time_eth0)) -ge $RESTART_THRESHOLD ]]; then
                        log error "eth0 has been down for more than 30 minutes. Rebooting device." "$RED"
                        reboot
                else
                        last_failure_time_eth0=$now
                        restart_networking
                fi
        else
                last_failure_time_eth0=0
        fi
        
        # Check wlan0
        if ! check_internet "8.8.8.8" "wlan0"; then
                if [[ $((now - last_failure_time_wlan0)) -ge $RESTART_THRESHOLD ]]; then
                        log error "wlan0 has been down for more than 30 minutes. Rebooting device." "$RED"
                        reboot
                else
                        last_failure_time_wlan0=$now
                        restart_networking
                fi
        else
                last_failure_time_wlan0=0
        fi
        
        # Check PLC on eth1
        if ! check_plc; then
                if [[ $((now - last_failure_time_plc)) -ge $RESTART_THRESHOLD ]]; then
                        log error "PLC on eth1 has been unreachable for more than 30 minutes. Rebooting device." "$RED"
                        reboot
                else
                        last_failure_time_plc=$now
                        restart_networking
                fi
        else
                last_failure_time_plc=0
        fi
}

main() {
        while true; do
                check_and_handle_failures
                log debug "Completed a round of checks. Pausing for $CHECK_INTERVAL seconds before the next check." "$BLUE"
                sleep "$CHECK_INTERVAL"
        done
}

trap 'log warning "Script terminated." "$YELLOW"; exit 0' SIGINT SIGTERM

main "$@"

