#ifndef MACRO_H
#define MACRO_H
	.macro start_map base, register
	@GBLA _map_address_
 _map_address_ = \base
	.endm

	.macro _m_ label=0,size
	.if \label != 0
 \label = _map_address_
	.endif
 _map_address_ = _map_address_ + \size
	.endm

	.macro ldr_ reg,label
	ldr \reg,[globalptr,#\label]
	.endm
	
	.macro ldrb_ reg,label
	ldrb \reg,[globalptr,#\label]
	.endm
	
	.macro ldrh_ reg,label
	add \reg,globalptr,#((\label) & 0xFF00)
	add \reg,\reg,#((\label) & 0x00FF)
	ldrh \reg,[\reg]
	.endm
	
	.macro str_ reg,label
	str \reg,[globalptr,#\label]
	.endm
	
	.macro strb_ reg,label
	strb \reg,[globalptr,#\label]
	.endm
	
	.macro strh_ reg,label
	strh \reg,[globalptr,#\label]
	.endm



	.macro ldreq_ reg,label
	ldreq \reg,[globalptr,#\label]
	.endm
	
	.macro ldreqb_ reg,label
	ldreqb \reg,[globalptr,#\label]
	.endm
	
	.macro streq_ reg,label
	streq \reg,[globalptr,#\label]
	.endm
	
	.macro streqb_ reg,label
	streqb \reg,[globalptr,#\label]
	.endm
	



	.macro ldrne_ reg,label
	ldrne \reg,[globalptr,#\label]
	.endm
	
	.macro ldrneb_ reg,label
	ldrneb \reg,[globalptr,#\label]
	.endm
	
	.macro strne_ reg,label
	strne \reg,[globalptr,#\label]
	.endm
	
	.macro strneb_ reg,label
	strneb \reg,[globalptr,#\label]
	.endm
	
	.macro strcsb_ reg,label
	strcsb \reg,[globalptr,#\label]
	.endm
	
	.macro strcs_ reg,label
	strcs \reg,[globalptr,#\label]
	.endm

	.macro ldrhi_ reg,label
	ldrhi \reg,[globalptr,#\label]
	.endm
	
	.macro ldrhib_ reg,label
	ldrhib \reg,[globalptr,#\label]
	.endm
	
	.macro strhi_ reg,label
	strhi \reg,[globalptr,#\label]
	.endm
	
	.macro strhib_ reg,label
	strhib \reg,[globalptr,#\label]
	.endm


	.macro ldrmi_ reg,label
	ldrmi \reg,[globalptr,#\label]
	.endm
	
	.macro ldrmib_ reg,label
	ldrmib \reg,[globalptr,#\label]
	.endm
	
	.macro strmi_ reg,label
	strmi \reg,[globalptr,#\label]
	.endm
	
	.macro strmib_ reg,label
	strmib \reg,[globalptr,#\label]
	.endm

	.macro ldrpl_ reg,label
	ldrpl \reg,[globalptr,#\label]
	.endm
	
	.macro ldrplb_ reg,label
	ldrplb \reg,[globalptr,#\label]
	.endm
	
	.macro strpl_ reg,label
	strpl \reg,[globalptr,#\label]
	.endm
	
	.macro strplb_ reg,label
	strplb \reg,[globalptr,#\label]
	.endm


	.macro ldrgt_ reg,label
	ldrgt \reg,[globalptr,#\label]
	.endm
	
	.macro ldrgtb_ reg,label
	ldrgtb \reg,[globalptr,#\label]
	.endm
	
	.macro strgt_ reg,label
	strgt \reg,[globalptr,#\label]
	.endm
	
	.macro strgtb_ reg,label
	strgtb \reg,[globalptr,#\label]
	.endm


	.macro ldrge_ reg,label
	ldrge \reg,[globalptr,#\label]
	.endm
	
	.macro ldrgeb_ reg,label
	ldrgeb \reg,[globalptr,#\label]
	.endm
	
	.macro strge_ reg,label
	strge \reg,[globalptr,#\label]
	.endm
	
	.macro strgeb_ reg,label
	strgeb \reg,[globalptr,#\label]
	.endm


	.macro ldrlt_ reg,label
	ldrlt \reg,[globalptr,#\label]
	.endm
	
	.macro ldrltb_ reg,label
	ldrltb \reg,[globalptr,#\label]
	.endm
	
	.macro strlt_ reg,label
	strlt \reg,[globalptr,#\label]
	.endm
	
	.macro strltb_ reg,label
	strltb \reg,[globalptr,#\label]
	.endm


	.macro ldrle_ reg,label
	ldrle \reg,[globalptr,#\label]
	.endm
	
	.macro ldrleb_ reg,label
	ldrleb \reg,[globalptr,#\label]
	.endm
	
	.macro strle_ reg,label
	strle \reg,[globalptr,#\label]
	.endm
	
	.macro strleb_ reg,label
	strleb \reg,[globalptr,#\label]
	.endm


	.macro ldrlo_ reg,label
	ldrlo \reg,[globalptr,#\label]
	.endm
	
	.macro ldrlob_ reg,label
	ldrlob \reg,[globalptr,#\label]
	.endm
	
	.macro strlo_ reg,label
	strlo \reg,[globalptr,#\label]
	.endm
	
	.macro strlob_ reg,label
	strlob \reg,[globalptr,#\label]
	.endm
	
	.macro strcc_ reg,label
	strcc \reg,[globalptr,#\label]
	.endm
	
	.macro strccb_ reg,label
	strccb \reg,[globalptr,#\label]
	.endm

	.macro ldrcc_ reg,label
	ldrcc \reg,[globalptr,#\label]
	.endm
	
	.macro ldrccb_ reg,label
	ldrccb \reg,[globalptr,#\label]
	.endm

	.macro ldrcsb_ reg,label
	ldrcsb \reg,[globalptr,#\label]
	.endm

	.macro strls_ reg,label
	strls \reg,[globalptr,#\label]
	.endm

	.macro strlsb_ reg,label
	strlsb \reg,[globalptr,#\label]
	.endm

	.macro ldrls_ reg,label
	ldrls \reg,[globalptr,#\label]
	.endm

	.macro ldrlsb_ reg,label
	ldrlsb \reg,[globalptr,#\label]
	.endm

	.macro adr_ reg,label
	add \reg,globalptr,#\label
	.endm
	
	.macro adrl_ reg,label
	add \reg,globalptr,#((\label) & 0xFF00)
	add \reg,\reg,#((\label) & 0x00FF)
	.endm

 
#endif