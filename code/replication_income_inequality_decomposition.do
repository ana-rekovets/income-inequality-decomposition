/*==============================================================================
  Income Inequality, Capitalism, and Diversity:
  A Goodness-of-fit Decomposition Perspective
  
  Author  : Anastasiia Rekovets
  Date    : September 2023
  Contact : ana.rekovets@gmail.com
  GitHub  : https://github.com/ana-rekovets
  
  Description:
    Replication script for "Income Inequality, Capitalism, and Diversity:
    A Goodness-of-fit Decomposition Perspective" (Rekovets, 2023).
    Extends the analysis of Sturm & De Haan (AER P&P, 2015) and Ashraf & Galor
    (AER, 2013), as merged by Ibrahim Ben Araar (2022/2023). The script applies
    the rego method (Huettner & Sunder, University of Leipzig) to decompose the
    R-squared goodness-of-fit of each OLS regression model into individual
    regressor contributions via Shapley values.

    Sections:
      0. Housekeeping           — environment setup, logging, package install
      1. Data preparation       — load and clean Sturm & De Haan (2015) data
      2. Merge                  — join Ashraf & Galor (2013); build interaction term
      3. OLS regressions        — 10 models, exported comparison table
      4. Rego decompositions    — Shapley R2 for each model (Tables 3-12)
      5. Combination models     — economic indicators + structural controls (Tables 13-15)
      6. Descriptive statistics — summary table (Appendix Table A2)

  Data sources:
    - Sturm & De Haan (2015): https://www.aeaweb.org/articles?id=10.1257/aer.p20151112
    - Ashraf & Galor (2013):  https://www.aeaweb.org/articles?id=10.1257/aer.103.1.1

  Required Stata packages (auto-installed below):
    - egenmore  (moving averages via filter)
    - estout    (regression tables)
    - rego      (Shapley R-squared decomposition)
==============================================================================*/


*==============================================================================*
*  0. HOUSEKEEPING
*==============================================================================*

clear all
set more off
version 15                        // adjust to your Stata version if needed

* ---------- working directory -------------------------------------------------
* Set this to the folder that contains both data sub-folders:
*   data_DeHaanSturm\
*   data_AshrafGalor\
* Example (Windows):
*   global root "C:\Users\YourName\Desktop\Paper_Data"
* Example (Mac/Linux):
*   global root "~/Desktop/Paper_Data"

global root "CHANGE_TO_YOUR_PATH"

* ---------- log ---------------------------------------------------------------
cap log close
log using "${root}/income_inequality_decomposition.log", replace text

* ---------- required packages -------------------------------------------------
* Installs each package only if not already present
foreach pkg in egenmore estout rego {
    cap which `pkg'
    if _rc != 0 {
        ssc install `pkg', replace
    }
}


*==============================================================================*
*  1. LOAD AND PREPARE STURM & DE HAAN (2015) DATA
*==============================================================================*

use "${root}/data_DeHaanSturm/Sturm_DeHaan_IncIneq_Cap_Frac_AER_P&P_data.dta", clear

* Flag five-year interval years used in the analysis
generate sample5yr = 1 if inlist(year, 1970, 1975, 1980, 1985, ///
                                        1990, 1995, 2000, 2005, 2010)

* ---------- variable lists for moving-average construction --------------------
local deplist  gini_net_avg gini_market_avg
local efwlist  efw_nodist
local ethlist  adekw_eth adekw_lan adekw_rel dowjeea_elf dowjeea_gi dow_elf1
local koflist  kofgi_ecoflows fdi_st_gdp
local exolist  lrgdpepop

* ---------- five-year moving averages -----------------------------------------
* For each variable: current + past 4 years (lags 0–4), then also lags 3 and 5
foreach lst in dep efw eth kof exo {
    foreach var of varlist ``lst'list' {
        quietly egen   ma`var' = filter(`var'), lags(0/4) coef(1 1 1 1 1) normalise
        quietly generate l3ma`var' = l3.ma`var'
        quietly generate l5ma`var' = l5.ma`var'
        quietly generate l5`var'  = l5.`var'
    }
}

