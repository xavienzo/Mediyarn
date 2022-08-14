using CSV
using DataFrames

# Hi, welcome to my program that checks for interaction between two drugs
# This program builds a dictionary based on data from interaction.csv file
# which contains the results of the Disproportionality Analysis.
# It asks the user for input in the form of drug ATC codes and then
# checks for the interaction between those drugs and returns the 
# associated risk for it. 

read_file = CSV.File("interaction.csv")
df = DataFrame(read_file)


library = Dict()
for i in 1:nrow(df)
    pair = (df[i,1], df[i,2])
    library[pair] = df[i,3]
end


println("Hi, please enter the ATC code of drug 1:")
drug1 = readline(stdin)
println("Please enter the ATC code for drug2:")
drug2 = readline(stdin)

while drug1 != "end"

    if haskey(library, (drug1, drug2))
        rr = library[(drug1, drug2)]
        println("The relative risk of prescribing these two drugs together is $rr")
    elseif haskey(library, (drug2, drug1))
        rr = library[(drug2, drug1)]
        println("The relative risk of prescribing these two drugs together is $rr")
    else
        println("Sorry, there is currently no information available on the usage of these two drugs together")
    end

    println("Hi, enter 'end' to finish your search or enter an ATC code to search for another interaction:")
    global drug1 = readline(stdin)
    if drug1 != "end"
        println("Please enter the ATC code for drug2:")
        global drug2 = readline(stdin)
    end

end