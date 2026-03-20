from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import joblib
import pandas as pd
import os
import math
from datetime import datetime, timedelta

app = Flask(__name__)
# Enable CORS so the Flutter app can talk to Flask securely
CORS(app)

print("🧠 Waking up the EnergyTwin AI...")

# ==========================================
# 1. LOAD THE XGBOOST MODEL
# ==========================================
MODEL_PATH = "../models/xgboost_price_predictor_v1.joblib" 

try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    full_model_path = os.path.join(base_dir, MODEL_PATH)
    model = joblib.load(full_model_path)
    print("✅ XGBoost Model loaded successfully!")
except FileNotFoundError:
    print(f"⚠️ Warning: Model not found at {full_model_path}.")
    model = None

# ==========================================
# 2. HEALTH CHECK ENDPOINT
# ==========================================
@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "online", "message": "EnergyTwin DE Flask Backend is running!"}), 200

# ==========================================
# 3. COMPREHENSIVE INVESTMENT ADVISOR
# ==========================================
@app.route('/simulate_investment', methods=['POST'])
def simulate_investment():
    try:
        data = request.get_json()
        
        # User Inputs
        monthly_gas = float(data.get('monthly_gas_bill_eur', 150))
        house_size = float(data.get('house_size_sqm', 120))
        insulation = data.get('insulation_level', 'average') 
        
        yearly_gas_cost = monthly_gas * 12
        gas_price_kwh = 0.10
        yearly_gas_kwh = yearly_gas_cost / gas_price_kwh
        
        # Actual thermal heat needed (assuming old gas boiler is 85% efficient)
        actual_heat_demand_kwh = yearly_gas_kwh * 0.85 
        
        # Determine COP based on insulation quality
        if insulation == 'good':
            cop = 4.2
        elif insulation == 'average':
            cop = 3.5
        else: 
            cop = 2.8
            
        hp_electricity_kwh = actual_heat_demand_kwh / cop
        
        # Financial Math
        standard_elec_price = 0.30 # 30 ct/kWh
        smart_elec_price = 0.18    # 18 ct/kWh (AI optimized)
        
        dumb_hp_cost = hp_electricity_kwh * standard_elec_price
        smart_hp_cost = hp_electricity_kwh * smart_elec_price
        annual_savings = yearly_gas_cost - smart_hp_cost
        
        # Environmental Math (CO2 footprint)
        gas_co2_kg = yearly_gas_kwh * 0.20
        hp_co2_kg = hp_electricity_kwh * 0.35 
        co2_saved_kg = max(0, gas_co2_kg - hp_co2_kg)
        
        # ROI Math (Assuming €15,000 net cost)
        installation_cost = 15000 
        roi_years = installation_cost / annual_savings if annual_savings > 0 else 99
        
        return jsonify({
            "current_yearly_gas_cost_eur": round(yearly_gas_cost, 2),
            "smart_heatpump_cost_eur": round(smart_hp_cost, 2),
            "ai_annual_savings_eur": round(annual_savings, 2),
            "estimated_roi_years": round(roi_years, 1),
            "heat_demand_kwh": round(actual_heat_demand_kwh),
            "hp_electricity_kwh": round(hp_electricity_kwh),
            "cop_estimated": cop,
            "co2_saved_kg": round(co2_saved_kg),
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ==========================================
# 4. LIVE MARKET PREDICTOR (WITH CALIBRATION)
# ==========================================
@app.route('/predict_prices', methods=['GET'])
def predict_prices():
    try:
        if model is None:
            return jsonify({"error": "Model not loaded on server."}), 500

        target_day = request.args.get('target', 'today')

        # A. Determine Dates
        if target_day == 'tomorrow':
            start_idx, end_idx = 24, 48
            target_date = datetime.now() + timedelta(days=1)
        else:
            start_idx, end_idx = 0, 24
            target_date = datetime.now()

        month = target_date.month
        day_of_week = target_date.weekday()
        is_weekend = 1 if day_of_week >= 5 else 0

        # B. Fetch Weather (Open-Meteo)
        weather_url = "https://api.open-meteo.com/v1/forecast"
        weather_params = {
            "latitude": 50.1109,
            "longitude": 8.6821,
            "hourly": ["wind_speed_100m", "shortwave_radiation"],
            "timezone": "Europe/Berlin",
            "forecast_days": 2
        }
        weather_res = requests.get(weather_url, params=weather_params)
        weather_res.raise_for_status()
        weather_data = weather_res.json()

        wind_speeds = weather_data['hourly']['wind_speed_100m'][start_idx:end_idx]
        solar_rads = weather_data['hourly']['shortwave_radiation'][start_idx:end_idx]

        # C. Fetch 7-Day Persistence Grid Load (Fraunhofer ISE)
        historical_dt = target_date - timedelta(days=7)
        historical_str = historical_dt.strftime('%Y-%m-%d')
        
        try:
            load_url = f"https://api.energy-charts.info/public_power?bzn=DE-LU&start={historical_str}&end={historical_str}"
            load_res = requests.get(load_url)
            load_res.raise_for_status()
            
            raw_15min_load = next((item['data'] for item in load_res.json() if item['name'] in ['Load', 'Stromverbrauch', 'Gesamt (Netzlast)']), None)
            
            if raw_15min_load and len(raw_15min_load) >= 96:
                hourly_real_load = []
                for i in range(0, 96, 4):
                    chunk = [val for val in raw_15min_load[i:i+4] if val is not None]
                    hourly_real_load.append(sum(chunk) / len(chunk) if chunk else 50000)
            else:
                raise ValueError("Valid load data not found.")
        except Exception as e:
            print(f"⚠️ Load fallback triggered: {e}")
            hourly_real_load = [50000 + (10000 * math.sin(math.pi * (h - 6) / 12)) if 6 <= h <= 18 else 45000 for h in range(24)]

        # D. Fetch Yesterday's Market Average for Baseline Calibration
        try:
            yesterday_dt = target_date - timedelta(days=1)
            yesterday_str = yesterday_dt.strftime('%Y-%m-%d')
            price_url = f"https://api.energy-charts.info/price?bzn=DE-LU&start={yesterday_str}&end={yesterday_str}"
            price_res = requests.get(price_url)
            price_res.raise_for_status()
            yesterday_prices = price_res.json().get('price', [])
            yesterday_avg = sum(yesterday_prices) / len(yesterday_prices) if yesterday_prices else 100.0
        except Exception as e:
            print(f"⚠️ Calibration fallback triggered: {e}")
            yesterday_avg = 100.0 

        # E. Generate AI Predictions
        raw_predictions = []
        for hour in range(24):
            solar = max(0, solar_rads[hour] * 50) 
            wind_on = min(40000, max(0, (wind_speeds[hour] / 20.0) * 25000))
            wind_off = wind_on * 0.25 
            load = hourly_real_load[hour]
            
            total_renewable = solar + wind_on + wind_off
            renewable_ratio = total_renewable / load if load > 0 else 0

            df_hour = pd.DataFrame([{
                'Electricity_Load': load, 'Generation_Solar': solar, 'Generation_Wind_Onshore': wind_on,
                'Generation_Wind_Offshore': wind_off, 'Total_Renewable': total_renewable,
                'Renewable_Ratio': renewable_ratio, 'hour': hour, 'day_of_week': day_of_week,
                'month': month, 'is_weekend': is_weekend
            }])

            expected_cols = [
                'Electricity_Load', 'Generation_Solar', 'Generation_Wind_Onshore', 
                'Generation_Wind_Offshore', 'Total_Renewable', 'Renewable_Ratio', 
                'hour', 'day_of_week', 'month', 'is_weekend'
            ]
            df_hour = df_hour[expected_cols]

            price = float(model.predict(df_hour)[0])
            raw_predictions.append(price)

        # F. Apply Calibration Offset
        raw_avg = sum(raw_predictions) / len(raw_predictions)
        calibration_offset = yesterday_avg - raw_avg
        calibrated_predictions = [round(p + calibration_offset, 2) for p in raw_predictions]

        return jsonify({
            "date": target_date.strftime("%Y-%m-%d"),
            "hourly_prices": calibrated_predictions,
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ==========================================
# 5. AUTOMATED ACCURACY TRACKER
# ==========================================
@app.route('/benchmark', methods=['GET'])
def benchmark():
    try:
        # Default to checking 'today' since yesterday's API values are securely published
        target_day = request.args.get('target', 'today')
        
        if target_day == 'tomorrow':
            target_dt = datetime.now() + timedelta(days=1)
        else:
            target_dt = datetime.now()
            
        target_str = target_dt.strftime('%Y-%m-%d')
        
        # 1. Fetch REAL Prices
        fraunhofer_url = f"https://api.energy-charts.info/price?bzn=DE-LU&start={target_str}&end={target_str}"
        real_res = requests.get(fraunhofer_url)
        
        if real_res.status_code != 200:
             return jsonify({"error": f"Failed to fetch real EPEX prices for {target_str}."}), 404
             
        real_data = real_res.json()
        real_prices = real_data.get('price', [])
        
        if len(real_prices) < 24:
            return jsonify({"error": "Incomplete data from EPEX SPOT."}), 400
            
        real_prices = real_prices[:24] 
        
        max_price = max(real_prices)
        min_price = min(real_prices)
        avg_price = sum(real_prices) / len(real_prices)
        real_cheapest_hour = real_prices.index(min_price)
        
        # 2. Fetch AI Prices (Self-ping)
        ai_res = requests.get(f'http://127.0.0.1:5001/predict_prices?target={target_day}')
        ai_data = ai_res.json()
        ai_prices = ai_data.get('hourly_prices', [])
        
        if not ai_prices:
            return jsonify({"error": "AI prediction failed during benchmark."}), 500
            
        # 3. Calculate Performance Metrics
        errors = [abs(real - ai) for real, ai in zip(real_prices, ai_prices)]
        mae = sum(errors) / len(errors)
        
        ai_cheapest_hour = ai_prices.index(min(ai_prices))
        if real_cheapest_hour == ai_cheapest_hour:
            peak_accuracy = "100% Perfect Match! Heat Pump will turn on at the exact right time."
        else:
            peak_accuracy = f"Missed by {abs(real_cheapest_hour - ai_cheapest_hour)} hour(s)."

        return jsonify({
            "target_date": target_str,
            "real_market_stats": {
                "max_price_eur_mwh": round(max_price, 2),
                "min_price_eur_mwh": round(min_price, 2),
                "average_price_eur_mwh": round(avg_price, 2),
                "actual_cheapest_hour": f"{str(real_cheapest_hour).zfill(2)}:00",
                "raw_prices": real_prices
            },
            "ai_performance": {
                "mean_absolute_error_eur": round(mae, 2),
                "cheapest_hour_prediction": peak_accuracy,
                "ai_predicted_prices": ai_prices
            },
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)