@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper19init
	.global framehook
	.global hbhook
	counter = mapperdata+0
	enable = mapperdata+4
	reg0	= mapperdata+8
	reg1	= mapperdata+9
@---------------------------------------------------------------------------------
mapper19init:
@---------------------------------------------------------------------------------
	.word map19_8,map19_A,map19_C,map19_E

	adr r1,write0
	str_ r1,writemem_tbl+8

	adr r1,map19_r
	str_ r1,readmem_tbl+8
	
	adr r0,hook
	str_ r0,scanlinehook

	ldr r0,=VRAM_chr		@enable chr write
	ldr r1,=vram_write_tbl	
	mov r2,#8
	b filler

@---------------------------------------------------------------------------------
write0:
	cmp addy,#0x5000
	blo IO_W
	and r1,addy,#0x7800
	cmp r1,#0x5000
	streqb_ r0,counter+2
	moveq pc,lr

	cmp r1,#0x5800
	movne pc,lr
	strb_ r0,counter+3
	and r0,r0,#0x80
	strb_ r0,enable
	mov pc,lr
@---------------------------------------------------------------------------------
map19_r:
	cmp addy,#0x5000
	blo IO_R
	mov r0, #0

	and r1,addy,#0x7800

	cmp r1,#0x5000
	ldreqb_ r0,counter+2
	moveq pc,lr

	cmp r1,#0x5800
	ldreqb_ r0,counter+3
	biceq r0, r0, #0x80
	mov pc,lr

@---------------------------------------------------------------------------------
map19_8:
	cmp r0, #0xE0
	bcc 0f
	ldrb_ r1, reg0
	ands r1, r1, r1
	beq 1f
0:
	and r1,addy,#0x7800
	ldr r2,=writeCHRTBL
	ldr pc,[r2,r1,lsr#9]

map19_A:
	cmp r0, #0xE0
	bcc 0f
	ldrb_ r1, reg1
	ands r1, r1, r1
	beq 1f
0:
	and r1,addy,#0x7800
	ldr r2,=writeCHRTBL
	ldr pc,[r2,r1,lsr#9]

1:
	and r1,addy,#0x7800
	and r0, r0, #0x1F
	mov r1, r1, lsr#11
	b chr1k
	
map19_C:			@ Do NameTable RAMROM change, for mirroring.
	cmp r0, #0xE0
	movcc pc, lr

	mov r1, addy, lsr#11
	and r0, r0, #1
	and r1, r1, #3
	ldr r2, =NES_VRAM
	add r2, r2, r0, lsl#11
	ldr r0, =vram_map+8*4
	add r0, r0, r1, lsl#2
	str r2, [r0]
	mov pc, lr
@---------------------------------------------------------------------------------
map19_E:
@---------------------------------------------------------------------------------
	and r1,addy,#0x7800
	cmp r1,#0x6000
	beq map89_
	cmp r1,#0x7000
	beq mapCD_
	cmp r1,#0x6800
	movne pc, lr

	and r1, r0, #0x40
	strb_ r1, reg0
	and r1, r0, #0x80
	strb_ r1, reg1
	b mapAB_
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	@ldr_ r0, scanline
	@cmp r0, #100
	@bleq sprefresh

	ldrb_ r0,enable
	cmp r0,#0
	beq h1

	ldr_ r0,counter
@	adds r0,r0,#0x71aaab		@113.66667
	adds r0,r0,#0x720000
	str_ r0,counter
	bcc h1
	mov r0,#0
	strb_ r0,enable
	sub r0,r0,#0x10000
	str_ r0,counter
@	b irq6502
	b CheckI
h1:
	fetch 0