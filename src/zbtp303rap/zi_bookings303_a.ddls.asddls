@EndUserText.label: 'Booking - Interface'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity zi_bookings303_a 
as projection on ZR_BOOKINGS303_A
{
    key BookingUUID,
    TravelUUID,
    BookingID,
    BookingDate,
    CustomerID,
    AirlineID,
    ConnectionID,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    BookingStatus,
    LocalLastChangeAt,
    /* Associations */
    _BookingStatus,
    _BookingSupplement: redirected to composition child zi_booksuppl303_a,
    _Carrier,
    _Connection,
    _Customer,
    _Travel : redirected to parent ZI_TRAVEL303_A
}
