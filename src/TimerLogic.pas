unit TimerLogic;

{ Pure time calculations used by the main form. Has no UI or OS
  dependencies so it can be unit tested on any platform. }

{$mode objfpc}{$H+}

interface

const
  MaxHour = 23;
  MaxMinute = 59;
  MaxSecond = 59;

  MinDelayHours = 1;
  MaxDelayHours = 24;

  MSecsPerSecond = 1000;
  SecondsPerMinute = 60;
  SecondsPerHour = 60 * SecondsPerMinute;
  SecondsPerDay = 24 * SecondsPerHour;
  MSecsPerDay = Int64(SecondsPerDay) * MSecsPerSecond;

type
  TTimeParts = record
    Hours: Integer;
    Minutes: Integer;
    Seconds: Integer;
  end;

function MakeTimeParts(AHours, AMinutes, ASeconds: Integer): TTimeParts;

{ Parses the text of a time field. Empty or non-numeric text gives 0 and
  the result is clamped to 0..AMax. }
function ParseTimeField(const AText: string; AMax: Integer): Integer;

{ Two digit representation of a time field value, e.g. 5 -> '05'. }
function FormatTimeField(AValue: Integer): string;

{ Adds ADelta to AValue, wrapping around within 0..AMax
  (used by the up/down arrow keys). }
function StepTimeField(AValue, ADelta, AMax: Integer): Integer;

{ True when ACandidate may be shown in a time field while the user is
  typing: empty, or at most two digits with a value not above AMax. }
function IsValidTimeFieldText(const ACandidate: string; AMax: Integer): Boolean;

{ Text that results from pressing AKey in an edit containing AText with
  the given selection (ASelStart is 0-based). Handles backspace and
  printable characters; other control characters leave the text as is. }
function ApplyKeyToText(const AText: string; ASelStart, ASelLength: Integer;
  AKey: Char): string;

function TimePartsToSeconds(const AParts: TTimeParts): Integer;

{ Splits a duration into hours, minutes and seconds. Negative durations
  are treated as zero. }
function SecondsToTimeParts(ATotalSeconds: Integer): TTimeParts;

{ Milliseconds from ANow until the next occurrence of the wall clock time
  AClock. A time that is not in the future today means the same time
  tomorrow, so the result is always in 1..MSecsPerDay. }
function MSecsUntilClockTime(ANow: TDateTime; const AClock: TTimeParts): Int64;

{ Whole seconds left until ADeadline (both in milliseconds, e.g. from
  GetTickCount64), rounded up so 00:00:00 is only shown when it is time. }
function RemainingSeconds(ANowTicks, ADeadlineTicks: QWord): Integer;

function ClampDelayHours(AValue: Integer): Integer;

{ Initial countdown for the configured delay. The hour field only goes up
  to 23, so a 24 hour delay is shown as 23:59:59. }
function DefaultCountdown(ADelayHours: Integer): TTimeParts;

{ Initial clock time: the current time moved forward by the delay. }
function DefaultClockTime(ANow: TDateTime; ADelayHours: Integer): TTimeParts;

{ Human readable duration, e.g. '01 h 05 m 00 s'. }
function FormatRemaining(ATotalSeconds: Integer): string;

implementation

uses
  SysUtils, DateUtils;

function Clamp(AValue, AMin, AMax: Integer): Integer;
begin
  if AValue < AMin then
    Result := AMin
  else if AValue > AMax then
    Result := AMax
  else
    Result := AValue;
end;

function IsDigits(const AText: string): Boolean;
var
  C: Char;
begin
  for C in AText do
    if not (C in ['0'..'9']) then
      Exit(False);
  Result := True;
end;

function MakeTimeParts(AHours, AMinutes, ASeconds: Integer): TTimeParts;
begin
  Result.Hours := AHours;
  Result.Minutes := AMinutes;
  Result.Seconds := ASeconds;
end;

function ParseTimeField(const AText: string; AMax: Integer): Integer;
var
  S: string;
