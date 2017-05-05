/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : t/ttrulwrite.p                                                  
  Description :                                                                 
  Created     : 13/12/06 Alex Leenstra                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
13/12/06 AlexL  1.00    Created
11/09/09 Sudhir 1.01    Updated p-xstac. Added comments.
25/06/10 gp     1.02    [EMM5-0802] locking problems in various sources
15/07/17 ku     1.03    [EMM6-0004] Fixes for Daily Customs.
11/09/15 Amity  1.04    [emm6-0026] check  eua or exa or t1 or ima (On the basis of order) while creating a new truck.
08/02/16 Amity  1.05    [emm6-0013] Added new field in the tdoc and ttruc system.
------------------------------------------------------------------------------*/
   
{x/xxxxlwrite.i} 
{x/xxxxpvar.i}   /*- default variables -*/
   
define variable v-xstac as char no-undo.


FUNCTION FN_CustomsRdy returns logical (p-rowid as rowid):
  /*------------------------------------------------------------------------------
    Purpose: Calculate whether truck is customs ready  
      Notes:  
  ------------------------------------------------------------------------------*/
  define variable v-ready as logi no-undo init false.
  define buffer b-ttruck for ttruck.

  find first b-ttruck no-lock where rowid(b-ttruck) = p-rowid no-error.
  if available b-ttruck then
  do:
    if b-ttruck.ttrult1 = true then do:
      assign v-ready = can-find(first tdoc no-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = b-ttruck.ttruc and tdoc.gdctc = "T1").
    end.
    else do:
      if ttru.ttruldocima then do:
        assign v-ready = can-find(first tdoc no-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = b-ttruck.ttruc and tdoc.gdctc = "IMA").
      end.
      else do:
        if b-ttruck.ttruleu1 then 
          assign v-ready = can-find(first tdoc no-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = b-ttruck.ttruc and (tdoc.gdctc = "EU1" or tdoc.gdctc = "EUA")).
        else if ttru.ttrulex1 then 
          assign v-ready = can-find(first tdoc no-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = b-ttruck.ttruc and (tdoc.gdctc = "EX1" or tdoc.gdctc = "EXA")).
      end.
    end.
  end.  
  return v-ready.
  
END FUNCTION. /*FN_CustomsRdy*/


