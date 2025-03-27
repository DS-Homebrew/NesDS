;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper20init
	.global fdscmdwrite
	.global diskbios

	.struct mapperData
irqEnable:			.byte 0
irqRepeat:			.byte 0
irqOccur:			.byte 0
irqTransfer:		.byte 0
diskEnable:			.byte 0
soundEnable:		.byte 0
rwStart:			.byte 0
rwMode:				.byte 0
diskMotorMode:		.byte 0
diskEject:			.byte 0
driveReady:			.byte 0
driveReset:			.byte 0
firstAccess:		.byte 0
diskSide:			.byte 0
diskMountCount:		.byte 0
irqType:			.byte 0
soundStartupFlag:	.byte 0
					.skip 3 ;@ Align
bDiskThrottle:		.word 0
diskThrottleTime:	.word 0
disk:				.word 0
diskW:				.word 0
irqCounter:			.word 0
irqLatch:			.word 0
blockPoint:			.word 0
blockMode:			.word 0
sizeFileData:		.word 0
fileAmount:			.word 0
point:				.word 0
soundStartupTimer: 	.word 0
soundSeekendTimer: 	.word 0

diskNo:				.word 0
makerId: 			.word 0
gameId:				.word 0


EXCMDWR_NONE		= 0
EXCMDWR_DISKINSERT	= 1
EXCMDWR_DISKEJECT	= 2

BLOCK_READY			= 0
BLOCK_VOLUME_LABEL	= 1
BLOCK_FILE_AMOUNT	= 2
BLOCK_FILE_HEADER	= 3
BLOCK_FILE_DATA		= 4

SIZE_VOLUME_LABEL	= 56
SIZE_FILE_AMOUNT	= 2
SIZE_FILE_HEADER	= 16

