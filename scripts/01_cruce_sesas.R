# ==============================================================================
# ETAPA 1 - PROCESAMIENTO DE DATOS - CRUCE DE TABLAS
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Carga de Librerías
# ------------------------------------------------------------------------------

###install.packages("readxl") # Descomentar si no se cuenta con la librería
library(readxl)

# ------------------------------------------------------------------------------
# 1.1 Carga de Datos 
# ------------------------------------------------------------------------------

ruta_archivo <- "data/raw/2025 AP Individual Bases.xlsx"

# Importamos y forzamos la conversión a data.frame nativo.

emision <- as.data.frame(read_excel(ruta_archivo, sheet = "Emision", skip = 1))
siniestros <- as.data.frame(read_excel(ruta_archivo, sheet = "Siniestros", skip = 1))

# ------------------------------------------------------------------------------
# 1.2 Análisis Exploratorio y Estructura de Datos (Data Profiling)
# ------------------------------------------------------------------------------
cat("\n--- DIMENSIONES DE LAS TABLAS (Filas, Columnas) ---\n")
cat("Emisión (Expuestos):", dim(emision), "\n")
cat("Siniestros (Reclamaciones):", dim(siniestros), "\n")

cat("\n--- NOMBRES DE LAS COLUMNAS ---\n")
print(colnames(emision))
print(colnames(siniestros))

cat("\n--- ESTRUCTURA DE DATOS (Verificación de Tipos) ---\n")
# str() nos dice si R leyó los números como números (num) o como cadenas (chr)
cat("Estructura - Emisión:\n")
str(emision)
cat("Estructura - Siniestros:\n")
str(siniestros)

cat("\n--- DETECCIÓN DE DATOS FALTANTES (NAs) POR COLUMNA ---\n")
# Esto nos dirá si faltan edades, montos o variables clave que afecten severidad/frecuencia
cat("Faltantes en Emisión:\n")
print(colSums(is.na(emision)))
cat("Faltantes en Siniestros:\n")
print(colSums(is.na(siniestros)))

cat("\n--- RESUMEN ESTADÍSTICO (Detección de anomalías) ---\n")
# Ayuda a ver si hay edades negativas o montos ilógicos
summary(emision)
summary(siniestros)

# ------------------------------------------------------------------------------
# 1.3 Limpieza y Preparación de Llaves Tarifarias
# ------------------------------------------------------------------------------
emision$EDAD <- as.numeric(emision$EDAD)
siniestros$EDAD <- as.numeric(siniestros$EDAD)

# Esto eliminará los registros que decían "No disponible"
emision <- subset(emision, !is.na(EDAD))
siniestros <- subset(siniestros, !is.na(EDAD))

# Ajustamos las llaves a las variables comunes en ambas tablas
llaves <- c("COBERTURA", "ENTIDAD", "EDAD", "SEXO")

# ------------------------------------------------------------------------------
# 1.4 Agrupación: Expuestos (Denominador) y Siniestros (Numerador)
# ------------------------------------------------------------------------------

asegurados_agrup <- aggregate(
  `NUMERO DE ASEGURADOS` ~ COBERTURA + ENTIDAD + EDAD + SEXO,
  data = emision, FUN = sum, na.rm = TRUE
)

reclamaciones_agrup <- aggregate(
  cbind(`NUMERO DE RECLAMACIONES`, `MONTO PAGADO`) ~ COBERTURA + ENTIDAD + EDAD + SEXO,
  data = siniestros, FUN = sum, na.rm = TRUE
)
# ------------------------------------------------------------------------------
# 1.5 Cruce Riguroso de Tablas 
# ------------------------------------------------------------------------------
tabla_cruce <- merge(asegurados_agrup, reclamaciones_agrup, by = llaves, all.x = TRUE)

# Limpieza de nulos donde no hubo accidentes
tabla_cruce$`NUMERO DE RECLAMACIONES`[is.na(tabla_cruce$`NUMERO DE RECLAMACIONES`)] <- 0
tabla_cruce$`MONTO PAGADO`[is.na(tabla_cruce$`MONTO PAGADO`)] <- 0

# ------------------------------------------------------------------------------
# 1.6 Cálculos Actuariales: Frecuencia, Severidad y Prima Pura
# ------------------------------------------------------------------------------
tabla_cruce$Frecuencia <- tabla_cruce$`NUMERO DE RECLAMACIONES` / tabla_cruce$`NUMERO DE ASEGURADOS`
# Usamos ifelse para evitar dividir entre 0 y generar valores infinitos
tabla_cruce$Severidad <- ifelse(tabla_cruce$`NUMERO DE RECLAMACIONES` > 0, 
                                tabla_cruce$`MONTO PAGADO` / tabla_cruce$`NUMERO DE RECLAMACIONES`, 
                                0)

