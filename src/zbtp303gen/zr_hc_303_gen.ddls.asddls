@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_HC_303_GEN
  as select from zhc_303_gen as HCMMaster
{
  key e_number              as ENumber,
      e_name                as EName,
      e_department          as EDepartment,
      status                as Status,
      job_title             as JobTitle,
      start_date            as StartDate,
      end_date              as EndDate,
      email                 as Email,
      m_number              as MNumber,
      m_name                as MName,
      m_department          as MDepartment,
      crea_date_time        as CreaDateTime,
      crea_uname            as CreaUname,
      lchg_date_time        as LchgDateTime,
      lchg_uname            as LchgUname,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_change_by  as LocalLastChangeBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt

}
