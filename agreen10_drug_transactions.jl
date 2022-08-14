################################################################################
#
# Program: agreen10_drug_transactions.jl
# Purpose: Association rule mining of MIMIC-III data
# Description: Filters out non-drug entries and repeats while converting the data
#	into a list of lists in order to generate association rules to determine which
#	drug pairings are associated with hypotensive adverse drug interctions	
# Created by: Allen Green
# Created on: 2021-03-28
# Last modified by: Allen Green
# Last modified on: 2021-04-16
#
################################################################################

#Reads in Query File
#****MAKE SURE YOU CHANGE TO PATH TO WHERE YOU STORE THE QUERY.TXT FILE****
input_file = open("/users/agreen10/data/projects/team6/data/agreen10_hypo_drug_query.txt", "r")

#A Temporary list that is reset for each HADM, stores the drugs for each unique
#HADM ID until that list is ready to be pushed to transactions
temp = []

#A list of lists showing the unique drugs for each HADM as a sublist within the overall list
transactions = [[]]

#A list used to reset the for loop when a new HADM is encountered, needs to have an initial
#entry so I put "Start". This caused some empty entries at the beginning of the list but these entries were filtered out later
HADM = ["Start"]

#Array used to count to total number of drugs in the refined dataset
count = []

#Module used to filter by time and date
using Dates

#Reads each line of the input individually
for line in readlines(input_file)
	#Splits each line into an array based on the data type. For us, all we care about is 
	#[1] = HADM and [2] = The drug
	line_array = split(line, "\t")
	#Splits starttime into date and time: [1] = date; [2] = time
	Start_Date_Time = split(line_array[3], " ")
	#Splits charttime into date and time: [1] = date; [2] = time
	Chart_Date_Time = split(line_array[4], " ")
	
	#Filters out all drugs that were prescribed >48 hours before a hypotensive event. Only keeps drugs given within 48 hours of a hypotensive event
	if Date(Chart_Date_Time[1]) - Date(Start_Date_Time[1]) == Day(1) || Date(Chart_Date_Time[1]) - Date(Start_Date_Time[1]) == Day(0)
		#If the HADM of the line is equal to the last element in the HADM list, we are still working 
		#with the same HADM. The second logic segment is a way to filter out repeat drugs. If both
		#conditions are true, we move onto the next line because this is a repeat drug in the patient's drug list 
		if line_array[1] == last(HADM) && line_array[2] in temp
		#Removes non-drug entries from list. We filtered out the main ones and this decreased the dataset by over half
		elseif line_array[2] == "Sodium Chloride 0.9%  Flush" || 
			line_array[2] == "Chlorhexidine Gluconate 0.12% Oral Rinse" || 
			line_array[2] == "Sarna Lotion" || 
			line_array[2] == "Artificial Tears Preserv. Free" || 
			line_array[2] == "Artificial Tears" || 
			line_array[2] == "Artificial Tear Ointment" ||
			line_array[2] == "Vitamin D" ||
			line_array[2] == "Multivitamins" ||
			line_array[2] == "Multivitamins W/minerals" ||
			line_array[2] == "Multivitamin IV" ||
			line_array[2] == "Vitamin B Complex" ||
			line_array[2] == "Fish Oil (Omega 3)" ||
			line_array[2] == "Vitamin E"
		#Since the last 2 line filtered out any repeats and non-drug entries, this one adds any new unique drugs to
		#the temp list. The only condition this condition is checking is whether this is still the same patient using HADM 
		elseif line_array[1] == last(HADM)
			push!(temp, line_array[2])
		#Only lines with new HADM will get to the else statement and so we need to start a new
		#list. First, the temp list is added to the transactions list and the length of the temp list is added to count list
		#and then the temp list is reset for the next HADM
		else
			push!(transactions, temp)
			push!(count, length(temp))
			global temp = []
		end 
	end
	#This adds the HADM for the line we just finished looking at to the HADM list so that
	#we can determine whether the next HADM is identical or different
	push!(HADM, line_array[1])
end

#Counts total drugs in the filtered data set
total_drugs = sum(count)
print(total_drugs)

#This removes the 2 empty elements at the beginning of the list that may cause inaccuracy in the results. Given the size of the data we are using,
#these 2 elements wont impact the results much but if you are trying smaller subsets of data, they will have a bigger impact.
#1st element : empty bracket hard coded in to define the data type (needed to run ARules commands)
#2nd element : 1st HADM is compared to the "Start" in the HADM list and is sent to the else condition

accurate_transactions = transactions[3:(length(transactions))]
#print(accurate_transactions[1:5])

#Uses ARules module to generate association rules
using ARules 

#Association Rule Commands

#frequencies = frequent(accurate_transactions, 2, 2)
#print(frequencies)
rules = apriori(accurate_transactions, supp = 0.3, conf = 0.1, maxlen = 2)
print(rules)
  
