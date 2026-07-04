# ==============================================================================
# Proyecto: Análisis de la inseguridad alimentaria utilizando datos de la ENAHO
# Script: Acondicionamiento
# Autora: Micaela Cusipuma
# Fecha: 02-07-2026
# Objetivo: Acondicionar la base de datos consolidada (Tipado, Selección,
#           Renombrado, Tratamiento de NAs).
# ==============================================================================
rm(list = ls())
# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN DEL ENTORNO--------------------------------------------------
# ------------------------------------------------------------------------------
library(tidyverse)
library(arrow)
library(janitor)
library(naniar)
renv::snapshot()

# ------------------------------------------------------------------------------
# 1. CARGA, SELECCIÓN, RENOMBRADO Y DIAGNÓSTICO---------------------------------
# ------------------------------------------------------------------------------
base_raw <- read_parquet("datos/procesados/base_por_persona_180626.parquet")

# Seleccionamos las variables de nuestro interés y renombramos con dplyr
# Usamos los sufijos "_edu"/"_ia" para las columnas que quedaron duplicadas
# tras el left_join (comparten nombre en mod300 y mod130 pero no forman parte
# de las keys de unión).
base_seleccion <- base_raw %>%
  select(
    # Llaves de integración y factores de expansión
    año         = AÑO,
    mes         = MES,
    conglome    = CONGLOME,
    nconglome   = NCONGLOME_edu,
    subconglome = SUB_CONGLOME_edu,
    vivienda    = VIVIENDA,
    hogar       = HOGAR,
    codperso    = CODPERSO,
    codinfor    = CODINFOR,
    ubigeo      = UBIGEO_edu,
    dominio     = DOMINIO_edu,
    estrato     = ESTRATO_edu,
    factor07    = FACTOR07_edu,
    
    # Demográficas (módulo 300)
    sexo  = P207_edu,
    edad  = P208A,
    
    # Educación (módulo 300)
    nivel_edu   = P301A,   # Nivel educativo alcanzado (1-12, 99=missing)
    matricula_anterior = P303,  # ¿Estuvo matriculado el año pasado?
    
    # Inseguridad Alimentaria - Escala FIES (módulo 130)
    ia_preocupacion   = P130_1,  # Preocupación por falta de comida
    ia_no_saludable   = P130_2,  # No comió alimentos saludables/nutritivos
    ia_no_variado     = P130_3,  # No comió alimentos variados
    ia_saltó_comida   = P130_4,  # Dejó de desayunar/almorzar/cenar
    ia_comió_menos    = P130_5,  # Comió menor cantidad de lo normal
    ia_sin_alimentos  = P130_6,  # El hogar se quedó sin alimentos
    ia_hambre         = P130_7,  # Tuvo hambre pero no comió
    ia_dia_sin_comer  = P130_8,  # Estuvo sin comer un día entero
  )

# Inspección rápida
dim(base_seleccion)
names(base_seleccion)
glimpse(base_seleccion)

# ------------------------------------------------------------------------------
# 2. DIAGNÓSTICO DE NAs Y REPORTE-----------------------------------------------
# ------------------------------------------------------------------------------

# 2.1 Visualización gráfica (naniar)
grafico_nas <- gg_miss_var(base_seleccion, show_pct = TRUE) +
  labs(
    title = "Porcentaje de Valores Perdidos (NAs) por Variable",
    subtitle = "Proyecto: Inseguridad Alimentaria usando datos de la ENAHO (2025)",
    y = "% de Valores Perdidos",
    x = "Variables"
  ) +
  theme_minimal()

print(grafico_nas)

ggsave("outputs/Grafico_NAs_InseguridadAlimentaria.jpg", plot = grafico_nas,
       width = 8, height = 6, bg = "white")

# 2.2 Reporte tabular
reporte_nas <- base_seleccion %>%
  summarise(across(everything(), ~ round(sum(is.na(.)) / n() * 100, 2))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "porcentaje_na") %>%
  arrange(desc(porcentaje_na))

write_csv(reporte_nas, "outputs/Reporte_Datos_Perdidos_ENAHO.csv")

# ------------------------------------------------------------------------------
# 3. TRATAMIENTO DE NAs---------------------------------------------------------
# ------------------------------------------------------------------------------

