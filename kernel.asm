[BITS 16]
[ORG 500h]

start:
    cli
    call set_video_mode
    call print_interface
    call print_newline
    call shell
    jmp $

set_video_mode:
    mov ax, 0x03
    int 0x10
    ret

print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

print_newline:
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    ret

print_interface:
    mov si, header
    call print_string
    mov si, menu
    call print_string
    call print_newline
    ret

print_help:
    mov si, menu
    call print_string
    call print_newline
    ret

shell:
    mov si, prompt
    call print_string
    call read_command
    call print_newline
    call execute_command
    jmp shell

read_command:
    mov di, command_buffer
    xor cx, cx
.read_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .done_read
    cmp al, 0x08
    je .handle_backspace
    cmp cx, 255
    jge .done_read
    stosb
    mov ah, 0x0E
    mov bl, 0x1F
    int 0x10
    inc cx
    jmp .read_loop

.handle_backspace:
    cmp di, command_buffer
    je .read_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .read_loop

.done_read:
    mov byte [di], 0
    ret

execute_command:
    mov si, command_buffer
    
    ;проверка на help
    mov di, help_cmd
    call compare_strings
    je do_help
    ;проверка на cls
    mov di, cls_cmd
    call compare_strings
    je do_cls

    ; проверка на shut
    mov di, shut_cmd
    call compare_strings
    je do_shutdown

    ;проверка на load
    mov di, load_cmd
    call compare_strings
    je load_program

    ;если не распознано
    call unknown_command
    ret

do_banner:
    call print_interface
    call print_newline
    ret

do_help:
    call print_help
    call print_newline
    ret

do_cls:
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10

    ret

unknown_command:
    mov si, unknown_msg
    call print_string
    call print_newline
    ret

do_shutdown:
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    ret

compare_strings:
    push si                 ;сохраняем SI
    push di                 ;сохраняем DI
    .compare_loop:
        lodsb               ; загружаем символ из [SI] в AL и увеличиваем SI
        scasb               ; сравниваем AL с символом по адресу [DI] и увеличиваем DI
        jne .not_equal      ; если символы не равны, выходим с флагом неравенства
        cmp al, 0           ;проверяем, достигли ли конца строки (нулевой байт)
        je .equal           ;Если достигли конца строки, строки равны
        jmp .compare_loop   ; Продолжаем сравнение
    .not_equal:
        pop di              ;восстанавливаем DI
        pop si              ;восстанавливаем SI
        ret                 ;возвращаемся, если строки не равны
    .equal:
        pop di              ; Восстанавливаем DI
        pop si              ; Восстанавливаем SI
        ret                 ; Возвращаемся, если строки равны     ; Возвращаемся, если строки равны

help_cmd db "help", 0
cls_cmd db "cls", 0
shut_cmd db "shut", 0
load_cmd db "load", 0
    
load_program:
    mov si, command_buffer
    add si, 5

    xor ax, ax
    mov cl, 0
.next_digit:
    cmp byte [si], 0
    je .done_load
    cmp byte [si], '0'
    jb .done_load
    cmp byte [si], '9'
    ja .done_load
    sub byte [si], '0'
    mov bl, [si]
    mov ax, ax
    mov al, bl
    add ax, cx
    shl cx, 1
    shl cx, 1
    add cx, ax
    inc si
    jmp .next_digit
.done_load:
    call start_program
    ret

start_program:
    mov ah, 0x02
    mov al, 16
    mov ch, 0
    mov dh, 0
    mov cl, cl
    mov bx, 700h
    int 0x13
    jmp 700h

write_to_sector:
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 10
    mov dh, 0
    mov dl, 0x80
    mov bx, text_to_write

    int 0x13

    jc write_error

    mov si, success_msg
    call print_string
    call read_from_sector
    ret
    
read_from_sector:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 10
    mov dh, 0
    mov dl, 0x80
    mov bx, buffer

    int 0x13

    jc read_error

    mov si, buffer
    call print_string
    call print_newline
    ret
    
write_error db 'Write error!', 0
read_error db 'Read error!', 0
        
header db '=============================    XorisOS    ====================================', 0
menu db '_________________________________________________', 10, 13, 10 ,13
     db 'Commands:', 10, 13, 10, 13
     db '  help - get list of the commands', 10, 13
     db '  cls - clear terminal', 10, 13
     db '  shut - shutdown PC', 10, 13
     db '  load <sector num> - load program from disk sector', 10, 13
     db '_________________________________________________', 0
unknown_msg db 'Unknown command.', 0
prompt db 'user#xos~$ ', 0
mt db '', 10, 13, 0
success_msg db 'Data written successfully!', 10, 13, 0
buffer db 512 dup(0)
text_to_write db 'Hello!', 0
command_buffer db 256 dup(0)
