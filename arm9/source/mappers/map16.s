;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper16init
	.global __barcode
	.global __barcode_out

	.struct mapperData
patch:		.byte 0		;@ May never used
eepromType:	.byte 0
irqEnable:	.byte 0
reg0:		.byte 0
reg1:		.byte 0
			.skip 3		;@ Align
irqCounter:	.word 0
irqLatch:	.word 0

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Bandai FCG boards with the FCG-1 that supports no EEPROM, and the LZ93D50 with no or 256 bytes of EEPROM.
;@ See also mapper 153, 157 & 159
mapper16init:
;@----------------------------------------------------------------------------
	.word write, write, write, write
	
	mov r0, #0
	str_ r0, irqCounter
	str_ r0, irqLatch
	strb_ r0, eepromType

	ldrb_ r0, cartFlags		;@ Games need sram.
	orr r0, r0, #SRAM
	strb_ r0, cartFlags

	stmfd sp!, {lr}

	adr r1, writeL
	str_ r1,m6502WriteTbl+12

	ldr r0,=hook
	str_ r0,scanlineHook

	adr r1, readL
	str_ r1, m6502ReadTbl+12

	ldr r0, =NES_SRAM
	bl x24c01_reset
	ldr r0, =NES_SRAM
	bl x24c02_reset

;@ Patch for games...
	ldr_ r0,prgcrc

	ldr r1, =0x1F01		@ Dragon Ball Z
	cmp r1, r0
	moveq r0, #0

	ldr r1, =0x4E30		@ Dragon Ball Z2
	cmp r1, r0

	ldrne r1, =0x5E48	@ Dragon Ball Z3
	cmpne r1, r0

	ldrne r1, =0x492c	@ Datach - Dragon Ball Z Gaiden
	cmpne r1, r0

	ldrne r1, =0xE158	@ Datach - Dragon Ball Z Gaiden
	cmpne r1, r0

	ldrne r1, =0xC0E3	@ Datach - SD Gundam - Gundam Wars(J)
	cmpne r1, r0

	ldrne r1, =0x4D9A	@ Datach - Ultraman Club - Supokon Fight!(J)
	cmpne r1, r0

	ldrne r1, =0x01CC	@ Datach - Yuu Yuu Hakusho - Bakutou Ankoku Bujutsu Kai (J)
	cmpne r1, r0

	ldrne r1, =0xEF42	@ Datach - Battle Rush - Build Up Robot Tournament(J)
	cmpne r1, r0

	ldrne r1, =0x027D	@ Datach - J League Super Top Players(J)
	cmpne r1, r0

	moveq r0, #1
	streqb_ r0, eepromType

	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
readL:
;@----------------------------------------------------------------------------
	ldrb_ r1, patch
	ands r1, r1, r1
	movne r0, addy, lsr#8
	bxne lr
	tst addy, #0xFF
	movne r0, #0
	bxne lr

	stmfd sp!, {lr}
	ldrb_ r1, eepromType
	cmp r1, #0
	bne 0f

	bl x24c01_read
	ands r0, r0, r0
	movne r0, #0x10
	ldrb r1, barcodeOut
	orr r0, r0, r1
	@mov r0, #0
	ldmfd sp!, {pc}

0:
	cmp r1, #1
	bne 1f

	bl x24c02_read
	ands r0, r0, r0
	movne r0, #0x10
	ldrb r1, barcodeOut
	orr r0, r0, r1
	ldmfd sp!, {pc}

1:
	bl x24c01_read
	stmfd sp!, {r0}
	bl x24c02_read
	ldmfd sp!, {r1}
	ands r0, r0, r1
	movne r0, #0x10
	ldrb r1, barcodeOut
	orr r0, r0, r1
	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
writeL:
	ldrb_ r1, patch
	ands r1, r1, r1
	bxne lr
	b writeSubA

;@----------------------------------------------------------------------------
write:
	ldrb_ r1, patch
	ands r1, r1, r1
	beq writeSubA
	b writeSubB

;@----------------------------------------------------------------------------
writeSubB:
	bx lr

;@----------------------------------------------------------------------------
writeSubA:
	and r1, addy, #0xf
	cmp r1, #8
	bcs 8f

	ldr_ r2, vromMask
	add r2, r2, #1
	movs r2, r2, lsr#10

	stmfd sp!, {r0, lr}
	and r1, addy, #7
	blne chr1k
	ldmfd sp!, {r0, lr}

	ldrb_ r2, eepromType
	cmp r2, #2
	bxne lr
	strb_ r0, reg0
	ands r0, r0, #0x8
	movne r0, #0xFF
	ldrb_ r1, reg1
	ands r1, r1, #0x40
	movne r1, #0xFF
	b x24c01_write

8:
	cmp r1, #8
	beq 8f
	cmp r1, #9
	beq 9f
	cmp r1, #0xa
	beq a1
	cmp r1, #0xb
	beq b1
	cmp r1, #0xc
	beq c1
	cmp r1, #0xd
	beq d1

	bx lr
8:
	b map89AB_

9:
	ands r1, r0, #3
	beq mirror2V_
	cmp r1, #1
	beq mirror2H_
	cmp r1, #2
	b mirror1_

a1:
	and r1, r0, #1
	strb_ r1, irqEnable
	ldr_ r1, irqLatch
	str_ r1, irqCounter
	mov r0,#0
	b rp2A03SetIRQPin

b1:
	strb_ r0, irqLatch
	strb_ r0, irqCounter
	bx lr

c1:
	strb_ r0, irqLatch + 1
	strb_ r0, irqCounter + 1
	bx lr

d1:
	ldrb_ r2, eepromType
	cmp r2, #0
	bne 1f

	ands r1, r0, #0x40
	movne r1, #0xFF
	ands r0, r0, #0x20
	movne r0, #0xFF
	b x24c01_write

1:
	cmp r2, #1
	bne 2f

	ands r1, r0, #0x40
	movne r1, #0xFF
	ands r0, r0, #0x20
	movne r0, #0xfF
	b x24c02_write

2:
	;@ No need to support now.
	bx lr

;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb r0, barcode
	ands r0, r0, r0
	beq 0f

	ldrb r0, barcodeCnt
	add r0, r0, #1
	cmp r0, #9
	moveq r0, #0
	strb r0, barcodeCnt
	bne 0f

	ldr r1, =barcode_data
	ldrb r2, barcodePtr
	ldrb r0, [r1, r2]
	cmp r0, #0xFF
	moveq r0, #0
	streqb r0, barcode
	streqb r0, barcodeOut
	streqb r0, barcodePtr
	streqb r0, barcodeCnt
	strb r0, barcodeOut
	addne r2, r2, #1
	strneb r2, barcodePtr

0:
	ldrb_ r0, irqEnable
	ands r0, r0, r0
	bxeq lr
	ldr_ r0, irqCounter
	cmp r0, #115
	subcs r0, r0, #114
	strcs_ r0, irqCounter
	bxcs lr

	ldr r1, =0xFFFF
	and r0, r0, r1
	str_ r0, irqCounter
	mov r0,#1
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
barcodePtr:
	.byte 0
barcodeCnt:
	.byte 0
__barcode:
barcode:
	.byte 0
__barcode_out:
barcodeOut:
	.byte 0
