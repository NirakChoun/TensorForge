	.att_syntax
	.file	"LLVMDialectModule"
	.text
	.globl	entry                           # -- Begin function entry
	.prefalign	4, .Lfunc_end0, nop
	.type	entry,@function
entry:                                  # @entry
# %bb.0:
	pushq	%rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$72, %rsp
	movq	240(%rsp), %r15
	xorl	%ecx, %ecx
	movq	%rsi, 8(%rsp)                   # 8-byte Spill
	.p2align	4
.LBB0_1:                                # %.preheader15.split.us.preheader
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
                                        #       Child Loop BB0_3 Depth 3
                                        #       Child Loop BB0_5 Depth 3
                                        #         Child Loop BB0_6 Depth 4
                                        #           Child Loop BB0_7 Depth 5
                                        #       Child Loop BB0_11 Depth 3
                                        #         Child Loop BB0_12 Depth 4
	movl	$250, %ebp
	movl	$32, %eax
	movq	200(%rsp), %r13
	movq	144(%rsp), %r11
	movq	%rcx, 24(%rsp)                  # 8-byte Spill
	movq	%r15, 16(%rsp)                  # 8-byte Spill
	subq	%rcx, %rbp
	cmpq	$32, %rbp
	cmovaeq	%rax, %rbp
	imulq	$1320, %rcx, %rax               # imm = 0x528
	addq	240(%rsp), %rax
	xorl	%ecx, %ecx
	xorl	%edx, %edx
	movq	%rax, 32(%rsp)                  # 8-byte Spill
	.p2align	4
.LBB0_2:                                # %.preheader12.lr.ph.us
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_3 Depth 3
                                        #       Child Loop BB0_5 Depth 3
                                        #         Child Loop BB0_6 Depth 4
                                        #           Child Loop BB0_7 Depth 5
                                        #       Child Loop BB0_11 Depth 3
                                        #         Child Loop BB0_12 Depth 4
	movq	%rcx, %rax
	movl	$330, %r14d                     # imm = 0x14A
	movl	$330, %r12d                     # imm = 0x14A
	movq	%r11, 64(%rsp)                  # 8-byte Spill
	movq	%rcx, 48(%rsp)                  # 8-byte Spill
	movq	%rdx, 40(%rsp)                  # 8-byte Spill
	movq	%r15, 56(%rsp)                  # 8-byte Spill
	shlq	$5, %rax
	subq	%rax, %r14
	movl	$32, %eax
	cmpq	$32, %r14
	cmovaeq	%rax, %r14
	subq	%rdx, %r12
	shll	$2, %r14d
	cmpq	$32, %r12
	cmovaeq	%rax, %r12
	xorl	%ebx, %ebx
	.p2align	4
.LBB0_3:                                # %.preheader12.us
                                        #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movq	%r15, %rdi
	xorl	%esi, %esi
	movq	%r14, %rdx
	callq	memset@PLT
	incq	%rbx
	addq	$1320, %r15                     # imm = 0x528
	cmpq	%rbp, %rbx
	jb	.LBB0_3
# %bb.4:                                # %.preheader14.us
                                        #   in Loop: Header=BB0_2 Depth=2
	movq	32(%rsp), %rax                  # 8-byte Reload
	movq	40(%rsp), %rbx                  # 8-byte Reload
	movq	8(%rsp), %rcx                   # 8-byte Reload
	movq	64(%rsp), %r11                  # 8-byte Reload
	movq	56(%rsp), %r15                  # 8-byte Reload
	xorl	%edx, %edx
	vxorps	%xmm3, %xmm3, %xmm3
	leaq	(%rax,%rbx,4), %rax
	.p2align	4
.LBB0_5:                                # %.preheader11.us
                                        #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_6 Depth 4
                                        #           Child Loop BB0_7 Depth 5
	imulq	$1320, %rdx, %rsi               # imm = 0x528
	movq	%r11, %rdi
	xorl	%r8d, %r8d
	addq	%rax, %rsi
	.p2align	4
