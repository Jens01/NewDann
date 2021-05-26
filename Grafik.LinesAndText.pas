// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unit Grafik.LinesAndText;

interface

uses
  GR32, GR32_Polygons, GR32_ArrowHeads, Vcl.Graphics, System.SysUtils, Winapi.Windows, System.Generics.Collections;

type
  TGrafik = class
  strict private
  strict protected
    FBitmap: TBitmap32;
    procedure _DrawLine(pts: TArrayOfFloatPoint; Color: TColor32; Filler: TCustomPolygonFiller); overload;
    procedure _DrawLine(pts: TArrayOfFloatPoint; Color: TColor32; EndStyle: TEndStyle = esButt); overload;
    procedure _DrawLine(pts: TArrayOfArrayOfFloatPoint; Color: TColor32; EndStyle: TEndStyle = esButt); overload;
    procedure _Rotate(pts: TArrayOfFloatPoint; OriginX, OriginY, DegAngle: single); overload;
    procedure _Rotate(pts: TArrayOfArrayOfFloatPoint; OriginX, OriginY, DegAngle: single); overload;
    procedure _Translate(var pts: TArrayOfFloatPoint; X, Y: single); overload;
    procedure _Translate(var pts: TArrayOfArrayOfFloatPoint; X, Y: single); overload;
  public
    constructor Create(ABitmap: TBitmap32);
  end;

  THatchedStyle = (hsClear, hsCustom, hsSolid, hsCrossLeft, hsCrossRight, hsCross, hsPoint);

  THatchedPattern = class(TCustomSampler)
  private
    FFillColor: TColor32;
    FHatchingColor: TColor32;
    FHatchedStyle: THatchedStyle;
    FDistance: Single;
    FHatchedFunc: TFunc<Single, Single, Boolean>;
  public
    function GetSampleFloat(X, Y: TFloat): TColor32; override;
    property FillColor: TColor32 read FFillColor write FFillColor;
    property HatchingColor: TColor32 read FHatchingColor write FHatchingColor;
    property HatchedStyle: THatchedStyle read FHatchedStyle write FHatchedStyle;
    property Distance: Single read FDistance write FDistance;
    property HatchedFunc: TFunc<Single, Single, Boolean> read FHatchedFunc write FHatchedFunc;
  end;

  TAreaFiller = class(TCustomPolygonFiller)
  private
    FSampler: THatchedPattern;
    procedure Filler(Dst: PColor32; DstX, DstY, Length: Integer; AlphaValues: PColor32);
  protected
    function GetFillLine: TFillLineEvent; override;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure BeginRendering; override;
    procedure EndRendering; override;
    property Sampler: THatchedPattern read FSampler;
  end;

  TLine = class(TGrafik)
  private
    FPoints: TArrayOfFloatPoint;
    procedure _DrawLine(Width: Single; Color: TColor32; BeginArrowSize: single; EndArrowSize: single); overload;
  public
    procedure AddPoints(X, Y: single); overload;
    procedure AddPoints(APoint: TFloatPoint); overload;
    // procedure AddPoints(APoints: TArrayOfFloatPoint); overload;
    procedure AddPoints(APoints: TArray<TFloatPoint>); overload;
    procedure AddTriangle(X1, Y1, X2, Y2, X3, Y3: single);
    procedure AddRect(X1, Y1, X2, Y2: single); overload;
    procedure AddRect(R: TFloatRect); overload;
    procedure AddRect(R: TRect); overload;
    procedure AddCircle(X, Y, R: single);
    procedure AddArc(X, Y, R, StartAngle, SweepAngle: single);
    procedure Clear;
    procedure DrawLine(Width: Single; Color: TColor32; EndStyle: TEndStyle = esButt); overload;
    procedure DrawLine(Width: Single; Color: TColor32; dashes: TArrayOfFloat; EndStyle: TEndStyle = esButt); overload;
    procedure DrawLine(Width: Single; Color: TColor32; BeginArrowSize, EndArrowSize: single); overload;
    procedure DrawLine(Width: Single; Color: TColor32; dashes: TArrayOfFloat; BeginArrowSize: single;
      EndArrowSize: single); overload;
    procedure DrawBeginArrow(Size: single; Color: TColor32);
    procedure DrawEndArrow(Size: single; Color: TColor32);
    procedure DrawArea(Width: Single; LineColor, FillColor: TColor32; dashes: TArrayOfFloat = []);
    procedure DrawAreaHatched(Width, HatchingDistance: Single; Style: THatchedStyle;
      LineColor, HatchingColor, FillColor: TColor32; dashes: TArrayOfFloat = []); overload;
    procedure DrawAreaHatched(Width: Single; Hatching: TFunc<Single, Single, Boolean>;
      LineColor, HatchingColor, FillColor: TColor32; dashes: TArrayOfFloat = []); overload;
    procedure Rotate(OriginX, OriginY, DegAngle: single);
    procedure Translate(X, Y: single);
  end;

