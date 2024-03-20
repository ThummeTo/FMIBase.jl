#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
ToDo 
"""
const fmi2ComponentState = Cuint
export fmi2ComponentState

"""
ToDo 
"""
const fmi2ComponentStateInstantiated = Cuint(0)  # after instantiation
export fmi2ComponentStateInstantiated

"""
ToDo 
"""
const fmi2ComponentStateInitializationMode = Cuint(1)  # after finishing initialization
export fmi2ComponentStateInitializationMode

"""
ToDo 
"""
const fmi2ComponentStateEventMode = Cuint(2)
export fmi2ComponentStateEventMode

"""
ToDo 
"""
const fmi2ComponentStateContinuousTimeMode = Cuint(3)
export fmi2ComponentStateContinuousTimeMode

"""
ToDo 
"""
const fmi2ComponentStateTerminated = Cuint(4)
export fmi2ComponentStateTerminated

"""
ToDo 
"""
const fmi2ComponentStateError = Cuint(5)
export fmi2ComponentStateError

"""
ToDo 
"""
const fmi2ComponentStateFatal = Cuint(6)
export fmi2ComponentStateFatal
