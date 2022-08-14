################################################################################
#
# Program: agreen10_ATC_transactions.jl
# Purpose: Association rule mining of MIMIC-III data converted into ATC codes
# Description: MIMIC-III drug list data converted to ATC codes is formatted 
#	into a list of lists in order to generate association rules to determine which
#	drug class pairings are associated with hypotensive adverse drug interctions	
# Created by: Allen Green
# Created on: 2021-04-11
# Last modified by: Allen Green
# Last modified on: 2021-04-16
#
################################################################################

#Reads in Query File
#****MAKE SURE YOU CHANGE TO PATH TO WHERE YOU STORE THE .CSV FILE****
input_file = open("/users/agreen10/data/projects/team6/data/atc_all_list.csv", "r")

#A Temporary list that is reset for each HADM, stores the ATC codes for each unique
#HADM ID until that list is ready to be pushed to transactions
temp = []

#A list of lists showing the unique ATC codes for each HADM as a list within the overall list
transactions = [[]]

#A list used to reset the for loop when a new HADM is encountered, needs to have an initial
#entry so I put "Start"
HADM = ["Start"]

#Reads each line of the input individually
for line in readlines(input_file)
	#Splits each line into an array based on the data type. For us, all we care about is 
	#[1] = HADM and [2] = ATC Code
	line_array = split(line, ",")
	#If the HADM of the line is equal to the last element in HADM, we are still working 
	#with the same HADM. The second portion of the condition is a way to skip over repeat codes. If both
	#conditions are true, we have a repeat ATC code so we move onto the next line 
	if line_array[1] == last(HADM) && line_array[2] in temp
	#This condition adds unique ATC codes to the temp list
	elseif line_array[1] == last(HADM)
		push!(temp, line_array[2])
	#Only lines with new HADM will get to the else statement and so we need to start a new
	#list. First, the temp list is added to the transactions list
	#and then the temp list is reset for the next HADM
	else
		push!(transactions, temp)
		global temp = []
	end 
#This adds the HADM for the line we just finished looking at to the HADM list so that
#we can determine whether the next HADM is identical or different
push!(HADM, line_array[1])
end

#This removes the 3 empty elements at the beginning of the list that may cause inaccuracy in the results. Given the size of the data we are using
#these 3 elements wont impact the results much but if you are trying smaller subsets of data, they will have a bigger impact.
#1st element : empty bracket hard coded in to define the data type (needed to run ARules commands)
#2nd element : 1st HADM is compared to "Start" which sends the if statement to the else command
#3rd element : 2nd HADM (1st real number) is compared to the 1st HADM which is the column title (HADM_ID) and sends the if statement to the else command

accurate_transactions = transactions[4:(length(transactions))]
#print(accurate_transactions[1:10])

#Uses ARules module to generate association rules
using ARules 

#Association Rule Commands

#frequencies = frequent(accurate_transactions, 2, 2)
#print(frequencies)
rules = apriori(accurate_transactions, supp = 0.2, conf = 0.3, maxlen = 2)
print(rules)
