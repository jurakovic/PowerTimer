unit TaskbarProgress;

{ The progress of the countdown on the taskbar button, through the shell's
  ITaskbarList3. Every failure is ignored: the button then shows no
  progress, and nothing else changes. Does nothing on other platforms. }

{$mode objfpc}{$H+}

interface

{ Shows ACompleted of ATotal as a green bar on the taskbar button of
  AWindow. Windows drops the bar when the button is created again, e.g.
  when the window comes back from the tray, so it is set again with every
  change rather than once. }
procedure SetTaskbarProgress(AWindow: THandle; ACompleted, ATotal: QWord);

{ Removes the bar from the taskbar button of AWindow. }
procedure ClearTaskbarProgress(AWindow: THandle);

implementation

{$IFDEF WINDOWS}

uses
  Windows, ActiveX, ShlObj;

var
  Initialized: Boolean = False;
  ComInitialized: Boolean = False;
  // nil when it couldn't be created
  TaskbarList: ITaskbarList3 = nil;

{ The shell's taskbar object, created on first use. }
function GetTaskbarList: ITaskbarList3;
var
  List: ITaskbarList3;
begin
  if not Initialized then
  begin
    Initialized := True;
    // S_FALSE, COM already initialized on this thread, is a success too,
    // and is balanced by CoUninitialize as well
    ComInitialized := Succeeded(CoInitialize(nil));
    if Succeeded(CoCreateInstance(CLSID_TaskbarList, nil,
      CLSCTX_INPROC_SERVER, ITaskbarList3, List))
      and Succeeded(List.HrInit) then
      TaskbarList := List;
  end;
  Result := TaskbarList;
end;

procedure SetTaskbarProgress(AWindow: THandle; ACompleted, ATotal: QWord);
var
  List: ITaskbarList3;
begin
  List := GetTaskbarList;
  if List = nil then
    Exit;
  List.SetProgressState(AWindow, TBPF_NORMAL);
  List.SetProgressValue(AWindow, ACompleted, ATotal);
end;

procedure ClearTaskbarProgress(AWindow: THandle);
var
  List: ITaskbarList3;
begin
  List := GetTaskbarList;
  if List <> nil then
    List.SetProgressState(AWindow, TBPF_NOPROGRESS);
end;

finalization
  TaskbarList := nil;
  if ComInitialized then
    CoUninitialize;

{$ELSE}

procedure SetTaskbarProgress(AWindow: THandle; ACompleted, ATotal: QWord);
begin
end;

procedure ClearTaskbarProgress(AWindow: THandle);
begin
end;

{$ENDIF}

end.
