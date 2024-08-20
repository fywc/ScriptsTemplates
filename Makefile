###############################################################################
# Basic Makefile 
###############################################################################

# Use Bash sdf
SHELL = /bin/bash

# $(AR)    # 生产 archive 文件的默认程序 ar
# $(CC)    # 编译 C 代码的默认编译器 cc
# $(CXX)   # 编译 C++ 代码的默认编译器 g++
# $(ARFLAGS)   # ar 的参数 'rv'
# $(CFLAGS)    # 编译 C 代码的参数
# $(CXXFLAGS)  # 编译 C++ 代码的参数
# $(CPPFLAGS)  # C 代码预编译的参数

#Arch ?= ARM32 # ARM v7
#CC = arm-linux-gnueabihf-gcc
#CXX = arm-linux-gnueabihf-g++

#Arch ?= ARM64    # ARM v8
#CC = aarch64-linux-gnu-gcc
#CXX = aarch64-linux-gnu-g++

#Arch ?= X64	# X64
#CC = gcc
#CXX = g++
#CC = gcc-5
#CXX = g++-5


# Functions
find_includes_in_dir = $(shell find $(1) -name "*.h" | sed 's|/[^/]*$$||' | sort -u)

# ---------------------------------------------------------------------
# Toolchain Configuration
# ---------------------------------------------------------------------
C_STANDARD              := -std=gnu11
CXX_STANDARD            := -std=gnu++11

# -----------------------------------------------------------------------------------------------------------------
# Defined Symbols
# -----------------------------------------------------------------------------------------------------------------
DEFS                    := 

# ---------------------------------------------------------------------------------------------------------------------------------------
# Compiler & Linker Flags
# ---------------------------------------------------------------------------------------------------------------------------------------
# Flags sent to all tools in the Toolchain 
TOOLCHAIN_SETTINGS      := -fmessage-length=0

# C Compiler -- Warnings 
CFLAGS                  += $(TOOLCHAIN_SETTINGS) $(DEFS) $(addprefix -I, $(INC_DIRS))
CFLAGS                  += -Wall
CFLAGS                  += -Wextra
CFLAGS                  += -Wfatal-errors
CFLAGS                  += -Wpacked
CFLAGS                  += -Winline
CFLAGS                  += -Wfloat-equal
CFLAGS                  += -Wconversion
CFLAGS                  += -Wpointer-arith
CFLAGS                  += -Wdisabled-optimization
CFLAGS                  += -Wno-unused-parameter

# C++ Compiler -- Required & Optimization Flags
CXXFLAGS                += $(CFLAGS)

# C++ -- Warnings
CXXFLAGS                += -Weffc++
CXXFLAGS                += -Wfloat-equal
CXXFLAGS                += -Wsign-promo
CXXFLAGS                += -Wmissing-declarations 
CXXFLAGS                += -Woverloaded-virtual
CXXFLAGS                += -Wmissing-format-attribute
CXXFLAGS                += -Wold-style-cast
CXXFLAGS                += -Wshadow
CXXFLAGS                += -Wctor-dtor-privacy

# Linker
LDFLAGS                 += $(TOOLCHAIN_SETTINGS) $(DEFS)

# -------------------------------------------------------------
# Build Type Modifiers
# -------------------------------------------------------------
# Debug
DEFS_DEBUG              := -DDEBUG
CFLAGS_DEBUG            := -ggdb -g3 -Og

# Release
CFLAGS_RELEASE          := -O3

#########################################################################################################################################
# RULE DEFINITIONS -- This section is generic
#########################################################################################################################################

