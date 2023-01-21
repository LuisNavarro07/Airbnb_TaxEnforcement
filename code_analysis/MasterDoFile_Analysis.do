********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Master Do File - Analysis  
********************************************************************************
********************************************************************************

/// 1 . Descriptive Statistics 
do "${ac}/1_DescriptiveMonthly.do"
/// 2. Main Results: Quantities 
do "${ac}/2_RegressionMonthly.do" 
/// 3. Main Results: Prices 
do "${ac}/3_RegressionDaily.do"
/// 4. Robustness Check: Stacked DID 
do "${ac}/4_StackedDID.do"
