# mit-lab1
### Execsise 8
```
case 'o':
	// Replace this with your code.
	num = getuint(&ap, lflag);
	base = 8;
    goto number;
```
### Execsise 9&10
```
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
        for (int j = 2; j != 7; ++j) {
            cprintf(" %08x", ebp[j]);   
        }
        cprintf("\n");
        ebp = (uint32_t *) (*ebp);
    }
   	return 0;
}
```
### Execsise 11&12
修改debuginfo_eip里的代码段
```
    info->eip_file = stabstr + stabs[lfile].n_strx;
    stab_binsearch(stabs,&lline,&rline,N_SLINE,addr);
    if(lline>rline){
        return -1;
    }else{
        info->eip_line=stabs[lline].n_desc;
    }
```
修改mon_backtrace的代码段
```
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
        for (int j = 2; j != 7; ++j) {
            cprintf(" %08x", ebp[j]);   
        }
        cprintf("\n");
        debuginfo_eip(ebp[1],&info);
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
        ebp = (uint32_t *) (*ebp);
    }
   	return 0;
}
```
