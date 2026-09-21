-- ============================================================
-- SEZNAM ADVERTISING
-- PIPELINE COMPLETO DE PREPARACIÓN DE DATOS PARA MACHINE LEARNING
-- ============================================================
--
-- Unidad de análisis:
--     1 cliente × 1 mes
--
-- Variable objetivo:
--     gasto_publicitario
--
-- Arquitectura:
--     PostgreSQL -> preparación / feature engineering
--     Python     -> preprocesamiento / modelización / evaluación
--
-- Las tablas originales deben estar cargadas previamente:
--     client
--     probehnuto
--     dobito
--
-- El resultado final:
--     train
--     test
--
-- Todas las variables predictoras utilizan únicamente información
-- anterior al mes objetivo.
-- ============================================================



-- ============================================================
-- 1. AGREGACIÓN DEL GASTO PUBLICITARIO POR CLIENTE Y MES
-- ============================================================


CREATE TABLE public.gasto_cliente_mes AS
SELECT
    client_id,
    month_year_datum_transakce AS mes,
    SUM(kc_proklikano) AS gasto_publicitario,
    COUNT(*) AS operaciones_publicidad
FROM public.probehnuto
WHERE client_id IS NOT NULL
GROUP BY client_id, month_year_datum_transakce;

CREATE INDEX idx_gasto_cliente_mes
ON public.gasto_cliente_mes (client_id, mes);

DROP TABLE IF EXISTS public.probehnuto;
DROP TABLE IF EXISTS public.dobito;
DROP TABLE IF EXISTS public.client;


CREATE TABLE public.client (
    client_id INTEGER,
    kraj VARCHAR(255),
    obor VARCHAR(255)
);


CREATE TABLE public.probehnuto (
    client_id INTEGER,
    month_year_datum_transakce DATE,
    sluzba VARCHAR(255),
    kc_proklikano NUMERIC(10,2)
);


CREATE TABLE public.dobito (
    client_id INTEGER,
    month_year_datum_transakce DATE,
    kc_dobito NUMERIC(10,2)
);


----------
CREATE TABLE gasto_cliente_mes AS
SELECT
    client_id,
    month_year_datum_transakce AS mes,
    SUM(kc_proklikano) AS gasto_publicitario,
    COUNT(*) AS operaciones_publicidad
FROM probehnuto
WHERE client_id IS NOT NULL
GROUP BY client_id, month_year_datum_transakce;

CREATE INDEX idx_gasto_cliente_mes
ON gasto_cliente_mes (client_id, mes);


-- ============================================================
-- 2. GASTO POR CLIENTE, MES Y SERVICIO
-- ============================================================

DROP TABLE IF EXISTS mapa_servicios;

CREATE TEMP TABLE mapa_servicios AS
SELECT
    sluzba,
    ROW_NUMBER() OVER (ORDER BY sluzba) AS numero_servicio
FROM (
    SELECT DISTINCT sluzba
    FROM probehnuto
    WHERE sluzba IS NOT NULL
) s;

DROP TABLE IF EXISTS gasto_servicio_mes;

