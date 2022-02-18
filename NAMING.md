# Naming Conventions in the Taki Source Code

 * **TakiRoutine**
   * Declares a public-interface routine. Usually this will just be a
     `jmp` to the "real" internal routine. Providing these public
     versions ensures that no matter what changes happen underneath, if
     the routine is still relevant in future versions of Taki, it will
     be found at the same location (or at least, the same offset
     relative to Taki's start).
 * **TakiVarFoo**
   * Declares a public-interface variable. As with public-interface
     functions, these variables' locations are intended to remain
     stable across future versions.
 * **TakiMacro_**
   * An underscore suffix indicates a macro.
 * **_TakiRoutine**
   * Declares a private, exported subroutine name.
 * **_TakiVarFoo**
   * Declares a private, exported variable name.
 * **pLabel**
   * Declares a private, unexported routine, subroutine, or other
     executable code label.
 * **pvFoo**
   * Declares a private, unexported variable name.
 * **@Foo**
   * A **ca65**-ism. Declares a label that is only visible until between
     the two nearest non-`@` labels.
