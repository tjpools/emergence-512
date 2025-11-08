# Simple "Hello World!" Bootloader

## Understanding the Raw Binary: How Systems Come to Life

This project is an exploration of the most fundamental level of computing—creating a **raw executable binary** that runs directly on hardware without an operating system. By building a bootloader from scratch, we witness firsthand how a computer system awakens from its powered-off state and begins executing code.

### What Makes This Special?

Unlike typical programs that rely on an OS, runtime libraries, or language frameworks, this bootloader is:

- **Truly raw**: Direct machine code that speaks to hardware through BIOS
- **Self-contained**: No dependencies, no libraries, no OS—just 512 bytes of pure executable
- **First code to run**: This is what executes when you power on a computer
- **The foundation**: This is how every operating system (including Fedora, Windows, Linux) begins its journey

### The Boot Process Unveiled

When you press the power button:

1. **Power-On Self Test (POST)**: Hardware initializes
2. **BIOS/UEFI loads**: Firmware takes control
3. **First 512 bytes loaded**: BIOS reads our bootloader from disk into memory at `0x7C00`
4. **CPU jumps to our code**: This is where our "Hello World!" lives
5. **We control everything**: Screen, keyboard, disk—all through our code
6. **Chain-load to OS**: We hand control to the real OS bootloader (GRUB, etc.)

This bootloader sits at step 4, giving us complete control before any OS exists.

## Features

- Displays "Hello World!" directly to hardware (no printf, no console API)
- Pure x86 assembly—as close to the metal as you can get
- 512-byte MBR-compliant bootloader with proper boot signature
- Demonstrates BIOS interrupt handling (`INT 0x10`, `INT 0x16`, `INT 0x13`)
- Chain-loading capability to pass control to the OS

## The Anatomy of a Raw Executable

### What is a "Raw Binary"?

Unlike typical executables (ELF on Linux, PE on Windows), our bootloader is a **raw binary**:

- **No file format**: No headers, no metadata, just pure machine code
- **Direct execution**: Every byte is either an instruction or data
- **Position-dependent**: Code is written to run at a specific memory address (`0x7C00`)
- **No loader needed**: BIOS directly loads and executes it

When we assemble `boot.asm`, NASM produces `boot.bin`—exactly 512 bytes that the CPU can execute directly. This is machine code in its purest form.

### How Our Bootloader Brings the System to Life

1. **Power-on → BIOS takes control**
   - Hardware is initialized
   - BIOS searches for bootable devices (looks for `0xAA55` signature)

2. **BIOS loads our raw binary**
   - Reads first 512 bytes from boot device
   - Copies it to memory address `0x7C00`
   - CPU jumps to `0x7C00` and starts executing *our* code

3. **We initialize the environment** (lines 8-12 of boot.asm)
   - Set up segment registers (DS, ES, SS)
   - Initialize stack pointer
   - *We are now in control*

4. **Direct hardware interaction**
   - Clear screen using `INT 0x10` (BIOS video service)
   - Print "Hello World!" character by character
   - No operating system, no libraries—just us and the BIOS

5. **Wait for user input**
   - Use `INT 0x16` (BIOS keyboard service)
   - We're running in a pre-OS environment

6. **Chain-load to OS**
   - Read next sector from disk using `INT 0x13`
   - Jump to that code (typically GRUB or another bootloader)
   - Fedora's boot process begins

## Prerequisites

You need the following tools installed:

```bash
# On Fedora/RHEL
sudo dnf install nasm qemu-system-x86

# On Ubuntu/Debian
sudo apt install nasm qemu-system-x86

# On Arch
sudo pacman -S nasm qemu
```

## Building

To assemble the bootloader:

```bash
make
```

This creates `boot.bin`, a 512-byte bootloader binary.

## Testing

### Option 1: QEMU (Recommended)

Test the bootloader in QEMU virtual machine:

```bash
make test
```

Or explicitly:

```bash
make test-qemu
```

### Option 2: Create Disk Image

Create a full disk image:

```bash
make bootloader.img
make test-qemu-img
```

