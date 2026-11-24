program PowerTimer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  // First: its initialization makes later loads of a DLL by name search
  // only the system directory, and the LCL units after it load DLLs by
  // name, some already in their own initialization
  SystemLibraries,
  Interfaces, // LCL widgetset
  Forms,
  MainForm,
  AboutForm,
  OptionsForm,
  WarningForm,
  AccessKeyLabel,
  AppInfo,
  TimerLogic,
  TimeFields,
  Countdown,
  PowerActions,
  AppSettings;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := AppTitle;
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
