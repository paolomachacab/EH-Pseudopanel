* EH Pseudopanel Building Script  
* Author: Paolo Machaca

clear all
cls

********************************************************************************
**# 1. Definir Global genérico 
********************************************************************************

* Defina la ruta principal donde se encuentran sus datos
* Cambie "[tu_ruta_local]" por la ubicación correspondiente en su computadora

global path "[tu_ruta_local]"
global raw "$path/raw"
global processed "$path/processed"
global out "$path/output"
global temp "$path/temp"
global aux "$path/aux"

********************************************************************************
**# 2. Cargar y limpiar cada año
********************************************************************************

local years "2015 2016 2017 2018 2019 2021 2022 2023"

foreach year in `years' {
    use "$raw/EH`year'_Persona.dta", clear
    keep folio factor estrato upm depto area sexo edad niv_ed_g yhogpc
    gen enc_year = `year'
    gen mujer = (sexo == 2)
    rename yhogpc ingreso_pc
    save "$processed/EH`year'_clean.dta", replace
}

********************************************************************************
**# 3. Unir las bases usando append
********************************************************************************

* 1: Append secuencial desde un primer archivo base
use "$processed/EH2015_clean.dta", clear
foreach year in 2016 2017 2018 2019 2021 2022 2023 {
    append using "$processed/EH`year'_clean.dta"
}

* 2: Append por lotes desde archivos individuales
* Esta opción es útil cuando no se quiere usar una base inicial como referencia
* 
* local files: nombre de archivos a unir
* local files: "EH2015_clean.dta EH2016_clean.dta ..."
* foreach file in `files' {
*     append using "$processed/`file'"
* }

order folio enc_year depto area sexo mujer edad ingreso_pc
rename enc_year year

********************************************************************************
**# 4. Variables adicionales para análisis
********************************************************************************

foreach y in `years' {
    gen pobreza`y' = (ingreso_pc < 900 & year == `y')
}

egen id_hogar = group(folio year)

********************************************************************************
**# 5. Preparar merge con módulo alternativo
********************************************************************************

* En este ejemplo se muestra cómo agregar un módulo adicional (como el módulo de empleo)
* Usamos "folio" como identificador único entre módulos de un mismo año

foreach year in 2015 2016 2017 2018 2019 2021 2022 2023 {
    use "$processed/EH`year'_clean.dta", clear
    merge 1:1 folio using "$raw/EH`year'_Empleo.dta", keepusing(ocupacion rama_actividad categoria_ocupacional) nogenerate
    save "$processed/EH`year'_merged.dta", replace
}

* Reunir todo en un único archivo pseudopanel
use "$processed/EH2015_merged.dta", clear
foreach year in 2016 2017 2018 2019 2021 2022 2023 {
    append using "$processed/EH`year'_merged.dta"
}

save "$processed/EH_Panel_AllYears.dta", replace

********************************************************************************
**# 6. Configuración de diseño muestral y análisis
********************************************************************************

svyset [pw=factor], strata(estrato) psu(upm)

reg ingreso_pc edad i.niv_ed_g mujer i.depto if year==2023 [pw=factor]

********************************************************************************
**# 7. Exportación
********************************************************************************

keep folio year depto ingreso_pc mujer edad ocupacion rama_actividad categoria_ocupacional
export delimited using "$out/EH_Panel_2023_Subset.csv", replace

* Fin del script
```


