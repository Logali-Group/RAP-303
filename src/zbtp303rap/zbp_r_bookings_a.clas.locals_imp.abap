class lhc_Booking definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculateTotalPrice for determine on modify
      importing keys for Booking~calculateTotalPrice.

    methods setBookingDate for determine on save
      importing keys for Booking~setBookingDate.

    methods setBookingNumber for determine on save
      importing keys for Booking~setBookingNumber.

    methods validateConnection for validate on save
      importing keys for Booking~validateConnection.

    methods validateCurrencyCode for validate on save
      importing keys for Booking~validateCurrencyCode.

    methods validateCustomer for validate on save
      importing keys for Booking~validateCustomer.

endclass.

class lhc_Booking implementation.

  method calculateTotalPrice.

    read entities of zr_travel303_a in local mode
         entity Booking by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(travels).

    modify entities of zr_travel303_a in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( travels ).

  endmethod.

  method setBookingDate.

    read entities of zr_travel303_a in local mode
       entity Booking
         fields ( BookingDate )
         with corresponding #( keys )
       result data(bookings).

    delete bookings where BookingDate is not initial.
    check bookings is not initial.

    loop at bookings assigning field-symbol(<booking>).
      <booking>-BookingDate = cl_abap_context_info=>get_system_date( ).
    endloop.

    modify entities of zr_travel303_a in local mode
      entity Booking
        update  fields ( BookingDate )
        with corresponding #( bookings ).

  endmethod.

  method setBookingNumber.

    data max_bookingid type /dmo/booking_id.
    data bookings_update type table for update zr_travel303_a\\Booking.

    "Read all travels for the requested bookings
    read entities of zr_travel303_a in local mode
      entity Booking by \_Travel
        fields ( TravelUUID )
        with corresponding #( keys )
      result data(travels).

    " Process all affected travels. Read respective bookings for one travel
    loop at travels into data(travel).
      read entities of zr_travel303_a in local mode
        entity Travel by \_Booking
          fields ( BookingID )
          with value #( ( %tky = travel-%tky ) )
        result data(bookings).

      " find max used bookingID in all bookings of this travel
      max_bookingid = '0000'.
      loop at bookings into data(booking).
        if booking-BookingID > max_bookingid.
          max_bookingid = booking-BookingID.
        endif.
      endloop.

      "Provide a booking ID for all bookings of this travel that have none.
      loop at bookings into booking where BookingID is initial.
        max_bookingid += 1.
        append value #( %tky      = booking-%tky
                        BookingID = max_bookingid
                      ) to bookings_update.

      endloop.
    endloop.

    " Provide a booking ID for all bookings that have none.
    modify entities of zr_travel303_a in local mode
      entity booking
        update fields ( BookingID )
        with bookings_update.

  endmethod.

  method validateConnection.

    read entities of zr_travel303_a in local mode
       entity Booking
         fields ( BookingID AirlineID ConnectionID FlightDate )
         with corresponding #( keys )
       result data(bookings).

    read entities of zr_travel303_a in local mode
      entity Booking by \_Travel
        from corresponding #( bookings )
      link data(travel_booking_links).

    loop at bookings assigning field-symbol(<booking>).
      "overwrite state area with empty message to avoid duplicate messages
      append value #(  %tky               = <booking>-%tky
                       %state_area        = 'VALIDATE_CONNECTION' ) to reported-booking.

      " Raise message for non existing airline ID
      if <booking>-AirlineID is initial.
        append value #( %tky = <booking>-%tky ) to failed-booking.

        append value #( %tky                = <booking>-%tky
                        %state_area         = 'VALIDATE_CONNECTION'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_airline_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path              = value #( travel-%tky = travel_booking_links[ key id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-AirlineID = if_abap_behv=>mk-on
                       ) to reported-booking.
      endif.
      " Raise message for non existing connection ID
      if <booking>-ConnectionID is initial.
        append value #( %tky = <booking>-%tky ) to failed-booking.

        append value #( %tky                = <booking>-%tky
                        %state_area         = 'VALIDATE_CONNECTION'
                        %msg                = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_connection_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = value #( travel-%tky = travel_booking_links[ key id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-ConnectionID = if_abap_behv=>mk-on
                       ) to reported-booking.
      endif.
      " Raise message for non existing flight date
      if <booking>-FlightDate is initial.
        append value #( %tky = <booking>-%tky ) to failed-booking.

        append value #( %tky                = <booking>-%tky
                        %state_area         = 'VALIDATE_CONNECTION'
                        %msg                = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_flight_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = value #( travel-%tky = travel_booking_links[ key id  source-%tky = <booking>-%tky ]-target-%tky )
                        %element-FlightDate = if_abap_behv=>mk-on
                       ) to reported-booking.
      endif.
      " check if flight connection exists
      if <booking>-AirlineID is not initial and
         <booking>-ConnectionID is not initial and
         <booking>-FlightDate is not initial.

        select single Carrier_ID, Connection_ID, Flight_Date   from /dmo/flight  where  carrier_id    = @<booking>-AirlineID
                                                               and  connection_id = @<booking>-ConnectionID
                                                               and  flight_date   = @<booking>-FlightDate
                                                               into  @data(flight).

        if sy-subrc <> 0.
          append value #( %tky = <booking>-%tky ) to failed-booking.

          append value #( %tky                 = <booking>-%tky
                          %state_area          = 'VALIDATE_CONNECTION'
                          %msg                 = new /dmo/cm_flight_messages(
                                                                textid      = /dmo/cm_flight_messages=>no_flight_exists
                                                                carrier_id  = <booking>-AirlineID
                                                                flight_date = <booking>-FlightDate
                                                                severity    = if_abap_behv_message=>severity-error )
                          %path                  = value #( travel-%tky = travel_booking_links[ key id  source-%tky = <booking>-%tky ]-target-%tky )
                          %element-FlightDate    = if_abap_behv=>mk-on
                          %element-AirlineID     = if_abap_behv=>mk-on
                          %element-ConnectionID  = if_abap_behv=>mk-on
                        ) to reported-booking.

        endif.

      endif.

    endloop.

  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.


    read entities of zr_travel303_a in local mode
     entity Booking
       fields (  CustomerID )
       with corresponding #( keys )
   result data(bookings).

    read entities of zr_travel303_a in local mode
      entity Booking by \_Travel
        from corresponding #( bookings )
      link data(travel_booking_links).

    data customers type sorted table of /dmo/customer with unique key customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = corresponding #( bookings discarding duplicates mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.

    if  customers is not initial.
      " Check if customer ID exists
      select from /dmo/customer fields customer_id
                                for all entries in @customers
                                where customer_id = @customers-customer_id
      into table @data(valid_customers).
    endif.

    " Raise message for non existing customer id
    loop at bookings into data(booking).
      append value #(  %tky               = booking-%tky
                       %state_area        = 'VALIDATE_CUSTOMER' ) to reported-booking.

      if booking-CustomerID is  initial.
        append value #( %tky = booking-%tky ) to failed-booking.

        append value #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_customer_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = value #( travel-%tky = travel_booking_links[ key id  source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerID = if_abap_behv=>mk-on
                       ) to reported-booking.

      elseif booking-CustomerID is not initial and not line_exists( valid_customers[ customer_id = booking-CustomerID ] ).
        append value #(  %tky = booking-%tky ) to failed-booking.

        append value #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>customer_unkown
                                                                customer_id = booking-customerId
                                                                severity = if_abap_behv_message=>severity-error )
                        %path               = value #( travel-%tky = travel_booking_links[ key id  source-%tky = booking-%tky ]-target-%tky )
                        %element-CustomerID = if_abap_behv=>mk-on
                       ) to reported-booking.
      endif.

    endloop.

  endmethod.

endclass.
