@echo off
goto :INIT

::
:: PORTABLEAPPS COMPILER
:: Developed by daemon.devin (daemon.devin@gmail.com)
::
:: For support, visit the GitHub project:
:: https://github.com/daemondevin/pac-man
::
:: Sign.bat
::	This batch utility is executed from within the LauncherCompiler.nsi file.
::	It can also be used as a standalone if you pass certain parameters it needs.
:: 

:HEADER
	echo.
	echo  %__NAME% (%__VERSION%)
	echo  by daemon.devin
    echo.
    goto :EOF
	
:GET_STARTED
	echo To get started, enter /? or --help
    echo.
	goto :EOF

:SWITCH_HELP	
	if [%~1]==[] goto :USAGE_HELP
	
	if [%~1]==[/t] goto :HELP_TIMESTAMP
	if [%~1]==[-t] goto :HELP_TIMESTAMP
	if [%~1]==[--timestamp] goto :HELP_TIMESTAMP
	
	if [%~1]==[/p] goto :HELP_PASSWORD
	if [%~1]==[-p] goto :HELP_PASSWORD
	if [%~1]==[--password] goto :HELP_PASSWORD
	
	if [%~1]==[/p] goto :HELP_HASHES
	if [%~1]==[-p] goto :HELP_HASHES
	if [%~1]==[--password] goto :HELP_HASHES

	goto :USAGE_HELP

:USAGE_HELP
	echo Sign a specified binary using SHA1/SHA256 hashes with an optional timestamp.
	echo.
	echo  USAGE:
	echo.    %__BAT_NAME% [switch "switch value"]
    echo.
	echo  SWITCH:
	echo.    /?, --help              ^| Displays this help text
	echo.    /h, --hashing   "value" ^| which hash to sign with; SHA1 or SHA256
	echo.    /p, --password  "value" ^| Specify a password if you need one
	echo.    /t, --timestamp "value" ^| Lists available timestamp providers
	echo.
	echo.    /?, --help [switch]     ^| Will display the help text for that switch
	echo.
	echo  EXAMPLE:
	echo    Sign a binary using Comodo timestamp
	echo.      %__BAT_NAME% /t "Comodo" /c "C:\cert.pfx" /f "C:\AppNamePortable.exe"
	echo.
	echo    Sign a binary using abc123 as the password for the certificate
	echo.      %__BAT_NAME% -p "abc123" -c "C:\cert.pfx" -f "C:\AppNamePortable.exe"
	echo.
	echo    Show help text for different switch parameters
	echo.      %__BAT_NAME% /? --file   ^| Displays the binary file help text
	echo.      %__BAT_NAME% /? -t       ^| Displays the timestamp help text
	echo.      %__BAT_NAME% --help -p   ^| Displays the password help text
	echo.
    goto :EOF

:HELP_FILE
	echo  The full path to the binary file to have signed
	echo     required
    echo.
	echo  USAGE:
	echo    %__BAT_NAME% "C:\7-ZipPortable\7-ZipPortable.exe"
	echo.
    goto :EOF

:HELP_PASSWORD
	echo  Specifies a password if your certificate requires one
	echo     optional
    echo.
	echo  USAGE:
	echo    %__BAT_NAME% /p "password"
	echo.
    goto :EOF

:HELP_TIMESTAMP
	echo  Timestamp providers and their available hashes.
	echo     optional
    echo.
	echo  	PROVIDERS	 ALGORITHMS
	echo.
	echo  	Comodo		SHA1, SHA256
	echo  	Verisign	SHA1, SHA256
	echo  	GlobalSign	SHA1, SHA256
	echo  	DigiCert	SHA1, SHA256
	echo  	Starfield	SHA1, SHA256
	echo  	SwissSign	SHA1
    echo.
	echo  USAGE:
	echo    %__BAT_NAME% /t "Comodo" "C:\7-ZipPortable\7-ZipPortable.exe"
	echo    %__BAT_NAME% /t "GlobalSign" "C:\7-ZipPortable\7-ZipPortable.exe"
	echo.
    goto :EOF