const
  cCommands: array of string = ['B', '/B', 'I', '/I', 'U', '/U', 'S', '/S', 'FONT', '/FONT', 'BR', 'TAB', 'SUB', '/SUB',
    'SUP', '/SUP'];

type
  { TTextParser }
  TAttr = TPair<string, string>;
  TParserNotify = reference to procedure(Sender: TObject; Text: string; var X, Y: single);
  TCommandNotify = reference to procedure(Sender: TObject; Text: string; AAttribute: TArray<TAttr>; var X, Y: single);

  TTextParser = class(TObject)
  strict private
    FAttribute: TArray<TAttr>;
    FOnDrawText: TParserNotify;
    FOnCommand: TCommandNotify;
    procedure ParseCommand(var ACommand: string; var AAttribute: TArray<TAttr>);
    procedure DoDrawText(Text: string; var X, Y: Single);
    procedure ParseText(AText: string; DoText: TProc<string, Single, Single>);
  public
    procedure Parse(AText: string);
    property OnDrawText: TParserNotify read FOnDrawText write FOnDrawText;
    property OnCommand: TCommandNotify read FOnCommand write FOnCommand;
  end;

  TText = class(TGrafik)
  private
    FParser: TTextParser;
    FFont: TFont;
    FRestFont: TFont;
    FTextMetric: TTextMetric;
    FPointsArray: TArrayOfArrayOfFloatPoint;
    FText: string;
    FPlainText: string;
    FUpdateCount: Integer;
    procedure SetText(const Value: string);
    function GetCharSet: TFontCharset;
    function GetFontName: TFontName;
    function GetHeight: Integer;
    function GetSize: Integer;
    function GetStyle: TFontStyles;
    procedure SetCharSet(const Value: TFontCharset);
    procedure SetFontName(const Value: TFontName);
    procedure SetHeight(const Value: Integer);
    procedure SetSize(const Value: Integer);
    procedure SetStyle(const Value: TFontStyles);
    procedure MakePolygon;
    procedure SetMetric;
    function TextWidth(pts: TArrayOfArrayOfFloatPoint): single; overload;
    procedure SetTab(Attr: TArray<TAttr>; var X: single);
    procedure ReResetFont;
    procedure SetFont(Attr: TArray<TAttr>);
    procedure GetText(Sender: TObject; Text: string; var X, Y: single);
    procedure GetCommand(Sender: TObject; ACommand: string; Attr: TArray<TAttr>; var X, Y: single);
  public
    constructor Create(ABitmap: TBitmap32);
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure DrawText(X, Y: single; Color: TColor32 = clBlack32; DegAngle: single = 0);
    function TextBaseline: Integer;
    function TextWidth: single; overload;
    function TextHeight: Integer;
    property Text: string read FText write SetText;
    property FontName: TFontName read GetFontName write SetFontName;
    property Height: Integer read GetHeight write SetHeight;
    property Size: Integer read GetSize write SetSize;
    property CharSet: TFontCharset read GetCharSet write SetCharSet;
    property Style: TFontStyles read GetStyle write SetStyle;
    property TextMetric: TTextMetric read FTextMetric;
  end;

implementation

uses
  GR32_VectorUtils, GR32_Geometry, GR32_Text_VCL, GR32_Blend, System.Math, System.StrUtils;

{ TGrafik_Text_Line }

procedure TLine.DrawLine(Width: Single; Color: TColor32; EndStyle: TEndStyle = esButt);
var
  pts: TArrayOfFloatPoint;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 1) and (Color <> $0) then
  begin
    pts := BuildPolyline(FPoints, Width, jsMiter, EndStyle);
    _DrawLine(pts, Color, EndStyle);
  end;
