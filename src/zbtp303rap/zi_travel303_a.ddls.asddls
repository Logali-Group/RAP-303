@EndUserText.label: 'Travel - Interface'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_TRAVEL303_A
  provider contract transactional_interface
  as projection on ZR_TRAVEL303_A
{
  key TravelUUID,
      TravelID,
      AgencyID,
      CustomerID,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      LocalLastChangedAt,

      /* Associations */
      _Agency,
      _Booking : redirected to composition child zi_bookings303_a,
      _Currency,
      _Customer,
      _OverallStatus
}
