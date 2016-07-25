start			mov ax,0ac0h
			mov ds,ax
			jmp start.skip

			call 0ac0h:l2chs
			retf
			call 0ac0h:srch_dir_ext
			retf
			call 0ac0h:read_rt_dir
			retf
			call 0ac0h:read_fat
			retf
			call 0ac0h:fetch_fat_entry
			retf
			call 0ac0h:read_file_ext
			retf
			call 0ac0h:print_string_f
			retf
			call 0ac0h:print_string_len
			retf
			call 0ac0h:clr_scr_wide
			retf
			call 0ac0h:clr_scr_wide
			retf
			call 0ac0h:ip_char_no_sym_bck_len
			retf
			call 0ac0h:reboot
			retf
			call 0ac0h:halt
			retf
			call 0ac0h:format8_3
			retf
			call 0ac0h:unformat8_3
			retf
			call 0ac0h:list_directory
			retf
			call 0ac0h:str_cpy
			retf
			call 0ac0h:cmp_str_len
			retf
			call 0ac0h:dmp_regs
			retf
			call 0ac0h:print_32_bit
			retf
			call 0ac0h:print_16_bit
			retf
			call 0ac0h:print_8_bit
			retf
				
.skip			mov [DriveNo],dx
			mov [SectorsPerTrack],bx
			mov [Heads],cx			

			mov ax,ds
			mov es,ax
			mov bx,curr_dir_buffer			
			call read_rt_dir
			jc disk_err_code

			mov ax,ds
			mov es,ax
			mov bx,fat_buffer		
			call read_fat
			jc disk_err_code

.init_shell_vars	mov [pwd],byte '/'
			mov [curr_dir_sector_count],word 14
			inc word [path_var_next_index]					

.prompt_command		mov si,prompt_command
			call print_string

			mov cx,3
			mov si,command_var
			call ip_char_no_sym_bck_len
.check_run		mov di,run_command
			mov bx,cx
			call cmp_str_len
			jc start.prompt_fname
.check_pwd		mov di,pwd_command
			mov bx,cx
			call cmp_str_len
			jnc start.check_clr
			mov si,pwd
			mov cx,word[path_var_next_index]
			call print_string_len
			mov si,nxt_ln
			call print_string
			jmp start.prompt_command

.check_clr		mov di,clear_command
			mov bx,cx
			call cmp_str_len
			jnc start.check_hlt
			call clr_scr_wide
			jmp start.prompt_command	

.check_hlt		mov di,halt_command
			mov bx,cx
			call cmp_str_len
			jnc start.check_rst
			jmp halt

.check_rst		mov di,reboot_command
			mov bx,cx
			call cmp_str_len
			jnc start.check_ls
			jmp reboot

.check_ls		mov di,ls_command
			mov bx,cx
			call cmp_str_len
			jnc start.check_cd
			
			mov si,curr_dir_buffer
			mov cx,word[curr_dir_sector_count]
			call list_directory
			jmp start.prompt_command

.check_cd		mov di,cd_command				;check
			mov bx,cx
			call cmp_str_len
			jnc start.inv_cmd
			
			mov si,prompt_dname				;get dir name
			call print_string				
			mov si,unform_dir_entry_var
			mov cx,12
			call ip_char_no_sym_bck_len

.check_cd_curr_dir	mov di,curr_dir_input
			mov bx,12
			call cmp_str_len
			jc start.prompt_command

.check_cd_uppr_dir	mov di,uppr_dir_input
			mov bx,12
			call cmp_str_len
			jnc start.check_cd_sub_dir
			
			jmp start.cd_srch_dir_entry

.check_cd_sub_dir	pusha
			mov di,dir_entry_var
			call format8_3
			popa

			mov si,dir_entry_var				;srch dir for sub-dir
