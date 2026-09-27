	.att_syntax
	.file	"LLVMDialectModule"
	.text
	.globl	entry                           # -- Begin function entry
	.prefalign	4, .Lfunc_end0, nop
	.type	entry,@function
entry:                                  # @entry
	.cfi_startproc
# %bb.0:                                # %.preheader10.preheader
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	pushq	%rax
	.cfi_def_cfa_offset 64
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	176(%rsp), %r12
	movq	136(%rsp), %r13
	movq	80(%rsp), %rbp
	movl	$330064, %edi                   # imm = 0x50950
	movq	%rsi, %r15
	callq	_mlir_memref_to_llvm_alloc@PLT
	movq	%rax, %r14
	movl	$330000, %edx                   # imm = 0x50910
	xorl	%esi, %esi
	movq	%rax, (%rsp)                    # 8-byte Spill
	xorl	%ebx, %ebx
	addq	$63, %r14
	andq	$-64, %r14
	movq	%r14, %rdi
	callq	memset@PLT
	.p2align	4
.LBB0_1:                                # %.preheader10
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
                                        #       Child Loop BB0_3 Depth 3
	imulq	$1320, %rbx, %rax               # imm = 0x528
	movq	%rbp, %rcx
	xorl	%edx, %edx
	addq	%r14, %rax
	.p2align	4
.LBB0_2:                                # %.preheader9
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_3 Depth 3
	vmovss	(%rax,%rdx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movq	$-1, %rsi
	movq	%rcx, %rdi
	.p2align	4
.LBB0_3:                                #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	vmovss	4(%r15,%rsi,4), %xmm1           # xmm1 = mem[0],zero,zero,zero
	vmulss	(%rdi), %xmm1, %xmm1
	incq	%rsi
	addq	$1320, %rdi                     # imm = 0x528
	vaddss	%xmm1, %xmm0, %xmm0
	vmovss	%xmm0, (%rax,%rdx,4)
	cmpq	$169, %rsi
	jb	.LBB0_3
# %bb.4:                                #   in Loop: Header=BB0_2 Depth=2
	addq	$4, %rcx
	cmpq	$329, %rdx                      # imm = 0x149
	leaq	1(%rdx), %rdx
	jb	.LBB0_2
# %bb.5:                                #   in Loop: Header=BB0_1 Depth=1
	addq	$680, %r15                      # imm = 0x2A8
	cmpq	$249, %rbx
	leaq	1(%rbx), %rbx
	jb	.LBB0_1
# %bb.6:
	movl	$330064, %edi                   # imm = 0x50950
	callq	_mlir_memref_to_llvm_alloc@PLT
	movq	%rax, %r15
	addq	$63, %rax
	xorl	%edx, %edx
	andq	$-64, %rax
	movq	%rax, %rcx
	.p2align	4
.LBB0_7:                                # %.preheader8
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_8 Depth 2
	movq	$-1, %rsi
	.p2align	4
.LBB0_8:                                #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovss	4(%r14,%rsi,4), %xmm0           # xmm0 = mem[0],zero,zero,zero
	vaddss	4(%r13,%rsi,4), %xmm0, %xmm0
	vmovss	%xmm0, 4(%rcx,%rsi,4)
	incq	%rsi
	cmpq	$329, %rsi                      # imm = 0x149
	jb	.LBB0_8
# %bb.9:                                #   in Loop: Header=BB0_7 Depth=1
	addq	$1320, %rcx                     # imm = 0x528
	addq	$1320, %r14                     # imm = 0x528
	cmpq	$249, %rdx
	leaq	1(%rdx), %rdx
	jb	.LBB0_7
# %bb.10:                               # %.preheader.preheader
	xorl	%ecx, %ecx
	vxorps	%xmm0, %xmm0, %xmm0
	.p2align	4
.LBB0_11:                               # %.preheader
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_12 Depth 2
	movq	$-1, %rdx
	.p2align	4
.LBB0_12:                               #   Parent Loop BB0_11 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovss	4(%rax,%rdx,4), %xmm1           # xmm1 = mem[0],zero,zero,zero
	vcmpunordss	%xmm1, %xmm1, %xmm2
	vmaxss	%xmm0, %xmm1, %xmm3
	vblendvps	%xmm2, %xmm1, %xmm3, %xmm1
	vmovss	%xmm1, 4(%r12,%rdx,4)
	incq	%rdx
	cmpq	$329, %rdx                      # imm = 0x149
	jb	.LBB0_12
# %bb.13:                               #   in Loop: Header=BB0_11 Depth=1
	addq	$1320, %r12                     # imm = 0x528
	addq	$1320, %rax                     # imm = 0x528
	cmpq	$249, %rcx
	leaq	1(%rcx), %rcx
	jb	.LBB0_11
# %bb.14:
	movq	(%rsp), %rdi                    # 8-byte Reload
	callq	_mlir_memref_to_llvm_free@PLT
	movq	%r15, %rdi
	addq	$8, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	jmp	_mlir_memref_to_llvm_free@PLT   # TAILCALL
.Lfunc_end0:
	.size	entry, .Lfunc_end0-entry
	.cfi_endproc
                                        # -- End function
	.globl	_mlir_ciface_entry              # -- Begin function _mlir_ciface_entry
	.prefalign	4, .Lfunc_end1, nop
	.type	_mlir_ciface_entry,@function
_mlir_ciface_entry:                     # @_mlir_ciface_entry
	.cfi_startproc
# %bb.0:
	subq	$168, %rsp
	.cfi_def_cfa_offset 176
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
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end1:
	.size	_mlir_ciface_entry, .Lfunc_end1-_mlir_ciface_entry
	.cfi_endproc
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
