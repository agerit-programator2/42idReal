object frmCustomerEdit: TfrmCustomerEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Editace zákazníka'
  ClientHeight = 460
  ClientWidth = 520
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object lblCode: TLabel
    Left = 24
    Top = 20
    Width = 50
    Height = 15
    Caption = 'Kód'
  end
  object lblName: TLabel
    Left = 24
    Top = 52
    Width = 50
    Height = 15
    Caption = 'Jméno'
  end
  object lblEmail: TLabel
    Left = 24
    Top = 84
    Width = 50
    Height = 15
    Caption = 'Email'
  end
  object lblPhone: TLabel
    Left = 24
    Top = 116
    Width = 50
    Height = 15
    Caption = 'Telefon'
  end
  object lblCredit: TLabel
    Left = 24
    Top = 148
    Width = 90
    Height = 15
    Caption = 'Credit limit'
  end
  object lblDiscount: TLabel
    Left = 24
    Top = 180
    Width = 90
    Height = 15
    Caption = 'Sleva [%]'
  end
  object lblOrders: TLabel
    Left = 24
    Top = 212
    Width = 90
    Height = 15
    Caption = 'Počet objednávek'
  end
  object lblNotes: TLabel
    Left = 24
    Top = 276
    Width = 50
    Height = 15
    Caption = 'Poznámka'
  end
  object edCode: TDBEdit
    Left = 140
    Top = 16
    Width = 120
    Height = 23
    TabOrder = 0
  end
  object edName: TDBEdit
    Left = 140
    Top = 48
    Width = 360
    Height = 23
    TabOrder = 1
  end
  object edEmail: TDBEdit
    Left = 140
    Top = 80
    Width = 360
    Height = 23
    TabOrder = 2
  end
  object edPhone: TDBEdit
    Left = 140
    Top = 112
    Width = 200
    Height = 23
    TabOrder = 3
  end
  object edCreditLimit: TDBEdit
    Left = 140
    Top = 144
    Width = 160
    Height = 23
    TabOrder = 4
  end
  object edDiscount: TDBEdit
    Left = 140
    Top = 176
    Width = 160
    Height = 23
    TabOrder = 5
  end
  object edOrders: TDBEdit
    Left = 140
    Top = 208
    Width = 160
    Height = 23
    TabOrder = 6
  end
  object chkVip: TDBCheckBox
    Left = 140
    Top = 240
    Width = 160
    Height = 22
    Caption = 'VIP zákazník'
    TabOrder = 7
    ValueChecked = '1'
    ValueUnchecked = '0'
  end
  object memNotes: TDBMemo
    Left = 140
    Top = 272
    Width = 360
    Height = 120
    TabOrder = 8
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 412
    Width = 520
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 9
    object btnOK: TBitBtn
      Left = 320
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Uložit'
      Default = True
      OnClick = btnOKClick
      TabOrder = 0
    end
    object btnCancel: TBitBtn
      Left = 416
      Top = 10
      Width = 90
      Height = 28
      Cancel = True
      Caption = 'Storno'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object dsEdit: TDataSource
    Left = 448
    Top = 16
  end
end
