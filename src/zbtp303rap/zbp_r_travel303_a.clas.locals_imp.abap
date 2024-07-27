class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        rejected type c length 1 value 'X', " Rejected
      end of travel_status.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods precheck_create for precheck
      importing entities for create Travel.

    methods precheck_update for precheck
      importing entities for update Travel.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateCurrencyCode for validate on save
      importing keys for Travel~validateCurrencyCode.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.



    types:
      t_entities_create type table for create zr_travel303_a,
      t_entities_update type table for update zr_travel303_a,
      t_failed_travel   type table for failed   early zr_travel303_a,
      t_reported_travel type table for reported early zr_travel303_a.


    methods precheck_auth
      importing
        entities_create type t_entities_create optional
        entities_update type t_entities_update optional
      changing
        failed          type t_failed_travel
        reported        type t_reported_travel.

endclass.

class lhc_Travel implementation.

  method get_instance_features.

    read entities of zr_travel303_a in local mode
     entity Travel
       fields ( OverallStatus )
       with corresponding #( keys )
     result data(travels)
     failed failed.


    result = value #( for ls_travel in travels
                          ( %tky                   = ls_travel-%tky

                            %field-BookingFee      = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                             then if_abap_behv=>fc-f-read_only
                                                             else if_abap_behv=>fc-f-unrestricted )
                            %action-acceptTravel   = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                             then if_abap_behv=>fc-o-disabled
                                                             else if_abap_behv=>fc-o-enabled )
                            %action-rejectTravel   = cond #( when ls_travel-OverallStatus = travel_status-rejected
                                                             then if_abap_behv=>fc-o-disabled
                                                             else if_abap_behv=>fc-o-enabled )
                            %action-deductDiscount = cond #( when ls_travel-OverallStatus = travel_status-accepted
                                                             then if_abap_behv=>fc-o-disabled
                                                             else if_abap_behv=>fc-o-enabled )
                            %assoc-_Booking        = cond #( when ls_travel-OverallStatus = travel_status-rejected
                                                            then if_abap_behv=>fc-o-disabled
                                                            else if_abap_behv=>fc-o-enabled )
                          ) ).


  endmethod.

  method get_instance_authorizations.

    data: update_requested type abap_bool,
          delete_requested type abap_bool,
          update_granted   type abap_bool,
          delete_granted   type abap_bool.

    read entities of zr_travel303_a in local mode
      entity Travel
        fields ( AgencyID )
        with corresponding #( keys )
        result data(travels)
      failed failed.

    check travels is not initial.

    "Select Country Code and agency of corresponding persistent travel instance
    select from /dmo/a_travel_d as travel
      inner join /dmo/agency    as agency on travel~agency_id = agency~agency_id
      fields travel~travel_uuid , travel~agency_id, agency~country_code
      for all entries in @travels
      where travel_uuid eq @travels-TravelUUID
      into  table @data(travel_agency_country).


    "edit is treated like update
    update_requested = cond #( when requested_authorizations-%update      = if_abap_behv=>mk-on
                                 or requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                               then abap_true else abap_false ).

    delete_requested = cond #( when requested_authorizations-%delete      = if_abap_behv=>mk-on
                               then abap_true else abap_false ).


    loop at travels into data(travel).
      "get country_code of agency in corresponding instance on persistent table
      read table travel_agency_country with key travel_uuid = travel-TravelUUID
        assigning field-symbol(<travel_agency_country_code>).

      "Auth check for active instances that have before image on persistent table
      if sy-subrc = 0.

        "check auth for update
        if update_requested = abap_true.

          if travel-AgencyID = '70004'."REPLACE WITH BUSINESS LOGIC
            update_granted = abap_false.
          else.
            update_granted = abap_true.
          endif.

          if update_granted = abap_false.
            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages(
                                                     textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                     agency_id = travel-AgencyID
                                                     severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on
                           ) to reported-travel.
          endif.
        endif.

        "check auth for delete
        if delete_requested = abap_true.

           if travel-AgencyID = '70004'."REPLACE WITH BUSINESS LOGIC
            delete_granted = abap_false.
          else.
            delete_granted = abap_true.
          endif.

          if delete_granted = abap_false.
            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages(
                                     textid   = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                     agency_id = travel-AgencyID
                                     severity = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on
                           ) to reported-travel.
          endif.
        endif.

        " operations on draft instances and on active instances
      else.
         if travel-AgencyID = '70004'."REPLACE WITH BUSINESS LOGIC
            update_granted = abap_false.
          else.
            update_granted = abap_true.
          endif.
        if update_granted = abap_false.
          append value #( %tky = travel-%tky
                          %msg = new /dmo/cm_flight_messages(
                                   textid   = /dmo/cm_flight_messages=>not_authorized
                                   severity = if_abap_behv_message=>severity-error )
                          %element-AgencyID = if_abap_behv=>mk-on
                        ) to reported-travel.
        endif.
      endif.

      append value #( let upd_auth = cond #( when update_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                          del_auth = cond #( when delete_granted = abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                       %tky = travel-%tky
                       %update                = upd_auth
                       %action-Edit           = upd_auth

                       %delete                = del_auth
                    ) to result.
    endloop.

  endmethod.

  method get_global_authorizations.


    data lv_import_country_check_value type land1.

    authority-check object '/DMO/TRVL'
       id '/DMO/CNTRY' field lv_import_country_check_value
       id 'ACTVT'      field '01'.

    data(lv_dummy_auth_for_creation) = cond #( when sy-subrc = 0 then abap_true else abap_false ).


    if requested_authorizations-%create eq if_abap_behv=>mk-on.
      if lv_dummy_auth_for_creation = abap_true.
        result-%create = if_abap_behv=>auth-allowed.
      else.
        result-%create = if_abap_behv=>auth-unauthorized.
        append value #( %msg    = new /dmo/cm_flight_messages(
                                       textid   = /dmo/cm_flight_messages=>not_authorized
                                       severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.
    endif.

    data lv_dummy_auth type abap_boolean value abap_true.

    "Edit/Update
    if requested_authorizations-%update                =  if_abap_behv=>mk-on or
       requested_authorizations-%action-Edit           =  if_abap_behv=>mk-on.

      if  lv_dummy_auth = abap_true.
        result-%update                =  if_abap_behv=>auth-allowed.
        result-%action-Edit           =  if_abap_behv=>auth-allowed.

      else.
        result-%update                =  if_abap_behv=>auth-unauthorized.
        result-%action-Edit           =  if_abap_behv=>auth-unauthorized.

        append value #( %msg    = new /dmo/cm_flight_messages(
                                       textid   = /dmo/cm_flight_messages=>not_authorized
                                       severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on )
          to reported-travel.

      endif.
    endif.

    if requested_authorizations-%delete =  if_abap_behv=>mk-on.
      if lv_dummy_auth = abap_true.
        result-%delete = if_abap_behv=>auth-allowed.
      else.
        result-%delete = if_abap_behv=>auth-unauthorized.
        append value #( %msg    = new /dmo/cm_flight_messages(
                                       textid   = /dmo/cm_flight_messages=>not_authorized
                                       severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.
      endif.
    endif.

  endmethod.

  method precheck_create.

    me->precheck_auth(
       exporting
         entities_create = entities
       changing
         failed          = failed-travel
         reported        = reported-travel ).

  endmethod.

  method precheck_update.

    me->precheck_auth(
       exporting
         entities_update = entities
       changing
         failed          = failed-travel
         reported        = reported-travel ).

  endmethod.

  method acceptTravel.

    modify entities of zr_travel303_a in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #(  for key in keys ( %tky          = key-%tky
                                            OverallStatus = travel_status-accepted ) ).

    read entities of zr_travel303_a in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

  method deductDiscount.

    data travels_for_update type table for update zr_travel303_a.
    data(keys_with_valid_discount) = keys.

    loop at keys_with_valid_discount assigning field-symbol(<key_with_valid_discount>) where %param-discount_percent is initial
                                                        or %param-discount_percent > 100
                                                        or %param-discount_percent <= 0.

      append value #( %tky                       = <key_with_valid_discount>-%tky ) to failed-travel.

      append value #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = new /dmo/cm_flight_messages(
                                                       textid = /dmo/cm_flight_messages=>discount_invalid
                                                       severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on
                    ) to reported-travel.

      delete keys_with_valid_discount.
    endloop.

    check keys_with_valid_discount is not initial.

    "get total price
    read entities of zr_travel303_a in local mode
      entity Travel
        fields ( BookingFee )
        with corresponding #( keys_with_valid_discount )
      result data(travels).

    loop at travels assigning field-symbol(<travel>).
      data percentage type decfloat16.
      data(discount_percent) = keys_with_valid_discount[ key id  %tky = <travel>-%tky ]-%param-discount_percent.
      percentage =  discount_percent / 100 .
      data(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ) .

      append value #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee
                    ) to travels_for_update.
    endloop.

    "update total price with reduced price
    modify entities of zr_travel303_a in local mode
      entity Travel
       update fields ( BookingFee )
       with travels_for_update.

    "Read changed data for action result
    read entities of zr_travel303_a in local mode
      entity Travel
        all fields with
        corresponding #( travels )
      result data(travels_with_discount).

    result = value #( for travel in travels_with_discount ( %tky   = travel-%tky
                                                            %param = travel ) ).
  endmethod.

  method reCalcTotalPrice.

    types: begin of ty_amount_curr,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_curr.

    data amount_per_currencycode type standard table of ty_amount_curr.

    read entities of zr_travel303_a in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(travels).

    delete travels where CurrencyCode is initial.

    loop at travels assigning field-symbol(<travel>).

      amount_per_currencycode = value #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      read entities of zr_travel303_a in local mode
           entity Travel by \_Booking
           fields ( FlightPrice CurrencyCode )
           with value #( ( %tky = <travel>-%tky ) )
           result data(bookings).

      loop at bookings into data(booking) where CurrencyCode is not initial.
        collect value ty_amount_curr( amount        =  booking-FlightPrice
                                      currency_code = booking-CurrencyCode ) into amount_per_currencycode.
      endloop.

      read entities of zr_travel303_a in local mode
           entity Booking by \_BookingSupplement
           fields ( BookSupplPrice CurrencyCode )
           with value #( for ref_booking in bookings ( %tky = ref_booking-%tky ) )
           result data(bookingssupplements).

      loop at bookingssupplements into data(bookingssupplement) where CurrencyCode is not initial.
        collect value ty_amount_curr( amount        = bookingssupplement-BookSupplPrice
                                      currency_code = bookingssupplement-CurrencyCode ) into amount_per_currencycode.
      endloop.


      clear <travel>-TotalPrice.

      loop at amount_per_currencycode into data(single_amount).

        if single_amount-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount-amount.
        else.

          /dmo/cl_flight_amdp=>convert_currency(
            exporting
              iv_amount               = single_amount-amount
              iv_currency_code_source = single_amount-currency_code
              iv_currency_code_target = <travel>-CurrencyCode
              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
            importing
              ev_amount               = data(total_booking_price_curr)
          ).

          <travel>-TotalPrice += total_booking_price_curr.

        endif.

      endloop.

    endloop.

    modify entities of zr_travel303_a in local mode
           entity Travel
           update fields ( TotalPrice )
           with corresponding #( travels ).

  endmethod.

  method rejectTravel.

    modify entities of zr_travel303_a in local mode
          entity Travel
          update fields ( OverallStatus )
          with value #(  for key in keys ( %tky          = key-%tky
                                           OverallStatus = travel_status-rejected ) ).

    read entities of zr_travel303_a in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).
  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.

    modify entities of zr_travel303_a in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( keys ).

  endmethod.

  method setStatusToOpen.

    read entities of zr_travel303_a in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels).

    delete travels where OverallStatus is not initial.
    check travels is not initial.

    modify entities of  zr_travel303_a in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #(  for travel in travels (
                              %tky = travel-%tky
                              OverallStatus = travel_status-open ) ).

  endmethod.

  method setTravelNumber.

    read entities of zr_travel303_a in local mode
       entity Travel
       fields ( TravelID )
       with corresponding #( keys )
       result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from ztravel303_a
           fields max( travel_id )
           into @data(lv_max_travel_id).


    modify entities of  zr_travel303_a in local mode
           entity Travel
           update fields ( TravelID )
           with value #(  for travel in travels index into i (
                              %tky = travel-%tky
                              TravelID = lv_max_travel_id + i ) ).

  endmethod.

  method validateAgency.

    data: modification_granted type abap_boolean,
          agency_country_code  type land1.

    read entities of zr_travel303_a in local mode
      entity Travel
        fields ( AgencyID TravelID )
        with corresponding #( keys )
      result data(travels).

    data agencies type sorted table of /dmo/agency with unique key agency_id.

    " Optimization of DB select: extract distinct non-initial agency IDs
    agencies = corresponding #( travels discarding duplicates mapping agency_id = AgencyID except * ).
    delete agencies where agency_id is initial.

    if  agencies is not initial.
      " Check if Agency ID exists
      select from /dmo/agency fields agency_id, country_code
                              for all entries in @agencies
                              where agency_id = @agencies-agency_id
        into table @data(valid_agencies).
    endif.

    " Raise message for non existing Agency id
    loop at travels into data(travel).
      append value #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_AGENCY'
                    ) to reported-travel.

      if travel-AgencyID is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                          textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                          severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID   = if_abap_behv=>mk-on
                       ) to reported-travel.

      elseif travel-AgencyID is not initial and not line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).
        append value #(  %tky = travel-%tky ) to failed-travel.

        append value #(  %tky               = travel-%tky
                         %state_area        = 'VALIDATE_AGENCY'
                         %msg               = new /dmo/cm_flight_messages(
                                                                agency_id = travel-agencyid
                                                                textid    = /dmo/cm_flight_messages=>agency_unkown
                                                                severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID  = if_abap_behv=>mk-on
                      ) to reported-travel.
      endif.

    endloop.

  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.

    read entities of zr_travel303_a in local mode
       entity Travel
       fields ( CustomerID )
       with corresponding #( keys )
       result data(travels).

    data customers type sorted table of /dmo/customer with unique key customer_id.

    customers = corresponding #( travels discarding duplicates mapping customer_id = CustomerID except * ).
