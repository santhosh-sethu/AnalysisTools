#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function test1(str)	
	String str
	print str
end

function AT_test1(str)	
	string str
	test1(str)
end