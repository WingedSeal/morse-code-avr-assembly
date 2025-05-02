.equ DASH = 0b00000001

.macro parseMorseCode
	; Update X register and return morse code in R16 (return 0 if too many character)
	.EQU SHORT_LONG_THRESHOLD = 30
	.EQU CHAR_THRESHOLD = 50
	LDI R16, 0
	LDI R17, 0 ; Counts how many bits (first 3 bits of the result R16)
	LOOP_TIME_DELTA:
		INC R17
		CPI R17, 6
		BRLO _NOT_TOO_MANY_CHARS 
			; handle unknown morse code, too many character
		LOOP_TOO_MANY_CHARS:
				LD R0, X+
				LD R18, X+
				SBIW R24:R25, 2
				BRCS _HANDLE_R24 ; Unsigned underflow 
				; (handling in case of odd number size)
				CPI R18, CHAR_THRESHOLD
				BRSH LOOP_TIME_DELTA_DONE
				RJMP LOOP_TOO_MANY_CHARS
		_NOT_TOO_MANY_CHARS:
		LSL R16
		LD R18, X+
		CPI R18, SHORT_LONG_THRESHOLD
		BRLO _SHORT
		; _LONG:
			INC R16
		_SHORT:
			; PASS
		LD R18, X+
		SBIW R24:R25, 2
		BRCS _HANDLE_R24 ; Unsigned underflow (handling in case of odd number size)
		CPI R18, CHAR_THRESHOLD
		BRSH LOOP_TIME_DELTA_DONE
		RJMP LOOP_TIME_DELTA
	_HANDLE_R24:
	LDI R24, 0
	LDI R25, 0
	LOOP_TIME_DELTA_DONE:
	LSL R17
	LSL R17
	LSL R17
	LSL R17
	LSL R17

	OR R16, R17

	RJMP _END_PARSE_MORSE_CODE
	_HANDLE_R24_EARLY_RETURN:
	LDI R24, 0
	LDI R25, 0
	_END_PARSE_MORSE_CODE:

.endmacro

.macro updateOutputDisplays
	; LDI XL, low(input_time_deltas) - Should be set before calling
	; LDI XH, high(input_time_deltas) - Should be set before calling
	LDI YL, low(output_displays)
	LDI YH, high(output_displays)
	LOOP_OUTPUT_DISPLAYS:
		parseMorseCode ; R16
		TST R16
		BRNE _R16_IS_NOT_ZERO
			LDI R16, DASH
			ST Y+, R16
			RJMP _END_SEARCH_MORSE_CODE
		_R16_IS_NOT_ZERO:
		LDI ZH, high(MORSE_CODE << 1)
		LDI ZL, low(MORSE_CODE << 1)
		LOOP_SEARCH_MORSE_CODE:
			LPM R17, Z+ ; Morse Code
			CPI ZL, low((MORSE_CODE << 1) + MORSE_CODE_SIZE)
			LDI R18, high((MORSE_CODE << 1) + MORSE_CODE_SIZE)
			CPC ZH, R18
			BRNE _MATCH
			; _NO_MATCH
				LDI R16, DASH
				ST Y+, R16
				RJMP _END_SEARCH_MORSE_CODE
			_MATCH:
			CP R16, R17
			BRNE LOOP_SEARCH_MORSE_CODE
		ADIW Z, (MORSE_CODE_SIZE - 1)
		LPM R16, Z ; Display
		ST Y+, R16
		_END_SEARCH_MORSE_CODE:
		MOV R23, R24
		OR R23, R25 ; Check if R24:R25 is 0
		BRNE LOOP_OUTPUT_DISPLAYS
	MOV R23, YL
	SUBI R23, low(output_displays) ; Since the difference is guaranteed to be 
	; within a byte, high byte can be safely ignored
	LDI YL, low(output_displays)
	LDI YH, high(output_displays)
	LDI R22, 0 ; Starts displaying at index 0 (no longer used for time counter)
.endmacro
