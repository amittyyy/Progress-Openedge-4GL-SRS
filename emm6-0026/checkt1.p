 /* ------------------------ Copyright Javra Software ---------------------------

File : script 
Description : SR [emm6-0026] to check the t1 toggle box if duty paid is uncheck and NEU is check. 
Created : 8/24/2015 amit timilsina 

Date Author Version Description 
-------- ------ ------- ---------------------------------------------------------
15/07/08 amity 1.00 Created 
--------------------------------------------------------------------------------*/
    
    DISABLE TRIGGERS FOR LOAD OF ttruck.
FOR EACH sord  EXCLUSIVE-LOCK WHERE sord.sordlentrepot = YES,
    EACH ttruc EXCLUSIVE-LOCK OF sord WHERE ttruc.sordn = sord.sordn:
    IF sord.sordldutypaid = NO THEN
    ASSIGN
         ttruc.ttrult1 = YES.
    ELSE 
        ASSIGN
            ttruc.ttruldocima = YES.
    DISPLAY ttruc.ttruc ttruc.ttrult1 ttruc.ttruldocima sord.sordldutypaid sord.sordlentrepot.
END.
