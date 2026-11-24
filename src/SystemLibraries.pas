unit SystemLibraries;

{ Loads Windows DLLs from the system directory only. A DLL loaded by its
  name alone is looked for in the folder of PowerTimer.exe first, so a DLL
  of that name planted there, e.g. in Downloads, would be loaded and run.

  The initialization makes every later load of a DLL by its name alone,
  also by the LCL, search only the system directory. It must run before
  the units that load DLLs, so PowerTimer.lpr lists this unit first; it
  uses only Windows and SysUtils for that reason. }

{$mode objfpc}{$H+}

interface

{ Full path of AName in the Windows system directory, or '' when that
  directory cannot be determined (always '' on other platforms). }
function SystemFilePath(const AName: string): string;

{ Loads the DLL AName from the Windows system directory, never from the
  folder of PowerTimer.exe. Returns its module handle, or 0 when it can't
  be loaded, with the error in GetLastError (always 0 on other
  platforms). }
function LoadSystemLibrary(const AName: string): THandle;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils;

{$IFDEF WINDOWS}

const
  // Declared here so it doesn't depend on the version of FPC's Windows
  // unit. Needs Windows 8, or Windows 7 with update KB2533623.
  LOAD_LIBRARY_SEARCH_SYSTEM32 = $00000800;

type
  TSetDefaultDllDirectories = function(DirectoryFlags: DWORD): BOOL; stdcall;

function SetDllDirectoryW(lpPathName: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'SetDllDirectoryW';

function SystemFilePath(const AName: string): string;
var
  Buffer: array[0..MAX_PATH] of WideChar;
  Len: UINT;
  Dir: UnicodeString;
begin
  Len := GetSystemDirectoryW(@Buffer[0], Length(Buffer));
  // 0 means failure; a value >= the buffer size is the size it would need
  if (Len = 0) or (Len >= Length(Buffer)) then
    Exit('');
  SetString(Dir, PWideChar(@Buffer[0]), Len);
  Result := IncludeTrailingPathDelimiter(string(Dir)) + AName;
end;

function LoadSystemLibrary(const AName: string): THandle;
var
  Path: string;
begin
  Result := LoadLibraryExW(PWideChar(UnicodeString(AName)), 0,
    LOAD_LIBRARY_SEARCH_SYSTEM32);
  if (Result <> 0) or (GetLastError <> ERROR_INVALID_PARAMETER) then
    Exit;
  // A Windows that doesn't know the flag: load the DLL by its full path
  Path := SystemFilePath(AName);
  if Path <> '' then
    Result := LoadLibraryW(PWideChar(UnicodeString(Path)));
end;

{ Makes every later load of a DLL by its name alone search only the system
  directory. Where SetDefaultDllDirectories isn't available (Windows 7
  without update KB2533623), it at least takes the current directory out
  of the search. }
procedure RestrictDllSearch;
var
  SetDefaultDllDirectories: TSetDefaultDllDirectories;
  NoDirectory: WideChar;
begin
  Pointer(SetDefaultDllDirectories) := GetProcAddress(
    GetModuleHandle('kernel32.dll'), 'SetDefaultDllDirectories');
  if Assigned(SetDefaultDllDirectories)
    and SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_SYSTEM32) then
    Exit;
  // An empty string, not nil, removes the current directory
  NoDirectory := #0;
  SetDllDirectoryW(@NoDirectory);
end;

{$ELSE}

function SystemFilePath(const AName: string): string;
begin
  Result := '';
end;

function LoadSystemLibrary(const AName: string): THandle;
begin
  Result := 0;
end;

{$ENDIF}

initialization
  {$IFDEF WINDOWS}
  RestrictDllSearch;
  {$ENDIF}

end.
