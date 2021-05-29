object frmRunner: TfrmRunner
  Left = 0
  Top = 0
  Caption = 'Neural Networks Runner'
  ClientHeight = 610
  ClientWidth = 762
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Icon.Data = {
    0000010001001010000001002000680400001600000028000000100000002000
    0000010020000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000F00000018000000030000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    00000000002E00000092000000A80000002D0000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000050000
    002F00000099000000650000009D0000003B0000000000000000000000000000
    000000000000000000000000000000000014000000370000005C000000820000
    009F0000005B0000002F000000AE0000005A0000001700000000000000000000
    000000000000000000010000003E000000970000009800000079000000600000
    002800000033000000BD000000F6000000EB000000B30000002D000000000000
    0000000000150000004C000000AA000000650000005D00000036000000840000
    002700000044000000E4000000FF000000FF000000FD00000090000000060000
    00310000009500000096000000AE000000630000007D000000580000004E0000
    00570000004100000063000000BD000000EA000000F9000000C1000000210000
    009B0000005F0000002D0000003B000000890000006300000040000000570000
    003A00000043000000510000003F000000460000007500000099000000920000
    00BC000000380000008A0000003A0000001F00000063000000710000002B0000
    004900000045000000370000008A000000400000007F00000055000000BD0000
    00AA000000300000003800000059000000440000001C0000004C0000005F0000
    0025000000480000002E00000024000000530000005500000041000000A70000
    006C0000007E000000720000006F0000004100000058000000410000004E0000
    002B0000002D0000004700000026000000830000002E0000007E000000680000
    001C00000094000000770000004600000057000000490000004E0000004C0000
    004E0000003300000065000000790000002700000060000000950000001B0000
    00000000002A00000095000000770000003A000000380000004F000000760000
    0052000000890000003A0000004E00000078000000950000002B000000000000
    0000000000000000001D000000770000009B000000600000003A000000700000
    003A0000004E0000006A0000009B000000780000001E00000000000000000000
    0000000000000000000000000008000000360000007B0000009A000000A00000
    009E000000980000007600000035000000080000000000000000000000000000
    00000000000000000000000000000000000000000004000000130000001F0000
    001D00000010000000030000000000000000000000000000000000000000FFC7
    0000FF870000FE070000F0030000C00100008000000000000000000000000000
    000000000000000000000000000080010000C0030000E0070000F81F0000}
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    762
    610)
  PixelsPerInch = 96
  TextHeight = 13
  inline frmGraph: TfrmGraph
    Left = 456
    Top = 0
    Width = 306
    Height = 610
    Align = alRight
    TabOrder = 0
    ExplicitLeft = 456
    ExplicitWidth = 306
    ExplicitHeight = 610
    inherited imgStructure: TImage32
      Width = 306
      Height = 481
      ExplicitWidth = 306
      ExplicitHeight = 481
    end
    inherited pnlMenu: TPanel
      Width = 306
      ExplicitWidth = 306
      inherited lblClickInfo: TLabel
        Margins.Bottom = 0
      end
      inherited lstInfo: TListBox
        Width = 273
        ExplicitWidth = 273
      end
    end
  end
  object grdData: TStringGrid
    Left = 0
    Top = 172
    Width = 450
    Height = 438
    Anchors = [akLeft, akTop, akRight, akBottom]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
    ParentColor = True
    TabOrder = 1
  end
  object btnRun: TButton
    Left = 16
    Top = 8
    Width = 417
    Height = 41
    Caption = 'Run'
    TabOrder = 2
    OnClick = btnRunClick
  end
  object btnBreak: TButton
    Left = 184
    Top = 55
    Width = 75
    Height = 25
    Caption = 'Break'
    Enabled = False
    TabOrder = 3
    OnClick = btnBreakClick
  end
  object pnlMenu: TPanel
    Left = 0
    Top = 86
    Width = 450
    Height = 80
    Caption = 'pnlMenu'
    ShowCaption = False
    TabOrder = 4
    object lblSeparator: TLabel
      Left = 8
      Top = 15
      Width = 48
      Height = 26
      Alignment = taCenter
      Caption = 'CSV'#13#10'Separator'
    end
    object lblDecimalSeparator: TLabel
      Left = 65
      Top = 15
      Width = 48
      Height = 26
      Alignment = taCenter
      Caption = 'Decimal-'#13#10'Separator'
    end
    object edtSeparator: TEdit
      Left = 8
      Top = 47
      Width = 45
      Height = 21
      MaxLength = 3
      TabOrder = 0
      Text = ';'
      OnChange = edtSeparatorChange
    end
    object edtDecimalSeparator: TEdit
      Left = 65
      Top = 47
      Width = 45
      Height = 21
      MaxLength = 1
      TabOrder = 1
      Text = '.'
      OnChange = edtDecimalSeparatorChange
    end
    object btnLoadCSV: TButton
      Left = 133
      Top = 15
      Width = 52
      Height = 50
      Caption = 'Load'#13#10'CSV'
      TabOrder = 2
      WordWrap = True
      OnClick = btnLoadCSVClick
    end
    object btnSaveCSV: TButton
      Left = 191
      Top = 15
      Width = 50
      Height = 50
      Caption = 'Save'#13#10'CSV'
      TabOrder = 3
      WordWrap = True
      OnClick = btnSaveCSVClick
    end
    object btnLoadStructure: TButton
      Left = 260
      Top = 15
      Width = 57
      Height = 50
      Caption = 'Load'#13#10'Structure'
      TabOrder = 4
      WordWrap = True
      OnClick = btnLoadStructureClick
    end
    object btnClearGrid: TButton
      Left = 384
      Top = 15
      Width = 41
      Height = 50
      Caption = 'Clear'#13#10'Grid'
      TabOrder = 5
      WordWrap = True
      OnClick = btnClearGridClick
    end
  end
  object dlgData: TOpenTextFileDialog
    DefaultExt = 'CSV'
    Filter = 'CSV|*.CSV'
    Title = 'Load Data'
    Left = 368
    Top = 574
  end
  object dlgStructure: TOpenTextFileDialog
    DefaultExt = 'XML'
    Filter = 'XML|*.XML'
    Title = 'Load Structure'
    Left = 408
    Top = 568
  end
  object dlgSaveData: TSaveTextFileDialog
    DefaultExt = 'CSV'
    Filter = 'CSV|*.CSV'
    Left = 464
    Top = 568
  end
end
