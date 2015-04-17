unit FormGen;

{$mode objfpc}{$H+}{$M+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons;

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
    FNameCB: TComboBox;
    FActionCB: TComboBox;
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
    procedure DelClick (Sender: TObject);
    procedure FillCB (AList: TStringList);
    procedure OnChangeParam (Sender: TObject);
    procedure EditKeyPress(Sender: TObject; var Key: char);
    Destructor Destroy ();
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
    procedure AddBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
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
{$R *.lfm}

{ TFormTable }

procedure TFormTable.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  TableArr[Self.Tag].FormClose;
end;

procedure TFormTable.FormCreate(Sender: TObject);
begin
  FDBGrid.OnTitleClick:= @TitleClick;
end;

procedure TFormTable.AddBtnClick(Sender: TObject);
begin
  TableArr[Self.Tag].AddFilter ();
end;

procedure TFormTable.TitleClick(AColumn: TColumn);
begin
  TableArr[Self.Tag].OnColumnClick (AColumn.Index);
end;

procedure TFilter.CreateFilter(APanel: TPanel; Count: integer);
begin
  FNameCB:= TComboBox.Create(nil);
  with FNameCB do
  begin
    Parent:= APanel;
    Top:= 28 + 24*count;
    Left:= 5;
    Width:= 128;
    Height:= 24;
    ReadOnly:= true;
    Visible:= true;
    OnChange:= @OnChangeParam;
    ItemIndex:= 0;
  end;
  FActionCB:= TComboBox.Create(nil);
  with FActionCB do
  begin
    Name:= 'Action';
    Parent:= APanel;
    Top:= 28 + 24*count;
    Left:= 134;
    Width:= 52;
    Height:= 24;
    ReadOnly:= true;
    Visible:= true;
    ItemIndex:= 0;
    OnChange:= @OnChangeParam;
  end;
  ValueEdit:= TEdit.Create(nil);
  with ValueEdit do
  begin
    Parent:= APanel;
    Top:= 28 + 24*count;
    Left:= 190;
    Width:= 72;
    Height:= 24;
    Visible:= true;
    OnChange:= @OnChangeParam;
    OnKeyPress:= @EditKeyPress;
  end;
  ApplyBTN:= TSpeedButton.Create(nil);
  with ApplyBtn do
  begin
    Parent:= APanel;
    Height:= 26;
    Width:= 24;
    Glyph.LoadFromFile('apply_icon.bmp');
    Left:= 264;
    Top:= 28 + 24*count;
    Tag:= count;
    OnClick:= @AppClick;
  end;
  DelBTN:= TSpeedButton.Create(nil);
  with DelBtn do
  begin
    Parent:= APanel;
    Height:= 26;
    Width:= 24;
    Glyph.LoadFromFile('del_icon.bmp');
    Left:= 292;
    Top:= 28 + 24*count;
    Tag:= count;
    OnClick:= @DelClick;
  end;
  Self.isApply:= false;
end;

procedure TFilter.OnChangeParam (Sender: TObject);
begin
  isApply:= false;
  ApplyBtn.Enabled:= true;
  if (not Sender.ClassNameIs('TEdit')) and
    not((Sender as TComboBox).name = 'Action') then
    ValueEdit.Clear;
end;

procedure TFilter.FillCB(AList: TStringList);
var
  i: integer;
begin
  for i:=0 to AList.Count - 1 do
    FNameCB.Items.Add(AList.ValueFromIndex[i]);
  for i:=0 to 6 do
    FActionCB.Items.Add(ActionArr[i]);
  FNameCB.ItemIndex:= 0;
  FActionCB.ItemIndex:= 0;
end;

procedure TFilter.EditKeyPress(Sender: TObject; var Key: char);
var
  Temp: TField;
begin
  Temp:= TableArr[ApplyBtn.Parent.Parent.Tag].GetColForNum(FNameCB.ItemIndex);
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
  if (FNameCB.Text = '') or (FActionCB.Text = '') or (ValueEdit.Text = '') then
  begin
    ShowMessage('Заполните все поля');
    exit;
  end;
  ApplyBtn.Enabled:= false;
  TableArr[ApplyBtn.Parent.Parent.Tag].ApplyFilter(Sender);
end;

procedure TFilter.DelClick (Sender: TObject);
begin
  TableArr[DelBtn.Parent.Parent.Tag].DelFilter(Sender);
end;

destructor TFilter.Destroy();
begin
  FNameCB:= nil;
  FActionCB:= nil;
  ValueEdit:= nil;
  ApplyBTN:= nil;
  DelBTN:= nil;
  Parametr:= nil;
end;

procedure TFilter.ChangePos (num: integer);
begin
  FNameCB.Top:= 28 + 24*num;
  FActionCB.Top:= 28 + 24*num;
  ValueEdit.Top:= 28 + 24*num;
  ApplyBTN.Top:= 28 + 24*num;
  DelBTN.Top:= 28 + 24*num;
  ApplyBTN.Tag:= num;
  DelBTN.Tag:= num;
end;



end.

