Next: [harib04c](harib04c.md), Previous: [harib04a](harib04a.md), Up: [Chapter7](chapter7.md)

----

# Chapter7

## harib04b

### 課題

割り込みハンドラの中では画面表示しない。

### 学習

#### io_stihlt

```sti``` は「次の命令実行後に」割り込み可能にする。

よって

```Assembly
	sti
	hlt
```

のように連続させることで、```hlt``` 前に割り込まれることがなくなる。

```C
	io_sti();
	io_hlt();
```

では ```sti``` と ```hlt``` の間に ```ret``` や ```call``` が入るので、割り込まれる危険性がある。

#### 参考

- [80386 Programmer's Reference Manual -- Opcode STI](https://pdos.csail.mit.edu/6.828/2016/readings/i386/STI.htm)

### 成果

- [bootpack.c](/bootpack.c)
    - キーバッファにデータがあればそれを表示する
- [bootpack.h](/bootpack.h)
    - io_stihlt(), struct KEYBUF 定義
- [int.c](/int.c)
    - 割り込みハンドラではキーコードを取得しバッファに保存するだけ

----

Next: [harib04c](harib04c.md), Previous: [harib04a](harib04a.md), Up: [Chapter7](chapter7.md)
