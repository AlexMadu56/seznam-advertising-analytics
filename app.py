from pathlib import Path
import numpy as np
import pandas as pd
import streamlit as st
import plotly.graph_objects as go
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error

# -----------------------------
# Page configuration
# -----------------------------
st.set_page_config(
    page_title="Seznam · Advertising Analytics",
    page_icon=None,
    layout="wide",
    initial_sidebar_state="collapsed",
)

# -----------------------------
# Visual system
# -----------------------------
st.markdown(
    """
    <style>
    :root {
        --paper: #FAFAF8;
        --ink: #202A33;
        --muted: #6B7480;
        --line: #DCE1E5;
        --blue: #7893A8;
        --blue-soft: #E8EEF2;
        --sage: #93A998;
        --sage-soft: #EAF0EB;
        --sand: #D7B889;
        --sand-soft: #F3EDE2;
        --white: #FFFFFF;
    }

    .stApp {
        background: var(--paper);
        color: var(--ink);
    }

    [data-testid="stHeader"] {
        background: transparent;
    }

    /* Hide the native collapsible sidebar entirely — filters now live in a
       fixed left column built with st.columns so they are always visible. */
    [data-testid="stSidebar"] {
        display: none;
    }

    .block-container {
        max-width: 1320px;
        padding-top: 2.2rem;
        padding-bottom: 3rem;
    }

    h1, h2, h3 {
        color: var(--ink);
        letter-spacing: -0.025em;
    }

    h1 {
        font-size: 2.2rem !important;
        line-height: 1.08 !important;
        font-weight: 650 !important;
        margin-bottom: .45rem !important;
    }

    h2 {
        font-size: 1.35rem !important;
        font-weight: 600 !important;
    }

    p, label, .stMarkdown {
        color: var(--ink);
    }

    .eyebrow {
        color: var(--muted);
        text-transform: uppercase;
        letter-spacing: .13em;
        font-size: .70rem;
        font-weight: 650;
        margin-bottom: .65rem;
    }

    .intro {
        max-width: 640px;
        color: var(--muted);
        font-size: .96rem;
        line-height: 1.6;
        margin-bottom: 1.5rem;
    }

    .metric-row {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1px;
        background: var(--line);
        border: 1px solid var(--line);
        margin: 1.1rem 0 1.8rem;
    }

    .metric {
        background: var(--white);
        padding: 1.25rem 1.25rem 1.15rem;
        min-height: 112px;
    }

    .metric.primary {
        background: var(--blue-soft);
    }

    .metric.secondary {
        background: var(--sage-soft);
    }

    .metric-label {
        color: var(--muted);
        font-size: .72rem;
        text-transform: uppercase;
        letter-spacing: .08em;
        margin-bottom: .55rem;
    }

    .metric-value {
        color: var(--ink);
        font-size: 1.72rem;
        line-height: 1;
        font-weight: 650;
        letter-spacing: -.035em;
    }

    .metric-sub {
        color: var(--muted);
        font-size: .75rem;
        margin-top: .42rem;
    }

    .section-note {
        color: var(--muted);
        font-size: .83rem;
        margin-top: -.35rem;
        margin-bottom: .8rem;
    }

    .info-strip {
        display: flex;
        gap: .5rem;
        flex-wrap: wrap;
        color: var(--muted);
        font-size: .78rem;
        margin: .3rem 0 1.1rem;
    }

    .pill {
        border: 1px solid var(--line);
        background: var(--white);
        padding: .32rem .58rem;
        border-radius: 999px;
    }

    .callout {
        border-left: 3px solid var(--sand);
        background: var(--sand-soft);
        padding: .85rem 1rem;
        color: var(--ink);
        font-size: .82rem;
        line-height: 1.5;
        margin-top: 1rem;
    }

    .footer {
        border-top: 1px solid var(--line);
        margin-top: 2.4rem;
        padding-top: 1rem;
        color: var(--muted);
        font-size: .72rem;
        line-height: 1.55;
    }

    /* ---------- Left filter panel ---------- */
    .filters-marker { display: none; }

    div[data-testid="column"]:has(.filters-marker) {
        background: #F5F5F1;
        border-right: 1px solid var(--line);
        padding: 1.6rem 1.15rem 2rem;
        min-height: calc(100vh - 2rem);
        border-radius: 2px;
    }

    div[data-testid="column"]:has(.filters-marker) [data-testid="stExpander"] {
        border: 1px solid var(--line);
        border-radius: 0;
        background: var(--white);
        margin-bottom: .55rem;
    }

    div[data-testid="column"]:has(.filters-marker) [data-testid="stExpander"] summary {
        font-weight: 600;
        font-size: .84rem;
    }

    .filters-title {
        color: var(--muted);
        text-transform: uppercase;
        letter-spacing: .13em;
        font-size: .70rem;
        font-weight: 650;
        margin-bottom: .3rem;
    }

    .filters-caption {
        color: var(--muted);
        font-size: .78rem;
        line-height: 1.45;
        margin-bottom: 1.3rem;
    }

    .filter-label {
        color: var(--ink);
        font-size: .82rem;
        font-weight: 650;
        margin-bottom: .35rem;
        margin-top: .2rem;
    }

    .period-readout {
        color: var(--muted);
        font-size: .76rem;
        margin-top: -.2rem;
        margin-bottom: 1.3rem;
    }

    div[data-testid="column"]:has(.filters-marker) hr {
        margin: 1.1rem 0;
        border-color: var(--line);
    }

    div[data-testid="stTabs"] button {
        font-weight: 550;
    }

    @media (max-width: 800px) {
        .metric-row {
            grid-template-columns: repeat(2, 1fr);
        }
        h1 {
            font-size: 1.7rem !important;
        }
    }

    @media (max-width: 480px) {
        .metric-row {
            grid-template-columns: 1fr;
        }
    }
    </style>
    """,
    unsafe_allow_html=True,
)

