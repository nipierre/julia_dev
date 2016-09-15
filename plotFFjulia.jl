Pkg.add("Gadfly")
Pkg.add("Glob")
Pkg.add("DataFrames")
Pkg.add("Formatting")
using Gadfly
using Glob
using DataFrames
using Formatting

xlim = [0.2, 0.85]
font = 132
line_style = [7, 3, 4, 10]
#colors = [ROOT.kAzure, ROOT.kRed, ROOT.kGreen+2, ROOT.kViolet, ROOT.kCyan, ROOT.kOrange]
#colors = [ROOT.kRed, ROOT.kBlue, ROOT.kBlack, ROOT.kGreen+2]

function read_ff_data(ff_data, additional_files, Q2)
    #=
    Read FFs from file.
    ff_data0 and mc_samples are lists of directories containing FFdataX files.
    A list of directories containing pandas data frames for each FF is returned.
    =#
    # files is a list of dicts of lists of files :)

      if ff_data
          files = [make_dirs(f) for f in ff_data]
          ff_names = get_particle_FF_names(args.particle)
          ff_data = [] # list of dictionaries with data frames
          for f in files
              ff_data.append(Dict())
              o = read_ff_data_Q2(f["original"][0], Q2)
              for name in ff_names
                  ff_data[-1][name] = DataFrame()
                  ff_data[-1][name]["z"] = o["z"]
                  ff_data[-1][name]["original"] = o[name]

                  # compute mean and rms values for stat and sys error bands
                  if f["mc_samples_stat"]
                      m = map(read_ff_data_Q2, f["mc_samples_stat"], [Q2]*len(f["mc_samples_stat"]))
                      m_zipped = zip([x[name] for x in m])
                      m_zipped = [filter(!isnan(x), m) for m in m_zipped]
                      ff_data[-1][name]["stat_mean"] = map(mean, m_zipped)
                      ff_data[-1][name]["stat_rms"] = map(std, m_zipped)
                  else
                      ff_data[-1][name]["stat_mean"] = None
                      ff_data[-1][name]["stat_rms"] = None
                  end
                  if f["mc_samples_sys"]
                      m = map(read_ff_data_Q2, f["mc_samples_sys"], [Q2]*len(f["mc_samples_sys"]))
                      m_zipped = zip([x[name] for x in m])
                      m_zipped = [filter(!isnan(x), m) for m in m_zipped]
                      ff_data[-1][name]["sys_mean"] = map(mean, m_zipped)
                      ff_data[-1][name]["sys_rms"] = map(std, m_zipped)
                  else
                      ff_data[-1][name]["sys_mean"] = None
                      ff_data[-1][name]["sys_rms"] = None
                  end
                  if f["mc_samples_pdf_sys"]
                      m = map(read_ff_data_Q2, f["mc_samples_pdf_sys"], [Q2]*len(f["mc_samples_pdf_sys"]))
                      m_zipped = zip([x[name] for x in m])
                      m_zipped = [filter(!isnan(x), m) for m in m_zipped]
                      ff_data[-1][name]["pdf_sys_mean"] = map(mean, m_zipped)
                      ff_data[-1][name]["pdf_sys_rms"] = map(std, m_zipped)
                  else
                      ff_data[-1][name]["pdf_sys_mean"] = None
                      ff_data[-1][name]["pdf_sys_rms"] = None
                  end
              end
          end
      end


      additional_data = []
      if additional_files
          for f in additional_files
              open(f,'r') do file
                  lines = file.readlines()
                  lines = map(l[:-1].split(), lines)
                  lines = [map(x.strip(), l) for l in lines]
                  names = lines[0]
              end
              FFs = [map(float, l) for l in lines[2:end]]
              FFs = DataFrame(FFs, columns=names)
              additional_data.append(FFs)
          end
      end

      return ff_data, additional_data
end

function read_ff_data_Q2(f, Q2, sep="\t"):
    #=
    Reads FFs for Q2.
    =#
    open(f,'r') do file
        lines = file.readlines()
        lines = map(l[:-1].split(sep), lines)
        lines = [map(x.strip(), l) for l in lines]
        names = lines[0]
    end

    for (i,l) in enumerate(lines)
        fe = FormatExp("Q2 = {}")
        if l[0] == fmt(fe,Q2)
            break
        end
    end

    FFs = [l for l in lines[i+1: i+67]]
    FFs = [map(float, l) for l in FFs]
    FFs = pd.DataFrame(FFs, columns=names)
    return FFs
end

function make_dirs(ff_data)
      #=
      Search directories for FFdata and return dictionary with list of files.
      If dir is 'None' set corresponding list of files to None.
      =#
      stat = glob.glob(ff_data + "/stat/mc_samples/FFdata*")
      sys = glob.glob(ff_data + "/sys/mc_samples/FFdata*")
      orig = glob.glob(ff_data + "/stat/unmodified/FFdata0")
      pdf = glob.glob(ff_data + "/pdf_sys/mc_samples/FFdata*")

      dict = ("original"=>orig, "mc_samples_stat"=>stat, "mc_samples_sys"=>sys, "mc_samples_pdf_sys"=>pdf)
      return dict
end

function get_particle_FF_names(p)
    #=
    Returns a list of p(article)'s FF names.
    =#
    titles = Dict("pi"=>["fav", "gluon", "unf"],
                  "pi+"=>["fav", "gluon", "unf"],
                  "K+"=>["fav", "gluon", "sbar", "unf"],
                  "K"=>["fav", "gluon", "sbar", "unf"],
                  "K0"=>["fav", "gluon", "sbar", "unf"],
                  "K_diff_cs"=>["fav", "unf"])
    return titles[p]
end

function get_particle_ylabel(p)
    ylabel = Dict("pi"=>["#font[12]{zD}_{fav}^{#pi} ",
                     "#font[12]{zD}_{g}^{#pi} ",
                     "#font[12]{zD}^{#pi}_{unf} "],
              "pi+"=>["#font[12]{zD}_{fav}^{#pi^{+}} ",
                      "#font[12]{zD}_{g}^{#pi^{+}} ",
                      "#font[12]{zD}^{#pi^{+}}_{unf} "],
              "K+"=>["#font[12]{zD}_{fav}^{K^{+}}",
                     "#font[12]{zD}_{g}^{K^{+}}",
                     "#font[12]{zD}_{s}^{K^{+}}",
                     "#font[12]{zD}^{K^{+}}_{unf}"],
              "K"=>["#font[12]{zD}_{fav}^{K}",
                     "#font[12]{zD}_{g}^{K}",
                     "#font[12]{zD}_{s}^{K}",
                     "#font[12]{zD}^{K}_{unf}"],
              "K0"=>["#font[12]{zD}_{fav}^{K^{0}}",
                     "#font[12]{zD}_{g}^{K^{0}}",
                     "#font[12]{zD}^{K^{0}}_{s}",
                     "#font[12]{zD}^{K^{0}}_{unf}"],
              "K_diff_cs"=>["#font[12]{zD}_{fav}^{K}",
                            "#font[12]{zD}^{K}_{unf}"])
    return ylabel[p]
end

function get_particles_FF_index(p, FF)
    FFs = Dict("pi"=>["fav", "gluon", "unf"],
               "pi+"=>["fav", "gluon", "unf"],
               "K+"=>["fav", "gluon", "sbar", "unf"],
               "K"=>["fav", "gluon", "sbar", "unf"],
               "K0"=>["fav", "gluon", "sbar", "unf"],
               "K_diff_cs"=>["fav", "unf"])
    return FFs[p].index(FF)
end
