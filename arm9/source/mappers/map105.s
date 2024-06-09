@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper105init
	counter = mapperData+0
	reg0 = mapperData+4
	reg1 = mapperData+5
	reg2 = mapperData+6
	reg3 = mapperData+7
	latch = mapperData+8
	latchbit = mapperData+9

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
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Board with MMC1 plus timers
@ Used in:
@ Nintendo World Championships
mapper105init:
@---------------------------------------------------------------------------------
	.word write0,write1,void,write3

	adr r0,hook
	str_ r0,scanlineHook

	mov r0,#0x0c	@init MMC1 regs
	strb_ r0,reg0
@	mov r0,#0x00
@	strb r0,reg1
@	strb r0,reg2
@	strb r0,reg3
@reset
	mov r0,#0
	strb_ r0,latch
	strb_ r0,latchbit

@	ldrb r0,reg0
@	orr r0,r0,#0x0c
@	strb r0,reg0

	mov r0,#0
	b map89ABCDEF_
reset:
	mov r0,#0
	strb_ r0,latch
	strb_ r0,latchbit
	bx lr
@---------------------------------------------------------------------------------
write0:		@($8000-$9FFF)
@---------------------------------------------------------------------------------
	adr addy,w0
writelatch: @-----
	tst r0,#0x80
	bne reset

	ldrb_ r2,latchbit
	ldrb_ r1,latch
	and r0,r0,#1
	orr r0,r1,r0,lsl r2

	cmp r2,#4
	mov r1,#0
	bxeq addy

	add r2,r2,#1
	strb_ r2,latchbit
	strb_ r0,latch
	bx lr
w0:@----
	strb_ r1,latch
	strb_ r1,latchbit
	strb_ r0,reg0

	mov addy,lr
	tst r0,#0x02
	bne w01

	tst r0,#0x01
	bl mirror1_
	mov lr,addy
	b romswitch
w01:
	tst r0,#0x01
	bl mirror2V_
	mov lr,addy
	b romswitch
@---------------------------------------------------------------------------------
write1:		@($A000-$BFFF)
@---------------------------------------------------------------------------------
	adr addy,w1
	b writelatch
w1:	strb_ r1,latch
	strb_ r1,latchbit
	strb_ r0,reg1
	@----
	tst r0,#0x10
	strne_ r1,counter	@#0
	b romswitch
@---------------------------------------------------------------------------------
write3:		@($E000-$FFFF)
@---------------------------------------------------------------------------------
	adr addy,w3
	b writelatch
w3:	strb_ r1,latch
	strb_ r1,latchbit
	strb_ r0,reg3
@---------------------------------------------------------------------------------
romswitch:
@---------------------------------------------------------------------------------
	ldrb_ r0,reg1
	tst r0,#0x8
	beq rs2
	ldrb_ r0,reg3
	orr r0,r0,#0x8

	ldrb_ r1,reg0
	tst r1,#0x08
	beq rs1
				@switch 16k / high 128k:
	str lr,[sp,#-4]!
	mov addy,r0
	tst r1,#0x04
	beq rs0

	bl map89AB_	@map low bank
	orr r0,addy,#0x0f
	ldr lr,[sp],#4
	b mapCDEF_	@hardwired high bank
rs0:
	bl mapCDEF_	@map high bank
	and r0,addy,#0x08
	ldr lr,[sp],#4
	b map89AB_	@hardwired low bank
rs1:				@switch 32k:
	mov r0,r0,lsr#1
	b map89ABCDEF_
rs2:				@switch 32k / low 128k:
	mov r0,r0,lsr#1
	and r0,r0,#0x3
	b map89ABCDEF_
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------

	ldrb_ r1,reg1
	tst r1,#0x10
	bne hk0

	ldr_ r0,counter
	add r0,r0,#113			@ Cycles per scanline
	str_ r0,counter
	orr r0,r0,#dip<<25		@ DIP switch
	cmp r0,#0x3e000000
	blo hk0

@	mov r1,#0
@	str r1,counter
@	b irq6502
	b CheckI
hk0:
	fetch 0
@---------------------------------------------------------------------------------
