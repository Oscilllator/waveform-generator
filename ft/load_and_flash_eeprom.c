#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "ftd2xx.h"

#include "eeprom_funcs.h"


int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    const char *filename = argv[1];
    FT232H_DATA_WITH_STRINGS data_with_strings;
    FT_HANDLE ftHandle;
    FT_STATUS ftStatus;

    // Read the EEPROM data from the file
    FILE *file = fopen(filename, "rb");
    if (file == NULL) {
        printf("Failed to open file: %s\n", filename);
        return 1;
    }

    long filesize = ftell(file);
    fseek(file, 0, SEEK_SET);
    printf("File size: %ld bytes\n", filesize);
    printf("Struct size: %zu bytes\n", sizeof(FT232H_DATA_WITH_STRINGS));

    size_t read = fread(&data_with_strings, sizeof(FT232H_DATA_WITH_STRINGS), 1, file);

    fclose(file);

    if (read != 1) {
        printf("Failed to read EEPROM data from file, status: %d\n", (int)read);
        return 1;
    }


    printf("Contents of eeprom:");
    debug_print_ft_eeprom_232h(&data_with_strings.data);

    printf("\nString fields:\n");
    printf("Manufacturer: %s\n", data_with_strings.ManufacturerBuf);
    printf("ManufacturerId: %s\n", data_with_strings.ManufacturerIdBuf);
    printf("Description: %s\n", data_with_strings.DescriptionBuf);
    printf("SerialNumber: %s\n", data_with_strings.SerialNumberBuf);

    uint16_t vid = 0x1337;
    uint16_t pid = 0x0001;
    printf("Modifying vid to %d and pid to %d", vid, pid);
    data_with_strings.data.common.VendorId = vid;
    data_with_strings.data.common.ProductId = pid;

    // Open the device
    ftStatus = FT_SetVIDPID(0x1337, 0x0001);
    ftStatus = FT_Open(0, &ftHandle);
    // ftStatus = FT_OpenEx("FT232H", FT_OPEN_BY_DESCRIPTION, &ftHandle);
    if (ftStatus != FT_OK) {
        printf("Failed to open FTDI device (Status: %d)\n", (int)ftStatus);
        return 1;
    }

    // Program the EEPROM
    ftStatus = FT_EEPROM_Program(ftHandle,
                                 &data_with_strings.data,
                                 sizeof(data_with_strings.data),
                                 data_with_strings.ManufacturerBuf,
                                 data_with_strings.ManufacturerIdBuf,
                                 data_with_strings.DescriptionBuf,
                                 data_with_strings.SerialNumberBuf);
    if (ftStatus != FT_OK) {
        printf("Failed to program EEPROM (Status: %d)\n", (int)ftStatus);
        FT_Close(ftHandle);
        return 1;
    }

    printf("EEPROM successfully programmed\n");

    // Close the device
    FT_Close(ftHandle);

    return 0;
}