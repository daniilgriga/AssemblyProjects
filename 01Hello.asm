.model tiny
.code
org 100h

Lesgo:      mov ah, 09h
            mov dx, offset WassupStr
            int 21h

            mov ah, 4ch
            int 21h


NL          equ 0dh, 0ah

WassupStr   db 	"Wassup my boooooiy", NL, "$"

end Lesgo


; if we replace 09h to 02h in 5 line - we got 02h coomand: Display Char - sends
; the charachter in dl to the Standard Output. WassupString's address is 010B ->
; -> dx = 010B. 21h -> 02h in ah -> Dispaly Char in dl = 0B.
; for "!" we need replace 0B to 21.
