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
;               mov dx, offset UserPassword
;               mov ah, 09h
;               int 21h

                ret
                endp

;===============================================================================================
; Function to compare user and real password
; Entry: none
; Exit:  none
; Destr: AX, BX, DX, SI, DI                                                                  !!!
;===============================================================================================
CheckPassword   proc

                mov si, offset Password
                call StrLen

                mov si, offset UserPassword
                mov di, offset Password

check:
                mov al, [si]
                mov bl, [di]
                cmp al, bl
                jne wrong_password

                inc si
                inc di
                loop check

                mov al, [si]
                mov bl, [di]
                cmp al, bl
                jne wrong_password

                mov dx, offset CorrectMessage
                jmp print_message

wrong_password:
                mov dx, offset WrongMessage

print_message:
                mov ah, 09h
                int 21h

                ret
                endp

;=============================================================================
; Count length of string
; Entry:        si = string offset
; Exit:         cl = length of string
; Destr: AL                                                                !!!
;=============================================================================
StrLen          proc

                push bx
                mov bx, si
                xor cx, cx
cycle:
                mov al, [bx]
                cmp al, "$"
                je match

                inc cl
                inc bx
                jmp cycle

match:
                pop bx

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

Password        db  "electron", "$"

UserPassword    db  100  dup ("$")
;===============================================================================================

end             LessGo
