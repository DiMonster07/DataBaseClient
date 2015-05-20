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
    function GetId(ANum: integer): integer;
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
  TempList: TStringList;
  i, key, num: integer;
  s: string;
begin
  TempList:= TStringList.Create;
  if (FAction = ctEdit) or (FAction = ctInsert) then
    if isNullCheckEdit() then
    begin
      ShowMessage('Заполните все поля!');
      exit;
    end;
  for i:=0 to high(ArrControls) do
  begin
    if ArrControls[i] is TEdit then
      TempList.Append((ArrControls[i] as TEdit).Text)
    else
      TempList.Append((ArrControls[i] as TComboBox).Caption)
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
      DataModule1.SQLQuery.ParamByName(s).AsInteger:= GetId(i)
    else
      DataModule1.SQLQuery.ParamByName(s).AsString:=
        (ArrControls[i] as TEdit).Text;
  end;
  DataModule1.SQLQuery.ExecSQL;
  //DataModule1.SQLTransaction1.Commit;
  (FormsOfTables.FForms[Tag] as TFormTable).InvalidateDBGrid(Tag);
  Close;
  //Устанавливает фокус на строку 3
  //FDBGrid.DataSource.DataSet.MoveBy(3);
end;

function TFormChangeData1.GetId(ANum: integer): integer;
var
  i, k, j: integer;
  temp: TStringList;
  TempDSource: TDataSource;
  TempSQLQuery: TSQLQuery;
  TempSQLTransaction: TSQLTransaction;
begin
  TempDSource:= TDataSource.Create(DataModule1);
  TempSQLQuery:= TSQLQuery.Create(DataModule1);
  TempSQLTransaction:= TSQLTransaction.Create(DataModule1);
  TempDSource.DataSet:= TempSQLQuery;
  TempSQLQuery.DataBase:= DataModule1.IBConnection1;
  TempSQLQuery.Transaction:= TempSQLTransaction;
  TempSQLTransaction.DataBase:= DataModule1.IBConnection1;
  temp:= TStringList.Create;
  k:= (ArrControls[ANum] as TComboBox).ItemIndex;
  i:= MetaData.MetaTables[Tag].Fields[ANum + 1].Reference.TableTag;
  TempSQLQuery.Close;
  TempSQLQuery.SQL.Text:= 'SELECT * FROM ' +
    MetaData.MetaTables[i].Name;
  TempSQLQuery.Open;
  while not TempSQLQuery.EOF do
  begin
    temp.Append(TempSQLQuery.Fields[0].AsString);
    TempSQLQuery.Next;
  end;
  TempSQLQuery.Close;
  TempDSource.Free;
  TempSQLQuery.Free;
  TempSQLTransaction.Free;
  result:= StrToInt(temp[k]);
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

