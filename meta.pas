unit meta;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, DBGrids, ComCtrls, Menus, DbCtrls,
  Grids, DBConnection;

type
  TField = class
  private
    FDCaption: ansistring;
    FDName: ansistring;
    FDWidth: integer;
  published
    property Name: string read FDName write FDName;
    property Caption: string read FDCaption write FDCaption;
    property Width: integer read FDWidth write FDWidth;
  end;

  TTable = class
  private
    TBName: ansistring;
    TBCaption: ansistring;
    TBMenuIten: TMenuItem;
    TBColumns: array of TField;
    TBForm: TForm;
    TBDBGrid: TDBGrid;
    TBSQLQuery: TSQLQuery;
    TBDataSource: TDataSource;
    TBNavigator: TDBNavigator;
    FormStatus: boolean;
    isCallColumn: boolean;
  public
    procedure CreateForm (Sender: TObject);
    procedure DelForm (Sender: TObject);
    function GetForm(): TForm;
    procedure FormClose(Sender: TObject; var CanClose: boolean);
    procedure CreateMenuItem (Caption: string);
    procedure OnClickMenuItem (Sender: TObject);
    procedure CreateCaptionColumn();
    procedure GetCaptionColumn();
  published
    property Name: string read TBName write TBName;
    property Caption: string  read TBCaption write TBCaption;
    property FStatus: boolean  read FormStatus write FormStatus;
  end;

var
  TableArr: array of TTable;
  NameTable: array of TField;
  TBConnection: TIBConnection;
  MainItem: TMenuItem;
  TranslateList: TStringList;
  ColWidth: integer;

procedure CreateTable (TName: string);
function FindTableofName (TName: string):TTable;

implementation

procedure TTable.CreateForm (Sender: TObject);
begin
  TBForm:= TForm.Create(Application);
  with TBForm do
  begin
    Parent := nil;
    Caption:= (Sender as TMenuItem).Caption;
    Width:= 420;
    Height:= 550;
    OnCloseQuery:= @FormClose;
    BorderStyle:= bsSingle;
    Show;
  end;
  TBDBGrid:= TDBGrid.Create(TBForm);
  with TBDBGrid do
  begin
    Parent := TBForm;
    Width:= 400;
    Height:= 490;
    Left:= 10;
    Top:= 10;
    Visible:= true;
  end;
  FStatus:= true;
  TBSQLQuery:= TSQLQuery.Create(TBForm);
  with TBSQLQuery do
  begin
    DataBase:= DataModule1.IBConnection1;
    SQL.Text:= 'SELECT * FROM ' + TBName;
  end;
  TBDataSource:= TDataSource.Create(TBForm);
  with TBDataSource do
  begin
    DataSet:= TBSQLQuery;
  end;
  TBDBGrid.DataSource:= TBDataSource;
  TBSQLQuery.Active:= true;
  TBNavigator:= TDBNavigator.Create(TBForm);
  with TBNavigator do
  begin
    Parent:= TBForm;
    DataSource:= TBDataSource;
    Top:= 505;
    Left:= 65;
    Width:= 271;
    Height:= 30;
    Visible:= true;
  end;
  if not(isCallColumn) then
    CreateCaptionColumn();
  GetCaptionColumn()
end;

procedure TTable.CreateCaptionColumn();
var
  i: integer;
  s: ansistring;
begin
  isCallColumn:= true;
  for i:=0 to TBDbGrid.Columns.Count-1 do
  begin
    SetLength(TBColumns, length(TBColumns) + 1);
    TBColumns[high(TBColumns)] := TField.Create;
    TBColumns[high(TBColumns)].Name:= TBDbGrid.Columns.Items[i].Title.Caption;
    TBColumns[high(TBColumns)].Caption:=
      TranslateList.Values[TBDbGrid.Columns.Items[i].Title.Caption];
    if TBColumns[high(TBColumns)].Name = 'ID' then
      TBColumns[high(TBColumns)].Width:= 50
    else if TBColumns[high(TBColumns)].Name = 'NAME' then
      TBColumns[high(TBColumns)].Width:= 200
    else
      TBColumns[high(TBColumns)].Width:= 100
    end;
end;

procedure TTable.GetCaptionColumn();
var
  i: integer;
begin
  for i:=0 to TBDbGrid.Columns.Count-1 do
  begin
    TBDbGrid.Columns.Items[i].Title.Caption:= AnsiToUtf8(TBColumns[i].Caption);
    TBDbGrid.Columns.Items[i].Width:= TBColumns[i].Width;
  end;
end;

function TTable.GetForm(): TForm;
begin
  result:= TBForm;
end;

procedure TTable.FormClose(Sender: TObject; var CanClose: boolean);
begin
  TBForm:= nil;
  TBDBGrid:= nil;
  TBDataSource:= nil;
  TBSQLQuery:= nil;
  FStatus:= false;
end;

procedure TTable.DelForm (Sender: TObject);
begin
  TBForm:= nil;
  TBDBGrid:= nil;
  TBDataSource:= nil;
  TBSQLQuery:= nil;
  FStatus:= false;
end;

procedure TTable.OnClickMenuItem (Sender: TObject);
begin
  if FStatus then
    TBForm.Show
  else
    CreateForm (Sender);
end;

procedure TTable.CreateMenuItem (Caption: string);
begin
  TBMenuIten:= TMenuItem.Create(MainItem);
  TBMenuIten.Caption:= Caption;
  TBMenuIten.OnClick:= @OnClickMenuItem;
  MainItem.Add(TBMenuIten);
end;

procedure CreateTable (TName: string);
begin
  SetLength(TableArr, length(TableArr) + 1);
  TableArr[high(TableArr)]:= TTable.Create;
  TableArr[high(TableArr)].Name:= TName;
  TableArr[high(TableArr)].Caption:= AnsiToUtf8(TranslateList.Values[TName]);
  TableArr[high(TableArr)].CreateMenuItem (AnsiToUtf8(TranslateList.Values[TName]));
end;

function FindTableofName (TName: string):TTable;
var
  i: integer;
begin
  for i:=0 to high(TableArr) do
    if TableArr[i].Name = TName then
    begin
      result:= TableArr[i];
      break;
    end;
end;

end.
