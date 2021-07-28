object perBandForm: TperBandForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Set LO values per Band'
  ClientHeight = 304
  ClientWidth = 248
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 248
    Height = 263
    Align = alClient
    TabOrder = 0
    object kvgBandLOValues: TValueListEditor
      Left = 1
      Top = 1
      Width = 246
      Height = 261
      Align = alClient
      DropDownRows = 9
      FixedColor = clBtnShadow
      FixedCols = 1
      KeyOptions = [keyEdit]
      TabOrder = 0
      TitleCaptions.Strings = (
        'Band'
        'LO frequency')
      OnKeyPress = kvgBandLOValuesKeyPress
      ColWidths = (
        55
        185)
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 263
    Width = 248
    Height = 41
    Align = alBottom
    TabOrder = 1
    object Button1: TButton
      Left = 8
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 158
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = Button2Click
    end
  end
end
