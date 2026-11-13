unit Countdown;

{ The countdown of the main form: when the action runs. The time and the
  tick count are passed in, and the action runs through an event, so the
  countdown has no UI or OS dependencies and can be unit tested. }

{$mode objfpc}{$H+}

interface

uses
  Classes, TimerLogic, PowerActions;

type
  { Countdown waits for the entered duration, counting the ticks, so a
    change of the clock doesn't change it. ClockTime waits until the clock
    shows the entered time: it keeps that as a local date and time and
    compares it with the time on every tick, so it follows a change of the
    clock, e.g. to or from daylight saving time. }
  TCountdownMode = (cmCountdown, cmClockTime);

  TPowerActionEvent = procedure(AAction: TPowerAction) of object;

  { TCountdown }

  TCountdown = class
  private
    FRunning: Boolean;
    FMode: TCountdownMode;
    FEntered: TTimeParts;
    FAction: TPowerAction;
    FDeadline: QWord; // Countdown mode, in ticks
    FTarget: TDateTime; // ClockTime mode, local time
    FEndTime: TDateTime; // Countdown mode, local time, see EndTime
    FOnChange: TNotifyEvent;
    FOnRunAction: TPowerActionEvent;
    procedure DoChange;
  public
    { Starts waiting for AEntered: a duration in Countdown mode, the next
      occurrence of that clock time in ClockTime mode. ANow is the local
      time and ATicks the tick count in milliseconds (GetTickCount64).
      Returns False and starts nothing when there is no time to wait, which
      is 00:00:00 in Countdown mode; the caller then decides whether to run
      the action itself. ClockTime mode always starts: a clock time always
      has a next occurrence. }
    function Start(AMode: TCountdownMode; const AEntered: TTimeParts;
      AAction: TPowerAction; ANow: TDateTime; ATicks: QWord): Boolean;
    { Called regularly while running. When the time is up it stops,
      fires OnChange and then OnRunAction with the action. }
    procedure Tick(ANow: TDateTime; ATicks: QWord);
    { Stops without running the action. }
    procedure Stop;
    { Whole seconds left, rounded up; 0 when not running. }
    function RemainingSeconds(ANow: TDateTime; ATicks: QWord): Integer;
    { When the action runs, as a local time. In ClockTime mode that is the
      target. In Countdown mode it is the end computed at Start, kept as
      long as the time and the tick count move on together, so it doesn't
      flicker when they drift by a millisecond; once ANow plus the time
      left differs from it by more than 2 seconds, e.g. after the clock was
      changed, it is that instead, and Tick keeps it from then on. }
    function EndTime(ANow: TDateTime; ATicks: QWord): TDateTime;
    property Running: Boolean read FRunning;
    property Mode: TCountdownMode read FMode;
    { The time as it was entered, e.g. to show it again after a stop. }
    property Entered: TTimeParts read FEntered;
    property Action: TPowerAction read FAction;
    { Fired whenever the countdown starts or stops, also when it ends. }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    { Fired when the countdown ends, after OnChange. }
    property OnRunAction: TPowerActionEvent read FOnRunAction write FOnRunAction;
  end;

implementation

const
  // How far the end of a countdown may drift before EndTime moves it
  EndTimeToleranceMs = 2 * MSecsPerSecond;

{ TCountdown }

procedure TCountdown.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TCountdown.Start(AMode: TCountdownMode; const AEntered: TTimeParts;
  AAction: TPowerAction; ANow: TDateTime; ATicks: QWord): Boolean;
var
  DelayMs: Int64;
begin
  if AMode = cmCountdown then
  begin
    DelayMs := Int64(TimePartsToSeconds(AEntered)) * MSecsPerSecond;
    if DelayMs <= 0 then
      Exit(False);
    FDeadline := ATicks + QWord(DelayMs);
    FEndTime := ANow + DelayMs / MSecsPerDay;
  end
  else
    FTarget := NextOccurrence(ANow, AEntered);

  FMode := AMode;
  FEntered := AEntered;
  FAction := AAction;
  FRunning := True;
  Result := True;
  DoChange;
end;

procedure TCountdown.Tick(ANow: TDateTime; ATicks: QWord);
begin
  if not FRunning then
    Exit;
  FEndTime := EndTime(ANow, ATicks);
  if RemainingSeconds(ANow, ATicks) > 0 then
    Exit;
  FRunning := False;
  DoChange;
  if Assigned(FOnRunAction) then
    FOnRunAction(FAction);
end;

procedure TCountdown.Stop;
begin
  if not FRunning then
    Exit;
  FRunning := False;
  DoChange;
end;

function TCountdown.RemainingSeconds(ANow: TDateTime; ATicks: QWord): Integer;
begin
  if not FRunning then
    Exit(0);
  if FMode = cmClockTime then
    Result := SecondsUntil(ANow, FTarget)
  else
    Result := TimerLogic.RemainingSeconds(ATicks, FDeadline);
end;

function TCountdown.EndTime(ANow: TDateTime; ATicks: QWord): TDateTime;
var
  LeftMs: QWord;
begin
  if FMode = cmClockTime then
    Exit(FTarget);
  if ATicks < FDeadline then
    LeftMs := FDeadline - ATicks
  else
    LeftMs := 0;
  Result := ANow + LeftMs / MSecsPerDay;
  if Abs(Result - FEndTime) * MSecsPerDay <= EndTimeToleranceMs then
    Result := FEndTime;
end;

end.
