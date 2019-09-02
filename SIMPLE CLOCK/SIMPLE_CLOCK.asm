;SIMPLE CLOCK - Bibit and Henry (BLE) - 9/1/19 (A PALINDROME!)
;This little program runs Simple Clock.

;======== Organization ======
	;R1 - seconds - time
	;R2 - minutes - time
	;R3 - hours - time
	;R4 - used for timer 0 postscaler
	;R5 - used for R4 postscaler
	;R6 - used for timer 1 postscaler

.org 0
ljmp INIT

; Timer 0 interrupt
.org 000Bh
	lcall TIMER_0_ISR
reti 									; exit

; Timer 1 interrupt
.org 001Bh
	lcall TIMER_1_ISR
reti 									; exit

.org 100h
INIT:
	;======== Variables ======
	.equ SEC_ONES, 20h
	.equ SEC_TENS, 21h

	.equ MIN_ONES, 22h
	.equ MIN_TENS, 23h

	.equ TEMP_R3, 24h 					; to address the bits in R3

	.equ SUPER_FAST_MODE, 25h.0 		; flag for super fast mode (hours tick every ~second)

	; Formatting for 12 hour clock
	mov SEC_ONES, #0Ah
	mov SEC_TENS, #06h
	
	mov MIN_ONES, #0Ah
	mov MIN_TENS, #06h

	clr SUPER_FAST_MODE 				; start in normal time pace

	; When clock turns on, display 12:00:00
	mov R1, #00h
	mov R2, #00h
	mov R3, #12h

	; Intialize timer 0 postscalers
	mov R4, #10h 						; counts 16
	mov R5, #0FAh 						; counts 250

	; Initialize timer 1 postscaler
	mov R6, #64h 						; counts 100

	; Write 1s to use port 1 to use it as input
	mov P1, #0FFh
	clr P1.2				; clear P1.2 to use it as an output for set time button
							; if P1.1 is high (connected to P1.0), then count seconds normally
							; if P1.1 is low (connected to P1.2), then speed count seconds (set time)

	; IE (interrupt enable) register
	; _____________________________________________
	; | EA | - | ET2 | ES | ET1 | EX1 | ET0 | EX0 |
	; |____|___|_____|____|_____|_____|_____|_____|
	; EA (IE.7): interrupt enable bit (must be set to use interrupts)
	; IE.6: reserved
	; ET2 (IE.5): timer 2 overflow interrupt enable bit (only 8052)
	; ES (IE.4): serial port interrupt enable bit
	; ET1 (IE.3): timer 1 overflow interrupt enable bit
	; EX1 (IE.2): external interrupt 1 enable bit
	; ET0 (IE.1): timer 0 overflow interrupt enable bit
	; EX0 (IE.0): external interrupt 0 enable bit

	; Interrupt initialization
	mov IE, #00h 			; disable all interrupts
	setb EA 				; enable interrupts
	setb ET0				; enable timer 0 overflow interrupt
	setb ET1 				; enable timer 1 overflow interrupt

	; Initialize TMOD
	mov TMOD, #12h 			; set timer 1 to use 12MHz clock in mode 1 (00010000 bin = 10 hex)
							; set timer 0 to use 12MHz clock in mode 2 (00000010 bin = 02 hex)
							; final TMOD value = #10h | #02h = #12h
	
	; Timer 0 interrupt initialization (for seconds interrupt)
	mov TL0, #06h 			; initialize TL0 (#06h for 250 us)
	mov TH0, #06h 			; initialize TH0 (#06h for 250 us) - reload value			
	setb TR0 				; start timer 0

	; Timer 1 interrupt initialization (for super fast mode)
	mov TL1, #00h 			; initialize TL1 (#00h for 65536 us)
	mov TH1, #00h 			; initialize TH1 (#00h for 65536 us)
	clr TR1 				; do not start timer 1

