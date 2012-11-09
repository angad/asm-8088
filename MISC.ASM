$mod186
$EP
NAME MISC
; Interrupt and misc routines for uPD70208 microcomputer system
;
; Filename:	MISC.ASM
;
; Author: 	Dr Tay Teng Tiow
; Address:     	Department of Electrical Engineering 
;         	National University of Singapore
;		10, Kent Ridge Crescent
;		Singapore 0511.	
; Date:   	3rd November 1991
;
; This file contains proprietory information and cannot be copied 
; or distributed without prior permission from the author.
;---------------------------------------------------------------------------

public	print_char, print_2hex, iodefine, Set_timer0, Set_timer1, Set_timer2
extrn 	serial_rec_action:far, timer0_action:far, timer1_action:far, timer2_action:far

INT_VEC_SEG	SEGMENT		AT 	0H
; Define the interrupt vector locations
; System reserved interrupts
		ORG	0000H
	DIV_ZERO	DD	?	;not defined yet
	SINGLE_STEP	DD	?	;not defined yet
	NMI_INPUT	DD	?	;start of downloaded program
	BRK_3_VEC	DD	?	;not defined yet
	OVERFLOW	DD	?	;not defined yet
	ARRAY_BND	DD	?	;Array Bounds
		ORG     020H
	TIMER0_VEC		DD		TIMER0_INTR ; 8 x 4 = 32
     
; Interrupt control unit
		ORG	030H
	INTP0		DD	SERIAL_INTR
	INTP1		DD	?       ;external, not used yet  
	INTP2		DD	?	;external, not used yet
	INTP3		DD	?	;external, not used yet
    NUMERICS        DD      ?       ;
    RSVED           DD      ?       ;system reserved 
    TIMER1_VEC      DD      TIMER1_INTR       ;route for timer 1
    TIMER2_VEC      DD      TIMER2_INTR       ;Timer2 Route
           ;Reserved from 050H to 080H     
	       ORG     080H
;Interrupt Vector addrerss from 080h (type 32) to 3fCH (type 255)
;are avaiable for user software interrupt           
; Software interrupts
	SOFT0		DD	? ;TYPE 32
	SOFT1		DD	? ;TYPE 33
	SOFT2		DD	?
	SOFT3		DD	?
	SOFT4		DD	?
	SOFT5		DD	?
	SOFT6		DD	?
	SOFT7		DD	?
INT_VEC_SEG	ENDS



INT_RAM_AREA	SEGMENT
	QUEUE_LEN	EQU	128

	QUEUE_TRANS	DB	QUEUE_LEN DUP(?)
	QUEUE_HEAD	DW	0H
	QUEUE_TAIL	DW	0H
INT_RAM_AREA	ENDS


$include(80188.inc)


MISC_ROUTINE	SEGMENT
ASSUME CS:MISC_ROUTINE

; ---This procdeure initialize the system I/O area and on-chip devices-----
IODEFINE	PROC	FAR
		PUSH	AX
        	PUSH	DX

; Initialize SCU for operation
		MOV	AL,SMD_DATA
		OUT	SMD,AL
; Enable serial interrupts
		MOV	AL,S_INT_ENA
		OUT	SIER,AL
; =============== INITIALIZATION OF INTERRUPT CONTROL UNIT =============
; Initialize ICU for operation
		
; Mask all interrupts except SCU
                ;disable TX interrupt,ENABLE RX.
		MOV	AL,1
		OUT	SIER,AL
; SCU use INT0, enable INT0		
	        MOV     DX, INT0_CTRL
  		XOR	AX,AX
         	OUT	DX,AL
; Mask other Int
                CLI
                MOV	DX,IMKW
		MOV	AX,0EEH
		OUT 	DX,AL   
		POP	DX
		POP	AX
		RET
IODEFINE	ENDP





; ----------------Start of procedure PRINT_2HEX ------------------------
PRINT_2HEX 	PROC	FAR
	QUE_BASE	EQU	OFFSET QUEUE_TRANS
; The byte to be printed as 2 HEX number is put into AL.
; This procedure is then called.
		CALL	FAR PTR CHAR2HEX
; Result is return in AX
		PUSH 	AX
		MOV	AL,AH
		CALL	FAR PTR PRINT_CHAR
		POP	AX
		CALL	FAR PTR PRINT_CHAR
		RET
