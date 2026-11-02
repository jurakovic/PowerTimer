program PowerTimer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // LCL widgetset
  Forms,
  MainForm,
  TimerLogic,
  PowerActions,
  AppSettings;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'Power Timer';
  Application.Scaled := True;
  // The main form owns the taskbar button, so hiding it to the tray
  // removes the button.
  {$PUSH}{$WARN SYMBOL_PLATFORM OFF}
  Application.MainFormOnTaskBar := True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
