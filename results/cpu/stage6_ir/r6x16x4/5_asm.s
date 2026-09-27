	.att_syntax
	.file	"LLVMDialectModule"
	.text
	.globl	entry                           # -- Begin function entry
	.prefalign	4, .Lfunc_end0, nop
	.type	entry,@function
entry:                                  # @entry
# %bb.0:
	pushq	%r15
	pushq	%r14
	pushq	%r12
	pushq	%rbx
	subq	$792, %rsp                      # imm = 0x318
	movq	848(%rsp), %rdx
	movq	944(%rsp), %rax
	movq	904(%rsp), %rcx
	leaq	3400(%rsi), %rdi
	xorl	%r9d, %r9d
	leaq	5240(%rdx), %r8
	.p2align	4
.LBB0_1:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
                                        #       Child Loop BB0_3 Depth 3
                                        #     Child Loop BB0_6 Depth 2
	imulq	$1320, %r9, %r10                # imm = 0x528
	imulq	$680, %r9, %r11                 # imm = 0x2A8
	movq	%rdx, %rbx
	xorl	%r14d, %r14d
	addq	%rax, %r10
	.p2align	4
.LBB0_2:                                #   Parent Loop BB0_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_3 Depth 3
	vxorps	%xmm0, %xmm0, %xmm0
	movq	$-4, %r15
	movq	%rbx, %r12
	vxorps	%xmm1, %xmm1, %xmm1
	vxorps	%xmm2, %xmm2, %xmm2
	vxorps	%xmm3, %xmm3, %xmm3
	vxorps	%xmm4, %xmm4, %xmm4
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm6, %xmm6, %xmm6
	vxorps	%xmm7, %xmm7, %xmm7
	vxorps	%xmm8, %xmm8, %xmm8
	vxorps	%xmm9, %xmm9, %xmm9
	vxorps	%xmm10, %xmm10, %xmm10
	vxorps	%xmm11, %xmm11, %xmm11
	.p2align	4
