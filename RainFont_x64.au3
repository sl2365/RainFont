;*****************************************
; RainFont_x64.au3 updated by sl23
; https://forum.rainmeter.net/viewtopic.php?t=45631
; Original code supplied by JSMorley
; Created with ISN AutoIt Studio v1.16
; Compiled with AutoIt v3.3.16.1
;*****************************************

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=rF.ico
#AutoIt3Wrapper_Res_Fileversion_First_Increment=Y	; AutoIncrement: Before (Y); After (N) compile. Default=N
#AutoIt3Wrapper_Res_FileVersion_AutoIncrement=Y
#AutoIt3Wrapper_Res_Fileversion=3.3.8.45
#AutoIt3Wrapper_Res_ProductVersion=3.3.16.1
#AutoIt3Wrapper_Res_Description=RainFont_x64
#AutoIt3Wrapper_Res_LegalCopyright=sl23
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#RequireAdmin
#include <Array.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <ListBoxConstants.au3>
#include <GDIPlus.au3>
#include <StaticConstants.au3>
#include "Metrics.au3"
#include "RainFont_Render.au3"

; -------------------------
; Globals used by renderer/UI
; -------------------------
Global $Mainform
Global $CurrentBrowseDir, $g_SkinsFolder, $g_View, $g_ListPaths, $g_Populating
Global $g_LastFontInfo
Global $g_LastFontPath = ""
; renderer handle globals (ensure they exist when GUI cleanup runs)
Global $hGraphic = 0
Global $hFont = 0
Global $hFamily = 0
Global $hFormat = 0
Global $hBrush = 0
Global $hMemHandle = 0
; Preview rectangle (change these in one place)
Global $PREV_X = 10
Global $PREV_Y = 445
Global $PREV_W = 380
Global $PREV_H = 70

; Debounce globals (for listbox selection)
Global $g_LastSelectionTimer = 0
Global $g_LastSelectionIndex = -1

; Cache of user-font paths (in-memory, cleared on exit)
Global $g_UserListPaths

; Start state
Opt("TrayIconHide", 1)
Opt("GUICloseOnESC", 0)
_Singleton("RainFont", 0)

; --- Working folder & embed/extract banner (original behavior) ---
$WorkingDir = @TempDir & "\RainFont\"
DirCreate($WorkingDir)

; FileInstall will embed RainFont.bmp into the compiled EXE at compile-time.
; When compiled the EXE will extract the embedded file into %TEMP%\RainFont\RainFont.bmp
If @Compiled Then
    Local $sDest = $WorkingDir & "RainFont.bmp"
    If Not FileExists($sDest) Then FileInstall("RainFont.bmp", $sDest, 1)
Else
    ; For running from source, copy the banner into temp working folder if present
    If FileExists(@ScriptDir & "\RainFont.bmp") And Not FileExists($WorkingDir & "RainFont.bmp") Then
        FileCopy(@ScriptDir & "\RainFont.bmp", $WorkingDir & "RainFont.bmp", 1)
    EndIf
EndIf

; Current browse dir (preserve original behavior)
$CurrentBrowseDir = ".\"

; read saved browse folder if present
If FileExists(@ScriptDir & "\RainFont.dir") Then
    Local $DirFile = FileOpen(@ScriptDir & "\RainFont.dir", 0)
    If $DirFile <> -1 Then
        Local $DirLine = FileReadLine($DirFile)
        If $DirLine <> "" Then $CurrentBrowseDir = $DirLine
        FileClose($DirFile)
    EndIf
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

; Ensure list paths array exists
If Not IsArray($g_ListPaths) Then Dim $g_ListPaths[0]

