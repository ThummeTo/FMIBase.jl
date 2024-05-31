#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
ToDo 
"""
const fmi3InstanceState = Cuint
export fmi3InstanceState

"""
ToDo 
"""
const fmi3InstanceStateInstantiated = Cuint(0)  # after instantiation
export fmi3InstanceStateInstantiated

"""
ToDo 
"""
const fmi3InstanceStateInitializationMode = Cuint(1)  # after finishing initialization
export fmi3InstanceStateInitializationMode

"""
ToDo 
"""
const fmi3InstanceStateEventMode = Cuint(2)
export fmi3InstanceStateEventMode

"""
ToDo 
"""
const fmi3InstanceStateStepMode = Cuint(3)
export fmi3InstanceStateStepMode

"""
ToDo 
"""
const fmi3InstanceStateClockActivationMode = Cuint(4)
export fmi3InstanceStateClockActivationMode

"""
ToDo 
"""
const fmi3InstanceStateContinuousTimeMode = Cuint(5)
export fmi3InstanceStateContinuousTimeMode

"""
ToDo 
"""
const fmi3InstanceStateConfigurationMode = Cuint(6)
export fmi3InstanceStateConfigurationMode

"""
ToDo 
"""
const fmi3InstanceStateReconfigurationMode = Cuint(7)
export fmi3InstanceStateReconfigurationMode

"""
ToDo 
"""
const fmi3InstanceStateTerminated = Cuint(8)
export fmi3InstanceStateTerminated

"""
ToDo 
"""
const fmi3InstanceStateError = Cuint(9)
export fmi3InstanceStateError

"""
ToDo 
"""
const fmi3InstanceStateFatal = Cuint(10)
export fmi3InstanceStateFatal
