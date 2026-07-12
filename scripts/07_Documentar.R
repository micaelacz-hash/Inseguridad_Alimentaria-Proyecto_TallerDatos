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

# ==============================================================================
# 2. INYECTAMOS LOS METADATOS----------------------------------------------------
# ==============================================================================

# Usamos la función var_label() para generar los nombresd de nuestras variables

# A. Variables base exploradas (etiquetadas)
var_label(base_codebook$edad) <- "Edad del encuestado, en años cumplidos (Fuente: P208A)"
var_label(base_codebook$sexo) <- "Sexo del encuestado (Fuente: P207)"
var_label(base_codebook$nivel_edu_etiqueta) <- "Nivel educativo alcanzado, 12 categorías originales (Fuente: P301A)"
var_label(base_codebook$matricula_anterior_etiqueta) <- "¿Estuvo matriculado en algún centro o programa educativo el año pasado? (Fuente: P303)"
var_label(base_codebook$ia_preocupacion_etiqueta) <- "Preocupación por falta de comida en el hogar (Fuente: P130_1)"
var_label(base_codebook$ia_no_saludable_etiqueta) <- "No comió alimentos saludables/nutritivos (Fuente: P130_2)"
var_label(base_codebook$ia_no_variado_etiqueta) <- "No comió alimentos variados (Fuente: P130_3)"
var_label(base_codebook$ia_saltó_comida_etiqueta) <- "Dejó de desayunar, almorzar o cenar (Fuente: P130_4)"
var_label(base_codebook$ia_comió_menos_etiqueta) <- "Comió menor cantidad de lo normal (Fuente: P130_5)"
var_label(base_codebook$ia_sin_alimentos_etiqueta) <- "El hogar se quedó sin alimentos (Fuente: P130_6)"
var_label(base_codebook$ia_hambre_etiqueta) <- "Tuvo hambre pero no comió (Fuente: P130_7)"
var_label(base_codebook$ia_dia_sin_comer_etiqueta) <- "Estuvo sin comer un día entero (Fuente: P130_8)"

# B. Variables analíticas (creadas en el script 05)
var_label(base_codebook$score_fies_bruto) <- "Puntaje bruto FIES: N° de respuestas afirmativas (0 a 8)"
var_label(base_codebook$severidad_rasch) <- "Severidad latente estimada por el modelo Rasch ponderado (RM.weights)"
var_label(base_codebook$nivel_inseguridad_alimentaria) <- "Nivel de inseguridad alimentaria (4 categorías, según puntos de corte FIES)"
var_label(base_codebook$grupo_edad_teoria) <- "Grupo etario según criterio teórico (etapas de ciclo de vida)"
var_label(base_codebook$nivel_edu_agrupado) <- "Nivel educativo agrupado en 7 categorías"
var_label(base_codebook$grupo_edad_datos) <- "Grupo etario según criterio de datos (terciles de la distribución empírica de edad)"
