@---------------------------------------------------------------------------------
	#include "equates.h"
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
	.global NES_DRAM
	.global NES_DISK

	.global rom_files
	.global rom_start
	.global ipc_region
	.global nes_region
	.global ct_buffer

#ifdef ROM_EMBEDED
	.global romebd_s
#endif

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
empty_R:		@read bad address (error)
@---------------------------------------------------------------------------------
	DEBUGINFO READ,addy

	mov r0,addy,lsr#8
void: @- - - - - - - - -empty function
@	mov r0,#0	@VS excitebike liked this, read from $3DDE ($2006).
	bx lr
@---------------------------------------------------------------------------------
rom_W:			@write ROM address (error)
empty_W:		@write bad address (error)
@---------------------------------------------------------------------------------
	DEBUGINFO WRITE,addy
	bx lr
@---------------------------------------------------------------------------------
ram_R:	@ram read ($0000-$1FFF)
@---------------------------------------------------------------------------------
	bic addy,addy,#0x1f800		@only 0x07FF is RAM
	ldrb r0,[cpu_zpage,addy]
	bx lr
@---------------------------------------------------------------------------------
ram_W:	@ram write ($0000-$1FFF)
@---------------------------------------------------------------------------------
	bic addy,addy,#0x1f800		@only 0x07FF is RAM
	strb r0,[cpu_zpage,addy]
	bx lr
@---------------------------------------------------------------------------------
sram_W:	@sram write ($6000-$7FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+12
	strb r0,[r1,addy]
	ldr_ r1, emuFlags
	orr r1, r1, #NEEDSRAM
	str_ r1, emuFlags
	bx lr
@---------------------------------------------------------------------------------
mem_R60:	@mem read ($6000-$7FFF) (8K)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+12		@[m6502MemTbl+12] = romBase + (page# * 8K)
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_R80:	@rom read ($8000-$9FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+16
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RA0:	@rom read ($A000-$BFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+20
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RC0:	@rom read ($C000-$DFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+24
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
rom_RE0:	@rom read ($E000-$FFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+28
	ldrb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_W80:	@rom write ($8000-$9FFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+16
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WA0:	@rom write ($A000-$BFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+20
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WC0:	@rom write ($C000-$DFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+24
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
mem_WE0:	@rom write ($E000-$FFFF)
@---------------------------------------------------------------------------------
	ldr_ r1,m6502MemTbl+28
	strb r0,[r1,addy]
	bx lr
@---------------------------------------------------------------------------------
@mem_R	@mem read ($8000-$FFFF) (actually $6000-$FFFF now)
@---------------------------------------------------------------------------------
@	adr r2,m6502MemTbl
@	ldr r1,[r2,r1,lsr#11] @r1=addy & 0xe000
@	ldrb r0,[r1,addy]
@	bx lr
@---------------------------------------------------------------------------------
filler: @r0=data r1=dest r2=word count
@	exit with r0 unchanged
@---------------------------------------------------------------------------------
	subs r2,r2,#1
	str r0,[r1,r2,lsl#2]
	bne filler
	bx lr
@---------------------------------------------------------------------------------
hblankinterrupt:
	ldr r1, =__hblankhook
	ldr r1, [r1]
	bx r1
.ltorg
@---------------------------------------------------------------------------------


@----------------------------------
@all below is for memory pre-alloc.

.section .bss, "aw"
.align 4
ipc_region:
	.skip 8192

ct_buffer:
	.skip 512*20			@DISPCNTBUFF & BGCNTBUFF
.align 10				@0x400 aligned

nes_region:				@NES_RAM should be 0x400 bytes aligned.... 
	.skip 0x800 + 0x2000 + 0x3000 + 0x2000 + 0x400 + 0x100 + 0x100

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
rom_start:
	.skip 0x40000 + 16		@this is the bigest size for FDS game.
NES_DRAM:				@if the game is a FDS one, this is available. otherwise not.
	.skip 0x8000
NES_DISK:				@same to NES_DRAM
	.skip 0x40000
	.skip ROM_MAX_SIZE - 0x40000 - 16 - 0x8000 - 0x40000		@the rest room for rom file.

#endif
