##################################################################
# Hypotension Drug Interaction Checker Prototype
# Asks for user input of 2-n drugs
# Determines and prints relative risk ratio for available drug pairs
# This is a prototype tool and is merged with output from Disproportionality Analysis 
# See final_interaction.jl for final version

# array for user entry
drug_list_array = []
# dictionary for known interactions and relative risks
known_interactions_dict = Dict()
# Ultimately, we will import results from ypan34_disprop_analysis.jl into this dict
# keys are drug pairs (ATC codes as strings), values are relative risk
# example dictionary pairs
known_interactions_dict["C07AB02,C03AA03"] = 1.5
# metoprolol and HCTZ
known_interactions_dict["N05BA06,N05CD08"] = 2.0
# lorazepam and midazolam
known_interactions_dict["N05CD08,C07AB03"] = 1.3
# midazolam and atenolol
known_interactions_dict["a,b"] = 1.2
known_interactions_dict["b,c"] = 4
# testing pairs

# user entry sequence
println("To begin your search for hypotension-related drug interactions, please enter the ATC code of the first drug in your set.")
drug_code = readline(stdin)
#ask user to enter drugs, push drugs to drug_list_array
while drug_code != "done"
    push!(drug_list_array, drug_code)

    println("Please enter the ATC code for the next drug, or enter done to end the search.")
    global drug_code = readline(stdin)
end

println("Searching for interactions...")

println("The following pairs have returned interactions:")

# Scans each individual pair to see if it has an documented interaction in the known_interactions_dict
for n in 1:length(drug_list_array)
    for m in 1:length(drug_list_array)
        if haskey(known_interactions_dict, "$(drug_list_array[n]),$(drug_list_array[m])")

        
        println("$(drug_list_array[n]) and $(drug_list_array[m]) interact with RR = $(known_interactions_dict["$(drug_list_array[n]),$(drug_list_array[m])"])")
        end
    end
end

# test input "a" "t" "d" "c" "b" "done" should return two interactions (b and c -> 1.2, a and b -> 4)