# Cálculo Final: Prima Pura de Riesgo
tabla_cruce$Prima_Pura <- tabla_cruce$Frecuencia * tabla_cruce$Severidad

frecuencia_nacional <- sum(tabla_cruce$`NUMERO DE RECLAMACIONES`) / sum(tabla_cruce$`NUMERO DE ASEGURADOS`)
cat("\nFrecuencia Nacional 2025:", round(frecuencia_nacional, 6), "\n")

# ==============================================================================
# ETAPA 2 - ANALISIS EXPLORATORIO
# ==============================================================================
# ------------------------------------------------------------------------------
# 2.1 Análisis Univariado
# ------------------------------------------------------------------------------
cat("\n--- FRECUENCIA POR SEXO ---\n")
freq_sexo <- aggregate(cbind(`NUMERO DE ASEGURADOS`, `NUMERO DE RECLAMACIONES`) ~ SEXO, data = tabla_cruce, FUN = sum)
freq_sexo$Frecuencia <- freq_sexo$`NUMERO DE RECLAMACIONES` / freq_sexo$`NUMERO DE ASEGURADOS`
print(freq_sexo[order(-freq_sexo$Frecuencia), ])

cat("\n--- FRECUENCIA POR COBERTURA ---\n")
freq_cobertura <- aggregate(cbind(`NUMERO DE ASEGURADOS`, `NUMERO DE RECLAMACIONES`) ~ COBERTURA, data = tabla_cruce, FUN = sum)
freq_cobertura$Frecuencia <- freq_cobertura$`NUMERO DE RECLAMACIONES` / freq_cobertura$`NUMERO DE ASEGURADOS`
print(freq_cobertura[order(-freq_cobertura$Frecuencia), ])

# Top 5 Entidades
freq_entidad <- aggregate(cbind(`NUMERO DE ASEGURADOS`, `NUMERO DE RECLAMACIONES`) ~ ENTIDAD, data = tabla_cruce, FUN = sum)
freq_entidad$Frecuencia <- freq_entidad$`NUMERO DE RECLAMACIONES` / freq_entidad$`NUMERO DE ASEGURADOS`
freq_entidad_valida <- subset(freq_entidad, `NUMERO DE ASEGURADOS` > 100)
top_5_entidades <- head(freq_entidad_valida[order(-freq_entidad_valida$Frecuencia), ], 5)

cat("\n--- TOP 5 ENTIDADES CON MAYOR FRECUENCIA ---\n")
print(top_5_entidades)
# ------------------------------------------------------------------------------
# 2.2 Gráficos Univariados: Severidad por Cobertura y Top Entidades por Frecuencia
# ------------------------------------------------------------------------------
par(bty = "n", mar = c(5, 10, 4, 2), family = "sans", las = 1) # las=1 para texto horizontal

# Severidad por Cobertura
sev_cobertura <- aggregate(cbind(`MONTO PAGADO`, `NUMERO DE RECLAMACIONES`) ~ COBERTURA, data = tabla_cruce, FUN = sum)
sev_cobertura$Severidad <- sev_cobertura$`MONTO PAGADO` / sev_cobertura$`NUMERO DE RECLAMACIONES`
sev_cobertura <- sev_cobertura[order(sev_cobertura$Severidad), ]

barplot(sev_cobertura$Severidad, names.arg = sev_cobertura$COBERTURA, horiz = TRUE,
        col = "#3498db", border = NA, xlab = "Severidad Promedio ($)",
        main = "Severidad por Tipo de Cobertura", cex.names = 0.8)

top_5_entidades_plot <- top_5_entidades[order(top_5_entidades$Frecuencia), ]
barplot(top_5_entidades_plot$Frecuencia, names.arg = top_5_entidades_plot$ENTIDAD, horiz = TRUE,
        col = "#e67e22", border = NA, xlab = "Frecuencia Relativa",
        main = "Top 5 Entidades con Mayor Frecuencia", cex.names = 0.8)

# ------------------------------------------------------------------------------
# 2.3 Análisis Multivariable (Edad vs Sexo)
# ------------------------------------------------------------------------------

freq_edad_sexo <- aggregate(
  cbind(`NUMERO DE ASEGURADOS`, `NUMERO DE RECLAMACIONES`) ~ EDAD + SEXO,
  data = tabla_cruce, FUN = sum
)
freq_edad_sexo$Frecuencia <- freq_edad_sexo$`NUMERO DE RECLAMACIONES` / freq_edad_sexo$`NUMERO DE ASEGURADOS`

