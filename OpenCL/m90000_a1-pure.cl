/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include M2S(INCLUDE_PATH/inc_vendor.h)
#include M2S(INCLUDE_PATH/inc_types.h)
#include M2S(INCLUDE_PATH/inc_platform.cl)
#include M2S(INCLUDE_PATH/inc_common.cl)
#include M2S(INCLUDE_PATH/inc_scalar.cl)
#endif

DECLSPEC u64 MurmurHash64A_round_g (const u8 *data, u64 hash, const u32 cur_pos) {
  #define M 0xc6a4a7935bd1e995
  #define R 47

  u64 k = ((u64) data[cur_pos])
    | ((u64) data[cur_pos + 1] << 8)
    | ((u64) data[cur_pos + 2] << 16)
    | ((u64) data[cur_pos + 3] << 24)
    | ((u64) data[cur_pos + 4] << 32)
    | ((u64) data[cur_pos + 5] << 40)
    | ((u64) data[cur_pos + 6] << 48)
    | ((u64) data[cur_pos + 7] << 56);
  
  k *= M;
  k ^= k >> R;
  k *= M;

  hash ^= k;
  hash *= M;

  #undef M
  #undef R

  return hash;
}

DECLSPEC u64 MurmurHash64A_final_g (const u8 *data, u64 hash, const u32 cur_pos, const u32 len) {
  #define M 0xc6a4a7935bd1e995
  #define R 47

  const u32 overflow = len & 7;

  if (overflow == 7)
  {
    hash ^= ((u64) data[cur_pos + 6] << 48);
  }
  if (overflow >= 6)
  {
    hash ^= ((u64) data[cur_pos + 5] << 40);
  }
  if (overflow >= 5)
  {
    hash ^= ((u64) data[cur_pos + 4] << 32);
  }
  if (overflow >= 4)
  {
    hash ^= ((u64) data[cur_pos + 3] << 24);
  }
  if (overflow >= 3)
  {
    hash ^= ((u64) data[cur_pos + 2] << 16);
  }
  if (overflow >= 2)
  {
    hash ^= ((u64) data[cur_pos + 1] << 8);
  }
  if (overflow >= 1)
  {
    hash ^= ((u64) data[cur_pos]);
  }
  if (overflow > 0)
  {
    hash *= M;
  }

  hash ^= hash >> R;
  hash *= M;
  hash ^= hash >> R;

  #undef M
  #undef R

  return hash;
}

DECLSPEC u64 MurmurHash64A_g (const u64 seed, const u8 *data, const u32 len)
{
  #define M 0xc6a4a7935bd1e995
  #define R 47

  //Initialize hash
  u64 hash = seed ^ (len * M);

  const u64 INITIAL = hash;
  
  const u32 endpos = len - (len & 7);

  //const u32 nBlocks = len >> 3; // number of 8 byte blocks
  const u8 *data2 = (const u8*) data;

  // Loop over blocks of 8 bytes
  u32 i = 0;
  while (i != endpos) {
    hash = MurmurHash64A_round_g(data2, hash, i);

    i += 8;
  }

  // Overflow

  const u64 BEFORE_FINAL = hash;

  hash = MurmurHash64A_final_g (data2, hash, i, len);

  const u64 AFTER_FINAL = hash;

  printf("debug: %016lx:%016lx:%c%c%c%c%c%c%c%c%c%c len: %d INITIAL: %016lx B4FINAL: %016lx AFTER_FINAL: %016lx\n", hash, seed, data2[0], data2[1], data2[2], data2[3], data2[4], data2[5], data2[6], data2[7], data2[8], data2[9], len, INITIAL, BEFORE_FINAL, AFTER_FINAL);
  //printf("data2 = %.2s, len = %d\n", data2[0], len);

  #undef M
  #undef R

  return hash;
}

