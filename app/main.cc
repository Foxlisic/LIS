#include <qb.h>
#include "core.cc"

Core* core;

program(13)

    core = new Core(argc, argv);
    fps { }
    delete core;

end
