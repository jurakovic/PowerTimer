unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, Menus, LCLType, TimerLogic, PowerActions, AppSettings;

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
    miClose: TMenuItem;
    miShow: TMenuItem;
    pmTray: TPopupMenu;
    pnlFocusHolder: TPanel;
    tmrCountdown: TTimer;
    trayIcon: TTrayIcon;
    procedure btnAboutClick(Sender: TObject);
    procedure btnDelayMinusClick(Sender: TObject);
    procedure btnDelayPlusClick(Sender: TObject);
    procedure btnOptionsClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure cbDefaultActionChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure miCloseClick(Sender: TObject);
    procedure miShowClick(Sender: TObject);
    procedure ModeButtonClick(Sender: TObject);
    procedure TimeFieldExit(Sender: TObject);
    procedure TimeFieldKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimeFieldKeyPress(Sender: TObject; var Key: Char);
    procedure tmrCountdownTimer(Sender: TObject);
    procedure trayIconClick(Sender: TObject);
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
    procedure SetDelayHours(AHours: Integer);
    procedure SetOptionsVisible(AVisible: Boolean);
    procedure ApplySettings(const ASettings: TAppSettings);
    procedure RestoreWindowPosition(const ASettings: TAppSettings);
    function CurrentSettings: TAppSettings;
    procedure SaveCurrentSettings;
    function SelectedAction: TPowerAction;
    procedure SetInputsEnabled(AEnabled: Boolean);
    procedure StartCountdown;
    procedure StopCountdown;
    procedure ShowRemaining(ASeconds: Integer);
    procedure RunAction(AAction: TPowerAction);
    procedure SetTrayHint(const AHint: string);
    procedure HideToTray;
    procedure RestoreFromTray;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  AppInfo, AboutForm, TimeFields;

{$R *.lfm}

resourcestring
  rsStart = 'START';
  rsStop = 'STOP';
  rsConfirm = 'Confirm';
  rsConfirmClose = 'If you close this application the selected action will not be performed.'
    + LineEnding + 'Are you sure you want to continue?';
  rsConfirmZeroTime = 'No time entered, the selected action will be performed immediately.'
    + LineEnding + 'Continue?';
  // Application title, action, remaining time
  rsTrayHintRunning = '%s - %s after %s';

const
  // UTF-8 encoded U+25BC / U+25B2 for the options toggle button
  ArrowDown = #$E2#$96#$BC;
  ArrowUp = #$E2#$96#$B2;

  // Space below the last visible control, in 96 DPI pixels
  BottomMargin = 6;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Settings: TAppSettings;
begin
  // The captions in the form file are only what the designer shows
  Caption := AppTitle;
  trayIcon.Hint := AppTitle;
  FClockMode := btnSetTime.Down;
  trayIcon.Icon.Assign(Application.Icon);
  // Without an active control the form would focus the hour field. The
  // empty, zero-size panel holds the focus instead, so nothing looks
  // selected until the user clicks a control or presses Tab; it is no tab
  // stop, so Tab goes on to the hour field.
  ActiveControl := pnlFocusHolder;
  // Filled from PowerActions so that ItemIndex always equals
  // Ord(TPowerAction).
  FillPowerActionList(cbAction.Items);
  FillPowerActionList(cbDefaultAction.Items);
  Settings := LoadSettings;
  ApplySettings(Settings);
  RestoreWindowPosition(Settings);
  SetOptionsVisible(False);
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveCurrentSettings;
end;

procedure TfrmMain.ApplySettings(const ASettings: TAppSettings);
begin
  cbRememberWinPos.Checked := ASettings.RememberWindowPos;
  cbWarnZeroTime.Checked := ASettings.WarnZeroTime;
  cbMinimizeToTray.Checked := ASettings.MinimizeToTray;
  cbDefaultAction.ItemIndex := Ord(ASettings.DefaultAction);
  cbAction.ItemIndex := Ord(ASettings.DefaultAction);
  SetDelayHours(ASettings.DefaultDelayHours);
end;

procedure TfrmMain.RestoreWindowPosition(const ASettings: TAppSettings);
var
  Bounds: TRect;
begin
  if not (ASettings.RememberWindowPos and ASettings.HasWindowPos) then
    Exit;
  // Only use the stored position if the window would be on a monitor,
  // e.g. not after a second monitor was disconnected.
  Bounds := Rect(ASettings.WindowLeft, ASettings.WindowTop,
    ASettings.WindowLeft + Width, ASettings.WindowTop + Height);
  if Screen.MonitorFromRect(Bounds, mdNull) = nil then
    Exit;
  Position := poDesigned;
  Left := ASettings.WindowLeft;
  Top := ASettings.WindowTop;
end;

