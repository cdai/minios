
[section .data]

;[section .text]

global startup_32

[SECTION .text]
ALIGN   32
[BITS   32]

startup_32:
        mov     ax, 24 		; SelectorVideo
     	mov     gs, ax
	mov 	ah, 0Ch
	mov 	ebx, 0
	mov 	ecx, len
	mov 	edx, Message

.loop:
	mov 	edi, ebx
	add 	edi, (80 * 20) 	; (80 * row + col) * 2
	imul 	edi, 2
     	mov     al, byte [edx]
     	mov     [gs:edi], ax

	inc 	ebx
	dec 	ecx
	inc 	edx
	cmp 	ecx, 0h
	jne 	.loop

	jmp 	$

Message:
	db 	"Welcome to MiniOS"
	db 	13,10		; CRLF
len 	equ 	$ - Message
