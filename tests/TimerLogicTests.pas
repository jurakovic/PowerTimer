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
  published
    procedure SecondsConversion_RoundTrips;
    procedure SecondsToTimeParts_NegativeIsZero;
    procedure SecondsToTimeParts_FullDayIs24Hours;
    procedure MSecsUntilClockTime_LaterToday;
    procedure MSecsUntilClockTime_EarlierMeansTomorrow;
    procedure MSecsUntilClockTime_NowMeansTomorrow;
    procedure NextOccurrence_LaterToday;
    procedure NextOccurrence_EarlierMeansTomorrow;
    procedure NextOccurrence_NowMeansTomorrow;
    procedure SecondsUntil_RoundsUp;
    procedure RemainingSeconds_RoundsUp;
    procedure ClampDelayHours_Limits;
    procedure DefaultCountdown_UsesDelay;
    procedure DefaultClockTime_AddsDelay;
    procedure FormatRemaining_Formats;
  end;

implementation

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

initialization
  RegisterTest(TTimerLogicTests);

end.