.cd_srch_dir_entry	mov cx,word [curr_dir_sector_count]
			mov di,curr_dir_buffer
			call srch_dir_ext
			jnc start.cd_dir_nt_fnd

			add bx,11					;check if file is a sub-dir
			mov cl,[bx]
			and cl,10h
			cmp cl,00
			je start.cd_dir_nt_fnd				;not dir

			mov bx,fat_buffer				;ax -> first fat entry, si -> op buffer, bx -> fatbuff
			mov si,file_buffer	
			call read_file_ext	
			
			mov [curr_dir_sector_count],cx	

			mov ax,cx
			mov dx,0
			mul word[BytesPerSector]
			mov cx,ax					;move buffer length in bytes to cx
			mov di,curr_dir_buffer
			call str_cpy
 
.set_pwd_uppr		mov si,unform_dir_entry_var
			mov di,uppr_dir_input
			mov bx,12
			call cmp_str_len
			jnc start.set_pwd_sub_dir
			mov si,pwd
			add si,word[path_var_next_index]
.set_pwd_uppr_lp	mov ax,word [path_var_next_index]	
			cmp ax,1
			je start.cd_end
			dec si
			dec word [path_var_next_index]
			mov al,'/'
			cmp [si],al
			je start.cd_end
			jmp start.set_pwd_uppr_lp			

.set_pwd_sub_dir	mov di,pwd
			add di,word[path_var_next_index]
			mov ax,word[path_var_next_index]
			cmp ax,1
			je start.set_pwd_sub_dir_skip
			mov al,'/'
			mov [di],al
			inc di
			inc word[path_var_next_index]
.set_pwd_sub_dir_skip	mov si,unform_dir_entry_var
			mov cx,12
			call str_cpy
			add word [path_var_next_index],12
			add di,12
.set_pwd_sub_dir_lp	dec di
			mov al,' '
			cmp [di],al
			jne start.cd_end
			dec word [path_var_next_index]	
			jmp start.set_pwd_sub_dir_lp						

.cd_dir_nt_fnd		mov si,dirNotFoundMess
			call print_string
			mov si,nxt_ln
			call print_string
.cd_end			jmp start.prompt_command		

.inv_cmd		mov si,invalid_command
			call print_string
			mov si,nxt_ln
			call print_string
			jmp start.prompt_command

.prompt_fname		mov si,prompt_fname
			call print_string

			mov cx,12
			mov si,prgm_name
			call ip_char_no_sym_bck_len
			mov di,frmt_prgm_name
			call format8_3

			mov si,frmt_prgm_name
			mov di,curr_dir_buffer
			mov cx,word [curr_dir_sector_count]
			call srch_dir
			jc start.execute
			mov si,fileNotFoundMess
			call print_string
			mov si,nxt_ln
			call print_string
			jmp start.prompt_command			;correct upto getting fat entry of file, after search
			
.execute		pusha
			mov di,kernel_fname
			mov bx,11
			call cmp_str_len
			jnc start.execute_cont
			mov si,kernel_execute
			call print_string
			mov si,nxt_ln
			call print_string
			jmp start.prompt_command
	
.execute_cont		popa
			mov bx,fat_buffer
			mov si,file_buffer
			call read_file
			jc disk_err_code 	

			pusha
			call 0ec0h:0000h
			mov ax,0ac0h
			mov ds,ax
			popa
			mov si,nxt_ln
			call print_string

			jmp start.prompt_command



;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
;* STRINGS
;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
reg_al			db 'REG AL :',0
reg_ah			db 'REG AH :',0
reg_bl			db 'REG BL :',0
reg_bh			db 'REG BH :',0
reg_cl			db 'REG CL :',0
reg_ch			db 'REG CH :',0
reg_dl			db 'REG DL :',0
reg_dh			db 'REG DH :',0
nxt_ln			db 10,13,0

prompt_fname		db 'Enter program name :',0
invalid_command		db 'Error! Invalid Command',0
prompt_command		db 'Enter command :',0
prompt_dname		db 'Enter directory name :',0

halt_command		db 'hlt',0
reboot_command		db 'rst',0
run_command		db 'run',0
clear_command		db 'clr',0
pwd_command		db 'pwd',0
ls_command		db 'ls ',0
cd_command		db 'cd ',0

