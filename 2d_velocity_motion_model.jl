using Plots, Distributions

gr();


struct Robot
    x::Float64
    y::Float64
    theta::Float64
end

struct Control
    v::Float64
    ω::Float64
end

# alphas
# const α = [0.1, 0.01, 0.01, 0.1, 0.01, 0.05]
const α = [0.1, 0.1, 0.01, 1, 0.1, 0.5]

function sample(variance::Float64)
    return rand(Normal(0, variance))
end

# sample_motion_model_velocity, taken from Probabilistic Robotics Ch. 5.3
function sample_motion_model_velocity(x::Robot, u::Control, dt::Float64)
    v_hat = u.v + sample(u.v^2 * α[1] + u.ω^2 * α[2])
    ω_hat = u.ω + sample(u.v^2 * α[3] + u.ω^2 * α[4])

    # γ is error added to final orientation
    γ_hat = sample(u.v^2 * α[5] + u.ω^2 * α[6])

    x_prime = x.x - (v_hat / ω_hat) * sin(x.theta) + (v_hat / ω_hat) * sin(x.theta + ω_hat * dt)
    y_prime = x.y + (v_hat / ω_hat) * cos(x.theta) - (v_hat / ω_hat) * cos(x.theta + ω_hat * dt)
    theta_prime = x.theta + ω_hat * dt + γ_hat * dt

    return Robot(x_prime, y_prime, theta_prime)
end

function circleShape(h, k, r)
    θ = LinRange(0, 2 * π, 500)
    x = h .+ r * cos.(θ)
    y = k .+ r * sin.(θ)
    return x, y
end

function montecarlo_sim(robot::Robot, control::Control, steps::Int, dt::Float64, num_particles::Int)
    intermediary_results = []
    final_results = []

    # Perform montecarlo
    for i in 1:num_particles
        particle = robot
        for j in 1:steps/2
            particle = sample_motion_model_velocity(particle, control, dt)
        end
        push!(intermediary_results, particle)
        for j in 1:steps/2
            particle = sample_motion_model_velocity(particle, control, dt)
        end
        push!(final_results, particle)
    end

    return intermediary_results, final_results
end

function plot_control(robot::Robot, control::Control)
    # Plot initial position
    scatter!([robot.x], [robot.y], label="Initial Position", legend=:topleft, markercolor=:red, markersize=5)

    # Compute the circle senter, and draw the circle
    radius = control.v / control.ω
    x_c = robot.x - radius * sin(robot.theta)
    y_c = robot.y + radius * cos(robot.theta)

    circle = circleShape(x_c, y_c, radius)
    plot!(circle, seriestype=[:shape], fillalpha=0.0, lw=2, label="Motion Path", legend=:topleft)
end

function plot_results(intermediary_results, final_results)
    # Plot the results
    scatter!([r.x for r in intermediary_results], [r.y for r in intermediary_results], label="Intermediary Results", legend=:topleft)
    scatter!([r.x for r in final_results], [r.y for r in final_results], label="Final Results", legend=:topleft)
end



function main()
    # Initialize Robot State -- Assume Known
    robot = Robot(0, 0, 0)

    control = Control(1.5, 0.2)

    # Initialize Simulation parameters 
    steps = 100
    dt = 0.1
    num_particles = 100

    # p = plot(xlims=(-10, 10), ylims=(-10, 10), legend=:topleft, xlabel="x", ylabel="y")
    p = plot(xlabel="x", ylabel="y")
    intermediary_results, final_results = montecarlo_sim(robot, control, steps, dt, num_particles)
    plot_control(robot, control)
    plot_results(intermediary_results, final_results)

    display(p)

    while true
        input = readline()
        if input == "q"
            break
        elseif input == "r"
            control = Control(rand(Uniform(0, 2)), rand(Uniform(-0.5, 0.5)))
            print("New Control: v = $(control.v), ω = $(control.ω)\n")

            intermediary_results, final_results = montecarlo_sim(robot, control, steps, dt, num_particles)
            p = plot(xlabel="x", ylabel="y")
            plot_control(robot, control)
            plot_results(intermediary_results, final_results)
            display(p)
        elseif input == "s"
            print("Enter filename: ")
            input = readline()
            savefig(p, input)
        end
    end
end

main()

# WebIO.webio_serve(page("/", req -> main(req)), 8000)