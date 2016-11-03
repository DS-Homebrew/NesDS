#include <nds.h>
#include <stdio.h>
#include <string.h>
#include "ds_misc.h"
#include "c_defs.h"

int ips_stat = 0;		// 0 = no ips, 1 = already has one.
int ips_len = 0;		//length of ips patch.
char *ips_start = (char *)rom_start + ROM_MAX_SIZE - MAX_IPS_SIZE; //alloca the ips patch here.

void load_ips(const char *name)
{
	FILE *fp;

	ips_stat = 0;
	ips_len = 0;

	fp = fopen(name,"rb");
	if(!fp)
		return;

	ips_len = fread(ips_start,1,MAX_IPS_SIZE,fp);

	if(ips_len > 0)
		ips_stat = 1;
	else 
		ips_stat = 0;

	fclose(fp);
}

unsigned int read24(const void *p){
	const unsigned char *x=(const unsigned char*)p;
	return x[2]|(x[1]<<8)|(x[0]<<16);
}

unsigned short read16(const void *p){
	const unsigned char *x=(const unsigned char*)p;
	return x[1]|(x[0]<<8);
}

int ipspatch(char *pfile, int *sizfile, const char *pips, const unsigned int sizips){ //pass pfile=NULL to get sizfile.
	unsigned int offset=5,address=0,size=-1,u;
	if(sizips<8||memcmp(pips,"PATCH",5))return 2;
	if(!pfile)*sizfile=0;
	while(1){
		if(offset+3>sizips)return 1;address=read24(pips+offset);offset+=3;
		if(address==0x454f46&&offset==sizips)break;
		if(offset+2>sizips)return 1;size=read16(pips+offset);offset+=2;
		if(size){
			if(offset+size>sizips)return 1;
			if(!pfile){
				if(*sizfile<address+size)*sizfile=address+size;
				offset+=size;
				continue;
			}
			if(address+size>*sizfile)return 1;
			//fprintf(stderr,"write 0x%06x %dbytes\n",address,size);
			memcpy(pfile+address,pips+offset,size);
			offset+=size;
		}else{
			if(offset+3>sizips)return 1;size=read16(pips+offset);offset+=2;
			if(!pfile){
				if(*sizfile<address+size)*sizfile=address+size;
				offset++;
				continue;
			}
			if(address+size>*sizfile)return 1;
			//fprintf(stderr,"fill  0x%06x %dbytes\n",address,size);
			for(u=address;u<address+size;u++)pfile[u]=pips[offset];
			offset++;
		}
	}
	return 0;
}

int patch_ips( char *pIPS, char * pROM, int imagesize, int ipssize ){return ipspatch(pROM,&imagesize,pIPS,ipssize);}

void do_ips(int romsize)
{
	if(ips_stat)
		patch_ips(ips_start, (char *)rom_start, romsize, ips_len);
}
