;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Core.nsh
;   This file provides core functionality and instructions for use with the other segments.
; 

Var WrapperFile
;${If} ${FilesExists}, ${If} ${DirExists}.
!macro _FilesExists _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"
	StrCmp `${_b}` `` +4 0 ;if path is not blank, continue to next check
	IfFileExists `${_b}` `0` +3 ;if path exists, continue to next check (IfFileExists returns true if this is a directory)
	IfFileExists `${_b}\*.*` +2 0 ;if path is not a directory, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1" ;file exists
	;now we have a definitive value - the file exists or it does not
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!define FilesExists `"" FilesExists`
!macro _DirExists _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"	
	StrCmp `${_b}` `` +3 0 ;if path is not blank, continue to next check
	IfFileExists `${_b}\*.*` 0 +2 ;if directory exists, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1"
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!define DirExists `"" DirExists`
!define xml::Unload `!insertmacro xml::Unload`
!macro xml::Unload
	xml::_Unload
!macroend
!ifdef Get_Drives
	Function Get::Drives
		!macro _Get::Drives _DRV _FUNC
			Push $0
			Push `${_DRV}`
			GetFunctionAddress $0 `${_FUNC}`
			Push `$0`
			Call Get::Drives
			Pop $0
		!macroend
		!define Get::Drives `!insertmacro _Get::Drives`
		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		Push $5
		Push $6
		Push $8
		Push $9
		System::Alloc /NOUNLOAD 1024
		Pop $2
		System::Call /NOUNLOAD 'kernel32::GetLogicalDriveStringsA(i,i) i(1024, r2)'
		StrCmp $0 ALL drivestring
		StrCmp $0 '' 0 typeset
		StrCpy $0 ALL
		Goto drivestring
		typeset:
		StrCpy $6 -1
		IntOp $6 $6 + 1
		StrCpy $8 $0 1 $6
		StrCmp $8$0 '' enumex
		StrCmp $8 '' +2
		StrCmp $8 '+' 0 -4
		StrCpy $8 $0 $6
		IntOp $6 $6 + 1
		StrCpy $0 $0 '' $6
		StrCmp $8 'FDD' 0 +3
		StrCpy $6 2
		Goto drivestring
		StrCmp $8 'HDD' 0 +3
		StrCpy $6 3
		Goto drivestring
		StrCmp $8 'NET' 0 +3
		StrCpy $6 4
		Goto drivestring
		StrCmp $8 'CDROM' 0 +3
		StrCpy $6 5
		Goto drivestring
		StrCmp $8 'RAM' 0 typeset
		StrCpy $6 6
		drivestring:
		StrCpy $3 $2
		enumok:
		System::Call /NOUNLOAD 'kernel32::lstrlenA(t) i(i r3) .r4'
		StrCmp $4$0 '0ALL' enumex
		StrCmp $4 0 typeset
		System::Call /NOUNLOAD 'kernel32::GetDriveTypeA(t) i(i r3) .r5'
		StrCmp $0 ALL +2
		StrCmp $5 $6 letter enumnext
		StrCmp $5 2 0 +3
		StrCpy $8 FDD
		Goto letter
		StrCmp $5 3 0 +3
		StrCpy $8 HDD
		Goto letter
		StrCmp $5 4 0 +3
		StrCpy $8 NET
		Goto letter
		StrCmp $5 5 0 +3
		StrCpy $8 CDROM
		Goto letter
		StrCmp $5 6 0 enumex
		StrCpy $8 RAM
		letter:
		System::Call /NOUNLOAD '*$3(&t1024 .r9)'
		Push $0
		Push $1
		Push $2
		Push $3
		Push $4
		Push $5
		Push $6
		Push $8
		Call $1
		Pop $9
		Pop $8
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Pop $0
		StrCmp $9 'StopGetDrives' enumex
		enumnext:
		IntOp $3 $3 + $4
		IntOp $3 $3 + 1
		Goto enumok
		enumex:
		System::Free $2
		Pop $9
		Pop $8
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Pop $0
	FunctionEnd
