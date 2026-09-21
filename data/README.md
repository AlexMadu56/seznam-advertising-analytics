Datos

Los datos utilizados en este proyecto proceden del dataset Seznam del CTU Relational Dataset Repository, mantenido por la Czech Technical University in Prague.

El dataset contiene información anonimizada relacionada con la actividad publicitaria online y está organizado en varias tablas relacionadas.

Descarga

Los datos se descargan desde la página oficial del dataset Seznam en el CTU Relational Dataset Repository.

El procedimiento es:

1. Acceder a la página del dataset Seznam.
2. Descargar los archivos de datos proporcionados por CTU.
3. Descomprimir los archivos descargados.
4. Identificar las tablas utilizadas en este proyecto.
5. Importar los archivos en PostgreSQL.
6. Ejecutar el pipeline SQL incluido en:

sql/sql_pipeline_seznam.sql

Tablas utilizadas

El proyecto utiliza principalmente las siguientes tablas:

* client: información anonimizada de los clientes, incluyendo región y sector.
* probehnuto: registros de gasto publicitario.
* dobito: movimientos relacionados con las recargas del saldo publicitario.

El dataset original también contiene otras tablas, pero no todas se utilizan en el pipeline desarrollado en este proyecto.

Importación en PostgreSQL

Los archivos descargados se importan en una base de datos PostgreSQL.

Las tablas mantienen inicialmente la estructura y los nombres de las variables originales del dataset. El procesamiento posterior se realiza mediante SQL.

Una vez cargadas las tablas, se ejecuta:

sql/sql_pipeline_seznam.sql

Este pipeline transforma los datos originales en un conjunto de datos mensual a nivel de cliente y construye las variables necesarias para el modelo.

Archivos generados

Durante el desarrollo local se generan varios archivos que no forman parte del repositorio de GitHub:

train.csv
test.csv
dashboard_final.csv

Estos archivos contienen datos derivados del dataset original y están excluidos mediante .gitignore.

Por este motivo, para reproducir completamente el proyecto es necesario descargar primero los datos originales desde CTU y ejecutar el pipeline de transformación.

Estructura esperada

Después de descargar los datos, la estructura local puede variar dependiendo de cómo se hayan descomprimido los archivos. El repositorio no incluye los datos originales.

Una vez preparados los datos y ejecutado el pipeline, el entorno local debe disponer de los archivos necesarios para ejecutar el notebook de modelado y el dashboard.

Nota sobre los datos

Los datos no se incluyen en este repositorio debido a su tamaño. El repositorio contiene únicamente el código, la documentación y los procedimientos necesarios para trabajar con ellos.