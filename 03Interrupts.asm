.model tiny
.code
org 100h

VIDEOSEG        equ 0b800h
START_Y         equ 5*80*2
START_X         equ 20*2

PlaceInVidSeg 	macro
		        mov bx, VIDEOSEG
                mov es, bx
                mov bx, START_Y + START_X
                mov ah, 95h
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

                ;int 09h                                 ; for check that i will be in my func

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
                push es
                push ds

                PlaceInVidSeg

                in al, 60h
                mov es:[bx], ax                         ; in RAM 'value' of port 60h

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

                pop ds
                pop es
                pop bx
                pop ax

                db  0eah
Std09off        dw  0
Std09seg        dw  0

                endp

EndOfProgram:

end LessGo
