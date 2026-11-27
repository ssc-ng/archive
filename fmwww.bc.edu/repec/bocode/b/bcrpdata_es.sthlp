{smcl}
{* *! version 0.2.1  27nov2026}{...}
{vieweralsosee "bcrpdata (English)" "help bcrpdata"}{...}
{viewerjumpto "Sintaxis" "bcrpdata_es##syntax"}{...}
{viewerjumpto "Descripcion" "bcrpdata_es##description"}{...}
{viewerjumpto "Opciones" "bcrpdata_es##options"}{...}
{viewerjumpto "Comentarios" "bcrpdata_es##remarks"}{...}
{viewerjumpto "Ejemplos" "bcrpdata_es##examples"}{...}
{viewerjumpto "Autor" "bcrpdata_es##author"}{...}
{hline}
{title:Titulo}

{phang}
{bf:bcrpdata} {hline 2} Descarga series estadisticas del Banco Central de
Reserva del Peru (BCRPData) a Stata

{phang}
{it:Version {bf:0.2.1} (27nov2026)}{p_end}


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:bcrpdata} {it:codigo} [{it:codigo} ...]
[{cmd:,} {opt from(periodo)} {opt to(periodo)} {opt clear}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt from(periodo)}}periodo inicial (ver formatos abajo){p_end}
{synopt:{opt to(periodo)}}periodo final; requiere {opt from()}{p_end}
{synopt:{opt clear}}reemplaza los datos en memoria aunque tengan cambios sin guardar{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:bcrpdata} consulta la API de BCRPData
({browse "https://estadisticas.bcrp.gob.pe/estadisticas/series/"}) y deja
en memoria una base con una variable {cmd:fecha} y una variable por
serie, con el codigo como nombre y la descripcion de la serie como
etiqueta. La base queda declarada con {helpb tsset}.

{pstd}
{bf:Como encontrar el codigo:} en BCRPData, busque la serie por
categoria o por nombre. El codigo aparece en la columna {it:Codigo} y en
la direccion de la pagina de la serie, por ejemplo {cmd:PN02508AQ}.


{marker options}{...}
{title:Opciones}

{phang}
{opt from(periodo)} y {opt to(periodo)} limitan el rango, con el formato
de la API segun la frecuencia de la serie:

{p2colset 9 24 26 2}{...}
{p2col:{it:Frecuencia}}{it:Formato} (ejemplo){p_end}
{p2col:mensual}{cmd:2021-1} (enero de 2021){p_end}
{p2col:trimestral}{cmd:2022-1} (primer trimestre de 2022){p_end}
{p2col:anual}{cmd:2015}{p_end}
{p2col:diaria}{cmd:2024-11-01}{p_end}
{p2colreset}{...}

{pmore}
Sin estas opciones, la API devuelve solo los datos mas recientes.

{phang}
{opt clear} permite reemplazar datos en memoria con cambios sin guardar.


{marker remarks}{...}
{title:Comentarios}

{pstd}
{bf:Fechas.} La variable {cmd:fecha} queda en el formato de Stata que
corresponde a la frecuencia: {cmd:%tm} (mensual), {cmd:%tq} (trimestral),
{cmd:%ty} (anual) o {cmd:%td} (diaria).

{pstd}
{bf:Series diarias.} La API devuelve solo dias habiles, y los feriados
sin dato quedan como missing. Con {cmd:tsset} diario, los fines de
semana cuentan como huecos; para rezagos o diferencias entre dias
habiles consecutivos, use un indice: {cmd:gen t = _n} y {cmd:tsset t}.

{pstd}
{bf:Varias series.} Todas las series de una llamada deben tener la misma
frecuencia; si se mezclan, la API usa la de la primera serie y omite las
demas. La API acepta hasta 10 series por consulta; con mas,
{cmd:bcrpdata} hace varias consultas y las une por periodo.

{pstd}
{bf:Etiquetas.} Stata limita las etiquetas de variable a 80 caracteres.
Si el nombre de la serie es mas largo, la etiqueta muestra la parte
final del nombre y su unidad, por ejemplo "Agropecuario (millones S/ de
2007)". El nombre completo queda en la caracteristica {cmd:nombre} de la
variable: {cmd:char list PM04986AA[nombre]}.

{pstd}
{bf:Datos faltantes y series descontinuadas.} Los valores no disponibles
quedan como missing ({cmd:.}). Si la serie no tiene datos en el periodo
pedido (por ejemplo, una serie descontinuada sin {opt from()}), el
comando lo indica y no modifica los datos en memoria.


{marker examples}{...}
{title:Ejemplos}

{pstd}Mensual{p_end}
{phang2}{cmd:. bcrpdata PN38071GM, from(2021-1) to(2022-6) clear}{p_end}

{pstd}Trimestral{p_end}
{phang2}{cmd:. bcrpdata PN02508AQ, from(2022-1) to(2024-4) clear}{p_end}

{pstd}Anual{p_end}
{phang2}{cmd:. bcrpdata PM04986AA, from(2015) to(2024) clear}{p_end}

{pstd}Diaria (tipo de cambio interbancario, compra){p_end}
{phang2}{cmd:. bcrpdata PD04637PD, from(2024-11-01) to(2024-11-30) clear}{p_end}

{pstd}Dos series de la misma frecuencia y un grafico{p_end}
{phang2}{cmd:. bcrpdata PN01288PM PN01289PM, from(2010-1) to(2012-12) clear}{p_end}
{phang2}{cmd:. tsline PN01288PM PN01289PM}{p_end}


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. Este comando no es un producto oficial del BCRP ni
del INEI. Los datos son del Banco Central de Reserva del Peru; revise sus
{browse "https://estadisticas.bcrp.gob.pe/estadisticas/series/ayuda/condiciones-de-uso":condiciones de uso}.
Distribuido bajo la Licencia Publica General GNU v3
(https://www.gnu.org/licenses/gpl-3.0.txt).

{psee}
In English: {helpb bcrpdata}
{p_end}
