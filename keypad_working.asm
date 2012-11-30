$MOD186
$EP
NAME TIMER
; Main program for uPD70208 microcomputer system
;
; Author: 	Dr Tay Teng Tiow
; Address:     	Department of Electrical Engineering 
;         	National University of Singapore
;		10, Kent Ridge Crescent
;		Singapore 0511.	
; Date:   	6th September 1991
;
; This file contains proprietory information and cannot be copied 
; or distributed without prior permission from the author.
; =========================================================================

public	serial_rec_action, timer0_action, timer1_action, timer2_action
extrn	print_char:far, print_2hex:far, iodefine:far
extrn   Set_timer0:far, Set_timer1:far, Set_timer2:far

STACK_SEG	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	MAIN_MESS   DB  10,13,'Main Loop           '
	TIMER0_MESS	DB	10,13,'TIMER0 INTERRUPT    '
	TIMER1_MESS	DB	10,13,'TIMER1 INTERRUPT    '
	TIMER2_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	KEY_PRESSED DB  10,13,'KEY PRESSED         '
	
	; -- define messages for other timers

	T0_COUNT		DB	2FH
	T0_COUNT_SET	DB	2FH
	T1_COUNT		DB	2FH
	T1_COUNT_SET	DB	2FH
	T2_COUNT		DB	2FH
	T2_COUNT_SET	DB	2FH

	LED_SELECT  DB  0FEH
	NUMBERS		DB	03FH, 006H, 05BH, 04FH, 066H, 06DH, 07DH, 007H, 07FH, 06FH
	CURRENT_NUMBER DB 00H
	BARCODE		DB  00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
	;BARCODE		DB  03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH
	BARCODE_I	DB 00H
	KEYPAD_CURRENT_ROW DB 00H
	KEYPAD_ROW	DB 0FEH;

	REC_MESS	DB	10,13,'Period of timer0 =     '



DATA_SEG	ENDS

;------------------------------------------
;--CHIP SELECTS
; 8255 register addresses
; PCS1
IC8255_PORTA_ADDR EQU 80H;
IC8255_PORTB_ADDR EQU 81H;
IC8255_PORTC_ADDR EQU 82H;
IC8255_CW_ADDR    EQU 83H;

PCS2_ADDR EQU 100H
PCS3_ADDR EQU 180H
PCS4_ADDR EQU 200H
	


;-------------------------------------------

CODE_SEG	SEGMENT

	PUBLIC		START

ASSUME	CS:CODE_SEG, SS:STACK_SEG, DS:DATA_SEG

START:

;initialize stack area
		MOV	AX, STACK_SEG		
		MOV	SS, AX
		MOV	SP, TOS

		MOV AX, DATA_SEG
		MOV DS, AX

; Initialize the on-chip pheripherals
		CALL	FAR PTR	IODEFINE
		
	;KEYPAD INIT

	MOV DX, IC8255_CW_ADDR

	;CW Register 
	;Port C Lower Input, Port C Upper Output 
	;Port B input, Port A output
	;1 0 0 0 0 0 1 0

	MOV AL, 82H
	OUT DX, AL

; Initialize MCS


;This procedure generates 10ms delay at 5MHz
;operating frequency, which corresponds to 
;50,000 clock cycles.
;DEBOUNCE PROC	NEAR
;	PUSH	CX
;	MOV CX, 094Ch ; 2380 dec
;	BACK:		
;		NOP	  ; 3 clocks
;	LOOP BACK; 18 clocks
;	POP CX
;	RET
;DEBOUNCE ENDP

; ^^^^^^^^^^^^^^^^^  Start of User Main Routine  ^^^^^^^^^^^^^^^^^^
    ;call Set_timer0
	;call Set_timer1
	call Set_timer2
      STI

NEXT:     
;BEGIN MAIN LOOP
	;slowing down the main loop
	MOV CX, 05FFFH ; 2380 dec
	SLEEP:
		NOP
	LOOP SLEEP; 18 clocks

	;MOV AL, 01H ;Printing 1 to check the start of main loop
	;CALL FAR PTR PRINT_2HEX

	;PUSH AX
	;MOV AL, 0AH ;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH ;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR
	;POP AX

	XOR AX, AX
	ROL KEYPAD_ROW, 01H
	CMP KEYPAD_ROW, 77H
	JE RESET_KEYPAD_ROW
	JNZ CHECK_KEYPAD_ROW