*    delete customers where customer_id is initial.

    if customers is not initial.
      select from /dmo/customer
             fields customer_id
             for all entries in @customers
             where customer_id eq @customers-customer_id
             into table @data(valid_customers).
    endif.

    loop at travels into data(travel).

      append value #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) to reported-travel.

      if travel-CustomerID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                   severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on  ) to reported-travel.

      elseif travel-CustomerID is not initial and not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg        = new /dmo/cm_flight_messages( customer_id = travel-CustomerID
                                                                   textid   = /dmo/cm_flight_messages=>customer_unkown
                                                                   severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on  ) to reported-travel.

      endif.
    endloop.


  endmethod.

  method validateDates.

    read entities of zr_travel303_a in local mode
       entity Travel
         fields (  BeginDate EndDate TravelID )
         with corresponding #( keys )
       result data(travels).

    loop at travels into data(travel).

      append value #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_DATES' ) to reported-travel.

      if travel-BeginDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-EndDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-EndDate < travel-BeginDate and travel-BeginDate is not initial
                                           and travel-EndDate is not initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = travel-BeginDate
                                                                end_date   = travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.
      if travel-BeginDate < cl_abap_context_info=>get_system_date( ) and travel-BeginDate is not initial.
        append value #( %tky               = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                begin_date = travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.

    endloop.

  endmethod.

  method precheck_auth.

    data:
      entities          type t_entities_update,
      operation         type if_abap_behv=>t_char01,
      agencies          type sorted table of /dmo/agency with unique key agency_id,
      is_modify_granted type abap_bool.

    " Either entities_create or entities_update is provided.  NOT both and at least one.
    assert not ( entities_create is initial equiv entities_update is initial ).

    if entities_create is not initial.
      entities = corresponding #( entities_create mapping %cid_ref = %cid ).
      operation = if_abap_behv=>op-m-create.
    else.
      entities = entities_update.
      operation = if_abap_behv=>op-m-update.
    endif.

    delete entities where %control-AgencyID = if_abap_behv=>mk-off.

    agencies = corresponding #( entities discarding duplicates mapping agency_id = AgencyID except * ).

    check agencies is not initial.

    select from /dmo/agency fields agency_id, country_code
                            for all entries in @agencies
                            where agency_id = @agencies-agency_id
      into table @data(agency_country_codes).

    loop at entities into data(entity).
      is_modify_granted = abap_false.

      read table agency_country_codes with key agency_id = entity-AgencyID
                   assigning field-symbol(<agency_country_code>).

      "If invalid or initial AgencyID -> validateAgency
      check sy-subrc = 0.
      case operation.
        when if_abap_behv=>op-m-create.

          is_modify_granted = abap_true. "REPLACE WITH BUSINESS LOGIC

        when if_abap_behv=>op-m-update.
          is_modify_granted = abap_true. "REPLACE WITH BUSINESS LOGIC

      endcase.

      if is_modify_granted = abap_false.
        append value #(
                         %cid      = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                         %tky      = entity-%tky
                       ) to failed.

        append value #(
                         %cid      = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                         %tky      = entity-%tky
                         %msg      = new /dmo/cm_flight_messages(
                                                 textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                 agency_id = entity-AgencyID
                                                 severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID   = if_abap_behv=>mk-on
                      ) to reported.
      endif.
    endloop.

  endmethod.

endclass.
