#include "proc.h" 		/* sched_init */
#include "system.h" 		/* move_to_user_mode */
#include "proto.h" 		/* write,fork */

int main(void)
{
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

