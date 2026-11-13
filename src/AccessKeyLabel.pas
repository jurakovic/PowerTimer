unit AccessKeyLabel;

{ A label that underlines its access key (the letter after "&") only while
  Alt is held down in its form, or always when "Underline access keys" is
  on in the Windows settings. LCL labels underline it all the time.

  A label doesn't see the keys, so its form calls RepaintAccessKeys when
  Alt goes down or up and when the form is activated or deactivated.

  The class keeps the name TLabel, so a form unit that lists this unit
  after StdCtrls gets it for all its labels, while its form file and the
  designer keep plain TLabels. Labels without an access key look the same
  as before, and other platforms keep the underline. }

{$mode objfpc}{$H+}

interface

uses
  Types, Controls, StdCtrls;

type

  { TLabel }

  TLabel = class(StdCtrls.TLabel)
  protected
    procedure DoDrawText(var Rect: TRect; Flags: Longint); override;
  end;

{ Repaints the labels with an access key in AParent and in the controls in
  it, so that they follow the Alt key and the form's activation. }
procedure RepaintAccessKeys(AParent: TWinControl);

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Forms;

function HasAccessKey(ALabel: TLabel): Boolean;
begin
  Result := ALabel.ShowAccelChar and (Pos('&', ALabel.Caption) > 0);
end;

{$IFDEF WINDOWS}
function AccessKeysShown(AControl: TControl): Boolean;
var
  AlwaysShown: BOOL;
  Form: TCustomForm;
begin
  AlwaysShown := False;
  if SystemParametersInfo(SPI_GETKEYBOARDCUES, 0, @AlwaysShown, 0)
    and AlwaysShown then
    Exit(True);
  // The key's physical state: when Alt is released in another window,
  // e.g. after Alt+Tab, this window gets no key-up.
  Form := GetParentForm(AControl);
  Result := (Form <> nil) and Form.Active and (GetAsyncKeyState(VK_MENU) < 0);
end;
{$ENDIF}

procedure TLabel.DoDrawText(var Rect: TRect; Flags: Longint);
begin
  {$IFDEF WINDOWS}
  if HasAccessKey(Self) and not AccessKeysShown(Self) then
    Flags := Flags or DT_HIDEPREFIX;
  {$ENDIF}
  inherited DoDrawText(Rect, Flags);
end;

procedure RepaintAccessKeys(AParent: TWinControl);
var
  I: Integer;
  Control: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    Control := AParent.Controls[I];
    if Control is TWinControl then
      RepaintAccessKeys(TWinControl(Control))
    else if (Control is TLabel) and HasAccessKey(TLabel(Control)) then
      Control.Invalidate;
  end;
end;

end.
