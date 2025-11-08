# Makefile for building the bootloader

# Output file
BOOTLOADER = boot.bin
ISO_IMAGE = bootloader.iso
IMG_IMAGE = bootloader.img

# Assembler
AS = nasm
ASFLAGS = -f bin

# Source files
SRC = boot.asm

.PHONY: all clean test test-qemu test-bochs

all: $(BOOTLOADER)

# Assemble the bootloader
$(BOOTLOADER): $(SRC)
	$(AS) $(ASFLAGS) $(SRC) -o $(BOOTLOADER)
	@echo "Bootloader compiled successfully!"
	@ls -lh $(BOOTLOADER)

# Create a bootable disk image (raw format)
$(IMG_IMAGE): $(BOOTLOADER)
	dd if=$(BOOTLOADER) of=$(IMG_IMAGE) bs=512 count=1
	# Pad to 1.44MB floppy size
	dd if=/dev/zero of=$(IMG_IMAGE) bs=512 count=2879 seek=1
	@echo "Disk image created: $(IMG_IMAGE)"

# Test with QEMU (most common)
test-qemu: $(BOOTLOADER)
	qemu-system-x86_64 -drive format=raw,file=$(BOOTLOADER) -m 512

# Test with QEMU using disk image
test-qemu-img: $(IMG_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(IMG_IMAGE) -m 512

# Test with Bochs
test-bochs: $(BOOTLOADER)
	@echo "Creating Bochs configuration..."
	@echo "megs: 32" > bochsrc.txt
	@echo "romimage: file=/usr/share/bochs/BIOS-bochs-latest" >> bochsrc.txt
	@echo "vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest" >> bochsrc.txt
	@echo "floppya: 1_44=$(BOOTLOADER), status=inserted" >> bochsrc.txt
	@echo "boot: floppy" >> bochsrc.txt
	bochs -f bochsrc.txt -q

# Default test target
test: test-qemu

# Clean build artifacts
clean:
	rm -f $(BOOTLOADER) $(IMG_IMAGE) $(ISO_IMAGE) bochsrc.txt
	@echo "Cleaned build artifacts"

# Show hexdump of bootloader (useful for debugging)
hexdump: $(BOOTLOADER)
	hexdump -C $(BOOTLOADER) | head -20

# Disassemble the bootloader (requires ndisasm)
disasm: $(BOOTLOADER)
	ndisasm -b 16 $(BOOTLOADER) | head -50