* ---------- rename for clarity ------------------------------------------------
rename gini_market_avg  ginimarket
rename adekw_eth        frac_adekw_eth
rename adekw_lan        frac_adekw_lan
rename adekw_rel        frac_adekw_rel
rename dowjeea_elf      frac_dow09_elf
rename dowjeea_gi       frac_dow09_gi
rename dow_elf1         frac_dow12_elf1

* ---------- key constructed variables ----------------------------------------
* Economic freedom: lagged 5 years (to address potential endogeneity)
generate ecfree = l5.efw_nodist

* Redistribution: ratio of market Gini to net Gini
generate redistribution = ginimarket / gini_net_avg

* Logarithmic transformations (used in robustness checks)
generate ln_redistribution = log(redistribution)
generate ln_ecfree         = log(ecfree)

* ---------- variable labels ---------------------------------------------------
label var ecfree          "Economic Freedom Index (5-yr lag, Areas 1 & 3 corrected)"
label var ginimarket      "Market Gini (pre-tax, pre-transfer household income)"
label var redistribution  "Redistribution ratio (market Gini / net Gini)"
label var ln_redistribution "Log redistribution ratio"
label var ln_ecfree       "Log Economic Freedom Index"
label var lrgdpepop       "Log real GDP per capita (5-yr average)"
label var kofgi_ecoflows  "KOF Economic Globalisation Index – Flows (5-yr average)"
label var fdi_st_gdp      "FDI stock (% of GDP, 5-yr average; source: KOF)"
label var frac_adekw_eth  "Ethnic fractionalization (ADEKW)"
label var frac_adekw_lan  "Linguistic fractionalization (ADEKW)"
label var frac_adekw_rel  "Religious fractionalization (ADEKW)"
label var frac_dow09_elf  "Ethno-linguistic fractionalization – ELF (Dow 2009)"
label var frac_dow09_gi   "Ethno-linguistic fractionalization – Greenberg index (Dow 2009)"
label var frac_dow12_elf1 "Ethno-linguistic fractionalization – ELF1 (Dow 2012)"


*==============================================================================*
*  2. MERGE WITH ASHRAF & GALOR (2013) DATA
*     (provides predicted genetic diversity and country-level characteristics)
*==============================================================================*

merge m:1 country using ///
    "${root}/data_AshrafGalor/data/country.dta"

* Keep only matched observations and records from the master dataset
* (_merge == 2: countries in Ashraf-Galor not in Sturm-DeHaan — drop)
drop if _merge == 2
drop _merge

* Rename Ashraf-Galor predicted diversity variable to shorter name
* NOTE: the variable is named pdiv_aa in the original country.dta file;
*       if your copy uses a different name, update the line below accordingly.
rename pdiv_aa pdiv

label var pdiv "Predicted heterozygosity (migratory distance to East Africa)"

* ---------- interaction term --------------------------------------------------
generate ecfree_pdiv = ecfree * pdiv
label var ecfree_pdiv "Economic Freedom × Predicted Diversity (interaction)"


*==============================================================================*
*  3. TABLE 1 — OLS REGRESSIONS (10 MODELS)
*     Dependent variable: redistribution
*     Replicates Araar (2022/2023), extended from Sturm & De Haan (2015)
*==============================================================================*

eststo clear

* Model 1 – Basic model
eststo m1: quietly reg redistribution c.ecfree##c.pdiv

* Model 2 – Basic model, year 2005 only (comparison with Sturm & De Haan 2015)
eststo m2: quietly reg redistribution c.ecfree##c.pdiv if year == 2005

* Model 3 – Basic + Log GDP per capita
eststo m3: quietly reg redistribution c.ecfree##c.pdiv lrgdpepop

* Model 4 – Basic + KOF globalisation index
eststo m4: quietly reg redistribution c.ecfree##c.pdiv kofgi_ecoflows

* Model 5 – Basic + Continent dummies
eststo m5: quietly reg redistribution c.ecfree##c.pdiv europe asia africa wb_nam oceania

* Model 6 – Basic + Legal origin dummies
eststo m6: quietly reg redistribution c.ecfree##c.pdiv legor_so legor_ge legor_sc

* Model 7 – Basic + Share of Muslims
eststo m7: quietly reg redistribution c.ecfree##c.pdiv pmuslim

