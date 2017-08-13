	.file	"naskfunc.S"    /* ソースファイル名情報 */
	.arch	i486            /* 486の命令まで使いたいという記述 */
	.code32                 /* 32ビットモード用の機械語を作らせる */
	.text

/* オブジェクトファイルのための情報 */

	.globl	io_hlt
	.type	io_hlt, @function
	.globl	write_mem8
	.type	write_mem8, @function

/* 以下は実際の関数 */

io_hlt:                         /* void io_hlt(void); */
	hlt
	ret

write_mem8:                     /* void write_mem8(int addr, int data); */
	movl		4(%esp), %ecx /* [ESP+4]にaddrが入っているのでそれをECXに読み込む */
	movb		8(%esp), %al /* [ESP+8]にdataが入っているのでそれをALに読み込む */
	movb		%al, (%ecx)
	ret
