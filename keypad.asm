$MOD186
$ep
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

public	serial_rec_action, timer2_action, timer1_action
extrn	print_char:far, print_2hex:far, iodefine:far
extrn   set_timers:far

STACK_SEG	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER0_MESS	DB	10,13,'TIMER0 INTERRUPT    '
	TIMER1_MESS	DB	10,13,'TIMER1 INTERRUPT    '
	TIMER2_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	T_COUNT		DB	2FH
	T_COUNT_SET	DB	2FH
	REC_MESS	DB	10,13,'Period of timer0 =     '
  TEST_PRINT_SERIAL DB 2 DUP(0H), 10,13
 
 ;****Keypad******
  KEY_DECODE 	DB 24 DUP(0)
  LAST_FOUND 	DB 0H ; 0 NO KEY FOUND, 1 KEY FOUND
  KEYPAD_INPUT 	DB 33 
  ;**********
  
  ; LED_COUNT 	DB 0H
  ; LED_CURRENT_DIGIT DB 01H
  ; LED_MAX_COUNT	 DB 06H
  ; LED_DISPLAY_Q 	DB 6 DUP(00H)
  ; LED_DECODE DB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH
  ;-------------|0 , 1   , 2  , 3 ,  4 ,  5 ,  6 ,  7 ,  8 ,  9
DATA_SEG	ENDS

; 8255 register addresses
; PCS1
IC8255_PORTA_ADDR EQU 80H;
IC8255_PORTB_ADDR EQU 81H;
IC8255_PORTC_ADDR EQU 82H;
IC8255_CW_ADDR    EQU 83H;

PCS2_ADDR EQU 100H
PCS3_ADDR EQU 180H

;***
NEXT_KEY	EQU 18;---------DEFINE * (1) AS NEXT
CLEAR_KEY	EQU 20;---------DEFINE # (1) AS CLEAR
DELETE_KEY	EQU 21 ;---------DEFINE * (2) AS DELETE KEY
ENTER_KEY 	EQU 23;---------DEFINE #(2) AS ENTER KEY

CODE_SEG	SEGMENT


	PUBLIC		START

ASSUME	CS:CODE_SEG, SS:STACK_SEG, DS:DATA_SEG

START:
	CLI
;initialize stack area
		MOV	AX,STACK_SEG		
		MOV	SS,AX
		MOV	SP,TOS

		MOV AX, DATA_SEG
		MOV DS, AX
	
; Initialize the on-chip pheripherals
		CALL	FAR PTR	IODEFINE
	
	MOV DX, IC8255_CW_ADDR
	MOV AL, 82H  ;PORTC LOWER OUTPUT - PORTB INPUT
	;Port C Lower Input, Port C Upper Output 
	;Port B Input, Port A output 
	OUT DX, AL
  
	MOV DX, IC8255_PORTA_ADDR
	MOV AL, 0FFH
	OUT DX, AL
	
; Initialize MCS:
	;MPCS
	
	;MMCS

; Initialize key code
	
	MOV DS:KEY_DECODE[0], 1
	MOV DS:KEY_DECODE[1], 2
	MOV DS:KEY_DECODE[2], 3
	MOV DS:KEY_DECODE[3], 1
	MOV DS:KEY_DECODE[4], 2
	MOV DS:KEY_DECODE[5], 3
	MOV DS:KEY_DECODE[6], 4
	MOV DS:KEY_DECODE[7], 5
	MOV DS:KEY_DECODE[8], 6
	MOV DS:KEY_DECODE[9], 4
	MOV DS:KEY_DECODE[10], 5
	MOV DS:KEY_DECODE[11], 6
	MOV DS:KEY_DECODE[12], 7
	MOV DS:KEY_DECODE[13], 8
	MOV DS:KEY_DECODE[14], 9
	MOV DS:KEY_DECODE[15], 7
	MOV DS:KEY_DECODE[16], 8
	MOV DS:KEY_DECODE[17], 9
	;MOV DS:KEY_DECODE[18], *
	MOV DS:KEY_DECODE[19], 0
	;MOV DS:KEY_DECODE[20], #
	;MOV DS:KEY_DECODE[21], *
	MOV DS:KEY_DECODE[22], 0
	;MOV DS:KEY_DECODE[23], #
	

; ^^^^^^^^^^^^^^^^^  Start of User Main Routine  ^^^^^^^^^^^^^^^^^^
    call set_timers
      STI

NEXT:     

	;To get input from keypad
