
%include "var.inc"
%include "pm.inc"

extern main

global gdt,pdt
global startup_32

pdt:


[SECTION .text]
ALIGN   32
[BITS   32]

startup_32:
	mov 	ax, 16 		; SelectorData
	mov 	ds, ax
	mov 	es, ax
	mov 	ss, ax
	mov 	esp, TopOfStack

; 1) Print welcome message
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
	jmp 	setup_paging


; Temporary data and stack, will be overriden later
Message:
	db 	"Welcome to MiniOS"
len 	equ $ - Message


; LinearAddr[31~22] = 10 bits = 1024 entry (* 4B = 4096B)
; So PDT has 1024 entries (1024 page tables, occupy 4096b totally)
; LinearAddr[21~12] = 10 bits = 1024 entry (* 4B = 4096B)
; So PD  has 1024 entries (1024 pages, occupy 4096b totally)
; LinearAddr[11~0]  = 12 bits = 4096 byte 
; So offset (page size) is 4096b
PdtSize 	equ 	1024
PtSize 		equ 	1024
EntrySize 	equ 	4
PageSize 	equ 	4096

times 	PdtSize*EntrySize-($-$$) db 0

pg0:
times 	PtSize*EntrySize 	db 0

pg1:
times 	PtSize*EntrySize 	db 0

pg2:
times 	PtSize*EntrySize 	db 0

pg3:
times 	PtSize*EntrySize 	db 0


; 4) Setup paging
PgRw 		equ 	111h

ALIGN   32
setup_paging:

	; 4.1) Clear page space
	mov 	ecx, PdtSize + PtSize 		; counter = 5*1024
	xor 	eax, eax
	xor 	edi, edi
	cld 					; DF=0: edi move forward
	rep 	stosd 				; move eax => [es:edi] by dword

	; 4.2) Fill page dir
	mov 	dword [pdt], pg0 + PgRw 	; 111h(7): read/write page
	mov 	dword [pdt+04h], pg1 + PgRw 
	mov 	dword [pdt+08h], pg2 + PgRw
	mov 	dword [pdt+0ch], pg3 + PgRw

	; 4.3) Fill page table
	;      pg0~3 can represent 0h ~ fff000h (16MB) memory space

	; 0x3ffc: start addr of last entry of last PT
	mov 	edi, (pg3 + PtSize * EntrySize) - EntrySize 	
						
	; 0xfff000: start addr of last page represented by last entry
	mov 	eax, ((4 * PtSize * PageSize) - PageSize) + PgRw 	
						
	std 					; DF=1: edi move backward
.loop:
	stosd 					; move eax => [es:edi] by dword
	sub 	eax, PageSize
	jge 	.loop

	; 4.4) Set cr3 (PDBR, Page-Dir Base address Register)
	xor 	eax, eax
	mov 	cr3, eax

	; 4.5) Set PG bit of cr0 to enable paging 
	mov 	eax, cr0
	or 	eax, 80000000h
	mov 	cr0, eax

	; 4.6) Transfer control to main()
	ret


; Temporary stack space
times 	100h 	db 	0
TopOfStack 	equ	$ 


gdt:

;[SECTION .gdt]
;                            	 Base Addr,        Limit, 	Attribute
LABEL_GDT:	   	Descriptor      0h,           0h, 0h
LABEL_DESC_CODE:	Descriptor  	0h,       0ffffh, DA_CR	| DA_32 | DA_LIMIT_4K
LABEL_DESC_DATA:	Descriptor 	0h,       0ffffh, DA_DRW | DA_32 | DA_LIMIT_4K
LABEL_DESC_TEMP:	Descriptor      0h,           0h, 0h
times 	252 	dd 	0x0, 0x0		; space for LDT and TSS

GdtLen		equ	$ - LABEL_GDT
GdtPtr		dw	GdtLen - 1		; GDT limit
		dd	LABEL_GDT		; GDT base addr

SelectorCode	equ	LABEL_DESC_CODE - LABEL_GDT
SelectorData 	equ	LABEL_DESC_DATA - LABEL_GDT
