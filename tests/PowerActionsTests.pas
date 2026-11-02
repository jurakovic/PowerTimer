unit PowerActionsTests;

{ Only the pure mapping functions are tested here: running an action
  would shut down, lock or suspend the machine running the tests. }

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, PowerActions;

type

  TPowerActionsTests = class(TTestCase)
  published
    procedure PowerActionFromIndex_MapsListOrder;
    procedure PowerActionFromIndex_OutOfRangeIsDefault;
    procedure ShutdownArguments_PerAction;
    procedure Names_MatchActions;
  end;

implementation

procedure TPowerActionsTests.PowerActionFromIndex_MapsListOrder;
begin
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

procedure TPowerActionsTests.ShutdownArguments_PerAction;
begin
  AssertEquals('/s /t 0', ShutdownArguments(paShutdown));
  AssertEquals('/r /t 0', ShutdownArguments(paRestart));
  AssertEquals('/l', ShutdownArguments(paLogoff));
  AssertEquals('/h', ShutdownArguments(paHibernate));
  AssertEquals('', ShutdownArguments(paLock));
  AssertEquals('', ShutdownArguments(paSleep));
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
