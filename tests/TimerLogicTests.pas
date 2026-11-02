unit TimerLogicTests;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, fpcunit, testregistry, TimerLogic;

type

  TTimerLogicTests = class(TTestCase)
  private
    procedure CheckParts(const AExpected, AActual: TTimeParts);
  published
    procedure ParseTimeField_ParsesDigits;
    procedure ParseTimeField_InvalidTextIsZero;
    procedure ParseTimeField_ClampsToMax;
    procedure FormatTimeField_PadsToTwoDigits;
    procedure StepTimeField_WrapsAround;
    procedure IsValidTimeFieldText_AcceptsOnlyTwoDigitsInRange;
    procedure ApplyKeyToText_InsertsAtCaret;
    procedure ApplyKeyToText_ReplacesSelection;
    procedure ApplyKeyToText_Backspace;
    procedure ApplyKeyToText_IgnoresOtherControlKeys;
    procedure SecondsConversion_RoundTrips;
    procedure SecondsToTimeParts_NegativeIsZero;
    procedure MSecsUntilClockTime_LaterToday;
    procedure MSecsUntilClockTime_EarlierMeansTomorrow;
    procedure MSecsUntilClockTime_NowMeansTomorrow;
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

procedure TTimerLogicTests.ParseTimeField_ParsesDigits;
begin
  AssertEquals(7, ParseTimeField('07', MaxHour));
  AssertEquals(23, ParseTimeField('23', MaxHour));
  AssertEquals(5, ParseTimeField(' 5 ', MaxMinute));
end;

procedure TTimerLogicTests.ParseTimeField_InvalidTextIsZero;
begin
  AssertEquals(0, ParseTimeField('', MaxHour));
  AssertEquals(0, ParseTimeField('ab', MaxHour));
  AssertEquals(0, ParseTimeField('-5', MaxHour));
  AssertEquals(0, ParseTimeField('1.5', MaxHour));
  AssertEquals(0, ParseTimeField('99999999999999', MaxHour));
end;

procedure TTimerLogicTests.ParseTimeField_ClampsToMax;
begin
  AssertEquals(23, ParseTimeField('24', MaxHour));
  AssertEquals(59, ParseTimeField('99', MaxSecond));
end;

procedure TTimerLogicTests.FormatTimeField_PadsToTwoDigits;
begin
  AssertEquals('00', FormatTimeField(0));
  AssertEquals('05', FormatTimeField(5));
  AssertEquals('23', FormatTimeField(23));
end;

procedure TTimerLogicTests.StepTimeField_WrapsAround;
begin
  AssertEquals(6, StepTimeField(5, 1, MaxHour));
  AssertEquals(0, StepTimeField(23, 1, MaxHour));
  AssertEquals(23, StepTimeField(0, -1, MaxHour));
  AssertEquals(59, StepTimeField(0, -1, MaxMinute));
  AssertEquals(0, StepTimeField(59, 1, MaxSecond));
end;

procedure TTimerLogicTests.IsValidTimeFieldText_AcceptsOnlyTwoDigitsInRange;
begin
  AssertTrue(IsValidTimeFieldText('', MaxHour));
  AssertTrue(IsValidTimeFieldText('2', MaxHour));
  AssertTrue(IsValidTimeFieldText('23', MaxHour));
  AssertTrue(IsValidTimeFieldText('59', MaxMinute));
  AssertFalse(IsValidTimeFieldText('24', MaxHour));
  AssertFalse(IsValidTimeFieldText('60', MaxMinute));
  AssertFalse(IsValidTimeFieldText('123', MaxMinute));
  AssertFalse(IsValidTimeFieldText('1a', MaxMinute));
  AssertFalse(IsValidTimeFieldText('-1', MaxMinute));
end;

procedure TTimerLogicTests.ApplyKeyToText_InsertsAtCaret;
begin
  AssertEquals('12', ApplyKeyToText('1', 1, 0, '2'));
  AssertEquals('21', ApplyKeyToText('1', 0, 0, '2'));
end;

procedure TTimerLogicTests.ApplyKeyToText_ReplacesSelection;
begin
  AssertEquals('3', ApplyKeyToText('12', 0, 2, '3'));
  AssertEquals('13', ApplyKeyToText('12', 1, 1, '3'));
end;

procedure TTimerLogicTests.ApplyKeyToText_Backspace;
begin
  AssertEquals('1', ApplyKeyToText('12', 2, 0, #8));
  AssertEquals('12', ApplyKeyToText('12', 0, 0, #8));
  AssertEquals('', ApplyKeyToText('12', 0, 2, #8));
end;

procedure TTimerLogicTests.ApplyKeyToText_IgnoresOtherControlKeys;
begin
  AssertEquals('12', ApplyKeyToText('12', 1, 0, #3));
  AssertEquals('12', ApplyKeyToText('12', 1, 0, #13));
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
