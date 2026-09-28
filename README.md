# Chorus

Chorus is a Common Lisp library for programming GPUs. It targets NVIDIA GPUs through CUDA, Apple silicon, and AMD GPUs.

Chorus began as a fork of [CL-Cuda](https://github.com/takagi/cl-cuda), Masayuki Takagi's Common Lisp library for NVIDIA CUDA. The implementation in this tree is the CUDA backend. The manual sources are in [documentation/](documentation/). From that directory, `make` builds `chorus.pdf`.

## Targets

* **CUDA.** NVIDIA GPUs, through the CUDA driver API and `nvcc`. This tree implements this backend. Toolkit and architecture constraints are under [Requirements for the CUDA backend](#requirements-for-the-cuda-backend).
* **Apple silicon.** See [Apple silicon](#apple-silicon).
* **AMD.** AMD GPUs. See [AMD](#amd).

The kernel language defines kernel functions, kernel macros, and kernel symbol macros as S-expressions. Kernel macros and kernel symbol macros give abstractions that CUDA C does not have. That matters in GPU programming, where resources are tight.

On the CUDA backend, a kernel launches much as an ordinary Common Lisp function does. The launch runs in a CUDA context and takes grid and block sizes. The kernel manager compiles and loads the kernel the first time it is launched. Chorus compiles the kernel to CUDA C (a `.cu` file). NVCC, the NVIDIA CUDA compiler driver, compiles that file to PTX. The CUDA driver API loads the module and launches the kernel. See [Kernel manager](#kernel-manager).

A memory block allocates the host side and the device side together. `sync-memory-block` copies between them. The same layer also exposes CFFI host pointers and CUDA device pointers.

The CUDA backend is verified on Windows and Linux. See [Verification environments](#verification-environments).

## Example

The following is part of the vector-addition example, the CUDA backend's version of the CUDA SDK `vectorAdd` sample.

You can define `vec-add-kernel` with the `defkernel` macro. In the definition, `aref` reads a value stored in an array. `set` stores a value into an array. `block-dim-x`, `block-idx-x`, and `thread-idx-x` are the kernel language's index variables. The CUDA backend maps them to the CUDA C built-ins, and each CUDA thread uses them to choose the array index it operates on.

On the CUDA backend, launch the kernel inside `with-cuda` and pass `:grid-dim` and `:block-dim`. `with-cuda` initializes CUDA, keeps a CUDA context, and selects the nvcc `-arch=sm_XY` option from the device's compute capability when `*nvcc-options*` does not already name an architecture. `with-memory-blocks` allocates the memory blocks. `sync-memory-block` copies a block between host and device.

For the whole code, please see [examples/vector-add.lisp](examples/vector-add.lisp).

    (defkernel vec-add-kernel (void ((a float*) (b float*) (c float*) (n int)))
      (let ((i (+ (* block-dim-x block-idx-x) thread-idx-x)))
        (if (< i n)
            (set (aref c i)
                 (+ (aref a i) (aref b i))))))
    
    (defun main ()
      (let* ((dev-id 0)
             (n 1024)
             (threads-per-block 256)
             (blocks-per-grid (/ n threads-per-block)))
        (with-cuda (dev-id)
          (with-memory-blocks ((a 'float n)
                               (b 'float n)
                               (c 'float n))
            (random-init a n)
            (random-init b n)
            (sync-memory-block a :host-to-device)
            (sync-memory-block b :host-to-device)
            (vec-add-kernel a b c n
                            :grid-dim  (list blocks-per-grid 1 1)
                            :block-dim (list threads-per-block 1 1))
            (sync-memory-block c :device-to-host)
            (verify-result a b c n)))))

## Installation

You can install Chorus via Quicklisp once this system is on the local-projects path (or otherwise visible to ASDF):

    > (ql:quickload :chorus)

To run the test suite from a checkout:

    > (asdf:test-system :chorus)

or, with SBCL:

    sbcl --load ~/quicklisp/setup.lisp --load test/run.lisp

`test/run.lisp` loads the local `.asd` files, prints driver/`nvcc` discovery, then loads `chorus-test` (tests run at load time).

## Requirements for the CUDA backend

The CUDA backend requires:

* NVIDIA CUDA-enabled GPU
* CUDA driver (`nvcuda.dll` on Windows, `libcuda.so.1` on Linux)
* CUDA Toolkit (`nvcc`) to compile kernels to PTX
* On Windows, Visual Studio with the C++ workload (`cl.exe`) so `nvcc` has a host compiler

RTX 50-series (Blackwell, compute capability 12.0) needs CUDA Toolkit 12.8 or later. CUDA 13.x is the toolkit this backend is written for.

With CUDA 13, `nvcc` can target Turing and newer (`sm_75` and above): RTX 20-, 30-, 40-, and 50-series, plus matching professional and datacenter parts (T4, A100, Ada, Hopper, Blackwell). Maxwell, Pascal, and Volta are outside what CUDA 13 can compile.

The CUDA backend runs on Windows and Linux.

Kernel files are written to the OS temporary directory unless you set `*tmp-path*`. `nvcc` is found on `PATH`, via `CUDA_PATH` / `CUDA_HOME`, or in the usual toolkit install locations (`C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\` on Windows, `/usr/local/cuda` on Unix).

## Verification environments

### CUDA on Windows

Verified on this configuration; the full test suite passes:

* Windows 11 x86_64
* GeForce RTX 5090 (Blackwell, sm_120)
* NVIDIA driver 610.88, CUDA 13.3
* Visual Studio 2022 Community (MSVC)
* SBCL 2.6.8 64-bit

Architecture is taken from the live device (`-arch=sm_XY`), so other Turing-and-newer GPUs with a matching toolkit are expected to work the same way. They have not all been re-run here.

### Apple silicon

Apple silicon is a Chorus target. This tree has no Apple silicon backend.

### AMD

AMD GPUs are a Chorus target. This tree has no AMD backend, and no verification run on AMD hardware is recorded here.

### Historical (2011–2016)

The following were reported against CUDA 4–8 and pre-Turing GPUs. They are left for provenance. They are **not** expected to work with the current code and CUDA 13: the driver FFI is 64-bit, grovel/`cuda.h` is no longer used at load time, and CUDA 13 cannot offline-compile architectures before `sm_75`.

#### Environment 1
* Mac OS X 10.6.8 (MacBookPro)
* GeForce 9400M
* CUDA 4
* SBCL 1.0.55 32-bit
* Reported at the time: all tests pass, all examples work

#### Environment 2
* Amazon Linux x86_64 (Amazon EC2)
* Tesla M2050
* CUDA 4
* SBCL 1.1.7 64-bit
* Reported at the time: all tests pass, verified examples work
* `(setf *nvcc-options* (list "-arch=sm_20" "-m32"))` was needed

#### Environment 3 (Thanks to Viktor Cerovski)
* Linux 3.5.0-32-generic Ubuntu SMP x86_64
* GeForce 9800 GT
* CUDA 5
* SBCL 1.1.7 64-bit
* Reported at the time: all tests pass, all examples work

#### Environment 4 (Thanks to wvxvw)
* Fedora 18 x86_64
* GeForce GTX 560M
* CUDA 5.5
* SBCL 1.1.2-1.fc18
* Reported at the time: `vector-add` example works
* `(setf *nvcc-options* (list "-arch=sm_20" "-m32"))` was needed
* video drivers from `rpmfusion` instead of the ones in the `cuda` package
* see issue [#1](https://github.com/takagi/cl-cuda/issues/1#issuecomment-22813518)

#### Environment 5 (Thanks to Atabey Kaygun)
* Linux 3.11-2-686-pae SMP Debian 3.11.8-1 (2013-11-13) i686 GNU/Linux
* NVIDIA Corporation GK106 GeForce GTX 660
* CUDA 5.5
* SBCL 1.1.12
* Reported at the time: all tests pass, all examples work

#### Environment 6 (Thanks to @gos-k)
* Ubuntu 16.04.1 LTS
* GeForce GTX 1080
* CUDA Version 8.0.27
* Driver Version 367.35
* CCL Version 1.11-r16635 (LinuxX8664)
* Reported at the time: all tests pass, all examples work

## API

Here explain some APIs commonly used.

### [Macro] with-cuda

    WITH-CUDA (dev-id) &body body

Initializes CUDA and keeps a CUDA context during `body`. `dev-id` is passed to `get-cuda-device` function and the device handler returned is passed to `create-cuda-context` function to create a CUDA context in the expanded form. The results of `get-cuda-device` and `create-cuda-context` functions are bound to `*cuda-device*` and `*cuda-context*` special variables respectively. Unless `*nvcc-options*` already contains an architecture flag, `with-cuda` prepends `-arch=sm_XY` from the device's compute capability (`cuDeviceGetAttribute`). The kernel manager unloads before `with-cuda` exits.

### [Function] synchronize-context

    SYNCHRONIZE-CONTEXT

Blocks until a CUDA context has completed all preceding requested tasks.

### [Function] alloc-memory-block

    ALLOC-MEMORY-BLOCK type size

Allocates a memory block to hold `size` elements of type `type` and returns it. Actually, linear memory areas are allocated on both host and device memory and a memory block holds pointers to them.

### [Function] free-memory-block

    FREE-MEMORY-BLOCK memory-block

Frees `memory-block` previously allocated by `alloc-memory-block`. Freeing a memory block twice should cause an error.

### [Macro] with-memory-block, with-memory-blocks

    WITH-MEMORY-BLOCK (var type size) &body body
    WITH-MEMORY-BLOCKS ({(var type size)}*) &body body

Binds `var` to a memory block allocated using `alloc-memory-block` applied to the given `type` and `size` during `body`. The memory block is freed using `free-memory-block` when `with-memory-block` exits. `with-memory-blocks` is a plural form of `with-memory-block`.

### [Function] sync-memory-block

    SYNC-MEMORY-BLOCK memory-block direction

Copies stored data between host memory and device memory for `memory-block`. `direction` is either `:host-to-device` or `:device-to-host` which specifies the direction of copying.

### [Accessor] memory-block-aref

    MEMORY-BLOCK-AREF memory-block index

Accesses `memory-block`'s element specified by `index`. Note that the accessed memory area is that on host memory. Use `sync-memory-block` to synchronize stored data between host memory and device memory.

### [Macro] defglobal

    DEFGLOBAL name expression &optional qualifiers

Defines a global variable. `name` is a symbol which is the name of the variable. `expression` initializes it; the type is inferred from that value. Optional `qualifiers` is one of or a list of keywords: `:device`, `:constant`, `:shared`, `:managed` and `:restrict`, which are corresponding to CUDA C's `__device__`, `__constant__`, `__shared__`, `__managed__` and `__restrict__` variable qualifiers. If not given, `:device` is used.

    (defglobal pi 3.14159 :constant)

### [Accessor] global-ref

    GLOBAL-REF name type &optional manager

Accesses a global variable's value on device from host with automatically copying its value from/to device. `type` is the Lisp/CUDA type of the global (for example `int` or `float`).

    (defglobal x 0)
    (global-ref 'x 'int)                 ; => 0
    (setf (global-ref 'x 'int) 42)
    (global-ref 'x 'int)                 ; => 42

### [Special Variable] \*tmp-path\*

Specifies the temporary directory in which Chorus generates files such as `.cu` file and `.ptx` file. The default is `nil`, which uses the OS temporary directory (`UIOP:TEMPORARY-DIRECTORY`).

    (setf *tmp-path* "/path/to/tmp/")   ; Unix
    (setf *tmp-path* #P"C:/Temp/chorus/")

### [Special Variable] \*nvcc-options\*

Specifies additional command line options passed to `nvcc` command that Chorus calls internally. The default is `nil`. If no architecture option is present (`-arch=…`, `--gpu-architecture`, or `-gencode`), `with-cuda` inserts `-arch=sm_XY` from the device. Compiles that happen outside `with-cuda` fall back to `-arch=native` (CUDA 11.6+).

    (setf *nvcc-options* (list "-arch=sm_120"))

### [Special Variable] \*nvcc-binary\*

Specifies the path to `nvcc` so that Chorus can call it internally. The default is `nil`, which auto-detects `nvcc` on `PATH` and in standard CUDA Toolkit locations. The strings `"nvcc"` and `"nvcc.exe"` also mean auto-detect.

    (setf *nvcc-binary* "/usr/local/cuda/bin/nvcc")
    (setf *nvcc-binary* #P"C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v13.3/bin/nvcc.exe")

### [Function] find-nvcc

    FIND-NVCC => pathname or nil

Returns the absolute path of `nvcc`, or `nil` if it cannot be found.

### [Function] nvcc-available-p

    NVCC-AVAILABLE-P => generalized boolean

True when `find-nvcc` locates a compiler.

### [Function] nvcc-arch-option

    NVCC-ARCH-OPTION major minor => string

Formats an nvcc architecture flag from a compute capability. `(nvcc-arch-option 12 0)` is `"-arch=sm_120"`.

### [Special Variable] \*show-messages\*

Specifies whether to let Chorus show operational messages or not. The default is `t`.

    (setf *show-messages* nil)

### [Special Variable] \*sdk-not-found\*

Readonly. The value is `t` if the CUDA backend failed to load the CUDA driver library (`nvcuda.dll` on Windows, `libcuda.so.1` on Linux, or, on Darwin, `CUDA.framework` / `libcuda.dylib`), otherwise `nil`. The variable says nothing about the CUDA Toolkit (`nvcc`). Use `nvcc-available-p` for that.

    *sdk-not-found*    ; => nil

## Kernel Description Language

### Types

not documented yet.

### IF statement

    IF test-form then-form [else-form]

`if` allows the execution of a form to be dependent on a single `test-form`. First `test-form` is evaluated. If the result is `true`, then `then-form` is selected; otherwise `else-form` is selected. Whichever form is selected is then evaluated. If `else-form` is not provided, does nothing when `else-form` is selected.

Example:

    (if (= a 0)
        (return 0)
        (return 1))

Compiled:

    if (a == 0) {
      return 0;
    } else {
      return 1;
    }

### LET statement

    LET ({(var init-form)}*) statement*

`let` declares new variable bindings and set corresponding `init-form`s to them and execute a series of `statement`s that use these bindings. `let` performs the bindings in parallel. For sequentially, use `let*` kernel macro instead.

Example:

    (let ((i 0))
      (return i))

Compiled:

    {
      int i = 0;
      return i;
    }

### SYMBOL-MACROLET statement

    SYMBOL-MACROLET ({(symbol expansion)}*) statement*

`symbol-macrolet` establishes symbol expansion rules in the variable environment and execute a series of `statement`s that use these rules. In Chorus's compilation process, the symbol macros found in a form are replaces by corresponding `expansion`s.

Example:

    (symbol-macrolet ((x 1.0))
      (return x))

Compiled:

    {
      return 1.0;
    }

### MACROLET statement

    MACROLET ({(name lambda-list local-form*)}*) statement*

`macrolet` establishes local macro definitions, using the same format as `defkernelmacro`, and executes a series of `statement`s with these definition bindings.

Example:

    (macrolet ((square (a)
                 (if (numberp a)
                     (* a a)
                     `(* ,a ,a))))
      (return (square 2)))

Compiled:

    {
      return 4;
    }

### DO statement

    DO ({(var init-form step-form)}*) (test-form) statement*

`do` iterates over a group of `statement`s until `test-form` holds (the same convention as Common Lisp `do`). `do` accepts an arbitrary number of iteration `var`s and their initial values are supplied by `init-form`s. `step-form`s supply how the `var`s should be updated on succeeding iterations through the loop.

Example:

    (do ((a 0 (+ a 1))
         (b 0 (+ b 1)))
        ((> a 15))
      (do-some-statement))

Compiled:

    for ( int a = 0, int b = 0; ! (a > 15); a = a + 1, b = b + 1 )
    {
      do_some_statement();
    }

### WITH-SHARED-MEMORY statement

    WITH-SHARED-MEMORY ({(var type size*)}*) statement*

`with-shared-memory` declares new variable bindings on shared memory by adding `__shared__` variable specifiers. It allows to declare array variables if dimensions are provided. A series of `statement`s are executed with these bindings.

Example:

    (with-shared-memory ((a int 16)
                         (b float 16 16))
      (return))

Compiled:

    {
      __shared__ int a[16];
      __shared__ float b[16][16];
      return;
    }

### SET statement

    SET reference expression

`set` provides simple variable assignment. It accepts one of variable, structure and array references as `reference`.

Example:

    (set x 1.0)
    (set (float4-x y) 1.0)
    (set (aref z 0) 1.0)

Compiled:

    x = 1.0;
    y.x = 1.0;
    z[0] = 1.0;

### PROGN statement

    PROGN statement*

`progn` evaluates `statement`s, in the order in which they are given.

Example:

    (progn
      (do-some-statements)
      (do-more-statements))

Compiled:

    do_some_statements();
    do_more_statements();

### RETURN statement

    RETURN [return-form]

`return` returns control, with `return-form` if supplied, from a kernel function.

Example:

    (return 0)

Compiled:

    return 0;

## Architecture

The following figure illustrates the CUDA backend in this tree.

                       +---------------------------------+-----------+-----------+
                       | defkernel                       | memory    | context   |
            chorus/api +---------------------------------+           |           |
                       | kernel-manager / nvcc           |           |           |
                       +---------------------------------+-----------+-----------+
                       +----------------------------+----------------------------+
           chorus/lang | Kernel description lang.   | the Compiler               |
                       +----------------------------+----------------------------+
                       +---------------------------------------------------------+
     chorus/driver-api | driver-api                                              |
                       +---------------------------------------------------------+
                       +---------------------------------------------------------+
                  CUDA | CUDA driver API                                         |
                       +---------------------------------------------------------+

Chorus consists of three subpackages: `api`, `lang` and `driver-api`.

`driver-api` subpackage is a FFI binding to CUDA driver API. `api` subpackage invokes CUDA driver API via this binding internally.

`lang` subpackage provides the kernel description language. It provides the language's syntax, type, built-in functions and the compiler to CUDA C. `api` subpackage calls this compiler.

`api` subpackage provides API for Chorus users. It further consists of `context`, `memory`, `nvcc`, `kernel-manager` and `defkernel` subpackages. `context` subpackage has responsibility on initializing CUDA and managing CUDA contexts. `memory` subpackage offers memory management, providing high level API for memory block data structure and low level API for handling host memory and device memory directly. `nvcc` locates the CUDA toolkit compiler and invokes it. `kernel-manager` subpackage manages the entire process from compiling the kernel description language to loading/unloading obtained kernel module autonomously. Since it is wrapped by `defkernel` subpackage which provides the interface to define kernel functions, Chorus's users usually do not need to use it for themselves.

## Kernel manager

The kernel manager is a module which manages defining kernel functions, compiling them into a CUDA kernel module, loading it and unloading it. I show you its work as a finite state machine here.

To begin with, the kernel manager has four states.

    I   initial state
    II  compiled state
    III module-loaded state
    IV  function-loaded state

The initial state is its entry point. The compiled state is a state where kernel functions defined with the kernel description language have been compiled into a CUDA kernel module (.ptx file). The obtained kernel module has been loaded in the module-loaded state. In the function-loaded state, each kernel function in the kernel module has been loaded.

Following illustrates the kernel manager's state transfer.

          compile-module        load-module            load-function
        =================>    =================>     =================>
      I                    II                    III                    IV
        <=================    <=================
          define-function     <========================================
          define-macro          unload
          define-symbol-macro
          define-global

`kernel-manager-compile-module` function compiles defined kernel functions into a CUDA kernel module. `kernel-manager-load-module` function loads the obtained kernel module. `kernel-manager-load-function` function loads each kernel function in the kernel module.

In the module-loaded state and function-loaded state, `kernel-manager-unload` function unloads the kernel module and turn the kernel manager's state back to the compiled state. `kernel-manager-define-function`, `kernel-manager-define-macro`, `kernel-manager-define-symbol-macro` and `kernel-manager-define-global` functions, which are wrapped as `defkernel`, `defkernelmacro`, `defkernel-symbol-macro` and `defglobal` macros respectively, change its state back into the initial state and make it require compilation again.

The kernel manager is stored in `*kernel-manager*` special variable when Chorus is loaded and keeps alive during the Common Lisp process. Usually, you do not need to manage it explicitly.

## How the CUDA backend works when the CUDA driver is not installed

On a machine with no NVIDIA driver, the CUDA backend still compiles and loads. A call into the driver then signals `sdk-not-found-error`. The same behavior matters for an application that has a path other than the CUDA backend and may run where the NVIDIA driver is absent.

**Compile and load time**
Chorus is compiled and loaded without signaling if the CUDA driver library cannot be loaded. API symbols are still interned, so user programs can refer to them.

**Run time**
Calling a Chorus driver API signals `sdk-not-found-error`. `*sdk-not-found*` is `t` in that case. Absence of `nvcc` is separate: `*sdk-not-found*` can be `nil` (driver present) while `nvcc-available-p` is false (toolkit missing). Kernel launch then fails when nvcc is invoked.

The CUDA backend decides the driver is present when `cffi:use-foreign-library` successfully loads `nvcuda.dll`, `libcuda.so.1`, or the CUDA framework.

## Streams

The low level interface works with multiple streams. With the async stuff it's possible to overlap copy and computation with two streams. Chorus provides `*cuda-stream*` special variable, to which bound stream is used in kernel function calls.

The following is for working with streams in [mgl-mat](https://github.com/melisgl/mgl-mat):

    (defmacro with-cuda-stream ((stream) &body body)
      (alexandria:with-gensyms (stream-pointer)
        `(cffi:with-foreign-objects
             ((,stream-pointer 'chorus/driver-api:cu-stream))
           (chorus/driver-api:cu-stream-create ,stream-pointer 0)
           (let ((,stream (cffi:mem-ref ,stream-pointer
                                        'chorus/driver-api:cu-stream)))
             (unwind-protect
                  (locally ,@body)
               (chorus/driver-api:cu-stream-destroy ,stream))))))

then, call a kernel function with binding a stream to `*cuda-stream*`:

    (with-cuda-stream (*cuda-stream*)
      (call-kernel-function))

## Author

* Masayuki Takagi (kamonama@gmail.com)
* Christopher Mark Gore (cgore@cgore.com)

## Copyright

Copyright (c) 2012-2021 Masayuki Takagi (kamonama@gmail.com)
Copyright (c) 2026 Christopher Mark Gore (cgore@cgore.com)

## License

Licensed under the MIT License. `tools/drvapi_error_string.h` remains under the terms stated in that file.
