			jmp short start
			nop


; The disk params are expected to be set correctly by the program which creates the bootable OS Disk (except for diskno and ScPrTrck and hds)
; The hardcoded disk params are specefic to the virtual disk configuration used in the demos provided


OEMLabel		db "OS Drive"				; Disk label
BytesPerSector		dw 512					; Bytes per sector
SectorsPerCluster	db 1					; Sectors per cluster
ReservedForBoot		dw 1					; Reserved sectors for boot record
NumberOfFats		db 2					; Number of copies of the FAT
RootDirEntries		dw 224					; Number of entries in root dir
								; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors		dw 2880					; Number of logical sectors
MediumByte		db 0F0h					; Medium descriptor byte
SectorsPerFat		dw 9					; Sectors per FAT
SectorsPerTrack		dw 63					; Sectors per track (36/cylinder)
Heads			dw 15					; Number of sides/heads
HiddenSectors		dd 0					; Number of hidden sectors
LargeSectors		dd 0					; Number of LBA sectors
DriveNo			dw 0					; Drive No: 0
Signature		db 41					; Drive signature: 41 for floppy
VolumeID		dd 00000000h				; Volume ID: any number
VolumeLabel		db "FabulOS    "			; Volume Label: any 11 chars
FileSystem		db "FAT12   "				; File system type: don't change!

;*******************************************************************************************************
;* BOOTLOADER START
;*******************************************************************************************************

start			mov ax,07c0h				; data segment starts at 0x07c00
			mov ds,ax
			call set_disk_params
			jc btldr_err_code	
			
			mov ax,ds
			mov es,ax
			mov bx,root_dir_buffer			; specify mem loc where the root dir is to be loaded
			call read_rt_dir
			jc btldr_err_code

			mov ax,ds
			mov es,ax
			mov bx,fat_buffer		
			call read_fat
			jc btldr_err_code

			mov si,prgm_name
			mov di,root_dir_buffer
			mov cx,14
			call srch_dir
			jnc btldr_err_code

			mov bx, fat_buffer	
			mov si,file_buffer
			call read_file 		

.file_loaded		mov dx,word [DriveNo] 
			mov bx,word [SectorsPerTrack]
			mov cx,word [Heads]
			jmp 0ac0h:0000h

;*******************************************************************************************************
;* SET DISK PARAMS - DriveNo, SectorsPerTrack, Heads  
;* IP: [dl -> Drive No, set by BIOS if it finds a bootable disk ] 
;* OP: [carry set -> Error, else -> fields are set]
;* [All registers are restored]  
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[DriveNo, SectorsPerTrack, Heads]
;*******************************************************************************************************

set_disk_params		pusha
			movzx dx,dl
			mov [DriveNo], dx
			mov ah,08h
			int 13h
			jnc set_disk_params.set
			jmp set_disk_params.return
.set			movzx dx,dh
			mov [Heads], dx
			movzx cx,cl
			mov [SectorsPerTrack],cx
			clc
.return			popa
			ret

;*******************************************************************************************************
;* READ FILE  
;* IP: [ax -> FAT entry of first file cluster, bx -> FAT buffer ptr, si -> ptr to buffer where file is to be read into] 
;* OP: [carry set -> corrupted file, else -> file will be read to buffer]
;* [All registers are restored]  
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

read_file		nop			

.read_cluster		push ax
			push bx					
			add ax,31
			call l2chs					
			mov ax,ds
			mov es,ax
			mov bx,si
			mov ah,02h
			mov al,01h
			int 13h
			add si,512
			pop bx
			pop ax

.fetch_fat_entry	push si
			mov di,ax
			mov si,bx
			call fetch_fat_entry

.analyse_fat_entry	cmp ax,0ff8h
			jc read_file.not_end
			clc
			pop si
			ret	
	
.not_end		cmp ax,0ff0h
			jc read_file.not_resrv
.resrv			stc
			pop si
			ret	
.not_resrv		cmp ax,000h
			jne read_file.continue	
.unused			stc
			pop si
			ret			
.continue		pop si
			jmp read_file.read_cluster		

;*******************************************************************************************************
;* FETCH FAT ENTRY  
;* IP : [si -> pointer to FAT buffer, di -> fat-index]
;* OP : ax [least significant 12 bits]
;* [All registers are restored except output register is restored]  
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None] 
;*******************************************************************************************************

fetch_fat_entry		push si
			push di
			push bx
			push cx

			push di

;Convert index to triplet index

			mov ax,di			                		
			mov bl,02h			
			div bl
			mov ah,00h
			mov bl,03h			
			mul bl

			add si,ax
												
.fetch			mov bl,[si]				; fetch 3 bytes
			inc si
			mov ch,[si]
			inc si
			mov cl,[si]
			
			pop di

			mov ax,di
			mov bh,02h
			div bh
			cmp ah,00h
			jne fetch_fat_entry.odd
.even			mov al,bl
			mov ah,ch
			and ah,0fh
			jmp fetch_fat_entry.return

.odd			mov ah,cl
			and ch,0F0h
			mov al,ch
			mov cx,04h
			ror ax,04h	
			jmp fetch_fat_entry.return

.return			pop cx
			pop bx
			pop di
			pop si	
			ret

;*******************************************************************************************************
;* READ FAT
;* IP: [es:bx pointer to start of buffer ]
;* OP: [ Carry set -> read error, else fat will be read to buffer ] 
;* [All registers are restored]
;* [References to Labels of properly defined functions]
;*		[l2chs]
;* [References to Labels other than of properly defined functions]
;*		[Rt_dir_first_sctr]
;*******************************************************************************************************

