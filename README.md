# MIPS-Memory-Manager
Memory allocation manager for the MIPS assembly language. Allows memory that has been marked as free to be reused in future calls to alloc.  
This code was implemented and tested in [MARS (MIPS Assembler and Runtime Simulator)](http://courses.missouristate.edu/kenvollmar/mars/).  
The purpose of this code was for my own enjoyment and to learn more about memory management. It is provided as is (although contributions are welcome)
and while it should save memory consumption for most programs this does come at the cost of additional executed instructions.

## Source Files
* `MemManagementList.asm` provides the key functionality for managing free/allocated/uinitialized memory
* `MemManager.asm` the source file which should be included when using the memory manager. Implements `alloc` and `free`

## alloc
Function to allocate new memory either using syscall 9 (to initialize memory on the heap) or by returning memory that was marked free

## free
Function which takes in the address of allocated memory and marks it as free (ready to be used again by a call to alloc)

# Example
The provided example sorts an array using recursive MergeSort.  Additionally, code to plot the memory impact is provided.
* `standard_mergesort.asm` provides code to run mergesort using syscall 9 directly (syscall 9 allocates heap memory)
* `managed_mergesort.asm` provides code to run mergesort using memory managment via calls to `alloc` and `free`
* `standard_impact.txt` the result of running `standard_mergesort.asm`
* `managed_impact.txt` the result of running `managed_mergesort.asm`
* `plot_impact.py` python code to plot the impact data
* `Impact_Plot.png` a plot of the memory impact of standard and managed MergeSort
