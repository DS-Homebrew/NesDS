#ifndef _multi_nesds__
#define _multi_nesds__

#include "../../common/wifi_shared.h"

#include <nds.h>

#endif

#ifdef __cplusplus
extern "C"{
#endif

extern Wifi_MainStruct Wifi_Data_Struct;
extern WifiSyncHandler synchandler;
extern volatile Wifi_MainStruct * WifiData;
extern int Wifi_RawTxFrameNIFI(u16 datalen, u16 rate, u16 * data);
extern void Handler(int packetID, int readlength);

#ifdef __cplusplus
}
#endif
