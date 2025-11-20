module HospitalScheduling

include("DataGenerator.jl")
include("Scheduler.jl")

using .DataGenerator
using .Scheduler

export DataGenerator, Scheduler

end # module
