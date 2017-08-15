OUTPUT_FORMAT(binary)
SECTIONS
{
  .ipl : {
    boot.o (.data);
  }
  .fat12 : {
    BYTE(0xf0); BYTE(0xff); BYTE(0xff); BYTE(0x03);
    BYTE(0x40); BYTE(0x00); BYTE(0x05); BYTE(0x60);
    BYTE(0x00); BYTE(0x07); BYTE(0x80); BYTE(0x00);
    BYTE(0x09); BYTE(0xa0); BYTE(0x00); BYTE(0x0b);
    BYTE(0xc0); BYTE(0x00); BYTE(0xff); BYTE(0x0f);
    . += 4588;
    BYTE(0xf0); BYTE(0xff); BYTE(0xff); BYTE(0x03);
    BYTE(0x40); BYTE(0x00); BYTE(0x05); BYTE(0x60);
    BYTE(0x00); BYTE(0x07); BYTE(0x80); BYTE(0x00);
    BYTE(0x09); BYTE(0xa0); BYTE(0x00); BYTE(0x0b);
    BYTE(0xc0); BYTE(0x00); BYTE(0xff); BYTE(0x0f);
    . += 4588;
    BYTE(0x48);                 /* 'H' */
    BYTE(0x41);                 /* 'A' */
    BYTE(0x52);                 /* 'R' */
    BYTE(0x49);                 /* 'I' */
    BYTE(0x42);                 /* 'B' */
    BYTE(0x4f);                 /* 'O' */
    BYTE(0x54);                 /* 'T' */
    BYTE(0x45);                 /* 'E' */
    BYTE(0x53);                 /* 'S' */
    BYTE(0x59);                 /* 'Y' */
    BYTE(0x53);                 /* 'S' */
    BYTE(0x20);                 /* Attr: ATTR_ARCHIVE */
    . += 10;                    /* unused for FAT12 */
    SHORT(0);                   /* WrtTime: 00:00:00 */
    SHORT(0x2a21);              /* WrtDate: 0010 101/0 001/0 0001: 2001/01/01 */
    SHORT(2);                   /* FstClusLO */
    LONG(SIZEOF(.file));        /* FileSize */
  } = 0x00000000
  . = 0x4200;                   /* 2nd cluster offset */
  .file : {
    file.o (.data);
  } = 0x00000000
  . = 0x5800;
  .nofile : {
    LONG(0);
    . = 1474560-0x5800;         /* 1440KB disk */
  } = 0x00000000
}
