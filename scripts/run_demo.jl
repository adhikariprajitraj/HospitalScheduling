using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()

using HospitalScheduling
using HospitalScheduling.DataGenerator
using HospitalScheduling.Scheduler
using Dates
using JuMP

function main()
    println("=== Hospital Scheduling Optimization Demo ===")
    
    # 1. Generate Data
    println("\n[1] Generating Data...")
    start_date = Date(2023, 10, 23) # A Monday
    num_days = 7
    
    # Generate 20 nurses
    nurses = DataGenerator.generate_nurses(20)
    println("    Generated $(length(nurses)) nurses.")
    
    # Generate shifts for 1 week
    shifts = DataGenerator.generate_demand(start_date, num_days)
    println("    Generated $(length(shifts)) shifts for $num_days days.")

    # 2. Solve Optimization Problem
    println("\n[2] Solving Optimization Problem...")
    model, x = Scheduler.solve_schedule(nurses, shifts)
    
    status = termination_status(model)
    println("    Solver Status: $status")
    
    if status == MOI.OPTIMAL
        obj_val = objective_value(model)
        println("    Optimal Cost: \$$(round(obj_val, digits=2))")
        
        # 3. Display Results
        println("\n[3] Schedule:")
        
        # Extract assignment
        assignment = value.(x)
        
        # Print a simple schedule
        # Group by Day
        shifts_by_day = Dict{Date, Vector{Int}}()
        for s in 1:length(shifts)
            d = shifts[s].date
            if !haskey(shifts_by_day, d)
                shifts_by_day[d] = []
            end
            push!(shifts_by_day[d], s)
        end
        
        sorted_dates = sort(collect(keys(shifts_by_day)))
        
        for d in sorted_dates
            println("\n    Date: $d")
            day_shifts = shifts_by_day[d]
            # Sort shifts by type (Morning < Afternoon < Night)
            sort!(day_shifts, by = s -> shifts[s].type)
            
            for s_idx in day_shifts
                s = shifts[s_idx]
                assigned_nurses = [nurses[n].name for n in 1:length(nurses) if assignment[n, s_idx] > 0.5]
                println("      Shift $(s.type) ($(s.duration_hours)h): $(join(assigned_nurses, ", "))")
            end
        end
        
    else
        println("    No optimal solution found.")
    end
end

main()
