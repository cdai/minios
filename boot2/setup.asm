	

SYSSEG 		equ 0x1000
NEWSYSSEG 	equ 0x0000

	;org 	90200h

	mov 	ax, cs
	mov 	ds, ax
	mov 	es, ax

	mov 	ah, 03h 		; read cursur position
	xor 	bh, bh
	int 	10h

	mov 	bp, BootMessage ; es:bp = message start address
	mov 	cx, 13 			; cx 	= message length 
	mov 	ax, 1301h
	mov 	bx, 0007h 		; bx	= page no.(bh=0 page-0)
						; 		  attribute(bl=7 white fg and black bg)
	mov 	dl, 0h
	int 	10h
	;jmp 	$
	jmp	NEWSYSSEG:0h
; 1) 
	

; 2) Move system to 0x0000
	mov 	ax, SYSSEG
	mov 	ds, ax
	mov 	ax, NEWSYSSEG
	mov 	es, ax
	mov 	cx, 7ffffh 		; cx 	= counter
	xor 	si, si 			; ds:si = source
	xor 	di, di 			; es:di = target
	rep 	movsw 			; move word by word

; 2) Get ready for protection mode

; 描述符类型
DA_32		EQU	4000h	; 32 位段

; 存储段描述符类型
DA_DR		EQU	90h	; 存在的只读数据段类型值
DA_DRW		EQU	92h	; 存在的可读写数据段属性值
DA_C		EQU	98h	; 存在的只执行代码段属性值

; 描述符
; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				; 段界限1
	dw	%1 & 0FFFFh				; 段基址1
	db	(%1 >> 16) & 0FFh			; 段基址2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; 属性1 + 段界限2 + 属性2
	db	(%1 >> 24) & 0FFh			; 段基址3
%endmacro ; 共 8 字节

; GDT 选择子
[SECTION .gdt]
; GDT
;                              段基址,       段界限     , 属性
LABEL_GDT:	   Descriptor       0,                0, 0           ; 空描述符
LABEL_DESC_CODE32: Descriptor       0, 		1000, DA_C + DA_32; 非一致代码段
;LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; 显存首地址

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT基地址

SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
;SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, 0 ;LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs,
					; 并跳转到 Code32Selector:0  处

	;jmp 	NEWSYSSEG:0h 	; far jump!
	
BootMessage:			
	db 	13,10
	db 	"In setup!"
	db 	13,10
