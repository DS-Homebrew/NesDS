;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper5init

.struct mapperData
counter:	.byte 0
enable:		.byte 0
prgSize:	.byte 0
chrSize:	.byte 0
chrBank:	.byte 0
mmc5IrqR:	.byte 0
mmc5Mul1:	.byte 0
mmc5Mul2:	.byte 0
m5mirror:	.word 0

prgPage0:	.byte 0
prgPage1:	.byte 0
prgPage2:	.byte 0
prgPage3:	.byte 0

chrPage0:	.word 0
chrPage1:	.word 0
chrPage2:	.word 0
chrPage3:	.word 0
chrPage4:	.word 0
chrPage5:	.word 0
chrPage6:	.word 0
chrPage7:	.word 0
chrPage8:	.word 0
chrPage9:	.word 0
chrPage10:	.word 0
chrPage11:	.word 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC5
mapper5init:
;@----------------------------------------------------------------------------
	.word void,void,void,void

	adr r1,write0
	str_ r1,rp2A03MemWrite

	adr r1,mmc5_r
	str_ r1,rp2A03MemRead

	mov r0,#3
	strb_ r0,prgSize
	strb_ r0,chrSize

	mov r0,#0x7f
	strb_ r0,prgPage0
	strb_ r0,prgPage1
	strb_ r0,prgPage2
	strb_ r0,prgPage3

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
;@----------------------------------------------------------------------------
write0:
;@-------------------------------监视 char *-----------------------------------
	cmp addy,#0x5000
	blo empty_W
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
	bxlt lr			;@ Get out.
	cmp r2,#0x17
	ble _17
	cmp r2,#0x20
	bxlt lr			;@ Get out.
	cmp r2,#0x27
	ble _20
	cmp r2,#0x2b
	ble _28
	cmp r2,#0x30
	beq _30
	bx lr			;@ Get out.

_00:
	and r0,r0,#0x03
	strb_ r0,prgSize
	b mmc5Prg
_01:
	and r0,r0,#0x03
	strb_ r0,chrSize
	b mmc5ChrB		;@ Both A and B?
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
	adrl_ r1,prgPage0
	strb r0,[r1,r2]
mmc5Prg:
	ldrb_ r1,prgSize
	cmp r1,#0x00
	bne not0
	ldrb_ r0,prgPage1
	mov r0,r0,lsr#2
	b map89ABCDEF_
not0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne not1
	ldrb_ r0,prgPage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb_ r0,prgPage3
	mov r0,r0,lsr#1
	ldr lr,[sp],#4
	b mapCDEF_
not1:
	cmp r1,#0x02
	bne not2
	ldrb_ r0,prgPage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb_ r0,prgPage2
	bl mapCD_
	ldrb_ r0,prgPage3
	ldr lr,[sp],#4
	b mapEF_
not2:
	ldrb_ r0,prgPage0
	bl map89_
	ldrb_ r0,prgPage1
	bl mapAB_
	ldrb_ r0,prgPage2
	bl mapCD_
	ldrb_ r0,prgPage3
	ldr lr,[sp],#4
	b mapEF_

