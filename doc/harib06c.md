Next: [harib06d](harib06d.md), Previous: [harib06b](harib06b.md), Up: [Chapter9](chapter9.md)

----

# Chapter9

## harib06c

### 課題

メモリ上限を正しく判定する。

### 学習

チェック上限の 3GB までメモリが搭載されていると誤判定した理由を明らかにし、正しい判定を行えるようにする。

#### コンパイル結果を確認

harib06b での memtest_sub は以下のようにコンパイルされていた。for ループの中身が無意味とされすべて削除されている。

```Assembly
memtest_sub:
	pushl	%ebp
	movl	%esp, %ebp
	movl	8(%ebp), %eax		/* i = start */
.L2:
	cmpl	12(%ebp), %eax		/* loop { */
	ja	.L6			/* 	if (i > end) goto .L6 */
	addl	$4096, %eax		/* 	i += 0x1000 */
	jmp	.L2			/* } */
.L6:
	popl	%ebp
	ret
```

Tips: `gcc -S` を実行するときに `-fno-asynchronous-unwind-tables` オプションを付与すると `.cfi_startproc`, `.cfi_offset` のようなデバッグ時に使用される `CFI directive` を抑制するので見やすくなる。

#### 最適化抑制

関数属性を使用して memtest_sub() の最適化を抑制した。

```diff
diff --git a/bootpack.c b/bootpack.c
index a0a6e79..5aecc65 100644
--- a/bootpack.c
+++ b/bootpack.c
@@ -128,7 +128,7 @@ unsigned int memtest(unsigned int start, unsigned int end)
 	return i;
 }
 
-unsigned int memtest_sub(unsigned int start, unsigned int end)
+unsigned int __attribute__((optimize("O0"))) memtest_sub(unsigned int start, unsigned int end)
 {
 	unsigned int i, *p, old, pat0 = 0xaa55aa55, pat1 = 0x55aa55aa;
 	for (i = start; i <= end; i += 0x1000) {
```

これによりメモリ上限を正しく判定できるようになった。  
（手元の環境では QEMU に `-m 64` を設定しているので 64MB）

```Assembly
memtest_sub:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$32, %esp
	movl	$-1437226411, -8(%ebp)
	movl	$1437226410, -12(%ebp)
	movl	8(%ebp), %eax
	movl	%eax, -4(%ebp)
	jmp	.L2
.L7:
	movl	-4(%ebp), %eax
	addl	$4092, %eax
	movl	%eax, -16(%ebp)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	movl	%eax, -20(%ebp)
	movl	-16(%ebp), %eax
	movl	-8(%ebp), %edx
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	notl	%eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, -12(%ebp)
	je	.L3
	nop
	jmp	.L4
.L9:
	nop
.L4:
	movl	-16(%ebp), %eax
	movl	-20(%ebp), %edx
	movl	%edx, (%eax)
	jmp	.L5
.L3:
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	notl	%eax
	movl	%eax, %edx
	movl	-16(%ebp), %eax
	movl	%edx, (%eax)
	movl	-16(%ebp), %eax
	movl	(%eax), %eax
	cmpl	%eax, -8(%ebp)
	jne	.L9
	movl	-16(%ebp), %eax
	movl	-20(%ebp), %edx
	movl	%edx, (%eax)
	addl	$4096, -4(%ebp)
.L2:
	movl	-4(%ebp), %eax
	cmpl	12(%ebp), %eax
	jbe	.L7
.L5:
	movl	-4(%ebp), %eax
	leave
	ret
```

しかしながら生成されたコードはかなり冗長。

#### volatile の利用

単に最適化を抑制するというのは場当たり的な対処。
ポインタ unsigned int *p の指す先が安定した固定値ではないのだから 
volatile 指定するほうが C 言語仕様としては正しい。

```diff
diff --git a/bootpack.c b/bootpack.c
index a0a6e79..cd5d3b5 100644
--- a/bootpack.c
+++ b/bootpack.c
@@ -130,7 +130,8 @@ unsigned int memtest(unsigned int start, unsigned int end)
 
 unsigned int memtest_sub(unsigned int start, unsigned int end)
 {
-	unsigned int i, *p, old, pat0 = 0xaa55aa55, pat1 = 0x55aa55aa;
+	unsigned int i, old, pat0 = 0xaa55aa55, pat1 = 0x55aa55aa;
+	volatile unsigned int *p;
 	for (i = start; i <= end; i += 0x1000) {
 		p = (unsigned int *) (i + 0xffc);
 		old = *p;	/* いじる前の値を覚えておく */
```

こちらでもメモリ上限を正しく判定できるようになった。  
しかも