par(bty = "n", mar = c(5, 5, 4, 2), family = "sans", las = 1)
datos_f <- subset(freq_edad_sexo, SEXO %in% c("Femenino", "Mujer", "M", "F"))
datos_m <- subset(freq_edad_sexo, SEXO %in% c("Masculino", "Hombre", "H"))
max_freq <- max(freq_edad_sexo$Frecuencia, na.rm = TRUE)

plot(datos_f$EDAD, datos_f$Frecuencia, type = "l", col = "#2c3e50", lwd = 2.5, ylim = c(0, max_freq),
     xlab = "Edad", ylab = "Frecuencia de Siniestralidad",
     main = "Curva de Frecuencia por Edad y Sexo", cex.main = 1.2, col.main = "#333333")
lines(datos_m$EDAD, datos_m$Frecuencia, col = "#e74c3c", lwd = 2.5)
legend("topleft", legend = c("Femenino", "Masculino"), col = c("#2c3e50", "#e74c3c"), lwd = 2.5, bty = "n", cex = 0.9)

# ------------------------------------------------------------------------------
# 2.4 Cruce Multivariable: Severidad por Edad y Sexo en la Entidad más Riesgosa
# ------------------------------------------------------------------------------

# CORRECCIÓN: Usamos head(..., 1) para extraer el 1er lugar (Ciudad de México) en vez del 5to
entidad_critica <- head(top_5_entidades$ENTIDAD, 1)

# Filtramos la tabla de cruce solo para esta entidad
datos_entidad <- subset(tabla_cruce, ENTIDAD == entidad_critica)

# Agrupamos severidad por Edad y Sexo dentro de esta entidad
cruce_triple <- aggregate(cbind(`MONTO PAGADO`, `NUMERO DE RECLAMACIONES`) ~ EDAD + SEXO, data = datos_entidad, FUN = sum)
cruce_triple$Severidad <- ifelse(cruce_triple$`NUMERO DE RECLAMACIONES` > 0,
                                 cruce_triple$`MONTO PAGADO` / cruce_triple$`NUMERO DE RECLAMACIONES`, 0)

datos_f_triple <- subset(cruce_triple, SEXO %in% c("Femenino", "Mujer", "M", "F"))
datos_m_triple <- subset(cruce_triple, SEXO %in% c("Masculino", "Hombre", "H"))

par(bty = "n", mar = c(5, 5, 4, 2), family = "sans", las = 1)

# Antes de graficar, verificamos que ambas tablas tengan al menos un registro válido
if(nrow(datos_f_triple) > 0 & nrow(datos_m_triple) > 0) {
  
  max_sev <- max(cruce_triple$Severidad, na.rm = TRUE)
  
  plot(datos_f_triple$EDAD, datos_f_triple$Severidad, type = "l", 
       col = "#8e44ad", lwd = 2.5, ylim = c(0, max_sev),
       xlab = "Edad", ylab = "Severidad Promedio ($)",
       main = paste("Severidad por Edad y Sexo en", entidad_critica),
       cex.main = 1.1, col.main = "#333333")
  
  lines(datos_m_triple$EDAD, datos_m_triple$Severidad, col = "#27ae60", lwd = 2.5)
  
  legend("topleft", legend = c("Femenino", "Masculino"), 
         col = c("#8e44ad", "#27ae60"), lwd = 2.5, bty = "n", cex = 0.9)
         
} else {
  cat("\nNota: No hay suficientes datos válidos para graficar la severidad en", entidad_critica, "\n")
}


# ==============================================================================
# ETAPA 3 - ENTREGABLES
# ==============================================================================

# ------------------------------------------------------------------------------
# 3.1 Tabla Tarifaria Final (Prima Pura de Riesgo)
# ------------------------------------------------------------------------------
# Filtramos cohortes con masa crítica (>50 asegurados) y ordenamos por prima pura
tabla_valida <- subset(tabla_cruce, `NUMERO DE ASEGURADOS` >= 50)
top_primas <- head(tabla_valida[order(-tabla_valida$Prima_Pura), c("COBERTURA", "ENTIDAD", "EDAD", "SEXO", "Prima_Pura")], 10)

cat("\n--- TOP 10 COHORTES TARIFARIAS (MAYOR PRIMA PURA DE RIESGO) ---\n")
print(top_primas)

# ------------------------------------------------------------------------------
# 3.2 Exportación de Datos para el Reporte
# ------------------------------------------------------------------------------
write.csv(tabla_cruce, "data/processed/tabla_consolidada_sesas.csv", row.names = FALSE)
cat("\nArchivo 'tabla_consolidada_sesas.csv' exportado exitosamente a la carpeta data/processed/\n")