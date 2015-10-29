#include "system.h" 		/* marco */
#include "head.h" 		/* idt */

extern void page_fault(void);

void trap_init(void)
{
	set_trap_gate(14,&page_fault);
}