!endif
!ifdef CompareVersions
	Function Compare
		!define Compare `!insertmacro _Compare`
		!macro _Compare _VER1 _VER2 _RESULT
			Push `${_VER1}`
			Push `${_VER2}`
			Call Compare
			Pop ${_RESULT}
		!macroend
		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		Push $5
		Push $6
		Push $7
		StrCpy $2 -1
		IntOp $2 $2 + 1
		StrCpy $3 $0 1 $2
		StrCmp $3 '' +2
		StrCmp $3 '.' 0 -3
		StrCpy $4 $0 $2
		IntOp $2 $2 + 1
		StrCpy $0 $0 '' $2
		StrCpy $2 -1
		IntOp $2 $2 + 1
		StrCpy $3 $1 1 $2
		StrCmp $3 '' +2
		StrCmp $3 '.' 0 -3
		StrCpy $5 $1 $2
		IntOp $2 $2 + 1
		StrCpy $1 $1 '' $2
		StrCmp $4$5 '' +20
		StrCpy $6 -1
		IntOp $6 $6 + 1
		StrCpy $3 $4 1 $6
		StrCmp $3 '0' -2
		StrCmp $3 '' 0 +2
		StrCpy $4 0
		StrCpy $7 -1
		IntOp $7 $7 + 1
		StrCpy $3 $5 1 $7
		StrCmp $3 '0' -2
		StrCmp $3 '' 0 +2
		StrCpy $5 0
		StrCmp $4 0 0 +2
		StrCmp $5 0 -30 +10
		StrCmp $5 0 +7
		IntCmp $6 $7 0 +6 +8
		StrCpy $4 '1$4'
		StrCpy $5 '1$5'
		IntCmp $4 $5 -35 +5 +3
		StrCpy $0 0
		Goto end
		StrCpy $0 1
		Goto end
		StrCpy $0 2
		end:
		Pop $7
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
!endif
Function Get.Parent
	!macro Get.Parent _PATH _RET
		Push `${_PATH}`
		Call Get.Parent
		Pop ${_RET}
	!macroend
	!define Get.Parent "!insertmacro _Get.Parent"
	Exch $0
	Push $1
	Push $2
	StrCpy $2 $0 1 -1
	StrCmp $2 '\' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $1 0
	IntOp $1 $1 - 1
	StrCpy $2 $0 1 $1
	StrCmp $2 '\' +2
	StrCmp $2 '' 0 -3
	StrCpy $0 $0 $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!ifdef ConFunc
	Function WriteS
		!macro _WriteS _FILE _ENTRY _VALUE _RESULT
			Push `${_FILE}`
			Push `${_ENTRY}`
			Push `${_VALUE}`
			Call WriteS
			Pop ${_RESULT}
		!macroend
		!define WriteS `!insertmacro _WriteS`
		!insertmacro TextFunc_BOM
		Exch $2
		Exch
		Exch $1
		Exch
		Exch 2
		Exch $0
		Exch 2
		Push $3
		Push $4
		Push $5
		Push $6
		Push $7
		ClearErrors
		IfFileExists $0 0 +81
		FileOpen $3 $0 a
		IfErrors +79
		FileReadWord $3 $7
		IntCmp $7 0xFEFF +4
		FileSeek $3 0 SET
		StrCpy $TextFunc_BOM 0
		Goto +2
		StrCpy $TextFunc_BOM FFFE
		StrLen $0 $1
		StrCmpS $0 0 0 +3
		StrCpy $0 ''
		Goto +67
		IntCmp $7 0xFEFF +3
		FileRead $3 $4
		Goto +2
		FileReadUTF16LE $3 $4
		IfErrors +41
		StrCpy $5 $4 $0
		StrCmpS $5 $1 0 -6
		StrCpy $5 0
		IntOp $5 $5 - 1
		StrCpy $6 $4 1 $5
		StrCmpS $6 '$\r' -2
		StrCmpS $6 '$\n' -3
		StrCpy $6 $4
		StrCmpS $5 -1 +3
		IntOp $5 $5 + 1
		StrCpy $6 $4 $5
		StrCmpS $2 '' +4
		StrCmpS $6 '$1$2' 0 +3
		StrCpy $0 SAME
		Goto +47
		FileSeek $3 0 CUR $5
		StrLen $4 $4
		IntCmp $7 0xFEFF 0 +2 +2
		IntOp $4 $4 * 2
		IntOp $4 $5 - $4
		FileSeek $3 0 END $6
		IntOp $6 $6 - $5
		System::Alloc $6
		Pop $0
		FileSeek $3 $5 SET
		System::Call 'kernel32::ReadFile(i r3, i r0, i r6, t.,)'
		FileSeek $3 $4 SET
		StrCmpS $2 '' +5
		IntCmp $7 0xFEFF +3
		FileWrite $3 '$1$2$\r$\n'
		Goto +2
		FileWriteUTF16LE $3 '$1$2$\r$\n'
		System::Call 'kernel32::WriteFile(i r3, i r0, i r6, t.,)'
		System::Call 'kernel32::SetEndOfFile(i r3)'
		System::Free $0
		StrCmpS $2 '' +3
		StrCpy $0 CHANGED
		Goto +24
		StrCpy $0 DELETED
		Goto +22
		StrCmpS $2 '' 0 +3
		StrCpy $0 SAME
		Goto +19
		IntCmp $7 0xFEFF +4
		FileSeek $3 -1 END
		FileRead $3 $4
		Goto +3
		FileSeek $3 -2 END
		FileReadUTF16LE $3 $4
		IfErrors +4
		IntCmp $7 0xFEFF +6
		StrCmpS $4 '$\r' +3
		StrCmpS $4 '$\n' +2
		FileWrite $3 '$\r$\n'
		FileWrite $3 '$1$2$\r$\n'
		Goto +5
		StrCmpS $4 '$\r' +3
		StrCmpS $4 '$\n' +2
		FileWriteUTF16LE $3 '$\r$\n'
		FileWriteUTF16LE $3 '$1$2$\r$\n'
		StrCpy $0 ADDED
		FileClose $3
		Goto +3
		SetErrors
		StrCpy $0 ''
		Pop $7
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
	Function ReadS
		!macro _ReadS _FILE _ENTRY _RESULT
			Push `${_FILE}`
			Push `${_ENTRY}`
			Call ReadS
			Pop ${_RESULT}
		!macroend
		!define ReadS `!insertmacro _ReadS`
		!insertmacro TextFunc_BOM
		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		Push $5
		ClearErrors
		FileOpen $2 $0 r
		IfErrors +22
		FileReadWord $2 $5
		IntCmp $5 0xFEFF +4
		FileSeek $2 0 SET
		StrCpy $TextFunc_BOM 0
		Goto +2
		StrCpy $TextFunc_BOM FFFE
		StrLen $0 $1
		StrCmpS $0 0 +14
		IntCmp $5 0xFEFF +3
		FileRead $2 $3
		Goto +2
		FileReadUTF16LE $2 $3
		IfErrors +9
		StrCpy $4 $3 $0
		StrCmpS $4 $1 0 -6
		StrCpy $0 $3 '' $0
		StrCpy $4 $0 1 -1
		StrCmpS $4 '$\r' +2
		StrCmpS $4 '$\n' 0 +5
		StrCpy $0 $0 -1
		Goto -4
		SetErrors
		StrCpy $0 ''
		FileClose $2
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
	Function Write
		!define Write `!insertmacro _Write`
		!macro _Write _FILE _ENTRY _VALUE _RESULT
			Push `${_FILE}`
			Push `${_ENTRY}`
			Push `${_VALUE}`
			Call Write
			Pop ${_RESULT}
		!macroend
		Exch $2
		Exch
		Exch $1
		Exch
		Exch 2
		Exch $0
		Exch 2
		Push $3
		Push $4
		Push $5
		Push $6
		ClearErrors
		IfFileExists $0 0 error
		FileOpen $3 $0 a
		IfErrors error
		StrLen $0 $1
		StrCmp $0 0 0 readnext
		StrCpy $0 ''
		Goto close
		readnext:
		FileRead $3 $4
		IfErrors add
		StrCpy $5 $4 $0
		StrCmp $5 $1 0 readnext
		StrCpy $5 0
		IntOp $5 $5 - 1
		StrCpy $6 $4 1 $5
		StrCmp $6 '$\r' -2
		StrCmp $6 '$\n' -3
		StrCpy $6 $4
		StrCmp $5 -1 +3
		IntOp $5 $5 + 1
		StrCpy $6 $4 $5
		StrCmp $2 '' change
		StrCmp $6 '$1$2' 0 change
		StrCpy $0 SAME
		Goto close
		change:
		FileSeek $3 0 CUR $5
		StrLen $4 $4
		IntOp $4 $5 - $4
		FileSeek $3 0 END $6
		IntOp $6 $6 - $5
		System::Alloc /NOUNLOAD $6
		Pop $0
		FileSeek $3 $5 SET
		System::Call /NOUNLOAD 'kernel32::ReadFile(i r3, i r0, i $6, t.,)'
		FileSeek $3 $4 SET
		StrCmp $2 '' +2
		FileWrite $3 '$1$2$\r$\n'
		System::Call /NOUNLOAD 'kernel32::WriteFile(i r3, i r0, i $6, t.,)'
		System::Call /NOUNLOAD 'kernel32::SetEndOfFile(i r3)'
		System::Free $0
		StrCmp $2 '' +3
		StrCpy $0 CHANGED
		Goto close
		StrCpy $0 DELETED
		Goto close
		add:
		StrCmp $2 '' 0 +3
		StrCpy $0 SAME
		Goto close
		FileSeek $3 -1 END
		FileRead $3 $4
		IfErrors +4
		StrCmp $4 '$\r' +3
		StrCmp $4 '$\n' +2
		FileWrite $3 '$\r$\n'
		FileWrite $3 '$1$2$\r$\n'
		StrCpy $0 ADDED
		close:
		FileClose $3
		Goto end
		error:
		SetErrors
		StrCpy $0 ''
		end:
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
	Function Read
		!define Read `!insertmacro _Read`
		!macro _Read _FILE _ENTRY _RESULT
			Push `${_FILE}`
			Push `${_ENTRY}`
			Call Read
			Pop ${_RESULT}
		!macroend
		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		ClearErrors
		FileOpen $2 $0 r
		IfErrors error
		StrLen $0 $1
		StrCmp $0 0 error
		readnext:
		FileRead $2 $3
		IfErrors error
		StrCpy $4 $3 $0
		StrCmp $4 $1 0 readnext
		StrCpy $0 $3 '' $0
		StrCpy $4 $0 1 -1
		StrCmp $4 '$\r' +2
		StrCmp $4 '$\n' 0 close
		StrCpy $0 $0 -1
		Goto -4
		error:
		SetErrors
		StrCpy $0 ''
		close:
		FileClose $2
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
!endif
!ifdef Include_ReadLine
	Function ReadLine
		!macro _ReadLine _FILE _NUMBER _RESULT
			Push `${_FILE}`
			Push `${_NUMBER}`
			Call ReadLine
			Pop ${_RESULT}
		!macroend
		!define ReadLine `!insertmacro _ReadLine`
		!insertmacro TextFunc_BOM
		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		Push $5
		ClearErrors
		IfFileExists $0 0 TextFunc_LineRead_error
		IntOp $1 $1 + 0
		IntCmp $1 0 TextFunc_LineRead_error 0 TextFunc_LineRead_plus
		StrCpy $4 0
		FileOpen $2 $0 r
		IfErrors TextFunc_LineRead_error
		FileReadWord $2 $5
		IntCmp $5 0xFEFF +6
		FileSeek $2 0 SET
		StrCpy $TextFunc_BOM 0
		IntCmp $5 0xFEFF +3		
		FileRead $2 $3
		Goto +3
		StrCpy $TextFunc_BOM FFFE
		FileReadUTF16LE $2 $3
		IfErrors +3
		IntOp $4 $4 + 1
		Goto -7
		FileClose $2
		IntOp $1 $4 + $1
		IntOp $1 $1 + 1
		IntCmp $1 0 TextFunc_LineRead_error TextFunc_LineRead_error
		TextFunc_LineRead_plus:
		FileOpen $2 $0 r
		IfErrors TextFunc_LineRead_error
		StrCpy $3 0
		IntOp $3 $3 + 1
		IntCmp $5 0xFEFF +3		
		FileRead $2 $0
		Goto +2
		FileReadUTF16LE $2 $0
		IfErrors +4
		StrCmp $3 $1 0 -6
		FileClose $2
		Goto TextFunc_LineRead_end
		FileClose $2
		TextFunc_LineRead_error:
		SetErrors
		StrCpy $0 ''
		TextFunc_LineRead_end:
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
!endif
!ifdef Include_WordRep
	Function WordRepS
		!macro _WordRepS _STRING _WORD1 _WORD2 _NUMBER _RESULT
			Push `${_STRING}`
			Push `${_WORD1}`
			Push `${_WORD2}`
			Push `${_NUMBER}`
			Call WordRepS
			Pop ${_RESULT}
		!macroend
		!define WordRepS `!insertmacro _WordRepS`
		Exch $2
		Exch
		Exch $1
		Exch
		Exch 2
		Exch $0
		Exch 2
		Exch 3
		Exch $R0
		Exch 3
		Push $3
		Push $4
		Push $5
		Push $6
		Push $7
		Push $8
		Push $9
		Push $R1
		ClearErrors
		StrCpy $R1 $R0
		StrCpy $9 ""
		StrCpy $3 $2 1
		StrCpy $2 $2 "" 1
		StrCmp $3 E 0 +3
		StrCpy $9 E
		Goto -4
		StrCpy $4 $2 1 -1
		StrCpy $5 ""
		StrCpy $6 ""
		StrLen $7 $0
		StrCmpS $7 0 ERROR1
		StrCmpS $R0 "" ERROR1
		StrCmpS $3 { BEGIN
		StrCmpS $3 } END CHK
		BEGIN:
		StrCpy $8 $R0 $7
		StrCmpS $8 $0 0 +4
		StrCpy $R0 $R0 "" $7
		StrCpy $5 "$5$1"
		Goto -4
		StrCpy $3 $2 1
		StrCmpS $3 } 0 MERGE
		END:
		StrCpy $8 $R0 "" -$7
		StrCmpS $8 $0 0 +4
		StrCpy $R0 $R0 -$7
		StrCpy $6 "$6$1"
		Goto -4
		MERGE:
		StrCmpS $4 * 0 +5
		StrCmpS $5 "" +2
		StrCpy $5 $1
		StrCmpS $6 "" +2
		StrCpy $6 $1
		StrCpy $R0 "$5$R0$6"
		Goto DONE
		CHK:
		StrCmpS $3 + +2
		StrCmpS $3 - 0 ERROR3
		StrCpy $5 $2 1
		IntOp $2 $2 + 0
		StrCmpS $2 0 0 ONE
		StrCmpS $5 0 ERROR2
		StrCpy $3 ""
		REPLACE:
		StrCpy $5 0
		StrCpy $2 $R0 $7 $5
		StrCmpS $2 "" +4
		StrCmpS $2 $0 +6
		IntOp $5 $5 + 1
		Goto -4
		StrCmpS $R0 $R1 ERROR1
		StrCpy $R0 "$3$R0"
		Goto DONE
		StrCpy $2 $R0 $5
		IntOp $5 $5 + $7
		StrCmpS $4 * 0 +3
		StrCpy $6 $R0 $7 $5
		StrCmpS $6 $0 -3
		StrCpy $R0 $R0 "" $5
		StrCpy $3 "$3$2$1"
		Goto REPLACE
		ONE:
		StrCpy $5 0
		StrCpy $8 0
		Goto LOOP
		PRELOOP:
		IntOp $5 $5 + 1
		LOOP:
		StrCpy $6 $R0 $7 $5
		StrCmpS $6$8 0 ERROR1
		StrCmpS $6 "" MINUS
		StrCmpS $6 $0 0 PRELOOP
		IntOp $8 $8 + 1
		StrCmpS $3$8 +$2 FOUND
		IntOp $5 $5 + $7
		Goto LOOP
		MINUS:
		StrCmpS $3 - 0 ERROR2
		StrCpy $3 +
		IntOp $2 $8 - $2
		IntOp $2 $2 + 1
		IntCmp $2 0 ERROR2 ERROR2 ONE
		FOUND:
		StrCpy $3 $R0 $5
		StrCmpS $4 * 0 +5
		StrCpy $6 $3 "" -$7
		StrCmpS $6 $0 0 +3
		StrCpy $3 $3 -$7
		Goto -3
		IntOp $5 $5 + $7
		StrCmpS $4 * 0 +3
		StrCpy $6 $R0 $7 $5
		StrCmpS $6 $0 -3
		StrCpy $R0 $R0 "" $5
		StrCpy $R0 "$3$1$R0"
		Goto DONE
		ERROR3:
		StrCpy $R0 3
		Goto ERROR
		ERROR2:
		StrCpy $R0 2
		Goto ERROR
		ERROR1:
		StrCpy $R0 1
		ERROR:
		StrCmp $9 E +3
		StrCpy $R0 $R1
		Goto +2
		SetErrors
		DONE:
		Pop $R1
		Pop $9
		Pop $8
		Pop $7
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Pop $0
		Exch $R0
	FunctionEnd
	Function WordRep
		!define WordRep `!insertmacro _WordRep`
		!macro _WordRep _STRING _WORD1 _WORD2 _NUMBER _RESULT
			Push `${_STRING}`
			Push `${_WORD1}`
			Push `${_WORD2}`
			Push `${_NUMBER}`
			Call WordRep
			Pop ${_RESULT}
		!macroend
		Exch $2
		Exch
		Exch $1
		Exch
		Exch 2
		Exch $0
		Exch 2
		Exch 3
		Exch $R0
		Exch 3
		Push $3
		Push $4
		Push $5
		Push $6
		Push $7
		Push $8
		Push $9
		Push $R1
		ClearErrors
		StrCpy $R1 $R0
		StrCpy $9 ''
		StrCpy $3 $2 1
		StrCpy $2 $2 '' 1
		StrCmp $3 'E' 0 +3
		StrCpy $9 E
		Goto -4
		StrCpy $4 $2 1 -1
		StrCpy $5 ''
		StrCpy $6 ''
		StrLen $7 $0
		StrCmp $7 0 error1
		StrCmp $R0 '' error1
		StrCmp $3 '{' beginning
		StrCmp $3 '}' ending errorchk
		beginning:
		StrCpy $8 $R0 $7
		StrCmp $8 $0 0 +4
		StrCpy $R0 $R0 '' $7
		StrCpy $5 '$5$1'
		Goto -4
		StrCpy $3 $2 1
		StrCmp $3 '}' 0 merge
		ending:
		StrCpy $8 $R0 '' -$7
		StrCmp $8 $0 0 +4
		StrCpy $R0 $R0 -$7
		StrCpy $6 '$6$1'
		Goto -4
		merge:
		StrCmp $4 '*' 0 +5
		StrCmp $5 '' +2
		StrCpy $5 $1
		StrCmp $6 '' +2
		StrCpy $6 $1
		StrCpy $R0 '$5$R0$6'
		Goto end
		errorchk:
		StrCmp $3 '+' +2
		StrCmp $3 '-' 0 error3
		StrCpy $5 $2 1
		IntOp $2 $2 + 0
		StrCmp $2 0 0 one
		StrCmp $5 0 error2
		StrCpy $3 ''
		all:
		StrCpy $5 0
		StrCpy $2 $R0 $7 $5
		StrCmp $2 '' +4
		StrCmp $2 $0 +6
		IntOp $5 $5 + 1
		Goto -4
		StrCmp $R0 $R1 error1
		StrCpy $R0 '$3$R0'
		Goto end
		StrCpy $2 $R0 $5
		IntOp $5 $5 + $7
		StrCmp $4 '*' 0 +3
		StrCpy $6 $R0 $7 $5
		StrCmp $6 $0 -3
		StrCpy $R0 $R0 '' $5
		StrCpy $3 '$3$2$1'
		Goto all
		one:
		StrCpy $5 0
		StrCpy $8 0
		Goto loop
		preloop:
		IntOp $5 $5 + 1
		loop:
		StrCpy $6 $R0 $7 $5
		StrCmp $6$8 0 error1
		StrCmp $6 '' minus
		StrCmp $6 $0 0 preloop
		IntOp $8 $8 + 1
		StrCmp $3$8 +$2 found
		IntOp $5 $5 + $7
		Goto loop
		minus:
		StrCmp $3 '-' 0 error2
		StrCpy $3 +
		IntOp $2 $8 - $2
		IntOp $2 $2 + 1
		IntCmp $2 0 error2 error2 one
		found:
		StrCpy $3 $R0 $5
		StrCmp $4 '*' 0 +5
		StrCpy $6 $3 '' -$7
		StrCmp $6 $0 0 +3
		StrCpy $3 $3 -$7
		Goto -3
		IntOp $5 $5 + $7
		StrCmp $4 '*' 0 +3
		StrCpy $6 $R0 $7 $5
		StrCmp $6 $0 -3
		StrCpy $R0 $R0 '' $5
		StrCpy $R0 '$3$1$R0'
		Goto end
		error3:
		StrCpy $R0 3
		Goto error
		error2:
		StrCpy $R0 2
		Goto error
		error1:
		StrCpy $R0 1
		error:
		StrCmp $9 'E' +3
		StrCpy $R0 $R1
		Goto +2
		SetErrors
		end:
		Pop $R1
		Pop $9
		Pop $8
		Pop $7
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Pop $0
		Exch $R0
	FunctionEnd
