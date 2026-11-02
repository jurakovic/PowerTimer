unit AppInfoTests;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, AppInfo;

type

  TAppInfoTests = class(TTestCase)
  published
    procedure AppTitleWithVersion_AddsVersion;
    procedure AppTitleWithVersion_EmptyVersionGivesTitle;
    procedure AppVersion_NoVersionResourceGivesEmpty;
  end;

implementation

procedure TAppInfoTests.AppTitleWithVersion_AddsVersion;
begin
  AssertEquals('Power Timer v1.0.0', AppTitleWithVersion('1.0.0'));
  AssertEquals('Power Timer v1.0.1-preview.2', AppTitleWithVersion('1.0.1-preview.2'));
end;

procedure TAppInfoTests.AppTitleWithVersion_EmptyVersionGivesTitle;
begin
  AssertEquals('Power Timer', AppTitleWithVersion(''));
end;

procedure TAppInfoTests.AppVersion_NoVersionResourceGivesEmpty;
begin
  // The test runner is built without version info
  AssertEquals('', AppVersion);
end;

initialization
  RegisterTest(TAppInfoTests);

end.
