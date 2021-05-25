// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unit NewDann.Graph;

interface

{$DEFINE GR32!}

uses
  System.Types, System.SysUtils, System.Math, System.Classes, System.Generics.Collections, Vcl.Graphics,
{$IFDEF GR32!}
  GR32, Grafik.LinesAndText,
{$ENDIF}
  NewDann.Network;

type

  TFannGraphPositions = class
  strict private
    FPixelWidth: Integer;
    FPixelHeight: Integer;
    FDrawNeurons: TList<TNeuron>;
    FNeuronsPerLayer: TArray<Integer>;
    function NeuronCount(LayerIndx: Integer): Integer;
    function NeuronCountMax: Integer;
    function LayerCount: Integer;
    function NeuronsPerLayer: TArray<Integer>;
    function PosY(N: TNeuron): Single;
    function PosX(N: TNeuron): Single;
    function NeuronXDistance: Single;
    function NeuronYDistance: Single;
  public
    constructor Create(PixelWidth, PixelHeight: Integer; DrawNeurons: TArray<TNeuron>);
    destructor Destroy; override;
    function NeuronPosition(N: TNeuron): TPointF;
    function NeuronOfPoint(P: TPointF; CircleWidth: Integer; var Neuron: TNeuron): Boolean;
  end;

  TConColorEvent = procedure(Sender: TObject; Con: TConnection; var Color: TColor) of object;
  TNeuronColorEvent = procedure(Sender: TObject; Neuron: TNeuron; var ColorBorder, ColorFill: TColor) of object;

  TDrawNeuronGraph = class
  private const
    CircleWidth = 20;

  strict private
    FCanvas: TCanvas;
{$IFDEF GR32!}
    FBitmap: TBitmap32;
{$ENDIF}
    FWidth, FHeight: Integer;
    FBorderVert: Integer;
    FBorderHori: Integer;
    FIsDrawWeigths: Boolean;
    FIsDrawNeurons: Boolean;
    FIsDrawCons: Boolean;
    FIsDrawValue: Boolean;
    FDigits: Integer;
    FTextHeights: Integer;
    FNeurons: TList<TNeuron>;
    FCons: TList<TConnection>;
    FOnConnectionColor: TConColorEvent;
    FOnNeuronColor: TNeuronColorEvent;
    procedure DoConnectionColor(Con: TConnection; var Color: TColor);
    procedure DoNeuronColor(Neuron: TNeuron; var ColorBorder, ColorFIll: TColor);
    procedure ClearCanvas;
    procedure DrawLine(P1: TPointF; P2: TPointF; C: TColor; LW: Single);
    function Gray(Intensity: Byte; Alpha: Byte = $FF): TColor;
    procedure DrawWeights(GP: TFannGraphPositions);
    procedure DrawCon(GP: TFannGraphPositions; LineWidth: Single);
    procedure DrawNeurons(GP: TFannGraphPositions);
    procedure DrawText(Pos: TPointF; Text: string; C: TColor = clBlack);
    procedure DrawNeuron(Pos: TPointF; N: TNeuron);
    procedure DrawNeuronText(Pos: TPointF; N: TNeuron);
    procedure DrawWeight(Pos: TPointF; Weight: Single);
    function WeightMax: Single;
    function WeightMin: Single;
  public
    constructor Create(Canvas: TCanvas; Width, Height: Integer);
    destructor Destroy; override;
    procedure Clear;
    procedure SetNeurons(Neurons: TArray<TNeuron>);
    procedure SetConnections(Cons: TArray<TConnection>);
    procedure Draw(LineWidth: Single);
{$IFDEF GR32!}
    procedure Repaint;
{$ENDIF}
    procedure SetBorder(const Width, Height: Integer);
    function NeuronOfPoint(P: TPoint; var Neuron: TNeuron): Boolean;
    function NeuronLayerOfPoint(P: TPoint): TArray<TNeuron>;
    function ConOfPoint(P: TPoint; Radius: Single; var Con: TConnection): Boolean;
    property BorderVert: Integer read FBorderVert write FBorderVert;
    property BorderHori: Integer read FBorderHori write FBorderHori;
    property IsDrawWeigths: Boolean read FIsDrawWeigths write FIsDrawWeigths;
    property IsDrawCons: Boolean read FIsDrawCons write FIsDrawCons;
    property IsDrawNeurons: Boolean read FIsDrawNeurons write FIsDrawNeurons;
    property IsDrawValue: Boolean read FIsDrawValue write FIsDrawValue;
    property Digits: Integer read FDigits write FDigits;
    property TextHeights: Integer read FTextHeights write FTextHeights;
    property OnConnectionColor: TConColorEvent read FOnConnectionColor write FOnConnectionColor;
    property OnNeuronColor: TNeuronColorEvent read FOnNeuronColor write FOnNeuronColor;
  end;

  TGraphAction = class
  strict private
    FMarkedNeurons: TArray<TNeuron>;
    FMarkedCons: TArray<TConnection>;