begin
  S := Trim(AText);
  if (S = '') or (Length(S) > 9) or not IsDigits(S) then
    Exit(0);
  Result := Clamp(StrToInt(S), 0, AMax);
end;

function FormatTimeField(AValue: Integer): string;
begin
  Result := Format('%.2d', [AValue]);
end;

function StepTimeField(AValue, ADelta, AMax: Integer): Integer;
var
  Range: Integer;
begin
  Range := AMax + 1;
  Result := (Clamp(AValue, 0, AMax) + ADelta) mod Range;
  if Result < 0 then
    Inc(Result, Range);
end;

function IsValidTimeFieldText(const ACandidate: string; AMax: Integer): Boolean;
begin
  if ACandidate = '' then
    Exit(True);
  Result := (Length(ACandidate) <= 2) and IsDigits(ACandidate)
    and (StrToInt(ACandidate) <= AMax);
end;

function ApplyKeyToText(const AText: string; ASelStart, ASelLength: Integer;
  AKey: Char): string;
var
  Start, Len: Integer;
begin
  Start := Clamp(ASelStart, 0, Length(AText));
  Len := Clamp(ASelLength, 0, Length(AText) - Start);
  Result := AText;

  if AKey = #8 then
  begin
    if Len > 0 then
      Delete(Result, Start + 1, Len)
    else if Start > 0 then
      Delete(Result, Start, 1);
  end
  else if AKey >= ' ' then
  begin
    Delete(Result, Start + 1, Len);
    Insert(AKey, Result, Start + 1);
  end;
end;

function TimePartsToSeconds(const AParts: TTimeParts): Integer;
begin
  Result := AParts.Hours * SecondsPerHour + AParts.Minutes * SecondsPerMinute
    + AParts.Seconds;
end;

function SecondsToTimeParts(ATotalSeconds: Integer): TTimeParts;
begin
  if ATotalSeconds < 0 then
    ATotalSeconds := 0;
  Result.Hours := ATotalSeconds div SecondsPerHour;
  Result.Minutes := (ATotalSeconds div SecondsPerMinute) mod 60;
  Result.Seconds := ATotalSeconds mod 60;
end;

function MSecsUntilClockTime(ANow: TDateTime; const AClock: TTimeParts): Int64;
var
  Target: TDateTime;
begin
  Target := DateOf(ANow) + EncodeTime(
    Clamp(AClock.Hours, 0, MaxHour),
    Clamp(AClock.Minutes, 0, MaxMinute),
    Clamp(AClock.Seconds, 0, MaxSecond), 0);
  Result := Round((Target - ANow) * MSecsPerDay);
  if Result <= 0 then
    Inc(Result, MSecsPerDay);
end;

function RemainingSeconds(ANowTicks, ADeadlineTicks: QWord): Integer;
begin
  if ANowTicks >= ADeadlineTicks then
    Exit(0);
  Result := (ADeadlineTicks - ANowTicks + MSecsPerSecond - 1) div MSecsPerSecond;
end;

function ClampDelayHours(AValue: Integer): Integer;
begin
  Result := Clamp(AValue, MinDelayHours, MaxDelayHours);
end;

function DefaultCountdown(ADelayHours: Integer): TTimeParts;
begin
  ADelayHours := ClampDelayHours(ADelayHours);
  if ADelayHours > MaxHour then
    Result := MakeTimeParts(MaxHour, MaxMinute, MaxSecond)
  else
    Result := MakeTimeParts(ADelayHours, 0, 0);
end;

function DefaultClockTime(ANow: TDateTime; ADelayHours: Integer): TTimeParts;
var
  H, M, S, MS: Word;
begin
  DecodeTime(IncHour(ANow, ClampDelayHours(ADelayHours)), H, M, S, MS);
  Result := MakeTimeParts(H, M, S);
end;

function FormatRemaining(ATotalSeconds: Integer): string;
var
  P: TTimeParts;
begin
  P := SecondsToTimeParts(ATotalSeconds);
  Result := Format('%.2d h %.2d m %.2d s', [P.Hours, P.Minutes, P.Seconds]);
end;

end.
