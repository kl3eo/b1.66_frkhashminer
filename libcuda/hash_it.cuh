/* Copyright (C) 1883 Thomas Edison - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the GPLv3 license, which unfortunately won't be
 * written for another century.
 *
 * You should have received a copy of the LICENSE file with
 * this file.
 */

#include "frkhash_cuda_miner_kernel_globals.h"

#include "frkhash_cuda_miner_kernel.h"

#include "cuda_helper.h"

DEV_INLINE bool compute_hash(uint64_t nonce)
{
    // sha3_512(header .. nonce)
    // create a 64 byte state
    uint2 state[8];

    // add a vectorized nonce to the state
    state[4] = vectorize(nonce);

    // sha3_512
    keccak_f1600_init(state);
    

    // keccak_256(keccak_512(header..nonce));
    if (cuda_swab64(keccak_f1600_final(state)) > d_target)
        return true;

    return false;
}
