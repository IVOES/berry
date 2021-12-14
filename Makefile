CFLAGS    = -Wall -Wextra -std=c99 -pedantic-errors -O2
LIBS      = -lm
TARGET    = berry
CC       ?= gcc
MKDIR     = mkdir
LFLAGS    = 

INCPATH   = src default
SRCPATH   = src default
GENERATE  = generate
CONFIG    = default/berry_conf.h
COC       = python3 tools/coc/main.py
CONST_TAB = $(GENERATE)/be_const_strtab.h

ifeq ($(OS), Windows_NT) # Windows
    CFLAGS    += -Wno-format # for "%I64d" warning
    LFLAGS    += -Wl,--out-implib,berry.lib # export symbols lib for dll linked
    TARGET    := $(TARGET).exe
    PY3       := $(PY3).exe
else
    CFLAGS    += -DUSE_READLINE_LIB
    LIBS      += -lreadline -ldl
    OS        := $(shell uname)
    ifeq ($(OS), Linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

ifneq ($(V), 1)
    Q=@
    MSG=@echo
else
    MSG=@true
endif

ifeq ($(TEST), 1)
    CFLAGS += -fprofile-arcs -ftest-coverage
    LFLAGS += -fprofile-arcs -ftest-coverage
endif

SRCS     = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.c))
OBJS     = $(patsubst %.c, %.o, $(SRCS))
DEPS     = $(patsubst %.c, %.d, $(SRCS))
INCFLAGS = $(foreach dir, $(INCPATH), -I"$(dir)")

.PHONY : clean

all: $(TARGET)

debug: CFLAGS += -O0 -g -DBE_DEBUG
debug: all

test: CFLAGS += --coverage
test: LFLAGS += --coverage
test: all
	$(MSG) [Run Testcases...]
	$(Q) ./testall.be
	$(Q) $(RM) */*.gcno */*.gcda

$(TARGET): $(OBJS)
	$(MSG) [Linking...]
	$(Q) $(CC) $(OBJS) $(LFLAGS) $(LIBS) -o $@
	$(MSG) done

$(OBJS): %.o: %.c
	$(MSG) [Compile] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

sinclude $(DEPS)

$(OBJS): $(CONST_TAB)

$(CONST_TAB): $(GENERATE) $(SRCS) $(CONFIG)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC)  -o $(GENERATE) $(SRCPATH) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	cp $(TARGET) /usr/local/bin

uninstall:
	$(RM) /usr/local/bin/$(TARGET)

prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(MSG) done

clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* berry.lib
	$(MSG) done
