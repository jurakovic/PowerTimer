unit AppSettings;

{ User settings, stored in HKEY_CURRENT_USER\Software\Power Timer using
  the same value names as the C# version, so existing settings are kept. }

{$mode objfpc}{$H+}

interface

uses
  PowerActions;

const
  DefaultRegistryKey = 'Software\Power Timer';

type
  TAppSettings = record
    RememberWindowPos: Boolean;
    WarnZeroTime: Boolean;
    MinimizeToTray: Boolean;
    DefaultAction: TPowerAction;
    DefaultDelayHours: Integer;
    HasWindowPos: Boolean;
    WindowLeft: Integer;
    WindowTop: Integer;
  end;

function DefaultSettings: TAppSettings;

{ Brings values that may come from an old or edited registry into range. }
procedure NormalizeSettings(var ASettings: TAppSettings);

{ Reads the settings. Missing or invalid values fall back to the defaults. }
function LoadSettings(const AKey: string = DefaultRegistryKey): TAppSettings;

function SaveSettings(const ASettings: TAppSettings;
  const AKey: string = DefaultRegistryKey): Boolean;

implementation

uses
  SysUtils, Registry, TimerLogic;

const
  ValRememberWinPos = 'rememberWinPos';
  ValPositionX = 'positionX';
  ValPositionY = 'positionY';
  ValWarnZeroTime = 'warnZeroTime';
  ValMinimizeToTray = 'minimizeToTray';
  ValDefaultAction = 'defaultAction';
  ValDefaultTimeDelay = 'defaultTimeDelay';

function DefaultSettings: TAppSettings;
begin
  Result.RememberWindowPos := True;
  Result.WarnZeroTime := True;
  Result.MinimizeToTray := True;
  Result.DefaultAction := DefaultPowerAction;
  Result.DefaultDelayHours := MinDelayHours;
  Result.HasWindowPos := False;
  Result.WindowLeft := 0;
  Result.WindowTop := 0;
end;

procedure NormalizeSettings(var ASettings: TAppSettings);
begin
  ASettings.DefaultDelayHours := ClampDelayHours(ASettings.DefaultDelayHours);
  ASettings.DefaultAction := PowerActionFromIndex(Ord(ASettings.DefaultAction));
end;

function ReadInt(AReg: TRegistry; const AName: string; ADefault: Integer;
  out AFound: Boolean): Integer;
begin
  Result := ADefault;
  AFound := False;
  if not AReg.ValueExists(AName) then
    Exit;
  try
    Result := AReg.ReadInteger(AName);
    AFound := True;
  except
    on ERegistryException do
      Result := ADefault;
  end;
end;

function ReadInt(AReg: TRegistry; const AName: string; ADefault: Integer): Integer;
var
  Found: Boolean;
begin
  Result := ReadInt(AReg, AName, ADefault, Found);
end;

function LoadSettings(const AKey: string): TAppSettings;
var
  Reg: TRegistry;
  HasX, HasY: Boolean;
begin
  Result := DefaultSettings;
  Reg := TRegistry.Create;
  try
    try
      if not Reg.OpenKeyReadOnly(AKey) then
        Exit;
      Result.RememberWindowPos :=
        ReadInt(Reg, ValRememberWinPos, Ord(Result.RememberWindowPos)) <> 0;
      Result.WarnZeroTime :=
        ReadInt(Reg, ValWarnZeroTime, Ord(Result.WarnZeroTime)) <> 0;
      Result.MinimizeToTray :=
        ReadInt(Reg, ValMinimizeToTray, Ord(Result.MinimizeToTray)) <> 0;
      Result.DefaultAction := PowerActionFromIndex(
        ReadInt(Reg, ValDefaultAction, Ord(Result.DefaultAction)));
      Result.DefaultDelayHours :=
        ReadInt(Reg, ValDefaultTimeDelay, Result.DefaultDelayHours);
      Result.WindowLeft := ReadInt(Reg, ValPositionX, 0, HasX);
      Result.WindowTop := ReadInt(Reg, ValPositionY, 0, HasY);
      Result.HasWindowPos := HasX and HasY;
    except
      on ERegistryException do
        Result := DefaultSettings;
    end;
  finally
    Reg.Free;
  end;
  NormalizeSettings(Result);
end;

function SaveSettings(const ASettings: TAppSettings; const AKey: string): Boolean;
var
  Reg: TRegistry;
  S: TAppSettings;
begin
  S := ASettings;
  NormalizeSettings(S);
  Result := False;
  Reg := TRegistry.Create;
  try
    try
      if not Reg.OpenKey(AKey, True) then
        Exit;
      Reg.WriteInteger(ValRememberWinPos, Ord(S.RememberWindowPos));
      Reg.WriteInteger(ValWarnZeroTime, Ord(S.WarnZeroTime));
      Reg.WriteInteger(ValMinimizeToTray, Ord(S.MinimizeToTray));
      Reg.WriteInteger(ValDefaultAction, Ord(S.DefaultAction));
      Reg.WriteInteger(ValDefaultTimeDelay, S.DefaultDelayHours);
      if S.HasWindowPos then
      begin
        Reg.WriteInteger(ValPositionX, S.WindowLeft);
        Reg.WriteInteger(ValPositionY, S.WindowTop);
      end;
      Result := True;
    except
      on ERegistryException do
        Result := False;
    end;
  finally
    Reg.Free;
  end;
end;

end.
