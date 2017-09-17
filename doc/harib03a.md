Next: [harib03b](harib03b.md), Previous: [harib02i](harib02i.md), Up: [Chapter6](chapter6.md)

----

# Chapter6

## harib03a

### 課題

ソースファイルを整理する。

### 学習

bootpack.c から

- 描画関連の関数を graphic.c に
- GDT や IDT などのディスクリプタテーブル関連の関数を dsctbl.c に

移動した。

#### haribote.img が不正になっていた

[Chapter5](chapter5.md) の [harib02i](harib02i.md) で haribote.sys のサイズが 7296 バイト（15 セクタ）に増え、[harib02g](harib02g.md) の 13 セクタから 2 セクタ多く消費するようになっていた。
しかし haribote.lds での FAT は 13 セクタのままであり、末尾の 640 バイト（7296 - 512 * 13）にアクセスできない状態となっていた。

```shell-session
$ /sbin/fsck.msdos haribote.img 
fsck.fat 4.1 (2017-01-24)
/HARIBOTE.SYS
  File size is 7296 bytes, cluster chain length is 6656 bytes.
  Truncating file to 6656 bytes.
Perform changes ? (y/n) n
haribote.img: 1 files, 13/2847 clusters
$ sudo mount -oro,loop haribote.img /mnt
$ cmp haribote.sys /mnt/HARIBOTE.SYS
cmp: /mnt/HARIBOTE.SYS: Input/output error
$ wc -c haribote.sys /mnt/HARIBOTE.SYS
 7296 haribote.sys
wc: /mnt/HARIBOTE.SYS: Input/output error
 7182 /mnt/HARIBOTE.SYS
14478 total
$ sudo umount /mnt
```

いままでと異なり、これが検出できなかったのはデータエリアでの haribote.sys 後のセクタを 0 クリアするオフセットを

```
  . = 0x4200;                   /* 2nd cluster offset */
  .file : {
    file.o (.data);
  } = 0x00000000
  . = 0x6200;                   /* <-- BUG: 0x5c00 でなければならなかった */
  .nofile : {
    LONG(0);
    . = 1474560-0x6200;         /* 1440KB disk */
  } = 0x00000000
```

のように 0x6200 と計算間違いしていたため。

0x6200 は先頭から 25088 バイト目で、haribote.sys の開始オフセット 0x4200（== 16896）から 8192 バイト後である。
本来は 13 セクタ後であるので 0x4200 + 512 * 13（== 0x4200 + 0x1a00 == 0x5c00）となっているべきだった。
2 セクタ追加の暗算を 0x5800 + 0x0200 + 0x0200 => 0x6200 としてしまった。

```shell-session
$ git show a7a67b87916e17a3fdabcb51e916884110d9adca
commit a7a67b87916e17a3fdabcb51e916884110d9adca
Author: harry botter <harry.botter.30@gmail.com>
Date:   Wed Aug 16 22:31:30 2017 +0900

    modify disk image because haribote.sys came to use 13 sectors

diff --git a/haribote.lds b/haribote.lds
index 660c03e..d72e148 100644
--- a/haribote.lds
+++ b/haribote.lds
@@ -9,14 +9,16 @@ SECTIONS
     BYTE(0x40); BYTE(0x00); BYTE(0x05); BYTE(0x60);
     BYTE(0x00); BYTE(0x07); BYTE(0x80); BYTE(0x00);
     BYTE(0x09); BYTE(0xa0); BYTE(0x00); BYTE(0x0b);
-    BYTE(0xc0); BYTE(0x00); BYTE(0xff); BYTE(0x0f);
-    . += 4588;
+    BYTE(0xc0); BYTE(0x00); BYTE(0x0d); BYTE(0xe0);
+    BYTE(0x00); BYTE(0xff); BYTE(0x0f); BYTE(0x00);
+    . = 4608;
     BYTE(0xf0); BYTE(0xff); BYTE(0xff); BYTE(0x03);
     BYTE(0x40); BYTE(0x00); BYTE(0x05); BYTE(0x60);
     BYTE(0x00); BYTE(0x07); BYTE(0x80); BYTE(0x00);
     BYTE(0x09); BYTE(0xa0); BYTE(0x00); BYTE(0x0b);
-    BYTE(0xc0); BYTE(0x00); BYTE(0xff); BYTE(0x0f);
-    . += 4588;
+    BYTE(0xc0); BYTE(0x00); BYTE(0x0d); BYTE(0xe0);
+    BYTE(0x00); BYTE(0xff); BYTE(0x0f); BYTE(0x00);
+    . = 9216;
     BYTE(0x48);                 /* 'H' */
     BYTE(0x41);                 /* 'A' */
     BYTE(0x52);                 /* 'R' */
@@ -39,9 +41,9 @@ SECTIONS
   .file : {
     file.o (.data);
   } = 0x00000000
-  . = 0x5800;
+  . = 0x6200;
   .nofile : {
     LONG(0);
-    . = 1474560-0x5800;         /* 1440KB disk */
+    . = 1474560-0x6200;         /* 1440KB disk */
   } = 0x00000000
 }
```

手動で haribote.lds を編集していると同じ誤りを繰り返しかねないので support/makelds を作成した。

### 成果

- [Makefile](/Makefile)
    - dsctbl.c, graphic.c を追加
- [bootpack.c](/bootpack.c)
    - 描画関連とディスクリプタテーブル関連の関数を移動
- [dsctbl.c](/dsctbl.c)
    - ディスクリプタテーブル関連の関数を bootpack.c から移動
- [graphic.c](/graphic.c)
    - 描画関連の関数を bootpack.c から移動
- haribote.lds
    - [support/makelds](/support/makelds) を使用して動的に生成することこととしリポジトリからは削除
- [support/makelds](/support/makelds)
    - 現在の haribote.sys から haribote.lds を動的に生成する

----

Next: [harib03b](harib03b.md), Previous: [harib02i](harib02i.md), Up: [Chapter6](chapter6.md)
