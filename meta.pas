unit meta;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, DBGrids, Controls,
  Graphics, Dialogs, ExtCtrls, Menus, DbCtrls, Grids, DBConnection, FormGen,
  FormChangeData, StdCtrls, Buttons;

type

  TPointFilter = ^TFilter;
  TTypeField = (TInt, TStr);
  TTypeOrder = (Up, Down, None);
  TListDataFields = array of TStringList;

  { TField }

  TField = class
  private
    FCaption: string;
    FName: string;
    FWidth: integer;
    RefTable: string;
    RefField: string;
    RefNameField: string;
    RefCaption: string;
    RefType: TTypeField;
    FieldType: TTypeField;
    isReference: boolean;
    isOrder: TTypeOrder;
  published
    property Name: string read FName write FName;
    property Caption: string read FCaption write FCaption;
    property Width: integer read FWidth write FWidth;
    property RefS: boolean read isReference write isReference;
    property TypeField: TTypeField read FieldType write FieldType;
    property OrderStatus: TTypeOrder read isOrder write isOrder;
    property RType: TTypeField read RefType write RefType;
    property FType: TTypeField read FieldType write FieldType;
  end;

  { TTable }

  TTable = class
  private
    FName: string;
    FCaption: string;
    FForm: TFormTable;
    FFormChange: TFormChangeData1;
    TableColumns: array of TField;
    Filters: array of TFilter;
    TempArrData: TListDataFields;
    FormStatus: boolean;
    isReferences: boolean;
    isFiltred: boolean;
    isSort: boolean;
    isChanges: boolean;
  public
    procedure CreateForm (Sender: TObject);
    function GetForm(): TForm;
    procedure FormClose();
    procedure CreateCaptionColumn(TableName: string);
    procedure ChangeCaptionColumn();
    procedure CreateRef();
    function GetColForNum (n: integer): TField;
    function GetCol(CName: string): TField;
    function SQLGen ():TStringList;
    procedure DelFilter(Sender: TObject);
    procedure ApplyFilter (Sender: TObject);
    procedure AddFilter ();
    procedure AddQueryFilter ();
    procedure CreateQueryParams (APointer: TPointFilter);
    procedure OnColumnClick(ANum: integer);
    procedure OpenFormEditingTable (Index: integer;
      AChangeType: TChangeType);
    procedure FormChangeClose();
    function GetListDataFields(): TListDataFields;
    function GetListIdFields(): TListDataFields;
    function CreateSortQuery (): string;
    function GenQueryChanges(ATypeAction: TChangeType;
      AListData: TStringList): TStringList;
    procedure FormUpdateData();
    procedure DeleteArrData();
  published
    property Name: string read FName write FName;
    property Caption: string  read FCaption write FCaption;
    property FStatus: boolean  read FormStatus write FormStatus;
    property RefStatus: boolean read isReferences write isReferences;
    property FiltStatus: boolean read isFiltred write isFiltred;
    property SortStatus: boolean read isSort write isSort;
    property ChangeStatus: boolean read isChanges write isChanges;
  end;

var
  TableArr: array of TTable;
  TBConnection: TIBConnection;
  TranslateList: TStringList;
  ColWidth: integer;

procedure CreateTable (TableName: string);
function FindTableofName (TableName: string):TTable;
function CreateItemName (IName: string): string;
function CheckRef (TableColumns: TField):boolean;
function GenFreeId(): integer;
implementation

{Editing}

{select max(id) from groups}

function GenFreeId: integer;
var
  i, max, k: integer;
begin
  max:= 0;
  for i:=0 to high(TableArr) do
  begin
    if not TableArr[i].RefStatus then
    begin
      DataModule1.SQLQuery.Close;
      DataModule1.SQLQuery.SQL.Text:= 'select max(id) from ' + TableArr[i].Name;
      DataModule1.SQLQuery.Open;
      k:= DataModule1.SQLQuery.Fields[0].AsInteger;
      if k > max then
        max:= k;
    end;
  end;
  result:= max + 1;
end;

