' *********************************************************************************
' ** Script Name: IT_OSD_VBS_CreateTSvariable
' ** Created on: 16.12.2013
' ** Author: Jyri Lehtonen / http://it.peikkoluola.net
' **
' ** Purpose: You have information that you need to write to an AD object Attribute
' ** Usage: IT_OSD_VBS_CreateTSvariable.vbs (no parameters exist)
' **
' ** License: This program is free software: you can redistribute it and/or modify
' ** it under the terms of the GNU General Public License as published by
' ** the Free Software Foundation, either version 3 of the License, or
' ** (at your option) any later version.
' **
' ** This program is distributed in the hope that it will be useful,
' ** but WITHOUT ANY WARRANTY; without even the implied warranty of
' ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
' ** GNU General Public License for more details.
' ** 
' ** History: 
' ** 1.0 / Jyri Lehtonen / 16.12.2013 / Initial version.
' *********************************************************************************
 ' Some variables
 Option Explicit
 Dim objWMIService, objItem, colItems, strComputer, intDrive, tsenv
 strComputer = "."
 intDrive = 0
 
 ' WMI connection and query execution
 ' On Error Resume Next
 set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
 set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Volume WHERE Label = 'OSDisk'")
 
' The task sequence must be running for this script to work
' Create the required Object for Task Sequence manipulating
set tsenv = CreateObject("Microsoft.SMS.TSEnvironment")
 
 ' Test loop to get data from WMI query
 for Each objItem in colItems
 tsenv("OSDisk") = objItem.DriveLetter
 'Wscript.Echo "Disk Label: " & objItem.Label & vbCrLf & "Disk Letter: " & objItem.DriveLetter 
 Next
 
 Wscript.Quit