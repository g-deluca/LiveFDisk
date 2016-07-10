;---------------------------------------------------
; MAIN
  
   mov sp, 0x8000   ; sp: 2000h past code start
   
   xor ah, ah
   mov al, 0x03
   int 0x10         ; starts video mode

   xor ax, ax    ; make it zero
   mov ss, ax   ; stack starts at 0

 
;------------------------------------
;menu
menu:
   call clear_screen
   mov byte [xpos], 10
   mov byte [ypos], 3
   mov byte [partition_number], 0
   
   mov ah, 0x09      ; attribute
   mov si, hellomsg   ; text string
   call print_string
   add byte [ypos], 2  ;down two rows
   mov byte [xpos], 10  ;new line
   
   mov ah, 0x07
   mov si, option1
   call print_string
   add byte [ypos], 1   ;down one rows
   mov byte [xpos], 10  ;new line
  
   mov si, option2
   call print_string
   add byte [ypos], 1   ;down one row
   mov byte [xpos], 10  ;new line
   
   mov si, option3
   call print_string
   add byte [ypos], 2   ;down two row
   mov byte [xpos], 10  ;new line
   
  mov si, quitmsg
   call print_string
   add byte [ypos], 1  ;down one rows
   mov byte [xpos], 10  ;new line
   
   mov si, _quitmsg
   call print_string
   add byte [ypos], 2  ;down two rows
   mov byte [xpos], 10  ;new line
   
   jmp wait_menu


wait_menu:
   mov ah, 0
   int 0x16
   cmp al, 0x71    ; is it 'q' ?
   je shutdown     ; then quit
   
   cmp al, 0x31    ; is it '1' ?
   je table        ; then print table 

   cmp al, 0x32    ; is it '2'?
   je general_data
   
   cmp al, 0x33    ; is it '3'?
   je change_id

   jmp wait_menu       ; if not, keep waiting

;------------------------------------
;option 1 chosen: read partition table 
table:
   mov ah, 0x02    ; read sectors
   mov al, 1       ; read one sector
   mov cl, 1       ; 1st sector
   xor ch, ch      ; cylinder 0
   xor dh, dh      ; head 0
   mov dl, 0x80    ; first hdd
   mov bx, 0x9000
   mov es, bx
   xor bx, bx
   int 0x13
   jc error

;now we print the titles of the columns in the table
   mov ah, 0x03
   mov si, titles
   call print_string
;and we start the interpretation of what we read
   mov bx, 0x1be   ; first partition (es:bx = 0x9000:0x01be)

read_partition:
   add byte [ypos], 1
   mov byte [xpos], 18
   add byte [partition_number], 1
   cmp byte [partition_number], 5  ; check if it's the last partition
   jz hang
   push ax
   push bx
   movzx ax, byte [partition_number]
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string
   pop bx
   pop ax

start_end_cylinder:
   mov byte [xpos], 25
   mov ah, [es:bx+2]   
   shr ah, 6        ; getting the upper two bits of the starting cylinder
   mov al, [es:bx+3]  ; getting the lowest bits of the starting cylinder 
   inc ax
   push bx
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string
   pop bx
   mov byte [xpos], 33  ; position ready for the next entry
   mov ah, [es:bx+6]   
   shr ah, 6        ; getting the upper two bits of the ending cylinder
   mov al, [es:bx+7]  ; getting the lowest bits of the ending cylinder    
   inc ax
   push bx
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string
   pop bx
 
system_id:
   mov byte [xpos], 41  ; position ready for next entry
   push bx
   movzx ax, byte [es:bx+4]   ; get system id from table
   mov bl, 0x10
   call convert_number
   mov ah, 0x0f 
   call print_string
   pop bx
   

