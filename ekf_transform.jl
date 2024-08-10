using StatsPlots, Distributions, StatsBase, FiniteDifferences
using Printf

# This file is to generate the plot grids from chapter 3
# which show how an EKF linearizes the motion model

function make_linear_transform(a::Float64, b::Float64)
    return x -> a * x + b
end

function main()
    # Initiale distribution
    INIT_MEAN = 0
    INIT_VAR = 1
    p1 = plot(Normal(0, 1), label="Initial Distribution p(x)", xlims=(-5, 5), ylims=(0, 0.5), legend=:topright, xlabel="x", ylabel="p(x)", fill=(0, 0.5, :gray), linecolor=:black)

    # Transformation
    x = -5:0.1:5
    # f_x = make_linear_transform(-5.0, 0.5)

    f_x = x -> -(x + 5)^2 / 40

    y = f_x.(x)
    p2 = plot(x, y, label="Function g(x)", legend=:topright)

    # Calculate line for first order taylor
    f_prime_x = central_fdm(5, 1)(f_x, INIT_MEAN)
    b = f_x(INIT_MEAN)
    f_taylor_x = make_linear_transform(f_prime_x, b)
    y_taylor = f_taylor_x.(x)
    plot!(p2, x, y_taylor, label="First Order Taylor", legend=:topright)
    ylabel!(p2, "y = g(x)")
    xlabel!(p2, "x")



    # Now a couple of things msut be done.
    # 1. Perform a monte-carlo simulation to calculate the true distribution p(y)

    monte_x = rand(Normal(INIT_MEAN, INIT_VAR), 100000)
    monte_y = f_x.(monte_x)

    p3 = density(monte_y, label="Transformed Distribution", legend=:topleft, fill=(0, 0.5, :gray), linecolor=:black)

    # ylims!(p3, 0, 0.5)
    xlabel!("y")
    ylabel!("p(y)")

    # 2. Calculate mean and variance of the simulated data
    mean_y = mean(monte_y)
    var_y = var(monte_y)

    @printf("The resulting montecarlo mean is %f and variance is %f\n", mean_y, sqrt(var_y))
    @printf("The closed form linearized mean is %f and variance is %f\n", f_x(INIT_MEAN), abs(f_prime_x))

    plot!(p3, Normal(mean_y, sqrt(abs(var_y))), label="Monte-Carlo Approximation", legend=:topleft, linewidth=2, linestyle=:dash, linecolor=:black)
    plot!(p3, Normal(f_x(INIT_MEAN), abs(f_prime_x)), label="First Order Taylor", legend=:topleft, linewidth=2, linecolor=:black)

    vline!(p3, [mean_y], label="Monte Carlo Mean", legend=:topleft, linewidth=2, linestyle=:dash, linecolor=:black)
    vline!(p3, [f_x(INIT_MEAN)], label="Linearized Mean", legend=:topleft, linewidth=2, linecolor=:black)

    p = plot(p3, p2, p1, layout=@layout([a b; _ c]), size=(1200, 800))
    display(p)

    print("Press 'q' to quit, 's' to save the plot\n")

    while true
        input = readline()
        if input ∈ ["q", "^C"]
            break
        elseif input == "s"
            print("Enter filename: ")
            filename = readline()
            savefig(p, filename)
        end
    end
end

main()