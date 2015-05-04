unit meta;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, DBGrids, Controls,
  Graphics, Dialogs, ExtCtrls, Menus, DbCtrls, Grids, DBConnection,
  StdCtrls, Buttons;

type

  TTypeField = (TInt, TStr);
  TListDataFields = array of TStringList;
  TTypeOrder = (None, Up, Down);

  { TMField }

  TMField = class
  private
    FName: string;
    FCaption: string;
    FWidth: integer;
    FTableTag: integer;
    FType: TTypeField;
    FReference: TMField;
    FOrderStatus: TTypeOrder;
  published
    property Name: string read FName write FName;
    property Caption: string read FCaption write FCaption;
    property Width: integer read FWidth write FWidth;
    property TableTag: integer read FTableTag write FTableTag;
    property FieldType: TTypeField read FType write FType;
    property Reference: TMField read FReference write FReference;
    property isOrder: TTypeOrder read FOrderStatus write FOrderStatus;
  end;

  { TMTable }

  TMTable = class
    Fields: array of TMField;
  private
    FName: string;
    FCaption: string;
    FRefFields: boolean;
  public
    procedure FillDataTable (ANameTable: string);
    procedure FillDataFields (ANameTable: string);
    procedure FillReferencedField ();
    function GetDataFieldOfIndex (AIndex: integer): TStringList;
    function FindFieldOfName (AName: string): TMField;
  published
    property Name: string read FName write FName;
    property Caption: string read FCaption write FCaption;
    property isRefFields: boolean read FRefFields write FRefFields;
  end;

  { TMeta }

  TMeta = class
    MetaTables: array of TMTable;
  public
    function FindTableOfName (AName: string): TMTable;
  end;

var
  TBConnection: TIBConnection;
  TranslateList: TStringList;
  ColWidth: integer;
  MetaData: TMeta;

function CreateItemName (IName: string): string;
function CheckReference (AName: string): integer;
implementation

{ TMeta procedure }

function TMeta.FindTableOfName (AName: string): TMTable;
var
  i: integer = 0;
begin
  while i < length(MetaTables) do
  begin
    if MetaTables[i].Name = AName then
      exit(MetaTables[i]);
    inc(i);
  end;
  result:= nil;
end;

{ TMtable procedure }

 function TMTable.GetDataFieldOfIndex (AIndex: integer): TStringList;
 var
   i: integer;
   temp: TStringList;
 begin
   temp:= TStringList.Create;
   DataModule1.SQLQuery.Close;
   DataModule1.SQLQuery.SQL.Text:= 'SELECT * FROM ';
   if Fields[AIndex].Reference <> nil then
     DataModule1.SQLQuery.SQL.Text:= DataModule1.SQLQuery.SQL.Text +
       MetaData.MetaTables[Fields[AIndex].Reference.TableTag].Name
   else
     DataModule1.SQLQuery.SQL.Text:= DataModule1.SQLQuery.SQL.Text +
       MetaData.MetaTables[Fields[AIndex].TableTag].Name;
   DataModule1.SQLQuery.Open;
   while not DataModule1.SQLQuery.EOF do
   begin
     temp.Append(DataModule1.SQLQuery.Fields[1].AsString);
     DataModule1.SQLQuery.Next;
   end;
   result:= temp;
 end;

 procedure TMTable.FillDataTable(ANameTable: string);
 begin
   FName:= ANameTable;
   FCaption:= TranslateList.Values[ANameTable];
   FillDataFields(ANameTable);
 end;

 procedure TMTable.FillDataFields (ANameTable: string);
 var
   i: integer;
   s, t: string;
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
     'select  R.RDB$FIELD_NAME, F.RDB$FIELD_TYPE ' +
     'from RDB$FIELDS F, RDB$RELATION_FIELDS R where F.RDB$FIELD_NAME = ' +
     'R.RDB$FIELD_SOURCE and R.RDB$SYSTEM_FLAG = 0 and RDB$RELATION_NAME = ' +
     '''' + ANameTable + '''';
   TempSQLQuery.Open;
   while not TempSQLQuery.EOF do
   begin
     s:= CreateItemName(TempSQLQuery.Fields[0].AsString);
     SetLength(Fields, length(Fields) + 1);
     Fields[high(Fields)]:= TMField.Create;
     Fields[high(Fields)].Name:= s;
     Fields[high(Fields)].Caption:= TranslateList.Values[s];
     Fields[high(Fields)].TableTag:= high(MetaData.MetaTables);
     if TempSQLQuery.Fields[1].AsInteger = 8 then
       Fields[high(Fields)].FType:= TInt
     else
       Fields[high(Fields)].FType:= TStr;
     t:= FName + '||' + s;
     if s = 'ID' then
       Fields[high(Fields)].Width:= 40
     else
       Fields[high(Fields)].Width:= StrToInt(TranslateList.Values[t]);
     TempSQLQuery.Next;
   end;
   TempSQLQuery.Close;
   TempDSource.Free;
   TempSQLQuery.Free;
   TempSQLTransaction.Free;
 end;

 procedure TMTable.FillReferencedField ();
 var
   i, k, n: integer;
   s, s1: string;
 begin
   for i:= 0 to high(Fields) do
   begin
     n:= CheckReference(Fields[i].Name);
     if n <> 0 then
     begin
       for k:= 1 to n - 1 do
         s+= Fields[i].Name[k];
       for k:= n + 1 to length(Fields[i].Name) do
         s1+= Fields[i].Name[k];
       Fields[i].Reference:= TMField.Create;
       Fields[i].Reference:= MetaData.FindTableOfName(s + 'S').FindFieldOfName(s1);
       Fields[i].Caption:= TranslateList.Values['Caption_' + Fields[i].Name];
       FRefFields:= true;
     end;
     s:= '';
     s1:= '';
   end;
 end;

 function TMTable.FindFieldOfName (ANAme: string): TMField;
 var
   i: integer = 0;
 begin
   for i:= 0 to length(Fields) - 1 do
   begin
     if Fields[i].Name = AName then
       exit(Fields[i]);
   end;
   result:= nil;
 end;

 { Not Classes functions }

 function CheckReference (AName: string): integer;
 var
   i: integer = 0;
 begin
   while i <= length(AName) do
   begin
     if AName[i] = '_' then
       exit(i);
     inc(i);
   end;
 result:= 0;
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
end.

