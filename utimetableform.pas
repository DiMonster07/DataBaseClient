unit Utimetableform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, CheckLst, FormChangeData,
  meta, SqlGenerator, DBConnection, GenerationForms, windows;

type

  { TTimeTableForm }

  TTimeTableForm = class(TForm)
    RowListBox: TCheckListBox;
    DataListBox: TCheckListBox;
    ColListBox: TCheckListBox;
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
    procedure DataListBoxItemClick(Sender: TObject; Index: integer);
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
    procedure RowListBoxItemClick(Sender: TObject; Index: integer);
  private
    DataArray: array of array of TStringList;
  public
    FiltersManager: TFiltersManager;
    EditingManager: TEditingManager;
    procedure AddQueryFilter ();
    procedure ChangeCaptionColumn(AColList, ARowList: TStringList);
    procedure SetParams (Sender: TObject);
    procedure FillGridData ();
    procedure FillCB (AList: TStringList);
    procedure DelFilter(ATag: integer);
    procedure InsertClick (Ax, Ay: integer);
    procedure EditClick (Ax, Ay: integer);
    procedure DeleteClick (Ax, Ay: integer);
    function GetListDataCell (Ax, Ay: integer): TStringList;
    procedure FillListBox(AColList, ARowList: TStringList);
    function GetCountCheckedItems(): integer;
    procedure UpdateHeightRows(Index: integer);
    procedure UpdateHeaderVisible ();
  end;

var
  ListNamesFile: array [0..2] of string = ('tt_add.png','tt_edit.png',
    'tt_del.png');
  Margin: integer = 2;
  DefHeightFont: integer = 17;
  DefCountStr: integer = 8;
  TimetableForm: TTimetableForm;
  DefWidthCol: integer = 350;
  CurrentRowHeight: integer;
  DefWidthImg: integer = 15;
  SelectedCellRow, SelectedCellCol: integer;
implementation
var
  Row, Col: integer;
{$R *.lfm}

{ TTimetableForm }

procedure TTimetableForm.FormCreate(Sender: TObject);
begin
  FiltersManager:= TFiltersManager.Create;
  EditingManager:= TEditingManager.Create;
  FiltersPanel.Visible:= false;
  DataStringGrid.Color:= clWindow;
  DelEditingForm:= @FDelEditingForm;
end;

procedure TTimetableForm.SetParams (Sender: TObject);
var
  i, t: integer;
  ord: string;
  temp: TStringList;
begin
  Tag:= 8;
  FiltersPanel.Tag:= Tag;
  AddFilterBtn.Tag:= Tag;
  temp:= FiltersManager.GenDataForCB(Tag);
  FillCB(temp);
  Caption:= MetaData.MetaTables[Tag].Caption;
  for i:= 0 to high(MetaData.MetaTables[Tag].Fields) do
    DataListBox.Items.Add(MetaData.MetaTables[Tag].Fields[i].Caption);
  DataListBox.CheckAll(cbChecked);
  DataListBox.Checked[0]:= false;
  CurrentRowHeight:= (GetCountCheckedItems + 1) * DefHeightFont;
  ApplyBtnClick(Self);
end;

procedure TTimeTableForm.CBChange(Sender: TObject);
begin
  ApplyBtn.Enabled:= true;
end;

procedure TTimeTableForm.FillListBox(AColList, ARowList: TStringList);
  procedure FillBox (AListBox: TCheckListBox; AList: TStringList);
  var
    i: integer;
    max: integer = 0;
  begin
    AListBox.Clear;
    for i:=0 to AList.Count - 1 do
    begin
      AListBox.Items.Add(AList[i]);
      if length(AList[i]) > max then max:= length(AList[i]);
    end;
    AListBox.CheckAll(cbChecked);
    if max > 25 then max:= 25;
    AListBox.Width:= max*DefCountStr + 50;
  end;
