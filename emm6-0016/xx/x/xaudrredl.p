/* ------------------------------------  ---------------------------------------
                                                                                
  File        : x/xaudrredl.p                                                   
  Description :                                                                 
  Created     : 15/08/18 Kushal Basnet                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
15/08/18 kushal 1.00    Created                                                 
------------------------------------------------------------------------------*/
                                                                                         
{x/xxxxlparam.i}                                                                         




procedure p-choose:
/*------------------------------------------------------------------------------
    Field: v-button                                                             
    Event: CHOOSE                                                               
--------------------------------------------------------------------------------
  Purpose: To manually reduce xaudit table directly from the program.                                                                     
    Notes:                                                                      
  Created: 15/08/18 Kushal Basnet                                               
------------------------------------------------------------------------------*/

define variable iBaseDate  as date no-undo.
define variable ibatchconf as logical no-undo.
define variable v-output   as character no-undo.

assign iBaseDate    = date(f-screenvalue('v-basedate'))
       ibatchconf   = logical(f-screenvalue('v-batchconf')).

    if iBaseDate <> ? then
    do:
        find first xsystem no-lock no-error.
        if avail xsystem then
            assign v-output = xsystem.xsysttempdir.

        output to value(v-output + "xaudrred.txt").

        put unformatted
            "begin zap " string(time,"hh:mm:ss") skip.

        put unformatted
            "Delete Audit up to :  " iBaseDate skip(4).

        message "Delete audit up to " iBaseDate
            view-as alert-box question buttons yes-no update vAnswer as logi.

        if vAnswer = true then
        do:
            disable triggers for load of xaud.

            for each xaudit where xaud.xaudd LT iBaseDate exclusive-lock:
                delete xaud.
            end.
        end.

        put unformatted
            "end zap " string(time,"hh:mm:ss") skip.

        output close.

        os-command silent value(v-output + "xaudrred.txt").
    end.

else
    message "Enter the Date First!" view-as alert-box.

END PROCEDURE. /* p-choose */



