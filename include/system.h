#ifndef _SYSTEM_H_
#define _SYSTEM_H_

#define _set_tssldt_desc(n,addr,type) 	\
__asm__ ("movw $104,%1\n\t" 		\
	"movw %%ax,%2\n\t" 		\
	"rorl $16,%%eax\n\t" 		\
	"movb %%al,%3\n\t" 		\
	"movb $" type ",%4\n\t" 	\
	"movb $0x00,%5\n\t" 		\
	"movb %%ah,%6\n\t" 		\
	"rorl $16,%%eax" 		\
	::"a" (addr), "m" (*(n)), "m" (*(n+2)), "m" (*(n+4)), 	\
	 "m" (*(n+5)), "m" (*(n+6)), "m" (*(n+7)) 		\
)

#define set_tss_desc(n,addr) _set_tssldt_desc(((char *) (n)),((int)(addr)),"0x89")
#define set_ldt_desc(n,addr) _set_tssldt_desc(((char *) (n)),((int)(addr)),"0x82")

#endif