!endif
Function SetVariablesPath
	!macro _SetVariablesPath _VAR _PATH
		Push "${_VAR}"
		Push "${_PATH}"
		Call SetVariablesPath
	!macroend
	!define _SetVariablesPath "!insertmacro _SetVariablesPath"
	Exch $R0
	Exch
	Exch $R1
	Push $R2
	Push $R3
	Push $R7
	Push $R8
	Push $R9
	${SetEnvironmentVariable} $R1 $R0
	${WordReplaceS} $R0 \ / + $R2
	${SetEnvironmentVariable} "$R1:Forwardslash" $R2
	${WordReplaceS} $R0 \ \\ + $R3
	${SetEnvironmentVariable} "$R1:DoubleBackslash" $R3
	Pop $R9
	Pop $R8
	Pop $R7
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
FunctionEnd
Function _GetOptions
	!define _GetOptions `!insertmacro _GetOptionsCall`
	!macro _GetOptionsCall _PARAMETERS _OPTION _RESULT
		Push `${_PARAMETERS}`
		Push `${_OPTION}`
		Call _GetOptions
		Pop ${_RESULT}
	!macroend
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	ClearErrors
	StrCpy $2 $1 '' 1
	StrCpy $1 $1 1
	StrLen $3 $2
	StrCpy $7 0
	BEGIN:
	StrCpy $4 -1
	StrCpy $6 ''
	QUOTE:
	IntOp $4 $4 + 1
	StrCpy $5 $0 1 $4
	StrCmp $5$7 '0' NOTFOUND
	StrCmp $5 '' TRIMRIGHT
	StrCmp $5 '"' 0 +7
	StrCmp $6 '' 0 +3
	StrCpy $6 '"'
	Goto QUOTE
	StrCmp $6 '"' 0 +3
	StrCpy $6 ''
	Goto QUOTE
	StrCmp $5 `'` 0 +7
	StrCmp $6 `` 0 +3
	StrCpy $6 `'`
	Goto QUOTE
	StrCmp $6 `'` 0 +3
	StrCpy $6 ``
	Goto QUOTE
	StrCmp $5 '`' 0 +7
	StrCmp $6 '' 0 +3
	StrCpy $6 '`'
	Goto QUOTE
	StrCmp $6 '`' 0 +3
	StrCpy $6 ''
	Goto QUOTE
	StrCmp $6 '"' QUOTE
	StrCmp $6 `'` QUOTE
	StrCmp $6 '`' QUOTE
	StrCmp $5 $1 0 QUOTE
	StrCmp $7 0 TRIMLEFT TRIMRIGHT
	TRIMLEFT:
	IntOp $4 $4 + 1
	StrCpy $5 $0 $3 $4
	StrCmp $5 '' NOTFOUND
	StrCmp $5 $2 0 QUOTE
	IntOp $4 $4 + $3
	StrCpy $0 $0 '' $4
	StrCpy $4 $0 1
	StrCmp $4 ' ' 0 +3
	StrCpy $0 $0 '' 1
	Goto -3
	StrCpy $7 1
	Goto BEGIN
	TRIMRIGHT:
	StrCpy $0 $0 $4
	StrCpy $4 $0 1 -1
	StrCmp $4 ' ' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $3 $0 1
	StrCpy $4 $0 1 -1
	StrCmp $3 $4 0 END
	StrCmp $3 '"' +3
	StrCmp $3 `'` +2
	StrCmp $3 '`' 0 END
	StrCpy $0 $0 -1 1
	Goto END
	NOTFOUND:
	SetErrors
	StrCpy $0 ''
	END:
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function GetVersion
	!macro _GetVersion _FILE _RESULT
		Push `${_FILE}`
		Call GetVersion
		Pop ${_RESULT}
	!macroend
	!define GetVersion `!insertmacro _GetVersion`
	Exch $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	ClearErrors
	GetDLLVersion '$0' $1 $2
	IfErrors +9
	IntOp $3 $1 >> 16
	IntOp $3 $3 & 0x0000FFFF
	IntOp $4 $1 & 0x0000FFFF
	IntOp $5 $2 >> 16
	IntOp $5 $5 & 0x0000FFFF
	IntOp $6 $2 & 0x0000FFFF
	StrCpy $0 '$3.$4.$5.$6'
	Goto +3
	SetErrors
	StrCpy $0 ''
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!ifdef IsFileLocked
	!macro _LL_FileLocked _a _b _t _f
		!insertmacro _LOGICLIB_TEMP
		System::Call kernel32::GetCurrentProcess()i.s
		System::Call kernel32::IsWow64Process(is,*i.s)
		Pop $_LOGICLIB_TEMP
		StrCmpS $_LOGICLIB_TEMP 0 +3
		IfFileExists "$PLUGINSDIR\LockedList64.dll" +2
		File "/oname=$PLUGINSDIR\LockedList64.dll" `${NSISDIR}\Plugins\LockedList64.dll`
		LockedList::IsFileLocked `${_b}`
		Pop $_LOGICLIB_TEMP
		!insertmacro _== $_LOGICLIB_TEMP true `${_t}` `${_f}`
	!macroend
	!define FileLocked `"" LL_FileLocked`
