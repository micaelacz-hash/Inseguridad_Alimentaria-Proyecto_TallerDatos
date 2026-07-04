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

ggsave("outputs/Grafico_NAs_InseguridadAlimentaria.jgg", plot = grafico_nas,
       width = 8, height = 6, bg = "white")

# 2.2 Reporte tabular
reporte_nas <- base_seleccion %>%
  summarise(across(everything(), ~ round(sum(is.na(.)) / n() * 100, 2))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "porcentaje_na") %>%
  arrange(desc(porcentaje_na))

write_csv(reporte_nas, "outputs/Reporte_Datos_Perdidos_ENAHO.csv")
