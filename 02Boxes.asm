.model tiny
.code
org 100h

VIDEOSEG        equ 0b800h
START_Y         equ 3*80*2
START_X         equ 10*2
BLINKING_PINK   equ 11011100b

Lesgo:
                mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X

                call SizeAnalysis

                mov ah, BLINKING_PINK
                call BoxBuild
                call BoxText

                mov ah, 4ch                             ; exit
                int 21h

BoxSizeX db  20
BoxSizeY db  10

;=============================================================================
; Size of Box analysis
; Entry:
; Exit:
; Destr: AL, CL                                                            !!!
;=============================================================================
SizeAnalysis    proc

                mov si, 81h
                call AtoI
                cmp al, 0

                je lol
                mov [BoxSizeX], al

                call AtoI
                cmp al, 0

                je lol
                mov [BoxSizeY], al

                mov si, offset Text
                call StrLen                             ; cl = length of Text

                mov al, [BoxSizeX]
                cmp cl, al                              ; compare

                jbe without_upd                         ; BoxSizeX => length of Text ? nothing : change

                mov [BoxSizeX], cl
                add [BoxSizeX], 10                      ; update size

                without_upd:
                lol:

                ret
                endp

;=============================================================================
; Draws box
; Entry:        di = location rn
;
; Exit:  none
; Destr: DI, SI, BX, CX                                                    !!!
;=============================================================================
BoxBuild        proc

                mov si, offset FrameStyle4              ; FrameStyle addr in si

                call BoxLine

                mov cl, [BoxSizeY]
                sub cl, 2
                next:
                        push cx                         ; save cx for last loop

                        call NextPosition

                        push si
                        call BoxLine                    ; draw body of Box
                        pop si

                        pop cx                          ; return cx for last loop
                loop next

                call NextPosition

                add si, 3
                call BoxLine

                ret
                endp

;=============================================================================
; Change DI to next position for string
; Entry:        di = location
; Exit:         di = update location
; Destr: AX, DI                                                            !!!
;=============================================================================
NextPosition    proc

                xor bx, bx

                mov bl, [BoxSizeX]
                shl bx, 1
                add di, 80*2
                sub di, bx
                sub di, 4

                ret
                endp

;=============================================================================
; Draws string
; Entry:
;               ah = color
;               di = location
;               si = framestyle symbol
;               es = segment
; Exit: none
; Destr: AX, DI, SI, CX                                                    !!!
;=============================================================================
BoxLine         proc

                lodsb
                stosw

                lodsb

                mov cl, [BoxSizeX]
                rep stosw

                lodsb
                stosw

                ret
                endp

;=============================================================================
; Write Text in the Box
; Entry:        ah = color
;               di = place in video memory
;               es = segment
; Exit: none
; Destr: SI, AX, BX, CL                                                    !!!
;=============================================================================
BoxText         proc

                mov si, offset Text
                call StrLen                             ; cl = strlen (Text)

                push cx

                xor bx, bx

                shr cl, 1
                shl cl, 1

                call ParityLength

                cmp al, 1
                jne even_number

                add cl, 4

                even_number:
                        mov bx, cx

                        mov cl, [BoxSizeX]
                        shr cl, 1
                        shl cl, 1

                        add bx, cx

                        sub di, bx
;======================================
                        push ax
                        push bx

                        xor ax, ax
                        xor bx, bx

                        mov al, [BoxSizeY]
                        shr al, 1
                        shl al, 1

                        sub al, 2
                        mov bx, 80
                        mul bx

                        sub di, ax

                        pop bx
                        pop ax

                pop cx

                string:
                        lodsb
                        stosw
                loop string

                ret
                endp

;=============================================================================
; Count length of string
; Entry:        si = string offset
; Exit:         cl = length of string
; Destr: AL                                                                !!!
;=============================================================================
StrLen          proc

                mov bx, si

                xor cl, cl
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
; Function to check parity Text length
; Entry:        si = string offset
; Exit:         al = 0 - odd number; al = 1 - even number
; Destr: AL                                                                !!!
;=============================================================================
ParityLength    proc

                push cx

                mov si, offset Text
                call StrLen

                and cl, 1
                mov al, cl

                pop cx

                ret
                endp

;=============================================================================
; Function to skip spaces
; Entry:        si = cmd offset
; Exit:         si = first not " ", "\n", "\r" symbol offset
; Destr: DX, SI                                                            !!!
;=============================================================================
SkipSpaces      proc

                inf_loop:
                        mov al, [si]

                        cmp al, " "                     ; space
                        je skip

                        cmp al, 0Ah                     ; \n
                        je skip

                        cmp al, 0Dh                     ; \r
                        je skip

                        cmp al, 0                       ; end of string
                        je  ok

                        jmp ok

                skip:
                        inc si
                        jmp inf_loop

                ok:
                        ret


                ret
                endp

;=============================================================================
; Function atoi from С++
; Entry:        si = cmd offset
; Exit:         ax = result number
; Destr: AX, BX, CL                                                        !!!
;=============================================================================
AtoI            proc

                call SkipSpaces

                xor ax, ax
                xor cx, cx

                runner_but_not_on_the_blade:
                        mov cl, [si]
                        inc si

                        cmp cl, "0"                     ;
                        jb false_case                   ;
                                                        ; if - else in asm :)
                        cmp cl, "9"                     ;
                        ja false_case                   ;

                        mov bx, 10
                        mul bx

                        sub cl, "0"
                        add al, cl                      ; write a number

                        jmp runner_but_not_on_the_blade

                false_case:                             ; else

                ret
                endp


FrameStyle0 db "123456789"
FrameStyle1 db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle2 db  "+-+| |\_/"
FrameStyle3 db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle4 db  218, 196, 191, 179, " ", 179, 192, 196, 217

Text        db "stay hard", "#"

end Lesgo


//              1) use string functions + try consider parity - DONE
//              2) atoi - DONE
// TODO:        3) read from cmd - done, but only one argument
