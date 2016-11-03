@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper1init
	reg0 = mapperdata+0
	reg1 = mapperdata+1
	reg2 = mapperdata+2
	reg3 = mapperdata+3
	last_addr = mapperdata+4
	patch = mapperdata+12
	shift = mapperdata+13
	regbuf = mapperdata + 8
	wram_patch = mapperdata + 9
	wram_bank = mapperdata + 10
	wram_count = mapperdata + 11
@---------------------------------------------------------------------------------
mapper1init:
@---------------------------------------------------------------------------------
	.word write, write, write, write
	stmfd sp!, {lr}
	
	mov r0,#0x0c			@init MMC1 regs
	strb_ r0,reg0
	mov r0,#0x0
	strb_ r0,reg1
	strb_ r0,reg2
	strb_ r0,reg3
	strb_ r0, shift
	strb_ r0, regbuf
	strb_ r0, patch
	strb_ r0, wram_patch
	
	mov r0, #0
	bl map89AB_
	
	ldr_ r0, prgsize16k
	cmp r0, #32
	movcc r0, #-1
	movcs r0, #15
	movcs r1, #1
	strcsb_ r1, patch
	bl mapCDEF_
/*
@patch for games...
	stmfd sp!, {lr}
	ldr_ r1, rombase	@src
	ldr_ r2, romsize8k	@size
	mov r2, r2, lsl#13
	bl crc

	ldr r1, =0xb8e16bd0	@Snow Bros.(J)
	cmp r1, r0
	moveq r2, #2
	streqb_ r2, patch

	ldr r1, =0xcd2a73f0	@Pirates!(U)
	cmp r1, r0
	moveq r2, #2
	streqb_ r2, patch

	ldr r1, =0xc9556b36	@ Final Fantasy I&II(J)
	cmp r1, r0
	moveq r2, #2
	streqb_ r2, wram_patch

	ldr r1, =0xb8747abf	@Best Play - Pro Yakyuu Special(J)
	cmp r1, r0
	ldrne r1, =0x29449ba9	@Nobunaga no Yabou - Zenkoku Ban(J)
	cmpne r1, r0
	ldrne r1, =0x2b11e0b0	@Nobunaga no Yabou - Zenkoku Ban(J)(alt)
	cmpne r1, r0
	ldrne r1, =0x4642dda6	@Nobunaga's Ambition(U)
	cmpne r1, r0
	ldrne r1, =0xfb69743a	@Aoki Ookami to Shiroki Mejika - Genghis Khan(J)
	cmpne r1, r0
	ldrne r1, =0x2225c20f	@Genghis Khan(U)
	cmpne r1, r0
	ldrne r1, =0xabbf7217	@Sangokushi(J)
	cmpne r1, r0
	moveq r2, #0
	streqb_ r2, wram_patch
	moveq r2, #0
	streqb_ r2, wram_bank
	streqb_ r2, wram_count
*/
	ldmfd sp!, {pc}

@---------------------------------------------------------------------------------
write:		@($8000-$9FFF)
@---------------------------------------------------------------------------------
	stmfd sp!, {lr}
	stmfd sp!, {r0}
	
	ldr r1, =0xBFFF
	cmp r1, addy
	bne skip1
	ldrb_ r1, wram_patch
	cmp r1, #1
	bne skip1
	
	ldrb_ r2, wram_bank
	tst r0, #1
	addne r2, r2, #1
	strb_ r2, wram_bank
	
	ldrb_ r1, wram_count
	add r1, r1, #1
	strb_ r1, wram_count
	cmp r1, #5
	bne skip1
	
@something is wrong here..
	cmp r2, #0
	ldreq r0, =NES_SRAM - 0x6000
	ldrne r0, =NES_SRAM + 0x2000 - 0x6000	@too big.... in vnes, wram is 128k
	str_ r0,memmap_tbl+12
	mov r0, #0
	strb_ r2, wram_bank
	strb_ r1, wram_count

skip1:
	ldrb_ r1, patch
	cmp r1, #1
	beq skip2
	
	ldr_ r0, last_addr
	and r0, r0, #0x6000
	and r1, addy, #0x6000
	cmp r1, r0
	movne r2, #0
	strneb_ r2, shift
	strneb_ r2, regbuf
	str_ addy, last_addr

skip2:
	ldmfd sp!, {r0}
	tst r0, #0x80
	beq skip3
	
	mov r1, #0
	strb_ r1, shift
	strb_ r1, regbuf
	ldrb_ r1, reg0
	orr r1, r1, #0x0c
	strb_ r1, reg0
	ldmfd sp!, {pc}
@---
	.ltorg
	
skip3:
	tst r0, #1
	beq skip4
	
	ldrb_ r1, regbuf
	ldrb_ r2, shift
	mov r0, #1
	orr r1, r1, r0, lsl r2
	strb_ r1, regbuf

skip4:
	ldrb_ r2, shift
	add r2, r2, #1
	strb_ r2, shift
	cmp r2, #5
	bcs skip5
	
	ldmfd sp!, {pc}

