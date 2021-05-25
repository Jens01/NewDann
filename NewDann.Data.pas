// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unit NewDann.Data;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types;

type
  FlatArray = TArray<Single>;
  TDataType = (dtTrain, dtValid, dtTest);
  TDataTypes = TArray<TDataType>;

  TData = class
  strict private
    FDataText: TStringList;
    FData: TList<FlatArray>;
    FSeparator: string;
    FDecimalSeparator: Char;
    FErrorPos: TPoint;
    FOnError: TNotifyEvent;
    FOnChanged: TNotifyEvent;
    function DataTypeOfStr(s: string): TDataTypes;
    procedure ClearError;
    procedure CleanDataText;
    function GetItemCount: Integer; overload;
    function GetItemCount(Indx: Integer): Integer; overload;
    function GetIsValid: Boolean;
    function GetData(Indx: Integer): TArray<Single>;
    function IsItemCountValid: Boolean;
    function GetDataStr(Indx: Integer): TArray<string>;
    function LineTextToFloat(Indx: Integer; Format: TFormatSettings; var Res: FlatArray; var DataType: TDataTypes): Boolean;
    function TextToFloat(Format: TFormatSettings; P: TProc<FlatArray, TDataTypes>): Boolean;
    procedure MakeData;
    procedure SetSeparator(const Value: string);
    procedure SetDecimalSeparator(const Value: Char);
    procedure DoError;
    procedure DoChanged;
    procedure SetInputCount(const Value: Integer);
    procedure SetOutputCount(const Value: Integer);
    function GetDataCount: Integer;
  strict protected
    FError: string;
    FInputCount: Integer;
    FOutputCount: Integer;
    procedure ClearData; virtual;
    procedure ConserveData(r: FlatArray; DataType: TDataTypes); virtual;
    function ContainsType(dt: TDataTypes; DataType: TDataType): Boolean;
    function IsParseError(DataText: string; Pos: TPoint): Boolean; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadDataFromFile(Filename: string); overload;
    procedure LoadDataFromFile(Filename: string; Encoding: TEncoding); overload;
    procedure LoadDataFromArray(T: TArray<string>);
    procedure SaveToCSVFile(Filename: string; Encoding: TEncoding = nil);
    procedure AddData(Indx, Col: Integer; Data: TArray<Single>); virtual;
    function SliceOfData(Indx, Start, Count: Integer): TArray<Single>;
    property Data[Indx: Integer]: TArray<Single> read GetData; default;
    property DataCount: Integer read GetDataCount;
    property InputCount: Integer read FInputCount write SetInputCount;
    property OutputCount: Integer read FOutputCount write SetOutputCount;
    property Separator: string read FSeparator write SetSeparator;
    property DecimalSeparator: Char read FDecimalSeparator write SetDecimalSeparator;
    property ItemCount: Integer read GetItemCount;
    property IsValid: Boolean read GetIsValid;
    property Error: string read FError;
    property ErrorPos: TPoint read FErrorPos;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TTrainData = class(TData)
  strict private
    FTrainData: TList<FlatArray>;
    FValidData: TList<FlatArray>;
    FTestData: TList<FlatArray>;
    procedure ClearData; override;
    procedure ConserveData(r: FlatArray; DataType: TDataTypes); override;
    function IsParseError(DataText: string; Pos: TPoint): Boolean; override;
    function GetInTestData(Indx: Integer): TArray<Single>;
    function GetOutTestData(Indx: Integer): TArray<Single>;
    function GetInTrainData(Indx: Integer): TArray<Single>;
    function GetOutTrainData(Indx: Integer): TArray<Single>;
    function GetInValidData(Indx: Integer): TArray<Single>;
    function GetOutValidData(Indx: Integer): TArray<Single>;
    function GetTrainDataCount: Integer;
    function GetValidDataCount: Integer;
    function GetTestDataCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property InTestData[Indx: Integer]: TArray<Single> read GetInTestData;
    property OutTestData[Indx: Integer]: TArray<Single> read GetOutTestData;
    property InTrainData[Indx: Integer]: TArray<Single> read GetInTrainData;
    property OutTrainData[Indx: Integer]: TArray<Single> read GetOutTrainData;
    property InValidData[Indx: Integer]: TArray<Single> read GetInValidData;
    property OutValidData[Indx: Integer]: TArray<Single> read GetOutValidData;
    property TrainDataCount: Integer read GetTrainDataCount;
    property ValidDataCount: Integer read GetValidDataCount;
    property TestDataCount: Integer read GetTestDataCount;
  end;

