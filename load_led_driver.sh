#!/bin/bash

# This script is run by systemd after boot to load the WS281x driver.

# THE DEFINITIVE FIX: Wait 5 seconds for the system to fully initialize.
sleep 5

DRIVER_DIR="/home/tmart234/rpi_ws281x/rp1_ws281x_pwm"

# Unload any potentially conflicting modules first.
dtoverlay -r pwm &> /dev/null || true
rmmod rp1_ws281x_pwm &> /dev/null || true

# Now, load our driver and overlay onto the free hardware.
insmod $DRIVER_DIR/rp1_ws281x_pwm.ko
dtoverlay rp1_ws281x_pwm
pinctrl set 18 a3 pn

echo "WS281x LED driver loaded for Pi 5."
