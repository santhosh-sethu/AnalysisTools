#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function AT_EphysTraces(VoltWinName, batchsize,noTrials, channel)


string VoltWinName 
variable batchsize, noTrials, channel
//The ROIs and the scans
SVAR scanListStr = root:Packages:twoP:examine:scanListStr
SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
Wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
Wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
NVAR Gbslnst = root:packages:analysisTools:Gbslnst 
NVAR Gbslnend = root:packages:analysisTools:Gbslnend 
NVAR Gpeakst = root:packages:analysisTools:Gpeakst 
NVAR GpeakEnd = root:packages:analysisTools:GpeakEnd

variable TotScans = CountObjectsDFR($("root:twoP_Scans:"),4)

string FullscansList= ""
variable i ,j,ScanNum 
for (i = 0; i < TotScans;i+=1)
	string xx = GetIndexedObjNameDFR($("root:twoP_Scans:"),4,i)
	FullscansList = AddListItem(xx,FullscansList,";",inf)
endfor	


DoWindow PeaksTable
if(V_flag)
	DoWindow/F PeaksTable
else
	edit/N=PeaksTable	
endif


wave VoltPeaks = $("root:ROI_analysis:VoltPeaks")
if(waveexists(VoltPeaks))
else
	Make/N = (TotScans) $("root:ROI_analysis:VoltPeaks")
endif
Appendtotable/W = PeaksTable VoltPeaks

//window to be plotted in

doWindow/F $VoltWinName 

if(V_Flag) 
else	
	Display/N = $VoltWinName 
endif
	
	

variable numScans = ItemsInList(scanListStr,";")


if(batchsize == 8)
		//if(waveExists(order)==0)
			make/o/n = (batchsize) order,direction
			wave order = order
			//order = {3,5,7,0,2,4,6,1}	// traces displayed in this specific order --> {225,270,315,0,45,90,135,180}   //old values: order = {6,1,5,3,7,0,4,2} 	
			order = {0,2,4,6,1,3,5,7}
			//order = {0,2,4,6,1,3,5,7}//old order {0,180,45,225,90,270,135,315}
			direction = {0,45,90,135,180,225,270,315}
			wave direction = direction
		//else
		//endif 
	else 
	make/o/n = (batchsize) order
	for (j = 0; j < batchsize; j+=1)
		order[j] = j
	endfor
endif

string theScanName, axisName

variable l, st_pt, end_pt, k
for ( i = 0; i <noTrials; i+=1)
	for (j = 0; j < batchsize; j+=1)
		theScanName = StringFromList((j+1)*(i+1)-1,scanListStr,";")
		print theScanName
		ScanNum = WhichListItem(theScanName,FullscansList,";")
		print ScanNum
		Wave/Z theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ep"+num2str(channel))
		
		VoltPeaks[ScanNum] = (wavemax(theScan,GpeakSt,GpeakEnd) - mean(theScan,GbslnSt,GbslnEnd))*1000
		
		FindValue /V = (j) order
		l = V_value+1
		
		st_pt = 1/batchsize*(l-1)+.005  //divide the graph equally for the number of directions and space the plots for each direction.
	
		end_pt = 1/batchsize*l-.005
	
		k = order(l-1)
			
		axisname = "axis"+ theScanName+"trace" //axis handle

		appendtograph/W = $VoltWinName /B=$axisname theScan
		DoWindow/F $VoltWinName

			
			
		ModifyGraph axisEnab($axisname)={st_pt,end_pt} //position graph
		ModifyGraph standoff=1,freePos($axisname)={0,left}
		//ModifyGraph rgb($theScanName) =(red,green,blue)
		
		
		
		
	
	endfor
endfor	


end