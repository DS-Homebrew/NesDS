@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper9init
	.global mapper10init
	.global mapper9BGcheck
@	.global mapper_9_hook

	reg = mapperData
	reg0 = mapperData + 0
	reg1 = mapperData + 1
	reg2 = mapperData + 2
	reg3 = mapperData + 3
	latch_a = mapperData + 4
	latch_b = mapperData + 5
	chrc = mapperData + 6

@----------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ MMC2
@ Used in:
@ Punch Out
mapper9init:	@really bad Punchout hack
@---------------------------------------------------------------------------------
	.word empty_W,writeAB,write,write
map10start:
	mov r0, #0
	str_ r0, reg
	mov r0, #4
	strb_ r0, reg1
	mov r0, #0xFE
	strb_ r0, latch_a
	strb_ r0, latch_b

	ldrb_ r0,cartFlags
	bic r0,r0,#SCREEN4	@(many punchout roms have bad headers)
	strb_ r0,cartFlags

@	ldr r0,=mapper_9_hook
@	str_ r0,scanlineHook

	adr r0,framehook
	str_ r0,newFrameHook

	adr r0, chrlatch2
	str_ r0, ppuChrLatch

	mov r0,#-1
	b map89ABCDEF_		@everything to last bank

@---------------------------------------------------------------------------------
@ MMC4
mapper10init:
@---------------------------------------------------------------------------------
	.word empty_W,write,write,write
	b map10start
@---------------------------------------------------------------------------------
writeAB:
	and r1, addy, #0xF000
	cmp r1, #0xA000
	beq map89_
	strb_ r0, reg0
	ldrb_ r2, latch_a
	cmp r2, #0xFD
	beq chr0123_
	bx lr

@---------------------------------------------------------------------------------
write:
	and r1, addy, #0xF000
	cmp r1, #0xA000
	beq map89AB_
	cmp r1, #0xB000
	bne c000
	strb_ r0, reg0
	ldrb_ r2, latch_a
	cmp r2, #0xFD
	beq chr0123_
	bx lr

b000: @-------------------------
	strb_ r0,reg0
	bx lr
c000: @-------------------------
	cmp r1, #0xC000
	bne d000

	strb_ r0,reg1
	b chr0123_
	ldrb_ r2, latch_a
	cmp r2, #0xFE
	beq chr0123_
	bx lr
d000: @-------------------------
	cmp r1, #0xD000
	bne e000
	strb_ r0, reg2
	ldrb_ r2, latch_b
	cmp r2, #0xFD
	beq chr4567_
	bx lr
e000: @-------------------------
	cmp r1, #0xE000
	bne f000
	tst addy,#0x1000
	bne f000
	strb_ r0, reg3
	ldrb_ r2, latch_b
	cmp r2, #0xFE
	beq chr4567_
	bx lr
f000: @-------------------------
	tst r0,#1
	b mirror2V_