; ------------------------------------------------------------------
; Add: Cache builder for user fonts (reuses _ScanFontsRec)
; ------------------------------------------------------------------
Func _CacheUserFonts()
    ; Build an in-memory list of user font file paths.
    ; This does not touch GUI controls; it only fills $g_UserListPaths.
    If IsArray($g_UserListPaths) And UBound($g_UserListPaths) > 0 Then Return True

    Local $sUser = EnvGet("USERPROFILE")
    Local $aLikely[7] = [ _
        $sUser & "\Desktop", _
        $sUser & "\Downloads", _
        $sUser & "\Documents", _
        $sUser & "\Pictures", _
        $sUser & "\AppData\Roaming\Microsoft\Windows\Fonts", _
        $sUser & "\AppData\Local\Microsoft\Windows\Fonts", _
        $sUser & "\AppData\Local" _
    ]

    Local $aFound[1] = [0]
    For $i = 0 To UBound($aLikely) - 1
        If $aLikely[$i] <> "" And FileExists($aLikely[$i]) Then
            _ScanFontsRec($aLikely[$i], $aFound)
        EndIf
    Next

    If Not IsArray($aFound) Or UBound($aFound) <= 1 Then
        ; Ensure cached array exists but empty
        If IsArray($g_UserListPaths) Then
            ReDim $g_UserListPaths[0]
        Else
            Dim $g_UserListPaths[0]
        EndIf
        Return False
    EndIf

    Local $cnt = UBound($aFound) - 1
    If IsArray($g_UserListPaths) Then
        ReDim $g_UserListPaths[$cnt]
    Else
        Dim $g_UserListPaths[$cnt]
    EndIf

    Local $idx = 0
    For $j = 1 To UBound($aFound) - 1
        $g_UserListPaths[$idx] = $aFound[$j]
        $idx += 1
    Next
    Return True
EndFunc
; ------------------------------------------------------------------

; Main window (single GUI) — load banner from the working dir if present
$Mainform = GUICreate("RainFont", 400, 660, -1, -1)
If FileExists($WorkingDir & "RainFont.bmp") Then GUICtrlCreatePic($WorkingDir & "RainFont.bmp", 0, 0, 400, 60)

GUICtrlCreateLabel("Welcome to RainFont_x64", 10, 67, 150, 19)
GUICtrlSetFont(-1, 9, 700, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x946300)

; Help label: make it a control so we can respond to clicks
$HelpLabel = GUICtrlCreateLabel("Help", 358, 67, 100, 19)
GUICtrlSetFont($HelpLabel, 9, 400, 4, "Segoe UI")
GUICtrlSetColor($HelpLabel, 0x3981E5)
; Set hand cursor if available (best-effort). 32649 is commonly IDC_HAND.
GUICtrlSetCursor($HelpLabel, 32649)

; Buttons
$BtnWindows = GUICtrlCreateButton("Windows", 10, 88, 70, 25)
$BtnUser = GUICtrlCreateButton("User", 90, 88, 70, 25)
$BtnSkins = GUICtrlCreateButton("Skins", 170, 88, 70, 25)
$BtnSetSkins = GUICtrlCreateButton("Set Skins Folder", 290, 88, 100, 25)

