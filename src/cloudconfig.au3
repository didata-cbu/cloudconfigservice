#pragma compile(Console, true)
; Change this to 'false' to build a 32-bit binary
#pragma compile(x64, true)
#pragma compile(UPX, true)
; The name of the binary to generate
#pragma compile(Out, cloudconfig.exe)
; The icon to use as the progrma icon (gets jammed into binary)
#pragma compile(Icon, Bogo-D-Project-Disk-iDisk.ico)
; Icon courtesy http://bogo-d.deviantart.com
; Ownership info
#pragma compile(CompanyName, 'Dimension Data')
#pragma compile(FileDescription, 'Cloud Config Service')
#pragma compile(Comments, 'Cloud Config Service')
#pragma compile(FileVersion, 1.3.1.2)
#pragma compile(InternalName, 'CloudConfig')
#pragma compile(LegalCopyright, 'Copyright 2015 Dimension Data')

; We don't need no stinkin' trayicon!
#NoTrayIcon
; Since we will be modifying the system, we need Admin
#RequireAdmin

; Our logging routines
#include "Log.au3"
#include "Misc.au3"
; Routines for interfacing with Service Manager
#include "Services.au3"
#include "StringConstants.au3"
#include <FileConstants.au3>
#include <EventLog.au3>

; Our constants and variables
; The service name(s)
Global Const $sServiceName = "CloudConfig"
Global Const $sServiceDisplayName = "CloudConfig"
; The directory we expect to find our config file and other sundries
Global Const $prepDir = 'C:\CloudConfigService'
; The config file for the service
Global Const $configFile = $prepDir & '\CloudConfig.ini'
; We extract the command from the config file and jam it in this variable
Global $command = ''
; This is the number of boots the system has performed (as extracted from
; the config file)
Global $rebootcount = 0

; constants for Event log
Global Const $WE_SUCCESS = 0
Global Const $WE_ERROR = 1
Global Const $WE_WARNING = 2
Global Const $WE_INFORMATION = 4
Global Const $WE_SUCCESSAUDIT = 8
Global Const $WE_FAILUREAUDIT = 16

; The CCS_BOOT_COUNT is used to determine when to fire off the customization
; For Priced Software images on the Dimension Data Cloud, the value needs to be
; 2. For 3rd parties making images that can be imported into the Cloud, the value
; needs to be 3 to account for the extra boot that occurs when the image is initially
; imported into the platform.
;
; Uncomment to build for a Priced Software image
;Global Const $CCS_BOOT_COUNT = 2
; Uncomment to build a 3rd party image
Global Const $CCS_BOOT_COUNT = 3

; for future feature expansion, not currently used
Global $pingHost = '256.0.0.1' ; yes, it's an illegal IP. this is by design
Global $sleepyTime = 5000 ; Ping timeout, in milliseconds
Global $oldHostname = ''

If Not @Compiled Then Exit
If Not _Singleton(@ScriptName, 1) Then
   If $cmdline[0] > 0 Then
	  If $cmdline[1] = "finish" Then
		 WriteLog("Removing service.")
		 RemoveService()
	  Else
		 WriteLog("Unrecognized command. Terminating due to multiple instances.")
	  EndIf
	  Exit
   EndIf
   WriteLog("Multiple instances running. Terminating.")
   Exit
EndIf



If $cmdline[0] > 0 Then
	Switch $cmdline[1]
		Case "install", "-i", "/i"
			InstallService()
		Case "remove", "-u", "/u", "uninstall"
			RemoveService()
		Case "run", "-r", "/r", "start"
			_SelfRun($sServiceName, "start")
		Case "stop", "-s", "/s"
			_SelfRun($sServiceName, "stop")
		Case Else
			;WriteLog(" - - - Help - - - " & @crlf)
			;WriteLog(" Service Example Params : " & @crlf)
			;WriteLog("  -i : Installs service" & @crlf)
			;WriteLog("  -u : Removes service" & @crlf)
			;WriteLog("  -r : Runs the service" & @crlf)
			;WriteLog("  -s : Stops the service" & @crlf)
			;WriteLog(" - - - - - - - - " & @crlf)
			Exit
	EndSwitch
Else
	If Not _Service_Exists($sServiceName) Then
		If MsgBox(20, "Service Not Installed.", "Would you like to install this service?" & @CRLF & $sServiceName) = 6 Then
			If InstallService() Then
				If MsgBox(4, $sServiceName, "Service Installed Successfully." & @CRLF & "Do you wish to start the process?") = 6 Then _SelfRun($sServiceName, "start")
			EndIf
		Else
			Exit
		EndIf
	EndIf
EndIf



_Service_Init($sServiceName)
Exit


