class Core {
protected:

    Uint32 s[256];      // Размер стека 1K
    Uint32 r[256];      // Количество регистров 32 битные, 1 Кб блочной памяти ПЛИС
    Uint8  psw;         // Регистр флагов
    Uint32 pc;          // Program Counter
    Uint8* mem;
    Uint32 mem_max;

public:

    Core(int argc, char** argv);
    ~Core();
    int     step();
    Uint8   fetch();
    Uint32  fetch_dword();
    Uint8   read(Uint32 a);
    void    write(Uint32 a, Uint8 b);
};

// ---------------------------------------------------------------------

Core::Core(int argc, char** argv) {

    psw     = 0;
    mem_max = 0xFFFF; // 64K
    mem     = (Uint8*) malloc(mem_max + 1);

    FOR (i,0,255) { s[i] = 0; r[i] = 0; }
    FOR (i,0,mem_max) mem[i] = 0;

    if (argc >= 2) {
        FILE* fp = fopen(argv[1], "rb");
        if (fp) {
            (void) fread(mem, 1, 65536, fp);
            fclose(fp);
        } else {
            printf("File not found: %s\n", argv[1]);
        }
    }
}

Core::~Core() {
    free(mem);
}

// Считывание следующего байта
Uint8 Core::fetch() {

    Uint8 r = mem[pc & mem_max];
    pc = (pc + 1) & mem_max;
    return r;
}

// Загрузка 32-х битного значения
Uint32 Core::fetch_dword() {

    Uint8 a = fetch();
    Uint8 b = fetch();
    Uint8 c = fetch();
    Uint8 d = fetch();
    return (d<<24) + (c<<16) + (b << 8) + a;
}

// Чтение байта из памяти
Uint8 Core::read(Uint32 a) {
    return mem[a & mem_max];
}

// Запись байта в память
void Core::write(Uint32 a, Uint8 b) {
    mem[a & mem_max] = b;
}

// -----------------------------------------------------------------------------

int Core::step() {

    Uint8  a, b, c, d;
    Uint8  opcode = fetch();
    Uint32 t;
    Uint64 m;

    switch (opcode) {

        // MOV r, Imm32
        case 0x00: {

            a    = fetch();
            r[a] = fetch_dword();
            return 6;
        }

        // MOV A, B
        case 0x01: {

            b = fetch();
            a = fetch();
            r[a] = r[b];
            return 3;
        }

        // MOVB A, [B]
        case 0x02: {

            b = fetch();
            a = fetch();
            r[a] = read(r[b]);
            return 5;
        }

        // MOVW A, [B]
        case 0x03: {

            b = fetch();
            a = fetch();
            t = r[b];
            r[a] = read(t) + (read(t+1) << 8);
            return 6;
        }

        // MOVD A, [B]
        case 0x04: {

            b = fetch();
            a = fetch();
            t = r[b];
            r[a] = read(t) + (read(t+1) << 8) + (read(t+2) << 16) + (read(t+3) << 24);
            return 8;
        }

        // MOVB [A], B
        case 0x05: {

            b = fetch();
            a = fetch();
            write(r[a], r[b]);
            return 5;
        }

        // MOVW [A], B
        case 0x06: {

            b = fetch();
            a = fetch();
            t = r[a];
            write(t,   r[b]);
            write(t+1, r[b]>>8);
            return 6;
        }

        // MOVD [A], B
        case 0x07: {

            b = fetch();
            a = fetch();
            t = r[a];
            write(t,   r[b]);
            write(t+1, r[b] >> 8);
            write(t+2, r[b] >> 16);
            write(t+3, r[b] >> 24);
            return 8;
        }

        // MUL
        case 0x08: {

            b = fetch();
            c = fetch();
            a = fetch();
            d = fetch();
            m = a * b;
            r[c] = m;
            r[d] = m >> 32;
            return 5;
        }

        // DIV
        case 0x09: {

            b = fetch();
            c = fetch();
            a = fetch();
            d = fetch();
            r[c] = a / b;
            r[d] = m % b;
            return 38;
        }

        // MOVS A, I8
        case 0x1E: {

            a = fetch();
            b = fetch();
            if (b & 0x80) b |= 0xFFFFFF00;
            r[a] = b;
            return 3;
        }
    }

    return 1;
}