### Option 3: View the Code

See hexadecimal representation:

```bash
make hexdump
```

Disassemble the bootloader:

```bash
make disasm
```

## Installing to Real Hardware (Advanced)

⚠️ **WARNING**: This will overwrite the MBR of your device. Only do this on a USB drive or disk you're willing to erase!

1. Build the bootloader:
   ```bash
   make
   ```

2. Write to USB drive (replace `/dev/sdX` with your USB device):
   ```bash
   sudo dd if=boot.bin of=/dev/sdX bs=512 count=1
   ```

3. Boot from the USB drive

## Installing on Fedora (Before OS Loads)

To make this bootloader run before Fedora boots on real hardware:

1. **Create a bootable USB** with the bootloader as described above
2. **Boot from USB** - Set your BIOS/UEFI to boot from USB first
3. The bootloader will display "Hello World!" and wait for a keypress
4. When you press a key, it attempts to chain-load the next boot sector
5. To actually boot Fedora after this, you'd need to modify the chain-loading part to point to Fedora's bootloader location

### Integration with GRUB (Safer Method)

For a safer integration without overwriting your MBR:

1. Build the bootloader
2. Copy `boot.bin` to `/boot`:
   ```bash
   sudo cp boot.bin /boot/hello-bootloader.bin
   ```
3. Add a GRUB menu entry in `/etc/grub.d/40_custom`:
   ```
   menuentry "Hello World Bootloader" {
       set root=(hd0,1)
       chainloader /boot/hello-bootloader.bin
       boot
   }
   ```
4. Update GRUB:
   ```bash
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg
   ```

## File Structure

- `boot.asm` - Main bootloader source code in x86 assembly
- `Makefile` - Build system
- `README.md` - This file

## Technical Deep Dive: Inside the Raw Binary

### The Magic 512 Bytes

Our bootloader must be exactly 512 bytes because:
- **MBR standard**: Master Boot Record is one disk sector (512 bytes)
- **Boot signature**: Last 2 bytes must be `0x55 0xAA` for BIOS to recognize it as bootable
- **Usable space**: Only 510 bytes for our code and data
- **Everything counts**: Every instruction, every character of our message

### Memory Layout at Boot Time

```
0x00000 - 0x003FF : Interrupt Vector Table (IVT)
0x00400 - 0x004FF : BIOS Data Area
0x00500 - 0x07BFF : Free memory
0x07C00 - 0x07DFF : Our bootloader (512 bytes) ← We are here!
0x07E00 - 0x9FFFF : Free memory (where we load the OS)
0xA0000 - 0xFFFFF : Video memory, BIOS, etc.
```

### Why 16-bit Real Mode?

When the CPU first powers on, it starts in **16-bit real mode**:
- Direct hardware access without memory protection
- Can only address 1 MB of memory
- Uses segment:offset addressing
- No virtual memory, no privilege levels
- This is how computers worked in the 1980s!

Our bootloader runs in this primitive environment, demonstrating computing at its most fundamental level.

### BIOS Interrupts: The Pre-OS API

Without an OS, how do we interact with hardware? Through **BIOS interrupts**:

- `INT 0x10` - Video services (our screen output)
- `INT 0x13` - Disk services (reading sectors)
- `INT 0x16` - Keyboard services (waiting for input)

These are software interrupts that call BIOS firmware routines—the only "API" available before an OS loads.

### From Assembly to Machine Code

When we run `nasm -f bin boot.asm -o boot.bin`:

```
Assembly:           Machine Code:
mov ah, 0x0E   →    B4 0E
int 0x10       →    CD 10
```

The assembler translates human-readable mnemonics into raw bytes that the CPU understands. No compilation, no linking—just direct translation to executable code.

## Why This Matters: The Bottom of the Stack

This project strips away every layer of abstraction:
- ❌ No Python/Java/C runtime
- ❌ No standard library
- ❌ No system calls
- ❌ No operating system
- ❌ No file formats
- ✅ Just CPU, BIOS, and raw machine code