begin
  FillBox(ColListBox, AColList);
  FillBox(RowListBox, ARowList);
  ColListBox.Left:= RowListBox.Left + RowListBox.Width + 5;
  DataListBox.Left:= ColListBox.Left + ColListBox.Width + 5;
end;

function TTimeTableForm.GetCountCheckedItems(): integer;
var
  i, c: integer;
begin
  c:= 0;
  for i:=0 to DataListBox.Count - 1 do
    if DataListBox.Checked[i] then inc(c);
  result:= c;
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
end;

procedure TTimeTableForm.ApplyBtnClick(Sender: TObject);
var
  RowTemp, ColTemp: TstringList;
begin
  RowTemp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(RowCB.ItemIndex + 1);
  ColTemp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(ColumnCB.ItemIndex + 1);
  ApplyBtn.Enabled:= false;
  FillListBox(ColTemp, RowTemp);
  FillGridData();
  UpdateHeaderVisible();
end;

procedure TTimeTableForm.RowListBoxItemClick(Sender: TObject; Index: integer);
begin
  UpdateHeaderVisible();
end;

procedure TTimeTableForm.UpdateHeaderVisible ();
var
  i: integer;
begin
  for i:= 1 to DataStringGrid.RowCount - 1 do
  begin
    if not RowListBox.Checked[i - 1] then
      DataStringGrid.RowHeights[i]:= 0
    else if DataStringGrid.RowHeights[i] = 0 then
      DataStringGrid.RowHeights[i]:= CurrentRowHeight;
  end;
  for i:= 1 to DataStringGrid.ColCount - 1 do
  begin
    if not ColListBox.Checked[i - 1] then
      DataStringGrid.ColWidths[i]:= 0
    else
      DataStringGrid.ColWidths[i]:= DefWidthCol;
  end;
end;

procedure TTimeTableForm.DataListBoxItemClick(Sender: TObject; Index: integer);
begin
  if GetCountCheckedItems < 3 then
    DataListBox.Checked[Index]:= true
  else
  begin
    CurrentRowHeight:= (GetCountCheckedItems + 1)*DefHeightFont;
    UpdateHeightRows(Index);
    DataStringGrid.Invalidate;
  end;
end;

function TTimeTableForm.GetListDataCell (Ax, Ay: integer): TStringList;
var
  i, k, j, RecordNum: integer;
  s: string;
  temp: TStringList;
begin
  temp:= TStringList.Create;
  RecordNum:= AY div CurrentRowHeight;
  if DataArray[Row - 1][Col - 1] <> nil then
    for i:=RecordNum*DefCountStr to RecordNum*DefCountStr + 6 do
    begin
      s:= DataArray[Row - 1][Col - 1][i];
      k:= pos(':', s);
      delete(s, 1, k + 1);
      temp.Append(s);
    end;
  result:= temp;
end;

procedure TTimeTableForm.DataStringGridDblClick(Sender: TObject);
var
  count: integer;
begin
  if (Row = 0) or (Col = 0) then exit;
  if DataStringGrid.RowHeights[Row] > CurrentRowHeight then
  begin
    if DataArray[Row - 1][Col - 1] = nil then
    begin
      DataStringGrid.RowHeights[Row]:= CurrentRowHeight;
      exit;
    end;
    count:= round(DataArray[Row - 1][Col - 1].Count/DefCountStr);
    if DataStringGrid.RowHeights[Row] < CurrentRowHeight*count then
      DataStringGrid.RowHeights[Row]:= CurrentRowHeight*count
    else
      DataStringGrid.RowHeights[Row]:= CurrentRowHeight
  end
  else
  if (DataArray[Row - 1][Col - 1] <> nil) then
    DataStringGrid.RowHeights[Row]:= CurrentRowHeight*
      round(DataArray[Row - 1][Col - 1].Count/DefCountStr);
end;

procedure TTimeTableForm.DataStringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DataStringGrid.MouseToCell(x, y, Col, Row);
end;

