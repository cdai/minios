#include "proc.h"
#include "mm.h" 		/* PAGE_SIZE */
#include "system.h" 		/* set_tss/ldt_desc */

/*
 * 1 page:
 * 	task_struct
 * 	kernel mode stack
 */
union task_union {
	struct task_struct task;
	char kernel_stack[PAGE_SIZE];
};

/* The kernel space of init task */
static union task_union init_task = { INIT_TASK, };

/* The pointer to PCB(task_struct array) */
struct task_struct *task[NR_TASKS] = { &(init_task.task), };

/* 
 * The stack for kernel code. 
 * The user stack for task-0/1
 */
long user_stack[PAGE_SIZE >> 2];

/* 
 * Struct for "lss stack_start,%esp" at head.asm 
 *  stack_start[0~31]  => %esp 	(user_stack)
 *  stack_start[32~47] => ss	(SelectorData)
 */
struct {
	u32 	*a;
	u16 	b;
} stack_start = { user_stack, 0x10 };


void sched_init()
{
	int i;
	struct desc_struct *p;

	// 1.Clear NT flag
	__asm__("pushfl ; andl $0xffffbfff,(%esp) ; popfl");

	// 2.Init PCB(task_struct),TSS,LDT
	set_tss_desc(gdt + FIRST_TSS_ENTRY, &(init_task.task.tss));
	set_ldt_desc(gdt + FIRST_LDT_ENTRY, &(init_task.task.ldt));

	p = gdt + FIRST_LDT_ENTRY + 1;
	for (i = 1; i < NR_TASKS; i++) {
		task[i] = NULL;
		p->a = p->b = 0;
		p++;
		p->a = p->b = 0;
		p++;
	}
	ltr(0);
	lldt(0);

	// 3.Enable time interrupt
}