!endif
!ifdef TrimString
	;=== This works better than TrimWhite because 
	;=== this can also remove carriage returns.
	Function Trim
		!macro _Trim _RESULT _STRING
			Push `${_STRING}`
			Call Trim
			Pop `${_RESULT}`
		!macroend
		!define Trim `!insertmacro _Trim`
		Exch $R1
		Push $R2
		StrCpy $R2 `$R1` 1
		StrCmpS `$R2` " " +5
		StrCmpS `$R2` `$\r` +4
		StrCmpS `$R2` `$\n` +3
		StrCmpS `$R2` `$\t` +2
		Goto +3
		StrCpy $R1 `$R1` "" 1
		Goto -7
		StrCpy $R2 `$R1` 1 -1
		StrCmpS `$R2` " " +5
		StrCmpS `$R2` `$\r` +4
		StrCmpS `$R2` `$\n` +3
		StrCmpS `$R2` `$\t` +2
		Goto +3
		StrCpy $R1 `$R1` -1
		Goto -7
		Pop $R2
		Exch $R1
	FunctionEnd
!endif
!ifdef CloseProc
	Function CloseX
		!macro _CloseX _PROCESS
			Push `${_PROCESS}`
			Call CloseX
		!macroend
		!define CloseX "!insertmacro _CloseX"
		Exch $0
		Push $1
		CLOSE:
		${If} ${ProcessExists} `$0`
			${CloseProcess} `$0` $1
			${If} ${ProcessExists} `$0`
				${TerminateProcess} `$0` $1
				Sleep 1000
				Goto CLOSE
			${EndIf}
		${EndIf}
		Pop $1
		Pop $0
	FunctionEnd
