#ifdef __arm__

;@----------------------------------------------------------------------------
	#include "equates.h"
	#include "M6502mac.h"
;@----------------------------------------------------------------------------
	.global NSF_Run
	.global EMU_Run
	.global cpuInit
	.global CPU_reset
	.global ntsc_pal_reset

	.syntax unified
	.arm

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text, "ax"				;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
NSF_Run:
;@----------------------------------------------------------------------------
	ldr r0, =__nsfPlay
	ldr r0, [r0]
	ands r0, r0, r0
	beq noPlay

	ldr r0, =__nsfInit
	ldr r0, [r0]
	ands r0, r0, r0
	beq noInit

	mov r0, #0
	mov r1, m6502zpage
	ldr r2, =0x2000/4
	bl filler

	ldr r1, =nsfExtraChipSelect
	ldr r1, [r1]
	tst r1, #4
	bne 0f

	ldr r1, =wram
	ldr r2, =0x2000/4
	bl filler
0:
	ldr addy, =0x4015
	mov r0, #0xf
	bl soundwrite
		ldr addy, =0x4017
		mov r0, #0xc0
		bl soundwrite
		ldr addy, =0x4080
		mov r0, #0x80
		bl soundwrite
		ldr addy, =0x408a
		mov r0, #0xe8
		bl soundwrite

	ldr m6502pc, =0x4710
	encodePC
	ldr r0, =__nsfSongNo
	ldr m6502a, [r0]
	orr m6502a, m6502a, m6502a, lsl#24
	ldr r0, =__nsfSongMode
	ldr m6502x, [r0]
	mov m6502y, #0
	mov r0,#1
	str_ r0, m6502RegSP
	orr cycles,#CYC_I

	mov r0, #0
	ldr r1, =__nsfInit
	str r0, [r1]

	ldr_ r0,cyclesPerScanline
	mov r0,r0, lsl#14
	bl rp2A03RunXCycles
	b nsfOut

noInit:
	ldr_ r1,m6502LastBank
	sub m6502pc,m6502pc,r1
	cmp m6502pc, #0x4700
	bne nsfRun

	ldr m6502pc, =0x4720
	encodePC
	mov r0,#1
	str_ r0, m6502RegSP
	mov m6502a, #0
	b nsfRun

noPlay:
	ldr m6502pc, =0x4700
	encodePC
	mov r0,#1
	str_ r0, m6502RegSP
nsfRun:
	ldr_ r0,cyclesPerScanline
	mov r0,r0, lsl#8
	bl rp2A03RunXCycles
nsfOut:
	adr_ r2,m6502Regs
	stmia r2,{m6502nz-m6502pc}	;@ save 6502 state
	bl updatesound
	ldmfd sp!,{r4-r11,pc}

;@----------------------------------------------------------------------------
EMU_Run:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr globalptr,=globals
	adr_ r0,m6502Regs
	ldmia r0,{m6502nz-m6502pc,m6502zpage}	;@ restore 6502 state

	;@--- beginning of EMU_Run
	ldr_ r0,cyclesPerScanline
;@----------------------------------------------------------------------------
nesFrameLoop:
;@----------------------------------------------------------------------------
	bl rp2A03RunXCycles
	bl ppuDoScanline
	cmp r0,#0
	bne nesFrameLoop
	@--- end of EMU_Run

	adr_ r0,m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ save 6502 state

	bl refreshNESjoypads

	bl updatesound

	ldmfd sp!,{r4-r11,pc}

;@----------------------------------------------------------------------------
cpuInit:
;@----------------------------------------------------------------------------
	ldr r0,=rp2A03
	b rp2A03Init
;@----------------------------------------------------------------------------
CPU_reset:	;@ Called by loadcart (r0-r9 are free to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldrb_ r1,emuFlags
	ands r1,#PALTIMING
	movne r1,#REV_RP2A07
	ldr r0,=rp2A03
	bl rp2A03Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
ntsc_pal_reset:			;@ r0 = emuFlags
;@----------------------------------------------------------------------------
;@---NTSC/PAL
	stmfd sp!,{r0,globalptr,lr}
	ldr globalptr,=globals

	ands r0,#PALTIMING
	movne r0,#REV_RP2A07
	bl rp2A03SetRevision
	ldmfd sp!,{r0}

	ands r0,#PALTIMING
	movne r0,#REV_RP2C07
	bl rp2C02SetRevision

	ldmfd sp!,{globalptr,lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
