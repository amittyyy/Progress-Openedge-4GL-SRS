/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : t/ttruccustom.p                                                 
  Description :                                                                 
  Created     : 09/09/12 Sudhir Shakya                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
09/09/12 sshaky 1.00    Created
18/02/10 nsah   1.01    EMM5-0666: display value for destination.
14/07/15 ku		1.02	EMM6-0010: Added a logic in leave event for customer reference number (MRN-Nbr) according to the document provided by EU Customs.   
16/07/15 ku 	1.03	EMM6-0019: Modified the logic in validation so that user can input a temporary customer reference number.                                               
------------------------------------------------------------------------------*/
                                                                                         
{x/xxxxlparam.i}                                                                         

PROCEDURE p-before-commit:
/*------------------------------------------------------------------------------
    Event: BEFORE-COMMIT                                                        
--------------------------------------------------------------------------------
  Purpose: Pass on all screen values to ttruck commit trigger.
    Notes:                                                                      
  Created: 09/09/12 Sudhir Shakya          
 modified: 09/09/23 gp
------------------------------------------------------------------------------*/

  if f-getvalue('v-customref') = "" or f-getvalue('v-customref') = ? then
  do:
    assign p-error = 'mandatory' + chr(1) + " : T1/IMA Reference " .
    return.
  end.  
  
  if f-getvalue('v-euaexaref') = "" or f-getvalue('v-euaexaref') = ? then
  do:
    assign p-error = 'mandatory' + chr(1) + " : EUA/EXA Reference " .
    return.
  end.       
 
  if date(f-getvalue('v-customdate')) = ? then
  do:
    assign p-error = 'mandatory' + chr(1) + " : Date Customs " .
    return.
  end.
      
  assign p-result = p-allvalues.
      
END PROCEDURE. /* p-before-commit */


PROCEDURE p-leave-customdate:
/*------------------------------------------------------------------------------
    Field: v-customdate                                                         
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose: Field cannot have value greater than today's date. 
    Notes:                                                                      
  Created: 09/09/12 Sudhir Shakya                                               
------------------------------------------------------------------------------*/
  
  if date (p-value) GT today then assign p-error = 'date-today'.
  
END PROCEDURE. /* p-leave-customdate */


PROCEDURE p-after-enable:
  /*------------------------------------------------------------------------------
      Event: AFTER-ENABLE                                                         
  --------------------------------------------------------------------------------
    Purpose: Change value of ttruled3x to force commit trigger.
      Notes:                                                                      
    Created: 09/09/12 Sudhir Shakya                                               
  ------------------------------------------------------------------------------*/
  
  define variable v-ttruled3x as logi no-undo.
  
  /* get value for destination */
  find first ttru no-lock where rowid(ttruck) = p-rowid no-error.
  if available ttru then 
  do:
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error.
    if available sord then 
    do:
      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.
      if available gcom then
        find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gcom.gcouc no-error.
    end.
  end.

  assign
    v-ttruled3x = logical (f-screenvalue ('ttruled3x'))
    p-result = 'ttruled3x'    + chr (1) + string (not v-ttruled3x) + chr(1) + 
               'v-destination' + chr(1) + (if available gcom then gcom.gcomtshortname + (if available gcou then ', ' + gcou.gcoum else '') else ''). /* EMM5-0666: display destination */

END PROCEDURE. /* p-after-enable */




procedure p-leave-custref:
/*------------------------------------------------------------------------------
    Field: v-customref                                                          
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 15/07/13 Kushal Basnet                                               
------------------------------------------------------------------------------*/

/* ku v1.02 :  Added a logic in leave event for customer reference number (MRN-Nbr) according to the document provided by EU Customs. */

