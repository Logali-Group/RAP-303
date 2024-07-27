class lcl_buffer definition.

  public section.
    constants: created type c length 1 value 'C',
               updated type c length 1 value 'U',
               deleted type c length 1 value 'D'.

    types: begin of ty_buffer_master.
             include type zhc_303_master as data.
    types:   flag type c length 1,
           end of ty_buffer_master.

    types: tt_master type sorted table of ty_buffer_master with unique key e_number.

    class-data mt_buffer_master type tt_master.

endclass.

class lhc_HCMMaster definition inheriting from cl_abap_behavior_handler.
  private section.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for HCMMaster result result.

    methods create for modify
      importing entities for create HCMMaster.

    methods update for modify
      importing entities for update HCMMaster.

    methods delete for modify
      importing keys for delete HCMMaster.

    methods read for read
      importing keys for read HCMMaster result result.

    methods lock for lock
      importing keys for lock HCMMaster.

endclass.

class lhc_HCMMaster implementation.

  method get_instance_authorizations.
  endmethod.

  method create.

    data ls_buffer type lcl_buffer=>ty_buffer_master.

    select max( e_number ) as e_number
           from zhc_303_master into @data(lv_e_number).

    get time stamp field data(lv_tsl).

    loop at entities into data(ls_entities).

      lv_e_number += 1.
      ls_buffer-data-e_number = lv_e_number.
      ls_buffer-data-crea_date_time = lv_tsl.
      ls_buffer-data-crea_uname = sy-uname. " cl_abap_context_info=>get_user_technical_name( ).
      ls_buffer-data-e_name         = ls_entities-EmployeeName.
      ls_buffer-data-e_department   = ls_entities-EmployeeDepartment.
      ls_buffer-data-status         = ls_entities-Status.
      ls_buffer-data-job_title      = ls_entities-JobTitle.
      ls_buffer-data-start_date     = ls_entities-StartDate.
      ls_buffer-data-end_date       = ls_entities-EndDate.
      ls_buffer-data-email          = ls_entities-email.
      ls_buffer-data-m_number       = ls_entities-ManagerNumber.
      ls_buffer-data-m_name         = ls_entities-ManagerName.
      ls_buffer-data-m_department   = ls_entities-ManagerDepartment.
      ls_buffer-flag = lcl_buffer=>created.

      insert ls_buffer into table lcl_buffer=>mt_buffer_master.
    endloop.

  endmethod.

  method update.

    get time stamp field data(lv_tsl).

    loop at entities into data(ls_entities).

      select single *
             from zhc_303_master
             where e_number eq @ls_entities-EmployeeNumber
             into @data(ls_ddbb).

      insert value #( flag = lcl_buffer=>updated
                      data = value #(  e_number = ls_entities-EmployeeNumber
                                       e_name = cond #( when ls_entities-%control-EmployeeName = if_abap_behv=>mk-on
                                                       then ls_entities-EmployeeName
                                                       else ls_ddbb-e_name  )
                                      e_department  = cond #( when ls_entities-%control-EmployeeDepartment = if_abap_behv=>mk-on
                                                       then ls_entities-EmployeeDepartment
                                                       else ls_ddbb-e_department  )
                                    status = cond #( when ls_entities-%control-Status = if_abap_behv=>mk-on
                                                       then ls_entities-Status
                                                       else ls_ddbb-status  )
                                    job_title = cond #( when ls_entities-%control-JobTitle = if_abap_behv=>mk-on
                                                       then ls_entities-JobTitle
                                                       else ls_ddbb-job_title  )
                                    start_date = cond #( when ls_entities-%control-StartDate = if_abap_behv=>mk-on
                                                       then ls_entities-StartDate
                                                       else ls_ddbb-start_date  )
                                    end_date  = cond #( when ls_entities-%control-EndDate = if_abap_behv=>mk-on
                                                       then ls_entities-EndDate
                                                       else ls_ddbb-end_date  )
                                    email    = cond #( when ls_entities-%control-Email = if_abap_behv=>mk-on
                                                       then ls_entities-Email
                                                       else ls_ddbb-email  )
                                    m_number   = cond #( when ls_entities-%control-ManagerNumber = if_abap_behv=>mk-on
                                                       then ls_entities-ManagerNumber
                                                       else ls_ddbb-m_number  )
                                    m_name      = cond #( when ls_entities-%control-ManagerName = if_abap_behv=>mk-on
                                                       then ls_entities-ManagerName
                                                       else ls_ddbb-m_name  )
                                    m_department  = cond #( when ls_entities-%control-ManagerDepartment = if_abap_behv=>mk-on
                                                       then ls_entities-ManagerDepartment
                                                       else ls_ddbb-m_department  )
                                    lchg_date_time = lv_tsl
                                    lchg_uname     = sy-uname ) ) into table lcl_buffer=>mt_buffer_master.

      if ls_entities-EmployeeNumber is not initial.
        insert value #( %cid           = ls_entities-EmployeeNumber
                        EmployeeNumber = ls_entities-EmployeeNumber ) into table mapped-hcmmaster.
      endif.

    endloop.

  endmethod.

  method delete.

      loop at keys into data(ls_keys).

        insert value #( flag = lcl_buffer=>deleted
                        data = value #( e_number = ls_keys-EmployeeNumber ) ) into table lcl_buffer=>mt_buffer_master.

        if ls_keys-EmployeeNumber is not initial.
           insert value #( %cid           = ls_keys-EmployeeNumber
                           EmployeeNumber = ls_keys-EmployeeNumber ) into table mapped-hcmmaster.
        endif.
      endloop.

  endmethod.

  method read.
  endmethod.

  method lock.
  endmethod.

endclass.

class lsc_ZI_303_MASTER definition inheriting from cl_abap_behavior_saver.
  protected section.

    methods finalize redefinition.

    methods check_before_save redefinition.

    methods save redefinition.

    methods cleanup redefinition.

    methods cleanup_finalize redefinition.

endclass.

class lsc_ZI_303_MASTER implementation.

  method finalize.
  endmethod.

  method check_before_save.
  endmethod.

  method save.

    data: lt_created_data type standard table of zhc_303_master,
          lt_updated_data type standard table of zhc_303_master,
          lt_deleted_data type standard table of zhc_303_master.

    lt_created_data = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>created )
                                 ( <row>-data ) ).

    if lt_created_data is not initial.
      insert zhc_303_master from table @lt_created_data.
    endif.

    lt_updated_data = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>updated )
                                 ( <row>-data ) ).

    if lt_updated_data is not initial.
      update zhc_303_master from table @lt_updated_data.
    endif.


    lt_deleted_data = value #( for <row> in lcl_buffer=>mt_buffer_master where ( flag = lcl_buffer=>deleted )
                                 ( <row>-data ) ).

    if lt_deleted_data is not initial.
      delete zhc_303_master from table @lt_deleted_data.
    endif.

  endmethod.

  method cleanup.
  endmethod.

  method cleanup_finalize.
  endmethod.

endclass.
