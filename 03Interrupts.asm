.model tiny
.code
org 100h

LessGo:         jmp main


; =================== CONSTANTS ===================
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
R_SCAN_CODE     equ 13h
; =================================================

; ===================== MACROS ====================
PlaceInVidSeg 	macro
		        mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X
	            endm
; =================================================

;===============================================================================================
;===============================================================================================
; My hardware handler (standard = int 09h)
; Entry: none
; Exit:  none
; Destr: NONE                                                                                !!!
;===============================================================================================
;===============================================================================================
MyInt09h        proc

                push ax bx cx dx si di bp sp ds es ss

                mov bx, cs                              ;
                mov ds, bx                              ; install DS on our code segment

                in al, 60h

                push ax
                cmp al, F_SCAN_CODE
                jne skip_frame

                mov ah, [CLR_FROM_CMD]
                mov si, [SI_FROM_CMD]
                call BoxBuild
skip_frame:
                pop ax
                cmp al, R_SCAN_CODE
                jne skip_remove

                mov ah, 0h
                mov si, offset FrameStyleC
                call BoxBuild
skip_remove:

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

                pop ss es ds sp bp di si dx cx bx ax

                db  0eah
Std09off        dw  0
Std09seg        dw  0

                endp

;===============================================================================================
BoxSizeX        db  20
BoxSizeY        db  10

SI_FROM_CMD     dw 0
CLR_FROM_CMD    db 0
;===============================================================================================

;===============================================================================================
;===============================================================================================
; Function to read cmd arguments
; Entry:
; Exit:         ah = color
;               cx = offset FrameStyle
;               dx = offset string for frame
; Destr: AX, BX, CX, DX, SI                                                                  !!!
;===============================================================================================
;===============================================================================================
ReadCMD         proc

                mov si, 81h

;=================== first argument = BoxSizeX

                call AtoIDEC

                cmp al, 0
                je lol

                mov [BoxSizeX], al

;=================== second argument = BoxSizeY

                call AtoIDEC

                cmp al, 0
                je lol

                mov [BoxSizeY], al

;=================== third argument = color

                call AtoIHEX

                cmp al, 0
                je lol

                mov ah, al
                mov [CLR_FROM_CMD], ah

;=================== fourth argument = FrameStyle

                push ax
                call AtoIDEC

                cmp al, 0
                jne jump

                mov cx, si
                add si, 9                       ; 9 = length of FrameStyle

                jmp skip_std_style

jump:
                mov cx, offset FrameStyle1

                sub al, 1
                mov bx, 9
                mul bx

                add cx, ax
                mov [SI_FROM_CMD], cx

;=================== fifth argument = text for frame

skip_std_style:
                pop ax

                call SkipSpaces

                mov dx, si

lol:

                ret
                endp

;===============================================================================================
;===============================================================================================
; Draws box
; Entry:        di = location rn
;
; Exit:  none
; Destr: DI, SI, BX, CX                                                                      !!!
;===============================================================================================
;===============================================================================================
BoxBuild        proc

                PlaceInVidSeg

                call BoxLine

                xor cx, cx
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


;===============================================================================================
;===============================================================================================
; Change DI to next position for string
; Entry:        di = location
; Exit:         di = update location
; Destr: AX, DI                                                                              !!!
;===============================================================================================
;===============================================================================================
NextPosition    proc

                push bx

                xor bx, bx
                mov bl, [BoxSizeX]
                shl bx, 1
                add di, 80*2
                sub di, bx

                pop bx

                ret
                endp


;===============================================================================================
;===============================================================================================
; Draws string
; Entry:
;               ah = color
;               di = location
;               si = framestyle symbol
;               es = segment
; Exit: none
; Destr: AX, DI, SI, CX                                                                      !!!
;===============================================================================================
;===============================================================================================
BoxLine         proc

                push cx
                xor cx, cx

                lodsb
                stosw

                lodsb


                mov cl, [BoxSizeX]
                sub cl, 2
                rep stosw

                lodsb
                stosw

                pop cx

                ret
                endp

