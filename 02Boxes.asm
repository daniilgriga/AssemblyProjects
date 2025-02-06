.model tiny
.code
org 100h

Lesgo:      mov ah, 09h
            mov dx, offset WassupStr
            int 21h

            call PutSymbol

            mov ah, 4ch
            int 21h


PutSymbol   proc

            mov bx, 0b800h
            mov es, bx
            mov bx, 5*80*2 + 40*2

            mov byte ptr es:[bx], 'A'
            mov byte ptr es:[bx + 1], 10011101b

            ret
            endp

NL          equ 0dh, 0ah

WassupStr   db 	"Wassup", NL, "$"

end Lesgo