_20:				;@ For sprites.
_21:
_22:
_23:
_24:
_25:
_26:
_27:
	ldrb_ r1,chrBank
	orr r0, r0, r1, lsl#8
	adrl_ r1,chrPage0
	sub r2,r2,#0x20
	str r0,[r1, r2, lsl#2]
mmc5ChrA:
@	bx lr			;@ Get out?
	ldrb_ r1,chrSize
	cmp r1,#0x00
	bne notCh0
	ldr_ r0,chrPage7
@	mov r0,r0,lsr#3
	b chr01234567_
notCh0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notCh1
	ldr_ r0,chrPage3
@	mov r0,r0,lsr#2
	bl chr0123_
	ldr lr,[sp],#4
	ldr_ r0,chrPage7
@	mov r0,r0,lsr#2
@	b chr4567_
	bx lr			;@ Get out?
notCh1:
	cmp r1,#0x02
	bne notCh2
	ldr_ r0,chrPage1
@	mov r0,r0,lsr#1
	bl chr01_
	ldr_ r0,chrPage3
@	mov r0,r0,lsr#1
	bl chr23_
	ldr_ r0,chrPage5
@	mov r0,r0,lsr#1
@	bl chr45_
	ldr lr,[sp],#4
	ldr_ r0,chrPage7
@	mov r0,r0,lsr#1
@	b chr67_
	bx lr			;@ Get out?
notCh2:
	ldr_ r0,chrPage0
	bl chr0_
	ldr_ r0,chrPage1
	bl chr1_
	ldr_ r0,chrPage2
	bl chr2_
	ldr_ r0,chrPage3
	bl chr3_
	ldr_ r0,chrPage4
@	bl chr4_
	ldr_ r0,chrPage5
@	bl chr5_
	ldr_ r0,chrPage6
@	bl chr6_
	ldr lr,[sp],#4
	ldr_ r0,chrPage7
@	b chr7_
	bx lr			;@ Get out?
_30:
	and r0, r0, #3
	strb_ r0, chrBank
	bx lr
_28:				;@ For background.
_29:
_2a:
_2b:
	ldrb_ r1,chrBank
	orr r0, r0, r1, lsl#8
	adrl_ r1,chrPage0
	sub r2,r2,#0x20
	add r1, r1, r2, lsl#2
	str r0,[r1]
mmc5ChrB:
@	bx lr			;@ Get out?
	ldrb_ r1,chrSize
	cmp r1,#0x00
	bne notChB0
	ldr_ r0,chrPage11
	mov r0,r0,lsr#3
	b chr01234567_
notChB0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notChB1
	ldr_ r0,chrPage11
@	mov r0,r0,lsr#2
@	bl chr0123_
	ldr lr,[sp],#4
	ldr_ r0,chrPage11
	mov r0,r0,lsr#2
	b chr4567_
	bx lr
notChB1:
	cmp r1,#0x02
	bne notChB2
	ldr_ r0,chrPage9
@	mov r0,r0,lsr#1
@	bl chr01_
	ldr_ r0,chrPage11
@	mov r0,r0,lsr#1
@	bl chr23_
	ldr_ r0,chrPage9
	mov r0,r0,lsr#1
	bl chr45_
	ldr lr,[sp],#4
	ldr_ r0,chrPage11
	mov r0,r0,lsr#1
	b chr67_
	bx lr
notChB2:
	ldr_ r0,chrPage8
@	bl chr0_
	ldr_ r0,chrPage9
@	bl chr1_
	ldr_ r0,chrPage10
@	bl chr2_
	ldr_ r0,chrPage11
@	bl chr3_
	ldr_ r0,chrPage8
	bl chr4_
	ldr_ r0,chrPage9
	bl chr5_
	ldr_ r0,chrPage10
	bl chr6_
	ldr lr,[sp],#4
	ldr_ r0,chrPage11
	b chr7_

map5Sound:
	bx lr
;@----------------------------------------------------------------------------
mmc5_200:
	and r2,addy,#0xff
	cmp r2,#0x03
	streqb_ r0,counter
	bxeq lr

	cmp r2,#0x04
	beq setEnIrq

	cmp r2,#0x05
	streqb_ r0,mmc5Mul1
	bxeq lr

	cmp r2,#0x06
	streqb_ r0,mmc5Mul2
	bx lr

setEnIrq:
	and r0,r0,#0x80
	strb_ r0,enable
	ldrb_ r1,mmc5IrqR
	and r0,r0,r1
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
mmc5_c00w:
	@dup write, no need
	@ldr r1, =NES_XRAM - 0x4000
	@strb r0, [r1, addy]

	/* update BG */
	ldr r1, =NES_XRAM + 0x1C00
	ldr r2, =NDS_BG+0x2000
	b writeBG
;@----------------------------------------------------------------------------
;@ never reach here, the NES_XRAM is read from m6502MemTbl
mmc5_c00r:
	ldr r1, =NES_XRAM - 0x4000
	ldrb r0, [r1, addy]
	bx lr

;@----------------------------------------------------------------------------
mmc5_r:		@5204,5205,5206
	cmp addy,#0x5200
	blo empty_R
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
	bx lr

MMC5IRQR:
	stmfd sp!,{lr}
	mov r0,#0
	bl rp2A03SetIRQPin
	ldmfd sp!,{lr}
	ldrb_ r0,mmc5IrqR
	and r1,r0,#0x40
	strb_ r1,mmc5IrqR
	bx lr

MMC5MulA:
	ldrb_ r1,mmc5Mul1
	ldrb_ r2,mmc5Mul2
	mul r0,r1,r2
	and r0,r0,#0xff
	bx lr
MMC5MulB:
	ldrb_ r1,mmc5Mul1
	ldrb_ r2,mmc5Mul2
	mul r0,r1,r2
	mov r0,r0,lsr#8
	bx lr

;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r2,counter
	ldr_ r1,scanline
	ldrb_ r0,mmc5IrqR
	cmp r1,#0
	orreq r0,#0x40
	beq h1

	cmp r1,#240
	biceq r0,r0,#0xC0
	beq h1

	cmp r1,r2
	orreq r0,r0,#0x80
	strb_ r0,mmc5IrqR

	ldrb_ r2,enable
	ands r0,r0,r2
	bne rp2A03SetIRQPin
	bx lr
h1:
	strb_ r0,mmc5IrqR
	ldrb_ r1,enable
	ands r0,r0,r1
	beq rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
