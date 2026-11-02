unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, LCLType, TimerLogic, PowerActions;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnAbout: TButton;
    btnCountdown: TSpeedButton;
    btnDelayMinus: TButton;
    btnDelayPlus: TButton;
    btnOptions: TButton;
    btnSetTime: TSpeedButton;
    btnStart: TButton;
    cbAction: TComboBox;
    cbDefaultAction: TComboBox;
    cbMinimizeToTray: TCheckBox;
    cbRememberWinPos: TCheckBox;
    cbWarnZeroTime: TCheckBox;
    edtDefaultDelay: TEdit;
    edtHour: TEdit;
    edtMinute: TEdit;
    edtSecond: TEdit;
    gbOptions: TGroupBox;
    lblDefaultAction: TLabel;
    lblDefaultDelay: TLabel;
    tmrCountdown: TTimer;
    procedure btnStartClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ModeButtonClick(Sender: TObject);
    procedure TimeFieldExit(Sender: TObject);
    procedure TimeFieldKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimeFieldKeyPress(Sender: TObject; var Key: Char);
    procedure tmrCountdownTimer(Sender: TObject);
  private
    FClockMode: Boolean;
    FDelayHours: Integer;
    FRunning: Boolean;
    FDeadline: QWord;
    FEnteredTime: TTimeParts;
    function FieldMax(AEdit: TEdit): Integer;
    function ReadTimeFields: TTimeParts;
    procedure WriteTimeFields(const AParts: TTimeParts);
    procedure ResetTimeFields;
    function SelectedAction: TPowerAction;
    procedure SetInputsEnabled(AEnabled: Boolean);
    procedure StartCountdown;
    procedure StopCountdown;
    procedure ShowRemaining(ASeconds: Integer);
    procedure RunAction(AAction: TPowerAction);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  AppTitle = 'Power Timer';

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDelayHours := MinDelayHours;
  FClockMode := btnSetTime.Down;
  ResetTimeFields;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FRunning then
    CanClose := MessageDlg('Confirm',
      'If you close this application the selected action will not be performed.'
      + LineEnding + 'Are you sure you want to continue?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmMain.FieldMax(AEdit: TEdit): Integer;
begin
  if AEdit = edtHour then
    Result := MaxHour
  else
    Result := MaxMinute;
end;

function TfrmMain.ReadTimeFields: TTimeParts;
begin
  Result := MakeTimeParts(
    ParseTimeField(edtHour.Text, MaxHour),
    ParseTimeField(edtMinute.Text, MaxMinute),
    ParseTimeField(edtSecond.Text, MaxSecond));
end;

procedure TfrmMain.WriteTimeFields(const AParts: TTimeParts);
begin
  edtHour.Text := FormatTimeField(AParts.Hours);
  edtMinute.Text := FormatTimeField(AParts.Minutes);
  edtSecond.Text := FormatTimeField(AParts.Seconds);
end;

procedure TfrmMain.ResetTimeFields;
begin
  if FClockMode then
    WriteTimeFields(DefaultClockTime(Now, FDelayHours))
  else
    WriteTimeFields(DefaultCountdown(FDelayHours));
end;

function TfrmMain.SelectedAction: TPowerAction;
begin
  Result := PowerActionFromIndex(cbAction.ItemIndex);
end;

procedure TfrmMain.ModeButtonClick(Sender: TObject);
begin
  if FClockMode = btnSetTime.Down then
    Exit;
  FClockMode := btnSetTime.Down;
  ResetTimeFields;
end;

procedure TfrmMain.TimeFieldExit(Sender: TObject);
var
  Edit: TEdit;
begin
  Edit := Sender as TEdit;
  Edit.Text := FormatTimeField(ParseTimeField(Edit.Text, FieldMax(Edit)));
end;

procedure TfrmMain.TimeFieldKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Edit: TEdit;
  Delta: Integer;
begin
  case Key of
    VK_UP: Delta := 1;
    VK_DOWN: Delta := -1;
  else
    Exit;
  end;
  Edit := Sender as TEdit;
  Edit.Text := FormatTimeField(StepTimeField(
    ParseTimeField(Edit.Text, FieldMax(Edit)), Delta, FieldMax(Edit)));
  Edit.SelectAll;
  Key := 0;
end;

procedure TfrmMain.TimeFieldKeyPress(Sender: TObject; var Key: Char);
var
  Edit: TEdit;
begin
  Edit := Sender as TEdit;
  if Key in ['0'..'9'] then
  begin
    if not IsValidTimeFieldText(
      ApplyKeyToText(Edit.Text, Edit.SelStart, Edit.SelLength, Key),
      FieldMax(Edit)) then
      Key := #0;
  end
  else if Key >= ' ' then
    Key := #0; // only digits; backspace and Ctrl shortcuts pass through
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if FRunning then
    StopCountdown
  else
    StartCountdown;
end;

procedure TfrmMain.SetInputsEnabled(AEnabled: Boolean);
begin
  btnCountdown.Enabled := AEnabled;
  btnSetTime.Enabled := AEnabled;
  edtHour.Enabled := AEnabled;
  edtMinute.Enabled := AEnabled;
  edtSecond.Enabled := AEnabled;
  cbAction.Enabled := AEnabled;
  btnOptions.Enabled := AEnabled;
end;

procedure TfrmMain.StartCountdown;
var
  Entered: TTimeParts;
  DelayMs: Int64;
begin
  Entered := ReadTimeFields;
  WriteTimeFields(Entered);

  if FClockMode then
    DelayMs := MSecsUntilClockTime(Now, Entered)
  else
    DelayMs := Int64(TimePartsToSeconds(Entered)) * MSecsPerSecond;

  if DelayMs <= 0 then
  begin
    if cbWarnZeroTime.Checked and (MessageDlg('Confirm',
      'No time entered, the selected action will be performed immediately.'
      + LineEnding + 'Continue?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
      Exit;
    RunAction(SelectedAction);
    Exit;
  end;

  FEnteredTime := Entered;
  FDeadline := GetTickCount64 + QWord(DelayMs);
  FRunning := True;
  SetInputsEnabled(False);
  btnStart.Caption := 'STOP';
  ShowRemaining(RemainingSeconds(GetTickCount64, FDeadline));
  tmrCountdown.Enabled := True;
end;

procedure TfrmMain.StopCountdown;
begin
  tmrCountdown.Enabled := False;
  FRunning := False;
  // Show what was entered again, not the remaining time: in "Set time"
  // mode the remaining time would otherwise be read as a clock time.
  WriteTimeFields(FEnteredTime);
  SetInputsEnabled(True);
  btnStart.Caption := 'START';
end;

procedure TfrmMain.ShowRemaining(ASeconds: Integer);
begin
  WriteTimeFields(SecondsToTimeParts(ASeconds));
end;

procedure TfrmMain.tmrCountdownTimer(Sender: TObject);
var
  Remaining: Integer;
begin
  if not FRunning then
    Exit;
  Remaining := RemainingSeconds(GetTickCount64, FDeadline);
  ShowRemaining(Remaining);
  if Remaining = 0 then
  begin
    StopCountdown;
    RunAction(SelectedAction);
  end;
end;

procedure TfrmMain.RunAction(AAction: TPowerAction);
var
  Error: string;
begin
  if not ExecutePowerAction(AAction, Error) then
    MessageDlg(AppTitle, Error, mtError, [mbOK], 0);
end;

end.