!endif
!ifdef WININET_FUNCTION
	!macro _WININET _URL
		System::Call `wininet::DeleteUrlCacheEntryW(t '${_URL}')i .r0`
	!macroend
	!define WININET "!insertmacro _WININET"
!endif
!ifdef RMEMPTYDIRECTORIES
	Function RMEmptyDir
		!macro _RMEmptyDir _DIR _SUBDIR
			Push `${_SUBDIR}`
			Push `${_DIR}`
			Call RMEmptyDir
		!macroend
		!define RMEmptyDir `!insertmacro _RMEmptyDir`
		Exch $0 ; dir
		Exch
		Exch $1 ; subdir
		Push $2
		Push $3
		FindFirst $2 $3 `$0\*.*`
		StrCmpS $2 "" +9
		StrCmpS $3 "" +8
		StrCmpS $3 "." +5
		StrCmpS $3 ".." +4
		RMDir `$0\$3\$1`
		RMDir `$0\$3`
		RMDir `$0`
		FindNext $2 $3
		Goto -7
		FindClose $2
		Pop $3
		Pop $2
		Pop $1
		Pop $0
	FunctionEnd
!endif
!ifdef NTFS
	!define FILE_SUPPORTS_REPARSE_POINTS 0x00000080
	!macro YESNO _FLAGS _BIT _VAR
		IntOp ${_VAR} ${_FLAGS} & ${_BIT}
		${IfThen} ${_VAR} <> 0 ${|} StrCpy ${_VAR} 1 ${|}
		${IfThen} ${_VAR} == 0 ${|} StrCpy ${_VAR} 0 ${|}
	!macroend
	Function ValidateFS
		!macro _ValidateFS _PATH _RETURN
			Push `${_PATH}`
			Call ValidateFS
			Pop ${_RETURN}
		!macroend
		!define ValidateFS `!insertmacro _ValidateFS`
		Exch $0
		Push $1
		Push $2
		StrCpy $0 $0 3
		System::Call `Kernel32::GetVolumeInformation(t "$0",t,i ${NSIS_MAX_STRLEN},*i,*i,*i.r1,t,i ${NSIS_MAX_STRLEN})i.r0`
		${If} $0 <> 0
			!insertmacro YESNO $1 ${FILE_SUPPORTS_REPARSE_POINTS} $2
		${EndIf}
		Pop $0
		Pop $1
		Exch $2
	FunctionEnd
