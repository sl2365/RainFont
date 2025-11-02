;*****************************************
; RainFont_x64.au3 updated by sl23
; Original code supplied by JSMorley
; Created with ISN AutoIt Studio v1.16
; Compiled with AutoIt v3.3.16.1
;*****************************************

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=rF.ico
#AutoIt3Wrapper_Res_Fileversion_First_Increment=Y	; AutoIncrement: Before (Y); After (N) compile. Default=N
#AutoIt3Wrapper_Res_FileVersion_AutoIncrement=Y
#AutoIt3Wrapper_Res_Fileversion=3.3.8.1
#AutoIt3Wrapper_Res_ProductVersion=3.3.16.1
#AutoIt3Wrapper_Res_Description=RainFont_x64
#AutoIt3Wrapper_Res_LegalCopyright=sl23
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#RequireAdmin

#include <Array.au3>
#Include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <ListBoxConstants.au3>
#Include <GDIPlus.au3>
#include <StaticConstants.au3>

Global $hGUI, $hGraphic, $hBrush, $hFormat, $hFamily, $hFont, $tLayout, $BadFont, $aArray

Opt("TrayIconHide", 1)
Opt("GUICloseOnESC", 0)
_Singleton("RainFont", 0)


$WorkingDir = @TempDir & "\RainFont\"
DirCreate($WorkingDir)
FileInstall("RainFont.bmp", $WorkingDir & "RainFont.bmp", 1)

$CurrentBrowseDir = ".\"

If FileExists(@ScriptDir & "\RainFont.dir") Then

	$DirFile = FileOpen(@ScriptDir & "\RainFont.dir", 0)
	$DirLine = FileReadLine($DirFile)
	$CurrentBrowseDir = $DirLine

	FileClose($DirFile)

EndIf

$Mainform = GUICreate("RainFont", 400, 610, -1, -1)
$BannerPic = GUICtrlCreatePic($WorkingDir & "RainFont.bmp", 0, 0, 400, 60)
$WelcomeLabel = GUICtrlCreateLabel("Welcome to RainFont", 10, 71, 139, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$LinkLabel = GUICtrlCreateLabel("Help", 358, 71, 100, 19)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0x3981E5)
GUICtrlSetCursor (-1, 0)

$WindowsFontsList = GUICtrlCreateList("", 10, 135, 380, 201, BitOR($GUI_SS_DEFAULT_LIST,$WS_HSCROLL))
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetLimit ($WindowsFontsList, 460)

