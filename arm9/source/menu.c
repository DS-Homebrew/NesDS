#include <nds.h>
#include <fat.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

struct menu_item menu_file_items[] = {
	{
		.name = "\rLoad ROM",
		.type = 1,
		.x = 1, .y = 5, .w = 8, .h = 3,
		.func = menu_file_loadrom
	},
	{
		.name = "\rSave State",
		.type = 1,
		.x = 16, .y = 5, .w = 10, .h = 3,
		.func = menu_file_savestate
	},
	{
		.name = "\rSave SRAM",
		.type = 1,
		.x = 1, .y = 12, .w = 9, .h = 3,
		.func = menu_file_savesram
	},
	{
		.name = "\rLoad State",
		.type = 1,
		.x = 16, .y = 12, .w = 10, .h = 3,
		.func = menu_file_loadstate
	},
	{
		.name = "\rSlot Inc",
		.type = 1,
		.x = 1, .y = 19, .w = 8, .h = 3,
		.func = menu_file_slot
	},
	{
		.name = "\rSlot Dec",
		.type = 1,
		.x = 16, .y = 19, .w = 8, .h = 3,
		.func = menu_file_slot
	},
};
struct menu_unit menu_file = {
	.top = "File",
	.subcnt = 6,
	.item = menu_file_items,
	.start = menu_file_start,
};
	
struct menu_unit menu_input = {
	.top = "Input",
	.subcnt = 0,
	.start = menu_input_start,
};

struct menu_unit menu_adjust = {
	.top = "Scale",
	.subcnt = 0,
	.start = menu_adjust_start,
};

struct menu_item menu_display_items[] = {
	{
		.name = "\rAdjust\rScaling",
		.type = 0,
		.x = 1, .y = 5, .w = 7, .h = 4,
		.child = &menu_adjust,
	},
	{
		.name = "\r\x7F-lerp",
		.type = 1,
		.x = 1, .y = 13, .w = 6, .h = 3,
		.func = menu_display_br
	},
	{
		.name = "\rFlicker",
		.type = 1,
		.x = 10, .y = 13, .w = 7, .h = 3,
		.func = menu_display_br
	},
	{
		.name = "\rNone",
		.type = 1,
		.x = 20, .y = 13, .w = 4, .h = 3,
		.func = menu_display_br
	},
	{
		.name = "Sprites\rPerframe",
		.type = 1,
		.x = 1, .y = 20, .w = 8, .h = 2,
		.func = menu_display_br
	},
	{
		.name = "Sprites\rPertile",
		.type = 1,
		.x = 12, .y = 20, .w = 7, .h = 2,
		.func = menu_display_br
	},
	{
		.name = "All\rpuresoft",
		.type = 1,
		.x = 22, .y = 20, .w = 8, .h = 2,
		.func = menu_display_br
	},
	{
		.name = "\rDec",
		.type = 1,
		.x = 22, .y = 6, .w = 3, .h = 3,
		.func = menu_display_br
	},
	{
		.name = "\rInc",
		.type = 1,
		.x = 16, .y = 6, .w = 3, .h = 3,
		.func = menu_display_br
	},
	{
		.name = "On\rOr\rOff",
		.type = 1,
		.x = 27, .y = 13, .w = 3, .h = 3,
		.func = menu_display_br
	},
};

struct menu_unit menu_display = {
	.top = "Display",
	.subcnt = 10,
	.start = menu_display_start,
	.item = menu_display_items,
};

struct menu_unit menu_nifi = {
	.top = "Nifi",
	.subcnt = 0,
	.start = menu_nifi_start,
};

