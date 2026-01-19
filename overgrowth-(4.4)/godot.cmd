@echo off
setlocal
set "EXE=%~dp0tools\godot\Godot_v4.4.1-stable_win64_console.exe"
if not exist "%EXE%" (
  echo Could not find "%EXE%"
  exit /b 1
)
"%EXE%" %*
endlocal