$SelectOneLabel = GUICtrlCreateLabel("Select an installed font from " & @WindowsDir & "\Fonts " & @CRLF & "or browse to find and select an uninstalled font:", 10, 92, 311, 38)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$BrowseButton = GUICtrlCreateButton("Browse", 10, 355, 70, 25)
GUICtrlSetTip(-1, "Browse for an uninstalled .ttf font on your hard drive")
$FontFileInput = GUICtrlCreateInput("Browse your hard drive for a .ttf font file", 85, 355, 280, 25)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Browse your hard drive for a .ttf font")
$FontNameInput = GUICtrlCreateInput("", 10, 400, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontNameButton = GUICtrlCreateButton("C", 370, 400, 20, 25)
GUICtrlSetTip(-1, "Copy FontFace setting to your clipboard")
GUICtrlSetState ($CopyFontNameButton, $GUI_DISABLE)
$FontSubInput = GUICtrlCreateInput("", 10, 430, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontSubButton = GUICtrlCreateButton("C", 370, 430, 20, 25)
GUICtrlSetTip(-1, "Copy StringStyle setting to your clipboard")
GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
$FullFontNameLabel = GUICtrlCreateLabel("Full Font Name:", 10, 470, 380, 20)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0x3981E5)
$FullFontNameValue = GUICtrlCreateLabel("", 107, 470, 380, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$FamilyLabel = GUICtrlCreateLabel("Font Family:", 10, 490, 380, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$FamilyValue = GUICtrlCreateLabel("", 107, 490, 380, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SubFamilyLabel = GUICtrlCreateLabel("Font SubFamily:", 10, 510, 380, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SubFamilyValue = GUICtrlCreateLabel("", 107, 510, 380, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$ErrorLabel = GUICtrlCreateLabel("", 10, 541, 375, 80)
GUICtrlSetFont(-1, 14, 800, 0, "Segoe UI")
GUICtrlSetColor ($ErrorLabel, 0xFF4000)
GUICtrlSetState ($ErrorLabel, $GUI_HIDE)
$EraseSampleLabel = GUICtrlCreateLabel("", 10, 541, 380, 80)
GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)


$SplashScreen = GUICreate("RainFont", 210, 50, -1, -1, BitOR($WS_SYSMENU, $WS_POPUP, $WS_POPUPWINDOW, $WS_BORDER, $WS_CLIPSIBLINGS))
$SplashLabel = GUICtrlCreateLabel("Scanning Fonts", 1, 12, 200, 30, $SS_CENTER)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
GUISetState(@SW_SHOWNORMAL, $SplashScreen)

$a = 1
Global $RegArray[1][2]

While 1
	ReDim $RegArray[$a + 1][2]
	$RegArray[$a][0] = StringReplace(RegEnumVal("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",$a), " (TrueType)", "", 0, 0)
	$RegArray[$a][1] = RegRead ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", RegEnumVal("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",$a))
	if @Error = -1 Then ExitLoop
	$a = $a + 1
WEnd

_ArrayDelete($RegArray, $a)
_ArraySort($RegArray)

$a = 1
While $a <= UBound($RegArray) -1
	if StringInStr($RegArray[$a][1], ".ttf", 0) = 0 Then
		_ArrayDelete($RegArray, $a)
		If $a > 1 Then $a = $a - 1
	Else
		GUICtrlSetData($WindowsFontsList, $RegArray[$a][0] & "   [File: " & $RegArray[$a][1] & "]", "")
		$a = $a + 1
	EndIf
WEnd


GUIDelete($SplashScreen)
GUISetState(@SW_SHOWNORMAL, $MainForm)
Send("{HOME}")

While 1

	$UserEvent = GUIGetMsg()

	Switch $UserEvent

		Case $GUI_EVENT_CLOSE
			DirRemove($WorkingDir, 1)
			_GDIPlus_FontDispose($hFont)
			_GDIPlus_FontFamilyDispose($hFamily)
			_GDIPlus_StringFormatDispose($hFormat)
			_GDIPlus_BrushDispose($hBrush)
			_GDIPlus_GraphicsDispose($hGraphic)
			_GDIPlus_Shutdown ()
			Exit

		Case $CopyFontNameButton
			ClipPut(GUICtrlRead($FontNameInput))
			$sToolTipAnswer = ToolTip("FontFace setting now in Windows Clipboard",Default,Default,"Copied",1,3)
			Sleep(2000)
			ToolTip("")

		Case $CopyFontSubButton
			ClipPut(GUICtrlRead($FontSubInput))
			$sToolTipAnswer = ToolTip("StringStyle setting now in Windows Clipboard",Default,Default,"Copied",1,3)
			Sleep(2000)
			ToolTip("")

		Case $FullFontNameLabel
			_ArrayDisplay($aArray)

		Case $WindowsFontsList

			$BadFont=0
			GUICtrlSetState ($FontNameInput, $GUI_DISABLE)
			GUICtrlSetState ($CopyFontNameButton, $GUI_DISABLE)
			GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
			GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
			GUICtrlSetData($FontNameInput, "FontFace=")
			GUICtrlSetData($FontSubInput, "StringStyle=")
			GUICtrlSetState ($EraseSampleLabel, $GUI_SHOW)
			GUICtrlSetData($FontFileInput, "Browse your hard drive for a .ttf font file")

			$StripFontName = StringRegExp(GUICtrlRead($WindowsFontsList), '\[File: (.*)\]', 3)
			If @error Then
				$sFontData = FileRead(@WindowsDir & "\Fonts\" & GUICtrlRead($WindowsFontsList))
				$FontFileName = GUICtrlRead($WindowsFontsList)
			Else
				$sFontData = FileRead(@WindowsDir & "\Fonts\" & $StripFontName[0])
				$FontFileName = $StripFontName[0]
			EndIf

			$aArray = _RH_TTF_GetInfo($sFontData)
			for $a = 0 to UBound($aArray) - 1
				If $aArray[$a][2] <> "" And $aArray[$a][1] = "" Then
				$aArray[$a][1] = $aArray[$a][2]
				EndIf
			Next

			If IsArray($aArray) = 0 Or $aArray[1][1] = "" Then
				GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)
				GUICtrlSetState ($ErrorLabel, $GUI_SHOW)
				GUICtrlSetData($ErrorLabel, $FontFileName & " does not appear to be a valid TrueType font for Rainmeter!")
				$BadFont=1
			Else

				GUICtrlSetState ($ErrorLabel, $GUI_HIDE)
				GUICtrlSetState ($FontNameInput, $GUI_ENABLE)
				GUICtrlSetState ($CopyFontNameButton, $GUI_ENABLE)
				GUICtrlSetData($FontNameInput, "FontFace=" & $aArray[1][1])
				GUICtrlSetData($FullFontNameValue, $aArray[4][1])
				GUICtrlSetData($FamilyValue, $aArray[1][1])
				GUICtrlSetData($SubFamilyValue, $aArray[2][1])
				If StringUpper($aArray[2][1]) <> "" Then
					If StringUpper($aArray[2][1]) = "ITALIC" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "Italic")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 2
					ElseIf StringUpper($aArray[2][1]) = "BOLD" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "Bold")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 1
					ElseIf StringUpper($aArray[2][1]) = "BOLD ITALIC" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "BoldItalic")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 3
					ElseIf StringUpper($aArray[2][1]) = "REGULAR" Then
						GUICtrlSetData($FontSubInput, "StringStyle=")
						GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
						$FontStyle = 0
					Else
						GUICtrlSetData($FontSubInput, "StringStyle=")
						GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
						$FontStyle = 0
						GUICtrlSetData($SubFamilyValue, $aArray[2][1] & " (Style not supported)")
					EndIf
				Else
						GUICtrlSetData($FontSubInput, "StringStyle=")
						GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
						$FontStyle = 0
				EndIf



				GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)
				If $BadFont=0 Then
					_GDIPlus_Startup ()
					$hGraphic = _GDIPlus_GraphicsCreateFromHWND($Mainform)
					$hBrush = _GDIPlus_BrushCreateSolid(0xFF303030)
					$hFormat = _GDIPlus_StringFormatCreate()
					$hFamily = _GDIPlus_FontFamilyCreate($aArray[1][1])
					$hFont = _GDIPlus_FontCreate($hFamily, 18, $FontStyle, 3)
					$tLayout = _GDIPlus_RectFCreate(10, 541, 380, 80)
					_GDIPlus_GraphicsDrawStringEx($hGraphic, "ABCXYZabcxyz1290#?&%", $hFont, $tLayout, $hFormat, $hBrush)

					_GDIPlus_FontDispose($hFont)
					_GDIPlus_FontFamilyDispose($hFamily)
					_GDIPlus_StringFormatDispose($hFormat)
					_GDIPlus_BrushDispose($hBrush)
					_GDIPlus_GraphicsDispose($hGraphic)
					_GDIPlus_Shutdown ()
				EndIf

			;_ArrayDisplay($aArray)

			EndIf


		Case $BrowseButton

			$FileToLoad = FileOpenDialog("Open.ttf font file", $CurrentBrowseDir, "TTF Font (*.ttf)", 3)
			If Not @error Then

				$BadFont=0
				_GUICtrlListBox_SetCurSel($WindowsFontsList, -1)
				GUICtrlSetState ($FontNameInput, $GUI_DISABLE)
				GUICtrlSetState ($CopyFontNameButton, $GUI_DISABLE)
				GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
				GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
				GUICtrlSetData($FontNameInput, "FontFace=")
				GUICtrlSetData($FontSubInput, "StringStyle=")
				GUICtrlSetState ($EraseSampleLabel, $GUI_SHOW)

				Dim $szDrive, $szDir, $szFName, $szExt
				$SplitFileToLoad = _PathSplit($FileToLoad, $szDrive, $szDir, $szFName, $szExt)
				$CurrentBrowseDir = $SplitFileToLoad[1] & $SplitFileToLoad[2]
				$DirFile = FileOpen(@ScriptDir & "\RainFont.dir", 2)
				FileWriteLine($DirFile, $CurrentBrowseDir)
				FileClose($DirFile)
				GUICtrlSetData($FontFileInput, $FileToLoad)
				FileClose($FileToLoad)

				$sFontData = FileRead($FileToLoad)

				$aArray = _RH_TTF_GetInfo($sFontData)
				for $a = 0 to UBound($aArray) - 1
					If $aArray[$a][2] <> "" And $aArray[$a][1] <>  $aArray[$a][2] Then
						$aArray[$a][1] = $aArray[$a][2]
					EndIf
				Next

				If IsArray($aArray) = 0 Or $aArray[1][1] = "" Then
					GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)
					GUICtrlSetState ($ErrorLabel, $GUI_SHOW)
					GUICtrlSetData($ErrorLabel, $SplitFileToLoad[3] & $SplitFileToLoad[4] & " does not appear to be a valid TrueType font for Rainmeter!")
					$BadFont=1
				Else

					GUICtrlSetState ($ErrorLabel, $GUI_HIDE)
					GUICtrlSetState ($FontNameInput, $GUI_ENABLE)
					GUICtrlSetState ($CopyFontNameButton, $GUI_ENABLE)
					GUICtrlSetData($FontNameInput, "FontFace=" & $aArray[1][1])
					GUICtrlSetData($FullFontNameValue, $aArray[4][1])
					GUICtrlSetData($FamilyValue, $aArray[1][1])
					GUICtrlSetData($SubFamilyValue, $aArray[2][1])
					If StringUpper($aArray[2][1]) = "ITALIC" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "Italic")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 2
					ElseIf StringUpper($aArray[2][1]) = "BOLD" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "Bold")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 1
					ElseIf StringUpper($aArray[2][1]) = "BOLD ITALIC" or StringUpper($aArray[2][1]) = "BOLDIT" Then
						GUICtrlSetData($FontSubInput, "StringStyle=" & "BoldItalic")
						GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
						$FontStyle = 3
					Else
						GUICtrlSetData($FontSubInput, "StringStyle=")
						GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
						GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
						$FontStyle = 0
					EndIf
					GUICtrlSetState($FontFileInput, $GUI_FOCUS)
					Send("{HOME}")
					Send("{HOME}")
					GUICtrlSetState($BrowseButton, $GUI_FOCUS)
					$BadFont=0
				EndIf

				If $BadFont=0 Then
					_GDIPlus_Startup()
					$hGraphic = _GDIPlus_GraphicsCreateFromHWND($Mainform)
					$hBrush = _GDIPlus_BrushCreateSolid(0xFF303030)
					$hFormat = _GDIPlus_StringFormatCreate()
					$hCollection = DllCall($ghGDIPDll, 'int', 'GdipNewPrivateFontCollection', 'ptr*', 0)
					$hCollection = $hCollection[1]
					DllCall($ghGDIPDll, 'int', 'GdipPrivateAddFontFile', 'ptr', $hCollection, 'wstr', $FileToLoad)
					$hFamily = DllCall($ghGDIPDll, 'int', 'GdipCreateFontFamilyFromName', 'wstr', $aArray[1][1], 'ptr', $hCollection, 'ptr*', 0) ; (!) "FreeMono" - Font name
					$hFamily = $hFamily[3]
					$hFont = _GDIPlus_FontCreate($hFamily, 18, $FontStyle)
					$tLayout = _GDIPlus_RectFCreate(10, 541, 380, 80)
					_GDIPlus_GraphicsDrawStringEx($hGraphic, "ABCXYZabcxyz1290#?&%", $hFont, $tLayout, $hFormat, $hBrush)
					_GDIPlus_FontDispose($hFont)
					_GDIPlus_FontFamilyDispose($hFamily)
					DllCall($ghGDIPDll, 'int', 'GdipDeletePrivateFontCollection', 'ptr*', $hCollection)
					_GDIPlus_StringFormatDispose($hFormat)
					_GDIPlus_BrushDispose($hBrush)
					_GDIPlus_GraphicsDispose($hGraphic)
					_GDIPlus_Shutdown()
				EndIf

			;_ArrayDisplay($aArray)

			EndIf

			Case $LinkLabel
			ShellExecute("http://rainmeter.net/cms/Meters-ANoteOnFonts")

	EndSwitch

