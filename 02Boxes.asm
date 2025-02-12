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

                mov ah, 4ch                                 ; exit
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
                add [BoxSizeX], 4                       ; update size

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
BoxBuild    proc

            mov si, offset FrameStyle2                  ; addr FrameStyle1 in si
            call BoxLine

            add si, 3                                   ; go to next trio of symbols

            mov cl, BoxSizeY - 2
            next:
                    mov dx, cx                          ; save cx for last loop

                    call NextPosition
                    call BoxLine                        ; draw body of Box

                    mov cx, dx                          ; return cx for last loop
            loop next

            add si, 3                                   ; go to next trio of symbols
            call NextPosition
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

                mov al, [BoxSizeX]
                shl ax, 1
                add di, 80*2
                sub di, ax
                sub di, 2

                ret
                endp

;=============================================================================
; Draws string
; Entry:        di = location
;               si = framestyle offset
;               es = segment
;
; Exit: none
; Destr: AL, DI, SI, CX                                                    !!!
;=============================================================================
BoxLine     proc

            mov al, [si]                                ; symbol ASCII in al now
            mov byte ptr es:[di], al                    ; write symbol

            mov cl, [BoxSizeX]                          ; length of Box
            go:
                    add di, 2                           ; skip attribute bite
                    mov al, [si + 1]                    ; ASCII in al now
                    mov byte ptr es:[di], al            ; write symbol
            loop go

            add di, 2                                   ; skip attribute bite
            mov al, [si + 2]                            ; ASCII in al now
            mov byte ptr es:[di], al                    ; write symbol

            ret
            endp

;=============================================================================
; Write Text in the Box
; Entry:    di = place in video memory
;           es = segment
; Exit: none
; Destr: SI, AX, BX, CL                                                     !!!
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
; Entry: si = string offset
; Exit:  cl = length of string
; Destr: AL                                                                !!!
;=============================================================================
StrLen      proc

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

Text        db "David Goggins once said: stay hard", "#"

end Lesgo
