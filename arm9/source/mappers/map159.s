;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper159init

	.struct mapperData
counter:	.word 0
latch:		.word 0
enable:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Bandai FCG boards with an LZ93D50 and a 128-byte serial EEPROM (X24C01).
;@ Used in:
;@ Dragon Ball Z: Kyoushuu! Saiya-jin
;@ Magical Taruruuto-kun: Fantastic World!!
;@ Magical Taruruuto-kun 2: Mahou Daibouken
;@ SD Gundam Gaiden - Knight Gundam Monogatari
;@ See also mapper 16, 153 & 157
mapper159init:
;@----------------------------------------------------------------------------
	.word write0,write0,write0,write0

	ldrb_ r1,cartFlags		;@ Get cartFlags
	bic r1,r1,#SRAM			;@ Don't use SRAM on this mapper
	strb_ r1,cartFlags		;@ Set cartFlags
	ldr r1,mapper159init
	str_ r1,m6502WriteTbl+12

	ldr r0,=hook
	str_ r0,scanlineHook

	bx lr
;@----------------------------------------------------------------------------
write0:
;@----------------------------------------------------------------------------
	and addy,addy,#0x0f
	tst addy,#0x08
	ldreq r1,=writeCHRTBL
	adrne r1,tbl-8*4
	ldr pc,[r1,addy,lsl#2]
tbl: .word map89AB_,mirrorKonami_,wA,wB,wC,void,void,void
;@---------------------------
wA:
	and r0,r0,#1
	strb_ r0,enable
	ldr_ r0,latch
	str_ r0,counter
	mov r0,#0
	b rp2A03SetIRQPin
;@---------------------------
wB:
	strb_ r0,latch
	bx lr
;@---------------------------
wC:
	strb_ r0,latch+1
	bx lr

;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r0,enable
	cmp r0,#0
	bxeq lr

	ldr_ r0,counter
	subs r0,r0,#113
	str_ r0,counter
	mov r0,#1
	bcc rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
