unit TimerLogicTests;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, fpcunit, testregistry, TimerLogic;

type

  TTimerLogicTests = class(TTestCase)
  private
    procedure CheckParts(const AExpected, AActual: TTimeParts);
    procedure CheckDateTime(AExpected, AActual: TDateTime);
    function TestFormat: TFormatSettings;
  published
    procedure SecondsConversion_RoundTrips;
    procedure SecondsToTimeParts_NegativeIsZero;
    procedure SecondsToTimeParts_FullDayIs24Hours;
    procedure SecondsToFieldParts_StopsAt99Hours;
    procedure MSecsUntilClockTime_LaterToday;
    procedure MSecsUntilClockTime_EarlierMeansTomorrow;
    procedure MSecsUntilClockTime_NowMeansTomorrow;
    procedure NextOccurrence_LaterToday;
    procedure NextOccurrence_EarlierMeansTomorrow;
    procedure NextOccurrence_NowMeansTomorrow;
    procedure SecondsUntil_RoundsUp;
    procedure RemainingSeconds_RoundsUp;
    procedure ClampDelayHours_Limits;
    procedure FormatDelayHours_ShowsTheUnit;
    procedure DefaultCountdown_UsesDelay;
    procedure DefaultClockTime_AddsDelay;
    procedure FormatRemaining_Formats;
    procedure FormatDuration_Formats;
    procedure FormatEndTime_SameDay;
    procedure FormatEndTime_NextDayIsTomorrow;
    procedure FormatEndTime_LaterDayShowsTheDate;
    procedure FormatEndTime_WithSeconds;
    procedure CountdownStatus_CountdownIdle;
    procedure CountdownStatus_ZeroCountdownIsRightAway;
    procedure CountdownStatus_ClockIdle;
    procedure CountdownStatus_ClockIdleTomorrow;
    procedure CountdownStatus_Running;
    procedure CountdownStatus_RunningOverMidnight;
  end;

implementation

const
  // UTF-8 encoded U+00B7, as in the status texts
  Dot = #$C2#$B7;

procedure TTimerLogicTests.CheckParts(const AExpected, AActual: TTimeParts);
begin
  AssertEquals('hours', AExpected.Hours, AActual.Hours);
  AssertEquals('minutes', AExpected.Minutes, AActual.Minutes);
  AssertEquals('seconds', AExpected.Seconds, AActual.Seconds);
end;

procedure TTimerLogicTests.CheckDateTime(AExpected, AActual: TDateTime);
begin
  AssertTrue(Format('expected %s, got %s', [
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AExpected),
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AActual)]),
    SameDateTime(AExpected, AActual));
end;

{ A fixed format, so the results don't depend on the locale the tests run
  in. }
function TTimerLogicTests.TestFormat: TFormatSettings;
begin
  Result := DefaultFormatSettings;
  Result.ShortTimeFormat := 'hh:nn';
  Result.LongTimeFormat := 'hh:nn:ss';
  Result.TimeSeparator := ':';
  Result.ShortDateFormat := 'dd.mm.yyyy';
  Result.DateSeparator := '.';
end;

procedure TTimerLogicTests.SecondsConversion_RoundTrips;
var
  P: TTimeParts;
begin
  P := SecondsToTimeParts(3725);
  CheckParts(MakeTimeParts(1, 2, 5), P);
  AssertEquals(3725, TimePartsToSeconds(P));
  AssertEquals(86399, TimePartsToSeconds(MakeTimeParts(23, 59, 59)));
end;

procedure TTimerLogicTests.SecondsToTimeParts_NegativeIsZero;
begin
  CheckParts(MakeTimeParts(0, 0, 0), SecondsToTimeParts(-10));
end;

procedure TTimerLogicTests.SecondsToTimeParts_FullDayIs24Hours;
begin
  CheckParts(MakeTimeParts(24, 0, 0), SecondsToTimeParts(SecondsPerDay));
end;

procedure TTimerLogicTests.SecondsToFieldParts_StopsAt99Hours;
begin
  CheckParts(MakeTimeParts(24, 0, 0), SecondsToFieldParts(SecondsPerDay));
  CheckParts(MakeTimeParts(99, 59, 59), SecondsToFieldParts(MaxFieldSeconds));
  CheckParts(MakeTimeParts(99, 59, 59), SecondsToFieldParts(100 * SecondsPerHour));
  CheckParts(MakeTimeParts(0, 0, 0), SecondsToFieldParts(-10));
end;

procedure TTimerLogicTests.MSecsUntilClockTime_LaterToday;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 10, 0, 0, 0);
  AssertEquals(Int64(90) * 60 * 1000,
    MSecsUntilClockTime(NowValue, MakeTimeParts(11, 30, 0)));
