.PHONY: all clean release

all:
	mkdir -p build
	dasm src/dinosaur.asm -Isrc -Iinc -f3 -v0 -obuild/cart.bin -sbuild/cart.sym -lbuild/cart.lst

clean:
	rm -rf build

release: all
	mkdir -p release
	cp build/cart.bin release/Dino_v1.0.0.bin