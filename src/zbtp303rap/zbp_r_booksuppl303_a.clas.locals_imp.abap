class lhc_BookingSupplement definition inheriting from cl_abap_behavior_handler.
  private section.

    methods calculateTotalPrice for determine on modify
      importing keys for BookingSupplement~calculateTotalPrice.

    methods setBookSupplNumber for determine on save
      importing keys for BookingSupplement~setBookSupplNumber.

    methods validateCurrencyCode for validate on save
      importing keys for BookingSupplement~validateCurrencyCode.

    methods validateSupplement for validate on save
      importing keys for BookingSupplement~validateSupplement.

endclass.

class lhc_BookingSupplement implementation.

  method calculateTotalPrice.

    read entities of zr_travel303_a in local mode
         entity BookingSupplement by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(travels).

    modify entities of zr_travel303_a in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( travels ).

  endmethod.

  method setBookSupplNumber.

    data max_bookingsupplementid type /dmo/booking_supplement_id.
    data bookingsupplements_update type table for update zr_travel303_a\\BookingSupplement.

    "Read all bookings for the requested booking supplements
    read entities of zr_travel303_a in local mode
      entity BookingSupplement by \_Booking
        fields (  BookingUUID  )
        with corresponding #( keys )
      result data(bookings).

    " Process all affected bookings. Read respective booking supplements for one booking
    loop at bookings into data(ls_booking).
      read entities of zr_travel303_a in local mode
        entity Booking by \_BookingSupplement
          fields ( BookingSupplementID )
          with value #( ( %tky = ls_booking-%tky ) )
        result data(bookingsupplements).

      " find max used bookingID in all bookings of this travel
      max_bookingsupplementid = '00'.
      loop at bookingsupplements into data(bookingsupplement).
        if bookingsupplement-BookingSupplementID > max_bookingsupplementid.
          max_bookingsupplementid = bookingsupplement-BookingSupplementID.
        endif.
      endloop.

      "Provide a booking supplement ID for all booking supplement of this booking that have none.
      loop at bookingsupplements into bookingsupplement where BookingSupplementID is initial.
        max_bookingsupplementid += 1.
        append value #( %tky                = bookingsupplement-%tky
                        bookingsupplementid = max_bookingsupplementid
                      ) to bookingsupplements_update.

      endloop.
    endloop.

    modify entities of zr_travel303_a in local mode
      entity BookingSupplement
        update fields ( BookingSupplementID ) with bookingsupplements_update.

  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateSupplement.

    read entities of zr_travel303_a in local mode
     entity BookingSupplement
       fields ( SupplementID )
       with corresponding #(  keys )
     result data(bookingsupplements)
     failed data(read_failed).

    failed = corresponding #( deep read_failed ).

    read entities of zr_travel303_a in local mode
      entity BookingSupplement by \_Booking
        from corresponding #( bookingsupplements )
      link data(booksuppl_booking_links).

    read entities of zr_travel303_a in local mode
      entity BookingSupplement by \_Travel
        from corresponding #( bookingsupplements )
      link data(booksuppl_travel_links).


    data supplements type sorted table of /dmo/supplement with unique key supplement_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    supplements = corresponding #( bookingsupplements discarding duplicates mapping supplement_id = SupplementID except * ).
    delete supplements where supplement_id is initial.

    if  supplements is not initial.
      " Check if customer ID exists
      select from /dmo/supplement fields supplement_id
                                  for all entries in @supplements
                                  where supplement_id = @supplements-supplement_id
      into table @data(valid_supplements).
    endif.

    loop at bookingsupplements assigning field-symbol(<bookingsupplement>).

      append value #(  %tky        = <bookingsupplement>-%tky
                       %state_area = 'VALIDATE_SUPPLEMENT'
                    ) to reported-bookingsupplement.

      if <bookingsupplement>-SupplementID is  initial.
        append value #( %tky = <bookingsupplement>-%tky ) to failed-bookingsupplement.

        append value #( %tky                  = <bookingsupplement>-%tky
                        %state_area           = 'VALIDATE_SUPPLEMENT'
                        %msg                  = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_supplement_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                 = value #( booking-%tky = booksuppl_booking_links[ key id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                         travel-%tky  = booksuppl_travel_links[  key id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-SupplementID = if_abap_behv=>mk-on
                       ) to reported-bookingsupplement.


      elseif <bookingsupplement>-SupplementID is not initial and not line_exists( valid_supplements[ supplement_id = <bookingsupplement>-SupplementID ] ).
        append value #(  %tky = <bookingsupplement>-%tky ) to failed-bookingsupplement.

        append value #( %tky                  = <bookingsupplement>-%tky
                        %state_area           = 'VALIDATE_SUPPLEMENT'
                        %msg                  = new /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>supplement_unknown
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                 = value #( booking-%tky = booksuppl_booking_links[ key id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                          travel-%tky = booksuppl_travel_links[  key id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-SupplementID = if_abap_behv=>mk-on
                       ) to reported-bookingsupplement.
      endif.

    endloop.

  endmethod.

endclass.
