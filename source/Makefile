BUILD := ./build
SRC := .

ENTRYPOINT:=0x10000

# 编译 boot 目录下的 boot.asm 和 loader.asm 文件，生成 boot.bin 和 loader.bin 文件
$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

# 编译 kernel 目录下的 start.asm 文件，生成 start.o 文件
$(BUILD)/kernel/%.o: $(SRC)/kernel/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f elf32 $< -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel/start.o
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -static $^ -o $@ -Ttext $(ENTRYPOINT)


$(BUILD)/system.bin: $(BUILD)/kernel.bin
	$(shell mkdir -p $(dir $@))
	objcopy -O binary $< $@

$(BUILD)/system.map: $(BUILD)/kernel.bin
	$(shell mkdir -p $(dir $@))
	nm $< | sort > $@


$(BUILD)/image/master.img:  $(BUILD)/boot/boot.bin \
							$(BUILD)/boot/loader.bin \
							$(BUILD)/system.bin \
							$(BUILD)/system.map
	$(shell mkdir -p $(dir $@))
	yes | bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $(BUILD)/image/master.img
	dd if=$(BUILD)/boot/boot.bin of=$(BUILD)/image/master.img bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/boot/loader.bin of=$(BUILD)/image/master.img bs=512 count=4 seek=2 conv=notrunc
	dd if=$(BUILD)/system.bin of=$(BUILD)/image/master.img bs=512 count=200 seek=10 conv=notrunc


.PHONY: clean

clean:
	sudo rm -rf $(BUILD)
	sudo rm -f $(SRC)/*.ini


.PHONY: bochs
bochs: $(BUILD)/image/master.img
	bochs -f $(SRC)/bochs/bochsrc -q