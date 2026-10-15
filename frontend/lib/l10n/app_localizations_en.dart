// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addressExample => 'e.g. Musterstraße 12, 10115 Berlin';

  @override
  String get addressHint => 'Street, number, postcode, city';

  @override
  String get addressLabel => 'Property address';

  @override
  String get adviceBifacial =>
      'Performance transparency: Due to local cloud fluctuations, the system uses bifacial panels to maximize diffuse light capture.';

  @override
  String adviceClimateStable(Object score) {
    return 'Climate audit: Your location shows high solar stability (score: $score). Winter production risks are evaluated as \'low\'.';
  }

  @override
  String adviceFinanceDirect(Object profit) {
    return 'Financial strategy: \'Direct purchase\' highly recommended. With a $profit net profit over 20 years, this is your property\'s best asset.';
  }

  @override
  String get adviceFinanceLease =>
      'Financial strategy: \'Solar lease\'. To mitigate initial risks and enjoy full maintenance coverage, an OpEx model is more efficient for your profile.';

  @override
  String get adviceFinanceLoan =>
      'Financial strategy: \'Financing model\'. Your annual savings exceed loan installments, allowing the system to pay for itself.';

  @override
  String adviceIndependenceHigh(Object autarky) {
    return 'Energy independence: Outstanding! You will achieve $autarky% independence from the grid, creating a solid hedge against German electricity inflation.';
  }

  @override
  String adviceIndependenceLow(Object autarky) {
    return 'Consumption audit: Due to high household consumption, your autarky is $autarky%. We recommend shifting heavy appliance usage to peak sun hours (11:00–15:00).';
  }

  @override
  String adviceInsulation(Object rating) {
    return 'Infrastructure upgrade: Your building\'s energy rating ($rating) is low. Attic insulation is recommended to boost your solar ROI by an estimated 8%.';
  }

  @override
  String adviceSustainability(Object co2, Object trees, Object grade) {
    return 'Sustainability: This system offsets $co2 tons of CO₂ annually, equivalent to planting $trees mature trees. Status: \'$grade\'.';
  }

  @override
  String get adviceTeamMeister =>
      'Execution team: A tier-1 \'Solar-Meister\' from your region will be assigned to oversee high-load calibration and VDE compliance.';

  @override
  String get adviceTeamRegional =>
      'Installation team: Certified regional contractors are prioritized for rapid deployment and local grid synchronization.';

  @override
  String get advisorCalculating => 'Calculating…';

  @override
  String get advisorChip1 => '3–4× more efficient than gas';

  @override
  String get advisorChip2 => 'AI off-peak scheduling';

  @override
  String get advisorChip3 => 'Up to 80% less CO₂';

  @override
  String get advisorChip4 => '€15k install, BAFA subsidy eligible';

  @override
  String get advisorHeadline1 => 'Swap your gas boiler\nfor a';

  @override
  String get advisorHeadline2 => 'smart heat pump.';

  @override
  String get advisorIntro =>
      'Replace your gas boiler with a smart heat pump and let EnergyTwin\'s AI schedule heating around cheap electricity windows. Enter your property details to see your exact savings.';

  @override
  String get advisorInvalidBill => 'Please enter a valid monthly bill.';

  @override
  String get advisorPill => 'Powered by live EPEX SPOT market data';

  @override
  String get advisorRunningTwin => 'Running Digital Twin simulation…';

  @override
  String advisorServerError(Object code) {
    return 'Server error $code.';
  }

  @override
  String get advisorSimEyebrow => 'YOUR SIMULATION';

  @override
  String get advisorSimSubtitle =>
      'Three inputs are all the Digital Twin needs to model your heating demand.';

  @override
  String get advisorSimTitle => 'Tell us about your home.';

  @override
  String get advisorStep1Body =>
      'Burns natural gas at ~85% efficiency. German gas costs ~€0.10/kWh. Heating a typical home produces 1,200–2,400 kg of CO₂ every year.';

  @override
  String get advisorStep1Title => 'Your gas boiler today';

  @override
  String get advisorStep2Body =>
      'Moves heat from outdoor air using a small amount of electricity. A COP of 3.5 means 1 kWh in → 3.5 kWh of heat out — far more efficient than any combustion boiler.';

  @override
  String get advisorStep2Title => 'The heat pump upgrade';

  @override
  String get advisorStep3Body =>
      'Our AI monitors German EPEX SPOT prices and pre-heats your home during cheap windows (overnight wind surplus, midday solar dip) — saving an extra 40% on electricity.';

  @override
  String get advisorStep3Title => 'EnergyTwin AI scheduling';

  @override
  String get advisorSubtitle => 'ROI simulation · AI off-peak scheduling';

  @override
  String get advisorTitle => 'Heat Pump Advisor';

  @override
  String get advisorUnreachable => 'Could not reach server after 3 attempts.';

  @override
  String get advisorWhyEyebrow => 'WHY IT PAYS OFF';

  @override
  String get advisorWhyTitle => 'From burning gas to\nsmart, scheduled heat.';

  @override
  String get advisorySubtitle =>
      'Personalized recommendations from EnergyTwin\'s solar analysis engine';

  @override
  String get advisoryTitle => 'AI strategic advisory';

  @override
  String get analysisComplete => 'ANALYSIS COMPLETE';

  @override
  String get analyzeAnother => 'Analyze another property';

  @override
  String get analyzedProperty => 'ANALYZED PROPERTY';

  @override
  String get analyzedRoof => 'Analyzed roof';

  @override
  String get annualElecSavings => 'Annual electricity savings';

  @override
  String get annualHeatDemand => 'Annual heat demand';

  @override
  String get annualHeatDemandHint =>
      'Total thermal energy your home needs for heating — derived from gas consumption × 85% boiler efficiency';

  @override
  String get annualSavingsHint => 'Yearly reduction in electricity bill';

  @override
  String get appTitle => 'EnergyTwin | AI Command Center';

  @override
  String get asmBoiler => 'Gas boiler efficiency';

  @override
  String get asmBoilerHint => 'Typical old condensing boiler';

  @override
  String get asmBoilerValue => '85%';

  @override
  String get asmGasCo2 => 'Gas CO₂ intensity';

  @override
  String get asmGasCo2Hint => 'Direct natural gas emissions';

  @override
  String get asmGasCo2Value => '0.20 kg / kWh';

  @override
  String get asmGasPrice => 'Gas price';

  @override
  String get asmGasPriceHint => 'Current German residential tariff';

  @override
  String get asmGasPriceValue => '€0.10 / kWh';

  @override
  String get asmGridCo2 => 'Grid CO₂ intensity';

  @override
  String get asmGridCo2Hint => 'German electricity mix, 2024';

  @override
  String get asmGridCo2Value => '0.35 kg / kWh';

  @override
  String get asmInstall => 'Installation cost';

  @override
  String get asmInstallHint => 'Net after BAFA subsidy (up to €18,750)';

  @override
  String get asmInstallValue => '€15,000';

  @override
  String get asmSmartRate => 'Smart rate (EnergyTwin)';

  @override
  String get asmSmartRateHint => 'Off-peak EPEX SPOT average';

  @override
  String get asmSmartRateValue => '€0.18 / kWh';

  @override
  String get asmStdElec => 'Standard electricity';

  @override
  String get asmStdElecHint => 'Average German household rate';

  @override
  String get asmStdElecValue => '€0.30 / kWh';

  @override
  String get assumptionsSubtitle =>
      'Transparent methodology — Germany 2024 data.';

  @override
  String get assumptionsTitle => 'Model assumptions';

  @override
  String get backToTracing => 'Back to tracing';

  @override
  String get bafaEligible =>
      'BAFA-eligible system — qualifies for German state subsidy';

  @override
  String get batteryValue => 'Battery value';

  @override
  String get best => 'BEST';

  @override
  String get buildingInsulation => 'Building insulation';

  @override
  String get calculateSavings => 'Calculate my savings';

  @override
  String get carsHint => 'Taken off the road equivalent';

  @override
  String carsValue(Object count) {
    return '$count cars';
  }

  @override
  String get changeAddress => 'Change address';

  @override
  String get chartSubtitle => 'Hover or tap the curve for exact prices';

  @override
  String get chartTitle => 'Hourly price curve';

  @override
  String get cheapest => 'Cheapest';

  @override
  String clearCount(Object count) {
    return 'Clear ($count)';
  }

  @override
  String get co2Eliminated => 'CO₂ eliminated';

  @override
  String get co2EliminatedHint => 'Annual carbon emissions prevented';

  @override
  String co2LessThanGas(Object pct) {
    return '$pct% less CO₂ than gas';
  }

  @override
  String get co2PerYear => 'CO₂ eliminated per year';

  @override
  String get co2ReductionVsGas => 'CO₂ reduction vs. your gas boiler';

  @override
  String get co2SavedPerYear => 'CO₂ saved per year';

  @override
  String get copAcceptable => 'Acceptable';

  @override
  String get copExcellent => 'Excellent';

  @override
  String get copFull => 'Coefficient of performance';

  @override
  String copFullHint(Object cop) {
    return '1 kWh electricity → ${cop}x kWh of heat. Depends on insulation quality and system design.';
  }

  @override
  String get copGood => 'Good';

  @override
  String get copHintAverage => 'COP ≈ 3.5  ·  typical German installation';

  @override
  String get copHintGood => 'COP ≈ 4.2  ·  excellent with underfloor heating';

  @override
  String get copHintPoor => 'COP ≈ 2.8  ·  needs higher water temps';

  @override
  String copLabel(Object rating) {
    return 'COP · $rating';
  }

  @override
  String get cornerPlaced => 'corner placed';

  @override
  String get cornersPlaced => 'corners placed';

  @override
  String get costGas => 'Gas Boiler';

  @override
  String get costGasDesc =>
      'Your current system — gas burned at 85% efficiency';

  @override
  String get costSmartHp => 'EnergyTwin Smart Heat Pump';

  @override
  String get costSmartHpDesc =>
      'AI shifts load to off-peak windows — avg €0.18/kWh';

  @override
  String get costStdHp => 'Standard Heat Pump';

  @override
  String get costStdHpDesc =>
      'Off-the-shelf install, billed at flat €0.30/kWh tariff';

  @override
  String get costSubtitle =>
      'Same warmth — three very different heating strategies.';

  @override
  String get costTitle => 'Annual cost comparison';

  @override
  String ctPerKwhValue(Object value) {
    return '$value ct/kWh';
  }

  @override
  String ctValue(Object value) {
    return '$value ct';
  }

  @override
  String get ecoClimateHero => 'Climate Hero';

  @override
  String get ecoGradeHint => 'Sustainability rating for this system';

  @override
  String get ecoGradeTitle => 'EnergyTwin eco grade';

  @override
  String get ecoWarrior => 'Eco-Warrior';

  @override
  String get elecBillHelper => 'Average monthly bill in euros';

  @override
  String get elecBillLabel => 'Monthly electricity bill';

  @override
  String get energyClassHelper => 'EU energy label A (best) – G (worst)';

  @override
  String get energyClassLabel => 'Energy efficiency class';

  @override
  String energyClassSemantics(Object letter) {
    return 'Energy class $letter';
  }

  @override
  String get envTitle => 'Environmental impact';

  @override
  String errorServerCode(Object code) {
    return 'Server returned error $code. Please try again.';
  }

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorUnreachable =>
      'Could not reach server after 3 attempts. Check your connection.';

  @override
  String get fetchSatellite => 'Fetch satellite image';

  @override
  String get financialTitle => 'Financial overview';

  @override
  String get fiveCheapestHours => 'FIVE CHEAPEST HOURS';

  @override
  String get gasBillHelper =>
      'Your average monthly gas or district heating bill';

  @override
  String get gasBillLabel => 'Monthly heating / gas bill';

  @override
  String get gridPriceHelper => 'Your current tariff in ct/kWh';

  @override
  String get gridPriceLabel => 'Grid electricity price';

  @override
  String get guideSubtitle => 'Retail = wholesale + 15 ct grid/tax + 19% VAT';

  @override
  String get guideTitle => 'Price guide';

  @override
  String homeAboveAverage(Object pct, Object avg) {
    return '$pct% above today\'s average of $avg ct';
  }

  @override
  String homeBelowAverage(Object pct, Object avg) {
    return '$pct% below today\'s average of $avg ct';
  }

  @override
  String get homeCtaBody =>
      'Enter a few details about your home and get a personalised savings estimate in under a minute.';

  @override
  String get homeCtaButton => 'Start with the Advisor';

  @override
  String get homeCtaPrices => 'Explore live prices';

  @override
  String get homeCtaSavings => 'Calculate my savings';

  @override
  String get homeCtaTitle => 'Ready to see what you could save?';

  @override
  String get homeFeatureAdvisorBody =>
      'Find out what replacing your gas boiler really saves, and how AI scheduling around cheap windows adds even more.';

  @override
  String get homeFeatureAdvisorTitle => 'Heat Pump Advisor';

  @override
  String get homeFeaturePricesBody =>
      'Day-ahead prices for today and tomorrow, converted into what you actually pay per kWh — with the cheapest hours highlighted.';

  @override
  String get homeFeaturePricesTitle => 'Price Forecast';

  @override
  String get homeFeatureSolarBody =>
      'Trace your roof on satellite imagery and get AI panel placement, yearly yield and payback estimates in seconds.';

  @override
  String get homeFeatureSolarTitle => 'Solar AI';

  @override
  String get homeFooterSources =>
      'Market data: SMARD.de · EPEX SPOT. Prices shown are forecasts, not tariffs.';

  @override
  String get homeFullForecast => 'Full forecast for today & tomorrow';

  @override
  String get homeHeadline1 => 'Power your home\nat the';

  @override
  String get homeHeadline2 => 'smartest hour.';

  @override
  String get homeHowEyebrow => 'HOW IT WORKS';

  @override
  String get homeHowTitle => 'From market data\nto money saved.';

  @override
  String get homeIntro =>
      'EnergyTwin forecasts German electricity prices with machine learning and turns them into real savings for your heat pump, solar roof and everyday appliances.';

  @override
  String get homeLiveBadge => 'Live forecast · EPEX SPOT DE-LU';

  @override
  String get homeLiveUnavailable => 'Live prices are unavailable';

  @override
  String get homeOpenTool => 'Open tool';

  @override
  String get homePlatformEyebrow => 'PLATFORM';

  @override
  String get homePlatformSubtitle =>
      'Every tool runs on the same live market forecast, so your decisions stay consistent from today\'s laundry to a 20-year solar investment.';

  @override
  String get homePlatformTitle =>
      'Three tools. One goal:\na cheaper, greener home.';

  @override
  String get homeServerNoResponse => 'The forecast server didn\'t respond.';

  @override
  String get homeStatHorizon => 'Day-ahead horizon';

  @override
  String get homeStatMae => 'Forecast MAE per MWh';

  @override
  String get homeStatTools => 'AI-powered tools';

  @override
  String get homeStatVat => 'VAT included in prices';

  @override
  String get homeStepCollect => 'Collect';

  @override
  String get homeStepCollectBody =>
      'Generation, load and spot-price data stream in from SMARD and the EPEX SPOT day-ahead auction.';

  @override
  String get homeStepOptimize => 'Optimize';

  @override
  String get homeStepOptimizeBody =>
      'Your heat pump, solar and appliances are planned around the cheapest, greenest windows.';

  @override
  String get homeStepPredict => 'Predict';

  @override
  String get homeStepPredictBody =>
      'A gradient-boosted model forecasts every hour of the coming day, accounting for wind, solar and demand.';

  @override
  String get homeTrust1 => 'XGBoost forecasting';

  @override
  String get homeTrust2 => 'Retail prices incl. VAT';

  @override
  String get homeTrust3 => 'Built for German homes';

  @override
  String get homeWakingUp => 'Waking up the forecast engine…';

  @override
  String get hourlyHeatmap => 'HOURLY HEATMAP';

  @override
  String get houseSize => 'House size';

  @override
  String get householdHelper => 'Number of people living there';

  @override
  String get householdLabel => 'Household size';

  @override
  String get hpElectricity => 'Heat pump electricity';

  @override
  String get hpElectricityHint =>
      'Electricity the heat pump consumes to deliver the heat demand above';

  @override
  String get independence => 'Independence';

  @override
  String insightAfter(Object pct) {
    return ' — about $pct% cheaper than the daily average.';
  }

  @override
  String get insightBefore =>
      'shift your dishwasher, laundry or EV charging to ';

  @override
  String get insightPlan => 'Plan ahead: ';

  @override
  String get insightSmart => 'Smart move: ';

  @override
  String get insulationAverage => 'Average';

  @override
  String get insulationAverageDesc => 'Standard German construction';

  @override
  String insulationClass(Object level) {
    return 'Insulation class · $level';
  }

  @override
  String get insulationClassHint =>
      'Determines achievable COP and heat distribution type (radiators vs. underfloor heating)';

  @override
  String get insulationGood => 'Good';

  @override
  String get insulationGoodDesc => 'Modern, renovated or passive';

  @override
  String get insulationPoor => 'Poor';

  @override
  String get insulationPoorDesc => 'Pre-1980, minimal insulation';

  @override
  String get investmentPayback => 'Investment payback period';

  @override
  String kgValue(Object value) {
    return '$value kg';
  }

  @override
  String get kpiAnnualSavings => 'Annual savings';

  @override
  String get kpiBestHour => 'Best hour';

  @override
  String get kpiCo2Avoided => 'CO₂ avoided';

  @override
  String get kpiCurrentPrice => 'Current price';

  @override
  String get kpiDailyRange => 'Daily range';

  @override
  String get kpiDayAverage => 'Day average';

  @override
  String get kpiNextBestHour => 'Next best hour';

  @override
  String get kpiOpeningPrice => 'Opening price';

  @override
  String get kpiPanels => 'Panels on your roof';

  @override
  String get kpiPayback => 'Payback period';

  @override
  String get kpiPeakMinusOffPeak => 'peak minus off-peak';

  @override
  String get kwhPerYear => 'kWh / yr';

  @override
  String kwpCapacity(Object kwp) {
    return '$kwp kWp installed capacity';
  }

  @override
  String get language => 'Language';

  @override
  String get legendCheap => 'Cheap < 15 ct';

  @override
  String get legendMid => 'Mid 15–25 ct';

  @override
  String get legendPeak => 'Peak > 25 ct';

  @override
  String get loadingAlmost => 'Almost there…';

  @override
  String get loadingConnecting => 'Connecting to server…';

  @override
  String get loadingPrices => 'Loading prices…';

  @override
  String loadingRetry(Object attempt) {
    return 'Retrying… (attempt $attempt of 3)';
  }

  @override
  String get loadingWarmingUp => 'Server is warming up…';

  @override
  String get metricsExplain =>
      'Independence: % of electricity self-produced. Sun Score: location quality. Battery Value: estimated benefit of adding a home battery.';

  @override
  String get monthlyRelief => 'Monthly relief';

  @override
  String get monthlyReliefHint => 'Average monthly bill reduction';

  @override
  String moreNeeded(Object count) {
    return '$count more needed';
  }

  @override
  String get navAdvisor => 'Advisor';

  @override
  String get navHome => 'Home';

  @override
  String get navPrices => 'Prices';

  @override
  String get navSolar => 'Solar AI';

  @override
  String get netProfit20 => '20-year net profit';

  @override
  String get netProfit20Hint => 'Total earnings after installation cost';

  @override
  String get now => 'NOW';

  @override
  String panelOverlay(Object count, Object area) {
    return 'AI panel placement overlay — $count panels on $area m²';
  }

  @override
  String get panelsSuffix => ' panels';

  @override
  String get paybackHint => 'Time to recoup installation investment';

  @override
  String get peak => 'Peak';

  @override
  String get peopleSuffix => 'people';

  @override
  String get perKwhInclVat => 'per kWh incl. VAT';

  @override
  String get perMonthShort => '€/mo';

  @override
  String get perMonthSuffix => '€ / month';

  @override
  String get perYearShort => '/yr';

  @override
  String get pricesAiForecast => 'XGBoost AI forecast';

  @override
  String get pricesEyebrow => 'GERMAN ELECTRICITY MARKET';

  @override
  String get pricesFetchingToday => 'Fetching today\'s 24-hour price curve';

  @override
  String get pricesFetchingTomorrow =>
      'Fetching tomorrow\'s 24-hour price curve';

  @override
  String get pricesHeadline => 'What power really costs,\nhour by hour.';

  @override
  String get pricesIntro =>
      'Wholesale EPEX SPOT prices converted to your retail price — plus 15 ct grid fees & taxes and 19% VAT.';

  @override
  String get pricesLiveData => 'Live EPEX SPOT data';

  @override
  String get pricesLoadError => 'Couldn\'t load prices';

  @override
  String get pricesSubtitle => 'EPEX SPOT DE-LU · retail incl. grid fees & VAT';

  @override
  String get pricesTitle => 'Price Forecast';

  @override
  String get propertyDetails => 'Property details';

  @override
  String get propertyDetailsSubtitle =>
      'Enter your address to fetch a satellite image of your roof.';

  @override
  String get propertySubtitle =>
      'The bill auto-estimates as you adjust size and insulation.';

  @override
  String get propertyTitle => 'Your property';

  @override
  String get ready => 'Ready';

  @override
  String get resultsEyebrow => 'YOUR DIGITAL TWIN RESULTS';

  @override
  String get resultsTitle => 'Here\'s what you\'d save.';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get rightNow => 'RIGHT NOW';

  @override
  String roofArea(Object area) {
    return 'Roof area: $area m²';
  }

  @override
  String get runAiAnalysis => 'Run AI analysis';

  @override
  String get schedulingSubtitle =>
      'The AI shifts your heat pump runtime to the three cheapest daily windows on the German EPEX SPOT market — the same prices shown on your Prices screen.';

  @override
  String get schedulingTip =>
      'A well-insulated home retains heat for 3–6 hours, making schedule shifting painless and invisible to occupants.';

  @override
  String schedulingTitle(Object amount, Object pct) {
    return 'How EnergyTwin saves an extra $amount/yr ($pct%)';
  }

  @override
  String get selectedProperty => 'Selected property';

  @override
  String get simulationComplete => 'Simulation complete';

  @override
  String get sizeDetached => 'Detached house';

  @override
  String get sizeLarge => 'Large property';

  @override
  String get sizeMediumApartment => 'Medium apartment';

  @override
  String get sizeSemiDetached => 'Semi-detached';

  @override
  String get sizeSmallApartment => 'Small apartment';

  @override
  String get solarAddressNotFound => 'Could not find address.';

  @override
  String get solarBackendUnreachable => 'Failed to connect to backend.';

  @override
  String get solarChip1 => '3-step analysis';

  @override
  String get solarChip2 => 'ROI & payback calc';

  @override
  String get solarChip3 => 'CO₂ impact report';

  @override
  String get solarConnecting => 'Connecting…';

  @override
  String get solarFetchingImage => 'Fetching satellite image…';

  @override
  String get solarFindingRoof => 'Finding your roof…';

  @override
  String get solarHeadline1 => 'See what your roof\ncould';

  @override
  String get solarHeadline2 => 'earn you.';

  @override
  String get solarIntro =>
      'Enter your property address and energy details. We fetch a satellite image, you trace your roof outline, and our AI calculates your exact solar potential and financial return.';

  @override
  String get solarNoPanelsFit =>
      'No solar panels fit inside the traced outline. Trace the full roof surface and try again.';

  @override
  String get solarPill => 'Solar irradiance via Open-Meteo · Satellite imagery';

  @override
  String get solarPotentialTitle => 'Your roof\'s solar potential.';

  @override
  String get solarRunningAnalysis => 'Running solar analysis…';

  @override
  String get solarRunningSim => 'Running solar simulation…';

  @override
  String get solarServerError => 'Server error. Please try again.';

  @override
  String get solarSimFailed => 'Simulation failed. Please try again.';

  @override
  String get solarSubtitle => 'Satellite roof analysis · yield & payback';

  @override
  String get solarTapAtLeast3 => 'Tap at least 3 corners on the roof!';

  @override
  String get solarTitle => 'Solar AI';

  @override
  String get sourceEpex => 'Source: EPEX SPOT DE-LU via Fraunhofer ISE';

  @override
  String get sourceModel => 'Source: XGBoost model trained on ENTSO-E data';

  @override
  String get specsTitle => 'System specifications';

  @override
  String get startOver => 'Start over';

  @override
  String get statBreakEven => 'Break-even payback';

  @override
  String get statCo2PerYear => 'CO₂ eliminated / yr';

  @override
  String get statSavedPerYear => 'Saved per year';

  @override
  String get statTwentyYears => 'Total over 20 years';

  @override
  String get statusAverage => 'Average';

  @override
  String get statusCheapHour => 'Cheap hour';

  @override
  String get statusPeakHour => 'Peak hour';

  @override
  String get stepEnterDetails => 'Enter details';

  @override
  String get stepTraceRoof => 'Trace roof';

  @override
  String get stepViewResults => 'View results';

  @override
  String get sunScore => 'Sun score';

  @override
  String get systemMetrics => 'System metrics';

  @override
  String get tagComputerVision => 'Computer vision';

  @override
  String get tagSatellite => 'Satellite';

  @override
  String get tagSmartScheduling => 'Smart scheduling';

  @override
  String get tapRoofCorners => 'Tap corners of your roof';

  @override
  String get themeDark => 'Dark mode';

  @override
  String get themeLight => 'Light mode';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String tonsPerYear(Object value) {
    return '$value t/yr';
  }

  @override
  String get traceSubtitle =>
      'Tap the corners of your roof polygon in order — at least 3 points.';

  @override
  String get traceTip1 =>
      'Tap each corner of the roof surface you want to cover.';

  @override
  String get traceTip2 =>
      'Go around the outline in order — clockwise or counter-clockwise.';

  @override
  String get traceTip3 => 'Run the AI analysis once the shape looks right.';

  @override
  String get traceTitle => 'Trace your roof';

  @override
  String get treeEquivalent => 'Tree equivalent';

  @override
  String get treeEquivalentHint => 'Annual CO₂ absorption equivalent';

  @override
  String treesApprox(Object count) {
    return '~$count trees';
  }

  @override
  String get treesHint => 'Equivalent annual CO₂ absorption';

  @override
  String treesPerYear(Object count) {
    return '~$count trees/yr';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get typicalDay => 'A TYPICAL DAY';

  @override
  String get undo => 'Undo';

  @override
  String get unitCtKwh => 'ct/kWh';

  @override
  String get windowEveningBody =>
      'Evening demand spikes push EPEX to 30–60 ct/kWh. EnergyTwin pauses the heat pump. Stored heat keeps your home comfortable without paying peak rates.';

  @override
  String get windowEveningTitle => 'Avoid evening peak';

  @override
  String get windowMiddayBody =>
      'Germany\'s solar fleet peaks and prices can hit 0 or even go negative. EnergyTwin maximises heat pump runtime in this window — essentially free heat.';

  @override
  String get windowMiddayTitle => 'Solar surplus midday';

  @override
  String get windowNightBody =>
      'Wind turbines run all night but demand is minimal. EPEX prices fall to 5–15 ct/kWh. EnergyTwin pre-charges your home\'s thermal mass silently while you sleep.';

  @override
  String get windowNightTitle => 'Overnight wind valley';

  @override
  String get yearsSuffix => ' yrs';

  @override
  String yearsValue(Object value) {
    return '$value years';
  }

  @override
  String get zoneCheap => 'Cheap';

  @override
  String get zoneCheapDesc => 'Run heat pump, charge EV, do laundry';

  @override
  String get zoneMid => 'Mid';

  @override
  String get zoneMidDesc => 'Normal household use, monitor closely';

  @override
  String get zonePeak => 'Peak';

  @override
  String get zonePeakDesc => 'Avoid big loads, discharge battery';
}