read_fat		pusha
			push bx
			mov ax,word [FAT_first_sctr]
			call l2chs				
			mov ah,02h				; ah = 02h - param for disk read (int 13h)
			mov al,byte [SectorsPerFAT]		; No of sectors to read = No of sectors for fat = 9
			pop bx
			int 13h
			popa
			ret

;*******************************************************************************************************
;* DISK ERROR CODE - jmp to this label, when error occurs during bootloader execution
;*******************************************************************************************************

btldr_err_code		mov si,disk_err_str
			call print_string
			mov si,nxt_ln
			call print_string
			jmp $

;*******************************************************************************************************
;* READ ROOT DIRECTORY. 
;* IP: [ex:bx ->Buffer to where root is to be read into]
;* OP: [ Carry set -> read error, else fat will be read to buffer ] 
;* [All registers are restored]
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[Rt_dir_first_sctr]
;*******************************************************************************************************

read_rt_dir		pusha
			movzx ax,byte [Rt_dir_first_sctr]	; logical sector no of the sector to read (ie, logical sec no of root dir)
			call l2chs
			mov ah,02h
			mov al,byte [NoOfRtDirSectors]		; No of sectors to read (ie, length of root dir in sectors)
			int 13h
			popa
			ret

;*******************************************************************************************************
;* SEARCH A DIRECTORY BUFFER FOR A FILE 
;* IP: [si -> ptr to prgm name buffer, 	di -> ptr to dir buffer, cx -> no of sectors ]
;* OP: [If carry is set, then file found and ax is fat entry of first cluster, else carry 0 and ax restored ]
;* [Except for the OP registers, no register is altered] 
;* [References to Labels of properly defined functions]
;*		[cmp_str_len]
;* [References to Labels other than of properly defined functions]
;*		[DirEntriesPerSector]
;*******************************************************************************************************
			
srch_dir		push cx
			push dx
			push ax

			movzx ax,byte [DirEntriesPerSector]
			mov dx,00h
			mul cx
			mov cx,ax
			pop ax
			pop dx

			push bx
			push di
			push si
			push ax
			mov bx, 11				; size in bytes of each filename = no of characters to compare for match
.lp			call cmp_str_len
			jnc srch_dir.continue
			add di,26
			pop ax
			mov ax,[di]
			stc
			jmp srch_dir.return
.continue		add di,32				; size of a directory entry
			loop srch_dir.lp
			pop ax
			clc
.return			pop si
			pop di
			pop bx
			pop cx
			ret

;*******************************************************************************************************
;* CONVERT LOGICAL SECTOR NUMBER TO CHS AND SET CX,DX register for INT 13H : ah=2,3 
;* IP: [logical sector no -> ax] 
;* OP: [head no -> dh, drive no -> dl, sector no -> cl, cylinder no -> ch] 
;* [Except for the OP registers, no register is altered] 
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[SectorsPerTrack, Heads, DiskNo]
;*******************************************************************************************************

l2chs			push bx
			push ax
			mov bx, ax				; Save logical sector
			mov dx, 0				; First the sector
			div word [SectorsPerTrack]
			add dl, 01h				; Physical sectors start at 1
			mov cl, dl				; Sectors belong in CL for int 13h
			mov ax, bx
			mov dx, 0				; Now calculate the head
			div word [SectorsPerTrack]
			mov dx, 0
			div word [Heads]
			mov dh, dl				; Head/side
			mov ch, al				; Track
			mov dl, byte [DriveNo]			; Set correct device
			pop ax
			pop bx
			ret

;*******************************************************************************************************
;* STRING COMPARE FUNCTION - Compare fixed two strings upto n chars.
;* IP: [si,di -> string , n -> bx]
;* OP:
;* [All registers are restored]  
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

cmp_str_len		pusha
			cld
			mov ax,ds
			mov es,ax
			mov cx,bx
			rep cmpsb
			jne cmp_str_len.uneq
.eq 			stc					
			jmp cmp_str_len.end
.uneq			clc			
.end			popa
			ret

;*******************************************************************************************************
;* STRING PRINT FUNCTION 
;* IP: [si -> string]
;* OP:
;* [All registers are restored]  
;* [References to Labels of properly defined functions]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None] 
;*******************************************************************************************************
	
								; Output string in SI to screen
print_string		pusha					
			mov ah, 0Eh				; int 10h teletype function
.repeat			lodsb					; Get char from string
			cmp al, 0
			je .done				; If char is zero, end of string
			int 10h					; Otherwise, print it
			jmp short .repeat
.done			popa
			ret	

;*******************************************************************************************************
;* CONSTANTS
;*******************************************************************************************************

BytesPerDirEntry	db 32
Rt_dir_first_sctr	db 19
nxt_ln			db 10,13,0
disk_err_str		db 'BE',0
prgm_name		db 'KERNEL     '
DirEntriesPerSector     db 16
NoOfRtDirSectors	db 14
FAT_first_sctr		dw 1
SectorsPerFAT		db 9

;*******************************************************************************************************
;* BOOT SIGNATURE
;*******************************************************************************************************

			times 510 - ($-$$) db 0
			dw 0xaa55

;*******************************************************************************************************
;* BELOW BOOT LOADER
;*******************************************************************************************************

root_dir_buffer		times (224*32) db 0
fat_buffer		times (512*9) db 0
file_buffer					;In memory location 0x0AC0:0x0000, assuming boot sector is loaded into 0x07c0:0x0000
