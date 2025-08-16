#!/bin/bash

# ==============================================================================
#      Pi 5 Mobile Lighting Rig - Wi-Fi Hotspot & OSC Setup Script
# ==============================================================================
# This script configures the Raspberry Pi to act as a standalone Wi-Fi hotspot,
# allowing a phone with TouchOSC to connect directly for control.
# It also installs the necessary Python libraries for OSC communication.
#
# USAGE:
# 1. Run the main 'install_and_test.sh' script first to set up the core system.
# 2. Run this script WITHOUT sudo: ./setup_hotspot.sh
# 3. Reboot when prompted.
# ==============================================================================

# Exit immediately if any command fails.
set -e

# --- Configuration ---
# You can change these values if you like
WIFI_SSID="Pi_LED_Control"
WIFI_PASS="lightsOn" # Must be at least 8 characters
PI_IP="192.168.4.1"

echo "--- Starting Wi-Fi Hotspot and OSC Setup ---"

# --- Step 1: Install Hotspot and DHCP Software ---
echo "--> Installing hostapd and dnsmasq..."
sudo apt-get update
sudo apt-get install -y hostapd dnsmasq

# --- Step 2: Configure a Static IP for the Pi ---
echo "--> Configuring static IP for wlan0..."
# We append our configuration to the dhcpcd config file
sudo tee -a /etc/dhcpcd.conf > /dev/null <<EOF

# Configuration for Wi-Fi Hotspot
interface wlan0
static ip_address=${PI_IP}/24
nohook wpa_supplicant
EOF

# --- Step 3: Configure the DHCP Server (dnsmasq) ---
echo "--> Configuring DHCP server (dnsmasq)..."
# Create a new config file for our hotspot
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

# --- Step 4: Configure the Hotspot (hostapd) ---
echo "--> Configuring the hotspot (hostapd)..."
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=wlan0
driver=nl80211
ssid=${WIFI_SSID}
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=${WIFI_PASS}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Tell the system where to find our new hostapd config file
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# --- Step 5: Install Python OSC Library ---
echo "--> Installing python-osc into the ledfx virtual environment..."
source $HOME/ledfx_venv/bin/activate
pip install python-osc
deactivate
echo "OSC library installed."

# --- Step 6: Unblock Wi-Fi and Enable Services ---
echo "--> Enabling services and unblocking Wi-Fi..."
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl unmask dnsmasq
sudo systemctl enable dnsmasq

# --- Step 7: Final Instructions ---
echo ""
echo "--- HOTSPOT SETUP COMPLETE ---"
echo ""
echo "The system is now configured to create its own Wi-Fi network on boot."
echo "Please REBOOT now to apply all changes: sudo reboot"
echo ""
echo "Before rebooting:"
echo "sudo systemctl stop wpa_supplicant.service"
echo "sudo systemctl disable wpa_supplicant.service"
echo "After rebooting:"
echo "1. On your phone, connect to the Wi-Fi network named: '${WIFI_SSID}'"
echo "2. The password is: '${WIFI_PASS}'"
echo "3. In your TouchOSC app, set the 'Host' IP address to: '${PI_IP}'"
echo ""
