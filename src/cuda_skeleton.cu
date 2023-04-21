#include "decom.h"

using namespace std;

__global__ void test_Kernel(int* C,int* num_v1,int* num_v2)
{
    int threadID = threadIdx.x;
    
}

void cuda_query(string dir, int num_blocks_per_grid, int num_threads_per_block, int* queryAns) {
	BiGraph h_g(dir);
	lrIndexBasic(h_g);    
    vector<vector<lrval_index_block*>> h_lrval_index_u; vector<vector<lrval_index_block*>> h_lrval_index_v;
    build_lrval_index(h_g, h_lrval_index_u, h_lrval_index_v);
    int num_h_lrval_index_u = 0;
    int num_h_lrval_index_v = 0;
    for (int i = 0;i<h_lrval_index_u.size();i++){
        num_h_lrval_index_u = num_h_lrval_index_u + h_lrval_index_u[i].size();
    }
    for (int i = 0;i<h_lrval_index_v.size();i++){
        num_h_lrval_index_v = num_h_lrval_index_v + h_lrval_index_v[i].size();
    }
    cout<<num_h_lrval_index_u<<" "<< num_h_lrval_index_v<<"\n";
    exit(0);
    size_t size = 2 * sizeof(int);
    size_t size_num_v1 = sizeof(int);
    size_t size_num_v2 = sizeof(int);
    size_t size_h_lrval_index_u = sizeof(lrval_index_block*)*h_lrval_index_u[0].size()*h_lrval_index_u.size();
    size_t size_h_lrval_index_v = sizeof(lrval_index_block*)*h_lrval_index_v[0].size()*h_lrval_index_v.size();
    cout<<size_h_lrval_index_u<<" "<<size_num_v1<<"\n";
    exit(0);
    // int *h_c,*d_c;
    // h_c = (int*)malloc(size);
    // cudaMalloc((void**)&d_c,size);
    // cudaMemcpy(d_c,h_c,size,cudaMemcpyHostToDevice);
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_c);
    // cudaMemcpy(h_c,d_c,size,cudaMemcpyDeviceToHost);
    // cout<<h_c[0]<<" "<<h_c[1]<<"\n";
    // exit(0);



    int *d_num_v1;
    int *d_num_v2;
    
    cudaMalloc((void**)&d_num_v1,size_num_v1);
    cudaMalloc((void**)&d_num_v2,size_num_v2);
    cudaMemcpy(d_num_v1,&h_g.num_v1,size_num_v1,cudaMemcpyHostToDevice);
    cudaMemcpy(d_num_v2,&h_g.num_v2,size_num_v2,cudaMemcpyHostToDevice);

    // int *h_c,*d_c;
    // h_c = (int*)malloc(size);
    // cudaMalloc((void**)&d_c,size);
    // cudaMemcpy(d_c,h_c,size,cudaMemcpyHostToDevice);
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_c,d_num_v1,d_num_v2);
    // cudaMemcpy(h_c,d_c,size,cudaMemcpyDeviceToHost);
    // exit(0);

    vector<vector<lrval_index_block*>> *d_lrval_index_u;
    vector<vector<lrval_index_block*>> *d_lrval_index_v;
    cudaMalloc(&d_lrval_index_u,size_h_lrval_index_u);
    cudaMalloc(&d_lrval_index_v,size_h_lrval_index_v);
    cudaMemcpy(d_lrval_index_u,&h_lrval_index_u,size_h_lrval_index_u,cudaMemcpyHostToDevice);
    cudaMemcpy(d_lrval_index_v,&h_lrval_index_v,size_h_lrval_index_v,cudaMemcpyHostToDevice);
    
    exit(0);
    // vector<bool> left; vector<bool> right;
    // // all the vertices in query result are set as true
    // vector<vector<int>> queryStream;
    // queryStream.resize(Q_MAX);
    // int n_query = 0;
    // loadQuery(argv[2], queryStream, n_query);
    // queryStream.resize(n_query);
    // int queryAns[n_query*3];    




}
