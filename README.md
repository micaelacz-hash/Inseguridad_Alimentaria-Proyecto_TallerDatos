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
| Documentación (CodeBook) | `labelled`, `codebook` |

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
│   ├── 06_EDA_VariablesAnaliticas.R        # Análisis exploratorio de las variables analíticas creadas
│   └── 07_Documentar.R                  # CodeBook con la definición formal de cada variable
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

---

## Contexto metodológico: la FIES y el modelo Rasch
La Escala de Experiencia de Inseguridad Alimentaria (FIES, por sus siglas en inglés) es el instrumento desarrollado por la FAO (Organización de las Naciones Unidas para la Alimentación y la Agricultura) a través de su iniciativa Voices of the Hungry, para medir la inseguridad alimentaria. Asimismo, esta es la base del Indicador 2.1.2 de los Objetivos de Desarrollo Sostenible (ODS) de Naciones Unidas, y se reporta anualmente en el informe The State of Food Security and Nutrition in the World (SOFI).

La FIES no se analiza como una simple suma de respuestas afirmativas (una escala simple), sino mediante un modelo Rasch: un parámetro de la Teoría de Respuesta al Ítem. Este modelo estima, para cada una de las 8 preguntas, un parámetro de severidad: **qué tan "difícil" es que un hogar responda "Sí"**. A partir de ello asigna a cada persona un puntaje de severidad latente. 

En el caso de este proyecto, la adopción de este enfoque no es una elección arbitraria, sino que va acorde al protocolo oficial y obligatorio de la FAO para construir la escala de inseguirdad alimentaria, ya que permite calibrar las mediciones contra una escala de referencia global, haciendo comparables los resultados de inseguridad alimentaria entre países y a lo largo del tiempo (Cafiero, Viviani & Nord, 2018).

En el Perú, el Instituto Nacional de Estadística e Informática (INEI) **incorporó el módulo de Inseguridad Alimentaria (FIES) a la ENAHO de forma permanente a partir de 2025**, tras un proceso de adaptación metodológica desarrollado entre 2023 y 2026 con acompañamiento técnico directo de la FAO. Según la primera medición oficial (2025), la inseguridad alimentaria moderada o severa afectó al 30.5% de la población peruana, y la severa al 3.4%. Estas cifras oficiales se usan en este proyecto como referencia de comparación frente a los resultados obtenidos con la base analítica propia **(ver sección CLASIFICAR)**.

### Referencias
- Cafiero, C., Viviani, S., & Nord, M. (2018). Food security measurement in a global context: The food insecurity experience scale. _Measurement, 116_, 146–152. https://doi.org/10.1016/j.measurement.2017.10.065
- FAO. Voices of the Hungry — Background. fao.org
- FAO. Applying the FIES. fao.org
- FAO. (2025, 4 de junio). Applying the FIES | Measuring hunger, food security and food consumption | Food and Agriculture Organization of the United Nations. MeasuringHunger. https://www.fao.org/measuring-hunger/access-to-food/applying-the-fies/en
- INEI. (2023). Instituto Nacional de Estadistica e Informatica. Inei.Gob.Pe. https://m.inei.gob.pe/prensa/noticias/inei-realizara-prueba-piloto-de-la-aplicacion-del-modulo-de-inseguridad-alimentaria-en-la-enaho-15251/
- El Peruano (2026, 11 de junio). Inseguridad alimentaria moderada o severa afectó al 30,5% de la población peruana en 2025. Diario Oficial El Peruano. https://elperuano.pe/noticia/297792-inseguridad-alimentaria-moderada-o-severa-afecto-al-305-de-la-poblacion-peruana-en-2025
‌
---

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

A partir de este puntaje, se construyeron las siguientes variables analíticas: `score_fies_bruto`, `severidad_rasch`, `nivel_inseguridad_alimentaria`, que resultan en la clasificación en 4 niveles: seguridad, leve, moderada, severa. A ello se suman las variables `grupo_edad_teoria`, `nivel_edu_agrupado` y `grupo_edad_datos`. Para observar el proceso detallado de creación de las variables, por favor referirse al script. Para una definición más formal de cada una de ellas, por favor referirse al CodeBook generado en el script `07_Documentar.R`.

