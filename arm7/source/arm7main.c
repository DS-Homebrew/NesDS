#include <nds.h>
#include <string.h>
#include "c_defs.h"

#include "audiosys.h"
#include "handler.h"

#define MIXFREQ 0x5e00
#define MIXBUFSIZE 128

s16 buffer[MIXBUFSIZE*20];

void readAPU(void);
void resetAPU(void);

static int chan = 0;

const short logtable[1024] = {
0,10,17,23,28,33,38,42,47,51,54,58,62,66,69,73,76,79,
82,86,89,92,95,98,101,104,107,110,113,115,118,121,124,126,
129,132,134,137,139,142,145,147,150,152,155,157,159,162,164,167,
169,171,174,176,178,181,183,185,188,190,192,194,197,199,201,203,
205,208,210,212,214,216,218,220,222,225,227,229,231,233,235,237,
239,241,243,245,247,249,251,253,255,257,259,261,263,265,267,269,
271,272,274,276,278,280,282,284,286,288,289,291,293,295,297,299,
301,302,304,306,308,310,311,313,315,317,319,320,322,324,326,327,
329,331,333,334,336,338,340,341,343,345,346,348,350,352,353,355,
357,358,360,362,363,365,367,368,370,372,373,375,377,378,380,381,
383,385,386,388,390,391,393,394,396,398,399,401,402,404,406,407,
409,410,412,413,415,416,418,420,421,423,424,426,427,429,430,432,
433,435,436,438,439,441,442,444,445,447,448,450,451,453,454,456,
457,459,460,462,463,465,466,468,469,470,472,473,475,476,478,479,
480,482,483,485,486,488,489,490,492,493,495,496,497,499,500,502,
503,504,506,507,509,510,511,513,514,515,517,518,520,521,522,524,
525,526,528,529,530,532,533,534,536,537,538,540,541,542,544,545,
546,548,549,550,551,553,554,555,557,558,559,561,562,563,564,566,
567,568,570,571,572,573,575,576,577,578,580,581,582,583,585,586,
587,588,590,591,592,593,595,596,597,598,600,601,602,603,604,606,
607,608,609,610,612,613,614,615,616,618,619,620,621,622,624,625,
626,627,628,629,631,632,633,634,635,636,638,639,640,641,642,643,
645,646,647,648,649,650,651,653,654,655,656,657,658,659,660,662,
663,664,665,666,667,668,669,670,672,673,674,675,676,677,678,679,
680,681,682,684,685,686,687,688,689,690,691,692,693,694,695,696,
697,698,700,701,702,703,704,705,706,707,708,709,710,711,712,713,
714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,
730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,
746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,760,
761,762,763,764,765,766,767,768,769,770,771,772,773,774,774,775,
776,777,778,779,780,781,782,783,784,784,785,786,787,788,789,790,
791,792,792,793,794,795,796,797,798,799,799,800,801,802,803,804,
805,805,806,807,808,809,810,811,811,812,813,814,815,816,816,817,
818,819,820,821,821,822,823,824,825,826,826,827,828,829,830,830,
831,832,833,834,834,835,836,837,838,838,839,840,841,842,842,843,
844,845,845,846,847,848,849,849,850,851,852,852,853,854,855,855,
856,857,858,858,859,860,861,861,862,863,864,864,865,866,866,867,
868,869,869,870,871,872,872,873,874,874,875,876,876,877,878,879,
879,880,881,881,882,883,883,884,885,885,886,887,888,888,889,890,
890,891,892,892,893,894,894,895,895,896,897,897,898,899,899,900,
901,901,902,903,903,904,905,905,906,906,907,908,908,909,910,910,
911,911,912,913,913,914,914,915,916,916,917,917,918,919,919,920,
920,921,922,922,923,923,924,924,925,926,926,927,927,928,928,929,
930,930,931,931,932,932,933,933,934,935,935,936,936,937,937,938,
938,939,939,940,940,941,942,942,943,943,944,944,945,945,946,946,
947,947,948,948,949,949,950,950,951,951,952,952,953,953,954,954,
955,955,956,956,957,957,957,958,958,959,959,960,960,961,961,962,
962,963,963,963,964,964,965,965,966,966,967,967,967,968,968,969,
969,970,970,970,971,971,972,972,973,973,973,974,974,975,975,975,
976,976,977,977,977,978,978,979,979,979,980,980,980,981,981,982,
982,982,983,983,983,984,984,985,985,985,986,986,986,987,987,987,
988,988,988,989,989,989,990,990,990,991,991,991,992,992,992,993,
993,993,994,994,994,995,995,995,996,996,996,996,997,997,997,998,
998,998,999,999,999,999,1000,1000,1000,1001,1001,1001,1001,1002,1002,1002,
1002,1003,1003,1003,1004,1004,1004,1004,1005,1005,1005,1005,1006,1006,1006,1006,
1007,1007,1007,1007,1007,1008,1008,1008,1008,1009,1009,1009,1009,1009,1010,1010,
1010,1010,1011,1011,1011,1011,1011,1012,1012,1012,1012,1012,1013,1013,1013,1013,
1013,1013,1014,1014,1014,1014,1014,1015,1015,1015,1015,1015,1015,1016,1016,1016,
1016,1016,1016,1017,1017,1017,1017,1017,1017,1017,1018,1018,1018,1018,1018,1018,
1018,1019,1019,1019,1019,1019,1019,1019,1019,1019,1020,1020,1020,1020,1020,1020,
1020,1020,1020,1021,1021,1021,1021,1021,1021,1021,1021,1021,1021,1021,1022,1022,
1022,1022,1022,1022,1022,1022,1022,1022,1022,1022,1022,1022,1023,1023,1023,1023,
1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,
1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023,1023
};
static inline short soundconvert(short output, int sft)
{
	if(output >= 0) {
		output = logtable[output << sft];
	} else {
		output = -logtable[(-output) << sft];
	}
	return output << 5;
}
	
void restartsound(int ch) {
	chan = ch;

	SCHANNEL_CR(0)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x3F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(1)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x3F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(2)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x3F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(3)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x2F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(4)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x7F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(5)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x60)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(6)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x7F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(7)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x7F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;
	SCHANNEL_CR(8)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x7F)|SOUND_PAN(0x40)|SOUND_FORMAT_16BIT;

	SCHANNEL_CR(10)=SCHANNEL_ENABLE|SOUND_REPEAT |SOUND_VOL(0x7F)|SOUND_PAN(0x40)|SOUND_FORMAT_8BIT;

	TIMER0_CR = TIMER_ENABLE; 
	TIMER1_CR = TIMER_CASCADE | TIMER_IRQ_REQ | TIMER_ENABLE;
}

void stopsound() {
	SCHANNEL_CR(0)=0;
	SCHANNEL_CR(1)=0;
	SCHANNEL_CR(2)=0;
	SCHANNEL_CR(3)=0;
	SCHANNEL_CR(4)=0;
	SCHANNEL_CR(5)=0;
	SCHANNEL_CR(6)=0;
	SCHANNEL_CR(7)=0;
	SCHANNEL_CR(8)=0;
	SCHANNEL_CR(10)=0;
	TIMER0_CR = 0;
	TIMER1_CR = 0;
}

int pcmpos = 0;
int APU_paused=0;

Int32 NESAPUSoundSquareRender1();
Int32 NESAPUSoundSquareRender2();
Int32 NESAPUSoundTriangleRender1();
Int32 NESAPUSoundNoiseRender1();
Int32 NESAPUSoundDpcmRender1();
Int32 FDSSoundRender1();
Int32 FDSSoundRender2();
Int32 FDSSoundRender3();
Int32 VRC6SoundRender1();
Int32 VRC6SoundRender2();
Int32 VRC6SoundRender3();
void VRC6SoundInstall();

