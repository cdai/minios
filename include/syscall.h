#ifndef _SYSCALL_H_
#define _SYSCALL_H_

extern int sys_fork();
extern int sys_write();

fn_ptr sys_call_table[] =
{
	(u32)0,
	(u32)0,
	sys_fork,
	(u32)0,
	sys_write
};

#endif
