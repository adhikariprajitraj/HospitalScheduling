module Scheduler

using JuMP
using HiGHS
using Dates
using ..DataGenerator

export solve_schedule

"""
    solve_schedule(nurses::Vector{Nurse}, shifts::Vector{Shift})

Builds and solves the nurse scheduling problem.
Returns the model and the assignment matrix.
"""
function solve_schedule(nurses::Vector{Nurse}, shifts::Vector{Shift})
    # Create the optimization model
    model = Model(HiGHS.Optimizer)
    set_silent(model) # Suppress solver output for cleaner logs

    num_nurses = length(nurses)
    num_shifts = length(shifts)

    # --- Decision Variables ---
    # x[n, s] = 1 if nurse n is assigned to shift s, 0 otherwise
    @variable(model, x[1:num_nurses, 1:num_shifts], Bin)

    # --- Constraints ---

    # 1. Shift Coverage: Ensure enough nurses are assigned to each shift
    for s in 1:num_shifts
        @constraint(model, sum(x[n, s] for n in 1:num_nurses) >= shifts[s].required_nurses)
    end

    # 2. Skill Coverage: Ensure enough SENIOR nurses per shift
    for s in 1:num_shifts
        @constraint(model, sum(x[n, s] for n in 1:num_nurses if nurses[n].skill_level == DataGenerator.Senior) >= shifts[s].min_seniors)
    end

    # 3. One shift per day per nurse
    # We need to group shifts by day
    shifts_by_day = Dict{Date, Vector{Int}}()
    for s in 1:num_shifts
        d = shifts[s].date
        if !haskey(shifts_by_day, d)
            shifts_by_day[d] = []
        end
        push!(shifts_by_day[d], s)
    end

    for n in 1:num_nurses
        for (day, day_shifts) in shifts_by_day
            @constraint(model, sum(x[n, s] for s in day_shifts) <= 1)
        end
    end

    # 4. Rest Period: No Morning shift after a Night shift
    # Assuming shifts are ordered or we can find them.
    # We need to identify Night shifts on Day D and Morning shifts on Day D+1
    # Let's build a lookup
    # (Date, ShiftType) -> ShiftIndex
    shift_lookup = Dict{Tuple{Date, DataGenerator.ShiftType}, Int}()
    for s in 1:num_shifts
        shift_lookup[(shifts[s].date, shifts[s].type)] = s
    end

    sorted_dates = sort(collect(keys(shifts_by_day)))
    for i in 1:(length(sorted_dates)-1)
        d_curr = sorted_dates[i]
        d_next = sorted_dates[i+1]
        
        # Only relevant if days are consecutive
        if (d_next - d_curr) == Day(1)
            # Check if Night exists on d_curr and Morning on d_next
            if haskey(shift_lookup, (d_curr, DataGenerator.Night)) && haskey(shift_lookup, (d_next, DataGenerator.Morning))
                s_night = shift_lookup[(d_curr, DataGenerator.Night)]
                s_morning = shift_lookup[(d_next, DataGenerator.Morning)]
                
                for n in 1:num_nurses
                    @constraint(model, x[n, s_night] + x[n, s_morning] <= 1)
                end
            end
        end
    end

    # 5. Contract Hours (Weekly or Total for the period)
    # For simplicity, let's enforce Total Hours for the generated period
    # In a real system, this would be per-week.
    # Let's approximate: Total Min/Max scaled to the number of days
    # (Assuming the generated period is roughly a week or multiple of weeks)
    # Actually, let's just use the raw min/max from the nurse struct as "Period Limits" for this assignment
    for n in 1:num_nurses
        total_hours = sum(x[n, s] * shifts[s].duration_hours for s in 1:num_shifts)
        @constraint(model, total_hours >= nurses[n].contract_hours_min)
        @constraint(model, total_hours <= nurses[n].contract_hours_max)
    end

    # --- Objective Function ---
    # Minimize Total Cost
    # Cost = HourlyRate * Duration
    @objective(model, Min, 
        sum(x[n, s] * nurses[n].hourly_rate * shifts[s].duration_hours for n in 1:num_nurses, s in 1:num_shifts)
    )

    # --- Solve ---
    optimize!(model)

    return model, x
end

end # module