name_id:
   mov byte [xpos], 48  ; position ready for next entry
   mov ah, 0x0f
   
   cmp byte [es:bx+4], 0x82    ; is it a linux swap?
   jz _swap
   
   cmp byte [es:bx+4], 0x83    ; is it a linux?
   jz _Linux

   cmp byte [es:bx+4], 0x07    ; is it a NTFS?
   jz _NTFS
   cmp byte [es:bx+4], 0x27    ; is it a NTFS?
   jz _NTFS
   cmp byte [es:bx+4], 0x87    ; is it a NTFS?
   jz _NTFS

   cmp byte [es:bx+4], 0xcb    ; is it a FAT 32?
   jz _FAT32
   cmp byte [es:bx+4], 0x0b    
   jz _FAT32
   cmp byte [es:bx+4], 0x0c    
   jz _FAT32
   cmp byte [es:bx+4], 0x1b  
   jz _FAT32
   cmp byte [es:bx+4], 0x1c 
   jz _FAT32
   cmp byte [es:bx+4], 0xcb  
   jz _FAT32
   cmp byte [es:bx+4], 0xcc 
   jz _FAT32
   
   cmp byte [es:bx+4], 0x85    ; is it a linux extended?
   jz _LinuxExt
   
   mov si, unknown_id
   call print_string
   jmp is_boot

_swap:
   mov si, swap_id
   call print_string
   jmp is_boot
_NTFS:
   mov si, NTFS_id
   call print_string
   jmp is_boot
_FAT32:
   mov si, FAT32_id
   call print_string
   jmp is_boot
_Linux:
   mov si, Linux_id
   call print_string
   jmp is_boot
_LinuxExt:
   mov si, LinuxExt_id
   call print_string
   jmp is_boot


is_boot:
   mov byte [xpos], 64  ; position ready for next entry
   cmp byte [es:bx], 0x80   ; is it a booteable partition?
   jne _noBoot
   mov ah, 0x0f
   mov si, bootmsg
   call print_string
_noBoot:
   add bx, 0x10
   jmp read_partition

;------------------------------------
;option 2 chosen: get general information
general_data:
   mov ah, 0x08
   mov dl, 0x80
   int 0x13   ; dh: maximum head number, ch: maximum cylinder number
              ; cl: maximum sector number (high two bits of maximum cylinder number)
   jc error
   push cx
   push dx
   mov ah, 0x03
   mov si, max_head    ; showing the maximum head number
   call print_string
   mov ah, 0x0f
   pop dx
   xor ax, ax
   mov al, dh
   inc ax
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string
   add byte [ypos], 1
   mov byte [xpos], 10 
   mov ah, 0x03
   mov si, max_cyl
   call print_string 
   pop cx
   mov al, ch
   mov ah, cl
   push cx
   shr ah, 6
   inc ax
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string
   add byte [ypos], 1
   mov byte [xpos], 10 
   mov ah, 0x03
   mov si, max_sec
   call print_string
   pop cx
   xor ax, ax
   mov al, cl
   and al, 0x3f
   inc ax
   mov bl, 0x0a
   call convert_number
   mov ah, 0x0f
   call print_string  
   jmp hang


;------------------------------------
;option 3 chosen: change id of 3rd partition
change_id:
   mov ah, 0x07
   mov si, change1
   call print_string
   add byte [ypos], 1  ;down two rows
   mov byte [xpos], 10  ;new line
   mov si, change2
   call print_string
   add byte [ypos], 1  ;down two rows
   mov byte [xpos], 10  ;new line
   mov si, change3
   call print_string
   add byte [ypos], 2  ;down two rows
   mov byte [xpos], 10  ;new line
   mov ah, 0x0f
   mov si, work
   call print_string
   mov bx, 0x9000
   mov es, bx
   xor bx, bx
   mov bx, 0x01de
_loop:
   mov ah, 0
   int 0x16
   cmp al, 0x71   ; is it 'q'?
   jz menu      
   cmp al, 0x31   ; is it '1'?
   jz _change_NTFS
   cmp al, 0x32   ; is it '2'?
   jz _change_Linux
   cmp al, 0x33   ; is it '3'?
   jz _change_BSD
   jmp _loop
_change_NTFS:
   mov byte [es:bx+4], 0x07   ; make it NTFS
   jmp _continue
_change_Linux:
   mov byte [es:bx+4], 0x83   ; make it Linux
   jmp _continue
_change_BSD:
   mov byte [es:bx+4], 0xa5

_continue:
   mov ah, 0x03    ; write sector
   mov al, 0x01    ; 1 sector
   xor ch, ch      ; cylinder 0
   xor dh, dh      ; head 0
   mov cl, 0x01    ; sector 1
   mov dl, 0x80    ; first hdd
   xor bx, bx
   int 0x13
   jc error_writing
   mov ah, 0x0f
   mov si, ready
   call print_string
   
   jmp hang
   