implementation

function SliceOf(Q: TArray<Single>; Start, Count: Integer): TArray<Single>; inline;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i       := 0 to Count - 1 do
    Result[i] := Q[Start + i];
end;

{ TData }

constructor TData.Create;
begin
  inherited;
  FData := TList<FlatArray>.Create;

  FDataText := TStringList.Create;
  ClearError;
  FSeparator        := ';';
  FDecimalSeparator := ',';
  FInputCount       := 0;
  FOutputCount      := 0;
end;

destructor TData.Destroy;
begin
  FDataText.Free;
  FData.Free;
  inherited;
end;

procedure TData.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TData.DoError;
begin
  if Assigned(FOnError) then
    FOnError(Self);
end;

procedure TData.AddData(Indx, Col: Integer; Data: TArray<Single>);
var
  L: TList<Single>;
  i: Integer;
begin
  if Length(Data) > 0 then
  begin
    L := TList<Single>.Create;
    try
      for i := 0 to Col - 1 do
        L.Add(FData[Indx][i]);
      L.AddRange(Data);
      for i := L.Count to Length(FData[Indx]) - 1 do
        L.Add(FData[Indx][i]);
      FData[Indx] := L.ToArray;
    finally
      L.Free;
    end;
    DoChanged;
  end;
end;

procedure TData.CleanDataText;
var
  i: Integer;
begin
  for i := FDataText.Count - 1 downto 0 do
    if FDataText[i].Trim.IsEmpty then
      FDataText.Delete(i);
end;

procedure TData.ClearData;
begin
  FData.Clear;
end;

procedure TData.ClearError;
begin
  FError    := '';
  FErrorPos := TPoint.Create(-1, -1);
  DoError;
end;

procedure TData.ConserveData(r: FlatArray; DataType: TDataTypes);
begin
  FData.Add(r);
end;

function TData.ContainsType(dt: TDataTypes; DataType: TDataType): Boolean;
var
  iDataType: TDataType;
begin
  for iDataType in dt do
    if iDataType = DataType then
      Exit(True);
  Result := False;
end;

function TData.GetData(Indx: Integer): TArray<Single>;
begin
  Result := FData[Indx];
end;

function TData.GetDataCount: Integer;
begin
  Result := FData.Count;
end;

function TData.GetDataStr(Indx: Integer): TArray<string>;
var
  i: Integer;
  s: TArray<string>;
begin
  s := FDataText[Indx].Split([FSeparator], None);
  SetLength(Result, Length(s));
  for i       := 0 to Length(s) - 1 do
    Result[i] := s[i].Trim;
end;

function TData.GetIsValid: Boolean;
begin
  Result := (FErrorPos.X = -1) and FError.IsEmpty;
end;

function TData.GetItemCount(Indx: Integer): Integer;
var
  s: TArray<string>;
begin
  s      := GetDataStr(Indx);
  Result := Length(s);
  if Length(DataTypeOfStr(s[0])) > 0 then
    Result := Result - 1;
end;

function TData.GetItemCount: Integer;
begin
  Result := GetItemCount(0);
end;

function TData.IsItemCountValid: Boolean;
var
  Y, c: Integer;
begin
  ClearError;
  c := GetItemCount;
  if c <> FInputCount + FOutputCount then
  begin
    FErrorPos := TPoint.Create(0, 0);
    FError    := 'Itemcount <> InputCount + OutputCount -> ' + c.ToString + ' <> ' + FInputCount.ToString + ' + ' +
      FOutputCount.ToString;
    DoError;
    Exit(False);
  end;
  for Y := 0 to FDataText.Count - 1 do
    if c <> GetItemCount(Y) then
    begin
      FErrorPos := TPoint.Create(0, Y);
      FError    := 'Invalid Itemcount - Line: ' + Y.ToString;
      DoError;
      Exit(False);
    end;
  Result := True;
