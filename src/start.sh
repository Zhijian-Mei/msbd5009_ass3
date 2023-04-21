nvcc -std=c++11 cuda_skeleton.cu decom.cpp main.cpp -o lrds

./lrds -ParallelQuery ../data/example/ 1 2

