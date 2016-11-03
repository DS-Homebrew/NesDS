	#include "equates.h"
	.global x24c02_reset
	.global x24c02_write
	.global x24c02_read
@-------------------------------------------
	peepdata = mapperdata + 64
	now_state = mapperdata + 68
	next_state = mapperdata + 72
	bitcnt = mapperdata + 76
	addr = mapperdata + 80
	data = mapperdata + 81
	sda = mapperdata + 82
	scl_old = mapperdata + 83
	sda_old = mapperdata + 84
	rw = mapperdata + 85
@-------------------------------------------
X24C02_IDLE = 0			@ Idle
X24C02_DEVADDR = 1		@ Device address set
X24C02_ADDRESS = 2		@ Address set
X24C02_READ = 3			@ Read
X24C02_WRITE = 4		@ Write
X24C02_ACK = 5			@ Acknowledge
X24C02_NAK = 6			@ Not Acknowledge
X24C02_ACK_WAIT = 7		@ Acknowledge wait

.section .text, "ax"
.align 4

@-------------------------------------------
x24c02_reset:
@-------------------------------------------
	str_ r0, peepdata
	mov r1, #0
	strb_ r1, addr
	strb_ r1, data
	strb_ r1, rw
	strb_ r1, scl_old
	strb_ r1, sda_old
	mov r1, #0xFF
	strb_ r1, sda
	mov r1, #X24C02_IDLE
	str_ r1, now_state
	str_ r1, next_state
	mov pc, lr

@-------------------------------------------
x24c02_write:
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

	mov r2, #X24C02_DEVADDR
	str_ r2, now_state
	mov r2, #0
	str_ r2, bitcnt
	mov r2, #0xFF
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

stopcnd:
	cmp r5, #0
	cmpne r7, #0
	beq sclrise
	mov r2, #X24C02_IDLE
	str_ r2, now_state
	mov r2, #0xFF
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

sclrise:
	ands r9, r9, r9
	beq sclfall

	ldr_ r3, now_state
	cmp r3, #X24C02_DEVADDR
	beq xdevaddrr
	cmp r3, #X24C02_ADDRESS
	beq xaddressr
	cmp r3, #X24C02_READ
	beq xreadr
	cmp r3, #X24C02_WRITE
	beq xwriter
	cmp r3, #X24C02_NAK
	beq xnakr
	cmp r3, #X24C02_ACK
	beq xackr
	cmp r3, #X24C02_ACK_WAIT
	beq xackwaitr
	b sclfall

xdevaddrr:
	ldr_ r3, bitcnt
	cmp r3, #8
	add r5, r3, #1
	str_ r5, bitcnt
	bcs xend
	rsb r4, r3, #7
	ldrb_ r2, data
	mov r5, #1
	bic r2, r2, r5, lsl r4
	ands r1, r1, r1
	orrne r2, r2, r5, lsl r4
	strb_ r2, data
	ldmfd sp!, {r3-r9}
	mov pc, lr

xaddressr:
	ldr_ r3, bitcnt
	cmp r3, #8
	add r5, r3, #1
	str_ r5, bitcnt
	bcs xend
	rsb r4, r3, #7
	ldrb_ r2, addr
	mov r5, #1
	bic r2, r2, r5, lsl r4
	ands r1, r1, r1
	orrne r2, r2, r5, lsl r4
	strb_ r2, addr
	ldmfd sp!, {r3-r9}
	mov pc, lr

xreadr:
	ldr_ r3, bitcnt
	cmp r3, #8
	bcs xreadendr
	ldrb_ r4, data
	rsb r5, r3, #7
	mov r6, #1
	tst r4, r6, lsl r5
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
	rsb r5, r3, #7
	mov r6, #1
	bic r4, r6, lsl r5
	ands r1, r1, r1
	orrne r4, r4, r6, lsl r5
	strb_ r4, data
	add r3, r3, #1
	str_ r3, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xnakr:
	mov r2, #0xFF
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xackr:
	mov r2, #0
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xackwaitr:
	ands r1, r1, r1
	bne xend
	mov r3, #X24C02_READ
	str_ r3, next_state
	ldr_ r4, peepdata
	ldrb_ r5, addr
	ldrb r6, [r4, r5]
	strb_ r6, data
	ldmfd sp!, {r3-r9}
	mov pc, lr

