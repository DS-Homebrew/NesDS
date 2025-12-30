@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global nespatch
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
nespatch:
@---------------------------------------------------------------------------------
@patch some games to act smoothly....
	ldr_ r0, prgcrc

	ldr r1, =0x49B3		@TMNT 1
	cmp r0, r1
	ldreq r2, =362
	streq_ r2,cyclesPerScanline
	bxeq lr

	ldr r1, =0x33AA		@Akumajou Densetsu
	cmp r0, r1
	ldreq r2, =362
	streq_ r2,cyclesPerScanline
	bxeq lr

	ldr r1, =0x0A62		@Joe & Mac
	cmp r0, r1
	ldreq r2, =340
	streq_ r2,cyclesPerScanline
	bxeq lr

	ldr r1, =0xB2B5		@Three Eyed ONE/Mitsume Ga Tooru
	cmp r0, r1
	ldreq r2, =360
	streq_ r2,cyclesPerScanline
	bxeq lr

	ldr r1, =0x8A35		@Feng Shen Bang(Chinese)
	cmp r0, r1
	ldreq r2, =360
	streq_ r2,cyclesPerScanline

	bx lr
