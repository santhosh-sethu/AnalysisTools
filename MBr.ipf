#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///////////////////////////////////////////////////////////////////////
////////////////////////MATRIX BROWSER/////////////////////////////////
Menu "Analysis"
	SubMenu "Packages"
		"Matrix Browser", /Q, MBrOpen()
	End
End

Function MBrOpen()
	DoWindow MBr
	If(!V_flag)
		InitializeMBr()
	EndIf
End

Function InitializeMBr()
	If(!DataFolderExists("root:Packages:MBr"))
		NewDataFolder root:Packages:MBr
	EndIf
	SetDataFolder root:Packages:MBr
	
	NewPanel/N=MBr/W=(300,0,1200,450)/K=1 as "Matrix Browser"

	ModifyPanel/W=MBr fixedSize=0
	SetWindow MBr sizeLimit = {900,450,inf,inf}
	MBr_BuildControls()
End

Function InitializeMBrfromFUNC(left,top)
	Variable left,top
	
	If(!DataFolderExists("root:Packages:MBr"))
		NewDataFolder root:Packages:MBr
	EndIf
	SetDataFolder root:Packages:MBr
	NewPanel/N=MBr/W=(left,top,left+900,top+450)/K=1 as "Matrix Browser"
	ModifyPanel/W=MBr fixedSize=0
	SetWindow MBr sizeLimit = {900,450,inf,inf}
	MBr_BuildControls()
End

Function LoadMBr_Items()
	If(!DataFolderExists("root:Packages:MBr"))
		NewDataFolder root:Packages:MBr
	EndIf
	SetDataFolder root:Packages:MBr
	
	//Make package waves
	Make/O/T/N=1 root:Packages:MBr:folderTable
	Make/O/T/N=1 root:Packages:MBr:waveListTable
	
	String/G root:Packages:MBr:errorStr
	SVAR errorStr = root:Packages:MBr:errorStr
	
	String/G root:Packages:MBr:MatrixOPList
	SVAR MatrixOPList = root:Packages:MBr:MatrixOPList
	MatrixOPList = "Average;Avg Graph;-----;Max Proj;Transpose;-----;Avg Cols;Avg Rows;Extract Cols;Extract Rows;Get Row Slice;Get Col Slice;Get Layer;Get Beam;Concat Cols;-----;Empty Slice Cache"
	
	String/G root:Packages:MBr:outWaveStr
	String/G root:Packages:MBr:cmdStr
	SVAR cmdStr = root:Packages:MBr:cmdStr
	
	String/G recoveryWaveStr = "root:Packages:MBr:recoveryWave"
	
	String/G root:Packages:MBr:currentDataFolder
	SVAR cdf = root:Packages:MBr:currentDataFolder

	Variable/G root:Packages:MBr:selFolder
	NVAR selFolder= root:Packages:MBr:selFolder
	selFolder = 0
	
	String/G root:Packages:MBr:selWaveList
	SVAR selWaveList = root:Packages:MBr:selWaveList
	selWaveList = ""
	
	String/G root:Packages:MBr:matchStr
	SVAR matchStr = root:Packages:MBr:matchStr
	matchStr = "*"
	String/G root:Packages:MBr:notMatchStr
	SVAR notMatchStr = root:Packages:MBr:notMatchStr
	notMatchStr = ""
		
	Make/O/N=1 root:Packages:MBr:selWave
	Wave selWave = root:Packages:MBr:selWave
	
	Variable/G root:Packages:MBr:timeRef
	Variable/G root:Packages:MBr:mouseDown
	NVAR mouseDown = root:Packages:MBr:mouseDown
	mouseDown = 0
	
	Variable/G root:Packages:MBr:mouseOnEdge
	NVAR mouseOnEdge = root:Packages:MBr:mouseOnEdge
	mouseOnEdge = 0
	Variable/G root:Packages:MBr:resizingEdge
	NVAR resizingEdge = root:Packages:MBr:resizingEdge
	resizingEdge = 0
	
	Make/O/N=4096 root:Packages:MBr:imageHist
	
	//sequence of mouse down/up events to detect drag and drop from a list box
	String/G root:Packages:MBr:eventSequence
	SVAR eventSequence=root:Packages:MBr:eventSequence
	eventSequence = ""
	
	Variable/G root:Packages:MBr:selectedRow
	String/G root:Packages:MBr:selectedWave
	String/G root:Packages:MBr:selectedWaveDisplayStr
	SVAR selectedWaveDisplayStr = root:Packages:MBr:selectedWaveDisplayStr
	SVAR selectedWave = root:Packages:MBr:selectedWave
	selectedWave = ""
	selectedWaveDisplayStr = ""
	
	Variable/G root:Packages:MBr:viewerOpen
	NVAR viewerOpen = root:Packages:MBr:viewerOpen
	viewerOpen = 0 
	Variable/G root:Packages:MBr:MBr_Value
	
	//Additional parameter panel variables
	Variable/G root:Packages:MBr:pRow
	NVAR pRow =  root:Packages:MBr:pRow
	Variable/G root:Packages:MBr:pColumn
	NVAR pColumn =  root:Packages:MBr:pColumn
	Variable/G root:Packages:MBr:pLayer
	NVAR pLayer =  root:Packages:MBr:pLayer
	Variable/G root:Packages:MBr:pRadius
	NVAR pRadius =  root:Packages:MBr:pRadius
	pRow = 0;pColumn=0;pLayer=0;pRadius=1
	String/G root:Packages:MBr:pColumnRange
	SVAR pColumnRange=root:Packages:MBr:pColumnRange
	pColumnRange = ""
	String/G root:Packages:MBr:pRowRange
	SVAR pRowRange=root:Packages:MBr:pRowRange
	pRowRange = ""
	
	//Clipboard panel variables
	Make/O/T/N=1 root:Packages:MBr:clipboardListWave
	Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
	clipboardListWave = ""
	Variable/G root:Packages:MBr:useClipboard
	NVAR useClipboard = root:Packages:MBr:useClipboard
	useClipboard = 0
	
	//Wave to hold the matrix slice and layers
	Make/O/N=10 root:Packages:MBr:sliceWave
	Make/O/N=(10,10,1) root:Packages:MBr:layerWave
	Variable/G root:Packages:MBr:horSize
	Variable/G root:Packages:MBr:vertSize
	Variable/G root:Packages:MBr:depthSize
	Variable/G root:Packages:MBr:beamRadius
	NVAR beamRadius = root:Packages:MBr:beamRadius
	beamRadius = 10
	
	//Slider
	Variable/G root:Packages:MBr:play
	NVAR play = root:Packages:MBr:play
	play = 0
	Variable/G root:Packages:MBr:sliderPos
	NVAR sliderPos = root:Packages:MBr:sliderPos
	String/G root:Packages:MBr:sliderPosStr
	SVAR sliderPosStr = root:Packages:MBr:sliderPosStr
	Variable depth = 1
	sliderPos = 1
	sliderPosStr = num2str(sliderPos) + "/" + num2str(depth)
	
	//Histogram waves
	Make/O/N=2 root:Packages:MBr:histLeftX
	Make/O/N=2 root:Packages:MBr:histRightX
	Make/O/N=2 root:Packages:MBr:histLeftY = {0,inf}
	Make/O/N=2 root:Packages:MBr:histRightY = {0,inf}
	Make/O/N=65536 root:Packages:MBr:imageHist
	
End

