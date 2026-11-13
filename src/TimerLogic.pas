unit TimerLogic;

{ Pure time calculations: the time arithmetic, the default delay and the
  texts of the status bar. The input rules of the time fields are in
  TimeFields. Has no UI or OS dependencies so it can be unit tested on any
  platform. }

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

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

  // The most the two-digit time fields can show: 99:59:59
  MaxFieldSeconds = 99 * SecondsPerHour + 59 * SecondsPerMinute + 59;

type
  TTimeParts = record
    Hours: Integer;
    Minutes: Integer;
    Seconds: Integer;
  end;

  { What the status bar describes: the countdown that Start would begin in
    Countdown mode or in At time mode, or the one that is running. }
  TStatusKind = (skCountdownIdle, skClockIdle, skRunning);

function MakeTimeParts(AHours, AMinutes, ASeconds: Integer): TTimeParts;

function TimePartsToSeconds(const AParts: TTimeParts): Integer;

{ Splits a duration into hours, minutes and seconds. Negative durations
  are treated as zero. The hours are not limited to 23: a whole day gives
  24:00:00. }
function SecondsToTimeParts(ATotalSeconds: Integer): TTimeParts;

{ SecondsToTimeParts for the time fields: at most 99:59:59, the most two
  digits per field can show, also when more time is left. }
function SecondsToFieldParts(ATotalSeconds: Integer): TTimeParts;

{ The next occurrence of the wall clock time AClock after ANow, as a local
  date and time: today at AClock, or tomorrow at AClock when that is not at
  least 1 ms in the future. }
function NextOccurrence(ANow: TDateTime; const AClock: TTimeParts): TDateTime;

{ Milliseconds from ANow until the next occurrence of the wall clock time
  AClock. A time that is not in the future today means the same time
  tomorrow, so the result is always in 1..MSecsPerDay. }
function MSecsUntilClockTime(ANow: TDateTime; const AClock: TTimeParts): Int64;

{ Whole seconds from ANow until ATarget, both local times, rounded up as
  RemainingSeconds does; 0 when ATarget is not in the future. }
function SecondsUntil(ANow, ATarget: TDateTime): Integer;

{ Whole seconds left until ADeadline (both in milliseconds, e.g. from
  GetTickCount64), rounded up so 00:00:00 is only shown when it is time. }
function RemainingSeconds(ANowTicks, ADeadlineTicks: QWord): Integer;

function ClampDelayHours(AValue: Integer): Integer;

{ The default delay with its unit, e.g. '1 h'. }
function FormatDelayHours(AHours: Integer): string;

{ Initial countdown for the configured delay. The hour field only goes up
  to 23, so a 24 hour delay is shown as 23:59:59. }
function DefaultCountdown(ADelayHours: Integer): TTimeParts;

{ Initial clock time: the current time moved forward by the delay. }
function DefaultClockTime(ANow: TDateTime; ADelayHours: Integer): TTimeParts;

{ Human readable duration, e.g. '01 h 05 m 00 s'. }
function FormatRemaining(ATotalSeconds: Integer): string;

{ A duration as hours, minutes and seconds, e.g. '01:12:30'. Negative
  durations are treated as zero, and the hours can go over 23
  ('24:00:00'). }
function FormatDuration(ATotalSeconds: Integer): string;

{ When AEnd is, seen from ANow, in the time format of AFormat: 'at 23:45',
  'tomorrow at 01:00' on the next day, or 'on <short date> at 01:00' on a
  later day. The time is the short time format, or the long one, with
  seconds, when AShowSeconds is True. }
function FormatEndTime(ANow, AEnd: TDateTime; AShowSeconds: Boolean;
  const AFormat: TFormatSettings): string;

{ The text of the status bar: when AActionName runs, at AEnd, and in how
  many seconds (ASeconds), e.g.
    skCountdownIdle: 'Shutdown at 23:45 if started now · in 01:00:00', or
      'Shutdown right away if started now' when ASeconds is 0
    skClockIdle: 'Shutdown tomorrow at 14:00 · in 23:30:00'
    skRunning: 'Shutdown at 23:45 · 00:42:17 left'
  AShowSeconds and AFormat are passed on to FormatEndTime. }
function CountdownStatus(AKind: TStatusKind; const AActionName: string;
  ANow, AEnd: TDateTime; ASeconds: Integer; AShowSeconds: Boolean;
  const AFormat: TFormatSettings): string;

implementation

uses
  DateUtils;

const
  // UTF-8 encoded U+00B7, between the end time and the duration
  MiddleDot = #$C2#$B7;