CREATE TABLE gasto_servicio_mes AS
SELECT
    p.client_id,
    p.month_year_datum_transakce AS mes,

    SUM(CASE WHEN m.numero_servicio = 1 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_1,
    SUM(CASE WHEN m.numero_servicio = 2 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_2,
    SUM(CASE WHEN m.numero_servicio = 3 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_3,
    SUM(CASE WHEN m.numero_servicio = 4 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_4,
    SUM(CASE WHEN m.numero_servicio = 5 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_5,
    SUM(CASE WHEN m.numero_servicio = 6 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_6,
    SUM(CASE WHEN m.numero_servicio = 7 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_7,
    SUM(CASE WHEN m.numero_servicio = 8 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_8,
    SUM(CASE WHEN m.numero_servicio = 9 THEN p.kc_proklikano ELSE 0 END) AS gasto_servicio_9

FROM probehnuto p
LEFT JOIN mapa_servicios m
    ON p.sluzba = m.sluzba
WHERE p.client_id IS NOT NULL
GROUP BY p.client_id, p.month_year_datum_transakce;

CREATE INDEX idx_gasto_servicio_mes
ON gasto_servicio_mes (client_id, mes);


-- ============================================================
-- 3. RECARGAS POR CLIENTE Y MES
-- ============================================================

DROP TABLE IF EXISTS recarga_cliente_mes;

CREATE TABLE recarga_cliente_mes AS
SELECT
    client_id,
    month_year_datum_transakce AS mes,

    SUM(kc_dobito) AS recarga_neta,

    SUM(CASE WHEN kc_dobito > 0 THEN kc_dobito ELSE 0 END)
        AS recarga_positiva,

    SUM(CASE WHEN kc_dobito < 0 THEN -kc_dobito ELSE 0 END)
        AS ajuste_negativo,

    COUNT(*) AS operaciones_recarga,

    COUNT(*) FILTER (WHERE kc_dobito < 0)
        AS num_ajustes_negativos

FROM dobito
WHERE client_id IS NOT NULL
GROUP BY client_id, month_year_datum_transakce;

CREATE INDEX idx_recarga_cliente_mes
ON recarga_cliente_mes (client_id, mes);


-- ============================================================
-- 4. TABLA BASE CLIENTE-MES
-- ============================================================

DROP TABLE IF EXISTS cliente_mes_base;

CREATE TABLE cliente_mes_base AS
SELECT
    g.client_id,
    g.mes,
    g.gasto_publicitario,

    COALESCE(r.recarga_neta, 0) AS recarga_neta,
    COALESCE(r.recarga_positiva, 0) AS recarga_positiva,
    COALESCE(r.ajuste_negativo, 0) AS ajuste_negativo,
    COALESCE(r.operaciones_recarga, 0) AS operaciones_recarga,
    COALESCE(r.num_ajustes_negativos, 0) AS num_ajustes_negativos,

    c.kraj AS region,
    c.obor AS sector

FROM gasto_cliente_mes g
LEFT JOIN recarga_cliente_mes r
    ON g.client_id = r.client_id
   AND g.mes = r.mes
LEFT JOIN client c
    ON g.client_id = c.client_id;


-- ============================================================
-- 5. HISTORIAL DE GASTO: LAGS CALENDARIO 1-12 MESES
-- ============================================================

DROP TABLE IF EXISTS dataset_historico;

CREATE TABLE dataset_historico AS
SELECT
    b.*,

    COALESCE(g1.gasto_publicitario, 0) AS gasto_lag_1,
    COALESCE(g2.gasto_publicitario, 0) AS gasto_lag_2,
    COALESCE(g3.gasto_publicitario, 0) AS gasto_lag_3,
    COALESCE(g4.gasto_publicitario, 0) AS gasto_lag_4,
    COALESCE(g5.gasto_publicitario, 0) AS gasto_lag_5,
    COALESCE(g6.gasto_publicitario, 0) AS gasto_lag_6,
    COALESCE(g7.gasto_publicitario, 0) AS gasto_lag_7,
    COALESCE(g8.gasto_publicitario, 0) AS gasto_lag_8,
    COALESCE(g9.gasto_publicitario, 0) AS gasto_lag_9,
    COALESCE(g10.gasto_publicitario, 0) AS gasto_lag_10,
    COALESCE(g11.gasto_publicitario, 0) AS gasto_lag_11,
    COALESCE(g12.gasto_publicitario, 0) AS gasto_lag_12

FROM cliente_mes_base b

LEFT JOIN gasto_cliente_mes g1
    ON g1.client_id = b.client_id
   AND g1.mes = b.mes - INTERVAL '1 month'
LEFT JOIN gasto_cliente_mes g2
    ON g2.client_id = b.client_id
   AND g2.mes = b.mes - INTERVAL '2 months'
LEFT JOIN gasto_cliente_mes g3
    ON g3.client_id = b.client_id
   AND g3.mes = b.mes - INTERVAL '3 months'
LEFT JOIN gasto_cliente_mes g4
    ON g4.client_id = b.client_id
   AND g4.mes = b.mes - INTERVAL '4 months'
LEFT JOIN gasto_cliente_mes g5
    ON g5.client_id = b.client_id
   AND g5.mes = b.mes - INTERVAL '5 months'
LEFT JOIN gasto_cliente_mes g6
    ON g6.client_id = b.client_id
   AND g6.mes = b.mes - INTERVAL '6 months'
LEFT JOIN gasto_cliente_mes g7
    ON g7.client_id = b.client_id
   AND g7.mes = b.mes - INTERVAL '7 months'
LEFT JOIN gasto_cliente_mes g8
    ON g8.client_id = b.client_id
   AND g8.mes = b.mes - INTERVAL '8 months'
LEFT JOIN gasto_cliente_mes g9
    ON g9.client_id = b.client_id
   AND g9.mes = b.mes - INTERVAL '9 months'
LEFT JOIN gasto_cliente_mes g10
    ON g10.client_id = b.client_id
   AND g10.mes = b.mes - INTERVAL '10 months'
LEFT JOIN gasto_cliente_mes g11
    ON g11.client_id = b.client_id
   AND g11.mes = b.mes - INTERVAL '11 months'
LEFT JOIN gasto_cliente_mes g12
    ON g12.client_id = b.client_id
   AND g12.mes = b.mes - INTERVAL '12 months';


-- ============================================================
-- 6. RESÚMENES HISTÓRICOS DE GASTO
-- ============================================================

ALTER TABLE dataset_historico
ADD COLUMN gasto_media_3m DOUBLE PRECISION,
ADD COLUMN gasto_media_6m DOUBLE PRECISION,
ADD COLUMN gasto_media_12m DOUBLE PRECISION,
ADD COLUMN gasto_mediana_12m DOUBLE PRECISION,
ADD COLUMN gasto_std_3m DOUBLE PRECISION,
ADD COLUMN gasto_std_6m DOUBLE PRECISION,
ADD COLUMN gasto_std_12m DOUBLE PRECISION,
ADD COLUMN gasto_max_12m DOUBLE PRECISION,
ADD COLUMN num_meses_activos_12m INTEGER;

UPDATE dataset_historico
SET
    gasto_media_3m = (gasto_lag_1 + gasto_lag_2 + gasto_lag_3) / 3.0,

    gasto_media_6m = (
        gasto_lag_1 + gasto_lag_2 + gasto_lag_3 +
        gasto_lag_4 + gasto_lag_5 + gasto_lag_6
    ) / 6.0,

    gasto_media_12m = (
        gasto_lag_1 + gasto_lag_2 + gasto_lag_3 +
        gasto_lag_4 + gasto_lag_5 + gasto_lag_6 +
        gasto_lag_7 + gasto_lag_8 + gasto_lag_9 +
        gasto_lag_10 + gasto_lag_11 + gasto_lag_12
    ) / 12.0,

    gasto_std_3m = (
        SELECT STDDEV_SAMP(v)
        FROM (VALUES
            (gasto_lag_1),(gasto_lag_2),(gasto_lag_3)
        ) AS x(v)
    ),

    gasto_std_6m = (
        SELECT STDDEV_SAMP(v)
        FROM (VALUES
            (gasto_lag_1),(gasto_lag_2),(gasto_lag_3),
            (gasto_lag_4),(gasto_lag_5),(gasto_lag_6)
        ) AS x(v)
    ),

    gasto_std_12m = (
        SELECT STDDEV_SAMP(v)
        FROM (VALUES
            (gasto_lag_1),(gasto_lag_2),(gasto_lag_3),
            (gasto_lag_4),(gasto_lag_5),(gasto_lag_6),
            (gasto_lag_7),(gasto_lag_8),(gasto_lag_9),
            (gasto_lag_10),(gasto_lag_11),(gasto_lag_12)
        ) AS x(v)
    ),

    gasto_max_12m = GREATEST(
        gasto_lag_1,gasto_lag_2,gasto_lag_3,gasto_lag_4,
        gasto_lag_5,gasto_lag_6,gasto_lag_7,gasto_lag_8,
        gasto_lag_9,gasto_lag_10,gasto_lag_11,gasto_lag_12
    ),

    num_meses_activos_12m =
        (gasto_lag_1 > 0)::INTEGER +
        (gasto_lag_2 > 0)::INTEGER +
        (gasto_lag_3 > 0)::INTEGER +
        (gasto_lag_4 > 0)::INTEGER +
        (gasto_lag_5 > 0)::INTEGER +
        (gasto_lag_6 > 0)::INTEGER +
        (gasto_lag_7 > 0)::INTEGER +
        (gasto_lag_8 > 0)::INTEGER +
        (gasto_lag_9 > 0)::INTEGER +
        (gasto_lag_10 > 0)::INTEGER +
        (gasto_lag_11 > 0)::INTEGER +
        (gasto_lag_12 > 0)::INTEGER;

UPDATE dataset_historico d
SET gasto_mediana_12m = q.mediana
FROM (
    SELECT client_id, mes,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY valor) AS mediana
    FROM dataset_historico d2
    CROSS JOIN LATERAL (VALUES
        (gasto_lag_1),(gasto_lag_2),(gasto_lag_3),
        (gasto_lag_4),(gasto_lag_5),(gasto_lag_6),
        (gasto_lag_7),(gasto_lag_8),(gasto_lag_9),
        (gasto_lag_10),(gasto_lag_11),(gasto_lag_12)
    ) x(valor)
    GROUP BY client_id, mes
) q
WHERE d.client_id = q.client_id
  AND d.mes = q.mes;


-- ============================================================
-- 7. DINÁMICA DEL GASTO
-- ============================================================

ALTER TABLE dataset_historico
ADD COLUMN cambio_1m DOUBLE PRECISION,
ADD COLUMN cambio_2m DOUBLE PRECISION,
ADD COLUMN ratio_lag1_media3 DOUBLE PRECISION,
ADD COLUMN cambio_12m DOUBLE PRECISION,
ADD COLUMN ratio_lag1_lag12 DOUBLE PRECISION,
ADD COLUMN diferencia_media3_media12 DOUBLE PRECISION,
ADD COLUMN peso_3m_sobre_12m DOUBLE PRECISION,
ADD COLUMN proporcion_meses_activos_3m_12m DOUBLE PRECISION;

UPDATE dataset_historico
SET
    cambio_1m = gasto_lag_1 - gasto_lag_2,
    cambio_2m = gasto_lag_1 - gasto_lag_3,

    ratio_lag1_media3 =
        CASE WHEN gasto_media_3m > 0
             THEN gasto_lag_1 / gasto_media_3m END,

    cambio_12m = gasto_lag_1 - gasto_lag_12,

    ratio_lag1_lag12 =
        CASE WHEN gasto_lag_12 > 0
             THEN gasto_lag_1 / gasto_lag_12 END,

    diferencia_media3_media12 =
        gasto_media_3m - gasto_media_12m,

    peso_3m_sobre_12m =
        CASE
            WHEN (
                gasto_lag_1 + gasto_lag_2 + gasto_lag_3 +
                gasto_lag_4 + gasto_lag_5 + gasto_lag_6 +
                gasto_lag_7 + gasto_lag_8 + gasto_lag_9 +
                gasto_lag_10 + gasto_lag_11 + gasto_lag_12
            ) > 0
            THEN (
                gasto_lag_1 + gasto_lag_2 + gasto_lag_3
            ) / (
                gasto_lag_1 + gasto_lag_2 + gasto_lag_3 +
                gasto_lag_4 + gasto_lag_5 + gasto_lag_6 +
                gasto_lag_7 + gasto_lag_8 + gasto_lag_9 +
                gasto_lag_10 + gasto_lag_11 + gasto_lag_12
            )
        END,

    proporcion_meses_activos_3m_12m =
        CASE WHEN num_meses_activos_12m > 0
             THEN (
                (gasto_lag_1 > 0)::INTEGER +
                (gasto_lag_2 > 0)::INTEGER +
                (gasto_lag_3 > 0)::INTEGER
             )::DOUBLE PRECISION / num_meses_activos_12m
             ELSE 0 END;


-- ============================================================
-- 8. SERVICIOS UTILIZADOS ANTES DEL MES OBJETIVO
-- ============================================================

ALTER TABLE dataset_historico
ADD COLUMN num_servicios INTEGER;

UPDATE dataset_historico d
SET num_servicios = q.num_servicios
FROM (
    SELECT d2.client_id, d2.mes,
           COUNT(DISTINCT p.sluzba) AS num_servicios
    FROM dataset_historico d2
    JOIN probehnuto p
      ON p.client_id = d2.client_id
     AND p.month_year_datum_transakce < d2.mes
     AND p.sluzba IS NOT NULL
    GROUP BY d2.client_id, d2.mes
) q
WHERE d.client_id = q.client_id
  AND d.mes = q.mes;

UPDATE dataset_historico
SET num_servicios = COALESCE(num_servicios, 0);


-- ============================================================
-- 9. GASTO POR SERVICIO DEL MES ANTERIOR
-- ============================================================

DROP TABLE IF EXISTS dataset_servicios;

CREATE TABLE dataset_servicios AS
SELECT
    d.*,

    COALESCE(s.gasto_servicio_1, 0) AS gasto_servicio_1,
    COALESCE(s.gasto_servicio_2, 0) AS gasto_servicio_2,
    COALESCE(s.gasto_servicio_3, 0) AS gasto_servicio_3,
    COALESCE(s.gasto_servicio_4, 0) AS gasto_servicio_4,
    COALESCE(s.gasto_servicio_5, 0) AS gasto_servicio_5,
    COALESCE(s.gasto_servicio_6, 0) AS gasto_servicio_6,
    COALESCE(s.gasto_servicio_7, 0) AS gasto_servicio_7,
    COALESCE(s.gasto_servicio_8, 0) AS gasto_servicio_8,
    COALESCE(s.gasto_servicio_9, 0) AS gasto_servicio_9

FROM dataset_historico d
LEFT JOIN gasto_servicio_mes s
  ON s.client_id = d.client_id
 AND s.mes = d.mes - INTERVAL '1 month';


-- ============================================================
-- 10. VARIABLES DE COMPOSICIÓN DE SERVICIOS
-- ============================================================

ALTER TABLE dataset_servicios
ADD COLUMN servicios_activos_lag1 INTEGER,
ADD COLUMN concentracion_servicios_lag1 DOUBLE PRECISION,
ADD COLUMN servicio_principal_share_lag1 DOUBLE PRECISION,

ADD COLUMN share_servicio_1 DOUBLE PRECISION,
ADD COLUMN share_servicio_2 DOUBLE PRECISION,
ADD COLUMN share_servicio_3 DOUBLE PRECISION,
ADD COLUMN share_servicio_4 DOUBLE PRECISION,
ADD COLUMN share_servicio_5 DOUBLE PRECISION,
ADD COLUMN share_servicio_6 DOUBLE PRECISION,
ADD COLUMN share_servicio_7 DOUBLE PRECISION,
ADD COLUMN share_servicio_8 DOUBLE PRECISION,
ADD COLUMN share_servicio_9 DOUBLE PRECISION;

UPDATE dataset_servicios
SET
    servicios_activos_lag1 =
        (gasto_servicio_1 > 0)::INTEGER +
        (gasto_servicio_2 > 0)::INTEGER +
        (gasto_servicio_3 > 0)::INTEGER +
        (gasto_servicio_4 > 0)::INTEGER +
        (gasto_servicio_5 > 0)::INTEGER +
        (gasto_servicio_6 > 0)::INTEGER +
        (gasto_servicio_7 > 0)::INTEGER +
        (gasto_servicio_8 > 0)::INTEGER +
        (gasto_servicio_9 > 0)::INTEGER,

    concentracion_servicios_lag1 =
        CASE WHEN gasto_lag_1 > 0 THEN
            POWER(gasto_servicio_1 / gasto_lag_1, 2) +
            POWER(gasto_servicio_2 / gasto_lag_1, 2) +
            POWER(gasto_servicio_3 / gasto_lag_1, 2) +
            POWER(gasto_servicio_4 / gasto_lag_1, 2) +
            POWER(gasto_servicio_5 / gasto_lag_1, 2) +
            POWER(gasto_servicio_6 / gasto_lag_1, 2) +
            POWER(gasto_servicio_7 / gasto_lag_1, 2) +
            POWER(gasto_servicio_8 / gasto_lag_1, 2) +
            POWER(gasto_servicio_9 / gasto_lag_1, 2)
        END,

    servicio_principal_share_lag1 =
        CASE WHEN gasto_lag_1 > 0 THEN
            GREATEST(
                gasto_servicio_1,gasto_servicio_2,gasto_servicio_3,
                gasto_servicio_4,gasto_servicio_5,gasto_servicio_6,
                gasto_servicio_7,gasto_servicio_8,gasto_servicio_9
            ) / gasto_lag_1
        END,

    share_servicio_1 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_1 / gasto_lag_1 END,
    share_servicio_2 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_2 / gasto_lag_1 END,
    share_servicio_3 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_3 / gasto_lag_1 END,
    share_servicio_4 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_4 / gasto_lag_1 END,
    share_servicio_5 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_5 / gasto_lag_1 END,
    share_servicio_6 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_6 / gasto_lag_1 END,
    share_servicio_7 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_7 / gasto_lag_1 END,
    share_servicio_8 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_8 / gasto_lag_1 END,
    share_servicio_9 = CASE WHEN gasto_lag_1 > 0 THEN gasto_servicio_9 / gasto_lag_1 END;


-- ============================================================
-- 11. AJUSTES NEGATIVOS DEL MES ANTERIOR
-- ============================================================

ALTER TABLE dataset_servicios
ADD COLUMN ajustes_negativos_lag1 DOUBLE PRECISION,
ADD COLUMN num_ajustes_negativos_lag1 INTEGER;

UPDATE dataset_servicios d
SET
    ajustes_negativos_lag1 = COALESCE(r.ajuste_negativo, 0),
    num_ajustes_negativos_lag1 = COALESCE(r.num_ajustes_negativos, 0)
FROM recarga_cliente_mes r
WHERE r.client_id = d.client_id
  AND r.mes = d.mes - INTERVAL '1 month';


-- ============================================================
-- 12. HISTORIAL DE RECARGAS 1-12 MESES
-- ============================================================

DROP TABLE IF EXISTS dataset_recargas;

CREATE TABLE dataset_recargas AS
SELECT
    d.*,

    COALESCE(r1.recarga_neta, 0) AS recarga_lag_1,
    COALESCE(r2.recarga_neta, 0) AS recarga_lag_2,
    COALESCE(r3.recarga_neta, 0) AS recarga_lag_3,
    COALESCE(r4.recarga_neta, 0) AS recarga_lag_4,
    COALESCE(r5.recarga_neta, 0) AS recarga_lag_5,
    COALESCE(r6.recarga_neta, 0) AS recarga_lag_6,
    COALESCE(r7.recarga_neta, 0) AS recarga_lag_7,
    COALESCE(r8.recarga_neta, 0) AS recarga_lag_8,
    COALESCE(r9.recarga_neta, 0) AS recarga_lag_9,
    COALESCE(r10.recarga_neta, 0) AS recarga_lag_10,
    COALESCE(r11.recarga_neta, 0) AS recarga_lag_11,
    COALESCE(r12.recarga_neta, 0) AS recarga_lag_12,

    COALESCE(r1.recarga_positiva, 0) AS recarga_positiva_lag1,
    COALESCE(r1.ajuste_negativo, 0) AS ajuste_negativo_lag1

FROM dataset_servicios d

LEFT JOIN recarga_cliente_mes r1 ON r1.client_id=d.client_id AND r1.mes=d.mes-INTERVAL '1 month'
LEFT JOIN recarga_cliente_mes r2 ON r2.client_id=d.client_id AND r2.mes=d.mes-INTERVAL '2 months'
LEFT JOIN recarga_cliente_mes r3 ON r3.client_id=d.client_id AND r3.mes=d.mes-INTERVAL '3 months'
LEFT JOIN recarga_cliente_mes r4 ON r4.client_id=d.client_id AND r4.mes=d.mes-INTERVAL '4 months'
LEFT JOIN recarga_cliente_mes r5 ON r5.client_id=d.client_id AND r5.mes=d.mes-INTERVAL '5 months'
LEFT JOIN recarga_cliente_mes r6 ON r6.client_id=d.client_id AND r6.mes=d.mes-INTERVAL '6 months'
LEFT JOIN recarga_cliente_mes r7 ON r7.client_id=d.client_id AND r7.mes=d.mes-INTERVAL '7 months'
LEFT JOIN recarga_cliente_mes r8 ON r8.client_id=d.client_id AND r8.mes=d.mes-INTERVAL '8 months'
LEFT JOIN recarga_cliente_mes r9 ON r9.client_id=d.client_id AND r9.mes=d.mes-INTERVAL '9 months'
LEFT JOIN recarga_cliente_mes r10 ON r10.client_id=d.client_id AND r10.mes=d.mes-INTERVAL '10 months'
LEFT JOIN recarga_cliente_mes r11 ON r11.client_id=d.client_id AND r11.mes=d.mes-INTERVAL '11 months'
LEFT JOIN recarga_cliente_mes r12 ON r12.client_id=d.client_id AND r12.mes=d.mes-INTERVAL '12 months';


-- ============================================================
-- 13. VARIABLES DE RECARGA Y DINÁMICA
-- ============================================================

ALTER TABLE dataset_recargas
ADD COLUMN recarga_media_3m DOUBLE PRECISION,
ADD COLUMN recarga_std_3m DOUBLE PRECISION,
ADD COLUMN recarga_media_12m DOUBLE PRECISION,
ADD COLUMN recarga_std_12m DOUBLE PRECISION,
ADD COLUMN recarga_total_12m DOUBLE PRECISION,
ADD COLUMN recarga_ultimos_3_meses DOUBLE PRECISION,
ADD COLUMN meses_recarga_positiva_12m INTEGER,
ADD COLUMN ajustes_negativos_12m DOUBLE PRECISION,
ADD COLUMN meses_con_ajuste_12m INTEGER,
ADD COLUMN cambio_recarga_1m DOUBLE PRECISION,
ADD COLUMN ratio_recarga_lag1_media3 DOUBLE PRECISION,
ADD COLUMN peso_recarga_3m_12m DOUBLE PRECISION,
ADD COLUMN proporcion_meses_recarga_3m_12m DOUBLE PRECISION;

UPDATE dataset_recargas
SET
    recarga_media_3m = (recarga_lag_1 + recarga_lag_2 + recarga_lag_3) / 3.0,

    recarga_std_3m = (
        SELECT STDDEV_SAMP(v)
        FROM (VALUES
            (recarga_lag_1),(recarga_lag_2),(recarga_lag_3)
        ) AS x(v)
    ),

    recarga_media_12m = (
        recarga_lag_1 + recarga_lag_2 + recarga_lag_3 +
        recarga_lag_4 + recarga_lag_5 + recarga_lag_6 +
        recarga_lag_7 + recarga_lag_8 + recarga_lag_9 +
        recarga_lag_10 + recarga_lag_11 + recarga_lag_12
    ) / 12.0,

    recarga_std_12m = (
        SELECT STDDEV_SAMP(v)
        FROM (VALUES
            (recarga_lag_1),(recarga_lag_2),(recarga_lag_3),
            (recarga_lag_4),(recarga_lag_5),(recarga_lag_6),
            (recarga_lag_7),(recarga_lag_8),(recarga_lag_9),
            (recarga_lag_10),(recarga_lag_11),(recarga_lag_12)
        ) AS x(v)
    ),

    recarga_total_12m =
        recarga_lag_1 + recarga_lag_2 + recarga_lag_3 +
        recarga_lag_4 + recarga_lag_5 + recarga_lag_6 +
        recarga_lag_7 + recarga_lag_8 + recarga_lag_9 +
        recarga_lag_10 + recarga_lag_11 + recarga_lag_12,

    recarga_ultimos_3_meses =
        recarga_lag_1 + recarga_lag_2 + recarga_lag_3,

    meses_recarga_positiva_12m =
        (recarga_lag_1 > 0)::INTEGER +
        (recarga_lag_2 > 0)::INTEGER +
        (recarga_lag_3 > 0)::INTEGER +
        (recarga_lag_4 > 0)::INTEGER +
        (recarga_lag_5 > 0)::INTEGER +
        (recarga_lag_6 > 0)::INTEGER +
        (recarga_lag_7 > 0)::INTEGER +
        (recarga_lag_8 > 0)::INTEGER +
        (recarga_lag_9 > 0)::INTEGER +
        (recarga_lag_10 > 0)::INTEGER +
        (recarga_lag_11 > 0)::INTEGER +
        (recarga_lag_12 > 0)::INTEGER,

    cambio_recarga_1m = recarga_lag_1 - recarga_lag_2,

    ratio_recarga_lag1_media3 =
        CASE
            WHEN (recarga_lag_1 + recarga_lag_2 + recarga_lag_3) / 3.0 <> 0
            THEN recarga_lag_1 /
                 ((recarga_lag_1 + recarga_lag_2 + recarga_lag_3) / 3.0)
        END,

    peso_recarga_3m_12m =
        CASE
            WHEN recarga_total_12m <> 0
            THEN (recarga_lag_1 + recarga_lag_2 + recarga_lag_3)
                 / recarga_total_12m
        END,

    proporcion_meses_recarga_3m_12m =
        CASE
            WHEN meses_recarga_positiva_12m > 0
            THEN (
                (recarga_lag_1 > 0)::INTEGER +
                (recarga_lag_2 > 0)::INTEGER +
                (recarga_lag_3 > 0)::INTEGER
            )::DOUBLE PRECISION / meses_recarga_positiva_12m
            ELSE 0
        END;


UPDATE dataset_recargas d
SET
    ajustes_negativos_12m = q.total_ajustes,
    meses_con_ajuste_12m = q.meses_ajuste
FROM (
    SELECT
        d2.client_id,
        d2.mes,
        SUM(COALESCE(r.ajuste_negativo, 0)) AS total_ajustes,
        COUNT(*) FILTER (
            WHERE COALESCE(r.ajuste_negativo, 0) > 0
        ) AS meses_ajuste
    FROM dataset_recargas d2
    LEFT JOIN recarga_cliente_mes r
      ON r.client_id = d2.client_id
     AND r.mes >= d2.mes - INTERVAL '12 months'
     AND r.mes < d2.mes
    GROUP BY d2.client_id, d2.mes
) q
WHERE d.client_id=q.client_id
  AND d.mes=q.mes;


-- ============================================================
-- 14. VARIABLES ESTACIONALES
-- ============================================================

ALTER TABLE dataset_recargas
ADD COLUMN mes_num INTEGER,
ADD COLUMN año INTEGER,
ADD COLUMN trimestre INTEGER,
ADD COLUMN mes_sin DOUBLE PRECISION,
ADD COLUMN mes_cos DOUBLE PRECISION;

UPDATE dataset_recargas
SET
    mes_num = EXTRACT(MONTH FROM mes)::INTEGER,
    año = EXTRACT(YEAR FROM mes)::INTEGER,
    trimestre = EXTRACT(QUARTER FROM mes)::INTEGER,
    mes_sin = SIN(2 * PI() * EXTRACT(MONTH FROM mes) / 12.0),
    mes_cos = COS(2 * PI() * EXTRACT(MONTH FROM mes) / 12.0);


-- ============================================================
-- 15. HISTORIAL COMPLETO DE 12 MESES
-- ============================================================

ALTER TABLE dataset_recargas
ADD COLUMN historial_12m_completo INTEGER;

UPDATE dataset_recargas
SET historial_12m_completo =
    CASE WHEN mes >= DATE '2013-08-01' THEN 1 ELSE 0 END;


-- ============================================================
-- 16. DATASET FINAL
-- ============================================================

DROP TABLE IF EXISTS dataset_modelo;

CREATE TABLE dataset_modelo AS
SELECT
    client_id AS id_cliente,
    mes,
    año,
    mes_num,
    trimestre,

    gasto_publicitario,

    gasto_lag_1 AS gasto_mes_anterior,
    gasto_lag_2,
    gasto_lag_3,
    gasto_lag_4,
    gasto_lag_5,
    gasto_lag_6,
    gasto_lag_7,
    gasto_lag_8,
    gasto_lag_9,
    gasto_lag_10,
    gasto_lag_11,
    gasto_lag_12,

    gasto_media_3m,
    gasto_media_6m,
    gasto_media_12m,
    gasto_mediana_12m,
    gasto_std_3m,
    gasto_std_6m,
    gasto_std_12m,
    gasto_max_12m,
    num_meses_activos_12m,
    historial_12m_completo,

    cambio_1m,
    cambio_2m,
    ratio_lag1_media3,
    cambio_12m,
    ratio_lag1_lag12,
    diferencia_media3_media12,
    peso_3m_sobre_12m,
    proporcion_meses_activos_3m_12m,

    gasto_servicio_1,
    gasto_servicio_2,
    gasto_servicio_3,
    gasto_servicio_4,
    gasto_servicio_5,
    gasto_servicio_6,
    gasto_servicio_7,
    gasto_servicio_8,
    gasto_servicio_9,

    servicios_activos_lag1,
    concentracion_servicios_lag1,
    servicio_principal_share_lag1,
    share_servicio_1,
    share_servicio_2,
    share_servicio_3,
    share_servicio_4,
    share_servicio_5,
    share_servicio_6,
    share_servicio_7,
    share_servicio_8,
    share_servicio_9,
    ajustes_negativos_lag1,
    num_ajustes_negativos_lag1,

    recarga_lag_1 AS recarga_mes_anterior,
    recarga_lag_2,
    recarga_lag_3,
    recarga_lag_4,
    recarga_lag_5,
    recarga_lag_6,
    recarga_lag_7,
    recarga_lag_8,
    recarga_lag_9,
    recarga_lag_10,
    recarga_lag_11,
    recarga_lag_12,

    recarga_positiva_lag1,
    ajuste_negativo_lag1,
    recarga_ultimos_3_meses,

    recarga_media_3m,
    recarga_std_3m,
    recarga_media_12m,
    recarga_std_12m,
    recarga_total_12m,

    meses_recarga_positiva_12m,
    ajustes_negativos_12m,
    meses_con_ajuste_12m,

    cambio_recarga_1m,
    ratio_recarga_lag1_media3,
    peso_recarga_3m_12m,
    proporcion_meses_recarga_3m_12m,

    num_servicios,
    mes_sin,
    mes_cos,
    region,
    sector

FROM dataset_recargas;


-- ============================================================
-- 17. FILTRADO Y DIVISIÓN TEMPORAL
-- ============================================================

DROP TABLE IF EXISTS dataset_modelo_completo;
CREATE TABLE dataset_modelo_completo AS
SELECT *
FROM dataset_modelo
WHERE historial_12m_completo = 1;

DROP TABLE IF EXISTS train;
DROP TABLE IF EXISTS test;

CREATE TABLE train AS
SELECT *
FROM dataset_modelo_completo
WHERE mes < DATE '2015-01-01';

CREATE TABLE test AS
SELECT *
FROM dataset_modelo_completo
WHERE mes >= DATE '2015-01-01';

CREATE INDEX idx_train_cliente_mes
ON train (id_cliente, mes);

CREATE INDEX idx_test_cliente_mes
ON test (id_cliente, mes);


-- ============================================================
-- 18. VALIDACIONES
-- ============================================================

SELECT
    'train' AS conjunto,
    COUNT(*) AS observaciones,
    COUNT(DISTINCT id_cliente) AS clientes,
    MIN(mes) AS fecha_minima,
    MAX(mes) AS fecha_maxima
FROM train
UNION ALL
SELECT
    'test',
    COUNT(*),
    COUNT(DISTINCT id_cliente),
    MIN(mes),
    MAX(mes)
FROM test;

SELECT
    COUNT(*) AS observaciones,
    COUNT(*) FILTER (WHERE gasto_publicitario IS NULL) AS nulos_objetivo,
    COUNT(*) FILTER (WHERE gasto_mes_anterior IS NULL) AS nulos_gasto_anterior,
    COUNT(*) FILTER (WHERE gasto_media_3m IS NULL) AS nulos_media_3m,
    COUNT(*) FILTER (WHERE recarga_mes_anterior IS NULL) AS nulos_recarga_anterior,
    COUNT(*) FILTER (WHERE num_servicios IS NULL) AS nulos_servicios,
    COUNT(*) FILTER (WHERE region IS NULL) AS nulos_region,
    COUNT(*) FILTER (WHERE sector IS NULL) AS nulos_sector
FROM train;

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'train'
ORDER BY ordinal_position;