* Model 8 – Basic + Share of Protestants
eststo m8: quietly reg redistribution c.ecfree##c.pdiv pprotest

* Model 9 – Basic + Share of Catholics
eststo m9: quietly reg redistribution c.ecfree##c.pdiv pcatholic

* Model 10 – Basic + Share of other religions
eststo m10: quietly reg redistribution c.ecfree##c.pdiv pother

* ---------- export regression table ------------------------------------------
esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10, ///
    r2(3)                               ///
    star(* 0.10 ** 0.05 *** 0.01)       ///
    compress                            ///
    mtitles("Basic" "2005" "+GDP" "+KOF" "+Continent" "+Legal" ///
            "+Muslim" "+Protestant" "+Catholic" "+OtherRel")  ///
    title("Table 1: OLS Regressions — Determinants of Income Redistribution")

eststo clear


*==============================================================================*
*  4. REGO DECOMPOSITIONS — SHAPLEY R² CONTRIBUTIONS
*     Uses the manually created interaction term (ecfree_pdiv) because rego
*     does not accept factor-variable (##) syntax.
*==============================================================================*

* ---------- Table 3: Basic model (all years) ----------------------------------
rego redistribution ecfree pdiv ecfree_pdiv

* ---------- Table 4: Basic model (2005 only) ----------------------------------
rego redistribution ecfree pdiv ecfree_pdiv if year == 2005

* ---------- Table 5: Basic + Log GDP per capita -------------------------------
rego redistribution ecfree pdiv ecfree_pdiv lrgdpepop

* ---------- Table 6: Basic + KOF globalisation index -------------------------
rego redistribution ecfree pdiv ecfree_pdiv kofgi_ecoflows

* ---------- Table 7: Basic + Continent dummies --------------------------------
rego redistribution ecfree pdiv ecfree_pdiv europe asia africa wb_nam oceania

* ---------- Table 8: Basic + Legal origin dummies ----------------------------
rego redistribution ecfree pdiv ecfree_pdiv legor_so legor_ge legor_sc

* ---------- Table 9: Basic + Share of Muslims ---------------------------------
rego redistribution ecfree pdiv ecfree_pdiv pmuslim

* ---------- Table 10: Basic + Share of Protestants ---------------------------
rego redistribution ecfree pdiv ecfree_pdiv pprotest

* ---------- Table 11: Basic + Share of Catholics -----------------------------
rego redistribution ecfree pdiv ecfree_pdiv pcatholic

* ---------- Table 12: Basic + Share of other religions -----------------------
rego redistribution ecfree pdiv ecfree_pdiv pother


*==============================================================================*
*  5. COMBINATION MODELS (Tables 13–15)
*     Basic model + economic indicators + one additional group of controls
*==============================================================================*

* ---------- Table 13: + Economic indicators + Continent dummies ---------------
rego redistribution ecfree pdiv ecfree_pdiv ///
    lrgdpepop kofgi_ecoflows               ///
    europe asia africa wb_nam oceania

* ---------- Table 14: + Economic indicators + Legal origins ------------------
rego redistribution ecfree pdiv ecfree_pdiv ///
    lrgdpepop kofgi_ecoflows               ///
    legor_so legor_ge legor_sc

* ---------- Table 15: + Economic indicators + Religious composition ----------
rego redistribution ecfree pdiv ecfree_pdiv ///
    lrgdpepop kofgi_ecoflows               ///
    pprotest pmuslim pcatholic pother


*==============================================================================*
*  6. APPENDIX — DESCRIPTIVE STATISTICS
*==============================================================================*

estpost summarize                                               ///
    redistribution ecfree pdiv                                 ///
    frac_adekw_eth frac_adekw_lan frac_adekw_rel frac_dow09_elf ///
    lrgdpepop kofgi_ecoflows                                   ///
    europe asia wb_nam oceania                                  ///
    legor_so legor_ge legor_sc                                  ///
    pmuslim pcatholic pprotest pother

* noobs suppresses the observation count row (already shown per-model above)
esttab, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    noobs                                                       ///
    collabels("Obs." "Mean" "Std. Dev." "Min" "Max")           ///
    title("Appendix Table A2: Descriptive Statistics")


*==============================================================================*
*  7. CLOSE LOG
*==============================================================================*

log close