end;

procedure TLine.DrawArea(Width: Single; LineColor, FillColor: TColor32; dashes: TArrayOfFloat = []);
begin
  if Assigned(FBitmap) and (Length(FPoints) > 2) then
  begin
    _DrawLine(FPoints, FillColor);
    DrawLine(Width, LineColor, dashes, esSquare)
  end;
end;

procedure TLine.DrawAreaHatched(Width: Single; Hatching: TFunc<Single, Single, Boolean>;
  LineColor, HatchingColor, FillColor: TColor32; dashes: TArrayOfFloat);
var
  Filler: TAreaFiller;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 2) then
  begin
    Filler := TAreaFiller.Create;
    try
      Filler.Sampler.FillColor     := FillColor;
      Filler.Sampler.HatchingColor := HatchingColor;
      Filler.Sampler.HatchedStyle  := hsCustom;
      Filler.Sampler.HatchedFunc   := Hatching;
      _DrawLine(FPoints, FillColor, Filler);
    finally
      Filler.Free;
    end;
    DrawLine(Width, LineColor, dashes, esSquare)
  end;
end;

procedure TLine.DrawAreaHatched(Width, HatchingDistance: Single; Style: THatchedStyle;
  LineColor, HatchingColor, FillColor: TColor32; dashes: TArrayOfFloat);
var
  Filler: TAreaFiller;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 2) then
  begin
    Filler := TAreaFiller.Create;
    try
      Filler.Sampler.FillColor     := FillColor;
      Filler.Sampler.HatchingColor := HatchingColor;
      Filler.Sampler.HatchedStyle  := Style;
      Filler.Sampler.Distance      := HatchingDistance;
      _DrawLine(FPoints, FillColor, Filler);
    finally
      Filler.Free;
    end;
    DrawLine(Width, LineColor, dashes, esSquare)
  end;
end;

procedure TLine.DrawBeginArrow(Size: single; Color: TColor32);
var
  A: TArrowHeadFourPt;
  pts: TArrayOfFloatPoint;
  P: TPolygonRenderer32VPR;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 1) then
  begin
    A := TArrowHeadFourPt.Create(Abs(Size));
    try
      pts := A.GetPoints(FPoints, False);
    finally
      A.free;
    end;
    _DrawLine(pts, Color);
  end;
end;

procedure TLine.DrawEndArrow(Size: single; Color: TColor32);
var
  A: TArrowHeadFourPt;
  pts: TArrayOfFloatPoint;
  P: TPolygonRenderer32VPR;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 1) then
  begin
    A := TArrowHeadFourPt.Create(Abs(Size));
    try
      pts := A.GetPoints(FPoints, True);
    finally
      A.free;
    end;
    _DrawLine(pts, Color);
  end;
end;

procedure TLine.DrawLine(Width: Single; Color: TColor32; BeginArrowSize, EndArrowSize: single);
begin
  if (Length(FPoints) > 1) then
  begin
    _DrawLine(Width, Color, BeginArrowSize, EndArrowSize);
    DrawLine(Width, Color);
  end;
end;

procedure TLine.DrawLine(Width: Single; Color: TColor32; dashes: TArrayOfFloat; BeginArrowSize, EndArrowSize: single);
begin
  if (Length(FPoints) > 1) then
  begin
    _DrawLine(Width, Color, BeginArrowSize, EndArrowSize);
    DrawLine(Width, Color, dashes);
  end;
end;

procedure TLine._DrawLine(Width: Single; Color: TColor32; BeginArrowSize, EndArrowSize: single);
var
  UnitVec: TFloatPoint;
  len: Integer;
begin
  if not IsZero(BeginArrowSize) then
  begin
    UnitVec    := GetUnitVector(FPoints[0], FPoints[1]);
    FPoints[0] := OffsetPoint(FPoints[0], UnitVec.X * BeginArrowSize, UnitVec.Y * BeginArrowSize);
    DrawBeginArrow(BeginArrowSize, Color);
  end;
  if not IsZero(EndArrowSize) then
  begin
    len              := Length(FPoints);
    UnitVec          := GetUnitVector(FPoints[len - 1], FPoints[len - 2]);
    FPoints[len - 1] := OffsetPoint(FPoints[len - 1], UnitVec.X * EndArrowSize, UnitVec.Y * EndArrowSize);
    DrawEndArrow(EndArrowSize, Color)
  end;
