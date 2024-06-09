@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper20init
	.global fdscmdwrite
	.global diskbios
	irq_enable	= mapperData
	irq_repeat	= mapperData + 1
	irq_occur	= mapperData + 2
	irq_transfer	= mapperData + 3
	disk_enable	= mapperData + 4
	sound_enable	= mapperData + 5
	RW_start	= mapperData + 6
	RW_mode		= mapperData + 7
	disk_motor_mode = mapperData + 8
	disk_eject	= mapperData + 9
	drive_ready	= mapperData + 10
	drive_reset	= mapperData + 11
	first_access	= mapperData + 12
	disk_side	= mapperData + 13
	disk_mount_count = mapperData + 14
	irq_type	= mapperData + 15
	sound_startup_flag = mapperData + 16
	bDiskThrottle	= mapperData + 17

	DiskThrottleTime= mapperData + 24
	disk		= mapperData + 28
	disk_w		= mapperData + 32
	irq_counter	= mapperData + 36
	irq_latch	= mapperData + 40
	block_point	= mapperData + 44
	block_mode	= mapperData + 48
	size_file_data	= mapperData + 52
	file_amount	= mapperData + 56
	point		= mapperData + 60
	sound_startup_timer= mapperData + 64
	sound_seekend_timer= mapperData + 68
	
	diskno	= mapperData + 72
	makerid = mapperData + 76
	gameid	= mapperData + 80


EXCMDWR_NONE		= 0
EXCMDWR_DISKINSERT	= 1
EXCMDWR_DISKEJECT	= 2

