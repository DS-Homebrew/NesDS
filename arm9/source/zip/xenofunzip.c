/*
 * xenofunzip - gzip/zip decompression interface for zlib, based on info-zip's funzip
 * note: xenogzip uses gzio but xenofunzip uses normal inflateInit2()/inflate().
 */

#if defined(ARM9) || defined(ARM7)
#include <stdio.h>
#include <string.h>
#include <nds.h>
#include "c_defs.h"
#include "zlib.h" // dszip: put zlib stuff also here.
#define min(a,b) ((a)<(b)?(a):(b))
#define err(e,m) {consoletext(64,e==-4?"memory error":m,0);return e;}

// what is this messy hack? bah
static int zzz;
static void xfree(void *opaque, void *address){}
static void* xcalloc(void *opaque, unsigned items, unsigned size){
	unsigned char *ret = rom_start+zzz; // the &io_dldi technique lol.
	memset(ret,0,items*size);
	zzz+=items*size;
	fprintf(stderr,"%08x\n",(unsigned int)ret);
	return ret;
}

#else
#include "../xenobox.h"
#define err(e,m) {fprintf(stderr,"%s\n",m);return e;}
#endif

//minimal size, for embedded env.
#define BUFFER_SIZE 512

/* PKZIP header definitions */
#define ZIPMAG 0x4b50           /* two-byte zip lead-in */
#define LOCREM 0x0403           /* remaining two bytes in zip signature */
#define LOCSIG 0x04034b50L      /* full signature */
#define LOCFLG 4                /* offset of bit flag */
#define  CRPFLG 1               /*  bit for encrypted entry */
#define  EXTFLG 8               /*  bit for extended local header */
#define LOCHOW 6                /* offset of compression method */
#define LOCTIM 8                /* file mod time (for decryption) */
#define LOCCRC 12               /* offset of crc */
#define LOCSIZ 16               /* offset of compressed size */
#define LOCLEN 20               /* offset of uncompressed length */
#define LOCFIL 24               /* offset of file name field length */
#define LOCEXT 26               /* offset of extra field length */
#define LOCHDR 28               /* size of local header, including LOCREM */
#define EXTHDR 16               /* size of extended local header, inc sig */

/* GZIP header definitions */
#define GZPMAG 0x8b1f           /* two-byte gzip lead-in */
#define GZPHOW 0                /* offset of method number */
#define GZPFLG 1                /* offset of gzip flags */
#define  GZPMUL 2               /* bit for multiple-part gzip file */
#define  GZPISX 4               /* bit for extra field present */
#define  GZPISF 8               /* bit for filename present */
#define  GZPISC 16              /* bit for comment present */
#define  GZPISE 32              /* bit for encryption */
#define GZPTIM 2                /* offset of Unix file modification time */
#define GZPEXF 6                /* offset of extra flags */
#define GZPCOS 7                /* offset of operating system compressed on */
#define GZPHDR 8                /* length of minimal gzip header */

#define STORED            0    /* compression methods */
#define SHRUNK            1
#define REDUCED1          2
#define REDUCED2          3
#define REDUCED3          4
#define REDUCED4          5
#define IMPLODED          6
#define TOKENIZED         7
#define DEFLATED          8
#define ENHDEFLATED       9
#define DCLIMPLODED      10
#define BZIPPED          12
#define LZMAED           14
#define IBMTERSED        18
#define IBMLZ77ED        19
#define WAVPACKED        97
#define PPMDED           98
#define NUM_METHODS      17     /* number of known method IDs */

/////
typedef unsigned int   ulg;
typedef unsigned short ush;
typedef unsigned char  uch;

#define SH(p) ((ush)(uch)((p)[0]) | ((ush)(uch)((p)[1]) << 8))
#define LG(p) ((ulg)(SH(p)) | ((ulg)(SH((p)+2)) << 16))

