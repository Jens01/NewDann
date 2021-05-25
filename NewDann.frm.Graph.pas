// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unit NewDann.frm.Graph;

interface

uses
  NewDann.Graph, NewDann.Network, NewDann.Formula,
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.ExtCtrls,
  GR32_Layers, GR32_Image;

type

  TSelectNeuronEvent = procedure(Sender: TObject; SelectedNeurons: TArray<TNeuron>) of object;
  TSelectConEvent = procedure(Sender: TObject; SelectedCons: TArray<TConnection>) of object;

  TfrmGraph = class(TFrame)
    imgStructure: TImage32;
    pnlMenu: TPanel;
    chkWeights: TCheckBox;
    chkDrawValue: TCheckBox;
    edtLine: TSpinEdit;
    lblClickInfo: TLabel;
    lstInfo: TListBox;
    procedure chkWeightsClick(Sender: TObject);
    procedure chkDrawValueClick(Sender: TObject);
    procedure edtLineChange(Sender: TObject);
    procedure imgStructureMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
      Layer: TCustomLayer);
    procedure imgStructureGDIOverlay(Sender: TObject);
    procedure imgStructureClick(Sender: TObject);
    procedure imgStructureResize(Sender: TObject);
  private
    FIsStrg: Boolean;
    FGraph: TDrawNeuronGraph;
    FGraphAction: TGraphAction;
    FOnNeuronSelect: TSelectNeuronEvent;
    FOnUnselect: TNotifyEvent;
    FOnConSelect: TSelectConEvent;
    FNeuralNetwork: TNeuralNet;
    procedure OnGraphConColor(Sender: TObject; Con: TConnection; var Color: TColor);
    procedure OnGraphNeuronColor(Sender: TObject; Neuron: TNeuron; var ColorBorder, ColorFill: TColor);
    procedure OnGraphMarked(Sender: TObject);
    procedure OnGraphEmptyMarked(Sender: TObject);
    procedure DoNeuronSelect;
    procedure DoConSelect;
    procedure DoUnSelect;
    function GetMarkedCons: TArray<TConnection>;
    function GetMarkedNeurons: TArray<TNeuron>;
    procedure WriteInfoNeuron;
    procedure WriteInfoCon;
    procedure _Draw;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Draw; overload;
    procedure Draw(Neurons: TArray<TNeuron>; Cons: TArray<TConnection>); overload;
    procedure RemoveSelected;
    property NeuralNetwork: TNeuralNet read FNeuralNetwork write FNeuralNetwork;
    property MarkedNeurons: TArray<TNeuron> read GetMarkedNeurons;
    property MarkedCons: TArray<TConnection> read GetMarkedCons;
    property OnNeuronSelect: TSelectNeuronEvent read FOnNeuronSelect write FOnNeuronSelect;
    property OnConSelect: TSelectConEvent read FOnConSelect write FOnConSelect;
    property OnUnselect: TNotifyEvent read FOnUnselect write FOnUnselect;
  end;

implementation

{$R *.dfm}

{ TFrame1 }
constructor TfrmGraph.Create(AOwner: TComponent);
begin
  inherited;
  FGraph                   := TDrawNeuronGraph.Create(imgStructure.Canvas, imgStructure.Width, imgStructure.Height);
  FGraph.OnConnectionColor := OnGraphConColor;
  FGraph.OnNeuronColor     := OnGraphNeuronColor;

  FGraphAction             := TGraphAction.Create(FGraph);
  FGraphAction.OnMark      := OnGraphMarked;
  FGraphAction.OnEmptyMark := OnGraphEmptyMarked;
end;

destructor TfrmGraph.Destroy;
begin
  FGraphAction.Free;
  FGraph.Free;
  inherited;
end;

procedure TfrmGraph.chkDrawValueClick(Sender: TObject);
begin
  Draw;
end;

procedure TfrmGraph.chkWeightsClick(Sender: TObject);
begin
  Draw;
end;

procedure TfrmGraph.DoConSelect;
begin
  DoUnSelect;
  if Assigned(FOnConSelect) then
    FOnConSelect(Self, FGraphAction.MarkedCons);
end;

procedure TfrmGraph.DoNeuronSelect;
begin
  DoUnSelect;
  if Assigned(FOnNeuronSelect) then
    FOnNeuronSelect(Self, FGraphAction.MarkedNeurons);
end;

procedure TfrmGraph.DoUnSelect;
begin
  if Assigned(FOnUnSelect) then
    FOnUnSelect(Self);
end;

procedure TfrmGraph.Draw(Neurons: TArray<TNeuron>; Cons: TArray<TConnection>);
begin
  FGraph.SetNeurons(Neurons);
  FGraph.SetConnections(Cons);
  _Draw;
end;

