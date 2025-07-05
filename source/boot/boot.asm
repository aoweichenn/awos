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

    ; Bochs 调试断点魔数（magic breakpoint）
    xchg bx, bx
    ; 调用打印函数
    mov si, booting_msg
    call print

    ; 阻塞
    jmp $

; 初始化字符串
booting_msg db "Booting AWOS...", 10, 13, 0

; ===== 子函数：打印字符串（SI=字符串地址）=====
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

; ===== 填充引导扇区结束标记 =====
; 填充 0
times 510 - ($ - $$) db 0
; 硬盘校验码，主引导扇区的最后两个字节必须是 0x55 0xaa
; 小端序：0x55 0xAA
db 0x55, 0xaa