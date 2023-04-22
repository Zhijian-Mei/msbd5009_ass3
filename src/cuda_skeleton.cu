#include "decom.h"

using namespace std;
const int Q_MAX = 10000000;
__global__ void Kernel(int* d_lrval_index_u_size,int* d_queryStream,int* d_queryAns,int* d_n_query,int* d_lrval_index_u_length)
{
    const int tid = blockDim.x*blockIdx.x + threadIdx.x;
    const int nthread = blockDim.x*gridDim.x; 

    for(int i = tid;i<*d_n_query; i+= nthread){
        int flag = 0;
        int lval = d_queryStream[i*2];
        int rval = d_queryStream[i*2+1];
        if ((*d_lrval_index_u_length<= lval) || (d_lrval_index_u_size[lval] <= rval)){
		    flag = 0;
        } else {
            flag = 1;
        }

        d_queryAns[i*3] = lval;
        d_queryAns[i*3+1] = rval;
        d_queryAns[i*3+2] = flag;
    }
    
}


void cuda_query(string dir, int num_blocks_per_grid, int num_threads_per_block, int* queryAns) {
	BiGraph h_g(dir);
	lrIndexBasic(h_g);    
    vector<vector<lrval_index_block*>> h_lrval_index_u; vector<vector<lrval_index_block*>> h_lrval_index_v;
    build_lrval_index(h_g, h_lrval_index_u, h_lrval_index_v);

    int *h_lrval_index_u_size,*d_lrval_index_u_size;
    int h_lrval_index_u_length = (int)h_lrval_index_u.size();
    int *d_lrval_index_u_length;
    
    cudaMalloc((void**)&d_lrval_index_u_length,sizeof(int));
    cudaMemcpy(d_lrval_index_u_length,&h_lrval_index_u_length,sizeof(int),cudaMemcpyHostToDevice);

    size_t size_h_lrval_index_u_size = sizeof(h_lrval_index_u.size()) * h_lrval_index_u.size();
    h_lrval_index_u_size = (int*)malloc(size_h_lrval_index_u_size);
    
    for (int i = 0;i<h_lrval_index_u.size();i++){
        h_lrval_index_u_size[i] = h_lrval_index_u[i].size();
    }
    
    cudaMalloc((void**)&d_lrval_index_u_size,size_h_lrval_index_u_size);
    cudaMemcpy(d_lrval_index_u_size,h_lrval_index_u_size,size_h_lrval_index_u_size,cudaMemcpyHostToDevice);

    vector<vector<int>> queryStream;
    queryStream.resize(Q_MAX);
    int n_query = sizeof(queryAns)/sizeof(queryAns[0]);
    int *d_n_query;

    loadQuery(dir, queryStream);
    queryStream.resize(n_query);
    cudaMalloc((void**)&d_n_query,sizeof(int));
    cudaMemcpy(d_n_query,&n_query,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(&n_query,d_n_query,sizeof(int),cudaMemcpyDeviceToHost);
    
    
    int *h_queryStream,*d_queryStream;
    size_t size_h_query = sizeof(queryStream[0][0]) * n_query * 2;
    h_queryStream = (int*)malloc(size_h_query);
    for (int i = 0;i<n_query;i++){
        h_queryStream[i*2] = queryStream[i][0];
        h_queryStream[i*2+1] = queryStream[i][1];
    }

    cudaMalloc((void**)&d_queryStream,size_h_query);
    cudaMemcpy(d_queryStream,h_queryStream,size_h_query,cudaMemcpyHostToDevice);

    
    int *d_queryAns;
    size_t size_h_queryAns = sizeof(int)*n_query*3;

    cudaMalloc((void**)&d_queryAns,size_h_queryAns);
    cudaMemcpy(d_queryAns,queryAns,size_h_queryAns,cudaMemcpyHostToDevice);
    Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size,d_queryStream,d_queryAns,d_n_query,d_lrval_index_u_length);

    cudaMemcpy(queryAns,d_queryAns,size_h_queryAns,cudaMemcpyDeviceToHost);



    






}
