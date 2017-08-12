	.set	BOTPAK, 0x00280000 /* bootpackのロード先 */
	.set	DSKCAC, 0x00100000 /* ディスクキャッシュの場所 */
	.set	DSKCAC0, 0x00008000 /* ディスクキャッシュの場所（リアルモード） */

	.set	CYLS, 0x0ff0    /* ブートセクタが設定する */
	.set	LEDS, 0x0ff1
	.set	VMODE, 0x0ff2   /* 色数に関する情報。何ビットカラーか？ */
	.set	SCRNX, 0x0ff4   /* 解像度のX */
	.set	SCRNY, 0x0ff6   /* 解像度のY */
	.set	VRAM, 0x0ff8    /* グラフィックバッファの開始番地 */
	.code16

/* 画面モードを設定 */

	movb	$0x13, %al      /* VGAグラフィックス、320x200x8bitカラー */
	movb	$0x00, %ah
	int	$0x10
	movb	$8, (VMODE)     /* 画面モードをメモする（C言語が参照する） */
	movw	$320, (SCRNX)
	movw	$200, (SCRNY)
	movl	$0x000a0000, (VRAM)

/* キーボードのLED状態をBIOSに教えてもらう */

	movb	$0x02, %ah
	int	$0x16           /* keyboard BIOS */
	movb	%al, (LEDS)

/* PICが一切の割り込みを受け付けないようにする */
/*	AT互換機の仕様では、PICの初期化をするなら、
	こいつをCLI前にやっておかないと、たまにハングアップする
	PICの初期化はあとでやる */

	movb	$0xff, %al
	out	%al, $0x21
	nop                     /* OUT命令を連続させるとうまくいかない機種があるらしいので */
	out	%al, $0xa1

	cli                     /* さらにCPUレベルでも割り込み禁止 */

/* CPUから1MB以上のメモリにアクセスできるように、A20GATEを設定 */

	call	waitkbdout
	movb	$0xd1, %al
	out	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al      /* enable A20 */
	out	%al, $0x60
	call	waitkbdout

/* プロテクトモード移行 */

	.arch	i486            /* 486の命令まで使いたいという記述 */

	lgdt	(GDTR0)         /* 暫定GDTを設定 */
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax /* bit31を0にする（ページング禁止のため） */
	orl	$0x00000001, %eax /* bit0を1にする（プロテクトモード移行のため） */
	movl	%eax, %cr0
	jmp	pipelineflush
pipelineflush:
	movw	$1*8, %ax      /* 読み書き可能セグメント32bit */
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

/* bootpackの転送 */

	movl	$bootpack, %esi
	movl	$BOTPAK, %edi
	movl	$512*1024/4, %ecx
	call	memcpy

/* ついでにディスクデータも本来の位置へ転送 */

/* まずはブートセクタから */

	movl	$0x7c00, %esi   /* 転送元 */
	movl	$DSKCAC, %edi   /* 転送先 */
	movl	$512/4, %ecx
	call	memcpy

/* 残り全部 */

	movl	$DSKCAC0+512, %esi /* 転送元 */
	movl	$DSKCAC+512, %edi  /* 転送先 */
	movl	$0, %ecx
	movb	(CYLS), %cl
	imull	$512*18*2/4,%ecx /* シリンダ数からバイト数/4に変換 */
	subl	$512/4, %ecx       /* IPLの分だけ差し引く */
	call	memcpy

/* asmheadでしなければいけないことは全部し終わったので、
	あとはbootpackに任せる */

/* bootpackの起動 */

	movl	$BOTPAK, %ebx
	movl	16(%ebx), %ecx
	addl	$3, %ecx        /* ECX += 3; */
	shrl	$2, %ecx        /* ECX /= 4; */
	jz	skip            /* 転送するべきものがない */
	movl	20(%ebx), %esi  /* 転送元 */
	addl	%ebx, %esi
	movl	12(%ebx), %edi  /* 転送先 */
	call	memcpy
skip:
	movl	12(%ebx), %esp  /* スタック初期値 */
	ljmpl	$2*8, $0x0000001b

waitkbdout:
	inb	$0x64, %al
	andb	$0x02, %al
	jnz	waitkbdout      /* ANDの結果が0でなければwaitkbdoutへ */
	ret

memcpy:
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, (%edi)
	addl	$4, %edi
	subl	$1, %ecx
	jnz	memcpy          /* 引き算した結果が0でなければmemcpyへ */
	ret

/* memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける */

	.balign	16, 0
GDT0:
	.space	8               /* ヌルセレクタ */
	.short	0xffff,0x0000,0x9200,0x00cf /* 読み書き可能セグメント32bit */
	.short	0xffff,0x0000,0x9a28,0x0047 /* 実行可能セグメント32bit（bootpack用） */

	.short	0
GDTR0:
	.short	8*3-1
	.long	GDT0

	.balign	16, 0
bootpack:
