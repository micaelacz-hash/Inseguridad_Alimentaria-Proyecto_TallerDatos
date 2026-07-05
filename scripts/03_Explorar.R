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

# ------------------------------------------------------------------------------
# 3.3 Matrícula el año anterior--------------------------------------------------
# ------------------------------------------------------------------------------
tabla_matricula <- base_diseno %>%
  filter(!is.na(matricula_anterior_etiqueta)) %>%
  group_by(matricula_anterior_etiqueta) %>%
  summarise(Poblacion = survey_total(vartype = NULL), Porcentaje = survey_mean(vartype = NULL) * 100) %>%
  mutate(Poblacion = scales::comma(round(Poblacion, 0)), Porcentaje = paste0(round(Porcentaje, 1), "%")) %>%
  rename(`Matriculado el año anterior` = matricula_anterior_etiqueta, `Total (N)` = Poblacion, `%` = Porcentaje)

ft_matricula <- formato_flextable(tabla_matricula, "Tabla 3. Perú: Matrícula educativa el año anterior, 2025")
print(ft_matricula)

# ------------------------------------------------------------------------------
# 3.4 Bloque Inseguridad Alimentaria (8 ítems combinados, % de "Sí")------------
# ------------------------------------------------------------------------------
tabla_ia <- base_explorar %>%
  select(conglome, estrato, factor07, ends_with("_etiqueta") & starts_with("ia_")) %>%
  pivot_longer(cols = starts_with("ia_"), names_to = "Item", values_to = "Respuesta") %>%
  filter(Respuesta == "Sí") %>%
  as_survey_design(ids = conglome, strata = estrato, weights = factor07, nest = TRUE) %>%
  group_by(Item) %>%
  summarise(Poblacion = survey_total(vartype = NULL)) %>%
  mutate(
    Porcentaje = (Poblacion / sum(base_explorar$factor07, na.rm = TRUE)) * 100,
    Poblacion = scales::comma(round(Poblacion, 0)),
    Porcentaje = paste0(round(Porcentaje, 1), "%"),
    Item = case_when(
      str_detect(Item, "ia_preocupacion")  ~ "Preocupación por falta de comida",
      str_detect(Item, "ia_no_saludable")  ~ "No comió alimentos saludables/nutritivos",
      str_detect(Item, "ia_no_variado")    ~ "No comió alimentos variados",
      str_detect(Item, "ia_saltó_comida")  ~ "Dejó de desayunar/almorzar/cenar",
      str_detect(Item, "ia_comió_menos")   ~ "Comió menor cantidad de lo normal",
      str_detect(Item, "ia_sin_alimentos") ~ "El hogar se quedó sin alimentos",
      str_detect(Item, "ia_hambre")        ~ "Tuvo hambre pero no comió",
      str_detect(Item, "ia_dia_sin_comer") ~ "Estuvo sin comer un día entero",
      TRUE ~ Item
    )
  ) %>%
  arrange(desc(parse_number(str_remove(Poblacion, ",")))) %>%
  rename(`Situación reportada` = Item, `Personas (N)` = Poblacion, `% que respondió "Sí"` = Porcentaje)

ft_ia <- formato_flextable(tabla_ia, "Tabla 4. Perú: Población según situaciones de inseguridad alimentaria reportadas, 2025")
print(ft_ia)

# ------------------------------------------------------------------------------
# 3.5 Estadísticos de resumen: Edad (Variable Continua)--------------------------
# ------------------------------------------------------------------------------
stats_edad <- base_diseno %>%
  filter(!is.na(edad)) %>%
  summarise(
    `Mínimo` = min(edad, na.rm = TRUE),
    `Percentil 25 (Q1)` = survey_quantile(edad, 0.25, vartype = NULL),
    `Mediana (Q2)` = survey_median(edad, vartype = NULL),
    `Media (Promedio)` = survey_mean(edad, vartype = NULL),
    `Desviación Estándar` = survey_sd(edad, vartype = NULL),
    `Percentil 75 (Q3)` = survey_quantile(edad, 0.75, vartype = NULL),
    `Máximo` = max(edad, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = everything(), names_to = "Estadístico", values_to = "Valor (Años)") %>%
  mutate(
    Estadístico = str_remove(Estadístico, "_q[0-9]+"),
    `Valor (Años)` = scales::comma(round(`Valor (Años)`, 1))
  )

ft_edad <- formato_flextable(stats_edad, "Tabla 5. Perú: Edad de la población (estadísticos de resumen), 2025") %>%
  add_footer_lines(values = "Nota: La base incluye personas desde los 3 años (alcance del módulo 300). No se excluyó a los menores porque las preguntas de inseguridad alimentaria se responden una sola vez por hogar y se asignan a todos sus integrantes, por lo que reflejan la situación del hogar y no una experiencia individual del menor.")%>%
  align(align = "justify", part = "footer") %>%
  fontsize(size = 8, part = "footer")

print(ft_edad)

# ==============================================================================
# 4. EXPLORACIÓN UNIVARIADA: GRÁFICOS
# ==============================================================================

# Tema reutilizable para estandarizar título centrado, subtítulo y fuente
tema_graficos <- theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
    plot.subtitle = element_text(hjust = 0.5, color = "grey40"),
    plot.caption = element_text(hjust = 0, size = 8, color = "grey50")
  )

