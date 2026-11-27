{smcl}
{* *! version 1.0.1  27nov2026}{...}
{vieweralsosee "sriinei (English)" "help sriinei"}{...}
{viewerjumpto "Sintaxis" "sriinei_es##syntax"}{...}
{viewerjumpto "Descripcion" "sriinei_es##description"}{...}
{viewerjumpto "Opciones" "sriinei_es##options"}{...}
{viewerjumpto "Comentarios" "sriinei_es##remarks"}{...}
{viewerjumpto "Ejemplos" "sriinei_es##examples"}{...}
{viewerjumpto "Autor" "sriinei_es##author"}{...}
{hline}
{title:Titulo}

{phang}
{bf:sriinei} {hline 2} Descarga un modulo de microdatos del portal
SRIENAHO del INEI (Peru)

{phang}
{it:Version {bf:1.0.1} (27nov2026)}{p_end}


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:sriinei}{cmd:,}
{opt cod:igo(#)}
{opt mod:ulo(#)}
{opt tipo(formato)}
{opt des:tino(carpeta)}
[{opt replace} {opt nounz:ip}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt codigo(#)}}codigo de la encuesta/ronda en el portal; obligatoria{p_end}
{synopt:{opt modulo(#)}}numero de modulo; obligatoria{p_end}
{synopt:{opt tipo(formato)}}{cmd:stata}, {cmd:spss}, {cmd:csv} o {cmd:dbf}; obligatoria{p_end}
{synopt:{opt destino(carpeta)}}carpeta donde se guarda el modulo; se crea si no existe; obligatoria{p_end}
{synopt:{opt replace}}vuelve a descargar aunque el modulo ya se haya descargado{p_end}
{synopt:{opt nounzip}}deja el .zip sin descomprimir{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:sriinei} descarga un modulo de microdatos del portal SRIENAHO del
INEI (Peru), armando la direccion de descarga con el patron del portal:

{p 8 8 2}
{it:https://proyectos.inei.gob.pe/iinei/srienaho/descarga/FORMATO/COD-ModuloN.zip}

{pstd}
Funciona con cualquier encuesta publicada en el portal (ENAHO, ENA,
ENAPRES y otras): no trae un catalogo propio de encuestas, anios o
modulos, asi que no se desactualiza cuando se publican encuestas nuevas.

{pstd}
{bf:Como encontrar codigo() y modulo():} entre al portal de microdatos
({browse "https://proyectos.inei.gob.pe/microdatos/"}), elija la encuesta
y el anio, y mire el enlace de descarga de un modulo. El archivo se llama
{it:COD}{cmd:-Modulo}{it:N}{cmd:.zip}: {it:COD} va en {opt codigo()} y
{it:N} en {opt modulo()}.


{marker options}{...}
{title:Opciones}

{phang}
{opt codigo(#)} es el codigo de la encuesta/ronda que aparece en el
enlace de descarga.

{phang}
{opt modulo(#)} es el numero de modulo que aparece en el enlace de
descarga.

{phang}
{opt tipo(formato)} es el formato del archivo: {cmd:stata}, {cmd:spss},
{cmd:csv} o {cmd:dbf}. No todos los formatos existen para todas las
encuestas y anios.

{phang}
{opt destino(carpeta)} es la carpeta donde se guarda el modulo. Se crea
si no existe.

{phang}
{opt replace} vuelve a descargar el modulo aunque ya se haya descargado
en {opt destino()}.

{phang}
{opt nounzip} deja el archivo {cmd:.zip} descargado sin descomprimir.


{marker remarks}{...}
{title:Comentarios}

{pstd}
Al descomprimir, {cmd:sriinei} lista los archivos y carpetas que el
modulo creo en {opt destino()}. Los nombres vienen del .zip del INEI y
suelen ser distintos de {it:COD}{cmd:-Modulo}{it:N}.

{pstd}
Para saber si un modulo ya se descargo, {cmd:sriinei} guarda en
{opt destino()} un pequeno archivo de registro,
{cmd:.sriinei_}{it:COD}{cmd:-Modulo}{it:N}{cmd:_}{it:FORMATO}{cmd:.txt},
con la direccion usada y los archivos extraidos. Si ese archivo existe,
el modulo se omite, salvo que use {opt replace}. Con {opt nounzip}, se
revisa el propio {cmd:.zip}. Borrar el archivo de registro obliga a una
nueva descarga.


{marker examples}{...}
{title:Ejemplos}

{pstd}Un modulo en formato Stata (reemplace los codigos por los que vea en el portal){p_end}
{phang2}{cmd:. sriinei, codigo(906) modulo(1234) tipo(stata) destino("C:/ENA/raw")}{p_end}

{pstd}Dejar el .zip sin descomprimir{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(csv) destino("C:/ENA/raw") nounzip}{p_end}

{pstd}Volver a descargar aunque ya se haya descargado{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(stata) destino("C:/ENA/raw") replace}{p_end}

{pstd}Varios modulos de la misma encuesta{p_end}
{phang2}{cmd:foreach m in 1895 1896 1897 {c 123}}{p_end}
{phang2}{cmd:    sriinei, codigo(1036) modulo(`m') tipo(stata) destino("C:/ENA/raw")}{p_end}
{phang2}{cmd:{c 125}}{p_end}


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. La afiliacion se indica solo para identificacion
-- este software no es un producto oficial del INEI y el INEI no es
responsable por el. Distribuido bajo la Licencia Publica General GNU v3
(https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Portal de microdatos: {browse "https://proyectos.inei.gob.pe/microdatos/"}

{psee}
In English: {helpb sriinei}
{p_end}
