	

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
	jmp 	$
; 1) 

; 2) Move system to 0x0000
	mov 	ax, SYSSEG
	mov 	ds, ax
	mov 	ax, NEWSYSSEG
	mov 	es, ax
	mov 	cx, 7ffffh 		; cx 	= counter
	xor 	si, si 			; ds:si = source
	xor 	di, di 			; es:di = target
	;rep 	movsw 			; move word by word

; 2) Get ready for protection mode
	

	;jmp 	NEWSYSSEG:0h 	; far jump!
	
BootMessage:			
	db 	13,10
	db 	"In setup!"
	db 	13,10