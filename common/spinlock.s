@coto: fix compiler warnings by making sure ARM7/ARM9 uses correct SWP opcodes
#ifdef ARM7
	.cpu arm7tdmi
#else
	#ifdef ARM9
		.cpu arm946e-s
	#endif
#endif

.text
.code 32
.ARM 

.GLOBL SLasm_Acquire, SLasm_Release   
SLasm_Acquire:					
   ldr r2,[r0]					
   cmp r2,#0					
   movne r0,#1	                
   bxne lr		                
   mov	r2,r1					
   swp r2,r2,[r0]				
   cmp r2,#0					
   cmpne r2,r1	                
   moveq r0,#0	                
   bxeq lr		                
   swp r2,r2,[r0]				
   mov r0,#1                   
   bx lr		                



SLasm_Release:					
   ldr r2,[r0]					
   cmp r2,r1	                
   movne r0,#2                 
   bxne lr		                
   mov r2,#0					
   swp r2,r2,[r0]				
   cmp r2,r1					
   moveq r0,#0	                
   movne r0,#2                 
   bx lr		                



	.pool
	.end