end;

procedure TTimerLogicTests.MSecsUntilClockTime_EarlierMeansTomorrow;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 22, 0, 0, 0);
  AssertEquals(Int64(3) * 60 * 60 * 1000,
    MSecsUntilClockTime(NowValue, MakeTimeParts(1, 0, 0)));
end;

procedure TTimerLogicTests.MSecsUntilClockTime_NowMeansTomorrow;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 12, 34, 56, 0);
  AssertEquals(MSecsPerDay,
    MSecsUntilClockTime(NowValue, MakeTimeParts(12, 34, 56)));
  NowValue := EncodeDateTime(2024, 3, 1, 12, 34, 56, 400);
  AssertEquals(MSecsPerDay - 400,
    MSecsUntilClockTime(NowValue, MakeTimeParts(12, 34, 56)));
end;

procedure TTimerLogicTests.NextOccurrence_LaterToday;
begin
  CheckDateTime(EncodeDateTime(2024, 3, 1, 11, 30, 0, 0),
    NextOccurrence(EncodeDateTime(2024, 3, 1, 10, 0, 0, 0), MakeTimeParts(11, 30, 0)));
end;

procedure TTimerLogicTests.NextOccurrence_EarlierMeansTomorrow;
begin
  CheckDateTime(EncodeDateTime(2024, 3, 2, 1, 0, 0, 0),
    NextOccurrence(EncodeDateTime(2024, 3, 1, 22, 0, 0, 0), MakeTimeParts(1, 0, 0)));
end;

procedure TTimerLogicTests.NextOccurrence_NowMeansTomorrow;
begin
  CheckDateTime(EncodeDateTime(2024, 3, 2, 12, 34, 56, 0),
    NextOccurrence(EncodeDateTime(2024, 3, 1, 12, 34, 56, 0), MakeTimeParts(12, 34, 56)));
  CheckDateTime(EncodeDateTime(2024, 3, 2, 12, 34, 56, 0),
    NextOccurrence(EncodeDateTime(2024, 3, 1, 12, 34, 56, 400), MakeTimeParts(12, 34, 56)));
end;

procedure TTimerLogicTests.SecondsUntil_RoundsUp;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 12, 0, 0, 0);
  AssertEquals('1 ms', 1, SecondsUntil(NowValue, IncMilliSecond(NowValue, 1)));
  AssertEquals('1000 ms', 1, SecondsUntil(NowValue, IncMilliSecond(NowValue, 1000)));
  AssertEquals('1001 ms', 2, SecondsUntil(NowValue, IncMilliSecond(NowValue, 1001)));
  AssertEquals('1 h', 3600, SecondsUntil(NowValue, IncHour(NowValue)));
  AssertEquals('now', 0, SecondsUntil(NowValue, NowValue));
  AssertEquals('past', 0, SecondsUntil(NowValue, IncSecond(NowValue, -5)));
end;

procedure TTimerLogicTests.RemainingSeconds_RoundsUp;
begin
  AssertEquals(10, RemainingSeconds(1000, 11000));
  AssertEquals(10, RemainingSeconds(1001, 11000));
  AssertEquals(1, RemainingSeconds(10999, 11000));
  AssertEquals(0, RemainingSeconds(11000, 11000));
  AssertEquals(0, RemainingSeconds(12000, 11000));
end;

procedure TTimerLogicTests.ClampDelayHours_Limits;
begin
  AssertEquals(1, ClampDelayHours(0));
  AssertEquals(1, ClampDelayHours(-3));
  AssertEquals(5, ClampDelayHours(5));
  AssertEquals(24, ClampDelayHours(24));
  AssertEquals(24, ClampDelayHours(100));
end;

procedure TTimerLogicTests.FormatDelayHours_ShowsTheUnit;
begin
  AssertEquals('1 h', FormatDelayHours(1));
  AssertEquals('24 h', FormatDelayHours(24));
end;

procedure TTimerLogicTests.DefaultCountdown_UsesDelay;
begin
  CheckParts(MakeTimeParts(1, 0, 0), DefaultCountdown(1));
  CheckParts(MakeTimeParts(23, 0, 0), DefaultCountdown(23));
  CheckParts(MakeTimeParts(23, 59, 59), DefaultCountdown(24));
  CheckParts(MakeTimeParts(1, 0, 0), DefaultCountdown(0));
end;

procedure TTimerLogicTests.DefaultClockTime_AddsDelay;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 22, 15, 30, 0);
  CheckParts(MakeTimeParts(0, 15, 30), DefaultClockTime(NowValue, 2));
  CheckParts(MakeTimeParts(22, 15, 30), DefaultClockTime(NowValue, 24));
end;

