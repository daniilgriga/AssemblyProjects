.model tiny
.code
org 100h

LessGo:         jmp Main


; =================== CONSTANTS ===================
NL              equ 0dh, 0ah
; =================================================

; ===================== MACROS ====================
EOP             macro
                mov ah, 4ch
                int 21h
                endm
; =================================================

Main:
                call SignatureOutput

                call GetPassword

                EOP

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
GetPassword     proc                                    ;    bp - 22     bp - 20
                                                        ; I-----------I-----------I-----------I-----------I----------I- - - - -
                push bp                                 ; I           I           I           I           I          I
                mov bp, sp                              ; I MAX | LEN I     -     I    ...    I     -     I    bp    I ret.addr
                sub sp, 22                              ; I           I           I           I           I          I
                                                        ; I-----------I-----------I---------- I-----------I----------I- - - - -
                mov ah, 09h                             ;      ^sp <=============== sp - 22 ================== ^sp
                mov dx, offset AskPassword
                int 21h                                 ;    bp - 22     bp - 20
                                                        ; I-----------I-----------I-----------I-----------I----------I- - - - -
                mov ah, 0Ah                             ; I           I           I           I           I          I
                lea dx, [bp - 22]                       ; I  30 | LEN I     -     I    ...    I     -     I    bp    I ret.addr
                mov byte ptr [bp - 22], 30              ; I           I           I           I           I          I
                int 21h                                 ; I-----------I-----------I---------- I-----------I----------I- - - - -
                                                        ;      ^sp <=============== sp - 22 ================== ^sp
                mov ah, 09h
                mov dx, offset NewLine
                int 21h
                                                        ;                            bp - 21 = real length of user passweor
                lea si, [bp - 20]                       ;                            bp - 22     bp - 20 = addr of user password
                mov al, [si]                            ; I----------I-----------I-----------I-----------I----------I- - - - -
                cmp al, 03h                             ; I          I           I           I           I          I
                je jump                                 ; I    bp    I    LEN    I  30 | LEN I    ...    I    bp    I ret.addr
                                                        ; I          I           I           I           I          I
                push [bp - 21]                          ; I----------I-----------I-----------I---------- I----------I- - - - -
                push bp                                 ;      ^sp <=push= ^sp <=push= ^sp <==== sp - 22 ==== ^sp
                call CalcHashDJB2                       ;      ^param     ^param    of CalcHashDJB2

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

                mov ax, 5381h                           ; hash = 5381h
                                                        ;      bp                  bp + 4     bp + 6                  bx - 20
                mov bx, [bp + 4]                        ; I----------I----------I----------I-----------I-----------I-----------I- - - - -
                lea si, [bx - 20]                       ; I          I          I          I           I           I           I
                xor cx, cx                              ; I    bp    I ret.addr I    bp    I    LEN    I  30 | LEN I    ...    I
                mov cl, [bp + 6]                        ; I          I          I          I           I           I           I
                                                        ; I----------I----------I----------I-----------I-----------I-----------I- - - - -
                xor bx, bx                              ;     ^sp <=push= ^sp <=call= ^sp

hash_mash:
                push cx
                mov bl, [si]

                mov cx, ax                              ; copy
                shl ax, 5                               ; hash * 32
                add ax, cx                              ; add hash
                add ax, bx                              ; add symbol

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
