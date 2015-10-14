
%include "var.inc"
%include "pm.inc"

extern main

[SECTION .data]

global startup_32

[SECTION .text]
ALIGN   32
[BITS   32]

startup_32:
	mov 	ax, 16 		; SelectorData
	mov 	ds, ax
	mov 	es, ax

; 1) Output welcome message
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

; 2) Reset GDTR
	lgdt 	[GdtPtr]

; 3) Prepare return address
	push 	main

; 4) Setup paging

	ret


[SECTION .data]
Message:
	db 	"Welcome to MiniOS"
len 	equ $ - Message

times 	100h 	db 	0
TopOfStack 	equ	$ 


[SECTION .gdt]
;                            	 Base Addr,        Limit, 	Attribute
LABEL_GDT:	   	Descriptor      0h,           0h, 0h
LABEL_DESC_SYSTEM:	Descriptor  	0h,       0ffffh, DA_CR	| DA_32 | DA_LIMIT_4K
LABEL_DESC_DATA:	Descriptor 	0h,       0ffffh, DA_DRW | DA_32 | DA_LIMIT_4K
times 	253 	dd 	0x0, 0x0		; space for LDT and TSS

GdtLen		equ	$ - LABEL_GDT
GdtPtr		dw	GdtLen - 1		; GDT limit
		dd	LABEL_GDT		; GDT base addr

SelectorSystem	equ	LABEL_DESC_SYSTEM - LABEL_GDT
SelectorData 	equ	LABEL_DESC_DATA - LABEL_GDT
