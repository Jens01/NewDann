// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
unit NewDann.Network;

interface

{.$DEFINE USEOPENCL }

uses
  System.Generics.Collections, System.SysUtils, System.Generics.Defaults, System.Types, System.Classes, System.Math,
  NewDann.Formula,
{$IFDEF USEOPENCL}
  NewDann.OpenCL,
{$ENDIF}
  Xml.XMLDoc, Xml.XMLIntf;

const
  cDeltaMinimum = 1E-6;

type
  TTrainType = (RPROP, BackpropOnline, BackpropBatch);
  TStopType = (stopNo, stopUserBreak, stopErrorAccomplished, stopNoErrorDifference);

  TStopTypeHelper = record helper for TStopType
  public
    function ToText: string;
  end;

  TPointHelper = record helper for TPoint
  public
    function ToText: string;
    procedure FromText(S: string);
  end;

  TRPROP = record
  private
    FDeltaMax: Single;
    FDeltaMin: Single;
    FDeltaDown: Single;
    FDeltaUp: Single;
  public
    procedure SetStandard;
    property DeltaMax: Single read FDeltaMax write FDeltaMax;
    property DeltaMin: Single read FDeltaMin write FDeltaMin;
    property DeltaUp: Single read FDeltaUp write FDeltaUp;
    property DeltaDown: Single read FDeltaDown write FDeltaDown;
  end;

  TNeuron = class
  strict private
    FDelta: Single;
    FInValue: Single;
    FOutValue: Single;
    FDeriveValue: Single;
    FIsBias: Boolean;
    FIsDropOut: Boolean;
    FActFunc: TThresholdType;
    FActSteepness: Single;
    FPos: TPoint;
    function GetOutValue: Single;
    procedure SetInValue(const Value: Single);
    function GetLayerIndx: Integer;
    function GetDelta: Single;
  public
    constructor Create(Num_Layer, Num_Neuron: Integer; IsBias: Boolean = False);
{$IFDEF USEOPENCL}
    procedure SetValue(const InValue, OutValue, DeriveValue: Single); overload;
{$ENDIF}
    procedure SetValue(const InValue: Single); overload;
    procedure NewPosX(const X: Integer);
    // TPoint in Pos :
    // X -> NeuronIndex
    // Y -> LayerIndex
    property LayerIndx: Integer read GetLayerIndx;
    property IsBias: Boolean read FIsBias;
    property IsDropOut: Boolean read FIsDropOut write FIsDropOut;
    property InValue: Single read FInValue write SetInValue;
    property OutValue: Single read FOutValue;
    property DeriveValue: Single read FDeriveValue;
    property ActSteepness: Single read FActSteepness write FActSteepness;
    property ActFunc: TThresholdType read FActFunc write FActFunc;
    property Delta: Single read GetDelta write FDelta;
    property Pos: TPoint read FPos;
  end;

  TNeuronList = class(TObjectList<TNeuron>)
  strict private
{$IFDEF USEOPENCL}
    FThresholdCL: TThresholdCL;
{$ENDIF}
    function GetLayerNeurons(LayerIndx: Integer): TArray<TNeuron>;
    function GetNeuronCount(LayerIndx: Integer): Integer;
    function GetLayerCounts: TArray<Integer>;
    function GetLayerCount: Integer;
    function GetNeuronCountMax: Integer;
    function GetCountInput: Integer;
    function GetCountOutput: Integer;
    function GetNeuronsInput: TArray<TNeuron>;
    function GetNeuronsOutput: TArray<TNeuron>;
    function GetCountHidden: Integer;
    function GetNeuronsHidden: TArray<TNeuron>;
    function GetNeuron(Pos: TPoint): TNeuron;
    function GetOutValues: TArray<Single>;
    function GetOutput: TArray<Single>;
    procedure DropOut(LayerIndx: Integer; Rate: Single);
    procedure DropOutReset;
  public
    procedure Sort;
    procedure CleanAndSort;
    procedure CleanPositions;
    procedure InsertNeurons(N: TArray<TNeuron>);
    procedure DataToNeurons(LayerIndx: Integer; InputData: TArray<Single>);
{$IFDEF USEOPENCL}
    procedure DataToNeuronsCL(LayerIndx: Integer; InputData: TArray<Single>; ThresholdData: TArray<Integer>);
{$ENDIF}
    procedure DefActFunction(LayerIndx: Integer; F: TThresholdType);
    function NeuronOfPos(Pos: TPoint): TNeuron;
    function BetaByNguyenWidrow: Single;
    procedure DroppingOut(DropOutRateOfHiddenLayer: TArray<Single>);
    property Output: TArray<Single> read GetOutput;
    property NeuronsInput: TArray<TNeuron> read GetNeuronsInput;
    property NeuronsOutput: TArray<TNeuron> read GetNeuronsOutput;
    property NeuronsHidden: TArray<TNeuron> read GetNeuronsHidden;
    property OutValues: TArray<Single> read GetOutValues;
    property CountInput: Integer read GetCountInput;
    property CountOutput: Integer read GetCountOutput;
    property CountHidden: Integer read GetCountHidden;
    property LayerNeurons[LayerIndx: Integer]: TArray<TNeuron> read GetLayerNeurons;
    property NeuronCount[LayerIndx: Integer]: Integer read GetNeuronCount;
    property NeuronCountMax: Integer read GetNeuronCountMax;
    property LayerCount: Integer read GetLayerCount;
    property LayerCounts: TArray<Integer> read GetLayerCounts;
    property Neuron[Pos: TPoint]: TNeuron read GetNeuron;
{$IFDEF USEOPENCL}
    property ThresholdCL: TThresholdCL read FThresholdCL write FThresholdCL;
{$ENDIF}
  end;

  TConnection = class
  strict private
    FFromNeuron: TNeuron;
    FToNeuron: TNeuron;
    FWeight: Single;
    FSumGradient: Single;
    // BackPROP
    FMomentum: Single;
    // RPROP
    FGradient: Single;
    FDelta: Single;
    function calcGradient: Single;
    procedure AddWeight_BackPROP(Gradient, Epsilon, MomentumFaktor: Single);
  public
    procedure SumGradient;
    procedure AddWeight_BackPROP_Online(Epsilon, MomentumFaktor: Single);
    procedure AddWeight_BackPROP_Batch(Epsilon, MomentumFaktor: Single);
    procedure AddWeight_RPROP(RPROP: TRPROP);
    procedure Clear;
    procedure Clear_Epoch;
    property FromNeuron: TNeuron read FFromNeuron write FFromNeuron;
    property ToNeuron: TNeuron read FToNeuron write FToNeuron;
    property Weight: Single read FWeight write FWeight;
    // BackPROP
    property Momentum: Single read FMomentum write FMomentum;
  end;

  TConList = class(TObjectList<TConnection>)
  strict private
    function GetNeuron(Pos: TPoint): TNeuron;
    function GetLayerCount: Integer;
    function GetInConsOfNeuron(Pos: TPoint): TArray<TConnection>;
    function GetOutConsOfNeuron(Pos: TPoint): TArray<TConnection>;
    function GetWeightMax: Single;
    function GetWeightMin: Single;
    function GetWeights: TArray<Single>;
    function IsNeuronsPerLayerValid(NeuronsPerLayer: TArray<Integer>): Boolean;
  public
    procedure CreateNetwork(NeuronsPerLayer: TArray<Integer>);
    procedure Reset;
    procedure Clear_Epoch;
    function DeltaOfNeuron(Pos: TPoint): Single;
    function SumValueXWeights(Pos: TPoint): Single;
    function ToNeurons: TArray<TNeuron>;
    function ConsOfNeurons(N1, N2: TNeuron): TConnection;
    function SumSqrWeights(N: TNeuron): Single;
    procedure SumGradient;
    procedure AddWeights_BackPROP_Online(Epsilon, MomentumFaktor: Single);
    procedure AddWeights_BackPROP_Batch(Epsilon, MomentumFaktor: Single);
    procedure AddWeights_RPROP(RPROP: TRPROP);
    procedure RandomWeights(MinWeight, MaxWeight: Single);
    procedure SetWeightsByNguyenWidrow(N: TNeuron; beta: Single);
    procedure CleanSmallWeights(const Epsilon: Single = 0);
    property Weights: TArray<Single> read GetWeights;
    property InConsOfNeuron[Pos: TPoint]: TArray<TConnection> read GetInConsOfNeuron;
    property OutConsOfNeuron[Pos: TPoint]: TArray<TConnection> read GetOutConsOfNeuron;
    // property Neuron[Pos: TPoint]: TNeuron read GetNeuron;
    property LayerCount: Integer read GetLayerCount;
    property WeightMin: Single read GetWeightMin;
    property WeightMax: Single read GetWeightMax;
  end;

  TNeuralNetLoader = class
  strict private
    FNeurons: TNeuronList;
    FConList: TConList;
    procedure SetXML(XML: string);
    function GetXML: string;
  public
    constructor Create(Neurons: TNeuronList; ConList: TConList);
    procedure SaveStructure(Filename: string);
    procedure LoadStructure(Filename: string);
    property XML: string read GetXML write SetXML;
  end;

  TMSEDifference = class
  strict private
    FMSEdifferenceQueue: TQueue<Single>;
    FDifferenceCount: Integer;
    FinternMSEdifferenceCount: Integer;
    FDifference: Single;
    FinternMSEdifference: Single;
    function _MeanAndStdDev: Boolean;
  private
    function GetDifference: Single;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(ExpectedMSE: Single);
    function IsDifference(MSE: Single): Boolean;
    property Difference: Single read GetDifference write FDifference;
    property DifferenceCount: Integer read FDifferenceCount write FDifferenceCount;
  end;

  TRunData = reference to procedure(Const Indx, Count: Integer; var Res: TArray<Single>; var IsBreak: Boolean);

  TNeuralNetRunner = class
  strict private
    FOwnsObjects: Boolean;
    FNeurons: TNeuronList;
    FConList: TConList;
  private
    function GetIsValid: Boolean;
  public
    constructor Create; overload;
    constructor Create(ConList: TConList; Neurons: TNeuronList); overload;
    destructor Destroy; override;
    procedure Run(InputData: TArray<Single>); overload;
    procedure Run(Input: TRunData; OutPut: TProc < Integer, TArray < Single >> ); overload;
    function Output: TArray<Single>;
    procedure LoadStructureFromFile(Filename: string);
    procedure LoadStructureFromXML(XML: string);
    property IsValid: Boolean read GetIsValid;
    property Con: TConList read FConList;
    property Neurons: TNeuronList read FNeurons;
  end;

  TMSEEvent = procedure(Sender: TObject; M: Single; Epoche: Integer; var Stop: Boolean) of object;
  TDataEvent = procedure(Sender: TObject; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>) of object;

  TNeuralNet = class
  strict private
    FLossFunc: TErrorFunc;
    FWeightErrorFunc: TWeightErrorFunc;
    FWeightErrorLambda: Single;
    FNeurons: TNeuronList;
    FConList: TConList;
    FOnMSE: TMSEEvent;
    FOnTrainData: TDataEvent;
    FOnValidData: TDataEvent;
    FOnTestData: TDataEvent;
    FOnCreateStructure: TNotifyEvent;
    FMomentumFaktor: Single;
    FEpsilon: Single;
    FRPROP: TRPROP;
    FLastEpochIndx: Integer;
    FStopType: TStopType;
    FRunner: TNeuralNetRunner;
    FMSEDifference: TMSEDifference;
    FDropOutRateOfHiddenLayer: TArray<Single>;
{$IFDEF USEOPENCL}
    FThresholdCL: TThresholdCL;
{$ENDIF}
    procedure learnRun(InputData: TArray<Single>);
    function GetNeuron(Pos: TPoint): TNeuron;
    function GetConnection(N1, N2: TNeuron): TConnection;
    function MSEcalc(Output: TArray<Single>): Single;
    function MSE(CountData: Integer; DataEvent: TDataEvent): Single;
    procedure DoMSE(MSE: Single; Epoche: Integer; var Stop: Boolean);
    procedure Calc_Delta(Input, Output: TArray<Single>);
    function GetOutputValues: TArray<Single>;
    procedure Train_Basic(CountData: Integer; P: TFunc<Integer, Integer, TStopType>);
    procedure DoData(DataEvent: TDataEvent; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure DoTrainData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure DoTrainDataOut(Indx, OutCount: Integer; var OutData: TArray<Single>);
    procedure DoValidData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    procedure DoTestData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
    function GetInCount: Integer;
    function GetOutCount: Integer;
    procedure DoCreateStructure;
    function GetMSEdifference: Single;
    function GetMSEdifferenceCount: Integer;
    procedure SetMSEdifference(const Value: Single);
    procedure SetMSEdifferenceCount(const Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure CreateNetwork(NeuronsPerLayer: TArray<Integer>);
    procedure Run(InputData: TArray<Single>);
    procedure RandomWeights(MinWeight, MaxWeight: Single);
    procedure RandomWeightsByNguyenWidrow(MinWeight, MaxWeight: Single);
    procedure Train_BackPROP_Online(CountTrainData, CountValidData: Integer; MSE: Single);
    procedure Train_BackPROP_Batch(CountTrainData, CountValidData: Integer; MSE: Single);
    procedure Train_RPROP(CountTrainData, CountValidData: Integer; MSE: Single);
    function ErrorOfTestData(CountTestData: Integer): Single;
    function ErrorOfValidData(CountValidData: Integer): Single;
    function ToNeurons: TArray<TNeuron>;
    function ToConnections: TArray<TConnection>;
    procedure CleanNeurons;
    procedure CleanSmallWeights(const Epsilon: Single = 0);
    procedure DefActFunction(LayerIndx: Integer; F: TThresholdType);
    procedure SaveStructure(Filename: string);
    procedure LoadStructure(Filename: string);
    procedure RemoveConnection(C: TConnection);
    procedure RemoveNeuron(N: TNeuron);
    property InCount: Integer read GetInCount;
    property OutCount: Integer read GetOutCount;
    property MomentumFaktor: Single read FMomentumFaktor write FMomentumFaktor;
    property Epsilon: Single read FEpsilon write FEpsilon;
    property RPROP: TRPROP read FRPROP write FRPROP;
    property Neuron[Pos: TPoint]: TNeuron read GetNeuron;
    property OutputValues: TArray<Single> read GetOutputValues;
    property Connection[N1, N2: TNeuron]: TConnection read GetConnection;
    property Con: TConList read FConList;
    property Neurons: TNeuronList read FNeurons;
    property MSEdifference: Single read GetMSEdifference write SetMSEdifference;
    property MSEdifferenceCount: Integer read GetMSEdifferenceCount write SetMSEdifferenceCount;
    property LastEpochIndx: Integer read FLastEpochIndx;
    property StopType: TStopType read FStopType;
    property OnMSE: TMSEEvent read FOnMSE write FOnMSE;
    property OnTrainData: TDataEvent read FOnTrainData write FOnTrainData;
    property OnValidData: TDataEvent read FOnValidData write FOnValidData;
    property OnTestData: TDataEvent read FOnTestData write FOnTestData;
    property OnCreateStructure: TNotifyEvent read FOnCreateStructure write FOnCreateStructure;
    property LossFunc: TErrorFunc read FLossFunc write FLossFunc;
    property WeightErrorFunc: TWeightErrorFunc read FWeightErrorFunc write FWeightErrorFunc;
    property WeightErrorLambda: Single read FWeightErrorLambda write FWeightErrorLambda;
    property DropOutRateOfHiddenLayer: TArray<Single> read FDropOutRateOfHiddenLayer write FDropOutRateOfHiddenLayer;
  end;

function ThresholdTypeOfNeurons(Neurons: TArray<TNeuron>): TArray<TThresholdType>;

implementation

function ThresholdTypeOfNeurons(Neurons: TArray<TNeuron>): TArray<TThresholdType>;
var
  L: TList<TThresholdType>;
  iNeuron: TNeuron;
begin
  L := TList<TThresholdType>.Create;
  try
    for iNeuron in Neurons do
      L.Add(iNeuron.ActFunc);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

{ TNeuralNet }

constructor TNeuralNet.Create;
begin
  inherited;
  FConList        := TConList.Create;
  FNeurons        := TNeuronList.Create;
  FRunner         := TNeuralNetRunner.Create(FConList, FNeurons);
  FMSEDifference  := TMSEDifference.Create;
  FMomentumFaktor := 0.25;
  FEpsilon        := 0.1;
  FRPROP.SetStandard;
  FLossFunc          := loss_MSE;
  FWeightErrorFunc   := nil;
  FWeightErrorLambda := 0.000001;
  FLastEpochIndx     := 0;

{$IFDEF USEOPENCL}
  FThresholdCL         := TThresholdCL.Create;
  FNeurons.ThresholdCL := FThresholdCL;
{$ENDIF}
end;

destructor TNeuralNet.Destroy;
begin
{$IFDEF USEOPENCL}
  FThresholdCL.Free;
{$ENDIF}
  FMSEDifference.Free;
  FRunner.Free;
  FNeurons.Free;
  FConList.Free;
  inherited;
end;

procedure TNeuralNet.CleanNeurons;
var
  LC, C: Integer;
  Cons: TArray<TConnection>;
  i: Integer;
  iCon: TConnection;
begin
  LC := FNeurons.LayerCount;
  repeat
    C     := FNeurons.Count;
    for i := C - 1 downto 0 do
    begin
      if FNeurons[i].Pos.Y < LC - 1 then
      begin
        Cons := FConList.OutConsOfNeuron[FNeurons[i].Pos];
        if Length(Cons) = 0 then
        begin
          for iCon in FConList.InConsOfNeuron[FNeurons[i].Pos] do
            FConList.Remove(iCOn);
          FNeurons.Delete(i);
          FNeurons.CleanPositions;
        end;
      end;
      if (FNeurons[i].Pos.Y > 0) and not FNeurons[i].IsBias then
      begin
        Cons := FConList.InConsOfNeuron[FNeurons[i].Pos];
        if Length(Cons) = 0 then
        begin
          for iCon in FConList.OutConsOfNeuron[FNeurons[i].Pos] do
            FConList.Remove(iCOn);
          FNeurons.Delete(i);
          FNeurons.CleanPositions;
        end;
      end;
    end;
  until FNeurons.Count = C;
end;

procedure TNeuralNet.CleanSmallWeights(const Epsilon: Single);
begin
  FConList.CleanSmallWeights(Epsilon);
  CleanNeurons;
end;

procedure TNeuralNet.Clear;
begin
  FNeurons.Clear;
  FConList.Clear;
end;

procedure TNeuralNet.DefActFunction(LayerIndx: Integer; F: TThresholdType);
begin
  FNeurons.DefActFunction(LayerIndx, F);
end;

function TNeuralNet.ErrorOfTestData(CountTestData: Integer): Single;
var
  tmp: TWeightErrorFunc;
begin
  tmp := FWeightErrorFunc;
  try
    FWeightErrorFunc := nil;
    Result           := MSE(CountTestData, FOnTestData);
  finally
    FWeightErrorFunc := tmp;
  end;
end;

function TNeuralNet.ErrorOfValidData(CountValidData: Integer): Single;
begin
  Result := MSE(CountValidData, FOnValidData);
end;

procedure TNeuralNet.DoData(DataEvent: TDataEvent; Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  SetLength(InData, InCount);
  SetLength(OutData, OutCount);
  DataEvent(Self, Indx, InCount, OutCount, InData, OutData);
end;

procedure TNeuralNet.DoValidData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  DoData(FOnValidData, Indx, InCount, OutCount, InData, OutData);
end;

procedure TNeuralNet.DoTestData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  DoData(FOnTestData, Indx, InCount, OutCount, InData, OutData);
end;

procedure TNeuralNet.DoTrainData(Indx, InCount, OutCount: Integer; var InData, OutData: TArray<Single>);
begin
  DoData(FOnTrainData, Indx, InCount, OutCount, InData, OutData);
end;

procedure TNeuralNet.DoTrainDataOut(Indx, OutCount: Integer; var OutData: TArray<Single>);
var
  InData: TArray<Single>;
begin
  SetLength(InData, 0);
  SetLength(OutData, OutCount);
  FOnTrainData(Self, Indx, 0, OutCount, InData, OutData);
end;

procedure TNeuralNet.DoMSE(MSE: Single; Epoche: Integer; Var Stop: Boolean);
begin
  Stop := False;
  if Assigned(FOnMSE) then
    FOnMSE(Self, MSE, Epoche, Stop);
end;

function TNeuralNet.GetConnection(N1, N2: TNeuron): TConnection;
begin
  Result := FConList.ConsOfNeurons(N1, N2);
end;

function TNeuralNet.GetInCount: Integer;
begin
  if Neurons.LayerCount > 1 then
    Result := FNeurons.CountInput
  else
    Result := 0;
end;

function TNeuralNet.GetMSEdifference: Single;
begin
  Result := FMSEDifference.Difference;
end;

function TNeuralNet.GetMSEdifferenceCount: Integer;
begin
  Result := FMSEDifference.DifferenceCount;
end;

function TNeuralNet.GetOutCount: Integer;
var
  c: Integer;
begin
  c := Neurons.LayerCount;
  if c > 1 then
    Result := FNeurons.CountOutput
  else
    Result := 0;
end;

function TNeuralNet.GetNeuron(Pos: TPoint): TNeuron;
begin
  Result := FNeurons.Neuron[Pos];
end;

function TNeuralNet.GetOutputValues: TArray<Single>;
begin
  Result := FNeurons.Output;
end;

{$IFDEF USEOPENCL}

procedure TNeuralNet.learnRun(InputData: TArray<Single>);
var
  iNeuron: TNeuron;
  iLayer: Integer;
  DataIn: TArray<Single>;
  DataThreshold: TArray<Integer>;
  NN: TArray<TNeuron>;
  i, c: Integer;
begin
  for iNeuron in FNeurons.LayerNeurons[0] do
    iNeuron.SetValue(InputData[iNeuron.Pos.X]);

  for iLayer := 1 to FConList.LayerCount - 1 do
  begin
    NN := FNeurons.LayerNeurons[iLayer];
    c  := Length(NN);
    SetLength(DataIn, c);
    SetLength(DataThreshold, c);
    for i := 0 to c - 1 do
      if NN[i].IsBias then
      begin
        DataIn[i]        := 0;
        DataThreshold[i] := 1;
      end
      else
      begin
        DataIn[i]        := FConList.SumValueXWeights(NN[i].Pos);
        DataThreshold[i] := Ord(NN[i].ActFunc);
      end;
    FNeurons.DataToNeuronsCL(iLayer, DataIn, DataThreshold);
  end;
end;
{$ELSE}

procedure TNeuralNet.learnRun(InputData: TArray<Single>);
var
  iNeuron: TNeuron;
  iLayer: Integer;
begin
  for iNeuron in FNeurons.LayerNeurons[0] do
    iNeuron.SetValue(InputData[iNeuron.Pos.X]);

  for iLayer := 1 to FNeurons.LayerCount - 1 do
    for iNeuron in FNeurons.LayerNeurons[iLayer] do
      iNeuron.SetValue(FConList.SumValueXWeights(iNeuron.Pos));
end;
{$ENDIF}

function TNeuralNet.MSE(CountData: Integer; DataEvent: TDataEvent): Single;
var
  i, Cin, Cout: Integer;
  _Input, _Output: TArray<Single>;
begin
  if not Assigned(DataEvent) then
    DataEvent := FOnValidData;
  Cin         := FNeurons.CountInput;
  Cout        := FNeurons.CountOutput;

  Result := 0;
  for i  := 0 to CountData - 1 do
  begin
    DoData(DataEvent, i, Cin, Cout, _Input, _Output);
    Run(_Input);
    Result := Result + MSEcalc(_Output);
  end;
  Result := Result / CountData;
end;

function TNeuralNet.MSEcalc(Output: TArray<Single>): Single;
begin
  Result := FLossFunc(FNeurons.OutValues, Output);
  if Assigned(FWeightErrorFunc) then
    Result := Result + FWeightErrorLambda * FWeightErrorFunc(FConList.Weights);
end;

procedure TNeuralNet.RandomWeights(MinWeight, MaxWeight: Single);
begin
  FConList.RandomWeights(MinWeight, MaxWeight);
end;

procedure TNeuralNet.RandomWeightsByNguyenWidrow(MinWeight, MaxWeight: Single);
var
  beta: Single;
  iNeuron: TNeuron;
begin
  FConList.RandomWeights(MinWeight, MaxWeight);
  if FNeurons.CountHidden > 0 then
  begin
    beta := FNeurons.BetaByNguyenWidrow;

    for iNeuron in FNeurons.NeuronsHidden do
      FConList.SetWeightsByNguyenWidrow(iNeuron, beta);
    for iNeuron in FNeurons.NeuronsOutput do
      FConList.SetWeightsByNguyenWidrow(iNeuron, beta);
  end;
end;

procedure TNeuralNet.RemoveConnection(C: TConnection);
begin
  FConList.Remove(C);
  CleanNeurons;
end;

procedure TNeuralNet.RemoveNeuron(N: TNeuron);
begin
  if (N.Pos.Y > 0) and (N.Pos.Y < FNeurons.LayerCount - 1) then
  begin
    FNeurons.Remove(N);
    FNeurons.CleanPositions;
    CleanNeurons;
  end;
end;

procedure TNeuralNet.DoCreateStructure;
begin
  if Assigned(FOnCreateStructure) then
    FOnCreateStructure(Self);
end;

procedure TNeuralNet.Run(InputData: TArray<Single>);
begin
  FRunner.Run(InputData);
end;

procedure TNeuralNet.SaveStructure(Filename: string);
var
  Loader: TNeuralNetLoader;
begin
  Loader := TNeuralNetLoader.Create(FNeurons, FConList);
  try
    Loader.SaveStructure(Filename);
  finally
    Loader.Free;
  end;
end;

procedure TNeuralNet.SetMSEdifference(const Value: Single);
begin
  FMSEDifference.Difference := Value;
end;

procedure TNeuralNet.SetMSEdifferenceCount(const Value: Integer);
begin
  FMSEDifference.DifferenceCount := Value;
end;

procedure TNeuralNet.LoadStructure(Filename: string);
var
  Loader: TNeuralNetLoader;
begin
  Loader := TNeuralNetLoader.Create(FNeurons, FConList);
  try
    Loader.LoadStructure(Filename);
  finally
    Loader.Free;
  end;
  DoCreateStructure;
end;

function TNeuralNet.ToConnections: TArray<TConnection>;
begin
  Result := FConList.ToArray;
end;

procedure TNeuralNet.Calc_Delta(Input, Output: TArray<Single>);
var
  c: Integer;
  iLayer: Integer;
  iNeuron: TNeuron;
begin
  learnRun(Input);
  c := FConList.LayerCount;

  iLayer := c - 1;
  for iNeuron in FNeurons.LayerNeurons[iLayer] do
    iNeuron.Delta := iNeuron.DeriveValue * (Output[iNeuron.Pos.X] - iNeuron.OutValue);

  for iLayer := c - 2 downto 1 do
    for iNeuron in FNeurons.LayerNeurons[iLayer] do
      iNeuron.Delta := iNeuron.DeriveValue * FConList.DeltaOfNeuron(iNeuron.Pos);
end;

function TNeuralNet.ToNeurons: TArray<TNeuron>;
begin
  Result := FNeurons.ToArray;
end;

procedure TNeuralNet.Train_Basic(CountData: Integer; P: TFunc<Integer, Integer, TStopType>);
var
  Cin, Cout: Integer;
  _Input, _Output: TArray<Single>;
  i, epochIndx: Integer;
  Stop: TStopType;
begin
  Cin  := FNeurons.CountInput;
  Cout := FNeurons.CountOutput;
  FConList.Reset;

  epochIndx := 0;
  Stop      := stopNo;
  repeat
    FConList.Clear_Epoch;
    FNeurons.DroppingOut(FDropOutRateOfHiddenLayer);

    i := 0;
    repeat
      DoTrainData(i, Cin, Cout, _Input, _Output);
      Calc_Delta(_Input, _Output);
      Stop := P(i, epochIndx);
      Inc(i);
    until (Stop <> stopNo) or (i > CountData - 1);

    Inc(epochIndx);

  until (Stop <> stopNo);

  FStopType      := Stop;
  FLastEpochIndx := epochIndx - 1;
end;

procedure TNeuralNet.Train_BackPROP_Batch(CountTrainData, CountValidData: Integer; MSE: Single);
begin
  FMSEDifference.Start(MSE);
  Train_Basic(CountTrainData,
    function(Indx, EpochIndx: Integer): TStopType
    var
      epochMSE: Single;
      IsUserStop: Boolean;
    begin
      FConList.SumGradient;
      if (Indx mod (CountTrainData - 1) = 0) and (Indx > 0) then
      begin
        FConList.AddWeights_BackPROP_Batch(FEpsilon, FMomentumFaktor);
        epochMSE := Self.MSE(CountValidData, FOnValidData);
        DoMSE(epochMSE, EpochIndx, IsUserStop);
        if IsUserStop then
          Result := stopUserBreak
        else if Abs(epochMSE) < MSE then
          Result := stopErrorAccomplished
        else if FMSEDifference.IsDifference(epochMSE) then
          Result := stopNoErrorDifference
        else
          Result := stopNo;
      end
      else
        Result := stopNo;
    end);
end;

procedure TNeuralNet.Train_BackPROP_Online(CountTrainData, CountValidData: Integer; MSE: Single);
var
  epochMSE: Single;
  Cout: Integer;
begin
  Cout := FNeurons.CountOutput;

  FMSEDifference.Start(MSE);
  epochMSE := 0;
  Train_Basic(CountTrainData,
    function(Indx, EpochIndx: Integer): TStopType
    var
      _Output: TArray<Single>;
      IsUserStop: Boolean;
    begin
      FConList.AddWeights_BackPROP_Online(FEpsilon, FMomentumFaktor);
      DoTrainDataOut(Indx, Cout, _Output);
      epochMSE := epochMSE + MSEcalc(_Output);

      if (Indx mod (CountTrainData - 1) = 0) and (Indx > 0) then
      begin
        epochMSE := epochMSE / CountTrainData;
        DoMSE(epochMSE, EpochIndx, IsUserStop);
        if IsUserStop then
          Result := stopUserBreak
        else if Abs(epochMSE) < MSE then
          Result := stopErrorAccomplished
        else if FMSEDifference.IsDifference(epochMSE) then
          Result := stopNoErrorDifference
        else
          Result := stopNo;
      end
      else
        Result := stopNo;
    end);
end;

procedure TNeuralNet.Train_RPROP(CountTrainData, CountValidData: Integer; MSE: Single);
begin
  FMSEDifference.Start(MSE);
  Train_Basic(CountTrainData,
    function(Indx, EpochIndx: Integer): TStopType
    var
      epochMSE: Single;
      IsUserStop: Boolean;
    begin
      FConList.SumGradient;
      if (Indx mod (CountTrainData - 1) = 0) and (Indx > 0) then
      begin
        FConList.AddWeights_RPROP(FRPROP);
        epochMSE := Self.MSE(CountValidData, FOnValidData);
        DoMSE(epochMSE, EpochIndx, IsUserStop);
        if IsUserStop then
          Result := stopUserBreak
        else if Abs(epochMSE) < MSE then
          Result := stopErrorAccomplished
        else if FMSEDifference.IsDifference(epochMSE) then
          Result := stopNoErrorDifference
        else
          Result := stopNo;
      end
      else
        Result := stopNo;
    end);
end;

procedure TNeuralNet.CreateNetwork(NeuronsPerLayer: TArray<Integer>);
begin
  FConList.CreateNetwork(NeuronsPerLayer);
  FNeurons.InsertNeurons(FConList.ToNeurons);
  DoCreateStructure;
end;

{ TConList }

procedure TConList.AddWeights_BackPROP_Batch(Epsilon, MomentumFaktor: Single);
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.AddWeight_BackPROP_Batch(Epsilon, MomentumFaktor);
end;

procedure TConList.AddWeights_BackPROP_Online(Epsilon, MomentumFaktor: Single);
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.AddWeight_BackPROP_Online(Epsilon, MomentumFaktor);
end;

procedure TConList.SetWeightsByNguyenWidrow(N: TNeuron; beta: Single);
var
  iCon: TConnection;
  EuclideanNorm: Single;
begin
  EuclideanNorm := Sqrt(SumSqrWeights(N));
  for iCon in GetInConsOfNeuron(N.Pos) do
    iCon.Weight := (beta * iCon.Weight) / EuclideanNorm;
end;

procedure TConList.SumGradient;
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.SumGradient;
end;

function TConList.SumSqrWeights(N: TNeuron): Single;
var
  iCon: TConnection;
begin
  Result := 0;
  for iCon in GetInConsOfNeuron(N.Pos) do
    Result := Result + iCon.Weight * iCon.Weight;
end;

procedure TConList.AddWeights_RPROP(RPROP: TRPROP);
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.AddWeight_RPROP(RPROP);
end;

procedure TConList.Reset;
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.Clear;
end;

procedure TConList.CleanSmallWeights(const Epsilon: Single);
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if IsZero(Self[i].Weight, Epsilon) then
      Delete(i);
end;

procedure TConList.Clear_Epoch;
var
  iCon: TConnection;
begin
  for iCon in Self do
    iCon.Clear_Epoch;
end;

function TConList.ConsOfNeurons(N1, N2: TNeuron): TConnection;
var
  iCon: TConnection;
begin
  for iCon in Self do
    if (iCon.FromNeuron = N1) and (iCon.ToNeuron = N2) or (iCon.FromNeuron = N2) and (iCon.ToNeuron = N1) then
      Exit(iCon);
  Result := nil;
end;

procedure TConList.CreateNetwork(NeuronsPerLayer: TArray<Integer>);
var
  i, ii: Integer;
  iLayer: Integer;
  con: TConnection;
  iNeuron: TNeuron;
begin
  Clear;
  if IsNeuronsPerLayerValid(NeuronsPerLayer) then
  begin
    for iLayer := 0 to Length(NeuronsPerLayer) - 2 do
    begin
      for i := 0 to NeuronsPerLayer[iLayer] do
      begin
        if (i = NeuronsPerLayer[iLayer]) then
          iNeuron := TNeuron.Create(iLayer, i, True)
        else if (iLayer = 0) then
          iNeuron := TNeuron.Create(iLayer, i)
        else
          iNeuron := GetNeuron(TPoint.Create(i, iLayer));

        for ii := 0 to NeuronsPerLayer[iLayer + 1] - 1 do
        begin
          con            := TConnection.Create;
          con.FromNeuron := iNeuron;

          if i = 0 then
            con.ToNeuron := TNeuron.Create(iLayer + 1, ii)
          else
            con.ToNeuron := GetNeuron(TPoint.Create(ii, iLayer + 1));
          Add(Con);
        end;
      end;
    end;
  end;
end;

function TConList.DeltaOfNeuron(Pos: TPoint): Single;
var
  Cons: TArray<TConnection>;
  iCon: TConnection;
begin
  Cons   := OutConsOfNeuron[Pos];
  Result := 0;
  for iCon in Cons do
    Result := Result + iCon.ToNeuron.Delta * iCon.Weight;
end;

function TConList.GetInConsOfNeuron(Pos: TPoint): TArray<TConnection>;
var
  L: TList<TConnection>;
  iCon: TConnection;
begin
  L := TList<TConnection>.Create;
  try
    for iCon in Self do
      if (iCon.ToNeuron.Pos = Pos) then
        L.Add(iCon);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TConList.GetOutConsOfNeuron(Pos: TPoint): TArray<TConnection>;
var
  L: TList<TConnection>;
  iCon: TConnection;
begin
  L := TList<TConnection>.Create;
  try
    for iCon in Self do
      if (iCon.FromNeuron.Pos = Pos) then
        L.Add(iCon);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TConList.GetLayerCount: Integer;
var
  iCon: TConnection;
begin
  Result := -1;
  for iCon in Self do
    Result := Max(iCon.ToNeuron.LayerIndx, Result);
  Result   := Result + 1;
end;

function TConList.GetNeuron(Pos: TPoint): TNeuron;
var
  iCon: TConnection;
begin
  for iCon in Self do
  begin
    if Assigned(iCon.FromNeuron) and (iCon.FromNeuron.Pos = Pos) then
      Exit(iCon.FromNeuron);
    if Assigned(iCon.ToNeuron) and (iCon.ToNeuron.Pos = Pos) then
      Exit(iCon.ToNeuron);
  end;
  Result := nil;
end;

function TConList.GetWeightMax: Single;
var
  iCon: TConnection;
begin
  Result := NegInfinity;
  for iCon in Self do
    Result := Max(Result, iCon.Weight);
end;

function TConList.GetWeightMin: Single;
var
  iCon: TConnection;
begin
  Result := Infinity;
  for iCon in Self do
    Result := Min(Result, iCon.Weight);
end;

function TConList.GetWeights: TArray<Single>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i       := 0 to Count - 1 do
    Result[i] := Self[i].Weight;
end;

function TConList.IsNeuronsPerLayerValid(NeuronsPerLayer: TArray<Integer>): Boolean;
var
  i: Integer;
begin
  if Length(NeuronsPerLayer) = 0 then
    Exit(False);

  for i := 0 to Length(NeuronsPerLayer) - 1 do
    if NeuronsPerLayer[i] = 0 then
      Exit(False);
  Result := True;
end;

procedure TConList.RandomWeights(MinWeight, MaxWeight: Single);
var
  iCon: TConnection;
  W: Single;
begin
  if MaxWeight - 1E-3 > MinWeight then
  begin
    for iCon in Self do
    begin
      repeat
        W := RandomRangeF(MinWeight, MaxWeight);
      until not IsZero(W, 0.01);
      iCon.Weight := W;
    end;
  end;
end;

function TConList.SumValueXWeights(Pos: TPoint): Single;
var
  Cons: TArray<TConnection>;
  iCon: TConnection;
begin
  Cons   := InConsOfNeuron[Pos];
  Result := 0;

  for iCon in Cons do
    Result := Result + iCon.FromNeuron.OutValue * iCon.Weight;
end;

function TConList.ToNeurons: TArray<TNeuron>;
var
  NL: TNeuronList;
  iCon: TConnection;
begin
  NL := TNeuronList.Create(False);
  try
    for iCon in Self do
    begin
      NL.Add(iCon.FromNeuron);
      NL.Add(iCon.ToNeuron);
    end;
    NL.CleanAndSort;
    Result := NL.ToArray;
  finally
    NL.Free;
  end;
end;

{ TNeuron }

constructor TNeuron.Create(Num_Layer, Num_Neuron: Integer; IsBias: Boolean);
begin
  inherited Create;
  FActFunc := funcLINEAR;
  FPos.Create(Num_Neuron, Num_Layer);
  FActSteepness := 1;
  FIsBias       := IsBias;
  FDelta        := 0;
  if FIsBias then
  begin
    FInValue  := 1;
    FOutValue := 1;
  end
  else
  begin
    FInValue  := 0;
    FOutValue := 0;
  end;
  FIsDropOut := False;
end;

function TNeuron.GetOutValue: Single;
begin
  if FIsBias then
    Result := 1
  else
    Result := FActFunc.ToFunction.Invoke(FInValue);
end;

procedure TNeuron.NewPosX(const X: Integer);
begin
  FPos.X := X;
end;

function TNeuron.GetDelta: Single;
begin
  Result := IfThen(FIsDropOut, 0, FDelta);
end;

function TNeuron.GetLayerIndx: Integer;
begin
  Result := FPos.Y
end;

procedure TNeuron.SetInValue(const Value: Single);
begin
  FInValue  := Value;
  FOutValue := GetOutValue;
end;

{$IFDEF USEOPENCL}

procedure TNeuron.SetValue(const InValue, OutValue, DeriveValue: Single);
begin
  FInValue := InValue;

  if FIsBias then
  begin
    FOutValue    := 1;
    FDeriveValue := 1;
  end
  else
  begin
    FOutValue    := OutValue;
    FDeriveValue := DeriveValue;
  end;
end;
{$ENDIF}

procedure TNeuron.SetValue(const InValue: Single);
begin
  FInValue := InValue;

  if FIsBias then
  begin
    FOutValue    := 1;
    FDeriveValue := 1;
  end
  else
  begin
    FOutValue    := GetOutValue;
    FDeriveValue := FActFunc.ToDeriveFunction.Invoke(FOutValue, FInValue);
  end;
end;

{ TNeuronList }

procedure TNeuronList.DataToNeurons(LayerIndx: Integer; InputData: TArray<Single>);
var
  iNeuron: TNeuron;
begin
  for iNeuron in GetLayerNeurons(LayerIndx) do
    if not iNeuron.IsBias then
      iNeuron.InValue := InputData[iNeuron.Pos.X];
end;
{$IFDEF USEOPENCL}

procedure TNeuronList.DataToNeuronsCL(LayerIndx: Integer; InputData: TArray<Single>; ThresholdData: TArray<Integer>);
var
  iNeuron: TNeuron;
  OutData: TArray<Single>;
  DeriveData: TArray<Single>;
begin
  OutData    := FThresholdCL.Run_threshold(InputData, ThresholdData);
  DeriveData := FThresholdCL.Run_thresholdDerive(InputData, OutData, ThresholdData);
  for iNeuron in GetLayerNeurons(LayerIndx) do
    iNeuron.SetValue(InputData[iNeuron.Pos.X], OutData[iNeuron.Pos.X], DeriveData[iNeuron.Pos.X]);
end;
{$ENDIF}

procedure TNeuronList.DefActFunction(LayerIndx: Integer; F: TThresholdType);
var
  iNeuron: TNeuron;
begin
  for iNeuron in GetLayerNeurons(LayerIndx) do
    iNeuron.ActFunc := F;
end;

procedure TNeuronList.DroppingOut(DropOutRateOfHiddenLayer: TArray<Single>);
var
  i, C: Integer;
begin
  DropOutReset;
  C     := GetLayerCount;
  for i := 0 to Length(DropOutRateOfHiddenLayer) - 1 do
    if i + 1 < C then
      DropOut(i + 1, DropOutRateOfHiddenLayer[i]);
end;

procedure TNeuronList.DropOut(LayerIndx: Integer; Rate: Single);
var
  NN: TArray<TNeuron>;
  DropNeurons: TArray<Integer>;
  i: Integer;
begin
  NN                             := GetLayerNeurons(LayerIndx);
  DropNeurons                    := RandomUniqueIntegerList(Length(NN) - 1, Rate);
  for i                          := 0 to Length(DropNeurons) - 1 do
    NN[DropNeurons[i]].IsDropOut := True;
end;

procedure TNeuronList.DropOutReset;
var
  iNeuron: TNeuron;
begin
  for iNeuron in Self do
    iNeuron.IsDropOut := False;
end;

function TNeuronList.BetaByNguyenWidrow: Single;
var
  H, N: Integer;
begin
  H      := CountHidden;
  N      := CountInput;
  Result := Power(0.7 * H, 1 / N);
end;

procedure TNeuronList.CleanAndSort;
var
  i: Integer;
  tmp: Boolean;
begin
  Sort;
  tmp         := OwnsObjects;
  OwnsObjects := False;
  try
    for i := Count - 2 downto 0 do
    begin
      if Self[i] = Self[i + 1] then
        Delete(i + 1);
    end;
  finally
    OwnsObjects := tmp;
  end;
end;

procedure TNeuronList.CleanPositions;
var
  iNeuron: TNeuron;
  iLayer, Pos: Integer;
begin
  iLayer := -1;
  Pos    := -1;
  for iNeuron in Self do
  begin
    if iLayer <> iNeuron.Pos.Y then
    begin
      iLayer := iNeuron.Pos.Y;
      iNeuron.NewPosX(0);
      Pos := 0;
    end
    else
    begin
      Inc(Pos);
      iNeuron.NewPosX(Pos);
    end;
  end;
end;

function TNeuronList.GetCountHidden: Integer;
var
  iNeuron: TNeuron;
  c: Integer;
begin
  c      := GetLayerCount;
  Result := 0;
  for iNeuron in Self do
    if not iNeuron.IsBias and (iNeuron.Pos.Y <> 0) and (iNeuron.Pos.Y <> c - 1) then
      Inc(Result);
end;

function TNeuronList.GetCountInput: Integer;
var
  iNeuron: TNeuron;
begin
  Result := 0;
  for iNeuron in Self do
    if not iNeuron.IsBias and (iNeuron.LayerIndx = 0) then
      Inc(Result);
end;

function TNeuronList.GetCountOutput: Integer;
begin
  Result := GetNeuronCount(GetLayerCount - 1);
end;

function TNeuronList.GetLayerCount: Integer;
var
  iNeuron: TNeuron;
begin
  Result := 0;
  for iNeuron in Self do
    Result := Max(Result, iNeuron.LayerIndx + 1);
end;

function TNeuronList.GetLayerCounts: TArray<Integer>;
var
  i, c: Integer;
  iNeuron: TNeuron;
begin
  c := GetLayerCount;
  SetLength(Result, c);
  for i := 0 to c - 1 do
  begin
    Result[i] := 0;
    for iNeuron in Self do
      if iNeuron.LayerIndx = i then
        Result[i] := Result[i] + 1;
  end;
end;

function TNeuronList.GetLayerNeurons(LayerIndx: Integer): TArray<TNeuron>;
var
  L: TList<TNeuron>;
  iNeuron: TNeuron;
begin
  L := TList<TNeuron>.Create;
  try
    for iNeuron in Self do
      if iNeuron.LayerIndx = LayerIndx then
        L.Add(iNeuron);
    L.Sort(TComparer<TNeuron>.Construct(
      function(const L, R: TNeuron): Integer
      begin
        Result := CompareValue(L.Pos.X, R.Pos.X);
      end));

    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TNeuronList.GetNeuron(Pos: TPoint): TNeuron;
var
  iNeuron: TNeuron;
begin
  for iNeuron in Self do
    if iNeuron.Pos = Pos then
      Exit(iNeuron);
  Result := nil;
end;

function TNeuronList.GetNeuronCount(LayerIndx: Integer): Integer;
var
  iNeuron: TNeuron;
begin
  Result := 0;
  for iNeuron in Self do
    if iNeuron.LayerIndx = LayerIndx then
      Result := Result + 1;
end;

function TNeuronList.GetNeuronCountMax: Integer;
var
  i: Integer;
begin
  Result   := 0;
  for i    := 0 to GetLayerCount - 1 do
    Result := Max(GetNeuronCount(i), Result);
end;

function TNeuronList.GetNeuronsHidden: TArray<TNeuron>;
var
  L: TList<TNeuron>;
  iNeuron: TNeuron;
  c: Integer;
begin
  c := GetLayerCount;
  L := TList<TNeuron>.Create;
  try
    for iNeuron in Self do
      if InRange(iNeuron.Pos.Y, 1, c - 1) then
        L.Add(iNeuron);

    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function TNeuronList.GetNeuronsInput: TArray<TNeuron>;
begin
  Result := LayerNeurons[0];
end;

function TNeuronList.GetNeuronsOutput: TArray<TNeuron>;
begin
  Result := LayerNeurons[GetLayerCount - 1];
end;

function TNeuronList.GetOutput: TArray<Single>;
var
  R: TArray<TNeuron>;
  i, c: Integer;
begin
  R := GetNeuronsOutput;
  c := Length(R);
  SetLength(Result, c);
  for i       := 0 to c - 1 do
    Result[i] := R[i].OutValue;
end;

function TNeuronList.GetOutValues: TArray<Single>;
var
  N: TArray<TNeuron>;
  i: Integer;
begin
  N := GetNeuronsOutput;
  SetLength(Result, Length(N));
  for i       := 0 to Length(N) - 1 do
    Result[i] := N[i].OutValue;
end;

procedure TNeuronList.InsertNeurons(N: TArray<TNeuron>);
begin
  Clear;
  AddRange(N);
end;

function TNeuronList.NeuronOfPos(Pos: TPoint): TNeuron;
var
  iNeuron: TNeuron;
begin
  for iNeuron in Self do
    if iNeuron.Pos = Pos then
      Exit(iNeuron);
  Result := nil;
end;

procedure TNeuronList.Sort;
begin
  inherited Sort(TComparer<TNeuron>.Construct(
    function(const L, R: TNeuron): Integer
    begin
      Result := CompareValue(L.LayerIndx, R.LayerIndx);
      if Result = 0 then
        Result := CompareValue(L.Pos.X, R.Pos.X);
    end));
end;

{ TConnection }

procedure TConnection.AddWeight_BackPROP(Gradient, Epsilon, MomentumFaktor: Single);
var
  d: Single;
begin
  d := Epsilon * Gradient;
  if MomentumFaktor > 0 then
  begin
    FMomentum := (FMomentum + d) * MomentumFaktor;
    FWeight   := FWeight + FMomentum;
  end
  else
    FWeight := FWeight + d;

  FWeight   := EnsureRange(FWeight, -1500, 1500);
  FMomentum := EnsureRange(FMomentum, -1500, 1500);
end;

procedure TConnection.AddWeight_BackPROP_Batch(Epsilon, MomentumFaktor: Single);
begin
  AddWeight_BackPROP(FSumGradient, Epsilon, MomentumFaktor);
end;

procedure TConnection.AddWeight_BackPROP_Online(Epsilon, MomentumFaktor: Single);
begin
  AddWeight_BackPROP(calcGradient, Epsilon, MomentumFaktor);
end;

procedure TConnection.AddWeight_RPROP(RPROP: TRPROP);
var
  S: TValueSign;
begin
  FDelta := Max(FDelta, cDeltaMinimum);
  S      := _Sign(FSumGradient * FGradient, 1E-6);

  if S = PositiveValue then
  begin
    FDelta := Min(FDelta * RPROP.DeltaUp, RPROP.DeltaMax);
  end
  else if S = NegativeValue then
  begin
    FDelta := Max(FDelta * RPROP.DeltaDown, RPROP.DeltaMin);
    // FSumGradient := 0;
  end;

  S       := _Sign(FSumGradient, 1E-6);
  FWeight := FWeight + S * Min(FDelta, 1500);
  FWeight := EnsureRange(FWeight, -1500, 1500);

  FGradient := FSumGradient;
end;

procedure TConnection.Clear;
begin
  FSumGradient := 0;
  FMomentum    := 0;
  // RPROP
  FGradient := 0;
  FDelta    := 0;
end;

procedure TConnection.Clear_Epoch;
begin
  FSumGradient := 0;
  FMomentum    := 0;
end;

procedure TConnection.SumGradient;
begin
  FSumGradient := FSumGradient + calcGradient;
end;

function TConnection.CalcGradient: Single;
begin
  Result := FFromNeuron.OutValue * FToNeuron.Delta
end;

{ TNeuralNetRunner }

constructor TNeuralNetRunner.Create;
begin
  inherited;
  FOwnsObjects := True;
  FNeurons     := TNeuronList.Create;
  FConList     := TConList.Create;

end;

constructor TNeuralNetRunner.Create(ConList: TConList; Neurons: TNeuronList);
begin
  FOwnsObjects := False;
  FNeurons     := Neurons;
  FConList     := ConList;
end;

destructor TNeuralNetRunner.Destroy;
begin
  if FOwnsObjects then
  begin
    FNeurons.Free;
    FConList.Free;
  end;
  inherited;
end;

function TNeuralNetRunner.GetIsValid: Boolean;
begin
  Result := Assigned(FNeurons) and Assigned(FConList) and (FNeurons.CountInput > 0) and (FNeurons.CountOutput > 0);
end;

procedure TNeuralNetRunner.LoadStructureFromFile(Filename: string);
var
  Loader: TNeuralNetLoader;
begin
  Loader := TNeuralNetLoader.Create(FNeurons, FConList);
  try
    Loader.LoadStructure(Filename);
  finally
    Loader.Free;
  end;
end;

procedure TNeuralNetRunner.LoadStructureFromXML(XML: string);
var
  Loader: TNeuralNetLoader;
begin
  Loader := TNeuralNetLoader.Create(FNeurons, FConList);
  try
    Loader.XML := XML;
  finally
    Loader.Free;
  end;
end;

function TNeuralNetRunner.Output: TArray<Single>;
begin
  Result := FNeurons.Output;
end;

procedure TNeuralNetRunner.Run(Input: TRunData; OutPut: TProc < Integer, TArray < Single >> );
var
  IsBreak: Boolean;
  Data: TArray<Single>;
  i, C: Integer;
begin
  c := FNeurons.CountInput;
  i := 0;
  repeat
    IsBreak := False;
    SetLength(Data, 0);
    Input(i, c, Data, IsBreak);
    if not IsBreak then
    begin
      Run(Data);
      OutPut(i, FNeurons.Output);
      Inc(i)
    end;
  until IsBreak;
end;

procedure TNeuralNetRunner.Run(InputData: TArray<Single>);
var
  iNeuron: TNeuron;
  iLayer: Integer;
begin
  FNeurons.DataToNeurons(0, InputData);
  for iLayer := 1 to FConList.LayerCount - 1 do
    for iNeuron in FNeurons.LayerNeurons[iLayer] do
      iNeuron.InValue := FConList.SumValueXWeights(iNeuron.Pos);
end;

{ TPointHelper }

procedure TPointHelper.FromText(S: string);
var
  SS: TArray<string>;
begin
  SS := S.Split([',']);
  if Length(SS) = 2 then
  begin
    Self.X := SS[0].Trim.ToInteger;
    Self.Y := SS[1].Trim.ToInteger;
  end
  else
    raise Exception.Create('Error: TPointHelper.FromText');
end;

function TPointHelper.ToText: string;
begin
  Result := Self.X.ToString + ',' + Self.Y.ToString;
end;

{ TRPROP }

procedure TRPROP.SetStandard;
begin
  FDeltaMax  := 50;
  FDeltaMin  := 0;
  FDeltaDown := 0.5;
  FDeltaUp   := 1.2;
end;

{ TNeuralNetLoader }

constructor TNeuralNetLoader.Create(Neurons: TNeuronList; ConList: TConList);
begin
  inherited Create;
  FNeurons := Neurons;
  FConList := ConList;
end;

procedure TNeuralNetLoader.SetXML(XML: string);
var
  XMLdoc: IXMLDocument;
  Elements, iElement, E: IXMLNode;
  iNeuron: TNeuron;
  iCon: TConnection;
  Pos: TPoint;
  Bias: Boolean;
  s: string;
  i: Integer;
  w: Single;

  function ToFloat(Txt: string): Single;
  begin
    if not TryStrToFloat(StringReplace(Txt, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]), Result) then
      Result := StrToFloat(StringReplace(Txt, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]));
  end;

begin
  XMLdoc := TXMLDocument.Create(nil);
  XMLdoc.LoadFromXML(XML);

  Elements := XMLdoc.ChildNodes.FindNode('NeuralNetworkStructure');
  if Assigned(Elements) then
  begin
    FNeurons.Clear;
    FConList.Clear;

    iElement := Elements.ChildNodes.FindNode('Neurons');
    for i    := 0 to iElement.ChildNodes.Count - 1 do
    begin
      E := iElement.ChildNodes[i];
      Pos.FromText(E.Text);
      Bias            := E.Attributes['bias'];
      iNeuron         := TNeuron.Create(Pos.Y, Pos.X, Bias);
      s               := E.Attributes['threshold'];
      iNeuron.ActFunc := TThresholdType.Create(s);
      FNeurons.Add(iNeuron);
    end;
    FNeurons.CleanAndSort;

    iElement := Elements.ChildNodes.FindNode('Connections');
    for i    := 0 to iElement.ChildNodes.Count - 1 do
    begin
      E    := iElement.ChildNodes[i];
      iCon := TConnection.Create;
      Pos.FromText(E.ChildNodes.FindNode('FromNeuron').Text);
      iCon.FromNeuron := FNeurons.NeuronOfPos(Pos);
      Pos.FromText(E.ChildNodes.FindNode('ToNeuron').Text);
      iCon.ToNeuron := FNeurons.NeuronOfPos(Pos);
      w             := ToFloat(E.ChildNodes.FindNode('Weight').Text);
      iCon.Weight   := w;
      FConList.Add(iCon);
    end;
  end;
end;

procedure TNeuralNetLoader.LoadStructure(Filename: string);
var
  sl: TStringlist;
begin
  sl := TStringList.Create;
  try
    sl.LoadFromFile(Filename);
    SetXML(sl.Text);
  finally
    sl.Free;
  end;
end;

procedure TNeuralNetLoader.SaveStructure(Filename: string);
var
  sl: TStringlist;
begin
  sl := TStringList.Create;
  try
    sl.Text := GetXML;
    sl.SaveToFile(Filename);
  finally
    sl.Free;
  end;
end;

function TNeuralNetLoader.GetXML: string;
var
  XML: IXMLDocument;
  Elements, iElement, E: IXMLNode;
  iNeuron: TNeuron;
  iCon: TConnection;
begin
  XML        := TXMLDocument.Create(nil);
  XML.Active := True;

  XML.DocumentElement := XML.CreateNode('NeuralNetworkStructure', ntElement, '');
  Elements            := XML.DocumentElement.AddChild('Neurons');
  for iNeuron in FNeurons do
  begin
    iElement                         := Elements.AddChild('Neuron');
    iElement.Attributes['threshold'] := iNeuron.ActFunc.ToName;
    iElement.Attributes['bias']      := iNeuron.IsBias;
    iElement.Text                    := iNeuron.Pos.ToText;
  end;

  Elements := XML.DocumentElement.AddChild('Connections');
  for iCon in FConList do
  begin
    iElement := Elements.AddChild('Connection');
    E        := iElement.AddChild('FromNeuron');
    E.Text   := iCon.FromNeuron.Pos.ToText;
    E        := iElement.AddChild('ToNeuron');
    E.Text   := iCon.ToNeuron.Pos.ToText;
    E        := iElement.AddChild('Weight');
    E.Text   := iCon.Weight.ToString;
  end;
  XML.SaveToXML(Result);
  Result := FormatXMLData(Result);
end;

{ TStopTypeHelper }

function TStopTypeHelper.ToText: string;
begin
  case Self of
    stopNo:
      Result := 'No Break';
    stopUserBreak:
      Result := 'UserBreak';
    stopErrorAccomplished:
      Result := 'Error Accomplished';
    stopNoErrorDifference:
      Result := 'No Error Difference';
  else
    raise Exception.Create('Fehler: TStopTypeHelper.ToText');
  end;
end;

{ TMSEDifference }

constructor TMSEDifference.Create;
begin
  inherited;
  FMSEdifferenceQueue := TQueue<Single>.Create;
  FDifferenceCount    := 25;
end;

destructor TMSEDifference.Destroy;
begin
  FMSEdifferenceQueue.Free;
  inherited;
end;

function TMSEDifference.GetDifference: Single;
begin
  Result := Max(FDifference, 1E-15);
end;

function TMSEDifference._MeanAndStdDev: Boolean;
var
  _Mean, _StdDev: Single;
begin
  MeanAndStdDev(FMSEdifferenceQueue.ToArray, _Mean, _StdDev);
  Result := _StdDev < FinternMSEdifference;
end;

function TMSEDifference.IsDifference(MSE: Single): Boolean;
begin
  FMSEdifferenceQueue.Enqueue(MSE);
  Result := FinternMSEdifferenceCount > 1;
  if Result then
  begin
    Result := FMSEdifferenceQueue.Count > FinternMSEdifferenceCount;
    if Result then
    begin
      FMSEdifferenceQueue.Dequeue;
      Result := _MeanAndStdDev;
    end;
  end;
end;

procedure TMSEDifference.Start(ExpectedMSE: Single);
begin
  FinternMSEdifference      := GetDifference;
  FinternMSEdifferenceCount := Max(FinternMSEdifferenceCount, 1);
  FMSEdifferenceQueue.Clear;
end;

end.
