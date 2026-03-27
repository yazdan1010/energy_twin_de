import os
import sys
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(base_dir)
# 2. Point Python directly inside your teammate's folder so 'import config' works magically
sys.path.append(os.path.join(base_dir, "solar_part_files"))
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import joblib
import pandas as pd

import math
from datetime import datetime, timedelta
import base64
import cv2
import numpy as np
from solar_part_files.data_fetcher import get_coordinates_from_address, fetch_satellite_image, fetch_historical_weather
from solar_part_files.roof_analyser import place_panels_on_roof, calculate_dynamic_scale

# --- TEAMMATE'S SOLAR MODULES ---
from solar_part_files.ml_engine import SasanSolarAI
from solar_part_files.solar_engine import calculate_architect_analysis
from solar_part_files.optimizer import generate_architect_report
from solar_part_files import config

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

        # B. Fetch Weather Forecast (Open-Meteo - 100% Reliable)
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
            
            # FIXED THE JSON PARSING BUG HERE!
            load_json = load_res.json()
            production_types = load_json.get('production_types', []) if isinstance(load_json, dict) else load_json
            
            raw_15min_load = next((item['data'] for item in production_types if item.get('name') in ['Load', 'Stromverbrauch', 'Gesamt (Netzlast)']), None)
            
            if raw_15min_load and len(raw_15min_load) >= 96:
                hourly_real_load = []
                for i in range(0, 96, 4):
                    chunk = [val for val in raw_15min_load[i:i+4] if val is not None]
                    hourly_real_load.append(sum(chunk) / len(chunk) if chunk else 50000)
            else:
                raise ValueError("Valid load data not found.")
        except Exception as e:
            print(f"⚠️ Load fallback triggered safely: {e}")
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
            yesterday_avg = 100.0 

        # E. Generate AI Predictions (NON-LINEAR PHYSICS)
        raw_predictions = []
        for hour in range(24):
            # 1. Solar Physics: Max grid capacity ~80,000 MW. Radiation max ~800 W/m2.
            # This multiplier ensures zero at night and massive spikes at noon.
            solar = min(80000, max(0, solar_rads[hour] * 100))
            
            # 2. Wind Physics: Power scales with the CUBE of wind speed (Velocity^3).
            # German cut-in speed is ~10km/h. Max capacity ~65,000 MW.
            speed = wind_speeds[hour]
            if speed < 10:
                wind_on = 0
            else:
                wind_on = min(65000, 65000 * ((speed - 10) / 20.0)**3)
            
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

            # Enforce column order
            df_hour = df_hour[['Electricity_Load', 'Generation_Solar', 'Generation_Wind_Onshore', 
                               'Generation_Wind_Offshore', 'Total_Renewable', 'Renewable_Ratio', 
                               'hour', 'day_of_week', 'month', 'is_weekend']]

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
        ai_res = requests.get(f'{request.host_url}predict_prices?target={target_day}')
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