procedure TTimeTableForm.DataStringGridMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, k, Summ, count: integer;
  RightCorner, LeftCorner: integer;
  Fy, Fx, NumCol, r: integer;
begin
  DataStringGrid.MouseToCell(x, y, Col, Row);
  if (Col = 0) or (Row = 0) then exit;
  Fy:= y - DataStringGrid.CellRect(Col, Row).Top;
  Fx:= x - DataStringGrid.CellRect(Col, Row).Left;
  if (Fx < DefWidthCol - Margin) and (Fx > DefWidthCol - DefWidthImg - Margin) then
  begin
    if (Fy < DefWidthImg + Margin) and (Fy > Margin) then
      InsertClick(Fx, Fy)
    else
    begin
      NumCol:= Fy div (count*DefHeightFont);
      r:= 0;
      for i:= 1 to 2 do
        if (Fy > (Margin + DefWidthImg)*i + CurrentRowHeight*NumCol) and
          (Fy < (Margin + DefWidthImg)*(i + 1) + CurrentRowHeight*NumCol) then
        begin
          r:= i;
          break;
        end;
       case r of
         1: EditClick(Fx, Fy);
         2: DeleteClick(Fx, Fy);
       end;
    end;
  end;
end;

 { DataStringGrid }

procedure TTimeTableForm.DataStringGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  i, k, c, j,  count: integer;
  img: TPicture;
