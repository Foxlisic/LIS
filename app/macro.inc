; Система макросов

; MOV A, IMM32
macro   movi    a, b {
        db      0, a
        dd      b
}

; MOV
macro   movr    a, b { db 1, b, a }     ; mov a, b
macro   movbm   a, b { db 2, b, a }     ; movb a, [b]
macro   movwm   a, b { db 3, b, a }     ; movw a, [b]
macro   movdm   a, b { db 4, b, a }     ; movd a, [b]
macro   movbr   a, b { db 5, b, a }     ; movb [a], b
macro   movwr   a, b { db 6, b, a }     ; movw [a], b
macro   movdr   a, b { db 7, b, a }     ; movd [a], b
macro   movs    a, b { db 0x1E, a, b }  ; movs a, i8

macro   xmul    c, a, b, r { db $08, b, c, a, r } ; a*b => hi=r,lo=c
macro   xdiv    c, a, b, r { db $09, b, c, a, r } ; a/b => c,r
