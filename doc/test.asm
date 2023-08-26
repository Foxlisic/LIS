
        ; Обчистка экрана
        ; ----------------------------------------
        mov     r0, 1
        mov     r1, 1
        mov     r2, $a0000
        mov     r3, $b0000
@@:     mov     byte [r2], r1
        add     r2, r0
        cmp     r2, r3
        jnz     @b

        ; CBW r1 -> ..
        mov     r250, 0x00000080    ; 6
        mov     r251, 0xffffff00    ; 6
        and     r0, r1, r250        ; 4 проверка r1
        je      @nope               ; 2
        or      r1, r251            ; 4

        ; Дравинг линясы
        ; r1-x1, r2-y1, r3-x2, r4-y2
        ; ----------------------------------------
        push    r5 r6
        mov     r7, r1
        mov     r8, r2
        mov     r5, 1           ; signx
        mov     r6, 1           ; signy
        sub     r1, r3          ; r1 = |x2-x1|
        jnc     @f1
        mov     r5, -1
        add     r1, r3
        add     r1, r3
@f1:    sub     r2, r4          ; r2 = |y2-y1|
        jnc     @f2
        mov     r6, -1
        add     r2, r3
        add     r2, r3
@f2:    mov     r0, 0
        sub     r2, r0, r2
        add     r7, r1, r2      ; error  = deltax - deltay
        call    PSET_x1y1       ; обговаривается отдельным буйзариком
        cmp     r7, r3          ; while ((x1 != x2) || (y1 != y2))
        jnz     .next
        cmp     r8, r4
        jnz     .net
        ret
.next:  call    PSET            ; this.pset(x1, y1, color)
        add     r9, r7, r7      ; error2 = 2 * error
        cmp     r9, r2          ; if (error2 > -deltay) { error -= deltay; x1 += signx; }
        jc      .s1
        add     r7, r2
        add     r1, r5
.s1:    cmp     r9, r1          ; if (error2 <  deltax) { error += deltax; y1 += signy; }
        jnc     .next
        add     r7, r1
        add     r2, r6
        jmp     .next
