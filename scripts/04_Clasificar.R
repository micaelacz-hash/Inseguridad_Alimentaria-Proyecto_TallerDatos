# ====================================================================================
# Proyecto: Análisis de la inseguridad alimentaria utilizando datos de la ENAHO
# Script: Clasificar
# Autora: Micaela Cusipuma
# Fecha: 05-07-2026
# Objetivo: Estimar el índice de inseguridad alimentaria mediante el modelo Rasch
#           (metodología FIES/Voices of the Hungry de la FAO), y crear variables
#           analíticas adicionales.
# =====================================================================================
rm(list = ls())
# ------------------------------------------------------------------------------
# 0. Llamado de librerías---------------------------------------------
# ------------------------------------------------------------------------------

library(RM.weights)
library(Hmisc)
library(xfun)
library(tidyverse)
library(arrow)
library(survey)
library(srvyr)
library(here)
library(gtsummary)
library(flextable)
renv::snapshot()

base_limpia <- read_parquet(here("datos", "procesados", "base_explorar_030726.parquet"))

# ==============================================================================
# 1. Estimación del modelo Rasch (Metodología FIES - FAO)-----------------------
# ==============================================================================
# Seleccionamos las preguntas del módulo Inseguridad Alimentaria
vars_fies <- c("ia_preocupacion", "ia_no_saludable", "ia_no_variado",
               "ia_saltó_comida", "ia_comió_menos", "ia_sin_alimentos",
               "ia_hambre", "ia_dia_sin_comer")

# 1.1 Preparamos la matriz 0/1 requerida por el paquete RM.weights (1 = Sí, 0 = No)
# El paquete RM.weights requiere el siguiente formato: filas = personas, columnas = ítems, realizamos el cambio
XX <- base_limpia %>%
  select(all_of(vars_fies)) %>%
  mutate(across(everything(), ~ if_else(. == 1, 1, 0))) %>%
  as.data.frame()

wt <- as.numeric(str_replace_all(base_limpia$factor07, ",", "."))

# 1.2 Ajustamos el modelo Rasch ponderado (Conditional Maximum Likelihood)
modelo_rasch <- RM.w(XX, .w = wt, country = "Peru_InseguridadAlimentaria")

# 1.3 Parámetros de severidad de cada ítem (qué tan "difícil" es responder Sí)
severidad_items <- data.frame(
  Item = vars_fies,
  Severidad = modelo_rasch$b,
  Error_Estandar = modelo_rasch$se.b,
  Infit = modelo_rasch$infit,
  Outfit = modelo_rasch$outfit
) %>%
  arrange(Severidad)
print(severidad_items)

# 1.4 Confiabilidad del modelo (equivalente al alfa de Cronbach para escalas Rasch)
print(modelo_rasch$reliab)

# ==============================================================================
# 2. ASIGNACIÓN DEL PUNTAJE RASCH A CADA PERSONA--------------------------------
# ==============================================================================
# RM.w() estima un parámetro de severidad latente por cada puntaje bruto posible
# (0 a 8), no directamente por persona. Asignamos a cada persona el parámetro
# correspondiente a su propio puntaje bruto (raw score).

base_analitica <- base_limpia %>%
  mutate(
    score_fies_bruto = rowSums(XX),
    # modelo_rasch$a tiene un valor por cada raw score posible (0 a 8, 9 valores)
    severidad_rasch = modelo_rasch$a[score_fies_bruto + 1],
    error_rasch = modelo_rasch$se.a[score_fies_bruto + 1]
  )