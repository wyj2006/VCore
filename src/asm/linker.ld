MEMORY
{
    RAM (rwx) : ORIGIN = 0, LENGTH = 1024
}

SECTIONS
{
    . = 0;
    .text :
    {
        *(.text)
    } > RAM

    .data :
    {
        *(.data)
    } > RAM
}