$SelectOneLabel = GUICtrlCreateLabel("", 10, 117, 380, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

$WindowsFontsList = GUICtrlCreateList("", 10, 155, 380, 260, BitOR($GUI_SS_DEFAULT_LIST,$WS_HSCROLL))
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetLimit ($WindowsFontsList, 460)

$BrowseButton = GUICtrlCreateButton("Browse", 10, 410, 60, 25)
$FontFileInput = GUICtrlCreateInput("Browse your computer for a font file...", 75, 410, 285, 25)
$SaveFolderBtn = GUICtrlCreateButton("💾", 365, 410, 25, 25)

$FontNameInput = GUICtrlCreateInput("", 10, 520, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontNameButton = GUICtrlCreateButton("C", 370, 520, 20, 25)
GUICtrlSetState ($CopyFontNameButton, $GUI_DISABLE)
$FontSubInput = GUICtrlCreateInput("", 10, 550, 354, 25)
GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
$CopyFontSubButton = GUICtrlCreateButton("C", 370, 550, 20, 25)
GUICtrlSetState ($CopyFontSubButton, $GUI_DISABLE)

$FullFontNameLabel = GUICtrlCreateLabel("Full Font Name:", 10, 585, 120, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0x3981E5)

$FullFontNameValue = GUICtrlCreateLabel("", 135, 585, 255, 20)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x946300)

$FamilyLabel = GUICtrlCreateLabel("Font Family:", 10, 610, 120, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$FamilyValue = GUICtrlCreateLabel("", 135, 610, 255, 20)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x946300)

$SubFamilyLabel = GUICtrlCreateLabel("Font SubFamily:", 10, 635, 120, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SubFamilyValue = GUICtrlCreateLabel("", 135, 635, 255, 20)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x946300)

$EraseSampleLabel = GUICtrlCreateLabel("", $PREV_X, $PREV_Y, $PREV_W, $PREV_H)
GUICtrlSetState ($EraseSampleLabel, $GUI_HIDE)
$ErrorLabel = GUICtrlCreateLabel("", $PREV_X, $PREV_Y, $PREV_W, $PREV_H)
GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")
GUICtrlSetColor ($ErrorLabel, 0xFF4000)
GUICtrlSetState($ErrorLabel, $GUI_HIDE)

; Splash (centered)
Local $w = 320, $h = 80
Local $x = Int((@DesktopWidth - $w) / 2)
Local $y = Int((@DesktopHeight - $h) / 2)
$SplashScreen = GUICreate("RainFont", $w, $h, $x, $y, BitOR($WS_SYSMENU, $WS_POPUP, $WS_POPUPWINDOW, $WS_BORDER, $WS_CLIPSIBLINGS))
$SplashLabel = GUICtrlCreateLabel("Scanning Fonts", 1, 12, 200, 30, $SS_CENTER)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
GUISetState(@SW_SHOWNORMAL, $SplashScreen)

; populate windows fonts into list (initial)
$g_View = "windows"
_PopulateWindowsFonts()

; Pre-cache user fonts while the splash is visible (no GUI change, reuse existing scanner)
_CacheUserFonts()

_UpdateSelectOneLabel()
GUIDelete($SplashScreen)
GUISetState(@SW_SHOWNORMAL, $Mainform)

; initialize renderer now that GUI is visible
Render_Init()

; preview first item if any
If ($g_View = "skins" Or $g_View = "user") And IsArray($g_ListPaths) And UBound($g_ListPaths) > 0 Then
    Local $iSel = _GUICtrlListBox_GetCurSel($WindowsFontsList)
    If $iSel = -1 Then $iSel = 0
    If $iSel >= 0 And $iSel < UBound($g_ListPaths) Then
        _ProcessFontFile($g_ListPaths[$iSel], False)
    EndIf
EndIf

Send("{HOME}")
_ShowSelectionPreview()

; helpers and event loop
Global $hUserScanSplash = 0
Func ShowUserScanSplash()
    If $hUserScanSplash And WinExists($hUserScanSplash) Then Return
    Local $w = 320, $h = 80
    Local $x = Int((@DesktopWidth - $w) / 2)
    Local $y = Int((@DesktopHeight - $h) / 2)
    $hUserScanSplash = GUICreate("Scanning user folders...", $w, $h, $x, $y, BitOR($WS_POPUP, $WS_BORDER))
    GUICtrlCreateLabel("Scanning user folders... Please wait.", 10, 12, $w - 20, 20)
    GUICtrlCreateLabel("This may take a few seconds.", 10, 32, $w - 20, 20)
    GUISetState(@SW_SHOW, $hUserScanSplash)
    Local $hWnd = WinGetHandle($hUserScanSplash)
    If $hWnd Then
        DllCall("user32.dll", "int", "SetWindowPos", "hwnd", $hWnd, "hwnd", -1, "int", $x, "int", $y, "int", 0, "int", 0, "int", 0x0001)
    EndIf
EndFunc

Func HideUserScanSplash()
    If $hUserScanSplash Then
        GUIDelete($hUserScanSplash)
        $hUserScanSplash = 0
    EndIf
EndFunc

Func _FocusWindowsFontsList()
    ControlFocus($Mainform, "", $WindowsFontsList)
EndFunc

; Show preview/fields for the currently selected item in the top list
Func _ShowSelectionPreview()
    If GUICtrlRead($WindowsFontsList) = "" Then Return

    If $g_View = "windows" Then
        Local $sLine = GUICtrlRead($WindowsFontsList)
        Local $aMatch = StringRegExp($sLine, '\[File:\s*(.+?)\]', 3)
        Local $sFileName = ""
        If IsArray($aMatch) Then
            $sFileName = $aMatch[0]
        Else
            $sFileName = $sLine
        EndIf
        Local $sFullPath = @WindowsDir & "\Fonts\" & $sFileName
        If FileExists($sFullPath) Then
            _ProcessFontFile($sFullPath, True)
        Else
            _ShowError("Font file not found: " & $sFullPath)
        EndIf

    Else
        Local $iSel = _GUICtrlListBox_GetCurSel($WindowsFontsList)
        If $iSel = -1 Then $iSel = 0
        If IsArray($g_ListPaths) And $iSel >= 0 And $iSel < UBound($g_ListPaths) Then
            _ProcessFontFile($g_ListPaths[$iSel], False)
        Else
            _ShowError("Could not resolve selection to a font file.")
        EndIf
    EndIf
EndFunc

; Main loop
While 1
    $UserEvent = GUIGetMsg()
    Switch $UserEvent
        Case $GUI_EVENT_CLOSE
            Render_Shutdown()
            DirRemove($WorkingDir, 1)

            ; clear cached user-list
            If IsArray($g_UserListPaths) Then
                ReDim $g_UserListPaths[0]
            Else
                Dim $g_UserListPaths[0]
            EndIf

            If IsHWnd($hGraphic) Then
                _GDIPlus_GraphicsDispose($hGraphic)
                $hGraphic = 0
            EndIf

            If IsHWnd($hFont) Then
                _GDIPlus_FontDispose($hFont)
                $hFont = 0
            EndIf

            If IsHWnd($hFamily) Then
                _GDIPlus_FontFamilyDispose($hFamily)
                $hFamily = 0
            EndIf

            If IsHWnd($hFormat) Then
                _GDIPlus_StringFormatDispose($hFormat)
                $hFormat = 0
            EndIf

            If IsHWnd($hBrush) Then
                _GDIPlus_BrushDispose($hBrush)
                $hBrush = 0
            EndIf

            ; if a font was added to memory, remove it
            If $hMemHandle Then
                DllCall("gdi32.dll", "int", "RemoveFontMemResourceEx", "ptr", $hMemHandle)
                $hMemHandle = 0
            EndIf

            _GDIPlus_Shutdown()
            Exit

        Case $CopyFontNameButton
            ClipPut(GUICtrlRead($FontNameInput))
            ToolTip("FontFace copied",Default,Default,"Copied",1,3)
            Sleep(1200)
            ToolTip("")

        Case $CopyFontSubButton
            ClipPut(GUICtrlRead($FontSubInput))
            ToolTip("StringStyle copied",Default,Default,"Copied",1,3)
            Sleep(1200)
            ToolTip("")

		Case $FullFontNameLabel
			If IsArray($g_LastFontInfo) Then
				; Open the full, fixed-size Font Metrics window with complete info
				ShowFontMetrics($g_LastFontInfo, $g_LastFontPath)
			Else
				_ShowError("No font information available. Select a font first.")
			EndIf

        Case $BtnWindows
            $g_View = "windows"
            _PopulateWindowsFonts()
            _UpdateSelectOneLabel()
            _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
            _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
            _FocusWindowsFontsList()
            ; ensure first item is previewed
            _ShowSelectionPreview()

        Case $BtnSetSkins
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
            If $g_SkinsFolder = "" Or Not FileExists($g_SkinsFolder) Then
                MsgBox(48, "Skins folder not set", "Please set the Rainmeter Skins folder first using 'Set Skins Folder'.")
            Else
                $g_View = "skins"
                _PopulateSkinsFonts($g_SkinsFolder)
                _UpdateSelectOneLabel()
                _FocusWindowsFontsList()
                ; preview first skin font if available
                _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
                _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
                _ShowSelectionPreview()
            EndIf

        Case $BtnUser
            $g_View = "user"
            ; If cache exists, populate instantly from it (no scanning); otherwise fall back to original scan.
            If IsArray($g_UserListPaths) And UBound($g_UserListPaths) > 0 Then
                $g_Populating = True
                GUICtrlSetData($WindowsFontsList, "")
                If IsArray($g_ListPaths) Then
                    ReDim $g_ListPaths[UBound($g_UserListPaths)]
                Else
                    Dim $g_ListPaths[UBound($g_UserListPaths)]
                EndIf
                For $i = 0 To UBound($g_UserListPaths) - 1
                    Local $full = $g_UserListPaths[$i]
                    Local $name = _GetFileNameFromPath($full)
                    GUICtrlSetData($WindowsFontsList, $name, "")
                    $g_ListPaths[$i] = $full
                Next
                $g_Populating = False
                _UpdateSelectOneLabel()
                _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
                _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
                _FocusWindowsFontsList()
                ; preview first cached user font
                _ShowSelectionPreview()
            Else
                ShowUserScanSplash()
                _PopulateUserFonts_Fast()
                HideUserScanSplash()
                _UpdateSelectOneLabel()
                _FocusWindowsFontsList()
                ; preview first scanned user font
                _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
                _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
                _ShowSelectionPreview()
            EndIf

        Case $WindowsFontsList
            If $g_Populating Then ContinueLoop

            ; Debounce selection events so rapid repeats (or stuck key events) don't block previewing.
            Local $iSelNow = _GUICtrlListBox_GetCurSel($WindowsFontsList)
            If $iSelNow = -1 Then $iSelNow = 0

            If $iSelNow = $g_LastSelectionIndex Then
                If $g_LastSelectionTimer <> 0 And TimerDiff($g_LastSelectionTimer) < 250 Then
                    ContinueLoop ; ignore this rapid repeat event
                EndIf
            EndIf

            ; Update the last-selection timestamp/index (accepted event)
            $g_LastSelectionIndex = $iSelNow
            $g_LastSelectionTimer = TimerInit()

            If $g_View = "windows" Then
                Local $sLine = GUICtrlRead($WindowsFontsList)
                Local $aMatch = StringRegExp($sLine, '\[File:\s*(.+?)\]', 3)
                Local $sFileName = ""
                If IsArray($aMatch) Then
                    $sFileName = $aMatch[0]
                Else
                    $sFileName = $sLine
                EndIf
                Local $sFullPath = @WindowsDir & "\Fonts\" & $sFileName
                If FileExists($sFullPath) Then
                    _ProcessFontFile($sFullPath, True)
                Else
                    _ShowError("Font file not found: " & $sFullPath)
                EndIf

            ElseIf $g_View = "skins" Or $g_View = "user" Then
                ; use the debounced index ($iSelNow) already computed
                If $iSelNow = -1 Then ExitLoop
                Local $sFull = ""
                If IsArray($g_ListPaths) And $iSelNow >= 0 And $iSelNow < UBound($g_ListPaths) Then
                    $sFull = $g_ListPaths[$iSelNow]
                    Local $sVisibleName = GUICtrlRead($WindowsFontsList)
                    If _GetFileNameFromPath($sFull) <> $sVisibleName Then
                        $sFull = ""
                    EndIf
                EndIf
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
                    _ShowError("Could not resolve selection to a font file.")
                EndIf
            EndIf

        Case $BrowseButton
            $FileToLoad = FileOpenDialog("Open font file", $CurrentBrowseDir, "Font Files (*.ttf;*.otf;*.ttc)", 3)
            If Not @error Then
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

        Case $HelpLabel
            ; Open the forum help page in the user's default browser
            ShellExecute("https://docs.rainmeter.net/tips/fonts-guide/")
    EndSwitch
WEnd

; ---------- Helper: process a font file (includes TTC handling) ----------
Func _BE_DWORD_FromBinary($b4)
    If BinaryLen($b4) <> 4 Then Return SetError(1, 0, 0)
    Local $s = BinaryToString($b4)
    Local $v = 0
    For $i = 1 To 4
        $v = $v * 256 + Asc(StringMid($s, $i, 1))
    Next
    Return $v
EndFunc

Func _ProcessFontFile($sFullPath, $bInstalled)
    If $sFullPath = "" Then Return False
    If Not FileExists($sFullPath) Then
        _HideError()
        _ShowError($sFullPath & " not found.")
        Return False
    EndIf

    ; ---- START: reject .ttc font collections early to avoid crashes ----
    Local $szD, $szP, $szN, $szE
    _PathSplit($sFullPath, $szD, $szP, $szN, $szE)
    If StringLower($szE) = ".ttc" Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sFullPath) & @CRLF & _
                   "Font collections (.ttc) are not supported. Please select a single .ttf or .otf file.")
        Return False
    EndIf
    ; ---- END: reject .ttc ----

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

    ; detect TTC and abort early (we already filtered by extension above)
    Local $sOriginalPath = $sFullPath
    Local $sTempFacePath = ""
    Local $sMagic = ""
    If BinaryLen($sFontData) >= 4 Then $sMagic = BinaryToString(BinaryMid($sFontData, 1, 4))

    If $sMagic = "ttcf" Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sOriginalPath) & @CRLF & "Font collections (.ttc) are not supported.")
        Return False
    EndIf

    ; parse name table
    Local $aInfo = _RH_TTF_GetInfo($sFontData)
    If Not IsArray($aInfo) Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sFullPath) & @CRLF & "does not appear to be a valid TrueType/OpenType font for Rainmeter!")
        Return False
    EndIf

    If $aInfo[1][1] = "" Then
        _HideError()
        _ShowError(_GetFileNameFromPath($sFullPath) & @CRLF & "does not appear to be a valid TrueType/OpenType font for Rainmeter!")
        Return False
    EndIf

    $g_LastFontInfo = $aInfo
    If $g_LastFontPath = "" Then $g_LastFontPath = $sFullPath

    ; populate UI
    _HideError()
    GUICtrlSetState ($FontNameInput, $GUI_ENABLE)
    GUICtrlSetState ($CopyFontNameButton, $GUI_ENABLE)
    GUICtrlSetData($FontNameInput, "FontFace=" & $aInfo[1][1])
    GUICtrlSetData($FullFontNameValue, $aInfo[4][1])
    GUICtrlSetData($FamilyValue, $aInfo[1][1])
    GUICtrlSetData($SubFamilyValue, $aInfo[2][1])

    Local $FontStyle = 0
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

    ; Clear preview area then call renderer
    _ClearPreviewArea($Mainform, $PREV_X, $PREV_Y, $PREV_W, $PREV_H)

    Local $bRendered = Render_PreviewFromFile($sFullPath, $aInfo, $bInstalled, $FontStyle)
    If Not $bRendered Then
        _HideError()
        _ShowError("Unable to create preview for: " & _GetFileNameFromPath($g_LastFontPath))
        Return False
    EndIf

    ; update current browse dir
    If Not $bInstalled Then
        Local $szD2, $szP2, $szN2, $szE2
        _PathSplit($g_LastFontPath, $szD2, $szP2, $szN2, $szE2)
        $CurrentBrowseDir = $szD2 & $szP2
        Local $hSave = FileOpen(@ScriptDir & "\RainFont.dir", 2)
        If $hSave <> -1 Then
            FileWriteLine($hSave, $CurrentBrowseDir)
            FileClose($hSave)
        EndIf
    EndIf

    Return True
