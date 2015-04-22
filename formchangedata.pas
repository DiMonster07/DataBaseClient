unit FormChangeData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, DBConnection;

type

  TArrWidthParam = array of integer;
  TChangeType = (ctEdit, ctInsert, ctDelete);

  { TFormChangeData1 }

  TFormChangeData1 = class(TForm)
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    FAction: TChangeType;
    ArrComboBox: array of TComboBox;
    ApplyButton: TBitBtn;
    procedure FormReWriteData(ANum: integer; AWidth: integer);
    procedure CreateBtn ();
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ChangeApplyClick (Sender: TObject);
  end;

var
  FormChangeData1: TFormChangeData1;

implementation
uses meta;
var
  UsedWidth: integer;
{$R *.lfm}

{ TFormChangeData1 }

procedure TFormChangeData1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  TableArr[Self.Tag].ChangeStatus:= false;
end;

procedure TFormChangeData1.FormCreate(Sender: TObject);
begin
  UsedWidth:=0;
end;

procedure TFormChangeData1.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
var
  i: integer;
begin
  for i:=0 to high(ArrComboBox) do
    ArrComboBox[i].Free;
  SetLength(ArrComboBox, 0);
  TableArr[Self.Tag].FormChangeClose;
end;

procedure TFormChangeData1.FormReWriteData(ANum: integer; AWidth: integer);
var
  i: integer;
begin
  ArrComboBox[ANum]:= TComboBox.Create(Self);
  with ArrComboBox[ANum] do
  begin
    Parent:= self;
    Top:= 15;
    Left:= UsedWidth + 10;
    Width:= AWidth + 10;
    Height:= 24;
    ReadOnly:= true;
    Visible:= true;
  end;
  UsedWidth+= AWidth + 20;
end;

procedure TFormChangeData1.CreateBtn ();
begin
  ApplyButton:= TBitBtn.Create(Self);
  with ApplyButton do
  begin
     Parent:= self;
     Top:= 15;
     Left:= UsedWidth + 10;
     Kind:= bkOK;
     Width:= 104;
     Height:= 24;
     Caption:= '&Применить';
     Visible:= true;
     OnClick:= @ChangeApplyClick;
  end;
  UsedWidth+= ApplyButton.Width + 10;
  self.Width:= UsedWidth + 10;
  UsedWidth:= 0;
end;

procedure TFormChangeData1.ChangeApplyClick (Sender: TObject);
var
  TempList: TStringList;
  i: integer;
begin
  TempList:= TStringList.Create;
  for i:=0 to high(ArrComboBox) do
    TempList.Append(ArrComboBox[i].Text);
  DataModule1.MakeChangesDatabase(
    TableArr[Self.Tag].GenQueryChanges(FAction, TempList));
  TableArr[Self.Tag].FormUpdateData;
  TempList.Destroy;
  Self.Close;
end;

end.

