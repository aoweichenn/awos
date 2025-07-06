[org 0x1000]
; 魔数 0x55aa，用于判断有无错误
dw 0x55aa

section .text

mov si, loading_msg
call print
call detect_memory

; 阻塞
jmp $





loading_msg:
    db "Loading AWOS...", 10, 13, 0
loading_error_msg:
    db "Loading Error!!!", 10, 13, 0
detecting_memory_success_msg:
    db "Detecting Memory Success...", 10, 13, 0

; ====== 子函数模块 ======
; 处理加载错误的函数
handle_loading_error:
    mov si, loading_error_msg
    call print
    ; 让 CPU 停止
    hlt
    ; 阻塞
    jmp $

; 打印函数，将 si 中的信息打印出来
print:
    mov ah, 0x0e
.loop:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .loop
.done:
    ret

; 内存检测
detect_memory:
    xor ebx, ebx

    ; es:di 结构体缓存位置
    xor ax, ax
    mov es, ax
    mov edi,  ards_buffer
    ; 固定签名
    mov edx, 0x534d4150

    .next:
        ; 子功能号
        mov eax, 0xe820
        ; ards 结构的大小
        mov ecx, 20
        ; 系统调用 0x15
        int 0x15

        ; 如果 CF 置位就表示出错
        jc handle_loading_error
        ; 将缓存指针指向下一个结构体
        add di, cx
        ; 将结构体数量 + 1
        inc word [ards_count]

        cmp ebx, 0
        jnz .next

        mov si, detecting_memory_success_msg
        call print

        xchg bx, bx
        ; 结构体数量
        mov cx, [ards_count]
        ; 结构体指针
        mov si, 0

        .show:
            mov eax, [si + ards_buffer]
            mov ebx, [si + ards_buffer + 8]
            mov edx, [si + ards_buffer + 16]
            add si, 20
            xchg bx, bx
            loop .show


ards_count:
    dw 0
ards_buffer:
