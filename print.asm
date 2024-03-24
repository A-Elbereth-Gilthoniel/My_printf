global print


section .bss
    value_buf db 100 DUP(?)   ; buffer of the value
    number2 db ?                ; the end of the 'value_buf'

section .data
    args Dq 0, 0, 0, 0, 0   ; first five arguments of function
    symb_buf db 0           ; buffer of symbols

    num_argue dq 0          ; number of handled arguments (Except for the first string)
    all_symb db '0123456789ABCDEF'  ; alphabet of digits of any coding

    stack_arg dq 0          ; address in the stack where arguments are located

; При относительной адресации как из jmp-таблицы (в section.data) ссылаться на наши метки (в section.text)

section .rodata

spec_jmp:                       ; table of JMP-functions
        dq 0
        dq binary
        dq char
        dq decimal
        dq 10 DUP(0)
        dq octal
        dq 3 DUP(0)
        dq string_type
        dq 0
        dq unsigned
        dq 2 DUP(0)
        dq hexadecimal
        dq 2 DUP(0)

;============================================
SYS_WRITE equ 0x01
NULL_SYMBOL equ 0x00
MAX_INT_VAL equ 2147483647

%define COUNTER r8
                    ; address of curent symbol in str buffer
;============================================
section .text

;============================================
print:
    mov [rel stack_arg], rsp
    add qword [rel stack_arg], 8

    mov qword [rel args + 32], r9
    mov qword [rel args + 24], r8
    mov qword [rel args + 16], rcx
    mov qword [rel args + 8],  rdx
    mov qword [rel args],      rsi

    mov COUNTER, 0x00                        ; address of curent symbol
    mov byte [rel number2], 0x00
    mov qword [rel num_argue], 0x00

    push rbx
    ;push rbp
    push r10
    push r11
    push r12
    push r13
    push r15
    while_spec_not_found:
        cmp byte [rel rdi], NULL_SYMBOL
        je end_of_the_string
        cmp byte [rel rdi], 0x25        ; symbol '%'
        je specificator
        inc rdi
        inc COUNTER
    jmp while_spec_not_found
        specificator:
        mov qword r11, COUNTER

        mov rsi, rdi
        sub rsi, r11
        call console_output

        mov qword COUNTER, 0x00
        call spec_handler
        add rdi, 2
    jmp while_spec_not_found

    end_of_the_string:
    mov rax, SYS_WRITE
    mov rsi, rdi
    sub rsi, COUNTER
    mov rdi, 1
    mov rdx, COUNTER
    syscall

    pop r15
    pop r13
    pop r12
    pop r11
    pop r10
    ;pop rbp
    pop rbx


    ret
;============================================
; PURPOSE: handling the printf specificator
; ENTRY: rdi - current address in the string
; DESTR: rax, rdx, rsi, r13, r11
;============================================
spec_handler:
    push rdi

    xor rdx, rdx
    mov dl, byte [rel rdi + 1]
    mov r13b, 0x01                   ; type of value: signed
    cmp dl, 0x25                     ; symbol '%'
    je percent

    call get_argument                ; arguments for specificators below
    lea rax, [(rdx - 'a') * 8]
    lea r15, [rel spec_jmp]
    add rax, r15
jmptbl_jmp:    jmp [rax]


    unsigned:
        xor r13b, r13b                   ; type of value: unsigned
        jmp decimal

    percent:
        mov rax, 0x01
        inc rdi
        mov rsi, rdi
        mov rdi, 1
        mov rdx, 1
        syscall
        jmp exit_handler

    decimal:
        mov r11, 10
        call print_num
        jmp exit_handler

    octal:
        mov r11, 8
        call print_num
        jmp exit_handler

    hexadecimal:
        mov r11, 16
        call print_num
        jmp exit_handler

    binary:
        mov r11, 2
        call print_num
        jmp exit_handler

    string_type:
        call calculate_length
        call console_output
        jmp exit_handler

    char:
        mov r11, 0x01
        mov rdx, rsi
        mov byte [rel symb_buf], dl
        lea rsi, [rel symb_buf]
        call console_output

    exit_handler:
        pop rdi
        ret
;=====================================================
; PURPOSE: determining, where the argument is located
; ENTRY:
; OUTPUT: rsi - value of the current argument
;         num_argue
; CHANGED: num_argue, stack_arg
;=====================================================
get_argument:
    mov r10, [rel num_argue]
    cmp r10, 0x04
    ja arg_in_stack

    mov rsi, [rel args + r10 * 8]
    jmp arg_is_taken

    arg_in_stack:
        push rbx
        mov rbx, rsp
        mov rsp, [rel stack_arg]
        pop rsi
        mov [rel stack_arg], rsp
        mov rsp, rbx
        pop rbx
        jmp arg_is_taken

    arg_is_taken:
        inc qword [rel num_argue]
        ret
;============================================================
; PURPOSE: print text to the console
; ENTRY: RSI - address of the text
;        r11 - number of the symbols
; DESTR: r11, rcx
;============================================================
console_output:
    push rax
    push rdi
    push rdx

    mov rax, SYS_WRITE
    mov rdi, 0x01
    mov rdx, r11
    syscall

    pop rdx
    pop rdi
    pop rax
    ret
;============================================================
; PURPOSE: print value
; ENTRY: r13b - type of value (0 - unsigned, 1 - signed)
;        r11 - number of the encoding
;        rsi - value
; DESTR: rsi, rbx, rcx, rdx, rax, r12
;=============================================================
print_num:
    push rdi


    lea r10, [rel all_symb]           ; array of symbols with current encoding
    lea rcx, [rel number2]            ; length of the 'value_buf'
    xor rbx, rbx

    mov rax, rsi                    ; check, value is neg or no
    cmp r13b, 0x01
    jne while_rax_not_null
    cmp rax, MAX_INT_VAL
    jbe while_rax_not_null

    neg eax                         ; eax * (-1)

    while_rax_not_null:
        xor rdx, rdx
        div r11
        add rdx, r10
        dec rcx
        mov byte r12b, [rel rdx]
        mov byte [rel rcx], r12b
        inc rbx
        cmp rax, 0x00
    jne while_rax_not_null

    cmp r13b, 0x01
    jne output_value
    cmp esi, MAX_INT_VAL
    jbe output_value                        ; print '-' before negative value
    dec rcx
    mov byte [rel rcx], 0x2D                 ; symbol '-'
    inc rbx

    output_value:
    mov rax, SYS_WRITE
    mov rsi, rcx
    mov rdi, 1
    mov rdx, rbx
    syscall

    pop rdi
    ret
;=============================================================
; PURPOSE: calculating the length of the string with address in "rsi"
; ENTRY: rsi - address of the string
; CHANGE: r11 - number of symbols in the strings
;=============================================================
calculate_length:
    push rsi
    xor r11, r11

    while_null_not_found:
        cmp byte [rel rsi], NULL_SYMBOL
        je null_is_found
        inc rsi
        inc r11
    jmp while_null_not_found

    null_is_found:
    pop rsi
    ret
;=========================================================

;
;              /\       /\
;             /  \     /  \
;            / |  \___/  | \
;            |             |
;            |  ||     ||  |
;            |      |      |
;             \    | |    /
;              \_________/
;
;=========================================================
