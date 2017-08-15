Next: [harib02e](harib02e.md), Previous: [harib02c](harib02c.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02d

### 課題

文字を表示する。

### 学習

#### bootpack.hrb ヘッダの確認

フォントデータが追加になったので bootpack.hrb ヘッダを確認した。

```shell-session
$ hexdump -C ../wine/harib02d/bootpack.hrb | head -3
00000000  00 10 31 00 48 61 72 69  00 00 00 00 00 00 31 00  |..1.Hari......1.|
00000010  40 00 00 00 c4 03 00 00  00 00 00 e9 9b 03 00 00  |@...............|
00000020  40 00 31 00 55 89 e5 e8  43 00 00 00 0f bf 05 f6  |@.1.U...C.......|
$ hexdump -C bootpack.hrb | head -3
00000000  00 10 31 00 48 61 72 69  00 00 00 00 00 00 31 00  |..1.Hari......1.|
00000010  40 00 00 00 6c 03 00 00  00 00 00 e9 40 03 00 00  |@...l.......@...|
00000020  40 00 31 00 55 89 e5 57  56 53 83 ec 1c 8b 5d 08  |@.1.U..WVS....].|
```

相違点は以下のとおり。

オフセット | wine 作成版 | 手元版 | 意味
---------- | ----------- | ---------- | ----
+20        | 0x000003c4  | 0x0000036c | .dataの初期値列がファイルのどこにあるか
+28        | 0x0000039b  | 0x00000340 | エントリアドレス-0x20

```shell-session
$ hexdump -C ../wine/harib02d/bootpack.hrb | tail -6
000003c0  60 fc ff ff 00 18 18 18  18 24 24 24 24 7e 42 42  |`........$$$$~BB|
000003d0  42 e7 00 00 00 00 00 ff  00 00 00 ff 00 ff ff 00  |B...............|
000003e0  00 00 ff ff 00 ff 00 ff  ff ff ff ff c6 c6 c6 84  |................|
000003f0  00 00 00 84 00 84 84 00  00 00 84 84 00 84 00 84  |................|
00000400  84 84 84 84                                       |....|
00000404
$ hexdump -C bootpack.hrb | tail -6
00000360  55 89 e5 5d e9 57 ff ff  ff 00 00 00 00 00 00 ff  |U..].W..........|
00000370  00 00 00 ff 00 ff ff 00  00 00 ff ff 00 ff 00 ff  |................|
00000380  ff ff ff ff c6 c6 c6 84  00 00 00 84 00 84 84 00  |................|
00000390  00 00 84 84 00 84 00 84  84 84 84 84 00 18 18 18  |................|
000003a0  18 24 24 24 24 7e 42 42  42 e7 00 00              |.$$$$~BBB...|
000003ac
```

.data セクションにはパレットデータとフォントデータが格納されているはずだが、内容から

- wine 作成版は 0x3c4 からフォントデータが、0x3d4 からパレットデータが
- 手元版は 0x36c からパレットデータが、0x39c からフォントデータが

配置されていることが判る。

```shell-session
$ grep HariStartup ../wine/harib02d/bootpack.map 
0x000003BB : _HariStartup
$ grep HariStartup bootpack.map 
                0x000000000000001c        0x4 LONG 0x340 (HariStartup - 0x20)
                0x0000000000000360                HariStartup
```

マップファイルから HariStartup の配置は

- wine 作成版は 0x3bb、よって 0x3bb - 0x20 == 0x39b
- 手元版は 0x360、よって 0x360 - 0x20 == 0x340

となっており、bootpack.hrb のヘッダが正しく生成されていることが確認できた。

### 成果

- [bootpack.c](/bootpack.c)
    - デスクトップに文字 'A' を表示する。

----

Next: [harib02e](harib02e.md), Previous: [harib02c](harib02c.md), Up: [Chapter5](chapter5.md)
