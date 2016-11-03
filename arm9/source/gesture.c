#include <nds.h>
#include <stdio.h>
#include <string.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

#define GMARGIN 32

int gesture = 0;		//not active
int gesture_x = 0;		//old value
int gesture_y = 0;
int gesture_type = 0;	//0 = stop, 1 = start, 4 = Up, 5 = Left, 6 = Down, 7 = Right
char gesture_combo[32] = {0};
int gesture_pos = 0;
int last_pos = 0;

void add_combo(void)
{
	if(gesture_pos >= 16)
		return;

	gesture_x = last_x;
	gesture_y = last_y;

	switch(gesture_type) {
	case 4:
		gesture_combo[gesture_pos++] = 'U';
		break;
	case 5:
		gesture_combo[gesture_pos++] = 'L';
		break;
	case 6:
		gesture_combo[gesture_pos++] = 'D';
		break;
	case 7:
		gesture_combo[gesture_pos++] = 'R';
		break;
	}
	gesture_combo[gesture_pos] = 0;
}

void check_motion(void)
{
	if(last_y > gesture_y + GMARGIN) {  //down motion	priority highest.
		gesture_type = 6;
	}
	else if(last_x > gesture_x + GMARGIN) {	//right motion
		gesture_type = 7;
	}
	else if(last_x < gesture_x - GMARGIN) {	//left motion
		gesture_type = 5;
	}
	else if(last_y < gesture_y - GMARGIN) {	//up motion
		gesture_type = 4;
	}
}

void do_gesture(void)
{
	if(menu_stat !=0)
		return;

	if(!(IPC_KEYS & KEY_TOUCH) && touchstate != 4) {
		gesture = 0;
		gesture_type = 0;
		return;
	}

	if(gesture_type == 0 && touchstate == 2) {
		memset((void *)(SUB_BG),0,64*24);
		powerOn(PM_BACKLIGHT_BOTTOM | PM_BACKLIGHT_TOP);
		consoletext(64 * 4 + 16, "Gesture Motions:", 0);
		gesture_type = 1;
		gesture_x = last_x;
		gesture_y = last_y;
		gesture_pos = 0;
		last_pos = 0;
		gesture_combo[0] = 0;
		return;
	}

	if(touchstate > 1 && touchstate < 4) {
		switch(gesture_type) {
		case 1:
			check_motion();
			if(gesture_type != 1) {
				add_combo();
			}
			break;
		case 4:
			if(last_y < gesture_y)
				gesture_y = last_y;
			check_motion();
			if(gesture_type != 4)
				add_combo();
			break;
		case 5:
			if(last_x < gesture_x)
				gesture_x = last_x;
			check_motion();
			if(gesture_type != 5)
				add_combo();
			break;
		case 6:
			if(last_y > gesture_y)
				gesture_y = last_y;
			check_motion();
			if(gesture_type != 6)
				add_combo();
			break;
		case 7:
			if(last_x > gesture_x)
				gesture_x = last_x;
			check_motion();
			if(gesture_type != 7)
				add_combo();
			break;
		}
	}
	else if(touchstate == 4) {
		if(gesture_pos > 0) {
			int i;

			if(!(__emuflags & SCREENSWAP)) {
				powerOff(PM_BACKLIGHT_BOTTOM);
			} else {
				powerOff(PM_BACKLIGHT_TOP);
			}
		
			do_gesture_type = -1;
			for(i = 0; i < MAX_SC; i++) {
				if(!strcmp(gesture_combo, gestures_tbl[i])) {
					do_gesture_type = i;
					break;
				}
			}

			gesture_type = 0;
			gesture = 1;
			gesture_pos = 0;
			last_pos = 0;
			hideconsole();
			gesture_combo[0] = 0;
			return;
		}
		else if(__emuflags & LIGHTGUN) {
			if(!(__emuflags & SCREENSWAP)) {
				powerOff(PM_BACKLIGHT_BOTTOM);
			} else {
				powerOff(PM_BACKLIGHT_TOP);
			}
		}
	}

	if(last_pos != gesture_pos) {
		consoletext(64 * 5 + 16, "                ", 0);
		consoletext(64 * 5 + 16, gesture_combo, 0x1000);
	}
	last_pos = gesture_pos;
}

//get a gesture, shonw at *out*.
int get_gesture(int out)
{
	if(!(IPC_KEYS & KEY_TOUCH) && touchstate != 4) {
		gesture = 0;
		gesture_type = 0;
		return 0;
	}

	if(gesture_type == 0 && touchstate == 2) {
		gesture_type = 1;
		gesture_x = last_x;
		gesture_y = last_y;
		gesture_pos = 0;
		last_pos = 0;
		gesture_combo[0] = 0;
		return 0;
	}

	if(touchstate > 1 && touchstate < 4) {
		switch(gesture_type) {
		case 1:
			check_motion();
			if(gesture_type != 1) {
				add_combo();
			}
			break;
		case 4:
			if(last_y < gesture_y)
				gesture_y = last_y;
			check_motion();
			if(gesture_type != 4)
				add_combo();
			break;
		case 5:
			if(last_x < gesture_x)
				gesture_x = last_x;
			check_motion();
			if(gesture_type != 5)
				add_combo();
			break;
		case 6:
			if(last_y > gesture_y)
				gesture_y = last_y;
			check_motion();
			if(gesture_type != 6)
				add_combo();
			break;
		case 7:
			if(last_x > gesture_x)
				gesture_x = last_x;
			check_motion();
			if(gesture_type != 7)
				add_combo();
			break;
		}
	}
	else if(touchstate == 4) {
		if(gesture_pos > 0) {
			return 1;
		}
		else
			return -1;
	}

	if(last_pos != gesture_pos) {
		consoletext(out, "                ", 0);
		consoletext(out, gesture_combo, 0x1000);
	}
	last_pos = gesture_pos;
	return 0;
}
			


	
