#ifndef NESPPU_HEADER
#define NESPPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

/** Revision of PPU chip */
typedef enum {
	/** NTSC first revision(s) */
	REV_RP2C02		= 0x00,
	/** PAL revision */
	REV_RP2C07		= 0x01,
	/** NTSC RGB revision */
	REV_RP2C03		= 0x02,
	/** NTSC RGB revision */
	REV_RP2C04		= 0x02,
	/** NTSC RGB revision */
	REV_RP2C05		= 0x02,
	/** UMC UA6528P, Argentina Famiclone */
	REV_UA6528P		= 0x03,
	/** UMC UA6538, aka Dendy */
	REV_UA6538		= 0x04,
	/** UMC UA6548, Brazil Famiclone */
	REV_UA6548		= 0x05,
} RP2C03REV;

typedef struct {
	u32 scanline;
	u32 nextLineChange;
	u32 lineState;
	u32 scanlineHook;
	u32 frame;
	u32 cyclesPerScanline;
	u32 lastScanline;

	u32 fpsValue;
	u32 adjustBlend;

// PPU State
	u32 vramAddr;
	u32 vramAddr2;
	u32 scrollX;
	u32 scrollY;
	u32 scrollYTemp;
	u32 sprite0Y;
	u32 readTemp;
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
	u8 rp2C02Revision;
	u8 unusedAlign[2];

	u32 loopy_t;
	u32 loopy_x;
	u32 loopy_y;
	u32 loopy_v;
	u32 loopy_shift;

	u32 vromMask;
	u32 vromBase;
	u32 palSyncLine;

	u32 pixStart;
	u32 pixEnd;

	u32 newFrameHook;
	u32 endFrameHook;
	u32 hblankHook;
	u32 ppuChrLatch;
	u16 nesChrMap[8];
	u32 ppuOAMMem[64];
	u8 paletteMem[32];

	void (*ppuIrqFunc)(bool);
	u8 unusedAlign2[8];
} RP2C02;

void paletteinit(void);
void PaletteTxAll(void);

#ifdef __cplusplus
}
#endif

#endif // NESPPU_HEADER
