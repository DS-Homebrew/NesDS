nesDS, using toolchain devkitARM.
We spent a few weeks to port the original nesDS project to the GCC toolchain. Then we made a new EX Edition, and made it possible to emulate the the NES/FC games that the origianl nesDS didn't work well.
Since the 0.40 version, I ported the code of EX Edtion to the original nesDS, now it is the best nes-emulator~!

If you found any bug on nesDS, just tell me. Maybe I could fix it.

2011-3-23
avenir contributed some codes to version 0.45a.

2011-9-32
avenir contributed some codes to version 1.0a.

Q: What can I do if some pics had been crashed?
A: You can try the 'sprite per-line type' under the 'Display' menu bar. If it does not work, just tell me, I will try to fix it.

CAUTION:
The extlink may cause some problems to nesDS, if does, please try the new moonshell.
Even if the sram is auto saved, it may be lost. This may be related to the dldi cache... If you have the same problem, just shutdown your DS when rom menu is shown.

The coming figures are:
????
Tell me what you need.

UPDATES:
--------
2014-08:
mapper5 update.

current:
FDS and vcr6 sound are enabled in NSF mode
sprite0y is updated in sp-pertile mode

1.3a:
alpha blend fixed.
touch the current menu item to hide menu.
cheat list bug fixed. fix the flicking of cheat list.
all saving flushed.
Sound update, the volume = sin(original * pi / 2) ^ 0.7, like a linear to log conversion.
Load and save slot number merged to one.
nsf play supported, use <left/right> to select song, use <up/down> to play/stop, use 'debug' menu to see the details.

1.2b:
vcr6 sound channel for mapper24 and mapper26 is added.
a sound reset button is added to menu>settings>config, which is used when the sound goes bad,
when close and open the DS, this is probly needed.
Mapper253 is added.
fds saving is disabled when the game is not a fds.

CRITICAL NOTE:
the sound rendering has almost reached the ability of arm7, so .....
the arm7 will auto detect the IF, by which to fix the mess of sound.

1.1b2:
every apu channel mirrored to a nds sound channel

1.1b:
sound update, fds sound works fine.
AutoFire config can be saved.
game is more stable & sound goes bad?
binary files converted to .c/.h, can be compiled by devkitARM r39

1.1a:
fds sound added, just works.
Mapper198 added, SRAM saving not supported.
Sound update.
Gesture update.

1.0:
rom patch database added, which can select a PAL/NTSC timing or fix the header of rom.
Nifi fixed.
'About' flicking fixed.
Better flicker when PALTIMING is enabled.
dswifix(which is for nifi) src is added.

1.0b:
Mapper240 added.
fixed the tmpfile.
DPCM weakened, sounds better?
A bug with ppustat fixed. e.g.'teenage mutant ninja turtles'
A bug with palette fixed.
Patch update. Battleloads (Europe) <Double Dragons> added.
SRAM can be saved whatever a game supports.

1.0a:
code of .gz replaced with a new one, still works.
.zip supported. NOTE: Only one file is allowed in the .zip archive.
code of ips been re-written.
'Double Screen Show' is supported to show all the pixels at the same time. Check 'About' for more info.
Sprites with SP-perframe updated.
Some bugs related to 'Scaling' are fixed.
Some other changes.
Thanks to avenir.

0.56a:
Short-Cuts updated. Fast forward & rewind can be changed.
Screen scaling can be saved to nesDS.ini
gzip file supported. only .gz could work. Thanks to dszip. The decompression of large files would take a while.
compiled with latest libnds(as required).

0.55b:
Sound update.
Sprites update.
A bug of Memory fixed.
Palette sync added, click Menu > Game > Display > OnOrOff to change. More info, see the 'About'.
Pal sync needed:Fantastic Adventures of Dizzy, Micro Machines, Wizards & Warriors, Feng Shen Bang.

0.55a:
A bug with nesDS.ini fixed, works with latest devkitARM-r34
Saving for FDS added. Menu > Game > Extra > Save FDS.
Shows time on the top menu.
Mapper 216 189 added. e.g. Magic Jewelry 2, Master Fight 2, Street Fighter 4...
Some others..

0.54a:
Big nose freak out update.
mapper225 226 227 229 230 231 255 added.
Sound enhanced.
Raw PCM update, nearly perfect.
sprite0y update.
nifi update.

NOTE: unstable with devkitARM r33, using r32 instead.


0.53b:
Mapper1 updated.
Auto-fire adjusting added.
Swap-Screens disabled if LIGHTGUN active.
sprite0y for SP-pertile fixed.
Careful to use Swap-Screens, which may shutdown DS.

0.53a:
IPS supported. First, load a .ips file, then load the rom to start a patched game. The rom file won't be changed. The ips file should be smaller than 512kB.
Barcode supported. Click Menu>Game>Extra>Barcode
Gesture supported. Click Menu>Config>Short-Cuts to configure. When the menu is hidden or the LIGHTGUN is enabled, you can touch the sub-screen to draw a gesture.
Mapper245 added.
Mapper16 updated.
Raw PCM updated.
'SP-Pertile' updated.	E.g. The issue with Super Mario 3 is fixed.
Some others...

