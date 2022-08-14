using DataFrames
using CSV
using FreqTables
using Query
using Dates
using DataFramesMeta

# read in drugs mapped onto ATC code
df_hypo = CSV.read("/gpfs/data/biol1555/projects/team6/code/atc_pairwise.csv", DataFrame)
df_all = CSV.read("/gpfs/data/biol1555/projects/team6/code/atc_all_list.csv", DataFrame)
# pairwise frequency matrix of hypo-preceding drugs
freq = freqtable(df_hypo, :ATC, :ATC_1)
# group the full prescription table by day and admission id
gdf_all = groupby(df_all, [:1, :3])

"""
n111: freqency of AE after prescription of both drugs within 24 hours
n11: number of reports with both drugs prescribed (if a drug is prescribed multiple times in the same day, number of report is 1)
f11: relative reporting rate of AE, given the co-prescription of two drugs
n001: freqency of AE with no prescription to either drug within 24 hours
n00: number of reports with neither drug prescribed
f00: relative reporting rate of AE, given no prescription of either drug
n101/n011: freqency of AE with prescription to one drug but not the other
n10/n01: number of reports with one drug prescribed but not the other
f10/f01: relative reporting rate of AE, given the prescription of one drug but not the other
"""
function da_estimate(drug1, drug2)
    n111 = freq[drug1, drug2]
    n11 = 0
    map(gdf_all) do d
        if drug1 in d.ATC && drug2 in d.ATC
            n11 += 1
        end
    end
    f11 = n111/n11
    n001 = 10283 - freq[drug1, drug1] - freq[drug2, drug2] + n111
    n00 = 0
    map(gdf_all) do d
        if !(drug1 in d.ATC) && !(drug2 in d.ATC)
            n00 += 1
        end
    end
    f00 = n001/n00
    n101 = freq[drug1, drug1] - n111
    n10 = 0
    map(gdf_all) do d
        if drug1 in d.ATC && !(drug2 in d.ATC)
            n10 += 1
        end
    end
    f10 = n101/n10
    n011 = freq[drug2, drug2] - n111
    n01 = 0
    map(gdf_all) do d
        if !(drug1 in d.ATC) && drug2 in d.ATC
            n01 += 1
        end
    end
    f01 = n011/n01

    g00 = f00/(1-f00)
    g10 = f10/(1-f10)
    g01 = f01/(1-f01)
    g10_adjusted = maximum([g00, g10])
    g01_adjusted = maximum([g00, g01])
    g11 = 1-1/(g10_adjusted + g01_adjusted - g00 +1)
    or = f11/g11

    alpha = 0.5
    omega = log2((n111 + alpha)/((g11*n11) + alpha))

    return or, omega
end

# read in original list of hypo-proceding drug list
df_hypo_original = CSV.read("/gpfs/data/biol1555/projects/team6/code/atc_list.csv", DataFrame)
gdf_hypo = groupby(df_hypo_original, :HADM_ID)
# push pairwise combination into arrays
pair = []
for i in 1:length(gdf_hypo)
    a = gdf_hypo[i].ATC
    if length(a) > 1
        for j in 1:(length(a)-1)
            for k in (j+1):length(a)
                push!(pair, [a[j],a[k]])
            end
        end
    end
end
unique!(pair)
# apply the DA function to each combination
or = []
omega = []
idx = 0
for i in pair
    est = da_estimate(i[1], i[2])
    push!(or, est[1])
    push!(omega, est[2])
    idx += 1
    print("$idx")
end

d1_col = getindex.(pair, 1)
d2_col = getindex.(pair, 2)
df_da = DataFrame(DRUG1 = d1_col, DRUG2 = d2_col, OR = or, OMEGA = omega)
CSV.write("//gpfs//data//biol1555//projects//team6//code//interaction.csv", df_da) 