RESET_KEYPAD_ROW:
	MOV KEYPAD_ROW, 0EH

CHECK_KEYPAD_ROW:
	MOV AL, KEYPAD_ROW
	MOV DX, IC8255_PORTC_ADDR	;DX = Port B Address
	OUT DX, AL					;
	MOV DX, IC8255_PORTB_ADDR	;

CHECK_KEY_CLOSED:	 			;Check when key is pressed. Keep looping here
	IN AL, DX					;Move to AL, value in Port B. 
	CMP AL, 00H
	JE NEXT
	CMP AL, 03FH
	JE NEXT
	CMP AL, 0FFH
	JE NEXT
	CMP AL, 0BFH
	JE NEXT
	CMP AL, 07FH
	JE NEXT
	CMP AL, 0FH
	JE NEXT

	;ANGAD'S SMARTASS HASHING ALGO
	AND AL, KEYPAD_ROW
	
	;PUSH AX
	;CALL FAR PTR PRINT_2HEX
	;MOV AL, 0AH ;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH ;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR
	;POP AX

	;KEY 1
	CMP AL, 0F3H
	JE K1

	;KEY 2
	CMP AL, 0F5H
	JE K2

	;KEY 3
	CMP AL, 0F6H
	JE K3

	;KEY 4
	CMP AL, 0FBH
	JE K4

	;KEY 5 & 7
	CMP AL, 0F9H
	JE K5

	;KEY 6 & *
	CMP AL, 0FAH
	JE K6

	;KEY 8
	CMP AL, 0FDH
	JE K8

	;KEY 9 & 0
	CMP AL, 0FCH
	JE K9
	JNE NEXT

K1:
	XOR BX, BX
	MOV BL, 01H
	JMP ADD_BARCODE

K2:
	XOR BX, BX
	MOV BL, 02H
	JMP ADD_BARCODE

K3:
	XOR BX, BX
	MOV BL, 03H
	JMP ADD_BARCODE
	
K4:
	XOR BX, BX
	MOV BL, 04H
	JMP ADD_BARCODE
K5:
	XOR BX, BX
	MOV AL, KEYPAD_ROW
	CMP AL, 0FDH
	JE K7
	MOV BL, 05H
	JMP ADD_BARCODE

K6:
	XOR BX, BX
	MOV AL, KEYPAD_ROW
	CMP AL, 0FEH
	JE K_STAR
	MOV BL, 06H
	JMP ADD_BARCODE
K7:
	XOR BX, BX
	MOV BL, 07H
	JMP ADD_BARCODE

K8:
	XOR BX, BX
	MOV BL, 08H
	JMP ADD_BARCODE

K9:
	XOR BX, BX
	MOV AL, KEYPAD_ROW
	CMP AL, 0FEH
	JE K0
	MOV BL, 09H
	JMP ADD_BARCODE

K0: 
	XOR BX, BX
	MOV BL, 00H
	JMP ADD_BARCODE

K_STAR:
	XOR BX, BX
	MOV CX, 08H
	CLEAR_BARCODE:
		MOV BX, CX
		DEC BX
		MOV BARCODE[BX], 00H
	LOOP CLEAR_BARCODE
	MOV BARCODE_I, 00H
	JMP NEXT
	
K_HASH:
	XOR BX, BX
	MOV BL, 0AH
	JMP ADD_BARCODE

ADD_BARCODE:
	MOV AL, NUMBERS[BX]
	MOV BL, BARCODE_I
	MOV BARCODE[BX], AL
	INC BARCODE_I
	JMP NEXT

JMP NEXT

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^


SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS

		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX

		CMP	AL,'<'
		JNE	S_FAST

		INC	DS:T0_COUNT_SET
		INC	DS:T0_COUNT_SET
		
		;MOV DX, IC8255_PORTA_ADDR
		;MOV AL, 0FFH
		;OUT DX, AL

		JMP	S_NEXT0
