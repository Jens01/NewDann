object frmNewDann: TfrmNewDann
  Left = 0
  Top = 0
  Caption = 'Neural Networks'
  ClientHeight = 811
  ClientWidth = 1069
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
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    1069
    811)
  PixelsPerInch = 96
  TextHeight = 13
  object lblHeader: TLabel
    Left = 0
    Top = 0
    Width = 1069
    Height = 39
    Align = alTop
    Alignment = taCenter
    Caption = 'Testprogram - Neural Networks'
    DragCursor = crHandPoint
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -32
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Layout = tlCenter
    ExplicitWidth = 448
  end
  object lblHeader2: TLabel
    Left = 0
    Top = 39
    Width = 1069
    Height = 26
    Align = alTop
    Alignment = taCenter
    Caption = 
      'Author: Jens Biermann, An der Beeke 1, D-31636 Linsburg, jens-bi' +
      'ermann@gmx.net'#13#10'(Icon: sahua d/ thenounproject.com, OmniThreadLi' +
      'brary.com, Graphics32.org)'
    ExplicitWidth = 405
  end
  object grpDraw: TGroupBox
    Left = 611
    Top = 210
    Width = 129
    Height = 150
    Anchors = [akTop, akRight]
    Caption = 'Structure Options'
    TabOrder = 0
    object lblChangeActType: TLabel
      Left = 16
      Top = 75
      Width = 80
      Height = 26
      Caption = 'Change ActType'#13#10'of Neuron'
    end
    object btnRemove: TButton
      Left = 8
      Top = 18
      Width = 113
      Height = 41
      Caption = 'Remove'#13#10
      Enabled = False
      TabOrder = 0
      WordWrap = True
      OnClick = btnRemoveClick
    end
    object cbbthresholdOfNode: TComboBox
      Left = 16
      Top = 104
      Width = 105
      Height = 21
      Enabled = False
      TabOrder = 1
      Text = 'Sigmoid'
      OnChange = cbbthresholdOfNodeChange
    end
  end
  object pnlMain: TPanel
    Left = 211
    Top = 68
    Width = 394
    Height = 735
    Anchors = [akTop, akRight]
    ShowCaption = False
    TabOrder = 1
    object lblCount: TLabel
      Left = 25
      Top = 375
      Width = 11
      Height = 25
      Caption = '0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object pgcDann: TPageControl
      Left = 21
      Top = 25
      Width = 356
      Height = 330
      ActivePage = tsCreateNN
      TabOrder = 0
      object tsCreateNN: TTabSheet
        Caption = 'Create NN'
        object lblInputCount: TLabel
          Left = 102
          Top = 11
          Width = 65
          Height = 26
          Caption = 'Inputneurons'#13#10'Count'
        end
        object lblOutputNeuronsCount: TLabel
          Left = 102
          Top = 140
          Width = 73
          Height = 26
          Caption = 'Outputneurons'#13#10'Count'
        end
        object btnCreateNN: TButton
          Left = 32
          Top = 177
          Width = 249
          Height = 30
          Caption = 'Create NN'
          TabOrder = 0
          OnClick = btnCreateNNClick
        end
        object btnLoad: TButton
          Left = 32
          Top = 224
          Width = 75
          Height = 30
          Caption = 'Load'#13#10'Structure'
          TabOrder = 1
          WordWrap = True
          OnClick = btnLoadClick
        end
        object btnSave: TButton
          Left = 119
          Top = 224
          Width = 75
          Height = 30
          Caption = 'Save'#13#10'Structure'
          TabOrder = 2
          WordWrap = True
          OnClick = btnSaveClick
        end
        object edtInputCount: TSpinEdit
          Left = 21
          Top = 12
          Width = 75
          Height = 22
          MaxValue = 500
          MinValue = 1
          TabOrder = 3
          Value = 1
        end
        object edtOutputCount: TSpinEdit
          Left = 21
          Top = 141
          Width = 75
          Height = 22
          MaxValue = 500
          MinValue = 1
          TabOrder = 4
          Value = 1
        end
        object grpHiddenLayer: TGroupBox
          Left = 4
          Top = 43
          Width = 302
          Height = 91
          Caption = 'Hidden Layer'
          TabOrder = 5
          object lblNeuronCount: TLabel
            Left = 98
            Top = 28
            Width = 67
            Height = 13
            Caption = 'Neuron Count'
          end
          object lblLayerCount: TLabel
            Left = 98
            Top = 51
            Width = 57
            Height = 26
            Caption = 'Hiddenlayer'#13#10'Count'
          end
          object edtNeuronCount: TSpinEdit
            Left = 17
            Top = 24
            Width = 75
            Height = 22
            MaxValue = 500
            MinValue = 1
            TabOrder = 0
            Value = 3
          end
          object edtLayerCount: TSpinEdit
            Left = 17
            Top = 55
            Width = 75
            Height = 22
            MaxValue = 100
            MinValue = 0
            TabOrder = 1
            Value = 1
          end
          object cbbthreshold: TComboBox
            Left = 192
            Top = 24
            Width = 97
            Height = 21
            TabOrder = 2
            Text = 'Sigmoid'
          end
          object lblWikiThreshold: TLinkLabel
            Left = 200
            Top = 51
            Width = 78
            Height = 17
            Caption = '<A>Wiki Thresholds</A>'
            TabOrder = 3
            OnLinkClick = lblWikiThresholdLinkClick
          end
        end
        object btnExportStructure: TButton
          Left = 206
          Top = 224
          Width = 75
          Height = 30
          Caption = 'Export'#13#10'Structure'
          TabOrder = 6
          WordWrap = True
          OnClick = btnExportStructureClick
        end
      end
      object tsData: TTabSheet
        Caption = 'Data'
        ImageIndex = 2
        ExplicitLeft = 2
        object lblSeparator: TLabel
          Left = 136
          Top = 8
          Width = 48
          Height = 26
          Caption = 'CSV'#13#10'Separator'
        end
        object lblDataInfo: TLabel
          Left = 24
          Top = 58
          Width = 3
          Height = 13
        end
        object lblDecimalSeparator: TLabel
          Left = 216
          Top = 8
          Width = 48
          Height = 26
          Caption = 'Decimal-'#13#10'Separator'
        end
        object mmoData: TMemo
          Left = 24
          Top = 75
          Width = 313
          Height = 214
          Lines.Strings = (
            '#?;1; 1; 0'
            '#*?;0; 1; 1'
            '1; 0; 1'
            '#*?;0; 0; 0')
          ScrollBars = ssBoth
          TabOrder = 0
          OnChange = mmoDataChange
        end
        object edtSeparator: TEdit
          Left = 136
          Top = 37
          Width = 45
          Height = 21
          MaxLength = 3
          TabOrder = 1
          Text = ';'
          OnChange = edtSeparatorChange
        end
        object btnLoadData: TButton
          Left = 26
          Top = 7
          Width = 75
          Height = 50
          Caption = 'Load'#13#10'CSV Data'
          TabOrder = 2
          WordWrap = True
          OnClick = btnLoadDataClick
        end
        object edtDecimalSeparator: TEdit
          Left = 216
          Top = 37
          Width = 45
          Height = 21
          MaxLength = 1
          TabOrder = 3
          Text = '.'
          OnChange = edtDecimalSeparatorChange
        end
      end
      object tsTrainNN: TTabSheet
        Caption = 'Train NN'
        ImageIndex = 1
        object lblError: TLabel
          Left = 162
          Top = 19
          Width = 51
          Height = 13
          Caption = 'Train Error'
        end
        object lblWeightLambda: TLabel
          Left = 162
          Top = 65
          Width = 74
          Height = 13
          Caption = 'Weight Lambda'
        end
        object lblMEBreak: TLabel
          Left = 162
          Top = 111
          Width = 107
          Height = 13
          Caption = 'Error Break Difference'
        end
        object btnTrainBackPropOnline: TButton
          Left = 22
          Top = 220
          Width = 75
          Height = 40
          Caption = 'Train'#13#10'BackPROP'#13#10'Online'
          Enabled = False
          TabOrder = 0
          WordWrap = True
          OnClick = btnTrainBackPropOnlineClick
        end
        object btnTrainBackpropBatch: TButton
          Left = 115
          Top = 220
          Width = 75
          Height = 40
          Caption = 'Train'#13#10'BackPROP'#13#10'Batch'
          Enabled = False
          TabOrder = 1
          WordWrap = True
          OnClick = btnTrainBackpropBatchClick
        end
        object btnTrainRPROP: TButton
          Left = 206
          Top = 220
          Width = 75
          Height = 75
          Caption = 'Train'#13#10'RPROP'
          TabOrder = 2
          WordWrap = True
          OnClick = btnTrainRPROPClick
        end
        object edtMSE: TEdit
          Left = 160
          Top = 36
          Width = 113
          Height = 21
          TabOrder = 3
          Text = '0.001'
        end
        object btnBreak: TButton
          Left = 18
          Top = 164
          Width = 75
          Height = 25
          Caption = 'break'
          DoubleBuffered = True
          ParentDoubleBuffered = False
          TabOrder = 4
          OnClick = btnBreakClick
        end
        object btnSetWeights: TButton
          Left = 111
          Top = 164
          Width = 75
          Height = 25
          Caption = 'SetWeights'
          TabOrder = 5
          OnClick = btnSetWeightsClick
        end
        object btnCleanWeights: TButton
          Left = 206
          Top = 162
          Width = 75
          Height = 25
          Caption = 'Clean Weights'
          TabOrder = 6
          WordWrap = True
          OnClick = btnCleanWeightsClick
        end
        object rgWeightError: TRadioGroup
          Left = 24
          Top = 32
          Width = 113
          Height = 81
          Caption = 'Weight Error'
          Items.Strings = (
            'None'
            'WeighttFunc1'
            'WeighttFunc2')
          TabOrder = 7
          OnClick = rgWeightErrorClick
        end
        object edtWeightLambda: TEdit
          Left = 162
          Top = 81
          Width = 113
          Height = 21
          TabOrder = 8
          Text = 'edtWeightLambda'
          OnChange = edtWeightLambdaChange
        end
        object edtMSEDifference: TEdit
          Left = 162
          Top = 127
          Width = 113
          Height = 21
          TabOrder = 9
          OnChange = edtMSEDifferenceChange
        end
      end
      object tsTest: TTabSheet
        Caption = 'Test NN'
        ImageIndex = 3
        object lblTestResult: TLabel
          Left = 72
          Top = 112
          Width = 81
          Height = 23
          Caption = 'Testresult'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object btnTest: TButton
          Left = 72
          Top = 40
          Width = 75
          Height = 25
          Caption = 'Test NN'
          TabOrder = 0
          OnClick = btnTestClick
        end
      end
    end
  end
  object mmoMSE: TMemo
    Left = 0
    Top = 65
    Width = 208
    Height = 746
    Align = alLeft
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  inline frmGraph: TfrmGraph
    Left = 746
    Top = 65
    Width = 323
    Height = 746
    Align = alRight
    TabOrder = 3
    ExplicitLeft = 746
    ExplicitTop = 65
    ExplicitWidth = 323
    ExplicitHeight = 746
    inherited imgStructure: TImage32
      Width = 323
      Height = 617
      BitmapAlign = baCenter
      ExplicitWidth = 323
      ExplicitHeight = 617
    end
    inherited pnlMenu: TPanel
      Width = 323
      ExplicitWidth = 323
      DesignSize = (
        323
        129)
    end
  end
  object dlgData: TOpenTextFileDialog
    DefaultExt = 'CSV'
    Filter = 'CSV|*.CSV'
    Title = 'Load Data'
    Left = 576
    Top = 608
  end
  object dlgExportStructure: TSaveTextFileDialog
    DefaultExt = 'XML'
    Filter = 'XML|*.XML'
    Title = 'Save Structure'
    Left = 656
    Top = 608
  end
  object dlgOpenStructure: TFileOpenDialog
    DefaultExtension = '*.XML'
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 632
    Top = 512
  end
end
