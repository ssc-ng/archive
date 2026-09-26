{smcl}
{* *! version 1.20  24sep2026}{...}
{vieweralsosee "tsvy (English)" "help tsvy"}{...}
{viewerjumpto "Sintaxis" "tsvy_es##syntax"}{...}
{viewerjumpto "Descripcion" "tsvy_es##description"}{...}
{viewerjumpto "Opciones" "tsvy_es##options"}{...}
{viewerjumpto "Comentarios" "tsvy_es##remarks"}{...}
{viewerjumpto "Ejemplos" "tsvy_es##examples"}{...}
{viewerjumpto "Estructura del frame" "tsvy_es##frame"}{...}
{viewerjumpto "Referencias" "tsvy_es##references"}{...}
{viewerjumpto "Autor" "tsvy_es##author"}{...}
{viewerjumpto "Vea tambien" "tsvy_es##also_see"}{...}
{hline}
{title:Titulo}

{phang}
{bf:tsvy} {hline 2} Tabla de estimaciones puntuales y test de
Wald/Bonferroni/CLD, por nivel de agregacion y anio, para datos de
encuestas complejas

{phang}
{it:Version {bf:1.20} (24sep2026)}{p_end}

{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:tsvy}
{ifin}{cmd:,}
{cmdab:varn:ame(}{it:varname}{cmd:)}
{cmdab:years:(}{it:numlist}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:opciones}]

