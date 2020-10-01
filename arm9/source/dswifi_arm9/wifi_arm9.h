// DS Wifi interface code
// Copyright (C) 2005-2006 Stephen Stair - sgstair@akkit.org - http://www.akkit.org
// wifi_arm9.c - arm9 wifi support header
/****************************************************************************** 
DSWifi Lib and test materials are licenced under the MIT open source licence:
Copyright (c) 2005-2006 Stephen Stair

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
******************************************************************************/


#ifndef WIFI_ARM9_H
#define WIFI_ARM9_H


#include <nds/ndstypes.h>
#include "../../../common/wifi_shared.h"

#define SGIP_DEBUG_MESSAGE(param) 
#define SGIP_DEBUG_ERROR(param)

#ifdef WIFI_USE_TCP_SGIP


// Wifi Packet Handler function: (int packetID, int packetlength) - packetID is only valid while the called function is executing.
// call Wifi_RxRawReadPacket while in the packet handler function, to retreive the data to a local buffer.
typedef void (*WifiPacketHandler)(int, int);

// Wifi Sync Handler function: Callback function that is called when the arm7 needs to be told to synchronize with new fifo data.
// If this callback is used (see Wifi_SetSyncHandler()), it should send a message via the fifo to the arm7, which will call Wifi_Sync() on arm7.
typedef void (*WifiSyncHandler)();
#endif


#ifdef __cplusplus
extern "C" {
#endif


extern volatile Wifi_MainStruct * WifiData;
extern WifiSyncHandler synchandler;

extern void Wifi_CopyMacAddr(volatile void * dest, volatile void * src);
extern int Wifi_CmpMacAddr(volatile void * mac1, volatile void * mac2);

extern unsigned long Wifi_Init(int initflags);
extern bool Wifi_InitDefaultCustom(bool useFirmwareSettings);
extern int Wifi_CheckInit();

extern int Wifi_RawTxFrame(u16 datalen, u16 rate, u16 * data);
extern void Wifi_SetSyncHandler(WifiSyncHandler wshfunc);
extern void Wifi_RawSetPacketHandler(WifiPacketHandler wphfunc);
extern int Wifi_RxRawReadPacket(s32 packetID, s32 readlength, u16 * data);

extern void Wifi_DisableWifi();
extern void Wifi_EnableWifi();
extern void Wifi_SetPromiscuousMode(int enable);
extern void Wifi_ScanMode();
extern void Wifi_SetChannel(int channel);

extern int Wifi_GetNumAP();
extern int Wifi_GetAPData(int apnum, Wifi_AccessPoint * apdata);
extern int Wifi_FindMatchingAP(int numaps, Wifi_AccessPoint * apdata, Wifi_AccessPoint * match_dest);
extern int Wifi_ConnectAP(Wifi_AccessPoint * apdata, int wepmode, int wepkeyid, u8 * wepkey);
extern void Wifi_AutoConnect();

extern int Wifi_AssocStatus();
extern int Wifi_DisconnectAP();
extern int Wifi_GetData(int datatype, int bufferlen, unsigned char * buffer);


extern void Wifi_Update();
extern void Wifi_Sync();


#ifdef WIFI_USE_TCP_SGIP
extern void Wifi_Timer(int num_ms);
extern void Wifi_SetIP(u32 IPaddr, u32 gateway, u32 subnetmask, u32 dns1, u32 dns2);
extern u32 Wifi_GetIP();
#endif

extern int Wifi_RawTxFrame_NIFI(u16 datalen, u16 rate, u16 * data);
extern void arm9_synctoarm7Custom();
extern void Timer_50ms(void);
#ifdef __cplusplus
}
#endif

#endif