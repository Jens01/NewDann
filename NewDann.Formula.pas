// NewDann - Project
// Author : Jens Biermann, Linsburg
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
unit NewDann.Formula;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections;

type
  TThresholdType = (funcLINEAR, funcSIGMOID, funcGAUSSIAN, funcBinaryStep, functanH, funcArcTan, funcArcSinH, funcELLIOT, funcSIN,
    funcCOS, funcRELU, funcLEAKY_RELU, funcSoftPlus);

  TthresholdFunc = reference to function(const InputValue: Single): Single;
  TthresholdDeriveFunc = reference to function(const OutputValue, InputValue: Single): Single;

  ThresholdTypeHelper = record helper for TThresholdType
  private
    function NameToType(Name: string): TThresholdType;
  public
    constructor Create(Name: string);
    function ToFunction: TthresholdFunc;
    function ToDeriveFunction: TthresholdDeriveFunc;
    function ToName: string;
    class function ToArrayStr: TArray<string>; static;
  end;

function SameThresholdType(ThresholdTypeArray: TArray<TThresholdType>; var ThresholdType: TThresholdType): Boolean;

// https://en.wikipedia.org/wiki/Activation_function#ref_heaviside
function threshold_Linear(const InputValue: Single): Single; inline;
function threshold_Sigmoid(const InputValue: Single): Single; inline;
function threshold_tanH(const InputValue: Single): Single; inline;
function threshold_ArcTan(const InputValue: Single): Single; inline;
function threshold_ArcSinH(const InputValue: Single): Single; inline;
function threshold_ElliotSig(const InputValue: Single): Single; inline;
function threshold_ReLU(const InputValue: Single): Single; inline;
function threshold_LeakyReLU(const InputValue: Single): Single; inline;
function threshold_SoftPlus(const InputValue: Single): Single; inline;
function threshold_Sin(const InputValue: Single): Single; inline;
function threshold_Cos(const InputValue: Single): Single; inline;
function threshold_Gaussian(const InputValue: Single): Single; inline;
function threshold_BinaryStep(const InputValue: Single): Single; inline;