procedure TTimerLogicTests.FormatRemaining_Formats;
begin
  AssertEquals('00 h 00 m 00 s', FormatRemaining(0));
  AssertEquals('01 h 05 m 09 s', FormatRemaining(3909));
  AssertEquals('23 h 59 m 59 s', FormatRemaining(86399));
end;

procedure TTimerLogicTests.FormatDuration_Formats;
begin
  AssertEquals('0', '00:00:00', FormatDuration(0));
  AssertEquals('59', '00:00:59', FormatDuration(59));
  AssertEquals('3600', '01:00:00', FormatDuration(3600));
  AssertEquals('86399', '23:59:59', FormatDuration(86399));
  AssertEquals('86400', '24:00:00', FormatDuration(86400));
  AssertEquals('-5', '00:00:00', FormatDuration(-5));
end;

procedure TTimerLogicTests.FormatEndTime_SameDay;
begin
  AssertEquals('at 23:45', FormatEndTime(EncodeDateTime(2024, 3, 1, 22, 45, 0, 0),
    EncodeDateTime(2024, 3, 1, 23, 45, 0, 0), False, TestFormat));
end;

procedure TTimerLogicTests.FormatEndTime_NextDayIsTomorrow;
begin
  AssertEquals('tomorrow at 01:00', FormatEndTime(
    EncodeDateTime(2024, 3, 1, 23, 30, 0, 0),
    EncodeDateTime(2024, 3, 2, 1, 0, 0, 0), False, TestFormat));
end;

procedure TTimerLogicTests.FormatEndTime_LaterDayShowsTheDate;
begin
  AssertEquals('on 03.03.2024 at 01:00', FormatEndTime(
    EncodeDateTime(2024, 3, 1, 23, 30, 0, 0),
    EncodeDateTime(2024, 3, 3, 1, 0, 0, 0), False, TestFormat));
end;

procedure TTimerLogicTests.FormatEndTime_WithSeconds;
var
  NowValue, EndValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 12, 0, 0, 0);
  EndValue := EncodeDateTime(2024, 3, 1, 14, 0, 30, 0);
  AssertEquals('with', 'at 14:00:30', FormatEndTime(NowValue, EndValue, True, TestFormat));
  AssertEquals('without', 'at 14:00', FormatEndTime(NowValue, EndValue, False, TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_CountdownIdle;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 22, 45, 0, 0);
  AssertEquals('Shutdown at 23:45 if started now ' + Dot + ' in 01:00:00',
    CountdownStatus(skCountdownIdle, 'Shutdown', NowValue, IncHour(NowValue),
      SecondsPerHour, False, TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_ZeroCountdownIsRightAway;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 22, 45, 0, 0);
  AssertEquals('Shutdown right away if started now',
    CountdownStatus(skCountdownIdle, 'Shutdown', NowValue, NowValue, 0, False,
      TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_ClockIdle;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 14, 30, 0, 0);
  AssertEquals('Restart at 15:00 ' + Dot + ' in 00:30:00',
    CountdownStatus(skClockIdle, 'Restart', NowValue,
      EncodeDateTime(2024, 3, 1, 15, 0, 0, 0), 30 * SecondsPerMinute, False,
      TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_ClockIdleTomorrow;
var
  NowValue: TDateTime;
begin
  // 14:00 entered at 14:30, e.g. a typo for 15:00
  NowValue := EncodeDateTime(2024, 3, 1, 14, 30, 0, 0);
  AssertEquals('Shutdown tomorrow at 14:00 ' + Dot + ' in 23:30:00',
    CountdownStatus(skClockIdle, 'Shutdown', NowValue,
      EncodeDateTime(2024, 3, 2, 14, 0, 0, 0), 23 * SecondsPerHour + 30 * SecondsPerMinute,
      False, TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_Running;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 23, 2, 43, 0);
  AssertEquals('Shutdown at 23:45 ' + Dot + ' 00:42:17 left',
    CountdownStatus(skRunning, 'Shutdown', NowValue,
      EncodeDateTime(2024, 3, 1, 23, 45, 0, 0), 42 * SecondsPerMinute + 17, False,
      TestFormat));
end;

procedure TTimerLogicTests.CountdownStatus_RunningOverMidnight;
var
  NowValue: TDateTime;
begin
  NowValue := EncodeDateTime(2024, 3, 1, 14, 30, 1, 0);
  AssertEquals('Hibernate tomorrow at 14:00:30 ' + Dot + ' 23:30:29 left',
    CountdownStatus(skRunning, 'Hibernate', NowValue,
      EncodeDateTime(2024, 3, 2, 14, 0, 30, 0), 23 * SecondsPerHour + 30 * SecondsPerMinute + 29,
      True, TestFormat));
end;

initialization
  RegisterTest(TTimerLogicTests);

end.
