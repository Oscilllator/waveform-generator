#include <stdio.h>
#include <sys/time.h>
#include <string.h>
#include "ftd2xx.h"

// typedef struct program_data_with_strings {
//     FT_PROGRAM_DATA data;
//     char ManufacturerBuf[32];
//     char ManufacturerIdBuf[16];
//     char DescriptionBuf[64];
//     char SerialNumberBuf[16];
// } PROGRAM_DATA_WITH_STRINGS;

typedef struct ft232h_data_with_strings {
    FT_EEPROM_232H data;
    char ManufacturerBuf[32];
    char ManufacturerIdBuf[16];
    char DescriptionBuf[64];
    char SerialNumberBuf[16];
} FT232H_DATA_WITH_STRINGS;


void print_ft_program_data(FT_PROGRAM_DATA *data) {
    printf("Signature1: 0x%08X\n", data->Signature1);
    printf("Signature2: 0x%08X\n", data->Signature2);
    printf("Version: %d\n", data->Version);
    printf("VendorId: 0x%04X\n", data->VendorId);
    printf("ProductId: 0x%04X\n", data->ProductId);
    printf("Manufacturer: %s\n", data->Manufacturer);
    printf("ManufacturerId: %s\n", data->ManufacturerId);
    printf("Description: %s\n", data->Description);
    printf("SerialNumber: %s\n", data->SerialNumber);
    printf("MaxPower: %d\n", data->MaxPower);
    printf("PnP: %d\n", data->PnP);
    printf("SelfPowered: %d\n", data->SelfPowered);
    printf("RemoteWakeup: %d\n", data->RemoteWakeup);
    
    // Rev4 (FT232B) extensions
    printf("Rev4: %d\n", data->Rev4);
    printf("IsoIn: %d\n", data->IsoIn);
    printf("IsoOut: %d\n", data->IsoOut);
    printf("PullDownEnable: %d\n", data->PullDownEnable);
    printf("SerNumEnable: %d\n", data->SerNumEnable);
    printf("USBVersionEnable: %d\n", data->USBVersionEnable);
    printf("USBVersion: 0x%04X\n", data->USBVersion);
    
    // Rev 5 (FT2232) extensions
    printf("Rev5: %d\n", data->Rev5);
    printf("IsoInA: %d\n", data->IsoInA);
    printf("IsoInB: %d\n", data->IsoInB);
    printf("IsoOutA: %d\n", data->IsoOutA);
    printf("IsoOutB: %d\n", data->IsoOutB);
    printf("PullDownEnable5: %d\n", data->PullDownEnable5);
    printf("SerNumEnable5: %d\n", data->SerNumEnable5);
    printf("USBVersionEnable5: %d\n", data->USBVersionEnable5);
    printf("USBVersion5: 0x%04X\n", data->USBVersion5);
    printf("AIsHighCurrent: %d\n", data->AIsHighCurrent);
    printf("BIsHighCurrent: %d\n", data->BIsHighCurrent);
    printf("IFAIsFifo: %d\n", data->IFAIsFifo);
    printf("IFAIsFifoTar: %d\n", data->IFAIsFifoTar);
    printf("IFAIsFastSer: %d\n", data->IFAIsFastSer);
    printf("AIsVCP: %d\n", data->AIsVCP);
    printf("IFBIsFifo: %d\n", data->IFBIsFifo);
    printf("IFBIsFifoTar: %d\n", data->IFBIsFifoTar);
    printf("IFBIsFastSer: %d\n", data->IFBIsFastSer);
    printf("BIsVCP: %d\n", data->BIsVCP);
    
    // Rev 6 (FT232R) extensions
    printf("UseExtOsc: %d\n", data->UseExtOsc);
    printf("HighDriveIOs: %d\n", data->HighDriveIOs);
    printf("EndpointSize: %d\n", data->EndpointSize);
    printf("PullDownEnableR: %d\n", data->PullDownEnableR);
    printf("SerNumEnableR: %d\n", data->SerNumEnableR);
    printf("InvertTXD: %d\n", data->InvertTXD);
    printf("InvertRXD: %d\n", data->InvertRXD);
    printf("InvertRTS: %d\n", data->InvertRTS);
    printf("InvertCTS: %d\n", data->InvertCTS);
    printf("InvertDTR: %d\n", data->InvertDTR);
    printf("InvertDSR: %d\n", data->InvertDSR);
    printf("InvertDCD: %d\n", data->InvertDCD);
    printf("InvertRI: %d\n", data->InvertRI);
    printf("Cbus0: %d\n", data->Cbus0);
    printf("Cbus1: %d\n", data->Cbus1);
    printf("Cbus2: %d\n", data->Cbus2);
    printf("Cbus3: %d\n", data->Cbus3);
    printf("Cbus4: %d\n", data->Cbus4);
    printf("RIsD2XX: %d\n", data->RIsD2XX);
    
    // Rev 7 (FT2232H) Extensions
    printf("PullDownEnable7: %d\n", data->PullDownEnable7);
    printf("SerNumEnable7: %d\n", data->SerNumEnable7);
    printf("ALSlowSlew: %d\n", data->ALSlowSlew);
    printf("ALSchmittInput: %d\n", data->ALSchmittInput);
    printf("ALDriveCurrent: %d\n", data->ALDriveCurrent);
    printf("AHSlowSlew: %d\n", data->AHSlowSlew);
    printf("AHSchmittInput: %d\n", data->AHSchmittInput);
    printf("AHDriveCurrent: %d\n", data->AHDriveCurrent);
    printf("BLSlowSlew: %d\n", data->BLSlowSlew);
    printf("BLSchmittInput: %d\n", data->BLSchmittInput);
    printf("BLDriveCurrent: %d\n", data->BLDriveCurrent);
    printf("BHSlowSlew: %d\n", data->BHSlowSlew);
    printf("BHSchmittInput: %d\n", data->BHSchmittInput);
    printf("BHDriveCurrent: %d\n", data->BHDriveCurrent);
    printf("IFAIsFifo7: %d\n", data->IFAIsFifo7);
    printf("IFAIsFifoTar7: %d\n", data->IFAIsFifoTar7);
    printf("IFAIsFastSer7: %d\n", data->IFAIsFastSer7);
    printf("AIsVCP7: %d\n", data->AIsVCP7);
    printf("IFBIsFifo7: %d\n", data->IFBIsFifo7);
    printf("IFBIsFifoTar7: %d\n", data->IFBIsFifoTar7);
    printf("IFBIsFastSer7: %d\n", data->IFBIsFastSer7);
    printf("BIsVCP7: %d\n", data->BIsVCP7);
    printf("PowerSaveEnable: %d\n", data->PowerSaveEnable);
    
    // Rev 8 (FT4232H) Extensions
    printf("PullDownEnable8: %d\n", data->PullDownEnable8);
    printf("SerNumEnable8: %d\n", data->SerNumEnable8);
    printf("ASlowSlew: %d\n", data->ASlowSlew);
    printf("ASchmittInput: %d\n", data->ASchmittInput);
    printf("ADriveCurrent: %d\n", data->ADriveCurrent);
    printf("BSlowSlew: %d\n", data->BSlowSlew);
    printf("BSchmittInput: %d\n", data->BSchmittInput);
    printf("BDriveCurrent: %d\n", data->BDriveCurrent);
    printf("CSlowSlew: %d\n", data->CSlowSlew);
    printf("CSchmittInput: %d\n", data->CSchmittInput);
    printf("CDriveCurrent: %d\n", data->CDriveCurrent);
    printf("DSlowSlew: %d\n", data->DSlowSlew);
    printf("DSchmittInput: %d\n", data->DSchmittInput);
    printf("DDriveCurrent: %d\n", data->DDriveCurrent);
    printf("ARIIsTXDEN: %d\n", data->ARIIsTXDEN);
    printf("BRIIsTXDEN: %d\n", data->BRIIsTXDEN);
    printf("CRIIsTXDEN: %d\n", data->CRIIsTXDEN);
    printf("DRIIsTXDEN: %d\n", data->DRIIsTXDEN);
    printf("AIsVCP8: %d\n", data->AIsVCP8);
    printf("BIsVCP8: %d\n", data->BIsVCP8);
    printf("CIsVCP8: %d\n", data->CIsVCP8);
    printf("DIsVCP8: %d\n", data->DIsVCP8);
    
    // Rev 9 (FT232H) Extensions
    printf("PullDownEnableH: %d\n", data->PullDownEnableH);
    printf("SerNumEnableH: %d\n", data->SerNumEnableH);
    printf("ACSlowSlewH: %d\n", data->ACSlowSlewH);
    printf("ACSchmittInputH: %d\n", data->ACSchmittInputH);
    printf("ACDriveCurrentH: %d\n", data->ACDriveCurrentH);
    printf("ADSlowSlewH: %d\n", data->ADSlowSlewH);
    printf("ADSchmittInputH: %d\n", data->ADSchmittInputH);
    printf("ADDriveCurrentH: %d\n", data->ADDriveCurrentH);
    printf("Cbus0H: %d\n", data->Cbus0H);
    printf("Cbus1H: %d\n", data->Cbus1H);
    printf("Cbus2H: %d\n", data->Cbus2H);
    printf("Cbus3H: %d\n", data->Cbus3H);
    printf("Cbus4H: %d\n", data->Cbus4H);
    printf("Cbus5H: %d\n", data->Cbus5H);
    printf("Cbus6H: %d\n", data->Cbus6H);
    printf("Cbus7H: %d\n", data->Cbus7H);
    printf("Cbus8H: %d\n", data->Cbus8H);
    printf("Cbus9H: %d\n", data->Cbus9H);
    printf("IsFifoH: %d\n", data->IsFifoH);
    printf("IsFifoTarH: %d\n", data->IsFifoTarH);
    printf("IsFastSerH: %d\n", data->IsFastSerH);
    printf("IsFT1248H: %d\n", data->IsFT1248H);
    printf("FT1248CpolH: %d\n", data->FT1248CpolH);
    printf("FT1248LsbH: %d\n", data->FT1248LsbH);
    printf("FT1248FlowControlH: %d\n", data->FT1248FlowControlH);
    printf("IsVCPH: %d\n", data->IsVCPH);
    printf("PowerSaveEnableH: %d\n", data->PowerSaveEnableH);
}

