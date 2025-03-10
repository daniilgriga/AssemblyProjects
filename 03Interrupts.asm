.model tiny
.code
org 100h

LessGo:         jmp Main


; =================== CONSTANTS ===================
LENGTH_SCREEN   equ 80*2

VIDEOSEG        equ 0b800h

START_Y         equ 1*LENGTH_SCREEN
START_X         equ LENGTH_SCREEN - 10*2

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
T_SCAN_CODE     equ 14h

    ACTIVE      equ 1
NOT_ACTIVE      equ 0
; =================================================

; ===================== MACROS ====================
PlaceInVidSeg 	macro
		        mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X
	            endm

PlaceInVidSeg 	macro
		        mov bx, VIDEOSEG
                mov es, bx
                mov di, START_Y + START_X
	            endm

GetDS       macro
                mov bx, cs                              ;
                mov ds, bx                              ; get DS on our code segment
                endm
; =================================================

;===============================================================================================
;===============================================================================================
; My hardware handler (standard = int 08h)
; Entry: none
; Exit:  none
; Destr: NONE                                                                                !!!
;===============================================================================================
;===============================================================================================
MyInt08h        proc

                push ss es ds sp bp di si dx cx bx ax

                GetDS

                cmp [OutputStatus], ACTIVE
                jne skip_timer

                cmp [TimerStatus], ACTIVE
                jne skip_timer

                call ReopenScreen
                call SaveScreen

                mov ah, [COLOR_FROM_CMD]
                mov si, [SI_FROM_CMD]
                call BoxBuild
                call PrintRegisters

skip_timer:
                mov al, 20h
                out 20h, al

                pop ax bx cx dx si di bp sp ds es ss

                db  0eah                                ; far jmp on standard 08h interrupt
Std08off        dw  0
Std08seg        dw  0

                endp

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

                GetDS

                xor ax, ax

                in al, 60h

                cmp al, F_SCAN_CODE
                je draw_data
                cmp al, D_SCAN_CODE
                je remove_data
                cmp al, T_SCAN_CODE
                je timer

                jmp skip_that_sh

draw_data:
                cmp [OutputStatus], ACTIVE
                je skip_that_sh

                call SaveScreen

                mov ah, [COLOR_FROM_CMD]
                mov si, [SI_FROM_CMD]

                call BoxBuild
                call PrintRegisters

                mov [OutputStatus], ACTIVE
                jmp end_int

remove_data:
                cmp [OutputStatus], NOT_ACTIVE
                je skip_that_sh

                call ReopenScreen

                mov [OutputStatus], NOT_ACTIVE
                jmp end_int

timer:
                xor [TimerStatus], ACTIVE
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
                                               ; far jmp on standard 09h interrupt
Std09off        dw  0
Std09seg        dw  0

                endp

;===============================================================================================
BoxSizeX        db  10
BoxSizeY        db  15

SI_FROM_CMD     dw  offset FrameStyle5
COLOR_FROM_CMD  db  57h

OutputStatus    db  0
TimerStatus     db  0
;===============================================================================================

;===============================================================================================
;===============================================================================================
; Draws box
; Entry:        ah = color
;               si = offset style
;               di = location rn
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
                sub cl, 2                               ; remove first and last rows
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
                add di, LENGTH_SCREEN
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
                add di, LENGTH_SCREEN + 1*2
                mov cx, 13                              ; output 11 registers for now...
Reg:
                push cx di

                mov cx, 3                               ; length of str with reg is 3 symbols (AX:)
RegOutput:
                lodsb                                   ;
                stosw                                   ;
                loop RegOutput                          ;                               STACK
                                                        ; I----------I----------I----------I----------I----------I- - - - -
                mov bx, ss:[bp + 4]                     ; I          I          I          I          I          I
                add bp, 2                               ; I    DX    I    CX    I    BP    I ret.addr I    AX    I   BX
                call PrintRegValues                     ; I          I          I          I          I          I
                                                        ; I----------I----------I----------I----------I----------I- - - - -
                pop di cx                               ;      ^                     ^          ^          ^
                                                        ;     SP                    BP       BP + 2     BP + 4
                add di, LENGTH_SCREEN                   ;
                loop Reg

                pop bp

                ret
                endp

;===============================================================================================
;===============================================================================================
; Print Registers value in video memory (RAM)
; Entry:        bx = registers value
; Exit:
; Destr: CX, DX, AX                                                                          !!!
;===============================================================================================
;===============================================================================================

