#include "proc.h"
#include "mm.h"

/*
 * 1 page:
 * 	task_struct
 * 	kernel mode stack
 */
union task_union {
	struct task_struct task;
	char stack[PAGE_SIZE];
};

static union task_union init_task = {};


void sched_init()
{

}
