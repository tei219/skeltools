@echo off
if "%~d0"=="\\" (
	echo.
	echo [ERR ] - not support UNC
	pause
	goto :EOF
)
setlocal
pushd %CD%
cd /d %~d0%~p0

rem https://msdn.microsoft.com/ja-jp/library/hh925568(v=vs.110).aspx?cs-save-lang=1&cs-lang=csharp#code-snippet-2
set regkey0="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP"
set regkey1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

rem detect version 1-4
for /f "usebackq delims=\ tokens=1-6" %%a in (`reg query %regkey0%`) do (
	rem echo %%a\%%b\%%c\%%d\%%e\%%f
	reg query "%%a\%%b\%%c\%%d\%%e\%%f" | (findstr /C:"Install    REG_DWORD    0x1" 1>nul && echo installed .NET Framework %%f) 
)

rem detect above 4
for /f "usebackq tokens=3" %%a in (`reg query %regkey1% 2^>nul ^| findstr "Release"`) do (
	if "%%a"=="0x5c615" ( echo installed .NET Framework v4.5 )
	if "%%a"=="0x5c733" ( echo installed .NET Framework v4.5.1 [8.1/2012R2] )
	if "%%a"=="0x5c786" ( echo installed .NET Framework v4.5.1 [8/7 SP1/Vista SP2] )
	if "%%a"=="0x5cbf5" ( echo installed .NET Framework v4.5.2 )
	if "%%a"=="0x6004F" ( echo installed .NET Framework v4.6 [10] )
	if "%%a"=="0x60051" ( echo installed .NET Framework v4.6 [Non-10] )
	if "%%a"=="0x6040E" ( echo installed .NET Framework v4.6.1 [10] )
	if "%%a"=="0x6041f" ( echo installed .NET Framework v4.6.1 [Non-10] )
)


:EOB
popd
endlocal
pause
goto :EOF
