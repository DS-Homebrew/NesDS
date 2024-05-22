@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"

	.global mapper42init

 countdown = mapperData+0
 rombank = mapperData+1

@----------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper42init:
@----------------------------------------------------------------------------
	.word chr01234567_,void,void,write3
	mov addy,lr

	ldr r1,=mem_R60			@Swap in ROM at $6000-$7FFF.
	str_ r1,m6502ReadTbl+12
	ldr r1,=empty_W		@ROM.
	str_ r1,m6502WriteTbl+12

	mov r0,#-1
	bl map89ABCDEF_

@	ldr r0,=MMC3_IRQ_Hook
@	str r0,scanlineHook

	mov r0,#0
	bl map67_IRQ_Hook

	bx addy

@----------------------------------------------------------------------------
write0:		@$8000-8001
@----------------------------------------------------------------------------
@	tst addy,#3
@	bxne lr
	b chr01234567_
@----------------------------------------------------------------------------
write3:		@E000-E003
@----------------------------------------------------------------------------
	and r1,addy,#3
	ldr pc,[pc,r1,lsl#2]
nothing:
	bx lr
@----------------------------------------------------------------------------
commandlist:	.word map67_,cmd1,nothing,nothing
cmd0:
@	strb r1,rombank
@	and r0,r0,#0xF
	b map67_IRQ_Hook
cmd1:
	tst r0,#0x08
	beq mirror2H_
	b mirror2V_
cmd2:
cmd3:
	@.end
