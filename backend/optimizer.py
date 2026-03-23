import config # Connection to global standards

def generate_architect_report(analysis, confidence, energy_rating):
    """
    Strategic Advisory Engine (Layer 4):
    Translates Technical ML Outputs into actionable Business Intelligence 
    for the 2026 German Photovoltaic Market.
    """
    report = []
    
    # Extract payback from the 'no_battery' scenario for baseline strategy
    # This ensures compatibility with the solar_engine output structure.
    base_payback = analysis['no_battery']['payback']
    system_capacity = analysis['capacity_kwp']
    
    # 1. Financial Investment Strategy
    # In 2026, direct purchase is the gold standard if ROI is under 10 years.
    # Higher confidence from ML ( > 92%) justifies immediate capital investment.
    if base_payback < 10 and confidence > 92:
        report.append("Strategy: 'Direktkauf' (Direct Purchase) is highly recommended. Fast ROI with low climatic risk.")
    elif base_payback < 14:
        report.append("Strategy: 'Miet-Solar' (Leasing) recommended to avoid high upfront costs while securing energy independence.")
    else:
        # For longer payback periods, state-subsidized loans are the best path.
        report.append("Strategy: 'KfW-Financing' - Utilize low-interest green loans (e.g., Program 270) to offset the longer payback period.")

    # 2. Smart Storage & Grid Integration (Customized for NRW Region)
    # Suggesting a battery only if the system has enough generation capacity.
    if system_capacity > 2.0:
        # Standard sizing: 1.1kWh of storage per 1kWp of solar (Ideal for Heat Pump buffering)
        recommended_battery = round(system_capacity * 1.1, 1)
        
        # Guardrails: Standard residential batteries in 2026 typically range from 5kWh to 15kWh.
        recommended_battery = max(5.0, min(recommended_battery, 15.0))
        
        report.append(f"Technical Alert: A {recommended_battery}kWh Battery is REQUIRED to reach >75% self-sufficiency in Bonn.")
    
    # 3. Building Synergy (Energy Rating Response)
    # Addressing thermal loss for lower-rated buildings.
    if energy_rating in ['E', 'F', 'G']:
        report.append("Critical Advice: Combine Solar with 'Fassadendämmung' (Insulation). PV alone won't fix high thermal loss.")
    elif energy_rating in ['A', 'B']:
        # High-efficiency homes are ideal for automated load management.
        report.append("Performance Note: Your high-efficiency building is perfect for a 'Smart Energy Manager' to automate EV charging.")

    # 4. Contractor & Market Matching
    # Selecting the best business model based on installation size and complexity.
    if system_capacity > 12.0:
        report.append("Installer Match: 'Enpal' - Specialized in large-scale residential deployments with full maintenance.")
    elif energy_rating in ['F', 'G']:
        report.append("Installer Match: 'Zolar' - Best for complex roof renovations and historical building integration.")
    else:
        # Local certified 'Meister' companies are often most cost-effective for standard jobs.
        report.append("Installer Match: 'Regional Bonn Meister' - Direct local craftmanship for maximum cost-efficiency.")

    # 5. Environmental & ESG Impact
    report.append(f"Environmental Impact: Projecting an annual offset of {analysis['co2_saved']} tons of CO2.")

    return report