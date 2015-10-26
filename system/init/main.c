#include "proc.h"
#include "system.h" 		/* move_to_user_mode */

int main(void)
{
	sched_init();

	move_to_user_mode();

	return 0;
}

