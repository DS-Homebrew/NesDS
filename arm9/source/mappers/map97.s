@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper97init
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Irem TAM-S1
@ Used in:
@ Kaiketsu Yanchamaru
mapper97init:
@---------------------------------------------------------------------------------
	.word write97,write97,void,void

	mov r0,#-1
	b map89AB_
@---------------------------------------------------------------------------------
write97:
@---------------------------------------------------------------------------------
	stmfd sp!,{r0,lr}
	bl mapCDEF_
	ldmfd sp!,{r0,lr}
	tst r0,#0x80
	b mirror2V_
@---------------------------------------------------------------------------------
