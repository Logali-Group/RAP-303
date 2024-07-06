@EndUserText.label: 'Booking Supplements - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZC_BOOKSUPPL303_A as projection on ZR_BOOKSUPPL303_A
{
    key BookSupplUUID,
    
    TravelUUID,
    
    BookingUUID,
    
    @Search.defaultSearchElement: true
    BookingSupplementID,
    
    @ObjectModel.text.element: [ 'SupplementDescription' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Supplement_StdVH',
                                                     element: 'SupplementID'},
                                           additionalBinding: [ { localElement: 'BookSupplPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }],
                                           useForValidation: true }]
    SupplementID,
    _SupplementText.Description as SupplementDescription: localized,
    BookSupplPrice,
    
    @Consumption.valueHelpDefinition: [{entity.name: 'I_CurrencyStdVH',
                                          entity.element: 'Currency',
                                          useForValidation: true }]
    CurrencyCode,
    
    LocalLastChangedAt,
    /* Associations */
    _Booking : redirected to parent ZC_BOOKINGS303_A,
    _Product,
    _SupplementText,
    _Travel : redirected to ZC_TRAVEL303_A
}
