@EndUserText.label: 'Booking - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BookingID']

define view entity ZC_BOOKINGS303_A
  as projection on zr_bookings303_a
{
  key BookingUUID,

      TravelUUID,
            
      @Search.defaultSearchElement: true
      BookingID,

      BookingDate,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH',
                                                     element: 'CustomerID'},
                                           useForValidation: true }]
      CustomerID,
      _Customer.LastName as CustomerName,
      
      @ObjectModel.text.element: [ 'CarrierName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'AirlineID'},
                                           additionalBinding: [{ localElement: 'FlightDate',
                                                                 element: 'FlightDate',
                                                                 usage: #RESULT },
                                                               { localElement: 'ConnectionID',
                                                                 element: 'ConnectionID',
                                                                 usage: #RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }],
                                           useForValidation: true }]
      AirlineID,
      _Carrier.Name as CarrierName,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'ConnectionID'},
                                           additionalBinding: [{ localElement: 'FlightDate',
                                                                 element: 'FlightDate',
                                                                 usage: #RESULT },
                                                               { localElement: 'AirlineID',
                                                                 element: 'AirlineID',
                                                                 usage: #FILTER_AND_RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }],
                                           useForValidation: true }]
      ConnectionID,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'FlightDate'},
                                           additionalBinding: [{ localElement: 'AirlineID',
                                                                 element: 'AirlineID',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'ConnectionID',
                                                                 element: 'ConnectionID',
                                                                 usage: #FILTER_AND_RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }],
                                           useForValidation: true }]
      FlightDate,
      
      @Consumption.valueHelpDefinition: [ 
          { entity: {name: '/DMO/I_Flight_StdVH', element: 'Price'},
            additionalBinding: [ { localElement: 'FlightDate',   
                                   element: 'FlightDate',   
                                   usage: #FILTER_AND_RESULT},
                                 { localElement: 'AirlineID',    
                                   element: 'AirlineID',    
                                   usage: #FILTER_AND_RESULT},
                                 { localElement: 'ConnectionID', 
                                   element: 'ConnectionID', 
                                   usage: #FILTER_AND_RESULT},
                                 { localElement: 'CurrencyCode', 
                                   element: 'CurrencyCode', 
                                   usage: #RESULT } ], 
            useForValidation: true }
        ]                                           
      FlightPrice,
      
      @Consumption.valueHelpDefinition: [{entity.name: 'I_CurrencyStdVH',
                                          entity.element: 'Currency',
                                          useForValidation: true }]
      CurrencyCode,
      
      @ObjectModel.text.element: [ 'BookingStatusText' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Booking_Status_VH',
                                                     element: 'BookingStatus'}}]
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      
      LocalLastChangeAt,
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child ZC_BOOKSUPPL303_A,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent ZC_TRAVEL303_A
}
