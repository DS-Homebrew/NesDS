#ifndef GBAEMU4DS_FSTREAM
#define GBAEMU4DS_FSTREAM

#include <nds.h>
#include <fat.h>

//Prototypes for ichfly's extended FAT driver
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "fatfile.h" //required for linking FILE_STRUCT and other FAT related initializers

//extra settings for ownfilebuffer
#define sectorscale 1 //1,2,4,8
#define buffslots 255
#define sectorsize 0x200*sectorscale
//#define sectorbinsz clzero(sectorsize)

//extra settings for ownfilebuffer
//#define chucksizeinsec 1 //1,2,4,8
//#define buffslots 255
//#define chucksize 0x200*chucksizeinsec


#define u32size (sizeof(u32))
#define u16size (sizeof(u16))
#define u8size (sizeof(u8))

#define sectorsize_u32units ((sectorsize/u32size)-1) //start from zero
#define sectorsize_u16units ((sectorsize/u16size)-1)
#define sectorsize_u8units ((sectorsize/u8size)-1)

#define sectorsize_int32units (sectorsize/u32size) 	//start from real number 1
#define sectorsize_int16units (sectorsize/u16size) 	//start from real number 1
#define sectorsize_int8units (sectorsize/u8size) 	//start from real number 1

#define strm_buf_size (int)(1024*256)

#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifdef uppern_read_emulation
	extern FILE* ichflyfilestream;
	extern volatile int ichflyfilestreamsize;
#endif

extern	u8 ichfly_readu8extern(int pos);
extern 	u16 ichfly_readu16extern(int pos);
extern 	u32 ichfly_readu32extern(int pos);

extern 	u8 ichfly_readu8(int pos);
extern 	u16 ichfly_readu16(int pos);
extern 	u32 ichfly_readu32(int pos);
extern 	void ichfly_readdma_rom(u32 pos,u8 *ptr,u32 c,int readal);

extern void closegbarom();
extern void generatefilemap(int size);
extern void getandpatchmap(u32 offsetgba,u32 offsetthisfile);

extern volatile  u32 *sectortabel;
extern void * lastopen;
extern void * lastopenlocked;

extern PARTITION* partitionlocked;
extern FN_MEDIUM_READSECTORS	readSectorslocked;
extern u32 current_pointer;
extern u32 allocedfild[buffslots];
extern u8* greatownfilebuffer;

#ifdef __cplusplus
}
#endif
