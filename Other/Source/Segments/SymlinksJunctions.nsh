;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; SymlinksJunctions.nsh
;   This file handles symbolic links, directory junctions, and hard links
;   with backup, restoration, and conflict resolution.
; 
; USAGE
;	Add sections [SymLink1], [Junction1], [HardLink1] etc. to Launcher.ini
;
;	SymLink Keys (Symbolic Links):
;	LinkPath		-	Path where the symbolic link will be created
;	TargetPath		-	Path that the link points to (supports %PAL:* variables)
;	Type			-	file, directory (auto-detect if not specified)
;	IfExists		-	skip, backup, replace, update
;	Required		-	true/false (show error if creation fails)
;	Relative		-	true/false (create relative vs absolute link)
;	Temporary		-	true/false (remove on app exit vs persist)
;
;	Junction Keys (Directory Junctions - NTFS only):
;	JunctionPath	-	Path where the junction will be created
;	TargetPath		-	Directory that the junction points to
;	IfExists		-	skip, backup, replace
;	Required		-	true/false (show error if creation fails)
;	Temporary		-	true/false (remove on app exit vs persist)
;
;	HardLink Keys (Hard Links - same volume only):
;	LinkPath		-	Path where the hard link will be created
;	TargetPath		-	File that the hard link points to (must be file)
;	IfExists		-	skip, backup, replace
;	Required		-	true/false (show error if creation fails)
;	Temporary		-	true/false (remove on app exit vs persist)
;
; EXAMPLES
;	[SymLink1]
;	LinkPath=%USERPROFILE%\Documents\MyAppData
;	TargetPath=%PAL:DataDir%\Documents
;	Type=directory
;	IfExists=backup
;	Required=true
;	Relative=false
;	Temporary=true
;
;	[Junction1]
;	JunctionPath=C:\ProgramData\MyApp
;	TargetPath=%PAL:DataDir%
;	IfExists=replace
;	Required=false
;	Temporary=true
;
;	[HardLink1]
;	LinkPath=%APPDATA%\MyApp\config.ini
;	TargetPath=%PAL:DataDir%\config.ini
;	IfExists=backup
;	Required=true
;	Temporary=true
;

!ifdef SYMLINKSJUNCTIONS
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!ifndef WORDREPLACE_NSH_INCLUDED
	!include WordReplace.nsh
!endif

; Windows link management tools
!define MKLINK `$SYSDIR\cmd.exe /c mklink`
!define RMDIR `$SYSDIR\rmdir.exe`
!define DEL `$SYSDIR\del.exe`

; Link type constants
!define LINK_TYPE_SYMBOLIC 1
!define LINK_TYPE_JUNCTION 2
!define LINK_TYPE_HARD 3

; File attribute constants for link detection
!define FILE_ATTRIBUTE_REPARSE_POINT 0x400
!define IO_REPARSE_TAG_SYMLINK 0xA000000C
!define IO_REPARSE_TAG_MOUNT_POINT 0xA0000003

; Check if path is a symbolic link, junction, or hard link
!define Link::GetType `!insertmacro _Link::GetType`
!macro _Link::GetType _PATH _RESULT _TARGET _LINKTYPE
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_TARGET} ""
	StrCpy ${_LINKTYPE} "none"
	
	${ParseLocations} "${_PATH}" $R8
	
	; Check if path exists
	${IfNot} ${FileExists} "$R8"
		${DebugMsg} "Path does not exist: $R8"
		Goto _LINK_TYPE_END
	${EndIf}
	
	; Get file attributes
	System::Call 'Kernel32::GetFileAttributes(t "$R8") i .r0'
	${If} $0 == -1
		${DebugMsg} "Cannot get attributes for: $R8"
		Goto _LINK_TYPE_END
	${EndIf}
	
	; Check if it's a reparse point (symlink or junction)
	IntOp $1 $0 & ${FILE_ATTRIBUTE_REPARSE_POINT}
	${If} $1 != 0
		StrCpy ${_RESULT} "true"
		
		; Use DIR command to get link information
		ExecDos::Exec /TOSTACK `"$SYSDIR\cmd.exe" /c "dir /-c "$R8" | findstr /C:"<"`
		Pop $2
		Pop $3
		
		${If} $2 == 0
			; Parse the output to determine link type and target
			${StrLoc} $0 "$3" "<SYMLINKD>" ">"
			${If} $0 != ""
				StrCpy ${_LINKTYPE} "symbolic_directory"
				; Extract target from output
				${StrLoc} $1 "$3" "[" ">"
				${If} $1 != ""
					StrCpy $2 $3 "" $1
					IntOp $1 $1 + 1
					StrCpy $2 $2 "" $1
					${StrLoc} $1 "$2" "]" ">"
					${If} $1 != ""
						StrCpy ${_TARGET} $2 $1
					${EndIf}
				${EndIf}
				Goto _LINK_TYPE_END
			${EndIf}
			
			${StrLoc} $0 "$3" "<SYMLINK>" ">"
			${If} $0 != ""
				StrCpy ${_LINKTYPE} "symbolic_file"
				; Extract target from output
				${StrLoc} $1 "$3" "[" ">"
				${If} $1 != ""
					StrCpy $2 $3 "" $1
					IntOp $1 $1 + 1
					StrCpy $2 $2 "" $1
					${StrLoc} $1 "$2" "]" ">"
					${If} $1 != ""
						StrCpy ${_TARGET} $2 $1
					${EndIf}
				${EndIf}
				Goto _LINK_TYPE_END
			${EndIf}
			
			${StrLoc} $0 "$3" "<JUNCTION>" ">"
			${If} $0 != ""
				StrCpy ${_LINKTYPE} "junction"
				; Extract target from output
				${StrLoc} $1 "$3" "[" ">"
				${If} $1 != ""
					StrCpy $2 $3 "" $1
					IntOp $1 $1 + 1
					StrCpy $2 $2 "" $1
					${StrLoc} $1 "$2" "]" ">"
					${If} $1 != ""
						StrCpy ${_TARGET} $2 $1
					${EndIf}
				${EndIf}
				Goto _LINK_TYPE_END
			${EndIf}
		${EndIf}
	${Else}
		; Check if it might be a hard link by checking link count
		System::Call 'Kernel32::CreateFile(t "$R8", i 0, i 3, i 0, i 3, i 0, i 0) i .r0'
		${If} $0 != -1
			System::Call 'Kernel32::GetFileInformationByHandle(i r0, &i64 r1) i .r2'
			${If} $2 != 0
				; Extract number of links from file information structure
				System::Call '*$1(i, i, i, i, i, i, i, i .r3, i, i, i)'
				${If} $3 > 1
					StrCpy ${_RESULT} "true"
					StrCpy ${_LINKTYPE} "hardlink"
					${DebugMsg} "Hard link detected: $R8 (Links: $3)"
				${EndIf}
			${EndIf}
			System::Call 'Kernel32::CloseHandle(i r0)'
		${EndIf}
	${EndIf}
	
	_LINK_TYPE_END:
	${If} ${_RESULT} == "true"
		${DebugMsg} "Link detected: $R8 -> ${_TARGET} (Type: ${_LINKTYPE})"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create symbolic link
