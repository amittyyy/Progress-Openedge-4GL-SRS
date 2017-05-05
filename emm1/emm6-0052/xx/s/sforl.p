/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
 
  File        : s/sforl.p 
  Description : 
  Created     : 25/01/07 Alex Leenstra 
 
Date     Author Version Description 
-------- ------ ------- --------------------------------------------------------
25/01/07 AlexL  1.00    Created 
06/08/09 Mohan  1.01    EMM5-0235 Fixed the problem of not displaying the grade on browser. 
25/09/15 Amity  1.02    EMM6-0052 added radio button for EU or NEU in forecast sales and forecast purchase.
------------------------------------------------------------------------------*/
 
{x/xxxxlparam.i} 

PROCEDURE p-question:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START 
--------------------------------------------------------------------------------
  Purpose: 
    Notes: 
  Created: 25/01/07 Alex Leenstra 
------------------------------------------------------------------------------*/
  find first sfor no-lock where rowid(sforecast) = p-rowid no-error.

  define variable h-browse as handle no-undo.

  h-browse = f-handle('v-browse01').

  assign p-error = 'Forder' + chr(1) + string(h-browse:num-selected-rows)  + chr(1) + (if sfor.sforlftype then 'Sales' else 'Purchase').

END PROCEDURE. /* p-question */


PROCEDURE p-transfer:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START 
  --------------------------------------------------------------------------------
    Purpose: 
      Notes:                                                                      
            - this proc is fired by event
    Created: 25/01/07 Alex Leenstra                                               
  ------------------------------------------------------------------------------*/
  define variable h-browse as handle no-undo.
  define variable h-query  as handle no-undo. 
  define variable h-buffer as handle no-undo.
  define variable h-field  as handle no-undo.
  define variable v-xstac as char no-undo.

  assign 
    h-browse = f-handle('v-browse01')
    h-query  = h-browse:query 
    h-buffer = h-query:get-buffer-handle(1) no-error.
 
  if f-getvalue('answer') NE 'true' then return.
 
  do v-cnt = h-browse:num-selected-rows to 1 by -1: /* all selected records in the browser  */
    assign v-ok = h-browse:fetch-selected-row(v-cnt).
    find first sfor exclusive-lock where rowid(sforecast) = h-buffer:rowid no-error.
    assign v-xstac = f-xstanext("sforecast",sfor.xstac,100,true,rowid(sforecast)).
    assign sfor.xstac = v-xstac.
    release sfor. 
  end.
  assign p-action = 's-qryreopen'.
 
END PROCEDURE. /* p-transfer */


PROCEDURE p-leave-sfran:
/*------------------------------------------------------------------------------
     File: sforecast (Forecasts) 
    Field: sfran (Contract number)                                              
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose:   Shows job in job field. 
    Notes:                                                                      
  Created: 17/02/07 Kalash Shrestha                                             
------------------------------------------------------------------------------*/

  find first sfra no-lock where sFra.xlevc = f-xlevc('sFramecont') and sFra.sfran = integer(p-value) no-error.
  assign p-result = 'gjobc' + chr(1) + if available sFra then sFra.gjobc else ''.

END PROCEDURE. /* p-leave-sfran */


PROCEDURE p-display-framecontract:
/*------------------------------------------------------------------------------
    Event: ROW-DISPLAY 
--------------------------------------------------------------------------------
  Purpose: 
    Notes:                                                                      
  Created: 09/06/30 Mohan Niroula 
  Changed: 10/07/28 GP EMM5-0773 
------------------------------------------------------------------------------*/
  define variable returnvalue as inte no-undo.
  define variable v-weeknum   as inte no-undo. 
  define variable v-day       as inte no-undo.
  define variable v-first     as date no-undo.

  find first sfor no-lock where rowid(sforecast) = f-getrowid('sforecast') no-error.
  if available sfor then
  do:
    run proc/weeknum.p(input sfor.sfordfordate, output v-weeknum).

    /* assign returnvalue = year(sfor.sfordfordate) mod 10 * 100 + (inte(v-weeknum) mod 100) * 1.*/
    assign returnvalue = v-weeknum mod 1000.
    assign p-result = 'v-yearweek' + chr(1) + string(returnvalue).
    for first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') 
    and gcom.gcomn = sfor.gcomnclient,
    each ggra no-lock where ggra.xlevc = f-xlevc('ggrade')
    and ggra.ggrac = sfor.ggrac:
      assign p-result = p-result + chr (1) + 'v-ggram' + chr(1) + string(ggra.ggram).
    end.
    find first sFra no-lock where sFra.xlevc = f-xlevc('sframecont')
    and sFra.sfran = sfor.sfran no-error.
      if available sFra then
        assign p-result = p-result + chr(1) + 'v-sfram2' + chr(1) + sFra.sfram.
      else
        assign p-result = p-result + chr(1) + 'v-sfram2' + chr(1) + ''.
  end.  /* if available sforecast then do */

END PROCEDURE. /* p-display-framecontract */

PROCEDURE p-show-Eu-Neu:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START 
--------------------------------------------------------------------------------
  Purpose: 
    Notes: [EMM6-0052]
  Created: 25/09/2015 Amity Timalsina 
------------------------------------------------------------------------------*/
find first sforecast no-lock where rowid(sforecast) = f-getrowid('sforecast') no-error.
find first sorder no-lock where sorder.sfran = sforecast.sfran no-error.
/*find first ocoil no-lock where ocoil.sordn = sorder.sordn no-error.*/

if available sorder then 
do:
  if sorder.sordleu = true then 
    assign p-result = 'v-forcustoms' + chr(1) + '0'.
  else
    assign p-result = 'v-forcustoms' + chr(1) + '1'.
end.
else 
  message "Sales order not assigned as Eu or NEu, Please check !"
    view-as alert-box information.
    
END PROCEDURE. /* p-show-Eu-Neu */