# 4.1 Histograma: Edad (Ponderado)
plot_edad <- ggplot(base_explorar %>% filter(!is.na(edad) & !is.na(factor07)),
                    aes(x = edad, weight = factor07)) +
  geom_histogram(fill = "#4A7C59", color = "white", binwidth = 5) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Gráfico 1. Distribución de edad de la población",
       x = "Edad (años)", y = "Frecuencia Poblacional",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos
print(plot_edad)

# 4.2 Barras: Nivel educativo (Ponderado, horizontal)
plot_nivel_edu <- ggplot(base_explorar %>% filter(!is.na(nivel_edu_etiqueta) & !is.na(factor07)),
                         aes(x = fct_rev(nivel_edu_etiqueta), weight = factor07)) +
  geom_bar(fill = "#2E5B88", alpha = 0.85) +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Gráfico 2. Distribución de la población según nivel educativo",
       x = "", y = "Población",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos
print(plot_nivel_edu)

# 4.3 Barras: % de "Sí" en cada ítem de inseguridad alimentaria
plot_ia <- ggplot(tabla_ia, aes(x = reorder(`Situación reportada`, parse_number(`% que respondió "Sí"`)),
                                y = parse_number(`% que respondió "Sí"`))) +
  geom_col(fill = "#D73027", alpha = 0.85) +
  coord_flip() +
  labs(title = "Gráfico 3. Perú: % de la población que reportó cada situación de inseguridad alimentaria, 2025",
       x = "", y = "% que respondió \"Sí\"",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos
print(plot_ia)


# ==============================================================================
# 5. EXPLORACIÓN BIVARIADA: RELACIONES ENTRE VARIABLES
# ==============================================================================

# ------------------------------------------------------------------------------
# 5.1 Categórica vs. Categórica (Tabla de Contingencia)
# ------------------------------------------------------------------------------
# Nivel educativo según Sexo (Porcentajes por fila)
tabla_edu_sexo_datos <- base_diseno %>%
  filter(!is.na(sexo_etiqueta) & !is.na(nivel_edu_etiqueta)) %>%
  group_by(sexo_etiqueta, nivel_edu_etiqueta) %>%
  summarise(Poblacion = survey_total(vartype = NULL)) %>%
  group_by(sexo_etiqueta) %>%
  mutate(
    Porcentaje = (Poblacion / sum(Poblacion)) * 100,
    Celda = paste0(scales::comma(round(Poblacion, 0)), " (", round(Porcentaje, 1), "%)")
  ) %>%
  select(sexo_etiqueta, nivel_edu_etiqueta, Celda) %>%
  pivot_wider(names_from = sexo_etiqueta, values_from = Celda) %>%
  rename(`Nivel Educativo` = nivel_edu_etiqueta)

ft_edu_sexo <- formato_flextable(tabla_edu_sexo_datos, "Tabla 6. Perú: Nivel educativo según sexo, 2025")
print(ft_edu_sexo)

# ------------------------------------------------------------------------------
# 5.2 Categórica vs. Continua (Boxplot por grupos)
# ------------------------------------------------------------------------------
# Calculamos estadísticos ponderados reales por grupo (el boxplot por sí solo
# no respeta el factor de expansión, ya que geom_boxplot ignora el aesthetic weight)
stats_edad_hambre <- base_diseno %>%
  filter(!is.na(ia_hambre_etiqueta) & !is.na(edad)) %>%
  group_by(ia_hambre_etiqueta) %>%
  summarise(
    media = survey_mean(edad, vartype = NULL),
    q1 = survey_quantile(edad, 0.25, vartype = NULL),
    mediana = survey_median(edad, vartype = NULL),
    q3 = survey_quantile(edad, 0.75, vartype = NULL)
  ) %>%
  rename_with(~ str_remove(., "_q[0-9]+$"), .cols = starts_with("q"))

print(stats_edad_hambre)

# Gráfico: boxplot (forma referencial) + media ponderada real anotada
plot_edad_hambre <- ggplot(base_explorar %>% filter(!is.na(ia_hambre_etiqueta) & !is.na(edad)),
                           aes(x = ia_hambre_etiqueta, y = edad, fill = ia_hambre_etiqueta)) +
  geom_boxplot(alpha = 0.5, outlier.color = "red", outlier.alpha = 0.3) +
  geom_point(data = stats_edad_hambre, aes(x = ia_hambre_etiqueta, y = media),
             inherit.aes = FALSE, shape = 18, size = 4, color = "black") +
  geom_text(data = stats_edad_hambre,
            aes(x = ia_hambre_etiqueta, y = media, label = paste0("Media: ", round(media, 1))),
            inherit.aes = FALSE, vjust = -1.2, size = 3.2, fontface = "bold") +
  scale_fill_manual(values = c("Sí" = "#D73027", "No" = "#2E5B88")) +
  labs(title = "Gráfico 4. Edad según experiencia de hambre por falta de alimentos",
       x = "¿Tuvo hambre pero no comió?", y = "Edad (años)",
       caption = "Fuente: ENAHO 2025. La caja muestra cuartiles sin ponderar (forma referencial); el rombo negro indica la media ponderada por factor de expansión.") +
  tema_graficos + theme(legend.position = "none")
print(plot_edad_hambre)

# Tabla complementaria: estadísticos ponderados completos (media, Q1, mediana, Q3)
tabla_stats_edad_hambre <- stats_edad_hambre %>%
  mutate(across(c(media, q1, mediana, q3), ~ round(., 1))) %>%
  rename(
    `¿Tuvo hambre pero no comió?` = ia_hambre_etiqueta,
    `Media` = media, `Q1` = q1, `Mediana` = mediana, `Q3` = q3
  )

ft_stats_edad_hambre <- formato_flextable(tabla_stats_edad_hambre,
       "Tabla 7. Estadísticos ponderados de edad según experiencia de hambre por falta de alimentos")
print(ft_stats_edad_hambre)

# ------------------------------------------------------------------------------
# 5.3 Categórica vs. Categórica (Barras proporcionales apiladas)
# ------------------------------------------------------------------------------
# ¿Tuvo hambre pero no comió? según nivel educativo
plot_edu_hambre <- ggplot(base_explorar %>% filter(!is.na(nivel_edu_etiqueta) & !is.na(ia_hambre_etiqueta)),
                          aes(x = fct_rev(nivel_edu_etiqueta), fill = ia_hambre_etiqueta, weight = factor07)) +
  geom_bar(position = "fill", alpha = 0.85) +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("Sí" = "#D73027", "No" = "#2E5B88")) +
  labs(title = "Gráfico 5. Proporción que reportó hambre por falta de alimentos, según nivel educativo",
       x = "", y = "Proporción de la población", fill = "¿Tuvo hambre\npero no comió?",
       caption = "Fuente: ENAHO 2025. Cálculos ajustados por factor de expansión.") +
  tema_graficos + theme(legend.position = "bottom")
print(plot_edu_hambre)

# =====================================================================================
# 6. EXPORTACIÓN MASIVA (Imágenes para Informe descriptivo que haremos en Markdown)----
# =====================================================================================
ruta_salida <- "outputs/outputs_exploracion_inicial"

if (!dir.exists(ruta_salida)) {
  dir.create(ruta_salida, recursive = TRUE)
}

save_as_image(ft_nivel_edu,        path = paste0(ruta_salida, "/Tabla1_NivelEducativo.png"))
save_as_image(ft_sexo,             path = paste0(ruta_salida, "/Tabla2_Sexo.png"))
save_as_image(ft_matricula,        path = paste0(ruta_salida, "/Tabla3_Matricula.png"))
save_as_image(ft_ia,               path = paste0(ruta_salida, "/Tabla4_InseguridadAlimentaria.png"))
save_as_image(ft_edad,             path = paste0(ruta_salida, "/Tabla5_Stats_Edad.png"))
save_as_image(ft_edu_sexo,         path = paste0(ruta_salida, "/Tabla6_EduSexo.png"))
save_as_image(ft_stats_edad_hambre, path = paste0(ruta_salida, "/Tabla7_Stats_EdadHambre.png"))

ggsave(paste0(ruta_salida, "/Grafico1_Edad.jpg"),            plot = plot_edad,           width = 8, height = 5, bg = "white")
ggsave(paste0(ruta_salida, "/Grafico2_NivelEducativo.jpg"),  plot = plot_nivel_edu,      width = 8, height = 5, bg = "white")
ggsave(paste0(ruta_salida, "/Grafico3_InsegAlimentaria.jpg"), plot = plot_ia,            width = 8, height = 5, bg = "white")
ggsave(paste0(ruta_salida, "/Grafico4_Edad_Hambre.jpg"),     plot = plot_edad_hambre,    width = 8, height = 5, bg = "white")
ggsave(paste0(ruta_salida, "/Grafico5_Edu_Hambre.jpg"),      plot = plot_edu_hambre,     width = 8, height = 5, bg = "white")
