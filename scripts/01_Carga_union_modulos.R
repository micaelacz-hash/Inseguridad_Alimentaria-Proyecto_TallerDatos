#================================================================================
#Proyecto: Análisis de la inseguridad alimentaria usando datos de la ENAHO
#Script: Cargar los módulos y hacer los joins
#Autora: Micaela Cusipuma
#Fecha: 02-07-2026
#===============================================================================

#1. Carga de librerías---------------------------
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(rio)
library(tidyverse)
library(janitor)
renv::snapshot(force = TRUE)

#2. Importar datos--------------------
# Se cargan los módulos de educación e inseguridad alimentaria
mod300 <- import("datos/crudos/Enaho01A-2025-300.csv", encoding = "Latin-1")
mod130 <- import("datos/crudos/Enaho01-2025-130.csv", encoding = "Latin-1")

#3. Unión de bases----------------------------------
# Creación de keys, para darle un identificador al hogar encuestado
  keys_hogar <- c("AÑO", "MES", "CONGLOME", "VIVIENDA", "HOGAR")
# El módulo 130 (inseguridad alimentaria) se responde a nivel de hogar por un solo informante (CODINFOR), por lo que NO incluye CODPERSO. Por eso el key de persona
# solo puede construirse con CODINFOR, no con CODPERSO.
  keys_personas <- c(keys_hogar, "CODINFOR")
#Unimos las bases de datos: el módulo 300 (educación) y el módulo 130 (inseguridad alimentaria)
#Usamos suffix para distinguir columnas duplicadas (P203-P209) que existen en ambos
#módulos pero no forman parte de las keys de unión
  base_persona <- mod300 %>%
    left_join(mod130, by = keys_personas, suffix = c("_edu", "_ia"))
    gc()

#4. Exportamos base de datos creada------------------------
install.packages("arrow")
library(arrow)
renv::snapshot()
write_parquet(base_persona, "datos/procesados/base_por_persona_180626.parquet")

