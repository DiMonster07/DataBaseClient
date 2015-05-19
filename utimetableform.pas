unit Utimetableform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, FormChangeData,
  meta, SqlGenerator, DBConnection, GenerationForms, windows;

type

  { TTimetableForm }

  TTimetableForm = class(TForm)
    DBGrid1: TDBGrid;
    OptionsPanel: TPanel;
    FiltersPanel: TPanel;
    OpenFiltersPanelBtn: TSpeedButton;
    AddFilterBtn: TSpeedButton;
    procedure FormCreate(Sender: TObject);
  private

  public
    Filters: TFiltersArray;
    //procedure AddFilter(ATag: integer);
    //procedure DelFilter(ATag: integer);
    //procedure ApplyFilter(Sender: TObject);
    //procedure ChangeCaptionColumn();
    //procedure AddQueryFilter ();
    //procedure GenQueryFilter ();
  published
    //property isFiltred: boolean read FFiltredStatus write FFiltredStatus;
  end;

var
  TimetableForm: TTimetableForm;

implementation

{$R *.lfm}

{ TTimetableForm }

procedure TTimetableForm.FormCreate(Sender: TObject);
begin

end;

end.

