#include <mm.h>

#define LOW_MEM 0x100000 			// start at 1MB
#define PAGING_MEMORY (15*1024*1024) 		// main memory: 15MB
#define PAGING_PAGES (PAGING_MEMORY>>12) 	// pages: 15MB/4096 = 3840
#define MAP_NR(addr) (((addr)-LOW_MEM)>>12)

#define FREE 0
#define USED 100
#define INVALID 100

static long HIGH_MEM = 0;
static unsigned char mem_map [ PAGING_PAGES ] = {0,};


unsigned long get_free_page(void)
{
	register unsigned long __res asm("ax");

	__asm__("std ; repne ; scasb\n\t"
		"jne 1f\n\t"
		"movb $1,1(%%edi)\n\t"
		"sall $12,%%ecx\n\t"
		"addl %2,%%ecx\n\t"
		"movl %%ecx,%%edx\n\t"
		"movl $1024,%%ecx\n\t"
		"leal 4092(%%edx),%%edi\n\t"
		"rep ; stosl\n\t"
		" movl %%edx,%%eax\n"
		"1: cld"
		:"=a" (__res)
		:"0" (0),"i" (LOW_MEM),"c" (PAGING_PAGES),
		"D" (mem_map+PAGING_PAGES-1)
		);
	return __res;
}

void mem_init(long start_mem, long end_mem)
{
	int i, start_nr, end_nr;

	HIGH_MEM = end_mem;
	start_nr = MAP_NR(start_mem);
	end_nr = MAP_NR(end_mem);

	// 1MB ~ start_mem(4MB) is used as kernel buffer
	for (i = 0; i < start_nr; i++)
		mem_map[i] = USED;

	// start_mem ~ end_mem(16MB) is free
	while (i++ < end_nr)
		mem_map[i] = FREE;

	// end_mem ~ 16MB is invalid
	while (i++ < PAGING_PAGES)
		mem_map[i] = INVALID;
}

