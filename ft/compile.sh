gcc -Wall -Werror -o load_and_flash_eeprom load_and_flash_eeprom.c -L./build -lftd2xx -I../../.. -Wl,-rpath,../../../build
