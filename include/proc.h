#ifndef _PROC_H_
#define _PROC_H_

#include "type.h" 		/* u32 */
#include "head.h"		/* gdt,ldt */ 


/****************************************/
/* 		Struct 			*/
/****************************************/

struct tss_struct {
	u32	back_link;	/* 16 high bits zero */
	u32	esp0;
	u32	ss0;		/* 16 high bits zero */
	u32	esp1;
	u32	ss1;		/* 16 high bits zero */
	u32	esp2;
	u32	ss2;		/* 16 high bits zero */
	u32	cr3;
	u32	eip;
	u32	eflags;
	u32	eax,ecx,edx,ebx;
	u32	esp;
	u32	ebp;
	u32	esi;
	u32	edi;
	u32	es;		/* 16 high bits zero */
	u32	cs;		/* 16 high bits zero */
	u32	ss;		/* 16 high bits zero */
	u32	ds;		/* 16 high bits zero */
	u32	fs;		/* 16 high bits zero */
	u32	gs;		/* 16 high bits zero */
	u32	ldt;		/* 16 high bits zero */
	u32	trace_bitmap;	/* bits: trace 0, bitmap 16-31 */
};

struct task_struct {
	u32 	state;
	u32 	pid;
	u32 	father;
	struct desc_struct ldt[3];
	struct tss_struct tss;
};


/****************************************/
/* 		Global Var 		*/
/****************************************/

#define NR_TASKS 64

#define TASK_RUNNING		0
#define TASK_INTERRUPTIBLE	1
#define TASK_UNINTERRUPTIBLE	2
#define TASK_ZOMBIE		3
#define TASK_STOPPED		4

#define INIT_TASK 			\
{                       		\
/* state */	TASK_RUNNING, 		\
/* pid */ 	0, 			\
/* father */ 	0, 			\
		/***** LDT *****/ 	\
		{ 			\
/* null */        {0,0},          	\
/* code */        {0x9f,0xc0fa00},	\
/* data */        {0x9f,0xc0f200},	\
		}, 			\
        	/***** TSS *****/ 	\
		{ 			\
/* back_link */ 	0,              \
/* esp0=top of page */ 	&init_task+PAGE_SIZE,\
/* ss0=SelectorData */ 	0x10,           \
/* esp1,ss1,esp2,ss2 */ 0,0,0,0,        \
/* cr3=pdt */ 		&pg_dir,        \
/* eip,eflags */ 	0,0,            \
/* eax,ecx,edx,ebx */ 	0,0,0,0,        \
/* esp,ebp,esi,edi */ 	0,0,0,0,        \
/* es,cs,ss */ 		0x17,0x17,0x17, \
/* ds,fs,gs */ 		0x17,0x17,0x17, \
/* ldt */ 		_LDT(0),        \
/* trace */ 		0x80000000,     \
		}, 			\
}

extern struct task_struct *task[NR_TASKS];
extern struct task_struct *current;


#define FIRST_TSS_ENTRY 4
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY+1)
#define _TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
#define _LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))
#define ltr(n) __asm__("ltr %%ax"::"a" (_TSS(n)))
#define lldt(n) __asm__("lldt %%ax"::"a" (_LDT(n)))


/****************************************/
/* 		Function 		*/
/****************************************/

void sched_init();

#endif
