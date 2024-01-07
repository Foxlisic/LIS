include "macro.inc"

        org     0

        xmul    1, 2, 3, 0

        movs    1, -1
        movbm   1, 1
        movwm   1, 1
        movdm   1, 1
        movbr   1, 1
        movwr   1, 1
        movdr   1, 1

        movi    5, 0xAA123465
        movr    2, 5