{pstd}
donde {it:statname} es una de {cmd:mean}, {cmd:total}, {cmd:proportion},
o {cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Principales}
{synopt:{opt varn:ame(varname)}}variable de analisis; requerida. El
numerador, cuando {cmd:stat(ratio)}{p_end}
{synopt:{opt years(numlist)}}anios calendario realmente presentes en
{cmd:ANIO_} en los datos actuales, en orden ascendente; requerida{p_end}
{synopt:{opt stat(statname)}}estadistico a estimar y testear:
{cmd:mean}, {cmd:total}, {cmd:proportion}, o {cmd:ratio}; requerida{p_end}
{synopt:{opt nivel(varlist)}}variables que definen los niveles de
agregacion sobre los que hacer el loop; por defecto
{cmd:nivel(NACIONAL REGION NOMBREDD_)}{p_end}
{synopt:{opt cruce(varname)}}una variable de cruce adicional (por
ejemplo, sexo, un grupo etario, un tipo de uso de la tierra -- cualquier
cosa que necesite la tabla ademas de {cmd:nivel()}); si se da, se estima
y testea por separado cada combinacion de valor de {cmd:nivel()} x valor
de {it:cruce}{p_end}
{synopt:{opt subpop(exp)}}universo de analisis, mismo rol que
{cmd:subpop()} del prefijo {helpb svy} nativo -- ver
{help tsvy_es##remarks_subpop:Comentarios: subpop() vs if}. Recomendado
por sobre {cmd:[if]} siempre que tambien se use {cmd:cruce()}{p_end}
{synopt:{opt l:evel(#)}}el valor de {it:varname} que se trata como
exito; solo importa con {cmd:stat(proportion)}; por defecto
{cmd:level(1)}{p_end}
{synopt:{opt d:enominator(varname)}}variable denominador, para que
{cmd:stat(ratio)} estime la razon entre {it:varname} y {it:denominator};
requerida con {cmd:stat(ratio)}, se ignora en cualquier otro caso{p_end}
{synopt:{opt expectcats(numlist)}}categorias que {it:varname} deberia
tomar; {cmd:tsvy} se detiene antes de estimar nada si las
categorias observadas no coinciden exactamente{p_end}

{syntab:Estimacion}
{synopt:{opt a:lpha(#)}}nivel de significancia para los intervalos de
confianza y los tests de Wald/Bonferroni; por defecto
{cmd:alpha(0.05)}{p_end}
{synopt:{opt boot(#)}}numero de replicas bootstrap para el F omnibus;
{cmd:boot(0)}, el default, usa el calculo analitico (asintotico) en vez
de un bootstrap{p_end}
{synopt:{opt bseed(#)}}semilla aleatoria para el bootstrap, cuando
{cmd:boot()>0}{p_end}

{syntab:Vs-una-referencia (opcional)}
{synopt:{opt refyear(#)}}anio calendario (uno de {cmd:years()}) a usar
como base fija. Agrega las columnas {cmd:P_VS_REF}/{cmd:SIG_VS_REF},
comparando CADA anio contra {cmd:refyear()} (Bonferroni sobre {it:k}-1
comparaciones) -- una pregunta DISTINTA de {cmd:GRUPO} (CLD de todos los
pares){p_end}

{syntab:MMD (opcional, apagado por defecto)}
{synopt:{opt mmd}}corre ademas {cmd:mmd_2s} (test de dos muestras
Maximum Mean Discrepancy, {browse "https://ideas.repec.org/c/boc/bocode/s459820.html":ssc install mmd_2s}),
comparando los 2 anios indicados en {cmd:mmdyears()} en cada bloque, y
agregando {cmd:P_MMD}/{cmd:EFFECT_MMD} al frame acumulador. Apagado por
defecto: corre {cmd:mmdboot()}*{cmd:mmdreps()} remuestreos POR bloque,
notablemente mas lento que el resto de {cmd:tsvy} en una corrida con
muchos bloques de {cmd:nivel()}/{cmd:cruce()}. Requiere
{cmd:mmdyears()} y {cmd:mmdweight()}; no soportado con {cmd:boot()>0}{p_end}
{synopt:{opt mmdyears(numlist)}}los 2 anios EXACTOS, ambos de
{cmd:years()}, que compara {cmd:mmd} -- requerido si se pasa {cmd:mmd};
{cmd:tsvy} corta con un mensaje en vez de adivinar un par. Independiente
de {cmd:refyear()}: son dos preguntas distintas ({cmd:refyear()} es el
anio base de {cmd:P_VS_REF}/{cmd:SIG_VS_REF}, un contraste del
ESTIMADOR de la encuesta contra {it:k}-1 anios; {cmd:mmdyears()} son
siempre 2 anios, contrastados sobre la DISTRIBUCION completa a nivel de
unidad) y no tienen por que coincidir -- {cmd:mmd} funciona sin
{cmd:refyear()} en absoluto{p_end}
{synopt:{opt mmdweight(varname)}}variable de peso pasada a {cmd:mmd_2s}
como {cmd:[aweight=}{it:varname}{cmd:]}; requerido si se pasa {cmd:mmd}.
{cmd:mmd_2s} no es un comando {helpb svy}, no hereda el peso de
{helpb svyset} -- se pide explicito, igual criterio que
{cmd:denominator()} para {cmd:stat(ratio)}{p_end}
{synopt:{opt mmdboot(#)}}opcion {cmd:boot()} pasada a {cmd:mmd_2s}; por
defecto {cmd:mmdboot(200)}{p_end}
{synopt:{opt mmdreps(#)}}opcion {cmd:reps()} pasada a {cmd:mmd_2s}; por
defecto {cmd:mmdreps(20)}{p_end}
{synopt:{opt mmdseed(#)}}opcion {cmd:seed()} pasada a {cmd:mmd_2s}; por
defecto {cmd:mmdseed(12345)}{p_end}

{syntab:Salida}
{synopt:{opt frame(name)}}frame acumulador; por defecto
{cmd:frame(ACUM_ALL)}{p_end}
{synopt:{opt threshold(#)}}umbral de CV(%) por encima del cual una fila
se marca {cmd:REF_ = "a/"}; por defecto {cmd:threshold(15)}{p_end}
{synopt:{opt replace}}elimina y recrea el frame acumulador en vez de
agregarle filas{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} debe existir en los datos actuales; tambien debe existir una
variable llamada literalmente {cmd:ANIO_} (la variable que
{cmd:tsvy} usa internamente como {cmd:over()}). El dataset ya debe
estar declarado con {helpb svyset}.

{pstd}
{bf:Requiere Stata 16.0 o superior.} {cmd:tsvy} acumula su salida con
{helpb frame:frames} ({cmd:frame create}, {cmd:frame }{it:nombre}{cmd::}),
una funcionalidad introducida en Stata 16; no corre en Stata 14 o 15.

{pstd}
{cmd:tsvy} siempre deja exactamente una fila en {cmd:frame()} por cada
combinacion ({cmd:nivel()}, [{cmd:cruce}]) vista en algun lado de los
datos, incluso cuando esa combinacion no tiene observaciones utilizables
(0 observaciones, o muy pocos anios para estimar): ese bloque recibe una
fila "vacia" (todas las columnas en missing salvo
{cmd:NIVEL}/{cmd:CATEGORIA}/{cmd:CRUCE}/{cmd:var}) en vez de saltarse por
completo. Esto hace predecible la cuenta de filas al exportar a un rango
fijo contiguo en una plantilla despues de {cmd:reshape wide}, sin tener
que revisarla cada vez. Aplica solo al camino conjunto
({cmd:boot()==0}).


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:tsvy} arma, en una sola pasada, la tabla que normalmente
necesita quien trabaja con cortes transversales repetidos u olas panel de
una encuesta compleja: estimaciones puntuales desagregadas por nivel de
agregacion (nacional, regional, local, ...) y por anio, {it:junto con} un
test de si la estimacion de cada nivel realmente cambio de un anio a
otro. Recorre cada nivel de agregacion nombrado en {cmd:nivel()},
corriendo el mismo calculo de F omnibus/Bonferroni/CLD
una vez por combinacion (nivel x valor x [valor de
{cmd:cruce}]), y acumula una fila por anio en un frame listo para
{cmd:reshape wide} y exportar -- asi que la tabla de puntos y el test
F/Bonferroni/CLD salen de la misma llamada, sin una pasada separada que
haya que mantener alineada a mano.

{pstd}
{cmd:tsvy} es un companero de
{browse "https://github.com/atalaveracuya/tabsvy":tabsvy}/{cmd:tabsvyexport}
(una herramienta separada, de proposito general, del mismo autor, que
sigue el mismo diseno de recorrer-y-acumular, pero corre
{cmd:svy: + parmby} en cada nivel -- solo estimaciones puntuales, sin
test entre anios). Si usa {cmd:tabsvy} y ademas necesita saber si los
anios son significativamente distintos entre si dentro de cada nivel,
{cmd:tsvy} es la misma idea con un test de Wald/Bonferroni/CLD agregado;
si nunca uso {cmd:tabsvy}, {cmd:tsvy} funciona solo, sin necesitar nada
de ese repositorio.

{pstd}
{cmd:tsvy} {it:no} modifica ni depende del codigo interno de
{cmd:tabsvy.ado}. Si resulta util, integrarlo
dentro de {cmd:tabsvy} mismo es un paso natural
a futuro, pero eso
requiere acceso de escritura al repositorio de {cmd:tabsvy} que este
comando no asume.


{marker options}{...}
{title:Opciones}

{dlgtab:Principales}

{phang}
{opt varname(varname)} es la unica variable de analisis: no un
{it:varlist}. Para tabular varias
variables, llame a {cmd:tsvy} una vez por variable, hacia el mismo
{cmd:frame()} (ver {help tsvy_es##examples:Ejemplos}).

{phang}
{opt years(numlist)} lista los anios calendario reales presentes en
{cmd:ANIO_} en los datos {it:actuales}, en orden cronologico ascendente
-- no se asume que van de 1 a k sin huecos. {cmd:tsvy} lee los
codigos distintos que realmente tiene {cmd:ANIO_} con {helpb levelsof} y
los mapea, por posicion ascendente, uno a uno contra {cmd:years()}; se
detiene con un error si las cantidades no coinciden. Esto sigue la misma
logica de {cmd:years()} que ya tiene {cmd:tabsvy}, asi
que una base a la que le falta un anio entero se maneja simplemente
listando los anios que {it:si} estan presentes, sin decodificar el value
label de {cmd:ANIO_}.

{phang}
{opt stat(statname)} es el estadistico a estimar y testear: {cmd:mean},
{cmd:total}, {cmd:proportion}, o {cmd:ratio}.

{phang}
{opt nivel(varlist)} lista las variables cuyos valores distintos definen
los niveles de agregacion sobre los que hacer el loop -- por ejemplo, una
variable constante {cmd:NACIONAL} (ver
{help tsvy_es##remarks:Comentarios}), un codigo de region, un codigo
de departamento. Por defecto {cmd:nivel(NACIONAL REGION NOMBREDD_)},
igual que el default de {cmd:tabsvy} y la convencion que documenta (una
variable {cmd:NACIONAL} igual a 1 para toda observacion, que representa
"sin desagregar"). Cada valor distinto de cada variable en {cmd:nivel()}
obtiene su propio bloque de filas en la salida.

{phang}
{opt cruce(varname)} agrega una segunda variable de cruce: en vez de
una estimacion por valor de {cmd:nivel()},
{cmd:tsvy} estima una vez por combinacion (valor de {cmd:nivel()},
valor de {it:cruce}), y agrega una columna {cmd:CRUCE} al frame
acumulador. No esta limitada a ningun tipo particular de cruce -- sexo,
un grupo etario, una categoria de uso de la tierra, un tipo de actividad,
lo que necesite la tabla.

{phang}
{opt subpop(exp)} restringe el universo de analisis (por ejemplo,
{cmd:subpop(elegible == 1 & sin_omision == 1)}), el mismo rol que ya
cumple {cmd:[if]} -- pero implementado via la opcion nativa {cmd:svy,
subpop(if {it:exp})} en vez de un filtro {cmd:[if]}, asi que nunca
descarta una UPM del calculo de varianza del diseno. El
{cmd:if} inicial es opcional -- {cmd:subpop(}{it:exp}{cmd:)} y
{cmd:subpop(if }{it:exp}{cmd:)} (la forma que exige el {cmd:subpop()}
nativo de {cmd:svy}) se aceptan igual. Ver
{help tsvy_es##remarks_subpop:Comentarios: subpop() vs if} para por que
esto importa siempre que tambien se de {cmd:cruce()}, y para lo que
{cmd:tsvy} hace para frenar el error especifico que motivo esta opcion.
No soportado junto con {cmd:boot()} > 0 (ver Comentarios).

{phang}
{opt level(#)} es el valor de {it:varname} que se trata como exito,
para {cmd:stat(proportion)}. {opt denominator(varname)} es la variable
denominador para {cmd:stat(ratio)}, requerida con ese estadistico.
{opt alpha(#)} es el nivel de significancia para los intervalos de
confianza y los tests de Wald/Bonferroni.

{phang}
{opt expectcats(numlist)} declara, de entrada, que categorias deberia
tomar {it:varname} (por ejemplo, {cmd:expectcats(1 2)} para un indicador
dicotomico). Si las categorias realmente observadas en los datos no
coinciden exactamente, {cmd:tsvy} se detiene antes de estimar nada,
la misma validacion temprana que hace {cmd:tabsvy} con su propio
{cmd:expectcats()}.

{dlgtab:Estimacion}

{phang}
{opt boot(#)} y {opt bseed(#)} controlan el bootstrap del F omnibus (ver
arriba). {cmd:boot()>0} requiere que el {helpb svyset} actual declare
tanto una UPM {it:como} un estrato.

{dlgtab:Salida}

{phang}
{opt frame(name)} nombra el frame acumulador. Si todavia no existe, se
crea; las filas existentes se conservan (y se agregan las nuevas) salvo
que tambien se de {opt replace}.

{phang}
{opt threshold(#)} es el umbral del coeficiente de variacion (en
porcentaje) por encima del cual la columna {cmd:REF_} de una fila se fija
en {cmd:"a/"}, una marca comun para una estimacion demasiado imprecisa
(alta variabilidad muestral) para reportar con confianza.

{phang}
{opt replace} elimina y recrea {cmd:frame()} en vez de agregarle filas a
lo que ya tenga. Usela en la primera llamada de una secuencia (ver
{help tsvy_es##examples:Ejemplos}); omitala en las llamadas
siguientes que deban acumularse en el mismo frame.


{marker remarks}{...}
{title:Comentarios y ejemplos}

{pstd}
Los comentarios se presentan bajo los siguientes titulos:

{phang2}{help tsvy_es##remarks_nacional:La convencion NACIONAL}{p_end}
{phang2}{help tsvy_es##remarks_subpop:subpop() vs if}{p_end}
{phang2}{help tsvy_es##remarks_limits:Diferencias con tabsvy, y limitaciones actuales}{p_end}

{marker remarks_nacional}{...}
{pstd}{bf:La convencion NACIONAL}

{pstd}
El {cmd:nivel()} por defecto de {cmd:tsvy} espera una variable
llamada literalmente {cmd:NACIONAL}, constante en 1 para toda
observacion, igual que documenta el propio README de {cmd:tabsvy}
({cmd:gen NACIONAL = 1}). Esto es lo que permite que un solo loop
{cmd:nivel("NACIONAL REGION NOMBREDD_")} produzca un bloque "nacional"
(un unico valor, sin desagregacion real) junto a desagregaciones
genuinas de region/departamento, usando el mismo mecanismo para ambas
cosas.

{marker remarks_subpop}{...}
{pstd}{bf:subpop() vs if}

{pstd}
Restringir el universo de analisis con {cmd:[if]} y hacerlo con
{cmd:subpop()} dan LA MISMA estimacion puntual -- pero no siempre el
mismo error estandar, y la direccion de la diferencia importa.
Restringir con {cmd:[if]} {it:antes} de estimar puede descartar UPMs
enteras del diseno: si un estrato queda con una sola UPM sobreviviente
despues del filtro, el {cmd:singleunit(missing)} por defecto de Stata (o
{cmd:singleunit(certainty)}, que le asigna variancia CERO a ese estrato
en silencio, sin avisar) hace que la contribucion real de ese estrato a
la variancia nunca se cuente. {cmd:subpop()} mantiene el diseno COMPLETO
(todas las UPM y estratos muestreados) para el calculo de variancia, y
solo excluye del reporte final las categorias fuera de la subpoblacion
-- ver West, Berglund y Heeringa (2008), la referencia canonica de este
mecanismo exacto (citada completa mas abajo).

{pstd}
Esto no es una preocupacion teorica para este paquete: es el bug que
motivo {cmd:subpop()} en primer lugar. Un script real de produccion
tenia {cmd:MUJER==1} dentro del {cmd:[if]} JUNTO con {cmd:cruce(MUJER)}
-- lo que anulaba {cmd:cruce()} en silencio, porque {cmd:touse} (armado
desde {cmd:[if]}) ya habia excluido al otro grupo antes de que
{cmd:cruce()} pudiera separar por el. Medido en tabulados reales de
produccion, el error estandar resultante para el grupo minoritario
(Mujer, ~30% del universo ponderado) salio sistematicamente ~6.7% mas
chico que el valor correcto -- confirmado contra una simulacion Monte
Carlo nativa de Stata (1,000 muestras replicadas de una poblacion
estratificada fija) que reproduce el mecanismo exacto: estratos
reducidos a una sola UPM informante bajo {cmd:[if]} aportan variancia
cero en silencio.

{pstd}
{cmd:subpop()} cierra esto a nivel de sintaxis, no solo confiando en la
disciplina de quien escribe el codigo: es un lugar SEPARADO de
{cmd:[if]} para declarar el universo, y {cmd:tsvy} verifica activamente
que ni la variable de {cmd:cruce()} ni ninguna variable de {cmd:nivel()}
aparezca como palabra completa dentro de la expresion de {cmd:subpop()}
-- cortando con una explicacion de este mecanismo exacto si la
encuentra, en vez de dejar que el mismo error reaparezca una opcion mas
adelante.

{pstd}
Patron recomendado: use {cmd:subpop()} -- no {cmd:[if]} -- para definir
quien cuenta en absoluto (por ejemplo, un indicador de UA valida, un
indicador de sexo-no-omitido), AUNQUE esa restriccion sea la misma para
todos los grupos de {cmd:cruce()}. Ver inmediatamente abajo por que las
dos no son intercambiables de forma confiable, ni siquiera en ese caso
que "parece seguro". Use {cmd:cruce()}/{cmd:over()} -- nunca {cmd:[if]}
-- para separar los grupos que se estan comparando.

{pstd}
{bf:Un {cmd:[if]} de solo-universo no es un atajo seguro para
{cmd:subpop()}.} Cuando {cmd:[if]} restringe SOLO el universo (la misma
condicion para todos los grupos de {cmd:cruce()}, nunca un valor del
grupo que se compara), {cmd:[if]} y {cmd:subpop(if} {it:misma
condicion}{cmd:)} dan LA MISMA estimacion puntual, siempre -- confirmado
hasta epsilon de maquina de precision doble en cada replica probada
hasta ahora, incluida la simulacion de abajo. NO dan de forma confiable
el mismo error estandar: un {cmd:[if]} de solo-universo esta expuesto al
mismo mecanismo de descarte de UPM descrito arriba, solo que sin el
error de {cmd:cruce()}-dentro-del-{cmd:[if]} que motivo esta opcion en
primer lugar. Si la restriccion llega a excluir a todos los miembros de
alguna UPM (o deja a un estrato con una sola UPM sobreviviente),
{cmd:[if]} descarta esa UPM del diseno y se pierde su contribucion a la
variancia; {cmd:subpop()} la mantiene. Esto es poco frecuente con
fracciones bajas de omision y se vuelve real a medida que crece la
proporcion omitida -- confirmado con una simulacion Monte Carlo de 250
muestras replicadas de un diseno estratificado por conglomerados en
cada uno de cuatro niveles de omision del universo (10%, 20%, 30%, 50%
-- 1,000 replicas en total): la diferencia maxima en la estimacion
puntual fue exactamente {cmd:0.0000000000} en los cuatro niveles; la
diferencia maxima en el error estandar fue exactamente
{cmd:0.0000000000} en 10%, 20% y 30%, pero {cmd:0.0018270000} en 50% --
alrededor de 4.5% del error estandar promedio de ese nivel (0.040686),
una divergencia real y estructural, no ruido de punto flotante,
apareciendo exactamente donde el mecanismo de arriba lo predice: al
menos una replica con 50% de omision termino excluyendo una UPM entera.
Ver, en este repositorio, {cmd:ejemplo_if_vs_subpop_universo.do} y
{cmd:simulacion_stata_if_vs_subpop_universo.do}. Consecuencia practica:
use {cmd:subpop()} incluso para una restriccion de solo-universo --
{cmd:[if]} seguido, pero no siempre, da el mismo error estandar, y no
hay forma de saber desde el resultado solo en cual de los dos casos se
esta.

{pstd}
{cmd:subpop()} por ahora solo esta soportado cuando {cmd:boot()} es 0
(el default, el camino conjunto de {cmd:over()} -- el que se usa en
produccion); {cmd:tsvy} corta con un error si se combina {cmd:subpop()}
con {cmd:boot()} > 0, en vez de ignorarlo en silencio.

{marker remarks_mmd}{...}
{pstd}{bf:Rendimiento de mmd(), y por que viene apagado por defecto}

{pstd}
A diferencia del resto del camino de produccion de {cmd:tsvy} (un solo
{cmd:svy:} por variable de {cmd:nivel()}, calculando todos los niveles y
anios juntos via {cmd:over()}, sin remuestreo), {cmd:mmd} corre una
llamada SEPARADA a {cmd:mmd_2s} por cada bloque ({cmd:nivel()},
{cmd:cruce()}), cada una con {cmd:mmdboot()}*{cmd:mmdreps()} remuestreos
sobre los datos crudos a nivel de unidad. Una corrida con pocos bloques
(por ejemplo {cmd:nivel(NACIONAL)} solo) apenas lo nota; una con muchos
(por ejemplo {cmd:nivel(NOMBREDD_)} cruzado con {cmd:cruce(sexo)}, 24
departamentos x 2 = 48 bloques) puede tardar sustancialmente mas que la
misma llamada sin {cmd:mmd}. Por eso {cmd:mmd} viene apagado por
defecto y hay que pedirlo explicitamente, y por eso
{cmd:mmdboot()}/{cmd:mmdreps()} quedan ajustables en vez de fijos:
bajarlos para una primera pasada sobre muchos bloques, subirlos para
una corrida final sobre los pocos bloques que importan.

{pstd}
{cmd:mmd_2s} no es un comando {helpb svy}: no usa el diseno de
{helpb svyset} (estratos/UPM) en absoluto, asi que {cmd:subpop()} no se
le puede pasar como prefijo nativo {cmd:svy, subpop()} igual que al
resto de {cmd:tsvy}. Cuando se pasan {cmd:subpop()} y {cmd:mmd} juntos,
{cmd:tsvy} aplica la expresion de {cmd:subpop()} a {cmd:mmd_2s} como un
{cmd:[if]} directo -- no hay riesgo de perdida de UPM que evitar aca,
porque {cmd:mmd_2s} nunca uso el diseno de la encuesta para empezar.
Los 2 anios comparados son exactamente los de {cmd:mmdyears()}, el MISMO
par en todos los bloques -- {cmd:tsvy} no sustituye un anio distinto si
alguno de los dos falta en un bloque puntual; si cualquiera de los 2
anios de {cmd:mmdyears()} no tiene datos en ese bloque, o {cmd:mmd_2s}
falla, {cmd:P_MMD}/{cmd:EFFECT_MMD} simplemente quedan en missing para
ese bloque, el mismo criterio de degradar sin cortar que ya tiene
{cmd:P_VS_REF}. Ver {help tsvy_es##options:mmdyears()} sobre por que ya
no depende de {cmd:refyear()} vs el ultimo anio.

{marker remarks_limits}{...}
{pstd}{bf:Diferencias con tabsvy, y limitaciones actuales}

{phang2}o (solo {cmd:boot()==0}) un bloque de {cmd:nivel()} x
[{cmd:cruce}] con datos en UN SOLO anio igual recibe una fila, con
{cmd:ESTIMA}/{cmd:ERROR_ST}/{cmd:LIM_INF}/{cmd:LIM_SUP}/{cmd:N_SIN_PON}/
{cmd:N_PONDERA}/{cmd:CV} llenos para ese anio -- solo
{cmd:F_WALD}/{cmd:P_WALD}/{cmd:GRUPO}/{cmd:P_VS_REF}/{cmd:SIG_VS_REF}
quedan en missing para todo el bloque, porque con 1 anio genuinamente no
hay con que testear. Esto aplica solo al
camino de produccion ({cmd:boot()==0}); con {cmd:boot()>0}, {cmd:tsvy}
estima una vez por bloque via bootstrap, y ese camino
todavia exige al menos 2 anios de datos para correr -- un bloque con 1
anio se sigue salteando ahi con un aviso, sin aportar filas, igual que
siempre. {cmd:tabsvy} no tiene esta restriccion en ningun caso, porque
no necesita comparar anios entre si.{p_end}
{phang2}o {cmd:tsvy} todavia no tiene las opciones
{cmd:keepcat()}/{cmd:tipo()} de {cmd:tabsvy} para recorrer un bloque
tematico de varias variables indicadoras 0/1 a la vez. Si una tabla
necesita ese patron, siga usando {cmd:tabsvy} para eso, o llame a
{cmd:tsvy} una vez por indicador hacia el mismo {cmd:frame()} y
etiquete el bloque usted mismo (ver
{help tsvy_es##examples:Ejemplos}).{p_end}
{phang2}o {cmd:tsvy} requiere que la variable que usa internamente
como {cmd:over()} se llame exactamente {cmd:ANIO_}; no es
configurable.{p_end}
{phang2}o cuando {cmd:boot()}
es 0 (el default), {cmd:tsvy} corre un solo
{cmd:svy: STAT ..., over(nivel_var [cruce_var] ANIO_)} conjunto por cada
variable de {cmd:nivel()} -- el mismo comando que correria a mano para
tener una tabla de referencia -- en vez de filtrar a un valor de
{cmd:nivel()} (y, si se dio, de {cmd:cruce()}) por vez y correr
{cmd:over(ANIO_)} dentro de ese filtro. Esto importa siempre que un
subconjunto filtrado pueda dejar afuera estratos enteros que por
casualidad no tengan ninguna observacion de ese valor puntual: filtrar
primero puede dar un error estandar sistematicamente mas
chico que el de referencia con {cmd:over()} conjunto (confirmado en
datos reales de produccion, hasta 35% mas chico en categorias chicas/
raras de {cmd:cruce()}), aunque la
estimacion puntual coincida exacto de las dos formas.
{cmd:nivel()} y {cmd:cruce()} (cuando se da) se
agrupan {it:juntas} con {cmd:ANIO_} en una sola variable
{cmd:egen group()} y se cortan de UNA llamada conjunta a {cmd:svy:} por
posicion, lo que
funciona porque
{cmd:egen group()} ordena ascendente primero por {cmd:nivel()}, despues
por {cmd:cruce()}, despues por {cmd:ANIO_}, asi que cada bloque
({cmd:nivel()}, {cmd:cruce()}) sigue siendo un rango contiguo de
codigos. Esto replica el diseno de la herramienta companera
{cmd:parmby_tdiff.ado} (Talavera Cuya 2026): una sola llamada a
{cmd:svy:} con todas las variables de cruce juntas en {cmd:over()},
cortada por posicion despues, nunca re-filtrada ni re-estimada por
bloque -- {cmd:tsvy} usa {cmd:egen group()} mas {cmd:summarize} en vez
de la aritmetica fija mod/ceil de {cmd:parmby_tdiff} justamente porque
{cmd:egen group()} tolera combinaciones ({cmd:nivel()}, {cmd:cruce()})
faltantes o dispersas (un departamento sin UAs de algun tipo de uso de
la tierra, por ejemplo) sin necesitar un cruce perfectamente
rectangular -- {cmd:parmby_tdiff} en cambio documenta eso como
requisito (su cantidad de columnas de {it:e(b)} debe ser divisible
exacto entre la cantidad de anios). Solo {cmd:boot()>0} usa el
camino de filtrar y despues {cmd:over(ANIO_)}, porque reconstruye
replicas de remuestreo por bloque via bootstrap -- un mecanismo
distinto, que implementa la misma matematica exacta de
F-test/Bonferroni/CLD y da resultados identicos de cualquier
forma.{p_end}


{marker examples}{...}
{title:Ejemplos}

{pstd}
El script de abajo (preparacion + ejemplos 1-5) esta confirmado corriendo
de punta a punta sin error en Stata real. El {cmd:.} inicial antes de un
comando de una sola linea es el prompt de comando (convencion estandar de
los help files de Stata, no es parte del comando, y es seguro copiarlo
tal cual); las lineas dentro del bloque {cmd:foreach} del ejemplo 3 se
muestran sin el, porque un {cmd:.} dejado en cada linea de un bloque
{cmd:foreach}/{cmd:forvalues} de varias lineas -- incluido el cuerpo y la
llave de cierre -- rompe el parseo del bloque en Stata al pegarlo en un
do-file. Las lineas de comentario (que empiezan con {cmd:*}) no llevan
prompt de ningun modo; se muestran aca tal como quedarian en su propio
do-file.

{pstd}
Cada ejemplo de abajo es autocontenido y corre sobre {cmd:auto.dta}, uno
de los datasets de ejemplo incluidos en Stata -- alcanza con
{cmd:sysuse auto}, no hace falta ningun dato externo. {cmd:auto.dta}
no tiene un diseno de encuesta real,
asi que la preparacion de abajo es la minima que deja correr a
{cmd:tsvy} (cada observacion como su propia UPM). {cmd:auto.dta} tampoco tiene una variable
de anio, asi que {cmd:ANIO_} se fabrica solo para poder ejercitar la
mecanica a traves del tiempo -- en un uso real, {cmd:ANIO_} y la
convencion {cmd:NACIONAL} vienen de la misma preparacion que ya se usa
antes de llamar a {cmd:tabsvy} (ver su README).

{phang2}{cmd:* Preparacion}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}

{pstd}
{bf:Ejemplo 1: una llamada, varios niveles de agregacion.} {cmd:mean} de
{cmd:mpg}, tres niveles ({cmd:NACIONAL} y ambos valores de
{cmd:foreign}), tres anios cada uno -- estimaciones puntuales mas el test
F/Bonferroni/CLD entre anios, todo en un frame, una sola llamada:{p_end}
{phang2}{cmd:* Ejemplo 1: una llamada, varios niveles de agregacion}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:  nivel(NACIONAL foreign) frame(F1) replace}{p_end}
{phang2}{cmd:. frame F1: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Ejemplo 2: {cmd:proportion}}, con {cmd:expectcats()} vigilando la
codificacion de la variable de analisis ({cmd:foreign} debe tomar
exactamente 0/1, o {cmd:tsvy} se detiene antes de estimar
nada):{p_end}
{phang2}{cmd:* Ejemplo 2: proportion, con expectcats()}{p_end}
{phang2}{cmd:. tsvy, varname(foreign) stat(proportion) level(1) ///}{p_end}
{phang2}{cmd:   years(2021 2022 2023) expectcats(0 1)  ///}{p_end}
{phang2}{cmd:   nivel(NACIONAL) frame(F2) replace}{p_end}
{phang2}{cmd:. frame F2: list NIVEL CATEGORIA ANIO ESTIMA CV REF_ F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Ejemplo 3: {cmd:total}}, varias variables acumuladas en el mismo
frame ({cmd:replace} solo en la primera llamada -- este es el patron
para recorrer {cmd:tsvy} sobre muchas variables de analisis, tal
como un pipeline real lo recorre sobre muchos indicadores). Note que el
bloque {cmd:foreach} de abajo no lleva {cmd:.} inicial en ninguna de sus
lineas -- ver la nota al inicio de esta seccion sobre por que:{p_end}
{phang2}{cmd:* Ejemplo 3: total, varias variables en el mismo frame}{p_end}
{phang2}{cmd:local variables mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:local i = `i' + 1}{p_end}
{phang2}{cmd: tsvy, varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd: nivel(NACIONAL) frame(F3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:frame F3: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Ejemplo 4: una segunda dimension de cruce} con {cmd:cruce()} --
aca, una particion por precio hace de sustituto de una particion
demografica real como sexo (o, en una tabla de produccion, una
categorica real como un tipo de uso de la tierra):{p_end}
{phang2}{cmd:* Ejemplo 4: una segunda dimension de cruce con cruce()}{p_end}
{phang2}{cmd:. gen byte precio_alto = (price > 6000)}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:  nivel(NACIONAL) cruce(precio_alto) frame(F4) replace}{p_end}
{phang2}{cmd:. frame F4: list NIVEL CATEGORIA CRUCE ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA CRUCE)}{p_end}

{pstd}
{bf:Ejemplo 5: {cmd:ratio}} -- {opt denominator()} es requerida, y es una
opcion aparte de {opt varname()} (el numerador), no una expresion
{cmd:num/den}:{p_end}
{phang2}{cmd:* Ejemplo 5: ratio -- denominator() es una opcion aparte}{p_end}
{phang2}{cmd:. tsvy, varname(trunk) stat(ratio) denominator(length) ///}{p_end}
{phang2}{cmd:years(2021 2022 2023) nivel(NACIONAL foreign) frame(F5) replace}{p_end}
{phang2}{cmd:. frame F5: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Ejemplo 6: restringir el universo con {cmd:[if]}.} {cmd:tsvy}
acepta un {cmd:if} inicial igual que {cmd:svy:}, y lo aplica a cada
estimacion que el loop hace internamente -- no esta limitado al
cruce {cmd:nivel()}/{cmd:cruce()}. Usela cuando la estimacion deba
correr sobre una subpoblacion en vez de todo el dataset (por ejemplo,
solo los registros que pasan una condicion de elegibilidad o control de
calidad definida antes). Abajo, {cmd:rep78} viene missing en 5 autos de
{cmd:auto.dta}; restringir a {cmd:rep78 < .} los saca del universo antes
de estimar, igual que un pipeline real restringe a los registros que
pasan su propio filtro antes de llamar a {cmd:svy: total}:{p_end}
{phang2}{cmd:* Ejemplo 6: restringir el universo con [if]}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(weight) stat(total) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) nivel(NACIONAL foreign) frame(F6) replace}{p_end}
{phang2}{cmd:. frame F6: list NIVEL CATEGORIA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Este {cmd:if} importa en cada llamada de un loop, no solo en la
primera.} Si su pipeline estima varios indicadores, cada uno bajo su
propia condicion de elegibilidad, ponga esa condicion en todas las
llamadas a {cmd:tsvy} dentro del loop -- {cmd:replace} sigue yendo
solo en la primera llamada, pero el {cmd:if} va en todas:{p_end}
{phang2}{cmd:. foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy if elegible == 1 & control_calidad == 0, ///}{p_end}
{phang2}{cmd:        varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        nivel(NACIONAL) frame(F7) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}

{pstd}
El mismo patron escala directo a un pipeline real de encuesta compleja:
mantenga el loop {cmd:forvalues}/{cmd:foreach} del ejemplo 3, reemplace
{cmd:mpg weight length} por su propia lista de variables indicadoras,
agregue la condicion {cmd:if} que sus datos realmente necesiten (como en
el ejemplo 6), y reemplace {cmd:nivel(NACIONAL foreign)} por las
variables de nivel de agregacion que realmente tengan sus datos (un total
nacional mas las variables tipo region/departamento que apliquen).{p_end}

{pstd}
{bf:Ejemplo 7: {cmd:refyear()} -- comparar cada anio contra UN anio
base.} {cmd:GRUPO} (usado en todos los ejemplos de arriba) responde
"que anios difieren ENTRE SI" -- todos los pares, Bonferroni sobre
{it:k}(k-1)/2 comparaciones. {cmd:refyear()} responde una pregunta mas
angosta y DISTINTA -- "que anios difieren de ESTE anio base" -- solo
{it:k}-1 comparaciones, Bonferroni sobre {it:k}-1 (Dunn 1961) -- y
agrega {cmd:P_VS_REF}/{cmd:SIG_VS_REF} al frame junto a (no en lugar de)
{cmd:GRUPO}. Las dos pueden legitimamente no coincidir sobre los mismos
datos porque testean familias distintas de hipotesis. Abajo, 2023 es
el anio base -- cada otro anio recibe un
p-valor {cmd:P_VS_REF} contra el, y la propia fila de 2023 queda missing
(un anio no se testea contra si mismo):{p_end}
{phang2}{cmd:* Ejemplo 7: refyear() -- contra un anio base, no todos los pares}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL foreign) refyear(2023) frame(F8) replace}{p_end}
{phang2}{cmd:. frame F8: list NIVEL CATEGORIA ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CATEGORIA)}{p_end}

{pstd}
{bf:Ejemplo 8: {cmd:refyear()} junto con {cmd:cruce()}.} {cmd:refyear()}
funciona igual con {cmd:cruce()} que sin el: con {cmd:boot()==0} (el
default, y tambien el camino que toma {cmd:cruce()} -- ver
{help tsvy_es##remarks_limits:Comentarios}), {cmd:tsvy} calcula
{cmd:P_VS_REF} en linea a partir del mismo {cmd:e(b)}/{cmd:e(V)}
conjunto que ya corto para {cmd:GRUPO}/{cmd:F_WALD}; con
{cmd:boot()>0} se estima una vez por bloque en cambio. De cualquier
forma, cada bloque de
({cmd:nivel()}, {it:cruce}) recibe su propio chequeo de base
{cmd:refyear()} y su propia columna {cmd:P_VS_REF}:{p_end}
{phang2}{cmd:* Ejemplo 8: refyear() + cruce() juntos}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(precio_alto) refyear(2023) frame(F9) replace}{p_end}
{phang2}{cmd:. frame F9: list NIVEL CATEGORIA CRUCE ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CATEGORIA CRUCE)}{p_end}

{pstd}
{bf:Ejemplo 9: {cmd:subpop()} en vez de {cmd:[if]}, con
{cmd:cruce()}.} La restriccion de universo ({cmd:rep78 < .}, la misma
del ejemplo 6) se mueve del {cmd:[if]} a {cmd:subpop()}; la variable
de {cmd:cruce()} ({cmd:foreign}) nunca se repite dentro de
{cmd:subpop()} -- ver {help tsvy_es##remarks_subpop:Comentarios} sobre
por que {cmd:tsvy} verifica activamente esa combinacion exacta, y la
rechaza. {cmd:subpop()} acepta tanto la expresion sola
como el {cmd:if} inicial, igual que el {cmd:subpop()} nativo de
{cmd:svy} -- las dos lineas de abajo son equivalentes:{p_end}
{phang2}{cmd:* Ejemplo 9: subpop() con cruce()}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(rep78 < .) frame(F10) replace}{p_end}
{phang2}{cmd:. frame F10: list NIVEL CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(NIVEL CATEGORIA CRUCE)}{p_end}
{phang2}{cmd:* equivalente -- forma nativa con "if", tambien aceptada}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(if rep78 < .) frame(F10) replace}{p_end}

{pstd}
{bf:Ejemplo 10: un ejemplo completo, corrible de punta a punta,
con {cmd:sysuse auto}.} No necesita ningun dato instalado -- cualquiera
con Stata puede correrlo tal cual. Arma un diseno muestral complejo
chico sobre el {cmd:auto.dta} interno de Stata, usa una condicion
genuinamente presente en los datos ({cmd:rep78} tiene 5 valores
missing, la propia variable de historial de reparaciones de Stata) como
restriccion de universo, y {cmd:foreign} (ya presente en los datos)
como dominio de cruce -- nada inventado:{p_end}
{phang2}{cmd:* Ejemplo 10: subpop() con sysuse auto}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen double psu   = ceil(_n/4)}{p_end}
{phang2}{cmd:. gen double strat = ceil(psu/2)}{p_end}
{phang2}{cmd:. gen double wgt   = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], strata(strat) singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,3))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(foreign) subpop(!missing(rep78)) frame(F11) replace}{p_end}
{phang2}{cmd:. frame F11: list CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(CRUCE)}{p_end}

{pstd}
Chequeo cruzado contra {cmd:svy} nativo para una celda (por ejemplo,
{cmd:foreign==1} en el primer anio sintetico, codigo {cmd:ANIO_==1}):
restrinja {cmd:subpop()} a esa misma celda y saque {cmd:over()} por
completo -- los dos numeros deberian coincidir:{p_end}
{phang2}{cmd:. svy, subpop(if !missing(rep78) & foreign==1 & ANIO_==1): mean mpg}{p_end}
{phang2}{cmd:. frame F11: list ESTIMA ERROR_ST if CRUCE==1 & ANIO==2021}{p_end}

{pstd}
{bf:Ejemplo 11: {cmd:sysuse nlsw88}, con un universo de dato
faltante genuino.} {cmd:nlsw88} (un dataset de ensenanza conocido sobre
salarios de mujeres) tiene valores realmente missing en {cmd:wage} para
algunas encuestadas -- exactamente el tipo de no-respuesta para el que
existe {cmd:subpop()}, sin inventar nada para el ejemplo. El dominio que
se compara es la afiliacion sindical ({cmd:union}):{p_end}
{phang2}{cmd:* Ejemplo 11: subpop() con sysuse nlsw88}{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. gen double psu   = ceil(_n/6)}{p_end}
{phang2}{cmd:. gen double strat = ceil(psu/2)}{p_end}
{phang2}{cmd:. gen double wgt   = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], strata(strat) singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,2))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(wage) stat(mean) years(2021 2022) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) cruce(union) subpop(!missing(wage)) frame(F12) replace}{p_end}
{phang2}{cmd:. frame F12: list CATEGORIA CRUCE ANIO ESTIMA ERROR_ST, sepby(CRUCE)}{p_end}

{pstd}
Nota honesta sobre este dataset en particular: envolver la misma
condicion {cmd:!missing(wage)} en {cmd:[if]} en vez de {cmd:subpop()}
no cambiaria el error estandar de forma visible aca, porque el diseno
sintetico {cmd:psu}/{cmd:strat} de arriba no correlaciona los faltantes
de {cmd:wage} con ningun estrato en particular. El mecanismo importa --
y aparece como una diferencia real -- justamente cuando la restriccion
(dato faltante, un indicador de elegibilidad, lo que sea) se concentra
dentro de estratos especificos, el escenario que
{help tsvy_es##remarks_subpop:Comentarios: subpop() vs if} documenta y
mide en detalle.{p_end}

{pstd}
{bf:Ejemplo 12: {cmd:mmd} --
un test distribucional junto a {cmd:F_WALD}/{cmd:GRUPO}.} Requiere
{browse "https://ideas.repec.org/c/boc/bocode/s459820.html":ssc install mmd_2s}
antes. Leer {help tsvy_es##remarks_mmd:Comentarios: rendimiento de
mmd()} antes de prenderlo sobre muchos bloques de
{cmd:nivel()}/{cmd:cruce()}. Nota: {cmd:mmdyears()} es independiente de
{cmd:refyear()} -- este ejemplo compara 2022 vs 2023, mientras
{cmd:refyear()} queda en 2021 para {cmd:P_VS_REF}/{cmd:SIG_VS_REF}, un
par deliberadamente distinto para mostrar que las dos opciones no
tienen que coincidir:{p_end}
{phang2}{cmd:* Ejemplo 12: mmd, comparando un par explicito de anios}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen double psu = ceil(_n/3)}{p_end}
{phang2}{cmd:. gen double wgt = 1}{p_end}
{phang2}{cmd:. svyset psu [pweight=wgt], singleunit(certainty)}{p_end}
{phang2}{cmd:. gen str4 yr = string(2021 + mod(_n,3))}{p_end}
{phang2}{cmd:. encode yr, gen(ANIO_)}{p_end}
{phang2}{cmd:. gen double NACIONAL = 1}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    nivel(NACIONAL) refyear(2021) mmd mmdyears(2022 2023) ///}{p_end}
{phang2}{cmd:    mmdweight(wgt) frame(F13) replace}{p_end}
{phang2}{cmd:. frame F13: list CATEGORIA ANIO ESTIMA F_WALD P_WALD P_MMD EFFECT_MMD}{p_end}


{marker frame}{...}
{title:Estructura del frame}

{pstd}
{cmd:tsvy} deja las siguientes variables en {cmd:frame()}, una fila
por (nivel de {cmd:nivel()}, valor, [valor de {it:cruce}], anio):

{synoptset 16 tabbed}{...}
{synopt:{cmd:NIVEL}}el nombre de la variable de {cmd:nivel()} para esta
fila (sin el {cmd:_} final si lo tuviera, siguiendo la convencion de
{cmd:tabsvy} -- ej. {cmd:NOMBREDD_} se convierte en {cmd:NOMBREDD}){p_end}
{synopt:{cmd:CATEGORIA}}el valor de la variable de {cmd:NIVEL} para esta fila{p_end}
{synopt:{cmd:CRUCE}}valor de {cmd:cruce()}, si se dio{p_end}
{synopt:{cmd:var}}fijo en 1 (se mantiene solo por compatibilidad de
columnas con el propio frame de {cmd:tabsvy}, donde identifica una
categoria de una variable categorica){p_end}
{synopt:{cmd:VARNAME}}el nombre, como string, de la variable
pasada en {opt varname()} en esta llamada -- igual en TODAS las filas
que deja esa llamada; util para distinguir, en un frame que acumula
varias llamadas de {cmd:tsvy} (ver {help tsvy_es##examples:Ejemplo 3}),
que bloque de filas vino de que variable{p_end}
{synopt:{cmd:ANIO}}anio calendario (mapeado desde {cmd:years()}){p_end}
{synopt:{cmd:ESTIMA}}estimacion puntual{p_end}
{synopt:{cmd:ERROR_ST}}error estandar{p_end}
{synopt:{cmd:CV}}coeficiente de variacion, en porcentaje{p_end}
{synopt:{cmd:LIM_INF LIM_SUP}}limites de confianza{p_end}
{synopt:{cmd:N_SIN_PON N_PONDERA}}tamano de muestra sin ponderar /
ponderado{p_end}
{synopt:{cmd:REF_}}{cmd:"a/"} si {cmd:CV} supera {cmd:threshold()}{p_end}
{synopt:{cmd:F_WALD P_WALD}}estadistico F de Wald global y su p-valor
analitico -- {it:constante entre todos los anios dentro del mismo
bloque}, ya que el test compara todos los anios de ese bloque a la
vez. Queda missing cuando menos de 2 anios del bloque tienen varianza
definida y positiva (un anio con proporcion exactamente 0 o 1 no la
tiene) -- con 0 o 1 anios utilizables no queda nada que testear.
Mientras {it:al menos 2} anios sean utilizables, {cmd:F_WALD}/
{cmd:P_WALD} se calculan sobre ese subconjunto (los anios degenerados
se excluyen del contraste, no todo el bloque).
Esto es independiente de {cmd:ESTIMA}: un bloque con un solo anio
utilizable igual trae {cmd:ESTIMA}/{cmd:ERROR_ST}/etc. de ese anio, con
{cmd:F_WALD}/{cmd:P_WALD}/{cmd:GRUPO} en missing -- ver
{help tsvy_es##remarks_limits:Comentarios: diferencias con tabsvy}{p_end}
{synopt:{cmd:GRUPO}}el codigo del Compact Letter Display para el anio de
{it:esta fila} dentro de su bloque -- varia por anio{p_end}
{synopt:{cmd:P_VS_REF}}p-valor ajustado por Bonferroni ({it:k}-1
comparaciones) del anio de {it:esta fila} contra {cmd:refyear()}; missing
si no se especifico {cmd:refyear()}, y siempre missing en la fila del
propio {cmd:refyear()} -- una familia de comparaciones DISTINTA de
{cmd:GRUPO}{p_end}
{synopt:{cmd:SIG_VS_REF}}estrellas de significancia para {cmd:P_VS_REF}:
{cmd:"*"} p<0.10, {cmd:"**"} p<0.05, {cmd:"***"} p<0.01{p_end}
{synopt:{cmd:P_MMD}}(los 2 anios comparados los fija
{cmd:mmdyears()}) p-valor bootstrap de {cmd:mmd_2s},
comparando la distribucion completa de {opt varname()} entre los 2
anios de {cmd:mmdyears()} -- {it:constante entre todos los anios dentro
del mismo bloque}, mismo patron que {cmd:F_WALD}/{cmd:P_WALD}. Missing
salvo que se haya pasado {cmd:mmd}, y missing en un bloque donde la
comparacion no se pudo correr (ver
{help tsvy_es##remarks_mmd:Comentarios: rendimiento de mmd()}){p_end}
{synopt:{cmd:EFFECT_MMD}}el estadistico de tamano de efecto que
acompana a {cmd:P_MMD} para esa misma comparacion de dos anios -- mismas
reglas de missing que {cmd:P_MMD}{p_end}
{p2colreset}{...}

{pstd}
Como {cmd:F_WALD}/{cmd:P_WALD}/{cmd:P_MMD}/{cmd:EFFECT_MMD} son
constantes dentro de un bloque y {cmd:GRUPO} varia por anio, un
{cmd:reshape wide} posterior deberia listar {cmd:GRUPO} entre las
variables que se reestructuran (asi se convierte en {cmd:GRUPO2023},
{cmd:GRUPO2024}, ...) pero dejar {cmd:F_WALD}/{cmd:P_WALD}/{cmd:P_MMD}/
{cmd:EFFECT_MMD} en {cmd:i()} en cambio, para que se lleven una sola vez
por bloque en vez de repetirse innecesariamente por anio:

{phang2}{cmd:. reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV N_PONDERA N_SIN_PON GRUPO,}{p_end}
{phang2}{cmd:        i(NIVEL CATEGORIA var VARNAME F_WALD P_WALD P_MMD EFFECT_MMD) j(ANIO)}{p_end}

{pstd}
Este esquema es por lo demas compatible con la mitad de estimaciones
puntuales de {cmd:tabsvyexport} ({cmd:ESTIMA}/{cmd:REF_} por anio), ya
que {cmd:tabsvyexport} ya descarta toda columna que no necesita antes de
su propio reshape.


{marker references}{...}
{title:Referencias}

{pstd}
Los contrastes
{it:k}-1 contra la base de {cmd:refyear()} usan la misma correccion de
Bonferroni que {cmd:GRUPO}, aplicada a una familia de comparaciones mas
chica y DISTINTA (Dunn, O.J. 1961. Multiple comparisons among means.
{it:Journal of the American Statistical Association} 56(293): 52-64).

{pstd}
West, B.T., Berglund, P.A., Heeringa, S.G. 2008. A closer examination of
subpopulation analysis of complex-sample survey data. {it:Stata Journal}
8(4): 520-531. Referencia canonica de {help
tsvy_es##remarks_subpop:por que subpop() difiere de if}, el mecanismo
detras de {cmd:subpop()} (la incorporacion principal de esta version).


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. La afiliacion se indica solo para fines de
identificacion -- este software no es un producto oficial de INEI y INEI
no es responsable por el. Distribuido bajo la licencia GNU General
Public License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).


{marker also_see}{...}
{title:Vea tambien}

{psee}
En linea: {helpb svy}
{p_end}

{psee}
In English: {helpb tsvy}
{p_end}
