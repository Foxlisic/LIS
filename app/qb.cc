// Активация видеорежима
void screen(int x, int parameter = 0) {

    _videomode  = x;
    _width      = 640,
    _height     = 400,
    _scale      = 2;
    _save_frame = 1;
    _x_term     = 0;
    _y_term     = 0;
    _fore       = 15;
    _back       = -1;
    _font_size  = 16;

    switch (x) {

        case  3: _width = 640; _height = 400; _scale = 2; _font_size = 16; break;
        case 12: _width = 640; _height = 480; _scale = 2; _font_size = 16; break;
        case 13: _width = 320; _height = 200; _scale = 4; _font_size = 8;  break;
    }

    _screen_buffer      = (Uint32*) malloc(_width * _height * sizeof(Uint32));
    _screen_buffer_idx  = (Uint8*)  malloc(_width * _height * sizeof(Uint8));
    _sdl_window         = SDL_CreateWindow("Quick Basic Example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, _scale * _width, _scale * _height, SDL_WINDOW_SHOWN);
    _sdl_renderer       = SDL_CreateRenderer(_sdl_window, -1, SDL_RENDERER_PRESENTVSYNC);
    _sdl_screen_texture = SDL_CreateTexture(_sdl_renderer, SDL_PIXELFORMAT_BGRA32, SDL_TEXTUREACCESS_STREAMING, _width, _height);

    SDL_SetTextureBlendMode(_sdl_screen_texture, SDL_BLENDMODE_NONE);

    // Скопировать палитру для возможного будущего изменения
    for (int i = 0; i < 256; i++) _dos_palette[i] = dos_palette[i];

    // Создать новый файл
    if (_save_frame) { FILE* fp = fopen("out/record.ppm", "wb"); if (fp) fclose(fp); else _save_frame = 0; }
}

// Сохранение фрейма
void save() {

    FILE* fp = fopen("out/record.ppm", "ab");
    if (fp) {

        fprintf(fp, "P6\n# Verilator\n%d %d\n255\n", _width, _height);
        for (int y = 0; y < _height; y++)
        for (int x = 0; x < _width; x++) {
            fwrite(&_screen_buffer[y*_width + x], 1, 3, fp);
        }

        fclose(fp);
    }
}

// Обработка фрейма
int frame() {

    SDL_Event evt;
    SDL_Rect  dstRect;

    for (;;) {

        Uint32 ticks = SDL_GetTicks();

        // Обработать все новые события
        while (SDL_PollEvent(& evt)) {

            switch (evt.type) {

                case SDL_QUIT:
                    return 0;

                case SDL_KEYDOWN:

                    // kbd_scancode(evt.key.keysym.scancode, 0);
                    break;

                case SDL_KEYUP:

                    // kbd_scancode(evt.key.keysym.scancode, 1);
                    break;
            }
        }

        // Истечение таймаута
        if (ticks - _prev_ticks >= 40) {

            _prev_ticks = ticks;

            dstRect.x = 0;
            dstRect.y = 0;
            dstRect.w = _scale * _width;
            dstRect.h = _scale * _height;

            SDL_UpdateTexture       (_sdl_screen_texture, NULL, _screen_buffer, _width * sizeof(Uint32));
            SDL_SetRenderDrawColor  (_sdl_renderer, 0, 0, 0, 0);
            SDL_RenderClear         (_sdl_renderer);
            SDL_RenderCopy          (_sdl_renderer, _sdl_screen_texture, NULL, &dstRect);
            SDL_RenderPresent       (_sdl_renderer);

            // Указано сохранение кадра
            if (_save_frame) save();

            return 1;
        }

        SDL_Delay(1);
    }
}

// Удалить окно
void destroy() {

    free(_screen_buffer);
    SDL_DestroyTexture  (_sdl_screen_texture);
    SDL_DestroyRenderer (_sdl_renderer);
    SDL_DestroyWindow   (_sdl_window);
    SDL_Quit();
}

// Очистка экрана в определенный цвет из палитры
void cls(Uint8 idx = 0) {

    for (int x = 0; x < _height * _width; x++) {
        _screen_buffer    [x] = _dos_palette[idx];
        _screen_buffer_idx[x] = idx;
    }
}

// Установка точки
void pset(int x, int y, Uint8 idx) {

    if (x < 0 || y < 0 || x > _width || y >= _height)
        return;

    _screen_buffer    [y*_width + x] = _dos_palette[idx];
    _screen_buffer_idx[y*_width + x] = idx;
}

// Чтение точки (IDX)
Uint8 point(int x, int y) {

    if (x < 0 || y < 0 || x > _width || y >= _height)
        return 0;

    return _screen_buffer_idx[y*_width + x];
}

// Линия по Брезенхэму
void line(int x1, int y1, int x2, int y2, Uint8 color) {

    // Инициализация смещений
    int signx  = x1 < x2 ? 1 : -1;
    int signy  = y1 < y2 ? 1 : -1;
    int deltax = x2 > x1 ? x2 - x1 : x1 - x2;
    int deltay = y2 > y1 ? y2 - y1 : y1 - y2;
    int error  = deltax - deltay;
    int error2;

    // Если линия - это точка
    pset(x2, y2, color);

    // Перебирать до конца
    while ((x1 != x2) || (y1 != y2)) {

        pset(x1, y1, color);
        error2 = 2 * error;
        if (error2 > -deltay) { error -= deltay; x1 += signx; }
        if (error2 <  deltax) { error += deltax; y1 += signy; }
    }
}

Uint32 rgb(int r, int g, int b) {

    r = (r < 0) ? 0 : (r > 255 ? 255 : r);
    g = (g < 0) ? 0 : (g > 255 ? 255 : g);
    b = (b < 0) ? 0 : (b > 255 ? 255 : b);
    return r*65536 + g*256 + b;
}

// Сформировать палитру
void palette(Uint8 idx, Uint32 rgb) {
    _dos_palette[idx] = rgb;
}

// Создать монотонную палитру grayscale
void palette_gray() {

    for (int idx = 0; idx < 256; idx++)
        _dos_palette[idx] = idx + 256*idx + 65536*idx;
}

// Цвет символов и прочего
void color(int fore, int back = -1) {
    _fore = fore;
    _back = back;
}

// Установки курсора
void locate(int x, int y) {
    _x_term = x;
    _y_term = y;
}

// Размер шрифта 8 или 16
void font(int size) {
    _font_size = size;
}

// Печать одного символа на экране
void printch(unsigned char ch) {

    for (int i = 0; i < _font_size; i++)
    for (int j = 0; j < 8;  j++) {

        int k  = _font_size == 16 ? font8x16[16*ch + i] : font8x8[8*ch + i];
        int cl = k & (1 << (7-j)) ? _fore : _back;
        if (cl >= 0) pset(_x_term + j, _y_term + i, cl);
    }
}

// Печать строки на экране
void print(const char* s) {

    int i = 0;
    while (s[i]) {

        printch(s[i]); i++;
        _x_term += 8;
    }
}
