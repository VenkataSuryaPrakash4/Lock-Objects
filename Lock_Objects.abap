*&---------------------------------------------------------------------*
*& Report Y1111111111
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT y1111111111.
*SUBMIT ZTEST111111 AND RETURN.
*IMPORT lv_name FROM MEMORY ID 'NAM'.
*nam = lv_name."Guruprasad

*1. ztcust_details --> using wa or internal table.
*2. We can not modify the primary key fields, but we refer the primary key fields and modify the non primary key fields.
*3. Modify or Update --> ztcust_details.

*DATA: wa_cust_details TYPE ztcust_details.
*SELECT SINGLE *
*       FROM ztcust_details
*       INTO wa_cust_details
*       WHERE customer_number = '1710'.
*IF wa_cust_details IS NOT INITIAL.
*   wa_cust_details-postal_code = '8974558'.
*   wa_cust_details-aadhar_number = ' '.
*   UPDATE ztcust_details from wa_cust_details.
*   clear:wa_cust_details.
*ENDIF.
*
*data:lv_kunnr type KUNNR.

*DATA:lt_cust TYPE TABLE OF  ztcust_details,
*     wa_cust TYPE ztcust_details.
*SELECT *
*  FROM ztcust_details
*  INTO TABLE lt_cust
*  UP TO 2 ROWS.
*IF sy-subrc = 0.
*  LOOP AT lt_cust INTO wa_cust.
*    wa_cust-postal_code = '532422342'.
*    MODIFY lt_cust FROM wa_cust.
*    CLEAR:wa_cust.
*  ENDLOOP.
*ENDIF.
*
*CALL FUNCTION 'ZFM_UPD_HOTEL_DATA' IN UPDATE TASK
*  EXPORTING
*    it_customer = lt_cust.
*IF sy-subrc = 0.
*  COMMIT WORK.
*ELSE.
*  ROLLBACK WORK.
*ENDIF.
DATA:lt_cust  TYPE TABLE OF ztcustomer_det,
     lwa_cust TYPE ztcustomer_det,
     lv_garg  TYPE seqg3-garg,
     lt_enq   TYPE TABLE OF seqg3,
     wa_enq   TYPE seqg3,
     lv_message TYPE string.

SELECT *
  FROM ztcustomer_det
  INTO TABLE lt_cust.

LOOP AT lt_cust INTO lwa_cust.
  lwa_cust-currency = 'INR'.

**---Record by record lock based on primary keys-----
  CALL FUNCTION 'ENQUEUE_EZCUSTOMER'
    EXPORTING
      mode_ztcustomer_det = 'E'
      mandt               = sy-mandt
      customer_number     = lwa_cust-customer_number
    EXCEPTIONS
      foreign_lock        = 1
      system_failure      = 2
      OTHERS              = 3.

*  CALL FUNCTION 'ENQUEUE_E_TABLE'
*    EXPORTING
*      mode_rstable   = 'E'
*      tabname        = 'ZTCUSTOMER_DET'
*    exceptions
*      foreign_lock   = 1
*      system_failure = 2
*      others         = 3.

  IF sy-subrc = 1.
    CONCATENATE sy-mandt lwa_cust-customer_number INTO lv_garg.

* Find the editing user
    CALL FUNCTION 'ENQUEUE_READ'
      EXPORTING
        gclient               = sy-mandt
        gname                 = 'ZTCUSTOMER_DET'
        garg                  = lv_garg "client+all keyfields(5000000000703)
      TABLES
        enq                   = lt_enq
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.
    IF sy-subrc = 0.

    ENDIF.

    READ TABLE lt_enq INTO wa_enq INDEX 1.
    IF sy-subrc = 0.
      CONCATENATE 'Customer is already locked by the user:' wa_enq-guname INTO lv_message SEPARATED BY space.

*Customer is already locked by the user:
      MESSAGE lv_message  TYPE 'S'.
    ENDIF.
  ELSE.
    MODIFY ztcustomer_det FROM lwa_cust.
    CALL FUNCTION 'DEQUEUE_EZCUSTOMER'
      EXPORTING
        mode_ztcustomer_det = 'E'
        mandt               = sy-mandt
        customer_number     = lwa_cust-customer_number.
  ENDIF.
  CLEAR:lwa_cust,lv_garg,lv_message.
ENDLOOP.
