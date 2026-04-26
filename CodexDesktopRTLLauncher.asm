option casemap:none

GetEnvironmentVariableA PROTO :QWORD,:QWORD,:DWORD
CreateDirectoryA PROTO :QWORD,:QWORD
FindResourceA PROTO :QWORD,:QWORD,:QWORD
LoadResource PROTO :QWORD,:QWORD
LockResource PROTO :QWORD
SizeofResource PROTO :QWORD,:QWORD
CreateFileA PROTO :QWORD,:DWORD,:DWORD,:QWORD,:DWORD,:DWORD,:QWORD
WriteFile PROTO :QWORD,:QWORD,:DWORD,:QWORD,:QWORD
CloseHandle PROTO :QWORD
GetFileAttributesA PROTO :QWORD
CreateProcessA PROTO :QWORD,:QWORD,:QWORD,:QWORD,:DWORD,:DWORD,:QWORD,:QWORD,:QWORD,:QWORD
WaitForSingleObject PROTO :QWORD,:DWORD
GetExitCodeProcess PROTO :QWORD,:QWORD
ExitProcess PROTO :DWORD
MessageBoxA PROTO :QWORD,:QWORD,:QWORD,:DWORD

includelib kernel32.lib
includelib user32.lib

CALL1 MACRO fn:req, a1:req
    mov rcx, a1
    sub rsp, 40
    call fn
    add rsp, 40
ENDM

CALL2 MACRO fn:req, a1:req, a2:req
    mov rcx, a1
    mov rdx, a2
    sub rsp, 40
    call fn
    add rsp, 40
ENDM

CALL3 MACRO fn:req, a1:req, a2:req, a3:req
    mov rcx, a1
    mov rdx, a2
    mov r8, a3
    sub rsp, 40
    call fn
    add rsp, 40
ENDM

CALL4 MACRO fn:req, a1:req, a2:req, a3:req, a4:req
    mov rcx, a1
    mov rdx, a2
    mov r8, a3
    mov r9, a4
    sub rsp, 40
    call fn
    add rsp, 40
ENDM

CALL5 MACRO fn:req, a1:req, a2:req, a3:req, a4:req, a5:req
    mov rcx, a1
    mov rdx, a2
    mov r8, a3
    mov r9, a4
    sub rsp, 56
    mov rax, a5
    mov QWORD PTR [rsp+32], rax
    call fn
    add rsp, 56
ENDM

CALL7 MACRO fn:req, a1:req, a2:req, a3:req, a4:req, a5:req, a6:req, a7:req
    mov rcx, a1
    mov rdx, a2
    mov r8, a3
    mov r9, a4
    sub rsp, 72
    mov rax, a5
    mov QWORD PTR [rsp+32], rax
    mov rax, a6
    mov QWORD PTR [rsp+40], rax
    mov rax, a7
    mov QWORD PTR [rsp+48], rax
    call fn
    add rsp, 72
ENDM

CALL10 MACRO fn:req, a1:req, a2:req, a3:req, a4:req, a5:req, a6:req, a7:req, a8:req, a9:req, a10:req
    mov rcx, a1
    mov rdx, a2
    mov r8, a3
    mov r9, a4
    sub rsp, 88
    mov rax, a5
    mov QWORD PTR [rsp+32], rax
    mov rax, a6
    mov QWORD PTR [rsp+40], rax
    mov rax, a7
    mov QWORD PTR [rsp+48], rax
    mov rax, a8
    mov QWORD PTR [rsp+56], rax
    mov rax, a9
    mov QWORD PTR [rsp+64], rax
    mov rax, a10
    mov QWORD PTR [rsp+72], rax
    call fn
    add rsp, 88
ENDM

RT_RCDATA equ 10
GENERIC_WRITE equ 40000000h
CREATE_ALWAYS equ 2
FILE_ATTRIBUTE_NORMAL equ 80h
INVALID_FILE_ATTRIBUTES equ 0FFFFFFFFh
CREATE_NO_WINDOW equ 08000000h
INFINITE equ 0FFFFFFFFh
STARTF_USESHOWWINDOW equ 1

.data
titleText BYTE "Codex Desktop RTL",0
noEnvText BYTE "Could not resolve LOCALAPPDATA or USERPROFILE.",0
extractText BYTE "Failed to extract embedded launcher files.",0
launchText BYTE "Failed to start PowerShell runner.",0

localAppDataName BYTE "LOCALAPPDATA",0
userProfileName BYTE "USERPROFILE",0
appDataLocalSuffix BYTE "\AppData\Local",0
appRootSuffix BYTE "\CodexDesktopRTL",0
payloadSuffix BYTE "\Payload",0

portableSuffix BYTE "\CodexDesktopRTL-Portable.ps1",0
asarPatchSuffix BYTE "\Patch-Codex-Asar-RTL.ps1",0
integrityPatchSuffix BYTE "\Patch-Codex-Exe-AsarIntegrity.ps1",0
iconSuffix BYTE "\CodexDesktopRTL.ico",0

pwshPath BYTE "C:\Program Files\PowerShell\7\pwsh.exe",0
cmdPrefixPwsh BYTE '"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "',0
cmdPrefixWinPs BYTE 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "',0
quoteSuffix BYTE '"',0

.data?
rootBuf BYTE 4096 dup(?)
appDir BYTE 4096 dup(?)
payloadDir BYTE 4096 dup(?)
pathBuf BYTE 4096 dup(?)
cmdBuf BYTE 8192 dup(?)
siBuf BYTE 104 dup(?)
piBuf BYTE 24 dup(?)
exitCode QWORD ?
written QWORD ?
hInfo QWORD ?
hData QWORD ?
pData QWORD ?
dataSize QWORD ?
hFile QWORD ?
writeOk QWORD ?
resIdTmp QWORD ?
fileNameTmp QWORD ?
suffixTmp QWORD ?

