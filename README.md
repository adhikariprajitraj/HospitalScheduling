# Hospital Scheduling Optimization in Julia

This project implements a nurse scheduling optimization system using Julia and JuMP. It generates realistic nurse and shift data and solves a Mixed-Integer Linear Programming (MILP) problem to assign shifts while respecting various constraints.

## Features

- **Data Generation**: Creates realistic profiles for nurses (Skill levels, Contract hours, Hourly rates) and shift demands.
- **Optimization Model**: Uses `JuMP` with the `HiGHS` solver to minimize total staffing costs.
- **Constraints**:
    - **Hard Constraints**:
        - Shift coverage (minimum nurses per shift).
        - Skill coverage (minimum senior nurses per shift).
        - Maximum one shift per day per nurse.
        - Minimum rest time (No Morning shift immediately after a Night shift).
        - Contract hour limits (Min/Max hours per period).

## Prerequisites

- **Julia**: Version 1.6 or higher.
- **Packages**: `JuMP`, `HiGHS`, `DataFrames`, `CSV`, `Dates`, `Random`.

## Installation

1. Clone this repository or copy the files.
2. Navigate to the project directory:
   ```bash
   cd HospitalScheduling
   ```

## Usage

To run the demonstration script, which generates data, solves the model, and prints the schedule:

```bash
julia scripts/run_demo.jl
```

The script will automatically install and instantiate the required dependencies defined in `Project.toml` on the first run.

## Project Structure

- `src/DataGenerator.jl`: Logic for generating nurses and shift requirements.
- `src/Scheduler.jl`: The JuMP optimization model formulation.
- `src/HospitalScheduling.jl`: Main package module.
- `scripts/run_demo.jl`: Entry point script.
- `Project.toml`: Dependency file.