begin
  if length(DataArray) <> 0 then
  begin
    with DataStringGrid.Canvas do
    begin
      count:= GetCountCheckedItems + 1;
      img:= TPicture.Create;
      if (aRow <> 0) and (aCol <> 0) then
      begin
        Img.LoadFromFile('icon\' + ListNamesFile[0]);
        Draw(DefWidthCol + aRect.Left - Img.Width - Margin, aRect.Top + Margin,
          Img.Graphic);
        if (DataArray[aRow - 1][aCol - 1] <> nil) and
          (DataArray[aRow - 1][aCol - 1].Count <> 0) then
        begin
          for i:= 1 to 2 do
          begin
            Img.LoadFromFile('icon\' + ListNamesFile[i]);
            Draw(DefWidthCol + aRect.Left - Img.Width - Margin,
              aRect.Top + Margin + i*Img.Height + Margin, Img.Graphic);
          end;
          c:= round(DataArray[aRow - 1][aCol - 1].Count/8);
          if DataStringGrid.RowHeights[aRow] < c*CurrentRowHeight then
          begin
            Font.Color:= clGreen;
            Font.Bold;
            Font.Size:= 10;
            TextOut(DefWidthCol + aRect.Left - 27 - Margin,
              aRect.Top + DataStringGrid.RowHeights[aRow] - 20, ' ↓ ' +
              IntToStr(c - round(DataStringGrid.RowHeights[aRow]/
              CurrentRowHeight)));
            Font.Color:= clBlack;
            Font.Size:= 0;
          end;
          j:= -1;
          for i:= 0 to DataArray[aRow - 1][aCol - 1].Count - 1 do
          begin
            if DataArray[aRow - 1][aCol - 1][i] <> '' then
            begin
              if DataListBox.Checked[i - (i div DefCountStr)*DefCountStr] then
              begin
                inc(j);
                TextOut(aRect.Left + Margin, aRect.Top +
                  j*DefHeightFont, DataArray[aRow - 1][aCol - 1][i]);
              end;
            end
            else
            if i <> DataArray[aRow - 1][aCol - 1].Count - 1 then
            begin
              inc(j);
              TextOut(aRect.Left + Margin, aRect.Top + j*DefHeightFont,
                DataArray[aRow - 1][aCol - 1][i]);
              for k:= 1 to 2 do
              begin
                Img.LoadFromFile('icon\' + ListNamesFile[k]);
                Draw(DefWidthCol + aRect.Left - Img.Width - Margin,
                  aRect.Top + (k)*Img.Height + 2*Margin +
                  count*DefHeightFont*(round(i/DefCountStr)), Img.Graphic);
              end;
            end;
          end;
        end;
      end;
      Img.Free;
    end;
  end;
end;

procedure TTimeTableForm.UpdateHeightRows(Index: integer);
var
  k, c: integer;
begin
  for k:= 1 to DataStringGrid.RowCount - 1 do
  begin
    if CurrentRowHeight >= DataStringGrid.RowHeights[k] then
      DataStringGrid.RowHeights[k]:= CurrentRowHeight
    else
    begin
      if DataListBox.Checked[Index] then
        c:= round(DataStringGrid.RowHeights[k]/
          (GetCountCheckedItems*DefHeightFont))
      else
        c:= round(DataStringGrid.RowHeights[k]/
          ((GetCountCheckedItems + 2)*DefHeightFont));
      DataStringGrid.RowHeights[k]:= c*CurrentRowHeight;
    end;
  end;
end;

procedure TTimetableForm.ChangeCaptionColumn(AColList, ARowList: TStringList);
var
  i, k, c: integer;
begin
  c:= GetCountCheckedItems;
  for i:= 1 to AColList.Count do
  begin
    DataStringGrid.ColWidths[i]:= DefWidthCol;
    DataStringGrid.Cells[i, 0]:= AColList[i - 1];
  end;
  for k:= 1 to ARowList.Count do
  begin
    DataStringGrid.RowHeights[k]:= CurrentRowHeight;
    DataStringGrid.Cells[0, k]:= ARowList[k - 1];
  end;
  with MetaData.MetaTables[Tag].Fields[RowCB.ItemIndex + 1] do
    DataStringGrid.ColWidths[0]:= Width;
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
  AddQueryFilter;
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
  UpdateHeaderVisible();
  DataStringGrid.Invalidate;
end;

{ Filters }

procedure TTimetableForm.DelFilter(ATag: integer);
begin
  FiltersManager.DelFilter(ATag);
  if FiltersManager.GetCountFilters = 0 then
  begin
    FiltersManager.isFiltred:= false;
    DataStringGrid.Width:= Width - OpenFiltersPanelBtn.Width - 8;
    FiltersPanel.Visible:= false;
  end;
  FillGridData;
end;

procedure TTimetableForm.AddQueryFilter ();
var
  i, c: integer;
begin
  SQLQuery1.Close;
  FiltersManager.GenQueryFilter(SQLQuery1, Tag);
  SQLQuery1.SQL.Append(CreateSortQuery(Tag));
end;

procedure TTimetableForm.AddFilterBtnClick(Sender: TObject);
begin
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

procedure TTimeTableForm.OpenFiltersPanelBtnClick(Sender: TObject);
begin
  FiltersPanel.Visible:= true;
  DataStringGrid.Width:= Width - FiltersPanel.Width;
  FiltersManager.AddFilter(FiltersPanel, Tag);
end;

{ Editing }

procedure TTimeTableForm.InsertClick (Ax, Ay: integer);
begin
  EditingManager.OpenFormEditingTable (ctInsert, Tag, GetListDataCell(Ax, Ay));
  DataStringGrid.Col:= Col;
  DataStringGrid.Row:= Row;
end;

procedure TTimeTableForm.EditClick (Ax, Ay: integer);
begin
  EditingManager.OpenFormEditingTable (ctEdit, Tag, GetListDataCell(Ax, Ay));
  DataStringGrid.Col:= Col;
  DataStringGrid.Row:= Row;
end;

procedure TTimeTableForm.DeleteClick (Ax, Ay: integer);
begin
  EditingManager.DeleteRecord(StrToInt(GetListDataCell(Ax, Ay)[0]), Tag);
  FillGridData();
  DataStringGrid.Col:= Col;
  DataStringGrid.Row:= Row;
end;

end.