end;

procedure TLine.DrawLine(Width: Single; Color: TColor32; dashes: TArrayOfFloat; EndStyle: TEndStyle = esButt);
var
  pts: TArrayOfArrayOfFloatPoint;
  P: TPolygonRenderer32VPR;
begin
  if Assigned(FBitmap) and (Length(FPoints) > 1) and (Color <> $0) then
  begin
    if Length(dashes) > 0 then
    begin
      pts := BuildDashedLine(FPoints, dashes);
      pts := BuildPolyPolyLine(pts, False, Width, jsMiter, EndStyle);
      _DrawLine(pts, Color);
    end
    else
      DrawLine(Width, Color, EndStyle);
  end;
end;

procedure TLine.AddPoints(APoint: TFloatPoint);
begin
  FPoints := FPoints + [APoint];
end;

procedure TLine.AddArc(X, Y, R, StartAngle, SweepAngle: single);
begin
  Clear;
  FPoints := Circle(X, Y, R, 360);
  SetLength(FPoints, Round(SweepAngle));
  _Rotate(FPoints, X, Y, -StartAngle + 90);
end;

procedure TLine.AddCircle(X, Y, R: single);
begin
  Clear;
  FPoints := Circle(X, Y, R);
  AddPoints(FPoints[0]);
end;
{
  procedure TLine.AddPoints(APoints: TArrayOfFloatPoint);
  var
  P: TFloatPoint;
  begin
  Clear;
  for P in APoints do
  AddPoints(P);
  end; }

procedure TLine.AddPoints(APoints: TArray<TFloatPoint>);
var
  P: TFloatPoint;
begin
  Clear;
  for P in APoints do
    AddPoints(P);
end;

procedure TLine.AddPoints(X, Y: single);
begin
  AddPoints(FloatPoint(X, Y));
end;

procedure TLine.AddRect(R: TFloatRect);
begin
  Clear;
  FPoints := Rectangle(R);
  FPoints := ClosePolygon(FPoints);
end;

procedure TLine.AddRect(X1, Y1, X2, Y2: single);
begin
  AddRect(FloatRect(X1, Y1, X2, Y2));
end;

procedure TLine.AddRect(R: TRect);
begin
  AddRect(FloatRect(R));
end;

procedure TLine.AddTriangle(X1, Y1, X2, Y2, X3, Y3: single);
begin
  AddPoints(X1, Y1);
  AddPoints(X2, Y2);
  AddPoints(X3, Y3);
  AddPoints(X1, Y1);
end;

{ TGrafik }

constructor TGrafik.Create(ABitmap: TBitmap32);
begin
  inherited Create;
  FBitmap := ABitmap;
end;

procedure TGrafik._Rotate(pts: TArrayOfFloatPoint; OriginX, OriginY, DegAngle: single);
var
  s: single;
  c: single;
  i: Integer;
  tmp: TFloatPoint;
begin
  if not SameValue(DegAngle, 0) then
  begin
    SinCos(DegToRad(DegAngle), s, c);
    for i := Low(pts) to High(pts) do
    begin
      tmp.X    := pts[i].X - OriginX;
      tmp.Y    := pts[i].Y - OriginY;
      pts[i].X := tmp.X * c + (tmp.Y * s) + OriginX;
      pts[i].Y := tmp.Y * c - (tmp.X * s) + OriginY;
    end;
  end;
end;

procedure TGrafik._Rotate(pts: TArrayOfArrayOfFloatPoint; OriginX, OriginY, DegAngle: single);
var
  i: Integer;
begin
  for i := Low(pts) to High(pts) do
    _Rotate(pts[i], OriginX, OriginY, DegAngle);
end;

procedure TGrafik._Translate(var pts: TArrayOfFloatPoint; X, Y: single);
begin
  pts := TranslatePolygon(pts, X, Y);
end;

procedure TGrafik._Translate(var pts: TArrayOfArrayOfFloatPoint; X, Y: single);
var
  i: Integer;
begin
  for i := Low(pts) to High(pts) do
    _Translate(pts[i], X, Y);
