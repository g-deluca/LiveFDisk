[ORG 0x7c00]

   ; load my program into memory

   mov ah, 0x02   ; read
   mov al, 0x03   ; 3 sectors
   xor ch, ch     ; cylinder 0
   xor dh, dh     ; head 0
   mov cl, 0x02   ; from sector 2
   xor dl, dl     ; from floppy
   mov bx, 0x8000
   mov es, bx
   xor bx, bx
   int 0x13       ; es:bx = load program in 0x8000:0x0000
   jc error

   mov bx, 0x8000
   mov ds, bx
   jmp 0x8000:0

error:
   jmp error
   
   times 0x1fe-($-$$) db 0  ; fill 1st sector with 0's
   dw 0xaa55                ; signature
   
   
