;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mmc3Init
	.global mmc3SetBankPpu
	.global mmc3SetBankCpu
	.global mmc3MappingW
	.global mmc3Mapping0W
	.global mmc3Mapping1W
	.global mmc3MirrorW
	.global mmc3CounterW
	.global mmc3IrqEnableW
	.global mmc3HSync

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3
mmc3Init:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}
	mov r0, #0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1
	mov r0, #-2
	strb_ r0, prg2
	mov r0, #-1
	strb_ r0, prg3

	bl mmc3SetBankCpu

	mov r0,#0
	strb_ r0,chr01
	mov r0,#2
	strb_ r0,chr23
	mov r0,#4
	strb_ r0,chr4
	mov r0,#5
	strb_ r0,chr5
	mov r0,#6
	strb_ r0,chr6
	mov r0,#7
	strb_ r0,chr7

	bl mmc3SetBankPpu

	mov r0,#0xFF
	strb_ r0,irq_latch

	ldr r0,=mmc3HSync
	str_ r0,scanlineHook

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
mmc3SetBankCpu:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb_ r0,prg1
	bl mapAB_
	ldrb_ r0,prg3
	bl mapEF_
	ldrb_ r1,reg0
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
mmc3SetBankPpu:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f

	mov r1,#0
	ldrb_ r0,chr4
	bl chr1k
	mov r1,#1
	ldrb_ r0,chr5
	bl chr1k
	mov r1,#2
	ldrb_ r0,chr6
	bl chr1k
	mov r1,#3
	ldrb_ r0,chr7
	bl chr1k
	mov r1,#4
	ldrb_ r0,chr01
	bl chr2k1k
	ldmfd sp!,{lr}
	mov r1,#6
	ldrb_ r0,chr23
	b chr2k1k

0:
	mov r1,#0
	ldrb_ r0,chr01
	bl chr2k1k
	mov r1,#2
	ldrb_ r0,chr23
	bl chr2k1k
	mov r1,#4
	ldrb_ r0,chr4
	bl chr1k
	mov r1,#5
	ldrb_ r0,chr5
	bl chr1k
	mov r1,#6
	ldrb_ r0,chr6
	bl chr1k
	ldmfd sp!,{lr}
	mov r1,#7
	ldrb_ r0,chr7
	b chr1k

;@----------------------------------------------------------------------------
mmc3MappingW:		;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy,#1
	bne mmc3Mapping1W

mmc3Mapping0W:
	ldrb_ r1,reg0
	strb_ r0,reg0
	eor r1,r1,r0
	tst r1,#0xC0
	bxeq lr
	stmfd sp!,{lr}
	bl mmc3SetBankCpu
	ldmfd sp!,{lr}
	b mmc3SetBankPpu

mmc3Mapping1W:
	strb_ r0,reg1
	ldrb_ r2,reg0
	mov r2,r2,ror#3
	adrl_ r1,chr01
	strb r0,[r1,r2,lsr#29]
	ands r1,r2,#0x10
	movne r1,#4
	add pc,pc,r2,lsr#26
	nop
setChr01:
	b chr2k1k
	nop
setChr23:
	eor r1,r1,#2
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
setPrg0:
	b mmc3SetBankCpu
	nop
setPrg1:
	b mapAB_

;@----------------------------------------------------------------------------
mmc3MirrorW:		;@ A000-BFFF
;@----------------------------------------------------------------------------
	tst addy, #1
	bne wa001

	strb_ r0, reg2
	ldrb_ r1, cartFlags
	tst r1, #SCREEN4
	bxne lr
	tst r0, #1
	b mirror2V_

wa001:				@ WRAM enable
	strb_ r0, reg3
	bx lr

;@----------------------------------------------------------------------------
mmc3CounterW:		;@ C000-DFFF
;@----------------------------------------------------------------------------
	tst addy, #1

	streqb_ r0, irq_latch
	bxeq lr

	mov r0, #1
	strb_ r0, irq_reload
	bx lr

;@----------------------------------------------------------------------------
mmc3IrqEnableW:		;@ E000-FFFF
;@----------------------------------------------------------------------------
	ands r0, addy, #1
	strb_ r0, irq_enable
	beq rp2A03SetIRQPin
	bx lr

;@----------------------------------------------------------------------------
mmc3HSync:			;@ Sharp version, IRQ as long as counter is 0
;@----------------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1
	cmp r0, #240
	bxcs lr
	tst r1, #0x18
	bxeq lr

	ldrb_ r0, irq_reload
	mov r1,#0
	strb_ r1, irq_reload
	ldrb_ r2, irq_counter
	cmp r2,#0				;@ Is counter 0?
	cmpne r0,#1				;@ Or forced reload?
	ldreqb_ r2, irq_latch	;@ Load latch to counter
	subne r2, r2, #1
	strb_ r2, irq_counter
	cmp r2,#0				;@ Is counter 0?
	bxne lr

	ldrb_ r0, irq_enable
	cmp r0,#0
	bxeq lr
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
mmc3HSyncAlt:		;@ NEC version, IRQ only on counter n->0 transition
;@----------------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1
	cmp r0, #240
	bxcs lr
	tst r1, #0x18
	bxeq lr

	ldrb_ r0, irq_reload
	mov r1,#0
	strb_ r1, irq_reload
	ldrb_ r2, irq_counter
	movs r1,r2				;@ Keep old counter in r1. Is counter 0?
	cmpne r0,#1				;@ Or forced reload?
	ldreqb_ r2, irq_latch	;@ Load latch to counter
	subne r2, r2, #1
	strb_ r2, irq_counter
	cmp r2,r1				;@ Is old count == new count, no IRQ
	bxeq lr
	cmp r2,#0				;@ Is counter 0?
	bxne lr

	ldrb_ r0, irq_enable
	cmp r0,#0
	bxeq lr
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
