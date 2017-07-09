OUTPUT_FORMAT(binary)
SECTIONS
{
  . = 0x7c00;
  .text : {
    *(.text);
    BYTE(0xf0);
    BYTE(0xff);
    BYTE(0xff);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    . += 4600;
    BYTE(0xf0);
    BYTE(0xff);
    BYTE(0xff);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    BYTE(0);
    . += 1469432;
  } = 0x00000000
}
