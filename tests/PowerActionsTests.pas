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
    procedure ShutdownExePath_IsInSystemDirectory;
    procedure Names_MatchActions;
  end;

implementation

procedure TPowerActionsTests.PowerActionFromIndex_MatchesStoredOrder;
begin
  // These numbers are stored in the registry (also by the C# version):
  // if this test fails, existing settings would select the wrong action.
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
      AssertEquals(PowerActionNames[Action], Items[Ord(Action)]);
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
  AssertEquals('/l', ShutdownArguments(paLogoff));
  AssertEquals('/h', ShutdownArguments(paHibernate));
  AssertEquals('', ShutdownArguments(paLock));
  AssertEquals('', ShutdownArguments(paSleep));
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
  AssertEquals('Shutdown', PowerActionNames[paShutdown]);
  AssertEquals('Restart', PowerActionNames[paRestart]);
  AssertEquals('Logoff', PowerActionNames[paLogoff]);
  AssertEquals('Lock', PowerActionNames[paLock]);
  AssertEquals('Sleep', PowerActionNames[paSleep]);
  AssertEquals('Hibernate', PowerActionNames[paHibernate]);
end;

initialization
  RegisterTest(TPowerActionsTests);

end.
