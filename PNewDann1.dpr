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
  BSplines in 'NiceChart\BSplines.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmNewDann, frmNewDann);
  Application.Run;
end.