# -----------------------------
# Helpers
# -----------------------------
EUR_CZK = 24.313

MONTH_ES = {
    "Jan": "Ene", "Feb": "Feb", "Mar": "Mar", "Apr": "Abr",
    "May": "May", "Jun": "Jun", "Jul": "Jul", "Aug": "Ago",
    "Sep": "Sep", "Oct": "Oct", "Nov": "Nov", "Dec": "Dic",
}


def month_es(d):
    label = d.strftime("%b %Y")
    for en, es in MONTH_ES.items():
        label = label.replace(en, es)
    return label


def eur(czk):
    return czk / EUR_CZK


def fmt_eur(value):
    if pd.isna(value):
        return "—"
    return f"{value:,.0f} €".replace(",", ".")


def fmt_czk(value):
    if pd.isna(value):
        return "—"
    return f"{value:,.0f} Kč".replace(",", ".")


def fmt_number(value, decimals=0):
    if pd.isna(value):
        return "—"
    return f"{value:,.{decimals}f}".replace(",", "X").replace(".", ",").replace("X", ".")


def money_pair(czk, decimals=0):
    return f"{fmt_eur(eur(czk))} · {fmt_czk(czk)}"


def base_figure(height=450):
    fig = go.Figure()
    fig.update_layout(
        height=height,
        paper_bgcolor="#FAFAF8",
        plot_bgcolor="#FAFAF8",
        font=dict(family="Arial, sans-serif", color="#202A33"),
        margin=dict(l=10, r=10, t=35, b=10),
        hoverlabel=dict(
            bgcolor="#FFFFFF",
            bordercolor="#DCE1E5",
            font=dict(color="#202A33"),
        ),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="left",
            x=0,
        ),
    )
    fig.update_xaxes(
        showgrid=False,
        zeroline=False,
        linecolor="#DCE1E5",
        tickfont=dict(color="#6B7480", size=11),
    )
    fig.update_yaxes(
        showgrid=True,
        gridcolor="#E9ECEE",
        zeroline=False,
        linecolor="#DCE1E5",
        tickfont=dict(color="#6B7480", size=11),
    )
    return fig


def add_euro_kc_hover(fig, x, y, name, color, mode="lines"):
    fig.add_trace(
        go.Scatter(
            x=x,
            y=y,
            name=name,
            mode=mode,
            line=dict(color=color, width=2.4),
            hovertemplate="%{x}<br>%{y:,.0f} Kč<extra></extra>",
        )
    )


# -----------------------------
# Load data
# -----------------------------
DATA_PATH = Path(__file__).parent / "dashboard_final.csv"

