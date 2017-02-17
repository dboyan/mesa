.section #gk110_builtin_code
// DIV U32
//
// UNR recurrence (q = a / b):
// look for z such that 2^32 - b <= b * z < 2^32
// then q - 1 <= (a * z) / 2^32 <= q
//
// INPUT:   $r0: dividend, $r1: divisor
// OUTPUT:  $r0: result, $r1: modulus
// CLOBBER: $r2 - $r3, $p0 - $p1
// SIZE:    22 / 14 * 8 bytes
//
gk110_div_u32:
   sched 0x28 0x04 0x28 0x04 0x28 0x28 0x28
   bfind u32 $r2 $r1
   xor b32 $r2 $r2 0x1f
   mov b32 $r3 0x1
   shl b32 $r2 $r3 clamp $r2
   cvt u32 $r1 neg u32 $r1
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   sched 0x28 0x28 0x28 0x28 0x28 0x28 0x28
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   sched 0x04 0x28 0x04 0x28 0x28 0x2c 0x04
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mov b32 $r3 $r0
   mul high $r0 u32 $r0 u32 $r2
   cvt u32 $r2 neg u32 $r1
   add $r1 (mul u32 $r1 u32 $r0) $r3
   set $p0 0x1 ge u32 $r1 $r2
   $p0 sub b32 $r1 $r1 $r2
   sched 0x28 0x2c 0x04 0x20 0x2e 0x28 0x20
   $p0 add b32 $r0 $r0 0x1
   $p0 set $p0 0x1 ge u32 $r1 $r2
   $p0 sub b32 $r1 $r1 $r2
   $p0 add b32 $r0 $r0 0x1
   ret

// DIV S32, like DIV U32 after taking ABS(inputs)
//
// INPUT:   $r0: dividend, $r1: divisor
// OUTPUT:  $r0: result, $r1: modulus
// CLOBBER: $r2 - $r3, $p0 - $p3
//
gk110_div_s32:
   set $p2 0x1 lt s32 $r0 0x0
   set $p3 0x1 lt s32 $r1 0x0 xor $p2
   sched 0x20 0x28 0x28 0x04 0x28 0x04 0x28
   cvt s32 $r0 abs s32 $r0
   cvt s32 $r1 abs s32 $r1
   bfind u32 $r2 $r1
   xor b32 $r2 $r2 0x1f
   mov b32 $r3 0x1
   shl b32 $r2 $r3 clamp $r2
   cvt u32 $r1 neg u32 $r1
   sched 0x28 0x28 0x28 0x28 0x28 0x28 0x28
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   sched 0x28 0x28 0x04 0x28 0x04 0x28 0x28
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mul $r3 u32 $r1 u32 $r2
   add $r2 (mul high u32 $r2 u32 $r3) $r2
   mov b32 $r3 $r0
   mul high $r0 u32 $r0 u32 $r2
   cvt u32 $r2 neg u32 $r1
   add $r1 (mul u32 $r1 u32 $r0) $r3
   sched 0x2c 0x04 0x28 0x2c 0x04 0x28 0x20
   set $p0 0x1 ge u32 $r1 $r2
   $p0 sub b32 $r1 $r1 $r2
   $p0 add b32 $r0 $r0 0x1
   $p0 set $p0 0x1 ge u32 $r1 $r2
   $p0 sub b32 $r1 $r1 $r2
   $p0 add b32 $r0 $r0 0x1
   $p3 cvt s32 $r0 neg s32 $r0
   sched 0x04 0x2e 0x28 0x04 0x28 0x28 0x28
   $p2 cvt s32 $r1 neg s32 $r1
   ret

// RCP F64
//
// INPUT:   $r0d
// OUTPUT:  $r0d
// CLOBBER: $r2 - $r13, $p0
//
gk110_rcp_f64:
   ext u32 $r2 $r1 0xb14
   add b32 $r3 $r2 0xffffffff
   joinat #L3
   set b32 $p0 0x1 gt u32 $r3 0x7fd
   mov b32 $r3 0x0
   sched 0x2b 0x04 0x2d 0x2b 0x04 0x2b 0x28
   (not $p0) bra #L2
   // Nan/Inf/denorm
   mov b32 $r3 0xffffffff
   set $p0 0x1 gtu f64 abs $r0d 0x7ff0000000000000
   (not $p0) bra #L4
   // NaN -> NaN
   or b32 $r1 $r1 0x80000
   bra #L2
