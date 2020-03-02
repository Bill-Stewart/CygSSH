// Written by Bill Stewart
//
// Usage: posh [-c] [-- parameter [...]]
//
// Runs Windows PowerShell/PowerShell Core using winpty.exe.
//
// -c runs PowerShell Core instead of Windows PowerShell.
//
// parameters after -- are command-line parameters for Windows PowerShell/
// PowerShell core executable (e.g., -NoProfile, etc.).

{$MODE OBJFPC}
{$H+}
{$APPTYPE CONSOLE}
{$R posh.res}

Uses
  getopts, windows, wasUtils;

Const
  PS_WIN_APPPATH_SUBKEY  = 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\PowerShell.exe';
  PS_CORE_APPPATH_SUBKEY = 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\pwsh.exe';

Var
  Core: Boolean;
  Opt: Char;
  PSPath, ExecutableDir, WinptyPath, CommandLine: String;

Procedure Pause(Const Msg: String);
  Begin
  WriteLn(Msg);
  WriteLn();
  Write('Press ENTER to continue: ');
  ReadLn();
  End;

Function GetPSPath(Const Core: Boolean): String;
  Var
    Subkey, Path: String;
  Begin
  Result := '';
  If Not Core Then
    Subkey := PS_WIN_APPPATH_SUBKEY
  Else
    Subkey := PS_CORE_APPPATH_SUBKEY;
  If GetRegistryStringValue(HKEY_LOCAL_MACHINE, PChar(Subkey), '', Path) = 0 Then
    Result := ExpandEnvStrings(Path);
  End;

Begin
  OptErr := False;  // No stdout output for invalid options

  Core := False;   // default = Windows PowerShell
  Repeat
    Opt := GetOpt('ch');
    Case Opt Of
      'c': Core := True;
      'h':
        Begin
        Pause('posh [-c] [-- parameter [...]]');
        Exit();
        End;
    End; //Case
  Until Opt = EndOfOptions;

  PSPath := GetPSPath(Core);

  If PSPath = '' Then
    Begin
    ExitCode := ERROR_FILE_NOT_FOUND;
    Pause('Unable to find PowerShell program file path in registry');
    Exit();
    End;

  If Not FileExists(PSPath) Then
    Begin
    ExitCode := ERROR_FILE_NOT_FOUND;
    Pause('File not found - ''' + PSPath + '''');
    Exit();
    End;

  ExecutableDir := GetFilePath(ParamStr(0));
  WinptyPath := BuildPath(ExecutableDir, 'winpty.exe');
  If Not FileExists(WinptyPath) Then
    Begin
    ExitCode := ERROR_FILE_NOT_FOUND;
    Pause('File not found - ''' + WinptyPath + '''');
    Exit();
    End;

  CommandLine := Quote(WinptyPath) + ' ' + Quote(PSPath);

  // Pass along any other command-line options
  If ParamStr(OptInd) <> '' Then
    CommandLine := CommandLine + ' ' + GetCommandLineTail(OptInd);

  ExitCode := Exec(CommandLine);
End.