.LBB0_3:                                #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	vmovups	(%r12), %ymm12
	vbroadcastss	-3384(%rdi,%r15,4), %ymm13
	vmovups	32(%r12), %ymm14
	vbroadcastss	28(%rdi,%r15,4), %ymm15
	vfmadd231ps	%ymm12, %ymm13, %ymm0   # ymm0 = (ymm13 * ymm12) + ymm0
	vfmadd231ps	%ymm13, %ymm14, %ymm1   # ymm1 = (ymm14 * ymm13) + ymm1
	vbroadcastss	-2704(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm3   # ymm3 = (ymm13 * ymm14) + ymm3
	vfmadd231ps	%ymm13, %ymm12, %ymm2   # ymm2 = (ymm12 * ymm13) + ymm2
	vbroadcastss	-2024(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm5   # ymm5 = (ymm13 * ymm14) + ymm5
	vfmadd231ps	%ymm13, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm13) + ymm4
	vbroadcastss	-1344(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm7   # ymm7 = (ymm13 * ymm14) + ymm7
	vfmadd231ps	%ymm13, %ymm12, %ymm6   # ymm6 = (ymm12 * ymm13) + ymm6
	vbroadcastss	-664(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm9   # ymm9 = (ymm13 * ymm14) + ymm9
	vfmadd231ps	%ymm13, %ymm12, %ymm8   # ymm8 = (ymm12 * ymm13) + ymm8
	vbroadcastss	16(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm11  # ymm11 = (ymm13 * ymm14) + ymm11
	vfmadd231ps	%ymm12, %ymm13, %ymm10  # ymm10 = (ymm13 * ymm12) + ymm10
	vmovups	1352(%r12), %ymm12
	vbroadcastss	-3380(%rdi,%r15,4), %ymm13
	vmovups	1320(%r12), %ymm14
	vfmadd231ps	%ymm12, %ymm13, %ymm1   # ymm1 = (ymm13 * ymm12) + ymm1
	vfmadd231ps	%ymm13, %ymm14, %ymm0   # ymm0 = (ymm14 * ymm13) + ymm0
	vbroadcastss	-2700(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm2   # ymm2 = (ymm13 * ymm14) + ymm2
	vfmadd231ps	%ymm13, %ymm12, %ymm3   # ymm3 = (ymm12 * ymm13) + ymm3
	vbroadcastss	-2020(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm4   # ymm4 = (ymm13 * ymm14) + ymm4
	vfmadd231ps	%ymm13, %ymm12, %ymm5   # ymm5 = (ymm12 * ymm13) + ymm5
	vbroadcastss	-1340(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm6   # ymm6 = (ymm13 * ymm14) + ymm6
	vfmadd231ps	%ymm13, %ymm12, %ymm7   # ymm7 = (ymm12 * ymm13) + ymm7
	vbroadcastss	-660(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm8   # ymm8 = (ymm13 * ymm14) + ymm8
	vfmadd231ps	%ymm13, %ymm12, %ymm9   # ymm9 = (ymm12 * ymm13) + ymm9
	vbroadcastss	20(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm10  # ymm10 = (ymm13 * ymm14) + ymm10
	vfmadd231ps	%ymm12, %ymm13, %ymm11  # ymm11 = (ymm13 * ymm12) + ymm11
	vmovups	2640(%r12), %ymm12
	vbroadcastss	-3376(%rdi,%r15,4), %ymm13
	vmovups	2672(%r12), %ymm14
	vfmadd231ps	%ymm12, %ymm13, %ymm0   # ymm0 = (ymm13 * ymm12) + ymm0
	vfmadd231ps	%ymm13, %ymm14, %ymm1   # ymm1 = (ymm14 * ymm13) + ymm1
	vbroadcastss	-2696(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm3   # ymm3 = (ymm13 * ymm14) + ymm3
	vfmadd231ps	%ymm13, %ymm12, %ymm2   # ymm2 = (ymm12 * ymm13) + ymm2
	vbroadcastss	-2016(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm5   # ymm5 = (ymm13 * ymm14) + ymm5
	vfmadd231ps	%ymm13, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm13) + ymm4
	vbroadcastss	-1336(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm7   # ymm7 = (ymm13 * ymm14) + ymm7
	vfmadd231ps	%ymm13, %ymm12, %ymm6   # ymm6 = (ymm12 * ymm13) + ymm6
	vbroadcastss	-656(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm9   # ymm9 = (ymm13 * ymm14) + ymm9
	vfmadd231ps	%ymm13, %ymm12, %ymm8   # ymm8 = (ymm12 * ymm13) + ymm8
	vbroadcastss	24(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm11  # ymm11 = (ymm13 * ymm14) + ymm11
	vfmadd231ps	%ymm12, %ymm13, %ymm10  # ymm10 = (ymm13 * ymm12) + ymm10
	vmovups	3992(%r12), %ymm12
	vmovups	3960(%r12), %ymm14
	vbroadcastss	-3372(%rdi,%r15,4), %ymm13
	addq	$5280, %r12                     # imm = 0x14A0
	vfmadd231ps	%ymm12, %ymm13, %ymm1   # ymm1 = (ymm13 * ymm12) + ymm1
	vfmadd231ps	%ymm13, %ymm14, %ymm0   # ymm0 = (ymm14 * ymm13) + ymm0
	vbroadcastss	-2692(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm15, %ymm10  # ymm10 = (ymm15 * ymm14) + ymm10
	vfmadd231ps	%ymm12, %ymm15, %ymm11  # ymm11 = (ymm15 * ymm12) + ymm11
	vfmadd231ps	%ymm14, %ymm13, %ymm2   # ymm2 = (ymm13 * ymm14) + ymm2
	vfmadd231ps	%ymm13, %ymm12, %ymm3   # ymm3 = (ymm12 * ymm13) + ymm3
	vbroadcastss	-2012(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm4   # ymm4 = (ymm13 * ymm14) + ymm4
	vfmadd231ps	%ymm13, %ymm12, %ymm5   # ymm5 = (ymm12 * ymm13) + ymm5
	vbroadcastss	-1332(%rdi,%r15,4), %ymm13
	vfmadd231ps	%ymm14, %ymm13, %ymm6   # ymm6 = (ymm13 * ymm14) + ymm6
	vfmadd231ps	%ymm13, %ymm12, %ymm7   # ymm7 = (ymm12 * ymm13) + ymm7
	vbroadcastss	-652(%rdi,%r15,4), %ymm13
	addq	$4, %r15
	vfmadd231ps	%ymm14, %ymm13, %ymm8   # ymm8 = (ymm13 * ymm14) + ymm8
	vfmadd231ps	%ymm13, %ymm12, %ymm9   # ymm9 = (ymm12 * ymm13) + ymm9
	cmpq	$164, %r15
	jb	.LBB0_3
# %bb.4:                                # %.preheader202
                                        #   in Loop: Header=BB0_2 Depth=2
	vmovsd	672(%rsi,%r11), %xmm12          # xmm12 = mem[0],zero
	vmovups	221760(%rdx,%r14,4), %ymm13
	vmovups	221792(%rdx,%r14,4), %ymm15
	addq	$64, %rbx
	cmpq	$304, %r14                      # imm = 0x130
	vmovaps	%xmm12, 272(%rsp)               # 16-byte Spill
	vbroadcastss	%xmm12, %ymm12
	vfmadd231ps	%ymm13, %ymm12, %ymm0   # ymm0 = (ymm12 * ymm13) + ymm0
	vfmadd231ps	%ymm12, %ymm15, %ymm1   # ymm1 = (ymm15 * ymm12) + ymm1
	vmovsd	1352(%rsi,%r11), %xmm12         # xmm12 = mem[0],zero
	vmovaps	%xmm12, -128(%rsp)              # 16-byte Spill
	vbroadcastss	%xmm12, %ymm12
	vfmadd231ps	%ymm13, %ymm12, %ymm2   # ymm2 = (ymm12 * ymm13) + ymm2
	vfmadd231ps	%ymm12, %ymm15, %ymm3   # ymm3 = (ymm15 * ymm12) + ymm3
	vmovsd	2032(%rsi,%r11), %xmm12         # xmm12 = mem[0],zero
	vmovaps	%xmm12, -96(%rsp)               # 16-byte Spill
	vbroadcastss	%xmm12, %ymm12
	vfmadd231ps	%ymm13, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm13) + ymm4
	vfmadd231ps	%ymm12, %ymm15, %ymm5   # ymm5 = (ymm15 * ymm12) + ymm5
	vmovsd	2712(%rsi,%r11), %xmm12         # xmm12 = mem[0],zero
	vbroadcastss	%xmm12, %ymm14
	vmovaps	%xmm12, 208(%rsp)               # 16-byte Spill
	vmovsd	3392(%rsi,%r11), %xmm12         # xmm12 = mem[0],zero
	vfmadd231ps	%ymm13, %ymm14, %ymm6   # ymm6 = (ymm14 * ymm13) + ymm6
	vfmadd231ps	%ymm14, %ymm15, %ymm7   # ymm7 = (ymm15 * ymm14) + ymm7
	vbroadcastss	%xmm12, %ymm14
	vmovaps	%xmm12, 240(%rsp)               # 16-byte Spill
	vmovsd	4072(%rsi,%r11), %xmm12         # xmm12 = mem[0],zero
	vfmadd231ps	%ymm13, %ymm14, %ymm8   # ymm8 = (ymm14 * ymm13) + ymm8
	vfmadd231ps	%ymm14, %ymm15, %ymm9   # ymm9 = (ymm15 * ymm14) + ymm9
	vbroadcastss	%xmm12, %ymm14
	vmovaps	%xmm12, 304(%rsp)               # 16-byte Spill
	vmovshdup	272(%rsp), %xmm12       # 16-byte Folded Reload
                                        # xmm12 = mem[1,1,3,3]
	vfmadd231ps	%ymm13, %ymm14, %ymm10  # ymm10 = (ymm14 * ymm13) + ymm10
	vfmadd231ps	%ymm15, %ymm14, %ymm11  # ymm11 = (ymm14 * ymm15) + ymm11
	vmovups	223080(%rdx,%r14,4), %ymm14
	vbroadcastss	%xmm12, %ymm13
	vmovups	223112(%rdx,%r14,4), %ymm12
	vfmadd231ps	%ymm13, %ymm14, %ymm0   # ymm0 = (ymm14 * ymm13) + ymm0
	vfmadd231ps	%ymm12, %ymm13, %ymm1   # ymm1 = (ymm13 * ymm12) + ymm1
	vmovshdup	-128(%rsp), %xmm13      # 16-byte Folded Reload
                                        # xmm13 = mem[1,1,3,3]
	vbroadcastss	%xmm13, %ymm13
	vfmadd231ps	%ymm12, %ymm13, %ymm3   # ymm3 = (ymm13 * ymm12) + ymm3
	vfmadd231ps	%ymm13, %ymm14, %ymm2   # ymm2 = (ymm14 * ymm13) + ymm2
	vmovshdup	-96(%rsp), %xmm13       # 16-byte Folded Reload
                                        # xmm13 = mem[1,1,3,3]
	vbroadcastss	%xmm13, %ymm13
	vfmadd231ps	%ymm12, %ymm13, %ymm5   # ymm5 = (ymm13 * ymm12) + ymm5
	vfmadd231ps	%ymm13, %ymm14, %ymm4   # ymm4 = (ymm14 * ymm13) + ymm4
	vmovshdup	208(%rsp), %xmm13       # 16-byte Folded Reload
                                        # xmm13 = mem[1,1,3,3]
	vbroadcastss	%xmm13, %ymm13
	vfmadd231ps	%ymm12, %ymm13, %ymm7   # ymm7 = (ymm13 * ymm12) + ymm7
	vfmadd231ps	%ymm13, %ymm14, %ymm6   # ymm6 = (ymm14 * ymm13) + ymm6
	vmovshdup	240(%rsp), %xmm13       # 16-byte Folded Reload
                                        # xmm13 = mem[1,1,3,3]
	vbroadcastss	%xmm13, %ymm13
	vfmadd231ps	%ymm12, %ymm13, %ymm9   # ymm9 = (ymm13 * ymm12) + ymm9
	vfmadd231ps	%ymm13, %ymm14, %ymm8   # ymm8 = (ymm14 * ymm13) + ymm8
	vmovshdup	304(%rsp), %xmm13       # 16-byte Folded Reload
                                        # xmm13 = mem[1,1,3,3]
	vbroadcastss	%xmm13, %ymm13
	vfmadd231ps	%ymm12, %ymm13, %ymm11  # ymm11 = (ymm13 * ymm12) + ymm11
	vfmadd231ps	%ymm14, %ymm13, %ymm10  # ymm10 = (ymm13 * ymm14) + ymm10
	vmovups	32(%rcx,%r14,4), %ymm13
	vmovups	(%rcx,%r14,4), %ymm12
	vaddps	%ymm1, %ymm13, %ymm1
	vaddps	%ymm0, %ymm12, %ymm14
	vaddps	%ymm2, %ymm12, %ymm15
	vaddps	%ymm3, %ymm13, %ymm0
	vaddps	%ymm12, %ymm8, %ymm2
	vaddps	%ymm12, %ymm10, %ymm8
	vxorps	%xmm10, %xmm10, %xmm10
	vaddps	%ymm13, %ymm11, %ymm3
	vaddps	%ymm4, %ymm12, %ymm4
	vaddps	%ymm6, %ymm12, %ymm6
	vaddps	%ymm5, %ymm13, %ymm5
	vaddps	%ymm7, %ymm13, %ymm7
	vaddps	%ymm13, %ymm9, %ymm9
	vmaxps	%ymm10, %ymm1, %ymm12
	vcmpunordps	%ymm1, %ymm1, %ymm11
	vcmpunordps	%ymm5, %ymm5, %ymm13
	vblendvps	%ymm11, %ymm1, %ymm12, %ymm1
	vmaxps	%ymm10, %ymm14, %ymm12
	vcmpunordps	%ymm14, %ymm14, %ymm11
	vblendvps	%ymm11, %ymm14, %ymm12, %ymm14
	vmaxps	%ymm10, %ymm0, %ymm11
	vcmpunordps	%ymm0, %ymm0, %ymm12
	vmovups	%ymm1, 32(%r10,%r14,4)
	vblendvps	%ymm12, %ymm0, %ymm11, %ymm0
	vmaxps	%ymm10, %ymm15, %ymm11
	vcmpunordps	%ymm15, %ymm15, %ymm12
	vmovups	%ymm14, (%r10,%r14,4)
	vblendvps	%ymm12, %ymm15, %ymm11, %ymm11
	vmaxps	%ymm10, %ymm5, %ymm12
	vcmpunordps	%ymm3, %ymm3, %ymm15
	vmovups	%ymm0, 1352(%r10,%r14,4)
	vblendvps	%ymm13, %ymm5, %ymm12, %ymm5
	vmaxps	%ymm10, %ymm4, %ymm12
	vcmpunordps	%ymm4, %ymm4, %ymm13
	vmovups	%ymm11, 1320(%r10,%r14,4)
	vblendvps	%ymm13, %ymm4, %ymm12, %ymm4
	vmaxps	%ymm10, %ymm7, %ymm12
	vcmpunordps	%ymm7, %ymm7, %ymm13
	vmovups	%ymm5, 2672(%r10,%r14,4)
	vblendvps	%ymm13, %ymm7, %ymm12, %ymm7
	vmaxps	%ymm10, %ymm6, %ymm12
	vcmpunordps	%ymm6, %ymm6, %ymm13
	vmovups	%ymm4, 2640(%r10,%r14,4)
	vblendvps	%ymm13, %ymm6, %ymm12, %ymm6
	vmaxps	%ymm10, %ymm9, %ymm12
	vcmpunordps	%ymm9, %ymm9, %ymm13
	vmovups	%ymm7, 3992(%r10,%r14,4)
	vblendvps	%ymm13, %ymm9, %ymm12, %ymm9
	vmaxps	%ymm10, %ymm2, %ymm12
	vcmpunordps	%ymm2, %ymm2, %ymm13
	vmovups	%ymm6, 3960(%r10,%r14,4)
	vblendvps	%ymm13, %ymm2, %ymm12, %ymm2
	vmaxps	%ymm10, %ymm3, %ymm12
	vmovups	%ymm9, 5312(%r10,%r14,4)
	vblendvps	%ymm15, %ymm3, %ymm12, %ymm3
	vmaxps	%ymm10, %ymm8, %ymm12
	vcmpunordps	%ymm8, %ymm8, %ymm10
	vmovups	%ymm2, 5280(%r10,%r14,4)
	vblendvps	%ymm10, %ymm8, %ymm12, %ymm8
	vmovups	%ymm3, 6632(%r10,%r14,4)
	vmovups	%ymm8, 6600(%r10,%r14,4)
	leaq	16(%r14), %r14
	jb	.LBB0_2
# %bb.5:                                # %.preheader204.preheader
                                        #   in Loop: Header=BB0_1 Depth=1
	vxorps	%xmm1, %xmm1, %xmm1
	vxorps	%xmm15, %xmm15, %xmm15
	vxorps	%xmm0, %xmm0, %xmm0
	vxorps	%xmm11, %xmm11, %xmm11
	movq	$-4, %rbx
	movq	%r8, %r14
	vxorps	%xmm7, %xmm7, %xmm7
	vxorps	%xmm13, %xmm13, %xmm13
	vxorps	%xmm6, %xmm6, %xmm6
	vxorps	%xmm9, %xmm9, %xmm9
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm2, %xmm2, %xmm2
	vxorps	%xmm4, %xmm4, %xmm4
	vxorps	%xmm8, %xmm8, %xmm8
	vxorps	%xmm14, %xmm14, %xmm14
	vxorps	%xmm3, %xmm3, %xmm3
	vxorps	%xmm10, %xmm10, %xmm10
	vmovaps	%xmm1, 576(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 608(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 640(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 416(%rsp)                # 16-byte Spill
	vxorps	%xmm1, %xmm1, %xmm1
	vmovaps	%xmm15, 160(%rsp)               # 16-byte Spill
	vxorps	%xmm15, %xmm15, %xmm15
	vmovaps	%xmm0, 384(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 176(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 272(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -64(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 304(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 208(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 240(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -128(%rsp)               # 16-byte Spill
	vmovaps	%xmm0, 496(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 528(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 560(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -48(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 480(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 512(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 544(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 592(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 624(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 656(%rsp)                # 16-byte Spill
	vmovups	%ymm1, -96(%rsp)                # 32-byte Spill
	vxorps	%xmm1, %xmm1, %xmm1
	vmovaps	%xmm1, 352(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 688(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 720(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 336(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 672(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 704(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 736(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 432(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, -16(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 16(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, 48(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, -32(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, (%rsp)                   # 16-byte Spill
	vmovaps	%xmm1, 32(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, 448(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 80(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, 112(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 144(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 64(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, 96(%rsp)                 # 16-byte Spill
	vmovaps	%xmm1, 128(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 464(%rsp)                # 16-byte Spill
	.p2align	4
.LBB0_6:                                # %.preheader204
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovaps	-64(%rsp), %xmm1                # 16-byte Reload
	vinsertps	$16, 304(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0],mem[0],xmm1[2,3]
	vinsertps	$32, 208(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 240(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vinsertps	$16, 576(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[2,3]
	vinsertps	$16, 352(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0],mem[0],xmm6[2,3]
	vinsertps	$32, 608(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$16, -128(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0],mem[0],xmm7[2,3]
	vinsertps	$16, 432(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0],mem[0],xmm4[2,3]
	vinsertps	$16, 464(%rsp), %xmm15, %xmm15 # 16-byte Folded Reload
                                        # xmm15 = xmm15[0],mem[0],xmm15[2,3]
	vinsertps	$16, 416(%rsp), %xmm5, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm5[0],mem[0],xmm5[2,3]
	vinsertps	$16, 448(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0],mem[0],xmm3[2,3]
	vmovaps	%xmm1, 352(%rsp)                # 16-byte Spill
	vinsertps	$16, 384(%rsp), %xmm11, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm11[0],mem[0],xmm11[2,3]
	vinsertps	$48, 640(%rsp), %xmm0, %xmm11 # 16-byte Folded Reload
                                        # xmm11 = xmm0[0,1,2],mem[0]
	vinsertps	$16, 592(%rsp), %xmm9, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm9[0],mem[0],xmm9[2,3]
	vinsertps	$32, 624(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 656(%rsp), %xmm0, %xmm9 # 16-byte Folded Reload
                                        # xmm9 = xmm0[0,1,2],mem[0]
	vinsertps	$16, 672(%rsp), %xmm2, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm2[0],mem[0],xmm2[2,3]
	vinsertps	$32, 704(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 736(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vinsertps	$32, 176(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 272(%rsp), %xmm1, %xmm12 # 16-byte Folded Reload
                                        # xmm12 = xmm1[0,1,2],mem[0]
	vmovaps	-48(%rsp), %xmm1                # 16-byte Reload
	vinsertps	$16, 480(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0],mem[0],xmm1[2,3]
	vinsertps	$32, 512(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 544(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovups	%ymm7, -128(%rsp)               # 32-byte Spill
	vmovaps	%ymm5, %ymm7
	vmovaps	%ymm3, %ymm5
	vmovups	-3960(%r14), %ymm2
	vmovaps	%xmm0, 208(%rsp)                # 16-byte Spill
	vmovups	-96(%rsp), %ymm0                # 32-byte Reload
	vinsertps	$16, 688(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[2,3]
	vinsertps	$32, 720(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 336(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vmovaps	%xmm1, 304(%rsp)                # 16-byte Spill
	vinsertps	$16, 496(%rsp), %xmm13, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm13[0],mem[0],xmm13[2,3]
	vinsertps	$32, 528(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 560(%rsp), %xmm1, %xmm13 # 16-byte Folded Reload
                                        # xmm13 = xmm1[0,1,2],mem[0]
	vinsertf128	$1, 352(%rsp), %ymm12, %ymm3 # 16-byte Folded Reload
	vinsertf128	$1, %xmm11, %ymm9, %ymm12
	vmovups	%ymm0, -96(%rsp)                # 32-byte Spill
	vinsertps	$16, -32(%rsp), %xmm14, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm14[0],mem[0],xmm14[2,3]
	vinsertps	$32, (%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 32(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vmovsd	-3928(%r14), %xmm14             # xmm14 = mem[0],zero
	vinsertf128	$1, 304(%rsp), %ymm13, %ymm13 # 16-byte Folded Reload
	vmovups	-96(%rsp), %ymm9                # 32-byte Reload
	vmovaps	%xmm0, 176(%rsp)                # 16-byte Spill
	vinsertps	$16, -16(%rsp), %xmm8, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm8[0],mem[0],xmm8[2,3]
	vinsertps	$32, 16(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 48(%rsp), %xmm0, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm0[0,1,2],mem[0]
	vmovaps	144(%rsp), %xmm0                # 16-byte Reload
	vinsertps	$16, 64(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[2,3]
	vinsertps	$32, 96(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 128(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vmovups	-128(%rsp), %ymm8               # 32-byte Reload
	vinsertf128	$1, 208(%rsp), %ymm9, %ymm9 # 16-byte Folded Reload
	vmovaps	%xmm0, 240(%rsp)                # 16-byte Spill
	vinsertps	$16, 80(%rsp), %xmm10, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm10[0],mem[0],xmm10[2,3]
	vmovaps	%ymm6, %ymm10
	vmovaps	%ymm4, %ymm6
	vmovaps	%ymm15, %ymm4
	vbroadcastss	-3384(%rdi,%rbx,4), %ymm15
	vinsertps	$32, 112(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 160(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vfmadd231ps	%ymm14, %ymm15, %ymm8   # ymm8 = (ymm15 * ymm14) + ymm8
	vfmadd231ps	%ymm15, %ymm2, %ymm3    # ymm3 = (ymm2 * ymm15) + ymm3
	vbroadcastss	-2704(%rdi,%rbx,4), %ymm15
	vmovups	%ymm0, 272(%rsp)                # 32-byte Spill
	vmovsd	-2608(%r14), %xmm0              # xmm0 = mem[0],zero
	vmovups	%ymm8, -128(%rsp)               # 32-byte Spill
	vinsertf128	$1, 176(%rsp), %ymm1, %ymm8 # 16-byte Folded Reload
	vbroadcastss	-1344(%rdi,%rbx,4), %ymm1
	vmovups	-128(%rsp), %ymm11              # 32-byte Reload
	vfmadd231ps	%ymm14, %ymm15, %ymm10  # ymm10 = (ymm15 * ymm14) + ymm10
	vfmadd231ps	%ymm15, %ymm2, %ymm13   # ymm13 = (ymm2 * ymm15) + ymm13
	vbroadcastss	-2024(%rdi,%rbx,4), %ymm15
	vfmadd231ps	%ymm1, %ymm2, %ymm9     # ymm9 = (ymm2 * ymm1) + ymm9
	vfmadd231ps	%ymm14, %ymm1, %ymm6    # ymm6 = (ymm1 * ymm14) + ymm6
	vbroadcastss	-664(%rdi,%rbx,4), %ymm1
	vfmadd231ps	%ymm14, %ymm15, %ymm7   # ymm7 = (ymm15 * ymm14) + ymm7
	vfmadd231ps	%ymm15, %ymm2, %ymm12   # ymm12 = (ymm2 * ymm15) + ymm12
	vbroadcastss	16(%rdi,%rbx,4), %ymm15
	vmovups	%ymm9, -96(%rsp)                # 32-byte Spill
	vmovups	272(%rsp), %ymm9                # 32-byte Reload
	vfmadd231ps	%ymm14, %ymm1, %ymm5    # ymm5 = (ymm1 * ymm14) + ymm5
	vfmadd231ps	%ymm1, %ymm2, %ymm8     # ymm8 = (ymm2 * ymm1) + ymm8
	vmovups	-2640(%r14), %ymm1
	vfmadd231ps	%ymm14, %ymm15, %ymm4   # ymm4 = (ymm15 * ymm14) + ymm4
	vmovups	-1320(%r14), %ymm14
	vinsertf128	$1, 240(%rsp), %ymm9, %ymm9 # 16-byte Folded Reload
	vfmadd231ps	%ymm2, %ymm15, %ymm9    # ymm9 = (ymm15 * ymm2) + ymm9
	vbroadcastss	-3380(%rdi,%rbx,4), %ymm2
	vbroadcastss	20(%rdi,%rbx,4), %ymm15
	vfmadd231ps	%ymm0, %ymm2, %ymm11    # ymm11 = (ymm2 * ymm0) + ymm11
	vfmadd231ps	%ymm2, %ymm1, %ymm3     # ymm3 = (ymm1 * ymm2) + ymm3
	vbroadcastss	-2700(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm0, %ymm15, %ymm4    # ymm4 = (ymm15 * ymm0) + ymm4
	vfmadd231ps	%ymm1, %ymm15, %ymm9    # ymm9 = (ymm15 * ymm1) + ymm9
	vbroadcastss	24(%rdi,%rbx,4), %ymm15
	vmovups	%ymm11, -128(%rsp)              # 32-byte Spill
	vmovups	-96(%rsp), %ymm11               # 32-byte Reload
	vfmadd231ps	%ymm0, %ymm2, %ymm10    # ymm10 = (ymm2 * ymm0) + ymm10
	vfmadd231ps	%ymm2, %ymm1, %ymm13    # ymm13 = (ymm1 * ymm2) + ymm13
	vbroadcastss	-2020(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm14, %ymm15, %ymm9   # ymm9 = (ymm15 * ymm14) + ymm9
	vfmadd231ps	%ymm0, %ymm2, %ymm7     # ymm7 = (ymm2 * ymm0) + ymm7
	vfmadd231ps	%ymm2, %ymm1, %ymm12    # ymm12 = (ymm1 * ymm2) + ymm12
	vbroadcastss	-1340(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm0, %ymm2, %ymm6     # ymm6 = (ymm2 * ymm0) + ymm6
	vfmadd231ps	%ymm2, %ymm1, %ymm11    # ymm11 = (ymm1 * ymm2) + ymm11
	vbroadcastss	-660(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm0, %ymm2, %ymm5     # ymm5 = (ymm2 * ymm0) + ymm5
	vfmadd231ps	%ymm2, %ymm1, %ymm8     # ymm8 = (ymm1 * ymm2) + ymm8
	vmovsd	-1288(%r14), %xmm2              # xmm2 = mem[0],zero
	vbroadcastss	-3376(%rdi,%rbx,4), %ymm0
	vmovups	-128(%rsp), %ymm1               # 32-byte Reload
	vfmadd231ps	%ymm2, %ymm0, %ymm1     # ymm1 = (ymm0 * ymm2) + ymm1
	vfmadd231ps	%ymm0, %ymm14, %ymm3    # ymm3 = (ymm14 * ymm0) + ymm3
	vbroadcastss	-2696(%rdi,%rbx,4), %ymm0
	vfmadd231ps	%ymm2, %ymm15, %ymm4    # ymm4 = (ymm15 * ymm2) + ymm4
	vmovups	%ymm1, -128(%rsp)               # 32-byte Spill
	vmovups	(%r14), %ymm1
	vmovaps	%ymm4, %ymm15
	vfmadd231ps	%ymm2, %ymm0, %ymm10    # ymm10 = (ymm0 * ymm2) + ymm10
	vfmadd231ps	%ymm0, %ymm14, %ymm13   # ymm13 = (ymm14 * ymm0) + ymm13
	vbroadcastss	-2016(%rdi,%rbx,4), %ymm0
	vfmadd231ps	%ymm2, %ymm0, %ymm7     # ymm7 = (ymm0 * ymm2) + ymm7
	vfmadd231ps	%ymm0, %ymm14, %ymm12   # ymm12 = (ymm14 * ymm0) + ymm12
	vbroadcastss	-1336(%rdi,%rbx,4), %ymm0
	vfmadd231ps	%ymm2, %ymm0, %ymm6     # ymm6 = (ymm0 * ymm2) + ymm6
	vfmadd231ps	%ymm0, %ymm14, %ymm11   # ymm11 = (ymm14 * ymm0) + ymm11
	vbroadcastss	-656(%rdi,%rbx,4), %ymm0
	vmovups	%ymm11, -96(%rsp)               # 32-byte Spill
	vmovaps	%ymm3, %ymm11
	vmovaps	%ymm6, %ymm4
	vmovaps	%ymm10, %ymm6
	vmovaps	%ymm9, %ymm10
	vmovaps	%ymm12, %ymm9
	vfmadd231ps	%ymm2, %ymm0, %ymm5     # ymm5 = (ymm0 * ymm2) + ymm5
	vfmadd231ps	%ymm0, %ymm14, %ymm8    # ymm8 = (ymm14 * ymm0) + ymm8
	vmovsd	32(%r14), %xmm0                 # xmm0 = mem[0],zero
	vbroadcastss	-3372(%rdi,%rbx,4), %ymm2
	addq	$5280, %r14                     # imm = 0x14A0
	vmovaps	%ymm5, %ymm3
	vmovaps	%ymm7, %ymm5
	vmovups	-128(%rsp), %ymm7               # 32-byte Reload
	vfmadd231ps	%ymm2, %ymm1, %ymm11    # ymm11 = (ymm1 * ymm2) + ymm11
	vfmadd231ps	%ymm0, %ymm2, %ymm7     # ymm7 = (ymm2 * ymm0) + ymm7
	vextractf128	$1, %ymm11, %xmm12
	vmovshdup	%xmm12, %xmm14          # xmm14 = xmm12[1,1,3,3]
	vmovaps	%xmm12, -64(%rsp)               # 16-byte Spill
	vmovaps	%xmm14, 304(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm11, %xmm11, %xmm14      # xmm14 = xmm11[1,0]
	vmovapd	%xmm14, 176(%rsp)               # 16-byte Spill
	vmovshdup	%xmm7, %xmm2            # xmm2 = xmm7[1,1,3,3]
	vmovaps	%xmm2, -128(%rsp)               # 16-byte Spill
	vshufps	$255, %xmm12, %xmm12, %xmm2     # xmm2 = xmm12[3,3,3,3]
	vmovaps	%xmm2, 240(%rsp)                # 16-byte Spill
	vbroadcastss	-2692(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm0, %ymm2, %ymm6     # ymm6 = (ymm2 * ymm0) + ymm6
	vfmadd231ps	%ymm2, %ymm1, %ymm13    # ymm13 = (ymm1 * ymm2) + ymm13
	vshufpd	$1, %xmm12, %xmm12, %xmm2       # xmm2 = xmm12[1,0]
	vmovups	-96(%rsp), %ymm12               # 32-byte Reload
	vmovapd	%xmm2, 208(%rsp)                # 16-byte Spill
	vbroadcastss	-2012(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm0, %ymm2, %ymm5     # ymm5 = (ymm2 * ymm0) + ymm5
	vfmadd231ps	%ymm2, %ymm1, %ymm9     # ymm9 = (ymm1 * ymm2) + ymm9
	vbroadcastss	-1332(%rdi,%rbx,4), %ymm2
	vfmadd231ps	%ymm2, %ymm1, %ymm12    # ymm12 = (ymm1 * ymm2) + ymm12
	vfmadd231ps	%ymm0, %ymm2, %ymm4     # ymm4 = (ymm2 * ymm0) + ymm4
	vshufps	$255, %xmm11, %xmm11, %xmm2     # xmm2 = xmm11[3,3,3,3]
	vmovaps	%xmm2, 272(%rsp)                # 16-byte Spill
	vbroadcastss	-652(%rdi,%rbx,4), %ymm2
	vmovups	%ymm12, -96(%rsp)               # 32-byte Spill
	vfmadd231ps	%ymm2, %ymm1, %ymm8     # ymm8 = (ymm1 * ymm2) + ymm8
	vfmadd231ps	%ymm0, %ymm2, %ymm3     # ymm3 = (ymm2 * ymm0) + ymm3
	vbroadcastss	28(%rdi,%rbx,4), %ymm2
	addq	$4, %rbx
	vextractf128	$1, %ymm8, %xmm14
	vfmadd231ps	%ymm0, %ymm2, %ymm15    # ymm15 = (ymm2 * ymm0) + ymm15
	vmovshdup	%xmm11, %xmm0           # xmm0 = xmm11[1,1,3,3]
	vfmadd231ps	%ymm1, %ymm2, %ymm10    # ymm10 = (ymm2 * ymm1) + ymm10
	vextractf128	$1, %ymm12, %xmm2
	vmovaps	%xmm0, 384(%rsp)                # 16-byte Spill
	vmovshdup	%xmm6, %xmm0            # xmm0 = xmm6[1,1,3,3]
	vmovaps	%xmm0, 352(%rsp)                # 16-byte Spill
	vextractf128	$1, %ymm13, %xmm0
	vshufps	$255, %xmm0, %xmm0, %xmm1       # xmm1 = xmm0[3,3,3,3]
	vmovaps	%xmm0, -48(%rsp)                # 16-byte Spill
	vmovaps	%xmm1, 544(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm0, %xmm0, %xmm1         # xmm1 = xmm0[1,0]
	vmovshdup	%xmm0, %xmm0            # xmm0 = xmm0[1,1,3,3]
	vmovaps	%xmm0, 480(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm13, %xmm13, %xmm0     # xmm0 = xmm13[3,3,3,3]
	vmovapd	%xmm1, 512(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 560(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm13, %xmm13, %xmm0       # xmm0 = xmm13[1,0]
	vmovapd	%xmm0, 528(%rsp)                # 16-byte Spill
	vmovshdup	%xmm13, %xmm0           # xmm0 = xmm13[1,1,3,3]
	vmovaps	%xmm0, 496(%rsp)                # 16-byte Spill
	vmovshdup	%xmm5, %xmm0            # xmm0 = xmm5[1,1,3,3]
	vmovaps	%xmm0, 416(%rsp)                # 16-byte Spill
	vextractf128	$1, %ymm9, %xmm0
	vshufps	$255, %xmm0, %xmm0, %xmm1       # xmm1 = xmm0[3,3,3,3]
	vmovaps	%xmm1, 640(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm0, %xmm0, %xmm1         # xmm1 = xmm0[1,0]
	vmovapd	%xmm1, 608(%rsp)                # 16-byte Spill
	vmovshdup	%xmm0, %xmm1            # xmm1 = xmm0[1,1,3,3]
	vmovaps	%xmm1, 576(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm9, %xmm9, %xmm1       # xmm1 = xmm9[3,3,3,3]
	vmovaps	%xmm1, 656(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm9, %xmm9, %xmm1         # xmm1 = xmm9[1,0]
	vmovapd	%xmm1, 624(%rsp)                # 16-byte Spill
	vmovshdup	%xmm9, %xmm1            # xmm1 = xmm9[1,1,3,3]
	vmovaps	%xmm1, 592(%rsp)                # 16-byte Spill
	vmovshdup	%xmm4, %xmm1            # xmm1 = xmm4[1,1,3,3]
	vmovaps	%xmm1, 432(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm2, %xmm2, %xmm1       # xmm1 = xmm2[3,3,3,3]
	vmovaps	%xmm1, 736(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm2, %xmm2, %xmm1         # xmm1 = xmm2[1,0]
	vmovapd	%xmm1, 704(%rsp)                # 16-byte Spill
	vmovshdup	%xmm2, %xmm1            # xmm1 = xmm2[1,1,3,3]
	vmovaps	%xmm1, 672(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm12, %xmm12, %xmm1     # xmm1 = xmm12[3,3,3,3]
	vmovaps	%xmm1, 336(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm12, %xmm12, %xmm1       # xmm1 = xmm12[1,0]
	vmovapd	%xmm1, 720(%rsp)                # 16-byte Spill
	vmovshdup	%xmm12, %xmm1           # xmm1 = xmm12[1,1,3,3]
	vmovaps	%xmm1, 688(%rsp)                # 16-byte Spill
	vmovshdup	%xmm3, %xmm1            # xmm1 = xmm3[1,1,3,3]
	vmovaps	%xmm1, 448(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm14, %xmm14, %xmm1     # xmm1 = xmm14[3,3,3,3]
	vmovaps	%xmm1, 32(%rsp)                 # 16-byte Spill
	vshufpd	$1, %xmm14, %xmm14, %xmm1       # xmm1 = xmm14[1,0]
	vmovapd	%xmm1, (%rsp)                   # 16-byte Spill
	vmovshdup	%xmm14, %xmm1           # xmm1 = xmm14[1,1,3,3]
	vmovaps	%xmm1, -32(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm8, %xmm8, %xmm1       # xmm1 = xmm8[3,3,3,3]
	vmovaps	%xmm1, 48(%rsp)                 # 16-byte Spill
	vshufpd	$1, %xmm8, %xmm8, %xmm1         # xmm1 = xmm8[1,0]
	vmovapd	%xmm1, 16(%rsp)                 # 16-byte Spill
	vmovshdup	%xmm8, %xmm1            # xmm1 = xmm8[1,1,3,3]
	vmovaps	%xmm1, -16(%rsp)                # 16-byte Spill
	vmovshdup	%xmm15, %xmm1           # xmm1 = xmm15[1,1,3,3]
	vmovaps	%xmm1, 464(%rsp)                # 16-byte Spill
	vextractf128	$1, %ymm10, %xmm1
	vshufps	$255, %xmm1, %xmm1, %xmm12      # xmm12 = xmm1[3,3,3,3]
	vmovaps	%xmm1, 144(%rsp)                # 16-byte Spill
	vmovaps	%xmm12, 128(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm1, %xmm1, %xmm12        # xmm12 = xmm1[1,0]
	vmovshdup	%xmm1, %xmm1            # xmm1 = xmm1[1,1,3,3]
	vmovaps	%xmm1, 64(%rsp)                 # 16-byte Spill
	vshufps	$255, %xmm10, %xmm10, %xmm1     # xmm1 = xmm10[3,3,3,3]
	vmovapd	%xmm12, 96(%rsp)                # 16-byte Spill
	vmovshdup	%xmm10, %xmm12          # xmm12 = xmm10[1,1,3,3]
	vmovaps	%xmm1, 160(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm10, %xmm10, %xmm1       # xmm1 = xmm10[1,0]
	vmovaps	%xmm12, 80(%rsp)                # 16-byte Spill
	vmovapd	%xmm1, 112(%rsp)                # 16-byte Spill
	cmpq	$164, %rbx
	jb	.LBB0_6
# %bb.7:                                # %.preheader203
                                        #   in Loop: Header=BB0_1 Depth=1
	vinsertps	$16, 384(%rsp), %xmm11, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm11[0],mem[0],xmm11[2,3]
	vinsertps	$32, 176(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 272(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vinsertps	$16, -128(%rsp), %xmm7, %xmm12 # 16-byte Folded Reload
                                        # xmm12 = xmm7[0],mem[0],xmm7[2,3]
	vinsertps	$16, 576(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[2,3]
	vinsertps	$32, 608(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 640(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vinsertps	$16, 416(%rsp), %xmm5, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm5[0],mem[0],xmm5[2,3]
	vinsertps	$16, 432(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0],mem[0],xmm4[2,3]
	addq	$4080, %rdi                     # imm = 0xFF0
	vmovups	%ymm1, -128(%rsp)               # 32-byte Spill
	vmovaps	-64(%rsp), %xmm1                # 16-byte Reload
	vinsertps	$16, 304(%rsp), %xmm1, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm1[0],mem[0],xmm1[2,3]
	vmovsd	672(%rsi,%r11), %xmm1           # xmm1 = mem[0],zero
	vinsertps	$32, 208(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0,1],mem[0],xmm7[3]
	vinsertps	$48, 240(%rsp), %xmm7, %xmm11 # 16-byte Folded Reload
                                        # xmm11 = xmm7[0,1,2],mem[0]
	vmovsd	223072(%rdx), %xmm7             # xmm7 = mem[0],zero
	vmovaps	%xmm1, 272(%rsp)                # 16-byte Spill
	vbroadcastss	%xmm1, %ymm1
	vmovups	%ymm7, 752(%rsp)                # 32-byte Spill
	vfmadd231ps	%ymm7, %ymm1, %ymm12    # ymm12 = (ymm1 * ymm7) + ymm12
	vmovups	-128(%rsp), %ymm7               # 32-byte Reload
	vmovups	%ymm12, 208(%rsp)               # 32-byte Spill
	vmovups	223040(%rdx), %ymm12
	vinsertf128	$1, %xmm11, %ymm7, %ymm11
	vinsertps	$16, 352(%rsp), %xmm6, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm6[0],mem[0],xmm6[2,3]
	vmovaps	-48(%rsp), %xmm6                # 16-byte Reload
	vinsertps	$16, 480(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0],mem[0],xmm6[2,3]
	vinsertps	$32, 512(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1],mem[0],xmm6[3]
	vinsertps	$48, 544(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1,2],mem[0]
	vfmadd231ps	%ymm1, %ymm12, %ymm11   # ymm11 = (ymm12 * ymm1) + ymm11
	vinsertps	$16, 496(%rsp), %xmm13, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm13[0],mem[0],xmm13[2,3]
	vinsertps	$32, 528(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 560(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovsd	2032(%rsi,%r11), %xmm13         # xmm13 = mem[0],zero
	vmovups	%ymm11, -128(%rsp)              # 32-byte Spill
	vmovups	752(%rsp), %ymm11               # 32-byte Reload
	vinsertf128	$1, %xmm6, %ymm1, %ymm6
	vmovsd	1352(%rsi,%r11), %xmm1          # xmm1 = mem[0],zero
	vmovaps	%xmm1, -48(%rsp)                # 16-byte Spill
	vbroadcastss	%xmm1, %ymm1
	vfmadd231ps	%ymm11, %ymm1, %ymm7    # ymm7 = (ymm1 * ymm11) + ymm7
	vfmadd231ps	%ymm1, %ymm12, %ymm6    # ymm6 = (ymm12 * ymm1) + ymm6
	vinsertps	$16, 592(%rsp), %xmm9, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm9[0],mem[0],xmm9[2,3]
	vinsertps	$32, 624(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 656(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovups	%ymm6, 240(%rsp)                # 32-byte Spill
	vmovsd	3392(%rsi,%r11), %xmm6          # xmm6 = mem[0],zero
	vmovups	%ymm7, 176(%rsp)                # 32-byte Spill
	vmovshdup	272(%rsp), %xmm7        # 16-byte Folded Reload
                                        # xmm7 = mem[1,1,3,3]
	vinsertf128	$1, %xmm0, %ymm1, %ymm1
	vbroadcastss	%xmm13, %ymm0
	vmovshdup	%xmm13, %xmm13          # xmm13 = xmm13[1,1,3,3]
	vfmadd231ps	%ymm0, %ymm12, %ymm1    # ymm1 = (ymm12 * ymm0) + ymm1
	vfmadd231ps	%ymm11, %ymm0, %ymm5    # ymm5 = (ymm0 * ymm11) + ymm5
	vmovups	-96(%rsp), %ymm0                # 32-byte Reload
	vinsertps	$16, 688(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[2,3]
	vinsertps	$32, 720(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 336(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vbroadcastss	%xmm7, %ymm9
	vmovups	%ymm1, 304(%rsp)                # 32-byte Spill
	vinsertps	$16, 672(%rsp), %xmm2, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm2[0],mem[0],xmm2[2,3]
	vinsertps	$32, 704(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 736(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovups	%ymm5, 384(%rsp)                # 32-byte Spill
	vinsertps	$16, 448(%rsp), %xmm3, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm3[0],mem[0],xmm3[2,3]
	vmovaps	144(%rsp), %xmm2                # 16-byte Reload
	vinsertps	$16, 64(%rsp), %xmm2, %xmm2 # 16-byte Folded Reload
                                        # xmm2 = xmm2[0],mem[0],xmm2[2,3]
	vinsertps	$32, 96(%rsp), %xmm2, %xmm2 # 16-byte Folded Reload
                                        # xmm2 = xmm2[0,1],mem[0],xmm2[3]
	vinsertps	$48, 128(%rsp), %xmm2, %xmm2 # 16-byte Folded Reload
                                        # xmm2 = xmm2[0,1,2],mem[0]
	vbroadcastss	%xmm13, %ymm3
	vinsertf128	$1, %xmm1, %ymm0, %ymm1
	vmovsd	2712(%rsi,%r11), %xmm0          # xmm0 = mem[0],zero
	vmovaps	%xmm0, -64(%rsp)                # 16-byte Spill
	vbroadcastss	%xmm0, %ymm0
	vfmadd231ps	%ymm0, %ymm12, %ymm1    # ymm1 = (ymm12 * ymm0) + ymm1
	vfmadd231ps	%ymm11, %ymm0, %ymm4    # ymm4 = (ymm0 * ymm11) + ymm4
	vinsertps	$16, -16(%rsp), %xmm8, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm8[0],mem[0],xmm8[2,3]
	vinsertps	$32, 16(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1],mem[0],xmm0[3]
	vinsertps	$48, 48(%rsp), %xmm0, %xmm0 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0,1,2],mem[0]
	vmovups	%ymm1, -96(%rsp)                # 32-byte Spill
	vinsertps	$16, -32(%rsp), %xmm14, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm14[0],mem[0],xmm14[2,3]
	vinsertps	$32, (%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 32(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovups	%ymm4, 352(%rsp)                # 32-byte Spill
	vinsertps	$16, 464(%rsp), %xmm15, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm15[0],mem[0],xmm15[2,3]
	vinsertf128	$1, %xmm1, %ymm0, %ymm8
	vbroadcastss	%xmm6, %ymm0
	vmovaps	%ymm11, %ymm1
	vmovshdup	%xmm6, %xmm6            # xmm6 = xmm6[1,1,3,3]
	vfmadd231ps	%ymm11, %ymm0, %ymm5    # ymm5 = (ymm0 * ymm11) + ymm5
	vmovsd	4072(%rsi,%r11), %xmm11         # xmm11 = mem[0],zero
	vfmadd231ps	%ymm0, %ymm12, %ymm8    # ymm8 = (ymm12 * ymm0) + ymm8
	vbroadcastss	%xmm11, %ymm0
	vfmadd231ps	%ymm1, %ymm0, %ymm4     # ymm4 = (ymm0 * ymm1) + ymm4
	vinsertps	$16, 80(%rsp), %xmm10, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm10[0],mem[0],xmm10[2,3]
	vinsertps	$32, 112(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1],mem[0],xmm1[3]
	vinsertps	$48, 160(%rsp), %xmm1, %xmm1 # 16-byte Folded Reload
                                        # xmm1 = xmm1[0,1,2],mem[0]
	vmovshdup	-64(%rsp), %xmm10       # 16-byte Folded Reload
                                        # xmm10 = mem[1,1,3,3]
	vinsertf128	$1, %xmm2, %ymm1, %ymm14
	vbroadcastss	%xmm6, %ymm1
	vbroadcastss	%xmm10, %ymm2
	vfmadd231ps	%ymm12, %ymm0, %ymm14   # ymm14 = (ymm0 * ymm12) + ymm14
	vmovsd	224392(%rdx), %xmm0             # xmm0 = mem[0],zero
	vmovshdup	-48(%rsp), %xmm12       # 16-byte Folded Reload
                                        # xmm12 = mem[1,1,3,3]
	vfmadd213ps	208(%rsp), %ymm0, %ymm7 # 32-byte Folded Reload
                                        # ymm7 = (ymm0 * ymm7) + mem
	vfmadd213ps	384(%rsp), %ymm0, %ymm13 # 32-byte Folded Reload
                                        # ymm13 = (ymm0 * ymm13) + mem
	vfmadd213ps	352(%rsp), %ymm0, %ymm10 # 32-byte Folded Reload
                                        # ymm10 = (ymm0 * ymm10) + mem
	vfmadd213ps	%ymm5, %ymm0, %ymm6     # ymm6 = (ymm0 * ymm6) + ymm5
	vmovshdup	%xmm11, %xmm5           # xmm5 = xmm11[1,1,3,3]
	vbroadcastss	%xmm12, %ymm15
	vfmadd213ps	176(%rsp), %ymm0, %ymm12 # 32-byte Folded Reload
                                        # ymm12 = (ymm0 * ymm12) + mem
	vbroadcastss	%xmm5, %ymm11
	vfmadd213ps	%ymm4, %ymm0, %ymm5     # ymm5 = (ymm0 * ymm5) + ymm4
	vmovups	224360(%rdx), %ymm0
	vfmadd213ps	-128(%rsp), %ymm0, %ymm9 # 32-byte Folded Reload
                                        # ymm9 = (ymm0 * ymm9) + mem
	vfmadd213ps	240(%rsp), %ymm0, %ymm15 # 32-byte Folded Reload
                                        # ymm15 = (ymm0 * ymm15) + mem
	vfmadd213ps	304(%rsp), %ymm0, %ymm3 # 32-byte Folded Reload
                                        # ymm3 = (ymm0 * ymm3) + mem
	vfmadd213ps	-96(%rsp), %ymm0, %ymm2 # 32-byte Folded Reload
                                        # ymm2 = (ymm0 * ymm2) + mem
	vmovups	1280(%rcx), %ymm4
	vfmadd213ps	%ymm8, %ymm0, %ymm1     # ymm1 = (ymm0 * ymm1) + ymm8
	vfmadd213ps	%ymm14, %ymm0, %ymm11   # ymm11 = (ymm0 * ymm11) + ymm14
	vmovsd	1312(%rcx), %xmm0               # xmm0 = mem[0],zero
	vaddps	%ymm0, %ymm7, %ymm14
	vaddps	%ymm4, %ymm9, %ymm7
	vaddps	%ymm4, %ymm15, %ymm9
	vaddps	%ymm0, %ymm12, %ymm8
	vaddps	%ymm0, %ymm13, %ymm12
	vaddps	%ymm4, %ymm3, %ymm15
	vaddps	%ymm0, %ymm10, %ymm13
	vaddps	%ymm4, %ymm11, %ymm10
	vxorps	%xmm11, %xmm11, %xmm11
	vaddps	%ymm4, %ymm2, %ymm3
	vaddps	%ymm0, %ymm6, %ymm2
	vaddps	%ymm4, %ymm1, %ymm6
	vaddps	%ymm0, %ymm5, %ymm0
	vmaxps	%ymm11, %ymm7, %ymm1
	vcmpunordps	%ymm7, %ymm7, %ymm4
	vcmpunordps	%ymm9, %ymm9, %ymm5
	vblendvps	%ymm4, %ymm7, %ymm1, %ymm1
	vmaxps	%ymm11, %ymm9, %ymm4
	vcmpunordps	%ymm15, %ymm15, %ymm7
	vblendvps	%ymm5, %ymm9, %ymm4, %ymm4
	vmaxps	%ymm11, %ymm15, %ymm5
	vcmpunordps	%ymm3, %ymm3, %ymm9
	vmovups	%ymm1, 1280(%r10)
	vblendvps	%ymm7, %ymm15, %ymm5, %ymm5
	vmaxps	%ymm11, %ymm3, %ymm7
	vxorps	%xmm15, %xmm15, %xmm15
	vblendvps	%ymm9, %ymm3, %ymm7, %ymm7
	vmaxps	%ymm11, %ymm6, %ymm3
	vcmpunordps	%ymm6, %ymm6, %ymm9
	vblendvps	%ymm9, %ymm6, %ymm3, %ymm9
	vmaxps	%ymm11, %ymm10, %ymm3
	vcmpunordps	%ymm10, %ymm10, %ymm6
	vblendvps	%ymm6, %ymm10, %ymm3, %ymm11
	vmaxps	%xmm15, %xmm14, %xmm3
	vcmpunordps	%ymm14, %ymm14, %ymm6
	vcmpunordps	%ymm8, %ymm8, %ymm10
	vblendvps	%xmm6, %xmm14, %xmm3, %xmm3
	vmaxps	%xmm15, %xmm8, %xmm6
	vblendvps	%xmm10, %xmm8, %xmm6, %xmm6
	vmaxps	%xmm15, %xmm12, %xmm8
	vcmpunordps	%ymm12, %ymm12, %ymm10
	vmovlps	%xmm3, 1312(%r10)
	vmovups	%ymm4, 2600(%r10)
	vblendvps	%xmm10, %xmm12, %xmm8, %xmm8
	vmaxps	%xmm15, %xmm13, %xmm10
	vcmpunordps	%ymm13, %ymm13, %ymm12
	vmovlps	%xmm6, 2632(%r10)
	vmovups	%ymm5, 3920(%r10)
	vblendvps	%xmm12, %xmm13, %xmm10, %xmm10
	vmaxps	%xmm15, %xmm2, %xmm12
	vcmpunordps	%ymm2, %ymm2, %ymm13
	vmovlps	%xmm8, 3952(%r10)
	vmovups	%ymm7, 5240(%r10)
	vblendvps	%xmm13, %xmm2, %xmm12, %xmm2
	vmaxps	%xmm15, %xmm0, %xmm12
	vcmpunordps	%ymm0, %ymm0, %ymm13
	vmovlps	%xmm10, 5272(%r10)
	vmovups	%ymm9, 6560(%r10)
	vblendvps	%xmm13, %xmm0, %xmm12, %xmm0
	vmovlps	%xmm2, 6592(%r10)
	vmovups	%ymm11, 7880(%r10)
	vmovlps	%xmm0, 7912(%r10)
	cmpq	$240, %r9
	leaq	6(%r9), %r9
	jb	.LBB0_1
# %bb.8:                                # %.preheader201
	xorl	%edi, %edi
	vxorps	%xmm0, %xmm0, %xmm0
	movq	%rdx, %r8
	.p2align	4
.LBB0_9:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_10 Depth 2
	movq	$-4, %r9
	movq	%r8, %r10
	vxorps	%xmm1, %xmm1, %xmm1
	vxorps	%xmm2, %xmm2, %xmm2
	vxorps	%xmm3, %xmm3, %xmm3
	vxorps	%xmm4, %xmm4, %xmm4
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm6, %xmm6, %xmm6
	vxorps	%xmm7, %xmm7, %xmm7
	vxorps	%xmm8, %xmm8, %xmm8
	.p2align	4
.LBB0_10:                               #   Parent Loop BB0_9 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovups	(%r10), %ymm9
	vbroadcastss	167976(%rsi,%r9,4), %ymm12
	vmovups	32(%r10), %ymm11
	vbroadcastss	167296(%rsi,%r9,4), %ymm10
	vbroadcastss	168656(%rsi,%r9,4), %ymm13
	vfmadd231ps	%ymm11, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm11) + ymm4
	vfmadd231ps	%ymm12, %ymm9, %ymm3    # ymm3 = (ymm9 * ymm12) + ymm3
	vbroadcastss	169336(%rsi,%r9,4), %ymm12
	vfmadd231ps	%ymm9, %ymm10, %ymm1    # ymm1 = (ymm10 * ymm9) + ymm1
	vfmadd231ps	%ymm10, %ymm11, %ymm2   # ymm2 = (ymm11 * ymm10) + ymm2
	vfmadd231ps	%ymm11, %ymm13, %ymm6   # ymm6 = (ymm13 * ymm11) + ymm6
	vfmadd231ps	%ymm13, %ymm9, %ymm5    # ymm5 = (ymm9 * ymm13) + ymm5
	vbroadcastss	167300(%rsi,%r9,4), %ymm13
	vfmadd231ps	%ymm11, %ymm12, %ymm8   # ymm8 = (ymm12 * ymm11) + ymm8
	vfmadd231ps	%ymm9, %ymm12, %ymm7    # ymm7 = (ymm12 * ymm9) + ymm7
	vmovups	1352(%r10), %ymm9
	vmovups	1320(%r10), %ymm11
	vbroadcastss	167980(%rsi,%r9,4), %ymm12
	vfmadd231ps	%ymm9, %ymm13, %ymm2    # ymm2 = (ymm13 * ymm9) + ymm2
	vfmadd231ps	%ymm13, %ymm11, %ymm1   # ymm1 = (ymm11 * ymm13) + ymm1
	vbroadcastss	168660(%rsi,%r9,4), %ymm13
	vfmadd231ps	%ymm11, %ymm12, %ymm3   # ymm3 = (ymm12 * ymm11) + ymm3
	vfmadd231ps	%ymm12, %ymm9, %ymm4    # ymm4 = (ymm9 * ymm12) + ymm4
	vbroadcastss	169340(%rsi,%r9,4), %ymm12
	vfmadd231ps	%ymm11, %ymm13, %ymm5   # ymm5 = (ymm13 * ymm11) + ymm5
	vfmadd231ps	%ymm13, %ymm9, %ymm6    # ymm6 = (ymm9 * ymm13) + ymm6
	vfmadd231ps	%ymm11, %ymm12, %ymm7   # ymm7 = (ymm12 * ymm11) + ymm7
	vfmadd231ps	%ymm9, %ymm12, %ymm8    # ymm8 = (ymm12 * ymm9) + ymm8
	vmovups	2640(%r10), %ymm9
	vbroadcastss	167304(%rsi,%r9,4), %ymm13
	vmovups	2672(%r10), %ymm11
	vbroadcastss	167984(%rsi,%r9,4), %ymm12
	vfmadd231ps	%ymm9, %ymm13, %ymm1    # ymm1 = (ymm13 * ymm9) + ymm1
	vfmadd231ps	%ymm13, %ymm11, %ymm2   # ymm2 = (ymm11 * ymm13) + ymm2
	vbroadcastss	168664(%rsi,%r9,4), %ymm13
	vfmadd231ps	%ymm11, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm11) + ymm4
	vfmadd231ps	%ymm12, %ymm9, %ymm3    # ymm3 = (ymm9 * ymm12) + ymm3
	vbroadcastss	169344(%rsi,%r9,4), %ymm12
	vfmadd231ps	%ymm11, %ymm13, %ymm6   # ymm6 = (ymm13 * ymm11) + ymm6
	vfmadd231ps	%ymm13, %ymm9, %ymm5    # ymm5 = (ymm9 * ymm13) + ymm5
	vfmadd231ps	%ymm11, %ymm12, %ymm8   # ymm8 = (ymm12 * ymm11) + ymm8
	vfmadd231ps	%ymm9, %ymm12, %ymm7    # ymm7 = (ymm12 * ymm9) + ymm7
	vmovups	3992(%r10), %ymm9
	vbroadcastss	167308(%rsi,%r9,4), %ymm13
	vmovups	3960(%r10), %ymm11
	vbroadcastss	167988(%rsi,%r9,4), %ymm12
	addq	$5280, %r10                     # imm = 0x14A0
	vfmadd231ps	%ymm9, %ymm13, %ymm2    # ymm2 = (ymm13 * ymm9) + ymm2
	vfmadd231ps	%ymm13, %ymm11, %ymm1   # ymm1 = (ymm11 * ymm13) + ymm1
	vbroadcastss	168668(%rsi,%r9,4), %ymm13
	vfmadd231ps	%ymm11, %ymm12, %ymm3   # ymm3 = (ymm12 * ymm11) + ymm3
	vfmadd231ps	%ymm12, %ymm9, %ymm4    # ymm4 = (ymm9 * ymm12) + ymm4
	vbroadcastss	169348(%rsi,%r9,4), %ymm12
	addq	$4, %r9
	vfmadd231ps	%ymm11, %ymm13, %ymm5   # ymm5 = (ymm13 * ymm11) + ymm5
	vfmadd231ps	%ymm13, %ymm9, %ymm6    # ymm6 = (ymm9 * ymm13) + ymm6
	vfmadd231ps	%ymm11, %ymm12, %ymm7   # ymm7 = (ymm12 * ymm11) + ymm7
	vfmadd231ps	%ymm9, %ymm12, %ymm8    # ymm8 = (ymm12 * ymm9) + ymm8
	cmpq	$164, %r9
	jb	.LBB0_10
# %bb.11:                               # %.preheader200
                                        #   in Loop: Header=BB0_9 Depth=1
	vmovsd	167952(%rsi), %xmm10            # xmm10 = mem[0],zero
	vmovups	221760(%rdx,%rdi,4), %ymm9
	vmovups	221792(%rdx,%rdi,4), %ymm12
	addq	$64, %r8
	cmpq	$304, %rdi                      # imm = 0x130
	vbroadcastss	%xmm10, %ymm11
	vmovshdup	%xmm10, %xmm10          # xmm10 = xmm10[1,1,3,3]
	vbroadcastss	%xmm10, %ymm10
	vfmadd231ps	%ymm9, %ymm11, %ymm1    # ymm1 = (ymm11 * ymm9) + ymm1
	vfmadd231ps	%ymm11, %ymm12, %ymm2   # ymm2 = (ymm12 * ymm11) + ymm2
	vmovsd	168632(%rsi), %xmm11            # xmm11 = mem[0],zero
	vbroadcastss	%xmm11, %ymm13
	vfmadd231ps	%ymm9, %ymm13, %ymm3    # ymm3 = (ymm13 * ymm9) + ymm3
	vfmadd231ps	%ymm13, %ymm12, %ymm4   # ymm4 = (ymm12 * ymm13) + ymm4
	vmovsd	169312(%rsi), %xmm13            # xmm13 = mem[0],zero
	vbroadcastss	%xmm13, %ymm14
	vfmadd231ps	%ymm9, %ymm14, %ymm5    # ymm5 = (ymm14 * ymm9) + ymm5
	vfmadd231ps	%ymm14, %ymm12, %ymm6   # ymm6 = (ymm12 * ymm14) + ymm6
	vmovsd	169992(%rsi), %xmm14            # xmm14 = mem[0],zero
	vbroadcastss	%xmm14, %ymm15
	vfmadd231ps	%ymm9, %ymm15, %ymm7    # ymm7 = (ymm15 * ymm9) + ymm7
	vfmadd231ps	%ymm12, %ymm15, %ymm8   # ymm8 = (ymm15 * ymm12) + ymm8
	vmovups	223112(%rdx,%rdi,4), %ymm9
	vmovups	223080(%rdx,%rdi,4), %ymm12
	vfmadd231ps	%ymm9, %ymm10, %ymm2    # ymm2 = (ymm10 * ymm9) + ymm2
	vfmadd231ps	%ymm10, %ymm12, %ymm1   # ymm1 = (ymm12 * ymm10) + ymm1
	vmovshdup	%xmm11, %xmm10          # xmm10 = xmm11[1,1,3,3]
	vbroadcastss	%xmm10, %ymm10
	vfmadd231ps	%ymm9, %ymm10, %ymm4    # ymm4 = (ymm10 * ymm9) + ymm4
	vfmadd231ps	%ymm10, %ymm12, %ymm3   # ymm3 = (ymm12 * ymm10) + ymm3
	vmovshdup	%xmm13, %xmm10          # xmm10 = xmm13[1,1,3,3]
	vbroadcastss	%xmm10, %ymm10
	vfmadd231ps	%ymm9, %ymm10, %ymm6    # ymm6 = (ymm10 * ymm9) + ymm6
	vfmadd231ps	%ymm10, %ymm12, %ymm5   # ymm5 = (ymm12 * ymm10) + ymm5
	vmovshdup	%xmm14, %xmm10          # xmm10 = xmm14[1,1,3,3]
	vbroadcastss	%xmm10, %ymm10
	vfmadd231ps	%ymm9, %ymm10, %ymm8    # ymm8 = (ymm10 * ymm9) + ymm8
	vfmadd231ps	%ymm12, %ymm10, %ymm7   # ymm7 = (ymm10 * ymm12) + ymm7
	vmovups	32(%rcx,%rdi,4), %ymm10
	vmovups	(%rcx,%rdi,4), %ymm9
	vaddps	%ymm2, %ymm10, %ymm2
	vaddps	%ymm1, %ymm9, %ymm1
	vaddps	%ymm4, %ymm10, %ymm4
	vaddps	%ymm3, %ymm9, %ymm3
	vaddps	%ymm5, %ymm9, %ymm5
	vaddps	%ymm7, %ymm9, %ymm7
	vaddps	%ymm6, %ymm10, %ymm6
	vaddps	%ymm10, %ymm8, %ymm8
	vmaxps	%ymm0, %ymm2, %ymm9
	vcmpunordps	%ymm2, %ymm2, %ymm10
	vcmpunordps	%ymm1, %ymm1, %ymm11
	vcmpunordps	%ymm4, %ymm4, %ymm12
	vblendvps	%ymm10, %ymm2, %ymm9, %ymm2
	vmaxps	%ymm0, %ymm1, %ymm9
	vblendvps	%ymm11, %ymm1, %ymm9, %ymm1
	vmaxps	%ymm0, %ymm4, %ymm9
	vcmpunordps	%ymm3, %ymm3, %ymm11
	vmovups	%ymm2, 324752(%rax,%rdi,4)
	vblendvps	%ymm12, %ymm4, %ymm9, %ymm4
	vmaxps	%ymm0, %ymm3, %ymm9
	vcmpunordps	%ymm6, %ymm6, %ymm12
	vmovups	%ymm1, 324720(%rax,%rdi,4)
	vblendvps	%ymm11, %ymm3, %ymm9, %ymm3
	vmaxps	%ymm0, %ymm6, %ymm9
	vcmpunordps	%ymm5, %ymm5, %ymm11
	vmovups	%ymm4, 326072(%rax,%rdi,4)
	vblendvps	%ymm12, %ymm6, %ymm9, %ymm6
	vmaxps	%ymm0, %ymm5, %ymm9
	vcmpunordps	%ymm8, %ymm8, %ymm12
	vmovups	%ymm3, 326040(%rax,%rdi,4)
	vblendvps	%ymm11, %ymm5, %ymm9, %ymm5
	vmaxps	%ymm0, %ymm8, %ymm9
	vcmpunordps	%ymm7, %ymm7, %ymm11
	vmovups	%ymm6, 327392(%rax,%rdi,4)
	vblendvps	%ymm12, %ymm8, %ymm9, %ymm8
	vmaxps	%ymm0, %ymm7, %ymm9
	vmovups	%ymm5, 327360(%rax,%rdi,4)
	vblendvps	%ymm11, %ymm7, %ymm9, %ymm7
	vmovups	%ymm8, 328712(%rax,%rdi,4)
	vmovups	%ymm7, 328680(%rax,%rdi,4)
	leaq	16(%rdi), %rdi
	jb	.LBB0_9
# %bb.12:                               # %.preheader199.preheader
	vxorps	%xmm0, %xmm0, %xmm0
	leaq	5240(%rdx), %rdi
	vxorps	%xmm7, %xmm7, %xmm7
	movq	$-4, %r8
	vxorps	%xmm8, %xmm8, %xmm8
	vxorps	%xmm4, %xmm4, %xmm4
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm15, %xmm15, %xmm15
	vxorps	%xmm11, %xmm11, %xmm11
	vxorps	%xmm14, %xmm14, %xmm14
	vxorps	%xmm2, %xmm2, %xmm2
	vxorps	%xmm6, %xmm6, %xmm6
	vxorps	%xmm10, %xmm10, %xmm10
	vxorps	%xmm1, %xmm1, %xmm1
	vxorps	%xmm13, %xmm13, %xmm13
	vxorps	%xmm3, %xmm3, %xmm3
	vxorps	%xmm9, %xmm9, %xmm9
	vxorps	%xmm12, %xmm12, %xmm12
	vmovaps	%xmm0, 272(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 240(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -128(%rsp)               # 16-byte Spill
	vmovaps	%xmm0, 304(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 208(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -96(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 176(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -16(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -32(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 384(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -48(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 160(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 16(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, 48(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, 80(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, (%rsp)                   # 16-byte Spill
	vmovaps	%xmm0, 32(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, 64(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, 96(%rsp)                 # 16-byte Spill
	vmovaps	%xmm0, 128(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 352(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, -64(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 112(%rsp)                # 16-byte Spill
	vmovaps	%xmm0, 144(%rsp)                # 16-byte Spill
	vxorps	%xmm0, %xmm0, %xmm0
	.p2align	4
.LBB0_13:                               # %.preheader199
                                        # =>This Inner Loop Header: Depth=1
	vinsertps	$16, -16(%rsp), %xmm5, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm5[0],mem[0],xmm5[2,3]
	vinsertps	$16, 304(%rsp), %xmm8, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm8[0],mem[0],xmm8[2,3]
	vinsertps	$16, 272(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0],mem[0],xmm7[2,3]
	vinsertps	$32, 240(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0,1],mem[0],xmm7[3]
	vinsertps	$16, 16(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0],mem[0],xmm6[2,3]
	vinsertps	$32, 48(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1],mem[0],xmm6[3]
	vinsertps	$16, -64(%rsp), %xmm9, %xmm9 # 16-byte Folded Reload
                                        # xmm9 = xmm9[0],mem[0],xmm9[2,3]
	vinsertps	$16, 96(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0],mem[0],xmm3[2,3]
	vinsertps	$32, 128(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0,1],mem[0],xmm3[3]
	vinsertps	$16, %xmm13, %xmm1, %xmm1 # xmm1 = xmm1[0],xmm13[0],xmm1[2,3]
	vinsertps	$16, %xmm12, %xmm0, %xmm0 # xmm0 = xmm0[0],xmm12[0],xmm0[2,3]
	vinsertps	$32, 208(%rsp), %xmm8, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm8[0,1],mem[0],xmm8[3]
	vinsertps	$48, -96(%rsp), %xmm8, %xmm12 # 16-byte Folded Reload
                                        # xmm12 = xmm8[0,1,2],mem[0]
	vinsertps	$16, -32(%rsp), %xmm14, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm14[0],mem[0],xmm14[2,3]
	vinsertps	$48, -128(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0,1,2],mem[0]
	vinsertps	$32, 384(%rsp), %xmm8, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm8[0,1],mem[0],xmm8[3]
	vinsertps	$48, -48(%rsp), %xmm8, %xmm13 # 16-byte Folded Reload
                                        # xmm13 = xmm8[0,1,2],mem[0]
	vinsertps	$16, (%rsp), %xmm10, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm10[0],mem[0],xmm10[2,3]
	vinsertps	$32, 32(%rsp), %xmm8, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm8[0,1],mem[0],xmm8[3]
	vinsertps	$48, 64(%rsp), %xmm8, %xmm8 # 16-byte Folded Reload
                                        # xmm8 = xmm8[0,1,2],mem[0]
	vinsertps	$48, 80(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1,2],mem[0]
	vinsertps	$32, 112(%rsp), %xmm9, %xmm9 # 16-byte Folded Reload
                                        # xmm9 = xmm9[0,1],mem[0],xmm9[3]
	vinsertps	$48, 352(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0,1,2],mem[0]
	vinsertps	$16, 176(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0],mem[0],xmm4[2,3]
	vinsertps	$16, 160(%rsp), %xmm2, %xmm2 # 16-byte Folded Reload
                                        # xmm2 = xmm2[0],mem[0],xmm2[2,3]
	vmovups	-3960(%rdi), %ymm10
	vbroadcastss	167296(%rsi,%r8,4), %ymm14
	vinsertps	$32, %xmm15, %xmm5, %xmm5 # xmm5 = xmm5[0,1],xmm15[0],xmm5[3]
	vinsertf128	$1, %xmm12, %ymm7, %ymm7
	vinsertf128	$1, %xmm8, %ymm6, %ymm6
	vbroadcastss	167976(%rsi,%r8,4), %ymm12
	vbroadcastss	169336(%rsi,%r8,4), %ymm8
	vinsertps	$48, %xmm11, %xmm5, %xmm5 # xmm5 = xmm5[0,1,2],xmm11[0]
	vinsertps	$48, 144(%rsp), %xmm9, %xmm11 # 16-byte Folded Reload
                                        # xmm11 = xmm9[0,1,2],mem[0]
	vmovsd	-3928(%rdi), %xmm9              # xmm9 = mem[0],zero
	vinsertf128	$1, %xmm13, %ymm5, %ymm5
	vfmadd231ps	%ymm14, %ymm10, %ymm7   # ymm7 = (ymm10 * ymm14) + ymm7
	vfmadd231ps	%ymm12, %ymm10, %ymm5   # ymm5 = (ymm10 * ymm12) + ymm5
	vinsertf128	$1, %xmm11, %ymm3, %ymm3
	vbroadcastss	168656(%rsi,%r8,4), %ymm11
	vfmadd231ps	%ymm9, %ymm14, %ymm4    # ymm4 = (ymm14 * ymm9) + ymm4
	vfmadd231ps	%ymm9, %ymm12, %ymm2    # ymm2 = (ymm12 * ymm9) + ymm2
	vfmadd231ps	%ymm9, %ymm8, %ymm0     # ymm0 = (ymm8 * ymm9) + ymm0
	vfmadd231ps	%ymm10, %ymm8, %ymm3    # ymm3 = (ymm8 * ymm10) + ymm3
	vmovsd	-2608(%rdi), %xmm8              # xmm8 = mem[0],zero
	vfmadd231ps	%ymm9, %ymm11, %ymm1    # ymm1 = (ymm11 * ymm9) + ymm1
	vfmadd231ps	%ymm11, %ymm10, %ymm6   # ymm6 = (ymm10 * ymm11) + ymm6
	vbroadcastss	167300(%rsi,%r8,4), %ymm9
	vmovups	-2640(%rdi), %ymm10
	vbroadcastss	168664(%rsi,%r8,4), %ymm11
	vfmadd231ps	%ymm8, %ymm9, %ymm4     # ymm4 = (ymm9 * ymm8) + ymm4
	vfmadd231ps	%ymm9, %ymm10, %ymm7    # ymm7 = (ymm10 * ymm9) + ymm7
	vbroadcastss	167980(%rsi,%r8,4), %ymm9
	vfmadd231ps	%ymm8, %ymm9, %ymm2     # ymm2 = (ymm9 * ymm8) + ymm2
	vfmadd231ps	%ymm9, %ymm10, %ymm5    # ymm5 = (ymm10 * ymm9) + ymm5
	vbroadcastss	168660(%rsi,%r8,4), %ymm9
	vfmadd231ps	%ymm8, %ymm9, %ymm1     # ymm1 = (ymm9 * ymm8) + ymm1
	vfmadd231ps	%ymm9, %ymm10, %ymm6    # ymm6 = (ymm10 * ymm9) + ymm6
	vbroadcastss	169340(%rsi,%r8,4), %ymm9
	vfmadd231ps	%ymm8, %ymm9, %ymm0     # ymm0 = (ymm9 * ymm8) + ymm0
	vfmadd231ps	%ymm10, %ymm9, %ymm3    # ymm3 = (ymm9 * ymm10) + ymm3
	vmovsd	-1288(%rdi), %xmm8              # xmm8 = mem[0],zero
	vbroadcastss	167304(%rsi,%r8,4), %ymm9
	vmovups	-1320(%rdi), %ymm10
	vfmadd231ps	%ymm8, %ymm9, %ymm4     # ymm4 = (ymm9 * ymm8) + ymm4
	vfmadd231ps	%ymm9, %ymm10, %ymm7    # ymm7 = (ymm10 * ymm9) + ymm7
	vbroadcastss	167984(%rsi,%r8,4), %ymm9
	vfmadd231ps	%ymm8, %ymm11, %ymm1    # ymm1 = (ymm11 * ymm8) + ymm1
	vfmadd231ps	%ymm11, %ymm10, %ymm6   # ymm6 = (ymm10 * ymm11) + ymm6
	vbroadcastss	169344(%rsi,%r8,4), %ymm11
	vfmadd231ps	%ymm8, %ymm9, %ymm2     # ymm2 = (ymm9 * ymm8) + ymm2
	vfmadd231ps	%ymm9, %ymm10, %ymm5    # ymm5 = (ymm10 * ymm9) + ymm5
	vfmadd231ps	%ymm8, %ymm11, %ymm0    # ymm0 = (ymm11 * ymm8) + ymm0
	vfmadd231ps	%ymm10, %ymm11, %ymm3   # ymm3 = (ymm11 * ymm10) + ymm3
	vmovsd	32(%rdi), %xmm9                 # xmm9 = mem[0],zero
	vmovups	(%rdi), %ymm10
	vbroadcastss	167308(%rsi,%r8,4), %ymm8
	addq	$5280, %rdi                     # imm = 0x14A0
	vfmadd231ps	%ymm9, %ymm8, %ymm4     # ymm4 = (ymm8 * ymm9) + ymm4
	vfmadd231ps	%ymm8, %ymm10, %ymm7    # ymm7 = (ymm10 * ymm8) + ymm7
	vmovshdup	%xmm4, %xmm11           # xmm11 = xmm4[1,1,3,3]
	vextractf128	$1, %ymm7, %xmm8
	vmovshdup	%xmm7, %xmm12           # xmm12 = xmm7[1,1,3,3]
	vmovaps	%xmm11, 176(%rsp)               # 16-byte Spill
	vshufps	$255, %xmm8, %xmm8, %xmm11      # xmm11 = xmm8[3,3,3,3]
	vmovaps	%xmm8, 336(%rsp)                # 16-byte Spill
	vmovaps	%xmm12, 272(%rsp)               # 16-byte Spill
	vmovaps	%xmm11, -96(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm8, %xmm8, %xmm11        # xmm11 = xmm8[1,0]
	vmovapd	%xmm11, 208(%rsp)               # 16-byte Spill
	vmovshdup	%xmm8, %xmm11           # xmm11 = xmm8[1,1,3,3]
	vmovaps	%xmm11, 304(%rsp)               # 16-byte Spill
	vshufps	$255, %xmm7, %xmm7, %xmm11      # xmm11 = xmm7[3,3,3,3]
	vmovaps	%xmm11, -128(%rsp)              # 16-byte Spill
	vshufpd	$1, %xmm7, %xmm7, %xmm11        # xmm11 = xmm7[1,0]
	vmovapd	%xmm11, 240(%rsp)               # 16-byte Spill
	vbroadcastss	167988(%rsi,%r8,4), %ymm11
	vfmadd231ps	%ymm11, %ymm10, %ymm5   # ymm5 = (ymm10 * ymm11) + ymm5
	vfmadd231ps	%ymm9, %ymm11, %ymm2    # ymm2 = (ymm11 * ymm9) + ymm2
	vbroadcastss	168668(%rsi,%r8,4), %ymm11
	vextractf128	$1, %ymm5, %xmm14
	vshufps	$255, %xmm5, %xmm5, %xmm8       # xmm8 = xmm5[3,3,3,3]
	vshufpd	$1, %xmm5, %xmm5, %xmm15        # xmm15 = xmm5[1,0]
	vfmadd231ps	%ymm9, %ymm11, %ymm1    # ymm1 = (ymm11 * ymm9) + ymm1
	vfmadd231ps	%ymm11, %ymm10, %ymm6   # ymm6 = (ymm10 * ymm11) + ymm6
	vmovshdup	%xmm2, %xmm11           # xmm11 = xmm2[1,1,3,3]
	vmovaps	%xmm11, 160(%rsp)               # 16-byte Spill
	vbroadcastss	169348(%rsi,%r8,4), %ymm11
	addq	$4, %r8
	vmovshdup	%xmm1, %xmm13           # xmm13 = xmm1[1,1,3,3]
	vfmadd231ps	%ymm10, %ymm11, %ymm3   # ymm3 = (ymm11 * ymm10) + ymm3
	vshufps	$255, %xmm14, %xmm14, %xmm10    # xmm10 = xmm14[3,3,3,3]
	vfmadd231ps	%ymm9, %ymm11, %ymm0    # ymm0 = (ymm11 * ymm9) + ymm0
	vmovaps	%xmm10, -48(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm14, %xmm14, %xmm10      # xmm10 = xmm14[1,0]
	vmovapd	%xmm10, 384(%rsp)               # 16-byte Spill
	vmovshdup	%xmm14, %xmm10          # xmm10 = xmm14[1,1,3,3]
	vmovaps	%xmm10, -32(%rsp)               # 16-byte Spill
	vmovshdup	%xmm5, %xmm10           # xmm10 = xmm5[1,1,3,3]
	vmovaps	%xmm10, -16(%rsp)               # 16-byte Spill
	vextractf128	$1, %ymm6, %xmm10
	vshufps	$255, %xmm10, %xmm10, %xmm11    # xmm11 = xmm10[3,3,3,3]
	vextractf128	$1, %ymm3, %xmm9
	vmovshdup	%xmm0, %xmm12           # xmm12 = xmm0[1,1,3,3]
	vmovaps	%xmm11, 64(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm10, %xmm10, %xmm11      # xmm11 = xmm10[1,0]
	vmovapd	%xmm11, 32(%rsp)                # 16-byte Spill
	vmovshdup	%xmm10, %xmm11          # xmm11 = xmm10[1,1,3,3]
	vmovaps	%xmm11, (%rsp)                  # 16-byte Spill
	vshufps	$255, %xmm6, %xmm6, %xmm11      # xmm11 = xmm6[3,3,3,3]
	vmovaps	%xmm11, 80(%rsp)                # 16-byte Spill
	vshufpd	$1, %xmm6, %xmm6, %xmm11        # xmm11 = xmm6[1,0]
	vmovapd	%xmm11, 48(%rsp)                # 16-byte Spill
	vmovshdup	%xmm6, %xmm11           # xmm11 = xmm6[1,1,3,3]
	vmovaps	%xmm11, 16(%rsp)                # 16-byte Spill
	vshufps	$255, %xmm9, %xmm9, %xmm11      # xmm11 = xmm9[3,3,3,3]
	vmovaps	%xmm11, 144(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm9, %xmm9, %xmm11        # xmm11 = xmm9[1,0]
	vmovapd	%xmm11, 112(%rsp)               # 16-byte Spill
	vmovshdup	%xmm9, %xmm11           # xmm11 = xmm9[1,1,3,3]
	vmovaps	%xmm11, -64(%rsp)               # 16-byte Spill
	vshufps	$255, %xmm3, %xmm3, %xmm11      # xmm11 = xmm3[3,3,3,3]
	vmovaps	%xmm11, 352(%rsp)               # 16-byte Spill
	vshufpd	$1, %xmm3, %xmm3, %xmm11        # xmm11 = xmm3[1,0]
	vmovapd	%xmm11, 128(%rsp)               # 16-byte Spill
	vmovshdup	%xmm3, %xmm11           # xmm11 = xmm3[1,1,3,3]
	vmovaps	%xmm11, 96(%rsp)                # 16-byte Spill
	vmovaps	%xmm8, %xmm11
	vmovaps	336(%rsp), %xmm8                # 16-byte Reload
	cmpq	$164, %r8
	jb	.LBB0_13
# %bb.14:                               # %.preheader
	vinsertps	$16, 176(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0],mem[0],xmm4[2,3]
	vinsertps	$16, 160(%rsp), %xmm2, %xmm2 # 16-byte Folded Reload
                                        # xmm2 = xmm2[0],mem[0],xmm2[2,3]
	vinsertps	$16, %xmm13, %xmm1, %xmm1 # xmm1 = xmm1[0],xmm13[0],xmm1[2,3]
	vinsertps	$16, %xmm12, %xmm0, %xmm0 # xmm0 = xmm0[0],xmm12[0],xmm0[2,3]
	vinsertps	$16, 96(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0],mem[0],xmm3[2,3]
	vinsertps	$32, 128(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0,1],mem[0],xmm3[3]
	vinsertps	$48, 352(%rsp), %xmm3, %xmm3 # 16-byte Folded Reload
                                        # xmm3 = xmm3[0,1,2],mem[0]
	vmovsd	224392(%rdx), %xmm12            # xmm12 = mem[0],zero
	vmovups	%ymm4, 176(%rsp)                # 32-byte Spill
	vinsertps	$16, 272(%rsp), %xmm7, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm7[0],mem[0],xmm7[2,3]
	vinsertps	$32, 240(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1],mem[0],xmm4[3]
	vinsertps	$48, -128(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1,2],mem[0]
	vmovsd	223072(%rdx), %xmm7             # xmm7 = mem[0],zero
	vmovups	%ymm4, 240(%rsp)                # 32-byte Spill
	vinsertps	$16, 304(%rsp), %xmm8, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm8[0],mem[0],xmm8[2,3]
	vinsertps	$32, 208(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1],mem[0],xmm4[3]
	vinsertps	$48, -96(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1,2],mem[0]
	vmovups	176(%rsp), %ymm8                # 32-byte Reload
	vmovaps	%xmm4, -96(%rsp)                # 16-byte Spill
	vmovsd	167952(%rsi), %xmm4             # xmm4 = mem[0],zero
	vmovaps	%xmm4, -128(%rsp)               # 16-byte Spill
	vbroadcastss	%xmm4, %ymm4
	vfmadd231ps	%ymm7, %ymm4, %ymm8     # ymm8 = (ymm4 * ymm7) + ymm8
	vmovups	%ymm4, 208(%rsp)                # 32-byte Spill
	vmovups	240(%rsp), %ymm4                # 32-byte Reload
	vmovups	%ymm8, 176(%rsp)                # 32-byte Spill
	vmovups	223040(%rdx), %ymm8
	vmovups	176(%rsp), %ymm13               # 32-byte Reload
	vinsertf128	$1, -96(%rsp), %ymm4, %ymm4 # 16-byte Folded Reload
	vfmadd231ps	208(%rsp), %ymm8, %ymm4 # 32-byte Folded Reload
                                        # ymm4 = (ymm8 * mem) + ymm4
	vmovups	%ymm4, -96(%rsp)                # 32-byte Spill
	vinsertps	$16, -16(%rsp), %xmm5, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm5[0],mem[0],xmm5[2,3]
	vinsertps	$16, -32(%rsp), %xmm14, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm14[0],mem[0],xmm14[2,3]
	vinsertps	$32, 384(%rsp), %xmm5, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm5[0,1],mem[0],xmm5[3]
	vinsertps	$48, -48(%rsp), %xmm5, %xmm5 # 16-byte Folded Reload
                                        # xmm5 = xmm5[0,1,2],mem[0]
	vmovsd	168632(%rsi), %xmm14            # xmm14 = mem[0],zero
	vinsertps	$32, %xmm15, %xmm4, %xmm4 # xmm4 = xmm4[0,1],xmm15[0],xmm4[3]
	vinsertps	$48, %xmm11, %xmm4, %xmm4 # xmm4 = xmm4[0,1,2],xmm11[0]
	vbroadcastss	%xmm14, %ymm11
	vinsertf128	$1, %xmm5, %ymm4, %ymm5
	vinsertps	$16, 16(%rsp), %xmm6, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm6[0],mem[0],xmm6[2,3]
	vinsertps	$16, (%rsp), %xmm10, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm10[0],mem[0],xmm10[2,3]
	vinsertps	$32, 48(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1],mem[0],xmm4[3]
	vinsertps	$32, 32(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1],mem[0],xmm6[3]
	vinsertps	$48, 80(%rsp), %xmm4, %xmm4 # 16-byte Folded Reload
                                        # xmm4 = xmm4[0,1,2],mem[0]
	vinsertps	$48, 64(%rsp), %xmm6, %xmm6 # 16-byte Folded Reload
                                        # xmm6 = xmm6[0,1,2],mem[0]
	vmovsd	169312(%rsi), %xmm10            # xmm10 = mem[0],zero
	vfmadd231ps	%ymm7, %ymm11, %ymm2    # ymm2 = (ymm11 * ymm7) + ymm2
	vfmadd231ps	%ymm11, %ymm8, %ymm5    # ymm5 = (ymm8 * ymm11) + ymm5
	vmovsd	169992(%rsi), %xmm11            # xmm11 = mem[0],zero
	vinsertf128	$1, %xmm6, %ymm4, %ymm6
	vbroadcastss	%xmm10, %ymm4
	vfmadd231ps	%ymm7, %ymm4, %ymm1     # ymm1 = (ymm4 * ymm7) + ymm1
	vfmadd231ps	%ymm4, %ymm8, %ymm6     # ymm6 = (ymm8 * ymm4) + ymm6
	vbroadcastss	%xmm11, %ymm4
	vfmadd231ps	%ymm7, %ymm4, %ymm0     # ymm0 = (ymm4 * ymm7) + ymm0
	vinsertps	$16, -64(%rsp), %xmm9, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm9[0],mem[0],xmm9[2,3]
	vinsertps	$32, 112(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0,1],mem[0],xmm7[3]
	vinsertps	$48, 144(%rsp), %xmm7, %xmm7 # 16-byte Folded Reload
                                        # xmm7 = xmm7[0,1,2],mem[0]
	vinsertf128	$1, %xmm7, %ymm3, %ymm3
	vmovshdup	-128(%rsp), %xmm7       # 16-byte Folded Reload
                                        # xmm7 = mem[1,1,3,3]
	vfmadd231ps	%ymm8, %ymm4, %ymm3     # ymm3 = (ymm4 * ymm8) + ymm3
	vmovups	224360(%rdx), %ymm4
	vbroadcastss	%xmm7, %ymm8
	vfmadd231ps	%ymm7, %ymm12, %ymm13   # ymm13 = (ymm12 * ymm7) + ymm13
	vmovshdup	%xmm14, %xmm7           # xmm7 = xmm14[1,1,3,3]
	vfmadd213ps	-96(%rsp), %ymm4, %ymm8 # 32-byte Folded Reload
                                        # ymm8 = (ymm4 * ymm8) + mem
	vbroadcastss	%xmm7, %ymm9
	vfmadd231ps	%ymm7, %ymm12, %ymm2    # ymm2 = (ymm12 * ymm7) + ymm2
	vfmadd213ps	%ymm5, %ymm4, %ymm9     # ymm9 = (ymm4 * ymm9) + ymm5
	vmovshdup	%xmm10, %xmm5           # xmm5 = xmm10[1,1,3,3]
	vbroadcastss	%xmm5, %ymm7
	vfmadd231ps	%ymm5, %ymm12, %ymm1    # ymm1 = (ymm12 * ymm5) + ymm1
	vmovshdup	%xmm11, %xmm5           # xmm5 = xmm11[1,1,3,3]
	vxorps	%xmm11, %xmm11, %xmm11
	vbroadcastss	%xmm5, %ymm10
	vfmadd231ps	%ymm5, %ymm12, %ymm0    # ymm0 = (ymm12 * ymm5) + ymm0
	vmovups	1280(%rcx), %ymm5
	vfmadd213ps	%ymm6, %ymm4, %ymm7     # ymm7 = (ymm4 * ymm7) + ymm6
	vfmadd213ps	%ymm3, %ymm4, %ymm10    # ymm10 = (ymm4 * ymm10) + ymm3
	vmovsd	1312(%rcx), %xmm3               # xmm3 = mem[0],zero
	vaddps	%ymm5, %ymm8, %ymm8
	vaddps	%ymm5, %ymm9, %ymm9
	vaddps	%ymm5, %ymm7, %ymm7
	vaddps	%ymm5, %ymm10, %ymm10
	vaddps	%ymm3, %ymm2, %ymm4
	vaddps	%ymm3, %ymm1, %ymm2
	vaddps	%ymm3, %ymm13, %ymm6
	vaddps	%ymm3, %ymm0, %ymm0
	vmaxps	%ymm11, %ymm8, %ymm1
	vcmpunordps	%ymm8, %ymm8, %ymm5
	vcmpunordps	%ymm10, %ymm10, %ymm14
	vblendvps	%ymm5, %ymm8, %ymm1, %ymm1
	vmaxps	%ymm11, %ymm9, %ymm5
	vcmpunordps	%ymm9, %ymm9, %ymm8
	vblendvps	%ymm8, %ymm9, %ymm5, %ymm5
	vmaxps	%ymm11, %ymm7, %ymm8
	vcmpunordps	%ymm7, %ymm7, %ymm9
	vmovups	%ymm1, 326000(%rax)
	vblendvps	%ymm9, %ymm7, %ymm8, %ymm7
	vxorps	%xmm9, %xmm9, %xmm9
	vmaxps	%ymm11, %ymm10, %ymm8
	vblendvps	%ymm14, %ymm10, %ymm8, %ymm8
	vcmpunordps	%ymm6, %ymm6, %ymm10
	vmaxps	%xmm9, %xmm6, %xmm12
	vmaxps	%xmm9, %xmm4, %xmm13
	vmaxps	%xmm9, %xmm0, %xmm3
	vblendvps	%xmm10, %xmm6, %xmm12, %xmm6
	vcmpunordps	%ymm4, %ymm4, %ymm10
	vmaxps	%xmm9, %xmm2, %xmm12
	vcmpunordps	%ymm0, %ymm0, %ymm9
	vblendvps	%xmm10, %xmm4, %xmm13, %xmm4
	vcmpunordps	%ymm2, %ymm2, %ymm10
	vblendvps	%xmm9, %xmm0, %xmm3, %xmm0
	vmovlps	%xmm6, 326032(%rax)
	vmovups	%ymm5, 327320(%rax)
	vblendvps	%xmm10, %xmm2, %xmm12, %xmm2
	vmovlps	%xmm4, 327352(%rax)
	vmovups	%ymm7, 328640(%rax)
	vmovlps	%xmm2, 328672(%rax)
	vmovups	%ymm8, 329960(%rax)
	vmovlps	%xmm0, 329992(%rax)
	addq	$792, %rsp                      # imm = 0x318
	popq	%rbx
	popq	%r12
	popq	%r14
	popq	%r15
	vzeroupper
	retq
.Lfunc_end0:
	.size	entry, .Lfunc_end0-entry
                                        # -- End function
	.globl	_mlir_ciface_entry              # -- Begin function _mlir_ciface_entry
	.prefalign	4, .Lfunc_end1, nop
	.type	_mlir_ciface_entry,@function
_mlir_ciface_entry:                     # @_mlir_ciface_entry
# %bb.0:
	subq	$168, %rsp
	movq	8(%rdi), %rax
	movq	8(%rsi), %rsi
	movq	8(%rdx), %rdx
	movq	8(%rcx), %rcx
	movq	%rsi, 16(%rsp)
	movq	%rax, %rsi
	movq	%rcx, 112(%rsp)
	movq	%rdx, 72(%rsp)
	callq	entry@PLT
	addq	$168, %rsp
	retq
.Lfunc_end1:
	.size	_mlir_ciface_entry, .Lfunc_end1-_mlir_ciface_entry
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
