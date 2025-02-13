.model tiny
.code
org 100h

VIDEOSEG equ 0b800h

Lesgo:          mov bx, VIDEOSEG
                mov es, bx
                mov di, 5*80*2 + 20*2

                call SizeAnalysis

                call BoxBuild

                call BoxText

                mov ah, 4ch                             ; exit
                int 21h

BoxSizeX db  20
BoxSizeY equ 10

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

                jbe lol                                 ; BoxSizeX => length of Text ? nothing : change

                mov [BoxSizeX], cl
                add [BoxSizeX], 8                       ; update size

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

                mov si, offset FrameStyle3              ; addr FrameStyle1 in si

                mov ah, 1011100b
                call BoxLine

                mov cl, BoxSizeY - 2
                next:
                        mov dx, cx                      ; save cx for last loop

                        call NextPosition

                        push si
                        call BoxLine                    ; draw body of Box
                        pop si

                        mov cx, dx                      ; return cx for last loop
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
; Entry:        ;ah = color
;               di = place in video memory
;               es = segment
; Exit: none
; Destr: SI, AX, BX, CL                                                    !!!
;=============================================================================
BoxText     proc

            mov si, offset Text
            call StrLen                                 ; cl = strlen (Text)

            xor bx, bx

            mov al, cl
            shr al, 1
            shl al, 1

            mov bx, ax

            mov al, [BoxSizeX]
            shr al, 1
            shl al, 1

            add bx, ax
            add bx, 80*(BoxSizeY - 2)

            sub di, bx

            string:                                     ; write a Text (using cx for loop)
                    mov al, [si]
                    mov byte ptr es:[di], al

                    add di, 2
                    add si, 1
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

FrameStyle1 db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle2 db  "+-+| |\_/"
FrameStyle3 db    3,   3,   3,   3, " ",   3,   3,   3,   3

Text        db "damir loxx", "#"

end Lesgo


// TODO:        1) use string functions
//              2) atoi
//              3) read from cmd
