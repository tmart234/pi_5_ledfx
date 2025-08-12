#!/bin/bash

# This script is run at boot by the systemd service to load the custom
# kernel module and configure the GPIO pin for the WS2812B LEDs.

# Use absolute paths to ensure commands work regardless of working directory
DRIVER_DIR="/home/$PI_USER/rpi_ws281x/rp1_ws281x_pwm"

# Unload any old module first to ensure a clean state.
rmmod rp1_ws281x_pwm &> /dev/null || true

# Load the new driver and configure the hardware
insmod $DRIVER_DIR/rp1_ws281x_pwm.ko
dtoverlay rp1_ws281x_pwm
pinctrl set 18 a3 pn

echo "WS281x LED driver loaded for Pi 5."