//    FNN: TNeuralNet;
    FGraphPos: TPoint;
    FGraph: TDrawNeuronGraph;
    FOnMark: TNotifyEvent;
    FOnEmptyMark: TNotifyEvent;
    procedure DoMark;
    procedure DoEmptyMark;
  public
    constructor Create(Graph: TDrawNeuronGraph);
    procedure Mark;
    procedure MarkLayerNeurons;
//    property NeuralNetwork: TNeuralNet read FNN write FNN;
    property GraphPos: TPoint read FGraphPos write FGraphPos;
    property MarkedNeurons: TArray<TNeuron> read FMarkedNeurons;
    property MarkedCons: TArray<TConnection> read FMarkedCons;
    property OnMark: TNotifyEvent read FOnMark write FOnMark;
    property OnEmptyMark: TNotifyEvent read FOnEmptyMark write FOnEmptyMark;
  end;

implementation

function Collinear(P1, P2, P3: TPointF): Boolean; inline;
const
  eps = 0.001;
begin
  Result := IsZero(P1.X * (P2.Y - P3.Y) + P2.X * (P3.Y - P1.Y) + P3.X * (P1.Y - P2.Y), eps);
end;

function PointOnLine(const LinePoint1, LinePoint2, Point: TPointF): Boolean;
const
  eps = 0.0001;
var
  L, LL, W: Single;
  A: TPointF;
begin
  Result := Collinear(LinePoint1, LinePoint2, Point);
  if Result then
  begin
    A      := Point - LinePoint1;
    W      := A.Normalize.DotProduct((LinePoint2 - LinePoint1).Normalize);
    L      := A.Length;
    LL     := (LinePoint2 - LinePoint1).Length;
    Result := (CompareValue(L, 0, eps) > -1) and (CompareValue(L, LL, eps) < 1) and
      not((W < 0) and (CompareValue(L, 0, eps) = 1));
  end;
end;

function IntersecCircleLine(LinePoint1, LinePoint2, Circle: TPointF; Radius: Single; var P1, P2: TPointF): Integer;
const
  eps = 0.0001;
var
  D, l, r: Single;
  d1, d2, d3: TPointF;

  function Point1: TPointF;
  var
    x, y, sgn: Single;
  begin
    if d3.Y < 0 then
      sgn := -1
    else
      sgn  := 1;
    x      := (D * d3.Y + sgn * d3.X * Sqrt(r)) / (l * l);
    y      := (-D * d3.X + Abs(d3.Y) * Sqrt(r)) / (l * l);
    Result := TPointF.Create(x, y);
  end;
  function Point2: TPointF;
  var
    x, y, sgn: Single;
  begin
    if d3.Y < 0 then
      sgn := -1
    else
      sgn  := 1;
    x      := (D * d3.Y - sgn * d3.X * Sqrt(r)) / (l * l);
    y      := (-D * d3.X - Abs(d3.Y) * Sqrt(r)) / (l * l);
    Result := TPointF.Create(x, y);
  end;

