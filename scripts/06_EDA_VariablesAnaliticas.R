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

# ------------------------------------------------------------------------------
# 1. PREPARACIÓN DE ETIQUETAS Y FACTORES ORDENADOS-------------------------------
# ------------------------------------------------------------------------------
# Etiquetamos grupo_edad_datos (terciles) con el rango de edad real de cada tercil
rangos_tercil <- base_analitica %>%
  filter(!is.na(grupo_edad_datos)) %>%
  group_by(grupo_edad_datos) %>%
  summarise(min_edad = min(edad, na.rm = TRUE), max_edad = max(edad, na.rm = TRUE), .groups = "drop") %>%
  mutate(grupo_edad_datos_etiqueta = paste0("Tercil ", grupo_edad_datos, " (", min_edad, "-", max_edad, " años)")) %>%
  arrange(grupo_edad_datos)

base_analitica <- base_analitica %>%
  left_join(rangos_tercil %>% select(grupo_edad_datos, grupo_edad_datos_etiqueta), by = "grupo_edad_datos") %>%
  mutate(
    nivel_inseguridad_alimentaria = factor(nivel_inseguridad_alimentaria,
                                           levels = c("1. Seguridad alimentaria", "2. Inseguridad leve",
                                                      "3. Inseguridad moderada", "4. Inseguridad severa")),
    grupo_edad_teoria = factor(grupo_edad_teoria,
                               levels = c("Niñez (3 a 11 años)", "Adolescencia (12 a 17 años)",
                                          "Juventud (18 a 29 años)", "Adultez (30 a 59 años)",
                                          "Adultez mayor (60 años a más)")),
    nivel_edu_agrupado = factor(nivel_edu_agrupado,
                                levels = c("Sin nivel / Inicial", "Primaria", "Secundaria",
                                           "Superior no universitaria", "Superior universitaria",
                                           "Maestría/Doctorado", "Básica especial")),
    grupo_edad_datos_etiqueta = factor(grupo_edad_datos_etiqueta,
                                       levels = rangos_tercil$grupo_edad_datos_etiqueta)
  )

# Paleta de colores para los 4 niveles de severidad
colores_severidad <- c(
  "1. Seguridad alimentaria" = "#1a9850",
  "2. Inseguridad leve"      = "#fee08b",
  "3. Inseguridad moderada"  = "#fc8d59",
  "4. Inseguridad severa"    = "#d73027"
)

# Tema reutilizable de gráficos
tema_graficos <- theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
    plot.subtitle = element_text(hjust = 0.5, color = "grey40"),
    plot.caption = element_text(hjust = 0, size = 8, color = "grey50")
  )

# Formato reutilizable de tablas
estilo_reporte <- function(ft, titulo, fuente) {
  ft %>%
    add_header_lines(values = titulo) %>%
    add_footer_lines(values = fuente) %>%
    autofit() %>%
    border_remove() %>%
    hline_top(border = fp_border(width = 1.5), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.5), part = "header") %>%
    hline_bottom(border = fp_border(width = 1.5), part = "body") %>%
    align(align = "center", part = "all") %>%
    align(j = 1, align = "left", part = "body") %>%
    bold(part = "header") %>%
    align(align = "left", part = "footer") %>%
    fontsize(size = 9, part = "footer")
}

fuente_enaho <- "Fuente: ENAHO 2025. Cálculos expandidos a nivel poblacional."

# ------------------------------------------------------------------------------
# 2. DISEÑO MUESTRAL--------------------------------------------------------------
# ------------------------------------------------------------------------------
base_diseno <- base_analitica %>%
  filter(!is.na(factor07)) %>%
  as_survey_design(ids = conglome, strata = estrato, weights = factor07, nest = TRUE)


