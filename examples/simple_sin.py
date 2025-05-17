import time
import numpy as np

from ..awglib import verilog_consts as vc
from ..awglib import awglib

awg = awglib.awg()
theta = np.linspace(0, 2 * np.pi, 1000)
samples = np.sin(theta)
awg.send_volts(samples, trigger_mode=vc.TRIGGER_MODE_NONE, continuous=True)
time.sleep(30000)