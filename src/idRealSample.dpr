program idRealSample;

{$R *.res}

uses
  Vcl.Forms,
  uDM in 'uDM.pas' {DM: TDataModule},
  uScriptEngine in 'uScriptEngine.pas',
  uMain in 'uMain.pas' {frmMain},
  uCustomerEdit in 'uCustomerEdit.pas' {frmCustomerEdit},
  uScriptEditor in 'uScriptEditor.pas' {frmScriptEditor},
  uAppConfig in 'uAppConfig.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '42idReal - Delphi + MariaDB scripting sample';
  Application.CreateForm(TDM, DM);
  if not DM.ConnectDatabase then
  begin
    Application.Terminate;
    Exit;
  end;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
