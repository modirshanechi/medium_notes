# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Script for reading data for 500 most cited researchers in fields of comp. neuro.,
# ML, and high energy physics.
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
using HTTP
using Gumbo
using MediumRandomNotes
using JLD
using ProgressMeter
using Dates

N_page = 50
for Field = ["computational_neuroscience","machine_learning","high_energy_physics"]
    BaseAddress = "https://scholar.google.co.uk/citations?view_op=search_authors&hl=en&mauthors=label:"
    URL = [BaseAddress * Field]

    Rs = Array{Researcher,1}(undef,N_page*10)

    for j = 1:N_page
        @show (Field, j)
        Rs_temp, URL[1] = search_page_process(URL[1], Field; pause = 5 + exp(randn()))
        Rs[(j-1)*10 .+ (1:10)] .= Rs_temp
    end

    save("src/Google_scholar_data/Field" * Field * "_Npage" * string(N_page) *
         "_Date" * string(today()) * ".jld", "Rs", Rs, "Date", today())
end
