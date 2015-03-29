unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, DBGrids, ComCtrls, Menus, DbCtrls,
  Grids, Meta, ListView, DBConnection;

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
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  ProgramForm: TProgramForm;

function CreateItemName (IName: string): string;

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
   q:integer;
 begin
   q:=0;
   MainItem:= DirItem;
   DataModule1.SQLQuery.Active:= false;
   DataModule1.SQLQuery.SQL.Text:=
     'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS WHERE RDB$SYSTEM_FLAG = 0';
   DataModule1.SQLQuery.Open;
   TranslateList:= TStringList.Create;
   TranslateList.LoadFromFile('Meta.in');
   while not DataModule1.SQLQuery.EOF do
   begin
     CreateTable(CreateItemName(DataModule1.SQLQuery.Fields[0].AsString));
     DataModule1.SQLQuery.Next;
     q+= 1;
   end;
   DataModule1.SQLQuery.Close;
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

