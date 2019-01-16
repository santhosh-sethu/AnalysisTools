#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function AT_DSplot_Spikes(xStart,xEnd,threshold,maxWidth,ISI,angles,deltaAngle)
	Variable xStart,xEnd,threshold,maxWidth,ISI
	String angles
	Variable deltaAngle
	
	Variable numWaves,i,numSpikes,firstAngle
	
	//Uses the selected waves in AT itemList.
	String theWaveList = getWaveNames()
	
	numWaves = ItemsInList(theWaveList,";")
	If(numWaves == 0)
		return -1
	EndIf
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";") 
	String outWaveName = ReplaceString(StringFromList(0,NameOfWave(theWave),"_"),NameOfWave(theWave),"DSspk")
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName 
	
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		FlattenWave(theWave)
		outWave[i] = CountSpikes(theWave,xStart,xEnd,threshold,maxWidth,ISI)
	EndFor
	
	If(strlen(angles))
		orderWave(outWave,angles)
		Make/FREE/N=(numWaves) findMinAngle
		For(i=0;i<numWaves;i+=1)
			findMinAngle[i] = str2num(StringFromList(i,angles,","))
		EndFor
		firstAngle = WaveMin(findMinAngle)
		
		//Set scale according to delta and first angles
		If(deltaAngle)
			SetScale/P x,firstAngle,deltaAngle,outWave
		EndIf	
	EndIf
	
	outputDS(outWave)
	//Display the plot.
//	GetWindow/Z analysis_tools wsize // open the graph window next to the Analysis Tools window
//	Display/N=$(NameOfWave(outWave) + "_graph")/W=(V_right+10,V_top,V_right+360,V_top+200) outWave as NameOfWave(outWave)
//	SetAxis left,0,*
//	Label bottom "Angle (deg)"
//	Label left "# Spikes"
End

//Gets DS plot of the integral 
Function AT_DSplot_Integrate(BaselineStart,BaselineEnd,SignalStart,SignalEnd,angles,deltaAngle)
	Variable BaselineStart,BaselineEnd,SignalStart,SignalEnd
	String angles
	Variable deltaAngle
	
	Variable numWaves,i,numSpikes,firstAngle
	
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";") 
	String outWaveName = ReplaceString(StringFromList(0,NameOfWave(theWave),"_"),NameOfWave(theWave),"DSarea")
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName 
	
	
	//integrate the responses
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		SetScale/P x,0,1,theWave
		Variable baseline = mean(theWave,BaselineStart,BaselineEnd)
		//subtract baseline from temporary wave
		Duplicate/FREE theWave,temp
		temp -= baseline
		outWave[i] = area(temp,SignalStart,SignalEnd)
	EndFor
	
	//Figure out the angle orders.
	If(strlen(angles))
		orderWave(outWave,angles)
		Make/FREE/N=(numWaves) findMinAngle
		For(i=0;i<numWaves;i+=1)
			findMinAngle[i] = str2num(StringFromList(i,angles,","))
		EndFor
		firstAngle = WaveMin(findMinAngle)
		
		//Set scale according to delta and first angles
		If(deltaAngle)
			SetScale/P x,firstAngle,deltaAngle,outWave
		EndIf	
	EndIf
	
	//Adds the output wave to a new dataset for quick result viewing
	outputDS(outWave)
	
	//Display the plot
//	GetWindow/Z analysis_tools wsize // open the graph window next to the Analysis Tools window
//	Display/N=$(NameOfWave(outWave) + "_graph")/W=(V_right+10,V_top,V_right+360,V_top+200) outWave as NameOfWave(outWave)
//	SetAxis left,0,*
//	Label bottom "Angle (deg)"
//	Label left "Area"
End

