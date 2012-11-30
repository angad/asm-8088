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
extrn   Set_timer0:far, Set_timer1:far, Set_timer2:far, disable_timer0:far

STACK_SEG	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


;----------------------------------------------------------------
;--------------------DATA SEGMENT--------------------------------
;----------------------------------------------------------------

DATA_SEG	SEGMENT

	;-- String messages
	MAIN_MESS   DB  10,13,'Main Loop           '
	TIMER0_MESS	DB	10,13,'TIMER0 INTERRUPT    '
	TIMER1_MESS	DB	10,13,'TIMER1 INTERRUPT    '
	TIMER2_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	KEY_PRESSED DB  10,13,'KEY PRESSED         '

	REC_MESS	DB  10,13,'KEY PRESSED         '
	
	DI_INC	DW 0000H

	; -- Timers counters

	T0_COUNT		DB	2FH
	T0_COUNT_SET	DB	2FH
	T1_COUNT		DB	2FH
	T1_COUNT_SET	DB	2FH
	T2_COUNT		DB	2FH
	T2_COUNT_SET	DB	2FH

	; -- BCD and Keypad

	LED_SELECT  DB  0FEH
	NUMBERS		DB	03FH, 006H, 05BH, 04FH, 066H, 06DH, 07DH, 007H, 07FH, 06FH
	CURRENT_NUMBER DB 00H
	BARCODE		DB  00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
	;BARCODE		DB  03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH, 03FH
	BARCODE_I	DB 00H
	KEYPAD_CURRENT_ROW DB 00H
	KEYPAD_ROW	DB 0FEH;

	; -- Voice

	DESIRED_SOUND DW 999
	SOUND_ADDR			DD	0
	SOUND_LEFT			DW	0
	SOUND_BASE_ADDR		DD	0, 4713, 8481, 11945, 15315, 18317, 21614, 26120, 30013, 31809
						DD	36107, 39110, 43768, 47646, 51847, 56124, 60775, 66907, 73225
						DD	78520, 84565, 87674, 90326, 93756, 96907, 101370, 106075, 109155
						DD	112854, 115703, 118631, 121867, 126347, 129602, 133161, 134469
						DD	137351, 141625, 146695, 152503, 159103, 162214, 166331, 170638
						DD	175769, 178219, 181435, 183391, 187071, 191560, 196299, 198222
						DD	201345, 205826, 210477, 213770, 216003, 219454, 225267, 229879
						DD	234904, 242475, 249711, 259862, 260667
	SOUND_SIZE			DW	4713, 3768, 3464, 3370, 3002, 3297, 4506, 3893, 1796, 4298
						DW	3003, 4658, 3878, 4201, 4277, 4651, 6132, 6318, 5295, 6045
						DW	3109, 2652, 3430, 3151, 4463, 4705, 3080, 3699, 2849, 2928
						DW	3236, 4480, 3255, 3559, 1308, 2882, 4274, 5070, 5808, 6600
						DW	3111, 4117, 4307, 5131, 2450, 3216, 1956, 3680, 4489, 4739
						DW	1923, 3123, 4481, 4651, 3293, 2233, 3451, 5813, 4612, 5025
						DW	7571, 7236, 10151, 805, 800
	SOUND_INIT			EQU 0
	SOUND_HUNDRED		EQU	28
	SOUND_THOUSAND		EQU	29
	SOUND_PRODUCT		EQU	30
	SOUND_AND			EQU	50
	SOUND_COST			EQU	52
	SOUND_DOLLAR		EQU	53
	SOUND_CENT			EQU	54
	SOUND_GREETING		EQU	55
	SOUND_MORNING		EQU	56
	SOUND_AFTERNOON		EQU	57
	SOUND_EVENING		EQU	58
	SOUND_PAY			EQU	59
	SOUND_PURCHASE		EQU	60
	SOUND_CHANGE		EQU	61
	SOUND_EXIT			EQU	62
	SOUND_BEEP			EQU	63
	SOUND_SILENCE		EQU	64
	SOUND_QUEUE_LEN		EQU	32
	SOUND_QUEUE			DB	SOUND_QUEUE_LEN DUP(?)
	SOUND_HEAD			DB	0
	SOUND_TAIL			DB	0
	SOUND_TEST_LEFT		DB	0
	
	
		
