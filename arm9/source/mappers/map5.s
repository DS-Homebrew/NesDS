@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper5init
	.global NES_XRAM
	counter = mapperdata+0
	enable = mapperdata+1
	prgsize = mapperdata+2
	chrsize = mapperdata+3
	chrbank = mapperdata+4
	mmc5irqr = mapperdata+5
	mmc5mul1 = mapperdata+6
	mmc5mul2 = mapperdata+7
	m5mirror = mapperdata+8
	prgpage0 = mapperdata+12
	prgpage1 = mapperdata+13
	prgpage2 = mapperdata+14
	prgpage3 = mapperdata+15
	chrpage0 = mapperdata+28
	chrpage1 = mapperdata+32
	chrpage2 = mapperdata+36
	chrpage3 = mapperdata+40
	chrpage4 = mapperdata+44
	chrpage5 = mapperdata+48
	chrpage6 = mapperdata+52
	chrpage7 = mapperdata+56
	chrpage8 = mapperdata+60
	chrpage9 = mapperdata+64
	chrpage10 = mapperdata+68
	chrpage11 = mapperdata+72
@---------------------------------------------------------------------------------
mapper5init:
@---------------------------------------------------------------------------------
	.word void,void,void,void

	adr r1,write0
	str_ r1,writemem_tbl+8

	adr r1,mmc5_r
	str_ r1,readmem_tbl+8

	mov r0,#3
	strb_ r0,prgsize
	strb_ r0,chrsize

	mov r0,#0x7f
	strb_ r0,prgpage0
	strb_ r0,prgpage1
	strb_ r0,prgpage2
	strb_ r0,prgpage3

	adr r0,hook
	str_ r0,scanlinehook

	mov pc,lr
@---------------------------------------------------------------------------------
write0:
@----------------------------------监视 char *-----------------------------------------------
	cmp addy,#0x5000
	blo IO_W
	cmp addy,#0x5100
	blo map5Sound
	cmp addy,#0x5c00
	bge mmc5_c00w
	cmp addy,#0x5200
	bge mmc5_200

	ands r2,addy,#0xff
	beq _00
	cmp r2,#0x01
	beq _01
	cmp r2,#0x05
	beq _05
	cmp r2,#0x14
	movlt pc,lr		@ get out.
	cmp r2,#0x17
	ble _17
	cmp r2,#0x20
	movlt pc,lr		@ get out.
	cmp r2,#0x27
	ble _20
	cmp r2,#0x2b
	ble _28
	cmp r2,#0x30
	beq _30
	mov pc,lr		@ get out.

_00:
	and r0,r0,#0x03
	strb_ r0,prgsize
	b mmc5prg
_01:
	and r0,r0,#0x03
	strb_ r0,chrsize
	b mmc5chrb		@ both A and B?
_05:
	strb_ r0,m5mirror
	cmp r0,#0x55
	beq mirror5_1
	cmp r0,#0
	beq mirror5_1
	cmp r0, #0xaa
	beq mirror_xram_0000
	cmp r0,#0xE4
	beq mirror4_
	eor r1,r0,r0,lsr#4
	ands r1,r1,#0x0C
	b mirror2V_
@	b mirrorKonami_


mirror5_1:
	cmp r0,#0
	b mirror1_

_14:
_15:
_16:
_17:
	sub r2,r2,#0x14
	adrl_ r1,prgpage0
	strb r0,[r1,r2]
mmc5prg:
	ldrb_ r1,prgsize
	cmp r1,#0x00
	bne not0
	ldrb_ r0,prgpage1
	mov r0,r0,lsr#2
	b map89ABCDEF_
not0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne not1
	ldrb_ r0,prgpage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb_ r0,prgpage3
	mov r0,r0,lsr#1
	ldr lr,[sp],#4
	b mapCDEF_
not1:
	cmp r1,#0x02
	bne not2
	ldrb_ r0,prgpage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb_ r0,prgpage2
	bl mapCD_
	ldrb_ r0,prgpage3
	ldr lr,[sp],#4
	b mapEF_
not2:
	ldrb_ r0,prgpage0
	bl map89_
	ldrb_ r0,prgpage1
	bl mapAB_
	ldrb_ r0,prgpage2
	bl mapCD_
	ldrb_ r0,prgpage3
	ldr lr,[sp],#4
	b mapEF_

_20:				@ For sprites.
_21:
_22:
_23:
_24:
_25:
_26:
_27:
	ldrb_ r1,chrbank
	orr r0, r0, r1, lsl#8
	adrl_ r1,chrpage0
	sub r2,r2,#0x20
	add r1, r1, r2, lsl#2
	str r0,[r1]
mmc5chra:
@	mov pc,lr		; get out?
	ldrb_ r1,chrsize
	cmp r1,#0x00
	bne notch0
	ldr_ r0,chrpage7
@	mov r0,r0,lsr#3
	b chr01234567_
notch0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notch1
	ldr_ r0,chrpage3
@	mov r0,r0,lsr#2
	bl chr0123_
	ldr lr,[sp],#4
	ldr_ r0,chrpage7
@	mov r0,r0,lsr#2
@	b chr4567_
	mov pc,lr		@ get out?
notch1:
	cmp r1,#0x02
	bne notch2
	ldr_ r0,chrpage1
@	mov r0,r0,lsr#1
	bl chr01_
	ldr_ r0,chrpage3
@	mov r0,r0,lsr#1
	bl chr23_
	ldr_ r0,chrpage5
