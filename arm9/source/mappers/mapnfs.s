@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mappernsfinit
	.global wram

	exchip		= mapperdata+0
	bankswitch	= mapperdata+4
	banksize	= mapperdata+8
	exaddr		= mapperdata+12
	songno		= mapperdata+16
	repcnt		= mapperdata+20
	banks		= mapperdata+24
@---------------------------------------------------------------------------------
mappernsfinit:	@play nsf files
@---------------------------------------------------------------------------------
	.word write, write, write, write

	stmfd sp!, {r3, r4, addy, lr}
	movs r0, #0
	str_ r0, songno
	str_ r0, repcnt
	str_ r0, exaddr
	ldr r1, =exram
	mov r2, #128/4
	bl filler

	ldr r0, =romsize
	ldr r0, [r0]
	ldr r1, =0xfff
	add r0, r0, r1
	mov r0, r0, lsr#12
	str_ r0, banksize

	@skip pal reset
	@remap the memtable
	ldr r0, =wram + 0xa000 - 0x4000
	str_ r0, memmap_tbl + 8
	ldr r0, =wram + 0x0000 - 0x6000
	str_ r0, memmap_tbl + 12
	ldr r0, =wram + 0x2000 - 0x8000
	str_ r0, memmap_tbl + 16
	ldr r0, =wram + 0x4000 - 0xA000
	str_ r0, memmap_tbl + 20
	ldr r0, =wram + 0x6000 - 0xC000
	str_ r0, memmap_tbl + 24
	ldr r0, =wram + 0x8000 - 0xE000
	str_ r0, memmap_tbl + 28
	
	@read the exchip flag
	adrl_ r0, nsfextrachipselect
	ldrb r0, [r0]
	str_ r0, exchip

	@set the start songno
	adrl_ r0, nsfstartsong
	ldrb r0, [r0]
	adrl_ r1, nsftotalsong
	ldrb r1, [r1]
	cmp r0, r1
	movhi r0, #1
	sub r0, r0, #1
	str_ r0, songno

	mov r0, #0
	adrl_ r1, nsfbankswitch
	ldrb r2, [r1], #1
	orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orr r0, r0, r2
		ldrb r2, [r1], #1
		orrs r0, r0, r2
	str_ r0, bankswitch
	beq bankswitchoff
bankswitchon:
	ldrh_ r0, nsfloadaddress
	mov r0, r0, lsr#12
	mov r1, #0
0:
	cmp r0, #8
	bcs 1f
	bl bankswitch_func
	add r1, r1, #1
	add r0, r0, #1
	b 0b

1:
	mov r2, #0
	
	adrl_ r3, nsfbankswitch
2:
	add r0, r2, #8
	ldrb r1, [r3, r2]
	bl bankswitch_func
	add r2, r2, #1
	cmp r2, #8
	bne 2b
