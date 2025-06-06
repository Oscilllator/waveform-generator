# Why does it exist

The purpose of this waveform generator is to give your computer the ability to make waves. It should be thought of as a waveform interface for your computer, like a network interface or an audio interface. The computer streams waveforms continuously to the generator, the generator itself has no memory.
I created this because I don't like the software interface to any other waveform generator I have used.

You use it like this:
```python
import numpy as np
import awglib
awg = awglib.awg()
samples = np.sin(np.linspace(0, 2 * np.pi, 1000))
awg.send_volts(samples)
```

You can simply stream samples to it, or gate the sending of the samples on a trigger input. It also has two digital outputs which are embedded in the sample stream. You can use them like this:

```python
samples = np.sin(np.linspace(0, 2 * np.pi, 1000))
d0 = samples > 0.8
d1 = samples < -0.5
awg.send_volts(samples, digital=[d0, d1])
```

Which then would look like this:
![image](https://raw.githubusercontent.com/Oscilllator/waveform-generator/refs/heads/main/docs/2025-04-05_16-04.png)

This is useful for triggering your scope or other instruments.


## Specifications
| Parameter           | Value    |
|---------------------|----------|
| Samples rate        | 10 MSa/s |
| Rise/fall time      | 50 ns    |
| Max output current  | 600 mA   |
| Resolution          | 14 bit   |
| Digital outputs     | 2        |

The device also has a 16 bit digital output bus for debugging the fpga, and 8 LED's. The digital outputs come straight from the FPGA and so have no drive strength to speak of. You won't blow up the FPGA if you 50R terminate them, though.

It looks like this:

![image](https://raw.githubusercontent.com/Oscilllator/waveform-generator/refs/heads/main/docs/2025-04-05_18-04.png)

## Examples

### Scrolling text

This example is `examples/scrolling_text.py` and demonstrates some of the benefits of having a streaming setup - there is a lot of memory on your main computer as compared to any reasonable waveform generator.

This whole gif is one single waveform of about ~500MB over the wire. Several passes are made over the text, one for each letter section. The persistence of vision within the oscilloscope stitches them together, producing whole letters. Once the whole text has been emitted the waveform is then re-emitted with the embedded digital trigger pulse sent with a slightly different time delay. This is easily done by simply concatenating the waveform to itself many times, attaching a shifted version of the trigger array each time. This wastes a lot of memory but was trivial to implement.


![demo](docs/text_scroll.webp)

## Setup
### From a new computer
#### Udev rules
The USB chip is a FT232, but I have programmed it to have a custom Vid and Pid, so that the linux kernel doesn't grab it.

This script sets up the udev rules so the device can be opened without root:

```./ft/setup.sh```
#### Python library
I install it like this from the root directory of the repository:

```pip install -e .```

That way the library is loaded from the repository on startup rather than being copied to an install directory. Ask your favourite AI what's right for you.

### From a bare PCB
The EEPROM of the FT2332 needs to be programmed so that it will output in synchronous FIFO mode, and so that the default vendor ID and product ID is changed, preventing the linux kernel from recognising it.

```./program_eeprom.sh```

## Repository contents
This repository contains the kicad files, RTL, and API to operate a waveform generator.

### Hardware
I got the PCB's assembled with JLCPCB's 6 layer service with plated over vias, to make the routing of the FPGA BGA package easy.
The device uses an FT232 as a USB->FIFO adapter, that currently streams exclusively in the PC->FT232 direction. Use of the device in this mode requires flashing the eeprom, for which a utility is also included.

### RTL
The Flow of information is as follows:

PC -> FT232 -> ECP5 FPGA -> AD9744 DAC -> Amplifier

The RTL for the fpga is provided, which uses the excellent repository [here](https://github.com/WangXuan95/FPGA-ftdi245fifo/tree/main?tab=readme-ov-file#cn) to interface with the FT232. The AD9744 has a simple parallel interface, so that also makes things easy.

The simulation can be run as a unit test with `./run_tests.sh`

### API
The waveform generator is interfaces with in python, though I may [port it to C](https://harrydb.com/Continuous-waveforms) at some point.

### Bringup notes

This device was designed as a series of sub-boards. It started as a [Colorlight DAC](https://harrydb.com/20240902-A-good-waveform-generator) dev board and the [amplifier stage](https://harrydb.com/20250103-awg-buffer-bringup). These were then merged into a [Single PCB](https://harrydb.com/20250403-AWG-2-bringup). There are [various other notes](https://harrydb.com/#waveform-generator) on my lab notes page that detail other parts of the design process.

