unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, Menus, ActnList, LCLType, TimerLogic, PowerActions, AppSettings,
  Countdown;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    actAbout: TAction;
    actOptions: TAction;
    alMain: TActionList;
    btnCountdown: TSpeedButton;
    btnDelayMinus: TButton;
    btnDelayPlus: TButton;
    btnSetTime: TSpeedButton;
    bvlStatus: TBevel;
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
    lblAbout: TLabel;
    lblColon1: TLabel;
    lblColon2: TLabel;
    lblDefaultAction: TLabel;
    lblDefaultDelay: TLabel;
    lblHours: TLabel;
    lblMinutes: TLabel;
    lblOptions: TLabel;
    lblSeconds: TLabel;
    lblStatus: TLabel;
    miClose: TMenuItem;
    miShow: TMenuItem;
    pmTray: TPopupMenu;
    pnlFocusHolder: TPanel;
    pnlStatus: TPanel;
    shpModeFrame: TShape;
    shpModeMark: TShape;
    tmrCountdown: TTimer;
    trayIcon: TTrayIcon;
    procedure actAboutExecute(Sender: TObject);
    procedure actOptionsExecute(Sender: TObject);
    procedure btnDelayMinusClick(Sender: TObject);
    procedure btnDelayPlusClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure cbDefaultActionChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormWindowStateChange(Sender: TObject);
    procedure lblAboutClick(Sender: TObject);
    procedure lblOptionsClick(Sender: TObject);
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
    FCountdown: TCountdown;
    function FieldMax(AEdit: TEdit): Integer;
    function ReadTimeFields: TTimeParts;
    procedure WriteTimeFields(const AParts: TTimeParts);
    procedure ResetTimeFields;
    procedure SetDelayHours(AHours: Integer);
    procedure SetOptionsVisible(AVisible: Boolean);
    procedure UpdateModeMark;
    procedure ApplySettings(const ASettings: TAppSettings);
    procedure RestoreWindowPosition(const ASettings: TAppSettings);
    function CurrentSettings: TAppSettings;
    procedure SaveCurrentSettings;
    function SelectedAction: TPowerAction;
    procedure SetInputsEnabled(AEnabled: Boolean);
    procedure StartCountdown;
    procedure CountdownChange(Sender: TObject);
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
  rsStart = 'Start';
  rsStop = 'Stop';
  rsConfirm = 'Confirm';
  rsConfirmClose = 'If you close this application the selected action will not be performed.'
    + LineEnding + 'Are you sure you want to continue?';
  rsConfirmZeroTime = 'No time entered, the selected action will be performed immediately.'
    + LineEnding + 'Continue?';
  // Application title, action, remaining time
  rsTrayHintRunning = '%s - %s after %s';

const
  // Space between the last visible control and the status bar, in 96 DPI
  // pixels
  BottomMargin = 6;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Settings: TAppSettings;
begin
  // The title and the tray hint in the form file are only what the designer
  // shows
  Caption := AppTitle;
  trayIcon.Hint := AppTitle;
  FClockMode := btnSetTime.Down;
  UpdateModeMark;
  trayIcon.Icon.Assign(Application.Icon);
  FCountdown := TCountdown.Create;
  FCountdown.OnChange := @CountdownChange;
  FCountdown.OnRunAction := @RunAction;
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

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FCountdown.Free;
end;

{ Esc stops a running countdown. It can't be the Cancel key of the Start
  button, which would also start a countdown on Esc while idle. }
procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and FCountdown.Running then
  begin
    FCountdown.Stop;
    Key := 0;
  end;
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
    LastControl := gbOptions
  else
    LastControl := lblHours; // the unit labels end the main row
  // Computed from the (already DPI scaled) controls, so it fits on high-DPI
  // screens too. The status bar is aligned to the bottom and moves along.
  ClientHeight := LastControl.Top + LastControl.Height
    + Scale96ToForm(BottomMargin) + pnlStatus.Height;
end;