@	mov r0,r0,lsr#1
@	bl chr45_
	ldr lr,[sp],#4
	ldr_ r0,chrpage7
@	mov r0,r0,lsr#1
@	b chr67_
	mov pc,lr		@ get out?
notch2:
	ldr_ r0,chrpage0
	bl chr0_
	ldr_ r0,chrpage1
	bl chr1_
	ldr_ r0,chrpage2
	bl chr2_
	ldr_ r0,chrpage3
	bl chr3_
	ldr_ r0,chrpage4
@	bl chr4_
	ldr_ r0,chrpage5
@	bl chr5_
	ldr_ r0,chrpage6
@	bl chr6_
	ldr lr,[sp],#4
	ldr_ r0,chrpage7
@	b chr7_
	mov pc,lr		@ get out?
_30:
	and r0, r0, #3
	strb_ r0, chrbank
	mov pc, lr
_28:				@ For background.
_29:
_2a:
_2b:
	ldrb_ r1,chrbank
	orr r0, r0, r1, lsl#8
	adrl_ r1,chrpage0
	sub r2,r2,#0x20
	add r1, r1, r2, lsl#2
	str r0,[r1]
mmc5chrb:
@	mov pc,lr		; get out?
	ldrb_ r1,chrsize
	cmp r1,#0x00
	bne notchb0
	ldr_ r0,chrpage11
	mov r0,r0,lsr#3
	b chr01234567_
notchb0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notchb1
	ldr_ r0,chrpage11
@	mov r0,r0,lsr#2
@	bl chr0123_
	ldr lr,[sp],#4
	ldr_ r0,chrpage11
	mov r0,r0,lsr#2
	b chr4567_
	mov pc,lr
notchb1:
	cmp r1,#0x02
	bne notchb2
	ldr_ r0,chrpage9
@	mov r0,r0,lsr#1
@	bl chr01_
	ldr_ r0,chrpage11
@	mov r0,r0,lsr#1
@	bl chr23_
	ldr_ r0,chrpage9
	mov r0,r0,lsr#1
	bl chr45_
	ldr lr,[sp],#4
	ldr_ r0,chrpage11
	mov r0,r0,lsr#1
	b chr67_
	mov pc,lr
notchb2:
	ldr_ r0,chrpage8
@	bl chr0_
	ldr_ r0,chrpage9
@	bl chr1_
	ldr_ r0,chrpage10
@	bl chr2_
	ldr_ r0,chrpage11
@	bl chr3_
	ldr_ r0,chrpage8
	bl chr4_
	ldr_ r0,chrpage9
	bl chr5_
	ldr_ r0,chrpage10
	bl chr6_
	ldr lr,[sp],#4
	ldr_ r0,chrpage11
	b chr7_

map5Sound:
	mov pc,lr
@---------------------------------------------------------------------------------
mmc5_200:
	and r2,addy,#0xff
	cmp r2,#0x03
	streqb_ r0,counter
	moveq pc,lr

	cmp r2,#0x04
	beq setEnIrq

	cmp r2,#0x05
	streqb_ r0,mmc5mul1
	moveq pc,lr

	cmp r2,#0x06
	streqb_ r0,mmc5mul2
	mov pc,lr

setEnIrq:
	and r0,r0,#0x80
	strb_ r0,enable
	mov pc,lr
@---------------------------------------------------------------------------------
mmc5_c00w:
	@dup write, no need
	@ldr r1, =NES_XRAM - 0x4000
	@strb r0, [r1, addy]

	/* update BG */
	ldr r1, =NES_XRAM + 0x1C00
	ldr r2, =NDS_BG+0x2000
	b writeBG
@---------------------------------------------------------------------------------
@ never reach here, the NES_XRAM is read from memmap_tbl
mmc5_c00r:
	ldr r1, =NES_XRAM - 0x4000
	ldrb r0, [r1, addy]
	mov pc, lr

@---------------------------------------------------------------------------------
mmc5_r:		@5204,5205,5206
	cmp addy,#0x5200
	blo IO_R
	cmp addy,#0x5C00
	bge mmc5_c00r
	and r2,addy,#0xff
	cmp r2,#0x04
	beq MMC5IRQR
	cmp r2,#0x05
	beq MMC5MulA
	cmp r2,#0x06
	beq MMC5MulB

	mov r0,#0xff
	mov pc,lr

MMC5IRQR:
	ldrb_ r0,mmc5irqr
	ldrb_ r1,enable
	cmp r1,#0
	andne r1,r0,#0x40
	strb_ r1,mmc5irqr
	mov pc,lr

MMC5MulA:
	ldrb_ r1,mmc5mul1
	ldrb_ r2,mmc5mul2
	mul r0,r1,r2
	and r0,r0,#0xff
	mov pc,lr
MMC5MulB:
	ldrb_ r1,mmc5mul1
	ldrb_ r2,mmc5mul2
	mul r0,r1,r2
	mov r0,r0,lsr#8
	mov pc,lr

@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,counter
	ldr_ r1,scanline
	ldrb_ r2,mmc5irqr
	cmp r1,#239
	blt h2
	orr r2,r2,#0x40
h2:
	cmp r1,#245
	bge h1

	cmp r1,r0
	ble h1

	orr r2,r2,#0x80
	strb_ r2,mmc5irqr

	ldrb_ r0,enable
	cmp r0,#0
@	bne irq6502
	bne CheckI
h1:
	strb_ r2,mmc5irqr
	fetch 0
@---------------------------------------------------------------------------------
