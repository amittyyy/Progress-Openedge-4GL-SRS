/* ------------------------------------  ---------------------------------------
                                                                                
  File        : x/xaudrred.p                                                    
  Description :                                                                 
  Created     : 15/08/18 Kushal Basnet                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
15/08/18 kushal 1.00    Created                                                 
------------------------------------------------------------------------------*/

{x/xaudrred.s}
{x/xxxxrhdr.i} 

define variable iBaseDate  as date no-undo.
define variable ibatchconf as logical no-undo.

assign 
    iBaseDate   = v-basedate
    ibatchconf  = v-batchconf.
    
if ibatchconf = yes then
            iBaseDate = ADD-INTERVAL(TODAY, -3, "months") - DAY(TODAY) + 1.

put unformatted 
    "begin zap " string(time,"hh:mm:ss") skip.

put unformatted 
    "Delete Audit up to :  " iBaseDate skip(4).

disable triggers for load of xaud.
  
for each xaudit where xaud.xaudd LT iBaseDate exclusive-lock:
    delete  xaud.
end.

put unformatted 
    "end zap " string(time,"hh:mm:ss") skip.



{x/xxxxrftr.i}                                                                  