!define SymLink::Create `!insertmacro _SymLink::Create`
!macro _SymLink::Create _LINKPATH _TARGETPATH _TYPE _RELATIVE _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_LINKPATH}" $R8
	${ParseLocations} "${_TARGETPATH}" $R9
	
	; Validate target exists
	${IfNot} ${FileExists} "$R9"
		StrCpy ${_ERROR} "Target path does not exist: $R9"
		${DebugMsg} "Target not found: $R9"
		Goto _SYMLINK_CREATE_END
	${EndIf}
	
	; Auto-detect type if not specified
	${If} "${_TYPE}" == ""
	${OrIf} "${_TYPE}" == "auto"
		${If} ${FileExists} "$R9\*.*"
			StrCpy $0 "/D"
		${Else}
			StrCpy $0 ""
		${EndIf}
	${ElseIf} "${_TYPE}" == "directory"
		StrCpy $0 "/D"
	${Else}
		StrCpy $0 ""
	${EndIf}
	
	; Handle relative vs absolute paths
	${If} "${_RELATIVE}" == "true"
		; Calculate relative path
		${GetRelativePath} "$R8" "$R9" $1
		StrCpy $R9 "$1"
	${EndIf}
	
	${DebugMsg} "Creating symbolic link: $R8 -> $R9"
	
	; Create the symbolic link
	ExecDos::Exec /TOSTACK `"$SYSDIR\cmd.exe" /c "mklink $0 "$R8" "$R9""`
	Pop $1 ; Return code
	Pop $2 ; Output
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Symbolic link created successfully: $R8"
			${Break}
		${Case} "1"
			; Parse output for specific error
			${StrLoc} $3 "$2" "already exists" "<"
			${If} $3 != ""
				StrCpy ${_ERROR} "Link path already exists"
			${Else}
				${StrLoc} $3 "$2" "privilege" "<"
				${If} $3 != ""
					StrCpy ${_ERROR} "Insufficient privileges to create symbolic link"
				${Else}
					StrCpy ${_ERROR} "Failed to create symbolic link"
				${EndIf}
			${EndIf}
			${DebugMsg} "Failed to create symbolic link: ${_ERROR}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Symbolic link creation failed (Error $1)"
			${DebugMsg} "Symbolic link creation failed: Error $1"
			${Break}
	${EndSwitch}
	
	_SYMLINK_CREATE_END:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create junction
!define Junction::Create `!insertmacro _Junction::Create`
!macro _Junction::Create _JUNCTIONPATH _TARGETPATH _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_JUNCTIONPATH}" $R8
	${ParseLocations} "${_TARGETPATH}" $R9
	
	; Validate target directory exists
	${IfNot} ${FileExists} "$R9\*.*"
		StrCpy ${_ERROR} "Target directory does not exist: $R9"
		${DebugMsg} "Target directory not found: $R9"
		Goto _JUNCTION_CREATE_END
	${EndIf}
	
	${DebugMsg} "Creating junction: $R8 -> $R9"
	
	; Create the junction using mklink /J
	ExecDos::Exec /TOSTACK `"$SYSDIR\cmd.exe" /c "mklink /J "$R8" "$R9""`
	Pop $1 ; Return code
	Pop $2 ; Output
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Junction created successfully: $R8"
			${Break}
		${Case} "1"
			; Parse output for specific error
			${StrLoc} $3 "$2" "already exists" "<"
			${If} $3 != ""
				StrCpy ${_ERROR} "Junction path already exists"
			${Else}
				${StrLoc} $3 "$2" "privilege" "<"
				${If} $3 != ""
					StrCpy ${_ERROR} "Insufficient privileges to create junction"
				${Else}
					StrCpy ${_ERROR} "Failed to create junction"
				${EndIf}
			${EndIf}
			${DebugMsg} "Failed to create junction: ${_ERROR}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Junction creation failed (Error $1)"
			${DebugMsg} "Junction creation failed: Error $1"
			${Break}
	${EndSwitch}
	
	_JUNCTION_CREATE_END:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create hard link
