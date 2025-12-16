;@-----------------------------------------------------------------------------
	#include "equates.h"
;@-----------------------------------------------------------------------------
	.global joystate
	.global nifi_keys
	.global __af_state
	.global __af_start

	.global IO_reset
	.global setJoyPort1
	.global refreshNESjoypads
	.global standardJoy_W
	.global fourScore_W
	.global standardJoy0_R
	.global standardJoy1_R
	.global vsJoy0_R
	.global vsJoy1_R
	.global zapper_R
	.global joyflags
;@-----------------------------------------------------------------------------
.section .text,"ax"
;@-----------------------------------------------------------------------------
IO_reset:
;@-----------------------------------------------------------------------------
	mov r0, #0
	str r0, af_state			;@ Clear autofire state

	ldr r0,=standardJoy_W		;@ $4016: Joypad 0 write
	str_ r0,rp2A03IOWrite
	ldr r0,=standardJoy0_R		;@ $4016: controller 1
	str_ r0,rp2A03IORead0
	ldr r0,=standardJoy1_R		;@ $4017: controller 2
	str_ r0,rp2A03IORead1

	bx lr

;@-----------------------------------------------------------------------------
setJoyPort1:				;@ r0=controller type, 0=standard, 1=zapper.
	.type   setJoyPort1 STT_FUNC
;@-----------------------------------------------------------------------------
	stmfd sp!,{globalptr,lr}
	ldr globalptr,=globals	@ init ptr regs

	cmp r0,#1
	ldreq r0,=zapper_R			;@ $4017: controller 2
	ldrne r0,=standardJoy1_R	;@ $4017: controller 2
	str_ r0,rp2A03IORead1
	ldmfd sp!,{globalptr,lr}
	bx lr
;@-----------------------------------------------------------------------------
refreshNESjoypads:	;@ Call every frame
;@used to refresh joypad button status
;@-----------------------------------------------------------------------------
	ldr r2, =nifi_stat
	ldr r2, [r2]
	cmp r2, #5
	bcs multi_nifi

	ldr r1,=IPC_KEYS		;@ Read the NDS button status
	ldr r1,[r1]

	@-> R L D U St Sl B A

	ldr r2,joyflags
	mov r0,#0

	tst r2,#B_A_SWAP		;@ Swap buttons?
	bne rj0
		tst r1,#KEY_B
		orrne r0,r0,#1
		tst r2,#AUTOFIRE	;@ Auto?
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
	orrne r2,r2,r0			;@ Refresh joy0state
	tst r2,#P2_ENABLE
	orrne r2,r2,r0,lsl#8	;@ Refresh joy1state
	str r2,joystate

	b af_fresh

joyflags:	.word P1_ENABLE	@d0-7=pad0, d8-15=pad1, others=flags

joystate:
joy0state: .byte 0
joy1state: .byte 0
joy2state: .byte 0
joy3state: .byte 0
outPortVal: .byte 0
			.space 3
joy0serial: .word 0
joy1serial: .word 0
@nrplayers .long 0	@Number of players in multilink.

__af_state:
af_state:		@auto fire state
	.word 0		@af_state
__af_start:
af_start:		@auto fire start
	.word 0x101	@af_start 30 fps

;@-----------------------------------------------------------------------------
standardJoy_W:					;@ 4016
;@writing operation to strobe/clear joypad status.
;@-----------------------------------------------------------------------------
	strb r0,outPortVal
	tst r0,#1				;@ 0 for clear; 1 for strobe
	bxeq lr

	ldrb r0,joy0state
	sub r0,r0,#0x100		;@ for normal joypads.
	str r0,joy0serial

	ldrb r0,joy1state
	orr r0,r0,#0x100		;@ for normal joypads.
	str r0,joy1serial
	bx lr
;@-----------------------------------------------------------------------------
fourScore_W:			;@ 4016
;@writing operation to strobe/clear joypad status.
;@-----------------------------------------------------------------------------
	strb r0,outPortVal
	tst r0,#1				;@ 0 for clear; 1 for strobe
	bxeq lr

	ldrb r0,joy0state
	ldrb r1,joy2state
	orr r0,r0,r1,lsl#8
	orr r0,r0,#0x00080000	;@ 4player adapter
	str r0,joy0serial

	ldrb r0,joy1state
	ldrb r1,joy3state
	orr r0,r0,r1,lsl#8
	orr r0,r0,#0x00040000	;@ 4player adapter
	str r0,joy1serial
	bx lr
@---------------------------------------------------------------------------------
standardJoy0_R:			;@ 4016
@---------------------------------------------------------------------------------
	ldr r0,joy0serial
	ldrb r1,outPortVal
	tst r1,#1				;@ Strobe on?
	mov r1,r0,asr#1
	and r0,r0,#1
	streq r1,joy0serial		;@ Only shift when not strobe

	orr r0,r0,#0x40			;@ Open bus value

	ldr_ r1, emuFlags
	tst r1, #MICBIT
	bic r1, #MICBIT
	str_ r1, emuFlags
	orrne r0, r0, #0x4

	bx lr
@---------------------------------------------------------------------------------
vsJoy0_R:				;@ 4016
@---------------------------------------------------------------------------------
	ldr r0,joy0serial
	ldrb r1,outPortVal
	tst r1,#1				;@ Strobe on?
	mov r1,r0,asr#1
	and r0,r0,#1
	streq r1,joy0serial		;@ Only shift when not strobe

	ldrb r1,joy0state
	tst r1,#8				;@ Start = Coin
	orrne r0,r0,#0x40

	bx lr
@---------------------------------------------------------------------------------
standardJoy1_R:			;@ 4017
@---------------------------------------------------------------------------------
	ldr r0,joy1serial
	ldrb r1,outPortVal
	tst r1,#1				;@ Strobe on?
	mov r1,r0,asr#1
	and r0,r0,#1
	streq r1,joy1serial

	orr r0,r0,#0x40			;@ Open bus value

	bx lr
@---------------------------------------------------------------------------------
vsJoy1_R:				;@ 4017
@---------------------------------------------------------------------------------
	ldr r0,joy1serial
	ldrb r1,outPortVal
	tst r1,#1				;@ Strobe on?
	mov r1,r0,asr#1
	and r0,r0,#1
	streq r1,joy1serial

	orr r0,r0,#0xf8			;@ VS dip switches

	bx lr
@---------------------------------------------------------------------------------
zapper_R:				;@ 4016/4017
@---------------------------------------------------------------------------------
	ldr r0,joy1serial
	ldrb r1,outPortVal
	tst r1,#1				;@ Strobe on?
	mov r1,r0,asr#1
	and r0,r0,#1
	streq r1,joy1serial

	ldr r1, =IPC_KEYS
	ldr r2, [r1]
	ands r2, r2, #KEY_TOUCH
	orrne r0, r0, #0x10

	ldr r2, =renderData

	ldr r1, =IPC_TOUCH_X
	ldrh r1, [r1]

	add r2, r2, r1

	ldr_ r1, lightY

	add r2, r2, r1, lsl#8		;@ r2 = renderData
	ldrb r2, [r2]

	adr r1, bright
	sub r2, r2, #0xC0
	ldrb r2, [r1, r2]
	ands r2, r2, r2
	orreq r0, r0, #8

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
