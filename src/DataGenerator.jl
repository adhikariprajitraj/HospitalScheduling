module DataGenerator

using Random
using Dates
using DataFrames

export Nurse, Shift, generate_nurses, generate_demand, SKILL_LEVELS, SHIFT_TYPES

# --- Enums and Constants ---
@enum SkillLevel Trainee=1 Junior=2 Senior=3
@enum ShiftType Morning=1 Afternoon=2 Night=3

const SKILL_LEVELS = [Trainee, Junior, Senior]
const SHIFT_TYPES = [Morning, Afternoon, Night]

# --- Structs ---
struct Nurse
    id::Int
    name::String
    skill_level::SkillLevel
    contract_hours_min::Int
    contract_hours_max::Int
    hourly_rate::Float64
    preferences::Vector{Tuple{Date, ShiftType}} # (Date, ShiftType) tuples for preferred days off or specific shifts
end

struct Shift
    id::Int
    date::Date
    type::ShiftType
    duration_hours::Int
    required_nurses::Int
    min_seniors::Int
end

# --- Data Generation Functions ---

"""
    generate_nurses(n_nurses::Int)

Generates a list of `n_nurses` with random attributes.
"""
function generate_nurses(n_nurses::Int; seed::Int=42)
    Random.seed!(seed)
    nurses = Vector{Nurse}()
    names = ["Alice", "Bob", "Charlie", "Diana", "Evan", "Fiona", "George", "Hannah", "Ian", "Julia", "Kevin", "Laura", "Mike", "Nina", "Oscar", "Paula", "Quinn", "Rachel", "Steve", "Tina"]

    for i in 1:n_nurses
        name = rand(names) * " " * string(i)
        
        # Weighted skill distribution to ensure enough seniors
        # 40% Senior, 35% Junior, 25% Trainee
        r = rand()
        if r < 0.40
            skill = Senior
        elseif r < 0.75
            skill = Junior
        else
            skill = Trainee
        end
        
        # Contract details based on skill
        if skill == Senior
            min_h, max_h = 30, 48
            rate = 45.0
        elseif skill == Junior
            min_h, max_h = 24, 40
            rate = 30.0
        else # Trainee
            min_h, max_h = 20, 36
            rate = 20.0
        end

        # Random preferences (e.g., prefers not to work on some random days)
        # For simplicity, we'll just store them as a list of (Date, ShiftType) to AVOID
        # In a real app, this would be more complex.
        # Here, let's say they have 2 random preferences for the upcoming month
        prefs = Vector{Tuple{Date, ShiftType}}()
        
        push!(nurses, Nurse(i, name, skill, min_h, max_h, rate, prefs))
    end
    return nurses
end

"""
    generate_demand(start_date::Date, num_days::Int)

Generates shift requirements for a period of `num_days`.
"""
function generate_demand(start_date::Date, num_days::Int; seed::Int=42)
    Random.seed!(seed)
    shifts = Vector{Shift}()
    shift_id = 1

    for d in 0:(num_days-1)
        current_date = start_date + Day(d)
        is_weekend = dayofweek(current_date) >= 6

        for s_type in SHIFT_TYPES
            # Demand varies by shift type and weekend
            base_demand = is_weekend ? 3 : 5
            if s_type == Morning
                req = base_demand + rand(0:2)
                dur = 8
                min_sen = 2
            elseif s_type == Afternoon
                req = base_demand + rand(0:1)
                dur = 8
                min_sen = 1
            else # Night
                req = max(2, base_demand - 2)
                dur = 10 # Night shifts are longer
                min_sen = 1
            end

            push!(shifts, Shift(shift_id, current_date, s_type, dur, req, min_sen))
            shift_id += 1
        end
    end
    return shifts
end

end # module
