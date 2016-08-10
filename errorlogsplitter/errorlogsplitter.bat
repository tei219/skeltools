@echo off
setlocal
pushd %CD%
cd /d %~d0%~p0

set filename=
if "%1"=="" (
	set filename=ERRORLOG
) else (
	set filename=%1
)

echo set foldername by %filename% ...
type %filename% | bin\gawk.exe "NR=1 {gsub(/[:.]/,""-""""); time = $1 ""_"""" $2} NR<50 {if ($0 ~ /Server name is/){svr=gensub(/(.*)'(.*)'(.*)/,""\\2"""",""""""); print svr ""_"""" time}}" > foldername
for /f "usebackq" %%a in (`type foldername`) do (
	set foldername=%%a
)
del /f foldername

echo splitting %filename% ...
type %filename% | bin\awk.exe "{if ($3 ~ /^spid[0-9][0-9]*s/) {fn=$3.spid; print $0 > $3 "".spid""""; fflush();}}" 1>nul

for /f "usebackq" %%a in (`dir /b *.spid`) do (
	echo dividing %%a ...
	start "dividing %%a" /d . /min /low cmd /c "echo 1 > %%a.processing && type %%a | cscript lib\divide.vbs /file:%%a && del %%a.processing"
	bin\sleep.exe 1
)

echo waiting ...
:CHKLOOP1
	dir /b *.processing 2>nul 1>chk
	call :CHKFILESIZE chk
	if exist chk (
		bin\sleep.exe 10
		goto :CHKLOOP1
	)
echo done.

echo cleaning ...
del /f *.spid

echo organizing ...
set deadlockfolder=deadlock\%foldername%
mkdir 2>nul %deadlockfolder%
(move 1>nul *.deadlock %deadlockfolder% 2>&1) || (echo *no deadlock && echo 1 > %deadlockfolder%\no_deadlock && goto :DETECTNODEADLOCK)

echo generate result (deadlock.txt) ...
dir /b %deadlockfolder% | bin\gawk.exe "{ print substr($1,0,index($1,""-"""")-1); }" | bin\uniq.exe > list

call :CHKFILESIZE list

for /f %%a in (list) do (
	echo extracting %%a ...
	@start "extract %%a" /d . /min /low cmd /c "echo 1 > %%a.processing && (for /f ""usebackq"" %%i in ('dir /b /s %deadlockfolder%\%%a*.deadlock') do ( cscript lib\extracter.wsf /logbase:%%a /file:%%i /outfn:%%a-deadlock.txt )) && del %%a.processing"
	bin\sleep.exe 1
)

echo waiting ...
:CHKLOOP2
	dir /b *.processing 2>nul 1>chk
	call :CHKFILESIZE chk
	if exist chk (
		bin\sleep.exe 10
		goto :CHKLOOP2
	)
echo done.

echo organizing ...
:DETECTNODEADLOCK
if exist %deadlockfolder%\no_deadlock (
	echo %deadlockfolder% ^(no deadlock^) >> deadlock.txt
) else (
	echo %deadlockfolder% >> deadlock.txt
	for /f "usebackq" %%a in (`dir 2^>nul /b spid*deadlock.txt`) do (
		type %%a >> deadlock.txt
	)

	echo cleaning ...
	del 2>nul /f list
	del 2>nul /f spid*deadlock.txt
)

echo finished.
echo ----- ERRORLOG SPLITTER -----
echo splitted '%filename%' as .deadlock is stored in '%deadlockfolder%'
echo check 'deadlock.txt' 
echo. 
echo - NOTE -
echo deadlock.txt shows summary of deadlock-list occurred in 2 processes.
echo please refer to each .deadlock file for the detail of deadlock that occurred in 3 or more processes.
echo use deadlocktxt_template.xls to see deadlock.txt
echo ----- ----------------- -----

:EOB
popd
endlocal
if exist debug ( pause )
goto :EOF

rem ---
:CHKFILESIZE
	if "%~z1"=="0" (
		del /f %1
	)
exit /b