DATA_SEG	ENDS

;----------------------------------------------------------------
;--------------------DATA SEGMENT END----------------------------
;----------------------------------------------------------------


;----------------------------------------------------------------
;--------------------CHIP SELECTS--------------------------------
;----------------------------------------------------------------
; 8255 register addresses
; PCS1
IC8255_PORTA_ADDR EQU 80H;
IC8255_PORTB_ADDR EQU 81H;
IC8255_PORTC_ADDR EQU 82H;
IC8255_CW_ADDR    EQU 83H;

PCS2_ADDR EQU 100H
PCS3_ADDR EQU 180H
PCS4_ADDR EQU 200H

MMCS EQU 0FFA6H
MPCS EQU 0FFA8H

;----------------------------------------------------------------
;-------------------CHIP SELECT END------------------------------
;----------------------------------------------------------------


;----------------------------------------------------------------
;--------------------CODE SEGMENT--------------------------------
;----------------------------------------------------------------

CODE_SEG	SEGMENT
	PUBLIC		START
ASSUME		CS:CODE_SEG, SS:STACK_SEG, DS:DATA_SEG

START:

;-----------------------STACK AREA INIT--------------------------
	MOV	AX, STACK_SEG		
	MOV	SS, AX
	MOV	SP, TOS

	MOV AX, DATA_SEG
	MOV DS, AX
;----------------------------------------------------------------

;--------------ON-CHIP PERIPEHRALS--------------------------------
	CALL	FAR PTR	IODEFINE
	
	;IC8255 - Control Word
	MOV DX, IC8255_CW_ADDR

	;CW Register 
	;Port C Lower Input, Port C Upper Output 
	;Port B input, Port A output
	;1 0 0 0 0 0 1 0
	MOV AL, 82H
	OUT DX, AL

; Initialize MCS

	MOV DX, MMCS
	MOV	AX, 8003H
	OUT	DX, AX

	MOV DX, MPCS
	MOV AX, 4084H
	OUT DX, AX

;----------------------------------------------------------------

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

;------------------------Setting the timers---------------------
    call Set_timer0
	;call Set_timer1
	;call Set_timer2
      STI
;---------------------------------------------------------------

	MOV CX, 20
	SPEAK:
		MOV AL, CL
		CALL VOICE_ON_QUEUE
	LOOP SPEAK


	;MOV AL, SOUND_INIT
	;CALL VOICE_ON_QUEUE

	;MOV AL, SOUND_EVENING
	;CALL VOICE_ON_QUEUE

NEXT:
;----------------------------------------------------------------
;--------------------MAIN LOOP INIT------------------------------
;----------------------------------------------------------------

	;slowing down the main loop
	MOV CX, 05FFFH ; 2380 dec
	SLEEP:
		NOP
	LOOP SLEEP; 18 clocks


;----------------------------------------------------------------
;--------------------START KEYPAD----------------------------------
;----------------------------------------------------------------

;----------------------------------------------------------------
;--------------------END KEYPAD----------------------------------
;----------------------------------------------------------------
JMP NEXT

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^

VOICE_ON_QUEUE PROC NEAR
	PUSH AX
	PUSH BX
	PUSH DX
	PUSH DS
	
	MOV	DX, DATA_SEG
	MOV	DS, DX
	
	PUSH AX	

	MOV AL, 02H ;Printing 1 to check the start of main loop
	CALL FAR PTR PRINT_2HEX
	MOV AL, 0AH ;NEW LINE
	CALL 	FAR PTR PRINT_CHAR
	MOV AL, 0DH ;CARRIAGE RETURN
	CALL	FAR PTR PRINT_CHAR

	POP AX

	MOV BH, 0
	MOV BL, BYTE PTR SOUND_HEAD
	MOV BYTE PTR SOUND_QUEUE[BX], AL
	INC BL

	CMP BL, SOUND_QUEUE_LEN
	JNE VOICE_ON_QUEUE_STALL
	
	MOV BL, 0
	
VOICE_ON_QUEUE_STALL:
		
	MOV BYTE PTR SOUND_HEAD, BL
 
	CALL	FAR PTR	Set_timer0
	
	POP	DS
	POP DX
	POP BX
	POP AX
	
	RET
