@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Clientes Libros - Ventas'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zc_l_clnts_lib
  as select from ztb_l_clnts_lib
{
  key id_libro                      as Idlibro,
      count ( distinct id_cliente ) as Ventas
}
group by
  id_libro;
