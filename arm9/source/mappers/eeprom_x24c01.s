	#include "equates.h"
	.global x24c01_reset
	.global x24c01_write
	.global x24c01_read
@-------------------------------------------
	peepdata = mapperdata + 32
	now_state = mapperdata + 36
	next_state = mapperdata + 40
	bitcnt = mapperdata + 44
	addr = mapperdata + 48
	data = mapperdata + 49
	sda = mapperdata + 50
	scl_old = mapperdata + 51
	sda_old = mapperdata + 52
@-------------------------------------------
X24C01_IDLE = 0			@ Idle
X24C01_ADDRESS = 1		@ Address set
X24C01_READ = 2			@ Read
X24C01_WRITE = 3		@ Write
X24C01_ACK = 4			@ Acknowledge
X24C01_ACK_WAIT = 5		@ Acknowledge wait

.section .text, "ax"
.align 4

@-------------------------------------------
x24c01_reset:
@-------------------------------------------
	str_ r0, peepdata
	mov r1, #0
	strb_ r1, addr
	strb_ r1, data
	strb_ r1, scl_old
	strb_ r1, sda_old
	mov r1, #0xFF
	strb_ r1, sda
	mov r1, #X24C01_IDLE
	str_ r1, now_state
	str_ r1, next_state
	mov pc, lr

@-------------------------------------------
x24c01_write:
@r9 scl_rise
@r8 scl_fall
@r7 sda_rise
@r6 sda_fall
@r5 scl_old_temp
@r4 sda_old_temp

	ldr_ r2, emuflags
	orr r2, r2, #NEEDSRAM
	str_ r2, emuflags

	stmfd sp!, {r3-r9}
	ldrb_ r3, scl_old
	mvn r9, r3
	and r9, r9, r0
	mvn r8, r0
	and r8, r3, r8
	ldrb_ r2, sda_old
	mvn r7, r2
	and r7, r7, r1
	mvn r6, r1
	and r6, r2, r6
	ldrb_ r5, scl_old
	ldrb_ r4, sda_old
	strb_ r0, scl_old
	strb_ r1, sda_old

	cmp r5, #0
	cmpne r6, #0
	beq stopcnd

	mov r2, #X24C01_ADDRESS
	str_ r2, now_state
	mov r2, #0
	str_ r2, bitcnt
	strb_ r2, addr
	mov r2, #0xFF
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

stopcnd:
	cmp r5, #0
	cmpne r7, #0
	beq sclrise
	mov r2, #X24C01_IDLE
	str_ r2, now_state
	mov r2, #0xFF
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

sclrise:
	ands r9, r9, r9
	beq sclfall

	ldr_ r3, now_state
	cmp r3, #X24C01_ADDRESS
	beq xaddressr
	cmp r3, #X24C01_ACK
	beq xackr
	cmp r3, #X24C01_READ
	beq xreadr
	cmp r3, #X24C01_WRITE
	beq xwriter
	cmp r3, #X24C01_ACK_WAIT
	beq xackwaitr
	b sclfall

xaddressr:
	ldr_ r3, bitcnt
	cmp r3, #7
	bcs bitbigr
	ldrb_ r2, addr
	mov r4, #1
	bic r2, r2, r4, lsl r3
	ands r1, r1, r1
	orrne r2, r2, r4, lsl r3
	strb_ r2, addr
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

bitbigr:
	ands r1, r1, r1
	beq 0f

	mov r2, #X24C01_READ
	str_ r2, next_state
	ldrb_ r4, addr
	and r4, r4, #0x7F
	ldr_ r5, peepdata
	ldrb r6, [r5, r4]
	strb_ r6, data
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

0:
	mov r2, #X24C01_WRITE
	str_ r2, next_state
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xackr:
	mov r2, #0
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xreadr:
	ldr_ r3, bitcnt
	cmp r3, #8
	bcs xreadendr
	ldrb_ r4, data
	mov r5, #1
	tst r4, r5, lsl r3
	movne r4, #1
	moveq r4, #0
	strb_ r4, sda
	
xreadendr:
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xwriter:
	ldr_ r3, bitcnt
	cmp r3, #8
	bcs xreadendr
	ldrb_ r4, data
	mov r5, #1
	bic r4, r4, r5, lsl r3
	ands r1, r1, r1
	orrne r4, r4, r5, lsl r3
	strb_ r4, data
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xackwaitr:
	ands r1, r1, r1
	moveq r3, #X24C01_IDLE
	streq_ r3, next_state
	ldmfd sp!, {r3-r9}
	mov pc, lr

sclfall:
	ands r8, r8, r8
	beq xend

	ldr_ r3, now_state
	cmp r3, #X24C01_ADDRESS
	beq xaddressf
	cmp r3, #X24C01_ACK
	beq xackf
	cmp r3, #X24C01_READ
	beq xreadf
	cmp r3, #X24C01_WRITE
	beq xwritef

	b xend

xaddressf:
	ldr_ r4, bitcnt
	cmp r4, #8
	movcs r0, #X24C01_ACK
	strcs_ r0, now_state
	movcs r0, #0xFF
	strcsb_ r0, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xackf:
	ldr_ r0, next_state
	str_ r0, now_state
	mov r0, #0
	str_ r0, bitcnt
	mov r0, #0xFF
	strb_ r0, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xreadf:
	ldr_ r4, bitcnt
	cmp r4, #8
	bcc xend
	mov r0, #X24C01_ACK_WAIT
	str_ r0, now_state
	ldrb_ r0, addr
	add r0, r0, #1
	and r0, r0, #0x7F
	strb_ r0, addr
	ldmfd sp!, {r3-r9}
	mov pc, lr

xwritef:
	ldr_ r4, bitcnt
	cmp r4, #8
	bcc xend
	mov r0, #X24C01_ACK
	str_ r0, now_state
	mov r0, #X24C01_IDLE
	str_ r0, next_state
	ldr_ r1, peepdata
	ldrb_ r2, addr
	and r2, r2, #0x7F
	ldrb_ r3, data
	strb r3, [r1, r2]
	add r2, r2, #1
	and r2, r2, #0x7F
	strb_ r2, addr

xend:
	ldmfd sp!, {r3-r9}
	mov pc, lr
	

@-------------------------------------------
x24c01_read:
	ldrb_ r0, sda
	mov pc, lr

	

	






	


