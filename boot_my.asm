; %define        _BOOT_DEBUG_

%ifdef  _BOOT_DEBUG_
    org 0100h
%else
    org 07c00h
%endif

%ifdef  _BOOT_DEBUG_
BaseOfStack     equ 0100h
%else
BaseOfStack     equ 07c00h
%endif

BaseOfLoader    equ 09000h      ; the location where loader.bin is located --- segment address
OffsetOfLoader  equ 0100h       ; the location where loader.bin is located --- offset address

RootDirSectors  equ 14          ; 根目录占用空间
SectorNoOfRootDirectory equ 19	; the first sector number of Root Dirctory
SectorNoOfFAT1	equ 1		; the first sector number of FAT1 = BPB_RsvdSecCnt
DeltaSectorNo	equ 17		; DeltaSectorNo = BPB_RsvdSeCnt + (BPB_NumFATs * FATSz) - 2
				; 文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
	jmp short LABEL_START	; Start to boot
	nop 			; this nop is necessary
    	
	; Below is the FAT12 disk header
	BS_OEMName	DB 'ForrestY'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512		; 每扇区字节数
	BPB_SecPerClus	DB 1		; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1		; Boot 记录占用多少扇区
	BPB_NumFATs	DB 2		; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224		; 根目录文件数最大值
	BPB_TotSec16	DW 2880		; 逻辑扇区总数
	BPB_Media	DB 0xF0		; 媒体描述符
	BPB_FATSz16	DW 9		; 每FAT扇区数
	BPB_SecPerTrk	DW 18		; 每磁道扇区数
	BPB_NumHeads	DW 2		; 磁头数(面数)
	BPB_HiddSec	DD 0		; 隐藏扇区数
	BPB_TotSec32	DD 0		; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
	BS_DrvNum	DB 0		; 中断 13 的驱动器号
	BS_Reserved1	DB 0		; 未使用
	BS_BootSig	DB 29h		; 扩展引导标记 (29h)
	BS_VolID	DD 0		; 卷序列号
	BS_VolLab	DB 'OrangeS0.02'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节
	
LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack
	
	; flush screen
	mov ax, 0600h	; AH = 6, AL = 0h
	mov bx, 0700h	; 黑底白字(BL = 07h)
	mov cx, 0	; 左上角(0,0)
	mov dx, 0184fh	; 右下角(80,50)
	int 10h
	
	mov dh, 0	; 0th string: "Booting  "
	call DispStr	; display the designated string
	
	xor ah,ah	; reset software driver
	xor dl, dl	;
	int 13h		;

; find loader.bin in diskA's root directory
	mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	; judge whether the root dirctory has already been read over
	; if it is read over, then there is no loader.bin 
	cmp word [wRootDirSizeForLoop], 0
	jz LABEL_NO_LOADERBIN
	dec word [wRootDirSizeForLoop]
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader	; es:bx -> BaseOfLoader:OffsetOfLoader
	mov ax, [wSectorNo]	; ax <- a sector num in root directory
	mov cl, 1		; a parameter of ReadSector saved in sl
	call ReadSector

	mov si, LoaderFileName	; ds:si -> "LOADER  BIN"
	mov di, OffsetOfLoader	; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	; 循环次数控制，如果已经读完了一个sector，就跳到下一个sector;一个sector里似乎有16(10h)个根目录条目？
	cmp dx, 0
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	
	dec dx
	mov cx, 11
LABEL_CMP_FILENAME:
	cmp cx, 0
	jz LABEL_FILENAME_FOUND
	dec cx
	lodsb			; ds:si -> al; si++
	cmp al, byte [es:di]
	jz LABEL_GO_ON
	jmp LABEL_DIFFERENT	;只要发现不一样的字符就表明本 DirectoryEntry 不是要找的
LABEL_GO_ON:
	inc di
	jmp LABEL_CMP_FILENAME
	
LABEL_DIFFERENT:	
	and di, 0FFE0h		; di &= E0 为了让它指向本条目开头
	add di, 20h		; di += 20h 到下一个条目
	mov si, LoaderFileName
	jmp LABEL_SEARCH_FOR_LOADERBIN
	
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add word [wSectorNo], 1
	jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN
	
LABEL_NO_LOADERBIN:
	mov dh, 2		; the 2th string "No LOADER."
	call DispStr
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h		; ┓
	int	21h			    ; ┛没有找到 LOADER.BIN, 回到 DOS
%else
	jmp	$			; 没有找到 LOADER.BIN, 死循环在这里
%endif

LABEL_FILENAME_FOUND:
	mov ax, RootDirSectors
	and di, 0FFE0h	; di -> the begin of current entry
	add di, 01Ah	; di -> DIR_FstClus --- beginning cluster number
	mov cx, word [es:di]	; beginning cluster number 起始簇号 => 对应在FAT中的序号
	push cx			; 保存此sector在FAT中的序号 
	add cx, ax
	add cx, DeltaSectorNo	; cl <- the beginning sector number of loader.bin 
	mov ax, BaseOfLoader
	mov es, ax				; es <- BaseOfLoader
	mov bx, OffsetOfLoader	; bx <- OffsetOfLoader
	mov ax, cx				; ax <- loader.bin所在扇区号

