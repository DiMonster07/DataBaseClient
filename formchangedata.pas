unit FormChangeData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFormChangeData1 }

  TFormChangeData1 = class(TForm)
    ComboBox1: TComboBox;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    procedure CreateElements();
  end;

var
  FormChangeData1: TFormChangeData1;

implementation
uses meta;
{$R *.lfm}

{ TFormChangeData1 }

procedure TFormChangeData1.FormCreate(Sender: TObject);
begin

end;

procedure TFormChangeData1.CreateElements;
begin

end;

end.

