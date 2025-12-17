;@----------------------------------------------------------------------------
	#include "mmc1.i"
;@----------------------------------------------------------------------------
	.global mapper105init

	.struct mmc1Extra
counter:	.word 0

	dip = 0xb		@ DIPswitch, for playtime. 6min default.
					@ 0x0 - 9.695
					@ 0x1 - 9.318
					@ 0x2 - 9.070
					@ 0x3 - 8.756
					@ 0x4 - 8.444
					@ 0x5 - 8.131
					@ 0x6 - 7.818
					@ 0x7 - 7.505
					@ 0x8 - 7.193
					@ 0x9 - 6.880
					@ 0xa - 6.567
					@ 0xb - 6.254
					@ 0xc - 5.942
					@ 0xd - 5.629
					@ 0xe - 5.316
					@ 0xf - 5.001
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Board with MMC1 plus timers
;@ Used in:
;@ Nintendo World Championships
mapper105init:
;@----------------------------------------------------------------------------
	.word mmc1Write0,write1,mmc1Write2,mmc1Write3
	stmfd sp!,{lr}

	bl mmc1Init

	adr r0,romSwitch
	str_ r0,cpuSwitch
	adr r0,hook
	str_ r0,scanlineHook

	mov r0,#0
	bl map89ABCDEF_

	ldmfd sp!, {pc}
;@----------------------------------------------------------------------------
write1:		;@ ($A000-$BFFF)
;@----------------------------------------------------------------------------
	adr addy,w1
	b mmc1WriteLatch
w1:
	strb_ r0,reg1
	@----
	tst r0,#0x10

	stmfd sp!, {r0,lr}
	mov r0,#0
	strne_ r0,counter
	blne rp2A03SetIRQPin
	ldmfd sp!, {r0,lr}

	b romSwitch
;@----------------------------------------------------------------------------
romSwitch:
;@----------------------------------------------------------------------------
	ldrb_ r0,reg1
	tst r0,#0x8
	beq rs2
	ldrb_ r0,reg3
	orr r0,r0,#0x8

	ldrb_ r1,reg0
	tst r1,#0x08
	beq rs1
					;@ Switch 16k / high 128k:
	stmfd sp!,{lr}
	tst r1,#0x04
	beq rs0

	bl map89AB_		;@ Map low bank
	ldmfd sp!,{lr}
	mov r0,#0x0f
	b mapCDEF_		;@ Hardwired high bank
rs0:
	bl mapCDEF_		;@ Map high bank
	ldmfd sp!,{lr}
	mov r0,#0x08
	b map89AB_		;@ Hardwired low bank
rs2:				;@ Switch 32k / low 128k:
	and r0,r0,#0x6
rs1:				;@ Switch 32k:
	mov r0,r0,lsr#1
	b map89ABCDEF_
;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r1,reg1
	tst r1,#0x10
	bxne lr

	ldr_ r0,counter
	add r0,r0,#113			;@ Cycles per scanline
	str_ r0,counter
	mov r0,r0,lsr#25
	cmp r0,#0x10|dip		;@ DIP switch
	bxne lr

	mov r0,#1
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