0.52a:
The 'menu' is re-designed.
Raw PCM supported, not perfect, can be switched off in menu>Settings>Config.
Settings of nesDS can be written to 'nesDS.ini' at runtime, done in menu>Settings.
Short-Cuts can be configured in menu>Settings.
'LightGun' is placed in menu>Game>Extra, 'Micphone' and 'FDS disk' are also added there. 'Micphone' is not tested.
Nothing more.


0.51a:
Roll back some updates in 0.50b.
Mapper90 added. It works fine. You need to reload the nes rom to get a 'Soft-Reset'.
Light-Gun added. Under the 'Input' bar, click 'No LightGun' to active Light-Gun. When shooting, hold L-button and touch the sub-screen. 'Swap screens' is recommended. R-button can be used to rewind game play.
sprite0y calculation for SP-pertile corrected, better.
V-flip for SP-pertile corrected, better.
A patch file added, used to correct the header of rom or modify the settings of nesDS.
Below shows the games patched:
PRGCRC		Name
0x33AA		Akumajou Densetsu
0x0A62		Joe & Mac
0x49B3		TMNT 1
0xE91E		Duck Hunt(JUE)
0x15CF		Wild Gunman
0x15CF		Gum Shoe
0x9F65		Hogan's Alley (JU)
0xB2B5		Three Eyed ONE/Mitsume Ga Tooru
0x8A35		Feng Shen Bang(Chinese)
0xD796		Alien Syndrome (J)

0.50b:
nesDS.ini commented.
nesDS.ini: ScreenSwap added. If your DS' top-screen did not work well, set this value to 1.
mapper 19, 71, 118 updated.
NES cycles-per-scanline modified to 121, to make the graphic more smooth. E.g. tmnt, Akumajou Densetsu.... Also makes Joe&Mac work fine.
A sound bug fixed, which may cause a panic....
Sub-screen will be closed if there is a NES_RESET.
Cheat list can be loaded/saved from/to a file. EXTENTION:.cht
FrameSkip for Pure-Soft rendering can be adjusted. If you have a DSi, frameskip 1 would be OK; For DS/DSL, frameskip 2 is recommended.
frameskip 1 means that the graphic is updated at 30fps. 2 for 20fps. On the older nesDS, frameskip 2 equals to 30fps.
sprite0y changed, which makes the graphic better. e.g. Super Mario...
CRAM added..

0.50a2:
All memory needed is pre-allocated, and all malloc() are deleted.. This is done for those who cannot run nesDS well.
The average length of roms' names MUST be lower than 64bytes, for saving memory.
MAX_ROM_SIZE is set to 3M.
Delay for multi-player is slightly lower.
Mapper4 is updated. e.g. tmnt3 works well now.
Path for nesDS.ini is updated. Available paths now are:"/","/_dstwoplug/","/ismartplug/","/moonshl2/extlink/","/_iMenu/_ini/","/_plugin_/"

0.50a:
Nifi/Multi-players supported.
Cheat re-added.
About/Help tip added.
NTSC/PAL timing supported.
Roms menu cached, which will speed up the rom menu when start another game.
some bugs fixed.

0.48b:
Mapper68 updated. e.g. After Burner(U)
Some bugs fixed.
nesDS.ini updated.

0.48a:
software-render re-added, to deal with the mappers 9, 10, 19, etc.

0.47b:
sound update.
L+UP to show NES on top screen when playing.
L+DOWN for bottom screen.

0.47a:
sound enhanced. MAX VOL x2.
fds supported. Do NOT use realtime saving and loading.("save state" and "load state"). Safe to use KEY_R and KEY_L.
R+UP = disk A
R+LEFT = disk B
R+DOWN = disk C
R+RIGHT = disk D

0.46a:
mapper163 added..
sound updated.
MAX FILES enlarged.

0.45b:
The memory region of "NES" is relocated from 0x23f0000 to 0x23ec000. advised by avenir. Now the nesDS on my DS could return to the homebrew menu.
A software for sprite-scaling is added. Select 'Per-scanline' to active it.
Mid-frame BG pal refresh is supported. Some games like 'Wizards Warriors' work fine.
Some others not important...

0.45a_v2:
sound fixed..

0.45a:
avenir write a patch to nesDS, what's new? He said...
@----------- start -----------@
Extended the reset to "If not loaded from hbmenu/xenofile, returns DSi/3DS menu on DSi/3DS".
stringsort() is now a wrapper for qsort().
extlink now accepts multibyte filename thanks to Unicode support.
Directory listing is shown the same way as WinNT(8.3 lower case). <- If you name a file all lower case in 8.3...
/nesDS.ini is used for configuration(minIni).
@----------- end   -----------@
updates:
Add the shout-cuts for configuration.
Sound fixed.. better than 0.44b. Almost no noise(not the noise channel).
sprite0y of 'per-scanline' fixed.
h-blank interrupt handler added, which was removed since 0.44b. 
some other chanegs.. No update for mappers.

