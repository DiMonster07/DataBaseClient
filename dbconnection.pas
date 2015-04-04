unit DBConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    DSource: TDataSource;
    IBConnection1: TIBConnection;
    SQLQuery: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  public
    procedure DBConnect ();
    procedure DBDisConnect ();
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

end.

