#include <stdlib.h>

#include "obj_dir/Vga.h"
#include "tb.h"

int main(int argc, char **argv) {

    Main* app = new Main(640, 400, 2, 25);

    // -------------------------------------
    Verilated::commandArgs(argc, argv);
    // -------------------------------------

    // Обработка возникшего события
    while (int event = app->event()) {

        // 1 кадр = 1 млн тактов
        if (event == EvtRedraw) {
            app->frame();
        }
    }

    delete app;

    exit(EXIT_SUCCESS);
}
