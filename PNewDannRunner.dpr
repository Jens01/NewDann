program PNewDannRunner;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  NewDann.Runner in 'NewDann.Runner.pas' {frmRunner},
  NewDann.frm.Graph in 'NewDann.frm.Graph.pas' {frmGraph: TFrame},
  NewDann.Data in 'NewDann.Data.pas',
  NewDann.Network in 'NewDann.Network.pas',
  NewDann.Formula in 'NewDann.Formula.pas',
  NewDann.Graph in 'NewDann.Graph.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmRunner, frmRunner);
  Application.Run;
end.