begin
  /// Result :
  /// 0 : no intersection
  /// 1 : two intersections
  /// 2 : one tangential intersection

  d1 := LinePoint1 - Circle;
  d2 := LinePoint2 - Circle;
  d3 := d2 - d1;
  l  := d3.Length;
  D  := d1.CrossProduct(d2);

  r := Radius * Radius * l * l - D * D;

  if (r > eps) then
  begin
    P1     := Point1 + Circle;
    P2     := Point2 + Circle;
    Result := 1;
  end
  else if (r > -eps) then
  begin
    P1     := Point1 + Circle;
    P2     := TPointF.Create(0, 0);
    Result := 2;
  end
  else
  begin
    P1     := TPointF.Create(0, 0);
    P2     := TPointF.Create(0, 0);
    Result := 0;
  end;

end;

// function IntersecCircleLine2(LinePoint1, LinePoint2, Circle: TPointF; Radius: Single): Boolean; inline;
// var
// D, l, r: Single;
// d1, d2, V: TPointF;
// begin
// d1 := LinePoint1 - Circle;
// d2 := LinePoint2 - Circle;
// V := d2 - d1;
// l := V.X * V.X + V.Y * V.Y;
//
// D      := d1.CrossProduct(d2);
// r      := Radius * Radius * l - D * D;
// Result := r >= 0;
// end;

{ TDrawNeuronGraph }

constructor TDrawNeuronGraph.Create(Canvas: TCanvas; Width, Height: Integer);
begin
  inherited Create;
{$IFDEF GR32!}
  FBitmap := TBitmap32.Create;
{$ENDIF}
  FNeurons := TList<TNeuron>.Create;
  FCons    := TList<TConnection>.Create;
  FCanvas  := Canvas;
  SetBorder(Width, Height);
  FBorderVert    := 20;
  FBorderHori    := 10;
  FIsDrawWeigths := False;
  FIsDrawCons    := True;
  FIsDrawNeurons := True;
  FIsDrawValue   := False;
  FDigits        := 1;
  FTextHeights   := 14;
end;

destructor TDrawNeuronGraph.Destroy;
begin
  FCons.Free;
  FNeurons.Free;
{$IFDEF GR32!}
  FBitmap.Free;
{$ENDIF}
  inherited;
end;

procedure TDrawNeuronGraph.DoConnectionColor(Con: TConnection; var Color: TColor);
begin
  if Assigned(FOnConnectionColor) then
    FOnConnectionColor(Self, Con, Color);
end;

procedure TDrawNeuronGraph.DoNeuronColor(Neuron: TNeuron; var ColorBorder, ColorFIll: TColor);
begin
  if Assigned(FOnNeuronColor) then
    FOnNeuronColor(Self, Neuron, ColorBorder, ColorFIll);
end;

function TDrawNeuronGraph.Gray(Intensity: Byte; Alpha: Byte = $FF): TColor;
begin
  Result := { TColor(255) shl 24 + } TColor(Intensity) shl 16 + TColor(Intensity) shl 8 + TColor(Intensity);
end;

function TDrawNeuronGraph.NeuronLayerOfPoint(P: TPoint): TArray<TNeuron>;
var
  N: TNeuron;
  L: TList<TNeuron>;
  iNeuron: TNeuron;
begin
  SetLength(Result, 0);
  if NeuronOfPoint(P, N) then
  begin
    L := TList<TNeuron>.Create;
    try
      for iNeuron in FNeurons do
        if iNeuron.Pos.Y = N.Pos.Y then
          L.Add(iNeuron);
      Result := L.ToArray;
    finally
      L.Free;
    end;
  end;
end;

function TDrawNeuronGraph.NeuronOfPoint(P: TPoint; var Neuron: TNeuron): Boolean;
var
  N: TNeuron;
  GP: TFannGraphPositions;
begin
  P  := P - TPoint.Create(0, FBorderVert);
  GP := TFannGraphPositions.Create(FWidth - FBorderHori * 2, FHeight - FBorderVert * 2, FNeurons.ToArray);
  try
    Result := GP.NeuronOfPoint(P, CircleWidth, N);
    if Result then
      Neuron := N;
  finally
    GP.Free;
  end;
