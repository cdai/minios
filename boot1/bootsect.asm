
%include "var.inc"

; ############################
; 	Booting Process
; ############################

	org 	07c00h

; 1) Move bootsect to 0x90000
	mov 	ax, BOOTSEG
	mov 	ds, ax
	mov 	ax, INITSEG
	mov 	es, ax
	mov 	cx, 256 		; cx 	= counter
	xor 	si, si 			; ds:si = source
	xor 	di, di 			; es:di = target
	rep 	movsw 			; move word by word
	jmp 	INITSEG:ok_move-$$ 	; far jump!
ok_move:
	mov 	ax, cs 			; re-init registers
	mov 	ds, ax
	mov 	es, ax
	mov 	ss, ax
	mov 	sp, 0xff00 		; arbitrary value >> 512, but < INITSEG

; 2) Load setup module at 0x90200
load_setup:
	mov 	dx, 0000h		; dx 	= driver(dh)/head(dl)
	mov 	cx, 0002h		; cx 	= track(ch)/sector(cl)
	mov 	bx, 0200h		; es:bx = target(es=9000h,bx=90200-90000)
	mov 	ah, 02h			; ah 	= service id(ah=02 means read)
	mov 	al, SETUPLEN 		; al 	= number of sectors to read(al)
	int 	13h
	jnc 	ok_load_setup
		
	xor 	dl, dl			; reset floppy and retry if failed
	xor 	ah, ah
	int 	13h
	jmp 	load_setup 		

; 3) Display loading message
ok_load_setup:
	mov 	ah, 03h 		; read cursur position
	xor 	bh, bh
	int 	10h

	mov 	bp, msg1-$$		; es:bp = message start address
	mov 	cx, 21 			; cx 	= message length 
	mov 	ax, 1301h
	mov 	bx, 0007h 		; bx	= page no.(bh=0 page-0)
					; 	  attribute(bl=7 white fg and black bg)
	mov 	dl, 0h
	int 	10h
	jmp 	load_system

; 4) Load system module at 0x10000
;    Assume SYSSIZE < 72 track (36864)
;    1 track = 18 sectors * 512b = 9216(b)
;    1 head = 80 tracks * 9216 = 720(kb)
MAX_ONE_READ 	equ 72

load_system:
	mov 	ax, SYSSEG
	mov 	es, ax
	mov 	bx, 0000h		; es:bx = target(es=1000h,bx=0)
	mov 	dx, 0000h		; dx 	= driver(dh)/head(dl)
	mov 	cx, 0006h		; cx 	= track(ch)/sector(cl)

	mov 	ax, SYSSIZE
	add 	ax, 511
	shr 	ax, 9			; al 	= (SYSSIZE + 511) / 512 sectors to read

	cmp 	al, MAX_ONE_READ
	jbe 	.loop
	mov 	al, MAX_ONE_READ 	; al 	= (al <= 72) ? al : 72
.loop
	mov 	ah, 02h			; ah 	= service id(ah=02 means read)
	int 	13h			; ignore any error

; 5) Kill motor
ok_load_system:
	mov 	dx, 0x3f2		; floppy controller port
	mov 	al, 0			; floppy A
	outb				; output al to dx port

; 6) Jump to setup
	jmp 	SETUPSEG:0h

; ############################
; 	Message
; ############################

msg1:		
	db 	13,10				; CRLF
	db 	"Loading system..."
	db 	13,10				; CRLF

times 	510-($-$$) 	db	0
	dw 		0xaa55
