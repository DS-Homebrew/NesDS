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
	str_ r0, irq_latch
	str_ r0, reg0

	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1

	bl mmc3SetBankCpu

	mov r0, #0
	strb_ r0, chr01
	mov r0, #2
	strb_ r0, chr23
	mov r0, #4
	strb_ r0, chr4
	mov r0, #5
	strb_ r0, chr5
	mov r0, #6
	strb_ r0, chr6
	mov r0, #7
	strb_ r0, chr7

	bl mmc3SetBankPpu

	mov r0, #0xFF
	strb_ r0, irq_latch

	ldr r0,=mmc3HSync
	str_ r0,scanlineHook

	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
mmc3SetBankCpu:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1

	mov r0, #-2
	bl map89_
	ldrb_ r0, prg0
	bl mapCD_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapEF_

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapCDEF_

;@----------------------------------------------------------------------------
mmc3SetBankPpu:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f

	mov r1, #0
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr6
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr7
	bl chr1k
	mov r1, #4
	ldrb_ r0, chr01
	mov r0,r0,lsr#1
	bl chr2k
	ldmfd sp!, {lr}
	mov r1, #6
	ldrb_ r0, chr23
	mov r0,r0,lsr#1
	b chr2k

0:
	mov r1, #0
	ldrb_ r0, chr01
	mov r0,r0,lsr#1
	bl chr2k
	mov r1, #2
	ldrb_ r0, chr23
	mov r0,r0,lsr#1
	bl chr2k
	mov r1, #4
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr6
	bl chr1k
	ldmfd sp!, {lr}
	mov r1, #7
	ldrb_ r0, chr7
	b chr1k

;@----------------------------------------------------------------------------
mmc3MappingW:		;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy, #1
	bne mmc3Mapping1W

mmc3Mapping0W:
	strb_ r0, reg0
	stmfd sp!, {lr}
	bl mmc3SetBankCpu
	ldmfd sp!, {lr}
	b mmc3SetBankPpu

mmc3Mapping1W:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #7
	adrl_ r2, chr01
	strb r0, [r2, r1]
	cmp r1, #6
	bcc mmc3SetBankPpu
	b mmc3SetBankCpu

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
