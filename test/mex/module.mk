mex_TEST_FILES = \
  %reldir%/bug-54096.tst \
  %reldir%/bug-51725.tst \
  $(MEX_TEST_SRC)

MEX_TEST_SRC = \
  %reldir%/bug_54096.c \
  %reldir%/bug_51725.c

MEX_TEST_FUNCTIONS = $(MEX_TEST_SRC:%.c=%.mex)

## Since these definitions for MKOCTFILE and MKMEXFILE are only used
## here, defining them in this file is probably OK.  If there are ever
## used elsewhre, maybe then they could be moved to build-aux/module.mk
## or the main Makefile.am file.  The MKOCTFILE variables are included
## for completeness, in case we someday want to test building .oct
## files as well.

AM_V_mkmexfile = $(am__v_mkmexfile_@AM_V@)
am__v_mkmexfile_ = $(am__v_mkmexfile_@AM_DEFAULT_V@)
am__v_mkmexfile_0 = @echo "  MKMEXFILE     " $@;
am__v_mkmexfile_1 =

AM_VOPT_mkmexfile = $(am__vopt_mkmexfile_@AM_V@)
am__vopt_mkmexfile_ = $(am__vopt_mkmexfile_@AM_DEFAULT_V@)
am__vopt_mkmexfile_0 =
am__vopt_mkmexfile_1 = -v

## And probably many others...
MKOCTFILECPPFLAGS = \
  -I$(top_srcdir)/libinterp/corefcn \
  -Ilibinterp/corefcn

MKOCTFILE = $(top_builddir)/src/mkoctfile $(MKOCTFILECPPFLAGS)

MKMEXFILECPPFLAGS = \
  -I$(top_srcdir)/libinterp/corefcn \
  -Ilibinterp/corefcn

MKMEXFILE = $(top_builddir)/src/mkoctfile --mex $(MKMEXFILECPPFLAGS)

%.mex : %.c
	$(AM_V_mkmexfile)$(MKMEXFILE) $(AM_VOPT_mkmexfile) $< -o $@ || rm -f $@

## Until we decide how to handle installing the executable MEX files,
## don't install them or the associated test files.
noinst_TEST_FILES += $(mex_TEST_FILES)