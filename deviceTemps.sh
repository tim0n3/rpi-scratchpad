#!/usr/bin/env bash
# Script: deviceTemps.sh
# Purpose: Display the ARM CPU and temperature of Raspberry Pi 2/3/4
# -------------------------------------------------------
#
#!/bin/bash

# Global variables for log files
stdout_log="stdout.log"
stderr_log="stderr.log"
error_log="error.log"

# Function to redirect standard error (stderr) to a specified log file with timestamps and "[ERROR]" prefix.
log_stderr() {
	exec 2> >(while IFS= read -r line; do
	echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $line" >> "$error_log"
done)
}

# Function to redirect standard output (stdout) to a specified log file with timestamps and "[INFO]" prefix.
log_stdout() {
	exec > >(while IFS= read -r line; do
	echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $line" >> "$stdout_log"
done)
}

# Function to capture the exit code of the last command, log it, and print a stack trace before exiting.
exit_code() {
	local exit_code=$?

	if [ $exit_code -ne 0 ]; then
		# Redirect stderr to stdout for consistent logging.
		exec 2>&1
		echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] Exit code: $exit_code" >> "$error_log"

		# Print a stack trace or debug trace.
		echo "Stack trace:"
		local frame=0
		while caller $frame; do
			((frame++))
		done
		# Exit with the captured exit code.
		exit $exit_code
	fi
}

# Function to test if a file exists, log errors, and handle exit codes accordingly.
check_file_existence() {
	local file_path="$1"

	if [ -e "$file_path" ]; then
		# If the file exists, redirect stdout to the specified log file.
		log_stdout
	else
		# If the file doesn't exist, redirect stderr to the specified log file, log an error, and exit with an error code.
		log_stderr
		echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] File not found: $file_path" >> "$stderr_log"
		exit_code
	fi
}

# Usage example with proper redirections
file_path="/sys/class/thermal/thermal_zone0/temp"
gpu_file_path=$(which vcgencmd) 

# Check if the file exists before attempting to read its contents
check_file_existence "$file_path"
check_file_existence "$gpu_file_path" 

# Read CPU temperature
cpu=$(<"$file_path")

# Testing GPU utility... Probably not gonna make it into the \
# final product but will test on an old RPI pre-Buster install.
# Looks like you can install command-line utility \
# that allows you to communicate with the VideoCore GPU.
# You can install it with pip3 install setuptools \
# and pip3 install vcgencmd
# GPU temperature util
gpu=$(vcgencmd measure_temp)

# Output information
echo "$(date '+%Y-%m-%d %H:%M:%S') @ $(hostname)"
echo "-------------------------------------------"
echo "CPU => $((cpu/1000)) C" || exit_code
echo "GPU => $gpu" || exit_code
