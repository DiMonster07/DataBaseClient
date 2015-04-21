program DBProject;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, meta, DBConnection, FormGen, FormChangeData;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TDataModule1, DataModule1);
  Application.CreateForm(TProgramForm, ProgramForm);
  Application.CreateForm(TFormChangeData1, FormChangeData1);
  Application.Run;
end.

