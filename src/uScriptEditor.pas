unit uScriptEditor;

{
  Editor scriptů uložených v DB (tabulka scripts).
  Levý panel: seznam všech scriptů (grid)
  Pravý panel: detail vybraného scriptu - metadata + tělo scriptu.
  Tlačítka: Nový / Uložit / Smazat / Test kompilace / Zavřít
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Mask,
  Vcl.Buttons, Vcl.ComCtrls,
  Data.DB, FireDAC.Comp.Client;

type
  TfrmScriptEditor = class(TForm)
    pnlLeft: TPanel;
    pnlRight: TPanel;
    Splitter: TSplitter;
    Grid: TDBGrid;
    lblForm: TLabel;
    edForm: TDBEdit;
    lblEvent: TLabel;
    cbEvent: TDBComboBox;
    lblField: TLabel;
    edField: TDBEdit;
    lblDesc: TLabel;
    edDesc: TDBEdit;
    chkEnabled: TDBCheckBox;
    lblOrder: TLabel;
    edOrder: TDBEdit;
    lblCode: TLabel;
    memCode: TDBMemo;
    pnlBottom: TPanel;
    btnNew: TBitBtn;
    btnSave: TBitBtn;
    btnDelete: TBitBtn;
    btnTest: TBitBtn;
    btnClose: TBitBtn;
    ds: TDataSource;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FQuery: TFDQuery;
  end;

implementation

uses
  uDM, uScriptEngine,
  uPSComponent, uPSCompiler;

{$R *.dfm}

procedure TfrmScriptEditor.FormCreate(Sender: TObject);
begin
  FQuery := TFDQuery.Create(Self);
  FQuery.CachedUpdates := True;
  DM.OpenScriptsForEditing(FQuery);
  ds.DataSet := FQuery;

  Grid.DataSource := ds;

  edForm.DataSource := ds;     edForm.DataField := 'form_name';
  cbEvent.DataSource := ds;    cbEvent.DataField := 'event_name';
  edField.DataSource := ds;    edField.DataField := 'field_name';
  edDesc.DataSource := ds;     edDesc.DataField := 'description';
  chkEnabled.DataSource := ds; chkEnabled.DataField := 'enabled';
  edOrder.DataSource := ds;    edOrder.DataField := 'exec_order';
  memCode.DataSource := ds;    memCode.DataField := 'script_code';

  cbEvent.Items.Clear;
  cbEvent.Items.Add('OnFieldChange');
  cbEvent.Items.Add('OnValidate');
  cbEvent.Items.Add('OnBeforeSave');
  cbEvent.Items.Add('OnAfterLoad');
end;

procedure TfrmScriptEditor.FormDestroy(Sender: TObject);
begin
  if Assigned(FQuery) and FQuery.Active then FQuery.Close;
end;

procedure TfrmScriptEditor.btnNewClick(Sender: TObject);
begin
  FQuery.Append;
  FQuery.FieldByName('form_name').AsString  := 'CustomerEdit';
  FQuery.FieldByName('event_name').AsString := 'OnFieldChange';
  FQuery.FieldByName('enabled').AsInteger   := 1;
  FQuery.FieldByName('exec_order').AsInteger:= 100;
  FQuery.FieldByName('script_code').AsString:=
    'begin' + sLineBreak + '  // sem napište tělo scriptu' + sLineBreak + 'end.';
  edForm.SetFocus;
end;

procedure TfrmScriptEditor.btnSaveClick(Sender: TObject);
begin
  try
    DM.SaveScript(FQuery);
    StatusBar.SimpleText := 'Uloženo.';
  except
    on E: Exception do
    begin
      StatusBar.SimpleText := 'Chyba: ' + E.Message;
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmScriptEditor.btnDeleteClick(Sender: TObject);
begin
  if FQuery.IsEmpty then Exit;
  if MessageDlg('Smazat vybraný script?', mtConfirmation,
       [mbYes, mbNo], 0) <> mrYes then Exit;
  FQuery.Delete;
  FQuery.ApplyUpdates(0);
end;

procedure TfrmScriptEditor.btnTestClick(Sender: TObject);
var
  PS: TPSScript;
  i: Integer;
  Msg: string;
begin
  // Pouze otestujeme, zda se script zkompiluje. Běh je doménou formuláře,
  // kde jsou k dispozici pole z dataset.
  PS := TPSScript.Create(nil);
  try
    PS.Script.Text := FQuery.FieldByName('script_code').AsString;
    if PS.Compile then
      MessageDlg('Script se úspěšně zkompiloval.', mtInformation, [mbOK], 0)
    else
    begin
      Msg := 'Chyba překladu:';
      for i := 0 to PS.CompilerMessageCount - 1 do
        Msg := Msg + sLineBreak + PS.CompilerErrorToStr(i);
      MessageDlg(Msg, mtError, [mbOK], 0);
    end;
  finally
    PS.Free;
  end;
end;

procedure TfrmScriptEditor.btnCloseClick(Sender: TObject);
begin
  if FQuery.State in [dsEdit, dsInsert] then
    if MessageDlg('Uložit rozpracované změny?', mtConfirmation,
         [mbYes, mbNo], 0) = mrYes then
      DM.SaveScript(FQuery)
    else
      FQuery.Cancel;
  ModalResult := mrOk;
end;

end.
