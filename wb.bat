REM Boot checks

SETLOCAL
ECHO %computername% |findstr /i SERVER && EXIT 

:TIMERS
REM regolo l'orologio e lo imposto perché recuperi sempre l'ora dal web 
sc config w32time start= auto &
net start w32time
w32tm /config /manualpeerlist:"tempo.ien.it"
w32tm /resync /nowait 

%LS%=VRFS

REM verifico che il server web locale sia raggiungibile (se non sono a scuola non lo è)
ping -n 1 -i 1 %LS% || GOTO :OFFSITE

:POL
REM aggiorno le policy di sicurezza (utile per )
set UCS=http://VRFS/sw/Registry.pol
curl -o %temp%\Registry.pol %UCS% && move %temp%\Registry.pol C:\Windows\System32\GroupPolicy\Machine
gpupdate /force & 

:PRN
wmic printer list brief |findstr /i DIDATTICA && GOTO VEYON
set UCP=http://VRFS/sw/d.prn
curl -o %temp%\d.prn %UCP% && C:\Windows\System32\spool\tools\PrintBrm.exe -R -f %temp%\d.prn

:VEYON
sc query |findstr /i veyon && GOTO VEYONCONF
set UCS=http://VRFS/sw/veyonSetup.exe
set CNF=http://VRFS/sw/vs.json
curl -o %temp%\vs.json %CNF% 
curl -o %temp%\vs.exe %UCS% && %temp%\vs.exe /S /ApplyConfig=%TEMP%\vs.json 
GOTO CURA

:VEYONCONF
set CNF=http://VRFS/sw/vs.json
curl -o %temp%\vs.json %CNF% 
"C:\PROGRAM FILES\VEYON\veyon-cli.exe" config import %temp%\vs.json

:OFFSITE

:FIX

:LOG

ECHO %USERNAME% > %TEMP%\wb.LOG
