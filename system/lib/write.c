#include "type.h" 	/* u32 */

int write(int fd, const char *buf, int cnt)
{
	long res;
        __asm__(
                "int 0x80"
                : "=a"(res)
                : "0"(4), "b"(fd), "c"((u32)buf), "d"(cnt)
        );
	return 0;
}

