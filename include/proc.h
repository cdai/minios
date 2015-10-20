#ifndef _PROC_H_
#define _PROC_H_

#include "type.h" 	/* u32 */

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

void sched_init();

#endif
