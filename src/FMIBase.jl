#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

module FMIBase

using Reexport
@reexport using FMICore
import FMICore: Creal

using Requires
import ChainRulesCore
import Base: show

# just load to make it available in other packages
import EzXML
import ZipFile

include("utils.jl")
include("error_msg.jl")
include("log_level.jl")

include("struct.jl")
include("io.jl")
include("FMI2/helper.jl")
include("FMI3/helper.jl")
include("FMI2/struct.jl")
include("FMI3/struct.jl")

include("base.jl")
include("printing.jl")

include("convert.jl")
include("md.jl")

include("FMI2/eval.jl")
include("FMI3/eval.jl")
include("eval.jl")

include("callbacks.jl")
include("setup.jl")
include("logging.jl")
include("sense.jl")
include("snapshot.jl")
include("valueRefs.jl")

# Requires init
function __init__()
    @require FMISensitivity="3e748fe5-cd7f-4615-8419-3159287187d2" begin
        import .FMISensitivity
        include("extensions/FMISensitivity.jl")
    end
    @require JLD2="033835bb-8acc-5ee8-8aae-3f567f8a3819" begin
        import .JLD2
        include("extensions/JLD2.jl")
    end
    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        import .DataFrames
        include("extensions/DataFrames.jl") 
        @require CSV="336ed68f-0bac-5ca0-87d4-7b16caf5d00b" begin
            import .CSV
            include("extensions/CSV.jl")   
        end
    end
    @require MAT="23992714-dd62-5051-b70f-ba57cb901cac" begin
        import .MAT
        include("extensions/MAT.jl")   
    end
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
        import .Plots
        include("extensions/Plots.jl")
    end
end

end # module FMIBase
