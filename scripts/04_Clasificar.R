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