Function MBr_BuildControls()
	STRUCT WMWinHookStruct s
	//Make package waves
	
	If(!DataFolderExists("root:Packages:MBr"))
		NewDataFolder root:Packages:MBr
	EndIf
	
	Make/O/T/N=1 root:Packages:MBr:folderTable
	Make/O/T/N=1 root:Packages:MBr:waveListTable
	
	String/G root:Packages:MBr:errorStr
	SVAR errorStr = root:Packages:MBr:errorStr
	
	String/G root:Packages:MBr:MatrixOPList
	SVAR MatrixOPList = root:Packages:MBr:MatrixOPList
	MatrixOPList = "Average;Avg Graph;-----;Max Proj;Transpose;-----;Avg Cols;Avg Rows;Extract Cols;Extract Rows;Get Row Slice;Get Col Slice;Get Layer;Get Beam;Concat Cols;-----;Empty Slice Cache"
	
	String/G root:Packages:MBr:outWaveStr
	String/G root:Packages:MBr:cmdStr
	SVAR cmdStr = root:Packages:MBr:cmdStr
	
	String/G recoveryWaveStr = "root:Packages:MBr:recoveryWave"
	
	String/G root:Packages:MBr:currentDataFolder
	SVAR cdf = root:Packages:MBr:currentDataFolder

	Variable/G root:Packages:MBr:selFolder
	NVAR selFolder= root:Packages:MBr:selFolder
	selFolder = 0
	
	String/G root:Packages:MBr:selWaveList
	SVAR selWaveList = root:Packages:MBr:selWaveList
	selWaveList = ""
	
	String/G root:Packages:MBr:matchStr
	SVAR matchStr = root:Packages:MBr:matchStr
	matchStr = "*"
	String/G root:Packages:MBr:notMatchStr
	SVAR notMatchStr = root:Packages:MBr:notMatchStr
	notMatchStr = ""
		
	Make/O/N=1 root:Packages:MBr:selWave
	Wave selWave = root:Packages:MBr:selWave
	
	Variable/G root:Packages:MBr:timeRef
	Variable/G root:Packages:MBr:mouseDown
	NVAR mouseDown = root:Packages:MBr:mouseDown
	mouseDown = 0
	
	Variable/G root:Packages:MBr:mouseOnEdge
	NVAR mouseOnEdge = root:Packages:MBr:mouseOnEdge
	mouseOnEdge = 0
	Variable/G root:Packages:MBr:resizingEdge
	NVAR resizingEdge = root:Packages:MBr:resizingEdge
	resizingEdge = 0
	
	Make/O/N=4096 root:Packages:MBr:imageHist
	
	//sequence of mouse down/up events to detect drag and drop from a list box
	String/G root:Packages:MBr:eventSequence
	SVAR eventSequence=root:Packages:MBr:eventSequence
	eventSequence = ""
	
	Variable/G root:Packages:MBr:selectedRow
	String/G root:Packages:MBr:selectedWave
	String/G root:Packages:MBr:selectedWaveDisplayStr
	SVAR selectedWaveDisplayStr = root:Packages:MBr:selectedWaveDisplayStr
	SVAR selectedWave = root:Packages:MBr:selectedWave
	selectedWave = ""
	selectedWaveDisplayStr = ""
	
	Variable/G root:Packages:MBr:viewerOpen
	NVAR viewerOpen = root:Packages:MBr:viewerOpen
	viewerOpen = 0 
	Variable/G root:Packages:MBr:MBr_Value
	
	//Additional parameter panel variables
	Variable/G root:Packages:MBr:pRow
	NVAR pRow =  root:Packages:MBr:pRow
	Variable/G root:Packages:MBr:pColumn
	NVAR pColumn =  root:Packages:MBr:pColumn
	Variable/G root:Packages:MBr:pLayer
	NVAR pLayer =  root:Packages:MBr:pLayer
	Variable/G root:Packages:MBr:pRadius
	NVAR pRadius =  root:Packages:MBr:pRadius
	pRow = 0;pColumn=0;pLayer=0;pRadius=1
	String/G root:Packages:MBr:pColumnRange
	SVAR pColumnRange=root:Packages:MBr:pColumnRange
	pColumnRange = ""
	String/G root:Packages:MBr:pRowRange
	SVAR pRowRange=root:Packages:MBr:pRowRange
	pRowRange = ""
	
	//Clipboard panel variables
	Make/O/T/N=1 root:Packages:MBr:clipboardListWave
	Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
	clipboardListWave = ""
	Variable/G root:Packages:MBr:useClipboard
	NVAR useClipboard = root:Packages:MBr:useClipboard
	useClipboard = 0
	
	//Wave to hold the matrix slice and layers
	Make/O/N=10 root:Packages:MBr:sliceWave
	Make/O/N=(10,10,1) root:Packages:MBr:layerWave
	Variable/G root:Packages:MBr:horSize
	Variable/G root:Packages:MBr:vertSize
	Variable/G root:Packages:MBr:depthSize
	Variable/G root:Packages:MBr:beamRadius
	NVAR beamRadius = root:Packages:MBr:beamRadius
	beamRadius = 10
	
	//Slider
	Variable/G root:Packages:MBr:play
	NVAR play = root:Packages:MBr:play
	play = 0
	Variable/G root:Packages:MBr:sliderPos
	NVAR sliderPos = root:Packages:MBr:sliderPos
	String/G root:Packages:MBr:sliderPosStr
	SVAR sliderPosStr = root:Packages:MBr:sliderPosStr
	Variable depth = 1
	sliderPos = 1
	sliderPosStr = num2str(sliderPos) + "/" + num2str(depth)
	
	//Histogram waves
	Make/O/N=2 root:Packages:MBr:histLeftX
	Make/O/N=2 root:Packages:MBr:histRightX
	Make/O/N=2 root:Packages:MBr:histLeftY = {0,inf}
	Make/O/N=2 root:Packages:MBr:histRightY = {0,inf}
	Make/O/N=65536 root:Packages:MBr:imageHist
	
	SetDataFolder root:
	
	//Define guides
	DefineGuide/W=MBr LG={FL,350},RG={FR,-100},TG={FT,40},MG={FB,-56}//MG={TG,0.6,FB}
	DefineGuide/W=MBr MControlGuide={TG,125}
	DefineGuide/W=MBr	BControlGuide={MG,43}
	DefineGuide/W=MBr BParameterGuide={TG,200}
	DefineGuide/W=MBr BClipboardGuide={TG,400}
	
	//Folder list box
	Wave/T folderTable = MBr_GetFolderListItems()
	ListBox MBr_FolderListBox win=MBr,pos={5,40},size={150,355},frame=0,fsize=10,mode=2,listWave=folderTable,selRow=selFolder,proc=MBr_ListBoxProc
	
	//Item list box
	Wave/T waveListTable = MBr_GetFolderItems()
	ListBox MBr_ItemListBox win=MBr,pos={165,40},size={175,355},frame=0,fsize=10,focusRing=0,mode=4,listWave=waveListTable,selWave=selWave,proc=MBr_ListBoxProc
	
	//Navigation controls
	Button MBr_NavBack win=MBr,pos={5,18},size={40,20},title="Back",proc=MBr_ButtonProc
	SetVariable MBr_cdf win=MBr,pos={52,20},size={200,20},fsize=10,value=cdf,title=" ",disable=2,frame=0
	Button MBr_DeleteWave win=MBr,pos={290,18},size={50,20},title="Delete",proc=MBr_ButtonProc
	SetVariable MBr_match win=MBr,pos={165,402},size={150,20},frame=1,fsize=10,value=matchStr,title="Match",proc=MBr_SetVariableProc
	SetVariable MBr_notMatch win=MBr,pos={165,422},size={150,20},frame=1,fsize=10,value=notMatchStr,title="Not",proc=MBr_SetVariableProc
	
	//Graph Window
	Display/HOST=MBr/N=MBrGraph/FG=(LG,TG,RG,MG)
	SetVariable MBr_selectedWave win=MBr,pos={365,20},size={200,20},fsize=10,value=selectedWaveDisplayStr,title=" ",disable=2,frame=0

	//Graph Window Controls
	NewPanel/HOST=MBr/FG=(LG,MG,RG,FB)/N=BottomControlPanel
	ModifyPanel/W=MBr#BottomControlPanel frameStyle=0 
	Button MBr_AutoScale win=MBr#BottomControlPanel,pos={3,1},size={35,20},title="AUTO",fsize=8,proc=MBr_ButtonProc
	Button MBr_playMovie win=MBr#BottomControlPanel,pos={40,1},size={20,20},title="  \\W549>",fSize=12,disable=1,proc=MBr_ButtonProc
	Slider MBr_Slider win=MBr#BottomControlPanel,pos={65,1},size={350,20},vert=0,ticks=0,value=sliderPos,disable=1,proc=MBr_SliderProc
	SetVariable MBr_WhichLayer win=MBr#BottomControlPanel,pos={420,3},size={40,20},live=1,frame=0,disable=1,title=" ",value=sliderPosStr
	PopUpMenu MBr_ColorPalette win=MBr#BottomControlPanel,pos={3,23},bodywidth=125,disable=1,value="*COLORTABLEPOP*",proc=MBr_PopUpProc

	
	//Matrix Controls
	NewPanel/HOST=MBr/FG=(RG,TG,FR,MControlGuide)/N=MatrixControlPanel as "Matrix Controls"
	ModifyPanel/W=MBr#MatrixControlPanel frameStyle=0
	Button MBr_MatrixViewer win=MBr#MatrixControlPanel,pos={8,0},size={84,20},title="Slice View",proc=MBr_ButtonProc
	GroupBox MBr_SliceControlGroupBox win=MBr#MatrixControlPanel,pos={3,20},size={92,2}
	CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,pos={11,23},size={20,20},title="Hor",disable=1,proc=MBr_CheckProc
	CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,pos={51,23},size={20,20},title="Vert",disable=1,proc=MBr_CheckProc
	CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,pos={11,43},size={30,20},title="Beam",disable=1,proc=MBr_CheckProc
	SetVariable MBr_BeamRadius win=MBr#MatrixControlPanel,pos={60,43},size={30,20},title= " ",value=beamRadius,disable=1
	
	SetDrawEnv/W=MBr#MatrixControlPanel xcoord= abs,ycoord= abs,textxjust= 1,textyjust= 1,fsize=12
	DrawText/W=MBr#MatrixControlPanel 50,75,"Matrix OPs"
	PopUpMenu MBr_MatrixPopUp win=MBr#MatrixControlPanel,pos={8,83},size={84,20},bodyWidth=84,title=" ",value=#"root:Packages:MBr:MatrixOPList",proc=MBr_PopUpProc
	cmdStr = GetCmdStr()
		
	Button MBr_Run win=MBr#MatrixControlPanel,pos={8,103},size={40,20},title= "Run",proc=MBr_ButtonProc
	Button MBr_Undo win=MBr#MatrixControlPanel,pos={53,103},size={40,20},title= "Undo",proc=MBr_ButtonProc
	
	//Matrix Parameters Panel
	NewPanel/HOST=MBr/N=ParameterPanel/FG=(RG,MControlGuide,FR,BParameterGuide)
	ModifyPanel/W=MBr#ParameterPanel,frameStyle=0
	GroupBox ParameterGroupBox win=MBr#ParameterPanel,pos={5,3},size={92,2}
	
	//Clipboard controls
	NewPanel/HOST=MBr/N=ClipboardPanel/FG=(RG,BParameterGuide,FR,BClipboardGuide)
	ModifyPanel/W=MBr#ClipboardPanel,frameStyle=0
	Button MBr_WaveClipboardButton win=MBr#ClipboardPanel,pos={12,3},size={75,20},title="Clipboard",proc=MBr_ButtonProc
	Button MBr_ClearClipboardButton win=MBr#ClipboardPanel,pos={13,23},size={75,20},title="Clear",proc=MBr_ButtonProc
	ListBox MBr_WaveClipboardListBox win=MBr#ClipboardPanel,pos={6,46},size={90,105},frame=0,listWave=root:Packages:MBr:clipboardListWave,mode=0
	
	//Set window hooks
	SetWindow MBr,hook(resizeHook) = MBr_ResizeHook
End

Function MBr_ResizeHook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	
	switch(s.eventCode)
		case 0://activate
			break
		case 1://deactivate
			break
		case 6://resize
			GetWindow MBr wsize
			ListBox MBr_ItemListBox win=MBr,size={175,V_bottom - V_top - 95}
			ListBox MBr_FolderListBox win=MBr,size={150,V_bottom - V_top - 95}
			SetVariable MBr_match win=MBr,pos={165,V_bottom - V_top - 48}
			SetVariable MBr_notMatch win=MBr,pos={165,V_bottom - V_top - 28}
			ControlUpdate MBr_ItemListBox
			ControlUpdate MBr_FolderListBox
			break
	endswitch
	
