# TAKI - Text Animation KIt (for the Apple \]\[)

**Taki** aims to provide a facility for various animated text effects
on the screen of your Apple \]\[.

Design goals include:
  * Text effects must run as smoothly as possible
  * It must be possible to use text effects from legible AppleSoft BASIC code.

## Building notes

If you want to modify or build from these sources, you will need tools from the following projects:

  * The ca65 and ld65 tools from [the cc65 project](https://github.com/cc65/cc65) (I use version 2.19 - 2.18 is known not to work)
  * These [tools for manipulating Apple DOS 3.3 filesystems](https://github.com/deater/dos33fsprogs)

NOTE: The **dos33fsprogs** project contains *many* different subprojects, most of which are *not needed* to build the disk image. The only subdirectories you must build, are `dos33fs-utils` and `asoft_basic-utils`.

The Makefile assumes all of these tools are accessible from the current `PATH` environment variable.
