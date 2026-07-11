# Análisis de la Inseguridad alimentaria utilizando datos de la ENAHO

## Descripción del proyecto
Este repositorio incluye el código y el flujo de trabajo completo del proyecto **"Análisis de la Inseguridad alimentaria"**
Se utilizan datos de la Encuesta Nacional de Hogares (ENAHO) de 2025 trabajado integramente en **R**.

El análisis explora la relación entre la inseguridad alimentaria y las siguientes dimensiones demográficas: grupos de edad, nivel educativo y sexo.

De momento el proyecto incluye los módulos de la ENAHO referentes a la inseguridad alimentaria y nivel educativo, progresivamente se añadirán más módulos. 

## Programas y librerías utilizadas
**Lenguaje y entorno:**
- R (versión 4.4.1)
- RStudio
- Control de versiones: Git y GitHub
- Gestión de dependencias: `renv` (ver `renv.lock` para las versiones exactas de cada paquete)

**Librerías de R:**

| Categoría | Paquetes |
|---|---|
| Manipulación de datos | `tidyverse`, `dplyr`, `tidyr`, `stringr`, `readr`, `rio`, `janitor` |
| Importación/exportación | `arrow` (formato parquet) |
| Diagnóstico de datos faltantes | `naniar` |
| Diseño muestral complejo (ENAHO) | `survey`, `srvyr` |
| Modelo Rasch / Escala FIES | `RM.weights` |
| Tablas y reportes | `flextable`, `gtsummary`, `officer`, `scales` |
| Gráficos | `ggplot2` |
| Rutas de archivo reproducibles | `here` |
| Exportación de tablas a imagen | `webshot2` |
| Configuración inicial de Git/GitHub | `usethis`, `gitcreds` |

Para instalar exactamente las mismas versiones utilizadas en este proyecto, cloná el repositorio y corré:
```r
renv::restore()
```

## Estructura del directorio
El directorio se organiza a través de la siguiente estructura de carpetas:
```text
├── scripts/
│   ├── 00_Configuracion_Inicial.R          # Configuración del entorno, creación de carpetas y enlace a GitHub
│   ├── 01_Carga_union_modulos.R            # Carga y unión (left_join) de los módulos 300 (Educación) y 130 (Inseguridad Alimentaria)
│   ├── 02_Acondicionar.R                   # Selección, renombrado, diagnóstico y tratamiento de valores perdidos
│   ├── 03_Explorar.R                       # Análisis exploratorio de datos (EDA) univariado y bivariado
│   ├── 04_Informe_Exploracion_Inicial.Rmd  # Código fuente dinámico del informe descriptivo (EDA)
│   ├── 05_Clasificar.R                  # Estimación del índice Rasch (FIES) y creación de variables analíticas
│   ├── 06_EDA_VariablesAnaliticas.R        # [Pendiente] Análisis exploratorio de las variables analíticas creadas
│   └── 07_Documentar.R                  # [Pendiente] CodeBook con la definición formal de cada variable
├── datos/
│   ├── crudos/                 # Módulos originales de la ENAHO en formato .csv (no incluidos en el repositorio)
│   └── procesados/             # Bases procesadas en formato .parquet, generadas por los scripts 01, 02, 03 y 05
├── outputs/
│   ├── outputs_exploracion_inicial/    # Tablas y gráficos del EDA inicial (script 03), usados en el informe .Rmd
│   ├── Grafico_NAs_InseguridadAlimentaria.jpg   # Diagnóstico gráfico de valores perdidos (script 02)
│   ├── Reporte_Datos_Perdidos_ENAHO.csv         # Diagnóstico tabular de valores perdidos (script 02)
│   └── CLASIFICAR_Reporte_VariablesCreadas.html # Reporte de variables analíticas creadas (script 05)
├── renv/                        # Carpeta aislada del entorno local de paquetes
├── renv.lock                    # Registro exacto de las versiones de las librerías utilizadas
├── .gitignore                   # Configuración de exclusión para evitar la subida de datos masivos al repositorio
├── README.md                    # Documentación del proyecto
└── Inseguridad_Alimentaria-Proyecto_TallerDatos.Rproj  # Archivo de inicialización del entorno R
```
A continuación, se detalla las principales decisiones y acciones tomadas en cada paso del flujo de trabajo. Si se tienen dudas más específicas, por favor, referirse al script en concreto.

## EXTRAER

Se descargaron los módulos 300 (Educación) y 130 (Inseguridad Alimentaria) de la ENAHO 2025 en su formato anual. Se guardaron las bases de datos (.csv) en la carpeta correspondiente, así como el diccionario y la ficha técnica proporcionados por el INEI.

## GESTIONAR

