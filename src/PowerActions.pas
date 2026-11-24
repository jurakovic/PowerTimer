unit PowerActions;

{ The actions Power Timer can perform when the countdown ends. }

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  { The ordinal values are part of the stored settings: they are written to
    the registry (defaultAction). Only append new actions; never reorder or
    remove one. }
  TPowerAction = (paShutdown, paRestart, paLogoff, paLock, paSleep, paHibernate);

  { How an action runs: shutdown.exe with arguments, LockWorkStation or
    SetSuspendState. }
  TActionKind = (akShutdownExe, akLockWorkStation, akSuspend);

  TPowerActionInfo = record
    Name: string;
    Kind: TActionKind;
    // The arguments for shutdown.exe of akShutdownExe, '' for the others
    ShutdownArgs: string;
  end;

const
  DefaultPowerAction = paShutdown;

  { Each action, described once: a new action is one entry, and the table
    doesn't compile without an entry for every action. }
  PowerActionInfo: array[TPowerAction] of TPowerActionInfo = (
    (Name: 'Shut down'; Kind: akShutdownExe; ShutdownArgs: '/s /t 0'),
    (Name: 'Restart'; Kind: akShutdownExe; ShutdownArgs: '/r /t 0'),
    (Name: 'Sign out'; Kind: akShutdownExe; ShutdownArgs: '/l'),
    (Name: 'Lock'; Kind: akLockWorkStation; ShutdownArgs: ''),
    (Name: 'Sleep'; Kind: akSuspend; ShutdownArgs: ''),
    (Name: 'Hibernate'; Kind: akShutdownExe; ShutdownArgs: '/h'));

{ The name of AAction, as the lists show it. }
function PowerActionName(AAction: TPowerAction): string;

{ Maps a list index (e.g. ItemIndex of a combo box or a stored setting)
  to an action. Out of range values give DefaultPowerAction. }
function PowerActionFromIndex(AIndex: Integer): TPowerAction;

{ Replaces the contents of AItems with the action names in TPowerAction
  order, so the index of an item is the ordinal of its action (see
  PowerActionFromIndex). Used to fill the action combo boxes. }
procedure FillPowerActionList(AItems: TStrings);

{ Arguments for shutdown.exe, or '' when the action does not use it. }
function ShutdownArguments(AAction: TPowerAction): string;

type
  { What the computer supports, of what Sleep and Hibernate need. }
  TPowerCapabilities = record
    SystemS1, SystemS2, SystemS3: Boolean; // sleep states
    SystemS4: Boolean; // hibernation
    HiberFilePresent: Boolean; // hibernation is turned on
    AoAc: Boolean; // Modern Standby
  end;

  { SYSTEM_POWER_CAPABILITIES of the Windows SDK, as GetPwrCapabilities
    fills it: the fields up to AoAc, then the rest of its 76 bytes. In the
    interface so the tests can check its layout. }
  TSystemPowerCapabilities = packed record
    PowerButtonPresent, SleepButtonPresent, LidPresent: ByteBool;
    SystemS1, SystemS2, SystemS3, SystemS4, SystemS5: ByteBool;
    HiberFilePresent: ByteBool;
    FullWake, VideoDimPresent, ApmPresent, UpsPresent: ByteBool;
    ThermalControl, ProcessorThrottle: ByteBool;
    ProcessorMinThrottle, ProcessorMaxThrottle: Byte;
    FastSystemS4, Hiberboot, WakeAlarmPresent: ByteBool;
    AoAc: ByteBool;
    Rest: array[21..75] of Byte;
  end;

{ Why AAction can't run with ACaps, or '' when it can. Sleep needs one of
  the sleep states S1 to S3, or Modern Standby, on which Windows reports
  no sleep state although SetSuspendState puts the computer to sleep.
  Hibernate needs S4 and the hibernation file; without the file,
  hibernation is turned off, and the reason says how to turn it on. The
  other actions are always available. }
function UnavailableReason(AAction: TPowerAction;
  const ACaps: TPowerCapabilities): string;

{ UnavailableReason for this computer, with its capabilities from
  GetPwrCapabilities. Only Sleep and Hibernate are checked; when the
  capabilities can't be read, the action counts as available (always ''
  on other platforms). }
function PowerActionUnavailableReason(AAction: TPowerAction): string;

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
  Windows, Process, SystemLibraries,
  {$ENDIF}
  SysUtils;

resourcestring
  rsSleepNotSupported = 'Sleep is not supported on this computer.';
  rsHibernateNotSupported = 'Hibernation is not supported on this computer.';
  rsHibernationOff = 'Hibernation is turned off on this computer. It can be '
    + 'turned on with "powercfg /hibernate on" in a command prompt run as '
    + 'administrator.';
  {$IFDEF WINDOWS}
  // shutdown.exe
  rsShutdownExeNotFound = 'Could not find %s: the Windows system directory is unknown.';
  // Path of shutdown.exe, error message
  rsCouldNotStart = 'Could not start %s: %s';
  // Arguments, exit code
  rsShutdownExeFailed = 'shutdown.exe %s failed with exit code %d.';
  rsCouldNotLock = 'Could not lock the workstation';
  rsCouldNotSleep = 'Could not put the computer to sleep';
  // DLL name, error message
  rsCouldNotLoad = 'Could not load %s: %s';
  {$ELSE}
  // Action name
  rsOnlyOnWindows = '%s is only supported on Windows.';
  {$ENDIF}