Func _main($iArg, $sArgs)

   Local $hostNameChanged = False

   If Not _Service_ReportStatus($SERVICE_RUNNING, $NO_ERROR, 0) Then
	  WriteLog("Error sending running status, exiting")
	  _Service_ReportStatus($SERVICE_STOPPED, _WinAPI_GetLastError(), 0)
	Exit
   EndIf

   If Not FileExists($configFile) Then
	  ; if we don't have our config file, we abort all operations
	  WriteLog('No config file present. Aborting.')
	  WriteEventLog($WE_ERROR, 'No config file present.')
	  _Service_ReportStatus($SERVICE_STOPPED, _WinAPI_GetLastError(), 0)
	Exit
   EndIf

   Local $bServiceRunning = True ; REQUIRED

   ; how many reboots have we performed?
   Local $rebootcount = readConfig('stage')
   ; what do we run?
   Local $command = readConfig('execution')
   ; how long do we pause before launching our script?
   Local $launchDelay = Int(readConfig('delay'))
   ; do we reboot?
   Local $reboot = readConfig('reboot')

   ; we only use a while loop so we can easily break out of the switch statement
   While $bServiceRunning

   Switch ($rebootcount)
	  Case $CCS_BOOT_COUNT
		 ; launch the cmd script
		 WriteLog('Deployment stage: ' & $rebootcount)
		 writeConfig('stage', $rebootcount + 1) ; update to push it past our allowed value

		 ; finally, launch our customization script, if provided
		 If $command <> '' Then
			If FileExists($command) Then
			   Sleep($launchDelay)  ; pause
			   WriteLog('Launching "' & $command & '" ...')
			   ; Run the command and wait for it to finish
			   Run(@ComSpec & " /c " & $command, "", @SW_HIDE)
			Else
			   WriteLog('The supplied action, "' & $command & '" could not be found or accessed.')
			EndIf
		 EndIf

		; The command ran, do we reboot?
		 If $reboot Then
			; we need to force a reboot
			WriteLog('Forcing system reboot.')
			WriteEventLog($WE_INFORMATION, 'Rebooting system.')
			Shutdown(BitOR($SD_REBOOT, $SD_FORCE))
		 EndIf

		 ; we're done, so signal end
		 $bServiceRunning = False

	  Case Else
		 writeConfig('stage', $rebootcount + 1) ; update the reboot count
		 $bServiceRunning = False
   EndSwitch

   WEnd


   _Service_ReportStatus($SERVICE_STOP_PENDING, $NO_ERROR, 1000)
   WriteLog("Stopping service.")
   _Service_Stop($sServiceName)

   _Service_ReportStatus($SERVICE_STOPPED, $NO_ERROR, 0)

EndFunc   ;==>_Svc_Main



Func InstallService()

