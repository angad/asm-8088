$MOD186
$EP
NAME TIMER
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

	REC_MESS	DB  10,13,'INPUT RECEIVED      '
	
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
	BARCODE_DEC	DB	00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
	BARCODE_I	DB 00H
	BARCODE_LEN		EQU 6
	BARCODE_BUFFER	DB BARCODE_LEN DUP(?)
	BARCODE_TAIL	EQU 0
	;BARCODE_TAIL	EQU 0


	;-- TODO: Add BCD Mappings
	ENTER_BARCODE DB	07FH, 07FH, 07FH, 07FH, 07FH, 07FH
	ENTER_QUANTITY	DB	06FH, 06FH, 06FH, 06FH, 06FH, 06FH 
	
	
	KEYPAD_CURRENT_ROW DB 00H
	KEYPAD_ROW	DB 0FEH; 
	KEYPAD1_HASH		DB	0FCH, 0F3H, 0F5H, 0F6H, 0FBH, 0F9H, 0FAH, 0F9H, 0FDH, 0FCH, 0FAH
	KEYPAD2_HASH	DB	0EEH, 0D7H, 0E7H, 0F7H, 0DBH, 0EBH, 0F3H, 0DDH, 0EDH, 0F5H, 0DEH

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
    ;call Set_timer0
	;call Set_timer1
	call Set_timer2
      STI
;---------------------------------------------------------------

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
	
	;--TODO: Get rid of these compares
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
	CMP AL, 08H
	JE NEXT

	;ANGAD'S SMARTASS HASHING ALGO
	AND AL, KEYPAD_ROW
	MOV AH, KEYPAD_ROW

	CALL NEAR PTR KEYPAD_PROCESS


;----------------------------------------------------------------
;--------------------END KEYPAD----------------------------------
;----------------------------------------------------------------
JMP NEXT

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^
KEYPAD_PROCESS PROC NEAR
	PUSH AX
	PUSH BX
	PUSH DX
	PUSH DS

	MOV	DX, DATA_SEG
	MOV	DS, DX

	;-------Keypad 1------------

	MOV CX, 10
	FIND_KEY:
		MOV BX, CX
		MOV AH, KEYPAD1_HASH[BX]
		CMP AH, AL
		JE RESOLVE_COLLISION
	LOOP FIND_KEY

	JNE KEYPAD2

	RESOLVE_COLLISION:
		MOV AL, KEYPAD_ROW

		;PUSH AX
		;CALL FAR PTR PRINT_2HEX
		;MOV AL, 0AH ;NEW LINE
		;CALL 	FAR PTR PRINT_CHAR
		;MOV AL, 0DH ;CARRIAGE RETURN
		;CALL	FAR PTR PRINT_CHAR
		;POP AX

		CMP CX, 10
		JE COLLISION_6_STAR
		CMP CX, 7
		JE COLLISION_7_5
		CMP CX, 9
		JE COLLISION_9_0

	ADD_BARCODE:
		MOV BX, CX
		MOV AL, NUMBERS[BX]
		MOV CX, BX
		MOV BL, BARCODE_I
		MOV BARCODE[BX], AL
		MOV BARCODE_DEC[BX], CL
		INC BARCODE_I
		MOV AL, SOUND_BEEP
		CALL VOICE_ON_QUEUE
		JMP KEYPAD_EXIT

	COLLISION_6_STAR:
		CMP AL, 0FEH
		JE CLEAR
		MOV CX, 6
		JMP ADD_BARCODE

	COLLISION_7_5:
		CMP AL, 0FBH
		JNE ADD_BARCODE
		MOV CX, 5
		JMP ADD_BARCODE

	COLLISION_9_0:
		CMP AL, 0FEH
		JNE ADD_BARCODE
		MOV CX, 0
		JMP ADD_BARCODE

	CLEAR:
		XOR BX, BX
		MOV CX, 08H
		CLEAR_BARCODE:
			MOV BX, CX
			DEC BX
			MOV BARCODE[BX], 00H
			MOV BARCODE_DEC[BX], 00H
		LOOP CLEAR_BARCODE
		MOV BARCODE_I, 00H
		JMP KEYPAD_EXIT

	KEYPAD2:
		MOV CX, 10
		FIND_KEY2:
			MOV BX, CX
			MOV AH, KEYPAD2_HASH[BX]
			CMP AH, AL
			JE PROCESS_COMMAND
		LOOP FIND_KEY2

		PROCESS_COMMAND:
			CMP CX, 1
			JE NEW_TRANSACTION
			CMP CX, 2
			JE NEW_ITEM
			CMP CX, 3
			JE GET_QUANTITY
			CMP CX, 10
			JE SEND_BARCODE_QUANTITY
			JMP KEYPAD_EXIT
		
		; New transaction
		; Send [OP]EN to shop pc
		; Play greeting
		NEW_TRANSACTION:
			MOV AL, 'O'
			CALL FAR PTR PRINT_CHAR
			MOV AL, 'P'
			CALL FAR PTR PRINT_CHAR

			MOV AL, SOUND_GREETING
			CALL NEAR PTR VOICE_ON_QUEUE
			MOV AL, SOUND_AFTERNOON
			CALL NEAR PTR VOICE_ON_QUEUE
			JMP KEYPAD_EXIT

		; New item
		; Send [IT]EM to shop pc
		; Clear BCD
		; Wait for user to input Barcode
		NEW_ITEM:
			MOV AL, 'I'
			CALL FAR PTR PRINT_CHAR
			MOV AL, 'T'
			CALL FAR PTR PRINT_CHAR
