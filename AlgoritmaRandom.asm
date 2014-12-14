;TINGGAL DITAMBAHIN CARA INPUT
;DAN CARA NGECEK SOAL
; DAN KALO SALAH JUGA
; LUTHFI - 14 DESEMBER 2014

.include "m8515def.inc"

.def temp =r16	; Define temporary variable
.def EW = r17	; for PORTA
.def PB = r18	; for PORTB
.def A  = r19

.org $00
	rjmp START
.org $07
	rjmp ISR_TOV0

; PORTB as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW

START:	
ldi	temp,low(RAMEND) ; Set stack pointer to -
out	SPL,temp	; -- last internal RAM location
ldi	temp,high(RAMEND)
out	SPH,temp

rcall INIT_LCD

ldi	temp,$ff
out	DDRA,temp	; Set port A as output
out	DDRB,temp	; Set port B as output

INTRO :
ldi r17, 0x30

ldi r16,(1<<CS02)|(1<<CS00); 
out TCCR0,r16			
ldi r16,1<<TOV0
out TIFR,r16		; Interrupt if overflow occurs in T/C0
ldi r16,1<<TOIE0
out TIMSK,r16		; Enable Timer/Counter0 Overflow int
ser r16
out DDRB,r16		; Set port B as output
sei

LOADBYTE:

cpi	r17, 0x39	; Check if we've reached the end of the message
breq INTRO	; If so, quit
inc r17
rjmp LOADBYTE

QUIT: rjmp QUIT

WAIT_LCD:
ldi	r20, 1
ldi	r21, 69
ldi	r22, 69
CONT:	dec	r22
brne	CONT
dec	r21
brne	CONT
dec	r20
brne	CONT
ret

INIT_LCD:
rcall CLEAR_LCD
cbi PORTA,1	; CLR RS
ldi PB,0x38	; MOV DATA,0x38 --> 8bit, 2line, 5x7
out PORTB,PB
sbi PORTA,0	; SETB EN
cbi PORTA,0	; CLR EN
rcall WAIT_LCD
cbi PORTA,1	; CLR RS
ldi PB,$0C	; MOV DATA,0x0E --> disp ON, cursor OFF, blink OFF
out PORTB,PB
sbi PORTA,0	; SETB EN
cbi PORTA,0	; CLR EN

rcall WAIT_LCD
rcall CLEAR_LCD ; CLEAR LCD
ret

CLEAR_LCD:
cbi PORTA,1	; CLR RS
ldi PB,$01	; MOV DATA,0x01
out PORTB,PB
sbi PORTA,0	; SETB EN
cbi PORTA,0	; CLR EN
rcall WAIT_LCD

cbi PORTA,1	; CLR RS
ldi PB,0x87	; MOV DATA,0x38 --> 8bit, 2line, 5x7
out PORTB,PB
sbi PORTA,0	; SETB EN
cbi PORTA,0	; CLR EN
rcall WAIT_LCD

ret

WRITE_TEXT:
sbi PORTA,1	; SETB RS
out PORTB, A
sbi PORTA,0	; SETB EN
cbi PORTA,0	; CLR EN
rcall WAIT_LCD
rcall WAIT_LCD
ret

ISR_TOV0:
push r16
in r16,SREG

push r16
in r16,PORTB	; read Port B
com r16			; invert bits of r16 
out PORTB,r16	; write Port B


mov A, r17	; Put the character onto Port B
rcall WRITE_TEXT
rcall CLEAR_LCD

pop r16
out SREG,r16
pop r16
reti
