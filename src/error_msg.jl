#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

const ERR_MSG_CONT_TIME_MODE = "Function must be called in mode continuous time!\nThis is most probably because the FMU errored before. If no messages are printed, check that the FMU message printing is enabled (this is tool dependent and must be selected during export) and follow the message printing instructions under https://thummeto.github.io/FMI.jl/dev/features/#Debugging-/-Logging"
ERR_MSG_NO_FMISENSITIVITY(
    varname,
    vartype,
) = "Wrong dispatched: `$(varname)` is `$(vartype)`.\nThis is most likely because you tried differentiating (AD) over a FMU.\nIf so, you need to `import FMISensitivity` first."
