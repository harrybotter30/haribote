OUTPUT_FORMAT(binary);

SECTIONS
{
    .head : {
        LONG(0x310000+((SIZEOF(.data)+4095) & ~ 4095)) /*  0 : .data+heap の大きさ（4KBの倍数） + 0x00310000 */
        LONG(0x69726148)      /*  4 : シグネチャ "Hari" */
        LONG(0)               /*  8 : mmarea の大きさ（4KBの倍数） */
        LONG(0x310000)        /* 12 : スタック初期値＆.data転送先 */
        LONG(SIZEOF(.data))   /* 16 : .dataサイズ */
        LONG(LOADADDR(.data)) /* 20 : .dataの初期値列のファイル位置 */
        LONG(0xE9000000)      /* 24 : 0xE9000000 */
        LONG(HariStartup - 0x20) /* 28 : エントリアドレス - 0x20 */
        LONG(0x310000+SIZEOF(.data)) /* 32 : heap領域（malloc領域）開始アドレス */
    }

    .text : {
        _btext = .;
        EXCLUDE_FILE(startup.o) *(.text)
        startup.o(.text)
        . = (. + 3) & ~ 3;
        _etext = .;
    } = 0x00000000

    .data 0x310000 : AT (ADDR(.text) + SIZEOF(.text)) ALIGN(4) {
        _bdata = .;
        *(.data)
        *(.rodata*)
        *(.bss)
        . = (. + 3) & ~ 3;
        _edata = .;
    } = 0x00000000

    /DISCARD/ : { *(.eh_frame) }

}
