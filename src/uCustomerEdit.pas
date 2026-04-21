unit uCustomerEdit;

{
  Formulář pro editaci/vložení zákazníka.
  Demonstruje jak se v informačním systému volají uživatelské scripty:

    - PrepareEdit/PrepareInsert - načte záznam do lokálního FDQuery
    - OnAfterLoad  -> hned po otevření
    - OnFieldChange -> po potvrzení editace konkrétního pole (OnExit)
    - OnValidate  -> volá se před uložením, nad každým polem, které má
                     pro daný formulář definovaný validační script
    - OnBeforeSave -> celkový hook, může Cancel() ukončit uložení
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Mask, Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.Buttons,
  Data.DB, FireDAC.Comp.Client, System.StrUtils,
  uDM, uScriptEngine;

const
  FORM_ID = 'CustomerEdit';

type
  TfrmCustomerEdit = class(TForm)
    pnlBottom: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    lblCode: TLabel;
    edCode: TDBEdit;
    lblName: TLabel;
    edName: TDBEdit;
    lblEmail: TLabel;
    edEmail: TDBEdit;
    lblPhone: TLabel;
    edPhone: TDBEdit;
    lblCredit: TLabel;
    edCreditLimit: TDBEdit;
    lblDiscount: TLabel;
    edDiscount: TDBEdit;
    lblOrders: TLabel;
    edOrders: TDBEdit;
    chkVip: TDBCheckBox;
    lblNotes: TLabel;
    memNotes: TDBMemo;
    dsEdit: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FieldEditExit(Sender: TObject);
  private
    FQuery: TFDQuery;
    FHost: TScriptHost;
    FIsInsert: Boolean;

    procedure EnsureEditState;
    procedure RunEvent(const AEvent: string; const AField: string = '');
    function  ValidateAll: Boolean;
    procedure MapFieldEditEvents;
  public
    procedure PrepareInsert;
    procedure PrepareEdit(AId: Integer);
  end;

implementation

{$R *.dfm}

procedure TfrmCustomerEdit.FormCreate(Sender: TObject);
begin
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := DM.Connection;
  FQuery.CachedUpdates := False;
  dsEdit.DataSet := FQuery;

  FHost := TScriptHost.Create(FQuery);

  // propojit DBEdity na dsEdit
  edCode.DataSource := dsEdit;         edCode.DataField := 'code';
  edName.DataSource := dsEdit;         edName.DataField := 'name';
  edEmail.DataSource := dsEdit;        edEmail.DataField := 'email';
  edPhone.DataSource := dsEdit;        edPhone.DataField := 'phone';
  edCreditLimit.DataSource := dsEdit;  edCreditLimit.DataField := 'credit_limit';
  edDiscount.DataSource := dsEdit;     edDiscount.DataField := 'discount_percent';
  edOrders.DataSource := dsEdit;       edOrders.DataField := 'total_orders';
  chkVip.DataSource := dsEdit;         chkVip.DataField := 'is_vip';
  memNotes.DataSource := dsEdit;       memNotes.DataField := 'notes';

  MapFieldEditEvents;
end;

procedure TfrmCustomerEdit.FormDestroy(Sender: TObject);
begin
  FHost.Free;
end;

procedure TfrmCustomerEdit.MapFieldEditEvents;
begin
  // OnExit spouští OnFieldChange pro dané pole.
  edCode.OnExit         := FieldEditExit;
  edName.OnExit         := FieldEditExit;
  edEmail.OnExit        := FieldEditExit;
  edPhone.OnExit        := FieldEditExit;
  edCreditLimit.OnExit  := FieldEditExit;
  edDiscount.OnExit     := FieldEditExit;
  edOrders.OnExit       := FieldEditExit;
  memNotes.OnExit       := FieldEditExit;
end;

procedure TfrmCustomerEdit.PrepareInsert;
begin
  FIsInsert := True;
  Caption := 'Nový zákazník';
  FQuery.SQL.Text :=
    'SELECT id, code, name, email, phone, credit_limit, discount_percent, ' +
    '       total_orders, is_vip, notes FROM customers WHERE 1=0';
  FQuery.Open;
  FQuery.Append;
  FQuery.FieldByName('credit_limit').AsFloat := 0;
  FQuery.FieldByName('discount_percent').AsFloat := 0;
  FQuery.FieldByName('total_orders').AsInteger := 0;
  FQuery.FieldByName('is_vip').AsInteger := 0;
  RunEvent('OnAfterLoad');
end;

procedure TfrmCustomerEdit.PrepareEdit(AId: Integer);
begin
  FIsInsert := False;
  Caption := 'Editace zákazníka';
  FQuery.SQL.Text :=
    'SELECT id, code, name, email, phone, credit_limit, discount_percent, ' +
    '       total_orders, is_vip, notes FROM customers WHERE id = :id';
  FQuery.ParamByName('id').AsInteger := AId;
  FQuery.Open;
  if FQuery.IsEmpty then
  begin
    MessageDlg('Záznam nebyl nalezen.', mtWarning, [mbOK], 0);
    Exit;
  end;
  FQuery.Edit;
  RunEvent('OnAfterLoad');
end;

procedure TfrmCustomerEdit.EnsureEditState;
begin
  if not (FQuery.State in [dsEdit, dsInsert]) then
    FQuery.Edit;
end;

procedure TfrmCustomerEdit.FieldEditExit(Sender: TObject);
var
  DBEd: TDBEdit;
  DBMem: TDBMemo;
  FieldName: string;
begin
  FieldName := '';
  if Sender is TDBEdit then
  begin
    DBEd := TDBEdit(Sender);
    FieldName := DBEd.DataField;
  end
  else if Sender is TDBMemo then
  begin
    DBMem := TDBMemo(Sender);
    FieldName := DBMem.DataField;
  end;
  if FieldName = '' then Exit;
  // trigger Post na dataset, aby nová hodnota byla čitelná v scriptu
  if FQuery.State in [dsEdit, dsInsert] then
    FQuery.UpdateRecord;
  RunEvent('OnFieldChange', FieldName);
end;

procedure TfrmCustomerEdit.RunEvent(const AEvent, AField: string);
var
  Scripts: TScriptList;
  S: TScriptRec;
  Msg: string;
  Ok: Boolean;
begin
  Scripts := DM.LoadScripts(FORM_ID, AEvent, AField);
  try
    for S in Scripts do
    begin
      Ok := FHost.RunScript(S.Id, S.FormName, S.EventName, S.FieldName,
              S.ScriptCode, Msg);
      DM.LogScriptRun(S.Id, S.FormName, S.EventName, S.FieldName, Ok, Msg);
      if not Ok then
      begin
        if AEvent = 'OnValidate' then
          raise EAbort.Create(Msg)       // validační chybu propíchne ValidateAll
        else if AEvent = 'OnBeforeSave' then
          raise EAbort.Create(Msg)
        else
          MessageDlg(Format('Chyba scriptu (%s/%s%s): '#13#10'%s',
            [AEvent, AField,
             IfThen(S.Description <> '', ' - ' + S.Description, ''),
             Msg]), mtWarning, [mbOK], 0);
      end;
    end;
  finally
    Scripts.Free;
  end;
end;

function TfrmCustomerEdit.ValidateAll: Boolean;
var
  Fields: array of string;
  F: string;
begin
  // pole, která můžou mít validaci - odpovídá fixní struktuře formuláře.
  // Validátory, které nejsou definovány, se prostě nespustí.
  Fields := ['code', 'name', 'email', 'phone', 'credit_limit',
             'discount_percent', 'total_orders', 'notes'];
  try
    for F in Fields do
      RunEvent('OnValidate', F);
    Result := True;
  except
    on E: EAbort do
    begin
      MessageDlg('Validace selhala:'#13#10 + E.Message, mtError, [mbOK], 0);
      Result := False;
    end;
  end;
end;

procedure TfrmCustomerEdit.btnOKClick(Sender: TObject);
begin
  if FQuery.State in [dsEdit, dsInsert] then
    FQuery.UpdateRecord;

  if not ValidateAll then
  begin
    ModalResult := mrNone;
    Exit;
  end;

  try
    RunEvent('OnBeforeSave');
  except
    on E: EAbort do
    begin
      MessageDlg('Uložení zrušeno:'#13#10 + E.Message, mtWarning, [mbOK], 0);
      ModalResult := mrNone;
      Exit;
    end;
  end;

  // Scripty mohly změnit pole -> Post + ApplyUpdates
  if FQuery.State in [dsEdit, dsInsert] then
    FQuery.Post;

  if FIsInsert then
  begin
    // ID dohledáme po insertu - v tomto sample jednoduše uložíme přes
    // samostatný insert, aby nám nevadilo chybějící auto-increment refresh.
    with TFDQuery.Create(nil) do
    try
      Connection := DM.Connection;
      SQL.Text :=
        'INSERT INTO customers (code, name, email, phone, credit_limit, ' +
        '  discount_percent, total_orders, is_vip, notes) ' +
        'VALUES (:code, :name, :email, :phone, :cl, :dp, :oo, :vip, :notes)';
      ParamByName('code').AsString   := FQuery.FieldByName('code').AsString;
      ParamByName('name').AsString   := FQuery.FieldByName('name').AsString;
      ParamByName('email').AsString  := FQuery.FieldByName('email').AsString;
      ParamByName('phone').AsString  := FQuery.FieldByName('phone').AsString;
      ParamByName('cl').AsFloat      := FQuery.FieldByName('credit_limit').AsFloat;
      ParamByName('dp').AsFloat      := FQuery.FieldByName('discount_percent').AsFloat;
      ParamByName('oo').AsInteger    := FQuery.FieldByName('total_orders').AsInteger;
      ParamByName('vip').AsInteger   := FQuery.FieldByName('is_vip').AsInteger;
      ParamByName('notes').AsString  := FQuery.FieldByName('notes').AsString;
      ExecSQL;
    finally
      Free;
    end;
  end
  else
  begin
    with TFDQuery.Create(nil) do
    try
      Connection := DM.Connection;
      SQL.Text :=
        'UPDATE customers SET code=:code, name=:name, email=:email, ' +
        '  phone=:phone, credit_limit=:cl, discount_percent=:dp, ' +
        '  total_orders=:oo, is_vip=:vip, notes=:notes WHERE id=:id';
      ParamByName('code').AsString   := FQuery.FieldByName('code').AsString;
      ParamByName('name').AsString   := FQuery.FieldByName('name').AsString;
      ParamByName('email').AsString  := FQuery.FieldByName('email').AsString;
      ParamByName('phone').AsString  := FQuery.FieldByName('phone').AsString;
      ParamByName('cl').AsFloat      := FQuery.FieldByName('credit_limit').AsFloat;
      ParamByName('dp').AsFloat      := FQuery.FieldByName('discount_percent').AsFloat;
      ParamByName('oo').AsInteger    := FQuery.FieldByName('total_orders').AsInteger;
      ParamByName('vip').AsInteger   := FQuery.FieldByName('is_vip').AsInteger;
      ParamByName('notes').AsString  := FQuery.FieldByName('notes').AsString;
      ParamByName('id').AsInteger    := FQuery.FieldByName('id').AsInteger;
      ExecSQL;
    finally
      Free;
    end;
  end;

  ModalResult := mrOk;
end;

end.
