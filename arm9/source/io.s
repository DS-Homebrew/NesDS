@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global IO_reset
	.global IO_R
	.global IO_W
	.global joypad_write_ptr
	.global joy0_W
	.global joyflags
	.global refreshNESjoypads
	.global spriteY_lookup
	.global spriteY_lookup2
	.global joystate
	.global nifi_keys
	.global ad_scale
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
IO_reset:
@---------------------------------------------------------------------------------
	mov pc,lr
@---------------------------------------------------------------------------------
IO_R:		@I/O read
@read a IO register for NES
@---------------------------------------------------------------------------------
	sub r2,addy,#0x4000	@minus basic io address 0x4000
	subs r2,r2,#0x15	
	bmi empty_R		@no readable io register lower than 0x4015
	cmp r2,#3
	ldrmi pc,[pc,r2,lsl#2]	@go (0x4000 + (r2 - 15) * 4)
	mov pc, lr
	@b FDS_R
io_read_tbl:
	.word _4015r	@4015 (sound)
	.word joy0_R	@4016: controller 1
	.word joy1_R	@4017: controller 2
FDS_R:
	mov r0, #0
	mov pc, lr
@---------------------------------------------------------------------------------
IO_W:		@I/O write
@write a IO register for NES
@---------------------------------------------------------------------------------
	sub r2,addy,#0x4000
	cmp r2,#0x18	@no writeable io register greater than 0x4018
	ldrmi pc,[pc,r2,lsl#2]
	b FDS_W
io_write_tbl:
	.word soundwrite	@pAPU Pulse #1 Control Register 0x4000
	.word soundwrite	@pAPU Pulse #1 Ramp Control Register 0x4001
	.word soundwrite	@pAPU Pulse #1 Fine Tune (FT) Register 0x4002
	.word soundwrite	@pAPU Pulse #1 Coarse Tune (CT) Register 0x4003
	.word soundwrite	@pAPU Pulse #2 Control Register 0x4004
	.word soundwrite	@pAPU Pulse #2 Ramp Control Register 0x4005
	.word soundwrite	@pAPU Pulse #2 Fine Tune Register 0x4006
	.word soundwrite	@pAPU Pulse #2 Coarse Tune Register 0x4007
	.word soundwrite	@pAPU Triangle Control Register #1 0x4008
	.word soundwrite	@pAPU Triangle Control Register #2 0x4009
	.word soundwrite	@pAPU Triangle Frequency Register #1 0x400a
	.word soundwrite	@pAPU Triangle Frequency Register #2 0x400b
	.word soundwrite	@pAPU Noise Control Register #1 0x400c
	.word soundwrite	@Unused
	.word soundwrite	@pAPU Noise Frequency Register #1 0x400e
	.word soundwrite	@pAPU Noise Frequency Register #2 0x400f
	.word soundwrite	@pAPU Delta Modulation Control Register 0x4010
	.word soundwrite	@pAPU Delta Modulation D/A Register 0x4011
	.word soundwrite	@pAPU Delta Modulation Address Register 0x4012
	.word soundwrite	@pAPU Delta Modulation Data Length Register 0x4013
	.word dma_W		@$4014: Sprite DMA transfer
	.word soundwrite
joypad_write_ptr:
	.word joy0_W	@$4016: Joypad 0 write
	.word void		@$4017: ?
@----
FDS_W:
	cmp r2, #0x40
	bcc empty_W
	cmp r2, #0x90
	bcs empty_W
	b soundwrite
@---------------------------------------------------------------------------------
dma_W:	@(4014)		sprite DMA transfer
@shell we edit?
@---------------------------------------------------------------------------------
PRIORITY = 0x000	@0x800=AGB OBJ priority 2/3

	ldr r1,=3*512*CYCLE		@ was 512...	514 is the right number...
	sub cycles,cycles,r1
	stmfd sp!,{r3-r8,lr}

	and r1,r0,#0xe0
	adr_ addy,memmap_tbl
	ldr addy,[addy,r1,lsr#3]
	and r0,r0,#0xff
	add addy,addy,r0,lsl#8	@addy=DMA source

	mov r0, addy
	ldr r1, =NES_SPRAM
	mov r7, #240/5/4
cpsp:
	ldmia r0!, {r2-r6}
	stmia r1!, {r2-r6}
	subs r7, r7, #1
	bne cpsp
	ldmia r0!, {r2-r5}
	stmia r1!, {r2-r5}

	ldr_ r0, emuflags
	tst r0, #0x40 + SOFTRENDER		@sprite render type or pure software
	beq 0f
	ldmfd sp!,{r3-r8,pc}
0:
	ldr_ r0,emuflags  		@r7,8=priority flags for scaling type
	tst r0,#ALPHALERP
	moveq r7,#0x00200000
	movne r7,#0
	eor r8,r7,#0x00200000
	
	ldr r2,=NDS_OAM
dm0:
	adr r5,spriteY_lookup
	
	ldr r0, =ad_scale
	ldr r0, [r0]
	and r0, r0, #0x1F000
	cmp r0, #(0x14 << 12)
	addcc r5, r5, #1
	add r5, r5, #1

	ldrb_ r0,ppuctrl0frame	@8x16?
	tst r0,#0x20
	bne dm4
@- - - - - - - - - - - - - 8x8 size
							@get sprite0 hit pos:
	tst r0,#0x08			@CHR base? (0000/1000)
	moveq r4,#0+PRIORITY	@r4=CHR set+AGB priority
	movne r4,#0x100+PRIORITY
	ldrb r0,[addy,#1]		@sprite tile#
	ldr r1,=NDS_OBJVRAM
	addne r1,r1,#0x2000
	add r0,r1,r0,lsl#5		@r0=VRAM base+tile*32
	ldr r1,[r0]				@I dont really give a shit about Y flipping at the moment
	cmp r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	and r0,r0,#31
	ldrb r1,[addy]			@r1=sprite0 Y
	add r1,r1,#1
	add r1,r1,r0,lsr#2
@	moveq r1,#512			@blank tile=no hit
	cmp r1,#239
	movhi r1,#512			@no hit if Y>239
	str_ r1,sprite0y
@	ldrb r1,[addy,#3]		@r1=sprite0 x
@	strb r1,sprite0x

dm11:
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm10			@skip if sprite Y>239
	ldrb r0,[r5,r0]			@r0=scaled y

	mov r1,r3,lsr#24
	orr r0,r0,r1,lsl#16	@sprite x
	
	and r1,r3,#0x00c00000	@flip
	orr r0,r0,r1,lsl#6

	and r1,r3,r7		@priority
	orr r0,r0,r1,lsr#11		@Set Transp OBJ. (for non-alpha)

	str r0,[r2],#4			@store OBJ Atr 0,1

	and r1,r3,#0x0000ff00		@tile#
	and r0,r3,#0x00030000		@color
	orr r0,r1,r0,lsl#4
	orr r0,r4,r0,lsr#8		@tileset

	tst r3,r8
	orrne r0,r0,#0x0400		@priority (for alpha)

	strh r0,[r2],#4			@store OBJ Atr 2
dm9:
	tst addy,#0xff
	bne dm11
	mov r0, #0x200
	str r0, [r2]			@hide the sprite 65 of NDS, which was used by per-line type
	ldmfd sp!,{r3-r8,pc}
dm10:
	mov r0,#0x2a0			@double, y=160
	str r0,[r2],#8
	b dm9

dm4:	@- - - - - - - - - - - - - 8x16 size
				@check sprite hit:
	ldrb r0,[addy,#1]		@sprite tile#
	movs r0,r0,lsr#1
	orrcs r0,r0,#0x80
	ldr r1,=NDS_OBJVRAM
	add r0,r1,r0,lsl#6
	ldr r1,[r0]
	cmp r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	and r0,r0,#63
	ldrb r1,[addy]			@r1=sprite0 Y
	add r1,r1,#1
	add r1,r1,r0,lsr#2
@	moveq r1,#512			@blank tile=no hit
	cmp r1,#239
	movhi r1,#512			@no hit if Y>239
	str_ r1,sprite0y
@	ldrb r1,[addy,#3]		@r1=sprite0 x
@	strb r1,sprite0x

	mov r4,#PRIORITY
dm12:
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm13				@skip if sprite Y>239
	ldrb r0,[r5,r0]				@r0=scaled y
		
	mov r1,r3,lsr#24
	orr r0,r0,r1,lsl#16	@sprite x

	and r1,r3,#0x00c00000	@flip
	orr r0,r0,r1,lsl#6

	and r1,r3,r7		@priority
	orr r0,r0,r1,lsr#11		@Set Transp OBJ. (for non-alpha)

	orr r0,r0,#0x8000		@8x16
	str r0,[r2],#4			@store OBJ Atr 0,1

	and r1,r3,#0x0000ff00	@tile#
	movs r0,r1,lsr#9
	orrcs r0,r0,#0x80
	orr r0,r4,r0,lsl#1		@priority, tile#*2
	and r1,r3,#0x00030000	@color
	orr r0,r0,r1,lsr#4

	tst r3,r8
	orrne r0,r0,#0x0400		@priority (for alpha)

	strh r0,[r2],#4			@store OBJ Atr 2
dm14:
	tst addy,#0xff
	bne dm12
	mov r0, #0x200
	str r0, [r2]			@hide the sprite 65 of NDS, which was used by per-line type
	ldmfd sp!,{r3-r8,pc}
dm13:
	mov r0,#0x2a0			@double, y=160
	str r0,[r2],#8
	b dm14
	
spriteY_lookup: .skip 512
spriteY_lookup2: .skip 512
@---------------------------------------------------------------------------------
refreshNESjoypads:	@call every frame
@used to refresh joypad button status
@---------------------------------------------------------------------------------
	ldr r2, =nifi_stat
	ldr r2, [r2]
	cmp r2, #5
	bcs multi_nifi

	ldr r1,=IPC_KEYS		@read the NDS button status
	ldr r1,[r1]

	@-> R L D U St Sl B A

	ldr r2,joyflags
	mov r0,#0

	tst r2,#B_A_SWAP		@swap buttons?
	bne rj0
		tst r1,#KEY_B
		orrne r0,r0,#1
		tst r2,#AUTOFIRE	@auto?
		tstne r1,#KEY_A
		orrne r0,r0,#1	

		tst r1,#KEY_Y
		orrne r0,r0,#2
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		orrne r0,r0,#2
	b rj1
rj0:
		tst r1,#KEY_A
		orrne r0,r0,#1
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		orrne r0,r0,#1	

		tst r1,#KEY_B
		orrne r0,r0,#2
		tst r2,#AUTOFIRE
		tstne r1,#KEY_Y
		orrne r0,r0,#2
rj1:
	tst r1,#KEY_SELECT
	orrne r0,r0,#4
	tst r1,#KEY_START
	orrne r0,r0,#8
	tst r1,#KEY_UP
	orrne r0,r0,#16
	tst r1,#KEY_DOWN
	orrne r0,r0,#32
	tst r1,#KEY_LEFT
	orrne r0,r0,#64
	tst r1,#KEY_RIGHT
	orrne r0,r0,#128

	tst r2,#P1_ENABLE
	orrne r2,r2,r0		@refresh joy0state
	tst r2,#P2_ENABLE
	orrne r2,r2,r0,lsl#8	@refresh joy1state
	str r2,joystate		

	b af_fresh

joyflags:	.word P1_ENABLE	@d0-7=pad0, d8-15=pad1, others=flags

joystate:       
joy0state: .byte 0
joy1state: .byte 0
joy2state: .byte 0       
joy3state: .byte 0      
joy0serial: .word 0
joy1serial: .word 0
@nrplayers DCD 0	@Number of players in multilink.
@---------------------------------------------------------------------------------
joy0_W:		@4016
@writing operation to reset/clear joypad status.
@---------------------------------------------------------------------------------
	tst r0,#1		@0 for clear; 1 for reset
	movne pc,lr
	@ldr r2,nrplayers
	@cmp r2,#3
	mov r2,#-1

	ldrb r0,joy0state
	@ldrb r1,joy2state
	@orr r0,r0,r1,lsl#8
	orr r0,r0,r2,lsl#8	@for normal joypads.
	@orrpl r0,r0,#0x00080000	@4player adapter
	str r0,joy0serial

	ldrb r0,joy1state
	@ldrb r1,joy3state
	@orr r0,r0,r1,lsl#8
	orr r0,r0,r2,lsl#8	@for normal joypads.
	@orrpl r0,r0,#0x00040000	@4player adapter
	str r0,joy1serial
	mov pc,lr
@---------------------------------------------------------------------------------
joy0_R:		@4016
@---------------------------------------------------------------------------------
	ldr r0,joy0serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy0serial

	ldrb_ r1,cartflags
	tst r1,#VS
	orreq r0,r0,#0x40
	moveq pc,lr

	ldrb r1,joy0state
	tst r1,#8		@start=coin (VS)
	orrne r0,r0,#0x40

	ldr_ r1, emuflags
	tst r1, #MICBIT
	bic r1, #MICBIT
	str_ r1, emuflags
	orrne r0, r0, #0x4

	mov pc,lr
@---------------------------------------------------------------------------------
joy1_R:		@4017
@---------------------------------------------------------------------------------
	ldr r0,joy1serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy1serial

	ldr_ r1, emuflags
	tst r1, #LIGHTGUN
	beq 0f

	ldr r1, =IPC_KEYS
	ldr r2, [r1]
	ands r2, r2, #KEY_TOUCH
	orrne r0, r0, #0x10

	ldr r2, =renderdata

	ldr r1, =IPC_TOUCH_X
	ldrh r1, [r1]

	add r2, r2, r1

	ldr_ r1, lighty

	add r2, r2, r1, lsl#8		@r1 = renderdata
	ldrb r2, [r2]

	adr r1, bright
	sub r2, r2, #0xC0
	ldrb r2, [r1, r2]
	ands r2, r2, r2
	orreq r0, r0, #8

0:
	ldrb_ r1,cartflags 
	tst r1,#VS
	orrne r0,r0,#0xf8	@VS dip switches

	mov pc,lr
@------
bright:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 
	.byte 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0 
@---------------------------------------------------------------------------------
multi_nifi:
	ldr r1,=nifi_keys		@read the NDS button status
	ldr r1,[r1]

	@-> R L D U St Sl B A

	ldr r2,joyflags
	mov r0,#0

	tst r2,#B_A_SWAP		@swap buttons?
	bne rj2
		tst r1,#KEY_B
		orrne r0,r0,#1
		tst r2,#AUTOFIRE	@auto?
		tstne r1,#KEY_A
		orrne r0,r0,#1	

		tst r1,#KEY_Y
		orrne r0,r0,#2
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		orrne r0,r0,#2
	b rj3
rj2:
		tst r1,#KEY_A
		orrne r0,r0,#1
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		orrne r0,r0,#1	

		tst r1,#KEY_B
		orrne r0,r0,#2
		tst r2,#AUTOFIRE
		tstne r1,#KEY_Y
		orrne r0,r0,#2
rj3:
	tst r1,#KEY_SELECT
	orrne r0,r0,#4
	tst r1,#KEY_START
	orrne r0,r0,#8	

	tst r1,#KEY_UP
	orrne r0,r0,#16
	tst r1,#KEY_DOWN
	orrne r0,r0,#32
	tst r1,#KEY_LEFT
	orrne r0,r0,#64
	tst r1,#KEY_RIGHT
	orrne r0,r0,#128

@----
@player2
	mov r1, r1, lsr#16
	tst r2,#B_A_SWAP		@swap buttons?
	bne rj4
		tst r1,#KEY_B
		orrne r0,r0,#(1 << 8)
		tst r2,#AUTOFIRE	@auto?
		tstne r1,#KEY_A
		eorne r0,r0,#(1 << 8)	

		tst r1,#KEY_Y
		orrne r0,r0,#(2 << 8)
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		orrne r0,r0,#(2 << 8)
	b rj5
rj4:
		tst r1,#KEY_A
		orrne r0,r0,#(1 << 8)
		tst r2,#AUTOFIRE
		tstne r1,#KEY_X
		eorne r0,r0,#(1 << 8)	

		tst r1,#KEY_B
		orrne r0,r0,#(2 << 8)
		tst r2,#AUTOFIRE
		tstne r1,#KEY_Y
		orrne r0,r0,#(1 << 8)
rj5:
	tst r1,#KEY_SELECT
	orrne r0,r0,#(4 << 8)
	tst r1,#KEY_START
	orrne r0,r0,#(8 << 8)
	tst r1,#KEY_UP
	orrne r0,r0,#(16 << 8)
	tst r1,#KEY_DOWN
	orrne r0,r0,#(32 << 8)
	tst r1,#KEY_LEFT
	orrne r0,r0,#(64 << 8)
	tst r1,#KEY_RIGHT
	orrne r0,r0,#(128 << 8)

	str r0,joystate	

	@b af_fresh

@---------------------------------
af_fresh:		@adjust the frequency of the auto-fire
	ldr r2,joyflags
	ldr_ r1, af_st
	tst r1, #0xff00
	beq aup
	sub r1, #0x100
	str_ r1, af_st
	orr r2, r2, #AUTOFIRE
	b aend
aup:
	tst r1, #0xff
	beq afresh
	sub r1, r1, #0x1
	str_ r1, af_st
	bic r2, r2, #AUTOFIRE
	b aend
afresh:
	ldr_ r1, af_start
	sub r1, #0x100
	str_ r1, af_st
	orr r2, r2, #AUTOFIRE
aend:
	@eor r2,r2,#AUTOFIRE	@toggle autofire state
	str r2,joyflags
	
	mov pc, lr