struct menu_unit menu_extra = {
	.top = "Extra",
	.subcnt = 0,
	.start = menu_extra_start,
};
struct menu_item menu_game_items[] = {
	{
		.name = "\r Input",
		.type = 0,
		.x = 1, .y = 5, .w = 7, .h = 3,
		.child = &menu_input,
	},
	{
		.name = "\r Display",
		.type = 0,
		.x = 16, .y = 5, .w = 9, .h = 3,
		.child = &menu_display,
	},
	{
		.name = "\r  Nifi",
		.type = 0,
		.x = 1, .y = 12, .w = 8, .h = 3,
		.child = &menu_nifi,
	},
	{
		.name = "\rNTSC",
		.type = 1,
		.x = 16, .y = 12, .w = 4, .h = 3,
		.func = menu_game_ntsc,
	},
	{
		.name = "\rPAL",
		.type = 1,
		.x = 24, .y = 12, .w = 4, .h = 3,
		.func = menu_game_pal,
	},
	{
		.name = "\r RESET",
		.type = 1,
		.x = 21, .y = 19, .w = 7, .h = 3,
		.func = menu_game_reset,
	},
	{
		.name = "\r Extra",
		.type = 0,
		.x = 1, .y = 19, .w = 7, .h = 3,
		.child = &menu_extra,
	},
	{
		.name = " Show\r All\r pixel",
		.type = 1,
		.x = 11, .y = 19, .w = 7, .h = 3,
		.func = show_all_pixel,
	}
};
struct menu_unit menu_game = {
	.top = "Game",
	.subcnt = 8,
	.start = menu_game_start,
	.item = menu_game_items,
};



struct menu_unit menu_cheat_search = {
	.top = "Search",
	.subcnt = 0,
	.start = menu_cheat_search_start,
};
struct menu_unit menu_cheat_list = {
	.top = "List",
	.subcnt = 0,
	.start = menu_cheat_list_start,
};

struct menu_item menu_cheat_items[] = {
	{
		.name = "\rSearch",
		.type = 0,
		.x = 1, .y = 5, .w = 6, .h = 3,
		.child = &menu_cheat_search,
	},
	{
		.name = "\rCheat List",
		.type = 0,
		.x = 16, .y = 5, .w = 10, .h = 3,
		.child = &menu_cheat_list,
	},
	{
		.name = "\rSave To File",
		.type = 1,
		.x = 1, .y = 12, .w = 12, .h = 3,
		.func = menu_cht_action,
	},
	{
		.name = "\rLoad From File",
		.type = 1,
		.x = 16, .y = 12, .w = 14, .h = 3,
		.func = menu_cht_action,
	},
};
struct menu_unit menu_cheat = {
	.top = "Cheat",
	.subcnt = 4,
	.item = menu_cheat_items,
};

struct menu_unit menu_debug = {
	.top = "Debug",
	.subcnt = 0,
	.start = menu_debug_start,
};


struct menu_item menu_shortcut_items[] = {
	{
		.name = " L",
		.type = 1,
		.x = 1, .y = 17, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " R",
		.type = 1,
		.x = 7, .y = 17, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " \x80",
		.type = 1,
		.x = 13, .y = 17, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " \x81",
		.type = 1,
		.x = 19, .y = 17, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " \x82",
		.type = 1,
		.x = 25, .y = 17, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " \x83",
		.type = 1,
		.x = 1, .y = 21, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " Y",
		.type = 1,
		.x = 7, .y = 21, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " X",
		.type = 1,
		.x = 13, .y = 21, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " B",
		.type = 1,
		.x = 25, .y = 21, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = " A",
		.type = 1,
		.x = 19, .y = 21, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Sta",
		.type = 1,
		.x = 19, .y = 13, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Sel",
		.type = 1,
		.x = 25, .y = 13, .w = 3, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Clear",
		.type = 1,
		.x = 11, .y = 13, .w = 5, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Next",
		.type = 1,
		.x = 25, .y = 4, .w = 4, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Prev",
		.type = 1,
		.x = 25, .y = 8, .w = 4, .h = 1,
		.func = menu_shortcut_func,
	},
	{
		.name = "Gesture",
		.type = 1,
		.x = 1, .y = 13, .w = 7, .h = 1,
		.func = menu_shortcut_func,
	},
};

struct menu_unit menu_short_cut = {
	.top = "Short-Cuts",
	.subcnt = 16,
	.start = menu_shortcut_start,
	.item = menu_shortcut_items,
};

