start			mov ax,0ec0h
			mov ds,ax
			
			mov si,prompt
			call print_string
	
			mov ah,0
			int 16h

			mov ah,0eh
			int 10h

			push ax
			mov al,0dh
			int 10h
			mov al,0ah
			int 10h
			pop ax
			
			sub al,30h
			movzx cx,al

			mov dx,0
			mov ax,1
		
.lp			mul cx
			loop .lp

			mov si,result
			call print_string

			call print_32_bit

			retf

prompt			db 'Enter digit (< 9) :',0
result			db 'Factorial :',0

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
