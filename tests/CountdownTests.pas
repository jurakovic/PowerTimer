unit CountdownTests;

{ Drives TCountdown with its own times and tick counts. The events are
  recorded in a log, so their order is checked too: 'change:1;' for
  OnChange while running and 'change:0;' when not, since the main form's
  handler reads Running, 'run:<ordinal>;' for OnRunAction and 'warn;' for
  OnWarn. }

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
    procedure CheckDateTime(const AMessage: string; AExpected, AActual: TDateTime);
    procedure CountdownChange(Sender: TObject);
    procedure CountdownRunAction(AAction: TPowerAction);
    procedure CountdownWarn(Sender: TObject);
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
    procedure Tick_ClockSetBackWaitsLonger;
    procedure Tick_ClockSetForwardRunsAtOnce;
    procedure Tick_CountdownIgnoresTheClock;
    procedure EndTime_CountdownIsStartPlusTheDuration;
    procedure EndTime_CountdownFollowsAClockChange;
    procedure EndTime_ClockTimeIsTheTarget;
    procedure Warn_OnceAtWarnSecondsLeft;
    procedure Warn_NotForACountdownOfWarnSecondsOrLess;
    procedure Warn_NeverWithZeroWarnSeconds;
    procedure Warn_ClockTime;
    procedure Postpone_CountdownMovesTheEndAndWarnsAgain;
    procedure Postpone_ClockTimeMovesTheTargetAndWarnsAgain;
    procedure Postpone_KeepsTheEnteredTime;
    procedure Postpone_WhenIdleDoesNothing;
    procedure Start_AfterAWarningWarnsAgain;
  end;

implementation

procedure TCountdownTests.CountdownChange(Sender: TObject);
begin
  AssertTrue('sender', Sender = FCountdown);
  FLog := FLog + Format('change:%d;', [Ord(FCountdown.Running)]);
end;

procedure TCountdownTests.CountdownRunAction(AAction: TPowerAction);
begin
  FLog := FLog + Format('run:%d;', [Ord(AAction)]);
end;

procedure TCountdownTests.CountdownWarn(Sender: TObject);
begin
  AssertTrue('sender', Sender = FCountdown);
  FLog := FLog + 'warn;';
end;

procedure TCountdownTests.CheckDateTime(const AMessage: string; AExpected,
  AActual: TDateTime);
begin
  AssertTrue(Format('%s: expected %s, got %s', [AMessage,
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AExpected),
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AActual)]),
    SameDateTime(AExpected, AActual));
end;

procedure TCountdownTests.SetUp;
begin
  FCountdown := TCountdown.Create;
  FCountdown.OnChange := @CountdownChange;
  FCountdown.OnRunAction := @CountdownRunAction;
  FCountdown.OnWarn := @CountdownWarn;
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
  AssertEquals('log', 'change:1;', FLog);
end;

procedure TCountdownTests.Tick_BeforeTheEndRunsNothing;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 10999);
  AssertTrue('running', FCountdown.Running);
  AssertEquals('remaining', 1, FCountdown.RemainingSeconds(FNow, 10999));
  AssertEquals('log', 'change:1;', FLog);
end;

