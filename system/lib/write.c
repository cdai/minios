#include "proto.h" 		/* write() */

int write(u32 fd, const char *buf, u32 cnt)
{
	long res;
        __asm__(
                "int 0x80"
                : "=a"(res)
                : "0"(4), "b"(fd), "c"((u32)buf), "d"(cnt)
        );
	return 0;
}

