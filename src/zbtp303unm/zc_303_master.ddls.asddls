@EndUserText.label: 'HCM - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_303_MASTER
  provider contract transactional_query
  as projection on ZI_303_MASTER
{
      @ObjectModel.text.element: [ 'EmployeeName' ]
  key EmployeeNumber,
      EmployeeName,
      EmployeeDepartment,
      Status,
      JobTitle,
      StartDate,
      EndDate,
      Email,
      @ObjectModel.text.element: [ 'ManagerName' ]
      ManagerNumber,
      ManagerName,
      ManagerDepartment,
      @Semantics.user.createdBy: true
      CreatedAt,
      CreatedBy,
      ChangedAt,
      @Semantics.user.lastChangedBy: true
      ChangedBy
}
