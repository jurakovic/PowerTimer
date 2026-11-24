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

const
  { The main form ticks every 250 ms while the computer is awake. A longer
    gap than this between two ticks means the ticks couldn't run: the
    computer was asleep or hibernating. The tick count goes on meanwhile. }
  SleepGapMs = 10000;
  { When the end passed during such a gap, the action runs this many
    seconds after waking instead, and is announced first. }
  WakeGraceSeconds = 60;

type
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
    FWarnSeconds: Integer;
    FWarned: Boolean; // OnWarn was fired, or won't be, until the end
    FLastTicks: QWord; // of Start or the last Tick
    FEndedDuringSleep: Boolean;
    FOnChange: TNotifyEvent;
    FOnRunAction: TPowerActionEvent;
    FOnWarn: TNotifyEvent;
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
      fires OnChange and then OnRunAction with the action. Before that it
      fires OnWarn once, when at most WarnSeconds are left.
      When the time ran out during a gap of more than SleepGapMs since the
      last tick, the computer slept through the end, and the action doesn't
      run on waking: the end moves to WakeGraceSeconds from now,
      EndedDuringSleep is set and OnWarn fires, whatever WarnSeconds is.
      The gap is in ticks, so a clock set forward past the target in
      ClockTime mode still runs the action at once. }
    procedure Tick(ANow: TDateTime; ATicks: QWord);
    { Stops without running the action. }
    procedure Stop;
    { Moves the end ASeconds later and warns again before the new end.
      Entered stays, so a stop still shows the time that was entered. Clears
      EndedDuringSleep. Does nothing when not running. }
    procedure Postpone(ASeconds: Integer);
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
    { How many seconds before the end OnWarn fires, 0 for never. Set it
      before Start: a countdown that isn't longer than that doesn't warn,
      since whoever started it knows when it ends. }
    property WarnSeconds: Integer read FWarnSeconds write FWarnSeconds;
    { The end passed while the computer was asleep, and the action now runs
      WakeGraceSeconds after waking, see Tick. False after Start and
      Postpone. }
    property EndedDuringSleep: Boolean read FEndedDuringSleep;
    { Fired whenever the countdown starts or stops, also when it ends. }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    { Fired when the countdown ends, after OnChange. }
    property OnRunAction: TPowerActionEvent read FOnRunAction write FOnRunAction;
    { Fired once while running, when at most WarnSeconds are left, and
      again after Postpone. Also fired on waking when the end passed while
      the computer was asleep, then with EndedDuringSleep set. }
    property OnWarn: TNotifyEvent read FOnWarn write FOnWarn;
  end;

implementation

uses
  DateUtils;

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
  FLastTicks := ATicks;
  FEndedDuringSleep := False;
  FWarned := (FWarnSeconds <= 0)
    or (RemainingSeconds(ANow, ATicks) <= FWarnSeconds);
  Result := True;
  DoChange;
end;

procedure TCountdown.Tick(ANow: TDateTime; ATicks: QWord);
var
  Seconds: Integer;
  Slept: Boolean;
begin
  if not FRunning then
    Exit;
  Slept := (ATicks > FLastTicks) and (ATicks - FLastTicks > SleepGapMs);
  FLastTicks := ATicks;
  if Slept and (RemainingSeconds(ANow, ATicks) = 0) then
  begin
    // Running the action now would give no notice, so it is announced for
    // a while instead
    if FMode = cmClockTime then
      FTarget := IncSecond(ANow, WakeGraceSeconds)
    else
    begin
      FDeadline := ATicks + QWord(WakeGraceSeconds * MSecsPerSecond);
      FEndTime := ANow + WakeGraceSeconds / SecondsPerDay;
    end;
    FEndedDuringSleep := True;
    FWarned := True;
    if Assigned(FOnWarn) then
      FOnWarn(Self);
    Exit;
  end;
  FEndTime := EndTime(ANow, ATicks);
  Seconds := RemainingSeconds(ANow, ATicks);
  if Seconds > 0 then
  begin
    if not FWarned and (Seconds <= FWarnSeconds) then
    begin
      FWarned := True;
      if Assigned(FOnWarn) then
        FOnWarn(Self);
    end;
    Exit;
  end;
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

procedure TCountdown.Postpone(ASeconds: Integer);
begin
  if not FRunning then
    Exit;
  if FMode = cmClockTime then
    FTarget := IncSecond(FTarget, ASeconds)
  else
  begin
    FDeadline := FDeadline + QWord(Int64(ASeconds) * MSecsPerSecond);
    FEndTime := FEndTime + ASeconds / SecondsPerDay;
  end;
  FWarned := False;
  FEndedDuringSleep := False;
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
