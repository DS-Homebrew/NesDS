@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper225init
	.global mapper226init
	.global mapper227init
	.global mapper229init
	.global mapper230init
	.global mapper231init
	tmp = mapperdata
	tmp1 = mapperdata + 4
	reg0 = mapperdata + 8
	reg1 = mapperdata + 12
	tmp2 = mapperdata + 16
@---------------------------------------------------------------------------------
mapper225init:
@---------------------------------------------------------------------------------
	.word w225, w225, w225, w225
	
	mov r0, #0
	b map89ABCDEF_
	
@---------------------------------------------------------------------------------
mapper226init:
@---------------------------------------------------------------------------------
	.word w226, w226, w226, w226
	
	mov r0, #0
	b map89ABCDEF_

@---------------------------------------------------------------------------------
mapper227init:
@---------------------------------------------------------------------------------
	.word w227, w227, w227, w227
	
	stmfd sp!, {lr}
	mov r0, #0
	bl map89AB_
	mov r0, #0
	bl mapCDEF_
	ldmfd sp!, {pc}

@---------------------------------------------------------------------------------
mapper229init:
@---------------------------------------------------------------------------------
	.word w229, w229, w229, w229
	
	mov r0, #0
	b map89ABCDEF_

@---------------------------------------------------------------------------------
mapper230init:
@---------------------------------------------------------------------------------
	.word w230, w230, w230, w230
	stmfd sp!, {lr}

	ldr r0, rom_sw
	eor r0, #1
	str r0, rom_sw

	tst r0, #0xFF
	beq 0f

	mov r0, #0
	bl map89AB_
	mov r0, #7
	bl mapCDEF_
	ldmfd sp!, {pc}
0:
	mov r0, #8
	bl map89AB_
	mov r0, #-1
	bl mapCDEF_
	ldmfd sp!, {pc}
	
rom_sw:
	.word 0x1
@---------------------------------------------------------------------------------
mapper231init:
@---------------------------------------------------------------------------------
	.word w231, w231, w231, w231
	
	stmfd sp!, {lr}
	ldr_ r1, vrommask
	tst r1, #0x80000000
	moveq r0, #0
	bleq chr01234567_

	ldmfd sp!, {lr}
	mov r0, #0
	b map89ABCDEF_

@-----------------
w225:
@-----------------
	stmfd sp!, {lr}
	str_ addy, tmp
	and r0, addy, #0x3F
	bl chr01234567_
	ldr_ r0, tmp
	tst r0, #0x2000
	bl mirror2V_
	ldr_ addy, tmp
	mov r1, addy, lsr#7
	str_ r1, tmp1
	tst addy, #0x1000
	beq w225_4k
	tst addy, #0x40
	beq w225_l
	ldr_ r0, tmp1
	mov r0, r0, lsl#1
	add r0, r0, #1
	str_ r0, tmp
	bl map89AB_
	ldr_ r0, tmp
	bl mapCDEF_
	ldmfd sp!, {pc}
w225_l:
	ldr_ r0, tmp1
	mov r0, r0, lsl#1
	str_ r0, tmp
	bl map89AB_
	ldr_ r0, tmp
	bl mapCDEF_
	ldmfd sp!, {pc}
w225_4k:
	ldr_ r0, tmp1
	bl map89ABCDEF_
	ldmfd sp!, {pc}

@-----------------
w226:
@-----------------
	tst addy, #1
	strneb_ r0, reg1
	streqb_ r0, reg0

	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x40
	bl mirror2H_

	ldrb_ r0, reg0
	tst r0, #0x80
	mov r0, r0, lsr#1
	and r0, r0, #0xF
	orrne r0, r0, #0x10
	ldrb_ r1, reg1
	tst r1, #1
	orrne r0, r0, #0x20
	str_ r0, tmp

	ldrb_ r0, reg0
	tst r0, #0x20
	beq w226_4k
	tst r0, #0x1
	beq w226_l
	ldr_ r0, tmp
	mov r0, r0, lsl#1
	add r0, r0, #1
	str_ r0, tmp
	bl map89AB_
	ldr_ r0, tmp
	bl mapCDEF_
	ldmfd sp!, {pc}
