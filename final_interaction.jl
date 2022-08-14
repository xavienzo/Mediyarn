using CSV
using DataFrames

##################################################################
# Welcome to our Hypotension Drug Interaction Checker!
# This program asks the user for an input of 2 or more drugs.
# Determines and prints risk for the drug pairs that have known
# interactions based on the observed-to-expected ratio found from
# the Disproportionality Analysis.


# loading the data into a dataframe
read_file = CSV.File("interaction.csv")
df = DataFrame(read_file)


# creating a dataset of drug pairs with their OR values
library = Dict()
for i in 1:nrow(df)
    pair = (df[i,1], df[i,2])
    library[pair] = df[i,3]
end

# Beginning of the user-interface section
println("To begin your search for hypotension-related drug interactions, please enter the 4th-level ATC code of the first drug in your set.")
drug = readline(stdin)
drug_inputs = []

while drug != "."
    # preventing duplicates in list
    if !(drug in drug_inputs)
        push!(drug_inputs, drug)
    end

    # user enters "." to proceed to output the results or enters next code
    println("Please enter the 4th-level ATC code for the next drug, or enter \".\" to end the search.")
    global drug = readline(stdin)
end

# checking for invalid input
if length(drug_inputs) == 1
    println("Sorry, invalid input: only one drug code entered.")
else
    check_list = []
    # searches the dictionary and returns the risk of each valid drug pair
    println("The following information was found for the drugs you input:")
    for d1 in 1:length(drug_inputs)
        for d2 in 1:length(drug_inputs)
            drug1 = drug_inputs[d1]
            drug2 = drug_inputs[d2]

            if haskey(library, (drug1, drug2))
                println("Patients who experienced a hypotensive drug interaction were $(library[(drug1, drug2)]) times more likely to have taken $drug1 with $drug2 than patients who had not had a hypotensive drug interaction.")
                push!(check_list, 1)
            end
        end
    end
    if length(check_list) == 0
        println("Sorry, there is currently no available hypotensive relative risk information for the inputted drug list. To read more on the approaches and limitations of this system, visit: https://docs.google.com/presentation/d/1dMmokrhirSaBkudmBK2rCpzB9JyV2OGHKUylZpEJJjo/edit?usp=sharing")
    end    
end


