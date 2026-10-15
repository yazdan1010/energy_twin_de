import numpy as np
import pandas as pd
import config 
from optimizer import generate_architect_report, generate_advice_items

def calculate_architect_analysis(ml_annual_yield, num_panels, monthly_bill, energy_rating, historical_df, ai_accuracy_val):
    """
    Comprehensive Financial Engine: No lines removed, strictly adding new strategic metrics.
    """
    
    # 1. System Capacity (Physical specifications)
    panel_power_watt = getattr(config, 'WATT_PER_PANEL', 440) 
    total_kwp = (num_panels * panel_power_watt) / 1000
    
    # 2. Total System Yield Calculation
    total_system_area = num_panels * config.PANEL_AREA_SQM
    actual_annual_yield = ml_annual_yield * total_system_area
    
    # --- DYNAMIC MONTHLY DISTRIBUTION ---
    if 'time' in historical_df.columns:
        historical_df['time'] = pd.to_datetime(historical_df['time'])
        historical_df['month'] = historical_df['time'].dt.month
        
        monthly_distribution = historical_df.groupby('month')['shortwave_radiation'].sum() 
        total_energy_sum = monthly_distribution.sum()
        
        dynamic_weights = (monthly_distribution / total_energy_sum).to_list()
        monthly_yields = [round(actual_annual_yield * w, 2) for w in dynamic_weights]
        
        # Strategic Metric: Location/Climate Stability Score
        location_score = round((1 - (monthly_distribution.std() / monthly_distribution.mean())) * 100, 1)
    else:
        monthly_yields = [round(actual_annual_yield / 12, 2)] * 12
        location_score = 75.0

    # Seasonal Aggregation
    seasonal_data = {
        "Winter": round(monthly_yields[0] + monthly_yields[1] + monthly_yields[11], 2),
        "Spring": round(sum(monthly_yields[2:5]), 2),
        "Summer": round(sum(monthly_yields[5:8]), 2),
        "Autumn": round(sum(monthly_yields[8:11]), 2)
    }

    # 3. Dynamic Investment Logic
    total_investment = (total_kwp * config.INSTALLATION_COST_PER_KW) + 3500 
    invest_battery = total_investment + config.BATTERY_UPGRADE_COST
    
    # 4. Consumption Profile (YOUR REQUESTED LINES)
    current_grid_price = config.AVG_GRID_PRICE if config.AVG_GRID_PRICE > 0 else 0.42
    annual_consumption_kwh = (monthly_bill / current_grid_price) * 12
    
    # 5. Self-Consumption Ratios
    rating_efficiency_bonus = {
        'A': 0.45, 'B': 0.40, 'C': 0.35, 'D': 0.30, 
        'E': 0.25, 'F': 0.20, 'G': 0.15
    }
    sc_ratio = rating_efficiency_bonus.get(energy_rating, 0.30)
    sc_ratio_battery = 0.80 
    
    # 6. Financial Scenario Analysis (YOUR REQUESTED LOGIC)
    # Scenario A: Grid-Tied (No Battery)
    annual_self_con_no = min(actual_annual_yield * sc_ratio, annual_consumption_kwh)
    annual_export_no = max(0, actual_annual_yield - annual_self_con_no)
    benefit_no = (annual_self_con_no * current_grid_price) + (annual_export_no * config.FEED_IN_TARIFF)
    net_benefit_no = benefit_no - (total_investment * config.MAINTENANCE_RATE_STD)
    payback_no = total_investment / net_benefit_no if net_benefit_no > 0 else 25

    # Scenario B: Autarky-Focused (With Battery)
    annual_self_con_yes = min(actual_annual_yield * sc_ratio_battery, annual_consumption_kwh)
    annual_export_yes = max(0, actual_annual_yield - annual_self_con_yes)
    benefit_yes = (annual_self_con_yes * current_grid_price) + (annual_export_yes * config.FEED_IN_TARIFF)
    net_benefit_yes = benefit_yes - (invest_battery * config.MAINTENANCE_RATE_BATT)
    payback_yes = invest_battery / net_benefit_yes if net_benefit_yes > 0 else 25
    
    # 7. NEW STRATEGIC KPI CALCULATIONS (For the 3 New Boxes)
    twenty_year_profit = (net_benefit_yes * 20) * 0.85 # Net after 15% estimated lifecycle costs
    autarky_rate = round((annual_self_con_yes / annual_consumption_kwh) * 100, 1)
    co2_saved_tons = (actual_annual_yield * 0.385) / 1000
    tree_count = int((co2_saved_tons * 1000) / 21)

    # --- FINAL PACKAGING ---
    analysis_results = {
        "yield": round(actual_annual_yield, 2),
        "num_panels": num_panels,
        "capacity_kwp": round(total_kwp, 2),
        "co2_saved": round(co2_saved_tons, 2),
        "monthly_yield": monthly_yields,
        "seasonal_data": seasonal_data,
        "ai_accuracy": round(ai_accuracy_val, 1),
        "roof_area": round(total_system_area, 1),
        
        # New Structured Data for 3-Box Dashboard Layout
        "financials": {
            "annual_savings": round(net_benefit_yes, 2),
            "monthly_relief": round(net_benefit_yes / 12, 2),
            "twenty_year_profit": round(twenty_year_profit, 2),
            "payback": round(payback_yes, 1)
        },
        "strategy": {
            "autarky_rate": min(autarky_rate, 100.0),
            "location_score": location_score,
            "battery_impact": 80.0, # Expected performance during night
            "financing_recommendation": "Financing Recommended" if payback_yes < 12 else "Leasing Recommended",
            "energy_coverage": round((actual_annual_yield / annual_consumption_kwh) * 100, 1)
        },
        "environment": {
            "co2_saved": round(co2_saved_tons, 2),
            "tree_count": tree_count,
            "eco_grade": "Climate Hero" if co2_saved_tons > 4 else "Eco-Warrior"
        },
        
        # Backwards Compatibility (No Battery data)
        "no_battery": {
            "payback": round(payback_no, 1),
            "invest": round(total_investment, 2),
            "annual_savings": round(net_benefit_no, 2),
            "sc_rate": round((annual_self_con_no / actual_annual_yield) * 100, 1) if actual_annual_yield > 0 else 0
        },
        "with_battery": {
            "payback": round(payback_yes, 1),
            "invest": round(invest_battery, 2),
            "annual_savings": round(net_benefit_yes, 2),
            "sc_rate": round((annual_self_con_yes / actual_annual_yield) * 100, 1) if actual_annual_yield > 0 else 0
        }
    }

    # Trigger Strategic Advice Report
    analysis_results["strategic_advice"] = generate_architect_report(
        analysis_results, confidence=95.0, energy_rating=energy_rating
    )
    analysis_results["advice_items"] = generate_advice_items(analysis_results, energy_rating=energy_rating)

    return analysis_results