
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            protect.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifndef	_ORANGES_PROTECT_H_
#define	_ORANGES_PROTECT_H_


/* 存储段描述�??/系统段描述�?? */
typedef struct s_descriptor		/* �? 8 �?字节 */
{
	u16	limit_low;		/* Limit */
	u16	base_low;		/* Base */
	u8	base_mid;		/* Base */
	u8	attr1;			/* P(1) DPL(2) DT(1) TYPE(4) */
	u8	limit_high_attr2;	/* G(1) D(1) 0(1) AVL(1) LimitHigh(4) */
	u8	base_high;		/* Base */
}DESCRIPTOR;

/*  Gate Descriptor */
typedef struct s_gate
{
	u16	offset_low;	/* Offset Low */
	u16	selector;	/* Selector */
	u8	dcount;		/* 该字段只在调用门描述符中有效。�?�果在利�?
				   调用门调用子程序时引起特权级的转换和堆栈
				   的改变，需要将外层堆栈�?的参数�?�制到内�?
				   堆栈。�?�双字�?�数字�?�就�?用于说明这�?�情�?
				   发生时，要�?�制的双字参数的数量�?*/
	u8	attr;		/* P(1) DPL(2) DT(1) TYPE(4) */
	u16	offset_high;	/* Offset High */
}GATE;

typedef struct s_tss {
	u32	backlink;
	u32	esp0;		/* stack pointer to use during interrupt */
	u32	ss0;		/*   "   segment  "  "    "        "     */
	u32	esp1;
	u32	ss1;
	u32	esp2;
	u32	ss2;
	u32	cr3;
	u32	eip;
	u32	flags;
	u32	eax;
	u32	ecx;
	u32	edx;
	u32	ebx;
	u32	esp;
	u32	ebp;
	u32	esi;
	u32	edi;
	u32	es;
	u32	cs;
	u32	ss;
	u32	ds;
	u32	fs;
	u32	gs;
	u32	ldt;
	u16	trap;
	u16	iobase;	/* I/O位图基址大于或等于TSS段界限，就表示没有I/O许可位图 */
	/*u8	iomap[2];*/
}TSS;

/* GDT */
/* 描述符索�? */
#define	INDEX_DUMMY			0	// �?
#define	INDEX_FLAT_C		1	// �? LOADER 里面已经�?定了�?.
#define	INDEX_FLAT_RW		2	// �?
#define	INDEX_VIDEO			3	// �?
#define	INDEX_TSS		4
#define	INDEX_LDT_FIRST		5
/* 选择�? */
#define	SELECTOR_DUMMY		   0		// �?
#define	SELECTOR_FLAT_C		0x08		// �? LOADER 里面已经�?定了�?. 
#define	SELECTOR_FLAT_RW	0x10		// �?
#define	SELECTOR_VIDEO		(0x18+3)	// �?<-- RPL=3
#define	SELECTOR_TSS		0x20		// TSS. 从�?�层跳到内存�? SS �? ESP 的值从里面获得.
#define SELECTOR_LDT_FIRST	0x28

#define	SELECTOR_KERNEL_CS	SELECTOR_FLAT_C
#define	SELECTOR_KERNEL_DS	SELECTOR_FLAT_RW
#define	SELECTOR_KERNEL_GS	SELECTOR_VIDEO

/* 每个任务有一�?单独�? LDT, 每个 LDT �?的描述�?�个�?: */
#define LDT_SIZE		2

/* 描述符类型值�?�明 */
#define	DA_32			0x4000	/* 32 位�??				*/
#define	DA_LIMIT_4K		0x8000	/* 段界限粒度为 4K 字节			*/
#define	DA_DPL0			0x00	/* DPL = 0				*/
#define	DA_DPL1			0x20	/* DPL = 1				*/
#define	DA_DPL2			0x40	/* DPL = 2				*/
#define	DA_DPL3			0x60	/* DPL = 3				*/
/* 存储段描述�?�类型值�?�明 */
#define	DA_DR			0x90	/* 存在的只读数�?段类型�?		*/
#define	DA_DRW			0x92	/* 存在的可读写数据段属性�?		*/
#define	DA_DRWA			0x93	/* 存在的已访问�?读写数据段类型�?	*/
#define	DA_C			0x98	/* 存在的只执�?�代码�?�属性�?		*/
#define	DA_CR			0x9A	/* 存在的可执�?�可读代码�?�属性�?		*/
#define	DA_CCO			0x9C	/* 存在的只执�?�一致代码�?�属性�?		*/
#define	DA_CCOR			0x9E	/* 存在的可执�?�可读一致代码�?�属性�?	*/
/* 系统段描述�?�类型值�?�明 */
#define	DA_LDT			0x82	/* 局部描述�?�表段类型�?			*/
#define	DA_TaskGate		0x85	/* 任务门类型�?				*/
#define	DA_386TSS		0x89	/* �?�? 386 任务状态�?�类型�?		*/
#define	DA_386CGate		0x8C	/* 386 调用门类型�?			*/
#define	DA_386IGate		0x8E	/* 386 �?�?门类型�?			*/
#define	DA_386TGate		0x8F	/* 386 陷阱门类型�?			*/

/* 选择子类型值�?�明 */
/* 其中, SA_ : Selector Attribute */
#define	SA_RPL_MASK	0xFFFC
#define	SA_RPL0		0
#define	SA_RPL1		1
#define	SA_RPL2		2
#define	SA_RPL3		3

#define	SA_TI_MASK	0xFFFB
#define	SA_TIG		0
#define	SA_TIL		4

/* �?�?向量 */
#define	INT_VECTOR_DIVIDE		0x0
#define	INT_VECTOR_DEBUG		0x1
#define	INT_VECTOR_NMI			0x2
#define	INT_VECTOR_BREAKPOINT		0x3
#define	INT_VECTOR_OVERFLOW		0x4
#define	INT_VECTOR_BOUNDS		0x5
#define	INT_VECTOR_INVAL_OP		0x6
#define	INT_VECTOR_COPROC_NOT		0x7
#define	INT_VECTOR_DOUBLE_FAULT		0x8
#define	INT_VECTOR_COPROC_SEG		0x9
#define	INT_VECTOR_INVAL_TSS		0xA
#define	INT_VECTOR_SEG_NOT		0xB
#define	INT_VECTOR_STACK_FAULT		0xC
#define	INT_VECTOR_PROTECTION		0xD
#define	INT_VECTOR_PAGE_FAULT		0xE
#define	INT_VECTOR_COPROC_ERR		0x10

/* �?�?向量 */
#define	INT_VECTOR_IRQ0			0x20
#define	INT_VECTOR_IRQ8			0x28


/* �? */
/* 线性地址 �? 物理地址 */
#define vir2phys(seg_base, vir)	(u32)(((u32)seg_base) + (u32)(vir))


#endif /* _ORANGES_PROTECT_H_ */
