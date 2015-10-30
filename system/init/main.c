#include "proc.h" 		/* sched_init */
#include "system.h" 		/* move_to_user_mode */
#include "proto.h" 		/* write,fork */

static void myprint(const char *str)
{
	int i;

	i = 0;
	while (str[i++]);

	write(1, str, i);
}

int main(void)
{
	trap_init();
	sched_init();
	sti();
	move_to_user_mode();

	if (!fork()) {

	}

	myprint("In kernel");

	while(1){}

	return 0;
}

