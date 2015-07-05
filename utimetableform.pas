unit Utimetableform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  DBGrids, DbCtrls, ExtCtrls, StdCtrls, Buttons, Grids, CheckLst, Menus, FormChangeData,
  meta, SqlGenerator, DBConnection, GenerationForms, windows, ComObj, Variants;

type

  { TCellsManager }

  TCellsManager = class
  public
    procedure DrawImg (ACanvas: TCanvas; ARect: TRect; ACountItems: integer;
      ANum: integer);
    procedure DrawText (ARect: TRect);
  end;

  { TTimeTableForm }

  TTimeTableForm = class(TForm)
    MainMenu1: TMainMenu;
    ExpItem: TMenuItem;
    RowListBox: TCheckListBox;
    DataListBox: TCheckListBox;
    ColListBox: TCheckListBox;
    DataSource1: TDataSource;
    Label1: TLabel;
    ApplyBtn: TSpeedButton;
    SaveDialog1: TSaveDialog;
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
    procedure DataStringGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DataStringGridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DataStringGridShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure FormCreate(Sender: TObject);
    procedure CBChange(Sender: TObject);
    procedure ExpItemClick(Sender: TObject);
    procedure OpenFiltersPanelBtnClick(Sender: TObject);
    procedure RowListBoxItemClick(Sender: TObject; Index: integer);
  private
    DataArray: array of array of TStringList;
  public
    CellsManager: TCellsManager;
    FiltersManager: TFiltersManager;
    EditingManager: TEditingManager;
    procedure AddQueryFilter ();
    procedure ChangeCaptionColumn(AColList, ARowList: TStringList);
    procedure SetParams (Sender: TObject);
    procedure FillGridData ();
    procedure FillCB (AList: TStringList);
    procedure DelFilter();
    procedure InsertClick (Ax, Ay: integer);
    procedure EditClick (Ax, Ay: integer);
    procedure DeleteClick (Ax, Ay: integer);
    function GetListDataCell (Ax, Ay: integer): TStringList;
    procedure FillListBox(AColList, ARowList: TStringList);
    function GetCountCheckedItems(): integer;
    procedure UpdateRowsHeight(Index: integer);
    procedure UpdateHeaderVisible ();
    procedure DragDropRecord(EndX, EndY: integer);
    function GetTextSaveToHTML(): TStringList;
    function ParsingDataCell(aRow, aCol, ANum: integer): TStringList;
    function GetCountColCheckedItems(): integer;
    function GetDataStringGrid (): TStringList;
    function GetDataSelection (): TStringList;
    procedure SaveInExcel(FileName: AnsiString);
  end;

var
  ListNamesImg: array [0..2] of string = ('tt_add.png','tt_edit.png',
    'tt_del.png');
  TimetableForm: TTimetableForm;

implementation
uses main;
var
  ImgArray: array [0..2] of TPicture;
  Row, Col, kX, kY: integer;
  cX, cY: integer;
  Margin: integer = 2;
  DefHeightFont: integer = 17;
  DefCountStr: integer = 8;
  DefWidthCol: integer = 350;
  CurrentRowHeight: integer;
  DefWidthImg: integer = 15;
  HeightCurrRow: integer;
  isMouseDown: boolean = false;
  isDragDrop: boolean = false;

{$R *.lfm}

{ TTimetableForm }

procedure TTimetableForm.FormCreate(Sender: TObject);
var
  i: integer;