fileNotFoundMess	db 'File Not found',0
dirNotFoundMess		db 'Sub-directory not found',0
disk_err_str		db 'Disk Read Error',0
f_found			db 'Found File',0
kernel_execute		db 'Error! Execution of Kernel program is not allowed',0
reboot_mess		db 'Rebooting System....',10,13,'Press any key to continue ........',0
halt_mess		db 'Halting System....',10,13,'Press any key to continue ........',0

ftype_dir		db 'd ',0
ftype_file		db '- ',0

;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
;* DRIVE PARAMS
;**********************************************************************************************************************************************
;**********************************************************************************************************************************************

DriveNo			dw 0
SectorsPerTrack		dw 63					
Heads			dw 16					
DirEntriesPerSector     db 16
Rt_dir_first_sctr	db 19
NoOfRtDirSectors	db 14
FAT_first_sctr		dw 1
SectorsPerFAT		db 9
BytesPerSector		dw 512


;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
;* CONSTANTS
;**********************************************************************************************************************************************
;**********************************************************************************************************************************************

kernel_fname		db 'KERNEL     ',0
curr_dir_input		db '.           ',0
uppr_dir_input		db '..          ',0
empty_str		db '                ',0


;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
;* VARIABLES
;**********************************************************************************************************************************************
;**********************************************************************************************************************************************

command_var		db '   ',0
prgm_name		db '            ',0
frmt_prgm_name		db '           ',0
pwd			times 500 db 0
			db 0					;To allow safe print of pwd
path_var_max_len	dw 500
path_var_next_index     dw 0
curr_dir_sector_count	dw 0

dir_entry_var		db '           ',0
unform_dir_entry_var	db '            ',0


;**********************************************************************************************************************************************
;**********************************************************************************************************************************************
;* ALL FUNCTIONS
;**********************************************************************************************************************************************
;**********************************************************************************************************************************************



;**********************************************************************************************************************************************
;* DISK IO RELATED
;**********************************************************************************************************************************************

;*******************************************************************************************************
;* GET 8.3 FORMATTED NAME - Convert 8.3 fat file name to 11 char without '.' and with appropriate ' ' padding 
;* IP: [si -> pointer to source, di -> pointer to destination]
;* OP: [The data at si is formatted and outputted at di]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

format8_3		pusha
			mov cx,11
			
			pusha
			mov si,di
			call clear_str
			popa

.lp			mov al,[si]
			cmp al,'.'
			je format8_3.next
			mov bh,[si]
			
			cmp bh,97
			jc format8_3.cpy1
			cmp bh,123
			jnc format8_3.cpy1
			sub bh,32			

.cpy1			mov [di],bh
			inc si
			inc di
			loop format8_3.lp
			jmp format8_3.return

.next			inc si
.lp2			cmp cx,4
			jc format8_3.skip
			mov bh,20h
			mov [di],bh
			inc di
			loop format8_3.lp2
.skip			mov al,[si]
			mov bh,[si]
			
			cmp bh,97
			jc format8_3.cpy2
			cmp bh,123
			jnc format8_3.cpy2
			sub bh,32			

.cpy2			mov [di],bh
			inc si
			inc di
			loop format8_3.skip

.return			popa
			ret

;*******************************************************************************************************
;* GET 8.3 UNFORMATTED NAME - Convert 11 char name without '.' and with appropriate ' ' padding to 8.3 fat file name   
;* IP: [si -> pointer to source,di -> destination pointer]
;* OP: [The data at si is formatted and outputted at di]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

; cx, bx no to add to si to reach ext
; si nxt source char
; di nxt dest char

unformat8_3		pusha

			pusha
			mov si,di
			mov cx,12
			call clear_str
			popa
			
			mov cx,8
			
.lp_name		mov bx,cx
			push di
			mov di,empty_str
			call cmp_str_len
			jc unformat8_3.lp_ext
			pop di
			mov al,[si]
			mov [di],al
			inc si
			inc di
			loop unformat8_3.lp_name
			push di
			
