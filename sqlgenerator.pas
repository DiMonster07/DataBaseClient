unit SqlGenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, Forms, DBGrids, Controls,
  Graphics, Dialogs, ExtCtrls, Menus, DbCtrls, Grids, DBConnection, meta,
  StdCtrls, Buttons;

function SQLGen (ANum: integer): TStringList;
function CreateSortQuery (ATag: integer): string;
function GenQueryChanges(): TStringList;
function GenUniqId (): integer;
function GenInsertQuery(ANum: integer): TStringList;
function GenUpdateQuery(ANum: integer): TStringList;
function GetNameField(ATag, Index: integer): string;

implementation

function SQLGen (ANum: integer): TStringList;
var
  i: integer;
  a, b, res: TStringList;
  head: string;
  s1: String;
  temp: TMField;
begin
  a:= TStringList.Create;
  b:= TStringList.Create;
  res:= TStringList.Create;
  head:= 'SELECT ';
  a.Append('FROM ' + MetaData.MetaTables[ANum].Name);
  for i:=0 to high(MetaData.MetaTables[ANum].Fields) do
  begin
    temp:= MetaData.MetaTables[ANum].Fields[i];
    if i > 0 then head+= ', ';
    if temp.Reference <> nil then
    begin
      head+= MetaData.MetaTables[temp.Reference.TableTag].Name + '.' +
        MetaData.MetaTables[temp.Reference.TableTag].Fields[1].Name;
      s1:= 'INNER JOIN ' + MetaData.MetaTables[temp.Reference.TableTag].Name +
        ' ON ' + MetaData.MetaTables[temp.Reference.TableTag].Name  + '.' +
        temp.Reference.Name + ' = ' + MetaData.MetaTables[ANum].Name + '.' +
        MetaData.MetaTables[ANum].Fields[i].Name;
      b.Append(s1);
      a.Append(b.text);
      b.clear;
    end
    else
    begin
      head+= ' '+ MetaData.MetaTables[ANum].Name + '.' +
        MetaData.MetaTables[ANum].Fields[i].Name;
    end;
  end;
  res.Append(head);
  res.Append(a.text);
  result:= res;
end;

function GetNameField(ATag, Index: integer): string;
var
  t: integer;
begin
  if MetaData.MetaTables[ATag].Fields[index + 1].Reference <> nil then
  begin
    t:= MetaData.MetaTables[ATag].Fields[index + 1].Reference.TableTag;
    result:= MetaData.MetaTables[t].Name + '.' +
      MetaData.MetaTables[t].Fields[1].Name;
  end
  else
    result:= MetaData.MetaTables[ATag].Name + '.' +
      MetaData.MetaTables[ATag].Fields[index + 1].Name;
end;

function CreateSortQuery (ATag: integer): string;
var
  i, c, t: integer;
  s, ts: string;
begin
  c:= 0;
  for i:= 0 to high(MetaData.MetaTables[ATag].Fields) do
  begin
    ts:= '';
    case MetaData.MetaTables[ATag].Fields[i].isOrder of
      Up, Down:
        begin
          if MetaData.MetaTables[ATag].Fields[i].Reference <> nil then
          begin
            t:= MetaData.MetaTables[ATag].Fields[i].Reference.TableTag;
            ts:= MetaData.MetaTables[t].Name + '.';
            if MetaData.MetaTables[t].Name = 'WEEKDAYS' then
              ts+= MetaData.MetaTables[t].Fields[0].Name
            else
              ts+= MetaData.MetaTables[t].Fields[1].Name;
          end
          else
            ts:= MetaData.MetaTables[ATag].Name + '.' +
              MetaData.MetaTables[ATag].Fields[i].Name;
          if MetaData.MetaTables[ATag].Fields[i].isOrder = Up then
            ts+= ' ASC'
          else
            ts+= ' DESC';
          if c <> 0 then
            s:= s + ',' + ts
          else
            s:= s + ts;
          inc(c);
        end;
    end;
  end;
  if c <> 0 then
    s:= 'ORDER BY ' + s;
  result:= s;
end;

function GenQueryChanges(): TStringList;
var
  i, j, k: integer;
  s1, s2, s3: string;
  temp: TStringList;
begin
  Temp:= TStringList.Create;
end;

function GenInsertQuery(ANum: integer): TStringList;
var
  i, k: integer;
  s1, s2, s3: string;
  temp: TStringList;
begin
  temp:= TStringList.Create;
  s1:= 'INSERT INTO ' + MetaData.MetaTables[ANum].Name;
  for i:=0 to high(MetaData.MetaTables[ANum].Fields) do
  begin
    s2:= s2 + MetaData.MetaTables[ANum].Fields[i].Name;
    if i <> high(MetaData.MetaTables[ANum].Fields) then
      s2+= ', ';
    s3:= s3 + ':p' + IntToStr(i) + ' ';
    if i <> high(MetaData.MetaTables[ANum].Fields) then
      s3+= ', ';
  end;
  s1+= ' (' + s2 + ')';
  temp.Append(s1);
  temp.Append('VALUES (' + s3 + ')');
  result:= temp;
end;

function GenUpdateQuery(ANum: integer): TStringList;
var
  i, k: integer;
  s1, s2: string;
  temp: TStringList;
begin
  temp:= TStringList.Create;
  s1:= 'UPDATE ' + MetaData.MetaTables[ANum].Name + ' SET ';
  temp.Append(s1);
  s1:= '';
  for i:=1 to high(MetaData.MetaTables[ANum].Fields) do
  begin
    s1:=MetaData.MetaTables[ANum].Fields[i].Name + ' = :p' + IntToStr(i);
    if i <> high(MetaData.MetaTables[ANum].Fields) then
      s1+= ' , ';
    temp.Append(s1);
  end;
  temp.Append('WHERE ID = :p0' );
  result:= temp;
end;

function GenUniqId (): integer;
begin
  DataModule1.SQLQuery.Close;
  DataModule1.SQLQuery.SQL.Text:=
    'SELECT GEN_ID(genuniq_id, 1) FROM RDB$DATABASE';
  DataModule1.SQLQuery.Open;
  result:= DataModule1.SQLQuery.Fields[0].AsInteger;
end;

end.