BLOCK_READY		= 0
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

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ FDS expansion
mapper20init:
@---------------------------------------------------------------------------------
	@.word void, void, void, void
	.word write, write, write, void

	ldr_ r2, romBase
	ldrb r1, [r2, #-12]		@diskno		DEBUT this...
	strb_ r1, diskno
	DEBUGINFO DISKNO, r1
	mov r0, r1, lsl#2
	strb_ r0, prgSize16k		@65500 * diskno, not equal...
	ldrb r1, [r2, #0x1F]		@makerid.... I dont know..
	strb_ r1, makerid
	DEBUGINFO MAKEID, r1
	ldrb r1, [r2, #0x20]
	mov r0, r1, lsl#24
	ldrb r1, [r2, #0x21]
	orr r0, r0, r1, lsl#16
	ldrb r1, [r2, #0x22]
	orr r0, r0, r1, lsl#8
	ldrb r1, [r2, #0x23]
	orr r0, r0, r1
	str_ r0, gameid
	DEBUGINFO GAMEID, r0
	mov r0, #20
	DEBUGINFO MAPPER, r0

	mov r0, #0xff
	strb_ r0, disk_enable
	strb_ r0, sound_enable
	strb_ r0, RW_start
	strb_ r0, disk_eject
	strb_ r0, disk_side
	strb_ r0, sound_startup_flag

	mov r0, #119
	strb_ r0, disk_mount_count

	mov r0, #-1
	str_ r0, sound_startup_timer
	str_ r0, sound_seekend_timer

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
	str_ r1, disk_w

	adr r0, exread
	str_ r0, m6502ReadTbl + 8
	adr r0, exwrite
	str_ r0, m6502WriteTbl + 8
	ldr r0, =writel
	str_ r0, m6502WriteTbl + 12
	ldr r0, =hsync
	str_ r0, scanlineHook
	ldr r0, =frameend
	str_ r0, endFrameHook

	@mov r0, #NESCMD_DISK_THROTTLE_OFF

	bx lr

@-------------------------------
exread:
@-------------------------------
	ldr r1, =0x4020
	cmp addy, r1
	bcc IO_R

	mov r0, addy, lsr#8
	cmp r0, #0x40
	bxne lr
	and r1, addy, #0xFF
	cmp r1, #0x34
	bcs IO_R
	subs r1, r1, #0x30
	ldrcs pc, [pc, r1, lsl#2]
	b empty_R
@--------------------------
exrtbl:
	.word r30, r31, r32, r33
r30:
	mov r0, #0x80
	mov r1, #0
	ldrb_ r2, irq_occur
	strb_ r1, irq_occur
	ands r2, r2, r2
	bxeq lr
	ldrb_ r2, irq_transfer
	tst r2, #0xFF
	orrne r0, #0x2
	orreq r0, #0x1
	bx lr

r31:
	ldrb_ r0, RW_mode
	ands r0, r0, r0
	moveq r0, #0xFF
	bxeq lr

	mov r0, #0
	strb_ r0, first_access

	ldr_ r0, disk
	ands r0, r0, r0
	moveq r0, #0xFF
	bxeq lr

	ldr_ r0, block_mode
	ldr pc, [pc, r0, lsl#2]
	nop
@-----------------------
r31tbl:
	.word exread_ready, exread_label, exread_amount, exread_header, exread_data
@-----------------------
exread_ready:
	mov r0, addy, lsr#8
	bx lr

exread_label:
	ldr_ r1, disk
	ldr_ r2, block_point
	ldrb r0, [r1, r2]
	cmp r2, #SIZE_VOLUME_LABEL
	addcc r2, r2, #1
	strcc_ r2, block_point
	movcs r0, #0
	bx lr

exread_amount:
	ldr_ r0, disk
	ldr_ r1, block_point
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	cmp r1, #SIZE_FILE_AMOUNT
	addcc r1, r1, #1
	strcc_ r1, block_point
	strcc_ r0, file_amount
	movcs r0, #0
	bx lr

exread_header:
	ldr_ r0, disk
	ldr_ r1, block_point
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	cmp r1, #13
	streq_ r0, size_file_data
	cmp r1, #14
	ldreq_ r2, size_file_data
	addeq r2, r0, lsl#8
	streq_ r2, size_file_data

	cmp r1, #SIZE_FILE_HEADER
	addcc r1, r1, #1
	strcc_ r1, block_point
	movcs r0, #0
	bx lr

exread_data:
	ldr_ r0, disk
	ldr_ r1, block_point
	ldr_ r2, point
	add r2, r1, r2
	ldrb r0, [r0, r2]
	ldr_ r2, size_file_data
	cmp r1, r2
	addls r1, r1, #1
	strls_ r1, block_point
	movhi r0, #0
	bx lr

r32:
	mov r0, #0x40
	ldrb_ r1, disk_eject
	ands r1, r1, r1
	orrne r0, #0x7
	bxne lr

	ldrb_ r1, disk_motor_mode
	ands r1, r1, r1
	bxeq lr

	ldrb_ r1, drive_reset
	ands r1, r1, r1
	biceq r0, r0, #0x2
	bx lr

r33:
	mov r0, #0x80
	bx lr


@-------------------------------
exwrite:
@-------------------------------
	ldr r1, =0x4020
	cmp addy, r1
	bcc IO_W

	mov r1, addy, lsr#8
	cmp r1, #0x40
	bne empty_W
	and r1, addy, #0xFF
	cmp r1, #0x27
	bcs IO_W
	subs r1, r1, #0x20

	ldrcs pc, [pc, r1, lsl#2]
	bx lr
exwtbl:
	.word w20, w21, w22, w23, w24, w25, w26

@-----
w20:
	strb_ r0, irq_latch
	bx lr
w21:
	strb_ r0, irq_latch+1
	bx lr
w22:
	mov r1, #0
	strb_ r1, irq_occur
	and r1, r0, #1
	strb_ r1, irq_repeat
	ands r1, r0, #2
	streqb_ r1, irq_enable
	bxeq lr
	ldrb_ r1, disk_enable
	ands r1, r1, r1
	strb_ r1, irq_enable
	bxeq lr
	ldr_ r1, irq_latch
	str_ r1, irq_counter
	bx lr

w23:
	ands r0, r0, #1
	strb_ r0, disk_enable
	bxne lr
	strb_ r0, irq_enable
	strb_ r0, irq_occur
	bx lr

w24:
	ldrb_ r1, RW_mode
	ands r1, r1, r1
	bxne lr

	ldrb_ r1, first_access
	ands r1, r1, r1
	movne r1, #0
	strneb_ r1, first_access
	bxne lr

	ldr_ r1, disk
	ands r1, r1, r1
	bxeq lr

	ldr_ r1, block_mode
	ldr pc, [pc, r1, lsl#2]
	nop
w24tbl:
	.word void, exwrite_label, exwrite_amount, exwrite_header, exwrite_data
@---------------
exwrite_label:
	ldr_ r1, block_point
	cmp r1, #SIZE_VOLUME_LABEL
	bxhi lr
	ldr_ r2, disk
	strb r0, [r2, r1]
	ldr_ r2, disk_w
	mov r0, #0xFF
	strb r0, [r2, r1]
	add r1, r1, #1
	str_ r1, block_point
	bx lr

exwrite_amount:
	ldr_ r1, block_point
	cmp r1, #SIZE_FILE_AMOUNT
	bxcs lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]
	ldr_ r2, disk_w
	mov r0, #0xFF
	strb r0, [r2, addy]
	add r1, r1, #1
	str_ r1, block_point
	bx lr

exwrite_header:
	ldr_ r1, block_point
	cmp r1, #SIZE_FILE_HEADER
	bxcs lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]

	cmp r1, #13
	streq_ r0, size_file_data
	cmp r1, #14
	ldreq_ r2, size_file_data
	orreq r2, r0, lsl#8
	streq_ r2, size_file_data

	ldr_ r2, disk_w
	mov r0, #0xFF
	strb r0, [r2, addy]

	add r1, r1, #1
	str_ r1, block_point
	bx lr

exwrite_data:
	ldr_ r1, block_point
	ldr_ r2, size_file_data
	cmp r1, r2
	bxhi lr
	ldr_ addy, point
	add addy, addy, r1
	ldr_ r2, disk
	strb r0, [r2, addy]
	ldr_ r2, disk_w
	mov r0, #0xFF
	strb r0, [r2, addy]
	add r1, r1, #1
	str_ r1, block_point
	bx lr

w25:
	and r1, r0, #0x80
	strb_ r1, irq_transfer
	@clear irq....
	ands r1, r0, #0x40
	beq 0f
	ldrb_ r1, RW_start
	ands r1, r1, r1
	bne 0f
	str_ r1, block_point
	mov r1, #0xff
	strb_ r1, first_access

	ldr_ r1, block_mode
	ldr pc, [pc, r1, lsl#2]
	nop
exchtbl:
	.word exch_ready, exch_label, exch_amount, exch_header, exch_data
@-------------------	
exch_ready:
	mov r1, #BLOCK_VOLUME_LABEL
	str_ r1, block_mode
	mov r1, #0
	str_ r1, point
	b 0f

exch_label:
	mov r1, #BLOCK_FILE_AMOUNT
	str_ r1, block_mode
	ldr_ r1, point
	add r1, r1, #SIZE_VOLUME_LABEL
	str_ r1, point
	b 0f

exch_amount:
	mov r1, #BLOCK_FILE_HEADER
	str_ r1, block_mode
	ldr_ r1, point
	add r1, r1, #SIZE_FILE_AMOUNT
	str_ r1, point
	b 0f

exch_header:
	mov r1, #BLOCK_FILE_DATA
	str_ r1, block_mode
	ldr_ r1, point
	add r1, r1, #SIZE_FILE_HEADER
	str_ r1, point
	b 0f

exch_data:
	mov r1, #BLOCK_FILE_HEADER
	str_ r1, block_mode
	ldr_ r2, point
	ldr_ r1, size_file_data
	add r2, r2, #1
	add r2, r2, r1
	str_ r2, point

0:
	and r1, r0, #0x40
	strb_ r1, RW_start
	and r1, r0, #0x4
	strb_ r1, RW_mode

	tst r0, #0x2
	beq 1f
	mov r1, #0
	str_ r1, point
	str_ r1, block_point
	mov r1, #BLOCK_READY
	str_ r1, block_mode
	mov r1, #0
	strb_ r1, sound_startup_flag
	mov r1, #0xff
	strb_ r1, RW_start
	strb_ r1, drive_reset
	mov r1, #-1
	strb_ r1, sound_startup_timer
	b 2f

1:
	mov r1, #0
	strb_ r1, drive_reset
	ldrb_ r1, sound_startup_flag
	ands r1, r1, r1
	bne 2f
	@MechanicalSound( MECHANICAL_SOUND_MOTOR_ON );
	mov r1, #0xFF
	strb_ r1, sound_startup_flag
	mov r1, #40
	str_ r1, sound_startup_timer
	mov r1, #60*7
	str_ r1, sound_startup_timer

2:
	ands r1, r0, #1
	strb_ r1, disk_motor_mode
	bne 0f
	ldr_ r1, sound_seekend_timer
	tst r1, #0x80000000
	moveq r1, #-1
	streq_ r1, sound_seekend_timer
	@MechanicalSound( MECHANICAL_SOUND_MOTOR_OFF );

0:
	tst r0, #8
	b mirror2V_
@-------------
w26:
	bx lr

@-------------
writel:
	ldr r2, =NES_DRAM - 0x6000
	strb r0, [r2, addy]
	bx lr

@-------------
write:
	ldr r2, =NES_DRAM - 0x6000
	strb r0, [r2, addy]
	bx lr

@-------------
hsync:
	ldrb_ r0, irq_enable
	ands r0, r0, r0
	beq checktr

	ldr_ r1, irq_counter
	ldrb_ r2, irq_type
	ands r2, r2, r2
	subeq r1, r1, #114

	tst r1, #0x80000000
	str_ r1, irq_counter
	beq 0f

	ldr_ r0, irq_latch
	add r1, r1, r0
	str_ r1, irq_counter

	ldrb_ r0, irq_occur
	ands r0, r0, r0
	bne 0f

	mov r0, #0xff
	strb_ r0, irq_occur

	ldrb_ r0, irq_repeat
	ands r0, r0, r0
	streqb_ r0, irq_enable

	b CheckI

0:
	ldr_ r1, irq_counter
	ldrb_ r2, irq_type
	ands r2, r2, r2
	subne r1, r1, #114
	strne_ r1, irq_counter

checktr:
	ldrb_ r0, irq_transfer
	ands r0, r0, r0
	bne CheckI
hk:
	fetch 0


@-------------
frameend:
	ldr_ r1, disk
	ands r1, r1, r1
	beq b1

	ldrb_ r1, disk_eject
	ands r1, r1, r1
	beq a0

	ldrb_ r1, disk_mount_count
	cmp r1, #121
	movcs r0, #0
	strcsb_ r0, disk_eject
	addcc r1, r1, #1
	strccb_ r1, disk_mount_count

a0:
	ldr_ r1, sound_startup_timer
	subs r1, r1, #1
	str_ r1, sound_startup_timer
	@blcc MechanicalSound( MECHANICAL_SOUND_BOOT );

	ldr_ r1, sound_seekend_timer
	subs r1, r1, #1
	str_ r1, sound_seekend_timer
	@blcc MechanicalSound( MECHANICAL_SOUND_MOTOR_OFF );
	@MechanicalSound( MECHANICAL_SOUND_SEEKEND );
	movcc r0, #0
	strccb_  r0, sound_startup_flag

b0:
	ldr_ r1, disk
	ands r1, r1, r1
	beq b1

	ldrb_ r1, disk_mount_count
	cmp r1, #120
	bcc c0

b1:
	ldrb_ r1, irq_transfer
	ands r1, r1, r1
	beq d0

c0:
	ldr_ r1, DiskThrottleTime
	cmp r1, #3
	movcs r2, #1
	movcc r2, #0
	str_ r2, bDiskThrottle
	ldrcc_ r1, DiskThrottleTime
	addcc r1, r1, #1
	strcc_ r1, DiskThrottleTime
	b e0

d0:
	mov r0, #0
	str_ r0, DiskThrottleTime
	str_ r0, bDiskThrottle

e0:
	@ldr_ r0, bDiskThrottle
	@b command
	bx lr

@------------------------------------
fdscmdwrite:	@called when....
	@r0 = data
	stmfd sp!,{globalptr,lr}
	ldr globalptr,=globals

excmd_insert:
	strb_ r0, disk_side
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
	str_ r3, disk_w

	mov r0, #0xFF
	strb_ r0, disk_eject
	mov r0, #0
	strb_ r0, drive_ready
	strb_ r0, disk_mount_count

	ldmfd sp!,{globalptr,pc}

excmd_eject:
	mov r0, #0
	str_ r0, disk
	str_ r0, disk_w
	strb_ r0, drive_ready
	strb_ r0, disk_mount_count
	mov r0, #0xFF
	strb_ r0, disk_eject
	strb_ r0, disk_side
	bx lr

.ltorg

@-------------------------------
.section .bss, "aw"
@NES_DRAM:			@defined in memory.s
	@.skip 0x8000
@NES_DISK:			@defined in memory.s
	@.skip 0x40000		@max for 256k
	@.skip 4