define variable v-custref as character no-undo.
define variable v-count as integer no-undo.
define variable v-str1 as character no-undo.
define variable v-multiples as integer no-undo.
define variable v-subtotal as integer no-undo.
define variable v-total as integer init 0 no-undo.
define variable v-rem as integer no-undo.
define variable v-tempnbr as character no-undo.
                                                                                                                                                                           
    if (not p-value begins "ART546") and (not p-value begins "T") then    /* ku v1.03 : Modified the logic in validation so that */
    do:																	  /* user can input a temporary customer reference number. */	
        assign v-custref = p-value.
        if length(v-custref) eq 18 then
        do:
            do v-count = 1 to (length(v-custref) - 1):
            
            assign v-str1 = substring(v-custref, v-count , 1).
            
            /* Table implementation */
            if v-str1 = "A" then v-str1 = "10".
            else if v-str1 = "B" then v-str1 = "12".
            else if v-str1 = "C" then v-str1 = "13".
            else if v-str1 = "D" then v-str1 = "14".
            else if v-str1 = "E" then v-str1 = "15".
            else if v-str1 = "F" then v-str1 = "16".
            else if v-str1 = "G" then v-str1 = "17".
            else if v-str1 = "H" then v-str1 = "18".
            else if v-str1 = "I" then v-str1 = "19".
            else if v-str1 = "J" then v-str1 = "20".
            else if v-str1 = "K" then v-str1 = "21".
            else if v-str1 = "L" then v-str1 = "23".
            else if v-str1 = "M" then v-str1 = "24".
            else if v-str1 = "N" then v-str1 = "25".
            else if v-str1 = "O" then v-str1 = "26".
            else if v-str1 = "P" then v-str1 = "27".
            else if v-str1 = "Q" then v-str1 = "28".
            else if v-str1 = "R" then v-str1 = "29".
            else if v-str1 = "S" then v-str1 = "30".
            else if v-str1 = "T" then v-str1 = "31".
            else if v-str1 = "U" then v-str1 = "32".
            else if v-str1 = "V" then v-str1 = "34".
            else if v-str1 = "W" then v-str1 = "35".
            else if v-str1 = "X" then v-str1 = "36".
            else if v-str1 = "Y" then v-str1 = "37".
            else if v-str1 = "Z" then v-str1 = "38".
            
            assign v-multiples = exp(2,(v-count - 1))
                   v-subtotal  = v-multiples * integer(v-str1)
                   v-total = v-total + v-subtotal.
 
            end.
            
            assign v-rem = v-total mod 11.
            if v-rem eq 10 then v-rem = 0.
            
            if integer(substring(v-custref, 18, 1)) ne v-rem then
                p-error = "custrefinval".
            
        end.
        else 
            p-error = "custrefnum".
    end.
    else 
    do:
        if p-value begins "T" and length(substring(p-value, 2)) ne 18 then
            p-error = "custrefnum".

    end.
  
END PROCEDURE. /* p-leave-custref */