.lp_ext			pop di	

			add si,cx
			mov bx,3
			push di
			mov di,empty_str
			call cmp_str_len
			jc unformat8_3.end

			pop di	
			mov cx,3
			mov ah,'.'
			mov [di],ah
			inc di
			call str_cpy
			push di
			
.end			pop di
			popa
			ret

;*******************************************************************************************************
;* CONVERT LOGICAL SECTOR NUMBER TO CHS AND SET CX,DX register for INT 13H : ah=2,3 
;* IP: [logical sector no -> ax] 
;* OP: [head no -> dh, drive no -> dl, sector no -> cl, cylinder no -> ch] 
;* [Except for the OP registers, no register is altered] 
;* [References to Labels of properly defined functions (those listed here) ]
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
;* SET DISK PARAMS - DriveNo, SectorsPerTrack, Heads  
;* IP: [dl -> Drive No, set by BIOS if it finds a bootable disk ] 
;* OP: [carry set -> Error, else -> fields are set]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
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
;* LIST FILES AND FOLDERS IN A DIRECTORY
;* IP: [ si -> ptr to dir buffer, cx -> no of sectors in dir ]
;* OP: [ outputs the directory contents ]
;* [All registers are restored] 
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

list_directory		pusha
			mov bl,0
			
.lp_out			push cx
			movzx cx,byte[DirEntriesPerSector]

.lp			mov al,[si]
			cmp al,0
			je list_directory.end
			cmp al,0e5h
			je list_directory.skip			

.clr_dir_entry_var	pusha
			mov si,dir_entry_var
			mov cx,11
			call clear_str
			popa	
		
.get_dir_entry		mov di,	dir_entry_var
			push cx
			mov cx,11
			call str_cpy
			pop cx		
	
			push si
			add si,11
			mov al,[si]
			and al,10h
			pop si			

.print_dir_entry	pusha
			mov si,di
			mov di,unform_dir_entry_var
			call unformat8_3

.f_type			cmp al,00h
			je list_directory.ftype_file	
			mov si,ftype_dir
			call print_string
			jmp list_directory.fname_print
.ftype_file		mov si,ftype_file
			call print_string		

.fname_print		mov si,di
			call print_string
			popa
			inc bl

			cmp bl,5
			jne list_directory.skip
			mov bl,0	
			push si	
			mov si,nxt_ln
			call print_string
			pop si

.skip			add si,32
			loop list_directory.lp
			pop cx
			loop list_directory.lp_out
			push cx
		
.end			pop cx
			mov si,nxt_ln
			call print_string
			popa
			ret

;*******************************************************************************************************
;* SEARCH A DIRECTORY BUFFER FOR A FILE 
;* IP: [si -> ptr to prgm name buffer, 	di -> ptr to dir buffer, cx -> no of sectors ]
;* OP: [If carry is set, then file found and ax is fat entry of first cluster, else carry 0 and ax restored ]
;* [Except for the OP registers, no register is altered] 
;* [References to Labels of properly defined functions (those listed here) ]
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
;* SEARCH DIRECTORY FUNCTION - EXTENDED 
;* IP: [si -> ptr to prgm name buffer, 	di -> ptr to dir buffer, cx -> no of sectors ]
;* OP: [If carry is set -> file found and ax -> fat entry of first cluster & bx -> dir entry of file , else carry 0 and all regs including 
;*      ax,bx restored ]
;* [Except for the OP registers, no register is altered] 
;* [References to Labels of properly defined functions (those listed here) ]
;*		[cmp_str_len]
;* [References to Labels other than of properly defined functions]
;*		[DirEntriesPerSector]
;*******************************************************************************************************
			
srch_dir_ext		push cx
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
			jnc srch_dir_ext.continue
			pop bx
			mov bx,di
			add di,26
			pop ax
			mov ax,[di]
			stc
			jmp srch_dir_ext.return
.continue		add di,32				; size of a directory entry
			loop srch_dir_ext.lp
			pop ax
			pop bx
			clc
.return			pop si
			pop di
			pop cx
			ret

