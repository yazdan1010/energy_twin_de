import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @addressExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Musterstraße 12, 10115 Berlin'**
  String get addressExample;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, number, postcode, city'**
  String get addressHint;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Property address'**
  String get addressLabel;

  /// No description provided for @adviceBifacial.
  ///
  /// In en, this message translates to:
  /// **'Performance transparency: Due to local cloud fluctuations, the system uses bifacial panels to maximize diffuse light capture.'**
  String get adviceBifacial;

  /// No description provided for @adviceClimateStable.
  ///
  /// In en, this message translates to:
  /// **'Climate audit: Your location shows high solar stability (score: {score}). Winter production risks are evaluated as \'low\'.'**
  String adviceClimateStable(Object score);

  /// No description provided for @adviceFinanceDirect.
  ///
  /// In en, this message translates to:
  /// **'Financial strategy: \'Direct purchase\' highly recommended. With a {profit} net profit over 20 years, this is your property\'s best asset.'**
  String adviceFinanceDirect(Object profit);

  /// No description provided for @adviceFinanceLease.
  ///
  /// In en, this message translates to:
  /// **'Financial strategy: \'Solar lease\'. To mitigate initial risks and enjoy full maintenance coverage, an OpEx model is more efficient for your profile.'**
  String get adviceFinanceLease;

  /// No description provided for @adviceFinanceLoan.
  ///
  /// In en, this message translates to:
  /// **'Financial strategy: \'Financing model\'. Your annual savings exceed loan installments, allowing the system to pay for itself.'**
  String get adviceFinanceLoan;

  /// No description provided for @adviceIndependenceHigh.
  ///
  /// In en, this message translates to:
  /// **'Energy independence: Outstanding! You will achieve {autarky}% independence from the grid, creating a solid hedge against German electricity inflation.'**
  String adviceIndependenceHigh(Object autarky);

  /// No description provided for @adviceIndependenceLow.
  ///
  /// In en, this message translates to:
  /// **'Consumption audit: Due to high household consumption, your autarky is {autarky}%. We recommend shifting heavy appliance usage to peak sun hours (11:00–15:00).'**
  String adviceIndependenceLow(Object autarky);

  /// No description provided for @adviceInsulation.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure upgrade: Your building\'s energy rating ({rating}) is low. Attic insulation is recommended to boost your solar ROI by an estimated 8%.'**
  String adviceInsulation(Object rating);

  /// No description provided for @adviceSustainability.
  ///
  /// In en, this message translates to:
  /// **'Sustainability: This system offsets {co2} tons of CO₂ annually, equivalent to planting {trees} mature trees. Status: \'{grade}\'.'**
  String adviceSustainability(Object co2, Object trees, Object grade);

  /// No description provided for @adviceTeamMeister.
  ///
  /// In en, this message translates to:
  /// **'Execution team: A tier-1 \'Solar-Meister\' from your region will be assigned to oversee high-load calibration and VDE compliance.'**
  String get adviceTeamMeister;

  /// No description provided for @adviceTeamRegional.
  ///
  /// In en, this message translates to:
  /// **'Installation team: Certified regional contractors are prioritized for rapid deployment and local grid synchronization.'**
  String get adviceTeamRegional;

  /// No description provided for @advisorCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get advisorCalculating;

  /// No description provided for @advisorChip1.
  ///
  /// In en, this message translates to:
  /// **'3–4× more efficient than gas'**
  String get advisorChip1;

  /// No description provided for @advisorChip2.
  ///
  /// In en, this message translates to:
  /// **'AI off-peak scheduling'**
  String get advisorChip2;

  /// No description provided for @advisorChip3.
  ///
  /// In en, this message translates to:
  /// **'Up to 80% less CO₂'**
  String get advisorChip3;

  /// No description provided for @advisorChip4.
  ///
  /// In en, this message translates to:
  /// **'€15k install, BAFA subsidy eligible'**
  String get advisorChip4;

  /// No description provided for @advisorHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Swap your gas boiler\nfor a'**
  String get advisorHeadline1;

  /// No description provided for @advisorHeadline2.
  ///
  /// In en, this message translates to:
  /// **'smart heat pump.'**
  String get advisorHeadline2;

  /// No description provided for @advisorIntro.
  ///
  /// In en, this message translates to:
  /// **'Replace your gas boiler with a smart heat pump and let EnergyTwin\'s AI schedule heating around cheap electricity windows. Enter your property details to see your exact savings.'**
  String get advisorIntro;

  /// No description provided for @advisorInvalidBill.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid monthly bill.'**
  String get advisorInvalidBill;

  /// No description provided for @advisorPill.
  ///
  /// In en, this message translates to:
  /// **'Powered by live EPEX SPOT market data'**
  String get advisorPill;

  /// No description provided for @advisorRunningTwin.
  ///
  /// In en, this message translates to:
  /// **'Running Digital Twin simulation…'**
  String get advisorRunningTwin;

  /// No description provided for @advisorServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error {code}.'**
  String advisorServerError(Object code);

  /// No description provided for @advisorSimEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR SIMULATION'**
  String get advisorSimEyebrow;

  /// No description provided for @advisorSimSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three inputs are all the Digital Twin needs to model your heating demand.'**
  String get advisorSimSubtitle;

  /// No description provided for @advisorSimTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your home.'**
  String get advisorSimTitle;

  /// No description provided for @advisorStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Burns natural gas at ~85% efficiency. German gas costs ~€0.10/kWh. Heating a typical home produces 1,200–2,400 kg of CO₂ every year.'**
  String get advisorStep1Body;

  /// No description provided for @advisorStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Your gas boiler today'**
  String get advisorStep1Title;

  /// No description provided for @advisorStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Moves heat from outdoor air using a small amount of electricity. A COP of 3.5 means 1 kWh in → 3.5 kWh of heat out — far more efficient than any combustion boiler.'**
  String get advisorStep2Body;

  /// No description provided for @advisorStep2Title.
  ///
  /// In en, this message translates to:
  /// **'The heat pump upgrade'**
  String get advisorStep2Title;

  /// No description provided for @advisorStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Our AI monitors German EPEX SPOT prices and pre-heats your home during cheap windows (overnight wind surplus, midday solar dip) — saving an extra 40% on electricity.'**
  String get advisorStep3Body;

  /// No description provided for @advisorStep3Title.
  ///
  /// In en, this message translates to:
  /// **'EnergyTwin AI scheduling'**
  String get advisorStep3Title;

  /// No description provided for @advisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ROI simulation · AI off-peak scheduling'**
  String get advisorSubtitle;

  /// No description provided for @advisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Heat Pump Advisor'**
  String get advisorTitle;

  /// No description provided for @advisorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach server after 3 attempts.'**
  String get advisorUnreachable;

  /// No description provided for @advisorWhyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WHY IT PAYS OFF'**
  String get advisorWhyEyebrow;

  /// No description provided for @advisorWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'From burning gas to\nsmart, scheduled heat.'**
  String get advisorWhyTitle;

  /// No description provided for @advisorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations from EnergyTwin\'s solar analysis engine'**
  String get advisorySubtitle;

  /// No description provided for @advisoryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI strategic advisory'**
  String get advisoryTitle;

  /// No description provided for @analysisComplete.
  ///
  /// In en, this message translates to:
  /// **'ANALYSIS COMPLETE'**
  String get analysisComplete;

  /// No description provided for @analyzeAnother.
  ///
  /// In en, this message translates to:
  /// **'Analyze another property'**
  String get analyzeAnother;

  /// No description provided for @analyzedProperty.
  ///
  /// In en, this message translates to:
  /// **'ANALYZED PROPERTY'**
  String get analyzedProperty;

  /// No description provided for @analyzedRoof.
  ///
  /// In en, this message translates to:
  /// **'Analyzed roof'**
  String get analyzedRoof;

  /// No description provided for @annualElecSavings.
  ///
  /// In en, this message translates to:
  /// **'Annual electricity savings'**
  String get annualElecSavings;

  /// No description provided for @annualHeatDemand.
  ///
  /// In en, this message translates to:
  /// **'Annual heat demand'**
  String get annualHeatDemand;

  /// No description provided for @annualHeatDemandHint.
  ///
  /// In en, this message translates to:
  /// **'Total thermal energy your home needs for heating — derived from gas consumption × 85% boiler efficiency'**
  String get annualHeatDemandHint;

  /// No description provided for @annualSavingsHint.
  ///
  /// In en, this message translates to:
  /// **'Yearly reduction in electricity bill'**
  String get annualSavingsHint;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EnergyTwin | AI Command Center'**
  String get appTitle;

  /// No description provided for @asmBoiler.
  ///
  /// In en, this message translates to:
  /// **'Gas boiler efficiency'**
  String get asmBoiler;

  /// No description provided for @asmBoilerHint.
  ///
  /// In en, this message translates to:
  /// **'Typical old condensing boiler'**
  String get asmBoilerHint;

  /// No description provided for @asmBoilerValue.
  ///
  /// In en, this message translates to:
  /// **'85%'**
  String get asmBoilerValue;

  /// No description provided for @asmGasCo2.
  ///
  /// In en, this message translates to:
  /// **'Gas CO₂ intensity'**
  String get asmGasCo2;

  /// No description provided for @asmGasCo2Hint.
  ///
  /// In en, this message translates to:
  /// **'Direct natural gas emissions'**
  String get asmGasCo2Hint;

  /// No description provided for @asmGasCo2Value.
  ///
  /// In en, this message translates to:
  /// **'0.20 kg / kWh'**
  String get asmGasCo2Value;

  /// No description provided for @asmGasPrice.
  ///
  /// In en, this message translates to:
  /// **'Gas price'**
  String get asmGasPrice;

  /// No description provided for @asmGasPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Current German residential tariff'**
  String get asmGasPriceHint;

  /// No description provided for @asmGasPriceValue.
  ///
  /// In en, this message translates to:
  /// **'€0.10 / kWh'**
  String get asmGasPriceValue;

  /// No description provided for @asmGridCo2.
  ///
  /// In en, this message translates to:
  /// **'Grid CO₂ intensity'**
  String get asmGridCo2;

  /// No description provided for @asmGridCo2Hint.
  ///
  /// In en, this message translates to:
  /// **'German electricity mix, 2024'**
  String get asmGridCo2Hint;

  /// No description provided for @asmGridCo2Value.
  ///
  /// In en, this message translates to:
  /// **'0.35 kg / kWh'**
  String get asmGridCo2Value;

  /// No description provided for @asmInstall.
  ///
  /// In en, this message translates to:
  /// **'Installation cost'**
  String get asmInstall;

  /// No description provided for @asmInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Net after BAFA subsidy (up to €18,750)'**
  String get asmInstallHint;

  /// No description provided for @asmInstallValue.
  ///
  /// In en, this message translates to:
  /// **'€15,000'**
  String get asmInstallValue;

  /// No description provided for @asmSmartRate.
  ///
  /// In en, this message translates to:
  /// **'Smart rate (EnergyTwin)'**
  String get asmSmartRate;

  /// No description provided for @asmSmartRateHint.
  ///
  /// In en, this message translates to:
  /// **'Off-peak EPEX SPOT average'**
  String get asmSmartRateHint;

  /// No description provided for @asmSmartRateValue.
  ///
  /// In en, this message translates to:
  /// **'€0.18 / kWh'**
  String get asmSmartRateValue;

  /// No description provided for @asmStdElec.
  ///
  /// In en, this message translates to:
  /// **'Standard electricity'**
  String get asmStdElec;

  /// No description provided for @asmStdElecHint.
  ///
  /// In en, this message translates to:
  /// **'Average German household rate'**
  String get asmStdElecHint;

  /// No description provided for @asmStdElecValue.
  ///
  /// In en, this message translates to:
  /// **'€0.30 / kWh'**
  String get asmStdElecValue;

  /// No description provided for @assumptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent methodology — Germany 2024 data.'**
  String get assumptionsSubtitle;

  /// No description provided for @assumptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Model assumptions'**
  String get assumptionsTitle;

  /// No description provided for @backToTracing.
  ///
  /// In en, this message translates to:
  /// **'Back to tracing'**
  String get backToTracing;

  /// No description provided for @bafaEligible.
  ///
  /// In en, this message translates to:
  /// **'BAFA-eligible system — qualifies for German state subsidy'**
  String get bafaEligible;

  /// No description provided for @batteryValue.
  ///
  /// In en, this message translates to:
  /// **'Battery value'**
  String get batteryValue;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @buildingInsulation.
  ///
  /// In en, this message translates to:
  /// **'Building insulation'**
  String get buildingInsulation;

  /// No description provided for @calculateSavings.
  ///
  /// In en, this message translates to:
  /// **'Calculate my savings'**
  String get calculateSavings;

  /// No description provided for @carsHint.
  ///
  /// In en, this message translates to:
  /// **'Taken off the road equivalent'**
  String get carsHint;

  /// No description provided for @carsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} cars'**
  String carsValue(Object count);

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get changeAddress;

  /// No description provided for @chartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hover or tap the curve for exact prices'**
  String get chartSubtitle;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Hourly price curve'**
  String get chartTitle;

  /// No description provided for @cheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get cheapest;

  /// No description provided for @clearCount.
  ///
  /// In en, this message translates to:
  /// **'Clear ({count})'**
  String clearCount(Object count);

  /// No description provided for @co2Eliminated.
  ///
  /// In en, this message translates to:
  /// **'CO₂ eliminated'**
  String get co2Eliminated;

  /// No description provided for @co2EliminatedHint.
  ///
  /// In en, this message translates to:
  /// **'Annual carbon emissions prevented'**
  String get co2EliminatedHint;

  /// No description provided for @co2LessThanGas.
  ///
  /// In en, this message translates to:
  /// **'{pct}% less CO₂ than gas'**
  String co2LessThanGas(Object pct);

  /// No description provided for @co2PerYear.
  ///
  /// In en, this message translates to:
  /// **'CO₂ eliminated per year'**
  String get co2PerYear;

  /// No description provided for @co2ReductionVsGas.
  ///
  /// In en, this message translates to:
  /// **'CO₂ reduction vs. your gas boiler'**
  String get co2ReductionVsGas;

  /// No description provided for @co2SavedPerYear.
  ///
  /// In en, this message translates to:
  /// **'CO₂ saved per year'**
  String get co2SavedPerYear;

  /// No description provided for @copAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Acceptable'**
  String get copAcceptable;

  /// No description provided for @copExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get copExcellent;

  /// No description provided for @copFull.
  ///
  /// In en, this message translates to:
  /// **'Coefficient of performance'**
  String get copFull;

  /// No description provided for @copFullHint.
  ///
  /// In en, this message translates to:
  /// **'1 kWh electricity → {cop}x kWh of heat. Depends on insulation quality and system design.'**
  String copFullHint(Object cop);

  /// No description provided for @copGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get copGood;

  /// No description provided for @copHintAverage.
  ///
  /// In en, this message translates to:
  /// **'COP ≈ 3.5  ·  typical German installation'**
  String get copHintAverage;

  /// No description provided for @copHintGood.
  ///
  /// In en, this message translates to:
  /// **'COP ≈ 4.2  ·  excellent with underfloor heating'**
  String get copHintGood;

  /// No description provided for @copHintPoor.
  ///
  /// In en, this message translates to:
  /// **'COP ≈ 2.8  ·  needs higher water temps'**
  String get copHintPoor;

  /// No description provided for @copLabel.
  ///
  /// In en, this message translates to:
  /// **'COP · {rating}'**
  String copLabel(Object rating);

  /// No description provided for @cornerPlaced.
  ///
  /// In en, this message translates to:
  /// **'corner placed'**
  String get cornerPlaced;

  /// No description provided for @cornersPlaced.
  ///
  /// In en, this message translates to:
  /// **'corners placed'**
  String get cornersPlaced;

  /// No description provided for @costGas.
  ///
  /// In en, this message translates to:
  /// **'Gas Boiler'**
  String get costGas;

  /// No description provided for @costGasDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current system — gas burned at 85% efficiency'**
  String get costGasDesc;

  /// No description provided for @costSmartHp.
  ///
  /// In en, this message translates to:
  /// **'EnergyTwin Smart Heat Pump'**
  String get costSmartHp;

  /// No description provided for @costSmartHpDesc.
  ///
  /// In en, this message translates to:
  /// **'AI shifts load to off-peak windows — avg €0.18/kWh'**
  String get costSmartHpDesc;

  /// No description provided for @costStdHp.
  ///
  /// In en, this message translates to:
  /// **'Standard Heat Pump'**
  String get costStdHp;

  /// No description provided for @costStdHpDesc.
  ///
  /// In en, this message translates to:
  /// **'Off-the-shelf install, billed at flat €0.30/kWh tariff'**
  String get costStdHpDesc;

  /// No description provided for @costSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same warmth — three very different heating strategies.'**
  String get costSubtitle;

  /// No description provided for @costTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual cost comparison'**
  String get costTitle;

  /// No description provided for @ctPerKwhValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ct/kWh'**
  String ctPerKwhValue(Object value);

  /// No description provided for @ctValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ct'**
  String ctValue(Object value);

  /// No description provided for @ecoClimateHero.
  ///
  /// In en, this message translates to:
  /// **'Climate Hero'**
  String get ecoClimateHero;

  /// No description provided for @ecoGradeHint.
  ///
  /// In en, this message translates to:
  /// **'Sustainability rating for this system'**
  String get ecoGradeHint;

  /// No description provided for @ecoGradeTitle.
  ///
  /// In en, this message translates to:
  /// **'EnergyTwin eco grade'**
  String get ecoGradeTitle;

  /// No description provided for @ecoWarrior.
  ///
  /// In en, this message translates to:
  /// **'Eco-Warrior'**
  String get ecoWarrior;

  /// No description provided for @elecBillHelper.
  ///
  /// In en, this message translates to:
  /// **'Average monthly bill in euros'**
  String get elecBillHelper;

  /// No description provided for @elecBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly electricity bill'**
  String get elecBillLabel;

  /// No description provided for @energyClassHelper.
  ///
  /// In en, this message translates to:
  /// **'EU energy label A (best) – G (worst)'**
  String get energyClassHelper;

  /// No description provided for @energyClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy efficiency class'**
  String get energyClassLabel;

  /// No description provided for @energyClassSemantics.
  ///
  /// In en, this message translates to:
  /// **'Energy class {letter}'**
  String energyClassSemantics(Object letter);

  /// No description provided for @envTitle.
  ///
  /// In en, this message translates to:
  /// **'Environmental impact'**
  String get envTitle;

  /// No description provided for @errorServerCode.
  ///
  /// In en, this message translates to:
  /// **'Server returned error {code}. Please try again.'**
  String errorServerCode(Object code);

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach server after 3 attempts. Check your connection.'**
  String get errorUnreachable;

  /// No description provided for @fetchSatellite.
  ///
  /// In en, this message translates to:
  /// **'Fetch satellite image'**
  String get fetchSatellite;

  /// No description provided for @financialTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial overview'**
  String get financialTitle;

  /// No description provided for @fiveCheapestHours.
  ///
  /// In en, this message translates to:
  /// **'FIVE CHEAPEST HOURS'**
  String get fiveCheapestHours;

  /// No description provided for @gasBillHelper.
  ///
  /// In en, this message translates to:
  /// **'Your average monthly gas or district heating bill'**
  String get gasBillHelper;

  /// No description provided for @gasBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly heating / gas bill'**
  String get gasBillLabel;

  /// No description provided for @gridPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Your current tariff in ct/kWh'**
  String get gridPriceHelper;

  /// No description provided for @gridPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Grid electricity price'**
  String get gridPriceLabel;

  /// No description provided for @guideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Retail = wholesale + 15 ct grid/tax + 19% VAT'**
  String get guideSubtitle;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Price guide'**
  String get guideTitle;

  /// No description provided for @homeAboveAverage.
  ///
  /// In en, this message translates to:
  /// **'{pct}% above today\'s average of {avg} ct'**
  String homeAboveAverage(Object pct, Object avg);

  /// No description provided for @homeBelowAverage.
  ///
  /// In en, this message translates to:
  /// **'{pct}% below today\'s average of {avg} ct'**
  String homeBelowAverage(Object pct, Object avg);

  /// No description provided for @homeCtaBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a few details about your home and get a personalised savings estimate in under a minute.'**
  String get homeCtaBody;

  /// No description provided for @homeCtaButton.
  ///
  /// In en, this message translates to:
  /// **'Start with the Advisor'**
  String get homeCtaButton;

  /// No description provided for @homeCtaPrices.
  ///
  /// In en, this message translates to:
  /// **'Explore live prices'**
  String get homeCtaPrices;

  /// No description provided for @homeCtaSavings.
  ///
  /// In en, this message translates to:
  /// **'Calculate my savings'**
  String get homeCtaSavings;

  /// No description provided for @homeCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to see what you could save?'**
  String get homeCtaTitle;

  /// No description provided for @homeFeatureAdvisorBody.
  ///
  /// In en, this message translates to:
  /// **'Find out what replacing your gas boiler really saves, and how AI scheduling around cheap windows adds even more.'**
  String get homeFeatureAdvisorBody;

  /// No description provided for @homeFeatureAdvisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Heat Pump Advisor'**
  String get homeFeatureAdvisorTitle;

  /// No description provided for @homeFeaturePricesBody.
  ///
  /// In en, this message translates to:
  /// **'Day-ahead prices for today and tomorrow, converted into what you actually pay per kWh — with the cheapest hours highlighted.'**
  String get homeFeaturePricesBody;

  /// No description provided for @homeFeaturePricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Forecast'**
  String get homeFeaturePricesTitle;

  /// No description provided for @homeFeatureSolarBody.
  ///
  /// In en, this message translates to:
  /// **'Trace your roof on satellite imagery and get AI panel placement, yearly yield and payback estimates in seconds.'**
  String get homeFeatureSolarBody;

  /// No description provided for @homeFeatureSolarTitle.
  ///
  /// In en, this message translates to:
  /// **'Solar AI'**
  String get homeFeatureSolarTitle;

  /// No description provided for @homeFooterSources.
  ///
  /// In en, this message translates to:
  /// **'Market data: SMARD.de · EPEX SPOT. Prices shown are forecasts, not tariffs.'**
  String get homeFooterSources;

  /// No description provided for @homeFullForecast.
  ///
  /// In en, this message translates to:
  /// **'Full forecast for today & tomorrow'**
  String get homeFullForecast;

  /// No description provided for @homeHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Power your home\nat the'**
  String get homeHeadline1;

  /// No description provided for @homeHeadline2.
  ///
  /// In en, this message translates to:
  /// **'smartest hour.'**
  String get homeHeadline2;

  /// No description provided for @homeHowEyebrow.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get homeHowEyebrow;

  /// No description provided for @homeHowTitle.
  ///
  /// In en, this message translates to:
  /// **'From market data\nto money saved.'**
  String get homeHowTitle;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'EnergyTwin forecasts German electricity prices with machine learning and turns them into real savings for your heat pump, solar roof and everyday appliances.'**
  String get homeIntro;

  /// No description provided for @homeLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live forecast · EPEX SPOT DE-LU'**
  String get homeLiveBadge;

  /// No description provided for @homeLiveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live prices are unavailable'**
  String get homeLiveUnavailable;

  /// No description provided for @homeOpenTool.
  ///
  /// In en, this message translates to:
  /// **'Open tool'**
  String get homeOpenTool;

  /// No description provided for @homePlatformEyebrow.
  ///
  /// In en, this message translates to:
  /// **'PLATFORM'**
  String get homePlatformEyebrow;

  /// No description provided for @homePlatformSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every tool runs on the same live market forecast, so your decisions stay consistent from today\'s laundry to a 20-year solar investment.'**
  String get homePlatformSubtitle;

  /// No description provided for @homePlatformTitle.
  ///
  /// In en, this message translates to:
  /// **'Three tools. One goal:\na cheaper, greener home.'**
  String get homePlatformTitle;

  /// No description provided for @homeServerNoResponse.
  ///
  /// In en, this message translates to:
  /// **'The forecast server didn\'t respond.'**
  String get homeServerNoResponse;

  /// No description provided for @homeStatHorizon.
  ///
  /// In en, this message translates to:
  /// **'Day-ahead horizon'**
  String get homeStatHorizon;

  /// No description provided for @homeStatMae.
  ///
  /// In en, this message translates to:
  /// **'Forecast MAE per MWh'**
  String get homeStatMae;

  /// No description provided for @homeStatTools.
  ///
  /// In en, this message translates to:
  /// **'AI-powered tools'**
  String get homeStatTools;

  /// No description provided for @homeStatVat.
  ///
  /// In en, this message translates to:
  /// **'VAT included in prices'**
  String get homeStatVat;

  /// No description provided for @homeStepCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get homeStepCollect;

  /// No description provided for @homeStepCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Generation, load and spot-price data stream in from SMARD and the EPEX SPOT day-ahead auction.'**
  String get homeStepCollectBody;

  /// No description provided for @homeStepOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get homeStepOptimize;

  /// No description provided for @homeStepOptimizeBody.
  ///
  /// In en, this message translates to:
  /// **'Your heat pump, solar and appliances are planned around the cheapest, greenest windows.'**
  String get homeStepOptimizeBody;

  /// No description provided for @homeStepPredict.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get homeStepPredict;

  /// No description provided for @homeStepPredictBody.
  ///
  /// In en, this message translates to:
  /// **'A gradient-boosted model forecasts every hour of the coming day, accounting for wind, solar and demand.'**
  String get homeStepPredictBody;

  /// No description provided for @homeTrust1.
  ///
  /// In en, this message translates to:
  /// **'XGBoost forecasting'**
  String get homeTrust1;

  /// No description provided for @homeTrust2.
  ///
  /// In en, this message translates to:
  /// **'Retail prices incl. VAT'**
  String get homeTrust2;

  /// No description provided for @homeTrust3.
  ///
  /// In en, this message translates to:
  /// **'Built for German homes'**
  String get homeTrust3;

  /// No description provided for @homeWakingUp.
  ///
  /// In en, this message translates to:
  /// **'Waking up the forecast engine…'**
  String get homeWakingUp;

  /// No description provided for @hourlyHeatmap.
  ///
  /// In en, this message translates to:
  /// **'HOURLY HEATMAP'**
  String get hourlyHeatmap;

  /// No description provided for @houseSize.
  ///
  /// In en, this message translates to:
  /// **'House size'**
  String get houseSize;

  /// No description provided for @householdHelper.
  ///
  /// In en, this message translates to:
  /// **'Number of people living there'**
  String get householdHelper;

  /// No description provided for @householdLabel.
  ///
  /// In en, this message translates to:
  /// **'Household size'**
  String get householdLabel;

  /// No description provided for @hpElectricity.
  ///
  /// In en, this message translates to:
  /// **'Heat pump electricity'**
  String get hpElectricity;

  /// No description provided for @hpElectricityHint.
  ///
  /// In en, this message translates to:
  /// **'Electricity the heat pump consumes to deliver the heat demand above'**
  String get hpElectricityHint;

  /// No description provided for @independence.
  ///
  /// In en, this message translates to:
  /// **'Independence'**
  String get independence;

  /// No description provided for @insightAfter.
  ///
  /// In en, this message translates to:
  /// **' — about {pct}% cheaper than the daily average.'**
  String insightAfter(Object pct);

  /// No description provided for @insightBefore.
  ///
  /// In en, this message translates to:
  /// **'shift your dishwasher, laundry or EV charging to '**
  String get insightBefore;

  /// No description provided for @insightPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan ahead: '**
  String get insightPlan;

  /// No description provided for @insightSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart move: '**
  String get insightSmart;

  /// No description provided for @insulationAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get insulationAverage;

  /// No description provided for @insulationAverageDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard German construction'**
  String get insulationAverageDesc;

  /// No description provided for @insulationClass.
  ///
  /// In en, this message translates to:
  /// **'Insulation class · {level}'**
  String insulationClass(Object level);

  /// No description provided for @insulationClassHint.
  ///
  /// In en, this message translates to:
  /// **'Determines achievable COP and heat distribution type (radiators vs. underfloor heating)'**
  String get insulationClassHint;

  /// No description provided for @insulationGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get insulationGood;

  /// No description provided for @insulationGoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern, renovated or passive'**
  String get insulationGoodDesc;

  /// No description provided for @insulationPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get insulationPoor;

  /// No description provided for @insulationPoorDesc.
  ///
  /// In en, this message translates to:
  /// **'Pre-1980, minimal insulation'**
  String get insulationPoorDesc;

  /// No description provided for @investmentPayback.
  ///
  /// In en, this message translates to:
  /// **'Investment payback period'**
  String get investmentPayback;

  /// No description provided for @kgValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String kgValue(Object value);

  /// No description provided for @kpiAnnualSavings.
  ///
  /// In en, this message translates to:
  /// **'Annual savings'**
  String get kpiAnnualSavings;

  /// No description provided for @kpiBestHour.
  ///
  /// In en, this message translates to:
  /// **'Best hour'**
  String get kpiBestHour;

  /// No description provided for @kpiCo2Avoided.
  ///
  /// In en, this message translates to:
  /// **'CO₂ avoided'**
  String get kpiCo2Avoided;

  /// No description provided for @kpiCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get kpiCurrentPrice;

  /// No description provided for @kpiDailyRange.
  ///
  /// In en, this message translates to:
  /// **'Daily range'**
  String get kpiDailyRange;

  /// No description provided for @kpiDayAverage.
  ///
  /// In en, this message translates to:
  /// **'Day average'**
  String get kpiDayAverage;

  /// No description provided for @kpiNextBestHour.
  ///
  /// In en, this message translates to:
  /// **'Next best hour'**
  String get kpiNextBestHour;

  /// No description provided for @kpiOpeningPrice.
  ///
  /// In en, this message translates to:
  /// **'Opening price'**
  String get kpiOpeningPrice;

  /// No description provided for @kpiPanels.
  ///
  /// In en, this message translates to:
  /// **'Panels on your roof'**
  String get kpiPanels;

  /// No description provided for @kpiPayback.
  ///
  /// In en, this message translates to:
  /// **'Payback period'**
  String get kpiPayback;

  /// No description provided for @kpiPeakMinusOffPeak.
  ///
  /// In en, this message translates to:
  /// **'peak minus off-peak'**
  String get kpiPeakMinusOffPeak;

  /// No description provided for @kwhPerYear.
  ///
  /// In en, this message translates to:
  /// **'kWh / yr'**
  String get kwhPerYear;

  /// No description provided for @kwpCapacity.
  ///
  /// In en, this message translates to:
  /// **'{kwp} kWp installed capacity'**
  String kwpCapacity(Object kwp);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @legendCheap.
  ///
  /// In en, this message translates to:
  /// **'Cheap < 15 ct'**
  String get legendCheap;

  /// No description provided for @legendMid.
  ///
  /// In en, this message translates to:
  /// **'Mid 15–25 ct'**
  String get legendMid;

  /// No description provided for @legendPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak > 25 ct'**
  String get legendPeak;

  /// No description provided for @loadingAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there…'**
  String get loadingAlmost;

  /// No description provided for @loadingConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server…'**
  String get loadingConnecting;

  /// No description provided for @loadingPrices.
  ///
  /// In en, this message translates to:
  /// **'Loading prices…'**
  String get loadingPrices;

  /// No description provided for @loadingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retrying… (attempt {attempt} of 3)'**
  String loadingRetry(Object attempt);

  /// No description provided for @loadingWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Server is warming up…'**
  String get loadingWarmingUp;

  /// No description provided for @metricsExplain.
  ///
  /// In en, this message translates to:
  /// **'Independence: % of electricity self-produced. Sun Score: location quality. Battery Value: estimated benefit of adding a home battery.'**
  String get metricsExplain;

  /// No description provided for @monthlyRelief.
  ///
  /// In en, this message translates to:
  /// **'Monthly relief'**
  String get monthlyRelief;

  /// No description provided for @monthlyReliefHint.
  ///
  /// In en, this message translates to:
  /// **'Average monthly bill reduction'**
  String get monthlyReliefHint;

  /// No description provided for @moreNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} more needed'**
  String moreNeeded(Object count);

  /// No description provided for @navAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Advisor'**
  String get navAdvisor;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get navPrices;

  /// No description provided for @navSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar AI'**
  String get navSolar;

  /// No description provided for @netProfit20.
  ///
  /// In en, this message translates to:
  /// **'20-year net profit'**
  String get netProfit20;

  /// No description provided for @netProfit20Hint.
  ///
  /// In en, this message translates to:
  /// **'Total earnings after installation cost'**
  String get netProfit20Hint;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now;

  /// No description provided for @panelOverlay.
  ///
  /// In en, this message translates to:
  /// **'AI panel placement overlay — {count} panels on {area} m²'**
  String panelOverlay(Object count, Object area);

  /// No description provided for @panelsSuffix.
  ///
  /// In en, this message translates to:
  /// **' panels'**
  String get panelsSuffix;

  /// No description provided for @paybackHint.
  ///
  /// In en, this message translates to:
  /// **'Time to recoup installation investment'**
  String get paybackHint;

  /// No description provided for @peak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get peak;

  /// No description provided for @peopleSuffix.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get peopleSuffix;

  /// No description provided for @perKwhInclVat.
  ///
  /// In en, this message translates to:
  /// **'per kWh incl. VAT'**
  String get perKwhInclVat;

  /// No description provided for @perMonthShort.
  ///
  /// In en, this message translates to:
  /// **'€/mo'**
  String get perMonthShort;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'€ / month'**
  String get perMonthSuffix;

  /// No description provided for @perYearShort.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get perYearShort;

  /// No description provided for @pricesAiForecast.
  ///
  /// In en, this message translates to:
  /// **'XGBoost AI forecast'**
  String get pricesAiForecast;

  /// No description provided for @pricesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'GERMAN ELECTRICITY MARKET'**
  String get pricesEyebrow;

  /// No description provided for @pricesFetchingToday.
  ///
  /// In en, this message translates to:
  /// **'Fetching today\'s 24-hour price curve'**
  String get pricesFetchingToday;

  /// No description provided for @pricesFetchingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Fetching tomorrow\'s 24-hour price curve'**
  String get pricesFetchingTomorrow;

  /// No description provided for @pricesHeadline.
  ///
  /// In en, this message translates to:
  /// **'What power really costs,\nhour by hour.'**
  String get pricesHeadline;

  /// No description provided for @pricesIntro.
  ///
  /// In en, this message translates to:
  /// **'Wholesale EPEX SPOT prices converted to your retail price — plus 15 ct grid fees & taxes and 19% VAT.'**
  String get pricesIntro;

  /// No description provided for @pricesLiveData.
  ///
  /// In en, this message translates to:
  /// **'Live EPEX SPOT data'**
  String get pricesLiveData;

  /// No description provided for @pricesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load prices'**
  String get pricesLoadError;

  /// No description provided for @pricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'EPEX SPOT DE-LU · retail incl. grid fees & VAT'**
  String get pricesSubtitle;

  /// No description provided for @pricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Forecast'**
  String get pricesTitle;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get propertyDetails;

  /// No description provided for @propertyDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your address to fetch a satellite image of your roof.'**
  String get propertyDetailsSubtitle;

  /// No description provided for @propertySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The bill auto-estimates as you adjust size and insulation.'**
  String get propertySubtitle;

  /// No description provided for @propertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your property'**
  String get propertyTitle;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @resultsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR DIGITAL TWIN RESULTS'**
  String get resultsEyebrow;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what you\'d save.'**
  String get resultsTitle;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry connection'**
  String get retryConnection;

  /// No description provided for @rightNow.
  ///
  /// In en, this message translates to:
  /// **'RIGHT NOW'**
  String get rightNow;

  /// No description provided for @roofArea.
  ///
  /// In en, this message translates to:
  /// **'Roof area: {area} m²'**
  String roofArea(Object area);

  /// No description provided for @runAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Run AI analysis'**
  String get runAiAnalysis;

  /// No description provided for @schedulingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI shifts your heat pump runtime to the three cheapest daily windows on the German EPEX SPOT market — the same prices shown on your Prices screen.'**
  String get schedulingSubtitle;

  /// No description provided for @schedulingTip.
  ///
  /// In en, this message translates to:
  /// **'A well-insulated home retains heat for 3–6 hours, making schedule shifting painless and invisible to occupants.'**
  String get schedulingTip;

  /// No description provided for @schedulingTitle.
  ///
  /// In en, this message translates to:
  /// **'How EnergyTwin saves an extra {amount}/yr ({pct}%)'**
  String schedulingTitle(Object amount, Object pct);

  /// No description provided for @selectedProperty.
  ///
  /// In en, this message translates to:
  /// **'Selected property'**
  String get selectedProperty;

  /// No description provided for @simulationComplete.
  ///
  /// In en, this message translates to:
  /// **'Simulation complete'**
  String get simulationComplete;

  /// No description provided for @sizeDetached.
  ///
  /// In en, this message translates to:
  /// **'Detached house'**
  String get sizeDetached;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large property'**
  String get sizeLarge;

  /// No description provided for @sizeMediumApartment.
  ///
  /// In en, this message translates to:
  /// **'Medium apartment'**
  String get sizeMediumApartment;

  /// No description provided for @sizeSemiDetached.
  ///
  /// In en, this message translates to:
  /// **'Semi-detached'**
  String get sizeSemiDetached;

  /// No description provided for @sizeSmallApartment.
  ///
  /// In en, this message translates to:
  /// **'Small apartment'**
  String get sizeSmallApartment;

  /// No description provided for @solarAddressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find address.'**
  String get solarAddressNotFound;

  /// No description provided for @solarBackendUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to backend.'**
  String get solarBackendUnreachable;

  /// No description provided for @solarChip1.
  ///
  /// In en, this message translates to:
  /// **'3-step analysis'**
  String get solarChip1;

  /// No description provided for @solarChip2.
  ///
  /// In en, this message translates to:
  /// **'ROI & payback calc'**
  String get solarChip2;

  /// No description provided for @solarChip3.
  ///
  /// In en, this message translates to:
  /// **'CO₂ impact report'**
  String get solarChip3;

  /// No description provided for @solarConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get solarConnecting;

  /// No description provided for @solarFetchingImage.
  ///
  /// In en, this message translates to:
  /// **'Fetching satellite image…'**
  String get solarFetchingImage;

  /// No description provided for @solarFindingRoof.
  ///
  /// In en, this message translates to:
  /// **'Finding your roof…'**
  String get solarFindingRoof;

  /// No description provided for @solarHeadline1.
  ///
  /// In en, this message translates to:
  /// **'See what your roof\ncould'**
  String get solarHeadline1;

  /// No description provided for @solarHeadline2.
  ///
  /// In en, this message translates to:
  /// **'earn you.'**
  String get solarHeadline2;

  /// No description provided for @solarIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your property address and energy details. We fetch a satellite image, you trace your roof outline, and our AI calculates your exact solar potential and financial return.'**
  String get solarIntro;

  /// No description provided for @solarNoPanelsFit.
  ///
  /// In en, this message translates to:
  /// **'No solar panels fit inside the traced outline. Trace the full roof surface and try again.'**
  String get solarNoPanelsFit;

  /// No description provided for @solarPill.
  ///
  /// In en, this message translates to:
  /// **'Solar irradiance via Open-Meteo · Satellite imagery'**
  String get solarPill;

  /// No description provided for @solarPotentialTitle.
  ///
  /// In en, this message translates to:
  /// **'Your roof\'s solar potential.'**
  String get solarPotentialTitle;

  /// No description provided for @solarRunningAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Running solar analysis…'**
  String get solarRunningAnalysis;

  /// No description provided for @solarRunningSim.
  ///
  /// In en, this message translates to:
  /// **'Running solar simulation…'**
  String get solarRunningSim;

  /// No description provided for @solarServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again.'**
  String get solarServerError;

  /// No description provided for @solarSimFailed.
  ///
  /// In en, this message translates to:
  /// **'Simulation failed. Please try again.'**
  String get solarSimFailed;

  /// No description provided for @solarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Satellite roof analysis · yield & payback'**
  String get solarSubtitle;

  /// No description provided for @solarTapAtLeast3.
  ///
  /// In en, this message translates to:
  /// **'Tap at least 3 corners on the roof!'**
  String get solarTapAtLeast3;

  /// No description provided for @solarTitle.
  ///
  /// In en, this message translates to:
  /// **'Solar AI'**
  String get solarTitle;

  /// No description provided for @sourceEpex.
  ///
  /// In en, this message translates to:
  /// **'Source: EPEX SPOT DE-LU via Fraunhofer ISE'**
  String get sourceEpex;

  /// No description provided for @sourceModel.
  ///
  /// In en, this message translates to:
  /// **'Source: XGBoost model trained on ENTSO-E data'**
  String get sourceModel;

  /// No description provided for @specsTitle.
  ///
  /// In en, this message translates to:
  /// **'System specifications'**
  String get specsTitle;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @statBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Break-even payback'**
  String get statBreakEven;

  /// No description provided for @statCo2PerYear.
  ///
  /// In en, this message translates to:
  /// **'CO₂ eliminated / yr'**
  String get statCo2PerYear;

  /// No description provided for @statSavedPerYear.
  ///
  /// In en, this message translates to:
  /// **'Saved per year'**
  String get statSavedPerYear;

  /// No description provided for @statTwentyYears.
  ///
  /// In en, this message translates to:
  /// **'Total over 20 years'**
  String get statTwentyYears;

  /// No description provided for @statusAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statusAverage;

  /// No description provided for @statusCheapHour.
  ///
  /// In en, this message translates to:
  /// **'Cheap hour'**
  String get statusCheapHour;

  /// No description provided for @statusPeakHour.
  ///
  /// In en, this message translates to:
  /// **'Peak hour'**
  String get statusPeakHour;

  /// No description provided for @stepEnterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details'**
  String get stepEnterDetails;

  /// No description provided for @stepTraceRoof.
  ///
  /// In en, this message translates to:
  /// **'Trace roof'**
  String get stepTraceRoof;

  /// No description provided for @stepViewResults.
  ///
  /// In en, this message translates to:
  /// **'View results'**
  String get stepViewResults;

  /// No description provided for @sunScore.
  ///
  /// In en, this message translates to:
  /// **'Sun score'**
  String get sunScore;

  /// No description provided for @systemMetrics.
  ///
  /// In en, this message translates to:
  /// **'System metrics'**
  String get systemMetrics;

  /// No description provided for @tagComputerVision.
  ///
  /// In en, this message translates to:
  /// **'Computer vision'**
  String get tagComputerVision;

  /// No description provided for @tagSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get tagSatellite;

  /// No description provided for @tagSmartScheduling.
  ///
  /// In en, this message translates to:
  /// **'Smart scheduling'**
  String get tagSmartScheduling;

  /// No description provided for @tapRoofCorners.
  ///
  /// In en, this message translates to:
  /// **'Tap corners of your roof'**
  String get tapRoofCorners;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get themeLight;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @tonsPerYear.
  ///
  /// In en, this message translates to:
  /// **'{value} t/yr'**
  String tonsPerYear(Object value);

  /// No description provided for @traceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the corners of your roof polygon in order — at least 3 points.'**
  String get traceSubtitle;

  /// No description provided for @traceTip1.
  ///
  /// In en, this message translates to:
  /// **'Tap each corner of the roof surface you want to cover.'**
  String get traceTip1;

  /// No description provided for @traceTip2.
  ///
  /// In en, this message translates to:
  /// **'Go around the outline in order — clockwise or counter-clockwise.'**
  String get traceTip2;

  /// No description provided for @traceTip3.
  ///
  /// In en, this message translates to:
  /// **'Run the AI analysis once the shape looks right.'**
  String get traceTip3;

  /// No description provided for @traceTitle.
  ///
  /// In en, this message translates to:
  /// **'Trace your roof'**
  String get traceTitle;

  /// No description provided for @treeEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Tree equivalent'**
  String get treeEquivalent;

  /// No description provided for @treeEquivalentHint.
  ///
  /// In en, this message translates to:
  /// **'Annual CO₂ absorption equivalent'**
  String get treeEquivalentHint;

  /// No description provided for @treesApprox.
  ///
  /// In en, this message translates to:
  /// **'~{count} trees'**
  String treesApprox(Object count);

  /// No description provided for @treesHint.
  ///
  /// In en, this message translates to:
  /// **'Equivalent annual CO₂ absorption'**
  String get treesHint;

  /// No description provided for @treesPerYear.
  ///
  /// In en, this message translates to:
  /// **'~{count} trees/yr'**
  String treesPerYear(Object count);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @typicalDay.
  ///
  /// In en, this message translates to:
  /// **'A TYPICAL DAY'**
  String get typicalDay;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unitCtKwh.
  ///
  /// In en, this message translates to:
  /// **'ct/kWh'**
  String get unitCtKwh;

  /// No description provided for @windowEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Evening demand spikes push EPEX to 30–60 ct/kWh. EnergyTwin pauses the heat pump. Stored heat keeps your home comfortable without paying peak rates.'**
  String get windowEveningBody;

  /// No description provided for @windowEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid evening peak'**
  String get windowEveningTitle;

  /// No description provided for @windowMiddayBody.
  ///
  /// In en, this message translates to:
  /// **'Germany\'s solar fleet peaks and prices can hit 0 or even go negative. EnergyTwin maximises heat pump runtime in this window — essentially free heat.'**
  String get windowMiddayBody;

  /// No description provided for @windowMiddayTitle.
  ///
  /// In en, this message translates to:
  /// **'Solar surplus midday'**
  String get windowMiddayTitle;

  /// No description provided for @windowNightBody.
  ///
  /// In en, this message translates to:
  /// **'Wind turbines run all night but demand is minimal. EPEX prices fall to 5–15 ct/kWh. EnergyTwin pre-charges your home\'s thermal mass silently while you sleep.'**
  String get windowNightBody;

  /// No description provided for @windowNightTitle.
  ///
  /// In en, this message translates to:
  /// **'Overnight wind valley'**
  String get windowNightTitle;

  /// No description provided for @yearsSuffix.
  ///
  /// In en, this message translates to:
  /// **' yrs'**
  String get yearsSuffix;

  /// No description provided for @yearsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} years'**
  String yearsValue(Object value);

  /// No description provided for @zoneCheap.
  ///
  /// In en, this message translates to:
  /// **'Cheap'**
  String get zoneCheap;

  /// No description provided for @zoneCheapDesc.
  ///
  /// In en, this message translates to:
  /// **'Run heat pump, charge EV, do laundry'**
  String get zoneCheapDesc;

  /// No description provided for @zoneMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get zoneMid;

  /// No description provided for @zoneMidDesc.
  ///
  /// In en, this message translates to:
  /// **'Normal household use, monitor closely'**
  String get zoneMidDesc;

  /// No description provided for @zonePeak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get zonePeak;

  /// No description provided for @zonePeakDesc.
  ///
  /// In en, this message translates to:
  /// **'Avoid big loads, discharge battery'**
  String get zonePeakDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
