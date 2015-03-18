#include-once

Global $LogFile = "cloudconfigservice.log"
Global $LogfilePath = 'C:\CloudConfigService'
Global $hLogFile = FileOpen($LogfilePath & '\' & $LogFile, 1)
WriteLog("", 1)

Func WriteLog($text, $isNewLogFile = 0, $isCRLF = 0)
	Dim $Months[12]
	$Months[0] = "January"
	$Months[1] = "February"
	$Months[2] = "March"
	$Months[3] = "April"
	$Months[4] = "May"
	$Months[5] = "June"
	$Months[6] = "July"
	$Months[7] = "August"
	$Months[8] = "September"
	$Months[9] = "October"
	$Months[10] = "November"
	$Months[11] = "December"

	If @HOUR > 12 Then
		$Hour = @HOUR - 12
		$HourSuffix = " PM"
	Else
		$Hour = @HOUR
		$HourSuffix = " AM"
	EndIf

	If $isNewLogFile = 1 Then
		Local $FormatString = "Log created: " & $Months[@MON - 1] & " " & @MDAY &", " & @YEAR & " : " & $Hour & ":" & @MIN & ":" & @SEC & $HourSuffix
		DrawLine(StringLen($FormatString), '_')
		FileWriteLine($hLogFile, $FormatString)
		DrawLine(StringLen($FormatString), '_')
		FileWriteLine($hLogFile, @CRLF & @CRLF)
	Else
		Local $FormatString = ''
		For $index = 1 To $isCRLF
			$FormatString = $FormatString & @CRLF
		Next
		$FormatString = $FormatString & $Months[@MON - 1] & " " & @MDAY & ", " & @YEAR & " : " & $Hour & ":" & @MIN & ":" & @SEC & $HourSuffix & " [" & @AutoItPID & "] >> " & $text
		FileWriteLine($hLogFile, $FormatString)
	EndIf
EndFunc

; because Services.au3 doesn't actually define this function but uses it anyway
Func logprint($text, $isNewLogFile = 0, $isCRLF = 0)
	Dim $Months[12]
	$Months[0] = "January"
	$Months[1] = "February"
	$Months[2] = "March"
	$Months[3] = "April"
	$Months[4] = "May"
	$Months[5] = "June"
	$Months[6] = "July"
	$Months[7] = "August"
	$Months[8] = "September"
	$Months[9] = "October"
	$Months[10] = "November"
	$Months[11] = "December"

	If @HOUR > 12 Then
		$Hour = @HOUR - 12
		$HourSuffix = " PM"
	Else
		$Hour = @HOUR
		$HourSuffix = " AM"
	EndIf

	If $isNewLogFile = 1 Then
		Local $FormatString = "Log created: " & $Months[@MON - 1] & " " & @MDAY &", " & @YEAR & " : " & $Hour & ":" & @MIN & ":" & @SEC & $HourSuffix
		DrawLine(StringLen($FormatString), '_')
		FileWriteLine($hLogFile, $FormatString)
		DrawLine(StringLen($FormatString), '_')
		FileWriteLine($hLogFile, @CRLF & @CRLF)
	Else
		Local $FormatString = ''
		For $index = 1 To $isCRLF
			$FormatString = $FormatString & @CRLF
		Next
		$FormatString = $FormatString & $Months[@MON - 1] & " " & @MDAY & ", " & @YEAR & " : " & $Hour & ":" & @MIN & ":" & @SEC & $HourSuffix & " [" & @AutoItPID & "] >> " & $text
		FileWriteLine($hLogFile, $FormatString)
	EndIf
EndFunc


Func DrawLine($Count, $Character)
	Local $FormatString = ''
	For $index = 1 To $Count
		$FormatString = $FormatString & $Character
	Next
	FileWriteLine($hLogFile, $FormatString)
EndFunc
