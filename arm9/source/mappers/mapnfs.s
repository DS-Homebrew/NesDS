;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------

	.global nsfHeader
	.global __nsfPlay
	.global __nsfInit
	.global __nsfSongNo
	.global __nsfSongMode
	.global nsfExtraChipSelect

	.global mappernsfinit

	.struct mapperData
exChip:		.word
bankswitch:	.word
bankSize:	.word
exAddr:		.word
songNo:		.word
repCnt:		.word
banks:		.word
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
mappernsfinit:	;@ Play nsf files
;@----------------------------------------------------------------------------
	.word write, write, write, write

	stmfd sp!, {r3, r4, addy, lr}
	movs r0, #0
	str_ r0, songNo
	str_ r0, repCnt
	str_ r0, exAddr
	ldr r1,=exram
	mov r2, #128/4
	bl filler

	ldr r0, =romsize
	ldr r0, [r0]
	ldr r1, =0xfff
	add r0, r0, r1
	mov r0, r0, lsr#12
	str_ r0, bankSize

	;@ Skip pal reset
	;@ Remap the memtable
	ldr r0, =wram + 0xa000 - 0x4000
	str_ r0, m6502MemTbl + 8
	ldr r0, =wram + 0x0000 - 0x6000
	str_ r0, m6502MemTbl + 12
	ldr r0, =wram + 0x2000 - 0x8000
	str_ r0, m6502MemTbl + 16
	ldr r0, =wram + 0x4000 - 0xA000
	str_ r0, m6502MemTbl + 20
	ldr r0, =wram + 0x6000 - 0xC000
	str_ r0, m6502MemTbl + 24
	ldr r0, =wram + 0x8000 - 0xE000
	str_ r0, m6502MemTbl + 28
	
	;@ Read the exChip flag
	ldrb r0, nsfExtraChipSelect
	str_ r0, exChip

	;@ Set the start songNo
	ldrb r0, nsfStartSong
	ldrb r1, nsfTotalSong
	cmp r0, r1
	movhi r0, #1
	sub r0, r0, #1
	str_ r0, songNo

	mov r0, #0
	adr r1, nsfBankSwitch
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
	beq bankswitchOff
bankswitchOn:
	ldr r0, =nsfLoadAddress
	ldrh r0, [r0]
	mov r0, r0, lsr#12
	mov r1, #0
0:
	cmp r0, #8
	bcs 1f
	bl bankswitchFunc
	add r1, r1, #1
	add r0, r0, #1
	b 0b

1:
	mov r2, #0

	adr r3, nsfBankSwitch
2:
	add r0, r2, #8
	ldrb r1, [r3, r2]
	bl bankswitchFunc
	add r2, r2, #1
	cmp r2, #8
	bne 2b
