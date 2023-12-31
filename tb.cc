#include <stdlib.h>

#include "obj_dir/Vga.h"
#include "obj_dir/Vcpu.h"
#include "tb.h"

int main(int argc, char **argv) {

    Main* app = new Main(640, 400, 2, 25);

    app->load(argc, argv);

    // -------------------------------------
    Verilated::commandArgs(argc, argv);
    // -------------------------------------

    // Обработка возникшего события
    while (app->event()) {
        app->frame();
    }

    delete app;

    exit(EXIT_SUCCESS);
}
