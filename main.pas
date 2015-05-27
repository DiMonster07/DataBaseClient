unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, Menus, DbCtrls,
  Grids, Buttons, ActnList, ComCtrls, DBGrids, Meta, DBConnection,
  GenerationForms, Utimetableform;

type

  { TProgramForm }

  TProgramForm = class(TForm)
    MainMenu1: TMainMenu;
    FileItem: TMenuItem;
    DirItem: TMenuItem;
    AboutItem: TMenuItem;
    MenuItem1: TMenuItem;
    TimetableItem: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure AboutItemClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure CreateMenuTable ();
    procedure OnClickMenuItem (Sender: TObject);
    procedure TimetableItemClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  ProgramForm: TProgramForm;
  DefRowHeight: integer;
  count: integer;
implementation
{$R *.lfm}
{ ProgramForm }


procedure TProgramForm.FormCreate(Sender: TObject);
begin
  DataModule1.DBConnect();
  CreateMenuTable;
  DefRowHeight:= 22;
  count:= 0;
end;

procedure TProgramForm.AboutItemClick(Sender: TObject);
begin
  ShowMessage('Разработчик: Дмитрий Томак')
end;

procedure TProgramForm.Button1Click(Sender: TObject);
begin
  //StringGrid1.Canvas.TextRect(StringGrid1.CellRect(1,1), 0,0, 'ewbw', );
  inc(count);
end;

procedure TProgramForm.FormClick(Sender: TObject);
begin

end;

procedure TProgramForm.FormPaint(Sender: TObject);
begin

end;

//Работа с Menu

 procedure TProgramForm.CreateMenuTable ();
 var
   MenuItem: TMenuItem;
   i, c:integer;
   s: string;
 begin
   DataModule1.SQLQuery.Active:= false;
   DataModule1.SQLQuery.SQL.Text:=
     'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS WHERE RDB$SYSTEM_FLAG = 0';
   DataModule1.SQLQuery.Open;
   TranslateList:= TStringList.Create;
   TranslateList.LoadFromFile('Meta.in');
   MetaData:= TMeta.Create;
   c:= 0;
   while not DataModule1.SQLQuery.EOF do
   begin
     s:= CreateItemName(DataModule1.SQLQuery.Fields[0].AsString);
     SetLength(MetaData.MetaTables, length(MetaData.MetaTables) + 1);
     MetaData.MetaTables[high(MetaData.MetaTables)]:= TMTable.Create;
     MetaData.MetaTables[high(MetaData.MetaTables)].FillDataTable(s);
     MenuItem:= TMenuItem.Create(DirItem);
     MenuItem.Caption:= TranslateList.Values[s];
     MenuItem.OnClick:= @OnClickMenuItem;
     MenuItem.Tag:= c;
     DirItem.Add(MenuItem);
     inc(c);
     DataModule1.SQLQuery.Next;
   end;
   for i:= 0 to high(MetaData.MetaTables) do
     MetaData.MetaTables[i].FillReferencedField;
   FormsOfTables:= TFormsOfTables.Create;
   DataModule1.SQLQuery.Close;
 end;
procedure TProgramForm.OnClickMenuItem (Sender: TObject);
begin
  if FormsOfTables.FForms[(Sender as TMenuItem).Tag] = nil then
  begin
    FormsOfTables.FForms[(Sender as TMenuItem).Tag]:= TFormTable.Create(Application);
    FormsOfTables.FForms[(Sender as TMenuItem).Tag].SetParams(Sender);
  end;
  FormsOfTables.FForms[(Sender as TMenuItem).Tag].Show;
end;

procedure TProgramForm.TimetableItemClick(Sender: TObject);
begin
  TimetableForm:= TTimetableForm.Create(Application);
  TimetableForm.SetParams(Sender);
  TimetableForm.Show;
end;

end.