;*******************************************************************************************************
;* READ ROOT DIRECTORY. 
;* IP: [es:bx ->Buffer to where root is to be read into]
;* OP: [ Carry set -> read error, else fat will be read to buffer ] 
;* [All registers are restored]
;* [References to Labels of properly defined functions (those listed here) ]
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
;* READ FAT
;* IP: [es:bx pointer to start of buffer ]
;* OP: [ Carry set -> read error, else fat will be read to buffer ] 
;* [All registers are restored]
;* [References to Labels of properly defined functions (those listed here) ]
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
;* FETCH FAT ENTRY  
;* IP : [si -> pointer to FAT buffer, di -> fat-index]
;* OP : ax [least significant 12 bits]
;* [All registers are restored except output register is restored]  
;* [References to Labels of properly defined functions (those listed here) ]
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
;* READ FILE  
;* IP: [ax -> FAT entry of first file cluster, bx -> FAT buffer ptr, si -> ptr to buffer where file is to be read into] 
;* OP: [carry set -> corrupted file, else -> file will be read to buffer]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

read_file		nop	
			push si		

.read_cluster		push ax
			push bx		
			cmp ax,0
			je read_file.root_dir			
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
			pop si
			ret	
	
.not_end		cmp ax,0ff0h
			jc read_file.not_resrv
.resrv			stc
			pop si
			pop si
			ret	
.not_resrv		cmp ax,000h
			jne read_file.continue	
.unused			stc
			pop si
			pop si
			ret			
.continue		pop si
			jmp read_file.read_cluster

.root_dir		mov ax,ds
			mov es,ax
			mov bx,si
			call read_rt_dir
			pop bx
			pop ax
			pop si
			ret

;*******************************************************************************************************
;* READ FILE  - EXTENDED
;* IP: [ax -> FAT entry of first file cluster, bx -> FAT buffer ptr, si -> ptr to buffer where file is to be read into] 
;* OP: [carry set -> corrupted file, else -> file will be read to buffer and cx -> sector count ]
;* [All registers are restored, except ]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

read_file_ext		nop	
			push si	
			mov cx,0	

.read_cluster		push ax
			push bx	
			push cx	
			cmp ax,0
			je read_file_ext.root_dir				
			add ax,31
			call l2chs					
			mov ax,ds
			mov es,ax
			mov bx,si
			mov ah,02h
			mov al,01h
			int 13h
			add si,512
			pop cx
			pop bx
			pop ax

.fetch_fat_entry	push si
			mov di,ax
			mov si,bx
			call fetch_fat_entry

.analyse_fat_entry	cmp ax,0ff8h
			jc read_file_ext.not_end
			clc
			pop si
			pop si
			inc cx
			ret	
	
.not_end		cmp ax,0ff0h
			jc read_file_ext.not_resrv
.resrv			stc
			pop si
			pop si
			ret	
.not_resrv		cmp ax,000h
			jne read_file_ext.continue	
.unused			stc
			pop si
			pop si
			ret			
.continue		pop si
			inc cx
			jmp read_file_ext.read_cluster	

.root_dir		mov ax,ds
			mov es,ax
			mov bx,si
			call read_rt_dir
			pop cx
			pop bx
			pop ax
			pop si
			movzx cx,byte[NoOfRtDirSectors]
			ret

;**********************************************************************************************************************************************









;**********************************************************************************************************************************************
;* STRING MANIPULATION RELATED
;**********************************************************************************************************************************************

;*******************************************************************************************************
;* STRING COPY FUNCTION 
;* IP: [si -> source, di->destination, cx -> length ]
;* OP: [copid to di]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None] 
;*******************************************************************************************************

								
str_cpy			pusha		
.lp			mov al,[si]
			mov [di],al
			inc si
			inc di
			loop str_cpy.lp			
			popa
			ret

;*******************************************************************************************************
;* STRING PRINT FUNCTION 
;* IP: [si -> string]
;* OP:
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
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

print_string_f		pusha	
			mov ah, 0Eh				; int 10h teletype function
.repeat			lodsb					; Get char from string
			cmp al, 0
			je .done				; If char is zero, end of string
			int 10h					; Otherwise, print it
			jmp short .repeat
