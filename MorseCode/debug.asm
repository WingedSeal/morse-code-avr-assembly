.macro _debug_setup   
    LDI R16, high(UBRR_VALUE) 
    STS UBRR0H, R16
    LDI R16, low(UBRR_VALUE)
    STS UBRR0L, R16 ; 9600 baud
    LDI R16, (1<<TXEN0)
    STS UCSR0B, R16
    LDI R16, (1<<UCSZ01)|(1<<UCSZ00) ; 8 data bits, 1 stop bit, no parity
    STS UCSR0C, R16
.endmacro

.IFDEF _DEBUG
.equ BAUD_RATE = 9600
.equ F_CPU = 16_000_000
.equ UBRR_VALUE = ((F_CPU / 16) / BAUD_RATE) - 1


.macro print
	PUSH ZL
	PUSH ZH
	PUSH R16

	RJMP print_start

print_data:
	.db @0, 0
print_start:
	LDI ZL, low(print_data << 1)
	LDI ZH, high(print_data << 1)
print_loop:
	LPM R16, Z+
	CPI R16, 0
	BREQ print_done
	CALL send_char
	RJMP print_loop
print_done:
	POP R16
	PUSH R16
	MOV R16, @1
	CALL _print_byte_decimal
	LDI R16, '\n'
	CALL send_char
	POP R16
	POP ZH
	POP ZL
.endmacro


; Print array pointed by X with length in R24:R25
print_X_input:
	PUSH R16
	PUSH R24
	PUSH R25
	PUSH XL
	PUSH XH
    
	LDI R16, 'I'
    RCALL send_char
    LDI R16, 'N'
    RCALL send_char
	LDI R16, ':'
    RCALL send_char
	LDI R16, ' '
    RCALL send_char
	MOV R16, R25
    RCALL _print_byte_decimal
	LDI R16, '-'
    RCALL send_char
    MOV R16, R24
    RCALL _print_byte_decimal
    LDI R16, '\r'
    RCALL send_char
    LDI R16, '\n'
    RCALL send_char

	MOV R16, R25
    OR R16, R24
    BREQ _print_X_input_done
_print_X_input_loop:
    LD R16, X+
    RCALL _print_byte_decimal
	LDI R16, ' '
    RCALL send_char
    SBIW R24:R25, 1
    BRNE _print_X_input_loop  

_print_X_input_done:
	LDI R16, '\r'
    RCALL send_char
    LDI R16, '\n'
    RCALL send_char
    POP XH
    POP XL
    POP R25
	POP R24
	POP R16
    RET

.EQU DECIMAL = 10
_print_byte_decimal:
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19

	MOV R17, R16 ; Value to convert
	LDI R18, '0' ; ASCII offset
	LDI R19, 0 ; Digit counts

	TST R17
	BRNE _convert_loop
	PUSH R18
	LDI R19, 1
	RJMP _flush_loop

_convert_loop:
	CLR R16 ; Remainder
_division_while:
	CPI R17, DECIMAL   
	BRLO _division_end_while
	SUBI R17, DECIMAL
	INC R16
	RJMP _division_while
_division_end_while:
	; R17 is the remainder (0-9)
	; R16 is the quotient

	ADD R17, R18 ; Convert remainder to ASCII
	PUSH R17
	INC R19
	MOV R17, R16
	TST R17
	BRNE _convert_loop
	_flush_loop:
		POP R16
		RCALL send_char
		DEC R19
		BRNE _flush_loop
	POP R19
	POP R18
	POP R17
	POP R16
	RET

; Send a character in R16 via USART
send_char:
    PUSH R17
_wait_ready:
    LDS R17, UCSR0A
    SBRS R17, UDRE0 ; Wait until data register is empty
    RJMP _wait_ready
    STS UDR0, R16
    POP R17
    RET

; Print array pointed by Y with length in R23
print_Y_output:
	PUSH R16
	PUSH R23
	PUSH YL
	PUSH YH
    
	LDI R16, 'O'
    RCALL send_char
    LDI R16, 'U'
    RCALL send_char
	LDI R16, 'T'
    RCALL send_char
	LDI R16, ':'
    RCALL send_char
	LDI R16, ' '
    RCALL send_char
    MOV R16, R23
    RCALL _print_byte_decimal
    LDI R16, '\r'
    RCALL send_char
    LDI R16, '\n'
    RCALL send_char

	TST R23
    BREQ _print_Y_output_done
_print_Y_output_loop:
    LD R16, Y+
    RCALL send_char
	LDI R16, ' '
    RCALL send_char
    DEC R23
    BRNE _print_Y_output_loop  

_print_Y_output_done:
	LDI R16, '\r'
    RCALL send_char
    LDI R16, '\n'
    RCALL send_char
    POP YH
    POP YL
    POP R23
	POP R16
    RET
.ENDIF
