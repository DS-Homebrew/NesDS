/*---------------------------------------------------------------------------------
	derived from the default ARM7 core
---------------------------------------------------------------------------------*/
#include <nds.h>
#include <dswifi7.h>
//#include <maxmod7.h>
#include "ds_misc.h"
#include "c_defs.h"

void nesmain();

//---------------------------------------------------------------------------------
void VblankHandler(void) {
//---------------------------------------------------------------------------------
	Wifi_Update();
}

int ipc_region = 0;

volatile bool exitflag = false;

u8 *bootstub;
u32 ndstype;
typedef void (*type_void)();
type_void bootstub_arm7;
static void sys_exit(){
	if(!bootstub_arm7){
		if(ndstype>=2)writePowerManagement(0x10, 1);
		else writePowerManagement(0, PM_SYSTEM_PWR);
	}
	bootstub_arm7(); //won't return
}

extern int APU_paused;
void dealrawpcm(unsigned char *out);
//---------------------------------------------------------------------------------
int main() {
//---------------------------------------------------------------------------------
	readUserSettings();

	irqInit();
	fifoInit();
	// Start the RTC tracking IRQ
	initClockIRQ();

	installSystemFIFO();
	installWifiFIFO();
	//irqSet(IRQ_VCOUNT, VcountHandler);
	irqSet(IRQ_VBLANK, VblankHandler);

	irqEnable(IRQ_TIMER1 | IRQ_VBLANK | IRQ_NETWORK);
	
	{
		ndstype=0;
		u32 myself = readPowerManagement(4); //(PM_BACKLIGHT_LEVEL);
		if(myself & (1<<6))
			ndstype=(myself==readPowerManagement(5))?1:2;
	}

	bootstub=(u8*)0x02ff4000;
	bootstub_arm7=(*(u64*)bootstub==0x62757473746F6F62ULL)?(*(type_void*)(bootstub+0x0c)):0;
	setPowerButtonCB(sys_exit); 

	while(!fifoCheckValue32(FIFO_USER_06))		//wait for the value of ipc_region
		swiWaitForVBlank();				
	ipc_region = fifoGetValue32(FIFO_USER_06);

	nesmain();

	// Keep the ARM7 mostly idle
	while (1) {
		if ( 0 == (REG_KEYINPUT & (KEY_SELECT | KEY_START | KEY_L | KEY_R))) {
			sys_exit();
		}
		inputGetAndSend();
		swiWaitForVBlank();
	}
	//return 0;
}
