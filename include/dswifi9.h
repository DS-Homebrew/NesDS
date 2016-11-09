// DSWifi Project - Arm9 Library Header File (dswifi9.h)
// Copyright (C) 2005-2006 Stephen Stair - sgstair@akkit.org - http://www.akkit.org
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

#ifndef DSWIFI9_H
#define DSWIFI9_H

#include "dswifi_version.h"
#include "wifi_shared.h"

// well, some flags and stuff are just stuffed in here and not documented very well yet... Most of the important stuff is documented though.
// Next version should clean up some of this a lot more :)

#define WIFIINIT_OPTION_USELED		   0x0002

// default option is to use 64k heap
#define WIFIINIT_OPTION_USEHEAP_64     0x0000
#define WIFIINIT_OPTION_USEHEAP_128    0x1000
#define WIFIINIT_OPTION_USEHEAP_256    0x2000
#define WIFIINIT_OPTION_USEHEAP_512    0x3000
#define WIFIINIT_OPTION_USECUSTOMALLOC 0x4000
#define WIFIINIT_OPTION_HEAPMASK       0xF000

#define WFLAG_PACKET_DATA		0x0001
#define WFLAG_PACKET_MGT		0x0002
#define WFLAG_PACKET_BEACON		0x0004
#define WFLAG_PACKET_CTRL		0x0008

#define WFLAG_PACKET_ALL		0xFFFF


#define WFLAG_APDATA_ADHOC			0x0001
#define WFLAG_APDATA_WEP			0x0002
#define WFLAG_APDATA_WPA			0x0004
#define WFLAG_APDATA_COMPATIBLE		0x0008
#define WFLAG_APDATA_EXTCOMPATIBLE	0x0010
#define WFLAG_APDATA_SHORTPREAMBLE	0x0020
#define WFLAG_APDATA_ACTIVE			0x8000








extern const char * ASSOCSTATUS_STRINGS[];



