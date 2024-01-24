#!/bin/bash

# Function to log messages with timestamp
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/internet-connection.log
}

# Function for handling errors
handle_error() {
  local error_message="$1"
  log "ERROR: $error_message"
  log "STACK TRACE: $(caller)"
  exit 1
}

# Set the interface for ping
interface="eth0"

# Log start of script
log "Checking internet connection..."

# Perform ping and capture the return code
ping -c4 www.google.com -I "$interface" || handle_error "Ping failed"

# Check the return code
if [ "$?" -ne 0 ]; then
  log "Connection lost, rebooting..."
  # Add a log entry before rebooting
  log "Rebooting due to internet connection loss"
  /sbin/shutdown -r +1 "Connection lost, rebooting..."
else
  log "Internet connection is stable."
fi

# Log end of script
log "Script execution completed."