;~ 	Check for Adminstrativee rights
	If Not (IsAdmin()) Then
		MsgBox(0, $sServiceName, "You must have administrative rights to install this as a service.")
		;WriteLog("Admin rights needed, will exit now")
		Exit
	EndIf

	;WriteLog("Installing Service, Please Wait" & @CRLF)
	FileCopy(@ScriptName, @SystemDir & '\' & @ScriptName, 1)
	_Service_Create($sServiceName, $sServiceDisplayName, $SERVICE_WIN32_OWN_PROCESS, $SERVICE_AUTO_START, $SERVICE_ERROR_SEVERE, '"' & @SystemDir & '\' & @ScriptName & '"')

	If @error Then
		WriteLog("Problem Installing Service, Error number is " & @error & @CRLF & " message  : " & _WinAPI_GetLastErrorMessage())
		Return 0
	Else
		WriteLog("Installation of Service Successful.")
	EndIf


	Return 1
	Exit
EndFunc   ;==>InstallService



Func RemoveService()
	_Service_Stop($sServiceName)
	Sleep(30000) ; pause for 30 seconds
	_Service_Delete($sServiceName)
	If Not @error Then WriteLog("Service Removed Successfully" & @CRLF)
	Exit
EndFunc   ;==>RemoveService


Func _exit()
	_Service_ReportStatus($SERVICE_STOPPED, $NO_ERROR, 0);
EndFunc   ;==>_exit

Func _Stopping()
	_Service_ReportStatus($SERVICE_STOP_PENDING, $NO_ERROR, 3000)
EndFunc   ;==>_Stopping

Func _SelfRun($servicename, $action)
	Local $sCmdFile = 'sc ' & $action & ' "' & $servicename & '"'
	Run($sCmdFile, @TempDir, @SW_HIDE)
	Exit
EndFunc   ;==>_SelfRun


Func writeConfig($section, $other)
	Switch ($section)
		Case 'stage'
			IniWrite($configFile, "deployment stage", "state", $other)
	EndSwitch
EndFunc   ;==>writeConfig

Func readConfig($section)
   Local $value = ''
	Switch ($section)
	  Case 'stage'
		 $value = IniRead($configFile, "deployment stage", "state", 0)
	  Case 'execution'
		 $value = IniRead($configFile, "deployment execution", "action", "")
	  Case 'delay'
		 $value = IniRead($configFile, "deployment execution", "delay", 60000) ; default to 1 minute
	  Case 'reboot'
		 $value = IniRead($configFile, "deployment execution", "forcereboot", "FALSE") ; default to no reboot
		 ; normalize $value into a boolean
		 If $value = 'true' Or $value = 'True' Or $value = 'TRUE' Or $value = 1 Or $value = 'yes' Or $value = 'Yes' Or $value = 'YES' Then
			; to simplify, only check for values that cause a reboot
			$value = True
		 Else
			; all other values are considered False
			$value = False
		 EndIf
	EndSwitch
	Return $value
EndFunc   ;==>readConfig

Func WriteEventLog($severity, $message)
   Local $hEventLog, $aData[1] = [0]
   Local $eventMessage = $sServiceName & ': ' & $message
   $hEventLog = _EventLog__Open("", "Application")
   _EventLog__Report($hEventLog, $severity, 0, 2, "", $eventMessage, $aData)
   _EventLog__Close($hEventLog)
EndFunc

; Check the hostname of the system and compare it with a defined value
Func checkHostname($expected)
   ; Update our view of environment variables
   EnvUpdate()
   ; get our current hostname
   Local $compName = @ComputerName
   ; check to see if it matches what we expect
   Local $return = StringCompare($compName, $expected, $STR_NOCASESENSE)
   If  $return = 0 Then
	  Return True
   Else
	  Return False
   EndIf
EndFunc   ;==>checkHostname

; not currently used
Func checkNetwork()
	Local $return = Ping($pingHost, $sleepyTime)
	If $return > 0 Then
		; network is alive
		writeConfig('network', '')
	EndIf
 EndFunc   ;==>checkNetwork

Func getIP()
   ; On the Dimension Data Cloud, all servers are assigned an RFC1918 address on
   ; all NICs. For MCP 1.0 locations, this will always be in the 10.0.0.0/8 space. For
   ; MCP 2.0 locations, it can be in any of the RFC1918 space, 10.0.0.0/8,
   ; 192.168.0.0/16 or 172.16.0.0/12. Our job is to try to determine what this IP is.
   ; In addition, you cannot assign a public IPv4 address directly to a server. You must
   ; always use NAT or VIPs.
   ; There are 4 macros that may contain the IP of the system.

   ; first, create an array using the macros (because AutoIT doesn't have variable interpolation
   Local $ipArray[4]
   $ipArray[0] = @IPAddress1
   $ipArray[1] = @IPAddress2
   $ipArray[2] = @IPAddress3
   $ipArray[3] = @IPAddress4

   Local $ip3 = ''

   ; now loop over the array
   For $ip In $ipArray
	  ; start evaluating the IP
	  $ip3 = StringLeft($ip, 3)
	  If $ip3 = '10.' Or $ip3 = '192' Or $ip3 = 172' Then
		 ; We stop at the first one we find, regardless of how many there may be
		 Return $ip
	  EndIf
   Next

   ; apparently, we didn't find any private addresses, so return "false"
   Return 0

EndFunc

Func updateHostsFile($ipAddress, $hostName)
   ; Update the hosts file with the IP and hostname we require
   Local $file = @SystemDir & "\drivers\etc\hosts"

   Local $fileHandle = FileOpen($file, $FO_OVERWRITE) ;; OVERWRITE existing file!!
   If $fileHandle = -1 Then
	  Return False
   EndIf
   Local $hostLine = '# Hosts file updated by Cloud Config Service' & @CRLF & $ipAddress & @TAB & $hostName & @CRLF
   Local $result = FileWriteLine($fileHandle, $hostLine)
   If $result = 0 Then
	  Return False
   EndIf
   FileClose($fileHandle)
   Return True
EndFunc


Func getVolGUID($volLabel)
   ;; this function iterates over the mounted drives to figure out what
   ;; the volume label is. It does this without regard to drive letter

   ;; get all drives
   Local $drives = DriveGetDrive("FIXED")

   ; Loop over the array holding the drive letters
   For $i = 1 To $drives[0]
	  ; get drive letter and uppercase it
	  Local $currentDrive = StringUpper($drives[$i])
	  ; get this drive's label and uppercase it
	  Local $currentLabel = StringUpper(DriveGetLabel($currentDrive))

	  If $currentLabel = $volLabel Then
		 ;; found it, grab the GUID
		 Local $volGUID = extractVolGUID($currentDrive)
		 Return $volGUID
	  EndIf
   Next

   Return False
EndFunc

Func extractVolGUID($drive)
   ;; get the GUID of the drive
   $drive = $drive & '\' ;; make sure there's a path. a double \\ doesn't hinder execution
   Local $iPID = Run(@ComSpec & ' /C mountvol.exe ' & $drive & ' /L', "", @SW_HIDE, $STDOUT_CHILD)
   ProcessWaitClose($iPID)
   Local $sOutput = StdoutRead($iPID)
   Local $volGUID = StringStripWS($sOutput, $STR_STRIPALL)

   Return $volGUID
EndFunc
