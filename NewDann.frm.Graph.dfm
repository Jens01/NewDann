object frmGraph: TfrmGraph
  Left = 0
  Top = 0
  Width = 491
  Height = 603
  TabOrder = 0
  object imgStructure: TImage32
    Left = 0
    Top = 129
    Width = 491
    Height = 474
    Align = alClient
    Bitmap.ResamplerClassName = 'TNearestResampler'
    BitmapAlign = baTopLeft
    Scale = 1.000000000000000000
    ScaleMode = smNormal
    TabOrder = 0
    OnClick = imgStructureClick
    OnGDIOverlay = imgStructureGDIOverlay
    OnMouseDown = imgStructureMouseDown
    OnResize = imgStructureResize
  end
  object pnlMenu: TPanel
    Left = 0
    Top = 0
    Width = 491
    Height = 129
    Align = alTop
    BevelOuter = bvNone
    Caption = 'pnlMenu'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      491
      129)
    object lblClickInfo: TLabel
      Left = 23
      Top = 30
      Width = 150
      Height = 13
      Caption = 'Ctrl + Click -> select Nodelayer'
    end
    object chkWeights: TCheckBox
      Left = 23
      Top = 10
      Width = 94
      Height = 17
      Caption = 'Draw Weights'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = chkWeightsClick
    end
    object chkDrawValue: TCheckBox
      Left = 123
      Top = 10
      Width = 75
      Height = 17
      Caption = 'Draw Value'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = chkDrawValueClick
    end
    object edtLine: TSpinEdit
      Left = 204
      Top = 8
      Width = 75
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 2
      Value = 2
      OnChange = edtLineChange
    end
    object lstInfo: TListBox
      Left = 23
      Top = 48
      Width = 458
      Height = 75
      Anchors = [akLeft, akTop, akRight, akBottom]
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      ItemHeight = 13
      ParentColor = True
      TabOrder = 3
    end
  end
end
