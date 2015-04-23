unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, Menus, DbCtrls,
  Grids, Buttons, ActnList, ComCtrls, DBGrids, Meta, DBConnection;

type

  { TProgramForm }

  TProgramForm = class(TForm)
    MainMenu1: TMainMenu;
    FileItem: TMenuItem;
    DirItem: TMenuItem;
    AboutItem: TMenuItem;
    procedure AboutItemClick(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure CreateMenuTable ();
    procedure OnClickMenuItem (Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  ProgramForm: TProgramForm;
implementation
{$R *.lfm}
{ ProgramForm }

procedure TProgramForm.FormCreate(Sender: TObject);
begin
  DataModule1.DBConnect();
  CreateMenuTable;
end;

procedure TProgramForm.AboutItemClick(Sender: TObject);
begin
  ShowMessage('Разработчик: Дмитрий Томак')
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
   c:= 0;
   while not DataModule1.SQLQuery.EOF do
   begin
     s:= CreateItemName(DataModule1.SQLQuery.Fields[0].AsString);
     CreateTable(s);
     MenuItem:= TMenuItem.Create(DirItem);
     MenuItem.Caption:= TranslateList.Values[s];
     MenuItem.OnClick:= @OnClickMenuItem;
     MenuItem.Tag:= c;
     DirItem.Add(MenuItem);
     inc(c);
     DataModule1.SQLQuery.Next;
   end;
   for i:=0 to high(TableArr) do
     TableArr[i].CreateRef;
   DataModule1.SQLQuery.Close;
 end;
procedure TProgramForm.OnClickMenuItem (Sender: TObject);
begin
  if TableArr[(Sender as TMenuItem).Tag].FStatus then
    TableArr[(Sender as TMenuItem).Tag].GetForm.Show
  else
    TableArr[(Sender as TMenuItem).Tag].CreateForm(Sender);
end;

end.

