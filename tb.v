`timescale 10ns / 1ns
module tb;

// Тестбенчевые сигналы
// =============================================================================
reg reset_n;
reg clock_hi; always #0.5 clock_hi = ~clock_hi;
reg clock_25; always #2.0 clock_25 = ~clock_25;

initial begin

    $readmemh("tb.hex", memory, 0);
    $readmemh("regs.hex", regs, 0);
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    clock_hi = 0;
    clock_25 = 0;
    reset_n  = 0;

    #3.0  reset_n = 1;
    #2000 $finish;

end

// Контроллер блочной памяти
// =============================================================================

reg  [ 7:0] memory[1024*1024];
reg  [31:0] regs[256], stack[1024];

reg  [ 7:0] in;
wire [ 7:0] out;
wire        we;
wire [31:0] address;
wire [ 7:0] ra, rb;
reg  [31:0] r1, r2;
wire [31:0] ro;
wire [ 9:0] sp;
reg  [31:0] si;
wire [31:0] so;
wire        rw, sw;

always @(posedge clock_hi)
begin

    in <= memory[address[19:0]];
    r1 <= regs[ra];
    r2 <= regs[rb];
    si <= stack[sp];

    if (we) memory[address[19:0]] <= out;
    if (rw) regs[ra] <= ro;
    if (sw) stack[sp] <= so;

end

// Описание подключения CPU
// =============================================================================

cpu CPU
(
    .clock      (clock_25),
    .reset_n    (reset_n),
    .ce         (1'b1),
    // Память
    .address    (address),
    .in         (in),
    .out        (out),
    .we         (we),
    // Регистры
    .ra         (ra),
    .rb         (rb),
    .r1         (r1),
    .r2         (r2),
    .ro         (ro),
    .rw         (rw),
    // Стейк
    .sp         (sp),
    .sw         (sw),
    .si         (si),
    .so         (so)
);

endmodule
