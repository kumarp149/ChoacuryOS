/*
    The kernel of Choacury
    I call it the Choakern! The code still needs to be finished tho...
*/

/* Includes needed for the kernel to actually work.*/
#include "../drivers/ports.h"
#include "../drivers/gdt.h"
#include "../drivers/idt.h"
#include "../drivers/pic.h"
#include "../drivers/ps2.h"
#include "../drivers/ps2_keymap_fi.h"
#include "../drivers/types.h"
#include "../drivers/vga.h"

/* A Simple kernel written in C */
void k_main() 
{
    gdt_init();
    idt_init();

    /* Display Info Message */
    k_clear_screen();
    k_printf("\xB0\xB1\xB2\xDB Welcome to Choacury! \xDB\xB2\xB1\xB0", 0, 9);
    k_printf("Version: Post Reset Build Jan 5th 2024\n"                
             "(C)opyright: \2 Pineconium 2023, 2024\n", 1, 7);
    
    pic_init();

    ps2_init();
    /* FIXME: support more keymaps :) */
    ps2_init_keymap_fi();

    /* I think we should put some keyboard control here */

    /* Text Cursor control */
    // Note QEMU might cause some weird artifacts when loaded.
    port_byte_out(0x3d4, 14);
    int position = port_byte_in(0x3d5);
    position = position << 8;

    port_byte_out(0x3d4, 15);
    position += port_byte_in(0x3d5);

    int offset_from_vga = position * 2;

    /* Enable interrupts to make keyboard work */
    asm volatile("sti");

    /* Quick hack to print keyboard input */
    u16* vga_mem = (u16*)0xb8000;
    vga_mem += 80 * 4;

    /* Allow Keyboard Entry stuff, but this doesnt work on VirtualBox */
    for (;;) {
        key_event_t event;
        ps2_get_key_event(&event);

        if (event.key == KEY_NONE || (event.modifiers & KEY_EVENT_MODIFIERS_RELEASED)) {
            asm volatile("hlt");
            continue;
        }

        /* Backspace handler */
        if (event.key == KEY_Backspace) {
            if (vga_mem > (u16*)0xb8000 + 80 * 4) {
                *(--vga_mem) = (TC_WHITE << 8) | ' ';   // <-- Replaces the previous character with a blank space
            }
            continue;
        }

        /* Enter Key/New Line Character */
        if (event.key == KEY_Enter) {
            u32 line = (vga_mem - (u16*)0xb8000) / 80;
            vga_mem = (u16*)0xb8000 + (line + 1) * 80;  // <-- Prints a new line, but it kinda fills the remaining spaces in the line above with space characters
                                                        // Meaning it can be annoying to edit the line above without arrow support
            continue;
        }

        const char* utf8 = key_to_utf8(&event);
        if (!utf8)
            continue;

        while (*utf8) {
            *vga_mem++ = (TC_WHITE << 8) | *utf8++;
        }
    }
};
