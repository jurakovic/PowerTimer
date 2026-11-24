unit WarningForm;

{ The warning shortly before the action runs: a small window above all
  other windows, also while the main window is in the tray, counting down,
  with Cancel and +10 min. It may open while the user is typing in another
  program, so no key presses a button: an empty panel has the focus, and
  there is no default or cancel button. }

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, StdCtrls, ExtCtrls;

type

  { TfrmWarning }

  TfrmWarning = class(TForm)
    btnCancel: TButton;
    btnPostpone: TButton;
    lblMessage: TLabel;
    pnlFocusHolder: TPanel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnPostponeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FOnCancelCountdown: TNotifyEvent;
    FOnPostpone: TNotifyEvent;
  public
    { Shows '<action> in <n> seconds', and the window if it is hidden. }
    procedure ShowWarning(const AActionName: string; ASeconds: Integer);
    { Fired by Cancel, which stops the countdown. }
    property OnCancelCountdown: TNotifyEvent read FOnCancelCountdown
      write FOnCancelCountdown;
    { Fired by +10 min, which moves the action PostponeMinutes later. }
    property OnPostpone: TNotifyEvent read FOnPostpone write FOnPostpone;
  end;

implementation

uses
  SysUtils, AppInfo, TimerLogic;

{$R *.lfm}

resourcestring
  // Action, seconds left (see FormatSecondsLeft)
  rsWarningMessage = '%s in %s';
  // Minutes
  rsPostpone = '+%d min';

{ TfrmWarning }

procedure TfrmWarning.FormCreate(Sender: TObject);
begin
  // The title and the texts in the form file are only what the designer
  // shows
  Caption := AppTitle;
  btnPostpone.Caption := Format(rsPostpone, [PostponeMinutes]);
  // The empty, zero-size panel holds the focus, so a key typed for another
  // program doesn't press a button
  ActiveControl := pnlFocusHolder;
end;

procedure TfrmWarning.ShowWarning(const AActionName: string; ASeconds: Integer);
var
  Msg: string;
begin
  Msg := Format(rsWarningMessage, [AActionName, FormatSecondsLeft(ASeconds)]);
  // Only on change: the countdown timer fires several times per second
  if lblMessage.Caption <> Msg then
    lblMessage.Caption := Msg;
  if not Visible then
    Show;
end;

procedure TfrmWarning.btnCancelClick(Sender: TObject);
begin
  if Assigned(FOnCancelCountdown) then
    FOnCancelCountdown(Self);
end;

procedure TfrmWarning.btnPostponeClick(Sender: TObject);
begin
  if Assigned(FOnPostpone) then
    FOnPostpone(Self);
end;

{ Closing the window only hides it: the action still runs. }
procedure TfrmWarning.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

end.
