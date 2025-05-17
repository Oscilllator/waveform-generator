# This should set up the waveform generator ready for use.
# It does not program the eeprom of a fresh board, however.

sudo cp 99-awg.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "udev rules copied!"

