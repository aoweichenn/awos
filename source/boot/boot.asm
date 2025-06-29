[org 0x7c00]

; 设置屏幕模式为文本模式，清除屏幕
mov ax, 3
int 0x10

; 初始化段寄存器（不初始化的话某些虚拟机上会有问题）
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

; 0xb800 是文本显示器的内存区域
mov ax, 0xb800
mov ds, ax
mov byte [0], 'H'

; 阻塞
jmp $

; 填充 0
times 510 - ($ - $$) db 0
; 硬盘校验码，主引导扇区的最后两个字节必须是 0x55 0xaa
db 0x55, 0xaa