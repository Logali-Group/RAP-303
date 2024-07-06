@EndUserText.label: 'Booking - Interface'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity zi_booksuppl303_a
  as projection on zr_booksuppl303_a
{
  key BookSupplUUID,
      TravelUUID,
      BookingUUID,
      BookingSupplementID,
      SupplementID,
      BookSupplPrice,
      CurrencyCode,
      LocalLastChangedAt,
      /* Associations */
      _Booking : redirected to parent zi_bookings303_a,
      _Product,
      _SupplementText,
      _Travel  : redirected to ZI_TRAVEL303_A
}