WEnd


Func _RH_TTF_GetInfo($bBinary)
    Local $tBinary = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
    DllStructSetData($tBinary, 1, $bBinary)
    Local $pBinary = DllStructGetPtr($tBinary)
    Local $pPointer = $pBinary
    Local $tTT_OFFSET_TABLE = DllStructCreate("word MajorVersion;" & _
            "word MinorVersion;" & _
            "word NumOfTables;" & _
            "word SearchRange;" & _
            "word EntrySelector;" & _
            "word RangeShift;", _
            $pPointer)
    $pPointer += 12
    If DllStructGetData($tTT_OFFSET_TABLE, "MajorVersion") <> 256 And DllStructGetData($tTT_OFFSET_TABLE, "MinorVersion") <> 0 Then
        Return SetError(1, 0, 0)
    EndIf
    Local $iNumOfTables = 265 * BitAND(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 0xF) + BitShift(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 8)
    Local $iOffset
    Local $tTT_TABLE_DIRECTORY
    For $i = 1 To $iNumOfTables
        $tTT_TABLE_DIRECTORY = DllStructCreate("char Tag[4];" & _
                "dword CheckSum;" & _
                "dword Offset;" & _
                "dword Length;", _
                $pPointer)
        $pPointer += 16
        If DllStructGetData($tTT_TABLE_DIRECTORY, "Tag") == "name" Then
            $iOffset = _RH_BigEndianToInt(DllStructGetData($tTT_TABLE_DIRECTORY, "Offset"), 4)
            ExitLoop
        EndIf
    Next
    If Not $iOffset Then Return SetError(2, 0, 0)
    $pPointer = $pBinary + $iOffset
    Local $pDir = $pPointer
    Local $tTT_NAME_TABLE_HEADER = DllStructCreate("word FSelector;" & _
            "word NRCount;" & _
            "word StorageOffset;", _
            $pPointer)
    $pPointer += 6
    Local $iNRCount = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "NRCount"), 2)
    Local $iStorageOffset = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "StorageOffset"), 2)
    Local $aInfo[28][3] = [["Copyright notice"],["Font Name"],["Subfamily Name"],["Identifier"],["Full font Name"],["Version"],["Postscript Name"],["Trademark"],["Manufacturer"],["Designer"],["Description"],["URL Vendor"], _
            ["URL Designer"],["License Description"],["License Info URL"],["Reserved Field "],["Preferred Family"],["Preferred Subfamily"],["Compatible Full"],["Sample text"],["PostScript CID Findfont Name"],["WWS Family Name"],["WWS Subfamily Name"]]
    Local $tTT_NAME_RECORD, $bString, $iNameID, $iPlatform
    Local $iLangID = -1
    For $i = 1 To $iNRCount
        $tTT_NAME_RECORD = DllStructCreate("word PlatformID;" & _
                "word EncodingID;" & _
                "word LanguageID;" & _
                "word NameID;" & _
                "word StringLength;" & _
                "word StringOffset;", _
                $pPointer)
        $pPointer += 12 ; size of $tTT_NAME_RECORD
        $bString = DllStructGetData(DllStructCreate("byte[" & _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "StringLength"), 2) & "]", $pDir + $iStorageOffset + _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "StringOffset"), 2)), 1)
        $iNameID = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "NameID"), 2)
        $iPlatform = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "PlatformID"), 2)
        If $iNameID < 23 Then
            If $iPlatform = 1 Then
                $aInfo[$iNameID][1] = _RH_FormatStringEllipsis(BinaryToString($bString), 100)
            ElseIf $iPlatform = 3 Then
                If $iLangID = -1 And $iNameID = 0 Then $iLangID = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "LanguageID"), 2)
                If _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "LanguageID"), 2) = $iLangID Then $aInfo[$iNameID][2] = _RH_FormatStringEllipsis(BinaryToString($bString, 3), 100)
            EndIf
        EndIf
    Next
    Return $aInfo
