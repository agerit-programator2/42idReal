object frmScriptEditor: TfrmScriptEditor
  Left = 0
  Top = 0
  Caption = 'Editor scriptů'
  ClientHeight = 600
  ClientWidth = 1000
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
  object Splitter: TSplitter
    Left = 400
    Top = 0
    Width = 4
    Height = 541
    ExplicitLeft = 408
    ExplicitHeight = 600
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 541
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object Grid: TDBGrid
      Left = 0
      Top = 0
      Width = 400
      Height = 541
      Align = alClient
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -12
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = [fsBold]
    end
  end
  object pnlRight: TPanel
    Left = 404
    Top = 0
    Width = 596
    Height = 541
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblForm: TLabel
      Left = 16
      Top = 16
      Width = 50
      Height = 15
      Caption = 'Formulář'
    end
    object lblEvent: TLabel
      Left = 16
      Top = 48
      Width = 50
      Height = 15
      Caption = 'Event'
    end
    object lblField: TLabel
      Left = 16
      Top = 80
      Width = 50
      Height = 15
      Caption = 'Pole'
    end
    object lblDesc: TLabel
      Left = 16
      Top = 112
      Width = 50
      Height = 15
      Caption = 'Popis'
    end
    object lblOrder: TLabel
      Left = 16
      Top = 144
      Width = 50
      Height = 15
      Caption = 'Pořadí'
    end
    object lblCode: TLabel
      Left = 16
      Top = 180
      Width = 90
      Height = 15
      Caption = 'Tělo scriptu'
    end
    object edForm: TDBEdit
      Left = 130
      Top = 12
      Width = 200
      Height = 23
      TabOrder = 0
    end
    object cbEvent: TDBComboBox
      Left = 130
      Top = 44
      Width = 200
      Height = 23
      TabOrder = 1
    end
    object edField: TDBEdit
      Left = 130
      Top = 76
      Width = 200
      Height = 23
      TabOrder = 2
    end
    object edDesc: TDBEdit
      Left = 130
      Top = 108
      Width = 450
      Height = 23
      TabOrder = 3
    end
    object edOrder: TDBEdit
      Left = 130
      Top = 140
      Width = 80
      Height = 23
      TabOrder = 4
    end
    object chkEnabled: TDBCheckBox
      Left = 350
      Top = 12
      Width = 120
      Height = 22
      Caption = 'Aktivní'
      TabOrder = 5
      ValueChecked = '1'
      ValueUnchecked = '0'
    end
    object memCode: TDBMemo
      Left = 16
      Top = 200
      Width = 564
      Height = 325
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 6
      WordWrap = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 541
    Width = 1000
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnNew: TBitBtn
      Left = 8
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Nový'
      OnClick = btnNewClick
      TabOrder = 0
    end
    object btnSave: TBitBtn
      Left = 104
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Uložit'
      OnClick = btnSaveClick
      TabOrder = 1
    end
    object btnDelete: TBitBtn
      Left = 200
      Top = 6
      Width = 90
      Height = 28
      Caption = 'Smazat'
      OnClick = btnDeleteClick
      TabOrder = 2
    end
    object btnTest: TBitBtn
      Left = 296
      Top = 6
      Width = 140
      Height = 28
      Caption = 'Test kompilace'
      OnClick = btnTestClick
      TabOrder = 3
    end
    object btnClose: TBitBtn
      Left = 900
      Top = 6
      Width = 90
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Zavřít'
      OnClick = btnCloseClick
      TabOrder = 4
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 581
    Width = 1000
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ds: TDataSource
    Left = 960
    Top = 16
  end
end