end;

procedure TDrawNeuronGraph.DrawNeurons(GP: TFannGraphPositions);
var
  iNeuron: TNeuron;
  P: TPointF;
begin
  for iNeuron in FNeurons do
  begin
    P := GP.NeuronPosition(iNeuron) + TPointF.Create(0, FBorderVert);
    DrawNeuron(P, iNeuron);
    DrawNeuronText(P, iNeuron);
  end;
end;

procedure TDrawNeuronGraph.SetBorder(const Width, Height: Integer);
begin
  FWidth  := Width;
  FHeight := Height;
{$IFDEF GR32!}
  FBitmap.SetSize(FWidth, FHeight);
  FBitmap.Clear(clWhite32);
{$ENDIF}
end;

procedure TDrawNeuronGraph.SetConnections(Cons: TArray<TConnection>);
begin
  FCons.Clear;
  FCons.AddRange(Cons);
end;

procedure TDrawNeuronGraph.SetNeurons(Neurons: TArray<TNeuron>);
begin
  FNeurons.Clear;
  FNeurons.AddRange(Neurons);
end;

function TDrawNeuronGraph.WeightMax: Single;
var
  iCon: TConnection;
begin
  Result := NegInfinity;
  for iCon in FCons do
    Result := Max(Result, iCon.Weight);
end;

function TDrawNeuronGraph.WeightMin: Single;
var
  iCon: TConnection;
begin
  Result := Infinity;
  for iCon in FCons do
    Result := Min(Result, iCon.Weight);
end;

procedure TDrawNeuronGraph.Draw(LineWidth: Single);
var
  GP: TFannGraphPositions;
begin
{$IFDEF GR32!}
  FBitmap.Clear(clWhite32);
{$ELSE}
  Clear;
{$ENDIF}
  GP := TFannGraphPositions.Create(FWidth - FBorderHori * 2, FHeight - FBorderVert * 2, FNeurons.ToArray);
  try
    if FIsDrawCons then
      DrawCon(GP, LineWidth);
    if FIsDrawWeigths then
      DrawWeights(GP);
    if FIsDrawNeurons then
      DrawNeurons(GP);
  finally
    GP.Free;
  end;
{$IFDEF GR32!}
  Repaint;
{$ENDIF}
end;

procedure TDrawNeuronGraph.DrawWeights(GP: TFannGraphPositions);
var
  Pmov, P1, P2: TPointF;
  P: TPointF;
  N1, N2: TNeuron;
  iCon: TConnection;
begin
  Pmov := TPointF.Create(0, FBorderVert);
  for iCon in FCons do
  begin
    N1 := iCon.FromNeuron;
    N2 := iCon.ToNeuron;
    if FNeurons.Contains(N1) and FNeurons.Contains(N2) then
    begin
      P1 := GP.NeuronPosition(N1) + Pmov;
      P2 := GP.NeuronPosition(N2) + Pmov;

      if Odd(iCon.FromNeuron.Pos.X) then
        P := (P2 - P1) * 0.45
      else
        P := (P2 - P1) * 0.55;
      P   := P + P1;
      DrawWeight(P, iCon.Weight);
    end;
  end;
end;

procedure TDrawNeuronGraph.DrawCon(GP: TFannGraphPositions; LineWidth: Single);
var
  Pmov, P1, P2: TPointF;
  N1, N2: TNeuron;
  iCon: TConnection;
  C: TColor;
  _Min, _Max, M: Single;
begin
  _Min := WeightMin;
  _Max := WeightMax;
  Pmov := TPointF.Create(0, FBorderVert);
  for iCon in FCons do
  begin
    N1 := iCon.FromNeuron;
    N2 := iCon.ToNeuron;
    if FNeurons.Contains(N1) and FNeurons.Contains(N2) then
    begin
      P1 := GP.NeuronPosition(N1) + Pmov;
      P2 := GP.NeuronPosition(N2) + Pmov;

      if iCon.Weight > 0 then
        M := _Max
      else
        M := _Min;

      if IsZero(M) then
        C := clWhite
      else
        C := Gray(20 + 255 - Round(Abs(iCon.Weight / M) * 236));
      DoConnectionColor(iCon, C);
      DrawLine(P1, P2, C, LineWidth);
    end;
  end;
