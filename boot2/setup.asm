
; ############################
; 	Constants & Macro
; ############################
	
SYSSEG 		equ 0x1000
NEWSYSSEG 	equ 0x0000

; 描述符类型
DA_32		equ	4000h	; 32 位段
DA_LIMIT_4K	equ	8000h	; 段界限粒度为 4K 字节

; 存储段描述符类型
DA_DR		equ	90h	; 存在的只读数据段类型值
DA_DRW		equ	92h	; 存在的可读写数据段属性值
DA_C		equ	98h	; 存在的只执行代码段属性值
DA_CR		equ	9Ah	; 存在的可执行可读代码段属性值

; Descriptor macro
%macro Descriptor 3
	dw	%2 & 0FFFFh							; Limit 1
	dw	%1 & 0FFFFh							; Base addr 1
	db	(%1 >> 16) & 0FFh					; Base addr 2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; Attr 1 + Limit 2 + Attr 2
	db	(%1 >> 24) & 0FFh					; Base addr 3
%endmacro


; ############################
; 	Booting Process
; ############################

[SECTION .s16]
[BITS 	16]
LABEL_BEGIN:

; 1) Read env from BIOS

; 2) Move system to 0x0000
	mov 	ax, SYSSEG
	mov 	ds, ax
	mov 	ax, NEWSYSSEG
	mov 	es, ax
	mov 	cx, 1000h 		; cx 	= counter
	xor 	si, si 			; ds:si = source
	xor 	di, di 			; es:di = target
	;rep 	movsw 			; move word by word

; 3) Enter protection mode
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	mov		sp, 0100h

	; 3.1) Init descriptor
	xor		eax, eax
	mov		ax, cs
	shl		eax, 4
	add		eax, LABEL_SEG_CODE32
	mov		word [LABEL_DESC_CODE32 + 2], ax
	shr		eax, 16
	mov		byte [LABEL_DESC_CODE32 + 4], al
	mov		byte [LABEL_DESC_CODE32 + 7], ah

	; 3.2) Load gdt to gdtr
	xor		eax, eax
	mov		ax, ds
	shl		eax, 4
	add		eax, LABEL_GDT			; eax <- gdt base addr
	mov		dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt base addr
	lgdt	[GdtPtr]

	; 3.3) Disable interrupt
	cli

	; 3.4) Enable A20 addr line
	in		al, 92h
	or		al, 00000010b
	out		92h, al

	; 3.5) Set PE in cr0
	mov		eax, cr0
	or		eax, 1
	mov		cr0, eax

	; 3.6) Jump to protective mode!
	jmp		dword SelectorCode32:0	; SelectorCode32 (LABEL_SEG_CODE32:0)

[SECTION .s32]
ALIGN	32
[BITS 	32]
LABEL_SEG_CODE32:
	mov 	ax, SelectorVideo
	mov 	gs, ax
	mov 	edi, (80 * 11 + 79) * 2
	mov 	ah, 0Ch
	mov 	al, 'P'
	mov 	[gs:edi], ax

; 4) Jump to system
	mov 	ax, SelectorData
	mov 	ds, ax
	mov 	es, ax
	mov 	ax, SelectorData
	mov 	ss, ax
	mov 	esp, 1000h

	jmp 	SelectorSystem:0

SegCode32Len equ $ - LABEL_SEG_CODE32

[SECTION .gdt]
;                            Base Addr,        Limit, 	Attribute
LABEL_GDT:	   		Descriptor       0,            0, 0
LABEL_DESC_CODE32: 	Descriptor       0, SegCode32Len, DA_CR  | DA_32 | DA_LIMIT_4K
LABEL_DESC_SYSTEM:	Descriptor  10000h,       0ffffh, DA_CR	 | DA_32 | DA_LIMIT_4K
LABEL_DESC_DATA:	Descriptor 	 0,       0ffffh, DA_DRW | DA_32 | DA_LIMIT_4K
LABEL_DESC_VIDEO:  	Descriptor 0B8000h,       0ffffh, DA_DRW

GdtLen		equ	$ - LABEL_GDT
GdtPtr		dw	GdtLen - 1					; GDT limit
			dd	0							; GDT base addr

SelectorCode32		equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorSystem		equ	LABEL_DESC_SYSTEM - LABEL_GDT
SelectorData 		equ	LABEL_DESC_DATA - LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO - LABEL_GDT

BootMessage:			
	db 	13,10
	db 	"In setup!"
	db 	13,10