End

Function/S GetCmdStr()
	SVAR cmdStr = root:Packages:MBr:cmdStr
	SVAR matrixOPList = root:Packages:MBr:matrixOPList
	Variable i,listItem
	SVAR selectedWave = root:Packages:MBr:selectedWave
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	SVAR outWaveStr = root:Packages:MBr:outWaveStr
	SVAR errorStr = root:Packages:MBr:errorStr
	String tempWaveStr
	SVAR whichList = root:Packages:analysisTools:whichList
	
	//If(cmpstr(whichList,"Browser"))
		ControlInfo/W=MBr#MatrixControlPanel MBr_MatrixPopUp
	//ElseIf(cmpstr(whichList,"AT"))
	//	S_Value = "Transpose"
	//EndIf
	If(!strlen(S_Value))
		S_Value = "Transpose"
	EndIf
	
	strswitch(S_value)
		case "Transpose":
			cmdStr = "MatrixTranspose " + cdf + selectedWave
			break
		case "Avg Cols":
			outWaveStr = cdf + selectedWave + "_avgCol"
			cmdStr = "MatrixOP/O " + outWaveStr + " = averageCols(" + cdf + selectedWave + ")"
			cmdStr += ";MatrixTranspose " + outWaveStr
			cmdStr += ";Redimension/N=(-1,0,0)" + outWaveStr
			break
		case "Avg Rows":
			outWaveStr = cdf + selectedWave + "_avgRow"
			tempWaveStr = "root:Packages:MBr:tempWave"
			//transpose so we can use average col command
			cmdStr = "MatrixTranspose " + cdf + selectedWave
			cmdStr += ";MatrixOP/O " + outWaveStr + " = averageCols(" + cdf + selectedWave + ")"
			cmdStr += ";MatrixTranspose " + outWaveStr
			cmdStr += ";Redimension/N=(-1,0,0)" + outWaveStr
			//transpose back to original format
			cmdStr += ";MatrixTranspose " + cdf + selectedWave
			break	
		case "Get Col Slice":
			//Layers become rows in this manipulation
			ControlInfo /W=MBr#ParameterPanel pColumn
			If(V_flag > 0)
				If(DimSize($selectedWave,2) > 0)
					outWaveStr = cdf + selectedWave + "_col" + num2str(V_Value)
					cmdStr = "MatrixOP/O " + outWaveStr + "=col(" + cdf + selectedWave + "," + num2str(V_Value) + ")"
					cmdStr +=";MatrixOP/O temp = transposeVol(" + outWaveStr + ",2)"
					cmdStr +=";Duplicate/O temp," + outWaveStr
					cmdStr +=";SetScale/P y,DimOffset(" + cdf + selectedWave + ",0),DimDelta(" + cdf + selectedWave + ",0)," + outWaveStr
					cmdStr +=";KillWaves/Z temp"
				Else
					cmdStr = "error:dim3"
				EndIf
			Else
				errorStr = "Must enter column index"
			EndIf
			break
		case "Get Row Slice":
			//Layers become rows in this manipulation
			ControlInfo /W=MBr#ParameterPanel pRow
			If(V_flag > 0)
				If(DimSize($selectedWave,2) > 0)
					outWaveStr = cdf + selectedWave + "_row" + num2str(V_Value)
					cmdStr = "MatrixOP/O " + outWaveStr + "=row(" + cdf + selectedWave + "," + num2str(V_Value-1) + ")"
					cmdStr +=";MatrixOP/O temp = transposeVol(" + outWaveStr + ",3)"
					cmdStr +=";Duplicate/O temp," + outWaveStr
					cmdStr +=";SetScale/P y,DimOffset(" + cdf + selectedWave + ",1),DimDelta(" + cdf + selectedWave + ",1)," + outWaveStr
					cmdStr +=";KillWaves/Z temp"
				Else
					cmdStr = "error:dim3"
				EndIf
			Else
				errorStr = "Must enter row index"
			EndIf
			break
		case "Get Layer":
			ControlInfo /W=MBr#ParameterPanel pLayer
			If(V_flag > 0)
				If(DimSize($selectedWave,0) > 0 && DimSize($selectedWave,1) > 1)
					outWaveStr = cdf + selectedWave + "_lay" + num2str(V_Value+1)
					cmdStr = "MatrixOP/O " + outWaveStr + "=layer(" + cdf + selectedWave + "," + num2str(V_Value-1) + ")"
					cmdStr +=";SetScale/P x,DimOffset(" + cdf + selectedWave + ",0),DimDelta(" + cdf + selectedWave + ",0)," + outWaveStr
					cmdStr +=";SetScale/P y,DimOffset(" + cdf + selectedWave + ",1),DimDelta(" + cdf + selectedWave + ",1)," + outWaveStr
				Else
					cmdStr = "error:dim2"
				EndIf
			Else
				errorStr = "Must enter layer index"
			EndIf
			
			break
		case "Get Beam":
			//Test for each parameter input
			ControlInfo /W=MBr#ParameterPanel pColumn
			If(V_flag > 0)
				Variable c = V_Value
				ControlInfo /W=MBr#ParameterPanel pRow
				If(V_flag > 0)
					Variable r = V_Value
					ControlInfo /W=MBr#ParameterPanel pLayer
					If(V_flag < 0)
						Variable rad = 1	//default
					Else
						outWaveStr = cdf + selectedWave + UniqueName("_beam",1,0)
						If(rad == 1)
							cmdStr = "MatrixOP/O" + outWaveStr + "=beam(" + cdf + selectedWave + "," + num2str(r) + "," + num2str(c) + ")"
						Else
							cmdStr = "GetBeamAvg(origWave,xPos,yPos,beamRadius,outWaveStr)"
						EndIf
					EndIf
				Else
					errorStr = "Must enter row index"
				EndIf
			Else
				errorStr = "Must enter column index"
			EndIf
			break
		case "Max Proj":
			outWaveStr = cdf + selectedWave + "_MProj"
			cmdStr = "MatrixOP/O " + outWaveStr + "= sumBeams(" + cdf + selectedWave + ")"
			cmdStr +=";SetScale/P x,DimOffset(" + cdf + selectedWave + ",0),DimDelta(" + cdf + selectedWave + ",0)," + outWaveStr
			cmdStr +=";SetScale/P y,DimOffset(" + cdf + selectedWave + ",1),DimDelta(" + cdf + selectedWave + ",1)," + outWaveStr
			break
		case "Max Cols":
			outWaveStr = cdf + selectedWave + "_MCol"
			cmdStr = "MatrixOP/O" + outWaveStr + "=maxCols(" + cdf + selectedWave + ")"
			break
		case "Max Rows":	
			outWaveStr = cdf + selectedWave + "_MRow"	
			cmdStr = "MatrixOP/O" + outWaveStr + "=maxRows(" + cdf + selectedWave + ")"
			break
		case "Extract Cols":
			cmdStr = "print \"Extracting columns...\""
			break
		case "Extract Rows":
			cmdStr = "print \"Extracting rows...\""
			break	
		case "Concat Cols":
			cmdStr = "print \"Concatenating columns...\""
			break
		case "Empty Slice Cache":
			SetDataFolder root:Packages:MBr
			String sliceCache = RemoveEnding(WaveList("savedSlice*",",",""),",")
			If(!strlen(sliceCache))
				sliceCache = "none"
			EndIf
			cmdStr = "KillWaves/Z " + sliceCache
			outWaveStr = ""
			SetDataFolder cdf
		case "Average":
			cmdStr = "avgSelectedWaves(" + "\"" + selWaveList + "\"" + ",2)" + "/CB"
			break
		case "Avg Graph":
			String tracesOnGraph = TraceNameList("MBr#MBrGraph",";",1)
			For(i=0;i<ItemsInList(tracesOnGraph,";");i+=1)
				Wave theWave = TraceNameToWaveRef("MBr#MBrGraph",StringFromList(i,tracesOnGraph,";"))
				tracesOnGraph = ReplaceString(StringFromList(i,tracesOnGraph,";"),tracesOnGraph,GetWavesDataFolder(theWave,2))
			EndFor
			cmdStr = "avgSelectedWaves(" + "\"" + tracesOnGraph + "\"" + ")"
	endswitch

	return cmdStr
End