end;

procedure TDrawNeuronGraph.ClearCanvas;
var
  R: TRect;
begin
  R                   := TRect.Create(TPoint.Create(0, 0), FWidth, FHeight);
  Fcanvas.brush.color := clWhite;
  Fcanvas.fillrect(R);
end;

function TDrawNeuronGraph.ConOfPoint(P: TPoint; Radius: Single; var Con: TConnection): Boolean;
var
  iCon: TConnection;
  N1, N2: TNeuron;
  P1, P2, P3, P4: TPointF;
  GP: TFannGraphPositions;
begin
  P  := P - TPoint.Create(0, FBorderVert);
  GP := TFannGraphPositions.Create(FWidth - FBorderHori * 2, FHeight - FBorderVert * 2, FNeurons.ToArray);
  try
    for iCon in FCons do
    begin
      N1 := iCon.FromNeuron;
      N2 := iCon.ToNeuron;
      if FNeurons.Contains(N1) and FNeurons.Contains(N2) then
      begin
        P1 := GP.NeuronPosition(N1);
        P2 := GP.NeuronPosition(N2);
        if (IntersecCircleLine(P1, P2, P, Radius, P3, P4) > 0) and (PointOnLine(P1, P2, P3) or PointOnLine(P1, P2, P4)) then
        begin
          Con := iCon;
          Exit(True);
        end;
      end;
    end;
  finally
    GP.Free;
  end;
  Result := False;
end;

procedure TDrawNeuronGraph.DrawNeuronText(Pos: TPointF; N: TNeuron);
var
  s: string;
begin
  if FIsDrawValue then
  begin
    s := Format('%.*f', [FDigits, N.InValue]) + '/' + Format('%.*f', [FDigits, N.OutValue]) + '/' +
      Format('%.*f', [FDigits, N.DeriveValue]);
    DrawText(Pos, s, clRed)
  end
  else
  begin
    s := N.Pos.X.ToString;
    DrawText(Pos, s);
  end;
end;

procedure TDrawNeuronGraph.Clear;
begin
{$IFDEF GR32!}
  FBitmap.Clear(clWhite32);
{$ENDIF}
  ClearCanvas;
end;

{$IFDEF GR32!}

procedure TDrawNeuronGraph.Repaint;
begin
  FBitmap.DrawTo(FCanvas.Handle, 0, 0);
end;

procedure TDrawNeuronGraph.DrawLine(P1: TPointF; P2: TPointF; C: TColor; LW: Single);
var
  L: TLine;
begin
  L := TLine.Create(FBitmap);
  try
    L.AddPoints(P1);
    L.AddPoints(P2);
    L.DrawLine(LW, Color32(C));
  finally
    L.Free;
  end;
end;

procedure TDrawNeuronGraph.DrawText(Pos: TPointF; Text: string; C: TColor);
var
  T: TText;
  H, W: Single;
begin
  T := TText.Create(FBitmap);
  try
    T.Height := FTextHeights;
    T.Text   := Text;
    H        := T.TextHeight;
    W        := T.TextWidth;
    T.DrawText(Pos.X - W / 2, Pos.Y + H / 4, Color32(C));
  finally
    T.Free;
  end;
end;

procedure TDrawNeuronGraph.DrawNeuron(Pos: TPointF; N: TNeuron);
var
  L: TLine;
  R: TRectF;
  P: TPointF;
  CBorder: TColor;
  CFill: TColor;