function PowerActionName(AAction: TPowerAction): string;
begin
  Result := PowerActionInfo[AAction].Name;
end;

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
      AItems.Add(PowerActionName(Action));
  finally
    AItems.EndUpdate;
  end;
end;

function ShutdownArguments(AAction: TPowerAction): string;
begin
  Result := PowerActionInfo[AAction].ShutdownArgs;
end;

function UnavailableReason(AAction: TPowerAction;
  const ACaps: TPowerCapabilities): string;
begin
  Result := '';
  case AAction of
    paSleep:
      if not (ACaps.SystemS1 or ACaps.SystemS2 or ACaps.SystemS3
        or ACaps.AoAc) then
        Result := rsSleepNotSupported;
    paHibernate:
      if not ACaps.SystemS4 then
        Result := rsHibernateNotSupported
      else if not ACaps.HiberFilePresent then
        Result := rsHibernationOff;
  end;
end;

{$IFDEF WINDOWS}

const
  ShutdownExeName = 'shutdown.exe';
  PowrProfName = 'powrprof.dll';

type
  TSetSuspendState = function(bHibernate, bForce,
    bWakeupEventsDisabled: ByteBool): ByteBool; stdcall;
  TGetPwrCapabilities = function(
    var lpspc: TSystemPowerCapabilities): ByteBool; stdcall;

var
  // Loaded on first use by PowrProfFunction
  PowrProf: THandle = 0;

function ShutdownExePath: string;
begin
  Result := SystemFilePath(ShutdownExeName);
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
    AError := Format(rsShutdownExeNotFound, [ShutdownExeName]);
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
        AError := Format(rsCouldNotStart, [ExePath, E.Message]);
        Exit;
      end;
    end;
    Result := Proc.ExitStatus = 0;
    if not Result then
      AError := Format(rsShutdownExeFailed, [AArguments, Proc.ExitStatus]);
  finally
    Proc.Free;
  end;
end;

{ user32.dll is one of the known DLLs, which Windows always loads from the
  system directory, so it can stay imported. }
function LockWorkStation: BOOL; stdcall; external 'user32.dll';

{ The function AName of powrprof.dll, or nil with a message in AError when
  the DLL or the function can't be loaded. The DLL is loaded from the
  system directory on first use instead of being imported: Windows loads
  an imported DLL when Power Timer starts, and since powrprof.dll isn't
  one of the known DLLs, it would look for it next to PowerTimer.exe
  first. }
function PowrProfFunction(const AName: string; out AError: string): Pointer;
begin
  AError := '';
  if PowrProf = 0 then
    PowrProf := LoadSystemLibrary(PowrProfName);
  if PowrProf <> 0 then
    Result := GetProcAddress(PowrProf, PChar(AName))
  else
    Result := nil;
  if Result = nil then
    AError := Format(rsCouldNotLoad, [PowrProfName, SysErrorMessage(GetLastOSError)]);
end;

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
var
  SetSuspendState: TSetSuspendState;
begin
  AError := '';
  Result := False;
  // No else: each kind has its branch
  case PowerActionInfo[AAction].Kind of
    akShutdownExe:
      Result := RunShutdownExe(ShutdownArguments(AAction), AError);
    akLockWorkStation:
      begin
        Result := LockWorkStation;
        if not Result then
          AError := LastErrorText(rsCouldNotLock);
      end;
    akSuspend:
      begin
        Pointer(SetSuspendState) := PowrProfFunction('SetSuspendState', AError);
        if not Assigned(SetSuspendState) then
          Exit(False);
        EnableShutdownPrivilege;
        // Sleep, not hibernate; bForce has no effect; wake events stay
        // enabled, so a wake timer such as a scheduled task can wake the
        // computer, as after Sleep from the Start menu
        Result := SetSuspendState(False, False, False);
        if not Result then
          AError := LastErrorText(rsCouldNotSleep);
      end;
  end;
end;

function PowerActionUnavailableReason(AAction: TPowerAction): string;
var
  GetPwrCapabilities: TGetPwrCapabilities;
  Error: string;
  SystemCaps: TSystemPowerCapabilities;
  Caps: TPowerCapabilities;
begin
  Result := '';
  if not (AAction in [paSleep, paHibernate]) then
    Exit;
  // Unknown capabilities don't stop the action: an error still shows when
  // it runs
  Pointer(GetPwrCapabilities) := PowrProfFunction('GetPwrCapabilities', Error);
  if not Assigned(GetPwrCapabilities) then
    Exit;
  FillChar(SystemCaps, SizeOf(SystemCaps), 0);
  if not GetPwrCapabilities(SystemCaps) then
    Exit;
  Caps.SystemS1 := SystemCaps.SystemS1;
  Caps.SystemS2 := SystemCaps.SystemS2;
  Caps.SystemS3 := SystemCaps.SystemS3;
  Caps.SystemS4 := SystemCaps.SystemS4;
  Caps.HiberFilePresent := SystemCaps.HiberFilePresent;
  Caps.AoAc := SystemCaps.AoAc;
  Result := UnavailableReason(AAction, Caps);
end;

{$ELSE}

function ShutdownExePath: string;
begin
  Result := '';
end;

function ExecutePowerAction(AAction: TPowerAction; out AError: string): Boolean;
begin
  Result := False;
  AError := Format(rsOnlyOnWindows, [PowerActionName(AAction)]);
end;

function PowerActionUnavailableReason(AAction: TPowerAction): string;
begin
  Result := '';
end;

{$ENDIF}

end.