hang:
   mov ah, 0
   int 0x16
   cmp al, 0x71    ; is it 'q' ?
   je menu         ; then go to menu
   jmp hang        ; if not, keep waiting

shutdown:
   mov ax, 0x5307   ; power management
   mov bx, 0x01     ; device id
   mov cx, 0x03     ; power status
   int 0x15

error:
   mov si, errormsg1
   mov ah, 0x04
   call print_string
   jmp hang
error_writing:
   mov si, errormsg2
   mov ah, 0x04
   call print_string
   jmp hang

;---------------------------------------------------
;AUX FUNCTIONS

;------------------------------------
;PrintString
;  Input: 
;    ah = attributes
;    si = string
;  Output: -
print_string:
   push es
   pusha
   mov cx, 0xb800   ; text video memory
   mov es, cx

_printing:
   lodsb    ; string char to AL
   cmp al, 0
   je _done   ; else, we're done

   mov cx, ax    ; save char/attribute
   movzx ax, byte [ypos]
   mov dx, 160   ; dx =  2 bytes (char/attrib)
   mul dx      ; for 80 columns
   movzx bx, byte [xpos]
   shl bx, 1    ; times 2 to skip attrib
 
   mov di, 0        ; start of video memory
   add di, ax      ; add y offset
   add di, bx      ; add x offset so that di = (x,y)
 
   mov ax, cx        ; restore char/attribute
   stosw              ; write char/attribute on es:di
   add byte [xpos], 1  ; advance to right
   jmp _printing

 _done:
   popa 
   pop es
   ret
 

;------------------------------------
; ClearScreen
;   Input: -
;   Output: -

clear_screen:
   popa
   xor ax, ax
   mov ah, 0x06
   mov bh, 0x07
   mov cx, 0x0
   mov dx, 0x184f
   int 0x10
   pusha
   ret

;------------------------------------
; ConvertNumber
;   Input:
;     ax = Number to be converted
;     bl = Base
;   Output:
;     si = Start of NUL-terminated buffer containing 
;          the converted number in ASCII represention.

convert_number:
   mov si, bufferend  ; Start at the end
_convert:
   div bl             ; Divide by base, al = quotient, ah = remainder
   mov byte [quotient], al
   add ah, 48         ; Convert to printable char ('0' = 48)
   cmp ah, 57         ; Hex digit? ('9' = 57)
   jbe _store         ; No. Store it
   add ah, 7          ; Adjust hex digit ('A'-'0'-10 = 65 - 48 - 10 = 7)
_store:
   dec si             ; Move back one position
   mov [si], ah       ; Store converted digit
   and al, al         ; Division result 0?
   jz _doneconv       ; Yes? Then it's done
   movzx ax, byte [quotient]
   jmp _convert       ; No? Keep converting
_doneconv:   
   ret

;------------------------------------
;VARIABLES AND CONSTANTS

;partition table data
partition_number db 0

;system id's
swap_id db "Linux swap",0
NTFS_id db "NTFS",0
FAT32_id db "FAT 32",0
Linux_id db "Linux",0
LinuxExt_id db "Linux extended",0
unknown_id db "Unknown",0

;variables needed for printing 
xpos   db 10
ypos   db 3

;messages
change1 db "1. NTFS",0
change2 db "2. Linux",0
change3 db "3. BSD",0
work db "Working...",0
ready db "  DONE",0
option1 db "1) Show partition table",0
option2 db "2) Show drive parameters",0
option3 db "3) Change ID from 3rd partition (Use after reading partition table)",0
quitmsg db "Press 'q' to quit",0
_quitmsg db "When you choose an option press 'q' to go back to menu",0
hellomsg db "Welcome to my LiveFDisk :D", 0
errormsg1 db "int 0x13 failed reading disk",0
errormsg2 db "int 0x13 failed writing disk",0
titles db "Partition    Start     End     ID      System       Boot", 0
bootmsg db 254,0
max_head db "Logical last index of heads: ",0
max_sec db "Logical last index of sectors per track: ",0
max_cyl db "Logical last index of cylinders: ",0

;stuff used by convert_number
buffer times 16 db 0
bufferend db 0
quotient db 0

times 0x600-($-$$) db 0   ; 1536 bytes (3 sectores)
;==================================
