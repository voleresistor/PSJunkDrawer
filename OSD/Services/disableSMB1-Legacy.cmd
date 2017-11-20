@echo off

rem Remove SMB1 (mrxsmb10) from network stack dependencies and disable it
sc.exe config lanmanworkstation depend= bowser/mrxsmb20/nsi
sc.exe config mrxsmb10 start= disabled