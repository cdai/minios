
[section .data]

[section .text]

global myprint

myprint:
	mov 	ecx, [esp+8] 	; len
	mov 	ebp, [esp+4]	; msg
	mov 	eax, 1301h
	mov 	ebx, 0007h
	mov 	dl, 0h
	int 	10h

	;mov 	edx, [esp+8]
	;mov 	ecx, [esp+4]
	;mov 	ebx, 1
	;mov 	eax, 4
	;int 	0x80
	;ret

	;mov 	ebx, 0 			; sys_exit
	;mov 	eax, 1
	;int 	0x80