PRINT_2HEX	ENDP




; ---------------- Start of procedure PRINT_CHAR ------------------------
PRINT_CHAR	PROC	FAR
; This procedure is called to put a character into queue for transmission
; through the serial port. 
; The data to be transmitted is put in AL before the procedure is called.
; Data is put at the tail. Queue_tail is then inc to point to next loc.
; Data is taken from the head. Queue_head is then inc to point to next data.
	
		PUSH	BX			;Save BX	
		PUSH	ES

		PUSH	AX

		MOV	BX,SEG QUEUE_TAIL	;Init segment register.
		MOV	ES,BX			;ES now contains seg of INT_RAM_AREA

		IN	AL,SIER 		;disable TX interrupt.
		AND	AL,11111101B
		OUT	SIER,AL

		POP	AX
		MOV	BX,ES:QUEUE_TAIL		
		MOV	ES:QUE_BASE[BX],AL	;Put data to queue_tail.
		INC	ES:QUEUE_TAIL		;Increment queue_tail
		CMP	ES:QUEUE_TAIL,QUEUE_LEN	;and wrap around
		JL	L_PRINT1		;to zero if needed.
		MOV	ES:QUEUE_TAIL,0
L_PRINT1:	
		IN	AL,SIER			;enable TX interrupt
		OR	AL,00000010B
		OUT	SIER,AL

		POP	ES
		POP	BX
		RET
PRINT_CHAR	ENDP




;------------------Start of Procedure CHAR2HEX ----------------------------
CHAR2HEX	PROC	FAR
; Char to be converted to HEX is put in AL before calling this procedure.
; HEX version is return in AX.
		MOV	AH,AL
		AND	AL,00001111B
		CMP	AL,9
		JG	GT9_1
		OR	AL,00110000B
		JMP 	DIGIT2
GT9_1:		SUB	AL,9
		OR	AL,01000000B
DIGIT2:
		SHR	AH,4
		CMP	AH,9
		JG	GT9_2
		OR	AH,00110000B
		JMP	DONE
GT9_2:		SUB	AH,9
		OR	AH,01000000B
DONE:
		RET
CHAR2HEX	ENDP





Set_timer0      proc Far
	push ax
	push dx
	;Initialize Timer0	
	mov ax, 0;
	mov dx, T0_CNT;init timer count register to 0
	OUT DX, AL

	MOV AX, TIMER0_TIME
	MOV DX, T0_CA
	OUT DX, AL
	
	MOV AX,0E001H ;enable counting
	MOV DX, T0_CON
	OUT DX, AL

	MOV DX, TIMER_CTRL;Timer Interrupt Control Register(80188.inc)
	MOV AL, 01H; Serial Interrupte Enable Register (w), Divisor Latch most  Significant BYTE(80188.inc)
	OUT DX, AL
	pop dx
	pop ax

ret
Set_timer0 endp

Set_timer1      proc Far
	push ax
	push dx
	;Initialize Timer1
	mov ax, 0;
	mov dx, T1_CNT;init timer count register to 0
	OUT DX, AL

	MOV AX, TIMER1_TIME
	MOV DX, T1_CA
	OUT DX, AL
	
	MOV AX,0E001H ;enable counting
	MOV DX, T1_CON
	OUT DX, AL

	MOV DX, TIMER_CTRL;Timer Interrupt Control Register(80188.inc)
	MOV AL, 01H; Serial Interrupte Enable Register (w), Divisor Latch most  Significant BYTE(80188.inc)
	OUT DX, AL
	pop dx
	pop ax

ret
Set_timer1 endp


Set_timer2      proc Far
	push ax
	push dx

	;Initialize Timer2 -- LED
	mov ax, 0;
	mov dx, T2_CNT;
	OUT DX, AL

	MOV AX, TIMER2_TIME;
	MOV DX, T2_CA;
	OUT DX, AL

	MOV AX,0E001H
	MOV DX, T2_CON
	OUT DX, AL

	MOV DX, TIMER_CTRL
	MOV AL, 01H
	OUT DX, AL
	pop dx
	pop ax

ret
Set_timer2 endp
; ************************************************************************
;			INTERRUPT ROUTINES				 *
; ************************************************************************

