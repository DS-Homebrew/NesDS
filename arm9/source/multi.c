#include <nds.h>
#include <dswifi9.h>
#include <stdlib.h>
#include <string.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

char data[4096];
static const char nesds[32]		= {0xB2, 0xD1, 'n', 'e', 's', 'd', 's', 0};
static const char nfconnect[32]	= {0xB2, 0xD1, 'c', 'o', 'n', 'e', 'd', 0};
static char nfcrc[32]				= {0xB2, 0xD1, 0x81, 0, 0, 0};

// nfdata[3..6]	= nifi_cmd
// 7..8			= framecount	used by guest, sent by host
// 9..10		= player1 keys  sent by host
// 11.12		= player2 keys  sent by guest, re-sent by guest
// 13.77		= hosts' key_buf... needed by guest when the recent packages were lost.
static char nfdata[128]			= {0xB2, 0xD1, 0x82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
//static char nfsync[]			= {0xB2, 0xD1, 0x83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};		//sync the memory....

//0 not ready, 1 act as a host and waiting, 2 act as a guest and waiting, 3 connecting, 4 connected, 5 host ready, 6 guest ready
int nifi_stat = 0;
int nifi_cmd = 0;
int nifi_keys = 0;		//holds the keys for players.
int new_nkeys = 0;		//holds the next key for refreshing.
int old_nkeys = 0;		//if no new_keys coming, use the old_keys
int plykeys1 = 0;		//player1
int plykeys2 = 0;		//player2
int new_framecount = 0;	//used by the guest for syncing.
int guest_framecount = 0;	//used by the guest for syncing.
int old_guest_framecount = 0;	//used by the guest for syncing.
static int framecount = 0;

char key_maps[16];			//for guest to record the key_buf state.
int key_buf[16];			//for guest to record the keys...

int frame_stuck;		//ont player should not be stuck when the other failed to comm...

void deep_reset()
{
	//unsigned char *memp = (unsigned char *)NES_RAM;
	//memset(memp, 0, 0x7800);
	memset(key_buf, 0, 16 * 4);
	memset(key_maps, 0, 16);
}

void sendcmd()
{
	memcpy(nfdata + 3, &nifi_cmd, 4);
	if(nifi_stat == 5) {	//host
		memcpy(nfdata + 9, &new_nkeys, 4);
		memcpy(nfdata + 7, &new_framecount, 2);
		memcpy(nfdata + 13, key_buf, 4*16);
		Wifi_RawTxFrame(78, 0x0014, (unsigned short *)nfdata);
	} else {
		plykeys2 = IPC_KEYS & MP_KEY_MSK;
		memcpy(nfdata + 7, &framecount, 2);
		memcpy(nfdata + 11, &plykeys2, 2);
		Wifi_RawTxFrame(14, 0x0014, (unsigned short *)nfdata);
	}
}


void getcmd()
{
	memcpy(&nifi_cmd, data + 35, 4);
	if(nifi_stat == 5) {	//host
		memcpy(&plykeys2, data + 43, 2);
		memcpy(&guest_framecount, data + 39, 2);
	} else {
		int i;
		char *kbufp = data + 45;
		memcpy(&new_framecount, data + 39, 2);
		memcpy(&new_nkeys, data + 41, 4);
		key_buf[(new_framecount >> 1) &15] = new_nkeys;
		key_maps[(new_framecount >> 1) &15] = 1;			//the key is valid.
		for(i = framecount + 1; i < new_framecount; i+=2) {
			int tmp = (i >> 1) & 15;
			memcpy(&key_buf[tmp], kbufp + tmp * 4, 4);
			key_maps[tmp] = 1;
		}
	}
}

void Handler(int packetID, int readlength)
{
	Wifi_RxRawReadPacket(packetID, readlength, (unsigned short *)data);

	// Lazy test to see if this is our packet.
	if (data[32] == 0xB2 && data[33] == 0xD1)  {//a packet from another ds.
		switch(nifi_stat) {
			case 0:
				return;
			case 1:			//love this.
				if(strncmp(data + 34, nesds + 2, 8) == 0) {
					nifi_stat = 3;
				}
				break;
			case 2:			//love this.
				if(strncmp(data + 34, nfconnect + 2, 8) == 0) {
					nifi_stat = 4;
				}
				break;
			case 3:
				if(data[34] == 0x81) {		//Check the CRC. Make sure that both players are using the same game.
					int remotecrc = (data[35] | (data[36] << 8));
					if(debuginfo[17] == remotecrc) {	//ok. same game
						nifi_stat = 5;
						nifi_cmd |= MP_CONN;
						sendcmd();
						hideconsole();
						NES_reset();
						deep_reset();
						new_nkeys = 0;
						nifi_keys = 0;
						plykeys1 = 0;
						plykeys2 = 0;
						framecount = 0;
						new_framecount = 0;
						guest_framecount = 0;
						global_playcount = 0;
						joyflags &= ~AUTOFIRE;
						__af_st = __af_start;
						menu_game_reset();	//menu is closed.
					} else {		//bad crc. disconnect the comm.
						nifi_stat = 0;
						nifi_cmd &= ~MP_CONN;
						sendcmd();
					}
				}
				break;
			case 4:
				if(data[34] == 0x82) {
					getcmd();
					if(nifi_cmd & MP_CONN) {	//CRC ok, get ready for multi-play.
						nifi_stat = 6;
						hideconsole();
						NES_reset();
						deep_reset();
						new_nkeys = 0;
						nifi_keys = 0;
						plykeys1 = 0;
						plykeys2 = 0;
						framecount = 0;
						new_framecount = 0;
						guest_framecount = 0;
						global_playcount = 0;
						joyflags &= ~AUTOFIRE;
						__af_st = __af_start;
						menu_game_reset();	//menu is closed.
					} else {					//CRC error, the both sides should choose the some game.
						nifi_stat = 0;
					}
				}
				break;
			case 5:						//as a host, and receiving the package from guest.
				getcmd();
				break;
			case 6:						//update player1's joystate
				getcmd();
				break;
		}
	}
}

void bug_DC_FlushAll()
{
	DC_FlushAll();
}

void Timer_10ms(void) {
	Wifi_Timer(10);
}

void initNiFi()
{
	Wifi_InitDefault(false);
	Wifi_SetPromiscuousMode(1);
	//Wifi_EnableWifi();
	Wifi_RawSetPacketHandler(Handler);
	Wifi_SetChannel(10);

	if(1) {
		//for secial configuration for wifi
		irqDisable(IRQ_TIMER3);
		irqSet(IRQ_TIMER3, Timer_10ms); // replace timer IRQ
		// re-set timer3
		TIMER3_CR = 0;
		TIMER3_DATA = -(6553 / 5); // 6553.1 * 256 / 5 cycles = ~10ms;
		TIMER3_CR = 0x00C2; // enable, irq, 1/256 clock
		irqEnable(IRQ_TIMER3);
	}
}

//called by play()
void do_multi()
{
	static int count = 0;
	if(!nifi_stat) {
		framecount = 0;
		if(nifi_cmd & MP_NFEN) {
			Wifi_DisableWifi();
			nifi_cmd &= ~MP_NFEN;
		}
		return;
	}

	switch(nifi_stat) {
		case 1:		//act as a host, waiting for another player.
			if(!(nifi_cmd & MP_NFEN))
				Wifi_EnableWifi();
			nifi_cmd = MP_HOST | MP_NFEN;
			break;	//waiting for interrupt.
		case 2:		//act as a guest.
			if(!(nifi_cmd & MP_NFEN))
				Wifi_EnableWifi();
			nifi_cmd = MP_NFEN;
			if(count++ > 30) {			//send a flag every second to search a host.
				Wifi_RawTxFrame(8, 0x0014, (unsigned short *)nesds);
				count = 0;
			}
			break;
		case 3:							//tell the guest that he should send the PRGCRC to the host
			if(!(nifi_cmd & MP_NFEN))
				Wifi_EnableWifi();
			if(count++ > 30) {			//send a connected flag.
				Wifi_RawTxFrame(8, 0x0014, (unsigned short *)nfconnect);
				count = 0;
			}
			break;
		case 4:
			if(!(nifi_cmd & MP_NFEN))
				Wifi_EnableWifi();
			if(count++ > 30) {			//send a connected flag.
				nfcrc[3] = debuginfo[17] &0xFF;
				nfcrc[4] = (debuginfo[17] >> 8 )&0xFF;
				Wifi_RawTxFrame(6, 0x0014, (unsigned short *)nfcrc);
				count = 0;
			}
			break;
		case 5:				//host should refresh the global keys.
			if(framecount & 1)  {//refresh when a odd count.
				new_nkeys = (IPC_KEYS & MP_KEY_MSK) | ((plykeys2 & MP_KEY_MSK) << 16);
				nifi_keys = new_nkeys;
				key_buf[(framecount >> 1) &15] = new_nkeys;
				new_framecount = framecount;
			}
			sendcmd();
			/*
			if(framecount >= guest_framecount + 3) {
				swiWaitForVBlank();			//host cound not be faster then host.
			}*/
			break;
		case 6:				//guest...
			//if(framecount & 1)  {//refresh when a even count.
				plykeys2 = IPC_KEYS & MP_KEY_MSK;
				sendcmd();
			//}
			frame_stuck = 0;
			while(framecount > new_framecount) {
				swiWaitForVBlank();			//guest cound not be faster then host.
				if(frame_stuck++ > 120) {	// 2 seconds for stuck!!!
					nifi_stat = 0;
					break;
				}
			}

			if(key_maps[((framecount + 1) >> 1) & 15]) {
				IPC_KEYS |= KEY_R;			//quick up!!!
			}

			frame_stuck = 0;
			if(framecount & 1) {			//need to sync the keys.
				while(!key_maps[(framecount >> 1) & 15]) {		//just wait....
					swiDelay(10000);			//1ms delay, more or less.
					if(frame_stuck++ > 2000) {   //2 second..
						nifi_stat = 0;
						break;
					}
				}
				nifi_keys = key_buf[(framecount >> 1) & 15];
				key_maps[(framecount >> 1) & 15] = 0;			//clear the state.
			}
			break;
		default:
			break;
	}
	framecount++;
}
