program CWSC;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  OmniRig_TLB in '..\..\20.0\Imports\OmniRig_TLB.pas',
  RegExpr in 'RegExpr.pas',
  Unit2 in 'Unit2.pas' {perBandForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CW Skimmer Companion';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TperBandForm, perBandForm);
  Application.Run;
end.