!endif
!ifdef ComputerName
	Function GetComputerName
		!macro _GetComputerName _NAME
			Call GetComputerName
			Pop ${_NAME}
		!macroend
		!define GetComputerName `!insertmacro _GetComputerName`
		Push $0
		Push $1
		System::Call `kernel32.dll::GetComputerNameExW(i 4,w .r0,*i ${NSIS_MAX_STRLEN} r1)i.r1`
		StrCmpS $1 1 0 +3
		StrCpy $0 `\\$0`
		Goto +6
		System::Call `kernel32.dll::GetComputerNameW(t .r0,*i ${NSIS_MAX_STRLEN} r1)i.r1`
		StrCmpS $1 1 0 +3
		StrCpy $0 `\\$0`
		Goto +2
		StrCpy $0 ""
		Pop $1
		Exch $0
	FunctionEnd
!endif
!ifdef ACL
	!define SetACL::Key `!insertmacro SetACL::Key`
	!macro SetACL::Key _ROOT _KEY
		AccessControl::SetRegKeyOwner ${_ROOT} `${_KEY}` (S-1-5-32-545)
		AccessControl::ClearOnRegKey ${_ROOT} `${_KEY}` EVERYONE FULLACCESS
		AccessControl::SetRegKeyOwner ${_ROOT} `${_KEY}` (S-1-5-32-545)
		AccessControl::GrantOnRegKey ${_ROOT} `${_KEY}` EVERYONE FULLACCESS
	!macroend