resourcestring
  // Hours, minutes, seconds
  rsRemainingFormat = '%.2d h %.2d m %.2d s';
  // Hours
  rsDelayHoursFormat = '%d h';
  // Time
  rsEndToday = 'at %s';
  // Time
  rsEndTomorrow = 'tomorrow at %s';
  // Short date, time
  rsEndLater = 'on %s at %s';
  // Action, end (see rsEndToday), duration
  rsStatusCountdownIdle = '%s %s if started now ' + MiddleDot + ' in %s';
  // Action
  rsStatusCountdownNow = '%s right away if started now';
  // Action, end (see rsEndToday), duration
  rsStatusClockIdle = '%s %s ' + MiddleDot + ' in %s';
  // Action, end (see rsEndToday), time left
  rsStatusRunning = '%s %s ' + MiddleDot + ' %s left';

function Clamp(AValue, AMin, AMax: Integer): Integer;
begin
  if AValue < AMin then
    Result := AMin
  else if AValue > AMax then
    Result := AMax
  else
    Result := AValue;
end;

function MakeTimeParts(AHours, AMinutes, ASeconds: Integer): TTimeParts;
begin
  Result.Hours := AHours;
  Result.Minutes := AMinutes;
  Result.Seconds := ASeconds;
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

function SecondsToFieldParts(ATotalSeconds: Integer): TTimeParts;
begin
  Result := SecondsToTimeParts(Clamp(ATotalSeconds, 0, MaxFieldSeconds));
end;

function NextOccurrence(ANow: TDateTime; const AClock: TTimeParts): TDateTime;
begin
  Result := DateOf(ANow) + EncodeTime(
    Clamp(AClock.Hours, 0, MaxHour),
    Clamp(AClock.Minutes, 0, MaxMinute),
    Clamp(AClock.Seconds, 0, MaxSecond), 0);
  if Round((Result - ANow) * MSecsPerDay) <= 0 then
    Result := IncDay(Result);
end;

function MSecsUntilClockTime(ANow: TDateTime; const AClock: TTimeParts): Int64;
begin
  Result := Round((NextOccurrence(ANow, AClock) - ANow) * MSecsPerDay);
end;

function SecondsUntil(ANow, ATarget: TDateTime): Integer;
var
  MSecs: Int64;
begin
  MSecs := Round((ATarget - ANow) * MSecsPerDay);
  if MSecs <= 0 then
    Exit(0);
  Result := (MSecs + MSecsPerSecond - 1) div MSecsPerSecond;
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

function FormatDelayHours(AHours: Integer): string;
begin
  Result := Format(rsDelayHoursFormat, [AHours]);
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
  Result := Format(rsRemainingFormat, [P.Hours, P.Minutes, P.Seconds]);
end;

function FormatDuration(ATotalSeconds: Integer): string;
var
  P: TTimeParts;
begin
  P := SecondsToTimeParts(ATotalSeconds);
  Result := Format('%.2d:%.2d:%.2d', [P.Hours, P.Minutes, P.Seconds]);
end;

function FormatEndTime(ANow, AEnd: TDateTime; AShowSeconds: Boolean;
  const AFormat: TFormatSettings): string;
var
  Time: string;
  Days: Integer;
begin
  if AShowSeconds then
    Time := FormatDateTime('tt', AEnd, AFormat)
  else
    Time := FormatDateTime('t', AEnd, AFormat);
  Days := Trunc(DateOf(AEnd)) - Trunc(DateOf(ANow));
  if Days <= 0 then
    Result := Format(rsEndToday, [Time])
  else if Days = 1 then
    Result := Format(rsEndTomorrow, [Time])
  else
    Result := Format(rsEndLater, [FormatDateTime('ddddd', AEnd, AFormat), Time]);
end;

function CountdownStatus(AKind: TStatusKind; const AActionName: string;
  ANow, AEnd: TDateTime; ASeconds: Integer; AShowSeconds: Boolean;
  const AFormat: TFormatSettings): string;
var
  EndText: string;
begin
  if (AKind = skCountdownIdle) and (ASeconds <= 0) then
    Exit(Format(rsStatusCountdownNow, [AActionName]));
  EndText := FormatEndTime(ANow, AEnd, AShowSeconds, AFormat);
  case AKind of
    skCountdownIdle:
      Result := Format(rsStatusCountdownIdle,
        [AActionName, EndText, FormatDuration(ASeconds)]);
    skClockIdle:
      Result := Format(rsStatusClockIdle,
        [AActionName, EndText, FormatDuration(ASeconds)]);
  else
    Result := Format(rsStatusRunning,
      [AActionName, EndText, FormatDuration(ASeconds)]);
  end;
end;

end.
