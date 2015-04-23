unit FormChangeData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, DBConnection;

type

  TArrWidthParam = array of integer;
  TChangeType = (ctEdit, ctEditBox, ctInsert, ctInsertBox, ctDelete);

  { TFormChangeData1 }

  TFormChangeData1 = class(TForm)
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    FAction: TChangeType;
    ArrComboBox: array of TComboBox;
    ArrEdits: array of TEdit;
    ApplyButton: TBitBtn;
    procedure CreateFormReWriteData(ANum: integer; AWidth: integer);
    procedure CreateFormEditData(ANum: integer; AWidth: integer);
    procedure CreateBtn ();
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ChangeApplyClick (Sender: TObject);
  end;

var
  FormChangeData1: TFormChangeData1;

implementation
uses meta;
var
  UsedWidth, UsedHeight: integer;
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

procedure TFormChangeData1.CreateFormReWriteData(ANum: integer; AWidth: integer);
var
  i: integer;
begin
  ArrComboBox[ANum]:= TComboBox.Create(Self);
  with ArrComboBox[ANum] do
  begin
    Parent:= self;
    Top:= 10 + UsedHeight;
    Left:= 10;
    Width:= AWidth + 20;
    Height:= 24;
    ReadOnly:= true;
    Visible:= true;
    UsedHeight+= Height + 5;
  end;
end;

procedure TFormChangeData1.CreateFormEditData(ANum: integer; AWidth: integer);
begin
  ArrEdits[ANum]:= TEdit.Create(Self);
  with ArrEdits[ANum] do
  begin
    Parent:= self;
    Top:= 10 + UsedHeight;
    Left:= 10;
    Width:= AWidth + 10;
    Height:= 24;
    Visible:= true;
    UsedHeight+= Height + 5;
  end;
end;

procedure TFormChangeData1.CreateBtn ();
begin
  ApplyButton:= TBitBtn.Create(Self);
  with ApplyButton do
  begin
     Parent:= self;
     Top:= UsedHeight + 10;
     Kind:= bkOK;
     Width:= 104;
     Left:= self.Width div 2 - Width div 2;
     Height:= 24;
     Caption:= '&Применить';
     Visible:= true;
     OnClick:= @ChangeApplyClick;
     UsedHeight+= Height + 5;
  end;
  UsedWidth+= ApplyButton.Width + 10;
  self.Height:= UsedHeight + 20;
  self.Width:= 350;
  UsedHeight:= 0;
  UsedWidth:= 0;
end;

procedure TFormChangeData1.ChangeApplyClick (Sender: TObject);
var
  TempList: TStringList;
  i: integer;
begin
  TempList:= TStringList.Create;
  if (FAction = ctInsert) or (FAction = ctEdit) then
    for i:=0 to high(ArrEdits) do
      TempList.Append(ArrEdits[i].Text)
  else
    for i:=0 to high(ArrComboBox) do
      TempList.Append(ArrComboBox[i].Text);
  DataModule1.MakeChangesDatabase(
    TableArr[Self.Tag].GenQueryChanges(FAction, TempList));
  TableArr[Self.Tag].FormUpdateData;
  TempList.Destroy;
  Self.Close;
end;

end.

