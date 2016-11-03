#include <nds.h>
#include <fat.h>

#include "fatmore.h"
#include "fatfile.h"
#include "file_allocation_table.h"
#include "disc.h"
#include "partition.h"

//gbaemu4ds file stream code
FILE* ichflyfilestream;
volatile int ichflyfilestreamsize=0;

volatile u32 *sectortabel;
void * lastopen;
void * lastopenlocked;

PARTITION* partitionlocked;
FN_MEDIUM_READSECTORS	readSectorslocked;
u32 current_pointer = 0;
u32 allocedfild[buffslots];
u8* greatownfilebuffer;


__attribute__ ((aligned (4)))
u8 ichfly_readu8extern(int pos){
return ichfly_readu8(pos); //ichfly_readu8(pos);
}

__attribute__ ((aligned (4)))
u16 ichfly_readu16extern(int pos){
return ichfly_readu16(pos); //ichfly_readu16(pos);
}

__attribute__ ((aligned (4)))
u32 ichfly_readu32extern(int pos){
return ichfly_readu32(pos); //ichfly_readu32(pos);
}

//gbaemu4ds ichfly stream code
__attribute__ ((hot))
__attribute__ ((aligned (4)))
u8 ichfly_readu8(int pos) //need lockup
{
	// Calculate the sector and byte of the current position,
	// and store them
	int sectoroffset = pos % sectorsize;
	int mappoffset = pos / sectorsize;
	
	u8* asd = (u8*)(sectortabel[mappoffset*2 + 1]);
	
	if(asd != (u8*)0x0){
		return asd[sectoroffset]; //found exit here
	}
	else{
		sectortabel[allocedfild[current_pointer]] = 0x0; //reset

		allocedfild[current_pointer] = mappoffset*2 + 1; //set new slot
		asd = greatownfilebuffer + current_pointer * sectorsize;
		sectortabel[mappoffset*2 + 1] = (u32)asd;

		readSectorslocked(sectortabel[mappoffset*2], sectorscale, asd);
		current_pointer++;
		if(current_pointer == buffslots)
			current_pointer = 0;
	}
	return (asd[sectoroffset]);
}

__attribute__ ((hot))
__attribute__ ((aligned (4)))
u16 ichfly_readu16(int pos) //need lockup
{
	// Calculate the sector and byte of the current position,
	// and store them
	int sectoroffset = pos % sectorsize;
	int mappoffset = pos / sectorsize;
	
	u8* asd = (u8*)(sectortabel[mappoffset*2 + 1]);
	
	if(asd != (u8*)0x0){
		return *(u16*)(&asd[sectoroffset]); //found exit here
	}
	else{
		sectortabel[allocedfild[current_pointer]] = 0x0; //clear old slot

		allocedfild[current_pointer] = mappoffset*2 + 1; //set new slot
		asd = greatownfilebuffer + current_pointer * sectorsize;
		sectortabel[mappoffset*2 + 1] = (u32)asd;
	
		readSectorslocked(sectortabel[mappoffset*2], sectorscale, asd);

		current_pointer++;
		if(current_pointer == buffslots)
			current_pointer = 0;
	}
	return *(u16*)(&asd[sectoroffset]);
}

__attribute__ ((hot))
__attribute__ ((aligned (4)))
u32 ichfly_readu32(int pos) //need lockup
{
	// Calculate the sector and byte of the current position,
	// and store them
	int sectoroffset = pos % sectorsize;
	int mappoffset = pos / sectorsize;
	
	u8* asd = (u8*)(sectortabel[mappoffset*2 + 1]);
	
	if(asd != (u8*)0x0){
		return *(u32*)(&asd[sectoroffset]); //found exit here
	}
	else{
		sectortabel[allocedfild[current_pointer]] = 0x0;

		allocedfild[current_pointer] = mappoffset*2 + 1; //set new slot
		asd = greatownfilebuffer + current_pointer * sectorsize;
		sectortabel[mappoffset*2 + 1] = (u32)asd;
	
		readSectorslocked(sectortabel[mappoffset*2], sectorscale, asd);
		current_pointer++;
		if(current_pointer == buffslots)
			current_pointer = 0;
	}
	return *(u32*)(&asd[sectoroffset]);
}