end;

{ TTextParser }

procedure TTextParser.DoDrawText(Text: string; var X, Y: Single);
begin
  if Length(Text) > 0 then
    FOnDrawText(Self, Text, X, Y);
end;

procedure TTextParser.Parse(AText: string);
var
  DrawText: string;
  Command: string;
  IsCommand: boolean;
  Attr: TArray<TAttr>;
  i: Integer;
  X, Y: single;
begin
  if Length(AText) > 0 then
  begin
    Command   := '';
    IsCommand := False;
    DrawText  := '';
    i         := 1;
    X         := 0;
    Y         := 0;
    while Length(AText) >= i do
    begin
      if SameText(AText[i], '<') and not IsCommand then
      begin
        IsCommand := True;
        Command   := '';
        DoDrawText(DrawText, X, Y);
        DrawText := '';
      end

      else if SameText(AText[i], '>') and IsCommand then
      begin
        IsCommand := False;
        ParseCommand(Command, Attr);
        FOnCommand(Self, Command, Attr, X, Y);
      end

      else if IsCommand then
        Command := Command + AText[i]

      else
      begin
        DrawText := DrawText + AText[i];
      end;

      Inc(i);
    end;
    DoDrawText(DrawText, X, Y);
  end;
end;

procedure TTextParser.ParseCommand(var ACommand: string; var AAttribute: TArray<TAttr>);
var
  c: string;
  Texte: TArray<string>;
  s: TArray<string>;
  i: Integer;
  L: TList<TAttr>;
begin
  c := Trim(ACommand);
  SetLength(AAttribute, 0);
  c     := StringReplace(c, '  ', ' ', [rfReplaceAll]);
  c     := StringReplace(c, ' =', '=', [rfReplaceAll]);
  c     := StringReplace(c, '= ', '=', [rfReplaceAll]);
  Texte := TArray<string>(SplitString(c, ' '));
  c     := Trim(Texte[0]);
  if c[1] <> '/' then
  begin
    L := TList<TAttr>.Create;
    try
      for i := 1 to Length(Texte) - 1 do
      begin
        s := TArray<string>(SplitString(Texte[i], '='));
        L.Add(TAttr.Create(Trim(s[0]), Trim(s[1])));
      end;
      AAttribute := L.ToArray;
    finally
      L.free;
    end;
  end;
  ACommand := c;
end;

procedure TTextParser.ParseText(AText: string; DoText: TProc<string, Single, Single>);
begin

end;

{ TText }

procedure TText.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

constructor TText.Create(ABitmap: TBitmap32);
begin
  inherited;
  FParser            := TTextParser.Create;
  FParser.OnDrawText := GetText;
  FParser.OnCommand  := GetCommand;

  FFont         := TFont.Create;
  FFont.Name    := 'Arial';
  FFont.Height  := 18;
  FFont.Style   := [];
  FFont.CharSet := 0;
  FRestFont     := TFont.Create;
  FRestFont.Assign(FFont);
  SetMetric;
end;

destructor TText.Destroy;
begin
  FRestFont.free;
  FFont.free;
  FParser.free;
  inherited;
end;

procedure TText.DrawText(X, Y: single; Color: TColor32 = clBlack32; DegAngle: single = 0);
begin
  _Translate(FPointsArray, X, Y - TextBaseline);
  _Rotate(FPointsArray, X, Y, DegAngle);
  _DrawLine(FPointsArray, Color);
  FText := '';
end;

procedure TText.EndUpdate;
begin
  Dec(FUpdateCount);
  MakePolygon;
end;

function TText.GetCharSet: TFontCharset;
begin
  Result := FFont.CharSet;
end;

function TText.GetFontName: TFontName;
begin
  Result := FFont.Name;
end;

function TText.GetHeight: Integer;
begin
  Result := FFont.Height;
end;

function TText.GetSize: Integer;
begin
  Result := FFont.Size;
end;

function TText.GetStyle: TFontStyles;
begin
  Result := FFont.Style;
end;

procedure TText.SetTab(Attr: TArray<TAttr>; var X: single);
begin
  if (Length(Attr) > 0) and SameText(Attr[0].Key, 'Pos') then
    X := X + Attr[0].Value.ToSingle;
end;

procedure TText.ReResetFont;
begin
  FFont.Assign(FRestFont);
