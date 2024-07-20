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


endclass.

class lhc_Travel implementation.

  method get_instance_features.
  endmethod.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method precheck_create.
  endmethod.

  method precheck_update.
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
  endmethod.

endclass.
