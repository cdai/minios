
global timer_interrupt,system_call,sys_fork,sys_write

extern sys_call_table,find_empty_process,copy_process

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

sys_fork:
	call 	find_empty_process ; save ret to eax
	push 	gs
	push 	esi
	push 	edi
	push 	ebp
	push 	eax 		; pid
	call 	copy_process
	add 	esp, 20 	; pop 5 times
	ret

disp_row: 	dd 	21

sys_write:
	push 	ebp
	mov 	ebp, esp
	push 	gs
	mov 	ax, 0x18
	mov 	gs, ax

	; buf
	; ret addr
	; ebp
	; gs
	; --- esp
	mov 	ah, 0Fh
	mov 	ebx, [esp+12] 	
	mov 	al, byte [ebx] 	; ebx is char offset
	mov 	ecx, [disp_row] ; ecx is old row number
	mov 	edi, ecx
	imul 	edi, 160 	; (80 * row + col) * 2
.loop:
	mov 	[gs:edi], ax

	add 	edi, 2
	inc 	ebx
	mov 	al, byte [ebx]
	cmp 	al, 0h
	jnz 	.loop

	inc 	ecx 		; set position to next line
	mov 	[disp_row], ecx

	pop 	gs
	pop 	ebp
	ret