# ==========================================
# 6A. STEP 1: FETCH SATELLITE IMAGE
# ==========================================
@app.route('/get_roof', methods=['POST'])
def get_roof():
    try:
        data = request.get_json()
        address = data.get('address', 'Bonn, Germany')
        
        # 1. Geocode
        lat, lon = get_coordinates_from_address(address, config.MAPBOX_TOKEN)
        if lat is None:
            return jsonify({"error": "Address not found."}), 404
            
        # 2. Fetch Image
        img_path = fetch_satellite_image(lat, lon, config.MAPBOX_TOKEN)
        if not img_path:
            return jsonify({"error": "Failed to fetch satellite imagery."}), 500
            
        # 3. Convert image to Base64 to send to Flutter
        with open(img_path, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
            
        return jsonify({
            "status": "success",
            "lat": lat,
            "lon": lon,
            "image_base64": encoded_string
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ==========================================
# 6B. STEP 2: SIMULATE SOLAR DASHBOARD
# ==========================================
@app.route('/simulate_solar', methods=['POST'])
def simulate_solar():
    try:
        data = request.get_json()
        
        # ==========================================
        # 1. EXACT PAYLOAD EXTRACTION (100% MATCH)
        # ==========================================
        address = data.get('address', '')
        energy_rating = data.get('energy_rating', 'D').upper()
        grid_price = float(data.get('grid_price_ct_kwh', 35.0))
        monthly_bill = float(data.get('monthly_bill_eur', 120.0))
        household_size = int(data.get('number_of_residents', 3))
        
        # ==========================================
        # 2. AUTO-GEOCODING (Address -> GPS)
        # ==========================================
        lat = data.get('lat')
        lon = data.get('lon')
        
        if not lat or not lon:
            # Safely get coordinates if Flutter only sent text
            geo_url = f"https://nominatim.openstreetmap.org/search?q={address}&format=json&limit=1"
            geo_res = requests.get(geo_url, headers={'User-Agent': 'EnergyTwin/1.0'}).json()
            if geo_res:
                lat = float(geo_res[0]['lat'])
                lon = float(geo_res[0]['lon'])
            else:
                return jsonify({"error": f"Address not found on map: {address}. Try adding the city."}), 400

        # ==========================================
        # 3. ROOF PROCESSING & OPENCV CRASH PREVENTION
        # ==========================================
        raw_points = data.get('roof_points', [])
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        img_path = os.path.join(base_dir, "solar_part_files", "assets", "roof_top.png")
        
        if raw_points:
            roof_contour = np.array([[int(p['x'] * 2), int(p['y'] * 2)] for p in raw_points], dtype=np.int32)
        else:
            # Fallback dynamic bounding box if no map points exist
            img = cv2.imread(img_path)
            if img is not None:
                h, w = img.shape[:2]
                padding = int(min(h, w) * 0.15)
                roof_contour = np.array([
                    [padding, padding], 
                    [w-padding, padding], 
                    [w-padding, h-padding], 
                    [padding, h-padding]
                ], dtype=np.int32)
            else:
                roof_contour = np.array([[50,50], [350,50], [350,350], [50,350]], dtype=np.int32)

        num_panels, final_img = place_panels_on_roof(img_path, roof_contour)
        
        if num_panels == 0:
            return jsonify({"error": "No clear roof detected. The property might be obscured by trees or lack high-res satellite data."}), 400

        _, buffer = cv2.imencode('.png', final_img)
        analyzed_image_base64 = base64.b64encode(buffer).decode('utf-8')

        # ==========================================
        # 4. ML & FINANCIAL ENGINES
        # ==========================================
        historical_df = fetch_historical_weather(lat, lon, years=config.HISTORY_YEARS)
        ai_advisor = SasanSolarAI(config.HISTORICAL_DATA_FILE) 
        X, y = ai_advisor.prepare_features(energy_rating, household_size)

        accuracy, r2 = ai_advisor.validate_model_performance(X, y)
        ml_predicted_yield = ai_advisor.final_prediction(X)

        # IMPORTANT: Make sure your teammate's function accepts 'grid_price_ct_kwh' if they updated it!
        # If their function does NOT take grid_price yet, just remove it from the arguments below.
        analysis = calculate_architect_analysis(
            ml_annual_yield=ml_predicted_yield, 
            num_panels=num_panels, 
            monthly_bill=monthly_bill, 
            energy_rating=energy_rating, 
            historical_df=historical_df,
            ai_accuracy_val=accuracy
            # grid_price_ct_kwh=grid_price  <-- UNCOMMENT THIS IF YOUR TEAMMATE ADDED IT TO THE FUNCTION
        )
        
        analysis["analyzed_image_base64"] = analyzed_image_base64

        return jsonify(analysis), 200

    except Exception as e:
        # This will send the exact Python crash log back to your Flutter app
        return jsonify({"error": f"Backend Crash: {str(e)}"}), 500
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)