@------------------------------
@mapper_9_hook:
@---------------------------------------------------------------------------------
@	ldr_ r0,scanline
@	sub r0,r0,#1
@	tst r0,#7
@	ble h9
@	cmp r0,#239
@	bhi h9
@
@	ldr r2,=latchtbl
@	ldrb r0,[r2,r0,lsr#3]
@
@	cmp r0,#0xfd
@	ldreqb_ r0,reg2
@	ldrneb_ r0,reg3
@	bl chr4567_
@h9:
@	fetch 0
@---------------------------------------------------------------------------------
framehook:
	stmfd sp!, {r3-r9}

	ldrb_ r6, ppuCtrl0
	tst r6, #0x10
	ldreqb_ r5, latch_a
	ldrneb_ r5, latch_b

	mov r3, #0x0
	mov r4, #32*30*2
	ldr r1, =NDS_BG
latlp:
	ldrh r0, [r1]
	and r2, r0, #0xFF
	bic r0, #0x100
	orr r0, r3, r0
	strh r0, [r1], #2

	cmp r2, #0xFE
	cmpeq r5, #0xFD
	eoreq r3, r3, #0x100
	moveq r5, #0xFE

	cmp r2, #0xFD
	cmpeq r5, #0xFE
	eoreq r3, r3, #0x100
	moveq r5, #0xFD

	tst r1, #0x3F
	subne r4, r4, #1
	bne latlp
	tst r1, #0x800
	subeq r1, r1, #0x40		@roll back one line.
	eor r1, r1, #0x800
	subs r4, r4, #1
	bne latlp

	tst r6, #0x10
	streqb_ r5, latch_a
	strneb_ r5, latch_b

@	ldreqb_ r2,reg2
@	ldrneb_ r2,reg3
@	beq chr4567_

	ldr r9, =currentBG
	ldr r8, [r9]			@get the current bg.
	adr r7, latchtbl		@to check if the chrbg is cached...
	ldrb r4, [r7, r8, lsr#3]

rechr:
	ldr_ r3, vromBase
	ldrb_ r6, ppuCtrl0
	tst r6, #0x10
	bne chrb
chra:
	ldrb_ r5, latch_a
	cmp r5, #0xFD
	ldrneb_ r6, reg0
	ldreqb_ r6, reg1
	cmp r4, r6
	beq lend
	strb r6, [r7, r8, lsr#3]
	add r5, r3, r6, lsl#12		@r5 = src
	b dochr

chrb:
	ldrb_ r5, latch_b
	cmp r5, #0xFD
	ldrneb_ r6, reg2
	ldreqb_ r6, reg3
	cmp r4, r6
	beq lend
	strb r6, [r7, r8, lsr#3]
	add r5, r3, r6, lsl#12		@r5 = src

dochr:
	ldr r9, =NDS_VRAM
	add r6, r9, r8, lsl#11		@dst bg chr
	add r6, r6, #0x2000		@dst latch bg chr
	ldr r7, =CHR_DECODE

chrlp:
	ldrb r0,[r5],#1
	ldrb r1,[r5,#7]
	ldr r0,[r7,r0,lsl#2]
	ldr r1,[r7,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	str r0,[r6],#4
	tst r6, #0x1f
	bne chrlp
	add r5, r5, #8
	movs r0, r6, lsl#19
	bne chrlp

lend:
	ldmfd sp!, {r3-r9}
	bx lr


@---------------------------------------------------------------------------------
chrlatch:
	ldr_ r4, vromBase		@r4 returns the new ptr
	tst r1, #0x8			@r1 = ppuCtrl0, r0 = tile#
	bne spchrb
spchra:
	ldrb_ r2, latch_a
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
	strb_ r2, latch_a
	add r4, r4, lr, lsl#12
	add r4, r4, r0, lsl#4
	bx r12				@do NOT return to lr, but r12...

spchrb:
	ldrb_ r2, latch_b
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
	strb_ r2, latch_b
	add r4, r4, lr, lsl#12
	add r4, r4, r0, lsl#4
	bx r12				@do NOT return to lr, but r12...


@------------------------
chrlatch2:
	ldr r1, =0x1FF0
	and r0, r0, r1
	ldrb_ r1, latch_a
	ldrb_ r2, latch_b

	cmp r0, #0x0FD0
	bne 1f
	cmp r1, #0xFD
	beq 1f

	mov r0, #0xFD
	strb_ r0, latch_a
	ldrb_ r0, reg0
	b chr0123_

1:
	cmp r0, #0x0FE0
	bne 2f
	cmp r1, #0xFE
	beq 2f

	mov r0, #0xFE
	strb_ r0, latch_a
	ldrb_ r0, reg1
	b chr0123_

2:
	ldr r1, =0x1FD0
	cmp r0, r1
	bne 3f
	cmp r2, #0xFD
	beq 3f

	mov r0, #0xFD
	strb_ r0, latch_b
	ldrb_ r0, reg2
	b chr4567_

3:
	ldr r1, =0x1FE0
	cmp r0, r1
	bxne lr
	cmp r2, #0xFE
	bxeq lr

	mov r0, #0xFE
	strb_ r0, latch_b
	ldrb_ r0, reg3
	b chr4567_

@---------------------------------------------------------------------------------
mapper9BGcheck: @called from PPU.s, r0=FD-FF
@---------------------------------------------------------------------------------
	cmp r0,#0xff
	bxeq lr

	ldr r1,=latchtbl
	and r2,addy,#0x3f
	cmp r2,#0x10
	strlob r0,[r1,addy,lsr#6]

	bx lr

latchtbl:
.skip 32
