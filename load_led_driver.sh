#!/bin/bash

# This script is run by systemd after boot to load the WS281x driver.

DRIVER_DIR="/home/tmart234/rpi_ws281x/rp1_ws281x_pwm"

# Unload any potentially conflicting modules first.
dtoverlay -r pwm &> /dev/null || true
rmmod rp1_ws281x_pwm &> /dev/null || true

# Load our custom driver and configure the hardware.
insmod $DRIVER_DIR/rp1_ws281x_pwm.ko
dtoverlay -d $DRIVER_DIR rp1_ws281x_pwm
pinctrl set 18 a3 pn

echo "WS281x LED driver for Pi 5 loaded successfully."