procedure TCountdownTests.Tick_AtTheEndStopsAndRunsTheAction;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 11000);
  AssertFalse('running', FCountdown.Running);
  AssertEquals('remaining', 0, FCountdown.RemainingSeconds(FNow, 11000));
  AssertEquals('log', 'change:1;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Tick_AfterTheEndDoesNothingMore;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 0, 10), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 11000);
  FCountdown.Tick(FNow, 12000);
  AssertEquals('log', 'change:1;change:0;run:3;', FLog);
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
  AssertEquals('log', 'change:1;change:0;', FLog);
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

procedure TCountdownTests.Tick_ClockSetBackWaitsLonger;
var
  Start: TDateTime;
begin
  // 07:00 entered at 23:00 on the night the clocks go back an hour: after
  // 8 hours the clock shows 06:00, and it runs only at 07:00, 9 hours on.
  Start := EncodeDateTime(2024, 10, 26, 23, 0, 0, 0);
  FCountdown.Start(cmClockTime, MakeTimeParts(7, 0, 0), paLock, Start, 1000);
  AssertEquals('at start', 8 * SecondsPerHour,
    FCountdown.RemainingSeconds(Start, 1000));
  FCountdown.Tick(EncodeDateTime(2024, 10, 27, 6, 0, 0, 0),
    1000 + 8 * SecondsPerHour * MSecsPerSecond);
  AssertTrue('running at 06:00', FCountdown.Running);
  AssertEquals('at 06:00', SecondsPerHour, FCountdown.RemainingSeconds(
    EncodeDateTime(2024, 10, 27, 6, 0, 0, 0), 1000 + 8 * SecondsPerHour * MSecsPerSecond));
  FCountdown.Tick(EncodeDateTime(2024, 10, 27, 7, 0, 0, 0),
    1000 + 9 * SecondsPerHour * MSecsPerSecond);
  AssertFalse('running at 07:00', FCountdown.Running);
  AssertEquals('log', 'change:1;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Tick_ClockSetForwardRunsAtOnce;
begin
  FCountdown.Start(cmClockTime, MakeTimeParts(13, 0, 0), paLock, FNow, 1000);
  FCountdown.Tick(EncodeDateTime(2024, 3, 1, 13, 0, 1, 0), 2000);
  AssertFalse('running', FCountdown.Running);
  AssertEquals('log', 'change:1;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Tick_CountdownIgnoresTheClock;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(1, 0, 0), paLock, FNow, 1000);
  FCountdown.Tick(IncHour(FNow, 2), 2000);
  AssertTrue('running', FCountdown.Running);
  AssertEquals('remaining', SecondsPerHour - 1,
    FCountdown.RemainingSeconds(IncHour(FNow, 2), 2000));
  AssertEquals('log', 'change:1;', FLog);
end;

procedure TCountdownTests.EndTime_CountdownIsStartPlusTheDuration;
var
  Later: TDateTime;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(1, 0, 0), paLock, FNow, 1000);
  CheckDateTime('at start', IncHour(FNow), FCountdown.EndTime(FNow, 1000));
  // Ten minutes on, the clock 400 ms ahead of the tick count
  Later := IncMilliSecond(IncMinute(FNow, 10), 400);
  FCountdown.Tick(Later, 1000 + 10 * SecondsPerMinute * MSecsPerSecond);
  CheckDateTime('ten minutes on', IncHour(FNow),
    FCountdown.EndTime(Later, 1000 + 10 * SecondsPerMinute * MSecsPerSecond));
end;

procedure TCountdownTests.EndTime_CountdownFollowsAClockChange;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(1, 0, 0), paLock, FNow, 1000);
  // The clock is set an hour ahead, the tick count moves on by a second
  CheckDateTime('after the change', IncHour(FNow, 2),
    FCountdown.EndTime(IncSecond(IncHour(FNow), 1), 2000));
  FCountdown.Tick(IncSecond(IncHour(FNow), 1), 2000);
  CheckDateTime('kept by Tick', IncHour(FNow, 2),
    FCountdown.EndTime(IncSecond(IncHour(FNow), 2), 3000));
end;

procedure TCountdownTests.EndTime_ClockTimeIsTheTarget;
begin
  FNow := EncodeDateTime(2024, 3, 1, 22, 0, 0, 0);
  FCountdown.Start(cmClockTime, MakeTimeParts(1, 0, 0), paShutdown, FNow, 5000);
  CheckDateTime('at start', EncodeDateTime(2024, 3, 2, 1, 0, 0, 0),
    FCountdown.EndTime(FNow, 5000));
  CheckDateTime('an hour on', EncodeDateTime(2024, 3, 2, 1, 0, 0, 0),
    FCountdown.EndTime(IncHour(FNow), 5000 + SecondsPerHour * MSecsPerSecond));
end;

procedure TCountdownTests.Warn_OnceAtWarnSecondsLeft;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 60000);
  AssertEquals('61 s left', 'change:1;', FLog);
  FCountdown.Tick(FNow, 61000);
  AssertEquals('60 s left', 'change:1;warn;', FLog);
  FCountdown.Tick(FNow, 62000);
  AssertEquals('59 s left', 'change:1;warn;', FLog);
  FCountdown.Tick(FNow, 121000);
  AssertEquals('at the end', 'change:1;warn;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Warn_NotForACountdownOfWarnSecondsOrLess;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 1, 0), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 1000);
  FCountdown.Tick(FNow, 30000);
  FCountdown.Tick(FNow, 61000);
  AssertEquals('60 s', 'change:1;change:0;run:3;', FLog);

  FLog := '';
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 1, 1), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 1000);
  AssertEquals('61 s, at the start', 'change:1;', FLog);
  FCountdown.Tick(FNow, 2000);
  AssertEquals('61 s, at 60 s left', 'change:1;warn;', FLog);
