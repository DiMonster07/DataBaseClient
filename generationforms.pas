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
    procedure CreateFilter(APanel: TPanel; Count: integer);
    procedure CreateQueryParams ();
    procedure ChangePos (num: integer);
    procedure AppClick (Sender: TObject);
    procedure DelClick (Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FillCB (AList: TStringList);
    procedure OnChangeParam (Sender: TObject);
    procedure EditKeyPress(Sender: TObject; var Key: char);
    destructor DestroyFilter ();
  published
    property isApply: boolean read AppStatus write AppStatus;
    property TagForm: integer read FTag write FTag;
  end;

  TFiltersArray = array of TFilter;

  { TEditingManager }

  TEditingManager = class
  private

  public

  published

  end;

  { TFiltersManager }

  TFiltersManager = class
  private
    Filters: TFiltersArray;
    FFiltredStatus: boolean;
  public
    procedure AddFilter (ADBGrid: TDBGrid; APanel: TPanel; ATag: integer);
    procedure DelFilter(ADBGrid: TDBGrid; ATag: integer);
    procedure ApplyFilter(ATag, AIndex: integer);
    procedure GenQueryFilter (ASQLQuery: TSQLQuery; ATag: integer);
    procedure SetCountFilters (ACount: integer);
    function GetCountFilters(): integer;
  published
    property isFiltred: boolean read FFiltredStatus write FFiltredStatus;
  end;

  { TFormTable }

  TFormTable = class(TForm)
    AddBtn: TBitBtn;
    FDataSource: TDataSource;
    FDBGrid: TDBGrid;
    FDBNavigator: TDBNavigator;
    FilterPanel: TPanel;
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
    FFormsChange: TArrayForms;
    procedure DelFilter(ATag: integer);
    procedure ApplyFilter(Sender: TObject);
    procedure AddQueryFilter ();
    procedure ChangeCaptionColumn();
    procedure OnColumnClick(ANum: integer);
    procedure OpenFormEditingTable (Index: integer; AChangeType: TChangeType);
    procedure FDelClosedForms (Sender: TObject);
    procedure InvalidateDBGrid(ATag: integer);
    function isFormOpenedForId(AId: integer): TFormChangeData1;
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
  FormTable: TFormTable;
  FormsOfTables: TFormsOfTables;
  ActionArr: array[0..6] of string = ('<', '>', '>=', '<=', '=',
    '<>', 'включает');
implementation
var
  KoY: integer;

{$R *.lfm}

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
        if length(FForms[k].FFormsChange) <> 0 then
        begin
          temp:= MetaData.MetaTables[ATag].GetDataFieldOfIndex(1);
          for i:= 1 to high(MetaData.MetaTables[k].Fields) do
            if MetaData.MetaTables[k].Fields[i].Reference <> nil then
              if MetaData.MetaTables[k].Fields[i].Reference.TableTag = ATag then
              begin
                g:= i - 1;
                break;
              end;
          for h:=0 to high(FForms[k].FFormsChange) do
            FForms[k].FFormsChange[h].FillComboBox(Temp, g);
        end;
        FForms[k].InvalidateDBGrid(ATag);
      end;
    end;
end;

{ TFormTable }

function TFormTable.isFormOpenedForId(AId: integer): TFormChangeData1;
var
  i, k: integer;
begin
  k:= -1;
  for i:=0 to high(FFormsChange) do
    if FFormsChange[i].IdLabel.Tag = AId then
      exit(FFormsChange[i]);
  result:= nil;
end;

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
var
  i: integer;
begin
  for i:=0 to high(FFormsChange) do
    FormsOfTables.FForms[Tag].FFormsChange[i].Free;
  FormsOfTables.FForms[Tag]:= nil;
end;

procedure TFormTable.FormCreate(Sender: TObject);
begin
  FDBGrid.OnTitleClick:= @TitleClick;
  DelClosedForm:= @FDelClosedForms;
  InvalidateGrid:= @InvalidateDBGrid;
  FiltersManager:= TFiltersManager.Create;
end;

procedure TFormTable.TitleClick(AColumn: TColumn);
begin
  OnColumnClick (AColumn.Index);
end;

procedure TFormTable.AddBtnClick(Sender: TObject);
begin
  FiltersManager.AddFilter(FDBGrid, FilterPanel, Tag);
end;

procedure TFormTable.AddFiltersPanelBtnClick(Sender: TObject);
begin
  FilterPanel.Visible:= true;
  FDBGrid.Width:= Width - DefWidthFiltersPanel - 38;
  FiltersManager.AddFilter(FDBGrid, FilterPanel, Tag);
end;

procedure TFormTable.DelFilter(ATag: integer);
begin
  FiltersManager.DelFilter(FDBGrid, ATag);
  if FiltersManager.GetCountFilters = 0 then
  begin
    FiltersManager.isFiltred:= false;
    FDBGrid.Width:= Width - InsertBtn.Width - AddFiltersPanelBtn.Width - 8;
    FilterPanel.Visible:= false;
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
  FiltersManager.ApplyFilter(Tag, (Sender as TSpeedButton).Tag);
  AddQueryFilter;
end;

procedure TFormTable.ChangeCaptionColumn();
var
  i: integer;
begin
  for i:=0 to FDBGrid.Columns.Count-1 do
  begin
    FDBGrid.Columns.Items[i].Title.Caption:=
      MetaData.MetaTables[Tag].Fields[i].Caption;
    case MetaData.MetaTables[Tag].Fields[i].isOrder of
      Down: FDBGrid.Columns.Items[i].Title.Caption:=
        FDBGrid.Columns.Items[i].Title.Caption + ' ↓ ';
      Up: FDBGrid.Columns.Items[i].Title.Caption:=
        FDBGrid.Columns.Items[i].Title.Caption + ' ↑ ';
    end;
    FDBGrid.Columns.Items[i].Width:=
      MetaData.MetaTables[Tag].Fields[i].Width;
  end;
  if MetaData.MetaTables[Tag].Fields[0].Caption = 'ИН' then
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
  FilterPanel.Tag:= Tag;
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

 { Editing }

 procedure TFormTable.FDelClosedForms (Sender: TObject);
 var
   i, k, j: integer;
 begin
   j:= (Sender as TForm).Tag;
   for i:= 0 to high(FormsOfTables.FForms[j].FFormsChange) do
     if not FormsOfTables.FForms[j].FFormsChange[i].Visible then
     begin
       FormsOfTables.FForms[j].FFormsChange[i].Free;
       for k:= i to high(FormsOfTables.FForms[j].FFormsChange) - 1 do
       begin
           FormsOfTables.FForms[j].FFormsChange[k]:=
             FormsOfTables.FForms[j].FFormsChange[k + 1];
           FormsOfTables.FForms[j].FFormsChange[k].ArrControls[0].Tag:= k;
           FormsOfTables.FForms[j].FFormsChange[k + 1]:= nil;
       end;
       break;
     end;
   SetLength(FormsOfTables.FForms[j].FFormsChange,
     length(FormsOfTables.FForms[j].FFormsChange) - 1);
 end;

 procedure TFormTable.OpenFormEditingTable (Index: integer;
   AChangeType: TChangeType);
 var
   i, k, j: integer;
   s: string;
   temp: TStringList;
   TempControl: array of TControl;
 begin
   SetLength(FFormsChange, length(FFormsChange) + 1);
   FFormsChange[high(FFormsChange)]:= TFormChangeData1.Create(Application);
   FFormsChange[high(FFormsChange)].Tag:= Tag;
   FFormsChange[high(FFormsChange)].FAction:= AChangeType;
   FFormsChange[high(FFormsChange)].BorderStyle:= bsSingle;
   FFormsChange[high(FFormsChange)].IdLabel.Tag:= FSQLQuery.Fields[0].Value;
   temp:= TStringList.Create;
   k:= GenUniqId;
   s:= '';
   for i:= 0 to high(MetaData.MetaTables[Tag].Fields) do
   begin
     if MetaData.MetaTables[Tag].Fields[i].Caption <> 'ИН' then
     begin
       temp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(i);
       SetLength(FFormsChange[high(FFormsChange)].ArrControls, length(
         FFormsChange[high(FFormsChange)].ArrControls) + 1);
       if MetaData.MetaTables[Tag].Fields[i].Reference <> nil then
       begin
         FFormsChange[high(FFormsChange)].CreateComboBox(temp,
           MetaData.MetaTables[tag].Fields[i].Caption,
           MetaData.MetaTables[tag].Fields[i].Width);
         k:= high(FFormsChange[high(FFormsChange)].ArrControls);
         j:= temp.IndexOf(string(FSQLQuery.Fields.FieldByNumber(i + 1).Value));
         (FFormsChange[high(FFormsChange)].ArrControls[k] as TComboBox)
           .ItemIndex:= j;
       end
       else
       begin
         FFormsChange[high(FFormsChange)].CreateEdit(
           MetaData.MetaTables[tag].Fields[i].Caption,
           MetaData.MetaTables[tag].Fields[i].Width);
         k:= high(FFormsChange[high(FFormsChange)].ArrControls);
           (FFormsChange[high(FFormsChange)].ArrControls[k] as TEdit).Text:=
             string(FSQLQuery.Fields.FieldByNumber(i + 1).Value);
       end;
       s:= s + string(FSQLQuery.Fields.FieldByNumber(i + 1).Value) + '||';
     end;
     if AChangeType = ctEdit then
       FFormsChange[high(FFormsChange)].Caption:= s
     else
       FFormsChange[high(FFormsChange)].Caption:= 'Новая запись';
   end;
   FFormsChange[high(FFormsChange)].ArrControls[0].Tag:= high(FFormsChange);
   FFormsChange[high(FFormsChange)].CreateBtn;
   FFormsChange[high(FFormsChange)].Show;
 end;

procedure TFormTable.InsertBtnClick(Sender: TObject);
var
  temp: TFormChangeData1;
begin
  temp:= isFormOpenedForId(FSQLQuery.Fields[0].Value);
  if temp = nil then
  begin
    if isFormOpenedForId(FSQLQuery.Fields[0].Value) = nil  then
      OpenFormEditingTable(FSQLQuery.RecNo, ctInsert);
  end
  else
    temp.Show;
end;

procedure TFormTable.EditBtnClick(Sender: TObject);
var
  temp: TFormChangeData1;
begin
  temp:= isFormOpenedForId(FSQLQuery.Fields[0].Value);
  if temp = nil then
  begin
    if trunc(KoY/FDBGrid.DefaultRowHeight) = 0 then exit;
      OpenFormEditingTable(FSQLQuery.RecNo, ctEdit);
  end
  else
    temp.show;
end;

procedure TFormTable.DeleteBtnClick(Sender: TObject);
var
  i: LongInt;
  temp: TFormChangeData1;
begin
  if FSQLQuery.Fields.FieldByNumber(1).Value = Null then exit;
  DataModule1.SQLQuery.Close;
  DataModule1.SQLQuery.SQL.Text:= 'DELETE FROM ' + MetaData.MetaTables[Tag].Name
    + ' WHERE ID = ' + String(FSQLQuery.Fields.FieldByNumber(1).Value);
  i:= MessageDLG('Вы действительно хотите удалить эту запись?',
      mtConfirmation, mbYesNoCancel, 0);
  if i = mrYes then
  begin
    try
      DataModule1.SQLQuery.ExecSQL;
      //DataModule1.SQLTransaction1.Commit;
      temp:= isFormOpenedForId(FSQLQuery.Fields[0].Value);
      if temp <> nil then
        temp.close;
      InvalidateGrid(Tag);
      FDBGrid.DataSource.DataSet.MoveBy(0);
    except
      MessageDLG('Невозможно удалить эту запись т.к. она используется другой таблицей',
      mtError,[mbYes], 0);
    end;
  end;
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



{ TFiltersManager }

function TFiltersManager.GetCountFilters(): integer;
begin
  result:= length(Filters);
end;

procedure TFiltersManager.SetCountFilters (ACount: integer);
begin
  SetLength(Filters, ACount);
end;

procedure TFiltersManager.AddFilter (ADBGrid: TDBGrid; APanel: TPanel;
  ATag: integer);
var
  TempList: TStringList;
  i: integer;
begin
  if length(Filters) > 12 then exit;
  SetLength(Filters, length(Filters) + 1);
  Filters[high(Filters)]:= TFilter.Create;
  Filters[high(Filters)].CreateFilter(APanel, high(Filters));
  Filters[high(Filters)].TagForm:= ATag;
  TempList:= TStringList.Create;
  for i:=0 to ADBGrid.Columns.Count - 1 do
    if ADBGrid.Columns.Items[i].Visible then
      TempList.Append(MetaData.MetaTables[ATag].Fields[i].Caption);
  Filters[high(Filters)].FillCB(TempList);
end;

procedure TFiltersManager.DelFilter(ADBGrid: TDBGrid; ATag: integer);
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
  temp:= Filters[AIndex];
  Filters[AIndex].isApply:= true;
  Filters[AIndex].Parametr:= TParametr.Create;
  Filters[AIndex].Parametr.Name:= 'param' + IntToStr(AIndex);
  Filters[AIndex].Parametr.NameAction:= Filters[AIndex].ActionBox.Text;
  Filters[AIndex].Parametr.Value:= Filters[AIndex].ValueEdit.Text;
  k:= temp.NameBox.ItemIndex + 1;
  Filters[AIndex].Parametr.Num:= k;
  if MetaData.MetaTables[ATag].Fields[k].Reference <> nil then
  begin
    j:= MetaData.MetaTables[ATag].Fields[k].Reference.TableTag;
    Filters[AIndex].Parametr.NameField:= MetaData.MetaTables[j].Name +
      '.' + MetaData.MetaTables[j].Fields[1].Name;
  end
  else
    Filters[AIndex].Parametr.NameField:= MetaData.MetaTables[ATag].Name + '.' +
      MetaData.MetaTables[ATag].Fields[k].Name;
  Filters[AIndex].CreateQueryParams;
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
begin
  if (NameBox.Text = '') or (ActionBox.Text = '') or (ValueEdit.Text = '') then
  begin
    ShowMessage('Заполните все поля');
    exit;
  end;
  ApplyBtn.Enabled:= false;
  FormsOfTables.FForms[Panel.Parent.Tag].ApplyFilter(Sender);
end;

procedure TFilter.DelClick (Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  i, k: integer;
begin
  k:= TagForm;
  i:= DelBtn.Tag;
  DestroyFilter;
  FormsOfTables.FForms[k].DelFilter(i);
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
  if temp = nil then
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

