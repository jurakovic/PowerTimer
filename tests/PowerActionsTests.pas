unit PowerActionsTests;

{ Only the pure mapping functions are tested here: running an action
  would shut down, lock or suspend the machine running the tests. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, PowerActions;

type

  TPowerActionsTests = class(TTestCase)
  published
    procedure PowerActionFromIndex_MatchesStoredOrder;
    procedure PowerActionFromIndex_OutOfRangeIsDefault;
    procedure FillPowerActionList_IndexIsOrdinal;
    procedure ShutdownArguments_PerAction;
    procedure ShutdownArguments_Forced;
    procedure CanForce_PerAction;
    procedure ShutdownExePath_IsInSystemDirectory;
    procedure Names_MatchActions;
    procedure Kinds_PerAction;
    procedure UnavailableReason_Sleep;
    procedure UnavailableReason_Hibernate;
    procedure UnavailableReason_OtherActionsAlwaysAvailable;
    procedure SystemPowerCapabilities_MatchesTheWindowsLayout;
  end;

implementation

function Caps(AS1, AS2, AS3, AS4, AHiberFile, AAoAc: Boolean): TPowerCapabilities;
begin
  Result.SystemS1 := AS1;
  Result.SystemS2 := AS2;
  Result.SystemS3 := AS3;
  Result.SystemS4 := AS4;
  Result.HiberFilePresent := AHiberFile;
  Result.AoAc := AAoAc;
end;

procedure TPowerActionsTests.PowerActionFromIndex_MatchesStoredOrder;
begin
  // These numbers are stored in the registry: if this test fails, existing
  // settings would select the wrong action.
  AssertTrue(PowerActionFromIndex(0) = paShutdown);
  AssertTrue(PowerActionFromIndex(1) = paRestart);
  AssertTrue(PowerActionFromIndex(2) = paLogoff);
  AssertTrue(PowerActionFromIndex(3) = paLock);
  AssertTrue(PowerActionFromIndex(4) = paSleep);
  AssertTrue(PowerActionFromIndex(5) = paHibernate);
end;

procedure TPowerActionsTests.PowerActionFromIndex_OutOfRangeIsDefault;
begin
  AssertTrue(PowerActionFromIndex(-1) = DefaultPowerAction);
  AssertTrue(PowerActionFromIndex(6) = DefaultPowerAction);
  AssertTrue(PowerActionFromIndex(MaxInt) = DefaultPowerAction);
end;

procedure TPowerActionsTests.FillPowerActionList_IndexIsOrdinal;
var
  Items: TStringList;
  Action: TPowerAction;
begin
  Items := TStringList.Create;
  try
    Items.Add('stale item');
    FillPowerActionList(Items);
    AssertEquals('count', Ord(High(TPowerAction)) + 1, Items.Count);
    for Action := Low(TPowerAction) to High(TPowerAction) do
    begin
      AssertEquals(PowerActionName(Action), Items[Ord(Action)]);
      AssertTrue(PowerActionFromIndex(Ord(Action)) = Action);
    end;
  finally
    Items.Free;
  end;
end;

procedure TPowerActionsTests.ShutdownArguments_PerAction;
begin
  AssertEquals('/s /t 0', ShutdownArguments(paShutdown));
  AssertEquals('/r /t 0', ShutdownArguments(paRestart));
  AssertEquals('/h', ShutdownArguments(paHibernate));
  // Signing out runs ExitWindowsEx
  AssertEquals('', ShutdownArguments(paLogoff));
  AssertEquals('', ShutdownArguments(paLock));
  AssertEquals('', ShutdownArguments(paSleep));
  AssertEquals('not forced', '/s /t 0', ShutdownArguments(paShutdown, False));
end;

{ Only Shut down and Restart get /f; Hibernate doesn't close the apps. }
procedure TPowerActionsTests.ShutdownArguments_Forced;
begin
  AssertEquals('/s /t 0 /f', ShutdownArguments(paShutdown, True));
  AssertEquals('/r /t 0 /f', ShutdownArguments(paRestart, True));
  AssertEquals('/h', ShutdownArguments(paHibernate, True));
  AssertEquals('', ShutdownArguments(paLogoff, True));
  AssertEquals('', ShutdownArguments(paLock, True));
  AssertEquals('', ShutdownArguments(paSleep, True));
end;

procedure TPowerActionsTests.CanForce_PerAction;
begin
  AssertTrue('Shut down', PowerActionCanForce(paShutdown));
  AssertTrue('Restart', PowerActionCanForce(paRestart));
  AssertTrue('Sign out', PowerActionCanForce(paLogoff));
  AssertFalse('Lock', PowerActionCanForce(paLock));
  AssertFalse('Sleep', PowerActionCanForce(paSleep));
  AssertFalse('Hibernate', PowerActionCanForce(paHibernate));
end;

procedure TPowerActionsTests.ShutdownExePath_IsInSystemDirectory;
{$IFDEF WINDOWS}
var
  Path: string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  Path := ShutdownExePath;
  AssertTrue('in System32: ' + Path, SameText(
    IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot'))
    + 'System32\shutdown.exe', Path));
  AssertTrue('exists: ' + Path, FileExists(Path));
  {$ELSE}
  AssertEquals('', ShutdownExePath);
  {$ENDIF}
end;

procedure TPowerActionsTests.Names_MatchActions;
begin
  AssertEquals('Shut down', PowerActionName(paShutdown));
  AssertEquals('Restart', PowerActionName(paRestart));
  AssertEquals('Sign out', PowerActionName(paLogoff));
  AssertEquals('Lock', PowerActionName(paLock));
  AssertEquals('Sleep', PowerActionName(paSleep));
  AssertEquals('Hibernate', PowerActionName(paHibernate));
end;

{ Lock, Sleep and Sign out are API calls, the others run shutdown.exe;
  only these have arguments for it. }
procedure TPowerActionsTests.Kinds_PerAction;
var
  Action: TPowerAction;
  Info: TPowerActionInfo;
begin
  AssertTrue('Lock', PowerActionInfo[paLock].Kind = akLockWorkStation);
  AssertTrue('Sleep', PowerActionInfo[paSleep].Kind = akSuspend);
  AssertTrue('Sign out', PowerActionInfo[paLogoff].Kind = akSignOut);
  for Action := Low(TPowerAction) to High(TPowerAction) do
  begin
    Info := PowerActionInfo[Action];
    if Action in [paLock, paSleep, paLogoff] then
      AssertEquals(Info.Name + ' arguments', '', Info.ShutdownArgs)
    else
    begin
      AssertTrue(Info.Name + ' kind', Info.Kind = akShutdownExe);
      AssertTrue(Info.Name + ' arguments', Info.ShutdownArgs <> '');
    end;
  end;
end;

procedure TPowerActionsTests.UnavailableReason_Sleep;
begin
  AssertEquals('S1', '', UnavailableReason(paSleep,
    Caps(True, False, False, False, False, False)));
  AssertEquals('S3', '', UnavailableReason(paSleep,
    Caps(False, False, True, False, False, False)));
  AssertEquals('Modern Standby only', '', UnavailableReason(paSleep,
    Caps(False, False, False, False, False, True)));
  AssertEquals('none', 'Sleep is not supported on this computer.',
    UnavailableReason(paSleep, Caps(False, False, False, True, True, False)));
end;

procedure TPowerActionsTests.UnavailableReason_Hibernate;
begin
  AssertEquals('S4 and the file', '', UnavailableReason(paHibernate,
    Caps(False, False, False, True, True, False)));
  AssertEquals('S4 without the file', 'Hibernation is turned off on this '
    + 'computer. It can be turned on with "powercfg /hibernate on" in a '
    + 'command prompt run as administrator.', UnavailableReason(paHibernate,
    Caps(True, True, True, True, False, False)));
  AssertEquals('no S4', 'Hibernation is not supported on this computer.',
    UnavailableReason(paHibernate, Caps(True, True, True, False, True, True)));
end;

procedure TPowerActionsTests.UnavailableReason_OtherActionsAlwaysAvailable;
var
  None: TPowerCapabilities;
begin
  None := Caps(False, False, False, False, False, False);
  AssertEquals('Shut down', '', UnavailableReason(paShutdown, None));
  AssertEquals('Restart', '', UnavailableReason(paRestart, None));
  AssertEquals('Sign out', '', UnavailableReason(paLogoff, None));
  AssertEquals('Lock', '', UnavailableReason(paLock, None));
end;

procedure TPowerActionsTests.SystemPowerCapabilities_MatchesTheWindowsLayout;
var
  R: TSystemPowerCapabilities;
begin
  // The offsets of SYSTEM_POWER_CAPABILITIES in the Windows SDK
  AssertEquals('size', 76, SizeOf(R));
  AssertEquals('SystemS1', 3, PByte(@R.SystemS1) - PByte(@R));
  AssertEquals('SystemS4', 6, PByte(@R.SystemS4) - PByte(@R));
  AssertEquals('HiberFilePresent', 8, PByte(@R.HiberFilePresent) - PByte(@R));
  AssertEquals('AoAc', 20, PByte(@R.AoAc) - PByte(@R));
end;

initialization
  RegisterTest(TPowerActionsTests);

end.