VOICE_ON_QUEUE ENDP


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

S_NEXT1:	
		MOV	AL,DS:REC_MESS[BX]	;print message
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
	XOR CX,CX
	XOR DX,DX

	MOV	AX,DATA_SEG
	MOV	DS,AX
	
	;slowing down the timer 
	;MOV CX, 04FFFH ; 2380 dec
	;SLEEP_TIMER:
	;	NOP
	;LOOP SLEEP_TIMER; 18 clocks

;----------------------------------------------------
	; SOUND_LEFT: Number of bytes left in the queue
	CMP WORD PTR SOUND_LEFT, 0
	JNE timer0_ACTION_PROCEED
	
	; Reload with next item in the queue
	MOV BH, 0
	MOV BL, BYTE PTR SOUND_TAIL
	
	CMP BYTE PTR SOUND_HEAD, BL
	JNE timer0_ACTION_RELOAD
	
	;disable timer 0, freeing up resources
	call disable_timer0
 
	JMP T0_NEXT1
	
timer0_ACTION_RELOAD:
	
	MOV BL, BYTE PTR SOUND_QUEUE[BX]
	MOV SI, OFFSET SOUND_BASE_ADDR
		
	SHL BX, 2
	MOV AX, WORD PTR [BX][SI]
 
	MOV WORD PTR SOUND_ADDR[0], AX
	
	MOV AX, WORD PTR 2[BX][SI]	
	MOV WORD PTR SOUND_ADDR[2], AX
	
	SHR BX, 1
	MOV SI, OFFSET SOUND_SIZE
	MOV AX, WORD PTR [BX][SI]
	MOV WORD PTR SOUND_LEFT, AX
	MOV AL, BYTE PTR SOUND_TAIL
	INC AL
	CMP AL, SOUND_QUEUE_LEN
	JNE timer0_QUEUE_NO_OVERFLOW
	
	MOV AL, 0
	
timer0_QUEUE_NO_OVERFLOW:

	MOV BYTE PTR SOUND_TAIL, AL
	JMP T0_NEXT1
	
timer0_ACTION_PROCEED:

	;PUSH AX
	;MOV AL, 41H
	;CALL FAR PTR PRINT_CHAR
	;MOV AL, 0AH ;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH ;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR
	;POP AX

	DEC WORD PTR SOUND_LEFT
	
	MOV SI, WORD PTR SOUND_ADDR[0]
	MOV DI, WORD PTR SOUND_ADDR[2]

	; SI - Intra-segment address, DI - Segment address
	ADD DI, 8H
	SHL DI, 12

	; Set extra segment to point to 8000H, the starting segment of the EEPROM
	MOV DS, DI
	 
	; Get byte from EEPROM address space
	MOV AL, [SI]
	
	; Put byte to DAC
	MOV DX, PCS4_ADDR
	OUT DX, AL
	
	;Printing contents of EEPROM

	;PUSH AX
	;CALL FAR PTR PRINT_2HEX ; Print the value
	;MOV AL, 20H
	;CALL FAR PTR PRINT_CHAR
	;MOV AL, 0AH				;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH				;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR

	;MOV AL, 42H
	;CALL FAR PTR PRINT_CHAR
	;MOV AL, 0AH ;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH ;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR

	;MOV AX, SI
	;CALL FAR PTR PRINT_2HEX
	;MOV AL, 0AH ;NEW LINE
	;CALL 	FAR PTR PRINT_CHAR
	;MOV AL, 0DH ;CARRIAGE RETURN
	;CALL	FAR PTR PRINT_CHAR

	;POP AX

	; Increment EEPROM address to move to the next sample
	MOV AX, DATA_SEG
	MOV DS, AX

	INC WORD PTR SOUND_ADDR[0]
	JNZ T0_NEXT1

	; Increment memory segment
	INC WORD PTR SOUND_ADDR[2]

;---------------------------------------------


	DEC	DS:T0_COUNT
	JNZ	T0_NEXT1
	MOV	AL,DS:T0_COUNT_SET
	MOV	DS:T0_COUNT,AL

T0_NEXT1:
;T0_NEXT1:
	POP	CX
	POP	BX
	POP	DS
	POP AX
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
