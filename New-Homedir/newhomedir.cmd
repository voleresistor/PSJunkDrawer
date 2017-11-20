@echo off

powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -NonInteractive -File new-homedir.ps1
set exitCode=%errorLevel%

echo Exiting %exitCode%
exit /B %exitCode%