end;

function TData.IsParseError(DataText: string; Pos: TPoint): Boolean;
begin
  FError    := 'Invalid String "' + DataText + '" - Line: ' + Pos.Y.ToString + ' Pos: ' + Pos.X.ToString;
  FErrorPos := Pos;
  Result    := True;
end;

procedure TData.LoadDataFromFile(Filename: string);
begin
  FDataText.Clear;
  FDataText.LoadFromFile(Filename);
  MakeData;
end;

procedure TData.LoadDataFromFile(Filename: string; Encoding: TEncoding);
begin
  FDataText.Clear;
  FDataText.LoadFromFile(Filename, Encoding);
  MakeData;
end;

procedure TData.LoadDataFromArray(T: TArray<string>);
begin
  FDataText.Clear;
  FDataText.AddStrings(T);
  MakeData;
end;

procedure TData.MakeData;
var
  Format: TFormatSettings;
begin
  CleanDataText;
  if (FDataText.Count > 0) or not FDataText.Text.Trim.IsEmpty then
  begin
    Format                  := TFormatSettings.Create;
    Format.DecimalSeparator := FDecimalSeparator;
    TextToFloat(Format, ConserveData);

    if GetIsValid then
      IsItemCountValid;
    DoChanged;
  end
  else
  begin
    FError    := 'Datatext is empty!';
    FErrorPos := TPoint.Create(0, 0);
    DoError;
  end;
end;

procedure TData.SaveToCSVFile(Filename: string; Encoding: TEncoding);
var
  sl: TStringList;
  sb: TStringBuilder;
  iLine: FlatArray;
  iData: Single;
begin
  sl := TStringList.Create;
  sb := TStringBuilder.Create;
  try
    for iLine in FData do
    begin
      sb.Clear;
      for iData in iLine do
        sb.Append(iData).Append(FSeparator);
      sb.Remove(sb.Length - 1, 1);
      sl.Add(sb.ToString);
    end;
    sl.SaveToFile(Filename, Encoding);
  finally
    sb.Free;
    sl.Free;
  end;
end;

procedure TData.SetDecimalSeparator(const Value: Char);
begin
  if (FDecimalSeparator <> Value) and (Value <> '') then
  begin
    FDecimalSeparator := Value;
    MakeData;
  end;
end;

procedure TData.SetInputCount(const Value: Integer);
begin
  if FInputCount <> Value then
  begin
    FInputCount := Value;
    MakeData;
  end;
end;

procedure TData.SetOutputCount(const Value: Integer);
begin
  if FOutputCount <> Value then
  begin
    FOutputCount := Value;
    MakeData;
  end;
end;

procedure TData.SetSeparator(const Value: string);
begin
  if not SameStr(FSeparator, Value) then
  begin
    if Value.IsEmpty then
      FSeparator := ' '
    else
      FSeparator := Value;
    MakeData;
  end;
end;

function TData.SliceOfData(Indx, Start, Count: Integer): TArray<Single>;
begin
  Result := SliceOf(FData[Indx], Start, Count);
end;

function TData.DataTypeOfStr(s: string): TDataTypes;
var
  L: TList<TDataType>;
begin
  s := s.Trim;
  L := TList<TDataType>.Create;
  try
    if s.Contains('*') then
      L.Add(dtValid);
    if s.Contains('?') then
      L.Add(dtTest);
    if s.Contains('#') then
      L.Add(dtTrain);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TData.LineTextToFloat(Indx: Integer; Format: TFormatSettings; var Res: FlatArray; var DataType: TDataTypes): Boolean;
var
  s: TArray<string>;
  X: Integer;
  F: Single;
  Start: Integer;
