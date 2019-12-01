# Check for DevkitPro before attempting to compile
ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

# TOPDIR stores the top level of the directory (ie. the current folder)
TOPDIR ?= $(CURDIR)
include $(DEVKITPRO)/libnx/switch_rules

#---------------------------------------------------------------------------------
# Options for compilation
# TARGET: Name of the output file(s)
# BUILD: Directory where object files & intermediate files will be placed
# SOURCES: List of directories containing source code
# INCLUDES: List of directories containing header files
# ROMFS: Directory containing data to be added to RomFS
# OUTDIR: Directory to structure sdcard contents
# FDIR: Directory where forwarder makefile/files/output is
# FFILE: Name of forwarder nsp
# TITLEID: TitleID of applet to override (only affects directory name)
#---------------------------------------------------------------------------------
TARGET		:=	NX-Activity-Log
BUILD		:=	build
SOURCES		:=	source source/screens source/ui source/ui/list source/ui/list/item source/ui/sidemenu
INCLUDES	:=	include include/screens include/ui include/ui/list include/ui/list/item include/ui/sidemenu
# ROMFS		:=	romfs
OUTDIR		:=	sdcard
FDIR		:=	forwarder
FFILE		:=	exefs.nsp
TITLEID		:=	0100000000001013

#---------------------------------------------------------------------------------
# Options for .nacp information
#---------------------------------------------------------------------------------
APP_TITLE   := 	NX Activity Log
APP_AUTHOR	:= 	tallbl0nde
APP_VERSION	:=	1.1.0a
ICON 		:= 	img/icon.jpg

#---------------------------------------------------------------------------------
# Options for code generation
# LIBS: Libraries to link against
# (I dunno what the rest is)
#---------------------------------------------------------------------------------
LIBS	:=  -lstdc++fs -lnx `sdl2-config --libs` -lSDL2_ttf `freetype-config --libs` -lSDL2_image -lpng -ljpeg -lwebp -lSimpleIniParser

ARCH	:=	-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE

CFLAGS	:=	-g -Wall -O2 -ffunction-sections $(ARCH) $(DEFINES)
CFLAGS	+=	$(INCLUDE) -D__SWITCH__

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=c++17

ASFLAGS	:=	-g $(ARCH)
LDFLAGS	=	-specs=$(DEVKITPRO)/libnx/switch.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(PORTLIBS) $(LIBNX) $(CURDIR)/SimpleIniParser

#---------------------------------------------------------------------------------
# This is all wizardry to me also
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) $(foreach dir,$(DATA),$(CURDIR)/$(dir))
export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

export LD	:=	$(CXX)

export OFILES_BIN	:=	$(addsuffix .o,$(BINFILES))
export OFILES_SRC	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES 	:=	$(OFILES_BIN) $(OFILES_SRC)
export HFILES_BIN	:=	$(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) $(foreach dir,$(LIBDIRS),-I$(dir)/include) -I$(CURDIR)/$(BUILD)
export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

#---------------------------------------------------------------------------------
# End of wizardry
# Set .nro flags
#---------------------------------------------------------------------------------

# Add icon and nacp flags (as these will always be present)
export APP_ICON := $(TOPDIR)/$(ICON)
export NROFLAGS += --icon=$(APP_ICON) --nacp=$(CURDIR)/$(TARGET).nacp

# Add romfs flag when directory present
ifneq ($(ROMFS),)
	export NROFLAGS += --romfsdir=$(CURDIR)/$(ROMFS)
endif

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
# Default build target: everything
#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD):
ifeq ($(wildcard $(CURDIR)/SimpleIniParser/LICENSE),)
	@$(error "Please run 'git submodule update --init' before running 'make'")
endif
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) -C $(CURDIR)/SimpleIniParser -f $(CURDIR)/SimpleIniParser/Makefile
	@$(MAKE) -C $(CURDIR)/$(FDIR) -f $(CURDIR)/$(FDIR)/Makefile
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
# Clean removes all build files + sdcard directory
#---------------------------------------------------------------------------------
clean:
	@echo Cleaning ALL build files...
	@rm -rf $(BUILD) $(TARGET).nro $(TARGET).nacp $(TARGET).elf $(OUTDIR)
	@$(MAKE) -C $(CURDIR)/SimpleIniParser -f $(CURDIR)/SimpleIniParser/Makefile clean
	@$(MAKE) -C $(CURDIR)/$(FDIR) -f $(CURDIR)/$(FDIR)/Makefile clean
	@echo Done!
#---------------------------------------------------------------------------------
else
.PHONY:	all

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# Main target
#---------------------------------------------------------------------------------
# Important binaries are copied into approporiate places
# (I gave up figuring out how to do it properly)
all: $(OUTPUT).nro
	@mkdir -p $(TOPDIR)/$(OUTDIR)/switch
	@mkdir -p $(TOPDIR)/$(OUTDIR)/atmosphere/titles/$(TITLEID)/
	@mkdir -p $(TOPDIR)/$(OUTDIR)/ReiNX/titles/$(TITLEID)/
	@cp $(OUTPUT).nro $(TOPDIR)/$(OUTDIR)/switch/
	@cp $(TOPDIR)/$(FDIR)/$(FFILE) $(TOPDIR)/$(OUTDIR)/atmosphere/titles/$(TITLEID)/
	@cp $(TOPDIR)/$(FDIR)/$(FFILE) $(TOPDIR)/$(OUTDIR)/ReiNX/titles/$(TITLEID)/
	@echo
	@echo "All done! Simply copy the folders within ./$(OUTDIR) to your SD card :)"

$(OUTPUT).nro	:	$(OUTPUT).elf $(OUTPUT).nacp
$(OUTPUT).elf	:	$(OFILES)
$(OFILES_SRC)	: $(HFILES_BIN)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------