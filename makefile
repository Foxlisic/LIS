CONF=-lSDL2
VPAR=-Wall -Wno-unused -Wno-width
VINC=/usr/share/verilator/include

all: ica
ica:
	iverilog -g2005-sv -o tb.qqq tb.v cpu.v
	vvp tb.qqq -o tb.vcd > vvp.log
	rm tb.qqq
tbc:
	verilator $(VPAR) -cc ga.v
	cd obj_dir && make -f Vga.mk
	g++ -o tb -I$(VINC) tb.cc $(VINC)/verilated.cpp obj_dir/Vga__ALL.a $(CONF)
	strip tb
	./tb
wav:
	gtkwave tb.gtkw
video:
	ffmpeg -framerate 60 -r 60 -i temp/%08d.ppm -vf "scale=w=1280:h=800,pad=width=1920:height=1080:x=320:y=140:color=black" -sws_flags neighbor -sws_dither none -f mp4 -q:v 0 -vcodec mpeg4 -y record.mp4
clean:
	rm -f tb temp/*.ppm *.o