MAIN:
	; display the seconds
	mov P3, R1

	; display the minutes
	mov P2, R2

	; display the hours 
	; since wiring is weird, reflect R3 into P0:
	; mov P0.0, R3.7
	; mov P0.1, R3.6
	; mov P0.2, R3.5
	; mov P0.3, R3.4
	; mov P0.4, R3.3
	; mov P0.5, R3.2
	; mov P0.6, R3.1
	; mov P0.7, R3.0
	
	mov TEMP_R3, R3

	; for R3.7 (P0.0)
	jnb TEMP_R3.7, MAIN_CONT0
		setb P0.0
		jmp MAIN_CONT1
	MAIN_CONT0:
	clr P0.0
	MAIN_CONT1:

	; for R3.6 (P0.1)
	jnb TEMP_R3.6, MAIN_CONT2
		setb P0.1
		jmp MAIN_CONT3
	MAIN_CONT2:
	clr P0.1
	MAIN_CONT3:

	; for R3.5 (P0.2)
	jnb TEMP_R3.5, MAIN_CONT4
		setb P0.2
		jmp MAIN_CONT5
	MAIN_CONT4:
	clr P0.2
	MAIN_CONT5:

	; for R3.4 (P0.3)
	jnb TEMP_R3.4, MAIN_CONT6
		setb P0.3
		jmp MAIN_CONT7
	MAIN_CONT6:
	clr P0.3
	MAIN_CONT7:

	; for R3.3 (P0.4)
	jnb TEMP_R3.3, MAIN_CONT8
		setb P0.4
		jmp MAIN_CONT9
	MAIN_CONT8:
	clr P0.4
	MAIN_CONT9:

	; for R3.2 (P0.5)
	jnb TEMP_R3.2, MAIN_CONT10
		setb P0.5
		jmp MAIN_CONT11
	MAIN_CONT10:
	clr P0.5
	MAIN_CONT11:

	; for R3.1 (P0.6)
	jnb TEMP_R3.1, MAIN_CONT12
		setb P0.6
		jmp MAIN_CONT13
	MAIN_CONT12:
	clr P0.6
	MAIN_CONT13:

	; for R3.0 (P0.7)
	jnb TEMP_R3.0, MAIN_CONT14
		setb P0.7
		jmp MAIN_CONT15
	MAIN_CONT14:
	clr P0.7
	MAIN_CONT15:

sjmp MAIN					; repeat

TIMER_0_ISR:	
	jb SUPER_FAST_MODE, SUPER_FAST_MODE_CONT; check if in super fast mode
		jnb P1.1, FAST_MODE_CONT 			; jump if button is pressed (in fast mode)

	REGULAR_MODE_CONT:
	clr TR1 								; disable timer 1
	mov R6, #64h 							; reload R6
	clr SUPER_FAST_MODE 					; clear super fast mode flag
	djnz R4, TIMER_0_ISR_END 				; decrement R4
		djnz R5, REGULAR_MODE_CONT0			; decrement R5
			lcall SECONDS_INTERRUPT			; update the time
			mov R5, #0FAh 					; reload R5
		REGULAR_MODE_CONT0:
		mov R4, #10h 						; reload R4
	ljmp TIMER_0_ISR_END 					; exit


	SUPER_FAST_MODE_CONT:
	jnb P1.1, SUPER_FAST_MODE_CONT0 		; jump if button is pressed (confirm we should be in super fast mode)
		; super fast mode flag is set but we should not be in super fast mode
		clr TR1 							; disable timer 1
		mov R6, #64h 						; reload R6
		clr SUPER_FAST_MODE 				; clear super fast mode flag
		ljmp TIMER_0_ISR_END 				; exit
	SUPER_FAST_MODE_CONT0:
	lcall SECONDS_INTERRUPT					; update the time
	ljmp TIMER_0_ISR_END

	FAST_MODE_CONT:
	setb TR1 								; start timer 1
	djnz R4, TIMER_0_ISR_END 				; decrement R4
		lcall SECONDS_INTERRUPT				; update the time
		mov R4, #10h 						; reload R4

	TIMER_0_ISR_END:
ret

TIMER_1_ISR:
	djnz R6, TIMER_1_ISR_CONT0 			; decrement R6
		setb SUPER_FAST_MODE 			; put into super fast mode
		clr TR1 						; disable timer 1
		mov R6, #64h 					; reload R6
	TIMER_1_ISR_CONT0:
	mov TL1, #00h 						; reload TL1
	mov TH1, #00h 						; reload TH1
ret

SECONDS_INTERRUPT:
	; every second
	inc R1
	
	djnz SEC_ONES, SECONDS_INTERRUPT_CONT0
		lcall SKIP_SEC_ONES
		mov SEC_ONES, #0Ah
		
		djnz SEC_TENS, SECONDS_INTERRUPT_CONT0
			mov R1, #00h
			inc R2
			mov SEC_TENS, #06h
			
			djnz MIN_ONES, SECONDS_INTERRUPT_CONT0
				lcall SKIP_MIN_ONES
				mov MIN_ONES, #0Ah
				
				djnz MIN_TENS, SECONDS_INTERRUPT_CONT0
					mov R2, #00h
					inc R3
					mov MIN_TENS, #06h
					
					cjne R3, #0Ah, SECONDS_INTERRUPT_CONT1
						lcall SKIP_HOUR_ONES
					SECONDS_INTERRUPT_CONT1:
					cjne R3, #13h, SECONDS_INTERRUPT_CONT0
						mov R3, #01h
		
	SECONDS_INTERRUPT_CONT0:
ret

SKIP_SEC_ONES:
	inc R1
	inc R1
	inc R1
	inc R1
	inc R1
	inc R1
ret

SKIP_MIN_ONES:
	inc R2
	inc R2
	inc R2
	inc R2
	inc R2
	inc R2
ret

SKIP_HOUR_ONES:
	inc R3
	inc R3
	inc R3
	inc R3
	inc R3
	inc R3
ret

end