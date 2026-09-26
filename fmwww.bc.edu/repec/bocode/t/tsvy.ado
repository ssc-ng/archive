*! tsvy.ado v1.20 - 24sep2026
*! Motor generico de estimacion + test (F de Wald + Bonferroni + Compact
*! Letter Display) con encuestas complejas, usando svylet como unico motor.
*! Requiere Stata 16 o superior EN LA INSTALACION (usa frame create/
*! frame ...: ...); el "version 14" de las lineas de abajo NO es sobre
*! eso, ver la nota v1.6 (revertida) inmediatamente debajo.
*!
*! v1.20 -- BREAKING CHANGE: renombra la COLUMNA de salida CAIDA a
*! CATEGORIA (columna, no opcion -- no hay opcion caida()/categoria(),
*! nunca la hubo; esto es distinto del rename de opcion CAIDA()->NIVEL()
*! de v1.19). [SUPERSEDED la nota v1.19 de abajo, que decia explicitamente
*! que esta columna NO iba a cambiar de nombre -- a pedido del usuario,
*! tras ver en produccion real que "CAIDA" quedaba sin relacion de
*! nombre con ninguna opcion (a diferencia de NIVEL/CRUCE, que SI
*! coinciden con su opcion) y que su significado cambia segun el bloque
*! (ej. CAIDA=1 en NIVEL="NACIONAL" es "todo el pais", CAIDA=1 en
*! NIVEL="foreign" es "Foreign") -- confuso de leer en produccion.
*! "CATEGORIA" es el termino que el manual INEI usa para el mismo
*! concepto (pag. 21: "Contiene los conceptos que identifican las
*! categorias"). Cambia: la columna en el frame acumulador (todos los
*! "gen double CAIDA" pasan a "gen double CATEGORIA"), el parametro
*! interno del subprograma _tsvy_fila_vacia (CAIDA()->CATEGORIA(), sin
*! uso externo, pero renombrado por consistencia con la columna que
*! alimenta), y todos los .do de este repo que hacian
*! list/reshape/egen/sepby sobre CAIDA. Sin cambio de comportamiento
*! (mismo valor, solo el nombre de columna). Quien ya leia CAIDA de un
*! frame de tsvy en sus propios .do debe reemplazarlo por CATEGORIA.
*!
*! v1.19 -- BREAKING CHANGE: renombra la opcion CAIDA() a NIVEL() (mismo
*! tipo de cambio que v1.8 con SEXOVAR()->CRUCE(): solo el NOMBRE de la
*! opcion, sin cambio de comportamiento). Motivo: alineacion con el
*! vocabulario oficial del "Manual para la presentacion de cuadros
*! estadisticos" (INEI, 2006) que revisa este mismo proyecto -- la
*! opcion define exactamente el "listado de clasificaciones" de la
*! "columna matriz" del cuadro (pag. 21 del manual: "el elemento
*! localizado al lado izquierdo del cuadro... Contiene los conceptos que
*! identifican las categorias"), y "NIVEL" es el termino que el propio
*! manual usa para esos niveles de clasificacion (pag. 23: "Para
*! distinguir los diferentes niveles de una clasificacion se recurrira
*! al uso de sangrias") -- ademas de ser, desde siempre, el nombre de la
*! columna de salida que esta opcion alimenta (NIVEL en el frame
*! acumulador), asi que ahora opcion y columna comparten nombre, igual
*! que ya pasa con cruce()/CRUCE. "Caida" no era vocabulario del manual
*! ni de la literatura de encuestas -- jerga interna sin significado
*! claro para quien lee el codigo o el help por primera vez. cruce() NO
*! cambia (esa palabra si tiene respaldo directo en el manual: la propia
*! definicion de columna matriz habla de "cruzamiento" con el
*! encabezado). [SUPERSEDED en v1.20 -- ver nota v1.20 arriba] La columna
*! de salida CAIDA (el VALOR puntual dentro de
*! cada NIVEL, ej. el codigo de departamento) tampoco cambia -- sigue
*! siendo CAIDA, sin relacion de nombre con la opcion nivel() desde
*! ahora (mismo patron que ya existia: la opcion cruce() alimenta la
*! columna CRUCE, pero el VALOR puntual de una categoria de nivel() no
*! tenia opcion propia con su nombre ni la tiene ahora). Quien ya usaba
*! caida() en sus .do debe reemplazarlo por nivel() -- ver USO mas abajo
*! y los .do de este mismo repo (ejemplo_uso_tsvy.do, etc.), ya
*! actualizados.
*!
*! v1.18 -- FIX: un bloque (NIVEL x CAIDA x [CRUCE]) con datos en UN SOLO
*! anio (real en cultivos/dominios chicos) ya NO pierde la fila entera.
*! Hasta v1.17, el camino conjunto (boot()==0, el de produccion) exigia
*! al menos 2 anios validos para escribir CUALQUIER columna del bloque
*! -- con 1 solo anio, toda la fila (ESTIMA incluido) quedaba missing via
*! _tsvy_fila_vacia, aunque el punto estimado de ese unico anio SI se
*! hubiera calculado (viene del mismo "svy: over(combo)" conjunto que
*! corre para TODOS los anios de `a' a la vez, no de un calculo aparte).
*! Encontrado comparando, dominio por dominio, la salida de tsvy contra
*! un pipeline paralelo que arma la misma tabla con un "svy," subpop()
*! por anio (sin el requisito de 2+ anios): en cada dominio con
*! cobertura de un solo anio, ese pipeline SI mostraba el dato y tsvy no
*! -- confirmado en las 4 hojas de un caso real (oregano/coca/cacao/
*! achiote), siempre el mismo patron (Amazonas-2025, Lima-2026, Loreto-
*! 2024, etc., cada uno con datos en 1 anio nada mas).
*!
*! Ahora: ESTIMA/ERROR_ST/LIM_INF/LIM_SUP/N_SIN_PON/N_PONDERA/CV se
*! llenan igual que siempre para CUALQUIER anio con columna real en
*! e(b), sin importar cuantos anios validos tenga el bloque -- eso no
*! cambia. Lo que SI sigue exigiendo 2+ anios (porque matematicamente no
*! hay con que testear con 1 solo) es F_WALD/P_WALD/GRUPO/P_VS_REF/
*! SIG_VS_REF, que quedan en missing/vacios para todo el bloque cuando
*! k_cat_valido==1 -- igual criterio de "degradar sin cortar" que ya
*! usaba P_VS_REF cuando refyear() no estaba presente en un bloque. Un
*! bloque sin NINGUN anio con columna real (k_cat_valido==0, varianza
*! degenerada en todos) sigue usando _tsvy_fila_vacia como hasta ahora
*! -- ahi si no hay absolutamente nada que conservar.
*!
*! v1.17 -- REDISENO de mmd() a pedido del usuario: el par de anios ya no
*! se asume (refyear() vs el ultimo anio de years()) -- ahora se declara
*! EXPLICITAMENTE con la opcion nueva mmdyears(anio1 anio2), y mmd() sin
*! mmdyears() corta con un mensaje claro en vez de adivinar un default.
*! Motivo: el default implicito de v1.16 (refyear() vs ultimo anio)
*! atava mmd() a refyear() sin motivo real -- son preguntas distintas
*! (refyear() es la base de P_VS_REF/SIG_VS_REF, un contraste de a
*! ESTIMADOR contra k-1 anios; mmd() siempre compara exactamente 2 anios,
*! sobre la DISTRIBUCION) y el usuario puede querer comparar un par que
*! no incluya a refyear() en absoluto (ej. dos anios pre-pandemia). Ya
*! no se calcula "el ultimo anio PRESENTE en cada bloque" tampoco (v1.16
*! lo hacia por si un bloque no llegaba hasta el ultimo anio de years())
*! -- mmdyears() fija el MISMO par en todos los bloques; si un bloque no
*! tiene datos de alguno de los 2 anios, sigue degradando a P_MMD/
*! EFFECT_MMD missing para ESE bloque puntual (mismo criterio que
*! siempre), pero ya no intenta sustituir el anio faltante por otro.
*! refyear() deja de ser requisito de mmd() -- son opciones independientes
*! ahora; mmdweight()/mmdboot()/mmdreps()/mmdseed()/el resto del diseno
*! (opt-in, boot()==0 unicamente, subpop() como [if] plano) no cambia.
*!
*! v1.16 -- agrega mmd() (opcional, default apagado): un segundo test por
*! bloque (NIVEL x CAIDA x [CRUCE]), ADEMAS del F de Wald/Bonferroni ya
*! existente, usando el comando externo mmd_2s (Maximum Mean Discrepancy,
*! kernel RBF -- ssc install mmd_2s; https://ideas.repec.org/c/boc/bocode/
*! s459820.html). A diferencia de F_WALD/GRUPO (que comparan TODOS los
*! anios entre si, sobre el ESTIMADOR/media/total/ratio), mmd_2s compara
*! solo DOS anios ([SUPERSEDED en v1.17 -- ya NO es refyear() contra el
*! ultimo anio de years(), ver nota v1.17 arriba: son los 2 anios de
*! mmdyears()]) y sobre la DISTRIBUCION completa de `varname' a nivel de
*! UNIDAD (no del agregado
*! survey) -- detecta diferencias de forma/varianza que un test sobre la
*! media puede no ver. Por eso viaja aparte, en columnas propias (P_MMD/
*! EFFECT_MMD), nunca reemplazando F_WALD/P_WALD.
*!
*! Diseno, en orden de decision:
*!   1. Apagado por default (mmd, flag): mmd_2s corre boot()*reps()
*!      remuestreos POR BLOQUE (NIVEL x CAIDA x CRUCE) -- en una corrida
*!      con muchos bloques (ej. NOMBREDD_ x cruce(sexo), 24 x 2 = 48
*!      bloques) esto es sustancialmente mas lento que el resto de tsvy
*!      (que hace UN solo svy: por over() conjunto, sin bootstrap en el
*!      camino de produccion). Se prendio a pedido explicito del usuario,
*!      pero se dejo opt-in porque el usuario mismo senalo el riesgo de
*!      demora antes de decidir el default.
*!   2. [SUPERSEDED en v1.17 -- ver nota v1.17 arriba] Requiere refyear()
*!      (corta con error si se pasa mmd sin refyear(): no hay "ultimo
*!      anio vs base" sin un anio base) y mmdweight() (mmd_2s no es un
*!      comando svy:, no hereda pweight de svyset -- se pasa aparte,
*!      EXPLICITO, mismo criterio que denominator() para stat(ratio):
*!      tsvy nunca adivina un nombre de variable). Desde v1.17, el
*!      requisito es mmdyears() (no refyear()) -- mmdweight() sigue
*!      igual.
*!   3. Solo soportado en el camino conjunto (boot()==0, el de produccion)
*!      -- mismo criterio y mismo error que subpop() (ver v1.15): corta
*!      con error si se combina con boot()>0, en vez de ignorar mmd() en
*!      silencio.
*!   4. Universo: `cond_bloque' (NIVEL=valor [CRUCE=valor]) restringido a
*!      los dos anios comparados, MAS subpop() si se paso -- mmd_2s no
*!      entiende "svy, subpop()" (no es un comando svy:), asi que aca
*!      subpop() se aplica como [if] directo; no hay perdida de UPM que
*!      evitar porque mmd_2s no usa el diseno svyset en absoluto (no
*!      calcula error estandar de una media/total, es un test
*!      distribucional sobre observaciones individuales).
*!   5. Si mmd_2s falla (rc!=0) o el bloque no tiene datos en AMBOS anios,
*!      P_MMD/EFFECT_MMD quedan en missing para ESE bloque -- mismo
*!      criterio de degradacion sin cortar el loop que ya usa F_WALD/
*!      P_VS_REF cuando falta un anio.
*!   6. Columnas P_MMD/EFFECT_MMD SIEMPRE existen en el frame acumulador
*!      (missing si no se paso mmd, o si el bloque no lo pudo calcular) --
*!      mismo criterio que F_WALD/P_WALD/P_VS_REF: esquema de columnas
*!      estable entre llamadas de tsvy que se van a acumular/exportar
*!      juntas, sin importar si CADA llamada puntual pidio mmd.
*!
*! v1.15.2 -- corrige una afirmacion sobreestimada de v1.15 (solo
*! documentacion, sin cambio de codigo en tsvy.ado): el usuario volvio a
*! correr la simulacion if-vs-subpop() de solo-universo citada abajo (250
*! replicas x 4 niveles de omision = 1,000 en total, la misma cantidad
*! prometida) y encontro que, al 50% de omision, la diferencia MAXIMA en
*! error estandar entre [if] y subpop() NO es 0.0000000000 como se
*! afirmaba -- es 0.0018270000 (~4.5% del error estandar promedio de ese
*! nivel, 0.040686), una divergencia real, no ruido de punto flotante. La
*! estimacion puntual (b) si coincidio exacto en los 4 niveles (10, 20,
*! 30, 50%). Causa: el mismo mecanismo de descarte de UPM que motivo
*! subpop() en primer lugar (ver v1.15 mas abajo) NO esta limitado al
*! caso cruce()-dentro-de-[if] -- cualquier restriccion en [if], incluida
*! una de solo-universo, puede excluir una UPM entera si la omision es
*! suficientemente alta; a 10/20/30% simplemente no ocurrio en ninguna de
*! esas 750 replicas, pero a 50% si ocurrio en al menos una de las 250.
*! Se corrige la afirmacion "matematicamente identicos" de
*! tsvy.sthlp/tsvy_es.sthlp (Remarks: subpop() vs if) por una mas
*! precisa: estimacion puntual siempre igual, error estandar NO
*! garantizado igual, con los numeros reales de esta corrida documentados
*! ahi. Refuerza (no debilita) el caso de usar subpop() SIEMPRE para
*! definir el universo, no solo cuando cruce() esta involucrado.
*!
*! v1.15.1 -- corrige un bug real de produccion en subpop(), encontrado
*! por el usuario en su propio bucle (forvalues de 10 variables, 10/10
*! iteraciones fallando con "invalid subpop() option", rc=111, 0 filas
*! exportadas por corrida). Causa: v1.15 siempre armaba
*! "svy, subpop(if `subpop')" -- si el usuario ya escribia el "if"
*! adentro de subpop(), tal como se documentaba en ESTE MISMO archivo
*! (bloque USO de abajo) y en tsvy.sthlp/tsvy_es.sthlp (ej.
*! "subpop(if cuenta_UA==1 & OMISION_SEXO!=1)", exactamente la sintaxis
*! que uso el usuario), el resultado era "subpop(if if ...)" --
*! invalido para Stata. Fix: `subpop' se recorta y se le saca un "if "
*! inicial (si esta) ANTES de los chequeos de palabra completa
*! (cruce()/caida() dentro de subpop()) y antes de armar `svyprefix' --
*! asi "subpop(exp)" y "subpop(if exp)" quedan equivalentes. No se pudo
*! correr contra Stata real en este entorno (sin Stata disponible);
*! se pide al usuario reintentar exactamente el bucle que fallo antes
*! de confiar en el fix en produccion.
*!
*! v1.15 -- agrega SUBpop(), igual convencion que subpop() del comando
*! nativo svy (ver svy.ado: SUBpop(passthru) a nivel de prefijo, separado
*! de [if]). Motivo directo: en esta misma sesion de trabajo se depuro un
*! bug real de produccion donde MUJER==1 quedaba metido en el [if] JUNTO
*! con cruce(MUJER) -- eso anula cruce() de raiz, porque `touse' (armado
*! desde [if]) ya excluye al otro grupo ANTES de que egen group() pueda
*! separar por cruce(). El resultado medido en produccion: error estandar
*! sistematicamente ~6.7% mas chico en el grupo minoritario (Mujer),
*! confirmado ademas con una simulacion Monte Carlo nativa de Stata (ver
*! simulacion_stata_if_vs_over.do) que reproduce el mismo mecanismo:
*! estratos que bajo [if] quedan con 1 sola UPM informante aportan
*! varianza CERO (singleunit(certainty), sin aviso visible), mientras que
*! el diseno completo (subpop()/over()) SI aporta esa variancia real.
*!
*! subpop() resuelve esto estructuralmente, no solo por disciplina del
*! usuario: es un lugar SEPARADO de [if] para restringir el UNIVERSO de
*! analisis (ej. "cuenta_UA==1 & OMISION_SEXO!=1"), que tsvy pasa TAL
*! CUAL al prefijo "svy, subpop(if ...):" de cada llamada svy: del camino
*! conjunto (boot()==0) -- exactamente el patron nativo validado en esta
*! misma sesion con datos reales (comparado, en simulacion de 1,000
*! replicas con 4 niveles de omision del 10% al 50%, contra el camino
*! [if]-solo-para-universo: diferencia maxima 0.0000000000 en estimacion
*! y error estandar en TODOS los niveles -- ver
*! simulacion_stata_if_vs_subpop_universo.do). *** CORREGIDO EN v1.15.2
*! (ver arriba): la corrida real mostro 0.0018270000 de diferencia en
*! error estandar al 50% de omision -- NO 0.0000000000 en TODOS los
*! niveles como se afirmaba aca. La estimacion puntual si coincidio
*! siempre; el error estandar no. *** A diferencia de [if],
*! subpop() mantiene el diseno COMPLETO (todas las UPM/estratos
*! seleccionados) para el calculo de varianza; Stata solo excluye del
*! REPORTE las categorias fuera de la subpoblacion, sin perder la
*! contribucion de sus UPM a la variabilidad entre-conglomerados.
*!
*! Salvaguarda agregada (el motivo REAL de esta version, no solo la
*! opcion en si): si se pasa cruce() y ADEMAS subpop(), tsvy valida que
*! la variable de cruce() no aparezca como palabra completa dentro de la
*! expresion de subpop() -- y corta con error explicando el mecanismo si
*! la encuentra. Mismo chequeo para cada variable de caida(). Esto
*! previene en el momento, no despues de exportar mal, el error exacto
*! que motivo esta version: mover el problema de [if]+cruce() a
*! subpop()+cruce() sin la opcion de arriba habria sido igual de fragil.
*!
*! Implementacion en el camino conjunto (boot()==0, el de produccion):
*!   - `touse' sigue viniendo SOLO de [if] (sin cambio) -- subpop() NUNCA
*!     se mezcla dentro de `touse', ni se usa para filtrar `combo' ni las
*!     llamadas svy:. Si se mezclara, subpop() perderia su proposito
*!     entero (volveria a excluir UPM del diseno antes de que Stata
*!     pudiera contarlas).
*!   - `combo' se sigue armando "if `touse'" (universo de [if], como
*!     siempre) -- categorias de `combo' enteramente fuera de la
*!     subpoblacion simplemente no reciben columna real en e(b)/coleq(),
*!     el MISMO mecanismo que v1.13 ya construyo para categorias con
*!     varianza degenerada (fila vacia puntual, sin correr de posicion
*!     las demas) -- subpop() no necesito ningun cambio ahi.
*!   - Las 4 ramas de stat() (mean/total/ratio/proportion) anteponen
*!     "svy, subpop(if `subpop')" en vez de "svy" cuando se paso
*!     subpop() -- una sola linea nueva (`svyprefix') reutilizada por
*!     las 4, sin duplicar codigo.
*!   - La rama de stat(proportion) (identificacion de filas por ecuacion
*!     de `level') pasa de "exigir exactamente k_total columnas o exit
*!     498" a mapear cada categoria de `combo' por el NOMBRE de su
*!     columna DENTRO de la ecuacion encontrada (mismo patron v1.13 que
*!     ya usan mean/total/ratio) -- necesario porque subpop() puede
*!     dejar categorias enteras sin columna en CUALQUIER ecuacion, un
*!     caso que el "exit 498" de antes de esta version no distinguia de
*!     un error real de configuracion. Con salvaguarda: si el mapeo por
*!     nombre no encuentra NINGUNA columna (indicio de que el formato de
*!     nombre de columna no es el esperado), cae de vuelta al error
*!     original en vez de seguir con datos posiblemente desalineados.
*!
*! LIMITACION: subpop() no esta soportado con boot()>0 (camino viejo,
*! que llama svylet por bloque via [if] filtrado -- no expone su propio
*! subpop() nativo). tsvy corta con error claro si se combinan, en vez
*! de ignorar subpop() en silencio. boot()>0 no se usa en produccion
*! actual (ver nota v1.9), asi que esto no bloquea ningun caso real hoy.
*!
*! FIX INCIDENTAL (encontrado al implementar subpop(), pero preexistente
*! desde v1.13, no exclusivo de subpop()): los locales "mapa_col_<valor>"
*! que ubican cada categoria de `combo' por nombre de columna NO se
*! limpiaban entre iteraciones de `foreach a of local caida' -- como
*! `combo' es un tempvar nuevo cada `a' (group() numera denso 1..k_total
*! desde 1 siempre), un "mapa_col_3" de un `a' anterior con OTRO k_total
*! podia quedar pegado y leerse por error si en el `a' actual la
*! categoria "3" no tenia columna real (nunca se sobreescribia, solo se
*! agregaban valores nuevos). subpop() vuelve esto mas facil de disparar
*! (aumenta cuantas categorias quedan sin columna), asi que se corrige
*! ahora: se registra que nombres se mapearon en cada iteracion
*! (`mapa_col_nombres_prev') y se limpian explicitamente antes de volver
*! a construir el mapa en la iteracion siguiente -- en ambas ramas
*! (proportion y el resto). Sin cambio de comportamiento cuando `combo'
*! nunca pierde una categoria entre un `a' y el siguiente (caso normal
*! hasta ahora).
*!
*! ADVERTENCIA HONESTA: esta version NO se pudo correr contra Stata real
*! (sin Stata disponible en el entorno de esta sesion) -- el diseno del
*! prefijo "svy, subpop(if ...): STAT ..., over(combo)" SI esta validado
*! contra Stata real, pero corrido a mano (ver los dos .do de simulacion
*! citados arriba, corridos por el usuario en su propia instalacion), no
*! integrado dentro de tsvy.ado como esta ahora. Antes de produccion,
*! correr pruebas_svylet_tsvy.do (o al menos un caso real con subpop())
*! y comparar el resultado contra "svy, subpop(if ...): STAT ...,
*! over(caida cruce ANIO_)" corrido a mano sobre el mismo dataset --
*! mismo criterio de validacion que exige el resto de este changelog.
*!
*! v1.14 -- agrega la columna VARNAME al frame acumulador: el nombre
*! (string) de la variable de analisis pasada en varname() para esta
*! llamada, la misma en TODAS las filas que produce esa llamada. Motivo:
*! `var' viene fijo en 1 en tsvy (a diferencia de tabsvy, donde identifica
*! una categoria) -- es solo un remanente de compatibilidad de columnas
*! con el frame de tabsvy, nunca distinguio nada en tsvy. Un pipeline real
*! llama tsvy una vez por variable hacia el MISMO frame() (ver Ejemplo 3
*! en tsvy.sthlp/tsvy_es.sthlp) -- hasta ahora, una vez apiladas todas las
*! llamadas, nada en el frame decia de que variable salio cada bloque de
*! filas, salvo llevar la cuenta aparte de en que orden se corrio el loop
*! (ej. contando N_filas/N_anios por bloque). VARNAME cierra ese hueco
*! directamente en el frame, sin depender del orden del loop ni de
*! postprocesar por conteo de filas. Se genera en los tres lugares donde
*! se arma una fila del frame acumulador (bloque real via el camino
*! conjunto, bloque real via el camino viejo con boot()>0, y la fila
*! "vacia" de _tsvy_fila_vacia agregada por v1.10 para combinaciones sin
*! datos) -- str32 porque un nombre de variable Stata no supera los 32
*! caracteres. Sin cambio de comportamiento en ninguna otra columna.
*!
*! v1.13 -- FIX real (v1.12 solo diagnosticaba) del bug de SEDE_POS
*! confirmado con datos de produccion: el "svy: `stat' ..., over(combo)"
*! conjunto puede excluir de e(b) alguna categoria puntual de `combo'
*! (varianza no definida/muestra degenerada), sin aviso -- confirmado
*! con un caso real (100 de 340 categorias, oficina x usos x anio):
*! colsof(e(b))=339 pero `combo' tenia 340 categorias segun levelsof.
*! Como v1.4-v1.11 asumian columna=categoria por POSICION, esa UNA
*! categoria faltante corria de posicion TODAS las columnas siguientes
*! -- confirmado comparando contra "collapse (sum) ..., by(usos)" sobre
*! los datos crudos Y contra la tabla que el propio "svy:" imprime
*! (nombres de columna literalmente "... 99 101 102 ..." saltando el
*! 100): cada bloque posterior al hueco quedaba con estimaciones REALES
*! pero de la categoria vecina (la primera fila de cada bloque
*! resultaba ser el dato real del anio ANTERIOR, y la ultima fila
*! "tomaba prestado" el primer dato del bloque siguiente).
*!
*! Fix real: en vez de asumir columna=categoria, se arma un mapa
*! POR NOMBRE de columna (colnames de e(b) trae literalmente el valor
*! de la categoria de `combo', confirmado con datos reales) para ubicar
*! la columna real de cada categoria -- si una categoria no tiene
*! columna, b_sel_all/V_sel_all quedan con esa fila en missing en vez
*! de con el dato de la categoria vecina. Dentro de cada bloque
*! (`a'=`cval' [`cruce'=`sval']), se detecta si alguna de sus posiciones
*! quedo en missing y se recorta a las posiciones con dato real ANTES
*! de llamar a tsvy_core (que sigue recibiendo un vector totalmente
*! definido, igual que siempre) -- el/los anio(s) sin dato real quedan
*! como fila vacia PUNTUAL de ESE anio en el frame (no de todo el
*! bloque), preservando la garantia de v1.10 (una fila por cada
*! (caida,cruce,anio) que "deberia" existir, sin correr de posicion las
*! demas). Si despues del recorte quedan menos de 2 anios con dato real,
*! el bloque completo se trata como insuficiente (mismo camino que ya
*! existia para bloques con <2 anios en los datos crudos).
*!
*! Cuando NO falta ninguna categoria (caso normal, NACIONAL/REGION y la
*! gran mayoria de SEDE_POS), el mapa por nombre coincide exactamente
*! con la posicion asumida de siempre -- sin cambio de comportamiento
*! ni de resultados respecto a versiones anteriores.
*!
*! El chequeo de v1.12 (colsof(e(b)) vs k_total) se mantiene como aviso
*! informativo (ya no corta con error) -- solo aplica fuera de
*! stat(proportion), donde colsof(e(b)) no es comparable contra k_total
*! (ver nota junto a la definicion de k_total en el cuerpo del programa).
*!
*! v1.12 -- DIAGNOSTICO: bug real de produccion en SEDE_POS (28 oficinas
*! x 17 usos x 4 anios = ~1900 categorias en el over(combo) conjunto).
*! Desde v1.4, el camino conjunto (boot()==0) arma `b_sel_all'/`V_sel_all'
*! asumiendo SIN VERIFICAR que la columna `i' de e(b) es la categoria
*! combo==`i' (simple correspondencia posicional). Confirmado con datos
*! reales (comparando contra "collapse (sum) ..., by(usos)" directo
*! sobre los datos crudos, y contra la tabla que el propio "svy: total
*! ..., over(combo)" imprime) que en corridas con MUCHAS categorias, esa
*! correspondencia se rompe: aparecen "saltos" en la tabla impresa por
*! svy: (ej. category 100 ausente, "99: ...=99" seguido de "101:
*! ...=101") -- e(b) trae MENOS columnas que categorias distintas tiene
*! `combo' segun levelsof. Como el codigo asumia columna=categoria a
*! ciegas, esa UNA categoria faltante corria de posicion TODAS las
*! columnas siguientes: cada bloque quedaba con una estimacion REAL,
*! pero de la categoria vecina -- sin ningun error, silencioso (los
*! bloques mas alejados en la secuencia de categorias acumulan mas
*! corrimiento, consistente con lo visto: oficinas SEDE_POS bajas casi
*! sin corrimiento, oficinas mas avanzadas en la secuencia con varios
*! anios corridos).
*!
*! Este fix agrega el chequeo defensivo que faltaba: compara colsof(e(b))
*! contra `k_total' (categorias distintas de `combo' segun levelsof) ANTES
*! de armar `b_sel_all', y corta con error duro (en vez de seguir con
*! datos desalineados) si no coinciden -- reporta ademas los nombres de
*! columna de e(b) para poder disenar, en la proxima version, el
*! reemplazo real: mapear cada columna a su categoria de `combo' por
*! IDENTIDAD (nombre de columna), no por posicion asumida.
*!
*! v1.11 -- FIX en _tsvy_fila_vacia (v1.10): "gen byte ANIO = `anio'"
*! en un solo paso dejaba ANIO en missing para toda fila vacia (rompia
*! el "reshape wide" siguiente con "variable ANIO contains missing
*! values", r(498)) -- un anio como 2023 no entra en el rango de byte
*! (-127..100), y "generate" con tipo declarado literalmente en el
*! comando NO amplia el tipo como si lo hace "replace" sobre una
*! variable ya existente. Reemplazado por el mismo patron de dos pasos
*! ("gen byte ANIO = ." + "replace ANIO = `anio'") que ya usa el resto
*! del archivo para las filas reales.
*!
*! v1.10 -- FIX de integridad posicional del frame acumulador (camino
*! conjunto, boot()==0): hasta v1.9, una combinacion (caida,cruce) sin
*! datos suficientes para estimar (0 observaciones, o menos de 2 anios)
*! se saltaba SIN dejar fila en el frame -- silenciosamente, sin mas
*! rastro que un "di as err" en pantalla. Encontrado en produccion real
*! (ENA, Dom_Iguales): la region Selva no tiene NINGUNA observacion de
*! usos=6 ("superficie en descanso"); al hacer reshape wide + export
*! excel a un rango CONTIGUO de la plantilla, la fila faltante corrio
*! TODAS las filas siguientes de Selva una posicion hacia arriba en el
*! Excel exportado -- confirmado visualmente comparando contra la
*! plantilla (fila etiquetada "usos=7" mostrando el valor real de
*! usos=8, y asi sucesivamente). Este bug no es exclusivo de
*! Dom_Iguales: afecta a CUALQUIER consumidor que asuma que el frame
*! acumulador trae una fila por cada combinacion (caida,cruce,anio) que
*! "deberia" existir, sin huecos -- exactamente lo que un reshape wide +
*! export a celdas fijas necesita.
*!
*! FIX: el universo de valores de cruce() se calcula UNA sola vez por
*! variable de caida() (union de todos los vistos en el `touse' completo,
*! no per-cval como hasta v1.9), y el loop interno pasa a recorrer ESE
*! universo completo en vez de solo los valores presentes en cada cval.
*! Cuando una combinacion puntual no tiene observaciones (r(N)==0 en el
*! summarize de corte) o tiene menos de 2 anios, en vez de solo saltarla
*! ahora se le agrega una fila "vacia" (nuevo subprograma
*! _tsvy_fila_vacia: NIVEL/CAIDA/CRUCE/var poblados, TODO lo demas en
*! missing, ANIO fijo en el primer anio de years() solo para que
*! "reshape wide" tenga con que anclar la fila). Asi el frame SIEMPRE
*! tiene exactamente una fila por cada (caida,cruce) que aparece en
*! ALGUNA parte de los datos -- position-safe para exportar a un rango
*! contiguo sin tener que revalidar la cuenta de filas cada vez.
*!
*! Aplica solo al camino conjunto (boot()==0, el caso de produccion);
*! el camino viejo (boot()>0) sigue sin agregar fila cuando un bloque se
*! salta -- no se toco en este fix, sigue siendo el mecanismo distinto
*! de siempre (bootstrap via svylet por bloque).
*!
*! v1.9 -- FIX de fondo (no solo de nombre) para cruce(): hasta v1.8,
*! CUALQUIER llamada con cruce() -- sin importar boot() -- caia al
*! camino VIEJO (filtra "if caida==cval & cruce==sval" y corre
*! "over(ANIO_)" aparte, por bloque). Ese es EXACTAMENTE el patron que
*! v1.4 ya habia identificado como estadisticamente incorrecto para
*! caida() (error estandar sistematicamente mas chico cuando el filtro
*! deja algun estrato sin observaciones de ese bloque) -- pero v1.4 solo
*! corrigio el caso caida() x ANIO_ (dos variables), nunca extendio el
*! fix a un tercer cruce. Confirmado en produccion real (ENA, superficie
*! por tipo de uso de la tierra): comparando "svylet ... if usos==k,
*! over(ANIO_)" (via cruce(usos)) contra "svy: total ..., over(usos
*! ANIO_)" corrido a mano, el error estandar de cruce() salia
*! sistematicamente MAS CHICO -- hasta 35% en categorias chicas/raras
*! (ver PR/commit que agrego esta nota para el detalle celda por celda).
*!
*! La correccion generaliza el mismo mecanismo que v1.4 ya usa para
*! caida() (un unico "svy: STAT ..., over(combo)" conjunto, sobre un
*! `combo' armado con egen group(), y despues un corte de e(b)/e(V) por
*! POSICION -- nunca un re-filtrado ni una segunda llamada a svy:) a
*! TRES variables en vez de dos: cuando se pasa cruce(), `combo' ahora
*! agrupa group(`a' `cruce' ANIO_) en vez de group(`a' ANIO_), y el loop
*! de corte de bloques se anida un nivel mas (cval de caida(), despues
*! sval de cruce() DENTRO de ese cval) sobre el MISMO combo/e(b)/e(V) ya
*! capturado -- nunca se vuelve a invocar "svy:" por bloque. Como
*! egen group() ordena ascendente por `a', despues por `cruce', despues
*! por ANIO_, cada (cval,sval) sigue siendo un rango CONTIGUO de columnas
*! de `combo' (misma garantia que ya explota v1.4 para caida() sola),
*! asi que el mismo patron summarize-min/max de v1.4 sigue funcionando
*! sin cambios, solo con una condicion extra en el filtro.
*!
*! Este diseno (una sola llamada svy: con TODAS las variables de cruce
*! juntas en over(), despues cortar submatrices de e(b)/e(V) por
*! posicion en vez de re-filtrar y re-estimar) es el mismo principio que
*! usa parmby_tdiff.ado (Talavera Cuya 2026, companero de este repo para
*! pruebas t/F sobre un unico over() ya corrido) -- confirmado como
*! practica correcta al revisar ese codigo. La diferencia de
*! implementacion es que parmby_tdiff ubica cada bloque con aritmetica
*! posicional fija (mod/ceil, asumiendo un cruce RECTANGULAR completo:
*! e(b) debe ser exactamente divisible entre n_anios, documentado como
*! requisito en su propio help) mientras que tsvy sigue usando
*! egen group() + summarize (min/max) para ubicar cada bloque -- mas
*! robusto ante combinaciones caida()xcruce() con datos faltantes o
*! celdas vacias (el caso real de REGION x tipo de uso de la tierra en
*! produccion, donde no todo departamento/region tiene UAs con todo tipo
*! de uso en todo anio), sin exigir un cruce rectangular perfecto.
*!
*! boot()>0 SIGUE usando el camino viejo (filtrar + over(ANIO_) por
*! bloque, ahora solo por ese motivo, nunca por cruce() en si) --
*! bootstrap reconstruye replicas de remuestreo por bloque via svylet,
*! un mecanismo distinto que no se toco en este fix; ver la nota junto a
*! "Camino VIEJO" en el cuerpo del programa.
*!
*! Sin cambio de esquema de columnas en el frame acumulador (CRUCE sigue
*! siendo la misma columna agregada en v1.8); el cambio es puramente al
*! ERROR_ST/CV/LIM_INF/LIM_SUP/F_WALD/P_WALD/GRUPO que produce una
*! llamada con cruce() y boot()==0 (el caso de produccion), que ahora
*! coincide exacto con el calculo de referencia (confirmado celda por
*! celda contra "svy: total ..., over(caida cruce ANIO_)" corrido a
*! mano, ver PR/commit).
*!
*! v1.8 -- Renombra la opcion SEXOVAR() a CRUCE(), y la columna SEXO del
*! frame acumulador a CRUCE (BREAKING CHANGE de nombre, sin cambio de
*! comportamiento). Motivo: sexovar() nunca estuvo limitada a sexo -- es
*! cualquier variable de cruce adicional dentro de cada caida() (grupo
*! etario, tipo de actividad, tipo de uso de la tierra, lo que necesite
*! la tabla -- ver ejemplo_uso_tsvy.do, donde ya se usaba con un grupo
*! de precio como sustituto de una particion demografica real). El
*! nombre SEXOVAR/SEXO sugeria una restriccion que el codigo nunca tuvo,
*! y llevaba a doble lectura en tablas que cruzan por algo que no es
*! sexo (ej. superficie por tipo de uso de la tierra). Quien tenga
*! do-files existentes con `sexovar(...)` o que lean la columna `SEXO`
*! del frame acumulador debe actualizarlos a `cruce(...)`/`CRUCE` --
*! no hay alias de compatibilidad hacia atras.
*!
*! v1.7 -- FIX en tsvy_core() (replicado de svylet_core() en svylet.ado
*! v1.6, ver ese archivo para el detalle completo): el F omnibus quedaba
*! en blanco apenas UNA de las k categorias de over() tenia varianza
*! degenerada (proporcion exactamente 0 o 1), aunque las demas tuvieran
*! variables perfectamente calculables -- confirmado en tabulados de
*! produccion reales (tipo_actividad/Pecuaria: filas con 4/4 anios con
*! Estimacion, F en blanco porque 1-3 de esos anios eran exactamente
*! 0%). Ahora se calcula sobre el subconjunto de categorias con varianza
*! definida (minimo 2). Identico a v1.6 cuando no hay degeneradas.
*!
*! v1.6 -- REVERTIDO (mismo dia): se probo cambiar "version 14" a
*! "version 16" en las dos declaraciones del programa, con la idea de
*! que "frame create"/"frame `frame': ..." (Stata 16+) necesitaba ese
*! ajuste. Esa idea era INCORRECTA y se revirtio antes de mandar el
*! paquete a revision: "version 14" NO bloquea comandos mas nuevos como
*! frame (el motivo real por el que se requiere Stata 16 es que el
*! EJECUTABLE de Stata 14/15 no trae el comando frame en absoluto, sin
*! importar que "version" declare el programa) -- eso ya se confirmo
*! funcionando en produccion real con "version 14" + frames durante toda
*! esta sesion. Peor: "version 14" SI cambia el formato de nombres de
*! ecuacion que da "svy: proportion ..., over()" (por-categoria bajo
*! version 14 vs "@"-combinado nativo en Stata 19+, CONFIRMADO en Stata
*! real -- ver ejemplo_svylet.do, ejemplo 10). El camino conjunto de
*! tsvy (over() unico, boot()==0 & cruce()=="", lineas ~415-424 mas
*! abajo) llama "svy: proportion ..., over(combo)" DIRECTO y despues
*! empareja columnas via coleq() contra el label/ordinal/codigo de
*! level() -- exactamente la logica que depende del formato por-
*! categoria. Cambiar a "version 16" habria roto silenciosamente
*! "tsvy, stat(proportion)" en el camino por defecto (coleq() ya no
*! encuentra las `k_total' columnas esperadas, exit 498). Revertido a
*! "version 14" en ambos lugares -- sin cambio de comportamiento neto
*! respecto a v1.5.
*!
*! v1.5 -- agrega refyear(): columnas P_VS_REF/SIG_VS_REF, comparando
*! CADA anio contra un anio BASE fijo (ej. refyear(2026)), Bonferroni
*! sobre k-1 comparaciones -- una FAMILIA DE HIPOTESIS DISTINTA de la
*! que responde GRUPO/F_WALD/P_WALD (que compara TODOS los pares entre
*! si, Bonferroni sobre k(k-1)/2). Encontrado al comparar las letras
*! GRUPO de tsvy contra un script de referencia que solo comparaba cada
*! anio contra 2026 (Bonferroni sobre 3 comparaciones, no sobre 6 como
*! el CLD): ~17% de las 81 comparaciones "anio vs 2026" derivadas de
*! GRUPO no coincidian con el resultado directo del script de
*! referencia -- NINGUNA de las dos salidas estaba mal, son PREGUNTAS
*! DISTINTAS (ver svylet.sthlp, seccion Remarks, para la justificacion
*! completa y las referencias: Dunn 1961; Dunnett 1955, 1964; Hsu 1996).
*! refyear() deja elegir la pregunta "vs un anio base" ademas de (no en
*! reemplazo de) GRUPO/CLD. Mismo criterio de autosuficiencia que v1.4
*! (FIX 2/FIX 3): el camino nuevo arma el contraste con llamadas mata:
*! de una linea (vectorizadas), sin definir una funcion mata nueva
*! dentro de "program define tsvy"; el camino viejo pasa ref() a
*! svylet.ado (que si define su propia funcion mata, a nivel de
*! archivo, para esto -- ver svylet.ado v1.4).
*!
*! v1.4 -- FIX: el error estandar de niveles de caida() que UNEN varias
*! strata del diseno original (tipico de REGION, que agrupa muchos
*! departamentos/DOMINIO) no coincidia con el que da correr
*! "svy: STAT ..., over(caida_var ANIO_)" a mano. Hasta v1.3, tsvy
*! filtraba PRIMERO ("if caida_var==valor") y recien ahi corria
*! "over(ANIO_)" (via svylet) -- en teoria equivalente para estimacion
*! de subpoblaciones, pero en datos reales de produccion (ENA) la
*! estimacion puntual (ESTIMA) coincidia exacto contra el calculo de
*! referencia, mientras que el error estandar de REGION quedaba
*! sistematicamente MAS CHICO (5%-20% segun anio/region); NACIONAL (1
*! sola categoria) y NOMBREDD_ (cada categoria ~ 1 sola strata) SI
*! coincidian exacto. Confirmado celda por celda contra dos .xlsx de
*! salida (uno del pipeline via tsvy, otro de "svy linearized: total
*! ..., over(REGION ANIO_)" corrido a mano sobre el mismo dataset/
*! diseno) -- ver PR/commit que agrego esta nota para el detalle
*! completo.
*!
*! Ahora, cuando boot()==0 y no se paso cruce() (el caso de
*! produccion actual), tsvy corre UN SOLO "svy: STAT ..., over(caida_var
*! ANIO_)" conjunto por cada variable de caida() -- el MISMO comando
*! que el calculo de referencia -- y extrae despues, para cada valor de
*! caida_var, el bloque de columnas de e(b)/e(V) que le corresponde
*! (bloque contiguo, gracias a que el agrupamiento auxiliar se arma con
*! "egen group(caida_var ANIO_)", que ordena ascendente por caida_var y
*! despues por ANIO_ dentro de cada caida_var). El test F/CLD se sigue
*! corriendo por separado DENTRO de cada bloque (anios de un mismo
*! valor de caida_var entre si, nunca contra otro valor de caida_var) --
*! ver el comentario junto al "foreach a of local caida" en el cuerpo
*! del programa. boot()>0 y cruce() TODAVIA usan el camino viejo
*! (if + over(ANIO_) por separado) -- ninguno de los dos aparece en el
*! uso de produccion actual, y extenderles el camino nuevo sin poder
*! correr Stata para validarlo ahora mismo es mas riesgo del que vale
*! la pena por ahora.
*!
*! FIX 2 (mismo v1.4, encontrado al probar el FIX de arriba en
*! produccion real): el camino nuevo NO puede depender de que
*! svylet.ado este completamente cargado -- probado que una llamada
*! muda al comando svylet (sin argumentos, solo para forzar la carga)
*! NO alcanza para que Stata registre _svylet_seleccionar ni compile
*! svylet_core(): fallaba con "command _svylet_seleccionar is
*! unrecognized" en cuanto el camino nuevo corria SOLO (boot()==0, sin
*! cruce(), osea la corrida tipica: NINGUN bloque llega a invocar el
*! comando svylet como tal). Por eso el camino nuevo ahora es
*! autosuficiente: define su propia copia de svylet_core() (llamada
*! tsvy_core(), identica) y hace la seleccion de filas de e(b)/e(V) que
*! antes hacia _svylet_seleccionar() en linea, sin llamar a ningun
*! programa de otro archivo .ado.
*!
*! FIX 3 (mismo v1.4, encontrado al probar el FIX 2 en produccion real):
*! tsvy_core() no se puede definir DENTRO de "program define tsvy ...
*! end" -- Mata solo compila una definicion de funcion como bloque
*! mata: de nivel de archivo, nunca anidada en el cuerpo de un programa
*! Stata (fallaba al cargar el .ado con r(9611), con o sin "quietly"
*! alrededor). tsvy_core() vive, igual que svylet_core() en svylet.ado,
*! en su propio bloque mata: DESPUES del "end" que cierra el programa,
*! al final de este archivo.
*!
*! v1.3 -- Renombrado de tabsvylet a tsvy (mismo comando, sin cambios de
*! comportamiento) -- nombre mas compacto, mantiene la referencia a "tab"
*! del patron de tabsvy/tabsvyexport que sigue. tabsvylet.ado/.sthlp ya
*! no existen en el repo; el reemplazo es tsvy.ado/tsvy.sthlp/tsvy_es.sthlp.
*!
*! v1.2 -- FIX: if `if' NUNCA funcionaba (bug desde v1.0). El if-exp que
*! deja syntax [if] en el macro `if' YA incluye la palabra "if" (patron
*! estandar "cmd `if' `in'"); el codigo envolvia ese `if' de nuevo dentro
*! de una expresion booleana propia (filtro_base/subset), dejando un "if"
*! suelto en medio de la expresion -- fallaba con rc=111 en TODA
*! combinacion caida()/especie en cuanto se pasaba un if() (incluso el
*! del propio ejemplo de USO en este mismo encabezado, linea de abajo).
*! Reemplazado por marksample touse -- ver el comentario junto a
*! "marksample touse, novarlist" en el cuerpo del programa.
*!
*! Companero de tabsvy/tabsvyexport (github.com/atalaveracuya/tabsvy):
*! misma idea (un loop sobre niveles de agregacion -- NACIONAL/REGION/
*! NOMBREDD_ -- que acumula filas en un frame, listas para reshape wide y
*! exportar a Excel), pero en vez de "svy + parmby" (que solo da la tabla
*! de puntos), llama a svylet por cada combinacion (nivel de agregacion x
*! valor x [cruce]), que YA corre "svy: mean/total/proportion/ratio"
*! internamente -- asi que la tabla de puntos Y el test de comparacion
*! entre anios (F omnibus + Bonferroni + letras CLD) salen de la MISMA
*! pasada de estimacion, sin correr "svy:" dos veces y sin pegar los
*! resultados por posicion en matrices sueltas.
*!
*! v1.1 -- agrega denominator(varname), passthrough directo a
*! svylet(stat(ratio)). Requerido cuando stat(ratio); ignorado (con
*! aviso) en cualquier otro stat().
*!
*! Este comando NO modifica ni depende del codigo interno de tabsvy.ado
*! -- vive en el repo de svylet porque svylet es el motor que necesita.
*! Si mas adelante conviene fusionarlo dentro de tabsvy como un
*! ENGINE(svylet), este archivo es el punto de partida para eso.
*!
*! Reemplaza, para el caso "necesito tabla de puntos POR ANIO y ademas
*! saber si los anios son significativamente distintos entre si", el
*! patron manual que se repetia (matrices AC/AR, loops while, locales
*! indexados por posicion "F_r`r'_sp`o'", pegado por "in `fila'") en
*! especies_varestruc_svylet.do -- ver ejemplo_uso_tsvy.do para el
*! mismo cuadro de especies pecuarias reducido de ~300 lineas a un puñado
*! de llamadas.
*!
*! LIMITACIONES respecto a tabsvy (deliberadas, por ahora):
*!   - Una sola variable de analisis por llamada (igual que svylet: no
*!     acepta varlist). Para varias variables (ej. 13 especies), llamar
*!     tsvy una vez por variable, como en el ejemplo.
*!   - No tiene keepcat()/tipo() (el loop de bloques tematicos de tabsvy).
*!     Si tu caso los necesita, seguis usando tabsvy (motor svy+parmby)
*!     para esos cuadros -- tsvy es especificamente para cuadros que
*!     SI necesitan el test entre anios.
*!   - Cada combinacion (nivel de agregacion x valor x [cruce]) necesita
*!     AL MENOS 2 anios presentes en los datos para poder correr el test
*!     (requisito de svylet, k>=2). Si un dominio tiene un solo anio de
*!     datos, esa combinacion se salta con un aviso (no hay nada que
*!     comparar ahi) -- a diferencia de tabsvy, que si puede tabular un
*!     dominio con un solo anio (no necesita comparar nada).
*!
*! USO (mismo espiritu que tabsvy -- declarar el estrato/diseno y
*! NACIONAL=1 antes, como siempre; una llamada por variable, un loop
*! afuera si hay varias):
*!
*!     svyset CONGLO_ANIO, strata(ESTRATO_ANIO) weight(FACTORFINAL) ///
*!         vce(linearized) singleunit(certainty)
*!
*!     tsvy if pecuario==1 & cuenta_ua==1 & omision_esp==0,       ///
*!         varname(P404A_n_UA_1) stat(total)                           ///
*!         years(2023 2024 2025 2026) frame(F1) replace
*!
*! (para la especie 2, misma llamada con varname(P404A_n_UA_2) y SIN
*! `replace`, para seguir acumulando en el mismo frame F1)
*!
*! USO CON UNA DIMENSION DE CRUCE ADICIONAL (agrega esa variable al
*! loop, y una columna CRUCE al frame acumulador -- por ejemplo, sexo,
*! pero puede ser cualquier variable de cruce: grupo etario, tipo de
*! actividad, lo que necesite la tabla):
*!
*!     tsvy if omision==0, varname(indicador) stat(proportion) ///
*!         level(1) years(2023 2024 2025 2026) cruce(sexo) frame(F2) replace
*!
*! USO CON subpop() (v1.15, RECOMENDADO por sobre [if] cuando se cruza
*! por una variable con cruce()): subpop() define el UNIVERSO de
*! analisis (misma restriccion para todos los grupos de cruce()) sin
*! perder UPM del diseno para el calculo de varianza -- a diferencia de
*! meter esa misma condicion en [if], que SI las pierde si algun grupo de
*! cruce() queda sin observaciones en algun estrato. Nunca poner la
*! variable de cruce() (ni de nivel()) dentro de subpop() -- tsvy corta
*! con error si la encuentra ahi (ver nota v1.15 de cabecera):
*!
*!     tsvy, varname(P404A_n_UA_1) stat(total) years(2023 2024 2025 2026) ///
*!         cruce(sexo) subpop(cuenta_ua==1 & omision_sexo==0) frame(F1) replace
*!
*! (equivalente exacto, validado con simulacion Monte Carlo de 1,000
*! replicas sobre datos reales -- ver simulacion_stata_if_vs_subpop_
*! universo.do -- a "tsvy if cuenta_ua==1 & omision_sexo==0, ...
*! cruce(sexo) ..."; la diferencia es que subpop() es a prueba de que
*! alguien mas tarde agregue "sexo==1" al [if] por error, como paso en
*! produccion real antes de este fix)
*!
*! USO CON mmd() (v1.16, rediseñado en v1.17; OPCIONAL, apagado por
*! default -- ver nota de cabecera sobre el costo de bootstrap por
*! bloque antes de prenderlo en una corrida con muchas categorias de
*! nivel()/cruce()). Requiere ssc install mmd_2s, mmdyears(anio1 anio2)
*! (los 2 anios EXACTOS de years() a comparar -- ya NO se asume refyear()
*! vs el ultimo anio, ver nota v1.17 de cabecera) y mmdweight() (variable
*! de peso PARA mmd_2s, no necesariamente la misma de svyset -- explicito,
*! tsvy nunca adivina):
*!
*!     tsvy, varname(super_ha) stat(total) years(2023 2024 2025 2026) ///
*!         subpop(cuenta_ua==1) mmd mmdyears(2025 2026) ///
*!         mmdweight(F_PRODUCTOR) mmdboot(200) mmdreps(20) mmdseed(12345) ///
*!         frame(F1) replace
*!
*! (compara, por cada bloque NIVEL x CATEGORIA, la DISTRIBUCION de super_ha
*! entre 2025 y 2026, tal cual se pidio en mmdyears() -- P_MMD/EFFECT_MMD
*! en el frame acumulador, constantes dentro del bloque igual que
*! F_WALD/P_WALD. mmdyears() no tiene por que coincidir con refyear(): son
*! independientes -- se puede usar mmd sin refyear() en absoluto)
*!
*! El frame que deja tsvy trae: NIVEL CATEGORIA [CRUCE] var VARNAME ANIO
*! ESTIMA ERROR_ST CV LIM_INF LIM_SUP N_SIN_PON N_PONDERA REF_ F_WALD
*! P_WALD GRUPO P_MMD EFFECT_MMD -- mismo esquema de columnas que deja
*! tabsvy (compatible con tabsvyexport para el bloque ESTIMA/REF_), mas
*! VARNAME (v1.14 -- el nombre, string, de la variable pasada en
*! varname() en esta llamada, constante en TODAS las filas de esta
*! llamada -- lo que distingue, en un frame que acumula varias llamadas
*! de tsvy, que bloque de filas vino de que variable; `var' en cambio
*! queda fijo en 1, solo por compatibilidad de columnas con tabsvy) y
*! F_WALD/P_WALD (constantes dentro de cada bloque nivel-valor-[cruce],
*! repetidas por anio) y GRUPO (la letra CLD de ESE anio dentro de su
*! bloque). Si se paso refyear(), ademas trae P_VS_REF/SIG_VS_REF
*! (Bonferroni de ESE anio contra el anio base, k-1 comparaciones -- ver
*! Remarks en svylet.sthlp sobre la diferencia con GRUPO/CLD); si no se
*! paso, esas dos columnas quedan en missing/vacias. P_MMD/EFFECT_MMD
*! (v1.16) siguen el mismo criterio: missing si no se paso mmd, o si el
*! bloque puntual no lo pudo calcular (ver nota de cabecera v1.16). Para
*! exportar TODAS las columnas (como hace
*! especies_varestruc_svylet.do a mano), el patron es:
*!
*!     frame F1: reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV    ///
*!         N_PONDERA N_SIN_PON GRUPO P_VS_REF SIG_VS_REF,                ///
*!         i(NIVEL CATEGORIA var VARNAME F_WALD P_WALD P_MMD EFFECT_MMD) j(ANIO)
*!
*! (F_WALD/P_WALD/P_MMD/EFFECT_MMD quedan en i() porque son constantes
*! dentro del grupo -- no varian por anio, no hace falta que el reshape
*! las repita sufijadas)
*!
*! Requiere: svylet (este mismo repo) y frameappend (SSC) -- la misma
*! dependencia que ya pide tabsvy para acumular filas sin postfile/tempfile.
*!
*! Author: Andres Talavera Cuya. Afiliacion indicada solo para fines de
*! identificacion -- este software no es un producto oficial de INEI y
*! INEI no es responsable por el. Distribuido bajo GNU GPL v3
*! (https://www.gnu.org/licenses/gpl-3.0.txt).

capture program drop tsvy
program define tsvy
    version 14
    syntax [if], VARNAME(string) YEARS(numlist ascending) STAT(string) ///
        [                                                              ///
        NIVEL(string)         /// niveles de agregacion (columna matriz). Def: "NACIONAL REGION NOMBREDD_"
        CRUCE(string)         /// variable extra de desagregacion (ej. sexo). Opcional
        SUBpop(string)        /// v1.15 -- universo de analisis, igual que subpop() nativo. Ver help
        LEVEL(integer 1)      /// solo aplica a stat(proportion) -- ver help svylet
        DENOMINATOR(string)   /// requerido si stat(ratio) -- ver help svylet
        ALPHA(real 0.05)      /// nivel de significancia del test (svylet)
        BOOT(integer 0)       /// replicas bootstrap del F omnibus (svylet), 0 = solo analitico
        BSEED(integer -1)     ///
        EXPECTCATS(numlist)   /// categorias que DEBERIA tener VARNAME -- valida antes de estimar
        FRAME(name)           /// frame acumulador. Def: ACUM_ALL
        THRESHOLD(real 15)    /// umbral de CV(%) para marcar "a/"
        REFYEAR(string)       /// anio base para P_VS_REF/SIG_VS_REF (ej. 2026) -- ver help
        REPLACE                /// si se especifica, reinicia el frame acumulador
        MMD                   /// v1.16 -- activa el test mmd_2s (distribucional) por bloque. Ver help
        MMDYEARS(numlist integer min=2 max=2) /// v1.17 -- los 2 anios EXACTOS (de years()) a comparar. Requerido si mmd
        MMDWEIGHT(string)     /// variable de peso PARA mmd_2s (aweight) -- requerido si mmd
        MMDBOOT(integer 200)  /// boot() de mmd_2s
        MMDREPS(integer 20)   /// reps() de mmd_2s
        MMDSEED(integer 12345) ///
        ]

    * ---------------------------------------------------------------
    * v1.2 -- if/in via marksample, no manipulando el texto crudo de
    * `if' a mano. Bug real encontrado en produccion: el macro `if' que
    * deja syntax [if] YA INCLUYE la palabra "if" (igual que `in' incluye
    * "in") -- es el patron estandar "cmd `varlist' `if' `in'", sin
    * reescribir el "if" a mano. La version anterior no lo sabia: envolvia
    * `if' de nuevo en filtro_base = "(`if')" y lo pegaba con & dentro de
    * subset, asi que ante un if() real (ej. "if pecuario==1 & cuenta_ua==1
    * & omision_esp==0") terminaba corriendo
    * "svylet ... if NACIONAL == 1 & (if pecuario==1 & ...)"
    * -- un "if" suelto en medio de una expresion booleana, invalido --
    * fallaba SIEMPRE que se pasaba un if() a tsvy, en cualquier
    * nivel()/especie (rc=111, "<primera palabra del if> not found").
    * touse (variable 0/1, marksample estandar) evita esa ambiguedad de
    * raiz: se antepone "if `touse'" explicitamente en cada uso, nunca se
    * reconstruye la expresion original como texto. tempvar (no un nombre
    * literal "touse"): subset queda "... & `touse'" y eso se le pasa TAL
    * CUAL a svylet, que internamente hace su PROPIO marksample touse
    * (nombre literal, sin tempvar) -- si tsvy tambien usara el
    * nombre literal "touse", cada llamada a svylet lo sobreescribiria
    * dentro del mismo loop, corrompiendo el touse de las iteraciones
    * siguientes. Con tempvar, el touse de tsvy y el de svylet son
    * columnas distintas por construccion, nunca chocan.
    * ---------------------------------------------------------------
    tempvar touse
    marksample touse, novarlist

    local stat = lower("`stat'")
    if !inlist("`stat'", "mean", "proportion", "total", "ratio") {
        di as err "tsvy: stat() debe ser mean, proportion, total o ratio"
        exit 198
    }
    if "`stat'" == "ratio" & "`denominator'" == "" {
        di as err "tsvy: stat(ratio) requiere denominator(varname)"
        exit 198
    }
    if "`nivel'"  == "" local nivel "NACIONAL REGION NOMBREDD_"
    if "`frame'"  == "" local frame "ACUM_ALL"

    * ---------------------------------------------------------------
    * v1.15 -- subpop() solo esta soportado en el camino conjunto
    * (boot()==0, el de produccion) -- ver nota de cabecera sobre por
    * que boot()>0 (que llama svylet por bloque via [if] filtrado, sin
    * su propio subpop() nativo) queda afuera por ahora. Corta con
    * error claro en vez de ignorar subpop() en silencio -- silenciar
    * subpop() aca reintroduciria exactamente el riesgo que esta opcion
    * existe para evitar.
    * ---------------------------------------------------------------
    if `"`subpop'"' != "" & `boot' > 0 {
        di as err "tsvy: subpop() todavia no esta soportado con boot()>0" ///
            " (camino viejo, via svylet por bloque). Use boot(0)" ///
            " (el default) para poder usar subpop(), o si necesita" ///
            " boot()>0 use [if] para el universo por ahora."
        exit 198
    }

    * ---------------------------------------------------------------
    * v1.17 -- mmd(): mismas validaciones fail-fast que el resto del
    * archivo ya aplica a subpop()/denominator() -- cortar ACA, antes de
    * entrar al loop de bloques, en vez de fallar a mitad de camino en
    * el primer bloque (o, peor, silenciarse dejando P_MMD en missing
    * sin avisar por que). REDISENO v1.17: ya no se asume refyear() vs
    * el ultimo anio de years() -- el usuario declara mmdyears(anio1
    * anio2) EXPLICITAMENTE; si pide mmd sin mmdyears(), corta con
    * mensaje en vez de adivinar un par por default (a pedido del
    * usuario -- ver nota de cabecera v1.17).
    * ---------------------------------------------------------------
    if "`mmd'" != "" {
        if `boot' > 0 {
            di as err "tsvy: mmd no esta soportado con boot()>0 (camino viejo," ///
                " via svylet por bloque) -- mismo motivo que subpop(). Use" ///
                " boot(0) (el default)."
            exit 198
        }
        if "`mmdyears'" == "" {
            di as err "tsvy: mmd requiere mmdyears(anio1 anio2) -- indique" ///
                " EXPLICITAMENTE los 2 anios de years() a comparar (ya no se" ///
                " asume refyear() vs el ultimo anio de years(); ver help)."
            exit 198
        }
        local mmdyr1 : word 1 of `mmdyears'
        local mmdyr2 : word 2 of `mmdyears'
        if `mmdyr1' == `mmdyr2' {
            di as err "tsvy: mmdyears(`mmdyears') tiene el mismo anio repetido --" ///
                " deben ser 2 anios distintos."
            exit 198
        }
        if "`mmdweight'" == "" {
            di as err "tsvy: mmd requiere mmdweight(variable_de_peso) -- mmd_2s no" ///
                " es un comando svy:, no hereda el pweight de svyset. Debe" ///
                " indicarse explicitamente (puede ser distinta del peso de svyset;" ///
                " ver el uso real con [aweight=...] en la ayuda de mmd_2s)."
            exit 198
        }
        capture confirm variable `mmdweight'
        if _rc {
            di as err "tsvy: no se encontro la variable mmdweight(`mmdweight')"
            exit 111
        }
        capture which mmd_2s
        if _rc {
            di as err "tsvy: mmd requiere el comando mmd_2s instalado -- ssc install mmd_2s"
            di as err "  (https://ideas.repec.org/c/boc/bocode/s459820.html)"
            exit 111
        }
    }

    * ---------------------------------------------------------------
    * v1.15.1 -- BUG REAL DE PRODUCCION (encontrado por el usuario en su
    * propio forvalues de 10 variables, rc=111 "invalid subpop() option"
    * en las 10 iteraciones): tsvy siempre arma
    * "svy, subpop(if `subpop')" -- si el usuario ya escribe el "if"
    * adentro de subpop(), tal como se escribe en svy NATIVO (asi lo
    * documentaba esta misma version en el USO de arriba y en el help:
    * "subpop(if cuenta_UA==1 & OMISION_SEXO!=1)"), el resultado era
    * "subpop(if if ...)" -- invalido, rc=111, 0 filas exportadas, en
    * TODAS las corridas del bucle real del usuario. Se normaliza aca:
    * si `subpop' (recortado de espacios) empieza literalmente con la
    * palabra "if" seguida de espacio, se la saca ANTES de los chequeos
    * de palabra completa de abajo y de armar `svyprefix' mas adelante
    * -- asi "subpop(exp)" y "subpop(if exp)" quedan equivalentes,
    * aceptando la forma que de hecho es la que todo el mundo escribe
    * (coincide con la convencion nativa, y con como esta escrito en el
    * help y en el USO de arriba).
    * ---------------------------------------------------------------
    if `"`subpop'"' != "" {
        local subpop = trim(`"`subpop'"')
        if regexm(`"`subpop'"', "^if[ 	]+(.+)$") {
            local subpop `"`=regexs(1)'"'
        }
    }

    * ---------------------------------------------------------------
    * v1.15 -- salvaguarda directa contra el bug real que motivo esta
    * version: cruce(MUJER) + "MUJER==1" metido en el [if] anula
    * cruce() de raiz (touse ya excluye al otro grupo antes de que
    * egen group() pueda separar por cruce()). Mover esa misma
    * restriccion a subpop() sin este chequeo seria igual de fragil --
    * subpop(MUJER==1) + cruce(MUJER) tiene el MISMO problema si
    * alguien lo escribe asi por error (subpop() tampoco deberia
    * usarse para separar el dominio que se compara, solo para el
    * universo). Se busca la variable como PALABRA COMPLETA (limites
    * de palabra vía regexm) para no confundir, ej., "MUJER" dentro de
    * "N_MUJERES". Mismo chequeo para cada variable de nivel().
    * ---------------------------------------------------------------
    if `"`subpop'"' != "" {
        if "`cruce'" != "" {
            if regexm(`"`subpop'"', "(^|[^A-Za-z0-9_])`cruce'([^A-Za-z0-9_]|$)") {
                di as err "tsvy: la variable de cruce(`cruce') aparece dentro de" ///
                    " subpop(`subpop')."
                di as err "  subpop() es para el UNIVERSO de analisis (misma" ///
                    " restriccion para todos los grupos) -- nunca para separar" ///
                    " el dominio que cruce() ya esta separando. Metiendo" ///
                    " `cruce' en subpop() se corre el riesgo de excluir todo" ///
                    " un grupo del universo antes de que cruce() pueda" ///
                    " separarlo, con el mismo efecto (error estandar" ///
                    " subestimado) que si `cruce' estuviera en el [if]."
                exit 198
            }
        }
        foreach a of local nivel {
            if regexm(`"`subpop'"', "(^|[^A-Za-z0-9_])`a'([^A-Za-z0-9_]|$)") {
                di as err "tsvy: la variable de nivel(`a') aparece dentro de" ///
                    " subpop(`subpop')."
                di as err "  subpop() es para el UNIVERSO de analisis -- nunca" ///
                    " para separar una categoria de nivel() en particular."
                exit 198
            }
        }
    }

    capture confirm variable `varname'
    if _rc {
        di as err "tsvy: no se encontro la variable `varname'"
        exit 111
    }
    if "`denominator'" != "" {
        capture confirm variable `denominator'
        if _rc {
            di as err "tsvy: no se encontro la variable denominator(`denominator')"
            exit 111
        }
    }
    capture confirm variable ANIO_
    if _rc {
        di as err "tsvy: no se encontro la variable ANIO_ en los datos actuales."
        exit 111
    }

    * ---------------------------------------------------------------
    * Validacion fail-fast de categorias declaradas (igual criterio que
    * expectcats() en tabsvy): si alguien cambio la codificacion de
    * VARNAME sin avisar, se corta ACA, no despues de exportar mal.
    * ---------------------------------------------------------------
    if "`expectcats'" != "" {
        quietly levelsof `varname' if `touse', local(catlist_obs)
        local catlist_obs : list sort catlist_obs
        local catlist_exp : list sort expectcats
        if "`catlist_obs'" != "`catlist_exp'" {
            di as err "tsvy: las categorias observadas de `varname' (`catlist_obs') no coinciden con expectcats(`expectcats')."
            di as err "  Revise la codificacion (value label) de `varname' antes de seguir."
            exit 498
        }
    }

    * ---------------------------------------------------------------
    * Deteccion de los codigos REALES de ANIO_ presentes (mismo criterio
    * que tabsvy v1.3): years() es la lista de anios reales de ESTA base,
    * en orden cronologico -- no asume que ANIO_ va 1..k sin huecos.
    * ---------------------------------------------------------------
    local nyears : word count `years'
    quietly levelsof ANIO_ if `touse', local(codigos_anio)
    local ncodigos : word count `codigos_anio'
    if `ncodigos' != `nyears' {
        di as err "tsvy: years() tiene `nyears' elemento(s) pero ANIO_ tiene `ncodigos' codigo(s) distinto(s) en los datos actuales (`codigos_anio')."
        di as err "  Deben coincidir uno a uno: el codigo mas chico de ANIO_ -> el primer anio de years(), en orden cronologico."
        exit 198
    }

    * ---------------------------------------------------------------
    * v1.4 -- refyear(): traduce el anio calendario (ej. 2026) al codigo
    * REAL de ANIO_ que le corresponde, usando la MISMA correspondencia
    * posicional years()<->codigos_anio ya validada arriba -- nunca se
    * decodifica contra el value label de ANIO_ (mismo criterio que el
    * resto del programa). refyear() habilita las columnas P_VS_REF/
    * SIG_VS_REF del frame acumulador (comparacion Bonferroni de cada
    * anio contra refyear(), k-1 comparaciones -- ver help para la
    * diferencia con GRUPO/CLD, que compara TODOS los pares). Si no se
    * especifica, esas columnas quedan en missing/vacias.
    * ---------------------------------------------------------------
    local refcode = .
    if "`refyear'" != "" {
        local pos = 0
        local j = 0
        foreach yr of local years {
            local j = `j' + 1
            if "`yr'" == "`refyear'" local pos = `j'
        }
        if `pos' == 0 {
            di as err "tsvy: refyear(`refyear') no esta en years(`years')."
            exit 198
        }
        local refcode : word `pos' of `codigos_anio'
    }
    local refopt ""
    if `refcode' != . local refopt "ref(`refcode')"

    * ---------------------------------------------------------------
    * v1.17 -- mmdyears(): misma traduccion posicional que refyear()
    * arriba (calendario -> codigo REAL de ANIO_), para los 2 anios que
    * mmd va a comparar. Vive DESPUES de la deteccion de codigos_anio
    * (no antes, como el resto de la validacion de mmd()) porque
    * necesita esa correspondencia ya armada -- mismo motivo que
    * refcode no se calcula antes de este punto tampoco.
    * ---------------------------------------------------------------
    local mmdcode1 = .
    local mmdcode2 = .
    if "`mmd'" != "" {
        * -- mmdyr1/mmdyr2 ya vienen de la validacion temprana de mas
        * arriba (donde se chequeo que fueran distintos) -- no se
        * vuelven a extraer aca, para no tener 2 lugares que parsear
        * `mmdyears' si algun dia cambia el criterio.
        local pos = 0
        foreach yr of local years {
            local pos = `pos' + 1
            if "`yr'" == "`mmdyr1'" local mmdcode1 : word `pos' of `codigos_anio'
            if "`yr'" == "`mmdyr2'" local mmdcode2 : word `pos' of `codigos_anio'
        }
        if `mmdcode1' == . | `mmdcode2' == . {
            di as err "tsvy: mmdyears(`mmdyears') debe contener 2 anios que esten" ///
                " en years(`years')."
            exit 198
        }
    }

    * ---------------------------------------------------------------
    * Frame acumulador
    * ---------------------------------------------------------------
    if "`replace'" != "" {
        capture frame drop `frame'
    }
    capture confirm frame `frame'
    if _rc {
        frame create `frame'
    }

    local bloques_saltados = 0
    local bloques_ok = 0

    * -- v1.15 -- inicializa el registro de nombres de columna mapeados
    * (mapa_col_<valor>) en la iteracion ANTERIOR de `foreach a of local
    * nivel'. Encontrado al implementar subpop() (que hace mas facil
    * disparar el caso: subpop() aumenta cuantas categorias de `combo'
    * quedan sin columna real) pero es un riesgo PREEXISTENTE de v1.13,
    * no exclusivo de subpop(): `combo' es un tempvar NUEVO cada `a'
    * (egen group() numera denso 1..k_total_actual desde 1 siempre), asi
    * que "mapa_col_3" de un `a' anterior con OTRO k_total podria quedar
    * con un valor de una corrida previa y leerse por error si en el `a'
    * actual la categoria "3" no tiene columna real (el "local mapa_col_
    * `nb'' = `pos'" de mas abajo solo SOBREESCRIBE los valores que SI
    * aparecen como nombre de columna, nunca limpia los que no). Ver el
    * "foreach nb of local mapa_col_nombres_prev" antes de reconstruir
    * el mapa en ambas ramas (proportion y el resto) mas abajo.
    local mapa_col_nombres_prev ""

    * ------------------------------------------------------------------
    * v1.4 -- el camino nuevo de mas abajo (ver nota junto al "foreach a")
    * necesita el mismo motor F omnibus + Bonferroni + CLD que
    * svylet_core() en svylet.ado, pero NO puede llamar a svylet_core()
    * (funcion mata) ni a _svylet_seleccionar() (subrutina Stata) TAL
    * CUAL viven ahi: probado en produccion real que, si el comando
    * svylet en si nunca llega a ejecutarse dentro de la MISMA corrida de
    * tsvy (el caso comun: boot()==0 y sin cruce(), que es exactamente
    * el camino que NO llama a svylet), Stata puede no haber registrado
    * _svylet_seleccionar todavia -- una llamada muda al comando svylet
    * (sin argumentos, para forzar la carga) NO alcanza: falla igual con
    * "command _svylet_seleccionar is unrecognized" (confirmado con log
    * real). En vez de depender de CUANDO/SI Stata termina de cargar el
    * resto de svylet.ado, tsvy.ado define su PROPIA copia de la funcion
    * mata (tsvy_core(), identica a svylet_core()) e implementa la
    * seleccion de filas de e(b)/e(V) en linea, sin subrutina aparte --
    * autosuficiente, sin depender del orden/momento de carga de otro
    * archivo .ado. Si el motor F/CLD de svylet_core() cambia, replicar
    * el cambio en tsvy_core() tambien.
    *
    * tsvy_core() NO puede definirse ACA (dentro de "program define tsvy
    * ... end"): Mata solo permite compilar una definicion de funcion
    * ("void nombre(...) { ... }") como bloque mata: de NIVEL DE ARCHIVO,
    * no anidada dentro del cuerpo de un programa Stata (probado: falla
    * al cargar el .ado con r(9611), sin importar si el bloque mata: va
    * envuelto en quietly o no). Por eso vive DESPUES del "end" que
    * cierra este programa, al final del archivo -- mismo lugar donde
    * vive el bloque mata: de svylet.ado, fuera de cualquier "program
    * define". Se carga junto con el resto del archivo apenas se invoca
    * el comando tsvy (una invocacion real, no una llamada muda a otro
    * archivo -- ver el parrafo de arriba sobre por que ESO fallaba).
    * ------------------------------------------------------------------

    foreach a of local nivel {
        quietly levelsof `a' if `touse', local(valores_a)
        local n_niveles : word count `valores_a'

        * ----------------------------------------------------------------
        * v1.4 -- camino NUEVO (default: boot()==0 y sin cruce()): un
        * solo "svy: STAT `varname', over(`a' ANIO_)" conjunto para TODOS
        * los valores de `a' a la vez -- el MISMO comando que produce el
        * numero de referencia cuando se corre a mano (ej.
        * "svy linearized: total PROD, over(REGION ANIO_)"). Ver nota de
        * cabecera (v1.4) sobre por que hace falta -- resumen: filtrar
        * "if `a'==valor" y recien ahi correr over(ANIO_) daba, en datos
        * reales, un error estandar mas chico que el correcto para
        * niveles que unen varias strata (REGION), aunque la estimacion
        * puntual coincidiera exacto.
        *
        * `combo' agrupa (`a', ANIO_) con egen group(), que numera
        * ascendente por `a' primero y por ANIO_ despues DENTRO de cada
        * `a' -- por construccion, todas las filas de un mismo valor de
        * `a' quedan en un rango CONTIGUO de valores de `combo', sin
        * huecos. Eso es lo que permite correr el svy: UNA sola vez para
        * toda la variable de nivel() y despues cortar, por valor de
        * `a', el bloque de columnas de e(b)/e(V) que le corresponde --
        * en vez de tener que decodificar el nombre de ecuacion/columna
        * que Stata le pondria a un over() de DOS variables directo
        * (over(`a' ANIO_)), que no se pudo verificar sin correr Stata.
        * ----------------------------------------------------------------
        if `boot' == 0 {
            if `n_niveles' < 1 {
                continue
            }

            * -- v1.9 -- `combo' ahora agrupa TAMBIEN por `cruce' cuando
            * se paso (group(`a' `cruce' ANIO_) en vez de group(`a' ANIO_)),
            * asi que el UNICO "svy: STAT ..., over(combo)" conjunto de mas
            * abajo cruza las tres dimensiones a la vez -- ver nota v1.9 de
            * cabecera sobre por que esto reemplaza el camino viejo de
            * cruce() (que filtraba "if cruce==valor" y corria over(ANIO_)
            * aparte, con el mismo problema de error estandar que v1.4 ya
            * habia identificado y corregido para nivel()).
            tempvar combo
            if "`cruce'" != "" {
                quietly egen `combo' = group(`a' `cruce' ANIO_) if `touse'
            }
            else {
                quietly egen `combo' = group(`a' ANIO_) if `touse'
            }

            * -- v1.15 -- svyprefix es "svy" o "svy, subpop(if `subpop')",
            * segun se haya pasado subpop() -- una sola construccion
            * reutilizada por las 4 ramas de stat(), en vez de duplicar
            * el if/else de subpop() cuatro veces. `touse' (armado SOLO
            * desde [if], ver marksample arriba) sigue aplicandose igual
            * que siempre en las 4 ramas -- subpop() nunca se mezcla
            * dentro de `touse' ni de `combo'; viaja SOLO como opcion de
            * prefijo, exactamente el patron nativo "svy, subpop(if ...):
            * STAT ..., over(combo)" validado contra Stata real en esta
            * misma sesion (ver nota de cabecera v1.15).
            local svyprefix "svy"
            if `"`subpop'"' != "" {
                local svyprefix `"svy, subpop(if `subpop')"'
            }

            if "`stat'" == "mean" {
                capture noisily `svyprefix': mean `varname' if `touse', over(`combo')
            }
            else if "`stat'" == "total" {
                capture noisily `svyprefix': total `varname' if `touse', over(`combo')
            }
            else if "`stat'" == "ratio" {
                capture noisily `svyprefix': ratio `varname'/`denominator' if `touse', over(`combo')
            }
            else {
                capture noisily `svyprefix': proportion `varname' if `touse', over(`combo')
            }
            if _rc {
                di as err "tsvy: svy fallo (rc=" _rc ") para el over(`a' ANIO_) " ///
                    "conjunto -- se saltan los " `n_niveles' " bloque(s) de `a'" ///
                    " (revise el diseno/datos)"
                local bloques_saltados = `bloques_saltados' + `n_niveles'
                continue
            }

            tempname B_all V_all
            matrix `B_all' = e(b)
            matrix `V_all' = e(V)
            local df_r = e(df_r)
            if "`df_r'" == "" {
                di as err "tsvy: e(df_r) no disponible tras el svy -- revisar version de Stata/diseno"
                exit 498
            }
            tempname Nmat_all Nsubpmat_all Rtable_all
            capture matrix `Nmat_all' = e(_N)
            capture matrix `Nsubpmat_all' = e(_N_subp)
            capture matrix `Rtable_all' = r(table)

            * `k_total' (numero de categorias distintas de `combo') se
            * calcula con levelsof, NO con colsof(e(b)) -- para
            * stat(proportion), e(b) trae una ECUACION por cada valor de
            * `varname' concatenada en la misma fila, asi que
            * colsof(e(b)) séria k_total*num_ecuaciones, no k_total solo.
            * Mismo criterio que usa svylet.ado en su propio comando (ahi
            * tambien sale de levelsof sobre la variable de over(), nunca
            * de colsof de la matriz).
            quietly levelsof `combo' if `touse', local(niveles_combo)
            local k_total : word count `niveles_combo'

            * -- v1.12/v1.13 -- v1.12 agrego el chequeo de que e(b) tenga
            * tantas columnas como categorias distintas cuenta `combo' --
            * confirmado en produccion real (SEDE_POS) que puede NO
            * coincidir: Stata excluye de e(b) alguna categoria puntual de
            * `combo' (varianza no definida/muestra degenerada), sin
            * aviso. v1.12 cortaba duro apenas detectaba esto; v1.13 ya
            * no corta -- ver el mapeo por NOMBRE de columna mas abajo
            * (idx_usar_all) y el recorte por bloque mas adelante, que
            * manejan la categoria faltante sin desalinear las demas.
            * Se deja este aviso informativo (no `exit') para que quede
            * registro de cuantas categorias faltaron. Solo aplica fuera
            * de stat(proportion) -- ver el comentario de `k_total' arriba
            * sobre por que colsof(e(b)) no es comparable ahi (traeria
            * k_total*num_ecuaciones, no k_total).
            if "`stat'" != "proportion" {
                local k_cols_b = colsof(`B_all')
                if `k_cols_b' != `k_total' {
                    local motivo_subpop = cond(`"`subpop'"' != "", ///
                        " (esperable con subpop(`subpop') activo: categorias enteramente" ///
                        " fuera de la subpoblacion tampoco reciben columna, ademas de las" ///
                        " de varianza degenerada)", "")
                    di as txt "tsvy: aviso -- e(b) del svy: `stat' conjunto para `a' trae " ///
                        "`k_cols_b' columna(s) mientras que `combo' (`a' `cruce' ANIO_) tiene " ///
                        "`k_total' categoria(s) distintas (" `=`k_total'-`k_cols_b'' " categoria(s)" ///
                        " sin columna en e(b), probablemente por varianza no definida/muestra" ///
                        " degenerada`motivo_subpop'). Se ubica cada categoria por su nombre de" ///
                        " columna real en vez de por posicion asumida; el/los anio(s) sin columna" ///
                        " quedan como fila vacia puntual mas abajo, sin correr de posicion las demas."
                }
            }

            * Misma logica que _svylet_seleccionar en svylet.ado, duplicada
            * aca EN LINEA en vez de llamada como subrutina de otro archivo
            * -- ver nota v1.4 de mas arriba (junto a la definicion de
            * tsvy_core()) sobre por que.
            tempname b_sel_all V_sel_all
            local idx_usar_all ""
            if "`stat'" == "proportion" {
                * e(b) trae una ECUACION por cada valor de `varname', y
                * DENTRO de cada ecuacion, una columna por categoria de
                * over() (`combo' aca). Se identifica la ecuacion de
                * `level' por el texto del value label, por "_prop_N"
                * (posicion ordinal, sin label), o por el codigo numerico
                * plano -- mismo criterio que svylet.ado.
                local vallab : value label `varname'
                local buscado_label ""
                if "`vallab'" != "" {
                    local buscado_label : label `vallab' `level'
                }
                quietly levelsof `varname', local(valores_x)
                local rank = 0
                local i = 0
                foreach v of local valores_x {
                    local i = `i' + 1
                    if `v' == `level' {
                        local rank = `i'
                    }
                }
                local buscado_ordinal = "_prop_`rank'"
                local buscado_numerico = "`level'"

                * -- v1.15 -- antes de esta version, se exigia encontrar
                * EXACTAMENTE `k_total' columnas para la ecuacion de
                * `level' o se cortaba con exit 498 -- correcto cuando la
                * causa es una mala configuracion (level() equivocado),
                * pero subpop() puede dejar una categoria de `combo'
                * ENTERA sin columna en NINGUNA ecuacion (subpoblacion
                * vacia para esa categoria), un caso legitimo que antes
                * no se distinguia de un error real. Ahora se mapea cada
                * categoria de `combo' (1..k_total) por el NOMBRE de su
                * columna DENTRO de la ecuacion encontrada -- mismo
                * patron v1.13 que ya usan mean/total/ratio -- y la(s)
                * categoria(s) sin columna quedan en "." (fila vacia
                * puntual mas abajo), no cortan el bloque entero.
                if `"`mapa_col_nombres_prev'"' != "" {
                    foreach nb of local mapa_col_nombres_prev {
                        local mapa_col_`nb' ""
                    }
                }
                local ecuaciones : coleq `B_all'
                local nombres_b : colnames `B_all'
                local pos = 0
                local n_en_ecuacion = 0
                local mapa_col_nombres_prev ""
                foreach eq of local ecuaciones {
                    local pos = `pos' + 1
                    if "`eq'" == "`buscado_label'" | "`eq'" == "`buscado_ordinal'" ///
                        | "`eq'" == "`buscado_numerico'" {
                        local n_en_ecuacion = `n_en_ecuacion' + 1
                        local nb : word `pos' of `nombres_b'
                        local mapa_col_`nb' = `pos'
                        local mapa_col_nombres_prev "`mapa_col_nombres_prev' `nb'"
                    }
                }
                forvalues i = 1/`k_total' {
                    if "`mapa_col_`i''" != "" {
                        local idx_usar_all "`idx_usar_all' `mapa_col_`i''"
                    }
                    else {
                        local idx_usar_all "`idx_usar_all' ."
                    }
                }

                * Salvaguarda: si NINGUNA columna matcheo (indicio de que
                * el nombre de columna dentro de la ecuacion no tiene el
                * formato asumido -- nunca confirmado contra Stata real
                * para stat(proportion), ver advertencia de cabecera
                * v1.15), cae de vuelta al error original en vez de
                * seguir con datos posiblemente desalineados.
                if `n_en_ecuacion' == 0 {
                    di as err "tsvy: no se encontro NINGUNA columna para el valor " ///
                        "`level'" " de " "`varname'" " en e(b) (over(`a' ANIO_) conjunto)."
                    di as err "  buscado como texto de label: " "`buscado_label'"
                    di as err "  buscado como ordinal sin label: " "`buscado_ordinal'"
                    di as err "  buscado como codigo numerico plano: " "`buscado_numerico'"
                    di as err "  ajustar level() si el valor de exito no es 1."
                    exit 498
                }
                if `n_en_ecuacion' < `k_total' {
                    local motivo_subpop_prop = cond(`"`subpop'"' != "", ///
                        " -- esperable con subpop(`subpop') activo (subpoblacion" ///
                        " vacia para esa categoria)", ///
                        ", probablemente varianza degenerada")
                    di as txt "tsvy: aviso -- la ecuacion de `stat' `level' para `a' trae " ///
                        "`n_en_ecuacion' de `k_total' categoria(s) de `combo' (" ///
                        `=`k_total'-`n_en_ecuacion'' " categoria(s) sin columna" ///
                        "`motivo_subpop_prop'). El/los anio(s) correspondientes quedan" ///
                        " como fila vacia puntual mas abajo, sin correr de posicion las demas."
                }
            }
            else {
                * -- v1.13 -- en vez de asumir columna=categoria (bug real
                * de produccion, ver nota v1.12/v1.13 de cabecera), ubica
                * la columna REAL de cada categoria de `combo' por su
                * NOMBRE en e(b) -- `colnames' trae literalmente el valor
                * de la categoria (confirmado con datos reales: "1 2 ...
                * 99 101 102 ..." cuando la 100 quedo excluida). Si una
                * categoria no tiene columna, su entrada en `idx_usar_all'
                * queda en "." en vez de una posicion -- b_sel_all/
                * V_sel_all quedan con esa fila en missing mas abajo, en
                * vez de con el dato de la categoria vecina.
                if `"`mapa_col_nombres_prev'"' != "" {
                    foreach nb of local mapa_col_nombres_prev {
                        local mapa_col_`nb' ""
                    }
                }
                local nombres_b : colnames `B_all'
                local pos = 0
                foreach nb of local nombres_b {
                    local pos = `pos' + 1
                    local mapa_col_`nb' = `pos'
                }
                local mapa_col_nombres_prev "`nombres_b'"
                forvalues i = 1/`k_total' {
                    if "`mapa_col_`i''" != "" {
                        local idx_usar_all "`idx_usar_all' `mapa_col_`i''"
                    }
                    else {
                        local idx_usar_all "`idx_usar_all' ."
                    }
                }
            }

            matrix `b_sel_all' = J(`k_total', 1, .)
            matrix `V_sel_all' = J(`k_total', `k_total', 0)
            local fila = 0
            foreach i of local idx_usar_all {
                local fila = `fila' + 1
                if "`i'" == "." continue
                matrix `b_sel_all'[`fila', 1] = `B_all'[1, `i']
                local col = 0
                foreach j of local idx_usar_all {
                    local col = `col' + 1
                    if "`j'" == "." continue
                    matrix `V_sel_all'[`fila', `col'] = `V_all'[`i', `j']
                }
            }

            * N ponderado/sin ponderar y limites de IC por categoria de
            * `combo', en el orden de `idx_usar_all' -- mismo patron que
            * usa svylet.ado internamente, con el mismo swap e(_N) <->
            * e(_N_subp) del fix de N_PONDERA/N_SIN_PON: e(_N) es el
            * tamano SIN ponderar y e(_N_subp) el PONDERADO (ver nota en
            * svylet.ado, seccion "tempname Nmat Nsubpmat Rtable").
            tempname Nout_sinpon_all Nout_pond_all LIout_all LSout_all
            matrix `Nout_sinpon_all' = J(`k_total', 1, .)
            matrix `Nout_pond_all'   = J(`k_total', 1, .)
            matrix `LIout_all'       = J(`k_total', 1, .)
            matrix `LSout_all'       = J(`k_total', 1, .)
            local fila = 0
            foreach i of local idx_usar_all {
                local fila = `fila' + 1
                capture matrix `Nout_sinpon_all'[`fila', 1] = `Nmat_all'[1, `i']
                capture matrix `Nout_pond_all'[`fila', 1]   = `Nsubpmat_all'[1, `i']
                capture matrix `LIout_all'[`fila', 1]       = `Rtable_all'["ll", `i']
                capture matrix `LSout_all'[`fila', 1]       = `Rtable_all'["ul", `i']
            }

            * Chequeo defensivo: `combo' deberia ser una secuencia DENSA
            * 1..`k_total' (min=1, max=k_total, sin huecos) -- es la
            * garantia de egen group() de la que depende todo el corte
            * por bloques mas abajo (rango contiguo de columnas por
            * valor de `a'). Si no se cumple, es mas seguro cortar ahi
            * que seguir con indices desalineados.
            quietly summarize `combo' if `touse', meanonly
            if r(min) != 1 | r(max) != `k_total' {
                di as err "tsvy: `combo' (group de `a' x ANIO_) no es una secuencia " ///
                    "densa 1..`k_total' (min=" r(min) " max=" r(max) ") -- no deberia " ///
                    "pasar, revise version de Stata/datos."
                exit 498
            }

            * -- v1.10 -- el universo de valores de cruce() se calcula UNA
            * sola vez por `a' (union de todos los vistos en CUALQUIER
            * `cval', via `touse' sin filtrar por `cval') -- no per-cval
            * como hasta v1.9. Necesario para el fix de abajo: hasta v1.9,
            * un (`cval',`sval') sin datos suficientes (0 observaciones, o
            * menos de 2 anios) se saltaba SIN agregar fila al frame
            * acumulador -- silenciosamente, sin mas rastro que el "di as
            * err" en pantalla. Un consumidor que hace "reshape wide" +
            * "export excel" a un rango CONTIGUO de una plantilla (el caso
            * real que motivo este fix: hoja Dom_Iguales, Selva sin NINGUN
            * dato de usos=6) terminaba con TODAS las filas siguientes de
            * ese bloque corridas una posicion -- bug de produccion real,
            * confirmado comparando el Excel exportado contra la
            * plantilla. Ahora cada combinacion salteada deja una fila
            * "vacia" (_tsvy_fila_vacia: todo missing salvo
            * NIVEL/CATEGORIA/CRUCE/var) en vez de cero filas, asi que el
            * frame SIEMPRE tiene exactamente una fila por cada
            * (categoria,cruce) que aparece en los datos -- seguro de
            * exportar a celdas fijas sin tener que revalidar la cuenta de
            * filas cada vez. Aplica solo al camino conjunto (boot()==0);
            * el camino viejo (boot()>0) sigue sin agregar fila cuando
            * salta un bloque -- ver nota junto a "Camino VIEJO" mas
            * abajo.
            local niveles_cruce_todos "."
            if "`cruce'" != "" {
                quietly levelsof `cruce' if `touse', local(niveles_cruce_todos)
            }
            local primer_anio : word 1 of `years'
            local nivel_actual = subinstr("`a'", "_", "", .)

            foreach cval of local valores_a {
                foreach sval of local niveles_cruce_todos {
                    local cond_bloque "`a' == `cval' & `touse'"
                    local etiqueta_bloque "`a'=`cval'"
                    local cruceopt ""
                    if "`cruce'" != "" {
                        local cond_bloque "`cond_bloque' & `cruce' == `sval'"
                        local etiqueta_bloque "`etiqueta_bloque' `cruce'=`sval'"
                        local cruceopt "cruce(`sval')"
                    }

                    quietly summarize `combo' if `cond_bloque', meanonly
                    if r(N) == 0 {
                        di as err "tsvy: se salta `etiqueta_bloque' -- no tiene observaciones" ///
                            " (fila vacia agregada para no correr de posicion las filas siguientes)."
                        local bloques_saltados = `bloques_saltados' + 1
                        _tsvy_fila_vacia, nivel("`nivel_actual'") categoria(`cval') ///
                            anio(`primer_anio') frame(`frame') varname(`"`varname'"') `cruceopt'
                        continue
                    }
                    local start_pos = r(min)
                    local end_pos   = r(max)
                    local k_cat = `end_pos' - `start_pos' + 1

                    quietly levelsof ANIO_ if `cond_bloque', local(anios_este_cval)
                    if wordcount("`anios_este_cval'") != `k_cat' {
                        di as err "tsvy: no se pudo alinear el bloque de `etiqueta_bloque' contra " ///
                            "ANIO_ (`k_cat' posicion(es) vs " wordcount("`anios_este_cval'") ///
                            " anio(s)) -- revise los datos."
                        exit 498
                    }

                    * -- v1.18 -- ya NO se salta el bloque completo solo por
                    * tener 1 anio (k_cat==1): ese unico anio SI tiene un
                    * punto estimado real (viene del mismo svy: over(combo)
                    * conjunto que corre para todo `a'), asi que se sigue
                    * procesando -- ver el chequeo de k_cat_valido mas abajo,
                    * que es donde de verdad se decide si hay o no con que
                    * testear (F_WALD/GRUPO). Antes de v1.18, un dominio con
                    * datos en un solo anio (comun en cultivos/departamentos
                    * chicos) perdia TODO el bloque, incluido ese punto
                    * estimado ya calculado -- confirmado en produccion
                    * comparando contra el pipeline paralelo via putexcel
                    * (que si mostraba el anio suelto, por estimar cada anio
                    * con un svy: independiente en vez de un over() conjunto).

                    tempname bmat Vmat nspmat npmat limat lsmat
                    mata: st_matrix("`bmat'", st_matrix("`b_sel_all'")[(`start_pos'::`end_pos'), 1])
                    mata: st_matrix("`Vmat'", st_matrix("`V_sel_all'")[(`start_pos'::`end_pos'), (`start_pos'::`end_pos')])
                    mata: st_matrix("`nspmat'", st_matrix("`Nout_sinpon_all'")[(`start_pos'::`end_pos'), 1])
                    mata: st_matrix("`npmat'", st_matrix("`Nout_pond_all'")[(`start_pos'::`end_pos'), 1])
                    mata: st_matrix("`limat'", st_matrix("`LIout_all'")[(`start_pos'::`end_pos'), 1])
                    mata: st_matrix("`lsmat'", st_matrix("`LSout_all'")[(`start_pos'::`end_pos'), 1])

                    * -- v1.13 -- alguna posicion DENTRO de este bloque
                    * puede no tener columna real en e(b) (ver aviso mas
                    * arriba) -- `bmat' queda con esa fila en missing. Se
                    * detecta aca y se recorta a las posiciones con dato
                    * real antes de llamar a tsvy_core (que sigue
                    * esperando un vector totalmente definido, igual que
                    * siempre); el/los anio(s) sin dato quedan como fila
                    * vacia PUNTUAL de ese anio en el frame, mas abajo --
                    * no afectan a los demas anios del mismo bloque. Si no
                    * falta ninguna posicion (caso normal), `pos_validas'
                    * termina siendo "1 2 ... `k_cat''" y este recorte no
                    * cambia nada.
                    local pos_validas ""
                    forvalues i = 1/`k_cat' {
                        if el(`bmat', `i', 1) != . {
                            local pos_validas "`pos_validas' `i'"
                        }
                    }
                    local pos_validas = trim("`pos_validas'")
                    local k_cat_valido : word count `pos_validas'

                    if `k_cat_valido' < `k_cat' {
                        di as err "tsvy: `etiqueta_bloque' -- " `=`k_cat'-`k_cat_valido'' ///
                            " de `k_cat' anio(s) sin columna real en e(b) -- se recorta a" ///
                            " los `k_cat_valido' anio(s) con dato real para el test; el/los" ///
                            " anio(s) sin dato quedan como fila vacia puntual (no corren de" ///
                            " posicion las filas siguientes)."
                    }

                    if `k_cat_valido' == 0 {
                        di as err "tsvy: se salta `etiqueta_bloque' -- despues de recortar" ///
                            " anio(s) sin columna real en e(b), no queda NINGUN anio con dato" ///
                            " (fila vacia agregada para no correr de posicion las filas" ///
                            " siguientes)."
                        local bloques_saltados = `bloques_saltados' + 1
                        _tsvy_fila_vacia, nivel("`nivel_actual'") categoria(`cval') ///
                            anio(`primer_anio') frame(`frame') varname(`"`varname'"') `cruceopt'
                        continue
                    }

                    local idxlist : subinstr local pos_validas " " ",", all
                    tempname bmat_uso Vmat_uso nspmat_uso npmat_uso limat_uso lsmat_uso
                    mata: st_matrix("`bmat_uso'", st_matrix("`bmat'")[(`idxlist'), 1])
                    mata: st_matrix("`Vmat_uso'", st_matrix("`Vmat'")[(`idxlist'), (`idxlist')])
                    mata: st_matrix("`nspmat_uso'", st_matrix("`nspmat'")[(`idxlist'), 1])
                    mata: st_matrix("`npmat_uso'", st_matrix("`npmat'")[(`idxlist'), 1])
                    mata: st_matrix("`limat_uso'", st_matrix("`limat'")[(`idxlist'), 1])
                    mata: st_matrix("`lsmat_uso'", st_matrix("`lsmat'")[(`idxlist'), 1])
                    local anios_uso ""
                    foreach p of local pos_validas {
                        local yr : word `p' of `anios_este_cval'
                        local anios_uso "`anios_uso' `yr'"
                    }

                    * -- v1.18 -- con k_cat_valido==1 no hay con que testear
                    * (F de Wald/Bonferroni/CLD necesitan al menos 2
                    * categorias validas) -- pero el punto ESTIMADO de ese
                    * unico anio SI es real (sale del mismo svy: over(combo)
                    * conjunto que los bloques con 2+ anios), asi que ya no
                    * se descarta la fila entera como hasta v1.17: mas abajo,
                    * el loop que arma FILAS_TMP llena ESTIMA/ERROR_ST/
                    * LIM_INF/LIM_SUP/N_SIN_PON/N_PONDERA/CV igual para
                    * cualquier `k_cat_valido' -- lo unico que cambia es que
                    * F_WALD/P_WALD/GRUPO/P_VS_REF quedan en missing (lo
                    * unico que de verdad no se puede calcular con 1 anio).
                    local F_omni = .
                    local p_omni = .
                    tempname pvsrefmat
                    matrix `pvsrefmat' = J(`k_cat_valido', 1, .)

                    if `k_cat_valido' >= 2 {
                        mata: tsvy_core("`bmat_uso'", "`Vmat_uso'", `df_r', `alpha', `k_cat_valido')
                        local F_omni = r(F_omnibus)
                        local p_omni = r(p_omnibus)
                        forvalues i = 1/`k_cat_valido' {
                            local letra_`i'  "`r(letra_`i')'"
                            local codigo_`i' : word `i' of `anios_uso'
                        }

                        * -- v1.4 -- refyear(): igual idea que ref() en svylet.ado
                        * (k-1 contrastes vs una categoria base, Bonferroni sobre
                        * k-1), pero armado con llamadas mata: de UNA linea cada
                        * una (vectorizadas, sin loop), en vez de definir una
                        * funcion mata nueva -- ver nota v1.4 de cabecera sobre
                        * por que una funcion mata no puede vivir dentro de
                        * "program define tsvy". `refpos_local' es la posicion
                        * DENTRO de este bloque (`etiqueta_bloque') del anio
                        * base -- puede no estar presente en TODOS los bloques
                        * (un dominio chico podria no tener datos justo del
                        * anio base), en cuyo caso P_VS_REF queda en missing
                        * para ese bloque.
                        local refpos_local = 0
                        if `refcode' != . {
                            local j = 0
                            foreach code of local anios_uso {
                                local j = `j' + 1
                                if `code' == `refcode' local refpos_local = `j'
                            }
                        }
                        if `refpos_local' > 0 {
                            tempname vdiag vrefcol vse vt vpraw
                            mata: st_matrix("`vdiag'", diagonal(st_matrix("`Vmat_uso'")))
                            mata: st_matrix("`vrefcol'", st_matrix("`Vmat_uso'")[.,`refpos_local'])
                            mata: st_matrix("`vse'", sqrt(st_matrix("`vdiag'") :+ st_matrix("`vdiag'")[`refpos_local',1] :- 2:*st_matrix("`vrefcol'")))
                            mata: st_matrix("`vt'", (st_matrix("`bmat_uso'") :- st_matrix("`bmat_uso'")[`refpos_local',1]) :/ st_matrix("`vse'"))
                            mata: st_matrix("`vpraw'", 2:*ttail(`df_r', abs(st_matrix("`vt'"))) :* (`k_cat_valido'-1))
                            mata: st_matrix("`pvsrefmat'", rowmin((st_matrix("`vpraw'"), J(`k_cat_valido',1,1))))
                            matrix `pvsrefmat'[`refpos_local', 1] = .
                        }
                    }
                    else {
                        di as err "tsvy: `etiqueta_bloque' -- solo 1 anio con dato real" ///
                            " (codigo `anios_uso') -- se conserva el punto estimado de ese" ///
                            " anio; F_WALD/P_WALD/GRUPO/P_VS_REF quedan missing (no hay con" ///
                            " que testear con 1 solo anio)."
                        local letra_1 ""
                    }

                    di as text _n "{hline 70}"
                    di as text "tsvy (over conjunto) -- `stat' de `varname', `etiqueta_bloque', over(ANIO_)"
                    di as text "{hline 70}"
                    if `F_omni' == . {
                        di as err "  F no calculable -- ver aviso arriba (varianza no definida en" ///
                            " alguna categoria, o menos de 2 anios validos en este bloque)."
                    }
                    else {
                        di as text "  F(" %3.0f `=`k_cat_valido'-1' ", " %6.0f `=`df_r'-(`k_cat_valido'-1)+1' ") = " ///
                            as res %9.4f `F_omni' as text "   Prob > F = " as res %6.4f `p_omni'
                    }

                    * ---------------------------------------------------
                    * v1.17 -- mmd_2s entre los 2 anios FIJOS de
                    * mmdyears() (mmdcode1/mmdcode2, ya traducidos a
                    * codigo de ANIO_ mas arriba) -- ya no depende de
                    * refyear() ni de "el ultimo anio presente en este
                    * bloque": el usuario dijo explicitamente que par
                    * comparar, y ese par es el MISMO en todos los
                    * bloques. Si alguno de los 2 anios no tiene datos en
                    * este bloque puntual, o mmd_2s falla, P_MMD/
                    * EFFECT_MMD quedan en missing -- no corta el loop
                    * (mismo criterio de degradacion que P_VS_REF).
                    * ---------------------------------------------------
                    local p_mmd = .
                    local effect_mmd = .
                    if "`mmd'" != "" {
                        local universo_mmd "`cond_bloque' & inlist(ANIO_, `mmdcode1', `mmdcode2')"
                        if `"`subpop'"' != "" {
                            local universo_mmd "`universo_mmd' & (`subpop')"
                        }
                        * -- se exige N>0 en CADA anio por separado, no
                        * solo en el total combinado: un bloque sin datos
                        * de uno de los 2 anios tiene N>0 igual (las
                        * filas del otro anio solas), pero mmd_2s con un
                        * by() de un solo grupo esta garantizado a
                        * fallar -- mejor detectarlo aca (mensaje mas
                        * preciso, sin gastar el bootstrap completo en
                        * una llamada condenada).
                        quietly count if `universo_mmd' & ANIO_ == `mmdcode1'
                        local n_mmd1 = r(N)
                        quietly count if `universo_mmd' & ANIO_ == `mmdcode2'
                        local n_mmd2 = r(N)
                        if `n_mmd1' > 0 & `n_mmd2' > 0 {
                            tempvar mmdgrp
                            quietly gen byte `mmdgrp' = (ANIO_ == `mmdcode2') if `universo_mmd'
                            di as text "  mmd_2s: `etiqueta_bloque' (mmdyears(`mmdyears'): codigo " ///
                                "`mmdcode1' vs `mmdcode2')..."
                            capture noisily mmd_2s `varname' if `universo_mmd' [aweight=`mmdweight'], ///
                                by(`mmdgrp') boot(`mmdboot') reps(`mmdreps') seed(`mmdseed')
                            if _rc == 0 {
                                local p_mmd = r(p_boot)
                                local effect_mmd = r(effect_size)
                            }
                            else {
                                di as err "  mmd_2s fallo (rc=" _rc ") para `etiqueta_bloque'" ///
                                    " -- P_MMD/EFFECT_MMD quedan missing para este bloque."
                            }
                            quietly drop `mmdgrp'
                        }
                        else {
                            di as err "  mmd_2s: `etiqueta_bloque' sin observaciones en mmdyears(`mmdyears')" ///
                                " (`n_mmd1' / `n_mmd2') dentro del universo -- se omite (P_MMD/EFFECT_MMD" ///
                                " missing para este bloque)."
                        }
                    }

                    capture frame drop FILAS_TMP
                    frame create FILAS_TMP
                    frame FILAS_TMP {
                        quietly set obs `k_cat'
                        gen str12  NIVEL      = subinstr("`a'", "_", "", .)
                        gen double CATEGORIA  = `cval'
                        gen byte   ANIO       = .
                        gen double ESTIMA     = .
                        gen double ERROR_ST   = .
                        gen double LIM_INF    = .
                        gen double LIM_SUP    = .
                        gen double N_SIN_PON  = .
                        gen double N_PONDERA  = .
                        gen double F_WALD     = `F_omni'
                        gen double P_WALD     = `p_omni'
                        gen double P_MMD      = `p_mmd'
                        gen double EFFECT_MMD = `effect_mmd'
                        gen str5   GRUPO      = ""
                        gen double P_VS_REF   = .
                        gen str3   SIG_VS_REF = ""
                        gen byte   var        = 1
                        gen str32  VARNAME    = "`varname'"
                        if "`cruce'" != "" {
                            gen double CRUCE = `sval'
                        }

                        * -- v1.13 -- `k_cat' filas (TODOS los anios reales
                        * de este bloque segun ANIO_, sin importar si
                        * tuvieron columna en e(b)) -- el ANIO de la fila
                        * `i' sale directo de `anios_este_cval' (dato
                        * crudo, no afectado por columnas faltantes). Si
                        * la posicion `i' esta en `pos_validas' (tiene
                        * columna real), se llena con el resultado de
                        * tsvy_core sobre el subconjunto recortado
                        * (`r'-esima posicion ahi); si no, la fila queda
                        * con ESTIMA y el resto en missing (fila vacia
                        * PUNTUAL de ese anio, ya generada por el "gen ...
                        * = ." de arriba) -- no afecta a los demas anios
                        * del mismo bloque.
                        forvalues i = 1/`k_cat' {
                            local codigo_orig_i : word `i' of `anios_este_cval'
                            local pos = 0
                            local j = 0
                            foreach code of local codigos_anio {
                                local j = `j' + 1
                                if `code' == `codigo_orig_i' local pos = `j'
                            }
                            if `pos' == 0 {
                                di as err "tsvy: no se pudo mapear el codigo de ANIO_ " ///
                                    "`codigo_orig_i' contra codigos_anio (`codigos_anio') -- revise years()."
                                exit 498
                            }
                            local yval : word `pos' of `years'
                            quietly replace ANIO = `yval' in `i'

                            local r : list posof "`i'" in pos_validas
                            if `r' > 0 {
                                quietly replace ESTIMA    = el(`bmat_uso', `r', 1)        in `i'
                                quietly replace ERROR_ST  = sqrt(el(`Vmat_uso', `r', `r')) in `i'
                                quietly replace LIM_INF   = el(`limat_uso', `r', 1)       in `i'
                                quietly replace LIM_SUP   = el(`lsmat_uso', `r', 1)       in `i'
                                quietly replace N_SIN_PON = el(`nspmat_uso', `r', 1)      in `i'
                                quietly replace N_PONDERA = el(`npmat_uso', `r', 1)       in `i'
                                quietly replace GRUPO     = "`letra_`r''"                 in `i'
                                quietly replace P_VS_REF  = el(`pvsrefmat', `r', 1)       in `i'
                            }
                        }
                        gen double CV = (ERROR_ST / ESTIMA) * 100
                        gen str2 REF_ = ""
                        replace REF_ = "a/" if CV > `threshold' & CV != .
                        replace SIG_VS_REF = "*"   if P_VS_REF < 0.10 & P_VS_REF != .
                        replace SIG_VS_REF = "**"  if P_VS_REF < 0.05 & P_VS_REF != .
                        replace SIG_VS_REF = "***" if P_VS_REF < 0.01 & P_VS_REF != .
                    }
                    frame `frame': frameappend FILAS_TMP
                    capture frame drop FILAS_TMP
                    local bloques_ok = `bloques_ok' + 1
                }
            }
            continue
        }

        * ----------------------------------------------------------------
        * Camino VIEJO -- desde v1.9, SOLO se llega aca cuando boot()>0
        * (el bloque de arriba, boot()==0, siempre hace "continue" antes
        * de esta linea, con o sin cruce()). Filtra "if `a'==`cval'
        * [& `cruce'==`sval']" y corre svylet ..., over(ANIO_) para cada
        * bloque por separado -- necesario porque boot() reconstruye
        * replicas de remuestreo por bloque (svylet/bootstrap), no un
        * unico over() conjunto como el camino nuevo. Ver nota v1.9 de
        * cabecera sobre por que cruce() ya no depende de este camino.
        * ----------------------------------------------------------------
        foreach cval of local valores_a {

            local niveles_cruce "."
            if "`cruce'" != "" {
                local cond_niv "`a' == `cval' & `touse'"
                quietly levelsof `cruce' if `cond_niv', local(niveles_cruce)
            }

            foreach sval of local niveles_cruce {
                local subset "`a' == `cval' & `touse'"
                if "`cruce'" != "" local subset "`subset' & `cruce' == `sval'"

                * refopt() es GLOBAL a toda la corrida de tsvy, pero un
                * bloque (`a'=`cval' [`cruce'=`sval']) chico podria no
                * tener datos justo del anio de refyear() -- svylet.ado
                * corta con error duro si se le pasa un ref() que no esta
                * entre las categorias de ESE over() especifico (correcto
                * para una llamada directa de un usuario, pero rompería
                * el loop aca). Por eso se arma `refopt_bloque' recien
                * aca, verificando PRIMERO si refcode esta presente en
                * este bloque puntual -- si no esta, se omite ref() SOLO
                * para este bloque (P_VS_REF queda missing ahi), sin
                * saltarse el resto del bloque.
                local refopt_bloque ""
                if "`refopt'" != "" {
                    quietly count if `subset' & ANIO_ == `refcode'
                    if r(N) > 0 local refopt_bloque "`refopt'"
                }

                capture noisily svylet `varname' if `subset', over(ANIO_) ///
                    stat(`stat') level(`level') denominator(`denominator') ///
                    alpha(`alpha') boot(`boot') bseed(`bseed') `refopt_bloque'
                if _rc {
                    di as err "tsvy: svylet fallo (rc=" _rc ") para " ///
                        "`a'=`cval'" cond("`cruce'"!="", " `cruce'=`sval'", "") ///
                        " -- se salta este bloque (revise si tiene al menos 2 anios con datos)"
                    local bloques_saltados = `bloques_saltados' + 1
                    continue
                }

                tempname bmat Vmat nspmat npmat limat lsmat pvsrefmat
                matrix `bmat'   = r(b)
                matrix `Vmat'   = r(V)
                matrix `nspmat' = r(n_sin_ponderar)
                matrix `npmat'  = r(n_ponderado)
                matrix `limat'  = r(ci_lower)
                matrix `lsmat'  = r(ci_upper)
                matrix `pvsrefmat' = r(p_vsref)
                local F_omni = r(F_omnibus)
                local p_omni = r(p_omnibus)
                local k_cat  = r(k_categorias)
                forvalues i = 1/`k_cat' {
                    local letra_`i'  "`r(letra_`i')'"
                    local codigo_`i' "`r(nombre_categoria_`i')'"
                }

                capture frame drop FILAS_TMP
                frame create FILAS_TMP
                frame FILAS_TMP {
                    quietly set obs `k_cat'
                    gen str12  NIVEL      = subinstr("`a'", "_", "", .)
                    gen double CATEGORIA  = `cval'
                    gen byte   ANIO       = .
                    gen double ESTIMA     = .
                    gen double ERROR_ST   = .
                    gen double LIM_INF    = .
                    gen double LIM_SUP    = .
                    gen double N_SIN_PON  = .
                    gen double N_PONDERA  = .
                    gen double F_WALD     = `F_omni'
                    gen double P_WALD     = `p_omni'
                    gen double P_MMD      = .   // v1.16 -- mmd() no soportado en el camino viejo (boot()>0)
                    gen double EFFECT_MMD = .
                    gen str5   GRUPO      = ""
                    gen double P_VS_REF   = .
                    gen str3   SIG_VS_REF = ""
                    gen byte   var        = 1
                    gen str32  VARNAME    = "`varname'"
                    if "`cruce'" != "" {
                        gen double CRUCE = `sval'
                    }

                    forvalues i = 1/`k_cat' {
                        * `codigo_`i'' es el codigo REAL de ANIO_ para esta
                        * categoria (r(nombre_categoria_i), devuelto por
                        * svylet) -- se mapea contra years() por POSICION
                        * ascendente dentro de codigos_anio, igual criterio
                        * que tabsvy: no se decodifica contra el value label
                        * de ANIO_ (mas fragil), se usa el orden cronologico
                        * que el propio usuario declaro en years().
                        local pos = 0
                        local j = 0
                        foreach code of local codigos_anio {
                            local j = `j' + 1
                            if `code' == `codigo_`i'' local pos = `j'
                        }
                        if `pos' == 0 {
                            di as err "tsvy: no se pudo mapear el codigo de ANIO_ " ///
                                "`codigo_`i'' contra codigos_anio (`codigos_anio') -- revise years()."
                            exit 498
                        }
                        local yval : word `pos' of `years'

                        quietly replace ANIO      = `yval'                    in `i'
                        quietly replace ESTIMA    = el(`bmat', `i', 1)        in `i'
                        quietly replace ERROR_ST  = sqrt(el(`Vmat', `i', `i')) in `i'
                        quietly replace LIM_INF   = el(`limat', `i', 1)       in `i'
                        quietly replace LIM_SUP   = el(`lsmat', `i', 1)       in `i'
                        quietly replace N_SIN_PON = el(`nspmat', `i', 1)      in `i'
                        quietly replace N_PONDERA = el(`npmat', `i', 1)       in `i'
                        quietly replace GRUPO     = "`letra_`i''"             in `i'
                    }
                    gen double CV = (ERROR_ST / ESTIMA) * 100
                    gen str2 REF_ = ""
                    replace REF_ = "a/" if CV > `threshold' & CV != .
                }
                frame `frame': frameappend FILAS_TMP
                capture frame drop FILAS_TMP
                local bloques_ok = `bloques_ok' + 1
            }
        }
    }

    local subpop_nota = cond(`"`subpop'"' != "", " -- subpop(`subpop')", "")
    frame `frame' {
        count
        di as text "tsvy: `frame' acumula ahora " as result r(N) as text ///
            " filas (VARNAME=`varname' STAT=`stat', " as result `bloques_ok' ///
            as text " bloques estimados, " as result `bloques_saltados' ///
            as text " saltados`subpop_nota')"
    }
end

* -------------------------------------------------------------------------
* v1.10 -- _tsvy_fila_vacia: agrega UNA fila "vacia" (todo en missing
* salvo NIVEL/CATEGORIA/[CRUCE]/var, con ANIO fijo en el primer anio de
* years() solo como ancla para que "reshape wide" tenga con que crear
* esa fila) al frame acumulador -- ver la nota v1.10 junto al
* "foreach cval of local valores_a" en el cuerpo de "program define
* tsvy" sobre por que hace falta. Vive como subprograma DENTRO de este
* mismo archivo, nunca llamado desde otro .ado: Stata registra todos
* los "program define" de un archivo al cargarlo (parsea el archivo
* entero antes de que cualquiera de sus programas se pueda invocar), asi
* que no hay riesgo de orden de carga como el que motivo que tsvy_core()
* fuera una copia propia de svylet_core() en vez de llamar al comando
* svylet (ver nota v1.4 mas abajo) -- ese riesgo es especifico de
* depender de un programa definido en OTRO archivo .ado que podria no
* estar cargado todavia, no aplica a un subprograma del mismo archivo.
* -------------------------------------------------------------------------
capture program drop _tsvy_fila_vacia
program define _tsvy_fila_vacia
    syntax, NIVEL(string) CATEGORIA(string) ANIO(string) FRAME(string) VARNAME(string) [CRUCE(string)]
    capture frame drop FILAS_TMP
    frame create FILAS_TMP
    frame FILAS_TMP {
        quietly set obs 1
        gen str12  NIVEL      = "`nivel'"
        gen double CATEGORIA  = `categoria'
        * -- v1.11 -- "gen byte ANIO = `anio'" (un solo paso, con el
        * literal ya adentro del generate) dejaba ANIO en missing: Stata
        * respeta el tipo "byte" declarado LITERALMENTE en el generate
        * (rango -127..100) y un anio como 2023 no entra ahi -- a
        * diferencia de "gen byte ANIO = . " + replace ANIO = 2023"
        * (el patron que ya usa el resto de este archivo, ver mas abajo
        * en el cuerpo de "program tsvy"), donde el "replace" sobre una
        * variable YA EXISTENTE si amplia el tipo de almacenamiento
        * (byte -> int) para que el valor entre. Mismo patron ahora aca.
        gen byte   ANIO       = .
        replace    ANIO       = `anio'
        gen double ESTIMA     = .
        gen double ERROR_ST   = .
        gen double LIM_INF    = .
        gen double LIM_SUP    = .
        gen double N_SIN_PON  = .
        gen double N_PONDERA  = .
        gen double F_WALD     = .
        gen double P_WALD     = .
        gen double P_MMD      = .
        gen double EFFECT_MMD = .
        gen str5   GRUPO      = ""
        gen double P_VS_REF   = .
        gen str3   SIG_VS_REF = ""
        gen byte   var        = 1
        gen str32  VARNAME    = "`varname'"
        if "`cruce'" != "" {
            gen double CRUCE = `cruce'
        }
        gen double CV = .
        gen str2   REF_ = ""
    }
    frame `frame': frameappend FILAS_TMP
    capture frame drop FILAS_TMP
end

* -------------------------------------------------------------------------
* v1.4 -- tsvy_core(): copia PROPIA (autosuficiente, ver nota junto al
* "foreach a of local nivel" en el cuerpo de "program define tsvy") del
* motor F omnibus + Bonferroni + Compact Letter Display de svylet.ado
* (svylet_core(), en svylet.ado). Debe vivir ACA, a nivel de archivo
* (fuera de cualquier "program define"), porque Mata no permite
* compilar una definicion de funcion dentro del cuerpo de un programa
* Stata (r(9611) si se intenta). Si el motor de svylet_core() cambia,
* replicar el cambio aca tambien.
* -------------------------------------------------------------------------
version 14
* "capture" ACA (a nivel Stata, antes de entrar al bloque mata:), no
* adentro del bloque -- un "mata drop" de una funcion que todavia no
* existe (la PRIMERA vez que este archivo se carga en la sesion) tira
* error, y adentro del bloque mata: ese error no lo atrapa ningun
* "capture" (ya se dejo de estar en modo Stata) -- cortaria la carga
* del archivo antes de llegar siquiera a la definicion de la funcion.
capture mata: mata drop tsvy_core()
mata:

void tsvy_core(string scalar bname, string scalar Vname, real scalar df,
                real scalar alpha, real scalar k)
{
    real matrix b, V, R, RVR, Pmat
    real scalar stat_wald, Fstat, p_omni, i, j, npares, t, se, p_raw, p_adj
    real scalar k_dim, df_ajustado, k_valida
    real colvector idx_validas, b_valida
    real matrix V_valida

    b = st_matrix(bname)
    V = st_matrix(Vname)

    real colvector var_degenerada
    var_degenerada = J(k,1,0)
    for (i=1; i<=k; i++) {
        if (missing(V[i,i]) | V[i,i] <= 0) var_degenerada[i] = 1
    }
    if (sum(var_degenerada) > 0) {
        printf("{txt}Aviso: varianza no definida (o cero) en %g de %g categorias" +
               " -- probablemente una proporcion exactamente 0 o 1 sin variabilidad.\n",
               sum(var_degenerada), k)
        printf("{txt}  Categorias afectadas (indice dentro de over(), no el valor): ")
        for (i=1; i<=k; i++) {
            if (var_degenerada[i]==1) printf("%g ", i)
        }
        printf("\n{txt}  Sus letras se muestran como [?] -- NO tratar como" +
               " sin diferencia, el test no se pudo calcular ahi.\n")
    }

    // v1.6 -- FIX (replicado de svylet_core() en svylet.ado, ver ese
    // archivo para el detalle): R se armaba con las k categorias
    // COMPLETAS, asi que UNA sola categoria de varianza degenerada
    // (proporcion exactamente 0 o 1) propagaba "." por R*V*R' y anulaba
    // el F omnibus ENTERO via lusolve(), aun con el resto de categorias
    // perfectamente calculables -- confirmado en produccion (tabulado
    // real de tsvy: filas con 4/4 anios con Estimacion, pero F en blanco
    // porque 1-3 de esos anios eran exactamente 0%). Ahora se calcula
    // sobre el SUBCONJUNTO de categorias con varianza definida, minimo 2
    // para poder testear una igualdad. Con 0 degeneradas, idx_validas es
    // 1..k y el resultado es identico al de v1.5.
    idx_validas = select((1::k), var_degenerada :== 0)
    k_valida = rows(idx_validas)
    if (k_valida >= 2) {
        b_valida = b[idx_validas]
        V_valida = V[idx_validas, idx_validas]
        k_dim = k_valida - 1
        R = J(k_dim, k_valida, 0)
        for (i=2; i<=k_valida; i++) {
            R[i-1,1] = -1
            R[i-1,i] = 1
        }
        RVR = R*V_valida*R'
        stat_wald = (R*b_valida)' * lusolve(RVR, R*b_valida)
        df_ajustado = df - k_dim + 1
        Fstat = (df_ajustado / (k_dim * df)) * stat_wald
        p_omni = 1 - F(k_dim, df_ajustado, Fstat)
        if (k_valida < k) {
            printf("{txt}  F omnibus calculado con %g de %g categorias" +
                   " (las de varianza degenerada quedan afuera del" +
                   " contraste, no del reporte -- sus puntos siguen" +
                   " listados, su letra queda en [?]).\n", k_valida, k)
        }
    }
    else {
        k_dim = .
        df_ajustado = .
        Fstat = .
        p_omni = .
        printf("{txt}  F omnibus no calculable: menos de 2 categorias" +
               " con varianza definida (%g de %g).\n", k_valida, k)
    }

    npares = k*(k-1)/2
    Pmat = J(k,k,.)
    for (i=1; i<=k-1; i++) {
        for (j=i+1; j<=k; j++) {
            if (var_degenerada[i]==1 | var_degenerada[j]==1) {
                p_adj = .
                Pmat[i,j] = p_adj
                Pmat[j,i] = p_adj
                continue
            }
            se = sqrt(V[i,i] + V[j,j] - 2*V[i,j])
            if (se > 0) {
                t = (b[j]-b[i]) / se
                p_raw = 2*ttail(df, abs(t))
                p_adj = min((p_raw*npares, 1))
            }
            else {
                p_adj = 1
            }
            Pmat[i,j] = p_adj
            Pmat[j,i] = p_adj
        }
    }

    string colvector letra_grupo
    letra_grupo = J(k,1,"")
    real scalar total_subsets, s, bitpos, ok, contenido, letra_idx, g
    real colvector miembros
    real matrix subsets_validos, maximales
    string scalar letra_actual
    subsets_validos = J(0, k, .)

    total_subsets = 2^k - 1
    for (s=total_subsets; s>=1; s--) {
        miembros = J(k,1,0)
        for (bitpos=1; bitpos<=k; bitpos++) {
            if ( mod(floor(s / 2^(bitpos-1)), 2) == 1 ) miembros[bitpos] = 1
        }
        if (sum(miembros) < 1) continue
        ok = 1
        for (i=1; i<=k & ok; i++) {
            if (miembros[i]==1 & var_degenerada[i]==1) {
                ok = 0
                break
            }
        }
        if (ok==0) continue
        for (i=1; i<=k & ok; i++) {
            if (miembros[i]==0) continue
            for (j=i+1; j<=k; j++) {
                if (miembros[j]==0) continue
                if (Pmat[i,j] < alpha) {
                    ok = 0
                    break
                }
            }
        }
        if (ok==1) subsets_validos = subsets_validos \ miembros'
    }

    maximales = J(0,k,.)
    for (s=1; s<=rows(subsets_validos); s++) {
        contenido = 0
        for (i=1; i<=rows(subsets_validos); i++) {
            if (i==s) continue
            if (all(subsets_validos[s,] :<= subsets_validos[i,]) &
                sum(subsets_validos[s,]) < sum(subsets_validos[i,])) {
                contenido = 1
                break
            }
        }
        if (contenido==0) maximales = maximales \ subsets_validos[s,]
    }

    letra_idx = 0
    for (g=1; g<=rows(maximales); g++) {
        letra_idx++
        letra_actual = char(96 + letra_idx)
        for (i=1; i<=k; i++) {
            if (maximales[g,i]==1) letra_grupo[i] = letra_grupo[i] + letra_actual
        }
    }

    for (i=1; i<=k; i++) {
        if (var_degenerada[i]==1) letra_grupo[i] = "?"
    }

    st_numscalar("r(F_omnibus)", Fstat)
    st_numscalar("r(p_omnibus)", p_omni)
    st_numscalar("r(n_pares)", npares)
    st_matrix("r(b)", b)
    for (i=1; i<=k; i++) {
        st_global("r(letra_"+strofreal(i)+")", letra_grupo[i])
    }
}
end
