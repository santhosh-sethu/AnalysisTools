﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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