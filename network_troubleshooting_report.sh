#!/bin/bash

REPORT_FILE="network_report.log"
ERROR_FILE="network_error.log"

> $REPORT_FILE  
> $ERROR_FILE

log() {
  COLOR_GREEN="\033[0;32m"  
  COLOR_RED="\033[0;31m"   
  COLOR_RESET="\033[0m"    

  local message="$1"
  echo -e "${COLOR_GREEN}$message${COLOR_RESET}" | tee -a $REPORT_FILE
}

log_error() {
  COLOR_RED="\033[0;31m"    
  COLOR_RESET="\033[0m"    

  local message="$1"
  echo -e "${COLOR_RED}$message${COLOR_RESET}" | tee -a $ERROR_FILE
}

install_tools() {
  REQUIRED_TOOLS=(iputils-ping net-tools traceroute dnsutils)
  for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! dpkg -s $TOOL &> /dev/null; then
      log "Installing $TOOL..."
      sudo apt-get update &>> $ERROR_FILE
      sudo apt-get install -y $TOOL &>> $ERROR_FILE
      if [[ $? -ne 0 ]]; then
        log_error "Failed to install $TOOL."
      else
        log "$TOOL installed successfully."
      fi
    else
      log "$TOOL is already installed."
    fi
  done
}

install_tools

check_ping() {
  log "** Ping Test **"
  ping -c 4 8.8.8.8 &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "Ping test failed."
  else
    log "Ping test passed."
  fi
}

check_dns_resolution() {
  log "** DNS Resolution Test **"
  dig google.com &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "DNS resolution test using dig failed."
  else
    log "DNS resolution test using dig passed."
  fi

  nslookup google.com &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "DNS resolution test using nslookup failed."
  else
    log "DNS resolution test using nslookup passed."
  fi
}

check_traceroute() {
  log "** Traceroute Test **"
  traceroute google.com &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "Traceroute test failed."
  else
    log "Traceroute test passed."
  fi
}

check_interface_status() {
  log "** Network Interface Status **"
  ip a &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "Failed to check network interface status."
  else
    log "Network interface status check passed."
  fi
}

check_routing_table() {
  log "** Routing Table Check **"
  netstat -rn &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "Failed to check routing table."
  else
    log "Routing table check passed."
  fi
}

check_arp_cache() {
  log "** ARP Cache Check **"
  arp -a &>> $REPORT_FILE
  if [[ $? -ne 0 ]]; then
    log_error "Failed to check ARP cache."
  else
    log "ARP cache check passed."
  fi
}

export -f log log_error check_ping check_dns_resolution check_traceroute check_interface_status check_routing_table check_arp_cache
export REPORT_FILE ERROR_FILE

if command -v parallel &> /dev/null; then
  log "GNU Parallel detected. Using parallel execution."
  parallel ::: check_ping check_dns_resolution check_traceroute check_interface_status check_routing_table check_arp_cache
else
  log "GNU Parallel not detected. Using background jobs."
  check_ping &
  check_dns_resolution &
  check_traceroute &
  check_interface_status &
  check_routing_table &
  check_arp_cache &

  wait
fi

log "\nNetwork troubleshooting completed. Check $REPORT_FILE for details and $ERROR_FILE for errors."

