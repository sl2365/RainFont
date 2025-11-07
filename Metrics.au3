; Metrics.au3
; Provides ShowFontMetrics($aInfo, $sFullPath) to display detailed font info
; Fixed-size, non-resizable window with a scrollable, two-column, read-only view.
#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>

; ---------------------------------------------------------------------------
; Helper functions (top-level)
; ---------------------------------------------------------------------------
Func _Repeat($sChar, $count)
    Local $s = ""
    For $ii = 1 To $count
        $s &= $sChar
    Next
    Return $s
EndFunc

Func _PadLabel($sLabel, $width)
    Local $s = $sLabel & _Repeat(" ", $width)
    Return StringLeft($s, $width)
EndFunc

; ---------------------------------------------------------------------------
; Public function: show the font metrics/details window.
; $aInfo - the name-table array returned from _RH_TTF_GetInfo (or similar)
; $sFullPath - (optional) full path to the font file (not required for current display)
; ---------------------------------------------------------------------------
Func ShowFontMetrics(ByRef $aInfo, $sFullPath = "")
    ; Defensive: ensure we have info
    If Not IsArray($aInfo) Then
        MsgBox(48, "Font Info", "No font information available.")
        Return
    EndIf

    ; Determine if $aInfo is a true 2-D array (rows x cols) or a 1-D array / array-of-scalars.
    Local $rows = UBound($aInfo)
    Local $bIs2D = True
    Local $cols = 0
    $cols = UBound($aInfo, 2)
    If @error Then
        $bIs2D = False
        SetError(0, 0) ; clear @error (cannot assign to @error directly)
        $cols = 1
    EndIf

    ; Build a list of (heading, value) pairs and determine the max heading length
    Local $aPairs[1][2] = [[ "", "" ]] ; dynamic container
    Local $iPairs = 0
    Local $iMaxLabelLen = 0

    ; If a file path was given, put Source file as the first row
    If $sFullPath <> "" Then
        Local $sExtra = $sFullPath
        If FileExists($sFullPath) Then $sExtra &= "  (" & Round(FileGetSize($sFullPath)/1024,2) & " KB)"
        $iPairs = 1
        ReDim $aPairs[$iPairs][2]
        $aPairs[0][0] = "Source file"
        $aPairs[0][1] = $sExtra
        If StringLen("Source file") > $iMaxLabelLen Then $iMaxLabelLen = StringLen("Source file")
    EndIf

    ; Append the name-table rows after the source row (if any)
    If $bIs2D Then
        For $i = 0 To $rows - 1
            Local $sLabel = ""
            Local $sVal = ""
            If $cols >= 1 Then $sLabel = $aInfo[$i][0]
            If $cols >= 2 Then $sVal = $aInfo[$i][1]
            If ($sVal = "" OR $sVal = Null) And $cols >= 3 Then $sVal = $aInfo[$i][2]
            If $sLabel = "" Then $sLabel = "NameID " & $i
            If $sVal = Null Then $sVal = ""
            $iPairs += 1
            ReDim $aPairs[$iPairs][2]
            $aPairs[$iPairs - 1][0] = $sLabel
            $aPairs[$iPairs - 1][1] = $sVal
            If StringLen($sLabel) > $iMaxLabelLen Then $iMaxLabelLen = StringLen($sLabel)
        Next
    Else
        For $i = 0 To $rows - 1
            Local $sLabel = "Item " & $i
            Local $sVal = $aInfo[$i]
            If $sVal = Null Then $sVal = ""
            $iPairs += 1
            ReDim $aPairs[$iPairs][2]
            $aPairs[$iPairs - 1][0] = $sLabel
            $aPairs[$iPairs - 1][1] = $sVal
            If StringLen($sLabel) > $iMaxLabelLen Then $iMaxLabelLen = StringLen($sLabel)
        Next
    EndIf

    ; Build formatted text using a monospace font and padded headings (two columns).
    Local $nHeadingColChars = $iMaxLabelLen + 2
    If $nHeadingColChars < 18 Then $nHeadingColChars = 18
    If $nHeadingColChars > 40 Then $nHeadingColChars = 40

    Local $sText = ""
    For $i = 0 To $iPairs - 1
        Local $sL = $aPairs[$i][0]
        Local $sV = $aPairs[$i][1]
        If $sV = Null Then $sV = ""
        $sText &= _PadLabel($sL, $nHeadingColChars) & " " & $sV & @CRLF
    Next

    ; ------------------------
    ; Layout: keep window size, move buttons near bottom and expand edit control
    ; ------------------------
    Local $nWidth = 640
    Local $nHeight = 480

    ; Button sizes / margins
    Local $btnHeight = 28
    Local $bottomMargin = 8    ; small margin below buttons
    Local $btnSpacingTop = 15  ; spacing between edit and buttons

    ; Compute button Y to place buttons close to the bottom
    Local $btnY = $nHeight - $bottomMargin - $btnHeight ; e.g., 480 - 8 - 28 = 444
    Local $editBottom = $btnY - $btnSpacingTop        ; edit bottom just above button area

    ; Create GUI
    Local $hMetrics = GUICreate("Font Metrics", $nWidth, $nHeight, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU))
    Local $editStyle = BitOR($ES_READONLY, $ES_AUTOVSCROLL, $ES_NOHIDESEL, $WS_VSCROLL, $WS_HSCROLL)
    Local $idEdit = GUICtrlCreateEdit($sText, 8, 8, $nWidth - 20, $editBottom, $editStyle)
    GUICtrlSetFont($idEdit, 10, 400, 0, "Consolas")

    ; Buttons placed near bottom with small margin under them
    Local $idCopy = GUICtrlCreateButton("Copy to Clipboard", 12, $btnY, 160, $btnHeight)
    ; Close button removed per request — user can still close via titlebar (X) or Alt+F4

    GUISetState(@SW_SHOW, $hMetrics)
    ; Put focus on Copy button so the edit does not show a caret by default
    GUICtrlSetState($idCopy, $GUI_FOCUS)
    GUICtrlSendMsg($idEdit, $EM_SETSEL, 0, 0)

    ; Modal loop — still responds to titlebar close
    While 1
        Local $msg = GUIGetMsg()
        Select
            Case $msg = $GUI_EVENT_CLOSE
                GUIDelete($hMetrics)
                Return
            Case $msg = $idCopy
                Local $sCopy = ""
                For $i = 0 To $iPairs - 1
                    Local $sHeading = $aPairs[$i][0]
                    Local $sValue = $aPairs[$i][1]
                    If $sValue = Null Then $sValue = ""
                    $sCopy &= $sHeading & ": " & $sValue & @CRLF
                Next
                ClipPut($sCopy)
                ToolTip("Font info copied to clipboard", Default, Default, "Copied", 1, 1)
                Sleep(1000)
                ToolTip("")
        EndSelect
        Sleep(10)
    WEnd
EndFunc
