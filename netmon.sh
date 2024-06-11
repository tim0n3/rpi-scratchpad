#!/bin/bash

set -x
# Define log file paths (consider a common log directory)
LOG_DIR="/home/tim/usb01/log/internet"
#DEBUG_LOG="$LOG_DIR/debug.log"
#ERROR_LOG="$LOG_DIR/error.log"
#SUCCESS_LOG="$LOG_DIR/success.log"

# Function to log messages with level
log() {
  local level="$1"
  local message="$2"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [$level]: $message" >> "$LOG_DIR/$(date +'%Y-%m-%d %H')_$level.log"
}

# Function to check internet connectivity (improved error handling)
check_internet() {
  local target="8.8.8.8"
  local count=3

  log debug "Beginning network checks"
  if ping -c "$count" -I "$iface" "$target" &> /dev/null; then
    log success "Internet connectivity on $iface is working fine."
    return 0
  else
    local exit_code=$?  # Capture ping exit code for better diagnostics
    log debug "Catching exit_code from ping command on $iface. Code: $exit_code"
    if [[ $exit_code -eq 1 ]]; then
      # Ping failed due to unreachable host (likely internet issue)
      log failure "Internet connectivity on $iface is down (ping exit code: $exit_code). Restarting networking service."
      systemctl restart networking.service &>> "$ERROR_LOG"
    else
      # Ping failed for other reasons (potentially ping command issue)
      log error "Ping command failed (exit code: $exit_code) - Check that iputils-ping is installed and you are using the correct interface."
    fi
    log error "Ping command failed (exit code: $exit_code) on interface $iface."
    log debug "Troubleshooting steps:"
    log debug "- Check if 'iputils-ping' is installed: sudo apt install iputils-ping (if using Debian/Ubuntu)"
    log debug "- Verify you are using the correct interface name (e.g., wlan0, eth0)."
    return 1
  fi
}

# Function to check multiple interfaces (optional)
check_all_interfaces() {
  local interfaces=(wlan0)  # Modify this list with your interfaces
  log debug "Checking the configured interfaces, $interfaces."
  for iface in "${interfaces[@]}"; do
    log debug "Checking $iface"
    check_internet "$iface"
  done
}

# Main function (simplified logic with optional loop)
main() {
  # Single check
  # if check_internet; then
  #   log DEBUG "Internet connectivity check passed."
  # else
  #   log DEBUG "Internet connectivity check failed."
  # fi

  # Looping check (uncomment to enable)
  while true; do
    check_all_interfaces  # Check all interfaces (optional)
    log debug "Completed a round of checks. Pausing for 1 minute before the next check."
    sleep 60  # Check every 60 seconds (adjust as needed)
  done
}

# Run the main function
main

