
        mov     r0, 0xB8000
        mov     r1, 0xB9000
        mov     r2, 0x0741
        movs    r3, 2
@@:     movw    [r0], r2
        add     r0, r3
        cmp     r0, r1
        jne     @b
stp:    jr      stp
