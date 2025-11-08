; Simple MBR Bootloader that prints "Hello World!"
; This runs in 16-bit real mode before the OS loads

[BITS 16]           ; We're working in 16-bit real mode
[ORG 0x7C00]        ; BIOS loads bootloader at address 0x7C00

start:
    ; Initialize segment registers
    xor ax, ax      ; Clear AX register
    mov ds, ax      ; Set data segment to 0
    mov es, ax      ; Set extra segment to 0
    mov ss, ax      ; Set stack segment to 0
    mov sp, 0x7C00  ; Set stack pointer (grows downward from bootloader)

    ; Clear screen
    mov ah, 0x00    ; Function: Set video mode
    mov al, 0x03    ; Mode: 80x25 text mode
    int 0x10        ; Call BIOS video interrupt

    ; Print "Hello World!" message
    mov si, msg     ; Load address of message into SI
    call print_string

    ; Wait for keypress
    mov si, msg_key
    call print_string
    
    xor ax, ax      ; Function: Wait for keypress
    int 0x16        ; Call BIOS keyboard interrupt

    ; Chain-load to the next boot sector (hand off to OS)
    ; Load first sector of next device
    mov ah, 0x02    ; Function: Read sectors
    mov al, 1       ; Number of sectors to read
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (sector after bootloader)
    mov dh, 0       ; Head 0
    mov dl, 0x80    ; Drive (0x80 = first hard disk)
    mov bx, 0x7E00  ; Load to address after bootloader
    int 0x13        ; Call BIOS disk interrupt
    
    jc load_error   ; Jump if carry flag is set (error)
    
    ; Jump to loaded sector (OS bootloader)
    jmp 0x0000:0x7E00

load_error:
    mov si, msg_error
    call print_string
    jmp halt

halt:
    cli             ; Clear interrupts
    hlt             ; Halt the CPU
    jmp halt        ; In case of NMI, loop halt

; Function to print null-terminated string
; Input: SI = pointer to string
print_string:
    mov ah, 0x0E    ; BIOS teletype function

.loop:
    lodsb           ; Load byte at SI into AL, increment SI
    test al, al     ; Check if AL is 0 (null terminator)
    jz .done        ; If zero, we're done
    int 0x10        ; Call BIOS video interrupt to print character
    jmp .loop       ; Repeat for next character

.done:
    ret

; Data section
msg:        db 'Hello World!', 0x0D, 0x0A, 0x0D, 0x0A, 0
msg_key:    db 'Press any key to load OS...', 0x0D, 0x0A, 0
msg_error:  db 'Error loading OS!', 0x0D, 0x0A, 0

; Fill rest of bootloader with zeros and add boot signature
times 510-($-$$) db 0   ; Pad with zeros to byte 510
dw 0xAA55               ; Boot signature (marks this as bootable)
