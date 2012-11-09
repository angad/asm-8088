;IO Setup for 80C188XL 
;By Zhu Shunyu

         UMCR    EQU    0FFA0H ; Upper Memory Control Register
         LMCR    EQU    0FFA2H ; Lower Memory control Register         
         PCSBA   EQU    0FFA4H ; Peripheral Chip Select Base Address
         MPCS    EQU    0FFA8H ; MMCS and PCS Alter Control Register


; Initial 80C188XL UCS Pin
; |start address|block size| value for No waits, No Ready   
;   FE000H            8K                 3E04H
;   FC000H           16K                 3C04H
;   F8000H           32K                 3804H
 
         
; Initialize Upper Chip Select pin with 8K ROM 
;         MOV DX, UMCR
;         MOV AX, 03E04H
;         OUT DX, AX

; Initialize Lower Chip Select pin with 8k RAM
;         MOV DX, LMCR
;         MOV AX, 01C4H  ; Starting address 1FFFH, 8K, No waits, last shoud be 5H for 1 waits      
;         OUT DX, AL
; Initialize MPCS to MAP peripheral to IO address
         MOV DX, MPCS
         MOV AX, 0083H
         OUT DX, AL
; PCSBA initial, set the serial port start from 00H
         MOV DX, PCSBA
         MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
         OUT DX, AL

;Serial port definition and initialize 
         SRB     EQU       00H ; Serial Receiver Buffer Register (R)
         STB     EQU       00H ; Serial Transmitter Holding Register(W)  
         SIER    EQU       01H ; Serial Interrupte Enable Register (w)
         IIR     EQU       02H ; Interrupt Identification Register (R)
         SMD     EQU       03H ; Serial Line Control Register
         SST     EQU       05H ; Serial Line Status Register
         DLL     EQU       00H ; Divisor Latch Least Significant BYTE
         DLM     EQU       01H ; Divisor Latch most  Significant BYTE

;Definition of content of SST register
;|Not Use|TE|THRE|BI|FE|PE|OE|DR|
;TE Transmitter empty
;THRE Transmittor Holding Register Empty
;BI Breakr Interrupt
;FE Framing Error
;PE Parity Error
;OE Overrun Error 
;DR Data Ready
          REC_RDY    EQU   00000001B
          TRAN_RDY   EQU   00100000B
          ERR_DET    EQU   00001110B
          BREAK_DET  EQU   00010000B
; Serial Line Control Data
        SMD_DATA     EQU    00000111B
        S_INT_ENA    EQU    00000011B
        S_INT_DIS    EQU    00000000B
   
;1st bit set 1 to access the Divisor latch 
;2 stop bits, 8 data bits, no parity check
        SMD_DATA_DIV EQU    10000111B
; Set divisor value        
        MOV DX, SMD
        MOV AL, SMD_DATA_DIV
        OUT DX, AL
        MOV DX, DLL
        MOV AL, 52
        OUT DX, AL
        MOV DX, DLM
        MOV AL, 0
        OUT DX, AL
;SET SERIAL PORT WORKING MODE
         MOV DX, SMD
         MOV AL, SMD_DATA
         OUT DX, AL
;DISABLE SERIAL PORT INT
         MOV DX, SIER
         MOV AL, 0
         OUT DX, AL



; Timer control Unit
  
         T2_CON    EQU      0FF66H ; Timer 2 Control Register
         T2_CA     EQU      0FF62H ; Timer 2 compare register
         T2_CNT    EQU      0FF60H ;

         T1_CON    EQU      0FF5EH ;
         T1_CB     EQU      0FF5CH ;
         T1_CA     EQU      0FF5AH ;
         T1_CNT    EQU      0FF58H
         
         T0_CON    EQU      0FF56H ;
         T0_CB     EQU      0FF54H ;
         T0_CA     EQU      0FF52H ;
         T0_CNT    EQU      0FF50H   

		 TIMER0_TIME	EQU 5000;
		 TIMER1_TIME	EQU	5000;
		 TIMER2_TIME	EQU 6000;
         
; Timer Control Data


;Interrupt Control Registers
      

	INT3_CTRL	EQU 0FF3EH ;Interrupt 3 Control Register
	INT2_CTRL	EQU 0FF3CH
	INT1_CTRL	EQU 0FF3AH
	INT0_CTRL	EQU 0FF38H
	TIMER_CTRL	EQU 0FF32H ;Timer Interrupt Control Register
	ISR		EQU 0FF30H ; Interrupt Status Register
        EOI             EQU 0FF22H ; END OF INTERRUPT REGISTER
	
        IMKW            EQU 0FF28H ; Interrupt Mask 
        IPMK            EQU 0FF2Ah ; Interrupt Priority Mask 

;| - | - | - | - |MSK|PM2|PM1|PM0| For TCU INT

;| - |SFNM|CAS|LVL|MSK|PM2|PM1|PM0| For TCU INT0,1

;MSK 1-enable, 0-mask int 
;pm0-pm1 Priority

    
