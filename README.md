# Quarterly expenditure: trend and seasonal decomposition in R

## Question and input

How do long-term trend and quarterly seasonality appear in the supplied expenditure
series? `Timeseries.csv` contains 284 ordered quarterly observations with `Year`,
`Quarter` and positive `Expenditure`. The original external dataset attribution is
not recorded here; confirm provenance before redistributing it beyond this project.
This is expenditure data, not verified operational demand or inventory performance.

## Methods demonstrated

- CSV/schema validation and log transformation
- Quadratic regression of log expenditure against time
- Centered five-quarter moving-average smoothing
- Multiplicative quarterly seasonal decomposition
- Trend and decomposition visualization

There is no Random Forest, held-out forecast, forecast-accuracy comparison or claim
of measured operational improvement. Existing historical images are not treated as
proof of output from the current script.

## Reproduce

Use a current R 4.x installation. From the repository root:

```bash
Rscript -e "install.packages(c('ggplot2', 'dplyr', 'zoo'), repos='https://cloud.r-project.org')"
Rscript forecast_model.R
```

The script fails on missing/invalid columns, nonpositive expenditure or nonconsecutive
quarters. It writes `outputs/log_trend.png`, `outputs/decomposition.png`,
`outputs/analysis.csv`, `outputs/seasonality.csv` and `outputs/sessionInfo.txt`.
The saved session information records package versions for a run; no lockfile or
cross-version reproducibility guarantee is implied.