begin
  L := TLine.Create(FBitmap);
  try

    if N.IsBias then
    begin
      P := Pos + TPointF.Create(-CircleWidth / 2, -CircleWidth / 2);
      R := TRectF.Create(P, CircleWidth, CircleWidth);
      L.AddRect(R.Round);
    end
    else
      L.AddCircle(Pos.X, Pos.Y, CircleWidth / 2);

    CBorder := clBlack;
    CFill   := clWhite;
    DoNeuronColor(N, CBorder, CFill);
    L.DrawArea(1, Color32(CBorder), Color32(CFill));
  finally
    L.Free;
  end;
end;

procedure TDrawNeuronGraph.DrawWeight(Pos: TPointF; Weight: Single);
var
  T: TText;
  H, W: Single;
begin
  T := TText.Create(FBitmap);
  try
    T.Text := Format('%.1f', [Weight]);
    H      := T.TextHeight;
    W      := T.TextWidth;
    T.DrawText(Pos.X - W / 2, Pos.Y + H / 4);
  finally
    T.Free;
  end;
end;

{$ELSE}

procedure TDrawNeuronGraph.DrawLine(P1: TPointF; P2: TPointF; C: TColor; LW: Single);
var
  _LW: Integer;
begin
  _LW := FCanvas.Pen.Width;
  try
    FCanvas.Pen.Width := Round(LW);
    FCanvas.Pen.Color := C;
    FCanvas.Polyline([P1.Round, P2.Round]);
  finally
    FCanvas.Pen.Width := _LW;
  end;
end;

procedure TDrawNeuronGraph.DrawNeuron(Pos: TPointF; N: TNeuron);
var
  R: TRect;
  P1: TPoint;
  tmpBS: TBrushStyle;
  tmpBorder: TColor;
  tmpFill: TColor;
  CBorder: TColor;
  CFill: TColor;
begin
  P1 := Pos.Round + TPoint.Create(-CircleWidth div 2, -CircleWidth div 2);
  R  := TRect.Create(P1, CircleWidth, CircleWidth);

  CBorder := clBlack;
  CFill   := clWhite;
  DoNeuronColor(N, CBorder, CFill);

  tmpBS     := FCanvas.Brush.Style;
  tmpBorder := FCanvas.Pen.Color;
  tmpFill   := FCanvas.Brush.Color;
  try
    FCanvas.Brush.Style := bsSolid;
    FCanvas.Brush.Color := CFill;
    FCanvas.Pen.Color   := CBorder;
    if N.IsBias then
      FCanvas.Rectangle(R)
    else
      FCanvas.Ellipse(R);
  finally
    FCanvas.Brush.Style := tmpBS;
    FCanvas.Pen.Color   := tmpBorder;
    FCanvas.Brush.Color := tmpFill;
  end;
end;

procedure TDrawNeuronGraph.DrawText(Pos: TPointF; Text: string; C: TColor);
var
  H, W: Integer;
begin
  H                  := FCanvas.TextHeight('0');
  W                  := FCanvas.TextWidth('0');
  FCanvas.Font.Color := C;
  FCanvas.TextOut(Pos.Round.X - W div 2, Pos.Round.Y - H div 2, Text);
end;

procedure TDrawNeuronGraph.DrawWeight(Pos: TPointF; Weight: Single);
var
  H, W: Integer;
  Text: string;
begin
  Text := Format('%.1f', [Weight]);
  H    := FCanvas.TextHeight(Text);
  W    := FCanvas.TextWidth(Text);
  // FCanvas.Brush.Style := bsClear;
  FCanvas.TextOut(Pos.Round.X - W div 2, Pos.Round.Y - H div 2, Text);
end;

{$ENDIF}
{ TFannGraphPositions }

constructor TFannGraphPositions.Create(PixelWidth, PixelHeight: Integer; DrawNeurons: TArray<TNeuron>);
begin
  inherited Create;
  FDrawNeurons := TList<TNeuron>.Create;
  FDrawNeurons.AddRange(DrawNeurons);
  FDrawNeurons.Sort;
  FNeuronsPerLayer := NeuronsPerLayer;
  FPixelWidth      := PixelWidth;
  FPixelHeight     := PixelHeight;
end;

destructor TFannGraphPositions.Destroy;
begin
  FDrawNeurons.Free;
  inherited;
end;

