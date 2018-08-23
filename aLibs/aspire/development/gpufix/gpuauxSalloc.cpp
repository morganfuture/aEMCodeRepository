/* Store a single precision matrix on the GPU.
 *
 * Yoel Shkolnisky, July 2016.
 */

/* Compile using
 * mex gpuauxSalloc.cpp -O -I/usr/local/cuda/targets/x86_64-linux/include/ -L/usr/local/cuda/targets/x86_64-linux/lib/ -lcublas
 */

#include <stdint.h>
#include <inttypes.h>
#include "mex.h"
//#include "cublas.h"
#include <cuda_runtime.h>
#include "cublas_v2.h"
#include "timings.h"

//#define DEBUG

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    int M,N;    // Dimensions of the input matrix.
    float *A;   // Data elements of the input array.
    float *gA;  // Pointer to the GPU copy of the data of A.
    uint64_t *gptr; // Address of the GPU-allocated array.
    uint64_t hptr;
    cublasHandle_t handle;
    cublasStatus_t retStatus;
    cudaError_t cudaStat;
    
    if (nrhs != 2) {
        mexErrMsgTxt("gpuauxSalloc requires 2 input arguments (handle and matrix A)");
    } else if (nlhs != 1) {
        mexErrMsgTxt("gpuauxSalloc requires 1 output argument");
    }
    
    hptr=(uint64_t) mxGetScalar(prhs[0]);
    handle = (cublasHandle_t) hptr;

    A = (float*) mxGetPr(prhs[1]);  // Get data of A.
    M = mxGetM(prhs[1]);   // Get number of rows of A.
    N = mxGetN(prhs[1]);   // Get number of columns of A.
        
    #ifdef DEBUG
    mexPrintf("M=%d  N=%d\n",M,N);
    #endif
        
    /* ALLOCATE SPACE ON THE GPU */
    //cublasAlloc (M*N, sizeof(float), (void**)&gA);
    cudaStat=cudaMalloc((void**)&gA,M*N*sizeof(float));
    
    // test for error
    if (cudaStat != cudaSuccess) {
        mexPrintf("CUBLAS: an error occured in cublasAlloc\n");
    } 
    #ifdef DEBUG
    else {
        mexPrintf("CUBLAS: cublasAlloc worked\n");
    }
    #endif
    
    retStatus = cublasSetMatrix (M, N, sizeof(float),
            A, M, (void*)gA, M);
    
    if (retStatus != CUBLAS_STATUS_SUCCESS) {
        mexPrintf("[%s,%d] an error occured in cublasSetMatrix\n",__FILE__,__LINE__);
    } 
    #ifdef DEBUG
    else {
        mexPrintf("[%s,%d] cublasSetMatrix worked\n",__FILE__,__LINE__);
    }
    #endif
        
    plhs[0] = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
    gptr=(uint64_t*) mxGetPr(plhs[0]);
    *gptr=(uint64_t) gA;

    #ifdef DEBUG
    mexPrintf("[%s,%d] GPU array allocated at address %" PRIu64 "\n", __FILE__,__LINE__,(uint64_t)gA);
    #endif

}

