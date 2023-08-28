
        ; Рисование линии
        ; r0-error
        ; r1-x1, r2-y1, r3-x2, r4-y2
        ; r5-signx, r6-deltax
        ; r7-signy, r8-deltay
        ; ----------------------------------------
        ; r0,r5-r13

        mov     r11, 320
        mov     r12, 0xA0000
        movs    r13, 15

        ; deltax = |x2-x1|, signx=sgn(x2-x1)
        movs    r5, 1           ; 3T
        sub     r6, r3, r1      ; 4T
        jns     @f              ; 1-2T
        movs    r5, -1          ; 3T
        sub     r6, r1, r3      ; 4T
@@:     ; deltay = |y2-y1|, signy=sgn(y2-y1)
        movs    r6, 1
        sub     r7, r4, r2
        jns     @f
        movs    r6, -1
        sub     r7, r2, r4
@@:     sub     r0, r6, r8      ; error =  deltax - deltay
.rep:   cmp     r1, r3          ; while ((x1 != x2) || (y1 != y2))
        jne     .next
        cmp     r2, r4
        jne     .next
        ret
.next:  mul     r2, r11 => r10  ; r10 будет результатом
        add     r10, r1
        add     r10, r12
        movb    [r10], r13      ; mov (0xA000+320*y+x),15
        add     r9, r0, r0
        add     r10, r0, r8     ; error2 + deltay > 0
        jbe     .next2
        sub     r0, r8          ; error -= deltay
        add     r1, r5          ; x1 += signx
.next2: cmp     r9, r6
        jnl     .rep            ; error2 <  deltax ?
        add     r0, r6          ; error += deltax
        add     r2, r7          ; y1 += signy
        jr      .rep
