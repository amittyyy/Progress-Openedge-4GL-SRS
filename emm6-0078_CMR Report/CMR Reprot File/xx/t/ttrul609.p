/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : t/ttrul609.p                                                    
  Description :                                                                 
  Created     : 11/01/07 Kalash Shrestha                                        
                                                                                
Date     Author Version     Description                                             
-------- ------ ----------  ----------------------------------------------------
11/01/07 Kalash 1.00        Created  
04/09/09 Mohan  1.2          EMM5-0380   Made the changes compatible with the new source of EMM4.
07/12/09 Mohan  1.3          EMM5-0567   Added the information in the vak16 field.     
2/18/15  Neha   1.4          EMM6-0078: Relation of v-vak16 was removed in the cmr report                          
------------------------------------------------------------------------------*/
                                                                                         
{x/xxxxlparam.i}  
                                                                      
def var gEuromit as inte no-undo init 10000. /*a constant, or gloabl variable*/

PROCEDURE p-leave:
  /*------------------------------------------------------------------------------
       File: ttruck (Trucks)                                                      
      Field: v-ttruc                                                              
      Event: LEAVE                                                                
  --------------------------------------------------------------------------------
    Purpose: On leave of truck number several fields are assigned with records from order 
             and truck and shown in the report output.                                                                    
      Notes:                                                                      
    Created: 11/01/07 Kalash Shrestha                                             
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-leave in ttrul609.p' view-as alert-box.*/

  define variable v-ttruc  as char no-undo.
  define variable v-vak01  as char no-undo.  
  define variable v-vak01a as char no-undo.
  define variable v-vak01b as char no-undo.
  define variable v-vak01c as char no-undo.
  define variable v-vak01d as char no-undo.
  define variable v-vak02  as char no-undo.  
  define variable v-vak02a as char no-undo.
  define variable v-vak02b as char no-undo.
  define variable v-vak02c as char no-undo.
  define variable v-vak02d as char no-undo.
  define variable v-vak03  as char no-undo.
  define variable v-vak04  as char no-undo.
  define variable v-vak04b as char no-undo.
  define variable v-vak05  as char no-undo.
  define variable v-vak06  as char no-undo.
  define variable v-vak13  as char no-undo.
  define variable v-vak16  as char no-undo.
  define variable v-vak16b as char no-undo.
  define variable v-vak16c as char no-undo.
  define variable v-vak16d as char no-undo.
  define variable v-vak18  as char no-undo.
  define variable v-vak18b as char no-undo.
  define variable v-vak18c as char no-undo.
  define variable vmessage as char no-undo.
  define variable v-coun1  as char no-undo. 
   
  define buffer bfTpt for gcompany.
  define buffer bfAgt for gcompany.
  define buffer b1-gcountry for gcou.
 
  if not can-find(first ttru no-lock where ttru.xlevc = f-xlevc('ttruck') and ttru.ttruc = f-getvalue('v-ttruc')) then 
  do:
    vmessage = vmessage + chr(1) +  'Truck does not exist !'.
    assign v-ttruc = ''. 
    assign p-result = 'v-ttruc' + chr(1) + v-ttruc.   
  end.
  else do:
    for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.ttruc = f-getvalue('v-ttruc'),  
    first sord no-lock where sord.xlevc = f-xlevc('sorder')
    and sord.sordn = ttru.sordn,
    first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
    and gcom.gcomn = sord.gcomnclient,
    first bfAgt where bfAgt.xlevc = f-xlevc('gcompany')
    and bfAgt.gcomn = sord.gcomnagent,
    first bfTpt where bfTpt.xlevc = f-xlevc('gcompany')
    and bfTpt.gcomn = ttru.gcomnforwarder:
      case sord.sordtpay4tpt:
        when "Agent" then 
        do:
          /*EMM5-0380:- Changed the query, previous query was wrong*/
          find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = bfAgt.gcomn and gadr.gadrttype = 'P' no-error.
          find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc no-error.
          assign 
            v-vak01  = gadr.gadrtname
            v-vak01b = (if available gadr then gadr.gadrtstreet1 else '')
            v-vak01c = (if available gadr then gadr.gadrtzipcode else '') + "  " + (if available gadr then gadr.gadrtcity else '')
            v-vak01d = (if available gcou then gcou.gcoum else '')
            .        
        end.
        when "Client" then 
        do:                                                          
          /*EMM5-0380:- Changed the query, previous query was wrong*/
           find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = gcom.gcomn and gadr.gadrttype = 'P' no-error.
           find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc no-error.             
           assign 
             v-vak01  = gcom.gcomm
             v-vak01b = (if available gadr then gadr.gadrtstreet1 else '')
             v-vak01c = (if available gadr then gadr.gadrtzipcode else '') + "  " + (if available gadr then gadr.gadrtcity else '')
             v-vak01d = (if available gcou then gcou.gcoum else '')
             .
        end.
        /*
        when "EMS" then do:
          find gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = gEuromit and gadr.gadrttype = 'P' no-error.
          find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc.
          assign 
            v-vak01  = gcom.gcomm
            v-vak01b = (if available gadr then gadr.gadrtstreet1 else '')
            v-vak01c = (if available gadr then gadr.gadrtzipcode else '') + "  " + (if available gadr then gadr.gadrtcity else '')
            v-vak01d = gcou.gcoum
            .
        end.
        otherwise message "oops! call 566 some inconsistent data ?!" view-as alert-box.
        */
      end case.
      find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = bfTpt.gcomn and gadr.gadrttype = "D" no-error.
      find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc no-error.     
      if available gadr then 
      do:
        find first b1-gcountry no-lock where b1-gcountry.xlevc = f-xlevc('gcountry') and b1-gcountry.gcouc = sord.gcouc no-error.
        if available b1-gcountry then assign v-coun1 = b1-gcountry.gcoum.
        find first scdm no-lock where scdm.xlevc = f-xlevc('scdm') and scdm.gcomnclient = sord.gcomnclient.
        assign
          v-vak02  = sord.sordtdesti-name
          v-vak02b = sord.sordtdesti-address
          v-vak02c = trim(sord.sordtdesti-zipcode + "  " + sord.sordtdesti-city)
          v-vak02d = (if available b1-gcountry then b1-gcountry.gcoum else '') /*if sord.gcouc NE ' ' and sord.gcouc NE ? then sord.gcouc else '' /*Mohan,EMM5-0380:- checked if it is empty*/*/
          v-vak13  = scdm.scdmtcmrvak13
        /*  v-vak16  = bfTpt.gcomm   */     /*Neha EMM6-0078: Relation of v-vak16 was removed in the cmr report */