Function MBr_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR cdf = root:Packages:MBr:currentDataFolder
	NVAR viewerOpen = root:Packages:MBr:viewerOpen
	SVAR selectedWave = root:Packages:MBr:selectedWave
	Wave theWave = $selectedWave
	Wave layerWave =  root:Packages:MBr:layerWave
	
	SVAR cmdStr = root:Packages:MBr:cmdStr
	SVAR outWaveStr = root:Packages:MBr:outWaveStr
	NVAR play = root:Packages:MBr:play
	String traceList
	
	SVAR recoveryWaveStr = root:Packages:MBr:recoveryWaveStr
	If(!SVAR_Exists(recoveryWaveStr))
		String/G root:Packages:MBr:recoveryWaveStr
		recoveryWaveStr = ""
	EndIf
	
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			strswitch(ba.ctrlName)
				case "atBrowseBackButton":
				case "MBr_NavBack":
					String parentDF = ParseFilePath(1,cdf,":",1,0)
					SetDataFolder parentDF
					cdf = parentDF
					MBr_GetFolderListItems()
					MBr_GetFolderItems()
					ControlUpdate MBr_cdf
					break
				case "MBr_DeleteWave":
					//consider making tracelist a global string that is passed to this function 
					//and updated every time a new wave is added to the graph
					If(DimSize($selectedWave,1) > 1)
						traceList = ImageNameList("MBr#MBrGraph",";")
					Else
						traceList = TraceNameList("MBr#MBrGraph",";",1)
					EndIf
					
						
					//Kills the slice viewer
					KillWindow/Z MBr#ViewerPanel
					DrawAction/L=UserFront/W=MBr#MBrGraph delete
					CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,Value=0,disable=1
					CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,Value=0,disable=1
					CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,Value=0,disable=1
					SetVariable MBr_BeamRadius win=MBr#MatrixControlPanel,disable=1
					animateControlDrop("MBr_SliceControlGroupBox","MBr#MatrixControlPanel",2,0.1)
					viewerOpen = 0
					
					If(numtype(WhichListItem(selectedWave,traceList,";")) == 0)
						KillWindow/Z MBr#MBrGraph
					EndIf
					KillWaves/Z $selectedWave
					MBr_GetFolderListItems()
					MBr_GetFolderItems()
				
					
					break
				case "MBr_MatrixViewer":
					If(!viewerOpen)
						MBr_SetUpViewer()
						viewerOpen = 1
					Else
						//Resize panel and reset guides
						DefineGuide/W=MBr MG={FB,-56}
						GetWindow MBr wsize
						MoveWindow/W=MBr V_left,V_top,V_right,V_bottom-200
						
						KillWindow/Z MBr#ViewerPanel
						DrawAction/L=UserFront/W=MBr#MBrGraph delete
						CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,Value=0,disable=1
						CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,Value=0,disable=1
						CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,Value=0,disable=1
						SetVariable MBr_BeamRadius win=MBr#MatrixControlPanel,disable=1
						animateControlDrop("MBr_SliceControlGroupBox","MBr#MatrixControlPanel",2,0.1)
						viewerOpen = 0
					EndIf
					break
				case "MBr_Run":
					//Standard command execution
					If(StringMatch(cmdStr,"error*"))
						ResolveErrorCode(cmdStr)
					Else
						If(WaveExists(theWave))
							If(strlen(recoveryWaveStr))
								Duplicate/O theWave,$recoveryWaveStr
							EndIf
							//Resolve clipboad flag
							If(StringMatch(cmdStr,"*/CB"))
								NVAR useClipboard = root:Packages:MBr:useClipboard
								useClipboard = 1
								cmdStr = ReplaceString("/CB",cmdStr,"")
							Else
								useClipboard = 0
							EndIf
							
							Execute cmdStr
							If(WaveExists($outWaveStr))
							//can be uncommented to display new waves or not.
								If(DimSize($outWaveStr,1) > 1)
									//NewImage $outWaveStr
								Else
									//Display $outWaveStr
								EndIf
							EndIf
							outWaveStr = ""
						EndIf
					
						//Special case, this will work without a wave selected
						ControlInfo/W=MBr#MatrixControlPanel MBr_MatrixPopUp
						If(cmpstr(S_value,"Empty Slice Cache") == 0)
							KillWindow/Z sliceGraph
							SetDataFolder root:Packages:MBr
							Execute/Z cmdStr
							SetDataFolder cdf
						ElseIf(cmpstr(S_value,"Extract Cols") == 0)
							ExtractColumns(selectedWave)
						ElseIf(cmpstr(S_value,"Extract Rows") == 0)	
							ExtractRows(selectedWave)
						ElseIf(cmpstr(S_value,"Concat Cols") == 0)
							ConcatCols(selectedWave)
						EndIf
					EndIf
					break
				case "MBr_Undo":
					If(WaveExists($recoveryWaveStr))
						Duplicate/O $recoveryWaveStr,theWave
					EndIf
					break
				case "MBr_AutoScale":
					SetAxis/W=MBr#MBrGraph/A
					break
				case "MBr_playMovie":
					If(play == 0)
						//starts movie as background task
						CtrlNamedBackground movie,period=10,start,proc=advanceMovieFrame
						Button MBr_playMovie win=MBr#BottomControlPanel,title="   \\W516>"
						play = 1
					ElseIf(play == 1)
						//stops movie 
						CtrlNamedBackground movie,stop,proc=advanceMovieFrame
						Button MBr_playMovie win=MBr#BottomControlPanel,title="  \\W549>"
						play = 0
					EndIf
					break	
				case "MBr_WaveClipboardButton":
					Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
					Variable size = DimSize(clipboardListWave,0)
					//Add another row and another wave
					If(size == 1 && !strlen(clipboardListWave[0]))
						clipboardListWave[0] = cdf + selectedWave
					Else
						Redimension/N=(size+1) clipboardListWave
						clipboardListWave[size] = cdf + selectedWave
					EndIf
					break
				case "MBr_ClearClipboardButton":
					NVAR useClipboard = root:Packages:MBr:useClipboard
					Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
					Redimension/N=1 clipboardListWave
					clipboardListWave = ""
					useClipboard = 0
					break
			endswitch
			//Update folder and item lists
			MBr_GetFolderListItems()
			MBr_GetFolderItems()
			
			break
		case -1: // control being killed
			break
	endswitch
	//Update cmdStr after running command in case wave lists have changed. 
	GetCmdStr()
	return 0
End

Function MBr_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	Wave sliceWave = root:Packages:MBr:sliceWave
	Wave layerWave = root:Packages:MBr:layerWave
	NVAR depthSize = root:Packages:MBr:depthSize
	NVAR horSize = root:Packages:MBr:horSize
	NVAR vertSize = root:Packages:MBr:vertSize
	SVAR selectedWave = root:Packages:MBr:selectedWave
	Variable xPos,yPos,yMin,yMax,xMin,xMax
	NVAR beamRadius = root:Packages:MBr:beamRadius
	
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			strswitch(cba.ctrlName)
				case "MBr_ViewerHorCheck":
					CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,value=0
					CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,value=0

					If(WaveExists($selectedWave))
						
						//Get the selected wave
						If(depthSize)
							Wave theWave = layerWave
							SetScale/P x,DimOffset($selectedWave,0),DimDelta($selectedWave,0),WaveUnits($selectedWave,0),layerWave
							SetScale/P y,DimOffset($selectedWave,1),DimDelta($selectedWave,1),WaveUnits($selectedWave,1),layerWave
						Else
							Wave theWave = $selectedWave
						EndIf
						
						//Check if the wave has the correct dimensionality for the slice
						//Otherwise it displays a single value in a valDisplay instead of showing the graph
					//	If(DimSize(theWave,1) == 1)
					//		switchViewer(1)
					//	Else
					//		switchViewer(0)
					//	EndIf
						
						//Get axis position for horizontal slice
						DrawAction/L=UserFront/W=MBr#MBrGraph delete
						GetAxis/Q/W=MBr#MBrGraph bottom
						xMin=V_min;xMax=V_max
						GetAxis/Q/W=MBr#MBrGraph left
						yMin=V_min;yMax=V_max
							
						//Append the slice indicator line onto the graph
						yPos = IndexToScale(theWave,ScaleToIndex(theWave,0.5*(yMax + yMin),1),1)	//snaps to data indices
						SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,linethick=1,linefgc=(0,65535,65535)
						DrawLine/W=MBr#MBrGraph xMin,yPos,xMax,yPos
						
						yPos = ScaleToIndex(theWave,yPos,1)
						If(yPos < DimSize(theWave,1) && yPos >= 0)
							Redimension/N=(DimSize(theWave,0)) sliceWave
							SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),WaveUnits(theWave,0),sliceWave	
							sliceWave[] = theWave[p][yPos]	
						EndIf
					EndIf
					break
				case "MBr_ViewerVertCheck":
					CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,value=0
					CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,value=0
					
					If(WaveExists($selectedWave))
						
						//Get the selected wave
						If(depthSize)
							Wave theWave = layerWave
							SetScale/P x,DimOffset($selectedWave,0),DimDelta($selectedWave,0),WaveUnits(theWave,0),layerWave
							SetScale/P y,DimOffset($selectedWave,1),DimDelta($selectedWave,1),WaveUnits(theWave,1),layerWave
						Else
							Wave theWave = $selectedWave
						EndIf
						
						//Check if the wave has the correct dimensionality for the slice
						//Otherwise it displays a single value in a valDisplay instead of showing the graph
					//	If(DimSize(theWave,0) == 1)
					//		switchViewer(1)
					//	Else
					//		switchViewer(0)
					//	EndIf
						
						
						//Get axis position for vertical slice
						DrawAction/L=UserFront/W=MBr#MBrGraph delete
						GetAxis/Q/W=MBr#MBrGraph left
						yMin=V_min;yMax=V_max
						GetAxis/Q/W=MBr#MBrGraph bottom
						xMin=V_min;xMax=V_max
						xPos = 0.5*(xMax + xMin)
						
						//Append the slice indicator line onto the graph
						xPos = IndexToScale(theWave,ScaleToIndex(theWave,xPos,0),0) //snaps to data indices
						SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,linethick=1,linefgc=(0,65535,65535)
						DrawLine/W=MBr#MBrGraph xPos,yMin,xPos,yMax	
						
						xPos = ScaleToIndex(theWave,xPos,0)
						//Check that the index conversion is in range
						If(xPos < DimSize(theWave,0) && xPos >= 0)
							SetScale/P x,DimOffset(theWave,1),DimDelta(theWave,1),WaveUnits(theWave,1),sliceWave	
							MatrixOP/O sliceWave = row(theWave,xPos)
							MatrixTranspose sliceWave
						EndIf
					EndIf
					break
				case "MBr_ViewerBeamCheck":
					CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,value=0
					CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,value=0
		
					If(WaveExists($selectedWave))
				
						Wave theWave = $selectedWave
						
						//Check if the wave has the correct dimensionality for the slice
						//Otherwise it displays a single value in a valDisplay instead of showing the graph
					//	If(DimSize(theWave,2) == 1)
					//		switchViewer(1)
					//	Else
					//		switchViewer(0)
					//	EndIf
						
						
						SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),WaveUnits(theWave,0),layerWave
						SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),WaveUnits(theWave,1),layerWave
						
						depthSize = DimSize(theWave,2)
						//Make sure slice wave gets redimensioned correctly
						If(depthSize)
							Redimension/N=(depthSize) sliceWave
						Else
							Redimension/N=1 sliceWave
						EndIf
						
						//Get center of axes for beam start point
						GetAxis/Q/W=MBr#MBrGraph left
						yMin=V_min;yMax=V_max
						GetAxis/Q/W=MBr#MBrGraph bottom
						xMin=V_min;xMax=V_max
						//Get index from scale
						xPos = ScaleToIndex(theWave,0.5*(xMin + xMax),0)
						yPos = ScaleToIndex(theWave,0.5*(yMin + yMax),1)
						//Get beam at X/Y coordinates
						
						
						wave sliceWave = GetBeamAvg(theWave,xPos,yPos,beamRadius)
					
						SetScale x,DimOffset(theWave,2),DimDelta(theWave,2),WaveUnits(theWave,2),sliceWave
					
					EndIf
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MBr_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	NVAR sliderPos = root:Packages:MBr:sliderPos
	Wave layerWave = root:Packages:MBr:layerWave
	NVAR depthSize = root:Packages:MBr:depthSize
	SVAR selectedWave = root:Packages:MBr:selectedWave
	Wave theWave = $selectedWave
	SVAR sliderPosStr = root:Packages:MBr:sliderPosStr
	
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				sliderPos = curval
				If(sliderPos <= depthSize && sliderPos >=0)
					layerWave[][][] = theWave[p][q][sliderPos]
					sliderPosStr = num2str(sliderPos+1) + "/" + num2str(depthSize)
					ControlUpdate MBr_WhichLayer
				EndIf
			endif
			break
	endswitch

	return 0