;===============================================================================================
FrameStyle1 db "123456789"
FrameStyle2 db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle3 db  "+-+| |\_/"
FrameStyle4 db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle5 db  218, 196, 191, 179, " ", 179, 192, 196, 217
FrameStyleC db  "         "
;===============================================================================================

EndOfProgram:

;===============================================================================================
;===============================================================================================
; Function to skip spaces
; Entry:        si = cmd offset
; Exit:         si = first not " ", "\n", "\r" symbol offset
; Destr: DX, SI                                                                              !!!
;===============================================================================================
;===============================================================================================
SkipSpaces      proc

inf_loop:
                mov al, [si]

                cmp al, " "                     ; space
                je skip

                cmp al, ASCII_SL_N              ; \n
                je skip

                cmp al, ASCII_SL_R              ; \r
                je skip

                cmp al, 0                       ; end of string
                je  ok

                jmp ok

skip:
                inc si
                jmp inf_loop

ok:

                ret
                endp

;===============================================================================================
;===============================================================================================
; Function AtoI for decimal from С++
; Entry:        si = cmd offset
; Exit:         ax = result number
; Destr: AX, BX, CL                                                                          !!!
;===============================================================================================
;===============================================================================================
AtoIDEC         proc

                call SkipSpaces

                xor ax, ax
                xor cx, cx

runner_but_not_on_the_blade:
                mov cl, [si]
                inc si

                cmp cl, ASCII_NULL
                jb false_case

                cmp cl, ASCII_NINE
                ja false_case

                mov bx, 10
                mul bx

                sub cl, ASCII_NULL
                add al, cl                      ; write a number

                jmp runner_but_not_on_the_blade

                false_case:                     ; else

                ret
                endp
;===============================================================================================
;===============================================================================================
; Function AtoI for hexadecimal numbers from С++
; Entry:        si = cmd offset
; Exit:         ax = result number
; Destr: AX, BX, CL                                                                          !!!
;===============================================================================================
;===============================================================================================
AtoIHEX         proc

                call SkipSpaces

                xor ax, ax
                xor cx, cx

runner_but_not_on_the_blade_damn:
                mov cl, [si]
                inc si

                cmp cl, ASCII_NULL
                jb next_check

                cmp cl, ASCII_NINE
                ja next_check

                jmp true_case

next_check:
                cmp cl, ASCII_A
                jb f_case

                cmp cl, ASCII_F
                ja f_case


true_case:
                mov bx, 16
                mul bx

                cmp cl, ASCII_A
                jae symbol

                sub cl, ASCII_NULL
                add al, cl
                jmp number

symbol:
                sub cl, ASCII_A
                add al, cl

number:
                jmp runner_but_not_on_the_blade_damn

f_case:

                ret
                endp

main:
                call ReadCMD

                xor ax, ax                              ;
                mov es, ax                              ;
                mov bx, 09h * 4                         ;  IRQ1 (Interrupt Request) vector address

                mov ax, es:[bx]                         ;
                mov Std09off, ax                        ;
                mov ax, es:[bx + 2]                     ;
                mov Std09seg, ax                        ; saving the address of the standard 09h interrupt

                cli                                     ; prevent the processor from executing hardware interrupts (IF = 0)
                mov es:[bx], offset MyInt09h            ; put -offset-

                push cs
                pop  ax

                mov es:[bx + 2], ax                     ; put -segment-
                sti                                     ; set interrupt flag (IF = 1)

                mov dx, offset EndOfProgram             ; size to keep resident
                shr dx, 4                               ; :16 (16-byte paragraphs)
                inc dx                                  ; for some situations
                mov ax, 3100h                           ; DOS Fn 31H: Terminate & Stay Resident
                int 21h

end             LessGo
