#!/bin/bash

# ==============================================================================
#      Definitive Pi 5 WS2812B Installation & Test Script (v30 - Final)
# ==============================================================================
# This script uses the official config.txt method for driver persistence.
#
# USAGE:
# 1. Save this script as install_and_test.sh in your home directory.
# 2. Make it executable: chmod +x install_and_test.sh
# 3. Run it WITHOUT sudo: ./install_and_test.sh
# ==============================================================================

# Prevent the script from being run as root.
if [ "$EUID" -eq 0 ]; then
  echo "ERROR: This script must NOT be run with sudo or as the root user."
  echo "Please run it as your normal user: ./install_and_test.sh"
  exit 1
fi

# Exit immediately if any command fails.
set -e

# Get the script's own directory to use absolute paths later.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "--- Starting Definitive Pi 5 LED Installation ---"

# --- STEP 1: PURGE PREVIOUS ATTEMPTS ---
echo "--> Removing any old source folders and service files..."
deactivate &> /dev/null || true
sudo systemctl disable led-driver-loader.service &> /dev/null || true
sudo rm -f /etc/systemd/system/led-driver-loader.service
sudo rm -f /usr/local/bin/load_led_driver.sh
sudo rm -rf $HOME/ledfx_venv
sudo rm -rf $HOME/rpi_ws281x
sudo rm -rf $HOME/rpi-ws281x-python
echo "Purge complete."

# --- STEP 2: INSTALL SYSTEM DEPENDENCIES ---
echo "--> Updating system and installing build tools..."
sudo apt-get update
sudo apt-get install -y git cmake python3-pip python3-venv scons device-tree-compiler

# --- STEP 3: BUILD & INSTALL THE CORE C LIBRARY ---
echo "--> Cloning and building the core C library..."
cd $HOME
git clone https://github.com/jgarff/rpi_ws281x.git
cd rpi_ws281x
git checkout pi5
sed -i '/.desc = "Pi 5 Model B - 4GB 1.0"/a \ \ \ \ {\
        .hwver  = 0xd04171,\
        .type = RPI_HWVER_TYPE_PI5,\
        .periph_base = 0,           \
        .videocore_base = 0,        \
        .desc = "Pi 5 Model B Rev 1.1 - 8GB",\
    },' rpihw.c
mkdir build
cd build
cmake ..
make
sudo make install
echo "C library installed."

# --- STEP 4: PATCH & BUILD THE KERNEL MODULE ---
echo "--> Patching and building the Pi 5 kernel module..."
cd $HOME/rpi_ws281x/rp1_ws281x_pwm
sed -i '111i\
//---\
void rp1_ws281x_pwm_chan(int channel, int invert);\
void rp1_ws281x_pwm_init(int channel, int invert);\
void rp1_ws281x_pwm_cleanup(void);\
int rp1_ws281x_pwm_open(struct inode *inode, struct file *file);\
int rp1_ws281x_pwm_release(struct inode *inode, struct file *file);\
long rp1_ws281x_pwm_ioctl(struct file *file, unsigned int cmd, unsigned long arg);\
void rp1_ws281x_dma_callback(void *param);\
ssize_t rp1_ws281x_dma(const char *buf, ssize_t len);\
ssize_t rp1_ws281x_pwm_write(struct file *file, const char *buf, size_t total, loff_t *loff);\
int rp1_ws281x_pwm_probe(struct platform_device *pdev);\
void rp1_ws281x_pwm_remove(struct platform_device *pdev);\
//---' rp1_ws281x_pwm.c
sed -i 's/int rp1_ws281x_pwm_remove(struct platform_device \*pdev)/void rp1_ws281x_pwm_remove(struct platform_device *pdev)/' rp1_ws281x_pwm.c
sed -i '/void rp1_ws281x_pwm_remove(struct platform_device \*pdev)/,/}/ s/return 0;/return;/' rp1_ws281x_pwm.c
make
./dts.sh
echo "Kernel module and overlay built successfully."

# --- STEP 5: CREATE VENV & INSTALL PYTHON WRAPPER ---
echo "--> Creating Python virtual environment and installing wrapper..."
cd $HOME
python3 -m venv ledfx_venv
source $HOME/ledfx_venv/bin/activate
git clone https://github.com/rpi-ws281x/rpi-ws281x-python.git
cd rpi-ws281x-python
git checkout pi5
git submodule update --init
cd library/lib
git checkout pi5
cd ../..
cd library
sudo $HOME/ledfx_venv/bin/python setup.py install
deactivate
echo "Python wrapper installed into the virtual environment."

# --- STEP 6: CONFIGURE SYSTEM FOR BOOT ---
echo "--> Configuring system to load driver on boot..."
# Copy the compiled overlay to the system directory
sudo cp $HOME/rpi_ws281x/rp1_ws281x_pwm/rp1_ws281x_pwm.dtbo /boot/firmware/overlays/

# Remove any old conflicting entries from config.txt
sudo sed -i '/^dtoverlay=rp1_ws281x_pwm/d' /boot/firmware/config.txt
sudo sed -i '/^dtoverlay=ws281x/d' /boot/firmware/config.txt

# Add the new, correct overlay to the end of config.txt
echo "dtoverlay=rp1_ws281x_pwm" | sudo tee -a /boot/firmware/config.txt
echo "Boot configuration updated."

# --- STEP 7: FINAL INSTRUCTIONS ---
echo ""
echo "--- INSTALLATION COMPLETE ---"
echo ""
echo "The system is now fully installed and configured to load the driver on boot."
echo "Please REBOOT now to apply all changes: sudo reboot"
echo ""
echo "After rebooting, the driver will be loaded automatically. You can test your lights with:"
echo "sudo $HOME/ledfx_venv/bin/python $SCRIPT_DIR/hw_test.py"
echo ""

