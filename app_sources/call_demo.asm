mov ax,0ec0h
mov ds,ax
mov si,string
call 0ac0h:002ch
retf

string db 'Hello',0