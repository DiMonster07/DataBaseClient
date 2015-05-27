unit Utimetableform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, FormChangeData,
  meta, SqlGenerator, DBConnection, GenerationForms, windows;

type

  { TTimeTableForm }

  TTimeTableForm = class(TForm)
    DataSource1: TDataSource;
    Label1: TLabel;
    ApplyBtn: TSpeedButton;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    ColumnCB: TComboBox;
    RowCB: TComboBox;
    DataSelectionLabel: TLabel;
    ColumnLabel: TLabel;
    RowLabel: TLabel;
    OptionsPanel: TPanel;
    FiltersPanel: TPanel;
    OpenFiltersPanelBtn: TSpeedButton;
    AddFilterBtn: TSpeedButton;
    DataSelectionPanel: TPanel;
    DataStringGrid: TStringGrid;
    procedure AddFilterBtnClick(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure DataStringGridDblClick(Sender: TObject);
    procedure DataStringGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DataStringGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DataStringGridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure CBChange(Sender: TObject);
    procedure OpenFiltersPanelBtnClick(Sender: TObject);
  private
    DataArray: array of array of TStringList;
  public
    FiltersManager: TFiltersManager;
    procedure AddQueryFilter ();
    procedure ChangeCaptionColumn(AColList, ARowList: TStringList);
    procedure ApplyFilter(Sender: TObject);
    procedure SetParams (Sender: TObject);
    procedure FillGridData ();
    procedure FillCB (AList: TStringList);
    procedure DelFilter(ATag: integer);
    procedure HandlerClick (aCol, aRow: integer);
  published

  end;

var
  ListNamesFile: array [0..2] of string = ('tt_add.png','tt_edit.png',
    'tt_del.png');
  Margin: integer = 2;
  DefHeightFont: integer = 17;
  TimetableForm: TTimetableForm;
  DefWidthCol: integer = 350;
  DefHeightRow: integer = 136;
  DefWidthImg: integer = 15;
implementation
var
  Row, Col: integer;
{$R *.lfm}

{ TTimetableForm }

procedure TTimetableForm.FormCreate(Sender: TObject);
begin
  FiltersManager:= TFiltersManager.Create;
  FiltersPanel.Visible:= false;
  DataStringGrid.Color:= clWindow;
end;

procedure TTimeTableForm.CBChange(Sender: TObject);
begin
  ApplyBtn.Enabled:= true;
end;

procedure TTimeTableForm.OpenFiltersPanelBtnClick(Sender: TObject);
begin
  FiltersPanel.Visible:= true;
  DataStringGrid.Width:= Width - FiltersPanel.Width;
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

procedure TTimeTableForm.FillCB (AList: TStringList);
var
  i: integer;
begin
  for i:=0 to AList.Count - 1 do
  begin
    ColumnCB.Items.Add(AList.ValueFromIndex[i]);
    RowCB.Items.Add(AList.ValueFromIndex[i]);
  end;
  ColumnCB.ItemIndex:= 3;
  ColumnCB.ReadOnly:= true;
  RowCB.ItemIndex:= 2;
  RowCB.ReadOnly:= true;
  FillGridData();
end;

procedure TTimetableForm.SetParams (Sender: TObject);
var
  t: integer;
  ord: string;
  temp: TStringList;
begin
  Tag:= 8;
  FiltersPanel.Tag:= Tag;
  AddFilterBtn.Tag:= Tag;
  temp:= FiltersManager.GenDataForCB(Tag);
  FillCB(temp);
  Caption:= MetaData.MetaTables[Tag].Caption;
end;

procedure TTimetableForm.AddFilterBtnClick(Sender: TObject);
begin
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

procedure TTimeTableForm.ApplyBtnClick(Sender: TObject);
begin
  ApplyBtn.Enabled:= false;
  FillGridData();
end;

procedure TTimeTableForm.DataStringGridDblClick(Sender: TObject);
begin
  if (Row = 0) or (Col = 0) then exit;
  if DataStringGrid.RowHeights[Row] > DefHeightRow then
    DataStringGrid.RowHeights[Row]:= DefHeightRow
  else if (DataArray[Row - 1][Col - 1] <> nil) and
      (round(DataArray[Row - 1][Col - 1].Count/8) > 1) then
    DataStringGrid.RowHeights[Row]:= round(DataArray[Row - 1][Col - 1].Count/8)*
      DefHeightRow;
end;

procedure TTimeTableForm.DataStringGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  i, k: integer;
  img: TPicture;
begin
  if length(DataArray) <> 0 then
  begin
    img:= TPicture.Create;
    if (aRow <> 0) and(aCol <> 0) then
    begin
      Img.LoadFromFile('icon\' + ListNamesFile[0]);
      DataStringGrid.Canvas.Draw(DefWidthCol + aRect.Left - Img.Width - Margin,
        aRect.Top + Margin, Img.Graphic);
      if DataArray[aRow - 1][aCol - 1] <> nil then
      begin
        for i:= 1 to 2 do
        begin
          Img.LoadFromFile('icon\' + ListNamesFile[i]);
          DataStringGrid.Canvas.Draw(DefWidthCol + aRect.Left - Img.Width -
            Margin, aRect.Top + Margin + i*Img.Height + Margin,
            Img.Graphic);
        end;
        /////Количество скрытых записей
        {if DataArray[aRow - 1][aCol - 1].Count > 8 then
        begin
          DataStringGrid.Canvas.TextOut(DefWidthCol + aRect.Left - 25 -
            Margin, aRect.Top + DefHeightRow - 27, ' ↓ ' + IntToStr(
            round(DataArray[aRow - 1][aCol - 1].Count/8) - 1));
        end; }
        for i:= 0 to DataArray[aRow - 1][aCol - 1].Count - 1 do
        begin
          if DataArray[aRow - 1][aCol - 1][i] <> '' then
          begin
            DataStringGrid.Canvas.TextOut(aRect.Left + Margin, aRect.Top +
              i*DefHeightFont, DataArray[aRow - 1][aCol - 1][i]);
          end
          else
          if i <> DataArray[aRow - 1][aCol - 1].Count - 1 then
          begin
            DataStringGrid.Canvas.TextOut(aRect.Left + Margin, aRect.Top +
              i*DefHeightFont, DataArray[aRow - 1][aCol - 1][i]);
            for k:= 1 to 2 do
            begin
              Img.LoadFromFile('icon\' + ListNamesFile[k]);
              DataStringGrid.Canvas.Draw(DefWidthCol + aRect.Left - Img.Width -
                Margin, aRect.Top + (k)*Img.Height + 2*Margin +
                DefHeightRow*(round(i/8)), Img.Graphic);
            end;
          end;
        end;
      end;
      Img.Free;
    end;
  end;
end;

procedure TTimeTableForm.DataStringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DataStringGrid.MouseToCell(x, y, Col, Row);
  //HandlerClick (Col, Row);
end;

procedure TTimeTableForm.DataStringGridMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, k, Summ: integer;
  RightCorner, LeftCorner: integer;
  Fy, Fx, NumCol, r: integer;
begin
  DataStringGrid.MouseToCell(x, y, Col, Row);
  if (Col = 0) or (Row = 0) then exit;
  Summ:= DataStringGrid.RowHeights[0];
  for i:=1 to DataStringGrid.RowCount do
  begin
    Summ:= Summ + DataStringGrid.RowHeights[i] + 1;
    if Summ > y then
    begin
      Fy:= y - (Summ - DataStringGrid.RowHeights[i] - 1);
      break;
    end;
  end;
  Fx:= x - DataStringGrid.ColWidths[0] - (Col - DataStringGrid.LeftCol)*DefWidthCol;
  if (Fx < DefWidthCol - Margin) and (Fx > DefWidthCol - DefWidthImg - Margin) then
  begin
    if (Fy < DefWidthImg + Margin) and (Fy > Margin) then
      ShowMessage('Добавить')
    else
    begin
      NumCol:= Fy div DefHeightRow;
      r:= 0;
      for i:= 1 to 2 do
        if (Fy > (Margin + DefWidthImg)*i) and
          (Fy < (Margin + DefWidthImg)*(i + 1)) then
        begin
          r:= i;
          break;
        end;
       case r of
       1:

         ;
       2:

         ;
       end;
    end;
  end;
end;

procedure TTimeTableForm.HandlerClick (aCol, aRow: integer);
var
  i, k, Summ: integer;
begin
  {ShowMessage(IntToStr(aCol) + ' ' + IntToStr(aRow));
  Summ:= 0;
  if (aCol = 0) or (aRow = 0) then exit;
  for i:=1 to DataStringGrid.RowCount do
  begin
    Summ:= Summ + DataStringGrid.RowHeights[i];
    if Summ > y
  end;  }
end;

procedure TTimetableForm.ApplyFilter(Sender: TObject);
begin
   AddQueryFilter;
end;

procedure TTimetableForm.AddQueryFilter ();
var
  i, c: integer;
begin
  SQLQuery1.Close;
  FiltersManager.GenQueryFilter(SQLQuery1, Tag);
  SQLQuery1.SQL.Append(CreateSortQuery(Tag));
  SQLQuery1.Open;
end;

procedure TTimetableForm.FillGridData ();
var
  ColTemp, RowTemp: TStringList;
  i, j, k, c, r: integer;
  procedure FillCell (ACol, ARow: integer);
  var
    k: integer;
    s: string;
  begin
    if DataArray[r][c] = nil then
      DataArray[r][c]:= TStringList.Create ;
    for k:=0 to SQLQuery1.FieldCount - 1 do
    begin
      s:= MetaData.MetaTables[Tag].Fields[k].Caption;
      DataArray[r][c].Append(s + ': ' + SQLQuery1.Fields[k].AsString);
    end;
    DataArray[r][c].Append('');
  end;
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Text:= SQLGen(Tag).Text;
  SQLQuery1.SQL.Append('ORDER BY ' + GetNameField(Tag, ColumnCB.ItemIndex) +
    ', ' + GetNameField(Tag, RowCB.ItemIndex));
  SQLQuery1.Open;
  RowTemp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(RowCB.ItemIndex + 1);
  ColTemp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(ColumnCB.ItemIndex + 1);
  DataStringGrid.ColCount:= ColTemp.Count + 1;
  DataStringGrid.RowCount:= RowTemp.Count + 1;
  SetLength(DataArray, 0);
  SetLength(DataArray, RowTemp.Count);
  for i:= 0 to RowTemp.Count - 1 do
  begin
    SetLength(DataArray[i], ColTemp.Count);
  end;
  RowTemp.IndexOf(SQLQuery1.Fields[RowCB.ItemIndex + 1].AsString);
  while not SQLQuery1.EOF do
  begin
    r:= RowTemp.IndexOf(SQLQuery1.Fields[RowCB.ItemIndex + 1].AsString);
    c:= ColTemp.IndexOf(SQLQuery1.Fields[ColumnCB.ItemIndex + 1].AsString);
    FillCell(c, r);
    SQLQuery1.Next;
  end;
  ChangeCaptionColumn(ColTemp, RowTemp);
end;

procedure TTimetableForm.DelFilter(ATag: integer);
begin
  FiltersManager.DelFilter(ATag);
  if FiltersManager.GetCountFilters = 0 then
  begin
    FiltersManager.isFiltred:= false;
    DataStringGrid.Width:= Width - OpenFiltersPanelBtn.Width - 8;
    FiltersPanel.Visible:= false;
  end;
  AddQueryFilter;
end;

procedure TTimetableForm.ChangeCaptionColumn(AColList, ARowList: TStringList);
var
  i, k: integer;
begin
  for i:= 1 to AColList.Count do
  begin
    DataStringGrid.ColWidths[i]:= DefWidthCol;
    DataStringGrid.Cells[i, 0]:= AColList[i - 1];
  end;
  for k:= 1 to ARowList.Count do
  begin
    DataStringGrid.RowHeights[k]:= DefHeightRow;
    DataStringGrid.Cells[0, k]:= ARowList[k - 1];
  end;
  with MetaData.MetaTables[Tag].Fields[RowCB.ItemIndex + 1] do
    DataStringGrid.ColWidths[0]:= Width;
  DataStringGrid.Canvas.Pen.Color:= clBlack;
  DataStringGrid.Canvas.TextOut(30, 30, AColList[i - 1]);
end;

end.