__attribute__ ((hot))
__attribute__ ((aligned (4)))
void ichfly_readdma_rom(u32 pos,u8 *ptr,u32 c,int readal) //need lockup only alined is not working 
{
	// Calculate the sector and byte of the current position,
	// and store them
	int sectoroffset = 0;
	int mappoffset = 0;
	int currsize = 0;

	if(readal == 4) //32 Bit
	{
		while(c > 0)
		{
			mappoffset = pos / sectorsize;
			sectoroffset = (pos % sectorsize) /4;
			currsize = (sectorsize / 4) - sectoroffset;
			if(currsize == 0)
				currsize = sectorsize / 4;
			if(currsize > c) 
				currsize = c;
				
			u32* asd = (u32*)(sectortabel[mappoffset*2 + 1]);
			
			if(asd != (u32*)0x0)//found exit here (block has data)
			{
				/*
				//ori
				int i = 0; //copy
				while(currsize > i)
				{
					*(u32*)(&ptr[i*4]) = asd[sectoroffset + i];
					i++;
				}
				*/
				
				//coto
				//DC_FlushRange(source, sizeof(dataToCopy));
				//dmaCopy(source, destination, sizeof(dataToCopy));
				
				DC_FlushRange((u32*)&asd[sectoroffset], currsize);
				dmaCopyWords(
					0,
					(u32*)(&asd[sectoroffset]),
					(u32*)(&ptr[0]),
					(currsize*4)
				);
				
				c -= currsize;
				pos += (currsize * 4);
				ptr += (currsize * 4);
				//continue;
			}
			else{
				sectortabel[allocedfild[current_pointer]] = 0x0;
				allocedfild[current_pointer] = mappoffset*2 + 1; //set new slot
				asd = (u32*)(greatownfilebuffer + current_pointer * sectorsize);
				sectortabel[mappoffset*2 + 1] = (u32)asd;
				readSectorslocked(sectortabel[mappoffset*2], sectorscale, asd);
				current_pointer++;
				if(current_pointer == buffslots)
					current_pointer = 0;
				//ori
				/*
				int i = 0; //copy
				while(currsize > i)
				{
					*(u32*)(&ptr[i*4]) = asd[sectoroffset + i];
					i++;
				}
				*/
				
				//coto
				//DC_FlushRange(source, sizeof(dataToCopy));
				//dmaCopy(source, destination, sizeof(dataToCopy));
				
				DC_FlushRange((u32*)&asd[sectoroffset], currsize);
				dmaCopyWords(
					0,
					(u32*)(&asd[sectoroffset]),
					(u32*)(&ptr[0]),
					(currsize*4)
				);
				
				c -= currsize;
				pos += (currsize * 4);
				ptr += (currsize * 4);
			}
		}
	}
	else //16 Bit
	{
		while(c > 0)
		{
			sectoroffset = (pos % sectorsize) / 2;
			mappoffset = pos / sectorsize;
			currsize = (sectorsize / 2) - sectoroffset;
			if(currsize == 0)currsize = sectorsize / 2;
			if(currsize > c) currsize = c;

			u16* asd = (u16*)(sectortabel[mappoffset*2 + 1]);
			//iprintf("%X %X %X %X %X %X\n\r",sectoroffset,mappoffset,currsize,pos,c,sectorsize);
			if(asd != (u16*)0x0)//found exit here
			{
				/*
				//ori
				int i = 0; //copy
				while(currsize > i)
				{
					*(u16*)(&ptr[i*2]) = asd[sectoroffset + i];
					i++;
				}
				*/
				
				//coto
				//DC_FlushRange(source, sizeof(dataToCopy));
				//dmaCopy(source, destination, sizeof(dataToCopy));
				
				DC_FlushRange((u32*)&asd[sectoroffset], currsize);
				dmaCopyHalfWords(
					0,
					(u16*)(&asd[sectoroffset]),
					(u16*)(&ptr[0]),
					(currsize*2)
				);
				
				
				c -= currsize;
				ptr += (currsize * 2);
				pos += (currsize * 2);
				//continue;
			}
			else{
				sectortabel[allocedfild[current_pointer]] = 0x0;
				allocedfild[current_pointer] = mappoffset*2 + 1; //set new slot
				asd = (u16*)(greatownfilebuffer + current_pointer * sectorsize);
				sectortabel[mappoffset*2 + 1] = (u32)asd;
				
				readSectorslocked(sectortabel[mappoffset*2], sectorscale, asd);
				current_pointer++;
				if(current_pointer == buffslots)current_pointer = 0;
				/*
				//ori
				int i = 0; //copy
				while(currsize > i)
				{
					*(u16*)(&ptr[i*2]) = asd[sectoroffset + i];
					i++;
				}
				*/
				
				//coto
				//DC_FlushRange(source, sizeof(dataToCopy));
				//dmaCopy(source, destination, sizeof(dataToCopy));
				
				DC_FlushRange((u32*)&asd[sectoroffset], currsize);
				dmaCopyHalfWords(
					0,
					(u16*)(&asd[sectoroffset]),
					(u16*)(&ptr[0]),
					(currsize*2)
				);
				
				c -= currsize;
				ptr += (currsize * 2);
				pos += (currsize * 2);
			}
		}
	}
}