;	Function SetACL::Key
;		!macro _SetACL::Key _ROOT _KEY
;			Push `${_KEY}`
;			Push ${_ROOT}
;			Call SetACL::Key
;		!macroend
;		!define SetACL::Key `!insertmacro _SetACL::Key`
;		Exch $0 ; root
;		Exch
;		Exch $1 ; key
;		Push $2
;		AccessControl::SetRegKeyOwner $0 `$1` (S-1-5-32-545)
;		Pop $2
;		AccessControl::ClearOnRegKey $0 `$1` EVERYONE FULLACCESS
;		Pop $2
;		AccessControl::SetRegKeyOwner $0 `$1` (S-1-5-32-545)
;		Pop $2
;		AccessControl::GrantOnRegKey $0 `$1` EVERYONE FULLACCESS
;		Pop $2
;		Pop $1
;		Pop $0
;	FunctionEnd
!endif
!ifdef ACL_DIR
;	!define SetACL::Dir `!insertmacro SetACL::Dir`
;	!macro SetACL::Dir _DIR
;		Push $R0
;		ReadEnvStr $R0 UserName
;		AccessControl::GrantOnFile `${_DIR}` `$R0` FULLACCESS
;		AccessControl::GrantOnFile `${_DIR}` (S-1-5-32-545) FULLACCESS
;		Pop $R0
;	!macroend
	Function SetACL::Dir
		!macro _SetACL::Dir _DIR
			Push `${_DIR}`
			Call SetACL::Dir
		!macroend
		!define SetACL::Dir `!insertmacro _SetACL::Dir`
		Exch $R9
		Push $R8
		ReadEnvStr $R8 UserName
		AccessControl::GrantOnFile `$R9` `$R8` FULLACCESS
		AccessControl::GrantOnFile `$R9` (S-1-5-32-545) FULLACCESS
		SetFileAttributes `$R9` NORMAL
		Pop $R8
		Pop $R9
	FunctionEnd
!endif
!ifdef CloseWindow
	!define CABW         CabinetWClass
	Function Close
		!macro _Close _CLASS _TITLE
			Push `${_TITLE}`
			Push `${_CLASS}`
			Call Close
		!macroend
		!define Close `!insertmacro _Close`
		Exch $2
		Exch
		Exch $1
		Push $0
		FindWindow $0 `$2` `$1`
		IntCmp $0 0 +5 0 0
		IsWindow $0 0 +4
		System::Call `user32::PostMessage(i,i,i,i) i($0,0x0010,0,0)`
		Sleep 100
		Goto -5
		Pop $0
		Pop $1
		Pop $2
	FunctionEnd
