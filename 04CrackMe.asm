.model tiny
.code
org 100h

LessGo:         jmp Main


;=================== CONSTANTS ===================
NL              equ 0dh, 0ah
;=================================================

Main:
                call SignatureOutput

                call GetPassword

                ;call CheckPassword

                mov ah, 4ch
                int 21h

;===============================================================================================
; Welcome text output
; Entry: none
; Exit:  none
; Destr: AX, DX                                                                              !!!
;===============================================================================================
SignatureOutput proc

                mov ah, 09h
                mov dx, offset Signature
                int 21h

                ret
                endp

;===============================================================================================
; Function to get user text
; Entry: none
; Exit:  none
; Destr: AX, DX, SI                                                                          !!!
;===============================================================================================
GetPassword     proc

                push bp
                mov bp, sp
                sub sp, 22

                mov ah, 09h
                mov dx, offset AskPassword
                int 21h

                mov ah, 0Ah
                lea dx, [bp - 22]
                mov byte ptr [bp - 22], 30
                int 21h

                ; I----------I----------I----------I----------I----------I- - - - -
                ; I          I          I          I          I          I
                ; I   max    I   real   I   ....   I   ****   I   ****   I ret.addr
                ; I          I          I          I          I          I
                ; I----------I----------I----------I----------I----------I- - - - -
                ;

                mov ah, 09h
                mov dx, offset NewLine
                int 21h

                lea si, [bp - 20]
                mov al, [si]
                cmp al, 03h
                je jump

                push [bp - 21]
                push bp
                call CalcHashDJB2

                cmp ax, [HashPassword]
                jne wrong_password

jump:
                mov dx, offset CorrectMessage
                jmp print_message

wrong_password:
                mov dx, offset WrongMessage

print_message:
                mov ah, 09h
                int 21h

                mov sp, bp
                pop bp

                ret
                endp

;===============================================================================================
; DJB2 hash function for string (hash = hash * 32 + hash + c)
; Entry:        si = string offset
; Exit:         ax = hash
; Destr:                                                                                     !!!
;===============================================================================================
CalcHashDJB2    proc

                push bp
                mov bp, sp

                mov ax, 5381h                               ; hash = 5381h

                mov bx, [bp + 4]
                lea si, [bx - 20]
                xor cx, cx
                mov cl, [bp + 6]

                xor bx, bx
hash_mash:
                push cx
                mov bl, [si]

                mov cx, ax                                  ; copy
                shl ax, 5                                   ; hash * 32
                add ax, cx                                  ; add hash
                add ax, bx                                  ; add symbol

                inc si
                pop cx
                loop hash_mash

                mov sp,bp
                pop bp

                ret 4
                endp

;========================================== VARIABLES ==========================================
Signature       db  NL, "######################################################", NL, "#", NL
                db      "#  Wassup, hacker!",   NL
                db      "#  Can you crack me?", NL, "#", NL
                db      "######################################################", NL, NL, "$"

AskPassword     db  "Enter the password:", "$"

NewLine         db  NL, "$"

WrongMessage    db  "LOL, get out", "$"
CorrectMessage  db  "Bazara net, u are admin here", "$"

UserPassword    db  10  dup (00h)
HashPassword    dw  0293Bh
;===============================================================================================

end             LessGo
