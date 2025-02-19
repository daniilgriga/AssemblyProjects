.model tiny
.code
org 100h

VIDEOSEG        equ 0b800h
START_Y         equ 5*80*2
START_X         equ 10*2
BLINKING_PINK   equ 11011100b

ASCII_NULL      equ "0"
ASCII_NINE      equ "9"
ASCII_A         equ "A"
ASCII_F         equ "F"
ASCII_SPACE     equ " "
ASCII_SL_N      equ 0Ah
ASCII_SL_R      equ 0Dh

F_SCAN_CODE     equ 21h

PlaceInVidSeg 	macro
		        mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X
                mov ah, 97h
	            endm


LessGo:
                xor ax, ax
                mov es, ax
                mov bx, 09h * 4                         ;  IRQ1 interrupt vector address

                mov ax, es:[bx]
                mov Std09off, ax
                mov ax, es:[bx + 2]
                mov Std09seg, ax

                cli                                     ; prevent the processor from executing hardware interrupts (IF = 0)
                mov es:[bx], offset MyInt09h            ; put -offset-

                push cs
                pop  ax

                mov es:[bx + 2], ax                     ; put -segment-
                sti                                     ; set interrupt flag (IF = 1)

                int 09h                                 ; for check that i will be in my func

                mov dx, offset EndOfProgram             ; size to keep resident
                shr dx, 4                               ; :16 (16-byte paragraphs)
                inc dx                                  ; for some situations
                mov ax, 3100h                           ; DOS Fn 31H: Terminate & Stay Resident
                int 21h

;===============================================================================================
; My hardware handler (standard = int 09h)
; Entry: none
; Exit:  none
; Destr: NONE                                                              !!!
;===============================================================================================
MyInt09h        proc

                push ax
                push bx
                push cx
                push dx
                push di
                push si
                push es

                in al, 60h

                cmp al, F_SCAN_CODE
                jne skip_frame


                mov ax, cs
                mov ds, ax

                call BoxBuild

skip_frame:

; ======================== Resetting the keyboard ready flag on port 61h =======================

                in al, 61h
                mov ah, al                              ; save
                or al, 80h                              ; bit mask
                out 61h, al                             ; 0 - enable keyboard, 1 - disable keyboard
                mov al, ah
                out 61h, al

; ==============================================================================================

; ============================= Resetting the interrupt controller =============================

                mov al, 20h                             ; int 21h, ah = 20h - DOS Fn to terminate a .COM program
                out 20h, al                             ; Port 20h - Command register of the 8259 PIC controller,
                                                        ;       which controls hardware interrupt processing

; ==============================================================================================

                pop es
                pop si
                pop di
                pop dx
                pop cx
                pop bx
                pop ax

                db  0eah
Std09off        dw  0
Std09seg        dw  0
                endp


BoxSizeX        equ  20
BoxSizeY        equ  10

;=============================================================================
; Draws box
; Entry:        di = location rn
;
; Exit:  none
; Destr: DI, SI, BX, CX                                                    !!!
;=============================================================================
BoxBuild        proc

                push ax
                push bx
                push cx
                push dx
                push di
                push si
                push es

                PlaceInVidSeg
                mov si, offset FrameStyle1

                call BoxLine

                mov cl, BoxSizeY
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

                pop es
                pop si
                pop di
                pop dx
                pop cx
                pop bx
                pop ax

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

                mov bl, BoxSizeX
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

                mov cl, BoxSizeX
                rep stosw

                lodsb
                stosw

                ret
                endp

FrameStyle1 db "123456789"
FrameStyle2 db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle3 db  "+-+| |\_/"
FrameStyle4 db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle5 db  218, 196, 191, 179, " ", 179, 192, 196, 217

Text        db "stay hard", "#"

EndOfProgram:

end LessGo