;-------------------------------------------------------------
;If key_pressed, then get port B address and port C address
KEYPAD_ROUTINE PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	MOV BL, 00H
	
	MOV AL, 0FH					;AL = 0000 1111
	MOV DX, IC8255_PORTB_ADDR	;DX = Port B Address
	OUT DX, AL					;Move to Port B, value 0000 1111
	MOV AX, IC8255_PORTC_ADDR	;

CHECK_KEY_CLOSED:	 			;Check when key is pressed. Keep looping here
	IN AL, DX					;Move to AL, value in Port B. 
	CMP AL, 00H ;any key pressed? 	;If any key pressed, value in Port B = AL !=0
	JZ CHECK_KEY_CLOSED				;If value is 0, then repeat = no key pressed.
	
	MOV AL, 80H					;AL = 1000 0000
	MOV BH, 04H					;BX = 0000 1000 0000 0000
NEXT_ROW:	
	ROL AL, 01H ;				;ROL AL = 0000 0001 and so on
	MOV CH, AL	;save 			;CH = 01H
	MOV DX, IC8255_PORTB_ADDR	;
	OUT DX, AL	
	MOV DX, IC8255_PORTC_ADDR
	IN AL, DX	

	MOV CL, 08H	
NEXT_COLUMN:	
	RCR AL, 01H ;move D0 to CF
	JC KEY_DETECTED	
	INC BL	 
	DEC CL	 
	JNZ NEXT_COLUMN
	
	MOV AL, CH	;Load 
	DEC BH	 
	JNZ NEXT_ROW	
	
	JMP NOT_FOUND_KEY
KEY_DETECTED:	
	MOV DS:KEYPAD_INPUT, BL ;---------STORE INPUT TO THIS VARIABLE
	XOR BH, BH
	MOV AL, DS:KEY_DECODE[BX]	;key code 
	MOV DX, IC8255_PORTA_ADDR	;Show on Port A LEDs
	OUT DX, AL
	
	JMP END_KEYPAD_ROUTINE
	
NOT_FOUND_KEY:
	MOV DS:LAST_FOUND, 0
	 
	END_KEYPAD_ROUTINE:
	POP DX
	POP CX
	POP BX
	POP AX
	RET
KEYPAD_ROUTINE ENDP

	

;MAIN LOOP


;JMP NEXT

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^


SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS

		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX

		CMP	AL,'<'
		JNE	S_FAST

		INC	DS:T_COUNT_SET
		INC	DS:T_COUNT_SET
		
		MOV DX, IC8255_PORTA_ADDR
		MOV AL, 0FFH
		OUT DX, AL

		JMP	S_NEXT0
S_FAST:
		CMP	AL,'>'
		JNE	S_RET

		DEC	DS:T_COUNT_SET
		DEC	DS:T_COUNT_SET

S_NEXT0:
		MOV	CX,22			;initialize counter for message
		MOV	BX,0

S_NEXT1:	MOV	AL,DS:REC_MESS[BX]	;print message
		call	FAR ptr print_char
		INC	BX
		LOOP	S_NEXT1

		MOV	AL,DS:T_COUNT_SET	;print current period of timer0
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

		MOV	AX,DATA_SEG
		MOV	DS,AX
	
		DEC	DS:T_COUNT
		JNZ	T0_NEXT1
		MOV	AL,DS:T_COUNT_SET
		MOV	DS:T_COUNT,AL

		MOV	CX,20
		MOV	BX,0H
T0_NEXT0:
		MOV	AL,DS:TIMER0_MESS[BX]
		INC	BX
		CALL 	FAR PTR PRINT_CHAR
		LOOP	T0_NEXT0

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
	
		DEC	DS:T_COUNT
		JNZ	T1_NEXT1
		MOV	AL,DS:T_COUNT_SET
		MOV	DS:T_COUNT,AL

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

		MOV	AX,DATA_SEG
		MOV	DS,AX
	
		DEC	DS:T_COUNT
		JNZ	T2_NEXT1
		MOV	AL,DS:T_COUNT_SET
		MOV	DS:T_COUNT,AL

		MOV	CX,20
		MOV	BX,0H
		
		
		
T2_NEXT0:
		MOV	AL,DS:TIMER2_MESS[BX]
		INC	BX
		CALL 	FAR PTR PRINT_CHAR
		LOOP	T2_NEXT0

T2_NEXT1:	
		POP	CX
		POP	BX
		POP	DS
		POP 	AX
		RET
TIMER2_ACTION	ENDP

;--------------------------------------------------------------

CODE_SEG	ENDS
END
