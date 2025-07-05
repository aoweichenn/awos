[org 0x1000]
; 魔数 0x55aa，用于判断有无错误
dw 0x55aa

mov si, loading
call print

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

loading:
    db "Loading AWOS...", 10, 13, 0