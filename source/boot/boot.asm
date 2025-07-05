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

; bochs 的魔数断点
xchg bx, bx

mov si, booting
call print

; 阻塞
jmp $

print:
    mov ah,0x0e

.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret


booting:
    db "Booting AWOS...", 10, 13, 0; \n, \r, 0 表示字符串结束


; 填充 0
times 510 - ($ - $$) db 0
; 硬盘校验码，主引导扇区的最后两个字节必须是 0x55 0xaa
db 0x55, 0xaa