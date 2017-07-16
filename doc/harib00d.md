Next: [harib00e](harib00e.md), Previous: [harib00c](harib00c.md), Up: [Chapter3](chapter3.md)

----

# Chapter3

## harib00d

### 課題

10 シリンダ分読み込む。

### 学習

#### ロジック

- セクタ番号を進めながら Disk BIOS 呼び出しで読み込む。
- 第 18 セクタを超えたら第 1 セクタにし、ヘッド番号を 1 増やす。
- ヘッド番号が 1 を超えたらヘッド番号を 0 にし、シリンダ番号を 1 増やす。
- シリンダ番号が CYLS 以上になったら終了。

#### ディレクティブ

- 定数をシンボルとして定義する場合は、[.set SYMBOL, EXPRESSION](http://ftp.gnu.org/old-gnu/Manuals/gas/html_node/as_118.html) を使う。
- シンボルをイミディエイトオペランドに使用する場合も '$' を前置する。

### 成果

- [ipl.S](/ipl.S)
    - 10 シリンダ分読み込む

----

Next: [harib00e](harib00e.md), Previous: [harib00c](harib00c.md), Up: [Chapter3](chapter3.md)
