
# Proyecto de Tarificación de Accidentes Personales (SESAS 2025)

## Descripción del Proyecto

Este repositorio contiene el flujo de trabajo actuarial para la tarificación de una cartera de Accidentes Personales Individuales, utilizando la base de datos SESAS 2025 de la CNSF. El objetivo principal es calcular la prima pura de riesgo mediante la estimación precisa de la frecuencia de siniestralidad y la severidad por cada cohorte tarifaria.

## Objetivos Analíticos

- **Procesamiento:** Cruzar la información de expuestos (Emisión) y reclamaciones (Siniestros) utilizando exclusivamente herramientas nativas de R Base, sin alterar los archivos originales.
- **Cálculo Actuarial:** Determinar la frecuencia relativa, severidad y prima pura de riesgo agrupando por las llaves comunes validadas: Cobertura, Entidad, Edad y Sexo.
- **Análisis Factorial:** Evaluar las variaciones de siniestralidad mediante segmentaciones univariadas y combinadas (ej. Edad vs. Sexo vs. Entidad) para identificar los factores que más impactan en el riesgo.
- **Entregable:** Generar un reporte ejecutivo con gráficos corporativos que fundamente el diseño de la tarifa final.

## Estructura del Repositorio

Para mantener el orden, evitar conflictos de versiones y asegurar la reproducibilidad, el proyecto se divide en las siguientes carpetas:

- `data/raw/`: Directorio para el archivo original (`2025 AP Individual Bases.xlsx`). *Nota: Por políticas de peso y seguridad, los datos crudos no se suben a GitHub (están ignorados en el `.gitignore`). Cada miembro del equipo debe colocar el archivo manualmente en su entorno local.*
- `data/processed/`: Almacena la tabla consolidada (`tabla_consolidada_sesas.csv`) generada tras el cruce, limpieza y cálculo de primas.
- `scripts/`: Contiene el código de procesamiento central (`01_cruce_sesas.R`). Aquí se realiza el *data profiling*, la limpieza de NAs, el `merge()` de las tablas y el cálculo aritmético de las métricas.
- `analysis/`: Contiene los scripts de R Markdown (`02_eda_frecuencias.Rmd`) dedicados al análisis exploratorio de datos (EDA), visualización corporativa y cruces multivariables.
- `report/`: Destinado a los entregables finales (PDF o HTML) con las conclusiones actuariales.

## Flujo de Trabajo del Equipo

Nuestra metodología de colaboración garantiza que el código sea transparente y que los cálculos estén estandarizados para todos los miembros:

1. **Preparación Local:** Cada integrante descarga el repositorio mediante `git clone` o `git pull` y se asegura de tener la base de datos original guardada en `data/raw/`.
2. **Ejecución del Procesamiento (Regla R Base):** Se ejecuta el script `01_cruce_sesas.R`. Este código importa los datos (usando únicamente la librería `readxl`), depura los registros nulos, realiza el cruce asimétrico (*Left Join*) para calcular las primas y exporta automáticamente la base consolidada a `data/processed/`. **Queda estrictamente prohibido el uso de paquetes externos como `dplyr` o `tidyr` para la manipulación de datos**.
3. **Análisis y Documentación:** A partir del archivo procesado unificado, se trabaja en la carpeta `analysis/`. El compañero encargado de la redacción (Salas) utilizará estos datos limpios y las visualizaciones generadas para redactar las interpretaciones, ajustar los gráficos de factores de riesgo y fundamentar analíticamente el diseño de la prima en el documento RMarkdown.
4. **Control de Cambios:** Todos los avances en los scripts y reportes se sincronizan en GitHub mediante *commits* descriptivos, manteniendo el repositorio libre de archivos temporales de R o bases de datos pesadas.