# =======================================================================================================================================
# Build Configuration Rule 
# - Generate build config using Product Root Directory ($1), Build Type ("Debug" or "Release") ($2)
# =======================================================================================================================================
# TODO: OBJECTS的目录设置的有问题
#OBJECTS                 := $$(addprefix $$(OBJ_DIR)/, $$(C_SRC:.c=.o) $$(CXX_SRC:.cpp=.o) $$(ASM_SRC:.s=.o))
define CONFIG_RULE
BUILD_DIR               := Build/$2
OBJ_DIR                 := $$(BUILD_DIR)/obj
ASM_DIR                 := $$(BUILD_DIR)/asm
INC_DIRS                := $$(call find_includes_in_dir, $$(SRC_DIRS))
HEADERS                 := $$(foreach dir, $$(SRC_DIRS), $$(shell find $$(dir) -name "*.h"))
ASM_SRC                 := $$(foreach dir, $$(SRC_DIRS), $$(shell find $$(dir) -name "*.s"))
C_SRC                   := $$(foreach dir, $$(SRC_DIRS), $$(shell find $$(dir) -name "*.c"))
CXX_SRC                 := $$(foreach dir, $$(SRC_DIRS), $$(shell find $$(dir) -name "*.cpp"))
ASSEMBLE                := $$(addprefix $$(ASM_DIR)/, $$(C_SRC:.c=.s) $$(CXX_SRC:.cpp=.s))
OBJECTS                 := $$(addprefix $$(OBJ_DIR)/, $$(C_SRC:.c=.o) $$(CXX_SRC:.cpp=.o) $$(ASM_SRC:.s=.o))
LDSCRIPTS               := $$(addprefix -T, $$(foreach dir, $$(SRC_DIRS), $$(shell find $$(dir) -name "*.ld")))
DIRS                    := $$(BUILD_DIR) $$(sort $$(dir $$(OBJECTS))) $$(sort $$(dir $$(ASSEMBLE)))
AUTODEPS                := $$(OBJECTS:.o=.d)


ifeq ($2, Release)
    DEFS    += $$(DEFS_RELEASE)
    CFLAGS  += $$(CFLAGS_RELEASE)
    LDFLAGS += $$(LDFLAGS_RELEASE)
else 
    DEFS    += $$(DEFS_DEBUG)
    CFLAGS  += $$(CFLAGS_DEBUG)
    LDFLAGS += $$(LDFLAGS_DEBUG)
endif

endef 
# =======================================================================================================================================
# End CONFIG_RULE
# =======================================================================================================================================


# =======================================================================================================================================
# Build Target Rule 
# - Generate build config using Product Name ($1), Product Root Directory ($2), Build Type ("Debug" or "Release") ($3)
# =======================================================================================================================================
define BUILD_TARGET_RULE
$(eval $(call CONFIG_RULE,$2,$3))

all : $$(BUILD_DIR)/$1  | $$(ASSEMBLE)

# Tool Invocations
$$(BUILD_DIR)/$1 : $$(OBJECTS) | $$(BUILD_DIR)
	@echo ' '
	@echo 'Building $$(@)'
	@echo 'Invoking: C++ Linker'
	$$(CXX) $$(LDFLAGS) $$(LDSCRIPTS) -o $$(@) $$(OBJECTS)
	@echo 'Finished building: $$@'
	@echo ' '

$$(ASSEMBLE) : | $$(DIRS)

$$(OBJECTS) : | $$(DIRS)

$$(DIRS) : 
	@echo Creating $$(@)
	@mkdir -p $$(@)

$$(OBJ_DIR)/%.o : %.c
	@echo Compiling $$(<F)
	@$$(CC) $$(C_STANDARD) -c $$< -o $$(@)

$$(ASM_DIR)/%.s : %.c
	@echo Compiling $$(<F)
	@$$(CXX) $$(CXX_STANDARD) -S $$< -o $$(@)

$$(OBJ_DIR)/%.o : %.cpp
	@echo Compiling $$(<F)
	@$$(CXX) $$(CXX_STANDARD) -c $$< -o $$(@)

$$(ASM_DIR)/%.s : %.cpp
	@echo Compiling $$(<F)
	@$$(CXX) $$(CXX_STANDARD) -S $$< -o $$(@)

$$(OBJ_DIR)/%.o : %.s
	@echo Assembling $$(<F)
	@$$(AS) $$(ASFLAGS) $$< -o $$(@)

clean :
	@rm -rf Build
	#-rm -rf Build

.PHONY : clean all

# include by auto dependencies
-include $$(AUTODEPS)

endef
# =======================================================================================================================================
# End BUILD_TARGET_RULE
# =======================================================================================================================================
#########################################################################################################################################
#########################################################################################################################################

# # Build Type
# ifeq ($(build), Debug)
# 	BUILD_TYPE := Debug
# else
# 	BUILD_TYPE := Release
# endif


# Defaults
PRODUCT ?= memcpy
PRODUCT_DIR ?= project/$(PRODUCT)
BUILD_TYPE ?= Debug
SRC_DIRS ?= src

# Evaluate Rules Defined Above
$(eval $(call BUILD_TARGET_RULE,$(PRODUCT),$(PRODUCT_DIR),$(BUILD_TYPE)))
