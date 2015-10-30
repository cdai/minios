#include "proto.h"

int fork()
{
        long res;
        __asm__(
                "int 0x80"
                : "=a"(res)
                : "0"(2)
        );      
        return 0;
}