End

Function MBr_PopUpProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SVAR cmdStr = root:Packages:MBr:cmdStr
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			strswitch(pa.ctrlName)
				case "MBr_MatrixPopUp":
					cmdStr = GetCmdStr()
					ResetParameterPanel(popStr)
					break
				case "MBr_ColorPalette":
					String imagesOnGraph = ImageNameList("MBr#MBrGraph",";")
					If(ItemsInList(imagesOnGraph,";") == 0)
						break
					Else
						String theImage = StringFromList(0,imagesOnGraph,";")
					EndIf
					ModifyImage/W=MBr#MBrGraph $theImage ctab={*,*,$popStr,0} 
					break
			endswitch
		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MBr_SetVariableProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			strswitch(sva.ctrlName)
				case "AT_match":
				case "MBr_match":
					MBr_GetFolderItems()
					break
				case "AT_notMatch":
				case "MBr_notMatch":
					MBr_GetFolderItems()
					break
				case "waveMatch":
					getWaveMatchList()
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Changes mouse to a different icon for different actions
Function SetMouse(s,code)
	STRUCT WMWinHookStruct &s
	Variable code
	//make sure code range is valid
	if (code < 0)
		code = 0
	endif
	if (code > 32)
		code = 32
	endif
	
	s.doSetCursor = 1
	s.cursorCode = code
End


//Animates resizing of group box in the control panel
Function animateControlDrop(ctrlName,ctrlWin,height,duration)
	String ctrlName,ctrlWin
	Variable height,duration
	Variable i,pauseTime,currentSize,steps,startTime,currentTime,elapsedTime
	
	ControlInfo/W=$ctrlWin $ctrlName
	steps = ceil(0.25*(height - V_height))	//for step size of 4
	pauseTime = abs(duration/steps)
	currentSize = V_height
	
	For(i=0;i<abs(steps);i+=1)
		If(steps > 0)
			currentSize +=4
		Else
			currentSize -=4
		EndIf
		GroupBox $ctrlName win=$ctrlWin,pos={V_left,V_top},size={V_width,currentSize}
		startTime = ticks
		Do
			currentTime = ticks
			elapsedTime = currentTime - startTime
		While(elapsedTime < pauseTime)
		ControlUpdate/W=$ctrlWin $ctrlName 
	EndFor	
End

Function/WAVE GetBeamAvg(origWave,xPos,yPos,beamRadius[,passOutputName])
	Wave origWave
	Variable xPos,yPos,beamRadius
	String passOutputName
	Variable size = DimSize(origWave,2)
	Variable i,j,xStart,yStart,xEnd,yEnd
	NVAR horSize = root:Packages:MBr:horSize
	NVAR vertSize = root:Packages:MBr:vertSize
	NVAR depthSize = root:Packages:MBr:depthSize
	Wave sliceWave = root:Packages:MBr:sliceWave

	horSize = DimSize(origWave,0)
	vertSize = DimSize(origWave,1)
	depthSize = DimSize(origWave,2)
	
	
	//Dimension boundary checks
	xStart = xPos - beamRadius
	yStart = yPos - beamRadius
	xEnd = xPos + beamRadius
	yEnd = yPos + beamRadius
	
	If(yStart < 0)
		yStart = 0
	EndIf
	
	If(xStart < 0)
		xStart = 0
	EndIf
	
	If(xEnd >= horSize)
		xEnd = horSize -1
	EndIf
	
	If(yEnd >= vertSize)
		yEnd = vertSize -1
	EndIf
		
	If(ParamIsDefault(passOutputName))
		If(NumType(yStart) == 2 || NumType(yEnd) == 2|| NumType(xStart) == 2 || NumType(xEnd) == 2)
			return sliceWave
		EndIf
		
		If(beamRadius == 0)
			Make/FREE/N=(1,1) beamAvg,num
		Else
			Make/FREE/N=(xEnd - xStart,yEnd - yStart) beamAvg,num
		EndIf
		
		beamAvg = 0
	
		If(depthSize > 0)
			For(i=0;i<depthSize;i+=1)
				beamAvg = origWave[p + xStart][q + yStart][i]
				sliceWave[i] = mean(beamAvg)	
			EndFor
		Else
			beamAvg = origWave[p + xStart][q + yStart][i]
			num = (NumType(beamAvg) != 2) ? 1 : 0
			Variable totalNums = sum(num)
			MatrixOP/O beamAvg = replaceNaNs(beamAvg,0)
			sliceWave[i] = sum(beamAvg)/totalNums
		EndIf
		return sliceWave
		
	Else
	//passOutputName is the string output wave name to hold the beam average
	//it indicates that the call is coming from the paramater panel
		Make/O/N=(depthSize) $passOutputName
		Wave outWave = $passOutputName
		
		If(beamRadius == 0)
			Make/FREE/N=(1,1) beamAvg,num
		Else
			Make/FREE/N=(xEnd - xStart,yEnd - yStart) beamAvg,num
		EndIf
		
		For(i=0;i<depthSize;i+=1)
			beamAvg = origWave[p + xStart][q + yStart][i]
			outWave[i] = mean(beamAvg)	
		EndFor
		return outWave
	EndIf

End

Function MBr_SetUpViewer()
	Wave sliceWave = root:Packages:MBr:sliceWave
	SVAR selectedWave = root:Packages:MBr:selectedWave
	NVAR MBr_Value = root:Packages:MBr:MBr_Value
	
	If(WaveExists($selectedWave))
		Wave theWave = $selectedWave
	Else
		return 0
	EndIf
	Variable yMin,yMax,xMin,xMax,xPos,yPos
	
	If(!strlen(TraceNameList("MBr#MBrGraph",";",1)) && !strlen(ImageNameList("MBr#MBrGraph",";")))
		return 0
	EndIf
	
	
	//Make viewer panel
	GetWindow MBr wsize
	MoveWindow/W=MBr V_left,V_top,V_right,V_bottom+200
	DefineGuide/W=MBr MG={FB,-256}
	NewPanel/HOST=MBr/FG=(LG,BControlGuide,RG,FB)/N=ViewerPanel as "Viewer Panel"
	ModifyPanel/W=MBr#ViewerPanel frameStyle=0
	
	//only displays graph if their is a 2D or higher wave selected, otherwise it sets of a value display
	Display/HOST=MBr#ViewerPanel/FG=(FL,FT,FR,FB)/N=ViewerGraph sliceWave
	ModifyGraph/W=MBr#ViewerPanel#ViewerGraph margin(left)=60,margin(right)=60
	//Reveal slice check boxes
	animateControlDrop("MBr_SliceControlGroupBox","MBr#MatrixControlPanel",43,0.1)
	CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,disable=0
	CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,disable=0
	CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,disable=0
	SetVariable MBr_BeamRadius win=MBr#MatrixControlPanel,disable=0
	
	//Get axis boundaries and draw cross section lines
	SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,linethick=1,linefgc=(0,65535,65535)
	GetAxis/Q/W=MBr#MBrGraph left
	yMin=V_min;yMax=V_max
	GetAxis/Q/W=MBr#MBrGraph bottom
	xMin=V_min;xMax=V_max
	DrawLine/W=MBr#MBrGraph xMin,0.5*(yMax+yMin),xMax,0.5*(yMax+yMin)
	
	//Set horizontal slice check box as default
	CheckBox MBr_ViewerHorCheck win=MBr#MatrixControlPanel,Value=1
	CheckBox MBr_ViewerVertCheck win=MBr#MatrixControlPanel,Value=0
	CheckBox MBr_ViewerBeamCheck win=MBr#MatrixControlPanel,Value=0
	
	//Append slice wave to the viewer graph
	If(DimSize($selectedWave,1) > 0 || DimSize($selectedWave,2) > 0)
		Redimension/N=(DimSize(theWave,0)) sliceWave
		AppendToGraph/W=MBr#ViewerPanel#ViewerGraph sliceWave
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0), sliceWave
	EndIf
	
	//Set window hook function for cross section viewing
	SetWindow MBr hook(sliceHook)=MBr_SliceHook,hookevents=1
	
End

Function switchViewer(whichOne)
	Variable whichOne
	Wave sliceWave = root:Packages:MBr:sliceWave
	NVAR MBr_Value = root:Packages:MBr:MBr_Value
//0 opens the graph
//1 opens the valDisplay
	If(whichOne == 0)
		KillControl/W=MBr#ViewerPanel MBr_ValueViewer
		Display/HOST=MBr#ViewerPanel/FG=(FL,FT,FR,FB)/N=ViewerGraph sliceWave
	Else
		KillWindow/Z MBr#ViewerGraph
		ValDisplay/Z MBr_ValueViewer win=MBr#ViewerPanel,pos={50,50},size={50,50},fsize=20,frame=0,fstyle=0,value=_NUM:MBr_Value
	EndIf
