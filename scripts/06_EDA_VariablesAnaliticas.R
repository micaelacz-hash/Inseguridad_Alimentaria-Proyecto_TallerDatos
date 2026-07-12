# ====================================================================================
# Proyecto: Análisis de la inseguridad alimentaria utilizando datos de la ENAHO
# Script: EDA de Variables Analíticas
# Autora: Micaela Cusipuma
# Fecha: 11-07-2026
# Objetivo: Explorar la distribución de las variables analíticas creadas en el script 05
#           (índice Rasch, nivel de inseguridad alimentaria, grupos de edad y nivel
#           educativo agrupado) y su relación con edad, nivel educativo y sexo.
# =====================================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y CARGA DE DATOS----------------------------------------------
# ------------------------------------------------------------------------------
library(tidyverse)
library(arrow)
library(survey)
library(srvyr)
library(flextable)
library(scales)
library(officer)
library(here)
renv::snapshot()

base_analitica <- read_parquet(here("datos", "procesados", "base_analitica_050726.parquet"))
