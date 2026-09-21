# Seznam Advertising Analytics

[Dashboard interactivo](https://seznam-advertising-analytics-5ihyleia2utty79hl4r9wr.streamlit.app)

Predicción del gasto mensual en publicidad online a partir del comportamiento histórico de los clientes.

## Introducción

¿Cuánto gastará una empresa en publicidad online el próximo mes?

Este proyecto utiliza datos reales de actividad publicitaria de Seznam.cz para construir un modelo capaz de estimar el gasto publicitario de cada cliente en el mes siguiente.

Los datos contienen información anonimizada sobre clientes, gasto en publicidad y movimientos relacionados con su saldo publicitario. En lugar de trabajar con un único archivo, el proyecto mantiene la estructura relacional original y utiliza PostgreSQL y SQL para transformar las diferentes tablas en un conjunto de datos preparado para machine learning.

El objetivo no es únicamente entrenar un modelo, sino construir un flujo completo de trabajo:

Datos relacionales → PostgreSQL → SQL → Variables predictoras → Modelo → Evaluación → Dashboard

El modelo final obtiene un R² de 0,8655, con un error absoluto medio de 2.778,42 Kč y una mediana del error absoluto de 386,49 Kč, aproximadamente 15,91 € utilizando la conversión fijada en el proyecto.

Problema

Una plataforma de publicidad necesita conocer cómo puede evolucionar el gasto de sus clientes.

El comportamiento anterior de un cliente puede aportar información para estimar su gasto futuro. Por ejemplo, el gasto de los meses anteriores, su evolución, los servicios utilizados o las recargas realizadas pueden ayudar a identificar diferentes patrones de comportamiento.

El objetivo del proyecto es predecir cuánto gastará cada cliente durante un determinado mes utilizando únicamente información disponible antes de ese mes.

Por tanto, el problema se plantea como una predicción temporal:

Predecir el gasto publicitario de un cliente a partir de su historial anterior.

## Datos

Los datos proceden del dataset Seznam del CTU Relational Dataset Repository, mantenido por la Czech Technical University in Prague.

El dataset contiene información relacionada con la actividad publicitaria online de Seznam.cz y está organizado mediante varias tablas relacionadas.

Las principales tablas utilizadas en este proyecto son:

* client: información anonimizada de los clientes, incluyendo región y sector.
* dobito: movimientos relacionados con el dinero añadido al saldo publicitario.
* probehnuto: gasto publicitario realizado por los clientes.

El dataset original también contiene la tabla probehnuto_mimo_penezenku, pero el análisis desarrollado en este proyecto se centra en las tablas utilizadas para construir las variables de gasto y recarga.

Los datos originales se descargaron desde la plataforma pública de CTU y posteriormente se importaron a PostgreSQL.

Los archivos de datos originales y los datasets generados durante el análisis no se incluyen en este repositorio.

## Preparación de los datos

El procesamiento se realiza principalmente mediante SQL en PostgreSQL.

A partir de las tablas originales se construye un dataset mensual a nivel de cliente.

El pipeline incluye:

* Agregación mensual del gasto publicitario.
* Unión de las diferentes tablas mediante el identificador de cliente.
* Construcción de variables históricas de gasto.
* Gasto de los meses anteriores.
* Medias y medianas históricas.
* Medidas de variabilidad del gasto.
* Gasto máximo histórico.
* Gasto por servicio.
* Número de servicios utilizados anteriormente.
* Composición del gasto por servicio.
* Información sobre las recargas del saldo.
* Recargas de meses anteriores.
* Medias y variabilidad de las recargas.
* Variables relacionadas con la estacionalidad.
* Construcción del conjunto final utilizado para machine learning.

Una parte importante del proyecto consiste en evitar que el modelo utilice información que no estaría disponible en el momento de realizar una predicción.

Por ejemplo, para predecir el gasto de abril se utilizan datos disponibles hasta marzo, pero no información procedente del propio mes de abril.

## Variable objetivo

La variable objetivo es:

gasto_publicitario

Representa el gasto publicitario realizado por un cliente durante el mes que se quiere predecir.

El modelo final no predice directamente el nivel de gasto, sino el cambio respecto al mes anterior:

cambio = gasto actual - gasto del mes anterior

La predicción final se reconstruye posteriormente:

gasto predicho = gasto del mes anterior + cambio predicho

Este planteamiento permite que el modelo se centre en la evolución del gasto del cliente.

## División temporal

Para evaluar el modelo se utiliza una división temporal en lugar de una división aleatoria.

Los datos de entrenamiento corresponden al periodo:

agosto de 2013 – diciembre de 2014

Los datos de prueba corresponden al periodo:

enero de 2015 – octubre de 2015

De esta forma, el modelo aprende a partir de datos históricos y posteriormente se evalúa sobre meses posteriores.

El conjunto de prueba contiene 362.834 observaciones.

Esta estrategia reproduce mejor el escenario real de utilizar información histórica para realizar predicciones sobre periodos futuros.

## Modelo

El modelo final utilizado es HistGradientBoostingRegressor de scikit-learn.

Configuración:

loss = absolute_error
learning_rate = 0.025
max_iter = 600
max_leaf_nodes = 63
min_samples_leaf = 20
l2_regularization = 1.0
random_state = 56

Antes de entrenar el modelo:

* Las variables numéricas se completan utilizando la mediana y se estandarizan.
* Las variables categóricas se completan utilizando la categoría más frecuente y se transforman mediante one-hot encoding.

Se utiliza la semilla 56 para garantizar la reproducibilidad del proceso.

## Resultados

Los resultados obtenidos sobre el conjunto de prueba son:

Métrica	Resultado
R²	0,8655
MAE	2.778,42 Kč
RMSE	18.625,90 Kč
Mediana del error absoluto	386,49 Kč
Mediana del error absoluto	≈ 15,91 €

R² indica qué proporción de la variabilidad del gasto consigue explicar el modelo.

El MAE representa el error absoluto medio entre el gasto real y la predicción.

El RMSE penaliza en mayor medida los errores grandes.

La mediana del error absoluto permite observar el error de una observación situada en el centro de la distribución y es menos sensible a valores extremos.

En este dataset existen clientes con niveles de gasto muy elevados, por lo que se muestran varias métricas para obtener una visión más completa del comportamiento del modelo.

## Dashboard

El proyecto incluye un dashboard interactivo desarrollado con Streamlit.

El dashboard permite explorar los resultados del modelo desde tres perspectivas principales.

## Evolución

Compara el gasto real y el gasto predicho a lo largo del tiempo y permite observar la evolución agregada del comportamiento de los clientes.

## Precisión

Analiza cómo se distribuyen los errores de predicción mediante:

* Mediana del error absoluto.
* Percentil 75 y percentil 90 del error absoluto.
* Comparación entre gasto real y predicho.
* Evolución mensual del error.

## Comportamiento

Permite analizar el error de predicción según:

* Región.
* Sector.

El objetivo del dashboard es facilitar la interpretación de los resultados sin necesidad de conocer los detalles técnicos del modelo.

## Estructura del proyecto

seznam_project/
│
├── app.py
├── README.md
├── requirements.txt
├── .gitignore
│
├── sql/
│   └── pipeline.sql
│
└── data/
    └── README.md

Los archivos de datos originales y los archivos generados durante el entrenamiento no forman parte del repositorio.

## Reproducibilidad

Para reproducir el proyecto:

1. Descargar el dataset Seznam desde el CTU Relational Dataset Repository.
2. Importar las tablas originales en PostgreSQL.
3. Ejecutar el pipeline SQL.
4. Generar los conjuntos de entrenamiento y prueba.
5. Ejecutar el proceso de preparación y entrenamiento del modelo en Python.
6. Generar las predicciones.
7. Ejecutar el dashboard de Streamlit.

El proyecto utiliza PostgreSQL para el procesamiento y transformación de los datos relacionales y Python para el modelado, evaluación y visualización.

## Tecnologías

* PostgreSQL
* SQL
* Python
* pandas
* NumPy
* scikit-learn
* Plotly
* Streamlit
* Jupyter

## Conclusión

El proyecto desarrolla un flujo completo de análisis predictivo a partir de datos relacionales reales.

El proceso comienza con varias tablas de actividad de clientes y termina con un modelo capaz de estimar el gasto publicitario mensual y un dashboard para analizar sus resultados.

La estructura general del proyecto es:

Datos relacionales
        ↓
PostgreSQL
        ↓
SQL y creación de variables
        ↓
División temporal
        ↓
Machine learning
        ↓
Evaluación
        ↓
Dashboard interactivo

El principal objetivo es mostrar cómo transformar datos empresariales reales y relacionados entre sí en un proceso reproducible de análisis y predicción, manteniendo una separación clara entre la información histórica utilizada para generar las predicciones y los valores futuros que se quieren estimar.