KERNEL_FQ void m90000_mxx (KERN_ATTR_BASIC ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);
  
  /**
   * base
   */

  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  //if ((gid == 0) && (lid == 0)) printf ("%016lx\n", pw_buf0);
  //printf("Hello world\n");

  // why is this here?
  // const u32 pw_len = pws[gid].pw_len & 63;

  /**
   * salt
   */

  
  const u32 seed_lo = salt_bufs[SALT_POS_HOST].salt_buf[0];
  const u32 seed_hi = salt_bufs[SALT_POS_HOST].salt_buf[1];
  const u64 seed = ((u64) seed_hi << 32) | ((u64) seed_lo); // seems to work?

  //u8 *temp_ref_lo = (u8*) &seed_lo;
  //u8 *temp_ref_hi = (u8*) &seed_hi;
  //u8 *temp_ref = (u8*) &seed;
  //if ((gid == 0) && (lid == 0)) printf ("seed = %02x%02x%02x%02x%02x%02x%02x%02x\n", temp_ref_lo[0], temp_ref_lo[1], temp_ref_lo[2], temp_ref_lo[3], temp_ref_hi[0], temp_ref_hi[1], temp_ref_hi[2], temp_ref_hi[3]);
  //if ((gid == 0) && (lid == 0)) printf ("seed = %02x%02x%02x%02x%02x%02x%02x%02x\n", temp_ref_lo[0], temp_ref_lo[1], temp_ref_lo[2], temp_ref_lo[3], temp_ref_lo[4], temp_ref_lo[5], temp_ref_lo[6], temp_ref_lo[7]);
  //if ((gid == 0) && (lid == 0)) printf ("seed = %02x%02x%02x%02x%02x%02x%02x%02x\n", temp_ref[0], temp_ref[1], temp_ref[2], temp_ref[3], temp_ref[4], temp_ref[5], temp_ref[6], temp_ref[7]);

  /**
   * loop
   */
  
  //printf("Running a1 m90000_mxx\n");

  // probably really bad for performance. fix later
  GLOBAL_AS const u8 *left = (GLOBAL_AS const u8*) pws[gid].i;
  // create combined buffer
  u8 combined_buf[256];

  // copy left buffer
  for (u32 i = 0; i < pws[gid].pw_len; i++) {
    combined_buf[i] = left[i];
  }
  
  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    //const u32 tmp_buf = combs_buf[il_pos].i;
    //if ((gid == 0) && (lid == 0)) printf ("combs_buf[il_pos].i = %08x\n", tmp_buf);

    //u64x hash = MurmurHash64A_g (seed, pws[gid].i, pws[gid].pw_len, combs_buf[il_pos].i, combs_buf[il_pos].pw_len);

    GLOBAL_AS const u8 *right = (GLOBAL_AS const u8*) combs_buf[il_pos].i;

    // copy right buffer
    for (u32 i = 0; i < combs_buf[il_pos].pw_len; i++) {
      combined_buf[i + pws[gid].pw_len] = right[i];
    }

    u64x hash = MurmurHash64A_g (seed, combined_buf, pws[gid].pw_len + combs_buf[il_pos].pw_len);

    const u32x r0 = l32_from_64(hash);
    const u32x r1 = h32_from_64(hash);
    const u32x z = 0;

    COMPARE_M_SCALAR (r0, r1, z, z);
  }
}

KERNEL_FQ void m90000_sxx (KERN_ATTR_BASIC ())
{
  /**
   * modifier
   */

  const u64 lid = get_local_id (0);

  /**
   * base
   */

  const u64 gid = get_global_id (0);

  if (gid >= GID_CNT) return;

  /**
   * salt
   */

  const u32 seed_lo = salt_bufs[SALT_POS_HOST].salt_buf[0];
  const u32 seed_hi = salt_bufs[SALT_POS_HOST].salt_buf[1];
  const u64 seed = ((u64) seed_hi << 32) | ((u64) seed_lo);

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R0],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R1],
    0,
    0
  };

  /**
   * loop
   */

  printf("Running a1 m90000_sxx\n");
  

  u8 combined_buf[256];

  // copy left buffer
  GLOBAL_AS const u8 *left = (GLOBAL_AS const u8*) pws[gid].i;
  for (u32 i = 0; i < pws[gid].pw_len; i++) {
    combined_buf[i] = left[i];
  }


  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos++)
  {
    
    // copy right buffer
    GLOBAL_AS const u8 *right = (GLOBAL_AS const u8*) combs_buf[il_pos].i;
    for (u32 i = 0; i < combs_buf[il_pos].pw_len; i++) {
      combined_buf[i + pws[gid].pw_len] = right[i];
    }

    u64 hash = MurmurHash64A_g (seed, combined_buf, pws[gid].pw_len + combs_buf[il_pos].pw_len);

    const u32 r0 = l32_from_64 (hash);
    const u32 r1 = h32_from_64 (hash);
    const u32 z = 0;

    COMPARE_S_SCALAR (r0, r1, z, z);
  }
}
