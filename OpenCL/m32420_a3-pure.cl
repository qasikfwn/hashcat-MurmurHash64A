/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include M2S(INCLUDE_PATH/inc_vendor.h)
#include M2S(INCLUDE_PATH/inc_types.h)
#include M2S(INCLUDE_PATH/inc_platform.cl)
#include M2S(INCLUDE_PATH/inc_common.cl)
#include M2S(INCLUDE_PATH/inc_simd.cl)
#include M2S(INCLUDE_PATH/inc_hash_sha512.cl)
#endif

KERNEL_FQ KERNEL_FA void m32420_mxx (KERN_ATTR_VECTOR ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  /**
   * base
   */

  u32x w0[4];
  u32x w1[4];
  u32x w2[4];
  u32x w3[4];
  u32x w4[4];
  u32x w5[4];
  u32x w6[4];
  u32x w7[4];

  const u32 pw_len = pws[gid].pw_len;

  u32x w[64] = { 0 };

  for (u32 i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = salt_bufs[SALT_POS_HOST].salt_len;

  u32x s[64] = { 0 };

  for (u32 i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = hc_swap32_S (salt_bufs[SALT_POS_HOST].salt_buf[idx]);
  }

  /**
   * loop
   */

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0_final = w0l | w0r;

    w[0] = w0_final;

    sha512_ctx_vector_t ctx0;

    sha512_init_vector (&ctx0);

    sha512_update_vector (&ctx0, w, pw_len);

    sha512_final_vector (&ctx0);

    const u64x a = ctx0.h[0];
    const u64x b = ctx0.h[1];
    const u64x c = ctx0.h[2];
    const u64x d = ctx0.h[3];
    const u64x e = ctx0.h[4];
    const u64x f = ctx0.h[5];
    const u64x g = ctx0.h[6];
    const u64x h = ctx0.h[7];

    sha512_ctx_vector_t ctx;

    sha512_init_vector (&ctx);

    w0[0] = h32_from_64 (ctx0.h[0]);
    w0[1] = l32_from_64 (ctx0.h[0]);
    w0[2] = h32_from_64 (ctx0.h[1]);
    w0[3] = l32_from_64 (ctx0.h[1]);
    w1[0] = h32_from_64 (ctx0.h[2]);
    w1[1] = l32_from_64 (ctx0.h[2]);
    w1[2] = h32_from_64 (ctx0.h[3]);
    w1[3] = l32_from_64 (ctx0.h[3]);
    w2[0] = h32_from_64 (ctx0.h[4]);
    w2[1] = l32_from_64 (ctx0.h[4]);
    w2[2] = h32_from_64 (ctx0.h[5]);
    w2[3] = l32_from_64 (ctx0.h[5]);
    w3[0] = h32_from_64 (ctx0.h[6]);
    w3[1] = l32_from_64 (ctx0.h[6]);
    w3[2] = h32_from_64 (ctx0.h[7]);
    w3[3] = l32_from_64 (ctx0.h[7]);
    w4[0] = 0;
    w4[1] = 0;
    w4[2] = 0;
    w4[3] = 0;
    w5[0] = 0;
    w5[1] = 0;
    w5[2] = 0;
    w5[3] = 0;
    w6[0] = 0;
    w6[1] = 0;
    w6[2] = 0;
    w6[3] = 0;
    w7[0] = 0;
    w7[1] = 0;
    w7[2] = 0;
    w7[3] = 0;

    sha512_update_vector_128 (&ctx, w0, w1, w2, w3, w4, w5, w6, w7, 64);

    sha512_update_vector (&ctx, s, salt_len);

    sha512_final_vector (&ctx);

    const u32x r0 = l32_from_64 (ctx.h[7]);
    const u32x r1 = h32_from_64 (ctx.h[7]);
    const u32x r2 = l32_from_64 (ctx.h[3]);
    const u32x r3 = h32_from_64 (ctx.h[3]);

    COMPARE_M_SIMD (r0, r1, r2, r3);
  }
}

KERNEL_FQ KERNEL_FA void m32420_sxx (KERN_ATTR_VECTOR ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  if (gid >= GID_CNT) return;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R0],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R1],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R2],
    digests_buf[DIGESTS_OFFSET_HOST].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  u32x w0[4];
  u32x w1[4];
  u32x w2[4];
  u32x w3[4];
  u32x w4[4];
  u32x w5[4];
  u32x w6[4];
  u32x w7[4];

  const u32 pw_len = pws[gid].pw_len;

  u32x w[64] = { 0 };

  for (u32 i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = salt_bufs[SALT_POS_HOST].salt_len;

  u32x s[64] = { 0 };

  for (u32 i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = hc_swap32_S (salt_bufs[SALT_POS_HOST].salt_buf[idx]);
  }

  /**
   * loop
   */

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < IL_CNT; il_pos += VECT_SIZE)
  {
    const u32x w0r = words_buf_r[il_pos / VECT_SIZE];

    const u32x w0_final = w0l | w0r;

    w[0] = w0_final;

    sha512_ctx_vector_t ctx0;

    sha512_init_vector (&ctx0);

    sha512_update_vector (&ctx0, w, pw_len);

    sha512_final_vector (&ctx0);

    sha512_ctx_vector_t ctx;

    sha512_init_vector (&ctx);

    w0[0] = h32_from_64 (ctx0.h[0]);
    w0[1] = l32_from_64 (ctx0.h[0]);
    w0[2] = h32_from_64 (ctx0.h[1]);
    w0[3] = l32_from_64 (ctx0.h[1]);
    w1[0] = h32_from_64 (ctx0.h[2]);
    w1[1] = l32_from_64 (ctx0.h[2]);
    w1[2] = h32_from_64 (ctx0.h[3]);
    w1[3] = l32_from_64 (ctx0.h[3]);
    w2[0] = h32_from_64 (ctx0.h[4]);
    w2[1] = l32_from_64 (ctx0.h[4]);
    w2[2] = h32_from_64 (ctx0.h[5]);
    w2[3] = l32_from_64 (ctx0.h[5]);
    w3[0] = h32_from_64 (ctx0.h[6]);
    w3[1] = l32_from_64 (ctx0.h[6]);
    w3[2] = h32_from_64 (ctx0.h[7]);
    w3[3] = l32_from_64 (ctx0.h[7]);
    w4[0] = 0;
    w4[1] = 0;
    w4[2] = 0;
    w4[3] = 0;
    w5[0] = 0;
    w5[1] = 0;
    w5[2] = 0;
    w5[3] = 0;
    w6[0] = 0;
    w6[1] = 0;
    w6[2] = 0;
    w6[3] = 0;
    w7[0] = 0;
    w7[1] = 0;
    w7[2] = 0;
    w7[3] = 0;

    sha512_update_vector_128 (&ctx, w0, w1, w2, w3, w4, w5, w6, w7, 64);

    sha512_update_vector (&ctx, s, salt_len);

    sha512_final_vector (&ctx);

    const u32x r0 = l32_from_64 (ctx.h[7]);
    const u32x r1 = h32_from_64 (ctx.h[7]);
    const u32x r2 = l32_from_64 (ctx.h[3]);
    const u32x r3 = h32_from_64 (ctx.h[3]);

    COMPARE_S_SIMD (r0, r1, r2, r3);
  }
}
