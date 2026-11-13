unit CountdownTests;

{ Drives TCountdown with its own times and tick counts. The events are
  recorded in a log, so their order is checked too: 'change;' for OnChange
  and 'run:<ordinal>;' for OnRunAction. }

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, fpcunit, testregistry, TimerLogic, PowerActions,
  Countdown;

type

  TCountdownTests = class(TTestCase)
  private
    FCountdown: TCountdown;
    FLog: string;
    FNow: TDateTime;
    procedure CountdownChange(Sender: TObject);
    procedure CountdownRunAction(AAction: TPowerAction);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Start_CountdownWaitsForTheDuration;
    procedure Tick_BeforeTheEndRunsNothing;
    procedure Tick_AtTheEndStopsAndRunsTheAction;
    procedure Tick_AfterTheEndDoesNothingMore;
    procedure Start_ClockTimeWaitsUntilThatTime;
    procedure Start_ZeroCountdownStartsNothing;
    procedure Stop_StopsWithoutRunningTheAction;
    procedure Stop_WhenIdleDoesNothing;
    procedure Tick_WhenIdleDoesNothing;
    procedure Start_KeepsTheValues;
  end;

implementation

procedure TCountdownTests.CountdownChange(Sender: TObject);
begin
  AssertTrue('sender', Sender = FCountdown);
  FLog := FLog + 'change;';
end;

procedure TCountdownTests.CountdownRunAction(AAction: TPowerAction);
begin
  FLog := FLog + Format('run:%d;', [Ord(AAction)]);
end;

procedure TCountdownTests.SetUp;
begin
  FCountdown := TCountdown.Create;
  FCountdown.OnChange := @CountdownChange;
  FCountdown.OnRunAction := @CountdownRunAction;
  FLog := '';
  FNow := EncodeDateTime(2024, 3, 1, 12, 0, 0, 0);
end;

procedure TCountdownTests.TearDown;
begin
  FCountdown.Free;
end;

procedure TCountdownTests.Start_CountdownWaitsForTheDuration;
begin
  AssertTrue('started', FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10),
    paLock, FNow, 1000));
  AssertTrue('running', FCountdown.Running);
  AssertEquals('remaining', 10, FCountdown.RemainingSeconds(FNow, 1000));
  AssertEquals('log', 'change;', FLog);
end;

procedure TCountdownTests.Tick_BeforeTheEndRunsNothing;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 10999);
  AssertTrue('running', FCountdown.Running);
  AssertEquals('remaining', 1, FCountdown.RemainingSeconds(FNow, 10999));
  AssertEquals('log', 'change;', FLog);
end;

procedure TCountdownTests.Tick_AtTheEndStopsAndRunsTheAction;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 11000);
  AssertFalse('running', FCountdown.Running);
  AssertEquals('remaining', 0, FCountdown.RemainingSeconds(FNow, 11000));
  AssertEquals('log', 'change;change;run:3;', FLog);
end;

procedure TCountdownTests.Tick_AfterTheEndDoesNothingMore;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 11000);
  FCountdown.Tick(FNow, 12000);
  AssertEquals('log', 'change;change;run:3;', FLog);
end;

procedure TCountdownTests.Start_ClockTimeWaitsUntilThatTime;
begin
  FNow := EncodeDateTime(2024, 3, 1, 22, 0, 0, 0);
  AssertTrue('started', FCountdown.Start(cmClockTime, MakeTimeParts(1, 0, 0),
    paShutdown, FNow, 5000));
  AssertEquals('remaining', 3 * SecondsPerHour,
    FCountdown.RemainingSeconds(FNow, 5000));
end;

procedure TCountdownTests.Start_ZeroCountdownStartsNothing;
begin
  AssertFalse('started', FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 0),
    paLock, FNow, 1000));
  AssertFalse('running', FCountdown.Running);
  AssertEquals('log', '', FLog);
end;

procedure TCountdownTests.Stop_StopsWithoutRunningTheAction;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Stop;
  AssertFalse('running', FCountdown.Running);
  AssertEquals('remaining', 0, FCountdown.RemainingSeconds(FNow, 1000));
  FCountdown.Tick(FNow, 20000);
  AssertEquals('log', 'change;change;', FLog);
end;

procedure TCountdownTests.Stop_WhenIdleDoesNothing;
begin
  FCountdown.Stop;
  AssertFalse('running', FCountdown.Running);
  AssertEquals('log', '', FLog);
end;

procedure TCountdownTests.Tick_WhenIdleDoesNothing;
begin
  FCountdown.Tick(FNow, 20000);
  AssertFalse('running', FCountdown.Running);
  AssertEquals('log', '', FLog);
end;

procedure TCountdownTests.Start_KeepsTheValues;
var
  Entered: TTimeParts;
begin
  FCountdown.Start(cmClockTime, MakeTimeParts(13, 45, 30), paHibernate, FNow,
    1000);
  Entered := FCountdown.Entered;
  AssertTrue('mode', FCountdown.Mode = cmClockTime);
  AssertTrue('action', FCountdown.Action = paHibernate);
  AssertEquals('hours', 13, Entered.Hours);
  AssertEquals('minutes', 45, Entered.Minutes);
  AssertEquals('seconds', 30, Entered.Seconds);
end;

initialization
  RegisterTest(TCountdownTests);

end.
