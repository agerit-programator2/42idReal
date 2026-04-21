unit uMain;

{
  Hlavní formulář - seznam zákazníků + tlačítka:
    Nový / Editovat / Smazat
    Scripty (otevře editor scriptů)
    Obnovit (reload gridu)
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnScripts: TButton;
    btnRefresh: TButton;
    Grid: TDBGrid;
    StatusBar: TStatusBar;
    procedure FormShow(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnScriptsClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
  private
    procedure OpenEditor(AInsert: Boolean);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uDM, uCustomerEdit, uScriptEditor;

{$R *.dfm}

procedure TfrmMain.FormShow(Sender: TObject);
begin
  DM.OpenCustomers;
  Grid.DataSource := DM.dsCustomers;
  StatusBar.SimpleText := 'Připojeno k databázi ' + DM.Connection.Params.Database;
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  DM.qCustomers.Close;
  DM.qCustomers.Open;
end;

procedure TfrmMain.btnNewClick(Sender: TObject);
begin
  OpenEditor(True);
end;

procedure TfrmMain.btnEditClick(Sender: TObject);
begin
  OpenEditor(False);
end;

procedure TfrmMain.GridDblClick(Sender: TObject);
begin
  OpenEditor(False);
end;

procedure TfrmMain.btnDeleteClick(Sender: TObject);
begin
  if DM.qCustomers.IsEmpty then Exit;
  if MessageDlg(Format('Smazat zákazníka "%s"?',
       [DM.qCustomers.FieldByName('name').AsString]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  DM.qCustomers.Delete;
  DM.qCustomers.ApplyUpdates(0);
end;

procedure TfrmMain.btnScriptsClick(Sender: TObject);
var
  F: TfrmScriptEditor;
begin
  F := TfrmScriptEditor.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmMain.OpenEditor(AInsert: Boolean);
var
  F: TfrmCustomerEdit;
begin
  if (not AInsert) and DM.qCustomers.IsEmpty then Exit;

  F := TfrmCustomerEdit.Create(Self);
  try
    if AInsert then
      F.PrepareInsert
    else
      F.PrepareEdit(DM.qCustomers.FieldByName('id').AsInteger);
    if F.ShowModal = mrOk then
      btnRefreshClick(nil);
  finally
    F.Free;
  end;
end;

end.
