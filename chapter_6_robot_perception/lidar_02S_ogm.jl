# Generates an occupancy grid map from a LIDAR scan
# uses the LIDAR scan data from the file 02S_lidar.dat

# This is a stationary dataset, so the robot pose can be assumed to be constant
# this solves the issue of the robot pose being unknown

# The LIDAR scan data is stored in the file 02S_lidar.dat
# The data is stored in the format of a 2D array, with each row representing a scan

# [time(s)] [x(m)] [y(m)] [z(m)] [i(dB)]

using DataFrames, CSV, StatsPlots, DataFramesMeta


function read_lidar_data(file_path)
    return CSV.read(file_path, DataFrame; header=["time", "x", "y", "z", "i"], skipto=2, delim=' ', ignorerepeated=true)
end

function read_radar_data(file_path)
    return CSV.read(file_path, DataFrame; header=["time", "x", "y", "p"], skipto=2, delim=' ', ignorerepeated=true)
end


function plot_lidar_data(lidar_data)

    trimmed = @view lidar_data[1:1000:end, :]

    title = plot(title="Scatter Plot of LIDAR Data", grid=false, showaxis=false, bottom_margin=-50Plots.px)
    # Plot the LIDAR data
    p1 = plot(trimmed.x, trimmed.y, trimmed.z, seriestype=:scatter, legend=false, xlabel="x", ylabel="y", zlabel="z")

    p2_subset = @subset(lidar_data, :x .< 10, :x .> 0, :z .< 0.2, :z .> -0.2)
    p2 = plot(p2_subset.x, p2_subset.y, seriestype=:scatter, legend=false, xlabel="x", ylabel="y")
    p3 = plot(trimmed.x, trimmed.z, seriestype=:scatter, legend=false, xlabel="x", ylabel="z")
    p4 = plot(trimmed.y, trimmed.z, seriestype=:scatter, legend=false, xlabel="y", ylabel="z")
    xlims!(p4, (-5, 5))
    ylims!(p4, (-3, 7))

    p = plot(title, p1, p2, p3, p4, layout=@layout([A{0.01h}; B C; D E]), size=(1200, 800))
    display(p)
end

function plot_radar_data(radar_data)
    p = plot(radar_data.x, radar_data.y, marker_z=radar_data.p, seriestype=:scatter, xlabel="x", ylabel="y", title="Scatter Plot of 2D-RADAR Data", legend=false)
    display(p)
end

function calibrate_radar_data()
    radar_data = read_radar_data("datasets/02S/02S_radar.dat")

    # @transform!(radar_data, r = sqrt(radar_data.x^2 + radar_data.y^2))
    # @transform!(radar_data, adj=

    # p = plot(radar_data.x, radar_data.y, marker_z=radar_data.p, seriestype=:scatter, xlabel="x", ylabel="y", title="Scatter Plot of 2D-RADAR Data", legend=false)
    p = density(radar_data.p, xlabel="p", ylabel="p(p)", title="Density Plot of 2D-RADAR Data", legend=false)
    display(p)
end

function display_lidar_data()
    println("Reading LIDAR data...")
    lidar_data = read_lidar_data("datasets/02S/02S_lidar.dat")

    println("Plotting requests")
    plot_lidar_data(lidar_data)
end

function display_radar_data()
    println("Reading 2D-RADAR data...")
    radar_data = read_radar_data("datasets/02S/02S_radar.dat")

    # trimmed = @view radar_data[1:500:end, :]
    # filtered = @view filter!([:p], p -> p > 80, radar_data)
    filtered = @rsubset radar_data :p > 80

    println("Plotting requests")
    plot_radar_data(filtered)
end

# Data ranges from y: -5 to 5, z: -5 to 5
function lidar_level_heat_map()
    lidar_data = read_lidar_data("datasets/02S/02S_lidar.dat")

    # Only return a slice of z data, near level
    @subset!(lidar_data, :x .> 0, :z .< 0.2, :z .> -0.2)

    # Create a 2D grid
    grid = zeros(120, 120)

    # Iterate over the LIDAR data
    for i in 1:size(lidar_data, 1)
        x = Int(round(lidar_data.x[i] * 10))
        y = Int(round(lidar_data.y[i] * 10)) + 60

        if x >= 1 && x <= 120 && x >= 1 && y <= 120
            grid[y, x] = 1 # This is weird but gives correct orientation (think rows, cols)
        end
    end

    p = heatmap(grid, title="Heatmap of LIDAR Data, |z| < 0.2", xlabel="x", ylabel="y", legend=false)
    display(p)
end

function main()
    println("02S LiDar Explorer")
    println("l: Display LIDAR data")
    println("lh: Lidar Level-Slice Heatmap")
    println("r: Display 2D-RADAR data")
    println("cr: Calibrate radar data")

    print("Select Mode: ")
    input = readline()

    if input == "l"
        println("Displaying LIDAR Data:")
        display_lidar_data()
    elseif input == "lh"
        println("Lidar Level-Slice Heatmap")
        lidar_level_heat_map()
    elseif input == "r"
        println("Displaying 2D-RADAR Data:")
        display_radar_data()
    elseif input == "cr"
        println("Plotting Radar Calibration Data")
        calibrate_radar_data()
    else
        println("Invalid input")
        main()
    end


    println("q: Quit, s: Save Plot, r: Restart")
    while (true)
        input = readline()
        if input == "q"
            break
        elseif input == "r"
            main()
            break
        elseif input == "s"
            print("Enter filename: ")
            filename = readline()
            savefig(filename)
        end
    end

    println("Exiting...")
end

main()