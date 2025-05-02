.macro setup
	; PORTD0-6 : 7-segment display
	; PORTB0 : indicate furthest left
	; PORTB1 : indicate furthest right
	; PINC0 : input morse code
	; PINC1 : input done
	; PINC2 : input go left
	; PINC3 : input go right
	LDI R16, low(RAMEND)
	OUT SPL, R16
	LDI R16, high(RAMEND)
	OUT SPH, R16
	LDI R16, 0x7F
	OUT DDRD, R16
	LDI R16, 0x03
	OUT DDRB, R16
	LDI R16, 0x0
	OUT DDRC, R16
	LDI R16, 0x0F
	OUT PORTC, R16

	LDI R16, (1 << PCIE1)
	STS PCICR, R16
	LDI R16, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10) | (1 << PCINT11)
	STS PCMSK1, R16
	SEI

	LDI R16, 0
	STS TCCR1A, R16
	LDI R16, (1 << WGM12) | (1 << CS12) ; CTC mode + Prescaler 256
	STS TCCR1B, R16
	.EQU Hz = 100 ; 10ms
	.EQU _OCR1A = ((16_000_000 / 256) / Hz) - 1
	LDI R16, high(_OCR1A)
	STS OCR1AH, R16
	LDI R16, low(_OCR1A)
	STS OCR1AL, R16
	; To do a 16-bit write, the High byte must be written before the Low byte. 
	; For a 16-bit read, the Low byte must be read before the High byte

	CLT

	LDI YL, low(output_displays)
	LDI YH, high(output_displays)
	LDI XL, low(input_time_deltas)
	LDI XH, high(input_time_deltas)

	LDI R23, 0 ; PINC1 not pressed
	LDI R22, 0 ; Time counter = 0

	LDI R16, DASH
	OUT PORTD, R16
	LDI R16, 0xFF
	OUT PORTB, R16
.endmacro