@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper16init
	patch		= mapperdata	@may never used
	eeprom_type	= mapperdata + 1
	irq_enable	= mapperdata + 2
	irq_type	= mapperdata + 3
	reg0		= mapperdata + 4
	reg1		= mapperdata + 5
	reg2		= mapperdata + 6
	irq_counter	= mapperdata + 8
	irq_latch	= mapperdata + 12

@---------------------------------------------------------------------------------
mapper16init:
@---------------------------------------------------------------------------------
	.word write, write, write, write
	
	mov r0, #0
	str_ r0, mapperdata
	str_ r0, mapperdata + 4
	str_ r0, irq_counter
	str_ r0, irq_latch
	strb_ r0, eeprom_type

	ldrb_ r0, cartflags		//games need sram.
	orr r0, r0, #SRAM
	strb_ r0, cartflags

	stmfd sp!, {lr}

	adr r1, writel
	str_ r1,writemem_tbl+12

	ldr r0,=hook
	str_ r0,scanlinehook

	adr r1, readl
	str_ r1, readmem_tbl+12

	ldr r0, =NES_SRAM
	bl x24c01_reset
	ldr r0, =NES_SRAM
	bl x24c02_reset

@patch for games...
	mov r0, #0		@init val
	ldr_ r1, rombase	@src
	ldr_ r2, prgsize8k	@size
	mov r2, r2, lsl#13
	swi 0x0e0000		@swicrc16
	
	ldr r1, =0x1F01		@Dragon Ball Z
	cmp r1, r0
	moveq r0, #0
	streqb_ r0, eeprom_type

	ldr r1, =0x4E30		@Dragon Ball Z2
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0x5E48		@Dragon Ball Z3
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0x492c		@Datach - Dragon Ball Z Gaiden
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0xE158		@Datach - Dragon Ball Z Gaiden
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0xC0E3		@Datach - SD Gundam - Gundam Wars(J)
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0x4D9A		@Datach - Ultraman Club - Supokon Fight!(J)
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0x01CC		@Datach - Yuu Yuu Hakusho - Bakutou Ankoku Bujutsu Kai (J) 
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0xEF42		@Datach - Battle Rush - Build Up Robot Tournament(J)
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldr r1, =0x027D		@Datach - J League Super Top Players(J)
	cmp r1, r0
	moveq r0, #1
	streqb_ r0, eeprom_type

	ldmfd sp!, {pc}

@---------------------------------------------------------------------------------
readl:
@---------------------------------------------------------------------------------
	ldrb_ r1, patch
	ands r1, r1, r1
	movne r0, addy, lsr#8
	movne pc, lr
	tst addy, #0xFF
	movne r0, #0
	movne pc, lr

	stmfd sp!, {lr}
	ldrb_ r1, eeprom_type
	cmp r1, #0
	bne 0f

	bl x24c01_read
	ands r0, r0, r0
	movne r0, #0x10
	ldrb_ r1, barcode_out
	orr r0, r0, r1
	@mov r0, #0
	ldmfd sp!, {pc}

0:
	cmp r1, #1
	bne 1f

	bl x24c02_read
	ands r0, r0, r0
	movne r0, #0x10
	ldrb_ r1, barcode_out
	orr r0, r0, r1
	ldmfd sp!, {pc}

1:
	bl x24c01_read
	stmfd sp!, {r0}
	bl x24c02_read
	ldmfd sp!, {r1}
	ands r0, r0, r1
	movne r0, #0x10
	ldrb_ r1, barcode_out
	orr r0, r0, r1
	ldmfd sp!, {pc}
	
@---------------------------------------------------------------------------------
writel:
	ldrb_ r1, patch
	ands r1, r1, r1
	movne pc, lr
	b writesuba

@--------------------------------------------------------------------------------
write:
	ldrb_ r1, patch
	ands r1, r1, r1
	beq writesuba
	b writesubb

@--------------------------------------------------------------------------------
writesubb:
	mov pc, lr

@--------------------------------------------------------------------------------
writesuba:
	and r1, addy, #0xf
	cmp r1, #8
	bcs 8f

	ldr_ r2, vrommask
	add r2, r2, #1
	movs r2, r2, lsr#10

	stmfd sp!, {r0, lr}
	and r1, addy, #7
	blne chr1k
	ldmfd sp!, {r0, lr}

	ldrb_ r2, eeprom_type
	cmp r2, #2
	movne pc, lr
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
	
	mov pc, lr
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
	strb_ r1, irq_enable
	ldr_ r1, irq_latch
	str_ r1, irq_counter
	mov pc, lr

b1:
	strb_ r0, irq_latch
	strb_ r0, irq_counter
	mov pc, lr

c1:
	strb_ r0, irq_latch + 1
	strb_ r0, irq_counter + 1
	mov pc, lr

d1:
	ldrb_ r2, eeprom_type
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
	@no need to support now.
	mov pc, lr

@--------------------------------------------------------------------------------
hook:
@--------------------------------------------------------------------------------
	ldrb_ r0, barcode
	ands r0, r0, r0
	beq 0f

	ldrb r0, barcode_cnt
	add r0, r0, #1
	cmp r0, #9
	moveq r0, #0
	strb r0, barcode_cnt
	bne 0f

	ldr r1, =barcode_data
	ldrb r2, barcode_ptr
	ldrb r0, [r1, r2]
	cmp r0, #0xFF
	moveq r0, #0
	streqb_ r0, barcode
	streqb_ r0, barcode_out
	streqb r0, barcode_ptr
	streqb r0, barcode_cnt
	strb_ r0, barcode_out
	addne r2, r2, #1
	strneb r2, barcode_ptr

0:
	ldrb_ r0, irq_enable
	ands r0, r0, r0
	beq hk
	ldr_ r0, irq_counter
	cmp r0, #115
	subcs r0, r0, #114
	strcs_ r0, irq_counter
	bcs hk
	ldr r1, =0xFFFF
	and r0, r0, r1
	str_ r0, irq_counter
	b CheckI

hk:
	fetch 0
@---------------------------------------------------------------------------------
barcode_ptr:
	.byte 0
barcode_cnt:
	.byte 0