EndFunc

; ---------- Misc helpers ----------
Func _UpdateSelectOneLabel()
    If $g_View = "windows" Then
        Local $iCount = _GUICtrlListBox_GetCount($WindowsFontsList)
        GUICtrlSetData($SelectOneLabel, "Select a font from (" & $iCount & ") ""Windows"" installed Fonts," & @CRLF & "or browse to find and select an uninstalled font:")
    ElseIf $g_View = "skins" Then
        Local $iCount = 0
        If IsArray($g_ListPaths) Then $iCount = UBound($g_ListPaths)
        GUICtrlSetData($SelectOneLabel, "Select a font from (" & $iCount & ") ""Rainmeter\Skins"" uninstalled Fonts," & @CRLF & "or browse to find an uninstalled font:")
    ElseIf $g_View = "user" Then
        Local $iCount = 0
        If IsArray($g_ListPaths) Then $iCount = UBound($g_ListPaths)
        GUICtrlSetData($SelectOneLabel, "Select a font from (" & $iCount & ") fonts found under your User profile," & @CRLF & "or browse to find an uninstalled font:")
    EndIf
EndFunc

Func _ClearPreviewArea($hWnd, $iX, $iY, $iW, $iH)
    Local $tRect = DllStructCreate("long Left; long Top; long Right; long Bottom")
    DllStructSetData($tRect, "Left", $iX)
    DllStructSetData($tRect, "Top", $iY)
    DllStructSetData($tRect, "Right", $iX + $iW)
    DllStructSetData($tRect, "Bottom", $iY + $iH)
    DllCall("user32.dll", "int", "InvalidateRect", "hwnd", $hWnd, "ptr", DllStructGetPtr($tRect), "int", 1)
    DllCall("user32.dll", "int", "UpdateWindow", "hwnd", $hWnd)