Understanding this level reveals:
- How operating systems bootstrap themselves
- What "bare metal" really means
- Why bootloaders like GRUB exist
- The foundation of all higher-level computing

## Seeing the Raw Binary in Action

### Examining Our Executable

After building, let's inspect the raw binary:

```bash
# View the raw bytes
hexdump -C boot.bin | head -20
```

You'll see actual machine code:
```
00000000  31 c0 8e d8 8e c0 8e d0  bc 00 7c b4 00 b0 03 cd  |1.........|.....|
00000010  10 be 4c 7c e8 1a 00 be  67 7c e8 14 00 31 c0 cd  |..L|....g|...1..|
...
000001f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 55 aa  |..............U.|
```

Notice the `55 aa` at the end—that's our boot signature!

### Disassemble the Binary

See what the CPU actually executes:

```bash
make disasm
```

```
00000000  31C0              xor ax,ax
00000002  8ED8              mov ds,ax
00000004  8EC0              mov es,ax
...
```

This is the raw machine code in human-readable form—no abstractions, just instructions.

## Experiments and Learning

### Modify the Message

Edit `boot.asm` and change the message:
```asm
msg: db 'Hello World!', 0x0D, 0x0A, 0x0D, 0x0A, 0
```

Rebuild and see your change appear at the hardware level!

### Add Colors

Modify the print function to use colored text:
```asm
mov ah, 0x0E    ; Teletype function
mov bl, 0x0A    ; Light green color
```

### Measure the Raw Binary

```bash
ls -l boot.bin
# Result: exactly 512 bytes
```

Every byte matters in this constrained environment!

### Compare Sizes

This 512-byte raw executable does what would take:
- A C program with libraries: ~20 KB (with static linking)
- A Python script with interpreter: ~15 MB
- A Java program with JVM: ~100 MB+

Raw binaries are the ultimate in efficiency—no overhead, no runtime, just code.

## Educational Value

This project teaches:

1. **Computer architecture**: How CPUs, memory, and BIOS interact
2. **Assembly language**: Direct hardware programming
3. **Binary formats**: Understanding executables at the byte level
4. **Boot process**: How every OS gets its start
5. **Systems programming**: Working without abstractions
6. **Historical context**: How early computers worked

## Clean Up

Remove all build artifacts:

```bash
make clean
```

**QEMU not found**: Install QEMU with your package manager (see Prerequisites)

**NASM not found**: Install NASM assembler (see Prerequisites)

**Bootloader doesn't appear on real hardware**: 
- Ensure BIOS is set to legacy/CSM mode (not pure UEFI)
- Verify the device is set as first boot priority
- Check that boot.bin was written correctly with `dd`

**"Error loading OS!" message**: 
- This is normal when testing - there's no OS in the next sector
- The bootloader tries to chain-load but fails gracefully

## Further Exploration

### Next Steps in Understanding System Bootstrap

1. **Add more functionality**: Try reading additional sectors, implementing a simple file system
2. **Study GRUB**: Examine how real bootloaders work (GRUB is much more complex!)
3. **Explore protected mode**: Learn about transitioning from 16-bit to 32-bit mode
4. **Build a tiny OS**: Extend this to create a minimal operating system kernel
5. **Read about UEFI**: Modern replacement for BIOS (more complex but more powerful)

### Resources

- Intel x86 instruction set reference
- BIOS interrupt reference
- "Operating Systems: Three Easy Pieces" (free online book)
- OSDev.org wiki (comprehensive OS development resource)

## Conclusion

This simple "Hello World!" bootloader is more than a toy—it's a window into the fundamental operation of computers. By creating a raw executable binary that runs before any OS, we've touched the bare metal and witnessed how systems truly come to life, one instruction at a time.

Every modern operating system, no matter how sophisticated, begins its journey in a place very much like this: a small amount of code, loaded by firmware, that takes control and builds up the complex software stack we use every day.

Welcome to the bottom of the stack. Welcome to where it all begins.

## License

This is an educational bootloader project. Feel free to use, modify, and learn from it.
