import DBInterface
import MySQL
using DataFrames
using CSV
using Dates
using Query
using Serialization
using PharmaceuticalClassification

function with_password(f::F) where {F <: Function}
    Sys.iswindows() && throw(ErrorException("This function is not secure on Windows."))
    password_secretbuffer = Base.getpass("Please enter your password")
    result = f(password_secretbuffer)
    Base.shred!(password_secretbuffer)
    return result
end

function open_mysql_connection(; host::AbstractString, user::AbstractString)
    return with_password() do password_secretbuffer
        return DBInterface.connect(
            MySQL.Connection,
            host,
            user,
            String(read(password_secretbuffer));
            opts = Dict(MySQL.API.MYSQL_ENABLE_CLEARTEXT_PLUGIN => "true"),
            ssl_enforce = true,
        )
    end
end

function close_mysql_connection!(conn)
    return DBInterface.close!(conn)
end

function mysql_execute(conn, sql_statement)
    return DBInterface.execute(conn, sql_statement)
end

host = "pursamydbcit.services.brown.edu"
user = "ypan34"
conn = open_mysql_connection(; host, user)

DataFrame(mysql_execute(conn, "show databases;"))
mysql_execute(conn, "use mimiciiiv14;");

############hypo preceding drug list mapping#############
df = DataFrame(mysql_execute(conn, "
SELECT i.HADM_ID,i.NDC,i.DRUG,i.STARTDATE, d.CHARTTIME
FROM PRESCRIPTIONS AS i
INNER JOIN (SELECT DISTINCT HADM_ID, MIN(CHARTTIME) AS CHARTTIME FROM CHARTEVENTS WHERE ITEMID = '220179' AND VALUE < 90 GROUP BY HADM_ID) AS d
ON i.HADM_ID = d.HADM_ID
WHERE i.DRUG_TYPE != 'BASE'
AND i.HADM_ID = d.HADM_ID
AND i.STARTDATE <= d.CHARTTIME;
"))

# filter drugs within 24 hour
transform!(df, [:CHARTTIME, :STARTDATE] .=> ByRow(x -> Date(x)) .=> [:CDATE, :SDATE])
df.a = df.CDATE - df.SDATE
df1 = @from i in df begin
    @where i.a.value <= 1
    @select i.HADM_ID, i.NDC, i.DRUG, i.STARTDATE, i.CHARTTIME
    @collect DataFrame
end
dropmissing!(df1, :2)
df1 = unique(df1, [:1,:3])
rename!(df1, :2 => :NDC)
df2 = unique(select(df1, :2))

"""
If the ndc code can be mapped onto multiple atc class, the program will prioritize the cardiovascular class.
If the atc class does not include "C", the program will assign the first atc class alphabetically.
"""
graph = Serialization.deserialize("/gpfs/data/biol1555/projects/team6/code/my_graph_filename.serialized")
atc = []
for i in df2[!,:1]
    ndc = i
    ndc_node = PharmClass("NDC", ndc)
    if haskey(graph, ndc_node)
        pars = parents(graph, ndc_node);
        atc_node = filter(x -> startswith(x.system, "ATC4"), pars)
        atc_c = filter(x -> startswith(x.value, "C"), atc_node)
        if length(atc_c) > 0
            atc_value = atc_c[1].value
        elseif length(atc_c) == 0
            if length(atc_node) > 0
                atc_value = atc_node[1].value
            else
                atc_value =0
            end
        end
        push!(atc, atc_value)
    else
        atc_value = 0
        push!(atc, atc_value)
    end
end

df2[!,:ATC] = atc
rename!(df2, :1 => :NDC)
df3 = leftjoin(df1, df2, on = :NDC)
df4 = unique(select(df3, :1, :ATC))
df4 = df4[df4[:,2] .!= 0, :]

CSV.write("//gpfs//data//biol1555//projects//team6//code//atc_list_alt.csv", df4) 

############complete drug list mapping#############

df = DataFrame(mysql_execute(conn, "
SELECT HADM_ID, NDC, DRUG, STARTDATE 
FROM PRESCRIPTIONS
WHERE DRUG_TYPE != 'BASE';
"))
# if a drug is prescribed multiple times in the same day it will be counted as one occurrence
dropmissing!(unique!(df, [:1, :3, :4]), :2)
# map the list of unique NDCs to ATC
df1 = unique(select(df, :2))
graph = Serialization.deserialize("/gpfs/data/biol1555/projects/team6/code/my_graph_filename.serialized")
atc = []
for i in df1[!,:1]
    ndc = i
    ndc_node = PharmClass("NDC", ndc)
    if haskey(graph, ndc_node)
        pars = parents(graph, ndc_node);
        atc_node = filter(x -> startswith(x.system, "ATC4"), pars)
        atc_c = filter(x -> startswith(x.value, "C"), atc_node)
        if length(atc_c) > 0
            atc_value = atc_c[1].value
        elseif length(atc_c) == 0
            if length(atc_node) > 0
                atc_value = atc_node[1].value
            else
                atc_value =0
            end
        end
        push!(atc, atc_value)
    else
        atc_value = 0
        push!(atc, atc_value)
    end
end
# join the list of corresponding ATCs to the original data
df1[!,:ATC] = atc
df2 = leftjoin(df, df1, on = :NDC)
# keep ATC prescriptions unique each day
df3 = unique(df2, [:1, :4, :5])
df3 = df3[df3[:, 5] .!= 0, :]
select!(df3, :1, :5, :4)

CSV.write("//gpfs//data//biol1555//projects//team6//code//atc_all_list.csv", df3) 


close_mysql_connection!(conn)