PrintRegValues  proc

                push si

                mov si, offset RegValBuffer             ; temporary buffer
                mov byte ptr [si], "h"                  ; HEX
                inc si

                mov cx, 4
hex_convert:
                mov dx, bx
                and dx, 0Fh                             ; low 4 bits
                cmp dx, 9                               ; check for numbers
                jle numero

                add dx, 7                               ; if its not a number -> +7 for ASCII 'A' (need + '0')

numero:
                add dx, ASCII_NULL
                mov [si], dl
                inc si
                shr bx, 4                               ; shift for next 4 bits
                loop hex_convert

                mov cx, 5                               ; 4 numbers + 1 "h"

turn_up_loop:
                mov al, [si]                            ; turn up a value and output from temporary buffer to RAM
                stosw
                dec si
                loop turn_up_loop

                pop si

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

                GetDS
                PlaceInVidSeg

                mov si, offset ScreenBuffer             ; temporary buffer for save screen

                xor cx, cx
                mov cl, [BoxSizeY]
save_process_row:
                push cx
                push di

                xor cx, cx
                mov cl, [BoxSizeX]

save_process_str:
                mov ax, es:[di]                         ; from RAM
                mov [si], ax                            ; to temporary buffer
                add di, 2
                add si, 2
                loop save_process_str

                pop di
                add di, LENGTH_SCREEN

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

                GetDS
                PlaceInVidSeg

                mov si, offset ScreenBuffer

                xor cx, cx
                mov cl, [BoxSizeY]

reopen_process_row:
                push cx
                push di

                xor cx, cx
                mov cl, [BoxSizeX]

reopen_process_str:
                mov ax, [si]                                ; from temporary buffer
                mov es:[di], ax                             ; to RAM
                add di, 2
                add si, 2
                loop reopen_process_str

                pop di
                add di, LENGTH_SCREEN

                pop cx
                loop reopen_process_row

                ret
                endp

;===============================================================================================
RegisterNames   db  "AX:", "BX:", "CX:", "DX:", "SI:", "DI:", "BP:", "SP:", "DS:", "ES:", "SS:", "IP:", "CS:"

FrameStyle1     db  "123456789"
FrameStyle2     db  201, 205, 187, 186, " ", 186, 200, 205, 188
FrameStyle3     db  "+-+| |\_/"
FrameStyle4     db    3,   3,   3,   3, " ",   3,   3,   3,   3
FrameStyle5     db  218, 196, 191, 179, " ", 179, 192, 196, 217
FrameStyleC     db  "         "

RegValBuffer    db 5    dup (0)
ScreenBuffer    dw 150  dup (0)
BackgrBuffer    dw 150  dup (0)
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

                mov [COLOR_FROM_CMD], al

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

                cmp al, ASCII_SPACE                     ; space
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

;===============================================================================================
;============================================ MAIN =============================================
;===============================================================================================

Main:
                call ReadCMD

                xor ax, ax
                mov es, ax

                mov bx, 08h * 4                         ; IRQ0 (Interrupt Request) vector address

                mov ax, es:[bx]                         ;
                mov Std08off, ax                        ;
                mov ax, es:[bx + 2]                     ;
                mov Std08seg, ax                        ; saving the address of the standard 08h interrupt

                cli                                     ; prevent the processor from executing hardware interrupts (IF = 0)
                mov es:[bx], offset MyInt08h            ; put -offset-
                push cs
                pop  ax
                mov es:[bx + 2], ax                     ; put -segment-
                sti                                     ; set interrupt flag (IF = 1)

                mov bx, 09h * 4                         ;  IRQ1 (Interrupt Request) vector address

                mov ax, es:[bx]                         ;
                mov Std09off, ax                        ;
                mov ax, es:[bx + 2]                     ;
                mov Std09seg, ax                        ; saving the address of the standard 09h interrupt

                cli
                mov es:[bx], offset MyInt09h
                push cs
                pop  ax
                mov es:[bx + 2], ax
                sti

                mov dx, offset SavePoint                ; size to keep resident
                shr dx, 4                               ; :16 (16-byte paragraphs)
                inc dx                                  ; for some situations
                mov ax, 3100h                           ; DOS Fn 31H: Terminate & Stay Resident
                int 21h

;===============================================================================================
;===============================================================================================
;===============================================================================================

end             LessGo