//Gets DS plot of the peak 
Function AT_DSplot_Peak(BaselineStart,BaselineEnd,SignalStart,SignalEnd,Width,Angles,deltaAngle)
	Variable BaselineStart,BaselineEnd,SignalStart,SignalEnd,Width
	String angles
	Variable deltaAngle
	
	Variable numWaves,i,numSpikes,firstAngle
	
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";") 
	String outWaveName = ReplaceString(StringFromList(0,NameOfWave(theWave),"_"),NameOfWave(theWave),"DSpk")
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName 
	
	//find peak of the responses
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		Variable baseline = mean(theWave,BaselineStart,BaselineEnd)
		//subtract baseline from temporary wave
		Duplicate/FREE theWave,temp
		temp -= baseline
		WaveStats/Q/R=(SignalStart,SignalEnd) temp
		Variable loc = V_maxloc
		
		If(Width)
			outWave[i] = mean(temp,loc-0.5*Width,loc+0.5*Width)
		Else
			outWave[i] = V_max
		EndIf
	EndFor
	
	//Figure out the angle orders.
	If(strlen(angles))
		orderWave(outWave,Angles)
		Make/FREE/N=(numWaves) findMinAngle
		For(i=0;i<numWaves;i+=1)
			findMinAngle[i] = str2num(StringFromList(i,Angles,","))
		EndFor
		firstAngle = WaveMin(findMinAngle)
		
		//Set scale according to delta and first angles
		If(deltaAngle)
			SetScale/P x,firstAngle,deltaAngle,outWave
		EndIf	
	EndIf
	
	//Adds the output wave to a new dataset for quick result viewing
	outputDS(outWave)
	
	//Display the plot
	//GetWindow/Z analysis_tools wsize // open the graph window next to the Analysis Tools window
	//Display/N=$(NameOfWave(outWave) + "_graph")/W=(V_right+10,V_top,V_right+360,V_top+200) outWave as NameOfWave(outWave)
	//SetAxis left,0,*
	//Label bottom "Angle (deg)"
	//Label left "Peak"
End


//Gets DS plot of the peak 
Function AT_Peak(BaselineStart,BaselineEnd,SignalStart,SignalEnd,Width,Prefix)
	//HELP:Finds the peak value for each wave, puts the results into a single output wave//ENDHELP
	Variable BaselineStart,BaselineEnd,SignalStart,SignalEnd,Width
	String Prefix
	
	Variable numWaves,i
	
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";") 
	String outWaveName = ReplaceString(StringFromList(0,NameOfWave(theWave),"_"),NameOfWave(theWave),prefix)
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName 
	
	//find peak of the responses
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		Variable baseline = mean(theWave,BaselineStart,BaselineEnd)
		//subtract baseline from temporary wave
		Duplicate/FREE theWave,temp
		temp -= baseline
		WaveStats/Q/R=(SignalStart,SignalEnd) temp
		Variable loc = V_maxloc
		
		If(Width)
			outWave[i] = mean(temp,loc-0.5*Width,loc+0.5*Width)
		Else
			outWave[i] = V_max
		EndIf
	EndFor
	
	//Adds the output wave to a new dataset for quick result viewing
	outputDS(outWave)
	
	//Display the plot
	//GetWindow/Z analysis_tools wsize // open the graph window next to the Analysis Tools window
	//Display/N=$(NameOfWave(outWave) + "_graph")/W=(V_right+10,V_top,V_right+360,V_top+200) outWave as NameOfWave(outWave)
	//SetAxis left,0,*
	//Label bottom "Trial"
	//Label left "Peak"
End

//Counts the spikes over specified threshold
//isi = minimum inter spike interval (0.003 works well)
//maxWidth = maximum width for rising and falling phase of the spike (0.002 works well)
Function CountSpikes(theWave,xStart,xEnd,threshold,maxWidth,isi)
	Wave theWave
	Variable xStart,xEnd,threshold,maxWidth,isi
	Variable numSpikes,leadEdge,trailEdge
	
	FindLevels/EDGE=0/M=(isi)/Q/R=(xStart,xEnd)/T=(maxWidth) theWave,threshold
	numSpikes = V_LevelsFound
	
	//cleanup
	KillWaves/Z W_FindLevels,coefs
	return numSpikes
End

//Takes a commma delimited list of angles or any ordered number list, uses it
//to reorder the input wave
Function/WAVE orderWave(theWave,order)
	Wave theWave
	String order
	Variable numItems,i
	
	numItems = ItemsInList(order,",")
	
	If(numItems == 0)
		//Make linear sortWave if there was no order input somehow.
		Make/FREE/N=(numItems) sortWave = x
	EndIf
	
	//create order wave
	Make/FREE/N=(numItems) sortWave
	For(i=0;i<numItems;i+=1)
		sortWave[i] = str2num(StringFromList(i,order,","))
	EndFor
	
	Sort sortWave,theWave
	return theWave
End