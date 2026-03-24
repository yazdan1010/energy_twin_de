import requests
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import  config
import os

def get_coordinates_from_address(address, mapbox_token):
    """
    Geocoding Layer: Converts address to precise coordinates via Mapbox.
    """
    # Professional English comments: Mapbox API integration for DE region
    url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{address}.json"
    params = {
        "access_token": mapbox_token, 
        "limit": 1, 
        "country": "DE", 
        "types": "address,postcode,place"
    }
    
    try:
        response = requests.get(url, params=params, timeout=60)
        response.raise_for_status()
        data = response.json()
        if 'features' in data and data['features']:
            lon, lat = data['features'][0]['center']
            print(f"📍 Location Verified: [{lat}, {lon}]")
            return lat, lon
        print("⚠️ Address not found in Germany.")
        return None, None
    except Exception as e:
        print(f"❌ Geocoding Error: {e}")
        return None, None

def fetch_historical_weather(lat, lon, years=5):
    """
    Climate Intelligence Layer: Open-Meteo Archive API.
    Fetches 5 years of historical radiation data for precision ML training.
    """
    end_date = (datetime.now() - timedelta(days=2)).date()
    start_date = end_date - timedelta(days=years * 365)
    
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "hourly": "temperature_2m,shortwave_radiation,direct_radiation,diffuse_radiation,cloud_cover,snowfall",
        "timezone": "Europe/Berlin"
    }
    
    url = "https://archive-api.open-meteo.com/v1/archive"
    
    try:
        response = requests.get(url, params=params, timeout=20)
        response.raise_for_status()
        data = response.json()
        
        # Structure the data for solar_engine processing
        df = pd.DataFrame(data['hourly'])
        df['time'] = pd.to_datetime(df['time'])
        
        # Save to local cache for ML Engine and Solar Engine
        df.to_csv(config.HISTORICAL_DATA_FILE, index=False)
        print(f"✅ Weather Data Synchronized: {len(df)} hourly records cached.")
        return df
    except Exception as e:
        print(f"❌ Weather API Error: {e}")
        return None

def fetch_smard_prices():
    """
    Economic Intelligence Layer: SMARD (Bundesnetzagentur) API.
    Updates Grid Price and Feed-in Tariff based on real-time market trends.
    """
    print("📡 Connecting to SMARD Market Data...")
    try:
        # Get the latest available timestamp for DE Day-ahead prices
        index_url = "https://www.smard.de/app/chart_data/4169/DE/index_hour.json"
        ts_res = requests.get(index_url, timeout=10)
        ts_res.raise_for_status()
        last_ts = ts_res.json()['timestamps'][-1]
        
        # Fetch the hourly series for the current period
        price_url = f"https://www.smard.de/app/chart_data/4169/DE/4169_DE_hour_{last_ts}.json"
        series = requests.get(price_url, timeout=10).json()['series']
        
        # Technical Fix: Extract values and filter out Nones
        recent_prices = [float(val[1]) for val in series[-720:] if val[1] is not None]
        
        if not recent_prices:
            raise ValueError("Empty price series from SMARD")
            
        # Calculate the 30-day average market price (per MWh)
        avg_market_price_mwh = np.mean(recent_prices)
        
        # Standard Grid Price calculation: Market + Grid Fees + Taxes (approx 0.185€ in DE)
        config.AVG_GRID_PRICE = round((avg_market_price_mwh / 1000) + 0.22, 3) 
        
        # Dynamic Feed-in Tariff based on EEG 2026 standards
        config.FEED_IN_TARIFF = 0.082 if config.AVG_GRID_PRICE > 0.40 else 0.075
        
        print(f"✅ Market Indices Updated: Grid @ {config.AVG_GRID_PRICE}€ | Feed-in @ {config.FEED_IN_TARIFF}€")
        return True
    except Exception as e:
        print(f"⚠️ SMARD Sync Warning: {e}. Utilizing Config Defaults.")
        return False

def fetch_satellite_image(lat, lon, mapbox_token):
    """
    Spatial Layer: Mapbox Static Satellite API.
    Captures high-res roof imagery for the AI Roof Analyser.
    """
    url = f"https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/{lon},{lat},19,0/800x800?access_token={mapbox_token}"
    
    # PRODUCTION FIX: Absolute pathing + Auto folder creation
    base_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(base_dir, "assets")
    
    # This safely creates the folder if it doesn't exist, preventing the Errno 2 crash!
    os.makedirs(assets_dir, exist_ok=True) 
    
    filename = os.path.join(assets_dir, "roof_top.png")
    
    try:
        # Pre-cleanup: Ensure fresh imagery for each session
        if os.path.exists(filename):
            os.remove(filename)
        
        # Fetch high-fidelity satellite tile
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        
        with open(filename, "wb") as f:
            f.write(response.content)
            
        print(f"✅ Satellite Frame Captured: {filename}")
        return filename
    except Exception as e:
        print(f"❌ Imagery Retrieval Failed: {e}")
        return None