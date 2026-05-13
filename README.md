# Income Inequality, Capitalism, and Diversity: A Goodness-of-fit Decomposition Perspective

**Author:** Anastasiia Rekovets · [github.com/ana-rekovets](https://github.com/ana-rekovets)  
**Contact:** ana.rekovets@gmail.com  
**Year:** 2023  
**Software:** Stata 15+

---

## Abstract

This research explores the dynamics of income redistribution in the context of economic
freedom, genetic diversity, and various socio-economic factors. Through the lens of
goodness-of-fit decomposition, it quantifies the individual contributions of economic freedom,
predicted genetic diversity, religious composition, economic indicators, continent-specific
factors, and legal origins in explaining cross-country income inequality.

The analysis extends the merged dataset of Ashraf & Galor (2013) and Sturm & De Haan (2015),
applying the **rego method** (Huettner & Sunder, University of Leipzig) to decompose the
R-squared goodness-of-fit of OLS regression models into individual regressor contributions
via **Shapley values**. The dataset spans 108 countries over 1971–2010 (8 five-year intervals).

Key findings: the interaction between economic freedom and genetic diversity consistently
accounts for ~50% of explained variation in redistribution. Scandinavian legal origin, Protestant
religious composition, and European geographic location emerge as substantial explanatory
factors, while the KOF globalisation index and Catholic religious composition contribute
comparatively little.

**Keywords:** income redistribution · economic freedom · predicted genetic diversity ·
Shapley decomposition · R-squared · legal origins · religious composition · panel data

---

## Repository Structure

```
income-inequality-decomposition/
│
├── README.md
│
├── code/
│   └── replication_income_inequality_decomposition.do   # Main Stata replication script
│
├── paper/
│   └── income_inequality_capitalism_diversity.docx      # Full research paper
│
├── presentation/
│   └── income_inequality_capitalism_diversity_presentation.pptx
│
└── output/
    └── output_replication_log.txt                       # Full Stata output log
```

---

## Data

The analysis draws on two publicly available datasets merged for this project:

| Dataset | Variables provided | Access |
|---|---|---|
| Sturm & De Haan (2015) | Redistribution measure (SWIID), Economic Freedom Index (Fraser Institute), fractionalization, legal origins, religious composition, continent dummies | [AEA](https://www.aeaweb.org/articles?id=10.1257/aer.p20151112) |
| Ashraf & Galor (2013) | Predicted genetic heterozygosity (migratory distance from East Africa, Out-of-Africa hypothesis) | [AEA](https://www.aeaweb.org/articles?id=10.1257/aer.103.1.1) |

> **Note:** Dataset files (`.dta`) are not included in this repository due to redistribution
> restrictions. Download the original supplementary files from the AEA links above, place
> them in a local `data/` folder, and update the `global root` path at the top of the do-file.

---

## Variables

| Variable | Description | Source |
|---|---|---|
| `redistribution` | Market Gini / Net Gini — ratio measuring degree of redistribution | Sturm & De Haan (2015), SWIID |
| `ecfree` | Economic Freedom Index, 5-year lag (proxy for capitalism) | Fraser Institute via Sturm & De Haan |
| `pdiv` | Predicted heterozygosity using migratory distance to East Africa | Ashraf & Galor (2013) |
| `ecfree_pdiv` | Economic Freedom × Predicted Diversity (interaction term) | Constructed |
| `lrgdpepop` | Log real GDP per capita, 5-year average | World Bank |
| `kofgi_ecoflows` | KOF Economic Globalisation Index — Flows, 5-year average | KOF via Sturm & De Haan |
| `europe`, `asia`, `africa`, `wb_nam`, `oceania` | Continent dummies | Sturm & De Haan |
| `legor_so`, `legor_ge`, `legor_sc` | Legal origin dummies: Socialist, German, Scandinavian | Sturm & De Haan |
| `pmuslim`, `pprotest`, `pcatholic`, `pother` | Share of religious groups in population (1980) | Sturm & De Haan |

---

## Methodology

### OLS Regression

Ten OLS regression models are estimated with **income redistribution** as the dependent
variable. A "basic" specification (Economic Freedom, Predicted Diversity, and their interaction)
is extended sequentially with additional control groups:

| Model | Specification |
|---|---|
| 1 | Basic model — all years |
| 2 | Basic model — year 2005 only (comparison with Sturm & De Haan 2015) |
| 3 | Basic + Log GDP per capita |
| 4 | Basic + KOF Globalisation Index |
| 5 | Basic + Continent dummies |
| 6 | Basic + Legal origin dummies |
| 7 | Basic + Share of Muslims |
| 8 | Basic + Share of Protestants |
| 9 | Basic + Share of Catholics |
| 10 | Basic + Share of other religions |

Three combination models (Tables 13–15) add economic indicators alongside each group of
structural controls simultaneously.

### Goodness-of-fit Decomposition (rego)

The **rego method** decomposes the overall R² of each OLS model into the individual
contribution of each regressor using the **Shapley value** from cooperative game theory.
The Shapley value calculates each variable's average marginal contribution to R² across
all possible orderings of regressors, satisfying efficiency, symmetry, additivity, and
null-player axioms. This provides a unique, fair attribution of explanatory power that
standard regression output alone cannot supply.

---

## Key Results

| Factor | Shapley %R² | Direction |
|---|---|---|
| EF × Predicted Diversity (interaction) | ~49–51% | Positive |
| Economic Freedom Index | ~22–40% | Negative |
| Predicted Diversity | ~7–14% | Negative |
| Log GDP per capita (when included) | ~36% | Positive |
| Europe dummy (when included) | ~37–38% | Positive |
| Legal origin — Scandinavia (when included) | ~31–38% | Positive |
| Share of Protestants (when included) | ~29% | Positive |
| Share of Muslims (when included) | ~11% | Negative |
| KOF Globalisation Index (when included) | ~9% | Negligible |
| Share of Catholics (when included) | ~1% | Negligible |

R² across all models ranges from **0.465 to 0.701**.

---

## Replication

### Requirements

- Stata 15 or later
- The following packages are **auto-installed** by the do-file if not already present:

| Package | Purpose |
|---|---|
| `egenmore` | Five-year moving averages via `egen filter()` |
| `estout` | Formatted regression tables via `esttab` |
| `rego` | Shapley R² decomposition |

### Steps

1. Download both datasets from the AEA links in the Data section above
2. Organise them as follows:

```
data/
├── data_DeHaanSturm/
│   └── Sturm_DeHaan_IncIneq_Cap_Frac_AER_P&P_data.dta
└── data_AshrafGalor/
    └── data/country.dta
```

3. Open `code/replication_income_inequality_decomposition.do`
4. Update `global root` on **line 34** to point to your local `data/` folder
5. Run the script — it installs missing packages, merges the data, runs all 13 regression
   and decomposition models, exports all tables, and saves a log automatically

The `output/output_replication_log.txt` file in this repository shows the expected output
for all 16 tables, and can be used to verify your replication.

---

## File Descriptions

| File | Description |
|---|---|
| `code/replication_income_inequality_decomposition.do` | Full Stata replication script. Sections: housekeeping, data prep, merge, OLS regressions, rego decompositions, combination models, descriptive statistics |
| `paper/income_inequality_capitalism_diversity.docx` | Research paper with full methodology, results, and discussion |
| `presentation/income_inequality_capitalism_diversity_presentation.pptx` | Slide deck summarising the research |
| `output/output_replication_log.txt` | Cleaned Stata output log containing all regression and rego decomposition results (Tables 3–15) and descriptive statistics (Table A2) |

---

## References

1. Ashraf, Q., & Galor, O. (2013). The "Out of Africa" Hypothesis, Human Genetic Diversity, and Comparative Economic Development. *American Economic Review*, 103(1), 1–46. https://doi.org/10.1257/aer.103.1.1

2. Cann, H. M. (2002). A Human Genome Diversity Cell Line Panel. *Science*, 296(5566), 261–262. https://doi.org/10.1126/science.296.5566.261b

3. Desmet, K., Ortuño-Ortín, I., & Weber, S. (2009). Linguistic Diversity and Redistribution. *Journal of the European Economic Association*, 7(6), 1291–1318. https://doi.org/10.1162/jeea.2009.7.6.1291

4. Huettner, F., & Sunder, M. (2011). rego: R-Squared Decomposition. University of Leipzig. http://www.marco-sunder.de/stata/rego.html

5. Lawson, R., Hall, J., Murphy, R., & Gwartney, J. (2015). Economic Freedom of the World — 2015 Annual Report. *SSRN Electronic Journal*. https://doi.org/10.2139/ssrn.3924422

6. Solt, F. (2016). The Standardized World Income Inequality Database. *Social Science Quarterly*, 97(5), 1267–1281. https://doi.org/10.1111/ssqu.12295

7. Sturm, J.-E., & De Haan, J. (2015). Income Inequality, Capitalism, and Ethno-Linguistic Fractionalization. *American Economic Review*, 105(5), 593–597. https://doi.org/10.1257/aer.p20151112

---

## License

Code released under the [MIT License](LICENSE).  
The underlying datasets are subject to their own redistribution terms — please consult the original sources.