Como resultado del script `05`, se exportó en HTML un reporte de las variables creadas, así como una cuarta base de datos procesada que incluye las nuevas variables. De manera adicional, se utilizaron las variables analíticas creadas para hacer un nuevo EDA, que se encuentra en el script 06_EDA_VariablesAnaliticas.R, donde se generaron gráficos y tablas exportadas a la carpeta "outputs_exploracion_analitica".

## DOCUMENTAR

En el script `07_Documentar.R`, se construyó el **CodeBook** del proyecto: documento que explica qué significa, de dónde viene y cómo se construyó cada variable importante de nuestro análisis

Para ello, primero, se armó una base de datos solo las variables que se quieren documentar: las originales ya etiquetadas (script `03_Explorar.R`) y las analíticas creadas a partir del modelo Rasch (script: `05_Clasificar.R`). A cada una de estas se le agregó una descripción clara (usando el paquete `labelled`); en el caso de las variables originales: el nombre de la pregunta de la ENAHO de la que provienen (por ejemplo, `P207` para sexo o `P130_1` para la primera pregunta de inseguridad alimentaria).

En el caso de las variables que nosotros construimos, especificamos las decisiones metodológicas: explicamos cómo se calcularon y qué decisiones se tomaron (por ejemplo, cómo se trataron los NAs, o qué puntos de corte se usaron para clasificar los niveles de inseguridad alimentaria).

Agregamos la información anteriormente mencionada a la base de datos, y con ello se generó el CodeBook usando el paquete `codebook`, el cual nos armó un reporte con la frecuencia, el tipo de datos, las etiquetas y los estadísticos básicos de cada variable. Guardamos este reporte como archivo `.Rmd` y `.html` en la carpeta "outputs", para que pueda consultarse la base de datos sin necesidad de revisar todo el código.

---

## Limitaciones metodológicas

Finalmente, al comparar los resultados de este proyecto con la cifra oficial que el INEI publicó en 2026, correspondiente al año 2025 (30.5% de la población en inseguridad alimentaria moderada o severa, y 3.4% en severa), se encontraron diferencias. Nuestra base de datos analítica calcula una prevalencia de 26.69% en inseguridad moderada o severa, y 7.21% en severa, este último porcentaje es más del doble de lo que reporta el INEI. Por todo ello, a continuación se brindar algunas aclaraciones y comentarios sobre las limitaciones metodológicas de este proyecto:

1. **Alcance poblacional distinto**: nuestra base solo incluye personas con nivel educativo declarado y cuyo hogar respondió el módulo de Inseguridad Alimentaria (ver sección ACONDICIONAR), lo que representa aproximadamente el 55% de la población total del Perú. En cambio, INEI reporta sobre la población total del país. Si los hogares que no respondieron el módulo 130 no lo hicieron de forma aleatoria (si el módulo se aplicó olo en ciertos meses o con menor cobertura en ciertas zonas) esto puede introducir un sesgo en nuestros resultados.

2. **Puntos de corte de clasificación**: en nuestro caso usamos los cortes convencionales genéricos para escalas FIES de 8 ítems (4 y 7 respuestas afirmativas), tal como se documenta en la sección CLASIFICAR. El INEI, en cambio, sigue el protocolo oficial de la FAO, que calibra sus umbrales contra una escala de referencia global, la cual puede no coincidir exactamente con un corte simple del puntaje bruto para el caso peruano.

3. **Réplica de la respuesta a nivel de hogar**: como se explica en la sección ACONDICIONAR, la respuesta del módulo de inseguridad alimentaria se responde una sola vez por hogar y se replica a todos sus integrantes. Entonces, si los hogares con mayor severidad tienden a tener más miembros, esto puede inflar la proporción de personas en los niveles más severos, respecto a un cálculo hecho directamente a nivel de hogar.

Estas diferencias no invalidan el análisis exploratorio de este proyecto, pero sí deben tenerse en cuenta al interpretar los resultados. Lo realizado en este proyecto es una aproximación descriptiva propia, no una réplica exacta de la cifra oficial del INEI.
