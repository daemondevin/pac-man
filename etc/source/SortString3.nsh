/*______________________________________________________________________________
 
                            Sort String 3
________________________________________________________________________________
This script will get all text left and right of a single specified character, removing everything else. 

Usage 
	Push "( 3320 -2032 -344 ) ( 3320 -2032 -368 ) dday/mr_woodfloor1 0 23" ;input
	Push "/" ;centre character
	Push " " ;right character
	Push " " ;left character
		Call StrSortLR
	Pop $0 ;output string

$0 = dday/mr_woodfloor1                                                       */

Function StrSortLR
Exch $0 ;left character
Exch
Exch $1 ;right character
Exch
Exch 2
Exch $2 ;centre character
Exch 2
Exch 3
Exch $3 ;input string
Exch 3
Push $4
Push $5
  StrCpy $5 0
loop1:
  IntOp $5 $5 - 1
  StrCpy $4 $3 1 $5
  StrCmp $4 "" error
  StrCmp $4 $2 0 loop1
   IntOp $5 $5 + 1
 loop2:
   StrCpy $4 $3 1 $5
   IntOp $5 $5 + 1
   StrCmp $4 "" loop3
   StrCmp $4 $1 0 loop2
    IntOp $5 $5 - 1
    StrCpy $3 $3 $5
    StrCpy $5 0
  loop3:
    IntOp $5 $5 - 1
    StrCpy $4 $3 1 $5
    StrCmp $4 "" error
    StrCmp $4 $0 0 loop3
     IntOp $5 $5 + 1
     StrCpy $3 $3 "" $5
   Goto exit
error:
  StrCpy $3 error
exit:
  StrCpy $0 $3
Pop $5
Pop $4
Pop $3
Pop $2
Pop $1
Exch $0 ;output string
FunctionEnd