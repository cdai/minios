
%include "var.inc"
%include "pm.inc"

; ############################
; 	Booting Process
; ############################

[SECTION .s16]
[BITS 	16]

; 1) Read memory info from BIOS
	mov 	ax, INITSEG
	mov 	ds, ax			; save to bootsect space
	mov 	ah, 0x88
	int 	0x15
	mov 	[MEMSIZE], ax		; ax=3c00h (15360kb=15mb)

; 2) Move system to 0x0000
;    round-1: 10000~1ffff => 0000~ffff
;       ...
;    round-5: 80000~8ffff => 70000~7ffff
; 
; NOTE: 8000h word = 10000h byte
WordPerMove 	equ 8000h

move_system:
	mov 	ax, 0h
.loop
	mov 	es, ax
	add 	ax, 1000h
	mov 	ds, ax
	mov 	cx, WordPerMove 	; cx 	= counter
	xor 	si, si 			; ds:si = source
	xor 	di, di 			; es:di = target
	rep 	movsw 			; move

	cmp 	ax, INITSEG
	jne 	.loop

; 3) Enter protection mode
	mov 	ax, cs
	mov 	ds, ax
	mov 	es, ax
	mov 	ss, ax
	mov 	sp, 0100h

	; 3.1) Load gdt to gdtr
	xor 	eax, eax
	mov 	ax, ds
	shl 	eax, 4
	add 	eax, LABEL_GDT		; eax <- gdt base addr
	mov 	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt base addr
	lgdt 	[GdtPtr]

	; 3.2) Disable interrupt
	cli

	; 3.3) Enable A20 addr line
	in 	al, 92h
	or 	al, 00000010b
	out 	92h, al

	; 3.4) Set PE in cr0
	mov 	eax, cr0
	or  	eax, 1
	mov 	cr0, eax

	; 3.5) Jump to protective mode!
	jmp 	dword SelectorCode:0	; 0x0000:0x0


[SECTION .gdt]
;                            	 Base Addr,        Limit, 	Attribute
LABEL_GDT:	   	Descriptor      0h,           0h, 0h
LABEL_DESC_CODE:	Descriptor  	0h,       0ffffh, DA_CR	| DA_32 | DA_LIMIT_4K
LABEL_DESC_DATA:	Descriptor 	0h,       0ffffh, DA_DRW | DA_32 | DA_LIMIT_4K
LABEL_DESC_VIDEO:  	Descriptor 0B8000h,       0ffffh, DA_DRW

GdtLen		equ	$ - LABEL_GDT
GdtPtr		dw	GdtLen - 1		; GDT limit
		dd	0			; GDT base addr

SelectorCode	equ	LABEL_DESC_CODE - LABEL_GDT
SelectorData 	equ	LABEL_DESC_DATA - LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO - LABEL_GDT