; **************** Start of SERIAL_INTR service routine ******************

;*****************CAUTION*****************
;At the end of interrutp routines, you must write EOI (end of Int) +
;with the INT type (INT0-type 12) (timer-type 8) 		   +	
;comment added by Zhu Shunyu	March,2000			   +				
;Interrupt Routines Modified accordly to fit 80C188XL
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SERIAL_INTR:
		PUSH	AX			;save registers
		PUSH	BX
                PUSH    DX

       

               	               
		IN	AL,IIR			;read in serial INT ID
                AND     AL,00000111B
		CMP     AL,00000100B		;check if rx interrupt
		JE	RECEIVE_INTR

		CMP    	AL,00000010B		;check if tx interrupt
		JE	TRANSMIT_INTR

		
;RESET_INT_CTL
                MOV DX, EOI
                MOV AX, 12
                OUT DX, AL

                POP     DX
		POP	BX			;false serial interrupt
		POP	AX
		IRET				;return

RECEIVE_INTR:	
              
		IN	AL,SRB			
; Information received will be used by user routine
; Action to be taken will be contained in SERIAL_REC_ACTION
		CALL	FAR PTR SERIAL_REC_ACTION
		
		MOV DX, EOI
                MOV AX, 12
                OUT DX, AL
		POP     DX
		POP	BX			;false serial interrupt
		POP	AX
		IRET

TRANSMIT_INTR:
               
		PUSH	ES			;save ES
		MOV	BX,SEG QUEUE_TAIL	;set ES to SERIAL_Q_SEG
		MOV	ES,BX
		MOV	BX,ES:QUEUE_TAIL
		CMP	BX,ES:QUEUE_HEAD	;more data to be transmitted?
		JE	L_TX2
		MOV	BX,ES:QUEUE_HEAD	;get data from queue
		MOV	AL,ES:QUE_BASE[BX]
		OUT	STB,AL			;tx data
		INC	ES:QUEUE_HEAD		;point to next data
		CMP	ES:QUEUE_HEAD,QUEUE_LEN ;wrap around if necessary
		JL	L_TX1
		MOV	ES:QUEUE_HEAD,0
L_TX1:		
		MOV	BX,ES:QUEUE_TAIL
		CMP	BX,ES:QUEUE_HEAD	;more data to be transmitted?
		JNE	L_TX3
L_TX2:
		IN	AL,SIER			;no more, disable TX interrupt.
		AND    	AL,11111101B
		OUT	SIER,AL
L_TX3:
		
;RESET_INT_CTL
                MOV DX, EOI
                MOV AX, 12
                OUT DX, AL
      		POP	ES			;restore original ES(transmit)
		
                POP     DX 
                POP	BX			;return serial interrupt
		POP	AX
		IRET
; **************** End of SERIAL_INTR service routine ************************






; **************** Start of TIMER0_INTR service routine ******************
TIMER0_INTR:
		PUSH 	AX
		
; Action to be taken on timer0 interrupt to be written by user
		CALL	FAR PTR TIMER0_ACTION
              
		POP	AX		;return interrupt
                ;RESET_INT_CTL	
                MOV DX, EOI
                MOV AX, 8
                OUT DX, AL
		IRET
; **************** End of TIMER0_INTR service routine ************************


; **************** Start of TIMER1_INTR service routine ******************
TIMER1_INTR:
		PUSH 	AX
		
; Action to be taken on timer1 interrupt to be written by user
		CALL	FAR PTR TIMER1_ACTION
              
		POP	AX		;return interrupt
                ;RESET_INT_CTL	
                MOV DX, EOI
                MOV AX, 8
                OUT DX, AL
		IRET
; **************** End of TIMER1_INTR service routine ************************


; **************** Start of TIMER2_INTR service routine ******************
TIMER2_INTR:
		PUSH 	AX
		
; Action to be taken on timer2 interrupt to be written by user
		CALL	FAR PTR TIMER2_ACTION
              
		POP	AX		;return interrupt
                ;RESET_INT_CTL	
                MOV DX, EOI
                MOV AX, 8
                OUT DX, AL
		IRET
; **************** End of TIMER2_INTR service routine ************************



MISC_ROUTINE	ENDS

END
