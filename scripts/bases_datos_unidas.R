# Cargamos las librerías------------------------------------------------------
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(rio)
library(tidyverse)
library(janitor)


# Usanos Renv-------------------------------------------------------------
renv::snapshot(force = TRUE)


#Importamos los datos------------------------------------------------------
# Se cargan los módulos de educación e inseguridad alimentaria

mod300  = import("Enaho01A-2025-300.csv", encoding = "Latin-1")
mod130  = import("Enaho01-2025-130.csv", encoding = "Latin-1")


#Unimos datos-------------------------------------------------------
# Creación de keys, para darle un identificador al hogar encuestado
keys_hogar <- c("AÑO", "MES", "CONGLOME", "VIVIENDA", "HOGAR")
# El key de persona se estructura para darle un identificador a la persona encuestada
keys_personas <- c(keys_hogar, "CODINFOR")


# Unimos las bases de datos: el módulo 300 (educación) y el módulo 130 (inseguridad alimentaria) 
# esto lo realizamos mediante las variables comunes de keys_personas, porque las preguntas de ambos módulos son para todas las personas y no por hogar
base_persona <- mod300 %>%
  left_join(mod130, by = keys_personas)
