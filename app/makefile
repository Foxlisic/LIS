all:
	fasm main.asm main.bin
	g++ main.cc -Wno-unused-result -I. -Os -o main -lSDL2_mixer -lSDL2 -lm
	./main main.bin
clean:
	rm -rf main main.bin