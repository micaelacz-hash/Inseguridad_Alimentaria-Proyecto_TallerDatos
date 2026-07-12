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