OFFSET_VOLUME_LABEL	= 0
OFFSET_FILE_AMOUNT	= 56
OFFSET_FILE_HEADER	= 58
OFFSET_FILE_DATA	= 74

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ FDS expansion
mapper20init:
;@----------------------------------------------------------------------------
	@.word void, void, void, void
	.word write, write, write, void

	ldr_ r2, romBase
	ldrb r1, [r2, #-12]		;@ diskNo		DEBUG this...
	strb_ r1, diskNo
	DEBUGINFO DISKNO, r1
	mov r0, r1, lsl#2
	strb_ r0, prgSize16k		;@ 65500 * diskNo, not equal...
	ldrb r1, [r2, #0x1F]		;@ makerId.... I dont know..
	strb_ r1, makerId
	DEBUGINFO MAKEID, r1
	ldrb r1, [r2, #0x20]
	mov r0, r1, lsl#24
	ldrb r1, [r2, #0x21]
	orr r0, r0, r1, lsl#16
	ldrb r1, [r2, #0x22]
	orr r0, r0, r1, lsl#8
	ldrb r1, [r2, #0x23]
	orr r0, r0, r1
	str_ r0, gameId
	DEBUGINFO GAMEID, r0
	mov r0, #20
	DEBUGINFO MAPPER, r0

	mov r0, #0xff
	strb_ r0, diskEnable
	strb_ r0, soundEnable
	strb_ r0, rwStart
	strb_ r0, diskEject
	strb_ r0, diskSide
	strb_ r0, soundStartupFlag

	mov r0, #119
	strb_ r0, diskMountCount

	mov r0, #-1
	str_ r0, soundStartupTimer
	str_ r0, soundSeekendTimer

	@MechanicalSound

	ldr r0, =NES_VRAM
	str_ r0, vromBase

	ldr r0, =NES_DRAM - 0x6000
	str_ r0, m6502MemTbl + 12
	str_ r0, m6502MemTbl + 16
	str_ r0, m6502MemTbl + 20
	str_ r0, m6502MemTbl + 24
	ldr r0, =diskbios - 0xE000
	str_ r0, m6502MemTbl + 28

	ldr r2, =0xFFFFFFFF
	mov r1, #0x100/4
	ldr r0, =NES_RAM + 0x100
0:
	str r2, [r0], #4
	subs r1, r1, #1
	bne 0b

	ldr_ r2, romBase
	str_ r2, disk
	ldr r1, =NES_DISK
	str_ r1, diskW

	adr r0, exRead
	str_ r0, rp2A03MemRead
	adr r0, exWrite
	str_ r0, rp2A03MemWrite
	ldr r0, =writel
	str_ r0, m6502WriteTbl + 12
	ldr r0, =hSync
	str_ r0, scanlineHook
	ldr r0, =frameEnd
	str_ r0, endFrameHook

	@mov r0, #NESCMD_DISK_THROTTLE_OFF

	bx lr

;@-------------------------------
exRead:
;@-------------------------------
	mov r0, addy, lsr#8
	cmp r0, #0x40
	bne empty_R
	and r1, addy, #0xFF
	cmp r1, #0x34
	bcs empty_R
	subs r1, r1, #0x30
	ldrcs pc, [pc, r1, lsl#2]
	b empty_R
;@--------------------------
exrTbl:
	.word r30, r31, r32, r33
r30:
	stmfd sp!,{lr}
	mov r0,#0
	bl rp2A03SetIRQPin			;@ Clear IRQ pin on CPU
	ldmfd sp!,{lr}
	mov r0, #0x80
	mov r1, #0
	ldrb_ r2, irqOccur
	strb_ r1, irqOccur
	ands r2, r2, r2
	bxeq lr
	ldrb_ r2, irqTransfer
	tst r2, #0xFF
	orrne r0, #0x2
	orreq r0, #0x1
	bx lr

r31:
	ldrb_ r0, rwMode
	ands r0, r0, r0
	moveq r0, #0xFF
	bxeq lr

	mov r0, #0
	strb_ r0, firstAccess

	ldr_ r0, disk
	ands r0, r0, r0
	moveq r0, #0xFF
	bxeq lr

	ldr_ r0, blockMode
	ldr pc, [pc, r0, lsl#2]
	nop
;@-----------------------
r31Tbl:
	.word exReadReady, exReadLabel, exReadAmount, exReadHeader, exReadData
;@-----------------------
exReadReady:
	mov r0, addy, lsr#8
	bx lr

exReadLabel:
	ldr_ r1, disk
	ldr_ r2, blockPoint
	ldrb r0, [r1, r2]
	cmp r2, #SIZE_VOLUME_LABEL
	addcc r2, r2, #1
	strcc_ r2, blockPoint
	movcs r0, #0
	bx lr

exReadAmount:
	ldr_ r0, disk
	ldr_ r1, blockPoint
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	cmp r1, #SIZE_FILE_AMOUNT
	addcc r1, r1, #1
	strcc_ r1, blockPoint
	strcc_ r0, fileAmount
	movcs r0, #0
	bx lr

exReadHeader:
	ldr_ r0, disk
	ldr_ r1, blockPoint
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	cmp r1, #13
	streq_ r0, sizeFileData
	cmp r1, #14
	ldreq_ r2, sizeFileData
	addeq r2, r0, lsl#8
	streq_ r2, sizeFileData

	cmp r1, #SIZE_FILE_HEADER
	addcc r1, r1, #1
	strcc_ r1, blockPoint
	movcs r0, #0
	bx lr

exReadData:
	ldr_ r0, disk
	ldr_ r1, blockPoint
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	ldr_ r2, sizeFileData
	cmp r1, r2
	addls r1, r1, #1
	strls_ r1, blockPoint
	movhi r0, #0
	bx lr

r32:
	mov r0, #0x40
	ldrb_ r1, diskEject
	ands r1, r1, r1
	orrne r0, #0x7
	bxne lr

	ldrb_ r1, diskMotorMode
	ands r1, r1, r1
	bxeq lr

	ldrb_ r1, driveReset
	ands r1, r1, r1
	biceq r0, r0, #0x2
	bx lr

r33:
	mov r0, #0x80
	bx lr


;@-------------------------------
exWrite:
;@-------------------------------
	mov r1, addy, lsr#8
	cmp r1, #0x40
	bne empty_W
	and r1, addy, #0xFF
	cmp r1, #0x90
	bcs empty_W
	cmp r1, #0x40
	bcs soundwrite
	sub r1, r1, #0x20
	cmp r1, #0x07
	ldrmi pc, [pc, r1, lsl#2]
	b empty_W
exwTbl:
	.word w20, w21, w22, w23, w24, w25, w26

;@-----
w20:
	strb_ r0, irqLatch
	bx lr
w21:
	strb_ r0, irqLatch+1
	bx lr
w22:
	mov r1, #0
	strb_ r1, irqOccur
	and r1, r0, #1
	strb_ r1, irqRepeat
	ands r0, r0, #2
	streqb_ r0, irqEnable
	beq rp2A03SetIRQPin			;@ Clear IRQ pin on CPU
	ldrb_ r0, diskEnable
	ands r0, r0, r0
	strb_ r0, irqEnable
	bxeq lr
	ldr_ r0, irqLatch
	str_ r0, irqCounter
	bx lr

w23:
	ands r0, r0, #1
	strb_ r0, diskEnable
	bxne lr
	strb_ r0, irqEnable
	strb_ r0, irqOccur
	b rp2A03SetIRQPin			;@ Clear IRQ pin on CPU

w24:
	ldrb_ r1, rwMode
	ands r1, r1, r1
	bxne lr

	ldrb_ r1, firstAccess
	ands r1, r1, r1
	movne r1, #0
	strneb_ r1, firstAccess
	bxne lr

	ldr_ r1, disk
	ands r1, r1, r1
	bxeq lr

	ldr_ r1, blockMode
	ldr pc, [pc, r1, lsl#2]
	nop
w24tbl:
	.word void, exWriteLabel, exWriteAmount, exWriteHeader, exWriteData
;@---------------
exWriteLabel:
	ldr_ r1, blockPoint
	cmp r1, #SIZE_VOLUME_LABEL
	bxhi lr
	ldr_ r2, disk
	strb r0, [r2, r1]
	ldr_ r2, diskW
	mov r0, #0xFF
	strb r0, [r2, r1]
	add r1, r1, #1
	str_ r1, blockPoint
	bx lr

exWriteAmount:
	ldr_ r1, blockPoint
	cmp r1, #SIZE_FILE_AMOUNT
	bxcs lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]
	ldr_ r2, diskW
	mov r0, #0xFF
	strb r0, [r2, addy]
	add r1, r1, #1
	str_ r1, blockPoint
	bx lr

exWriteHeader:
	ldr_ r1, blockPoint
	cmp r1, #SIZE_FILE_HEADER
	bxcs lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]

	cmp r1, #13
	streq_ r0, sizeFileData
	cmp r1, #14
	ldreq_ r2, sizeFileData
	orreq r2, r0, lsl#8
	streq_ r2, sizeFileData

	ldr_ r2, diskW
	mov r0, #0xFF
	strb r0, [r2, addy]

	add r1, r1, #1
	str_ r1, blockPoint
	bx lr

exWriteData:
	ldr_ r1, blockPoint
	ldr_ r2, sizeFileData
	cmp r1, r2
	bxhi lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]
	ldr_ r2, diskW
	mov r0, #0xFF
	strb r0, [r2, addy]
	add r1, r1, #1
	str_ r1, blockPoint
	bx lr

w25:
	and r1, r0, #0x80
	strb_ r1, irqTransfer
	;@ Clear irq....
	ands r1, r0, #0x40
	beq 0f
	ldrb_ r1, rwStart
	ands r1, r1, r1
	bne 0f
	str_ r1, blockPoint
	mov r1, #0xff
	strb_ r1, firstAccess

	ldr_ r1, blockMode
	ldr pc, [pc, r1, lsl#2]
	nop
exChTbl:
	.word exChReady, exChLabel, exChAmount, exChHeader, exChData
;@-------------------
exChReady:
	mov r1, #BLOCK_VOLUME_LABEL
	str_ r1, blockMode
	mov r1, #0
	str_ r1, point
	b 0f

exChLabel:
	mov r1, #BLOCK_FILE_AMOUNT
	str_ r1, blockMode
	ldr_ r1, point
	add r1, r1, #SIZE_VOLUME_LABEL
	str_ r1, point
	b 0f

exChAmount:
	mov r1, #BLOCK_FILE_HEADER
	str_ r1, blockMode
	ldr_ r1, point
	add r1, r1, #SIZE_FILE_AMOUNT
	str_ r1, point
	b 0f

exChHeader:
	mov r1, #BLOCK_FILE_DATA
	str_ r1, blockMode
	ldr_ r1, point
	add r1, r1, #SIZE_FILE_HEADER
	str_ r1, point
	b 0f

exChData:
	mov r1, #BLOCK_FILE_HEADER
	str_ r1, blockMode
	ldr_ r2, point
	ldr_ r1, sizeFileData
	add r2, r2, #1
	add r2, r2, r1
	str_ r2, point

0:
	and r1, r0, #0x40
	strb_ r1, rwStart
	and r1, r0, #0x4
	strb_ r1, rwMode

	tst r0, #0x2
	beq 1f
	mov r1, #0
	str_ r1, point
	str_ r1, blockPoint
	mov r1, #BLOCK_READY
	str_ r1, blockMode
	mov r1, #0
	strb_ r1, soundStartupFlag
	mov r1, #0xff
	strb_ r1, rwStart
	strb_ r1, driveReset
	mov r1, #-1
	strb_ r1, soundStartupTimer
	b 2f

1:
	mov r1, #0
	strb_ r1, driveReset
	ldrb_ r1, soundStartupFlag
	ands r1, r1, r1
	bne 2f
	@MechanicalSound( MECHANICAL_SOUND_MOTOR_ON );
	mov r1, #0xFF
	strb_ r1, soundStartupFlag
	mov r1, #40
	str_ r1, soundStartupTimer
	mov r1, #60*7
	str_ r1, soundStartupTimer

2:
	ands r1, r0, #1
	strb_ r1, diskMotorMode
	bne 0f
	ldr_ r1, soundSeekendTimer
	tst r1, #0x80000000
	moveq r1, #-1
	streq_ r1, soundSeekendTimer
	@MechanicalSound( MECHANICAL_SOUND_MOTOR_OFF );

0:
	tst r0, #8
	b mirror2V_
;@-------------
w26:
	bx lr

;@-------------
writel:
	ldr r2, =NES_DRAM - 0x6000
	strb r0, [r2, addy]
	bx lr

;@-------------
write:
	ldr r2, =NES_DRAM - 0x6000
	strb r0, [r2, addy]
	bx lr

;@-------------
hSync:
	ldrb_ r0, irqEnable
	ands r0, r0, r0
	beq checkTr

	ldr_ r1, irqCounter
	ldrb_ r2, irqType
	ands r2, r2, r2
	subeq r1, r1, #114

	tst r1, #0x80000000
	str_ r1, irqCounter
	beq 0f

	ldr_ r0, irqLatch
	add r1, r1, r0
	str_ r1, irqCounter

	ldrb_ r0, irqOccur
	ands r0, r0, r0
	bne 0f

	mov r0, #0xff
	strb_ r0, irqOccur

	ldrb_ r0, irqRepeat
	ands r0, r0, r0
	streqb_ r0, irqEnable

	mov r0,#1
	b rp2A03SetIRQPin			;@ Set IRQ pin on CPU

0:
	ldr_ r1, irqCounter
	ldrb_ r2, irqType
	ands r2, r2, r2
	subne r1, r1, #114
	strne_ r1, irqCounter

checkTr:
	ldrb_ r0, irqTransfer
	ands r0, r0, r0
	bne rp2A03SetIRQPin			;@ Set IRQ pin on CPU
	bx lr


;@-------------
frameEnd:
	ldr_ r1, disk
	ands r1, r1, r1
	beq b1

	ldrb_ r1, diskEject
	ands r1, r1, r1
	beq a0

	ldrb_ r1, diskMountCount
	cmp r1, #121
	movcs r0, #0
	strcsb_ r0, diskEject
	addcc r1, r1, #1
	strccb_ r1, diskMountCount

a0:
	ldr_ r1, soundStartupTimer
	subs r1, r1, #1
	str_ r1, soundStartupTimer
	@blcc MechanicalSound( MECHANICAL_SOUND_BOOT );

	ldr_ r1, soundSeekendTimer
	subs r1, r1, #1
	str_ r1, soundSeekendTimer
	@blcc MechanicalSound( MECHANICAL_SOUND_MOTOR_OFF );
	@MechanicalSound( MECHANICAL_SOUND_SEEKEND );
	movcc r0, #0
	strccb_  r0, soundStartupFlag

b0:
	ldr_ r1, disk
	ands r1, r1, r1
	beq b1

	ldrb_ r1, diskMountCount
	cmp r1, #120
	bcc c0

b1:
	ldrb_ r1, irqTransfer
	ands r1, r1, r1
	beq d0

c0:
	ldr_ r1, diskThrottleTime
	cmp r1, #3
	movcs r2, #1
	movcc r2, #0
	str_ r2, bDiskThrottle
	ldrcc_ r1, diskThrottleTime
	addcc r1, r1, #1
	strcc_ r1, diskThrottleTime
	b e0

d0:
	mov r0, #0
	str_ r0, diskThrottleTime
	str_ r0, bDiskThrottle

e0:
	@ldr_ r0, bDiskThrottle
	@b command
	bx lr

;@------------------------------------
fdscmdwrite:	;@ Called when....
	@r0 = data
	stmfd sp!,{globalptr,lr}
	ldr globalptr,=globals

exCmdInsert:
	strb_ r0, diskSide
	ldr r3, =65500
	mov r2, #0
	tst r0, #2
	movne r2, r3, lsl#1
	tst r0, #1
	addne r2, r2, r3

	ldr_ r1, romBase
	add r3, r1, r2
	str_ r3, disk

	ldr r1, =NES_DISK
	add r3, r1, r2
	str_ r3, diskW

	mov r0, #0xFF
	strb_ r0, diskEject
	mov r0, #0
	strb_ r0, driveReady
	strb_ r0, diskMountCount

	ldmfd sp!,{globalptr,pc}

exCmdEject:
	mov r0, #0
	str_ r0, disk
	str_ r0, diskW
	strb_ r0, driveReady
	strb_ r0, diskMountCount
	mov r0, #0xFF
	strb_ r0, diskEject
	strb_ r0, diskSide
	bx lr

.ltorg

;@-------------------------------
.section .bss, "aw"
@NES_DRAM:			@defined in memory.s
	@.skip 0x8000
@NES_DISK:			@defined in memory.s
	@.skip 0x40000		@max for 256k
	@.skip 4
