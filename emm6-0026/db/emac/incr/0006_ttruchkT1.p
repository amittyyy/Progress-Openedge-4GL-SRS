 /* ------------------------ Copyright Javra Software ---------------------------

File : script 
Description : SR [EMM6-0026]to check the t1 toggle box if duty paid is uncheck and NEU is check. 
Created : 8/24/2015 amit timilsina 

Date Author Version Description 
-------- ------ ------- ---------------------------------------------------------
15/07/08 amity 1.00 Created 
Reason:[EMM6-0013] change biz-logics regarding customs doc
--------------------------------------------------------------------------------*/
    
    DISABLE TRIGGERS FOR LOAD OF ttruck.   /* amity: to disable the trigger */
FOR EACH sord  EXCLUSIVE-LOCK WHERE sord.sordlentrepot = YES,
    EACH ttruc EXCLUSIVE-LOCK OF sord WHERE ttruc.sordn = sord.sordn:
    IF sord.sordldutypaid = NO THEN
    ASSIGN
         ttruc.ttrult1      = YES
         ttruc.ttruldocima  = no.
    ELSE 
        ASSIGN
            ttruc.ttruldocima = YES
	    ttruc.ttrult1     = NO.
  /*  DISPLAY ttruc.ttruc ttruc.ttrult1 ttruc.ttruldocima sord.sordldutypaid sord.sordlentrepot.*/
END.  /* amity:  FOR EACH sord*/
