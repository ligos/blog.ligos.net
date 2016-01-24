rem Windows System Image script
rem (c) Murray Grant 2016

rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem 
rem http://www.apache.org/licenses/LICENSE-2.0
rem 
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.


rem Configuration

rem The drive letter of your USB disk
SET BACKUPDRIVE=m:
rem A password to use on your backup (yes, you should have one).
SET BACKUPPASSWORD=somePassword
rem A network location to copy the backup to (optional). 
SET NETWORKBACKUP=\\COMPUTER\Backups

rem End configuration


rem Get the current date (http://stackoverflow.com/a/203116)
for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
set today=%Year%-%Month%-%Day%

rem Run Windows Backup and create a system image to the USB disk.
wbadmin start backup -backuptarget:%BACKUPDRIVE% -include:c: -allCritical -quiet

rem Delete any old backups (which were compressed.
del /q "%BACKUPDRIVE%\WindowsImageBackup\%COMPUTERNAME%*.7z.*"

rem Start 7-zip to compress the backup.
START "7-Zip Backup" /B /I /LOW /WAIT "C:\Program Files\7-Zip\7z.exe" a -r -mx1 -v1g -p%BACKUPPASSWORD% "%BACKUPDRIVE%:\WindowsImageBackup\%COMPUTERNAME%-SystemImage-%today%.7z" "%BACKUPDRIVE%:\WindowsImageBackup\%COMPUTERNAME%\*"

rem Delete the uncompressed backup files, if 7-zip completed successfully.
if %ERRORLEVEL% NEQ 1 GOTO AfterDelete
del /s /q "%BACKUPDRIVE%\WindowsImageBackup\%COMPUTERNAME%"

rem Copies the compressed backup files to another computer on the network. 
:AfterDelete
robocopy /mir /j /z /r:5 /w:15 %BACKUPDRIVE%\WindowsImageBackup "%NETWORKBACKUP%\SystemImages\%COMPUTERNAME%" *.7z.*