; loader.bin可能占多个扇区，需要用FAT表来找到所有的簇（扇区）。
; 文件的每个簇在FAT表里都有个表项，从第2个表项开始，表示数据区的第一个簇
; FAT项的值代表文件的下一个簇号
LABEL_GOON_LOADING_FILE:
	; 每读一个扇区就在“Booting  ”后面打一个点，
	push ax
	push bx
	mov ah, 0Eh
	mov al, '.'
	mov bl, 0Fh
	int 10h
	pop bx
	pop ax

	mov cl, 1
	call ReadSector
	pop ax				; 取出此sector在FAT中的序号
	call GetFATEntry	; 这个函数的作用就是把文件的下一个簇号读到ax中
	cmp ax, 0FFFh
	jz LABEL_FILE_LOADED
	push ax				; 保存刚得到的文件下一个簇号，也即是在FAT中的序号
	mov dx, RootDirSectors
	add ax, dx
	add ax, DeltaSectorNo
	add bx, [BPB_BytsPerSec]	; 紧接着上一个读入的扇区. bx <- OffsetOfLoader
	jmp LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	mov dh, 1			; 第1个string "Ready."
	call DispStr		; 显示字符串

; ************************************************************************
	; 跳入已加载到内存中的loader.bin开始处
	; 开始执行loader.bin代码.
	; boot sector至此完成任务
	jmp BaseOfLoader:OffsetOfLoader
; ************************************************************************



;============================================================================
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数, 在循环中会递减至零.
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数

;============================================================================
;字符串
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; LOADER.BIN 之文件名
; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9字节, 不够则用空格补齐. 序号 0
Message1		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
Message2		db	"No LOADER"; 9字节, 不够则用空格补齐. 序号 2
;============================================================================


; Function: DispStr
; 显示一个字符串，函数的参数在dh中，表示字符串的序号
DispStr:
	mov ax, MessageLength
	mul dh
	add ax, BootMessage
	; 构成串地址 es:bp = 串地址
	mov bp, ax
	mov ax, ds
	mov es, ax
	mov cx, MessageLength		; cx = 串长度
	mov ax, 01301h				; AH = 13,  AL = 01h
	mov bx, 0007h				; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov dl, 0
	int 10h
	ret


; Function: ReadSector
; 从第ax个secotr开始，将cl个sector读入es:bx开始的内存地址
ReadSector:
	; 由扇区号秋扇区在磁盘中的位置(扇区号 -> 柱面号, 起始扇区, 磁头号)
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数      │
	;                   └ 余 z => 起始扇区号 = z + 1
	push bp
	mov bp, sp
	sub esp, 2		; allocate 2 bytes in stack to store the number of sector

	mov byte [bp-2] , cl
	push bx			; 保存bx
	mov	bl, [BPB_SecPerTrk]		; 这行忘了写cnm
	div bl			; y 在 al 中, z 在 ah 中
	inc ah			; z++
	mov cl, ah		; cl <- 起始扇区号
	mov dh, al		; dh <- y
	shr al, 1		; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov ch, al		; ch <- 柱面号
	and dh, 1		; dh & 1 = 磁头号
	pop bx			; 恢复bx
	; ch: 柱面号  cl: 起始扇区号  dh: 、磁头号
	mov dl, [BS_DrvNum]		; 驱动器号(0表示A盘)
.GoOnReading:
	mov	ah, 2				; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h					; 把指定磁盘位置的扇区(ch, cl, dh)读到指定内存位置(es:bx)
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret



; Function: GetFATEntry
; 找到序号(在FAT中的序号，从2开始)为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中(结果是文件下一个簇的簇号，也就是在FAT中的序号)
GetFATEntry:
	push es
	push bx
	push ax
	; 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
	mov ax, BaseOfLoader
	sub ax, 0100h
	mov es, ax
	pop ax
	mov byte [bOdd], 0
	mov	bx, 3		; 又忘了写这一行cnm
	mul	bx			; dx:ax = ax * 3
	mov bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp dx, 0
	jz LABEL_EVEN
	mov byte [bOdd], 1
LABEL_EVEN:
	; 现在 ax 中是 FATEntry 在 FAT 中的偏移量,下面来
	; 计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx			
	mov	bx, [BPB_BytsPerSec]
	div	bx ; dx:ax / BPB_BytsPerSec
		   ;  ax <- 商 (FATEntry 所在的扇区相对于 FAT 的扇区号)
		   ;  dx <- 余数 (FATEntry 在扇区内的偏移)
	push	dx
	mov	bx, 0 ; bx <- 0 于是, es:bx = (BaseOfLoader - 100):00
	add	ax, SectorNoOfFAT1 ; 此句之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector ; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界
			   		   ; 发生错误, 因为一个 FATEntry 可能跨越两个扇区
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and ax, 0FFFh

LABEL_GET_FAT_ENTRY_OK:
	pop bx
	pop es
	ret

; --------------------------------------------------------------------
times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志





	

	

		
	
		







