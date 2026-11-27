*! sriinei.ado v1.0.1  27nov2026
*! Descarga un modulo de microdatos del portal SRIENAHO del INEI (Peru).
*! Autor: Andres Talavera Cuya
*! Licencia: GNU GPL v3 (https://www.gnu.org/licenses/gpl-3.0.txt)
*! No es un producto oficial del INEI. Ayuda: help sriinei

program define sriinei
    version 14.0

    syntax , CODigo(integer)   ///
             MODulo(integer)   ///
             TIPO(string)      ///
             DEStino(string)   ///
             [ REPLACE         ///
               NOUNzip ]

    local tipo_u = upper("`tipo'")
    if !inlist("`tipo_u'", "SPSS", "STATA", "CSV", "DBF") {
        di as error "tipo() debe ser: spss | stata | csv | dbf"
        exit 198
    }

    local archivo "`codigo'-Modulo`modulo'"
    local url "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/`tipo_u'/`archivo'.zip"
    local marca ".sriinei_`archivo'_`tipo_u'.txt"

    local destino = subinstr(`"`destino'"', char(92), "/", .)
    capture mkdir "`destino'"

    * Ya descargado? (.zip si nounzip; archivo de registro si se descomprimio)
    if "`replace'" == "" {
        local ya_existe = 0
        if "`nounzip'" != "" {
            capture confirm file "`destino'/`archivo'.zip"
            if _rc == 0 local ya_existe = 1
        }
        else {
            capture confirm file "`destino'/`marca'"
            if _rc == 0 local ya_existe = 1
        }
        if `ya_existe' {
            di as text "`archivo' (`tipo_u') ya fue descargado en `destino'" ///
                " -- se omite (use replace para volver a descargar)"
            exit 0
        }
    }

    di as text "Descargando `archivo' (`tipo_u')..."
    di as text "URL: `url'"
    capture copy "`url'" "`destino'/`archivo'.zip", replace
    if _rc {
        local rc = _rc
        di as error "Error al descargar `archivo': revise codigo(), modulo() y tipo()"
        di as error "en el portal https://proyectos.inei.gob.pe/microdatos/ y la conexion."
        exit `rc'
    }

    if "`nounzip'" != "" {
        di as text "Listo (sin descomprimir): " as result "`destino'/`archivo'.zip"
        exit 0
    }

    * Descomprimir y listar lo que se extrajo
    local pwd_actual "`c(pwd)'"
    quietly cd "`destino'"
    local antes_f : dir "." files "*", respectcase
    local antes_d : dir "." dirs "*", respectcase
    * lo extraido en una descarga anterior (para listarlo si se reemplaza)
    local previos ""
    capture confirm file "`marca'"
    if _rc == 0 {
        tempname fr
        file open `fr' using "`marca'", read text
        file read `fr' linea
        file read `fr' linea
        file read `fr' linea
        while r(eof) == 0 {
            local previos `"`previos' "`linea'""'
            file read `fr' linea
        }
        file close `fr'
    }
    capture unzipfile "`archivo'.zip", replace
    local rc = _rc
    if `rc' {
        quietly cd "`pwd_actual'"
        di as error "Error al descomprimir `archivo'.zip; el .zip quedo en `destino'"
        exit `rc'
    }
    erase "`archivo'.zip"
    local despues_f : dir "." files "*", respectcase
    local despues_d : dir "." dirs "*", respectcase
    local nuevos_f : list despues_f - antes_f
    local nuevos_d : list despues_d - antes_d

    * si no hay nada nuevo (se reemplazaron archivos), conservar la lista previa
    local lista ""
    foreach x of local nuevos_f {
        local lista `"`lista' "`x'""'
    }
    foreach x of local nuevos_d {
        local lista `"`lista' "`x'/""'
    }
    local reemplazo = 0
    if `"`lista'"' == "" & `"`previos'"' != "" {
        local lista `"`previos'"'
        local reemplazo = 1
    }

    capture erase "`marca'"
    tempname fh
    file open `fh' using "`marca'", write text
    file write `fh' "sriinei `archivo' `tipo_u'" _n "`url'" _n
    foreach x of local lista {
        file write `fh' "`x'" _n
    }
    file close `fh'
    quietly cd "`pwd_actual'"

    if `reemplazo' {
        di as text "Listo. Reemplazado en " as result "`destino'" as text ":"
    }
    else {
        di as text "Listo. Extraido en " as result "`destino'" as text ":"
    }
    foreach x of local lista {
        if substr("`x'", -1, 1) == "/" di as result "  `x'" as text "  (carpeta)"
        else di as result "  `x'"
    }
    if `"`lista'"' == "" {
        di as text "  (se reemplazaron archivos que ya existian con el mismo nombre)"
    }
end
