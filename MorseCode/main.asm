.org 0x00
	RJMP main
.org PCI1addr
	RJMP pcint1_handler

 ;.EQU _DEBUG = 1

.include "debug.asm"
.include "display.inc"
.include "parse.inc"
.include "code.asm"
.include "input.asm"
.include "setup.inc"
.include "delay.inc"

; X is reserved for input pointer
; Y is reserved for output display pointer
; R24:25 is reserved for input_time_deltas size
; R23 is reserved for output_displays size (not during input) and 
;   falling edge detection (during input)
; R22 is reserved for timer counter (during input) and 
;   keeping track of position in array Y when displaying (not during input)
; T-bit in SREG is reserved for keeping state (0 = not during input, 1 = during input)

.cseg
main:
	.IFDEF _DEBUG
	_debug_setup
	.ENDIF
	setup
loop:
	RJMP loop

time_counter:
	LDI R22, 0
	_TIME_COUNTER:
	delayms
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

