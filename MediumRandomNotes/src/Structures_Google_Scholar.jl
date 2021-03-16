# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
mutable struct Researcher
    Name::String
    URL::String
    Field::Array{SubString{String},1}
    N_cite::Int
    N_cite_2016::Int
    h_index::Int
    h_index_2016::Int
    ten_index::Int
    ten_index_2016::Int
    cite_time_series::Array{Int64,2}
    cite_20_paper::Array{Int64,2}
end
function Researcher(URL)
    r = HTTP.get(URL)
    r_parsed = parsehtml(String(r.body))
    Name = read_name(r_parsed)
    Field = read_fields(r_parsed)
    (N_cite, N_cite_2016, h_index, h_index_2016, ten_index, ten_index_2016) =
            read_cite_table(r_parsed)
    cite_time_series = read_cite_series(r_parsed)
    cite_20_paper = read_article_series(r_parsed)
    Researcher(Name, URL, Field, N_cite, N_cite_2016, h_index, h_index_2016,
               ten_index, ten_index_2016, cite_time_series, cite_20_paper)
end
export Researcher
