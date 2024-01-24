#!/bin/bash

ping -c4 www.google.com -I eth0
let a=$?
if [ "$a" != "0" ]; then
  /sbin/shutdown -r +1 Connection lost, rebooting...
fi