0.44b:
Since the nesDS file is larger, this version is NOT recommended for those who just want to play nes games.
Port the whole project to devkitPro, using libnds, libfat....
Almost no update, but some figures may be worse. e.g. sound with the games that read reg4015. Some games' sounds work better... - -!
You guys can try 'Start+Select+R+L' to exit your nesDS and return to the main menu of flash-card. On mine, it just shotdown my DS(R4SDHC with kernel1.34, no help with moonshell2 either).
Since this version, the mem region cannot be accessed freely, be careful if anyone wants to write a patch.
The libnds and libfat are too big... 128k around. Shit that!

0.44a:
A bug of cartflags was fixed, which will definitely make the game unable to save..
something about 'fetch_c' was changed, which may cause some problem. the bug logged in 0.43 was related to this.
set the nes ram reset value to 0x0, not 0xFFFFFFFF, which will cause the 'Super Mario' starting from world 0-1.
Supprised that karateka(j) works now... 

0.43:
Warning: A bug of SRAM was fixed. It may cause the games that use SRAM crashed.... 

0.43b:
DPCM/DMC suppoted! I should say that this is just for testing.... DPCM causes a lot of sound crashes, and I am busy fixing them.. well, Mario 3 works fine, also 'Chan'..
no other updates.
I need to slow down this project...

0.42b:
no sound updates.
short-cuts added..
extlink supported.
some unused files of sound are removed. It is much clear now...
no more...

0.41b:
mapper 9, 10, 118, 228 updated/fixed. Punch-Out, Action 52 IN 1, and some others games play well now.
The 'Flicker' function was slightly fixed. Our eyes will not be that hurt now ;p
A new bg render method was added, but not actived in this version, there are still alot work to do.

0.40:
'roll back' fixed... I did not release this version because there is no need to...

0.40b
named as 'nesDS 0.40', not 'nesDS EX 0.40', because the two versions had been merged into one.
some bugs fixed ....

0.31
mapper 23, 25 supported
rendering method changed
scaling supported

0.30beta
All the rendering sections has been re-written. Uses the NDS hardware to emu the NES graphic.
Much better speed and sound.

0.22
uses software to cal the CRC, same as Virtuanes.
mapper074 updataed, supporting some special games.
mapper0, 1, 4 updated.
fixed some bugs..

0.22b
mappers supported: 0, 1, 2, 3, 4, 10, 16, 19, 74, 246 (EX's mapper files is very different from the original.)
function added: cheat


CHANGES£º
--------
Touch screen should work better now
Fixed bug that was causing ARM7 to crash on emulators (ideas and desemu inputs were not working) 

CAUTIONS:
---------
Run the nesDS EX Edition on ideas may cause a crush, because ideas does NOT support "swi".

NOTES:
------
All other functionality should be identical to the original. nesDS inputs now work properly on 
emulators. You can run the nesDS on ideas by DLDI patching it with the R4 dldi patch using
dlditool. You must then enable DLDI support for R4 under File->Properties. You can also run nesDS 
on desmume but you will need to create a filesystem image from some files and embed the files to 
the emulator (you need to use fcsr for this).


COMPILING:
----------
You need devkitARM to compile this project. If you are compiling on windows you also need mingw. On linux you will need to have make installed. 

The project compiles on windows and linux using devkitARM r32 (devkitPro). To compile on windows use
msys-1.0.15 (devkitPro) as well. You do not need anyhting else to comiple the project.

Compiling on windows:

1) extract devkitARM to a folder
2) extract msys to a folder
3) add DEVKITARM environment variable  and set its value to the path where you extracted devkitARM, 
e.g: /c/devkitARM (must be linux style path!)
4) (OPTIONAL) add path to msys binaries in you windows path, e.g: c:\msys\bin (must be windows style path!)

You only need to do step 4 if you want to compile from the windows command shell. You can compile the project
without step 4 by launching mingw using msys.bat in the msys folder.

5) change to the project main directory, either in the windows command shell (step4 required) or mingw then
type make.

Compiling on linux:

1) extract devkitARM
2) create a DEVKITARM shell variable with the path to where you extracted devkitARM, e.g: /usr/local/devkitARM

You can create a variable in /etc/profile or in your home directory .bash_profile file as follows

export DEVKITARM=/usr/local/devkitARM

or just type this command in the shell before typing make


3) change to the project main directory then type make.


To delete all object files type:

make clean

in the main project directory


If you make changes to the emulator and want to add them to this project or if you want to join the project notify us
on http://sourceforge.net/projects/nesds


CREDITS:
--------
Original nesDS team:
Coding: loopy, FluBBa
More code:  Dwedit, tepples, kuwanger, chishm
Sound: Mamiya

___________________________
ported to gcc by minitroopa
EX Edition made by huiminghao
0.4x Edition made by huiminghao


more credits:
-------------
avenir
