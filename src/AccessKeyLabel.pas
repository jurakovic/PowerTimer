unit AccessKeyLabel;

{ A label that underlines its access key (the letter after "&") only while
  Windows shows keyboard cues, as it does for its own buttons and menus:
  once Alt is pressed, or always when "Underline access keys" is on in the
  Windows settings. LCL labels underline it all the time.

  The class keeps the name TLabel, so a form unit that lists this unit
  after StdCtrls gets it for all its labels, while its form file and the
  designer keep plain TLabels. Labels without an access key look the same
  as before. }

{$mode objfpc}{$H+}

interface

uses
  Types, StdCtrls;

type

  { TLabel }

  TLabel = class(StdCtrls.TLabel)
  protected
    procedure DoDrawText(var Rect: TRect; Flags: Longint); override;
  end;

implementation

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

procedure TLabel.DoDrawText(var Rect: TRect; Flags: Longint);
begin
  {$IFDEF WINDOWS}
  // The parent window holds the UI state. When Alt is pressed, Windows
  // clears UISF_HIDEACCEL there and the LCL repaints the window, so the
  // label is drawn again with the underline.
  if (Parent <> nil) and Parent.HandleAllocated
    and ((Windows.SendMessage(Parent.Handle, WM_QUERYUISTATE, 0, 0)
      and UISF_HIDEACCEL) <> 0) then
    Flags := Flags or DT_HIDEPREFIX;
  {$ENDIF}
  inherited DoDrawText(Rect, Flags);
end;

end.
