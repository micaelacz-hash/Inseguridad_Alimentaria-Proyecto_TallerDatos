# Análisis de la Inseguridad alimentaria utilizando datos de la ENAHO

## Descripción del proyecto
Este repositorio incluye el código y el flujo de trabajo completo del proyecto **"Análisis de la Inseguridad alimentaria"**
Se utilizan datos de la Encuesta Nacional de Hogares (ENAHO) de 2025 trabajado integramente en **R**.

El análisis explora la relación entre la inseguridad alimentaria y las siguientes dimensiones: Demográficas: Quintiles de ingreso, grupos de edad y nivel educativo.

## Programas y librerías utilizadas
El proyecto está desarrollado utilizando la versión 4.5.3 de **R**, con las siguientes librerías:
* `tidyverse` : para el procesamiento y gráficos (dplyry ggplot2)
* `rio` : importación de datos
* `arrow` : exportación e importación de BD en formato parquet
* `janitor` : limpieza de nombres de la ENAHO La versión de todas las librerías se controla utilizando renv
La versión de todas las librerías se controla utilizando renv

## Estructura del directorio
El directorio se organiza a través de la siguiente estructura de carpetas:

├── Creacion_R_Project.R        # Script principal: Configuración del entorno, creación de carpetas y enlace a GitHub
├── datos/
│   ├── crudos/                 # Módulos originales de la ENAHO en formato .csv
│   └── limpios/                # Bases maestras procesadas en formato .parquet (Output de scripts 01 y 02)
├── scripts/
│   ├── 01_Importar_modulos_ENAHO.R   # Carga masiva y cruce (merge) de los módulos 100, 200, 300, 400, 500 y Gobernabilidad
│   ├── 02_Limpieza_ENAHO.R           # Limpieza, recodificación y creación de variables (PEA, PET, Ocupados, Formalidad)
│   ├── 03_Exploracion.R        # Análisis descriptivo y generación de cruces bivariados
│   └── 04_Informe_Final.Rmd    # Código fuente dinámico para la elaboración del reporte
├── resultados/                 # Outputs finales: tablas, gráficos descriptivos y el informe en .pdf
├── renv/                       # Carpeta aislada del entorno local de paquetes
├── renv.lock                   # "Cápsula del tiempo": Registro exacto de las versiones de las librerías
├── .gitignore                  # Configuración de exclusión para evitar la subida de datos masivos al repositorio
└── [Nombre_del_Proyecto].Rproj # Archivo de inicialización del entorno R
