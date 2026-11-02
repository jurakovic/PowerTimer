unit PowerActions;

{ The actions Power Timer can perform when the countdown ends. }

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  { The ordinal values are part of the stored settings: they are written to
    the registry (defaultAction) and match the list order of the C# version.
    Only append new actions; never reorder or remove one. }
  TPowerAction = (paShutdown, paRestart, paLogoff, paLock, paSleep, paHibernate);

const
  DefaultPowerAction = paShutdown;

  PowerActionNames: array[TPowerAction] of string = (
    'Shutdown', 'Restart', 'Logoff', 'Lock', 'Sleep', 'Hibernate');

{ Maps a list index (e.g. ItemIndex of a combo box or a stored setting)
  to an action. Out of range values give DefaultPowerAction. }
function PowerActionFromIndex(AIndex: Integer): TPowerAction;

{ Replaces the contents of AItems with the action names in TPowerAction
  order, so the index of an item is the ordinal of its action (see
  PowerActionFromIndex). Used to fill the action combo boxes. }
procedure FillPowerActionList(AItems: TStrings);

{ Arguments for shutdown.exe, or '' when the action does not use it. }
function ShutdownArguments(AAction: TPowerAction): string;

{ Full path of shutdown.exe in the Windows system directory, or '' when that
  directory cannot be determined (always '' on other platforms). Starting a
  bare 'shutdown.exe' would look in the application's own directory first,
  so a planted shutdown.exe next to PowerTimer.exe would be run instead. }
function ShutdownExePath: string;

{ Performs the action. Returns False and a message in AError when the
  action could not be started. }
function ExecutePowerAction(AAction: TPowerAction; out AError: string): Boolean;

implementation

uses
  {$IFDEF WINDOWS}
  Windows, Process,
  {$ENDIF}
  SysUtils;

function PowerActionFromIndex(AIndex: Integer): TPowerAction;
begin
  if (AIndex >= Ord(Low(TPowerAction))) and (AIndex <= Ord(High(TPowerAction))) then
    Result := TPowerAction(AIndex)
  else
    Result := DefaultPowerAction;
end;

procedure FillPowerActionList(AItems: TStrings);
var
  Action: TPowerAction;
begin
  AItems.BeginUpdate;
  try
    AItems.Clear;
    for Action := Low(TPowerAction) to High(TPowerAction) do
      AItems.Add(PowerActionNames[Action]);
  finally
    AItems.EndUpdate;
  end;
end;

function ShutdownArguments(AAction: TPowerAction): string;
begin
  case AAction of
    paShutdown: Result := '/s /t 0';
    paRestart: Result := '/r /t 0';
    paLogoff: Result := '/l';
    paHibernate: Result := '/h';
  else
    Result := '';
  end;
end;

{$IFDEF WINDOWS}

const
  ShutdownExeName = 'shutdown.exe';

function ShutdownExePath: string;
var
  Buffer: array[0..MAX_PATH] of WideChar;
  Len: UINT;
  Dir: UnicodeString;
begin
  Len := GetSystemDirectoryW(@Buffer[0], Length(Buffer));
  // 0 means failure; a value >= the buffer size is the size it would need
  if (Len = 0) or (Len >= Length(Buffer)) then
    Exit('');
  SetString(Dir, PWideChar(@Buffer[0]), Len);
  Result := IncludeTrailingPathDelimiter(string(Dir)) + ShutdownExeName;
end;

function RunShutdownExe(const AArguments: string; out AError: string): Boolean;
var
  Proc: TProcess;
  ExePath: string;
begin
  Result := False;
  AError := '';
  ExePath := ShutdownExePath;
  if ExePath = '' then
  begin
    AError := 'Could not find ' + ShutdownExeName
      + ': the Windows system directory is unknown.';
    Exit;
  end;
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := ExePath;
    Proc.Parameters.Delimiter := ' ';
    Proc.Parameters.StrictDelimiter := True;
    Proc.Parameters.DelimitedText := AArguments;
    Proc.Options := [poNoConsole, poWaitOnExit];
    Proc.ShowWindow := swoHide;
    try
      Proc.Execute;
    except
      on E: Exception do
      begin
        AError := 'Could not start ' + ExePath + ': ' + E.Message;
        Exit;
      end;
    end;
    Result := Proc.ExitStatus = 0;
    if not Result then
      AError := Format('shutdown.exe %s failed with exit code %d.',
        [AArguments, Proc.ExitStatus]);
  finally
    Proc.Free;
  end;
end;

function LockWorkStation: BOOL; stdcall; external 'user32.dll';
function SetSuspendState(bHibernate, bForce, bWakeupEventsDisabled: ByteBool): ByteBool;
  stdcall; external 'powrprof.dll';

{ SetSuspendState requires the shutdown privilege to be enabled in the
  process token; it is present but disabled for interactive users. }
procedure EnableShutdownPrivilege;
var
  Token: THandle;
  Privileges: TOKEN_PRIVILEGES;
begin
  if not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
    @Token) then
    Exit;
  try
    Privileges.PrivilegeCount := 1;
    Privileges.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    if LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME, @Privileges.Privileges[0].Luid) then
      AdjustTokenPrivileges(Token, False, @Privileges, 0, nil, nil);
  finally
    CloseHandle(Token);
  end;
end;

function LastErrorText(const AWhat: string): string;
begin
  Result := AWhat + ': ' + SysErrorMessage(GetLastOSError);
end;

function ExecutePowerAction(AAction: TPowerAction; out AError: string): Boolean;
begin
  AError := '';
  case AAction of
    paShutdown, paRestart, paLogoff, paHibernate:
      Result := RunShutdownExe(ShutdownArguments(AAction), AError);
    paLock:
      begin
        Result := LockWorkStation;
        if not Result then
          AError := LastErrorText('Could not lock the workstation');
      end;
    paSleep:
      begin
        EnableShutdownPrivilege;
        Result := SetSuspendState(False, True, True);
        if not Result then
          AError := LastErrorText('Could not put the computer to sleep');
      end;
  else
    Result := False;
  end;
end;

{$ELSE}

function ShutdownExePath: string;
begin
  Result := '';
end;

function ExecutePowerAction(AAction: TPowerAction; out AError: string): Boolean;
begin
  Result := False;
  AError := PowerActionNames[AAction] + ' is only supported on Windows.';
end;

{$ENDIF}

end.
