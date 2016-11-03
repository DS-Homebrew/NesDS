#include <nds.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

static char *tips[]= {
//--------------------------------
"2009.9 ~ now  0.2x ~ 1.x        "
"Maintained by Hao Huiming.      "
"Ported to gcc by minitroopa.    "
"                                "
"CREDITS:                        "
"--------                        "
"Original nesDS team:            "
"Coding:       loopy, FluBBa     "
"More code:    Dwedit, tepples,  "
"              kuwanger, chishm  "
"Sound:        Mamiya            "
"---MORE---    avenir            "
"                                "
"Any interest/problem, visit:    "
"sourceforge.net/projects/nesds  ",

"Nifi help: tip1                 "
"First, both people load the same"
"game; Second, the 1P click 'As a"
"host' and the 2P click 'As a    "
"guest'. If done, the info below "
"will shot the state of Nifi.    "
"The 2P will have a small delay  "
"due to the Nifi, take care.     ",

"Nifi help: tip2                 "
"    Currently, it only allow two"
"people to join in only one game/"
"room at the same time. Both the "
"players should have the same rom"
". When playing, the KEY_(R orL )"
"is disabled. The players must   "
"have the same B_A_Swap setting. "
"Do NOT load a rom or anything   "
"that would corrupt the Nifi. Eg."
"save/load a realtime state; Save"
"sram; change render method, etc."
"You should not use short-cuts.  ",

"Rom mappers:                    "
"Mappers:  0 1 2 3 4 5 7 9 10 11 "
"15 16 17 18 19 21 22 23 24 25 26"
"32 33 34 40 64 65 66 67 68 69 70"
"71 72 73 74 75 76 77 78 79 80 85"
"86 87 90 91 92 93 94 97 99 105  " 
"118 119 151 152 158 163 180 184 "
"228 232 245 246 252 & FDS.      "
"When playing a game, click the  "
"'Debug' menu, a mapper# shows   "
"the mapper info of the rom. If  "
"its value is not on the list, it"
"is not supported. If there's no "
"such string, it means that this "
"is a FDS rom.                   ",

"Roms:                           "
"Roms bigger than 3.0MB would not"
"be supported. There's not enough"
"memory for it. Take care.       "
"Not all the roms using the      "
"supported mappers works well.   "
"There are a lot of reasons that "
"I cannt figure out yet. You can "
"report it on sf.net, BUT I cannt"
"make the guarantee that it would"
"be fixed.                       ",

"Render:                         "
"There are 3 methods. The first  "
"one 'Per-Frame' works fine on a "
"lot of games, the second one    "
"'SP-pertile' works great if the "
"game would change the sprites   "
"mid-frame, the third one is a   "
"pure-soft rendering, which is   "
"used when the others work bad.  "
"Second one is recommended.      "
"The thid one will slow down the "
"game, so a 'frameskip' is used. "
"You cannot define it yet.       ",

"VideoMode/PAL/NTSC/FPS:         "
"If you feel the game plays fater"
"than what you thought, you can  "
"try the 'PAL' under the 'File'  "
"bar, which is lead by a         "
"'VideoMode'.                    "
"NTSC:60Hz       PAL:50Hz        ",

"Only one flashcard for two DS?  "
"    Yeah, this is OK~! Load the "
"nesDS on one DS, then load the  "
"rom file to start play. When    "
"done, you can remove the        "
"flashcard and insert it into    "
"the other one. Nice, ha?        "
"    This could be useful if you "
"guys dont have the same nes rom "
"and want to use the Nifi.       ",

"Frame-Skip for Pure-Soft:       "
"Framskip 2 is recommended, if   "
"you have a DS/DSL. 1 is better  "
"if you have a DSi.              "
"Framskip 1 for DS would be OK,  "
"because 0x38(56) fps is JUST OK.",

"Light Gun:                      "
"Click Game>Extra>LightGun to use"
"it. Press L&R buttons to active "
"main menu.                      ",

"Raw PCM:                        "
"Some game use APU4011 to play a "
"voice, which is called Raw PCM. "
"This is not simulated very well,"
"and you can click menu>Settings>"
"Config>Raw PCM On/Off to active/"
"inactive it.                    ",

"IPS:                            "
"You can use a .ips file to patch"
"a nes rom. First, you need to   "
"select a .ips file when choosing"
"a rom. Second, start game with  "
"the rom you want to patch. Note "
"that, the rom file will not be  "
"modified by the IPS.            ",

"Barcode:                        "
"This is ported from VirtuaNES.  "
"Click Menu>Game>Extra>Barcode to"
"use it. You can input the code  "
"by yourself or just click the   "
"random to get a result. When    "
"ready, click transfer to use it.",

"Palette sync:                   "
"Some games may change the       "
"palette mid-frame and this will "
"make the Hareware-Rendering get "
"the wrong color. If one game did"
"NOT show the color well in      "
"rendering mode Per-frame & Per- "
"Tile, you can try this.         "
"Click Game>Display>OnOrOff to   "
"change the status.              "
"You can NOT use this when Pal   "
"Timing or Pure-Soft mode has    "
"been set.                       ",

"Show All Pixels:                "
"Both the screens could be used  "
"to show all the pixels. It is   "
"recommended that you use        "
"'PerFrame' and 'Show All Pixels'"
"simultaneously. It will be buggy"
"if SP-pertile is used in this   "
"mode and the the main part of   "
"graphic is shown on the bottom. ",

"NSF Player:                     "
"Use <left/right> to select song,"
"use <up/down> to play/stop, use "
"'debug' menu to see the details."
};

touchstring aboutext[]={
	{64*4+16,"<<"}, {64*4+44,">>"},
	{-1,0}};

int nesds_about()
{
	static int tipnum = -1;
	int i;
	int fresh = 0;

	if(tipnum < 0) {
		fresh = 1;
		tipnum = 0;
	}
	if(menu_stat == 5) {
		menu_stat = 6;
		fresh = 1;
	}
	
	i=do_touchstrings(aboutext,0);
	if(touchstate==4) {
		switch(i) {
			case 0: 
				tipnum--;
				if(tipnum < 0)
					tipnum = sizeof(tips)/sizeof(tips[0]) - 1;
				fresh = 1;
				break;
			case 1:
				tipnum++;
				if(tipnum >= sizeof(tips)/sizeof(tips[0]))
					tipnum = 0;
				fresh = 1;
				break;
		}
	}
	
	if(fresh) {
		clearconsole();
		hex8(64*4+30, tipnum);
		consoletext(64*6, tips[tipnum], 0x0000); 
	}

	return 0;
}