@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"

	.global mapper42init

 countdown = mapperdata+0
 rombank = mapperdata+1

@----------------------------------------------------------------------------
mapper42init:
@----------------------------------------------------------------------------
	.word chr01234567_,void,void,write3
	mov addy,lr

	ldr r1,=rom_R60			@Swap in ROM at $6000-$7FFF.
	str_ r1,readmem_tbl+12
	ldr r1,=empty_W		@ROM.
	str_ r1,writemem_tbl+12
	
	mov r0,#-1
	bl map89ABCDEF_
	
@	ldr r0,=MMC3_IRQ_Hook
@	str r0,scanlinehook

	mov r0,#0
	bl map67_IRQ_Hook

	mov pc,addy

@----------------------------------------------------------------------------
write0:		@$8000-8001
@----------------------------------------------------------------------------
@	tst addy,#3
@	movne pc,lr
	b chr01234567_
@----------------------------------------------------------------------------
write3:		@E000-E003
@----------------------------------------------------------------------------
	and r1,addy,#3
	ldr pc,[pc,r1,lsl#2]
nothing:
	mov pc,lr
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
