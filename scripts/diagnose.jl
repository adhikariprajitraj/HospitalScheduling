using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using HospitalScheduling
using HospitalScheduling.DataGenerator
using Dates

function diagnose()
    println("=== Diagnostic Report ===")
    
    start_date = Date(2023, 10, 23)
    num_days = 7
    
    nurses = DataGenerator.generate_nurses(20)
    shifts = DataGenerator.generate_demand(start_date, num_days)
    
    # Count nurses by skill level
    skill_counts = Dict()
    for nurse in nurses
        skill = nurse.skill_level
        skill_counts[skill] = get(skill_counts, skill, 0) + 1
    end
    
    println("\n[Nurses by Skill Level]")
    for (skill, count) in skill_counts
        println("  $skill: $count")
    end
    
    # Analyze shift requirements
    println("\n[Shift Requirements]")
    total_required = 0
    total_senior_required = 0
    
    for shift in shifts
        total_required += shift.required_nurses
        total_senior_required += shift.min_seniors
        println("  $(shift.date) $(shift.type): needs $(shift.required_nurses) nurses, $(shift.min_seniors) seniors")
    end
    
    println("\n[Summary]")
    println("  Total nurses: $(length(nurses))")
    println("  Total senior nurses: $(get(skill_counts, DataGenerator.Senior, 0))")
    println("  Total shifts: $(length(shifts))")
    println("  Total nurse-slots needed: $total_required")
    println("  Total senior-slots needed: $total_senior_required")
    
    # Check if we have enough seniors
    num_seniors = get(skill_counts, DataGenerator.Senior, 0)
    max_senior_shifts = num_seniors * num_days  # Assuming max 1 shift per day
    
    println("\n[Feasibility Check]")
    println("  Max senior shifts possible (1/day): $max_senior_shifts")
    println("  Total senior slots required: $total_senior_required")
    
    if max_senior_shifts < total_senior_required
        println("  ⚠️  NOT FEASIBLE: Not enough senior nurses!")
    else
        println("  ✓ Senior constraint seems feasible")
    end
end

diagnose()