!define HardLink::Create `!insertmacro _HardLink::Create`
!macro _HardLink::Create _LINKPATH _TARGETPATH _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_LINKPATH}" $R8
	${ParseLocations} "${_TARGETPATH}" $R9
	
	; Validate target file exists and is a file (not directory)
	${IfNot} ${FileExists} "$R9"
		StrCpy ${_ERROR} "Target file does not exist: $R9"
		${DebugMsg} "Target file not found: $R9"
		Goto _HARDLINK_CREATE_END
	${EndIf}
	
	${If} ${FileExists} "$R9\*.*"
		StrCpy ${_ERROR} "Target is a directory, not a file: $R9"
		${DebugMsg} "Target is directory, cannot create hard link: $R9"
		Goto _HARDLINK_CREATE_END
	${EndIf}
	
	; Check that both paths are on the same volume
	StrCpy $0 $R8 3 ; Get drive letter
	StrCpy $1 $R9 3
	${If} $0 != $1
		StrCpy ${_ERROR} "Hard links require both paths on the same volume"
		${DebugMsg} "Volume mismatch for hard link: $0 vs $1"
		Goto _HARDLINK_CREATE_END
	${EndIf}
	
	${DebugMsg} "Creating hard link: $R8 -> $R9"
	
	; Create the hard link using mklink /H
	ExecDos::Exec /TOSTACK `"$SYSDIR\cmd.exe" /c "mklink /H "$R8" "$R9""`
	Pop $1 ; Return code
	Pop $2 ; Output
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Hard link created successfully: $R8"
			${Break}
		${Case} "1"
			; Parse output for specific error
			${StrLoc} $3 "$2" "already exists" "<"
			${If} $3 != ""
				StrCpy ${_ERROR} "Link path already exists"
			${Else}
				StrCpy ${_ERROR} "Failed to create hard link"
			${EndIf}
			${DebugMsg} "Failed to create hard link: ${_ERROR}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Hard link creation failed (Error $1)"
			${DebugMsg} "Hard link creation failed: Error $1"
			${Break}
	${EndSwitch}
	
	_HARDLINK_CREATE_END:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Remove link (symlink, junction, or hard link)
!define Link::Remove `!insertmacro _Link::Remove`
!macro _Link::Remove _LINKPATH _LINKTYPE _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_LINKPATH}" $R8
	
	${DebugMsg} "Removing link: $R8 (Type: ${_LINKTYPE})"
	
	; Choose removal method based on link type
	${Switch} "${_LINKTYPE}"
		${Case} "symbolic_directory"
		${Case} "junction"
			; Use rmdir for directory links and junctions
			ExecDos::Exec /TOSTACK `"${RMDIR}" "$R8"`
			Pop $0
			Pop $1
			${Break}
		${Case} "symbolic_file"
		${Case} "hardlink"
		${CaseElse}
			; Use del for file links and hard links
			ExecDos::Exec /TOSTACK `"${DEL}" "$R8"`
			Pop $0
			Pop $1
			${Break}
	${EndSwitch}
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Link removed successfully: $R8"
			${Break}
		${Case} "2"
			StrCpy ${_RESULT} "true" ; Consider success if file not found
			StrCpy ${_ERROR} "Link not found"
			${DebugMsg} "Link not found for removal: $R8"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to remove link (Error $0)"
			${DebugMsg} "Failed to remove link $R8: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup existing link
