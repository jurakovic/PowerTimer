unit AppSettingsTests;

{ Uses a separate registry key so the real settings are never touched.
  On Windows this is HKEY_CURRENT_USER; other platforms use the FPC
  registry emulation. }

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Registry, fpcunit, testregistry, PowerActions, AppSettings;

type

  TAppSettingsTests = class(TTestCase)
  private
    procedure DeleteTestKey;
    procedure WriteRawInteger(const AName: string; AValue: Integer);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Defaults;
    procedure Normalize_ClampsDelay;
    procedure Load_MissingKeyGivesDefaults;
    procedure SaveAndLoad_RoundTrips;
    procedure Load_InvalidValuesFallBack;
    procedure Load_PositionNeedsBothCoordinates;
  end;

implementation

const
  TestKey = 'Software\Power Timer Tests';

procedure TAppSettingsTests.DeleteTestKey;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    if Reg.KeyExists(TestKey) then
      Reg.DeleteKey(TestKey);
  finally
    Reg.Free;
  end;
end;

procedure TAppSettingsTests.WriteRawInteger(const AName: string; AValue: Integer);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    AssertTrue('open test key', Reg.OpenKey(TestKey, True));
    Reg.WriteInteger(AName, AValue);
  finally
    Reg.Free;
  end;
end;

procedure TAppSettingsTests.SetUp;
begin
  DeleteTestKey;
end;

procedure TAppSettingsTests.TearDown;
begin
  DeleteTestKey;
end;

procedure TAppSettingsTests.Defaults;
var
  S: TAppSettings;
begin
  S := DefaultSettings;
  AssertTrue(S.RememberWindowPos);
  AssertTrue(S.WarnZeroTime);
  AssertTrue(S.MinimizeToTray);
  AssertTrue(S.DefaultAction = paShutdown);
  AssertEquals(1, S.DefaultDelayHours);
  AssertFalse(S.HasWindowPos);
end;

procedure TAppSettingsTests.Normalize_ClampsDelay;
var
  S: TAppSettings;
begin
  S := DefaultSettings;
  S.DefaultDelayHours := 0;
  NormalizeSettings(S);
  AssertEquals(1, S.DefaultDelayHours);
  S.DefaultDelayHours := 99;
  NormalizeSettings(S);
  AssertEquals(24, S.DefaultDelayHours);
end;

procedure TAppSettingsTests.Load_MissingKeyGivesDefaults;
var
  S, D: TAppSettings;
begin
  S := LoadSettings(TestKey);
  D := DefaultSettings;
  AssertEquals(D.RememberWindowPos, S.RememberWindowPos);
  AssertEquals(D.WarnZeroTime, S.WarnZeroTime);
  AssertEquals(D.MinimizeToTray, S.MinimizeToTray);
  AssertTrue(D.DefaultAction = S.DefaultAction);
  AssertEquals(D.DefaultDelayHours, S.DefaultDelayHours);
  AssertFalse(S.HasWindowPos);
end;

procedure TAppSettingsTests.SaveAndLoad_RoundTrips;
var
  S, L: TAppSettings;
begin
  S := DefaultSettings;
  S.RememberWindowPos := False;
  S.WarnZeroTime := False;
  S.MinimizeToTray := False;
  S.DefaultAction := paHibernate;
  S.DefaultDelayHours := 7;
  S.HasWindowPos := True;
  S.WindowLeft := -1200;
  S.WindowTop := 345;
  AssertTrue('save', SaveSettings(S, TestKey));

  L := LoadSettings(TestKey);
  AssertFalse(L.RememberWindowPos);
  AssertFalse(L.WarnZeroTime);
  AssertFalse(L.MinimizeToTray);
  AssertTrue(L.DefaultAction = paHibernate);
  AssertEquals(7, L.DefaultDelayHours);
  AssertTrue(L.HasWindowPos);
  AssertEquals(-1200, L.WindowLeft);
  AssertEquals(345, L.WindowTop);
end;

procedure TAppSettingsTests.Load_InvalidValuesFallBack;
var
  S: TAppSettings;
begin
  WriteRawInteger('defaultAction', 42);
  WriteRawInteger('defaultTimeDelay', 0);
  S := LoadSettings(TestKey);
  AssertTrue(S.DefaultAction = paShutdown);
  AssertEquals(1, S.DefaultDelayHours);
end;

procedure TAppSettingsTests.Load_PositionNeedsBothCoordinates;
begin
  WriteRawInteger('positionX', 100);
  AssertFalse(LoadSettings(TestKey).HasWindowPos);
end;

initialization
  RegisterTest(TAppSettingsTests);

end.