static int funzipstdio(FILE *in, FILE *out){
	int encrypted;
	ush n;
	uch h[LOCHDR];                // first local header (GZPHDR < LOCHDR)
	int g = 0;                    // true if gzip format
	unsigned int method = 0;      // initialized here to shut up gcc warning
	int size = -1;

	//info-zip's funzip stuff
	n = fgetc(in);  n |= fgetc(in) << 8;
	if (n == ZIPMAG){
		if (fread((char *)h, 1, LOCHDR, in) != LOCHDR || SH(h) != LOCREM)
			err(3, "invalid zipfile");
		switch (method = SH(h + LOCHOW)) {
			case STORED:
			case DEFLATED:
				break;
			default:
				err(3, "first entry not deflated or stored");
				break;
		}
		for (n = SH(h + LOCFIL); n--; ) g = fgetc(in);
		for (n = SH(h + LOCEXT); n--; ) g = fgetc(in);
		g = 0;
		size = LG(h+LOCSIZ);
		encrypted = h[LOCFLG] & CRPFLG;
	}else if (n == GZPMAG){
		if (fread((char *)h, 1, GZPHDR, in) != GZPHDR)
			err(3, "invalid gzip file");
		if ((method = h[GZPHOW]) != DEFLATED && method != ENHDEFLATED)
			err(3, "gzip file not deflated");
		if (h[GZPFLG] & GZPMUL)
			err(3, "cannot handle multi-part gzip files");
		if (h[GZPFLG] & GZPISX){
			n = fgetc(in);  n |= fgetc(in) << 8;
			while (n--) g = fgetc(in);
		}
		if (h[GZPFLG] & GZPISF)
			while ((g = fgetc(in)) != 0 && g != EOF) ;
		if (h[GZPFLG] & GZPISC)
			while ((g = fgetc(in)) != 0 && g != EOF) ;
		g = 1;
		encrypted = h[GZPFLG] & GZPISE;
	}else
		err(3, "input not a zip or gzip file");

	//now in points to deflated entry. let's just inflate it using zlib.

	//if entry encrypted, decrypt and validate encryption header
	if (encrypted)
		err(3, "encrypted zip unsupported");

	//decompress
	if (g || h[LOCHOW]){ //deflate
		Bytef *ibuffer, *obuffer;
		//uInt isize, osize;
		z_stream z;
		int result;

		zzz=0;
		z.zalloc = xcalloc;
		z.zfree = xfree;
		z.opaque = Z_NULL;
 
		result = inflateInit2( &z,-MAX_WBITS );
		if( result != Z_OK ) {
			err(result, z.msg );
		}

		//on nesDS dszip, never try to free these STATICALLY ALLOCATED buffer.
		ibuffer = xcalloc(NULL,1,BUFFER_SIZE);
		obuffer = xcalloc(NULL,1,BUFFER_SIZE);
    
		z.next_in = NULL;
		z.avail_in = 0;
		z.next_out = obuffer;
		z.avail_out = BUFFER_SIZE;
    
		for(;;){
			if( z.avail_in == 0 ){
				z.next_in = ibuffer;
				if(size>=0){
					if(size>0){
						z.avail_in = fread( ibuffer, 1, min(size,BUFFER_SIZE), in );
						size-=min(size,BUFFER_SIZE);
					}
				}else{
					z.avail_in = fread( ibuffer, 1, BUFFER_SIZE, in );
				}
			}

			result = inflate( &z, Z_SYNC_FLUSH ); //Z_NO_FLUSH? aww small buffer size...
			if( result != Z_OK && result != Z_STREAM_END ) {
				//free(ibuffer);free(obuffer);
				inflateEnd( &z );
				//char x[10];sprintf(x,"%d",result);
				//consoletext(64,x,0);while(1);
				err(result, z.msg );
			}
 
			fwrite( obuffer, 1, BUFFER_SIZE - z.avail_out, out );
			z.next_out = obuffer;
			z.avail_out = BUFFER_SIZE;

			if(result==Z_STREAM_END)break;
		}
		//free(ibuffer);free(obuffer);
		inflateEnd( &z );
	}else{ //stored
		while (size--) {
			int c = fgetc(in);fputc(c,out);
		}
	}

	//should check CRC32 but...
	return 0;
}

#if defined(ARM9) || defined(ARM7)
int do_decompression(const char *inname, const char *outname){ //dszip frontend
	FILE *in=fopen(inname,"rb");
	if(!in)return -1;
	FILE *out=fopen(outname,"wb");
	if(!out){fclose(in);return -1;}
	int ret = funzipstdio(in,out);
	fclose(in);fclose(out);
	return ret;
}
#else
int xenofunzip(const int argc, const char **argv){
	if(isatty(fileno(stdin))||isatty(fileno(stdout))){
		fprintf(stderr,
			"xenofunzip - gzip/zip decompression interface for zlib\n"
			"based on info-zip's funzip\n"
			"Both stdin and stdout have to be redirected\n"
		);
		return -1;
	}
	return funzipstdio(stdin,stdout);
}
#endif
