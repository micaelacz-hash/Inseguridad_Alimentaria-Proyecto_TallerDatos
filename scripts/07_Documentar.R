# ==============================================================================
# Proyecto: Análisis de la inseguridad alimentaria utilizando datos de la ENAHO
# Script: Documentar
# Autora: Micaela Cusipuma
# Fecha: 11-07-2026
# Objetivo: Añadir metadatos a la base analítica y generar el CodeBook final.
# ==============================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y PAQUETES
# ------------------------------------------------------------------------------
install.packages(c("labelled", "codebook"))

library(tidyverse)
library(arrow)
library(here)
library(labelled)  # Para inyectar etiquetas y metadatos en las variables
library(codebook)  # Para generar el CodeBook interactivo
renv::snapshot()

# Cargamos nuestra base de datos analítica final (fruto de EXTRAER a CLASIFICAR)
base_analitica <- read_parquet(here("datos", "procesados", "base_analitica_050726.parquet"))

# ==============================================================================
# 1. SELECCIÓN DE VARIABLES PARA EL CODEBOOK
# ==============================================================================

# Creamos una base de datos solo con las variables base exploradas + nuestras variables analíticas del script 05

base_codebook <- base_analitica %>%
  select(
    edad, sexo, nivel_edu_etiqueta, matricula_anterior_etiqueta,
    ia_preocupacion_etiqueta, ia_no_saludable_etiqueta, ia_no_variado_etiqueta,
    ia_saltó_comida_etiqueta, ia_comió_menos_etiqueta, ia_sin_alimentos_etiqueta,
    ia_hambre_etiqueta, ia_dia_sin_comer_etiqueta,
    score_fies_bruto, severidad_rasch, nivel_inseguridad_alimentaria,
    grupo_edad_teoria, nivel_edu_agrupado, grupo_edad_datos
  ) %>%
  mutate(across(where(is.character), as.factor)) # Para que "codebook" detecte nuestras etiquetas

# Exportamos como la base de datos documentada de nuestro proyecto
write_parquet(base_codebook, here("datos", "procesados", "base_codebook_110726.parquet"))