struct menu_item menu_config_items[] = {
	{
		.name = "\rSave SRAM\rAuto",
		.type = 1,
		.x = 1, .y = 5, .w = 9, .h = 4,
		.func = menu_config_func,
	},
	{
		.name = "\rSave SRAM\rManual",
		.type = 1,
		.x = 16, .y = 5, .w = 9, .h = 4,
		.func = menu_config_func,
	},
	{
		.name = "\rGraphic on\rTop-Screen",
		.type = 1,
		.x = 1, .y = 12, .w = 11, .h = 4,
		.func = menu_config_func,
	},
	{
		.name = "\rGraphic on\rSub-Screen",
		.type = 1,
		.x = 16, .y = 12, .w = 11, .h = 4,
		.func = menu_config_func,
	},
	{
		.name = "\rSound Reset",
		.type = 1,
		.x = 1, .y = 19, .w = 11, .h = 3,
		.func = menu_config_func,
	},
};
struct menu_unit menu_config = {
	.top = "Config",
	.subcnt = 5,
	.item = menu_config_items,
};

struct menu_item menu_setting_items[] = {
	{
		.name = "\rConfig",
		.type = 0,
		.x = 1, .y = 5, .w = 6, .h = 3,
		.child = &menu_config
	},
	{
		.name = "\rShort-Cuts",
		.type = 0,
		.x = 1, .y = 11, .w = 10, .h = 3,
		.child = &menu_short_cut
	},
	{
		.name = "\rSave nesDS.ini",
		.type = 1,
		.x = 1, .y = 17, .w = 14, .h = 3,
		.func = menu_saveini
	},
};
struct menu_unit menu_setting = {
	.top = "Settings",
	.subcnt = 3,
	.item = menu_setting_items,
};
	
struct menu_unit menu_about = {
	.top = "About",
	.subcnt = 0,
	.start = menu_about_start,
};

struct menu_item menu_items[] = {
	{
		.name = "\r File",
		.type = 0,
		.x = 1, .y = 5, .w = 6, .h = 3,
		.child = &menu_file
	},
	{
		.name = "\r Game",
		.type = 0,
		.x = 11, .y = 5, .w = 6, .h = 3,
		.child = &menu_game
	},
	{
		.name = "\r Cheat",
		.type = 0,
		.x = 21, .y = 5, .w = 7, .h = 3,
		.child = &menu_cheat
	},
	{
		.name = "\r Settings",
		.type = 0,
		.x = 1, .y = 12, .w = 10, .h = 3,
		.child = &menu_setting,
	},
	{
		.name = "\r Debug",
		.type = 0,
		.x = 16, .y = 12, .w = 7, .h = 3,
		.child = &menu_debug,
	},
	{
		.name = "\r About",
		.type = 0,
		.x = 1, .y = 19, .w = 7, .h = 3,
		.child = &menu_about,
	},
	{
		.name = " hide\r menu",
		.type = 1,
		.x = 24, .y = 20, .w = 6, .h = 2,
		.func = menu_hide,
	}
};

struct menu_unit menu = {
	.top = "Menu",
	.subcnt = 7,
	.item = menu_items
};

struct button top_button[8];
int top_bcnt = 0;
struct button menu_button[32];
int menu_bcnt = 0;
struct button user_button[32];
int user_bcnt = 0;

struct button *lastbutton = NULL;
int lastbutton_type = 0;
int lastbutton_cnt = 0;

void draw_button(char *text, int x, int y, int w, int h, int color)
{
	int i;
	consoletext(y * 64 + x * 2, "\xa2", color);
	consoletext((y + h + 1) * 64 + x * 2, "\xa3", color);
	consoletext((y + h + 1) * 64 + (x + w + 1) * 2, "\xa4", color);
	consoletext(y * 64 + (x + w + 1) * 2, "\xa5", color);

	for(i = x + 1; i < x + w + 1; i++) {
		consoletext(y * 64 + i * 2, "\xa0", color);
		consoletext((y + h + 1) * 64 + i * 2, "\xa0", color);
	}

	for(i = y + 1; i < y + h + 1; i++) {
		consoletext(i * 64 + x * 2, "\xa1", color);
		consoletext(i * 64 + (x + w + 1) * 2, "\xa1", color);
	}

	consoletext(y * 64 + 64 + x * 2 + 2, text, color);
}

