#include "decom.h"

using namespace std;
const int Q_MAX = 10000000;
__global__ void test_Kernel(int* d_lrval_index_u_size,int* d_queryStream)
{
    int threadID = threadIdx.x;
    d_queryStream[threadID] = 666;
    
}

void loadQuery(string dir, std::vector<std::vector<int>>& queryStream,int &line)
{
	int r, lval, rval;
	string queryFile = dir + "querystream.txt";
	FILE * queryVec = fopen(queryFile.c_str(), "r");
	line = 0;
	while ((r = fscanf(queryVec, "%d %d", &lval, &rval)) != EOF)
	{
		if (r != 2)
		{
			fprintf(stderr, "Bad file format: u v incorrect\n");
			exit(1);
		}
		queryStream[line].resize(2);
		queryStream[line][0] = lval;
		queryStream[line][1] = rval;
		line++;
	}
	// cout<<"line: " << line;

	fclose(queryVec);
}

void cuda_query(string dir, int num_blocks_per_grid, int num_threads_per_block, int* queryAns) {
	BiGraph h_g(dir);
	lrIndexBasic(h_g);    
    vector<vector<lrval_index_block*>> h_lrval_index_u; vector<vector<lrval_index_block*>> h_lrval_index_v;
    build_lrval_index(h_g, h_lrval_index_u, h_lrval_index_v);

    size_t size = 2 * sizeof(int);
    size_t size_num_v1 = sizeof(int);
    size_t size_num_v2 = sizeof(int);




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
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_c);
    // cudaMemcpy(h_c,d_c,size,cudaMemcpyDeviceToHost);
    // cout<<h_c[0]<<" "<<h_c[1]<<"\n";
    // exit(0);
    int *h_lrval_index_u_size,*d_lrval_index_u_size;
    size_t size_h_lrval_index_u_size = sizeof(h_lrval_index_u.size()) * h_lrval_index_u.size();
    h_lrval_index_u_size = (int*)malloc(size_h_lrval_index_u_size);
 
    for (int i = 0;i<h_lrval_index_u.size();i++){
        h_lrval_index_u_size[i] = h_lrval_index_u[i].size();
    }
    
    cudaMalloc((void**)&d_lrval_index_u_size,size_h_lrval_index_u_size);
    cudaMemcpy(d_lrval_index_u_size,h_lrval_index_u_size,size_h_lrval_index_u_size,cudaMemcpyHostToDevice);
    
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size);


    vector<bool> left; vector<bool> right;
    // all the vertices in query result are set as true
    vector<vector<int>> queryStream;
    queryStream.resize(Q_MAX);
    int n_query = 0;
    loadQuery(dir, queryStream,n_query);
    queryStream.resize(n_query);
    cout<<n_query<<"\n";
    exit(0);
    int *h_queryStream,*d_queryStream;
    size_t size_h_query = sizeof(queryStream[0][0]) * n_query * 2
    h_queryStream = (int*)malloc(size_h_query);
    for (int i = 0;i<n_query;i++){
        h_queryStream[i*2] = queryStream[i][0];
        h_queryStream[i*2+1] = queryStream[i][1];
    }

    cudaMalloc((void**)&d_queryStream,size_h_query);
    cudaMemcpy(d_queryStream,h_queryStream,size_h_query,cudaMemcpyHostToDevice);
    test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size,d_queryStream);
    cudaMemcpy(h_queryStream,d_queryStream,size,cudaMemcpyDeviceToHost);
    cout<<h_queryStream[0]<<" "<<h_queryStream[1]<<"\n";
    exit(0);


    int h_queryAns[n_query*3];
    int *d_queryAns;





}
