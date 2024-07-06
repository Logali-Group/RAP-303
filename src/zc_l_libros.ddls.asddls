@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Libros'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZC_L_LIBROS

  as select from    ztb_l_libros   as Libros
  
    inner join      ztb_l_categ    as Categ  on Libros.bi_categ = Categ.bi_categ
    
    left outer join zc_l_clnts_lib as Ventas on Libros.id_libro = Ventas.Idlibro
    
    association [0..*] to ZC_L_CLIENTES as _Clientes on $projection.IdLibro = _Clientes.IdLibro
{
  key Libros.id_libro   as IdLibro,
      Libros.titulo     as Titulo,
      Libros.bi_categ   as Categoria,
      Libros.autor      as Autor,
      Libros.editorial  as Editorial,
      Libros.idioma     as Idioma,
      Libros.paginas    as Paginas,
      @Semantics.amount.currencyCode: 'Moneda'
      Libros.precio     as Precio,
      Libros.moneda     as Moneda,
      case
        when Ventas.Ventas <= 1 then 1
        when Ventas.Ventas = 2 then 2
        when Ventas.Ventas > 2 then 3
        else 1
      end               as Ventas,

      case Ventas.Ventas
        when 0 then ''
        else ''
      end               as Text,

      Libros.formato    as Formato,
      Categ.descripcion as Descripcion,
      Libros.url        as Imagen,
      _Clientes
}