procedure TTable.FormChangeClose();
begin
  FFormChange.Free;
  isChanges:= false;
end;

procedure TTable.FormUpdateData();
begin
  FForm.FSQLQuery.Close;
  FForm.FSQLQuery.Open;
  isChanges:= false;
  ChangeCaptionColumn();
end;

procedure TTable.DeleteArrData();
var
  i: integer;
begin
 for i:=0 to high(TempArrData) do
   TempArrData[i].Free;
end;

function TTable.GenQueryChanges(ATypeAction: TChangeType;
  AListData: TStringList): TStringList;
var
  temp: TStringList;
  temp1: TListDataFields;
  s1, s2, s3: string;
  i: integer;
begin
  temp:= TStringList.Create;
  case ATypeAction of
  ctEdit, ctEditBox:
  begin
    s1:= 'UPDATE ' + FName + ' SET ';
    for i:=0 to AListData.Count - 1 do
    begin
      s1:= s1 + TableColumns[i].Name + ' = ' + '''' + AListData[i] + '''';
      if i <> AListData.Count - 1 then
        s1+= ', ';
    end;
    temp.Append(s1);
    if ATypeAction = ctEditBox then
    begin
      temp1:= GetListIdFields;
      s1:= '';
      for i:=0 to AListData.Count - 1 do
      begin
        s3:= string(FForm.FSQLQuery.Fields.FieldByNumber(i + 1).Value);
        s1:= s1 + TableColumns[i].Name + ' = ' + '''' +
          temp1[i].ValueFromIndex[FFormChange.ArrComboBox[i].Items.IndexOf(s3)] + '''';
        if i <> AListData.Count - 1 then
          s1+= 'and ';
      end;
      temp.Append('WHERE ' + s1);
    end
    else
      temp.Append('WHERE ' + TableColumns[0].Name +
        ' = ' + '''' + AListData[0] + '''');
  end;
  ctInsert, ctInsertBox:
  begin
    s1:= 'INSERT INTO ' + FName;
    for i:=0 to AListData.Count - 1 do
    begin
      s2:= s2 + TableColumns[i].Name;
      if i <> AListData.Count - 1 then
        s2+= ', ';
      s3:= s3 + '''' + AListData[i] + '''';
      if i <> AListData.Count - 1 then
        s3+= ', ';
    end;
    s1+= ' (' + s2 + ')';
    temp.Append(s1);
    temp.Append('VALUES (' + s3 + ')');
    ShowMessage(temp.text);
  end;
  end;
  result:= temp;
end;

procedure TTable.OpenFormEditingTable (Index: integer;
  AChangeType: TChangeType);
var
  i, k: integer;
  s: string;
begin
  if isChanges then
  begin
    FFormChange.Show;
    exit;
  end;
  isChanges:= true;
  FFormChange:= TFormChangeData1.Create(Application);
  FFormChange.Tag:= FForm.Tag;
  FFormChange.FAction:= AChangeType;
  FFormChange.BorderStyle:= bsSingle;
  TempArrData:= GetListDataFields;
  case AChangeType of
  ctEditBox, ctInsertBox:
  begin
    SetLength(FFormChange.ArrComboBox, length(TableColumns));
    for i:=0 to high(FFormChange.ArrComboBox) do
    begin
      FFormChange.CreateFormReWriteData(i, TableColumns[i].Width);
      for k:= 0 to TempArrData[i].Count - 1 do
        FFormChange.ArrComboBox[i].Items.Add(TempArrData[i].ValueFromIndex[k]);
      FFormChange.ArrComboBox[i].ItemIndex:=
        TempArrData[i].IndexOf(
        String(FForm.FSQLQuery.Fields.FieldByNumber(i + 1).Value));
    end;
    if AChangeType = ctEditBox then
       s:= 'Добавление записи'
    else
      for i:=1 to length(TableColumns) do
        s:= s + String(FForm.FSQLQuery.Fields.FieldByNumber(i).Value) + '|';
    FFormChange.Caption:= s;
  end;
  ctEdit:
  begin
    for i:=1 to length(TableColumns) do
      s:= s + String(FForm.FSQLQuery.Fields.FieldByNumber(i).Value) + '|';
    FFormChange.Caption:= s;
    SetLength(FFormChange.ArrEdits, length(TableColumns));
    for i:=0 to high(FFormChange.ArrEdits) do
    begin
      FFormChange.CreateFormEditData(i, TableColumns[i].Width);
      FFormChange.ArrEdits[i].Text:=
        String(FForm.FSQLQuery.Fields.FieldByNumber(i + 1).Value);
    end;
    FFormChange.ArrEdits[0].Enabled:= false;
  end;
  ctInsert:
  begin
    SetLength(FFormChange.ArrEdits, length(TableColumns));
    for i:=0 to high(FFormChange.ArrEdits) do
      FFormChange.CreateFormEditData(i, TableColumns[i].Width);
    FFormChange.ArrEdits[0].Enabled:= false;
    FFormChange.ArrEdits[0].Text:= IntToStr(GenFreeId);
    FFormChange.Caption:= FFormChange.ArrEdits[0].Text;
  end;
  end;
  FFormChange.CreateBtn;
  FFormChange.Show;
end;

function TTable.GetListDataFields(): TListDataFields;
var
  TempArr: TListDataFields;
  i: integer;
  s, s1: string;
begin
  DataModule1.SQLQuery.Close;
  SetLength(TempArr, Length(TableColumns));
  for i:=0 to high(TableColumns) do
    TempArr[i]:= TStringList.Create;
  if isReferences then
  begin
    for i:=0 to high(TableColumns) do
    begin
      DataModule1.SQLQuery.Close;
      DataModule1.SQLQuery.SQL.Text:= 'select ' + TableColumns[i].RefNameField
        + ' from ' + TableColumns[i].RefTable + 'S';
      DataModule1.SQLQuery.Open;
      while not DataModule1.SQLQuery.EOF do
      begin
        TempArr[i].Append(DataModule1.SQLQuery.Fields[0].AsString);
        DataModule1.SQLQuery.Next;
      end;
    end;
  end
  else
  begin
    DataModule1.SQLQuery.SQL.Text:= 'select * from ' + FName;
    DataModule1.SQLQuery.Open;
    while not DataModule1.SQLQuery.EOF do
    begin
      for i:=0 to high(TableColumns) do
        TempArr[i].Append(DataModule1.SQLQuery.Fields[i].AsString);
      DataModule1.SQLQuery.Next;
    end;
  end;
  DataModule1.SQLQuery.Close;
  result:= TempArr;
end;

function TTable.GetListIdFields(): TListDataFields;
var
  TempArr: TListDataFields;
  i: integer;
  s, s1: string;
begin
  DataModule1.SQLQuery.Close;
  SetLength(TempArr, Length(TableColumns));
  for i:=0 to high(TableColumns) do
    TempArr[i]:= TStringList.Create;
  for i:=0 to high(TableColumns) do
  begin
    DataModule1.SQLQuery.Close;
    DataModule1.SQLQuery.SQL.Text:= 'select id from ' +
      TableColumns[i].RefTable + 'S';
    DataModule1.SQLQuery.Open;
    while not DataModule1.SQLQuery.EOF do
    begin
      TempArr[i].Append(DataModule1.SQLQuery.Fields[0].AsString);
      DataModule1.SQLQuery.Next;
    end;
  end;
  DataModule1.SQLQuery.Close;
  result:= TempArr;
end;

{Filters}

procedure TTable.AddFilter ();
var
  TempList: TStringList;
  i: integer;
begin
  if length(Filters) > 12 then exit;
  SetLength(Filters, length(Filters) + 1);
  Filters[high(Filters)]:= TFilter.Create;
  Filters[high(Filters)].CreateFilter(FForm.FilterPanel, high(Filters));
  TempList:= TStringList.Create;
  for i:=0 to FForm.FDBGrid.Columns.Count - 1 do
  begin
    if TableColumns[i].isReference then
      TempList.Append(TableColumns[i].RefCaption)
    else
      TempList.Append(TableColumns[i].Caption)
  end;
  Filters[high(Filters)].FillCB(TempList);
  TempList.Destroy;
end;

procedure TTable.DelFilter(Sender: TObject);
var
  i, k: integer;
begin
  k:= (Sender as TSpeedButton).Tag;
  Filters[k].DestroyFilter;
  for i:= k to high(Filters) - 1 do
  begin
    Filters[i]:= Filters[i + 1];
    Filters[i + 1]:= nil;
    Filters[i].ChangePos(i);
    if Filters[i].isApply then
    begin
      Filters[i].Parametr.Name:= 'param' + IntToStr(i);
      CreateQueryParams(@Filters[i]);
    end;
  end;
  if length(Filters) = 1 then
  begin
    Self.isFiltred:= false;
  end;
  SetLength(Filters, length(Filters) - 1);
  AddQueryFilter;
end;

procedure TTable.ApplyFilter (Sender: TObject);
var
  k: integer;
  temp: ^TFilter;
begin
  temp:= @Filters[(Sender as TSpeedButton).Tag];
  temp^.isApply:= true;
  temp^.Parametr:= TParametr.Create;
  temp^.Parametr.Name:= 'param' + IntToStr((Sender as TSpeedButton).Tag);
  temp^.Parametr.NameAction:= temp^.ActionBox.Text;
  temp^.Parametr.Value:= temp^.ValueEdit.Text;
  k:= temp^.NameBox.ItemIndex;
  temp^.Parametr.Num:= k;
  if (Self).RefStatus then
  begin
    temp^.Parametr.NameField:=
      TableColumns[k].RefTable  + 'S.' + TableColumns[k].RefNameField;
  end
  else
    temp^.Parametr.NameField:= FName + '.' + TableColumns[k].Name;
  CreateQueryParams(temp);
  AddQueryFilter;
end;

 {TTable/Create Form}

procedure TTable.CreateForm (Sender: TObject);
begin
  SetLength(Filters, 0);
  FForm:= TFormTable.Create(Application);
  FForm.Tag:= (Sender as TMenuItem).Tag;
  FForm.EditBtn.Tag:= FForm.Tag;
  FForm.InsertBtn.Tag:= FForm.Tag;
  FForm.DeleteBtn.Tag:= FForm.Tag;
  FForm.Caption:= FCaption;
  if isReferences then
    FForm.FSQLQuery.SQL.Text:= SQLGen.Text
  else
    FForm.FSQLQuery.SQL.Text:= 'SELECT * FROM ' + FName;
  FForm.FSQLQuery.Active:= true;
  ChangeCaptionColumn();
  FStatus:= true;
  FForm.Show;
end;

procedure TTable.OnColumnClick(ANum: integer);
var
  s: string;
begin
  case TableColumns[ANum].isOrder of
    Up: TableColumns[ANum].isOrder:= Down;
    Down: TableColumns[ANum].isOrder:= None;
    None: TableColumns[ANum].isOrder:= Up;
  end;
  FForm.FSQLQuery.Active:= false;
  s:= CreateSortQuery;
  if Self.isSort then
  begin
    FForm.FSQLQuery.SQL.Delete(FForm.FSQLQuery.SQL.Count - 1);
    if s <> '' then
      FForm.FSQLQuery.SQL.Append(CreateSortQuery)
    else
      Self.isSort:= false;
  end
  else
  begin
    if s <> '' then
    begin
      FForm.FSQLQuery.SQL.Append(s);
      Self.isSort:= true;
    end
  end;
  FForm.FSQLQuery.Active:= true;
  ChangeCaptionColumn();
end;

procedure TTable.CreateRef();
var
  i, k: integer;
  s, t: string;
begin
  for i:=0 to high(TableColumns) do
  begin
    s:= '';
    t:= '';
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
      TableColumns[i].RType:=
        FindTableofName(TableColumns[i].RefTable + 'S').GetColForNum(1).FType;
      TableColumns[i].RefNameField:=
        FindTableofName(TableColumns[i].RefTable + 'S').GetColForNum(1).Name;
      k:= 1;
      while TableColumns[i].Caption[k] <> '_' do
      begin
        t += TableColumns[i].Caption[k];
        inc(k);
      end;
      if t = 'Преподаватель' then
        TableColumns[i].RefCaption:= t + '_Имя'
      else if t = 'Пара' then
        TableColumns[i].RefCaption:= t + '_Номер'
      else
        TableColumns[i].RefCaption:= t + '_Название'
    end;
  end;
end;


procedure TTable.CreateCaptionColumn(TableName: string);
var
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
    '''' + TableName + '''';
  TempSQLQuery.Open;
  while not TempSQLQuery.EOF do
  begin
    s:= CreateItemName(TempSQLQuery.Fields[0].AsString);
    SetLength(TableColumns, length(TableColumns) + 1);
    TableColumns[high(TableColumns)] := TField.Create;
    TableColumns[high(TableColumns)].isOrder:= none;
    TableColumns[high(TableColumns)].Name:= s;
    TableColumns[high(TableColumns)].Caption:= TranslateList.Values[s];
    if TempSQLQuery.Fields[1].AsInteger = 8 then
      TableColumns[high(TableColumns)].FType:= TInt
    else
      TableColumns[high(TableColumns)].FType:= TStr;
    t:= FName + '||' + s;
    if s = 'ID' then
      TableColumns[high(TableColumns)].Width:= 40
    else
      TableColumns[high(TableColumns)].Width:= StrToInt(TranslateList.Values[t]);
    TempSQLQuery.Next;
  end;
  TempSQLQuery.Close;
  TempDSource.Free;
  TempSQLQuery.Free;
  TempSQLTransaction.Free;
end;

procedure TTable.ChangeCaptionColumn();
var
  i: integer;
begin
  for i:=0 to FForm.FDBGrid.Columns.Count-1 do
  begin
    if TableColumns[i].isReference then
      FForm.FDBGrid.Columns.Items[i].Title.Caption:=
        TableColumns[i].RefCaption
    else
      FForm.FDBGrid.Columns.Items[i].Title.Caption:=
        TableColumns[i].Caption;
    case TableColumns[i].isOrder of
      Down: FForm.FDBGrid.Columns.Items[i].Title.Caption:=
        FForm.FDBGrid.Columns.Items[i].Title.Caption + ' ↓ ';
      Up: FForm.FDBGrid.Columns.Items[i].Title.Caption:=
        FForm.FDBGrid.Columns.Items[i].Title.Caption + ' ↑ ';
    end;
    FForm.FDBGrid.Columns.Items[i].Width:= TableColumns[i].Width;
  end;
end;

function TTable.GetForm(): TForm;
begin
  result:= FForm;
end;

procedure TTable.FormClose();
var
  i: integer;
begin
  FForm:= nil;
  for i:=0 to high(Filters) do
    Filters[i].DestroyFilter;
  SetLength(Filters, 0);
  FStatus:= false;
  FiltStatus:= false;
end;

function TTable.GetColForNum (n: integer): TField;
begin
  result:= TableColumns[n];
end;

function TTable.GetCol(CName: string): TField;
var
  q: integer;
begin
  for q:=0 to high(TableColumns) do
    if TableColumns[q].FName = CName then
    begin
      result:= TableColumns[q];
      break;
    end;
end;

procedure CreateTable (TableName: string);
begin
  SetLength(TableArr, length(TableArr) + 1);
  TableArr[high(TableArr)]:= TTable.Create;
  TableArr[high(TableArr)].Name:= TableName;
  TableArr[high(TableArr)].Caption:=TranslateList.Values[TableName];
  TableArr[high(TableArr)].CreateCaptionColumn(TableName);
end;

{ Query Generation}

function TTable.SQLGen ():TStringList;
var
  i, g: integer;
  a, b, res: TStringList;
  head: string;
  s1: String;
begin
  g:= 0;
  a:= TStringList.Create;
  b:= TStringList.Create;
  res:= TStringList.Create;
  head:= 'SELECT ';
  a.Append('FROM ' + FName);
  for i:=0 to high(TableColumns) do
  begin
    if i > 0 then head+= ', ';
    if TableColumns[i].RefS then
      begin
        head+= TableColumns[i].RefTable + 'S.' +
          FindTableofName(TableColumns[i].RefTable + 'S').TableColumns[1].Name;
        inc(g);
        s1:= 'INNER JOIN ' + TableColumns[i].RefTable + 'S ON ' +
          TableColumns[i].RefTable + 'S.' + TableColumns[i].RefField +
          ' = ' + FName + '.' + TableColumns[i].Name;
        b.Append(s1);
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

function TTable.CreateSortQuery (): string;
var
  i, c: integer;
   s, ts: string;
begin
  c:= 0;
  for i:= 0 to high(TableColumns) do
  begin
    ts:= '';
    case TableColumns[i].isOrder of
      Up:
        begin
          if TableColumns[i].RefS then
            ts:= TableColumns[i].RefTable + '_' +
              TableColumns[i].RefField + ' ASC'
          else
            ts:= FName + '.' + TableColumns[i].Name + ' ASC';
          if c <> 0 then
            s:= s + ',' + ts
          else
            s:= s + ts;
          inc(c);
        end;
      Down:
        begin
          if TableColumns[i].RefS then
            ts:= TableColumns[i].RefTable + '_' +
              TableColumns[i].RefField + ' DESC'
          else
            ts:= FName + '.' + TableColumns[i].Name + ' DESC';
          if c <> 0 then
            s:= s + ',' + ts
          else
            s:= s + ts;
          inc(c);
        end;
    end;
  end;
  if c <> 0 then
    s:= 'ORDER BY ' + s;
  result:= s;
end;

procedure TTable.CreateQueryParams (APointer: TPointFilter);
begin
  if APointer^.Parametr.NameAction = ActionArr[6] then
  begin
    APointer^.Parametr.Query:= APointer^.Parametr.NameField + ' ' +
      'LIKE :' + APointer^.Parametr.Name + ' ';
    APointer^.Parametr.Like:= true;
  end
  else
    APointer^.Parametr.Query:= APointer^.Parametr.NameField + ' ' +
      APointer^.Parametr.NameAction + ' ' + ':' + APointer^.Parametr.Name + ' ';
end;

procedure TTable.AddQueryFilter ();
var
  i, c: integer;
  isWasFirst: boolean = false;
begin
  FForm.FSQLQuery.Active:= false;
  FForm.FSQLQuery.SQL.Text:= '';
  for i:=0 to high(Filters) do
  begin
    if Filters[i].isApply then
    begin
      inc(c);
      if not isWasFirst then
      begin
        if Self.isReferences then
          FForm.FSQLQuery.SQL.Text:= SQLGen.Text + ' ' +
            ' where ' +  Filters[i].Parametr.Query
        else
          FForm.FSQLQuery.SQL.Text:= 'SELECT * FROM ' + FName +
            ' where ' +  Filters[i].Parametr.Query;
      end
      else
        FForm.FSQLQuery.SQL.Text:= FForm.FSQLQuery.SQL.Text +
          ' and ' + Filters[i].Parametr.Query;
      if Filters[i].Parametr.Like then
        FForm.FSQLQuery.ParamByName(Filters[i].Parametr.Name).AsString:= '%' +
          Filters[i].Parametr.Value + '%'
      else
      begin
        FForm.FSQLQuery.ParamByName(Filters[i].Parametr.Name).AsString:=
          Filters[i].Parametr.Value;
      end;
      isWasFirst:= true;
    end;
  end;
  if FForm.FSQLQuery.SQL.Text = '' then
    if isReferences then
      FForm.FSQLQuery.SQL.Text:= SQLGen.Text
    else
      FForm.FSQLQuery.SQL.Text:= 'SELECT * FROM ' + FName;
  FForm.FSQLQuery.SQL.Append(CreateSortQuery);
  FForm.FSQLQuery.Active:= true;
  ChangeCaptionColumn();
  FiltStatus:= true;
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