.code

CopyString PROC USES rsi rdi
    mov rdi, rcx
    mov rsi, rdx
copy_loop:
    mov al, BYTE PTR [rsi]
    mov BYTE PTR [rdi], al
    inc rsi
    inc rdi
    test al, al
    jne copy_loop
    ret
CopyString ENDP

AppendString PROC USES rsi rdi
    mov rdi, rcx
find_end:
    cmp BYTE PTR [rdi], 0
    je append_start
    inc rdi
    jmp find_end
append_start:
    mov rsi, rdx
append_loop:
    mov al, BYTE PTR [rsi]
    mov BYTE PTR [rdi], al
    inc rsi
    inc rdi
    test al, al
    jne append_loop
    ret
AppendString ENDP

WriteResource:
    mov resIdTmp, rcx
    mov fileNameTmp, rdx

    CALL3 FindResourceA, 0, resIdTmp, RT_RCDATA
    test rax, rax
    jz wr_fail
    mov hInfo, rax

    CALL2 LoadResource, 0, hInfo
    test rax, rax
    jz wr_fail
    mov hData, rax

    CALL1 LockResource, hData
    test rax, rax
    jz wr_fail
    mov pData, rax

    CALL2 SizeofResource, 0, hInfo
    test eax, eax
    jz wr_fail
    mov dataSize, rax

    CALL7 CreateFileA, fileNameTmp, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp rax, -1
    je wr_fail
    mov hFile, rax

    CALL5 WriteFile, hFile, pData, dataSize, OFFSET written, 0
    mov writeOk, rax
    CALL1 CloseHandle, hFile
    cmp writeOk, 0
    jz wr_fail

    mov eax, 1
    ret
wr_fail:
    xor eax, eax
    ret
ExtractOne:
    mov resIdTmp, rcx
    mov suffixTmp, rdx

    CALL2 CopyString, OFFSET pathBuf, OFFSET payloadDir
    CALL2 AppendString, OFFSET pathBuf, suffixTmp
    CALL2 WriteResource, resIdTmp, OFFSET pathBuf
    ret

main PROC
    CALL3 GetEnvironmentVariableA, OFFSET localAppDataName, OFFSET rootBuf, 4096
    cmp eax, 0
    jne have_root

    CALL3 GetEnvironmentVariableA, OFFSET userProfileName, OFFSET rootBuf, 4096
    cmp eax, 0
    jne have_user_profile

    CALL4 MessageBoxA, 0, OFFSET noEnvText, OFFSET titleText, 10h
    CALL1 ExitProcess, 1

have_user_profile:
    CALL2 AppendString, OFFSET rootBuf, OFFSET appDataLocalSuffix

have_root:
    CALL2 CopyString, OFFSET appDir, OFFSET rootBuf
    CALL2 AppendString, OFFSET appDir, OFFSET appRootSuffix
    CALL2 CreateDirectoryA, OFFSET appDir, 0

    CALL2 CopyString, OFFSET payloadDir, OFFSET appDir
    CALL2 AppendString, OFFSET payloadDir, OFFSET payloadSuffix
    CALL2 CreateDirectoryA, OFFSET payloadDir, 0

    CALL2 ExtractOne, 101, OFFSET portableSuffix
    cmp eax, 1
    jne extract_failed
    CALL2 ExtractOne, 102, OFFSET asarPatchSuffix
    cmp eax, 1
    jne extract_failed
    CALL2 ExtractOne, 103, OFFSET integrityPatchSuffix
    cmp eax, 1
    jne extract_failed
    CALL2 ExtractOne, 104, OFFSET iconSuffix
    cmp eax, 1
    jne extract_failed

    CALL1 GetFileAttributesA, OFFSET pwshPath
    cmp eax, INVALID_FILE_ATTRIBUTES
    je use_windows_powershell
    CALL2 CopyString, OFFSET cmdBuf, OFFSET cmdPrefixPwsh
    jmp build_command

use_windows_powershell:
    CALL2 CopyString, OFFSET cmdBuf, OFFSET cmdPrefixWinPs

build_command:
    CALL2 AppendString, OFFSET cmdBuf, OFFSET payloadDir
    CALL2 AppendString, OFFSET cmdBuf, OFFSET portableSuffix
    CALL2 AppendString, OFFSET cmdBuf, OFFSET quoteSuffix

    mov DWORD PTR [siBuf], 104
    mov DWORD PTR [siBuf+60], STARTF_USESHOWWINDOW
    mov WORD PTR [siBuf+64], 0

    CALL10 CreateProcessA, 0, OFFSET cmdBuf, 0, 0, 0, CREATE_NO_WINDOW, 0, OFFSET payloadDir, OFFSET siBuf, OFFSET piBuf
    test eax, eax
    jz launch_failed

    CALL2 WaitForSingleObject, QWORD PTR [piBuf], INFINITE
    CALL2 GetExitCodeProcess, QWORD PTR [piBuf], OFFSET exitCode
    CALL1 CloseHandle, QWORD PTR [piBuf+8]
    CALL1 CloseHandle, QWORD PTR [piBuf]
    CALL1 ExitProcess, exitCode

extract_failed:
    CALL4 MessageBoxA, 0, OFFSET extractText, OFFSET titleText, 10h
    CALL1 ExitProcess, 1

launch_failed:
    CALL4 MessageBoxA, 0, OFFSET launchText, OFFSET titleText, 10h
    CALL1 ExitProcess, 1
main ENDP

END
