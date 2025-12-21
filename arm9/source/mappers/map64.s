;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper64init
	.global mapper158init

	.struct mapperData
chr01:	.byte 0
chr23:	.byte 0
chr4:	.byte 0
chr5:	.byte 0
chr6:	.byte 0
chr7:	.byte 0
prg0:	.byte 0
prg1:	.byte 0

chr1:	.byte 0
chr3:	.byte 0
		.skip 5
prg2:	.byte 0

prg3:	.byte 0

cmd:	.byte 0

irq_latch:		.byte 0
irq_enable:		.byte 0
irq_reload:		.byte 0
irq_counter:	.byte 0
irq_mode:		.byte 0
				.skip 1		;@ align
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Tengen RAMBO-1
;@ Used in:
;@ Hard Drivin' (prototype)
;@ Klax
;@ Rolling Thunder
;@ Shinobi
;@ Skull and Crossbones
mapper64init:
;@----------------------------------------------------------------------------
	.word m64MappingW, m64MirrorW, m64CounterW, m64IrqEnableW
m64Init:
	stmfd sp!, {lr}
	mov r0, #0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1
	mov r0, #-2
	strb_ r0, prg2
	mov r0, #-1
	strb_ r0, prg3

	bl m64SetBankCpu

	mov r0,#0xFF
	strb_ r0,irq_latch

	adr r0,RAMBO1HSync
	str_ r0,scanlineHook

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
;@ Tengen RAMBO-1 with other mirroring
;@ Used in:
;@ Alien Syndrome
mapper158init:
;@----------------------------------------------------------------------------
	.word m64MappingW, rom_W, m64CounterW, m64IrqEnableW
	b m64Init
;@----------------------------------------------------------------------------
m64SetBankCpu:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb_ r0,prg1
	bl mapAB_
	ldrb_ r0,prg3
	bl mapEF_
	ldrb_ r1,cmd
	ldrb_ r0,prg0
	tst r1,#0x40
	beq sbc1

	bl mapCD_
	ldmfd sp!,{lr}
	ldrb_ r0,prg2
	b map89_

sbc1:
	bl map89_
	ldmfd sp!,{lr}
	ldrb_ r0,prg2
	b mapCD_

;@----------------------------------------------------------------------------
m64MappingW:		;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy,#1
	bne m64Mapping1W

m64Mapping0W:
	ldrb_ r1,cmd
	strb_ r0,cmd
	eor r1,r1,r0
	tst r1,#0x80			;@ Swap CHR A12
	beq noChrSwap
	adr_ r0,nesChrMap
	stmfd sp!,{r1,r3,r4}
	ldmia r0,{r1-r4}
	stmia r0!,{r3,r4}
	stmia r0!,{r1,r2}
	ldmfd sp!,{r1,r3,r4}
noChrSwap:
	tst r1,#0x40
	bxeq lr
	b m64SetBankCpu

m64Mapping1W:
	ldrb_ r2,cmd
	mov r2,r2,ror#4
	adrl_ r1,chr01
	strb r0,[r1,r2,lsr#28]
	ands r1,r2,#0x08
	movne r1,#4
	ldr pc,[pc,r2,lsr#26]
	nop
;@----------------------------------------------------------------------------
commandlist:	.word setChr01,setChr23,setChr4,setChr5,setChr6,setChr7,m64SetBankCpu,mapAB_
				.word cmd0x,cmd1x,void,void,void,void,void,m64SetBankCpu
;@----------------------------------------------------------------------------
setChr01:
	tst r2,#0x2		;@ K=1?
	bne chr1k
	b chr2k1k
setChr23:
	eor r1,r1,#2
	tst r2,#0x2		;@ K=1?
	bne chr1k
	b chr2k1k
setChr4:
	eor r1,r1,#4
	b chr1k
setChr5:
	eor r1,r1,#5
	b chr1k
setChr6:
	eor r1,r1,#6
	b chr1k
setChr7:
	eor r1,r1,#7
	b chr1k
cmd0x:			;@ 0400-07ff
	tst r2,#0x2		;@ K=1?
	bxeq lr
	eor r1,r1,#1
	b chr1k
cmd1x:			;@ 0c00-0fff
	tst r2,#0x2		;@ K=1?
	bxeq lr
	eor r1,r1,#3
	b chr1k

;@----------------------------------------------------------------------------
m64MirrorW:			;@ A000-BFFF
;@----------------------------------------------------------------------------
	tst addy,#1
	bxne lr
	tst r0,#1
	b mirror2V_
;@----------------------------------------------------------------------------
m64CounterW:		;@ C000-DFFF
;@----------------------------------------------------------------------------
	tst addy,#1
	streqb_ r0,irq_latch
	strneb_ r0,irq_mode
	ldrneb_ r0,irq_latch
	strneb_ r0,irq_counter
	bx lr
;@----------------------------------------------------------------------------
m64IrqEnableW:		;@ E000-E001
;@----------------------------------------------------------------------------
	ands r0,addy,#1
	strb_ r0,irq_enable
	beq rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
RAMBO1HSync:
;@----------------------------------------------------------------------------
	ldr_ r0,scanline
	cmp r0,#240		;@ Not rendering?
	bxhi lr			;@ Bye..

	ldrb_ r1,irq_mode
	tst r1,#1
	moveq r1,#1			;@ Scanline mode
	movne r1,#28		;@ Cycle mode (cpu cyles / 4)
	ldrb_ r0,irq_counter
	subs r0,r0,r1
	ldrmib_ r0,irq_latch
	strb_ r0,irq_counter
	bxpl lr

	ldrb_ r0,irq_enable
	cmp r0,#0
	bne rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
