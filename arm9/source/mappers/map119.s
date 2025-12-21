;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper119init

	.struct mmc3Extra
vromBase:	.word 0
vromMask:	.word 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3 on TQROM board
;@ Used in:
;@ High Speed
;@ Pin Bot
;@ Also see mapper 95, 118, 158 & 207
mapper119init:
;@----------------------------------------------------------------------------
	.word write0, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!,{lr}
	ldr_ r0,vmemBase
	str_ r0,vromBase
	ldr_ r0,vmemMask
	str_ r0,vromMask

	ldmfd sp!,{lr}
	b mmc3Init

;@----------------------------------------------------------------------------
write0:			;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy, #1
	beq mmc3Mapping0W

w8001:
	ldrb_ r2,reg0
	and r2,r2,#7
	cmp r2,#6
	bcs mmc3Mapping1W

	stmfd sp!,{r0,lr}
	tst r0,#0x40
	ldreq_ r1,vromBase
	ldrne r1,=CART_VRAM
	str_ r1,vmemBase
	ldreq_ r1,vromMask
	ldrne r1,=0x1FFF
	str_ r1,vmemMask

	ldreq r0,=void			;@ Disable chr write
	ldrne r0,=VRAM_chr		;@ Enable chr write
	ldr r1,=vram_write_tbl
	cmp r2,#1
	biceq r2,r2,#1
	addpl r2,r2,#2
	str r0,[r1,r2,lsl#2]!
	strls r0,[r1,#1]
	ldmfd sp!,{r0,lr}

	b mmc3Mapping1W
