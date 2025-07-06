[org 0x1000]
; 魔数 0x55aa，用于判断有无错误
dw 0x55aa

mov si, loading_msg
call print

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
        inc dword [ards_count]

        cmp ebx, 0
        jnz .next

        mov si, detecting_memory_success_msg
        call print

        jmp prepare_protected_mode

prepare_protected_mode:
    cli; 关闭中断

    ; 打开 a20 线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    ; 加载 gdt
    lgdt [gdt_ptr]

    ; 启用保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; 用跳转来刷新缓存, 并启用保护模式
    jmp dword code_selector:protect_mode

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

; 处理加载错误的函数
handle_loading_error:
    mov si, loading_error_msg
    call print
    ; 让 CPU 停止
    hlt
    ; 阻塞
    jmp $


loading_msg:
    db "Loading AWOS...", 10, 13, 0
loading_error_msg:
    db "Loading Error!!!", 10, 13, 0
detecting_memory_success_msg:
    db "Detecting Memory Success...", 10, 13, 0



[bits 32]
protect_mode:
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x10000; 修改栈顶

    ; 读取的目标内存
    mov edi, 0x10000
    ; 起始扇区
    mov ecx, 10
    ; 扇区数量，从起始扇区 0 读取 1 个扇区的数据到目标内存 0x1000 处
    mov bl, 200
    call read_disk

    xchg bx, bx
    jmp dword code_selector:0x10000
    ; 表示出错
    ud2

read_disk:
    ; 设置读写扇区的数量
    ; dx => 0x1f2
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    ; dx => 0x1f3
    inc dx
    ; 起始扇区的前 8 位，
    mov al, cl
    out dx, al

    ; dx => 0x1f4
    inc dx
    shr ecx, 8
    ; 起始扇区的中 8 位，
    mov al, cl
    out dx, al

    ; dx => 0x1f5
    inc dx
    shr ecx, 8
    ; 起始扇区的高 8 位，
    mov al, cl
    out dx, al

    ; dx => 0x1f6
    inc dx
    shr ecx, 8
    ; 将 cl 高 4 位置为 0
    and cl, 0b1111
    ; 主盘 --- LBA 模式
    mov al, 0b1110_0000
    or al, cl
    out dx, al

    ; dx => 0x1f7
    inc dx
    ; 读硬盘
    mov al, 0x20
    out dx, al

    ; 清空 ecx, 性能更好
    xor ecx, ecx
    mov cl, bl

    .read:
        ; 读取时会修改 cx，所以需要入栈保存 cx
        push cx
        ; 等待数据读取完毕
        call .waits
        ; 读取一个扇区
        call .reads
        ; 恢复 cx
        pop cx
        loop .read
    ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            ; 直接跳转到下一行，消耗时间等待硬盘准备好
            jmp $ + 2
            jmp $ + 2
            jmp $ + 2
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret

    .reads:
        mov dx, 0x1f0
        ; 一个扇区 256 字节
        mov cx, 256
        .readw:
            in ax, dx
            ; 直接跳转到下一行，消耗时间等待硬盘准备好
            jmp $ + 2
            jmp $ + 2
            jmp $ + 2
            mov [edi], ax
            add edi, 2
            loop .readw
        ret


code_selector equ (1 << 3)
data_selector equ (2 << 3)

memory_base equ 0; 内存开始的位置：基地址
; 内存界限 (4G / 4k) -1
memory_limit equ (((1024*1024*1024*4) / (1024*4)) - 1)


gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base
gdt_base:
    dd 0, 0; NULL 描述符
gdt_code:
    ; 段界限的 0 ~ 15 位
    dw memory_limit & 0xffff
    ; 基地址 0 ~ 15
    dw memory_base & 0xffff
    ; 基地址的 16 ~ 23 位
    db (memory_base >> 16) & 0xff
    ; 存在 - dlp 0 - S - 代码 - 非依从 - 可读 - 没有被访问过
    db 0b_1_00_1_1_0_1_0
    ; 4k - 32 位 - 不是 64 位 - 段界限 16 ~ 19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff;
gdt_data:
    ; 段界限的 0 ~ 15 位
    dw memory_limit & 0xffff
    ; 基地址 0 ~ 15
    dw memory_base & 0xffff
    ; 基地址的 16 ~ 23 位
    db (memory_base >> 16) & 0xff
    ; 存在 - dlp 0 - S - 数据 - 向上 - 可写 - 没有被访问过
    db 0b_1_00_1_0_0_1_0
    ; 4k - 32 位 - 不是 64 位 - 段界限 16 ~ 19
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf
    db (memory_base >> 24) & 0xff;
gdt_end:

ards_count:
    dd 0
ards_buffer:
