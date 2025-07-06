; 指定加载地址为 0x7c00
[org 0x7c00]
; 指定当前为 16 位实模式
bits 16

; ===== 数据段（存放已初始化的全局数据）=====
section .data

; ===== BSS段（预留未初始化内存空间）=====
; 本程序暂时没有未初始化的内存空间
section .bss


; ===== 代码段（程序指令）=====
section .text
global _start
_start:
    ; 初始化段寄存器，在实模式下必须设置，否则在某些虚拟机上会有问题
    ; 将 ax 置 0，将段寄存器都置 0
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    ; 初始化栈顶指针，栈指针指向 0x7c00 （向下增长）
    mov sp, 0x7c00

    ; 设置文本模式并清除屏幕
    mov ax, 3
    int 0x10
    mov si, booting_msg
    call print

    ; 读取的目标内存
    mov edi, 0x1000
    ; 起始扇区
    mov ecx, 2
    ; 扇区数量，从起始扇区 0 读取 1 个扇区的数据到目标内存 0x1000 处
    mov bl, 4
    call read_disk

    cmp word [0x1000], 0x55aa
    jnz error
    jmp 0:0x1002

    jmp $

; 初始化字符串
booting_msg db "Booting AWOS...", 10, 13, 0
booting_error_msg db "Booting Error!!!", 10, 13, 0


; ===== 子函数：打印字符串（SI=字符串地址）=====
error:
    mov si, booting_error_msg
    call print
    hlt
    jmp $

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







; ===== 填充引导扇区结束标记 =====
; 填充 0
times 510 - ($ - $$) db 0
; 硬盘校验码，主引导扇区的最后两个字节必须是 0x55 0xaa
; 小端序：0x55 0xAA
db 0x55, 0xaa