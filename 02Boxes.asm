.model tiny
.code
org 100h

Lesgo:      mov ah, 09h
            mov dx, offset WassupStr
            int 21h

            mov bx, dx
            call StrLen

            call PutSymbol              ; return symbol with ASCII = cl = length of WassupStr

            mov ah, 4ch                 ; exit
            int 21h

;=============================================================================
; Count length of string
; Entry: bx = string offset
; Exit:  cl = length of string
; Destr: AL                                                                !!!
;=============================================================================
StrLen      proc

            mov cl, 0

            cycle:
                    mov al, [bx]
                    cmp al, '#'

                    je match

                    inc cl
                    inc bx

                    jmp cycle

            match:
                    ret
                    endp

;=============================================================================
; Draws one char to video memory in (x = 40, y = 5)
; Entry: cl
; Exit:  none
; Destr: bx, es                                                            !!!
;=============================================================================
PutSymbol   proc

            mov bx, 0b800h
            mov es, bx
            mov bx, 5*80*2 + 40*2

            mov byte ptr es:[bx], cl
            mov byte ptr es:[bx + 1], 10011101b

            ret
            endp

NL          equ 0dh, 0ah

WassupStr   db 	"sup bro", "$", "#"

end Lesgo
