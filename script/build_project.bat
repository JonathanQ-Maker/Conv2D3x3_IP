@REM source vivado env variables. THIS IS SYSTEM SPECIFIC, change to match your system.
CALL C:\InstalledPrograms\Xilinx\Vivado\2023.2\settings64.bat

@REM Run build project tcl script
vivado -nolog -nojournal -mode batch -source .\script\build_project.tcl