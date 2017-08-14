	.file	"naskfunc.S"    /* ソースファイル名情報 */
	.arch	i486            /* 486の命令まで使いたいという記述 */
	.code32                 /* 32ビットモード用の機械語を作らせる */
	.text

/* オブジェクトファイルのための情報 */

	.globl	io_hlt
	.type	io_hlt, @function
	.globl	io_cli
	.type	io_cli, @function
	.globl	io_sti
	.type	io_sti, @function
	.globl	io_stihlt
	.type	io_stihlt, @function
	.globl	io_in8
	.type	io_in8, @function
	.globl	io_in16
	.type	io_in16, @function
	.globl	io_in32
	.type	io_in32, @function
	.globl	io_out8
	.type	io_out8, @function
	.globl	io_out16
	.type	io_out16, @function
	.globl	io_out32
	.type	io_out32, @function
	.globl	io_load_eflags
	.type	io_load_eflags, @function
	.globl	io_store_eflags
	.type	io_store_eflags, @function

/* 以下は実際の関数 */

io_hlt:                         /* void io_hlt(void); */
	hlt
	ret

io_cli:                         /* void io_cli(void); */
	cli
	ret

io_sti:                         /* void io_sti(void); */
	sti
	ret

io_stihlt:                      /* void io_stihlt(void); */
	sti
	hlt
	ret

io_in8:                         /* int io_in8(int port); */
	movl	4(%esp), %edx   /* port */
	movl	$0, %eax
	inb	%dx, %al
	ret

io_in16:                        /* int io_in16(int port); */
	movl	4(%esp), %edx   /* port */
	movl	$0, %eax
	inw	%dx, %ax
	ret

io_in32:                        /* int io_in32(int port); */
	movl	4(%esp), %edx   /* port */
	inl	%dx, %eax
	ret

io_out8:                        /* void io_out8(int port, int data); */
	movl	4(%esp), %edx   /* port */
	movb	8(%esp), %al    /* data */
	outb	%al, %dx
	ret

io_out16:                       /* void io_out16(int port, int data); */
	movl	4(%esp), %edx   /* port */
	movl	8(%esp), %eax   /* data */
	outw	%ax, %dx
	ret

io_out32:                       /* void io_out32(int port, int data); */
	movl	4(%esp), %edx   /* port */
	movl	8(%esp), %eax   /* data */
	outl	%eax, %dx
	ret

io_load_eflags:                 /* int io_load_eflags(void); */
	pushfl                  /* PUSH EFLAGS という意味 */
	popl	%eax
	ret

io_store_eflags:                /* void io_store_eflags(int eflags); */
	movl	4(%esp), %eax
	pushl	%eax
	popfl                   /* POP EFLAGS という意味 */
	ret