void mix(int chan) {
	int mapper = IPC_MAPPER;
	if(!APU_paused) {
		int i;
		s16 *dst = &buffer[chan*MIXBUFSIZE];
		for(i = 0; i < MIXBUFSIZE; i++) {
			static Int32 preval = 0;
			Int32 output = soundconvert(NESAPUSoundSquareRender1(), 6);
			*dst++ = ((preval + output) / 2);
			preval = output;
		}
		dst+=MIXBUFSIZE;
		for(i = 0; i < MIXBUFSIZE; i++) {
			static Int32 preval = 0;
			Int32 output = soundconvert(NESAPUSoundSquareRender2(), 6);
			*dst++ = ((preval + output) / 2);
			preval = output;
		}
		dst+=MIXBUFSIZE;
		for(i = 0; i < MIXBUFSIZE; i++) {
			static Int32 preval = 0;
			Int32 output = soundconvert(NESAPUSoundTriangleRender1(), 7);
			*dst++ = ((preval + output) / 2);
			preval = output;
		}
		dst+=MIXBUFSIZE;
		for(i = 0; i < MIXBUFSIZE; i++) {
			static Int32 preval = 0;
			Int32 output = soundconvert(NESAPUSoundNoiseRender1(), 6);
			output = ((preval + output) / 2);
			*dst++ = output;
			preval = output;
		}
		dst+=MIXBUFSIZE;
		for(i = 0; i < MIXBUFSIZE; i++) {
			static Int32 preval = 0;
			Int32 output = soundconvert(NESAPUSoundDpcmRender1(), 4);
			output = ((preval + output) / 2);
			*dst++ = output;
			preval = output;
		}
		dst+=MIXBUFSIZE;
		if(mapper == 20 || mapper == 256) {
			for(i = 0; i < MIXBUFSIZE; i++) {
				static Int32 preval = 0;
				Int32 output = soundconvert(FDSSoundRender3(), 0);
				output = ((preval + output) / 2);
				*dst++ = output;
				preval = output;
			}
		} else {
			dst+=MIXBUFSIZE;
		}
		dst+=MIXBUFSIZE;
		if(mapper == 24 || mapper == 26 || mapper == 256) {
			for(i = 0; i < MIXBUFSIZE; i++) {
				static Int32 preval = 0;
				Int32 output = VRC6SoundRender1() << 11;
				output = ((preval + output) / 2);
				*dst++ = output;
				preval = output;
			}
			dst+=MIXBUFSIZE;
			for(i = 0; i < MIXBUFSIZE; i++) {
				static Int32 preval = 0;
				Int32 output = VRC6SoundRender2() << 11;
				output = ((preval + output) / 2);
				*dst++ = output;
				preval = output;
			}
			dst+=MIXBUFSIZE;
			for(i = 0; i < MIXBUFSIZE; i++) {
				static Int32 preval = 0;
				Int32 output = VRC6SoundRender3() << 10;
				output = ((preval + output) / 2);
				*dst++ = output;
				preval = output;
			}
		}

		dealrawpcm((u8 *)&buffer[chan*(MIXBUFSIZE/2) + MIXBUFSIZE*18]);
	}
	readAPU();
	APU4015Reg();	//to refresh reg4015.
}

void initsound() { 		
	int i;
	powerOn(POWER_SOUND); 
	REG_SOUNDCNT = SOUND_ENABLE | SOUND_VOL(0x7F);
	for(i = 0; i < 16; i++) {
		SCHANNEL_CR(i) = 0;
	}
	SCHANNEL_SOURCE(0)=(u32)&buffer[0];
	SCHANNEL_SOURCE(1)=(u32)&buffer[2*MIXBUFSIZE];
	SCHANNEL_SOURCE(2)=(u32)&buffer[4*MIXBUFSIZE];
	SCHANNEL_SOURCE(3)=(u32)&buffer[6*MIXBUFSIZE];
	SCHANNEL_SOURCE(4)=(u32)&buffer[8*MIXBUFSIZE];
	SCHANNEL_SOURCE(5)=(u32)&buffer[10*MIXBUFSIZE];
	SCHANNEL_SOURCE(6)=(u32)&buffer[12*MIXBUFSIZE];
	SCHANNEL_SOURCE(7)=(u32)&buffer[14*MIXBUFSIZE];
	SCHANNEL_SOURCE(8)=(u32)&buffer[16*MIXBUFSIZE];
	SCHANNEL_SOURCE(10)=(u32)&buffer[18*MIXBUFSIZE];
	SCHANNEL_TIMER(0)=-0x2b9; 
	SCHANNEL_TIMER(1)=-0x2b9; 
	SCHANNEL_TIMER(2)=-0x2b9; 
	SCHANNEL_TIMER(3)=-0x2b9; 
	SCHANNEL_TIMER(4)=-0x2b9; 
	SCHANNEL_TIMER(5)=-0x2b9; 
	SCHANNEL_TIMER(6)=-0x2b9; 
	SCHANNEL_TIMER(7)=-0x2b9; 
	SCHANNEL_TIMER(8)=-0x2b9; 
	SCHANNEL_TIMER(10)=-0x2b9; 
	SCHANNEL_LENGTH(0)=MIXBUFSIZE;
	SCHANNEL_LENGTH(1)=MIXBUFSIZE;
	SCHANNEL_LENGTH(2)=MIXBUFSIZE;
	SCHANNEL_LENGTH(3)=MIXBUFSIZE;
	SCHANNEL_LENGTH(4)=MIXBUFSIZE;
	SCHANNEL_LENGTH(5)=MIXBUFSIZE;
	SCHANNEL_LENGTH(6)=MIXBUFSIZE;
	SCHANNEL_LENGTH(7)=MIXBUFSIZE;
	SCHANNEL_LENGTH(8)=MIXBUFSIZE;
	SCHANNEL_LENGTH(10)=MIXBUFSIZE / 2;
	SCHANNEL_REPEAT_POINT(0) = 0; 
	SCHANNEL_REPEAT_POINT(1) = 0; 
	SCHANNEL_REPEAT_POINT(2) = 0; 
	SCHANNEL_REPEAT_POINT(3) = 0; 
	SCHANNEL_REPEAT_POINT(4) = 0; 
	SCHANNEL_REPEAT_POINT(5) = 0; 
	SCHANNEL_REPEAT_POINT(6) = 0; 
	SCHANNEL_REPEAT_POINT(1) = 0; 
	SCHANNEL_REPEAT_POINT(8) = 0; 
	SCHANNEL_REPEAT_POINT(10) = 0; 
	TIMER0_DATA = -0x572;
	TIMER1_DATA = 0x10000 - MIXBUFSIZE;
	memset(buffer, 0, sizeof(buffer));

	memset(IPC_PCMDATA, 0, 512);
} 

