unit FormsManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, meta, GenerationForms,
  DBConnection;

type
  TFormsOfTables = class
    FForms: array of TFormTable;
  public
    constructor Create;
  end;
var
  FormsOfTables: TFormsOfTables;

implementation

constructor TFormsOfTables.Create;
begin
  SetLength(FForms, length(MetaData.MetaTables));

end;

end.

