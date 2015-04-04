unit meta;

{$mode objfpc}{$H+}{$LongStrings On}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, DBGrids, ComCtrls, Menus, DbCtrls,
  Grids, DBConnection;

type

  { TField }

  TField = class
  private
    FDCaption: string;
    FDName: string;
    FDWidth: integer;
    RefTable: string;
    RefField: string;
    isReference: boolean;
  published
    property Name: string read FDName write FDName;
    property Caption: string read FDCaption write FDCaption;
    property Width: integer read FDWidth write FDWidth;
    property RefS: boolean read isReference write isReference;
  end;

  { TTable }

  TTable = class
  private
    TBName: string;
    TBCaption: string;
    NewMenuIten: TMenuItem;
    TableColumns: array of TField;
    NewForm: TForm;
    NewDBGrid: TDBGrid;
    NewSQLQuery: TSQLQuery;
    NewDataSource: TDataSource;
    NewNavigator: TDBNavigator;
    FormStatus: boolean;
    isReferences: boolean;
  public
    procedure OnClickMenuItem (Sender: TObject);
    procedure CreateMenuItem (Caption: string);
    procedure CreateForm (Sender: TObject);
    procedure DelForm (Sender: TObject);
    function GetForm(): TForm;
    procedure FormClose(Sender: TObject; var CanClose: boolean);
    procedure CreateCaptionColumn(TableName: string);
    procedure GetCaptionColumn();
    procedure CreateRef();
    function GetColForNum (n: integer): TField;
    function GetCol(CName: string): TField;
    function SQLGen ():TStringList;
  published
    property Name: string read TBName write TBName;
    property Caption: string  read TBCaption write TBCaption;
    property FStatus: boolean  read FormStatus write FormStatus;
    property RefStatus: boolean read isReferences write isReferences;
  end;

var
  TableArr: array of TTable;
  NameTable: array of TField;
  TBConnection: TIBConnection;
  MainItem: TMenuItem;
  TranslateList: TStringList;
  ColWidth: integer;

procedure CreateTable (TableName: string);
function FindTableofName (TableName: string):TTable;
function CreateItemName (IName: string): string;
function CheckRef (TableColumns: TField):boolean;
implementation

procedure TTable.CreateForm (Sender: TObject);
var
  s: TStringList;
begin
  s:= TStringList.Create;
  FStatus:= true;
  NewForm:= TForm.Create(Application);
  with NewForm do
  begin
    Parent := nil;
    Caption:= (Sender as TMenuItem).Caption;
    Width:= 420;
    Height:= 550;
    OnCloseQuery:= @FormClose;
    BorderStyle:= bsSingle;
    Show;
  end;
  NewDBGrid:= TDBGrid.Create(NewForm);
  with NewDBGrid do
  begin
    Parent := NewForm;
    Width:= 400;
    Height:= 490;
    Left:= 10;
    Top:= 10;
    Visible:= true;
  end;
  NewSQLQuery:= TSQLQuery.Create(NewForm);
  with NewSQLQuery do
  begin
    DataBase:= DataModule1.IBConnection1;
    if isReferences then
    begin
      SQL.Text:= SQLGen.Text;
    end
    else
      SQL.Text:= 'SELECT * FROM ' + TBName;
  end;
  NewDataSource:= TDataSource.Create(NewForm);
  with NewDataSource do
  begin
    DataSet:= NewSQLQuery;
  end;
  NewDBGrid.DataSource:= NewDataSource;
  NewSQLQuery.Active:= true;
  NewNavigator:= TDBNavigator.Create(NewForm);
  with NewNavigator do
  begin
    Parent:= NewForm;
    DataSource:= NewDataSource;
    Top:= 505;
    Left:= 65;
    Width:= 271;
    Height:= 30;
    Visible:= true;
  end;
  GetCaptionColumn();
end;

procedure TTable.CreateRef();
var
  i, k: integer;
  s: string;
begin
  for i:=0 to high(TableColumns) do
  begin
    s:= '';
    k:= 1;
    if CheckRef(TableColumns[i]) then
    begin
      if not isReferences then isReferences:= true;
      TableColumns[i].RefS:= true;
      while TableColumns[i].Name[k] <> '_'  do
      begin
        s+= TableColumns[i].Name[k];
        inc(k);
      end;
      TableColumns[i].RefTable:= s;
      s:= '';
      k+= 1;
      while k < length(TableColumns[i].Name) + 1  do
      begin
        s+= TableColumns[i].Name[k];
        k+= 1;
      end;
      TableColumns[i].RefField:= s;
    end;
  end;
end;

function TTable.GetCol(CName: string): TField;
var
  q: integer;
begin
  for q:=0 to high(TableColumns) do
    if TableColumns[q].FDName = CName then
    begin
      result:= TableColumns[q];
      break;
    end;
end;

procedure CreateTable (TableName: string);
var
  s: string;
