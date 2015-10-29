#ifndef _SYSCALL_H_
#define _SYSCALL_H_

extern int sys_write();

fn_ptr sys_call_table[] =
{
	sys_write
};

#endif