procedure TfrmMain.actOptionsExecute(Sender: TObject);
begin
  SetOptionsVisible(not gbOptions.Visible);
end;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  ShowAbout(Self);
end;

{ The links in the status bar are labels: they can't take the keyboard
  focus, so their actions give them the shortcuts Alt+O and Alt+A. }
procedure TfrmMain.lblOptionsClick(Sender: TObject);
begin
  actOptions.Execute;
end;

procedure TfrmMain.lblAboutClick(Sender: TObject);
begin
  actAbout.Execute;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FCountdown.Running then
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

{ The selected mode has the accent mark on its left and its text in the
  accent color; the other one stays a plain flat button, so it still looks
  clickable. While the mode can't be changed, the mark is grey. }
procedure TfrmMain.UpdateModeMark;
var
  Selected, Other: TSpeedButton;
  MarkColor: TColor;
begin
  if FClockMode then
  begin
    Selected := btnSetTime;
    Other := btnCountdown;
  end
  else
  begin
    Selected := btnCountdown;
    Other := btnSetTime;
  end;
  shpModeMark.Top := Selected.Top;
  Selected.Font.Color := clHighlight;
  Other.Font.Color := clBtnText;
  if Selected.Enabled then
    MarkColor := clHighlight
  else
    MarkColor := clGrayText;
  shpModeMark.Brush.Color := MarkColor;
  shpModeMark.Pen.Color := MarkColor;
end;

procedure TfrmMain.ModeButtonClick(Sender: TObject);
begin
  if FClockMode = btnSetTime.Down then
    Exit;
  FClockMode := btnSetTime.Down;
  UpdateModeMark;
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
  if FCountdown.Running then
    FCountdown.Stop
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
  actOptions.Enabled := AEnabled;
  actAbout.Enabled := AEnabled;
  lblOptions.Enabled := AEnabled;
  lblAbout.Enabled := AEnabled;
  UpdateModeMark;
end;

procedure TfrmMain.StartCountdown;
var
  Entered: TTimeParts;
  Mode: TCountdownMode;
begin
  Entered := ReadTimeFields;
  WriteTimeFields(Entered);

  if FClockMode then
    Mode := cmClockTime
  else
    Mode := cmCountdown;
  if FCountdown.Start(Mode, Entered, SelectedAction, Now, GetTickCount64) then
    Exit;

  // Nothing to wait for (00:00:00 in Countdown mode): run the action now
  if cbWarnZeroTime.Checked and (MessageDlg(rsConfirm, rsConfirmZeroTime,
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  RunAction(SelectedAction);
end;

{ Called whenever the countdown starts or stops, also when it ends, before
  the action runs. }
procedure TfrmMain.CountdownChange(Sender: TObject);
begin
  if FCountdown.Running then
  begin
    SetOptionsVisible(False);
    SetInputsEnabled(False);
    btnStart.Caption := rsStop;
    // Enter starts a countdown but doesn't stop it by accident
    btnStart.Default := False;
    ShowRemaining(FCountdown.RemainingSeconds(Now, GetTickCount64));
    tmrCountdown.Enabled := True;
  end
  else
  begin
    tmrCountdown.Enabled := False;
    // Show what was entered again, not the remaining time: in "At time"
    // mode the remaining time would otherwise be read as a clock time.
    WriteTimeFields(FCountdown.Entered);
    SetInputsEnabled(True);
    btnStart.Caption := rsStart;
    btnStart.Default := True;
    SetTrayHint(AppTitle);
  end;
end;

procedure TfrmMain.ShowRemaining(ASeconds: Integer);
begin
  WriteTimeFields(SecondsToFieldParts(ASeconds));
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
  NowTime: TDateTime;
  Ticks: QWord;
begin
  NowTime := Now;
  Ticks := GetTickCount64;
  FCountdown.Tick(NowTime, Ticks);
  if FCountdown.Running then
    ShowRemaining(FCountdown.RemainingSeconds(NowTime, Ticks));
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
