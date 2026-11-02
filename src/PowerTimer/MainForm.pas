unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

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
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

end.
