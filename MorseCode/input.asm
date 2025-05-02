.macro noRETI
	POP R0
	POP R0
	; Used for preventing stackoverflow from pushing PC into
	; it every interrupt.
	SEI
.endmacro

.EQU IGNORE_THRESHOLD = 3

handle_last_input_below_threshold:
	ADD R22, R16
	BRCS UNSIGNED_OVERFLOW
	LD R16, -X
	ADD R22, R16
	BRCS UNSIGNED_OVERFLOW
	OVERFLOW_OR_NOT:
	ST X+, R22
	noRETI
	RJMP time_counter
	UNSIGNED_OVERFLOW:
		LDI R22, 0xFF
		RJMP OVERFLOW_OR_NOT

morse_code_input_during_input:
	LDI R23, 1 ; Indicate holding button
	LD R16, -X
	CPI R16, IGNORE_THRESHOLD
	BRLO handle_last_input_below_threshold
	ADIW X, 1
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


morse_code_input_falling_edge_during_input:
	LDI R23, 0 ; Indicate releasing button
	LD R16, -X
	CPI R16, IGNORE_THRESHOLD
	BRLO handle_last_input_below_threshold
	ADIW X, 1
	LDI R16, 0x00
	OUT PORTB, R16
	ST X+, R22
	noRETI
	RJMP time_counter

stop_during_input:
	CLT ; Update state to not during input
	LDI R22, 255
	ST X+, R22

	MOVW R24:R25, X
	LDI XL, low(input_time_deltas)
	LDI XH, high(input_time_deltas)
	
	SUB R24, XL
	SBC R25, XH

	.IFDEF _DEBUG
	CALL print_X_input
	.ENDIF
	updateOutputDisplays
	.IFDEF _DEBUG
	CALL print_Y_output
	.ENDIF
	handleDisplay
	
	noRETI
	RJMP loop



morse_code_input_not_during_input:
	SET ; Update state to during input
	LDI R23, 1
	LDI R16, 0x7F
	OUT PORTD, R16
	LDI R16, 0xFF
	OUT PORTB, R16
	LDI XL, low(input_time_deltas)
	LDI XH, high(input_time_deltas)
	noRETI
	RJMP time_counter

go_right_not_during_input:
	INC R22
	CP R22, R23 ; R22 == R23 - 1
	BREQ _CANT_GO_RIGHT
	; _CAN_GO_RIGHT
		ADIW Y, 1
		handleDisplay
		INC R22
	_CANT_GO_RIGHT:
	DEC R22
	RETI

go_left_not_during_input:
	TST R22
	BREQ _CANT_GO_LEFT
	; _CAN_GO_LEFT
		SBIW Y, 1
		DEC R22
		handleDisplay
	_CANT_GO_LEFT:
	RETI