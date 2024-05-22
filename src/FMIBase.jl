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

# just load to make it available in other packages (FMIImport, FMIExport)
import EzXML
import ZipFile
import SciMLBase
import DiffEqCallbacks

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

include("common.jl")
include("eval.jl")

include("get_set.jl")
include("callbacks.jl")
include("setup.jl")
include("logging.jl")
include("sense.jl")
include("snapshot.jl")
include("valueRefs.jl")
include("info.jl")

# extensions
using PackageExtensionCompat
function __init__()
    @require_extensions
end

# CSV.jl
function saveSolutionCSV end
function loadSolutionCSV end

# DataFrames.jl
# [Note] nothing to declare

# ForwardDiff.jl
# [Note] nothing to declare

# JLD2.jl
function saveSolutionJLD2 end 
function loadSolutionJLD2 end

# MAT.jl
function saveSolutionMAT end 
function loadSolutionMAT end

# Plots.jl
# [Note] nothing to declare

# ReverseDiff.jl
# [Note] nothing to declare

end # module FMIBase