sclfall:
	ands r8, r8, r8
	beq xend

	ldr_ r3, now_state
	cmp r3, #X24C02_DEVADDR
	beq xdevaddrf
	cmp r3, #X24C02_ADDRESS
	beq xaddressf
	cmp r3, #X24C02_READ
	beq xreadf
	cmp r3, #X24C02_WRITE
	beq xwritef
	cmp r3, #X24C02_NAK
	beq xnakf
	cmp r3, #X24C02_ACK
	beq xackf
	cmp r3, #X24C02_ACK_WAIT
	beq xackwaitf

	b xend

xdevaddrf:
	ldr_ r3, bitcnt
	cmp r3, #8
	bcc xend
	ldrb_ r3, data
	and r4, r3, #0xa0
	cmp r4, #0xa0
	bne xdev2

	mov r2, #X24C02_ACK
	str_ r2, now_state
	ands r2, r3, #1
	strb_ r2, rw
	mov r2, #0xFF
	strb_ r2, sda
	beq xdev1

	mov r2, #X24C02_READ
	str_ r2, next_state
	ldr_ r4, peepdata
	ldrb_ r5, addr
	ldrb r6, [r4, r5]
	strb_ r6, data
	mov r2, #0
	str_ r2, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xdev1:
	mov r2, #X24C02_ADDRESS
	str_ r2, next_state
	mov r2, #0
	str_ r2, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xdev2:
	mov r2, #X24C02_NAK
	str_ r2,now_state
	mov r2, #X24C02_IDLE
	str_ r2, next_state
	mov r2, #0xff
	strb_ r2, sda
	ldmfd sp!, {r3-r9}
	mov pc, lr

xaddressf:
	ldr_ r4, bitcnt
	cmp r4, #8
	bcc xend
	mov r0, #X24C02_ACK
	str_ r0, now_state
	mov r0, #0xFF
	strb_ r0, sda
	ldrb_ r2, rw
	ands r2, r2, r2
	movne r2, #X24C02_IDLE
	moveq r2, #X24C02_WRITE
	str_ r2, next_state
	mov r2, #0
	str_ r2, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xreadf:
	ldr_ r4, bitcnt
	cmp r4, #8
	bcc xend
	mov r0, #X24C02_ACK_WAIT
	str_ r0, now_state
	ldrb_ r0, addr
	add r0, r0, #1
	@and r0, r0, #0xFF
	strb_ r0, addr
	ldmfd sp!, {r3-r9}
	mov pc, lr

xwritef:
	ldr_ r4, bitcnt
	cmp r4, #8
	bcc xend
	mov r0, #X24C02_ACK
	str_ r0, now_state
	mov r0, #X24C02_WRITE
	str_ r0, next_state
	ldr_ r1, peepdata
	ldrb_ r2, addr
	ldrb_ r3, data
	strb r3, [r1, r2]
	add r2, r2, #1
	@and r2, r2, #0xFF
	strb_ r2, addr
	mov r2, #0
	str_ r2, bitcnt
	ldmfd sp!, {r3-r9}
	mov pc, lr

xnakf:
	mov r2, #X24C02_IDLE
	str_ r2, now_state
	mov r2, #0
	str_ r2, bitcnt
	mov r2, #0xFF
	strb_ r2, sda
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

xackwaitf:
	ldr_ r0, next_state
	str_ r0, now_state
	mov r0, #0
	str_ r0, bitcnt
	mov r0, #0xFF
	strb_ r0, sda

xend:
	ldmfd sp!, {r3-r9}
	mov pc, lr
	

@-------------------------------------------
x24c02_read:
	ldrb_ r0, sda
	mov pc, lr

	

	






	