#ifdef __cplusplus
extern "C" {
#endif

//////////////////////////////////////////////////////////////////////////
// Init/update/state management functions

// Wifi_Init: Initializes the wifi library (arm9 side) and the sgIP library.
//  int initflags: set up some optional things, like controlling the LED blinking.
//  Returns: a 32bit value that *must* be passed to arm7.
extern unsigned long Wifi_Init(int initflags);

// Wifi_CheckInit: Verifies when the ARM7 has been successfully initialized
//  Returns: 1 if the arm7 is ready for wifi, 0 otherwise
extern int Wifi_CheckInit();

// Wifi_DisableWifi: Instructs the ARM7 to disengage wireless and stop receiving or
//   transmitting.
extern void Wifi_DisableWifi();

// Wifi_EnableWifi: Instructs the ARM7 to go into a basic "active" mode, not actually
//   associated to an AP, but actively receiving and potentially transmitting
extern void Wifi_EnableWifi();

// Wifi_SetPromiscuousMode: Allows the DS to enter or leave a "promsicuous" mode, in which
//   all data that can be received is forwarded to the arm9 for user processing.
//   Best used with Wifi_RawSetPacketHandler, to allow user code to use the data
//   (well, the lib won't use 'em, so they're just wasting CPU otherwise.)
//  int enable:  0 to disable promiscuous mode, nonzero to engage
extern void Wifi_SetPromiscuousMode(int enable);

// Wifi_ScanMode: Instructs the ARM7 to periodically rotate through the channels to
//   pick up and record information from beacons given off by APs
extern void Wifi_ScanMode();

// Wifi_SetChannel: If the wifi system is not connected or connecting to an access point, instruct
//   the chipset to change channel
//  int channel: the channel to change to, in the range of 1-13
extern void Wifi_SetChannel(int channel);

// Wifi_GetNumAP:
//  Returns: the current number of APs that are known about and tracked internally
extern int Wifi_GetNumAP();

// Wifi_GetAPData: Grabs data from internal structures for user code (always succeeds)
//  int apnum:					the 0-based index of the access point record to fetch
//  Wifi_AccessPoint * apdata:	Pointer to the location where the retrieved data should be stored
extern int Wifi_GetAPData(int apnum, Wifi_AccessPoint * apdata);

// Wifi_FindMatchingAP: determines whether various APs exist in the local area. You provide a
//   list of APs, and it will return the index of the first one in the list that can be found
//   in the internal list of APs that are being tracked
//  int numaps:					number of records in the list
//  Wifi_AccessPoint * apdata:	pointer to an array of structures with information about the APs to find
//  Wifi_AccessPoint * match_dest:	OPTIONAL pointer to a record to receive the matching AP record.
//  Returns:					-1 for none found, or a positive/zero integer index into the array
extern int Wifi_FindMatchingAP(int numaps, Wifi_AccessPoint * apdata, Wifi_AccessPoint * match_dest);

// Wifi_ConnectAP: Connect to an access point
//  Wifi_AccessPoint * apdata:	basic data on the AP
//  int wepmode:				indicates whether wep is used, and what kind
//  int wepkeyid:				indicates which wep key ID to use for transmitting
//  unsigned char * wepkey:		the wep key, to be used in all 4 key slots (should make this more flexible in the future)
//  Returns:					0 for ok, -1 for error with input data
extern int Wifi_ConnectAP(Wifi_AccessPoint * apdata, int wepmode, int wepkeyid, unsigned char * wepkey);

// Wifi_AutoConnect: Connect to an access point specified by the WFC data in the firmware
extern void Wifi_AutoConnect();

// Wifi_AssocStatus: Returns information about the status of connection to an AP
//  Returns: a value from the WIFI_ASSOCSTATUS enum, continue polling until you
//            receive ASSOCSTATUS_CONNECTED or ASSOCSTATUS_CANNOTCONNECT
extern int Wifi_AssocStatus();

// Wifi_DisconnectAP: Disassociate from the Access Point
extern int Wifi_DisconnectAP();

// Wifi_Timer: This function should be called in a periodic interrupt. It serves as the basis
//   for all updating in the sgIP library, all retransmits, timeouts, and etc are based on this
//   function being called.  It's not timing critical but it is rather essential.
//  int num_ms:		The number of milliseconds since the last time this function was called.
extern void Wifi_Timer(int num_ms);

// Wifi_GetIP:
//  Returns:  The current IP address of the DS (may not be valid before connecting to an AP, or setting the IP manually.)
extern unsigned long Wifi_GetIP(); // get local ip

// Wifi_GetIPInfo: (values may not be valid before connecting to an AP, or setting the IP manually.)
//  struct in_addr * pGateway:	pointer to receive the currently configured gateway IP
//  struct in_addr * pSnmask:	pointer to receive the currently configured subnet mask
//  struct in_addr * pDns1:		pointer to receive the currently configured primary DNS server IP
//  struct in_addr * pDns2:		pointer to receive the currently configured secondary DNS server IP
//  Returns:					The current IP address of the DS
extern struct in_addr Wifi_GetIPInfo(struct in_addr * pGateway,struct in_addr * pSnmask,struct in_addr * pDns1,struct in_addr * pDns2);

// Wifi_SetIP: Set the DS's IP address and other IP configuration information.
//  unsigned long IPaddr:		The new IP address (NOTE! if this value is zero, the IP, the gateway, and the subnet mask will be allocated via DHCP)
//  unsigned long gateway:		The new gateway (example: 192.168.1.1 is 0xC0A80101)
//  unsigned long subnetmask:	The new subnet mask (example: 255.255.255.0 is 0xFFFFFF00)
//  unsigned long dns1:			The new primary dns server (NOTE! if this value is zero AND the IPaddr value is zero, dns1 and dns2 will be allocated via DHCP)
//  unsigned long dns2:			The new secondary dns server
extern void Wifi_SetIP(unsigned long IPaddr, unsigned long gateway, unsigned long subnetmask, unsigned long dns1, unsigned long dns2);

// Wifi_GetData: Retrieve an arbitrary or misc. piece of data from the wifi hardware. see WIFIGETDATA enum.
//  int datatype:				element from the WIFIGETDATA enum specifing what kind of data to get
//  int bufferlen:				length of the buffer to copy data to (not always used)
//  unsigned char * buffer:		buffer to copy element data to (not always used)
//  Returns:					-1 for failure, the number of bytes written to the buffer, or the value requested if the buffer isn't used.
extern int Wifi_GetData(int datatype, int bufferlen, unsigned char * buffer);

// Wifi_GetStats: Retreive an element of the wifi statistics gathered
//  int statnum:		Element from the WIFI_STATS enum, indicating what statistic to return
//  Returns:			the requested stat, or 0 for failure
extern u32 Wifi_GetStats(int statnum);
//////////////////////////////////////////////////////////////////////////
// Raw Send/Receive functions

// Wifi_RawTxFrame: Send a raw 802.11 frame at a specified rate
//  unsigned short datalen:	The length in bytes of the frame to send
//  unsigned short rate:	The rate to transmit at (Specified as mbits/10, 1mbit=0x000A, 2mbit=0x0014)
//  unsigned short * data:	Pointer to the data to send (should be halfword-aligned)
//  Returns:				Nothing of interest.
extern int Wifi_RawTxFrame(unsigned short datalen, unsigned short rate, unsigned short * data);

// Wifi_RawSetPacketHandler: Set a handler to process all raw incoming packets
//  WifiPacketHandler wphfunc:  Pointer to packet handler (see WifiPacketHandler definition for more info)
extern void Wifi_RawSetPacketHandler(WifiPacketHandler wphfunc);

// Wifi_RxRawReadPacket:  Allows user code to read a packet from within the WifiPacketHandler function
//  long packetID:			a non-unique identifier which locates the packet specified in the internal buffer
//  long readlength:		number of bytes to read (actually reads (number+1)&~1 bytes)
//  unsigned short * data:	location for the data to be read into
extern int Wifi_RxRawReadPacket(long packetID, long readlength, unsigned short * data);

//////////////////////////////////////////////////////////////////////////
// Fast transfer support - update functions

// Wifi_Update: Checks for new data from the arm7 and initiates routing if data
//   is available.
extern void Wifi_Update();

// Wifi_Sync: Call this function when requested to sync by the arm7 side of the
//   wifi lib
extern void Wifi_Sync();

// Wifi_SetSyncHandler: Call this function to request notification of when the
//   ARM7-side Wifi_Sync function should be called.
//  WifiSyncHandler sh:    Pointer to the function to be called for notification.
extern void Wifi_SetSyncHandler(WifiSyncHandler sh);

#define WFC_CONNECT	true
#define INIT_ONLY	false


extern bool Wifi_InitDefault(bool useFirmwareSettings);

#ifdef __cplusplus
};
#endif


#endif
