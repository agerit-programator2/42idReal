unit uScriptEngine;

{
  Wrapper nad Pascal Scriptem (RemObjects/Inno Setup) pro spouštění
  uživatelských scriptů uložených v DB. Scripty mají přístup k polím
  záznamu přes funkce GetField*/SetField* a mohou:
    - zrušit akci  (Cancel/Fail)
    - zobrazit zprávu / varování
    - logovat do script_log

  Závislost:
    * uPSComponent, uPSRuntime, uPSCompiler (Pascal Script).
      https://github.com/remobjects/pascalscript

  Zde používáme jediný TPSScript per spuštění (jednoduché, srozumitelné).
  Sdílené stavové proměnné mezi scripty jsou záměrně vynechané.
}

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  Data.DB,
  uPSCompiler, uPSRuntime, uPSComponent, uPSUtils;

type
  EScriptCancel = class(Exception);
  EScriptFail   = class(Exception);

  TScriptHost = class
  private
    FDataSet: TDataSet;
    FCurrentScriptId: Integer;
    FCurrentFormName: string;
    FCurrentEventName: string;
    FCurrentFieldName: string;

    // Pomocné funkce vystavené do scriptu
    function  ScGetFieldStr  (const AName: string): string;
    function  ScGetFieldInt  (const AName: string): Integer;
    function  ScGetFieldFloat(const AName: string): Double;
    function  ScGetFieldBool (const AName: string): Boolean;
    procedure ScSetFieldStr  (const AName, AValue: string);
    procedure ScSetFieldInt  (const AName: string; AValue: Integer);
    procedure ScSetFieldFloat(const AName: string; AValue: Double);
    procedure ScSetFieldBool (const AName: string; AValue: Boolean);
    function  ScFieldIsNull  (const AName: string): Boolean;
    procedure ScClearField   (const AName: string);

    procedure ScShowMessage(const AMsg: string);
    procedure ScShowWarning(const AMsg: string);
    procedure ScCancel     (const AReason: string);
    procedure ScFail       (const AReason: string);
    function  ScNow        : TDateTime;

    procedure HandleCompile(Sender: TPSScript);
    procedure HandleExec(Sender: TPSScript);
  public
    constructor Create(ADataSet: TDataSet);

    // Spustí jeden script; při jeho chybě zprávu předá volajícímu.
    //  Result: True  -> script doběhl bez Cancel/Fail
    //          False -> script zavolal Cancel nebo Fail (OutMsg = důvod)
    function RunScript(AScriptId: Integer;
      const AFormName, AEventName, AFieldName, AScriptCode: string;
      out OutMsg: string): Boolean;
  end;

implementation

uses
  Vcl.Dialogs;

{ TScriptHost }

constructor TScriptHost.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

// ---------------------------------------------------------------------
// Implementace funkcí zpřístupněných scriptům
// ---------------------------------------------------------------------
function TScriptHost.ScGetFieldStr(const AName: string): string;
var F: TField;
begin
  F := FDataSet.FindField(AName);
  if (F = nil) or F.IsNull then Exit('');
  Result := F.AsString;
end;

function TScriptHost.ScGetFieldInt(const AName: string): Integer;
var F: TField;
begin
  F := FDataSet.FindField(AName);
  if (F = nil) or F.IsNull then Exit(0);
  Result := F.AsInteger;
end;

function TScriptHost.ScGetFieldFloat(const AName: string): Double;
var F: TField;
begin
  F := FDataSet.FindField(AName);
  if (F = nil) or F.IsNull then Exit(0);
  Result := F.AsFloat;
end;

function TScriptHost.ScGetFieldBool(const AName: string): Boolean;
var F: TField;
begin
  F := FDataSet.FindField(AName);
  if (F = nil) or F.IsNull then Exit(False);
  Result := F.AsBoolean;
end;

procedure TScriptHost.ScSetFieldStr(const AName, AValue: string);
var F: TField;
begin
  F := FDataSet.FieldByName(AName);
  if not (FDataSet.State in [dsEdit, dsInsert]) then FDataSet.Edit;
  F.AsString := AValue;
end;

procedure TScriptHost.ScSetFieldInt(const AName: string; AValue: Integer);
var F: TField;
begin
  F := FDataSet.FieldByName(AName);
  if not (FDataSet.State in [dsEdit, dsInsert]) then FDataSet.Edit;
  F.AsInteger := AValue;
end;

procedure TScriptHost.ScSetFieldFloat(const AName: string; AValue: Double);
var F: TField;
begin
  F := FDataSet.FieldByName(AName);
  if not (FDataSet.State in [dsEdit, dsInsert]) then FDataSet.Edit;
  F.AsFloat := AValue;
end;

procedure TScriptHost.ScSetFieldBool(const AName: string; AValue: Boolean);
var F: TField;
begin
  F := FDataSet.FieldByName(AName);
  if not (FDataSet.State in [dsEdit, dsInsert]) then FDataSet.Edit;
  F.AsBoolean := AValue;
end;

function TScriptHost.ScFieldIsNull(const AName: string): Boolean;
var F: TField;
begin
  F := FDataSet.FindField(AName);
  Result := (F = nil) or F.IsNull;
