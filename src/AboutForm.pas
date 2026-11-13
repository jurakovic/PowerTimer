unit AboutForm;

{ The About box: name and version, what Power Timer does and a link to its
  home page. }

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, Graphics, StdCtrls, ExtCtrls;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    btnOK: TButton;
    imgIcon: TImage;
    lblDescription: TLabel;
    lblLink: TLabel;
    lblTitle: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lblLinkClick(Sender: TObject);
  end;

{ Shows the About box as a modal dialog. }
procedure ShowAbout(AOwner: TComponent);

implementation

uses
  SysUtils, LCLIntf, AppInfo;

{$R *.lfm}

resourcestring
  // Application title
  rsAboutCaption = 'About %s';

procedure ShowAbout(AOwner: TComponent);
var
  Form: TfrmAbout;
begin
  Form := TfrmAbout.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

{ TfrmAbout }

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  Caption := Format(rsAboutCaption, [AppTitle]);
  lblTitle.Caption := AppTitleWithVersion(AppVersion);
  lblLink.Caption := AppUrl;
  imgIcon.Picture.Icon.Assign(Application.Icon);
end;

procedure TfrmAbout.lblLinkClick(Sender: TObject);
begin
  OpenURL(AppUrl);
end;

end.
