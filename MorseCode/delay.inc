.macro delayms
	LDI R16, 0
    STS TCNT1H, R16
	STS TCNT1L, R16
	; To do a 16-bit write, the High byte must be written before the Low byte. 
	; For a 16-bit read, the Low byte must be read before the High byte
	LDI R16, (1 << OCF1A)
	OUT TIFR1, R16
	_LOOP_DELAY:
		IN R16, TIFR1
		SBRS R16, OCF1A
		RJMP _LOOP_DELAY
.endmacro