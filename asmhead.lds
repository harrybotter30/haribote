OUTPUT_FORMAT(binary)
SECTIONS
{
  . = 0xc200;
  .text : { *(.text); }
}