!endif
!ifdef LocalLow
	Function GetLocalAppDataLow
		!macro _GetLocalAppDataLow _VAR
			Call GetLocalAppDataLow
			Pop `${_VAR}`
		!macroend
		!define GetLocalAppDataLow `!insertmacro _GetLocalAppDataLow`
		Push $0
		Push $1
		Push $2
		System::Call `shell32::SHGetKnownFolderPath(g '{A520A1A4-1780-4FF6-BD18-167343C5AF16}', i 0x1000 ,in, *i.r1)i.r0`
		StrCmpS $0 0 0 +5
		System::Call /NOUNLOAD `kernel32::lstrlenW(i $1)i.r2`
		IntOp $2 $2 * 2
		System::Call /NOUNLOAD `*$1(&w$2 .r0)`
		System::Call `ole32::CoTaskMemFree(i $1)`
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd
!endif
Function GetLongPathName
	!macro _GetLongPathName _PATH
		Push `${_PATH}`
		Call GetLongPathName
		Pop `${_PATH}`
	!macroend
	!define GetLongPathName `!insertmacro _GetLongPathName`
	Exch $0
	Push $1
	Push $2
	System::Call 'kernel32::GetLongPathName(t r0, t .r1, i ${NSIS_MAX_STRLEN}) i .r2'
	StrCmpS $2 error 0 +3
	StrCpy $0 error
	Goto +2
	StrCpy $0 $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!ifdef PublicDoc
	Function GetPublicDoc
		!macro _GetPublicDoc _RET
			Call GetPublicDoc
			Pop `${_RET}`
		!macroend
		!define GetPublicDoc `!insertmacro _GetPublicDoc`
		Push $1
		Push $2
		Push $3
		Push $4
		StrCpy $1 ""
		StrCpy $2 0x002e
		StrCpy $3 ""
		StrCpy $4 ""
		System::Call `shell32::SHGetSpecialFolderPath(i $HWNDPARENT, t .r1, i r2, i r3) i .r4`
		Pop $4
		Pop $3
		Pop $2
		Exch $1
	FunctionEnd
!endif
Function FileName
	!macro _FileName _STRING _RESULT
		Push `${_STRING}`
		Call FileName
		Pop ${_RESULT}
	!macroend
	!define FileName "!insertmacro _FileName"
	Exch $0
	Push $1
	Push $2
	StrCpy $2 $0 1 -1
	StrCmp $2 '\' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $1 0
	IntOp $1 $1 - 1
	StrCpy $2 $0 1 $1
	StrCmp $2 '' +4
	StrCmp $2 '\' 0 -3
	IntOp $1 $1 + 1
	StrCpy $0 $0 '' $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function GetAfterChar
	!macro _GetAfterChar _STR _CHAR _RET
		Push `${_STR}`
		Push `${_CHAR}`
		Call GetAfterChar
		Pop `${_RET}`
	!macroend
	!define GetAfterChar "!insertmacro _GetAfterChar"
	Exch $0
	Exch
	Exch $1
	Push $2
	Push $3
	StrCpy $2 0
	IntOp $2 $2 - 1
	StrCpy $3 $1 1 $2
	StrCmpS $3 "" 0 +3
	StrCpy $0 ""
	Goto +5
	StrCmp $3 $0 +2
	Goto -6
	IntOp $2 $2 + 1
	StrCpy $0 $1 "" $2
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
${SegmentFile}
${Segment.onInit}
	${GetBaseName} $EXEFILE $BaseName
	StrCpy $WrapperFile `${WRAPPER}`
	StrCpy $AppID `${APPNAME}`
	StrCpy $AppName `${FULLNAME}`
	StrCpy $AppNamePortable `${PORTABLEAPPNAME}`
!macroend
${SegmentInit}
	IfFileExists `${WRAPPER}` 0 +5
	InitPluginsDir
	CopyFiles /SILENT `${WRAPPER}` `${WRAPPER2}`
	StrCpy $WrapperFile `${WRAPPER2}`
	Goto +5
	StrCpy $MissingFileOrPath `${WRAPPER}`
	MessageBox MB_OK|MB_ICONSTOP `$(LauncherFileNotFound)`
	Call Unload
	Quit
	!ifndef DisableProgramExecSegment
		${GetParameters} $0
		!ifdef UAC
			${GetOptions} $0 /UAC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /UAC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
			${GetOptions} $0 /NCRC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /NCRC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
		!endif
		!ifmacrodef ProExecInit
			!insertmacro ProExecInit
		!else
			StrCpy $ProgramExecutable ""
			StrCmpS $Bit 64 0 +5
			StrCmpS $0 "" +2
			${ReadWrapperConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters64
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadWrapperConfig} $ProgramExecutable Launch ProgramExecutable64
			StrCmpS $0 "" +3
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadWrapperConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadWrapperConfig} $ProgramExecutable Launch ProgramExecutable
		!endif
	!endif
	StrCmpS $ProgramExecutable "" 0 +3
	MessageBox MB_OK|MB_ICONSTOP `${RUNTIME} is missing [Launch]:ProgramExecutable - What is supposed to be launched?`
	Quit
	!ifmacrodef UnProExecInit
		!insertmacro UnProExecInit
	!endif
!macroend
${SegmentPreExecPrimary}
	${WriteRuntimeData} ${PAC} PluginsDir $PLUGINSDIR
!macroend
${SegmentUnload}
	!ifmacrodef UnloadEXE
		!insertmacro UnloadEXE
	!endif
	!ifmacrodef Unload
		!insertmacro Unload
	!endif
	!ifdef REGISTRY
		StrCmpS $Registry true 0 +2
		Registry::_Unload
	!endif
	SetOutPath `$TEMP` ;= prevents $PLUGINSDIR from being locked.
	FileClose $_FEIP_FileHandle
	Delete `$PLUGINSDIR\wrapper.ini`
	Delete `${WRAPPER2}`
	StrCmpS $SecondaryLaunch true +10
	${ReadRuntimeData} $0 ${PAC} PluginsDir
	StrCmpS $0 "" +3
	StrCmp `$0` `$PLUGINSDIR` +2
	RMDir /r `$0`
	Delete `${RUNTIME}`
	Delete `$TEMP\*.tmp`
	Delete `${RUNTIME2}`
	Delete `$TEMP\*.tmp`
	System::Free 0
!macroend
