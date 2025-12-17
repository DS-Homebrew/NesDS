;@----------------------------------------------------------------------------
	#include "mmc1.i"
;@----------------------------------------------------------------------------
	.global mmc1Init
	.global mmc1Write0
	.global mmc1Write1
	.global mmc1Write2
	.global mmc1Write3
	.global mmc1WriteLatch
	.global mmc1ACpuSwitch
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC1
mmc1Init:
;@----------------------------------------------------------------------------
	mov r0,#0x0c	;@ Init MMC1 regs
	strb_ r0,reg0
	adr r0,mmc1BCpuSwitch
	str_ r0,cpuSwitch
	bx lr

;@----------------------------------------------------------------------------
mmc1Write0:		;@ ($8000-$FFFF)
;@----------------------------------------------------------------------------
	adr addy,w0
;@--------------------------
mmc1WriteLatch:
;@--------------------------
	tst r0,#0x80
	bne mmc1Reset

	ldrb_ r2,latchBit
	ldrb_ r1,latch
	and r0,r0,#1
	orr r0,r1,r0,lsl r2

	subs r1,r2,#4
	streqb_ r1,latch
	streqb_ r1,latchBit
	bxeq addy

	add r2,r2,#1
	strb_ r2,latchBit
	strb_ r0,latch
	bx lr

;@--------------------------
mmc1Reset:
;@--------------------------
	mov r0,#0
	strb_ r0,latch
	strb_ r0,latchBit
	ldrb_ r0,reg0
	orr r0,r0,#0x0c
w0:
	ldrb_ r1,reg0
	strb_ r0,reg0
	eor r1,r1,r0

	stmfd sp!,{r1,lr}
	adr lr, w0ret
	movs r2,r0,lsl#31
	bcc mirror1_
	bcs mirror2V_
w0ret:
	ldmfd sp!,{r1,lr}
	tst r1,#0x0C
	ldrne_ pc,cpuSwitch
	tst r1,#0x10
	bne mmc1PpuSwitch
	bx lr
;@----------------------------------------------------------------------------
mmc1Write1:		;@ ($A000-$BFFF)
;@----------------------------------------------------------------------------
	adr addy,w1
	b mmc1WriteLatch
w1:
	strb_ r0,reg1
	b mmc1PpuSwitch
;@----------------------------------------------------------------------------
mmc1Write2:		;@ ($C000-$DFFF)
;@----------------------------------------------------------------------------
	adr addy,w2
	b mmc1WriteLatch
w2:
	strb_ r0,reg2
	b mmc1PpuSwitch
;@----------------------------------------------------------------------------
mmc1Write3:		;@ ($E000-$FFFF)
;@----------------------------------------------------------------------------
	adr addy,w3
	b mmc1WriteLatch
w3:
	strb_ r0,reg3
	ldr_ pc,cpuSwitch
;@----------------------------------------------------------------------------
mmc1ACpuSwitch:
;@----------------------------------------------------------------------------
	ldrb_ r0,reg3
	tst r0,#0x10
	beq mmc1BCpuSwitch

	ldrb_ r1,reg0
	tst r1,#0x08
	beq rs1
					;@ Switch 16k:
	stmfd sp!,{r0,lr}
	tst r1,#0x04
	beq rs2

	bl map89AB_		;@ Map low bank
	ldmfd sp!,{r0,lr}
	orr r0,r0,#0x07
	b mapCDEF_		;@ Hardwired high bank
rs2:
	bl mapCDEF_		;@ Map high bank
	ldmfd sp!,{r0,lr}
	and r0,#0x08
	b map89AB_		;@ Hardwired low bank

;@----------------------------------------------------------------------------
mmc1BCpuSwitch:
;@----------------------------------------------------------------------------
	ldrb_ r0,reg3

	ldrb_ r1,reg0
	tst r1,#0x08
	beq rs1
					;@ Switch 16k:
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
	mov r0,#0x00
	b map89AB_		;@ Hardwired low bank

rs1:				;@ Switch 32k:
	mov r0,r0,lsr#1
	b map89ABCDEF_
;@----------------------------------------------------------------------------
mmc1PpuSwitch:
;@----------------------------------------------------------------------------
	ldrb_ r2,reg0
	ldrb_ r0,reg1
	tst r2,#0x10
	beq chr8k

	stmfd sp!,{lr}
	bl chr0123_
	ldmfd sp!,{lr}
	ldrb_ r0,reg2
	b chr4567_

chr8k:
	mov r0,r0,lsr#1
	b chr01234567_
;@----------------------------------------------------------------------------