.done		mov ax,0ac0h
			mov ds,ax
			popa
			retf

;*******************************************************************************************************
;* STRING PRINT FUNCTION FIXED NO OF CHARS
;* IP: [si -> string, cx -> len]
;* OP:
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None] 
;*******************************************************************************************************

								; Output string in SI to screen
print_string_len	pusha					
			mov ah, 0Eh				; int 10h teletype function
.repeat			lodsb					; Get char from string
			int 10h					; Otherwise, print it
			loop print_string_len.repeat
			popa
			ret

;*******************************************************************************************************
;* STRING COMPARE FUNCTION - Compare fixed two strings upto n chars.
;* IP: [si,di -> string , n -> bx]
;* OP: [carry set -> equal]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
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
;* STRING CLEAR FUNCTION - Compare fixed a string upto n chars.
;* IP: [si -> string , n -> cx]
;* OP: [String cleared]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

clear_str		pusha
.lp			mov bl,20h
			mov [si],bl
			inc si
			loop clear_str.lp
			popa
			ret

;**********************************************************************************************************************************************









;**********************************************************************************************************************************************
;* CLEAR SCREEN
;**********************************************************************************************************************************************

;*******************************************************************************************************
;* CLEAR SCREEN SQR - Clearscreen for 4:3 mode
;* IP: []
;* OP: [Clearscreen for 4:3 mode]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

clr_scr_sqr		pusha
			mov ah,00h
			mov al,00h
			int 10h
			popa
			ret

;*******************************************************************************************************
;* CLEAR SCREEN WIDESCREEN - Clearscreen for 16:9 mode
;* IP: []
;* OP: [Clearscreen for 16:9 mode]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

clr_scr_wide		pusha
			mov ah,00h
			mov al,03h
			int 10h
			popa
			ret

;**********************************************************************************************************************************************








;**********************************************************************************************************************************************
;* GET USER INPUT
;**********************************************************************************************************************************************


;*******************************************************************************************************
;* INPUT FIXED NUMBER OF UPPERCASE CHARS 
;*			       - Input a fixed number of chars from user (unless user pressed enter before the char limit) [limit >= 1]
;*          	               - This function holds control until user presses enter.
;* IP: [si -> buffer where input is to be stored, cx -> count ]
;* OP: [set carry -> user pressed enter , else -> user did not press enter]
;* [All registers are restored, (carry flag is not, but its not a register)]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

ip_char_no_sym_bck_len	pusha
			call clear_str
			inc cx
			mov bx,01h

.read_for_save		mov ah,00h
			int 16h	

			cmp al,0dh
			jne ip_char_no_sym_bck_len.letterU
			mov si,nxt_ln
			call print_string
			jmp ip_char_no_sym_bck_len.return

.letterU		cmp al,65
			jc ip_char_no_sym_bck_len.letterL
			cmp al,91
			jnc ip_char_no_sym_bck_len.letterL
			jmp ip_char_no_sym_bck_len.print_save

.print_save		mov ah,0eh
			int 10h
			mov [si],al
			inc si
			inc bx
			cmp bx,cx
			je ip_char_no_sym_bck_len.read_to_just_print
			jmp ip_char_no_sym_bck_len.read_for_save

.letterL		cmp al,97
			jc ip_char_no_sym_bck_len.num
			cmp al,123
			jnc ip_char_no_sym_bck_len.num
			jmp ip_char_no_sym_bck_len.print_save

.num			cmp al,30h
			jc ip_char_no_sym_bck_len.back
			cmp al,3ah
			jnc ip_char_no_sym_bck_len.back
			jmp ip_char_no_sym_bck_len.print_save

.back			cmp al,8
			jne ip_char_no_sym_bck_len.symbols
			cmp bx,01h
			je ip_char_no_sym_bck_len.read_for_save
			dec si
			mov [si],byte ' '
			mov ah,0eh
			int 10h
			mov al,0
			mov ah,0eh
			int 10h
			mov al,8
			mov ah,0eh
			int 10h
			dec bx
			jmp ip_char_no_sym_bck_len.read_for_save

