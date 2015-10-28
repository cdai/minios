#include "proc.h"
#include "system.h" 		/* move_to_user_mode */
#include "proto.h" 		/* write */

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

	myprint("In kernel");

	while(1){}

	return 0;
}

