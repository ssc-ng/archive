{smcl}
{* *! version 1.35  19nov2026}{...}
{vieweralsosee "tsvyexport (in English)" "help tsvyexport"}{...}
{viewerjumpto "Sintaxis" "tsvyexport_es##syntax"}{...}
{viewerjumpto "Descripcion" "tsvyexport_es##description"}{...}
{viewerjumpto "Opciones" "tsvyexport_es##options"}{...}
{viewerjumpto "Comentarios: wide()" "tsvyexport_es##wide"}{...}
{viewerjumpto "Ejemplos" "tsvyexport_es##examples"}{...}
{viewerjumpto "Resultados guardados" "tsvyexport_es##results"}{...}
{viewerjumpto "Autor" "tsvyexport_es##author"}{...}
{viewerjumpto "Vea tambien" "tsvyexport_es##also_see"}{...}
{hline}
{title:Titulo}

{phang}
{bf:tsvyexport} {hline 2} Exporta un frame acumulador de {helpb tsvy} a Excel o Word

{phang}
{it:Version {bf:1.35} (19nov2026)}{p_end}

{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:tsvyexport using} {it:archivo} {cmd:}[{cmd:,} {it:opciones}{cmd:]}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt frame(name)}}frame acumulador a leer. Por defecto: {bf:ACUM_ALL}{p_end}
{synopt:{opt excel}}fuerza salida en Excel sin importar la extension del archivo{p_end}
{synopt:{opt word}}fuerza salida en Word sin importar la extension del archivo{p_end}
{synopt:{opt sheet(string)}}nombre de la hoja en Excel. Por defecto: {bf:tsvy}{p_end}
{synopt:{opt title(string)}}texto de titulo sobre la tabla (Word); en Excel solo aparece en el mensaje de pantalla{p_end}
{synopt:{opt numero(string)}}numero de cuadro al estilo INEI (capitulo.numero, ej. {cmd:"5.1"}), antepuesto al titulo. Solo Word{p_end}
{synopt:{opt unidad(string)}}unidad de medida entre parentesis en una linea debajo del titulo (ej. {cmd:"Hectareas"} sale como {cmd:"(Hectareas)"}). Solo Word{p_end}
{synopt:{opt fuente(string [, tamano(#)])}}linea de fuente al pie del cuadro, impresa como {cmd:"Fuente: "}+texto+{cmd:"."} (ej. {cmd:fuente("INEI - Encuesta Nacional Agropecuaria", tamano(9))}). {opt tamano(#)} es una suboption opcional (tamano de letra en puntos, por defecto {bf:9}). Solo {opt wide}+Word; si no se pasa, no sale esa linea{p_end}
{synopt:{opt elaboracion(string [, tamano(#)])}}linea de elaboracion al pie del cuadro, impresa como {cmd:"Elaboracion: "}+texto+{cmd:"."}, con la misma suboption opcional {opt tamano(#)}. Solo {opt wide}+Word; si no se pasa, no sale esa linea{p_end}
{synopt:{opt estilo(string)}}preset de formato para la tabla de {opt wide}+Word: {cmd:clasico}, {cmd:apa7} o {cmd:revista} -- fuente, tamanos y (para {cmd:apa7}/{cmd:revista}) borde de tres lineas. Sin pasarlo, el formato de Word por defecto (sin cambios respecto a antes de esta opcion). Solo {opt wide}+Word{p_end}
{synopt:{opt keep(varlist)}}exporta solo estas columnas, en este orden. Por defecto: todas las del frame{p_end}
{synopt:{opt replace}}sobreescribe el archivo de salida{p_end}
{synopt:{opt append}}agrega la tabla como una hoja nueva (Excel) o una seccion nueva (Word) a un archivo ya existente{p_end}
{synopt:{opt digits(#)}}decimales para las columnas continuas de estimacion (ESTIMA, ERROR_ST, CV, LIM_INF, LIM_SUP, F_WALD, EFFECT_MMD). Por defecto: {bf:2}{p_end}
{synopt:{opt wide}}una fila por nivel/categoria/variable de analisis, una columna por anio, en vez de una fila por anio -- ver {help tsvyexport_es##wide:Comentarios} mas abajo. No se puede combinar con {opt keep()}{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:tsvyexport} escribe la tabla de resultados que arma {helpb tsvy}
(un frame acumulador como {bf:ACUM_ALL}, una fila por nivel/categoria/anio)
en un archivo independiente Excel (.xlsx) o Word (.docx), formateado
para leerse fuera de Stata. El formato se toma de {opt excel}/{opt word}
si se especifica, o se infiere de la extension de {it:archivo}.

{pstd}
El frame original nunca se modifica: {cmd:tsvyexport} trabaja sobre una
copia temporal, aplica ahi los formatos numericos segun cada columna, y
descarta la copia al terminar.

{pstd}
{opt replace} y {opt append} siguen la misma logica en los dos formatos:
{opt replace} recrea el archivo de salida desde cero; {opt append}
agrega la exportacion actual como una unidad nueva y separada (una hoja
nueva en Excel, una seccion nueva tras un salto de pagina en Word) sin
tocar lo que el archivo ya tenia. Si el archivo todavia no existe,
{opt append} se comporta como una primera exportacion normal. Si el
archivo ya existe y no se especifica ninguna de las dos, {cmd:tsvyexport}
para con un error en vez de sobreescribirlo en silencio.

{marker options}{...}
{title:Opciones}

{phang}
{opt frame(name)} indica el frame a exportar. Es el mismo nombre que se
le paso a la opcion {cmd:frame()} de {helpb tsvy} al armar la tabla; por
defecto es {bf:ACUM_ALL} porque tambien es el valor por defecto de
{cmd:tsvy}.

{phang}
{opt keep(varlist)} restringe y reordena las columnas exportadas. Cada
nombre debe existir en el frame; la estructura del frame de {cmd:tsvy}
esta documentada en {help tsvy_es##frame:su propio help}.

{phang}
{opt digits(#)} solo afecta a las columnas continuas de estimacion. Los
conteos (ANIO, N_SIN_PON, N_PONDERA) siempre se muestran como enteros, y
los p-valores (P_WALD, P_VS_REF, P_MMD) siempre se muestran con 3
decimales, sin importar {opt digits()}.

{phang}
{opt numero(string)} y {opt unidad(string)} siguen la numeracion real de
cuadros que usa el manual oficial del INEI ("Manual para la
presentacion de cuadros estadisticos"): el numero de cuadro es un
codigo capitulo.numero (por ejemplo {cmd:"5.1"} o {cmd:"23.115"}),
colocado justo antes del titulo en la misma linea, con el titulo mismo
en mayusculas; la unidad de medida, cuando aplica a todo el cuadro, va
en su propia linea justo debajo, entre parentesis (por ejemplo
{cmd:"(Hectareas)"}). Las dos opciones solo afectan la salida a Word
({opt wide} o la plana); en Excel se aceptan pero no tienen efecto,
igual que {opt title()}. {opt numero()} pasa a mayusculas lo que tenga
{opt title()} (o el {cmd:VARNAME} usado como titulo por defecto en
{opt wide}); sin {opt numero()}, el titulo queda exactamente como se
dio, igual que antes de que existiera esta opcion.

{phang}
{bf:Nuevo en v1.19:} {opt fuente()} y {opt elaboracion()} siguen la
convencion del "Pie del cuadro" del mismo manual del INEI, que ordena
notas, llamadas, fuente y elaboracion, en ese orden, al pie del cuadro.
Cuando se pasan, agregan una linea {cmd:"Fuente: ..."} y una linea
{cmd:"Elaboracion: ..."} despues de la leyenda de Sig./Grupos. El
tamano de letra vive DENTRO de cada opcion, como suboption
{opt tamano(#)} (puntos, por defecto {bf:9}, mas chico que el cuerpo
del documento, igual que en los ejemplos del manual) -- ej.
{cmd:fuente("INEI - Direccion X", tamano(8))} -- en vez de una opcion
aparte a nivel de {cmd:tsvyexport}, para poder usar tamanos distintos
en {opt fuente()} y {opt elaboracion()} si hiciera falta. Las dos
opciones son independientes entre si -- omitir una solo salta esa
linea, y omitir {opt tamano()} adentro de una usa el default. Un texto
con coma (necesaria antes de que pueda aparecer {opt tamano()}) debe ir
entre comillas, ej. {cmd:fuente("INEI, Encuesta Nacional Agropecuaria")}.
Solo {opt wide}+Word (misma restriccion que {opt numero()}/{opt unidad()}).

{phang}
{bf:Nuevo en v1.21:} {opt estilo(string)} aplica un preset de formato a
la tabla de {opt wide}+Word -- fuente, tamanos de titulo/encabezado/
cuerpo/notas y (para {cmd:apa7}/{cmd:revista}) un estilo de bordes.
Investigado porque el manual del INEI no especifica ninguna tipografia
(solo advierte, generico, no distorsionar "el tipo de letra estandar"
al escalar para imprimir); los presets de abajo salen de guias de
estilo reales encontradas para agencias de estadistica y publicacion
academica:

{p2colset 9 26 28 2}{...}
{p2col:{cmd:clasico}}Arial Narrow -- titulo 10pt negrita, encabezado 8pt
negrita, cuerpo 8pt, notas 7pt. Respaldado por el Manual de Estilo del
INDEC (Argentina), que SI especifica tipografia por escrito para
cuadros (Helvetica/Arial Bold ~10pt en titulo, 7pt en cuerpo) -- el
precedente real mas cercano encontrado, ya que el manual del INEI mismo
no dice nada al respecto.{p_end}
{p2col:{cmd:apa7}}Times New Roman, 12pt en todo (10pt en {opt fuente()}/
{opt elaboracion()}), siguiendo las reglas oficiales de APA 7ma edicion
para tablas (apastyle.apa.org): borde de tres lineas (solo arriba de la
tabla, bajo el encabezado y al final -- nunca lineas verticales), y un
titulo en formato APA real -- {cmd:"Tabla N"} en negrita en su propia
linea, el titulo mismo en cursiva debajo (NO el formato de una sola
linea {cmd:"numero MAYUSCULAS"} que usa {opt numero()} para
{cmd:clasico}/{cmd:revista}/sin {opt estilo()}).{p_end}
{p2col:{cmd:revista}}Preset generico para revistas indexadas que no
exigen APA especificamente -- mismo borde de tres lineas, Times New
Roman, tamanos un poco menores (11/10/10/9pt) comunes en tablas de
resultados densas.{p_end}
{p2colreset}{...}

{pstd}
Sin {opt estilo()}, la tabla sale igual que antes de que existiera esta
opcion (fuente/tamano por defecto de Word, grilla completa de bordes).
Un {opt tamano(#)} explicito dentro de {opt fuente()}/
{opt elaboracion()} sigue ganando por encima del tamano del preset. Esta
opcion solo afecta {opt wide}+Word; la tabla plana de Word y la salida a
Excel quedan sin cambios (extenderla a Excel -- fuente/tamano, no
bordes, que no aplican igual en Excel -- es un seguimiento mas chico,
todavia no implementado). {bf:Confirmado contra Stata real (v1.23):}
la mecanica de bordes de {cmd:apa7}/{cmd:revista} (borrar todos los
bordes de la tabla y despues dibujar 3 de vuelta por rango de fila)
quedo verificada -- ver la Prueba 13 del {cmd:test_putdocx_merge.do}
que acompana este .ado.

{pstd}
{bf:Bug real de v1.24-v1.26, corregido en v1.27:} con datos reales, las
celdas de encabezado a la derecha de la fusion de {cmd:Estimacion}
(Var.%/Sig./Grupos) podian salir sin su sombreado, y con
{cmd:estilo(apa7)}/{cmd:estilo(revista)}, con una linea vertical de
grilla de mas en vez de la tabla de 3 lineas. Causa real: un
{cmd:colspan()} corre la direccion de columna de todas las celdas a su
derecha en esa fila, y el sombreado/limpieza de borde de esas columnas
de encabezado corria en un paso aparte, siempre DESPUES de que ese
corrimiento ya habia pasado. v1.27 formatea cada celda de encabezado en
la MISMA llamada que su propio {cmd:rowspan()}/{cmd:colspan()}, antes
de que cualquier corrimiento de direccion la pueda afectar. Ver la
Prueba 14 (se deja como referencia del bug) y la Prueba 15 (el fix) en
{cmd:test_putdocx_merge.do}.

{marker wide}{...}
{title:Comentarios: wide()}

{pstd}
Por defecto {cmd:tsvyexport} escribe el frame tal cual lo arma
{helpb tsvy} -- una fila por nivel/categoria/anio (forma "tidy").
{opt wide} en cambio escribe una fila por nivel/categoria/[cruce]/
variable de analisis, con una columna {cmd:ESTIMA}{it:anio} separada
por cada anio -- la forma que usan las tablas comparativas anio contra
anio, lado a lado. Es el mismo pivote que ya esta documentado como
receta de {cmd:reshape wide} en {help tsvy_es##frame:la seccion
Estructura del frame de tsvy}, hecho aca automaticamente, junto con la
exportacion.

{pstd}
{opt wide} siempre exporta un conjunto fijo de columnas (no se puede
combinar con {opt keep()}): las columnas identificadoras ({cmd:NIVEL},
{cmd:CATEGORIA}, {cmd:CRUCE} si esta presente, {cmd:VARNAME}), una
columna {cmd:ESTIMA}{it:anio} por cada valor distinto de {cmd:ANIO} en
el frame, una columna {cmd:SIG_VS_REF}{it:anio} por cada anio si el
frame trae {cmd:SIG_VS_REF} (solo presente cuando {helpb tsvy} corrio
con una categoria de referencia), {cmd:F_WALD}/{cmd:P_WALD} (el test
omnibus entre anios, constante dentro de cada fila porque no varia por
anio), una columna {cmd:SIG_WALD} con asteriscos de significancia
calculados aca a partir de {cmd:P_WALD} ({cmd:"*"} p<0.10, {cmd:"**"}
p<0.05, {cmd:"***"} p<0.01 -- los mismos umbrales que usa el propio
{cmd:SIG_VS_REF} de {helpb tsvy}), y una columna {cmd:GRUPOS} con la
letra de Compact Letter Display de cada anio unida con guion (por
ejemplo {cmd:"d-c-b-a"}), leida directo de la columna {cmd:GRUPO} de
{cmd:tsvy}. El frame necesita al menos 2 anios distintos para poder
pivotear.

{pstd}
{opt wide} combinado con {opt word} arma una tabla por {cmd:VARNAME}
cuando el frame tiene exactamente uno. Sale con un encabezado combinado
en 2 filas: una etiqueta de fila ({cmd:NIVEL}/{cmd:CATEGORIA}/
{cmd:CRUCE}), {cmd:Estimacion} fusionado sobre todas las columnas de
anio, y {cmd:Var. %}/{cmd:Sig.}/{cmd:Grupos} abarcando las dos filas de
encabezado -- el mismo formato que un cuadro comparativo anio contra
anio armado a mano. {cmd:Var. %} es el ULTIMO anio contra el
inmediato anterior (ej. {cmd:"Var. % 2026/2025"} -- v1.18; antes
comparaba el primer y el ultimo anio de todo el frame). Es la misma
definicion que usan las agencias de estadistica oficial (INEI, BCRP,
etc.), que siempre calculan la variacion anio-contra-anio-anterior, no
un cambio acumulado de toda la serie; es un comportamiento fijo, sin
opcion nueva para volver a la definicion vieja, porque no hay un caso
de uso real para conservarla. {bf:Nuevo en v1.16/v1.17:} esa etiqueta de
fila usa {cmd:CATEGORIA_LBL}/{cmd:CRUCE_LBL} (el texto real de la
etiqueta de valor, ej. {cmd:"Puno"}) en vez del codigo numerico puro de
{cmd:CATEGORIA}/{cmd:CRUCE}, cuando el frame trae esas columnas
({helpb tsvy_es:tsvy} v1.21 o posterior) y no estan en blanco para esa
fila -- SOLO ese texto, sin anteponer el nombre de la variable de
{cmd:nivel()} (v1.17; antes, en v1.16, salia {cmd:"departamento Puno"},
ahora sale solo {cmd:"Puno"}). Cuando {cmd:CATEGORIA_LBL} esta en
blanco para una fila, esa fila vuelve a {cmd:NIVEL} + el codigo
numerico, igual que siempre.

{pstd}
{bf:Nuevo en v1.13/v1.14:} con 2 o mas valores distintos de
{cmd:VARNAME}, {opt wide} combinado con {opt word} ya no para con un
error -- en cambio arma UNA sola tabla con filas anidadas:
{cmd:Categoria} [y {cmd:Cruce}, si {cmd:CRUCE} esta presente] fusionada
verticalmente con {cmd:rowspan} sobre cada fila {cmd:Variable}
(={cmd:VARNAME}) de ese grupo, y dos columnas hoja por anio
({cmd:Valor}/{cmd:Sig.}, donde {cmd:Sig.} es {cmd:SIG_VS_REF} de ese
anio -- la significancia de esa categoria contra la categoria de
referencia, no el test omnibus). La columna del omnibus se mantiene al
final, renombrada {cmd:Sig. Wald} para no confundirla con el
{cmd:Sig.} por anio. Esta forma necesita un {cmd:rowspan} de cuerpo que
arranca DENTRO del rango de otro {cmd:rowspan} de cuerpo en una columna
distinta, y una fila de encabezado con varios {cmd:colspan} (uno por
anio) aplicados de derecha a izquierda -- las dos mecanicas ya estan
confirmadas contra Stata real de forma aislada por el script
{cmd:test_putdocx_merge.do} que acompana a este .ado (Pruebas 7, 9, 11
y 12); {cmd:tsvyexport} en si todavia no se corrio de punta a punta con
datos reales de 2+ {cmd:VARNAME}. Con exactamente 1 {cmd:VARNAME}, la
tabla sale igual que en la forma descrita arriba.

{pstd}
Los numeros de esta tabla usan formato latinoamericano (separador de
miles con espacio, coma decimal, ej. {cmd:16 681}; {cmd:Var. %} ademas
lleva un {cmd:+} adelante cuando es positivo), sin importar la magnitud
({bf:corregido en v1.20:} un {cmd:ESTIMA} muy grande, ej. del orden de
los millones, se pasaba del ancho fijo que se usaba internamente para
formatearlo, y salia en notacion cientifica rota, ej.
{cmd:"3,40e+06"}; los numeros grandes ahora se formatean bien). Si hay
una fila con
{cmd:NIVEL} {cmd:"NACIONAL"}, sale sombreada como fila de total y va
primera (v1.15), igual que la convencion del manual del INEI de listar
el "Total" antes que las categorias que lo componen. {bf:Nuevo en
v1.30:} cuando el frame se armo con {opt cldmetodo()} de {helpb tsvy}
(v1.24+), la leyenda de Grupos muestra el metodo de ajuste entre
parentesis -- ej. {cmd:"Grupos (Holm): ..."}, {cmd:"Grupos (Fisher
LSD): ..."}. Un frame armado con una version anterior de {cmd:tsvy}
(sin esa characteristic guardada) muestra la leyenda exactamente igual
que antes, sin el parentesis. {bf:Nuevo en
v1.19:} las casillas siguen los simbolos que pide el propio manual para
valores especiales (p.25): un {cmd:ESTIMA} missing imprime {cmd:"..."}
("no disponible" -- puntos ASCII normales, no el caracter real de
elipsis, para mantener este archivo en ASCII puro); un {cmd:ESTIMA}
exactamente 0 imprime {cmd:"-"} ("magnitud cero"); y un {cmd:ESTIMA}
distinto de 0 pero que redondea a 0 con los decimales de {opt digits()}
imprime un {cmd:"0"} solo ("la cantidad no alcanza a la mitad de la
unidad"). Un {cmd:Var. %} missing (anio con denominador 0 o missing)
tambien imprime {cmd:"..."}; la distincion cero/media-unidad no aplica
a una variacion porcentual, solo a cifras de nivel. Despues de la
tabla va una leyenda corta explicando {cmd:Sig.}/{cmd:Sig. Wald}
y {cmd:Grupos}, y luego, cuando se pasan {opt fuente()}/
{opt elaboracion()}, las lineas de fuente/elaboracion descritas arriba.

{pstd}
{bf:Nuevo en v1.34:} {cmd:Sig.} ({cmd:SIG_WALD}) solo usa niveles iguales
o menores al {cmd:alpha()} con que {helpb tsvy} calculo las letras (0.05
por defecto: {cmd:**} p<0.05, {cmd:***} p<0.01), para que nunca salga una
estrella junto a letras que no separan anios por el solo hecho de usar
umbrales distintos. Si el F de Wald es significativo y aun asi todos los
anios comparten letra, la columna {cmd:CLD_INCONS} vale 1 y {cmd:GRUPOS}
lleva la llamada {cmd:b/}, explicada en la leyenda de Word. Con
{cmd:cldmetodo(auto)} de {helpb tsvy} (default desde tsvy v1.29), las
filas en que se uso un ajuste distinto de Bonferroni lo indican entre
parentesis en {cmd:GRUPOS}, ej. {cmd:"b-a-a (holm)"}, y la columna
{cmd:CLD_METODO} se exporta en Excel.

{marker examples}{...}
{title:Ejemplos}

{pstd}
Cada ejemplo de abajo es autocontenido y corre sobre {cmd:auto.dta}, uno
de los datasets de ejemplo de Stata, el mismo setup que usan
{help tsvy_es##examples:los propios ejemplos de tsvy} -- basta con
{cmd:sysuse auto}, no hace falta ningun dato externo. Cada ejemplo
primero llama a {helpb tsvy_es:tsvy} para armar (o agregar a) un frame
acumulador, y despues a {cmd:tsvyexport} para exportarlo -- solo la
linea de {cmd:tsvyexport} es nueva aca.

{phang2}{cmd:* Setup}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}
{phang2}{cmd:. gen byte precio_alto = (price > 6000)}{p_end}

{pstd}
Arma el frame por defecto {bf:ACUM_ALL} y despues lo exporta -- con
{cmd:.xlsx} alcanza para que {cmd:tsvyexport} sepa que hay que escribir
Excel:{p_end}
{phang2}{cmd:* Ejemplo 1: exportacion basica, formato inferido de la extension}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) frame(ACUM_ALL) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.xlsx}{p_end}

{pstd}
{cmd:frame()} en la llamada a {cmd:tsvy} y en la de
{cmd:tsvyexport} tiene que nombrar el mismo frame:{p_end}
{phang2}{cmd:* Ejemplo 2: Word, con titulo, desde un frame no por defecto}{p_end}
{phang2}{cmd:. tsvy, varname(weight) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL foreign) frame(MIACUM) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.docx, frame(MIACUM) ///}{p_end}
{phang2}{cmd:    title("Peso promedio por region")}{p_end}

{pstd}
Un segundo frame independiente (esta vez con
{cmd:cruce(precio_alto)}) exportado con {opt append} al mismo
{cmd:resultados.xlsx} del ejemplo 1, como hoja propia -- la hoja
{cmd:tsvy} del ejemplo 1 queda intacta:{p_end}
{phang2}{cmd:* Ejemplo 3: append -- agrega una hoja nueva, deja la primera intacta}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(precio_alto) frame(ACUM2) replace}{p_end}
{phang2}{cmd:. tsvyexport using resultados.xlsx, frame(ACUM2) ///}{p_end}
{phang2}{cmd:    sheet(mpg_por_precio) append}{p_end}

{pstd}
Reusa el frame {bf:ACUM_ALL} del ejemplo 1, hacia un archivo aparte:{p_end}
{phang2}{cmd:* Ejemplo 4: subconjunto de columnas, 3 decimales}{p_end}
{phang2}{cmd:. tsvyexport using resumen.xlsx, keep(NIVEL CATEGORIA ANIO ESTIMA ERROR_ST) ///}{p_end}
{phang2}{cmd:    digits(3) replace}{p_end}

{pstd}
Tres variables acumuladas en el mismo frame (mismo patron que
{help tsvy_es##examples:el propio Ejemplo 3 de tsvy}), y despues
exportadas en formato ancho: cada fila es un indicador, con una columna
por anio mas {cmd:SIG_WALD} y {cmd:GRUPOS}:{p_end}
{phang2}{cmd:* Ejemplo 5: wide -- una fila por indicador, una columna por anio}{p_end}
{phang2}{cmd:local indicadores mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local indicadores {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy, varname(`v') stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        nivel(NACIONAL) frame(ACUM3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:tsvyexport using reporte_ancho.xlsx, frame(ACUM3) wide replace}{p_end}

{pstd}
{opt wide} hacia un archivo {cmd:.docx}, un solo indicador desagregado
por categoria ({cmd:rep78}, la calificacion de mantenimiento, hace de
"departamento"; primero se descartan los 5 autos sin calificacion,
igual que en {help tsvy_es##examples:el propio Ejemplo 6 de tsvy}):
una fila por valor de {cmd:rep78}, con el encabezado combinado por anio
descrito arriba:{p_end}
{phang2}{cmd:* Ejemplo 6: wide -- Word, encabezado combinado, varias categorias}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(mpg) stat(mean) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) nivel(rep78) frame(ACUM4) replace}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace}{p_end}

{pstd}
El mismo cuadro del ejemplo 6, esta vez con la numeracion real de
cuadros del INEI: el codigo capitulo.numero va justo antes del titulo
(que sale en mayusculas), y la unidad de medida tiene su propia linea
entre parentesis debajo:{p_end}
{phang2}{cmd:* Ejemplo 7: wide -- Word, con numero()/unidad() al estilo INEI}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("5.1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    unidad("Millas por galon")}{p_end}

{phang2}{cmd:* Ejemplo 8: wide -- Word, con el pie del cuadro}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("5.1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    unidad("Millas por galon") ///}{p_end}
{phang2}{cmd:    fuente("INEI - Encuesta Nacional Agropecuaria", tamano(8)) ///}{p_end}
{phang2}{cmd:    elaboracion("INEI - Direccion de Estadisticas Agrarias")}{p_end}

{phang2}{cmd:* Ejemplo 9: wide -- Word, preset APA 7ma edicion}{p_end}
{phang2}{cmd:. tsvyexport using cuadro_categorias.docx, frame(ACUM4) wide replace ///}{p_end}
{phang2}{cmd:    numero("1") title("Rendimiento por categoria de mantenimiento") ///}{p_end}
{phang2}{cmd:    estilo("apa7")}{p_end}

{marker results}{...}
{title:Resultados guardados}

{pstd}
{cmd:tsvyexport} no deja nada en {cmd:r()}; revise {cmd:_rc} o el
mensaje que imprime en pantalla al terminar.

{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. La afiliacion se indica solo para fines de
identificacion -- este software no es un producto oficial del INEI y el
INEI no tiene responsabilidad sobre el. Distribuido bajo la licencia
GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{marker also_see}{...}
{title:Vea tambien}

{psee}
En linea: {helpb tsvy}, {helpb putexcel}, {helpb putdocx}
{p_end}

{psee}
In English: {helpb tsvyexport}
{p_end}