void generatefilemap(int size)
{
	FILE_STRUCT* file = (FILE_STRUCT*)(lastopen);
	lastopenlocked = lastopen; //copy
	PARTITION* partition;
	uint32_t cluster;
	int clusCount;
	partition = file->partition;
	partitionlocked = partition;

	readSectorslocked = file->partition->disc->readSectors;
	iprintf("generating file map (size %d Byte)",((size/sectorsize) + 1)*8);
	sectortabel =(u32*)malloc(((size/sectorsize) + 1)*8); //alloc for size every Sector has one u32
	greatownfilebuffer =(u8*)malloc(sectorsize * buffslots);

	clusCount = size/partition->bytesPerCluster;
	cluster = file->startCluster;


	//setblanc
	int i = 0;
	while(i < (partition->bytesPerCluster/sectorsize)*clusCount+1)
	{
		sectortabel[i*2 + 1] = 0x0;
		i++;
	}
	i = 0;
	while(i < buffslots)
	{
		allocedfild[i] = 0x0;
		i++;
	}


	int mappoffset = 0;
	i = 0;
	while(i < (partition->bytesPerCluster/sectorsize))
	{
		sectortabel[mappoffset*2] = _FAT_fat_clusterToSector(partition, cluster) + i;
		
		//debugging (fat fs sector numbers of image rom) 
		//iprintf("(%d)[%x]",(int)i,(unsigned int)_FAT_fat_clusterToSector(partition, cluster) + i);
		
		mappoffset++;
		i++;
	}
	while (clusCount > 0) {
		clusCount--;
		cluster = _FAT_fat_nextCluster (partition, cluster);

		i = 0;
		while(i < (partition->bytesPerCluster/sectorsize))
		{
			sectortabel[mappoffset*2] = _FAT_fat_clusterToSector(partition, cluster) + i;
			mappoffset++;
			i++;
		}
	}

}

void getandpatchmap(u32 offsetgba,u32 offsetthisfile)
{
	FILE_STRUCT* file = (FILE_STRUCT*)(lastopen);
	PARTITION* partition;
	uint32_t cluster;
	int clusCount;
	partition = file->partition;

	clusCount = offsetthisfile/partition->bytesPerCluster;
	cluster = file->startCluster;

	int offset1 = (offsetthisfile/sectorsize) % partition->bytesPerCluster;

	int mappoffset = offsetthisfile/sectorsize;
	while (clusCount > 0) {
		clusCount--;
		cluster = _FAT_fat_nextCluster (partition, cluster);
	}
	sectortabel[mappoffset*2] = _FAT_fat_clusterToSector(partition, cluster) + offset1;
}
