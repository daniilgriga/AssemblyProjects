.model tiny
.code
org 100h

LessGo:         jmp Main


; =================== CONSTANTS ===================
VIDEOSEG        equ 0b800h
START_Y         equ 1*80*2
START_X         equ (80 - 10)*2

STD_COLOR       equ 52h

ASCII_NULL      equ "0"
ASCII_NINE      equ "9"
ASCII_A         equ "A"
ASCII_F         equ "F"
ASCII_SPACE     equ " "
ASCII_SL_N      equ 0Ah
ASCII_SL_R      equ 0Dh

F_SCAN_CODE     equ 21h
D_SCAN_CODE     equ 20h
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

                push ss es ds sp bp di si dx cx bx ax

                mov bx, cs                              ;
                mov ds, bx                              ; install DS on our code segment

                xor ax, ax

                in al, 60h

                cmp al, F_SCAN_CODE
                je draw_frame
                cmp al, D_SCAN_CODE
                je remove
                jmp skip_that_sh

draw_frame:
                cmp [OutputStatus], 1
                je skip_that_sh

                call SaveScreen

                mov ah, [CLR_FROM_CMD]
                mov si, [SI_FROM_CMD]

                call BoxBuild

                call PrintRegisters

                mov [OutputStatus], 1
                jmp end_int

remove:
                cmp [OutputStatus], 0
                je skip_that_sh

                call ReopenScreen
                mov [OutputStatus], 0
                jmp end_int

skip_that_sh:
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
end_int:
                pop ax bx cx dx si di bp sp ds es ss

                db  0eah
Std09off        dw  0
Std09seg        dw  0

                endp

;===============================================================================================
BoxSizeX        db  10
BoxSizeY        db  13

SI_FROM_CMD     dw  offset FrameStyle5
CLR_FROM_CMD    db  57h

OutputStatus    db  0
CtrlSetStatus   db  0
;===============================================================================================

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
                push cx                                 ; save cx for last loop

                call NextPosition

                push si
                call BoxLine                            ; draw body of Box
                pop si

                pop cx                                  ; return cx for last loop
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
;===============================================================================================
; Print Register names in video memory (RAM)
; Entry:
; Exit:
; Destr: SI, DI, CX, BX, SP                                                                  !!!
;===============================================================================================
;===============================================================================================
PrintRegisters  proc

                push bp
                mov bp, sp

                PlaceInVidSeg
                mov si, offset RegisterNames
                add di, 80*2 + 1*2
                mov cx, 11                              ; output 11 registers for now...
Reg:
                push cx di

                mov cx, 3                               ; length of str with reg is 3 symbols (AX:)
RegOutput:
                lodsb
                stosw
                loop RegOutput

                mov bx, ss:[bp + 2]
                add bp, 2
                call PrintRegValues

                pop di cx

                add di, 80*2
                loop Reg

                pop bp

                ret
                endp

;===============================================================================================
;===============================================================================================
; Print Registers value in video memory (RAM)
; Entry:
; Exit:
; Destr: CX, DX, AX                                                                          !!!
;===============================================================================================
;===============================================================================================
PrintRegValues  proc

                mov cx, 4
hex_convert:
                mov dx, bx
                and dx, 0Fh

                cmp dx, 9
                jle numero

                add dx, 7
numero:
                add dx, "0"

                mov al, dl
                stosw
                shr bx, 4
                loop hex_convert

                mov byte ptr es:[di], "h"

                ret
                endp

;===============================================================================================
;===============================================================================================
; Func that saving teh current screen
; Entry:
; Exit:
; Destr: CX, DX, AX                                                                          !!!
;===============================================================================================
;===============================================================================================
SaveScreen      proc

                mov ax, cs
                mov ds, ax

                PlaceInVidSeg
                mov si, offset ScreenBuffer
                mov cx, 13
save_process_row:
                push cx
                push di

                mov cx, 10

save_process_str:
                mov ax, es:[di]
                mov [si], ax
                add di, 2
                add si, 2
                loop save_process_str

                pop di
                add di, 80*2

                pop cx
                loop save_process_row

                ret
                endp

;===============================================================================================
;===============================================================================================
; Reopen screen, that was saved
; Entry:
; Exit:
; Destr: AX, CX, DI, SI                                                                      !!!
;===============================================================================================
;===============================================================================================
ReopenScreen    proc

                mov ax, cs
                mov ds, ax

                PlaceInVidSeg
                mov si, offset ScreenBuffer

                mov cx, 13

reopen_process_row:
                push cx
                push di

                mov cx, 10

reopen_process_str:
                mov ax, [si]
                mov es:[di], ax
                add di, 2
                add si, 2
                loop reopen_process_str

                pop di
                add di, 80*2

                pop cx
                loop reopen_process_row

                ret
                endp

;===============================================================================================
RegisterNames   db  "AX:", "BX:", "CX:", "DX:", "SI:", "DI:", "BP:", "SP:", "DS:", "ES:", "SS:"

FrameStyle1     db  "123456789"
FrameStyle2     db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle3     db  "+-+| |\_/"
FrameStyle4     db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle5     db  218, 196, 191, 179, " ", 179, 192, 196, 217
FrameStyleC     db  "         "

ScreenBuffer    dw 130 dup (0)
;===============================================================================================

SavePoint:

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

                mov [CLR_FROM_CMD], al

;=================== fourth argument = FrameStyle

                push ax
                call AtoIDEC

                cmp al, 0
                jne jump

                mov cx, si
                add si, 9                               ; 9 = length of FrameStyle

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
; Function to skip spaces
; Entry:        si = cmd offset
; Exit:         si = first not " ", "\n", "\r" symbol offset
; Destr: DX, SI                                                                              !!!
;===============================================================================================
;===============================================================================================
SkipSpaces      proc

inf_loop:
                mov al, [si]

                cmp al, " "                             ; space
                je skip

                cmp al, ASCII_SL_N                      ; \n
                je skip

                cmp al, ASCII_SL_R                      ; \r
                je skip

                cmp al, 0                               ; end of string
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
                add al, cl                              ; write a number

                jmp runner_but_not_on_the_blade

                false_case:                             ; else

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

Main:
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

                mov dx, offset SavePoint             ; size to keep resident
                shr dx, 4                               ; :16 (16-byte paragraphs)
                inc dx                                  ; for some situations
                mov ax, 3100h                           ; DOS Fn 31H: Terminate & Stay Resident
                int 21h

end             LessGo