function TfrmMain.CurrentSettings: TAppSettings;
begin
  Result := DefaultSettings;
  Result.RememberWindowPos := cbRememberWinPos.Checked;
  Result.WarnZeroTime := cbWarnZeroTime.Checked;
  Result.MinimizeToTray := cbMinimizeToTray.Checked;
  Result.DefaultAction := PowerActionFromIndex(cbDefaultAction.ItemIndex);
  Result.DefaultDelayHours := FDelayHours;
  // RestoredLeft/Top are the normal window bounds, also while the window
  // is minimized (where Left/Top would be off-screen).
  Result.HasWindowPos := True;
  Result.WindowLeft := RestoredLeft;
  Result.WindowTop := RestoredTop;
end;

procedure TfrmMain.SaveCurrentSettings;
begin
  SaveSettings(CurrentSettings);
end;

procedure TfrmMain.SetDelayHours(AHours: Integer);
begin
  FDelayHours := ClampDelayHours(AHours);
  edtDefaultDelay.Text := FormatTimeField(FDelayHours);
  ResetTimeFields;
end;

procedure TfrmMain.btnDelayPlusClick(Sender: TObject);
begin
  SetDelayHours(FDelayHours + 1);
end;

procedure TfrmMain.btnDelayMinusClick(Sender: TObject);
begin
  SetDelayHours(FDelayHours - 1);
end;

procedure TfrmMain.cbDefaultActionChange(Sender: TObject);
begin
  cbAction.ItemIndex := cbDefaultAction.ItemIndex;
end;

procedure TfrmMain.SetOptionsVisible(AVisible: Boolean);
var
  LastControl: TControl;
begin
  gbOptions.Visible := AVisible;
  if AVisible then
  begin
    btnOptions.Caption := ArrowUp;
    LastControl := gbOptions;
  end
  else
  begin
    btnOptions.Caption := ArrowDown;
    LastControl := btnOptions;
  end;
  // Computed from the (already DPI scaled) controls, so it fits on high-DPI
  // screens too.
  ClientHeight := LastControl.Top + LastControl.Height + Scale96ToForm(BottomMargin);
end;

procedure TfrmMain.btnOptionsClick(Sender: TObject);
begin
  SetOptionsVisible(not gbOptions.Visible);
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  ShowAbout(Self);
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FRunning then
    CanClose := MessageDlg(rsConfirm, rsConfirmClose,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmMain.FieldMax(AEdit: TEdit): Integer;
begin
  if AEdit = edtHour then
    Result := MaxHour
  else if AEdit = edtMinute then
    Result := MaxMinute
  else
    Result := MaxSecond;
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
    if cbWarnZeroTime.Checked and (MessageDlg(rsConfirm, rsConfirmZeroTime,
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
      Exit;
    RunAction(SelectedAction);
    Exit;
  end;

  SetOptionsVisible(False);
  FEnteredTime := Entered;
  FDeadline := GetTickCount64 + QWord(DelayMs);
  FRunning := True;
  SetInputsEnabled(False);
  btnStart.Caption := rsStop;
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
  btnStart.Caption := rsStart;
  SetTrayHint(AppTitle);
end;

procedure TfrmMain.ShowRemaining(ASeconds: Integer);
begin
  WriteTimeFields(SecondsToTimeParts(ASeconds));
  SetTrayHint(Format(rsTrayHintRunning, [AppTitle,
    PowerActionNames[SelectedAction], FormatRemaining(ASeconds)]));
end;

procedure TfrmMain.SetTrayHint(const AHint: string);
begin
  // Only on change: updating a visible tray icon is not free and the
  // countdown timer fires several times per second.
  if trayIcon.Hint <> AHint then
    trayIcon.Hint := AHint;
end;

procedure TfrmMain.FormWindowStateChange(Sender: TObject);
begin
  if (WindowState = wsMinimized) and cbMinimizeToTray.Checked then
    HideToTray;
end;

procedure TfrmMain.HideToTray;
begin
  trayIcon.Show;
  // Hide the restored window rather than keeping a hidden minimized one,
  // so it reappears at its normal position.
  WindowState := wsNormal;
  Hide;
end;

procedure TfrmMain.RestoreFromTray;
begin
  Show;
  WindowState := wsNormal;
  Application.BringToFront;
  trayIcon.Hide;
end;

procedure TfrmMain.trayIconClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TfrmMain.miShowClick(Sender: TObject);
begin
  RestoreFromTray;
end;

procedure TfrmMain.miCloseClick(Sender: TObject);
begin
  Close;
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
  // Shutdown, restart and logoff may end the process without the form
  // being closed normally, so save the settings first.
  SaveCurrentSettings;
  if not ExecutePowerAction(AAction, Error) then
    MessageDlg(AppTitle, Error, mtError, [mbOK], 0);
end;

end.