procedure TfrmGraph.Draw;
begin
  FGraph.SetNeurons(FNeuralNetwork.ToNeurons);
  FGraph.SetConnections(FNeuralNetwork.ToConnections);
  _Draw;
end;

procedure TfrmGraph.edtLineChange(Sender: TObject);
begin
  FGraph.Draw(edtLine.Value);
end;

function TfrmGraph.GetMarkedCons: TArray<TConnection>;
begin
  Result := FGraphAction.MarkedCons;
end;

function TfrmGraph.GetMarkedNeurons: TArray<TNeuron>;
begin
  Result := FGraphAction.MarkedNeurons;
end;

procedure TfrmGraph.imgStructureClick(Sender: TObject);
begin
  if FIsStrg then
    FGraphAction.MarkLayerNeurons
  else
    FGraphAction.Mark;
  FGraph.Draw(edtLine.Value);
end;

procedure TfrmGraph.imgStructureGDIOverlay(Sender: TObject);
begin
  FGraph.Repaint;
end;

procedure TfrmGraph.imgStructureMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TCustomLayer);
begin
  FGraphAction.GraphPos := TPoint.Create(X, Y);
  FIsStrg               := ssCtrl in Shift;
end;

procedure TfrmGraph.imgStructureResize(Sender: TObject);
begin
  FGraph.SetBorder(imgStructure.Width, imgStructure.Height);
  FGraph.Draw(edtLine.Value);
end;

procedure TfrmGraph.OnGraphConColor(Sender: TObject; Con: TConnection; var Color: TColor);
var
  iCon: TConnection;
begin
  for iCon in FGraphAction.MarkedCons do
    if iCon = Con then
    begin
      Color := clRed;
      Break;
    end;
end;

procedure TfrmGraph.OnGraphNeuronColor(Sender: TObject; Neuron: TNeuron; var ColorBorder, ColorFill: TColor);
var
  iNeuron: TNeuron;
begin
  for iNeuron in FGraphAction.MarkedNeurons do
    if Neuron = iNeuron then
    begin
      ColorFill := clRed;
      Break;
    end;
end;

procedure TfrmGraph.RemoveSelected;
var
  iCon: TConnection;
  iNeuron: TNeuron;
begin
  if Assigned(FNeuralNetwork) then
  begin
    for iCon in FGraphAction.MarkedCons do
      FNeuralNetwork.RemoveConnection(iCon);
    for iNeuron in FGraphAction.MarkedNeurons do
      FNeuralNetwork.RemoveNeuron(iNeuron);
    Draw;
    DoUnSelect;
  end;
end;

procedure TfrmGraph._Draw;
begin
  FGraph.IsDrawWeigths := chkWeights.Checked;
  FGraph.IsDrawValue   := chkDrawValue.Checked;
  FGraph.BorderVert    := 80;
  imgStructure.BeginUpdate;
  try
    FGraph.Draw(edtLine.Value);
  finally
    imgStructure.EndUpdate;
  end;
end;

procedure TfrmGraph.WriteInfoCon;
var
  iCon: TConnection;

  function ConToStr(Con: TConnection): string;
  var
    sb: TStringBuilder;
  begin
    sb := TStringBuilder.Create;
    try
      sb.Append('FromPos: ').Append(Con.FromNeuron.Pos.ToText);
      sb.Append(' ToPos: ').Append(Con.ToNeuron.Pos.ToText);
      sb.Append(' Weight: ').Append(Con.Weight);

      Result := sb.ToString;
    finally
      sb.Free;
    end;
  end;

begin
  for iCon in FGraphAction.MarkedCons do
    lstInfo.AddItem(ConToStr(iCon), nil);
end;

procedure TfrmGraph.WriteInfoNeuron;
var
  iNeuron: TNeuron;

  function NodeToStr(N: TNeuron): string;
  var
    sb: TStringBuilder;
  begin
    sb := TStringBuilder.Create;
    try
      sb.Append('Pos: ').Append(N.Pos.ToText);
      sb.Append(' ').Append(N.ActFunc.ToName);
      if N.IsBias then
        sb.Append(' Biasnode');
      Result := sb.ToString;
    finally
      sb.Free;
    end;
  end;

begin
  for iNeuron in FGraphAction.MarkedNeurons do
    lstInfo.AddItem(NodeToStr(iNeuron), nil);
end;

procedure TfrmGraph.OnGraphMarked(Sender: TObject);
begin
  lstInfo.Clear;
  if Length(FGraphAction.MarkedNeurons) > 0 then
  begin
    WriteInfoNeuron;
    DoNeuronSelect;
  end;

  if Length(FGraphAction.MarkedCons) > 0 then
  begin
    WriteInfoCon;
    DoConSelect;
  end;
end;

procedure TfrmGraph.OnGraphEmptyMarked(Sender: TObject);
begin
  lstInfo.Clear;
  DoUnSelect;
end;

end.
