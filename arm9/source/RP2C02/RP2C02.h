#ifndef NESPPU_HEADER
#define NESPPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

/** Revision of PPU chip */
typedef enum {
	/** NTSC first revision(s) */
	REV_RP2C02		= 0x00,
	/** NTSC RGB revision */
	REV_RP2C03		= 0x01,
	/** NTSC RGB revision */
	REV_RP2C04		= 0x02,
	/** NTSC RGB revision */
	REV_RP2C05		= 0x03,
	/** PAL revision */
	REV_RP2C07		= 0x10,
	/** UMC UA6528P, Argentina Famiclone */
	REV_UA6528P		= 0x23,
	/** UMC UA6538, aka Dendy */
	REV_UA6538		= 0x24,
	/** UMC UA6548, Brazil Famiclone */
	REV_UA6548		= 0x25,
} RP2C03REV;

typedef struct {
	u32 scanline;
	u32 nextLineChange;
	u32 lineState;
	u32 frame;
	u32 cyclesPerScanline;
	u32 lastScanline;

// PPU State
	u32 vramAddr;
	u32 vramAddr2;
	u32 scrollX;
	u32 scrollY;
	u32 scrollYTemp;
	u32 sprite0Y;
	u32 bg0Cnt;
	u8 ppuBusLatch;
	u8 sprite0X;
	u8 vramAddrInc;
	u8 toggle;

	u8 ppuCtrl0;
	u8 ppuCtrl1;
	u8 ppuStat;
	u8 ppuOamAdr;

	u8 ppuCtrl0Frame;
	u8 readTemp;
	u8 rp2C02Revision;
	u8 unusedAlign[1];

	u32 loopy_t;
	u32 loopy_x;
	u32 loopy_y;
	u32 loopy_v;

	u32 vmemMask;
	u32 vmemBase;
	u32 palSyncLine;

	u32 pixStart;
	u32 pixEnd;
	u32 unused;

	u16 nesChrMap[8];
	u32 ppuOAMMem[64];
	u8 paletteMem[32];

	void (*ppuIrqFunc)(bool);
	void (*newFrameHook)(void);
	void (*endFrameHook)(void);
	void (*scanlineHook)(void);
	void (*ppuChrLatch)(int tileNr);
	u8 unusedAlign2[8];
} RP2C02;

void PPU_init(void);
void EMU_VBlank(void);
void paletteinit(void);
void PaletteTxAll(void);
void rescale_nr(u32 scale, u32 start);

#ifdef __cplusplus
}
#endif

#endif // NESPPU_HEADER
