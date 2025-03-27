;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper90init

	.struct mapperData
irqLatch:	.byte 0
irqEnable:	.byte 0
irqCounter:	.byte 0
irqPreset:	.byte 0
irqOffset:	.byte 0		;@ Shoud be fixed???
			.skip 3
prg6000:	.byte 0
prgE000:	.byte 0
prgSize:	.byte 0
chrSize:	.byte 0

mirMode:	.byte 0
mirType:	.byte 0
			.skip 2
keyVal:		.byte 0
mulVal1:	.byte 0
mulVal2:	.byte 0
			.skip 1
mulRes:		.word

prgReg0:	.byte 0
prgReg1:	.byte 0
prgReg2:	.byte 0
prgReg3:	.byte 0

chrReg0:	.word
chrReg1:	.word
chrReg2:	.word
chrReg3:	.word
chrReg4:	.word
chrReg5:	.word
chrReg6:	.word
chrReg7:	.word

ntReg0:		.word
ntReg1:		.word
ntReg2:		.word
ntReg3:		.word

patch:		.byte

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ 晶太 (Jīngtài, also known as J.Y. Company)'s proprietary ASIC
;@ Also see mapper 35, 209 & 211
mapper90init:
;@----------------------------------------------------------------------------
	.word write89,writeAB,writeCD,void

	stmfd sp!, {lr}

	ldr_ r0, prgSize8k
	sub r0, r0, #1
	strb_ r0, prgReg3
	sub r0, r0, #1
	strb_ r0, prgReg2
	sub r0, r0, #1
	strb_ r0, prgReg1
	sub r0, r0, #1
	strb_ r0, prgReg0

	mov r0, #-1
	bl map89ABCDEF_

	mov r0, #0
	bl chr01234567_

	mov r0, #0
	adrl_ r1, chrReg0
	adrl_ r2, ntReg0
0:
	str r0, [r1], #4
	cmp r0, #4
	strcc r0, [r2], #4
	add r0, r0, #1
	cmp r0, #8
	bne 0b

	ldrb r0, sw_val
	eor r0, r0, #0xFF
	strb r0, sw_val			;@ For multi-in-one switch.

	adr r1, readl
	str_ r1,rp2A03MemRead
	adr r1,writel
	str_ r1,rp2A03MemWrite

	ldr r0,=hbHook
	str_ r0,scanlineHook

	ldr_ r0, prgcrc
	ldr r1, =0x9A36
	cmp r0, r1
	streqb_ r0, patch

	ldmfd sp!, {pc}
;@--------------
sw_val:
	.word 0

;@----------------------------------------------------------------------------
writel:
;@----------------------------------------------------------------------------
	cmp addy,#0x5000
	blo empty_W
	ldr r1, =0x5803
	cmp addy, r1
	streqb_ r0, keyVal
	bxeq lr

	ldr r1, =0x5800
	cmp addy, r1
	bxcc lr
	add r1, r1, #2
	cmp addy, r1
	bxcs lr

	tst addy, #0x1
	streqb_ r0, mulVal1
	strneb_ r0, mulVal2

	ldrb_ r0, mulVal1
	ldrb_ r1, mulVal2
	mul r2,r1,r0

	str_ r2, mulRes
	bx lr
;@----------------------------------------------------------------------------
readl:
;@----------------------------------------------------------------------------
	cmp addy,#0x5000
	blo empty_R
	ldreqb r0, sw_val
	eoreq r0, r0, #0xFF
	bxeq lr
	ldr r1, =0x5800
	cmp addy, r1
	ldreqb_ r0, mulRes
	bxeq lr
	ldr r1, =0x5801
	cmp addy, r1
	ldreqb_ r0, mulRes + 1
	bxeq lr
	ldr r1, =0x5803
	cmp addy, r1
	ldreqb_ r0, keyVal
	bxeq lr

	mov r0, addy, lsr#8
	bx lr

