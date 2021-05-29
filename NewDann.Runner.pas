unit NewDann.Runner;

interface

uses
  NewDann.Data, NewDann.Network,
  OtlParallel, OtlTaskControl, OtlComm, OtlCommon,
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, NewDann.frm.Graph, Vcl.ExtDlgs,
  Vcl.ExtCtrls;

type
  TfrmRunner = class(TForm)
    frmGraph: TfrmGraph;
    grdData: TStringGrid;
    lblSeparator: TLabel;
    edtSeparator: TEdit;
    dlgData: TOpenTextFileDialog;
    dlgStructure: TOpenTextFileDialog;
    dlgSaveData: TSaveTextFileDialog;
    btnRun: TButton;
    btnBreak: TButton;
    pnlMenu: TPanel;
    lblDecimalSeparator: TLabel;
    edtDecimalSeparator: TEdit;
    btnLoadCSV: TButton;
    btnSaveCSV: TButton;
    btnLoadStructure: TButton;
    btnClearGrid: TButton;
    procedure btnLoadCSVClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClearGridClick(Sender: TObject);
    procedure btnLoadStructureClick(Sender: TObject);
    procedure btnSaveCSVClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnBreakClick(Sender: TObject);
    procedure edtSeparatorChange(Sender: TObject);
    procedure edtDecimalSeparatorChange(Sender: TObject);
  private
    FGridCount: Integer;
    FDataCount: Integer;
    FNNrunner: TNeuralNetRunner;
    FData: TData;
    FBackgroundWorker: IOmniBackgroundWorker;
    FWorkItem: IOmniWorkItem;
    FProcess: TOmniBackgroundWorkerDelegate;
    procedure DataToGrid;
    procedure Draw;
    procedure RunWorker;
    procedure RequestDone(const Sender: IOmniBackgroundWorker; const workItem: IOmniWorkItem);
    procedure OnThreadMessage(const task: IOmniTaskControl; const msg: TOmniMessage);
    procedure AddGridData(Y: Integer; Data: TArray<Single>);
    procedure CheckRun;
  public
  end;

var
  frmRunner: TfrmRunner;

implementation

uses
  System.Rtti, System.Math;

{$R *.dfm}

procedure TfrmRunner.btnRunClick(Sender: TObject);
begin
  btnBreak.Enabled := True;
  RunWorker;
end;

procedure TfrmRunner.btnBreakClick(Sender: TObject);
begin
  if Assigned(FworkItem) then
    FworkItem.CancellationToken.Signal;
end;

procedure TfrmRunner.btnClearGridClick(Sender: TObject);
begin
  grdData.RowCount    := 0;
  grdData.ColCount    := 0;
  grdData.Cells[0, 0] := '';
end;

procedure TfrmRunner.btnLoadCSVClick(Sender: TObject);
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
      FData.DecimalSeparator := edtDecimalSeparator.Text[1];
      FData.Separator        := edtSeparator.Text;
      FData.LoadDataFromFile(FileName, Encoding);
      FDataCount := FData.ItemCount;
      DataToGrid;
    end
    else
      raise Exception.Create('File does not exist.');
  end;
  CheckRun;
end;

procedure TfrmRunner.RunWorker;
begin
  FBackgroundWorker.Schedule(FworkItem);
end;

procedure TfrmRunner.RequestDone(const Sender: IOmniBackgroundWorker; const workItem: IOmniWorkItem);
begin
  btnBreak.Enabled := False;
end;

procedure TfrmRunner.OnThreadMessage(const task: IOmniTaskControl; const msg: TOmniMessage);
var
  Y: Integer;
  D: TArray<Single>;
begin
  D := msg.MsgData.ToArray<single>;
  Y := msg.MsgID;
  FData.AddData(Y, FDataCount, D);
  AddGridData(Y, D);
end;

procedure TfrmRunner.AddGridData(Y: Integer; Data: TArray<Single>);
var
  c: Integer;
  i: Integer;