skip5:
	bic r2, addy, #0xF8000
	mov r2, r2, lsr#13
	
	adrl_ r0, reg0
	ldrb_ r1, regbuf
	strb r1, [r0, r2]
	
	mov r0, #0
	strb_ r0, regbuf
	strb_ r0, shift
	
	ldrb_ r0, patch
	cmp r0, #1
	beq bigprom				@e.....
	
	ldr r1, =gotbl
	ldr pc, [r1, r2, lsl#2]
@-------------------------------------
gotbl:
	.word gol0, gol1, gol2, gol3
@-------------------------------------
gol0:	
	ldmfd sp!, {lr}
	ldrb_ r2, reg0
	tst r2, #0x2
	beq mirr4
	tst r2, #1
	b mirror2V_
mirr4:
	tst r2, #1
	b mirror1_
	
@-------------------------------------
gol1:
	ldr_ r0, vrommask
	tst r0, #0x80000000			@means that there is no vrom
	bne vrom0

	ldrb_ r2, reg0
	tst r2, #0x10
	beq chr8k
	
	ldrb_ r0, reg1
	bl chr0123_
	ldrb_ r0, reg2
	bl chr4567_
	ldmfd sp!, {pc}
	
chr8k:
	ldrb_ r0, reg1
	mov r0, r0, lsr#1
	bl chr01234567_
	ldmfd sp!, {pc}

vrom0:
	ldrb_ r2, reg0
	tst r2, #0x10
	@nesDS didnot support this....		@~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	ldrneb_ r0, reg1
	blne chr0123_
	ldmfd sp!, {pc}

@-------------------------------------
gol2:
	ldr_ r0, vrommask
	tst r0, #0x80000000			@means that there is no vrom
	bne vrom02

	ldrb_ r2, reg0
	tst r2, #0x10
	beq chr8k2
	
	ldrb_ r0, reg1
	bl chr0123_
	ldrb_ r0, reg2
	bl chr4567_
	ldmfd sp!, {pc}
	
chr8k2:
	ldrb_ r0, reg1
	mov r0, r0, lsr#1
	bl chr01234567_
	ldmfd sp!, {pc}

vrom02:
	ldrb_ r2, reg0
	tst r2, #0x10
	@nesDS didnot support this....		@~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	ldrneb_ r0, reg2
	blne chr4567_
	ldmfd sp!, {pc}
	
@-------------------------------------
gol3:
	ldrb_ r1, reg0
	tst r1, #0x8
	bne rom16k
	
	ldrb_ r1, reg3
	mov r0, r1, lsr#1
	ldmfd sp!, {lr}
	b map89ABCDEF_

rom16k:
	ldrb_ r1, reg0
	tst r1, #0x4
	beq romcf
	
	ldrb_ r0, reg3
	bl map89AB_
	
	mov r0, #-1
	bl mapCDEF_
	
	ldmfd sp!, {pc}
	
romcf:
	ldrb_ r0, reg3
	bl mapCDEF_
	mov r0, #0
	bl map89AB_
	
	ldmfd sp!, {pc}
@------------------------------------------------
bigprom:
	ldrb_ r0, wram_patch
	cmp r0, #2
	bne b1
	
	ldrb_ r0, reg1
	tst r0, #0x18
	ldreq r0, =NES_SRAM - 0x6000
	ldrne r0, =NES_SRAM + 0x2000 - 0x6000
	str_ r0,memmap_tbl+12

b1:
	cmp r2, #0
	bne b2

	ldrb_ r0, reg0
	and r0, r0, #3
	tst r0, #2
	bne 0f
	
	tst r0, #1
	bl mirror1H_
	b b2
0:
	tst r0, #1
	bl mirror2V_

b2:
	ldr_ r0, vrommask
	tst r0, #0x80000000
	bne b21

	ldrb_ r0, reg0
	tst r0, #0x10
	beq 0f

	ldrb_ r0, reg1
	bl chr0123_
	ldrb_ r0, reg2
	bl chr4567_
	b b3
0:
	ldrb_ r0, reg1
	mov r0, r0, lsr#1
	bl chr01234567_
	b b3

b21:
	ldrb_ r0, reg0
	tst r0, #0x10
	beq b3

	ldrb_ r0, reg1
	bl chr0123_
	ldrb_ r0, reg2
	bl chr4567_
b3:
	ldr_ r2, prgsize16k
	cmp r2, #32
	ldrcsb_ r1, reg1
	andcs r1, r1, #0x10
	movcc r1, #0
	str r1, prombase

	ldrb_ r0, reg0
	tst r0, #0x8
	beq b5

	tst r0, #0x4
	beq b4

	ldrb_ r2, reg3
	and r2, r2, #0xF
	add r0, r1, r2
	bl map89AB_

	ldr r1, prombase
	ldr_ r2, prgsize16k
	cmp r2, #32
	addcs r0, r1, #15
	blcs mapCDEF_
	ldmfd sp!, {pc}

b4:
	ldrb_ r2, reg3
	and r2, r2, #0xF
	add r0, r1, r2
	bl mapCDEF_

	ldr r1, prombase
	ldr_ r2, prgsize16k
	cmp r2, #32
	movcs r0, r1
	blcs map89AB_
	ldmfd sp!, {pc}

b5:
	add r1, r1, #0xF
	ldrb_ r2, reg3
	and r2, r2, r1
	mov r0, r2, lsr#1
	bl map89ABCDEF_
	ldmfd sp!, {pc}

@-----------------
prombase:
	.word 0