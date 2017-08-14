Next: [harib02a](harib02a.md), Previous: [harib01g](harib01g.md), Up: [Chapter4](chapter4.md)

----

# Chapter4

## harib01h

### 課題

空のデスクトップを描く。

### 学習

#### haribote.sys のサイズが 1024 バイトを超えた

haribote.sys のファイルサイズが 2 セクタを超えたので FAT で 3 セクタ分使うように修正した。

FAT の先頭部分 ```f0 ff ff 03 f0 ff 00 00 00 ...``` すなわち ```ff0 fff  003 fff  000 000 ...``` を
```ff0 fff  003 004  fff 000 ``` すなわち ```f0 ff ff 03 40 00 ff 0f 00 00 ...``` に修正した。

これは第 2 クラスタの次が第 3 クラスタで、それが最終クラスタであった状態から、
第 2 クラスタの次が第 3 クラスタ、その次が第 4 クラスタでそれが最終クラスタになったことを示す。

haribote.sys はディスクイメージの先頭から 0x4200 バイト（33 セクタ）目の場所に配置し、
0x4600 バイト（35 セクタ）目から 00 で埋めていたものを 0x4800 バイト（36 セクタ）目からに変更。

### 成果

- [bootpack.c](/bootpack.c)
    - 空のデスクトップを描く
- [haribote.lds](/haribote.lds)
    - FAT で 3 セクタを使用するように修正

----

Next: [harib02a](harib02a.md), Previous: [harib01g](harib01g.md), Up: [Chapter4](chapter4.md)
