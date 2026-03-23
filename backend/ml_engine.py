import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score

class SasanSolarAI:
    def __init__(self, csv_path="solar_data.csv"):
        self.csv_path = csv_path
        # Optimized XGBoost parameters for 2026 High-Resolution Weather Data
        # max_depth=6 is ideal for preventing overfitting with these features
        self.model = xgb.XGBRegressor(
            n_estimators=500,        
            learning_rate=0.03,      
            max_depth=6,             
            subsample=0.8,           
            colsample_bytree=0.8,    
            objective='reg:squarederror',
            random_state=42
        )

    def prepare_features(self, energy_rating, household_size):
        """Processes historical weather and building data into ML features."""
        df = pd.read_csv(self.csv_path)
        
        # Mapping Energy Rating A-G to numerical 1-7
        rating_map = {chr(65+i): i+1 for i in range(7)} 
        rating_val = rating_map.get(energy_rating, 4)

        # Feature selection including Cloud Cover
        features = ['shortwave_radiation', 'temperature_2m', 'snowfall', 'cloud_cover']
        X = df[features].copy()
        
        # --- ADDING SEASONALITY FEATURE ---
        # Helps the model understand the sun's angle difference between Dec and June
        # Calculation: (Row index // hours in a day // approx days in month) % 12
        X['month'] = (np.arange(len(df)) // (24 * 30)) % 12
        
        X.loc[:, 'energy_rating'] = rating_val
        X.loc[:, 'household_size'] = household_size
        
        # Yield Simulation (The Target 'y')
        # Using 0.21 (21% Efficiency) for modern 2026 N-Type solar panels
        y = (X['shortwave_radiation'] * 0.001 * 0.21) * (1 - (X['temperature_2m'] - 25).clip(0) * 0.0035)
        
        # Impact of Cloud Cover on scattering losses (15% reduction factor)
        y = y * (1 - (X['cloud_cover'] / 100) * 0.15)
        
        # Snow accumulation logic (Zero output if snowfall exceeds 0.5cm)
        y = y.mask(X['snowfall'] > 0.5, 0)
        
        return X, y

    def validate_model_performance(self, X, y):
        """Performs Backtesting on 20% of unseen historical data."""
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Training the XGBoost engine
        self.model.fit(X_train, y_train)
        
        # Performance Evaluation
        predictions = self.model.predict(X_test)
        mae = mean_absolute_error(y_test, predictions)
        r2 = r2_score(y_test, predictions)
        
        # Calculate accuracy relative to the mean yield
        accuracy = (1 - (mae / (y_test.mean() + 1e-6))) * 100
        return round(max(0, accuracy), 2), round(r2, 4)

    def final_prediction(self, X):
        """Forecasts the long-term annual average yield per square meter."""
        # Sum of hourly predictions divided by 3 (years) for a standardized annual forecast
        return self.model.predict(X).sum() / 3