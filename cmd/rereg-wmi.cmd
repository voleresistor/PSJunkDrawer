@echo off

rem disable and stop WMI service
sc config winmgmt start= disabled
net stop winmgmt /y

rem iunno
%systemdrive%

rem Re-register all dlls in wbem
cd %windir%\system32\wbem
for /f %%s in ('dir /b *.dll') do regsvr32 /s %

rem Re-register WMI exes
wmiprvse /regserver
winmgmt /regserver

rem restart WMI service
sc config winmgmt start= auto
net start winmgmt

rem recompile all MOFs
for /f %s in ('dir /s /b *.mof *.mfl') do mofcomp %s