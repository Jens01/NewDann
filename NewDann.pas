// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
unit NewDann;

interface

{ .$DEFINE TEECHART }

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections, Winapi.Windows, Winapi.ShellAPI,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, NewDann.Network, Vcl.Samples.Spin,
  OtlParallel, OtlTaskControl, OtlComm, OtlCommon, NewDann.Data,
  System.Diagnostics, Vcl.ComCtrls, Vcl.Dialogs,
  Vcl.ExtDlgs, NewDann.Formula,
  NewDann.frm.Graph,
{$IFDEF TEECHART}
  VCLTee.Chart, VCLTee.TeEngine, VCLTee.Series,
  VclTee.TeeGDIPlus, VCLTee.TeeProcs
{$ELSE}
  NiceChart, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart
{$ENDIF}
    ;

type

  TfrmNewDann = class(TForm)
    mmoMSE: TMemo;
    btnCreateNN: TButton;
    btnTrainRPROP: TButton;
    btnTrainBackpropBatch: TButton;
    lblCount: TLabel;
    btnSave: TButton;
    btnLoad: TButton;
    btnRemove: TButton;
    grpDraw: TGroupBox;
    btnTrainBackPropOnline: TButton;
    btnBreak: TButton;
    btnCleanWeights: TButton;
    rgWeightError: TRadioGroup;
    edtWeightLambda: TEdit;
    edtMSE: TEdit;
    pgcDann: TPageControl;
    tsCreateNN: TTabSheet;
    btnSetWeights: TButton;
    tsTrainNN: TTabSheet;
    lblError: TLabel;
    tsData: TTabSheet;
    mmoData: TMemo;
    edtSeparator: TEdit;
    lblSeparator: TLabel;
    btnLoadData: TButton;
    dlgData: TOpenTextFileDialog;
    lblDataInfo: TLabel;
    edtDecimalSeparator: TEdit;
    lblDecimalSeparator: TLabel;
    edtInputCount: TSpinEdit;
    lblInputCount: TLabel;
    lblOutputNeuronsCount: TLabel;
    edtOutputCount: TSpinEdit;
    lblWeightLambda: TLabel;
    pnlMain: TPanel;
    tsTest: TTabSheet;
    grpHiddenLayer: TGroupBox;
    edtNeuronCount: TSpinEdit;
    lblNeuronCount: TLabel;
    edtLayerCount: TSpinEdit;
    lblLayerCount: TLabel;
    cbbthreshold: TComboBox;
    cbbthresholdOfNode: TComboBox;
    lblHeader: TLabel;
    btnTest: TButton;
    lblTestResult: TLabel;
    btnExportStructure: TButton;
    dlgExportStructure: TSaveTextFileDialog;
    frmGraph: TfrmGraph;
    lblChangeActType: TLabel;
    lblHeader2: TLabel;
    lblWikiThreshold: TLinkLabel;
    edtMSEDifference: TEdit;
    lblMEBreak: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCreateNNClick(Sender: TObject);
    procedure btnTrainBackPropOnlineClick(Sender: TObject);
    procedure btnTrainRPROPClick(Sender: TObject);
    procedure btnBreakClick(Sender: TObject);
    procedure btnTrainBackpropBatchClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnSetWeightsClick(Sender: TObject);
    procedure btnCleanWeightsClick(Sender: TObject);
    procedure rgWeightErrorClick(Sender: TObject);
    procedure edtWeightLambdaChange(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
    procedure btnLoadDataClick(Sender: TObject);
    procedure mmoDataChange(Sender: TObject);
    procedure edtSeparatorChange(Sender: TObject);
    procedure edtDecimalSeparatorChange(Sender: TObject);
    procedure cbbthresholdOfNodeChange(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnExportStructureClick(Sender: TObject);
    procedure lblWikiThresholdLinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
    procedure edtMSEDifferenceChange(Sender: TObject);
    procedure cht1DblClick(Sender: TObject);
  private
{$IFDEF TEECHART}
    cht1: TChart;
    Series1: TFastLineSeries;
{$ELSE}
    chtError: TNiceChart;
    Series: TNiceSeries;
{$ENDIF}
    FNN: TNeuralNet;
    FData: TTrainData;
    FBackgroundWorker: IOmniBackgroundWorker;
    FWorkItem: IOmniWorkItem;
    FProcess: TOmniBackgroundWorkerDelegate;
    FRunMSE: TProc;
    procedure ClearTrain;
    procedure Draw;
    procedure OnNeuronSelect(Sender: TObject; SelectedNeurons: TArray<TNeuron>);
    procedure OnConSelect(Sender: TObject; SelectedCons: TArray<TConnection>);
    procedure OnUnselect(Sender: TObject);
    procedure OnMSEEvent(Sender: TObject; MSE: Single; Epoche: Integer; var Stop: Boolean);
    procedure OnTrainDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure OnValidDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure OnTestDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure OnNNCreating(Sender: TObject);
    procedure RequestDone(const Sender: IOmniBackgroundWorker; const workItem: IOmniWorkItem);
    procedure OnThreadMessageError(const task: IOmniTaskControl; const msg: TOmniMessage);
    procedure RunWorker;
    procedure ClearWorker;
    procedure OnDataError(Sender: TObject);
    procedure MemoToData;
    procedure Train(TrainType: TTrainType);
    procedure OnThreadMessageCount(const task: IOmniTaskControl; const msg: TOmniMessage);
    function ArrayToStr(N: TArray<Single>): string;
{$IFDEF TEECHART}
    procedure ChartZoomAll;
{$ENDIF}
    procedure ChartDraw(const MSEValue: Double);
  public
  end;

var
  frmNewDann: TfrmNewDann;

implementation

{$R *.dfm}

procedure TfrmNewDann.btnBreakClick(Sender: TObject);
begin
  if Assigned(FworkItem) then
    FworkItem.CancellationToken.Signal;
end;

procedure TfrmNewDann.btnCleanWeightsClick(Sender: TObject);
begin
  FNN.CleanSmallWeights(0.01);
  Draw;
end;

procedure TfrmNewDann.btnLoadClick(Sender: TObject);
var
  Filename: string;
begin
  Filename := ChangeFileExt(ParamStr(0), '.XML');
  if FileExists(Filename) then
  begin
    FNN.LoadStructure(Filename);
    Draw;
  end
  else
    ShowMessage('StructureFile not exists!');
end;

procedure TfrmNewDann.btnLoadDataClick(Sender: TObject);
var
  Encoding: TEncoding;
  EncIndex: Integer;
  Filename: string;
begin
  if dlgData.Execute(Self.Handle) then
  begin
    Filename := dlgData.FileName;
    EncIndex := dlgData.EncodingIndex;
    Encoding := dlgData.Encodings.Objects[EncIndex] as TEncoding;

    if FileExists(Filename) then
    begin
      mmoData.Lines.LoadFromFile(FileName, Encoding);

      FData.DecimalSeparator := edtDecimalSeparator.Text[1];
      FData.Separator        := edtSeparator.Text;
      FData.LoadDataFromFile(FileName, Encoding);
    end
    else
      raise Exception.Create('File does not exist.');
  end;
end;

procedure TfrmNewDann.btnTestClick(Sender: TObject);
var
  Error: Single;
  ErrorStr: string;
  i: Integer;
begin
  Error    := FNN.ErrorOfTestData(FData.TestDataCount);
  ErrorStr := Format('%.*f', [6, Error]);

  lblTestResult.Caption := 'Error : ' + ErrorStr;

  mmoMSE.Clear;
  for i := 0 to FData.TestDataCount - 1 do
  begin
    FNN.Run(FData.InTestData[i]);
    mmoMSE.Lines.Add(ArrayToStr(FNN.OutputValues) + '-> [' + ArrayToStr(FData.InTestData[i]) + '] Expect: ' +
      ArrayToStr(FData.OutTestData[i]));
  end;
  mmoMSE.Lines.Add('');
  mmoMSE.Lines.Add('Error : ' + ErrorStr);
end;

procedure TfrmNewDann.btnTrainBackpropBatchClick(Sender: TObject);
begin
  Train(BackpropBatch);
end;

procedure TfrmNewDann.btnExportStructureClick(Sender: TObject);
begin
  if dlgExportStructure.Execute then
  begin
    FNN.SaveStructure(dlgExportStructure.FileName);
  end;
end;

procedure TfrmNewDann.btnCreateNNClick(Sender: TObject);
var
  L: TList<Integer>;
  i: Integer;
  TT: TThresholdType;
begin
  L := TList<Integer>.Create;
  try
    L.Add(string(edtInputCount.Text).ToInteger);
    for i := 0 to edtLayerCount.Value - 1 do
      L.Add(edtNeuronCount.Value);
    L.Add(string(edtOutputCount.Text).ToInteger);

    FNN.CreateNetwork(L.ToArray);

    FNN.DefActFunction(0, funcLINEAR);
    TT    := TThresholdType(cbbthreshold.ItemIndex);
    for i := 1 to L.Count - 2 do
      FNN.DefActFunction(i, TT);
    FNN.DefActFunction(L.Count - 1, funcLINEAR);
  finally
    L.Free;
  end;

  // FNN.RandomWeights(-1, 1);
  FNN.RandomWeightsByNguyenWidrow(-0.5, 0.5);

  FNN.MomentumFaktor := 0.9;
  FNN.Epsilon        := 0.01;
  Draw;
end;

function TfrmNewDann.ArrayToStr(N: TArray<Single>): string;
var
  sb: TStringBuilder;
  i: Integer;
begin
  sb := TStringBuilder.Create;
  try
    for i := 0 to Length(N) - 1 do
      sb.AppendFormat('%.2f', [N[i]]).Append(' ');
    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

{$IFDEF TEECHART}

procedure TfrmNewDann.ChartZoomAll;
var
  _Max: Single;
  _Min: Single;
begin
  _Max := Series1.XValues.MaxValue;
  cht1.BottomAxis.SetMinMax(0, _Max);
  _Min := Series1.YValues.MinValue;
  _Max := Series1.YValues.MaxValue;
  cht1.LeftAxis.SetMinMax(_Min, _Max);
end;
{$ENDIF}

procedure TfrmNewDann.ChartDraw(const MSEValue: Double);
const
  Steps = 2;
var
  i, c: Integer;
{$IFDEF TEECHART}
  R: Single;
  _Min: Single;
  _Max: Single;
{$ENDIF}
begin
{$IFDEF TEECHART}
  c := Series1.Count;
  i := c - 1;
  Series1.AddXY(i, MSEValue);

  if c mod Steps = 0 then
  begin
    R    := Series1.YValues[i - 8] - Series1.YValues[i];
    _Min := Series1.YValues[i] - R / 3;
    _Max := Series1.YValues[i - 8];
    cht1.LeftAxis.SetMinMax(_Min, _Max);
    _Min := i - 8;
    _Max := i + 1;
    cht1.BottomAxis.SetMinMax(_Min, _Max);
    cht1.Refresh;
  end;
{$ELSE}
  c := Series.Count;
  i := c - 1;
  chtError.BeginUpdate;
  Series.AddXY(i, MSEValue);

  if c mod Steps = 0 then
  begin
    chtError.EndUpdate;
  end;
{$ENDIF}
end;

procedure TfrmNewDann.cht1DblClick(Sender: TObject);
begin
{$IFDEF TEECHART}
  ChartZoomAll;
{$ENDIF}
end;

procedure TfrmNewDann.btnRemoveClick(Sender: TObject);
begin
  frmGraph.RemoveSelected;
end;

procedure TfrmNewDann.btnSaveClick(Sender: TObject);
begin
  FNN.SaveStructure(ChangeFileExt(ParamStr(0), '.XML'));
end;

procedure TfrmNewDann.btnSetWeightsClick(Sender: TObject);
begin
  FNN.RandomWeightsByNguyenWidrow(-0.5, 0.5);
  Draw;
end;

procedure TfrmNewDann.btnTrainBackPropOnlineClick(Sender: TObject);
begin
  Train(BackpropOnline);
end;

procedure TfrmNewDann.btnTrainRPROPClick(Sender: TObject);
begin
  Train(RPROP);
end;

procedure TfrmNewDann.cbbthresholdOfNodeChange(Sender: TObject);
var
  iNeuron: TNeuron;
begin
  for iNeuron in frmGraph.MarkedNeurons do
    iNeuron.ActFunc := TThresholdType(cbbthresholdOfNode.ItemIndex);
end;

procedure TfrmNewDann.Draw;
begin
  frmGraph.Draw;
end;

procedure TfrmNewDann.edtDecimalSeparatorChange(Sender: TObject);
begin
  if Length(edtDecimalSeparator.Text) = 1 then
    FData.DecimalSeparator := edtDecimalSeparator.Text[1];
end;

procedure TfrmNewDann.edtMSEDifferenceChange(Sender: TObject);
begin
  FNN.MSEdifference := string(edtMSEDifference.Text).ToSingle;
end;

procedure TfrmNewDann.edtSeparatorChange(Sender: TObject);
begin
  FData.Separator := edtSeparator.Text;
end;

procedure TfrmNewDann.edtWeightLambdaChange(Sender: TObject);
var
  E: Single;
begin
  FormatSettings.DecimalSeparator := '.';
  if TryStrToFloat(edtWeightLambda.Text, E, FormatSettings) then
    FNN.WeightErrorLambda := E
  else
    raise Exception.Create('Fehler: WeightErrorLambda');
end;

procedure TfrmNewDann.FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
begin
  if NewHeight < 714 then
    NewHeight := 714;
  if NewWidth < 1100 then
    NewWidth := 1100;
end;

procedure TfrmNewDann.FormCreate(Sender: TObject);
begin
  FNN                   := TNeuralNet.Create;
  FNN.OnMSE             := OnMSEevent;
  FNN.OnTrainData       := OnTrainDataEvent;
  FNN.OnValidData       := OnValidDataEvent;
  FNN.OnTestData        := OnTestDataEvent;
  FNN.OnCreateStructure := OnNNCreating;
  FData                 := TTrainData.Create;
  FData.OnError         := OnDataError;
  MemoToData;

  frmGraph.NeuralNetwork  := FNN;
  frmGraph.OnNeuronSelect := OnNeuronSelect;
  frmGraph.OnConSelect    := OnConSelect;
  frmGraph.OnUnselect     := OnUnselect;

  cbbthreshold.Clear;
  cbbthreshold.Items.AddStrings(TThresholdType.ToArrayStr);
  cbbthreshold.ItemIndex := 1;

  cbbthresholdOfNode.Clear;
  cbbthresholdOfNode.Items.AddStrings(TThresholdType.ToArrayStr);
  cbbthresholdOfNode.ItemIndex := -1;

{$IFDEF TEECHART}
{$ELSE}
  chtError := TNiceChart.Create(Self);
  with chtError do
  begin
    Parent  := pnlMain;
    Left    := 8;
    Top     := 430;
    Width   := 375;
    Height  := 300;
    Anchors := [akLeft, akBottom];

    Title            := 'Error';
    ShowTitle        := True;
    ShowLegend       := False;
    AxisXTitle       := 'Epoch';
    AxisYTitle       := 'Error';
    AxisYScale       := 100;
    FormatterXAxis := '0.##';
    FormatterYAxis := '0.#######';
    AxisXOnePerValue := True;
  end;
  Series := chtError.AddSeries(skLine);
{$ENDIF}
  edtWeightLambda.Text    := '0.00001';
  edtMSEDifference.Text   := Format('%.15f', [FNN.MSEdifference]);
  rgWeightError.ItemIndex := 0;
  pgcDann.ActivePageIndex := 0;
end;

procedure TfrmNewDann.FormDestroy(Sender: TObject);
begin
  FData.Free;
  FNN.Free;
end;

procedure TfrmNewDann.lblWikiThresholdLinkClick(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, 'Open', PChar('https://en.wikipedia.org/wiki/Activation_function#ref_heaviside'), PChar(''), nil,
    SW_SHOWNORMAL);
end;

procedure TfrmNewDann.MemoToData;
begin
  FData.LoadDataFromArray(mmoData.Lines.ToStringArray);
end;

procedure TfrmNewDann.mmoDataChange(Sender: TObject);
begin
  MemoToData;
end;

procedure TfrmNewDann.OnTestDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  InData  := FData.InTestData[Indx];
  OutData := FData.OutTestData[Indx];
end;

procedure TfrmNewDann.OnTrainDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  InData  := FData.InTrainData[Indx];
  OutData := FData.OutTrainData[Indx];
end;

procedure TfrmNewDann.OnValidDataEvent(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  InData  := FData.InValidData[Indx];
  OutData := FData.OutValidData[Indx];
end;

procedure TfrmNewDann.OnNeuronSelect(Sender: TObject; SelectedNeurons: TArray<TNeuron>);
var
  TT: TThresholdType;
begin
  btnRemove.Enabled          := True;
  cbbthresholdOfNode.Enabled := True;
  if SameThresholdType(ThresholdTypeOfNeurons(SelectedNeurons), TT) then
    cbbthresholdOfNode.ItemIndex := Ord(TT)
  else
    cbbthresholdOfNode.ItemIndex := -1;
end;

procedure TfrmNewDann.OnConSelect(Sender: TObject; SelectedCons: TArray<TConnection>);
begin
  btnRemove.Enabled := True;
end;

procedure TfrmNewDann.OnUnselect(Sender: TObject);
begin
  btnRemove.Enabled            := False;
  cbbthresholdOfNode.Enabled   := False;
  cbbthresholdOfNode.ItemIndex := -1;
end;

procedure TfrmNewDann.OnNNCreating(Sender: TObject);
begin
  FData.InputCount  := FNN.InCount;
  FData.OutputCount := FNN.OutCount;
end;

procedure TfrmNewDann.OnDataError(Sender: TObject);
begin
  lblDataInfo.Caption := FData.Error;
end;

procedure TfrmNewDann.OnMSEEvent(Sender: TObject; MSE: Single; Epoche: Integer; var Stop: Boolean);
var
  V: TOmniValue;
begin
  Stop := FworkItem.CancellationToken.IsSignalled;
  if (Epoche < 100) and (Epoche mod 3 = 0) or (Epoche < 1000) and (Epoche mod 10 = 0) or (Epoche mod 100 = 0) then
  begin
    V.AsDouble := MSE;
    FworkItem.task.Comm.Send(0, V);
    V.AsInteger := Epoche;
    FworkItem.task.Comm.Send(1, V);
  end;
end;

procedure TfrmNewDann.OnThreadMessageError(const task: IOmniTaskControl; const msg: TOmniMessage);
begin
  mmoMSE.Lines.Add(Format('%.*f', [8, msg.MsgData.AsDouble]));
  ChartDraw(msg.MsgData.AsDouble);
  // Draw;
end;

procedure TfrmNewDann.OnThreadMessageCount(const task: IOmniTaskControl; const msg: TOmniMessage);
begin
  lblCount.Caption := msg.MsgData.AsInteger.ToString;
  lblCount.Repaint;
  Draw;
end;

procedure TfrmNewDann.RunWorker;
begin
  if Assigned(FProcess) then
  begin
    FBackgroundWorker := Parallel.BackgroundWorker.NumTasks(2). //
      OnRequestDone(RequestDone).//
      TaskConfig(Parallel.TaskConfig.OnMessage(0, OnThreadMessageError).OnMessage(1, OnThreadMessageCount)).//
      Execute(FProcess);
    FworkItem := FBackgroundWorker.CreateWorkItem(0);
    FBackgroundWorker.Schedule(FworkItem);
  end;
end;

procedure TfrmNewDann.Train(TrainType: TTrainType);
var
  SW: TStopwatch;
begin
  if not FData.IsValid then
  begin
    ShowMessage('Network and data not compatible');
    Exit;
  end;
  if (FNN.InCount = FData.InputCount) and (FNN.OutCount = FData.OutputCount) then
  begin

    // FNN.DropOutRateOfHiddenLayer := [0.25, 0.25];
    FNN.DropOutRateOfHiddenLayer := [0.25];

    SW := TStopwatch.Create;
    case TrainType of
      RPROP:
        begin
          FProcess := procedure(const WorkItem: IOmniWorkItem)
            begin
              SW.Start;
              FormatSettings.DecimalSeparator := '.';
              FNN.Train_RPROP(FData.TrainDataCount, FData.ValidDataCount, StrToFloat(edtMSE.Text, FormatSettings));
            end;
        end;
      BackpropOnline:
        begin
          FProcess := procedure(const WorkItem: IOmniWorkItem)
            begin
              SW.Start;
              FormatSettings.DecimalSeparator := '.';
              FNN.Train_BackPROP_Online(FData.TrainDataCount, FData.ValidDataCount, StrToFloat(edtMSE.Text, FormatSettings));
            end;
        end;
      BackpropBatch:
        begin
          FProcess := procedure(const WorkItem: IOmniWorkItem)
            begin
              SW.Start;
              FormatSettings.DecimalSeparator := '.';
              FNN.Train_BackPROP_Batch(FData.TrainDataCount, FData.ValidDataCount, StrToFloat(edtMSE.Text, FormatSettings));
            end;
        end;
    end;

    FRunMSE := procedure
      var
        MSE: Single;
      begin
        SW.Stop;
        MSE              := FNN.ErrorOfValidData(FData.ValidDataCount);
        lblcount.Caption := FNN.LastEpochIndx.ToString;
        mmoMSE.Lines.Add('EpochCount-> ' + FNN.LastEpochIndx.ToString);
        mmoMSE.Lines.Add('Error     -> ' + Format('%.*f', [8, MSE]));
        mmoMSE.Lines.Add('StopReason-> ' + FNN.StopType.ToText);
        mmoMSE.Lines.Add('Time      -> ' + SW.Elapsed);
      end;

    ClearTrain;
    RunWorker;
  end
  else
    ShowMessage('wrong network');
end;

procedure TfrmNewDann.ClearTrain;
begin
{$IFDEF TEECHART}
  Series1.Clear;
{$ELSE}
  chtError.Series[0].Clear;
{$ENDIF}
end;

procedure TfrmNewDann.ClearWorker;
begin
  FProcess := nil;
  FRunMSE  := nil;
end;

procedure TfrmNewDann.RequestDone(const Sender: IOmniBackgroundWorker; const workItem: IOmniWorkItem);
begin
  if Assigned(FRunMSE) then
    FRunMSE;
  Draw;
  ClearWorker;
end;

procedure TfrmNewDann.rgWeightErrorClick(Sender: TObject);
begin
  case rgWeightError.ItemIndex of
    0:
      FNN.WeightErrorFunc := nil;
    1:
      FNN.WeightErrorFunc := Weight_Error1;
    2:
      FNN.WeightErrorFunc := Weight_Error2;
  end;
end;

end.
