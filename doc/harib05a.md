Next: [harib05b](harib05b.md), Previous: [harib04g](harib04g.md), Up: [Chapter8](chapter8.md)

----

# Chapter8

## harib05a

### 課題

マウスデータをパケットとして受信する。

### 学習

マウス情報は 3 バイトのデータパケットとして送信されてくる。状態変数を使用して受信したのがどのデータなのかを認識する。  
最初の 0xfa を読み飛ばしているのは、enable_mouse() に対する acknowledge であるため。

#### 参考

- [PS/2 Mouse Interfacing / Movement Data Packet](https://web.archive.org/web/20180202180653/http://www.computer-engineering.org/ps2mouse/#Movement_Data_Packet)

### 成果

- [bootpack.c](/bootpack.c)
    - マウスデータをパケットとして表示する

----

Next: [harib05b](harib05b.md), Previous: [harib04g](harib04g.md), Up: [Chapter8](chapter8.md)
