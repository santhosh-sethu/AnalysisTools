#pragma rtGlobals=1	// Use modern global access method.
#include <New Polar Graphs>


Function AT_averagewavesSS(emptystring)

string emptystring
string wavenames = tracenamelist("",";",1)

variable tottraces = itemsinlist(wavenames)

wave  trace = Tracenametowaveref("",stringfromlist(0,wavenames))

Duplicate/O trace, Source


string axisnames = axislist("")
variable numaxes = itemsinlist(axisnames)


variable i, j, k, numleft,numbottom, numtraces
for(i = 0; i<numaxes; i+=1)
	if(WhichListItem("left_"+num2str(i),axisnames)>-1)
		numleft+=1
	endif
	if(WhichListItem("bottom_"+num2str(i),axisnames)>-1)
		numbottom+=1
	endif

endfor
print numleft, numbottom

string leftaxis, bottomaxis, tracename,AVGname, tempStr, AVGleftaxis, AVGbottomaxis
variable RunOnce = 0
variable Gred, Gblue, Ggreen
for(i = 0; i < numbottom;i+=1)

	for(j = 0; j < numleft; j+=1)
		Source = 0
		numtraces = 0
		RunOnce = 0
		for (k = 0; k < tottraces; k+=1)
			tracename = stringfromlist(k,wavenames)
			wave tracer = Tracenametowaveref("",tracename)
			leftaxis = stringbykey("YAXIS", traceinfo("",tracename,0))
			bottomaxis = stringbykey("XAXIS", traceinfo("",tracename,0))
			
			if(cmpstr(bottomaxis,"bottom_"+num2str(i))==0 && cmpstr(leftaxis,"left_"+num2str(j))==0)
				MatrixOP/O Source = tracer+Source
				numtraces+=1
				if(RunOnce == 0)
					tempStr = stringbyKey("rgb(x)",traceinfo("",tracename,0),"=")
					sscanf tempStr, "(%d,%d,%d)", Gred, Gblue, Ggreen
					AVGleftaxis = leftaxis
					AVGbottomaxis = bottomaxis
				endif
				RunOnce+=1
			endif
	
		endfor
		
		Source = source/numtraces

		AVGname = winname(0,1)+"_L"+num2str(j)+"B"+num2str(i)+"_AVG"
		
		
		duplicate/O Source, $AVGname
		appendtograph /B = $AVGbottomaxis /L = $AVGleftaxis $AVGname
		Modifygraph lsize($AVGname) = 2
		Modifygraph rgb($AVGname) = (Gred,Gblue,Ggreen)
	endfor
endfor


end