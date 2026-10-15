import config # Connection to real-time market indices and regional costs

def generate_architect_report(analysis, confidence=95.0, energy_rating='D'):
    """
    Strategic Advisory Engine: 
    Converts ML data into honest, professional, and clear English insights.
    Focuses on: Financial Transparency, Grid Independence, and Environmental Impact.
    """
    report = []
    
    # --- 1. FINANCIAL STRATEGY (ROI & Wealth Analysis) ---
    financials = analysis.get('financials', {})
    payback = financials.get('payback', 15)
    profit_20y = financials.get('twenty_year_profit', 0)
    
    # Logic: Recommendation based on long-term net profit and payback speed
    if payback < 10:
        report.append(f"Financial Strategy: 'Direct Purchase' highly recommended. With a €{profit_20y:,.0f} net profit over 20 years, this is your property's best asset.")
    elif payback < 13:
        report.append(f"Financial Strategy: 'Financing Model'. Your annual savings exceed loan installments, allowing the system to pay for itself.")
    else:
        report.append("Financial Strategy: 'Solar-Lease'. To mitigate initial risks and enjoy full maintenance coverage, an OpEx model is more efficient for your profile.")

    # --- 2. GRID INDEPENDENCE (Autarky Logic) ---
    strategy = analysis.get('strategy', {})
    autarky = strategy.get('autarky_rate', 0)
    
    # Logic: Personalized insight for the 15-resident household energy profile
    if autarky > 80:
        report.append(f"Energy Independence: Outstanding! You will achieve {autarky}% independence from the grid, creating a solid hedge against German electricity inflation.")
    else:
        report.append(f"Consumption Audit: Due to high occupancy (15 residents), your autarky is {autarky}%. We recommend shifting heavy appliance usage to peak sun hours (11:00-15:00).")

    # --- 3. INFRASTRUCTURE & CLIMATE (The Honesty Factor) ---
    location_score = strategy.get('location_score', 75)
    
    # Logic: Honest assessment of building efficiency vs PV performance
    if energy_rating in ['E', 'F', 'G']:
        report.append(f"Infrastructure Upgrade: Your building's energy rating ({energy_rating}) is low. Attic insulation is recommended to boost your Solar ROI by an estimated 8%.")
    
    # Logic: Climate stability check for the Bonn region (Meteostat data)
    if location_score > 85:
        report.append(f"Climate Audit: Your location in the Bonn region shows high solar stability (Score: {location_score}). Winter production risks are evaluated as 'Low'.")
    else:
        report.append(f"Performance Transparency: Due to local cloud fluctuations, the system utilizes Bi-facial panels to maximize diffuse light capture.")

    # --- 4. REGIONAL PARTNER SELECTION ---
    system_size = analysis.get('capacity_kwp', 0)
    if system_size > 10.0:
        report.append("Execution Team: A Tier-1 'Solar-Meister' from the Bonn region will be assigned to oversee high-load calibration and VDE compliance.")
    else:
        report.append("Installation Team: Certified NRW-region contractors are prioritized for rapid deployment and local grid synchronization.")

    # --- 5. ENVIRONMENTAL LEGACY (Dual Metric: CO2 + Trees) ---
    env = analysis.get('environment', {})
    trees = env.get('tree_count', 0)
    co2_val = env.get('co2_saved', 0)
    
    # Combined metric for technical accuracy and emotional impact
    report.append(f"Sustainability: This system offsets {co2_val} Tons of CO2 annually, equivalent to planting {trees} mature trees in the Bonn region. Status: '{env.get('eco_grade')}'.")

    return report

def generate_advice_items(analysis, energy_rating='D'):
    """
    Language-neutral version of generate_architect_report: each tip is an id plus the
    raw numbers it needs, so clients can render it in the visitor's language.
    Mirrors the decision logic above one-to-one.
    """
    items = []
    financials = analysis.get('financials', {})
    payback = financials.get('payback', 15)
    if payback < 10:
        items.append({"id": "finance_direct", "params": {"profit": financials.get('twenty_year_profit', 0)}})
    elif payback < 13:
        items.append({"id": "finance_loan", "params": {}})
    else:
        items.append({"id": "finance_lease", "params": {}})

    strategy = analysis.get('strategy', {})
    autarky = strategy.get('autarky_rate', 0)
    if autarky > 80:
        items.append({"id": "independence_high", "params": {"autarky": autarky}})
    else:
        items.append({"id": "independence_low", "params": {"autarky": autarky}})

    location_score = strategy.get('location_score', 75)
    if energy_rating in ['E', 'F', 'G']:
        items.append({"id": "insulation_upgrade", "params": {"rating": energy_rating}})
    if location_score > 85:
        items.append({"id": "climate_stable", "params": {"score": location_score}})
    else:
        items.append({"id": "bifacial", "params": {}})

    if analysis.get('capacity_kwp', 0) > 10.0:
        items.append({"id": "team_meister", "params": {}})
    else:
        items.append({"id": "team_nrw", "params": {}})

    env = analysis.get('environment', {})
    items.append({"id": "sustainability", "params": {
        "co2": env.get('co2_saved', 0), "trees": env.get('tree_count', 0), "grade": env.get('eco_grade')}})
    return items
