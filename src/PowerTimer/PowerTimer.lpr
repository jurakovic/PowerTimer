program PowerTimer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // LCL widgetset
  Forms,
  MainForm,
  TimerLogic;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'Power Timer';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
