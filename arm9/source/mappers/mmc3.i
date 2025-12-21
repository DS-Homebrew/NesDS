;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.struct mapperData
mmc3Start:
irq_latch:		.byte 0
irq_enable:		.byte 0
irq_reload:		.byte 0
irq_counter:	.byte 0

reg0:	.byte 0
reg1:	.byte 0
reg2:	.byte 0
reg3:	.byte 0

chr01:	.byte 0
chr23:	.byte 0
chr4:	.byte 0
chr5:	.byte 0
chr6:	.byte 0
chr7:	.byte 0

prg0:	.byte 0
prg1:	.byte 0
prg2:	.byte 0
prg3:	.byte 0
		.skip 2		;@ align
mmc3Extra:
