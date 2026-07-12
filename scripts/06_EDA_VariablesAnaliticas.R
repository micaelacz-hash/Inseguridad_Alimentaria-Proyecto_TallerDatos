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

# ==============================================================================
# 3. EXPLORACIÓN UNIVARIADA------------------------------------------------------
# ==============================================================================

# ------------------------------------------------------------------------------
# 3.1 Nivel de inseguridad alimentaria (Rasch)------------------------------------
# ------------------------------------------------------------------------------
tabla_nivel_ia <- base_diseno %>%
  filter(!is.na(nivel_inseguridad_alimentaria)) %>%
  group_by(nivel_inseguridad_alimentaria) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Nivel de Inseguridad Alimentaria` = nivel_inseguridad_alimentaria, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_nivel_ia <- flextable(tabla_nivel_ia) %>%
  estilo_reporte(
    titulo = "Tabla 1. Perú: Distribución de la población según nivel de inseguridad alimentaria (Rasch), 2025",
    fuente = fuente_enaho
  )
print(ft_nivel_ia)

plot_nivel_ia <- ggplot(base_analitica %>% filter(!is.na(nivel_inseguridad_alimentaria) & !is.na(factor07)),
                        aes(x = fct_rev(nivel_inseguridad_alimentaria), fill = nivel_inseguridad_alimentaria, weight = factor07)) +
  geom_bar(alpha = 0.9) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_manual(values = colores_severidad) +
  labs(title = "Gráfico 1. Distribución de la población según nivel de inseguridad alimentaria",
       x = "", y = "Población",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos + theme(legend.position = "none")
print(plot_nivel_ia)

# ------------------------------------------------------------------------------
# 3.2 Puntaje bruto FIES y severidad latente Rasch (variables continuas)---------
# ------------------------------------------------------------------------------
resumen_continua <- function(var_name, etiqueta) {
  base_diseno %>%
    filter(!is.na(.data[[var_name]])) %>%
    summarise(
      Media = survey_mean(.data[[var_name]], vartype = NULL),
      `Desv. Estándar` = survey_sd(.data[[var_name]], vartype = NULL),
      Mediana = survey_median(.data[[var_name]], vartype = NULL),
      Mínimo = min(.data[[var_name]], na.rm = TRUE),
      Máximo = max(.data[[var_name]], na.rm = TRUE)
    ) %>%
    mutate(across(everything(), ~ round(., 2))) %>%
    mutate(Variable = etiqueta) %>%
    relocate(Variable)
}

tabla_stats_fies <- bind_rows(
  resumen_continua("score_fies_bruto", "Puntaje Bruto FIES (0-8)"),
  resumen_continua("severidad_rasch", "Severidad Latente Rasch")
)

ft_stats_fies <- flextable(tabla_stats_fies) %>%
  estilo_reporte(
    titulo = "Tabla 2. Perú: Estadísticos de resumen del puntaje FIES y la severidad Rasch, 2025",
    fuente = fuente_enaho
  )
print(ft_stats_fies)

plot_severidad <- ggplot(base_analitica %>% filter(!is.na(severidad_rasch) & !is.na(factor07)),
                         aes(x = severidad_rasch, weight = factor07)) +
  geom_histogram(fill = "#4A7C59", color = "white", bins = 9) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Gráfico 2. Distribución de la severidad latente Rasch",
       x = "Severidad Latente Rasch", y = "Frecuencia Poblacional",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos
print(plot_severidad)

# ------------------------------------------------------------------------------
# 3.3 Grupo de edad (criterio teórico) y tercil de edad (criterio datos)---------
# ------------------------------------------------------------------------------
tabla_edad_teoria <- base_diseno %>%
  filter(!is.na(grupo_edad_teoria)) %>%
  group_by(grupo_edad_teoria) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Grupo Etario (Criterio Teórico)` = grupo_edad_teoria, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_edad_teoria <- flextable(tabla_edad_teoria) %>%
  estilo_reporte(
    titulo = "Tabla 3. Perú: Distribución de la población según grupo etario (criterio teórico), 2025",
    fuente = fuente_enaho
  )
print(ft_edad_teoria)

tabla_edad_datos <- base_diseno %>%
  filter(!is.na(grupo_edad_datos_etiqueta)) %>%
  group_by(grupo_edad_datos_etiqueta) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Tercil de Edad (Criterio Datos)` = grupo_edad_datos_etiqueta, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_edad_datos <- flextable(tabla_edad_datos) %>%
  estilo_reporte(
    titulo = "Tabla 4. Perú: Distribución de la población según tercil de edad (criterio datos), 2025",
    fuente = fuente_enaho
  )
print(ft_edad_datos)

# ------------------------------------------------------------------------------
# 3.4 Nivel educativo agrupado----------------------------------------------------
# ------------------------------------------------------------------------------
tabla_edu_agrupado <- base_diseno %>%
  filter(!is.na(nivel_edu_agrupado)) %>%
  group_by(nivel_edu_agrupado) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Nivel Educativo Agrupado` = nivel_edu_agrupado, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_edu_agrupado <- flextable(tabla_edu_agrupado) %>%
  estilo_reporte(
    titulo = "Tabla 5. Perú: Distribución de la población según nivel educativo agrupado, 2025",
    fuente = fuente_enaho
  )
print(ft_edu_agrupado)


