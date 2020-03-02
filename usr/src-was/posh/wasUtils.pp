{$MODE OBJFPC}
{$H+}

// Written by Bill Stewart

Unit
  wasUtils;

Interface

Uses
  windows;

Function BuildPath(Part1, Part2: String): String;

Function Exec(Const CommandLine: String): DWORD;

Function ExpandEnvStrings(Const S: String): String;

Function FileExists(Const Filename: String): Boolean;

Function GetCommandLineTail(Const ToSkip: LongInt): String;

Function GetFilePath(Const Path: String): String;

Function GetRegistryStringValue(Root: HKEY;
                                Const SubKey, ValueName: String;
                                Var ValueData: String): DWORD;

Function Quote(Const S: String): String;

Implementation

Const
  INVALID_FILE_ATTRIBUTES = DWORD(-1);

Function PathRemoveFileSpecA(pszPath: LPSTR): BOOL; stdcall;
  External 'shlwapi.dll';

Function BuildPath(Part1, Part2: String): String;
  Begin
  If Part1[Length(Part1)] <> '\' Then
    Part1 := Part1 + '\';
  Result := Part1 + Part2;
  End;

Function Exec(Const CommandLine: String): DWORD;
  Var
    StartInfo: STARTUPINFO;
    ProcInfo: PROCESS_INFORMATION;
    OK: Boolean;
  Begin
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  OK := CreateProcess(Nil,                 // LPCSTR                lpApplicationName
                      PChar(CommandLine),  // LPSTR                 lpCommandLine
                      Nil,                 // LPSECURITY_ATTRIBUTES lpProcessAttributes
                      Nil,                 // LPSECURITY_ATTRIBUTES lpThreadAttributes
                      True,                // BOOL                  bInheritHandles
                      0,                   // DWORD                 dwCreationFlags
                      Nil,                 // LPVOID                lpEnvironment
                      Nil,                 // LPCSTR                lpCurrentDirectory
                      @StartInfo,          // LPSTARTUPINFO         lpStartupInfo
                      @ProcInfo);          // LPPROCESS_INFORMATION lpProcessInformation
  Result := GetLastError();
  If OK Then
    If WaitForSingleObject(ProcInfo.hProcess, INFINITE) <> WAIT_FAILED Then
      GetExitCodeProcess(ProcInfo.hProcess, @Result);
  End;

Function ExpandEnvStrings(Const S: String): String;
  Var
    BufSize: DWORD;
    pStr: PChar;
  Begin
  Result := '';
  // First call: Get buffer size
  BufSize := ExpandEnvironmentStrings(PChar(S), Nil, 0);
  If BufSize > 0 Then
    Begin
    GetMem(pStr, BufSize);
    If ExpandEnvironmentStrings(PChar(S), pStr, BufSize) > 0 Then
      Result := String(pStr);
    FreeMem(pStr, BufSize);
    End;
  End;

Function FileExists(Const Filename: String): Boolean;
  Var
    Attrs: DWORD;
  Begin
  Attrs := GetFileAttributes(PChar(Filename));
  Result := (Attrs <> INVALID_FILE_ATTRIBUTES) And
    ((Attrs And FILE_ATTRIBUTE_DIRECTORY) = 0);
  End;

Function GetCommandLineTail(Const ToSkip: LongInt): String;
  Const
    WHITESPACE: Set Of Char = [#9, #32];
  Var
    pCL, pTail: PChar;
    InQuote: Boolean;
    ArgNo, N: LongInt;
  Begin
  pCL := GetCommandLine();
  pTail := Nil;
  If pCL^ <> #0 Then
    Begin
    While pCL^ In WHITESPACE Do
      Inc(pCL);
    InQuote := False;
    pTail := pCL;
    ArgNo := 0;
    For N := 0 To Length(pCL) Do
      Begin
      Case pCL[N] Of
        #0:
          Break;
        '"':
          Begin
          InQuote := Not InQuote;
          If InQuote Then
            Begin
            If ArgNo = ToSkip Then
              Break;
            End;
          Inc(pTail);
          End;
        #1..#32:
          Begin
          If (Not InQuote) And (Not (pCL[N - 1] In WHITESPACE)) Then
            Inc(ArgNo);
          Inc(pTail);
          End;
        Else
          Begin
          If ArgNo = ToSkip Then
            Break
          Else
            Inc(pTail);
          End;
      End; //Case
      End;
    End;
  Result := String(pTail);
  End;

Function GetFilePath(Const Path: String): String;
  Var
    BufSize: DWORD;
    pPath: PChar;
  Begin
  Result := Path;
  If Length(Path) > 0 Then
    Begin
    BufSize := Length(Path) + SizeOf(Char);
    GetMem(pPath, BufSize);
    // Copy string to buffer
    Move(Path[1], pPath^, Length(Path));
    // Add terminating null
    (pPath + BufSize - SizeOf(Char))^ := #0;
    If PathRemoveFileSpecA(pPath) Then
      Result := String(pPath);
    FreeMem(pPath, BufSize);
    End;
  End;

Function GetRegistryStringValue(Root: HKEY;
                                Const SubKey, ValueName: String;
                                Var ValueData: String): DWORD;
  Var
    RegHandle: HANDLE;
    ValueType, ValueSize: DWORD;
    pData: Pointer;
  Begin
  // Open key
  Result := RegOpenKeyEx(Root,           // HKEY   hKey
                         PChar(SubKey),  // LPCSTR lpSubkey
                         0,              // DWORD  ulOptions
                         KEY_READ,       // REGSAM samDesired
                         RegHandle);     // PHKEY  phkResult
  If Result = 0 Then
    Begin
    // First call: Get value size
    Result := RegQueryValueEx(RegHandle,         // HKEY    hKey
                              PChar(ValueName),  // LPCSTR  lpValueName
                              Nil,               // LPDWORD lpReserved
                              @ValueType,        // LPDWORD lpType
                              Nil,               // LPBYTE  lpData
                              @ValueSize);       // LPDWORD lpcbData
    If Result = 0 Then
      Begin
      // Must be REG_SZ or REG_EXPAND_SZ
      If (ValueType = REG_SZ) Or (ValueType = REG_EXPAND_SZ) Then
        Begin
        // Allocate buffer
        GetMem(pData, ValueSize);
        // Second call: Get value data
        Result := RegQueryValueEx(RegHandle,         // HKEY    hKey
                                  PChar(ValueName),  // LPCSTR  lpValueName
                                  Nil,               // LPDWORD lpReserved
                                  @ValueType,        // LPDWORD lpType
                                  pData,             // LPBYTE  lpData
                                  @ValueSize);       // LPDWORD lpcbData
        If Result = 0 Then
          ValueData := String(PChar(pData));
        FreeMem(pData, ValueSize);
        End
      Else
        Result := ERROR_INVALID_DATA;
      End;
    RegCloseKey(RegHandle);
    End;
  End;

Function Quote(Const S: String): String;
  Begin
  If Pos(' ', S) > 0 Then
    Result := '"' + S + '"'
  Else
    Result := S;
  End;

Begin
End.
