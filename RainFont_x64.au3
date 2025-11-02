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
#AutoIt3Wrapper_Res_Fileversion=3.3.8.23
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

; RainFont - footer/error visibility fixes + helpers
Global $hGUI, $hGraphic, $hBrush, $hFormat, $hFamily, $hFont, $tLayout, $BadFont, $aArray
Global $CurrentBrowseDir, $g_SkinsFolder, $g_View, $g_ListPaths, $g_Populating
Global $g_LastFontInfo

Opt("TrayIconHide", 1)
Opt("GUICloseOnESC", 0)
_Singleton("RainFont", 0)

$WorkingDir = @TempDir & "\RainFont\"
DirCreate($WorkingDir)
FileInstall("RainFont.bmp", $WorkingDir & "RainFont.bmp", 1)

$CurrentBrowseDir = ".\"

; read saved browse folder if present
If FileExists(@ScriptDir & "\RainFont.dir") Then
	$DirFile = FileOpen(@ScriptDir & "\RainFont.dir", 0)
	$DirLine = FileReadLine($DirFile)
	$CurrentBrowseDir = $DirLine
	FileClose($DirFile)
EndIf

; read saved skins folder if present
$g_SkinsFolder = ""
If FileExists(@ScriptDir & "\RainFont.skins") Then
    Local $hS = FileOpen(@ScriptDir & "\RainFont.skins", 0)
    If $hS <> -1 Then
        $g_SkinsFolder = StringStripWS(FileReadLine($hS), 3)
        FileClose($hS)
    EndIf
EndIf

$g_Populating = False
$g_LastFontInfo = ""

; Main window
$Mainform = GUICreate("RainFont", 400, 800, -1, -1)
$BannerPic = GUICtrlCreatePic($WorkingDir & "RainFont.bmp", 0, 0, 400, 60)
$WelcomeLabel = GUICtrlCreateLabel("Welcome to RainFont", 10, 67, 139, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$LinkLabel = GUICtrlCreateLabel("Help", 358, 67, 100, 19)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0x3981E5)
GUICtrlSetCursor (-1, 0)

; Top list
$WindowsFontsList = GUICtrlCreateList("", 10, 155, 380, 340, BitOR($GUI_SS_DEFAULT_LIST,$WS_HSCROLL))
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetLimit ($WindowsFontsList, 460)

; View control buttons (Windows / Skins / Set Skins)
$BtnWindows = GUICtrlCreateButton("Windows Fonts", 10, 88, 120, 26)
$BtnSkins = GUICtrlCreateButton("Skins Fonts", 140, 88, 120, 26)
$BtnSetSkins = GUICtrlCreateButton("Set Skins Folder", 270, 88, 120, 26)
GUICtrlSetTip($BtnSetSkins, "Choose the Rainmeter Skins folder to scan (recursive)")