begin
  s:= CreateItemName (TableName);
  SetLength(TableArr, length(TableArr) + 1);
  TableArr[high(TableArr)]:= TTable.Create;
  TableArr[high(TableArr)].Name:= s;
  TableArr[high(TableArr)].Caption:=TranslateList.Values[s];
  TableArr[high(TableArr)].CreateMenuItem(TranslateList.Values[s]);
  TableArr[high(TableArr)].CreateCaptionColumn(s);
end;

procedure TTable.CreateCaptionColumn(TableName: string);
var
  s: string;
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
  TempSQLQuery.Active:= false;
  TempSQLQuery.SQL.Text:=
    'select RDB$FIELD_NAME from rdb$relation_fields where RDB$RELATION_NAME = '
    + '''' + TableName + '''';
  TempSQLQuery.Open;
  while not TempSQLQuery.EOF do
  begin
    s:= CreateItemName(TempSQLQuery.Fields[0].AsString);
    SetLength(TableColumns, length(TableColumns) + 1);
    TableColumns[high(TableColumns)] := TField.Create;
    TableColumns[high(TableColumns)].Name:= s;
    TableColumns[high(TableColumns)].Caption:= TranslateList.Values[s];
    if s = 'ID' then
      TableColumns[high(TableColumns)].Width:= 40
    else
      TableColumns[high(TableColumns)].Width:= 200;
    TempSQLQuery.Next;
  end;
  TempSQLQuery.Close;
  TempDSource.Free;
  TempSQLQuery.Free;
  TempSQLTransaction.Free;
end;

procedure TTable.GetCaptionColumn();
var
  i: integer;
begin
  for i:=0 to NewDbGrid.Columns.Count-1 do
  begin
    NewDbGrid.Columns.Items[i].Title.Caption:= TableColumns[i].Caption;
    NewDbGrid.Columns.Items[i].Width:= TableColumns[i].Width;
  end;
end;

function TTable.GetForm(): TForm;
begin
  result:= NewForm;
end;

procedure TTable.FormClose(Sender: TObject; var CanClose: boolean);
begin
  NewForm:= nil;
  NewDBGrid:= nil;
  NewDataSource:= nil;
  NewSQLQuery:= nil;
  FStatus:= false;
end;

procedure TTable.DelForm (Sender: TObject);
begin
  NewForm:= nil;
  NewDBGrid:= nil;
  NewDataSource:= nil;
  NewSQLQuery:= nil;
  FStatus:= false;
end;

procedure TTable.OnClickMenuItem (Sender: TObject);
begin
  if FStatus then
    NewForm.Show
  else
    CreateForm(Sender);
end;

procedure TTable.CreateMenuItem (Caption: string);
begin
  NewMenuIten:= TMenuItem.Create(MainItem);
  NewMenuIten.Caption:= Caption;
  NewMenuIten.OnClick:= @OnClickMenuItem;
  MainItem.Add(NewMenuIten);
end;

function TTable.SQLGen ():TStringList;
var
  i, k, g: integer;
  a, b, res: TStringList;
  head: string;
  s1, s2, s3: String;
  output: text;
begin
  k:= 1;
  g:= 0;
  a:= TStringList.Create;
  b:= TStringList.Create;
  res:= TStringList.Create;
  head:= 'SELECT ';
  a.Append('FROM ' + TBName);
  for i:=0 to high(TableColumns) do
  begin
    if TableColumns[i].RefS then
    begin
      if g > 0 then head+= ', ';
      head+= TableColumns[i].RefTable + 'S.' +
        FindTableofName(TableColumns[i].RefTable + 'S').TableColumns[1].Name;
      inc(g);
      s1:= 'INNER JOIN ' + TableColumns[i].RefTable + 'S ON ' +
        TableColumns[i].RefTable + 'S.' + TableColumns[i].RefField +
        ' = ' + TBName + '.' + TableColumns[i].Name;
      b.add(s1);
      a.Append(b.text);
      b.clear;
    end
    else
    begin
      head+= ' ' + TableColumns[i].Name;
    end;
  end;
  res.Append(head);
  res.Append(a.text);
  result:= res;
end;

function TTable.GetColForNum (n: integer): TField;
begin
  result:= TableColumns[n];
end;

{Other functions and procedures}

function FindTableofName (TableName: string):TTable;
var
  i: integer;
begin
  for i:=0 to high(TableArr) do
    if TableArr[i].Name = TableName then
    begin
      result:= TableArr[i];
      break;
    end;
end;

 function CreateItemName (IName: string): string;
 var
   i: integer;
   s: string;
 begin
   for i:=1 to length(IName) do
   begin
     if IName[i] <> ' ' then
       s += IName[i]
     else
       break;
   end;
   result:= s;
 end;

 function CheckRef (TableColumns: TField):boolean;
var
  i: integer;
begin
  for i:=1 to length(TableColumns.Name) - 1 do
  begin
    if TableColumns.Name[i] = '_' then
    begin
      result:= true;
      exit;
    end;
  end;
  result:= false;
end;

end.