;@----------------------------------------------------------------------------
write89:
;@----------------------------------------------------------------------------
	tst addy, #0x1000
	bne 0f

	and addy, addy, #7
	cmp addy, #4
	bxcs lr

	adrl_ r1, prgReg0
	strb r0, [r1, addy]
	b setBankCPU

0:
	and addy, addy, #7
	adrl_ r1, chrReg0
	strb r0, [r1, addy, lsl#2]
	b setBankPPU

;@----------------------------------------------------------------------------
writeAB:
;@----------------------------------------------------------------------------
	tst addy, #0x1000
	bne 0f

	and addy, addy, #7
	adrl_ r1, chrReg0 + 1
	strb r0, [r1, addy, lsl#2]
	b setBankPPU

0:
	tst addy, #0x4
	and addy, addy, #3
	adrl_ r1, ntReg0
	addne r1, r1, #1
	strb r0, [r1, addy, lsl#2]
	b setBankVRAM
;@----------------------------------------------------------------------------
writeCD:
;@----------------------------------------------------------------------------
	tst addy, #0x1000
	bne wd000

	and r2, addy, #7
	ldr pc, [pc, r2, lsl#2]
	nop
;@-----------------
ctable:
	.word wc000, void, wc002, wc003, void, wc005, wc006, void
;@-----------------
wc000:
	ands r0,r0,#1
	strb_ r0, irqEnable
	beq rp2A03SetIRQPin
	bx lr
wc002:
	mov r0, #0
	strb_ r0, irqEnable			;@ This instruction does not work well...
	b rp2A03SetIRQPin
wc003:
	mov r0, #0xFF
	strb_ r0, irqEnable
	strb_ r0, irqPreset
	bx lr
wc005:
	ldrb_ r1, irqOffset
	tst r1, #0x80
	orrne r1, r1, r1
	eorne r0, r0, r1
	strneb_ r0, irqLatch
	andeq r1, r1, #0x27
	orreq r0, r0, r1
	streqb_ r0, irqLatch
	mov r0, #0xFF
	strb_ r0, irqPreset
	bx lr
wc006:
	ldrb_ r1, patch
	ands r1, r1, r1
	bxeq lr
	strb_ r0, irqOffset
	bx lr
;@-----------------
wd000:
	and addy, addy, #0x7
	cmp addy, #1
	bxhi lr
	andeq r0, r0, #3
	streqb_ r0, mirType
	beq setBankVRAM

	stmfd sp!, {lr}
	and r1, r0, #0x80
	strb_ r1, prg6000
	and r1, r0, #0x4
	strb_ r1, prgE000
	and r1, r0, #0x3
	strb_ r1, prgSize

	and r1, r0, #0x18
	mov r1, r1, lsr#3
	strb_ r1, chrSize

	and r1, r0, #0x20
	strb_ r1, mirMode

	bl setBankCPU
	bl setBankPPU
	ldmfd sp!, {lr}
	b setBankVRAM

;@--------------------------------
setBankCPU:
	ldrb_ r0, prgSize
	ldr pc, [pc, r0, lsl#2]
	nop
cpuTable:
	.word prgSet0, prgSet1, prgSet2, prgSet3
;@---------------
prgSet0:
	mov r0, #-1
	b map89ABCDEF_
prgSet1:
	stmfd sp!, {lr}
	ldrb_ r0, prgReg1
	bl map89AB_
	mov r0, #-1
	ldmfd sp!, {lr}
	b mapCDEF_
prgSet2:
	stmfd sp!, {lr}
	ldrb_ r0, prgReg0
	bl map89_
	ldrb_ r0, prgReg1
	bl mapAB_
	ldrb_ r0, prgReg2
	bl mapCD_
	ldmfd sp!, {lr}
	ldrb_ r0, prgE000
	ands r0, r0, r0
	ldrb_ r0, prgReg3
	b mapEF_

	stmfd sp!, {lr}
	mov r0, #-1
	bl mapEF_
	ldmfd sp!, {lr}
	ldrb_ r0, prg6000
	ands r0, r0, r0
	ldrneb_ r0, prgReg3
	bne map67_
	bx lr
prgSet3:
	stmfd sp!, {lr}
	ldrb_ r0, prgReg3
	bl map89_
	ldrb_ r0, prgReg2
	bl mapAB_
	ldrb_ r0, prgReg1
	bl mapCD_
	ldrb_ r0, prgReg0
	bl mapEF_
	ldmfd sp!, {pc}

;@--------------------------------
setBankPPU:
	ldrb_ r0, chrSize
	ldr pc, [pc, r0, lsl#2]
	nop
ppuTable:
	.word chrSet0, chrSet1, chrSet2, chrSet3
;@---------------
chrSet0:
	ldr_ r0, chrReg0
	b chr01234567_			;@ Two bytes.... e....
chrSet1:
	stmfd sp!, {lr}
	ldr_ r0, chrReg0
	bl chr0123_
	ldr_ r0, chrReg4
	ldmfd sp!, {lr}
	b chr4567_
chrSet2:
	stmfd sp!, {lr}
	ldr_ r0, chrReg0
	bl chr01_
	ldr_ r0, chrReg2
	bl chr23_
	ldr_ r0, chrReg4
	bl chr45_
	ldr_ r0, chrReg6
	bl chr67_
	ldmfd sp!, {pc}
chrSet3:
	stmfd sp!, {lr}
	ldr_ r0, chrReg0
	bl chr0_
	ldr_ r0, chrReg1
	bl chr1_
	ldr_ r0, chrReg2
	bl chr2_
	ldr_ r0, chrReg3
	bl chr3_
	ldr_ r0, chrReg4
	bl chr4_
	ldr_ r0, chrReg5
	bl chr5_
	ldr_ r0, chrReg6
	bl chr6_
	ldr_ r0, chrReg7
	bl chr7_
	ldmfd sp!, {pc}


;@--------------------------------
setBankVRAM:
	ldrb_ r1, patch
	ands r1, r1, r1
	bne 1f

	ldrb_ r0, mirMode
	ands r0, r0, r0
	bne vromNT
1:
	ldrb_ r0, mirType
	cmp r0, #0
	beq mirror2V_
	cmp r0, #1
	beq mirror2H_
	b mirror1H_			;@ This is correct...

vromNT:
	ldr_ r0, ntReg0
	cmp r0, #0
	beq 0f
	ldr_ r0, ntReg1
	cmp r0, #1
	beq 0f
	ldr_ r0, ntReg2
	cmp r0, #2
	beq 0f
	ldr_ r0, ntReg3
	cmp r0, #3
0:
	moveq r0, #0
	streqb_ r0, mirMode
	bxeq lr

	stmfd sp!, {lr}
	ldr_ r0, ntReg0
	mov r1, #0
	bl vromNT1k
	ldr_ r0, ntReg1
	mov r1, #1
	bl vromNT1k
	ldr_ r0, ntReg2
	mov r1, #2
	bl vromNT1k
	ldr_ r0, ntReg3
	mov r1, #3
	bl vromNT1k

	mov r0, #0x1C00
	add r0, r0, #0xc000
	str_ r0, bg0Cnt

	ldmfd sp!, {pc}

;@--------------------------------
hbHook:
;@--------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1
	cmp r0, #240
	bxcs lr
	tst r1, #0x18
	bxeq lr

	ldrb_ r0, irqCounter
	ldrb_ r1, irqPreset
	ands r1, r1, r1
	movne r2, #0
	strneb_ r2, irqPreset
	ldrneb_ r0, irqLatch
	strneb_ r0, irqCounter

	subs r0, r0, #0x1
	strcsb_ r0, irqCounter

	bxhi lr

	ldrb_ r0, irqEnable
	ands r0, r0, r0
	bne rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
