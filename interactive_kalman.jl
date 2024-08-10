using StatsPlots, Random, Distributions


# This is a basic program. I want it to initialize a point somewhere
# on the numberline between 1-100. 
# It will be initialized with global uncertainty, which will also be plotted. (uniform dist, 1-100)

# The user can press "m" to perform a measurement update -> which will take the point, add some noise to it,
# then plot a gaussian disribution around the sampled point. (normal dist, mean = sampled point + noise, std = measurement COV)

# The user can press left or right to move the point 1 space left or right, with added noise. They can press "p" to perform a prediction update
# This will perform the prediction step of the Kalman Filter, plotting the predicted gaussian  which will have increased covariance (update by motion model)

# The user can continue to press "m", to perform measurement updates, left and right to move the robot, and "p" to perform prediction updates.

# The user can press "q" to quit the program.
# The user can press "r" to reset the program, which will reinitialize the point on the numberline with global uncertainty.

@enum State INIT MOTION MEASUREMENT

struct Constants
    # Measurement noise
    R::Float64
    # Motion noise
    Q::Float64
end


const TRUTH_CONSTANTS = Constants(2, 1)
const ESTIMATED_CONSTANTS = Constants(3, 1)

mutable struct KalmanFilter
    mu::Float64
    sigma::Float64
end

mutable struct Robot
    point::Float64 # Ground Truth
    kf::KalmanFilter # Estimator
end

# Receives control, performs motion update step
function move_robot(robot::Robot, direction::String)
    # Determine which control was chosen
    if direction == "l"
        u = -5.0
    elseif direction == "r"
        u = 5.0
    end

    # Update the robot's truth point
    robot.point = robot.point + sample_truth_motion_model(u)

    # Update the robot's kalman filter
    robot_motion_update(robot, u)
    p = Plots.plot()
    xlims!(p, 0, 100)
    ylims!(p, 0, 1)
    plot_bot(robot, p)
    display(p)
end

function robot_motion_update(robot::Robot, u::Float64)
    # Update the robot's kalman filter
    robot.kf.mu = robot.kf.mu + u # Update the mean

    # Add the motion noise to the covariance
    robot.kf.sigma = robot.kf.sigma + ESTIMATED_CONSTANTS.Q
end

function update_robot(robot::Robot)
    # Sample a measurement that the sensor might return
    measurement_sample = sample_truth_measurement_model(robot.point)

    # Update the robot's kalman filter
    robot_measurement_update(robot, measurement_sample)

    # Plot changes
    p = Plots.plot()
    xlims!(p, 0, 100)
    ylims!(p, 0, 1)
    plot_bot(robot, p)
    # plot!(p, Normal(measurement_sample, TRUTH_CONSTANTS.R), label="Measurement Distribution")
    scatter!(p, [measurement_sample], [0], label="Measurement")
    display(p)
end

function robot_measurement_update(robot::Robot, z::Float64)
    # Compute the Kalman Gain
    # This is simplistic due to the 1D nature of the problem
    # This allows the matrix inversion to be replaced with division!
    K = robot.kf.sigma / (robot.kf.sigma + ESTIMATED_CONSTANTS.R)

    # Update the mean
    innovation = z - robot.kf.mu
    robot.kf.mu = robot.kf.mu + K * (innovation)

    # Update the covariance
    robot.kf.sigma = (1 - K) * robot.kf.sigma
end

# # x - vector of values
# function uniform(x)
#     s = size(x)[1]
#     return repeat([1 / s], s)
# end

## GROUND TRUTH SAMPLING FUNCTIONS

function sample_truth_motion_model(travel_dist::Float64)
    # Sample truth motion model from the point
    return rand(Normal(travel_dist, TRUTH_CONSTANTS.Q))
end

function sample_truth_measurement_model(point::Float64)
    # Sample a measurement from the point
    return rand(Normal(point, TRUTH_CONSTANTS.R))
end

## PLOTTING UTILITY

function plot_bot(robot::Robot, p::Any)
    scatter!(p, [robot.point], [0], label="Truth")

    plot!(Normal(robot.kf.mu, robot.kf.sigma), label="Belief Distribution")
end

# Entrypoint -- if "r" is pressed, should just re-execute main();
function main()
    # Initialize the robot -- requires starting point
    # and initial measurement

    p = Plots.plot()
    xlims!(p, 0, 100)
    ylims!(p, 0, 1)

    starting_point = rand(1.0:100.0)

    init_mu = sample_truth_measurement_model(starting_point)

    robot = Robot(starting_point, KalmanFilter(init_mu, ESTIMATED_CONSTANTS.R))
    plot_bot(robot, p)
    display(p)

    while true
        input = readline()
        if input ∈ ["q", "^C"]
            break
        elseif input == "i"
            main()
        elseif input ∈ ["m"]
            # todo
            update_robot(robot)
        elseif input ∈ ["l", "r"]
            move_robot(robot, input)
        elseif input == "s"
            print("Enter filename: ")
            filename = readline()
            savefig(filename)
        else
            print("Invalid Input. Press (q) to Quit")
        end
    end

    print("Exiting Program!")
end



main();