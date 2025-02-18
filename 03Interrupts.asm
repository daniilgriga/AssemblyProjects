.model tiny
.code
org 100h

EOP 	        macro
		        mov ax, 4c00h
		        int 21h
	            endm			; end of program

VIDEOSEG        equ 0b800h
START_Y         equ 5*80*2
START_X         equ 20*2

LessGo:
                mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X
                mov ah, 97h
                lodsb
                stosw

next:
                in al, 60h
                mov es:[bx], ax

                cmp al, 1
                jne next

                EOP

end LessGo
