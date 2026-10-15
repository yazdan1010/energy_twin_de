// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get addressExample => 'z. B. Musterstraße 12, 10115 Berlin';

  @override
  String get addressHint => 'Straße, Hausnummer, PLZ, Ort';

  @override
  String get addressLabel => 'Adresse der Immobilie';

  @override
  String get adviceBifacial =>
      'Leistungstransparenz: Aufgrund lokaler Bewölkungsschwankungen nutzt die Anlage bifaziale Module, um diffuses Licht optimal einzufangen.';

  @override
  String adviceClimateStable(Object score) {
    return 'Klimaanalyse: Ihr Standort weist eine hohe Solarstabilität auf (Wert: $score). Das Risiko geringer Winterproduktion wird als „niedrig“ eingestuft.';
  }

  @override
  String adviceFinanceDirect(Object profit) {
    return 'Finanzierungsstrategie: „Direktkauf“ sehr empfehlenswert. Mit $profit Nettogewinn über 20 Jahre ist dies die beste Investition für Ihre Immobilie.';
  }

  @override
  String get adviceFinanceLease =>
      'Finanzierungsstrategie: „Solar-Leasing“. Um Anfangsrisiken zu minimieren und von vollständiger Wartung zu profitieren, ist ein Mietmodell für Ihr Profil effizienter.';

  @override
  String get adviceFinanceLoan =>
      'Finanzierungsstrategie: „Finanzierungsmodell“. Ihre jährliche Ersparnis übersteigt die Kreditraten – die Anlage finanziert sich selbst.';

  @override
  String adviceIndependenceHigh(Object autarky) {
    return 'Energieunabhängigkeit: Hervorragend! Sie erreichen $autarky % Unabhängigkeit vom Netz – ein solider Schutz gegen steigende Strompreise in Deutschland.';
  }

  @override
  String adviceIndependenceLow(Object autarky) {
    return 'Verbrauchsanalyse: Aufgrund des hohen Haushaltsverbrauchs liegt Ihr Autarkiegrad bei $autarky %. Nutzen Sie energieintensive Geräte möglichst in den sonnenreichen Stunden (11–15 Uhr).';
  }

  @override
  String adviceInsulation(Object rating) {
    return 'Gebäudemodernisierung: Die Energieeffizienzklasse Ihres Gebäudes ($rating) ist niedrig. Eine Dachbodendämmung steigert Ihre Solarrendite um geschätzt 8 %.';
  }

  @override
  String adviceSustainability(Object co2, Object trees, Object grade) {
    return 'Nachhaltigkeit: Diese Anlage spart jährlich $co2 Tonnen CO₂ ein – so viel wie $trees ausgewachsene Bäume. Status: „$grade“.';
  }

  @override
  String get adviceTeamMeister =>
      'Ausführung: Ein erstklassiger Solar-Meisterbetrieb aus Ihrer Region übernimmt die Kalibrierung für hohe Lasten und die VDE-Konformität.';

  @override
  String get adviceTeamRegional =>
      'Installation: Zertifizierte Fachbetriebe aus Ihrer Region werden für eine schnelle Montage und den Netzanschluss bevorzugt.';

  @override
  String get advisorCalculating => 'Wird berechnet …';

  @override
  String get advisorChip1 => '3–4× effizienter als Gas';

  @override
  String get advisorChip2 => 'KI-Steuerung in Niedrigpreisphasen';

  @override
  String get advisorChip3 => 'Bis zu 80 % weniger CO₂';

  @override
  String get advisorChip4 => '15.000 € Installation, BAFA-förderfähig';

  @override
  String get advisorHeadline1 => 'Von der Gasheizung\nzur';

  @override
  String get advisorHeadline2 => 'smarten Wärmepumpe.';

  @override
  String get advisorIntro =>
      'Ersetzen Sie Ihre Gasheizung durch eine smarte Wärmepumpe und lassen Sie die KI von EnergyTwin das Heizen in günstige Stromphasen legen. Geben Sie Ihre Immobiliendaten ein und sehen Sie Ihre genaue Ersparnis.';

  @override
  String get advisorInvalidBill =>
      'Bitte geben Sie einen gültigen Monatsbetrag ein.';

  @override
  String get advisorPill => 'Basierend auf Live-Marktdaten von EPEX SPOT';

  @override
  String get advisorRunningTwin => 'Digitaler Zwilling wird simuliert …';

  @override
  String advisorServerError(Object code) {
    return 'Serverfehler $code.';
  }

  @override
  String get advisorSimEyebrow => 'IHRE SIMULATION';

  @override
  String get advisorSimSubtitle =>
      'Drei Angaben genügen dem digitalen Zwilling, um Ihren Heizbedarf zu modellieren.';

  @override
  String get advisorSimTitle => 'Erzählen Sie uns von Ihrem Zuhause.';

  @override
  String get advisorStep1Body =>
      'Verbrennt Erdgas mit ca. 85 % Wirkungsgrad. Gas kostet in Deutschland ca. 0,10 €/kWh. Das Heizen eines typischen Hauses verursacht jährlich 1.200–2.400 kg CO₂.';

  @override
  String get advisorStep1Title => 'Ihre Gasheizung heute';

  @override
  String get advisorStep2Body =>
      'Entzieht der Außenluft Wärme mit wenig Strom. Eine Leistungszahl (COP) von 3,5 bedeutet: 1 kWh Strom → 3,5 kWh Wärme – weit effizienter als jeder Verbrennungskessel.';

  @override
  String get advisorStep2Title => 'Der Umstieg auf die Wärmepumpe';

  @override
  String get advisorStep3Body =>
      'Unsere KI beobachtet die EPEX-SPOT-Preise und heizt Ihr Zuhause in günstigen Phasen vor (nächtlicher Windüberschuss, mittägliches Solartal) – das spart zusätzlich 40 % Stromkosten.';

  @override
  String get advisorStep3Title => 'KI-Steuerung von EnergyTwin';

  @override
  String get advisorSubtitle =>
      'Renditesimulation · KI-Steuerung in Niedrigpreisphasen';

  @override
  String get advisorTitle => 'Wärmepumpen-Berater';

  @override
  String get advisorUnreachable => 'Server nach 3 Versuchen nicht erreichbar.';

  @override
  String get advisorWhyEyebrow => 'WARUM ES SICH LOHNT';

  @override
  String get advisorWhyTitle =>
      'Vom Gasverbrennen zur\nsmarten, gesteuerten Wärme.';

  @override
  String get advisorySubtitle =>
      'Persönliche Empfehlungen der Solaranalyse von EnergyTwin';

  @override
  String get advisoryTitle => 'KI-Strategieberatung';

  @override
  String get analysisComplete => 'ANALYSE ABGESCHLOSSEN';

  @override
  String get analyzeAnother => 'Weitere Immobilie analysieren';

  @override
  String get analyzedProperty => 'ANALYSIERTE IMMOBILIE';

  @override
  String get analyzedRoof => 'Analysiertes Dach';

  @override
  String get annualElecSavings => 'Jährliche Stromkostenersparnis';

  @override
  String get annualHeatDemand => 'Jährlicher Wärmebedarf';

  @override
  String get annualHeatDemandHint =>
      'Gesamte Wärmeenergie, die Ihr Zuhause zum Heizen benötigt – abgeleitet aus Gasverbrauch × 85 % Kesselwirkungsgrad';

  @override
  String get annualSavingsHint => 'Jährliche Senkung der Stromrechnung';

  @override
  String get appTitle => 'EnergyTwin | KI-Kommandozentrale';

  @override
  String get asmBoiler => 'Wirkungsgrad Gasheizung';

  @override
  String get asmBoilerHint => 'Typischer älterer Brennwertkessel';

  @override
  String get asmBoilerValue => '85 %';

  @override
  String get asmGasCo2 => 'CO₂-Intensität Gas';

  @override
  String get asmGasCo2Hint => 'Direkte Emissionen von Erdgas';

  @override
  String get asmGasCo2Value => '0,20 kg / kWh';

  @override
  String get asmGasPrice => 'Gaspreis';

  @override
  String get asmGasPriceHint => 'Aktueller Haushaltstarif in Deutschland';

  @override
  String get asmGasPriceValue => '0,10 € / kWh';

  @override
  String get asmGridCo2 => 'CO₂-Intensität Strommix';

  @override
  String get asmGridCo2Hint => 'Deutscher Strommix, 2024';

  @override
  String get asmGridCo2Value => '0,35 kg / kWh';

  @override
  String get asmInstall => 'Installationskosten';

  @override
  String get asmInstallHint => 'Netto nach BAFA-Förderung (bis zu 18.750 €)';

  @override
  String get asmInstallValue => '15.000 €';

  @override
  String get asmSmartRate => 'Smarter Tarif (EnergyTwin)';

  @override
  String get asmSmartRateHint => 'EPEX-SPOT-Durchschnitt in Niedrigpreisphasen';

  @override
  String get asmSmartRateValue => '0,18 € / kWh';

  @override
  String get asmStdElec => 'Standardstrom';

  @override
  String get asmStdElecHint => 'Durchschnittlicher Haushaltsstrompreis';

  @override
  String get asmStdElecValue => '0,30 € / kWh';

  @override
  String get assumptionsSubtitle =>
      'Transparente Methodik – Daten für Deutschland 2024.';

  @override
  String get assumptionsTitle => 'Modellannahmen';

  @override
  String get backToTracing => 'Zurück zum Zeichnen';

  @override
  String get bafaEligible =>
      'BAFA-förderfähige Anlage – qualifiziert für staatliche Förderung';

  @override
  String get batteryValue => 'Batterienutzen';

  @override
  String get best => 'BESTE';

  @override
  String get buildingInsulation => 'Gebäudedämmung';

  @override
  String get calculateSavings => 'Meine Ersparnis berechnen';

  @override
  String get carsHint => 'Entspricht so vielen Autos weniger auf der Straße';

  @override
  String carsValue(Object count) {
    return '$count Autos';
  }

  @override
  String get changeAddress => 'Adresse ändern';

  @override
  String get chartSubtitle =>
      'Für genaue Preise auf die Kurve zeigen oder tippen';

  @override
  String get chartTitle => 'Stündliche Preiskurve';

  @override
  String get cheapest => 'Am günstigsten';

  @override
  String clearCount(Object count) {
    return 'Löschen ($count)';
  }

  @override
  String get co2Eliminated => 'Vermiedenes CO₂';

  @override
  String get co2EliminatedHint => 'Jährlich vermiedene CO₂-Emissionen';

  @override
  String co2LessThanGas(Object pct) {
    return '$pct % weniger CO₂ als mit Gas';
  }

  @override
  String get co2PerYear => 'Vermiedenes CO₂ pro Jahr';

  @override
  String get co2ReductionVsGas => 'CO₂-Reduktion gegenüber Ihrer Gasheizung';

  @override
  String get co2SavedPerYear => 'Eingespartes CO₂ pro Jahr';

  @override
  String get copAcceptable => 'Akzeptabel';

  @override
  String get copExcellent => 'Hervorragend';

  @override
  String get copFull => 'Leistungszahl (COP)';

  @override
  String copFullHint(Object cop) {
    return '1 kWh Strom → $cop× kWh Wärme. Abhängig von Dämmqualität und Anlagenauslegung.';
  }

  @override
  String get copGood => 'Gut';

  @override
  String get copHintAverage =>
      'COP ≈ 3,5  ·  typische Installation in Deutschland';

  @override
  String get copHintGood => 'COP ≈ 4,2  ·  ideal mit Fußbodenheizung';

  @override
  String get copHintPoor => 'COP ≈ 2,8  ·  benötigt höhere Vorlauftemperaturen';

  @override
  String copLabel(Object rating) {
    return 'COP · $rating';
  }

  @override
  String get cornerPlaced => 'Ecke gesetzt';

  @override
  String get cornersPlaced => 'Ecken gesetzt';

  @override
  String get costGas => 'Gasheizung';

  @override
  String get costGasDesc => 'Ihr aktuelles System – Gas mit 85 % Wirkungsgrad';

  @override
  String get costSmartHp => 'EnergyTwin Smart-Wärmepumpe';

  @override
  String get costSmartHpDesc =>
      'KI verlagert den Verbrauch in günstige Phasen – Ø 0,18 €/kWh';

  @override
  String get costStdHp => 'Standard-Wärmepumpe';

  @override
  String get costStdHpDesc =>
      'Standardinstallation, abgerechnet zum Festpreis von 0,30 €/kWh';

  @override
  String get costSubtitle =>
      'Gleiche Wärme – drei sehr unterschiedliche Heizstrategien.';

  @override
  String get costTitle => 'Jährlicher Kostenvergleich';

  @override
  String ctPerKwhValue(Object value) {
    return '$value ct/kWh';
  }

  @override
  String ctValue(Object value) {
    return '$value ct';
  }

  @override
  String get ecoClimateHero => 'Klimaheld';

  @override
  String get ecoGradeHint => 'Nachhaltigkeitsbewertung dieser Anlage';

  @override
  String get ecoGradeTitle => 'EnergyTwin-Ökobewertung';

  @override
  String get ecoWarrior => 'Umweltpionier';

  @override
  String get elecBillHelper => 'Durchschnittlicher Monatsbetrag in Euro';

  @override
  String get elecBillLabel => 'Monatliche Stromrechnung';

  @override
  String get energyClassHelper =>
      'EU-Energielabel A (beste) – G (schlechteste)';

  @override
  String get energyClassLabel => 'Energieeffizienzklasse';

  @override
  String energyClassSemantics(Object letter) {
    return 'Energieklasse $letter';
  }

  @override
  String get envTitle => 'Umweltwirkung';

  @override
  String errorServerCode(Object code) {
    return 'Der Server meldete Fehler $code. Bitte versuchen Sie es erneut.';
  }

  @override
  String get errorTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorUnreachable =>
      'Server nach 3 Versuchen nicht erreichbar. Bitte prüfen Sie Ihre Verbindung.';

  @override
  String get fetchSatellite => 'Satellitenbild laden';

  @override
  String get financialTitle => 'Finanzübersicht';

  @override
  String get fiveCheapestHours => 'DIE FÜNF GÜNSTIGSTEN STUNDEN';

  @override
  String get gasBillHelper =>
      'Ihre durchschnittlichen monatlichen Gas- oder Fernwärmekosten';

  @override
  String get gasBillLabel => 'Monatliche Heiz-/Gaskosten';

  @override
  String get gridPriceHelper => 'Ihr aktueller Tarif in ct/kWh';

  @override
  String get gridPriceLabel => 'Netzstrompreis';

  @override
  String get guideSubtitle =>
      'Endpreis = Großhandel + 15 ct Netz/Abgaben + 19 % MwSt.';

  @override
  String get guideTitle => 'Preisleitfaden';

  @override
  String homeAboveAverage(Object pct, Object avg) {
    return '$pct % über dem heutigen Durchschnitt von $avg ct';
  }

  @override
  String homeBelowAverage(Object pct, Object avg) {
    return '$pct % unter dem heutigen Durchschnitt von $avg ct';
  }

  @override
  String get homeCtaBody =>
      'Geben Sie ein paar Eckdaten zu Ihrem Zuhause ein und erhalten Sie in unter einer Minute eine persönliche Sparprognose.';

  @override
  String get homeCtaButton => 'Mit dem Berater starten';

  @override
  String get homeCtaPrices => 'Live-Preise ansehen';

  @override
  String get homeCtaSavings => 'Meine Ersparnis berechnen';

  @override
  String get homeCtaTitle => 'Bereit zu sehen, wie viel Sie sparen können?';

  @override
  String get homeFeatureAdvisorBody =>
      'Erfahren Sie, was der Austausch Ihrer Gasheizung wirklich spart – und wie die KI-Steuerung in günstigen Zeitfenstern noch mehr herausholt.';

  @override
  String get homeFeatureAdvisorTitle => 'Wärmepumpen-Berater';

  @override
  String get homeFeaturePricesBody =>
      'Day-Ahead-Preise für heute und morgen, umgerechnet in das, was Sie pro kWh wirklich zahlen – die günstigsten Stunden hervorgehoben.';

  @override
  String get homeFeaturePricesTitle => 'Preisprognose';

  @override
  String get homeFeatureSolarBody =>
      'Zeichnen Sie Ihr Dach auf dem Satellitenbild nach und erhalten Sie in Sekunden KI-Modulbelegung, Jahresertrag und Amortisation.';

  @override
  String get homeFeatureSolarTitle => 'Solar-KI';

  @override
  String get homeFooterSources =>
      'Marktdaten: SMARD.de · EPEX SPOT. Die angezeigten Preise sind Prognosen, keine Tarife.';

  @override
  String get homeFullForecast => 'Vollständige Prognose für heute & morgen';

  @override
  String get homeHeadline1 => 'Strom nutzen,\nwenn er am';

  @override
  String get homeHeadline2 => 'günstigsten ist.';

  @override
  String get homeHowEyebrow => 'SO FUNKTIONIERT ES';

  @override
  String get homeHowTitle => 'Von Marktdaten\nzu echter Ersparnis.';

  @override
  String get homeIntro =>
      'EnergyTwin prognostiziert die deutschen Strompreise mit maschinellem Lernen und macht daraus echte Einsparungen – für Ihre Wärmepumpe, Ihr Solardach und Ihre Haushaltsgeräte.';

  @override
  String get homeLiveBadge => 'Live-Prognose · EPEX SPOT DE-LU';

  @override
  String get homeLiveUnavailable => 'Live-Preise sind nicht verfügbar';

  @override
  String get homeOpenTool => 'Werkzeug öffnen';

  @override
  String get homePlatformEyebrow => 'PLATTFORM';

  @override
  String get homePlatformSubtitle =>
      'Alle Werkzeuge nutzen dieselbe Live-Marktprognose – so bleiben Ihre Entscheidungen stimmig, von der heutigen Wäsche bis zur Solarinvestition über 20 Jahre.';

  @override
  String get homePlatformTitle =>
      'Drei Werkzeuge. Ein Ziel:\nein günstigeres, grüneres Zuhause.';

  @override
  String get homeServerNoResponse =>
      'Der Prognoseserver hat nicht geantwortet.';

  @override
  String get homeStatHorizon => 'Day-Ahead-Horizont';

  @override
  String get homeStatMae => 'Prognosefehler (MAE) je MWh';

  @override
  String get homeStatTools => 'KI-gestützte Werkzeuge';

  @override
  String get homeStatVat => 'MwSt. in den Preisen enthalten';

  @override
  String get homeStepCollect => 'Erfassen';

  @override
  String get homeStepCollectBody =>
      'Erzeugungs-, Last- und Spotpreisdaten fließen von SMARD und der EPEX-SPOT-Day-Ahead-Auktion ein.';

  @override
  String get homeStepOptimize => 'Optimieren';

  @override
  String get homeStepOptimizeBody =>
      'Wärmepumpe, Solaranlage und Geräte werden auf die günstigsten und grünsten Zeitfenster abgestimmt.';

  @override
  String get homeStepPredict => 'Prognostizieren';

  @override
  String get homeStepPredictBody =>
      'Ein Gradient-Boosting-Modell prognostiziert jede Stunde des Folgetags – unter Berücksichtigung von Wind, Sonne und Nachfrage.';

  @override
  String get homeTrust1 => 'XGBoost-Prognosen';

  @override
  String get homeTrust2 => 'Endkundenpreise inkl. MwSt.';

  @override
  String get homeTrust3 => 'Für deutsche Haushalte entwickelt';

  @override
  String get homeWakingUp => 'Prognose-Engine wird gestartet …';

  @override
  String get hourlyHeatmap => 'STÜNDLICHE HEATMAP';

  @override
  String get houseSize => 'Wohnfläche';

  @override
  String get householdHelper => 'Anzahl der Personen im Haushalt';

  @override
  String get householdLabel => 'Haushaltsgröße';

  @override
  String get hpElectricity => 'Strombedarf der Wärmepumpe';

  @override
  String get hpElectricityHint =>
      'Strom, den die Wärmepumpe für den oben genannten Wärmebedarf verbraucht';

  @override
  String get independence => 'Unabhängigkeit';

  @override
  String insightAfter(Object pct) {
    return ' – rund $pct % günstiger als der Tagesdurchschnitt.';
  }

  @override
  String get insightBefore =>
      'verlegen Sie Spülmaschine, Wäsche oder E-Auto-Laden auf ';

  @override
  String get insightPlan => 'Vorausplanen: ';

  @override
  String get insightSmart => 'Unser Tipp: ';

  @override
  String get insulationAverage => 'Durchschnittlich';

  @override
  String get insulationAverageDesc => 'Übliche deutsche Bauweise';

  @override
  String insulationClass(Object level) {
    return 'Dämmklasse · $level';
  }

  @override
  String get insulationClassHint =>
      'Bestimmt die erreichbare JAZ und die Art der Wärmeverteilung (Heizkörper oder Fußbodenheizung)';

  @override
  String get insulationGood => 'Gut';

  @override
  String get insulationGoodDesc => 'Modern, saniert oder Passivhaus';

  @override
  String get insulationPoor => 'Schlecht';

  @override
  String get insulationPoorDesc => 'Vor 1980, kaum gedämmt';

  @override
  String get investmentPayback => 'Amortisationszeit der Investition';

  @override
  String kgValue(Object value) {
    return '$value kg';
  }

  @override
  String get kpiAnnualSavings => 'Jährliche Ersparnis';

  @override
  String get kpiBestHour => 'Günstigste Stunde';

  @override
  String get kpiCo2Avoided => 'Vermiedenes CO₂';

  @override
  String get kpiCurrentPrice => 'Aktueller Preis';

  @override
  String get kpiDailyRange => 'Tagesspanne';

  @override
  String get kpiDayAverage => 'Tagesdurchschnitt';

  @override
  String get kpiNextBestHour => 'Nächste günstige Stunde';

  @override
  String get kpiOpeningPrice => 'Preis um 0 Uhr';

  @override
  String get kpiPanels => 'Module auf Ihrem Dach';

  @override
  String get kpiPayback => 'Amortisationszeit';

  @override
  String get kpiPeakMinusOffPeak => 'Spitze minus Schwachlast';

  @override
  String get kwhPerYear => 'kWh / Jahr';

  @override
  String kwpCapacity(Object kwp) {
    return '$kwp kWp installierte Leistung';
  }

  @override
  String get language => 'Sprache';

  @override
  String get legendCheap => 'Günstig < 15 ct';

  @override
  String get legendMid => 'Mittel 15–25 ct';

  @override
  String get legendPeak => 'Spitze > 25 ct';

  @override
  String get loadingAlmost => 'Gleich geschafft …';

  @override
  String get loadingConnecting => 'Verbindung zum Server wird hergestellt …';

  @override
  String get loadingPrices => 'Preise werden geladen …';

  @override
  String loadingRetry(Object attempt) {
    return 'Neuer Versuch … ($attempt von 3)';
  }

  @override
  String get loadingWarmingUp => 'Der Server startet gerade …';

  @override
  String get metricsExplain =>
      'Unabhängigkeit: Anteil des selbst erzeugten Stroms. Sonnenwert: Standortqualität. Batterienutzen: geschätzter Vorteil eines Heimspeichers.';

  @override
  String get monthlyRelief => 'Monatliche Entlastung';

  @override
  String get monthlyReliefHint => 'Durchschnittliche monatliche Ersparnis';

  @override
  String moreNeeded(Object count) {
    return 'noch $count nötig';
  }

  @override
  String get navAdvisor => 'Berater';

  @override
  String get navHome => 'Start';

  @override
  String get navPrices => 'Preise';

  @override
  String get navSolar => 'Solar-KI';

  @override
  String get netProfit20 => 'Nettogewinn über 20 Jahre';

  @override
  String get netProfit20Hint =>
      'Gesamtertrag nach Abzug der Installationskosten';

  @override
  String get now => 'JETZT';

  @override
  String panelOverlay(Object count, Object area) {
    return 'KI-Modulbelegung – $count Module auf $area m²';
  }

  @override
  String get panelsSuffix => ' Module';

  @override
  String get paybackHint => 'Zeit, bis sich die Investition amortisiert hat';

  @override
  String get peak => 'Spitze';

  @override
  String get peopleSuffix => 'Personen';

  @override
  String get perKwhInclVat => 'pro kWh inkl. MwSt.';

  @override
  String get perMonthShort => '€/Monat';

  @override
  String get perMonthSuffix => '€ / Monat';

  @override
  String get perYearShort => '/Jahr';

  @override
  String get pricesAiForecast => 'XGBoost-KI-Prognose';

  @override
  String get pricesEyebrow => 'DEUTSCHER STROMMARKT';

  @override
  String get pricesFetchingToday =>
      'Die 24-Stunden-Preiskurve für heute wird geladen';

  @override
  String get pricesFetchingTomorrow =>
      'Die 24-Stunden-Preiskurve für morgen wird geladen';

  @override
  String get pricesHeadline =>
      'Was Strom wirklich kostet –\nStunde für Stunde.';

  @override
  String get pricesIntro =>
      'EPEX-SPOT-Großhandelspreise, umgerechnet in Ihren Endkundenpreis – zuzüglich 15 ct Netzentgelte & Abgaben und 19 % MwSt.';

  @override
  String get pricesLiveData => 'Live-Daten von EPEX SPOT';

  @override
  String get pricesLoadError => 'Preise konnten nicht geladen werden';

  @override
  String get pricesSubtitle =>
      'EPEX SPOT DE-LU · Endkundenpreis inkl. Netzentgelte & MwSt.';

  @override
  String get pricesTitle => 'Preisprognose';

  @override
  String get propertyDetails => 'Angaben zur Immobilie';

  @override
  String get propertyDetailsSubtitle =>
      'Geben Sie Ihre Adresse ein, um ein Satellitenbild Ihres Dachs zu laden.';

  @override
  String get propertySubtitle =>
      'Der Betrag wird automatisch geschätzt, wenn Sie Größe und Dämmung anpassen.';

  @override
  String get propertyTitle => 'Ihre Immobilie';

  @override
  String get ready => 'Bereit';

  @override
  String get resultsEyebrow => 'IHRE ERGEBNISSE DES DIGITALEN ZWILLINGS';

  @override
  String get resultsTitle => 'So viel würden Sie sparen.';

  @override
  String get retryConnection => 'Verbindung erneut versuchen';

  @override
  String get rightNow => 'JETZT';

  @override
  String roofArea(Object area) {
    return 'Dachfläche: $area m²';
  }

  @override
  String get runAiAnalysis => 'KI-Analyse starten';

  @override
  String get schedulingSubtitle =>
      'Die KI verlegt die Laufzeit Ihrer Wärmepumpe in die drei günstigsten Zeitfenster des Tages am EPEX-SPOT-Markt – dieselben Preise wie auf Ihrer Preisseite.';

  @override
  String get schedulingTip =>
      'Ein gut gedämmtes Haus hält die Wärme 3–6 Stunden – die Verschiebung bleibt für die Bewohner unbemerkt.';

  @override
  String schedulingTitle(Object amount, Object pct) {
    return 'So spart EnergyTwin zusätzlich $amount/Jahr ($pct %)';
  }

  @override
  String get selectedProperty => 'Ausgewählte Immobilie';

  @override
  String get simulationComplete => 'Simulation abgeschlossen';

  @override
  String get sizeDetached => 'Einfamilienhaus';

  @override
  String get sizeLarge => 'Große Immobilie';

  @override
  String get sizeMediumApartment => 'Mittelgroße Wohnung';

  @override
  String get sizeSemiDetached => 'Doppelhaushälfte';

  @override
  String get sizeSmallApartment => 'Kleine Wohnung';

  @override
  String get solarAddressNotFound => 'Die Adresse wurde nicht gefunden.';

  @override
  String get solarBackendUnreachable => 'Keine Verbindung zum Server.';

  @override
  String get solarChip1 => 'Analyse in 3 Schritten';

  @override
  String get solarChip2 => 'Rendite & Amortisation';

  @override
  String get solarChip3 => 'CO₂-Bilanz';

  @override
  String get solarConnecting => 'Verbindung wird hergestellt …';

  @override
  String get solarFetchingImage => 'Satellitenbild wird geladen …';

  @override
  String get solarFindingRoof => 'Ihr Dach wird gesucht …';

  @override
  String get solarHeadline1 => 'Was Ihr Dach\nIhnen';

  @override
  String get solarHeadline2 => 'einbringen kann.';

  @override
  String get solarIntro =>
      'Geben Sie Ihre Adresse und Energiedaten ein. Wir laden ein Satellitenbild, Sie zeichnen Ihren Dachumriss nach – und unsere KI berechnet Ihr genaues Solarpotenzial und Ihre Rendite.';

  @override
  String get solarNoPanelsFit =>
      'In die gezeichnete Fläche passen keine Solarmodule. Bitte zeichnen Sie die gesamte Dachfläche nach und versuchen Sie es erneut.';

  @override
  String get solarPill =>
      'Sonneneinstrahlung via Open-Meteo · Satellitenbilder';

  @override
  String get solarPotentialTitle => 'Das Solarpotenzial Ihres Dachs.';

  @override
  String get solarRunningAnalysis => 'Solaranalyse läuft …';

  @override
  String get solarRunningSim => 'Solarsimulation läuft …';

  @override
  String get solarServerError => 'Serverfehler. Bitte versuchen Sie es erneut.';

  @override
  String get solarSimFailed =>
      'Die Simulation ist fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get solarSubtitle => 'Satelliten-Dachanalyse · Ertrag & Amortisation';

  @override
  String get solarTapAtLeast3 => 'Tippen Sie mindestens 3 Ecken des Dachs an!';

  @override
  String get solarTitle => 'Solar-KI';

  @override
  String get sourceEpex => 'Quelle: EPEX SPOT DE-LU über Fraunhofer ISE';

  @override
  String get sourceModel =>
      'Quelle: XGBoost-Modell, trainiert mit ENTSO-E-Daten';

  @override
  String get specsTitle => 'Systemdaten';

  @override
  String get startOver => 'Neu beginnen';

  @override
  String get statBreakEven => 'Amortisationszeit';

  @override
  String get statCo2PerYear => 'CO₂ vermieden / Jahr';

  @override
  String get statSavedPerYear => 'Ersparnis pro Jahr';

  @override
  String get statTwentyYears => 'Gesamt über 20 Jahre';

  @override
  String get statusAverage => 'Durchschnitt';

  @override
  String get statusCheapHour => 'Günstige Stunde';

  @override
  String get statusPeakHour => 'Spitzenstunde';

  @override
  String get stepEnterDetails => 'Daten eingeben';

  @override
  String get stepTraceRoof => 'Dach zeichnen';

  @override
  String get stepViewResults => 'Ergebnisse';

  @override
  String get sunScore => 'Sonnenwert';

  @override
  String get systemMetrics => 'Systemkennzahlen';

  @override
  String get tagComputerVision => 'Bilderkennung';

  @override
  String get tagSatellite => 'Satellit';

  @override
  String get tagSmartScheduling => 'Intelligente Steuerung';

  @override
  String get tapRoofCorners => 'Tippen Sie die Ecken Ihres Dachs an';

  @override
  String get themeDark => 'Dunkler Modus';

  @override
  String get themeLight => 'Heller Modus';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String tonsPerYear(Object value) {
    return '$value t/Jahr';
  }

  @override
  String get traceSubtitle =>
      'Tippen Sie die Ecken Ihres Dachs der Reihe nach an – mindestens 3 Punkte.';

  @override
  String get traceTip1 =>
      'Tippen Sie jede Ecke der Dachfläche an, die belegt werden soll.';

  @override
  String get traceTip2 =>
      'Folgen Sie dem Umriss der Reihe nach – im oder gegen den Uhrzeigersinn.';

  @override
  String get traceTip3 => 'Starten Sie die KI-Analyse, sobald die Form passt.';

  @override
  String get traceTitle => 'Dach nachzeichnen';

  @override
  String get treeEquivalent => 'Baum-Äquivalent';

  @override
  String get treeEquivalentHint => 'Entspricht der jährlichen CO₂-Aufnahme';

  @override
  String treesApprox(Object count) {
    return '~$count Bäume';
  }

  @override
  String get treesHint => 'Entspricht der jährlichen CO₂-Aufnahme';

  @override
  String treesPerYear(Object count) {
    return '~$count Bäume/Jahr';
  }

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get typicalDay => 'EIN TYPISCHER TAG';

  @override
  String get undo => 'Rückgängig';

  @override
  String get unitCtKwh => 'ct/kWh';

  @override
  String get windowEveningBody =>
      'Die abendliche Nachfragespitze treibt EPEX auf 30–60 ct/kWh. EnergyTwin pausiert die Wärmepumpe. Die gespeicherte Wärme hält Ihr Zuhause behaglich – ohne Spitzenpreise.';

  @override
  String get windowEveningTitle => 'Abendspitze meiden';

  @override
  String get windowMiddayBody =>
      'Die deutschen Solaranlagen erreichen ihre Spitze, die Preise fallen auf 0 oder werden sogar negativ. EnergyTwin maximiert dann die Laufzeit der Wärmepumpe – praktisch kostenlose Wärme.';

  @override
  String get windowMiddayTitle => 'Solarüberschuss am Mittag';

  @override
  String get windowNightBody =>
      'Windräder laufen die ganze Nacht, der Verbrauch ist aber gering. Die EPEX-Preise fallen auf 5–15 ct/kWh. EnergyTwin lädt die Wärmespeichermasse Ihres Hauses lautlos, während Sie schlafen.';

  @override
  String get windowNightTitle => 'Nächtliches Windtal';

  @override
  String get yearsSuffix => ' J.';

  @override
  String yearsValue(Object value) {
    return '$value Jahre';
  }

  @override
  String get zoneCheap => 'Günstig';

  @override
  String get zoneCheapDesc =>
      'Wärmepumpe laufen lassen, E-Auto laden, Wäsche waschen';

  @override
  String get zoneMid => 'Mittel';

  @override
  String get zoneMidDesc => 'Normaler Verbrauch, Preise im Blick behalten';

  @override
  String get zonePeak => 'Spitze';

  @override
  String get zonePeakDesc => 'Große Verbraucher meiden, Batterie entladen';
}