.symbols		cmp al,32
			jc ip_char_no_sym_bck_len.read_for_save
			cmp al,48
			jc ip_char_no_sym_bck_len.print_save
			cmp al,58
			jc ip_char_no_sym_bck_len.read_for_save
			cmp al,65
			jc ip_char_no_sym_bck_len.print_save
			cmp al,91
			jc ip_char_no_sym_bck_len.read_for_save
			cmp al,97
			jc ip_char_no_sym_bck_len.print_save
			cmp al,123
			jc ip_char_no_sym_bck_len.read_for_save
			cmp al,127
			jc ip_char_no_sym_bck_len.print_save
			jmp ip_char_no_sym_bck_len.read_for_save

			
.read_to_just_print	mov ah,00h
			int 16h	

			cmp al,0dh
			jne ip_char_no_sym_bck_len.letterU2
			mov si,nxt_ln
			call print_string
			jmp ip_char_no_sym_bck_len.return	

.letterU2		cmp al,65
			jc ip_char_no_sym_bck_len.letterL2
			cmp al,91
			jnc ip_char_no_sym_bck_len.letterL2
			jmp ip_char_no_sym_bck_len.just_print

.just_print		mov ah,0eh
			int 10h
			inc bx
			jmp ip_char_no_sym_bck_len.read_to_just_print

.letterL2		cmp al,97
			jc ip_char_no_sym_bck_len.num2
			cmp al,123
			jnc ip_char_no_sym_bck_len.num2
			jmp ip_char_no_sym_bck_len.just_print

.num2			cmp al,30h
			jc ip_char_no_sym_bck_len.back2
			cmp al,3ah
			jnc ip_char_no_sym_bck_len.back2
			jmp ip_char_no_sym_bck_len.just_print

.back2			cmp al,8
			jne ip_char_no_sym_bck_len.symbols2
			cmp bx,01h
			je ip_char_no_sym_bck_len.read_to_just_print
			cmp bx,cx
			je ip_char_no_sym_bck_len.back	
			mov ah,0eh
			int 10h
			mov al,0
			mov ah,0eh
			int 10h
			mov al,8
			mov ah,0eh
			int 10h
			dec bx
			jmp ip_char_no_sym_bck_len.read_to_just_print

.symbols2		cmp al,32
			jc ip_char_no_sym_bck_len.read_to_just_print
			cmp al,48
			jc ip_char_no_sym_bck_len.just_print
			cmp al,58
			jc ip_char_no_sym_bck_len.read_to_just_print
			cmp al,65
			jc ip_char_no_sym_bck_len.just_print
			cmp al,91
			jc ip_char_no_sym_bck_len.read_to_just_print
			cmp al,97
			jc ip_char_no_sym_bck_len.just_print
			cmp al,123
			jc ip_char_no_sym_bck_len.read_to_just_print
			cmp al,127
			jc ip_char_no_sym_bck_len.just_print
			jmp ip_char_no_sym_bck_len.read_to_just_print	

.return			popa
			ret
;**********************************************************************************************************************************************








;**********************************************************************************************************************************************
;* DUMPING MEMORY AND REGISTERS
;**********************************************************************************************************************************************

;*******************************************************************************************************
;* DUMP OUT REGISTERS DISPLAY REGISTERS
;* IP: [Register values of all registers]
;* OP: [All register values are dumped]
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[print_16_bit]
;* [References to Labels other than of properly defined functions]
;*		[reg_al,reg_ah,reg_bh,reg_bl,reg_ch,reg_cl,reg_dl,reg_dh] (String to print out the register names, before reg values are 
;*              dumped)
;*******************************************************************************************************

