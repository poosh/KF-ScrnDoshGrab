@echo off

rem DON'T FORGET to Duplicate HumanPawn and PlayerController class code to the SZ_ScrnBalance!

setlocal
set KFDIR=d:\Games\kf
set STEAMDIR=c:\Steam\steamapps\common\KillingFloor
set outputdir=D:\KFOut\ScrnDoshGrab

echo Removing previous release files...
del /S /Q %outputdir%\*


echo Compiling project...
call make.cmd
if %ERRORLEVEL% NEQ 0 goto end

echo Exporting .int file...
%KFDIR%\system\ucc dumpint ScrnDoshGrab.u


echo.
echo Copying release files...
mkdir %outputdir%\System
mkdir %outputdir%\uz2


copy /y %KFDIR%\System\ScrnDoshGrab.* %outputdir%\system\
copy /y *.ini  %outputdir%


echo Compressing to .uz2...
%KFDIR%\System\ucc compress %KFDIR%\System\ScrnDoshGrab.u

move /y %KFDIR%\System\ScrnDoshGrab.u.uz2 %outputdir%\uz2

echo Release is ready!

endlocal

pause

:end
