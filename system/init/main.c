#include "proc.h" 		/* sched_init */
#include "system.h" 		/* move_to_user_mode */
#include "proto.h" 		/* write,fork */

#define start_mem 4*1024*1024
#define end_mem 16*1024*1024
#define buf_end 4*1024*1024

int main(void)
{
	mem_init(start_mem, end_mem);
	trap_init();
	sched_init();
	sti();
	move_to_user_mode();

	write("Forking process 0");
	if (!fork()) {

	}

	while(1){}

	return 0;
}