dmp_regs		pusha

			mov si,reg_al
			call print_string
			push ax
			mov ah,00h
			call print_16_bit
			mov si,nxt_ln
			call print_string
			
			mov si,reg_ah
			call print_string
			pop ax
			movzx ax,ah
			call print_16_bit
			mov si,nxt_ln
			call print_string
			
			mov si,reg_bl
			call print_string
			movzx ax,bl
			call print_16_bit
			mov si,nxt_ln
			call print_string

			mov si,reg_bh
			call print_string
			movzx ax,bh
			call print_16_bit
			mov si,nxt_ln
			call print_string

			mov si,reg_cl
			call print_string
			movzx ax,cl
			call print_16_bit
			mov si,nxt_ln
			call print_string

			mov si,reg_ch
			call print_string
			movzx ax,ch
			call print_16_bit
			mov si,nxt_ln
			call print_string

			mov si,reg_dl
			call print_string
			movzx ax,dl
			call print_16_bit
			mov si,nxt_ln
			call print_string

			mov si,reg_dh
			call print_string
			movzx ax,dh
			call print_16_bit
			mov si,nxt_ln
			call print_string

			popa	
			ret

;*******************************************************************************************************
;* PRINT 32 bit binary (<10000,0000D) in 8 digit ASCII with zero fill   
;* IP: [32 bit binary in ax(MSBs) & dx(LSBs)]
;* OP: op the 32 bit value in BCD ASCI form
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[print_16_bit]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

print_32_bit		pusha
			mov bx,10000D
			div bx
			call print_16_bit
			mov ax,dx
			call print_16_bit
			popa
			ret

;*******************************************************************************************************
;* PRINT 16 bit binary (<10000D) in 4 digit ASCII with zero fill  
;* IP: [16 bit binary in ax]
;* OP: op the 16 bit value in BCD ASCI form
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[print_8_bit]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

print_16_bit		pusha
			mov bl,100D
			div bl
			call print_8_bit
			mov al, ah
			call print_8_bit
			popa
			ret	

;*******************************************************************************************************
;* PRINT 8 bit binary (<100D) in 2 digit ASCII with zero fill  
;* IP: [8 bit binary in al]
;* OP: op the 8 bit value in BCD ASCI form
;* [All registers are restored]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

print_8_bit		pusha
			mov ah,00h
			aam
			add ah,30h
			add al,30h
			push ax
			mov al,ah
			mov ah,0eh
			int 10h
			pop ax
			mov ah,0eh
			int 10h
			popa
			ret			

;*********************************************************************************************************************************************









;**********************************************************************************************************************************************
;* MACHINE CONTROL
;**********************************************************************************************************************************************

;*******************************************************************************************************
;* REBOOT - Wait for user prompt then reboot
;* IP: [None]
;* OP: [Terminates execution after user prompt]
;* [Are All registers are restored? Ans: Execution terminates. So, the question is meaningless]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

reboot:			mov si,reboot_mess
			call print_string
			mov ax, 0
			int 16h					; Wait for keystroke
			call clr_scr_wide
			mov ax, 0
			int 19h					; Reboot the system

;*********************************************************************************************************************************************

;*******************************************************************************************************
;* HALT - Wait for user prompt then halt
;* IP: [None]
;* OP: [Terminates execution after user prompt]
;* [Are All registers are restored? Ans: Execution terminates. So, the question is meaningless]  
;* [References to Labels of properly defined functions (those listed here) ]
;*		[None]
;* [References to Labels other than of properly defined functions]
;*		[None]
;*******************************************************************************************************

halt:			mov si,halt_mess
			call print_string
			mov ax, 0
			int 16h					; Wait for keystroke
			call clr_scr_wide
			cli
			hlt					; Halt

;*********************************************************************************************************************************************


;*******************************************************************************************************
;* DISK ERROR CODE - jmp to this label, when error occurs during bootloader execution
;*******************************************************************************************************

disk_err_code		mov si,disk_err_str
			call print_string
			mov si,nxt_ln
			call print_string
			jmp $


;**********************************************************************************************************************************************
;* BUFFERS
;**********************************************************************************************************************************************

curr_dir_buffer		times (14*512) db 1
fat_buffer		times (9*512)  db 2
			times (4000h - ($ - $$) ) db 3
file_buffer		;0x0ec0:0x0000

;*********************************************************************************************************************************************