int add_buttonp(int group, struct button *adb)
{
	struct button *bt;
	int *bcnt;

	switch(group) {
	case 0:	//top buttion
		bt = &top_button[top_bcnt];
		bcnt = &top_bcnt;
		break;
	case 1:
		bt = &menu_button[menu_bcnt];
		bcnt = &menu_bcnt;
		break;
	default:
	case 2:
		bt = &user_button[user_bcnt];
		bcnt = &user_bcnt;
		break;
	}
	bt->name = adb->name;
	bt->type = adb->type;

	bt->x = adb->x;
	bt->y = adb->y;
	bt->w = adb->w;
	bt->h = adb->h;
	bt->stat = 0;

	*bcnt += 1;
	return bt->w + bt->x;
}

int add_button(int group, char *name, char type, char x, char y, char w, char h)
{
	struct button *bt;
	int *bcnt;

	switch(group) {
	case 0:	//top buttion
		bt = &top_button[top_bcnt];
		bcnt = &top_bcnt;
		break;
	case 1:
		bt = &menu_button[menu_bcnt];
		bcnt = &menu_bcnt;
		break;
	default:
	case 2:
		bt = &user_button[user_bcnt];
		bcnt = &user_bcnt;
		break;
	}
	bt->name = name;
	bt->type = type;

	bt->x = x;
	bt->y = y;
	bt->w = w;
	bt->h = h;
	bt->stat = 0;

	*bcnt += 1;
	return bt->w + bt->x;
}

void show_button_group(int group)
{
	struct button *bt;
	int *bcnt;
	int i;

	switch(group) {
	case 0:	//top buttion
		bt = top_button;
		bcnt = &top_bcnt;
		break;
	case 1:
		bt = menu_button;
		bcnt = &menu_bcnt;
		break;
	default:
	case 2:
		bt = user_button;
		bcnt = &user_bcnt;
		break;
	}

	for(i = 0; i < *bcnt; i++) {
		draw_button(bt->name, bt->x, bt->y, bt->w, bt->h, 0);
		bt++;
	}
}

void check_button_group(int group)
{
	struct button *bt;
	int *bcnt;
	int type;
	int i;

	switch(group) {
	case 0:	//top buttion
		bt = top_button;
		bcnt = &top_bcnt;
		type = 0;
		break;
	case 1:
		bt = menu_button;
		bcnt = &menu_bcnt;
		type = 1;
		break;
	default:
	case 2:
		bt = user_button;
		bcnt = &user_bcnt;
		type = 2;
		break;
	}

	for(i = 0; i < *bcnt; i++) {
		if(last_x >= bt->x * 8 + 4 && last_x <= (bt->x + bt->w + 2) * 8 - 3 && last_y >= bt->y * 8 + 4 && last_y <= (bt->y + bt->h + 2) * 8 - 3 ) {
			draw_button(bt->name, bt->x, bt->y, bt->w, bt->h, 0x1000);
			lastbutton = bt;
			lastbutton_type = type;
			lastbutton_cnt = i;
			bt->stat = 1;
			break;
		}
		bt++;
	}
}

int menu_stat = 0;
struct menu_unit *menu_array[16] = {&menu};
int menu_depth = 1;
struct menu_unit *last_menu = &menu;
char last_type = 0;
int menu_draw = 0;
void (*menu_func)(void) = NULL;

