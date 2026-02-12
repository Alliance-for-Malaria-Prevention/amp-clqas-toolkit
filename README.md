# Toolkit for assessment of ITN campaigns using cLQAS survey methods
This toolkit makes available generic tools for in-process assessment of household registration (HHR) and an end-process assessment of ITN distribution. These tools were developed for the Alliance for Malaria Prevention (AMP) by Eleanore Sternberg and Steve Poyer. 

Components of the toolkit:
1. Protocols
2. Word versions of questionnaires
3. XLSX versions of questionnaires for ODK-based platforms
4. R scripts to clean and check data
5. R Markdowns for reporting results

## Notes on use
- These tools are intended to be used for ITN distribution campaigns
- The in-process tools are for assessment of household registration prior to distribution
- The end-process tools are for assessment of the distribution shortly after the campaign
- All tools will need to be adapted to the local context, including whether the distribution is fixed point or door-to-door

The R scripts to clean and check data are intended to be run and reviewed by the data manager or similar role as part of data quality assurance during data collection. The results of this check should be fed back immediately to the assessment teams. By making most questions required in the ODK form and including internal checks, missing data and errors should be minimized but nightly checks are still important to ensure data quality. Additional checks should be added if the ODK form is altered to remove any of the checks.  

The R Markdown for reporting is meant to be run daily and will produce a Word document that can be circulated among the assessment team and the household registration teams. The summary of the number and types of errors is meant to inform corrections in the household registration activities. The final report is meant to be completed after the end of data collection.

Included in this repo is dummy data that can be used to test the R script. The dummy data consists of: 
- Three regions; Region 1 has 5 districts, Region 3 has 6 districts, and Region 3 has 4 districts
- There are 6 clusters per district and 10 households interviewed in each cluster
- There are 6 days of data collection with one cluster completed per district per day

The dummy data and generic R scripts assumes:
- Households **are not told** how many ITNs they will receive prior to the distribution.
- ITN distribution used the **fixed site** approach.
- An **ITN allocation strategy** of 1 net for every two people in a household, rounding up odd-numbered households, and applying a cap of 5 nets per household.

In addition, the generic assessment questionnaire includes a section to capture personally identifying information that may be used to link the assessment record to a household's digital campaign record or HHR record (or both). However, the generic R scripts assume that digital matching does not occur and analysis relies only on data captured through the generic assessment questionnaire.

## Assumptions on design of generic in-process assessment tools
- The in-process assessment compares the number of eligible household members on the day of assessment with the number recorded by the HHR team during the registration visit (the previous day).
- Depending on the HHR procedures, households may or may not receive written documentation from the HHR teams and may or may not be told how many ITNs they will receive from the campaign.
- The generic questionnaire includes fields to capture information shared by the HHR teams in written or verbal form.

## Assumptions on design of generic end-process assessment tools
- The end-process assessment compares the number of campaign ITNs reportedly received by a household with the number that should have been allocated to the household based on the outcome of the HHR process.
- Depending on the HHR procedures, households may or may not receive written documentation from the HHR teams and may or may not be told how many ITNs they will receive from the campaign.
- Depending on the campaign strategy, ITNs will have been distributed to household members using a door-to-door approach at the same time as registration, or using a fixed-site approach during which household members must go to a collect point to receive their ITNs.
- The generic questionnaire includes:
    - Fields to capture information shared by the HHR teams in written or verbal form.
    - Questions appropriate for both fixed site and door-to-door distribution strategies.

Modifications to the R scripts (and generic questionnaire) may be required if a programme's campaign design differed from these assumptions.

## References
- https://polioeradication.org/wp-content/uploads/2016/09/Assessing-Vaccination-Coverage-Levels-Using-Clustered-LQAS_Apr2012_EN.pdf
- Pezzoli, L., N. Andrews, and O. Olivier Ronveaux. “Clustered Lot Quality Assurance Sampling to Assess Immunisation Coverage: Increasing Rapidity and Maintaining Precision.” Tropical Medicine and International Health 15, no. 5 (May 2010): 540–546. https://doi.org/10.1111/j.1365-3156.2010.02482.x.
-	Okayasu, H., A. Brown, M. Nzioki, A. Gasasira, M. Takane, P. Mkanda, S. Wassilak, and R. Sutter. “Cluster Lot Quality Assurance Sampling: Effect of Increasing the Number of Clusters on Classification Precision and Operational Feasibility.” Journal of Infectious Diseases 210, suppl. 1 (November 1, 2014): S341–S346. https://doi.org/10.1093/infdis/jiu162.
