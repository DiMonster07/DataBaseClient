unit FormGen;

{$mode objfpc}{$H+}{$M+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, FormChangeData;

type

  TChangeEvent = procedure (Sender: TObject) of object;

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
  public
    procedure CreateFilter(APanel: TPanel; Count: integer);
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
    procedure AddBtnClick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FDBGridDblClick(Sender: TObject);
    procedure FDBGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure InsertBtnClick(Sender: TObject);
    procedure TitleClick(AColumn: TColumn);
  private
    { private declarations }
  public

  end;

var
  FormTable: TFormTable;
  ChangeNameCB: TChangeEvent;
  ActionArr: array[0..6] of string = ('<', '>', '>=', '<=', '=',
    '<>', 'включает');
implementation
uses meta;
var
  KoY: integer;

{$R *.lfm}

{ ActionChange }

procedure TFormTable.InsertBtnClick(Sender: TObject);
begin
  TableArr[Self.Tag].OpenFormEditingTable(StrToInt(
    FSQLQuery.Fields.FieldByNumber(1).Value), FSQLQuery.RecNo, ctInsert);
end;

procedure TFormTable.DeleteBtnClick(Sender: TObject);
begin
  TableArr[Self.Tag].OpenFormEditingTable(StrToInt(
    FSQLQuery.Fields.FieldByNumber(1).Value), FSQLQuery.RecNo, ctDelete);
end;

procedure TFormTable.EditBtnClick(Sender: TObject);
begin
  if trunc(KoY/FDBGrid.DefaultRowHeight) = 0 then exit;
  TableArr[Self.Tag].OpenFormEditingTable(
    StrToInt(FSQLQuery.Fields.FieldByNumber(1).Value), FSQLQuery.RecNo, ctEdit);
end;

procedure TFormTable.FDBGridDblClick(Sender: TObject);
begin
  EditBtnClick(Sender)
end;



{ TFormTable }

procedure TFormTable.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  TableArr[Self.Tag].FormClose;
end;

procedure TFormTable.FormCreate(Sender: TObject);
begin
  FDBGrid.OnTitleClick:= @TitleClick;
end;

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

procedure TFormTable.AddBtnClick(Sender: TObject);
begin
  TableArr[Self.Tag].AddFilter ();
end;

procedure TFormTable.FDBGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  KoY:= Y;
end;

procedure TFilter.DelClick (Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TableArr[DelBtn.Parent.Parent.Parent.Tag].DelFilter(Sender);
end;

procedure TFormTable.TitleClick(AColumn: TColumn);
begin
  TableArr[Self.Tag].OnColumnClick (AColumn.Index);
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
  Temp: TField;
begin
  Temp:= TableArr[ApplyBtn.Parent.Parent.Parent.Tag].
    GetColForNum(NameBox.ItemIndex);
  if Temp.RefS then
  begin
    if Temp.RType = TInt then
      if not (key in ['0'..'9', #8]) then
        key:= #0;
  end
  else
  begin
    if Temp.FType = TInt then
      if not (key in ['0'..'9', #8]) then
        key:= #0;
  end;
end;

procedure TFilter.AppClick (Sender: TObject);
begin
  if (NameBox.Text = '') or (ActionBox.Text = '') or (ValueEdit.Text = '') then
  begin
    ShowMessage('Заполните все поля');
    exit;
  end;
  ApplyBtn.Enabled:= false;
  TableArr[ApplyBtn.Parent.Parent.Parent.Tag].ApplyFilter(Sender);
end;

procedure TFilter.ChangePos (num: integer);
begin
  Panel.Top:= 23 * (num + 1) + (Panel.Height - 20) * num;
  ApplyBTN.Tag:= num;
  DelBTN.Tag:= num;
end;

end.

