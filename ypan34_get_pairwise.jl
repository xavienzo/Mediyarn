# Program that creates all possible pairwise ATC combinations before the hypotensive reading for each HADM_ID

using DataFrames
using CSV

# read in hypo-preceding drugs
df_hypo = CSV.read("/gpfs/data/biol1555/projects/team6/code/atc_list.csv", DataFrame)
# group by id
gdf = groupby(df_hypo, :HADM_ID)
length(gdf) #10283 reports
# empty dataframe to record crossjoined tables
df_cross = DataFrame(HADM_ID = Int64[], ATC = String[], HADM_ID_1 = Int64[], ATC_1 = String[])
# crossjoin each group to create all possible pairwise combinations
for i in (1:length(gdf))
    gdf_cross = crossjoin(gdf[i], gdf[i], makeunique = true)
    global df_cross = [df_cross; gdf_cross]
end

CSV.write("//gpfs//data//biol1555//projects//team6//code//atc_pairwise.csv", df_cross)
