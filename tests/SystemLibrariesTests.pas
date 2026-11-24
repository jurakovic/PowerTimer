unit SystemLibrariesTests;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, SystemLibraries;

type

  TSystemLibrariesTests = class(TTestCase)
  published
    procedure SystemFilePath_IsInSystemDirectory;
    procedure LoadSystemLibrary_LoadsFromSystemDirectory;
    procedure LoadSystemLibrary_MissingLibraryGivesZero;
  end;

implementation

{$IFDEF WINDOWS}

function System32Path(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('SystemRoot'))
    + 'System32\' + AName;
end;

function ModulePath(AModule: THandle): string;
var
  Buffer: array[0..MAX_PATH] of WideChar;
  Len: DWORD;
  Path: UnicodeString;
begin
  Len := GetModuleFileNameW(AModule, @Buffer[0], Length(Buffer));
  SetString(Path, PWideChar(@Buffer[0]), Len);
  Result := string(Path);
end;

{$ENDIF}

procedure TSystemLibrariesTests.SystemFilePath_IsInSystemDirectory;
begin
  {$IFDEF WINDOWS}
  AssertTrue(SystemFilePath('powrprof.dll'),
    SameText(System32Path('powrprof.dll'), SystemFilePath('powrprof.dll')));
  {$ELSE}
  AssertEquals('', SystemFilePath('powrprof.dll'));
  {$ENDIF}
end;

procedure TSystemLibrariesTests.LoadSystemLibrary_LoadsFromSystemDirectory;
var
  Module: THandle;
begin
  Module := LoadSystemLibrary('powrprof.dll');
  {$IFDEF WINDOWS}
  AssertTrue('loaded', Module <> 0);
  try
    AssertTrue('in System32: ' + ModulePath(Module),
      SameText(System32Path('powrprof.dll'), ModulePath(Module)));
  finally
    FreeLibrary(Module);
  end;
  {$ELSE}
  AssertTrue(Module = 0);
  {$ENDIF}
end;

procedure TSystemLibrariesTests.LoadSystemLibrary_MissingLibraryGivesZero;
begin
  AssertTrue(LoadSystemLibrary('no-such-library.dll') = 0);
end;

initialization
  RegisterTest(TSystemLibrariesTests);

end.