L4:
   and b32 $r4 $r1 0x7ff00000
   sched 0x28 0x2b 0x04 0x28 0x2b 0x2d 0x2b
   set b32 $p0 0x1 eq s32 $r4 0x0
   $p0 bra #L5
   // +/-Inf -> +/-0
   xor b32 $r1 $r1 0x7ff00000
   mov b32 $r0 0x0
   bra #L2
L5:
   set $p0 0x1 gtu f64 abs $r0d 0x0
   $p0 bra #L6
   // +/-0 -> +/-Inf
   sched 0x28 0x2b 0x20 0x28 0x2f 0x28 0x2b
   or b32 $r1 $r1 0x7ff00000
   bra #L2
L6:
   // non-0 denorms: multiply with 2^54, join with norms
   mul rn f64 $r0d $r0d 0x4350000000000000
   mov b32 $r3 0x36
L2:
   join nop
L3:
   set b32 $p0 0x1 lt s32 $r3 0x0
   $p0 bra #rsq_f64_end
   sched 0x28 0x04 0x28 0x28 0x2b 0x04 0x28
   // normalize near 1
   add b32 $r4 $r2 0xc01
   shl b32 $r7 $r4 clamp 0x14
   mov b32 $r6 $r0
   sub b32 $r7 $r1 $r7
   // convert to float, do newton-raphson step once
   cvt rz f32 $r5 f64 $r6
   rcp f32 $r4 $r5
   mov b32 $r0 0xbf800000
   sched 0x28 0x28 0x2a 0x2b 0x2e 0x28 0x2e
   fma rn f32 $r5 $r4 $r5 $r0
   add ftz rn f32 $r5 neg $r5 neg 0x0
   fma rn f32 $r0 $r4 $r5 $r4
   // convert back to double, do newton-raphson steps
   cvt f64 $r4 f32 $r0
   cvt f64 $r6 f64 neg $r6d
   mov b32 $r9 0x3ff00000
   mov b32 $r8 0x0
   sched 0x29 0x23 0x29 0x29 0x23 0x25 0x23
   fma rn f64 $r0d $r6d $r4d $r8d
   fma rn f64 $r10d $r0d $r4d $r4d
   mul rn f64 $r12d $r0d $r0d
   fma rn f64 $r10d $r10d $r12d $r10d
   fma rn f64 $r12d $r6d $r10d $r8d
   fma rn f64 $r4d $r0d $r10d $r4d
   fma rn f64 $r10d $r10d $r12d $r10d
   sched 0x20 0x28 0x20 0x28 0x28 0x28 0x28
   fma rn f64 $r8d $r6d $r4d $r8d
   subr b32 $r2 $r2 0x3ff
   fma rn f64 $r0d $r10d $r8d $r4d
   add b32 $r12 $r2 $r3
   ext u32 $r3 $r1 0xb14
   add b32 $r3 $r3 $r12
   add b32 $r2 $r3 0xffffffff
   sched 0x28 0x2b 0x28 0x28 0x2b 0x28 0x28
   set b32 $p0 0x1 lt u32 $r2 0x7fe
   (not $p0) bra #L7
   // normals, convert exponents back
   shl b32 $r12 $r12 clamp 0x14
   add b32 $r1 $r12 $r1
   bra #rsq_f64_end
L7:
   add b32 $r12 $r3 0xfffffc01
   set b32 $p0 0x1 gt s32 $r12 0x3ff
   sched 0x2b 0x20 0x25 0x28 0x2b 0x28 0x23
   (not $p0) bra #L8
   // infinity
   and b32 $r1 $r1 0x80000000
   mov b32 $r0 0x0
   add b32 $r1 $r1 0x7ff00000
   bra #rsq_f64_end
L8:
   // denorms, they only fall within a small range, can't be smaller than
   // 0x0004000000000000. The following code make use of this fact.
   subr b32 $r12 $r12 0xfffffc01
   set b32 $p0 0x1 gt u32 $r12 0x0
   sched 0x25 0x28 0x23 0x25 0x28 0x2c 0x2e
   and b32 $r1 $r1 0x000fffff
   $p0 mov b32 $r7 0x3fd00000
   (not $p0) mov b32 $r7 0x3fe00000
   add b32 $r1 $r1 0x00100000
   mov b32 $r6 0x0
   mul rn f64 $r0d $r0d $r6d
rsq_f64_end:
   ret
gk110_rsq_f64:
   sched 0x2e 0x00 0x00 0x00 0x00 0x00 0x00
   ret

.section #gk110_builtin_offsets
.b64 #gk110_div_u32
.b64 #gk110_div_s32
.b64 #gk110_rcp_f64
.b64 #gk110_rsq_f64