if not DATA_PATH.exists():
    st.error(
        "No se encuentra `dashboard_final.csv`. Coloca el archivo en la misma carpeta que `app.py`."
    )
    st.stop()

try:
    df = pd.read_csv(DATA_PATH)
except Exception as exc:
    st.error(f"No se pudo leer `dashboard_final.csv`: {exc}")
    st.stop()

required = {"mes", "gasto_publicitario", "prediccion"}
missing = required - set(df.columns)
if missing:
    st.error(
        "Faltan columnas necesarias en `dashboard_final.csv`: "
        + ", ".join(sorted(missing))
    )
    st.stop()

df["mes"] = pd.to_datetime(df["mes"], errors="coerce")
df["gasto_publicitario"] = pd.to_numeric(df["gasto_publicitario"], errors="coerce")
df["prediccion"] = pd.to_numeric(df["prediccion"], errors="coerce")

df = df.dropna(subset=["mes", "gasto_publicitario", "prediccion"]).copy()

if df.empty:
    st.error("El archivo no contiene observaciones válidas después de limpiar fechas y valores.")
    st.stop()

df["error"] = df["gasto_publicitario"] - df["prediccion"]
df["error_absoluto"] = df["error"].abs()

# -----------------------------
# Month options (one discrete stop per calendar month — the slider can
# only land on a whole month, it never scrubs continuously)
# -----------------------------
min_month = df["mes"].min().to_period("M").to_timestamp()
max_month = df["mes"].max().to_period("M").to_timestamp()

available_months = pd.date_range(min_month, max_month, freq="MS")
month_labels = [month_es(d) for d in available_months]

# -----------------------------
# Layout: narrow fixed left column for filters + main content column
# -----------------------------
col_filters, col_main = st.columns([1, 4.1], gap="large")

with col_filters:
    st.markdown('<div class="filters-marker"></div>', unsafe_allow_html=True)
    st.markdown('<div class="filters-title">Filtros</div>', unsafe_allow_html=True)
    st.markdown(
        '<div class="filters-caption">Ajusta el periodo y los segmentos que quieres explorar.</div>',
        unsafe_allow_html=True,
    )

    st.markdown('<div class="filter-label">Periodo</div>', unsafe_allow_html=True)
    selected_range = st.select_slider(
        "Periodo de evaluación",
        options=range(len(available_months)),
        value=(0, len(available_months) - 1),
        format_func=lambda i: month_labels[i],
        label_visibility="collapsed",
    )
    start_date = available_months[selected_range[0]]
    end_date = available_months[selected_range[1]]
    st.markdown(
        f'<div class="period-readout">{month_labels[selected_range[0]]} — {month_labels[selected_range[1]]}</div>',
        unsafe_allow_html=True,
    )

    st.markdown("<hr>", unsafe_allow_html=True)

    with st.expander("Región", expanded=False):
        if "region" in df.columns:
            regions = sorted(df["region"].dropna().astype(str).unique().tolist())
            selected_regions = st.multiselect(
                "Seleccionar región",
                regions,
                placeholder="Todas",
                label_visibility="collapsed",
            )
        else:
            selected_regions = []

    with st.expander("Sector", expanded=False):
        if "sector" in df.columns:
            sectors = sorted(df["sector"].dropna().astype(str).unique().tolist())
            selected_sectors = st.multiselect(
                "Seleccionar sector",
                sectors,
                placeholder="Todos",
                label_visibility="collapsed",
            )
        else:
            selected_sectors = []

filtered = df[
    (df["mes"] >= start_date)
    & (df["mes"] <= end_date + pd.offsets.MonthEnd(1))
].copy()

if selected_regions:
    filtered = filtered[filtered["region"].astype(str).isin(selected_regions)]

if selected_sectors:
    filtered = filtered[filtered["sector"].astype(str).isin(selected_sectors)]

