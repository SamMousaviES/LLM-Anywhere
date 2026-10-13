@echo off
setlocal
cd /d "%~dp0"
set "MODELS=%~dp0models"
set "PLLM_PORT=%PORTABLELLM_PORT%"
if not defined PLLM_PORT set "PLLM_PORT=8080"
set "PLLM_CONTEXT=%PORTABLELLM_CONTEXT_SIZE%"
if not defined PLLM_CONTEXT set "PLLM_CONTEXT=8192"
set "PLLM_BACKEND=%PORTABLELLM_BACKEND%"
if not defined PLLM_BACKEND set "PLLM_BACKEND=auto"
set "GPU=bin\windows-vulkan\llama-server.exe"
set "CPU=bin\windows-cpu\llama-server.exe"
if exist "%CPU%" goto RUNTIME_FOUND
if exist "%GPU%" goto RUNTIME_FOUND
(
  echo llama.cpp runtime not found.
  echo Run: powershell -ExecutionPolicy Bypass -File .\Setup-Windows.ps1
  pause
  exit /b 1
)
:RUNTIME_FOUND
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Generate-Continue-Config.ps1" -ModelsDir "%MODELS%" -OutputPath "%~dp0continue-config.yaml" -ServerPort "%PLLM_PORT%"
if errorlevel 1 (
  echo Could not generate the Continue configuration.
  pause
  exit /b 1
)
if /I "%PLLM_BACKEND%"=="cpu" goto CPU
if not exist "%GPU%" goto CPU
"%GPU%" --list-devices 2>nul | findstr /R /C:"Vulkan[0-9]" >nul
if errorlevel 1 goto CPU
echo Vulkan GPU found. Multi-model mode. Open http://127.0.0.1:%PLLM_PORT%
echo Continue setup: see %~dp0docs\CONTINUE.md
"%GPU%" --models-dir "%MODELS%" --models-max 1 --models-autoload -c "%PLLM_CONTEXT%" -ngl 20 --no-kv-offload --host 127.0.0.1 --port "%PLLM_PORT%"
if not errorlevel 1 exit /b 0
:CPU
if not exist "%CPU%" (
  echo CPU runtime not found. Run Setup-Windows.ps1 -Backend cpu.
  pause
  exit /b 1
)
echo Starting CPU multi-model mode. Open http://127.0.0.1:%PLLM_PORT%
echo Continue setup: see %~dp0docs\CONTINUE.md
"%CPU%" --models-dir "%MODELS%" --models-max 1 --models-autoload -c "%PLLM_CONTEXT%" -ngl 0 --host 127.0.0.1 --port "%PLLM_PORT%"
pause