EndFunc

Func _ShowError($sText)
    _ClearPreviewArea($Mainform, $PREV_X, $PREV_Y, $PREV_W, $PREV_H)
    GUICtrlSetState($EraseSampleLabel, $GUI_HIDE)
    GUICtrlSetData($ErrorLabel, $sText)
    GUICtrlSetState($ErrorLabel, $GUI_SHOW)
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
    GUICtrlSetData($WindowsFontsList, "")
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

    _UpdateSelectOneLabel()
    _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
    _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
    _ShowSelectionPreview()
    _FocusWindowsFontsList()
EndFunc

; -------------------------
; Populate Users Fonts list (fast)
; -------------------------
Func _PopulateUserFonts_Fast()
    $g_View = "user"
    $g_Populating = True
    GUICtrlSetData($WindowsFontsList, "")
    If Not IsArray($g_ListPaths) Then Dim $g_ListPaths[0]

    Local $sUser = EnvGet("USERPROFILE")
    Local $aLikely[7] = [ _
        $sUser & "\Desktop", _
        $sUser & "\Downloads", _
        $sUser & "\Documents", _
        $sUser & "\Pictures", _
        $sUser & "\AppData\Roaming\Microsoft\Windows\Fonts", _
        $sUser & "\AppData\Local\Microsoft\Windows\Fonts", _
        $sUser & "\AppData\Local" _
    ]

    Local $aFound[1] = [0]
    For $i = 0 To UBound($aLikely) - 1
        If $aLikely[$i] <> "" And FileExists($aLikely[$i]) Then
            _ScanFontsRec($aLikely[$i], $aFound)
        EndIf
    Next

    If Not IsArray($aFound) Or UBound($aFound) <= 1 Then
        GUICtrlSetData($WindowsFontsList, "No font files found in common user folders.")
        $g_ListPaths = ""
        $g_Populating = False
        _UpdateSelectOneLabel()
        Return
    EndIf

    Local $cnt = UBound($aFound) - 1
    ReDim $g_ListPaths[$cnt]
    Local $iOut = 0
    For $i = 1 To UBound($aFound) - 1
        Local $full = $aFound[$i]
        Local $name = _GetFileNameFromPath($full)
        GUICtrlSetData($WindowsFontsList, $name, "")
        $g_ListPaths[$iOut] = $full
        $iOut += 1
    Next

    _UpdateSelectOneLabel()
    _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
    _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
    _FocusWindowsFontsList()
    $g_Populating = False
