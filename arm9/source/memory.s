@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "M6502.i"
@---------------------------------------------------------------------------------
	.global hblankinterrupt
	.global void
	.global empty_R
	.global empty_W
	.global rom_W
	.global ram_R
	.global ram_W
	.global sram_W
	.global mem_R60
	.global rom_R80
	.global rom_RA0
	.global rom_RC0
	.global rom_RE0
	.global mem_W80
	.global mem_WA0
	.global mem_WC0
	.global mem_WE0
	.global filler

	.global DISPCNTBUFF
	.global BGCNTBUFF
	.global BGCNTBUFFB
	.global NES_RAM
	.global NES_NTRAM
	.global CART_SRAM
	.global CART_VRAM
	.global NES_XRAM
	.global CHR_DECODE
	.global MAPPED_RGB
	.global NES_DRAM
	.global NES_DISK

	.global rom_files
	.global rom_start
	.global ipc_region

#ifdef ROM_EMBEDED
	.global romebd_s
#endif

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
empty_R:		@ read bad address (error)
@---------------------------------------------------------------------------------
	DEBUGINFO READ,addy
	// Simulate cpu open bus
	ldrb r0,[m6502pc,#-1]
void: @- - - - - - - - -empty function
	bx lr
@---------------------------------------------------------------------------------
rom_W:			@write ROM address (error)
empty_W:		@write bad address (error)
@---------------------------------------------------------------------------------
	DEBUGINFO WRITE,addy
	bx lr
@---------------------------------------------------------------------------------
ram_R:	@ ram read ($0000-$1FFF)
@---------------------------------------------------------------------------------
	bic addy,addy,#0x1f800		@only 0x07FF is RAM
	ldrb r0,[m6502zpage,addy]
	bx lr
@---------------------------------------------------------------------------------
ram_W:	@ ram write ($0000-$1FFF)
@---------------------------------------------------------------------------------
	bic addy,addy,#0x1f800		@only 0x07FF is RAM
	strb r0,[m6502zpage,addy]
	bx lr
@---------------------------------------------------------------------------------
sram_W:	@ sram write ($6000-$7FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+12
	strb r0,[r1,addy]
	ldr_ r1, emuFlags
	orr r1, r1, #NEEDSRAM
	str_ r1, emuFlags
	bx lr
@---------------------------------------------------------------------------------
mem_R60:	@ mem read ($6000-$7FFF) (8K)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+12		@[m6502MemTbl+12] = romBase + (page# * 8K)
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_R80:	@ rom read ($8000-$9FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+16
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RA0:	@ rom read ($A000-$BFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+20
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RC0:	@ rom read ($C000-$DFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+24
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RE0:	@ rom read ($E000-$FFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+28
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_W80:	@ cart write ($8000-$9FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+16
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WA0:	@ cart write ($A000-$BFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+20
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WC0:	@ cart write ($C000-$DFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+24
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WE0:	@ cart write ($E000-$FFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+28
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
@mem_R	@ mem read ($6000-$FFFF)
@---------------------------------------------------------------------------------
@	adr r2,m6502MemTbl
@	ldr r1,[r2,r1,lsr#11] @r1=addy & 0xe000
@	ldrb r0,[r1,addy]
@	bx lr
@---------------------------------------------------------------------------------
filler: @ r0=data r1=dest r2=word count
@	exit with r0 unchanged
@---------------------------------------------------------------------------------
	subs r2,r2,#1
	str r0,[r1,r2,lsl#2]
	bne filler
	bx lr
@---------------------------------------------------------------------------------
hblankinterrupt:
//	ldr r1, =__hblankhook
	ldr r1, [r1]
	bx r1
.ltorg
@---------------------------------------------------------------------------------


@----------------------------------
@ all below is for memory pre-alloc.
.pool

.section .bss, "aw"
.align 4
ipc_region:
	.skip 8192

DISPCNTBUFF:
	.skip 512 * 4
BGCNTBUFF:
	.skip 256 * 16
BGCNTBUFFB:
	.skip 512 * 8

.align 10				@0x400 aligned
;@ Internal NES RAM
NES_RAM:				@NES_RAM should be 0x400 bytes aligned....
	.skip 0x800
NES_NTRAM:
	.skip 0x800

;@ Different kinds of Cartridge RAM
CART_SRAM:
	.skip 0x2000
CART_VRAM:
	.skip 0x8000
NES_XRAM:
	.skip 0x2000

CHR_DECODE:
	.skip 0x400
MAPPED_RGB:
	.skip 0x100

#ifdef ROM_EMBEDED

.section .text, "aw"
.align 4
rom_files:				@not used when testing
rom_start:				@not used when testing
romebd_s:
	.incbin "fm.nes"

.section .bss, "aw"
.align 4
NES_DRAM:
	.skip 0x8000
NES_DISK:
	.skip 0x40000

@-----------
#else

.section .bss, "aw"
.align 4

rom_files:
	.skip MAXFILES * 64 + MAXFILES * 4	@this will take a lot of memory. filename should not be longer than 64 in average.

	.align 8
	.skip 0xF0
rom_start:
	.skip 0x40000 + 16		@this is the bigest size for FDS game.
NES_DRAM:				@if the game is a FDS one, this is available. otherwise not.
	.skip 0x8000
NES_DISK:				@same to NES_DRAM
	.skip 0x40000
	.skip ROM_MAX_SIZE - 0x40000 - 16 - 0x8000 - 0x40000		@the rest room for rom file.

#endif
