#ifndef _HEAD_H_
#define _HEAD_H_

typedef struct desc_struct {
	u32 	a;
	u32 	b;
} desc_table[256];

extern u32 pdt[1024];
extern desc_table idt;
extern desc_table gdt;

#define GDT_NULL 0
#define GDT_CODE 1
#define GDT_DATA 2
#define GDT_TMP 3

#define LDT_NULL 0
#define LDT_CODE 1
#define LDT_DATA 2

#endif
