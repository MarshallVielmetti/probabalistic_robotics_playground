# TOY ROBOTICS EXAMPLES
Mostly reflective of the content of chapter 3 of Probabilistic Robotics by Sebastian Thrun

## INTERACTIVE_KALMAN
Toy kalman filter in 1 dimension

### Controls:
l, r to move the robot (stay within 0,100)
m to perform a measurement update

i to re initialize the program
q to quit

unfortunately these must be entered in the REPL.

### Underlying Motion Model
This simplistic robot has two controls - "l" and "r"
When either is executed, the robot attempts to move 5 units in the corresponding direction.
The actual amount moved is sampled from the ground truth distribution motion covariance Q.

### Motion Modeling
The underlying motion model is sampled as a normal distribution
Note that in this case that is correct-- the underlying motion model is normally distributed

It has estimated motion covariance Q.

### What Happens When You Move
Robot samples actual distance
Robot ground truth moves that distance

Kalman Filter estimate moves that distance, and the covariance is increased accordingly.

## efk_transform
Generates the plots from chapter 3.3 on the EKF

### How to Use
Can either use a linear transform, or input your own non-linear function
Unfortunately this has to be done by editing the file manually

### Examples
(Image showing example distribution)[sample_images/ekf_quadratic_transform.png]