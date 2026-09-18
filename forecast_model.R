# ==============================================================================
# Quarterly Expenditure Trend and Seasonal Decomposition
# Author: Kaiyi (Janice) Liu
# Target Application: Supply Chain Demand Planning & Inventory Optimization
# ==============================================================================

# 1. ENVIRONMENT SETUP & LIBRARY LOADING
# ------------------------------------------------------------------------------
# Load essential packages for data manipulation and visualization
library(ggplot2)
library(dplyr)
library(zoo)      # For rolling averages


# 2. DATA INGESTION & PREPROCESSING
# ------------------------------------------------------------------------------
# Load historical demand/macroeconomic data
# Run from repository root; input is the committed quarterly expenditure CSV.
raw_data <- read.csv("Timeseries.csv")
required <- c("Year", "Quarter", "Expenditure")
if (!all(required %in% names(raw_data))) stop("Expected Year, Quarter, Expenditure columns")
if (anyNA(raw_data[required])) stop("Input contains missing values")
if (!all(vapply(raw_data[required], is.numeric, logical(1)))) stop("Input columns must be numeric")
if (any(!is.finite(as.matrix(raw_data[required])))) stop("Input contains non-finite values")
if (any(raw_data$Expenditure <= 0)) stop("Expenditure must be positive for log analysis")
if (any(!raw_data$Quarter %in% 1:4)) stop("Quarter must be 1 to 4")
if (any(diff(raw_data$Year * 4 + raw_data$Quarter) != 1)) stop("Rows must be consecutive quarters in order")
raw_data$Value <- raw_data$Expenditure
dir.create("outputs", showWarnings = FALSE)

# Clean and structure the dataset
demand_data <- raw_data %>%
  # Assuming standard column names; adjust as necessary based on raw data
  # Select relevant columns and handle missing values
  na.omit() %>%
  mutate(
    # Create a sequential time index for modeling
    Time_Index = row_number(),
    Time_Squared = Time_Index^2,
    # Log-scale transformation to analyze annualized growth rates
    Log_Value = log(Value) 
  )

# 3. LONG-TERM TREND MODELING (QUADRATIC FIT)
# ------------------------------------------------------------------------------
# Fit a quadratic regression model to capture non-linear baseline growth
# Equation: y = B0 + B1*t + B2*t^2
quad_model <- lm(Log_Value ~ Time_Index + Time_Squared, data = demand_data)

# Append predicted baseline trend to the dataset
demand_data$Baseline_Trend <- predict(quad_model)

# 4. CYCLICAL FLUCTUATIONS (MOVING AVERAGE)
# ------------------------------------------------------------------------------
# Isolate macroeconomic cycles to prevent bullwhip effect in inventory
# Using an Order-5 Moving Average to smooth out short-term noise
demand_data$Cyclical_MA5 <- rollmean(demand_data$Log_Value, 
                                     k = 5, 
                                     fill = NA, 
                                     align = "center")

# 5. SEASONALITY EXTRACTION
# ------------------------------------------------------------------------------
# Convert raw values into a formal Time-Series (ts) object (Quarterly Frequency)
ts_demand <- ts(demand_data$Value, start = c(raw_data$Year[1], raw_data$Quarter[1]), frequency = 4)

# Decompose the time series to extract the exact seasonal coefficients
decomposed_ts <- decompose(ts_demand, type = "multiplicative")

# Extract seasonal indices (Used for adjusting quarterly safety stock)
seasonality_factors <- decomposed_ts$figure
print("Quarterly Seasonality Indices for Inventory Adjustment:")
print(seasonality_factors)

# 6. DATA VISUALIZATION (EXECUTIVE REPORTING)
# ------------------------------------------------------------------------------
# Plot 1: Actual Demand vs. Quadratic Baseline Trend
trend_plot <- ggplot(demand_data, aes(x = Time_Index)) +
  geom_line(aes(y = Log_Value, color = "Actual Log-Demand"), size = 1) +
  geom_line(aes(y = Baseline_Trend, color = "Quadratic Trend"), size = 1.2, linetype = "dashed") +
  labs(title = "Long-Term Demand Trend Analysis",
       x = "Time (Quarters)",
       y = "Log(Demand Volume)",
       color = "Legend") +
  theme_minimal()

# ==============================================================================
# END OF SCRIPT
# ==============================================================================

ggsave("outputs/log_trend.png", trend_plot, width = 9, height = 5)
png("outputs/decomposition.png", width = 1000, height = 800)
plot(decomposed_ts)
dev.off()
write.csv(demand_data, "outputs/analysis.csv", row.names = FALSE)
write.csv(data.frame(Quarter = 1:4, Seasonal_Factor = seasonality_factors), "outputs/seasonality.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "outputs/sessionInfo.txt")
