add_executable(${PROJECT_NAME} troll.m.cpp)

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_EXTENSIONS OFF)

set_target_properties(${PROJECT_NAME} PROPERTIES CXX_EXTENSIONS OFF)

# clangd completion
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)