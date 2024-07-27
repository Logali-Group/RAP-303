@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HCM - Root Entity'
define root view entity ZI_303_MASTER
  as select from zhc_303_master
{
  key e_number       as EmployeeNumber,
      e_name         as EmployeeName,
      e_department   as EmployeeDepartment,
      status         as Status,
      job_title      as JobTitle,
      start_date     as StartDate,
      end_date       as EndDate,
      email          as Email,
      m_number       as ManagerNumber,
      m_name         as ManagerName,
      m_department   as ManagerDepartment,
      crea_date_time as CreatedAt,
      crea_uname     as CreatedBy,
      lchg_date_time as ChangedAt,
      lchg_uname     as ChangedBy
}