void lidinterrupt(void)
{
	stopsound();
	restartsound(1);
}

void soundinterrupt(void)
{
	chan^=1;
	mix(chan);
	if(REG_IF & IRQ_TIMER1) {
		lidinterrupt();
		chan = 1;
		REG_IF = IRQ_TIMER1;
	}

}

static unsigned char pcm_out = 0x3F;
int pcm_line = 120;
int pcmprevol = 0x3F;
void dealrawpcm(unsigned char *out) 
{
	unsigned char *in = IPC_PCMDATA;
	int i;
	int count = 0;
	int line = 0;
	unsigned char *outp = out;

	pcm_line = REG_VCOUNT;

	if(1) {
		for(i = 0; i < MIXBUFSIZE; i++) {
			if(in[pcm_line] & 0x80) {
				pcm_out = in[pcm_line] & 0x7F;
				in[pcm_line] = 0;
				count++;
			}
			*out++ = (pcm_out + pcmprevol - 0x80);
			pcmprevol = pcm_out;
			line += 100;
			if(line >= 152) {
				line -= 152;
				pcm_line++;
				if(pcm_line > 262) {
					pcm_line = 0;
				}
			}
		}
	}
	if(count < 10) {		//not a playable raw pcm.
		for(i = 0; i < MIXBUFSIZE; i++) {
			*outp++ = 0;
			pcmprevol = 0x3F;
			pcm_out = 0x3F;
		}
	}
}

void APUSoundWrite(Uint address, Uint value);	//from s_apu.c (skip using read handlers, just write it directly)

void fifointerrupt(u32 msg, void *none)					//This should be registered to a fifo channel.
{
	switch(msg&0xff) {
		case FIFO_APU_PAUSE:
			APU_paused=1;
			memset(buffer,0,sizeof(buffer));
			break;
		case FIFO_UNPAUSE:
			APU_paused=0;
			break;
		case FIFO_APU_RESET:
			memset(buffer,0,sizeof(buffer));
			APU_paused=0;
			resetAPU();
			break;
		case FIFO_SOUND_RESET:
			lidinterrupt();
			break;
	}
}

void resetAPU() {
	NESReset();
	IPC_APUW = 0;
	IPC_APUR = 0;
}

void readAPU()
{
	u32 msg;
	if(1) {
		while((msg = fifoGetValue32(FIFO_USER_07)) != 0)
			APUSoundWrite(msg >> 8, msg&0xFF);
		IPC_APUR = IPC_APUW;
	}
	else {
		unsigned int *src = IPC_APUWRITE;
		unsigned int end = IPC_APUW;
		unsigned int start = IPC_APUR;
		while(start < end) {
			unsigned int val = src[start&(1024 - 1)];
			APUSoundWrite(val >> 8, val & 0xFF);
			start++;
		}
		IPC_APUR = start;
	}
}

void interrupthandler() {
	u32 flags=REG_IF&REG_IE;
	if(flags&IRQ_TIMER1)
		soundinterrupt();
}

void nesmain() {
	NESAudioFrequencySet(MIXFREQ);
	NESTerminate();
	NESHandlerInitialize();
	NESAudioHandlerInitialize();
	APUSoundInstall();
	FDSSoundInstall();
	VRC6SoundInstall();
	
	resetAPU();
	NESVolume(0);
	
	swiWaitForVBlank();
	initsound();
	restartsound(1);

	fifoSetValue32Handler(FIFO_USER_08, fifointerrupt, 0);		//use the last IPC channel to comm..
	irqSet(IRQ_TIMER1, soundinterrupt);
	//irqSet(IRQ_LID, lidinterrupt);
}
