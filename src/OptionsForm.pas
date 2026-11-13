unit OptionsForm;

{ The Options dialog: the settings that can be changed, edited on a copy
  that is only written back on OK. }

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, StdCtrls, ExtCtrls, AppSettings;

type

  { TfrmOptions }

  TfrmOptions = class(TForm)
    btnCancel: TButton;
    btnDelayMinus: TButton;
    btnDelayPlus: TButton;
    btnOK: TButton;
    bvlButtons: TBevel;
    cbDefaultAction: TComboBox;
    cbMinimizeToTray: TCheckBox;
    cbRememberWinPos: TCheckBox;
    cbWarnZeroTime: TCheckBox;
    edtDefaultDelay: TEdit;
    lblBehaviour: TLabel;
    lblDefaultAction: TLabel;
    lblDefaultDelay: TLabel;
    lblOnStartup: TLabel;
    procedure btnDelayMinusClick(Sender: TObject);
    procedure btnDelayPlusClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FDelayHours: Integer;
    procedure SetDelayHours(AHours: Integer);
    procedure ReadSettings(const ASettings: TAppSettings);
    procedure WriteSettings(var ASettings: TAppSettings);
  end;

{ Shows the Options dialog for ASettings as a modal dialog. On OK it writes
  the options back to ASettings, leaving the window position as it is, and
  returns True; on Cancel it returns False and ASettings stays unchanged. }
function EditSettings(AOwner: TComponent; var ASettings: TAppSettings): Boolean;

implementation

uses
  TimerLogic, TimeFields, PowerActions;

{$R *.lfm}

function EditSettings(AOwner: TComponent; var ASettings: TAppSettings): Boolean;
var
  Form: TfrmOptions;
begin
  Form := TfrmOptions.Create(AOwner);
  try
    Form.ReadSettings(ASettings);
    Result := Form.ShowModal = mrOK;
    if Result then
      Form.WriteSettings(ASettings);
  finally
    Form.Free;
  end;
end;

{ TfrmOptions }

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  // Filled from PowerActions so that ItemIndex always equals
  // Ord(TPowerAction).
  FillPowerActionList(cbDefaultAction.Items);
end;

procedure TfrmOptions.ReadSettings(const ASettings: TAppSettings);
begin
  cbDefaultAction.ItemIndex := Ord(ASettings.DefaultAction);
  SetDelayHours(ASettings.DefaultDelayHours);
  cbMinimizeToTray.Checked := ASettings.MinimizeToTray;
  cbRememberWinPos.Checked := ASettings.RememberWindowPos;
  cbWarnZeroTime.Checked := ASettings.WarnZeroTime;
end;

procedure TfrmOptions.WriteSettings(var ASettings: TAppSettings);
begin
  ASettings.DefaultAction := PowerActionFromIndex(cbDefaultAction.ItemIndex);
  ASettings.DefaultDelayHours := FDelayHours;
  ASettings.MinimizeToTray := cbMinimizeToTray.Checked;
  ASettings.RememberWindowPos := cbRememberWinPos.Checked;
  ASettings.WarnZeroTime := cbWarnZeroTime.Checked;
end;

procedure TfrmOptions.SetDelayHours(AHours: Integer);
begin
  FDelayHours := ClampDelayHours(AHours);
  edtDefaultDelay.Text := FormatTimeField(FDelayHours);
end;

procedure TfrmOptions.btnDelayPlusClick(Sender: TObject);
begin
  SetDelayHours(FDelayHours + 1);
end;

procedure TfrmOptions.btnDelayMinusClick(Sender: TObject);
begin
  SetDelayHours(FDelayHours - 1);
end;

end.
