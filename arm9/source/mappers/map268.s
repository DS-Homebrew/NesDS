;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper224init
	.global mapper268init

	.struct mmc3Extra
prgMask:	.byte 0
outerPRG:	.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3 with outer banking
mapper268init:
;@----------------------------------------------------------------------------
	.word write8, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW

	// Set Depending on sub mapper.
	ldrb_ r0,subMapper
	movs r0,r0,lsr#1
	teq r0,#1
	adreq r1,write7
	streq_ r1,m6502WriteTbl+12
	beq sub23

	adrcs r1,write5
	adrcc r1,write6
	strcs_ r1,rp2A03MemWrite
	strcc_ r1,m6502WriteTbl+12
sub23:
	stmfd sp!,{lr}
	bl mmc3Init
	ldmfd sp!,{lr}
	mov r0,#0
	b register1_0
;@----------------------------------------------------------------------------
;@ MMC3 with outer banking, subset of mapper 268
mapper224init:
;@----------------------------------------------------------------------------
	.word write8, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	adr r0,write5
	str_ r0,rp2A03MemWrite

	b mmc3Init

;@----------------------------------------------------------------------------
write5:		;@ ($5000-$5FFF)
;@----------------------------------------------------------------------------
	cmp addy,#0x5000
	bcc empty_W
	b doBanking
;@----------------------------------------------------------------------------
write6:		;@ ($6000-$6FFF)
;@----------------------------------------------------------------------------
	cmp addy,#0x7000
	bcs empty_W
	b doBanking
;@----------------------------------------------------------------------------
write7:		;@ ($7000-$7FFF)
;@----------------------------------------------------------------------------
	cmp addy,#0x7000
	bcc empty_W
doBanking:
	ands r1,addy,#7
	beq register0_0
	cmp r1,#1
	beq register1_0
	cmp r1,#3
	beq register3
	bx lr
;@----------------------------------------------------------------------------
register0_0:				;@ Submappers 0/1/2/3
	ldrb_ r1,prgMask
	tst r0,#0x40			;@ PRG mask A17
	bic r1,r1,#0x01
	orrne r1,r1,#0x01
	strb_ r1,prgMask

	and r1,r0,#0x07			;@ PRG offset A19-A17
	and r2,r0,#0x30			;@ PRG offset A24 & A23
	orr r1,r1,r2,lsl#2
	ldrb_ r2,outerPRG
	bic r2,r2,#0xC7
	orr r2,r2,r1
	strb_ r2,outerPRG

	b updatePRG
;@----------------------------------------------------------------------------
register1_0:				;@ Submappers 0/1/6/7/10/11
	ldrb_ r1,prgMask
	bic r1,r1,#0x0E
	tst r0,#0x80			;@ PRG mask A18
	orrne r1,r1,#0x02
	tst r0,#0x40			;@ PRG mask A19
	orreq r1,r1,#0x04
	tst r0,#0x20			;@ PRG mask A20
	orreq r1,r1,#0x08
	strb_ r1,prgMask

	ldrb_ r1,outerPRG
	bic r1,r1,#0x38
	tst r0,#0x10			;@ PRG offset A20
	orrne r1,r1,#0x08
	tst r0,#0x08			;@ PRG offset A22
	orrne r1,r1,#0x20
	tst r0,#0x04			;@ PRG offset A21
	orrne r1,r1,#0x10
	strb_ r2,outerPRG

	b updatePRG
;@----------------------------------------------------------------------------
register3:
	and r1,r0,#0x90
	cmp r1,#0x80			;@ Lock out?
	bxne lr
	ldr r0,=sram_W
	str_ r0,m6502WriteTbl+12
	bx lr
;@----------------------------------------------------------------------------
updatePRG:
;@----------------------------------------------------------------------------
	ldrb_ r1,prgMask
	ldrb_ r2,outerPRG
	and r2,r2,r1

	ldrb_ r0,prg0
	bic r0,r0,r1,lsl#4	;@ PRG
	orr r0,r0,r2,lsl#4
	strb_ r0,prg0

	ldrb_ r0,prg1
	bic r0,r0,r1,lsl#4	;@ PRG
	orr r0,r0,r2,lsl#4
	strb_ r0,prg1

	mov r0,#-2
	bic r0,r0,r1,lsl#4	;@ PRG
	orr r0,r0,r2,lsl#4
	strb_ r0,prg2

	mov r0,#-1
	bic r0,r0,r1,lsl#4	;@ PRG
	orr r0,r0,r2,lsl#4
	strb_ r0,prg3

	b mmc3SetBankCpu
;@----------------------------------------------------------------------------
write8:			;@($8000-$9FFF)
;@----------------------------------------------------------------------------
	tst addy,#1
	beq mmc3Mapping0W

w8001:
	ldrb_ r1,reg0
	and r1,r1,#6
	cmp r1,#6				;@ PRG or CHR?
	ldreqb_ r1,prgMask
	ldreqb_ r2,outerPRG
	biceq r0,r0,r1,lsl#4
	andeq r2,r2,r1
	orreq r0,r0,r2,lsl#4
	b mmc3Mapping1W
