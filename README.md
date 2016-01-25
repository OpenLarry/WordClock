# WordClock

## Requirements
* Vala compiler (>= 0.30)
* CMake (>= 2.6)
* libsoup-2.4
* gio-unix-2.0
* gio-2.0
* gee-0.8
* json-glib-1.0
* sdl, sdl-image

## Compilation

1. Clone repository:
  
  `git clone https://github.com/OpenLarry/WordClock.git `
2. Change directory:
  
  `cd WordClock`
3. Create build directory and change into (for out-of-source build, which is CMake default):
  
  `mkdir build`
  
  `cd build`
4. Initialize CMake:
  
  `cmake ..`
5. Compile source code:
  
  `make`
  
  (append e.g. `-j8` to use 8 jobs in parallel)
6. Change into generated folder
  
  `cd src`
7. Executable `wordclock` can be found here
