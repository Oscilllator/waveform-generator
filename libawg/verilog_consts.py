# verilog_consts.py
import re
import os
from typing import Dict, Any

def parse_verilog_defines(file_path: str) -> Dict[str, Any]:
    with open(file_path, 'r') as file:
        content = file.read()
    lines = content.split('\n')

    trigger_modes = []
    constants = {}
    for line in lines:
        if line.startswith("//"): continue
        if not line.startswith("`define"): continue
        contents = line.split(" ")[1:]
        if len(contents) < 2: continue

        name = contents[0]
        vals = [x for x in contents[1:] if x != ""]
        assert len(vals) == 1
        val = vals[0]
        binary_match = re.match(r"(\d+)'b([01_]+)", val)
        if binary_match:
            bit_width, binary_str = binary_match.groups()
            binary_str = binary_str.replace('_', '')
            val = int(binary_str, 2)
        else:
            val = int(val)
        constants[name] = val
        if name.startswith("TRIGGER_MODE_"):
            trigger_modes.append(val)
    constants["all_triggers"] = set(trigger_modes)
    return constants

os.chdir(os.path.dirname(os.path.abspath(__file__)))
_constants = parse_verilog_defines("../rtl/awg/defines.v")
print("constants: ", _constants)
globals().update(_constants)

def const_to_string(const: int) -> str:
    for name, val in _constants.items():
        if val == const:
            return name
    return "Unknown constant"
# Usage example (in another file):
# import verilog_consts as vc
# print(vc.TRIGGER_CMD_BIT)

