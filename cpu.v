/**
 * Простой 32-х битный процессор с собственной архитектурой
 */

module cpu
(
    input               clock,
    input               reset_n,
    input               ce,
    // -- Память
    output      [31:0]  address,
    input       [ 7:0]  in,
    output  reg [ 7:0]  out,
    output  reg         we,
    // -- Стек 1KB
    output  reg [ 9:0]  sp,
    input       [31:0]  si,
    output  reg [31:0]  so,
    output  reg         sw,
    // -- Регистры 1K
    output  reg [ 7:0]  ra, rb,
    input       [31:0]  r1, r2,
    output  reg [31:0]  ro,         // Для записи RO -> [RA]
    output  reg         rw          // Запись в регистр RA значения RO
);

localparam CF = 0, ZF = 1, SF = 2, OF = 3;

assign address = cp ? ea : pc;

reg         cp;
reg [31:0]  pc, ea;
reg [ 2:0]  alu;
reg [ 7:0]  opc;
reg [ 3:0]  m, t;
//                    OSZC
reg [ 3:0]  flag = 4'b0000;

always @(posedge clock)
if (reset_n == 1'b0) begin pc <= 0; t <= 0; cp <= 0; flag <= 4'b0000; end
else begin

    rw <= 0;
    we <= 0;
    sw <= 0;
    m  <= m + 1;

    case (t)

        // INITIAL
        0: begin

            case (in)
            // 6T MOV A, i
            8'h00: t <= 1;
            // 3T MOV A, B
            8'h01: t <= 2;
            // 5T+ MOV A, [B]
            8'h02, 8'h03, 8'h04: t <= 3;
            // 5T+ MOV [A], B
            8'h05, 8'h06, 8'h07: t <= 4;
            // 5T MUL B, C => A, R
            8'h08: t <= 14;
            // 38T DIV B, C => A, R
            8'h09: t <= 15;
            // 3T RET
            8'h0D: begin t <= 10; ra <= 255; end
            // 4T+ PUSH
            8'h0E: begin t <= 11; ra <= 255; end
            // 3T+ POP
            8'h0F: begin t <= 12; ra <= 255; end
            // 4T <ALU> A,B[,C]
            8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17: t <= 5;
            // 4T <SHR> A,B[,C]
            8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D,        8'h1F: t <= 6;
            // 3T MOV A, s8
            8'h1E: t <= 13;
            // 2T JMP b8
            8'h70: t <= 7;
            // 5T JMP|CALL i32
            8'h71,
            8'h0C: t <= 8;
            // 3T JMP A
            8'h7A: t <= 9;
            // 1-2T J<ccc>
            8'h72, 8'h73, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76,
            8'h77, 8'h78, 8'h79, 8'h7C, 8'h7D, 8'h7E, 8'h7F:
                if (br[in[3:1]] == in[0]) pc <= pc + 2; else t <= 7;
            endcase

            m   <= 0;
            pc  <= pc + 1;
            opc <= in;
            alu <= in[2:0];

        end

        // 6T MOV A, i32
        1: case (m)

            0: begin pc <= pc + 1; ra        <= in; end
            1: begin pc <= pc + 1; ro[  7:0] <= in; end
            2: begin pc <= pc + 1; ro[ 15:8] <= in; end
            3: begin pc <= pc + 1; ro[23:16] <= in; end
            4: begin pc <= pc + 1; ro[31:24] <= in; t <= 0; rw <= 1; end

        endcase

        // 3T MOV A, B
        2: case (m)

            0: begin pc <= pc + 1; rb <= in; end
            1: begin pc <= pc + 1; ra <= in; ro <= r2; rw <= 1; t <= 0; end

        endcase

        // 5T+ MOV A, (5T byte|6T word|8T dword) [B]
        3: case (m)

            0: begin pc <= pc + 1; rb <= in; end
            1: begin pc <= pc + 1; ra <= in; cp <= 1; ea <= r2; end
            2: begin ea <= ea + 1; m <= opc == 2 ? 6 : 3; ro        <= in; end
            3: begin ea <= ea + 1; m <= opc == 3 ? 6 : 4; ro[ 15:8] <= in; end
            4: begin ro[23:16] <= in; ea <= ea + 1; end
            5: begin ro[31:24] <= in; end
            6: begin t <= 0; rw <= 1; cp <= 0; end

        endcase

        // 5T+ MOV (5T byte|6T word|8T dword) [A], B
        4: case (m)

            0: begin rb <= in; pc <= pc + 1; end
            1: begin ra <= in; pc <= pc + 1; end
            2: begin ea <= r1;     m <= (opc == 5) ? 6 : 3; we <= 1; out <= r2[ 7:0]; cp <= 1; end
            3: begin ea <= ea + 1; m <= (opc == 6) ? 6 : 4; we <= 1; out <= r2[15:8]; end
            4: begin ea <= ea + 1; we <= 1; out <= r2[23:16]; end
            5: begin ea <= ea + 1; we <= 1; out <= r2[31:24]; end
            6: begin t <= 0; cp <= 0; end

        endcase

        // 4T АЛУ операция
        5: case (m)

            0: begin ra <= in; pc <= pc + 1; end
            1: begin rb <= in; pc <= pc + 1; end
            2: begin

                t    <= 0;
                flag <= _flag_alu;

                if (alu != 7) begin ro <= _res; rw <= 1; ra <= in; pc <= pc + 1; end

            end

        endcase

        // 4T СДВИГИ
        6: case (m)

            0: begin ra <= in; pc <= pc + 1; end
            1: begin rb <= in; pc <= pc + 1; end
            2: begin flag <= _flag_rot; ro <= _rot; rw <= 1; t <= 0; end

        endcase

        // 2T JMP b8
        7: begin t <= 0; pc <= pc + 1 + {{24{in[7]}}, in}; end

        // 5T JMP|CALL I32
        8: case (m)

            0: begin ro[  7:0] <= in; pc <= pc + 1; ra <= 255; end
            1: begin ro[ 15:8] <= in; pc <= pc + 1; end
            2: begin ro[23:16] <= in; pc <= pc + 1; end
            3: begin

                t  <= 0;
                pc <= {in, ro[23:0]};
                sp <= r1 - 1;
                ro <= r1 - 1;
                so <= pc + 1;
                sw <= (opc == 8'h0C);
                rw <= (opc == 8'h0C);

            end

        endcase

        // 3T JMP A
        9: case (m)

            0: begin ra <= in; end
            1: begin pc <= r1; t <= 0; end

        endcase

        // 3T RET
        10: case (m)

            0: begin sp <= r1; ro <= r1 + 1; rw <= 1; end
            1: begin pc <= si; t <= 0; end

        endcase

        // 4T+ PUSH <paramlist>
        11: case (m)

            0: begin opc <= in; sp <= r1; rw <= 1; ro <= r1 - in; pc <= pc + 1; end
            1: begin ra <= in; pc <= pc + 1; end
            2: begin

                m  <= 2;
                ra <= in;
                so <= r1;
                sw <= 1;
                sp <= sp - 1;

                // Считать аргументы
                if (opc == 1) t <= 0;
                else begin opc <= opc - 1; pc <= pc + 1; end

            end

        endcase

        // 3T+ POP <paramlist>
        12: case (m)

            0: begin opc <= in; sp <= r1; rw <= 1; ro <= r1 + in; pc <= pc + 1; end
            1: begin

                m  <= 1;
                rw <= 1;
                ra <= in;
                ro <= si;
                sp <= sp + 1;
                pc <= pc + 1;

                if (opc == 1) t <= 0; else opc <= opc - 1;

            end

        endcase

        // 3T MOV A, s8
        13: case (m)

            0: begin pc <= pc + 1; ra <= in; end
            1: begin pc <= pc + 1; ro <= {{24{in[7]}}, in}; rw <= 1; t <= 0; end

        endcase

        // 5T MUL B, C => A, R
        14: case (m)

            0: begin ra <= in; pc <= pc + 1; end
            1: begin rb <= in; pc <= pc + 1; end
            2: begin ra <= in; pc <= pc + 1; rw <= 1; ro <= imul[63:32];  end
            3: begin ra <= in; pc <= pc + 1; rw <= 1; ro <= imul[31:0]; end

        endcase

        // 38T DIV B, C => A, R
        15: case (m)

            0: begin ra <= in; pc <= pc + 1; end
            1: begin rb <= in; pc <= pc + 1; end
            2: begin so <= 1'b0; ro <= r1; opc <= 32; end
            3: begin

                ro <= {ro[30:0], divnext >= r2};                // Результат
                so <= {divnext >= r2 ? divnext - r2 : divnext}; // Остаток

                if (opc != 1) begin opc <= opc - 1; m <= 3; end

            end

            4: begin rw <= 1; ra <= in; pc <= pc + 1; end
            5: begin rw <= 1; ra <= in; pc <= pc + 1; ro <= so; t <= 0; end

        endcase

    endcase

end

// -----------------------------------------------------------------------------
// Вычислитель
// -----------------------------------------------------------------------------

// Быстрое умножение, а также деление
wire [63:0] imul = r1 * r2;
wire [31:0] divnext = {so[30:0], ro[31]};

// Условные переходы
wire [7:0] br =
{
    (flag[OF] ^ flag[SF]) | flag[ZF],   // JLE
    (flag[OF] ^ flag[SF]),              // JL
    1'b0,                               // Не используется
    flag[SF],
    flag[CF] | flag[ZF],                // JBE | JA
    flag[ZF],
    flag[CF],
    1'b0                                // Не используется
};

// Переполнение при логических операциях возможно тоже, но бессмысленно
wire overflow = (r1[31] ^ r2[31] ^ (alu <= 1)) & (r1[31] ^ _res[31]);

// АЛУ
wire [32:0] _res =
    alu == 3'h0 ? r1 + r2 :
    alu == 3'h1 ? r1 + r2 + flag[CF] :
    alu == 3'h3 ? r1 - r2 - flag[CF] :
    alu == 3'h4 ? r1 & r2 :
    alu == 3'h5 ? r1 ^ r2 :
    alu == 3'h6 ? r1 | r2 :
                  r1 - r2;  // SUB, CMP

// Установка флагов после АЛУ операции
wire [ 3:0] _flag_alu = {overflow, _res[31], ~|_res[31:0], _res[32]};

// -----------------------------------------------------------------------------
// 1=ROR, 0=ROL
// -----------------------------------------------------------------------------
wire [ 4:0] rt = opc[0] ? r2[4:0] : (~r2[4:0]) + 1;

// Процедура вращения вправо/влево
wire [31:0] t1 = rt[0] ? {r1[   0], r1[ 31:1]} : r1;
wire [31:0] t2 = rt[1] ? {t1[ 1:0], t1[ 31:2]} : t1;
wire [31:0] t3 = rt[2] ? {t2[ 3:0], t2[ 31:4]} : t2;
wire [31:0] t4 = rt[3] ? {t3[ 7:0], t3[ 31:8]} : t3;
wire [31:0] t5 = rt[4] ? {t4[15:0], t4[31:16]} : t4;

// Диапазоны
wire [ 3:0] m1 = rt[1] ? {rt[   0],     2'h3} : rt[0];
wire [ 7:0] m2 = rt[2] ? {m1[ 3:0],     4'hF} : m1;
wire [15:0] m3 = rt[3] ? {m2[ 7:0],    8'hFF} : m2;
wire [31:0] m4 = rt[4] ? {m3[15:0], 16'hFFFF} : m3;
wire [31:0] m5 = opc[0] ? ~m4 : m4;

// Итоговый результат вращения
wire [31:0] _rot =
    alu == 3'h0 ||
    alu == 3'h1 ? t5 :                  // ROL, ROR
    alu == 3'h2 ? (t5 & ~m5) :          // SHL
    alu == 3'h3 ? (t5 &  m5) :          // SHR
    alu == 3'h4 ? (t5 & ~m5) | (flag[CF] ?  m5 : 0) : // RCL
    alu == 3'h5 ? (t5 &  m5) | (flag[CF] ? ~m5 : 0) : // RCR
    alu == 3'h6 ? (t5 & ~m5) :          // SHL
        r1[31] ? t5 | ~m4 : t5 & m5;    // SAR

// Флаги после выполнения операции
wire [ 3:0] _flag_rot = {1'b0, _rot[31], _rot == 32'b0, t5[opc[0] ? 31 : 0]};

endmodule
