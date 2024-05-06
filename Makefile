BUILD_DIR := build
SRC_DIR   := src
ISO_DIR   := isodir

CC  := gcc
LD  := ld
ASM := nasm

CFLAGS   := -m32 -march=i386 -O2 -lto -mgeneral-regs-only -static -fPIC -fstack-protector -ffreestanding -Wall -Wextra -Werror -I$(SRC_DIR)
ASMFLAGS := -f elf32
LDFLAGS  := -m elf_i386 -T $(SRC_DIR)/linker.ld -nostdlib -flto

SRCS :=								\
	drivers/debug.c					\
	drivers/gdt.c					\
	drivers/idt.c					\
	drivers/interrupt.asm			\
	drivers/key.c					\
	drivers/pci.c					\
	drivers/pic.c					\
	drivers/pit.c					\
	drivers/ports.c					\
	drivers/ps2_keyboard.c			\
	drivers/keymaps/ps2_keymap_fi.c	\
	drivers/keymaps/ps2_keymap_us.c	\
	drivers/ps2.c					\
	drivers/sound.c					\
	drivers/storage/ata.c			\
	drivers/storage/device.c		\
	drivers/storage/gpt.c			\
	drivers/storage/partition.c		\
	drivers/ssp.c					\
	drivers/utils.c					\
	drivers/vga.c					\
	kernel/kernel.c					\
	kernel/krnentry.asm				\
	kernel/panic.c					\
	memory/kmalloc.c				\
	shell/shell.c					\
	shell/terminal.c				\

OBJS := $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(SRCS)))
DEPS := $(addprefix $(BUILD_DIR)/,$(addsuffix .d,$(filter-out %.asm,$(SRCS))))

.PHONY: all kernel iso run clean

all: kernel

kernel: $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(BUILD_DIR)/ChoacuryOS.bin
	grub-file --is-x86-multiboot $(BUILD_DIR)/ChoacuryOS.bin	

iso: kernel
	@mkdir -p $(ISO_DIR)/boot/grub
	cp $(BUILD_DIR)/ChoacuryOS.bin $(ISO_DIR)/boot/ChoacuryOS.bin
	cp $(SRC_DIR)/boot/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(BUILD_DIR)/ChoacuryOS.iso $(ISO_DIR)

run: iso
	qemu-system-x86_64 -hda $(BUILD_DIR)/ChoacuryOS.iso -serial stdio -audiodev pa,id=snd0 -machine pcspk-audiodev=snd0

clean:
	rm -rf $(BUILD_DIR) $(ISO_DIR)

-include $(DEPS)

$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c Makefile
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.asm.o: $(SRC_DIR)/%.asm
	@mkdir -p $(@D)
	$(ASM) $(ASMFLAGS) $< -o $@
