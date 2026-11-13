unit TimeFields;

{ Input rules of the hour, minute and second fields of the main form:
  parsing and formatting their text and what may be typed into them. Has no
  UI or OS dependencies so it can be unit tested on any platform. }

{$mode objfpc}{$H+}

interface

{ Parses the text of a time field. Empty or non-numeric text gives 0 and
  the result is clamped to 0..AMax. }
function ParseTimeField(const AText: string; AMax: Integer): Integer;

{ Two digit representation of a time field value, e.g. 5 -> '05'. }
function FormatTimeField(AValue: Integer): string;

{ Adds ADelta to AValue, wrapping around within 0..AMax
  (used by the up/down arrow keys). }
function StepTimeField(AValue, ADelta, AMax: Integer): Integer;

{ True when ACandidate may be shown in a time field while the user is
  typing: empty, or at most two digits with a value not above AMax. }
function IsValidTimeFieldText(const ACandidate: string; AMax: Integer): Boolean;

{ Text that results from pressing AKey in an edit containing AText with
  the given selection (ASelStart is 0-based). Handles backspace and
  printable characters; other control characters leave the text as is. }
function ApplyKeyToText(const AText: string; ASelStart, ASelLength: Integer;
  AKey: Char): string;

implementation

uses
  SysUtils, Math;

function IsDigits(const AText: string): Boolean;
var
  C: Char;
begin
  for C in AText do
    if not (C in ['0'..'9']) then
      Exit(False);
  Result := True;
end;

function ParseTimeField(const AText: string; AMax: Integer): Integer;
var
  S: string;
begin
  S := Trim(AText);
  if (S = '') or (Length(S) > 9) or not IsDigits(S) then
    Exit(0);
  Result := EnsureRange(StrToInt(S), 0, AMax);
end;

function FormatTimeField(AValue: Integer): string;
begin
  Result := Format('%.2d', [AValue]);
end;

function StepTimeField(AValue, ADelta, AMax: Integer): Integer;
var
  Range: Integer;
begin
  Range := AMax + 1;
  Result := (EnsureRange(AValue, 0, AMax) + ADelta) mod Range;
  if Result < 0 then
    Inc(Result, Range);
end;

function IsValidTimeFieldText(const ACandidate: string; AMax: Integer): Boolean;
begin
  if ACandidate = '' then
    Exit(True);
  Result := (Length(ACandidate) <= 2) and IsDigits(ACandidate)
    and (StrToInt(ACandidate) <= AMax);
end;

function ApplyKeyToText(const AText: string; ASelStart, ASelLength: Integer;
  AKey: Char): string;
var
  Start, Len: Integer;
begin
  Start := EnsureRange(ASelStart, 0, Length(AText));
  Len := EnsureRange(ASelLength, 0, Length(AText) - Start);
  Result := AText;

  if AKey = #8 then
  begin
    if Len > 0 then
      Delete(Result, Start + 1, Len)
    else if Start > 0 then
      Delete(Result, Start, 1);
  end
  else if AKey >= ' ' then
  begin
    Delete(Result, Start + 1, Len);
    Insert(AKey, Result, Start + 1);
  end;
end;

end.