:INIT
	set "__NAME=PAC-MAN LAUNCHER SIGNER"
    set "__FILENAME=%~n0"
    set "__VERSION=1.0"
    set "__YEAR=2018"
	
    set "__BAT_FILE=%~0"
    set "__BAT_PATH=%~dp0"
    set "__BAT_NAME=%~nx0"

    set "__BINARY=%~5"
	set "__HASH=%~4"
    set "__TIMESTAMP=%~3"
    set "__PASSWORD=%~2"
    set "__CERTIFICATE=%~1"

	if [%__TIMESTAMP%]==[Comodo] (
	
		set "__TS_SHA1 "http://timestamp.comodoca.com"
		set "__TS_SHA256 "http://timestamp.comodoca.com/?td=sha256"
	)
	
	if [%__TIMESTAMP%]==[Verisign] (
	
		set "__TS_SHA1 "http://timestamp.verisign.com/scripts/timstamp.dll"
		set "__TS_SHA256 "http://sha256timestamp.ws.symantec.com/sha256/timestamp"
	)
	
	if [%__TIMESTAMP%]==[GlobalSign] (

		set "__TS_SHA1 "http://timestamp.globalsign.com/scripts/timstamp.dll"
		set "__TS_SHA256 "http://timestamp.globalsign.com/?signature=sha2"
	)

	if [%__TIMESTAMP%]==[DigiCert] (

		set "__TS_SHA1 "http://timestamp.digicert.com"
		set "__TS_SHA256 "http://timestamp.digicert.com"
	)

	if [%__TIMESTAMP%]==[Starfield] (

		set "__TS_SHA1 "http://tsa.starfieldtech.com"
		set "__TS_SHA256 "http://tsa.starfieldtech.com"
	)

	if [%__TIMESTAMP%]==[SwissSign] (

		set "__TS_SHA1 "http://tsa.swisssign.net"
		set "__TS_SHA256 "http://tsa.swisssign.net"
	)

	set "__SIGNTOOL=%__BAT_PATH%\Contrib\bin\signtool.exe"

:PARSE
    if "%~1"=="" goto :VALIDATE

	if /i "%~1"=="/?"			call :SWITCH_HELP "%~2" & goto :END
	if /i "%~1"=="-?"			call :SWITCH_HELP "%~2" & goto :END
	if /i "%~1"=="--help"		call :SWITCH_HELP "%~2" & goto :END

	if /i "%~1"=="/c"			set "__CERTIFICATE=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="-c"			set "__CERTIFICATE=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="--cert"		set "__CERTIFICATE=%~2"	& shift & shift & goto :PARSE

	if /i "%~1"=="/p" 			set "__PASSWORD=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="-p" 			set "__PASSWORD=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="--password" 	set "__PASSWORD=%~2"	& shift & shift & goto :PARSE

	if /i "%~1"=="/t" 			set "__TIMESTAMP=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="-t" 			set "__TIMESTAMP=%~2"	& shift & shift & goto :PARSE
	if /i "%~1"=="--timestamp" 	set "__TIMESTAMP=%~2"	& shift & shift & goto :PARSE

	if /i "%~1"=="/h"			set "__HASH=%~2"		& shift & shift & goto :PARSE
	if /i "%~1"=="-h"			set "__HASH=%~2"		& shift & shift & goto :PARSE
	if /i "%~1"=="--hash"		set "__HASG=%~2"		& shift & shift & goto :PARSE

	if /i "%~1"=="/f"			set "__BINARY=%~2"		& shift & shift & goto :PARSE
	if /i "%~1"=="-f"			set "__BINARY=%~2"		& shift & shift & goto :PARSE
	if /i "%~1"=="--file"		set "__BINARY=%~2"		& shift & shift & goto :PARSE

    shift
    goto :PARSE

:VALIDATE
    if not defined __BINARY call :MISSING_BINARY & goto :END
    if not defined __CERTIFICATE call :MISSING_CERTIFICATE & goto :END

:MAIN
	if [%__HASH%]==[SHA256] (
	
		%__SIGNTOOL% sign /f %__CERTIFICATE% /p %__PASSWORD% /fd sha256 /tr %__TS_SHA256% /td sha256 /as /v %__BINARY%
	
	) 
	if [%__HASH%]==[SHA1] (
	
		%__SIGNTOOL% sign /f %__CERTIFICATE% /p %__PASSWORD% /t %__TS_SHA1% /v %__BINARY%
	
	)

:MISSING_BINARY
    call :HEADER
    echo.
	echo  CANNOT LOCATE FILE
    echo.
	echo  Please specify a full path to the binary executable you want to sign
	echo.
	call :USAGE_HELP
    goto :EOF

:MISSING_CERTIFICATE
    call :HEADER
    echo.
	echo  CANNOT LOCATE CERTIFICATE
    echo.
	echo  Please specify a full path to the certificate to sign with
	echo.
	call :USAGE_HELP
    goto :EOF

:END
    call :RESET
    exit /B

:RESET
    set "__NAME="
    set "__FILENAME="
    set "__VERSION="
    set "__YEAR="

    set "__BAT_FILE="
    set "__BAT_PATH="
    set "__BAT_NAME="

    set "__VERBOSE="

    set "__BINARY="
	set "__HASH="
    set "__TIMESTAMP="
    set "__PASSWORD="
	set "__CERTIFICATE="

    goto :EOF
	