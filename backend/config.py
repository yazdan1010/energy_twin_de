import os
from dotenv import load_dotenv

load_dotenv()

# --- API Keys & Tokens ---
# Updated to prioritize Mapbox for the new automated flow
MAPBOX_TOKEN = os.getenv("MAPBOX_TOKEN", "your_mapbox_token_here")
GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_KEY", "YOUR_KEY") # Keep as backup

# --- Physical PV Constants (2026 High-Efficiency Standards) ---
# Modern N-Type panels have better temperature coefficients
TEMP_COEFFICIENT = -0.0030    # Efficiency loss per degree Celsius (Improved for 2026)
SNOW_THRESHOLD = 0.5          # Modern panels shed snow faster (Threshold in cm)
SYSTEM_LOSSES = 0.12          # Better inverters and cabling (12% loss)

# --- Machine Learning & Data History ---
HISTORY_YEARS = 3                      # 3 years is the "Sweet Spot" for XGBoost
HISTORICAL_DATA_FILE = "solar_data.csv" # The main feature database

# --- CV & Panel Placement Constants (Mapbox Calibration) ---
# These must match the PIXELS_PER_METER in roof_analyser.py
MAP_ZOOM = 19                          # Mapbox optimal zoom for Bonn
PIXEL_TO_SQM_COEFF = 0.008264           # Calibrated for Zoom 11 Standard (1 / 11^2)

# --- Standard Panel Dimensions (Global Standard 2026) ---
# Standard 430W-450W Panel sizes
PANEL_WIDTH = 1.134           # Modern panel width (meters)
PANEL_HEIGHT = 1.722          # Modern panel height (meters)
PANEL_GAP = 0.02              # Standard mounting gap (meters)
PANEL_AREA_SQM = PANEL_WIDTH * PANEL_HEIGHT

# --- German Economic Data (Bonn / 2026 Market Averages) ---
# Prices in Germany have stabilized but remain high
AVG_GRID_PRICE = 0.42         # EUR per kWh (Average residential price in NRW)
FEED_IN_TARIFF = 0.078        # EEG Vergütung 2026 for systems < 10kWp
INSTALLATION_COST_PER_KW = 1450.0 # Average cost in Euro per kWp installed