3:
	ldr_ r0, exChip
	tst r0, #4
	beq bankswitchEnd

	mov r0, #6
	ldrb r1, [r3, #6]
	bl bankswitchFunc
	mov r0, #7
	ldrb r1, [r3, #7]
	bl bankswitchFunc
	b bankswitchEnd

bankswitchOff:
	ldr_ r0, romBase
	ldr_ r1, bankSize
	cmp r1, #8
	movcs r1, #8

	ldr r2, =wram
	ldr r3, =nsfLoadAddress
	ldrh r3, [r3]
	sub r3, r3, #0x8000
	add r2, r2, r3
	add r2, r2, #0x2000
	rsb r3, r3, #0x8000	;@ r3 = 8000 - (load - 8000)
	mov r1, r1, lsl#12
	cmp r1, r3
	movcs r1, r3
l3:
	subs r1, r1, #1
	ldrb r3, [r0, r1]
	strb r3, [r2, r1]
	bne l3

bankswitchEnd:
4:
	adr r3, initData
	ldrb r0, [r3], #1
	ldr r2, =wram + 0xa700
	strb r0, [r2]
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!
	ldrb r0, [r3], #1
	strb r0, [r2, #1]!

	ldrb r0, [r3], #1
	strb r0, [r2, #0xe]!
	ldr r1, =nsfInitAddress
	ldrh r1, [r1]
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
	ldr r1, =nsfPlayAddress
	ldrh r1, [r1]
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


	adr r0, exRead
	str_ r0, rp2A03MemRead
	adr r0, exWrite
	str_ r0, rp2A03MemWrite

	;@ PAL/NTSC?

	ldmfd sp!, {r3, r4, addy, pc}


;@-------------------------------
exRead:
;@-------------------------------
	ldr r1, =0x4800
	cmp addy, r1
	bne empty_R

	adr r1, exram
	ldr_ r2, exAddr
	and r0, r2, #0x7f
	ldrb r0, [r1, r0]
	tst r2, #0x80
	addne r2, r2, #1
	orrne r2, r2, #0x80
	strne_ r2, exAddr
	bx lr

;@-------------------------------
exWrite:
;@-------------------------------
	ldr r1, =0x5ff6
	cmp addy, r1
	bcs 0f

	ldr r1, =0x5016
	cmp addy, r1
	bxcs lr
	cmp addy, #0x4800
	bxcc lr
	beq ew
	cmp addy, #0x5000
	bxcc lr
ew:
	adr r1, exram
	ldr_ r2, exAddr
	and addy, r2, #0x7f
	strb r0, [r1, addy]

	tst r2, #0x80
	addne r2, r2, #1
	orrne r2, r2, #0x80
	strne_ r2, exAddr
	bx lr
0:
	mov r1, r0
	and r2, addy, #0xf
	mov r0, r2
	b bankswitchFunc


;@-------------------------------
write:
;@-------------------------------
	ldr_ r1, exChip
	tst r1, #4
	beq 0f

	sub r1, addy, #0x6000
	ldr r2, =wram
	strb r0, [r2, r1]
0:
	cmp addy, #0xf800
	streq_ r0, exAddr
	bx lr

;@-------------------------------
bankswitchFunc:
;@-------------------------------
	stmfd sp!, {r2-r6}
	cmp r0, #6
	bcc bankEnd
	cmp r0, #16
	bcs bankEnd

	adrl_ r2, banks
	strb r1, [r2, r0]

	ldr r2, =wram
	cmp r0, #7
	addcs r2, #0x2000
	andcs r0, r0, #7
	andcc r0, r0, #1
	add r2, r2, r0, lsl#12

	mov r1, r1, lsl#12
	ldrh r3, nsfLoadAddress
	ldr r4, =0xfff
	and r3, r3, r4
	sub r1, r1, r3

	ldr_ r3, romBase
	ldr_ r4, bankSize
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
bankEnd:
	ldmfd sp!, {r2-r6}
	bx lr


;@-------------------------------
nsfHeader:

nsfId:				.skip 5
nsfVersion:			.byte 0
nsfTotalSong:		.byte 0
nsfStartSong:		.byte 0
nsfLoadAddress: 	.short 0
nsfInitAddress: 	.short 0
nsfPlayAddress: 	.short 0
nsfSongName:		.skip 32
nsfArtistName:		.skip 32
nsfCopyrightName:	.skip 32
nsfSpeedNtsc:		.short 0
nsfBankSwitch:		.skip 8
nsfSpeedPal: 		.short 0
nsfNtscPalBits:		.byte 0
nsfExtraChipSelect:	.byte 0
nsfExpansion:		.skip 4
;@-------------------------------
__nsfPlay:
nsfPlay:
	.word 0
__nsfInit:
nsfInit:
	.word 0
__nsfSongNo:
nsfSongNo:
	.word 0
__nsfSongMode:
nsfSongMode:
	.word 0

;@-------------------------------
exram:
	.skip 128
initData:
	.byte	0x4c, 0x00, 0x47, 0x20, 0x4c, 0x00, 0x47, 0x20, 0x4c, 0x00, 0x47
