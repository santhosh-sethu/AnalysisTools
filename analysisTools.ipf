#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <New Polar Graphs>

Menu "Data", dynamic
	Submenu "Packages"
		 "Load Analysis Suite"
	End
End

//Finds any external procedure files to include
Function FindExternalModules()
	String filepath,folders,platform
	platform = IgorInfo(2)
	
	print "did it update?"
	If(cmpstr(platform,"Windows") == 0)
		filepath = SpecialDirPath("Igor Application",0,0,0) + "User Procedures\twoPhoton\analysisTools\External Procedures"
	ElseIf(cmpstr(platform,"Macintosh") == 0)
		filepath = SpecialDirPath("Igor Application",0,0,0) + "User Procedures:twoPhoton:analysisTools:External Procedures"
	EndIf
	
	//What folder is the analysisTools.ipf in?
	filepath = FunctionPath("FindExternalModules")
	If(cmpstr(platform,"Windows") == 0)
		filepath = ParseFilePath(1,filepath,"\\",1,0) + "External Procedures"
	ElseIf(cmpstr(platform,"Macintosh") == 0)
		filepath = ParseFilePath(1,filepath,":",1,0) + "External Procedures"
	EndIf
	
	NewPath/Q/Z/C/O IgorProcPath,filepath

	String/G root:Packages:analysisTools:fileList
	SVAR fileList = root:Packages:analysisTools:fileList
	
	fileList = IndexedFile(IgorProcPath,-1,".ipf")//finds ipf files
	InsertIncludes(fileList)
End

//Adds #includes the external procedure files
Function InsertIncludes(fileList)
	String fileList
	Variable numFiles,i
	String theFile
	
	numFiles = ItemsInList(fileList,";")
	
	For(i=0;i<numFiles;i+=1)
		theFile = StringFromList(i,fileList,";")
		theFile = RemoveEnding(theFile,".ipf")
		Execute/P "INSERTINCLUDE \"" + theFile + "\"" 
	EndFor
	Execute/P "COMPILEPROCEDURES ";
End

//Loads the analysis suite GUI
Function LoadAnalysisSuite([left,top])
	//So the window stays in position upon reload
	Variable left,top
	Variable width,height,i
	
	If(ParamIsDefault(left))
		left = 0
	EndIf
	If(ParamIsDefault(top))
		top = 0
	EndIf

	// Make the panel//////////
	DoWindow analysis_tools
	if(V_flag !=0)
	DoWindow/K analysis_tools
	else
	endif
	
	left += 0
	top += 50
	width = 575
	height = 510
	
	NewPanel /K=1 /W=(left,top,left + width,top + height) as "Analysis Tools"
	DoWindow/C analysis_tools
	ModifyPanel /W=analysis_tools, fixedSize= 1
	
	//Make analysisTools package folder
	If(!DataFolderExists("root:Packages:analysisTools"))
		NewDataFolder root:Packages:analysisTools
	EndIf
	
	//external procedures loaded
 	FindExternalModules()
	
	//Wave for remembering the most recent values for any given external function
	If(!WaveExists(root:Packages:analysisTools:extFuncValues))
		Make/T/N=(0,0) root:Packages:analysisTools:extFuncValues
	EndIf
	
	//Housekeeping variables and strings
	String/G root:Packages:analysisTools:tabList
	String/G root:Packages:analysisTools:currentTab
	String/G root:Packages:analysisTools:prevTab
	
	Variable/G root:Packages:analysisTools:viewerOpen
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	viewerOpen = 0
	
	Variable/G root:Packages:analysisTools:areSeparated
	NVAR areSeparated = root:Packages:analysisTools:areSeparated
	areSeparated = 0
	
	If(!WaveExists(root:Packages:twoP:examine:scanListWave))
		Make/T root:Packages:twoP:examine:scanListWave
	EndIf
	wave/T scanListWave = root:Packages:twoP:examine:scanListWave
	
	If(Exists("root:Packages:twoP:examine:scanListStr") !=2)
		String/G root:Packages:twoP:examine:scanListStr
	EndIf
	
	String/G root:Packages:analysisTools:scanFolderList
	SVAR scanFolderList = root:Packages:analysisTools:scanFolderList
	scanFolderList = ""
	For(i=0;i<DimSize(scanListWave,0);i+=1)
		scanFolderList += scanListWave[i] + ";"
	EndFor
	
	If(!WaveExists(root:Packages:twoP:examine:selWave))
		Make/O/N=(DimSize(scanListWave,0)) root:Packages:twoP:examine:selWave
	EndIf
	Wave selWave = root:Packages:twoP:examine:selWave
	

	If(!WaveExists(root:Packages:analysisTools:selFolderWave))
		Make/O/N=(1) root:Packages:analysisTools:selFolderWave
	EndIf
	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
		
	//Check size of selWave
	If(DimSize(selWave,0) != DimSize(scanListWave,0))
		Redimension/N=(DimSize(scanListWave,0)) selWave
	EndIf
	
	If(!WaveExists(root:packages:twoP:examine:ROIListWave))
		Make/T root:packages:twoP:examine:ROIListWave
	EndIf
	wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	
	If(!WaveExists(root:Packages:twoP:examine:ROIListSelWave))
		Make/O/N=(DimSize(ROIListWave,0)) root:Packages:twoP:examine:ROIListSelWave
	EndIf
	wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	
	//for the list box switcher
	String/G root:Packages:analysisTools:whichList
	SVAR whichList = root:Packages:analysisTools:whichList
	whichList = "AT"

	String/G root:Packages:twoP:examine:scanListStr
	String/G root:Packages:twoP:examine:ROIListStr
	
	String/G root:Packages:analysisTools:cmdList
	String/G root:Packages:analysisTools:currentCmd
	String/G root:Packages:analysisTools:prevCmd
	SVAR prevCmd = root:Packages:analysisTools:prevCmd
	prevCmd = ""
	SVAR cmdList = root:Packages:analysisTools:cmdList
	
	//Function Packages
	Make/O/T/N=(2,2) root:Packages:analysisTools:packageTable
	Wave/T packageTable = root:Packages:analysisTools:packageTable
	packageTable[0][0] = "Calcium Imaging"
	packageTable[0][1] = "-------ROIs--------;MultiROI;ROI Grid;Display ROIs;-------Maps-------;"
	packageTable[0][1] += "df Map;Vector Sum Map;------Masks-------;Get Dendritic Mask;Mask Scan Data;"
	packageTable[0][1] += "----Registration---;Adjust Galvo Distortion;Register Image;Rescale Scans"
	
	//packageTable[1][0] = "Basic Functions"
	//packageTable[1][1] = "-------------------;Average;Error"
	
	
	cmdList = "Data Sets;External Function;---------------;Load PClamp;---------------;Average;Error;Kill Waves;----Packages----;Calcium Imaging"
	//cmdList += "-------ROIs--------;"
	//cmdList += "MultiROI;ROI From Map;ROI Grid;Display ROIs;"//ROI Segmenter;ROI Tuning Curve;"
	//cmdList += "-------Maps-------;"
	//cmdList += "df Map;Vector Sum Map;"//Space-Time dF;"
	//cmdList += "------Masks-------;"
	//cmdList += "Get Dendritic Mask;Mask Scan Data;"
	//cmdList += "----Registration---;"
	//cmdList += "Adjust Galvo Distortion;Register Image;Rescale Scans;"
	//cmdList += "----Functions----;"
	//cmdList += "Get Peaks;Get Peak Times;Line Profile"

	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	currentCmd = StringFromList(0,cmdList,";")
	
	//For the Operation command and wave matching
	String/G root:Packages:analysisTools:waveMatchStr
	SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
	waveMatchStr = ""
	
	String/G root:Packages:analysisTools:waveNotMatchStr
	SVAR waveNotMatchStr = root:Packages:analysisTools:waveNotMatchStr
	waveNotMatchStr = ""
	
	String/G root:Packages:analysisTools:opList
	SVAR opList = root:Packages:analysisTools:opList
	opList = "Cmd Line;avg;sem;sum;delete;edit;display;differentiate"
	
	Make/O/T/N=1 root:Packages:analysisTools:AT_waveListTable
	Wave/T AT_waveListTable = root:Packages:analysisTools:AT_waveListTable
	Make/O/T/N=1 root:Packages:analysisTools:AT_WaveListTable_FullPath
	Wave/T AT_WaveListTable_FullPath = root:Packages:analysisTools:AT_WaveListTable_FullPath
	
	Make/O/N=1 root:Packages:analysisTools:AT_selWave
	Wave AT_selWave = root:Packages:analysisTools:AT_selWave
	AT_selWave = 0
	
	String/G root:Packages:analysisTools:runCmdStr
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	runCmdStr = ""
	
	String/G root:Packages:analysisTools:MBr_WindowSettings
	SVAR MBr_WindowSettings = root:Packages:analysisTools:MBr_WindowSettings
	MBr_WindowSettings = ""
	
	//For external functions
	String/G root:Packages:analysisTools:extFuncList
	SVAR extFuncList = root:Packages:analysisTools:extFuncList
	SVAR fileList = root:Packages:analysisTools:fileList
	extFuncList = getExternalFunctions(fileList)
	Variable/G root:Packages:analysisTools:numExtParams
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	String/G root:Packages:analysisTools:extParamNames
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	extParamNames = ""
	String/G root:Packages:analysisTools:extParamTypes
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	extParamTypes = ""
	String/G root:Packages:analysisTools:isOptional
	SVAR isOptional = root:Packages:analysisTools:isOptional
	isOptional = ""
	
	
	//For Data Sets////////////////////
	If(!DataFolderExists("root:Packages:analysisTools:DataSets"))
		NewDataFolder root:Packages:analysisTools:DataSets
	EndIf
	
	String/G root:Packages:analysisTools:DataSets:wsDims
	Variable/G root:Packages:analysisTools:DataSets:numWaveSets
	Variable/G root:Packages:analysisTools:DataSets:wsn
	
	//These will be the dummy data set for the wave list box until
	//the data set is actually saved. 
	Make/N=0/T/O root:Packages:analysisTools:DataSets:WaveListDS
	Make/N=0/T/O root:Packages:analysisTools:DataSets:ogWaveListDS
	
	
	
	Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	If(!WaveExists(dataSetNames))
		Make/T/N=1 root:Packages:analysisTools:DataSets:dataSetNames
		Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	EndIf
	
	GetDataSetNames()
	
	Make/O/N=(DimSize(dataSetNames,0)) root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	
	//Data set filters, only overwrite if it doesn't exist yet.
	If(!WaveExists(root:Packages:analysisTools:DataSets:dsFilters))
		Make/O/T/N=(DimSize(dataSetNames,0),2) root:Packages:analysisTools:DataSets:dsFilters
	EndIf
	
	
		
	//Create Variables////////////////////

	variable/G root:Packages:analysisTools:smthMode = 0	
	variable/G root:Packages:analysisTools:Gred 
	variable/G root:Packages:analysisTools:Ggreen 
	variable/G root:Packages:analysisTools:Gblue
	variable/G root:Packages:analysisTools:Gnumtrials
	variable/G root:Packages:analysisTools:Gbatchsize
	variable/G root:Packages:analysisTools:GpeakSt = 3
	variable/G root:Packages:analysisTools:GpeakEnd  = 5
	variable/G root:Packages:analysisTools:GbslnSt = 1
	variable/G root:Packages:analysisTools:GbslnEnd = 3
	variable/G root:Packages:analysisTools:GdarkValue
	variable/G root:Packages:analysisTools:GSpaceFilter = 3
	variable/G root:Packages:analysisTools:GSmoothFilter
	variable/G root:Packages:analysisTools:TempFilter = 0	
	variable/G root:Packages:analysisTools:able = 0
	NVAR able = root:Packages:analysisTools:able
	
	//ROI display variables
	String/G root:Packages:analysisTools:arrangementOptions
	SVAR arrangementOptions = root:Packages:analysisTools:arrangementOptions
	arrangementOptions = "None;Index;ROI"
	
	//Build the Tab control
	SVAR tabList = root:Packages:analysisTools:tabList
	
	///TAB LIST - semi-colon separated list of the tab names.
	//Just add another entry to the list to make a new tab.
	tabList = "Analysis"//;Browser"
	
	
	//MBr tools 
	DoWindow MBr
	If(V_flag)
		KillWindow/Z MBr
	EndIf
	
	NewPanel/N=MBr/W=(left,top,left+900,top+450)/K=1/HIDE=1 as "Matrix Browser"
	
	//Make additional tabs on MBr
	TabControl atTabMBr win=MBr,pos={0,0},proc=atTabProc
	For(i=0;i<ItemsInList(tabList,";");i+=1)
		//575-235 = width -235
		TabControl atTabMBr win=MBr,tabLabel(i) = StringFromList(i,tabList,";"),size={575-235,20}
	EndFor
	MBr_BuildControls()
	DoWindow MBr
	If(V_flag)
		GetWindow MBr wsize
		MBr_WindowSettings = "Width:" + num2str(V_right - V_left) + ";Height:" + num2str(V_bottom - V_top)
	EndIf
	//MBr_WindowSettings = "Width:" + num2str(V_right - V_left) + ";Height:" + num2str(V_bottom - V_top)

	SVAR cdf = root:Packages:MBr:currentDataFolder
	
	
	Make/O/N=(ItemsInList(tabList,";")) root:Packages:analysisTools:controlHeight
	Wave controlHeight = root:Packages:analysisTools:controlHeight
	//Add the names of your controls to the appropriate list to assign controls to that tab.
	//Assignment allows the tab to automatically hide or show controls assigned to that tab when it gets clicked. 
	//Make sure the name of a new control list is with format: 'ctrlList_' + 'name of control'
	
	CreateControlLists(cmdList)
	
	//New tab control lists...
	
	SVAR prevTab = root:Packages:analysisTools:prevTab
	SVAR currentTab = root:Packages:analysisTools:currentTab
	currentTab = StringFromList(0,tabList,";")
	prevTab = ""
	
	TabControl atTab win=analysis_tools,proc=atTabProc
	For(i=0;i<ItemsInList(tabList,";");i+=1)
		TabControl atTab win=analysis_tools,tabLabel(i) = StringFromList(i,tabList,";"),size={width-235,20}
	EndFor
	
	// ADD functions..
	
	//Scan list panel
	DefineGuide/W=analysis_tools listboxLeft={FR,-235},listboxBottom={FB,-10}
	NewPanel/HOST=analysis_tools/FG=(listboxLeft,FT,FR,listboxBottom)/N=scanListPanel
	ModifyPanel/W=analysis_tools#scanListPanel frameStyle=0
	ListBox/Z WaveListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,selWave=selWave,listWave=scanListWave,proc=atListBoxProc
	
	//ROI list Panel
	ListBox/Z ROIListBox win=analysis_tools#scanListPanel,size={80,height-75},pos={150,30},mode=4,selWave=ROIListSelWave,listWave=ROIListWave,proc=atListBoxProc
	Button nudgeROI win=analysis_tools#scanListPanel,size={60,20},pos={160,height-40},title="Nudge",proc=atButtonProc
	
	//Extra list box for folders, so I can switch between browsing and scan list
	ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=2,disable=1
	Button atBrowseButton win=analysis_tools#scanListPanel,size={40,20},pos={5,5},fsize=8,title="Browse",proc=atButtonProc
	Button atBrowseBackButton win=analysis_tools#scanListPanel,size={40,20},pos={50,5},fsize=8,title="Back",proc=MBr_ButtonProc,disable=1
	
	SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
	DrawText/W=analysis_tools#scanListPanel 75,25,"Scans"
	DrawText/W=analysis_tools#scanListPanel 180,25,"ROIs"
	
	//Reload analysis tools button
	Button reloadATButton win=analysis_tools,size={50,20},pos={3,468},title="Reload",proc=atButtonProc
	
	//Viewer Button
	Button atViewerButton win=analysis_tools,size={50,20},pos={3,448},title="Viewer",proc=atButtonProc
	String/G root:Packages:analysisTools:viewerRecall = ""
	
	//current data folder text

	SetVariable AT_cdf win=analysis_tools#scanListPanel,pos={100,8},size={200,20},fsize=10,value=cdf,title=" ",disable=1,frame=0
	
	PopUpMenu AT_CommandPop win=analysis_tools,pos={80,35},size={125,20},fsize=12, title="Command:",bodywidth=125,value=#"root:Packages:analysisTools:cmdList",mode=1,proc=atPopProc
	Button AT_RunCmd win=analysis_tools,pos={260,34},size={50,20},title="Run",proc=atButtonProc
	Button AT_Help win=analysis_tools,pos={210,34},size={20,20},title="?",proc=atButtonProc
	GroupBox AT_HelpBox win=analysis_tools,pos={7,269},size={326,200},disable=1
	
	//Variables
	SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
	Variable yPos = 60
//	DrawText/W=analysis_tools 30,yPos,"Baseline"
//	DrawText/W=analysis_tools 150,yPos,"Peak"
//	DrawText/W=analysis_tools 250,yPos,"Trials"
//	DrawText/W=analysis_tools 30,yPos+60,"Filters"
	
	yPos += 5
	setvariable bslnStVar, win = analysis_tools, pos = {10,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GbslnSt, title = "Bsln Start"
	setvariable peakStVar, win = analysis_tools, pos = {120,yPos}, size = {90, 30}, bodywidth=35,noproc, value = root:Packages:analysisTools:GpeakSt, title = "Peak Start"
	setvariable numtrialsVar, win = analysis_tools, pos = {230,yPos}, size = {100, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:Gnumtrials, title = "No. of trials"
	
	//for ROI Display function
	PopUpMenu horDisplayArrangementPopUp win=analysis_tools,pos={10,yPos},size={75,20},title="Hor. Arrange",value=#"root:Packages:analysisTools:arrangementOptions",disable=1
	PopUpMenu vertDisplayArrangementPopUp win=analysis_tools,pos={160,yPos},size={75,20},title="Vert. Arrange",value=#"root:Packages:analysisTools:arrangementOptions",disable=1
	CheckBox dispAveragesCheck win=analysis_tools,pos={10,yPos+20},size={50,20},title="Averages",disable=1
	SetVariable scanOrderROIdisplay win=analysis_tools,pos={10,yPos+40},size={175,20},title="Scan Order",value=_STR:"",disable=1
	//SetVariable roiOrderROIdisplay win=analysis_tools,pos={10,yPos+60},size={175,20},title="ROI Order",value=_STR:"",disable=1
	
	//for Get Dendritic Mask Function
	SetVariable maskThreshold win=analysis_tools,pos={96,62},size={100,20},title="Threshold",value=_NUM:0.05,limits={0,inf,0.005},disable=1
	CheckBox mask3DCheck win=analysis_tools,pos={10,82},size={50,20},title="3D",value=0,disable=1
	
	//For dF Map
	CheckBox varianceMapCheck win=analysis_tools,pos={140,61},size={100,20},title="Variance Map",disable=1
	CheckBox histogramCheck win=analysis_tools,pos={10,110},size={100,20},title="Make Histogram",disable=1
	CheckBox cleanUpNoise win=analysis_tools,pos={10,130},size={100,20},title="CleanUp Noise",disable=1
	SetVariable cleanUpNoiseThresh win=analysis_tools,pos={110,131},size={90,20},title="Threshold",value=_NUM:1.5,disable=1
	CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,150},size={150,20},title="Remove Laser Response",disable=1
	SetVariable spatialFilterCheck win=analysis_tools,pos={215,163},bodywidth=35,size={100,20},title="Pre Spatial Filter",value=_NUM:5,disable=1
	SetVariable postSpatialFilter win=analysis_tools,pos={215,183},bodywidth=35,size={100,20},title="Post Spatial Filter",value=_NUM:3,disable=1
	
		
	//Errors
	PopUpMenu errType win=analysis_tools,pos={20,120},size={50,20},title="Type",value="sem;sdev",disable=1

	//Load PClamp
	Button OpenABF2Loader win=analysis_tools,pos={71,66},size={150,20},title="Open PClamp Loader",disable=1,proc=atButtonProc
	
	//For ROI From Map
	CheckBox avgResultsCheck win=analysis_tools,pos={10,81},size={50,20},title="Avg Results",disable=1
	
	//For Mask Scan Data
	CheckBox maskAllFoldersCheck win=analysis_tools,pos={192,85},size={20,20},title="ALL",disable=1
	PopUpMenu maskListPopUp win=analysis_tools,pos={10,85},size={150,20},title="Masks",value=GetMaskWaveList(),disable=1
	
	//For Operation
	getWaveMatchList()
	SetVariable waveMatch win=analysis_tools,pos={80,62},size={150,20},title="Match",value=_STR:"*",disable=1,proc=atSetVarProc
	SetVariable waveNotMatch win=analysis_tools,pos={80,82},size={150,20},title="Not",value=_STR:"",disable=1,proc=atSetVarProc
	ListBox matchListBox win=analysis_tools,pos={5,120},size={225,320},mode=4,listWave=AT_waveListTable,selWave=AT_selWave,disable=1,proc=atListBoxProc
	SetVariable operation win=analysis_tools,pos={80,469},size={255,20},title="Operation",value=_STR:"",disable=1
	SetVariable outputSuffix win=analysis_tools,pos={80,450},size={150,20},title="Output Suffix",value=_STR:"",disable=1
	PopUpMenu operationOptionsPop win=analysis_tools,pos={233,447},size={100,20},bodywidth=100,title="",value=#"root:Packages:analysisTools:opList",disable=1,proc=atPopProc
	CheckBox useDataSetCheck win=analysis_tools,pos={238,102},title="",disable=1
	
	//For Line Profile
	SetVariable lineProfileWidth win=analysis_tools,pos={242,62},size={75,20},title="Width",value=_NUM:5,disable=1
	PopUpMenu SR_waveList win=analysis_tools,pos={35,60},bodywidth=200,size={200,20},title = " ",value=WinList("*",";","WIN:1"),proc=AT_ScanRegistryPopUpProc,disable=1 //also for scan register
	Button saveLineProfile win=analysis_tools,pos={35,98},size={75,20},title="Save Path",disable=1,proc=atButtonProc
	SetVariable saveLineProfileSuffix win=analysis_tools,pos={115,100},size={75,20},title="Suffix",disable=1,value=_STR:""
	Button applyLineProfile win=analysis_tools,pos={35,140},size={75,20},title="Apply Path",disable=1,proc=atButtonProc
	CheckBox useScanListCheck win=analysis_tools,pos={115,142},size={75,20},title="Use Scan List",disable=1
	PopUpMenu lineProfileTemplatePopUp win=analysis_tools,pos={62,120},bodywidth=130,size={130,20},disable=1,title="Paths",value=getSavedLineProfileList()
	CheckBox collapseLineProfileCheck win=analysis_tools,pos={115,162},size={75,20},title="Collapse",disable=1
	CheckBox dFLineProfileCheck win=analysis_tools,pos={248,142},size={75,20},title="∆F/F",disable=1
	CheckBox distanceOnlyCheck win=analysis_tools,pos={295,142},size={75,20},title="Dist.\rOnly",disable=1
	
	//For ROI segmenter
	Button OpenMaskButton win=analysis_tools,size={125,20},pos={197,85},title="Open Mask",disable=1,proc=atButtonProc
	Button GetSeedPosition win=analysis_tools,size={125,20},pos={197,110},title="Get Seed Position",disable=1,proc=atButtonProc

	//For image registration (translation)
	
	Button applyImageRegistration win=analysis_tools,size={150,20},pos={125,160},title="Apply Template",disable=1,proc=atButtonProc
	Button equalizeDimensions win=analysis_tools,size={150,20},pos={125,185},title="Equalize Dimensions",disable=1,proc=atButtonProc
	PopUpMenu refImagePopUp win=analysis_tools,bodywidth=175,pos={220,85},title="Reference Image",disable=1,value=#"root:Packages:analysisTools:scanFolderList"
	PopUpMenu testImagePopUp win=analysis_tools,bodywidth=175,pos={220,110},title="Test Image",disable=1,value=#"root:Packages:analysisTools:scanFolderList"
	PopUpMenu registrationTemplatePopUp win=analysis_tools,bodywidth=175,pos={220,135},title="Templates",disable=1,value=getWaveList("W_RegParams")
	//WaveList("W_RegParams",";","")
	
	//For Data Sets
	ListBox dataSetListBox win=analysis_tools,pos={235,120},size={100,320},mode=1,listWave=dataSetNames,selWave=dataSetSelWave,disable=1,proc=atListBoxProc
	Button addDataSet win=analysis_tools,pos={234,440},size={100,20},title="Add Data Set",disable=1,proc=atButtonProc
	Button addDataSetFromSelection win=analysis_tools,pos={234,460},size={100,20},title="Add Selection",disable=1,proc=atButtonProc
	Button delDataSet win=analysis_tools,pos={234,480},size={100,20},title="Del Data Set",disable=1,proc=atButtonProc
	SetVariable dataSetName win=analysis_tools,pos={80,451},size={130,20},title="DS Name",disable=1,value=_STR:"NewDS"
	Button matchStraddOR win=analysis_tools,pos={230,59},size={22,20},title="OR",fsize=8,disable=1,proc=atButtonProc
	Button notMatchStraddOR win=analysis_tools,pos={230,79},size={22,20},title="OR",fsize=8,disable=1,proc=atButtonProc
	SetVariable waveGrouping win=analysis_tools,pos={80,471},size={130,20},title="Grouping",disable=1,value=_STR:"",proc=atSetVarProc
	
	SetVariable prefixGroup win=analysis_tools,pos={10,491},size={40,20},title="P",disable=1,value=_STR:"",proc=atSetVarProc
	SetVariable groupGroup win=analysis_tools,pos={50,491},size={40,20},title="G",disable=1,value=_STR:"",proc=atSetVarProc
	SetVariable seriesGroup win=analysis_tools,pos={90,491},size={40,20},title="Se",disable=1,value=_STR:"",proc=atSetVarProc
	SetVariable sweepGroup win=analysis_tools,pos={130,491},size={40,20},title="Sw",disable=1,value=_STR:"",proc=atSetVarProc
	SetVariable traceGroup win=analysis_tools,pos={170,491},size={40,20},title="T",disable=1,value=_STR:"",proc=atSetVarProc
	
	//For Rescale Scans
	SetVariable scaleFactor win=analysis_tools,pos={125,62},size={125,20},bodywidth=40,title="Scale Factor (µm/volt)",disable=1,value=_NUM:60
	
	//For ROI Grid
	SetVariable gridSizeX win=analysis_tools,pos={10,108},size={60,20},title="X Size",value=_NUM:10,limits={1,inf,1},disable=1
	SetVariable gridSizeY win=analysis_tools,pos={80,108},size={60,20},title="Y Size",value=_NUM:10,limits={1,inf,1},disable=1
	CheckBox overwriteGrid win=analysis_tools,pos={10,60},size={60,20},title="Overwrite",disable=1
	CheckBox optimizePosition win=analysis_tools,pos={84,60},size={60,20},title="Optimize Positions",disable=1
	SetVariable pctOverlap win=analysis_tools,pos={196,61},size={80,20},title="% Overlap",value=_NUM:0,disable=1
	SetVariable pixelThresholdPct win=analysis_tools,pos={196,87},size={95,20},title="% Threshold",value=_NUM:0,limits={0,100,1},disable=1
	
	//For External Functions
	PopUpMenu extFuncPopUp win=analysis_tools,pos={21,67},size={150,20},title="Functions:",fSize=12,disable=1,value=#"root:Packages:analysisTools:extFuncList",proc=atPopProc
	
	String/G root:Packages:analysisTools:DSNames
	SVAR DSNames = root:Packages:analysisTools:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
	
	PopUpMenu extFuncDS win=analysis_tools,pos={21,90},size={150,20},title="Waves",fSize=12,disable=1,value=#"root:Packages:analysisTools:DSNames",proc=atPopProc
	PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
	Button extFuncHelp win=analysis_tools,pos={209,66},size={20,20},title="?",disable=1,proc=atButtonProc
	
	Make/N=0/T/O root:Packages:analysisTools:emptyWave
	Wave/T emptyWave = root:Packages:analysisTools:emptyWave
	ListBox extFuncDSListBox win=analysis_tools,size={155,344},pos={180,121},mode=0,listWave=emptyWave,disable=1
	
	//For MultiROI
	CheckBox doDarkSubtract win=analysis_tools,pos={10,250},size={150,20},title="Dark Subtraction",disable=1
	CheckBox activePixelsOnly win=analysis_tools,pos={10,270},size={150,20},title="Active Pixels Only",disable=1
	SetVariable activePixelThreshSize win=analysis_tools,pos={110,272},size={40,20},limits={0,inf,0.05},title="",value=_NUM:1.25,disable=1
	
	
	yPos += 20
	setvariable bslnEndVar, win = analysis_tools, pos = {10,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GbslnEnd, title = "Bsln End"
	setvariable peakEndVar, win = analysis_tools, pos = {120,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GpeakEnd, title = "Peak End"
	setvariable BatchsizeVar, win = analysis_tools, pos = {230,yPos}, size = {100, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GBatchSize, title = "Batch Size"
	
	//setvariable SpaceFilterVar, win = analysis_tools, pos = {30,yPos}, size = {130, 30}, disable = able, noproc, value = root:Packages:analysisTools:GSpaceFilter, title = "Space Filter (pix)"
	//CheckBox SpaceFilterBox,win = analysis_tools,pos={10,yPos},title = "", proc = atCheckProc
	//setvariable DarkValueVar, win = analysis_tools, pos = {190,yPos}, size = {100, 30}, disable = able, noproc, value = root:Packages:analysisTools:GdarkValue, title = "Dark Subt."
	//CheckBox DarkSubtBox,win = analysis_tools,pos={170,yPos}, title = "", proc = atCheckProc
	
	yPos += 20
	SetVariable SmoothFilterVar win=analysis_tools, pos={20,yPos},size={80,30},bodywidth=35,disable =0,value=root:Packages:analysisTools:GSmoothFilter, title = "Smooth"
	CheckBox SmoothBox,win = analysis_tools,pos={10,yPos}, title = "", proc = atCheckProc

	//CheckBox NotSeqBox,win = analysis_tools,pos={170,yPos},title="Not in sequence?",proc = atCheckProc
	
	yPos+=20
	CheckBox ch1Check,win=analysis_tools,pos={10,yPos},title="Ch1"
	CheckBox ch2Check,win=analysis_tools,pos={50,yPos},title="Ch2"
	CheckBox ratioCheck,win=analysis_tools,pos={90,yPos},title="Ratio"
	CheckBox ratioCheck,win=analysis_tools,pos={90,yPos},title="Ratio"
	
	yPos += 20
	CheckBox getPeaksCheck,win=analysis_tools,pos={10,yPos},title="Get Peaks"
	SetVariable pkWindow win=analysis_tools,title="Width",pos={68,yPos+1},bodywidth=35,value=_NUM:0,limits={0,inf,0.05},size={80,20},disable=0
	
	yPos +=20
	CheckBox doAvgCheck,win=analysis_tools,pos={10,yPos},title="Get tAvg"
	CheckBox doAvgROIsCheck,win=analysis_tools,pos={90,yPos},title="Avg ROIs"
	
	yPos += 20
	SetVariable angleList win=analysis_tools,title="Angles",pos={10,yPos-1},value=_STR:"",size={175,20},disable=0
	
	yPos += 20
	Wave/T/Z presetAngleWave = root:Packages:analysisTools:presetAngleWave
	If(!WaveExists(presetAngleWave))
		Make/O/T/N=(3,3) root:Packages:analysisTools:presetAngleWave
		Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
		presetAngleWave[0][0] = "-----"
		presetAngleWave[0][1] = ""
		presetAngleWave[1][0] = "Linear"
		presetAngleWave[1][1] = "0,45,90,135,180,225,270,315"
		presetAngleWave[2][0] = "Alternating"
		presetAngleWave[2][1] = "0,180,45,225,90,270,135,315"
	EndIf
	
	String/G root:Packages:analysisTools:presetAngleLists
	SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
	presetAngleLists = ""
	
	For(i=0;i<DimSize(presetAngleWave,0);i+=1)
		presetAngleLists += presetAngleWave[i][0] + ";"
	EndFor

	PopUpMenu presetAngleListPop win=analysis_tools,title="Presets",bodywidth=80,pos={10,yPos-1},value=#"root:Packages:analysisTools:presetAngleLists",disable=0,proc=atPopProc
	Button addPresetAngle win=analysis_tools,title="+",pos={100,yPos-1},size={20,20},disable=1,proc=atButtonProc
	Button deletePresetAngle win=analysis_tools,title="-",pos={125,yPos-1},size={20,20},disable=1,proc=atButtonProc
	
	DrawAction/W=analysis_tools delete
	ChangeControls("Data Sets","MultiROI")
	
	DoWindow/F analysis_tools
	
	
	//PopUp menus
	//PopupMenu ROIColorPop win = analysis_tools,pos={15,325},popColor= (0,0,0),proc = ROIColorPopProc, value= #"\"*COLORPOP*\""
	
	//Checkboxes
	
	//Build qkSpot Controls, keep hidden
	//qkSpot_BuildControls()
	//yPos+=25

	
	//Clear any text drawing layers from qkSpot build

	//Group Box
//	GroupBox AT_ControlGroupBox win=analysis_tools,pos={5,yPos},size={width-245,controlHeight[0]}
End

//Gets the external function list
Function/S getExternalFunctions(fileList)
	String fileList
	Variable numFiles,i
	String theFile,theList = ""
	
	numFiles = ItemsInList(fileList,";")
	
	For(i=0;i<numFiles;i+=1)
		theFile = StringFromList(i,fileList,";")
		theList += FunctionList("*", ";","WIN:" + theFile)
	EndFor	
	
	//Only matches functions with the prefix 'AT_'
	//This allow user to only include master functions, but also have many other subroutines that it uses, but
	//aren't seen by the function list.
	theList = ListMatch(theList,"AT_*",";")
	
	//Removes the AT from this list for easier viewing in the drop down menu
	theList = ReplaceString("AT_",theList,"")
	
	return theList
End


//Gets the data set names that already exist
Function/S GetDataSetNames()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	String dataSets,cdf
	Variable numDataSets,i
	
	cdf = GetDataFolder(1)
	SetDataFolder root:Packages:analysisTools:DataSets:
	
	dataSets = WaveList("DS_*",";","TEXT:1")
	numDataSets = ItemsInList(dataSets,";")
	Redimension/N=(numDataSets) dataSetNames
	
	For(i=0;i<numDataSets;i+=1)
		dataSetNames[i] = RemoveListItem(0,StringFromList(i,dataSets,";"),"_")	//also removes the DS from the front for display purposes
	EndFor
	
	SetDataFolder $cdf
End

//Assigns control variables to functions from the 'Command' pop up menu
Function CreateControlLists(cmdList)
	String cmdList
	Make/O/N=(ItemsInList(cmdList,";")) root:Packages:analysisTools:controlHeight
	Wave controlHeight = root:Packages:analysisTools:controlHeight
	//Add the names of your controls to the appropriate list to assign controls to that tab.
	//Assignment allows the tab to automatically hide or show controls assigned to that tab when it gets clicked. 
	//Make sure the name of a new control list is with format: 'ctrlList_' + 'name of control'
	
	//MultiROI
	String/G root:Packages:analysisTools:ctrlList_multiROI
	SVAR ctrlList_MultiROI = root:Packages:analysisTools:ctrlList_multiROI
	ctrlList_MultiROI = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;DarkValueVar;SmoothBox;SpaceFilterVar;SmoothFilterVar;angleList;BatchsizeVar;numtrialsVar;"
	ctrlList_MultiROI += "ch1Check;ch2Check;ratioCheck;getPeaksCheck;pkWindow;doAvgCheck;presetAngleListPop;addPresetAngle;deletePresetAngle;RemoveLaserResponseCheck;"
	ctrlList_MultiROI += "doDarkSubtract;activePixelsOnly;activePixelThreshSize;doAvgROIsCheck"

	
	//ROI From Map
	String/G root:Packages:analysisTools:ctrlList_roiFromMap
	SVAR ctrlList_roiFromMap = root:Packages:analysisTools:ctrlList_roiFromMap
	ctrlList_roiFromMap = "SmoothFilterVar;ch1Check;ch2Check;ratioCheck;SmoothBox;avgResultsCheck"

		
	//df Map
	String/G root:Packages:analysisTools:ctrlList_dfMap
	SVAR ctrlList_dfMap = root:Packages:analysisTools:ctrlList_dfMap
	//ctrlList_dfMap = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;DarkValueVar;SmoothBox;SpaceFilterVar;SmoothFilterVar;"
	//ctrlList_dfMap += "SpaceFilterBox;DarkSubtBox;NotSeqBox;ch1Check;ch2Check;ratioCheck"
	ctrlList_dfMap = "ch1Check;ch2Check;ratioCheck;maskListPopUp;varianceMapCheck;peakStVar;peakEndVar;bslnStVar;bslnEndVar;histogramCheck;cleanUpNoise;"
	ctrlList_dfMap += "RemoveLaserResponseCheck;SmoothFilterVar;SmoothBox;spatialFilterCheck;maskAllFoldersCheck;postSpatialFilter;cleanUpNoiseThresh;doDarkSubtract"

		
	//Average
	String/G root:Packages:analysisTools:ctrlList_average
	SVAR ctrlList_average = root:Packages:analysisTools:ctrlList_average
	ctrlList_average = "extFuncDS;extFuncChannelPop;extFuncDSListBox"
	
	//Error
	String/G root:Packages:analysisTools:ctrlList_error
	SVAR ctrlList_error = root:Packages:analysisTools:ctrlList_error
	ctrlList_error = "extFuncDS;extFuncChannelPop;extFuncDSListBox;errType"
	
	//Kill Waves
	String/G root:Packages:analysisTools:ctrlList_killwaves
	SVAR ctrlList_killwaves = root:Packages:analysisTools:ctrlList_killwaves
	ctrlList_killwaves = "extFuncDS;extFuncChannelPop;extFuncDSListBox"
	
	//Space-Time dF
	String/G root:Packages:analysisTools:ctrlList_spacetimeDF
	SVAR ctrlList_spacetimeDF = root:Packages:analysisTools:ctrlList_spacetimeDF
	ctrlList_spacetimeDF = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;SmoothBox;SmoothFilterVar"

	
	//ROI Tuning Curve
	String/G root:Packages:analysisTools:ctrlList_roiTuningCurve
	SVAR ctrlList_roiTuningCurve = root:Packages:analysisTools:ctrlList_roiTuningCurve
	ctrlList_roiTuningCurve = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;DarkValueVar;SmoothBox;SmoothFilterVar;"
	ctrlList_roiTuningCurve += "angleList;ch1Check;ch2Check;ratioCheck"

	
	//qkSpot
	String/G root:Packages:analysisTools:ctrlList_qkSpot
	SVAR ctrlList_qkSpot = root:Packages:analysisTools:ctrlList_qkSpot
	ctrlList_qkSpot = "matPrefix;prefTheta;preFilterType;preFilter;preFilterSz;postFilterType;postFilter;postFilterSz;bslnStart;peakStart;bslnEnd;peakEnd;"
	ctrlList_qkSpot +=	"subSlider;subDisplay;inflSlider;inflDisplay;runQkSpot;angleList"
	
	//Analysis tab control group
	String/G root:Packages:analysisTools:ctrlList_analysisTab
	SVAR ctrlList_analysisTab = root:Packages:analysisTools:ctrlList_analysisTab
	ctrlList_analysisTab = ctrlList_MultiROI + ";" + ctrlList_dfMap + ";"
	
	//Mapping tab control group 
	String/G root:Packages:analysisTools:ctrlList_mappingTab
	SVAR ctrlList_mappingTab = root:Packages:analysisTools:ctrlList_mappingTab
	ctrlList_mappingTab = ""
	
	//Displaying ROI traces
	String/G root:Packages:analysisTools:ctrlList_displayROIs
	SVAR ctrlList_displayROIs = root:Packages:analysisTools:ctrlList_displayROIs
	ctrlList_displayROIs = "horDisplayArrangementPopUp;vertDisplayArrangementPopUp;dispAveragesCheck;scanOrderROIdisplay;roiOrderROIdisplay;"
	ctrlList_displayROIs += "presetAngleListPop;addPresetAngle;deletePresetAngle"
	
	//Registering scans that are distorted during bidirectional scanning
	String/G root:Packages:analysisTools:ctrlList_adjustGalvoDistort
	SVAR ctrlList_adjustGalvoDistort = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
	ctrlList_adjustGalvoDistort = "SR_waveList;SR_phase;SR_phaseLock;SR_phaseVal;SR_pixelDeltaLock;SR_pixelDelta;SR_divergenceLock;SR_divergence;"
	ctrlList_adjustGalvoDistort += "SR_frequencyLock;SR_frequency;SR_pixelOffsetLock;SR_pixelOffset;SR_autoRegisterButton;SR_addROIButton;SR_reset;"
	ctrlList_adjustGalvoDistort += "SR_showROIButton;SR_saveTemplateButton;SR_applyTemplate;SR_templatePopUp;SR_UseAnalysisToolsCheck;ch1Check;ch2Check"

	//Get Dendritic Mask
	String/G root:Packages:analysisTools:ctrlList_getDendriticMask
	SVAR ctrlList_getDendriticMask = root:Packages:analysisTools:ctrlList_getDendriticMask
	ctrlList_getDendriticMask = "ch1Check;ch2Check;maskThreshold;mask3DCheck"
	
	//Mask Scan Data
	String/G root:Packages:analysisTools:ctrlList_maskScanData
	SVAR ctrlList_maskScanData = root:Packages:analysisTools:ctrlList_maskScanData
	ctrlList_maskScanData = "ch1Check;ch2Check;maskListPopUp"
	
	//Operation
	String/G root:Packages:analysisTools:ctrlList_operation
	SVAR ctrlList_operation = root:Packages:analysisTools:ctrlList_operation
	ctrlList_operation = "waveMatch;waveNotMatch;matchListBox;operation;outputSuffix;operationOptionsPop;dataSetListBox;useDataSetCheck;matchStraddOR;notMatchStraddOR"
	
	//Get Peaks
	String/G root:Packages:analysisTools:ctrlList_getPeaks
	SVAR ctrlList_getPeaks = root:Packages:analysisTools:ctrlList_getPeaks
	ctrlList_getPeaks = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;extFuncDS;extFuncDSListBox;extFuncChannelPop"
	
	//Line Profile
	String/G root:Packages:analysisTools:ctrlList_lineProfile
	SVAR ctrlList_lineProfile = root:Packages:analysisTools:ctrlList_lineProfile
	ctrlList_lineProfile = "SR_waveList;lineProfileWidth;saveLineProfile;useScanListCheck;applyLineProfile;lineProfileTemplatePopUp;saveLineProfileSuffix;"
	ctrlList_lineProfile += "ch1Check;ch2Check;collapseLineProfileCheck;dFLineProfileCheck;bslnStVar;bslnEndVar;SmoothFilterVar;SmoothBox;peakStVar;peakEndVar;distanceOnlyCheck"

	//ROI Segmenter
	String/G root:Packages:analysisTools:ctrlList_roiSegmenter
	SVAR ctrlList_roiSegmenter = root:Packages:analysisTools:ctrlList_roiSegmenter
	ctrlList_roiSegmenter = "OpenMaskButton;GetSeedPosition;maskListPopUp"
	
	//Register image (translation)
	String/G root:Packages:analysisTools:ctrlList_registerImage
	SVAR ctrlList_registerImage = root:Packages:analysisTools:ctrlList_registerImage
	ctrlList_registerImage = "applyImageRegistration;refImagePopUp;testImagePopUp;registrationTemplatePopUp;useScanListCheck;ch1Check;ch2Check"
	
	//Vector Sum Map
	String/G root:Packages:analysisTools:ctrlList_vectorSumMap
	SVAR ctrlList_vectorSumMap = root:Packages:analysisTools:ctrlList_vectorSumMap
	ctrlList_vectorSumMap = "ch1Check;ch2Check;ratioCheck;angleList;histogramCheck;presetAngleListPop;addPresetAngle;deletePresetAngle" 
	
	//Rescale scans Rescale Scans
	String/G root:Packages:analysisTools:ctrlList_rescaleScans
	SVAR ctrlList_rescaleScans = root:Packages:analysisTools:ctrlList_rescaleScans
	ctrlList_rescaleScans = "ch1Check;ch2Check;scaleFactor" 
	
	//Data Sets
	String/G root:Packages:analysisTools:ctrlList_dataSets
	SVAR ctrlList_dataSets = root:Packages:analysisTools:ctrlList_dataSets
	ctrlList_dataSets = "waveMatch;waveNotMatch;matchListBox;dataSetListBox;addDataSet;dataSetName;delDataSet;"
	ctrlList_dataSets += "waveGrouping;addDataSetFromSelection;matchStraddOR;notMatchStraddOR;"
	ctrlList_dataSets += "prefixGroup;GroupGroup;SeriesGroup;SweepGroup;TraceGroup"
	//Get Peak Times
	String/G root:Packages:analysisTools:ctrlList_getPeakTimes
	SVAR ctrlList_getPeakTimes = root:Packages:analysisTools:ctrlList_getPeakTimes
	ctrlList_getPeakTimes = "peakStVar;peakEndVar;dataSetListBox;useDataSetCheck" 
	
	//ROI Grid
	String/G root:Packages:analysisTools:ctrlList_roiGrid
	SVAR ctrlList_roiGrid = root:Packages:analysisTools:ctrlList_roiGrid
	ctrlList_roiGrid = "maskListPopUp;gridSizeX;gridSizeY;overwriteGrid;ch1Check;ch2Check;optimizePosition;pctOverlap;pixelThresholdPct" 

	//For External Functions
	String/G root:Packages:analysisTools:ctrlList_extFunc
	SVAR ctrlList_extFunc = root:Packages:analysisTools:ctrlList_extFunc
	ctrlList_extFunc = "extFuncPopUp;extFuncDS;extFuncChannelPop;extFuncDSListBox;extFuncHelp"
	
	//Load PClamp
	String/G root:Packages:analysisTools:ctrlList_loadPClamp
	SVAR ctrlList_loadPClamp = root:Packages:analysisTools:ctrlList_loadPClamp
	ctrlList_loadPClamp = "OpenABF2Loader"
End

//Called by the buttons
Function atButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	//Parameters
	NVAR Gnumtrials = root:Packages:analysisTools:Gnumtrials
	NVAR Gbatchsize = root:Packages:analysisTools:Gbatchsize
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt 
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd 
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR Gred = root:Packages:analysisTools:Gred
	NVAR Ggreen = root:Packages:analysisTools:Ggreen
	NVAR Gblue = root:Packages:analysisTools:Gblue
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	Variable i
	
	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlName)
				case "AT_RunCmd":
					ControlInfo/W=analysis_tools AT_CommandPop
					If(cmpstr(S_Value,"Line Profile") == 0)
						ControlInfo/W=analysis_tools SR_WaveList
						runCmdStr = ""
						runCmdStr = "DoWindow/F " + S_Value + ";getLineProfile()"
						RunCmd(runCmdStr)
					ElseIf(cmpstr(S_Value,"External Function") == 0 || cmpstr(S_Value,"Average") == 0 || cmpstr(S_Value,"Error") == 0 || cmpstr(S_Value,"Kill Waves") == 0)
						SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
						NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
						NVAR wsn = root:Packages:analysisTools:DataSets:wsn
						wsDims = ""
						numWaveSets = 0
						
						//Command string
						If(cmpstr(S_Value,"External Function") == 0)
							runCmdStr = SetExtFuncCmd()
						EndIf
					
						//WaveSet data
						ControlInfo/W=analysis_tools extFuncDS
						numWaveSets = GetNumWaveSets(S_Value)
						wsDims = GetWaveSetDims(S_Value)
						
						//Run the command for the designated number of wavesets
						Variable ref = StartMSTimer
						For(wsn=0;wsn<numWaveSets;wsn+=1)		
							RunCmd(runCmdStr)
						EndFor
						Variable dur = StopMSTimer(ref)/1000000
						print runCmdStr + "..." + num2str(numWaveSets) + " wavesets..." + num2str(dur) + " s"
					Else	
						RunCmd(runCmdStr)
					EndIf

					break
				case "nudgeROI":
					NudgeROI()
					break
				case "saveLineProfile":
					saveLineProfile()
					break
				case "applyLineProfile":
					applyLineProfile()
					break
				case "AT_Help":
					ControlInfo/W=analysis_tools AT_CommandPop
					AT_DisplayHelpMessage(S_Value)
					break
				case "extFuncHelp":
					ControlInfo/W=analysis_tools extFuncPopUp
					displayExtFuncHelp(S_Value)
					break
				case "ROISegmentButton":
					ControlInfo/W=analysis_tools maskListPopUp
					Wave theMask = $S_Value
					OpenMask(theMask)
					break
				case "applyImageRegistration":
					applyImageRegTemplate()
					break
				case "equalizeDimensions":
					EqualizeDimensions()
					break
				case "addPresetAngle":
					SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					
					String theAngles,theName
					
					Prompt theAngles,"Enter the angles: "
					Prompt theName,"Enter name of angle list: "
					DoPrompt "Add preset angle list",theName,theAngles
					If(V_Flag)
						return -1
					EndIf
					
					presetAngleLists += theName + ";"
					Variable size = DimSize(presetAngleWave,0)
					Redimension/N=(size+1,-1) presetAngleWave
					presetAngleWave[size][0] = theName
					presetAngleWave[size][1] = theAngles
					break
				case "deletePresetAngle":
					SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					
					ControlInfo/W=analysis_tools presetAngleListPop
					presetAngleLists = RemoveListItem(V_Value-1,presetAngleLists,";")
					DeletePoints V_Value-1,1,presetAngleWave
					break
				case "atBrowseButton":
					SVAR whichList = root:Packages:analysisTools:whichList
					
					If(cmpstr(whichList,"AT") == 0)
						whichList = "Browser"
					ElseIf(cmpstr(whichList,"Browser") == 0)
						whichList = "AT"
					EndIf
					
					flipLists(whichList)
					break
				case "addDataSet":
					Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
					ControlInfo/W=analysis_tools dataSetName
					addDataSet(S_Value)
					ListBox dataSetListBox win=analysis_tools,selRow=DimSize(dataSetNames,0)-1
					fillFilterTable()
					break
				case "addDataSetFromSelection":
					ControlInfo/W=analysis_tools dataSetName
					
					addDataSet(S_Value,selection=1)
					break
				case "delDataSet":
					ControlInfo/W=analysis_tools dataSetListBox
					delDataSet(V_Value)
					break
				case "reloadATButton":
					GetWindow/Z analysis_tools wsize
					KillWindow/Z analysis_tools
					
					LoadAnalysisSuite(left=V_left,top=V_top-50)
					//-50 accounts for the initial 50 pixel offset it gets upon first loading.
					break
				case "atViewerButton":
					If(viewerOpen)
						closeViewer()
					Else
						openViewer()
					EndIf
					break
				case "atViewerAutoScaleButton":
					SetAxis/W=analysis_tools#atViewerGraph/A
					break
				case "atViewerSeparateVertButton":
					SeparateTraces("vert")
					break
				case "atViewerSeparateHorizButton":
					SeparateTraces("horiz")
					break
				case "atViewerDisplayTracesButton":
					String theTraces = TraceNameList("analysis_tools#atViewerGraph",";",1)
	
					GetWindow/Z analysis_tools wsize
					//Duplicates the Viewer graph outside of the viewer
					String winRec = WinRecreation("analysis_tools#atViewerGraph",0)
					
					Variable pos1 = strsearch(winRec,"/W",0)
					Variable pos2 = strsearch(winRec,"/FG",0) - 1
					
					String matchStr = winRec[pos1,pos2]
					winRec = ReplaceString(matchStr,winRec,"/W=(" + num2str(V_right+10) + "," + num2str(V_top) + "," + num2str(V_right+360) + "," + num2str(V_top+200) + ")")
					winRec = ReplaceString("/FG=(FL,VT,FR,VB)/HOST=#",winRec,"")
					Execute/Q/Z winRec
					break
				case "atViewerClearTracesButton":
					clearTraces()
				case "matchStraddOR":
					ControlInfo/W=analysis_tools waveMatch
					SetVariable waveMatch win=analysis_tools,value=_STR:S_Value + "||"
					break
				case "notMatchStraddOR":
					ControlInfo/W=analysis_tools waveNotMatch
					SetVariable waveNotMatch win=analysis_tools,value=_STR:S_Value + "||"
					break
				case "OpenABF2Loader":
					InitializeABFPanel()
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Finds any help message within an external function, prints the help message
Function displayExtFuncHelp(theFunction)
	String theFunction
	Variable i
	String char = ""
	theFunction = "AT_" + theFunction
	
	String functionStr = ProcedureText(theFunction,0)
	Variable pos1 = strsearch(functionStr,"//HELP",0) + 7
	Variable pos2 = strsearch(functionStr,"//ENDHELP",0)
	
	String helpStr = theFunction + ": " + functionStr[pos1,pos2-1]
	
	//Inserts a line break every 50 characters, rounded to the next space
	If(strlen(helpStr) > 100)
		i=100
		Do
			char = helpStr[i]
			If(!cmpstr(char," "))
				helpStr[i] = char + "\r\t\t"
			Else
				i = strsearch(helpStr," ",i)
				helpStr[i] = "\r\t\t"
			EndIf
			i+=100
		While(i<strlen(helpStr))
	EndIf
	print "-----------HELP-------------"
	print helpStr
	print "----------------------------"
End

//Removes a dataset from the list
Function delDataSet(selectedRow)
	Variable selectedRow
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	//Don't allow the last data set to be deleted
	If(DimSize(dataSetNames,0) == 0)
		return -1
	EndIf
	
	//returns if no data set is selected
	If(selectedRow == -1)
		return 0
	EndIf
	
	String dataSetName = datasetNames[selectedRow]
	Wave theDataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Wave ogDataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	DeletePoints/M=0 selectedRow,1,dataSetNames,dataSetSelWave,ogDataSetWave,dsFilters
	KillWaves/Z theDataSetWave,ogDataSetWave
End

//Adds the wave to a new dataset for quick result viewing
Function outputDS(outWave)
	Wave outWave
	SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
	NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
	NVAR wsn = root:Packages:analysisTools:DataSets:wsn
	
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	//Input data set in use
	ControlInfo/W=analysis_tools extFuncDS
	Wave/T/Z ds = GetDataSetWave(dsName=S_Value)
	
	//Resize data set definition waves
	If(wsn == 0)
		//only make new data set if it doesn't exist
		If(!WaveExists(root:Packages:analysisTools:DataSets:DS_output))
			Redimension/N=(DimSize(dataSetNames,0)+1) dataSetNames,dataSetSelWave
			dataSetNames[DimSize(dataSetNames,0)-1] = "output"
		EndIf
		
		//New output ds waves
		Make/O/T/N=0 root:Packages:analysisTools:DataSets:DS_output,root:Packages:analysisTools:DataSets:ogDS_output
		Make/O/T/N=0 root:Packages:analysisTools:DataSets:DS_output,root:Packages:analysisTools:DataSets:DS_output		
	EndIf
	
	Wave/T ogdsOut = root:Packages:analysisTools:DataSets:ogDS_output
	Wave/T dsOut = root:Packages:analysisTools:DataSets:DS_output
	
	Redimension/N=(wsn*2+2) dsOut
	dsOut[wsn*2] = "----WSN " + num2str(wsn)  + "----"
	dsOut[wsn*2+1] = GetWavesDataFolder(outWave,2)//full path of the wave gets put into the data set table
	
	Redimension/N=(wsn+1) ogdsOut
	ogdsOut[wsn] = GetWavesDataFolder(outWave,2)
	
	//Set the data set list for use in external functions
	SVAR DSNames = root:Packages:analysisTools:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
	
	Variable i
	For(i=0;i<DimSize(dsFilters,0);i+=1)
		If(!cmpstr(dsFilters[i],"output"))
			//make fresh filter set for the output wave
			dsFilters[i][1] = ";;;;;;;;"
			return 0
		EndIf
	EndFor
	
	//If there was no output filter set
	Variable size = DimSize(dsFilters,0)
	Redimension/N=(size+1,2) dsFilters
	dsFilters[size][0] = "output"
	dsFilters[size][1] = ";;;;;;;;"
End

//adds a dataset defined by the matched waves in the list box
Function addDataSet(dataSetName,[selection])
	String dataSetName
	Variable selection
	Variable numWaves,currentNumSets,i,j,numScans
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	
	//Make the ds filter wave if it doesn't exist
	If(!WaveExists(root:Packages:analysisTools:DataSets:dsFilters))
		Make/O/T/N=(1,2) root:Packages:analysisTools:DataSets:dsFilters
	EndIf
	
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	SVAR cdf = root:Packages:MBr:currentDataFolder
	String possiblePath
		
	If(selection)
		//Get the wave paths from the item list box
		String fullPath = getSelectedItems()
		If(!strlen(fullPath))
			return 0
		EndIf
		numWaves = ItemsInList(fullPath,";")
	Else
		//Get the wave paths from the match list box
		ControlInfo/W=analysis_tools matchListBox
		Wave/T listWave = $("root:Packages:analysisTools:" + S_Value)
		
		If(!WaveExists(listWave))
			return -1
		EndIf
		
		//Get the full paths of the waves in listwave
		SVAR whichList = root:Packages:analysisTools:whichList
		SVAR scanListStr = root:Packages:twoP:examine:scanListStr
		Wave/T folderTable = root:Packages:MBr:folderTable
		
		Wave selFolderWave = root:Packages:analysisTools:selFolderWave
		Variable count = 0 
		
		fullPath = ""
		If(cmpstr(whichList,"AT") == 0)
		   numScans = ItemsInList(scanListStr,";")
			For(i=0;i<numScans;i+=1)
				fullPath += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + listWave[count] + ";"
				count += 1
			EndFor
			
			//If we're just trying to duplicate a currently displayed data set
			//Just take what's sitting in the matchList box.
			If(numScans == 0) 
			
				If(DimSize(listWave,0) == 0)
					return -1
				EndIf
			
				//ds to be copied
				ControlInfo/W=analysis_tools dataSetListBox
				
				Wave/T copyDS = GetDataSetWave(dsName = dataSetNames[V_Value])
				Wave/T ogcopyDS = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetNames[V_Value])
				
				//Make new text wave to hold the data set wave names
				Make/O/T/N=(DimSize(copyDS,0)) $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
				Make/O/T/N=(DimSize(ogcopyDS,0)) $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
				Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
				Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
				
				dataSetWave = copyDS
				ogdataSetWave = ogcopyDS
				
				//Add the DS name to the list wave
				currentNumSets = DimSize(dataSetNames,0)
				Redimension/N=(currentNumSets+1) dataSetNames,dataSetSelWave
				
				fillFilterTable()
				
				dataSetNames[currentNumSets] = dataSetName
				return 0
			EndIf
		ElseIf(cmpstr(whichList,"Browser") == 0)
			If(DimSize(folderTable,0) > 0)
				For(i=0;i<DimSize(folderTable,0);i+=1)
					String previousPath = ""
					If(selFolderWave[i] == 1)
						For(j=count;j<DimSize(listWave,0);j+=1)
							//Is the name of the next possible wave the same as the previously selected wave?
							If(cmpstr(listWave[j],previousPath) == 0)
								continue
							EndIf
							possiblePath = cdf + folderTable[i] + ":" + listWave[j]
							If(WaveExists($possiblePath))	//is the wave in this folder?
								fullPath += possiblePath + ";"
								previousPath = listWave[j]
								count+=1
							EndIf
						EndFor
					//fullPath +=  cdf + folderTable[i] + ":" + listWave[count] + ";"
					//count += 1
					EndIf
				EndFor
			Else
				previousPath = ""
				For(j=0;j<DimSize(listWave,0);j+=1)
					fullPath += cdf + listWave[j] + ";"
				EndFor
			EndIf
			Variable items = ItemsInList(fullPath,";")
		EndIf
		
		numWaves = DimSize(listWave,0)
	EndIf
	
	//Add the DS name to the list wave
	currentNumSets = DimSize(dataSetNames,0)
	Redimension/N=(currentNumSets+1) dataSetNames,dataSetSelWave
	dataSetNames[currentNumSets] = dataSetName

	//Make new text wave to hold the data set wave names
	Make/O/T/N=(numWaves) $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Make/O/T/N=(numWaves) $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	
	//Fill the data set wave
	For(i=0;i<numWaves;i+=1)
		If(strlen(StringFromList(i,fullPath,";")) == 0)
			continue
		EndIf	
		dataSetWave[i] = StringFromList(i,fullPath,";")
	EndFor
	ogdataSetWave = dataSetWave

	Make/N=(DimSize(dataSetWave,0))/T/O root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping
	Wave/T ogDS_saveDSGrouping = root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping
	ogDS_saveDSGrouping = ogdataSetWave
	
	//Reload the data set names
	GetDataSetNames()
	
	SVAR DSNames = root:Packages:analysisTools:DataSets:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
End

//Reads the match, prefix, group, series, etc. inputs to save the filter sets for the selected data set
Function/S GetDSFilters()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	ControlInfo/W=analysis_tools dataSetListBox
	String dsName = dataSetNames[V_Value]
	String dsFilters = ""
	
	ControlInfo/W=analysis_tools waveMatch
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools waveNotMatch
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools waveGrouping
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools prefixGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools groupGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools seriesGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools sweepGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools traceGroup
	dsFilters += S_Value + ";"
	
	return dsFilters
End


//Flips the list boxes between showing scanlistbox and ROI listbox to the full data browser folder/item list boxes
Function flipLists(whichList)
	String whichList
	
	//match strings	
	SVAR matchStr = root:Packages:MBr:matchStr
	SVAR notMatchStr = root:Packages:MBr:notMatchStr

	//current data folder string
	SVAR cdf = root:Packages:MBr:currentDataFolder
	
	//Waves for the scan and ROI tables
	wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	wave/T scanListWave = root:Packages:twoP:examine:scanListWave
	Wave selWave = root:Packages:twoP:examine:selWave
	
	//Waves for the folder and item tables
	Wave/T folderTable = MBr_GetFolderListItems()
	
	If(!WaveExists(root:Packages:analysisTools:selFolderWave))
		Make/O/N=(DimSize(folderTable,0)) root:Packages:analysisTools:selFolderWave
	EndIf
	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
	
	NVAR selFolder= root:Packages:MBr:selFolder
	selFolder = 0
	
	Wave selWaveMBr = root:Packages:MBr:selWave
	Wave/T waveListTable = MBr_GetFolderItems()

	//Change between the scan list box and the folder list box
	strswitch(whichList)
		case "AT":
			//shrink the window
			GetWindow analysis_tools wsize
			MoveWindow/W=analysis_tools V_left,V_top,V_right-75,V_bottom
			//change the subwindow guides
			DefineGuide/W=analysis_tools listboxLeft={FR,-235},listboxBottom={FB,-10}
			//text box labels
			SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
			DrawText/W=analysis_tools#scanListPanel 75,25,"Scans"
			DrawText/W=analysis_tools#scanListPanel 180,25,"ROIs"
			
			//Hide some controls
			Button atBrowseBackButton win=analysis_tools#scanListPanel,disable=1
			SetVariable AT_cdf win=analysis_tools#scanListPanel,disable=1
			ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,listWave=folderTable,selWave=selFolderWave,proc=MBr_ListBoxProc,disable=1
			ListBox AT_ItemListBox win=analysis_tools#scanListPanel,listWave=waveListTable,selWave=selWaveMBr,mode=4,size={80+75,500-65},proc=MBr_ListBoxProc,disable = 1
			
			//Move the ROI list box back
			ListBox ROIListBox win=analysis_tools#scanListPanel,pos={150,30}
			
			//Show the ROI list box
			ListBox ROIListBox win=analysis_tools#scanListPanel,disable=0
			
			//Show some controls
			Button nudgeROI win=analysis_tools#scanListPanel,disable = 0
			Button atBrowseButton win=analysis_tools#scanListPanel,title="Browse"
			
			//Change some control assignments
			ListBox/Z WaveListBox win=analysis_tools#scanListPanel,selWave=selWave,listWave=scanListWave,proc=atListBoxProc,disable=0
			//ListBox/Z ROIListBox win=analysis_tools#scanListPanel,selWave=ROIListSelWave,listWave=ROIListWave,size={80,500-65},proc=atListBoxProc	

			break
		case "Browser":
			//expand the window
			GetWindow analysis_tools wsize
			MoveWindow/W=analysis_tools V_left,V_top,V_right+75,V_bottom
			//change the subwindow guides
			DefineGuide/W=analysis_tools listboxLeft={FR,-235-75},listboxBottom={FB,-10}
			
			//kill text box labels
			DrawAction/W=analysis_tools#scanListPanel delete	
			
			//Move the ROI list box over
			ListBox ROIListBox win=analysis_tools#scanListPanel,disable=1
			
			//Hide some controls
			ListBox/Z WaveListBox win=analysis_tools#scanListPanel,selWave=selWave,listWave=scanListWave,proc=atListBoxProc,disable=1
			Button nudgeROI win=analysis_tools#scanListPanel,disable = 1
			//ListBox ROIListBox win=analysis_tools#scanListPanel,disable=1
			
			
			//Show some controls
			Button atBrowseButton win=analysis_tools#scanListPanel,title="Scans"
			SetVariable AT_cdf win=analysis_tools#scanListPanel,disable=2
			Button atBrowseBackButton win=analysis_tools#scanListPanel,disable=0

			//Change some control assignments
			ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,listWave=folderTable,selWave=selFolderWave,proc=MBr_ListBoxProc,disable=0
			ListBox AT_ItemListBox win=analysis_tools#scanListPanel,listWave=waveListTable,selWave=selWaveMBr,mode=4,size={80+75,500-65},pos={150,30},proc=MBr_ListBoxProc,disable = 0
			//ListBox ROIListBox win=analysis_tools#scanListPanel,listWave=waveListTable,selWave=selWaveMBr,size={80+75,500-65},proc=MBr_ListBoxProc

			break
	endswitch

End

//Displays the help message for the given command
Function AT_DisplayHelpMessage(topic)
	String topic
	String message,message1,message2
	
	Variable left,top,width,height,result
	
	String osInfo = IgorInfo(2)
	
	If(cmpstr(osInfo,"Macintosh") == 0)
		String font = "Helvetica Neue Light"
	ElseIf(cmpstr(osInfo,"Windows") == 0)
		font = "Arial"
	EndIf
	
	strswitch(topic)
		case "None":
			GroupBox AT_HelpBox win=analysis_tools,disable=1
			DrawAction/L=ProgBack/W=analysis_tools delete
			break
		case "Line Profile":
			left = 7
			top = 269
			width = 326
			height = 203
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets a line profile from a 2D image, or a time series.\r"
			message += "Initiate the line profile by clicking once on the image.\r"
			message += "The mouse position is tracked until the user clicks again to disengage \rthe line profile.\r"
			message += "The path can be saved for repeated use, and can be selected in the \r'Paths' drop down menu.\r\r"
			message2 = "Use Scan List: applies the selected path to a scan from the scan list on \rthe right.\r"
			message2 += "Collapse: for time series images (3D), it finds the max value of the line \rprofile over the indicated Peak time window\r"
			message2 += "∆F/F: measures ∆F/F line profile instead of the raw fluorescence value. Set \rbaseline and peak ranges appropriately.\r"
			message2 += "Dist. Only: does the line profile, but also detects if the profile started and \rended in pre-"
			message2 += "made ROIs, and measures the cable distance between them."	
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+93,message2
			SetDrawLayer/W=analysis_tools UserBack
			break
		case "ROI From Map":
			left = 7
			top = 100
			width = 326
			height = 140
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets the ∆F/F or ∆G/R signal from a time-varying ∆F/F or ∆G/R image\r"
			message += "instead of from the raw fluorescence trace.\r\r"
			message += "To make a map, use 'Get Dendritic Mask' first, then run 'dFMap' with that\r mask.\r\r"
			message += "• Select Scan and ROI from lists.\r"
			message += "• Select channel for ∆F/F or ratio for ∆G/R\r"
			message += "• Smooth applies a temporal filter (Savitzky-Golay; 13 works well).\r"
			message += "• Select whether to average the resulting ROI traces from the scan set."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Get Dendritic Mask":
			left = 7
			top = 88
			width = 326
			height = 100
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Creates a mask image of the neuron.\r\r"
			message += "These masks can be used for creating ∆F/F maps.\r\r"
			message += "• Select Scan from list. Multiple scans can be selected at once.\r"
			message += "• Select channel to use for the mask.\r"
			message += "• Set the threshold. Higher values are more stringent (0.05 works well)."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "dF Map":
			left = 7
			top = 200
			width = 326
			height = 190
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Creates a ∆F/F or ∆G/R map from a time-varying scan.\r\r"
			message += "Outputs peak ∆F/F or peak ∆G/R map, time-varying ∆F/F or ∆G/R map,\r"
			message += "and a peak time map.\r\r"
			message += "• Select Scan from list.\r"
			message += "• Select channel.\r"
			message += "• Select the mask wave to use. Create a mask using 'Get Dendritic Mask'.\r"
			message += "• Set the time windows for baseline and peak selection. These are\r"
			message += "    important if 'Remove Laser Response' is selected.\r"
			message1 = "Make Histogram: makes histogram of fluorescence values.\r"
			message1 += "CleanUp Noise: removes extremely high intensity values.\r"
			message1 += "Remove Laser Response: flattens the laser response for better baselining."
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+145,message1
			break
		case "Display ROIs":
			left = 7
			top = 130
			width = 326
			height = 78
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Displays the selected ROI traces from the selected scans.\r\r"
			message += "Arrange the ROIs and Scans either horizontally or vertically in a grid.\r\r"
			message += "• Averages: check to display the average ROI traces (must already exist).\r"
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Data Sets":
			left = 7
			top = 360
			width = 326
			height = 128
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Define data sets by selecting folders in the scan list, and using the\r"
			message += "match/not match inputs.\r\r"
			message += "• Click the 'Browse' Button to access the rest of the data folders outside\r"
			message += "   of twoP_Scans.\r\r"
			message += "• Once you've matched the waves, set the data set name and click 'Add'.\r\r"
			message += "• Data sets can then be operated on using the 'Operation' function."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Get Peaks":
			left = 7
			top = 105
			width = 326
			height = 113
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets the peaks of the selected ROIs and Scans\r\r"
			message += "• Select the scans and ROIs\r\r"
			message += "• Select the channels. Choose 'ratio' if the ROIs are ∆G/R format\r\r"
			message += "• A different peak wave will be made for each ROI, with one data point\r"
			message += "   per scan."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Operation":
			left = 7
			top = 350
			width = 326
			height = 143
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Perform a custom operation on matched waves or data sets.\r"
			message += "• Select multiple folders and use the match/not match inputs to find the\r"
			message += "  waves of interest.\r"
			message += "• Alternatively, select a data set defined using the 'Data Sets' function.\r"
			message += " Operation will only use a data set if 'Use Data Set' is checked.\r"
			message += "• Choose a function from the drop down menu, or manually write it in.\r"
			message += "  Enter a custom suffix for naming the output wave, leaving it blank auto-\r"
			message1 = "  matically creates a name.\r"
			message1 += "• Operation can be a custom equation using the w0,w1,w2,etc. notation\r"
			message1 += "  to indicate the waves in the list."
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+94,message1
			break
		case "MultiROI":
			left = 7
			top = 220
			width = 326
			height = 165
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Extracts Z data from ROI regions in a time series image.\r\r"
			message += "•  Select folders from the Scan List and check the desired channels.\r"
			message += "•  Select the ROIs to extract from the ROI list\r\r"
			message += "•  Select time windows for baselining and peaks in seconds (not points)\r"
			message += "•  'Get Peaks' gets the peak ∆F/F or ∆G/R from the extracted data.\r"
			message += "•  Width (seconds) averages around the peak, or takes a single data\r"
			message += "   point if set to zero.\r\r"
			message1 = "•  'Angles' will reorder the peak data according to the angles. Preset\r"
			message1 += "  angles can be used and added to."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+135,message1
			break
		case "Vector Sum Map":
			left = 7
			top = 145
			width = 326
			height = 80
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Uses ∆F/F maps from the selected scans to build an angle maps via\r"
			message += "vector summation. Also outputs DSI and Resultant maps.\r\r"
			message += "• Not setting the 'Angles' input results in linear angles in 45° increments\r"
			message += "• 'Make Histogram' makes a histogram of the output angles in the map."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Rescale Scans":
			left = 7
			top = 80
			width = 326
			height = 50
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Rescales the selected scans according to the indicated scale factor\r\r"
			message += "• 60µm/V was recently measured for the Ca imaging rig."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Adjust Galvo Distortion":
			left = 7
			top = 285
			width = 326
			height = 210
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Adjusts scan image to compensate for shearing artifacts.\r\r"
			message += "• Select an open image (can be twoPScanGraph) and click 'Auto' to begin.\r"
			message += "• Select several marquee ROIs across the image that have good\r" 
			message += "   vertical dendrites. Add each ROI by clicking the '+' button.\r"
			message += "• Click 'Done' when you're finished with the ROI selection, and a max\r"
			message1 = "   projection and the adjusted image will pop up.\r\r"
			message1 += "• Select the max projection image in the drop down menu, and fine\r"
			message1 += "  tune the parameters manually to optimize the correction.\r\r"
			message1 += "When done, 'Save' the correction, which now will be in the 'Templates' list.\r"
			message1 += "'Use Scan List' or select an open image, then 'Apply Template' to actually\r"
			message1 += "perform the correction. The correction can be performed on multiple scans.\r"
			message2 = "APPLYING A TEMPLATE OVERWRITES THE ORIGINAL DATA!"
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+82,message1
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+190,message2
			break
		case "Register Image":
			left = 7
			top = 215
			width = 326
			height = 150
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Aligns images in the case of drift across trials.\r\r"
			message += "• Select a reference image that all others will be aligned to.\r"
			message += "• Select an image to be aligned (test image) or use the scan list.\r"
			message += "  Multiple images can be aligned at once.\r\r"
			message += "• Click 'Run' to get the alignment data, now available in the 'Templates' list\r"
			message += "• Apply template will correct the alignment between the reference and test\r"
			message += "   image. THIS WILL OVERWRITE THE ORIGINAL DATA.\r\r"
			message1 = "'Use Scan List' will automatically select the scan's corresponding template."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+130,message1
			break
	endswitch
End

Function ShowGroupBox(left,top,width,height)
	Variable left,top,width,height
	
	//For animated group box
	
	Variable pixelsPerStep = 10
	Variable numSteps = floor(height/pixelsPerStep)
	Variable remainder = mod(height,pixelsPerStep)
	Variable i,currentHeight,pause,startTime,elapsedTime
	
	pause = 1
	
	//show/hide the group box
	ControlInfo/W=analysis_tools AT_HelpBox
	If(V_disable == 1)
		For(i=0;i<numSteps;i+=1)
			currentHeight = i*pixelsPerStep
			GroupBox AT_HelpBox win=analysis_tools,pos={left,top},size={width,currentHeight},disable=0
			
			startTime = ticks
			Do
				//empty loop
			While(ticks - startTime	 < pause)
			ControlUpdate/W=analysis_tools AT_HelpBox
		EndFor
			
		
		GroupBox AT_HelpBox win=analysis_tools,pos={left,top},size={width,height},disable=0
	
		
		return 1
	Else
		GroupBox AT_HelpBox win=analysis_tools,disable=1
		DrawAction/L=ProgBack/W=analysis_tools delete
		return -1
	EndIf
End

//Runs the selected commmand
Function RunCmd(cmdStr)
	String cmdStr
	Execute cmdStr
End

//Called by external procedures parameters 
Function atExtParamPopProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo/W=analysis_tools extFuncPopUp
			UpdateExtFuncValues(S_Value)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Called by the pop up menus
Function atPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	SVAR prevCmd = root:Packages:analysisTools:prevCmd
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	switch( pa.eventCode )
		case 2: // mouse up
		
			strswitch(pa.ctrlName)
				case "AT_CommandPop":
					Variable popNum = pa.popNum
					String popStr = pa.popStr
			
					If(cmpstr(popStr[0],"-") == 0)
						return 0
					EndIf
			
					prevCmd = currentCmd
					currentCmd = popStr
					ChangeControls(currentCmd,prevCmd)
					
					//Refresh external function page when it opens
					If(cmpstr(pa.popStr,"External Function") == 0)
						Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
						SVAR DSNames = root:Packages:analysisTools:DSNames
						DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
					
						KillExtParams()
						ControlInfo/W=analysis_tools extFuncPopUp
						ResolveFunctionParameters("AT_" + S_Value)
						recallExtFuncValues(S_Value)
						//Toggle the channel pop up menu
						ControlInfo/W=analysis_tools extFuncDS
						If(cmpstr(S_Value,"--Scan List--") == 0)
							//Scan list selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=0
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=0
							EndIf
							ListBox extFuncDSListBox win=analysis_tools,disable=1
							DrawAction/W=analysis_tools delete
						ElseIf(cmpstr(S_Value,"--None--") == 0 || cmpstr(S_Value,"--Item List--") == 0)
							//Item List selection or no wave selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							EndIf
							ListBox extFuncDSListBox win=analysis_tools,disable=1
							DrawAction/W=analysis_tools delete
						Else
							//Data set selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							EndIf
							
							SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
							DrawText/W=analysis_tools 175,100,"Waves:"
							OpenExtFuncWaveListBox(S_Value)
						EndIf
					ElseIf(!cmpstr(pa.popStr,"Average") || !cmpstr(pa.popStr,"Error") || !cmpstr(pa.popStr,"Kill Waves") )
						Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
						SVAR DSNames = root:Packages:analysisTools:DSNames
						DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")		
					EndIf
					
					break
				case "presetAngleListPop":
					popNum = pa.popNum
					popStr = pa.popStr
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					SetVariable angleList win=analysis_tools,value=_STR:presetAngleWave[popNum-1][1]
					SetVariable scanOrderROIdisplay win=analysis_tools,value=_STR:presetAngleWave[popNum-1][1]
					ControlUpdate/W=analysis_tools angleList
					ControlUpdate/W=analysis_tools scanOrderROIdisplay
					break
				case "operationOptionsPop":
					popStr = pa.popStr
					SetVariable operation win=analysis_tools,value=_STR:popStr	
					break
				case "extFuncPopUp":
					KillExtParams()
					ResolveFunctionParameters("AT_" + pa.popStr)
					recallExtFuncValues(pa.popStr)
					break
				case "extFuncDS":
					SetExtFuncMenus(pa.popStr)
					SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
					wsDims = GetWaveSetDims(pa.popStr)
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetExtFuncMenus(selection)
	String selection
	ControlInfo/W=analysis_tools AT_CommandPop
	String currentCmd = S_Value
	
	If(cmpstr(selection,"--Scan List--") == 0)
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=0
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=0
		EndIf
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	ElseIf(cmpstr(selection,"--None--") == 0 || cmpstr(selection,"--Item List--") == 0)
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
		EndIf
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	Else
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
			DrawAction/W=analysis_tools delete
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs,fstyle=2
			DrawText/W=analysis_tools 230,117,"Waves:"
		EndIf
		OpenExtFuncWaveListBox(selection)
	EndIf
End

//When a Data Set is selected in external functions, it opens a list box that
//shows the wave names that have been located. 
Function OpenExtFuncWaveListBox(dsName)
	String dsName
	Wave/T dsListWave = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	
	If(!WaveExists(dsListWave))
		PopUpMenu extFuncDS win=analysis_tools,mode=1
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
		return 0
	EndIf
	
	Duplicate/O dsListWave,root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
	Wave/T dsListWave_NamesOnly = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
	Variable i
	
	For(i=0;i<DimSize(dsListWave_NamesOnly,0);i+=1)
		dsListWave_NamesOnly[i] = ParseFilePath(0,dsListWave_NamesOnly[i],":",1,0)
	EndFor
	Make/O/N=(DimSize(dsListWave_NamesOnly,0)) root:Packages:analysisTools:DataSets:dsSelWave
	Wave dsSelWave = root:Packages:analysisTools:DataSets:dsSelWave
	ListBox extFuncDSListBox win=analysis_tools,listWave=dsListWave_NamesOnly,mode=4,disable=0,listwave=dsListWave_NamesOnly,selwave=dsSelWave,proc=atListBoxProc
End


////// Color Picker for NMultiROI//////
Function ROIColorPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			controlinfo/w=analysis_tools ROIColorPop
			variable/G Gred = V_red
			variable/G GBlue = V_blue
			variable/G Ggreen = V_green
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Called by the check boxes
Function atCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			strswitch(cba.ctrlName)
				case "SmoothBox":
				//// Temporal filter check box/////////////
					NVAR TempFilter = root:Packages:analysisTools:TempFilter
			
					if(checked)
						TempFilter = 1
						setvariable SmoothFilterVar disable = 0
					else
						TempFilter = 0
						setvariable SmoothFilterVar disable = 2
					endif
					
					break
				case "SpaceFilterBox":
				//// Spatial filter check box/////////////
					NVAR SpaceFilter = root:Packages:analysisTools:SpaceFilter
			
					if(checked)
						SpaceFilter = 1
						setvariable SpaceFilterVar disable = 0
					else
						SpaceFilter = 0
						setvariable SpaceFilterVar disable = 2
					endif
					
					break
				case "DarkSubtBox":
				//// Dark subtraction/////////////
					NVAR darkValue = root:Packages:analysisTools:GdarkValue
			
					if(checked)
						setvariable DarkValueVar disable = 0
						DarkROI(darkValue)	
					else	
						darkValue = 0
						setvariable DarkValueVar disable = 2
					endif
					
					break
				case "NotSeqBox":
					string curFolder = getdatafolder(1)
					setdatafolder "root:"
					variable/G NotInSequence = checked
					setdatafolder curFolder 
					
					break
			endswitch
			
			
		case -1: // control being killed
			break
	endswitch
	return 0
End

//Called by the tab controller
Function atTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca
	SVAR tabList = root:Packages:analysisTools:tabList
	SVAR currentTab = root:Packages:analysisTools:currentTab
	SVAR prevTab =  root:Packages:analysisTools:prevTab
	SVAR MBr_WindowSettings = root:Packages:analysisTools:MBr_WindowSettings
	SVAR whichList = root:Packages:analysisTools:whichList
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen

	Variable i
	
	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			//prevTab = currentTab
			//currentTab = StringFromList(tab,tabList,";")
			//hide or show controls
			//ChangeControls(currentCmd,prevCmd)
			//ChangeTabs(currentTab,prevTab)
			currentTab = StringFromList(tab,tabList,";")
			
			strswitch(currentTab)
				case "Analysis":
					break //does nothing for now
					
					
					//blocks the Browser functionality for Windows bc it currently doesn't work that well
					String platform = IgorInfo(2)
					If(cmpstr(platform,"Windows") == 0)
						break
					EndIf
					
					DoWindow MBr
					If(V_flag)
						GetWindow MBr wsize
						MBr_WindowSettings = "Width:" + num2str(V_right - V_left) + ";Height:" + num2str(V_bottom - V_top)
						SetWindow MBr hide=1
						
						If(cmpstr(whichList,"Browser") == 0)
							MoveWindow/W=analysis_tools V_left,V_top,V_left+575+75,V_top+510
						Else
							MoveWindow/W=analysis_tools V_left,V_top,V_left+575,V_top+510
						EndIf
						
						SetWindow analysis_tools hide=0
						TabControl atTab win=analysis_tools,value=0
					EndIf
											
					If(viewerOpen == 1)
						openViewer()
					EndIf
					
					break
				case "Browser":
					platform = IgorInfo(2)
					
					//blocks the Browser functionality for Windows bc it currently doesn't work that well
					If(cmpstr(platform,"Windows") == 0)
						break
					Else
						break	//removes browser entirely for now.
					EndIf
					
					GetWindow analysis_tools wsize
					SetWindow analysis_tools hide=1
					
					DoWindow MBr
					If(!V_flag)
						InitializeMBrfromFUNC(V_left,V_top)
						//Make additional tabs on MBr
						TabControl atTabMBr win=MBr,pos={0,0},proc=atTabProc
						For(i=0;i<ItemsInList(tabList,";");i+=1)
							//575-235 = width -235
							TabControl atTabMBr win=MBr,tabLabel(i) = StringFromList(i,tabList,";"),size={575-235,20}
						EndFor
					Else
						Variable width = str2num(StringByKey("Width",MBr_WindowSettings,":",";"))
						Variable height = str2num(StringByKey("Height",MBr_WindowSettings,":",";"))
						
						//MoveWindow/W=MBr V_left,V_top,V_left+900,V_top+450
						MoveWindow/W=MBr V_left,V_top,V_left+width,V_top+height
						SetWindow MBr hide=0
						TabControl atTabMBr win=MBr,value=1

					EndIf
					
					break
				case "Data Sets":
					GetWindow MBr wsize
					MBr_WindowSettings = "Width:" + num2str(V_right - V_left) + ";Height:" + num2str(V_bottom - V_top)
					SetWindow MBr hide=1
					MoveWindow/W=analysis_tools V_left,V_top,V_left+575,V_top+500
					SetWindow analysis_tools hide=0
					TabControl atTab win=analysis_tools,value=0
					break
			endswitch
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ChangeControls(currentCmd,prevCmd)
	String currentCmd,prevCmd
	Variable tab
	Wave controlHeight = root:Packages:analysisTools:controlHeight
	Variable i
	String cmdStr
	SVAR runCmdStr =  root:Packages:analysisTools:runCmdStr
	SVAR cmdList = root:Packages:analysisTools:cmdList
	
	SVAR saveCurrentCmd = root:Packages:analysisTools:currentCmd
	//Erase the help message box
	AT_DisplayHelpMessage("None")
	
//If(cmpstr(currentCmd[0],"-") == 0)
//		currentCmd = prevCmd
//		return 0
//	EndIf
	
	//Delete any draw layer items
	SetDrawLayer/K/W=analysis_tools UserBack
	
	strswitch(prevCmd)
		case "MultiROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
			break
		case "dF Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
			break
		case "Average":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
			break
		case "Error":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_error
			break
		case "Space-Time dF":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
			break
		case "qkSpot":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_qkSpot
			break
		case "ROI Tuning Curve":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
			break
		case "Display ROIs":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_displayROIs
			break
		case "Adjust Galvo Distortion":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
			break
		case "Get Dendritic Mask":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getDendriticMask
			break
		case "Mask Scan Data":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maskScanData
			break
		case "Operation":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_operation
			break
		case "Get Peaks":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeaks
			break
		case "Line Profile":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_lineProfile
			break
		case "ROI Segmenter":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiSegmenter
			break
		case "Register Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_registerImage
			break
		case "ROI From Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiFromMap
			break
		case "Vector Sum Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_vectorSumMap
			break
		case "Rescale Scans":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_rescaleScans
			break
		case "Data Sets":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dataSets
			break
		case "Get Peak Times":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeakTimes
			break
		case "ROI Grid":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiGrid
			break
		case "Load PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_loadPClamp
			break
		case "Kill Waves":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killwaves
			break
		case "External Function":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_extFunc
			ControlInfo/W=analysis_tools extFuncPopUp
			ResolveFunctionParameters("AT_" + S_Value)
			break	
	endswitch
	
	If(strlen(prevCmd))
		//Hide controls from previous tab)
		For(i=0;i<ItemsInList(ctrlList,";");i+=1)
			ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
			cmdStr = TrimString(StringFromList(0,S_Recreation,","))
			cmdStr += " win=analysis_tools,disable = 1"
			Execute cmdStr
		EndFor	
	EndIf	
	
	strswitch(currentCmd)
		case "MultiROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
			runCmdStr = "GetROI()"
			break
		case "dF Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
			//runCmdStr = "dFMaps()"
			runCmdStr = "dfMapSimple()"
			break
		case "Average":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
			runCmdStr = "AverageWaves()"
			break
		case "Error":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_error
			runCmdStr = "ErrorWaves()"
			break
		case "Space-Time dF":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
			runCmdStr = "SpaceTimeDF()"
			break
		case "qkSpot":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_qkSpot
			runCmdStr = "qkSpot()"
			break
		case "ROI Tuning Curve":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
			runCmdStr = "roiTuningCurve()"
			break
		case "Display ROIs":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_displayROIs
			runCmdStr = "displayROIs()"
			break
		case "Adjust Galvo Distortion":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
			runCmdStr = ""
			break
		case "Get Dendritic Mask":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getDendriticMask
			runCmdStr = "getDendriticMask()"
			break
		case "Mask Scan Data":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maskScanData
			runCmdStr = "maskScanData()"
			break
		case "Operation":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_operation
			runCmdStr = "doOperation()"
			break
		case "Get Peaks":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeaks
			runCmdStr = "getPeaks()"
			break
		case "Line Profile":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_lineProfile
			runCmdStr = "getLineProfile()"
			break
		case "ROI Segmenter":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiSegmenter
			runCmdStr = "OpenMask()"
			break
		case "Register Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_registerImage
			runCmdStr = "GetRegistrationParameters()"
			break
		case "ROI From Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiFromMap
			runCmdStr = "ROI_From_MapData()"
			break
		case "Vector Sum Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_vectorSumMap
			runCmdStr = "VectorSumMap()"
			break
		case "Rescale Scans":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_rescaleScans
			runCmdStr = "rescale2P_Scans()"
			break
		case "Data Sets":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dataSets
			runCmdStr = "print \"Define your Data Set!\""
			break
		case "Get Peak Times":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeakTimes
			runCmdStr = "GetPkTimes()"
			break
		case "ROI Grid":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiGrid
			runCmdStr = "gridROI()"
			break
		case "Load PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_loadPClamp
			runCmdStr = ""
			break
		case "Kill Waves":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killwaves
			runCmdStr = "AT_KillWaves()"
			break
		case "External Function":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_extFunc
			runCmdStr = "()"
			break
		default:
			//Loads a package if its not a function
			LoadPackage(currentCmd)
			return 0
	endswitch
	
	S_Recreation = ""
	
	If(cmpstr(currentCmd,"Adjust Galvo Distortion") == 0)
		AT_InitializeScanRegister()
		//Clear any text drawing layers from qkSpot build
		DrawAction/W=analysis_tools delete
	Else
		//Clear any text drawing layers from qkSpot build
		DrawAction/W=analysis_tools delete
	EndIf
		
	//Show controls from current tab
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		cmdStr += " win=analysis_tools,disable = 0"
		
		If(StringMatch(cmdStr,"*ch1Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) == 0)
			CheckBox ch1Check,win=analysis_tools,pos={34,264}
		ElseIf(StringMatch(cmdStr,"*ch2Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) == 0)
			CheckBox ch2Check,win=analysis_tools,pos={74,264},title="Ch2"
		ElseIf(StringMatch(cmdStr,"*ch1Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) != 0)
			CheckBox ch1Check,win=analysis_tools,pos={10,190},title="Ch1"
		ElseIf(StringMatch(cmdStr,"*ch2Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) != 0)
			CheckBox ch2Check,win=analysis_tools,pos={50,190},title="Ch2"
		EndIf
		
		Execute cmdStr
	EndFor
	
	//Change some of the control positions for certain functions
	strswitch(currentCmd)
		case "Adjust Galvo Distortion":
			CheckBox ch1Check,win=analysis_tools,pos={34,264}
			CheckBox ch2Check,win=analysis_tools,pos={74,264}
			CheckBox ratioCheck,win=analysis_tools,pos={104,264}
			AT_InitializeScanRegister()
			break
		case "Get Dendritic Mask":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			break
		case "Mask Scan Data":
			PopUpMenu maskListPopUp win=analysis_tools,value=GetMaskWaveList()
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			break
		case "df Map":
			PopUpMenu maskListPopUp win=analysis_tools,value=GetMaskWaveList()
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			SetVariable peakStVar win=analysis_tools,pos={230,103}
			SetVariable peakEndVar win=analysis_tools,pos={235,123}
			SetVariable bslnStVar win=analysis_tools,pos={232,63}
			SetVariable bslnEndVar win=analysis_tools,pos={237,83}
			CheckBox SmoothBox,win=analysis_tools,pos={225,143}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={240,143}
			CheckBox histogramCheck win=analysis_tools,pos={10,110}
			CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,151}
			CheckBox doDarkSubtract win=analysis_tools,pos={10,171}
			break
		case "Get Peaks":
			CheckBox ch1Check,win=analysis_tools,pos={26,61}
			CheckBox ch2Check,win=analysis_tools,pos={61,61}
			CheckBox ratioCheck,win=analysis_tools,pos={26,82}
			PopUpMenu extFuncDS win=analysis_tools,pos={21,110}
			ListBox extFuncDSListBox win=analysis_tools,pos={21,136}
			ControlInfo/W=analysis_tools extFuncDS
			If(cmpstr(S_Value,"--Scan List--") != 0)
				PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},disable=1
			Else
				PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},disable=0
			EndIf
			break
		case "Line Profile":
			CheckBox ch1Check,win=analysis_tools,pos={202,142}
			CheckBox ch2Check,win=analysis_tools,pos={202,162}
			SetVariable bslnStVar win=analysis_tools,pos={248,165}
			SetVariable bslnEndVar win=analysis_tools,pos={248,185}
			SetVariable peakStVar win=analysis_tools,pos={248,206}
			SetVariable peakEndVar win=analysis_tools,pos={248,226}
			CheckBox SmoothBox,win=analysis_tools,pos={115,184}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={135,185}
			break
		case "Register Image":
			CheckBox useScanListCheck win=analysis_tools,pos={278,109},title="Scan\rList"
			CheckBox ch1Check,win=analysis_tools,pos={10,162}
			CheckBox ch2Check,win=analysis_tools,pos={50,162}
			break
		case "ROI From Map":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			CheckBox SmoothBox,win=analysis_tools,pos={142,62}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={162,62}
			break
		case "Vector Sum Map":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			SetVariable angleList,win=analysis_tools,pos={10,81}
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,101}
			Button addPresetAngle,win=analysis_tools,pos={130,101}
			Button deletePresetAngle,win=analysis_tools,pos={155,101}
			CheckBox histogramCheck win=analysis_tools,pos={10,125}
			break
		case "Rescale Scans":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			break
		case "Display ROIs":
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,124}
			Button addPresetAngle,win=analysis_tools,pos={131,124}
			Button deletePresetAngle,win=analysis_tools,pos={156,124}
			break
		case "External Function":			
			ControlInfo/W=analysisTools extFuncPopUp
			ResolveFunctionParameters("AT_" + S_Value)
			PopUpMenu extFuncDS win=analysis_tools,pos={21,90}
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121}
			break
		case "Data Sets":
			SetDrawLayer/W=analysis_tools UserBack
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
			DrawText/W=analysis_tools 95,117,"Waves:"
			DrawText/W=analysis_tools 255,117,"Data Sets:"
			SetDrawLayer/W=analysis_tools ProgBack
			break
		case "Operation":
			SetDrawLayer/W=analysis_tools UserBack
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
			DrawText/W=analysis_tools 95,117,"Waves:"
			DrawText/W=analysis_tools 255,117,"Data Sets:"
			SetDrawLayer/W=analysis_tools ProgBack
			break
		case "Average":
		case "Error":
		case "Kill Waves":
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={21,90},disable=1
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121},disable=1
			ControlInfo/W=analysis_tools extFuncDS
			SetExtFuncMenus(S_Value)
			break
		default:
				//return controls to default positions

			CheckBox ch1Check,win=analysis_tools,pos={10,127}
			CheckBox ch2Check,win=analysis_tools,pos={50,127}
			CheckBox ratioCheck,win=analysis_tools,pos={90,127}
			SetVariable bslnStVar win=analysis_tools,pos={10,65}
			SetVariable bslnEndVar win=analysis_tools,pos={15,85}
			SetVariable peakStVar win=analysis_tools,pos={120,65}
			SetVariable peakEndVar win=analysis_tools,pos={125,85}
			CheckBox SmoothBox,win=analysis_tools,pos={10,107}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={30,107}
			CheckBox useScanListCheck win=analysis_tools,pos={115,142},title="Use Scan List"
			SetVariable angleList,win=analysis_tools,pos={10,186}
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,205}
			Button addPresetAngle,win=analysis_tools,pos={131,205}
			Button deletePresetAngle,win=analysis_tools,pos={156,205}
			CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,231}
			CheckBox doDarkSubtract win=analysis_tools,pos={10,250}
			PopUpMenu extFuncDS win=analysis_tools,pos={21,90}
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121}
			break
	endswitch

End

//Loads a function package
Function LoadPackage(thePackage)
	String thePackage
	SVAR cmdList = root:Packages:analysisTools:cmdList
	SVAR saveCurrentCmd = root:Packages:analysisTools:currentCmd
	Variable numPackages,i,index,load
	Wave/T packageTable = root:Packages:analysisTools:packageTable
	
	numPackages = DimSize(packageTable,0)
	//Finds which package
	For(i=0;i<numPackages;i+=1)
		If(cmpstr(packageTable[i][0],thePackage) == 0)
			index = i
			load = 1
			break
		ElseIf(cmpstr("Unload " + packageTable[i][0],thePackage) == 0)
			index = i
			load = 0
			break
		EndIf
	EndFor
	
	If(load)
		cmdList = ReplaceString(thePackage,cmdList,"Unload " + thePackage)
		cmdList += ";" + packageTable[index][1]
		String firstControl = StringFromList(1,packageTable[index][1],";")
		
		ChangeControls(firstControl,"")
		PopUpMenu AT_CommandPop win=analysis_tools,mode=WhichListItem(firstControl,cmdList)+1
		saveCurrentCmd = firstControl
	Else
		String unload = ReplaceString("Unload ",thePackage,"")
		cmdList = ReplaceString(thePackage,cmdList,unload)
		cmdList = ReplaceString(packageTable[index][1],cmdList,"")
		ChangeControls("Data Sets","")
		PopUpMenu AT_CommandPop win=analysis_tools,mode=WhichListItem("Data Sets",cmdList)+1
		saveCurrentCmd = "Data Sets"
	EndIf
End

Function ChangeTabs(currentTab,prevTab)
	String currentTab,prevTab
	String cmdStr
	Variable i
	SVAR runCmdStr =  root:Packages:analysisTools:runCmdStr
	
	strswitch(prevTab)
		case "Analysis":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_analysisTab
			break
		//case "Mapping":
		//	SVAR ctrlList = root:Packages:analysisTools:ctrlList_mappingTab
		//	break
	endswitch
	
	//Hide controls from previous tab)
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		cmdStr += ",disable = 1"
		Execute cmdStr
	EndFor
	
	strswitch(currentTab)
		case "Analysis":
			ControlInfo/W=analysis_tools AT_CommandPop
			strswitch(S_Value)
				case "MultiROI":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
					runCmdStr = "NMultiROI()"
					break
				case "dF Map":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
					runCmdStr = "dFMaps()"
					break
				case "Average":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
					runCmdStr = "averagewaves()"
					break
				case "Space-Time dF":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
					runCmdStr = "SpaceTimeDF()"
					break
				case "ROI Tuning Curve":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
					runCmdStr = "roiTuningCurve()"
					break
			endswitch
			break
		//case "Mapping":
		//	SVAR ctrlList = root:Packages:analysisTools:ctrlList_mappingTab
		//	runCmdStr = "qkSpot()"
		//	break
	endswitch
	
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		cmdStr += ",disable = 0"
		Execute cmdStr
	EndFor
End

//Animates resizing of group box in the control panel
Function AT_animateControlDrop(ctrlName,ctrlWin,controlHeight,tab,duration)
	String ctrlName,ctrlWin
	Wave controlHeight
	Variable tab,duration
	Variable i,pauseTime,currentSize,steps,startTime,currentTime,elapsedTime
	
	ControlInfo/W=$ctrlWin $ctrlName
	steps = ceil(0.2*(controlHeight[tab] - V_height))	//for step size of 4
	pauseTime = abs(duration/steps)
	currentSize = V_height
	
	For(i=0;i<abs(steps);i+=1)
		If(steps > 0)
			currentSize +=5
		Else
			currentSize -=5
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


////Smooth checkbox//////////////
//Currently not in use///
Function SmoothCheckBoxProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NVAR smthMode = root:smthMode
			if(checked)
				smthMode = 1
			else
				smthMode = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function atListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	Variable i,scanNum
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			strswitch(lba.ctrlName)
				case "WaveListBox":
					//populate scanListStr
					scanListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						scanListStr += listWave[i] + ";"
						scanNum = i	
						Endif
					EndFor
					
					//if no scans were selected
					If(cmpstr(scanListStr,";") == 0)
						break
					EndIf
					
					//Adjust current scan on 2PLSM GUI
					SVAR curScan = root:Packages:twoP:examine:CurScan
					curScan = StringFromList(0,scanListStr,";")
					
					// Get some variables from scan note
					if (cmpStr (curScan, "LiveWave") == 0)
						SVAR ScanNote  = root:packages:twoP:Acquire:LiveModeScanStr
					else
						SVAR ScanNote = $"root:twoP_Scans:" + curScan + ":" + curScan+  "_info"
					endif
					variable mode = NumberByKey("mode",ScanNote, ":", "\r")
					variable doephys = NumberByKey("ephys",ScanNote, ":", "\r")
					
					//Append the new scan to scanGraph
					if (mode == kePhysOnly)
						DoWindow/K twoPscanGraph
						NQ_NewTracesGraph (curScan)
					else
						NQ_NewScanGraph (curScan)
						variable nTraces = 0//doEphys + GUIPCountObjs ("root:twoP_Scans:" + CurScan, 1, "*avg*", 0) + GUIPCountObjs ("root:twoP_Scans:" + CurScan, 1, "*ratio*", 0)
						if (nTraces == 0) 
							DoWindow/K twoP_TracesGraph
						else
							NQ_NewTracesGraph (curScan)
						endif
					endif
					// adjust the movie controls and visibility and change display
					NQ_Adjust_Examine_Controls (curScan)
					
					NVAR curScanNum = root:Packages:twoP:examine:curScanNum
					curScanNum = scanNum
					
					break
				case "ROIListBox":
				//populate ROIListStr
					ROIListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						ROIListStr += listWave[i] + ";"
						Endif
					EndFor
					
				//Jamie's code for adding an ROI to the scanGraph if it exists
					// If shift key was held down, then we are just plotting
					//variable justPlot = ((ba.EventMod & 2) == 2)
					SVAR curScan = root:packages:twoP:examine:curScan
					if (cmpStr (curScan, "LiveWave") == 0)
						SVAR scanStr = root:packages:twoP:Acquire:LiveModeScanStr
					else
						SVAR scanStr = $"root:twoP_Scans:" + curScan + ":" + curScan + "_info"
					endif
					// window to plot on
					controlinfo/w=twoP_Controls ROIonWindowPopup
					string onWindow = S_Value
					doWindow/F $S_Value
					if (!(V_Flag))
						print "The selected graph no longer exists."
						return 1
					endif
					// check subwin for twoPScanGraph
					if (cmpStr (onWindow, "twoPScanGraph") ==0)
						NVAR ROIChan = root:packages:twoP:examine:roiChan
						switch (ROIChan)
							case 1:
								onWindow = "twoPScanGraph#Gch1"
								break
							case 2:
								onWindow = "twoPScanGraph#Gch2"
								break
							case 3:
								onWindow = "twoPScanGraph#Gmrg"
								break
						endSwitch
						// if selected channel is not displayed, just use first subwindow
						if (WhichListItem(stringfromlist (1, onWindow, "#"), childWindowList (stringfromlist (0, onWindow, "#")), ";") == -1) // subwin not present
							onWindow = "twoPScanGraph#" + stringFromList  (0, childWindowList (stringfromlist (0, onWindow, "#")))
						endif
					endif
					// get a list of traces already on the graph, so they are not added 2x
					string tracelist = tracenamelist (onWIndow, ";", 1)
					// find selected ROIs, append them (if not already appended) and set the "drag" option
					// also copy list of drag traces into a global string
					WAVE/T ROIListWave = root:Packages:twoP:examine:ROIListWave
					WAVE ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
					variable ii, numroi = numpnts (ROIListWave), red, green, blue
					string roiStr
					string/G root:packages:twoP:examine:ROInudgeList =""
					SVAR ROInudgeList = root:packages:twoP:examine:ROInudgeList 
					for (ii =0; ii < numRoi; ii += 1)
						if (ROIListSelWave [ii] == 0)
							continue
						endif
						roiStr = ROIListWave [ii]
						ROInudgeList += roiStr + ";"
						// display ROI if it is not already displayed
						if (WhichListItem(roiStr + "_y", tracelist, ";") == -1)
							WAVE roiXWave = $ "Root:twoP_ROIs:" + roiStr + "_x"
							WAVE roiYWave = $ "Root:twoP_ROIs:" + roiStr + "_y"
							if (!((WaveExists (roiXWave)) && (WaveExists (roiYWave))))
								continue
							endif
							red = numberbykey ("Red", note (roiXWave))
							green = numberbykey ("Green", note (roiXWave))
							blue = numberbykey ("Blue", note (roiXWave))
							appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
						endif
	
						// set quickDrag for selected rois
					//	if (!(justPlot))
					//		modifyGraph/W=$onWindow quickDrag ($roiStr + "_y")=1
					//		String/G root:packages:twoP:examine:NudgeOnWindow = onWindow
					//	endif
					endfor
				// if not just plotting, set nudge button to new title and new procedure
				//	if (!(justPlot))
				//		Button ROINudgeButton win=twoP_Controls, title = "Done", proc = NQ_RoiNudgeDoneButtonProc, fColor=(65535,0,0)
				//	endif
					break
					
					case "dataSetListBox":
						//Displays the data set in the Viewer if double clicked
						If(!viewerOpen)
							openViewer()
						EndIf
							
						Variable selection = lba.row
						Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_"+listWave[selection])
						Variable numWaves = DimSize(theDataSet,0)
						String selWaveList = ""
						
						traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
						If(strlen(traceList))
							KillWindow/Z analysis_tools#atViewerGraph
							Display/HOST=analysis_tools/FG=(FL,VT,FR,VB)/N=atViewerGraph
						EndIf
						
						For(i=0;i<numWaves;i+=1)
							Wave/Z theWave = $theDataSet[i]
							Variable type = WaveType(theWave,1)
							If(type == 1)
								AppendToGraph/W=analysis_tools#atViewerGraph theWave
							EndIf
						EndFor
					
					break
			endswitch
			break
		case 4: // cell selection
			strswitch(lba.ctrlName)
				case "dataSetListBox":
					Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetNames
					Wave selWave = root:Packages:analysisTools:DataSets:dataSetSelWave
					Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
					Wave matchListselWave = root:Packages:analysisTools:AT_selWave
					
					selection = lba.row
					
					//If selection is past the item list
					If(selection > DimSize(listWave,0) - 1)
						break
					EndIF
					
					Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + listWave[selection])
					
					If(!WaveExists(dataSetWave))
						break
					EndIf		
					
					Redimension/N=(DimSize(dataSetWave,0)) waveListTable,matchListselWave
					For(i=0;i<DimSize(DataSetWave,0);i+=1)
						waveListTable[i] = ParseFilePath(0,dataSetWave[i],":",1,0)
					EndFor
					
					checkMissingWaves(listWave[selection])
					updateWSDimText()
					updateWSFilters()

					break
				case "extFuncDSListBox":
						Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
						Wave selWave = root:Packages:analysisTools:DataSets:dsSelWave
						selWaveList = ""
						For(i=0;i<DimSize(listWave,0);i+=1)
							If(selWave[i] == 1)
								selWaveList += listWave[i] + ";"
							EndIf
						EndFor
						
						ControlInfo/W=analysis_tools extFuncDS
						Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + S_Value)
						
						AppendDSWaveToViewer(selWave,selWaveList,theDataSet)
				endswitch
		case 5: // cell selection plus shift key
			strswitch(lba.ctrlName)
				case "WaveListBox":
					//populate scanListStr
					scanListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						scanListStr += listWave[i] + ";"
						Endif
					EndFor
					break
				case "ROIListBox":
					//populate ROIListStr
					ROIListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						ROIListStr += listWave[i] + ";"
						Endif
					EndFor
					break
				case "extFuncDSListBox":
					Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
					Wave selWave = root:Packages:analysisTools:DataSets:dsSelWave
					
					ControlInfo/W=analysis_tools extFuncDS
					String dsName = S_Value
					Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + dsName)				
					Variable fullPathList = 0
					
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
							
							//If we hit a waveset label
							If(stringmatch(listWave[i],"*WSN*"))
								Variable index = tableMatch(listWave[i],theDataSet)
								selWaveList = ReplaceString(listWave[i] + ";",selWaveList,"")	//remove the wsLabel from the list
								selWaveList += getWaveSet(dsName,wsLabel=listWave[i])	//add in the entire waveset to the list
								fullPathList = 1
							EndIf
						EndIf
					EndFor	
			
					AppendDSWaveToViewer(selWave,selWaveList,theDataSet,fullPathList=fullPathList)
					break
				case "matchListBox":
					Wave/T listWave = root:Packages:analysisTools:AT_waveListTable
					Wave selWave = root:Packages:analysisTools:AT_selWave
					
					dsName = whichDataSet()
					Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
					fullPathList = 0
					
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						
							//If we hit a waveset label
							If(stringmatch(listWave[i],"*WSN*"))
								index = tableMatch(listWave[i],theDataSet)
								selWaveList = ReplaceString(listWave[i] + ";",selWaveList,"")	//remove the wsLabel from the list
								selWaveList += getWaveSet(dsName,wsLabel=listWave[i])	//add in the entire waveset to the list
								fullPathList = 1
							EndIf
						EndIf
					EndFor			
					
					AppendDSWaveToViewer(selWave,selWaveList,theDataSet,fullPathList=fullPathList)
					break
			endswitch
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

Function checkMissingWaves(dsName)
	String dsName
	Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	Wave/T ogds = $("root:Packages:analysisTools:DataSets:ogDS_" + dsName)
	Variable i
	
	For(i=0;i<DimSize(ds,0);i+=1)
		If(!stringmatch(ds[i],"*WSN*"))	//skip the wave set labels
			If(!WaveExists($ds[i]))
				DeletePoints i,1,ds
				i-=1
			EndIf
		EndIf
	EndFor
	
	For(i=0;i<DimSize(ogds,0);i+=1)
		If(!stringmatch(ogds[i],"*WSN*")	)//skip the wave set labels
			If(!WaveExists($ogds[i]))
				DeletePoints i,1,ogds
				i-=1
			EndIf
		EndIf
	EndFor

End


//Reads the filter settings for the selected data set, puts it into the variable boxes
Function updateWSFilters()
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	String groupList = "prefixGroup;groupGroup;seriesGroup;sweepGroup;traceGroup"
	Variable i,size
	String filters,dsName
	
	ControlInfo/W=analysis_tools dataSetListBox
	dsName = dataSetNames[V_Value]
	
	size = DimSize(dsFilters,0)
	For(i=0;i<size;i+=1)
		If(!cmpstr(dsFilters[i][0],dsName))
			filters = dsFilters[i][1]
			break
		EndIf
	EndFor
	
	//wave grouping variable
	SetVariable waveGrouping win=analysis_tools,value=_STR:StringFromList(2,filters,";")
	//prefix,group,series,etc. variables
	For(i=0;i<ItemsInList(groupList,";");i+=1)
		SetVariable $StringFromList(i,groupList,";") win=analysis_tools,value=_STR:StringFromList(i+3,filters,";")
	EndFor	
End

Function updateWSDimText()
	Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetNames
	Wave selWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave matchListselWave = root:Packages:analysisTools:AT_selWave
	
	ControlInfo/W=analysis_tools dataSetListBox
	Variable selection = V_Value
	Variable i,numWaves
	
	//No data set available
	If(DimSize(listWave,0) == 0)
		numWaves = DimSize(waveListTable,0)
		String dims = "1"
		DrawAction/W=analysis_tools delete		
		DrawText/W=analysis_tools 142,117,num2str(ItemsInList(dims)) + "/" + num2str(numWaves)
		return 0
	EndIf
	
	dims = GetWaveSetDims(listWave[selection])
	numWaves = 0
	For(i=0;i<ItemsInList(dims,";");i+=1)
		numWaves += str2num(StringFromList(i,dims,";"))
	EndFor
	
	DrawAction/W=analysis_tools delete		
	DrawText/W=analysis_tools 142,117,num2str(ItemsInList(dims)) + "/" + num2str(numWaves)
End


//Inputs data set name, and either wsn or wsLabel. Returns string list of waves in that wave set
Function/S getWaveSet(dsName,[wsn,wsLabel])
	String dsName
	Variable wsn
	String wsLabel
	String item,wsList = ""
	Variable pos1,pos2,index,i
	
	//Find the selected dataset
	If(isDataSet(dsName))
		Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	Else
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf
	
	//Defaults
	If(ParamIsDefault(wsn))
		wsn = -1
	EndIf
	
	If(ParamIsDefault(wsLabel))
		wsLabel = ""
	Else
		pos1 = strsearch(wsLabel,"WSN ",0)
		pos2 = strsearch(wsLabel,"--",pos1)
		String ws = wsLabel[pos1+4,pos2-1]
		wsn = str2num(wsLabel[pos1+4,pos2])
	EndIf
	
	//If nothing was input, return empty string
	If(wsn == -1 && strlen(wsLabel) == 0)
		return ""
	EndIf
	
	index = tableMatch("*WSN " + num2str(wsn) + "*",ds)
	i = 1
	Do
		If(index + i > DimSize(ds,0) - 1)
			return wsList
		EndIf
		item = ds[index+i]
		
		If(stringmatch(item,"*WSN*"))
			return wsList
		EndIf
		
		wsList += item + ";"
		i+=1
	While(index+i < DimSize(ds,0))
	
	return wsList
End

Function NudgeROI()
	WAVE/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	WAVE ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i
	
	Wave selWave = ROIListSelWave
	Wave/T listWave = ROIListWave
	
	//populate ROIListStr
	ROIListStr = ""
	For(i=0;i<DimSize(selWave,0);i+=1)
		If(selWave[i] == 1)
			ROIListStr += listWave[i] + ";"
		Endif
	EndFor
					
//Jamie's code for adding an ROI to the scanGraph if it exists
	// If shift key was held down, then we are just plotting
	//variable justPlot = ((ba.EventMod && 2) == 2)
	SVAR curScan = root:packages:twoP:examine:curScan
	if (cmpStr (curScan, "LiveWave") == 0)
		SVAR scanStr = root:packages:twoP:Acquire:LiveModeScanStr
	else
		SVAR scanStr = $"root:twoP_Scans:" + curScan + ":" + curScan + "_info"
		endif
	// window to plot on
	controlinfo/w=twoP_Controls ROIonWindowPopup

	string onWindow = S_Value
	
	doWindow/F $S_Value
	if (!(V_Flag))
		print "The selected graph no longer exists."
		return 1
	endif
// check subwin for twoPScanGraph
	if (cmpStr (onWindow, "twoPScanGraph") ==0)
		NVAR ROIChan = root:packages:twoP:examine:roiChan
		switch (ROIChan)
			case 1:
				onWindow = "twoPScanGraph#Gch1"
				break
			case 2:
				onWindow = "twoPScanGraph#Gch2"
				break
			case 3:
				onWindow = "twoPScanGraph#Gmrg"
				break
		endSwitch
		// if selected channel is not displayed, just use first subwindow
		if (WhichListItem(stringfromlist (1, onWindow, "#"), childWindowList (stringfromlist (0, onWindow, "#")), ";") == -1) // subwin not present
			onWindow = "twoPScanGraph#" + stringFromList  (0, childWindowList (stringfromlist (0, onWindow, "#")))
		endif
	endif
	// get a list of traces already on the graph, so they are not added 2x
	string tracelist = tracenamelist (onWIndow, ";", 1)
	// find selected ROIs, append them (if not already appended) and set the "drag" option
	// also copy list of drag traces into a global string
	WAVE/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	WAVE ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	variable ii, numroi = numpnts (ROIListWave), red, green, blue
	string roiStr
	string/G root:packages:twoP:examine:ROInudgeList =""
	SVAR ROInudgeList = root:packages:twoP:examine:ROInudgeList 
	for (ii =0; ii < numRoi; ii += 1)
		if (ROIListSelWave [ii] == 0)
			continue
		endif
		roiStr = ROIListWave [ii]
		ROInudgeList += roiStr + ";"
		// display ROI if it is not already displayed
		if (WhichListItem(roiStr + "_y", tracelist, ";") == -1)
			WAVE roiXWave = $ "Root:twoP_ROIs:" + roiStr + "_x"
			WAVE roiYWave = $ "Root:twoP_ROIs:" + roiStr + "_y"
			if (!((WaveExists (roiXWave)) && (WaveExists (roiYWave))))
				continue
			endif
			red = numberbykey ("Red", note (roiXWave))
			green = numberbykey ("Green", note (roiXWave))
			blue = numberbykey ("Blue", note (roiXWave))
			
			//Automatically make cyan
			red = 0
			green = 65535
			blue = 65535
			
			//Find which axes are being used
			String xAxisName,yAxisName,flags,info
			info = TraceInfo(onWindow,StringFromList(0,tracelist,";"),0)
			xAxisName = StringByKey("XAXIS",info,":",";")
			yAxisName = StringByKey("YAXIS",info,":",";")
			flags = StringByKey("AXISFLAGS",info,":",";")
			If(StringMatch(flags,"*/T*") && StringMatch(flags,"*/R*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/T=$xAxisName/R=$yAxisName RoiYWave vs RoiXwave
			ElseIf(StringMatch(flags,"*/T*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/T=$xAxisName RoiYWave vs RoiXwave
			ElseIf(StringMatch(flags,"*/R*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/R=$yAxisName RoiYWave vs RoiXwave
			Else
				appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
			EndIf
			
			//appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
		endif
	
					
		// set quickDrag for selected rois
					
		//	if (!(justPlot))
		//		modifyGraph/W=$onWindow quickDrag ($roiStr + "_y")=1
		//		String/G root:packages:twoP:examine:NudgeOnWindow = onWindow
		//	endif
	endfor
	//if not just plotting, set nudge button to new title and new procedure
	//	if (!(justPlot))
	//			Button ROINudgeButton win=twoP_Controls, title = "Done", proc = NQ_RoiNudgeDoneButtonProc, fColor=(65535,0,0)
	//	endif
End
//---------------------------------FUNCTIONS---------------------------------


Function ROI_From_MapData()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr 
	Variable k,i,j,s,r,count
	
	String channel = getChannel(1)
	channel = RemoveEnding(channel,";")
	String dFtype
	
	//Make wave list string for average results
	ControlInfo/W=analysis_tools avgResultsCheck
	Variable avgResults = V_Value
	
	//Loop through ROIs
	For(r=0;r<ItemsInList(ROIListStr,";");r+=1)
		//result list (for averaging) is reset after every ROI loop
		String resultList = ""
		
		String ROI = StringFromList(r,ROIListStr,";")
		String foldername = "root:ROI_analysis:ROI"+ROI
	
		If(DataFolderExists(foldername))
			Setdatafolder $foldername
		Else	
			NewDataFolder/S $foldername
		EndIf
		
		//X and Y waves that define the ROI area
		Wave roiX = $("root:twoP_ROIS:" + ROI+"_x")
		Wave roiY  = $("root:twoP_ROIS:" + ROI+"_y")
	
		//Loop through scans
		For(s=0;s<ItemsInList(scanListStr,";");s+=1)
	
			If(cmpstr(channel,"ch1") == 0)
				String ch1WaveName = "root:twoP_Scans:" + StringFromList(s,scanListStr,";") + ":" + StringFromList(s,scanListStr,";") + "_" + channel + "_dF"
				Wave ch1Wave = $ch1WaveName
				dFtype = "dF"
				If(!WaveExists(ch1Wave))
					print "Couldn't find wave " + NameOfWave(ch1Wave)
					return -1
				Else
					SetDataFolder GetWavesDataFolder(ch1Wave,1)
				EndIf
			ElseIf(cmpstr(channel,"ratio") == 0)
				ch1WaveName = "root:twoP_Scans:" + StringFromList(s,scanListStr,";") + ":" + StringFromList(s,scanListStr,";") + "_ch1_dGR"
				Wave ch1Wave = $ch1WaveName
				dFtype = "dGR"
			Else
				print "Only works with ch1 for now."
				return -1
			EndIf

			//ROI mask wave
			ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(dimSize(ch1Wave,0)),height=(dimSize(ch1Wave,1)),scalingwave=ch1Wave,seedx=(dimOffset(ch1Wave,0)+dimDelta(ch1Wave,0)),seedy=(dimOffset(ch1Wave,1)+dimDelta(ch1Wave,1))
			Wave ROIMask = M_ROIMask
			
			String outWaveName = foldername + ":" + ParseFilePath(1,NameOfWave(ch1Wave),"_",0,3) + dFtype + "_ROI" + ROI
			Make/O/N=(DimSize(ch1Wave,2)) $outWaveName
			Wave outWave = $outWaveName
			outWave = 0
	
			For(k=0;k<DimSize(ch1Wave,2);k+=1)
				//count # of real number pixels that are included in the average
				count = 0
		
				For(i=0;i<DimSize(ch1Wave,0);i+=1)
					For(j=0;j<DimSize(ch1Wave,1);j+=1)
						//Only pixels within the ROI
						If(ROIMask[i][j] == 1)
							continue
						Else
							//Only pixels that are real numbers, and not NaNs
							If(numtype(ch1Wave[i][j][k]) == 2)
								continue
							Else
								outWave[k] += ch1Wave[i][j][k]
								count+=1
							EndIf
						EndIf
					EndFor
				EndFor
				//Get the ROI average for that frame
				outWave[k]/= count
			EndFor
	
			ControlInfo/W=analysis_tools SmoothBox
			If(V_Value)
				ControlInfo/W=analysis_tools SmoothFilterVar
				Smooth/S=2 V_Value,outWave
			EndIf
	
			SetScale/P x,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),outWave
			
			//list of output wave paths for averaging
			If(avgResults)
				resultList += outWaveName + ";"
			EndIf
			
		EndFor
		
		//Average the ROIs
		If(avgResults)
			
			//prevent clipboard use for averaging routine
			NVAR useClipboard = root:Packages:MBr:useClipboard
			Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
			
			Redimension/N=1 clipboardListWave
			clipboardListWave[0] = ""
			useClipboard = 0
			
			avgSelectedWaves(resultList,0)
		EndIf
		KillWaves/Z ROIMask
	EndFor
End


//This procedure calculates the dF profile of selected ROIs over the scans selected in "Analysis Tools"
Function NMultiROI()
	NVAR Gbatchsize = root:Packages:analysisTools:Gbatchsize
	NVAR Gnumtrials = root:Packages:analysisTools:Gnumtrials
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd
	NVAR TempFilter = root:Packages:analysisTools:TempFilter
	NVAR SmoothSize = root:Packages:analysisTools:GSmoothFilter
	NVAR red = root:Packages:analysisTools:Gred
	NVAR green = root:Packages:analysisTools:Ggreen
	NVAR blue = root:Packages:analysisTools:Gblue
	
	wave/T ScanListWave = root:Packages:twoP:examine:ScanListWave
	wave selWave = root:Packages:twoP:examine:selWave
	NVAR darkValue = root:Packages:analysisTools:GdarkValue
	
	//The ROIs and the scans
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	
	//Get angle list
	CONTROLINFO/W=analysis_tools angleList
	String angleList = S_Value
	String errStr = ""
	String report = ""
	
	string ROI,scanName,ValueWaveName
	
	//Get channel mode
	string channelMode = ""
	string channel = "ch1"
	CONTROLINFO/W=analysis_tools ch1Check
	If(V_Value)
		channelMode += "1"
	Else
		channelMode +="0"
	EndIf
	
	CONTROLINFO/W=analysis_tools ch2Check
	If(V_Value)
		channelMode += "1"
	Else
		channelMode +="0"
	EndIf
	
	CONTROLINFO/W=analysis_tools ratioCheck
	If(V_Value)
		channelMode += "1"
	Else
		channelMode +="0"
	EndIf

	string savedFolder = getDataFolder (1)
	string curFolder = getdatafolder(1)

	if(!DataFolderExists("root:ROI_analysis"))
		NewDataFolder root:ROI_analysis
	endif
	
	SetDataFolder root:ROI_analysis	
	
	variable totalScans = numpnts(ScanListWave)
//	print "totalScans", totalScans
	
	
	NVAR curScanNumber = root:packages:twoP:examine:curScanNum
	wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	variable ScanNumber = curScanNumber

	variable ROIList
	variable bsln
	variable i
	
	//Run for every ROI selected
	For (ROIList = 0; ROIList < ItemsInList(ROIListStr,";"); ROIList+=1)
		
		ScanNumber = curScanNumber
		variable SelWaveNumber = 0
			
		//Get the ROI name
		ROI = StringFromList(ROIList,ROIListStr,";")
	
		String foldername = "root:ROI_analysis:ROI"+ROI
	
		If(DataFolderExists(foldername))
			setdatafolder $foldername
		Else	
			NewDataFolder/S $foldername
		EndIf
		
		//X and Y waves that define the ROI area
		Wave roiX = $("root:twoP_ROIS:" + ROI+"_x")
		Wave roiY  = $("root:twoP_ROIS:" + ROI+"_y")
	
			ValueWaveName = "ROI"+ROI+"_values" //wave that saves the (peak/avg) dF value of each scan
			if (waveexists($ValueWaveName)==0) //if this wave does not exist, create it
				make/N = (TotalScans) $ValueWaveName
			else
				//Print ValueWaveName +" exists"
			endif
			
			wave ValueSource =  $ValueWaveName
	
			
		//Get direction and order waves
		Gbatchsize = ItemsInList(scanListStr,";")
		report += "MultiROI...Scans: " + num2str(Gbatchsize)
		
		Make/O/N=(Gbatchsize) order,direction
		
		If(ItemsInList(angleList,",") != Gbatchsize)
			errStr += "Number of angles does not match number of scans"
			order = x
			direction = x
		Else
			//Get the angle order based on the angle list
			If(strlen(angleList))
				Make/FREE/N=(ItemsInList(scanListStr,";")) angleListWave,sortKey

				For(i=0;i<ItemsInList(angleList,",");i+=1)
					angleListWave[i] = str2num(StringFromList(i,angleList,","))
				EndFor
				
				direction = angleListWave
				Sort direction,direction
				
				For(i=0;i<ItemsInList(angleList,",");i+=1)
					FindValue/V=(WaveMin(angleListWave)) angleListWave
					angleListWave[V_Value] = 1000
					order[i] = V_Value
				EndFor
			EndIf
		EndIf
			

		Variable st_pt = 0,end_pt = 0
		String axisname, signals, tracename,firstChannel
	
		Variable j, k, ii, l,bothChannels
		
		//Run for each trial batch
		For(i=0;i<Gnumtrials;i+=1)
			
			//Run for each scan
			For(j=0;j<Gbatchsize;j+=1)
		 		//Get the current scan
		 		scanName = StringFromList(j,scanListStr,";")
		 		
		 		String inputWaveName = "root:twoP_Scans:" + scanName + ":" + scanName
		 		String inputWaveName2 = inputWaveName	//For possible second channel
		 		
		 		//Assign correct scan channels to waves
		 		If(cmpstr(channelMode,"100") == 0)
		 			//Channel 1 only
		 			inputWaveName += "_ch1"
		 			Wave inputWave = $inputWaveName
		 			bothChannels = 0
		 			firstChannel = "ch1"
		 		ElseIf(cmpstr(channelMode,"010") == 0)
		 			//Channel 2 only
		 			inputWaveName += "_ch2"
		 			Wave inputWave = $inputWaveName
		 			bothChannels = 0
		 			firstChannel = "ch2"
		 		ElseIf(cmpstr(channelMode,"110") == 0)
		 			//Channel 1 and 2
		 			inputWaveName += "_ch1"
		 			inputWaveName2 += "_ch2"
		 			Wave inputWave = $inputWaveName
		 			Wave inputWave2 = $inputWaveName2
		 			bothChannels = 1
		 			firstChannel = "ch1"
		 		ElseIf(cmpstr(channelMode[2],"1") == 0)
		 			//Ratiometric Ch1/Ch2
		 			inputWaveName += "_ch1"
		 			inputWaveName2 += "_ch2"
		 			Wave inputWave = $inputWaveName
		 			Wave inputWave2 = $inputWaveName2
		 			bothChannels = 1
		 			firstChannel = "ch1"
		 		Else
		 		//If user didn't check any of the boxes
		 		//default to Channel 1 only
		 			inputWaveName += "_ch1"
		 			Wave inputWave = $inputWaveName
		 			bothChannels = 0
		 			firstChannel = "ch1"
		 		EndIf
		 		
				
				//Check wave existence
				If(!WaveExists(inputWave))
					Abort inputWaveName + " - does not exist"
				ElseIf(bothChannels)
					If(!WaveExists(inputWave))
						Abort inputWaveName + " - does not exist"	
					EndIf
				EndIf
				
				//Make ROI average wave
				Make/O/N=(DimSize(inputWave, 2)) $(foldername + ":ROIavg_" + firstChannel)
				Wave ROIavg = $(foldername + ":ROIavg_" + firstChannel)
				
				If(bothChannels)
					Make/O/N=(DimSize(inputWave, 2)) $(foldername + ":ROIavg_ch2")
					Wave ROIavg2 = $(foldername + ":ROIavg_ch2")
				EndIf
				
				
				
				//ROI mask wave
				ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(dimSize(inputWave,0)),height=(dimSize(inputWave,1)),scalingwave=inputWave,seedx=(dimOffset(inputWave,0)+dimDelta(inputWave,0)),seedy=(dimOffset(inputWave,1)+dimDelta(inputWave,1))
				WAVE ROIMask = $(foldername + ":M_ROIMask")	
				
				//Average values over the ROI mask
				For(k=0;k<DimSize(inputWave,2);k+=1)
					ImageStats/M=1/P=(k)/R=ROImask inputWave
					
					ROIavg[k] = V_avg
					If(bothChannels)
						ImageStats/M=1/P=(k)/R=ROImask inputWave2
						ROIavg2[k] = V_avg
					EndIf
				EndFor
				
				
			
				If(TempFilter)
					Smooth/S=2 (SmoothSize), ROIavg //Savitzky-Golay smoothing // SS 10AUG2017 changed num from 15 to 9
					SetScale/P x,DimOffset(inputWave,2),DimDelta(inputWave,2),ROIavg
					If(bothChannels)
						Smooth/S=2 (SmoothSize), ROIavg2
						SetScale/P x,DimOffset(inputWave,2),DimDelta(inputWave,2),ROIavg2
					EndIf
					//IterativeSmooth(ROIavg,1)
				EndIf
				
				
				
				If(bothChannels)
					Variable redBaseline = mean(ROIavg2)
				EndIf
				//BE CAREFUL WITH DARK SUBTRACTION. IF THE SUBTRACTION ISN'T THE SAME ACROSS TRIALS, THE ∆F/F CAN
				//BE VERY WRONG WHEN COMPARING ACROSS TRIALS. TO BE SAFE JUST USE BASELINE SUBTRACTION FROM ROIavg.
				
				//Find dark value and subtract from ROI trace
				
				ControlInfo/W=analysis_tools DarkValueVar
				String saveDF = GetDataFolder(1)
		
				Wave darkMask = getDendriticMask()
				//Wave darkMask = root:twoP_Scans:Scan_AVG_ch2_mask
				Redimension/B/U darkMask
				
				If(bothChannels)
					ImageStats/R=darkMask inputWave2
					Variable darkValue_ch2 = V_avg
				EndIf
					
				ImageStats/R=darkMask inputWave
				Variable darkValue_ch1 = V_avg
				
				SetDataFolder $saveDF
				//Make/FREE/N=(round(0.05*DimSize(inputWave,0)),round(0.05*DimSize(inputWave,1)),GbslnEnd - GbslnSt) darkMatrix
				//darkMatrix[][][] = inputWave[p][q][r + GbslnSt]
				
			   //MatrixOP/FREE/O temp = sum(darkMatrix)
				//temp /= DimSize(darkMatrix,0)*DimSize(darkMatrix,1)
				//MatrixOP/O dark = sumBeams(temp)
				//dark /= DimSize(temp,2)
				//darkValue = dark[0]
				//print darkValue
				//ROIavg -= darkValue 
				
			
				//Remove the laser response
				FlattenLaserResponse(ROIavg,0,GbslnEnd,1,2.25)
				
				//Get the baseline value of the trace
				Wavestats/Q/R = (GbslnSt,GbslnEnd) ROIavg
				
				bsln = V_avg
				
				String dFName
				//Make ∆F/F or ∆G/R waves
				If(cmpstr(channelMode[2],"1") == 0)
					dFname = scanName + "_ROI" + ROI + "_dGR"
				Else
					dFname = scanName + "_ROI" + ROI
				EndIf
			
				Duplicate/O ROIavg, $dFname
				Wave ROIDF = $dFname 
				
				If(cmpstr(channelMode[2],"1") == 0)
					//∆G/R
					ROIDF = (ROIavg - (bsln-0.02*bsln))/(redBaseline - darkValue_ch2)
					//buffers in an extra 2% of the bsln signal so we aren't at a negative baseline all the time. 
				Else
					//∆F/F
					ROIDF = (ROIavg - (bsln-0.05*bsln))/(bsln - darkValue_ch1) 
				EndIf
				
				//Get frame time for scaling
				Variable delta = DimDelta(inputWave,2)
				SetScale/P x,0,delta,ROIDF
				
				//Finds the peak ∆F/F and puts into a wave
				Wavestats/Q/R = (GpeakSt,GpeakEnd) ROIDF
				ValueSource[ScanNumber] = V_max
				//Duplicate/O ROIDF, $(ScanName+"ROI"+ ROI)
			
				FindValue /V= (j) order
				l = V_value+1
			
				st_pt = 1/Gbatchsize*(l-1)+.005  //divide the graph equally for the number of directions and space the plots for each direction.
				end_pt = 1/Gbatchsize*l-.005
	
				k = order(l-1)
				
				tracename = scanName+"_ROI"+ ROI
				If(cmpstr(channelMode[2],"1") == 0)
					tracename = scanName+"_ROI"+ ROI + "_dGR"
				EndIf
				
				axisname = "axis"+ tracename//axis handle
				signals = "signal"+"_ROI"+ROI+"_"+"graph" // window handle
			
				DoWindow $signals
				If(V_flag == 0) //if does not window exist
					Display /N=$signals/B=$axisname ROIDF
					//tag /A=MT /N=$TagName $axisname, 0, DirectionName
					//TextBox/C/N=directions/A=MT " { 225 , 270 , 315 , 0 , 45 , 90 ,135 ,180 }" // Create textbox with order of directions
				Else
					If(strlen(TraceInfo(signals,NameOfWave(ROIDF),0)))
						RemoveFromGraph/Z/W = $signals $NameOfWave(ROIDF)
					EndIf
					AppendToGraph/W = $signals /B=$axisname ROIDF
				EndIf
		
				ModifyGraph/W = $signals  axisEnab($axisname)={st_pt,end_pt} //position graph
				ModifyGraph/W = $signals  standoff=1,freePos($axisname)={0,left}
				ModifyGraph/W = $signals  rgb($tracename) =(red,green,blue) // change color
				ModifyGraph/W = $signals  margin(left)=35,margin(bottom)=28,margin(right)=7,margin(top)=7,gfSize=8,axThick=0.5,standoff=0
				//Set axis to 0.2 ∆F/F
				//SetAxis/W = $signals left -0.05,0.2 
				If(cmpstr(channelMode[2],"1") == 0)
					Label/W = $signals left,"∆G/R   \\E"
				Else
					Label/W = $signals left,"∆F/F   \\E"
				EndIf
			//Scan loop
			EndFor
		//Batch loop
		EndFor
	//ROI loop
	EndFor
	print report
	SetDataFolder curFolder
End

//Recoded version of NMultiROI to keep style consistent
Function GetROI()
	//The ROIs and the scans
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	
	//scan or browser mode?
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	
	Variable numROIs,numScans,numFrames,doRatio,darkVal,darkVal2,bslnStart,bslnEnd,bsln,bsln2
	Variable TempFilter,smoothSize,getPeaks,pkStart,pkEnd,pkWindow,i,j,k,m,activePixels,activePixelThresh,darkSubtract
	String theROI,theScanName,ROIFolder,dFname,saveDF
	
	String errStr = ""
	String report = ""
	
	//Get the baseline parameters
	ControlInfo/W=analysis_tools bslnStVar
	bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	bslnEnd = V_Value
	ControlInfo/W=analysis_tools peakStVar
	pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	pkEnd = V_Value
	ControlInfo/W=analysis_tools pkWindow
	pkWindow = V_Value
	
	ControlInfo/W=analysis_tools doDarkSubtract
	darkSubtract = V_Value
	
	ControlInfo/W=analysis_tools activePixelsOnly
	activePixels = V_Value
	ControlInfo/W=analysis_tools activePixelThreshSize
	activePixelThresh = V_Value
	
	//Get the peak values?
	ControlInfo/W=analysis_tools getPeaksCheck
	getPeaks = V_Value
	
	//Get the average over the time window?
	ControlInfo/W=analysis_tools doAvgCheck
	Variable doAvg = V_Value
	
	//Average the ROIs that have been selected?
	ControlInfo/W=analysis_tools doAvgROIsCheck
	Variable avgROIs = V_Value

	
	//Get channel - only allows one at a time
	
	If(cmpstr(whichList,"AT") == 0)
		String channel = RemoveEnding(getChannel(1),";")
		If(cmpstr(channel,"ratio") == 0)
			doRatio = 1
		Else
		 	doRatio = 0
		EndIf
	Else
		channel = "ch1"
	EndIf
	
	//Make ROI_analysis folder
	If(!DataFolderExists("root:ROI_analysis"))
		NewDataFolder root:ROI_analysis
	EndIf
	SetDataFolder root:ROI_analysis	
	
	numROIs = ItemsInList(ROIListStr,";")
	
	If(cmpstr(whichList,"AT") == 0)		
		numScans = ItemsInList(scanListStr,";")
	ElseIf(cmpstr(whichList,"Browser") == 0)
		numScans = ItemsInList(selWaveList,";")
	EndIf
		
	//Divided up by batch?
	ControlInfo/W=analysis_tools BatchsizeVar
	Variable batchSize = V_Value
	If(batchSize == 0 || batchSize < 0 || batchSize == 1)
		batchSize = numScans
	EndIf	
		
	Variable batchCount,counter,nextBatch
	batchCount = 1
	counter = 0
	nextBatch = 0
		
	//LOOP THROUGH SCANS
		For(j=0;j<numScans;j+=1)
			
			//Scan Mode
			If(cmpstr(whichList,"AT") == 0)
				//Get the scan
				theScanName = StringFromList(j,scanListStr,";")
			
				If(doRatio)
					//ratio
					Wave/Z theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch1")
					Wave/Z theScan2 = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch2")
				
					//does channel 2 scan exist?
					If(!WaveExists(theScan2))
						DoAlert 0,"Couldn't find the scan: " + NameOfWave(theScan2)
						continue
					EndIf
				Else
					//single channel
					Wave/Z theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_" + channel)
				EndIf
				
			//Browser Mode
			ElseIf(cmpstr(whichList,"Browser") == 0)
				theScanName = StringFromList(j,selWaveList,";")
				Wave/Z theScan = $(cdf + theScanName)
			EndIf
			
			
			//Wave theScan = root:twoP_Scans:Scan_000:dGR_avg_90DARK_RF
			//theScanName = NameOfWave(theScan)
			
			//Does the scan exist?
			If(!WaveExists(theScan))
				DoAlert 0,"Couldn't find the scan: " + NameOfWave(theScan)
				continue
			EndIf
			
			numFrames = DimSize(theScan,2)
			
			//Make the waves to get raw fluorescence data from ROI
			If(doRatio)
				Make/FREE/N=(numFrames) RawROI,RawROI2
				//Set the scale for the raw ROI waves
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI,RawROI2
			Else
				Make/FREE/N=(numFrames) RawROI
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI
			EndIf
			
			//Get the dark values for each channel using a mask
			saveDF = GetDataFolder(1)
				
			Wave darkMask = getDendriticMask(theWave=theScan,noBuffer=0)
			Wave/Z maxProj = maxProj //created by getDendriticMask
			KillWaves/Z maxProj
			
			Redimension/B/U darkMask
			
			ImageStats/R=darkMask theScan
			darkVal = 0.9*V_avg
			
			//create some buffer room so the dark never accidentally gets higher than...
			//...the dendrite background in the case of a dim dendrite
			//darkVal -= 0.1*darkVal
			
			If(doRatio)
				ImageStats/R=darkMask theScan2
				darkVal2 = 0.9*V_avg
			EndIf
			
			KillWaves/Z darkMask
			
			SetDataFolder $saveDF
			 
			//Temporal smoothing
			ControlInfo/W=analysis_tools SmoothBox
			TempFilter = V_Value
			If(V_Value)
				ControlInfo/W=analysis_tools SmoothFilterVar
				smoothSize = V_Value
			EndIf

			
			//LOOP THROUGH ROIs	/////////////////////////////
			For(i=0;i<numROIs;i+=1)
				
				//set the counters
				If(j == batchSize * batchCount && i == 0)
					nextBatch = 1
					counter = 0
				ElseIf(j == batchSize * batchCount + 1) 	//only change batch after all ROIs have been completed
					batchCount += 1
					nextBatch = 0
				EndIf
			
				//Get the ROI
				theROI = StringFromList(i,ROIListStr,";")
				ROIFolder = "root:ROI_analysis:ROI" + theROI
		
				If(!DataFolderExists(ROIFolder))
					NewDataFolder $ROIFolder
				EndIf
				SetDataFolder $ROIFolder
		
				//X and Y waves that define the ROI area
				Wave/Z roiX = $("root:twoP_ROIS:" + theROI + "_x")
				Wave/Z roiY  = $("root:twoP_ROIS:" + theROI + "_y")
		
				//Do the ROI waves exist?
				If(!WaveExists(roiX))
					DoAlert 0,"Couldn't find the ROI X wave: " + NameOfWave(roiX)
					continue
				ElseIf(!WaveExists(roiY))
					DoAlert 0,"Couldn't find the ROI Y wave: " + NameOfWave(roiY)
					continue
				EndIf
				
				//Seed values for filling out the ROI mask
				Variable maskMax,maskMin,xSeed,ySeed
				WaveStats/Q theScan
				
				maskMin = WaveMin(roiX)
				maskMax = WaveMax(roiX)
				
				xSeed = maskMax + DimDelta(theScan,0)
				If(xSeed > IndexToScale(theScan,DimSize(theScan,0)-1,0))
					xSeed = 0
				EndIf
				
				maskMin = WaveMin(roiY)
				maskMax = WaveMax(roiY)
				
				ySeed = maskMax + DimDelta(theScan,1)
				If(ySeed > IndexToScale(theScan,DimSize(theScan,1)-1,1))
					ySeed = 0
				EndIf
				
				//ROI mask wave				
				ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(DimSize(theScan,0)),height=(DimSize(theScan,1)),scalingwave=theScan,seedx=xSeed,seedy=ySeed
				
			
				Wave ROIMask = $(ROIFolder + ":M_ROIMask")	
				
				//Did the ROI mask actually get created?
				If(!WaveExists(ROIMask))
					DoAlert 0, "Couldn't find the ROI mask wave for: " + NameOfWave(theScan)
					continue
				EndIf
				
				//For using only active pixels within an ROI, trim the ROI around the dendrite here.
				If(activePixels)
					
					Wave ROImaskTrim = $(ROIFolder + ":M_ROIMaskTrim")	
					Duplicate/O ROImask,ROImaskTrim
					
					ImageTransform averageImage theScan
					Wave avgImage = M_AveImage
					Wave stdImage = M_StdvImage
					
					ROImaskTrim = (avgImage > activePixelThresh*darkVal && ROImask == 0) ? ROImaskTrim : 1	
					
					Variable ROIpnts,trimROIpnts
					ImageStats/R=ROImask theScan 
					ROIpnts = V_npnts
					ImageStats/R=ROImaskTrim theScan 
					trimROIpnts = V_npnts
					
					If(trimROIpnts/ROIpnts < 0.1)
					//	DoAlert 0,"Less than 10% of " + theROI + " contains active pixels"
					EndIf
					
					Wave ROImask = ROImaskTrim
				EndIf

				//Average values over the ROI region
				For(k=0;k<numFrames;k+=1)
					ImageStats/M=1/P=(k)/R=ROImask theScan
					RawROI[k] = V_avg
					
					//Make/O/N=(DimSize(RawROI,0)) $(NameOfWave(theScan) + "_orig")//,root:theROI_smooth
					//Wave origROI = $(NameOfWave(theScan) + "_orig")
				//	Wave smoothROI = root:theROI_smooth
					
				
					If(doRatio)
						ImageStats/M=1/P=(k)/R=ROImask theScan2
						RawROI2[k] = V_avg
					EndIf
				EndFor
				
				
				//Searches for single frame large values that are more likely instrument noise.
				//Discovered values are set to the local mean
				Variable value,localAvg,sdev
				Wavestats/Q RawROI
				sdev = V_sdev
				For(m=1;m<numFrames-1;m+=1) //avoids end points
					value = RawROI[m]
					localAvg = mean(RawROI,pnt2x(RawROI,m-1),pnt2x(RawROI,m+1))
					If(value > localAvg + 3*sdev)
						RawROI[m] = localAvg
					EndIf
				EndFor
				
				//origROI = RawROI

				If(TempFilter)
					Smooth/S=2 (smoothSize), RawROI //Savitzky-Golay smoothing
					SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI
					
				//	smoothROI = RawROI
				//SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),origROI//,smoothROI
					If(doRatio)
						Smooth/S=2 (smoothSize), RawROI2
						SetScale/P x,DimOffset(theScan2,2),DimDelta(theScan2,2),RawROI2
					EndIf
				EndIf
				
				//Remove the laser response, if any to assist the baseline estimation.
				
				ControlInfo/W=analysis_tools RemoveLaserResponseCheck
				If(V_Value)
					FlattenLaserResponse(RawROI,0,bslnEnd,1,pkStart)
				EndIf			
				
				//Get the baseline value of the trace
				//Use median for the baseline, so it doesn't get pulled up or down from noisy values
				bsln = median(RawROI,bslnStart,bslnEnd)
				//print bsln
				
				//Get the red baseline for ratio
				If(doRatio)
					bsln2 = median(RawROI2,bslnStart,bslnEnd)
				EndIf
				
			//	theScanName = ReplaceString(StringFromList(0,theScanName,"_"),theScanName,"CTRL")
				//String replaceStr = ParseFilePath(1,theScanName,"_",1,0)
				//theScanName = ReplaceString(replaceStr,theScanName,"_")
				//theScanName = "Scan"
				
				//Make ∆F/F or ∆G/R waves
				If(cmpstr(whichList,"AT") == 0)
					If(doRatio)
						dFname = theScanName + "_1_ROI" + theROI + "_dGR"
					Else
						dFname = theScanName + "_" + channel + "_ROI" + theROI + "_dF"
					EndIf
				ElseIf(cmpstr(whichList,"Browser") == 0)
					//different naming scheme for non-scan list waves that might have different name structures
					dFname = theScanName + "_ROI" + theROI + "_dF"
				EndIF
				
				//Make the dF or dG wave
				Make/O/N=(numFrames) $dFName
				Wave dF = $dFName
			
				//Calculate ∆F/F or ∆G/R
				If(doRatio)
					//∆G/R
					If(darkSubtract)
						dF = (RawROI - bsln)/(bsln2 - darkVal2)
					Else
						dF = (RawROI - bsln)/bsln2
					EndIf
				Else
					//∆F/F
					If(darkSubtract)
						dF = (RawROI - bsln)/(bsln - darkVal) 
					Else
						dF = (RawROI - bsln)/bsln 
					EndIf
				EndIf
				
				//Set scale
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
				
				
				////////////////////////////////////////////////////
				//Gets the peak ∆F values for the list for the scan list
				If(getPeaks)
					
					//Start a new peak ∆F wave?
					If(j == 0 || nextBatch == 1)
						String baseName = theScanName
						
						If(doRatio)
							String peakDFname = baseName + "_1_ROI" + theROI + "_dGR_pk"
						Else
							peakDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_pk"
						EndIf
						
						Make/O/N=(batchSize) $peakDFname			
					Else
						If(doRatio)
							peakDFname = baseName + "_1_ROI" + theROI + "_dGR_pk"
						Else
							peakDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_pk"
						EndIf
					EndIf
					
					Wave/Z peakDF = $peakDFname
			
					If(!WaveExists(peakDF))
						DoAlert 0,"Couldn't find the peak ∆F wave."
						continue
					EndIf
			
					peakDF[counter] = getPeakVals(dF,pkStart,pkEnd,pkWindow)
				EndIf
				
				If(doAvg)
					If(j == 0 || nextBatch == 1)
						baseName = theScanName
						If(doRatio)
							String tavgDFname = baseName + "_1_ROI" + theROI + "_dGR_tavg"
						Else
							tavgDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_tavg"
						EndIf
						Make/O/N=(batchSize) $tavgDFname	
					Else
						If(doRatio)
							tavgDFname = baseName + "_1_ROI" + theROI + "_dGR_tavg"
						Else
							tavgDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_tavg"
						EndIf
					EndIf
				
					Wave/Z tavgDF = $tavgDFname
			
					If(!WaveExists(tavgDF))
						DoAlert 0,"Couldn't find the time average ∆F wave."
						continue
					EndIf
				
					tavgDF[counter] = mean(dF,pkStart,pkEnd)
				EndIf
					
					////REORDER THE PEAK DATA///////////////////////////////
					If(counter == batchSize - 1) //If we're at the end of a batch				
						//rearrange the peak data points according to the angle list
						If(getPeaks)
							If(batchSize > 1)
								Redimension/N=(batchSize) peakDF	
								Variable theSize = batchSize
							Else
								Redimension/N=(numScans) peakDF		
								theSize = numScans
							EndIf
							
							Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
							ControlInfo/W=analysis_tools presetAngleListPop
		
							If(V_Value != 1)
								String angleList = presetAngleWave[V_Value-1][1]
								Make/FREE/N=(theSize) order
								
								If(batchSize > 1)
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=1)
								Else
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=0)
								EndIf
															
								Make/FREE/N=(theSize) tempPeak
								//Sort theOrderWave,peakDF
								For(m=0;m<theSize;m+=1)
									tempPeak[m] = peakDF[theOrderWave[m]]
								EndFor
								peakDF = tempPeak
							EndIf
						EndIf
						
						//rearrange the time average data points according to the angle list
						If(doAvg)
							If(batchSize > 1)
								Redimension/N=(batchSize) tavgDF	
								theSize = batchSize
							Else
								Redimension/N=(numScans) tavgDF		
								theSize = numScans
							EndIf
						
							Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
							ControlInfo/W=analysis_tools presetAngleListPop
	
							If(V_Value != 1)
								angleList = presetAngleWave[V_Value-1][1]
								Make/FREE/N=(theSize) order
								
 								If(batchSize > 1)
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=1)
								Else
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=0)
								EndIf
								
								Make/FREE/N=(theSize) tempPeak

								For(m=0;m<theSize;m+=1)
									tempPeak[m] = tavgDF[theOrderWave[m]]
								EndFor
								tavgDF = tempPeak
								
							EndIf
						EndIf
						//////////////	
					EndIf	
					
					//Set the wave notes
					If(getPeaks)
						Note/K peakDF//kill existing note
						SetWaveNote(peakDF,"baseline;peak;smooth;channel;peakWidth")
					EndIf
					
					If(doAvg)
						Note/K tavgDF//kill existing note
						SetWaveNote(tavgDF,"baseline;peak;smooth;channel;peakWidth")
					EndIf
					
					//clean up
				//	KillWaves/Z ROIMask
					KillWaves/Z avgImage,stdImage//,ROImaskTrim
			EndFor	
			counter += 1
	EndFor	


	If(avgROIs)
		avgROIWaves(ROIListStr,scanListStr,channel,DimSize(theScan,2))
	EndIf
End

//Takes multiROI waves and averages them for each ROI separately
Function avgROIWaves(ROIListStr,scanListStr,channel,scanSize)
	String ROIListStr,scanListStr,channel
	Variable scanSize
	
	Variable i,j,numROIs,numScans
	String theROI,theScan,baseName,avgDFName,theROIName
	
	numROIs = ItemsInList(ROIListStr,";")
	numScans = ItemsInList(ScanListStr,";")
	
	baseName = StringFromList(0,ScanListStr,";")
	
	For(i=0;i<numROIs;i+=1)
		theROI = StringFromList(i,ROIListStr,";")
		
		If(cmpstr(channel,"ratio") == 0)
			//dGR
			avgDFName = "root:ROI_analysis:ROI" + theROI + ":" + baseName + "_" + channel + "_ROI" + theROI + "_dGR_avg"
		Else
			//dF
			avgDFName = "root:ROI_analysis:ROI" + theROI + ":" + baseName + "_" + channel + "_ROI" + theROI + "_dF_avg"
		EndIf
		Make/O/N=(scanSize) $avgDFName
		Wave/Z avgDF = $avgDFName
		avgDF = 0
		
		For(j=0;j<numScans;j+=1)
			theScan = StringFromList(j,ScanListStr,";")
			If(cmpstr(channel,"ratio") == 0)
				theROIName = "root:ROI_analysis:ROI" + theROI + ":" + theScan + "_" + channel + "_ROI" + theROI + "_dGR"
			Else
				//dF
				theROIName = "root:ROI_analysis:ROI" + theROI + ":" + theScan + "_" + channel + "_ROI" + theROI + "_dF"
			EndIf
			
			Wave/Z theROIWave = $theROIName
			avgDF += theROIWave
		
			//sets the wave notes
			If(j == 0)
				Note/K avgDF,"Averaged Waves: " + num2str(numScans)
				Note avgDF,NameOfWave(theROIWave)
			Else
				Note avgDF,NameOfWave(theROIWave)
			EndIf
		EndFor
		//does average
		avgDF /= numScans
		//sets scale
		SetScale/P x,DimOffset(theROIWave,0),DimDelta(theROIWave,0),avgDF
	EndFor
End

Function SetWaveNote(theWave,paramListStr)
	Wave theWave
	String paramListStr
	Variable numParams,i
	String theParam
	
	numParams = ItemsInList(paramListStr,";")
	
	ControlInfo/W=analysis_tools bslnStVar
	Variable bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	Variable bslnEnd = V_Value
	ControlInfo/W=analysis_tools peakStVar
	Variable pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	Variable pkEnd = V_Value
	ControlInfo/W=analysis_tools pkWindow
	Variable pkWindow = V_Value
	ControlInfo/W=analysis_tools SmoothBox
	Variable TempFilter = V_Value
	ControlInfo/W=analysis_tools SmoothFilterVar
	Variable smoothSize = V_Value
	
	For(i=0;i<numParams;i+=1)
		theParam = StringFromList(i,paramListStr,";")
		
		strswitch(theParam)
			case "baseline":
				Note theWave,"BSL_START:" + num2str(bslnStart)
				Note theWave,"BSL_END:" + num2str(bslnEnd)
				break
			case "peak":
				Note theWave,"PK_START:" + num2str(pkStart)
				Note theWave,"PK_END:" + num2str(pkEnd)
				break
			case "smooth":
				If(TempFilter)
					Note theWave,"SMOOTH:" + num2str(smoothSize)
				Else
					Note theWave,"SMOOTH:0"
				EndIf
				break
			case "channel":
				If(stringmatch(NameOfWave(theWave),"*ch1*"))
					Note theWave,"CHANNEL:1"
				ElseIf(stringmatch(NameOfWave(theWave),"*ch2*"))
					Note theWave,"CHANNEL:2"				
				Else
					Note theWave,"CHANNEL:-1"
				EndIf
				break
			case "peakWidth":
				Note theWave,"PK_WIDTH:" + num2str(pkWindow)
				break
			endswitch
	EndFor
	
End


//Called by getROI() to get the peak values of the ROIs
Function getPeakVals(inWave,pkStart,pkEnd,pkWindow[,getPkTm])
	Wave inWave
	Variable pkStart,pkEnd,pkWindow,getPkTm
	Variable pkLoc,peakVal
	
	WaveStats/Q/R=(pkStart,pkEnd) inWave
	pkLoc = V_maxLoc
	
	//if pkWindow is 0, it just takes the absolute peak instead of averaging over a range around the peak location.
	If(pkWindow != 0)
		peakVal = mean(inWave,pkLoc - 0.5*pkWindow,pkLoc + 0.5*pkWindow)
	Else
		peakVal = V_max
	EndIf
	
	If(ParamIsDefault(getPkTm))
		return peakVal
	Else
		return pkLoc
	EndIf
End

//Take ROIs, and finds their pk times for corresponding dF waves, puts values into a 2D matrix wave for mapping
Function ROIgrid_pktm(gridMask,startTm,endTm,threshold,fit,leftExclude)
	Wave gridMask
	Variable startTm,endTm,threshold
	String fit
	Variable leftExclude
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numROIs = ItemsInList(ROIListStr,";")
	Variable numScans =ItemsInList(scanListStr,";")
	Variable i,j,m,n,xDim,yDim,thePkTm
	String theROIName,theScanName,theWaveName
	
	Duplicate/FREE gridMask,testMask
	
	If(!DataFOlderExists("root:ROI_analysis:grid"))
		NewDataFolder root:ROI_analysis:grid	
	EndIf
	SetDataFolder root:ROI_analysis:grid
	
	xDim = DimSize(gridMask,0)
	yDim = DimSize(gridMask,1)
	
	For(i=0;i<numScans;i+=1)
		theScanName = StringFromList(i,scanListStr,";")
		//Make the grid wave for the scan to hold the peak times
		Make/O/N=(xDim,yDim) $(theScanName + "_grid_pktm")
		Wave grid = $(theScanName + "_grid_pktm")
		grid = 0
		
		For(j=0;j<numROIs;j+=1)
			//Get the dF wave for the selected scan and ROI
			theROIName = StringFromList(j,ROIListStr,";")

			theWaveName = "root:ROI_analysis:" + "ROI" + theROIName + ":" + theScanName + "_ch1_ROI" + theROIName + "_dF"
			Wave/Z theWave = $theWaveName
			If(!WaveExists(theWave))
				Abort "Cannot find the wave: " + theWaveName
			EndIf
			
			thePkTm = getPeakVals(theWave,startTm,endTm,0,getPkTm=1)	//gets the x location of the peak dF
			
			Variable	done = 0
			For(m=0;m<xDim;m+=1)
				For(n=0;n<yDim;n+=1)
					If(testMask[m][n] == 1)
						WaveStats/Q/R=(startTm,endTm) theWave
						Variable maxVal = V_max
						WaveStats/Q theWave
						Variable sdev = V_sdev
						If(maxVal < threshold*sdev)
							grid[m][n] = 0
						Else
							//find rise time using sigmoidal fit
							strswitch(fit)
								case "":
								case "none":
									break
								case "sigmoid":
									Variable peakIndex = ScaleToIndex(theWave,thePkTm,0)
									Make/O/N=(DimSize(theWave,0)) root:ROI_analysis:grid:theFit
									//attempt a fit up to the peak time to get the rise time
									try
										//Takes the fit 30% between 0 and the start tm all the way to the peak time.
										CurveFit/Q/M=2/W=2/X Sigmoid, theWave[ScaleToIndex(theWave,startTm/3,0),peakIndex]/D=root:ROI_analysis:grid:theFit
										AbortOnRTE
									catch
										done = 1
										break
									endtry
																		
									Wave theFit = $("root:ROI_analysis:grid:theFit")
									SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theFit
									FindLevel/Q theFit,0.5*WaveMax(theFit)
									thePkTm = V_LevelX
									KillWaves/Z theFit
									break
							endswitch
						
							If(thePkTm < leftExclude)
								grid[m][n] = 0
							Else					
								grid[m][n] = thePkTm
							EndIf
						EndIf
						testMask[m][n] = 0
						done = 1
					EndIf
					If(done)
						break
					EndIf
				EndFor
				If(done)
					break
				EndIf
			EndFor
			
		EndFor
	EndFor

	grid = (grid == 0) ? nan : grid
	SetScale/P x,DimOffset(gridMask,0),DimDelta(gridMask,0),grid
	SetScale/P y,DimOffset(gridMask,1),DimDelta(gridMask,1),grid
End

Function/WAVE GetOrderFromAngleList(angleList,orderWave[,useBatch])
	String angleList
	Wave orderWave
	Variable useBatch
	Variable batchSize
	
	ControlInfo/W=analysis_tools BatchsizeVar
	batchSize = V_Value
	
	If(batchSize == 0 || batchSize < 0 || batchSize == 1)
		batchSize = ItemsInList(angleList,",")
	EndIf	
	
	If(ParamIsDefault(useBatch))
		useBatch = 0
	EndIf
	
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i
	
	//Get the angle order based on the angle list
	If(useBatch)
		If(strlen(angleList))
			Make/FREE/N=(batchSize) angleListWave
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				angleListWave[i] = str2num(StringFromList(i,angleList,","))
			EndFor
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				FindValue/V=(WaveMin(angleListWave)) angleListWave
				angleListWave[V_Value] = 1000
				orderWave[i] = V_Value
			EndFor
		EndIf
	Else
		If(strlen(angleList))
			Make/FREE/N=(ItemsInList(scanListStr,";")) angleListWave
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				angleListWave[i] = str2num(StringFromList(i,angleList,","))
			EndFor
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				FindValue/V=(WaveMin(angleListWave)) angleListWave
				angleListWave[V_Value] = 1000
				orderWave[i] = V_Value
			EndFor
		EndIf
	EndIf
	return orderWave
End

//Generates tuning curve for selected scans in the selected ROI
Function roiTuningCurve()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd
	
	Variable i,j,k,theArea
	String ROI,dataFolder,scanName,angleList,tuningCurveName
	
	CONTROLINFO/W=analysis_tools angleList
	angleList = S_Value
	
	For (i=0;i<ItemsInList(ROIListStr,";");i+=1)
		ROI = "ROI" + StringFromList(i,ROIListStr,";")
		dataFolder = "root:NEW_ROI_analysis:" + ROI
		
		//Check ROI analysis folder exists
		If(!DataFolderExists(dataFolder))
			print "ROI data folder",dataFolder,"does not exist"
			return -1
		Else
			SetDataFolder $dataFolder
		EndIf
		
		//Check that ROI scan wave exists
		For(j=0;j<ItemsInList(scanListStr,";");j+=1)
				
			//Get the angle ordering
			Make/O/N=(ItemsInList(scanListStr,";")) $(dataFolder + "order")
			Wave order = $(dataFolder + "order")
			If(strlen(angleList))
				GetOrderFromAngleList(angleList,order)
			Else
				order = x
			EndIf
			
			//Get scan name according to the specified angle order
			scanName = StringFromList(order[j],scanListStr,";") + ROI
			
			If(WaveExists($scanName))
				Wave scanWave = $scanName
			Else
				print "Scan wave",scanName,"in folder",dataFolder,"does not exist"
				return -1
			EndIf
			
			//Make output tuning curve wave on first pass
			If(j == 0)
				tuningCurveName = "DStuning_" + scanName
				Make/O/N=(ItemsInList(scanListStr,";")) $tuningCurveName
				Wave tuningCurve = $tuningCurveName
			EndIf

			//Valid range checks
			If(GpeakEnd > DimSize(scanWave,0))
				GpeakEnd = DimSize(scanWave,0) - 1
			EndIf
			
			If(GpeakSt >  DimSize(scanWave,0))
				print "Start point is out of scan wave range"
				return -1
			ElseIf(GpeakSt < 0)
				GpeakSt = 0
			EndIf
			
			//Find integral of the indicated range of the ROI scan wave
			tuningCurve[j] = area(scanWave,pnt2x(scanWave,GpeakSt),pnt2x(scanWave,GpeakEnd))
		EndFor
		
		//Get dimensions for the tuning curve
		Make/FREE/N=(ItemsInList(angleList,",")) angleListWave
		For(k=0;k<ItemsInList(angleList,",");k+=1)
			angleListWave[k] = str2num(StringFromList(k,angleList,","))
		EndFor
		SetScale/I x,WaveMin(angleListWave),WaveMax(angleListWave),tuningCurve
	EndFor
	
End

//Takes input waves and finds the peak, puts results in a single output wave
Function getPeaks()
	//Get wave paths for analysis
	String theWaveList = getWaveNames()
	
	//Variables
	String outWaveName
	Variable xStart,xEnd,baseLineStart,baseLineEnd,numWaves,i

	ControlInfo/W=analysis_tools peakStVar
	xStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	xEnd = V_Value
	ControlInfo/W=analysis_tools bslnStVar
	baseLineStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	baseLineEnd = V_Value
	
	numWaves = ItemsInList(theWaveList,";")
	
	//make output wave
	outWaveName = ParseFilePath(0,StringFromList(0,theWaveList,";"),":",1,0)
	outWaveName = ReplaceString(StringFromList(0,outWaveName,"_"),outWaveName,"Pk")
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName
	
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		outWave[i] = WaveMax(theWave,xStart,xEnd) - mean(theWave,baseLineStart,baseLineEnd)
	EndFor
End

Function getPeakValues()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd
	
	Variable i,j,k,theArea
	String ROI,dataFolder,scanName,angleList,outputWaveName
	
	CONTROLINFO/W=analysis_tools angleList
	angleList = S_Value
	
	For (i=0;i<ItemsInList(ROIListStr,";");i+=1)
		ROI = "ROI" + StringFromList(i,ROIListStr,";")
		dataFolder = "root:ROI_analysis:" + ROI
		
		//Check ROI analysis folder exists
		If(!DataFolderExists(dataFolder))
			print "ROI data folder",dataFolder,"does not exist"
			return -1
		Else
			SetDataFolder $dataFolder
		EndIf
		
		//Check that ROI scan wave exists
		For(j=0;j<ItemsInList(scanListStr,";");j+=1)
			
			//Get scan name for the selected channel
			String suffix
			ControlInfo/W=analysis_tools ratioCheck
			If(V_Value)
				suffix = "_dGR"
			Else
				ControlInfo/W=analysis_tools ch1Check
				If(V_Value)
					suffix = "_dF"
				Else
					ControlInfo/W=analysis_tools ch2Check
					If(V_Value)
						suffix = "_dF"
					EndIf
				EndIf
			EndIf
			string channel = RemoveEnding(getChannel(1),";")
			
			scanName = StringFromList(j,scanListStr,";") + "_" + channel + suffix + "_" + ROI
			
			//Scan exists?
			If(WaveExists($scanName))
				Wave scanWave = $scanName
			Else
				print "Scan wave",scanName,"in folder",dataFolder,"does not exist"
				return -1
			EndIf
			
			//Make output wave on first pass
			If(j == 0)
				outputWaveName = scanName + "_peak"
				Make/O/N=(ItemsInList(scanListStr,";")) $outputWaveName
				Make/O/N=1 $(outputWaveName + "AVG"),$(outputWaveName + "SEM")
				Wave outWave = $outputWaveName
				Wave avgWave = $(outputWaveName + "AVG")
				Wave semWave = $(outputWaveName + "SEM")
			EndIf

			//Valid range checks
			If(GpeakEnd > DimSize(scanWave,0))
				GpeakEnd = DimSize(scanWave,0) - 1
			EndIf
			
			If(GpeakSt >  DimSize(scanWave,0))
				print "Start point is out of scan wave range"
				return -1
			ElseIf(GpeakSt < 0)
				GpeakSt = 0
			EndIf
			
			//Find peak of the indicated range of the ROI scan wave
			outWave[j] = WaveMax(scanWave,GpeakSt,GpeakEnd)
		EndFor
	EndFor
	WaveStats/Q outWave
	avgWave[0] = V_avg
	semWave[0] = V_sem
End



////////////////////////////////////////////////
Function DarkROI(darkValue)
	Variable darkValue

SVAR FirstScanName = root:packages:twoP:examine:curScan
wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
string channel = "ch1"
string ROIname
variable ROIList, run = 0

for (ROIList = 0; ROIList < numpnts(ROIListWave); ROIList+=1)
	ROIname = ROIListWave[ROIList]

	if(cmpstr(ROIname, "Dark")==0)

		wave roiY = root:twoP_ROIS:Dark_y
		wave roiX = root:twoP_ROIS:Dark_x
		wave Matrix = $("root:twoP_Scans:" +FirstScanName + ":" + FirstScanName + "_" + channel)  	

		ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(dimSize(Matrix,0)),height=(dimSize(Matrix,1)),scalingwave=Matrix,seedx=(dimOffset(Matrix,0)+dimDelta(Matrix,0)),seedy=(dimOffset(Matrix,1)+dimDelta(Matrix,1))
		WAVE M_ROIMask	

		ImageStats/R=M_ROIMask Matrix

		darkValue = V_avg
		print darkValue
		run+=1
	else
	endif
endfor

if (run != 1)
	print 	"Dark ROI not found"
endif

end

Function sliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				//Variable curval = sa.curval
				NVAR bkgF = root:bkgF
				CONTROLINFO/W=spot subSlider
				Variable userSubtract = V_value
				CONTROLINFO/W=spot inflSlider
				Variable inflation = V_value
				ValDisplay subDisplay value=_NUM:(-bkgF+userSubtract*bkgF)
				ValDisplay inflDisplay value=_NUM:(inflation*bkgF)
			endif
			break
	endswitch
	return 0
End

Function circleROI(diameter,xInd,yInd)
	Variable diameter,xInd,yInd
	Wave/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	SetDataFolder root:twoP_ROIS
	
	//make into an ROI
	String ROIName = "circle" + num2str(diameter) + "_x"
	Make/O/N=50 $ROIName
	Wave ROIx = $ROIName
	ROIName = "circle" + num2str(diameter) + "_y"
	Make/O/N=50 $ROIName
	Wave ROIy = $ROIName
	String theScanName = StringFromList(0,scanListStr,";")
	Wave theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch1")
	
	//Scale the ROIs correctly
	Variable yPos,xPos,left,right,bottom,top
	xPos = IndexToScale(theScan,xInd,0)
	yPos = IndexToScale(theScan,yInd,1)
	left = xPos - 0.5*diameter*DimDelta(theScan,0)
	right = xPos + 0.5*diameter*DimDelta(theScan,0)
	bottom = yPos - 0.5*diameter*DimDelta(theScan,1)
	top = yPos + 0.5*diameter*DimDelta(theScan,1)
	
	//make the circle
	ROIx = left +  0.5*(right-left) + 0.5*(right-left)*cos(2*pi*x/50)
	ROIy = bottom + 0.5*(top-bottom) + 0.5*(top-bottom)*sin(2*pi*x/50)
	
	Redimension/N=(DimSize(ROIListWave,0) + 1) ROIListWave,ROIListSelWave
	ROIListWave[DimSize(ROIListWave,0) - 1] = "circle" + num2str(diameter)
End


//Makes a grid of square ROIs across an image, only at locations within a defined mask
//or where there is high enough baseline fluorescence (dendrite).
Function gridROI()//theMask,size)
	//Get parameters from the analysis tools window
	ControlInfo/W=analysis_tools gridSizeX
	Variable sizeX = V_Value
	
	ControlInfo/W=analysis_tools gridSizeY
	Variable sizeY = V_Value

	ControlInfo/W=analysis_tools overwriteGrid
	Variable overwrite = V_Value
	
	//Optimize the position of each ROI to maximize pixels with activity.
	ControlInfo/W=analysis_tools optimizePosition
	Variable optimizePos = V_Value
	
	ControlInfo/W=analysis_tools pctOverlap
	Variable overlapPct = V_Value/100
	
	ControlInfo/W=analysis_tools pixelThresholdPct
	Variable thresholdPct = V_Value/100//0% means there is no threshold
	
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	String selectedScanStr = "root:twoP_Scans:" + StringFromList(0,scanListStr,";") + ":" + StringFromList(0,scanListStr,";") + "_ch1"
	
	
	ControlInfo/W=analysis_tools maskListPopUp
	Variable scanPosition = WhichListItem("Scan",S_Value,"_")
	
	If(scanPosition != -1)
		String theScanStr = RemoveEnding(ParseFilePath(1,S_Value,"_",0,scanPosition+2),"_")
		SetDataFolder root:twoP_Scans:$theScanStr
	EndIf
	
	//If there is no mask, make one
	Wave/Z theMask = $S_Value
	If(!WaveExists(theMask))
		Wave theScan = $selectedScanStr
		If(!WaveExists(theScan))
			Abort "Couldn't find the scan wave " + NameOfWave(theScan) + " for masking"
		EndIf
		Checkbox ratioCheck win=analysis_tools,value=0
		Wave theMask =	getDendriticMask(theWave=theScan)
	EndIf
	

	Variable xDim,yDim,remainderX,remainderY,xSteps,ySteps,i,j,avg,count,seedX,seedY,areaAvg
	String ROIName

	Wave/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	
	//Overwrite previous ROI grid?
	If(overwrite)
		deleteGridROI(ROIListWave,ROIListSelWave)
	EndIf
	
	
	Variable endX,endY,startX,startY
	
	xDim = DimSize(theMask,0)
	yDim = DimSize(theMask,1)
	
	xSteps = floor(xDim/sizeX)
	ySteps = floor(yDim/sizeY)
	remainderX = mod(xDim,sizeX)
	remainderY = mod(yDim,sizeY)
	
	Make/FREE/N=(sizeX,sizeY) buffer
	If(!DataFolderExists("root:ROI_analysis"))
		NewDataFolder root:ROI_analysis
	EndIf
	
	If(!DataFolderExists("root:ROI_analysis:grid"))
		NewDataFolder root:ROI_analysis:grid
	EndIf
	Make/O/N=(xSteps,ySteps) root:ROI_analysis:grid:grid_ROIMask
	Wave grid_ROIMask = root:ROI_analysis:grid:grid_ROIMask
	
	Variable gridX,gridY
	
	SetDataFolder root:twoP_ROIS
	count = 0
	gridX = 0
	
	If(optimizePos)
		Make/FREE/N=(xDim,yDim) usedPixels
		Make/FREE/N=(sizeX,sizeY) theArea
		usedPixels = 0
		theArea = 0
	EndIf
	
	i = 0
	j = 0
	
	Do
		gridY = 0
		j = 0
		Do	
			buffer = theMask[p + i][q + j]	//extract the square of data points
			avg = mean(buffer)	//avg is greater than 0 if it contains a non-masked point
			
			If(avg >= thresholdPct)	//% of pixels have values
				grid_ROIMask[gridX][gridY] = 1
				
				Redimension/N=(DimSize(ROIListWave,0) + 1) ROIListWave,ROIListSelWave
				ROIListWave[DimSize(ROIListWave,0) - 1] = "grid" + num2str(count)
				
				//make into an ROI
				ROIName = "grid" + num2str(count) + "_x"
				Make/O/N=5 $ROIName
				Wave ROIx = $ROIName
				ROIName = "grid" + num2str(count) + "_y"
				Make/O/N=5 $ROIName
				Wave ROIy = $ROIName
				
				//Define the ROI coordinates
				If(optimizePos)
					//Optimize the position of each ROI to maximize pixels with activity
					Variable startP,startQ,m,n,optimalP,optimalQ,maxAvg,whichPass
					startP = i - ceil(0.5*sizeX)
					startQ = j - ceil(0.5*sizeY)
					m = 0
					n = 0
					maxAvg = 0
					
					whichPass = 0
					
					//check for valid dimensions
					startP = (startP < 0) ? 0 : startP
					startQ = (startQ < 0) ? 0 : startQ
					
					optimalP = startP
					optimalQ = startQ
					whichPass = 0
					
					//Run optimization loop
					For(m=0;m<sizeX;m+=1)	//m and n count the row and col within optimization 
						If(startP + m > xDim - 1) //can't exceed row dimensions
							continue
						EndIf
						
						For(n=0;n<sizeY;n+=1)
							If(startQ + n > yDim - 1) //can't exceed col dimensions
								continue
							EndIf
							whichPass += 1
							
							buffer = theMask[p + startP + m][q + startQ + n]
							avg = mean(buffer)	//avg is greater than 0 if it contains a non-masked point
							
							//Make sure the area hasn't already been used in another ROI
							theArea = usedPixels[p + startP + m][q + startQ + n]
							areaAvg = mean(theArea)
							
							If(areaAvg > overlapPct)
								continue
							EndIf
							
							If(whichPass == 1) //first valid pass only
								maxAvg = avg
								optimalP = startP + m
								optimalQ = startQ + n
							Else
								//compare this ROI position to the previous best position
								If(avg > maxAvg)
									maxAvg = avg
									optimalP = startP + m
									optimalQ = startQ + n
								EndIf
							EndIf
							
						EndFor
					EndFor
					

						ROIx[0] = IndexToScale(theMask,optimalP,0)
						ROIx[1] = IndexToScale(theMask,optimalP,0)
						ROIx[2] = IndexToScale(theMask,optimalP + sizeX,0)
						ROIx[3] = IndexToScale(theMask,optimalP + sizeX,0)
						ROIx[4] = IndexToScale(theMask,optimalP,0)
						ROIy[0] = IndexToScale(theMask,optimalQ,1)
						ROIy[1] = IndexToScale(theMask,optimalQ + sizeY,1)
						ROIy[2] = IndexToScale(theMask,optimalQ + sizeY,1)
						ROIy[3] = IndexToScale(theMask,optimalQ,1)
						ROIy[4] = IndexToScale(theMask,optimalQ,1)
					
						//Fill in which pixels were occupied by the mask
						usedPixels[optimalP,optimalP+sizeX][optimalQ,optimalQ+sizeY] = 1
			
				Else
					ROIx[0] = IndexToScale(theMask,i,0)
					ROIx[1] = IndexToScale(theMask,i,0)
					ROIx[2] = IndexToScale(theMask,i + sizeX,0)
					ROIx[3] = IndexToScale(theMask,i + sizeX,0)
					ROIx[4] = IndexToScale(theMask,i,0)
					ROIy[0] = IndexToScale(theMask,j,1)
					ROIy[1] = IndexToScale(theMask,j + sizeY,1)
					ROIy[2] = IndexToScale(theMask,j + sizeY,1)
					ROIy[3] = IndexToScale(theMask,j,1)
					ROIy[4] = IndexToScale(theMask,j,1)
				EndIf
					
				count += 1
			Else
				grid_ROIMask[gridX][gridY] = 0
			EndIf
	
			gridY += 1
		
			j += sizeY
		While(j + sizeY < yDim - 1)
		
		gridX += 1
				
		i += sizeX
	While(i + sizeX < xDim - 1)
	
	//Scale the ROI grid mask
	Variable stepScaleX = DimDelta(theMask,0) * sizeX
	Variable stepScaleY = DimDelta(theMask,1) * sizeY
	
	startX = DimOffset(theMask,0) + 0.5*sizeX*DimDelta(theMask,0) 
	endX = startX + (xSteps-1)*stepScaleX
	startY =  DimOffset(theMask,1) + 0.5*sizeY*DimDelta(theMask,1) 
	endY = startY + (ySteps-1)*stepScaleY

	SetScale/I x,startX,endX,grid_ROIMask
	SetScale/I y,startY,endY,grid_ROIMask
	
End

Function similarityIndex()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	If(ItemsInList(scanListStr,";") != 3)
		DoAlert 0,"Need 3 wave: entry, exit, and turn."
		return -1
	EndIf
	
	Wave entry = $("root:ROI_analysis:" + StringFromList(0,scanListStr,";") + "_gridROI_peak")
	Wave exit = $("root:ROI_analysis:" + StringFromList(1,scanListStr,";") + "_gridROI_peak")
	Wave turn = $("root:ROI_analysis:" + StringFromList(2,scanListStr,";") + "_gridROI_peak")
	
	SetDataFolder GetWavesDataFolder(entry,1)
	
	Variable xSize = DimSize(entry,0)
	Variable ySize = DimSize(entry,1)
	
	Make/O/N=(xSize,ySize) sIndex
	Wave sIndex = sIndex
	
	sIndex = ( (entry - turn) - (exit - turn) ) / ( (entry - turn) + (exit - turn) )
	//sIndex = (1 - (abs(entry - turn)/turn)) - (1-(abs(exit - turn)/turn))
End

//Displays ROI scans and arranges them for easy viewing and comparison
Function displayROIs()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	
	String horArrange,vertArrange,ROI,Scan,Path,leftAxis,bottomAxis
	String scanOrderStr,roiOrderStr
	Variable numScans,numROIs,numTraces,horDim,vertDim,horDelta,vertDelta,i,j,count
	Variable maxValue,minValue,startLeft,endLeft,startBottom,endBottom,numHorAxes,numVertAxes
	Variable doAverages
	
	ControlInfo/W=analysis_tools horDisplayArrangementPopUp
	horArrange = S_Value
	ControlInfo/W=analysis_tools vertDisplayArrangementPopUp
	vertArrange = S_Value
	ControlInfo/W=analysis_tools dispAveragesCheck
	doAverages = V_Value
	
	numScans = ItemsInList(scanListStr,";")
	numROIs = ItemsInList(ROIListStr,";")
	numTraces = numScans * numROIs
	
	//Handle the wave ordering
	Variable k
	
	ControlInfo/W=analysis_tools scanOrderROIdisplay
	scanOrderStr = S_Value
	
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderWave
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderIndex = x
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderIndex2 = x
	
	For(k=0;k<ItemsInList(scanOrderStr,",");k+=1)
		scanOrderWave[k] = str2num(StringFromList(k,scanOrderStr,","))
	EndFor
	
	
	If(DimSize(scanOrderWave,0) == 0 || cmpstr(scanOrderStr,"presetAngleWave[0][1]") == 0)
		Redimension/N=(numScans) scanOrderWave,scanOrderIndex
		scanOrderWave = x
		scanOrderIndex = x
	EndIf
	
	//ControlInfo/W=analysis_tools roiOrderROIdisplay
	//roiOrderStr = S_Value
	
	//Make/FREE/N=(ItemsInList(roiOrderStr,",")) roiOrderIndex = x
	//Make/FREE/N=(ItemsInList(roiOrderStr,",")) roiOrderWave

	//For(k=0;k<ItemsInList(roiOrderStr,",");k+=1)
	//	roiOrderWave[k] = str2num(StringFromList(k,roiOrderStr,","))
	//EndFor
	
	SortColumns keyWaves={scanOrderWave},sortWaves={scanOrderIndex}
	//SortColumns keyWaves={roiOrderWave},sortWaves={roiOrderIndex}
	
	//Figure out which dimension is ROI and which is Scan
	strswitch(horArrange)
		case "None":
			numHorAxes = 1
			If(cmpstr(vertArrange,"ROI") == 0)	
				horDim = numScans
			Else
				horDim = numROIs
			EndIf
			break
		case "ROI":
			horDim = numROIs
			numHorAxes = numROIs
			break
		case "Index":
			horDim = numScans
			numHorAxes = numScans
			break
	endswitch
	
	strswitch(vertArrange)
		case "None":
			numVertAxes = 1
			If(cmpstr(horArrange,"Index") == 0)
				vertDim = numROIs
			Else
				vertDim = numScans
			EndIf
			break
		case "ROI":
			vertDim = numROIs
			numVertAxes = numROIs
			break
		case "Index":
			vertDim = numScans
			numVertAxes = numScans
			break
	endswitch
	
	If(cmpstr(horArrange,vertArrange) == 0 && cmpstr(horArrange,"None") != 0)
		DoAlert 0, "Can't use '" + horArrange + "' for both horizontal and vertical dimensions"
		return -1
	EndIf
	
	horDelta = 1/horDim
	vertDelta = 1/vertDim
	
	maxValue = -10
	minValue = 10
	
	count = 0
	
	//Build ROI display
	Display
	
	For(i=0;i<vertDim;i+=1)
		For(j=0;j<horDim;j+=1)
			
			//Get wave names
			If(cmpstr(horArrange,"ROI") == 0)
				ROI = StringFromList(j,ROIListStr,";")
			ElseIf(cmpstr(vertArrange,"ROI") == 0)
				ROI = StringFromList(i,ROIListStr,";")
			Else
				If(cmpstr(horArrange,"Index") == 0)
					ROI = StringFromList(i,ROIListStr,";")
				Else
					//defaults so that ROI is stepped by the horizontal dimension
					ROI = StringFromList(j,ROIListStr,";")
				EndIf
				
			EndIf
			
			If(cmpstr(horArrange,"Index") == 0)
				print pnt2x(scanOrderIndex,j)
				Scan = StringFromList(scanOrderIndex[j],scanListStr,";")
			ElseIf(cmpstr(vertArrange,"Index") == 0)
				Scan = StringFromList(scanOrderIndex[i],scanListStr,";")
			Else
				If(cmpstr(vertArrange,"ROI") == 0)
					Scan = StringFromList(scanOrderIndex[j],scanListStr,";")
				Else
					//defaults so that Scan is stepped by the vertical dimension
					Scan = StringFromList(scanOrderIndex[i],scanListStr,";")
				EndIf
			EndIf
			
			Path = "root:ROI_analysis:ROI" + ROI + ":" + Scan + "_ch2_ROI" + ROI + "_dF"
			//Path = "root:ROI_analysis:ROI" + ROI + ":" + Scan + "_ratio_ROI" + ROI + "_dGR"
			
			If(doAverages)
				Path += "_avg"
			EndIf
			
			Wave theWave = $Path
			
			If(!WaveExists(theWave))
				continue
			EndIf
			
			//Get axes names
			If(cmpstr(vertArrange,"None") == 0)
				leftAxis = "left_0"
				startLeft = 0
				endLeft = 1
			Else
				leftAxis = "left_" + num2str(i)
				startLeft = 1-vertDelta*i - 0.9*vertDelta
				endLeft = 1-vertDelta*i
			EndIf
			
			If(cmpstr(horArrange,"None") == 0)
				bottomAxis = "bottom_0"
				startBottom = 0
				endBottom = 1
			Else
				bottomAxis = "bottom_" + num2str(j)
				startBottom = horDelta*j
				endBottom = horDelta*j + 0.9*horDelta
			EndIf
			
			//Append trace to the graph
			AppendToGraph/L=$leftAxis/B=$bottomAxis theWave
			ModifyGraph axisEnab($bottomAxis)={startBottom,endBottom},freePos($leftAxis)={0,bottom_0},zero($leftAxis)=3,zeroThick($leftAxis)=0.5
			ModifyGraph axisEnab($leftAxis)={startLeft,endLeft},manTick($leftAxis)={0,0.2,0,1},manMinor($leftAxis)={1,0}
			DoUpdate
			
			//Max and min left axis values
			GetAxis/Q $leftAxis
			If(V_max > maxValue)
				maxValue = V_max
			EndIf
			
			If(V_min < minValue)
				minValue = V_min
			EndIf
			count += 1
		EndFor
	EndFor
	
	//Set all left axes to the same max and min
	For(i=0;i<numVertAxes;i+=1)
		leftAxis = "left_" + num2str(i)
		SetAxis $leftAxis,minValue,maxValue
	EndFor
	
	
	//Final modifications
	For(j=0;j<numHorAxes;j+=1)
		bottomAxis = "bottom_" + num2str(j)
		//ModifyGraph freePos($bottomAxis)={0,$("left_" + num2str(numVertAxes - 1))}
		ModifyGraph freePos($bottomAxis)={0,kwFraction}
	EndFor
	
	ModifyGraph margin(left)=28,margin(bottom)=28,margin(right)=7,margin(top)=7,gfSize=8,rgb=(0,0,0),axThick=0.5,standoff=0,btLen=2
End


Window stimPosPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1978,133,2178,843) as "Stimulus Position"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,20,"DIC"
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,220,"twoP"
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,420,"Projector/StimGen"
	CheckBox horizontalFlip,pos={10.00,620.00},size={60.00,16.00},proc=stimPosCheckProc,title=" Horizontal"
	CheckBox horizontalFlip,font="Arial",value= 0
	SetVariable xPos,pos={100.00,610.00},size={60.00,14.00},proc=stimPosVarProc,title="X"
	SetVariable xPos,font="Arial"
	SetVariable xPos,value= root:Packages:twoP:Acquire:positionMarkerX[0]
	SetVariable yPos,pos={100.00,630.00},size={60.00,14.00},proc=stimPosVarProc,title="Y"
	SetVariable yPos,font="Arial"
	SetVariable yPos,value= root:Packages:twoP:Acquire:positionMarkerY[0]
	SetVariable xStagePos,pos={65.00,650.00},size={95.00,14.00},proc=stimPosVarProc,title="Stage X"
	SetVariable xStagePos,font="Arial",value= _NUM:55
	SetVariable yStagePos,pos={65.00,670.00},size={95.00,14.00},proc=stimPosVarProc,title="Stage Y"
	SetVariable yStagePos,font="Arial",value= _NUM:4
	ValDisplay stageOffsetX,pos={65.00,690.00},size={80.00,15.00},title="Offset  X="
	ValDisplay stageOffsetX,font="Arial",fSize=10,frame=0,fStyle=2
	ValDisplay stageOffsetX,valueBackColor=(0,0,0,0),limits={0,0,0},barmisc={0,1000}
	ValDisplay stageOffsetX,value= #"root:Packages:twoP:Acquire:positionMarkerX[0] + root:Packages:twoP:Acquire:stageMarkerX[0]"
	ValDisplay stageOffsetY,pos={145.00,690.00},size={50.00,15.00},title="Y="
	ValDisplay stageOffsetY,font="Arial",fSize=10,frame=0,fStyle=2
	ValDisplay stageOffsetY,valueBackColor=(0,0,0,0),limits={0,0,0},barmisc={0,1000}
	ValDisplay stageOffsetY,value= #"root:Packages:twoP:Acquire:positionMarkerY[0] + root:Packages:twoP:Acquire:stageMarkerY[0]"
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:twoP:Acquire:
	Display/W=(10,20,190,200)/HOST=# /L=VertCrossing/B=HorizCrossing markerX vs markerY
	AppendToGraph/L=VertCrossing/B=HorizCrossing positionMarkerDICY vs positionMarkerDICX
	AppendToGraph/L=VertCrossing/B=HorizCrossing stageMarkerDICX vs stageMarkerDICY
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=5
	ModifyGraph rgb(markerX[0])=(52428,52425,1),rgb(markerX[1])=(16385,28398,65535)
	ModifyGraph rgb(markerX[2])=(65535,0,0),rgb(markerX[3])=(2,39321,1),marker(positionMarkerDICY[0])=8
	ModifyGraph mrkThick(positionMarkerDICY[0])=1
	ModifyGraph standoff=0
	ModifyGraph axThick=0.5
	ModifyGraph btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing}
	ModifyGraph freePos(HorizCrossing)={0,VertCrossing}
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing 250,-250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"90°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"0°"
	RenameWindow #,DIC
	SetActiveSubwindow ##
	String fldrSav1= GetDataFolder(1)
	SetDataFolder root:Packages:twoP:Acquire:
	Display/W=(10,220,190,400)/HOST=# /L=VertCrossing/B=HorizCrossing markerX vs markerY
	AppendToGraph/L=VertCrossing/B=HorizCrossing positionMarkerDICY vs positionMarkerDICX
	AppendToGraph/L=VertCrossing/B=HorizCrossing stageMarkerDICX vs stageMarkerDICY
	SetDataFolder fldrSav1
	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=5
	ModifyGraph rgb(markerX[0])=(52428,52425,1),rgb(markerX[1])=(16385,28398,65535)
	ModifyGraph rgb(markerX[2])=(65535,0,0),rgb(markerX[3])=(2,39321,1),marker(positionMarkerDICY[0])=8
	ModifyGraph mrkThick(positionMarkerDICY[0])=1
	ModifyGraph standoff=0
	ModifyGraph axThick=0.5
	ModifyGraph btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing}
	ModifyGraph freePos(HorizCrossing)={0,VertCrossing}
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing -250,250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"90°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"0°"
	RenameWindow #,twoP
	SetActiveSubwindow ##
	String fldrSav2= GetDataFolder(1)
	SetDataFolder root:Packages:twoP:Acquire:
	Display/W=(10,420,190,600)/HOST=# /L=VertCrossing/B=HorizCrossing markerY vs markerX
	AppendToGraph/L=VertCrossing/B=HorizCrossing positionMarkerY vs positionMarkerX
	AppendToGraph/L=VertCrossing/B=HorizCrossing stageMarkerY vs stageMarkerX
	SetDataFolder fldrSav2
	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=5
	ModifyGraph rgb(markerY[0])=(52428,52425,1),rgb(markerY[1])=(16385,28398,65535)
	ModifyGraph rgb(markerY[2])=(65535,0,0),rgb(markerY[3])=(2,39321,1),marker(positionMarkerY[0])=8
	ModifyGraph mrkThick(positionMarkerY[0])=1
	ModifyGraph standoff=0
	ModifyGraph axThick=0.5
	ModifyGraph btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing}
	ModifyGraph freePos(HorizCrossing)={0,VertCrossing}
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing -250,250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"0°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"90°"
	RenameWindow #,Projector
	SetActiveSubwindow ##
EndMacro

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
//SCAN REGISTER:

//This series of functions allows you to correct images that are out of register (image shearing)
//during bidirectional scanning with 2PLSM. 

//STEP 1: Select image

//Open a new image of the scan you want to correct, and select that graph window from the drop down menu.
//Set the initial parameters for the correction to use:

//Phase (slider): 40-50 degrees
//pixels: 10 or 15 is a good starting point
//divergence: set to 1. If its not working well, set to -1 and try again.
//frequency: 0.5 or 0.6 is good
//Offset: -8 works well

//STEP 2: Select ROIs

//Click 'Auto' allows you to add ROIs (make a marquee box on the image, click the '+' button to add ROI).
//These ROIs will be used for making sure the image is registered correctly. 

//STEP 3: Auto-register image

//Once ROIs are selected, click 'Done'. This will attempt to auto-register the image.

//STEP 4: Optimize correction

//The result probably won't be perfect. An max intensity projection of the uncorrected image will pop up, along with the corrected version. 
//Change the drop down to the uncorrected max intensity projection, then move around the parameters manually to optimize it.
//The corrected image will live update itself as the parameters as adjusted. 

//STEP 5: Save the correction template

//After you're happy with the correction, you can click 'Save' to save the correction template.
//The template now appears in a drop down menu for repeated use on other scans. 

//STEP 6: Apply template to other scans

//To apply the template to other scans, click the 'Use Scan List' check box, allowing you to select scans without opening an image plot.
//Select the channels (1, 2, or both) that you want to correct. 
//Select the template to use.
//Click 'Apply', and the correction will applied to all the scans that you selected in the scan list box.

//IMPORTANT: Applying the correction with the 'Apply' button will overwrite the original scan wave. Only do this if you're absolutely sure about the correction.

Function AT_InitializeScanRegister()
	//NewPanel/K=2/W=(100,100,300,330)/N=ScanRegistry as "Register Scan"
	PopUpMenu SR_waveList win=analysis_tools,pos={35,60},bodywidth=200,size={200,20},title = " ",value=WinList("*",";","WIN:1"),proc=AT_ScanRegistryPopUpProc,disable=0 //WaveList("*",";","DIMS:2")
	//SetVariable SR_phase win=ScanRegistry,live=1,pos={20,25},size={60,20},title="Phase",value=_NUM:0,proc=ScanRegistryVarProc
	Slider SR_phase win=analysis_tools,live=1,pos={50,80},size={150,20},value=50,limits={0,360,1},title="Phase",vert=0,proc=AT_ScanRegistrySliderProc
	CheckBox SR_phaseLock win=analysis_tools,pos={34,78},title="",value=0
	SetVariable SR_phaseVal win=analysis_tools,pos={210,80},size={40,20},title=" ",live=1,frame=0,value=_NUM:AT_GetSliderValue()
	CheckBox SR_pixelDeltaLock win=analysis_tools,pos={34,127},title="",value=0
	SetVariable SR_pixelDelta win=analysis_tools,pos={50,129},size={60,20},limits={-inf,inf,0.5},title="Pixels",value=_NUM:10,proc=AT_ScanRegistryVarProc
	CheckBox SR_divergenceLock win=analysis_tools,pos={34,150},title="",value=1
	SetVariable SR_divergence win=analysis_tools,pos={50,152},size={90,20},limits={-1,1,2},title="Divergence",value=_NUM:1,proc=AT_ScanRegistryVarProc
	CheckBox SR_frequencyLock win=analysis_tools,pos={34,173},title="",value=0
	SetVariable SR_frequency win=analysis_tools,pos={50,175},size={90,20},limits={0,inf,0.01},title="Frequency",value=_NUM:0.6,proc=AT_ScanRegistryVarProc
	CheckBox SR_pixelOffsetLock win=analysis_tools,pos={34,197},title="",value=0
	SetVariable SR_pixelOffset win=analysis_tools,pos={50,199},size={90,20},limits={-inf,inf,1},title="Offset",value=_NUM:-8,proc=AT_ScanRegistryVarProc
	Button SR_autoRegisterButton win=analysis_tools,pos={145,180},size={60,20},title="Auto",proc=AT_ScanRegistryButtonProc
	Button SR_addROIButton win=analysis_tools,pos={204,287},size={20,20},title="+",fColor=(3,52428,1),disable=1,proc=AT_ScanRegistryButtonProc
	Button SR_reset win=analysis_tools,pos={145,160},size={60,20},title="Reset",proc=AT_ScanRegistryButtonProc
	Button SR_showROIButton win=analysis_tools,pos={145,140},size={60,20},title="ROIs",proc=AT_ScanRegistryButtonProc
	//Button SR_quitButton win=analysis_tools,pos={145,60},size={60,20},title="Quit", fColor=(65535,0,0),proc=ScanRegistryButtonProc
	Button SR_saveTemplateButton win=analysis_tools,pos={145,200},size={60,20},title="Save",proc=AT_ScanRegistryButtonProc
	Button SR_applyTemplate win=analysis_tools,pos={176,224},size={50,20},title="Apply",proc=AT_ScanRegistryButtonProc
	
	String/G root:var:templateList
	SVAR templateList = root:var:templateList
	templateList = GetTemplateList()
	PopUpMenu SR_templatePopUp win=analysis_tools,pos={34,225},size={100,20},title="Templates",value=#"root:var:templateList",proc=AT_ScanRegistryPopUpProc
	CheckBox SR_UseAnalysisToolsCheck win=analysis_tools,pos={34,245},size={40,20},title="Use Scan List"
	
	//Wave to hold ROI coordinates for automatic registry
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	Make/O/N=(4,1) root:var:roiCoord = 0
	String/G root:var:roiXlist,root:var:roiYlist
	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	roiXlist = ""
	roiYlist = ""
	Variable/G root:var:hidden = 0
End

Function/S GetTemplateList()
	String cdf
	
	cdf = GetDataFolder(1)
	If(!DataFolderExists("root:Packages:twoP:Scan_Register_Templates"))
		NewDataFolder root:Packages:twoP:Scan_Register_Templates
	EndIf
	SetDataFolder root:Packages:twoP:Scan_Register_Templates
	
	String templateList = WaveList("template*",";","DIMS:2")
	If(!strlen(templateList))
		templateList = "None"
	EndIf
	
	SetDataFolder cdf
	return templateList
	
End

Function/WAVE CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
	Wave scanWave
	Variable pixelOffset,pixelDelta,phase,frequency,divergence
	//divergence is 1 if even columns shift positively and odd columns shift negatively
	//divergence is -1 if even columns shift negatively and odd columns shift positively
	
	Variable xDelta,yDelta,xOffset,yOffset,xSize,ySize,i
	
	xDelta = DimDelta(scanWave,0)
	xOffset = DimOffset(scanWave,0)
	xSize = DimSize(scanWave,0)
	yDelta = DimDelta(scanWave,1)
	yOffset = DimOffset(scanWave,1)
	ySize = DimSize(scanWave,1)
	
	//abort if no scanwave is found
	If(numtype(xDelta) == 2)
		abort
	EndIf
	
	//Make template wave for register adjustment
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	Make/O/N=(xSize,ySize) root:var:template
	Wave template = root:var:template
	template = 0
	
	//Creates the sine wave for the image correction. The second equation works much better when the constant pixel offset
	For(i=0;i<ySize;i+=1)
		If(mod(i,2) == 0)
			//template = 0.5*pixelDelta + 0.5*pixelDelta*sin((1/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
	//		template[][i] =  divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
			template[][i] = pixelOffset + divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
		Else
			//template[][i] = pixelOffset - divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
		EndIf
	EndFor
	
	
	//Make source grid with the images original scaling
	Make/O/D/N=(xSize,ySize) root:var:xs
	Make/O/D/N=(xSize,ySize) root:var:ys
	Wave xs = root:var:xs
	Wave ys = root:var:ys
	
	xs = p*xSize/(xSize)
	ys = q*ySize/(ySize)
	
	//Make destination grid, which is warped according to template sine wave
	Make/O/D/N=(xSize,ySize) root:var:xd
	Make/O/D/N=(xSize,ySize) root:var:yd
	Wave xd =  root:var:xd
	Wave yd =  root:var:yd
	
	xd = xs + template
	yd = ys //+ template
	
	//xs=p*imagerows/(gridRows-1)
	//ys=q*imageCols/(gridCols-1)
	//ImageInterpolate/RESL={4500,4500}/TRNS={radialPoly,1,0,0,0} Resample scanWave
	ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp scanWave
	
	Wave correctedImage = M_InterpolatedImage	
	return correctedImage
End

Function AT_AutoRegister(imageWave,windowName)
	Wave imageWave
	String windowName

	
	Variable error,rows,cols,left,right,top,bottom,i,j,k,m,numROIs,count,endPt
	
	Wave coordinates = root:var:roiCoord
	
	Variable timeRef = StartMSTimer
	
	numROIs = DimSize(coordinates,1)
	
	//errorWave keeps track of error minimization
	Make/O/N=1000 root:var:errorWave
	Wave errorWave = root:var:errorWave
	errorWave = 0
	
	//Original values for the image correction
	Variable pixelOffset,pixelDelta,phase,frequency,divergence
	Variable finalPixelOffset,finalPixelDelta,finalPhase,finalFrequency,finalDivergence
	
	//Some defaults initial values that are probably close to the right answer
	ControlInfo/W=analysis_tools SR_pixelDelta
	pixelDelta = V_Value
	
	ControlInfo/W=analysis_tools SR_pixelOffset
	pixelOffset = V_Value
				
	ControlInfo/W=analysis_tools SR_frequency
	frequency = V_Value
	
	ControlInfo/W=analysis_tools SR_phase
	phase = V_Value*pi/180
		
	ControlInfo/W=analysis_tools SR_divergence
	divergence = V_Value	
	//pixelOffset = -8
	//pixelDelta = 0
	//phase = 45*pi/180
	//frequency = 0.6
	//divergence = -1
	
	//Is this an image stack?
	If(DimSize(imageWave,2) > 0)
		MatrixOP/O/S maxProj = sumBeams(imageWave)
		Wave maxProj = maxProj
		SetScale/P x,DimOffset(imageWave,0),DimDelta(imageWave,0),maxProj
		SetScale/P y,DimOffset(imageWave,1),DimDelta(imageWave,1),maxProj
		Wave imagewave = maxProj
		NewImage imageWave
	EndIf
	
	Wave correctedImage = imageWave	
	
	//Get ROI coordinates in index
	Duplicate/O coordinates,root:var:roiCoordScale
	Wave coordinates_Scale = root:var:roiCoordScale
	Redimension/N=(6,-1) coordinates_Scale
	
	For(i=0;i<numROIs;i+=1)
		coordinates_Scale[0][i] = ScaleToIndex(imageWave,coordinates_Scale[0][i],0)//left
		coordinates_Scale[1][i] = ScaleToIndex(imageWave,coordinates_Scale[1][i],1)//top
		coordinates_Scale[2][i] = ScaleToIndex(imageWave,coordinates_Scale[2][i],0)//right
		coordinates_Scale[3][i] = ScaleToIndex(imageWave,coordinates_Scale[3][i],1)//bottom
		coordinates_Scale[4][i] = 	abs(coordinates_Scale[2][i] - coordinates_Scale[0][i])//rows
		
		If(stringmatch(windowName,"twoPscanGraph*"))
			coordinates_Scale[5][i] = 	abs(coordinates_Scale[1][i] - coordinates_Scale[3][i]) //cols
		Else
			coordinates_Scale[5][i] = 	abs(coordinates_Scale[3][i] - coordinates_Scale[1][i])//cols
		EndIf
		
		String dataName,peakName
		dataName = "data_" + num2str(i)
		peakName = "peaks_" + num2str(i)
	
		If(stringmatch(windowName,"twoPscanGraph*"))
			Make/O/N=(coordinates_Scale[4][i],coordinates_Scale[5][i]) $dataName = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
		Else
			Make/O/N=(coordinates_Scale[4][i],coordinates_Scale[5][i]) $dataName = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
		EndIf
		
		Make/O/N=(coordinates_Scale[5][i]) $peakName
	EndFor
	
	For(m=0;m<4;m+=1)
		count = 0
		
		If(m == 0)
			//pixel delta
			Redimension/N=50 errorWave
			endPt = 50
			ControlInfo/W=analysis_tools SR_pixelDeltaLock
			If(V_Value)
				continue
			Else
				pixelDelta = 0
			EndIf
		ElseIf(m == 1)
			//frequency
			Redimension/N=50 errorWave
			endPt = 50
		
			ControlInfo/W=analysis_tools SR_frequencyLock
			If(V_Value)
				continue
			Else
				frequency = 0.3	
			EndIf
		ElseIf(m == 2)	
			//pixel offset
			Redimension/N=60 errorWave
			endpt = 60
			ControlInfo/W=analysis_tools SR_pixelOffsetLock
			If(V_Value)
				continue
			Else
				pixelOffset = -15
			EndIf
		ElseIf(m == 3)
			//phase
			Redimension/N=100 errorWave
			endPt = 100
			ControlInfo/W=analysis_tools SR_phaseLock
			If(V_Value)
				continue
			Else
				phase = 0
			EndIf
		EndIf
		
		For(k=0;k<endPt;k+=1)
			//error will accumulate over each ROI, then the program will adjust parameters
			//in an attempt to find the parameters that minimize error. 
			error = 0
			For(i=0;i<numROIs;i+=1)
				//Get the updated ROI data
				dataName = "data_" + num2str(i)
				peakName = "peaks_" + num2str(i)
				Wave data = $dataName
				Wave peaks = $peakName
				
				If(stringmatch(windowName,"twoPscanGraph*"))
					data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
				Else
					data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
				EndIf
				//We'll be registering left/right shifts, so stepping through columns
				
				//Find peak intensity in each row of each ROI, calculate positional differences in peaks across rows.
				For(j=0;j<coordinates_Scale[5][i];j+=1)
					MatrixOP/O/FREE colData = col(data,j)
					WaveStats/Q colData
					peaks[j] = V_maxloc
					
					If(j > 0)
						error += abs(peaks[j-1] - peaks[j])
					EndIf
				EndFor
	
			EndFor
		
			errorWave[count] = error
			count += 1
		
	
			//update variables to new values
			If(m == 0)
				pixelDelta += 1
			ElseIf(m == 1)
				frequency += 0.01
			ElseIf(m == 2)
				pixelOffset += 0.5
			ElseIf(m == 3)
				phase += 1*pi/180
			EndIf
			
			Wave correctedImage = CorrectScanRegister(imageWave,pixelOffset,pixelDelta,phase,frequency,divergence)
		
		EndFor
		
		//Set the parameter to its minimum error value
		If(m == 0)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			pixelDelta = V_minloc
		ElseIf(m == 1)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			frequency = 0.3 + V_minloc*0.01
		ElseIf(m == 2)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			pixelOffset = -15 + V_minloc*0.5
		ElseIf(m == 3)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			phase = (V_minloc)*pi/180
		EndIf
		//Reset errorWave
		errorWave = 0
	EndFor	
	
	//Final correction with minimum parameter error values
	Wave correctedImage = CorrectScanRegister(imageWave,pixelOffset,pixelDelta,phase,frequency,divergence)
	
	error = 0
	//Kill ROI data waves
	For(i=0;i<numROIs;i+=1)
		dataName = "data_" + num2str(i)
		peakName = "peaks_" + num2str(i)
		Wave data = $dataName
		Wave peaks = $peakName
		
		If(stringmatch(windowName,"twoPscanGraph*"))
			data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
		Else
			data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
		EndIf	
		//We'll be registering left/right shifts, so stepping through columns
				
		//Get final error value from optimized parameters
		For(j=0;j<coordinates_Scale[5][i];j+=1)
			MatrixOP/O/FREE colData = col(data,j)
			WaveStats/Q colData
			peaks[j] = V_maxloc
					
			If(j > 0)
				error += abs(peaks[j-1] - peaks[j])
			EndIf
		EndFor
		
		KillWaves/Z data,peaks
	EndFor
	
	print "------------"
	print "Image registration: " + NameOfWave(imageWave)
	SetVariable SR_pixelOffset win=analysis_tools,value=_NUM:pixelOffset
	print "Pixel Offset = ",pixelOffset
	SetVariable SR_pixelDelta win=analysis_tools,value=_NUM:pixelDelta
	print "Pixel Delta = ",pixelDelta
	SetVariable SR_frequency win=analysis_tools,value=_NUM:frequency
	print "Frequency = ",frequency
	Slider SR_phase win=analysis_tools,value=phase*180/pi
	SetVariable SR_phaseVal win=analysis_tools,value=_NUM:AT_GetSliderValue()
	print "Phase = ",phase*180/pi
	print "Error = ",error
	AT_SR_Message(5)
	Variable totalTime = StopMSTimer(timeRef)
	print "Time = ", totalTime/1000000," s"
	NewImage correctedImage
End

Function AT_ScanRegistryVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			ControlInfo/W=analysis_tools SR_waveList
			String imageName = ImageNameList(S_Value,";")
			imageName = StringFromList(0,imageName,";")
			Wave scanWave = ImageNameToWaveRef(S_Value,imageName)
			
			Variable phase,pixelOffset,pixelDelta,divergence,frequency
			ControlInfo/W=analysis_tools SR_phase
			phase = V_Value*pi/180
			ControlInfo/W=analysis_tools SR_pixelDelta
			pixelDelta = V_Value
			ControlInfo/W=analysis_tools SR_divergence
			divergence = V_Value
			ControlInfo/W=analysis_tools SR_frequency
			frequency = V_Value
			Controlinfo/W=analysis_tools SR_pixelOffset
			pixelOffset = V_Value
			
			CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AT_GetSliderValue()
	Variable sliderVal
	ControlInfo/W=analysis_tools SR_phase
	sliderVal = V_Value
	return sliderVal
End

Function AT_ScanRegistrySliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				SetVariable SR_phaseVal win=analysis_tools,value=_NUM:curval
				
				ControlInfo/W=analysis_tools SR_waveList
				String imageName = ImageNameList(S_Value,";")
				imageName = StringFromList(0,imageName,";")
				Wave scanWave = ImageNameToWaveRef(S_Value,imageName)
		
			
				Variable phase,pixelOffset,pixelDelta,divergence,frequency
				phase = curval*pi/180
				ControlInfo/W=analysis_tools SR_pixelDelta
				pixelDelta = V_Value
				ControlInfo/W=analysis_tools SR_divergence
				divergence = V_Value
				ControlInfo/W=analysis_tools SR_frequency
				frequency = V_Value
				Controlinfo/W=analysis_tools SR_pixelOffset
				pixelOffset = V_Value
				CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
			endif
			break
	endswitch

	return 0
End

Function AT_ScanRegistryButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	String windowName,errStr
	Wave coordinates = root:var:roiCoord
	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	NVAR hidden = root:var:hidden
	Variable i,j,k
	String roiNameY,roiNameX
	
	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlName)
				case "SR_autoRegisterButton":
					ControlInfo/W=analysis_tools SR_autoRegisterButton
					String info = StringByKey("title",S_recreation,"=",",")
			
					If(strlen(info) > 10)
						info = info[0,10]
					EndIf
			
					If(StringMatch(info,"*Auto*"))
						errStr = AT_SetupROICapture()
						If(cmpstr(errStr,"-1") == 0)
							return -1
						Else
							ControlInfo/W=analysis_tools SR_waveList
							windowName = S_Value 
						EndIf
				
						Button SR_autoRegisterButton win=analysis_tools,title="Done",fColor=(65535,32764,16385)
						Button SR_addROIButton win=analysis_tools,disable=0
					//	Button SR_saveWaveformButton win=ScanRegistry,disable = 1
					//	Button SR_applyTemplate win=ScanRegistry, disable = 1
						AT_SR_Message(1)
						//Make text message to select ROIs for registry alignment. 
						//
					ElseIf(StringMatch(info,"*Done*"))
						Button SR_autoRegisterButton win=analysis_tools,title="Auto",fColor=(0,0,0)
						Button SR_addROIButton win=analysis_tools,disable=1
						//Trim ROI coordinates wave of its extra column
						Wave coordinates = root:var:roiCoord
						Variable size = DimSize(coordinates,1)
						
						MatrixOP/O/FREE result = sum(col(coordinates,size-1))
						
						If(result[0] == 0)
							Redimension/N=(-1,size - 1) coordinates
						EndIf
						AT_SR_Message(2)
						
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value
					
						
						String imageWaveName = AT_SetupROICapture()
						String channel = RemoveEnding(getChannel(1),";")
							
						If(cmpstr(windowName,"twoPscanGraph") == 0)
							
							If(cmpstr(channel,"ch1") == 0)
								windowName += "#GCH1"	
							ElseIf(cmpstr(channel,"ch2") == 0)
								windowName += "#GCH2"	
							EndIf
							
							Wave imageWave = $imageWaveName
						Else
							Wave imageWave = ImageNameToWaveRef(windowName,imageWaveName)
						EndIf
						
						//Register image
						AT_AutoRegister(imageWave,windowName)
					//	Button SR_saveWaveformButton win=ScanRegistry,disable = 0
					//	Button SR_applyTemplate win=ScanRegistry, disable = 0
					EndIf
					
					break
				case "SR_addROIButton":
					errStr = AT_SetupROICapture()
					If(cmpstr(errStr,"-1") == 0)
						return -1
					Else
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value 
					EndIf
					Wave coordinates = root:var:roiCoord
					//Add column to coordinate wave to hold next ROI
					Redimension/N=(-1,DimSize(coordinates,1) + 1) coordinates
					SR_addROI(windowName)
					break
				case "SR_reset":
					//Erases ROI lists
					For(i=0;i<ItemsInList(roiYlist,";");i+=1)
						roiNameY = StringFromList(i,roiYlist,";")
						roiNameX = StringFromList(i,roiXlist,";")
						RemoveFromGraph/Z $roiNameY
						KillWaves/Z $("root:var:" + roiNameY)
						KillWaves/Z $("root:var:" + roiNameX)
					EndFor
					
					roiXlist = ""
					roiYlist = ""
					
					//Resets to zero selected ROIs
					Redimension/N=(4,1) coordinates
					coordinates = 0
					
					//Resets button titles
					Button SR_autoRegisterButton win=analysis_tools,title="Auto",fColor=(0,0,0)
					Button SR_addROIButton win=analysis_tools,disable=1
				//	Button SR_saveWaveformButton win=ScanRegistry,disable = 0
				//	Button SR_applyTemplate win=ScanRegistry, disable = 0
					AT_SR_Message(5)
					break
				case "SR_showROIButton":
		
					errStr = AT_SetupROICapture()
					If(cmpstr(errStr,"-1") == 0)
						return -1
					Else
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value 
					EndIf
					
					If(hidden)
						ModifyGraph/W=$windowName hideTrace = 0
						hidden = 0
					Else	
						ModifyGraph/W=$windowName hideTrace = 1
						hidden = 1
					EndIf
					break
				case "SR_saveTemplateButton":
					//Saves the template waveform so it can be reapplied to other images

					If(!DataFolderExists("root:Packages:twoP:Scan_Register_Templates"))
						NewDataFolder root:Packages:twoP:Scan_Register_Templates
					EndIf
					SetDataFolder root:Packages:twoP:Scan_Register_Templates
					String templateName = UniqueName("template",1,0)
					Wave template = root:var:template
					Duplicate/O template,$templateName
					
										
					SVAR templateList = root:var:templateList
					templateList = GetTemplateList()
					PopUpMenu SR_templatePopUp win=analysis_tools,value=#"root:var:templateList"
					break
				case "SR_applyTemplate":
					
					ControlInfo/W=analysis_tools SR_templatePopUp
					wave template = $("root:Packages:twoP:Scan_Register_Templates:" + S_Value)
					
					ControlInfo/W=analysis_tools SR_UseAnalysisToolsCheck
					Variable useAnalysisTools = V_Value
					Variable loops,numChannels
					numChannels = 0
					If(UseAnalysisTools)
						SVAR scanListStr = root:Packages:twoP:examine:scanListStr
						loops = ItemsInList(scanListStr,";")
						ControlInfo/W=analysis_tools ch1Check
						numChannels = V_Value
						Variable theChannel = 1
						ControlInfo/W=analysis_tools ch2Check
						numChannels += V_Value
						If(V_Value)
							theChannel = 2 
						EndIf
					Else
						loops = 1
						numChannels = 1
					EndIf
					
					
					For(k=0;k<numChannels;k+=1)
						For(j=0;j<loops;j+=1)
							If(UseAnalysisTools)
								If(numChannels == 1)
									imageWaveName = StringFromList(j,scanListStr,";") + "_ch" + num2str(theChannel)
								Else
									imageWaveName = StringFromList(j,scanListStr,";") + "_ch" + num2str(k+1)
								EndIf
								
								SetDataFolder $("root:twoP_Scans:" + StringFromList(j,scanListStr,";"))
								Wave imageWave = $imageWaveName
							Else
								errStr = AT_SetupROICapture()
								If(cmpstr(errStr,"-1") == 0)
									return -1
								Else
									ControlInfo/W=analysis_tools SR_waveList
									windowName = S_Value 
								EndIf
					
								imageWaveName = AT_SetupROICapture()
								Wave imageWave = ImageNameToWaveRef(windowName,imageWaveName)						
							EndIf
							
							//If(DimSize(imageWave,2) > 0)
							//	Variable wholeStack
							//	DoAlert/T="Scan Register" 2,"Register entire stack?"
							//EndIf
							V_flag = 1
					
							Variable xDelta,yDelta,xOffset,yOffset,xSize,ySize
	
							xDelta = DimDelta(imageWave,0)
							xOffset = DimOffset(imageWave,0)
							xSize = DimSize(imageWave,0)
							yDelta = DimDelta(imageWave,1)
							yOffset = DimOffset(imageWave,1)
							ySize = DimSize(imageWave,1)
	
							Make/O/D/N=(xSize,ySize) root:var:xs
							Make/O/D/N=(xSize,ySize) root:var:ys
							Wave xs = root:var:xs
							Wave ys = root:var:ys
	
							xs = p*xSize/(xSize)
							ys = q*ySize/(ySize)
	
							//Make destination grid, which is warped according to template sine wave
							Make/O/D/N=(xSize,ySize) root:var:xd
							Make/O/D/N=(xSize,ySize) root:var:yd
							Wave xd =  root:var:xd
							Wave yd =  root:var:yd
		
							xd = xs + template
							yd = ys //+ template
					
							If(V_flag == 1)//whole stack registry
								//Makes wave to hold each layer of the stack
								Duplicate/O/FREE imageWave,theLayer
								Redimension/N=(-1,-1,0) theLayer
						
								//New name for the output wave; 'reg' stands for registered.
								//Duplicate/O imageWave,$(NameOfWave(imageWave) + "_reg")
								Wave correctedImage = imageWave //$(NameOfWave(imageWave) + "_reg")
						
								For(i=0;i<DimSize(imageWave,2);i+=1)
									theLayer[][] = imageWave[p][q][i]
									ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp theLayer
									Wave correctedLayer = M_InterpolatedImage
									correctedImage[][][i] = correctedLayer[p][q]
								EndFor
						
							ElseIf(V_flag == 2)//top layer registry
								ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp theLayer
								Wave correctedImage = M_InterpolatedImage	
							Else
								return -1
							EndIf
							
						EndFor
					EndFor
	
					break
			
			endswitch
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AT_SR_Message(code)
	Variable code
	String message
	
	DrawAction/W=analysis_tools delete
	
	switch(code)
		case 1:
			message = "Select ROIs using the marquee tool"
			break
		case 2:
			message = "Registering image"
			DrawAction/W=analysis_tools delete
			break
		case 3:
			message = "More than 1 image on the graph"
			break
		case 4:
			message = "Image wave cannot be found"
			break
		case 5:
			message = ""
			break
	endswitch
	
	SetDrawEnv/W=analysis_tools fsize=10,fstyle=(2^1),textxjust=0
	DrawText/W=analysis_tools 33,304,message
	
End

Function AT_ScanRegistryPopUpProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			strswitch(pa.ctrlName)
				case "SR_waveList":
					Variable popNum = pa.popNum
					String popStr = pa.popStr
					DoWindow/F $popStr
					String imageList = ImageNameList(popStr,";")
					
					If(strlen(imageList) != 0)
						Wave theImage = ImageNameToWaveRef(popStr,StringFromList(0,ImageNameList(popStr,";")))
					Else
						print "No images on graph"
						return -1
					EndIf
					
					SetDataFolder GetWavesDataFolder(theImage,1)
					break
				case "SR_templatePopUp":	
			
					SVAR templateList = root:var:templateList
					templateList = GetTemplateList()
					PopUpMenu SR_templatePopUp win=analysis_tools,value=#"root:var:templateList"
			
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function/S SR_addROI(theWindow)
	String theWindow

	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	
	If(!WaveExists(root:var:roiCoord))
		Make/N=(4,1) root:var:roiCoord
	EndIf
	
	Wave coordinates = root:var:roiCoord
	Variable numROIs = DimSize(coordinates,1) - 1
	
	String channel = RemoveEnding(getChannel(1),";")
	
	//Get coordinates of the marquee
	If(cmpstr(theWindow,"twoPscanGraph") == 0)
		Variable isScanGraph = 1
		If(cmpstr(channel,"ch1") == 0)
			theWindow += "#GCH1"
		ElseIf(cmpstr(channel,"ch2") == 0)
			theWindow += "#GCH2"
		EndIf
		GetMarquee/K/W=$theWindow/Z left,bottom
	Else
		GetMarquee/K/W=$theWindow/Z left,top
	EndIf
	
	coordinates[0][numROIs - 1] = V_left
	coordinates[1][numROIs - 1] = V_top
	coordinates[2][numROIs - 1] = V_right
	coordinates[3][numROIs - 1] = V_bottom
	
	String roiNameX = "ROIx_" + num2str(ItemsInList(roiXlist,";") + 1)
	roiXlist += roiNameX + ";"
	String roiNameY = "ROIy_" + num2str(ItemsInList(roiYlist,";") + 1)
	roiYlist += roiNameY + ";"
	
	Make/O/N=5 $("root:var:" + roiNameX) = {V_left,V_right,V_right,V_left,V_left}
	Wave roiXwave = $("root:var:" + roiNameX)
	Make/O/N=5 $("root:var:" + roiNameY) = {V_bottom,V_bottom,V_top,V_top,V_bottom}
	Wave roiYwave = $("root:var:" + roiNameY)
	
	If(isScanGraph)
		AppendToGraph/W=$theWindow/L/B roiYwave vs roiXwave
	Else
		AppendToGraph/W=$theWindow/L/T roiYwave vs roiXwave
	EndIf
	ModifyGraph/W=$theWindow rgb=(0,65535,65535)
End

Function/S AT_SetupROICapture()
	String imageName
	String errStr
	
	//Get the image window
	ControlInfo/W=analysis_tools SR_waveList
	DoWindow/F $S_Value
	
	String channel = RemoveEnding(getChannel(1),";")
	
	//If its the twoP Scan Graph
	If(cmpstr("twoPscanGraph",S_Value) == 0)
		If(cmpstr(channel,"ch1") == 0)
			S_Value = S_Value + "#GCH1"
		ElseIf(cmpstr(channel,"ch2") == 0)	
			S_Value = S_Value + "#GCH2"
		EndIf
		
		SVAR curScan = root:Packages:twoP:examine:curScan
		imageName = "root:twoP_Scans:" + curScan + ":" + curScan + "_" + channel
		Wave theImage = $imageName
	Else			
				
		//More than one image in graph?
		imageName = ImageNameList(S_Value,";")
		If(ItemsInList(imageName,";") > 1)
			AT_SR_Message(3)
			errStr = "-1"
		EndIf
		
		imageName = StringFromList(0,imageName,";")
		Wave theImage = ImageNameToWaveRef(S_Value,imageName)	
	EndIf
				
	//Image wave exists?
	If(!WaveExists(theImage))
		AT_SR_Message(4)
		errStr = "-1"
		return errStr	
	EndIf
				
	//Does image graph window exist?
	If(!V_flag)
		NewImage theImage
	EndIf	

	return imageName
End



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

//Averages the waves in the list
Function/S avgSelectedWaves(selWaveList,avgORerr)
	String selWaveList
	Variable avgORerr	//0 for avg, 1 for sem, 2 for both
	Variable numItems,i
	String avgWaveName,errWaveName
	
	//Use clipboard waves?
	NVAR useClipboard = root:Packages:MBr:useClipboard
	Wave/T clipboardListWave = root:Packages:MBr:clipboardListWave
	
	If(DimSize(clipboardListWave,0) == 1 && strlen(clipboardListWave[0]) == 0)
		useClipboard = 0
	EndIf
	
	If(useClipboard)
		selWaveList = ""
		For(i=0;i<DimSize(clipboardListWave,0);i+=1)
			selWaveList += clipboardListWave[i] + ";"
		EndFor
	EndIf
	
	numItems = ItemsInList(selWaveList,";")
	SetDataFolder GetWavesDataFolder($StringFromList(0,selWaveList,";"),1)
	
	ControlInfo/W=analysis_tools outputSuffix
	String suffix = S_Value
	
	ControlInfo/W=analysis_tools useDataSetCheck
	Variable useDS = V_Value
	
	If(strlen(suffix))
		If(avgORerr == 1)
			avgWaveName = "avgWave"
			errWaveName = StringFromList(0,selWaveList,";") + "_" + suffix
		Else
			avgWaveName = StringFromList(0,selWaveList,";") + "_" + suffix
			errWaveName = StringFromList(0,selWaveList,";") + "_" + suffix
		EndIf
	Else
		If(avgORerr == 1)
			avgWaveName = "avgWave"
			errWaveName = StringFromList(0,selWaveList,";") + "_sem"
		Else
			avgWaveName = StringFromList(0,selWaveList,";") + "_avg"
			errWaveName = StringFromList(0,selWaveList,";") + "_sem"
		EndIf
	EndIf
	
	//Check wave name length
	String shortName = ParseFilePath(0,avgWaveName,":",1,0)
	If(strlen(shortName) > 31)
		avgWaveName = ParseFilePath(1,avgWaveName,":",1,0) + shortName[0,30]
	EndIf
	
	shortName = ParseFilePath(0,errWaveName,":",1,0)
	If(strlen(shortName) > 31)
		errWaveName = ParseFilePath(1,errWaveName,":",1,0) + shortName[0,30]
	EndIf
	
	
	If(DimSize($StringFromList(0,selWaveList,";"),2) > 0)
	//3D
		Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0),DimSize($StringFromList(0,selWaveList,";"),1),DimSize($StringFromList(0,selWaveList,";"),2)) $avgWaveName
		
		If(avgORerr == 1 || avgORerr == 2)
			Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0),DimSize($StringFromList(0,selWaveList,";"),1),DimSize($StringFromList(0,selWaveList,";"),2)) $errWaveName
		EndIf
		
		Wave/Z avgWave = $avgWaveName
		Wave/Z errWave = $errWaveName
		
		SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),avgWave
		SetScale/P y,DimOffset($StringFromList(0,selWaveList,";"),1),DimDelta($StringFromList(0,selWaveList,";"),1),avgWave
		SetScale/P z,DimOffset($StringFromList(0,selWaveList,";"),2),DimDelta($StringFromList(0,selWaveList,";"),2),avgWave

		If(avgORerr == 1 || avgORerr == 2)
			SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),errWave
			SetScale/P y,DimOffset($StringFromList(0,selWaveList,";"),1),DimDelta($StringFromList(0,selWaveList,";"),1),errWave
			SetScale/P z,DimOffset($StringFromList(0,selWaveList,";"),2),DimDelta($StringFromList(0,selWaveList,";"),2),errWave
		EndIf
	ElseIf(DimSize($StringFromList(0,selWaveList,";"),1) > 0)
	//2D
		Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0),DimSize($StringFromList(0,selWaveList,";"),1)) $avgWaveName
		If(avgORerr == 1 || avgORerr == 2)
			Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0),DimSize($StringFromList(0,selWaveList,";"),1)) $errWaveName
		EndIf
		
		Wave/Z avgWave = $avgWaveName
		Wave/Z errWave = $errWaveName
		
		SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),avgWave
		SetScale/P y,DimOffset($StringFromList(0,selWaveList,";"),1),DimDelta($StringFromList(0,selWaveList,";"),1),avgWave
		
		If(avgORerr == 1 || avgORerr == 2)
			SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),errWave
			SetScale/P y,DimOffset($StringFromList(0,selWaveList,";"),1),DimDelta($StringFromList(0,selWaveList,";"),1),errWave
		EndIf
	Else
	//1D
		Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0)) $avgWaveName
		If(avgORerr == 1 || avgORerr == 2)
			Make/O/N=(DimSize($StringFromList(0,selWaveList,";"),0)) $errWaveName
		EndIf
		
		Wave/Z avgWave = $avgWaveName
		Wave/Z errWave = $errWaveName
		
		SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),avgWave
		
		If(avgORerr == 1 || avgORerr == 2)
			SetScale/P x,DimOffset($StringFromList(0,selWaveList,";"),0),DimDelta($StringFromList(0,selWaveList,";"),0),errWave
		EndIf
	EndIf
	
	//AVG calculation
	avgWave = 0

	Note/K avgWave,num2str(numItems) + " Waves Averaged:"
	For(i=0;i<numItems;i+=1)
		Wave currentWave = $StringFromList(i,selWaveList,";")
		avgWave += currentWave
		Note avgWave,NameOfWave(currentWave)
	EndFor
	avgWave /= numItems	
	
	//SEM calculation
	If(avgORerr == 1 || avgORerr == 2)
		errWave = 0
		Note/K errWave,num2str(numItems) + " Waves included:"
		For(i=0;i<numItems;i+=1)
			Wave currentWave = $StringFromList(i,selWaveList,";")
			errWave += (currentWave - avgWave)^2
			Note errWave,NameOfWave(currentWave)
		EndFor
		
		errWave = (sqrt(errWave / (numItems -1)))/sqrt(numItems)
	EndIf
	
	If(avgORerr == 1)
		KillWaves/Z avgWave
	EndIf
End

//Checks string length is less than 32 characters
Function CheckLongName(theString)
	String theString
	Variable length = strlen(theString)
	
	If(length > 31)
		return 1
	Else
		return 0
	EndIf
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

//Gets full path of the selected items in the ItemListBox
Function/S getSelectedItems()
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	WAVE/T/Z listWave = root:Packages:MBr:waveListTable
	WAVE/Z selWave = root:Packages:MBr:selWave
	Variable i
	
	selWaveList = ""

	For(i=0;i<DimSize(listWave,0);i+=1)
		If(selWave[i] == 1)
			selWaveList += cdf + listWave[i] + ";"
		EndIf
	EndFor
	
	return selWaveList
End

//Routes to using scan list or item list or data sets for wave selection.
Function/S getWaveNames()
	SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
	NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
	NVAR wsn = root:Packages:analysisTools:DataSets:wsn
	Variable i
	
	ControlInfo/W=analysis_tools extFuncDS
	String theWaveList = ""
	
	strswitch(S_Value)
		case "--None--":
			break
		case "--Scan List--":
			ControlInfo/W=analysis_tools extFuncChannelPop
			theWaveList = getScanListItems(V_Value)
			break
		case "--Item List--":
			theWaveList = getSelectedItems()
			break
		default:
			Wave/T ds = GetDataSetWave(dsName=S_Value)
			Variable pos = tableMatch("*WSN " + num2str(wsn) + "*",ds) + 1//first wave of the waveset
			Variable endpos = pos + str2num(StringFromList(wsn,wsDims,";")) //Last wave of the waveset
			For(i=pos;i<endpos;i+=1)
				theWaveList += ds[i] + ";"
			EndFor
			break
	endswitch
	return theWaveList
End

//Gets the full path wave list of the selected scans from scanList
Function/S getScanListItems(channel)
	Variable channel
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable i,size
	String dataFolder,chStr,theWaveList=""
	
	dataFolder = "root:twoP_Scans:"
	size = ItemsInList(scanListStr,";")
	
	If(channel == 1)
		chStr = "ch1"
	Else
		chStr = "ch2"
	EndIf
	
	For(i=0;i<size;i+=1)
		theWaveList += dataFolder + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_" + chStr + ";"
	EndFor
	theWaveList = RemoveEnding(theWaveList,";")
	return theWaveList
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

Function AppendDSWaveToViewer(selWave,itemList,dsWave,[fullPathList])
	Wave selWave
	String itemList
	Wave/T dsWave
	Variable fullPathList
	Variable i,j,type
	String dsWaveList = ""
	
	If(ParamIsDefault(fullPathList))
		fullPathList = 0
	EndIf
	
	
	Wave/Z/T folderTable = root:Packages:MBr:folderTable
	Wave selFolderWave = root:Packages:analysisTools:selFolderWave
	SVAR cdf = root:Packages:MBr:currentDataFolder
	String fullPath = ""
	Variable count = 0
	//If length of dsWave and selWave don't match, assume it need
	//to use the matchList from selected folders
	If(DimSize(selWave,0) != DimSize(dsWave,0))
		If(DimSize(folderTable,0) > 0)
			For(i=0;i<DimSize(folderTable,0);i+=1)
				String previousPath = ""
				If(selFolderWave[i] == 1)
					For(j=count;j<ItemsInList(itemList,";");j+=1)
						//Is the name of the next possible wave the same as the previously selected wave?
						If(cmpstr(StringFromList(j,itemList,";"),previousPath) == 0)
							continue
						EndIf
						String possiblePath = cdf + folderTable[i] + ":" + StringFromList(j,itemList,";")
						If(WaveExists($possiblePath))	//is the wave in this folder?
							fullPath += possiblePath + ";"
							previousPath = StringFromList(j,itemList,";")
							count+=1
						EndIf
					EndFor
				//fullPath +=  cdf + folderTable[i] + ":" + listWave[count] + ";"
				//count += 1
				EndIf
			EndFor
		Else
			previousPath = ""
			For(j=0;j<ItemsInList(itemList,";");j+=1)
				fullPath += cdf + StringFromList(j,itemList,";") + ";"
			EndFor
		EndIf
		
		dsWaveList = fullPath
		ElseIf(fullPathList)
			dsWaveList = itemList
		Else
			//Get the full path of the selected waves
			For(j=0;j<DimSize(selWave,0);j+=1)
				If(selWave[j] == 1)
					dsWaveList += dsWave[j] + ";"
				EndIf
			EndFor
	EndIf
	
	DoWindow/W=analysis_tools#atViewerGraph atViewerGraph
	
	//Does the window exist?
	
	If(V_flag)
		String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
		String traceCheck = traceList
		
		For(i=0;i<ItemsInList(itemList,";");i+=1)
			//Is it a numeric wave?
			String trace = StringFromList(i,itemList,";")		
				
			type = WaveType($StringFromList(i,dsWaveList,";"),1)
			If(type == 1)
				//Is it already on the graph?
				Variable isOnGraph = WhichListItem(trace,traceList,";")
				If(isOnGraph == -1)
				
					AppendToGraph/W=analysis_tools#atViewerGraph $StringFromList(i,dsWaveList,";")
				Else
					traceCheck = RemoveListItem(i,traceCheck,";")
					traceCheck = AddListItem("0",traceCheck,";",i)
				EndIf
			EndIf
		EndFor
		
		For(i=0;i<ItemsInList(traceCheck,";");i+=1)
			If(cmpstr(StringFromList(i,traceCheck,";"),"0") != 0)
				RemoveFromGraph/W=analysis_tools#atViewerGraph $StringFromList(i,traceCheck,";")
			EndIf
		EndFor
		
	EndIf
End

//If str matches an entry in the tableWave, returns the row, otherwise return -1
Function tableMatch(str,tableWave,[startp,endp])
	String str
	Wave/T tableWave
	Variable startp,endp//for range
	Variable i,size = DimSize(tableWave,0)
	
	If(ParamIsDefault(startp))
		startp = 0
	EndIf
	
	If(ParamIsDefault(endp))
		endp = size - 1
	EndIf
	
	For(i=startp;i<endp+1;i+=1)
		If(stringmatch(tableWave[i],str))
			return i
		EndIf
	EndFor
	
	return -1
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

Function/S ResolveErrorCode(cmdStr)
	String cmdStr
	
	String errorCode = StringByKey("error",cmdStr,":")
	//Possible error codes
	strswitch(errorCode)
		case "dim2":
			beep
			print "Expected at least a 2D wave"
			break
		case "dim3":
			beep
			print "Expected a 3D wave"
			break
		default:
			print "Unhandled error. Check code."
			break
	endswitch
	
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

Function/S ResolveCtabStr(ctabStr,theWave)
	String ctabStr
	Wave theWave
	String leftCstr,rightCstr
	Variable leftC,rightC
	
	If(!strlen(ctabStr))
		ctabStr = "error:ctab"
		return ctabStr
	EndIf
	
	ctabStr = ReplaceString("{",ctabStr,"")
	ctabStr = ReplaceString("}",ctabStr,"")
	
	leftCstr = StringFromList(0,ctabStr,",")
	rightCstr = StringFromList(1,ctabStr,",")
	
	//autoscale tests
	If(cmpstr(leftCstr,"*") == 0)
		leftC = WaveMin(theWave)
	Else
		leftC = str2num(leftCstr)
	EndIf
	
	If(cmpstr(rightCstr,"*") == 0)
		rightC = WaveMax(theWave)
	Else
		rightC = str2num(rightCStr)
	EndIf
	
	ctabStr = ReplaceString(leftCstr,ctabStr,num2str(leftC),0,1)
	ctabStr = ReplaceString(rightCstr,ctabStr,num2str(rightC),0,1)
	return ctabStr
End

Function/WAVE getDendriticMask([theWave,noBuffer])
	Wave theWave
	Variable noBuffer
	If(ParamIsDefault(noBuffer))
		noBuffer = 0 
	EndIf

	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	SVAR whichList = root:Packages:analysisTools:whichList
	Variable m,k,f,numScans,numChannels
	
	If(ParamIsDefault(theWave))
		If(cmpstr(whichList,"AT") == 0)
			String channel = getChannel(1)
			numChannels = ItemsInList(channel,";")
			numScans = ItemsInList(scanListStr,";")
		Else
			numChannels = 1
			numScans = ItemsInList(selWaveList,";")
		EndIf
	Else
		numScans = 1
		channel = getChannel(1)
		numChannels = ItemsInList(channel,";")
	EndIf
	
	For(k=0;k<numScans;k+=1)
		If(ParamIsDefault(theWave))
			If(cmpstr(whichList,"AT") == 0)
				String dataFolder = "root:twoP_Scans:" + StringFromList(k,scanListStr,";")
			ElseIf(cmpstr(whichList,"Browser") == 0)
				dataFolder = cdf
			EndIf
		Else
			dataFolder = GetWavesDataFolder(theWave,1)
		EndIf
		
		For(m=0;m<numChannels;m+=1)
			
			If(ParamIsDefault(theWave))
				If(cmpstr(whichList,"AT") == 0)
					String theChannel = StringFromList(m,channel,";")
					String scanPath = dataFolder + ":" + StringFromList(k,scanListStr,";") + "_" + theChannel
				Else
					scanPath = dataFolder + StringFromList(k,selWaveList,";")
				EndIf
			
				//Can we find the wave?
				If(DataFolderExists(dataFolder))
					SetDataFolder $dataFolder
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
			
				If(WaveExists($scanPath))
					Wave theWave = $scanPath
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
			
			EndIf
			
			//custom wave definition
			//Wave theWave = root:twoP_Scans:Scan_048:Scan_048_ch2
			
			
			//Variable declarations
			Variable minVal,maxVal,threshold,i,j,rows,cols,frames,maskThresh,mask3D
		
			ControlInfo/W=analysis_tools maskThreshold
			maskThresh = V_Value
			
			ControlInfo/W=analysis_tools mask3DCheck
			mask3D = V_Value
			
			rows = DimSize(theWave,0)
			cols = DimSize(theWave,1)
			
			If(mask3D)
				frames = DimSize(theWave,2)
			EndIf
			
			//Get max projection image
			MatrixOP/S/O maxProj = sumBeams(theWave)
			
			//Min value needs to be found without considering the edges, since they may have been buffered with zeros
			//for image registration purposes
			
			If(noBuffer)
				ImageStats maxProj
			Else
				ImageStats/G={20,DimSize(maxProj,0)-20,20,DimSize(maxProj,1)-20} maxProj
			EndIf
				
			minVal = V_min
			//minVal = WaveMin(maxProj)
			
			maxVal = WaveMax(maxProj)
			threshold = minVal + (maxVal - minVal)*maskThresh
		
			//Simple value thresholding
			maxProj = (maxProj < threshold) ? 0 : maxProj
	
			//Eliminate isolated points
			Make/FREE/N=(5,5) block
			block = 0
			
			If(mask3D)
			//3D masking
				Duplicate/FREE theWave,maskWave3D
				For(f=0;f<frames;f+=1)
				
					ImageStats/P=(f) maskWave3D
					threshold = V_avg + 2*V_sdev
					//make sub-threshold values zero
					maskWave3D = (maskWave3D < threshold) ? 0 : maskWave3D
					print f,"/",frames
					For(i=0;i<rows;i+=1)	
						For(j=0;j<cols;j+=1)	
							
							//check for image edges
							If(i-2 < 0 || i+2 > rows-2 || j-2 < 0 || j+2 > cols-2)
								continue
							Else
								//Get data block surrounding point
								block = maskWave3D[i-2 + p][j-2 + q][f]
								
								//Check for isolated points, set the to zero
								If(sum(block) < 3*maskWave3D[i][j][f])
									maskWave3D[i][j][f] = 0
								EndIf	
							EndIf
							
							block = 0
						EndFor
					EndFor
				EndFor
				//3D median filter 3x3
				ImageFilter/N=3 median maskWave3D
			
				//Create mask wave
				String maskName = NameOfWave(theWave) + "_mask3D"
				If(strlen(maskName) > 31)
					maskName = "Scan_mask3D"
				EndIf
			Else
			
			//2D masking
				For(i=0;i<rows;i+=1)	
					For(j=0;j<cols;j+=1)
						//skip zeros
						If(maxProj[i][j] == 0)
							continue
						EndIf			
				
						//check for image edges
						If(i-2 < 0 || i+2 > rows-2 || j-2 < 0 || j+2 > cols-2)
							continue
						Else
							//Get data block surrounding point
							block = maxProj[i-2 + p][j-2 + q]
							
							//Check for isolated point
							If(sum(block) < 3*maxProj[i][j])
								maxProj[i][j] = 0
							EndIf	
						EndIf
					
						block = 0
					EndFor
				EndFor
				//2D median filter 3x3
				MatrixFilter/N=3 median maxProj
				
				//Create mask wave
				maskName = NameOfWave(theWave) + "_mask"
				If(strlen(maskName) > 31)
					maskName = "Scan_mask"
				EndIf
			EndIf
	
		
			
			//Set non-zero values to 1
			If(mask3D)
				Make/O/N=(rows,cols,frames) $maskName
				Wave theMask = $maskName
				theMask = (maskWave3D == 0) ? 0 : 1
				//Scaling
				SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theMask
				SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theMask
				SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),theMask
			Else
				Make/O/N=(rows,cols) $maskName
				Wave theMask = $maskName
				theMask = (maxProj == 0) ? 0 : 1
				//Scaling
				SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theMask
				SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theMask
			EndIf
	
			ControlInfo/W=analysis_tools AT_CommandPop
			If(cmpstr(S_Value,"Get Dendritic Mask") == 0)
				print "Created dendritic mask of wave: " + scanPath
			EndIf
			
		EndFor
	EndFor
	
	return theMask
End


Function/S GetMaskWaveList()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	String maskList,folderPath,masksInCurrentFolder
	Variable numFolders,i,checkAllFolders,j
	Make/T/O/N=0 root:Packages:analysisTools:maskTable
	Wave/T maskTable = root:Packages:analysisTools:maskTable
	
	//Find mask waves in all scan folders?
	ControlInfo/W=analysis_tools maskAllFoldersCheck
	checkAllFolders = V_Value
	
	If(checkAllFolders)
		If(DataFolderExists("root:twoP_Scans"))
			DFREF scanPath = root:twoP_Scans
			numFolders = CountObjects("root:twoP_Scans",4)
		Else
			numFolders = 1
		EndIf
	Else
		numFolders = 1
	EndIf
	
	maskList = ""
	masksInCurrentFolder = ""
	
	For(i=0;i<numFolders;i+=1)
		If(checkAllFolders)
			folderPath = "root:twoP_Scans:" + GetIndexedObjNameDFR(scanPath,4,i)
		Else
			folderPath = "root:twoP_Scans:" + StringFromList(i,scanListStr,";")
		EndIf
		
		If(DataFolderExists(folderPath))
			SetDataFolder $folderPath
			maskList += WaveList("*mask*",";","")
			masksInCurrentFolder = WaveList("*mask*",";","")
			For(j=0;j<ItemsInList(masksInCurrentFolder,";");j+=1)
				Redimension/N=(DimSize(maskTable,0) + 1) maskTable	//add a row for new entry
				maskTable[DimSize(maskTable,0)-1] += folderPath + ":" + StringFromList(j,masksInCurrentFolder,";")
			EndFor
		Else
			maskList += ""
		EndIf
	EndFor
	
	return maskList
End

Function maskScanData()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	String dataFolder = "root:twoP_Scans:" + StringFromList(0,scanListStr,";")
	Variable numChannels,i
	String scanPath = ""
	
	numChannels = 0
	
	ControlInfo/W=analysis_tools ch1Check
	If(V_Value)
		numChannels = 1
		scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch1"
	EndIf
	
	ControlInfo/W=analysis_tools ch2Check
	If(V_Value)
		numChannels += 1
	EndIf
	
	If(numChannels == 0)
		Abort "Must select a channel"
	EndIf
	
	print "-------"
	
	//Loop through channels
	For(i=0;i<numChannels;i+=1)
		//If scanPath isn't assigned and we haven't aborted yet, it must be ch2
		If(!strlen(scanPath) || i > 0)
			scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch2"
		EndIf

		//Can we find the wave?
		If(DataFolderExists(dataFolder))
			SetDataFolder $dataFolder
		Else
			Abort "Couldn't find the wave: " + scanPath
		EndIf
	
		If(WaveExists($scanPath))
			Wave theWave = $scanPath
		Else
			Abort "Couldn't find the wave: " + scanPath
		EndIf
	
		ControlInfo/W=analysis_tools maskListPopUp
		Wave theMask = $S_Value
		
		//Make wave to hold the masked scan
		String maskedScanName = NameOfWave(theWave) + "_msk"
		Duplicate/O theWave,$maskedScanName
		Wave maskedScan = $maskedScanName
		
		maskedScan = theWave[p][q][r] * theMask[p][q][0]
		
		print "Scan " + scanPath + " has been masked using " + S_Value
	EndFor
End

Function maxLayer(theWave)
	wave theWave
	variable i,j
	
	Duplicate/O theWave,ratioPk
	wave ratioPk = ratioPk
	Redimension/N=(-1,-1,0) ratioPk
	
	For(i=0;i<DimSize(theWave,0);i+=1)	
		For(j=0;j<DimSize(theWave,1);j+=1)
			MatrixOP/FREE/O theBeam = Beam(theWave,i,j)
			Smooth/S=2 13, theBeam
			ratioPk[i][j] = WaveMax(theBeam,round(0.3*DimSize(theWave,2)),round(0.6*DimSize(theWave,2)))
		EndFor
	EndFor
End


Function dfMapSimple()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	SVAR selWaveList = root:Packages:MBr:selWaveList
	
	Variable numChannels,i,j,k,m,b,c,frames,rows,cols
	String scanPath = ""
	String dFWaveName
	String dataFolder = "root:twoP_Scans:" + StringFromList(0,scanListStr,";")
	Wave/T maskTable = root:Packages:analysisTools:maskTable
	
	SetDataFolder root:twoP_Scans
	DFREF twoPScans = GetDataFolderDFR()
	
	Variable timerRef = StartMSTimer
	
	numChannels = 0
	
	ControlInfo/W=analysis_tools ch1Check
	If(V_Value)
		numChannels = 1
		scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch1"
	EndIf
	
	ControlInfo/W=analysis_tools ch2Check
	If(V_Value)
		numChannels += 1
	EndIf
	
	ControlInfo/W=analysis_tools ratioCheck
	Variable doRatio = V_Value
	
	If(cmpstr(whichList,"AT") == 0) //only need channel selection if we're in scan mode (AT)
		If(numChannels == 0 && doRatio != 1)
			Abort "Must select a channel"
		EndIf
	ElseIf(cmpstr(whichList,"Browser") == 0)
		scanPath = cdf + StringFromList(0,selWaveList,";")
		dataFolder = cdf
		numChannels = 1
	EndIf
	
	If(doRatio)
		numChannels = 1
	EndIf
	
	print "-------"
		
	//Get the range for finding the peak dF
	Variable startTm,endTm,bslnStartTm,bslnEndTm
	ControlInfo/W=analysis_tools peakStVar
	startTm = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	endTm = V_Value

	ControlInfo/W=analysis_tools bslnStVar
	bslnStartTm = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	bslnEndTm = V_Value
	
	ControlInfo/W=analysis_tools spatialFilterCheck
	Variable spatialFilter = V_Value
	
	//Loop through channels
	For(c=0;i<numChannels;c+=1)
	
		If(doRatio)
		
		//////// ∆G/R MAPPING //////////////////////////
		
			//Green channel scan wave
			scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch1"

			//Can we find the wave?
			If(DataFolderExists(dataFolder))
				SetDataFolder $dataFolder
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf
	
			If(WaveExists($scanPath))
				Wave ch1Wave = $scanPath
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf
			
			//Red channel scan wave
			scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch2"

			//Can we find the wave?
			If(DataFolderExists(dataFolder))
				SetDataFolder $dataFolder
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf
	
			If(WaveExists($scanPath))
				Wave ch2Wave = $scanPath
				Wave ch2Wave_alternate = $scanPath
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf
			
			//Wave dimensions
			rows = DimSize(ch1Wave,0)
			cols = DimSize(ch1Wave,1)
			frames = DimSize(ch1Wave,2)
					
			//Cleans up some of the instrument noise that is plaguing these dF maps. 
			ControlInfo/W=analysis_tools cleanUpNoise
			Variable cleanNoise = V_Value
			
			ControlInfo/W=analysis_tools cleanUpNoiseThresh
			Variable cleanNoiseThresh = V_Value
			
			If(cleanNoise)
				Wave theWave = CleanUpNoise(ch1Wave,cleanNoiseThresh)	//threshold is in sdevs above the mean
				Wave ch2Wave = CleanUpNoise(ch2Wave_alternate,cleanNoiseThresh)
			EndIf
			
			
			//Variance Map?
			ControlInfo/W=analysis_tools varianceMapCheck
			If(V_Value)	
				MakeVarMap(theWave)
			EndIf
			
			//Get mask wave
			ControlInfo/W=analysis_tools maskAllFoldersCheck
			Variable checkAllFolders = V_Value
			ControlInfo/W=analysis_tools maskListPopUp	
	
			If(checkAllFolders)
			//	String folderPath = "root:twoP_Scans:" + GetIndexedObjNameDFR(twoPScans,4,V_Value) + ":"
				Wave theMask = $maskTable[V_Value-1]
			Else
				Wave theMask = $S_Value
			EndIf
			
			If(!WaveExists(theMask))
				Abort "Cannot find the mask wave"
			EndIf
			
			Duplicate/FREE theMask,darkMask
			Redimension/B/U darkMask
			
			//Get red channel baseline, spatial filter and temporal smooth it.
			Duplicate/FREE/O ch2Wave,redBaselineMat
			
			//Filter the red baseline the same as the
			// green channel will be filtered
			MatrixOP/O redBaseline = sumBeams(redBaselineMat)/frames
			MatrixFilter/N=3 median redBaseline
						
			//Set scales for red baseline
			SetScale/P x,DimOffset(ch2Wave,0),DimDelta(ch2Wave,0),redBaseline
			SetScale/P y,DimOffset(ch2Wave,1),DimDelta(ch2Wave,1),redBaseline
			
			//Find average dark value for red channel
			ImageStats/R=darkMask redBaseline //gets dark value from the first frame of all non-masked pixels
			Variable darkValue = 0.9*V_avg //estimate dark value slightly low to avoid it accidentally surpassing the dendrite baseline fluorescence.
			
			//Make time-varying dG/R Map Wave
			dFWaveName = NameOfWave(ch1Wave) + "_dGR"
			Duplicate/O ch1Wave,$dFWaveName
			Wave dFWave = $dFWaveName
			
			Redimension/S/N=(rows,cols,frames) dFWave
			dFWave = 0
			
			//Operate on temporary wave so raw data is never altered.
			Duplicate/FREE/O theWave,temp
			
			//Spatial filter for each layer of the green channel.
			
			If(spatialFilter)
				If(spatialFilter < 3)
					DoAlert 0,"Spatial filter must be 3 or greater."
					break
				EndIf

				For(k=0;k<frames;k+=1)
					MatrixOP/O/FREE theLayer = layer(temp,k)
					MatrixFilter/N=(spatialFilter) median theLayer
					temp[][][k] = theLayer[p][q][0]
				EndFor
			EndIf
				
			//Remove laser response loop for green channel
			ControlInfo/W=analysis_tools RemoveLaserResponseCheck
			Variable RemoveLaserResponse = V_Value

			For(i=0;i<rows;i+=1)
				For(j=0;j<cols;j+=1)
					If(darkMask[i][j] != 1)
						continue
					EndIf
					MatrixOP/FREE/O/S theBeam = Beam(temp,i,j)
					SetScale/P x,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),theBeam
					
					//Remove laser response from dF matrix wave for better baselining
					If(RemoveLaserResponse)
						Variable estimatePeakTm = 0.5*(endTm + startTm)
						FlattenLaserResponse(theBeam,0,bslnEndTm,1,estimatePeakTm)
					EndIf
					
					temp[i][j][] = theBeam[r]
				EndFor	
			EndFor	
			
			//Get green channel baseline fluorescence map
			Make/FREE/O/N=(rows,cols) greenBaseline
			
			Variable startLayer,endLayer
			startLayer = ScaleToIndex(ch1Wave,bslnStartTm,2)
			endLayer = ScaleToIndex(ch1Wave,bslnEndTm,2)
			
			For(i=startLayer;i<endLayer;i+=1)
				MatrixOP/FREE/O theLayer = layer(temp,i)
				greenBaseline += theLayer
			EndFor
			greenBaseline /= (endLayer - startLayer)
			

			//Eliminates the possibility of zero values in the dataset for dendrites in the mask, which all get converted to NaN at the end.
			temp = (temp[p][q][r] == greenBaseline[p][q][0]) ? temp[p][q][r] + 1 : temp[p][q][r]
			
			//Calculate ∆G/R time-varying map
			ControlInfo/W=analysis_tools doDarkSubtract
			If(V_Value)
				dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / (redBaseline[p][q][0] - darkValue)
			Else
				dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / redBaseline[p][q][0]
			EndIf
					
			//Make peak ∆G/R and peak-time map waves
			String dFPeakWaveName = dFWaveName + "_peak"
			Make/O/N=(rows,cols) $dFPeakWaveName,$(dFPeakWaveName + "Loc")
			Wave dFPeakWave = $dFPeakWaveName
			Wave dFPeakLoc = $(dFPeakWaveName + "Loc")
			dFPeakWave = gnoise(0.001)	
			dFPeakLoc = 0
			
			//Temporal smoothing of the dF map prior to finding the peaks.
			ControlInfo/W=analysis_tools SmoothBox
			Variable didSmooth = V_Value
			
			If(didSmooth)
				ControlInfo/W=analysis_tools SmoothFilterVar
				Variable smoothVar = V_Value
				Smooth/S=2/DIM=2 smoothVar,dFWave
			EndIf
			
			//Getting the peak ∆G/R and its time point from a beam 
			For(i=0;i<rows;i+=1)
				For(j=0;j<cols;j+=1)
					//only operates if the data is within the mask region to save time.
					If(darkMask[i][j] != 1)
						continue
					EndIf
					
					MatrixOP/FREE/O theBeam = Beam(dFWave,i,j)
					SetScale/P x,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),theBeam
					WaveStats/Q/R=(startTm,endTm) theBeam
					
					dFPeakLoc[i][j] = V_MaxRowLoc
					//averages 0.1 sec before and after the peak to get the final ∆G/R peak value
					dFPeakWave[i][j] = mean(theBeam,V_maxloc - 0.1,V_maxloc + 0.1)
				EndFor
			EndFor
			
			//Clip the edges of the image with a mask, to remove the projector artifact
			//theMask[0,10][] = 0
			//theMask[rows-11,rows-1][] = 0
			
			//Clip unreasonably high values
			//dFWave  = (dFWave > 100) ? 0 : dFWave
			//dFWave = (dFWave < 0) ? 0 : dFWave
			
			//Set scales
			SetScale/P x,DimOffset(ch1Wave,0),DimDelta(ch1Wave,0),dFPeakWave,dFPeakLoc,dFWave
			SetScale/P y,DimOffset(ch1Wave,1),DimDelta(ch1Wave,1),dFPeakWave,dFPeakLoc,dFWave
			SetScale/P z,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),dFWave
						
		Else
		
		//////// ∆F/F MAPPING //////////////////////////
		
			//If scanPath isn't assigned and we haven't aborted yet, it must be ch2
			If(!strlen(scanPath) || c > 0)
				scanPath = dataFolder + ":" + StringFromList(0,scanListStr,";") + "_ch2"
			EndIf

			//Can we find the wave?
			If(DataFolderExists(dataFolder))
				SetDataFolder $dataFolder
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf
	
			If(WaveExists($scanPath))
				Wave theWave = $scanPath
			Else
				Abort "Couldn't find the wave: " + scanPath
			EndIf


		//	Wave theWave = root:twoP_Scans:ds2008df4lp3l20_004:Scan_004_ch2_avg
		//	Wave theWave = root:twoP_Scans:TTXds2008df4lp3l20_028:Scan_028_ch2_avg
			
			
			String theWaveName = NameOfWave(theWave)
			
			//Make the input scan 32 bit float, instead of unsigned 16 bit integer
			Duplicate/FREE theWave,theWave32bit
			Wave theWave = theWave32bit
			Redimension/S theWave
			
			//Wave dimensions
			frames = DimSize(theWave,2)
			rows = DimSize(theWave,0)
			cols = DimSize(theWave,1)
		
			
			//Cleans up some of the instrument noise that is plaguing these dF maps. 
			ControlInfo/W=analysis_tools cleanUpNoise
			cleanNoise = V_Value
			
			ControlInfo/W=analysis_tools cleanUpNoiseThresh
			cleanNoiseThresh = V_Value
			
			
			If(cleanNoise)
				Wave theWave = CleanUpNoise($theWaveName,cleanNoiseThresh)	//threshold is in sdevs above the mean
				Redimension/S theWave
			EndIf
						
			//theWave = (theWave > 50) ? mean(theWave) : theWave
					
			//convolution ROI wave
			//Wave conv = root:ROI_analysis:convolution

			
			//Variance Map?
			ControlInfo/W=analysis_tools varianceMapCheck
			If(V_Value)	
				MakeVarMap(theWave)
			EndIf
			
			//Get mask wave
			ControlInfo/W=analysis_tools maskAllFoldersCheck
			checkAllFolders = V_Value
			ControlInfo/W=analysis_tools maskListPopUp	
			
			Variable scanPosition = WhichListItem("Scan",S_Value,"_")
			String theScanStr = RemoveEnding(ParseFilePath(1,S_Value,"_",0,scanPosition+2),"_")
			
			DFREF theScanPath = root:twoP_Scans
			
			If(checkAllFolders)
				//folderPath = "root:twoP_Scans:" + theScanStr + ":"
				Wave theMask = $maskTable[V_Value-1]
			Else
				Wave theMask = $S_Value
			EndIf
			
			If(!WaveExists(theMask))
				Abort "Cannot find the mask wave"
			EndIf
			
			Duplicate/FREE theMask,darkMask
			Redimension/B/U darkMask
		
			//Find average dark value
			ImageStats/R=darkMask/P=1 theWave
			darkValue = 0.9*V_avg  //estimate dark value slightly low to avoid it accidentally surpassing the dendrite baseline fluorescence.
			
			//Make time-varying dF Map wave
			dFWaveName = theWaveName + "_dF"
			Duplicate/O theWave,$dFWaveName
			Wave dFWave = $dFWaveName
		
			Redimension/S/N=(rows,cols,frames) dFWave
			dFWave = 0	
			
			//Operate on temporary wave so raw data is never altered.
			Duplicate/FREE/O theWave,temp
			
			//Spatial filter for each layer of the wave.
			If(spatialFilter)
				If(spatialFilter < 3)
					DoAlert 0,"Spatial filter must be 3 or greater."
					break
				EndIf

				For(k=0;k<frames;k+=1)
					MatrixOP/O/FREE theLayer = layer(temp,k)
					MatrixFilter/N=(spatialFilter) median theLayer
					temp[][][k] = theLayer[p][q][0]
				EndFor
			EndIf
			
		//	Duplicate/O/FREE temp,tempConv
		//	tempConv = 0
			
			//Remove laser response loop
			ControlInfo/W=analysis_tools RemoveLaserResponseCheck
			RemoveLaserResponse = V_Value

			For(i=0;i<rows;i+=1)
				For(j=0;j<cols;j+=1)
					If(darkMask[i][j] != 1)
						continue
					EndIf
			
					MatrixOP/FREE/O/S theBeam = Beam(temp,i,j)
					SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
					
			//		Duplicate/O/FREE conv,convBeam
				//	Convolve/A theBeam,convBeam
					
					
					//Remove laser response from dF matrix wave for better baselining
					If(RemoveLaserResponse)
						estimatePeakTm = 0.5*(endTm + startTm)
						FlattenLaserResponse(theBeam,0,bslnEndTm,1,estimatePeakTm)
					EndIf
					
					temp[i][j][] = theBeam[r]
			//		tempConv[i][j][] = convBeam[r]
				EndFor	
			EndFor	
			
			//Get the baseline fluorescence map
			Make/FREE/O/N=(rows,cols) greenBaseline
			startLayer = ScaleToIndex(theWave,bslnStartTm,2)
			endLayer = ScaleToIndex(theWave,bslnEndTm,2)
			
			greenBaseline = 0
			
			For(i=startLayer;i<endLayer;i+=1)
				MatrixOP/FREE/O theLayer = layer(temp,i)
				greenBaseline += theLayer
			EndFor
			greenBaseline /= (endLayer - startLayer)
			
			//Eliminates the possibility of zero values in the dataset for dendrites in the mask, which all get converted to NaN at the end.
			temp = (temp[p][q][r] == greenBaseline[p][q][0]) ? temp[p][q][r] + 1 : temp[p][q][r]
			
			//Get the ∆F/F time series map with dark subtraction from the non-masked area
			ControlInfo/W=analysis_tools doDarkSubtract
			If(V_Value)
				dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / (greenBaseline[p][q][0] - darkValue)
			Else
				dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / greenBaseline[p][q][0]
			EndIf
					
			//Make waves for the peak and peak-time maps
			dFPeakWaveName = dFWaveName + "_peak"
			
			If(strlen(dFPeakWaveName) > 28)
				dFPeakWaveName = ReplaceString(StringFromList(0,dFPeakWaveName,"_"),dFPeakWaveName,"Scan")
			EndIf
			
		//	dFPeakWaveName = "Scan_020_dF_peak"
			
			Make/O/N=(rows,cols) $dFPeakWaveName,$(dFPeakWaveName + "Loc")//,$(dFPeakWaveName + "dt"),$(dFWaveName + "conv")
		//	Make/O/N=(rows,cols,frames) $(dFWaveName + "dt")
			Wave dFPeakWave = $dFPeakWaveName
			Wave dFPeakLoc = $(dFPeakWaveName + "Loc")
		//	Wave dFDiff = $(dFWaveName + "dt")
		//	Wave dFDiff_pk = $(dFPeakWaveName + "dt")
		//	Wave dF_conv = $(dFWaveName + "conv")
			
			dFPeakWave = gnoise(0.001)
			dFPeakLoc = 0
		//	dFDiff = gnoise(0.001)
			//dFDiff_pk = gnoise(0.001)
			//dF_conv = gnoise(0.00001)
			
		//	Differentiate/DIM=2 dFWave/D=dfDiff
			
			//Temporal smoothing of the dF map prior to finding the peaks.
			ControlInfo/W=analysis_tools SmoothBox
			didSmooth = V_Value
			
			If(didSmooth)
				ControlInfo/W=analysis_tools SmoothFilterVar
				smoothVar = V_Value
				Smooth/S=2/DIM=2 smoothVar,dFWave
			EndIf
				
			//Getting the peak ∆F/F and its time point from a beam 
			For(i=0;i<rows;i+=1)
				For(j=0;j<cols;j+=1)
					//only operates if the data is within the mask region to save time.
					If(darkMask[i][j] != 1)
						continue
					EndIf
					
					MatrixOP/FREE/O/S theBeam = Beam(dFWave,i,j)
					SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
					WaveStats/Q/R=(startTm,endTm) theBeam
					
					dFPeakLoc[i][j] = V_MaxRowLoc
					//averages 0.1 sec before and after the peak to get the final ∆F/F peak value
					dFPeakWave[i][j] = mean(theBeam,V_maxloc - 0.5,V_maxloc + 0.5)
					
					//dFDiff_pk[i][j] = mean(theBeam,V_maxLoc-0.75,V_max+0.5) //get the average of the differential during the rising phase of the response.
					
				//	dF_conv[i][j] = WaveMax(dF_conv,startTm,endTm)
					//dFPeakWave[i][j] = mean(theBeam,startTm,endTm)
					//dFPeakWave[i][j] = V_avg
				EndFor
			EndFor
			
			//Set scales
			SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),dFPeakWave,dFPeakLoc,dFWave//,dFDiff,dFDiff_pk,dF_conv
			SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),dFPeakWave,dFPeakLoc,dFWave//,dFDiff,dFDiff_pk,dF_conv
			SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),dFWave//,dFDiff
		EndIf
		
			//MASKING AND FINAL FILTERING - code common to ∆F and ∆G maps.
			
			//Clip the edges of the image with a mask, to remove the projector artifact
			//theMask[0,10][] = 0
			//theMask[rows-11,rows-1][] = 0
			
			//Clip unreasonably high values
		   //dFWave  = (dFWave > 100) ? 0 : dFWave
		   //dFWave = (dFWave < 0) ? 0 : dFWave
		
			//Additional spatial filter on the peak ∆F/F or ∆G/R map
			ControlInfo/W=analysis_tools postSpatialFilter
			MatrixFilter/N=(V_Value)/R=darkMask median dFPeakWave
			//MatrixFilter/N=(V_Value)/R=darkMask median dFDiff_pk
			
			//If(doRatio)
			//	MatrixFilter/N=(V_Value)/R=darkMask median dFPeakWave
			//EndIf
			//MatrixFilter/N=3 median dFPeakWave
			
			//Apply the mask
			dFPeakWave *= theMask
			dFPeakLoc *= theMask
			//dFDiff_pk *= theMask
			dFWave *= theMask[p][q][0]
			//dFDiff *= theMask[p][q][0]
			//dF_conv *= theMask
			
			dFWave = (dFWave == 0) ? nan : dFWave
			dFPeakLoc = (dFPeakLoc == 0) ? nan : dFPeakLoc
			dFPeakWave = (dFPeakWave == 0) ? nan : dFPeakWave
		//	dFDiff_pk = (dFDiff_pk == 0) ? nan : dFDiff_pk
		//	dFDiff = (dFDiff == 0) ? nan : dFDiff
		//	dF_conv = (dF_conv == 0) ? nan : dF_conv
			
			//Make image histogram of peak fluorescence values
			ControlInfo/W=analysis_tools histogramCheck
			If(V_Value)
				String histName = NameOfWave(dFWave) + "_hist"
				
			
				If(doRatio)
					Histogram/C/B={0,0.0002,150}/DEST=$histName dFPeakWave
					Wave theHist = $histName
					SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"∆G/R",theHist
				Else
					Histogram/C/B={0,0.002,150}/DEST=$histName dFPeakWave
					Wave theHist = $histName
					SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"∆F/F",theHist
				EndIf
			EndIf
			
		//Set notes for the parameters used on to create the map
			For(b=0;b<3;b+=1)
				If(b == 0)
					Wave notedWave = dFWave
				ElseIf(b == 1)
					Wave notedWave = dFPeakWave
				ElseIf(b == 2)
					Wave notedWave = dFPeakLoc
				EndIf 
				
				If(c==0 && numChannels == 1 && !doRatio)
					Note/K notedWave,"TYPE:∆F/F"
					Note notedWave,"CHANNEL:1"
				ElseIf(c==2 && !doRatio)
					Note/K notedWave,"TYPE:∆F/F"
					Note/K notedWave,"CHANNEL:2"
				ElseIf(doRatio)
					Note/K notedWave,"TYPE:∆G/R"
					Note/K notedWave,"CHANNEL:1/2"
				EndIf
				
				Note notedWave,"BSL_START:" + num2str(bslnStartTm)
				Note notedWave,"BSL_END:" + num2str(bslnEndTm)
				Note notedWave,"PK_START:" + num2str(startTm)
				Note notedWave,"PK_END:" + num2str(endTm)
				If(didSmooth)
					Note notedWave,"SMOOTH:" + num2str(smoothVar)
				EndIf
				Note notedWave,"SPATIAL:" + num2str(spatialFilter)
				Note notedWave,"NOISE:" + num2str(cleanNoise)
				Note notedWave,"LASER:" + num2str(removeLaserResponse)
				Note notedWave,"MASK:" + NameOfWave(theMask)
			EndFor	

	EndFor
		If(doRatio)
			print "∆G/R Map for " + scanPath + " in " + num2str(StopMSTimer(timerRef)/(10^6)) + "s" 
		Else
			print "∆F/F Map for " + scanPath + " in " + num2str(StopMSTimer(timerRef)/(10^6)) + "s" 
		EndIf		
		
		KillWaves/Z redBaseline,greenBaseline
		
End

Function MakeVarMap(theWave)
	Wave theWave
	Variable i,rows,cols,frames
	
	//Get dimensions
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	frames = DimSize(theWave,2)
	
	String varMapName = NameOfWave(theWave) + "_var"
	Duplicate/O theWave,$varMapName
	Wave varMap = $varMapName
	Redimension/S/N=(rows,cols,0) varMap
	varMap = 0
				
	//Calculate variance across frames
	MatrixOP/FREE/O theMean = sumBeams(theWave)
	theMean /= frames
				
	For(i=0;i<frames;i+=1)
		varMap += (theMean - theWave[p][q][i])^2
	EndFor
				
	varMap /= (frames - 1)	
End


//Replaces extreme fluorescence values with the mean.
Function/WAVE CleanUpNoise(theWave,threshold)
	Wave theWave
	Variable threshold
	Variable i,j,rows,cols,frames
	
	//Get dimensions
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	frames = DimSize(theWave,2)
	
	//First make a variance map
	String varMapName = NameOfWave(theWave) + "_var"
	Duplicate/O theWave,$varMapName
	Wave varMap = $varMapName
	Redimension/S/N=(rows,cols,0) varMap
	varMap = 0
				
	//Calculate variance across frames
	MatrixOP/FREE/O theMean = sumBeams(theWave)
	theMean /= frames
				
	For(i=0;i<frames;i+=1)
		varMap += (theWave[p][q][i] - theMean[p][q])^2
	EndFor
				
	varMap /= (frames - 1)	
	varMap = sqrt(varMap)
				
	//Use the variance map to identify pixels that have large outlier values
	Duplicate/FREE theWave,theWaveNoise
				
	For(j=0;j<frames;j+=1)
		MatrixOP/FREE theLayer = layer(theWave,j)
		theWaveNoise[][][j] = (theLayer[p][q][0] > theMean[p][q][0] + threshold*varMap[p][q][0]) ? theMean[p][q][0] : theLayer[p][q][0]
	EndFor
	KillWaves/Z varMap		
	return theWaveNoise	
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

//Returns the selected data set name
Function/S whichDataSet()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	ControlInfo/W=analysis_tools dataSetListBox
	If(DimSize(dataSetNames,0) == 0)
		return ""
	EndIf
	
	If(V_Value == -1)
		return ""
	EndIf
	
	return dataSetNames[V_Value]
End

//Returns the wave reference for the selected or named data set
Function/WAVE getDataSetWave([dsName])
	String dsName
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	
	If(ParamIsDefault(dsName))
		ControlInfo/W=analysis_tools dataSetListBox
		
		If(V_Value > DimSize(dataSetNames,0) - 1)
			return $""
		EndIf
		
		dsName = "root:Packages:analysisTools:DataSets:DS_" + dataSetNames[V_Value]
		If(WaveExists($dsName))
			Wave/T theWave = $dsName
			return theWave
		EndIf
	Else
		dsName = "root:Packages:analysisTools:DataSets:DS_" + dsName
		If(WaveExists($dsName))
			Wave/T theWave = $dsName
			return theWave
		EndIf
	EndIf
End

//Perform a user defined operation between two waves
Function doOperation()
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	
	Variable numWaves = DimSize(waveListTable,0)
	Variable i
	
	//Set up operation counter for running from the command line
	Variable/G root:Packages:analysisTools:opCounter
	NVAR opCounter = root:Packages:analysisTools:opCounter
	opCounter = 0
	
	//Using a data set?
	ControlInfo/W=analysis_tools useDataSetCheck
	Variable useDS = V_Value
	
	//Resolve the operation
	ControlInfo/W=analysis_tools operation
	String theOp = S_Value
	ControlInfo/W=analysis_tools outputSuffix
	String suffix = S_Value
	
	String theWaveList = ""
	
	If(useDS)
		String DSList = GetDSinList(theOp)
		//data sets must be of equal length
		If(!DSEqualLength(DSList))
			Abort "Data sets must have the same number of waves"
		EndIf
				
		Variable numDS = ItemsInList(DSList,";")
		If(numDS == 0)
			theWaveList = GetDSWaveList()
			String DSwave = StringFromList(0,theWaveList,",")
			String operation = ResolveOperation(theOp,suffix,DSwave = DSwave)
		Else
			opCounter = -1
			operation = ResolveOperation(theOp,suffix)
			opCounter = 0
		EndIf
	Else
		operation = ResolveOperation(theOp,suffix)
	EndIf
	
	strswitch(operation)
		case "1":
			//average all waves
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
				avgSelectedWaves(theWaveList,0)
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
					EndFor
					avgSelectedWaves(theWaveList,0)
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += cdf + waveListTable[i] + ";"
					EndFor
					avgSelectedWaves(theWaveList,0)
				EndIf
			EndIf
			break
		case "2": 
			//add up all the waves
			
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
				addSelectedWaves(theWaveList)
			Else
				SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
				theWaveList = ""
				For(i=0;i<DimSize(waveListTable,0);i+=1)
					theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
				EndFor
				addSelectedWaves(theWaveList)
			EndIf
			break
		case "3":
			//standard error of the waves
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
				avgSelectedWaves(theWaveList,1)
			Else
				SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
				theWaveList = ""
				For(i=0;i<DimSize(waveListTable,0);i+=1)
					theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
				EndFor
				avgSelectedWaves(theWaveList,1)
			EndIf
			break
		case "5":
			SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))
			Wave w1 = $waveListTable[0]
			SetDataFolder $("root:twoP_Scans:" + StringFromList(1,scanListStr,";"))
			Wave w2 = $waveListTable[1]
		
			String outWaveName = NameOfWave(w1) + "_ratio"
			SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))
			Duplicate/O w1,$outWaveName
	
			Wave outWave = $outWaveName
			outWave = 0
	
			outWave = w2/w1
	
			outWave = (outWave == inf) ? nan : outWave
			outWave = (outWave == 0) ? nan : outWave
			outWave = (outWave > 10 || outWave < -10) ? nan : outWave
			MatrixFilter/N=7 median outWave
		case "6":
			//kill all the selected waves
			If(useDS)
			
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						Wave/Z theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i])
						KillWaves/Z theWave
					EndFor
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						KillWaves/Z $(cdf + waveListTable[i])
					EndFor
				EndIf
			EndIf
			break
		case "7":
			//display the selected waves in a single graph
			If(useDS)
				theWaveList = GetDSWaveList()
				Display $StringFromList(0,theWaveList,",")
				For(i=1;i<ItemsInList(theWaveList,",");i+=1)
					AppendToGraph $StringFromList(i,theWaveList,",")
				EndFor
			Else
				print "can only display using data set function for now."
			EndIf
			break
		case "8":
			//edit the waves
			If(useDS)
				theWaveList = GetDSWaveList()
				Execute/Q/Z "Edit/K=0 " + theWaveList
			EndIf
			break
		case "9":
			//Differentiate
			If(useDS)
				theWaveList = GetDSWaveList()
				For(i=0;i<ItemsInList(theWaveList,",");i+=1)
					DifferentiateWaves($StringFromList(i,theWaveList,";"))
				EndFor
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						Wave/Z theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i])
						DifferentiateWaves(theWave)
					EndFor
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += cdf + waveListTable[i] + ";"
						DifferentiateWaves($StringFromList(i,theWaveList,";"))
					EndFor
				EndIf
			EndIf
			break
		default:
			//free form
			opCounter = 0
			If(useDS)
				DSList = GetDSinList(theOp)
				//data sets must be of equal length
				If(!DSEqualLength(DSList))
					Abort "Data sets must have the same number of waves"
				EndIf
				
				numDS = ItemsInList(DSList,";")
				If(numDS == 0)	//if DS reference is from the selection
					theWaveList = GetDSWaveList()
					numWaves = ItemsInList(theWaveList,",")
					operation = ""
					For(i=0;i<numWaves;i+=1)
						opCounter = i
						DSwave = StringFromList(i,theWaveList,",")
						operation = ResolveOperation(theOp,suffix,DSwave = DSwave)
						Execute/Z operation
						print operation
					EndFor
				Else //if DS reference is stated in the command
					theWaveList = GetDSWaveList(dsName=StringFromList(0,DSList,";"))
					numWaves = ItemsInList(theWaveList,",")
					operation = ""
					For(i=0;i<numWaves;i+=1)
						opCounter = i
						operation = ResolveOperation(theOp,suffix)
						Execute/Z operation
						print operation
					EndFor
				EndIf
			Else
				Execute/Z operation
				print operation
				String outputWaveStr = StringFromList(0,operation,"=")
				Wave outWave = $outputWaveStr
			
				//Set scale
				String scaleWaveName = "root:twoP_Scans:" + StringFromList(0,scanListStr,";") + ":" + waveListTable[0]
				If(DimSize(outWave,2) > 0)
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
					SetScale/P y,DimOffset($scaleWaveName,1),DimDelta($scaleWaveName,1),outWave
					SetScale/P z,DimOffset($scaleWaveName,2),DimDelta($scaleWaveName,2),outWave
				ElseIf(DimSize(outWave,1) > 0)
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
					SetScale/P y,DimOffset($scaleWaveName,1),DimDelta($scaleWaveName,1),outWave
				Else
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
				EndIf
			
			//	applyFilters(outWave)
			EndIf
	endswitch
End

Function DSEqualLength(DSList)
	String DSList
	Variable numDS = ItemsInList(DSList,";")
	Variable length,lastLength,i
	
	If(numDS == 0)
		return -1
	EndIf
	
	For(i=0;i<numDS;i+=1)
		Wave/T dataSetWave = getDataSetWave(dsName=StringFromList(i,DSList,";"))
		length = DimSize(dataSetWave,0)
		If(i == 0)
			lastLength = length
		Else
			If(length != lastLength)
				return 0
			EndIf
		EndIf
	EndFor
	
	return 1 //equal length data sets
End


//Takes the input string, and parses to see if there are data set references present. Lists all DS references
Function/S GetDSinList(theOp)
	String theOp
	String DSList = ""
	Variable startPos,endPos
	
	//Find start position of a DS reference
	endPos = 0
	Do
		startPos = strsearch(theOp,"<",endPos)
		If(startPos != -1)
			//Find end position of a DS reference
			endPos = strsearch(theOp,">",startPos)
			If(endPos == -1)
				Abort "Need ending bracket for data set reference"
			EndIf
			DSList += theOp[startPos+1,endPos-1] + ";"
		EndIf
	While(startPos != -1)
			
	return DSList
End

//Finds the selected data set name, outputs the list of waves defined by that data set
//If wavesets are defined, loops through them and produces separate output waves for each wsn

Function/S GetDSWaveList([dsName,separator])
	String dsName,separator
	If(ParamIsDefault(separator))
		separator = ","
	EndIf
	
	If(ParamIsDefault(dsName))
		String dataSetName = whichDataSet()
		Wave/T ds = getDataSetWave()
	Else
		If(!cmpstr(dsName,"saveDSgrouping"))
			Wave/T ds = $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
		Else
			Wave/T ds = getDataSetWave(dsName=dsName)
		EndIf
	EndIf
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	//Find if there are wavesets, and what are their dimensions?
	Variable i,j,pos,size = DimSize(ds,0)
	Variable numWaveSets = 0
	
	String theWaveList = ""
	
	For(i=0;i<size;i+=1)
		theWaveList += ds[i] + separator
	EndFor
	theWaveList = RemoveEnding(theWaveList,separator)
	return theWaveList

End

//Return number wavesets in dataset
Function GetNumWaveSets(dsName)
	String dsName
	
	If(isDataSet(dsName))
		Wave/T ds = getDataSetWave(dsName=dsName)
	Else
		//If there is no valid wave set selected, just use the waves listed in the wave list table
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf
	
	Variable i,pos,size,numWaveSets
	
	size = DimSize(ds,0)
	numWaveSets = 0
	pos = 0
	For(i=0;i<size;i+=1)
		pos = tableMatch("*WSN*",ds,startp=pos,endp=size-1)
		If(pos == -1)
			break
		Else
			pos += 1
			numWaveSets += 1
		EndIf
	EndFor
	
	//If none were found, make it 1 waveset
	If(numWaveSets == 0)
		numWaveSets = 1
	EndIf
	
	return numWaveSets
End

//Is the input data set name actually a data set?
Function	isDataSet(dsName)
	String dsName
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Variable i
	
	If(strlen(dsName) == 0)
		return 0
	EndIf
	
	For(i=0;i<DimSize(dataSetNames,0);i+=1)
		If(!cmpstr(dataSetNames[i],dsName))
			return 1
		EndIf
	EndFor
	
	return 0
End

Function/S GetWaveSetDims(dsName)
	String dsName
	
	If(isDataSet(dsName))
		Wave/T ds = getDataSetWave(dsName=dsName)
	Else
		//If there is no valid wave set selected, just use the waves listed in the wave list table
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf	
		
	Variable i,pos,lastpos,size,dim,numWaveSets
	String wsDims = ""	
	
	size = DimSize(ds,0)
	pos = 0
	lastpos = 0
	For(i=0;i<size;i+=1)
		pos = tableMatch("*WSN*",ds,startp=pos,endp=size-1)
		
		If(pos == -1)
			//last waveset in the dataset
			dim = size- lastpos
			wsDims += num2str(dim) + ";"
			break
		Else
			If(numWaveSets > 0) //second or greater wave set label detected
				dim = pos - lastpos
				wsDims += num2str(dim) + ";"
			EndIf
			pos += 1
			numWaveSets += 1
		EndIf
		lastpos = pos
	EndFor
	
	return wsDims
End

Function addSelectedWaves(selWaveList)
	String selWaveList
	Variable i,xSize,ySize,zSize
	String outWaveName,suffix
	
	ControlInfo/W=analysis_tools outputSuffix
	suffix = S_Value
	
	If(!strlen(suffix))
		suffix = "sum"
	EndIf
	
	outWaveName = StringFromList(0,selWaveList,";") + "_" + suffix
	
	xSize = DimSize($StringFromList(0,selWaveList,";"),0)
	ySize = DimSize($StringFromList(0,selWaveList,";"),1)
	zSize = DimSize($StringFromList(0,selWaveList,";"),2)
	
	Make/O/N=(xSize,ySize,zSize) $outWaveName
	
	Wave outWave = $outWaveName
	outWave = 0
	
	For(i=0;i<ItemsInList(selWaveList,";");i+=1)
		Wave theWave = $StringFromList(i,selWaveList,";")
		outWave += theWave
	EndFor
	
	//Set scales
	If(xSize)
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	EndIf
	If(ySize)
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	EndIf
	If(zSize)
		SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),outWave
	EndIf
End

Function/S ResolveOperation(opStr,suffix[,DSwave])
	String opStr,suffix
	String DSwave
	NVAR opCounter = root:Packages:analysisTools:opCounter
	
	Variable char,op,i,numPhrases,type,index
	String theChar,newOpStr,theCommand,phrase,theWaveName
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable RunCmdLine = 0
	
	//remove whitespace
	opStr = ReplaceString(" ",opStr,"")
	//number of characters
	char = strlen(opStr)
	
	strswitch(opStr)
		case "avg":
			//Averaging
			return "1"
			break
		case "sum":
			//Sum
			return "2"
			break
		case "sem":
			return "3"
			break
		case "delete":
			//kill the waves
			return "6"
			break
		case "display":
			return "7"
			break
		case "edit":
			return "8"
			break
		case "differentiate":
			return "9"
			break
		default:
			ControlInfo/W=analysis_tools useDataSetCheck
			Variable useDS = V_Value
			ControlInfo/W=analysis_tools operationOptionsPop
			If(cmpstr(S_Value,"Cmd Line") == 0)
				Variable doCmdLine = 1
			EndIf
			
			String/G root:Packages:analysisTools:opFolder
			SVAR opFolder = root:Packages:analysisTools:opFolder
			
			String DSList = GetDSInList(opStr)
			Variable numDS = ItemsInList(DSList,";")
			
			If(useDS)
				newOpStr = ""
				For(i=0;i<char;i+=1)
					theChar = opStr[i]
					
					If(doCmdLine)
						//Get the result
						Variable isResult = ItemsInList(opStr,"=")
						If(isResult == 2) //object is receiving the result of the function
							String theResult = StringFromList(0,opStr,"=")	
						
							//Get the function argument
							String theArgument = StringFromList(1,opStr,"(") //Gets the string between the parentheses of the function call
							theArgument = RemoveEnding(theArgument,")")
					
							//Get the function 
							String theFunction = StringFromList(0,opStr,"(") //Gets the function 
							theFunction = StringFromList(1,theFunction,"=") //gets rid of the result string
						Else
							theArgument = opStr	
							theResult = ""
							theFunction = ""			
						EndIf	
						
						//Resolve the result
						If(isResult == 2)
							strswitch(theResult)
								case "rw":
									//wave result
									If(opCounter == 0)//get the folder of the first wave in the data set for the output
										If(numDS == 0)
											opFolder = GetWavesDataFolder($DSwave,1)
										EndIf
									EndIf
									
									If(numDS > 0)
										String theWaveList = GetDSWaveList(dsName=StringFromList(0,DSList,";"))
										Wave/Z theWave = $StringFromList(0,theWaveList,",")
										opFolder = GetWavesDataFolder($StringFromList(0,theWaveList,","),1)
									EndIf
									
									
									If(!strlen(suffix))
										theResult = opFolder + "result"
									Else
										theResult = opFolder + suffix
									EndIf
									
									//ensure unique name for the output wave
									If(WaveExists($theResult))
										theResult = ReplaceString(suffix,theResult,UniqueName(suffix,1,0))
									EndIf
									
									
									If(numDS == 0)
										Make/O/N=(DimSize(waveListTable,0)) $theResult
										Wave outWave = $theResult
										theResult += "[" + num2str(opCounter) + "]"
									Else
										If(opCounter != -1)
											Make/O/N=(DimSize(theWave,0)) $theResult
											Wave outWave = $theResult
											SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0), outWave
											SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1), outWave
										EndIf
									EndIf
									
									break
								case "rv":
									//variable result
									break
								case "rs":
									//string result
									break
							endswitch
						EndIf
						
						//Resolve the argument
						If(cmpstr(theArgument,"w") != 0)
							If(numDS == 0)
								Variable stringPos = WhichListItem("w",theArgument,",")
								If(stringPos == -1)
									theCommand = opStr + "(" + DSwave + ")"
									Abort "Couldn't resolve the operation"
								Else
									If(stringPos == 0)
										theArgument = ReplaceString("w,",theArgument,DSwave + ",")
									ElseIf(stringPos == strlen(theArgument) - 1)
										theArgument = ReplaceString(",w",theArgument,"," + DSwave)
									Else
										theArgument = ReplaceString(",w,",theArgument,"," + DSwave + ",")
									EndIf
								EndIf
							
								If(isResult == 2)
									theCommand = theResult + "=" + theFunction + "(" + theArgument + ")"
								Else
									theCommand = theFunction + "(" + theArgument + ")"
								EndIf
							Else
								If(!strlen(theArgument))
									theArgument = theFunction//if it mistakenly was put into the function string
								EndIf
								
								If(isResult == 2)
									theCommand = theResult + "=" + InsertDSWaveNames(theArgument,opCounter)

								Else
									theCommand = InsertDSWaveNames(theArgument,opCounter)
								EndIf
							EndIf
						Else
							If(isResult == 2)
								theCommand = theResult + "=" + opStr + "(" + DSwave + ")"
							Else
								theCommand = opStr + "(" + DSwave + ")"
							EndIf
						EndIf
						return theCommand
					EndIf
					
					
					//Separate the phrases of the operation by ;
					If(cmpstr(theChar,"=") == 0 || cmpstr(theChar,"+") == 0 || cmpstr(theChar,"-") == 0 || cmpstr(theChar,"*") == 0 || cmpstr(theChar,"/") == 0 || cmpstr(theChar,"^") == 0)
						theChar = ReplaceString(theChar,theChar,";" + theChar + ";")
					EndIf
					newOpStr += theChar
				EndFor
				numPhrases = ItemsInList(newOpStr,";")
				theCommand = ""
				
				For(i=0;i<numPhrases;i+=1)
					type = mod(i,2)
					phrase = StringFromList(i,newOpStr,";")
					
					If(type == 0)
						//wave definition
						theChar = phrase[0]
						If(cmpstr(theChar,"(") == 0)
							theCommand += theChar
							phrase = phrase[1,strlen(phrase)-1]
						EndIf
						
						Variable theNum = str2num(theChar)
						//If its a number not a wave
						If(numType(theNum) != 2)
							theCommand += theChar
							continue
						EndIf
						//index = str2num(phrase[1]) - 1 //Not zero offset, starts at 1 for indexing
						
						//specific data set reference
						If(cmpstr(theChar,"<") == 0)
							theCommand += theChar
							//take out the brackets
							phrase = ReplaceString("<",phrase,"")
							phrase = ReplaceString(">",phrase,"")
							Wave/Z theWave = getDataSetWave(dsName=phrase)
							If(WaveExists(theWave))
								theCommand += NameOfWave(theWave)
							EndIf
						Else
						
						EndIf
						
						theCommand += DSwave
						
						If(cmpstr(phrase[strlen(phrase)-1],")") == 0)
							theCommand += phrase[strlen(phrase)-1]
						EndIf
					ElseIf(type == 1)
						//operator
						theCommand += phrase
					EndIf
				EndFor
				
				
				return theCommand
			Else
				//make output wave
				theWaveName = "root:twoP_Scans:" + StringFromList(index,scanListStr,";") + ":" + waveListTable[0]
				String outputWaveName = theWaveName + "_" + suffix
				Duplicate/O $theWaveName,$outputWaveName
		
				theCommand = outputWaveName + "="
				newOpStr = ""
	
				For(i=0;i<char;i+=1)
					theChar = opStr[i]
			
					//Separate the phrases of the operation by ;
					If(cmpstr(theChar,"+") == 0 || cmpstr(theChar,"-") == 0 || cmpstr(theChar,"*") == 0 || cmpstr(theChar,"/") == 0 || cmpstr(theChar,"^") == 0)
						theChar = ReplaceString(theChar,theChar,";" + theChar + ";")
					EndIf
					newOpStr += theChar
				EndFor
	
				numPhrases = ItemsInList(newOpStr,";")
				For(i=0;i<numPhrases;i+=1)
					type = mod(i,2)
					phrase = StringFromList(i,newOpStr,";")
			
					If(type == 0)
						//wave definition
						theChar = phrase[0]
						If(cmpstr(theChar,"(") == 0)
							theCommand += theChar
							phrase = phrase[1,strlen(phrase)-1]
						EndIf
						index = str2num(phrase[1]) - 1 //Not zero offset, starts at 1 for indexing
						theWaveName = "root:twoP_Scans:" + StringFromList(index,scanListStr,";") + ":" + waveListTable[index]
						theCommand += theWaveName
						If(cmpstr(phrase[strlen(phrase)-1],")") == 0)
							theCommand += phrase[strlen(phrase)-1]
						EndIf
					ElseIf(type == 1)
						//operator
						theCommand += phrase
					EndIf
				EndFor
	
				return theCommand
			EndIf
			break
	endswitch
End

Function/S InsertDSWaveNames(opStr,index)
	String opStr
	Variable index
	String DSList = GetDSinList(opStr)
	Variable i
	
	For(i=0;i<ItemsInList(DSList,";");i+=1)
		String theDataSet = StringFromList(i,DSList,";")
		String theWaveList = GetDSWaveList(dsName=theDataSet)
		String theItem = StringFromList(index,theWaveList,",")
		opStr = ReplaceString("<" + theDataSet + ">",opStr,theItem)
	EndFor
	
	return opStr
End

Function/WAVE getWaveMatchList()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	//Full path wave list table
	Wave/T AT_WaveListTable_FullPath = root:Packages:analysisTools:AT_WaveListTable_FullPath
	
	Variable items = ItemsInList(scanListStr,";")
	Variable i
	SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
	SVAR notMatchStr = root:Packages:analysisTools:waveNotMatchStr
	String itemList = ""
	String masterItemList = ""
	String currentFolder,folder
	SVAR MBr_cdf = root:Packages:MBr:currentDataFolder
	
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave selWave = root:Packages:analysisTools:AT_selWave
	
	currentFolder = GetDataFolder(1)
	
	//Checks if match string has value
	If(!strlen(waveMatchStr))
		waveMatchStr = "*"
	EndIf
	
	//If we're in browser mode
	SVAR whichList = root:Packages:analysisTools:whichList
	Wave/T folderTable = root:Packages:MBr:folderTable
	Wave selFolderWave = root:Packages:analysisTools:selFolderWave
	
	//Find out the selected folders if we're in Browser mode
	If(cmpstr(whichList,"Browser") == 0)
		Variable browsing = 1
		String folderList = ""
		For(i=0;i<DimSize(folderTable,0);i+=1)
			If(selFolderWave[i] == 1)
				folderList +=  MBr_cdf + folderTable[i] + ";"
			EndIf
		EndFor
		items = ItemsInList(folderList,";")
	Else
		browsing = 0
	EndIf	
	
	//Fill out the wave match list box for each scan folder
	If(items == 0)
		items = 1
	EndIf
	
	Variable count = 0
	
	For(i=0;i<items;i+=1)
		If(browsing)
			If(!strlen(folderList))
				folder = MBr_cdf
			Else
				folder = StringFromList(i,folderList,";") + ":"
			EndIf
		Else
			folder = "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":"
		EndIf
	
		If(DataFolderExists(folder))
			SetDataFolder $folder
		Else
			continue
		EndIf
		
		//Are there any OR statements in the match string?
		Variable j,numORs
		numORs = ItemsInList(waveMatchStr,"||")
		
		//Match list
		itemList = ReplaceString(";",StringFromList(1,DataFolderDir(2),":"),"")
		itemList = TrimString(itemList)
		String item,fullPathItemList
		
		String tempList = ""
		//Match each OR element in the match string separately 
		For(j=0;j<numORs;j+=1)
			String matchStr = StringFromList(j,waveMatchStr,"||")
			tempList += ListMatch(itemList,matchStr,",")
		EndFor
		itemList = tempList
		
		itemList = RemoveDuplicateList(itemList,";")
		
		//Not match list
		numORs = ItemsInList(notMatchStr,"||")
		For(j=0;j<numORs;j+=1)
			If(strlen(notMatchStr))
				matchStr = StringFromList(j,notMatchStr,"||")
				itemList = ListMatch(itemList,"!*" + matchStr,",")
			EndIf
		EndFor
		masterItemList += itemList
		
		Redimension/N=(ItemsInList(masterItemList,",")) AT_WaveListTable_FullPath
		For(j=0;j<ItemsInList(itemList,",");j+=1)
			item = StringFromList(j,itemList,",")
			AT_WaveListTable_FullPath[count] = folder + item
			count += 1
		EndFor
	EndFor
	
	Redimension/N=(ItemsInList(masterItemList,",")) waveListTable,selWave
	
	For(i=0;i<ItemsInList(masterItemList,",");i+=1)
		waveListTable[i] = StringFromList(i,masterItemList,",")
	EndFor
	
	return waveListTable
End

//Takes a list of items, and removes all the duplicate items
Function/S RemoveDuplicateList(theList,separator)
	String theList,separator
	Variable i,j,size,checkpt
	String item
	
	checkpt = -1
	size = ItemsInList(theList,separator)
	For(i=0;i<size;i+=1)
		item = StringFromList(i,theList,separator)
		For(j=0;j<size;j+=1)
			//Skip the item being tested so it isn't flagged as a duplicate
			If(j == i)
				continue
			EndIf
			//Duplicate found
			If(cmpstr(item,StringFromList(j,theList,separator)) == 0)
				theList = RemoveListItem(j,theList,separator)
				size = ItemsInList(theList,separator)
				//restarts the loop
				i = checkpt	
				break
			ElseIf(j == size - 1) //no duplicates found for that item
				checkpt += 1
			EndIf
		EndFor
	EndFor
	return theList
End

Function atSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	Wave/T WaveListDS = root:Packages:analysisTools:DataSets:WaveListDS
	Wave/T ogWaveListDS = root:Packages:analysisTools:DataSets:ogWaveListDS	
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
				//Get wave match string
			strswitch(sva.ctrlName)
				case "waveMatch":
					SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
					waveMatchStr = sval
					getWaveMatchList()
					fillFilterTable()
					updateWSDimText()
					break
				case "waveNotMatch":
					SVAR waveNotMatchStr = root:Packages:analysisTools:waveNotMatchStr
					waveNotMatchStr = sval
					getWaveMatchList()
					fillFilterTable()
					updateWSDimText()
					break
				case "waveGrouping":
				//	String theList = GetDSWaveList()
				//	String dataSetName= whichDataSet()
				//	Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
					
				//	Wave/T theWaveList = root:Packages:analysisTools:DataSets:AT_WaveListTable
					
					
					//sort remaingin waves by by grouping	
				//	setWaveGrouping(theList,sval,dataSetName)
					
					//check for additional filters
				//	filterByGroup(theList,dataSetName)
					
					//make sure wave sets are all valid dimensions
				//	checkWaveSets(dataSetName)
					
					//fill out the table that remembers the filtering settings of each data set
				//	fillFilterTable()
					
					//update the list box and wave counters
				//	updateWaveListBox()
				//	updateWSDimText()
			
					String dataSetName= whichDataSet()
					String theList = GetDSWaveList()
					setWaveGrouping(theList,dataSetName)
					
					Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
					
					If(!WaveExists(ds))
						Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
					EndIf
					
					//Save the wave grouping so I can undo any prefix/group/series/etc adjustments
					Make/O/T/N=(DimSize(ds,0)) $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
					Wave/T saveDSgrouping = $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
					saveDSgrouping = ds
					//break
				case "prefixGroup":
				case "groupGroup":
				case "seriesGroup":
				case "sweepGroup":
				case "traceGroup":
					If(cmpstr(sva.ctrlName,"waveGrouping"))			
						dataSetName= whichDataSet()
						theList = GetDSWaveList()
					EndIf
					
					Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
					
					If(!WaveExists(ds))
						Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
					EndIf
					
				//	setWaveGrouping(theList,dataSetName)
					
					//check for additional filters
					filterByGroup(theList,dataSetName)
					
					//make sure wave sets are all valid dimensions	
					checkWaveSets(dataSetName)
					
					//fill out the table that remembers the filtering settings of each data set
					fillFilterTable()			
					
					//update the list box and wave counters
					updateWaveListBox()
					updateWSDimText()
					
					//Save the wave grouping so I can undo any prefix/group/series/etc adjustments
				//	Make/O/T/N=(DimSize(ds,0)) $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
				//	Wave/T saveDSgrouping = $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
				//	saveDSgrouping = ds
					
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

//Finds selected data set, updates it with the waves in the wave list box.
Function updateSelectedDataSet()
	//get the data set wave
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	ControlInfo/W=analysis_tools dataSetListBox
	String dsName = dataSetNames[V_Value]
	Wave/T ds = GetDataSetWave(dsName=dsName)
		
	//Wave list table
	Wave/T AT_waveListTable = root:Packages:analysisTools:AT_waveListTable
	
	Redimension/N=(DimSize(AT_waveListTable,0)) ds
	ds = AT_waveListTable
End

//Fills out the filter table for the selected data set
Function fillFilterTable()
	
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames

	//Fill in the data set filter table
	Variable currentNumSets = DimSize(dataSetNames,0)
	
	//Ensure correct wave dimensions
	If(currentNumSets == 0)
		return -1
	EndIf
	
	Redimension/N=(currentNumSets,2) dsFilters	
	ControlInfo/W=analysis_tools dataSetListBox
	
	dsFilters[V_Value][0] = dataSetNames[V_Value]
	dsFilters[V_Value][1] = GetDSFilters()

End

//If it finds any emtpy wavesets, eliminates them
Function checkWaveSets(dataSetName)
	String dataSetName
	Wave/T ds = GetDataSetWave(dsName = dataSetName)
	Wave/T ogds = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
		Wave/T ogds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	Variable i,pos1,pos2,index,count
	
	//Remove any blank spaces
	For(i=0;i<DimSize(ds,0);i+=1)
		If(!strlen(ds[i]))
			DeletePoints i,1,ds
			i-=1
		EndIf
	EndFor
	
	For(i=0;i<DimSize(ogds,0);i+=1)
		If(!strlen(ogds[i]))
			DeletePoints i,1,ogds
			i-=1
		EndIf
	EndFor
	
	
	String dims = GetWaveSetDims(dataSetName)
	
	count = 0
	For(i=0;i<DimSize(ds,0);i+=1)
		String item = ds[i]
		If(stringmatch(item,"*WSN*"))
			pos1 = strsearch(item,"WSN ",0)
			pos2 = strsearch(item,"--",pos1)
			index = str2num(item[pos1+4,pos2-1])
			If(!cmpstr(StringFromList(index,dims,";"),"0"))
				DeletePoints i,1,ds
				i-=1
			Else
				//must number the wave sets correctly if there are empty wavesets in the beginning of the ds wave list
				ds[i] = "----WSN " + num2str(count) + "----"
				count += 1
			EndIf
		EndIf
	EndFor
End

//Takes input of prefix,group,series,sweep, or trace and filters the wave list accordingly
Function/S filterByGroup(theList,dataSetName)
	String theList,dataSetName

	//current waveset grouping
	Wave/T ds = GetDataSetWave(dsName = dataSetName)
	
	//If no data set selection, we'll use the wave list table instead
	//This will happen if no data sets have been defined yet
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	//last waveset grouping
	Wave/T saveDSgrouping = $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
	theList = GetDSWaveList(dsName="saveDSgrouping",separator = ",")
	
	String groupList = "prefixGroup;groupGroup;seriesGroup;sweepGroup;traceGroup"
	Variable i,j,k,numWaves,numTerms
	String waveTerm,filterTerms,theWave,theTerm,fullTermList,tempList
	
	//Get the inputs from all of the variables (prefix,group,series,etc.)
	Variable termCount = 0
	fullTermList = ""
	For(i=0;i<ItemsInList(groupList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,groupList,";")
		fullTermList += S_Value + ";"
		If(strlen(S_Value) > 0)
			termCount += 1
		EndIf
	EndFor
	
	//break if no terms are present
	If(termCount == 0)
		//Input the new list into the data set wave
		Redimension/N=(DimSize(saveDSgrouping,0)) ds
		ds = saveDSgrouping
		return ""
	EndIf
		
	numWaves = ItemsInList(theList,",")
	
	//Will hold the final waveset list
	Variable match = 0
	
	For(k=0;k<ItemsInList(fullTermList,";");k+=1)
		//each overall input term for prefix/group/etc.
		filterTerms = resolveListItems(StringFromList(k,fullTermList,";"),",")
		numTerms = ItemsInList(filterTerms,",")
				
		If(numTerms == 0)
			continue
		EndIf		
				
		For(i=0;i<ItemsInList(theList,",");i+=1)
			theWave = ParseFilePath(0,StringFromList(i,theList,","),":",1,0)
			If(stringmatch(theWave,"*WSN*"))
				continue
			EndIf
		
			//Gets the term in the wave name to compare it to
			//Uses the overall term position (prefix/group/series) for this
			waveTerm = StringFromList(k,theWave,"_")	
			
			//Does the wave match any of the wave terms in this term slot? (prefix,group,series,etc.)
			match = 0
			For(j=0;j<numTerms;j+=1)
				//subterm within prefix/group/etc.
				theTerm = StringFromList(j,filterTerms,",")
				If(cmpstr(waveTerm,theTerm))
				//no match
					match = 0
				Else
				//match
					match = 1
					break
				EndIf
			EndFor
			
			//If one of the terms in the list matched the wave, keep it in the list
			If(!match)
				theList = RemoveListItem(i,theList,",")
				i -= 1
			EndIf
		EndFor
	EndFor
	
	//Input the new list into the data set wave
	Redimension/N=(ItemsInList(theList,",")) ds
	
	For(i=0;i<ItemsInList(theList,",");i+=1)
		ds[i] = StringFromList(i,theList,",")
	EndFor
	
	return theList
End

Function updateWaveListBox()
	//Refresh the wave list box for the new wave grouping
	Wave/T ds = GetDataSetWave()
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave matchListselWave = root:Packages:analysisTools:AT_selWave
	Redimension/N=(DimSize(ds,0)) waveListTable,matchListselWave
	Variable i
	For(i=0;i<DimSize(ds,0);i+=1)
		waveListTable[i] = ParseFilePath(0,ds[i],":",1,0)
	EndFor
	ControlUpdate/W=analysis_tools	 matchListBox

End

//Reorganizes the waves in the data set according to the wave grouping
Function setWaveGrouping(theList,dataSetName)
	String theList,dataSetName
	Wave/T ds = GetDataSetWave(dsName = dataSetName)
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	Variable numGroupings,numWaves,item,i,j,k,wsn,count
	String term,name,matchName,matchTerm
	
	//if there isn't a copy of the original ungrouped dataset, make one
	String copyName = "root:Packages:analysisTools:DataSets:og" + NameOfWave(ds)
	If(!WaveExists($copyName))
		Duplicate/T/O ds,$copyName
	EndIf
	Wave/T copy = $copyName
	
	//reset the wave groupings
	Redimension/N=(DimSize(copy,0)) ds
	ds = copy
	
	ControlInfo/W=analysis_tools waveGrouping
	String grouping = S_Value
	numGroupings = ItemsInList(grouping,",")
	numWaves = DimSize(ds,0)
	
	//make working waves
	Make/T/FREE/N=(numWaves) tempDS
	Make/FREE/N=(numWaves) matched
	
	matched = -1
	//wsn = 0
	
	For(i=0;i<numGroupings;i+=1)
		wsn = 0
		item = str2num(StringFromList(i,grouping,","))
		switch(item)
			case -2:
				//group all together
				Redimension/N=(DimSize(copy,0)) ds
				ds = copy
				break
			default:
				//group by the index

				//If the data set is already grouped, must do next grouping within that structure
				Variable m,numWaveSets = GetNumWaveSets(dataSetName)
				String wsDims = GetWaveSetDims(dataSetName)
				numWaves = DimSize(copy,0)
				
				//make fresh working waves
				Make/T/FREE/N=(numWaves) tempDS
				Make/FREE/N=(numWaves) matched
				Make/T/FREE/N=(DimSize(ds,0)) copy2
				copy2 = ds
				
				matched = -1	
					
				For(m=0;m<numWaveSets;m+=1)
					//uses block of waves from each subsequent waveset
					numWaves = str2num(StringFromList(m,wsDims,";"))
					String theWaves = getWaveSet(dataSetName,wsn=m)
					
					For(j=0;j<numWaves;j+=1)
						
						If(matched[j + m*numWaves] != -1)
							continue
						EndIf
						
						//name = ParseFilePath(0,ds[j],":",1,0)
						name = ParseFilePath(0,StringFromList(j,theWaves,";"),":",1,0)
						term = StringFromList(item,name,"_")
						
						For(k=0;k<numWaves;k+=1)
							If(matched[k + m*numWaves] != -1)
								continue
							EndIf
							//matchName = ParseFilePath(0,ds[k],":",1,0)
							matchName = ParseFilePath(0,StringFromList(k,theWaves,";"),":",1,0)
							matchTerm = StringFromList(item,matchName,"_")
						
							If(!cmpstr(term,matchTerm))
								matched[k + m*numWaves] = wsn
							EndIf	
							
						EndFor
						wsn += 1
					EndFor
				EndFor
				
				//Label first wave set, if there are more than 1
				count = 0

				//make copy of it without the wave set labels
				Variable size = DimSize(copy2,0)
				For(j=0;j<size;j+=1)
					If(stringmatch(copy2[j],"*WSN*"))
						DeletePoints j,1,copy2
						j -= 1
						size -= 1
					EndIf
				EndFor
				
				If(wsn > 0)
					InsertPoints 0,1,tempDS
					tempDS[count] = "----WSN 0----"
					count += 1
				EndIf
				
				//sort data set
				numWaves = DimSize(copy,0)
								
				For(j=0;j<wsn;j+=1)
					For(k=0;k<numWaves;k+=1)
						If(matched[k] == j)
							tempDS[count] = copy2[k]
							count +=1
						EndIf	
					EndFor
					
					If(j<wsn-1)
						InsertPoints count,1,tempDS
						tempDS[count] = "----WSN " + num2str(j+1) + "----"
					EndIf
					count+=1
				EndFor
				
				Redimension/N=(DimSize(tempDS,0)) ds
				ds = tempDS
		endswitch
	EndFor
	
	//updateWaveListBox()
End


Function applyFilters(theWave)
	Wave theWave
	theWave = (theWave == inf) ? nan : theWave
	theWave = (theWave == 0) ? nan : theWave
	theWave = (theWave > 10 || theWave < -10) ? nan : theWave
	//theWave = (theWave < 0) ? 
//	MatrixFilter/N=7 median theWave
End


//Makes histogram of a waves value distribution
Function freqHistogram(inWave,[binWidth])
	Wave inWave
	Variable binWidth
	Variable low,high,numBins
	
	low = WaveMin(inWave)
	high = WaveMax(inWave)
	
	If(ParamIsDefault(binWidth))
		binWidth = 0.05
	EndIf
	
	numBins = ceil((high - low)/binWidth)
	
	String outWaveName = NameOfWave(inWave) + "_hist"
	Make/O/N=(numBins) $outWaveName
	Wave outWave = $outWaveName
	outWave = 0
	
	Variable i,j,rows,cols,theBin,count
	
	rows = DimSize(inWave,0)
	cols = DimSize(inWave,1)
	If(cols == 0)
		cols = 1
	Endif
	count = 0
	For(i=0;i<rows;i+=1)
		For(j=0;j<cols;j+=1)
			theBin = floor((inWave[i][j] - low)/binWidth)
			If(numType(theBin) == 2)
				continue
			EndIf
			outWave[theBin] += 1
			count += 1
		EndFor
	EndFor
	
	outWave /= count
	
	SetScale/I x,low,high,outWave
	DoWindow FreqHist
	If(V_flag)
		KillWindow FreqHist
	EndIf
	Display/N=FreqHist outWave as "Frequency Histogram"
	ModifyGraph/W=FreqHist/Z mode=5,rgb=(0,0,0)
End


//Initiates line profile function
Function GetLineProfile()
	Variable/G root:var:activeProfile = 1
	
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	SetDataFolder root:var
	Variable /G root:var:mouseEvent = 0
	
	GetWindow/Z kwTopWin wavelist
	Wave/T WavesOnGraph = W_WaveList
	Wave theWave = $WavesOnGraph[0][1]
	
	GetWindow/Z kwTopWin activeSW
	String/G root:var:graphName = S_Value
	SVAR graphName = root:var:graphName
	String/G root:var:windowName = graphName
	SVAR windowName = root:var:windowName
	
	If(StringMatch(windowName,"*#*"))
		windowName = StringFromList(0,windowName,"#")
	EndIf
	
	Make/O/N=0 root:var:xWave,root:var:yWave,root:var:xWaveIndex,root:var:yWaveIndex
	Wave xWave = root:var:xWave
	Wave yWave = root:var:yWave
	
	String/G root:Packages:analysisTools:startROI
	SVAR startROI = root:Packages:analysisTools:startROI
	startROI = ""
	String/G root:Packages:analysisTools:endROI
	SVAR endROI = root:Packages:analysisTools:endROI
	endROI = ""
	String/G root:Packages:analysisTools:prevROI
	SVAR prevROI = root:Packages:analysisTools:prevROI
	prevROI = ""
	
	SetWindow $windowName, hook(getLineHook)=getLineHook
	return 0
End


//Mouse hook function for line profile function
Function getLineHook(s)
	STRUCT WMWinHookStruct &s
	SVAR graphName = root:var:graphName
	SVAR windowName = root:var:windowName

	NVAR mouseEvent = root:var:mouseEvent
	NVAR activeProfile = root:var:activeProfile
	Wave/T WavesOnGraph = W_WaveList
	
	SVAR startROI = root:Packages:analysisTools:startROI
	SVAR endROI = root:Packages:analysisTools:endROI
	SVAR prevROI = root:Packages:analysisTools:prevROI

	Variable/G root:Packages:analysisTools:distance 
	NVAR distance = root:Packages:analysisTools:distance 
	Wave/T/Z distanceWave = root:Packages:analysisTools:distanceWave

		
	If(DimSize(WavesOnGraph,0))
		Wave theWave = $WavesOnGraph[0][1]
		Variable count = 0
		Do
			Wave theWave = $WavesOnGraph[count][1]
			count+=1
		While(!DimSize(theWave,1))
	EndIf
	
	Variable i
	Variable hookResult = 0
	Wave xWave = root:var:xWave
	Wave yWave = root:var:yWave
	Wave xWaveIndex = root:var:xWaveIndex
	Wave yWaveIndex = root:var:yWaveIndex
	Variable distCols
	
	//Check for cable distance measurement check box.
	ControlInfo/W=analysis_tools distanceOnlyCheck
	Variable distOnly = V_Value
	If(distOnly)
		String/G root:Packages:analysisTools:distDataName
		SVAR distDataName = root:Packages:analysisTools:distDataName
	EndIf
	
	//If 2P Scan Graph, get the actual scan wave instead of the layer projection
	If(cmpstr(windowName,"twoPscanGraph") == 0)
		NVAR curScanNum = root:Packages:twoP:examine:curScanNum
		String scanNumStr
		If(curScanNum < 10)
			scanNumStr = "00" + num2str(curScanNum)
		ElseIf(curScanNum < 100)
			scanNumStr = "0" + num2str(curScanNum)
		Else
			scanNumStr = num2str(curScanNum)
		EndIf
		
		String channel
		Variable ch1,ch2
		ControlInfo/W=analysis_tools ch1Check
		ch1 = V_Value
		If(ch1)
			channel = "ch1"
		EndIf
		
		ControlInfo/W=analysis_tools ch2Check
		ch2 = V_Value
		If(ch2)
			channel = "ch2"
		EndIf
		
		If(!ch1 && !ch2)
			Abort "Since this is from twoPscanGraph, you have to select a channel."
		EndIf
		
		If(ch1 && ch2)
			Abort "Since this is from twoPscanGraph, you can only select a single channel at a time."
		EndIf
		
		String scanName = "root:twoP_Scans:Scan_" + scanNumStr + ":Scan_" + scanNumStr + "_" + channel
		If(WaveExists($scanName))
			Wave theWave = $scanName
		EndIf
	EndIf
	
	switch(s.eventCode)
		case 0:
		//handle activate
			break
		case 1:
		//handle deactivate
			break
		case 4:
		//mouse moved
		If(activeProfile)	//only starts tracing mouse path if the initial starting click has been made (sets activeProfile = 1)
			If(mouseEvent == 1 && activeProfile == 1)
				
				If(DimSize(xWave,0) == 0)
					Redimension/N=(DimSize(xWave,0)+1) xWave
					Redimension/N=(DimSize(yWave,0)+1) yWave
					xWave[DimSize(xWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0)
					yWave[DimSize(yWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1)
					
				Else
					If(ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0) == xWave[DimSize(xWave,0)-1])
						If(ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1) == yWave[DimSize(yWave,0)-1])
							//discards point if movement is sub-pixel
						EndIf
					Else
						
						Redimension/N=(DimSize(xWave,0)+1) xWave
						Redimension/N=(DimSize(yWave,0)+1) yWave
						xWave[DimSize(xWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0)
						yWave[DimSize(yWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1)
			
					EndIf
				EndIf
				//Is the mouse over a new ROI?
				Variable pass = 0
			 If(pass)
				String currentROI = getMouseROI(windowName,theWave,root:ROI_table_filter,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
				If(strlen(currentROI) && strlen(startROI))
					If(cmpstr(currentROI,startROI) != 0)
						If(cmpstr(currentROI,prevROI) != 0)
								Duplicate/FREE xWave,xFree
								Duplicate/FREE yWave,yFree
								For(i=0;i<DimSize(xWave,0);i+=1)
									xFree[i] = IndexToScale(theWave,xWave[i],0)
									yFree[i] = IndexToScale(theWave,yWave[i],1)
								EndFor
							//distance = getLineProfileDistance(xFree,yFree)
							
							//add another row to the distance wave
							Variable distWaveSize = DimSize(distanceWave,0)
							Redimension/N=(distWaveSize+1,2) distanceWave
							//fill with ROI that the mouse is over and its distance from the start
							If(DimSize(xFree,0) > 1)
								distanceWave[distWaveSize][0] = currentROI
								distanceWave[distWaveSize][1] = num2str(getLineProfileDistance(xFree,yFree))
							EndIf					
							//FillDMatrix(startROI,currentROI,distance)
							prevROI = currentROI
						EndIf
					EndIf
				EndIf
				
		     EndIf
				
			EndIf
		EndIf
			break
		case 5:
		//mouse up
		If(activeProfile)	//Stops tracing the mouse path if the path was active (sets activeProfile = 0), otherwise activate the path (sets activeProfile = 1)
			If(mouseEvent == 1)
				mouseEvent = 0
				Redimension/N=(DimSize(xWave,0)-1) xWave,xWaveIndex
				Redimension/N=(DimSize(yWave,0)-1) yWave,yWaveIndex
				activeProfile = 0
				
				xWaveIndex = xWave
				yWaveIndex = yWave
				For(i=0;i<DimSize(xWave,0);i+=1)
					xWave[i] = IndexToScale(theWave,xWave[i],0)
					yWave[i] = IndexToScale(theWave,yWave[i],1)
				EndFor
				
				//Get wave dimensions
				Variable frames = DimSize(theWave,2)
				
				//Take the line profile
				ControlInfo/W=analysis_tools lineProfileWidth
				Variable width = V_Value
				
				//Set data folder to the waves folder
				SetDataFolder GetWavesDataFolder(theWave,1)
				
				
				//Get baseline profile for ∆F/F
				ControlInfo/W=analysis_tools dFLineProfileCheck
				Variable doDF = V_Value
				
				
				
				If(doDF)
					Variable baselineStart,baselineEnd

					ControlInfo/W=analysis_tools bslnStVar
					baselineStart = V_Value
					ControlInfo/W=analysis_tools bslnEndVar
					baselineEnd = V_Value
					
					//Get the baseline portion of the scan
					Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),ScaleToIndex(theWave,baselineEnd,2)-ScaleToIndex(theWave,baselineStart,2)) baselineScan
					//Set scales
					SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
					SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
					SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
					
					baselineScan = theWave[p][q][baselineStart + r]
				
					//line profile the baseline scan
					ImageLineProfile/SC/P=-2 xWave=xWave,yWave=yWave,srcWave=baselineScan,width=width
									
					If(frames)
						Wave baselineProfile = M_ImageLineProfile
						Duplicate/O baselineProfile,M_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = M_ImageBaselineProfile
					Else
						Wave baselineProfile = W_ImageLineProfile
						Duplicate/O baselineProfile,W_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = W_ImageBaselineProfile
					EndIf
					
					//collapse baseline profile, mean over time
					collapseLineProfile(baselineProfile,"avg")
					
				EndIf
				
				
				//Line profile of the scan
				ImageLineProfile/SC/P=-2 xWave=xWave,yWave=yWave,srcWave=theWave,width=width
				
				If(frames)
					Wave theProfile = $(GetWavesDataFolder(theWave,1) + "M_ImageLineProfile")
				Else
					Wave theProfile = $(GetWavesDataFolder(theWave,1) + "W_ImageLineProfile")
				EndIf
				
				//Smooth the profile before collapsing
				ControlInfo/W=analysis_tools SmoothBox
				If(V_Value)
					ControlInfo/W=analysis_tools SmoothFilterVar
					If(DimSize(theProfile,1) > 0 && V_Value != 0)
						Smooth/S=2/DIM=1 V_Value,theProfile
					Else
						//Smooth/S=2 V_Value,theProfile
					EndIf
				EndIf
				
				//Collapse if selected to peak value
				ControlInfo/W=analysis_tools collapseLineProfileCheck
				If(DimSize(theProfile,1) > 0 && V_Value)
					ControlInfo/W=analysis_tools peakStVar
					Variable start = V_Value
					ControlInfo/W=analysis_tools peakEndVar
					Variable stop = V_Value
					collapseLineProfile(theProfile,"max",start=start,stop=stop)
				EndIf
				
				//∆F/F profile
				If(doDF)
					theProfile = (theProfile - baselineProfile)/baselineProfile
					//String dFProfileName = NameOfWave(theProfile) + "_dF"
					//Duplicate/O theProfile,$dFProfileName
					//KillWaves/Z theProfile,baselineProfile
					KillWaves/Z baselineProfile
					//Wave theProfile = $dFProfileName
				EndIf
				
				Variable version = floor(IgorVersion())
			
				//Rename line profile
				String lineProfileName = NameOfWave(theWave) + "_lineProfile"
			
				If(version > 7)
					String displacementProfileName = NameOfWave(theWave) + "_lineDisp"
			
					If(doDF)
						displacementProfileName += "_dF"
					EndIf	
			
					//Rename displacement profile wave for Igor 8
					If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
						Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
						Duplicate/O lineProfileDisp,$displacementProfileName
						KillWaves/Z lineProfileDisp
						Wave lineProfileDisp = $displacementProfileName
					EndIf
				EndIf
			
				//Different output wave names depending on 2D or 3D profile
				frames = DimSize(theWave,2)
				If(frames)
					String outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
				Else
					outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
				EndIf
				
				//Rename line profile wave
				lineProfileName = NameOfWave(theWave) + "_LP"
				
				If(doDF)
					lineProfileName += "_dF"
				EndIf
				
				If(WaveExists($outputProfileName))
					Wave lineProfile = $outputProfileName
					Duplicate/O lineProfile,$lineProfileName
					KillWaves/Z lineProfile
				EndIf	
		
				wave theProfile = $lineProfileName
				
				//Append the line profile path to the graph
				String xAxis,yAxis,info,flags
				info = ImageInfo(graphName,NameOfWave(theWave),0)
				xAxis = StringByKey("XAXIS",info,":",";")
				yAxis = StringByKey("YAXIS",info,":",";")
				flags = StringByKey("AXISFLAGS",info,":",";")
				
				info = TraceInfo(graphName,"W_LineProfileY",0)
				
				If(!strlen(info))	
					wave lineX = W_LineProfileX
					wave lineY = W_LineProfileY
					
					If(cmpstr(windowName,"twoPscanGraph")==0)
						ControlInfo/W=twoP_Controls CH1Check
						ch1 = V_Value
						ControlInfo/W=twoP_Controls CH2Check
						ch2 = V_Value
						
						If(ch1 && ch2)
							channel = "#GCH2"
						ElseIf(ch1)
							channel = "#GCH1"
						Else
							channel = "#GCH2"
						EndIf
						windowName = "twoPscanGraph" + channel
					EndIf
					
					If(StringMatch(flags,"*/R*") && StringMatch(flags,"*/T*"))
						AppendToGraph/W=$windowName/R=$yAxis/T=$xAxis lineY vs lineX
					ElseIf(StringMatch(flags,"*/R*"))
						AppendToGraph/W=$windowName/R=$yAxis lineY vs lineX
					ElseIf(StringMatch(flags,"*/T*"))
						AppendToGraph/W=$windowName/T=$xAxis lineY vs lineX
					Else
						AppendToGraph/W=$windowName lineY vs lineX
					EndIf
				EndIf

				//Display the line profile versus displacement
				DoWindow LineProfileGraph
				If(V_flag)
					KillWindow/Z LineProfileGraph
				EndIf
				
				If(version < 8)
					If(DimSize(theProfile,1) > 0)
					//	NewImage/N=LineProfileGraph theProfile
					Else
					//	Display/N=LineProfileGraph theProfile as "Line Profile"
					EndIf
				Else
					If(DimSize(theProfile,1) > 0)
						NewImage/N=LineProfileGraph theProfile
					Else
						Display/N=LineProfileGraph theProfile vs lineProfileDisp as "Line Profile"
					EndIf
				EndIf
		
				SetWindow $windowName, hook(getLineHook)=$""
				
				//Sets the ending ROI name and the distance between the start/end ROIs
				If(distOnly)
					Wave/T distData = $distDataName
					String mouseROI = getMouseROI(windowName,theWave,root:ROI_table_filter,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
					endROI = mouseROI
				//	print "End: " + mouseROI
				//	distData[0][DimSize(distData,1) - 1] = mouseROI
				//	distData[1][DimSize(distData,1) - 1] = num2str(WaveMax(lineProfileDisp)*3.3) //3.3 scale factor for Varsha's recordings.
					
					If(DimSize(xFree,0) > 1)
						distance = getLineProfileDistance(xFree,yFree)
					EndIf					
				//	If(strlen(startROI) && strlen(endROI))
				//		FillDMatrix(startROI,endROI,distance)
				//	EndIf
				//	print distance
					Wave filterTable = root:ROI_table_filter
					FillDMatrix(distanceWave,filterTable)
				EndIf
				
				
			ElseIf(mouseEvent == 0)
				mouseEvent = 1
				
				//Make the cable distance between ROIs data wave
				ControlInfo/W=analysis_tools distanceOnlyCheck
				distOnly = V_Value
				
				Make/N=(1,2)/O/T root:Packages:analysisTools:distanceWave
				Wave/T distanceWave = root:Packages:analysisTools:distanceWave
				
				If(distOnly)
					mouseROI = getMouseROI(windowName,theWave,root:ROI_table_filter,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
				//	print "Start: " + mouseROI
					
					
					startROI = mouseROI
					If(strlen(startROI))
						distanceWave[0][0] = startROI
						distanceWave[0][1] = num2str(0)
					EndIf
					
					distDataName = "root:ROI_analysis:distData" + "_" + mouseROI
					If(!WaveExists($distDataName))
						Make/O/T/N=(2,1) $distDataName
						//2 rows
						//Name of Wave: start ROI name
						//R0: end ROI name
						//R1: cable distance between those ROIs
						//columns will be added for each new ending ROI for a given starting ROI
					Else
						//add a column
						Wave/T distData = $distDataName
						Redimension/N=(2,DimSize($distDataName,1) + 1) $distDataName
					EndIf
				EndIf
					//reset ROI strings
				prevROI = ""
				currentROI = ""
			EndIf
		
						
		EndIf
		break
	endswitch
	
	return hookResult

End

Function FillDMatrix(distanceWave,filterTable)
	Wave/T distanceWave,filterTable
	
	Wave/T roiTable = root:ROI_table
	Wave dMatrix = root:ROI_dist_matrix
		
	Variable numFilterROIs = DimSize(filterTable,0)
	Variable numROIs = DimSize(roiTable,0)
	Variable i,j,length,row,col
	String ROIList = ""
	String filterROIList = ""
	
	//Make list for the ROI table
	For(i=0;i<numROIs;i+=1)
		ROIList += roiTable[i] + ";"
	EndFor
	For(i=0;i<numFilterROIs;i+=1)
		filterROIList += filterTable[i] + ";"
	EndFor
	
	ROIList = RemoveEnding(ROIList,";")
	filterROIList = RemoveEnding(filterROIList,";")
	
	length = DimSize(distanceWave,0)
	
	For(i=0;i<length;i+=1)
		
		For(j=0;j<length;j+=1)
		
			row = WhichListItem(distanceWave[i][0],ROIList,";")	//start ROI
			col = WhichListItem(distanceWave[j][0],ROIList,";")	//end ROI
			
			//Is it in the filtered list?
			Variable isPresent = WhichListItem(distanceWave[i][0],filterROIList,";")
			If(isPresent == -1)
				continue
			Else
				isPresent = WhichListItem(distanceWave[j][0],filterROIList,";")
				If(isPresent == -1)
					continue
				EndIf
			EndIf
			
			If(row == -1 || col == -1)
				continue
			Else
				dMatrix[row][col] = abs(str2num(distanceWave[j][1]) - str2num(distanceWave[i][1])) //Fill out matrix
				dMatrix[col][row] = abs(str2num(distanceWave[j][1]) - str2num(distanceWave[i][1])) //and reciprocal matrix cell
			EndIf
		EndFor
	EndFor
	
End

Function fillROITable(roiTable)
	Wave/T roiTable
	
	Variable i
	For(i=0;i<155;i+=1)
		roiTable[i] = "grid" + num2str(i)
	EndFor
End

//Get the name of the nearest ROI from the mouse position
Function/S getMouseROI(theWindow,scanWave,roiTable,ROIx,ROIy)
	String theWindow
	Wave scanWave
	Wave/T roiTable
	Wave ROIx,ROIy
	Variable xPos,yPos,distance,i,minDist
	String theROI
	
	minDist = 0
	
	If(cmpstr(theWindow,"twoPscanGraph") == 0)
		theWindow += "#GCH2"
	EndIf
	
	getCenter(roiTable,"root:twoP_ROIS")
	
	GetMouse/W=$theWindow
	xPos = AxisValFromPixel(theWindow,"Bottom",V_left)
	yPos = AxisValFromPixel(theWindow,"Left",V_top)
	
	//Index values for the mouse position
	Variable xIndex = ScaleToIndex(scanWave,xPos,0)
	Variable yIndex = ScaleToIndex(scanWave,yPos,1)
	
	For(i=0;i<NumPnts(roiTable);i+=1)
		//ROI mask wave
		Wave roiXboundary = $("root:twoP_ROIS:" + roiTable[i] + "_x")
		Wave roiYboundary = $("root:twoP_ROIS:" + roiTable[i] + "_y")
		ImageBoundaryToMask ywave=roiYboundary,xwave=roiXboundary,width=(dimSize(scanWave,0)),height=(dimSize(scanWave,1)),scalingwave=scanWave,seedx=dimOffset(scanWave,0),seedy=dimOffset(scanWave,1)
		String foldername = GetDataFolder(1)
		WAVE ROIMask = $(foldername + "M_ROIMask")	

		If(ROIMask[xIndex][yIndex] == 0)
			theROI = roiTable[i]
		EndIf
	EndFor
	
//	For(i=0;i<NumPnts(roiTable);i+=1)
//		distance = sqrt((ROIy[i] - yPos)^2 + (ROIx[i] - xPos)^2)
//		If(minDist == 0)
//			minDist = distance
//		ElseIf(distance < minDist)
//			minDist = distance
//			theROI = roiTable[i]  
//		EndIf
//	EndFor
	If(strlen(theROI))
		return theROI
	Else
		return ""
	EndIf
End

//Gets list of line profile waves
Function/S getSavedLineProfileList()	
	String folder = "root:var:LineProfiles"
	String profileList
	String saveDF = GetDataFolder(1)
	
	
	If(!varFolderExists())
		NewDataFolder root:var
	EndIf
	
	If(!DataFolderExists(folder))
		NewDataFolder $folder
	EndIf
	SetDatafolder $folder 
	
	If(!DataFolderExists(folder))
		profileList = "None"
	Else
		profileList = WaveList("LineProfileY*",";","")
	EndIf
	
	If(!strlen(profileList))
		profileList = "None"
	EndIf
	SetDataFolder $saveDF
	return profileList
End

Function varFolderExists()
	If(DataFolderExists("root:var"))
		return 1
	Else
		return 0
	EndIf
End

//Saves line profile waves as template
Function saveLineProfile()

	String saveDF = GetDataFolder(1)
	String folder = "root:var:LineProfiles"
	If(!DataFolderExists(folder))
		NewDataFolder $folder
	EndIf
	SetDatafolder $folder
	
	Wave xProfile = root:var:xWave
	Wave yProfile = root:var:yWave
	
	If(WaveExists(root:var:xWave))
		Wave xProfile = root:var:xWave
	Else
		Abort "Profile wave does not exist"
	EndIf
	
	If(WaveExists(root:var:yWave))
		Wave yProfile = root:var:yWave
	Else
		Abort "Profile wave does not exist"
	EndIf
	
	//Get output names for the saved line profiles
	String xName,yName
	ControlInfo/W=analysis_tools saveLineProfileSuffix
	If(!strlen(S_Value))
		xName = UniqueName("LineProfileX_",1,0)
		yName = ReplaceString("LineProfileX",xName,"LineProfileY")
	Else
		xName = "LineProfileX_" + S_Value
		yName = "LineProfileY_" + S_Value
	EndIf
	//Move and rename the profile waves
	MoveWave xProfile,$(folder + ":" + xName)
	MoveWave yProfile,$(folder + ":" + yName)
	
	SetDataFolder $saveDF
//	String profileList = getSavedProfileList()
	PopUpMenu lineProfileTemplatePopUp win=analysis_tools,value=getSavedLineProfileList()
	ControlUpdate/W=analysis_tools lineProfileTemplatePopUp
End

Function applyLineProfile()
	String saveDF = GetDataFolder(1)
	Variable i,j,version,ch1,ch2,numChannels,frames
	String lineProfileName,displacementProfileName,channel,outputProfileName
	
	//Get Igor version
	version = floor(IgorVersion())
	
	//Get channels
	ControlInfo/W=analysis_tools ch1Check
	ch1 = V_Value
	ControlInfo/W=analysis_tools ch2Check
	ch2 = V_Value
	
	If(ch1 && ch2)
		numChannels = 2
	ElseIf(ch1 || ch2)
		numChannels = 1
	EndIf
	
	//Get line profile width
	ControlInfo/W=analysis_tools lineProfileWidth
	Variable width = V_Value
	
	//Get line profile waves
	ControlInfo/W=analysis_tools lineProfileTemplatePopUp
	String yProfileName = S_Value
	String xProfileName = ReplaceString("LineProfileY",yProfileName,"LineProfileX")
	Wave xProfile = $("root:var:LineProfiles:" + xProfileName)
	Wave yProfile = $("root:var:LineProfiles:" + yProfileName)
	
	ControlInfo/W=analysis_tools useScanListCheck
	If(V_Value)
	//Use Scan List
		SVAR scanListStr = root:Packages:twoP:examine:scanListStr
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
			For(j=0;j<numChannels;j+=1)
				If(numChannels == 1 && ch1)
					channel = "ch1"
				ElseIf(numChannels == 1 && ch2)
					channel = "ch2"
				ElseIf(numChannels == 2)
					channel = "ch" + num2str(j + 1)
				EndIf
				
				Wave theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_" + channel)
				SetDataFolder GetWavesDataFolder(theWave,1)
				
				//Get baseline profile for ∆F/F
				ControlInfo/W=analysis_tools dFLineProfileCheck
				Variable doDF = V_Value
				
				If(doDF)
					Variable baselineStart,baselineEnd

					ControlInfo/W=analysis_tools bslnStVar
					baselineStart = V_Value
					ControlInfo/W=analysis_tools bslnEndVar
					baselineEnd = V_Value
					
					//Get the baseline portion of the scan
					Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),baselineEnd-baselineStart) baselineScan
					baselineScan = theWave[p][q][baselineStart + r]
					//Set Scales
					SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
					SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
					SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
					
					//Set data folder to the waves folder
					SetDataFolder GetWavesDataFolder(theWave,1)
					
					//line profile the baseline scan
					ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=baselineScan,width=width
					frames = DimSize(theWave,2)
					If(frames)
						Wave baselineProfile = M_ImageLineProfile
						Duplicate/O baselineProfile,M_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = M_ImageBaselineProfile
					Else
						Wave baselineProfile = W_ImageLineProfile
						Duplicate/O baselineProfile,W_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = W_ImageBaselineProfile
					EndIf
					
					//Collapse if selected to mean baseline
					collapseLineProfile(baselineProfile,"avg")
				
				EndIf
				
				
				ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=theWave,width=width
				
				//Rename the displacement wave for Igor 8
				If(version > 7)
					displacementProfileName = NameOfWave(theWave) + "_lineDisp"
					
					If(doDF)
						displacementProfileName += "_dF"
					EndIf
					
					//Rename displacement profile wave for Igor 8
					If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
						Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
						Duplicate/O lineProfileDisp,$displacementProfileName
						KillWaves/Z lineProfileDisp
					EndIf
				EndIf
			
				//Different output wave names depending on 2D or 3D profile
				frames = DimSize(theWave,2)
				If(frames)
					outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
				Else
					outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
				EndIf
				
				//Rename line profile wave
				lineProfileName = NameOfWave(theWave) + "_lineProfile"
				
				If(doDF)
					lineProfileName += "_dF"
				EndIf
				
				If(WaveExists($outputProfileName))
					Wave lineProfile = $outputProfileName
					Duplicate/O lineProfile,$lineProfileName
					KillWaves/Z lineProfile
				EndIf	
				
				wave theProfile = $lineProfileName
				
				//Smooth the profile before collapsing
				ControlInfo/W=analysis_tools SmoothBox
				If(V_Value)
					ControlInfo/W=analysis_tools SmoothFilterVar
					If(DimSize(theProfile,1) > 0 && V_Value != 0)
						Smooth/S=2/DIM=1 V_Value,theProfile
					Else
					//	Smooth/S=2 V_Value,theProfile
					EndIf
				EndIf
				
				//Collapse 2D profile to 1D max projection
				ControlInfo/W=analysis_tools collapseLineProfileCheck
				If(V_Value && frames)
					ControlInfo/W=analysis_tools peakStVar
					Variable start = V_Value
					ControlInfo/W=analysis_tools peakEndVar
					Variable stop = V_Value
					collapseLineProfile(theProfile,"max",start=start,stop=stop)
				EndIf
				
				//∆F/F profile
				If(doDF)
					theProfile = (theProfile - baselineProfile)/baselineProfile
					//String dFProfileName = NameOfWave(theProfile) + "_dF"
					//Duplicate/O theProfile,$dFProfileName
					//KillWaves/Z theProfile,baselineProfile
				//	Wave theProfile = $dFProfileName
				EndIf
				
			EndFor
		EndFor
	Else
	//Use top graph
		//Bring selected graph to the front
		ControlInfo/W=analysis_tools SR_WaveList
		DoWindow/F $S_Value
		
		//If 2P Scan Graph, get the actual scan wave instead of the layer projection
		
		If(cmpstr(S_Value,"twoPscanGraph") == 0)
			NVAR curScanNum = root:Packages:twoP:examine:curScanNum
			String scanNumStr
			If(curScanNum < 10)
				scanNumStr = "00" + num2str(curScanNum)
			ElseIf(curScanNum < 100)
				scanNumStr = "0" + num2str(curScanNum)
			Else
				scanNumStr = num2str(curScanNum)
			EndIf
		
		
			ControlInfo/W=analysis_tools ch1Check
			ch1 = V_Value
			If(ch1)
				channel = "ch1"
			EndIf
		
			ControlInfo/W=analysis_tools ch2Check
			ch2 = V_Value
			If(ch2)
				channel = "ch2"
			EndIf
		
			If(!ch1 && !ch2)
				Abort "Since this is from twoPscanGraph, you have to select a channel."
			EndIf
		
			If(ch1 && ch2)
				Abort "Since this is from twoPscanGraph, you can only select a single channel at a time."
			EndIf
		
			String scanName = "root:twoP_Scans:Scan_" + scanNumStr + ":Scan_" + scanNumStr + "_" + channel
			If(WaveExists($scanName))
				Wave theWave = $scanName
			EndIf
		Else
			//Get wave name from selected graph
			GetWindow/Z kwTopWin wavelist
			Wave/T WavesOnGraph = W_WaveList
			Wave theWave = $WavesOnGraph[0][1]
		EndIf
		
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		//Get baseline profile for ∆F/F
		ControlInfo/W=analysis_tools dFLineProfileCheck
		doDF = V_Value
		If(doDF)

			ControlInfo/W=analysis_tools bslnStVar
			baselineStart = V_Value
			ControlInfo/W=analysis_tools bslnEndVar
			baselineEnd = V_Value
					
			//Get the baseline portion of the scan
			Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),baselineEnd-baselineStart) baselineScan
			baselineScan = theWave[p][q][baselineStart + r]
			//Set Scales
			SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
			SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
			SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
					
			//Set data folder to the waves folder
			SetDataFolder GetWavesDataFolder(theWave,1)
					
			//line profile the baseline scan
			ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=baselineScan,width=width
			
			frames = DimSize(theWave,2)		
			If(frames)
				Wave baselineProfile = M_ImageLineProfile
				Duplicate/O baselineProfile,M_ImageBaselineProfile
				KillWaves/Z baselineProfile
				Wave baselineProfile = M_ImageBaselineProfile
			Else
				Wave baselineProfile = W_ImageLineProfile
				Duplicate/O baselineProfile,W_ImageBaselineProfile
				KillWaves/Z baselineProfile
				Wave baselineProfile = W_ImageBaselineProfile
			EndIf
					
			//Collapse to mean baseline
			collapseLineProfile(baselineProfile,"avg")
		EndIf

		ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=theWave,width=width
		
		//Rename line profile
		lineProfileName = NameOfWave(theWave) + "_LP"
			
		If(version > 7)
			displacementProfileName = NameOfWave(theWave) + "_LD"
			
			If(doDF)
				displacementProfileName += "_dF"
			EndIf	
			
			//Rename displacement profile wave for Igor 8
			If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
				Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
				Duplicate/O lineProfileDisp,$displacementProfileName
				KillWaves/Z lineProfileDisp
			EndIf
		EndIf
			
		//Different output wave names depending on 2D or 3D profile
		frames = DimSize(theWave,2)
		If(frames)
			outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
		Else
			outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
		EndIf
				
		//Rename line profile wave
		lineProfileName = NameOfWave(theWave) + "_LP"
				
		If(doDF)
			lineProfileName += "_dF"
		EndIf
				
		If(WaveExists($outputProfileName))
			Wave lineProfile = $outputProfileName
			Duplicate/O lineProfile,$lineProfileName
			KillWaves/Z lineProfile
		EndIf	
		
		wave theProfile = $lineProfileName
		
		
		//Smooth the profile before collapsing
		ControlInfo/W=analysis_tools SmoothBox
		If(V_Value)
			ControlInfo/W=analysis_tools SmoothFilterVar
			If(DimSize(theProfile,1) > 0 && V_Value != 0)
				Smooth/S=2/DIM=1 V_Value,theProfile
			ElseIf(V_Value != 0)
				//Smooth/S=2 V_Value,theProfile
			EndIf
		EndIf
		
		//Collapse 2D profile to 1D max projection
		ControlInfo/W=analysis_tools collapseLineProfileCheck
		If(V_Value && frames)
			ControlInfo/W=analysis_tools peakStVar
			start = V_Value
			ControlInfo/W=analysis_tools peakEndVar
			stop = V_Value
			collapseLineProfile(theProfile,"max",start=start,stop=stop)
		EndIf
				
		//∆F/F profile
		If(doDF)
			theProfile = (theProfile - baselineProfile[p][0])/baselineProfile[p][0]
			//String dFProfileName = NameOfWave(theProfile) + "_dF"
			//Duplicate/O theProfile,$dFProfileName
			//KillWaves/Z theProfile,baselineProfile
			//	Wave theProfile = $dFProfileName
		EndIf
		
		KillWaves/Z WavesOnGraph	
		
	EndIf
	
	
End

Function collapseLineProfile(theProfile,type,[start,stop])
	wave theProfile
	String type
	Variable start,stop
	Variable i
	
	Make/FREE/N=(DimSize(theProfile,1)) theCol
	
	If(ParamIsDefault(start))
		start = 0
	EndIf
	
	If(ParamIsDefault(stop))
		stop = DimSize(theProfile,1)
	EndIf
	
	For(i=start;i<stop;i+=1)
		theCol[] = theProfile[i][p]
		If(cmpstr(type,"max") == 0)
			theProfile[i] = WaveMax(theCol)
		ElseIf(cmpstr(type,"avg") == 0)
			theProfile[i] = Mean(theCol)
		EndIf
	EndFor
	
	//MatrixOP/FREE maxProj = maxRows(theProfile) 
	Redimension/N=(-1,0) theProfile
	//theProfile = maxProj
End

//Takes the distData waves, and correlates each ROI over trials with the ROIs in its distData wave. 
//Appends that correlation value to the end of the distData wave
Function correlateDistData()
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i,j,k,m,numROI
	String startROI,startDataList
	
	numROI = ItemsInList(ROIListStr,";")
	
  //Loop through angles
  For(m=0;m<8;m+=1)
	
	//Loop through reference ROIs
	For(i=0;i<numROI;i+=1)
		//Get the distData wave for each reference ROI
		startROI = StringFromList(i,ROIListStr,";")
		Wave/T distData = $("root:ROI_analysis:distData_" + startROI)
		
		If(!WaveExists(distData))
			//go to next ROI if there is no distData
			continue
		EndIf
		
		//Get the DStuning plots for each ROI
		SetDataFolder root:ROI_analysis:Values
		startDataList = WaveList("DStuning_c100_*ROI" + startROI + "*",";","DIMS:1")
		
		Variable repeats = ItemsInList(startDataList,";")
		//this holds the trial to trial amplitudes 
		Make/FREE/N=(repeats) tempStart = 0
		Make/FREE/N=(repeats) tempEnd = 0
		
		//Loop through end ROIs
		For(k=0;k<DimSize(distData,1);k+=1)
			//Matches the end ROI wave 
			String endDataList = WaveList("DStuning_c100_*ROI" + distData[0][k] + "*",";","DIMS:1")
			
			//Loop through the number of repeats per ROI to build the trial-to-trial amplitude waves to be correlated
			For(j=0;j<repeats;j+=1)
				Wave startData = $StringFromList(j,startDataList)
				Wave endData = $StringFromList(j,endDataList)
				tempStart[j] = startData[m]	//using only 1 angle for now.
				tempEnd[j] = EndData[m]
			EndFor
			
			//Make the x and y waves to hold the distance values (X), and the correlation values (Y)
			Make/O/N=(DimSize(distData,1)) $(NameOfWave(distData) + "_corrY_" + num2str(m)),$(NameOfWave(distData) + "_corrX_" + num2str(m))
			Wave corrY = $(NameOfWave(distData) + "_corrY_" + num2str(m))
			Wave corrX = $(NameOfWave(distData) + "_corrX_" + num2str(m))
			
			StatsLinearCorrelationTest/Q/Z tempStart,tempEnd
			Wave corrWave = W_StatsLinearCorrelationTest
			
			If(!WaveExists(corrWave))
				Abort "Can't find correlation output wave"
			EndIf
			
			//Get the correlation coefficient R
			corrY[k] = corrWave[1]
			corrX[k] = str2num(distData[1][k])
			
		EndFor
	EndFor
	
	//Concatenate the correlation/distance waves into a single wave
	String theListY = WaveList("distData*corrY*" + num2str(m),";","DIMS:1")
	String theListX = WaveList("distData*corrX*" + num2str(m),";","DIMS:1")
	Concatenate/NP/O theListY,$("distData_corrY_" + num2str(m))
	Concatenate/NP/O theListX,$("distData_corrX")
  EndFor

End

//Segments an ROI mask into specified sized sub-ROIs
Function OpenMask(theMask)
	Wave theMask
	NewImage/N=ROI_Image theMask
End

//
Function SegmentROIMap()
	
	//size of each ROI segment
	Variable pixelsPerSegment = 30
	
	Variable xPoint = hcsr(A,"ROI_Image")
	Variable yPoint = vcsr(A,"ROI_Image")

End

//Actually this just acquires the parameters needed to register an image.
//Use this function to register a max projection of the channel of interest.
//Then select the created parameter wave in the tempate list, and apply the template to...
//other test images or scans from the scan list box.

Function GetRegistrationParameters()
	Variable offsetX,offsetY,dX,dY,useScanList,i
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	//Get the channel
	String channel = RemoveEnding(getChannel(1),";")
	
	//Get the reference image	
	ControlInfo/W=analysis_tools refImagePopUp
	Wave refImage = $("root:twoP_Scans:" + S_Value + ":" + S_Value + "_" + channel)
		
	//Get the reference image offsets and deltas
	offsetX = DimOffset(refImage,0)
	offsetY = DimOffset(refImage,1)
	dX = DimDelta(refImage,0)
	dY = DimDelta(refImage,1)
	
	//Max project the reference wave. This will be the wave actually operated on
	//to get the regstration parameters.
	MatrixOP/O/FREE refMaxProj = sumBeams(refImage)
	SetScale/P x,offsetX,dX,refMaxProj
	SetScale/P y,offsetY,dY,refMaxProj
	Redimension/S refMaxProj

	ControlInfo/W=analysis_tools useScanListCheck
	useScanList = V_Value
	
	If(useScanList)
		String testImageList = scanListStr
	Else
		ControlInfo/W=analysis_tools testImagePopUp
		testImageList = S_Value
	EndIf
	
	//Register the images
	For(i=0;i<ItemsInList(testImageList,";");i+=1)
		String theWaveName = StringFromList(i,testImageList,";")
		Wave testImage = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel)
		//Max project the test wave
		MatrixOP/O/FREE testMaxProj = sumBeams(testImage)
		SetScale/P x,offsetX,dX,testMaxProj
		SetScale/P y,offsetY,dY,testMaxProj
		Redimension/S testMaxProj
		
		SetDataFolder GetWavesDataFolder(testImage,1)
		ImageRegistration/REFM=0/TSTM=0/TRNS={1,1,0}/CONV=1/Q testWave=testMaxProj,refWave=refMaxProj
		Wave param = W_RegParams
		If(!WaveExists(param))
			Abort "Cannot find the registration parameter wave."
		Else
			Redimension/N=7 param
			param[3] = offsetX;SetDimLabel 0,3,'X Offset',param
			param[4] = offsetY;SetDimLabel 0,4,'Y Offset',param
			param[5] = dX;SetDimLabel 0,5,dX,param
			param[6] = dY;SetDimLabel 0,6,dY,param
		EndIf
	EndFor
	
	Wave regWave = M_RegMaskOut
	KillWaves/Z regWave
	Wave regWave = M_RegOut
	KillWaves/Z regWave
End

//Returns the name of the checked channel
//Only allows a single channel to be checked at once.
Function/S getChannel(onlyOne)
	Variable onlyOne
	
	ControlInfo/W=analysis_tools ch1check
	If(V_Value)
		String channel="ch1;"
	Else
		channel = ""
	EndIf
	
	ControlInfo/W=analysis_tools ch2check

	If(cmpstr(channel,"ch1;") == 0 && V_Value == 1)
		If(onlyOne)
			Abort "Only select a single channel"
		Else
			channel += "ch2;"
		EndIf
	ElseIf(V_Value)
		channel = "ch2;"
	EndIf
	
	ControlInfo/W=analysis_tools ratioCheck
	If(V_Value)
		If(stringmatch(channel,"*ch1*") || stringmatch(channel,"*ch2*"))
			If(onlyOne)
				Abort "Only select a single channel"
			Else
				channel += "ratio"
			EndIf
		Else
			channel = "ratio"
		EndIf
	EndIf
	
	If(!strlen(channel))
		Abort "Must select a channel"
	EndIf

	return channel
End

//Takes image registration parameters and applies them to other images
Function applyImageRegTemplate()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable xDelta,yDelta,applyOffsetX,applyOffsetY,useScanList,i,j
	
	//Get the selected parameter wave
	ControlInfo/W=analysis_tools registrationTemplatePopUp
	Wave param = $("root:twoP_Scans:" + S_Value)
	If(!WaveExists(param))
		Abort "Couldn't find the parameter wave."
	EndIf
	
	xDelta = round(param[0])
	yDelta = round(param[1])
	
	ControlInfo/W=analysis_tools useScanListCheck
	useScanList = V_Value
	
	//Get the channel
	String channel = getChannel(0)
	For(j=0;j<ItemsInList(channel,";");j+=1)
		//if two channels are checked, it loops through both channels
		String currentChannel = StringFromList(j,channel,";")
		
		If(useScanList)
			String testImageList = scanListStr
		Else
			ControlInfo/W=analysis_tools testImagePopUp
			testImageList = "root:twoP_Scans:" + S_Value + ":" + S_Value + "_" + currentChannel
		EndIf
	
		For(i=0;i<ItemsInList(testImageList,";");i+=1)
			If(useScanList)
				Wave testImage = $("root:twoP_Scans:" + StringFromList(i,testImageList,";") + ":" + StringFromList(i,testImageList,";")) + "_" + currentChannel
			Else
				Wave testImage = $StringFromList(i,testImageList,";")
			EndIf
			
			If(useScanList)
				Wave/Z param = $("root:twoP_Scans:" + StringFromList(i,testImageList,";") + ":W_RegParams")
				If(!WaveExists(param))
					continue
				EndIf
				xDelta = round(param[0])
				yDelta = round(param[1])
			EndIf
					
			//Check if wave has been tagged, indicating that it already has been registered.
			Variable tagPresent = CheckTag(testImage,0,0,4,99)
			If(tagPresent)
			//	continue
			EndIf
			Variable theMean = mean(testImage)
			
			If(xDelta < 0)
				DeletePoints/M=0 0,-xDelta,testImage
				InsertPoints/M=0 DimSize(testImage,0),-xDelta,testImage
				//testImage[DimSize(testImage,0)+xDelta,DimSize(testImage,0)-1][] = testImage[p+xDelta][q]
				//inserted points become noise around the mean signal
				testImage[DimSize(testImage,0)+xDelta,DimSize(testImage,0)-1][] = theMean + gnoise(0.05*theMean)
			ElseIf(xDelta > 0)
				InsertPoints/M=0 0,xDelta,testImage
				DeletePoints/M=0 DimSize(testImage,0)-xDelta,xDelta,testImage
				//testImage[0,xDelta-1][] = testImage[p+xDelta][q]
				testImage[0,xDelta-1][] = theMean + gnoise(0.05*theMean)
			EndIf
		
			If(yDelta < 0)
				DeletePoints/M=1 0,-yDelta,testImage
				InsertPoints/M=1 DimSize(testImage,1),-yDelta,testImage
				//testImage[][DimSize(testImage,1)+yDelta,DimSize(testImage,1)-1] = testImage[p][q+yDelta]
				testImage[][DimSize(testImage,1)+yDelta,DimSize(testImage,1)-1] = theMean + gnoise(0.05*theMean)
			ElseIf(yDelta > 0)
				InsertPoints/M=1 0,yDelta,testImage
				DeletePoints/M=1 DimSize(testImage,1)-yDelta,yDelta,testImage
				//testImage[][0,yDelta-1] = testImage[p][q+yDelta]
				testImage[][0,yDelta-1] = theMean + gnoise(0.05*theMean)
			EndIf
			TagWave(testImage,0,0,4,99)
		EndFor
	EndFor
End

//Gets a list of waves inside the twoP_Scans folder and all of its subfolders
Function/S getWaveList(matchStr)
	String matchStr
	String theList,theFolder,saveDF,listItem
	theList = ""
	
	saveDF = GetDataFolder(1)
	
	Variable numFolders = CountObjects("root:twoP_Scans",4)
	Variable i
	
	For(i=0;i<numFolders;i+=1)
		theFolder = GetIndexedObjName("root:twoP_Scans",4,i)
		SetDataFolder $("root:twoP_Scans:" + theFolder)
		listItem = WaveList(matchStr,";","")
		If(strlen(listItem))
			theList += theFolder + ":" + listItem + ";"
		EndIf
	EndFor
	
	return theList
End

//Puts a defined value onto an image wave in the specified location.
//This will allow me to check whether the wave has been tagged or not
//during analysis.
Function TagWave(theWave,startRow,startCol,numRows,tagValue)
	Wave theWave
	Variable startRow,startCol,numRows,tagValue
	Variable i
	
	For(i=0;i<numRows;i+=1)
		theWave[startRow + i][startCol] = tagValue
	EndFor
End

//Checks if a wave has been tagged in the specified location with..
//the tagValue
Function CheckTag(theWave,startRow,startCol,numRows,tagValue)
	Wave theWave
	Variable startRow,startCol,numRows,tagValue
	Variable i,tagPresent
	
	For(i=0;i<numRows;i+=1)
		If(theWave[startRow + i][startCol] == tagValue)
			tagPresent = 1
		Else
			tagPresent = 0
		EndIf
	EndFor
	return tagPresent
End

//Goes through a wave set and finds the offsets incurred from image registration.
//Then it redimensions all the waves to eliminate rows/cols that have been created as buffers during image registration. 
Function EqualizeDimensions()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable minX,maxX,minY,maxY,i,j,buffer,row,col,sizeX,sizeY
	
	String channel = getChannel(0)
	
	For(j=0;j<ItemsInList(channel,";");j+=1)
		//Set the initial dimensions of the images using the first wave in the wave set
		String currentChannel = StringFromList(j,channel,";")
		String theWaveName = StringFromList(0,scanListStr,";") 
		Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
		
		minX = 0
		minY = 0
		sizeX = DimSize(theWave,0) - 1
		sizeY = DimSize(theWave,1) - 1
		maxX = sizeX
		maxY = sizeY
			
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
			//Get the channel and the image wave
			currentChannel = StringFromList(j,channel,";")
			theWaveName = StringFromList(i,scanListStr,";") 
			Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
		
			//check if wave exists
			If(!WaveExists(theWave))
				Abort "Couldn't find the wave: " + NameOfWave(theWave)
			EndIf
	
			//check row buffers at beginning of image
			row = 0
			col = 0
			Do
				//checks the value at each row 15 columns in, to prevent false positives from buffered columns 
				buffer = theWave[row][15]
				row += 1
			While(buffer == 0)
			
			If(row > minX)
				minX = row - 1
			EndIf
			
			//check row buffers at end of image
			row = DimSize(theWave,0) - 1
			Do
				buffer = theWave[row][15]
				row -= 1
			While(buffer == 0)
			
			If(row < maxX)
				maxX = row + 1
			EndIf
			
			//check row buffers at beginning of image
			row = 0
			col = 0
			Do
				buffer = theWave[15][col]
				col += 1
			While(buffer == 0)
			
			If(col > minY)
				minY = col - 1
			EndIf
			
			//check row buffers at end of image
			col = DimSize(theWave,1) - 1
			Do
				buffer = theWave[15][col]
				col -= 1
			While(buffer == 0)
			
			If(col < maxY)
				maxY = col + 1
			EndIf
		EndFor
		
		//Perform redimensioning
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
		
			//Get the channel and the image wave
			currentChannel = StringFromList(j,channel,";")
			theWaveName = StringFromList(i,scanListStr,";") 
			Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
			
			Variable deleteMin,deleteMax
			
			//Redimension in X
			deleteMin = minX
			deleteMax = sizeX - maxX
			DeletePoints/M=0 0,deleteMin,theWave
			DeletePoints/M=0 maxX+1,deleteMax,theWave
		
			//Redimension in Y
			deleteMin = minY
			deleteMax = sizeY - maxY
			DeletePoints/M=1 0,deleteMin,theWave
			DeletePoints/M=1 maxY+1,deleteMax,theWave
			
			//Edit the scan info note to avoid scanGraph errors.
			SVAR info = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_info")
			info = ReplaceStringByKey("PixWidth",info,num2str(DimSize(theWave,0)),":","\r")
			info = ReplaceStringByKey("PixHeight",info,num2str(DimSize(theWave,1)),":","\r")
		EndFor
	EndFor
	
End

//Fits an 5-polynomial to the data before the light response and subtracts it out.
//Can use the FindPeakTrough option (set to usePkTrough to 1 and set the estimated peak time)...
//...for optimizing the range of the fit, which can distort the data a bit if it's set improperly. 

Function FlattenLaserResponse(theWave,xStart,xEnd,usePkTrough,estimatedPkTm)
	Wave theWave
	Variable xStart,xEnd,usePkTrough,estimatedPkTm
	Variable troughVal
	
	//Should we even do the flattening?
	//test average for early and late in the baseline to see if they are actually trending down.
	Variable early,late,xMiddle,total
	xMiddle = 0.5*(xStart + xEnd)
	
	early = mean(theWave,xStart,xMiddle)
	late = mean(theWave,xMiddle,xEnd)
	total = mean(theWave,xStart,xEnd)
	
	variable earlyCenterX = x2pnt(theWave,0.5*(xStart + xMiddle))
	variable lateCenterX = x2pnt(theWave,0.5*(xEnd + xMiddle))
	variable totalCenterX = x2pnt(theWave,xMiddle)

	variable startX = x2pnt(theWave,xStart)
	
	Duplicate/O theWave,temp
	SEtScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),temp
	temp = nan
	temp[earlyCenterX] = early
	temp[lateCenterX] = late
	temp[totalCenterX] = total
	
		
	If(usePkTrough)
		troughVal = FindPeakTrough(theWave,estimatedPkTm,"YVALUE")
		Variable troughX = FindPeakTrough(theWave,estimatedPkTm,"")
	EndIf
	
	
	CurveFit/X/L=(troughX - startX)/Q/M=2/W=0 line,temp[startX,troughX]/D
	Wave theFit = $("fit_" + NameOfWave(temp))
	SetScale/I x,xStart,pnt2x(theWave,troughX),theFit
	
	theWave[startX,troughX] = theWave[p] - theFit[x2pnt(theFit,pnt2x(theWave,p))]
	
	Variable minVal = WaveMin(theFit)
	
	If(troughVal == -1)
	//No trough was found
		return -1
	EndIf
	
	If(usePkTrough)
		theWave[x2pnt(theWave,xStart),troughX] += troughVal
	Else
		theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] += minVal
	EndIf
		KillWaves/Z temp

	return 0
	
	//CurveFit/Q/M=2/W=0 poly_XOffset 3, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D
	CurveFit/Q/M=2/W=0 line, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D
	//CurveFit/Q/M=2/W=0 exp_XOffset, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D

	Wave theFit = $("fit_" + NameOfWave(theWave))
	//Redimension/N=(DimSize(theWave,0)) theFit
		
	minVal = WaveMin(theFit)
	//theFit -= minVal
	theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] = theWave[p] - theFit[x2pnt(theFit,pnt2x(theWave,p))]
	If(usePkTrough)
		theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] += troughVal
	EndIf
	//theWave[x2pnt(theWave,xEnd)+1,DimSize(theWave,0)-1] = theWave[p] - theFit[DimSize(theFit,0) - 1]
End

//Finds the start of the rising phase of the major peak in a wave
Function FindPeakTrough(theWave,estimatedPeakTime,returnValue)
	Wave theWave
	Variable estimatedPeakTime
	String returnValue
	Variable peakTm,peakIndex
	
	Duplicate/FREE theWave,smthWave	
	Smooth/S=2 13,smthWave

	If(!WaveExists(smthWave))
		return -1
	EndIf
	
	ControlInfo/W=analysis_tools peakStVar
	Variable pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	Variable pkEnd = V_Value
	
	ControlInfo/W=analysis_tools bslnStVar
	Variable bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	Variable bslnEnd = V_Value
	
	Variable pkStartIndex = x2pnt(smthWave,pkStart)
	
	WaveStats/Q/R=(pkStart,pkEnd) smthWave
	peakIndex = V_MaxRowLoc
	peakTm = V_MaxLoc
	
	
	//Is there an earlier peak that is better to use?
	Variable backCounter = 1
	Do
		WaveStats/Q/R=[pkStartIndex,peakIndex - backCounter] smthWave
		Variable peakIndex_early = V_MaxRowLoc
		Variable peakTm_early = V_MaxLoc
		Variable peakVal_early = V_Max
	
		If(peakIndex_early < peakIndex - backCounter - 1) // if it's found the peak more than 2 rows away from the right limit, that's a new peak.  
			
			//If the new peak is more than halfway down to the baseline, then it's not a peak.
			If(smthWave[peakIndex] - smthWave[peakIndex_early] > smthWave[peakIndex_early] - mean(smthWave,bslnStart,bslnEnd))
				break
			EndIf
			
			//use the earlier peak
			peakIndex = peakIndex_early
			peakTm = peakTm_early
			break
		EndIf
		
		backCounter += 1
	While(backCounter < peakIndex - pkStartIndex)
	
	//Is the last point in the window actually a peak?
	If(peakTm == pkEnd)
		WaveStats/Q/R=(pkEnd,pkEnd + 0.5) smthWave
		peakTm = V_MaxLoc
		If(peakTm != pkEnd)
			return -1
		EndIf
	EndIf
	
	//sigmoidal fit to find the trough x/y values
	CurveFit/N/Q/M=2/W=2 Sigmoid, smthWave[x2pnt(smthWave,bslnStart),peakIndex]/D
	Wave theFit = $("fit_" + NameOfWave(smthWave))
	
	//Find location where the sigmoidal fit is 5% of its maximum value - this is the trough.
	WaveStats/Q theFit
	FindLevel/EDGE=1/Q theFit,V_min + 0.05*(V_max-V_min)
	Variable trough2,troughVal2
	
	trough2 = x2pnt(smthWave,V_LevelX)
	troughVal2 = V_min + 0.05*(V_max-V_min)
	
	
	Duplicate/FREE smthWave,diffWave
	Differentiate diffWave

	Variable value,i,changeTicker,trough
	changeTicker = 0
	i = 0
	value = 0
	
	//Works backwards from the peak.
	//Identify the trough of the peak after seeing 3 points in a row that are downwards sloping
	Do
		//Break in case it never finds a trough
		If(i > peakIndex)
			return -1
		EndIf
		
		If(diffWave[peakIndex - i] < 0)
			changeTicker +=1
		Else
			changeTicker = 0
		EndIf
		i+=1
	While(changeTicker < 3)	

	trough = peakIndex - i + 3
	
	If(cmpstr(returnValue,"YVALUE") == 0)
		return smthWave[trough2]
	Else
		return trough2
	EndIf
End

//Finds the start of the rising phase of the major peak in a wave
Function FindPeakTrough3D(theWave,estimatedPeakTime,returnValue)
	Wave theWave
	Variable estimatedPeakTime
	String returnValue
	Variable peakTm,peakIndex
	
	If(DimSize(theWave,2) == 0)
		Abort "Must use 3D wave."
	EndIf
	
	Duplicate/FREE theWave,smthWave

	Smooth/S=2/DIM=2 13, smthWave

	If(!WaveExists(smthWave))
		return -1
	EndIf
	
	//Waves to hold the peak indexes
	//Make/O/FREE/N=(DimSize(theWave,0),DimSize(theWave,1)) peakTm,peakIndex
	variable i
	//transpose the matrix so its an x-z series
	MatrixOP/FREE/S xzWave = transposeVol(smthWave,2)
	
	//Trim matrix around the estimated peak time
	Variable startPt,numberPts
	startPt = ScaleToIndex(theWave,estimatedPeakTime,2) - ScaleToIndex(theWave,0.5,2)
	numberPts = (ScaleToIndex(theWave,estimatedPeakTime,2) + ScaleToIndex(theWave,0.5,2)) - startPt
	DeletePoints/M=0 0,startPt,xzWave
	Redimension/N=(numberPts,-1,-1) xzWave
	
	//Find the peak data point in the extracted region
	MatrixOP/FREE peakTmCols = maxCols(xzWave)
	MatrixOP/FREE peakTmMatrix = transposeVol(peakTmCols,3)
	MatrixOP/O peakTmMatrix = peakTmMatrix^t 
	peakTmMatrix += IndexToScale(theWave,startPt,2)
	Duplicate/FREE peakTmMatrix,peakIndexMatrix
	peakIndexMatrix = ScaleToIndex(theWave,peakTmMatrix,2)
	
	//Differentiate the smoothed matrix
	Duplicate/FREE smthWave,diffWave
	Differentiate/DIM=2 diffWave

	//Works backwards from the peak.
	//Identify the trough of the peak after seeing 3 points in a row that are downwards sloping
	Variable trough,completed,m,n
	Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1)) changeTicker,troughIndexMatrix
	changeTicker = 0
	troughIndexMatrix = 0
	i = 0
	
	//Get for trough positions
	Do
		If(i == startPt)
			//Need a break statement if noisy signals don't give a peak or trough after a certain point.
			break
		EndIf
		
		For(m=0;m<DimSize(theWave,0);m+=1)
			For(n=0;n<DimSize(theWave,1);n+=1)
				If(changeTicker[m][n] < 2)
					If(peakIndexMatrix[m][n] - i < 0)
						changeTicker[m][n] += 1
					Else
						changeTicker[m][n] = 0
					EndIf
				ElseIf(changeTicker[m][n] == 2)
					troughIndexMatrix = peakIndexMatrix[m][n] - i + 3
					troughIndexMatrix = (troughIndexMatrix[m][n] < 0) ? 0 : troughIndexMatrix[m][n]
				Else
					continue
				EndIf
			EndFor
		EndFor
		
		i+=1
		
		//stops when i is larger than the peak start point. 
	While(i < startPt)	
	
	//If(cmpstr(returnValue,"YVALUE") == 0)
	//	return smthWave[trough]
	//Else
		return trough
	//EndIf
End

//Takes multiple dF maps and associated stimulus angles, and creates a vector sum angle map
Function VectorSumMap()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numScans,i,rows,cols,theAngle
	String scanName,channel,channelName
	
	//Get the channel
	channel = RemoveEnding(getChannel(1),";")
	If(cmpstr(channel,"ch1") == 0)
		channelName = "dF"
		channel = "ch1"
	ElseIf(cmpstr(channel,"ch2") == 0)
		channelName = "dF"
		channel = "ch2"
	ElseIf(cmpstr(channel,"ratio") == 0)
		channelName = "dGR"
		channel = "ch1"
	Else
		Abort "Must select a channel."
	EndIf
	
	numScans = ItemsInList(scanListStr,";")
	
	//Get first wave for dimensioning the output wave
	String theWaveName = StringFromList(0,scanListStr,";") 
	Wave/Z theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_peak")
	
	If(!WaveExists(theWave))
		Abort "Cannot find the wave " + NameOfWave(theWave)
	EndIf
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	
	//Make the operating waves for the vector sum
	Make/O/FREE/N=(rows,cols) vSumX,vSumY,totalSignal
	
	//Make output wave
	String outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_vAng"
	Make/O/N=(rows,cols) $outWaveName
	Wave vAngle = $outWaveName
	
	outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_vRad"
	Make/O/N=(rows,cols) $outWaveName
	Wave vRadius = $outWaveName
	
   outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_DSI"
	Make/O/N=(rows,cols) $outWaveName
	Wave DSI = $outWaveName

	//Set scales
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),vSumX,vSumY,totalSignal,vRadius,vAngle,DSI
	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),vSumX,vSumY,totalSignal,vRadius,vAngle,DSI
		
	vAngle = 0
	vRadius = 0
	DSI = 0
	
	//Get the angles
	ControlInfo/W=analysis_tools angleList
	String angleList = S_Value
	
	If(ItemsInList(angleList,",") != numScans)
		Abort "# angles must equal # scans"
	EndIf
	
	vSumX = 0
	vSumY = 0
	totalSignal = 0
	
	//Loop through scans to make vector sum
	For(i=0;i<numScans;i+=1)
		//Get the scan wave
		theWaveName = StringFromList(i,scanListStr,";") 
		Wave/Z theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_peak")
		
		If(!WaveExists(theWave))
			Abort "Cannot find the wave " + NameOfWave(theWave)
		EndIf
		
		theAngle = str2num(StringFromList(i,angleList,","))
		
		vSumX += theWave * cos(theAngle * pi/180)
		vSumY += theWave * sin(theAngle * pi/180)
		totalSignal += theWave
	EndFor
	
	vRadius = sqrt(vSumX^2 + vSumY^2)
	vAngle = -atan2(vSumY,vSumX) * 180/pi
	DSI = vRadius / totalSignal
	
	vAngle = (vAngle[p][q] < 0) ? vAngle[p][q] + 360 : vAngle[p][q]
	vAngle = 360 - vAngle
	
	ControlInfo/W=analysis_tools histogramCheck
	If(V_Value)
		String histName = NameOfWave(vAngle) + "_hist"
		Histogram/C/B={0,2,180}/DEST=$histName vAngle
		Wave theHist = $histName
		SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"degrees",theHist
	
		//Display histogram polar plot
		NewPolarPlot()
		GetWindow/Z kwTopWin activeSW
		WMPolarAppendTrace(S_Value,theHist,$"", 360)
		ModifyGraph rgb(polarY0)=(0,0,0),lsize=2
	EndIf
		
End

//Clone of the packages polar plot, but doesn't require the GUI to be running
Function NewPolarPlot()
	String srcGraphName = "_default_"
	String srcDF= WMPolarGraphDF(srcGraphName)
	
	if( strlen(srcDF) == 0 || DataFolderExists(srcDF) == 0 )
		NewDataFolder root:Packages:WMPolarGraphs
		NewDataFolder root:Packages:WMPolarGraphs:'_default_'
	endif
	
	srcDF= WMPolarGraphDF(srcGraphName)
	
	if( strlen(srcDF) == 0 || DataFolderExists(srcDF) == 0 )	
		DoAlert 0, "Polar settings for graph \"" + srcGraphName +"\" are missing. Expected datafolder is "+srcDF
		return 0
	endif

	WMPolarGraphDefaults("_default_")

	String newGraphName= WMPolarNewGraphName()
	String destDF= WMPolarGraphDF(newGraphName) // returns full path from dfName

	Display/W=(10,45,360,345)
	DoWindow/C $newGraphName
	WMPolarSaveSettingsName(newGraphName,newGraphName)	// initially the graph name and data folder name are the same.
	
	SetWindow $newGraphName hook=WMPolarGraphHook, hookEvents=1	// mouse button events

	// copy the settings
	if( DataFolderExists(destDF) )
		WMPolarCleanOutDF(destDF)	// should remove any dependencies that prevent folder deletion.
		KillDataFolder/Z $destDF
	endif
	DuplicateDataFolder $srcDF+":", $destDF
	WMPolarCleanOutDF(destDF)
	
	DoWindow/F WMPolarGraphPanel	// nothing interesting can be done with an empty polar graph, 
//	WMPolarPanelUpdate()				// panel activation will cause WMPolarPanelUpdate to run, anyway


End

//Gets the middle point of an ROI defined by an x wave and a y wave
Function getCenter(ROItable,ROIFolder)
	Wave/T ROItable
	String ROIFolder
	Variable i,size
	String ROIStr
	size = DimSize(ROItable,0)
	
	If(numtype(size) == 2)
		return -1
	EndIf
	
	Make/O/N=(size) $(ROIFolder + ":ROIx"),$(ROIFolder + ":ROIy")
	Wave ROIx = $(ROIFolder + ":ROIx")
	Wave ROIy = $(ROIFolder + ":ROIy")
	
	For(i=0;i<size;i+=1)
		ROIStr = ROItable[i]
		Wave xWave = $(ROIfolder + ":" + ROIStr + "_x")
		Wave yWave = $(ROIfolder + ":" + ROIStr + "_y")
		ROIx[i] = median(xWave)
		ROIy[i] = median(yWave)
	EndFor	
End

Function rescale2P_Scans()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	ControlInfo/W=analysis_tools scaleFactor
	Variable scaleFactor = V_Value*(1e-6)//microns per volt
	Variable numScans,numChannels,i,j,XVStart,XVEnd,YVStart,YVEnd
	String folder,channel,info,theChannel
	scanListStr = "Scan_014"
	numScans = ItemsInList(scanListStr,";")
	channel = getChannel(0)
	numChannels = ItemsInList(channel,";")
	
	For(i=0;i<numScans;i+=1)
		folder = "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":"
		theChannel = StringFromList(0,channel,";")	//only one info wave for all the channels
		Wave theWave = $(folder + StringFromList(i,scanListStr,";") + "_" + theChannel)
		
		info = getScanInfo(theWave)
		
		If(cmpstr(info,"-1") == 0)
			DoAlert 0,"Couldn't find the scan info for scan: " + NameOfWave(theWave)
		EndIf
		
		//Get the galvo voltages
		XVStart = str2num(StringByKey("XSV",info,":","\r"))
		XVEnd = str2num(StringByKey("XEV",info,":","\r"))
		YVStart = str2num(StringByKey("YSV",info,":","\r"))
		YVEnd = str2num(StringByKey("YEV",info,":","\r"))
		
		//Reset the scales according to the scale factor
		For(j=0;j<numChannels;j+=1)	
			theChannel = StringFromList(j,channel,";")	
			Wave theWave = 	$(folder + StringFromList(i,scanListStr,";") + "_" + theChannel)
			SetScale/I x,XVStart*scaleFactor,XVEnd*scaleFactor,theWave
			SetScale/I y,YVStart*scaleFactor,YVEnd*scaleFactor,theWave
		EndFor
		
		//Rewrite the scan info note with the correct pixel size
		Variable xPixels,yPixels,XVrange,YVrange,newXpixSize,newYpixSize,xPos,yPos,newXPos,newYPos
		//xPixels = str2num(StringByKey("PixWidth",info,":","\r"))
		//yPixels = str2num(StringByKey("PixHeight",info,":","\r"))
		//XVrange = abs(XVEnd - XVStart)
		//YVrange = abs(YVEnd - YVStart)
		newXpixSize = DimDelta(theWave,0)	//scaled microns per pixel in X
		newYpixSize = DimDelta(theWave,1)	  //scaled microns per pixel in Y
		info = ReplaceStringByKey("XpixSize",info,num2str(newXpixSize),":","\r")
		info = ReplaceStringByKey("YpixSize",info,num2str(newYpixSize),":","\r")
		//replace the x and y offset scales
		newXPos = DimOffset(theWave,0)//XVStart * scaleFactor
		newYPos = DimOffset(theWave,1)//YVStart * scaleFactor
		info = ReplaceStringByKey("Xpos",info,num2str(newXPos),":","\r")
		info = ReplaceStringByKey("Ypos",info,num2str(newYPos),":","\r")
		
		String scanName = ParseFilePath(1,NameOfWave(theWave),"_",1,0)
		SVAR scanInfo = $(folder + scanName + "info")
		scanInfo = info
	EndFor
End

Function/S  getScanInfo(theScan)
	Wave theScan
	String scanName,folder,errorStr
	
	folder = GetWavesDataFolder(theScan,1)
	scanName = ParseFilePath(1,NameOfWave(theScan),"_",1,0)
	SVAR scanInfo = $(folder + scanName + "info")
	
	If(!SVAR_Exists(scanInfo))
		errorStr = "-1"
		return errorStr
	Else
		return scanInfo
	EndIf
End

//Uses scanListStr to compute the correlation across trials for specific x and y pixel
Function spatialCov([threshold,xPix,yPix,filter])
	Variable threshold,xPix,yPix,filter//filter is 1 for 3x3 avg, or 0 for no filter
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable i,j,k,m,n,xDim,yDim,numScans,pixelNumRef,pixelNumTest
	String theScan,theFolder,theChannel
	Variable progress = 0
	
	If(ParamIsDefault(xPix) && !ParamIsDefault(filter))
		Display/N=Progress
		SetDrawEnv fsize=20,xcoord=prel,ycoord=prel
		DrawText 0.5,0.5,num2str(progress) + " %"
	EndIf
	
	If(ParamIsDefault(filter))
		filter = 0
	EndIf
	
	numScans = ItemsInList(scanListStr,";")
	//Make the stack of images for covariance analysis
	For(k=0;k<numScans;k+=1)
		theScan = StringFromList(k,scanListStr,";")
		theFolder = "root:twoP_Scans:" + theScan
		theChannel = RemoveEnding(getChannel(1),";")
		Wave theWave = $(theFolder + ":" + theScan + "_" + theChannel + "_dF_peak")
		If(!WaveExists(theWave))
			Abort "Cannot find wave: " + NameOfWave(theWave)
		EndIf
		
		If(k==0)	//first pass
			xDim = DimSize(theWave,0)
			yDim = DimSize(theWave,1)
			Make/FREE/N=(xDim,yDim,numScans) imageStack
			
			//Make wave to hold correlation values
			SetDataFolder GetWavesDataFolder(theWave,1)
			WaveStats/Q theWave			
		EndIf
		imageStack[][][k] = theWave[p][q][0]
	EndFor
	
	Variable count = 0
	If(!ParamIsDefault(threshold))	
		For(i=0;i<xDim;i+=1)
			For(j=0;j<yDim;j+=1)
				If(imageStack[i][j][0] > threshold)
					count += 1
				EndIf
			EndFor
		EndFor
	Else
		count = xDim*yDim
	EndIf
	
	Variable startIndex,endX,endY,refEndX,refEndY
	If(!ParamIsDefault(xPix))
		If(ParamIsDefault(yPix))
			Abort "Must include both x and y pixel locations"
		EndIf
		Make/O/N=(xDim,yDim) $("correlation_x" + num2str(xPix) + "_y" + num2str(yPix))
		Wave correlation = $("correlation_x" + num2str(xPix) + "_y" + num2str(yPix))
		
		If(filter)
			startIndex = 1
			endX = xDim - 1
			refEndX = 2
			endY = yDim - 1
			refEndY = 2
		Else
			endX = xDim
			refEndX = 1
			endY = yDim
			refEndY = 1
			startIndex = 0
		EndIf
	Else
		Make/O/N=(count,count) $("corr_matrix")//matrix excludes NaNs for sizing
		Wave correlation = $("corr_matrix")
		startIndex = 0
		refEndX = xDim
		refEndY = yDim
		endX = xDim
		endY = yDim
	EndIf	
	correlation = 0
	
	//Z-beams to be compared
	Make/FREE/N=(numScans) refBeam,testBeam
		
	If(filter)
		Make/FREE/N=(3,3) buffer
	EndIf
	
	If(!ParamIsDefault(xPix))
		If(filter)
			For(k=0;k<numScans;k+=1)
				buffer[][] = imageStack[xPix-1 + p][yPix-1 + q][k]
				refBeam[k] = avgNaNWave(buffer)
			EndFor
		Else
			refBeam[] = imageStack[xPix][yPix][p]
		EndIf
	EndIf

	Variable refCount,testCount
	refCount = -1
	testCount = -1
	
	//Compute pearson coefficient between two Z-beams
	For(m=startIndex;m<refEndX;m+=1)//sets the reference pixel
		For(n=startIndex;n<refEndY;n+=1)
			pixelNumRef = m + n*xDim
			
			//only for full image xcorr
			If(ParamIsDefault(xPix))
				refBeam[] = imageStack[m][n][p]
			EndIf
					
			//skip pixel if its NaN or under threshold
			If(numtype(refBeam[0]) == 2)
				If(!ParamIsDefault(xPix))
					correlation[i][j] = nan
				EndIf
				continue
			ElseIf(!ParamIsDefault(threshold))
				If(refBeam[0] < threshold)
					continue
				EndIf
			EndIf
			
			//set counters
			refCount += 1
			testCount = -1		
			
			For(i=startIndex;i<endX;i+=1)
				For(j=startIndex;j<endY;j+=1)
					pixelNumTest = i + j*xDim

					testBeam[] = imageStack[i][j][p]
					
					//skip pixel if its NaN or under threshold
					If(numtype(testBeam[0]) == 2)
						If(!ParamIsDefault(xPix))
							correlation[i][j] = nan
						EndIf
						continue
					ElseIf(!ParamIsDefault(threshold))
						If(testBeam[0] < threshold)
							continue
						EndIf
					EndIf
					
					//set counters
					testCount += 1
					
					//3x3 spatial averaging
					If(filter)
						For(k=0;k<numScans;k+=1)
							buffer[][] = imageStack[i-1 + p][j-1 + q][k]
							testBeam[k] = avgNaNWave(buffer)
						EndFor
					EndIf			
					
					//Do the two beams covary across trials?
					//reference on X axis, test on Y axis
					If(ParamIsDefault(xPix))
						correlation[refCount][testCount] = StatsCorrelation(refBeam,testBeam)
					Else
						correlation[i][j] = StatsCorrelation(refBeam,testBeam)
					EndIf
				EndFor
			EndFor
			
			//only progress % if doing entire image xcorr.
			If(ParamIsDefault(xPix) && !ParamIsDefault(filter))
				progress += 1/(count)
				DrawAction/W=Progress delete
				SetDrawEnv fsize=20,xcoord=prel,ycoord=prel
				DrawText 0.5,0.5,num2str(progress*100) + " %"
				DoUpdate/W=Progress
			EndIf
		EndFor
	EndFor	
	If(!ParamIsDefault(xPix))
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),correlation
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),correlation
	EndIf
	
End

Function clusterMatrix(corrMatrix,numGroups)
	Wave corrMatrix
	Variable numGroups
	SetDataFolder GetWavesDataFolder(corrMatrix,1)
	
	KMeans/INIT=1/NCLS=(numGroups)/OUT=2/SEED=(ticks) corrMatrix
	
	Wave W_KMMembers = W_KMMembers
	Duplicate/O corrMatrix,clustMatrix
	Wave clustMatrix = clustMatrix
	Duplicate/O W_KMMembers,Sorting_Index
	Wave Sorting_Index = Sorting_Index;Sorting_Index=p
	Sort W_KMMembers,Sorting_Index
	clustMatrix = corrMatrix[Sorting_Index[p]][Sorting_Index[q]]
	SetScale/P x,0,1,clustMatrix
	SetScale/P y,0,1,clustMatrix
	
	KillWaves /Z M_KMClasses // Cleanup.  
End

Function FPClusterMatrix(corrMatrix,numGroups)
	Wave corrMatrix
	Variable numGroups
	SetDataFolder GetWavesDataFolder(corrMatrix,1)
	FPClustering/NOR/MAXC=(numGroups)/INCD/CM corrMatrix
	Duplicate/O corrMatrix,clustMatrix_FP
	Wave clutMatrix_FP
	Wave W_FPClusterIndex = W_FPClusterIndex
	Duplicate/O W_FPClusterIndex,Sorting_Index
	Wave Sorting_Index = Sorting_Index;Sorting_Index = p
	Sort W_FPClusterIndex,Sorting_Index
	clustMatrix_FP = corrMatrix[Sorting_Index[p]][Sorting_Index[q]]
	SetScale/P x,0,1,clustMatrix_FP
	SetScale/P y,0,1,clustMatrix_FP
End

Function colorByCluster(theWave,class,[threshold])
	Wave theWave,class
	Variable threshold
	Variable xDim,yDim,xDel,yDel,i,j
	
	//dimensions
	xDim = DimSize(theWave,0)
	yDim = DimSize(theWave,1)
	xDel = DimDelta(theWave,0)
	yDel = DimDelta(theWave,1)
	
	//output wave
	Make/O/N=(xDim,yDim) $("cluster_map_FP")
	Wave clusterMap = $("cluster_map_FP")
	Variable count = -1
	
	For(i=0;i<xDim;i+=1)
		For(j=0;j<yDim;j+=1)
			If(ParamIsDefault(threshold))
				If(numtype(theWave[i][j]) == 2)
					clusterMap[i][j] = NaN
					continue
				EndIf
			Else
				If(numtype(theWave[i][j]) == 2 || theWave[i][j] < threshold)
					clusterMap[i][j] = NaN
					continue
				EndIf
			EndIf
			count += 1
			clusterMap[i][j] = class[count] //class wave ignored NaNs before, so need a separate index
		EndFor
	EndFor
	
	
End

//averages a wave that contains NaNs
Function avgNaNWave(theWave)
	Wave theWave
	Variable xDim,yDim,i,j,value
	
	xDim = DimSize(theWave,0)
	yDim = DimSize(theWave,1)
	Make/FREE/N=(xDim) theCol
	Make/O/N=0 root:concat
	Wave concat = root:concat
	
	For(i=0;i<yDim;i+=1)
		theCol = theWave[p][i]
		Concatenate/NP {theCol},concat
	EndFor
	WaveTransform zapNaNs concat
	WaveStats/Q concat
	KillWaves/Z concat
	return V_avg
End

Function doCluster()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable i,j,k,xDim,yDim,numScans
	String theScan,theFolder,theChannel
	
	numScans = ItemsInList(scanListStr,";")
	//Make the stack of images for covariance analysis
	For(k=0;k<numScans;k+=1)
		theScan = StringFromList(k,scanListStr,";")
		theFolder = "root:twoP_Scans:" + theScan
		theChannel = RemoveEnding(getChannel(1),";")
		Wave theWave = $(theFolder + ":" + theScan + "_" + theChannel + "_dF_peak")
		If(!WaveExists(theWave))
			Abort "Cannot find wave: " + NameOfWave(theWave)
		EndIf
		
		If(k==0)	//first pass
			xDim = DimSize(theWave,0)
			yDim = DimSize(theWave,1)
			//Make wave to hold correlation values
			SetDataFolder GetWavesDataFolder(theWave,1)
			Make/O/N=(xDim*yDim,numScans) theData
			Wave theData = theData
		EndIf
		
		Make/FREE/N=(xDim) theCol
		Make/O/N=0 root:concat
		Wave concat = root:concat
		concat = 0
		
		//concatenate the image into a single row
		For(i=0;i<yDim;i+=1)
			theCol = theWave[p][i]
			Concatenate/NP {theCol},concat
		EndFor
		WaveTransform zapNaNs concat
		Redimension/N=(DimSize(concat,0),-1) theData
		theData[][k] = concat[p]
	EndFor
	FPClustering/CM/CAC/MAXC=(10) theData
	
End

Function CorrMatrix2()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i,j,numScans,numROIs
	String theROI,theScan,theChannel,theFolder,theWaveName
	
	numScans = ItemsInList(scanListStr,";")
	numROIs = ItemsInList(ROIListStr,";")
	Make/FREE/N=(numScans) refTrial,testTrial
	Make/FREE/N=(numScans,numROIs) trials
	
	For(i=0;i<numROIs;i+=1)
		theROI = StringFromList(i,ROIListStr,";")
		For(j=0;j<numScans;j+=1)
			theScan = StringFromList(j,ScanListStr,";")
			theFolder = "root:ROI_analysis:"
			theChannel = RemoveEnding(getChannel(1),";")
			theWaveName = theFolder + "ROI" + theROI + ":" + theScan + "_" + theChannel + "_" + "ROI" + theROI + "_dF"
			Wave theWave = $theWaveName
			//gets the peak over time window, puts into 2D wave.
			trials[j][i] = WaveMax(theWave,3,5)
			
			If(i == 0 && j == 0)//first pass
				SetDataFolder GetWavesDataFolder(theWave,1)
				Make/O/N=(numROIs,numROIs) $("peak_correlation")
				Wave correlation = $("peak_correlation")
			EndIf
		EndFor
	EndFor

	//get cross-correlations
	For(i=0;i<numROIs;i+=1)
		//reference
		refTrial = trials[p][i]
		For(j=0;j<numROIs;j+=1)
			//test
			testTrial = trials[p][j]
			correlation[i][j] = StatsCorrelation(refTrial,testTrial) 
		EndFor
	EndFor
End

//Takes a data set input or wave list and generates a correlation matrix
Function GetCorrelationMatrix(dataSet)
	String dataSet
	String DSfolder = "root:Packages:analysisTools:DataSets:"
	String dataSetPath = DSfolder + "DS_" + dataSet
	Variable i,j
	
	Wave/T DSTable = $dataSetPath
	If(!WaveExists(DSTable))
		print "Cannot find the data set: " + dataSet
		return -1
	EndIf
	
	Variable numWaves = DimSize(DSTable,0)
	
	//Set initial wave to navigate to its data folder
	Wave refWave = $DSTable[0]
	If(!WaveExists(refWave))
		print "Cannot find the wave: " + DSTable[i]
		return -1
	EndIf
		
	SetDataFolder GetWavesDataFolder(refWave,1)
	Make/O/N=(numWaves,numWaves) xCorr
	Wave xCorr = xCorr
	
	For(i=0;i<numWaves;i+=1)
		Wave refWave = $DSTable[i]
		If(!WaveExists(refWave))
			print "Cannot find the wave: " + DSTable[i]
			return -1
		EndIf
		
		For(j=0;j<numWaves;j+=1)
			Wave testWave = $DSTable[j]
			If(!WaveExists(testWave))
				print "Cannot find the wave: " + DSTable[j]
				return -1
			EndIf
			
			//Get correlation between refWave and testWave
			xCorr[i][j] = StatsCorrelation(refWave,testWave) 
		EndFor	
	EndFor	
End

Function ColorROI_xCorr(windowName,colorGroups)
	String windowName
	Wave colorGroups
	String ROIfolder = "root:twoP_ROIS"
	String traces = TraceNameList(windowName,";",1)
	
	Variable i,j,k
	Variable numROIs = DimSize(colorGroups,0)
	Variable numGroups = WaveMax(colorGroups) + 1

	For(i=0;i<numGroups;i+=1)
		//What color will this group get?
		String colorIndex = GetDistributedColorIndex(i,numGroups)
		String theCluster = ""
		//Get ROIs from that color group
		For(j=0;j<numROIs;j+=1)
			If(colorGroups[j] == i)
				theCluster += StringFromList(j,traces,";") + ";"
			EndIf
		EndFor
		//Color the ROIs on the graph
		For(k=0;k<ItemsInList(theCluster,";");k+=1)
			Variable color1,color2,color3
			color1 = str2num(StringFromList(0,colorIndex,","))
			color2 = str2num(StringFromList(1,colorIndex,","))
			color3 = str2num(StringFromList(2,colorIndex,","))
			String theTrace = StringFromList(k,theCluster,";")
			ModifyGraph/W=$windowName rgb($theTrace) = (color1,color2,color3)
		EndFor
	EndFor

End

Function/S GetDistributedColorIndex(index,numGroups)
	Variable index,numGroups
	
	Variable delta = 65535/numGroups
	String colorIndex =  num2str(round(enoise(32767) + 32767)) + "," + num2str(round(enoise(32767) + 32767)) + "," + num2str(delta*index)
	return colorIndex
End

//Function GetWaveList

Function DifferentiateWaves(theWave)
	Wave theWave
	String outWaveName = NameOfWave(theWave) + "_diff"
	Variable dim
	
	If(!WaveExists(theWave))
		Abort "Couldn't find the wave: " + NameOfWave(theWave)
	EndIf
	
	//What dimension to differentiate over?
	If(DimSize(theWave,0) > 0 && DimSize(theWave,1) > 0)
		If(DimSize(theWave,2) > 0)
			dim = 2
		Else
			Abort "Must be either a 1D or 3D wave"
		EndIf
	Else
		dim = 0
	EndIf
	
	//Make the output wave
	SetDataFolder GetWavesDataFolder(theWave,1)
	Duplicate/O theWave,$outWaveName
	Wave outWave = $outWaveName
	outWave = 0
	
	//Differentiate
	Differentiate/DIM=(dim) theWave/D=outWave
End

Function GetPkTimes()
	//Using a data set?
	ControlInfo/W=analysis_tools useDataSetCheck
	Variable useDS = V_Value

	If(useDS)
		String theWaveList = GetDSWaveList(separator=";")
	Else
		Abort "Only supports data set use for now"
	EndIf
	
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	Variable i,j,k,rows,cols,startTm,endTm

	//Get range info
	ControlInfo/W=analysis_tools peakStVar
	startTm = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	endTm = V_Value
	
	For(i=0;i<ItemsInList(theWaveList,";");i+=1)
		//Get input wave
		Wave theWave = $StringFromList(i,theWaveList,";")
		If(DimSize(theWave,2) == 0)
			Abort "Only supports 3D waves for now"
		EndIf
		
		//Get Dimensions
		rows = DimSize(theWave,0)
		cols = DimSize(theWave,1)
		
		//Make output wave
		SetDataFolder GetWavesDataFolder(theWave,1)
		String outWaveName = NameOfWave(theWave) + "_pkTm"
		Make/O/N=(rows,cols) $outWaveName
		Wave pkTm = $outWaveName
		
		//Getting the peak ∆F/F and its time point from a beam 
			For(j=0;j<rows;j+=1)
				For(k=0;k<cols;k+=1)
					MatrixOP/FREE/O/S theBeam = Beam(theWave,j,k)
					SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
					WaveStats/Q/R=(startTm,endTm) theBeam
					If(V_avg == 0)
						pkTm[j][k] = NaN
					Else
						pkTm[j][k] = V_MaxLoc
					EndIf
				EndFor
			EndFor
		//Set scales
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),pkTm
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),pkTm
	EndFor	
	
End

//takes image, if there is a non-NaN value, it marks the coordinate in an x and y 1D wave
Function convertImage2xy(theImage)
	Wave theImage
	ImageStats/Q theImage
	SetDataFolder GetWavesDataFolder(theImage,1)
	 
	Make/N=(V_npnts)/O $(NameOfWave(theImage) + "_x"),$(NameOfWave(theImage) + "_y"),$(NameOfWave(theImage) + "_pktm")
	Wave xwave = $(NameOfWave(theImage) + "_x")
	Wave ywave = $(NameOfWave(theImage) + "_y")
	Wave pktm = $(NameOfWave(theImage) + "_pktm")
	
	Variable xDim,yDim,i,j,count
	
	xDim = DimSize(theImage,0)
	yDim = DimSize(theImage,1)
	count = 0
	For(i=0;i<xDim;i+=1)
		For(j=0;j<yDim;j+=1)
			If(numtype(theImage[i][j]) != 2)
				xwave[count] = IndexToScale(theImage,i,0)
				ywave[count] = IndexToScale(theImage,j,1)
				pktm[count] = theImage[i][j]//will be used as an f(z) color function
				count += 1
			EndIf
		EndFor
	EndFor

End


//Takes image, gets the median pixel value for that column and puts it into a new wave dimensioned for the # image rows
Function medianCol(theImage)
	Wave/Z theImage
	
	If(!WaveExists(theImage))
		Abort "The wave: " + NameOfWave(theImage) + " does not exist"
	EndIf
	
	If(DimSize(theImage,1) == 0 || DimSize(theImage,0) == 0)
		Abort "Must be an 2D wave"
	EndIf
	
	SetDataFolder GetWavesDataFolder(theImage,1)
	
	Variable rows,cols,i,j
	rows = DimSize(theImage,0)
	cols = DimSize(theImage,1)
	
	Make/O/N=(rows) $(NameOfWave(theImage) + "_medCol")
	Wave outWave = $(NameOfWave(theImage) + "_medCol")
	
	For(i=0;i<rows;i+=1)
		MatrixOP/FREE theCol = row(theImage,i)^t
		WaveTransform zapNaNs theCol
		outWave[i] = median(theCol)
	EndFor
End

Function avgROIs()
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable i,j,numROIs,numScans
	numROIs = ItemsInList(ROIListStr,";")
	numScans = ItemsInList(scanListStr,";")
	
	//initial wave
	String theROIName = StringFromList(0,ROIListStr,";")
	String origScanName = StringFromList(0,scanListStr,";")
	String theWaveName = "root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF"
	Wave theWave = $theWaveName
	Variable size = DimSize(theWave,0)
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	For(i=0;i<numROIs;i+=1)
		theROIName = StringFromList(i,ROIListStr,";")
		Make/O/N=(size) $("root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF_avg")
		Wave theAvg = $("root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF_avg")
		Note/K theAvg,"Averaged " + num2str(numScans) + " waves:"
		For(j=0;j<numScans;j+=1)
			String theScanName = StringFromList(j,scanListStr,";")
			theWaveName = "root:ROI_analysis:ROI" + theROIName + ":" + theScanName + "_ch1_ROI" + theROIName + "_dF"
			Wave theWave = $theWaveName
			theAvg += theWave	
			Note theAvg,theWaveName
		EndFor
		theAvg /= numScans
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theAvg
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theAvg
		
	EndFor
End

Function NormalizeWaves()
	Variable i
	String theWaveList = GetDSWaveList(separator=";")
	For(i=0;i<ItemsInList(theWaveList,";");i+=1)
		String theWaveName = StringFromList(i,theWaveList,";")
		Wave theWave = $theWaveName
		
		SetDataFolder GetWavesDataFolder(theWave,1)
	//	String outWaveName = NameOfWave(theWave) + "_Nrm"
	//	Make/O/N=(DimSize(theWave,0)) $outWaveName
		//Wave outWave = $outWaveName
		
		Variable maxVal = WaveMax(theWave)
		theWave = theWave/maxVal
				
	//	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	//	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	EndFor
End

//Deletes ROIs that match grid*
Function deleteGridROI(ROIListWave,ROIListSelWave)
	Wave/T ROIListWave
	Wave ROIListSelWave
	
	Variable i,size
	size = DimSize(ROIListWave,0)
	
	For(i=size-1;i>-1;i-=1)	//count down
		If(StringMatch(ROIListWave[i],"grid*"))
			DeletePoints/M=0 i,1,ROIListWave,ROIListSelWave
		EndIf
	EndFor
End

//Makes a custom color table with the specified dimensions
//Useful for truncating a color table so the start/end colors make more sense
Function MakeCustomColorTable(colorMap,startRow,endRow)
	String colorMap
	Variable startRow,endRow
	
	If(!DataFolderExists("root:CustomColors"))
		NewDataFolder root:CustomColors
	EndIf
	SetDataFolder root:CustomColors
	
	ColorTab2Wave $colorMap
	Wave customTable = M_Colors
	
	Variable size = DimSize(customTable,0)
	DeletePoints endRow+1,size-1,customTable
	DeletePoints 0,startRow,customTable
	
End

//input wave should be a dendritic mask.
Function distanceMatrix(theWave,startX,startY)
	Wave theWave
	Variable startX,startY
	Variable xOff,yOff
	Variable left,right,up,down,keepGoing,xStep,yStep,i,j,xPos,yPos,numPts,blockDir
	
	Make/FREE/N=1 buffer
	Make/O/N=100 xPlot,yPlot
	Wave xPlot = xPlot
	Wave yPlot = yPlot
	xPlot = 0
	yPlot = 0
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	Make/O/N=4 count
	Wave count = count
	
	xPlot[0] = startX
	yPlot[0] = startY
	
	
	numPts = 0
	Do
		count = 0
		//Which direction are we testing?
		For(i=0;i<4;i+=1)
			switch(i)
				case 0:
					//right
					xStep = 1
					yStep = 0
					break
				case 1:
					//left
					xStep = -1
					yStep = 0
					break
				case 2:
					//down
					yStep = 1
					xStep = 0
					break
				case 3:
					//up
					yStep = -1
					xStep = 0
					break
			endswitch
			
			//reset for each direction
			xPos = startX
			yPos = startY	
			
			Do	
				xPos += xStep
				yPos += yStep		
				
				If(theWave[xPos][yPos] == 1)
					keepGoing = 1
					count[i] += 1
				Else
					keepGoing = 0
				EndIf
			While(keepGoing)
		EndFor
		
		numPts += 1
		keepGoing = 1
		
		//Prevent it from going back in the direction it just came from
		If(numPts > 1)
			count[blockDir] = 0
		EndIf
		
		//If in dead end
		If(count[0] + count[1] + count[2] + count[3] == 3)
			keepGoing = 0
		EndIf
		
		//Which direction gave the largest run?
		WaveStats/Q count

		If(round(V_maxLoc) == 0)
			blockDir = 1
			xPlot[numPts] = xPlot[numPts - 1] + count[0]
			yPlot[numPts] = yPlot[numPts - 1]
		ElseIf(round(V_maxLoc) == 1)
			blockDir = 0
			xPlot[numPts] = xPlot[numPts - 1] - count[1]
			yPlot[numPts] = yPlot[numPts - 1]
		ElseIf(round(V_maxLoc) == 2)
			blockDir = 3
			xPlot[numPts] = xPlot[numPts - 1]
			yPlot[numPts] = yPlot[numPts - 1] + count[2]
		ElseIf(round(V_maxLoc) == 3)
			blockDir = 2
			xPlot[numPts] = xPlot[numPts - 1]
			yPlot[numPts] = yPlot[numPts - 1] - count[3]	
		EndIf
		
		//Prevents running out of space in the plot waves
		If(numPts < 100)
			startX = xPlot[numPts]
			startY = yPlot[numPts]
		Else
			keepGoing = 0
		EndIf
		
	While(keepGoing)
	
	//clean up zeros and scale
	xPlot = (xPlot == 0) ? nan : xPlot
	yPlot = (yPlot == 0) ? nan : yPlot
	
	WaveTransform zapNaNs xPlot
	WaveTransform zapNaNs yPlot
	
	xPlot = IndexToScale(theWave,xPlot[p],0)
	yPlot = IndexToScale(theWave,yPlot[p],1)

End

Function clip()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numScans = ItemsInList(scanListStr,";")
	Variable i,val
	val = 65000
	
	For(i=0;i<numScans;i+=1)
		Wave theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_ch2")
		SetDataFolder GetWavesDataFolder(theWave,1)
		Variable avg = mean(theWave)
		theWave = (theWave[p][q][r] > val) ? avg : theWave[p][q][r]

	EndFor
End


Function getLineProfileDistance(xWave,yWave)
	Wave xWave,yWave
	Variable delta = xWave[1] - xWave[0]
	Variable size = DimSize(xWave,0)
	Variable i,distance
	
	distance = 0

	For(i=1;i<size;i+=1)
		If(yWave[i] != yWave[i-1])
			distance += sqrt(abs(yWave[i] - yWave[i-1])^2 + delta^2) //a^2 + b^2 = c^2
		Else
			distance += delta
		EndIf
	EndFor
	return distance
End

//Gets an x-scaling wave for the line profile
Function getLineProfileDistanceWave(xWave,yWave,theProfile,theImage)
	Wave xWave,yWave,theProfile,theImage
	Variable xDelta,yDelta,size,i,xD,yD
	String LPname,LDname
	
	If(!WaveExists(xWave) || !WaveExists(yWave) || !WaveExists(theProfile) || !WaveExists(theImage))
		Abort "Some of the waves don't exist."
	EndIf
	
	//dimensions
	xDelta = DimDelta(theImage,0)
	yDelta = DimDelta(theImage,1)
	size = DimSize(theProfile,0)
	
	//line distance wave name
	LPname = NameOfWave(theProfile)
	If(StringMatch(LPname,"*LP"))
		LDname = ReplaceString("LP",LPname,"LD")
	Else
		LDname = LPname + "_LD"
	EndIf
	
	SetDataFolder GetWavesDataFolder(theProfile,1)
	
	Make/O/N=(size) $LDname
	Wave LD = $LDname
	
	LD[0] = 0
	
	For(i=1;i<size;i+=1)
		//Get distance from each x/y data point to the next
		xD = abs(xWave[i] - xWave[i-1]) * 5
		yD = abs(yWave[i] - yWave[i-1]) * 5
		
		//calculate the point to point distance
		LD[i] = sqrt(xD^2 + yD^2) + LD[i-1]
	EndFor
	
End

//takes 2D matrix and concatenates the rows together
Function concatenate2D(theWave,outWave)
	wave theWave,outWave
	
	If(DimSize(theWave,1) == 0)
		Abort "Must use 2D wave"
	EndIf
	Variable size = DimSize(theWave,0)
	Variable cols = DimSize(theWave,1)
	Variable i,currentSize
	
	For(i=0;i<cols;i+=1)
		If(i==0)
			Redimension/N=(size) outWave
			outWave[0,size-1] = theWave[p][i]
		Else
			currentSize = DimSize(outWave,0)
			Redimension/N=(currentSize + size) outWave
			outWave[currentSize,currentSize+size-1] = theWave[p-currentSize][i]
		EndIf
		
	EndFor	
End

Function trimCMatrix(dMatrix,cMatrix)
	Wave dMatrix,cMatrix
	
	Variable rows = DimSize(dMatrix,0)
	Variable i
	For(i=0;i<rows;i+=1)
		If(dMatrix[i] == 0)
			dMatrix[i] = nan
			cMatrix[i] = nan
		EndIf
	EndFor
	WaveTransform zapNaNs dMatrix
	WaveTransform zapNaNs cMatrix
	
End

Function FilterROI_Table(roiTable,threshold,matchStr)
	Wave/T roiTable
	Variable threshold
	String matchStr
	Variable i
	
	For(i=0;i<DimSize(roiTable,0);i+=1)
		//Get the matched wave for thresholding the ROIs
		String theROI = "ROI" + roiTable[i]
		String folder = "root:ROI_analysis:" + theROI
		SetDataFolder $folder
		String theWaveList = DataFolderDir(2)
		theWaveList = StringByKey("WAVES",theWaveList,":",";")
		String matchWaveName = ListMatch(theWaveList,matchStr,",")
		matchWaveName = StringFromList(0,matchWaveName,",")
		
		Wave theWave = $matchWaveName
		
		If(WaveMax(theWave,3,5) < threshold)
			DeletePoints/M=0 i,1,roiTable
		EndIf
		
	EndFor
	

End

//Takes an ROI table and eliminates columns and rows from the DMatrix wave that aren't in the filter table
//roiTable is the full length table with all the ROIs
Function filterDMatrix(filterTable,roiTable,dMatrix)
	Wave/T filterTable,roiTable
	Wave dMatrix
	Variable size = DimSize(roiTable,0)
	Variable filterSize = DimSize(filterTable,0)
	Variable i,index,isPresent
	String filterList = ""
	String ROIList = ""
	String theROI
	
	//Get the ROI lists
	For(i=0;i<filterSize;i+=1)
		filterList += filterTable[i] + ";"
	EndFor
	
	For(i=0;i<size;i+=1)
		ROIList += roiTable[i] + ";"
	EndFor
	
	For(i=0;i<size;i+=1)
		theROI = StringFromList(i,ROIList,";")
		isPresent = WhichListItem(theROI,filterList,";")
		
		If(isPresent == -1)
			index = WhichListItem(theROI,ROIList,";")
			dMatrix[index][] = 0
			dMatrix[][index] = 0
		EndIf
	EndFor
End


Function GR_map(ch1,ch2,startTm,endTm)
	Wave ch1,ch2
	Variable startTm,endTm
	Variable startR,endR,size
	String name,outWaveName
	Variable rows,cols,frames
	
	rows = DimSize(ch1,0)
	cols = DimSize(ch1,1)
	frames =DimSize(ch1,2)
	
	startR = ScaleToIndex(ch1,startTm,2)
	endR = ScaleToIndex(ch1,endTm,2)
	size = endR - startR + 1
	
	name = NameOfWave(ch1)
	outWaveName = ReplaceString("ch1",name,"GR") 
	
	SetDataFolder GetWavesDataFolder(ch1,1)
	
	Make/FREE/N=(rows,cols,size) green
	
	//Get average green map over the peak area
	green = ch1[p][q][r+startR]
	MatrixOP/FREE greenAvg = sumBeams(green)/size
	MatrixFilter/N=3 median greenAvg
	
	//Get average red map over the entire scan
	MatrixOP/FREE redAvg = sumBeams(ch2)/frames
	MatrixFilter/N=3 median redAvg
	
	//Get the ratio map
	Make/O/N=(rows,cols) $outWaveName
	Wave GR = $outWaveName
	
	GR = greenAvg/redAvg	
End

Function Normalize3D(theWave)
	Wave theWave
	Variable i,j,k,numFrames,rows,cols,maxVal
	
	numFrames = DimSize(theWave,2)
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	
	For(i=0;i<rows;i+=1)
		For(j=0;j<cols;j+=1)
			MatrixOP/FREE theBeam = beam(theWave,i,j)
			maxVal = WaveMax(theBeam)
			theBeam /= maxVal
			theWave[i][j][] = theBeam[r]
		EndFor
	EndFor

End

Function ResolveFunctionParameters(theFunction)
	String theFunction
	String info = FunctionInfo(theFunction)
	
	//control list will need updating when controls are added
	SVAR ctrlList_extFunc = root:Packages:analysisTools:ctrlList_extFunc
	ctrlList_extFunc = "extFuncPopUp;extFuncDS;extFuncChannelPop;extFuncDSListBox;extFuncHelp;"
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	
	Variable numParams,i,pos
	String paramType,functionStr

	numParams = str2num(StringByKey("N_PARAMS",info,":",";"))
	
	//Function has no extra parameters declared
	If(numParams == 0)
		KillExtParams()
		return -1
	EndIf
	
	
	numExtParams = numParams
	paramType = ""

	//gets the type for each input parameter
	Variable numOptionals = str2num(StringByKey("N_OPT_PARAMS",info,":",";"))
	SVAR isOptional = root:Packages:analysisTools:isOptional
	isOptional = ""
	
	For(i=0;i<numParams;i+=1)
		paramType += StringByKey("PARAM_" + num2str(i) + "_TYPE",info,":",";") + ";"
		If(i < numParams - numOptionals)
			isOptional += "0" + ";"
		Else
			isOptional += "1" + ";"
		EndIf
	EndFor
	extParamTypes = paramType
	
	//Gets the names of each inputs in the selected function
	functionStr = ProcedureText(theFunction,0)
	pos = strsearch(functionStr,")",0)
	functionStr = functionStr[0,pos]
	functionStr = RemoveEnding(StringFromList(1,functionStr,"("),")")
	
	extParamNames = functionStr
	Variable type,left=10,top=125
	String name,paramName
	
	For(i=0;i<numParams;i+=1)
		name = StringFromList(i,functionStr,",")
		paramName = "param" + num2str(i)
		type = str2num(StringFromList(i,paramType,";"))
		switch(type)
			case 4://variable
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={125,20},title=name,value=_NUM:0,disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
			case 8192://string
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={150,20},title=name,value=_STR:"",disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
			case 16386://wave
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={150,20},title=name,value=_STR:"",disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
		endswitch
		top += 25
	EndFor
	
End

Function/S SetExtFuncCmd()
	Variable option//is this from external command, or is it from a built in command
	
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	SVAR isOptional = root:Packages:analysisTools:isOptional
	Variable i,type
	String runCmdStr = ""
	String name 
	
	SVAR builtInCmdStr = root:Packages:analysisTools:runCmdStr
	
	//External function
	ControlInfo/W=analysis_tools extFuncPopUp
	String theFunction = S_Value
	runCmdStr = "AT_" + theFunction + "("

	For(i=0;i<numExtParams;i+=1)
		ControlInfo/W=analysis_tools $("param" + num2str(i))
		type = str2num(StringFromList(i,extParamTypes,";"))
		name = StringFromList(i,extParamNames,",")
		
		switch(type)
			case 4://variable
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += num2str(V_Value) + ","
				Else
					//optional parameter
					If(V_Value)
						runCmdStr += name + "=" + num2str(V_Value) + ","
					EndIf
				EndIf
				break
			case 8192://string
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += "\"" + S_Value + "\","
				Else
					//optional parameter
					If(strlen(S_Value))
						runCmdStr += name + "=" + "\"" + S_Value + "\","
					EndIf
				EndIf
				break
			case 16386://wave
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += S_Value + ","
				Else
					//optional parameter
					If(strlen(S_Value))
						runCmdStr += name + "=" + S_Value + ","
					EndIf
				EndIf
				break
		endswitch
	EndFor
	runCmdStr = RemoveEnding(runCmdStr,",")
	runCmdStr += ")"

	return runCmdStr
End

Function KillExtParams()
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	Variable i
	For(i=0;i<numExtParams;i+=1)
		KillControl/W=analysis_tools $("param" + num2str(i))
	EndFor
End

Function updateExtFuncValues(theFunction)
	String theFunction
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	Wave/T extFuncValues = root:Packages:analysisTools:extFuncValues
	
	Variable cols,i,numParams,whichCol = -1
	
	cols = DimSize(extFuncValues,1)
	numParams = ItemsInList(extParamNames,",")
	
	If(cols == 0)
		whichCol = 0
		cols +=1
		Redimension/N=(1,cols) extFuncValues
		If(numParams + 2 > DimSize(extFuncValues,0))
			Redimension/N=(numParams + 2,-1) extFuncValues
		EndIf
	Else
	
		For(i=0;i<cols;i+=1)
			If(stringmatch(extFuncValues[0][i],theFunction))
				whichCol = i
				break
			EndIf
		EndFor
		
		If(whichCol == -1)
			whichCol = cols
			cols += 1
			Redimension/N=(-1,cols) extFuncValues
			If(numParams + 2 > DimSize(extFuncValues,0))
				Redimension/N=(numParams + 2,-1) extFuncValues
			EndIf
		EndIf
	EndIf
	
	///Fill out the table
	extFuncValues[0][whichCol] = theFunction
	extFuncValues[1][whichCol] = num2str(numParams)
	For(i=0;i<numParams;i+=1)
		ControlInfo/W=analysis_tools $("param" + num2str(i))
		If(numtype(V_Value) == 2 || strlen(S_Value))
			//string or wave input
			extFuncValues[i+2][whichCol] = S_Value
		Else
			//variable input
			extFuncValues[i+2][whichCol] = num2str(V_Value)
		EndIf
	EndFor

End

Function recallExtFuncValues(theFunction)
	String theFunction
	Wave/T extFuncValues = root:Packages:analysisTools:extFuncValues
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	Variable i,whichCol,cols
	
	cols = DimSize(extFuncValues,1)
	whichCol = -1
	
	For(i=0;i<cols;i+=1)
		If(stringmatch(extFuncValues[0][i],theFunction))
			whichCol = i
			break
		EndIf
	EndFor
	
	If(whichCol != -1)
		For(i=0;i<numExtParams;i+=1)
			ControlInfo/W=analysis_tools $("param" + num2str(i))
			If(numtype(V_Value) ==2)
				//string or wave input
				SetVariable $("param" + num2str(i)) win=analysis_tools,value=_STR:extFuncValues[i+2][whichCol]
			Else
				SetVariable $("param" + num2str(i)) win=analysis_tools,value=_NUM:str2num(extFuncValues[i+2][whichCol])
			EndIf
			
		EndFor
	EndIf

End

Function openViewer()
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	
	//Define guides
	DefineGuide/W=analysis_tools VT = {FT,0.63,FB}
	DefineGuide/W=analysis_tools VB = {FT,0.97,FB}
	
	//Add an additional 200 pixels to the toolbox on the bottom
	GetWindow analysis_tools wsize
	MoveWindow/W=analysis_tools V_left,V_top,V_right,V_bottom + 300
	
	//Open the display window only if it wasn't already open
	If(viewerOpen == 0)
		Display/HOST=analysis_tools/FG=(FL,VT,FR,VB)/N=atViewerGraph
	EndIf	
	
	//adjust guide for scanListPanel so it doesn't get in the viewer's way
	DefineGuide/W=analysis_tools listboxBottom={FT,0.61,FB}
	
	//Display the window controls
	Button atViewerAutoScaleButton win=analysis_tools,size={50,20},pos={3,788},title="AUTO",proc=atButtonProc
	Button atViewerSeparateVertButton win=analysis_tools,size={50,20},pos={60,788},title="VSEP",proc=atButtonProc
	Button atViewerSeparateHorizButton win=analysis_tools,size={50,20},pos={117,788},title="HSEP",proc=atButtonProc
	Button atViewerDisplayTracesButton win=analysis_tools,size={50,20},pos={174,788},title="DISP",proc=atButtonProc
	Button atViewerClearTracesButton win=analysis_tools,size={50,20},pos={231,788},title="CLEAR",proc=atButtonProc
	
	//Recall previous display
	If(strlen(viewerRecall))
		Execute/Z viewerRecall
	EndIf
	
	viewerOpen = 1
End

Function closeViewer()
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	
	viewerRecall = WinRecreation("analysis_tools#atViewerGraph",0)
	//viewerRecall = ReplaceString("Display/W=(162,200,488,600)/FG=(FL,VT,FR,VB)/HOST=#",viewerRecall,"AppendToGraph/W=analysis_tools#atViewerGraph")
	
	Variable pos1 = strsearch(viewerRecall,"Display",0)
	Variable pos2 = strsearch(viewerRecall,"#",0)
	String matchStr = viewerRecall[pos1,pos2]
	viewerRecall = ReplaceString(matchStr,viewerRecall,"AppendToGraph/W=analysis_tools#atViewerGraph")
	
	KillWindow/Z analysis_tools#atViewerGraph
	//Remove 200 pixels to the toolbox on the bottom
	GetWindow analysis_tools wsize
	MoveWindow/W=analysis_tools V_left,V_top,V_right,V_bottom - 300
	
	//adjust guide for scanListPanel so it doesn't get in the viewer's way
	DefineGuide/W=analysis_tools listboxBottom={FB,-10}
	
	viewerOpen = 0
End

Function AppendToViewer(itemList)
	String itemList
	SVAR cdf = root:Packages:MBr:currentDataFolder
	Variable i,j,type

	DoWindow/W=analysis_tools#atViewerGraph atViewerGraph
	
	//Does the window exist?
	If(V_flag)
		String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
		String traceCheck = traceList
	
		For(i=0;i<ItemsInList(itemList,";");i+=1)
			//Is it a numeric wave?
			type = WaveType($(cdf + StringFromList(i,itemList,";")),1)
			
			If(type == 1)
				//Is it already on the graph?
				Variable isOnGraph = WhichListItem(StringFromList(i,itemList,";"),traceList,";")
				If(isOnGraph == -1)
					AppendToGraph/W=analysis_tools#atViewerGraph $(cdf + StringFromList(i,itemList,";"))
				Else
					traceCheck = RemoveListItem(i,traceCheck,";")
					traceCheck = AddListItem("0",traceCheck,";",i)
				EndIf
			EndIf
		EndFor
		
		For(i=0;i<ItemsInList(traceCheck,";");i+=1)
			If(cmpstr(StringFromList(i,traceCheck,";"),"0") != 0)
				RemoveFromGraph/W=analysis_tools#atViewerGraph $StringFromList(i,traceCheck,";")
			EndIf
		EndFor
		
	EndIf
End

Function SeparateTraces(orientation)
	String orientation
	NVAR areSeparated = root:Packages:analysisTools:areSeparated
	String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
	String theTrace,prevTrace
	Variable numTraces,i,traceMax,traceMin,traceMinPrev,traceMaxPrev,offset
	offset = 0
	numTraces = ItemsInList(traceList,";")
	
	strswitch(orientation)
		case "vert":
			If(areSeparated)
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					offset = 0
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={0,offset}
				EndFor	
				areSeparated = 0	
			Else
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					Wave theTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",theTrace)
					traceMin = WaveMin(theTraceWave)
					traceMax = WaveMax(theTraceWave)
					Wave prevTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",StringFromList(i-1,traceList,";"))
					traceMinPrev = WaveMin(prevTraceWave)
					traceMaxPrev = WaveMax(prevTraceWave)
					offset -= abs(traceMax - traceMinPrev)
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={0,offset}
				EndFor
				areSeparated = 1
			EndIf
			break
		case "horiz":
			If(areSeparated)
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					offset = 0
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={offset,0}
				EndFor	
				areSeparated = 0	
			Else
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					Wave theTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",theTrace)
					traceMin = DimOffset(theTraceWave,0)
					traceMax = IndexToScale(theTraceWave,DimSize(theTraceWave,0)-1,0)
					Wave prevTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",StringFromList(i-1,traceList,";"))
					traceMinPrev = DimOffset(prevTraceWave,0)
					traceMaxPrev = IndexToScale(prevTraceWave,DimSize(prevTraceWave,0)-1,0)
					offset += abs(traceMinPrev+traceMax)
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={offset,0}
				EndFor
				areSeparated = 1
			EndIf
			break
	endswitch
End

//Clears all the traces from the Viewer window
Function clearTraces()
	String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
	Variable numTraces = ItemsInList(traceList,";")
	Variable i
	
	For(i=0;i<numTraces;i+=1)
		String theTrace = StringFromList(i,traceList,";")
		RemoveFromGraph/W=analysis_tools#atViewerGraph $theTrace
	EndFor	
End

Function/S textWaveToStringList(textWave,separator)
	Wave/T textWave
	String separator
	Variable size,i
	String strList = ""
	
	If(WaveType(textWave,1) !=2)
		Abort "Input must be a text wave"
	EndIf
	size = DimSize(textWave,0)
	For(i=0;i<size;i+=1)
		strList += textWave[i] + separator
	EndFor
	strList = RemoveEnding(strList,separator)
	
	return strList
End

Function/WAVE StringListToTextWave(strList,separator)
	String strList,separator
	Variable size,i
	
	If(!strlen(strList))
		Abort "String must be longer than 0 characters"
	EndIf
	
	size = ItemsInList(strList,separator)
	Make/FREE/T/N=(size) textWave
	For(i=0;i<size;i+=1)
		textWave[i] = StringFromList(i,strList,";")
	EndFor

	return textWave
End

//averages the selected waves
Function AverageWaves()
	Variable numWaves,i
	
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";")
	String outWaveName = NameOfWave(theWave) + "_avg"
	
	Variable dims = WaveDims(theWave)
	
	switch(dims)
		case 1:
			Make/O/N=(DimSize(theWave,0)) $outWaveName
			break
		case 2:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1)) $outWaveName
			break
		case 3:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1),DimSize(theWave,2)) $outWaveName
			break
	endswitch
	
	Wave outWave = $outWaveName 
	outWave = 0
	
	Note/K outWave,num2str(numWaves) + " waves averaged:"
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		outWave += theWave
		Note outWave,GetWavesDataFolder(theWave,2)
	EndFor
	outWave /= numWaves
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	
	outputDS(outWave)
End

//error (SEM) the selected waves
Function ErrorWaves()
	
	ControlInfo/W=analysis_tools errType
	String error = S_Value
	
	Variable numWaves,i

	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";")
	
	String outWaveName = NameOfWave(theWave) + "_" + error
	
	Variable dims = WaveDims(theWave)
	
	switch(dims)
		case 1:
			Make/O/N=(DimSize(theWave,0)) $outWaveName
			break
		case 2:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1)) $outWaveName
			break
		case 3:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1),DimSize(theWave,2)) $outWaveName
			break
	endswitch
	
	Wave outWave = $outWaveName 
	outWave = 0
	
	//Compute average first
	Make/FREE/N=(DimSize(outWave,0)) tempAvg
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		tempAvg += theWave
	EndFor
	outWave /= numWaves
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	
	//SEM calculation
	strswitch(error)
		case "SEM":
			Note/K outWave,num2str(numWaves) + " SEM waves included:"

			For(i=0;i<numWaves;i+=1)
				Wave theWave = $StringFromList(i,theWaveList,";")
				outWave += (theWave - tempAvg)^2
				Note outWave,GetWavesDataFolder(theWave,2)
			EndFor
			outWave = (sqrt(outWave / (numWaves -1)))/sqrt(numWaves)
			break
		case "SDEV":
			Note/K outWave,num2str(numWaves) + " SDEV waves included:"
			For(i=0;i<numWaves;i+=1)
				Wave theWave = $StringFromList(i,theWaveList,";")
				outWave += (theWave - tempAvg)^2
				Note outWave,GetWavesDataFolder(theWave,2)
			EndFor
			outWave = sqrt(outWave / (numWaves -1))
			break
	endswitch
		
	outputDS(outWave)
	
End

//Kill all the waves in the data set
Function AT_KillWaves()
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	Variable numWaves = ItemsInList(theWaveList,";")
	Variable i
	
	For(i=0;i<numWaves;i+=1)
		KillWaves/Z $StringFromList(i,theWaveList,";")
	EndFor

End