using GenieFramework, DataFrames, CSV
using DelimitedFiles
using Chron: UniformDistribution, HalfNormalDistribution, ExponentialDistribution, MeltsVolcanicZirconDistribution, BootstrapCrystDistributionKDE, metropolis_minmax, nanmean, nanpctile, nanstd
@genietools

#
# Logic goes here
#
Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

const FILE_DIR = "uploads"
mkpath(FILE_DIR)
@out title = "Bayesian Eruption Age Estimation"

route("/", method = POST) do
  files = Genie.Requests.filespayload()
  for f in files
      write(joinpath(FILE_DIR, f[2].name), f[2].data)
  end
  if length(files) == 0
      @info "No file uploaded"
  end
  return "Upload finished"
end

@in refresh = 1
@in calculate = 1
@in selected_file = ""
@out upfiles = readdir(FILE_DIR)

# Inputs
@out sigmas = [1, 2,]
@in input_sigma_level = 1
@out delimiters = [",", ";", "\ttab"]
@in selected_delimiter = ","
@out steps = [10_000, 100_000, 1_000_000,]
@in selected_steps = 100_000
@out burnins = [10_000,]
@in selected_burnin = 10_000
@out distributions = ["Bootstrapped", "Uniform", "Half-Normal", "Exponential", "Melts volcanic zircon"]
@in selected_dist = "Bootstrapped"

# Intermediate results
@out datatable = DataTable(DataFrame())
@out μ = [0.,]
@out σ = [0.,]
@out distribution = UniformDistribution
results = DataFrame(zeros(1,6), ["mean", "+", "-", "2.5% CI", "97.5% CI", "stdev"])
@out resultstable = DataTable(results)

# Plots
@out rankorder = PlotData()
@out distplot = PlotData()
@out resultsplot = PlotData()
@out markovplot = PlotData()
@out llplot = PlotData()


@handlers begin
    @onchange isready, refresh begin
        upfiles = readdir(FILE_DIR)
        filepath = joinpath(FILE_DIR, selected_file)
        if !isfile(filepath)
            selected_file = ""
        end
    end

    @onchange isready, selected_file, selected_delimiter, input_sigma_level, refresh begin
        filepath = joinpath(FILE_DIR, selected_file)
        if isfile(filepath)
            data = readdlm(filepath, Char(selected_delimiter[1]))
            if size(data,2) >= 2
                data[:,2] ./= input_sigma_level
                datasorted = sortslices(data, dims=1)
                μ = datasorted[:, 1]
                σ = datasorted[:, 2]
                rankorder = PlotData(
                    x=eachindex(μ),
                    xaxis="N",
                    y=μ,
                    yaxis="Age",
                    error_y=ErrorBar(array=σ),
                    plot=StipplePlotly.Charts.PLOT_TYPE_SCATTER,
                )
            else
                μ = [0.,]
                σ = [0.,]
                rankorder = PlotData()
            end
            if size(data, 2) == 2
                datatable = DataTable(DataFrame(data[:,:], ["μ", "σ"]))
            else
                datatable = DataTable(DataFrame(data[:,:], :auto))
            end
        end
    end

    @onchange μ, σ, selected_dist, input_sigma_level, refresh begin
        BootstrappedDistribution = BootstrapCrystDistributionKDE(μ, σ; cutoff=-0.05)

        dist = if selected_dist === "Bootstrapped"
            BootstrappedDistribution
        elseif selected_dist === "Uniform"
            UniformDistribution
        elseif selected_dist === "Half-Normal"
            HalfNormalDistribution
        elseif selected_dist === "Exponential"
            ExponentialDistribution
        elseif selected_dist === "Melts volcanic zircon"
            MeltsVolcanicZirconDistribution
        else
            UniformDistribution
        end

        distplot = PlotData(
            x=range(0,1,length=length(dist)),
            xaxis="Relative time",
            y=dist,
            yaxis="Probability density",
            plot=StipplePlotly.Charts.PLOT_TYPE_SCATTER,
        )

        distribution = copy(dist)
    end

    @onchange calculate begin
        tmindist, tmaxdist, lldist, acceptancedist = metropolis_minmax(selected_steps, distribution, μ, σ, burnin=selected_burnin)

        mu = nanmean(tmindist)
        l = nanpctile(tmindist, 2.5)
        u = nanpctile(tmindist, 97.5)
        stdev = nanstd(tmindist)

        results.mean .= mu
        results."+" .= u - mu
        results."-" .= mu - l
        results."2.5% CI" .= l
        results."97.5% CI" .= u
        results."stdev" .= stdev
        resultstable = DataTable(results)

        resultsplot= PlotData(
            x=tmindist,
            plot=StipplePlotly.Charts.PLOT_TYPE_HISTOGRAM,
        )
        llplot = PlotData(
            x=eachindex(lldist),
            y=lldist,
            plot=StipplePlotly.Charts.PLOT_TYPE_SCATTER,
        )
        markovplot = PlotData(
            x=eachindex(tmindist),
            y=tmindist,
            plot=StipplePlotly.Charts.PLOT_TYPE_SCATTER,
        )
    end

end

@page("/", "ui.jl")
Server.isrunning() || Server.up()