end;

procedure TText.SetFont(Attr: TArray<TAttr>);
var
  iP: TAttr;
begin
  for iP in Attr do
    case IndexText(iP.Key, ['COLOR', 'Size']) of
      0:
        FFont.Color := StringToColor(iP.Value.DeQuotedString);
      1:
        FFont.Size := iP.Value.DeQuotedString.ToInteger;
    end;
end;

procedure TText.GetText(Sender: TObject; Text: string; var X, Y: single);
var
  pts: TArrayOfArrayOfFloatPoint;
begin
  pts          := TextToPolyPolygon(FFont.Handle, FloatRect(X, Y, MaxSingle, MaxSingle), Text);
  FPointsArray := FPointsArray + pts;
  X            := X + TextWidth(pts);
  FPlainText   := FPlainText + Text;
end;

procedure TText.GetCommand(Sender: TObject; ACommand: string; Attr: TArray<TAttr>; var X, Y: single);
begin
  case IndexText(ACommand, cCommands) of
    0:
      FFont.Style := FFont.Style + [fsBold];
    1:
      FFont.Style := FFont.Style - [fsBold];
    2:
      FFont.Style := FFont.Style + [fsItalic];
    3:
      FFont.Style := FFont.Style - [fsItalic];
    4:
      FFont.Style := FFont.Style + [fsUnderline];
    5:
      FFont.Style := FFont.Style - [fsUnderline];
    6:
      FFont.Style := FFont.Style + [fsStrikeOut];
    7:
      FFont.Style := FFont.Style - [fsStrikeOut];
    8:
      SetFont(Attr);
    9:
      ReResetFont;
    10:
      begin
        X := 0;
        Y := Y + TextHeight;
      end;
    11:
      SetTab(Attr, X);
    12:
      Y := Y + TextHeight div 3;
    13:
      Y := Y - TextHeight div 3;
    14:
      Y := Y - TextHeight div 3;
    15:
      Y := Y + TextHeight div 3;
  end;
end;

function TText.TextHeight: Integer;
begin
  Result := FTextMetric.tmAscent + FTextMetric.tmDescent;
end;

function TText.TextWidth(pts: TArrayOfArrayOfFloatPoint): single;
var
  i: Integer;
  ii: Integer;
begin
  Result     := 0;
  for i      := Low(pts) to High(pts) do
    for ii   := Low(pts[i]) to High(pts[i]) do
      Result := Max(Result, pts[i][ii].X);
end;

function TText.TextBaseline: Integer;
begin
  Result := FTextMetric.tmAscent;
end;

procedure TText.MakePolygon;
begin
  if (FUpdateCount = 0) then
  begin
    FPointsArray := nil;
    if (Length(FText) > 0) then
      FParser.Parse(FText)
  end;
end;

procedure TText.SetCharSet(const Value: TFontCharset);
begin
  if FFont.CharSet <> Value then
  begin
    FFont.CharSet := Value;
    SetMetric;
    MakePolygon;
  end;
end;

procedure TText.SetFontName(const Value: TFontName);
begin
  if not SameText(FFont.Name, Value) then
  begin
    FFont.Name     := Value;
    FRestFont.Name := Value;
    SetMetric;
    MakePolygon;
  end;
end;

procedure TText.SetHeight(const Value: Integer);
begin
  if FFont.Height <> Value then
  begin
    FFont.Height     := Value;
    FRestFont.Height := Value;
    SetMetric;
    MakePolygon;
  end;
end;

procedure TText.SetMetric;
var
  dc: hdc;
begin
  dc := GetDC(0);
  SelectObject(dc, FFont.Handle);
  try
    GetTextMetrics(dc, FTextMetric);
  finally
    ReleaseDC(0, dc);
  end;
end;

procedure TText.SetSize(const Value: Integer);
begin
  if FFont.Size <> Value then
  begin
    FFont.Size     := Value;
    FRestFont.Size := Value;
    SetMetric;
    MakePolygon;
  end;
end;

procedure TText.SetStyle(const Value: TFontStyles);
begin
  if FFont.Style <> Value then
  begin
    FFont.Style     := Value;
    FRestFont.Style := Value;
    SetMetric;
    MakePolygon;
  end;
end;