EndFunc   ;==>_RH_TTF_GetInfo

Func _RH_TTF_GetFontMetrics($bBinary)
    Local $tBinary = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
    DllStructSetData($tBinary, 1, $bBinary)
    Local $pBinary = DllStructGetPtr($tBinary)
    Local $pPointer = $pBinary
    Local $tTT_OFFSET_TABLE = DllStructCreate("word MajorVersion;" & _
            "word MinorVersion;" & _
            "word NumOfTables;" & _
            "word SearchRange;" & _
            "word EntrySelector;" & _
            "word RangeShift;", _
            $pPointer)
    $pPointer += 12
    If DllStructGetData($tTT_OFFSET_TABLE, "MajorVersion") <> 256 And DllStructGetData($tTT_OFFSET_TABLE, "MinorVersion") <> 0 Then Return SetError(1, 0, 0)
    Local $iNumOfTables = 265 * BitAND(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 0xF) + BitShift(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 8)
    Local $iOffset
    Local $tTT_TABLE_DIRECTORY
    For $i = 1 To $iNumOfTables
        $tTT_TABLE_DIRECTORY = DllStructCreate("char Tag[4];" & _
                "dword CheckSum;" & _
                "dword Offset;" & _
                "dword Length;", _
                $pPointer)
        $pPointer += 16
        If DllStructGetData($tTT_TABLE_DIRECTORY, "Tag") == "OS/2" Then
            $iOffset = _RH_BigEndianToInt(DllStructGetData($tTT_TABLE_DIRECTORY, "Offset"), 4)
            ExitLoop
        EndIf
    Next
    If Not $iOffset Then Return SetError(2, 0, 0)
    $pPointer = $pBinary + $iOffset
    Local $tFontMetrics = DllStructCreate("align 1;word Version;" & _
            "short AvgCharWidth;" & _
            "word WeightClass;" & _
            "word WidthClass;" & _
            "word Type;" & _
            "short SubscriptXSize;" & _
            "short SubscriptYSize;" & _
            "short SubscriptXOffset;" & _
            "short SubscriptYOffset;" & _
            "short SuperscriptXSize;" & _
            "short SuperscriptYSize;" & _
            "short SuperscriptXOffset;" & _
            "short SuperscriptYOffset;" & _
            "short StrikeoutSize;" & _
            "short StrikeoutPosition;" & _
            "short FamilyClass;" & _
            "byte Panose[10];" & _
            "dword UnicodeRange1;" & _ ;
            "dword UnicodeRange2;" & _
            "dword UnicodeRange3;" & _ ;
            "dword UnicodeRange4;" & _
            "char VendID[4];" & _
            "word Selection;" & _
            "word FirstCharIndex;" & _
            "word LastCharIndex;" & _
            "short TypoAscender;" & _
            "short TypoDescender;" & _
            "short TypoLineGap;" & _
            "word WinAscent;" & _
            "word WinDescent;" & _
            "dword CodePageRange1;" & _
            "dword CodePageRange2;", _
            $pPointer)
    Local $aArray[7][2] = [["Name", ""], _
            ["Height", 10], _ ; Height ; FIXME: Where is this data stored?
            ["Weight", _RH_BigEndianToInt(DllStructGetData($tFontMetrics, "WeightClass"))], _ ; Weight
            ["Italic", BitAND(DllStructGetData($tFontMetrics, "Selection"), 1) = True], _ ; Italic
            ["Underline", BitAND(BitShift(DllStructGetData($tFontMetrics, "Selection"), 1), 1) = True], _ ; Underline
            ["StrikeOut", BitAND(BitShift(DllStructGetData($tFontMetrics, "Selection"), 4), 1) = True], _ ; StrikeOut
            ["CharSet", 1]] ; CharSet ; Forcing default DEFAULT_CHARSET ; FIXME: Where is this data stored?
    _ArrayDisplay($aArray)
	Return $aArray
EndFunc   ;==>_RH_TTF_GetFontMetrics

Func _RH_BigEndianToInt($iValue, $iSize = 2)
    Return Dec(Hex(BinaryMid($iValue, 1, $iSize)))
EndFunc   ;==>_RH_BigEndianToInt

Func _RH_FormatStringEllipsis($sString, $iNumChars)
    Local $iLen = StringLen($sString)
    If $iLen <= $iNumChars Then Return $sString
    Return StringLeft($sString, $iNumChars - 3) & "..."
EndFunc   ;==>_RH_FormatStringEllipsis
