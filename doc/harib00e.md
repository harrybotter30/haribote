Next: [harib00f](harib00f.md), Previous: [harib00d](harib00d.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00e

### 課題

halt するだけの OS である haribote.sys を含むディスクイメージを作成する。

### 学習

- [helloos1](helloos1.md) と同様にして haribote.sys はべた書きのリンカスクリプトで生成。
- haribote.img に埋め込むためにファイルシステムに書き込んで実験。
- 実験結果とテキストをもとに FAT 内に haribote.sys を含めたディスクイメージを作成するようリンカスクリプトを変更。

#### FAT ファイルシステム

haribote.img は FAT12 ファイルシステムのディスクイメージである。
実験をしながら求めるディスクイメージの作り方を調べる。

##### 実験

harib00d で作成した haribote.img に haribote.sys をコピーしてディスクイメージの変化を見る。

- イメージファイルをマウントするには -oloop オプションを使用する。
- vfat にならないようにファイルシステム種別を msdos にする。

```shell-session
$ make
cc -E   ipl.S -o ipl.s
as -al  ipl.s -o ipl.o >ipl.lst
cc -E   haribote.S -o haribote.s
as -al  haribote.s -o haribote.o >haribote.lst
ld  -T haribote.lds -o haribote.img ipl.o
ld  -T binary.lds -o haribote.sys haribote.o
$ cp haribote.img /tmp
$ mkdir /tmp/fat
$ sudo mount -t msdos -orw,loop /tmp/haribote.img /tmp/fat
[sudo] password for harry: 
$ sudo cp haribote.sys /tmp/fat
$ ls -al --full-time /tmp/fat
total 12
drwxr-xr-x  2 root root 7168 2017-07-17 11:02:18.000000000 +0900 .
drwxrwxrwt 12 root root 4096 2017-07-17 11:02:05.354670279 +0900 ..
-rwxr-xr-x  1 root root    3 2017-07-17 11:02:18.000000000 +0900 haribote.sys
$ sync
$ sudo umount /tmp/fat
$ diff -u <(hexdump -C haribote.img) <(hexdump -C /tmp/haribote.img)
--- /dev/fd/63	2017-07-17 11:03:02.214794956 +0900
+++ /dev/fd/62	2017-07-17 11:03:02.214794956 +0900
@@ -14,10 +14,17 @@
 000000d0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
 *
 000001f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 55 aa  |..............U.|
-00000200  f0 ff ff 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
+00000200  f0 ff ff 00 f0 ff 00 00  00 00 00 00 00 00 00 00  |................|
 00000210  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
 *
-00001400  f0 ff ff 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
+00001400  f0 ff ff 00 f0 ff 00 00  00 00 00 00 00 00 00 00  |................|
 00001410  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
 *
+00002600  48 41 52 49 42 4f 54 45  53 59 53 20 00 00 00 00  |HARIBOTESYS ....|
+00002610  00 00 00 00 00 00 49 10  f1 4a 03 00 03 00 00 00  |......I..J......|
+00002620  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
+*
+00004400  f4 eb fd 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
+00004410  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
+*
 00168000
$ hexdump -C haribote.sys
00000000  f4 eb fd                                          |...|
00000003
```

##### 差異の確認

hexdump 出力の比較により、コピー前後で以下の部分が変わっていることが判った。

オフセット | コピー前 | コピー後
---------- | -------- | --------
0x0200(512*1) | f0 ff ff | f0 ff ff 00 f0 ff
0x1400(512*10) | f0 ff ff | f0 ff ff 00 f0 ff
0x2600(512*19) | 00 00... | 48 41 52 49 42 4f 54 45  53 59 53...
0x4400(512*34) | 00 00 00 | f4 eb fd

今回の haribote.img では BIOS Parameter Block（BPB）で以下のように定義している。

- 1 クラスタあたりのセクタ数は 1
- 予約セクタ（ブートセクタ）の数は 1
- FAT の個数は 2
- ルートディレクトリのエントリ数は 224
- FAT のセクタ数は 9

また、FAT でのディレクトリエントリは 32bytes より、ルートディレクトリエントリは 32*224bytes == 14 セクタ使用する。
よって、各データ領域は以下のようになる。

オフセット | 役割
---------- | ----
0x0000(512*0) | ブートセクタ
0x0200(512*1) | 第 1 FAT
0x1400(512*10) | 第 2 FAT
0x2600(512*19) | ルートディレクトリエントリ
0x4200(512*33) | データ領域
0x167e00(512*2879) | データ末尾

よって、今回の相違は

- 第 1 FAT の先頭
- 第 2 FAT の先頭
- ルートディレクトリエントリの先頭
- データ領域の二番目のセクタ

にあらわれていることが判る。

##### FAT12

- little endian で 12 ビットずつ読む。
- コピー前は ```ff0 fff```
- コピー後は ```ff0 fff 000 fff```

ここから以下のように使用されていることが判る。

- 第 0, 1 クラスタは従来のまま
- 第 2 クラスタは未使用
- 第 3 クラスタは最終セクタ

更に、第 0, 1 クラスタは予約されていて固定の値を持つ。

- 第 0 クラスタ: 0xff0 はフロッピーの FAT12 を示す
- 第 1 クラスタ: 0xfff は終端を示す

##### ルートディレクトリエントリ（RDE）

32 バイトのエントリは以下の構造となっている。

名前 | オフセット | サイズ | 意味
---- | ---------- | ------ | ----
Name | 0 | 11 | 8+3 のファイル名（短い場合は 0x20 で埋める）
Attr | 11 | 1 | 属性を表すビットフラグ 1:READ_ONLY, 2:HIDDEN, 4:SYSTEM, 8:VOLUME_ID, 16:DIRECTORY, 32:ARCHIVE（15:LONG_NAME）
NTRes | 12 | 1 | NT 用に予約（0 にする）
CrtTimeTenth | 13 | 1 | 作成時の10ミリ秒単位の部分 [0..199]
CrtTime | 14 | 2 | 作成時刻（2 秒単位まで）
CrtDate | 16 | 2 | 作成日
LstAccDate | 18 | 2 | 最終アクセス日（時刻ではない）
FstClusHI | 20 | 2 | ファイルの先頭クラスタ番号の上位 16 ビット（FAT32 の場合のみ非 0）
WrtTime | 22 | 2 | 更新時刻（2 秒単位まで）
WrtDate | 24 | 2 | 更新日
FstClusLO | 26 | 2 | ファイルの先頭クラスタ番号
FileSize | 28 | 4 | ファイルサイズ

日付や時刻は 2 バイトをビットフィールドに分けて使用している。

ビット | 意味
------ | ----
0-4    | 2 秒単位での秒数 [0..29]（0 秒から 58 秒）
5-10   | 分 [0..59]
11-15  | 時 [0..23]
0-4    | 日 [0..31]
5-8    | 月 [1..12]
9-15   | 1980 年からの年数 [0..127]（1980 年から 2107 年）

以上から今回のエントリは以下の内容を表している。

- HARIBOTE.SYS という名前で
- ARCHIVE 属性が設定されており
- 更新時刻は 1049（0001 0:000 010:0 1001 -> 02:02:18）
- 更新日は 4af1（0100 101/0 111/1 0001 -> 2017/07/17）
- ファイル開始クラスタは 0003
- ファイルサイズは 3 バイト

\# 前述の ls -l の結果と比べると、Linux では更新時刻は UTC として扱われているようだ。  
\# データ領域として 0002 を使わず 0003 から使われている理由は不明。

##### ファイル内容

データ領域の二番目のクラスタひとつだけが使用されている。

内容は ```f4 eb fd``` であって

```Assembly
fin:
	hlt
	jmp	fin
```

になっていることが判る。

#### 参考

- [FAT32 File System Specification](http://msdn.microsoft.com/en-us/library/windows/hardware/gg463080.aspx)
- [FAT - OSDev Wiki](http://wiki.osdev.org/FAT)
- [０から作るOS開発　ブートローダその１１　FAT12ファイルシステムからファイルを読み込む](https://web.archive.org/web/20201107214109/http://softwaretechnique.jp/OS_Development/bootloader11.html)

### 成果

- [Makefile](/Makefile)
    - haribote.sys を作成する
    - haribote.sys を含む haribote.img を作成する
    - 疑似ターゲット asm 削除
- [binary.lds](/binary.lds)
    - haribote.sys 作成のためのリンカスクリプト
    - haribote.lds で直接 haribote.img を作成するため実際には必要ない
- [haribote.S](/haribote.S)
    - haribote.sys のソース
    - halt するだけの OS
- [haribote.lds](/haribote.lds)
    - haribote.img 内に haribote.sys を配置するよう修正
    - 実験では 0003 クラスタに配置されていたが、テキストでは 0002 クラスタに配置されているようなのでそれに準じた

----

Next: [harib00f](harib00f.md), Previous: [harib00d](harib00d.md), Up: [Chapter3](chapter3.md)
