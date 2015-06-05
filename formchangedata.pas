unit FormChangeData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, DBConnection, SqlGenerator, sqldb, db;

type

  TChangeEvent = procedure (Sender: TObject) of object;
  TArrWidthParam = array of integer;
  TChangeType = (ctEdit, ctInsert, ctDelete);
  TDelClosedForm = procedure (Sender: TObject);
  TInvalidateGrid = procedure (ATag: integer) of OBject;

  { TFormChangeData1 }

  TFormChangeData1 = class(TForm)
    IdLabel: TLabel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
  public
    FAction: TChangeType;
    ArrControls: array of TControl;
    ApplyButton: TBitBtn;
    procedure CreateComboBox(AList: TStringList; AName: string; AWidth: integer);
    procedure CreateEdit(AName: string; AWidth: integer);
    procedure CreateBtn ();
    procedure ChangeApplyClick (Sender: TObject);
    function isNullCheckEdit(): boolean;
    procedure FillComboBox(AList: TStringList; ANum: integer);
  end;

var
  FormChangeData1: TFormChangeData1;
  DelEditingForm: TDelClosedForm;
  InvalidateGrid: TInvalidateGrid;
implementation
uses meta, GenerationForms;
var
  UsedWidth, UsedHeight: integer;
{$R *.lfm}

{ TFormChangeData1 }

procedure TFormChangeData1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  i: integer;
begin
  for i:=0 to high(ArrControls) do
    ArrControls[i].Free;
  SetLength(ArrControls, 0);
  DelEditingForm(Sender);
end;

procedure TFormChangeData1.FormCreate(Sender: TObject);
begin
  UsedWidth:=0;
end;

procedure TFormChangeData1.FillComboBox(AList: TStringList; ANum: integer);
var
  i: integer;
begin
  (ArrControls[ANum] as TComboBox).Clear;
  for i:= 0 to AList.Count - 1 do
    (ArrControls[ANum] as TComboBox).Items.Add(AList.ValueFromIndex[i]);
  (ArrControls[ANum] as TComboBox).ItemIndex:= 0;
end;

procedure TFormChangeData1.CreateComboBox(AList: TStringList; AName: string;
  AWidth: integer);
var
  i: integer;
  ALabel: TLabel;
begin
  ALabel:= TLabel.Create(Self);
  with ALabel do
  begin
    Parent:= self;
    Top:= 10 + UsedHeight;
    Left:= 10;
    Width:= AWidth + 20;
    Height:= 18;
    Visible:= true;
    UsedHeight+= Height;
  end;
  ALabel.Caption:= AName + ':';
  ArrControls[high(ArrControls)]:= TComboBox.Create(Self);
  with (ArrControls[high(ArrControls)] as TComboBox) do
  begin
    Parent:= self;
    Top:= 10 + UsedHeight;
    Left:= 10;
    Width:= ALabel.Width + 20;
    Height:= 24;
    ReadOnly:= true;
    Visible:= true;
    UsedHeight+= Height + 5;
  end;
  for i:= 0 to AList.Count - 1 do
    (ArrControls[high(ArrControls)] as TComboBox).Items.Add(
      AList.ValueFromIndex[i]);
end;

procedure TFormChangeData1.CreateEdit(AName: string; AWidth: integer);
var
  ALabel: TLabel;
begin
  ALabel:= TLabel.Create(Self);
  with ALabel do
  begin
    Parent:= self;
    Top:= 10 + UsedHeight;
    Left:= 10;
    Width:= AWidth + 20;
    Height:= 18;
    Visible:= true;
    UsedHeight+= Height;
  end;
  ALabel.Caption:= AName + ':';
  ArrControls[high(ArrControls)]:= TEdit.Create(Self);
  with (ArrControls[high(ArrControls)] as TEdit) do
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
  Width:= 500;
  ApplyButton:= TBitBtn.Create(Self);
  with ApplyButton do
  begin
     Parent:= self;
     Top:= UsedHeight + 10;
     Kind:= bkOK;
     Width:= 104;
     Left:= self.Width - Width - 10;
     Height:= 24;
     Caption:= '&Применить';
     Visible:= true;
     OnClick:= @ChangeApplyClick;
     UsedHeight+= Height + 5;
  end;
  UsedWidth+= ApplyButton.Width + 10;
  Height:= UsedHeight + 15;
  UsedHeight:= 0;
  UsedWidth:= 0;
end;

procedure TFormChangeData1.ChangeApplyClick (Sender: TObject);
var
  i, key, num: integer;
  s: string;
begin
  if (FAction = ctEdit) or (FAction = ctInsert) then
    if isNullCheckEdit() then
    begin
      ShowMessage('Заполните все поля!');
      exit;
    end;
  DataModule1.SQLQuery.Close;
  if FAction = ctInsert then
  begin
    key:= GenUniqId;
    DataModule1.SQLQuery.SQL.Text:= GenInsertQuery(Tag).Text;
    DataModule1.SQLQuery.ParamByName('p0').AsInteger:= key;
  end
  else
  begin
    DataModule1.SQLQuery.SQL.Text:= GenUpdateQuery(Tag).Text;
    DataModule1.SQLQuery.ParamByName('p0').AsInteger:= IdLabel.Tag;
  end;
  for i:= 0 to high(ArrControls) do
  begin
    s:= 'p' + IntToStr(i + 1);
    if MetaData.MetaTables[Tag].Fields[i + 1].Reference <> nil then
      DataModule1.SQLQuery.ParamByName(s).AsInteger:= GetId(Tag, i,
        (ArrControls[i] as TComboBox).ItemIndex)
    else
      DataModule1.SQLQuery.ParamByName(s).AsString:=
        (ArrControls[i] as TEdit).Text;
  end;
  DataModule1.SQLQuery.ExecSQL;
  //DataModule1.SQLTransaction1.Commit;
  GlobalUpdate(Tag);
  Close;
end;

function TFormChangeData1.isNullCheckEdit(): boolean;
var
  i: integer;
  res: boolean;
begin
  i:= 0;
  for i:= 0 to high(ArrControls) do
  begin
    if ArrControls[i] is TEdit then
    begin
      if (ArrControls[i] as TEdit).text = '' then
        exit(true);
    end
  end;
  result:= false;
end;

end.

