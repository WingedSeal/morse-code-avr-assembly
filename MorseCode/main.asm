.org 0x00
	RJMP main
.org PCI1addr
	RJMP pcint1_handler

.include "display.inc"
.include "parse.inc"
.include "code.asm"
.include "input.asm"
.include "setup.inc"
.include "delay.inc"

; R24:25 is reserved for input_time_deltas size
; R23 is reserved for output_displays size (not during input) and 
;   falling edge detecting (during input)
; R22 is reserved for timer counter
; T-bit in SREG is reserved for keeping state (0 = not during input, 1 = during input)

TODO:
	RJMP TODO

.cseg
main:
	setup
	
	LDI R16, 0
    STS TCNT1H, R16
	STS TCNT1L, R16
	; To do a 16-bit write, the High byte must be written before the Low byte. 
	; For a 16-bit read, the Low byte must be read before the High byte
	LDI R16, (1 << OCF1A)
	OUT TIFR1, R16
	_LOOP_DELAY_TEST:
		IN R16, TIFR1
		SBRS R16, OCF1A
		RJMP _LOOP_DELAY_TEST
	NOP
loop:
	RJMP loop

time_counter:
	LDI R22, 0
	_TIME_COUNTER:
	delay100ms
	CPI R22, 0xFF
	BREQ _TIME_COUNTER
	INC R22
	RJMP _TIME_COUNTER


_PINC0_FALLING_EDGE_DETECTION:
	SBRS R23, 0
		RJMP _PINC0_FALLING_EDGE_DETECTION_FAILED
	LDI R23, 0
	RJMP morse_code_input_falling_edge_during_input

during_input:
	SBIS PINC, 0
	RJMP _PINC0_FALLING_EDGE_DETECTION
	_PINC0_FALLING_EDGE_DETECTION_FAILED:
	SBIC PINC, 0
	RJMP morse_code_input_during_input
	SBIC PINC, 1
	RJMP stop_during_input
	RETI

not_during_input:
	SBIC PINC, 0
	RJMP morse_code_input_not_during_input
	SBIC PINC, 2
	RJMP go_left_not_during_input
	SBIC PINC, 3
	RJMP go_right_not_during_input
	RETI

pcint1_handler:
	BRTS during_input
	RJMP not_during_input
	
.dseg
	.EQU INPUT_BUFFER_SIZE = 1024
	.EQU OUTPUT_BUFFER_SIZE = 256
	output_displays: .byte OUTPUT_BUFFER_SIZE
	input_time_deltas: .byte INPUT_BUFFER_SIZE
	; todo: maybe they can use the same space? further testing needed