end;

procedure TScriptHost.ScClearField(const AName: string);
var F: TField;
begin
  F := FDataSet.FieldByName(AName);
  if not (FDataSet.State in [dsEdit, dsInsert]) then FDataSet.Edit;
  F.Clear;
end;

procedure TScriptHost.ScShowMessage(const AMsg: string);
begin
  Vcl.Dialogs.MessageDlg(AMsg, mtInformation, [mbOK], 0);
end;

procedure TScriptHost.ScShowWarning(const AMsg: string);
begin
  Vcl.Dialogs.MessageDlg(AMsg, mtWarning, [mbOK], 0);
end;

procedure TScriptHost.ScCancel(const AReason: string);
begin
  raise EScriptCancel.Create(AReason);
end;

procedure TScriptHost.ScFail(const AReason: string);
begin
  raise EScriptFail.Create(AReason);
end;

function TScriptHost.ScNow: TDateTime;
begin
  Result := SysUtils.Now;
end;

// ---------------------------------------------------------------------
// Registrace funkcí do Pascal Script kompilátoru / runtime
// ---------------------------------------------------------------------
procedure TScriptHost.HandleCompile(Sender: TPSScript);
begin
  Sender.AddMethod(Self,@TScriptHost.ScGetFieldStr,
    'function  GetFieldStr  (const Name: string): string;');
  Sender.AddMethod(Self,@TScriptHost.ScGetFieldInt,
    'function  GetFieldInt  (const Name: string): Integer;');
  Sender.AddMethod(Self,@TScriptHost.ScGetFieldFloat,
    'function  GetFieldFloat(const Name: string): Double;');
  Sender.AddMethod(Self,@TScriptHost.ScGetFieldBool,
    'function  GetFieldBool (const Name: string): Boolean;');
  Sender.AddMethod(Self,@TScriptHost.ScSetFieldStr,
    'procedure SetFieldStr  (const Name, Value: string);');
  Sender.AddMethod(Self,@TScriptHost.ScSetFieldInt,
    'procedure SetFieldInt  (const Name: string; Value: Integer);');
  Sender.AddMethod(Self,@TScriptHost.ScSetFieldFloat,
    'procedure SetFieldFloat(const Name: string; Value: Double);');
  Sender.AddMethod(Self,@TScriptHost.ScSetFieldBool,
    'procedure SetFieldBool (const Name: string; Value: Boolean);');
  Sender.AddMethod(Self,@TScriptHost.ScFieldIsNull,
    'function  FieldIsNull  (const Name: string): Boolean;');
  Sender.AddMethod(Self,@TScriptHost.ScClearField,
    'procedure ClearField   (const Name: string);');
  Sender.AddMethod(Self,@TScriptHost.ScShowMessage,
    'procedure ShowMessage  (const Msg: string);');
  Sender.AddMethod(Self,@TScriptHost.ScShowWarning,
    'procedure ShowWarning  (const Msg: string);');
  Sender.AddMethod(Self,@TScriptHost.ScCancel,
    'procedure Cancel       (const Reason: string);');
  Sender.AddMethod(Self,@TScriptHost.ScFail,
    'procedure Fail         (const Reason: string);');
  Sender.AddMethod(Self,@TScriptHost.ScNow,
    'function  Now: TDateTime;');
end;

procedure TScriptHost.HandleExec(Sender: TPSScript);
begin
  // Funkce se registrovaly přes AddFunction v OnCompile, není co doplnit.
  // Tento handler je zde pro případnou budoucí registraci classes/instancí.
end;

// ---------------------------------------------------------------------
// RunScript
// ---------------------------------------------------------------------
function TScriptHost.RunScript(AScriptId: Integer;
  const AFormName, AEventName, AFieldName, AScriptCode: string;
  out OutMsg: string): Boolean;
var
  PS: TPSScript;
  i: Integer;
begin
  Result := True;
  OutMsg := '';
  FCurrentScriptId  := AScriptId;
  FCurrentFormName  := AFormName;
  FCurrentEventName := AEventName;
  FCurrentFieldName := AFieldName;

  PS := TPSScript.Create(nil);
  try
    PS.OnCompile := HandleCompile;
    PS.OnExecute := HandleExec;
    PS.Script.Text := AScriptCode;

    if not PS.Compile then
    begin
      OutMsg := 'Chyba překladu:';
      for i := 0 to PS.CompilerMessageCount - 1 do
        OutMsg := OutMsg + sLineBreak + PS.CompilerErrorToStr(i);
      Exit(False);
    end;

    try
      if not PS.Execute then
      begin
        OutMsg := 'Runtime chyba: ' + PS.ExecErrorToString;
        Exit(False);
      end;
    except
      on E: EScriptCancel do
      begin
        OutMsg := E.Message;
        Exit(False);
      end;
      on E: EScriptFail do
      begin
        OutMsg := E.Message;
        Exit(False);
      end;
      on E: Exception do
      begin
        OutMsg := 'Chyba: ' + E.Message;
        Exit(False);
      end;
    end;
  finally
    PS.Free;
  end;
end;

end.