.LBB0_6:                                # %.preheader.us
                                        #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        #       Parent Loop BB0_5 Depth=3
                                        # =>      This Loop Header: Depth=4
                                        #           Child Loop BB0_7 Depth 5
	vmovss	(%rsi,%r8,4), %xmm0             # xmm0 = mem[0],zero,zero,zero
	movq	$-1, %r9
	movq	%rdi, %r10
	.p2align	4
.LBB0_7:                                #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        #       Parent Loop BB0_5 Depth=3
                                        #         Parent Loop BB0_6 Depth=4
                                        # =>        This Inner Loop Header: Depth=5
	vmovss	4(%rcx,%r9,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	vmulss	(%r10), %xmm1, %xmm1
	incq	%r9
	addq	$1320, %r10                     # imm = 0x528
	vaddss	%xmm1, %xmm0, %xmm0
	vmovss	%xmm0, (%rsi,%r8,4)
	cmpq	$169, %r9
	jb	.LBB0_7
# %bb.8:                                #   in Loop: Header=BB0_6 Depth=4
	incq	%r8
	addq	$4, %rdi
	cmpq	%r12, %r8
	jb	.LBB0_6
# %bb.9:                                #   in Loop: Header=BB0_5 Depth=3
	incq	%rdx
	addq	$680, %rcx                      # imm = 0x2A8
	cmpq	%rbp, %rdx
	jb	.LBB0_5
# %bb.10:                               # %.preheader10.lr.ph.us
                                        #   in Loop: Header=BB0_2 Depth=2
	movq	%r15, %rax
	xorl	%ecx, %ecx
	.p2align	4
.LBB0_11:                               # %.preheader10.us
                                        #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_12 Depth 4
	xorl	%edx, %edx
	.p2align	4
.LBB0_12:                               #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        #       Parent Loop BB0_11 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	vmovss	(%r13,%rdx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	vaddss	(%rax,%rdx,4), %xmm0, %xmm0
	vcmpunordss	%xmm0, %xmm0, %xmm1
	vmaxss	%xmm3, %xmm0, %xmm2
	vblendvps	%xmm1, %xmm0, %xmm2, %xmm0
	vmovss	%xmm0, (%rax,%rdx,4)
	incq	%rdx
	cmpq	%r12, %rdx
	jb	.LBB0_12
# %bb.13:                               #   in Loop: Header=BB0_11 Depth=3
	incq	%rcx
	addq	$1320, %rax                     # imm = 0x528
	cmpq	%rbp, %rcx
	jb	.LBB0_11
# %bb.14:                               # %._crit_edge.us
                                        #   in Loop: Header=BB0_2 Depth=2
	movq	48(%rsp), %rcx                  # 8-byte Reload
	subq	$-128, %r15
	subq	$-128, %r11
	subq	$-128, %r13
	leaq	32(%rbx), %rdx
	incq	%rcx
	cmpq	$298, %rbx                      # imm = 0x12A
	jb	.LBB0_2
# %bb.15:                               # %.split.us
                                        #   in Loop: Header=BB0_1 Depth=1
	movq	16(%rsp), %r15                  # 8-byte Reload
	movq	24(%rsp), %rax                  # 8-byte Reload
	addq	$21760, 8(%rsp)                 # 8-byte Folded Spill
                                        # imm = 0x5500
	addq	$42240, %r15                    # imm = 0xA500
	leaq	32(%rax), %rcx
	cmpq	$218, %rax
	jb	.LBB0_1
# %bb.16:
	addq	$72, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
.Lfunc_end0:
	.size	entry, .Lfunc_end0-entry
                                        # -- End function
	.globl	_mlir_ciface_entry              # -- Begin function _mlir_ciface_entry
	.prefalign	4, .Lfunc_end1, nop
	.type	_mlir_ciface_entry,@function
_mlir_ciface_entry:                     # @_mlir_ciface_entry
# %bb.0:
	pushq	%rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$88, %rsp
	movq	8(%rdx), %rdx
	movq	8(%rdi), %rax
	movq	8(%rsi), %rsi
	movl	$32, %r14d
	movq	%rdx, 24(%rsp)                  # 8-byte Spill
	movq	8(%rcx), %rdx
	xorl	%ecx, %ecx
	movq	%rax, 8(%rsp)                   # 8-byte Spill
	movq	%rsi, 32(%rsp)                  # 8-byte Spill
	movq	%rdx, 16(%rsp)                  # 8-byte Spill
	.p2align	4
.LBB1_1:                                # %.preheader15.split.us.preheader.i
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
                                        #       Child Loop BB1_3 Depth 3
                                        #       Child Loop BB1_5 Depth 3
                                        #         Child Loop BB1_6 Depth 4
                                        #           Child Loop BB1_7 Depth 5
                                        #       Child Loop BB1_11 Depth 3
                                        #         Child Loop BB1_12 Depth 4
	movl	$250, %r13d
	movq	24(%rsp), %r12                  # 8-byte Reload
	movq	32(%rsp), %r15                  # 8-byte Reload
	movq	%rcx, 48(%rsp)                  # 8-byte Spill
	movq	%rdx, %rdi
	movq	%rdx, 40(%rsp)                  # 8-byte Spill
	subq	%rcx, %r13
	cmpq	$32, %r13
	cmovaeq	%r14, %r13
	imulq	$1320, %rcx, %rax               # imm = 0x528
	addq	16(%rsp), %rax                  # 8-byte Folded Reload
	xorl	%ecx, %ecx
	movq	%rax, 56(%rsp)                  # 8-byte Spill
	xorl	%eax, %eax
	.p2align	4
.LBB1_2:                                # %.preheader12.lr.ph.us.i
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_3 Depth 3
                                        #       Child Loop BB1_5 Depth 3
                                        #         Child Loop BB1_6 Depth 4
                                        #           Child Loop BB1_7 Depth 5
                                        #       Child Loop BB1_11 Depth 3
                                        #         Child Loop BB1_12 Depth 4
	movq	%rcx, 72(%rsp)                  # 8-byte Spill
	movq	%rcx, %rcx
	movl	$330, %ebx                      # imm = 0x14A
	movq	%rax, 64(%rsp)                  # 8-byte Spill
	movq	%rdi, 80(%rsp)                  # 8-byte Spill
	shlq	$5, %rcx
	subq	%rcx, %rbx
	cmpq	$32, %rbx
	cmovaeq	%r14, %rbx
	movq	%rdi, %r14
	xorl	%ebp, %ebp
	shll	$2, %ebx
	.p2align	4
.LBB1_3:                                # %.preheader12.us.i
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movq	%r14, %rdi
	xorl	%esi, %esi
	movq	%rbx, %rdx
	callq	memset@PLT
	incq	%rbp
	addq	$1320, %r14                     # imm = 0x528
	cmpq	%r13, %rbp
	jb	.LBB1_3
# %bb.4:                                # %.preheader14.us.i
                                        #   in Loop: Header=BB1_2 Depth=2
	movq	64(%rsp), %rbx                  # 8-byte Reload
	movq	56(%rsp), %rcx                  # 8-byte Reload
	movl	$330, %eax                      # imm = 0x14A
	movq	8(%rsp), %rdx                   # 8-byte Reload
	movl	$32, %r14d
	vxorps	%xmm3, %xmm3, %xmm3
	subq	%rbx, %rax
	leaq	(%rcx,%rbx,4), %rcx
	cmpq	$32, %rax
	cmovaeq	%r14, %rax
	xorl	%esi, %esi
	.p2align	4
.LBB1_5:                                # %.preheader11.us.i
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB1_6 Depth 4
                                        #           Child Loop BB1_7 Depth 5
	imulq	$1320, %rsi, %rdi               # imm = 0x528
	movq	%r15, %r8
	xorl	%r9d, %r9d
	addq	%rcx, %rdi
	.p2align	4
.LBB1_6:                                # %.preheader.us.i
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        #       Parent Loop BB1_5 Depth=3
                                        # =>      This Loop Header: Depth=4
                                        #           Child Loop BB1_7 Depth 5
	vmovss	(%rdi,%r9,4), %xmm0             # xmm0 = mem[0],zero,zero,zero
	movq	$-1, %r10
	movq	%r8, %r11
	.p2align	4
.LBB1_7:                                #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        #       Parent Loop BB1_5 Depth=3
                                        #         Parent Loop BB1_6 Depth=4
                                        # =>        This Inner Loop Header: Depth=5
	vmovss	4(%rdx,%r10,4), %xmm1           # xmm1 = mem[0],zero,zero,zero
	vmulss	(%r11), %xmm1, %xmm1
	incq	%r10
	addq	$1320, %r11                     # imm = 0x528
	vaddss	%xmm1, %xmm0, %xmm0
	vmovss	%xmm0, (%rdi,%r9,4)
	cmpq	$169, %r10
	jb	.LBB1_7
# %bb.8:                                #   in Loop: Header=BB1_6 Depth=4
	incq	%r9
	addq	$4, %r8
	cmpq	%rax, %r9
	jb	.LBB1_6
# %bb.9:                                #   in Loop: Header=BB1_5 Depth=3
	incq	%rsi
	addq	$680, %rdx                      # imm = 0x2A8
	cmpq	%r13, %rsi
	jb	.LBB1_5
# %bb.10:                               # %.preheader10.lr.ph.us.i
                                        #   in Loop: Header=BB1_2 Depth=2
	movq	80(%rsp), %rdi                  # 8-byte Reload
	xorl	%edx, %edx
	movq	%rdi, %rcx
	.p2align	4
.LBB1_11:                               # %.preheader10.us.i
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB1_12 Depth 4
	xorl	%esi, %esi
	.p2align	4
.LBB1_12:                               #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        #       Parent Loop BB1_11 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	vmovss	(%r12,%rsi,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	vaddss	(%rcx,%rsi,4), %xmm0, %xmm0
	vcmpunordss	%xmm0, %xmm0, %xmm1
	vmaxss	%xmm3, %xmm0, %xmm2
	vblendvps	%xmm1, %xmm0, %xmm2, %xmm0
	vmovss	%xmm0, (%rcx,%rsi,4)
	incq	%rsi
	cmpq	%rax, %rsi
	jb	.LBB1_12
# %bb.13:                               #   in Loop: Header=BB1_11 Depth=3
	incq	%rdx
	addq	$1320, %rcx                     # imm = 0x528
	cmpq	%r13, %rdx
	jb	.LBB1_11
# %bb.14:                               # %._crit_edge.us.i
                                        #   in Loop: Header=BB1_2 Depth=2
	movq	72(%rsp), %rcx                  # 8-byte Reload
	subq	$-128, %rdi
	subq	$-128, %r15
	subq	$-128, %r12
	leaq	32(%rbx), %rax
	incq	%rcx
	cmpq	$298, %rbx                      # imm = 0x12A
	jb	.LBB1_2
# %bb.15:                               # %.split.us.i
                                        #   in Loop: Header=BB1_1 Depth=1
	movq	40(%rsp), %rdx                  # 8-byte Reload
	movq	48(%rsp), %rax                  # 8-byte Reload
	addq	$21760, 8(%rsp)                 # 8-byte Folded Spill
                                        # imm = 0x5500
	addq	$42240, %rdx                    # imm = 0xA500
	leaq	32(%rax), %rcx
	cmpq	$218, %rax
	jb	.LBB1_1
# %bb.16:                               # %entry.exit
	addq	$88, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
.Lfunc_end1:
	.size	_mlir_ciface_entry, .Lfunc_end1-_mlir_ciface_entry
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
