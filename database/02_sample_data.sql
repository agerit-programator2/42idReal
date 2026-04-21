-- =====================================================================
-- 42idReal - Ukázková data
-- =====================================================================

USE idreal_demo;

-- ---------------------------------------------------------------------
-- Zákazníci
-- ---------------------------------------------------------------------
INSERT INTO customers (code, name, email, phone, credit_limit, discount_percent, total_orders, is_vip, notes) VALUES
 ('C0001', 'Novák Jan',               'novak@example.cz',    '+420 777 111 222',  50000.00,  5.00, 12, 0, 'Pravidelný zákazník'),
 ('C0002', 'ACME s.r.o.',              'info@acme.cz',        '+420 222 333 444', 250000.00, 10.00, 58, 1, 'VIP - velkoobchod'),
 ('C0003', 'Svobodová Petra',          'petra.s@example.cz',  '+420 603 987 654',  10000.00,  0.00,  2, 0, NULL),
 ('C0004', 'TechnoLab a.s.',           'obchod@technolab.cz', '+420 222 999 888', 500000.00, 12.00, 94, 1, 'Strategický partner'),
 ('C0005', 'Dvořák Tomáš - řemesla',   'dvorak@example.cz',   NULL,                 25000.00,  3.00,  7, 0, 'OSVČ');

-- ---------------------------------------------------------------------
-- Ukázkové scripty pro formulář CustomerEdit
-- ---------------------------------------------------------------------

-- 1) Po změně credit_limit automaticky dopočítat discount_percent a is_vip
INSERT INTO scripts (form_name, event_name, field_name, description, script_code, enabled, exec_order) VALUES
('CustomerEdit', 'OnFieldChange', 'credit_limit',
 'Podle výše kreditu nastaví slevu a VIP příznak',
'var
  cl: Double;
begin
  cl := GetFieldFloat(''credit_limit'');
  if cl >= 200000 then
  begin
    SetFieldFloat(''discount_percent'', 10);
    SetFieldInt(''is_vip'', 1);
  end
  else if cl >= 50000 then
  begin
    SetFieldFloat(''discount_percent'', 5);
    SetFieldInt(''is_vip'', 0);
  end
  else
  begin
    SetFieldFloat(''discount_percent'', 0);
    SetFieldInt(''is_vip'', 0);
  end;
end.', 1, 100);

-- 2) Validace emailu při OnValidate
INSERT INTO scripts (form_name, event_name, field_name, description, script_code, enabled, exec_order) VALUES
('CustomerEdit', 'OnValidate', 'email',
 'Email musí obsahovat @ a tečku v doménové části',
'var
  s: String;
  atPos, dotPos: Integer;
begin
  s := Trim(GetFieldStr(''email''));
  if s = '''' then Exit; // prázdný email je povolen
  atPos := Pos(''@'', s);
  dotPos := LastDelimiter(''.'', s);
  if (atPos < 2) or (dotPos <= atPos + 1) or (dotPos = Length(s)) then
    Fail(''Neplatný formát emailu'');
end.', 1, 100);

-- 3) Validace kódu zákazníka - povinně, formát "C" + 4 číslice
INSERT INTO scripts (form_name, event_name, field_name, description, script_code, enabled, exec_order) VALUES
('CustomerEdit', 'OnValidate', 'code',
 'Kód zákazníka musí být ve formátu Cxxxx',
'var
  s: String;
  i: Integer;
begin
  s := Trim(GetFieldStr(''code''));
  if Length(s) <> 5 then Fail(''Kód musí mít 5 znaků'');
  if UpperCase(Copy(s, 1, 1)) <> ''C'' then Fail(''Kód musí začínat písmenem C'');
  for i := 2 to 5 do
    if (s[i] < ''0'') or (s[i] > ''9'') then
      Fail(''Za písmenem C musí následovat 4 číslice'');
end.', 1, 100);

-- 4) OnBeforeSave - jméno se zkompaktní (trim, vícenásobné mezery)
INSERT INTO scripts (form_name, event_name, field_name, description, script_code, enabled, exec_order) VALUES
('CustomerEdit', 'OnBeforeSave', NULL,
 'Normalizace jména před uložením',
'var
  s: String;
begin
  s := Trim(GetFieldStr(''name''));
  while Pos(''  '', s) > 0 do
    s := StringReplace(s, ''  '', '' '', [rfReplaceAll]);
  if s = '''' then
    Cancel(''Jméno zákazníka je povinné.'');
  SetFieldStr(''name'', s);
end.', 1, 100);

-- 5) OnAfterLoad - doplnit poznámku pokud je prázdná u VIP
INSERT INTO scripts (form_name, event_name, field_name, description, script_code, enabled, exec_order) VALUES
('CustomerEdit', 'OnAfterLoad', NULL,
 'U VIP zákazníka bez poznámky nabídne výchozí text',
'begin
  if (GetFieldInt(''is_vip'') = 1) and (Trim(GetFieldStr(''notes'')) = '''') then
    SetFieldStr(''notes'', ''VIP zákazník - individuální podmínky'');
end.', 1, 200);