; Dynamic instruction label, updated to reflect the current view.
$SelectOneLabel = GUICtrlCreateLabel("", 10, 117, 380, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

; Browse area: input, Browse button, Save Folder button
$BrowseButton = GUICtrlCreateButton("Browse", 10, 500, 60, 25)
GUICtrlSetTip(-1, "Browse for an uninstalled .ttf/.otf/.ttc font on your hard drive")
$FontFileInput = GUICtrlCreateInput("Browse your hard drive for a font file", 75, 500, 285, 25)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$SaveFolderBtn = GUICtrlCreateButton("💾", 365, 500, 25, 25)
GUICtrlSetTip($SaveFolderBtn, "Save the folder shown in the path box as the default Browse folder")

; Inputs and copy buttons (below preview)
$FontNameInput = GUICtrlCreateInput("", 10, 580, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontNameButton = GUICtrlCreateButton("C", 370, 580, 20, 25)
GUICtrlSetTip(-1, "Copy FontFace setting to your clipboard")
GUICtrlSetState ($CopyFontNameButton, $GUI_DISABLE)
$FontSubInput = GUICtrlCreateInput("", 10, 615, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontSubButton = GUICtrlCreateButton("C", 370, 615, 20, 25)
GUICtrlSetTip(-1, "Copy StringStyle setting to your clipboard")
GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)

; Info labels
$FullFontNameLabel = GUICtrlCreateLabel("Full Font Name:", 10, 650, 120, 20)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0x3981E5)
; Make the FullFontName Label look clickable: hand cursor
GUICtrlSetCursor($FullFontNameLabel, 0)
GUICtrlSetTip($FullFontNameLabel, "Click for detailed font info")

$FullFontNameValue = GUICtrlCreateLabel("", 135, 650, 255, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")

$FamilyLabel = GUICtrlCreateLabel("Font Family:", 10, 675, 120, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$FamilyValue = GUICtrlCreateLabel("", 135, 675, 255, 20)

$SubFamilyLabel = GUICtrlCreateLabel("Font SubFamily:", 10, 700, 120, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SubFamilyValue = GUICtrlCreateLabel("", 135, 700, 255, 20)

; Footer / error area
; Create EraseSampleLabel first (used to temporarily hide preview region when needed)
$EraseSampleLabel = GUICtrlCreateLabel("", 10, 730, 380, 65)
GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)
; Create ErrorLabel after so it's above EraseSampleLabel in Z-order and taller
$ErrorLabel = GUICtrlCreateLabel("", 10, 730, 375, 65)
GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")
; use a visible error colour
GUICtrlSetColor ($ErrorLabel, 0xFF4000)
GUICtrlSetState($ErrorLabel, $GUI_HIDE)

; Splash (scanning)
$SplashScreen = GUICreate("RainFont", 210, 50, -1, -1, BitOR($WS_SYSMENU, $WS_POPUP, $WS_POPUPWINDOW, $WS_BORDER, $WS_CLIPSIBLINGS))
$SplashLabel = GUICtrlCreateLabel("Scanning Fonts", 1, 12, 200, 30, $SS_CENTER)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
GUISetState(@SW_SHOWNORMAL, $SplashScreen)

; populate windows fonts into list (initial)
$g_View = "windows"
If Not IsArray($g_ListPaths) Then Dim $g_ListPaths[0]
_PopulateWindowsFonts()
_UpdateSelectOneLabel() ; set initial dynamic instruction text
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
			ToolTip("FontFace setting now in Windows Clipboard",Default,Default,"Copied",1,3)
			Sleep(1200)
			ToolTip("")

		Case $CopyFontSubButton
			ClipPut(GUICtrlRead($FontSubInput))
			ToolTip("StringStyle setting now in Windows Clipboard",Default,Default,"Copied",1,3)
			Sleep(1200)
			ToolTip("")

		Case $FullFontNameLabel
			; show detailed font info (uses last parsed font info stored in $g_LastFontInfo)
			If IsArray($g_LastFontInfo) Then
				_ArrayDisplay($g_LastFontInfo)
			Else
				_ShowError("No font information available. Select a font first.")
			EndIf

		Case $BtnWindows
			; switch view to Windows fonts
			$g_View = "windows"
			_PopulateWindowsFonts()
			_UpdateSelectOneLabel()
			; ensure first item selected & visible
			_GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
			_GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)

		Case $BtnSetSkins
			; choose skins folder and save
			Local $sPick = FileSelectFolder("Select Rainmeter Skins folder", $g_SkinsFolder, 1)
			If Not @error And $sPick <> "" Then
				$g_SkinsFolder = $sPick
				Local $h = FileOpen(@ScriptDir & "\RainFont.skins", 2)
				If $h <> -1 Then
					FileWriteLine($h, $g_SkinsFolder)
					FileClose($h)
				EndIf
				If $g_View = "skins" Then _UpdateSelectOneLabel()
			EndIf

		Case $BtnSkins
			; switch view to skins fonts (requires skins folder)
			If $g_SkinsFolder = "" Or Not FileExists($g_SkinsFolder) Then
				MsgBox(48, "Skins folder not set", "Please set the Rainmeter Skins folder first using 'Set Skins Folder'.")
			Else
				$g_View = "skins"
				_UpdateSelectOneLabel()
				_PopulateSkinsFonts($g_SkinsFolder)
				; no preview here — _PopulateSkinsFonts previews the first item after populating
			EndIf

		Case $WindowsFontsList
			; ignore selection events fired while populating the list
			If $g_Populating Then ContinueLoop

			; selection behavior depends on current view
			If $g_View = "windows" Then
				; installed font selected
				Local $sLine = GUICtrlRead($WindowsFontsList)
				Local $aMatch = StringRegExp($sLine, '\[File: (.*)\]', 3)
				Local $sFileName
				If @error Or Not IsArray($aMatch) Then
					$sFileName = $sLine
				Else
					$sFileName = $aMatch[0]
				EndIf
				Local $sFullPath = @WindowsDir & "\Fonts\" & $sFileName
				If FileExists($sFullPath) Then
					_ProcessFontFile($sFullPath, True)
				Else
					_ShowError("Font file not found: " & $sFullPath)
				EndIf

			ElseIf $g_View = "skins" Then
				; SKINS VIEW — robust selection handling without changing the list selection
				Local $iSel = _GUICtrlListBox_GetCurSel($WindowsFontsList)
				If $iSel = -1 Then ExitLoop

				; Fast path: use index to get full path if available
				Local $sFull = ""
				If IsArray($g_ListPaths) And $iSel >= 0 And $iSel < UBound($g_ListPaths) Then
					$sFull = $g_ListPaths[$iSel]
					; verify that the basename matches the visible list item (defensive)
					Local $sVisibleName = GUICtrlRead($WindowsFontsList) ; visible text
					If _GetFileNameFromPath($sFull) <> $sVisibleName Then
						$sFull = "" ; fallback to search without changing selection
					EndIf
				EndIf

				; Fallback: search g_ListPaths for a matching basename (do NOT change the list selection)
				If $sFull = "" And IsArray($g_ListPaths) Then
					Local $sVisibleName = GUICtrlRead($WindowsFontsList)
					For $j = 0 To UBound($g_ListPaths) - 1
						If _GetFileNameFromPath($g_ListPaths[$j]) = $sVisibleName Then
							$sFull = $g_ListPaths[$j]
							ExitLoop
						EndIf
					Next
				EndIf

				If $sFull <> "" Then
					_ProcessFontFile($sFull, False)
				Else
					; No matching full path found — show an informative message
					_ShowError("Could not resolve selection to a font file.")
				EndIf
			EndIf

		Case $BrowseButton
			$FileToLoad = FileOpenDialog("Open font file", $CurrentBrowseDir, "Font Files (*.ttf;*.otf;*.ttc)", 3)
			If Not @error Then
				; update RainFont.dir default starting folder immediately
				Dim $szDrive, $szDir, $szFName, $szExt
				$SplitFileToLoad = _PathSplit($FileToLoad, $szDrive, $szDir, $szFName, $szExt)
				$CurrentBrowseDir = $SplitFileToLoad[1] & $SplitFileToLoad[2]
				$DirFile = FileOpen(@ScriptDir & "\RainFont.dir", 2)
				If $DirFile <> -1 Then
					FileWriteLine($DirFile, $CurrentBrowseDir)
					FileClose($DirFile)
				EndIf
				GUICtrlSetData($FontFileInput, $FileToLoad)
				_ProcessFontFile($FileToLoad, False)
			EndIf

		Case $SaveFolderBtn
			; Save the folder portion of the path in $FontFileInput to RainFont.dir
			Local $sPath = GUICtrlRead($FontFileInput)
			If $sPath = "" Then
				MsgBox(48, "No path", "Please place or browse to a file first, then click Save Folder to save its folder.")
			Else
				Dim $szD, $szP, $szN, $szE
				_PathSplit($sPath, $szD, $szP, $szN, $szE)
				Local $sFolder = $szD & $szP
				If $sFolder = "" Or Not FileExists($sFolder) Then
					MsgBox(48, "Invalid folder", "The folder could not be determined or does not exist.")
				Else
					Local $h = FileOpen(@ScriptDir & "\RainFont.dir", 2)
					If $h <> -1 Then
						FileWriteLine($h, $sFolder)
						FileClose($h)
						$CurrentBrowseDir = $sFolder
						ToolTip("Saved default folder: " & $sFolder, Default, Default, "Saved", 1, 2)
						Sleep(1000)
						ToolTip("")
					EndIf
				EndIf
			EndIf

		Case $LinkLabel
			ShellExecute("https://docs.rainmeter.net/tips/fonts-guide/")
	EndSwitch
WEnd

; ---------- Helper: process a font file (parse, update UI, draw sample) ----------
; returns True on success, False on failure
; Replace existing _ProcessFontFile in RainFont.au3 with the function below
Func _ProcessFontFile($sFullPath, $bInstalled)
    If $sFullPath = "" Then Return False
    If Not FileExists($sFullPath) Then
        _HideError()
        _ShowError($sFullPath & " not found.")
        Return False
    EndIf

    ; read file in binary (safe)
    Local $hFile = FileOpen($sFullPath, 16)
    If $hFile = -1 Then
        _HideError()
        _ShowError("Unable to open " & $sFullPath)
        Return False
    EndIf
    Local $sFontData = FileRead($hFile)
    FileClose($hFile)

    If BinaryLen($sFontData) = 0 Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sFullPath) & " could not be read or is empty.")
        Return False
    EndIf

    Local $aInfo = _RH_TTF_GetInfo($sFontData)
    ; store last parsed info for FullFontName click handler
    $g_LastFontInfo = $aInfo

    For $i = 0 To UBound($aInfo) - 1
        If $aInfo[$i][2] <> "" And $aInfo[$i][1] = "" Then $aInfo[$i][1] = $aInfo[$i][2]
    Next

    If IsArray($aInfo) = 0 Or $aInfo[1][1] = "" Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sFullPath) & @CRLF & "does not appear to be a valid TrueType/OpenType font for Rainmeter!")
        Return False
    EndIf

    ; populate UI fields
    _HideError()
    GUICtrlSetState ($FontNameInput, $GUI_ENABLE)
    GUICtrlSetState ($CopyFontNameButton, $GUI_ENABLE)
    GUICtrlSetData($FontNameInput, "FontFace=" & $aInfo[1][1])
    GUICtrlSetData($FullFontNameValue, $aInfo[4][1])
    GUICtrlSetData($FamilyValue, $aInfo[1][1])
    GUICtrlSetData($SubFamilyValue, $aInfo[2][1])

    If StringUpper($aInfo[2][1]) = "ITALIC" Then
        GUICtrlSetData($FontSubInput, "StringStyle=Italic")
        GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
        GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
        $FontStyle = 2
    ElseIf StringUpper($aInfo[2][1]) = "BOLD" Then
        GUICtrlSetData($FontSubInput, "StringStyle=Bold")
        GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
        GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
        $FontStyle = 1
    ElseIf StringUpper($aInfo[2][1]) = "BOLD ITALIC" Or StringUpper($aInfo[2][1]) = "BOLDIT" Then
        GUICtrlSetData($FontSubInput, "StringStyle=BoldItalic")
        GUICtrlSetState ($FontSubInput, $GUI_ENABLE)
        GUICtrlSetState ($CopyFontSubButton, $GUI_ENABLE)
        $FontStyle = 3
    Else
        GUICtrlSetData($FontSubInput, "StringStyle=")
        GUICtrlSetState ($FontSubInput, $GUI_DISABLE)
        GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)
        $FontStyle = 0
    EndIf

    ; --- Clear previous preview (erase the preview rectangle via Windows invalidation) ---
    ; Preview Position (part 1 of 2) Must keep both parts same position/size!
    _ClearPreviewArea($Mainform, 10, 530, 360, 50)

    ; Draw preview using GDI+ (with robust fallback for external fonts)
    _GDIPlus_Startup()
    $hGraphic = _GDIPlus_GraphicsCreateFromHWND($Mainform)

    ; font size used for preview (change if you want larger/smaller preview text)
    Local $iFontSize = 18

    Local $hFamily = 0, $hFont = 0
    Local $bTempAddedFont = False ; whether we temporarily loaded via AddFontResourceEx

    If $bInstalled Then
        ; installed font: create by name
        $hFamily = _GDIPlus_FontFamilyCreate($aInfo[1][1])
        $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $FontStyle, 3)
    Else
        ; 1) Try private GDI+ collection (existing approach)
        Local $aNew = DllCall("gdiplus.dll", 'int', 'GdipNewPrivateFontCollection', 'ptr*', 0)
        If IsArray($aNew) And $aNew[0] = 0 Then
            Local $hCollection = $aNew[1]
            DllCall("gdiplus.dll", 'int', 'GdipPrivateAddFontFile', 'ptr', $hCollection, 'wstr', $sFullPath)
            Local $aCF = DllCall("gdiplus.dll", 'int', 'GdipCreateFontFamilyFromName', 'wstr', $aInfo[1][1], 'ptr', $hCollection, 'ptr*', 0)
            ; If call succeeded, last array entry is the family pointer (best-effort extraction)
            If IsArray($aCF) And $aCF[0] = 0 And UBound($aCF) > 1 Then
                $hFamily = $aCF[UBound($aCF)-1]
            EndIf
            If $hFamily Then
                $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $FontStyle)
            EndIf
            ; free private collection handle (we already got family/font)
            DllCall("gdiplus.dll", 'int', 'GdipDeletePrivateFontCollection', 'ptr*', $hCollection)
        EndIf

        ; 2) If that failed to create a usable font, try AddFontResourceExW (private, process-only)
        If Not $hFont Then
            Local $aAdd = DllCall("gdi32.dll", "int", "AddFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
            If IsArray($aAdd) And $aAdd[0] > 0 Then
                $bTempAddedFont = True
                ; give GDI/GDI+ a moment (usually not needed but helps on some systems)
                Sleep(20)
                ; Now try creating a family by name from the newly-loaded resource
                $hFamily = _GDIPlus_FontFamilyCreate($aInfo[1][1])
                If $hFamily Then
                    $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $FontStyle, 3)
                EndIf
            EndIf
        EndIf

        ; 3) last fallback: try to create font family by name anyway (may use installed font if name matches)
        If Not $hFont Then
            $hFamily = _GDIPlus_FontFamilyCreate($aInfo[1][1])
            $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $FontStyle, 3)
        EndIf
    EndIf

    ; If we still have no font object, show a helpful footer error and bail
    If Not IsHWnd($hFont) And Not IsPtr($hFont) And $hFont = 0 Then
        ; hide any preview area and show error
        _HideError()
        _ShowError("Unable to create preview for: " & _GetFileNameFromPath($sFullPath))
        ; remove temp-added font if we added it
        If $bTempAddedFont Then DllCall("gdi32.dll", "int", "RemoveFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
        ; ensure cleanup of GDI+ graphics
        _GDIPlus_GraphicsDispose($hGraphic)
        _GDIPlus_Shutdown()
        Return False
    EndIf

    ; draw preview text
    $hBrush = _GDIPlus_BrushCreateSolid(0xFF303030)
    $hFormat = _GDIPlus_StringFormatCreate()
    ; Preview Position (part 2 of 2) Must keep both parts same position/size!
    $tLayout = _GDIPlus_RectFCreate(10, 530, 360, 50)
    _GDIPlus_GraphicsDrawStringEx($hGraphic, "ABCXYZabcxyz1290#?&%", $hFont, $tLayout, $hFormat, $hBrush)

    ; dispose GDI+ objects
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontFamilyDispose($hFamily)
    _GDIPlus_StringFormatDispose($hFormat)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_GraphicsDispose($hGraphic)
    _GDIPlus_Shutdown()

    ; If we temporarily added the font to the process, remove it now
    If $bTempAddedFont Then
        DllCall("gdi32.dll", "int", "RemoveFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
    EndIf

    ; update current browse dir to the file's folder (so next Browse opens there)
    If Not $bInstalled Then
        Local $szD, $szP, $szN, $szE
        _PathSplit($sFullPath, $szD, $szP, $szN, $szE)
        $CurrentBrowseDir = $szD & $szP
        Local $hSave = FileOpen(@ScriptDir & "\RainFont.dir", 2)
        If $hSave <> -1 Then
            FileWriteLine($hSave, $CurrentBrowseDir)
            FileClose($hSave)
        EndIf
    EndIf

    Return True
EndFunc ;==>_ProcessFontFile

; Helper: update the top instruction label to reflect current view
Func _UpdateSelectOneLabel()
    If $g_View = "windows" Then
        GUICtrlSetData($SelectOneLabel, "Select an installed font from ""Windows"" Fonts" & @CRLF & "or browse to find and select an uninstalled font:")
    Else
        GUICtrlSetData($SelectOneLabel, "Select an installed font from ""Rainmeter\Skins"" Fonts" & @CRLF & "or browse to find and select an uninstalled font:")
    EndIf
EndFunc

; Helper: erase (invalidate) the preview rectangle and force an immediate repaint.
Func _ClearPreviewArea($hWnd, $iX, $iY, $iW, $iH)
    Local $tRect = DllStructCreate("long Left; long Top; long Right; long Bottom")
    DllStructSetData($tRect, "Left", $iX)
    DllStructSetData($tRect, "Top", $iY)
    DllStructSetData($tRect, "Right", $iX + $iW)
    DllStructSetData($tRect, "Bottom", $iY + $iH)
    ; InvalidateRect(hWnd, rectPtr, bEraseBackground)
    DllCall("user32.dll", "int", "InvalidateRect", "hwnd", $hWnd, "ptr", DllStructGetPtr($tRect), "int", 1)
    ; UpdateWindow forces an immediate WM_PAINT to erase background
    DllCall("user32.dll", "int", "UpdateWindow", "hwnd", $hWnd)
EndFunc

; Helper: show/hide footer error text safely
Func _ShowError($sText)
    ; Hide the EraseSample label to ensure error is visible
    GUICtrlSetState($EraseSampleLabel, $GUI_HIDE)
    GUICtrlSetData($ErrorLabel, $sText)
    GUICtrlSetState($ErrorLabel, $GUI_SHOW)
    ; Bring error label to front (ensure visibility)
    Local $hErr = GUICtrlGetHandle($ErrorLabel)
    If $hErr Then DllCall("user32.dll", "int", "SetWindowPos", "hwnd", $hErr, "hwnd", 0, "int", 0, "int", 0, "int", 0, "int", 0, "int", 0x0001 + 0x0002)
EndFunc

Func _HideError()
    GUICtrlSetState($ErrorLabel, $GUI_HIDE)
EndFunc

Func _GetFileNameFromPath($sPath)
    If $sPath = "" Then Return ""
    Local $szDrive, $szDir, $szFName, $szExt
    _PathSplit($sPath, $szDrive, $szDir, $szFName, $szExt)
    Return $szFName & $szExt
EndFunc

; -------------------------
; Populate Windows Fonts list (registry)
; -------------------------
Func _PopulateWindowsFonts()
	; clear list and reset
	GUICtrlSetData($WindowsFontsList, "")
	; read registry and fill list
	Local $aReg[1][2], $i = 1
	While 1
		ReDim $aReg[$i + 1][2]
		$aReg[$i][0] = StringReplace(RegEnumVal("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",$i), " (TrueType)", "", 0, 0)
		$aReg[$i][1] = RegRead ("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", RegEnumVal("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",$i))
		If @Error = -1 Then ExitLoop
		$i = $i + 1
	WEnd

	_ArrayDelete($aReg, $i)
	_ArraySort($aReg)

	$a = 1
	While $a <= UBound($aReg) -1
		if StringInStr(StringLower($aReg[$a][1]), ".ttf") = 0 And StringInStr(StringLower($aReg[$a][1]), ".otf") = 0 And StringInStr(StringLower($aReg[$a][1]), ".ttc") = 0 Then
			_ArrayDelete($aReg, $a)
			If $a > 1 Then $a = $a - 1
		Else
			GUICtrlSetData($WindowsFontsList, $aReg[$a][0] & "   [File: " & $aReg[$a][1] & "]", "")
			$a = $a + 1
		EndIf
	WEnd

	; select first item by default
	_GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
	_GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
EndFunc ;==>_PopulateWindowsFonts

; -------------------------
; Populate Skins Fonts list (recursive)
; -------------------------
Func _PopulateSkinsFonts($sFolder)
	; indicate we are populating so selection events are ignored
	$g_Populating = True

	GUICtrlSetData($WindowsFontsList, "")
	; ensure $g_ListPaths is an array
	If Not IsArray($g_ListPaths) Then Dim $g_ListPaths[0]
	Local $aFound[1] = [0] ; will use dynamic _ArrayAdd
	_ScanFontsRec($sFolder, $aFound)
	; aFound holds full paths
	If Not IsArray($aFound) Or UBound($aFound) <= 1 Then
		GUICtrlSetData($WindowsFontsList, "No font files found in skins folder.")
		$g_ListPaths = ""
		$g_Populating = False
		Return
	EndIf
	; actual items start at index 1
	Local $cnt = UBound($aFound)-1
	ReDim $g_ListPaths[$cnt]
	Local $iOut = 0
	For $i = 1 To UBound($aFound)-1
		Local $full = $aFound[$i]
		Local $name = _GetFileNameFromPath($full)
		GUICtrlSetData($WindowsFontsList, $name, "")
		$g_ListPaths[$iOut] = $full
		$iOut += 1
	Next
	; select first item and show preview to keep UI in sync
	_GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
	_GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)

	; preview first item after population (now stable)
	If IsArray($g_ListPaths) And UBound($g_ListPaths) > 0 Then _ProcessFontFile($g_ListPaths[0], False)

	$g_Populating = False
EndFunc ;==>_PopulateSkinsFonts

; recursive scan helper: adds found font full paths to array (1-based append)
Func _ScanFontsRec($sFolder, ByRef $aOut)
	Local $h = FileFindFirstFile($sFolder & "\*.*")
	If $h = -1 Then Return
	Local $sFile = FileFindNextFile($h)
	While Not @error
		If $sFile <> "." And $sFile <> ".." Then
			Local $full = $sFolder & "\" & $sFile
			Local $attr = FileGetAttrib($full)
			If @error = 0 And StringInStr($attr, "D") Then
				_ScanFontsRec($full, $aOut)
			Else
				Local $sLow = StringLower($sFile)
				If StringInStr($sLow, ".ttf") Or StringInStr($sLow, ".otf") Or StringInStr($sLow, ".ttc") Then
					_ArrayAdd($aOut, $full)
				EndIf
			EndIf
		EndIf
		$sFile = FileFindNextFile($h)
	WEnd
	FileClose($h)
EndFunc ;==>_ScanFontsRec

; ---------- TTF/OTF name table parser (permissive) ----------
Func _RH_TTF_GetInfo($bBinary)
    If BinaryLen($bBinary) < 4 Then Return SetError(1, 0, 0)
    Local $s4 = BinaryToString(BinaryMid($bBinary, 1, 4))
    If $s4 = "ttcf" Then Return SetError(1, 0, 0)

    Local $tBinary = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
    DllStructSetData($tBinary, 1, $bBinary)
    Local $pBinary = DllStructGetPtr($tBinary)
    Local $pPointer = $pBinary

    Local $tTT_OFFSET_TABLE = DllStructCreate("dword sfnt;word NumOfTables;word SearchRange;word EntrySelector;word RangeShift;", $pPointer)
    $pPointer += 12
    Local $iNumOfTables = DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables")

    Local $iOffset = 0
    Local $tTT_TABLE_DIRECTORY
    For $i = 1 To $iNumOfTables
        $tTT_TABLE_DIRECTORY = DllStructCreate("char Tag[4];dword CheckSum;dword Offset;dword Length;", $pPointer)
        $pPointer += 16
        If DllStructGetData($tTT_TABLE_DIRECTORY, "Tag") == "name" Then
            $iOffset = _RH_BigEndianToInt(DllStructGetData($tTT_TABLE_DIRECTORY, "Offset"), 4)
            ExitLoop
        EndIf
    Next
    If Not $iOffset Then Return SetError(2, 0, 0)

    $pPointer = $pBinary + $iOffset
    Local $pDir = $pPointer
    Local $tTT_NAME_TABLE_HEADER = DllStructCreate("word FSelector;word NRCount;word StorageOffset;", $pPointer)
    $pPointer += 6
    Local $iNRCount = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "NRCount"), 2)
    Local $iStorageOffset = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "StorageOffset"), 2)

    Local $aInfo[28][3] = [["Copyright notice"],["Font Name"],["Subfamily Name"],["Identifier"],["Full font Name"],["Version"],["Postscript Name"],["Trademark"],["Manufacturer"],["Designer"],["Description"],["URL Vendor"], _
            ["URL Designer"],["License Description"],["License Info URL"],["Reserved Field "],["Preferred Family"],["Preferred Subfamily"],["Compatible Full"],["Sample text"],["PostScript CID Findfont Name"],["WWS Family Name"],["WWS Subfamily Name"]]
    Local $tTT_NAME_RECORD, $bString, $iNameID, $iPlatform
    Local $iLangID = -1
    For $i = 1 To $iNRCount
        $tTT_NAME_RECORD = DllStructCreate("word PlatformID;word EncodingID;word LanguageID;word NameID;word StringLength;word StringOffset;", $pPointer)
        $pPointer += 12
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
    Local $tTT_OFFSET_TABLE = DllStructCreate("word MajorVersion;word MinorVersion;word NumOfTables;word SearchRange;word EntrySelector;word RangeShift;", $pPointer)
    $pPointer += 12
    If DllStructGetData($tTT_OFFSET_TABLE, "MajorVersion") <> 256 And DllStructGetData($tTT_OFFSET_TABLE, "MinorVersion") <> 0 Then Return SetError(1, 0, 0)
    Local $iNumOfTables = 265 * BitAND(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 0xF) + BitShift(DllStructGetData($tTT_OFFSET_TABLE, "NumOfTables"), 8)
    Local $iOffset
    Local $tTT_TABLE_DIRECTORY
    For $i = 1 To $iNumOfTables
        $tTT_TABLE_DIRECTORY = DllStructCreate("char Tag[4];dword CheckSum;dword Offset;dword Length;", $pPointer)
        $pPointer += 16
        If DllStructGetData($tTT_TABLE_DIRECTORY, "Tag") == "OS/2" Then
            $iOffset = _RH_BigEndianToInt(DllStructGetData($tTT_TABLE_DIRECTORY, "Offset"), 4)
            ExitLoop
        EndIf
    Next
    If Not $iOffset Then Return SetError(2, 0, 0)

    $pPointer = $pBinary + $iOffset
    Local $tFontMetrics = DllStructCreate("align 1;word Version;short AvgCharWidth;word WeightClass;word WidthClass;word Type;short SubscriptXSize;short SubscriptYSize;short SubscriptXOffset;short SubscriptYOffset;short SuperscriptXSize;short SuperscriptYSize;short SuperscriptXOffset;short SuperscriptYOffset;short StrikeoutSize;short StrikeoutPosition;short FamilyClass;byte Panose[10];dword UnicodeRange1;dword UnicodeRange2;dword UnicodeRange3;dword UnicodeRange4;char VendID[4];word Selection;word FirstCharIndex;word LastCharIndex;short TypoAscender;short TypoDescender;short TypoLineGap;word WinAscent;word WinDescent;dword CodePageRange1;dword CodePageRange2;", $pPointer)
    Local $aArray[7][2] = [["Name", ""], ["Height", 10], ["Weight", _RH_BigEndianToInt(DllStructGetData($tFontMetrics, "WeightClass"))], ["Italic", BitAND(DllStructGetData($tFontMetrics, "Selection"), 1) = True], ["Underline", BitAND(BitShift(DllStructGetData($tFontMetrics, "Selection"), 1), 1) = True], ["StrikeOut", BitAND(BitShift(DllStructGetData($tFontMetrics, "Selection"), 4), 1) = True], ["CharSet", 1]]
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