/*          v-vak16b = gadr.gadrtstreet1*/
/*          v-vak16c = trim(gadr.gadrtzipcode ) + "  " + (gadr.gadrtcity )*/
/*          v-vak16d = (if available gcountry then gcou.gcoum else '') /*gcou.gcoum /*gadr.gcouc*/*/*/
          v-vak03  = if sord.gcouc NE ' ' and sord.gcouc NE ? and sord.sordtdesti-city NE ? and sord.sordtdesti-city NE ' ' then (sord.sordtdesti-city + "/" + v-coun1) else ''  /* nandeshwar, display country name */  
          v-vak04  = "EURO-MIT STAAL BV,"
          v-vak04b = "VLISSINGEN, HOLLAND"
          v-vak05  = "PACKLIST, MILLSHEET"
          v-vak06  = sord.sordtdlvterms
          v-vak18  = ttru.ttruttrucklicno
          v-vak18b = ttru.ttruttrailerlicno
          v-vak18c = ttru.ttrutsealno
          .
      end.
    end. /*for-first-ttru*/
  end.
  assign p-result = 
    'v-vak01'  + chr(1) + v-vak01  + chr(1) +
    'v-vak01b' + chr(1) + v-vak01b + chr(1) +
    'v-vak01c' + chr(1) + v-vak01c + chr(1) +
    'v-vak01d' + chr(1) + v-vak01d + chr(1) +
    'v-vak02'  + chr(1) + v-vak02  + chr(1) +
    'v-vak02b' + chr(1) + v-vak02b + chr(1) +
    'v-vak02c' + chr(1) + v-vak02c + chr(1) +
    'v-vak02d' + chr(1) + v-vak02d + chr(1) +
    'v-vak03'  + chr(1) + v-vak03  + chr(1) +
    'v-vak04'  + chr(1) + v-vak04  + chr(1) +
    'v-vak04b' + chr(1) + v-vak04b + chr(1) +
    'v-vak05'  + chr(1) + v-vak05  + chr(1) +
    'v-vak06'  + chr(1) + v-vak06  + chr(1) +
    'v-vak13'  + chr(1) + v-vak13  + chr(1) +
/*    'v-vak16'  + chr(1) + v-vak16  + chr(1) +*/ 
/*    'v-vak16b' + chr(1) + v-vak16b + chr(1) +*/
/*    'v-vak16c' + chr(1) + v-vak16c + chr(1) +*/
/*    'v-vak16d' + chr(1) + v-vak16d + chr(1) +*/
    'v-vak18'  + chr(1) + v-vak18  + chr(1) +
    'v-vak18b' + chr(1) + v-vak18b + chr(1) +
    'v-vak18c' + chr(1) + v-vak18c
    .

END PROCEDURE. /* p-leave */
