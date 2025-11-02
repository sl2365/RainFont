#include <Array.au3>


Global $sFontData = FileRead("C:\Windows\Fonts\ebrima.ttf") ; <- your font here (full path maybe)

; INFO:
$aArray = _RH_TTF_GetInfo($sFontData)

; Col 0 = Property Name
; Col 1 = ANSI
; Col 2 = Unicode


for $a = 0 to UBound($aArray) - 1
	;MsgBox("","",$aArray[$a][2])
	If $aArray[$a][2] <> "" And $aArray[$a][1] = "" Then
		$aArray[$a][1] = $aArray[$a][2]
	EndIf
Next

_ArrayDisplay($aArray)


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