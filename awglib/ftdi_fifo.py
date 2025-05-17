import os
import sys
import time
import signal
import numpy as np
import wire_format
from ctypes import CDLL

import verilog_consts as vc
import awglib
print(vc.TRIGGER_CMD_BIT)

def signal_handler(signum, frame):
    print("Received interrupt, terminating...")
    sys.exit(0)

def main():
    # setup_environment()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    awg = awglib.awg()
    theta = np.linspace(0, 2 * np.pi, 1000)
    samples = np.sin(theta)
    d0 = samples > 0.8
    d1 = samples < -0.5

    while True:
        print("sending")
        awg.send_volts(samples, digital=[d0, d1], trigger_mode=vc.TRIGGER_MODE_NONE, continuous=True)
        time.sleep(30000)

if __name__ == "__main__":
    main()
