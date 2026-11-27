*! bcrpdata.ado v0.2.1  27nov2026
*! Descarga series estadisticas del BCRP (BCRPData) a Stata.
*! Autor: Andres Talavera Cuya
*! Licencia: GNU GPL v3 (https://www.gnu.org/licenses/gpl-3.0.txt)
*! No es un producto oficial del BCRP ni del INEI. Ayuda: help bcrpdata

program define bcrpdata
    version 14.0
    syntax anything(name=codigos id="codigos de series"), ///
        [ FROM(string) TO(string) CLEAR ]

    local codigos = upper(strtrim(`"`codigos'"'))
    local codigos : list uniq codigos
    local nser : word count `codigos'
    if `nser' == 0 {
        di as error "Indique al menos un codigo de serie, ej.: bcrpdata PN01288PM"
        exit 198
    }
    if "`to'" != "" & "`from'" == "" {
        di as error "to() requiere from()"
        exit 198
    }

    * como use: si hay cambios sin guardar, exigir clear
    if "`clear'" == "" & c(changed) {
        di as error "no; los datos en memoria cambiaron -- use la opcion clear"
        exit 4
    }

    * ante cualquier error, devolver los datos en memoria tal como estaban
    preserve

    local base "https://estadisticas.bcrp.gob.pe/estadisticas/series/api"
    local periodo ""
    if "`from'" != "" local periodo "/`from'"
    if "`to'"   != "" local periodo "`periodo'/`to'"

    * la API acepta hasta 10 series por consulta: partir en tandas
    tempfile acum
    local ntanda = 0
    local resto `codigos'
    while "`resto'" != "" {
        local tanda ""
        forvalues j = 1/10 {
            gettoken c resto : resto
            if "`c'" != "" local tanda `tanda' `c'
        }
        local ++ntanda
        local lista = subinstr(strtrim("`tanda'"), " ", "-", .)
        local url "`base'/`lista'/csv`periodo'/ing"
        di as text "Consultando: " as result "`url'"

        tempfile crudo
        capture copy "`url'" "`crudo'", replace
        local rc = _rc
        if `rc' {
            di as error "No se pudo consultar la API (error `rc'); revise la conexion y los codigos."
            exit `rc'
        }

        * la API puede separar las lineas con <br> (HTML) en vez de saltos
        * de linea: convertirlos a saltos de linea reales
        tempfile limpio paso
        quietly copy "`crudo'" "`limpio'", replace
        foreach tag in "<br>" "<BR>" "<br/>" "<BR/>" "<br />" "<BR />" {
            quietly filefilter "`limpio'" "`paso'", from("`tag'") to("\n") replace
            quietly copy "`paso'" "`limpio'", replace
        }

        quietly import delimited using "`limpio'", varnames(nonames) ///
            stringcols(_all) encoding("utf-8") clear
        if c(N) == 1 & c(k) >= 2 {
            if "`from'" == "" {
                di as error "La API respondio, pero no hay datos recientes para: `tanda'"
                di as error "Sin from()/to() la API devuelve solo los ultimos datos; si la serie esta"
                di as error "descontinuada, indique el periodo con from() y to() (ver Fecha Inicio/Fin en BCRPData)."
            }
            else {
                di as error "La API respondio, pero las series no tienen datos entre `from' y `to': `tanda'"
                di as error "Revise Fecha Inicio / Fecha Fin en BCRPData; puede ser una serie descontinuada."
            }
            exit 2000
        }
        if c(N) < 2 | c(k) < 2 {
            tempname fh
            file open `fh' using "`crudo'", read text
            file read `fh' linea
            file close `fh'
            if strpos(lower(`"`macval(linea)'"'), "<!doctype") | strpos(lower(`"`macval(linea)'"'), "<html") {
                di as error "La API no reconoce el codigo: `tanda'"
                di as error "Copie el codigo tal como aparece en la columna Codigo de BCRPData."
                exit 111
            }
            di as error "La API no devolvio datos para: `tanda'"
            di as error "Revise los codigos (todas las series de una consulta deben tener la misma frecuencia) y el periodo."
            di as text "Comienzo de la respuesta de la API:"
            di as result substr(`"`macval(linea)'"', 1, 400)
            exit 459
        }

        * columna 1 = periodo; columnas 2.. = series, en el orden pedido
        * (la API omite las series de otra frecuencia que la primera)
        rename v1 periodo_txt
        local ncol = c(k) - 1
        if `ncol' != `: word count `tanda'' {
            di as text "Aviso: se pidieron " `: word count `tanda'' " series y la API devolvio `ncol'." ///
                " Las series de otra frecuencia que la primera se omiten."
        }
        unab vs : v*
        local i = 0
        foreach v of local vs {
            local ++i
            local cod : word `i' of `tanda'
            local etiq = `v'[1]
            * entidades HTML que a veces trae la API
            foreach par in "aacute á" "eacute é" "iacute í" "oacute ó" "uacute ú" ///
                "Aacute Á" "Eacute É" "Iacute Í" "Oacute Ó" "Uacute Ú" ///
                "ntilde ñ" "Ntilde Ñ" "uuml ü" "Uuml Ü" "deg °" {
                gettoken ent car : par
                local car = strtrim("`car'")
                local etiq : subinstr local etiq "&`ent';" "`car'", all
            }
            local etiq : subinstr local etiq "&amp;" "&", all
            local etiq = strtrim(`"`etiq'"')
            rename `v' `cod'
            * nombre completo en char; etiqueta: si pasa de 80 caracteres,
            * la parte final (despues del ultimo " - "), que distingue la serie
            char `cod'[nombre] `"`etiq'"'
            local corta `"`etiq'"'
            if ustrlen(`"`etiq'"') > 80 {
                local pos = ustrrpos(`"`etiq'"', " - ")
                if `pos' > 0 {
                    local corta = usubstr(`"`etiq'"', `pos' + 3, .)
                    * agregar la unidad: primer parentesis de la parte inicial
                    local ini = usubstr(`"`etiq'"', 1, `pos' - 1)
                    if ustrregexm(`"`ini'"', "\([^()]*\)") {
                        local unidad = ustrregexs(0)
                        local corta `"`corta' `unidad'"'
                    }
                }
                if ustrlen(`"`corta'"') > 80 local corta = usubstr(`"`corta'"', 1, 77) + "..."
            }
            label variable `cod' `"`corta'"'
        }
        quietly drop in 1
        foreach v of local tanda {
            capture confirm variable `v'
            if !_rc quietly destring `v', replace force
        }
        if `ntanda' > 1 {
            quietly merge 1:1 periodo_txt using "`acum'", nogenerate
        }
        quietly save "`acum'", replace
    }

    * meses en espanol -> ingles (Ene, Abr, Ago, Dic; el resto coincide)
    quietly {
        replace periodo_txt = subinstr(periodo_txt, "Ene.", "Jan.", 1)
        replace periodo_txt = subinstr(periodo_txt, "Abr.", "Apr.", 1)
        replace periodo_txt = subinstr(periodo_txt, "Ago.", "Aug.", 1)
        replace periodo_txt = subinstr(periodo_txt, "Dic.", "Dec.", 1)
    }

    * convertir el periodo a fecha de Stata segun su forma
    quietly {
        local p = periodo_txt[1]
        gen double fecha = .
        if regexm("`p'", "^[A-Za-z]{3}\.[0-9]{4}$") {
            replace fecha = monthly(subinstr(periodo_txt, ".", " ", .), "MY")
            format fecha %tmMon_CCYY
            local frec "mensual"
        }
        else if regexm("`p'", "^[QqTt][1-4]\.?([0-9][0-9]|[0-9][0-9][0-9][0-9])$") {
            * trimestre: T180, T1.80, Q1.2024... (letra, trimestre, punto opcional, anio)
            gen int _q = real(substr(periodo_txt, 2, 1))
            gen int _y = real(subinstr(substr(periodo_txt, 3, .), ".", "", .))
            replace _y = _y + cond(_y < 50, 2000, 1900) if _y < 100
            replace fecha = yq(_y, _q)
            drop _q _y
            format fecha %tq
            local frec "trimestral"
        }
        else if regexm("`p'", "^[0-9]{4}$") {
            replace fecha = real(periodo_txt)
            format fecha %ty
            local frec "anual"
        }
        else if regexm("`p'", "^[0-9]{1,2}\.[A-Za-z]{3}\.[0-9]{2}([0-9]{2})?$") {
            replace fecha = date(subinstr(periodo_txt, ".", " ", .), "DMY", 2050)
            format fecha %td
            local frec "diaria"
        }
        else local frec ""
    }
    if "`frec'" == "" | missing(fecha[1]) {
        drop fecha
        rename periodo_txt periodo
        di as text "Aviso: no se reconocio el formato del periodo (ej. " as result `"`p'"' as text ");" ///
            " se deja como texto en la variable periodo."
    }
    else {
        drop periodo_txt
        sort fecha
        order fecha
        label variable fecha "Periodo"
        if "`frec'" == "mensual"         quietly tsset fecha, monthly
        else if "`frec'" == "trimestral" quietly tsset fecha, quarterly
        else if "`frec'" == "anual"      quietly tsset fecha, yearly
        else                             quietly tsset fecha, daily
    }

    restore, not
    global S_FN ""
    di as text _n "Listo: " as result c(N) as text " periodos y " ///
        as result c(k) - 1 as text " series" cond("`frec'" != "", " (`frec')", "") "."
    describe, simple
end
