from .awglib import awg          # re-export the class
from . import verilog_consts      # optional, but convenient
__all__ = ["awg", "verilog_consts"]

