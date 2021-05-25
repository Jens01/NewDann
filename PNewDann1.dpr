program PNewDann1;



uses
  Vcl.Forms,
  NewDann.Graph in 'NewDann.Graph.pas',
  NewDann in 'NewDann.pas' {frmNewDann},
  NewDann.Network in 'NewDann.Network.pas',
  NewDann.Formula in 'NewDann.Formula.pas',
  NewDann.Data in 'NewDann.Data.pas',
  NewDann.frm.Graph in 'NewDann.frm.Graph.pas' {frmGraph: TFrame},
  NiceChart in 'NiceChart\NiceChart.pas',
  BSplines in 'NiceChart\BSplines.pas',
  DelphiCL in 'OpenCL\DelphiCL.pas',
  CL_Platform in 'OpenCL\CL_Platform.pas',
  CL_GL in 'OpenCL\CL_GL.pas',
  CL in 'OpenCL\CL.pas',
  NewDann.OpenCL in 'NewDann.OpenCL.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmNewDann, frmNewDann);
  Application.Run;
end.
