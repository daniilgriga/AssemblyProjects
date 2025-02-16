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

                call ReadCMD
                push si

                call SizeAnalysis

                pop si
                call BoxBuild
                call BoxText

                mov ah, 4ch                             ; exit
                int 21h


BoxSizeX db  20
BoxSizeY db  10

;=============================================================================
; Function to read cmd arguments
; Entry:
; Exit:
; Destr:                                                             !!!
;=============================================================================
ReadCMD         proc

                mov si, 81h
;===================
                call AtoIDEC

                cmp al, 0
                je lol

                mov [BoxSizeX], al
;===================
                call AtoIDEC

                cmp al, 0
                je lol

                mov [BoxSizeY], al
;===================
                call AtoIHEX

                cmp al, 0
                je lol

                mov ah, al
                push ax
;===================
                call AtoIDEC

                mov si, offset FrameStyle1

                sub al, 1
                mov bx, 9
                mul bx

                add si, ax

                pop ax
                lol:

                ret
                endp


;=============================================================================
; Size of Box analysis
; Entry:
; Exit:
; Destr: AL, CL                                                            !!!
;=============================================================================
SizeAnalysis    proc

                mov si, offset Text
                call StrLen                             ; cl = length of Text

                mov al, [BoxSizeX]
                cmp cl, al                              ; compare

                jbe without_upd                         ; BoxSizeX => length of Text ? nothing : change

                mov [BoxSizeX], cl
                add [BoxSizeX], 10                      ; update size

                without_upd:

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
                                                        ; bx = BoxSizeY * 1/2 * 80 * 2   +   BoxSizeX + StrLen(Text)
                mov si, offset Text
                call StrLen                             ; cl = strlen (Text)

                push cx

                xor bx, bx

                call ParityLength

                cmp al, 0
                je even_number_1

                add bl, 2

                even_number_1:
                        add cl, [BoxSizeX]

                        shr cl, 1
                        shl cl, 1

                        add bl, cl

                        and cl, 1

                        cmp cl, 0
                        je even_number_2

                        add bl, 2

                        even_number_2:
                                sub di, bx

                                push ax
                                xor ax, ax

                                mov al, [BoxSizeY]

                                shr al, 1
                                shl al, 1

                                mov bx, 80
                                mul bx

                                sub di, ax

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

                push bx

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
                        pop bx

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
; Function AtoI for decimal from С++
; Entry:        si = cmd offset
; Exit:         ax = result number
; Destr: AX, BX, CL                                                        !!!
;=============================================================================
AtoIDEC         proc

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

;=============================================================================
; Function AtoI for hexadecimal numbers from С++
; Entry:        si = cmd offset
; Exit:         ax = result number
; Destr: AX, BX, CL                                                        !!!
;=============================================================================
AtoIHEX         proc

                call SkipSpaces

                xor ax, ax
                xor cx, cx

                runner_but_not_on_the_blade_damn:
                        mov cl, [si]
                        inc si

                        cmp cl, "0"                     ;
                        jb next_check                   ;
                                                        ; if - else in asm :)
                        cmp cl, "9"                     ;
                        ja next_check                   ;

                        jmp true_case

                        next_check:
                                cmp cl, "A"
                                jb f_case

                                cmp cl, "F"
                                ja f_case


                        true_case:
                                mov bx, 16
                                mul bx

                                cmp cl, "A"
                                jae symbol

                                sub cl, "0"
                                add al, cl
                                jmp number

                                symbol:
                                        sub cl, "A"
                                        add al, cl

                                number:
                                        jmp runner_but_not_on_the_blade_damn

                f_case:                             ; else

                ret
                endp

FrameStyle1 db "123456789"
FrameStyle2 db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle3 db  "+-+| |\_/"
FrameStyle4 db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle5 db  218, 196, 191, 179, " ", 179, 192, 196, 217

Text        db "stay hard", "#"

end Lesgo


//              1) use string functions + try consider parity - DONE
//              2) AtoIDEC - DONE
//              3) read from cmd - DONE
//              4) text replacement - DONE
//              5) change color from cmd - DONE
//              6) change FrameStyle from cmd - DONE
// TODO:        7) FrameStyle0 - user style
c