begin
  s := GetDataStr(Indx);
  if Length(s) > 1 then
    DataType := DataTypeOfStr(s[0]);

  if Length(DataType) = 0 then
    Start := 0
  else
    Start := 1;

  SetLength(Res, Length(s) - Start);
  for X := Start to Length(s) - 1 do
  begin
    if TryStrToFloat(s[X], F, Format) then
      Res[X - Start] := F
    else if IsParseError(s[X], TPoint.Create(X, Indx)) then
    // if (X > 0) and not(s[X].Contains('#') or s[X].Contains('*') or s[X].Contains('?')) then
    begin
      DoError;
      Exit(False);
    end;
  end;
  Result := True;
end;

function TData.TextToFloat(Format: TFormatSettings; P: TProc<FlatArray, TDataTypes>): Boolean;
var
  Y: Integer;
  r: FlatArray;
  DataType: TDataTypes;
begin
  ClearError;
  ClearData;
  for Y := 0 to FDataText.Count - 1 do
  begin
    if LineTextToFloat(Y, Format, r, DataType) then
      P(r, DataType)
    else
      Exit(False);
  end;
  Result := True;
end;

{ TTrainData }

constructor TTrainData.Create;
begin
  inherited;
  FTrainData := TList<FlatArray>.Create;
  FValidData := TList<FlatArray>.Create;
  FTestData  := TList<FlatArray>.Create;
end;

destructor TTrainData.Destroy;
begin
  FTestData.Free;
  FValidData.Free;
  FTrainData.Free;
  inherited;
end;

procedure TTrainData.ClearData;
begin
  inherited;
  FTrainData.Clear;
  FValidData.Clear;
  FTestData.Clear;
end;

procedure TTrainData.ConserveData(r: FlatArray; DataType: TDataTypes);
begin
  inherited;
  if ContainsType(DataType, dtTrain) or (Length(DataType) = 0) then
    FTrainData.Add(r);
  if ContainsType(DataType, dtValid) then
    FValidData.Add(r);
  if ContainsType(DataType, dtTest) then
    FTestData.Add(r);
end;

function TTrainData.GetInTestData(Indx: Integer): TArray<Single>;
begin
  if FTestData.Count > 0 then
    Result := SliceOf(FTestData[Indx], 0, FInputCount)
  else
    Result := GetInTrainData(Indx);
end;

function TTrainData.GetOutTestData(Indx: Integer): TArray<Single>;
begin
  if FTestData.Count > 0 then
    Result := SliceOf(FTestData[Indx], FInputCount, FOutputCount)
  else
    Result := GetOutTrainData(Indx);
end;

function TTrainData.GetInTrainData(Indx: Integer): TArray<Single>;
begin
  Result := SliceOf(FTrainData[Indx], 0, FInputCount);
end;

function TTrainData.GetOutTrainData(Indx: Integer): TArray<Single>;
begin
  Result := SliceOf(FTrainData[Indx], FInputCount, FOutputCount);
end;

function TTrainData.GetInValidData(Indx: Integer): TArray<Single>;
begin
  if FValidData.Count > 0 then
    Result := SliceOf(FValidData[Indx], 0, FInputCount)
  else
    Result := GetInTrainData(Indx);
end;

function TTrainData.GetOutValidData(Indx: Integer): TArray<Single>;
begin
  if FValidData.Count > 0 then
    Result := SliceOf(FValidData[Indx], FInputCount, FOutputCount)
  else
    Result := GetOutTrainData(Indx);
end;

function TTrainData.GetTrainDataCount: Integer;
begin
  Result := FTrainData.Count
end;

function TTrainData.GetValidDataCount: Integer;
begin
  if FValidData.Count > 0 then
    Result := FValidData.Count
  else
    Result := GetTrainDataCount;
end;

function TTrainData.IsParseError(DataText: string; Pos: TPoint): Boolean;
begin
  inherited;
  Result := (Pos.X > 0) and not(DataText.Contains('#') or DataText.Contains('*') or DataText.Contains('?'));
end;

function TTrainData.GetTestDataCount: Integer;
begin
  if FTestData.Count > 0 then
    Result := FTestData.Count
  else
    Result := GetTrainDataCount;
end;

end.
