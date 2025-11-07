; RainFont_Render.au3 (trimmed, no debug/logging)
#include <GDIPlus.au3>

Global $g_Render_Inited = False
Global $Mainform
Global $PREV_X, $PREV_Y, $PREV_W, $PREV_H
Global $hGraphic, $hFont, $hFamily, $hFormat, $hBrush, $hMemHandle

Func Render_Init()
    $g_Render_Inited = True
    Return True
EndFunc

Func Render_Shutdown()
    $g_Render_Inited = False
    Return True
EndFunc

; Helper to attempt GDI+ font family creation
Func _TryCreateGdiPlusFont($name, $size, $style, ByRef $hfOut, ByRef $fOut)
    Local $hf = _GDIPlus_FontFamilyCreate($name)
    If $hf Then
        Local $fnt = _GDIPlus_FontCreate($hf, $size, $style, 3)
        If $fnt Then
            $hfOut = $hf
            $fOut = $fnt
            Return True
        Else
            _GDIPlus_FontFamilyDispose($hf)
        EndIf
    EndIf
    Return False
EndFunc

Func Render_PreviewFromFile($sFullPath, $aInfo, $bInstalled, $iFontStyle)
    If $sFullPath = "" Or Not IsArray($aInfo) Then Return False
    If Not $g_Render_Inited Then Render_Init()

    _GDIPlus_Startup()
    $hGraphic = _GDIPlus_GraphicsCreateFromHWND($Mainform)
    If Not $hGraphic Then
        _GDIPlus_Shutdown()
        Return False
    EndIf

    Local $iFontSize = 18
    $hFamily = 0
    $hFont = 0
    $bTempAddedFont = False
    $hMemHandle = 0

    ; Build candidate name list
    Local $aNames[0]
    _ArrayAdd($aNames, $aInfo[1][1])
    If $aInfo[16][1] <> "" Then _ArrayAdd($aNames, $aInfo[16][1])
    If $aInfo[6][1]  <> "" Then _ArrayAdd($aNames, $aInfo[6][1])
    If $aInfo[4][1]  <> "" Then _ArrayAdd($aNames, $aInfo[4][1])
    If $aInfo[7][1]  <> "" Then _ArrayAdd($aNames, $aInfo[7][1])

    ; Try private font collection via GDI+ first
    Local $aNew = DllCall("gdiplus.dll", 'int', 'GdipNewPrivateFontCollection', 'ptr*', 0)
    If IsArray($aNew) And $aNew[0] = 0 Then
        Local $hCollection = $aNew[1]
        DllCall("gdiplus.dll", 'int', 'GdipPrivateAddFontFile', 'ptr', $hCollection, 'wstr', $sFullPath)
        For $k = 0 To UBound($aNames) - 1
            If $aNames[$k] = "" Then ContinueLoop
            Local $aCF = DllCall("gdiplus.dll", 'int', 'GdipCreateFontFamilyFromName', 'wstr', $aNames[$k], 'ptr', $hCollection, 'ptr*', 0)
            If IsArray($aCF) And $aCF[0] = 0 And UBound($aCF) > 1 Then
                $hFamily = $aCF[UBound($aCF)-1]
                If $hFamily Then
                    $hFont = _GDIPlus_FontCreate($hFamily, $iFontSize, $iFontStyle)
                    If $hFont Then ExitLoop
                EndIf
            EndIf
        Next
        DllCall("gdiplus.dll", 'int', 'GdipDeletePrivateFontCollection', 'ptr*', $hCollection)
    EndIf

    ; If not found, try AddFontResourceExW
    If Not $hFont Then
        Local $aAdd = DllCall("gdi32.dll", "int", "AddFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
        If IsArray($aAdd) Then
            If $aAdd[0] > 0 Then
                $bTempAddedFont = True
                Sleep(80)
                For $k = 0 To UBound($aNames) - 1
                    If $aNames[$k] = "" Then ContinueLoop
                    If _TryCreateGdiPlusFont($aNames[$k], $iFontSize, $iFontStyle, $hFamily, $hFont) Then ExitLoop
                Next
                DllCall("user32.dll", "lresult", "SendMessageTimeoutW", "hwnd", -1, "uint", 0x001D, "wparam", 0, "lparam", 0, "uint", 0x0002, "uint", 100, "ptr", 0)
            EndIf
        EndIf
    EndIf

    ; If still not found, try AddFontMemResourceEx (memory install)
    If Not $hFont Then
        Local $hF = FileOpen($sFullPath, 16)
        If $hF <> -1 Then
            Local $sFontData = FileRead($hF)
            FileClose($hF)
            If BinaryLen($sFontData) > 0 Then
                Local $tBuf = DllStructCreate("byte[" & BinaryLen($sFontData) & "]")
                DllStructSetData($tBuf, 1, $sFontData)
                Local $pBuf = DllStructGetPtr($tBuf)
                Local $pNum = DllStructCreate("ptr")
                Local $aMem = DllCall("gdi32.dll", "ptr", "AddFontMemResourceEx", "ptr", $pBuf, "dword", BinaryLen($sFontData), "ptr", 0, "ptr*", DllStructGetPtr($pNum))
                If IsArray($aMem) And $aMem[0] <> 0 Then
                    $hMemHandle = $aMem[1]
                    Sleep(80)
                    For $k = 0 To UBound($aNames) - 1
                        If $aNames[$k] = "" Then ContinueLoop
                        If _TryCreateGdiPlusFont($aNames[$k], $iFontSize, $iFontStyle, $hFamily, $hFont) Then ExitLoop
                    Next
                EndIf
            EndIf
        EndIf
    EndIf

    ; Final attempt by direct names
    For $k = 0 To UBound($aNames) - 1
        If $aNames[$k] = "" Then ContinueLoop
        If _TryCreateGdiPlusFont($aNames[$k], $iFontSize, $iFontStyle, $hFamily, $hFont) Then ExitLoop
    Next

    ; If GDI+ succeeded, draw with GDI+
    If IsHWnd($hFont) Or (IsPtr($hFont) And $hFont <> 0) Then
        Local $iVPad = 6
        Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF946300)
        Local $hFormat = _GDIPlus_StringFormatCreate()
        Local $tLayout = _GDIPlus_RectFCreate($PREV_X, $PREV_Y + $iVPad, $PREV_W, $PREV_H - $iVPad)
        _GDIPlus_GraphicsDrawStringEx($hGraphic, "ABCDWXYZabcdwxyz 12347890@£#?&%", $hFont, $tLayout, $hFormat, $hBrush)
        _GDIPlus_FontDispose($hFont)
        _GDIPlus_FontFamilyDispose($hFamily)
        _GDIPlus_StringFormatDispose($hFormat)
        _GDIPlus_BrushDispose($hBrush)
        _GDIPlus_GraphicsDispose($hGraphic)
        _GDIPlus_Shutdown()
        If $bTempAddedFont Then DllCall("gdi32.dll", "int", "RemoveFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
        If $hMemHandle Then DllCall("gdi32.dll", "int", "RemoveFontMemResourceEx", "ptr", $hMemHandle)
        Return True
    EndIf

    ; GDI fallback
    Local $hWnd = $Mainform
    Local $aDC = DllCall("user32.dll", "ptr", "GetDC", "hwnd", $hWnd)
    If Not IsArray($aDC) Then
        _GDIPlus_GraphicsDispose($hGraphic)
        _GDIPlus_Shutdown()
        If $bTempAddedFont Then DllCall("gdi32.dll", "int", "RemoveFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
        If $hMemHandle Then DllCall("gdi32.dll", "int", "RemoveFontMemResourceEx", "ptr", $hMemHandle)
        Return False
    EndIf
    Local $hWndDC = $aDC[0]

    Local $aDPI = DllCall("gdi32.dll", "int", "GetDeviceCaps", "ptr", $hWndDC, "int", 90) ; LOGPIXELSY
    Local $nDPI = 96
    If IsArray($aDPI) Then $nDPI = $aDPI[0]
    Local $lfHeight = -Int(($iFontSize * $nDPI) / 72)

    Local $tLogFont = DllStructCreate("long lfHeight; long lfWidth; long lfEscapement; long lfOrientation; long lfWeight; byte lfItalic; byte lfUnderline; byte lfStrikeOut; byte lfCharSet; byte lfOutPrecision; byte lfClipPrecision; byte lfQuality; byte lfPitchAndFamily; wchar lfFaceName[64]")
    DllStructSetData($tLogFont, "lfHeight", $lfHeight)
    Local $iWeight = 400
    If $iFontStyle = 1 Or $iFontStyle = 3 Then $iWeight = 700
    DllStructSetData($tLogFont, "lfWeight", $iWeight)
    DllStructSetData($tLogFont, "lfItalic", ($iFontStyle = 2 Or $iFontStyle = 3) ? 1 : 0)
    DllStructSetData($tLogFont, "lfCharSet", 1) ; DEFAULT_CHARSET

    Local $sFace = $aInfo[6][1]
    If $sFace = "" Then $sFace = $aInfo[4][1]
    If $sFace = "" Then $sFace = $aInfo[1][1]
    DllStructSetData($tLogFont, "lfFaceName", $sFace)

    Local $aHF = DllCall("gdi32.dll", "ptr", "CreateFontIndirectW", "ptr", DllStructGetPtr($tLogFont))
    Local $hFontGDI = 0
    If IsArray($aHF) Then $hFontGDI = $aHF[0]

    Local $bGDIRendered = False
    If $hFontGDI Then
        Local $aMemDC = DllCall("gdi32.dll", "ptr", "CreateCompatibleDC", "ptr", $hWndDC)
        If IsArray($aMemDC) Then
            Local $hMemDC = $aMemDC[0]
            Local $aBmp = DllCall("gdi32.dll", "ptr", "CreateCompatibleBitmap", "ptr", $hWndDC, "int", $PREV_W, "int", $PREV_H)
            If IsArray($aBmp) Then
                Local $hBmp = $aBmp[0]
                Local $aOld = DllCall("gdi32.dll", "ptr", "SelectObject", "ptr", $hMemDC, "ptr", $hBmp)
                Local $hOldBmp = IsArray($aOld) ? $aOld[0] : 0
                DllCall("gdi32.dll", "int", "SetBkMode", "ptr", $hMemDC, "int", 1) ; TRANSPARENT
                Local $iColor = 0x006394
                DllCall("gdi32.dll", "int", "SetTextColor", "ptr", $hMemDC, "int", $iColor)
                DllCall("gdi32.dll", "ptr", "SelectObject", "ptr", $hMemDC, "ptr", $hFontGDI)
                Local $tRect = DllStructCreate("long left; long top; long right; long bottom")
                Local $iVPad = 6
                DllStructSetData($tRect, "left", 0)
                DllStructSetData($tRect, "top", $iVPad)
                DllStructSetData($tRect, "right", $PREV_W)
                DllStructSetData($tRect, "bottom", $PREV_H - $iVPad)
                Local $iFlags = 0x00000825 ; DT_CENTER|DT_VCENTER|DT_SINGLELINE|DT_NOPREFIX
                DllCall("user32.dll", "int", "DrawTextW", "ptr", $hMemDC, "wstr", "ABCDWXYZabcdwxyz 12347890@£#?&%", "int", -1, "ptr", DllStructGetPtr($tRect), "uint", $iFlags)
                DllCall("gdi32.dll", "bool", "BitBlt", "ptr", $hWndDC, "int", $PREV_X, "int", $PREV_Y, "int", $PREV_W, "int", $PREV_H, "ptr", $hMemDC, "int", 0, "int", 0, "int", 0x00CC0020)
                If $hOldBmp Then DllCall("gdi32.dll", "ptr", "SelectObject", "ptr", $hMemDC, "ptr", $hOldBmp)
                DllCall("gdi32.dll", "int", "DeleteObject", "ptr", $hBmp)
                DllCall("gdi32.dll", "bool", "DeleteDC", "ptr", $hMemDC)
                $bGDIRendered = True
            EndIf
        EndIf
        DllCall("gdi32.dll", "int", "DeleteObject", "ptr", $hFontGDI)
    EndIf

    DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $hWnd, "ptr", $hWndDC)

    _GDIPlus_GraphicsDispose($hGraphic)
    _GDIPlus_Shutdown()

    If $bTempAddedFont Then DllCall("gdi32.dll", "int", "RemoveFontResourceExW", "wstr", $sFullPath, "uint", 0x10, "ptr", 0)
    If $hMemHandle Then DllCall("gdi32.dll", "int", "RemoveFontMemResourceEx", "ptr", $hMemHandle)

    If $bGDIRendered Then Return True
    Return False
EndFunc