!define Link::Backup `!insertmacro _Link::Backup`
!macro _Link::Backup _LINKPATH _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	
	${Link::GetType} "${_LINKPATH}" $0 $1 $2
	${If} $0 == "true"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Target" "$1"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Type" "$2"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "true"
		${DebugMsg} "Backed up link: ${_LINKPATH} -> $1 (Type: $2)"
	${ElseIf} ${FileExists} "${_LINKPATH}"
		; It's a regular file/directory, not a link
		${If} ${FileExists} "${_LINKPATH}\*.*"
			StrCpy $2 "directory"
		${Else}
			StrCpy $2 "file"
		${EndIf}
		
		; For regular files/directories, we need to move them to backup
		StrCpy $3 "${_LINKPATH}.portable_backup"
		${ParseLocations} "$3" $4
		
		Rename "${_LINKPATH}" "$4"
		${If} ${Errors}
			${DebugMsg} "Failed to backup existing path: ${_LINKPATH}"
		${Else}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_BackupPath" "$4"
			${WriteRuntimeData} ${_SECTION} "${_KEY}_Type" "$2"
			${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "regular"
			${DebugMsg} "Backed up regular $2: ${_LINKPATH} -> $4"
		${EndIf}
	${Else}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "false"
		${DebugMsg} "Path did not exist: ${_LINKPATH}"
	${EndIf}
	
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Restore backed up link or file
!define Link::Restore `!insertmacro _Link::Restore`
!macro _Link::Restore _LINKPATH _SECTION _KEY _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	
	StrCpy ${_RESULT} "false"
	
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_Existed"
	${If} ${Errors}
		${DebugMsg} "No backup found for: ${_LINKPATH}"
		Goto _LINK_RESTORE_END
	${EndIf}
	
	${Switch} $0
		${Case} "true"
			; Restore original link
			${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_Target"
			${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_Type"
			
			${Switch} $2
				${Case} "symbolic_directory"
					${SymLink::Create} "${_LINKPATH}" "$1" "directory" "false" $3 $4
					${Break}
				${Case} "symbolic_file"
					${SymLink::Create} "${_LINKPATH}" "$1" "file" "false" $3 $4
					${Break}
				${Case} "junction"
					${Junction::Create} "${_LINKPATH}" "$1" $3 $4
					${Break}
				${Case} "hardlink"
					${HardLink::Create} "${_LINKPATH}" "$1" $3 $4
					${Break}
				${Default}
					${DebugMsg} "Unknown link type for restoration: $2"
					${Break}
			${EndSwitch}
			
			${If} $3 == "true"
				StrCpy ${_RESULT} "true"
				${DebugMsg} "Link restored successfully: ${_LINKPATH}"
			${Else}
				${DebugMsg} "Failed to restore link ${_LINKPATH}: $4"
			${EndIf}
			${Break}
			
		${Case} "regular"
			; Restore regular file/directory from backup
			${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_BackupPath"
			${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_Type"
			
			${If} ${FileExists} "$1"
				Rename "$1" "${_LINKPATH}"
				${If} ${Errors}
					${DebugMsg} "Failed to restore regular $2: ${_LINKPATH}"
				${Else}
					StrCpy ${_RESULT} "true"
					${DebugMsg} "Restored regular $2: ${_LINKPATH}"
				${EndIf}
			${Else}
				${DebugMsg} "Backup file not found: $1"
			${EndIf}
			${Break}
			
		${Case} "false"
		${CaseElse}
			; Path didn't exist originally, removal is success
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Path did not exist originally: ${_LINKPATH}"
			${Break}
	${EndSwitch}
	
	_LINK_RESTORE_END:
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if user can create symbolic links
!define Link::CanCreateSymLinks `!insertmacro _Link::CanCreateSymLinks`
!macro _Link::CanCreateSymLinks _RESULT
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	
	; Test symbolic link creation
	StrCpy $R8 "$TEMP\symlink_test_target"
	StrCpy $0 "$TEMP\symlink_test_link"
	
	; Create a test target file
	FileOpen $1 "$R8" w
	${If} $1 != ""
		FileWrite $1 "test"
		FileClose $1
		
		; Try to create a symbolic link
		ExecDos::Exec /TOSTACK `"$SYSDIR\cmd.exe" /c "mklink "$0" "$R8""`
		Pop $1 ; Return code
		Pop $2 ; Output
		
		${If} $1 == 0
			StrCpy ${_RESULT} "true"
			${DebugMsg} "User can create symbolic links"
			Delete "$0" ; Clean up test link
		${Else}
			${DebugMsg} "User cannot create symbolic links (insufficient privileges)"
		${EndIf}
		
		Delete "$R8" ; Clean up test target
	${EndIf}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Get relative path between two absolute paths
!define GetRelativePath `!insertmacro _GetRelativePath`
!macro _GetRelativePath _FROM _TO _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $R8
	Push $R9
	
	; Split paths into components
	${WordReplace} "${_FROM}" "\" "$\n" "+" $0
	${WordReplace} "${_TO}" "\" "$\n" "+" $1
	
	; Find common root
	StrCpy $2 1 ; Component index
	StrCpy $3 "" ; Common components
	${Do}
		${WordFind} "$0" "$\n" "+$2" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${WordFind} "$1" "$\n" "+$2" $5
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		
		${If} $4 == $5
			${If} $3 == ""
				StrCpy $3 "$4"
			${Else}
				StrCpy $3 "$3\$4"
			${EndIf}
			IntOp $2 $2 + 1
		${Else}
			${ExitDo}
		${EndIf}
	${Loop}
	
	; Calculate relative path
	StrCpy $R8 ""
	StrCpy $R9 $2
	
	; Count remaining components in FROM path (how many .. needed)
	${Do}
		${WordFind} "$0" "$\n" "+$R9" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${If} $R8 == ""
			StrCpy $R8 ".."
		${Else}
			StrCpy $R8 "$R8\.."
		${EndIf}
		IntOp $R9 $R9 + 1
	${Loop}
	
	; Add remaining components from TO path
	${Do}
		${WordFind} "$1" "$\n" "+$2" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${If} $R8 == ""
			StrCpy $R8 "$4"
		${Else}
			StrCpy $R8 "$R8\$4"
		${EndIf}
		IntOp $2 $2 + 1
	${Loop}
	
	${If} $R8 == ""
		StrCpy ${_RESULT} "."
	${Else}
		StrCpy ${_RESULT} "$R8"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Generate links and junctions report
!define Link::GenerateReport `!insertmacro _Link::GenerateReport`
!macro _Link::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Symbolic Links and Junctions Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "===================================$\r$\n$\r$\n"
		
		; Symbolic links
		FileWrite $0 "Symbolic Links:$\r$\n"
		FileWrite $0 "---------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 SymLink$R0 LinkPath
			${IfThen} ${Errors}

			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 SymLink$R0 TargetPath
			
			${Link::GetType} "$1" $3 $4 $5
			${If} $3 == "true"
				FileWrite $0 "$1 -> $4 (Type: $5)$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not found$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Junctions
		FileWrite $0 "$\r$\nJunctions:$\r$\n"
		FileWrite $0 "----------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 Junction$R0 JunctionPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 Junction$R0 TargetPath
			
			${Link::GetType} "$1" $3 $4 $5
			${If} $3 == "true"
				FileWrite $0 "$1 -> $4 (Type: $5)$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not found$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Hard links
		FileWrite $0 "$\r$\nHard Links:$\r$\n"
		FileWrite $0 "-----------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 HardLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 HardLink$R0 TargetPath
			
			${Link::GetType} "$1" $3 $4 $5
			${If} $3 == "true"
				FileWrite $0 "$1 -> $4 (Type: $5)$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not found$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileClose $0
		${DebugMsg} "Links and junctions report generated: ${_FILEPATH}"
	${EndIf}
	
	Pop $R0
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if two paths are on the same volume
!define Link::SameVolume `!insertmacro _Link::SameVolume`
!macro _Link::SameVolume _PATH1 _PATH2 _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	
	${ParseLocations} "${_PATH1}" $0
	${ParseLocations} "${_PATH2}" $1
	
	; Get volume information for both paths
	System::Call 'Kernel32::GetVolumePathName(t "$0", t .r2, i ${NSIS_MAX_STRLEN}) i .r3'
	${If} $3 != 0
		System::Call 'Kernel32::GetVolumePathName(t "$1", t .r3, i ${NSIS_MAX_STRLEN}) i .r0'
		${If} $0 != 0
			${If} $2 == $3
				StrCpy ${_RESULT} "true"
				${DebugMsg} "Paths are on same volume: $2"
			${Else}
				StrCpy ${_RESULT} "false"
				${DebugMsg} "Paths are on different volumes: $2 vs $3"
			${EndIf}
		${Else}
			StrCpy ${_RESULT} "false"
			${DebugMsg} "Cannot determine volume for path2: $1"
		${EndIf}
	${Else}
		StrCpy ${_RESULT} "false"
		${DebugMsg} "Cannot determine volume for path1: $0"
	${EndIf}
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if path supports reparse points (NTFS)
!define Link::SupportsReparsePoints `!insertmacro _Link::SupportsReparsePoints`
!macro _Link::SupportsReparsePoints _PATH _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	
	${ParseLocations} "${_PATH}" $R8
	
	; Get volume information
	System::Call 'Kernel32::GetVolumePathName(t "$R8", t .r0, i ${NSIS_MAX_STRLEN}) i .r1'
	${If} $1 != 0
		; Get file system type
		System::Call 'Kernel32::GetVolumeInformation(t "$0", i 0, i 0, i 0, i 0, i .r2, t .r3, i ${NSIS_MAX_STRLEN}) i .r1'
		${If} $1 != 0
			${If} $3 == "NTFS"
				StrCpy ${_RESULT} "true"
				${DebugMsg} "Path supports reparse points (NTFS): $0"
			${Else}
				StrCpy ${_RESULT} "false"
				${DebugMsg} "Path does not support reparse points ($3): $0"
			${EndIf}
		${Else}
			StrCpy ${_RESULT} "false"
			${DebugMsg} "Cannot determine file system for: $0"
		${EndIf}
	${Else}
		StrCpy ${_RESULT} "false"
		${DebugMsg} "Cannot determine volume for: $R8"
	${EndIf}
	
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Validate link configuration
!define Link::ValidateConfig `!insertmacro _Link::ValidateConfig`
!macro _Link::ValidateConfig _LINKPATH _TARGETPATH _LINKTYPE _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "true"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_LINKPATH}" $0
	${ParseLocations} "${_TARGETPATH}" $1
	
	; Validate paths are not the same
	${If} $0 == $1
		StrCpy ${_RESULT} "false"
		StrCpy ${_ERROR} "Link path and target path cannot be the same"
		Goto _VALIDATE_CONFIG_END
	${EndIf}
	
	; Validate target exists
	${IfNot} ${FileExists} "$1"
		StrCpy ${_RESULT} "false"
		StrCpy ${_ERROR} "Target path does not exist: $1"
		Goto _VALIDATE_CONFIG_END
	${EndIf}
	
	; Type-specific validations
	${Switch} "${_LINKTYPE}"
		${Case} "symbolic"
		${Case} "junction"
			; Check if file system supports reparse points
			${Link::SupportsReparsePoints} "$0" $2
			${If} $2 == "false"
				StrCpy ${_RESULT} "false"
				StrCpy ${_ERROR} "File system does not support symbolic links/junctions (requires NTFS)"
				Goto _VALIDATE_CONFIG_END
			${EndIf}
			${Break}
			
		${Case} "hardlink"
			; Check if both paths are on the same volume
			${Link::SameVolume} "$0" "$1" $2
			${If} $2 == "false"
				StrCpy ${_RESULT} "false"
				StrCpy ${_ERROR} "Hard links require both paths on the same volume"
				Goto _VALIDATE_CONFIG_END
			${EndIf}
			
			; Validate target is a file, not directory
			${If} ${FileExists} "$1\*.*"
				StrCpy ${_RESULT} "false"
				StrCpy ${_ERROR} "Hard link target must be a file, not a directory"
				Goto _VALIDATE_CONFIG_END
			${EndIf}
			${Break}
	${EndSwitch}
	
	; Validate link path parent directory exists or can be created
	${GetParent} "$0" $2
	${IfNot} ${FileExists} "$2"
		CreateDirectory "$2"
		${If} ${Errors}
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Cannot create parent directory: $2"
			Goto _VALIDATE_CONFIG_END
		${EndIf}
	${EndIf}
	
	_VALIDATE_CONFIG_END:
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check for circular link references
!define Link::CheckCircular `!insertmacro _Link::CheckCircular`
!macro _Link::CheckCircular _LINKPATH _TARGETPATH _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	
	${ParseLocations} "${_LINKPATH}" $R8
	${ParseLocations} "${_TARGETPATH}" $R9
	
	; Simple check: see if target path starts with link path
	StrLen $0 "$R8"
	StrCpy $1 "$R9" $0
	${If} $1 == "$R8"
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Circular reference detected: $R8 -> $R9"
		Goto _CIRCULAR_CHECK_END
	${EndIf}
	
	; More complex check: follow the chain of links
	StrCpy $2 "$R9" ; Current path to check
	StrCpy $3 0 ; Depth counter (prevent infinite loops)
	
	${Do}
		${Link::GetType} "$2" $4 $1 $0
		${If} $4 == "true"
			; It's a link, check if it points back to our link path
			${If} $1 == "$R8"
				StrCpy ${_RESULT} "true"
				${DebugMsg} "Circular reference detected in chain: $2 -> $1"
				${ExitDo}
			${EndIf}
			
			; Continue following the chain
			StrCpy $2 "$1"
			IntOp $3 $3 + 1
			
			; Prevent infinite loops
			${If} $3 > 10
				${DebugMsg} "Link chain too deep, stopping circular check"
				${ExitDo}
			${EndIf}
		${Else}
			; End of chain
			${ExitDo}
		${EndIf}
	${Loop}
	
	_CIRCULAR_CHECK_END:
	Pop $R9
	Pop $R8
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Get link statistics
!define Link::GetStatistics `!insertmacro _Link::GetStatistics`
!macro _Link::GetStatistics _SYMLINKS _JUNCTIONS _HARDLINKS _FAILED
	Push $0
	Push $1
	Push $R0
	
	StrCpy ${_SYMLINKS} "0"
	StrCpy ${_JUNCTIONS} "0"
	StrCpy ${_HARDLINKS} "0"
	StrCpy ${_FAILED} "0"
	
	; Count symbolic links
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 SymLink$R0 LinkPath
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${ReadRuntimeData} $1 LinkState "$0_Created"
		${IfNot} ${Errors}
			IntOp ${_SYMLINKS} ${_SYMLINKS} + 1
		${Else}
			${ReadRuntimeData} $1 LinkState "$0_Failed"
			${IfNot} ${Errors}
				IntOp ${_FAILED} ${_FAILED} + 1
			${EndIf}
		${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	
	; Count junctions
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 Junction$R0 JunctionPath
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${ReadRuntimeData} $1 JunctionState "$0_Created"
		${IfNot} ${Errors}
			IntOp ${_JUNCTIONS} ${_JUNCTIONS} + 1
		${Else}
			${ReadRuntimeData} $1 JunctionState "$0_Failed"
			${IfNot} ${Errors}
				IntOp ${_FAILED} ${_FAILED} + 1
			${EndIf}
		${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	
	; Count hard links
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 HardLink$R0 LinkPath
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${ReadRuntimeData} $1 HardLinkState "$0_Created"
		${IfNot} ${Errors}
			IntOp ${_HARDLINKS} ${_HARDLINKS} + 1
		${Else}
			${ReadRuntimeData} $1 HardLinkState "$0_Failed"
			${IfNot} ${Errors}
				IntOp ${_FAILED} ${_FAILED} + 1
			${EndIf}
		${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	
	Pop $R0
	Pop $1
	Pop $0
!macroend

${SegmentFile}

;= Enable symbolic links and junctions segment
!define SYMLINKSJUNCTIONS_ENABLED

;= Check permissions and backup existing links
${SegmentPre}
	!ifdef SYMLINKSJUNCTIONS_ENABLED
		${DebugMsg} "Processing symbolic links and junctions..."
		
		; Check if user can create symbolic links
		${Link::CanCreateSymLinks} $R9
		${If} $R9 == "false"
			${DebugMsg} "Warning: User cannot create symbolic links (insufficient privileges)"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Symbolic link creation requires 'Create symbolic links' privilege or administrator rights.$\n$\nSome features may not work correctly."
		${EndIf}
		
		; Process symbolic links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 SymLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 SymLink$R0 TargetPath
			${ReadLauncherConfig} $2 SymLink$R0 IfExists
			${ReadLauncherConfig} $3 SymLink$R0 Type
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "replace"
			${EndIf}
			
			; Validate target exists
			${ParseLocations} "$1" $R8
			${IfNot} ${FileExists} "$R8"
				${DebugMsg} "Symbolic link target does not exist: $R8"
				${WriteRuntimeData} LinkState "$0_Failed" "target_not_found"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing symbolic link: $0 -> $1"
			
			; Check if link path exists
			${If} ${FileExists} "$0"
				${DebugMsg} "Link path exists: $0"
				
				${Switch} $2
					${Case} "skip"
						${DebugMsg} "Skipping existing path: $0"
						${WriteRuntimeData} LinkState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${Case} "update"
					${CaseElse}
						${Link::Backup} "$0" "LinkBackup" "$0"
						${WriteRuntimeData} LinkState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Link path does not exist: $0"
				${WriteRuntimeData} LinkState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Process junctions
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Junction$R0 JunctionPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Junction$R0 TargetPath
			${ReadLauncherConfig} $2 Junction$R0 IfExists
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "replace"
			${EndIf}
			
			; Validate target directory exists
			${ParseLocations} "$1" $R8
			${IfNot} ${FileExists} "$R8\*.*"
				${DebugMsg} "Junction target directory does not exist: $R8"
				${WriteRuntimeData} JunctionState "$0_Failed" "target_not_found"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing junction: $0 -> $1"
			
			; Check if junction path exists
			${If} ${FileExists} "$0"
				${DebugMsg} "Junction path exists: $0"
				
				${Switch} $2
					${Case} "skip"
						${DebugMsg} "Skipping existing path: $0"
						${WriteRuntimeData} JunctionState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${CaseElse}
						${Link::Backup} "$0" "JunctionBackup" "$0"
						${WriteRuntimeData} JunctionState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Junction path does not exist: $0"
				${WriteRuntimeData} JunctionState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Process hard links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 HardLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 HardLink$R0 TargetPath
			${ReadLauncherConfig} $2 HardLink$R0 IfExists
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "replace"
			${EndIf}
			
			; Validate target file exists and is not a directory
			${ParseLocations} "$1" $R8
			${IfNot} ${FileExists} "$R8"
				${DebugMsg} "Hard link target file does not exist: $R8"
				${WriteRuntimeData} HardLinkState "$0_Failed" "target_not_found"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${If} ${FileExists} "$R8\*.*"
				${DebugMsg} "Hard link target is a directory: $R8"
				${WriteRuntimeData} HardLinkState "$0_Failed" "target_is_directory"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing hard link: $0 -> $1"
			
			; Check if link path exists
			${If} ${FileExists} "$0"
				${DebugMsg} "Hard link path exists: $0"
				
				${Switch} $2
					${Case} "skip"
						${DebugMsg} "Skipping existing path: $0"
						${WriteRuntimeData} HardLinkState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${CaseElse}
						${Link::Backup} "$0" "HardLinkBackup" "$0"
						${WriteRuntimeData} HardLinkState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Hard link path does not exist: $0"
				${WriteRuntimeData} HardLinkState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Links and junctions processing completed."
	!endif
!macroend

;= Create symbolic links, junctions, and hard links
${SegmentPrePrimary}
	!ifdef SYMLINKSJUNCTIONS_ENABLED
		${DebugMsg} "Creating symbolic links, junctions, and hard links..."
		
		; Create symbolic links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 SymLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this link
			${ReadRuntimeData} $1 LinkState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping symbolic link as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 LinkState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping symbolic link due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 SymLink$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot create required symbolic link '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 SymLink$R0 TargetPath
			${ReadLauncherConfig} $2 SymLink$R0 Type
			${ReadLauncherConfig} $3 SymLink$R0 Relative
			${ReadLauncherConfig} $4 SymLink$R0 Required
			
			; Set defaults
			${If} $3 == ""
				StrCpy $3 "false"
			${EndIf}
			
			; Remove existing path if we're replacing
			${ReadRuntimeData} $5 LinkState "$0_Action"
			${If} $5 == "backup"
				${If} ${FileExists} "$0"
					${Link::GetType} "$0" $R8 $R9 $R7
					${If} $R8 == "true"
						${Link::Remove} "$0" "$R7" $R8 $R9
					${Else}
						; Regular file/directory was backed up
						; It should have been moved during backup
					${EndIf}
				${EndIf}
			${EndIf}
			
			${DebugMsg} "Creating symbolic link: $0 -> $1"
			
			; Create the symbolic link
			${SymLink::Create} "$0" "$1" "$2" "$3" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} LinkState "$0_Created" "true"
				${WriteRuntimeData} LinkState "$0_LinkPath" "$0"
				${WriteRuntimeData} LinkState "$0_TargetPath" "$1"
				${WriteRuntimeData} LinkState "$0_Type" "symbolic"
				${DebugMsg} "Symbolic link created successfully: $0"
			${Else}
				${WriteRuntimeData} LinkState "$0_Failed" "$R9"
				${DebugMsg} "Failed to create symbolic link $0: $R9"
				${If} $4 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to create required symbolic link '$0'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Create junctions
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Junction$R0 JunctionPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this junction
			${ReadRuntimeData} $1 JunctionState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping junction as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 JunctionState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping junction due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 Junction$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot create required junction '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 Junction$R0 TargetPath
			${ReadLauncherConfig} $2 Junction$R0 Required
			
			; Remove existing path if we're replacing
			${ReadRuntimeData} $3 JunctionState "$0_Action"
			${If} $3 == "backup"
				${If} ${FileExists} "$0"
					${Link::GetType} "$0" $R8 $R9 $R7
					${If} $R8 == "true"
						${Link::Remove} "$0" "$R7" $R8 $R9
					${EndIf}
				${EndIf}
			${EndIf}
			
			${DebugMsg} "Creating junction: $0 -> $1"
			
			; Create the junction
			${Junction::Create} "$0" "$1" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} JunctionState "$0_Created" "true"
				${WriteRuntimeData} JunctionState "$0_JunctionPath" "$0"
				${WriteRuntimeData} JunctionState "$0_TargetPath" "$1"
				${DebugMsg} "Junction created successfully: $0"
			${Else}
				${WriteRuntimeData} JunctionState "$0_Failed" "$R9"
				${DebugMsg} "Failed to create junction $0: $R9"
				${If} $2 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to create required junction '$0'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Create hard links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 HardLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this hard link
			${ReadRuntimeData} $1 HardLinkState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping hard link as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 HardLinkState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping hard link due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 HardLink$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot create required hard link '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 HardLink$R0 TargetPath
			${ReadLauncherConfig} $2 HardLink$R0 Required
			
			; Remove existing file if we're replacing
			${ReadRuntimeData} $3 HardLinkState "$0_Action"
			${If} $3 == "backup"
				${If} ${FileExists} "$0"
					; Regular file was backed up during Link::Backup
				${EndIf}
			${EndIf}
			
			${DebugMsg} "Creating hard link: $0 -> $1"
			
			; Create the hard link
			${HardLink::Create} "$0" "$1" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} HardLinkState "$0_Created" "true"
				${WriteRuntimeData} HardLinkState "$0_LinkPath" "$0"
				${WriteRuntimeData} HardLinkState "$0_TargetPath" "$1"
				${DebugMsg} "Hard link created successfully: $0"
			${Else}
				${WriteRuntimeData} HardLinkState "$0_Failed" "$R9"
				${DebugMsg} "Failed to create hard link $0: $R9"
				${If} $2 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to create required hard link '$0'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Links and junctions creation completed."
	!endif
!macroend

;= Remove created links and junctions
${SegmentPostPrimary}
	!ifdef SYMLINKSJUNCTIONS_ENABLED
		${DebugMsg} "Removing created links and junctions..."
		
		; Remove hard links first (to avoid affecting file reference counts)
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 HardLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this hard link and if it should be temporary
			${ReadRuntimeData} $1 HardLinkState "$0_Created"
			${ReadLauncherConfig} $2 HardLink$R0 Temporary
			${If} $2 == ""
				StrCpy $2 "true" ; Default to temporary
			${EndIf}
			
			${If} $1 == "true"
			${AndIf} $2 == "true"
				${Link::Remove} "$0" "hardlink" $R8 $R7
				${If} $R8 == "true"
					${DebugMsg} "Hard link removed successfully: $0"
				${Else}
					${DebugMsg} "Failed to remove hard link $0: $R7"
				${EndIf}
			${ElseIf} $1 == "true"
				${DebugMsg} "Keeping persistent hard link: $0"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Remove symbolic links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 SymLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this link and if it should be temporary
			${ReadRuntimeData} $1 LinkState "$0_Created"
			${ReadLauncherConfig} $2 SymLink$R0 Temporary
			${If} $2 == ""
				StrCpy $2 "true" ; Default to temporary
			${EndIf}
			
			${If} $1 == "true"
			${AndIf} $2 == "true"
				; Determine link type for proper removal
				${Link::GetType} "$0" $R8 $R9 $R7
				${If} $R8 == "true"
					${Link::Remove} "$0" "$R7" $R8 $R9
					${If} $R8 == "true"
						${DebugMsg} "Symbolic link removed successfully: $0"
					${Else}
						${DebugMsg} "Failed to remove symbolic link $0: $R9"
					${EndIf}
				${EndIf}
			${ElseIf} $1 == "true"
				${DebugMsg} "Keeping persistent symbolic link: $0"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Remove junctions
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Junction$R0 JunctionPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this junction and if it should be temporary
			${ReadRuntimeData} $1 JunctionState "$0_Created"
			${ReadLauncherConfig} $2 Junction$R0 Temporary
			${If} $2 == ""
				StrCpy $2 "true" ; Default to temporary
			${EndIf}
			
			${If} $1 == "true"
			${AndIf} $2 == "true"
				${Link::Remove} "$0" "junction" $R8 $R7
				${If} $R8 == "true"
					${DebugMsg} "Junction removed successfully: $0"
				${Else}
					${DebugMsg} "Failed to remove junction $0: $R7"
				${EndIf}
			${ElseIf} $1 == "true"
				${DebugMsg} "Keeping persistent junction: $0"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Links and junctions removal completed."
	!endif
!macroend

;= Restore original files and directories
${SegmentUnload}
	!ifdef SYMLINKSJUNCTIONS_ENABLED
		${DebugMsg} "Restoring original files and directories..."
		
		; Restore symbolic links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 SymLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this link
			${ReadRuntimeData} $1 LinkState "$0_Action"
			${If} $1 == "backup"
				${Link::Restore} "$0" "LinkBackup" "$0" $R8
				${If} $R8 == "true"
					${DebugMsg} "Symbolic link restored: $0"
				${Else}
					${DebugMsg} "Failed to restore symbolic link: $0"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Restore junctions
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Junction$R0 JunctionPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this junction
			${ReadRuntimeData} $1 JunctionState "$0_Action"
			${If} $1 == "backup"
				${Link::Restore} "$0" "JunctionBackup" "$0" $R8
				${If} $R8 == "true"
					${DebugMsg} "Junction restored: $0"
				${Else}
					${DebugMsg} "Failed to restore junction: $0"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Restore hard links
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 HardLink$R0 LinkPath
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this hard link
			${ReadRuntimeData} $1 HardLinkState "$0_Action"
			${If} $1 == "backup"
				${Link::Restore} "$0" "HardLinkBackup" "$0" $R8
				${If} $R8 == "true"
					${DebugMsg} "Hard link restored: $0"
				${Else}
					${DebugMsg} "Failed to restore hard link: $0"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Links and junctions restoration completed."
	!endif
!macroend

!endif