with col_main:
    if filtered.empty:
        st.warning("No hay observaciones para los filtros seleccionados.")
        st.stop()

    # -----------------------------
    # Header
    # -----------------------------
    st.markdown('<div class="eyebrow">Seznam · advertising analytics</div>', unsafe_allow_html=True)
    st.title("Predicción mensual del gasto publicitario")
    st.markdown(
        '<div class="intro">Modelo de Machine Learning para anticipar el gasto mensual de clientes a partir de su comportamiento histórico, evolución temporal, recargas y uso de servicios.</div>',
        unsafe_allow_html=True,
    )

    # -----------------------------
    # Dynamic metrics
    # -----------------------------
    r2 = r2_score(filtered["gasto_publicitario"], filtered["prediccion"])
    mae = mean_absolute_error(filtered["gasto_publicitario"], filtered["prediccion"])
    rmse = mean_squared_error(
        filtered["gasto_publicitario"],
        filtered["prediccion"],
    ) ** 0.5
    median_error = filtered["error_absoluto"].median()

    st.markdown(
        f"""
        <div class="metric-row">
            <div class="metric primary">
                <div class="metric-label">R²</div>
                <div class="metric-value">{r2:.3f}</div>
                <div class="metric-sub">varianza explicada</div>
            </div>
            <div class="metric secondary">
                <div class="metric-label">Error absoluto mediano</div>
                <div class="metric-value">{fmt_eur(eur(median_error))}</div>
                <div class="metric-sub">{fmt_czk(median_error)}</div>
            </div>
            <div class="metric">
                <div class="metric-label">MAE</div>
                <div class="metric-value">{fmt_eur(eur(mae))}</div>
                <div class="metric-sub">{fmt_czk(mae)}</div>
            </div>
            <div class="metric">
                <div class="metric-label">RMSE</div>
                <div class="metric-value">{fmt_eur(eur(rmse))}</div>
                <div class="metric-sub">{fmt_czk(rmse)}</div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        f"""
        <div class="info-strip">
            <span class="pill">{month_labels[selected_range[0]]} — {month_labels[selected_range[1]]}</span>
            <span class="pill">{len(filtered):,} observaciones</span>
        </div>
        """.replace(",", "."),
        unsafe_allow_html=True,
    )

    # -----------------------------
    # Tabs
    # -----------------------------
    tab_evolution, tab_precision, tab_behavior = st.tabs(
        ["Evolución", "Precisión", "Comportamiento"]
    )

    # -----------------------------
    # Evolution
    # -----------------------------
    with tab_evolution:
        st.markdown("## Evolución del gasto")
        st.markdown(
            '<div class="section-note">Gasto agregado observado frente a la predicción mensual.</div>',
            unsafe_allow_html=True,
        )

        monthly = (
            filtered.groupby(filtered["mes"].dt.to_period("M"))
            .agg(
                gasto_real=("gasto_publicitario", "sum"),
                gasto_predicho=("prediccion", "sum"),
                observaciones=("prediccion", "size"),
            )
            .reset_index()
        )
        monthly["mes"] = monthly["mes"].dt.to_timestamp()

        fig = base_figure(470)
        fig.add_trace(
            go.Scatter(
                x=monthly["mes"],
                y=monthly["gasto_real"],
                name="Real",
                mode="lines+markers",
                line=dict(color="#7893A8", width=2.6),
                marker=dict(size=6),
                hovertemplate="%{x|%b %Y}<br>Real: %{y:,.0f} Kč<extra></extra>",
            )
        )
        fig.add_trace(
            go.Scatter(
                x=monthly["mes"],
                y=monthly["gasto_predicho"],
                name="Predicción",
                mode="lines+markers",
                line=dict(color="#93A998", width=2.6),
                marker=dict(size=6),
                hovertemplate="%{x|%b %Y}<br>Predicción: %{y:,.0f} Kč<extra></extra>",
            )
        )
        fig.update_layout(
            yaxis_title="Gasto agregado",
            xaxis_title=None,
        )
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        c1, c2, c3 = st.columns(3)

        median_spend = filtered["gasto_publicitario"].median()
        total_real = filtered["gasto_publicitario"].sum()
        total_pred = filtered["prediccion"].sum()

        with c1:
            st.markdown(
                f"""
                <div class="metric">
                    <div class="metric-label">Gasto mensual mediano</div>
                    <div class="metric-value">{fmt_eur(eur(median_spend))}</div>
                    <div class="metric-sub">{fmt_czk(median_spend)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        with c2:
            st.markdown(
                f"""
                <div class="metric">
                    <div class="metric-label">Gasto observado acumulado</div>
                    <div class="metric-value">{fmt_eur(eur(total_real))}</div>
                    <div class="metric-sub">{fmt_czk(total_real)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        with c3:
            st.markdown(
                f"""
                <div class="metric">
                    <div class="metric-label">Gasto predicho acumulado</div>
                    <div class="metric-value">{fmt_eur(eur(total_pred))}</div>
                    <div class="metric-sub">{fmt_czk(total_pred)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

    # -----------------------------
    # Precision
    # -----------------------------
    with tab_precision:
        st.markdown("## Precisión")
        st.markdown(
            '<div class="section-note">La selección temporal y los filtros de la izquierda actualizan todas las métricas y visualizaciones.</div>',
            unsafe_allow_html=True,
        )

        p50 = filtered["error_absoluto"].quantile(0.50)
        p75 = filtered["error_absoluto"].quantile(0.75)
        p90 = filtered["error_absoluto"].quantile(0.90)

        p1, p2, p3 = st.columns(3)

        with p1:
            st.markdown(
                f"""
                <div class="metric secondary">
                    <div class="metric-label">Mediana</div>
                    <div class="metric-value">{fmt_eur(eur(p50))}</div>
                    <div class="metric-sub">{fmt_czk(p50)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        with p2:
            st.markdown(
                f"""
                <div class="metric">
                    <div class="metric-label">P75</div>
                    <div class="metric-value">{fmt_eur(eur(p75))}</div>
                    <div class="metric-sub">{fmt_czk(p75)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        with p3:
            st.markdown(
                f"""
                <div class="metric">
                    <div class="metric-label">P90</div>
                    <div class="metric-value">{fmt_eur(eur(p90))}</div>
                    <div class="metric-sub">{fmt_czk(p90)}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        st.markdown("### Real frente a predicción")

        scatter = filtered[["gasto_publicitario", "prediccion"]].copy()
        scatter = scatter[
            (scatter["gasto_publicitario"] > 0)
            & (scatter["prediccion"] > 0)
        ]

        fig = base_figure(500)

        fig.add_trace(
            go.Scatter(
                x=scatter["gasto_publicitario"],
                y=scatter["prediccion"],
                mode="markers",
                name="Observaciones",
                marker=dict(
                    color="#7893A8",
                    size=4.5,
                    opacity=0.24,
                ),
                hovertemplate=(
                    "Real: %{x:,.0f} Kč"
                    "<br>Predicción: %{y:,.0f} Kč"
                    "<extra></extra>"
                ),
            )
        )

        if not scatter.empty:
            low = min(scatter["gasto_publicitario"].min(), scatter["prediccion"].min())
            high = max(scatter["gasto_publicitario"].max(), scatter["prediccion"].max())
            fig.add_trace(
                go.Scatter(
                    x=[low, high],
                    y=[low, high],
                    mode="lines",
                    name="Referencia y=x",
                    line=dict(color="#D7B889", width=1.6, dash="dash"),
                    hoverinfo="skip",
                )
            )

        fig.update_xaxes(type="log", title="Gasto real (Kč)")
        fig.update_yaxes(type="log", title="Gasto predicho (Kč)")
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        st.markdown("### Distribución del error absoluto")
        error_p99 = filtered["error_absoluto"].quantile(0.99)
        visible_errors = filtered.loc[
            filtered["error_absoluto"] <= error_p99,
            "error_absoluto",
        ]

        fig = base_figure(380)
        fig.add_trace(
            go.Histogram(
                x=visible_errors,
                nbinsx=55,
                marker_color="#93A998",
                opacity=0.82,
                hovertemplate="%{x:,.0f} Kč<br>%{y:,} observaciones<extra></extra>",
            )
        )
        fig.update_xaxes(title="Error absoluto (Kč)")
        fig.update_yaxes(title="Observaciones")
        fig.update_layout(showlegend=False)
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        st.caption(
            "La distribución se visualiza hasta el P99 para mejorar la legibilidad; las métricas utilizan todas las observaciones."
        )

        monthly_error = (
            filtered.groupby(filtered["mes"].dt.to_period("M"))
            .agg(
                mae=("error_absoluto", "mean"),
                mediana=("error_absoluto", "median"),
            )
            .reset_index()
        )
        monthly_error["mes"] = monthly_error["mes"].dt.to_timestamp()

        st.markdown("### Error a lo largo del periodo")

        fig = base_figure(390)
        fig.add_trace(
            go.Scatter(
                x=monthly_error["mes"],
                y=monthly_error["mae"],
                name="MAE",
                mode="lines+markers",
                line=dict(color="#7893A8", width=2.2),
                marker=dict(size=5),
                hovertemplate="%{x|%b %Y}<br>MAE: %{y:,.0f} Kč<extra></extra>",
            )
        )
        fig.add_trace(
            go.Scatter(
                x=monthly_error["mes"],
                y=monthly_error["mediana"],
                name="Mediana",
                mode="lines+markers",
                line=dict(color="#93A998", width=2.2),
                marker=dict(size=5),
                hovertemplate="%{x|%b %Y}<br>Mediana: %{y:,.0f} Kč<extra></extra>",
            )
        )
        fig.update_yaxes(title="Error")
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

        st.markdown(
            '<div class="callout">Los errores más elevados se concentran principalmente en cambios bruscos del gasto mensual respecto al historial reciente. Estos casos se analizarán en una fase específica del análisis del error.</div>',
            unsafe_allow_html=True,
        )

    # -----------------------------
    # Behaviour
    # -----------------------------
    with tab_behavior:
        st.markdown("## Comportamiento")
        st.markdown(
            '<div class="section-note">Mediana del error absoluto según características del cliente.</div>',
            unsafe_allow_html=True,
        )

        col_region, col_sector = st.columns(2)

        if "region" in filtered.columns:
            region_stats = (
                filtered.assign(region=filtered["region"].fillna("Sin información").astype(str))
                .groupby("region")
                .agg(
                    error_mediano=("error_absoluto", "median"),
                    observaciones=("error_absoluto", "size"),
                )
                .reset_index()
            )
            region_stats = region_stats[region_stats["observaciones"] >= 100]
            region_stats = region_stats.sort_values("error_mediano", ascending=True)

            with col_region:
                st.markdown("### Por región")
                fig = base_figure(max(340, 38 * len(region_stats) + 80))
                fig.add_trace(
                    go.Bar(
                        x=region_stats["error_mediano"],
                        y=region_stats["region"],
                        orientation="h",
                        marker_color="#7893A8",
                        hovertemplate=(
                            "%{y}<br>Mediana: %{x:,.0f} Kč"
                            "<extra></extra>"
                        ),
                    )
                )
                fig.update_xaxes(title="Error absoluto mediano (Kč)")
                fig.update_yaxes(title=None)
                fig.update_layout(showlegend=False)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
        else:
            with col_region:
                st.info("No hay información de región en el archivo.")

        if "sector" in filtered.columns:
            sector_stats = (
                filtered.assign(sector=filtered["sector"].fillna("Sin información").astype(str))
                .groupby("sector")
                .agg(
                    error_mediano=("error_absoluto", "median"),
                    observaciones=("error_absoluto", "size"),
                )
                .reset_index()
            )
            sector_stats = sector_stats[sector_stats["observaciones"] >= 100]
            sector_stats = sector_stats.sort_values("error_mediano", ascending=True)

            with col_sector:
                st.markdown("### Por sector")
                fig = base_figure(max(340, 30 * min(len(sector_stats), 18) + 80))
                display_sector = sector_stats.head(18)

                fig.add_trace(
                    go.Bar(
                        x=display_sector["error_mediano"],
                        y=display_sector["sector"],
                        orientation="h",
                        marker_color="#93A998",
                        hovertemplate=(
                            "%{y}<br>Mediana: %{x:,.0f} Kč"
                            "<extra></extra>"
                        ),
                    )
                )
                fig.update_xaxes(title="Error absoluto mediano (Kč)")
                fig.update_yaxes(title=None)
                fig.update_layout(showlegend=False)
                st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
        else:
            with col_sector:
                st.info("No hay información de sector en el archivo.")

    # -----------------------------
    # Footer
    # -----------------------------
    st.markdown(
        """
        <div class="footer">
            Fuente: Seznam dataset · CTU Relational Learning Repository.<br>
            Evaluación temporal sobre la ventana seleccionada. Conversión utilizada: 1 € = 24,313 Kč.
        </div>
        """,
        unsafe_allow_html=True,
    )