EndFunc

Func _PopulateSkinsFonts($sFolder)
    $g_Populating = True
    GUICtrlSetData($WindowsFontsList, "")
    If Not IsArray($g_ListPaths) Then Dim $g_ListPaths[0]
    Local $aFound[1] = [0]
    _ScanFontsRec($sFolder, $aFound)

    If Not IsArray($aFound) Or UBound($aFound) <= 1 Then
        GUICtrlSetData($WindowsFontsList, "No font files found in skins folder.")
        $g_ListPaths = ""
        $g_Populating = False
        _UpdateSelectOneLabel()
        Return
    EndIf

    Local $cnt = UBound($aFound) - 1
    ReDim $g_ListPaths[$cnt]
    Local $iOut = 0
    For $i = 1 To UBound($aFound) - 1
        Local $full = $aFound[$i]
        Local $name = _GetFileNameFromPath($full)
        GUICtrlSetData($WindowsFontsList, $name, "")
        $g_ListPaths[$iOut] = $full
        $iOut += 1
    Next

    _UpdateSelectOneLabel()
    _GUICtrlListBox_SetCurSel($WindowsFontsList, 0)
    _GUICtrlListBox_SetTopIndex($WindowsFontsList, 0)
    _FocusWindowsFontsList()
    $g_Populating = False
