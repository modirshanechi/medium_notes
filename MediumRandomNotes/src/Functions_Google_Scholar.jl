# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# A simple function for concatinating an array of strings to a single string
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function comb_text(word_vec::Array{SubString{String},1};space = " ")
    word_cat = [word_vec[1]]
    for i = 2:length(word_vec)
        word_cat[1] = word_cat[1] * space * word_vec[i]
    end
    word_cat[1]
end
export comb_text

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading the name of researcher given the parsed html
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function read_name(r_parsed)
    word_vec = split(r_parsed.root[1][1][1].text, " ")
    inds = 1:length(word_vec)
    dash_ind = inds[word_vec .== "-"]
    name = word_vec[1:(dash_ind[1]-1)]
    comb_text(name)
end
export read_name

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading the table of citations given the parsed html
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function read_cite_table(r_parsed)
    cite = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][1][2][1].text)
    cite_2016 = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][1][3][1].text)
    h_ind = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][2][2][1].text)
    h_ind_2016 = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][2][3][1].text)
    ten_ind = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][3][2][1].text)
    ten_ind_2016 = parse(Int,r_parsed.root[2][1][16][2][1][1][2][2][2][3][3][1].text)

    cite, cite_2016, h_ind, h_ind_2016, ten_ind, ten_ind_2016
end
export read_cite_table

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading the fields of expertise of a researcher given the parsed html
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function read_fields(r_parsed)
    word_vec = split(r_parsed.root[1][9].attributes["content"], " - ")
    if length(word_vec)>2
        return word_vec[3:end]
    else
        return []
    end
end
export read_fields

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading the cite-series given the parsed html
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function read_cite_series(r_parsed)
    N_years = Int(length(r_parsed.root[2][1][16][2][1][1][2][4][3][1].children) / 2)
    cite_series = Int.(zeros(N_years,2))
    for i = 1:N_years
        cite_series[i,1] = parse(Int,r_parsed.root[2][1][16][2][1][1][2][4][3][1][i][1].text)
        cite_series[i,2] = parse(Int,r_parsed.root[2][1][16][2][1][1][2][4][3][1][N_years+i][1][1].text)
    end
    return cite_series
end
export read_cite_series

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading citations of the 1st 20 most cited papers given the parsed html
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function read_article_series(r_parsed)
    N_article = length(r_parsed.root[2][1][16][2][1][4][1][2][1][2].children)
    article_series = Int.(zeros(N_article,2))
    for i = 1:N_article
        if length(r_parsed.root[2][1][16][2][1][4][1][2][1][2][i][3][1].children) == 0
            article_series[i,1] = -1
        else
            article_series[i,1] = parse(Int,r_parsed.root[2][1][16][2][1][4][1][2][1][2][i][3][1][1].text)
        end
        if length(r_parsed.root[2][1][16][2][1][4][1][2][1][2][i][2][1].children) == 0
            article_series[i,2] = 0
        else
            article_series[i,2] = parse(Int,r_parsed.root[2][1][16][2][1][4][1][2][1][2][i][2][1][1].text)
        end
    end
    return article_series
end
export read_article_series


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Access functions
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function access_N_cite(R)
    R.N_cite
end
export access_N_cite

function access_h_index(R)
    R.h_index
end
export access_h_index

function access_ten_index(R)
    R.ten_index
end
export access_ten_index

function access_1st_field(R)
    R.Field[1]
end
export access_1st_field

function access_most_cited(R;i=1)
    R.cite_20_paper[i,2]
end
export access_most_cited

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Reading the information of all researcher from a single search page
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function search_page_process(URL, Field; pause = 2)
    r = HTTP.get(URL)
    r_parsed = parsehtml(String(r.body))
    Rs = Array{Researcher,1}(undef,10)
    @showprogress 1 for i = 1:10
        sleep(pause)
        URL_researcher = get(r_parsed.root[2][1][11][2][1][i][1][1].attributes, "href", "")
        URL_researcher = "https://scholar.google.com" * URL_researcher * "&hl=en"
        Rs[i] = Researcher(URL_researcher)
    end

    word_vec = split(get(r_parsed.root[2][1][11][2][1][11][1][3].attributes, "onclick", ""), "\\")
    num_start = word_vec[end][4:(end-1)]
    after_author = word_vec[end-2][4:end]
    Next_URL = "https://scholar.google.co.uk/citations?view_op=search_authors&hl=en&mauthors=label:" *
                Field * "&after_author=" * after_author * "&astart=" * num_start

    return Rs, Next_URL
end
export search_page_process

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Functions for Bayesian inference over parameters of the power law
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
function predict_power_law(x;a=0.5,b=0.5)       # y = a x^b
    y_hat = a .* (x.^b)
end

function weighted_predict_power_law(x;a_s=[0.5],b_s=[0.5],w=[1.])       # y = a x^b
    a_s_prime = a_s[w .> 0]
    b_s_prime = b_s[w .> 0]
    w = w[w .> 0]
    Y = zeros(length(w),length(x))
    for i = 1:length(w)
        Y[i,:] .= predict_power_law.(x;a=a_s_prime[i],b=b_s_prime[i])
    end
    y = w' * Y
end

function logl_power_law(x,y;a=0.5,b=0.5,σ=0.5)  # log(y) = log(a x^b) + Normal(0,σ)
    y_hat = predict_power_law(x;a=a,b=b)
    res = log.(y) .- log.(y_hat)
    - sum( ((y .- y_hat).^2)./(2*σ^2) .+ log(σ)  )
end

function prior_param(N_sample; a_min = 0, a_max = 2,
                               b_min = 0, b_max = 2,
                               σ_min = 0, σ_max = 200)
    a_s = a_min .+ (a_max-a_min) .* rand(N_sample)
    b_s = b_min .+ (b_max-b_min) .* rand(N_sample)
    σ_s = σ_min .+ (σ_max-σ_min) .* rand(N_sample)

    return a_s, b_s, σ_s
end

function importance_weight(x,y,a_s,b_s,σ_s)
    N_sample = length(a_s)
    LL = zeros(N_sample)
    for i=1:N_sample
      a=a_s[i]
      b=b_s[i]
      σ=σ_s[i]
      LL[i] = logl_power_law(x,y;a=a,b=b,σ=σ)
    end
    ll = exp.(LL .- findmax(LL)[1])
    w = ll ./ sum(ll)
end