Se creó un R Project con el título del trabajo, y se realizó la conexión con Git y GitHub desde RStudio (script `00_Configuracion_Inicial.R`). Mediante este proceso se creó este repositorio de GitHub, el cual es continuamente actualizado a través de commits desde RStudio. En el proyecto, se creó la estructura de carpetas presentada en la sección anterior. No obstante, el presente README especifica los módulos de la ENAHO utilizados y cada script permite reproducir y generar como resultado las bases de datos procesadas. Finalmente, se utilizó el paquete `renv` para gestionar las versiones de las librerías utilizadas.

## ACONDICIONAR

Se realizó la fusión correspondiente de los módulos utilizados mediante un `left_join`, dando como resultado la primera base de datos procesada; el proceso detallado puede observarse correctamente documentado en el script `01_Carga_union_modulos.R`. Cabe destacar que, a diferencia de una unión persona a persona, el módulo 130 se responde a nivel de hogar por un único informante (`CODINFOR`), por lo que la key de unión no pudo incluir `CODPERSO`. Es por ello que, las respuestas de inseguridad alimentaria se replican a todos los integrantes del hogar.

En el script `02_Acondicionar.R`, se seleccionó y renombró las variables de interés, se realizó una revisión rápida de la estructura de los datos y se realizó un diagnóstico de valores perdidos, el cual dio como resultado dos reportes (uno gráfico y otro tabular) que pueden encontrarse en la carpeta "outputs". Finalmente, se aplicó una estrategia de tratamiento de valores perdidos a dos variables problemáticas:

- **`nivel_edu`**: se identificó el código "99" (No especificado) en una proporción mínima de casos (MCAR), tratado mediante eliminación (Listwise).
- **Las 8 preguntas de la escala FIES del módulo Inseguridad Alimentaria** (desde `ia_preocupacion` hasta `ia_dia_sin_comer`): se identificó un NA estructural (45% de los casos, correspondiente a hogares donde no se aplicó el módulo 130 ese mes), tratado mediante eliminación; adicionalmente, se recodificaron las respuestas "No sabe"/"No responde" como NA y se imputaron mediante la moda de cada pregunta.

El procedimiento completo puede observarse con detalle en el script `02_Acondicionar.R`. Como resultado, se exportó la segunda base de datos procesada, la cual: solo incluye a personas con nivel educativo declarado, y solo incluye a personas cuyo hogar respondió el módulo de inseguridad alimentaria.

## EXPLORAR

En el script `03_Explorar.R`, se cargó la base procesada más reciente y, de manera previa a la creación de gráficos y tablas, se crearon etiquetas para las opciones de respuesta de las variables de interés para el proyecto, guiándose del diccionario de datos de la ENAHO 2025. Posteriormente, se realizó un análisis exploratorio de datos (EDA) univariado y bivariado con las variables de interés, dando como resultado tablas y gráficos exportados a la subcarpeta "outputs_exploracion_inicial". Estos gráficos y tablas fueron utilizados en el script `04_Informe_Exploracion_Inicial.Rmd`, en el que se redacta el informe descriptivo de los datos, y se exporta como HTML hacia la carpeta "outputs". En todo el EDA se utiliza el factor de expansión (`factor07`) mediante diseño muestral complejo (`survey`/`srvyr`). Como resultado del script `03`, además de exportar los gráficos y tablas mencionados, se exportó una tercera base de datos procesada que incluye las etiquetas de las opciones de respuesta.

## CLASIFICAR

En el script `05_Clasificar.R`, se estimó el índice de inseguridad alimentaria mediante un **modelo Rasch ponderado** (que es parte de la metodología FIES/Voices of the Hungry de la FAO, implementada con el paquete `RM.weights`), se optó por ello antes que una simple suma de respuestas afirmativas, ya que ello construiría un indicador metodológicamente incorrecto. El modelo Rasch estima, para cada una de las 8 preguntas, un parámetro de severidad (es decir qué tan "difícil" es que alguien responda "Sí"), y asigna a cada persona un puntaje de severidad latente según su puntaje bruto (0 a 8 respuestas afirmativas), ponderado por `factor07`.

A partir de este puntaje, se construyeron las siguientes variables analíticas: `score_fies_bruto`, `severidad_rasch`, `nivel_inseguridad_alimentaria`, que resultan en la clasificación en 4 niveles: seguridad, leve, moderada, severa. A ello se suman las variables `grupo_edad_teoria`, `nivel_edu_agrupado` y `grupo_edad_datos`. Para observar el proceso detallado de creación de las variables, por favor referirse al script. Para una definición más formal de cada una de ellas, por favor referirse al CodeBook presentado en la carpeta "outputs" [proximamente se generará en el script `07_Documentar.R`].

Como resultado del script `05`, se exportó en HTML un reporte de las variables creadas, así como una cuarta base de datos procesada que incluye las nuevas variables. De manera adicional, se utilizarán las variables analíticas creadas para hacer un nuevo EDA, que se podrá encontrar en el script `06_EDA_VariablesAnaliticas.R`, donde se crearán gráficos y tablas exportadas a la carpeta "outputs_exploracion_analitica".
