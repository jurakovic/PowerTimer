unit TimeFieldsTests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, TimerLogic, TimeFields;

type

  TTimeFieldsTests = class(TTestCase)
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
  end;

implementation

procedure TTimeFieldsTests.ParseTimeField_ParsesDigits;
begin
  AssertEquals(7, ParseTimeField('07', MaxHour));
  AssertEquals(23, ParseTimeField('23', MaxHour));
  AssertEquals(5, ParseTimeField(' 5 ', MaxMinute));
end;

procedure TTimeFieldsTests.ParseTimeField_InvalidTextIsZero;
begin
  AssertEquals(0, ParseTimeField('', MaxHour));
  AssertEquals(0, ParseTimeField('ab', MaxHour));
  AssertEquals(0, ParseTimeField('-5', MaxHour));
  AssertEquals(0, ParseTimeField('1.5', MaxHour));
  AssertEquals(0, ParseTimeField('99999999999999', MaxHour));
end;

procedure TTimeFieldsTests.ParseTimeField_ClampsToMax;
begin
  AssertEquals(23, ParseTimeField('24', MaxHour));
  AssertEquals(59, ParseTimeField('99', MaxSecond));
end;

procedure TTimeFieldsTests.FormatTimeField_PadsToTwoDigits;
begin
  AssertEquals('00', FormatTimeField(0));
  AssertEquals('05', FormatTimeField(5));
  AssertEquals('23', FormatTimeField(23));
end;

procedure TTimeFieldsTests.StepTimeField_WrapsAround;
begin
  AssertEquals(6, StepTimeField(5, 1, MaxHour));
  AssertEquals(0, StepTimeField(23, 1, MaxHour));
  AssertEquals(23, StepTimeField(0, -1, MaxHour));
  AssertEquals(59, StepTimeField(0, -1, MaxMinute));
  AssertEquals(0, StepTimeField(59, 1, MaxSecond));
end;

procedure TTimeFieldsTests.IsValidTimeFieldText_AcceptsOnlyTwoDigitsInRange;
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

procedure TTimeFieldsTests.ApplyKeyToText_InsertsAtCaret;
begin
  AssertEquals('12', ApplyKeyToText('1', 1, 0, '2'));
  AssertEquals('21', ApplyKeyToText('1', 0, 0, '2'));
end;

procedure TTimeFieldsTests.ApplyKeyToText_ReplacesSelection;
begin
  AssertEquals('3', ApplyKeyToText('12', 0, 2, '3'));
  AssertEquals('13', ApplyKeyToText('12', 1, 1, '3'));
end;

procedure TTimeFieldsTests.ApplyKeyToText_Backspace;
begin
  AssertEquals('1', ApplyKeyToText('12', 2, 0, #8));
  AssertEquals('12', ApplyKeyToText('12', 0, 0, #8));
  AssertEquals('', ApplyKeyToText('12', 0, 2, #8));
end;

procedure TTimeFieldsTests.ApplyKeyToText_IgnoresOtherControlKeys;
begin
  AssertEquals('12', ApplyKeyToText('12', 1, 0, #3));
  AssertEquals('12', ApplyKeyToText('12', 1, 0, #13));
end;

initialization
  RegisterTest(TTimeFieldsTests);

end.