function TFannGraphPositions.LayerCount: Integer;
var
  iNeuron: TNeuron;
begin
  Result := 0;
  for iNeuron in FDrawNeurons do
    Result := Max(Result, iNeuron.LayerIndx + 1);
end;

function TFannGraphPositions.NeuronsPerLayer: TArray<Integer>;
var
  i, c: Integer;
begin
  c := LayerCount;
  SetLength(Result, c);
  for i       := 0 to c - 1 do
    Result[i] := NeuronCount(i);
end;

function TFannGraphPositions.NeuronCount(LayerIndx: Integer): Integer;
var
  iNeuron: TNeuron;
begin
  Result := 0;
  for iNeuron in FDrawNeurons do
    if iNeuron.LayerIndx = LayerIndx then
      Result := Result + 1;
end;

function TFannGraphPositions.NeuronCountMax: Integer;
var
  i: Integer;
begin
  Result   := 0;
  for i    := 0 to LayerCount - 1 do
    Result := Max(NeuronCount(i), Result);
end;

function TFannGraphPositions.NeuronOfPoint(P: TPointF; CircleWidth: Integer; var Neuron: TNeuron): Boolean;
var
  iNeuron: TNeuron;
  P1: TPointF;
begin
  for iNeuron in FDrawNeurons do
  begin
    P1 := NeuronPosition(iNeuron);
    if TPointF.PointInCircle(P, P1, CircleWidth div 2) then
    begin
      Neuron := iNeuron;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TFannGraphPositions.NeuronPosition(N: TNeuron): TPointF;
begin
  Result := TPointF.Create(PosX(N), PosY(N));
end;

function TFannGraphPositions.NeuronXDistance: Single;
begin
  Result := FPixelWidth / NeuronCountMax;
end;

function TFannGraphPositions.NeuronYDistance: Single;
begin
  Result := FPixelHeight / (Length(FNeuronsPerLayer) - 1)
end;

function TFannGraphPositions.PosX(N: TNeuron): Single;
var
  C: Integer;
  P: Single;
begin
  C := NeuronCount(N.LayerIndx);
  if Odd(C) then
    P := N.Pos.X - (C - 1) / 2
  else
    P := N.Pos.X - C / 2 + 0.5;

  Result := FPixelWidth / 2 + P * NeuronXDistance;
end;

function TFannGraphPositions.PosY(N: TNeuron): Single;
begin
  Result := NeuronYDistance * N.LayerIndx;
end;

{ TGraphAction }

constructor TGraphAction.Create(Graph: TDrawNeuronGraph);
begin
  inherited Create;
  FGraph := Graph;
  SetLength(FMarkedNeurons, 0);
end;

procedure TGraphAction.DoEmptyMark;
begin
  if Assigned(FOnEmptyMark) then
    FOnEmptyMark(Self);
end;

procedure TGraphAction.DoMark;
begin
  if Assigned(FOnMark) then
    FOnMark(Self);
end;

procedure TGraphAction.MarkLayerNeurons;
var
  NN: TArray<TNeuron>;
begin
  SetLength(FMarkedNeurons, 0);
  NN := FGraph.NeuronLayerOfPoint(FGraphPos);
  if Length(NN) > 0 then
  begin
    FMarkedNeurons := NN;
    DoMark;
  end
  else
    DoEmptyMark;
end;

procedure TGraphAction.Mark;
var
  N: TNeuron;
  Con: TConnection;
begin
  N := nil;
  SetLength(FMarkedNeurons, 0);
  SetLength(FMarkedCons, 0);
  if FGraph.NeuronOfPoint(FGraphPos, N) and Assigned(N) then
  begin
    SetLength(FMarkedNeurons, 1);
    FMarkedNeurons[0] := N;
    DoMark;
  end
  else if FGraph.ConOfPoint(FGraphPos, 10, Con) and Assigned(Con) then
  begin
    SetLength(FMarkedCons, 1);
    FMarkedCons[0] := Con;
    DoMark;
  end
  else
    DoEmptyMark;
end;

end.
