.macro noRETI
	POP R0
	POP R0
	; Used for preventing stackoverflow from pushing PC into
	; it every interrupt.
	SEI
.endmacro

morse_code_input_during_input:
	LDI R23, 1
	LDI R16, 0xFF
	OUT PORTB, R16
	ST X+, R22
	LDI R16, high(OUTPUT_BUFFER_SIZE)
	CPI R24, low(OUTPUT_BUFFER_SIZE)
	CPC R25, R16
	BRNE _BUFFER_NOT_OVERFLOW
		RJMP stop_during_input
	_BUFFER_NOT_OVERFLOW:
	noRETI
	RJMP time_counter

stop_during_input:
	CLT ; Update state to not during input
	ST X+, R22
	MOVW R24:R25, X
	LDI XL, low(input_time_deltas)
	LDI XH, high(input_time_deltas)
	SUB R24, XL
	SBC R25, XH
	updateOutputDisplays
	handleDisplay
	noRETI
	RJMP loop

morse_code_input_falling_edge_during_input:	
	LDI R23, 0
	LDI R16, 0x00
	OUT PORTB, R16
	ST X+, R22
	noRETI
	RJMP time_counter

morse_code_input_not_during_input:
	SET ; Update state to during input
	LDI R23, 1
	LDI R16, 0xEF
	OUT PORTD, R16
	LDI R16, 0xFF
	OUT PORTB, R16
	noRETI
	RJMP time_counter

go_left_not_during_input:
	LDI R16, low(output_displays)
	ADD R16, R23
	DEC R16
	CP YL, R16
	BREQ _CANT_GO_LEFT
		ADIW Y, 1
		handleDisplay
	_CANT_GO_LEFT:
	RETI

go_right_not_during_input:
	CPI YL, low(output_displays)
	BREQ _CANT_GO_RIGHT
		SBIW Y, 1
		handleDisplay
	_CANT_GO_RIGHT:
	RETI