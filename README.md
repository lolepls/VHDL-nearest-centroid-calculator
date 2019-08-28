# VHDL-nearest-centroid-calculator
A hardware component written in VHDL that, given the position of an observer and some centroids on a 256x256 grid, computes the nearest centroid to the observer.


# Project specifications

Development in VHDL of a hardware component that solves a specific problem. The software used was Xilinx Vivado 2018.3, and the target FPGA is Artix-7 xc7a200tfbg484-1.

# General description of the problem

A two-dimensional space is given, defined as a 256x256 matrix. In this space there are 8 points, called "centroids", each identified by a pair of coordinates (called "x" and "y") that determine its position within the matrix. There is also a further point, from here on called "observer", also identified by a pair of coordinates. The hardware component has the purpose of calculating the closest centroids to the observer, considering their Manhattan distance, defined as:

`MhD = (|x-x0| + |y-y0|)`

Of the 8 centroids contained in space, only some of them must be taken into consideration for distance analysis, while the others must be ignored. This is expressed by a 8 bit value value called "input mask". Each bit corresponds to a centroid: if it is 1, the relative centroid must be considered for distance analysis, while it must be ignored if the bit is 0. For example, the following input mask indicates that only the first, the third and the seventh centroid must be considered in the distance analysis: 

`01000101` 

The result of the computation is also an 8-bit value, called "exit mask": each bit will have value 1 if and only if the corresponding centroid was determined to be the closest to the observer. 
If more centroids are found at the same minimum distance from the observer, all the corresponding bits must be "1". For example, if the analysis has found that the nearest centroids are the first and the seventh, the exit mask is the following: 

`01000001`