/*procedure p-leave-euaexaref:                                                                                                               */
/*/*------------------------------------------------------------------------------                                                           */
/*    Field: v-customref                                                                                                                     */
/*    Event: LEAVE                                                                                                                           */
/*--------------------------------------------------------------------------------                                                           */
/*  Purpose:                                                                                                                                 */
/*    Notes:                                                                                                                                 */
/*  Created: 02/05/2015 amity timalsina                                                                                                      */
/*------------------------------------------------------------------------------*/                                                           */
/*                                                                                                                                           */
/*/* amity v1.02 :  Added a logic in leave event for customer reference number (MRN-Nbr) according to the document provided by EU Customs. */*/
/*                                                                                                                                           */
/*define variable v-euaexaref as character no-undo.                                                                                          */
/*define variable v-count as integer no-undo.                                                                                                */
/*define variable v-str1 as character no-undo.                                                                                               */
/*define variable v-multiples as integer no-undo.                                                                                            */
/*define variable v-subtotal as integer no-undo.                                                                                             */
/*define variable v-total as integer init 0 no-undo.                                                                                         */
/*define variable v-rem as integer no-undo.                                                                                                  */
/*define variable v-tempnbr as character no-undo.                                                                                            */
/*                                                                                                                                           */
/*    if (not p-value begins "ART546") and (not p-value begins "T") then    /* amity v1.03 : Modified the logic in validation so that */     */
/*    do:                                                                   /* user can input a temporary customer reference number. */      */
/*        assign v-euaexaref = p-value.                                                                                                      */
/*        if length(v-euaexaref) eq 18 then                                                                                                  */
/*        do:                                                                                                                                */
/*            do v-count = 1 to (length(v-euaexaref) - 1):                                                                                   */
/*                                                                                                                                           */
/*            assign v-str1 = substring(v-euaexaref, v-count , 1).                                                                           */
/*                                                                                                                                           */
/*            /* Table implementation */                                                                                                     */
/*            if v-str1 = "A" then v-str1 = "10".                                                                                            */
/*            else if v-str1 = "B" then v-str1 = "12".                                                                                       */
/*            else if v-str1 = "C" then v-str1 = "13".                                                                                       */
/*            else if v-str1 = "D" then v-str1 = "14".                                                                                       */
/*            else if v-str1 = "E" then v-str1 = "15".                                                                                       */
/*            else if v-str1 = "F" then v-str1 = "16".                                                                                       */
/*            else if v-str1 = "G" then v-str1 = "17".                                                                                       */
/*            else if v-str1 = "H" then v-str1 = "18".                                                                                       */
/*            else if v-str1 = "I" then v-str1 = "19".                                                                                       */
/*            else if v-str1 = "J" then v-str1 = "20".                                                                                       */
/*            else if v-str1 = "K" then v-str1 = "21".                                                                                       */
/*            else if v-str1 = "L" then v-str1 = "23".                                                                                       */
/*            else if v-str1 = "M" then v-str1 = "24".                                                                                       */
/*            else if v-str1 = "N" then v-str1 = "25".                                                                                       */
/*            else if v-str1 = "O" then v-str1 = "26".                                                                                       */
/*            else if v-str1 = "P" then v-str1 = "27".                                                                                       */
/*            else if v-str1 = "Q" then v-str1 = "28".                                                                                       */
/*            else if v-str1 = "R" then v-str1 = "29".                                                                                       */
/*            else if v-str1 = "S" then v-str1 = "30".                                                                                       */
/*            else if v-str1 = "T" then v-str1 = "31".                                                                                       */
/*            else if v-str1 = "U" then v-str1 = "32".                                                                                       */
/*            else if v-str1 = "V" then v-str1 = "34".                                                                                       */
/*            else if v-str1 = "W" then v-str1 = "35".                                                                                       */
/*            else if v-str1 = "X" then v-str1 = "36".                                                                                       */
/*            else if v-str1 = "Y" then v-str1 = "37".                                                                                       */
/*            else if v-str1 = "Z" then v-str1 = "38".                                                                                       */
/*                                                                                                                                           */
/*            assign v-multiples = exp(2,(v-count - 1))                                                                                      */
/*                   v-subtotal  = v-multiples * integer(v-str1)                                                                             */
/*                   v-total = v-total + v-subtotal.                                                                                         */
/*                                                                                                                                           */
/*            end.                                                                                                                           */
/*                                                                                                                                           */
/*            assign v-rem = v-total mod 11.                                                                                                 */
/*            if v-rem eq 10 then v-rem = 0.                                                                                                 */
/*                                                                                                                                           */
/*            if integer(substring(v-euaexaref, 18, 1)) ne v-rem then                                                                        */
/*                p-error = "custrefinval".                                                                                                  */
/*                                                                                                                                           */
/*        end.                                                                                                                               */
/*        else                                                                                                                               */
/*            p-error = "custrefnum".                                                                                                        */
/*    end.                                                                                                                                   */
/*    else                                                                                                                                   */
/*    do:                                                                                                                                    */
/*        if p-value begins "T" and length(substring(p-value, 2)) ne 18 then                                                                 */
/*            p-error = "custrefnum".                                                                                                        */
/*                                                                                                                                           */
/*    end.                                                                                                                                   */
/*                                                                                                                                           */
/*END PROCEDURE. /* p-leave-euaexaref */                                                                                                     */



