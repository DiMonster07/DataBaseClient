unit DBConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    DataSource1: TDataSource;
    DSource: TDataSource;
    IBConnection1: TIBConnection;
    SQLQuery: TSQLQuery;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  public
    procedure DBConnect ();
    procedure DBDisConnect ();
    procedure MakeChangesDatabase(AQuery: TStringList);
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin

end;

procedure TDataModule1.DBConnect ();
begin
  IBConnection1.DatabaseName:= 'TIMETABLE.FDB';
  IBConnection1.Password:= 'masterkey';
  IBConnection1.UserName:= 'SYSDBA';
  IBConnection1.Connected:= true;
end;

procedure TDataModule1.DBDisConnect ();
begin
  SQLQuery.Active:= false;
  IBConnection1.Connected:= false;
end;

procedure TDataModule1.MakeChangesDatabase(AQuery: TStringList);
begin
  SQLQuery.Close;
  SQLQuery.SQL.Text:= AQuery.Text;
  SQLQuery.ExecSQL;
  //SQLTransaction1.Commit;
end;

end.