S_FAST:
		CMP	AL,'>'
		JNE	S_RET

		DEC	DS:T0_COUNT_SET
		DEC	DS:T0_COUNT_SET

S_NEXT0:
		MOV	CX,22			;initialize counter for message
		MOV	BX,0

S_NEXT1:	MOV	AL,DS:REC_MESS[BX]	;print message
		call	FAR ptr print_char
		INC	BX
		LOOP	S_NEXT1

		MOV	AL,DS:T0_COUNT_SET	;print current period of timer0
		CALL	FAR PTR PRINT_2HEX
S_RET:
		POP	DS
		POP	BX
		POP	CX
		RET
SERIAL_REC_ACTION	ENDP


;--------------------------------------------------------------

;--------------------TIMER 0 ----------------------------------

TIMER0_ACTION	PROC	FAR
		PUSH	AX
		PUSH	DS
		PUSH	BX
		PUSH	CX

	XOR AX,AX
	XOR BX,BX

	MOV	AX,DATA_SEG
	MOV	DS,AX
	
	DEC	DS:T0_COUNT
	JNZ	T0_NEXT1
	MOV	AL,DS:T0_COUNT_SET
	MOV	DS:T0_COUNT,AL

	MOV	CX,20
	MOV	BX,0H


T0_NEXT1:	
		POP	CX
		POP	BX
		POP	DS
		POP 	AX
		RET
TIMER0_ACTION	ENDP

;--------------------------------------------------------------

;--------------------TIMER 1 ----------------------------------


TIMER1_ACTION	PROC	FAR
		PUSH	AX
		PUSH	DS
		PUSH	BX
		PUSH	CX

		MOV	AX,DATA_SEG
		MOV	DS,AX
	
		DEC	DS:T1_COUNT
		JNZ	T1_NEXT1
		MOV	AL,DS:T1_COUNT_SET
		MOV	DS:T1_COUNT,AL

		MOV	CX,20
		MOV	BX,0H
T1_NEXT0:
		MOV	AL,DS:TIMER1_MESS[BX]
		INC	BX
		CALL 	FAR PTR PRINT_CHAR
		LOOP	T1_NEXT0

T1_NEXT1:	
		POP	CX
		POP	BX
		POP	DS
		POP 	AX
		RET
TIMER1_ACTION	ENDP

;--------------------------------------------------------------

;--------------------TIMER 2 ----------------------------------


TIMER2_ACTION	PROC	FAR
		PUSH	AX
		PUSH	DS
		PUSH	BX
		PUSH	CX



		XOR AX, AX
		XOR BX, BX
		
		
;----------------------------
		;AD0 - AD5 PCS3 CS for 7-segment
		;7  6  5  4  3  2  1  0
		;x  x  A5 A4 A3 A2 A1 A0
		MOV DX, PCS3_ADDR
		MOV AL, LED_SELECT
		;MOV AL, 00111110B
		OUT DX, AL
		ROL LED_SELECT, 01H

		;AD0 - AD7 PCS2
		;AD7 - DOT (MSB)
		
		MOV DX, PCS2_ADDR
		MOV BL, CURRENT_NUMBER
		MOV AL, BARCODE[BX]
		;MOV AL, 01111111B
		OUT DX, AL
		INC CURRENT_NUMBER
		CMP CURRENT_NUMBER, 08H
		JE RESET_CURRENT
		JNE T2_NEXT1
;---------------------------
		DEC	DS:T2_COUNT
		JNZ	T2_NEXT1
		MOV	AL,DS:T2_COUNT_SET
		MOV	DS:T2_COUNT,AL
		MOV	BX,0H
		
RESET_CURRENT:
		MOV CURRENT_NUMBER, 00H
		DEC	DS:T2_COUNT
		JNZ	T2_NEXT1
		MOV	AL,DS:T2_COUNT_SET
		MOV	DS:T2_COUNT,AL
		MOV	BX,0H

T2_NEXT1:
		POP	CX
		POP	BX
		POP	DS
		POP AX
		RET

TIMER2_ACTION	ENDP

;--------------------------------------------------------------

CODE_SEG	ENDS
END