void debug_print_ft_eeprom_232h(const FT_EEPROM_232H *eeprom) {
    printf("FT_EEPROM_232H Debug Information:\n");
    printf("================================\n\n");

    // Print FT_EEPROM_HEADER fields
    printf("Common Header (FT_EEPROM_HEADER):\n");
    printf("  deviceType: %d\n", eeprom->common.deviceType);
    printf("  VendorId: 0x%04X\n", eeprom->common.VendorId);
    printf("  ProductId: 0x%04X\n", eeprom->common.ProductId);
    printf("  SerNumEnable: %d\n", eeprom->common.SerNumEnable);
    printf("  MaxPower: %d\n", eeprom->common.MaxPower);
    printf("  SelfPowered: %d\n", eeprom->common.SelfPowered);
    printf("  RemoteWakeup: %d\n", eeprom->common.RemoteWakeup);
    printf("  PullDownEnable: %d\n", eeprom->common.PullDownEnable);

    // Print FT_EEPROM_232H specific fields
    printf("\nFT_EEPROM_232H Specific Fields:\n");
    printf("  ACSlowSlew: %d\n", eeprom->ACSlowSlew);
    printf("  ACSchmittInput: %d\n", eeprom->ACSchmittInput);
    printf("  ACDriveCurrent: %d\n", eeprom->ACDriveCurrent);
    printf("  ADSlowSlew: %d\n", eeprom->ADSlowSlew);
    printf("  ADSchmittInput: %d\n", eeprom->ADSchmittInput);
    printf("  ADDriveCurrent: %d\n", eeprom->ADDriveCurrent);

    // CBUS options
    printf("  Cbus0: %d\n", eeprom->Cbus0);
    printf("  Cbus1: %d\n", eeprom->Cbus1);
    printf("  Cbus2: %d\n", eeprom->Cbus2);
    printf("  Cbus3: %d\n", eeprom->Cbus3);
    printf("  Cbus4: %d\n", eeprom->Cbus4);
    printf("  Cbus5: %d\n", eeprom->Cbus5);
    printf("  Cbus6: %d\n", eeprom->Cbus6);
    printf("  Cbus7: %d\n", eeprom->Cbus7);
    printf("  Cbus8: %d\n", eeprom->Cbus8);
    printf("  Cbus9: %d\n", eeprom->Cbus9);

    // FT1248 options
    printf("  FT1248Cpol: %d\n", eeprom->FT1248Cpol);
    printf("  FT1248Lsb: %d\n", eeprom->FT1248Lsb);
    printf("  FT1248FlowControl: %d\n", eeprom->FT1248FlowControl);

    // Hardware options
    printf("  IsFifo: %d\n", eeprom->IsFifo);
    printf("  IsFifoTar: %d\n", eeprom->IsFifoTar);
    printf("  IsFastSer: %d\n", eeprom->IsFastSer);
    printf("  IsFT1248: %d\n", eeprom->IsFT1248);
    printf("  PowerSaveEnable: %d\n", eeprom->PowerSaveEnable);

    // Driver option
    printf("  DriverType: %d\n", eeprom->DriverType);
}

void print_ft232h(FT232H_DATA_WITH_STRINGS *data) {
    printf("Manufacturer: %s\n", data->ManufacturerBuf);
    printf("ManufacturerId: %s\n", data->ManufacturerIdBuf);
    printf("Description: %s\n", data->DescriptionBuf);
    printf("SerialNumber: %s\n", data->SerialNumberBuf);
    debug_print_ft_eeprom_232h(&data->data);
}