end;

procedure TCountdownTests.Warn_NeverWithZeroWarnSeconds;
begin
  FCountdown.WarnSeconds := 0;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 61000);
  FCountdown.Tick(FNow, 120000);
  FCountdown.Tick(FNow, 121000);
  AssertEquals('log', 'change:1;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Warn_ClockTime;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmClockTime, MakeTimeParts(12, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(IncSecond(FNow, 59), 2000);
  AssertEquals('61 s left', 'change:1;', FLog);
  FCountdown.Tick(IncSecond(FNow, 60), 3000);
  AssertEquals('60 s left', 'change:1;warn;', FLog);
end;

procedure TCountdownTests.Postpone_CountdownMovesTheEndAndWarnsAgain;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(IncSecond(FNow, 60), 61000);
  AssertEquals('warned', 'change:1;warn;', FLog);
  FCountdown.Postpone(10 * SecondsPerMinute);
  AssertTrue('running', FCountdown.Running);
  AssertEquals('remaining', 60 + 10 * SecondsPerMinute,
    FCountdown.RemainingSeconds(IncSecond(FNow, 60), 61000));
  CheckDateTime('end', IncSecond(FNow, 120 + 10 * SecondsPerMinute),
    FCountdown.EndTime(IncSecond(FNow, 60), 61000));
  FCountdown.Tick(IncSecond(FNow, 120), 121000);
  AssertEquals('at the old end', 'change:1;warn;', FLog);
  FCountdown.Tick(IncSecond(FNow, 660), 661000);
  AssertEquals('60 s before the new end', 'change:1;warn;warn;', FLog);
  FCountdown.Tick(IncSecond(FNow, 720), 721000);
  AssertEquals('at the new end', 'change:1;warn;warn;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Postpone_ClockTimeMovesTheTargetAndWarnsAgain;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmClockTime, MakeTimeParts(12, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(IncSecond(FNow, 60), 2000);
  AssertEquals('warned', 'change:1;warn;', FLog);
  FCountdown.Postpone(10 * SecondsPerMinute);
  AssertEquals('remaining', 60 + 10 * SecondsPerMinute,
    FCountdown.RemainingSeconds(IncSecond(FNow, 60), 2000));
  CheckDateTime('end', EncodeDateTime(2024, 3, 1, 12, 12, 0, 0),
    FCountdown.EndTime(IncSecond(FNow, 60), 2000));
  FCountdown.Tick(EncodeDateTime(2024, 3, 1, 12, 2, 0, 0), 3000);
  AssertEquals('at the old end', 'change:1;warn;', FLog);
  FCountdown.Tick(EncodeDateTime(2024, 3, 1, 12, 11, 0, 0), 4000);
  AssertEquals('60 s before the new end', 'change:1;warn;warn;', FLog);
  FCountdown.Tick(EncodeDateTime(2024, 3, 1, 12, 12, 0, 0), 5000);
  AssertEquals('at the new end', 'change:1;warn;warn;change:0;run:3;', FLog);
end;

procedure TCountdownTests.Postpone_KeepsTheEnteredTime;
var
  Entered: TTimeParts;
begin
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 1000);
  FCountdown.Postpone(10 * SecondsPerMinute);
  Entered := FCountdown.Entered;
  AssertEquals('minutes', 2, Entered.Minutes);
  AssertEquals('seconds', 0, Entered.Seconds);
  AssertEquals('log', 'change:1;', FLog);
end;

procedure TCountdownTests.Postpone_WhenIdleDoesNothing;
begin
  FCountdown.Postpone(10 * SecondsPerMinute);
  AssertFalse('running', FCountdown.Running);
  AssertEquals('remaining', 0, FCountdown.RemainingSeconds(FNow, 1000));
  AssertEquals('log', '', FLog);
end;

procedure TCountdownTests.Start_AfterAWarningWarnsAgain;
begin
  FCountdown.WarnSeconds := 60;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 1000);
  FCountdown.Tick(FNow, 61000);
  FCountdown.Stop;
  FCountdown.Start(cmCountdown, MakeTimeParts(0, 2, 0), paLock, FNow, 100000);
  FCountdown.Tick(FNow, 160000);
  AssertEquals('log', 'change:1;warn;change:0;change:1;warn;', FLog);
end;

initialization
  RegisterTest(TCountdownTests);

end.
