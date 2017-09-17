Next: [harib04a](harib04a.md), Previous: [harib03d](harib03d.md), Up: [Chapter6](chapter6.md)

----

# Chapter6

## harib03e

### 課題

割り込みハンドラを登録する。

### 学習

#### 命令記法

gas では nasm と命令の記述方法が異なる。

nasm | gas
---- | ----
pushad | pushal
popad  | popal
iretd  | iretl

#### pusha

pusha(l) は以下の順ですべての汎用レジスタを退避する。

1. %(e)ax
1. %(e)cx
1. %(e)dx
1. %(e)bx
1. %(e)sp
1. %(e)bp
1. %(e)si
1. %(e)di

ただし、%(e)sp は %(e)ax を push する前の値を退避する。

#### popa

popa(l) は以下の順ですべての汎用レジスタを復元する。

1. %(e)di
1. %(e)si
1. %(e)bp
1. %(e)sp
1. %(e)bx
1. %(e)dx
1. %(e)cx
1. %(e)ax

ただし、%(e)sp は pop した値を破棄する。
（pop した値を %(e)sp にロードすると %(e)ax を push する前のアドレスになるためそれ以降のレジスタが復元できない）

#### asm_inthandlerXX の引数・返値

割り込みハンドラの C 側実装 inthandlerXX() はいずれも int *esp の引数を持つ。
今回の実装はいずれもこの引数を使用していない。

割り込みハンドラに入って、

```Assembly
	push	%es
	push	%ds
	pushal
```

した後の %esp の値を返している。

これらについてテキストには解説は見当たらず、どのような意味を持つのか不明。

#### 割り込みハンドラ登録

```C
	set_gatedesc(idt + 0x21, (int) asm_inthandler21, 2 * 8, AR_INTGATE32);
	set_gatedesc(idt + 0x27, (int) asm_inthandler27, 2 * 8, AR_INTGATE32);
	set_gatedesc(idt + 0x2c, (int) asm_inthandler2c, 2 * 8, AR_INTGATE32);
```

set_gatedesc で GATE_DESCRIPTOR に値を設定している。

第一引数は GATE_DESCRIPTOR へのポインタ。[harib02i](harib02i.md#%E3%83%A1%E3%83%A2%E3%83%AA%E3%83%9E%E3%83%83%E3%83%97)で確認したように、ADR_IDT（==0x0026f800）から割り込みハンドラテーブルが割り当てられているので、ADR_IDT＋割り込み番号でその割り込みの GATE_DESCRIPTOR を示す。

第二引数はハンドラのアドレス。レジスタやスタックを正しく操作する必要があるため C 言語の inthandlerXX ではなくアセンブリ言語の asm_inthandlerXX を指定する。

第三引数はセレクタ。割り込みハンドラのセレクタ 2 * 8 は init_gdtidt() 中の set_segmdesc(gdt + 2, ...) で設定したセグメントを示す。これは bootstack.hrb の内容をそのままメモリにロードしたセグメント。

第四引数はゲートディスクリプタの count と type。[harib02i](harib02i.md#%E3%82%B2%E3%83%BC%E3%83%88%E3%83%87%E3%82%A3%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%82%BF%E3%81%AE%E6%A7%8B%E9%80%A0)で確認したように、AR_INTGATE32（== 0x008e）は以下を意味する。

- ```count == 0```: スタックのコピー回数は 0
- ```P == 1```: セグメントは存在する
- ```DPL == 0```: ディスクリプタの権限レベルは 0
- ```S == 0```: ディスクリプタの種別は system
- ```TYPE == 0b1110```: 32bit 割り込みゲート

#### マスク解除

マスタ PIC は ```0xf9 == 0b11111001```、スレーブ PIC は ```0xef == 0b11101111``` によりマスク解除をしている。
これにより、IRQ1, IRQ2, IRQ12 が有効になる。

IRQ | デフォルトの割当
--- | ----
 0 | system timer (cannot be changed)
 1 | keyboard controller (cannot be changed)
 2 | cascaded signals from IRQs 815 (any devices configured to use IRQ 2 will actually be using IRQ 9)
 3 | serial port controller for serial port 2 (shared with serial port 4, if present)
 4 | serial port controller for serial port 1 (shared with serial port 3, if present)
 5 | parallel port 2 and 3  or  sound card
 6 | floppy disk controller
 7 | parallel port 1. It is used for printers or for any parallel port if a printer is not present. It can also be potentially be shared with a secondary sound card with careful management of the port.
 8 | real-time clock (RTC)
 9 | Advanced Configuration and Power Interface (ACPI) system control interrupt on Intel chipsets.[1] Other chipset manufacturers might use another interrupt for this purpose, or make it available for the use of peripherals (any devices configured to use IRQ 2 will actually be using IRQ 9)
10 | The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
11 | The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
12 | mouse on PS/2 connector
13 | CPU co-processor  or  integrated floating point unit  or  inter-processor interrupt (use depends on OS)
14 | primary ATA channel (ATA interface usually serves hard disk drives and CD drives)
15 | secondary ATA channel

#### 参考

- [80386 Programmer's Reference Manual -- Chapter 17](https://pdos.csail.mit.edu/6.828/2016/readings/i386/c17.htm)
- [Interrupt request (PC architecture) - Wikipedia](https://en.wikipedia.org/wiki/Interrupt_request_(PC_architecture))

### 成果

- [bootpack.c](/bootpack.c)
    - CPU 割り込み禁止解除
    - キーボード・マウス割り込みを許可
- [bootpack.h](/bootpack.h)
    - 割り込みハンドラ定義
- [dsctbl.c](/dsctbl.c)
    - 割り込みハンドラの設定
- [int.c](/int.c)
    - 割り込みハンドラ実装
- [naskfunc.S](/naskfunc.S)
    - 割り込みハンドラ用のレジスタ・スタック操作

----

Next: [harib04a](harib04a.md), Previous: [harib03d](harib03d.md), Up: [Chapter6](chapter6.md)
