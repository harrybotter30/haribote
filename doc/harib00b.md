Next: [harib00c](harib00c.md), Previous: [harib00a](harib00a.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00b

### 課題

ディスク読み込みでエラーが発生した時にリトライする。

### 学習

- ドライブリセット機能は AH=00h

#### INT 13h AH=00h: Reset Disk Drive

- パラメータ

レジスタ | 値
---- | ----
%ah | 00h
%dl | ドライブ番号

- 結果

レジスタ | 値
---- | ----
cf | エラー時に設定

##### 参考

- [INT 13h AH=00h: Reset Disk Drive](https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH.3D00h:_Reset_Disk_Drive)

### 成果

- [ipl.S](/ipl.S)
    - エラーが発生した時に 5 回までリトライする

----

Next: [harib00c](harib00c.md), Previous: [harib00a](harib00a.md), Up: [Chapter3](chapter3.md)
