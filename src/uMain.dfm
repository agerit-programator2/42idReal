object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = '42idReal - Sample scripting (Delphi + MariaDB)'
  ClientHeight = 520
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnNew: TButton
      Left = 8
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Nový'
      OnClick = btnNewClick
      TabOrder = 0
    end
    object btnEdit: TButton
      Left = 104
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Editovat'
      OnClick = btnEditClick
      TabOrder = 1
    end
    object btnDelete: TButton
      Left = 200
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Smazat'
      OnClick = btnDeleteClick
      TabOrder = 2
    end
    object btnRefresh: TButton
      Left = 296
      Top = 10
      Width = 90
      Height = 28
      Caption = 'Obnovit'
      OnClick = btnRefreshClick
      TabOrder = 3
    end
    object btnScripts: TButton
      Left = 792
      Top = 10
      Width = 100
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Scripty...'
      OnClick = btnScriptsClick
      TabOrder = 4
    end
  end
  object Grid: TDBGrid
    Left = 0
    Top = 48
    Width = 900
    Height = 453
    Align = alClient
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = [fsBold]
    OnDblClick = GridDblClick
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 501
    Width = 900
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end
