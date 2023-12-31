REM Boot checks

SETLOCAL
ECHO %computername% |findstr /i SERVER && EXIT 

:TIMERS
REM regolo l'orologio e lo imposto perché recuperi sempre l'ora dal web 
sc config w32time start= auto &
net start w32time
w32tm /config /manualpeerlist:"tempo.ien.it"
w32tm /resync /nowait 
net localgroup masters && GOTO POL
net localgroup masters /add
net localgroup masters docenti /add

SET LS=192.168.100.2
REM verifico che il server web locale sia raggiungibile (se non sono a scuola non lo è)
ping -n 1 -i 1 %LS% || GOTO :OFFSITE

:POL
REM aggiorno le policy di sicurezza (utile per )
set UCS=http://192.168.100.2/sw/Registry.pol
curl -o %temp%\Registry.pol %UCS% && move %temp%\Registry.pol C:\Windows\System32\GroupPolicy\Machine
gpupdate /force & 

:PRN
wmic printer list brief |findstr /i DIDATTICA && GOTO VEYON
set UCP=http://192.168.100.2/sw/d.prn
curl -o %temp%\d.prn %UCP% && C:\Windows\System32\spool\tools\PrintBrm.exe -R -f %temp%\d.prn

:VEYON
sc query |findstr /i veyon && GOTO VEYONCONF
set UCS=http://192.168.100.2/sw/veyonSetup.exe
set CNF=http://192.168.100.2/sw/vs.json
curl -o %temp%\vs.json %CNF% 
curl -o %temp%\vs.exe %UCS% && %temp%\vs.exe /S /ApplyConfig=%TEMP%\vs.json 
GOTO CURA

:VEYONCONF
set CNF=http://192.168.100.2/sw/vs.json
curl -o %temp%\vs.json %CNF% 
"C:\PROGRAM FILES\VEYON\veyon-cli.exe" config import %temp%\vs.json

:CURA
wmic product where "name like '%Ultimaker Cura%'" && GOTO CDS
set UCS=http://192.168.100.2/sw/cura.msi
curl -o %temp%\cura.msi %UCS% && %temp%\cura.msi /passive /norestart
set UCS=http://192.168.100.2/sw/cura.exe
curl -o %temp%\cura.exe %UCS% && %temp%\cura.exe -y
move %temp%\cura c:\users\default\appdata\roaming

:CDS

dir c:\apps\cds\c*.exe && GOTO FIX
set UCS=http://192.168.100.2/sw/cds.exe
curl -o %temp%\cds.exe %UCS% && %temp%\cds.exe -y
move %temp%\CdS c:\Apps\
copy "c:\apps\cds\Cricut Design Space.lnk" c:\users\public\desktop

:OFFSITE

:FIX
icacls c:\apps\cds /grant everyone:F /T

:LOG
REM winget install -h --disable-interactivity "Chimpa Agent"
REM admin@chimpa.private -> https://cloud.chimpa.eu/iccasetti/api/latest/mdm/windows/discovery_windows
ECHO %USERNAME% > %TEMP%\wb.LOG
