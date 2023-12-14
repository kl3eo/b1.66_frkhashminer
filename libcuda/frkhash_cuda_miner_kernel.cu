/* Copyright (C) 1883 Thomas Edison - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the GPLv3 license, which unfortunately won't be
 * written for another century.
 *
 * You should have received a copy of the LICENSE file with
 * this file.
 */

#include "frkhash_cuda_miner_kernel.h"

#include "frkhash_cuda_miner_kernel_globals.h"

#include "cuda_helper.h"

#define copy(dst, src, count)                                                                                          \
    for (int i = 0; i != count; ++i) {                                                                                 \
        (dst)[i] = (src)[i];                                                                                           \
    }

#include "keccak.cuh"

#include "hash_it.cuh"

__global__ void frkhash_search(Search_results* g_output, uint64_t start_nonce) {
    if (g_output->done)
        return;
    uint32_t const gid = blockIdx.x * blockDim.x + threadIdx.x;
    bool r = compute_hash(start_nonce + gid);
    if (threadIdx.x == 0)
        atomicInc((uint32_t*)&g_output->hashCount, 0xffffffff);
    if (r)
        return;
    uint32_t index = atomicInc((uint32_t*)&g_output->solCount, 0xffffffff);
    if (index >= MAX_SEARCH_RESULTS)
        return;
    g_output->gid[index] = gid;
    g_output->done = 1;
}

void run_frkhash_search(uint32_t gridSize, uint32_t blockSize, cudaStream_t stream, Search_results* g_output,
                       uint64_t start_nonce) {
    frkhash_search<<<gridSize, blockSize, 0, stream>>>(g_output, start_nonce);
    CUDA_CALL(cudaGetLastError());
}

void set_header(hash32_t _header) { CUDA_CALL(cudaMemcpyToSymbol(d_header, &_header, sizeof(hash32_t))); }

void set_target(uint64_t _target) { CUDA_CALL(cudaMemcpyToSymbol(d_target, &_target, sizeof(uint64_t))); }