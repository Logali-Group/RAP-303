@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_HC_303_GEN
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_HC_303_GEN
{
  key ENumber,
  EName,
  EDepartment,
  Status,
  JobTitle,
  StartDate,
  EndDate,
  Email,
  MNumber,
  MName,
  MDepartment,
  CreaDateTime,
  CreaUname,
  LchgDateTime,
  LchgUname,
  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangeBy,
  LocalLastChangedAt,
  LastChangedAt
  
}