;			MOV CX, 6
;			FILL_BCD_BARCODE_PROMPT:
;				MOV BX, 6
;				SUB BX, 6
;				MOV AL, ENTER_BARCODE[BX]
;				MOV BARCODE[BX], AL
;			LOOP FILL_BCD_BARCODE_PROMPT
			JMP CLEAR
			JMP KEYPAD_EXIT

		;Wait for user to input Quantity
		GET_BARCODE:
			JMP CLEAR
			JMP KEYPAD_EXIT

		; Send Barcode and Quantity to shop pc
		; Send [BA]rcode and [QU]andtity to shop pc
		SEND_BARCODE_QUANTITY:
			MOV AL, 'B'
			CALL FAR PTR PRINT_CHAR
			MOV AL, 'A'
			CALL FAR PTR PRINT_CHAR
			MOV AL, '['
			CALL FAR PTR PRINT_CHAR
			MOV CX, 6
			SEND_BARCODE_LOOP:
				MOV BX, 6
				SUB BX, CX
				MOV AL, BARCODE_DEC[BX]
				ADD AL, 48
				CALL FAR PTR PRINT_CHAR
			LOOP SEND_BARCODE_LOOP
			MOV AL, ']'
			CALL FAR PTR PRINT_CHAR
			MOV AL, 'Q'
			CALL FAR PTR PRINT_CHAR
			MOV AL, 'U'
			CALL FAR PTR PRINT_CHAR
			
			JMP CLEAR
			JMP KEYPAD_EXIT

KEYPAD_EXIT:
	POP	DS
	POP DX
	POP BX
	POP AX

	RET
KEYPAD_PROCESS ENDP


TRANSACTION PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	MOV AL, SOUND_GREETING
	CALL VOICE_ON_QUEUE
	MOV AL, SOUND_AFTERNOON
	CALL VOICE_ON_QUEUE

	POP DX
	POP CX
	POP BX
	POP AX
	RET
TRANSACTION ENDP

ITEM PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	MOV	DX, DATA_SEG
	MOV	DS, DX

	POP DX
	POP CX
	POP BX
	POP AX
	RET
ITEM ENDP


QTY PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	POP DX
	POP CX
	POP BX
	POP AX
QTY ENDP

;------------------VOICE-------------------------
VOICE_ON_QUEUE PROC NEAR
	PUSH AX
	PUSH BX
	PUSH DX
	PUSH DS
	
	MOV	DX, DATA_SEG
	MOV	DS, DX

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

		CMP	AL,'a'
		JNE	S_FAST

		INC	DS:T0_COUNT_SET
		INC	DS:T0_COUNT_SET
		
		;MOV DX, IC8255_PORTA_ADDR
		;MOV AL, 0FFH
		;OUT DX, AL

		JMP	S_NEXT0
S_FAST:
		CMP	AL,01H
		JNE	S_RET

		DEC	DS:T0_COUNT_SET
		DEC	DS:T0_COUNT_SET

S_NEXT0:
		MOV	CX,15			;initialize counter for message
		MOV	BX,0

S_NEXT1:	
		MOV	AL,DS:REC_MESS[BX]	;print message
		call	FAR ptr print_char
		INC	BX
		LOOP	S_NEXT1
		MOV AL, SOUND_GREETING
		CALL NEAR PTR VOICE_ON_QUEUE

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
