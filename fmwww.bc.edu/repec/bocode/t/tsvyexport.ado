*! tsvyexport.ado v1.37 - 23nov2026
*! v1.37 -- Leyenda del Word (wide) reescrita: tildes y enie reales (via
*! uchar(), el .ado sigue en ASCII), "Grupos (Bonferroni)" sin la frase
*! "salvo indicacion entre parentesis" cuando ninguna fila uso otro
*! metodo, "? indica..." solo si hay algun "?", y "Sig. (por anio)" solo
*! si SIG_VS_REF tiene datos (refyear()) y con el texto correcto (ese
*! anio contra el anio de referencia, no "categoria de referencia").
*! Encabezados Categoria/Estimacion y "Elaboracion:" con tilde.
*! v1.36 -- FIX: wide()+Word con 2+ VARNAME cortaba con "not sorted"
*! r(5) (by NIVEL CATEGORIA: despues de un gsort). CATFIRST/CATN y
*! CRUFIRST/CRUN se calculan ahora con bysort (__ORD) y se restaura el
*! orden del gsort, conservando NACIONAL primero. Limpieza: comilla de
*! mas en `varnombres', comentario DEBUG huerfano de v1.28.
*! CONFIRMADO contra Stata real (23nov2026): wide()+Word con 2 VARNAME
*! (mpg, weight) x nivel(NACIONAL foreign) sobre auto.dta corre limpio.
*! v1.35 -- FIX: fuente()/elaboracion() vaciaban `using' (el syntax
*! anidado reescribia los locales del syntax principal) y tsvyexport
*! cortaba con "no se pudo determinar el formato". Se parsean ahora en
*! el subprograma _tsvyexport_txtopt. Se quitan los 2 DEBUG de using.
*! v1.34 -- FIX: SIG_WALD (wide) y la leyenda de Sig. solo usan niveles
*! <= alpha de tsvy (char _dta[tsvy_alpha], 0.05 por defecto). Antes un
*! P_WALD entre 0.05 y 0.10 salia "*" junto a GRUPOS "a-a-a" (letras al
*! 5%), que se leia como contradictorio. Con alpha(0.10) en tsvy se
*! mantiene el "*" de p<0.10.
*! v1.34 -- F de Wald significativo con letras iguales: columna nueva
*! CLD_INCONS (1 = P_WALD < alpha y todos los anios con la misma letra),
*! GRUPOS lleva la llamada " b/" en esas filas y el Word la explica en
*! la leyenda. Si el frame trae CLD_METODO (tsvy v1.29+) y cldmetodo(auto)
*! uso mas de un metodo, GRUPOS indica el metodo entre parentesis.
*! Autor: Andres Talavera Cuya
*!
*! v1.33 -- BUG REAL (v1.32 fallo en Stata real): "option width(.8125)
*! not allowed" en el `putdocx table tbl(.,.), width()' que v1.32 agrego
*! para repartir el ancho entre columnas. Causa, confirmada con la
*! sintaxis real de putdocx table (el usuario pego `help putdocx table'
*! completo): width() para ancho de columna es un row_col_option, valido
*! SOLO en la forma tablename(., j) (una columna puntual) -- nunca en
*! tablename(.,.) (bloque, todas las columnas de una), que solo acepta
*! cell_fmt_options (sin width() en esa lista). Fix real: loop
*! `forvalues j = 1/ncols' llamando tbl(., `j'), width(...)' una
*! columna a la vez -- mismo reparto de 6.5in que v1.32 ya calculaba
*! bien, solo cambia COMO se aplica. De paso se agrega layout(fixed) a
*! la creacion de la tabla (table_option de putdocx table): el default
*! es layout(autofitwindow), que reajusta las columnas solas al ancho
*! de la ventana y podria pisar los width() explicitos de mas abajo.
*! SIN CONFIRMAR CONTRA STATA REAL TODAVIA.
*!
*! v1.32 -- Pedido del usuario ("el diseno sale un poco grande", con un
*! .docx real de wide()+estilo("apa7") y 10-12 anios adjunto): cada
*! columna de `putdocx table' nace con ancho FIJO (1170 twips=0.81in),
*! sin importar cuantas columnas tenga la tabla -- con pocas columnas
*! (hasta 8, el caso original de pocos anios) eso da justo 6.5in (el
*! ancho util de una pagina carta con margenes de 1in) y encajaba bien
*! por casualidad; con mas anios se iba mucho mas alla de la pagina,
*! celdas angostas, texto envuelto, tabla visualmente enorme -- se ve
*! clarito en las imagenes que mando el usuario (Tabla 2/3, 10-12
*! anios, "25,\n0" partido en 2 lineas, Grupos con 5+ lineas apiladas).
*! Fix: justo despues de crear la tabla (las 2 ramas de wide()+Word, 1
*! VARNAME y 2+), reparte 6.5in en partes iguales entre las columnas
*! con `putdocx table tbl(.,.), width()' -- ANTES de cualquier fusion
*! rowspan/colspan (mismo motivo de orden que v1.24 con border(all,
*! nil): un rango en bloque tipo tbl(.,.) solo es seguro antes de que
*! exista fusion que barrer). Con muchos anios (10-12) las columnas
*! siguen siendo angostas (es aritmetica: 6.5in entre 14-16 columnas),
*! pero la tabla ya no se sale de la pagina. SIN CONFIRMAR CONTRA STATA
*! REAL TODAVIA.
*!
*! v1.31 -- Bug real encontrado corriendo ejemplo_tsvyexport_comparacion_
*! metodos.do (caso extremo A, frame armado a mano con `input' en vez de
*! con tsvy): wide()+Word tiraba "not sorted" r(5) en el `reshape wide'.
*! Causa: el `reshape' corre sobre el frame tal cual llega -- con datos
*! de tsvy (via frameappend/append) el orden resultaba sorteado por
*! casualidad, pero no era una garantia; un frame armado en cualquier
*! otro orden rompia. Fix: `sort `idvars' ANIO' explicito justo antes
*! del reshape. De paso se documento (sin tocarlo, por el riesgo de
*! romper el orden NACIONAL-primero) un bug latente parecido en la rama
*! Word de 2+ VARNAME (`by NIVEL CATEGORIA:' despues de un `gsort' --
*! gsort nunca deja la bandera de "ordenado" que `by' sin bysort exige,
*! asi que esa rama tira el mismo error la primera vez que se use con
*! datos reales).
*!
*! v1.30 -- Pedido del usuario: la leyenda de Grupos debajo del cuadro
*! exportado ("Grupos: anios con la misma letra...") ahora muestra
*! entre parentesis el metodo de ajuste que uso cldmetodo() (tsvy
*! v1.24+) -- "Grupos (Holm): ...", "Grupos (Fisher LSD): ...", etc. --
*! leido de la characteristic _dta[tsvy_cldmetodo] que tsvy v1.29+ deja
*! en el frame (ver nota junto a la copia de trabajo, mas abajo). Con
*! un frame de una version vieja de tsvy (sin esa characteristic) la
*! leyenda sale exactamente igual que siempre, sin el parentesis -- no
*! rompe nada retroactivamente. SIN CONFIRMAR CONTRA STATA REAL
*! TODAVIA.
*!
*! v1.29 -- Pedido del usuario: el preset estilo("inei") se renombra a
*! estilo("clasico") -- mismo formato exacto (Arial Narrow, 10/8/8/7pt),
*! solo cambia el nombre. "inei" ya NO es un valor aceptado (rompe
*! codigo viejo que lo use -- cambio deliberado, no retrocompatible).
*! apa7/revista sin cambios.
*!
*! v1.28 -- SIN DIAGNOSTICAR TODAVIA, pero ACOTADO con datos reales: "no
*! se pudo determinar el formato" (r198) reportado 2 veces
*! (ejemplo_cuadro_sierra.do, Example 8 sobre cuadro_categorias.docx),
*! y el log completo de la segunda corrida lo acota fuerte -- el MISMO
*! archivo (cuadro_categorias.docx), el MISMO `using', corre bien en
*! Example 6 y 7 (sin fuente()/elaboracion()) y falla justo en Example
*! 8, que agrega fuente()+elaboracion() sin cambiar nada mas. Hipotesis:
*! los 2 unicos bloques que hacen `local 0 ...' + `syntax' anidado (la
*! suboption tamano() de fuente()/elaboracion(), v1.19) corrompen de
*! algun modo `using' antes de que el bloque de deteccion de formato lo
*! lea -- aun sin encontrar el mecanismo exacto en el codigo (usan
*! locales propios, `anything'/`tamano', que en teoria no deberian
*! tocar `using'). Cambios mientras tanto, todos de diagnostico: (1) un
*! `di' nuevo justo despues del bloque de fuente()/elaboracion() que
*! muestra `using' en ese punto -- bisecta si el problema es ESE bloque
*! o algo mas abajo; (2) el mensaje de error final tambien imprime
*! `using'/`ext' exactos; (3) `using' se envuelve en comillas compuestas
*! al armar `ext', por si el nombre de archivo trajera una comilla
*! literal. Nada de esto es el fix todavia -- correr Example 8 solo (ya
*! con v1.28 cargado) y mandar el log completo, con los 2 DEBUG nuevos,
*! antes de intentar una correccion real.
*!
*! v1.27 -- BUG REAL, causa de fondo encontrada (cuarta vuelta -- v1.24,
*! v1.25 y v1.26 estaban los 3 mirando el sintoma equivocado): con
*! datos reales (ejemplo_cuadro_apa7.do) el .docx seguia mostrando
*! Var.%/Sig./Grupos sin sombreado Y grilla completa (lineas
*! verticales) en vez de la tabla de 3 lineas, INCLUSO con v1.26 (sin
*! ningun border(all,nil) en bloque, `which tsvyexport' confirmo que
*! esa version SI estaba cargada). Causa real: el propio archivo ya
*! documentaba desde v1.8 que un colspan() corre la direccion de
*! columna de las celdas a SU DERECHA en esa misma fila -- pero esa
*! regla solo se aplicaba a la FUSION (Paso B: rowspan() antes,
*! colspan() al final, v1.11), nunca al FORMATO (Paso C), que quedaba
*! en un paso APARTE corrido siempre despues de TODOS los colspan() de
*! la fila. El colspan(`nyears') de Estimacion (columna 2) corre las
*! direcciones de Var.%/Sig./Grupos (las 3 columnas de rowspan puro a
*! su derecha); Paso C las formateaba con su direccion ORIGINAL, ya
*! vieja para ese momento -- terminaba pintando (o poniendo
*! border(all,nil) en) la celda fisica equivocada. Categoria (a la
*! izquierda del colspan) y Estimacion (el propio destino del
*! colspan, cuya direccion no cambia) por eso SI salian bien -- calza
*! exacto con el patron reportado las 3 veces (v1.24/v1.25/v1.26), con
*! y sin border() de por medio: border(all,nil) en bloque (el sintoma
*! que se persiguio esas 3 veces) era un SEGUNDO bug real pero
*! secundario, que tapaba este primero. Mismo problema en las 2 ramas
*! (1 VARNAME y 2+, esta ultima via `hdrcols' + colspan() de anio).
*! Fix: se elimina el Paso C separado -- cada celda de rowspan puro
*! (encabezado) o colspan (Estimacion/anio) ahora lleva su rowspan()/
*! colspan() y su `hdr' (formato) juntos, en la MISMA dupla de
*! llamadas, en el momento en que su direccion todavia es valida
*! (antes de que corra cualquier colspan() a su izquierda en esa
*! fila). test_putdocx_merge.do trae una Prueba 15 nueva que aisla
*! exactamente este mecanismo (formato inmediato vs. diferido despues
*! de un colspan() posterior) para confirmar contra Stata real antes
*! de dar esto por cerrado.
*!
*! v1.26 -- BUG REAL (tercera vuelta, reportado con datos reales sobre
*! Prueba 14): el fix de v1.25 (border(all,nil) DESPUES de la fusion,
*! ANTES del formato) TAMPOCO alcanzo -- Var.% seguia sin sombreado.
*! v1.24 y v1.25 solo cambiaban CUANDO corria el barrido en bloque
*! (tbl(.,.)); el problema real es el barrido en bloque EN SI. El
*! propio archivo ya lo advertia desde v1.5 (ver el comentario donde se
*! crea la tabla del encabezado, mas abajo): "nunca con un rango en
*! bloque tipo tbl(1/2,.) o tbl(.,.) -- esos rangos barren tambien
*! direcciones que una fusion ya elimino, y ningun ejemplo real
*! encontrado hace eso". border(all,nil) sobre tbl(.,.) rompia
*! justamente esa regla, sin importar en que momento se llamara.
*! Fix real: se elimina el barrido en bloque por completo. border(all,
*! nil) para apa7/revista ahora se agrega DENTRO de `hdr'/`ocuerpo_bare'/
*! `ocuerpo_new' (los mismos locales que ya arman font()/tamano() para
*! estilo(), ver mas abajo) -- queda seteado en la MISMA llamada
*! individual que pone el sombreado de cada celda (las mismas
*! direcciones ya usadas y confirmadas en Paso C/Paso D), nunca en un
*! paso aparte con tbl(.,.). Las 3 lineas puntuales de la "tabla de tres
*! lineas" (top de fila 1, bottom de fila 2, bottom de la ultima fila)
*! se siguen agregando al final, sin cambios -- esas SI usan rango por
*! fila (tbl(1,.), etc.) pero solo AGREGAN un borde, nunca limpian
*! nada, y esa mecanica ya esta confirmada (Prueba 13). Prueba 14 de
*! test_putdocx_merge.do actualizada para reflejar el patron real (sin
*! ningun border(all,nil) en bloque).
*!
*! v1.25 -- BUG REAL (segunda vuelta, Prueba 14 corrida en Stata real):
*! el fix de v1.24 (mover border(all,nil) a justo despues de crear la
*! tabla, ANTES de la fusion rowspan/colspan) genero un bug DISTINTO --
*! con ese orden, Var.% (la columna pegada a la derecha del colspan()
*! de Estimacion) se quedaba sin sombreado, mientras Categoria/Sig.
*! si lo tenian. Causa: el mismo patron de "el direccionamiento de
*! columna se corre despues de un colspan() aplicado en esa fila"
*! documentado en v1.8 -- pero esta vez aplicado a un barrido en bloque
*! (border(all,nil) sobre tbl(.,.)) hecho ANTES de que el colspan()
*! existiera, corriendo sobre la grilla ORIGINAL en vez de la grilla ya
*! fusionada. Fix definitivo: border(all,nil) va DESPUES de la fusion
*! (Paso B: rowspan y colspan ya aplicados, grid en su forma final) pero
*! ANTES del formato (Paso C: shading/bold) -- ni pisa formato que
*! todavia no existe (el bug de v1.21-v1.23), ni corre el
*! direccionamiento de columnas que un colspan() posterior iba a mover
*! (el bug de v1.24). Prueba 14 de test_putdocx_merge.do actualizada
*! para reproducir el patron real (rowspan puro + colspan + shading) y
*! confirmar este orden.
*!
*! v1.24 -- BUG REAL (reportado con datos reales, ejemplo_cuadro_apa7.do
*! sobre el cuadro sierra): en estilo("apa7"), las columnas del
*! encabezado con rowspan(2) puro (Var.%, Sig., Grupos) se quedaban SIN
*! el sombreado azul (D9E2F3) del encabezado, mientras que las que
*! tienen colspan (Categoria, Estimacion) SI lo conservaban -- una
*! inconsistencia visual real que el usuario detecto en el .docx
*! generado. Causa: border(all,nil) (el barrido que limpia la grilla
*! para armar la "tabla de tres lineas") se aplicaba al FINAL, DESPUES
*! de que el encabezado ya tenia su shading()/bold puestos -- ese
*! barrido en bloque sobre tbl(.,.) le borraba el sombreado a las
*! celdas de rowspan puro pero no a las de colspan (efecto secundario
*! de putdocx, no algo documentado). Fix: border(all,nil) ahora se
*! aplica INMEDIATAMENTE despues de crear la tabla (tbl = (nrows,ncols)),
*! antes de poner ningun contenido, fusion o formato -- asi nunca puede
*! borrar algo que todavia no existe. Las 3 lineas puntuales (top de
*! fila 1, bottom de fila 2, bottom de la ultima fila) se siguen
*! poniendo al final, como antes, porque esas SI necesitan que
*! `nrows' este definido y no tocan shading. Prueba 14 nueva en
*! test_putdocx_merge.do aisla exactamente el patron shading()+rowspan/
*! colspan mixto+border(all,nil) para confirmar el fix.
*!
*! v1.23 -- BUG REAL (segunda corrida real de test_putdocx_merge.do,
*! Prueba 13): el fix de v1.22 (fontsize(#) -> size(#)) SIGUIO fallando
*! -- "option size(12) not allowed", rc=198, en el mismo llamado.
*! Confirmado con help putdocx text/paragraph (pegado por el usuario):
*! putdocx NO tiene una opcion size() aparte -- font() es UNA sola
*! opcion combinada, fspec = "fontname [, size [, color]]" (ej.
*! font("Times New Roman", 12), no font("Times New Roman") size(12)).
*! Para fijar SOLO el tamano sin cambiar la fuente, la sintaxis es
*! font("", tamano) (fontname vacio) -- exactamente lo que necesitaba
*! tamano() de fuente()/elaboracion() (v1.19), que no depende de
*! estilo(). Con esta version, `estfont' vacio (sin estilo()) mas
*! font("`estfont'", `ftam'') hace justamente eso. Fix aplicado en
*! TODOS los llamados de titulo/encabezado/cuerpo/notas/fuente/
*! elaboracion que antes armaban font()+size() por separado. Mismo
*! alcance que v1.22: estas llamadas fallaban con error apenas se
*! ejecutaban, nunca generaron un .docx con el tamano mal aplicado en
*! silencio.
*!
*! CONFIRMADO (tercera corrida real, con font(nombre,tamano)): Prueba 13
*! de test_putdocx_merge.do paso limpio (rc=0, 10/13 OK). El .docx SI
*! mostraba la linea de "tabla de tres lineas" en el lugar equivocado a
*! primera vista, pero 6 diagnosticos aislados (columna unica, 2
*! columnas, celdas en blanco, font()/bold/halign por celda, titulo con
*! parrafos antes de la tabla, y una replica exacta linea por linea de
*! la Prueba 13) reprodujeron TODOS la posicion correcta de los bordes
*! -- la causa real era Word mostrando una version vieja del .docx
*! (ventana abierta de una corrida anterior, con el bug de fontsize()/
*! size(), que nunca recargo el archivo nuevo del disco). Cerrar esa
*! ventana y volver a abrir el archivo lo confirmo: border(all,nil) +
*! border(top/bottom,single) por rango de fila, combinado con
*! font(nombre,tamano), queda confirmado funcionando en Stata real.
*! estilo("apa7")/estilo("revista") son confiables con datos reales.
*!
*! v1.22 -- BUG REAL (primera corrida real de test_putdocx_merge.do con
*! la Prueba 13 nueva de v1.21): "option fontsize(12) not allowed",
*! rc=198, en el PRIMER llamado que usaba esa opcion. La opcion de
*! putdocx text/table para el tamano de letra es size(#), NO fontsize(#)
*! -- v1.19 (tamano() de fuente()/elaboracion()) y v1.21 (estilo())
*! inventaron "fontsize()" sin confirmarlo contra Stata real, y la
*! primera vez que se probo (Prueba 13) fallo de entrada. Fix: todas las
*! llamadas a size()/`onota_bare'/`ocuerpo_bare'/etc. que armaban
*! "fontsize(#)" ahora arman "size(#)" -- mismo comportamiento buscado,
*! nombre de opcion corregido. Afecta CUALQUIER uso de tamano() dentro de
*! fuente()/elaboracion() (v1.19) y de estilo() (v1.21) hecho antes de
*! esta version: esas llamadas fallaban con rc=198 apenas se ejecutaban,
*! asi que no hay riesgo de haber generado un .docx con el tamano
*! ignorado en silencio -- paraban con error.
*!
*! v1.21 -- Opcion nueva estilo() para wide()+Word: preset de formato
*! (fuente + tamanos + bordes), investigado con 2 agentes en paralelo
*! porque el manual del INEI no especifica ninguna tipografia (ver
*! comentario junto a la definicion de estilo() mas abajo para el
*! detalle completo de cada preset y sus fuentes).
*!   - estilo("clasico"): Arial Narrow, 10/8/8/7pt (titulo/encabezado/
*!     cuerpo/notas) -- respaldado por el Manual de Estilo del INDEC.
*!   - estilo("apa7"): Times New Roman, 12pt, tabla de tres lineas
*!     (bordes SOLO arriba/bajo encabezado/al final, nunca verticales),
*!     titulo en formato APA real ("Tabla N" en negrita + titulo en
*!     cursiva en lineas separadas, no el "numero MAYUSCULAS" de INEI).
*!   - estilo("revista"): generico para revistas indexadas no-APA,
*!     misma tabla de 3 lineas, Times New Roman, tamanos un poco
*!     menores (9-11pt).
*!   - sin estilo() (default): SIN CAMBIOS -- exactamente el
*!     comportamiento de v1.20 (fuente/tamano de Word por defecto, grilla
*!     completa de bordes). Retrocompatible: cada llamado de formato
*!     nuevo se arma con locales que quedan vacios cuando estilo()=="",
*!     asi que no hay NADA que agregar a ningun putdocx existente.
*! El default de tamano() dentro de fuente()/elaboracion() (v1.19) ahora
*! sigue el preset (7/10/9pt en vez de 9pt fijo) cuando hay estilo(); un
*! tamano(#) explicito del usuario sigue ganando siempre.
*! MECANICA SIN CONFIRMAR EN STATA REAL: border(all,nil) sobre tbl(.,.)
*! para borrar la grilla, seguido de border(top/bottom,single) por rango
*! de fila -- Prueba 13 nueva en test_putdocx_merge.do la aisla; correrla
*! antes de confiar en estilo("apa7")/estilo("revista") con datos reales.
*! El resto (font()/size() en celdas ya formateadas con bold/shading/
*! halign) reusa opciones de putdocx ya validadas en este mismo archivo.
*!
*! v1.20 -- BUG REAL (reportado por el usuario con datos de poblacion,
*! ejemplo census.dta): con ESTIMA de varios millones, las celdas de
*! wide()+Word salian mezcladas ("3,40e+06" en vez de "3 401 234,00").
*! Causa: `estfmt' formateaba con ancho fijo %9.Nf -- "3400000.00" ya
*! son 10 caracteres, mas de lo que entra en un ancho de 9, asi que
*! Stata's string() caia a notacion cientifica ("3.40e+06") para que
*! entrara; _tsvyexport_numes() solo sabe separar "intpart.decpart"
*! corriente, no reconoce el "e+06", y terminaba devolviendo la mezcla
*! rota que se vio en pantalla. Fix: ancho 20 en vez de 9 (para ESTIMA
*! y para VARPCT) -- alcanza para cualquier magnitud realista sin forzar
*! notacion cientifica; _tsvyexport_numes ya recorta el padding de mas
*! con strtrim(), asi que el ancho mayor no cambia nada para numeros
*! chicos.
*!
*! v1.19 -- Apegado al manual del INEI ("Manual para la presentacion de
*! cuadros estadisticos"), 2 puntos concretos que faltaban:
*!   1. Simbolos de casilla (p.25): ESTIMA missing -> "..." ("no
*!      disponible" -- ASCII "..." en vez del caracter unicode real de
*!      elipsis, por la convencion ASCII-puro de este archivo); ESTIMA
*!      exactamente 0 -> "-" ("magnitud cero"); ESTIMA != 0 pero redondea
*!      a 0 con los decimales de digits() -> "0" sin decimales ("la
*!      cantidad no alcanza a la mitad de la unidad"). Mismo tratamiento
*!      en las 2 ramas de wide()+Word (1 VARNAME y 2+). VARPCT missing
*!      (denominador 0 o missing) tambien usa "..." -- no aplica la
*!      distincion cero/media-unidad, que es propia de cifras de nivel,
*!      no de porcentajes de variacion.
*!   2. Pie del cuadro (p.26-27): opciones nuevas fuente()/elaboracion()
*!      -- cuando se pasan, agregan las lineas "Fuente: ..." y
*!      "Elaboracion: ..." despues de la leyenda de Sig./Grupos (el
*!      manual pide ese orden: notas, llamadas, fuente, elaboracion).
*!      Opcionales: sin pasarlas, el cuadro sale igual que siempre. Cada
*!      una acepta una suboption tamano(#) (entero, default 9, puntos)
*!      para el tamano de letra de ESA linea -- ej. fuente("INEI - ...",
*!      tamano(9)) -- en vez de una opcion tamano() aparte a nivel de
*!      tsvyexport, para poder usar tamanos distintos en fuente() y
*!      elaboracion() si hiciera falta.
*!
*! v1.18 -- BREAKING CHANGE en wide()+Word: Var.% ahora es el ULTIMO
*! anio contra el ANTERIOR (ej. "Var. % 2026/2025"), no el primer anio
*! contra el ultimo de toda la serie (hasta v1.17, "Var. % 2026/2023").
*! Es la definicion estandar de estadistica oficial (INEI, BCRP, etc.
*! siempre la usan anio-contra-anio-anterior) -- pedido del usuario tras
*! comparar contra un cuadro real. Fijo, sin opcion nueva: no hay caso
*! de uso real para la definicion vieja (cambio acumulado de toda la
*! serie), asi que no se agrego una opcion para elegir entre las dos.
*! Sin cambio con exactamente 2 anios (ahi "primero" y "anterior" son
*! el mismo anio).
*!
*! v1.17 -- Cuando CATEGORIA_LBL tiene texto, el rotulo "Categoria" va
*! SOLO ese texto (ej. "Puno"), sin anteponer NIVEL (ej. "departamento
*! Puno" -- lo que hacia v1.16). Pedido del usuario: el nombre de la
*! variable de nivel() no aporta nada junto al nombre real de la
*! categoria, y salia repetido en cada fila. Sin cambio cuando NO hay
*! CATEGORIA_LBL (o esta en blanco para esa fila): sigue "NIVEL numero",
*! igual que siempre.
*!
*! v1.16 -- Usa CATEGORIA_LBL/CRUCE_LBL (texto real de la categoria, ej.
*! "Puno") en vez del codigo numerico puro de CATEGORIA/CRUCE, cuando el
*! frame las trae -- columnas nuevas de tsvy.ado v1.21, opcionales
*! (frames armados con una version anterior de tsvy no las tienen, y
*! tsvyexport sigue mostrando el codigo numerico en ese caso, igual que
*! siempre). Afecta el rotulo "Categoria" de wide()+Word (las dos
*! ramas, 1 VARNAME y 2+) y la columna "Cruce" de la rama de 2+ VARNAME.
*! Si CATEGORIA_LBL/CRUCE_LBL esta en blanco para una fila puntual
*! (categoria sin etiqueta definida en el dataset original), esa fila
*! cae de nuevo al codigo numerico -- nunca una celda vacia.
*!
*! v1.15 -- El total (NIVEL == "NACIONAL") va PRIMERO, no ultimo. Pedido
*! del usuario al comparar contra un cuadro real del INEI (Cuadro N 01,
*! SIERRA: superficie registrada segun departamento) -- ese cuadro, como
*! los ejemplos del Anexo 6 del manual ("Departamento: Total / Amazonas
*! / ..."), siempre lista el Total antes que las categorias que lo
*! componen. Hasta v1.14 el orden de filas dependia de lo que dejara
*! reshape wide (en la practica, NIVEL/CATEGORIA alfabetico/numerico
*! ascendente -- NACIONAL podia salir en cualquier posicion, no
*! necesariamente al final, pero nunca garantizado primero). v1.15 arma
*! una bandera __NACPRIMERO = (NIVEL=="NACIONAL") justo despues del
*! reshape y ordena con gsort (-__NACPRIMERO NIVEL CATEGORIA ...) --
*! afecta wide() a Excel y a Word por igual, con 1 VARNAME o con 2+.
*!
*! v1.14 -- HALLAZGO REAL (primera corrida de test_putdocx_merge.do,
*! Pruebas 1-10, StataNow 19.5): 7 de 10 OK. Confirmado de nuevo el
*! orden rowspan-antes-que-colspan (v1.11). Pero aparecio un problema
*! DISTINTO: Prueba 8 (encabezado de 3 niveles) y Prueba 10 (rowspan
*! anidado de cuerpo) fallaron las dos en el MISMO punto -- el 2do
*! colspan() de una fila que ya tenia OTRO colspan() aplicado antes,
*! cuando ese 2do colspan() llega hasta el borde derecho original de la
*! fila. La Prueba 7 (tambien con 2 colspan() en una fila) SI paso,
*! porque su 2do colspan() no llegaba a tocar ese borde. La aritmetica
*! cuadra en los 3 casos si putdocx recorta el "ancho valido" de la
*! fila en (span-1) por cada colspan() ya aplicado en ella -- un
*! colspan() posterior tiene que caer DENTRO de ese ancho ya recortado,
*! no del ancho original. El orden que evita esto: aplicar los colspan()
*! de una misma fila de DERECHA A IZQUIERDA (el que llega mas lejos
*! primero, cuando la fila todavia esta intacta). v1.14 invierte asi el
*! loop de colspan() por anio en la rama de 2+ VARNAME (unica parte del
*! .ado con mas de 1 colspan() en la misma fila).
*!
*! CONFIRMADO (segunda corrida, Pruebas 11-12): las mismas tablas de la
*! 8 y la 10, con el orden de colspan() invertido, las dos pasaron --
*! 9 de 12 pruebas OK en total (los 3 fallos restantes: Prueba 5, que
*! falla a proposito -- es la referencia del orden incorrecto -- y las
*! Pruebas 8/10 originales, superadas por la 11/12). Con esto, TODOS los
*! mecanismos de putdocx que usa la rama de 2+ VARNAME quedan validados
*! de forma aislada: rowspan de cuerpo anidado en 2 niveles (Prueba 12)
*! y encabezado con varios colspan() por fila en orden derecha-a-
*! izquierda (Pruebas 7/11/12). Lo que TODAVIA no se corrio es
*! tsvyexport mismo, de punta a punta, con datos reales de 2+ VARNAME --
*! eso confirmaria que la aritmetica de columnas propia del .ado (mas
*! alla de la mecanica de putdocx ya validada) no tiene otro bug aparte.
*!
*! v1.13 -- wide()+Word con 2 o mas VARNAME: SIN CONFIRMAR EN STATA REAL
*! TODAVIA. Hasta v1.12, mas de 1 VARNAME era un error ("corra tsvy una
*! vez por variable"). El usuario pidio poder apilar varias variables en
*! el mismo cuadro, con filas anidadas NIVEL/CATEGORIA [/CRUCE] fusionadas
*! con rowspan (una fila por VARNAME dentro de cada grupo) y, por anio,
*! dos columnas hoja (Valor | Sig., donde Sig. es SIG_VS_REF -- la
*! significancia de esa categoria contra la de referencia ESE anio, no
*! el test omnibus). El omnibus (antes "Sig.") se renombra "Sig. Wald"
*! en esta rama para no confundirlo con el Sig. por anio. Con 1 sola
*! VARNAME el cuadro sale EXACTAMENTE igual que en v1.12 (rama separada,
*! codigo de v1.12 intacto). La parte nueva y riesgosa: un rowspan de
*! CUERPO (Categoria) que cubre un rango de filas DENTRO del cual otro
*! rowspan (Cruce, en la columna de al lado) arranca en una fila
*! posterior -- combinacion que ninguna prueba anterior (1-9) cubria.
*! test_putdocx_merge.do trae una Prueba 10 aislada para exactamente
*! esto; correrla (junto con las pendientes 7-9) es el proximo paso
*! antes de confiar en esta rama con datos reales.
*!
*! v1.12 -- numero()/unidad(): numeracion real de cuadros INEI, leida del
*! manual oficial subido por el usuario ("Manual para la presentacion de
*! cuadros estadisticos", INEI, Lima 2006). El manual usa "capitulo.numero"
*! (ej. "5.1", "23.115"), en MAYUSCULAS, en la MISMA linea que el titulo
*! -- no una linea "Cuadro Nro. 01" aparte, que es lo que este .ado hacia
*! antes (nada -- no habia numeracion). numero() antepone ese codigo al
*! titulo y pasa el titulo a mayusculas (regla explicita del manual,
*! p.19: "el titulo debe estar redactado en mayusculas"); unidad()
*! agrega una segunda linea entre parentesis debajo, igual que los
*! ejemplos reales del Anexo 6 ("(Hectareas)", "(Nuevos soles)"). Ambas
*! opciones son estrictamente aditivas: sin ellas, el titulo sale igual
*! que en v1.11.
*! Exporta el frame acumulador que arma tsvy (por defecto ACUM_ALL) a
*! Excel (.xlsx) o Word (.docx), sin tocar el frame original -- todo el
*! trabajo de formato ocurre sobre una copia temporal que se borra al
*! terminar.
*!
*! Dos formas de tabla:
*!   - por defecto (tidy): una fila por NIVEL x CATEGORIA x [CRUCE] x
*!     ANIO, tal cual deja el frame tsvy -- para seguir trabajando el
*!     dato (pivotear, filtrar) fuera de Stata.
*!   - wide(): una fila por NIVEL x CATEGORIA x [CRUCE] x VARNAME, con
*!     ESTIMA en una columna por anio (ESTIMA2023, ESTIMA2024, ...),
*!     seguida de F_WALD/P_WALD (el test omnibus, constante en el
*!     bloque), una columna SIG_WALD de asteriscos calculada aca mismo
*!     a partir de P_WALD (*** p<0.01, ** p<0.05, * p<0.10 -- mismo
*!     umbral que SIG_VS_REF), y una columna GRUPOS con las letras CLD
*!     de cada anio unidas con guion (ej. "d-c-b-a") -- el formato de
*!     cuadro comparativo por anio ya armado, sin pasar por ningun
*!     script externo. No se puede combinar con keep() (columnas fijas).
*!
*!     wide() + Word con 1 sola VARNAME arma un cuadro con encabezado
*!     combinado en 2 filas: Categoria [+ CRUCE] | Estimacion --
*!     fusionado sobre todas las columnas de anio -- | Var.% (calculado
*!     aca mismo entre el primer y el ultimo anio) | Sig. | Grupos, con
*!     Var.%/Sig./Grupos abarcando las dos filas de encabezado -- mismo
*!     formato que un cuadro comparativo anio contra anio armado a mano.
*!     Con 2 o mas VARNAME (v1.13, sin confirmar en Stata real -- ver
*!     arriba) arma en cambio filas anidadas Categoria [/Cruce]/Variable
*!     con rowspan, y dos columnas por anio (Valor | Sig., el Sig. por
*!     anio contra la categoria de referencia). Los numeros van en
*!     formato latinoamericano (separador de miles con espacio, coma
*!     decimal, "+" en Var.% positivo); la fila NIVEL == "NACIONAL" (si
*!     esta presente) sale sombreada como fila de total, y el cuadro
*!     lleva una leyenda de Sig./Grupos debajo.
*!
*! v1.11 -- CAUSA REAL encontrada (por fin) con un diagnostico aislado
*! (test_putdocx_merge.do, 6 pruebas minimas sin tsvy ni tsvyexport de
*! por medio, corridas contra Stata real): rowspan() es perfectamente
*! solido por si solo -- hasta 3 seguidos en la misma fila, confirmado
*! (Prueba 4). Lo que rompe el direccionamiento ("invalid cell
*! specification; column out of range") es aplicar rowspan() a una
*! columna POSTERIOR a un colspan() ya aplicado en esa misma fila
*! (Prueba 5, falla exactamente ahi); el orden inverso -- TODOS los
*! rowspan() primero, colspan() al final -- se probo aislado y funciono
*! limpio (Prueba 6). No era un limite de rowspan() en si (v1.9 estaba
*! mal en esa conclusion), ni de la instalacion de Stata -- era el
*! orden relativo entre los dos tipos de fusion. v1.11 aplica ese orden
*! (rowspan primero, colspan despues) y recupera el encabezado
*! combinado completo que se habia sacado en v1.9.
*!
*! v1.9 -- (CONCLUSION incorrecta, corregida en v1.11 -- ver arriba) tras
*! 3 rondas reales distintas con rowspan() en el orden colspan-primero
*! (v1.6, v1.7, v1.8), funcionaba 2 veces y fallaba la 3ra en columnas
*! distintas cada vez. Se atribuyo (mal) a un limite real de rowspan()
*! en esta instalacion de Stata, y se saco del todo.
*!
*! v1.8 -- (superado por v1.9 en la fusion vertical, pero el orden que
*! introdujo si sigue vigente) encontro que la causa de fondo del
*! "column out of range" no era colspan()/rowspan() en si, sino EL
*! ORDEN de las llamadas: en cuanto una celda de la fila 1 recibe su
*! fusion, las columnas SIGUIENTES en esa fila que todavia no tienen
*! contenido dejan de calzar con la numeracion original -- confirmado
*! comparando contra un ejemplo real publicado (tabla_05.do), que fija
*! el CONTENIDO de toda la fila primero y recien despues aplica
*! colspan(), nunca intercalado. Ese reordenamiento arreglo el error de
*! contenido en columnas posteriores a una fusion, pero rowspan() en si
*! siguio fallando por separado (ver v1.9).
*!
*! v1.6 -- DIAGNOSTICO, no fix: el mismo "invalid cell specification;
*! column out of range" volvio a salir en Stata real INCLUSO despues
*! de sacar los rangos en bloque (v1.5) -- esa hipotesis quedo
*! descartada por evidencia real, no solo por dudas teoricas. En vez
*! de adivinar una cuarta causa sin poder verla, cada linea de
*! putdocx table de la rama wide()+Word (crear tabla, cada celda de
*! encabezado, cada celda de cada fila de datos) queda envuelta en su
*! propio "cap noisily" numerado -- si algo vuelve a fallar, el
*! mensaje de error va a decir el numero de paso y la direccion de
*! celda exacta (tbl(fila,columna)) en vez del error generico de
*! Stata sin contexto. Nada del comportamiento cambia si todo corre
*! bien; esto es puramente para localizar el problema real en la
*! proxima corrida.
*!
*! v1.5 -- FIX real (v1.4, Ejemplo 6 de nuevo): un agente de
*! investigacion confirmo contra ejemplos reales publicados en GitHub
*! (ej. un cuadro de pobreza ENAHO estructuralmente identico a este
*! caso) que colspan()/rowspan() SI son "# celdas en total" (igual que
*! colspan de HTML) -- la matematica de columnas de v1.3 ya era
*! correcta, asi que el "column out of range" de esa version no era por
*! la semantica de colspan(). El sospechoso real: los rangos en bloque
*! (tbl(1/2,.), tbl(.,.)) usados solo para darle formato al
*! encabezado/bordes, que barren tambien direcciones que un merge
*! previo ya elimino -- ningun ejemplo real encontrado usa un rango en
*! bloque sobre una tabla con celdas fusionadas. v1.5 vuelve a armar el
*! encabezado combinado, pero fija contenido + fusion + formato
*! (bold/shading/rowspan/colspan) SIEMPRE en una sola linea por
*! direccion, nunca con un rango en bloque -- sin borde de tabla en
*! bloque tampoco (el estilo por defecto de putdocx table ya trae
*! grilla). v1.4 (encabezado de una sola fila) queda superado.
*!
*! v1.1 -- wide() (reshape + Excel/Word planos) CONFIRMADO corriendo
*! limpio contra Stata real.
*!
*! v1.1 -- wide() (reshape + Excel/Word planos) CONFIRMADO corriendo
*! limpio contra Stata real.
*!
*! Formato Excel: export excel (bulk, respeta el formato de despliegue
*! de cada variable) + una pasada de putexcel para encabezado en negrita
*! y bordes -- evita reconstruir la tabla celda por celda.
*! append() agrega el resultado como una HOJA NUEVA del mismo archivo
*! (putexcel/export excel, modify), no como filas nuevas de la misma
*! hoja -- mismo criterio que Word (ver abajo), para que append() se
*! comporte igual en los dos formatos.
*!
*! Formato Word: putdocx table ... = data(), que arma la tabla en un
*! solo paso a partir de las variables ya formateadas (respeta el %fmt
*! de cada variable, igual que Excel). append() usa
*! putdocx save ..., append(pagebreak) -- agrega la tabla como seccion
*! nueva al final del documento existente, no mezcla filas dentro de una
*! tabla ya guardada. SIG_VS_REF (tidy) o SIG_WALD (wide), si estan en
*! la tabla exportada, se marcan en superindice, celda por celda -- es
*! la unica columna donde vale la pena el costo de un loop por fila (el
*! resto se escribe en bloque via data()).
*!
*! v1.0 -- CONFIRMADO corriendo limpio contra Stata real (formato tidy,
*! Excel y Word, replace/append, keep()+digits()) -- ver los 4 ejemplos
*! del help.
*!
*! Como tabout, si el archivo de salida ya existe y no se especifica
*! replace ni append, para con un error en vez de sobreescribir en
*! silencio.
program define tsvyexport
    version 16
    syntax using/ [, FRAME(name) EXCEL WORD SHEET(string) TITLE(string) ///
        NUMERO(string) UNIDAD(string) FUENTE(string asis) ///
        ELABORACION(string asis) ESTILO(string) ///
        KEEP(string) REPLACE APPEND DIGITS(integer 2) WIDE]

    * -- v1.37 -- letras acentuadas para el texto del Word (titulos de
    * columna y leyenda) via uchar(), asi el .ado sigue siendo ASCII puro.
    local _a = uchar(225)
    local _e = uchar(233)
    local _i = uchar(237)
    local _o = uchar(243)
    local _n = uchar(241)
    local _u = uchar(250)

    if `"`keep'"' != "" & "`wide'" != "" {
        di as err "tsvyexport: keep() y wide no se pueden combinar -- wide()" ///
            " usa un conjunto de columnas fijo (ver help)"
        exit 198
    }

    * -- v1.21: estilo() -- preset de formato (fuente + tamanos) para el
    * cuadro de wide()+Word, investigado con 2 agentes (uno para APA7 y
    * revistas indexadas, otro para tipografia de agencias de
    * estadistica oficial) porque el manual del INEI NO especifica
    * ninguna fuente ni tamano de letra en ningun lado (solo dice
    * generico que no hay que "distorsionar el tipo de letra estandar"
    * al escalar para imprimir) -- la tipografia real es convencion de
    * facto, no una regla escrita ahi.
    *   - "clasico": Arial Narrow (respaldado por el Manual de Estilo del
    *     INDEC, que SI especifica tipografia por escrito para cuadros:
    *     Helvetica/Arial Bold ~10pt en titulo, 7pt en el resto) --
    *     titulo 10pt negrita, encabezado 8pt negrita, cuerpo 8pt, notas
    *     7pt. (El ejemplo que mando el usuario era 10/7/7/7 -- se subio
    *     encabezado/cuerpo a 8pt, el piso practico de legibilidad para
    *     texto que hay que leer con precision, dejando notas en 7pt
    *     igual que el precedente de INDEC).
    *   - "apa7": reglas oficiales de apastyle.apa.org para TABLAS --
    *     Times New Roman, SOLO bordes horizontales (arriba, bajo
    *     encabezado, al final -- nunca verticales, "tabla de tres
    *     lineas"), numero de tabla en negrita + titulo en cursiva en
    *     lineas separadas (formato APA real, distinto del "numero
    *     TITULO en mayusculas" de una sola linea que usa numero() al
    *     estilo INEI).
    *   - "revista": generico para revistas indexadas que no exigen APA
    *     especificamente -- mismo esquema de bordes de 3 lineas, Times
    *     New Roman, tamanos un poco menores (comunes en tablas de
    *     resultados con muchas columnas).
    *   - "" (default): SIN CAMBIOS -- fuente/tamano de Word por defecto
    *     (tema del documento), igual que siempre antes de v1.21.
    * El tamano en putdocx es PUNTOS (no medios-puntos), pero NO es una
    * opcion aparte -- font() de putdocx es una sola opcion combinada,
    * fspec = "fontname [, size [, color]]" (v1.23, confirmado con help
    * putdocx text/paragraph tras 2 intentos fallidos: v1.19/v1.21 primero
    * usaban "fontsize(#)" -- rc=198 en la primera corrida real -- y
    * v1.22 lo cambio a "size(#)" suelto, que TAMBIEN fallo con rc=198).
    local estilo = lower(`"`estilo'"')
    * -- v1.29: renombrado "inei" -> "clasico" (pedido del usuario) --
    * mismo preset (Arial Narrow, mismos tamanos), solo cambia el
    * nombre que se pasa en estilo(). "inei" ya NO es un valor valido.
    if !inlist("`estilo'", "", "clasico", "apa7", "revista") {
        di as err "tsvyexport: estilo() invalido -- use clasico, apa7 o revista"
        exit 198
    }
    if "`estilo'" == "clasico" {
        local estfont "Arial Narrow"
        local sz_titulo 10
        local sz_encab 8
        local sz_cuerpo 8
        local sz_nota 7
    }
    else if "`estilo'" == "apa7" {
        local estfont "Times New Roman"
        local sz_titulo 12
        local sz_encab 12
        local sz_cuerpo 12
        local sz_nota 10
    }
    else if "`estilo'" == "revista" {
        local estfont "Times New Roman"
        local sz_titulo 11
        local sz_encab 10
        local sz_cuerpo 10
        local sz_nota 9
    }
    else {
        local estfont ""
        local sz_titulo 9
        local sz_encab 9
        local sz_cuerpo 9
        local sz_nota 9
    }
    * -- 2 variantes de cada suboption por preset: "_bare" (para pegar
    * DESPUES de una coma que el llamado ya trae, ej. ", halign(right)
    * `ocuerpo_bare'") y "_new" (la clausula ", opciones" completa, para
    * llamados que hoy no tienen ninguna opcion). Vacias si estilo() es
    * "" -- asi el comportamiento por defecto queda IDENTICO a antes de
    * v1.21 (nada que agregar a ningun llamado).
    local otitulo_bare ""
    local otitulo_new ""
    local ounidad_new ""
    local oencab_bare ""
    local ocuerpo_bare ""
    local ocuerpo_new ""
    local onota_bare ""
    local onota_new ""
    * -- v1.26: border(all,nil) para apa7/revista YA NO es un barrido en
    * bloque (tbl(.,.)) -- el propio archivo ya documentaba desde v1.5
    * que esos rangos "barren tambien direcciones que una fusion ya
    * elimino" (ver el comentario junto a `hdr' mas abajo). v1.24 y
    * v1.25 lo probaron en 2 puntos distintos (antes y despues de la
    * fusion) y los dos rompieron el sombreado de la columna pegada a
    * un colspan() (Var.%), reportado con datos reales las 2 veces --
    * el barrido en bloque en si es el problema, no el orden. Fix real:
    * `oborder_bare' se agrega a CADA llamado individual que ya formatea
    * una celda (el mismo `hdr'/`ocuerpo_bare'/`ocuerpo_new' que ya
    * usan direcciones probadas, una por una, nunca tbl(.,.)) -- asi
    * "sin borde" queda seteado en la MISMA llamada que pone el
    * sombreado, en vez de en un paso aparte que pueda desalinearse.
    local oborder_bare ""
    if inlist("`estilo'", "apa7", "revista") local oborder_bare "border(all, nil)"
    if "`estilo'" != "" {
        * -- v1.23: font() de putdocx es UNA opcion combinada (nombre,
        * tamano, color), no font()+size() separados (help putdocx
        * paragraph##options -- fspec: "fontname [, size [, color]]").
        local otitulo_bare `"font("`estfont'", `sz_titulo') bold"'
        local otitulo_new `", `otitulo_bare'"'
        local ounidad_new `", font("`estfont'", `sz_titulo')"'
        local oencab_bare `"font("`estfont'", `sz_encab') `oborder_bare'"'
        local ocuerpo_bare `"font("`estfont'", `sz_cuerpo') `oborder_bare'"'
        local ocuerpo_new `", `ocuerpo_bare'"'
        local onota_bare `"font("`estfont'", `sz_nota')"'
        local onota_new `", `onota_bare'"'
    }

    * -- v1.19: tamano() vive DENTRO de fuente()/elaboracion(), como
    * suboption -- ej. fuente("INEI - ...", tamano(9)) -- en vez de una
    * opcion aparte al nivel de tsvyexport (que hubiera obligado a un
    * solo tamano para las dos lineas). Patron estandar de Stata para
    * "texto + suboptions" (el mismo que usa, por ejemplo, xtitle()):
    * se declara FUENTE()/ELABORACION() como string asis (texto crudo,
    * sin reinterpretar), y se vuelve a correr `syntax' sobre ese texto
    * -- `anything' toma todo lo que hay antes de la primera coma de
    * nivel superior (respetando comillas, igual que la linea de
    * comando principal), y `, tamano(#)' se parsea como una option
    * mas, con su propio default de 9. Sin tamano(), fuentetxt'/
    * elabtxt' quedan como el texto completo y ftam'/elabtam' caen al
    * default.
    * -- v1.21: el default de tamano() (cuando el usuario no lo pasa)
    * ahora es sz_nota' (9 si estilo() es "", igual que siempre -- 7/10/9
    * si es clasico/apa7/revista) en vez de un 9 fijo, para que fuente()/
    * elaboracion() combinen con el resto del cuadro cuando se usa un
    * estilo(). Un tamano(#) explicito sigue ganando siempre.
    local ftam `sz_nota'
    local elabtam `sz_nota'
    * -- v1.35 -- FIX: el `syntax' anidado sobre `local 0' corria en el
    * MISMO programa y reescribia los locales del syntax principal --
    * `using' quedaba vacio y tsvyexport cortaba con "no se pudo
    * determinar el formato" siempre que se pasaba fuente()/elaboracion().
    * Ahora se parsea en un subprograma (_tsvyexport_txtopt), que tiene
    * sus propios locales y devuelve el resultado en r().
    if `"`fuente'"' != "" {
        cap noisily _tsvyexport_txtopt `fuente'
        if _rc {
            di as err `"tsvyexport: fuente() mal formado -- use"' ///
                `" fuente("texto") o fuente("texto", tamano(#))"'
            exit 198
        }
        local fuentetxt `"`r(txt)'"'
        local ftam = cond(r(tam) < ., r(tam), `sz_nota')
    }
    if `"`elaboracion'"' != "" {
        cap noisily _tsvyexport_txtopt `elaboracion'
        if _rc {
            di as err `"tsvyexport: elaboracion() mal formado -- use"' ///
                `" elaboracion("texto") o elaboracion("texto", tamano(#))"'
            exit 198
        }
        local elabtxt `"`r(txt)'"'
        local elabtam = cond(r(tam) < ., r(tam), `sz_nota')
    }

    if "`frame'" == "" local frame ACUM_ALL
    cap confirm frame `frame'
    if _rc {
        di as err "tsvyexport: no existe el frame `frame' -- corra tsvy primero" ///
            " (o especifique frame() con el nombre que uso)"
        exit 111
    }

    if "`replace'" != "" & "`append'" != "" {
        di as err "tsvyexport: replace y append son mutuamente excluyentes"
        exit 198
    }
    if "`excel'" != "" & "`word'" != "" {
        di as err "tsvyexport: excel y word son mutuamente excluyentes"
        exit 198
    }

    * -- formato: explicito, o inferido de la extension de `using'.
    local fmt ""
    if "`excel'" != "" local fmt excel
    if "`word'"  != "" local fmt word
    if "`fmt'" == "" {
        * -- v1.28: reportado 2 veces con datos reales (archivos simples,
        * sin ruta ni comillas -- cuadro_sierra.docx, cuadro_categorias.docx
        * -- que a simple vista deberian detectarse bien) que este bloque
        * cae en "no se pudo determinar el formato" sin causa visible en
        * el codigo. Mientras no se reproduce, se agrega un debug -- si
        * vuelve a pasar, este mensaje va a mostrar EXACTAMENTE que
        * contiene `using' en ese momento (comillas de mas, espacio en
        * blanco, salto de linea, etc. que `ext' no este limpiando).
        local ext = lower(substr(`"`using'"', strrpos(`"`using'"', ".") + 1, .))
        if inlist("`ext'", "xlsx", "xls") local fmt excel
        if inlist("`ext'", "docx", "doc") local fmt word
    }
    if "`fmt'" == "" {
        di as err "tsvyexport: no se pudo determinar el formato -- use un archivo" ///
            " .xlsx/.docx, o especifique excel/word explicitamente"
        exit 198
    }

    cap confirm file "`using'"
    local filexists = !_rc
    if `filexists' & "`replace'" == "" & "`append'" == "" {
        di as err "tsvyexport: `using' ya existe -- especifique replace o append"
        exit 602
    }
    * -- append() sobre un archivo que todavia no existe no tiene sentido
    * (no hay nada a lo que agregar) -- se trata como una primera
    * exportacion normal.
    local doappend = `filexists' & "`append'" != ""

    if "`sheet'" == "" local sheet tsvy

    * -- copia de trabajo: nunca se toca el frame original del usuario.
    cap frame drop TSVYEXPORT_TMP
    frame copy `frame' TSVYEXPORT_TMP

    * -- v1.30 -- lee la characteristic _dta[tsvy_cldmetodo] que tsvy
    * (v1.29+) deja en el frame con que metodo armo GRUPO -- "frame copy"
    * duplica characteristics junto con los datos, asi que ya esta en
    * TSVYEXPORT_TMP. Vacio si el frame viene de una version vieja de
    * tsvy (antes de v1.28) o no fue armado por tsvy -- la leyenda mas
    * abajo se degrada con gracia a su texto generico de siempre en ese
    * caso, nunca corta con error por esto.
    frame TSVYEXPORT_TMP: local cldmetodo_usado : char _dta[tsvy_cldmetodo]
    * -- v1.32 -- alpha con el que tsvy calculo las letras (char
    * _dta[tsvy_alpha], tsvy v1.29+); 0.05 si el frame no lo trae.
    frame TSVYEXPORT_TMP: local sig_alpha : char _dta[tsvy_alpha]
    if "`sig_alpha'" == "" local sig_alpha 0.05
    local sig_leyenda "*** p<0.01"
    if `sig_alpha' >= 0.05 local sig_leyenda "`sig_leyenda', ** p<0.05"
    if `sig_alpha' >= 0.10 local sig_leyenda "`sig_leyenda', * p<0.10"
    local etiqueta_cldmetodo ""
    if "`cldmetodo_usado'" == "bonferroni" local etiqueta_cldmetodo "Bonferroni"
    if "`cldmetodo_usado'" == "holm"       local etiqueta_cldmetodo "Holm"
    if "`cldmetodo_usado'" == "fdr"        local etiqueta_cldmetodo "FDR, Benjamini-Hochberg"
    if "`cldmetodo_usado'" == "lsd"        local etiqueta_cldmetodo "Fisher LSD"
    if "`cldmetodo_usado'" == "auto"       local etiqueta_cldmetodo "Bonferroni"

    frame TSVYEXPORT_TMP {
      if "`wide'" != "" {
        * -----------------------------------------------------------
        * wide(): una fila por bloque (NIVEL CATEGORIA [CRUCE] VARNAME),
        * ESTIMA y GRUPO pasan de una fila por anio a una columna por
        * anio via reshape wide -- mismo patron ya documentado en
        * help tsvy (seccion "Frame layout"). F_WALD/P_WALD son
        * constantes dentro del bloque (quedan en i(), no se reshapean).
        * -----------------------------------------------------------
        foreach v in NIVEL CATEGORIA VARNAME ANIO ESTIMA GRUPO F_WALD P_WALD {
            cap confirm variable `v', exact
            if _rc {
                di as err "tsvyexport: wide() necesita la columna `v', que no" ///
                    " esta en el frame `frame' -- corrio con una version" ///
                    " distinta de tsvy?"
                exit 111
            }
        }
        quietly levelsof ANIO, local(anios) clean
        if `: word count `anios'' < 2 {
            di as err "tsvyexport: wide() necesita al menos 2 anios distintos" ///
                " en ANIO -- este frame solo tiene: `anios'"
            exit 198
        }

        quietly format ESTIMA %9.`digits'f
        quietly format P_WALD %9.3f

        * -- v1.32 -- FIX: SIG_WALD solo marca niveles <= alpha de tsvy.
        * Antes ponia "*" con p<0.10 aunque las letras de GRUPO se calculan
        * al alpha de tsvy (0.05 por defecto): un bloque con p=0.052 salia
        * "*" con GRUPOS "a-a-a", que se lee como contradictorio.
        quietly gen str3 SIG_WALD = ""
        if `sig_alpha' >= 0.10 quietly replace SIG_WALD = "*"   if P_WALD < 0.10 & P_WALD != .
        if `sig_alpha' >= 0.05 quietly replace SIG_WALD = "**"  if P_WALD < 0.05 & P_WALD != .
        quietly replace SIG_WALD = "***" if P_WALD < 0.01 & P_WALD != .

        * -- v1.13: hascruce/hassig se calculan UNA vez aca y se
        * reutilizan mas abajo (en la rama Word, para el cuadro con
        * varias VARNAME) -- SIG_VS_REF entra al reshape solo si el
        * frame lo trae (viene de tsvy, es opcional segun si se corrio
        * con una categoria de referencia).
        cap confirm variable CRUCE, exact
        local hascruce = !_rc
        cap confirm variable SIG_VS_REF, exact
        local hassig = !_rc

        * -- v1.16: CATEGORIA_LBL/CRUCE_LBL (texto de la etiqueta de
        * valor, si tsvy la guardo -- opcion agregada en tsvy.ado v1.18)
        * son opcionales: un frame armado con una version anterior de
        * tsvy no las trae, y tsvyexport tiene que seguir andando igual
        * (vuelve al codigo numerico puro, comportamiento de siempre).
        cap confirm variable CATEGORIA_LBL, exact
        local hascatlbl = !_rc
        local hascrulbl = 0
        if `hascruce' {
            cap confirm variable CRUCE_LBL, exact
            local hascrulbl = !_rc
        }

        local idvars NIVEL CATEGORIA
        if `hascatlbl' local idvars `idvars' CATEGORIA_LBL
        if `hascruce' local idvars `idvars' CRUCE
        if `hascrulbl' local idvars `idvars' CRUCE_LBL
        local idvars `idvars' VARNAME F_WALD P_WALD SIG_WALD
        * -- v1.34 -- CLD_METODO (tsvy v1.29+): constante dentro del
        * bloque, entra a i() igual que F_WALD/P_WALD.
        cap confirm variable CLD_METODO, exact
        local hasmet = !_rc
        if `hasmet' local idvars `idvars' CLD_METODO

        local reshapevars ESTIMA GRUPO
        if `hassig' local reshapevars `reshapevars' SIG_VS_REF

        quietly keep `idvars' ANIO `reshapevars'
        * -- v1.31: sort explicito ANTES del reshape -- sin esto, un
        * frame armado a mano (p.ej. con `input', en vez de via tsvy)
        * puede llegar en cualquier orden y reshape tira "not sorted"
        * r(5). Con datos que ya vienen de tsvy esto no se notaba
        * porque frameappend/append dejaban el orden correcto por
        * casualidad -- no por garantia.
        quietly sort `idvars' ANIO
        quietly reshape wide `reshapevars', i(`idvars') j(ANIO)

        local primero: word 1 of `anios'
        quietly gen str64 GRUPOS = cond(missing(GRUPO`primero'), "?", GRUPO`primero')
        * -- v1.34 -- CLD_INCONS: F de Wald significativo (P_WALD < alpha
        * de tsvy) pero TODOS los anios con la misma letra -- el test
        * global rechaza la igualdad y ningun par, tras el ajuste
        * multiple, lo hace. Se calcula aca desde el propio frame (no
        * depende de la version de tsvy) y se marca con la llamada "b/"
        * en GRUPOS, explicada en la leyenda.
        tempvar unaletra
        quietly gen byte `unaletra' = !missing(GRUPO`primero')
        foreach y of local anios {
            if "`y'" != "`primero'" {
                quietly replace GRUPOS = GRUPOS + "-" + ///
                    cond(missing(GRUPO`y'), "?", GRUPO`y')
                quietly replace `unaletra' = 0 if GRUPO`y' != GRUPO`primero'
            }
        }
        * GRUPO<anio> se borran DESPUES del loop: GRUPO`primero' se usa
        * como referencia en todas las iteraciones (v1.34 lo borraba en la
        * primera y fallaba con "GRUPO2023 not found", r(111)).
        foreach y of local anios {
            quietly drop GRUPO`y'
        }
        quietly gen byte CLD_INCONS = `unaletra' & P_WALD < `sig_alpha' & !missing(P_WALD)
        quietly count if CLD_INCONS
        local n_incons = r(N)
        * Con cldmetodo(auto) el metodo puede variar por bloque: si hay
        * mas de uno, se indica entre parentesis en GRUPOS.
        local metvaria = 0
        if `hasmet' {
            quietly levelsof CLD_METODO if CLD_METODO != "", local(mets_frame) clean
            local metvaria = (`: word count `mets_frame'' > 1) | ///
                ("`mets_frame'" != "" & "`mets_frame'" != "bonferroni" & "`cldmetodo_usado'" == "auto")
            if `metvaria' quietly replace GRUPOS = GRUPOS + " (" + CLD_METODO + ")" ///
                if CLD_METODO != "" & CLD_METODO != "bonferroni"
        }
        quietly replace GRUPOS = GRUPOS + " b/" if CLD_INCONS
        drop `unaletra'
        if `n_incons' > 0 {
            di as text "tsvyexport: `n_incons' fila(s) con F de Wald significativo pero" ///
                " una sola letra en GRUPOS (marcadas b/). Considere cldmetodo(auto) en tsvy."
        }

        local estimavars ""
        local sigrefvars ""
        foreach y of local anios {
            local estimavars `estimavars' ESTIMA`y'
            quietly format ESTIMA`y' %9.`digits'f
            if `hassig' local sigrefvars `sigrefvars' SIG_VS_REF`y'
        }
        local idcols NIVEL CATEGORIA
        if `hascatlbl' local idcols `idcols' CATEGORIA_LBL
        if `hascruce' local idcols `idcols' CRUCE
        if `hascrulbl' local idcols `idcols' CRUCE_LBL
        local idcols `idcols' VARNAME
        local expvars `idcols' `estimavars' `sigrefvars' F_WALD P_WALD SIG_WALD GRUPOS CLD_INCONS
        if `hasmet' local expvars `expvars' CLD_METODO
        quietly order `expvars'

        * -- v1.15: el total (NIVEL == "NACIONAL") va PRIMERO, no ultimo
        * -- mismo convenio que el Anexo 6 del manual INEI, donde toda
        * tabla con un "Total" lo lista antes que las categorias que lo
        * componen (ej. "Departamento: Total / Amazonas / ..."). Afecta
        * a Excel y Word por igual, y a las dos ramas de wide()+Word (1
        * VARNAME y 2+); la rama de 2+ VARNAME reordena de nuevo mas
        * abajo (con CRUCE/VARNAME de por medio) y reusa esta misma
        * bandera para no perder el orden aca.
        quietly gen byte __NACPRIMERO = (NIVEL == "NACIONAL")
        quietly gsort -__NACPRIMERO NIVEL CATEGORIA
      }
      else {
        quietly ds
        local allvars `r(varlist)'

        if `"`keep'"' != "" {
            local keepvars `keep'
            local faltantes ""
            foreach v of local keepvars {
                cap confirm variable `v', exact
                if _rc local faltantes `faltantes' `v'
            }
            if `"`faltantes'"' != "" {
                di as err "tsvyexport: keep() incluye variables que no estan" ///
                    " en el frame `frame': `faltantes'"
                exit 111
            }
            quietly keep `keepvars'
            quietly order `keepvars'
            local expvars `keepvars'
        }
        else local expvars `allvars'

        * -- formato de despliegue por tipo de columna (solo si la
        * columna esta presente -- CRUCE/P_MMD/EFFECT_MMD son opcionales
        * segun como se corrio tsvy). export excel y putdocx data()
        * respetan el %fmt de cada variable cuando no se les pasa un
        * nformat explicito, asi que basta con fijarlo aca una vez.
        cap confirm variable ANIO, exact
        if !_rc quietly format ANIO %6.0f
        foreach v in N_SIN_PON N_PONDERA {
            cap confirm variable `v', exact
            if !_rc quietly format `v' %12.0fc
        }
        foreach v in P_WALD P_VS_REF P_MMD P_KSMMD_KS P_KSMMD_MMD {
            cap confirm variable `v', exact
            if !_rc quietly format `v' %9.3f
        }
        foreach v in ESTIMA ERROR_ST CV LIM_INF LIM_SUP F_WALD EFFECT_MMD {
            cap confirm variable `v', exact
            if !_rc quietly format `v' %9.`digits'f
        }
      }

        quietly count
        local nobs = r(N)
        local nvars: word count `expvars'

        if "`fmt'" == "excel" {
            if `doappend' {
                export excel `expvars' using "`using'", ///
                    firstrow(variables) sheet("`sheet'") sheetreplace
            }
            else {
                export excel `expvars' using "`using'", ///
                    firstrow(variables) sheet("`sheet'") replace
            }

            mata: st_local("lastcol", _tsvyexport_xlcol(`nvars'))
            putexcel set "`using'", sheet("`sheet'") modify
            putexcel A1:`lastcol'1, bold border(bottom, thin) txtwrap
            putexcel A1:`lastcol'`=`nobs'+1', border(right, thin)
        }
        else if "`wide'" != "" {
            * -------------------------------------------------------
            * wide() + Word: cuadro con encabezado combinado en 2 filas
            * (Categoria | Estimacion -- fusionado sobre las columnas
            * de anio -- | Var.% | Sig. | Grupos), una tabla por
            * VARNAME. v1.5: reintentado con la semantica confirmada de
            * colspan()/rowspan() (# = total de celdas fusionadas,
            * igual que colspan de HTML -- la matematica de columnas ya
            * era correcta en el primer intento, ver v1.5 en el
            * encabezado del archivo). La diferencia real esta vez:
            * cada celda se formatea INDIVIDUALMENTE por su propia
            * direccion (bold/shading/rowspan/colspan en la MISMA
            * linea que fija su contenido), nunca con un rango en
            * bloque tipo tbl(1/2,.) o tbl(.,.) -- esos rangos barren
            * tambien direcciones que una fusion ya elimino, y ningun
            * ejemplo real encontrado hace eso. Por el mismo motivo no
            * hay borde de tabla en bloque; el estilo por defecto de
            * putdocx table ya trae grilla visible.
            * -------------------------------------------------------
            quietly levelsof VARNAME, local(varnombres) clean
            local nvarnames: word count `varnombres'

            * -- v1.13: mas de 1 VARNAME ya NO es un error -- con 1 sola
            * el cuadro sale exactamente como en v1.12 (sin cambios); con
            * varias arma filas anidadas NIVEL/CATEGORIA [/CRUCE], una
            * fila por VARNAME, con rowspan en las etiquetas repetidas --
            * el patron pedido por el usuario. Necesita un rowspan de
            * cuerpo que arranca DENTRO del rango de otro rowspan (en una
            * columna distinta): combinacion sin confirmar en Stata real
            * todavia -- test_putdocx_merge.do trae una Prueba 10 aislada
            * para esto, correrla antes de confiar en esta rama con datos
            * reales.
            * -- v1.16: usa CATEGORIA_LBL (texto real, ej. "Puno") en vez
            * del codigo numerico de CATEGORIA cuando esta disponible --
            * si esta en blanco para alguna fila puntual (categoria sin
            * etiqueta definida en el dataset original), cae de nuevo a
            * "NIVEL numero" para esa fila. v1.17: cuando SI hay
            * etiqueta, va SOLA -- sin anteponer NIVEL -- porque el
            * nombre de la variable (ej. "departamento") no aporta nada
            * junto al nombre real (ej. "Puno"); pedido del usuario
            * tras ver "departamento Puno" repetido en cada fila.
            if `hascatlbl' {
                quietly gen str80 ETIQUETA = cond(CATEGORIA_LBL != "", ///
                    CATEGORIA_LBL, NIVEL + " " + string(CATEGORIA))
            }
            else {
                quietly gen str80 ETIQUETA = NIVEL + " " + string(CATEGORIA)
            }
            if `hascruce' & `nvarnames' == 1 {
                if `hascrulbl' {
                    quietly replace ETIQUETA = ETIQUETA + " / " + ///
                        cond(CRUCE_LBL != "", CRUCE_LBL, string(CRUCE))
                }
                else {
                    quietly replace ETIQUETA = ETIQUETA + " / " + string(CRUCE)
                }
            }

            local nyears: word count `anios'
            local primero: word 1 of `anios'
            local ultimo: word `nyears' of `anios'
            * -- v1.18: Var.% es ULTIMO anio contra el ANTERIOR (no
            * contra el PRIMERO de la serie) -- convencion estandar de
            * estadistica oficial (INEI, BCRP, etc. siempre la definen
            * anio-contra-anio-anterior, nunca cambio acumulado de toda
            * la serie). Fijo, sin opcion nueva: es la unica definicion
            * que se usa en la practica, y agregar una opcion para el
            * caso viejo (primero/ultimo) metia complejidad de mas para
            * algo que nadie pidio conservar.
            local penultimo: word `=`nyears'-1' of `anios'
            quietly gen double VARPCT = ///
                (ESTIMA`ultimo' / ESTIMA`penultimo' - 1) * 100 ///
                if ESTIMA`penultimo' != 0 & ESTIMA`penultimo' != .
            * -- v1.20 FIX: ancho 9 (%9.Nf) es insuficiente para ESTIMA
            * de varios millones (ej. poblacion: "3400000.00" ya son 10
            * caracteres) -- Stata's string() cae a notacion cientifica
            * ("3.40e+06") cuando el numero no entra en el ancho pedido,
            * y _tsvyexport_numes() no reconoce esa notacion (solo sabe
            * de "intpart.decpart" corriente), asi que la mezclaba mal
            * ("3,40e+06"). Ancho 20 alcanza para cualquier ESTIMA
            * realista sin forzar notacion cientifica; _tsvyexport_numes
            * ya hace strtrim() del padding de mas que deja un ancho
            * grande de sobra.
            local estfmt %20.`digits'f

            * -- v1.21: `oencab_bare' agrega fuente/tamano de estilo() a
            * las 5 direcciones de formato de encabezado (una sola
            * definicion cubre las 2 filas de encabezado en las 2 ramas
            * -- 1 VARNAME y 2+ -- porque las 2 usan este mismo local).
            local hdr bold shading("D9E2F3") halign(center) valign(center) `oencab_bare'

            putdocx begin
            local titletext `"`title'"'
            if `"`titletext'"' == "" local titletext "`: word 1 of `varnombres''"
            if "`estilo'" == "apa7" {
                * -- v1.21: formato APA7 real para el titulo -- numero de
                * tabla en negrita en su propia linea ("Tabla N"), titulo
                * en cursiva en la linea de abajo. Distinto del "numero
                * TITULO-MAYUSCULAS" de una sola linea que usa numero()
                * al estilo INEI (v1.12) -- esa convencion NO es la de
                * APA, asi que apa7 no la reusa.
                putdocx paragraph, style(Title)
                if `"`numero'"' != "" {
                    putdocx text ("Tabla `numero'"), bold font("`estfont'", `sz_titulo')
                    putdocx paragraph
                }
                putdocx text (`"`titletext'"'), italic font("`estfont'", `sz_titulo')
                if `"`unidad'"' != "" {
                    putdocx paragraph
                    putdocx text ("(`unidad')"), font("`estfont'", `sz_titulo')
                }
            }
            else {
                putdocx paragraph, style(Title)
                if `"`numero'"' != "" {
                    local titleupper = strupper(`"`titletext'"')
                    local titletext `"`numero' `titleupper'"'
                }
                putdocx text (`"`titletext'"')`otitulo_new'
                if `"`unidad'"' != "" {
                    putdocx paragraph
                    putdocx text ("(`unidad')")`ounidad_new'
                }
            }

            local paso 0

            if `nvarnames' == 1 {
            * ---- v1.12: 1 sola VARNAME -- Categoria [+CRUCE] | Estimacion
            * (colspan sobre anios) | Var.% | Sig. | Grupos, SIN CAMBIOS. ----
            local nrows = 2 + `nobs'
            local ncols = 1 + `nyears' + 3
            local c_varpct = 2 + `nyears'
            local c_sig    = `c_varpct' + 1
            local c_grupos = `c_sig' + 1

            * -- v1.8: el diagnostico de v1.6/v1.7 (capture numerado por
            * celda) mostro que el problema no es colspan()/rowspan() en
            * si, sino EL ORDEN: en cuanto una celda de la fila 1 recibe
            * su fusion, las direcciones de columna de las celdas
            * SIGUIENTES en esa misma fila (todavia sin contenido) dejan
            * de calzar con la numeracion original de la grilla -- por
            * eso "columna 5" funcionaba (nada se habia fusionado
            * todavia delante de ella en ese momento) pero "columna 6"
            * ya no (la fusion anterior en esa fila ya habia corrido).
            * Un ejemplo real confirmado funcionando (tabla_05.do, con 2
            * grupos fusionados en la misma fila) sigue exactamente el
            * patron contrario: fija el CONTENIDO de TODAS las celdas de
            * la fila primero (numeracion original completa, sin ninguna
            * fusion todavia aplicada), y recien DESPUES aplica
            * colspan() a las que lo necesitan, como un segundo paso
            * separado. v1.8 sigue ese mismo orden -- contenido primero,
            * fusion despues, formato al final -- en vez de fijar
            * contenido+fusion+formato juntos celda por celda.
            local paso = `paso' + 1
            cap noisily putdocx table tbl = (`nrows', `ncols'), layout(fixed)
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (crear tabla `nrows' x `ncols'): rc=" _rc
                exit _rc
            }
            * -- v1.33: layout(fixed) en la creacion -- el default es
            * layout(autofitwindow) (columnas se reajustan solas al
            * ancho de la ventana), que podria pisar los width() por
            * columna de mas abajo. Con layout(fixed) el ancho que se
            * fija explicito por columna se respeta.
            *
            * -- v1.32 (corregido en v1.33, ver nota): cada columna de
            * putdocx table nace con un ancho FIJO (1170 twips=0.81in),
            * sin importar `ncols' -- con pocas columnas (hasta 8, el
            * caso original de 1 sola VARNAME con pocos anios) eso da
            * justo 6.5in, el ancho util de una pagina carta con
            * margenes de 1in, y encaja bien por casualidad. Con mas
            * anios (2+ VARNAME, o wide() con muchos anios) la tabla se
            * va mucho mas alla de la pagina -- celdas angostas, texto
            * envuelto en varias lineas, tabla "grande" (reportado por
            * el usuario con 10-12 anios). Fix: reparte 6.5in en partes
            * iguales entre las `ncols' columnas, apenas creada la tabla
            * y ANTES de cualquier fusion (mismo motivo que el orden de
            * v1.24 para border(all,nil)).
            *
            * v1.33: la v1.32 probo esto con un solo `putdocx table
            * tbl(.,.), width()' -- goto error real: "option width(...)
            * not allowed". Con la sintaxis real de putdocx table
            * (pegada por el usuario desde help putdocx table): width()
            * para columnas es un row_col_option, valido SOLO en la
            * forma tablename(., j) (una columna a la vez) -- NO es un
            * cell_fmt_option, asi que tablename(.,.) (bloque, todas las
            * columnas juntas) nunca lo acepta. Fix real: loop columna
            * por columna.
            local tblwidth_in = 6.5
            local colwidth_in = `tblwidth_in' / `ncols'
            forvalues j_v132 = 1/`ncols' {
                quietly putdocx table tbl(., `j_v132'), width(`colwidth_in')
            }
            * Paso A: CONTENIDO de toda la fila 1 y la fila 2, con la
            * numeracion original completa (1..`ncols') -- todavia sin
            * ninguna fusion aplicada.
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,1) = ("Categor`_i'a")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,1)): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,2) = ("Estimaci`_o'n")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,2)): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_varpct') = ("Var. % `ultimo'/`penultimo'")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_varpct')): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_sig') = ("Sig.")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_sig')): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_grupos') = ("Grupos")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_grupos')): rc=" _rc
                exit _rc
            }

            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,1) = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,1) blanco): rc=" _rc
                exit _rc
            }
            local yi = 0
            foreach y of local anios {
                local yi = `yi' + 1
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2, `=1+`yi'') = ("`y'")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`=1+`yi'') anio `y''): rc=" _rc
                    exit _rc
                }
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_varpct') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_varpct') blanco): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_sig') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_sig') blanco): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_grupos') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_grupos') blanco): rc=" _rc
                exit _rc
            }

            * -- v1.27: CAUSA REAL de fondo (encontrada por fin, tras
            * v1.24/v1.25/v1.26 -- los 3 apuntaban al border(all,nil) en
            * bloque, y los 3 fallaron porque ESE no era el problema
            * real): el propio archivo ya documentaba desde v1.8 que "en
            * cuanto una celda de la fila 1 recibe su fusion, las
            * direcciones de columna de las celdas SIGUIENTES en esa
            * misma fila dejan de calzar con la numeracion original" --
            * pero esa regla se aplico solo a la FUSION (Paso B) y nunca
            * al FORMATO. Aca el colspan(`nyears') de Estimacion (columna
            * 2) corre las direcciones de TODO lo que esta a su derecha
            * en la fila 1 -- exactamente `c_varpct'/`c_sig'/`c_grupos' --
            * asi que un formato "Paso C" separado, corrido DESPUES de
            * ese colspan(), usaba direcciones ya viejas y terminaba
            * pintando (o limpiando el borde de) la celda equivocada.
            * Por eso Categoria (columna 1, a la izquierda del colspan) y
            * Estimacion (columna 2, el propio destino del colspan, cuya
            * direccion no cambia) SI salian bien, y Var.%/Sig./Grupos
            * (las 3 a la derecha) NO -- el patron exacto reportado con
            * datos reales las 3 veces, con y sin border(). v1.24/v1.25/
            * v1.26 nunca lo vieron porque border(all,nil) en bloque
            * (tbl(.,.)) ANDABA ENCIMA, tapando la causa real con un
            * segundo bug (el que si describian esos comentarios, real
            * pero secundario). Fix: fusion + formato de CADA celda de
            * rowspan puro (1, `c_varpct', `c_sig', `c_grupos') juntos,
            * en el mismo momento -- direccion todavia intacta, ningun
            * colspan() corrido todavia --, y RECIEN DESPUES el colspan()
            * de Estimacion + su propio formato (su direccion, columna 2,
            * es estable: un colspan() nunca corre la direccion de la
            * celda que el mismo fusiona, solo las de su derecha).
            foreach c in 1 `c_varpct' `c_sig' `c_grupos' {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`c'), rowspan(2)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (rowspan tbl(1,`c')): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`c'), `hdr'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (formato tbl(1,`c')): rc=" _rc
                    exit _rc
                }
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,2), colspan(`nyears')
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (colspan tbl(1,2)): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,2), `hdr'
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (formato tbl(1,2)): rc=" _rc
                exit _rc
            }

            * -- fila 2 (anios): no le afecta el colspan() de la fila 1
            * (la direccion de columna se corre solo DENTRO de la fila
            * donde ocurre el colspan(), nunca en otras filas -- por eso
            * esta parte SI podia quedar en un paso aparte, corrido
            * despues, sin el bug de arriba).
            forvalues yi = 1/`nyears' {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2, `=1+`yi''), `hdr'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (formato tbl(2,`=1+`yi'')): rc=" _rc
                    exit _rc
                }
            }

            forvalues i = 1/`nobs' {
                local r = 2 + `i'
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r',1) = ("`=ETIQUETA[`i']'")`ocuerpo_new'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',1) fila `i', etiqueta): rc=" _rc
                    exit _rc
                }
                local yi = 0
                foreach y of local anios {
                    local yi = `yi' + 1
                    * -- v1.19: simbolos del manual (p.25) para casillas
                    * especiales -- "..." (ASCII, no el caracter unicode
                    * de elipsis real, por la misma convencion ASCII-puro
                    * del resto del archivo) = "no disponible" (ESTIMA
                    * missing); "-" = "magnitud cero" (ESTIMA exactamente
                    * 0); "0" sin decimales = "la cantidad no alcanza a
                    * la mitad de la unidad" (ESTIMA != 0 pero redondea a
                    * 0 con los decimales de digits()).
                    if ESTIMA`y'[`i'] == . {
                        local cellnum "..."
                    }
                    else if ESTIMA`y'[`i'] == 0 {
                        local cellnum "-"
                    }
                    else {
                        local rawnum = string(ESTIMA`y'[`i'], "`estfmt'")
                        mata: st_local("cellnum", _tsvyexport_numes("`rawnum'"))
                        if real("`rawnum'") == 0 local cellnum "0"
                    }
                    local paso = `paso' + 1
                    cap noisily putdocx table tbl(`r', `=1+`yi'') = ///
                        ("`cellnum'"), halign(right) `ocuerpo_bare'
                    if _rc {
                        di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`=1+`yi'') fila `i' anio `y''): rc=" _rc
                        exit _rc
                    }
                }
                * -- v1.19: VARPCT missing (denominador 0 o missing) ->
                * "..." ("no disponible"), mismo simbolo que ESTIMA.
                if VARPCT[`i'] == . {
                    local vpnum "..."
                }
                else {
                    * -- v1.20: mismo ancho amplio que ESTIMA (ver
                    * estfmt arriba) por la misma razon -- un Var.%
                    * extremo tampoco debe caer en notacion cientifica.
                    local rawvp = string(VARPCT[`i'], "%20.1f")
                    mata: st_local("vpnum", _tsvyexport_numes("`rawvp'"))
                    if VARPCT[`i'] > 0 local vpnum "+`vpnum'"
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r', `c_varpct') = ("`vpnum'"), halign(right) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_varpct') fila `i', varpct): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r', `c_sig') = ("`=SIG_WALD[`i']'"), halign(center) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_sig') fila `i', sig_wald): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r', `c_grupos') = ("`=GRUPOS[`i']'"), halign(center) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_grupos') fila `i', grupos): rc=" _rc
                    exit _rc
                }

                * -- v1.10: fila NACIONAL sombreada como fila de total,
                * igual que un cuadro real -- solo formato sobre celdas
                * que ya tienen contenido, sin fusion de por medio.
                if NIVEL[`i'] == "NACIONAL" {
                    forvalues c = 1/`ncols' {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`c'), bold shading("D9D9D9")
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (sombreado total tbl(`r',`c')): rc=" _rc
                            exit _rc
                        }
                    }
                }
            }
            }
            else {
            * ---- v1.13: 2+ VARNAME -- filas anidadas NIVEL/CATEGORIA
            * [/CRUCE] con rowspan, una fila por VARNAME, mas dos
            * columnas (Valor/Sig.) por anio -- Sig. es SIG_VS_REF (la
            * significancia de esa categoria contra la de referencia,
            * ese anio), no el test omnibus. El omnibus se mantiene al
            * final como "Sig. Wald" (mismo dato que "Sig." en la rama
            * de 1 sola VARNAME, renombrado aca para no confundirlo con
            * el Sig. por anio). Mismo orden de fusion ya confirmado
            * para el encabezado (rowspan antes que colspan, contenido
            * de toda la fila antes de fusionar); el rowspan del CUERPO
            * (Categoria/Cruce) sigue el mismo principio pero en una
            * combinacion todavia sin confirmar en Stata real -- ver
            * Prueba 10 de test_putdocx_merge.do.
            local c_cat = 1
            local c_cru = 0
            if `hascruce' local c_cru = 2
            local c_var = 2 + `hascruce'
            local c_varpct  = `c_var' + 2*`nyears' + 1
            local c_sigwald = `c_varpct' + 1
            local c_grupos  = `c_sigwald' + 1
            local ncols = `c_grupos'
            local nrows = 2 + `nobs'

            * -- columnas "etiqueta" del encabezado (rowspan(2) + formato):
            * Cruce solo entra en la lista si el frame lo trae -- si no,
            * `c_cru' vale 0 y NO debe colarse en un foreach (columna 0
            * no existe).
            local hdrcols `c_cat'
            if `hascruce' local hdrcols `hdrcols' `c_cru'
            local hdrcols `hdrcols' `c_var' `c_varpct' `c_sigwald' `c_grupos'

            * -- orden de filas: NIVEL/CATEGORIA [/CRUCE] contiguos, para
            * que el rowspan cubra un rango solido de filas -- y el
            * bloque NACIONAL (si esta) primero, no ultimo (v1.15,
            * __NACPRIMERO ya viene calculado de mas arriba).
            if `hascruce' quietly gsort -__NACPRIMERO NIVEL CATEGORIA CRUCE VARNAME
            else quietly gsort -__NACPRIMERO NIVEL CATEGORIA VARNAME
            * -- v1.31 NOTA (corregido en v1.36, ver abajo): gsort NO deja
            * la bandera de "ordenado" que `by' (sin bysort) exige -- el
            * `by NIVEL CATEGORIA:' de aca abajo va a tirar "not sorted"
            * r(5) la primera vez que se llegue a esta rama (2+
            * VARNAME), pase lo que pase con los datos. No se corrigio
            * en esta pasada porque un `bysort' derecho reordenaria y
            * rompe el orden NACIONAL-primero que el gsort de arriba
            * dejo a proposito (necesario para el rowspan de mas abajo)
            * -- el fix correcto necesita computar CATFIRST/CATN sin
            * perder ese orden (p.ej. comparando contra la fila anterior
            * en vez de `by') y probarse en Stata real antes de tocarlo,
            * esta rama ya estaba marcada como "sin confirmar" (ver nota
            * mas arriba, v1.13). Esta rama NO se activo en el caso que
            * reporto el bug (1 sola VARNAME) -- ver el fix real en el
            * `sort' agregado antes del reshape, mas arriba.
            * -- v1.36 -- FIX del bug descrito arriba: se guarda el orden
            * del gsort en __ORD, se calculan CATFIRST/CATN (y CRUFIRST/
            * CRUN) con bysort usando __ORD como orden interno del grupo,
            * y se vuelve al orden original con sort __ORD. Como el gsort
            * ya dejo cada NIVEL x CATEGORIA [x CRUCE] en filas contiguas,
            * la primera fila de cada grupo segun __ORD es la primera en
            * la tabla, y el orden NACIONAL-primero se conserva.
            quietly gen long __ORD = _n
            quietly bysort NIVEL CATEGORIA (__ORD): gen byte CATFIRST = (_n==1)
            quietly bysort NIVEL CATEGORIA (__ORD): gen long CATN = _N
            if `hascruce' {
                quietly bysort NIVEL CATEGORIA CRUCE (__ORD): gen byte CRUFIRST = (_n==1)
                quietly bysort NIVEL CATEGORIA CRUCE (__ORD): gen long CRUN = _N
            }
            quietly sort __ORD

            local paso = `paso' + 1
            cap noisily putdocx table tbl = (`nrows', `ncols'), layout(fixed)
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (crear tabla `nrows' x `ncols'): rc=" _rc
                exit _rc
            }
            * -- v1.32/v1.33: mismo fix que la rama de 1 VARNAME (ver esa
            * nota mas arriba) -- reparte 6.5in entre las `ncols'
            * columnas apenas creada la tabla, antes de cualquier
            * fusion, con un loop columna por columna (width() es un
            * row_col_option, valido solo en tbl(., j), no en tbl(.,.)).
            local tblwidth_in = 6.5
            local colwidth_in = `tblwidth_in' / `ncols'
            forvalues j_v132 = 1/`ncols' {
                quietly putdocx table tbl(., `j_v132'), width(`colwidth_in')
            }
            * Paso A: contenido de las 2 filas de encabezado, numeracion
            * original completa, sin fusiones todavia.
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_cat') = ("Categor`_i'a")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_cat')): rc=" _rc
                exit _rc
            }
            if `hascruce' {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`c_cru') = ("Cruce")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_cru')): rc=" _rc
                    exit _rc
                }
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_var') = ("Variable")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_var')): rc=" _rc
                exit _rc
            }
            local yi = 0
            foreach y of local anios {
                local yi = `yi' + 1
                local cv = `c_var' + 1 + 2*(`yi'-1)
                local cs = `cv' + 1
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`cv') = ("`y'")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`cv') anio `y''): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,`cv') = ("Valor")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`cv') Valor `y''): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,`cs') = ("Sig.")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`cs') Sig `y''): rc=" _rc
                    exit _rc
                }
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_varpct') = ("Var. % `ultimo'/`penultimo'")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_varpct')): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_sigwald') = ("Sig. Wald")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_sigwald')): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(1,`c_grupos') = ("Grupos")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(1,`c_grupos')): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_cat') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_cat') blanco): rc=" _rc
                exit _rc
            }
            if `hascruce' {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,`c_cru') = ("")
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_cru') blanco): rc=" _rc
                    exit _rc
                }
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_var') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_var') blanco): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_varpct') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_varpct') blanco): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_sigwald') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_sigwald') blanco): rc=" _rc
                exit _rc
            }
            local paso = `paso' + 1
            cap noisily putdocx table tbl(2,`c_grupos') = ("")
            if _rc {
                di as err "tsvyexport DEBUG paso `paso' (contenido tbl(2,`c_grupos') blanco): rc=" _rc
                exit _rc
            }

            * -- v1.27: mismo fix que en la rama de 1 VARNAME (ver el
            * comentario largo mas arriba) -- fusion + formato de cada
            * columna de rowspan puro (`hdrcols', todas a la IZQUIERDA o
            * a la DERECHA de los colspan() de anio, nunca dentro de
            * ellos) juntos, en el mismo momento, ANTES de tocar ningun
            * colspan() -- asi ninguna queda con una direccion que un
            * colspan() posterior vaya a correr. `c_varpct'/`c_sigwald'/
            * `c_grupos' son justo las 3 a la derecha de TODOS los
            * colspan() de anio -- las que el bug real afectaba.
            foreach c in `hdrcols' {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`c'), rowspan(2)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (rowspan encabezado tbl(1,`c')): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`c'), `hdr'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (formato tbl(1,`c')): rc=" _rc
                    exit _rc
                }
            }
            * -- v1.14: los colspan() de anio van de DERECHA A IZQUIERDA
            * (el ultimo anio primero) -- ver el cambio de version arriba
            * para la evidencia real que obligo este orden. v1.27: ahora
            * cada colspan() lleva su propio formato PEGADO (misma dupla
            * fusion+formato de arriba) -- la direccion de su propia
            * celda (`cv') es estable (un colspan() nunca corre la
            * direccion de la celda que el mismo fusiona), y como el
            * orden es derecha-a-izquierda, ningun colspan() de esta
            * fila corre todavia la direccion `cv' de la iteracion
            * siguiente (mas a la izquierda) cuando se la usa.
            forvalues yi = `nyears'(-1)1 {
                local cv = `c_var' + 1 + 2*(`yi'-1)
                local cs = `cv' + 1
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,`cv'), colspan(2)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (colspan encabezado tbl(1,`cv')): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,`cv'), `hdr'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (formato tbl(2,`cv')): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,`cs'), `hdr'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (formato tbl(2,`cs')): rc=" _rc
                    exit _rc
                }
            }

            * Paso D: contenido del cuerpo -- TODAS las filas primero, con
            * "" en las celdas que un rowspan va a absorber (misma logica
            * que el encabezado), antes de fusionar nada.
            forvalues i = 1/`nobs' {
                local r = 2 + `i'
                if CATFIRST[`i'] {
                    local paso = `paso' + 1
                    cap noisily putdocx table tbl(`r',`c_cat') = ("`=ETIQUETA[`i']'")`ocuerpo_new'
                    if _rc {
                        di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_cat') fila `i', categoria): rc=" _rc
                        exit _rc
                    }
                }
                else {
                    local paso = `paso' + 1
                    cap noisily putdocx table tbl(`r',`c_cat') = ("")`ocuerpo_new'
                    if _rc {
                        di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_cat') fila `i', blanco): rc=" _rc
                        exit _rc
                    }
                }
                if `hascruce' {
                    if CRUFIRST[`i'] {
                        * -- v1.16: CRUCE_LBL (texto real), si esta
                        * disponible y no en blanco para esta fila.
                        local crucetxt = string(CRUCE[`i'])
                        if `hascrulbl' & CRUCE_LBL[`i'] != "" local crucetxt = CRUCE_LBL[`i']
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`c_cru') = ("`crucetxt'")`ocuerpo_new'
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_cru') fila `i', cruce): rc=" _rc
                            exit _rc
                        }
                    }
                    else {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`c_cru') = ("")`ocuerpo_new'
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_cru') fila `i', blanco): rc=" _rc
                            exit _rc
                        }
                    }
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r',`c_var') = ("`=VARNAME[`i']'")`ocuerpo_new'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_var') fila `i', variable): rc=" _rc
                    exit _rc
                }
                local yi = 0
                foreach y of local anios {
                    local yi = `yi' + 1
                    local cv = `c_var' + 1 + 2*(`yi'-1)
                    local cs = `cv' + 1
                    * -- v1.19: simbolos del manual (p.25) para casillas
                    * especiales -- "..." (ASCII, no el caracter unicode
                    * de elipsis real, por la misma convencion ASCII-puro
                    * del resto del archivo) = "no disponible" (ESTIMA
                    * missing); "-" = "magnitud cero" (ESTIMA exactamente
                    * 0); "0" sin decimales = "la cantidad no alcanza a
                    * la mitad de la unidad" (ESTIMA != 0 pero redondea a
                    * 0 con los decimales de digits()).
                    if ESTIMA`y'[`i'] == . {
                        local cellnum "..."
                    }
                    else if ESTIMA`y'[`i'] == 0 {
                        local cellnum "-"
                    }
                    else {
                        local rawnum = string(ESTIMA`y'[`i'], "`estfmt'")
                        mata: st_local("cellnum", _tsvyexport_numes("`rawnum'"))
                        if real("`rawnum'") == 0 local cellnum "0"
                    }
                    local paso = `paso' + 1
                    cap noisily putdocx table tbl(`r',`cv') = ("`cellnum'"), halign(right) `ocuerpo_bare'
                    if _rc {
                        di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`cv') fila `i' anio `y''): rc=" _rc
                        exit _rc
                    }
                    if `hassig' {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`cs') = ("`=SIG_VS_REF`y'[`i']'"), halign(center) `ocuerpo_bare'
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`cs') fila `i' anio `y'', sig): rc=" _rc
                            exit _rc
                        }
                    }
                    else {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`cs') = ("")`ocuerpo_new'
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`cs') fila `i' anio `y'', blanco): rc=" _rc
                            exit _rc
                        }
                    }
                }
                * -- v1.19: VARPCT missing (denominador 0 o missing) ->
                * "..." ("no disponible"), mismo simbolo que ESTIMA.
                if VARPCT[`i'] == . {
                    local vpnum "..."
                }
                else {
                    * -- v1.20: mismo ancho amplio que ESTIMA (ver
                    * estfmt arriba) por la misma razon -- un Var.%
                    * extremo tampoco debe caer en notacion cientifica.
                    local rawvp = string(VARPCT[`i'], "%20.1f")
                    mata: st_local("vpnum", _tsvyexport_numes("`rawvp'"))
                    if VARPCT[`i'] > 0 local vpnum "+`vpnum'"
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r',`c_varpct') = ("`vpnum'"), halign(right) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_varpct') fila `i', varpct): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r',`c_sigwald') = ("`=SIG_WALD[`i']'"), halign(center) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_sigwald') fila `i', sig_wald): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`r',`c_grupos') = ("`=GRUPOS[`i']'"), halign(center) `ocuerpo_bare'
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (tbl(`r',`c_grupos') fila `i', grupos): rc=" _rc
                    exit _rc
                }
            }

            * Paso E: fusiones del CUERPO -- rowspan de Categoria en todas
            * sus filas de inicio, despues rowspan de Cruce (si existe) en
            * las suyas. Nunca se llama rowspan(1) (una sola fila no
            * necesita fusion). ESTA combinacion (un rowspan que arranca
            * dentro del rango de otro, en una columna distinta) es la
            * que prueba, aislada, la Prueba 10 de test_putdocx_merge.do.
            forvalues i = 1/`nobs' {
                local r = 2 + `i'
                if CATFIRST[`i'] & CATN[`i'] > 1 {
                    local paso = `paso' + 1
                    cap noisily putdocx table tbl(`r',`c_cat'), rowspan(`=CATN[`i']')
                    if _rc {
                        di as err "tsvyexport DEBUG paso `paso' (rowspan cuerpo tbl(`r',`c_cat')): rc=" _rc
                        exit _rc
                    }
                }
            }
            if `hascruce' {
                forvalues i = 1/`nobs' {
                    local r = 2 + `i'
                    if CRUFIRST[`i'] & CRUN[`i'] > 1 {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`c_cru'), rowspan(`=CRUN[`i']')
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (rowspan cuerpo tbl(`r',`c_cru')): rc=" _rc
                            exit _rc
                        }
                    }
                }
            }

            * -- v1.10 (extendido a esta rama): fila NACIONAL sombreada.
            forvalues i = 1/`nobs' {
                local r = 2 + `i'
                if NIVEL[`i'] == "NACIONAL" {
                    forvalues c = 1/`ncols' {
                        local paso = `paso' + 1
                        cap noisily putdocx table tbl(`r',`c'), bold shading("D9D9D9")
                        if _rc {
                            di as err "tsvyexport DEBUG paso `paso' (sombreado total tbl(`r',`c')): rc=" _rc
                            exit _rc
                        }
                    }
                }
            }
            }

            * -- v1.21: "tabla de tres lineas" para apa7/revista -- APA7
            * exige SOLO bordes horizontales (arriba de la tabla, bajo el
            * encabezado, al final de la tabla), nunca verticales;
            * "revista" sigue la misma convencion (es el estandar de
            * facto en journals de economia/ciencias sociales tambien).
            * v1.26: aca solo quedan las 3 lineas puntuales, agregadas
            * DESPUES de todo el contenido/shading/font -- el "limpiar
            * todo" (border(all,nil)) ya no es un paso aparte, quedo
            * repartido celda por celda dentro de `hdr'/`ocuerpo_bare'
            * (ver el comentario junto a esos locales, mas arriba) para
            * evitar el barrido en bloque (tbl(.,.)) que en v1.21-v1.25
            * le rompio el sombreado del encabezado dos veces distintas
            * (Var.%/Sig./Grupos primero, despues solo Var.%), siempre
            * con datos reales. Estas 3 lineas SI usan rango por fila
            * (tbl(1,.), etc.) porque solo AGREGAN un borde puntual, no
            * limpian nada -- mecanica ya confirmada en Stata real
            * (Prueba 13/14 de test_putdocx_merge.do). El encabezado
            * siempre ocupa las filas 1-2 en las 2 ramas (`nrows'/`ncols'
            * quedan en scope aca porque las dos ramas los definen con la
            * misma formula).
            if inlist("`estilo'", "apa7", "revista") {
                local paso = `paso' + 1
                cap noisily putdocx table tbl(1,.), border(top, single)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (borde superior tbl(1,.)): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(2,.), border(bottom, single)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (borde bajo encabezado tbl(2,.)): rc=" _rc
                    exit _rc
                }
                local paso = `paso' + 1
                cap noisily putdocx table tbl(`nrows',.), border(bottom, single)
                if _rc {
                    di as err "tsvyexport DEBUG paso `paso' (borde final tbl(`nrows',.)): rc=" _rc
                    exit _rc
                }
            }

            * -- v1.10: leyenda de Sig./Grupos debajo del cuadro, igual
            * que la nota que ya trae un cuadro armado a mano. Solo
            * opciones ya validadas en este mismo archivo (paragraph
            * sin opciones, text con italic) -- nada nuevo sin probar.
            * -- v1.30 -- "Grupos:" pasa a "Grupos (metodo):" cuando se
            * pudo leer que cldmetodo() uso tsvy (ver lectura de
            * `etiqueta_cldmetodo' mas arriba, junto a la copia de
            * trabajo) -- vacio (texto generico de siempre, sin el
            * parentesis) si el frame no trae esa characteristic.
            * -- v1.37 -- leyenda reescrita: (1) tildes/enie reales (via
            * uchar(), ver arriba); (2) "Grupos (metodo)" solo menciona el
            * parentesis por fila si alguna fila de verdad uso otro metodo
            * (cldmetodo(auto)); (3) "? indica..." solo si hay algun "?" en
            * GRUPOS; (4) "Sig. (por anio)" solo si alguna celda de
            * SIG_VS_REF trae dato, y con el texto correcto: compara ESE
            * anio contra el anio de referencia (refyear()), no contra una
            * categoria de referencia.
            local grupos_lbl ""
            if `"`etiqueta_cldmetodo'"' != "" local grupos_lbl " (`etiqueta_cldmetodo')"
            if `metvaria' local grupos_lbl " (Bonferroni; entre par`_e'ntesis, el m`_e'todo menos estricto usado en esa fila porque con Bonferroni la prueba F era significativa y todos los a`_n'os compart`_i'an letra)"
            quietly count if strpos(GRUPOS, "?")
            local hayinterrog = r(N) > 0
            local hassigdat = 0
            if `hassig' {
                foreach y of local anios {
                    quietly count if SIG_VS_REF`y' != ""
                    if r(N) > 0 local hassigdat = 1
                }
            }
            local siglbl = cond(`nvarnames' == 1, "Sig.", "Sig. Wald")
            local leyenda "`siglbl': significancia de la prueba F de Wald de igualdad entre los a`_n'os (`sig_leyenda')."
            local leyenda "`leyenda' Grupos`grupos_lbl': a`_n'os con la misma letra no presentan diferencia estad`_i'sticamente significativa entre s`_i' (Compact Letter Display)."
            if `hayinterrog' local leyenda "`leyenda' ? indica que la prueba no se pudo calcular en ese a`_n'o."
            if `nvarnames' > 1 & `hassigdat' local leyenda "`leyenda' Sig. (por a`_n'o): significancia de la diferencia entre ese a`_n'o y el a`_n'o de referencia."
            if `n_incons' > 0 local leyenda "`leyenda' b/ La prueba F de Wald es significativa, pero ning`_u'n par de a`_n'os difiere tras el ajuste por comparaciones m`_u'ltiples."

            local paso = `paso' + 1
            cap noisily putdocx paragraph
            if !_rc {
                cap noisily putdocx text ("`leyenda'"), italic `onota_bare'
            }

            * -- v1.19: Fuente/Elaboracion, ultimas 2 lineas del pie del
            * cuadro segun el manual (p.26-27: "notas, llamadas, fuente
            * y elaboracion", en ese orden -- la leyenda de Sig./Grupos
            * de arriba hace de nota). Opcionales: si el usuario no pasa
            * fuente()/elaboracion() el cuadro sale igual que siempre
            * (sin estas lineas). tamano() es una suboption DENTRO de
            * cada una (fuente("texto", tamano(#))), no una option
            * aparte -- asi cada linea puede llevar su propio tamano;
            * ya se parsearon arriba en fuentetxt'/ftam' y elabtxt'/
            * elabtam' (default 9 puntos, menor al cuerpo del documento,
            * como en los ejemplos del manual). font("`estfont'", #) en
            * vez de size(#) suelto -- estfont' es "" sin estilo(), y
            * font("", #) es justamente como putdocx deja fijar SOLO el
            * tamano sin tocar la fuente (ver help putdocx paragraph).
            if `"`fuentetxt'"' != "" {
                cap noisily putdocx paragraph
                cap noisily putdocx text ("Fuente: `fuentetxt'."), font("`estfont'", `ftam')
            }
            if `"`elabtxt'"' != "" {
                cap noisily putdocx paragraph
                cap noisily putdocx text ("Elaboraci`_o'n: `elabtxt'."), font("`estfont'", `elabtam')
            }

            local nvars = `ncols'

            if `doappend' putdocx save "`using'", append(pagebreak)
            else putdocx save "`using'", replace
        }
        else {
            putdocx begin
            local titletext `"`title'"'
            if `"`numero'"' != "" {
                if `"`titletext'"' != "" {
                    local titleupper = strupper(`"`titletext'"')
                    local titletext `"`numero' `titleupper'"'
                }
                else local titletext `"`numero'"'
            }
            if `"`titletext'"' != "" {
                putdocx paragraph, style(Title)
                putdocx text (`"`titletext'"')
                if `"`unidad'"' != "" {
                    putdocx paragraph
                    putdocx text ("(`unidad')")
                }
            }
            putdocx table tbl = data(`expvars'), varnames
            putdocx table tbl(1,.), shading("D9E2F3") bold border(all, single)

            local sigpos: list posof "SIG_VS_REF" in expvars
            if `sigpos' == 0 local sigpos: list posof "SIG_WALD" in expvars
            if `sigpos' > 0 {
                forvalues i = 1/`nobs' {
                    local r = `i' + 1
                    putdocx table tbl(`r', `sigpos'), script(super)
                }
            }

            if `doappend' putdocx save "`using'", append(pagebreak)
            else putdocx save "`using'", replace
        }
    }

    cap frame drop TSVYEXPORT_TMP

    local fmtmsg "`fmt'"
    if "`fmt'" == "excel" local fmtmsg "excel, hoja `sheet'"
    di as text "tsvyexport: `nobs' filas x `nvars' columnas exportadas a " ///
        as res "`using'" as text " (`fmtmsg')"
end

* -- v1.35 -- parsea "texto [, tamano(#)]" de fuente()/elaboracion() en
* su propio ambito de locales (ver nota v1.35 en el cuerpo principal).
capture program drop _tsvyexport_txtopt
program define _tsvyexport_txtopt, rclass
    syntax anything(everything) [, TAMANO(integer -1)]
    local txt `anything'
    return local txt `"`txt'"'
    return scalar tam = cond(`tamano' > 0, `tamano', .)
end

version 16
mata:
string scalar _tsvyexport_xlcol(real scalar c)
{
    string scalar s
    real scalar rem
    s = ""
    while (c > 0) {
        rem = mod(c - 1, 26)
        s = char(65 + rem) + s
        c = floor((c - 1) / 26)
    }
    return(s)
}

// v1.10 -- formato numerico al estilo peruano/latinoamericano para el
// cuadro wide()+Word: separador de miles con espacio ("16 681"), coma
// decimal ("18,6"), guion normal para negativos (no el signo menos
// unicode que usan reportes reales -- este .ado se mantiene ASCII puro
// a proposito, ver convencion del resto del archivo). Toma un numero
// YA formateado por Stata (string(x, "%N.Mf")) y solo le cambia los
// separadores -- no redondea ni recalcula nada.
string scalar _tsvyexport_numes(string scalar s)
{
    string scalar sign, intpart, decpart, grouped, ch
    real scalar dotpos, n, i

    s = strtrim(s)
    if (s == "." | s == "") return("")

    sign = ""
    if (substr(s, 1, 1) == "-") {
        sign = "-"
        s = substr(s, 2, .)
    }

    dotpos = strpos(s, ".")
    if (dotpos) {
        intpart = substr(s, 1, dotpos - 1)
        decpart = substr(s, dotpos + 1, .)
    }
    else {
        intpart = s
        decpart = ""
    }

    n = strlen(intpart)
    grouped = ""
    for (i = 1; i <= n; i++) {
        grouped = grouped + substr(intpart, i, 1)
        if (mod(n - i, 3) == 0 & i != n) grouped = grouped + " "
    }

    if (decpart != "") return(sign + grouped + "," + decpart)
    return(sign + grouped)
}
end