begin
  FiltersManager:= TFiltersManager.Create;
  EditingManager:= TEditingManager.Create;
  CellsManager:= TCellsManager.Create;
  FiltersPanel.Visible:= false;
  DataStringGrid.Color:= clWindow;
  DelEditingForm:= @FDelEditingForm;
  FiltersManager.AfterApplying:= @FillGridData;
  FiltersManager.AfterDeleting:= @DelFilter;
  for i:=0 to high(ListNamesImg) do
  begin
    ImgArray[i]:= TPicture.Create;
    ImgArray[i].LoadFromFile('icon\' + ListNamesImg[i]);
  end;
end;

procedure TTimetableForm.SetParams (Sender: TObject);
var
  i: integer;
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

function TTimeTableForm.GetCountColCheckedItems(): integer;
var
  i, k: integer;
begin
  k:= 0;
  for i:=0 to ColListBox.Count - 1 do
    if ColListBox.Checked[i] then inc(k);
  Result:= k;
end;

procedure TTimeTableForm.CBChange(Sender: TObject);
begin
  ApplyBtn.Enabled:= true;
end;

procedure TTimeTableForm.ExpItemClick(Sender: TObject);
var
  s: string;
  stream: TFileStream;
  temp: TStringList;
begin
  if SaveDialog1.Execute then
  begin
    s:= SaveDialog1.FileName;
    case SaveDialog1.FilterIndex of
      1: begin
           temp:= TStringList.Create;
           try
             Stream := TFileStream.Create(Utf8ToAnsi(s), fmOpenReadWrite);
           except
             Stream := TFileStream.Create(Utf8ToAnsi(s), fmCreate);
           end;
           temp.Append(GetTextSaveToHTML().Text);
           temp.SaveToStream(stream);
           temp.free;
           Stream.Free;
           exit;
         end;
      2: begin
           SaveInExcel(s);
         end;
    end;
  end;
end;

procedure TTimeTableForm.SaveInExcel(FileName: string);
var
  ExlApp, Sheet, Workbook, ArrayData, Range, Cell1, Cell2, ff: OleVariant;
  i, j, k, t, r, c:integer;
  s: string;
  temp: TStringList;
begin
  ExlApp := CreateOleObject('Excel.Application');
  ExlApp.Visible := false;
  Workbook:= ExlApp.Workbooks.Add;
  Sheet := ExlApp.Workbooks[1].WorkSheets[1];
  Sheet.name:= 'TimeTable';
  r:=DataStringGrid.RowCount;
  c:=DataStringGrid.ColCount;
  temp:= TStringList.Create;
  ArrayData := VarArrayCreate([1, r, 1, c], varVariant);
  for i := 1 to r do
    ArrayData[i, 1] := DataStringGrid.Cells[0, i - 1];
  for j := 1 to c do
    ArrayData[1, j] := DataStringGrid.Cells[j - 1, 0];
  for i := 0 to r - 2 do
    for j := 0 to c - 2 do
    begin
      if RowListBox.Checked[i] and ColListBox.Checked[j] then
        if (DataArray[i][j]<> nil) and (DataArray[i][j].Count <> 0) then
          for k:= 0 to DataArray[i][j].Count - 1 do
            if DataArray[i][j][k] <> '' then
            begin
              if (DataListBox.Checked[k - (k div DefCountStr)*DefCountStr]) then
                temp.Append(DataArray[i ][j ][k]);
            end
            else
              temp.Append(' ');
      ArrayData[i + 2, j + 2] := temp.text;
      temp.clear;
    end;
  Cell1 := WorkBook.WorkSheets[1].Cells[1, 1];
  Cell2 := WorkBook.WorkSheets[1].Cells[r + 1, c + 1];
  Range := WorkBook.WorkSheets[1].Range[Cell1, Cell2];
  Range.Value := ArrayData;
  for i:= 1 to c do
    WorkBook.WorkSheets[1].Columns.Item[i].Autofit;
  ExlApp.DisplayAlerts := False;
  ExlApp.Visible := true;
  ff:= FileName;
  Workbook.SaveAs(ff);
  ExlApp.Quit;
  ExlApp := Unassigned;
  Sheet := Unassigned;
end;

function TTimeTableForm.GetTextSaveToHTML(): TStringList;
var
  temp: TStringList;
begin
  temp:= TStringList.Create;
  temp.Append('<html><head><meta charset="utf-8">' + '<style>' +
  'table { width: ' + IntToStr(DefWidthCol*GetCountColCheckedItems()) + 'px;' +
  'border: 1px solid #000; border-collapse:collapse;}' +
  'td { border: 1px solid #000; padding: 5px; vertical-align: top;}' +
  '</style></head><body>');
  temp.Append(GetDataSelection ().Text);
  temp.Append('<table>');
  temp.Append(GetDataStringGrid().Text);
  temp.Append('</table></html>');
  result:= temp;
end;

function TTimeTableForm.GetDataSelection (): TStringList;
var
  temp: TStringList;
  i: integer;
begin
  temp:= TStringList.Create;
  temp.Append('<table style="width: 900px;">');
  temp.Append('<p>Параметры выбора данных: <br></p><tr><td>');
  temp.Append('Строки: ' + RowCB.Caption + '<br>' +
    'Столбцы: ' + ColumnCB.Caption);
  temp.Append('</td><td>' + MetaData.MetaTables[RowCB.ItemIndex].Caption +
    ':<ul>');
  for i:= 0 to ColListBox.Count - 1 do
    if ColListBox.Checked[i] then
       temp.Append('<li>' + DataStringGrid.Cells[i + 1, 0] + '</li> ');
  temp.Append('</ul></td><td>');
  temp.Append(MetaData.MetaTables[ColumnCB.ItemIndex].Caption + ':<ul>');
  for i:= 0 to RowListBox.Count - 1 do
    if RowListBox.Checked[i] then
       temp.Append('<li>' + DataStringGrid.Cells[0, i + 1] + '</li> ');
  temp.Append('</ul></td><td>Фильтры: <br><ul>');
  for i:= 0 to high(FiltersManager.Filters) do
    if FiltersManager.Filters[i].isApply then
    begin
      with FiltersManager.Filters[i]do
      begin
         temp.Append('<li>' + NameBox.Caption + ' ' + ActionBox.Caption + ' ' +
           ValueEdit.Caption + '</li>');
      end;
    end;
  temp.Append('</ul></td></tr>');
  temp.Append('</table>');
  result:= temp;
end;

function TTimeTableForm.GetDataStringGrid (): TStringList;
var
  temp: TStringList;
  i, j, k: integer;
begin
  temp:= TStringList.Create;
  temp.Append('<br><tr>');
  temp.Append('<td>');
  temp.Append(RowCB.Caption);
  temp.Append('</td>');
  for k:= 0 to ColListBox.Count - 1 do
    if ColListBox.Checked[k] then
    begin
      temp.Append('<td>');
      temp.Append(DataStringGrid.Cells[k + 1, 0]);
      temp.Append('</td>');
    end;
  temp.Append('</tr>');
  for i:= 0 to high(DataArray) do
  begin
    if RowListBox.Checked[i] then
    begin
      temp.Append('<tr>');
      temp.Append('<td>');
      temp.Append(DataStringGrid.Cells[0, i + 1]);
      temp.Append('</td>');
      for k:= 0 to high(DataArray[i]) do
        if ColListBox.Checked[k] then
        begin
          temp.Append('<td>');
          if (DataArray[i][k]<> nil) and (DataArray[i][k].Count <> 0) then
          begin
            for j:=0 to DataArray[i][k].Count - 1 do
            begin
              if DataArray[i][k][j] <> '' then
              begin
                if (DataListBox.Checked[j - (j div DefCountStr)*DefCountStr]) then
                  temp.Append(AnsiString(DataArray[i][k][j]) + '<br>');
              end
              else
                  temp.Append('<br>');
            end;
          end;
          temp.Append('</td>');
        end;
      temp.Append('</tr>');
    end;
  end;
  result:= temp;
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
    UpdateRowsHeight(Index);
    DataStringGrid.Invalidate;
  end;
end;

function TTimeTableForm.GetListDataCell (Ax, Ay: integer): TStringList;
var
  i, k, RecordNum: integer;
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

procedure TTimeTableForm.DragDropRecord(EndX, EndY: integer);
var
  i, key: integer;
  tX, tY: integer;
  NumRec: integer;
  DataCell, temp: TStringList;
  s: string;
begin
  tY:= kY - DataStringGrid.CellRect(Col, Row).Top;
  tX:= kX - DataStringGrid.CellRect(Col, Row).Left;
  NumRec:= tY div CurrentRowHeight;
  DataModule1.SQLQuery.Close;
  key:= GenUniqId();
  DataCell:= ParsingDataCell(Row, Col, NumRec);
  DataStringGrid.MouseToCell(EndX, EndY, Col, Row);
  DataModule1.SQLQuery.Close;
  DataModule1.SQLQuery.SQL.Text:= 'DELETE FROM ' +
    MetaData.MetaTables[Tag].Name + ' WHERE ID = ' + DataCell[0];
  DataModule1.SQLQuery.ExecSQL;
  DataModule1.SQLQuery.Close;
  DataCell[RowCB.ItemIndex + 1]:= DataStringGrid.Cells[0, Row];
  DataCell[ColumnCB.ItemIndex + 1]:= DataStringGrid.Cells[Col, 0];
  DataModule1.SQLQuery.SQL.Text:= GenInsertQuery(Tag).Text;
  DataModule1.SQLQuery.ParamByName('p0').AsInteger:= StrToInt(DataCell[0]);
  for i:= 1 to high(MetaData.MetaTables[Tag].Fields) do
  begin
    s:= 'p' + IntToStr(i);
    if MetaData.MetaTables[Tag].Fields[i].Reference <> nil then
    begin
      temp:= MetaData.MetaTables[Tag].GetDataFieldOfIndex(i);
      DataModule1.SQLQuery.ParamByName(s).AsInteger:=
        GetId(Tag, i - 1, temp.IndexOf(DataCell[i]))
    end
    else
      DataModule1.SQLQuery.ParamByName(s).AsString:= DataCell[i];
  end;
  DataModule1.SQLQuery.ExecSQL;
  //DataModule1.SQLTransaction1.Commit;
  GlobalUpdate(Tag);
end;

function TTimeTableForm.ParsingDataCell(aRow, aCol,
  ANum: integer): TStringList;
var
  i, c: integer;
  temp, curr: TStringList;
  s: string;
begin
  c:= 0;
  temp:= TStringList.Create;
  curr:= DataArray[aRow - 1][aCol - 1];
  for i:= DefCountStr*ANum to DefCountStr*(ANum + 1) - 2 do
  begin
    s:= curr[i];
    delete(s, 1, pos(':', s) + 1);
    temp.Append(s);
  end;
  result:= temp;
end;

procedure TTimeTableForm.DataStringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DataStringGrid.MouseToCell(x, y, Col, Row);
  kX:= x; kY:= y;
  isMouseDown:= true;
end;

procedure TTimeTableForm.DataStringGridMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  cX:= x;
  cY:= y;
  if isMouseDown then isDragDrop:= true;
end;

procedure TTimeTableForm.DataStringGridMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, count: integer;
  tCol, tRow: integer;
  Fy, Fx, NumCol, r: integer;
  s: string;
  temp: TStringList;
begin
  DataStringGrid.MouseToCell(x, y, tCol, tRow);
  if (tCol = 0) or (tRow = 0) then exit;
  if ((Row <> tRow) or (Col <> tCol)) and (DataArray[Row - 1][Col - 1] <> nil)
    and (DataArray[Row - 1][Col - 1].Count <> 0) then
  begin
    DragDropRecord(x, y);
    exit;
  end;
  HeightCurrRow:= DataStringGrid.RowHeights[Row];
  DataStringGrid.MouseToCell(x, y, Col, Row);
  if Button = mbRight then
  begin
    temp:= TStringList.Create;
    ProgramForm.DirItem.Items[Tag].Click;
    FormsOfTables.FForms[Tag].FiltersManager.DeleteAllFilters();
    temp.Append(IntToStr(RowCB.ItemIndex)); temp.Append(IntToStr(4));
    temp.Append(DataStringGrid.Cells[0, Row]);
    temp.Append(IntToStr(ColumnCB.ItemIndex)); temp.Append(IntToStr(4));
    temp.Append(DataStringGrid.Cells[Col, 0]);
    FormsOfTables.FForms[Tag].AddSomeFilters(2, temp);
    exit;
  end;
  count:= GetCountCheckedItems + 1;
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
  isMouseDown:= false;
end;

procedure TTimeTableForm.DataStringGridShowHint(Sender: TObject;
  HintInfo: PHintInfo);
begin

end;

 { TCellsManager }

 procedure TCellsManager.DrawImg (ACanvas: TCanvas; ARect: TRect;
   ACountItems: integer; ANum: integer);
 var
   i: integer;
 begin
   with ACanvas do
     for i:= 1 to 2 do
     begin
       Draw(DefWidthCol + aRect.Left - ImgArray[i].Width - Margin,
         aRect.Top + (i)*ImgArray[i].Height + 2*Margin +
         ACountItems*DefHeightFont*ANum, ImgArray[i].Graphic);
     end;
 end;

 procedure TCellsManager.DrawText (ARect: TRect);
 begin

 end;

 { DataStringGrid }

procedure TTimeTableForm.DataStringGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  i, c, j,  count: integer;
begin
  if (length(DataArray) <> 0) and (aRow <> 0) and (aCol <> 0) then
  begin
   { if isDragDrop and (Row <> aRow) and (Col <> aCol) then
    begin
      DataStringGrid.Canvas.Brush.Color:= clInfoBk;
      DataStringGrid.Canvas.FillRect(DataStringGrid.CellRect(Col, Row));
      isDragDrop:= false;
    end;   }
    with DataStringGrid.Canvas do
    begin
      count:= GetCountCheckedItems + 1;
      Draw(DefWidthCol + aRect.Left - ImgArray[0].Width - Margin, aRect.Top +
        Margin, ImgArray[0].Graphic);
      if (DataArray[aRow - 1][aCol - 1] <> nil) and
        (DataArray[aRow - 1][aCol - 1].Count <> 0) then
      begin
        CellsManager.DrawImg (DataStringGrid.Canvas, aRect, Count, 0);
        c:= DataArray[aRow - 1][aCol - 1].Count div 8;
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
            CellsManager.DrawImg (DataStringGrid.Canvas, aRect, Count,
              round(i/DefCountStr));
          end;
        end;
        if DataStringGrid.RowHeights[aRow] < c*CurrentRowHeight then
        begin
          Font.Color:= clGreen;
          Font.Bold;
          Font.Size:= 10;
          TextOut(DefWidthCol + aRect.Left - 27 - Margin,
            aRect.Top + DataStringGrid.RowHeights[aRow] - 20, ' ↓ ' +
            IntToStr(c - DataStringGrid.RowHeights[aRow] div CurrentRowHeight));
          Font.Color:= clBlack;
          Font.Size:= 0;
        end;
      end;
    end;
    DataStringGrid.Canvas.Brush.Color:= clWhite;
  end;
end;

procedure TTimeTableForm.UpdateRowsHeight(Index: integer);
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
  i, k: integer;
begin
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
  i, c, r: integer;
  procedure FillCell (ARow, ACol: integer);
  var
    k: integer;
    s: string;
  begin
    if DataArray[aRow][aCol] = nil then
      DataArray[aRow][aCol]:= TStringList.Create ;
    for k:=0 to SQLQuery1.FieldCount - 1 do
    begin
      s:= MetaData.MetaTables[Tag].Fields[k].Caption;
      DataArray[aRow][aCol].Append(s + ': ' + SQLQuery1.Fields[k].AsString);
    end;
    DataArray[aRow][aCol].Append('');
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
    SetLength(DataArray[i], ColTemp.Count);
  RowTemp.IndexOf(SQLQuery1.Fields[RowCB.ItemIndex + 1].AsString);
  while not SQLQuery1.EOF do
  begin
    r:= RowTemp.IndexOf(SQLQuery1.Fields[RowCB.ItemIndex + 1].AsString);
    c:= ColTemp.IndexOf(SQLQuery1.Fields[ColumnCB.ItemIndex + 1].AsString);
    FillCell(r, c);
    SQLQuery1.Next;
  end;
  ChangeCaptionColumn(ColTemp, RowTemp);
  UpdateHeaderVisible();
  DataStringGrid.Invalidate;
end;

{ Filters }

procedure TTimetableForm.DelFilter();
begin
  if FiltersManager.GetCountFilters = 0 then
  begin
    FiltersManager.isFiltred:= false;
    DataStringGrid.Width:= Width - OpenFiltersPanelBtn.Width - 8;
    FiltersPanel.Visible:= false;
  end;
  FillGridData;
end;

procedure TTimetableForm.AddQueryFilter ();
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
  EditingManager.SetItemIndex(RowCB.ItemIndex, Row - 1, ColumnCB.ItemIndex, Col - 1);
  if (Col > 0) and (Row > 0) then
    DataStringGrid.Selection:= DataStringGrid.CellRect(Col, Row);
  DataStringGrid.RowHeights[Row]:= HeightCurrRow;
end;

procedure TTimeTableForm.EditClick (Ax, Ay: integer);
begin
  EditingManager.OpenFormEditingTable (ctEdit, Tag, GetListDataCell(Ax, Ay));
  if (Col > 0) and (Row > 0) then
    DataStringGrid.Selection:= DataStringGrid.CellRect(Col, Row);
  DataStringGrid.RowHeights[Row]:= HeightCurrRow;
end;

procedure TTimeTableForm.DeleteClick (Ax, Ay: integer);
begin
  EditingManager.DeleteRecord(StrToInt(GetListDataCell(Ax, Ay)[0]), Tag);
  FillGridData();
  if (Col > 0) and (Row > 0) then
    DataStringGrid.Selection:= DataStringGrid.CellRect(Col, Row);
  DataStringGrid.RowHeights[Row]:= HeightCurrRow;
end;

end.

