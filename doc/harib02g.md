Next: [harib02h](harib02h.md), Previous: [harib02f](harib02f.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02g

### 課題

sprintf を使う。

### 学習

sprintf は [gcc の builtin 関数の一覧](https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html)に含まれていたので、libc をリンクしなくても使えるのではないかと期待したが、世の中そんなに甘くなかった。
\# 名前を __builtin_sprintf() に変更しても変わらず。

```shell-session
$ make
cc -E -fno-pic -Os -Wall  ipl10.S -o ipl10.s
as -al  ipl10.s -o ipl10.o >ipl10.lst
cc -E -fno-pic -Os -Wall  asmhead.S -o asmhead.s
as -al  asmhead.s -o asmhead.o >asmhead.lst
cc -E -fno-pic -Os -Wall  naskfunc.S -o naskfunc.s
as -al  naskfunc.s -o naskfunc.o >naskfunc.lst
cc -fno-pic -Os -Wall   -c -o bootpack.o bootpack.c
cc -fno-pic -Os -Wall   -c -o startup.o startup.c
cc -fno-pic -Os -Wall   -c -o tinylib.o tinylib.c
ld  -T asmhead.lds -o asmhead.bin asmhead.o
support/makefont hankaku.txt >font.bin
objcopy -Ibinary -Bi386 -Oelf32-i386 font.bin font.o
ld  -T hrb.lds -o bootpack.hrb bootpack.o naskfunc.o
bootpack.o: In function `HariMain':
bootpack.c:(.text+0x37c): undefined reference to `sprintf'
Makefile:31: recipe for target 'haribote.sys' failed
make: *** [haribote.sys] Error 1
```

しかたがないので最小限の範囲で自作する。

#### haribote.sys のサイズが 5632 バイトを超えた

tinylib.o の .text セクションが 1KB を超えたため haribote.sys が 11 セクタに収まらなくなった。

```shell-session
$ wc -c haribote.sys
6616 haribote.sys
$ readelf -S tinylib.o
There are 13 section headers, starting at offset 0x8ec:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 000034 000416 00  AX  0   0  1
  [ 2] .rel.text         REL             00000000 0007f4 000038 08   I 10   1  4
  [ 3] .data             PROGBITS        00000000 00044a 000000 00  WA  0   0  1
  [ 4] .bss              NOBITS          00000000 00044a 000000 00  WA  0   0  1
  [ 5] .rodata.str1.1    PROGBITS        00000000 00044a 00001d 01 AMS  0   0  1
  [ 6] .comment          PROGBITS        00000000 000467 00001e 01  MS  0   0  1
  [ 7] .note.GNU-stack   PROGBITS        00000000 000485 000000 00      0   0  1
  [ 8] .eh_frame         PROGBITS        00000000 000488 0001dc 00   A  0   0  4
  [ 9] .rel.eh_frame     REL             00000000 00082c 000058 08   I 10   8  4
  [10] .symtab           SYMTAB          00000000 000664 000140 10     11  11  4
  [11] .strtab           STRTAB          00000000 0007a4 00004e 00      0   0  1
  [12] .shstrtab         STRTAB          00000000 000884 000066 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  p (processor specific)
```

6616B は 12.92 セクタなので 13 セクタ使用する。
13 セクタ使用するよう haribote.lds を修正。

生成物に誤りがないか確認する。

```shell-session
$ /sbin/fsck.msdos haribote.img
fsck.fat 4.1 (2017-01-24)
haribote.img: 1 files, 13/2847 clusters
$ sudo mount -oro,loop haribote.img /mnt
$ cmp haribote.sys /mnt/HARIBOTE.SYS
$ wc -c haribote.sys /mnt/HARIBOTE.SYS
 6616 haribote.sys
 6616 /mnt/HARIBOTE.SYS
13232 total
$ sudo umount /mnt
```

2847 中 13 クラスタ使用しており、内容に問題はないようだ。

#### 参考

- [Using the GNU Compiler Collection (GCC): Other Builtins](https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html)

### 成果

- [Makefile](/Makefile)
    - bootpack.hrb に tinylib.o をリンクする
- [bootpack.c](/bootpack.c)
    - struct BOOTINFO::scrnx の値を表示する
- [haribote.lds](/haribote.lds)
    - FAT で 13 セクタを使用するように修正
- [tinylib.c](/tinylib.c)
    - sprintf の実装およびそれを実現するのに必要な関数群

----

Next: [harib02h](harib02h.md), Previous: [harib02f](harib02f.md), Up: [Chapter5](chapter5.md)
