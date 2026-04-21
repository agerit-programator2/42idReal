object DM: TDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 240
  Width = 420
  object Connection: TFDConnection
    LoginPrompt = False
    Left = 48
    Top = 24
  end
  object DrvMySQL: TFDPhysMySQLDriverLink
    Left = 48
    Top = 88
  end
  object WaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 48
    Top = 152
  end
  object qCustomers: TFDQuery
    Connection = Connection
    Left = 200
    Top = 24
  end
  object dsCustomers: TDataSource
    DataSet = qCustomers
    Left = 200
    Top = 88
  end
  object qScripts: TFDQuery
    Connection = Connection
    Left = 320
    Top = 24
  end
end