table(base_seleccion$nivel_edu, useNA = "ifany")       # Nivel educativo (MCAR, código 99)
table(base_seleccion$ia_preocupacion, useNA = "ifany") # Inseguridad alimentaria (Estructural + MAR)

# ------------------------------------------------------------------------------
# CASO 1: MCAR (Missing Completely At Random)
# Variable: nivel_edu
# Problema: Existe el código "99" (No especificado) en una proporción muy
# pequeña de casos (~0.1%), sin un patrón identificable por edad u otra variable.
# Estrategia: Eliminación (Listwise)
# ------------------------------------------------------------------------------

diagnostico_nivel_edu <- base_seleccion %>%
  count(nivel_edu) %>%
  arrange(desc(n))
print(diagnostico_nivel_edu)

base_tratada <- base_seleccion %>%
  mutate(nivel_edu = na_if(nivel_edu, 99)) %>%
  drop_na(nivel_edu)

sum(is.na(base_tratada$nivel_edu)) # Debería salir 0

# ------------------------------------------------------------------------------
# CASO 2: MCAR Estructural (a nivel de hogar) + MAR
# Variables: ia_preocupacion ... ia_dia_sin_comer (escala FIES completa)
# Problema: El módulo 130 no se aplicó a todos los hogares del corte mensual
# (~45% de las personas quedan con NA real tras el left_join). Adicionalmente, dentro de los
# hogares que sí respondieron hay una proporción pequeña con código "3" (No
# sabe) y "4" (No responde) en cada pregunta.
# Estrategia: Primero, eliminaremos los casos sin módulo aplicado y en segundo lugar recodificaremos 
#             los "No sabe"/"No responde" como NA, para aplicar
#             imputación simple por moda (categoría más frecuente) en
#             cada pregunta, dado que es una proporción muy pequeña de MAR.
# ------------------------------------------------------------------------------

vars_fies <- c("ia_preocupacion", "ia_no_saludable", "ia_no_variado",
               "ia_saltó_comida", "ia_comió_menos", "ia_sin_alimentos",
               "ia_hambre", "ia_dia_sin_comer")

# PASO 2.1: Diagnóstico — ¿cuántas personas no tienen el módulo aplicado?
diagnostico_ia <- base_tratada %>%
  summarise(
    total_casos = n(),
    sin_modulo_aplicado = sum(is.na(ia_preocupacion)),
    porcentaje_sin_modulo = round(sin_modulo_aplicado / total_casos * 100, 1)
  )
print(diagnostico_ia)

# PASO 2.2: Tratamiento en dos fases
base_tratada_2 <- base_tratada %>%
  
  # FASE A: Eliminación estructural — nos quedamos solo con las personas cuyo
  # hogar sí fue encuestado en el módulo de inseguridad alimentaria.
  filter(!is.na(ia_preocupacion)) %>%
  
  # FASE B: Recodificamos "No sabe" (3) y "No responde" (4), y celdas en
  # blanco, como NA en las 8 preguntas, y luego imputamos con la moda
  # (respuesta más frecuente) de cada pregunta.
  mutate(across(all_of(vars_fies), ~ na_if(str_trim(as.character(.)), ""))) %>%
  mutate(across(all_of(vars_fies), ~ if_else(. %in% c("3", "4"), NA_character_, .))) %>%
  mutate(across(all_of(vars_fies), as.integer))

# Calculamos la moda de cada pregunta e imputamos
moda <- function(x) {
  ux <- na.omit(x)
  as.integer(names(sort(table(ux), decreasing = TRUE))[1])
}

base_tratada_2 <- base_tratada_2 %>%
  mutate(across(all_of(vars_fies), ~ replace_na(., moda(.))))

# Verificación
sapply(base_tratada_2[vars_fies], function(x) sum(is.na(x))) # Deberían salir 0

# ------------------------------------------------------------------------------
# 4. EXPORTAMOS NUESTRA BASE DE DATOS--------------------------------------------
# ------------------------------------------------------------------------------

write_parquet(base_tratada_2, "datos/procesados/base_acondicionada_020726.parquet")
# OJO: TENEMOS QUE TENER EN CUENTA QUE ESTA BASE DE DATOS:
# - SOLO INCLUYE PERSONAS CON NIVEL EDUCATIVO DECLARADO (se eliminaron los 99)
# - SOLO INCLUYE PERSONAS CUYO HOGAR RESPONDIÓ EL MÓDULO DE INSEGURIDAD ALIMENTARIA