begin
  c                := Length(Data);
  grdData.ColCount := Max(FGridCount + C, grdData.ColCount);

  for i := 0 to c - 1 do
  begin
    grdData.RowCount                 := Max(y + 1, grdData.RowCount);
    grdData.Cells[i + FGridCount, Y] := Data[i].ToString;
  end;
end;

procedure TfrmRunner.btnLoadStructureClick(Sender: TObject);
var
  Encoding: TEncoding;
  EncIndex: Integer;
  Filename: string;
begin
  if dlgStructure.Execute(Self.Handle) then
  begin
    Filename := dlgStructure.FileName;
    EncIndex := dlgStructure.EncodingIndex;
    Encoding := dlgStructure.Encodings.Objects[EncIndex] as TEncoding;
    FNNrunner.LoadStructureFromFile(Filename);
    Draw;
  end;
  CheckRun;
end;

procedure TfrmRunner.btnSaveCSVClick(Sender: TObject);
var
  Encoding: TEncoding;
  EncIndex: Integer;
  Filename: string;
begin
  if dlgSaveData.Execute then
  begin
    Filename := dlgSaveData.FileName;
    EncIndex := dlgSaveData.EncodingIndex;
    Encoding := dlgSaveData.Encodings.Objects[EncIndex] as TEncoding;
    FData.SaveToCSVFile(Filename, Encoding);
  end;
end;

procedure TfrmRunner.CheckRun;
begin
  btnRun.Enabled := FNNrunner.IsValid and (FData.DataCount > 0) and
    (FData.ItemCount >= FNNrunner.Neurons.CountInput + FNNrunner.Neurons.CountOutput);
end;

procedure TfrmRunner.DataToGrid;
var
  c, r: Integer;
  data: TArray<Single>;
  Format: TFormatSettings;
begin
  Format                  := TFormatSettings.Create;
  Format.DecimalSeparator := edtDecimalSeparator.Text[1];

  grdData.ColCount := FData.ItemCount;
  grdData.RowCount := FData.DataCount;
  for r            := 0 to FData.DataCount - 1 do
  begin
    data                  := FData[r];
    for c                 := 0 to FData.ItemCount - 1 do
      grdData.Cells[c, r] := data[c].ToString(Format);
  end;
  FGridCount := grdData.ColCount;
end;

procedure TfrmRunner.Draw;
begin
  frmGraph.Draw(FNNrunner.Neurons.ToArray, FNNrunner.Con.ToArray);
end;

procedure TfrmRunner.edtDecimalSeparatorChange(Sender: TObject);
begin
  if Length(edtDecimalSeparator.Text) > 0 then
    FData.DecimalSeparator := edtDecimalSeparator.Text[1];
end;

procedure TfrmRunner.edtSeparatorChange(Sender: TObject);
begin
  FData.Separator := edtSeparator.Text;
end;

procedure TfrmRunner.FormCreate(Sender: TObject);
begin
  FNNrunner  := TNeuralNetRunner.Create;
  FData      := TData.Create;
  FGridCount := 0;
  FDataCount := 0;
  CheckRun;

  FProcess := procedure(const WorkItem: IOmniWorkItem)
    var
      c: Integer;
    begin
      // SW.Start;

      c := FData.DataCount;
      FNNrunner.Run(
        procedure(Const Indx, Count: Integer; var Res: TArray<Single>; var IsBreak: Boolean)
        begin
          IsBreak := WorkItem.CancellationToken.IsSignalled or (Indx >= c);
          if not IsBreak then
            Res := FData.SliceOfData(Indx, 0, Count);
        end,
        procedure(Indx: Integer; Output: TArray<Single>)
        begin
          WorkItem.Task.Comm.Send(Indx, TOmniValue.FromArray<Single>(Output));
        end);
    end;

  FBackgroundWorker := Parallel.BackgroundWorker.NumTasks(2). //
    OnRequestDone(RequestDone).//
    TaskConfig(Parallel.TaskConfig.OnMessage(OnThreadMessage)).//
    Execute(FProcess);
  FworkItem := FBackgroundWorker.CreateWorkItem(0);
end;

procedure TfrmRunner.FormDestroy(Sender: TObject);
begin
  FData.Free;
  FNNrunner.Free;
end;

end.