End

Function MBr_SliceHook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	Variable xPos,yPos,yMin,yMax,xMin,xMax
	NVAR horSize = root:Packages:MBr:horSize
	NVAR vertSize = root:Packages:MBr:vertSize
	NVAR depthSize = root:Packages:MBr:depthSize
	Wave layerWave = root:Packages:MBr:layerWave
	Wave sliceWave = root:Packages:MBr:sliceWave
	SVAR selectedWave = root:Packages:MBr:selectedWave
	NVAR beamRadius = root:Packages:MBr:beamRadius
	NVAR timeRef = root:Packages:MBr:timeRef
	SVAR cdf = root:Packages:MBr:currentDataFolder
	NVAR MBr_Value = root:Packages:MBr:MBr_Value
	
	If(WaveExists($selectedWave))
		If(depthSize)
			Wave theWave = layerWave
			Wave origWave = $selectedWave
		Else
			Wave origWave = $selectedWave
			Wave theWave = $selectedWave
		EndIf
	EndIf
	
	switch(s.eventCode)
		case 0://activate
			break
		case 1://deactivate
			break
		
		case 4://mouse moved
		//Redraws the slice indicator
			If(cmpstr(s.winname,"MBr#MBrGraph") == 0)
				DrawAction/L=UserFront/W=MBr#MBrGraph delete
				GetAxis/Q/W=MBr#MBrGraph left
				yMin=V_min;yMax=V_max
				GetAxis/Q/W=MBr#MBrGraph bottom
				xMin=V_min;xMax=V_max
				xPos = AxisValFromPixel(s.winname,"bottom",s.mouseLoc.h)
				yPos = AxisValFromPixel(s.winname,"left",s.mouseLoc.v)
				
				//Vertical slice
				ControlInfo/W=MBr#MatrixControlPanel MBr_ViewerVertCheck
				If(V_Value)
					If(xPos >= xMin && xPos <= xMax)
						xPos = IndexToScale(theWave,ScaleToIndex(theWave,xpos,0),0)	//snaps to data indices
						SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,linethick=1,linefgc=(0,65535,65535)	
						DrawLine/W=MBr#MBrGraph xPos,yMin,xPos,yMax
						
						//Further check that the index conversion is in range
						xPos = ScaleToIndex(theWave,xPos,0)
						If(xPos < DimSize(theWave,0) && xPos >= 0)
							MatrixOP/O sliceWave = row(theWave,xPos)
							MatrixTranspose sliceWave
						EndIf
				
						SetScale/P x,DimOffset(theWave,1),DimDelta(theWave,1),WaveUnits(theWave,1),sliceWave					
					EndIf
				EndIf
				
				//Horizontal slice
				ControlInfo/W=MBr#MatrixControlPanel MBr_ViewerHorCheck
				If(V_Value)
					If(yPos >= yMin && yPos <= yMax)
						yPos = IndexToScale(theWave,ScaleToIndex(theWave,yPos,1),1) //snaps to data indices
						SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,linethick=1,linefgc=(0,65535,65535)
						DrawLine/W=MBr#MBrGraph xMin,yPos,xMax,yPos
						
						//Further check that the index conversion is in range
						yPos = ScaleToIndex(theWave,yPos,1)
						If(yPos < DimSize(theWave,1) && yPos >= 0)
							sliceWave[] = theWave[p][yPos]
						EndIf			
						SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),WaveUnits(theWave,0),sliceWave			
					EndIf
				EndIf	
				
				//Beam slice
				ControlInfo/W=MBr#MatrixControlPanel MBr_ViewerBeamCheck
				If(V_Value)
					If(xPos >= xMin && xPos <= xMax && yPos >= yMin && yPos <=yMax)
						
						//Draw beam box indicator
						SetDrawEnv/W=MBr#MBrGraph xcoord=bottom,ycoord=left,fillfgc= (0,65535,65535,19661),fillpat=1,linethick=0
						If(beamRadius == 0)
							DrawRect/W=MBr#MBrGraph xPos+0.5*DimDelta(origWave,0),yPos-0.5*DimDelta(origWave,1),xPos-0.5*DimDelta(origWave,0),yPos+0.5*DimDelta(origWave,1)
						Else
							DrawRect/W=MBr#MBrGraph xPos+beamRadius*DimDelta(origWave,0),yPos-beamRadius*DimDelta(origWave,1),xPos-beamRadius*DimDelta(origWave,0),yPos+beamRadius*DimDelta(origWave,1)
						EndIf
						
						If(depthSize > 0)
							Redimension/N=(depthSize) sliceWave
						Else
							Redimension/N=1 sliceWave
						EndIf
						xPos = ScaleToIndex(origWave,xPos,0)
						yPos = ScaleToIndex(origWave,yPos,1)

						If(xPos < horSize && xPos >=0 && yPos < vertSize && yPos >=0)
							wave sliceWave = GetBeamAvg(origWave,xPos,yPos,beamRadius)
							SetScale x,DimOffset(origWave,2),DimDelta(origWave,2),WaveUnits(origWave,2),sliceWave
						EndIf
					EndIf
				EndIf
			EndIf
			break
		case 5: //mouse up, detecting double click.
			break
		case 11: //keyboard input
			If(cmpstr(s.keyText,"D",1) == 0)
				SetDataFolder root:Packages:MBr:
				String theName = UniqueName("savedSlice",1,0)
				String savedSliceStr = "root:Packages:MBr:" + theName
				Duplicate/O sliceWave,$savedSliceStr
				DoWindow sliceGraph
				If(V_flag)
					AppendToGraph/W=sliceGraph $savedSliceStr
				Else
					Display/N=sliceGraph $savedSliceStr as "Slice Wave"
				EndIf
				SetDataFolder cdf
			EndIf
			break
	endswitch
	return hookResult
End

Function/WAVE MBr_GetFolderItems()
	Wave/T waveListTable = root:Packages:MBr:waveListTable
	Wave selWave = root:Packages:MBr:selWave
	SVAR cdf = root:Packages:MBr:currentDataFolder
	SVAR matchStr = root:Packages:MBr:matchStr
	SVAR notMatchStr = root:Packages:MBr:notMatchStr
	String itemList
	Variable i
	
	//Checks if match string has value
	If(!strlen(matchStr))
		matchStr = "*"
	EndIf
	
	//Match list
	itemList = ReplaceString(";",StringFromList(1,DataFolderDir(2),":"),"")
	itemList = TrimString(itemList)
	itemList = ListMatch(itemList,matchStr,",")
	
	//Not match list
	If(strlen(notMatchStr))
		itemList = ListMatch(itemList,"!*" + notMatchStr,",")
	EndIf
	
	Redimension/N=(ItemsInList(itemList,",")) waveListTable,selWave
	
	For(i=0;i<ItemsInList(itemList,",");i+=1)
		waveListTable[i] = StringFromList(i,itemList,",")
	EndFor
	return waveListTable
End

Function/WAVE MBr_GetFolderListItems()
	Wave/Z/T folderTable = root:Packages:MBr:folderTable

	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
	If(!WaveExists(folderTable))
		Make/O/T/N=(DimSize(selFolderWave,0)) root:Packages:MBr:folderTable
	EndIf
	Wave/T folderTable = root:Packages:MBr:folderTable
	
	SVAR cdf = root:Packages:MBr:currentDataFolder
	Variable i
	
	//Indexes waves in current data folder, applies match string
	cdf = GetDataFolder(1)
	String folderList = ReplaceString(";",StringFromList(1,DataFolderDir(1),":"),"")
	folderList = TrimString(folderList)

	Redimension/N=(ItemsInList(folderList,",")) folderTable,selFolderWave
	
	//Fills out folder table for the list box
	For(i=0;i<ItemsInList(folderList,",");i+=1)
		folderTable[i] = StringFromList(i,folderList,",")
	EndFor
	return folderTable
End

Function ResetParameterPanel(cmd)
	String cmd
	Variable left,top
	left = 10
	top = 10
	NVAR pColumn = root:Packages:MBr:pColumn
	NVAR pRow = root:Packages:MBr:pRow
	NVAR pLayer = root:Packages:MBr:pLayer
	NVAR pRadius = root:Packages:MBr:pRadius
	SVAR pColumnRange = root:Packages:MBr:pColumnRange
	SVAR pRowRange = root:Packages:MBr:pRowRange
	
	//Get current parameters
	Variable i
	String parameterList = ControlNameList("MBr#ParameterPanel",";")
	parameterList = RemoveFromList("ParameterGroupBox",parameterList,";")
	
	For(i=0;i<ItemsInList(parameterList,";");i+=1)
		KillControl/W=MBr#ParameterPanel $StringFromList(i,parameterList,";")
	EndFor
	
	strswitch(cmd)
		case "Get Col Slice":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",30,0.1)
			SetVariable pColumn win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Column",value=pColumn
			break
		case "Get Row Slice":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",30,0.1)
			SetVariable pRow win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Row",value=pRow
			break
		case "Get Layer":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",30,0.1)
			SetVariable pLayer win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Layer",value=pLayer
			break
		case "Get Beam":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",80,0.1)
			SetVariable pRow win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Row",value=pRow
			top+=25
			SetVariable pColumn win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Column",value=pColumn
			top+=25
			SetVariable pRadius win=MBr#ParameterPanel,pos={left,top},size={75,20},limits={0,inf,1},title="Radius",value=pRadius
			break
		case "Extract Cols":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",55,0.1)
			CheckBox pAllColCheck win=MBr#ParameterPanel,pos={left,top},size={75,20},title="All columns"
			top+=25
			SetVariable pColumnRange win=MBr#ParameterPanel,pos={left,top},size={75,20},title="Columns",value=pColumnRange,proc=MBr_SetVariableProc
			break
		case "Extract Rows":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",55,0.1)
			CheckBox pAllRowCheck win=MBr#ParameterPanel,pos={left,top},size={75,20},title="All rows"
			top+=25
			SetVariable pRowRange win=MBr#ParameterPanel,pos={left,top},size={75,20},title="Rows",value=pRowRange,proc=MBr_SetVariableProc
			break
		case "Concat Cols":
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",55,0.1)
			CheckBox pAllColCheck win=MBr#ParameterPanel,pos={left,top},size={75,20},title="All columns"
			top+=25
			SetVariable pColumnRange win=MBr#ParameterPanel,pos={left,top},size={75,20},title="Columns",value=pColumnRange,proc=MBr_SetVariableProc
			break
		default:
			animateControlDrop("ParameterGroupBox","MBr#ParameterPanel",2,0.1)
			break
	endswitch

