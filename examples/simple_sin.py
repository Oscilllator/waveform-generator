import time
import numpy as np

import awglib
from awglib import verilog_consts as vc

awg = awglib.awg()
theta = np.linspace(0, 2 * np.pi, 1000)
samples = np.sin(theta)
awg.send_volts(samples, trigger_mode=vc.TRIGGER_MODE_NONE, continuous=True)
time.sleep(30000)