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
extrn   set_timers:far

STACK_SEG	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER0_MESS	DB	10,13,'TIMER0 INTERRUPT    '
	TIMER1_MESS	DB	10,13,'TIMER1 INTERRUPT    '
	TIMER2_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	
	; -- define messages for other timers

	T_COUNT		DB	2FH
	T_COUNT_SET	DB	2FH
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
	;1 0 0 0 0 0 1 1

	MOV AL, 83H
	OUT DX, AL

	;LED INIT

	MOV DX, IC8255_PORTA_ADDR
	MOV AL, 0FFH
	OUT DX, AL

; Initialize MCS

; Initialize key code


; ^^^^^^^^^^^^^^^^^  Start of User Main Routine  ^^^^^^^^^^^^^^^^^^
    call set_timers
      STI

NEXT:     

	MOV CH, 01111111B ;8 on 7-segment (Latch 1, PCS2)
	MOV CL, 10000000B ;1st 7-segment (Latch 2, PCS3)

	MOV DX, PCS3_ADDR
	MOV AL, CL
	OUT DX, AL
	
	MOV DX, PCS2_ADDR
	MOV AL, CH
	OUT DX, AL


;MAIN LOOP


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

		INC	DS:T_COUNT_SET
		INC	DS:T_COUNT_SET

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