EndFunc

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
EndFunc

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

    Local $tTT_NAME_TABLE_HEADER = DllStructCreate("word Format;word NRCount;word StorageOffset;", $pPointer)
    $pPointer += 6
    Local $iNRCount = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "NRCount"), 2)
    Local $iStorageOffset = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_TABLE_HEADER, "StorageOffset"), 2)

    Local $aInfo[28][3]
    $aInfo[0][0] = "Copyright notice"
    $aInfo[1][0] = "Font Name"
    $aInfo[2][0] = "Subfamily Name"
    $aInfo[3][0] = "Identifier"
    $aInfo[4][0] = "Full font Name"
    $aInfo[5][0] = "Version"
    $aInfo[6][0] = "Postscript Name"
    $aInfo[7][0] = "Trademark"
    $aInfo[8][0] = "Manufacturer"
    $aInfo[9][0] = "Designer"
    $aInfo[10][0] = "Description"
    $aInfo[11][0] = "URL Vendor"
    $aInfo[12][0] = "URL Designer"
    $aInfo[13][0] = "License Description"
    $aInfo[14][0] = "License Info URL"
    $aInfo[15][0] = "Reserved Field "
    $aInfo[16][0] = "Preferred Family"
    $aInfo[17][0] = "Preferred Subfamily"
    $aInfo[18][0] = "Compatible Full"
    $aInfo[19][0] = "Sample text"
    $aInfo[20][0] = "PostScript CID Findfont Name"
    $aInfo[21][0] = "WWS Family Name"
    $aInfo[22][0] = "WWS Subfamily Name"

    Local $tTT_NAME_RECORD, $bString, $iNameID, $iPlatform, $iEncodingID, $iLangID
    For $i = 1 To $iNRCount
        $tTT_NAME_RECORD = DllStructCreate("word PlatformID;word EncodingID;word LanguageID;word NameID;word StringLength;word StringOffset;", $pPointer)
        $pPointer += 12

        Local $iStrLen = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "StringLength"), 2)
        Local $iStrOff = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "StringOffset"), 2)
        $iNameID = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "NameID"), 2)
        $iPlatform = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "PlatformID"), 2)
        $iEncodingID = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "EncodingID"), 2)
        $iLangID = _RH_BigEndianToInt(DllStructGetData($tTT_NAME_RECORD, "LanguageID"), 2)

        Local $iStorePos = $iStorageOffset + $iStrOff
        If $iStrLen <= 0 Or $iStorePos < 0 Or ($iStorePos + $iStrLen) > BinaryLen($bBinary) Then ContinueLoop

        Local $tSlice = DllStructCreate("byte[" & $iStrLen & "]", $pDir + $iStorePos)
        $bString = DllStructGetData($tSlice, 1)

        If $iNameID < 23 Then
            Local $sDecoded = ""
            If $iPlatform = 1 Then
                $sDecoded = BinaryToString($bString)
            ElseIf $iPlatform = 0 Or $iPlatform = 3 Then
                Local $iLen = $iStrLen
                If $iLen >= 2 Then
                    For $bi = 1 To $iLen Step 2
                        Local $bHigh = Asc(BinaryToString(BinaryMid($bString, $bi, 1)))
                        Local $bLow = 0
                        If ($bi + 1) <= $iLen Then $bLow = Asc(BinaryToString(BinaryMid($bString, $bi + 1, 1)))
                        Local $code = $bHigh * 256 + $bLow
                        $sDecoded &= ChrW($code)
                    Next
                Else
                    $sDecoded = BinaryToString($bString)
                EndIf
            Else
                $sDecoded = BinaryToString($bString)
            EndIf

            If StringLen($sDecoded) Then
                $sDecoded = StringReplace($sDecoded, Chr(0), "")
                $sDecoded = StringStripWS($sDecoded, 3)
            EndIf

            If $sDecoded <> "" Then
                $aInfo[$iNameID][2] = _RH_FormatStringEllipsis($sDecoded, 100)
                If $aInfo[$iNameID][1] = "" Then $aInfo[$iNameID][1] = $aInfo[$iNameID][2]
            EndIf
        EndIf
    Next

    Return $aInfo
EndFunc   ;==>_RH_TTF_GetInfo

Func _RH_TTF_GetFontMetrics($bBinary)
    Local $a = _RH_TTF_GetInfo($bBinary)
    _ArrayDisplay($a)
    Return $a
EndFunc

Func _RH_BigEndianToInt($iValue, $iSize = 2)
    Return Dec(Hex(BinaryMid($iValue, 1, $iSize)))
EndFunc

Func _RH_FormatStringEllipsis($sString, $iNumChars)
    Local $iLen = StringLen($sString)
    If $iLen <= $iNumChars Then Return $sString
    Return StringLeft($sString, $iNumChars - 3) & "..."
EndFunc

; End of file