PROCEDURE p-commit:
/*------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
------------------------------------------------------------------------------*/
/*  message 'hello from p-commit in ttrulwrite.p' view-as alert-box.*/

  define buffer b-ttruck for ttruck.

  define variable v-ttruc           as char no-undo.
  define variable v-weight          as deci no-undo. 
  define variable v-sel-pallet-nett as deci no-undo.
  define variable v-t               as inte no-undo.
  define variable v-tdocddocdt      as date no-undo.
  define variable v-tdocc           as char no-undo.
  define variable v-gdctc           as char no-undo.
  define variable v-tdocc-eu        as char no-undo.  /* amity : emm6-0013 adding new field for Eua/exa reference */

  find first ttru exclusive-lock where rowid(ttruck) = p-bufferhdl:rowid no-error no-wait.

  /*  If triggered from 'Confirm Customs' t/ttrufcustom.p   */
  assign
    v-tdocc      = f-getoutput('v-customref', p-free-input)
    v-tdocc-eu   = f-getoutput('v-euaexaref', p-free-input)  /* amity : emm6-0013 adding new field for Eua/exa reference */
    v-tdocddocdt = date(f-getoutput('v-customdate', p-free-input)).
   
  do transaction:
    if v-tdocc NE ? then
    do:
      message 'creating doc' view-as alert-box.
      assign ttru.tdocc     = v-tdocc
             ttru.tdocteu   = v-tdocc-eu.   /*amity: Emm6-0013 added new field tdoceu in ttruck table*/
      if ttru.ttrult1 = true then do:
        assign v-gdctc = "T1".
      end.
      else do:
        if ttru.ttruldocima = true then do:
          assign v-gdctc = "IMA".
          if v-tdocc begins "ART546" then v-tdocc = v-tdocc + "-" + ttru.ttruc.
        end.
        else do:
          assign v-gdctc = if ttru.ttruleu1 then "EUA" else "EXA".
        end.
      end.
      find first tdoc exclusive-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.gdctc = v-gdctc and tdoc.tdocc = v-tdocc no-error. /*amity: emm6-0013*/
      if available tdoc then 
        assign
          tdoc.tdoclaangezuiverd  = true
          tdoc.tdoctcitydedouaner = ""
          tdoc.gcouc              = ""
          tdoc.tdocddocdt         = v-tdocddocdt
          tdoc.iinvn              = ?
          tdoc.tdoclready         = true
          tdoc.ttruc              = ttru.ttruc
          tdoc.tdocdzuiverdate    = v-tdocddocdt
          tdoc.tdocteu            = v-tdocc-eu.  /* amity: emm6-0013 added new field in tdoc table*/
        
      else
      do:
        create tdoc.
        assign
          tdoc.tdoclaangezuiverd  = true
          tdoc.tdoctcitydedouaner = ""
          tdoc.gcouc              = ""
          tdoc.gdctc              = v-gdctc
          tdoc.tdocddocdt         = v-tdocddocdt
          tdoc.tdocc              = v-tdocc
          tdoc.iinvn              = ?
          tdoc.tdoclready         = true
          tdoc.ttruc              = ttru.ttruc
          tdoc.tdocdzuiverdate    = v-tdocddocdt
          tdoc.tdocteu            = v-tdocc-eu.  /* amity: emm6-0013 added new field in tdoc table*/
          
          for each cpal where cpal.ttruc = ttruck.ttruc:			/* ku v1.03: Fixes for Daily Customs */
              for each ocoi exclusive-lock where ocoi.cpaln = cpal.cpaln
                  and ocoi.ocoileu = false:
                  ocoi.tdocc = tdoc.tdocc.
                  ocoi.ocoitdocno = tdoc.tdocc.
                  ocoi.gdctc = tdoc.gdctc.
                  ocoi.ocoitcustoms = "EXIT".
              release ocoil.
              end.
          end.
         
          
      end.
      release tdoc.
    end.
  end.  /* End of transaction     */

  if p-mode = '1' or p-mode = '2' then 
  do:
  
  /*  message "hello from p-commit in ttrulwrite.p"  skip "is this functioning properly ?!" skip p-mode
  skip "check value for orgexems...before"
  view-as alert-box.*/
  
    assign v-ttruc = string(ttru.sordn) + '-0'.
    for each b-ttruck where b-ttruck.xlevc = f-xlevc('ttruck')
    and b-ttruck.sordn = ttru.sordn 
    and b-ttruck.ttruc NE ? no-lock
    by b-ttruck.ttruc:
      assign v-ttruc = b-ttruck.ttruc.
    end.
    
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttruck.sordn no-error.
    assign 
      ttru.ttruc         = string(ttru.sordn) + '-' + string(int(entry(2,v-ttruc,'-')) + 1,'99')
      ttru.gcomnclient   = sord.gcomnclient
      ttru.ttrudorgexems = ttru.ttrudexems
      ttru.ttrudpworg    = ttru.ttrudpwdate.
      
    if sord.sordlentrepot = yes then   /* amity SR [emm6-0026] check while creating a new truck */
    do:     
      if sord.sordldutypaid = no then 
        assign 
          ttruck.ttrult1     = yes
          ttruck.ttruldocima = no.
      else 
        assign
          ttruc.ttruldocima = yes
          ttruck.ttrult1    = no.   
    end. /* amity: do [emm6-0026] */
  end.

  /*  Condition check for status change of truck from 700 to 800      */
  if (ttru.ttrulloprinted) 
  and (if ttru.ttrulcmr then ttru.ttrulcmrprinted else true) 
  and (if ttru.ttrulpacklist then ttru.ttrulplprinted else true) 
  and (if ttru.ttrulapplycustoms then FN_CustomsRdy(rowid(ttruck)) else true) then
  do:
    assign v-xstac = f-xstanext("ttruck",ttru.xstac,80,true,rowid(ttruck)).
    assign ttru.xstac = v-xstac.
  end.  
  else
    assign v-xstac = f-xstanext("ttruck",ttru.xstac,79,true,rowid(ttruck)).
  assign ttru.xstac = v-xstac.
    
  release ttru.
  