procedure TText.SetText(const Value: string);
begin
  if not SameStr(Value, FText) then
  begin
    FText      := Value;
    FPlainText := '';
    MakePolygon;
  end;
end;

function TText.TextWidth: single;
var
  pts: TArrayOfArrayOfFloatPoint;
begin
  pts    := TextToPolyPolygon(FFont.Handle, FloatRect(0, 0, MaxSingle, MaxSingle), FPlainText);
  Result := TextWidth(pts);
end;

procedure TGrafik._DrawLine(pts: TArrayOfFloatPoint; Color: TColor32; Filler: TCustomPolygonFiller);
var
  P: TPolygonRenderer32VPR;
begin
  P := TPolygonRenderer32VPR.Create(FBitmap);
  try
    P.Color  := Color;
    P.Filler := Filler;
    P.PolygonFS(pts);
  finally
    P.free;
  end;
end;

procedure TGrafik._DrawLine(pts: TArrayOfFloatPoint; Color: TColor32; EndStyle: TEndStyle = esButt);
var
  P: TPolygonRenderer32VPR;
begin
  P := TPolygonRenderer32VPR.Create(FBitmap);
  try
    P.Color := Color;
    P.PolygonFS(pts);
  finally
    P.free;
  end;
end;

procedure TGrafik._DrawLine(pts: TArrayOfArrayOfFloatPoint; Color: TColor32; EndStyle: TEndStyle = esButt);
var
  P: TPolygonRenderer32VPR;
begin
  P := TPolygonRenderer32VPR.Create(FBitmap);
  try
    P.Color := Color;
    P.PolyPolygonFS(pts);
  finally
    P.free;
  end;
end;

procedure TLine.Rotate(OriginX, OriginY, DegAngle: single);
begin
  _Rotate(FPoints, OriginX, OriginY, DegAngle);
end;

procedure TLine.Translate(X, Y: single);
begin
  _Translate(FPoints, X, Y);
end;

procedure TLine.Clear;
begin
  FPoints := nil;
end;

{ THatchedPatternSampler }

function THatchedPattern.GetSampleFloat(X, Y: TFloat): TColor32;
begin
  case FHatchedStyle of
    hsCrossLeft:
      if IsZero(Frac((X - Y) / FDistance)) then
        Result := FHatchingColor
      else
        Result := FFillColor;
    hsCrossRight:
      if IsZero(Frac((X + Y) / FDistance)) then
        Result := FHatchingColor
      else
        Result := FFillColor;
    hsCross:
      if IsZero(Frac((X - Y) / FDistance)) or IsZero(Frac((X + Y) / FDistance)) then
        Result := FHatchingColor
      else
        Result := FFillColor;
    hsPoint:
      if IsZero(Frac((X - Y) / FDistance)) and IsZero(Frac((X + Y) / FDistance)) then
        Result := FHatchingColor
      else
        Result := FFillColor;
    hsCustom:
      if FHatchedFunc(X, Y) then
        Result := FHatchingColor
      else
        Result := FFillColor;

    hsClear:
      Result := FFillColor;
    hsSolid:
      Result := FHatchingColor;
  end;
end;

{ TAreaFiller }

constructor TAreaFiller.Create;
begin
  inherited;
  FSampler := THatchedPattern.Create;
end;

destructor TAreaFiller.Destroy;
begin
  FSampler.Free;
  inherited;
end;

procedure TAreaFiller.BeginRendering;
begin
  FSampler.PrepareSampling
end;

procedure TAreaFiller.EndRendering;
begin
  FSampler.FinalizeSampling
end;

procedure TAreaFiller.Filler(Dst: PColor32; DstX, DstY, Length: Integer; AlphaValues: PColor32);
// cmBlend, cmMerge
var
  X: Integer;
  C: TColor32;
  BlendMemEx: TBlendMemEx;
begin
  BlendMemEx := BLEND_MEM_EX[cmMerge]^;
  for X      := DstX to DstX + Length - 1 do
  begin
    C := FSampler.GetSampleFloat(X, DstY);
    BlendMemEx(C, Dst^, AlphaValues^);
    Inc(Dst);
    Inc(AlphaValues);
  end;
end;

function TAreaFiller.GetFillLine: TFillLineEvent;
begin
  Result := Filler;
end;

end.