void do_menu()
{
	int i;

	do_gesture();
	
	if(menu_stat == 0 && touchstate != 4) {
		return;
	}

	if(menu_stat == 0 && gesture != 0)
		return;

	if(__emuflags & LIGHTGUN)
		return;

	if(menu_stat >= 5 && menu_func != NULL) {
		menu_func();
		return;
	}

	last_menu = menu_array[menu_depth - 1];

	if(menu_stat == 2)
		menu_stat = 3;

	if(menu_stat == 0) {
		if(menu_draw == 0)
			memset((void *)(SUB_BG),0,64*24);
		showconsole();
		screen_swap = 0;
		menu_stat = 1;
	}

	if(menu_stat == 1) {
		menu_stat = 2;
		if(menu_draw == 0) {
			int width = 0;

			memset((void *)(SUB_BG),0,64*24);
			top_bcnt = 0;
			menu_bcnt = 0;
			user_bcnt = 0;

			for(i = 0; i < menu_depth - 1; i++) {
				add_button(0, menu_array[i]->top, 0, width, 0, strlen(menu_array[i]->top), 1);
				width += strlen(menu_array[i]->top) + 3;
				consoletext(64 + width * 2 - 2, ">", 0);
			}
			
			//consoletext(width * 2 + 66, menu_array[i]->top, 0);
			//add a button to click
			add_button(0, menu_array[i]->top, 0, width, 0, strlen(menu_array[i]->top), 1);

			for(i = 0; i < 32; i++) {
				consoletext(64 * 3 + i * 2, "\xa0", 0);
			}

			width = 0;

			for (i = 0; i < last_menu->subcnt; i++) {
				add_buttonp(1, (struct button *)&(last_menu->item[i]));
			}

			if(last_menu->start) {
				last_menu->start();
			}

			show_button_group(0);
			show_button_group(1);

			menu_draw = 1;
		}
	}

	if(menu_stat == 3) {
		if(menu_depth == 1) { // show the time
			static char buf[20];
			static time_t old = 0;
			time_t unixTime = time(NULL);
			if(unixTime != old) {
				struct tm* timeStruct = gmtime((const time_t *)&unixTime);
				sprintf(buf, "%02d:%02d", timeStruct->tm_hour, timeStruct->tm_min);
				consoletext(64*2 - 12, buf, 0);
				old = unixTime;
			}
		}

		if(touchstate > 1) {
			if(!(lastbutton != NULL && last_x >= lastbutton->x * 8 + 4 && last_x <= (lastbutton->x + lastbutton->w + 2) * 8 - 3 
				&& last_y >= lastbutton->y * 8 + 4 && last_y <= (lastbutton->y + lastbutton->h + 2) * 8 - 3)) {
				if(lastbutton != NULL) {
					draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
					lastbutton->stat = 0;
					lastbutton = NULL;
				}
				check_button_group(0);
				check_button_group(1);
			}
		} else if(lastbutton != NULL) {
			draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
			lastbutton->stat = 0;
			lastbutton = NULL;
		}

		if(touchstate == 4 && lastbutton != NULL) {		//a button is clicked.
			draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
			lastbutton->stat = 0;
	
			if(lastbutton_type == 0) {
				if(menu_depth == lastbutton_cnt + 1) { //use this to hide menu
					menu_stat = 0;
					menu_draw = 0;
					hideconsole();
				} else { //change menu depth
					menu_depth = lastbutton_cnt + 1;
					last_menu = menu_array[menu_depth - 1];
					menu_stat = 1;
					menu_draw = 0;
					lastbutton = NULL;
				}
			} else if(lastbutton_type == 1) {
				if(last_menu->item[lastbutton_cnt].type == 0 && last_menu->item[lastbutton_cnt].child) {	//a sub menu
					last_menu = (struct menu_unit *)last_menu->item[lastbutton_cnt].child;
					menu_array[menu_depth] = last_menu;
					menu_depth++;
					menu_stat = 1;
					menu_draw = 0;
					lastbutton = NULL;
				}
				else if(last_menu->item[lastbutton_cnt].type == 1 && last_menu->item[lastbutton_cnt].func) {	//a sub menu
					menu_func = last_menu->item[lastbutton_cnt].func;
					lastbutton = NULL;
					menu_stat = 5;
				}
			}
		}
	}
}