END PROCEDURE. /* p-commit*/ 
  

PROCEDURE p-ttruttemp:
  /*------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
  ------------------------------------------------------------------------------*/
  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like ttruck.ttruttemp no-undo.
  def input  parameter v-oldvalue like ttruck.ttruttemp no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.
    
  find first ttru exclusive-lock where rowid(ttruck) = v-rowid no-error.
  assign ttru.ttruttemp = ''. /* forced commit / trigger */
  
  release ttru.

END PROCEDURE. /* p-ttruttemp */


PROCEDURE p-xstac:
  /*------------------------------------------------------------------------------
    Purpose: Trigger procedure run when truck status changed. 
      Notes: 1. If status reset, reset all document printed flags.
             2. If truck departed from EMS, set departure date/ set pallet status.
  ------------------------------------------------------------------------------*/
  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like ttruck.xstac no-undo.
  def input  parameter v-oldvalue like ttruck.xstac no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.
   
  find first ttru no-lock where rowid(ttruck) = v-rowid no-error.
  
  /*  Status is reset to '300', all reported document flags are reset. EUA/EUX document record is deleted.   */
  if v-oldvalue GE '700' and v-newvalue EQ '300' then 
  do:
    find current ttruck exclusive-lock.
    assign 
      ttru.ttrulcmrprinted = false
      ttru.ttrulplprinted  = false
      ttru.ttrulloprinted  = false.
      
    release ttruck.

    find first tdoc exclusive-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.gdctc = "EUA" and tdoc.ttruc = ttru.ttruc no-error.
    if available tdoc then           
      delete tdoc.              
  end.
   

  /*  Truck departed from EMS. Set depart-date; set status of all pallets in truck. Send mail   */
  if v-newvalue = '900' then 
  do: 
    for each cpal exclusive-lock where cpal.xlevc = f-xlevc('cpallet') 
    and cpal.ttruc = ttru.ttruc:
      assign v-xstac = f-xstanext("cpallet",cpal.xstac,90,true,rowid(cpallet)).
      assign
        cpal.glocc = ''
        cpal.xstac = v-xstac.                         
    end.      
  end.  
  
END PROCEDURE. /* p-xstac */


PROCEDURE p-ttrulcmr:
  /*------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
  ------------------------------------------------------------------------------*/
  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like ttruck.ttrulcmr no-undo.
  def input  parameter v-oldvalue like ttruck.ttrulcmr no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.
        
  if v-newvalue = false then   
  do:
    find first ttru exclusive-lock where rowid(ttruck) = v-rowid no-error.
    assign ttru.ttrulcmrprinted = false.
    release ttru.
  end.

END PROCEDURE. /* p-ttrulcmr */


PROCEDURE p-ttrulpacklist:
  /*------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
  ------------------------------------------------------------------------------*/
  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like ttruck.ttrulpacklist no-undo.
  def input  parameter v-oldvalue like ttruck.ttrulpacklist no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.
        
  if v-newvalue = false then   
  do:
    find first ttru exclusive-lock where rowid(ttruck) = v-rowid no-error.
    assign ttru.ttrulplprinted = false.      
    release ttru.
  end. 
  
END PROCEDURE. /* p-ttrulpacklist */
