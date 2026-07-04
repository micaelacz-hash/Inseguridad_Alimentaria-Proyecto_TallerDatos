# ====================================================================================
# Proyecto: Análisis de la inseguridad alimentaria utilizando datos de la ENAHO
# Script: Exploración (EDA)
# Autora: Micaela Cusipuma
# Fecha: 04-07-2026
# Objetivo: Describir la distribución original de las variables antes de clasificarlas
# =====================================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# 0. CONFIGURACIÓN Y CARGA DE DATOS
# ------------------------------------------------------------------------------
library(webshot2)
library(tidyverse)
library(arrow)
library(survey)
library(srvyr)
library(flextable)
library(scales)
library(officer)
library(here)
renv::snapshot()

# Cargamos la base de datos limpia (ACONDICIONADA)
base_limpia <- read_parquet(here("datos", "procesados", "base_acondicionada_020726.parquet"))

# ------------------------------------------------------------------------------
# 1. PREPARACIÓN DE ETIQUETAS----------------------------------------------------
# ------------------------------------------------------------------------------
# Todas las variables aquí exploradas ya pasaron por el acondicionamiento del
# script 02 (recodificación de missing codes y tratamiento de NAs).

base_explorar <- base_limpia %>%
  mutate(
    # A. Demográficas (Crudas)
    sexo_etiqueta = factor(sexo, levels = c(1, 2), labels = c("Hombre", "Mujer")),
    
    # B. Educación (Crudas)
    nivel_edu_etiqueta = factor(nivel_edu,
                                levels = 1:12,
                                labels = c("Sin nivel", "Educación inicial",
                                           "Primaria incompleta", "Primaria completa",
                                           "Secundaria incompleta", "Secundaria completa",
                                           "Superior no universitaria incompleta",
                                           "Superior no universitaria completa",
                                           "Superior universitaria incompleta",
                                           "Superior universitaria completa",
                                           "Maestría/Doctorado", "Básica especial")),
    
    matricula_anterior_etiqueta = factor(matricula_anterior,
                                         levels = c(1, 2),
                                         labels = c("Sí", "No")),
    
    # C. Limpieza numérica estricta — el factor de expansión no está en numérico
    factor07 = as.numeric(str_replace_all(factor07, ",", ".")),
    conglome = as.numeric(conglome),
    estrato  = as.numeric(estrato),
    edad     = as.numeric(edad)
  ) %>%
  
  # D. Etiquetamos las 8 preguntas de inseguridad alimentaria (Sí/No)
  mutate(across(starts_with("ia_"),
                ~ factor(., levels = c(1, 2), labels = c("Sí", "No")),
                .names = "{.col}_etiqueta"))

# Guardamos esta base de datos con las etiquetas creadas
write_parquet(base_explorar, "datos/procesados/base_explorar_030726.parquet")

# ------------------------------------------------------------------------------
# 2. DISEÑO MUESTRAL--------------------------------------------------------------
# ------------------------------------------------------------------------------
base_diseno <- base_explorar %>%
  filter(!is.na(factor07)) %>%
  as_survey_design(
    ids = conglome,
    strata = estrato,
    weights = factor07,
    nest = TRUE
  ) # Aquí utilizamos el factor de expansión

# ==============================================================================
# 3. EXPLORACIÓN UNIVARIADA: TABLAS DESCRIPTIVAS--------------------------------
# ==============================================================================
formato_flextable <- function(tabla, titulo) {
  flextable(tabla) %>%
    add_header_lines(values = titulo) %>%
    add_footer_lines(values = "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional.") %>%
    autofit() %>%
    theme_vanilla() %>%
    border_inner_h(part = "body", border = officer::fp_border(width = 0)) %>%
    align(align = "center", part = "all") %>%
    align(j = 1, align = "left", part = "body") %>%
    bold(part = "header") %>%
    align(align = "left", part = "footer") %>%
    fontsize(size = 9, part = "footer") %>%
    hline_bottom(part = "body", border = officer::fp_border(width = 1)) %>%
    hline_bottom(part = "footer", border = officer::fp_border(width = 0))
}

# ------------------------------------------------------------------------------
# 3.1 Nivel educativo------------------------------------------------------------
# ------------------------------------------------------------------------------
tabla_nivel_edu <- base_diseno %>%
  filter(!is.na(nivel_edu_etiqueta)) %>%
  group_by(nivel_edu_etiqueta) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Nivel Educativo` = nivel_edu_etiqueta, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_nivel_edu <- formato_flextable(tabla_nivel_edu, "Tabla 1. Perú: Distribución de la población según nivel educativo alcanzado, 2025")
print(ft_nivel_edu)


# ------------------------------------------------------------------------------
# 3.2 Sexo------------------------------------------------------------------------
# ------------------------------------------------------------------------------
tabla_sexo <- base_diseno %>%
  filter(!is.na(sexo_etiqueta)) %>%
  group_by(sexo_etiqueta) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(Sexo = sexo_etiqueta, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_sexo <- formato_flextable(tabla_sexo, "Tabla 2. Perú: Distribución de la población según sexo, 2025")
print(ft_sexo)
