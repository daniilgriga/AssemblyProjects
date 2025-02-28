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

                call CheckPassword

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

                mov ah, 09h
                mov dx, offset AskPassword
                int 21h

                mov si, offset UserPassword

reading:
                mov ah, 01h
                int 21h
                cmp al, 0Dh
                je end_read

                mov [si], al
                inc si
                jmp reading

end_read:
                ret
                endp

;===============================================================================================
; Function to compare user and real password
; Entry: none
; Exit:  none
; Destr: AX, BX, DX, SI, DI                                                                  !!!
;===============================================================================================
CheckPassword   proc

                mov si, offset UserPassword
                mov al, [si]
                cmp al, 03h
                je jump

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

                ret
                endp

;===============================================================================================
; DJB2 hash function for string (hash = hash * 32 + hash + c)
; Entry:        si = string offset
; Exit:         ax = hash
; Destr:                                                                                     !!!
;===============================================================================================
CalcHashDJB2    proc

                xor bx, bx
                mov ax, 5381h                               ; hash = 5381h

hash_mash:
                mov bl, [si]
                cmp bl, 00h
                je well_done

                mov cx, ax                                  ; copy
                shl ax, 5                                   ; hash * 32
                add ax, cx                                  ; add hash
                add ax, bx                                  ; add symbol

                inc si
                jmp hash_mash

well_done:
                ret
                endp

;========================================== VARIABLES ==========================================
Signature       db  NL, "######################################################", NL, "#", NL
                db      "#  Wassup, hacker!",   NL
                db      "#  Can you crack me?", NL, "#", NL
                db      "######################################################", NL, NL, "$"

AskPassword     db  "Enter the password:", "$"

WrongMessage    db  "LOL, get out", "$"
CorrectMessage  db  "Bazara net, u are admin here", "$"

UserPassword    db  10  dup (00h)
HashPassword    dw  0293Bh
;===============================================================================================

end             LessGo
