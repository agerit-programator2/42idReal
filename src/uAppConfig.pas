unit uAppConfig;

{
  Jednoduchý config loader - čte connection parametry z idreal.ini
  vedle spustitelného souboru. Pokud soubor neexistuje, použijí
  se výchozí lokální hodnoty.

  idreal.ini (příklad):
    [Database]
    Server=127.0.0.1
    Port=3306
    Database=idreal_demo
    User=root
    Password=
}

interface

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

type
  TDbConfig = record
    Server: string;
    Port: Integer;
    Database: string;
    User: string;
    Password: string;
    VendorLib: string; // libmariadb.dll / libmysql.dll
  end;

function LoadDbConfig: TDbConfig;

implementation

function LoadDbConfig: TDbConfig;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  IniPath := ChangeFileExt(ParamStr(0), '.ini');
  if not TFile.Exists(IniPath) then
    IniPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'idreal.ini');

  IniFile := TIniFile.Create(IniPath);
  try
    Result.Server    := IniFile.ReadString('Database', 'Server',   '127.0.0.1');
    Result.Port      := IniFile.ReadInteger('Database', 'Port',    3306);
    Result.Database  := IniFile.ReadString('Database', 'Database', 'idreal_demo');
    Result.User      := IniFile.ReadString('Database', 'User',     'root');
    Result.Password  := IniFile.ReadString('Database', 'Password', '');
    Result.VendorLib := IniFile.ReadString('Database', 'VendorLib','');
  finally
    IniFile.Free;
  end;
end;

end.