function thresholdDerive_Linear(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_Sigmoid(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_tanH(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_ArcTan(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_ArcSinH(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_ElliotSig(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_ReLU(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_LeakyReLU(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_SoftPlus(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_Sin(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_Cos(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_Gaussian(const OutputValue, InputValue: Single): Single; inline;
function thresholdDerive_BinaryStep(const OutputValue, InputValue: Single): Single; inline;

function _Sign(const AValue: Single; Epsilon: Single = 0): TValueSign; inline;
function SliceOf(Q: TArray<Single>; SetNum, Count: Integer): TArray<Single>; inline;
function RandomRangeF(const min, max: Single): Single; inline;
function RandomUniqueIntegerList(ToInt, Count: Integer): TArray<Integer>; overload; inline;
function RandomUniqueIntegerList(ToInt: Integer; Rate: Single): TArray<Integer>; overload; inline;

type
  TErrorFunc = reference to function(const OutValues, ExpectedValues: TArray<Single>): Single;
  TWeightErrorFunc = reference to function(const Weights: TArray<Single>): Single;

function loss_MSE(const OutValues, ExpectedValues: TArray<Single>): Single; inline;
function loss_MAE(const OutValues, ExpectedValues: TArray<Single>): Single; inline;
function loss_RMSE(const OutValues, ExpectedValues: TArray<Single>): Single; inline;

function Weight_Error1(const Weights: TArray<Single>): Single;
function Weight_Error2(const Weights: TArray<Single>): Single;

implementation

function threshold_Linear(const InputValue: Single): Single;
begin
  Result := InputValue;
end;

function thresholdDerive_Linear(const OutputValue, InputValue: Single): Single;
begin
  Result := 1;
end;

function threshold_Sigmoid(const InputValue: Single): Single;
begin
  Result := 1 / (1 + Exp(-InputValue));
end;

function thresholdDerive_Sigmoid(const OutputValue, InputValue: Single): Single;
begin
  Result := OutputValue * (1 - OutputValue);
end;

function threshold_tanH(const InputValue: Single): Single;
begin
  Result := Tanh(InputValue)
end;

function thresholdDerive_tanH(const OutputValue, InputValue: Single): Single;
begin
  Result := 1 - OutputValue * OutputValue;
end;

function threshold_ArcTan(const InputValue: Single): Single;
begin
  Result := ArcTan(InputValue);
end;

function thresholdDerive_ArcTan(const OutputValue, InputValue: Single): Single;
begin
  Result := 1 / (InputValue * InputValue + 1);
end;

function threshold_ArcSinH(const InputValue: Single): Single;
begin
  Result := ArcSinh(InputValue);
end;

function thresholdDerive_ArcSinH(const OutputValue, InputValue: Single): Single;
begin
  Result := 1 / Sqrt(InputValue * InputValue + 1);
end;

function threshold_ElliotSig(const InputValue: Single): Single;
begin
  Result := InputValue / (1 + Abs(InputValue));
end;

function thresholdDerive_ElliotSig(const OutputValue, InputValue: Single): Single;
begin
  Result := 1 / Sqr(1 + Abs(InputValue));
end;

function threshold_ReLU(const InputValue: Single): Single;
begin
  Result := Max(InputValue, 0);
end;

function thresholdDerive_ReLU(const OutputValue, InputValue: Single): Single;
begin
  Result := IfThen(InputValue > 0, 1, 0)
end;

function threshold_LeakyReLU(const InputValue: Single): Single;
begin
  if InputValue < 0 then
    Result := 0.01 * InputValue
  else
    Result := InputValue;
end;

function thresholdDerive_LeakyReLU(const OutputValue, InputValue: Single): Single;
begin
  if InputValue < 0 then
    Result := 0.01
  else
    Result := 1;
end;

function threshold_SoftPlus(const InputValue: Single): Single;
begin
  Result := Ln(1 + Exp(InputValue));
end;

function thresholdDerive_SoftPlus(const OutputValue, InputValue: Single): Single;
begin
  Result := 1 / (1 + Exp(-InputValue));
end;

function threshold_Sin(const InputValue: Single): Single;
begin
  Result := Sin(InputValue);
end;

function thresholdDerive_Sin(const OutputValue, InputValue: Single): Single;
begin
  Result := Cos(InputValue);
end;

function threshold_Cos(const InputValue: Single): Single;
begin
  Result := Cos(InputValue);
end;

function thresholdDerive_Cos(const OutputValue, InputValue: Single): Single;
begin
  Result := -Sin(InputValue);
end;

function threshold_Gaussian(const InputValue: Single): Single;
begin
  Result := Exp(-InputValue * InputValue);
end;

function thresholdDerive_Gaussian(const OutputValue, InputValue: Single): Single;
begin
  Result := -2 * InputValue * OutputValue
end;

function threshold_BinaryStep(const InputValue: Single): Single;
begin
  Result := IfThen(InputValue >= 0, 1, 0);
end;

function thresholdDerive_BinaryStep(const OutputValue, InputValue: Single): Single;
begin
  Result := 0;
end;

function _Sign(const AValue: Single; Epsilon: Single = 0): TValueSign;
begin
  if IsZero(AValue, Epsilon) then
    Result := ZeroValue
  else if (PInteger(@AValue)^ and $80000000) = $80000000 then
    Result := NegativeValue
  else
    Result := PositiveValue;
end;

function SliceOf(Q: TArray<Single>; SetNum, Count: Integer): TArray<Single>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i       := 0 to Count - 1 do
    Result[i] := Q[SetNum * Count + i];
end;

function RandomRangeF(const min, max: Single): Single;
begin
  Result := min + Random * (max - min);
end;

function RandomUniqueIntegerList(ToInt, Count: Integer): TArray<Integer>;
var
  A: TList<Integer>;
  L: TList<Integer>;
  i, x: Integer;
begin
  Randomize;
  L := TList<Integer>.Create;
  A := TList<Integer>.Create;
  try
    for i := 0 to ToInt do
      A.Add(i);

    repeat
      x := Random(A.Count);
      if not L.Contains(A[x]) then
        L.Add(A[x]);
    until L.Count = Count;

    L.Sort;
    Result := L.ToArray;
  finally
    A.Free;
    L.Free;
  end;
end;

function RandomUniqueIntegerList(ToInt: Integer; Rate: Single): TArray<Integer>;
begin
  Result := RandomUniqueIntegerList(ToInt, Integer(Round((ToInt + 1) * Rate)));
end;

function SameThresholdType(ThresholdTypeArray: TArray<TThresholdType>; var ThresholdType: TThresholdType): Boolean;
var
  i: Integer;
begin
  Result := Length(ThresholdTypeArray) > 0;
  if Result then
  begin
    ThresholdType := ThresholdTypeArray[0];
    for i         := 1 to Length(ThresholdTypeArray) - 1 do
      if ThresholdTypeArray[i] <> ThresholdType then
        Exit(False);
  end;
end;

function loss_MSE(const OutValues, ExpectedValues: TArray<Single>): Single;
// Mean Square Error
var
  i: Integer;
  d: Single;
  MSE: Single;
begin
  MSE   := 0;
  for i := 0 to Length(OutValues) - 1 do
  begin
    d   := ExpectedValues[i] - OutValues[i];
    MSE := MSE + d * d;
  end;
  Result := MSE / Length(OutValues);
end;

function loss_MAE(const OutValues, ExpectedValues: TArray<Single>): Single;
// Mean Absolute Error
var
  i: Integer;
  d: Single;
  MSE: Single;
begin
  MSE   := 0;
  for i := 0 to Length(OutValues) - 1 do
  begin
    d   := ExpectedValues[i] - OutValues[i];
    MSE := MSE + d;
  end;
  Result := MSE / Length(OutValues);
end;

function loss_RMSE(const OutValues, ExpectedValues: TArray<Single>): Single;
// Root Mean Square Error
begin
  Result := Sqrt(loss_MSE(OutValues, ExpectedValues));
end;

function Weight_Error1(const Weights: TArray<Single>): Single;
var
  W: Single;
begin
  Result := 0;
  for W in Weights do
    Result := Result + W * W / (1 + W * W);
end;

function Weight_Error2(const Weights: TArray<Single>): Single;
var
  W: Single;
begin
  Result := 0;
  for W in Weights do
    Result := Result + W * W;
end;

{ ThresholdTypeHelper }

constructor ThresholdTypeHelper.Create(Name: string);
begin
  Self := NameToType(Name);
end;

function ThresholdTypeHelper.NameToType(Name: string): TThresholdType;
var
  Func: TThresholdType;
  s: string;
begin
  for Func := Low(TThresholdType) to High(TThresholdType) do
  begin
    s := Func.ToName;
    if SameText(s, Name) then
      Exit(Func);
  end;
  raise Exception.Create('Error:  -> ThresholdTypeHelper.NameToType : ' + Name);
end;

class function ThresholdTypeHelper.ToArrayStr: TArray<string>;
var
  L: TList<string>;
  iTreshold: TThresholdType;
begin
  L := TList<string>.Create;
  try
    for iTreshold := Low(TThresholdType) to High(TThresholdType) do
      L.Add(iTreshold.ToName);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function ThresholdTypeHelper.ToDeriveFunction: TthresholdDeriveFunc;
begin
  case Self of
    funcLINEAR:
      Result := thresholdDerive_Linear;
    funcSIGMOID:
      Result := thresholdDerive_Sigmoid;
    functanH:
      Result := thresholdDerive_TanH;
    funcGAUSSIAN:
      Result := thresholdDerive_GAUSSIAN;
    funcBinaryStep:
      Result := thresholdDerive_BinaryStep;
    funcELLIOT:
      Result := thresholdDerive_ElliotSig;
    funcSIN:
      Result := thresholdDerive_Sin;
    funcCOS:
      Result := thresholdDerive_Cos;
    funcArcTan:
      Result := thresholdDerive_ArcTan;
    funcArcSinH:
      Result := thresholdDerive_ArcSinH;
    funcRELU:
      Result := thresholdDerive_ReLU;
    funcLEAKY_RELU:
      Result := thresholdDerive_LeakyReLU;
    funcSoftPlus:
      Result := thresholdDerive_SoftPlus;
  else
    raise Exception.Create('Error: ThresholdTypeHelper.ToDeriveFunction');
  end;
end;

function ThresholdTypeHelper.ToFunction: TthresholdFunc;
begin
  case Self of
    funcLINEAR:
      Result := threshold_Linear;
    funcSIGMOID:
      Result := threshold_Sigmoid;
    functanH:
      Result := threshold_TanH;
    funcGAUSSIAN:
      Result := threshold_GAUSSIAN;
    funcBinaryStep:
      Result := threshold_BinaryStep;
    funcELLIOT:
      Result := threshold_ElliotSig;
    funcSIN:
      Result := threshold_Sin;
    funcCOS:
      Result := threshold_Cos;
    funcArcTan:
      Result := threshold_ArcTan;
    funcArcSinH:
      Result := threshold_ArcSinH;
    funcRELU:
      Result := threshold_ReLU;
    funcLEAKY_RELU:
      Result := threshold_LeakyReLU;
    funcSoftPlus:
      Result := threshold_SoftPlus;
  else
    raise Exception.Create('Error: ThresholdTypeHelper.ToFunction');
  end;
end;

function ThresholdTypeHelper.ToName: string;
begin
  case Self of
    funcLINEAR:
      Result := 'Linear';
    funcSIGMOID:
      Result := 'Sigmoid';
    functanH:
      Result := 'TanH';
    funcGAUSSIAN:
      Result := 'GAUSSIAN';
    funcBinaryStep:
      Result := 'BinaryStep';
    funcELLIOT:
      Result := 'ElliotSig';
    funcSIN:
      Result := 'Sin';
    funcCOS:
      Result := 'Cos';
    funcArcTan:
      Result := 'ArcTan';
    funcArcSinH:
      Result := 'ArcSinH';
    funcRELU:
      Result := 'ReLU';
    funcLEAKY_RELU:
      Result := 'LeakyReLU';
    funcSoftPlus:
      Result := 'SoftPlus';
  else
    raise Exception.Create('Error: ThresholdTypeHelper.ToName');
  end;
end;

end.
