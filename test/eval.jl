#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

using PkgEval
using FMIBase

config = Configuration(; julia = "1.10");

package = Package(; name = "FMIBase");

@info "PkgEval"
result = evaluate([config], [package])

@info "Result"
println(result)

@info "Log"
println(result.log)
