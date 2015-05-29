unit GenerationForms;

{$mode objfpc}{$H+}{$M+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, Menus, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, FormChangeData,
  meta, SqlGenerator, DBConnection, windows;

type

  TArrayForms = array of TFormChangeData1;


  { TCommonClass }

  TCommonClass = class (TForm)

  end;

  { TParametr }

  TParametr = class
  private
    FPName: string;
    FNameField: string;
    FNumCol: integer;
    FNameAction: string;
    FValue: string;
    FQueryStr: string;
    isLike: boolean;
  published
    property NameField: string read FNameField write FNameField;
    property NameAction: string read FNameAction write FNameAction;
    property Value: string read FValue write FValue;
    property Query: string read FQueryStr write FQueryStr;
    property Like: boolean read isLike write isLike;
    property Num: integer read FNumCol write FNumCol;
    property Name: string read FPName write FPName;
  end;

  { TFilter}

  TFilter = class
    Panel: TPanel;
    NameBox: TComboBox;
    ActionBox: TComboBox;
    ValueEdit: TEdit;
    ApplyBtn: TSpeedButton;
    DelBtn: TSpeedButton;
    Parametr: TParametr;
  private
    AppStatus: boolean;
    FTag: integer;
  public
    procedure CreateFilter(APanel: TPanel; Count: integer); virtual;
    procedure CreateQueryParams (); virtual;
    procedure ChangePos (num: integer); virtual;
    procedure AppClick (Sender: TObject); virtual;
    procedure DelClick (Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer); virtual;
    procedure FillCB (AList: TStringList); virtual;
    procedure OnChangeParam (Sender: TObject); virtual;
    procedure EditKeyPress(Sender: TObject; var Key: char); virtual;
    destructor DestroyFilter (); virtual;
  published
    property isApply: boolean read AppStatus write AppStatus;
    property TagForm: integer read FTag write FTag;
  end;

  TFiltersArray = array of TFilter;

  { TEditingManager }

  TEditingManager = class
  private
    FFormsChange: TArrayForms;
  public
    procedure DelEditingForms ();
    procedure OpenFormEditingTable (AChangeType: TChangeType;
      ATag: integer; AList: TStringList);
    procedure InsertRecord(ATag: integer; AList: TStringList);
    procedure EditRecord(ATag: integer; AList: TStringList);
    procedure DeleteRecord(AId, ATag: integer);
    procedure CloseAllForms (ATag: integer);
    procedure FillComboBox(AList: TStringList; ANum: integer; Index: integer);
    function isFormOpenedForId(AId: integer): TFormChangeData1;
    function GetCountForms(): integer;
  end;

  { TFiltersManager }

  TFiltersManager = class
  private
    Filters: TFiltersArray;
    FFiltredStatus: boolean;
  public
    procedure AddFilter (APanel: TPanel; ATag: integer); virtual;
    procedure DelFilter(ATag: integer); virtual;
    procedure ApplyFilter(ATag, AIndex: integer); virtual;
    procedure GenQueryFilter (ASQLQuery: TSQLQuery; ATag: integer); virtual;
    function GenDataForCB(ATag: integer): TStringList; virtual;
    procedure SetCountFilters (ACount: integer); virtual;
    function GetCountFilters(): integer; virtual;
  published
    property isFiltred: boolean read FFiltredStatus write FFiltredStatus;
  end;

  { TFormTable }

  TFormTable = class(TForm)
    AddBtn: TBitBtn;
    FDataSource: TDataSource;
    FDBGrid: TDBGrid;
    FDBNavigator: TDBNavigator;
    FiltersPanel: TPanel;
    Label1: TLabel;
    FSQLQuery: TSQLQuery;
    FSQLTransaction: TSQLTransaction;
    InsertBtn: TSpeedButton;
    DeleteBtn: TSpeedButton;
    EditBtn: TSpeedButton;
    AddFiltersPanelBtn: TSpeedButton;
    procedure AddBtnClick(Sender: TObject);
    procedure AddFiltersPanelBtnClick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FDBGridColumnSized(Sender: TObject);
    procedure FDBGridDblClick(Sender: TObject);
    procedure FDBGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure InsertBtnClick(Sender: TObject);
    procedure TitleClick(AColumn: TColumn);
    procedure SetParams (Sender: TObject);
  private
    FSortedStatus: boolean;
    FUpdate: TChangeEvent;
  public
    FiltersManager: TFiltersManager;
    EditingManager: TEditingManager;
    procedure DelFilter(ATag: integer);
    procedure ApplyFilter(Sender: TObject);
    procedure AddQueryFilter ();
    procedure ChangeCaptionColumn();
    procedure OnColumnClick(ANum: integer);
    procedure InvalidateDBGrid(ATag: integer);
  published
    property isSorted: boolean read FSortedStatus write FSortedStatus;
    property Update: TChangeEvent read FUpdate write FUpdate;
  end;

  { TFormsOfTables }

  TFormsOfTables = class
  public
    FForms: array of TFormTable;
    constructor Create;
    procedure UpdateDataEditingForms (ATag: integer);
  end;

var
  FormsOfTables: TFormsOfTables;
  ActionArr: array[0..6] of string = ('<', '>', '>=', '<=', '=',
    '<>', 'включает');
  MarginLeft: integer = 50;

procedure FDelEditingForm (Sender: TObject);
procedure GlobalUpdate(ATag: integer);
implementation
uses Utimetableform;
var
  KoY: integer;

{$R *.lfm}

{ Other Function }

procedure GlobalUpdate(ATag: integer);
begin
  if FormsOfTables.FForms[ATag] <> nil then
    FormsOfTables.FForms[ATag].InvalidateDBGrid(ATag);
  If TimetableForm <> nil then
    TimetableForm.FillGridData
end;

procedure FDelEditingForm (Sender: TObject);
begin
  if FormsOfTables.FForms[(Sender as TForm).Tag] <> nil then
    FormsOfTables.FForms[(Sender as TForm).Tag].EditingManager.DelEditingForms
  else
    TimetableForm.EditingManager.DelEditingForms;
end;

{ TEditingManager }

procedure TEditingManager.FillComboBox(AList: TStringList; ANum: integer;
  Index: integer);
begin
  FFormsChange[Index].FillComboBox(AList, ANum);
end;

procedure TEditingManager.CloseAllForms (ATag: integer);
var
  i: integer;
begin
  for i:=0 to high(FFormsChange) do
    FFormsChange[i].Free;
end;

function TEditingManager.GetCountForms(): integer;
begin
   result:= length(FFormsChange);
end;

procedure TEditingManager.DelEditingForms ();
var
  i, k: integer;
begin
  if length(FFormsChange) = 0 then exit;
  for i:= 0 to high(FFormsChange) do
    if not FFormsChange[i].Visible then
    begin
      FFormsChange[i].Free;
      for k:= i to high(FFormsChange) - 1 do
      begin
        FFormsChange[k]:= FFormsChange[k + 1];
        FFormsChange[k].ArrControls[0].Tag:= k;
        FFormsChange[k + 1]:= nil;
      end;
      break;
    end;
  SetLength(FFormsChange, length(FFormsChange) - 1);
end;

procedure TEditingManager.OpenFormEditingTable (AChangeType: TChangeType;
  ATag: integer; AList: TStringList);
var
  i, k, j: integer;
  s: string;
  temp: TStringList;
  TempControl: array of TControl;
begin
  Randomize;
  SetLength(FFormsChange, length(FFormsChange) + 1);
  FFormsChange[high(FFormsChange)]:= TFormChangeData1.Create(Application);
  with FFormsChange[high(FFormsChange)] do
  begin
    Tag:= ATag;
    Left:= high(FFormsChange)*MarginLeft;
    Top:= ATag*Height;
    FAction:= AChangeType;
    BorderStyle:= bsSingle;
    if AList.Count <> 0 then
      IdLabel.Tag:= StrToInt(AList[0]);
    temp:= TStringList.Create;
    k:= GenUniqId;
    s:= '';
    with MetaData.MetaTables[ATag] do
    begin
    for i:= 0 to high(MetaData.MetaTables[ATag].Fields) do
      begin
        if Fields[i].Caption <> 'ИН' then
        begin
          temp:= GetDataFieldOfIndex(i);
          SetLength(ArrControls, length(ArrControls) + 1);
          if Fields[i].Reference <> nil then
          begin
            CreateComboBox(temp, Fields[i].Caption, Fields[i].Width);
            k:= high(ArrControls);
            if AChangeType = ctEdit then
              (ArrControls[k] as TComboBox).ItemIndex:= temp.IndexOf(Alist[i])
            else
              (ArrControls[k] as TComboBox).ItemIndex:= Random(temp.Count);
          end
          else
          begin
            CreateEdit(Fields[i].Caption, Fields[i].Width);
            k:= high(ArrControls);
            (ArrControls[k] as TEdit).Text:= Alist[i];
          end;
        end;
        if AChangeType = ctEdit then
          Caption:= 'Редактирование записи'
        else
          Caption:= 'Новая запись';
      end;
    end;
    ArrControls[0].Tag:= high(FFormsChange);
    CreateBtn;
    Show;
  end;
end;

procedure TEditingManager.InsertRecord(ATag: integer; AList: TStringList);
var
 temp: TFormChangeData1;
begin
  OpenFormEditingTable(ctInsert, ATag, AList)
end;

procedure TEditingManager.EditRecord(ATag: integer; AList: TStringList);
var
 temp: TFormChangeData1;
begin
 temp:= isFormOpenedForId(StrToInt(AList[0]));
 if temp = nil then
 begin
   if trunc(KoY/20) = 0 then exit;
   OpenFormEditingTable(ctEdit, ATag, AList);
 end
 else
   temp.show;
end;

procedure TEditingManager.DeleteRecord(AId, ATag: integer);
var
 i: LongInt;
 temp: TFormChangeData1;
begin
 DataModule1.SQLQuery.Close;
 DataModule1.SQLQuery.SQL.Text:= 'DELETE FROM ' + MetaData.MetaTables[ATag].Name
   + ' WHERE ID = ' + IntToStr(AId);
 i:= MessageDLG('Вы действительно хотите удалить эту запись?',
     mtConfirmation, mbYesNoCancel, 0);
 if i = mrYes then
 begin
   try
     DataModule1.SQLQuery.ExecSQL;
     //DataModule1.SQLTransaction1.Commit;
     temp:= isFormOpenedForId(AId);
     if temp <> nil then
       temp.close;
     //FormsOfTables.FForms[ATag].InvalidateDBGrid(ATag);
   except
     MessageDLG('Невозможно удалить эту запись т.к. она используется другой таблицей',
     mtError,[mbYes], 0);
   end;
 end;
 GlobalUpdate(ATag);
end;

function TEditingManager.isFormOpenedForId(AId: integer): TFormChangeData1;
var
  i, k: integer;
begin
  k:= -1;
  for i:=0 to high(FFormsChange) do
    if FFormsChange[i].IdLabel.Tag = AId then
      exit(FFormsChange[i]);
  result:= nil;
end;

{ Editing }

procedure TFormTable.InsertBtnClick(Sender: TObject);
var
  i: integer;
  temp: TStringList;
begin
 temp:= TStringList.Create;
 for i:=0 to FSQLQuery.Fields.Count - 1 do
   temp.Append(string(FSQLQuery.Fields.Fields[i].Value));
 EditingManager.InsertRecord(Tag, temp);
end;

procedure TFormTable.EditBtnClick(Sender: TObject);
var
  i: integer;
  temp: TStringList;
begin
  temp:= TStringList.Create;
  for i:=0 to FSQLQuery.Fields.Count - 1 do
    temp.Append(string(FSQLQuery.Fields.Fields[i].Value));
  EditingManager.EditRecord(Tag, temp);
end;

procedure TFormTable.DeleteBtnClick(Sender: TObject);
begin
  if FSQLQuery.Fields.FieldByNumber(1).Value = Null then exit;
  EditingManager.DeleteRecord(FSQLQuery.Fields.FieldByNumber(1).Value,
    Tag);
end;

procedure TFormTable.FDBGridDblClick(Sender: TObject);
begin
  EditBtnClick(Sender);
end;

procedure TFormTable.FDBGridColumnSized(Sender: TObject);
var
 i: integer;
begin
  for i:=0 to FDBGrid.Columns.Count - 1 do
  begin
    MetaData.MetaTables[Tag].Fields[i].Width:= FDBGrid.Columns.Items[i].Width;
    if MetaData.MetaTables[Tag].Fields[i].Reference <> nil then
      MetaData.MetaTables[Tag].Fields[i].Reference.Width:=
        FDBGrid.Columns.Items[i].Width;
  end;
end;

{ TFormsOfTables }

constructor TFormsOfTables.Create;
begin
  SetLength(FForms, length(MetaData.MetaTables));
end;

procedure TFormsOfTables.UpdateDataEditingForms (ATag: integer);
var
  i, k, h, g: integer;
  temp: TStringList;
  s, s1: string;
begin
  temp:= TStringList.Create;
  for k:= 0 to high(MetaData.MetaTables) do
    if MetaData.MetaTables[k].isRefFields then
    begin
      if FForms[k] <> nil then
      begin
        if FForms[k].EditingManager.GetCountForms <> 0 then
        begin
          temp:= MetaData.MetaTables[ATag].GetDataFieldOfIndex(1);
          for i:= 1 to high(MetaData.MetaTables[k].Fields) do
            if MetaData.MetaTables[k].Fields[i].Reference <> nil then
              if MetaData.MetaTables[k].Fields[i].Reference.TableTag = ATag then
              begin
                g:= i - 1;
                break;
              end;
          for h:=0 to (FForms[k] as TFormTable).EditingManager.GetCountForms - 1 do
            FForms[k].EditingManager.FillComboBox(Temp, g, h);
        end;
        FForms[k].InvalidateDBGrid(ATag);
      end;
    end;
end;

{ TFormTable }

procedure TFormTable.InvalidateDBGrid(ATag: integer);
begin
  FSQLQuery.Close;
  FSQLQuery.Open;
  ChangeCaptionColumn();
  if not MetaData.MetaTables[Tag].isRefFields then
    FormsOfTables.UpdateDataEditingForms(ATag);
end;

procedure TFormTable.FDBGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  KoY:= Y;
end;

procedure TFormTable.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  EditingManager.CloseAllForms(Tag);
  FormsOfTables.FForms[Tag]:= nil;
end;

procedure TFormTable.FormCreate(Sender: TObject);
begin
  FDBGrid.OnTitleClick:= @TitleClick;
  DelEditingForm:= @FDelEditingForm;
  InvalidateGrid:= @InvalidateDBGrid;
  FiltersManager:= TFiltersManager.Create;
  EditingManager:= TEditingManager.Create;
end;

procedure TFormTable.TitleClick(AColumn: TColumn);
begin
  OnColumnClick (AColumn.Index);
end;

procedure TFormTable.AddBtnClick(Sender: TObject);
begin
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

procedure TFormTable.AddFiltersPanelBtnClick(Sender: TObject);
begin
  FiltersPanel.Visible:= true;
  FDBGrid.Width:= Width - DefWidthFiltersPanel - 38;
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

procedure TFormTable.DelFilter(ATag: integer);
begin
  FiltersManager.DelFilter(ATag);
  if FiltersManager.GetCountFilters = 0 then
  begin
    FiltersManager.isFiltred:= false;
    FDBGrid.Width:= Width - InsertBtn.Width - AddFiltersPanelBtn.Width - 8;
    FiltersPanel.Visible:= false;
  end;
  AddQueryFilter;
end;

procedure TFormTable.AddQueryFilter ();
var
  i, c: integer;
begin
  FSQLQuery.Close;
  FiltersManager.GenQueryFilter(FSQLQuery, Tag);
  FSQLQuery.SQL.Append(CreateSortQuery(Tag));
  FSQLQuery.Open;
  ChangeCaptionColumn();
end;

procedure TFormTable.ApplyFilter (Sender: TObject);
begin
  AddQueryFilter;
end;

procedure TFormTable.ChangeCaptionColumn();
var
  i: integer;
begin
  for i:=0 to FDBGrid.Columns.Count-1 do
  begin
    with FDBGrid.Columns.Items[i] do
    begin
      Title.Caption:= MetaData.MetaTables[Self.Tag].Fields[i].Caption;
      case MetaData.MetaTables[Self.Tag].Fields[i].isOrder of
        Down: Title.Caption:= Title.Caption + ' ↓ ';
        Up: Title.Caption:= Title.Caption + ' ↑ ';
      end;
      Width:= MetaData.MetaTables[Self.Tag].Fields[i].Width;
    end;
  end;
  if MetaData.MetaTables[Self.Tag].Fields[0].Caption = 'ИН' then
    FDBGrid.Columns.Items[0].Visible:=  false;
end;

procedure TFormTable.OnColumnClick(ANum: integer);
var
  s: string;
begin
  case MetaData.MetaTables[Tag].Fields[ANum].isOrder of
    Up: MetaData.MetaTables[Tag].Fields[ANum].isOrder:= Down;
    Down: MetaData.MetaTables[Tag].Fields[ANum].isOrder:= None;
    None: MetaData.MetaTables[Tag].Fields[ANum].isOrder:= Up;
  end;
  FSQLQuery.Active:= false;
  s:= CreateSortQuery(Tag);
  if isSorted then
  begin
    FSQLQuery.SQL.Delete(FSQLQuery.SQL.Count - 1);
    if s <> '' then
      FSQLQuery.SQL.Append(CreateSortQuery(Tag))
    else
      isSorted:= false;
  end
  else
  begin
    if s <> '' then
    begin
      FSQLQuery.SQL.Append(s);
      isSorted:= true;
    end
  end;
  FSQLQuery.Active:= true;
  ChangeCaptionColumn();
end;

procedure TFormTable.SetParams (Sender: TObject);
begin
  FiltersManager.SetCountFilters(0);
  Tag:= (Sender as TMenuItem).Tag;
  FiltersPanel.Tag:= Tag;
  EditBtn.Tag:= Tag;
  InsertBtn.Tag:= Tag;
  DeleteBtn.Tag:= Tag;
  AddBtn.Tag:= Tag;
  Caption:= MetaData.MetaTables[Tag].Caption;
  FSQLQuery.Close;
  FSQLQuery.SQL.Text:= SQLGen(Tag).Text;
  FSQLQuery.Active:= true;
  if MetaData.MetaTables[Tag].Fields[0].Caption = 'ИН' then
    FDBGrid.Columns.Items[0].Visible:=  false;
  ChangeCaptionColumn();
end;

{ TFiltersManager }

function TFiltersManager.GetCountFilters(): integer;
begin
  result:= length(Filters);
end;

procedure TFiltersManager.SetCountFilters (ACount: integer);
begin
  SetLength(Filters, ACount);
end;

function TFiltersManager.GenDataForCB(ATag: integer): TStringList;
var
  TempList: TStringList;
  i: integer;
begin
  TempList:= TStringList.Create;
  for i:=0 to length(MetaData.MetaTables[ATag].Fields) - 1 do
    if MetaData.MetaTables[ATag].Fields[i].Caption <> 'ИН' then
      TempList.Append(MetaData.MetaTables[ATag].Fields[i].Caption);
  result:= TempList;
end;

procedure TFiltersManager.AddFilter (APanel: TPanel; ATag: integer);
begin
  if length(Filters) > 9 then exit;
  SetLength(Filters, length(Filters) + 1);
  Filters[high(Filters)]:= TFilter.Create;
  Filters[high(Filters)].CreateFilter(APanel, high(Filters));
  Filters[high(Filters)].TagForm:= ATag;
  Filters[high(Filters)].FillCB(GenDataForCB(ATag));
end;

procedure TFiltersManager.DelFilter(ATag: integer);
var
  i, k: integer;
begin
  k:= ATag;
  for i:= k to high(Filters) - 1 do
  begin
    Filters[i]:= Filters[i + 1];
    Filters[i + 1]:= nil;
    Filters[i].ChangePos(i);
    if Filters[i].isApply then
    begin
      Filters[i].Parametr.Name:= 'param' + IntToStr(i);
      Filters[i].CreateQueryParams;
    end;
  end;
  SetLength(Filters, length(Filters) - 1);
end;

procedure TFiltersManager.GenQueryFilter (ASQLQuery: TSQLQuery; ATag: integer);
var
  i, c: integer;
  isWasFirst: boolean = false;
begin
  ASQLQuery.SQL.Text:= SQLGen(ATag).Text;
  for i:=0 to high(Filters) do
    if Filters[i].isApply then
    begin
      inc(c);
      if not isWasFirst then
        ASQLQuery.SQL.Text:= ASQLQuery.SQL.Text + ' where ' +
          Filters[i].Parametr.Query
      else
        ASQLQuery.SQL.Text:= ASQLQuery.SQL.Text + ' and ' +
          Filters[i].Parametr.Query;
      if Filters[i].Parametr.Like then
        ASQLQuery.ParamByName(Filters[i].Parametr.Name).AsString:= '%' +
          Filters[i].Parametr.Value + '%'
      else
        ASQLQuery.ParamByName(Filters[i].Parametr.Name).AsString:=
          Filters[i].Parametr.Value;
      isWasFirst:= true;
    end;
end;

procedure TFiltersManager.ApplyFilter (ATag, AIndex: integer);
var
  i, k, j: integer;
  temp: TFilter;
begin
  with Filters[AIndex] do
  begin
    isApply:= true;
    Parametr:= TParametr.Create;
    Parametr.Name:= 'param' + IntToStr(AIndex);
    Parametr.NameAction:= ActionBox.Text;
    Parametr.Value:= ValueEdit.Text;
    k:= NameBox.ItemIndex + 1;
    Parametr.Num:= k;
    if MetaData.MetaTables[ATag].Fields[k].Reference <> nil then
    begin
      j:= MetaData.MetaTables[ATag].Fields[k].Reference.TableTag;
      Parametr.NameField:= MetaData.MetaTables[j].Name +
        '.' + MetaData.MetaTables[j].Fields[1].Name;
    end
    else
      Parametr.NameField:= MetaData.MetaTables[ATag].Name + '.' +
        MetaData.MetaTables[ATag].Fields[k].Name;
    CreateQueryParams;
  end;
end;

{ TFilters }

procedure TFilter.CreateFilter(APanel: TPanel; Count: integer);
begin
  Panel:= TPanel.Create (APanel);
  with Panel do
  begin
    Parent:= APanel;
    Width:= 410;
    Height:= 34;
    Top:= 23 * (count + 1) + (height - 20) * count;
    Left:= 8;
  end;
  NameBox:= TComboBox.Create(Panel);
  with NameBox do
  begin
    Parent:= Panel;
    Top:= 6;
    Left:= 3;
    Width:= 136;
    Height:= 23;
    ReadOnly:= true;
    Visible:= true;
    ItemIndex:= 0;
    OnChange:= @OnChangeParam;
  end;
  ActionBox:= TComboBox.Create(Panel);
  with ActionBox do
  begin
    Parent:= Panel;
    Top:= 6;
    Left:= 140;
    Width:= 88;
    Height:= 23;
    ReadOnly:= true;
    Visible:= true;
    ItemIndex:= 0;
    OnChange:= @OnChangeParam;
  end;
  ValueEdit:= TEdit.Create(Panel);
  with ValueEdit do
  begin
    Parent:= Panel;
    Top:= 6;
    Left:= 232;
    Width:= 120;
    Height:= 23;
    Visible:= true;
    OnChange:= @OnChangeParam;
    OnKeyPress:= @EditKeyPress;
  end;
  ApplyBtn:= TSpeedButton.Create(Panel);
  with ApplyBtn do
  begin
    Parent:= Panel;
    Height:= 26;
    Width:= 24;
    Glyph.LoadFromFile('apply_icon.bmp');
    Left:= 355;
    Top:= 5;
    Tag:= count;
    OnClick:= @AppClick;
  end;
  DelBTN:= TSpeedButton.Create(nil);
  with DelBtn do
  begin
    Parent:= Panel;
    Height:= 26;
    Width:= 24;
    Glyph.LoadFromFile('del_icon.bmp');
    Left:= 380;
    Top:= 5;
    Tag:= count;
    OnMouseUp:= @DelClick;
  end;
  Self.isApply:= false;
end;

destructor TFilter.DestroyFilter();
begin
  NameBox.Free;
  ActionBox.Free;
  ValueEdit.Free;
  ApplyBtn.Free;
  Panel.Free;
end;

procedure TFilter.AppClick (Sender: TObject);
var
  i, k: integer;
begin
  k:= TagForm;
  i:= DelBtn.Tag;
  if (NameBox.Text = '') or (ActionBox.Text = '') or (ValueEdit.Text = '') then
  begin
    ShowMessage('Заполните все поля');
    exit;
  end;
  ApplyBtn.Enabled:= false;
  if FormsOfTables.FForms[k] = nil then
  begin
    TimetableForm.FiltersManager.ApplyFilter(k, i);
    TimetableForm.FillGridData;
  end
  else
  begin
    FormsOfTables.FForms[k].FiltersManager.ApplyFilter(k, i);
    FormsOfTables.FForms[k].AddQueryFilter;
  end;
end;

procedure TFilter.DelClick (Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  i, k: integer;
begin
  k:= TagForm;
  i:= DelBtn.Tag;
  DestroyFilter;
  if FormsOfTables.FForms[k] = nil then
     TimetableForm.DelFilter(i)
  else
     FormsOfTables.FForms[k].DelFilter(i)
end;

procedure TFilter.CreateQueryParams ();
begin
  if Parametr.NameAction = ActionArr[6] then
  begin
    Parametr.Query:= Parametr.NameField + ' LIKE :' + Parametr.Name + ' ';
    Parametr.Like:= true;
  end
  else
    Parametr.Query:= Parametr.NameField + ' ' + Parametr.NameAction + ' :' +
      Parametr.Name + ' ';
end;

procedure TFilter.OnChangeParam (Sender: TObject);
begin
  isApply:= false;
  ApplyBtn.Enabled:= true;
  if Sender = NameBox then
    ValueEdit.Clear;
end;

procedure TFilter.FillCB(AList: TStringList);
var
  i: integer;
begin
  for i:=0 to AList.Count - 1 do
    NameBox.Items.Add(AList.ValueFromIndex[i]);
  for i:=0 to 6 do
    ActionBox.Items.Add(ActionArr[i]);
  NameBox.ItemIndex:= 0;
  ActionBox.ItemIndex:= 0;
end;

procedure TFilter.EditKeyPress(Sender: TObject; var Key: char);
var
  temp: TMField;
begin
  temp:= MetaData.MetaTables[TagForm].Fields[NameBox.ItemIndex + 1];
  if temp.Reference = nil then
  begin
    if Temp.FieldType = TInt then
      if not (key in ['0'..'9', #8]) then
        key:= #0;
  end
  else
  begin
    if MetaData.MetaTables[Temp.Reference.TableTag].Fields[1].FieldType = TInt then
      if not (key in ['0'..'9', #8]) then
        key:= #0;
  end;
end;

procedure TFilter.ChangePos (num: integer);
begin
  Panel.Top:= 23 * (num + 1) + (Panel.Height - 20) * num;
  ApplyBTN.Tag:= num;
  DelBTN.Tag:= num;
end;

end.

