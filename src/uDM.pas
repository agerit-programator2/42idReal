unit uDM;

{
  Data modul - centrální místo pro připojení k MariaDB přes FireDAC.

  Obsahuje:
    - Connection ke zdroji dat
    - Query / DataSource pro tabulku customers (zobrazuje hlavní formulář)
    - Pomocné metody pro práci se scripty (LoadScripts, LogScriptRun)
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Comp.UI;

type
  TScriptRec = record
    Id: Integer;
    FormName: string;
    EventName: string;
    FieldName: string;
    Description: string;
    ScriptCode: string;
    Enabled: Boolean;
    ExecOrder: Integer;
  end;

  TScriptList = TList<TScriptRec>;

  TDM = class(TDataModule)
    Connection: TFDConnection;
    DrvMySQL: TFDPhysMySQLDriverLink;
    WaitCursor: TFDGUIxWaitCursor;
    qCustomers: TFDQuery;
    dsCustomers: TDataSource;
    qScripts: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
  public
    function ConnectDatabase: Boolean;
    procedure OpenCustomers;

    // Načte všechny aktivní scripty pro daný formulář + event (+ volitelně field).
    // Vrací TScriptList seřazený podle exec_order. Volající musí .Free.
    function LoadScripts(const AFormName, AEventName: string;
      const AFieldName: string = ''): TScriptList;

    // Zapíše výsledek běhu scriptu do script_log.
    procedure LogScriptRun(const AScriptId: Integer;
      const AFormName, AEventName, AFieldName: string;
      ASuccess: Boolean; const AMessage: string);

    // Scripty CRUD - používá scripts editor.
    procedure OpenScriptsForEditing(AQuery: TFDQuery);
    procedure SaveScript(AQuery: TFDQuery);
  end;

var
  DM: TDM;

implementation

uses
  Vcl.Dialogs, Vcl.Forms,
  uAppConfig;

{$R *.dfm}

{ TDM }

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  Connection.LoginPrompt := False;
end;

function TDM.ConnectDatabase: Boolean;
var
  Cfg: TDbConfig;
begin
  Result := False;
  Cfg := LoadDbConfig;

  if Cfg.VendorLib <> '' then
    DrvMySQL.VendorLib := Cfg.VendorLib;

  Connection.Params.Clear;
  Connection.Params.DriverID := 'MySQL';
  Connection.Params.Database := Cfg.Database;
  Connection.Params.UserName := Cfg.User;
  Connection.Params.Password := Cfg.Password;
  Connection.Params.Add('Server=' + Cfg.Server);
  Connection.Params.Add('Port=' + IntToStr(Cfg.Port));
  Connection.Params.Add('CharacterSet=utf8mb4');

  try
    Connection.Connected := True;
    Result := True;
  except
    on E: Exception do
      MessageDlg('Nepodařilo se připojit k databázi:'#13#10 + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TDM.OpenCustomers;
begin
  if qCustomers.Active then
    qCustomers.Close;
  qCustomers.SQL.Text :=
    'SELECT id, code, name, email, phone, credit_limit, discount_percent, ' +
    '       total_orders, is_vip, notes ' +
    'FROM customers ORDER BY code';
  qCustomers.Open;
end;

function TDM.LoadScripts(const AFormName, AEventName: string;
  const AFieldName: string): TScriptList;
var
  Q: TFDQuery;
  Rec: TScriptRec;
begin
  Result := TScriptList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Connection;
    if AFieldName = '' then
      Q.SQL.Text :=
        'SELECT id, form_name, event_name, field_name, description, ' +
        '       script_code, enabled, exec_order ' +
        'FROM scripts ' +
        'WHERE enabled = 1 AND form_name = :fn AND event_name = :ev ' +
        '  AND (field_name IS NULL OR field_name = '''') ' +
        'ORDER BY exec_order, id'
    else
      Q.SQL.Text :=
        'SELECT id, form_name, event_name, field_name, description, ' +
        '       script_code, enabled, exec_order ' +
        'FROM scripts ' +
        'WHERE enabled = 1 AND form_name = :fn AND event_name = :ev ' +
        '  AND field_name = :fld ' +
        'ORDER BY exec_order, id';

    Q.ParamByName('fn').AsString := AFormName;
    Q.ParamByName('ev').AsString := AEventName;
    if AFieldName <> '' then
      Q.ParamByName('fld').AsString := AFieldName;
    Q.Open;
    while not Q.Eof do
    begin
      Rec.Id          := Q.FieldByName('id').AsInteger;
      Rec.FormName    := Q.FieldByName('form_name').AsString;
      Rec.EventName   := Q.FieldByName('event_name').AsString;
      Rec.FieldName   := Q.FieldByName('field_name').AsString;
      Rec.Description := Q.FieldByName('description').AsString;
      Rec.ScriptCode  := Q.FieldByName('script_code').AsString;
      Rec.Enabled     := Q.FieldByName('enabled').AsInteger = 1;
      Rec.ExecOrder   := Q.FieldByName('exec_order').AsInteger;
      Result.Add(Rec);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TDM.LogScriptRun(const AScriptId: Integer;
  const AFormName, AEventName, AFieldName: string;
  ASuccess: Boolean; const AMessage: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Connection;
    Q.SQL.Text :=
      'INSERT INTO script_log (script_id, form_name, event_name, ' +
      '  field_name, success, message) ' +
      'VALUES (:sid, :fn, :ev, :fld, :ok, :msg)';
    if AScriptId > 0 then
      Q.ParamByName('sid').AsInteger := AScriptId
    else
      Q.ParamByName('sid').Clear;
    Q.ParamByName('fn').AsString  := AFormName;
    Q.ParamByName('ev').AsString  := AEventName;
    if AFieldName = '' then
      Q.ParamByName('fld').Clear
    else
      Q.ParamByName('fld').AsString := AFieldName;
    Q.ParamByName('ok').AsInteger := Ord(ASuccess);
    Q.ParamByName('msg').AsString := AMessage;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TDM.OpenScriptsForEditing(AQuery: TFDQuery);
begin
  AQuery.Connection := Connection;
  AQuery.SQL.Text :=
    'SELECT id, form_name, event_name, field_name, description, ' +
    '       script_code, enabled, exec_order ' +
    'FROM scripts ORDER BY form_name, event_name, exec_order';
  AQuery.Open;
end;

procedure TDM.SaveScript(AQuery: TFDQuery);
begin
  if AQuery.State in [dsEdit, dsInsert] then
    AQuery.Post;
  AQuery.ApplyUpdates(0);
end;

end.
