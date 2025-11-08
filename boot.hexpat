// ImHex Pattern for Boot Loader Analysis
// Simplified version to avoid crashes

#pragma endian little

// Structure definition for the bootloader
struct Bootloader {
    // Code sections
    u8 init_code[11];
    u8 clear_screen[6];
    u8 print_hello[6];
    u8 print_keypress[6];
    u8 wait_key[4];
    u8 disk_read[16];
    u8 jump_handler[8];
    u8 error_path[7];
    u8 halt_code[5];
    u8 print_function[12];
    
    // Data sections
    char hello_msg[17];
    char key_msg[30];
    char error_msg[15];
    
    // Padding
    u8 padding[367];
    
    // Boot signature
    u8 boot_sig[2];
};

// Instantiate at offset 0
Bootloader bootloader @ 0x00;