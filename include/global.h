/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/


/* EXTERN is defined as extern except in global.c */
#ifdef	GLOBAL_VARIABLES_HERE
#undef	EXTERN
#define	EXTERN
#endif

EXTERN	int		disp_pos;
EXTERN	u8		gdt_ptr[6];	/* 0~15:Limit  16~47:Base */
EXTERN	DESCRIPTOR	gdt[GDT_SIZE];
EXTERN	u8		idt_ptr[6];	/* 0~15:Limit  16~47:Base */
EXTERN	GATE		idt[IDT_SIZE];

EXTERN  u32      k_reenter;       /* 初值为-1，中�?处理程序开始执行时�?增，结束时自减。非0则�?�明在一次中�?�?处理完之前又发生了一次中�? */

EXTERN  TSS      tss;
EXTERN  PROCESS* p_proc_ready;

extern	PROCESS		proc_table[];
extern	char		task_stack[];