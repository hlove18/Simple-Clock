;TEST - HENRY LOVE - 9/1/19
;This little program moves 1 into all 7 segment displays for simple clock.

INIT:


MAIN:
	; Write a 1 to all displays
	mov P0, #88h
	mov P2, #11h
	mov P3, #11h

sjmp main					; repeat

end