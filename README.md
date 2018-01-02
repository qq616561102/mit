# mit-lab3
修改以下代码段
## A段
### exercise 1
```
// kern/pmap.c

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
    envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
	memset(envs, 0, NENV * sizeof(struct Env));

	//////////////////////////////////////////////////////////////////////
	// Map the 'envs' array read-only by the user at linear address UENVS
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
    boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV*sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
```
### exercise 2
```
void
env_init(void)
{
    // Set up envs array
    // LAB 3: Your code here.
    int i = NENV;
    while (i>0) {
        i--;
        envs[i].env_id = 0;
        envs[i].env_link = env_free_list;
        env_free_list = &envs[i];
    }
    // Per-CPU part of the initialization
    env_init_percpu();
}
```
```
static int
env_setup_vm(struct Env *e)
{
    int i;
    struct PageInfo *p = NULL;

    // Allocate a page for the page directory
    if (!(p = page_alloc(ALLOC_ZERO)))
        return -E_NO_MEM;

    // ...

    // LAB 3: Your code here.
    e->env_pgdir = page2kva(p);
    memcpy(e->env_pgdir, kern_pgdir, PGSIZE); // use kern_pgdir as template 
    p->pp_ref++;
    // UVPT maps the env's own page table read-only.
    // Permissions: kernel R, user R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

    return 0;
}
```
```
static void
region_alloc(struct Env *e, void *va, size_t len)
{
    // LAB 3: Your code here.
    // (But only if you need it for load_icode.)
    //
    // Hint: It is easier to use region_alloc if the caller can pass
    //   'va' and 'len' values that are not page-aligned.
    //   You should round va down, and round (va + len) up.
    //   (Watch out for corner-cases!)

    // 根据最初地址和最终地址, 对整个内存对齐
    uintptr_t va_start = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t va_end = ROUNDUP((uintptr_t)va + len, PGSIZE);
    struct PageInfo *pginfo = NULL;
    for (int cur_va=va_start; cur_va<va_end; cur_va+=PGSIZE) {
        pginfo = page_alloc(0);
        if (!pginfo) {
            int r = -E_NO_MEM;
            panic("region_alloc: %e" , r);
        }
        cprintf("insert page at %08x\n",cur_va);
        page_insert(e->env_pgdir, pginfo, (void *)cur_va, PTE_U | PTE_W | PTE_P);
    }
}
```
```
置上的数据置0, 非常类似引导加载器做的内容, 可以参照boot/main.c, 函数映射到程序初始化栈的页面
static void
load_icode(struct Env *e, uint8_t *binary)
{
	// LAB 3: Your code here.
    struct Proghdr *ph, *eph;
    struct Elf *elf = (struct Elf *)binary;
    if (elf->e_magic != ELF_MAGIC) {
        panic("load_icode: not an ELF file");
    }
    ph = (struct Proghdr *)(binary + elf->e_phoff);
    eph = ph + elf->e_phnum;

    // 将地址加载到cr3寄存器
    lcr3(PADDR(e->env_pgdir));
    for (; ph<eph; ph++) {
        if (ph->p_type == ELF_PROG_LOAD) {
            if (ph->p_filesz > ph->p_memsz) {
                panic("load_icode: file size is greater than memory size");
            }
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
            memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
            memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
        }
    }
    // 更改函数入口
    e->env_tf.tf_eip = elf->e_entry;
    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.
    
    // LAB 3: Your code here.
    region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
    lcr3(PADDR(kern_pgdir));
}
```
```
void
env_create(uint8_t *binary, enum EnvType type)
{
    // LAB 3: Your code here.
    struct Env *e;
    int r = env_alloc(&e, 0);
    if (r<0) {
        panic("env_create: %e",r);
    }
    e->env_type = type;
    load_icode(e, binary);
}
```
```
void
env_run(struct Env *e)
{
    // LAB 3: Your code here.
    // panic("env_run not yet implemented");
    if (curenv && curenv->env_status == ENV_RUNNING) {
        curenv->env_status = ENV_RUNNABLE;
    }
    curenv = e;
    e->env_status = ENV_RUNNING;
    e->env_runs++;
    lcr3(PADDR(e->env_pgdir));
    
    // 将指令寄存器的值设置到可执行文件的入口
    env_pop_tf(&e->env_tf);
}
```
### exercise 4
```
/* kern/trapentry.S */

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0, T_DIVIDE)
TRAPHANDLER_NOEC(handler1, T_DEBUG)
TRAPHANDLER_NOEC(handler2, T_NMI)
TRAPHANDLER_NOEC(handler3, T_BRKPT)
TRAPHANDLER_NOEC(handler4, T_OFLOW)
TRAPHANDLER_NOEC(handler5, T_BOUND)
TRAPHANDLER_NOEC(handler6, T_ILLOP)
TRAPHANDLER_NOEC(handler7, T_DEVICE)
TRAPHANDLER(handler8, T_DBLFLT)
// 9 deprecated since 386
TRAPHANDLER(handler10, T_TSS)
TRAPHANDLER(handler11, T_SEGNP)
TRAPHANDLER(handler12, T_STACK)
TRAPHANDLER(handler13, T_GPFLT)
TRAPHANDLER(handler14, T_PGFLT)
// 15 reserved by intel
TRAPHANDLER_NOEC(handler16, T_FPERR)
TRAPHANDLER(handler17, T_ALIGN)
TRAPHANDLER_NOEC(handler18, T_MCHK)
TRAPHANDLER_NOEC(handler19, T_SIMDERR)
// system call (interrupt)
TRAPHANDLER_NOEC(handler48, T_SYSCALL)


/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
pushl %ds
pushl %es
pushal

movw $GD_KD, %ax
movw %ax, %ds
movw %ax, %es
pushl %esp
call trap
```
```
// kern/trap.c
void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
    void handler0();
    void handler1();
    void handler2();
    void handler3();
    void handler4();
    void handler5();
    void handler6();
    void handler7();
    void handler8();

    void handler10();
    void handler11();
    void handler12();
    void handler13();
    void handler14();

    void handler16();
    void handler17();
    void handler18();
    void handler19();
    void handler48();

    // inc/mmu.h
    SETGATE(idt[T_DIVIDE], 1, GD_KT, handler0, 0);
    SETGATE(idt[T_DEBUG], 1, GD_KT, handler1, 0);
    SETGATE(idt[T_NMI], 1, GD_KT, handler2, 0);
    SETGATE(idt[T_BRKPT], 1, GD_KT, handler3, 3);
    SETGATE(idt[T_OFLOW], 1, GD_KT, handler4, 0);
    SETGATE(idt[T_BOUND], 1, GD_KT, handler5, 0);
    SETGATE(idt[T_ILLOP], 1, GD_KT, handler6, 0);
    SETGATE(idt[T_DEVICE], 1, GD_KT, handler7, 0);
    SETGATE(idt[T_DBLFLT], 1, GD_KT, handler8, 0);

    SETGATE(idt[T_TSS], 1, GD_KT, handler10, 0);
    SETGATE(idt[T_SEGNP], 1, GD_KT, handler11, 0);
    SETGATE(idt[T_STACK], 1, GD_KT, handler12, 0);
    SETGATE(idt[T_GPFLT], 1, GD_KT, handler13, 0);
    SETGATE(idt[T_PGFLT], 1, GD_KT, handler14, 0);
    
    SETGATE(idt[T_FPERR], 1, GD_KT, handler16, 0);
    SETGATE(idt[T_ALIGN], 1, GD_KT, handler17, 0);
    SETGATE(idt[T_MCHK], 1, GD_KT, handler18, 0);
    SETGATE(idt[T_SIMDERR], 1, GD_KT, handler19, 0);

    // interrupt
    SETGATE(idt[T_SYSCALL], 0, GD_KT, handler48, 3);

	// Per-CPU setup 
	trap_init_percpu();
}
```
## B段
### Exercise 5
```
// kern/trap.c
static void
trap_dispatch(struct Trapframe *tf)
{
    // Handle processor exceptions.
    // LAB 3: Your code here.
    switch (tf->tf_trapno) {
        case T_PGFLT:
            page_fault_handler(tf);
            break;
        default:
        // Unexpected trap: The user process or the kernel has a bug.
        print_trapframe(tf);
        if (tf->tf_cs == GD_KT)
            panic("unhandled trap in kernel");
        else {
            env_destroy(curenv);
            return;
        }
    }
}
```
### Exercise 6
```
// kern/trap.c

// 为断点异常设置用户态权限
void
trap_init(void)
{
    // ...
    // SETGATE(idt[T_BRKPT], 1, GD_KT, handler3, 0);
    SETGATE(idt[T_BRKPT], 1, GD_KT, handler3, 3);
    // ...
}

// 添加断点处理
static void
trap_dispatch(struct Trapframe *tf)
{
    // Handle processor exceptions.
    // LAB 3: Your code here.
    switch (tf->tf_trapno) {
        case T_PGFLT:
            page_fault_handler(tf);
            break;
        case T_BRKPT:
            monitor(tf);
			break;
        default:
        // Unexpected trap: The user process or the kernel has a bug.
        print_trapframe(tf);
        if (tf->tf_cs == GD_KT)
            panic("unhandled trap in kernel");
        else {
            env_destroy(curenv);
            return;
        }
    }
}
```
### exercise 7
```
static void
trap_dispatch(struct Trapframe *tf)
{
    // Handle processor exceptions.
    // LAB 3: Your code here.
    switch (tf->tf_trapno) {
        case T_PGFLT:
            page_fault_handler(tf);
            break;
        case T_BRKPT:
            monitor(tf);
			break;
        case T_SYSCALL:
            tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
                            tf->tf_regs.reg_edx,
                            tf->tf_regs.reg_ecx,
                            tf->tf_regs.reg_ebx,
                            tf->tf_regs.reg_edi,
                            tf->tf_regs.reg_esi);
            break;
        default:
        // Unexpected trap: The user process or the kernel has a bug.
        print_trapframe(tf);
        if (tf->tf_cs == GD_KT)
            panic("unhandled trap in kernel");
        else {
            env_destroy(curenv);
            return;
        }
    }
}
```
```
// kern/syscall.c

int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

    // panic("syscall not implemented");
    
    int32_t retVal = 0;
    switch (syscallno) {
    case SYS_cputs:
        sys_cputs((const char *)a1, a2);
        break;
    case SYS_cgetc:
        retVal = sys_cgetc();
        break;
    case SYS_env_destroy:
        retVal = sys_env_destroy(a1);
        break;
    case SYS_getenvid:
        retVal = sys_getenvid();
        break;
    default:
        retVal = -E_INVAL;
    }
    return retVal;
}
```
### exercise 8
```
// lib/libmain.c

void
libmain(int argc, char **argv)
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
    thisenv = &envs[ENVX(sys_getenvid())];
    // ...
}
```
### exercise 9
```
// kern/trap.c
// 判断页错误来源

void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

    // Read processor's CR2 register to find the faulting address
    fault_va = rcr2();

    // Handle kernel-mode page faults.

    // LAB 3: Your code here.
    if ((tf->tf_cs & 3) == 0) panic("Page fault in kernel-mode");

    // We've already handled kernel-mode exceptions, so if we get here,
    // the page fault happened in user mode.

    // Destroy the environment that caused the fault.
    cprintf("[%08x] user fault va %08x ip %08x\n",
        curenv->env_id, fault_va, tf->tf_eip);
    print_trapframe(tf);
    env_destroy(curenv);
}
```
```
// kern/pmap.c
// 需要存储第一个访问出错的地址

int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
    // LAB 3: Your code here.
    uintptr_t start_va = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t end_va = ROUNDUP((uintptr_t)va + len, PGSIZE);
    for (uintptr_t cur_va=start_va; cur_va<end_va; cur_va+=PGSIZE) {
        pte_t *cur_pte = pgdir_walk(env->env_pgdir, (void *)cur_va, 0);
        if (cur_pte == NULL || (*cur_pte & (perm|PTE_P)) != (perm|PTE_P) || cur_va >= ULIM) {
            if (cur_va == start_va) {
                user_mem_check_addr = (uintptr_t)va;
            } else {
                user_mem_check_addr = cur_va;
            }
            return -E_FAULT;
        }
    }
    return 0;
}
```
```
// kern/syscall.c
// 输入字符串部分加入内存检查

static void
sys_cputs(const char *s, size_t len)
{
    // Check that the user has permission to read memory [s, s+len).
    // Destroy the environment if not.

    // LAB 3: Your code here.
    user_mem_assert(curenv, s, len, PTE_U);
    // Print the string supplied by the user.
    cprintf("%.*s", len, s);
}
```
```
// kern/kdebug.c
// debuginfo_eip 函数中加入内存检查

int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
    // ...

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
        if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) < 0) {
            return -1;
        }
		stabs = usd->stabs;
		stab_end = usd->stab_end;
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs, stab_end-stabs, PTE_U) < 0) {
            return -1;
        }
        if (user_mem_check(curenv, (void *)stabstr, stabstr_end-stabstr, PTE_U) < 0) {
            return -1;
        }

    // ...
}
```
