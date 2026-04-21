# 42idReal - Delphi + MariaDB sample: skriptování v IS

Ukázková aplikace pro testování **uživatelského scriptingu v informačním systému**.
Demonstruje, jak lze v IS přidávat vlastní scripty (uložené v databázi), které
ovlivňují chování formulářů - dopočty polí, validace, akce před uložením
záznamu - bez nutnosti rekompilovat aplikaci.

## Technologie

- **Delphi VCL** (testováno s Delphi 11/12; .dproj nastaven na 20.2)
- **FireDAC** pro připojení k **MariaDB / MySQL**
- **Pascal Script** (RemObjects) jako scriptovací engine
- **MariaDB 10.4+** (funguje i MySQL 8)

## Struktura repa

```
.
├── database/
│   ├── 01_schema.sql        # Schéma (customers, scripts, script_log)
│   └── 02_sample_data.sql   # Ukázkoví zákazníci a ukázkové scripty
├── src/
│   ├── idRealSample.dpr     # Hlavní projekt
│   ├── idRealSample.dproj
│   ├── uAppConfig.pas       # Načtení idreal.ini
│   ├── uDM.pas / .dfm       # Data modul - FireDAC, načítání scriptů, log
│   ├── uScriptEngine.pas    # Wrapper nad Pascal Scriptem
│   ├── uMain.pas / .dfm     # Seznam zákazníků
│   ├── uCustomerEdit.pas / .dfm   # Editace zákazníka + hooky scriptů
│   └── uScriptEditor.pas / .dfm   # Editor scriptů (CRUD tabulky scripts)
├── idreal.ini.sample        # Vzorové konfigurační údaje k DB
└── .gitignore
```

## Rychlý start

### 1) Databáze

```bash
mysql -u root -p < database/01_schema.sql
mysql -u root -p < database/02_sample_data.sql
```

### 2) Závislosti (Delphi)

Nainstalovat Pascal Script:

- https://github.com/remobjects/pascalscript
- Otevřít příslušný `.groupproj`, zkompilovat a nainstalovat design-time balíček
  (typicky `pscript_dXX.dpk`). Do *Library path* přidat adresář `Source/`.

FireDAC MySQL driver potřebuje `libmariadb.dll` / `libmysql.dll`. Buď ho
umístěte do adresáře s `.exe`, nebo do `PATH`, případně přesnou cestu uveďte
v `idreal.ini` -> `VendorLib`.

### 3) Konfigurace

Zkopírovat `idreal.ini.sample` vedle `idRealSample.exe` jako `idreal.ini`
a upravit přístupové údaje:

```ini
[Database]
Server=127.0.0.1
Port=3306
Database=idreal_demo
User=root
Password=secret
VendorLib=
```

### 4) Sestavení a spuštění

Otevřít `src/idRealSample.dproj` v Delphi, zkompilovat (F9).

## Jak scripting funguje

Scripty jsou uložené v tabulce `scripts`:

| Sloupec       | Význam                                                           |
|---------------|-------------------------------------------------------------------|
| `form_name`   | logický identifikátor formuláře (např. `CustomerEdit`)            |
| `event_name`  | `OnFieldChange` / `OnValidate` / `OnBeforeSave` / `OnAfterLoad`   |
| `field_name`  | název pole (pro `OnFieldChange` a `OnValidate`), jinak `NULL`     |
| `script_code` | vlastní tělo Pascal Scriptu                                       |
| `enabled`     | vypnutí bez mazání                                                |
| `exec_order`  | pořadí provedení pokud je na daný event více scriptů              |

Formulář `CustomerEdit` při práci s záznamem volá tyto eventy:

- **OnAfterLoad** - ihned po otevření / založení záznamu
- **OnFieldChange** - při opuštění editoru pole (`OnExit`)
- **OnValidate** - před uložením, volá se pro všechna pole s validačním scriptem
- **OnBeforeSave** - finální hook, může akci zrušit zavoláním `Cancel('...')`

### Funkce dostupné ve scriptech

```pascal
function  GetFieldStr  (const Name: string): string;
function  GetFieldInt  (const Name: string): Integer;
function  GetFieldFloat(const Name: string): Double;
function  GetFieldBool (const Name: string): Boolean;
procedure SetFieldStr  (const Name, Value: string);
procedure SetFieldInt  (const Name: string; Value: Integer);
procedure SetFieldFloat(const Name: string; Value: Double);
procedure SetFieldBool (const Name: string; Value: Boolean);
function  FieldIsNull  (const Name: string): Boolean;
procedure ClearField   (const Name: string);

procedure ShowMessage  (const Msg: string);
procedure ShowWarning  (const Msg: string);
procedure Cancel       (const Reason: string);  // zruší uložení / akci
procedure Fail         (const Reason: string);  // validační selhání
function  Now: TDateTime;
```

### Ukázka scriptu

OnFieldChange pro `credit_limit` - dopočte slevu a VIP příznak:

```pascal
var
  cl: Double;
begin
  cl := GetFieldFloat('credit_limit');
  if cl >= 200000 then
  begin
    SetFieldFloat('discount_percent', 10);
    SetFieldInt('is_vip', 1);
  end
  else if cl >= 50000 then
  begin
    SetFieldFloat('discount_percent', 5);
    SetFieldInt('is_vip', 0);
  end
  else
  begin
    SetFieldFloat('discount_percent', 0);
    SetFieldInt('is_vip', 0);
  end;
end.
```

OnValidate pro `email`:

```pascal
var
  s: String;
begin
  s := Trim(GetFieldStr('email'));
  if s = '' then Exit;
  if (Pos('@', s) < 2) or (LastDelimiter('.', s) <= Pos('@', s) + 1) then
    Fail('Neplatný formát emailu');
end.
```

## Úprava scriptů za běhu

V hlavním okně je tlačítko **Scripty...**, které otevře editor nad tabulkou
`scripts`. Změny se ukládají přímo do databáze a uplatní se hned při další
akci na formuláři - tzn. nové chování systému dostanete bez rekompilace.

## Logování

Každé spuštění scriptu se zapisuje do tabulky `script_log` (úspěch, text chyby,
časová značka). Pro ladění:

```sql
SELECT * FROM script_log ORDER BY created_at DESC LIMIT 50;
```
