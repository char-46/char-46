@echo off
:: ============================================================
::  cmdrc.cmd - cmd AutoRun 脚本模板
::  由 bootstrap.ps1 复制到 ShimDir (默认 D:\PATH) 并注册到
::  HKCU\Software\Microsoft\Command Processor :: AutoRun
::  (在 "clink inject" 之后链式调用)
:: ============================================================

:: guard against fnm env recursion
if defined FNM_AUTORUN_GUARD goto :eof
set "FNM_AUTORUN_GUARD=AutorunGuard"

:: skip everything in non-interactive mode (cmd /c ...)
echo %cmdcmdline% | find /i "/c" >nul && goto :eof

:: fnm (Node.js version manager)
FOR /f "tokens=*" %%z IN ('fnm env --use-on-cd') DO CALL %%z

:: interactive aliases (full shims live in ShimDir for scripts)
doskey npm=pnpm $*
doskey npx=pnpm dlx $*
