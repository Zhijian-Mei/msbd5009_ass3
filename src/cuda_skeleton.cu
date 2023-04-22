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
        if ((*d_lrval_index_u_length<= lval) || (d_lrval_index_u_size[i] <= rval)){
		    flag = 0;
        } else {
            flag = 1;
        }

        d_queryAns[i*3] = lval;
        d_queryAns[i*3+1] = rval;
        d_queryAns[i*3+2] = flag;
    }
    
}
__global__ void test(int* d_lrval_index_u_size,int* d_queryStream,int* d_queryAns,int* d_n_query,int* d_c,int* d_lrval_index_u_length)
{
    const int tid = blockDim.x*blockIdx.x + threadIdx.x;
    const int nthread = blockDim.x*gridDim.x; 

    for(int i = tid;i<*d_n_query; i+= nthread){
        int flag = 0;
        int lval = d_queryStream[i*2];
        int rval = d_queryStream[i*2+1];
        if ((*d_lrval_index_u_length<= lval) || (d_lrval_index_u_size[i] <= rval)){
		    flag = 0;
        } else {
            flag = 1;
        }

        d_queryAns[i*3] = lval;
        d_queryAns[i*3+1] = rval;
        d_queryAns[i*3+2] = flag;
    }
    
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

    // size_t size = 2 * sizeof(int);
    // size_t size_num_v1 = sizeof(int);
    // size_t size_num_v2 = sizeof(int);




    // int *d_num_v1;
    // int *d_num_v2;
    
    // cudaMalloc((void**)&d_num_v1,size_num_v1);
    // cudaMalloc((void**)&d_num_v2,size_num_v2);
    // cudaMemcpy(d_num_v1,&h_g.num_v1,size_num_v1,cudaMemcpyHostToDevice);
    // cudaMemcpy(d_num_v2,&h_g.num_v2,size_num_v2,cudaMemcpyHostToDevice);


    int *h_lrval_index_u_size,*d_lrval_index_u_size,*d_lrval_index_u_length;
    int h_lrval_index_u_length = h_lrval_index_u.size();
    

    cudaMalloc((void**)&d_lrval_index_u_length,sizeof(h_lrval_index_u.size()));
    cudaMemcpy(d_lrval_index_u_length,&h_lrval_index_u_length,sizeof(h_lrval_index_u.size()),cudaMemcpyHostToDevice);
    cudaMemcpy(&h_lrval_index_u_length,d_lrval_index_u_length,,sizeof(h_lrval_index_u.size()),cudaMemcpyDeviceToHost);
    cout<<h_lrval_index_u.size()<<"\n";
    cout<<h_lrval_index_u_length<<"\n";
    
    size_t size_h_lrval_index_u_size = sizeof(h_lrval_index_u.size()) * h_lrval_index_u.size();
    h_lrval_index_u_size = (int*)malloc(size_h_lrval_index_u_size);
    
    for (int i = 0;i<h_lrval_index_u.size();i++){
        h_lrval_index_u_size[i] = h_lrval_index_u[i].size();
    }
    
    cudaMalloc((void**)&d_lrval_index_u_size,size_h_lrval_index_u_size);
    cudaMemcpy(d_lrval_index_u_size,h_lrval_index_u_size,size_h_lrval_index_u_size,cudaMemcpyHostToDevice);
    
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size);

    vector<vector<int>> queryStream;
    queryStream.resize(Q_MAX);
    int n_query = 0;
    int *d_n_query;

    loadQuery(dir, queryStream,n_query);
    queryStream.resize(n_query);
    cudaMalloc((void**)&d_n_query,sizeof(int));
    cudaMemcpy(d_n_query,&n_query,sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(&n_query,d_n_query,sizeof(int),cudaMemcpyDeviceToHost);
    cout<<n_query<<"\n";
    
    
    int *h_queryStream,*d_queryStream;
    size_t size_h_query = sizeof(queryStream[0][0]) * n_query * 2;
    h_queryStream = (int*)malloc(size_h_query);
    for (int i = 0;i<n_query;i++){
        h_queryStream[i*2] = queryStream[i][0];
        h_queryStream[i*2+1] = queryStream[i][1];
    }

    cudaMalloc((void**)&d_queryStream,size_h_query);
    cudaMemcpy(d_queryStream,h_queryStream,size_h_query,cudaMemcpyHostToDevice);
    // test_Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size,d_queryStream);
    // int *h_c,*d_c;
    // h_c = (int*)malloc(sizeof(int)*100);
    // cudaMalloc((void**)&d_c,sizeof(int)*100);
    // cudaMemcpy(d_c,h_c,sizeof(int)*100,cudaMemcpyHostToDevice);
    // test<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size,d_queryStream,d_n_query,d_c);
    // cudaMemcpy(h_c,d_c,sizeof(int)*100,cudaMemcpyDeviceToHost);
    // cout<<h_c[0]<<" "<<h_c[1]<<"\n";
    // exit(0);


    
    int *d_queryAns;
    size_t size_h_queryAns = sizeof(int)*n_query*3;

    cudaMalloc((void**)&d_queryAns,size_h_queryAns);
    cudaMemcpy(d_queryAns,queryAns,size_h_queryAns,cudaMemcpyHostToDevice);
    Kernel<<<num_blocks_per_grid,num_threads_per_block>>>(d_lrval_index_u_size,d_queryStream,d_queryAns,d_n_query,d_lrval_index_u_length);

    cudaMemcpy(queryAns,d_queryAns,size_h_queryAns,cudaMemcpyDeviceToHost);



    






}
