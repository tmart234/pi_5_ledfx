import time
from rpi_ws281x import PixelStrip, Color

# --- LED Strip Configuration ---
LED_COUNT = 180        # Number of LED pixels.
LED_PIN = 18           # GPIO pin connected to the pixels (18 uses PWM).
LED_FREQ_HZ = 800000   # LED signal frequency in hertz (usually 800khz)
LED_DMA = 10           # DMA channel to use for generating signal (try 10)
LED_BRIGHTNESS = 128   # Set to 0 for darkest and 255 for brightest
LED_INVERT = False     # True to invert the signal (when using NPN transistor level shift)
LED_CHANNEL = 0        # set to '1' for GPIOs 13, 19, 41, 45 or 53

def color_wipe(strip, color, wait_ms=50):
    """Wipe color across display a pixel at a time."""
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, color)
        strip.show()
        time.sleep(wait_ms / 1000.0)

def test_all_pixels(strip):
    """A simple test to confirm all pixels are working."""
    print('Testing all pixels...')
    
    print('Setting all pixels to RED...')
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(255, 0, 0)) # Red
    strip.show()
    time.sleep(2)

    print('Setting all pixels to GREEN...')
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 255, 0)) # Green
    strip.show()
    time.sleep(2)

    print('Setting all pixels to BLUE...')
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 0, 255)) # Blue
    strip.show()
    time.sleep(2)
    
    print('Turning all pixels OFF...')
    for i in range(strip.numPixels()):
        strip.setPixelColor(i, Color(0, 0, 0)) # Off
    strip.show()
    
    print('Test complete.')

# --- Main Execution ---
if __name__ == '__main__':
    # Create PixelStrip object with appropriate configuration.
    strip = PixelStrip(LED_COUNT, LED_PIN, LED_FREQ_HZ, LED_DMA, LED_INVERT, LED_BRIGHTNESS, LED_CHANNEL)
    # Intialize the library (must be called once before other functions).
    strip.begin()

    print('Press Ctrl-C to quit.')
    try:
        test_all_pixels(strip)

    except KeyboardInterrupt:
        # Turn off all pixels on exit
        for i in range(strip.numPixels()):
            strip.setPixelColor(i, Color(0,0,0))
        strip.show()
