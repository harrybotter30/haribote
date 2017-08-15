Next: [harib02f](harib02f.md), Previous: [harib02d](harib02d.md), Up: [Chapter5](chapter5.md)

----

# Chapter5

## harib02e

### 課題

多種類の文字を表示する。

### 学習

#### フォントソースファイル hankaku.txt 追加

フォントソースファイル hankaku.txt をオリジナルからコピーする。

- "char 0xXX" をそのグリフを使用するコードポイントを表すヘッダとし
- それに続く 8 桁 16 行でグリフを表す
- 各行の '.' は表示しない点 '*' は表示する点を表す

オリジナルでは変換に makefont.exe を使用しているが、バイナリではどのような処理をしているのか明らかではない。
今回は処理を直接確認できる Perl スクリプトに置き換えた。

#### bootpack.hrb へのフォント埋め込み

テキストでは初出だが、「よくわからない独自ツールは使用しない」という方針により、すでに手元では [harib00i](harib00i.md#haribotesys-%E3%81%AE%E4%BD%9C%E6%88%90) で objcopy を使用する方法にたどり着いている。

また、[harib00j](harib00j.md#%E3%83%AA%E3%83%B3%E3%82%AB%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%83%88%E3%81%A7%E3%81%AE%E3%83%AF%E3%82%A4%E3%83%AB%E3%83%89%E3%82%AB%E3%83%BC%E3%83%89) で EXCLUDE_FILE を使うことで特定のオブジェクトからのセクションを意図した場所に配置する方法も学習済み。

両者を組み合わせ、フォントデータを通常のソースから生成された初期化済みデータの次に配置した。

#### bootpack.c でのフォント参照

オリジナルでは bin2obj.exe で埋め込んだデータに ```_hankaku``` というシンボル名をつけているが、[普通のやつらの下を行け: objcopy で実行ファイルにデータを埋め込む - bkブログ](http://0xcc.net/blog/archives/000076.html)で説明されているように、objcopy では ```extern char _binary_font_bin_start[]``` として参照できるようになる。

オリジナルからシンボル名を変更してフォントデータを参照する。

#### haribote.sys のサイズが 1536 バイトを超えた

バイナリのフォントデータが 4KB ある（== 16B/文字 * 256文字）ので haribote.sys が 3 セクタに収まらなくなった。

```shell-session
$ wc -c haribote.sys
5488 haribote.sys
$ support/makefont hankaku.txt | wc -c
4096
```

5488B は 10.72 セクタなので 11 セクタ使用する。
11 セクタ使用するよう haribote.lds を修正。

誤りがないか確認する。

```shell-session
$ /sbin/fsck.msdos haribote.img
fsck.fat 4.1 (2017-01-24)
haribote.img: 1 files, 11/2847 clusters
$ sudo mount -oro,loop haribote.img /mnt
$ cmp haribote.sys /mnt/HARIBOTE.SYS
$ wc -c haribote.sys /mnt/HARIBOTE.SYS
 5488 haribote.sys
 5488 /mnt/HARIBOTE.SYS
10976 total
$ sudo umount /mnt
```

2847 中 11 クラスタ使用しており、内容に相違はないようだ。

#### 参考

- [普通のやつらの下を行け: objcopy で実行ファイルにデータを埋め込む - bkブログ](http://0xcc.net/blog/archives/000076.html)
- [データファイルをバイナリに埋め込みたい - Linux関係メモ＠宇治屋電子](https://www.ujiya.net/linux/0107)

### 成果

- [Makefile](/Makefile)
    - [support/makefont](/support/makefont) でフォントデータを作成し bootpack.hrb に埋め込む
- [bootpack.c](/bootpack.c)
    - フォントデータを参照しデスクトップに文字 'A', 'B', 'C', '1', '2', '3' を表示する
- [hankaku.txt](/hankaku.txt)
    - オリジナルからコピーしたフォントのソース
- [haribote.lds](/haribote.lds)
    - FAT で 11 セクタを使用するように修正
- [hrb.lds](/hrb.lds)
    - フォントデータを通常のソースから生成された初期化済みデータの次に配置する
- [support/makefont](/support/makefont)
    - フォントのソースを読み込みバイナリのフォントデータを作成する

----

Next: [harib02f](harib02f.md), Previous: [harib02d](harib02d.md), Up: [Chapter5](chapter5.md)
