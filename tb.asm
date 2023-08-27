Прекол:

        call    ОбчиститьЭкран
OK:     jr      Прекол

ОбчиститьЭкран:

        movs    r0, 1
        movs    r1, 1
        mov     r2, $A0000
        mov     r3, $B0000
@@:     movb    [r2], r1
        add     r2, r0
        cmp     r2, r3
        jnz     @b
        ret
