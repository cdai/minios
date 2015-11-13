#include "proc.h"
#include "mm.h" 		/* PAGE_SIZE */
#include "system.h" 		/* set_tss/ldt_desc */
#include "io.h" 		/* outb,outb_p */
#include "syscall.h" 		/* system_call_table */

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

long volatile jiffies = 0;

/* PCB of current process */
struct task_struct *current = &(init_task.task);

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


#define LATCH (1193180/HZ)

extern int timer_interrupt(void);
extern int system_call(void);


long last_pid = 0;


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

	// 3.Enable time interrupt and syscall
	outb_p(0x36, 0x43);		/* binary, mode 3, LSB/MSB, ch 0 */
	outb_p(LATCH & 0xff, 0x40);	/* LSB */
	outb(LATCH >> 8, 0x40);		/* MSB */
	set_intr_gate(0x20, &timer_interrupt);
	outb(inb_p(0x21) & ~0x01, 0x21);
	set_system_gate(0x80, &system_call);
}

int find_empty_process(void)
{
	int i;

	// Wrap around
	while (1) {
		if (++last_pid < 0)
			last_pid = 1;

		for (i = 0; i < NR_TASKS; i++)
			if (task[i] && task[i]->pid == last_pid)
				break;

		if (i == NR_TASKS)
			break;
	}
	
	for (i = 0; i < NR_TASKS; i++)
		if (!task[i])
			return i;
	return -1;
}

int copy_process(int nr, long ebp, long edi, long esi, long gs,
		long none,
		long ebx, long ecx, long edx, long fs, long es, long ds,
		long eip, long cs, long eflags, long esp, long ss)
{
	struct task_struct *p;

	// Set p = start addr of new page
	p = (struct task_struct *) get_free_page();
	task[nr] = p;

	//*p = *current;
	p->pid = last_pid;

	return 0;
}

