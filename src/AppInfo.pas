unit AppInfo;

{ Name, home page and version of Power Timer. }

{$mode objfpc}{$H+}

interface

const
  AppTitle = 'Power Timer';
  AppUrl = 'https://github.com/jurakovic/PowerTimer';

{ Product version from the version resource of the running executable, e.g.
  '1.0.0' or '1.0.1-preview.2'. publish.sh sets it for releases; other
  builds have the default of the project, '0.0.0'. Gives '' when the
  executable has no version resource. }
function AppVersion: string;

{ AppTitle with the version, e.g. 'Power Timer v1.0.0', or only AppTitle
  when AVersion is ''. }
function AppTitleWithVersion(const AVersion: string): string;

implementation

uses
  SysUtils, fileinfo;

function AppVersion: string;
var
  Info: TFileVersionInfo;
begin
  Result := '';
  Info := TFileVersionInfo.Create(nil);
  try
    try
      Info.ReadFileInfo;
      Result := Info.VersionStrings.Values['ProductVersion'];
    except
      // No or unreadable version resource: the version is only shown, so
      // it is left out
      on Exception do
        Result := '';
    end;
  finally
    Info.Free;
  end;
end;

function AppTitleWithVersion(const AVersion: string): string;
begin
  if AVersion = '' then
    Result := AppTitle
  else
    Result := AppTitle + ' v' + AVersion;
end;

end.