End

Function MBr_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	NVAR timeRef = root:Packages:MBr:timeRef
	NVAR mouseDown = root:Packages:MBr:mouseDown
	NVAR selectedRow = root:Packages:MBr:selectedRow
	SVAR selectedWave = root:Packages:MBr:selectedWave
	NVAR horSize = root:Packages:MBr:horSize
	NVAR vertSize = root:Packages:MBr:vertSize
	NVAR depthSize = root:Packages:MBr:depthSize
	SVAR cmdStr = root:Packages:MBr:cmdStr
	SVAR selectedWaveDisplayStr = root:Packages:MBr:selectedWaveDisplayStr
	SVAR sliderPosStr = root:Packages:MBr:sliderPosStr
	SVAR eventSequence = root:Packages:MBr:eventSequence
	NVAR mouseOnEdge = root:Packages:MBr:mouseOnEdge
	NVAR resizingEdge = root:Packages:MBr:resizingEdge
	SVAR currentTab = root:Packages:analysisTools:currentTab
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	Variable i
	
	selWaveList = ""
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			eventSequence = "1"
			If(mouseOnEdge)
				resizingEdge = 1
			EndIf
		case 2: // mouse up
			eventSequence +="0"
			
			//break if graph is not present
			DoWindow/W=MBr#MBrGraph MBrGraph
			If(!V_Flag)
				ListBox MBr_ItemListBox win=MBr,disable=0
				break
			EndIf
			
			GetWindow MBr#MBrGraph gsize
			Variable left = V_left
			Variable right = V_right
			Variable top = V_top
			Variable bottom = V_bottom
			
			
		//	If(cmpstr(eventSequence,"10") == 0)
				
		//	EndIf
			
			//If(!resizingEdge)
				//If mouse up is the graph window area
				If(lba.mouseloc.h > left && lba.mouseloc.h < right && lba.mouseloc.v > top && lba.mouseloc.v < bottom)
					//If mouse up is occurring
					If(cmpstr(eventSequence,"100") == 0)
						If(!WaveType($selectedWave) == 0)
							AppendToGraph/W=MBr#MBrGraph $selectedWave
							SetDrawEnv/W=MBr#MBrGraph fsize=26,fstyle=0,textrgb=(3,52428,1)
							DrawText/W=MBr#MBrGraph 0.02,0.05,"+"
							DoUpdate/W=MBr#MBrGraph
							variable startTime,currentTime,elapsedTime
							startTime = ticks
							Do
								currentTime = ticks
								elapsedTime = currentTime - startTime
							While(elapsedTime < 20)
							DrawAction/W=MBr#MBrGraph delete
						EndIf
						eventSequence = ""
					EndIf
				EndIf
				ListBox MBr_ItemListBox win=MBr,disable=0
				
				//Fill out the selected wave list
			
				If(cmpstr(lba.ctrlName,"MBr_ItemListBox") == 0 || cmpstr(lba.ctrlName,"AT_ItemListBox") == 0)
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor

					//Add the traces to viewer if its in the analysis tab
					
					If(cmpstr(currentTab,"Analysis") == 0)
						AppendToViewer(selWaveList)
					EndIf
				EndIf
				//////////

			//Else
			//	ControlInfo MBr_FolderListBox
			//	ListBox MBr_FolderListBox win=MBr,size={lba.mouseloc.h - V_left,V_height}
			//	ControlUpdate MBr_FolderListBox
			//EndIf
			break
		case 3: // double click
			strswitch(lba.ctrlName)
			case "AT_FolderListBox":

			case "MBr_FolderListBox":
				If(row > DimSize(listWave,0)-1)
					break
				EndIf
				cdf = cdf + listWave[row] + ":"
				SetDataFolder cdf
				MBr_GetFolderListItems()
				MBr_GetFolderItems()
				ControlUpdate MBr_cdf
				//Update command string in case the popup menu hasn't actually been clicked prior to running a command
				cmdStr = GetCmdStr()
				break
				
			case "AT_ItemListBox":
			case "MBr_ItemListBox":
				String traces
	
				If(row > DimSize(listWave,0)-1)
					break
				EndIf
				selectedWave = listWave[row]
				selectedWaveDisplayStr = selectedWave
				Wave theWave = $selectedWave	
				
				DoUpdate/W=MBr#MBrGraph
				
				//test for numeric wave and dimensionality
				If(WaveType(theWave,0))
					KillWindow/Z MBr#MBrGraph
					Display/HOST=MBr/N=MBrGraph/FG=(LG,TG,RG,MG) as "MBrGraph"
					//Set margins so that the slice viewer can match them and the graphs will be lined up
					ModifyGraph/W=MBr#MBrGraph margin(left)=60,margin(right)=60
					//Get wave dimensions
					horSize = DimSize(theWave,0)
					vertSize = DimSize(theWave,1)
					depthSize = DimSize(theWave,2)
					
					//If 3D (with layers)
					If(depthSize)
						Slider MBr_Slider win=MBr#BottomControlPanel,disable=0,value=0,limits={0,depthSize-1,1}
						SetVariable MBr_WhichLayer win=MBr#BottomControlPanel,disable=0
						Button MBr_playMovie win=MBr#BottomControlPanel,disable=0
						PopUpMenu MBr_ColorPalette win=MBr#BottomControlPanel,disable=0
						sliderPosStr = "1/" + num2str(depthSize)
						Wave layerWave = root:Packages:MBr:layerWave
						Redimension/N=(horSize,vertSize) layerWave //only will hold one layer of the input wave at a time
						layerWave[][] = theWave[p][q][0] //initially loads in the first layer
						SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),layerWave
						SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),layerWave
						AppendImage/W=MBr#MBrGraph layerWave
						ControlInfo/W=MBr#BottomControlPanel MBr_ColorPalette
						ModifyImage/W=MBr#MBrGraph layerWave,ctab={WaveMin(theWave),WaveMax(theWave),$S_Value,0}
					Else
						Slider MBr_Slider win=MBr#BottomControlPanel,disable=1,value=0,limits={0,depthSize-1,1}
						SetVariable MBr_WhichLayer win=MBr#BottomControlPanel,disable=1
						Button MBr_playMovie win=MBr#BottomControlPanel,disable=1
						If(DimSize($selectedWave,1) > 0)
							AppendImage/W=MBr#MBrGraph theWave
							ControlInfo/W=MBr#BottomControlPanel MBr_ColorPalette
							ModifyImage/W=MBr#MBrGraph $selectedWave, ctab= {WaveMin(theWave),WaveMax(theWave),$S_Value,0}
							PopUpMenu MBr_ColorPalette win=MBr#BottomControlPanel,disable=0
						Else
							AppendToGraph/W=MBr#MBrGraph theWave
							PopUpMenu MBr_ColorPalette win=MBr#BottomControlPanel,disable=1
						EndIf
						
						Wave sliceWave = root:Packages:MBr:sliceWave
						Redimension/N=(horSize) sliceWave
					EndIf
				EndIf
				//Update command string in case the popup menu hasn't actually been clicked prior to running a command
				cmdStr = GetCmdStr()
				
				//Make image histogram for 2D or higher waves
				If(horSize > 0 && vertSize > 0)
					KillWindow/Z MBr#BottomControlPanel#histGraph
					MakeImageHistogram(selectedWave)
				EndIf
					
				break
			endswitch
			
			break
		case 4: // cell selection
			
			If(row > DimSize(listWave,0)-1)
				break
			EndIf
			strswitch(lba.ctrlName)
				case "MBr_ItemListBox":
					ListBox MBr_ItemListBox win=MBr,disable=2
					selectedRow = row
					selectedWave = listWave[row]
				case "AT_ItemListBox":	
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor
					If(cmpstr(currentTab,"Analysis") == 0)
						AppendToViewer(selWaveList)
					EndIf	
										
					//Set to null if a selection has changed.
					viewerRecall = ""
					break
			endswitch
			break
		case 5: // cell selection plus shift key
			strswitch(lba.ctrlName)
				case "AT_ItemListBox":	
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor
					If(cmpstr(currentTab,"Analysis") == 0)
						AppendToViewer(selWaveList)
					EndIf	
										
					//Set to null if a selection has changed.
					viewerRecall = ""
				break
			endswitch
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

//Note - this actually uses the catRows MatrixOP command; it takes a matrix, and stacks its columns one after the other into a longer, single dimension wave.
Function ConcatCols(selectedWave)
	String selectedWave
	Wave theWave = $selectedWave
	SVAR outWaveStr = root:Packages:MBr:outWaveStr
	SVAR cdf = root:Packages:MBr:currentDataFolder
	Variable startCol,endCol,i
	//Which columns?
	SVAR pColumnRange = root:Packages:MBr:pColumnRange

	ControlInfo/W=MBr#ParameterPanel pAllColCheck
	If(V_Value)
		//all columns
		startCol = 0
		endCol = DimSize(theWave,1)
	ElseIf(strlen(pColumnRange))
		//range of columns
		If(StringMatch(pColumnRange,"*-*"))
			startCol = str2num(StringFromList(0,pColumnRange,"-"))
			endCol = str2num(StringFromList(1,pColumnRange,"-"))
		Else
			startCol = str2num(pColumnRange)
			endCol = str2num(pColumnRange)
		EndIf
		//start column can't be negative
		startCol = (startCol < 0) ? 0 : startCol
	EndIf
	outWaveStr = cdf + selectedWave + "_catcol" 
	Make/FREE/N=(DimSize(theWave,0)) temp1,temp2
	temp1 = theWave[p][startCol]
	For(i=startCol;i<endCol;i+=1)
		If(DimSize(theWave,0) == i+1)
			break
		EndIf
		temp2 = theWave[p][i+1]
		MatrixOP/O $outWaveStr = catRows(temp1,temp2)
		Wave outWave = $outWaveStr
		Duplicate/O/FREE outWave,temp1
	EndFor
