## Table of contents :
- [Datasets](#datasets)
- [Packages Required](#packages-required)
- [Agreen10_drug_transactions.jl](#agreen10_drug_transactionsjl)
- [Agreen10_ATC_transactions.jl](#agreen10_atc_transactionsjl)
- [Ypan34_drug_map_final.jl](#ypan34_drug_map_finaljl)
- [Ypan34_get_pairwise.jl](#ypan34_get_pairwisejl)
- [Ypan34_disprop_analysis.jl](#ypan34_disprop_analysisjl)
- [Nscott2_interaction_checker.jl](#nscott2_interaction_checkerjl)
- [Final_interation.jl](#final_interationjl)
- [Rkakar_interaction.jl](#rkakar_interactionjl)
- [Rkakar_word_cloud.py](#rkakar_word_cloudpy)
- [Acknowledgement](#acknowledgement)

## Datasets
```source
 /gpfs/data/biol1555/projects/team6/code
  |-- agreen10_hypo_drug_query.txt
  |-- atc_all_list.csv
  |-- atc_list.csv
  |-- atc_pairwise.csv
  |-- interaction.csv
  ```
## Packages Required
- Julia: `DBInterface`, `MySQL`, `DataFrames`, `DataFramesMeta`, `CSV`, `Dates`, `Query`, `Serialization`, `PharmaceuticalClassification`, `FreqTables`, and `ARules`.
- Python: `math`, `csv`, `matplotlib`, and `wordcloud`

## [Agreen10_drug_transactions.jl](agreen10_drug_transactions.jl)
`Agreen10_drug_interactions.jl` is a Julia program which generates association rules based on MIMIC-III data. The program formats the data into a format compatible with the ARules julia package while also filtering out non-drug entries and repeats. The program uses a .txt file titled `agreen10_hypo_drug_query.txt` as it’s input. This .txt file contains the columns `HADM_ID`, `Drug`, `Drug_Name_Generic`, `StartDate`, and `ChartTime`. The exact data can be extracted from the MIMIC-III database using the following MySQL query:

 ```SQL
SELECT i.HADM_ID,i.DRUG,i.DRUG_NAME_GENERIC,i.STARTDATE, d.CHARTTIME
FROM PRESCRIPTIONS AS i
INNER JOIN (SELECT DISTINCT HADM_ID, MIN(CHARTTIME) AS CHARTTIME FROM CHARTEVENTS WHERE ITEMID = '220179' AND VALUE < 90 GROUP BY HADM_ID) AS d
ON i.HADM_ID = d.HADM_ID
WHERE i.DRUG_NAME_GENERIC != 'NULL'
AND i.HADM_ID = d.HADM_ID
AND i.STARTDATE <= d.CHARTTIME;
```
This query extracts the drug lists of patients who have had a hypotensive event (defined as a systolic blood pressure value < 90). The drug lists only contain drugs administered up to 48 hours prior to the hypotensive event. 

To run the `Agreen10_drug_interactions.jl` program, make sure that the ARules package and Julia/1.5.3 modules are installed and that the location of the .txt input file is specified. The program will output a list of association rules with their respective confidence, support, and lift values. The default parameters are set to a support of 30%, a confidence of 10% and a max length of 2 (in order to output drug pairings). These parameters can be edited to change the constraints of the association rules. There is also a frequencies output in the code that can be used to determine the number of times each distinct drug pairing occurs in the data. The default parameters are set to a minimum and maximum length of 2 (in order to only output pairs). These parameters can be changed in order to get a wider range of drug combinations of varying sizes.  

## [Agreen10_ATC_transactions.jl](agreen10_ATC_transactions.jl)
`Agreen10_ATC_interactions.jl` is a Julia program which generates association rules based on MIMIC-III data converted to ATC codes. The program formats the data into a format compatible with the ARules julia package. The program uses `atc_all_list.csv`  as its input. This .csv file contains the columns `HADM_ID`, `ATC`, and `StartDate`. The data from this .csv file is the direct output of the `ypan34_drug_map_final.jl` program which converts the NDC codes of a patient’s drug list to ATC codes. 

To run the `Agreen10_ATC_interactions.jl` program, make sure that the ARules package and Julia/1.5.3 modules are installed and that the location of the .csv input file is specified. The program will output a list of association rules with their respective confidence, support, and lift values. The default parameters are set to a support of 20%, a confidence of 30% and a max length of 2 (in order to output drug class pairings). These parameters can be edited to change the constraints of the association rules. There is also a frequencies output in the code that can be used to determine the number of times each distinct drug class pairing occurs in the data. The default parameters are set to a minimum and maximum length of 2 (in order to only output pairs). These parameters can be changed in order to get a wider range of drug combinations of varying sizes. 

## [Ypan34_drug_map_final.jl](ypan34_drug_map_final.jl)
- Input: two dataframes extracted from the MIMIC-III database. SQL queries were embedded in the program.
- Output: `atc_all_list.csv` and `atc_list.csv`
- This program processes two dataframes: one containing info on drugs prescribed within 24 hours of the hypotensive reading of each patient, and the other containing info on all patients' prescriptions. Then the program maps the prescriptions in NDC codes onto ATC4 codes. 
- Before running, make sure to install the packages indicated above and change the brown username to your own in the script.


## [Ypan34_get_pairwise.jl](ypan34_get_pairwise.jl)
- Input:`atc_list.csv`
- Output:`atc_pairwise.csv`
- This program creates all possible pairwise prescription combinations for each patient.
- Before running, make sure to install the packages indicated above.


## [Ypan34_disprop_analysis.jl](ypan34_disprop_analysis.jl)
- Input:`atc_pairwise.csv` and `atc_all_list.csv`
- Output:`interaction.csv`
- This program creates a function to perform disproportionality analysis and return the observed-to-expected ratio of hypotension given the co-prescription of drug pairs and the omega shrinkage measure with the tuning parameter set to 0.5, and then the disproportionality analysis function was applied to all possible pairwise combinations and generate a dataframe storing all the estimates of potentioal drug interaction scores. The procedure of disproportionality analysis refers to the paper: https://onlinelibrary.wiley.com/doi/abs/10.1002/sim.3247.
- Before running, make sure to install the packages indicated above.

## [Nscott2_interaction_checker.jl](nscott2_interaction_checker.jl)
This program is a prototype for final_interaction.jl. The program features a "placeholder" dictionary of (mock-up) known drug interactions, and includes a test input and output in a comment at the bottom of the file. Ultimately, the known interactions dictionary was populated with drug interactions data from `ypan34_disprop_analysis.jl` (and could theoretically be populated with other interactions data from similar projects).

## [Final_interation.jl](final_interaction.jl)
- Input: string - the 4th level ATC drug code describing the chemical subgroup of the drug
- Output: string - the interpretation of relative risk for each possible drug pair from the inputted list
- Program: This is a program that uses all the knowledge from our previous steps to put together a comprehensive user-facing system. This program checks the observed to expected ratio for a specific pair of drugs and outputs the risk consideration for them. The results are based on the initial SQL query and the Disproportionality Analysis.
- Structure: At the core of this program is a dictionary that saves all the information from the Disproportionality Analysis. The program may output different things based on what the input is. It checks for edge cases of an input of only 1 drug (since no pairs can be formed from a single drug), a list where no pair formed exists in our data library. The program is fairly easy to use and can be run by the line```julia final_interaction.jl```in the terminal. When the user has completed entering their drug codes, they must enter `.` for the program to start analysing and outputting results. The program uses the DataFrames and CSV packages.

## [Rkakar_interaction.jl](rkakar_interaction.jl)
This was a precursor to our final interaction checker program. Combined
this program with the `nscott2_interaction_checker.jl` to come up with our final program. It is run in a similar manner and only uses the DataFrames and CSV packages.

## [Rkakar_word_cloud.py](rkakar_word_cloud.py)
- Input: csv - output of the Disproportionality Analysis
- Output: image - wordcloud 
- Program: This program creates a word cloud of 4th-level ATC codes based on which one of them have shown greater association with hypotensive adverse
events. 
- Structure: This program was coded in python instead of Julia upon Dilum's recommendation. It uses the packages math, csv, matplotlib and wordcloud. Based on the output of the Disproportionality Analysis, each drug is asscoiated with the sum of $\Omega$ values from its occurrence in each pair it is in. The program is fairly easy to run but I was unable to run it on Oscar due to a permission denied error for package installation, so I ran it locally, which worked. This output was used in our poster presentation. 


## Acknowledgement
The programs in this Github repo are constructed with the help from Dilum Aluthge, Dr. Elizabeth Chen, and Dr. Neil Sarkar.



