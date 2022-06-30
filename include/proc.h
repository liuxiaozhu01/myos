
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                               proc.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */






typedef struct s_stackframe {	/* proc_ptr points here				â†? Low			*/
	u32	gs;		                /* â”?						â”?			*/
	u32	fs;		                /* â”?						â”?			*/
	u32	es;		                /* â”?						â”?			*/
	u32	ds;		                /* â”?						â”?			*/
	u32	edi;		            /* â”?						â”?			*/
	u32	esi;		            /* â”? pushed by save()		â”?			*/
	u32	ebp;		            /* â”?						â”?			*/
	u32	kernel_esp;	            /* <- 'popad' will ignore itâ”?			*/
	u32	ebx;		            /* â”?				â†‘æ ˆä»Žé«˜åœ°å€å¾€ä½Žåœ°å€å¢žé•¿*/		
	u32	edx;		            /* â”?						â”?			*/
	u32	ecx;		            /* â”?						â”?			*/
	u32	eax;		            /* â”?						â”?			*/
	u32	retaddr;	            /* return address for assembly code save()	â”?			*/
	u32	eip;		            /*  â”?						â”?			*/
	u32	cs;		                /*  â”?						â”?			*/
	u32	eflags;		            /*  â”? these are pushed by CPU during interrupt	â”?			*/
	u32	esp;		            /*  â”?						â”?			*/
	u32	ss;		                /*  â”?						â”·High			*/
}STACK_FRAME;


typedef struct s_proc {
	STACK_FRAME			regs;			/* process' registers saved in stack frame */

	u16				ldt_sel;		/* selector in gdt giving ldt base and limit*/
	DESCRIPTOR			ldts[LDT_SIZE];		/* local descriptors for code and data */
								/* 2 is LDT_SIZE - avoid include protect.h */
	u32				pid;			/* process id passed in from MM */
	char				p_name[16];		/* name of the process */
}PROCESS;


/* Number of tasks */
#define NR_TASKS	1

/* stacks of tasks */
#define STACK_SIZE_TESTA	0x8000

#define STACK_SIZE_TOTAL	STACK_SIZE_TESTA