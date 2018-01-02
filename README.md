# mit-lab2
<p>在kern/pmap.c中修改部分代码</p>
## Exercise 1
### boot_alloc()
```
    // Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    result = nextfree;
    nextfree += ROUNDUP(n, PGSIZE);
	return result;
```
### mem_init()
```
    //////////////////////////////////////////////////////////////////////
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
    pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
	memset(pages, 0, npages * sizeof(struct PageInfo));
```
### page_init()
```
    // The example code here marks all physical pages as free.
	// However this is not truly the case.  What memory is free?
	//  1) Mark physical page 0 as in use.
	//     This way we preserve the real-mode IDT and BIOS structures
	//     in case we ever need them.  (Currently we don't, but...)
	//  2) The rest of base memory, [PGSIZE, npages_basemem * PGSIZE)
	//     is free.
	//  3) Then comes the IO hole [IOPHYSMEM, EXTPHYSMEM), which must
	//     never be allocated.
	//  4) Then extended memory [EXTPHYSMEM, ...).
	//     Some of it is in use, some is free. Where is the kernel
	//     in physical memory?  Which pages are already in use for
	//     page tables and other data structures?
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
    size_t i;
    uint32_t pa;
    page_free_list = NULL;

    for(i = 0; i<npages; i++)
    {
        if(i == 0)
        {
            pages[0].pp_ref = 1;
            pages[0].pp_link = NULL;
            continue;
        }
        else if(i < npages_basemem)
        {
            // used for base memory
            pages[i].pp_ref = 0;
            pages[i].pp_link = page_free_list;
            page_free_list = &pages[i];
        }
        else if(i <= (EXTPHYSMEM/PGSIZE) || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT))
        {
            //used for IO memory
            pages[i].pp_ref++;
            pages[i].pp_link = NULL;
        }
        else
        {
            pages[i].pp_ref = 0;
            pages[i].pp_link = page_free_list;
            page_free_list = &pages[i];
        }

        pa = page2pa(&pages[i]);

        if((pa == 0 || (pa < IOPHYSMEM && pa <= ((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT)) && (pages[i].pp_ref == 0))
        {
            cprintf("page error : i %d\n",i);
        }
    }
```
### page_alloc()
```
struct PageInfo *
page_alloc(int alloc_flags)
{
    struct PageInfo* pp = NULL;
    if (!page_free_list)
    {
        return NULL;
    }

    pp = page_free_list;

    page_free_list = page_free_list->pp_link;

    if(alloc_flags & ALLOC_ZERO)
    {
        memset(page2kva(pp), 0, PGSIZE);
    }

	return pp;
}
```
### page_free
```
void
page_free(struct PageInfo *pp)
{
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

    assert(pp->pp_ref == 0 || pp->pp_link == NULL);

    pp->pp_link = page_free_list;
    page_free_list = pp;
}

```
## Exercise 4
### pgdir_walk()
```
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in

    pde_t *pde = NULL;
    pte_t *pgtable = NULL;

    struct PageInfo *pp = NULL;

    pde = &pgdir[PDX(va)];

    if(*pde & PTE_P)
    {
        pgtable = (KADDR(PTE_ADDR(*pde)));
    }
    else
    {
        if(!create ||
            !(pp = page_alloc(ALLOC_ZERO)) ||
            !(pgtable = (pte_t *)page2kva(pp)))
        {
            return NULL;
        }

        pp->pp_ref++;
        *pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
    }

	return &pgtable[PTX(va)];
}
```
### boot_map_region()
```
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    uintptr_t  va_next = va;
    physaddr_t pa_next = pa;
    pte_t       *pte   = NULL;

    ROUNDUP(size, PGSIZE);

    assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));

    int temp = 0;

    for(temp = 0; temp < size/PGSIZE; temp++)
    {
        pte = pgdir_walk(pgdir, (void*)va_next, 1);

        if(!pte)
        {
            return ;
        }

        *pte = PTE_ADDR(pa_next) | perm | PTE_P;
        pa_next += PGSIZE;
        va_next += PGSIZE;
    }
}
```
### page_lookup()
```
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
    pte_t * pte = pgdir_walk(pgdir, va, 0);

    if(!pte)
    {
        return NULL;
    }

    *pte_store = pte;

	return pa2page(PTE_ADDR(*pte));
}

```
### page_remove()
```
void
page_remove(pde_t *pgdir, void *va)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 0);
    pte_t ** pte_store = &pte;

    struct PageInfo *pp = page_lookup(pgdir, va, pte_store);

    if(!pp)
    {
        return ;
    }

    page_decref(pp);
    **pte_store = 0;
    tlb_invalidate(pgdir, va);
}

```
### page_insert()
```
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 0);
    physaddr_t ppa = page2pa(pp);

    if(pte)
    {
        if(*pte & PTE_P)
        {
            page_remove(pgdir, va);
        }

        if(page_free_list == pp)
        {
            page_free_list = page_free_list->pp_link;
        }
    }
    else
    {
        pte = pgdir_walk(pgdir, va, 1);
        if(!pte)
        {
            return -E_NO_MEM;
        }

    }

    *pte = page2pa(pp) | PTE_P | perm;

    pp->pp_ref++;
    tlb_invalidate(pgdir, va);
	return 0;
}
```
## Exercise 5
```
//////////////////////////////////////////////////////////////////////
	// Now we set up virtual memory

	//////////////////////////////////////////////////////////////////////
	// Map 'pages' read-only by the user at linear address UPAGES
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

    boot_map_region(kern_pgdir,
                    UPAGES,
                    ROUNDUP((sizeof(struct PageInfo) * npages), PGSIZE),
                    PADDR(pages),
                    (PTE_U | PTE_P));

	//////////////////////////////////////////////////////////////////////
	// Use the physical memory that 'bootstack' refers to as the kernel
	// stack.  The kernel stack grows down from virtual address KSTACKTOP.
	// We consider the entire range from [KSTACKTOP-PTSIZE, KSTACKTOP)
	// to be the kernel stack, but break this into two pieces:
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    
    boot_map_region(kern_pgdir,
                (KSTACKTOP - KSTKSIZE),
                KSTKSIZE,
                PADDR(bootstack),
                (PTE_W | PTE_P));

	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir,
                KERNBASE,
                ROUNDUP((0xFFFFFFFF - KERNBASE), PGSIZE),
                0,
                (PTE_W) | (PTE_P));
```