3:
	ldr_ r0, exchip
	tst r0, #4
	beq bankswitchend

	mov r0, #6
	ldrb r1, [r3, #6]
	bl bankswitch_func
	mov r0, #7
	ldrb r1, [r3, #7]
	bl bankswitch_func
	b bankswitchend

bankswitchoff:
	ldr_ r0, rombase
	ldr_ r1, banksize
	cmp r1, #8
	movcs r1, #8

	ldr r2, =wram
	ldrh_ r3, nsfloadaddress
	sub r3, r3, #0x8000
	add r2, r2, r3
	add r2, r2, #0x2000
	rsb r3, r3, #0x8000	@r3 = 8000 - (load - 8000)
	mov r1, r1, lsl#12
	cmp r1, r3
	movcs r1, r3
l3:
	subs r1, r1, #1
	ldrb r3, [r0, r1]
	strb r3, [r2, r1]
	bne l3

bankswitchend:
4:
	adr r3, initdata
	ldrb r0, [r3], #1
	ldr r2, =wram + 0xa700
	strb r0, [r2]
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!

	ldrb r0, [r3], #1
	strb r0, [r2, #0xe]!
	ldrh_ r1, nsfinitaddress
	and r4, r1, #0xff
	strb r4, [r2, #1]!
	mov r4, r1, lsr#8
	strb r4, [r2, #1]!

	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!

	ldrb r0, [r3], #1
	strb r0, [r2, #0xb]!
	ldrh_ r1, nsfplayaddress
	and r4, r1, #0xff
	strb r4, [r2, #1]!
	mov r4, r1, lsr#8
	strb r4, [r2, #1]!

	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]

5:
	ldr addy, =0x4015
	mov r0, #0x1f
	bl soundwrite
	ldr addy, =0x4080
	mov r0, #0x80
	bl soundwrite
	ldr addy, =0x408a
	mov r0, #0xe8
	bl soundwrite


	adr r0, exread
	str_ r0, readmem_tbl + 8
	adr r0, exwrite
	str_ r0, writemem_tbl + 8

	@pal/ntsc?

	ldmfd sp!, {r3, r4, addy, pc}


@-------------------------------
exread:
@-------------------------------
	ldr r1, =0x4800
	cmp addy, r1
	bne IO_R

	adr r1, exram
	ldr_ r2, exaddr
	and r0, r2, #0x7f
	ldrb r0, [r1, r0]
	tst r2, #0x80
	addne r2, r2, #1
	orrne r2, r2, #0x80
	strne_ r2, exaddr
	mov pc, lr

@-------------------------------
exwrite:
@-------------------------------
	ldr r1, =0x5ff6
	cmp addy, r1
	bcs 0f

	ldr r1, =0x5016
	cmp addy, r1
	movcs pc, lr
	cmp addy, #0x4800
	bcc IO_W
	beq ew
	cmp addy, #0x5000
	movcc pc, lr
ew:
	adr r1, exram
	ldr_ r2, exaddr
	and addy, r2, #0x7f
	strb r0, [r1, addy]

	tst r2, #0x80
	addne r2, r2, #1
	orrne r2, r2, #0x80
	strne_ r2, exaddr
	mov pc, lr
0:
	and r2, addy, #0xf
	mov r1, r0
	mov r0, r2
	b bankswitch_func


@-------------------------------
write:
@-------------------------------
	ldr_ r1, exchip
	tst r1, #4
	beq 0f

	sub r1, addy, #0x6000
	ldr r2, =wram
	strb r0, [r2, r1]
0:
	cmp addy, #0xf800
	streq_ r0, exaddr
	mov pc, lr

@-------------------------------
bankswitch_func:
@-------------------------------
	stmfd sp!, {r2-r6}
	cmp r0, #6
	bcc bankend
	cmp r0, #16
	bcs bankend

	adrl_ r2, banks
	strb r1, [r2, r0]

	ldr r2, =wram
	cmp r0, #7
	addcs r2, #0x2000
	andcs r0, r0, #7
	andcc r0, r0, #1
	add r2, r2, r0, lsl#12

	mov r1, r1, lsl#12
	ldrh_ r3, nsfloadaddress
	ldr r4, =0xfff
	and r3, r3, r4
	sub r1, r1, r3
	
	ldr_ r3, rombase
	ldr_ r4, banksize
	mov r4, r4, lsl#12

	mov r5, #0x1000
loop:
	tst r1, #0x80000000
	bne flush0
	cmp r1, r4
	bcs flush0
	
	ldrb r0, [r3, r1]
	b flush
flush0:
	mov r0, #0
flush:
	strb r0, [r2], #1
	subs r5, r5, #1
	addne r1, r1, #1
	bne loop
bankend:
	ldmfd sp!, {r2-r6}
	mov pc, lr

exram:
	.skip 128
initdata:
	.byte	0x4c, 0x00, 0x47, 0x20, 0x4c, 0x00, 0x47, 0x20, 0x4c, 0x00, 0x47
	