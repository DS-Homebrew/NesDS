#include <nds.h>
#include <stdio.h>
#include <unistd.h>

//extern size_t _FAT_directory_ucs2tombs (char* dst, const unsigned short* src, size_t len);	//this should not be used, because fat.h does NOT list it.
size_t ucs2tombs(unsigned char* dst, const unsigned short* src, size_t len) {
	size_t i=0,j=0;
	for (;src[i];i++){
		if(src[i] <= 0x007f){
			if(!dst)j++;else{
				if(len-j<2)break;
				dst[j++] = ((src[i] & 0x007f)      );
			}
		}else if(src[i] <= 0x07ff){
			if(!dst)j+=2;else{
				if(len-j<3)break;
				dst[j++] = ((src[i] & 0x07c0) >>  6) | 0xc0;
				dst[j++] = ((src[i] & 0x003f)      ) | 0x80;
			}
		}else if((src[i] & 0xdc00) == 0xd800 && (src[i+1] & 0xdc00) == 0xdc00){
			if(!dst)j+=4;else{
				unsigned short z = (src[i]&0x3ff)+0x40;
				if(len-j<5)break;
				dst[j++] = ((z      & 0x0300) >>  8) | 0xf0;   //2
				dst[j++] = ((z      & 0x00fc) >>  2) | 0x80;   //6
				dst[j++] = ((z      & 0x0003) <<  4)           //2
					  | ((src[i+1] & 0x03c0) >>  6) | 0x80; //4
				dst[j++] = ((src[i+1] & 0x003f)      ) | 0x80; //6
			}i++;
		}else{
			if(!dst)j+=3;else{
				if(len-j<4)break;
				dst[j++] = ((src[i] & 0xf000) >> 12) | 0xe0;
				dst[j++] = ((src[i] & 0x0fc0) >>  6) | 0x80;
				dst[j++] = ((src[i] & 0x003f)      ) | 0x80;
			}
		}
	}
	if(dst)dst[j]=0;
	return j;
}

static u8 buf[768]; //lol

typedef u16 UnicodeChar;
#define ExtLinkBody_MaxLength (256)
#define ExtLinkBody_ID (0x30545845) // EXT0
typedef struct {
  u32 ID,dummy1,dummy2,dummy3; // dummy is ZERO.
  char DataFullPathFilenameAlias[ExtLinkBody_MaxLength];
  char DataPathAlias[ExtLinkBody_MaxLength];
  char DataFilenameAlias[ExtLinkBody_MaxLength];
  char NDSFullPathFilenameAlias[ExtLinkBody_MaxLength];
  char NDSPathAlias[ExtLinkBody_MaxLength];
  char NDSFilenameAlias[ExtLinkBody_MaxLength];
  UnicodeChar DataFullPathFilenameUnicode[ExtLinkBody_MaxLength];
  UnicodeChar DataPathUnicode[ExtLinkBody_MaxLength];
  UnicodeChar DataFilenameUnicode[ExtLinkBody_MaxLength];
  UnicodeChar NDSFullPathFilenameUnicode[ExtLinkBody_MaxLength];
  UnicodeChar NDSPathUnicode[ExtLinkBody_MaxLength];
  UnicodeChar NDSFilenameUnicode[ExtLinkBody_MaxLength];
} TExtLinkBody;

char* myfgets(char *buf,int n,FILE *fp){ //accepts LF/CRLF
	char *ret=fgets(buf,n,fp);
	if(!ret)return NULL;
	if(strlen(buf)&&buf[strlen(buf)-1]=='\n')buf[strlen(buf)-1]=0;
	if(strlen(buf)&&buf[strlen(buf)-1]=='\r')buf[strlen(buf)-1]=0;
	return ret;
}

void SplitItemFromFullPathAlias(const char *pFullPathAlias,char *pPathAlias,char *pFilenameAlias){
	u32 SplitPos=0;
	{
		u32 idx=0;
		while(1){
			char uc=pFullPathAlias[idx];
			if(uc==0) break;
			if(uc=='/') SplitPos=idx+1;
			idx++;
		}
	}

	if(pPathAlias){
		if(SplitPos<=1){
			pPathAlias[0]='/';
			pPathAlias[1]=0;
		}else{
			u32 idx=0;
			for(;idx<SplitPos-1;idx++){
				pPathAlias[idx]=pFullPathAlias[idx];
			}
			pPathAlias[SplitPos-1]=0;
		}
	}
	if(pFilenameAlias)strcpy(pFilenameAlias,&pFullPathAlias[SplitPos]);
}

extern int argc;
extern char **argv;
bool readFrontend(char *target)
{
	char dir[768];
	if(argc>1){
		strcpy(target,argv[1]);
	}else{
		return false;
	}
	SplitItemFromFullPathAlias(target,dir,NULL);
	chdir(dir);
	return true;
}

