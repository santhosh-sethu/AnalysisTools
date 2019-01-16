#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Fills the WaveProc data table column with the indicated text
Function AT_fillDTableColumn(whichTable,whichColumn,baseName,startRow,numRows,singleCell,startIndex,endIndex)
	String whichTable,whichColumn,baseName
	Variable startRow,numRows
	Variable singleCell
	String startIndex
	Variable endIndex

	Variable i,j,count,startIndexVar
	startIndexVar = str2num(startIndex)
	If(numtype(startIndexVar) == 2)
		startIndexVar = 0
	EndIf
	
	String input = ""
	SVAR DtabColumnLabels = root:CmdTableWaves:DtabColumnLabels
	Variable col = WhichListItem(whichColumn,DtabColumnLabels,";")
	Wave/T tw = WaveRefIndexed(whichTable,col,1)
	
	count = 0
	For(i=startRow;i<startRow + numRows;i+=1)
		input = ""
		If(i > DimSize(tw,0) - 1)
			//add a row to the table
			For(j=0;j<8;j+=1)
				Wave/T colWave = WaveRefIndexed(whichTable,j,1)
				InsertPoints/M=0 i+1,1,colWave
			EndFor
		EndIf
		
		If(singleCell)
			For(j=0;j<endIndex-startIndexVar+1;j+=1)
				If(!strlen(startIndex))
					input = baseName
				Else
					input += baseName + num2str(startIndexVar + j) + ","
				EndIf
			EndFor
			input = RemoveEnding(input,",")
			tw[i] = input
		Else
			input = baseName + num2str(startIndexVar + count)
			tw[i] = input
		EndIf
		count += 1
	EndFor
	
End

Function extendMask(maskWave,theWave)
	Wave maskWave,theWave
	Variable rows,cols,frames,i,j,k
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	Duplicate/O theWave,$(NameOfWave(theWave) + "_filter")
	Wave filterWave = $(NameOfWave(theWave) + "_filter")
	Redimension/S filterWave
	
	rows = DimSize(maskWave,0)
	cols = DimSize(maskWave,1)
	frames = DimSize(maskWave,2)
	//Make/FREE/N=(3,3,3) block
	Make/FREE/N=(rows,cols,frames) imageMask
	imageMask = 0
	
	For(k=0;k<frames;k+=1)
		ImageStats/P=(k) theWave
		For(i=0;i<rows;i+=1)
			For(j=0;j<cols;j+=1)
				//part of the 3D dendritic mask
				If(maskWave[i][j][k] == 1)
					//Make sure we're not on the edges of the image volume
					If(i<3 || j < 3)
						continue
					ElseIf(i > rows-4 || j > cols-4)
						continue
					EndIf
					
					//Get the surrounding 3x3x3 pixel data
					//block = theWave[i-1 + p][j-1 + q][k-1 + r]
					imageMask[i-3,i+3][j-3,j+3][k,k] = 1
					
				EndIf
			EndFor
		EndFor
	EndFor
	//apply mask
	filterWave *= imageMask
	filterWave = (filterWave == 0) ? nan : filterWave	
End

//Finds puncta in an image above a certain size threshold, and can generate fit ellipses to the data
Function AT_AnalyzeParticles(MakeEllipses,BlockEdges,MarkParticle,minSize,Frame,GraphAppend)
	Variable MakeEllipses,BlockEdges,MarkParticle,MinSize,Frame
	String GraphAppend
	
	String theWaveList = getWaveNames()
	Variable i,j
	
	For(i=0;i<ItemsInList(theWaveList,";");i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		String cdf = GetWavesDataFolder(theWave,1)
		SetDataFolder $cdf
		
		If(WaveDims(theWave) < 2)
			Abort "Wave must be at least 2D."
		ElseIf(WaveDimS(theWave) == 2)
			Frame = 0
		EndIf
		
		String cmdStr,flagStr
		flagStr = ""
		cmdStr = ""
		
		If(BlockEdges)
			flagStr += "/EBPC"
		EndIf
		If(MakeEllipses)
			flagStr += "/E"
		EndIf
		If(MarkParticle)
			flagStr += "/M=3"
		EndIf
		
		cmdStr = "ImageAnalyzeParticles" + flagStr + "/A=(" + num2str(minSize) + ")" + "/P=(" + num2str(Frame) + ") stats "
		cmdStr += NameOfWave(root:twoP_Scans:Scan_048:Scan_048_ch1_BINARY)
		Execute/Z cmdStr
		
		
		//Converts ellipses to XY waves
		If(MakeEllipses)
			Wave moments = M_Moments
			
			//Scale the moments
			Variable scaleFactor = DimDelta(theWave,1)
		//	moments = moments * scaleFactor
			
			Variable numParticles = DimSize(moments,0)
					
			
			//New folder to hold xy ellipse waves
			If(!DataFolderExists(cdf + "Ellipses"))
				NewDataFolder $(cdf + "Ellipses")
			EndIf	
			SetDataFolder $(cdf + "Ellipses")
			
			For(j=0;j<numParticles;j+=1)
				//Make the ellipse waves
				Make/O/N=361 $("particle" + num2str(j)),$("particle" + num2str(j) + "x")
				
				Ellipsoid("particle" + num2str(j),moments[j][0],moments[j][1],moments[j][2],moments[j][3],moments[j][4])
				
				//Convert to scaled data
				Wave xWave = $("particle" + num2str(j) + "x")
				Wave yWave = $("particle" + num2str(j))
				
				xWave = IndexToScale(theWave,xWave,0)
				yWave = IndexToScale(theWave,yWave,1)
				
				//Smooth out the ellipses with gaussian fits
			//	CurveFit/Q/M=2/W=2 sin, xWave/D
			//	Wave fit = $("fit_" + NameOfWave(xWave))
			//	Duplicate/O fit,xWave
			//	KillWaves/Z fit
				
			//	CurveFit/Q/M=2/W=2 sin, yWave/D
			//	Wave fit = $("fit_" + NameOfWave(yWave))
			//	Duplicate/O fit,yWave
			//	KillWaves fit
				
				If(strlen(GraphAppend))
					String traceList = TraceNameList(graphAppend,";",1)
					Wave theTrace = TraceNameToWaveRef(graphAppend,StringFromList(j,traceList,";"))
					RemoveFromGraph/W=$graphAppend theTrace
					AppendToGraph/W=$graphAppend yWave vs xWave
				EndIf
			EndFor
		EndIf	
	EndFor	
End


// This creates an ellipsoid
// INPUTS:
//   wname - name of ywave having 361 points
//              (presumes xwave of same length is named wname + "x")
//   (xo,yo) - center position of ellipse
//   (a, b) - elliptical dimesions to above
//   alpha - angle of rotation (counterclockwise)
// OUTPUTS:
//   make all changes directly in ywave and xwave

Function Ellipsoid(wname,xo,yo,a,b,alpha)
    string wname
    variable xo,yo,a,b,alpha

    wave yw = $wname
    wave xw = $(wname +"x")
    
    make/FREE/n=361 urx,ury
    
    variable cosalpha = cos(alpha*Pi/180), sinalpha = sin(alpha*Pi/180)
    
    urx = a*(cos(p*Pi/180))
    ury = b*(sin(p*Pi/180))
    
    xw = xo + cosalpha* urx - sinalpha*ury
    yw = yo + sinalpha*urx + cosalpha*ury
        
    return (0)  
end