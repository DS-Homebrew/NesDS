;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper9init
	.global mapper10init

	.struct mapperData
reg0:		.byte 0
reg1:		.byte 0
reg2:		.byte 0
reg3:		.byte 0
latchA:		.byte 0
latchB:		.byte 0
latchTbl:	.skip 32

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC2
;@ Used in:
;@ Punch Out
mapper9init:	;@ Really bad PunchOut hack
;@----------------------------------------------------------------------------
	.word rom_W,writeAB,writeCD,writeEF
map10start:
	mov r0, #0
	str_ r0, reg0
	mov r0, #4
	strb_ r0, reg1
	mov r0, #0xFE
	strb_ r0, latchA
	strb_ r0, latchB

	ldrb_ r0,cartFlags
	bic r0,r0,#SCREEN4	;@ (Many PunchOut roms have bad headers)
	strb_ r0,cartFlags

	adr r0,frameHook
	str_ r0,newFrameHook

	adr r0,chrLatch2
	str_ r0,ppuChrLatch

	mov r0,#-1
	b map89ABCDEF_		;@ Everything to last bank

;@----------------------------------------------------------------------------
;@ MMC4
mapper10init:
;@----------------------------------------------------------------------------
	.word rom_W,writeAB_10,writeCD,writeEF
	b map10start
;@----------------------------------------------------------------------------
writeAB:
	tst addy,#0x1000
	beq map89_
	strb_ r0,reg0
	b chr0123_

;@----------------------------------------------------------------------------
writeAB_10:
	tst addy,#0x1000
	beq map89AB_
	strb_ r0,reg0
	b chr0123_

writeCD:
c000: @-------------------------
	tst addy,#0x1000
	bne d000
	strb_ r0,reg1
	ldrb_ r2,latchA
	cmp r2,#0xFE
	beq chr0123_
	bx lr
d000: @-------------------------
	strb_ r0,reg2
	b chr4567_

writeEF:
e000: @-------------------------
	tst addy,#0x1000
	streqb_ r0,reg3
	bxeq lr
f000: @-------------------------
	tst r0,#1
	b mirror2V_
;@----------------------------------------------------------------------------
frameHook:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r9}

	ldrb_ r6,ppuCtrl0
	tst r6,#0x10
	ldreqb_ r5,latchA
	ldrneb_ r5,latchB

	mov r3,#0
	cmp r5,#0xFE
	moveq r3,#0x100
	mov r4,#32*30*2
	ldr r1,=NDS_BG
latLoop:
	ldrh r0,[r1]
	and r2,r0,#0xFF
	bic r0,r0,#0x100
	orr r0,r0,r3
	strh r0,[r1],#2

	cmp r2,#0xFD
	moveq r3,#0x0
	cmp r2,#0xFE
	moveq r3,#0x100

	tst r1, #0x3F
	subne r4, r4, #1
	bne latLoop
	tst r1, #0x800
	subeq r1, r1, #0x40		;@ Roll back one line.
	eor r1, r1, #0x800
	subs r4, r4, #1
	bne latLoop
	cmp r3,#0
	moveq r5,#0xFD
	movne r5,#0xFE

	tst r6, #0x10
	streqb_ r5,latchA
	strneb_ r5,latchB

	ldr r9, =currentBG
	ldrb r8, [r9]			;@ Get the current bg.
	adrl_ r7, latchTbl		;@ To check if the chrBG is cached...
	ldrb r4, [r7, r8, lsr#3]

reChr:
	ldr_ r3, vmemBase
	ldrb_ r6, ppuCtrl0
	tst r6, #0x10
	bne chrB
chrA:
	ldrb_ r6, reg1
	cmp r4, r6
	beq lend
	strb r6, [r7, r8, lsr#3]
	add r5, r3, r6, lsl#12		;@ r5 = src
	b doChr

chrB:
	ldrb_ r6, reg3
	cmp r4, r6
	beq lend
	strb r6, [r7, r8, lsr#3]
	add r5, r3, r6, lsl#12		;@ r5 = src

doChr:
	ldr r9,=NDS_VRAM
	add r6,r9,r8,lsl#11			;@ dst bg chr
	add r6,r6,#0x2000			;@ dst latch bg chr
	ldr r7,=CHR_DECODE

chrLoop:
	ldrb r0,[r5],#1
	ldrb r1,[r5,#7]
	ldr r0,[r7,r0,lsl#2]
	ldr r1,[r7,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	str r0,[r6],#4
	tst r6,#0x1f				;@ 1 Tile
	bne chrLoop
	add r5,r5,#8
	movs r0,r6,lsl#19			;@ 256 Tiles
	bne chrLoop

lend:
	ldmfd sp!,{r3-r9}
	bx lr

;@----------------------------------------------------------------------------
chrLatch:
;@----------------------------------------------------------------------------
	ldr_ r4, vmemBase		;@ r4 returns the new ptr
	tst r1, #0x8			;@ r1 = ppuCtrl0, r0 = tile#
	bne spChrB
spChrA:
	ldrb_ r2, latchA
	cmp r2, #0xFD
	ldreqb_ lr, reg0
	ldrneb_ lr, reg1
	cmp r0, #0xFD
	cmpeq r2, #0xFE
	moveq r2, #0xFD
	ldreqb_ lr, reg0
	cmp r0, #0xFE
	cmpeq r2, #0xFD
	moveq r2, #0xFE
	ldreqb_ lr, reg1
	strb_ r2, latchA
	add r4, r4, lr, lsl#12
	add r4, r4, r0, lsl#4
	bx r12					;@ Do NOT return to lr, but r12...

spChrB:
	ldrb_ r2, latchB
	cmp r2, #0xFD
	ldreqb_ lr, reg2
	ldrneb_ lr, reg3
	cmp r0, #0xFD
	cmpeq r2, #0xFE
	moveq r2, #0xFD
	ldreqb_ lr, reg2
	cmp r0, #0xFE
	cmpeq r2, #0xFD
	moveq r2, #0xFE
	ldreqb_ lr, reg3
	strb_ r2, latchB
	add r4, r4, lr, lsl#12
	add r4, r4, r0, lsl#4
	bx r12					;@ do NOT return to lr, but r12...

;@----------------------------------------------------------------------------
chrLatch2:			;@ r0 = tile#
;@----------------------------------------------------------------------------
	ldr r1, =0x1FF0
	and r0, r0, r1
	ldrb_ r1, latchA
	ldrb_ r2, latchB

	cmp r0, #0x0FD0
	bne 1f
	cmp r1, #0xFD
	bxeq lr

	mov r0, #0xFD
	strb_ r0, latchA
	ldrb_ r0, reg0
	b chr0123_

1:
	cmp r0, #0x0FE0
	bne 2f
	cmp r1, #0xFE
	bxeq lr

	mov r0, #0xFE
	strb_ r0, latchA
	ldrb_ r0, reg1
	b chr0123_

2:
	ldr r1, =0x1FD0
	cmp r0, r1
	bne 3f
	cmp r2, #0xFD
	bxeq lr

	mov r0, #0xFD
	strb_ r0, latchB
	ldrb_ r0, reg2
	b chr4567_

3:
	ldr r1, =0x1FE0
	cmp r0, r1
	bxne lr
	cmp r2, #0xFE
	bxeq lr

	mov r0, #0xFE
	strb_ r0, latchB
	ldrb_ r0, reg3
	b chr4567_

