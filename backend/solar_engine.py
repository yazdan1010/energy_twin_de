import numpy as np
from config import AVG_GRID_PRICE, FEED_IN_TARIFF, INSTALLATION_COST_PER_KW, PANEL_AREA_SQM

def calculate_architect_analysis(ml_annual_yield, num_panels, monthly_bill, energy_rating):
    """
    Final Financial Engine (Layer 4):
    Integrates AI-predicted yields with 2026 German economic and regulatory reality.
    Includes Dual-Scenario analysis (Standard vs. Battery Storage).
    """
    
    # 1. System Capacity (Modern 430W-450W Panels)
    panel_power_watt = 430 
    total_kwp = (num_panels * panel_power_watt) / 1000
    
    # 2. Total System Yield Calculation (CRITICAL FIX)
    total_system_area = num_panels * PANEL_AREA_SQM
    actual_annual_yield = ml_annual_yield * total_system_area
    
    # 3. Real-World Investment Cost (Germany 2026)
    # Scenario A: Standard
    total_investment = (total_kwp * INSTALLATION_COST_PER_KW) + 3500 
    
    # Scenario B: Battery Addition
    battery_cost = 5500 # Estimated cost for ~10kWh storage in 2026
    invest_battery = total_investment + battery_cost
    
    # 4. Consumption Profile (Annualized)
    annual_consumption_kwh = (monthly_bill / AVG_GRID_PRICE) * 12
    
    # 5. Self-Consumption Logic (Based on your Building Efficiency Rating)
    rating_efficiency_bonus = {
        'A': 0.45, 'B': 0.40, 'C': 0.35, 'D': 0.30, 
        'E': 0.25, 'F': 0.20, 'G': 0.15
    }
    sc_ratio = rating_efficiency_bonus.get(energy_rating, 0.30)
    
    # Battery SC Ratio: Significant jump in self-sufficiency
    sc_ratio_battery = 0.75 
    
    # 6. Energy Distribution & Financials (Dual Scenario)
    
    # --- SCENARIO: WITHOUT BATTERY (Original) ---
    annual_self_con_no = min(actual_annual_yield * sc_ratio, annual_consumption_kwh)
    annual_export_no = max(0, actual_annual_yield - annual_self_con_no)
    benefit_no = (annual_self_con_no * AVG_GRID_PRICE) + (annual_export_no * FEED_IN_TARIFF)
    net_benefit_no = benefit_no - (total_investment * 0.01) # 1% maintenance
    payback_no = total_investment / net_benefit_no if net_benefit_no > 0 else 0

    # --- SCENARIO: WITH BATTERY (Added) ---
    annual_self_con_yes = min(actual_annual_yield * sc_ratio_battery, annual_consumption_kwh)
    annual_export_yes = max(0, actual_annual_yield - annual_self_con_yes)
    benefit_yes = (annual_self_con_yes * AVG_GRID_PRICE) + (annual_export_yes * FEED_IN_TARIFF)
    net_benefit_yes = benefit_yes - (invest_battery * 0.015) # 1.5% maintenance
    payback_yes = invest_battery / net_benefit_yes if net_benefit_yes > 0 else 0
    
    # 7. CO2 Environmental Impact
    co2_saved_tons = (actual_annual_yield * 0.38) / 1000

    # Calculate Rates for clean dictionary output
    sc_rate_no = round((annual_self_con_no / actual_annual_yield) * 100, 1) if actual_annual_yield > 0 else 0
    sc_rate_yes = round((annual_self_con_yes / actual_annual_yield) * 100, 1) if actual_annual_yield > 0 else 0

    return {
        "yield": round(actual_annual_yield, 2),
        "num_panels": num_panels,
        "capacity_kwp": round(total_kwp, 2),
        "co2_saved": round(co2_saved_tons, 2),
        # Original Data Structure (for main report compatibility)
        "savings": round(net_benefit_no, 2),
        "payback": round(payback_no, 1),
        "invest": round(total_investment, 2),
        "self_consumption_rate": sc_rate_no,
        # Enhanced Data for Dashboard & Main (Key Fix applied here)
        "no_battery": {
            "payback": round(payback_no, 1),
            "invest": round(total_investment, 2),
            "savings": round(net_benefit_no, 2),
            "sc_rate": sc_rate_no  # Fixed Key
        },
        "with_battery": {
            "payback": round(payback_yes, 1),
            "invest": round(invest_battery, 2),
            "savings": round(net_benefit_yes, 2),
            "sc_rate": sc_rate_yes  # Fixed Key
        }
    }