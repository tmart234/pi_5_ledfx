#!/usr/bin/env python3
import time
import mido
import logging
from pythonosc import dispatcher, osc_server

# --- Configuration ---
# IP address of the Raspberry Pi (listen on all interfaces)
IP_ADDRESS = "0.0.0.0"
# Port to listen for OSC messages on
OSC_PORT = 8000
# Name of the virtual MIDI port that LedFx will listen to
MIDI_PORT_NAME = 'LedFx_Controller'

# --- MIDI Mapping ---
# This dictionary maps OSC addresses from TouchOSC to MIDI Control Change (CC) numbers.
# You will map these CC numbers to sliders and knobs inside LedFx.
OSC_TO_MIDI_CC_MAP = {
    "/ledfx/master/brightness": 21,
    "/ledfx/bass/reactivity": 22,
    "/ledfx/mid/reactivity": 23,
    "/ledfx/high/reactivity": 24,
    "/ledfx/effect/speed": 25,
    "/ledfx/effect/blur": 26,
}

# --- Logging Setup ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# Global variable for our MIDI output port
midi_out_port = None

def handle_osc_to_midi_cc(address, *args):
    """
    Generic handler for OSC messages that need to be converted to MIDI CC.
    It expects one argument from OSC (a float between 0.0 and 1.0).
    """
    if not midi_out_port:
        return

    # Get the corresponding CC number from our map
    cc_number = OSC_TO_MIDI_CC_MAP.get(address)
    if cc_number is None:
        logging.warning(f"Received unmapped OSC address: {address}")
        return

    try:
        # OSC values are typically floats from 0.0 to 1.0.
        # MIDI CC values are integers from 0 to 127.
        osc_value = float(args[0])
        midi_value = int(osc_value * 127)

        # Create and send the MIDI message
        msg = mido.Message('control_change', control=cc_number, value=midi_value)
        midi_out_port.send(msg)
        logging.info(f"OSC '{address}' ({osc_value:.2f}) -> MIDI CC #{cc_number} ({midi_value})")

    except (ValueError, IndexError):
        logging.error(f"Invalid argument for OSC address {address}: {args}")

def main():
    """Main function to set up the OSC server and MIDI port."""
    global midi_out_port

    try:
        # Open the virtual MIDI port that LedFx will listen to.
        # On Linux, you may need to load the snd-virmidi kernel module first.
        midi_out_port = mido.open_output(MIDI_PORT_NAME, virtual=True)
        logging.info(f"Successfully opened virtual MIDI port '{MIDI_PORT_NAME}'")
    except Exception as e:
        logging.error(f"Could not open MIDI port. Is a virtual MIDI driver installed? Error: {e}")
        return

    # --- Setup OSC Dispatcher ---
    # Create a dispatcher to route incoming OSC messages.
    osc_dispatcher = dispatcher.Dispatcher()

    # Automatically map all the addresses from our dictionary to the handler function.
    for address in OSC_TO_MIDI_CC_MAP:
        osc_dispatcher.map(address, handle_osc_to_midi_cc)

    # --- Start OSC Server ---
    server = osc_server.ThreadingOSCUDPServer(
        (IP_ADDRESS, OSC_PORT), osc_dispatcher)
    logging.info(f"OSC Bridge started. Listening for commands on {server.server_address}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down OSC Bridge.")
    finally:
        server.server_close()
        midi_out_port.close()
        logging.info("MIDI port closed.")

if __name__ == "__main__":
    main()
