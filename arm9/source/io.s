@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global IO_reset
	.global joy0_W
	.global joyflags
	.global refreshNESjoypads
	.global joystate
	.global nifi_keys
	.global __af_state
	.global __af_start
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
IO_reset:
@---------------------------------------------------------------------------------
	mov r0, #0
	str r0, af_state			@ Clear autofire state

	ldr r0,=joy0_R				@ $4016: controller 1
	str_ r0,rp2A03IORead0
	ldr r0,=joy1_R				@ $4017: controller 2
	str_ r0,rp2A03IORead1
	ldr r0,=joy0_W				@ $4016: Joypad 0 write
	str_ r0,rp2A03IOWrite

	bx lr
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
@nrplayers .long 0	@Number of players in multilink.

__af_state:
af_state:		@auto fire state
	.word 0		@af_state
__af_start:
af_start:		@auto fire start
	.word 0x101	@af_start 30 fps

@---------------------------------------------------------------------------------
joy0_W:		@4016
@writing operation to reset/clear joypad status.
@---------------------------------------------------------------------------------
	tst r0,#1		@0 for clear; 1 for reset
	bxne lr
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
	bx lr
@---------------------------------------------------------------------------------
joy0_R:		@4016
@---------------------------------------------------------------------------------
	ldr r0,joy0serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy0serial

	ldrb_ r1,cartFlags
	tst r1,#VS
	orreq r0,r0,#0x40
	bxeq lr

	ldrb r1,joy0state
	tst r1,#8		@start=coin (VS)
	orrne r0,r0,#0x40

	ldr_ r1, emuFlags
	tst r1, #MICBIT
	bic r1, #MICBIT
	str_ r1, emuFlags
	orrne r0, r0, #0x4

	bx lr
@---------------------------------------------------------------------------------
joy1_R:		@4017
@---------------------------------------------------------------------------------
	ldr r0,joy1serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy1serial

	ldr_ r1, emuFlags
	tst r1, #LIGHTGUN
	beq 0f

	ldr r1, =IPC_KEYS
	ldr r2, [r1]
	ands r2, r2, #KEY_TOUCH
	orrne r0, r0, #0x10

	ldr r2, =renderData

	ldr r1, =IPC_TOUCH_X
	ldrh r1, [r1]

	add r2, r2, r1

	ldr_ r1, lightY

	add r2, r2, r1, lsl#8		@r2 = renderData
	ldrb r2, [r2]

	adr r1, bright
	sub r2, r2, #0xC0
	ldrb r2, [r1, r2]
	ands r2, r2, r2
	orreq r0, r0, #8

0:
	ldrb_ r1,cartFlags 
	tst r1,#VS
	orrne r0,r0,#0xf8	@VS dip switches

	bx lr
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
	ldr r1, af_state
	tst r1, #0xff00
	beq aUp
	sub r1, #0x100
	str r1, af_state
	orr r2, r2, #AUTOFIRE
	b aEnd
aUp:
	tst r1, #0xff
	beq aFresh
	sub r1, r1, #0x1
	str r1, af_state
	bic r2, r2, #AUTOFIRE
	b aEnd
aFresh:
	ldr r1, af_start
	sub r1, #0x100
	str r1, af_state
	orr r2, r2, #AUTOFIRE
aEnd:
	@eor r2,r2,#AUTOFIRE	@toggle autofire state
	str r2,joyflags
	
	bx lr
