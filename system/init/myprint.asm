
[section .data]

[section .text]

global myprint

myprint:
	;mov 	ecx, [esp+8] 	; len
	;mov 	ebp, [esp+4]	; msg
	;mov 	eax, 1301h
	;mov 	ebx, 0007h
	;mov 	dl, 0h
	;int 	10h

        mov     ax, 32 		; SelectorVideo
     	mov     gs, ax
	mov 	ah, 0Ch
	mov 	ebx, 0
	mov 	ecx, [esp+8]
     	;mov    edi, (80 * 11 + 79) * 2

.loop:
	mov 	edi, ebx
	add 	edi, (80 * 20)
	imul 	edi, 2
     	mov     al, 'X' ; byte [esp+4]
     	mov     [gs:edi], ax

	inc 	ebx
	dec 	ecx
	cmp 	ecx, 0h
	jne 	.loop

	jmp 	$

	;mov 	edx, [esp+8]
	;mov 	ecx, [esp+4]
	;mov 	ebx, 1
	;mov 	eax, 4
	;int 	0x80
	;ret

	;mov 	ebx, 0 			; sys_exit
	;mov 	eax, 1
	;int 	0x80
