
global timer_interrupt,system_call

extern sys_call_table

ALIGN   32
system_call:
	push 	ds
	push 	es
	push 	fs 		; backup ds/es/fs

	push	edx
	push 	ecx
	push 	ebx 		; push ebx/ecx/edx as param

	mov 	dx, 0x10
	mov 	ds, dx
	mov 	es, dx 		; set ds/es points to kernel space
	mov 	dx, 0x17
	mov 	fs, dx 		; set fs points to local data space

	call 	[sys_call_table+eax*4] 

	pop 	ebx
	pop 	ecx
	pop 	edx
	pop 	fs
	pop 	es
	pop 	ds
	iret

timer_interrupt:
	iret