End

Function ExtractColumns(selectedWave)
	String selectedWave
	Wave theWave = $selectedWave
	SVAR outWaveStr = root:Packages:MBr:outWaveStr
	SVAR cdf = root:Packages:MBr:currentDataFolder
	Variable startCol,endCol,i
	//Which columns?
	SVAR pColumnRange = root:Packages:MBr:pColumnRange

	ControlInfo/W=MBr#ParameterPanel pAllColCheck
	If(V_Value)
		//all columns
		startCol = 0
		endCol = DimSize(theWave,1)
	ElseIf(strlen(pColumnRange))
		//range of columns
		If(StringMatch(pColumnRange,"*-*"))
			startCol = str2num(StringFromList(0,pColumnRange,"-"))
			endCol = str2num(StringFromList(1,pColumnRange,"-"))
		Else
			startCol = str2num(pColumnRange)
			endCol = str2num(pColumnRange)
		EndIf
		//start column can't be negative
		startCol = (startCol < 0) ? 0 : startCol
	EndIf
		
	For(i=startCol;i<=endCol;i+=1)
		outWaveStr = cdf + selectedWave + "_col" + num2str(i)
		MatrixOP/O $outWaveStr = col(theWave,i)
		Redimension/N=(-1,0,0) $outWaveStr
		SetScale/P x,DimOffset(theWave,1),DimDelta(theWave,1),$outWaveStr
	EndFor
End

Function ExtractRows(selectedWave)
	String selectedWave
	Wave theWave = $selectedWave
	SVAR outWaveStr = root:Packages:MBr:outWaveStr
	SVAR cdf = root:Packages:MBr:currentDataFolder
	Variable startRow,endRow,i
	//Which columns?
	SVAR pRowRange = root:Packages:MBr:pRowRange
	ControlInfo/W=MBr#ParameterPanel pAllRowCheck
	If(V_Value)
		//all columns
		startRow = 0
		endRow = DimSize(theWave,0)
	ElseIf(strlen(pRowRange))
		//range of columns
		If(StringMatch(pRowRange,"*-*"))
			startRow = str2num(StringFromList(0,pRowRange,"-"))
			endRow = str2num(StringFromList(1,pRowRange,"-"))
		Else
			startRow = str2num(pRowRange)
			endRow = str2num(pRowRange)
		EndIf
		//start row can't be negative
		startRow = (startRow < 0) ? 0 : startRow
	EndIf
		
	For(i=startRow;i<=endRow;i+=1)
		If(i == DimSize(theWave,0))
			break
		EndIf
		outWaveStr = cdf + selectedWave + "_row" + num2str(i)
		MatrixOP/O $outWaveStr = row(theWave,i)
		Redimension/N=(-1,-1,0) $outWaveStr
		MatrixTranspose $outWaveStr
		Redimension/N=(-1,0,0) $outWaveStr
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),$outWaveStr
	EndFor
End

Function advanceMovieFrame(s)
	STRUCT WMBackgroundStruct &s
	SVAR selectedWave = root:Packages:MBr:selectedWave
	Wave theWave = $selectedWave
	Wave layerWave =  root:Packages:MBr:layerWave
	NVAR depthSize = root:Packages:MBr:depthSize
	SVAR sliderPosStr = root:Packages:MBr:sliderPosStr
	NVAR sliderPos = root:Packages:MBr:sliderPos
	NVAR play = root:Packages:MBr:play
	Variable currentLayer
	
	If(sliderPos+1 == depthSize)
		sliderPos = 0
	Else
		sliderPos +=1
	EndIf
	
	If(WaveExists(theWave))
		layerWave[][] = theWave[p][q][sliderPos] 
		play = 1
	Else
		//stops movie 
		CtrlNamedBackground movie,period=10,stop,proc=advanceMovieFrame
		Button MBr_playMovie win=MBr#BottomControlPanel,title="  \\W549>"
		play = 0
	EndIf
	
	sliderPosStr = num2str(sliderPos+1) + "/" + num2str(depthSize)
	Slider MBr_Slider win=MBr#BottomControlPanel,value=sliderPos
	ControlUpdate/W=MBr#BottomControlPanel MBr_Slider
	return 0
End








Function corrMatrix(inWave,xpnt,ypnt)
	Wave inWave
	Variable xpnt,ypnt
	Variable i,j,h,k
	
	Variable xSize = DimSize(inWave,0)
	Variable ySize = DimSize(inWave,1)
	Variable zSize = DimSize(inWave,2)
	
	Make/FREE/N=(zSize) beam1,beam2
	//For(i=xpnt-10;i<xpnt+10;i+=1)
	//	For(j=ypnt-10;j<ypnt+10;j+=1)
			Make/O/N=(xSize,ySize) $("root:Traces:cMat_" + StringFromList(1,NameOfWave(inWave),"_") + "_" + num2str(xpnt) + "_" + num2str(ypnt))
			Wave cMatrix = $("root:Traces:cMat_" + StringFromList(1,NameOfWave(inWave),"_") + "_" + num2str(xpnt) + "_" + num2str(ypnt))
			MatrixOP/O beam1 = beam(inWave,xpnt,ypnt)
			beam1[0,zSize-51] = beam1[p+50]
			Redimension/N=(zSize-51) beam1
			For(k=xpnt-20;k<xpnt+20;k+=1)
				For(h=ypnt-20;h<ypnt+20;h+=1)
					MatrixOP/O beam2 = beam(inWave,k,h)
					beam2[0,zSize-51] = beam2[p+50]
					Redimension/N=(zSize-51) beam2
					StatsLinearCorrelationTest/Q beam1,beam2
					Wave results = W_StatsLinearCorrelationTest
					cMatrix[k][h] = results[1]
				EndFor
			EndFor
	//	EndFor
	//EndFor

End

//Makes histogram of color values for 2D or higher waves.
Function MakeImageHistogram(selectedWave)
	String selectedWave
	Wave theWave = $selectedWave
	Variable i,depthSize
	String cdf = GetWavesDataFolder($selectedWave,1)
	
	Wave imageHist = root:Packages:MBr:imageHist
	Wave histLeftY = root:Packages:MBr:histLeftY
	Wave histRightY = root:Packages:MBr:histRightY
	Wave histLeftX = root:Packages:MBr:histLeftX
	Wave histRightX = root:Packages:MBr:histRightX
	
	//What wave is actually on the graph? Might not be the wave selected, but instead a single layer wave
	String imageOnGraph = ImageNameList("MBr#MBrGraph",";")
	If(!strlen(imageOnGraph))
		return -1 //error
	EndIf
	imageOnGraph = StringFromList(0,imageOnGraph,";")
	
	depthSize = DimSize(theWave,2)
	SetDataFolder $cdf
	imageHist = 0
	Histogram/RMD=[0,*][0,*]/B={0,1,4096} theWave,imageHist
	//Wave W_ImageHist
	//Variable leftVal = DimOffset(W_ImageHist,0)
	//Histogram /B={leftVal,1,4096} W_ImageHist,imageHist
	
	//histogram guides
	DefineGuide/W=MBr#BottomControlPanel histGuideL={FL,130}
	DefineGuide/W=MBr#BottomControlPanel histGuideT={FT,20}
	DefineGuide/W=MBr#BottomControlPanel histGuideB={FT,40}
	
 	DoWindow/W=MBr#BottomControlPanel#histGraph histGraph
 	If(!V_flag)
 		Display/HOST=MBr#BottomControlPanel/N=histGraph/FG=(histGuideL,histGuideT,FR,histGuideB) imageHist	
 	EndIf
 	
 	ModifyGraph/W=MBr#BottomControlPanel#histGraph/Z margin=7,gfSize=2,noLabel=2,axThick=0,standoff=0,btLen=2,mode=5,hbFill=2,rgb=(0,0,0)
 		
 	String info = ImageInfo("MBr#MBrGraph",imageOnGraph,0)
 	String ctabStr = StringByKey("RECREATION:ctab",info,"=",";")
 	ctabStr = ResolveCtabStr(ctabStr,theWave)
 	
 	histLeftX = str2num(StringFromList(0,ctabStr,","))
 	histRightX= str2num(StringFromList(1,ctabStr,","))
 	
 	AppendToGraph/W=MBr#BottomControlPanel#histGraph histLeftY vs histLeftX
 	AppendToGraph/W=MBr#BottomControlPanel#histGraph histRightY vs histRightX
 		
 	SetWindow MBr hook(histHook)=histHook,hookevents=3
 	
End

Function histHook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
End

//Inputs a 3D wave and outputs the a 2D wave max projection
Function/WAVE BeamMax(theWave,smoothVal,startFrame,endFrame)
	Wave theWave
	Variable smoothVal,startFrame,endFrame
	
	If(!WaveExists(theWave))
		Abort "Can't find wave " + NameOfWave(theWave)
	EndIf
	
	Variable rows,cols,frames,i,j
	//Wave dimensions
	frames = DimSize(theWave,2)
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	Make/O/N=(rows,cols) $(NameOfWave(theWave) + "_MP")
	Wave outWave = $(NameOfWave(theWave) + "_MP")
	
	For(i=0;i<rows;i+=1)
		For(j=0;j<cols;j+=1)
			//Get the beam
			MatrixOP/FREE/O theBeam = Beam(theWave,i,j)
			
			//Optional smoothing
			If(smoothVal > 0)
				If(mod(smoothVal,2) != 0)
					Smooth/S=2 smoothVal,theBeam
				Else
					Abort "Smooth value must be odd"
				EndIf
			EndIf
			//Get peak value
			outWave[i][j] = WaveMax(theBeam,startFrame,endFrame)
		EndFor
	EndFor
	
	return outWave
End