```Assembly
memtest_sub:
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ebx
	movl	8(%ebp), %eax
.L2:
	cmpl	12(%ebp), %eax
	ja	.L1
	movl	4092(%eax), %ebx
	leal	4092(%eax), %ecx
	movl	$-1437226411, 4092(%eax)
	movl	4092(%eax), %edx
	notl	%edx
	movl	%edx, 4092(%eax)
	movl	4092(%eax), %edx
	cmpl	$1437226410, %edx
	je	.L3
.L5:
	movl	%ebx, (%ecx)
	jmp	.L1
.L3:
	movl	4092(%eax), %edx
	notl	%edx
	movl	%edx, 4092(%eax)
	movl	4092(%eax), %edx
	cmpl	$-1437226411, %edx
	jne	.L5
	movl	%ebx, (%ecx)
	addl	$4096, %eax
	jmp	.L2
.L1:
	popl	%ebx
	popl	%ebp
	ret
```

生成されたコードも素晴らしい。

#### アセンブリ言語の利用

GCC でも当時のバージョンでは volatile が期待通りに動作していなかったのかもしれない。  
テキストを尊重してアセンブリ言語で書き直す。

##### 予期せぬ動作

がっ。4MB。最初から失敗している。リスティングファイルを見てみると気になる出力がある。

```Assembly
 189              	memtest_sub:
 190 00c0 57       	 pushl %edi
 191 00c1 56       	 pushl %esi
 192 00c2 53       	 pushl %ebx
 193 00c3 BE55AA55 	 movl $0xaa55aa55, %esi
 193      AA
 194 00c8 BFAA55AA 	 movl $0x55aa55aa, %edi
 194      55
 195 00cd 8B442410 	 movl 16(%esp), %eax
 196              	mts_loop:
 197 00d1 89C3     	 movl %eax, %ebx
 198 00d3 81C3FC0F 	 addl $0xffc, %ebx
 198      0000
 199 00d9 8B13     	 movl (%ebx), %edx
 200 00db 8933     	 movl %esi, (%ebx)
 201 00dd 8333FF   	 xorl $0xffffffff, (%ebx)
```

`xorl $0xffffffff, (%ebx)` なのに `83 33 FF` になっている。
これが `xorl $0xff, (%ebx)` 相当になるため判定が失敗しているのではないか？

ModR/M バイト `33` は `mod: 00, reg/opcode: 110, r/m: 011` となる。  
32-Bit Addressing での `mod: 00, r/m: 011` は、アドレス `[EBX]`、
`opcode: 83 /6` より `XOR sign-extended immediate byte with r/m dword` を意味する。

`sign-extended` なので意図通りだった。

逆に `xorl $0xff, (%ebx)` からリスティングファイルを作成したところ、`81 33 FF 00 00 00` となった。  
ModR/M バイトは `33` で同じなので `81 /6 id` になり `[EBX]` に対する `Exclusive-OR immediate dword to r/m dword` になる。

定数 `$0xffffffff` の書き方を変えて imm32 のコードを生成させようとして四苦八苦したがその必要はなかった。

##### 不具合

どこか別の誤りがあるのかと改めて確認したところ一行記述もれがあった。

```diff
index 15722f5..abb638c 100644
--- a/naskfunc.S
+++ b/naskfunc.S
@@ -191,6 +191,7 @@ mts_loop:
 	movl	%eax, %ebx
 	addl	$0xffc, %ebx    /* p = i + 0xffc; */
 	movl	(%ebx), %edx    /* old = *p; */
+	movl	%esi, (%ebx)	/* *p = pat0; */
 	xorl	$0xffffffff, (%ebx) /* *p ^= 0xffffffff; */
 	cmpl	(%ebx), %edi    /* if (*p != pat1) goto fin; */
 	jne	mts_fin
```

テキスト目視で Intel 構文を AT&T 構文に変換しながら書いていたいので一行飛ばしていたのだった。  
まぬけな結末で脱力する。

#### 参考

- [Detect x86 CPU Type (8086, i286, i386, i486, Pentium, Pentium Pro) · GitHub](https://gist.github.com/ljmccarthy/e87d0e0b028413fad3317ad80e9e4db1)
- [Detecting Intel Processors -- Knowing the generation of a system CPU](http://www.rcollins.org/ddj/Sep96/Sep96.html)
- [FLAGS register - Wikipedia](https://en.wikipedia.org/wiki/FLAGS_register#FLAGS)
- [Control register - Wikipedia](https://en.wikipedia.org/wiki/Control_register#CR0)
- [coder32 edition | X86 Opcode and Instruction Reference 1.12](http://ref.x86asm.net/coder32.html)
- [80386 Programmer's Reference Manual -- Opcode AAA](https://pdos.csail.mit.edu/6.828/2011/readings/i386/XOR.htm)
- [80386 Programmer's Reference Manual -- Section 17.2](https://pdos.csail.mit.edu/6.828/2011/readings/i386/s17_02.htm)

### 成果

- [bootpack.c](/bootpack.c)
    - memtest_sub() を削除
- [naskfunc.S](/naskfunc.S)
    - memtest_sub: を追加

----

Next: [harib06d](harib06d.md), Previous: [harib06b](harib06b.md), Up: [Chapter9](chapter9.md)
