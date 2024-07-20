class zcl_virtual_elem303 definition
  public
  final
  create public .

  public section.
    interfaces if_sadl_exit_calc_element_read.

  protected section.
  private section.
endclass.



class zcl_virtual_elem303 implementation.


  method if_sadl_exit_calc_element_read~get_calculation_info.

    case iv_entity.

      when 'ZC_TRAVEL303_A'.

        loop at it_requested_calc_elements assigning field-symbol(<fs_calc_elements>).
          if <fs_calc_elements> = 'DISCOUNT'.
            append 'TOTALPRICE' to et_requested_orig_elements.
          endif.
        endloop.


    endcase.


  endmethod.

  method if_sadl_exit_calc_element_read~calculate.

    data lt_original_data type standard table of zc_travel303_a with default key.

    lt_original_data = corresponding #( it_original_data ).

    loop at lt_original_data assigning field-symbol(<fs_original_data>).
        <fs_original_data>-Discount = <fs_original_data>-TotalPrice - ( <fs_original_data>-TotalPrice * ( 1 / 10 ) ).
    endloop.

    ct_calculated_data = corresponding #( lt_original_data ).

  endmethod.



endclass.
