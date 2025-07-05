boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

master.img: boot.bin
	yes | bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat master.img
	dd if=boot.bin of=master.img bs=512 count=1 conv=notrunc

.PHONY: clean

clean:
	sudo rm -f *.bin
	sudo rm -f *.img
	sudo rm -f *.lock


.PHONY: bochs
bochs: master.img
	bochs -q