w226_l:
	ldr_ r0, tmp
	mov r0, r0, lsl#1
	str_ r0, tmp
	bl map89AB_
	ldr_ r0, tmp
	bl mapCDEF_
	ldmfd sp!, {pc}
w226_4k:
	ldr_ r0, tmp
	bl map89ABCDEF_
	ldmfd sp!, {pc}

@-----------------
w227:
@-----------------
	tst addy, #0x100
	mov r0, addy, lsr#3
	and r0, r0, #0x0F
	orrne r0, r0, #0x10
	str_ r0, tmp1
	str_ addy, tmp

	stmfd sp!, {lr}
	tst addy, #2
	bl mirror2V_

	ldr_ r1, tmp
	tst r1, #0x1
	beq w227_hl4
	ldr_ r0, tmp1
	bl map89ABCDEF_
	b w227_8
w227_hl4:
	ldr_ r0, tmp
	tst r0, #0x4
	beq w227_l
	ldr_ r0, tmp1
	mov r0, r0, lsl#1
	add r0, r0, #1
	str_ r0, tmp2
	bl map89AB_
	ldr_ r0, tmp2
	bl mapCDEF_
	b w227_8
w227_l:
	ldr_ r0, tmp1
	mov r0, r0, lsl#1
	str_ r0, tmp2
	bl map89AB_
	ldr_ r0, tmp2
	bl mapCDEF_
w227_8:
	ldmfd sp!, {lr}
	ldr_ r1, tmp
	tst r1, #0x80
	movne pc, lr
	ldr_ r0, tmp1
	and r0, r0, #0x1C
	mov r0, r0, lsl#1
	tst r1, #0x200
	addne r0, r0, #7
	b mapCDEF_

@-----------------
w229:
@-----------------
	stmfd sp!, {lr}
	
	str_ addy, tmp
	tst addy, #0x20
	bl mirror2V_
	
	tst addy, #0x1E
	beq w229_none

	and r0, addy, #0x1F
	bl map89AB_
	and r0, addy, #0x1F
	bl mapCDEF_
	bic r0, addy, #0xF000
	bl chr01234567_
	ldmfd sp!, {pc}
w229_none:
	mov r0, #0
	bl map89ABCDEF_
	mov r0, #0
	bl chr01234567_
	ldr r1, =0x8001
	cmp r1, addy
	moveq r0, #1
	bleq chr01234567_
	ldmfd sp!, {pc}


@-----------------
w230:
@-----------------
	ldr r1, rom_sw
	ands r1, r1, r1
	andne r0, r0, #7
	bne map89AB_
	
	mov addy, lr
	str_ r0, tmp
	tst r0, #0x40
	bl mirror2H_
	ldr_ r0, tmp
	tst r0, #0x20
	andne r0, #0x1F
	andeq r0, #0x1E
	add r0, r0, #8
	str_ r0, tmp
	mov lr, addy
	moveq r0, r0, lsr#1
	beq map89ABCDEF_
	bl map89AB_
	ldr_ r0, tmp
	mov lr, addy
	b mapCDEF_


@-----------------
w231:
@-----------------
	str_ addy, tmp
	mov r0, addy
	mov addy, lr
	tst r0, #0x80
	bl mirror2V_
	ldr_ r0, tmp
	tst r0, #0x20
	movne lr, addy
	movne r0, r0, lsr#1
	andne r0, r0, #0xFF
	bne map89ABCDEF_

	and r0, r0, #0x1E
	str_ r0, tmp
	bl map89AB_
	ldr_ r0, tmp
	mov lr, addy
	b mapCDEF_
