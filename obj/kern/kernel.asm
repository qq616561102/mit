
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 2c 17 f0       	mov    $0xf0172c50,%eax
f010004b:	2d 26 1d 17 f0       	sub    $0xf0171d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 1d 17 f0       	push   $0xf0171d26
f0100058:	e8 b6 43 00 00       	call   f0104413 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 48 10 f0       	push   $0xf01048c0
f010006f:	e8 d5 2f 00 00       	call   f0103049 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 df 10 00 00       	call   f0101158 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 04 2a 00 00       	call   f0102a82 <env_init>
	trap_init();
f010007e:	e8 40 30 00 00       	call   f01030c3 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 c6 fb 12 f0       	push   $0xf012fbc6
f010008d:	e8 99 2b 00 00       	call   f0102c2b <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 8c 1f 17 f0    	pushl  0xf0171f8c
f010009b:	e8 e0 2e 00 00       	call   f0102f80 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 2c 17 f0 00 	cmpl   $0x0,0xf0172c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 2c 17 f0    	mov    %esi,0xf0172c40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 48 10 f0       	push   $0xf01048db
f01000ca:	e8 7a 2f 00 00       	call   f0103049 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 4a 2f 00 00       	call   f0103023 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 f4 56 10 f0 	movl   $0xf01056f4,(%esp)
f01000e0:	e8 64 2f 00 00       	call   f0103049 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 ec 06 00 00       	call   f01007de <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 48 10 f0       	push   $0xf01048f3
f010010c:	e8 38 2f 00 00       	call   f0103049 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 06 2f 00 00       	call   f0103023 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 f4 56 10 f0 	movl   $0xf01056f4,(%esp)
f0100124:	e8 20 2f 00 00       	call   f0103049 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 1f 17 f0    	mov    0xf0171f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 1f 17 f0    	mov    %edx,0xf0171f64
f010016e:	88 81 60 1d 17 f0    	mov    %al,-0xfe8e2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 1f 17 f0 00 	movl   $0x0,0xf0171f64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 1d 17 f0 40 	orl    $0x40,0xf0171d40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 60 4a 10 f0 	movzbl -0xfefb5a0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 1d 17 f0    	mov    %ecx,0xf0171d40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 60 4a 10 f0 	movzbl -0xfefb5a0(%edx),%eax
f0100226:	0b 05 40 1d 17 f0    	or     0xf0171d40,%eax
f010022c:	0f b6 8a 60 49 10 f0 	movzbl -0xfefb6a0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 40 49 10 f0 	mov    -0xfefb6c0(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 0d 49 10 f0       	push   $0xf010490d
f0100282:	e8 c2 2d 00 00       	call   f0103049 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 1f 17 f0 	addw   $0x50,0xf0171f68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 1f 17 f0 	mov    %dx,0xf0171f68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 1f 17 f0 	cmpw   $0x7cf,0xf0171f68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c 1f 17 f0       	mov    0xf0171f6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 2a 40 00 00       	call   f0104460 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 1f 17 f0 	subw   $0x50,0xf0171f68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 1f 17 f0    	mov    0xf0171f70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 1f 17 f0 	movzwl 0xf0171f68,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 1f 17 f0 00 	cmpb   $0x0,0xf0171f74
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 1f 17 f0       	mov    0xf0171f60,%eax
f01004d8:	3b 05 64 1f 17 f0    	cmp    0xf0171f64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 1f 17 f0    	mov    %edx,0xf0171f60
f01004e9:	0f b6 88 60 1d 17 f0 	movzbl -0xfe8e2a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 1f 17 f0 00 	movl   $0x0,0xf0171f60
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 1f 17 f0 b4 	movl   $0x3b4,0xf0171f70
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 1f 17 f0 d4 	movl   $0x3d4,0xf0171f70
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 1f 17 f0    	mov    0xf0171f70,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c 1f 17 f0    	mov    %esi,0xf0171f6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 1f 17 f0 	setne  0xf0171f74
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 19 49 10 f0       	push   $0xf0104919
f0100605:	e8 3f 2a 00 00       	call   f0103049 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 60 4b 10 f0       	push   $0xf0104b60
f010064b:	68 7e 4b 10 f0       	push   $0xf0104b7e
f0100650:	68 83 4b 10 f0       	push   $0xf0104b83
f0100655:	e8 ef 29 00 00       	call   f0103049 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 4c 4c 10 f0       	push   $0xf0104c4c
f0100662:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100667:	68 83 4b 10 f0       	push   $0xf0104b83
f010066c:	e8 d8 29 00 00       	call   f0103049 <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 95 4b 10 f0       	push   $0xf0104b95
f0100679:	68 ac 4b 10 f0       	push   $0xf0104bac
f010067e:	68 83 4b 10 f0       	push   $0xf0104b83
f0100683:	e8 c1 29 00 00       	call   f0103049 <cprintf>
	return 0;
}
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100695:	68 b6 4b 10 f0       	push   $0xf0104bb6
f010069a:	e8 aa 29 00 00       	call   f0103049 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 74 4c 10 f0       	push   $0xf0104c74
f01006ac:	e8 98 29 00 00       	call   f0103049 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 9c 4c 10 f0       	push   $0xf0104c9c
f01006c3:	e8 81 29 00 00       	call   f0103049 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 a1 48 10 00       	push   $0x1048a1
f01006d0:	68 a1 48 10 f0       	push   $0xf01048a1
f01006d5:	68 c0 4c 10 f0       	push   $0xf0104cc0
f01006da:	e8 6a 29 00 00       	call   f0103049 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 1d 17 00       	push   $0x171d26
f01006e7:	68 26 1d 17 f0       	push   $0xf0171d26
f01006ec:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01006f1:	e8 53 29 00 00       	call   f0103049 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 2c 17 00       	push   $0x172c50
f01006fe:	68 50 2c 17 f0       	push   $0xf0172c50
f0100703:	68 08 4d 10 f0       	push   $0xf0104d08
f0100708:	e8 3c 29 00 00       	call   f0103049 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 30 17 f0       	mov    $0xf017304f,%eax
f0100712:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100717:	83 c4 08             	add    $0x8,%esp
f010071a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010071f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100725:	85 c0                	test   %eax,%eax
f0100727:	0f 48 c2             	cmovs  %edx,%eax
f010072a:	c1 f8 0a             	sar    $0xa,%eax
f010072d:	50                   	push   %eax
f010072e:	68 2c 4d 10 f0       	push   $0xf0104d2c
f0100733:	e8 11 29 00 00       	call   f0103049 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100748:	89 ee                	mov    %ebp,%esi
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
f010074a:	68 cf 4b 10 f0       	push   $0xf0104bcf
f010074f:	e8 f5 28 00 00       	call   f0103049 <cprintf>
    while (ebp) {
f0100754:	83 c4 10             	add    $0x10,%esp
f0100757:	eb 74                	jmp    f01007cd <mon_backtrace+0x8e>
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
f0100759:	83 ec 04             	sub    $0x4,%esp
f010075c:	ff 76 04             	pushl  0x4(%esi)
f010075f:	56                   	push   %esi
f0100760:	68 e1 4b 10 f0       	push   $0xf0104be1
f0100765:	e8 df 28 00 00       	call   f0103049 <cprintf>
f010076a:	8d 5e 08             	lea    0x8(%esi),%ebx
f010076d:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100770:	83 c4 10             	add    $0x10,%esp
        for (int j = 2; j != 7; ++j) {
            cprintf(" %08x", ebp[j]);  
f0100773:	83 ec 08             	sub    $0x8,%esp
f0100776:	ff 33                	pushl  (%ebx)
f0100778:	68 fa 4b 10 f0       	push   $0xf0104bfa
f010077d:	e8 c7 28 00 00       	call   f0103049 <cprintf>
f0100782:	83 c3 04             	add    $0x4,%ebx
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
        for (int j = 2; j != 7; ++j) {
f0100785:	83 c4 10             	add    $0x10,%esp
f0100788:	39 fb                	cmp    %edi,%ebx
f010078a:	75 e7                	jne    f0100773 <mon_backtrace+0x34>
            cprintf(" %08x", ebp[j]);  
        }
        cprintf("\n");
f010078c:	83 ec 0c             	sub    $0xc,%esp
f010078f:	68 f4 56 10 f0       	push   $0xf01056f4
f0100794:	e8 b0 28 00 00       	call   f0103049 <cprintf>
        debuginfo_eip(ebp[1],&info);
f0100799:	83 c4 08             	add    $0x8,%esp
f010079c:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010079f:	50                   	push   %eax
f01007a0:	ff 76 04             	pushl  0x4(%esi)
f01007a3:	e8 12 32 00 00       	call   f01039ba <debuginfo_eip>
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
f01007a8:	83 c4 08             	add    $0x8,%esp
f01007ab:	8b 46 04             	mov    0x4(%esi),%eax
f01007ae:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007b1:	50                   	push   %eax
f01007b2:	ff 75 d8             	pushl  -0x28(%ebp)
f01007b5:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007bb:	ff 75 d0             	pushl  -0x30(%ebp)
f01007be:	68 00 4c 10 f0       	push   $0xf0104c00
f01007c3:	e8 81 28 00 00       	call   f0103049 <cprintf>
        ebp = (uint32_t *) (*ebp);
f01007c8:	8b 36                	mov    (%esi),%esi
f01007ca:	83 c4 20             	add    $0x20,%esp
{
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
f01007cd:	85 f6                	test   %esi,%esi
f01007cf:	75 88                	jne    f0100759 <mon_backtrace+0x1a>
        debuginfo_eip(ebp[1],&info);
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
        ebp = (uint32_t *) (*ebp);
    }
       return 0;
}
f01007d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007d9:	5b                   	pop    %ebx
f01007da:	5e                   	pop    %esi
f01007db:	5f                   	pop    %edi
f01007dc:	5d                   	pop    %ebp
f01007dd:	c3                   	ret    

f01007de <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007de:	55                   	push   %ebp
f01007df:	89 e5                	mov    %esp,%ebp
f01007e1:	57                   	push   %edi
f01007e2:	56                   	push   %esi
f01007e3:	53                   	push   %ebx
f01007e4:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e7:	68 58 4d 10 f0       	push   $0xf0104d58
f01007ec:	e8 58 28 00 00       	call   f0103049 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f1:	c7 04 24 7c 4d 10 f0 	movl   $0xf0104d7c,(%esp)
f01007f8:	e8 4c 28 00 00       	call   f0103049 <cprintf>

	if (tf != NULL)
f01007fd:	83 c4 10             	add    $0x10,%esp
f0100800:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100804:	74 0e                	je     f0100814 <monitor+0x36>
		print_trapframe(tf);
f0100806:	83 ec 0c             	sub    $0xc,%esp
f0100809:	ff 75 08             	pushl  0x8(%ebp)
f010080c:	e8 7b 2c 00 00       	call   f010348c <print_trapframe>
f0100811:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100814:	83 ec 0c             	sub    $0xc,%esp
f0100817:	68 10 4c 10 f0       	push   $0xf0104c10
f010081c:	e8 9b 39 00 00       	call   f01041bc <readline>
f0100821:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100823:	83 c4 10             	add    $0x10,%esp
f0100826:	85 c0                	test   %eax,%eax
f0100828:	74 ea                	je     f0100814 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010082a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100831:	be 00 00 00 00       	mov    $0x0,%esi
f0100836:	eb 0a                	jmp    f0100842 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100838:	c6 03 00             	movb   $0x0,(%ebx)
f010083b:	89 f7                	mov    %esi,%edi
f010083d:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100840:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100842:	0f b6 03             	movzbl (%ebx),%eax
f0100845:	84 c0                	test   %al,%al
f0100847:	74 63                	je     f01008ac <monitor+0xce>
f0100849:	83 ec 08             	sub    $0x8,%esp
f010084c:	0f be c0             	movsbl %al,%eax
f010084f:	50                   	push   %eax
f0100850:	68 14 4c 10 f0       	push   $0xf0104c14
f0100855:	e8 7c 3b 00 00       	call   f01043d6 <strchr>
f010085a:	83 c4 10             	add    $0x10,%esp
f010085d:	85 c0                	test   %eax,%eax
f010085f:	75 d7                	jne    f0100838 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100861:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100864:	74 46                	je     f01008ac <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100866:	83 fe 0f             	cmp    $0xf,%esi
f0100869:	75 14                	jne    f010087f <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086b:	83 ec 08             	sub    $0x8,%esp
f010086e:	6a 10                	push   $0x10
f0100870:	68 19 4c 10 f0       	push   $0xf0104c19
f0100875:	e8 cf 27 00 00       	call   f0103049 <cprintf>
f010087a:	83 c4 10             	add    $0x10,%esp
f010087d:	eb 95                	jmp    f0100814 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010087f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100882:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100886:	eb 03                	jmp    f010088b <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100888:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010088b:	0f b6 03             	movzbl (%ebx),%eax
f010088e:	84 c0                	test   %al,%al
f0100890:	74 ae                	je     f0100840 <monitor+0x62>
f0100892:	83 ec 08             	sub    $0x8,%esp
f0100895:	0f be c0             	movsbl %al,%eax
f0100898:	50                   	push   %eax
f0100899:	68 14 4c 10 f0       	push   $0xf0104c14
f010089e:	e8 33 3b 00 00       	call   f01043d6 <strchr>
f01008a3:	83 c4 10             	add    $0x10,%esp
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	74 de                	je     f0100888 <monitor+0xaa>
f01008aa:	eb 94                	jmp    f0100840 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008ac:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b3:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b4:	85 f6                	test   %esi,%esi
f01008b6:	0f 84 58 ff ff ff    	je     f0100814 <monitor+0x36>
f01008bc:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c1:	83 ec 08             	sub    $0x8,%esp
f01008c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c7:	ff 34 85 c0 4d 10 f0 	pushl  -0xfefb240(,%eax,4)
f01008ce:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d1:	e8 a2 3a 00 00       	call   f0104378 <strcmp>
f01008d6:	83 c4 10             	add    $0x10,%esp
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	75 21                	jne    f01008fe <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008dd:	83 ec 04             	sub    $0x4,%esp
f01008e0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e3:	ff 75 08             	pushl  0x8(%ebp)
f01008e6:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008e9:	52                   	push   %edx
f01008ea:	56                   	push   %esi
f01008eb:	ff 14 85 c8 4d 10 f0 	call   *-0xfefb238(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f2:	83 c4 10             	add    $0x10,%esp
f01008f5:	85 c0                	test   %eax,%eax
f01008f7:	78 25                	js     f010091e <monitor+0x140>
f01008f9:	e9 16 ff ff ff       	jmp    f0100814 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008fe:	83 c3 01             	add    $0x1,%ebx
f0100901:	83 fb 03             	cmp    $0x3,%ebx
f0100904:	75 bb                	jne    f01008c1 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100906:	83 ec 08             	sub    $0x8,%esp
f0100909:	ff 75 a8             	pushl  -0x58(%ebp)
f010090c:	68 36 4c 10 f0       	push   $0xf0104c36
f0100911:	e8 33 27 00 00       	call   f0103049 <cprintf>
f0100916:	83 c4 10             	add    $0x10,%esp
f0100919:	e9 f6 fe ff ff       	jmp    f0100814 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010091e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100921:	5b                   	pop    %ebx
f0100922:	5e                   	pop    %esi
f0100923:	5f                   	pop    %edi
f0100924:	5d                   	pop    %ebp
f0100925:	c3                   	ret    

f0100926 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100926:	55                   	push   %ebp
f0100927:	89 e5                	mov    %esp,%ebp
f0100929:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010092b:	83 3d 78 1f 17 f0 00 	cmpl   $0x0,0xf0171f78
f0100932:	75 0f                	jne    f0100943 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100934:	b8 4f 3c 17 f0       	mov    $0xf0173c4f,%eax
f0100939:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010093e:	a3 78 1f 17 f0       	mov    %eax,0xf0171f78
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

    result = nextfree;
f0100943:	a1 78 1f 17 f0       	mov    0xf0171f78,%eax

    nextfree += ROUNDUP(n, PGSIZE);
f0100948:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010094e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100954:	01 c2                	add    %eax,%edx
f0100956:	89 15 78 1f 17 f0    	mov    %edx,0xf0171f78



	return result;
}
f010095c:	5d                   	pop    %ebp
f010095d:	c3                   	ret    

f010095e <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010095e:	55                   	push   %ebp
f010095f:	89 e5                	mov    %esp,%ebp
f0100961:	56                   	push   %esi
f0100962:	53                   	push   %ebx
f0100963:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100965:	83 ec 0c             	sub    $0xc,%esp
f0100968:	50                   	push   %eax
f0100969:	e8 74 26 00 00       	call   f0102fe2 <mc146818_read>
f010096e:	89 c6                	mov    %eax,%esi
f0100970:	83 c3 01             	add    $0x1,%ebx
f0100973:	89 1c 24             	mov    %ebx,(%esp)
f0100976:	e8 67 26 00 00       	call   f0102fe2 <mc146818_read>
f010097b:	c1 e0 08             	shl    $0x8,%eax
f010097e:	09 f0                	or     %esi,%eax
}
f0100980:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100983:	5b                   	pop    %ebx
f0100984:	5e                   	pop    %esi
f0100985:	5d                   	pop    %ebp
f0100986:	c3                   	ret    

f0100987 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100987:	89 d1                	mov    %edx,%ecx
f0100989:	c1 e9 16             	shr    $0x16,%ecx
f010098c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010098f:	a8 01                	test   $0x1,%al
f0100991:	74 52                	je     f01009e5 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100993:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100998:	89 c1                	mov    %eax,%ecx
f010099a:	c1 e9 0c             	shr    $0xc,%ecx
f010099d:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f01009a3:	72 1b                	jb     f01009c0 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009a5:	55                   	push   %ebp
f01009a6:	89 e5                	mov    %esp,%ebp
f01009a8:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009ab:	50                   	push   %eax
f01009ac:	68 e4 4d 10 f0       	push   $0xf0104de4
f01009b1:	68 23 04 00 00       	push   $0x423
f01009b6:	68 21 56 10 f0       	push   $0xf0105621
f01009bb:	e8 e0 f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009c0:	c1 ea 0c             	shr    $0xc,%edx
f01009c3:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009c9:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009d0:	89 c2                	mov    %eax,%edx
f01009d2:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009da:	85 d2                	test   %edx,%edx
f01009dc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009e1:	0f 44 c2             	cmove  %edx,%eax
f01009e4:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009ea:	c3                   	ret    

f01009eb <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009eb:	55                   	push   %ebp
f01009ec:	89 e5                	mov    %esp,%ebp
f01009ee:	57                   	push   %edi
f01009ef:	56                   	push   %esi
f01009f0:	53                   	push   %ebx
f01009f1:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f4:	84 c0                	test   %al,%al
f01009f6:	0f 85 81 02 00 00    	jne    f0100c7d <check_page_free_list+0x292>
f01009fc:	e9 8e 02 00 00       	jmp    f0100c8f <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a01:	83 ec 04             	sub    $0x4,%esp
f0100a04:	68 08 4e 10 f0       	push   $0xf0104e08
f0100a09:	68 5f 03 00 00       	push   $0x35f
f0100a0e:	68 21 56 10 f0       	push   $0xf0105621
f0100a13:	e8 88 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a18:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a1b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a21:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a24:	89 c2                	mov    %eax,%edx
f0100a26:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100a2c:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a32:	0f 95 c2             	setne  %dl
f0100a35:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a38:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a3c:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a3e:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a42:	8b 00                	mov    (%eax),%eax
f0100a44:	85 c0                	test   %eax,%eax
f0100a46:	75 dc                	jne    f0100a24 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a4b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a51:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a54:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a57:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a59:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a5c:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a61:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a66:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100a6c:	eb 53                	jmp    f0100ac1 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a6e:	89 d8                	mov    %ebx,%eax
f0100a70:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100a76:	c1 f8 03             	sar    $0x3,%eax
f0100a79:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a7c:	89 c2                	mov    %eax,%edx
f0100a7e:	c1 ea 16             	shr    $0x16,%edx
f0100a81:	39 f2                	cmp    %esi,%edx
f0100a83:	73 3a                	jae    f0100abf <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a85:	89 c2                	mov    %eax,%edx
f0100a87:	c1 ea 0c             	shr    $0xc,%edx
f0100a8a:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100a90:	72 12                	jb     f0100aa4 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a92:	50                   	push   %eax
f0100a93:	68 e4 4d 10 f0       	push   $0xf0104de4
f0100a98:	6a 56                	push   $0x56
f0100a9a:	68 2d 56 10 f0       	push   $0xf010562d
f0100a9f:	e8 fc f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa4:	83 ec 04             	sub    $0x4,%esp
f0100aa7:	68 80 00 00 00       	push   $0x80
f0100aac:	68 97 00 00 00       	push   $0x97
f0100ab1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ab6:	50                   	push   %eax
f0100ab7:	e8 57 39 00 00       	call   f0104413 <memset>
f0100abc:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abf:	8b 1b                	mov    (%ebx),%ebx
f0100ac1:	85 db                	test   %ebx,%ebx
f0100ac3:	75 a9                	jne    f0100a6e <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ac5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aca:	e8 57 fe ff ff       	call   f0100926 <boot_alloc>
f0100acf:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad2:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad8:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
		assert(pp < pages + npages);
f0100ade:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0100ae3:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ae6:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aec:	be 00 00 00 00       	mov    $0x0,%esi
f0100af1:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af4:	e9 30 01 00 00       	jmp    f0100c29 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100af9:	39 ca                	cmp    %ecx,%edx
f0100afb:	73 19                	jae    f0100b16 <check_page_free_list+0x12b>
f0100afd:	68 3b 56 10 f0       	push   $0xf010563b
f0100b02:	68 47 56 10 f0       	push   $0xf0105647
f0100b07:	68 79 03 00 00       	push   $0x379
f0100b0c:	68 21 56 10 f0       	push   $0xf0105621
f0100b11:	e8 8a f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b16:	39 fa                	cmp    %edi,%edx
f0100b18:	72 19                	jb     f0100b33 <check_page_free_list+0x148>
f0100b1a:	68 5c 56 10 f0       	push   $0xf010565c
f0100b1f:	68 47 56 10 f0       	push   $0xf0105647
f0100b24:	68 7a 03 00 00       	push   $0x37a
f0100b29:	68 21 56 10 f0       	push   $0xf0105621
f0100b2e:	e8 6d f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b33:	89 d0                	mov    %edx,%eax
f0100b35:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b38:	a8 07                	test   $0x7,%al
f0100b3a:	74 19                	je     f0100b55 <check_page_free_list+0x16a>
f0100b3c:	68 2c 4e 10 f0       	push   $0xf0104e2c
f0100b41:	68 47 56 10 f0       	push   $0xf0105647
f0100b46:	68 7b 03 00 00       	push   $0x37b
f0100b4b:	68 21 56 10 f0       	push   $0xf0105621
f0100b50:	e8 4b f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b55:	c1 f8 03             	sar    $0x3,%eax
f0100b58:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b5b:	85 c0                	test   %eax,%eax
f0100b5d:	75 19                	jne    f0100b78 <check_page_free_list+0x18d>
f0100b5f:	68 70 56 10 f0       	push   $0xf0105670
f0100b64:	68 47 56 10 f0       	push   $0xf0105647
f0100b69:	68 7e 03 00 00       	push   $0x37e
f0100b6e:	68 21 56 10 f0       	push   $0xf0105621
f0100b73:	e8 28 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b78:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b7d:	75 19                	jne    f0100b98 <check_page_free_list+0x1ad>
f0100b7f:	68 81 56 10 f0       	push   $0xf0105681
f0100b84:	68 47 56 10 f0       	push   $0xf0105647
f0100b89:	68 7f 03 00 00       	push   $0x37f
f0100b8e:	68 21 56 10 f0       	push   $0xf0105621
f0100b93:	e8 08 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b98:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b9d:	75 19                	jne    f0100bb8 <check_page_free_list+0x1cd>
f0100b9f:	68 60 4e 10 f0       	push   $0xf0104e60
f0100ba4:	68 47 56 10 f0       	push   $0xf0105647
f0100ba9:	68 80 03 00 00       	push   $0x380
f0100bae:	68 21 56 10 f0       	push   $0xf0105621
f0100bb3:	e8 e8 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bb8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bbd:	75 19                	jne    f0100bd8 <check_page_free_list+0x1ed>
f0100bbf:	68 9a 56 10 f0       	push   $0xf010569a
f0100bc4:	68 47 56 10 f0       	push   $0xf0105647
f0100bc9:	68 81 03 00 00       	push   $0x381
f0100bce:	68 21 56 10 f0       	push   $0xf0105621
f0100bd3:	e8 c8 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bd8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bdd:	76 3f                	jbe    f0100c1e <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bdf:	89 c3                	mov    %eax,%ebx
f0100be1:	c1 eb 0c             	shr    $0xc,%ebx
f0100be4:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100be7:	77 12                	ja     f0100bfb <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be9:	50                   	push   %eax
f0100bea:	68 e4 4d 10 f0       	push   $0xf0104de4
f0100bef:	6a 56                	push   $0x56
f0100bf1:	68 2d 56 10 f0       	push   $0xf010562d
f0100bf6:	e8 a5 f4 ff ff       	call   f01000a0 <_panic>
f0100bfb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c00:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c03:	76 1e                	jbe    f0100c23 <check_page_free_list+0x238>
f0100c05:	68 84 4e 10 f0       	push   $0xf0104e84
f0100c0a:	68 47 56 10 f0       	push   $0xf0105647
f0100c0f:	68 82 03 00 00       	push   $0x382
f0100c14:	68 21 56 10 f0       	push   $0xf0105621
f0100c19:	e8 82 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c1e:	83 c6 01             	add    $0x1,%esi
f0100c21:	eb 04                	jmp    f0100c27 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c23:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c27:	8b 12                	mov    (%edx),%edx
f0100c29:	85 d2                	test   %edx,%edx
f0100c2b:	0f 85 c8 fe ff ff    	jne    f0100af9 <check_page_free_list+0x10e>
f0100c31:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c34:	85 f6                	test   %esi,%esi
f0100c36:	7f 19                	jg     f0100c51 <check_page_free_list+0x266>
f0100c38:	68 b4 56 10 f0       	push   $0xf01056b4
f0100c3d:	68 47 56 10 f0       	push   $0xf0105647
f0100c42:	68 8a 03 00 00       	push   $0x38a
f0100c47:	68 21 56 10 f0       	push   $0xf0105621
f0100c4c:	e8 4f f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c51:	85 db                	test   %ebx,%ebx
f0100c53:	7f 19                	jg     f0100c6e <check_page_free_list+0x283>
f0100c55:	68 c6 56 10 f0       	push   $0xf01056c6
f0100c5a:	68 47 56 10 f0       	push   $0xf0105647
f0100c5f:	68 8b 03 00 00       	push   $0x38b
f0100c64:	68 21 56 10 f0       	push   $0xf0105621
f0100c69:	e8 32 f4 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c6e:	83 ec 0c             	sub    $0xc,%esp
f0100c71:	68 cc 4e 10 f0       	push   $0xf0104ecc
f0100c76:	e8 ce 23 00 00       	call   f0103049 <cprintf>
}
f0100c7b:	eb 29                	jmp    f0100ca6 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c7d:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0100c82:	85 c0                	test   %eax,%eax
f0100c84:	0f 85 8e fd ff ff    	jne    f0100a18 <check_page_free_list+0x2d>
f0100c8a:	e9 72 fd ff ff       	jmp    f0100a01 <check_page_free_list+0x16>
f0100c8f:	83 3d 80 1f 17 f0 00 	cmpl   $0x0,0xf0171f80
f0100c96:	0f 84 65 fd ff ff    	je     f0100a01 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c9c:	be 00 04 00 00       	mov    $0x400,%esi
f0100ca1:	e9 c0 fd ff ff       	jmp    f0100a66 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100ca6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ca9:	5b                   	pop    %ebx
f0100caa:	5e                   	pop    %esi
f0100cab:	5f                   	pop    %edi
f0100cac:	5d                   	pop    %ebp
f0100cad:	c3                   	ret    

f0100cae <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cae:	55                   	push   %ebp
f0100caf:	89 e5                	mov    %esp,%ebp
f0100cb1:	57                   	push   %edi
f0100cb2:	56                   	push   %esi
f0100cb3:	53                   	push   %ebx
f0100cb4:	83 ec 0c             	sub    $0xc,%esp
	// free pages!
	size_t i;

    uint32_t pa;

    page_free_list = NULL;
f0100cb7:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0100cbe:	00 00 00 



    for(i = 0; i<npages; i++)
f0100cc1:	be 00 00 00 00       	mov    $0x0,%esi
f0100cc6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ccb:	e9 eb 00 00 00       	jmp    f0100dbb <page_init+0x10d>

    {

        if(i == 0)
f0100cd0:	85 db                	test   %ebx,%ebx
f0100cd2:	75 16                	jne    f0100cea <page_init+0x3c>

        {

            pages[0].pp_ref = 1;
f0100cd4:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100cd9:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

            pages[0].pp_link = NULL;
f0100cdf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

            continue;
f0100ce5:	e9 cb 00 00 00       	jmp    f0100db5 <page_init+0x107>

        }

        else if(i < npages_basemem)
f0100cea:	3b 1d 84 1f 17 f0    	cmp    0xf0171f84,%ebx
f0100cf0:	73 25                	jae    f0100d17 <page_init+0x69>

        {

            // used for base memory

            pages[i].pp_ref = 0;
f0100cf2:	89 f0                	mov    %esi,%eax
f0100cf4:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100cfa:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

            pages[i].pp_link = page_free_list;
f0100d00:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100d06:	89 10                	mov    %edx,(%eax)

            page_free_list = &pages[i];
f0100d08:	89 f0                	mov    %esi,%eax
f0100d0a:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d10:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
f0100d15:	eb 56                	jmp    f0100d6d <page_init+0xbf>

        }

        else if(i <= (EXTPHYSMEM/PGSIZE) || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT))
f0100d17:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100d1d:	76 16                	jbe    f0100d35 <page_init+0x87>
f0100d1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d24:	e8 fd fb ff ff       	call   f0100926 <boot_alloc>
f0100d29:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d2e:	c1 e8 0c             	shr    $0xc,%eax
f0100d31:	39 c3                	cmp    %eax,%ebx
f0100d33:	73 15                	jae    f0100d4a <page_init+0x9c>

        {

            //used for IO memory

            pages[i].pp_ref++;
f0100d35:	89 f0                	mov    %esi,%eax
f0100d37:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d3d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

            pages[i].pp_link = NULL;
f0100d42:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d48:	eb 23                	jmp    f0100d6d <page_init+0xbf>

        else

        {

            pages[i].pp_ref = 0;
f0100d4a:	89 f0                	mov    %esi,%eax
f0100d4c:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d52:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

            pages[i].pp_link = page_free_list;
f0100d58:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100d5e:	89 10                	mov    %edx,(%eax)

            page_free_list = &pages[i];
f0100d60:	89 f0                	mov    %esi,%eax
f0100d62:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d68:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d6d:	89 f7                	mov    %esi,%edi
f0100d6f:	c1 ff 03             	sar    $0x3,%edi
f0100d72:	c1 e7 0c             	shl    $0xc,%edi

        pa = page2pa(&pages[i]);



        if((pa == 0 || (pa < IOPHYSMEM && pa <= ((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT)) && (pages[i].pp_ref == 0))
f0100d75:	85 ff                	test   %edi,%edi
f0100d77:	74 1e                	je     f0100d97 <page_init+0xe9>
f0100d79:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100d7f:	77 34                	ja     f0100db5 <page_init+0x107>
f0100d81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d86:	e8 9b fb ff ff       	call   f0100926 <boot_alloc>
f0100d8b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d90:	c1 e8 0c             	shr    $0xc,%eax
f0100d93:	39 f8                	cmp    %edi,%eax
f0100d95:	72 1e                	jb     f0100db5 <page_init+0x107>
f0100d97:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d9c:	66 83 7c 30 04 00    	cmpw   $0x0,0x4(%eax,%esi,1)
f0100da2:	75 11                	jne    f0100db5 <page_init+0x107>

        {

            cprintf("page error : i %d\n",i);
f0100da4:	83 ec 08             	sub    $0x8,%esp
f0100da7:	53                   	push   %ebx
f0100da8:	68 d7 56 10 f0       	push   $0xf01056d7
f0100dad:	e8 97 22 00 00       	call   f0103049 <cprintf>
f0100db2:	83 c4 10             	add    $0x10,%esp

    page_free_list = NULL;



    for(i = 0; i<npages; i++)
f0100db5:	83 c3 01             	add    $0x1,%ebx
f0100db8:	83 c6 08             	add    $0x8,%esi
f0100dbb:	3b 1d 44 2c 17 f0    	cmp    0xf0172c44,%ebx
f0100dc1:	0f 82 09 ff ff ff    	jb     f0100cd0 <page_init+0x22>
            cprintf("page error : i %d\n",i);

        }

    }
}
f0100dc7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dca:	5b                   	pop    %ebx
f0100dcb:	5e                   	pop    %esi
f0100dcc:	5f                   	pop    %edi
f0100dcd:	5d                   	pop    %ebp
f0100dce:	c3                   	ret    

f0100dcf <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dcf:	55                   	push   %ebp
f0100dd0:	89 e5                	mov    %esp,%ebp
f0100dd2:	53                   	push   %ebx
f0100dd3:	83 ec 04             	sub    $0x4,%esp
	struct PageInfo* pp = NULL;

    if (!page_free_list)
f0100dd6:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100ddc:	85 db                	test   %ebx,%ebx
f0100dde:	74 52                	je     f0100e32 <page_alloc+0x63>

    pp = page_free_list;



    page_free_list = page_free_list->pp_link;
f0100de0:	8b 03                	mov    (%ebx),%eax
f0100de2:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80



    if(alloc_flags & ALLOC_ZERO)
f0100de7:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100deb:	74 45                	je     f0100e32 <page_alloc+0x63>
f0100ded:	89 d8                	mov    %ebx,%eax
f0100def:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100df5:	c1 f8 03             	sar    $0x3,%eax
f0100df8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dfb:	89 c2                	mov    %eax,%edx
f0100dfd:	c1 ea 0c             	shr    $0xc,%edx
f0100e00:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100e06:	72 12                	jb     f0100e1a <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e08:	50                   	push   %eax
f0100e09:	68 e4 4d 10 f0       	push   $0xf0104de4
f0100e0e:	6a 56                	push   $0x56
f0100e10:	68 2d 56 10 f0       	push   $0xf010562d
f0100e15:	e8 86 f2 ff ff       	call   f01000a0 <_panic>

    {

        memset(page2kva(pp), 0, PGSIZE);
f0100e1a:	83 ec 04             	sub    $0x4,%esp
f0100e1d:	68 00 10 00 00       	push   $0x1000
f0100e22:	6a 00                	push   $0x0
f0100e24:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e29:	50                   	push   %eax
f0100e2a:	e8 e4 35 00 00       	call   f0104413 <memset>
f0100e2f:	83 c4 10             	add    $0x10,%esp
    }



	return pp;
}
f0100e32:	89 d8                	mov    %ebx,%eax
f0100e34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e37:	c9                   	leave  
f0100e38:	c3                   	ret    

f0100e39 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e39:	55                   	push   %ebp
f0100e3a:	89 e5                	mov    %esp,%ebp
f0100e3c:	83 ec 08             	sub    $0x8,%esp
f0100e3f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
assert(pp->pp_ref == 0 || pp->pp_link == NULL);
f0100e42:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e47:	74 1e                	je     f0100e67 <page_free+0x2e>
f0100e49:	83 38 00             	cmpl   $0x0,(%eax)
f0100e4c:	74 19                	je     f0100e67 <page_free+0x2e>
f0100e4e:	68 f0 4e 10 f0       	push   $0xf0104ef0
f0100e53:	68 47 56 10 f0       	push   $0xf0105647
f0100e58:	68 bd 01 00 00       	push   $0x1bd
f0100e5d:	68 21 56 10 f0       	push   $0xf0105621
f0100e62:	e8 39 f2 ff ff       	call   f01000a0 <_panic>



    pp->pp_link = page_free_list;
f0100e67:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100e6d:	89 10                	mov    %edx,(%eax)

    page_free_list = pp;
f0100e6f:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
}
f0100e74:	c9                   	leave  
f0100e75:	c3                   	ret    

f0100e76 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e76:	55                   	push   %ebp
f0100e77:	89 e5                	mov    %esp,%ebp
f0100e79:	83 ec 08             	sub    $0x8,%esp
f0100e7c:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e7f:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e83:	83 e8 01             	sub    $0x1,%eax
f0100e86:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e8a:	66 85 c0             	test   %ax,%ax
f0100e8d:	75 0c                	jne    f0100e9b <page_decref+0x25>
		page_free(pp);
f0100e8f:	83 ec 0c             	sub    $0xc,%esp
f0100e92:	52                   	push   %edx
f0100e93:	e8 a1 ff ff ff       	call   f0100e39 <page_free>
f0100e98:	83 c4 10             	add    $0x10,%esp
}
f0100e9b:	c9                   	leave  
f0100e9c:	c3                   	ret    

f0100e9d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e9d:	55                   	push   %ebp
f0100e9e:	89 e5                	mov    %esp,%ebp
f0100ea0:	57                   	push   %edi
f0100ea1:	56                   	push   %esi
f0100ea2:	53                   	push   %ebx
f0100ea3:	83 ec 0c             	sub    $0xc,%esp
f0100ea6:	8b 5d 0c             	mov    0xc(%ebp),%ebx

    struct PageInfo *pp = NULL;



    pde = &pgdir[PDX(va)];
f0100ea9:	89 de                	mov    %ebx,%esi
f0100eab:	c1 ee 16             	shr    $0x16,%esi
f0100eae:	c1 e6 02             	shl    $0x2,%esi
f0100eb1:	03 75 08             	add    0x8(%ebp),%esi



    if(*pde & PTE_P)
f0100eb4:	8b 06                	mov    (%esi),%eax
f0100eb6:	a8 01                	test   $0x1,%al
f0100eb8:	74 2f                	je     f0100ee9 <pgdir_walk+0x4c>

    {

        pgtable = (KADDR(PTE_ADDR(*pde)));
f0100eba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ebf:	89 c2                	mov    %eax,%edx
f0100ec1:	c1 ea 0c             	shr    $0xc,%edx
f0100ec4:	39 15 44 2c 17 f0    	cmp    %edx,0xf0172c44
f0100eca:	77 15                	ja     f0100ee1 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ecc:	50                   	push   %eax
f0100ecd:	68 e4 4d 10 f0       	push   $0xf0104de4
f0100ed2:	68 fd 01 00 00       	push   $0x1fd
f0100ed7:	68 21 56 10 f0       	push   $0xf0105621
f0100edc:	e8 bf f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100ee1:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100ee7:	eb 77                	jmp    f0100f60 <pgdir_walk+0xc3>

    else

    {

        if(!create ||
f0100ee9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100eed:	74 7f                	je     f0100f6e <pgdir_walk+0xd1>
f0100eef:	83 ec 0c             	sub    $0xc,%esp
f0100ef2:	6a 01                	push   $0x1
f0100ef4:	e8 d6 fe ff ff       	call   f0100dcf <page_alloc>
f0100ef9:	83 c4 10             	add    $0x10,%esp
f0100efc:	85 c0                	test   %eax,%eax
f0100efe:	74 75                	je     f0100f75 <pgdir_walk+0xd8>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f00:	89 c1                	mov    %eax,%ecx
f0100f02:	2b 0d 4c 2c 17 f0    	sub    0xf0172c4c,%ecx
f0100f08:	c1 f9 03             	sar    $0x3,%ecx
f0100f0b:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f0e:	89 ca                	mov    %ecx,%edx
f0100f10:	c1 ea 0c             	shr    $0xc,%edx
f0100f13:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100f19:	72 12                	jb     f0100f2d <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f1b:	51                   	push   %ecx
f0100f1c:	68 e4 4d 10 f0       	push   $0xf0104de4
f0100f21:	6a 56                	push   $0x56
f0100f23:	68 2d 56 10 f0       	push   $0xf010562d
f0100f28:	e8 73 f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100f2d:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100f33:	89 fa                	mov    %edi,%edx

            !(pp = page_alloc(ALLOC_ZERO)) ||
f0100f35:	85 ff                	test   %edi,%edi
f0100f37:	74 43                	je     f0100f7c <pgdir_walk+0xdf>

        }



        pp->pp_ref++;
f0100f39:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f3e:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100f44:	77 15                	ja     f0100f5b <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f46:	57                   	push   %edi
f0100f47:	68 18 4f 10 f0       	push   $0xf0104f18
f0100f4c:	68 15 02 00 00       	push   $0x215
f0100f51:	68 21 56 10 f0       	push   $0xf0105621
f0100f56:	e8 45 f1 ff ff       	call   f01000a0 <_panic>

        *pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0100f5b:	83 c9 07             	or     $0x7,%ecx
f0100f5e:	89 0e                	mov    %ecx,(%esi)

    }



	return &pgtable[PTX(va)];
f0100f60:	c1 eb 0a             	shr    $0xa,%ebx
f0100f63:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100f69:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100f6c:	eb 13                	jmp    f0100f81 <pgdir_walk+0xe4>

            !(pgtable = (pte_t *)page2kva(pp)))

        {

            return NULL;
f0100f6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f73:	eb 0c                	jmp    f0100f81 <pgdir_walk+0xe4>
f0100f75:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f7a:	eb 05                	jmp    f0100f81 <pgdir_walk+0xe4>
f0100f7c:	b8 00 00 00 00       	mov    $0x0,%eax
    }



	return &pgtable[PTX(va)];
}
f0100f81:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f84:	5b                   	pop    %ebx
f0100f85:	5e                   	pop    %esi
f0100f86:	5f                   	pop    %edi
f0100f87:	5d                   	pop    %ebp
f0100f88:	c3                   	ret    

f0100f89 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f89:	55                   	push   %ebp
f0100f8a:	89 e5                	mov    %esp,%ebp
f0100f8c:	57                   	push   %edi
f0100f8d:	56                   	push   %esi
f0100f8e:	53                   	push   %ebx
f0100f8f:	83 ec 1c             	sub    $0x1c,%esp
f0100f92:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f95:	89 d7                	mov    %edx,%edi
f0100f97:	89 cb                	mov    %ecx,%ebx

    ROUNDUP(size, PGSIZE);



    assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f0100f99:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f0100f9f:	75 1b                	jne    f0100fbc <boot_map_region+0x33>
f0100fa1:	c1 eb 0c             	shr    $0xc,%ebx
f0100fa4:	89 5d e4             	mov    %ebx,-0x1c(%ebp)

    int temp = 0;



    for(temp = 0; temp < size/PGSIZE; temp++)
f0100fa7:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100faa:	be 00 00 00 00       	mov    $0x0,%esi

    {

        pte = pgdir_walk(pgdir, (void*)va_next, 1);
f0100faf:	29 df                	sub    %ebx,%edi

        }



        *pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0100fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb4:	83 c8 01             	or     $0x1,%eax
f0100fb7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100fba:	eb 5c                	jmp    f0101018 <boot_map_region+0x8f>

    ROUNDUP(size, PGSIZE);



    assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f0100fbc:	83 ec 08             	sub    $0x8,%esp
f0100fbf:	51                   	push   %ecx
f0100fc0:	68 ea 56 10 f0       	push   $0xf01056ea
f0100fc5:	e8 7f 20 00 00       	call   f0103049 <cprintf>
f0100fca:	83 c4 10             	add    $0x10,%esp
f0100fcd:	85 c0                	test   %eax,%eax
f0100fcf:	75 d0                	jne    f0100fa1 <boot_map_region+0x18>
f0100fd1:	68 3c 4f 10 f0       	push   $0xf0104f3c
f0100fd6:	68 47 56 10 f0       	push   $0xf0105647
f0100fdb:	68 39 02 00 00       	push   $0x239
f0100fe0:	68 21 56 10 f0       	push   $0xf0105621
f0100fe5:	e8 b6 f0 ff ff       	call   f01000a0 <_panic>

    for(temp = 0; temp < size/PGSIZE; temp++)

    {

        pte = pgdir_walk(pgdir, (void*)va_next, 1);
f0100fea:	83 ec 04             	sub    $0x4,%esp
f0100fed:	6a 01                	push   $0x1
f0100fef:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100ff2:	50                   	push   %eax
f0100ff3:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ff6:	e8 a2 fe ff ff       	call   f0100e9d <pgdir_walk>



        if(!pte)
f0100ffb:	83 c4 10             	add    $0x10,%esp
f0100ffe:	85 c0                	test   %eax,%eax
f0101000:	74 1b                	je     f010101d <boot_map_region+0x94>

        }



        *pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0101002:	89 da                	mov    %ebx,%edx
f0101004:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010100a:	0b 55 dc             	or     -0x24(%ebp),%edx
f010100d:	89 10                	mov    %edx,(%eax)

        pa_next += PGSIZE;
f010100f:	81 c3 00 10 00 00    	add    $0x1000,%ebx

    int temp = 0;



    for(temp = 0; temp < size/PGSIZE; temp++)
f0101015:	83 c6 01             	add    $0x1,%esi
f0101018:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010101b:	75 cd                	jne    f0100fea <boot_map_region+0x61>
        pa_next += PGSIZE;

        va_next += PGSIZE;

    }
}
f010101d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101020:	5b                   	pop    %ebx
f0101021:	5e                   	pop    %esi
f0101022:	5f                   	pop    %edi
f0101023:	5d                   	pop    %ebp
f0101024:	c3                   	ret    

f0101025 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101025:	55                   	push   %ebp
f0101026:	89 e5                	mov    %esp,%ebp
f0101028:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	 pte_t * pte = pgdir_walk(pgdir, va, 0);
f010102b:	6a 00                	push   $0x0
f010102d:	ff 75 0c             	pushl  0xc(%ebp)
f0101030:	ff 75 08             	pushl  0x8(%ebp)
f0101033:	e8 65 fe ff ff       	call   f0100e9d <pgdir_walk>



    if(!pte)
f0101038:	83 c4 10             	add    $0x10,%esp
f010103b:	85 c0                	test   %eax,%eax
f010103d:	74 31                	je     f0101070 <page_lookup+0x4b>

    }



    *pte_store = pte;
f010103f:	8b 55 10             	mov    0x10(%ebp),%edx
f0101042:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101044:	8b 00                	mov    (%eax),%eax
f0101046:	c1 e8 0c             	shr    $0xc,%eax
f0101049:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f010104f:	72 14                	jb     f0101065 <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0101051:	83 ec 04             	sub    $0x4,%esp
f0101054:	68 70 4f 10 f0       	push   $0xf0104f70
f0101059:	6a 4f                	push   $0x4f
f010105b:	68 2d 56 10 f0       	push   $0xf010562d
f0101060:	e8 3b f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0101065:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f010106b:	8d 04 c2             	lea    (%edx,%eax,8),%eax



	return pa2page(PTE_ADDR(*pte));
f010106e:	eb 05                	jmp    f0101075 <page_lookup+0x50>

    if(!pte)

    {

        return NULL;
f0101070:	b8 00 00 00 00       	mov    $0x0,%eax
    *pte_store = pte;



	return pa2page(PTE_ADDR(*pte));
}
f0101075:	c9                   	leave  
f0101076:	c3                   	ret    

f0101077 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101077:	55                   	push   %ebp
f0101078:	89 e5                	mov    %esp,%ebp
f010107a:	56                   	push   %esi
f010107b:	53                   	push   %ebx
f010107c:	83 ec 14             	sub    $0x14,%esp
f010107f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101082:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101085:	6a 00                	push   $0x0
f0101087:	53                   	push   %ebx
f0101088:	56                   	push   %esi
f0101089:	e8 0f fe ff ff       	call   f0100e9d <pgdir_walk>
f010108e:	89 45 f4             	mov    %eax,-0xc(%ebp)

    pte_t ** pte_store = &pte;



    struct PageInfo *pp = page_lookup(pgdir, va, pte_store);
f0101091:	83 c4 0c             	add    $0xc,%esp
f0101094:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101097:	50                   	push   %eax
f0101098:	53                   	push   %ebx
f0101099:	56                   	push   %esi
f010109a:	e8 86 ff ff ff       	call   f0101025 <page_lookup>



    if(!pp)
f010109f:	83 c4 10             	add    $0x10,%esp
f01010a2:	85 c0                	test   %eax,%eax
f01010a4:	74 18                	je     f01010be <page_remove+0x47>

    }



    page_decref(pp);
f01010a6:	83 ec 0c             	sub    $0xc,%esp
f01010a9:	50                   	push   %eax
f01010aa:	e8 c7 fd ff ff       	call   f0100e76 <page_decref>

    **pte_store = 0;
f01010af:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010b8:	0f 01 3b             	invlpg (%ebx)
f01010bb:	83 c4 10             	add    $0x10,%esp

    tlb_invalidate(pgdir, va);
}
f01010be:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010c1:	5b                   	pop    %ebx
f01010c2:	5e                   	pop    %esi
f01010c3:	5d                   	pop    %ebp
f01010c4:	c3                   	ret    

f01010c5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010c5:	55                   	push   %ebp
f01010c6:	89 e5                	mov    %esp,%ebp
f01010c8:	57                   	push   %edi
f01010c9:	56                   	push   %esi
f01010ca:	53                   	push   %ebx
f01010cb:	83 ec 10             	sub    $0x10,%esp
f01010ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010d1:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	  pte_t *pte = pgdir_walk(pgdir, va, 0);
f01010d4:	6a 00                	push   $0x0
f01010d6:	57                   	push   %edi
f01010d7:	ff 75 08             	pushl  0x8(%ebp)
f01010da:	e8 be fd ff ff       	call   f0100e9d <pgdir_walk>

    physaddr_t ppa = page2pa(pp);



    if(pte)
f01010df:	83 c4 10             	add    $0x10,%esp
f01010e2:	85 c0                	test   %eax,%eax
f01010e4:	74 27                	je     f010110d <page_insert+0x48>
f01010e6:	89 c6                	mov    %eax,%esi

    {

        if(*pte & PTE_P)
f01010e8:	f6 00 01             	testb  $0x1,(%eax)
f01010eb:	74 0f                	je     f01010fc <page_insert+0x37>

        {

            page_remove(pgdir, va);
f01010ed:	83 ec 08             	sub    $0x8,%esp
f01010f0:	57                   	push   %edi
f01010f1:	ff 75 08             	pushl  0x8(%ebp)
f01010f4:	e8 7e ff ff ff       	call   f0101077 <page_remove>
f01010f9:	83 c4 10             	add    $0x10,%esp

        }



        if(page_free_list == pp)
f01010fc:	3b 1d 80 1f 17 f0    	cmp    0xf0171f80,%ebx
f0101102:	75 20                	jne    f0101124 <page_insert+0x5f>

        {

            page_free_list = page_free_list->pp_link;
f0101104:	8b 03                	mov    (%ebx),%eax
f0101106:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
f010110b:	eb 17                	jmp    f0101124 <page_insert+0x5f>

    else

    {

        pte = pgdir_walk(pgdir, va, 1);
f010110d:	83 ec 04             	sub    $0x4,%esp
f0101110:	6a 01                	push   $0x1
f0101112:	57                   	push   %edi
f0101113:	ff 75 08             	pushl  0x8(%ebp)
f0101116:	e8 82 fd ff ff       	call   f0100e9d <pgdir_walk>
f010111b:	89 c6                	mov    %eax,%esi

        if(!pte)
f010111d:	83 c4 10             	add    $0x10,%esp
f0101120:	85 c0                	test   %eax,%eax
f0101122:	74 27                	je     f010114b <page_insert+0x86>

    }



    *pte = page2pa(pp) | PTE_P | perm;
f0101124:	89 d8                	mov    %ebx,%eax
f0101126:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010112c:	c1 f8 03             	sar    $0x3,%eax
f010112f:	c1 e0 0c             	shl    $0xc,%eax
f0101132:	8b 55 14             	mov    0x14(%ebp),%edx
f0101135:	83 ca 01             	or     $0x1,%edx
f0101138:	09 d0                	or     %edx,%eax
f010113a:	89 06                	mov    %eax,(%esi)



    pp->pp_ref++;
f010113c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
f0101141:	0f 01 3f             	invlpg (%edi)

    tlb_invalidate(pgdir, va);

	return 0;
f0101144:	b8 00 00 00 00       	mov    $0x0,%eax
f0101149:	eb 05                	jmp    f0101150 <page_insert+0x8b>

        if(!pte)

        {

            return -E_NO_MEM;
f010114b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    pp->pp_ref++;

    tlb_invalidate(pgdir, va);

	return 0;
}
f0101150:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101153:	5b                   	pop    %ebx
f0101154:	5e                   	pop    %esi
f0101155:	5f                   	pop    %edi
f0101156:	5d                   	pop    %ebp
f0101157:	c3                   	ret    

f0101158 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101158:	55                   	push   %ebp
f0101159:	89 e5                	mov    %esp,%ebp
f010115b:	57                   	push   %edi
f010115c:	56                   	push   %esi
f010115d:	53                   	push   %ebx
f010115e:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101161:	b8 15 00 00 00       	mov    $0x15,%eax
f0101166:	e8 f3 f7 ff ff       	call   f010095e <nvram_read>
f010116b:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010116d:	b8 17 00 00 00       	mov    $0x17,%eax
f0101172:	e8 e7 f7 ff ff       	call   f010095e <nvram_read>
f0101177:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101179:	b8 34 00 00 00       	mov    $0x34,%eax
f010117e:	e8 db f7 ff ff       	call   f010095e <nvram_read>
f0101183:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101186:	85 c0                	test   %eax,%eax
f0101188:	74 07                	je     f0101191 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010118a:	05 00 40 00 00       	add    $0x4000,%eax
f010118f:	eb 0b                	jmp    f010119c <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101191:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101197:	85 f6                	test   %esi,%esi
f0101199:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010119c:	89 c2                	mov    %eax,%edx
f010119e:	c1 ea 02             	shr    $0x2,%edx
f01011a1:	89 15 44 2c 17 f0    	mov    %edx,0xf0172c44
	npages_basemem = basemem / (PGSIZE / 1024);
f01011a7:	89 da                	mov    %ebx,%edx
f01011a9:	c1 ea 02             	shr    $0x2,%edx
f01011ac:	89 15 84 1f 17 f0    	mov    %edx,0xf0171f84

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011b2:	89 c2                	mov    %eax,%edx
f01011b4:	29 da                	sub    %ebx,%edx
f01011b6:	52                   	push   %edx
f01011b7:	53                   	push   %ebx
f01011b8:	50                   	push   %eax
f01011b9:	68 90 4f 10 f0       	push   $0xf0104f90
f01011be:	e8 86 1e 00 00       	call   f0103049 <cprintf>

	// Remove this line when you're ready to test this function.

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011c3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011c8:	e8 59 f7 ff ff       	call   f0100926 <boot_alloc>
f01011cd:	a3 48 2c 17 f0       	mov    %eax,0xf0172c48
	memset(kern_pgdir, 0, PGSIZE);
f01011d2:	83 c4 0c             	add    $0xc,%esp
f01011d5:	68 00 10 00 00       	push   $0x1000
f01011da:	6a 00                	push   $0x0
f01011dc:	50                   	push   %eax
f01011dd:	e8 31 32 00 00       	call   f0104413 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01011e2:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01011ef:	77 15                	ja     f0101206 <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011f1:	50                   	push   %eax
f01011f2:	68 18 4f 10 f0       	push   $0xf0104f18
f01011f7:	68 94 00 00 00       	push   $0x94
f01011fc:	68 21 56 10 f0       	push   $0xf0105621
f0101201:	e8 9a ee ff ff       	call   f01000a0 <_panic>
f0101206:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010120c:	83 ca 05             	or     $0x5,%edx
f010120f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
    pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101215:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f010121a:	c1 e0 03             	shl    $0x3,%eax
f010121d:	e8 04 f7 ff ff       	call   f0100926 <boot_alloc>
f0101222:	a3 4c 2c 17 f0       	mov    %eax,0xf0172c4c

	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101227:	83 ec 04             	sub    $0x4,%esp
f010122a:	8b 3d 44 2c 17 f0    	mov    0xf0172c44,%edi
f0101230:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101237:	52                   	push   %edx
f0101238:	6a 00                	push   $0x0
f010123a:	50                   	push   %eax
f010123b:	e8 d3 31 00 00       	call   f0104413 <memset>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f0101240:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101245:	e8 dc f6 ff ff       	call   f0100926 <boot_alloc>
f010124a:	a3 8c 1f 17 f0       	mov    %eax,0xf0171f8c
	memset(envs, 0, NENV * sizeof(struct Env));
f010124f:	83 c4 0c             	add    $0xc,%esp
f0101252:	68 00 80 01 00       	push   $0x18000
f0101257:	6a 00                	push   $0x0
f0101259:	50                   	push   %eax
f010125a:	e8 b4 31 00 00       	call   f0104413 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010125f:	e8 4a fa ff ff       	call   f0100cae <page_init>

	check_page_free_list(1);
f0101264:	b8 01 00 00 00       	mov    $0x1,%eax
f0101269:	e8 7d f7 ff ff       	call   f01009eb <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010126e:	83 c4 10             	add    $0x10,%esp
f0101271:	83 3d 4c 2c 17 f0 00 	cmpl   $0x0,0xf0172c4c
f0101278:	75 17                	jne    f0101291 <mem_init+0x139>
		panic("'pages' is a null pointer!");
f010127a:	83 ec 04             	sub    $0x4,%esp
f010127d:	68 f6 56 10 f0       	push   $0xf01056f6
f0101282:	68 9e 03 00 00       	push   $0x39e
f0101287:	68 21 56 10 f0       	push   $0xf0105621
f010128c:	e8 0f ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101291:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101296:	bb 00 00 00 00       	mov    $0x0,%ebx
f010129b:	eb 05                	jmp    f01012a2 <mem_init+0x14a>
		++nfree;
f010129d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012a0:	8b 00                	mov    (%eax),%eax
f01012a2:	85 c0                	test   %eax,%eax
f01012a4:	75 f7                	jne    f010129d <mem_init+0x145>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012a6:	83 ec 0c             	sub    $0xc,%esp
f01012a9:	6a 00                	push   $0x0
f01012ab:	e8 1f fb ff ff       	call   f0100dcf <page_alloc>
f01012b0:	89 c7                	mov    %eax,%edi
f01012b2:	83 c4 10             	add    $0x10,%esp
f01012b5:	85 c0                	test   %eax,%eax
f01012b7:	75 19                	jne    f01012d2 <mem_init+0x17a>
f01012b9:	68 11 57 10 f0       	push   $0xf0105711
f01012be:	68 47 56 10 f0       	push   $0xf0105647
f01012c3:	68 a6 03 00 00       	push   $0x3a6
f01012c8:	68 21 56 10 f0       	push   $0xf0105621
f01012cd:	e8 ce ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012d2:	83 ec 0c             	sub    $0xc,%esp
f01012d5:	6a 00                	push   $0x0
f01012d7:	e8 f3 fa ff ff       	call   f0100dcf <page_alloc>
f01012dc:	89 c6                	mov    %eax,%esi
f01012de:	83 c4 10             	add    $0x10,%esp
f01012e1:	85 c0                	test   %eax,%eax
f01012e3:	75 19                	jne    f01012fe <mem_init+0x1a6>
f01012e5:	68 27 57 10 f0       	push   $0xf0105727
f01012ea:	68 47 56 10 f0       	push   $0xf0105647
f01012ef:	68 a7 03 00 00       	push   $0x3a7
f01012f4:	68 21 56 10 f0       	push   $0xf0105621
f01012f9:	e8 a2 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012fe:	83 ec 0c             	sub    $0xc,%esp
f0101301:	6a 00                	push   $0x0
f0101303:	e8 c7 fa ff ff       	call   f0100dcf <page_alloc>
f0101308:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010130b:	83 c4 10             	add    $0x10,%esp
f010130e:	85 c0                	test   %eax,%eax
f0101310:	75 19                	jne    f010132b <mem_init+0x1d3>
f0101312:	68 3d 57 10 f0       	push   $0xf010573d
f0101317:	68 47 56 10 f0       	push   $0xf0105647
f010131c:	68 a8 03 00 00       	push   $0x3a8
f0101321:	68 21 56 10 f0       	push   $0xf0105621
f0101326:	e8 75 ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010132b:	39 f7                	cmp    %esi,%edi
f010132d:	75 19                	jne    f0101348 <mem_init+0x1f0>
f010132f:	68 53 57 10 f0       	push   $0xf0105753
f0101334:	68 47 56 10 f0       	push   $0xf0105647
f0101339:	68 ab 03 00 00       	push   $0x3ab
f010133e:	68 21 56 10 f0       	push   $0xf0105621
f0101343:	e8 58 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101348:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010134b:	39 c6                	cmp    %eax,%esi
f010134d:	74 04                	je     f0101353 <mem_init+0x1fb>
f010134f:	39 c7                	cmp    %eax,%edi
f0101351:	75 19                	jne    f010136c <mem_init+0x214>
f0101353:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0101358:	68 47 56 10 f0       	push   $0xf0105647
f010135d:	68 ac 03 00 00       	push   $0x3ac
f0101362:	68 21 56 10 f0       	push   $0xf0105621
f0101367:	e8 34 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010136c:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101372:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f0101378:	c1 e2 0c             	shl    $0xc,%edx
f010137b:	89 f8                	mov    %edi,%eax
f010137d:	29 c8                	sub    %ecx,%eax
f010137f:	c1 f8 03             	sar    $0x3,%eax
f0101382:	c1 e0 0c             	shl    $0xc,%eax
f0101385:	39 d0                	cmp    %edx,%eax
f0101387:	72 19                	jb     f01013a2 <mem_init+0x24a>
f0101389:	68 65 57 10 f0       	push   $0xf0105765
f010138e:	68 47 56 10 f0       	push   $0xf0105647
f0101393:	68 ad 03 00 00       	push   $0x3ad
f0101398:	68 21 56 10 f0       	push   $0xf0105621
f010139d:	e8 fe ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01013a2:	89 f0                	mov    %esi,%eax
f01013a4:	29 c8                	sub    %ecx,%eax
f01013a6:	c1 f8 03             	sar    $0x3,%eax
f01013a9:	c1 e0 0c             	shl    $0xc,%eax
f01013ac:	39 c2                	cmp    %eax,%edx
f01013ae:	77 19                	ja     f01013c9 <mem_init+0x271>
f01013b0:	68 82 57 10 f0       	push   $0xf0105782
f01013b5:	68 47 56 10 f0       	push   $0xf0105647
f01013ba:	68 ae 03 00 00       	push   $0x3ae
f01013bf:	68 21 56 10 f0       	push   $0xf0105621
f01013c4:	e8 d7 ec ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013cc:	29 c8                	sub    %ecx,%eax
f01013ce:	c1 f8 03             	sar    $0x3,%eax
f01013d1:	c1 e0 0c             	shl    $0xc,%eax
f01013d4:	39 c2                	cmp    %eax,%edx
f01013d6:	77 19                	ja     f01013f1 <mem_init+0x299>
f01013d8:	68 9f 57 10 f0       	push   $0xf010579f
f01013dd:	68 47 56 10 f0       	push   $0xf0105647
f01013e2:	68 af 03 00 00       	push   $0x3af
f01013e7:	68 21 56 10 f0       	push   $0xf0105621
f01013ec:	e8 af ec ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013f1:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01013f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01013f9:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101400:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101403:	83 ec 0c             	sub    $0xc,%esp
f0101406:	6a 00                	push   $0x0
f0101408:	e8 c2 f9 ff ff       	call   f0100dcf <page_alloc>
f010140d:	83 c4 10             	add    $0x10,%esp
f0101410:	85 c0                	test   %eax,%eax
f0101412:	74 19                	je     f010142d <mem_init+0x2d5>
f0101414:	68 bc 57 10 f0       	push   $0xf01057bc
f0101419:	68 47 56 10 f0       	push   $0xf0105647
f010141e:	68 b6 03 00 00       	push   $0x3b6
f0101423:	68 21 56 10 f0       	push   $0xf0105621
f0101428:	e8 73 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010142d:	83 ec 0c             	sub    $0xc,%esp
f0101430:	57                   	push   %edi
f0101431:	e8 03 fa ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f0101436:	89 34 24             	mov    %esi,(%esp)
f0101439:	e8 fb f9 ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f010143e:	83 c4 04             	add    $0x4,%esp
f0101441:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101444:	e8 f0 f9 ff ff       	call   f0100e39 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101449:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101450:	e8 7a f9 ff ff       	call   f0100dcf <page_alloc>
f0101455:	89 c6                	mov    %eax,%esi
f0101457:	83 c4 10             	add    $0x10,%esp
f010145a:	85 c0                	test   %eax,%eax
f010145c:	75 19                	jne    f0101477 <mem_init+0x31f>
f010145e:	68 11 57 10 f0       	push   $0xf0105711
f0101463:	68 47 56 10 f0       	push   $0xf0105647
f0101468:	68 bd 03 00 00       	push   $0x3bd
f010146d:	68 21 56 10 f0       	push   $0xf0105621
f0101472:	e8 29 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101477:	83 ec 0c             	sub    $0xc,%esp
f010147a:	6a 00                	push   $0x0
f010147c:	e8 4e f9 ff ff       	call   f0100dcf <page_alloc>
f0101481:	89 c7                	mov    %eax,%edi
f0101483:	83 c4 10             	add    $0x10,%esp
f0101486:	85 c0                	test   %eax,%eax
f0101488:	75 19                	jne    f01014a3 <mem_init+0x34b>
f010148a:	68 27 57 10 f0       	push   $0xf0105727
f010148f:	68 47 56 10 f0       	push   $0xf0105647
f0101494:	68 be 03 00 00       	push   $0x3be
f0101499:	68 21 56 10 f0       	push   $0xf0105621
f010149e:	e8 fd eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a3:	83 ec 0c             	sub    $0xc,%esp
f01014a6:	6a 00                	push   $0x0
f01014a8:	e8 22 f9 ff ff       	call   f0100dcf <page_alloc>
f01014ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b0:	83 c4 10             	add    $0x10,%esp
f01014b3:	85 c0                	test   %eax,%eax
f01014b5:	75 19                	jne    f01014d0 <mem_init+0x378>
f01014b7:	68 3d 57 10 f0       	push   $0xf010573d
f01014bc:	68 47 56 10 f0       	push   $0xf0105647
f01014c1:	68 bf 03 00 00       	push   $0x3bf
f01014c6:	68 21 56 10 f0       	push   $0xf0105621
f01014cb:	e8 d0 eb ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d0:	39 fe                	cmp    %edi,%esi
f01014d2:	75 19                	jne    f01014ed <mem_init+0x395>
f01014d4:	68 53 57 10 f0       	push   $0xf0105753
f01014d9:	68 47 56 10 f0       	push   $0xf0105647
f01014de:	68 c1 03 00 00       	push   $0x3c1
f01014e3:	68 21 56 10 f0       	push   $0xf0105621
f01014e8:	e8 b3 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f0:	39 c7                	cmp    %eax,%edi
f01014f2:	74 04                	je     f01014f8 <mem_init+0x3a0>
f01014f4:	39 c6                	cmp    %eax,%esi
f01014f6:	75 19                	jne    f0101511 <mem_init+0x3b9>
f01014f8:	68 cc 4f 10 f0       	push   $0xf0104fcc
f01014fd:	68 47 56 10 f0       	push   $0xf0105647
f0101502:	68 c2 03 00 00       	push   $0x3c2
f0101507:	68 21 56 10 f0       	push   $0xf0105621
f010150c:	e8 8f eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	6a 00                	push   $0x0
f0101516:	e8 b4 f8 ff ff       	call   f0100dcf <page_alloc>
f010151b:	83 c4 10             	add    $0x10,%esp
f010151e:	85 c0                	test   %eax,%eax
f0101520:	74 19                	je     f010153b <mem_init+0x3e3>
f0101522:	68 bc 57 10 f0       	push   $0xf01057bc
f0101527:	68 47 56 10 f0       	push   $0xf0105647
f010152c:	68 c3 03 00 00       	push   $0x3c3
f0101531:	68 21 56 10 f0       	push   $0xf0105621
f0101536:	e8 65 eb ff ff       	call   f01000a0 <_panic>
f010153b:	89 f0                	mov    %esi,%eax
f010153d:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101543:	c1 f8 03             	sar    $0x3,%eax
f0101546:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101549:	89 c2                	mov    %eax,%edx
f010154b:	c1 ea 0c             	shr    $0xc,%edx
f010154e:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0101554:	72 12                	jb     f0101568 <mem_init+0x410>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101556:	50                   	push   %eax
f0101557:	68 e4 4d 10 f0       	push   $0xf0104de4
f010155c:	6a 56                	push   $0x56
f010155e:	68 2d 56 10 f0       	push   $0xf010562d
f0101563:	e8 38 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101568:	83 ec 04             	sub    $0x4,%esp
f010156b:	68 00 10 00 00       	push   $0x1000
f0101570:	6a 01                	push   $0x1
f0101572:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101577:	50                   	push   %eax
f0101578:	e8 96 2e 00 00       	call   f0104413 <memset>
	page_free(pp0);
f010157d:	89 34 24             	mov    %esi,(%esp)
f0101580:	e8 b4 f8 ff ff       	call   f0100e39 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101585:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010158c:	e8 3e f8 ff ff       	call   f0100dcf <page_alloc>
f0101591:	83 c4 10             	add    $0x10,%esp
f0101594:	85 c0                	test   %eax,%eax
f0101596:	75 19                	jne    f01015b1 <mem_init+0x459>
f0101598:	68 cb 57 10 f0       	push   $0xf01057cb
f010159d:	68 47 56 10 f0       	push   $0xf0105647
f01015a2:	68 c8 03 00 00       	push   $0x3c8
f01015a7:	68 21 56 10 f0       	push   $0xf0105621
f01015ac:	e8 ef ea ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01015b1:	39 c6                	cmp    %eax,%esi
f01015b3:	74 19                	je     f01015ce <mem_init+0x476>
f01015b5:	68 e9 57 10 f0       	push   $0xf01057e9
f01015ba:	68 47 56 10 f0       	push   $0xf0105647
f01015bf:	68 c9 03 00 00       	push   $0x3c9
f01015c4:	68 21 56 10 f0       	push   $0xf0105621
f01015c9:	e8 d2 ea ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015ce:	89 f0                	mov    %esi,%eax
f01015d0:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01015d6:	c1 f8 03             	sar    $0x3,%eax
f01015d9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015dc:	89 c2                	mov    %eax,%edx
f01015de:	c1 ea 0c             	shr    $0xc,%edx
f01015e1:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01015e7:	72 12                	jb     f01015fb <mem_init+0x4a3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015e9:	50                   	push   %eax
f01015ea:	68 e4 4d 10 f0       	push   $0xf0104de4
f01015ef:	6a 56                	push   $0x56
f01015f1:	68 2d 56 10 f0       	push   $0xf010562d
f01015f6:	e8 a5 ea ff ff       	call   f01000a0 <_panic>
f01015fb:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101601:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101607:	80 38 00             	cmpb   $0x0,(%eax)
f010160a:	74 19                	je     f0101625 <mem_init+0x4cd>
f010160c:	68 f9 57 10 f0       	push   $0xf01057f9
f0101611:	68 47 56 10 f0       	push   $0xf0105647
f0101616:	68 cc 03 00 00       	push   $0x3cc
f010161b:	68 21 56 10 f0       	push   $0xf0105621
f0101620:	e8 7b ea ff ff       	call   f01000a0 <_panic>
f0101625:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101628:	39 d0                	cmp    %edx,%eax
f010162a:	75 db                	jne    f0101607 <mem_init+0x4af>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010162c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010162f:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// free the pages we took
	page_free(pp0);
f0101634:	83 ec 0c             	sub    $0xc,%esp
f0101637:	56                   	push   %esi
f0101638:	e8 fc f7 ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f010163d:	89 3c 24             	mov    %edi,(%esp)
f0101640:	e8 f4 f7 ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f0101645:	83 c4 04             	add    $0x4,%esp
f0101648:	ff 75 d4             	pushl  -0x2c(%ebp)
f010164b:	e8 e9 f7 ff ff       	call   f0100e39 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101650:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101655:	83 c4 10             	add    $0x10,%esp
f0101658:	eb 05                	jmp    f010165f <mem_init+0x507>
		--nfree;
f010165a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010165d:	8b 00                	mov    (%eax),%eax
f010165f:	85 c0                	test   %eax,%eax
f0101661:	75 f7                	jne    f010165a <mem_init+0x502>
		--nfree;
	assert(nfree == 0);
f0101663:	85 db                	test   %ebx,%ebx
f0101665:	74 19                	je     f0101680 <mem_init+0x528>
f0101667:	68 03 58 10 f0       	push   $0xf0105803
f010166c:	68 47 56 10 f0       	push   $0xf0105647
f0101671:	68 d9 03 00 00       	push   $0x3d9
f0101676:	68 21 56 10 f0       	push   $0xf0105621
f010167b:	e8 20 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101680:	83 ec 0c             	sub    $0xc,%esp
f0101683:	68 ec 4f 10 f0       	push   $0xf0104fec
f0101688:	e8 bc 19 00 00       	call   f0103049 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010168d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101694:	e8 36 f7 ff ff       	call   f0100dcf <page_alloc>
f0101699:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010169c:	83 c4 10             	add    $0x10,%esp
f010169f:	85 c0                	test   %eax,%eax
f01016a1:	75 19                	jne    f01016bc <mem_init+0x564>
f01016a3:	68 11 57 10 f0       	push   $0xf0105711
f01016a8:	68 47 56 10 f0       	push   $0xf0105647
f01016ad:	68 37 04 00 00       	push   $0x437
f01016b2:	68 21 56 10 f0       	push   $0xf0105621
f01016b7:	e8 e4 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01016bc:	83 ec 0c             	sub    $0xc,%esp
f01016bf:	6a 00                	push   $0x0
f01016c1:	e8 09 f7 ff ff       	call   f0100dcf <page_alloc>
f01016c6:	89 c3                	mov    %eax,%ebx
f01016c8:	83 c4 10             	add    $0x10,%esp
f01016cb:	85 c0                	test   %eax,%eax
f01016cd:	75 19                	jne    f01016e8 <mem_init+0x590>
f01016cf:	68 27 57 10 f0       	push   $0xf0105727
f01016d4:	68 47 56 10 f0       	push   $0xf0105647
f01016d9:	68 38 04 00 00       	push   $0x438
f01016de:	68 21 56 10 f0       	push   $0xf0105621
f01016e3:	e8 b8 e9 ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01016e8:	83 ec 0c             	sub    $0xc,%esp
f01016eb:	6a 00                	push   $0x0
f01016ed:	e8 dd f6 ff ff       	call   f0100dcf <page_alloc>
f01016f2:	89 c6                	mov    %eax,%esi
f01016f4:	83 c4 10             	add    $0x10,%esp
f01016f7:	85 c0                	test   %eax,%eax
f01016f9:	75 19                	jne    f0101714 <mem_init+0x5bc>
f01016fb:	68 3d 57 10 f0       	push   $0xf010573d
f0101700:	68 47 56 10 f0       	push   $0xf0105647
f0101705:	68 39 04 00 00       	push   $0x439
f010170a:	68 21 56 10 f0       	push   $0xf0105621
f010170f:	e8 8c e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101714:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101717:	75 19                	jne    f0101732 <mem_init+0x5da>
f0101719:	68 53 57 10 f0       	push   $0xf0105753
f010171e:	68 47 56 10 f0       	push   $0xf0105647
f0101723:	68 3c 04 00 00       	push   $0x43c
f0101728:	68 21 56 10 f0       	push   $0xf0105621
f010172d:	e8 6e e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101732:	39 c3                	cmp    %eax,%ebx
f0101734:	74 05                	je     f010173b <mem_init+0x5e3>
f0101736:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101739:	75 19                	jne    f0101754 <mem_init+0x5fc>
f010173b:	68 cc 4f 10 f0       	push   $0xf0104fcc
f0101740:	68 47 56 10 f0       	push   $0xf0105647
f0101745:	68 3d 04 00 00       	push   $0x43d
f010174a:	68 21 56 10 f0       	push   $0xf0105621
f010174f:	e8 4c e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101754:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101759:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010175c:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101763:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101766:	83 ec 0c             	sub    $0xc,%esp
f0101769:	6a 00                	push   $0x0
f010176b:	e8 5f f6 ff ff       	call   f0100dcf <page_alloc>
f0101770:	83 c4 10             	add    $0x10,%esp
f0101773:	85 c0                	test   %eax,%eax
f0101775:	74 19                	je     f0101790 <mem_init+0x638>
f0101777:	68 bc 57 10 f0       	push   $0xf01057bc
f010177c:	68 47 56 10 f0       	push   $0xf0105647
f0101781:	68 44 04 00 00       	push   $0x444
f0101786:	68 21 56 10 f0       	push   $0xf0105621
f010178b:	e8 10 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101790:	83 ec 04             	sub    $0x4,%esp
f0101793:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101796:	50                   	push   %eax
f0101797:	6a 00                	push   $0x0
f0101799:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010179f:	e8 81 f8 ff ff       	call   f0101025 <page_lookup>
f01017a4:	83 c4 10             	add    $0x10,%esp
f01017a7:	85 c0                	test   %eax,%eax
f01017a9:	74 19                	je     f01017c4 <mem_init+0x66c>
f01017ab:	68 0c 50 10 f0       	push   $0xf010500c
f01017b0:	68 47 56 10 f0       	push   $0xf0105647
f01017b5:	68 47 04 00 00       	push   $0x447
f01017ba:	68 21 56 10 f0       	push   $0xf0105621
f01017bf:	e8 dc e8 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017c4:	6a 02                	push   $0x2
f01017c6:	6a 00                	push   $0x0
f01017c8:	53                   	push   %ebx
f01017c9:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01017cf:	e8 f1 f8 ff ff       	call   f01010c5 <page_insert>
f01017d4:	83 c4 10             	add    $0x10,%esp
f01017d7:	85 c0                	test   %eax,%eax
f01017d9:	78 19                	js     f01017f4 <mem_init+0x69c>
f01017db:	68 44 50 10 f0       	push   $0xf0105044
f01017e0:	68 47 56 10 f0       	push   $0xf0105647
f01017e5:	68 4a 04 00 00       	push   $0x44a
f01017ea:	68 21 56 10 f0       	push   $0xf0105621
f01017ef:	e8 ac e8 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01017f4:	83 ec 0c             	sub    $0xc,%esp
f01017f7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017fa:	e8 3a f6 ff ff       	call   f0100e39 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017ff:	6a 02                	push   $0x2
f0101801:	6a 00                	push   $0x0
f0101803:	53                   	push   %ebx
f0101804:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010180a:	e8 b6 f8 ff ff       	call   f01010c5 <page_insert>
f010180f:	83 c4 20             	add    $0x20,%esp
f0101812:	85 c0                	test   %eax,%eax
f0101814:	74 19                	je     f010182f <mem_init+0x6d7>
f0101816:	68 74 50 10 f0       	push   $0xf0105074
f010181b:	68 47 56 10 f0       	push   $0xf0105647
f0101820:	68 4e 04 00 00       	push   $0x44e
f0101825:	68 21 56 10 f0       	push   $0xf0105621
f010182a:	e8 71 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010182f:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101835:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f010183a:	89 c1                	mov    %eax,%ecx
f010183c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010183f:	8b 17                	mov    (%edi),%edx
f0101841:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101847:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010184a:	29 c8                	sub    %ecx,%eax
f010184c:	c1 f8 03             	sar    $0x3,%eax
f010184f:	c1 e0 0c             	shl    $0xc,%eax
f0101852:	39 c2                	cmp    %eax,%edx
f0101854:	74 19                	je     f010186f <mem_init+0x717>
f0101856:	68 a4 50 10 f0       	push   $0xf01050a4
f010185b:	68 47 56 10 f0       	push   $0xf0105647
f0101860:	68 4f 04 00 00       	push   $0x44f
f0101865:	68 21 56 10 f0       	push   $0xf0105621
f010186a:	e8 31 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010186f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101874:	89 f8                	mov    %edi,%eax
f0101876:	e8 0c f1 ff ff       	call   f0100987 <check_va2pa>
f010187b:	89 da                	mov    %ebx,%edx
f010187d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101880:	c1 fa 03             	sar    $0x3,%edx
f0101883:	c1 e2 0c             	shl    $0xc,%edx
f0101886:	39 d0                	cmp    %edx,%eax
f0101888:	74 19                	je     f01018a3 <mem_init+0x74b>
f010188a:	68 cc 50 10 f0       	push   $0xf01050cc
f010188f:	68 47 56 10 f0       	push   $0xf0105647
f0101894:	68 50 04 00 00       	push   $0x450
f0101899:	68 21 56 10 f0       	push   $0xf0105621
f010189e:	e8 fd e7 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01018a3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018a8:	74 19                	je     f01018c3 <mem_init+0x76b>
f01018aa:	68 0e 58 10 f0       	push   $0xf010580e
f01018af:	68 47 56 10 f0       	push   $0xf0105647
f01018b4:	68 51 04 00 00       	push   $0x451
f01018b9:	68 21 56 10 f0       	push   $0xf0105621
f01018be:	e8 dd e7 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01018c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018c6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01018cb:	74 19                	je     f01018e6 <mem_init+0x78e>
f01018cd:	68 1f 58 10 f0       	push   $0xf010581f
f01018d2:	68 47 56 10 f0       	push   $0xf0105647
f01018d7:	68 52 04 00 00       	push   $0x452
f01018dc:	68 21 56 10 f0       	push   $0xf0105621
f01018e1:	e8 ba e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018e6:	6a 02                	push   $0x2
f01018e8:	68 00 10 00 00       	push   $0x1000
f01018ed:	56                   	push   %esi
f01018ee:	57                   	push   %edi
f01018ef:	e8 d1 f7 ff ff       	call   f01010c5 <page_insert>
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	85 c0                	test   %eax,%eax
f01018f9:	74 19                	je     f0101914 <mem_init+0x7bc>
f01018fb:	68 fc 50 10 f0       	push   $0xf01050fc
f0101900:	68 47 56 10 f0       	push   $0xf0105647
f0101905:	68 55 04 00 00       	push   $0x455
f010190a:	68 21 56 10 f0       	push   $0xf0105621
f010190f:	e8 8c e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101914:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101919:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010191e:	e8 64 f0 ff ff       	call   f0100987 <check_va2pa>
f0101923:	89 f2                	mov    %esi,%edx
f0101925:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f010192b:	c1 fa 03             	sar    $0x3,%edx
f010192e:	c1 e2 0c             	shl    $0xc,%edx
f0101931:	39 d0                	cmp    %edx,%eax
f0101933:	74 19                	je     f010194e <mem_init+0x7f6>
f0101935:	68 38 51 10 f0       	push   $0xf0105138
f010193a:	68 47 56 10 f0       	push   $0xf0105647
f010193f:	68 56 04 00 00       	push   $0x456
f0101944:	68 21 56 10 f0       	push   $0xf0105621
f0101949:	e8 52 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010194e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101953:	74 19                	je     f010196e <mem_init+0x816>
f0101955:	68 30 58 10 f0       	push   $0xf0105830
f010195a:	68 47 56 10 f0       	push   $0xf0105647
f010195f:	68 57 04 00 00       	push   $0x457
f0101964:	68 21 56 10 f0       	push   $0xf0105621
f0101969:	e8 32 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010196e:	83 ec 0c             	sub    $0xc,%esp
f0101971:	6a 00                	push   $0x0
f0101973:	e8 57 f4 ff ff       	call   f0100dcf <page_alloc>
f0101978:	83 c4 10             	add    $0x10,%esp
f010197b:	85 c0                	test   %eax,%eax
f010197d:	74 19                	je     f0101998 <mem_init+0x840>
f010197f:	68 bc 57 10 f0       	push   $0xf01057bc
f0101984:	68 47 56 10 f0       	push   $0xf0105647
f0101989:	68 5a 04 00 00       	push   $0x45a
f010198e:	68 21 56 10 f0       	push   $0xf0105621
f0101993:	e8 08 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101998:	6a 02                	push   $0x2
f010199a:	68 00 10 00 00       	push   $0x1000
f010199f:	56                   	push   %esi
f01019a0:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01019a6:	e8 1a f7 ff ff       	call   f01010c5 <page_insert>
f01019ab:	83 c4 10             	add    $0x10,%esp
f01019ae:	85 c0                	test   %eax,%eax
f01019b0:	74 19                	je     f01019cb <mem_init+0x873>
f01019b2:	68 fc 50 10 f0       	push   $0xf01050fc
f01019b7:	68 47 56 10 f0       	push   $0xf0105647
f01019bc:	68 5d 04 00 00       	push   $0x45d
f01019c1:	68 21 56 10 f0       	push   $0xf0105621
f01019c6:	e8 d5 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019cb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019d0:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01019d5:	e8 ad ef ff ff       	call   f0100987 <check_va2pa>
f01019da:	89 f2                	mov    %esi,%edx
f01019dc:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01019e2:	c1 fa 03             	sar    $0x3,%edx
f01019e5:	c1 e2 0c             	shl    $0xc,%edx
f01019e8:	39 d0                	cmp    %edx,%eax
f01019ea:	74 19                	je     f0101a05 <mem_init+0x8ad>
f01019ec:	68 38 51 10 f0       	push   $0xf0105138
f01019f1:	68 47 56 10 f0       	push   $0xf0105647
f01019f6:	68 5e 04 00 00       	push   $0x45e
f01019fb:	68 21 56 10 f0       	push   $0xf0105621
f0101a00:	e8 9b e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a05:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a0a:	74 19                	je     f0101a25 <mem_init+0x8cd>
f0101a0c:	68 30 58 10 f0       	push   $0xf0105830
f0101a11:	68 47 56 10 f0       	push   $0xf0105647
f0101a16:	68 5f 04 00 00       	push   $0x45f
f0101a1b:	68 21 56 10 f0       	push   $0xf0105621
f0101a20:	e8 7b e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a25:	83 ec 0c             	sub    $0xc,%esp
f0101a28:	6a 00                	push   $0x0
f0101a2a:	e8 a0 f3 ff ff       	call   f0100dcf <page_alloc>
f0101a2f:	83 c4 10             	add    $0x10,%esp
f0101a32:	85 c0                	test   %eax,%eax
f0101a34:	74 19                	je     f0101a4f <mem_init+0x8f7>
f0101a36:	68 bc 57 10 f0       	push   $0xf01057bc
f0101a3b:	68 47 56 10 f0       	push   $0xf0105647
f0101a40:	68 63 04 00 00       	push   $0x463
f0101a45:	68 21 56 10 f0       	push   $0xf0105621
f0101a4a:	e8 51 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a4f:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f0101a55:	8b 02                	mov    (%edx),%eax
f0101a57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a5c:	89 c1                	mov    %eax,%ecx
f0101a5e:	c1 e9 0c             	shr    $0xc,%ecx
f0101a61:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0101a67:	72 15                	jb     f0101a7e <mem_init+0x926>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a69:	50                   	push   %eax
f0101a6a:	68 e4 4d 10 f0       	push   $0xf0104de4
f0101a6f:	68 66 04 00 00       	push   $0x466
f0101a74:	68 21 56 10 f0       	push   $0xf0105621
f0101a79:	e8 22 e6 ff ff       	call   f01000a0 <_panic>
f0101a7e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a83:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a86:	83 ec 04             	sub    $0x4,%esp
f0101a89:	6a 00                	push   $0x0
f0101a8b:	68 00 10 00 00       	push   $0x1000
f0101a90:	52                   	push   %edx
f0101a91:	e8 07 f4 ff ff       	call   f0100e9d <pgdir_walk>
f0101a96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a99:	8d 57 04             	lea    0x4(%edi),%edx
f0101a9c:	83 c4 10             	add    $0x10,%esp
f0101a9f:	39 d0                	cmp    %edx,%eax
f0101aa1:	74 19                	je     f0101abc <mem_init+0x964>
f0101aa3:	68 68 51 10 f0       	push   $0xf0105168
f0101aa8:	68 47 56 10 f0       	push   $0xf0105647
f0101aad:	68 67 04 00 00       	push   $0x467
f0101ab2:	68 21 56 10 f0       	push   $0xf0105621
f0101ab7:	e8 e4 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101abc:	6a 06                	push   $0x6
f0101abe:	68 00 10 00 00       	push   $0x1000
f0101ac3:	56                   	push   %esi
f0101ac4:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101aca:	e8 f6 f5 ff ff       	call   f01010c5 <page_insert>
f0101acf:	83 c4 10             	add    $0x10,%esp
f0101ad2:	85 c0                	test   %eax,%eax
f0101ad4:	74 19                	je     f0101aef <mem_init+0x997>
f0101ad6:	68 a8 51 10 f0       	push   $0xf01051a8
f0101adb:	68 47 56 10 f0       	push   $0xf0105647
f0101ae0:	68 6a 04 00 00       	push   $0x46a
f0101ae5:	68 21 56 10 f0       	push   $0xf0105621
f0101aea:	e8 b1 e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aef:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101af5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101afa:	89 f8                	mov    %edi,%eax
f0101afc:	e8 86 ee ff ff       	call   f0100987 <check_va2pa>
f0101b01:	89 f2                	mov    %esi,%edx
f0101b03:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101b09:	c1 fa 03             	sar    $0x3,%edx
f0101b0c:	c1 e2 0c             	shl    $0xc,%edx
f0101b0f:	39 d0                	cmp    %edx,%eax
f0101b11:	74 19                	je     f0101b2c <mem_init+0x9d4>
f0101b13:	68 38 51 10 f0       	push   $0xf0105138
f0101b18:	68 47 56 10 f0       	push   $0xf0105647
f0101b1d:	68 6b 04 00 00       	push   $0x46b
f0101b22:	68 21 56 10 f0       	push   $0xf0105621
f0101b27:	e8 74 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101b2c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b31:	74 19                	je     f0101b4c <mem_init+0x9f4>
f0101b33:	68 30 58 10 f0       	push   $0xf0105830
f0101b38:	68 47 56 10 f0       	push   $0xf0105647
f0101b3d:	68 6c 04 00 00       	push   $0x46c
f0101b42:	68 21 56 10 f0       	push   $0xf0105621
f0101b47:	e8 54 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b4c:	83 ec 04             	sub    $0x4,%esp
f0101b4f:	6a 00                	push   $0x0
f0101b51:	68 00 10 00 00       	push   $0x1000
f0101b56:	57                   	push   %edi
f0101b57:	e8 41 f3 ff ff       	call   f0100e9d <pgdir_walk>
f0101b5c:	83 c4 10             	add    $0x10,%esp
f0101b5f:	f6 00 04             	testb  $0x4,(%eax)
f0101b62:	75 19                	jne    f0101b7d <mem_init+0xa25>
f0101b64:	68 e8 51 10 f0       	push   $0xf01051e8
f0101b69:	68 47 56 10 f0       	push   $0xf0105647
f0101b6e:	68 6d 04 00 00       	push   $0x46d
f0101b73:	68 21 56 10 f0       	push   $0xf0105621
f0101b78:	e8 23 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b7d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101b82:	f6 00 04             	testb  $0x4,(%eax)
f0101b85:	75 19                	jne    f0101ba0 <mem_init+0xa48>
f0101b87:	68 41 58 10 f0       	push   $0xf0105841
f0101b8c:	68 47 56 10 f0       	push   $0xf0105647
f0101b91:	68 6e 04 00 00       	push   $0x46e
f0101b96:	68 21 56 10 f0       	push   $0xf0105621
f0101b9b:	e8 00 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ba0:	6a 02                	push   $0x2
f0101ba2:	68 00 10 00 00       	push   $0x1000
f0101ba7:	56                   	push   %esi
f0101ba8:	50                   	push   %eax
f0101ba9:	e8 17 f5 ff ff       	call   f01010c5 <page_insert>
f0101bae:	83 c4 10             	add    $0x10,%esp
f0101bb1:	85 c0                	test   %eax,%eax
f0101bb3:	74 19                	je     f0101bce <mem_init+0xa76>
f0101bb5:	68 fc 50 10 f0       	push   $0xf01050fc
f0101bba:	68 47 56 10 f0       	push   $0xf0105647
f0101bbf:	68 71 04 00 00       	push   $0x471
f0101bc4:	68 21 56 10 f0       	push   $0xf0105621
f0101bc9:	e8 d2 e4 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bce:	83 ec 04             	sub    $0x4,%esp
f0101bd1:	6a 00                	push   $0x0
f0101bd3:	68 00 10 00 00       	push   $0x1000
f0101bd8:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101bde:	e8 ba f2 ff ff       	call   f0100e9d <pgdir_walk>
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	f6 00 02             	testb  $0x2,(%eax)
f0101be9:	75 19                	jne    f0101c04 <mem_init+0xaac>
f0101beb:	68 1c 52 10 f0       	push   $0xf010521c
f0101bf0:	68 47 56 10 f0       	push   $0xf0105647
f0101bf5:	68 72 04 00 00       	push   $0x472
f0101bfa:	68 21 56 10 f0       	push   $0xf0105621
f0101bff:	e8 9c e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c04:	83 ec 04             	sub    $0x4,%esp
f0101c07:	6a 00                	push   $0x0
f0101c09:	68 00 10 00 00       	push   $0x1000
f0101c0e:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c14:	e8 84 f2 ff ff       	call   f0100e9d <pgdir_walk>
f0101c19:	83 c4 10             	add    $0x10,%esp
f0101c1c:	f6 00 04             	testb  $0x4,(%eax)
f0101c1f:	74 19                	je     f0101c3a <mem_init+0xae2>
f0101c21:	68 50 52 10 f0       	push   $0xf0105250
f0101c26:	68 47 56 10 f0       	push   $0xf0105647
f0101c2b:	68 73 04 00 00       	push   $0x473
f0101c30:	68 21 56 10 f0       	push   $0xf0105621
f0101c35:	e8 66 e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c3a:	6a 02                	push   $0x2
f0101c3c:	68 00 00 40 00       	push   $0x400000
f0101c41:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c44:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c4a:	e8 76 f4 ff ff       	call   f01010c5 <page_insert>
f0101c4f:	83 c4 10             	add    $0x10,%esp
f0101c52:	85 c0                	test   %eax,%eax
f0101c54:	78 19                	js     f0101c6f <mem_init+0xb17>
f0101c56:	68 88 52 10 f0       	push   $0xf0105288
f0101c5b:	68 47 56 10 f0       	push   $0xf0105647
f0101c60:	68 76 04 00 00       	push   $0x476
f0101c65:	68 21 56 10 f0       	push   $0xf0105621
f0101c6a:	e8 31 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c6f:	6a 02                	push   $0x2
f0101c71:	68 00 10 00 00       	push   $0x1000
f0101c76:	53                   	push   %ebx
f0101c77:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101c7d:	e8 43 f4 ff ff       	call   f01010c5 <page_insert>
f0101c82:	83 c4 10             	add    $0x10,%esp
f0101c85:	85 c0                	test   %eax,%eax
f0101c87:	74 19                	je     f0101ca2 <mem_init+0xb4a>
f0101c89:	68 c0 52 10 f0       	push   $0xf01052c0
f0101c8e:	68 47 56 10 f0       	push   $0xf0105647
f0101c93:	68 79 04 00 00       	push   $0x479
f0101c98:	68 21 56 10 f0       	push   $0xf0105621
f0101c9d:	e8 fe e3 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ca2:	83 ec 04             	sub    $0x4,%esp
f0101ca5:	6a 00                	push   $0x0
f0101ca7:	68 00 10 00 00       	push   $0x1000
f0101cac:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101cb2:	e8 e6 f1 ff ff       	call   f0100e9d <pgdir_walk>
f0101cb7:	83 c4 10             	add    $0x10,%esp
f0101cba:	f6 00 04             	testb  $0x4,(%eax)
f0101cbd:	74 19                	je     f0101cd8 <mem_init+0xb80>
f0101cbf:	68 50 52 10 f0       	push   $0xf0105250
f0101cc4:	68 47 56 10 f0       	push   $0xf0105647
f0101cc9:	68 7a 04 00 00       	push   $0x47a
f0101cce:	68 21 56 10 f0       	push   $0xf0105621
f0101cd3:	e8 c8 e3 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101cd8:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101cde:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ce3:	89 f8                	mov    %edi,%eax
f0101ce5:	e8 9d ec ff ff       	call   f0100987 <check_va2pa>
f0101cea:	89 c1                	mov    %eax,%ecx
f0101cec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cef:	89 d8                	mov    %ebx,%eax
f0101cf1:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101cf7:	c1 f8 03             	sar    $0x3,%eax
f0101cfa:	c1 e0 0c             	shl    $0xc,%eax
f0101cfd:	39 c1                	cmp    %eax,%ecx
f0101cff:	74 19                	je     f0101d1a <mem_init+0xbc2>
f0101d01:	68 fc 52 10 f0       	push   $0xf01052fc
f0101d06:	68 47 56 10 f0       	push   $0xf0105647
f0101d0b:	68 7d 04 00 00       	push   $0x47d
f0101d10:	68 21 56 10 f0       	push   $0xf0105621
f0101d15:	e8 86 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d1a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d1f:	89 f8                	mov    %edi,%eax
f0101d21:	e8 61 ec ff ff       	call   f0100987 <check_va2pa>
f0101d26:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d29:	74 19                	je     f0101d44 <mem_init+0xbec>
f0101d2b:	68 28 53 10 f0       	push   $0xf0105328
f0101d30:	68 47 56 10 f0       	push   $0xf0105647
f0101d35:	68 7e 04 00 00       	push   $0x47e
f0101d3a:	68 21 56 10 f0       	push   $0xf0105621
f0101d3f:	e8 5c e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d44:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d49:	74 19                	je     f0101d64 <mem_init+0xc0c>
f0101d4b:	68 57 58 10 f0       	push   $0xf0105857
f0101d50:	68 47 56 10 f0       	push   $0xf0105647
f0101d55:	68 80 04 00 00       	push   $0x480
f0101d5a:	68 21 56 10 f0       	push   $0xf0105621
f0101d5f:	e8 3c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d64:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d69:	74 19                	je     f0101d84 <mem_init+0xc2c>
f0101d6b:	68 68 58 10 f0       	push   $0xf0105868
f0101d70:	68 47 56 10 f0       	push   $0xf0105647
f0101d75:	68 81 04 00 00       	push   $0x481
f0101d7a:	68 21 56 10 f0       	push   $0xf0105621
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d84:	83 ec 0c             	sub    $0xc,%esp
f0101d87:	6a 00                	push   $0x0
f0101d89:	e8 41 f0 ff ff       	call   f0100dcf <page_alloc>
f0101d8e:	83 c4 10             	add    $0x10,%esp
f0101d91:	85 c0                	test   %eax,%eax
f0101d93:	74 04                	je     f0101d99 <mem_init+0xc41>
f0101d95:	39 c6                	cmp    %eax,%esi
f0101d97:	74 19                	je     f0101db2 <mem_init+0xc5a>
f0101d99:	68 58 53 10 f0       	push   $0xf0105358
f0101d9e:	68 47 56 10 f0       	push   $0xf0105647
f0101da3:	68 84 04 00 00       	push   $0x484
f0101da8:	68 21 56 10 f0       	push   $0xf0105621
f0101dad:	e8 ee e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101db2:	83 ec 08             	sub    $0x8,%esp
f0101db5:	6a 00                	push   $0x0
f0101db7:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101dbd:	e8 b5 f2 ff ff       	call   f0101077 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dc2:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101dc8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dcd:	89 f8                	mov    %edi,%eax
f0101dcf:	e8 b3 eb ff ff       	call   f0100987 <check_va2pa>
f0101dd4:	83 c4 10             	add    $0x10,%esp
f0101dd7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dda:	74 19                	je     f0101df5 <mem_init+0xc9d>
f0101ddc:	68 7c 53 10 f0       	push   $0xf010537c
f0101de1:	68 47 56 10 f0       	push   $0xf0105647
f0101de6:	68 88 04 00 00       	push   $0x488
f0101deb:	68 21 56 10 f0       	push   $0xf0105621
f0101df0:	e8 ab e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101df5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dfa:	89 f8                	mov    %edi,%eax
f0101dfc:	e8 86 eb ff ff       	call   f0100987 <check_va2pa>
f0101e01:	89 da                	mov    %ebx,%edx
f0101e03:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101e09:	c1 fa 03             	sar    $0x3,%edx
f0101e0c:	c1 e2 0c             	shl    $0xc,%edx
f0101e0f:	39 d0                	cmp    %edx,%eax
f0101e11:	74 19                	je     f0101e2c <mem_init+0xcd4>
f0101e13:	68 28 53 10 f0       	push   $0xf0105328
f0101e18:	68 47 56 10 f0       	push   $0xf0105647
f0101e1d:	68 89 04 00 00       	push   $0x489
f0101e22:	68 21 56 10 f0       	push   $0xf0105621
f0101e27:	e8 74 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101e2c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e31:	74 19                	je     f0101e4c <mem_init+0xcf4>
f0101e33:	68 0e 58 10 f0       	push   $0xf010580e
f0101e38:	68 47 56 10 f0       	push   $0xf0105647
f0101e3d:	68 8a 04 00 00       	push   $0x48a
f0101e42:	68 21 56 10 f0       	push   $0xf0105621
f0101e47:	e8 54 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e4c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e51:	74 19                	je     f0101e6c <mem_init+0xd14>
f0101e53:	68 68 58 10 f0       	push   $0xf0105868
f0101e58:	68 47 56 10 f0       	push   $0xf0105647
f0101e5d:	68 8b 04 00 00       	push   $0x48b
f0101e62:	68 21 56 10 f0       	push   $0xf0105621
f0101e67:	e8 34 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e6c:	6a 00                	push   $0x0
f0101e6e:	68 00 10 00 00       	push   $0x1000
f0101e73:	53                   	push   %ebx
f0101e74:	57                   	push   %edi
f0101e75:	e8 4b f2 ff ff       	call   f01010c5 <page_insert>
f0101e7a:	83 c4 10             	add    $0x10,%esp
f0101e7d:	85 c0                	test   %eax,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xd42>
f0101e81:	68 a0 53 10 f0       	push   $0xf01053a0
f0101e86:	68 47 56 10 f0       	push   $0xf0105647
f0101e8b:	68 8e 04 00 00       	push   $0x48e
f0101e90:	68 21 56 10 f0       	push   $0xf0105621
f0101e95:	e8 06 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e9a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e9f:	75 19                	jne    f0101eba <mem_init+0xd62>
f0101ea1:	68 79 58 10 f0       	push   $0xf0105879
f0101ea6:	68 47 56 10 f0       	push   $0xf0105647
f0101eab:	68 8f 04 00 00       	push   $0x48f
f0101eb0:	68 21 56 10 f0       	push   $0xf0105621
f0101eb5:	e8 e6 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101eba:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101ebd:	74 19                	je     f0101ed8 <mem_init+0xd80>
f0101ebf:	68 85 58 10 f0       	push   $0xf0105885
f0101ec4:	68 47 56 10 f0       	push   $0xf0105647
f0101ec9:	68 90 04 00 00       	push   $0x490
f0101ece:	68 21 56 10 f0       	push   $0xf0105621
f0101ed3:	e8 c8 e1 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ed8:	83 ec 08             	sub    $0x8,%esp
f0101edb:	68 00 10 00 00       	push   $0x1000
f0101ee0:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101ee6:	e8 8c f1 ff ff       	call   f0101077 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eeb:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101ef1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef6:	89 f8                	mov    %edi,%eax
f0101ef8:	e8 8a ea ff ff       	call   f0100987 <check_va2pa>
f0101efd:	83 c4 10             	add    $0x10,%esp
f0101f00:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f03:	74 19                	je     f0101f1e <mem_init+0xdc6>
f0101f05:	68 7c 53 10 f0       	push   $0xf010537c
f0101f0a:	68 47 56 10 f0       	push   $0xf0105647
f0101f0f:	68 94 04 00 00       	push   $0x494
f0101f14:	68 21 56 10 f0       	push   $0xf0105621
f0101f19:	e8 82 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f1e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f23:	89 f8                	mov    %edi,%eax
f0101f25:	e8 5d ea ff ff       	call   f0100987 <check_va2pa>
f0101f2a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f2d:	74 19                	je     f0101f48 <mem_init+0xdf0>
f0101f2f:	68 d8 53 10 f0       	push   $0xf01053d8
f0101f34:	68 47 56 10 f0       	push   $0xf0105647
f0101f39:	68 95 04 00 00       	push   $0x495
f0101f3e:	68 21 56 10 f0       	push   $0xf0105621
f0101f43:	e8 58 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101f48:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f4d:	74 19                	je     f0101f68 <mem_init+0xe10>
f0101f4f:	68 9a 58 10 f0       	push   $0xf010589a
f0101f54:	68 47 56 10 f0       	push   $0xf0105647
f0101f59:	68 96 04 00 00       	push   $0x496
f0101f5e:	68 21 56 10 f0       	push   $0xf0105621
f0101f63:	e8 38 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f68:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f6d:	74 19                	je     f0101f88 <mem_init+0xe30>
f0101f6f:	68 68 58 10 f0       	push   $0xf0105868
f0101f74:	68 47 56 10 f0       	push   $0xf0105647
f0101f79:	68 97 04 00 00       	push   $0x497
f0101f7e:	68 21 56 10 f0       	push   $0xf0105621
f0101f83:	e8 18 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f88:	83 ec 0c             	sub    $0xc,%esp
f0101f8b:	6a 00                	push   $0x0
f0101f8d:	e8 3d ee ff ff       	call   f0100dcf <page_alloc>
f0101f92:	83 c4 10             	add    $0x10,%esp
f0101f95:	39 c3                	cmp    %eax,%ebx
f0101f97:	75 04                	jne    f0101f9d <mem_init+0xe45>
f0101f99:	85 c0                	test   %eax,%eax
f0101f9b:	75 19                	jne    f0101fb6 <mem_init+0xe5e>
f0101f9d:	68 00 54 10 f0       	push   $0xf0105400
f0101fa2:	68 47 56 10 f0       	push   $0xf0105647
f0101fa7:	68 9a 04 00 00       	push   $0x49a
f0101fac:	68 21 56 10 f0       	push   $0xf0105621
f0101fb1:	e8 ea e0 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101fb6:	83 ec 0c             	sub    $0xc,%esp
f0101fb9:	6a 00                	push   $0x0
f0101fbb:	e8 0f ee ff ff       	call   f0100dcf <page_alloc>
f0101fc0:	83 c4 10             	add    $0x10,%esp
f0101fc3:	85 c0                	test   %eax,%eax
f0101fc5:	74 19                	je     f0101fe0 <mem_init+0xe88>
f0101fc7:	68 bc 57 10 f0       	push   $0xf01057bc
f0101fcc:	68 47 56 10 f0       	push   $0xf0105647
f0101fd1:	68 9d 04 00 00       	push   $0x49d
f0101fd6:	68 21 56 10 f0       	push   $0xf0105621
f0101fdb:	e8 c0 e0 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fe0:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f0101fe6:	8b 11                	mov    (%ecx),%edx
f0101fe8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ff1:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101ff7:	c1 f8 03             	sar    $0x3,%eax
f0101ffa:	c1 e0 0c             	shl    $0xc,%eax
f0101ffd:	39 c2                	cmp    %eax,%edx
f0101fff:	74 19                	je     f010201a <mem_init+0xec2>
f0102001:	68 a4 50 10 f0       	push   $0xf01050a4
f0102006:	68 47 56 10 f0       	push   $0xf0105647
f010200b:	68 a0 04 00 00       	push   $0x4a0
f0102010:	68 21 56 10 f0       	push   $0xf0105621
f0102015:	e8 86 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010201a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102020:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102023:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102028:	74 19                	je     f0102043 <mem_init+0xeeb>
f010202a:	68 1f 58 10 f0       	push   $0xf010581f
f010202f:	68 47 56 10 f0       	push   $0xf0105647
f0102034:	68 a2 04 00 00       	push   $0x4a2
f0102039:	68 21 56 10 f0       	push   $0xf0105621
f010203e:	e8 5d e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102043:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102046:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010204c:	83 ec 0c             	sub    $0xc,%esp
f010204f:	50                   	push   %eax
f0102050:	e8 e4 ed ff ff       	call   f0100e39 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102055:	83 c4 0c             	add    $0xc,%esp
f0102058:	6a 01                	push   $0x1
f010205a:	68 00 10 40 00       	push   $0x401000
f010205f:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102065:	e8 33 ee ff ff       	call   f0100e9d <pgdir_walk>
f010206a:	89 c7                	mov    %eax,%edi
f010206c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010206f:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102074:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102077:	8b 40 04             	mov    0x4(%eax),%eax
f010207a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010207f:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f0102085:	89 c2                	mov    %eax,%edx
f0102087:	c1 ea 0c             	shr    $0xc,%edx
f010208a:	83 c4 10             	add    $0x10,%esp
f010208d:	39 ca                	cmp    %ecx,%edx
f010208f:	72 15                	jb     f01020a6 <mem_init+0xf4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102091:	50                   	push   %eax
f0102092:	68 e4 4d 10 f0       	push   $0xf0104de4
f0102097:	68 a9 04 00 00       	push   $0x4a9
f010209c:	68 21 56 10 f0       	push   $0xf0105621
f01020a1:	e8 fa df ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01020a6:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01020ab:	39 c7                	cmp    %eax,%edi
f01020ad:	74 19                	je     f01020c8 <mem_init+0xf70>
f01020af:	68 ab 58 10 f0       	push   $0xf01058ab
f01020b4:	68 47 56 10 f0       	push   $0xf0105647
f01020b9:	68 aa 04 00 00       	push   $0x4aa
f01020be:	68 21 56 10 f0       	push   $0xf0105621
f01020c3:	e8 d8 df ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01020c8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020cb:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01020d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020db:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01020e1:	c1 f8 03             	sar    $0x3,%eax
f01020e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020e7:	89 c2                	mov    %eax,%edx
f01020e9:	c1 ea 0c             	shr    $0xc,%edx
f01020ec:	39 d1                	cmp    %edx,%ecx
f01020ee:	77 12                	ja     f0102102 <mem_init+0xfaa>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020f0:	50                   	push   %eax
f01020f1:	68 e4 4d 10 f0       	push   $0xf0104de4
f01020f6:	6a 56                	push   $0x56
f01020f8:	68 2d 56 10 f0       	push   $0xf010562d
f01020fd:	e8 9e df ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102102:	83 ec 04             	sub    $0x4,%esp
f0102105:	68 00 10 00 00       	push   $0x1000
f010210a:	68 ff 00 00 00       	push   $0xff
f010210f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102114:	50                   	push   %eax
f0102115:	e8 f9 22 00 00       	call   f0104413 <memset>
	page_free(pp0);
f010211a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010211d:	89 3c 24             	mov    %edi,(%esp)
f0102120:	e8 14 ed ff ff       	call   f0100e39 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102125:	83 c4 0c             	add    $0xc,%esp
f0102128:	6a 01                	push   $0x1
f010212a:	6a 00                	push   $0x0
f010212c:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102132:	e8 66 ed ff ff       	call   f0100e9d <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102137:	89 fa                	mov    %edi,%edx
f0102139:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f010213f:	c1 fa 03             	sar    $0x3,%edx
f0102142:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102145:	89 d0                	mov    %edx,%eax
f0102147:	c1 e8 0c             	shr    $0xc,%eax
f010214a:	83 c4 10             	add    $0x10,%esp
f010214d:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102153:	72 12                	jb     f0102167 <mem_init+0x100f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102155:	52                   	push   %edx
f0102156:	68 e4 4d 10 f0       	push   $0xf0104de4
f010215b:	6a 56                	push   $0x56
f010215d:	68 2d 56 10 f0       	push   $0xf010562d
f0102162:	e8 39 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102167:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010216d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102170:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102176:	f6 00 01             	testb  $0x1,(%eax)
f0102179:	74 19                	je     f0102194 <mem_init+0x103c>
f010217b:	68 c3 58 10 f0       	push   $0xf01058c3
f0102180:	68 47 56 10 f0       	push   $0xf0105647
f0102185:	68 b4 04 00 00       	push   $0x4b4
f010218a:	68 21 56 10 f0       	push   $0xf0105621
f010218f:	e8 0c df ff ff       	call   f01000a0 <_panic>
f0102194:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102197:	39 c2                	cmp    %eax,%edx
f0102199:	75 db                	jne    f0102176 <mem_init+0x101e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010219b:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021a0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021a9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021af:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01021b2:	89 3d 80 1f 17 f0    	mov    %edi,0xf0171f80

	// free the pages we took
	page_free(pp0);
f01021b8:	83 ec 0c             	sub    $0xc,%esp
f01021bb:	50                   	push   %eax
f01021bc:	e8 78 ec ff ff       	call   f0100e39 <page_free>
	page_free(pp1);
f01021c1:	89 1c 24             	mov    %ebx,(%esp)
f01021c4:	e8 70 ec ff ff       	call   f0100e39 <page_free>
	page_free(pp2);
f01021c9:	89 34 24             	mov    %esi,(%esp)
f01021cc:	e8 68 ec ff ff       	call   f0100e39 <page_free>

	cprintf("check_page() succeeded!\n");
f01021d1:	c7 04 24 da 58 10 f0 	movl   $0xf01058da,(%esp)
f01021d8:	e8 6c 0e 00 00       	call   f0103049 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

    boot_map_region(kern_pgdir,
f01021dd:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021e2:	83 c4 10             	add    $0x10,%esp
f01021e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021ea:	77 15                	ja     f0102201 <mem_init+0x10a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ec:	50                   	push   %eax
f01021ed:	68 18 4f 10 f0       	push   $0xf0104f18
f01021f2:	68 c5 00 00 00       	push   $0xc5
f01021f7:	68 21 56 10 f0       	push   $0xf0105621
f01021fc:	e8 9f de ff ff       	call   f01000a0 <_panic>

                    UPAGES,

                    ROUNDUP((sizeof(struct PageInfo) * npages), PGSIZE),
f0102201:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f0102207:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

    boot_map_region(kern_pgdir,
f010220e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102214:	83 ec 08             	sub    $0x8,%esp
f0102217:	6a 05                	push   $0x5
f0102219:	05 00 00 00 10       	add    $0x10000000,%eax
f010221e:	50                   	push   %eax
f010221f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102224:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102229:	e8 5b ed ff ff       	call   f0100f89 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
 boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV*sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
f010222e:	a1 8c 1f 17 f0       	mov    0xf0171f8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102233:	83 c4 10             	add    $0x10,%esp
f0102236:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010223b:	77 15                	ja     f0102252 <mem_init+0x10fa>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010223d:	50                   	push   %eax
f010223e:	68 18 4f 10 f0       	push   $0xf0104f18
f0102243:	68 d0 00 00 00       	push   $0xd0
f0102248:	68 21 56 10 f0       	push   $0xf0105621
f010224d:	e8 4e de ff ff       	call   f01000a0 <_panic>
f0102252:	83 ec 08             	sub    $0x8,%esp
f0102255:	6a 05                	push   $0x5
f0102257:	05 00 00 00 10       	add    $0x10000000,%eax
f010225c:	50                   	push   %eax
f010225d:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102262:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102267:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010226c:	e8 18 ed ff ff       	call   f0100f89 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102271:	83 c4 10             	add    $0x10,%esp
f0102274:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102279:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010227e:	77 15                	ja     f0102295 <mem_init+0x113d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102280:	50                   	push   %eax
f0102281:	68 18 4f 10 f0       	push   $0xf0104f18
f0102286:	68 e4 00 00 00       	push   $0xe4
f010228b:	68 21 56 10 f0       	push   $0xf0105621
f0102290:	e8 0b de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

    boot_map_region(kern_pgdir,
f0102295:	83 ec 08             	sub    $0x8,%esp
f0102298:	6a 03                	push   $0x3
f010229a:	68 00 10 11 00       	push   $0x111000
f010229f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022a4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01022a9:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01022ae:	e8 d6 ec ff ff       	call   f0100f89 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

    boot_map_region(kern_pgdir,
f01022b3:	83 c4 08             	add    $0x8,%esp
f01022b6:	6a 03                	push   $0x3
f01022b8:	6a 00                	push   $0x0
f01022ba:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01022bf:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022c4:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01022c9:	e8 bb ec ff ff       	call   f0100f89 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01022ce:	8b 1d 48 2c 17 f0    	mov    0xf0172c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01022d4:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f01022d9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022dc:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022e3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022e8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022eb:	8b 3d 4c 2c 17 f0    	mov    0xf0172c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022f1:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01022f4:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022f7:	be 00 00 00 00       	mov    $0x0,%esi
f01022fc:	eb 55                	jmp    f0102353 <mem_init+0x11fb>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022fe:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102304:	89 d8                	mov    %ebx,%eax
f0102306:	e8 7c e6 ff ff       	call   f0100987 <check_va2pa>
f010230b:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102312:	77 15                	ja     f0102329 <mem_init+0x11d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102314:	57                   	push   %edi
f0102315:	68 18 4f 10 f0       	push   $0xf0104f18
f010231a:	68 f1 03 00 00       	push   $0x3f1
f010231f:	68 21 56 10 f0       	push   $0xf0105621
f0102324:	e8 77 dd ff ff       	call   f01000a0 <_panic>
f0102329:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102330:	39 d0                	cmp    %edx,%eax
f0102332:	74 19                	je     f010234d <mem_init+0x11f5>
f0102334:	68 24 54 10 f0       	push   $0xf0105424
f0102339:	68 47 56 10 f0       	push   $0xf0105647
f010233e:	68 f1 03 00 00       	push   $0x3f1
f0102343:	68 21 56 10 f0       	push   $0xf0105621
f0102348:	e8 53 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010234d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102353:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102356:	77 a6                	ja     f01022fe <mem_init+0x11a6>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102358:	8b 3d 8c 1f 17 f0    	mov    0xf0171f8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010235e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102361:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102366:	89 f2                	mov    %esi,%edx
f0102368:	89 d8                	mov    %ebx,%eax
f010236a:	e8 18 e6 ff ff       	call   f0100987 <check_va2pa>
f010236f:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102376:	77 15                	ja     f010238d <mem_init+0x1235>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102378:	57                   	push   %edi
f0102379:	68 18 4f 10 f0       	push   $0xf0104f18
f010237e:	68 f6 03 00 00       	push   $0x3f6
f0102383:	68 21 56 10 f0       	push   $0xf0105621
f0102388:	e8 13 dd ff ff       	call   f01000a0 <_panic>
f010238d:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102394:	39 c2                	cmp    %eax,%edx
f0102396:	74 19                	je     f01023b1 <mem_init+0x1259>
f0102398:	68 58 54 10 f0       	push   $0xf0105458
f010239d:	68 47 56 10 f0       	push   $0xf0105647
f01023a2:	68 f6 03 00 00       	push   $0x3f6
f01023a7:	68 21 56 10 f0       	push   $0xf0105621
f01023ac:	e8 ef dc ff ff       	call   f01000a0 <_panic>
f01023b1:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01023b7:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01023bd:	75 a7                	jne    f0102366 <mem_init+0x120e>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023bf:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01023c2:	c1 e7 0c             	shl    $0xc,%edi
f01023c5:	be 00 00 00 00       	mov    $0x0,%esi
f01023ca:	eb 30                	jmp    f01023fc <mem_init+0x12a4>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01023cc:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01023d2:	89 d8                	mov    %ebx,%eax
f01023d4:	e8 ae e5 ff ff       	call   f0100987 <check_va2pa>
f01023d9:	39 c6                	cmp    %eax,%esi
f01023db:	74 19                	je     f01023f6 <mem_init+0x129e>
f01023dd:	68 8c 54 10 f0       	push   $0xf010548c
f01023e2:	68 47 56 10 f0       	push   $0xf0105647
f01023e7:	68 fa 03 00 00       	push   $0x3fa
f01023ec:	68 21 56 10 f0       	push   $0xf0105621
f01023f1:	e8 aa dc ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023f6:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023fc:	39 fe                	cmp    %edi,%esi
f01023fe:	72 cc                	jb     f01023cc <mem_init+0x1274>
f0102400:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102405:	89 f2                	mov    %esi,%edx
f0102407:	89 d8                	mov    %ebx,%eax
f0102409:	e8 79 e5 ff ff       	call   f0100987 <check_va2pa>
f010240e:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f0102414:	39 c2                	cmp    %eax,%edx
f0102416:	74 19                	je     f0102431 <mem_init+0x12d9>
f0102418:	68 b4 54 10 f0       	push   $0xf01054b4
f010241d:	68 47 56 10 f0       	push   $0xf0105647
f0102422:	68 fe 03 00 00       	push   $0x3fe
f0102427:	68 21 56 10 f0       	push   $0xf0105621
f010242c:	e8 6f dc ff ff       	call   f01000a0 <_panic>
f0102431:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102437:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010243d:	75 c6                	jne    f0102405 <mem_init+0x12ad>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010243f:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102444:	89 d8                	mov    %ebx,%eax
f0102446:	e8 3c e5 ff ff       	call   f0100987 <check_va2pa>
f010244b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010244e:	74 51                	je     f01024a1 <mem_init+0x1349>
f0102450:	68 fc 54 10 f0       	push   $0xf01054fc
f0102455:	68 47 56 10 f0       	push   $0xf0105647
f010245a:	68 ff 03 00 00       	push   $0x3ff
f010245f:	68 21 56 10 f0       	push   $0xf0105621
f0102464:	e8 37 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102469:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010246e:	72 36                	jb     f01024a6 <mem_init+0x134e>
f0102470:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102475:	76 07                	jbe    f010247e <mem_init+0x1326>
f0102477:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010247c:	75 28                	jne    f01024a6 <mem_init+0x134e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010247e:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102482:	0f 85 83 00 00 00    	jne    f010250b <mem_init+0x13b3>
f0102488:	68 f3 58 10 f0       	push   $0xf01058f3
f010248d:	68 47 56 10 f0       	push   $0xf0105647
f0102492:	68 08 04 00 00       	push   $0x408
f0102497:	68 21 56 10 f0       	push   $0xf0105621
f010249c:	e8 ff db ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01024a1:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01024a6:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01024ab:	76 3f                	jbe    f01024ec <mem_init+0x1394>
				assert(pgdir[i] & PTE_P);
f01024ad:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01024b0:	f6 c2 01             	test   $0x1,%dl
f01024b3:	75 19                	jne    f01024ce <mem_init+0x1376>
f01024b5:	68 f3 58 10 f0       	push   $0xf01058f3
f01024ba:	68 47 56 10 f0       	push   $0xf0105647
f01024bf:	68 0c 04 00 00       	push   $0x40c
f01024c4:	68 21 56 10 f0       	push   $0xf0105621
f01024c9:	e8 d2 db ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01024ce:	f6 c2 02             	test   $0x2,%dl
f01024d1:	75 38                	jne    f010250b <mem_init+0x13b3>
f01024d3:	68 04 59 10 f0       	push   $0xf0105904
f01024d8:	68 47 56 10 f0       	push   $0xf0105647
f01024dd:	68 0d 04 00 00       	push   $0x40d
f01024e2:	68 21 56 10 f0       	push   $0xf0105621
f01024e7:	e8 b4 db ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01024ec:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01024f0:	74 19                	je     f010250b <mem_init+0x13b3>
f01024f2:	68 15 59 10 f0       	push   $0xf0105915
f01024f7:	68 47 56 10 f0       	push   $0xf0105647
f01024fc:	68 0f 04 00 00       	push   $0x40f
f0102501:	68 21 56 10 f0       	push   $0xf0105621
f0102506:	e8 95 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010250b:	83 c0 01             	add    $0x1,%eax
f010250e:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102513:	0f 86 50 ff ff ff    	jbe    f0102469 <mem_init+0x1311>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102519:	83 ec 0c             	sub    $0xc,%esp
f010251c:	68 2c 55 10 f0       	push   $0xf010552c
f0102521:	e8 23 0b 00 00       	call   f0103049 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102526:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010252b:	83 c4 10             	add    $0x10,%esp
f010252e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102533:	77 15                	ja     f010254a <mem_init+0x13f2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102535:	50                   	push   %eax
f0102536:	68 18 4f 10 f0       	push   $0xf0104f18
f010253b:	68 05 01 00 00       	push   $0x105
f0102540:	68 21 56 10 f0       	push   $0xf0105621
f0102545:	e8 56 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010254a:	05 00 00 00 10       	add    $0x10000000,%eax
f010254f:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102552:	b8 00 00 00 00       	mov    $0x0,%eax
f0102557:	e8 8f e4 ff ff       	call   f01009eb <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010255c:	0f 20 c0             	mov    %cr0,%eax
f010255f:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102562:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102567:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010256a:	83 ec 0c             	sub    $0xc,%esp
f010256d:	6a 00                	push   $0x0
f010256f:	e8 5b e8 ff ff       	call   f0100dcf <page_alloc>
f0102574:	89 c3                	mov    %eax,%ebx
f0102576:	83 c4 10             	add    $0x10,%esp
f0102579:	85 c0                	test   %eax,%eax
f010257b:	75 19                	jne    f0102596 <mem_init+0x143e>
f010257d:	68 11 57 10 f0       	push   $0xf0105711
f0102582:	68 47 56 10 f0       	push   $0xf0105647
f0102587:	68 cf 04 00 00       	push   $0x4cf
f010258c:	68 21 56 10 f0       	push   $0xf0105621
f0102591:	e8 0a db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102596:	83 ec 0c             	sub    $0xc,%esp
f0102599:	6a 00                	push   $0x0
f010259b:	e8 2f e8 ff ff       	call   f0100dcf <page_alloc>
f01025a0:	89 c7                	mov    %eax,%edi
f01025a2:	83 c4 10             	add    $0x10,%esp
f01025a5:	85 c0                	test   %eax,%eax
f01025a7:	75 19                	jne    f01025c2 <mem_init+0x146a>
f01025a9:	68 27 57 10 f0       	push   $0xf0105727
f01025ae:	68 47 56 10 f0       	push   $0xf0105647
f01025b3:	68 d0 04 00 00       	push   $0x4d0
f01025b8:	68 21 56 10 f0       	push   $0xf0105621
f01025bd:	e8 de da ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01025c2:	83 ec 0c             	sub    $0xc,%esp
f01025c5:	6a 00                	push   $0x0
f01025c7:	e8 03 e8 ff ff       	call   f0100dcf <page_alloc>
f01025cc:	89 c6                	mov    %eax,%esi
f01025ce:	83 c4 10             	add    $0x10,%esp
f01025d1:	85 c0                	test   %eax,%eax
f01025d3:	75 19                	jne    f01025ee <mem_init+0x1496>
f01025d5:	68 3d 57 10 f0       	push   $0xf010573d
f01025da:	68 47 56 10 f0       	push   $0xf0105647
f01025df:	68 d1 04 00 00       	push   $0x4d1
f01025e4:	68 21 56 10 f0       	push   $0xf0105621
f01025e9:	e8 b2 da ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01025ee:	83 ec 0c             	sub    $0xc,%esp
f01025f1:	53                   	push   %ebx
f01025f2:	e8 42 e8 ff ff       	call   f0100e39 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025f7:	89 f8                	mov    %edi,%eax
f01025f9:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01025ff:	c1 f8 03             	sar    $0x3,%eax
f0102602:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102605:	89 c2                	mov    %eax,%edx
f0102607:	c1 ea 0c             	shr    $0xc,%edx
f010260a:	83 c4 10             	add    $0x10,%esp
f010260d:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102613:	72 12                	jb     f0102627 <mem_init+0x14cf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102615:	50                   	push   %eax
f0102616:	68 e4 4d 10 f0       	push   $0xf0104de4
f010261b:	6a 56                	push   $0x56
f010261d:	68 2d 56 10 f0       	push   $0xf010562d
f0102622:	e8 79 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102627:	83 ec 04             	sub    $0x4,%esp
f010262a:	68 00 10 00 00       	push   $0x1000
f010262f:	6a 01                	push   $0x1
f0102631:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102636:	50                   	push   %eax
f0102637:	e8 d7 1d 00 00       	call   f0104413 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010263c:	89 f0                	mov    %esi,%eax
f010263e:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102644:	c1 f8 03             	sar    $0x3,%eax
f0102647:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010264a:	89 c2                	mov    %eax,%edx
f010264c:	c1 ea 0c             	shr    $0xc,%edx
f010264f:	83 c4 10             	add    $0x10,%esp
f0102652:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102658:	72 12                	jb     f010266c <mem_init+0x1514>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010265a:	50                   	push   %eax
f010265b:	68 e4 4d 10 f0       	push   $0xf0104de4
f0102660:	6a 56                	push   $0x56
f0102662:	68 2d 56 10 f0       	push   $0xf010562d
f0102667:	e8 34 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010266c:	83 ec 04             	sub    $0x4,%esp
f010266f:	68 00 10 00 00       	push   $0x1000
f0102674:	6a 02                	push   $0x2
f0102676:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010267b:	50                   	push   %eax
f010267c:	e8 92 1d 00 00       	call   f0104413 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102681:	6a 02                	push   $0x2
f0102683:	68 00 10 00 00       	push   $0x1000
f0102688:	57                   	push   %edi
f0102689:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010268f:	e8 31 ea ff ff       	call   f01010c5 <page_insert>
	assert(pp1->pp_ref == 1);
f0102694:	83 c4 20             	add    $0x20,%esp
f0102697:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010269c:	74 19                	je     f01026b7 <mem_init+0x155f>
f010269e:	68 0e 58 10 f0       	push   $0xf010580e
f01026a3:	68 47 56 10 f0       	push   $0xf0105647
f01026a8:	68 d6 04 00 00       	push   $0x4d6
f01026ad:	68 21 56 10 f0       	push   $0xf0105621
f01026b2:	e8 e9 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01026b7:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01026be:	01 01 01 
f01026c1:	74 19                	je     f01026dc <mem_init+0x1584>
f01026c3:	68 4c 55 10 f0       	push   $0xf010554c
f01026c8:	68 47 56 10 f0       	push   $0xf0105647
f01026cd:	68 d7 04 00 00       	push   $0x4d7
f01026d2:	68 21 56 10 f0       	push   $0xf0105621
f01026d7:	e8 c4 d9 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01026dc:	6a 02                	push   $0x2
f01026de:	68 00 10 00 00       	push   $0x1000
f01026e3:	56                   	push   %esi
f01026e4:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01026ea:	e8 d6 e9 ff ff       	call   f01010c5 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01026ef:	83 c4 10             	add    $0x10,%esp
f01026f2:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01026f9:	02 02 02 
f01026fc:	74 19                	je     f0102717 <mem_init+0x15bf>
f01026fe:	68 70 55 10 f0       	push   $0xf0105570
f0102703:	68 47 56 10 f0       	push   $0xf0105647
f0102708:	68 d9 04 00 00       	push   $0x4d9
f010270d:	68 21 56 10 f0       	push   $0xf0105621
f0102712:	e8 89 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102717:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010271c:	74 19                	je     f0102737 <mem_init+0x15df>
f010271e:	68 30 58 10 f0       	push   $0xf0105830
f0102723:	68 47 56 10 f0       	push   $0xf0105647
f0102728:	68 da 04 00 00       	push   $0x4da
f010272d:	68 21 56 10 f0       	push   $0xf0105621
f0102732:	e8 69 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102737:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010273c:	74 19                	je     f0102757 <mem_init+0x15ff>
f010273e:	68 9a 58 10 f0       	push   $0xf010589a
f0102743:	68 47 56 10 f0       	push   $0xf0105647
f0102748:	68 db 04 00 00       	push   $0x4db
f010274d:	68 21 56 10 f0       	push   $0xf0105621
f0102752:	e8 49 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102757:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010275e:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102761:	89 f0                	mov    %esi,%eax
f0102763:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102769:	c1 f8 03             	sar    $0x3,%eax
f010276c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010276f:	89 c2                	mov    %eax,%edx
f0102771:	c1 ea 0c             	shr    $0xc,%edx
f0102774:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f010277a:	72 12                	jb     f010278e <mem_init+0x1636>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010277c:	50                   	push   %eax
f010277d:	68 e4 4d 10 f0       	push   $0xf0104de4
f0102782:	6a 56                	push   $0x56
f0102784:	68 2d 56 10 f0       	push   $0xf010562d
f0102789:	e8 12 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010278e:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102795:	03 03 03 
f0102798:	74 19                	je     f01027b3 <mem_init+0x165b>
f010279a:	68 94 55 10 f0       	push   $0xf0105594
f010279f:	68 47 56 10 f0       	push   $0xf0105647
f01027a4:	68 dd 04 00 00       	push   $0x4dd
f01027a9:	68 21 56 10 f0       	push   $0xf0105621
f01027ae:	e8 ed d8 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01027b3:	83 ec 08             	sub    $0x8,%esp
f01027b6:	68 00 10 00 00       	push   $0x1000
f01027bb:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01027c1:	e8 b1 e8 ff ff       	call   f0101077 <page_remove>
	assert(pp2->pp_ref == 0);
f01027c6:	83 c4 10             	add    $0x10,%esp
f01027c9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027ce:	74 19                	je     f01027e9 <mem_init+0x1691>
f01027d0:	68 68 58 10 f0       	push   $0xf0105868
f01027d5:	68 47 56 10 f0       	push   $0xf0105647
f01027da:	68 df 04 00 00       	push   $0x4df
f01027df:	68 21 56 10 f0       	push   $0xf0105621
f01027e4:	e8 b7 d8 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027e9:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f01027ef:	8b 11                	mov    (%ecx),%edx
f01027f1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027f7:	89 d8                	mov    %ebx,%eax
f01027f9:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01027ff:	c1 f8 03             	sar    $0x3,%eax
f0102802:	c1 e0 0c             	shl    $0xc,%eax
f0102805:	39 c2                	cmp    %eax,%edx
f0102807:	74 19                	je     f0102822 <mem_init+0x16ca>
f0102809:	68 a4 50 10 f0       	push   $0xf01050a4
f010280e:	68 47 56 10 f0       	push   $0xf0105647
f0102813:	68 e2 04 00 00       	push   $0x4e2
f0102818:	68 21 56 10 f0       	push   $0xf0105621
f010281d:	e8 7e d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102822:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102828:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010282d:	74 19                	je     f0102848 <mem_init+0x16f0>
f010282f:	68 1f 58 10 f0       	push   $0xf010581f
f0102834:	68 47 56 10 f0       	push   $0xf0105647
f0102839:	68 e4 04 00 00       	push   $0x4e4
f010283e:	68 21 56 10 f0       	push   $0xf0105621
f0102843:	e8 58 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102848:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010284e:	83 ec 0c             	sub    $0xc,%esp
f0102851:	53                   	push   %ebx
f0102852:	e8 e2 e5 ff ff       	call   f0100e39 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102857:	c7 04 24 c0 55 10 f0 	movl   $0xf01055c0,(%esp)
f010285e:	e8 e6 07 00 00       	call   f0103049 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102863:	83 c4 10             	add    $0x10,%esp
f0102866:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102869:	5b                   	pop    %ebx
f010286a:	5e                   	pop    %esi
f010286b:	5f                   	pop    %edi
f010286c:	5d                   	pop    %ebp
f010286d:	c3                   	ret    

f010286e <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010286e:	55                   	push   %ebp
f010286f:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102871:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102874:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102877:	5d                   	pop    %ebp
f0102878:	c3                   	ret    

f0102879 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102879:	55                   	push   %ebp
f010287a:	89 e5                	mov    %esp,%ebp
f010287c:	57                   	push   %edi
f010287d:	56                   	push   %esi
f010287e:	53                   	push   %ebx
f010287f:	83 ec 1c             	sub    $0x1c,%esp
f0102882:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.

    uintptr_t start_va = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102885:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102888:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010288d:	89 c3                	mov    %eax,%ebx
f010288f:	89 45 e0             	mov    %eax,-0x20(%ebp)
    uintptr_t end_va = ROUNDUP((uintptr_t)va + len, PGSIZE);
f0102892:	8b 45 10             	mov    0x10(%ebp),%eax
f0102895:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102898:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f010289f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01028a4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for (uintptr_t cur_va=start_va; cur_va<end_va; cur_va+=PGSIZE) {
        pte_t *cur_pte = pgdir_walk(env->env_pgdir, (void *)cur_va, 0);
        if (cur_pte == NULL || (*cur_pte & (perm|PTE_P)) != (perm|PTE_P) || cur_va >= ULIM) {
f01028a7:	8b 75 14             	mov    0x14(%ebp),%esi
f01028aa:	83 ce 01             	or     $0x1,%esi
{
	// LAB 3: Your code here.

    uintptr_t start_va = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t end_va = ROUNDUP((uintptr_t)va + len, PGSIZE);
    for (uintptr_t cur_va=start_va; cur_va<end_va; cur_va+=PGSIZE) {
f01028ad:	eb 4c                	jmp    f01028fb <user_mem_check+0x82>
        pte_t *cur_pte = pgdir_walk(env->env_pgdir, (void *)cur_va, 0);
f01028af:	83 ec 04             	sub    $0x4,%esp
f01028b2:	6a 00                	push   $0x0
f01028b4:	53                   	push   %ebx
f01028b5:	ff 77 5c             	pushl  0x5c(%edi)
f01028b8:	e8 e0 e5 ff ff       	call   f0100e9d <pgdir_walk>
        if (cur_pte == NULL || (*cur_pte & (perm|PTE_P)) != (perm|PTE_P) || cur_va >= ULIM) {
f01028bd:	83 c4 10             	add    $0x10,%esp
f01028c0:	85 c0                	test   %eax,%eax
f01028c2:	74 10                	je     f01028d4 <user_mem_check+0x5b>
f01028c4:	89 f2                	mov    %esi,%edx
f01028c6:	23 10                	and    (%eax),%edx
f01028c8:	39 f2                	cmp    %esi,%edx
f01028ca:	75 08                	jne    f01028d4 <user_mem_check+0x5b>
f01028cc:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01028d2:	76 21                	jbe    f01028f5 <user_mem_check+0x7c>
            if (cur_va == start_va) {
f01028d4:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01028d7:	75 0f                	jne    f01028e8 <user_mem_check+0x6f>
                user_mem_check_addr = (uintptr_t)va;
f01028d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028dc:	a3 7c 1f 17 f0       	mov    %eax,0xf0171f7c
            } else {
                user_mem_check_addr = cur_va;
            }
            return -E_FAULT;
f01028e1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01028e6:	eb 1d                	jmp    f0102905 <user_mem_check+0x8c>
        pte_t *cur_pte = pgdir_walk(env->env_pgdir, (void *)cur_va, 0);
        if (cur_pte == NULL || (*cur_pte & (perm|PTE_P)) != (perm|PTE_P) || cur_va >= ULIM) {
            if (cur_va == start_va) {
                user_mem_check_addr = (uintptr_t)va;
            } else {
                user_mem_check_addr = cur_va;
f01028e8:	89 1d 7c 1f 17 f0    	mov    %ebx,0xf0171f7c
            }
            return -E_FAULT;
f01028ee:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01028f3:	eb 10                	jmp    f0102905 <user_mem_check+0x8c>
{
	// LAB 3: Your code here.

    uintptr_t start_va = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t end_va = ROUNDUP((uintptr_t)va + len, PGSIZE);
    for (uintptr_t cur_va=start_va; cur_va<end_va; cur_va+=PGSIZE) {
f01028f5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028fb:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01028fe:	72 af                	jb     f01028af <user_mem_check+0x36>
                user_mem_check_addr = cur_va;
            }
            return -E_FAULT;
        }
    }
    return 0;
f0102900:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102905:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102908:	5b                   	pop    %ebx
f0102909:	5e                   	pop    %esi
f010290a:	5f                   	pop    %edi
f010290b:	5d                   	pop    %ebp
f010290c:	c3                   	ret    

f010290d <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010290d:	55                   	push   %ebp
f010290e:	89 e5                	mov    %esp,%ebp
f0102910:	53                   	push   %ebx
f0102911:	83 ec 04             	sub    $0x4,%esp
f0102914:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102917:	8b 45 14             	mov    0x14(%ebp),%eax
f010291a:	83 c8 04             	or     $0x4,%eax
f010291d:	50                   	push   %eax
f010291e:	ff 75 10             	pushl  0x10(%ebp)
f0102921:	ff 75 0c             	pushl  0xc(%ebp)
f0102924:	53                   	push   %ebx
f0102925:	e8 4f ff ff ff       	call   f0102879 <user_mem_check>
f010292a:	83 c4 10             	add    $0x10,%esp
f010292d:	85 c0                	test   %eax,%eax
f010292f:	79 21                	jns    f0102952 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102931:	83 ec 04             	sub    $0x4,%esp
f0102934:	ff 35 7c 1f 17 f0    	pushl  0xf0171f7c
f010293a:	ff 73 48             	pushl  0x48(%ebx)
f010293d:	68 ec 55 10 f0       	push   $0xf01055ec
f0102942:	e8 02 07 00 00       	call   f0103049 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102947:	89 1c 24             	mov    %ebx,(%esp)
f010294a:	e8 e1 05 00 00       	call   f0102f30 <env_destroy>
f010294f:	83 c4 10             	add    $0x10,%esp
	}
}
f0102952:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102955:	c9                   	leave  
f0102956:	c3                   	ret    

f0102957 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102957:	55                   	push   %ebp
f0102958:	89 e5                	mov    %esp,%ebp
f010295a:	57                   	push   %edi
f010295b:	56                   	push   %esi
f010295c:	53                   	push   %ebx
f010295d:	83 ec 1c             	sub    $0x1c,%esp
f0102960:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
    uintptr_t va_start = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t va_end = ROUNDUP((uintptr_t)va + len, PGSIZE);
f0102962:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102969:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010296e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    struct PageInfo *pginfo = NULL;
    for (int cur_va=va_start; cur_va<va_end; cur_va+=PGSIZE) {
f0102971:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102977:	89 d3                	mov    %edx,%ebx
f0102979:	eb 4c                	jmp    f01029c7 <region_alloc+0x70>
        pginfo = page_alloc(0);
f010297b:	83 ec 0c             	sub    $0xc,%esp
f010297e:	6a 00                	push   $0x0
f0102980:	e8 4a e4 ff ff       	call   f0100dcf <page_alloc>
f0102985:	89 c6                	mov    %eax,%esi
        if (!pginfo) {
f0102987:	83 c4 10             	add    $0x10,%esp
f010298a:	85 c0                	test   %eax,%eax
f010298c:	75 16                	jne    f01029a4 <region_alloc+0x4d>
            int r = -E_NO_MEM;
            panic("region_alloc: %e" , r);
f010298e:	6a fc                	push   $0xfffffffc
f0102990:	68 23 59 10 f0       	push   $0xf0105923
f0102995:	68 1f 01 00 00       	push   $0x11f
f010299a:	68 34 59 10 f0       	push   $0xf0105934
f010299f:	e8 fc d6 ff ff       	call   f01000a0 <_panic>
        }
        cprintf("insert page at %08x\n",cur_va);
f01029a4:	83 ec 08             	sub    $0x8,%esp
f01029a7:	53                   	push   %ebx
f01029a8:	68 3f 59 10 f0       	push   $0xf010593f
f01029ad:	e8 97 06 00 00       	call   f0103049 <cprintf>
        page_insert(e->env_pgdir, pginfo, (void *)cur_va, PTE_U | PTE_W | PTE_P);
f01029b2:	6a 07                	push   $0x7
f01029b4:	53                   	push   %ebx
f01029b5:	56                   	push   %esi
f01029b6:	ff 77 5c             	pushl  0x5c(%edi)
f01029b9:	e8 07 e7 ff ff       	call   f01010c5 <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
    uintptr_t va_start = ROUNDDOWN((uintptr_t)va, PGSIZE);
    uintptr_t va_end = ROUNDUP((uintptr_t)va + len, PGSIZE);
    struct PageInfo *pginfo = NULL;
    for (int cur_va=va_start; cur_va<va_end; cur_va+=PGSIZE) {
f01029be:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029c4:	83 c4 20             	add    $0x20,%esp
f01029c7:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01029ca:	72 af                	jb     f010297b <region_alloc+0x24>
            panic("region_alloc: %e" , r);
        }
        cprintf("insert page at %08x\n",cur_va);
        page_insert(e->env_pgdir, pginfo, (void *)cur_va, PTE_U | PTE_W | PTE_P);
    }
}
f01029cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029cf:	5b                   	pop    %ebx
f01029d0:	5e                   	pop    %esi
f01029d1:	5f                   	pop    %edi
f01029d2:	5d                   	pop    %ebp
f01029d3:	c3                   	ret    

f01029d4 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01029d4:	55                   	push   %ebp
f01029d5:	89 e5                	mov    %esp,%ebp
f01029d7:	8b 55 08             	mov    0x8(%ebp),%edx
f01029da:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01029dd:	85 d2                	test   %edx,%edx
f01029df:	75 11                	jne    f01029f2 <envid2env+0x1e>
		*env_store = curenv;
f01029e1:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f01029e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029e9:	89 01                	mov    %eax,(%ecx)
		return 0;
f01029eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f0:	eb 5e                	jmp    f0102a50 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01029f2:	89 d0                	mov    %edx,%eax
f01029f4:	25 ff 03 00 00       	and    $0x3ff,%eax
f01029f9:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01029fc:	c1 e0 05             	shl    $0x5,%eax
f01029ff:	03 05 8c 1f 17 f0    	add    0xf0171f8c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102a05:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102a09:	74 05                	je     f0102a10 <envid2env+0x3c>
f0102a0b:	3b 50 48             	cmp    0x48(%eax),%edx
f0102a0e:	74 10                	je     f0102a20 <envid2env+0x4c>
		*env_store = 0;
f0102a10:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a13:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102a19:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102a1e:	eb 30                	jmp    f0102a50 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102a20:	84 c9                	test   %cl,%cl
f0102a22:	74 22                	je     f0102a46 <envid2env+0x72>
f0102a24:	8b 15 88 1f 17 f0    	mov    0xf0171f88,%edx
f0102a2a:	39 d0                	cmp    %edx,%eax
f0102a2c:	74 18                	je     f0102a46 <envid2env+0x72>
f0102a2e:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102a31:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102a34:	74 10                	je     f0102a46 <envid2env+0x72>
		*env_store = 0;
f0102a36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a39:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102a3f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102a44:	eb 0a                	jmp    f0102a50 <envid2env+0x7c>
	}

	*env_store = e;
f0102a46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102a49:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102a4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a50:	5d                   	pop    %ebp
f0102a51:	c3                   	ret    

f0102a52 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102a52:	55                   	push   %ebp
f0102a53:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102a55:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102a5a:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102a5d:	b8 23 00 00 00       	mov    $0x23,%eax
f0102a62:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102a64:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102a66:	b8 10 00 00 00       	mov    $0x10,%eax
f0102a6b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102a6d:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102a6f:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102a71:	ea 78 2a 10 f0 08 00 	ljmp   $0x8,$0xf0102a78
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102a78:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a7d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102a80:	5d                   	pop    %ebp
f0102a81:	c3                   	ret    

f0102a82 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102a82:	55                   	push   %ebp
f0102a83:	89 e5                	mov    %esp,%ebp
f0102a85:	56                   	push   %esi
f0102a86:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
int i = NENV;
    while (i>0) {
        i--;
        envs[i].env_id = 0;
f0102a87:	8b 35 8c 1f 17 f0    	mov    0xf0171f8c,%esi
f0102a8d:	8b 15 90 1f 17 f0    	mov    0xf0171f90,%edx
f0102a93:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a99:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a9c:	89 c1                	mov    %eax,%ecx
f0102a9e:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
        envs[i].env_link = env_free_list;
f0102aa5:	89 50 44             	mov    %edx,0x44(%eax)
f0102aa8:	83 e8 60             	sub    $0x60,%eax
        env_free_list = &envs[i];
f0102aab:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
int i = NENV;
    while (i>0) {
f0102aad:	39 d8                	cmp    %ebx,%eax
f0102aaf:	75 eb                	jne    f0102a9c <env_init+0x1a>
f0102ab1:	89 35 90 1f 17 f0    	mov    %esi,0xf0171f90
        envs[i].env_link = env_free_list;
        env_free_list = &envs[i];
    }

	// Per-CPU part of the initialization
	env_init_percpu();
f0102ab7:	e8 96 ff ff ff       	call   f0102a52 <env_init_percpu>
}
f0102abc:	5b                   	pop    %ebx
f0102abd:	5e                   	pop    %esi
f0102abe:	5d                   	pop    %ebp
f0102abf:	c3                   	ret    

f0102ac0 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102ac0:	55                   	push   %ebp
f0102ac1:	89 e5                	mov    %esp,%ebp
f0102ac3:	56                   	push   %esi
f0102ac4:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102ac5:	8b 1d 90 1f 17 f0    	mov    0xf0171f90,%ebx
f0102acb:	85 db                	test   %ebx,%ebx
f0102acd:	0f 84 45 01 00 00    	je     f0102c18 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ad3:	83 ec 0c             	sub    $0xc,%esp
f0102ad6:	6a 01                	push   $0x1
f0102ad8:	e8 f2 e2 ff ff       	call   f0100dcf <page_alloc>
f0102add:	89 c6                	mov    %eax,%esi
f0102adf:	83 c4 10             	add    $0x10,%esp
f0102ae2:	85 c0                	test   %eax,%eax
f0102ae4:	0f 84 35 01 00 00    	je     f0102c1f <env_alloc+0x15f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aea:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102af0:	c1 f8 03             	sar    $0x3,%eax
f0102af3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af6:	89 c2                	mov    %eax,%edx
f0102af8:	c1 ea 0c             	shr    $0xc,%edx
f0102afb:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102b01:	72 12                	jb     f0102b15 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b03:	50                   	push   %eax
f0102b04:	68 e4 4d 10 f0       	push   $0xf0104de4
f0102b09:	6a 56                	push   $0x56
f0102b0b:	68 2d 56 10 f0       	push   $0xf010562d
f0102b10:	e8 8b d5 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102b15:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
e->env_pgdir = page2kva(p);
f0102b1a:	89 43 5c             	mov    %eax,0x5c(%ebx)
    memcpy(e->env_pgdir, kern_pgdir, PGSIZE); // use kern_pgdir as template 
f0102b1d:	83 ec 04             	sub    $0x4,%esp
f0102b20:	68 00 10 00 00       	push   $0x1000
f0102b25:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102b2b:	50                   	push   %eax
f0102b2c:	e8 97 19 00 00       	call   f01044c8 <memcpy>
    p->pp_ref++;
f0102b31:	66 83 46 04 01       	addw   $0x1,0x4(%esi)

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102b36:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b39:	83 c4 10             	add    $0x10,%esp
f0102b3c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b41:	77 15                	ja     f0102b58 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b43:	50                   	push   %eax
f0102b44:	68 18 4f 10 f0       	push   $0xf0104f18
f0102b49:	68 c3 00 00 00       	push   $0xc3
f0102b4e:	68 34 59 10 f0       	push   $0xf0105934
f0102b53:	e8 48 d5 ff ff       	call   f01000a0 <_panic>
f0102b58:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102b5e:	83 ca 05             	or     $0x5,%edx
f0102b61:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102b67:	8b 43 48             	mov    0x48(%ebx),%eax
f0102b6a:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102b6f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102b74:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102b79:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102b7c:	89 da                	mov    %ebx,%edx
f0102b7e:	2b 15 8c 1f 17 f0    	sub    0xf0171f8c,%edx
f0102b84:	c1 fa 05             	sar    $0x5,%edx
f0102b87:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102b8d:	09 d0                	or     %edx,%eax
f0102b8f:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b92:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b95:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b98:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b9f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102ba6:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102bad:	83 ec 04             	sub    $0x4,%esp
f0102bb0:	6a 44                	push   $0x44
f0102bb2:	6a 00                	push   $0x0
f0102bb4:	53                   	push   %ebx
f0102bb5:	e8 59 18 00 00       	call   f0104413 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102bba:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102bc0:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102bc6:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102bcc:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102bd3:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102bd9:	8b 43 44             	mov    0x44(%ebx),%eax
f0102bdc:	a3 90 1f 17 f0       	mov    %eax,0xf0171f90
	*newenv_store = e;
f0102be1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102be4:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102be6:	8b 53 48             	mov    0x48(%ebx),%edx
f0102be9:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f0102bee:	83 c4 10             	add    $0x10,%esp
f0102bf1:	85 c0                	test   %eax,%eax
f0102bf3:	74 05                	je     f0102bfa <env_alloc+0x13a>
f0102bf5:	8b 40 48             	mov    0x48(%eax),%eax
f0102bf8:	eb 05                	jmp    f0102bff <env_alloc+0x13f>
f0102bfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bff:	83 ec 04             	sub    $0x4,%esp
f0102c02:	52                   	push   %edx
f0102c03:	50                   	push   %eax
f0102c04:	68 54 59 10 f0       	push   $0xf0105954
f0102c09:	e8 3b 04 00 00       	call   f0103049 <cprintf>
	return 0;
f0102c0e:	83 c4 10             	add    $0x10,%esp
f0102c11:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c16:	eb 0c                	jmp    f0102c24 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102c18:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102c1d:	eb 05                	jmp    f0102c24 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102c1f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102c24:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102c27:	5b                   	pop    %ebx
f0102c28:	5e                   	pop    %esi
f0102c29:	5d                   	pop    %ebp
f0102c2a:	c3                   	ret    

f0102c2b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102c2b:	55                   	push   %ebp
f0102c2c:	89 e5                	mov    %esp,%ebp
f0102c2e:	57                   	push   %edi
f0102c2f:	56                   	push   %esi
f0102c30:	53                   	push   %ebx
f0102c31:	83 ec 34             	sub    $0x34,%esp
f0102c34:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
    struct Env *e;
    int r = env_alloc(&e, 0);
f0102c37:	6a 00                	push   $0x0
f0102c39:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102c3c:	50                   	push   %eax
f0102c3d:	e8 7e fe ff ff       	call   f0102ac0 <env_alloc>
    if (r<0) {
f0102c42:	83 c4 10             	add    $0x10,%esp
f0102c45:	85 c0                	test   %eax,%eax
f0102c47:	79 15                	jns    f0102c5e <env_create+0x33>
        panic("env_create: %e",r);
f0102c49:	50                   	push   %eax
f0102c4a:	68 69 59 10 f0       	push   $0xf0105969
f0102c4f:	68 85 01 00 00       	push   $0x185
f0102c54:	68 34 59 10 f0       	push   $0xf0105934
f0102c59:	e8 42 d4 ff ff       	call   f01000a0 <_panic>
    }
    e->env_type = type;
f0102c5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c61:	89 c1                	mov    %eax,%ecx
f0102c63:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c69:	89 41 50             	mov    %eax,0x50(%ecx)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
    struct Proghdr *ph, *eph;
    struct Elf *elf = (struct Elf *)binary;
    if (elf->e_magic != ELF_MAGIC) {
f0102c6c:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102c72:	74 17                	je     f0102c8b <env_create+0x60>
        panic("load_icode: not an ELF file");
f0102c74:	83 ec 04             	sub    $0x4,%esp
f0102c77:	68 78 59 10 f0       	push   $0xf0105978
f0102c7c:	68 5f 01 00 00       	push   $0x15f
f0102c81:	68 34 59 10 f0       	push   $0xf0105934
f0102c86:	e8 15 d4 ff ff       	call   f01000a0 <_panic>
    }
    ph = (struct Proghdr *)(binary + elf->e_phoff);
f0102c8b:	89 fb                	mov    %edi,%ebx
f0102c8d:	03 5f 1c             	add    0x1c(%edi),%ebx
    eph = ph + elf->e_phnum;
f0102c90:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c94:	c1 e6 05             	shl    $0x5,%esi
f0102c97:	01 de                	add    %ebx,%esi
    lcr3(PADDR(e->env_pgdir));
f0102c99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c9c:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c9f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ca4:	77 15                	ja     f0102cbb <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ca6:	50                   	push   %eax
f0102ca7:	68 18 4f 10 f0       	push   $0xf0104f18
f0102cac:	68 63 01 00 00       	push   $0x163
f0102cb1:	68 34 59 10 f0       	push   $0xf0105934
f0102cb6:	e8 e5 d3 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102cbb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cc0:	0f 22 d8             	mov    %eax,%cr3
f0102cc3:	eb 60                	jmp    f0102d25 <env_create+0xfa>
    for (; ph<eph; ph++) {
        if (ph->p_type == ELF_PROG_LOAD) {
f0102cc5:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102cc8:	75 58                	jne    f0102d22 <env_create+0xf7>
            if (ph->p_filesz > ph->p_memsz) {
f0102cca:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102ccd:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0102cd0:	76 17                	jbe    f0102ce9 <env_create+0xbe>
                panic("load_icode: file size is greater than memory size");
f0102cd2:	83 ec 04             	sub    $0x4,%esp
f0102cd5:	68 b8 59 10 f0       	push   $0xf01059b8
f0102cda:	68 67 01 00 00       	push   $0x167
f0102cdf:	68 34 59 10 f0       	push   $0xf0105934
f0102ce4:	e8 b7 d3 ff ff       	call   f01000a0 <_panic>
            }
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102ce9:	8b 53 08             	mov    0x8(%ebx),%edx
f0102cec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cef:	e8 63 fc ff ff       	call   f0102957 <region_alloc>
            memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102cf4:	83 ec 04             	sub    $0x4,%esp
f0102cf7:	ff 73 10             	pushl  0x10(%ebx)
f0102cfa:	89 f8                	mov    %edi,%eax
f0102cfc:	03 43 04             	add    0x4(%ebx),%eax
f0102cff:	50                   	push   %eax
f0102d00:	ff 73 08             	pushl  0x8(%ebx)
f0102d03:	e8 c0 17 00 00       	call   f01044c8 <memcpy>
            memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0102d08:	8b 43 10             	mov    0x10(%ebx),%eax
f0102d0b:	83 c4 0c             	add    $0xc,%esp
f0102d0e:	8b 53 14             	mov    0x14(%ebx),%edx
f0102d11:	29 c2                	sub    %eax,%edx
f0102d13:	52                   	push   %edx
f0102d14:	6a 00                	push   $0x0
f0102d16:	03 43 08             	add    0x8(%ebx),%eax
f0102d19:	50                   	push   %eax
f0102d1a:	e8 f4 16 00 00       	call   f0104413 <memset>
f0102d1f:	83 c4 10             	add    $0x10,%esp
        panic("load_icode: not an ELF file");
    }
    ph = (struct Proghdr *)(binary + elf->e_phoff);
    eph = ph + elf->e_phnum;
    lcr3(PADDR(e->env_pgdir));
    for (; ph<eph; ph++) {
f0102d22:	83 c3 20             	add    $0x20,%ebx
f0102d25:	39 de                	cmp    %ebx,%esi
f0102d27:	77 9c                	ja     f0102cc5 <env_create+0x9a>
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
            memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
            memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
        }
    }
    e->env_tf.tf_eip = elf->e_entry;
f0102d29:	8b 47 18             	mov    0x18(%edi),%eax
f0102d2c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d2f:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
    region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f0102d32:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102d37:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102d3c:	89 f8                	mov    %edi,%eax
f0102d3e:	e8 14 fc ff ff       	call   f0102957 <region_alloc>
    lcr3(PADDR(kern_pgdir));
f0102d43:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d48:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d4d:	77 15                	ja     f0102d64 <env_create+0x139>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d4f:	50                   	push   %eax
f0102d50:	68 18 4f 10 f0       	push   $0xf0104f18
f0102d55:	68 74 01 00 00       	push   $0x174
f0102d5a:	68 34 59 10 f0       	push   $0xf0105934
f0102d5f:	e8 3c d3 ff ff       	call   f01000a0 <_panic>
f0102d64:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d69:	0f 22 d8             	mov    %eax,%cr3
    if (r<0) {
        panic("env_create: %e",r);
    }
    e->env_type = type;
    load_icode(e, binary);
}
f0102d6c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d6f:	5b                   	pop    %ebx
f0102d70:	5e                   	pop    %esi
f0102d71:	5f                   	pop    %edi
f0102d72:	5d                   	pop    %ebp
f0102d73:	c3                   	ret    

f0102d74 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102d74:	55                   	push   %ebp
f0102d75:	89 e5                	mov    %esp,%ebp
f0102d77:	57                   	push   %edi
f0102d78:	56                   	push   %esi
f0102d79:	53                   	push   %ebx
f0102d7a:	83 ec 1c             	sub    $0x1c,%esp
f0102d7d:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d80:	8b 15 88 1f 17 f0    	mov    0xf0171f88,%edx
f0102d86:	39 fa                	cmp    %edi,%edx
f0102d88:	75 29                	jne    f0102db3 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102d8a:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d8f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d94:	77 15                	ja     f0102dab <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d96:	50                   	push   %eax
f0102d97:	68 18 4f 10 f0       	push   $0xf0104f18
f0102d9c:	68 99 01 00 00       	push   $0x199
f0102da1:	68 34 59 10 f0       	push   $0xf0105934
f0102da6:	e8 f5 d2 ff ff       	call   f01000a0 <_panic>
f0102dab:	05 00 00 00 10       	add    $0x10000000,%eax
f0102db0:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102db3:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102db6:	85 d2                	test   %edx,%edx
f0102db8:	74 05                	je     f0102dbf <env_free+0x4b>
f0102dba:	8b 42 48             	mov    0x48(%edx),%eax
f0102dbd:	eb 05                	jmp    f0102dc4 <env_free+0x50>
f0102dbf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dc4:	83 ec 04             	sub    $0x4,%esp
f0102dc7:	51                   	push   %ecx
f0102dc8:	50                   	push   %eax
f0102dc9:	68 94 59 10 f0       	push   $0xf0105994
f0102dce:	e8 76 02 00 00       	call   f0103049 <cprintf>
f0102dd3:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102dd6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102ddd:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102de0:	89 d0                	mov    %edx,%eax
f0102de2:	c1 e0 02             	shl    $0x2,%eax
f0102de5:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102de8:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102deb:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102dee:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102df4:	0f 84 a8 00 00 00    	je     f0102ea2 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102dfa:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e00:	89 f0                	mov    %esi,%eax
f0102e02:	c1 e8 0c             	shr    $0xc,%eax
f0102e05:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e08:	39 05 44 2c 17 f0    	cmp    %eax,0xf0172c44
f0102e0e:	77 15                	ja     f0102e25 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e10:	56                   	push   %esi
f0102e11:	68 e4 4d 10 f0       	push   $0xf0104de4
f0102e16:	68 a8 01 00 00       	push   $0x1a8
f0102e1b:	68 34 59 10 f0       	push   $0xf0105934
f0102e20:	e8 7b d2 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102e25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e28:	c1 e0 16             	shl    $0x16,%eax
f0102e2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102e2e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102e33:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102e3a:	01 
f0102e3b:	74 17                	je     f0102e54 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102e3d:	83 ec 08             	sub    $0x8,%esp
f0102e40:	89 d8                	mov    %ebx,%eax
f0102e42:	c1 e0 0c             	shl    $0xc,%eax
f0102e45:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102e48:	50                   	push   %eax
f0102e49:	ff 77 5c             	pushl  0x5c(%edi)
f0102e4c:	e8 26 e2 ff ff       	call   f0101077 <page_remove>
f0102e51:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102e54:	83 c3 01             	add    $0x1,%ebx
f0102e57:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102e5d:	75 d4                	jne    f0102e33 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102e5f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e62:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e65:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e6c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e6f:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102e75:	72 14                	jb     f0102e8b <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102e77:	83 ec 04             	sub    $0x4,%esp
f0102e7a:	68 70 4f 10 f0       	push   $0xf0104f70
f0102e7f:	6a 4f                	push   $0x4f
f0102e81:	68 2d 56 10 f0       	push   $0xf010562d
f0102e86:	e8 15 d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102e8b:	83 ec 0c             	sub    $0xc,%esp
f0102e8e:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0102e93:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e96:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102e99:	50                   	push   %eax
f0102e9a:	e8 d7 df ff ff       	call   f0100e76 <page_decref>
f0102e9f:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ea2:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102ea6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ea9:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102eae:	0f 85 29 ff ff ff    	jne    f0102ddd <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102eb4:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eb7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ebc:	77 15                	ja     f0102ed3 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ebe:	50                   	push   %eax
f0102ebf:	68 18 4f 10 f0       	push   $0xf0104f18
f0102ec4:	68 b6 01 00 00       	push   $0x1b6
f0102ec9:	68 34 59 10 f0       	push   $0xf0105934
f0102ece:	e8 cd d1 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102ed3:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102eda:	05 00 00 00 10       	add    $0x10000000,%eax
f0102edf:	c1 e8 0c             	shr    $0xc,%eax
f0102ee2:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102ee8:	72 14                	jb     f0102efe <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102eea:	83 ec 04             	sub    $0x4,%esp
f0102eed:	68 70 4f 10 f0       	push   $0xf0104f70
f0102ef2:	6a 4f                	push   $0x4f
f0102ef4:	68 2d 56 10 f0       	push   $0xf010562d
f0102ef9:	e8 a2 d1 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102efe:	83 ec 0c             	sub    $0xc,%esp
f0102f01:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0102f07:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102f0a:	50                   	push   %eax
f0102f0b:	e8 66 df ff ff       	call   f0100e76 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102f10:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102f17:	a1 90 1f 17 f0       	mov    0xf0171f90,%eax
f0102f1c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102f1f:	89 3d 90 1f 17 f0    	mov    %edi,0xf0171f90
}
f0102f25:	83 c4 10             	add    $0x10,%esp
f0102f28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f2b:	5b                   	pop    %ebx
f0102f2c:	5e                   	pop    %esi
f0102f2d:	5f                   	pop    %edi
f0102f2e:	5d                   	pop    %ebp
f0102f2f:	c3                   	ret    

f0102f30 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102f30:	55                   	push   %ebp
f0102f31:	89 e5                	mov    %esp,%ebp
f0102f33:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102f36:	ff 75 08             	pushl  0x8(%ebp)
f0102f39:	e8 36 fe ff ff       	call   f0102d74 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102f3e:	c7 04 24 ec 59 10 f0 	movl   $0xf01059ec,(%esp)
f0102f45:	e8 ff 00 00 00       	call   f0103049 <cprintf>
f0102f4a:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102f4d:	83 ec 0c             	sub    $0xc,%esp
f0102f50:	6a 00                	push   $0x0
f0102f52:	e8 87 d8 ff ff       	call   f01007de <monitor>
f0102f57:	83 c4 10             	add    $0x10,%esp
f0102f5a:	eb f1                	jmp    f0102f4d <env_destroy+0x1d>

f0102f5c <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102f5c:	55                   	push   %ebp
f0102f5d:	89 e5                	mov    %esp,%ebp
f0102f5f:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102f62:	8b 65 08             	mov    0x8(%ebp),%esp
f0102f65:	61                   	popa   
f0102f66:	07                   	pop    %es
f0102f67:	1f                   	pop    %ds
f0102f68:	83 c4 08             	add    $0x8,%esp
f0102f6b:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102f6c:	68 aa 59 10 f0       	push   $0xf01059aa
f0102f71:	68 df 01 00 00       	push   $0x1df
f0102f76:	68 34 59 10 f0       	push   $0xf0105934
f0102f7b:	e8 20 d1 ff ff       	call   f01000a0 <_panic>

f0102f80 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102f80:	55                   	push   %ebp
f0102f81:	89 e5                	mov    %esp,%ebp
f0102f83:	83 ec 08             	sub    $0x8,%esp
f0102f86:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	if (curenv && curenv->env_status == ENV_RUNNING) {
f0102f89:	8b 15 88 1f 17 f0    	mov    0xf0171f88,%edx
f0102f8f:	85 d2                	test   %edx,%edx
f0102f91:	74 0d                	je     f0102fa0 <env_run+0x20>
f0102f93:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102f97:	75 07                	jne    f0102fa0 <env_run+0x20>
        curenv->env_status = ENV_RUNNABLE;
f0102f99:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
    }
    curenv = e;
f0102fa0:	a3 88 1f 17 f0       	mov    %eax,0xf0171f88
    e->env_status = ENV_RUNNING;
f0102fa5:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
    e->env_runs++;
f0102fac:	83 40 58 01          	addl   $0x1,0x58(%eax)
    lcr3(PADDR(e->env_pgdir));
f0102fb0:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fb3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102fb9:	77 15                	ja     f0102fd0 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fbb:	52                   	push   %edx
f0102fbc:	68 18 4f 10 f0       	push   $0xf0104f18
f0102fc1:	68 04 02 00 00       	push   $0x204
f0102fc6:	68 34 59 10 f0       	push   $0xf0105934
f0102fcb:	e8 d0 d0 ff ff       	call   f01000a0 <_panic>
f0102fd0:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102fd6:	0f 22 da             	mov    %edx,%cr3
    
    env_pop_tf(&e->env_tf);
f0102fd9:	83 ec 0c             	sub    $0xc,%esp
f0102fdc:	50                   	push   %eax
f0102fdd:	e8 7a ff ff ff       	call   f0102f5c <env_pop_tf>

f0102fe2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102fe2:	55                   	push   %ebp
f0102fe3:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fe5:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fea:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fed:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102fee:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ff3:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ff4:	0f b6 c0             	movzbl %al,%eax
}
f0102ff7:	5d                   	pop    %ebp
f0102ff8:	c3                   	ret    

f0102ff9 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ff9:	55                   	push   %ebp
f0102ffa:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ffc:	ba 70 00 00 00       	mov    $0x70,%edx
f0103001:	8b 45 08             	mov    0x8(%ebp),%eax
f0103004:	ee                   	out    %al,(%dx)
f0103005:	ba 71 00 00 00       	mov    $0x71,%edx
f010300a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010300d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010300e:	5d                   	pop    %ebp
f010300f:	c3                   	ret    

f0103010 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103010:	55                   	push   %ebp
f0103011:	89 e5                	mov    %esp,%ebp
f0103013:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103016:	ff 75 08             	pushl  0x8(%ebp)
f0103019:	e8 f7 d5 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f010301e:	83 c4 10             	add    $0x10,%esp
f0103021:	c9                   	leave  
f0103022:	c3                   	ret    

f0103023 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103023:	55                   	push   %ebp
f0103024:	89 e5                	mov    %esp,%ebp
f0103026:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103029:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103030:	ff 75 0c             	pushl  0xc(%ebp)
f0103033:	ff 75 08             	pushl  0x8(%ebp)
f0103036:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103039:	50                   	push   %eax
f010303a:	68 10 30 10 f0       	push   $0xf0103010
f010303f:	e8 63 0d 00 00       	call   f0103da7 <vprintfmt>
	return cnt;
}
f0103044:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103047:	c9                   	leave  
f0103048:	c3                   	ret    

f0103049 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103049:	55                   	push   %ebp
f010304a:	89 e5                	mov    %esp,%ebp
f010304c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010304f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103052:	50                   	push   %eax
f0103053:	ff 75 08             	pushl  0x8(%ebp)
f0103056:	e8 c8 ff ff ff       	call   f0103023 <vcprintf>
	va_end(ap);

	return cnt;
}
f010305b:	c9                   	leave  
f010305c:	c3                   	ret    

f010305d <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010305d:	55                   	push   %ebp
f010305e:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103060:	b8 c0 27 17 f0       	mov    $0xf01727c0,%eax
f0103065:	c7 05 c4 27 17 f0 00 	movl   $0xf0000000,0xf01727c4
f010306c:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010306f:	66 c7 05 c8 27 17 f0 	movw   $0x10,0xf01727c8
f0103076:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103078:	66 c7 05 26 28 17 f0 	movw   $0x68,0xf0172826
f010307f:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103081:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0103088:	67 00 
f010308a:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103090:	89 c2                	mov    %eax,%edx
f0103092:	c1 ea 10             	shr    $0x10,%edx
f0103095:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010309b:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f01030a2:	c1 e8 18             	shr    $0x18,%eax
f01030a5:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01030aa:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f01030b1:	b8 28 00 00 00       	mov    $0x28,%eax
f01030b6:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f01030b9:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f01030be:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01030c1:	5d                   	pop    %ebp
f01030c2:	c3                   	ret    

f01030c3 <trap_init>:
}


void
trap_init(void)
{
f01030c3:	55                   	push   %ebp
f01030c4:	89 e5                	mov    %esp,%ebp
    void handler18();
    void handler19();
    void handler48();

    // inc/mmu.h
    SETGATE(idt[T_DIVIDE], 1, GD_KT, handler0, 0);
f01030c6:	b8 7c 37 10 f0       	mov    $0xf010377c,%eax
f01030cb:	66 a3 a0 1f 17 f0    	mov    %ax,0xf0171fa0
f01030d1:	66 c7 05 a2 1f 17 f0 	movw   $0x8,0xf0171fa2
f01030d8:	08 00 
f01030da:	c6 05 a4 1f 17 f0 00 	movb   $0x0,0xf0171fa4
f01030e1:	c6 05 a5 1f 17 f0 8f 	movb   $0x8f,0xf0171fa5
f01030e8:	c1 e8 10             	shr    $0x10,%eax
f01030eb:	66 a3 a6 1f 17 f0    	mov    %ax,0xf0171fa6
    SETGATE(idt[T_DEBUG], 1, GD_KT, handler1, 0);
f01030f1:	b8 82 37 10 f0       	mov    $0xf0103782,%eax
f01030f6:	66 a3 a8 1f 17 f0    	mov    %ax,0xf0171fa8
f01030fc:	66 c7 05 aa 1f 17 f0 	movw   $0x8,0xf0171faa
f0103103:	08 00 
f0103105:	c6 05 ac 1f 17 f0 00 	movb   $0x0,0xf0171fac
f010310c:	c6 05 ad 1f 17 f0 8f 	movb   $0x8f,0xf0171fad
f0103113:	c1 e8 10             	shr    $0x10,%eax
f0103116:	66 a3 ae 1f 17 f0    	mov    %ax,0xf0171fae
    SETGATE(idt[T_NMI], 1, GD_KT, handler2, 0);
f010311c:	b8 88 37 10 f0       	mov    $0xf0103788,%eax
f0103121:	66 a3 b0 1f 17 f0    	mov    %ax,0xf0171fb0
f0103127:	66 c7 05 b2 1f 17 f0 	movw   $0x8,0xf0171fb2
f010312e:	08 00 
f0103130:	c6 05 b4 1f 17 f0 00 	movb   $0x0,0xf0171fb4
f0103137:	c6 05 b5 1f 17 f0 8f 	movb   $0x8f,0xf0171fb5
f010313e:	c1 e8 10             	shr    $0x10,%eax
f0103141:	66 a3 b6 1f 17 f0    	mov    %ax,0xf0171fb6
    SETGATE(idt[T_BRKPT], 1, GD_KT, handler3, 3);
f0103147:	b8 8e 37 10 f0       	mov    $0xf010378e,%eax
f010314c:	66 a3 b8 1f 17 f0    	mov    %ax,0xf0171fb8
f0103152:	66 c7 05 ba 1f 17 f0 	movw   $0x8,0xf0171fba
f0103159:	08 00 
f010315b:	c6 05 bc 1f 17 f0 00 	movb   $0x0,0xf0171fbc
f0103162:	c6 05 bd 1f 17 f0 ef 	movb   $0xef,0xf0171fbd
f0103169:	c1 e8 10             	shr    $0x10,%eax
f010316c:	66 a3 be 1f 17 f0    	mov    %ax,0xf0171fbe
    SETGATE(idt[T_OFLOW], 1, GD_KT, handler4, 0);
f0103172:	b8 94 37 10 f0       	mov    $0xf0103794,%eax
f0103177:	66 a3 c0 1f 17 f0    	mov    %ax,0xf0171fc0
f010317d:	66 c7 05 c2 1f 17 f0 	movw   $0x8,0xf0171fc2
f0103184:	08 00 
f0103186:	c6 05 c4 1f 17 f0 00 	movb   $0x0,0xf0171fc4
f010318d:	c6 05 c5 1f 17 f0 8f 	movb   $0x8f,0xf0171fc5
f0103194:	c1 e8 10             	shr    $0x10,%eax
f0103197:	66 a3 c6 1f 17 f0    	mov    %ax,0xf0171fc6
    SETGATE(idt[T_BOUND], 1, GD_KT, handler5, 0);
f010319d:	b8 9a 37 10 f0       	mov    $0xf010379a,%eax
f01031a2:	66 a3 c8 1f 17 f0    	mov    %ax,0xf0171fc8
f01031a8:	66 c7 05 ca 1f 17 f0 	movw   $0x8,0xf0171fca
f01031af:	08 00 
f01031b1:	c6 05 cc 1f 17 f0 00 	movb   $0x0,0xf0171fcc
f01031b8:	c6 05 cd 1f 17 f0 8f 	movb   $0x8f,0xf0171fcd
f01031bf:	c1 e8 10             	shr    $0x10,%eax
f01031c2:	66 a3 ce 1f 17 f0    	mov    %ax,0xf0171fce
    SETGATE(idt[T_ILLOP], 1, GD_KT, handler6, 0);
f01031c8:	b8 a0 37 10 f0       	mov    $0xf01037a0,%eax
f01031cd:	66 a3 d0 1f 17 f0    	mov    %ax,0xf0171fd0
f01031d3:	66 c7 05 d2 1f 17 f0 	movw   $0x8,0xf0171fd2
f01031da:	08 00 
f01031dc:	c6 05 d4 1f 17 f0 00 	movb   $0x0,0xf0171fd4
f01031e3:	c6 05 d5 1f 17 f0 8f 	movb   $0x8f,0xf0171fd5
f01031ea:	c1 e8 10             	shr    $0x10,%eax
f01031ed:	66 a3 d6 1f 17 f0    	mov    %ax,0xf0171fd6
    SETGATE(idt[T_DEVICE], 1, GD_KT, handler7, 0);
f01031f3:	b8 a6 37 10 f0       	mov    $0xf01037a6,%eax
f01031f8:	66 a3 d8 1f 17 f0    	mov    %ax,0xf0171fd8
f01031fe:	66 c7 05 da 1f 17 f0 	movw   $0x8,0xf0171fda
f0103205:	08 00 
f0103207:	c6 05 dc 1f 17 f0 00 	movb   $0x0,0xf0171fdc
f010320e:	c6 05 dd 1f 17 f0 8f 	movb   $0x8f,0xf0171fdd
f0103215:	c1 e8 10             	shr    $0x10,%eax
f0103218:	66 a3 de 1f 17 f0    	mov    %ax,0xf0171fde
    SETGATE(idt[T_DBLFLT], 1, GD_KT, handler8, 0);
f010321e:	b8 ac 37 10 f0       	mov    $0xf01037ac,%eax
f0103223:	66 a3 e0 1f 17 f0    	mov    %ax,0xf0171fe0
f0103229:	66 c7 05 e2 1f 17 f0 	movw   $0x8,0xf0171fe2
f0103230:	08 00 
f0103232:	c6 05 e4 1f 17 f0 00 	movb   $0x0,0xf0171fe4
f0103239:	c6 05 e5 1f 17 f0 8f 	movb   $0x8f,0xf0171fe5
f0103240:	c1 e8 10             	shr    $0x10,%eax
f0103243:	66 a3 e6 1f 17 f0    	mov    %ax,0xf0171fe6

    SETGATE(idt[T_TSS], 1, GD_KT, handler10, 0);
f0103249:	b8 b0 37 10 f0       	mov    $0xf01037b0,%eax
f010324e:	66 a3 f0 1f 17 f0    	mov    %ax,0xf0171ff0
f0103254:	66 c7 05 f2 1f 17 f0 	movw   $0x8,0xf0171ff2
f010325b:	08 00 
f010325d:	c6 05 f4 1f 17 f0 00 	movb   $0x0,0xf0171ff4
f0103264:	c6 05 f5 1f 17 f0 8f 	movb   $0x8f,0xf0171ff5
f010326b:	c1 e8 10             	shr    $0x10,%eax
f010326e:	66 a3 f6 1f 17 f0    	mov    %ax,0xf0171ff6
    SETGATE(idt[T_SEGNP], 1, GD_KT, handler11, 0);
f0103274:	b8 b4 37 10 f0       	mov    $0xf01037b4,%eax
f0103279:	66 a3 f8 1f 17 f0    	mov    %ax,0xf0171ff8
f010327f:	66 c7 05 fa 1f 17 f0 	movw   $0x8,0xf0171ffa
f0103286:	08 00 
f0103288:	c6 05 fc 1f 17 f0 00 	movb   $0x0,0xf0171ffc
f010328f:	c6 05 fd 1f 17 f0 8f 	movb   $0x8f,0xf0171ffd
f0103296:	c1 e8 10             	shr    $0x10,%eax
f0103299:	66 a3 fe 1f 17 f0    	mov    %ax,0xf0171ffe
    SETGATE(idt[T_STACK], 1, GD_KT, handler12, 0);
f010329f:	b8 b8 37 10 f0       	mov    $0xf01037b8,%eax
f01032a4:	66 a3 00 20 17 f0    	mov    %ax,0xf0172000
f01032aa:	66 c7 05 02 20 17 f0 	movw   $0x8,0xf0172002
f01032b1:	08 00 
f01032b3:	c6 05 04 20 17 f0 00 	movb   $0x0,0xf0172004
f01032ba:	c6 05 05 20 17 f0 8f 	movb   $0x8f,0xf0172005
f01032c1:	c1 e8 10             	shr    $0x10,%eax
f01032c4:	66 a3 06 20 17 f0    	mov    %ax,0xf0172006
    SETGATE(idt[T_GPFLT], 1, GD_KT, handler13, 0);
f01032ca:	b8 bc 37 10 f0       	mov    $0xf01037bc,%eax
f01032cf:	66 a3 08 20 17 f0    	mov    %ax,0xf0172008
f01032d5:	66 c7 05 0a 20 17 f0 	movw   $0x8,0xf017200a
f01032dc:	08 00 
f01032de:	c6 05 0c 20 17 f0 00 	movb   $0x0,0xf017200c
f01032e5:	c6 05 0d 20 17 f0 8f 	movb   $0x8f,0xf017200d
f01032ec:	c1 e8 10             	shr    $0x10,%eax
f01032ef:	66 a3 0e 20 17 f0    	mov    %ax,0xf017200e
    SETGATE(idt[T_PGFLT], 1, GD_KT, handler14, 0);
f01032f5:	b8 c0 37 10 f0       	mov    $0xf01037c0,%eax
f01032fa:	66 a3 10 20 17 f0    	mov    %ax,0xf0172010
f0103300:	66 c7 05 12 20 17 f0 	movw   $0x8,0xf0172012
f0103307:	08 00 
f0103309:	c6 05 14 20 17 f0 00 	movb   $0x0,0xf0172014
f0103310:	c6 05 15 20 17 f0 8f 	movb   $0x8f,0xf0172015
f0103317:	c1 e8 10             	shr    $0x10,%eax
f010331a:	66 a3 16 20 17 f0    	mov    %ax,0xf0172016
    
    SETGATE(idt[T_FPERR], 1, GD_KT, handler16, 0);
f0103320:	b8 c4 37 10 f0       	mov    $0xf01037c4,%eax
f0103325:	66 a3 20 20 17 f0    	mov    %ax,0xf0172020
f010332b:	66 c7 05 22 20 17 f0 	movw   $0x8,0xf0172022
f0103332:	08 00 
f0103334:	c6 05 24 20 17 f0 00 	movb   $0x0,0xf0172024
f010333b:	c6 05 25 20 17 f0 8f 	movb   $0x8f,0xf0172025
f0103342:	c1 e8 10             	shr    $0x10,%eax
f0103345:	66 a3 26 20 17 f0    	mov    %ax,0xf0172026
    SETGATE(idt[T_ALIGN], 1, GD_KT, handler17, 0);
f010334b:	b8 ca 37 10 f0       	mov    $0xf01037ca,%eax
f0103350:	66 a3 28 20 17 f0    	mov    %ax,0xf0172028
f0103356:	66 c7 05 2a 20 17 f0 	movw   $0x8,0xf017202a
f010335d:	08 00 
f010335f:	c6 05 2c 20 17 f0 00 	movb   $0x0,0xf017202c
f0103366:	c6 05 2d 20 17 f0 8f 	movb   $0x8f,0xf017202d
f010336d:	c1 e8 10             	shr    $0x10,%eax
f0103370:	66 a3 2e 20 17 f0    	mov    %ax,0xf017202e
    SETGATE(idt[T_MCHK], 1, GD_KT, handler18, 0);
f0103376:	b8 ce 37 10 f0       	mov    $0xf01037ce,%eax
f010337b:	66 a3 30 20 17 f0    	mov    %ax,0xf0172030
f0103381:	66 c7 05 32 20 17 f0 	movw   $0x8,0xf0172032
f0103388:	08 00 
f010338a:	c6 05 34 20 17 f0 00 	movb   $0x0,0xf0172034
f0103391:	c6 05 35 20 17 f0 8f 	movb   $0x8f,0xf0172035
f0103398:	c1 e8 10             	shr    $0x10,%eax
f010339b:	66 a3 36 20 17 f0    	mov    %ax,0xf0172036
    SETGATE(idt[T_SIMDERR], 1, GD_KT, handler19, 0);
f01033a1:	b8 d4 37 10 f0       	mov    $0xf01037d4,%eax
f01033a6:	66 a3 38 20 17 f0    	mov    %ax,0xf0172038
f01033ac:	66 c7 05 3a 20 17 f0 	movw   $0x8,0xf017203a
f01033b3:	08 00 
f01033b5:	c6 05 3c 20 17 f0 00 	movb   $0x0,0xf017203c
f01033bc:	c6 05 3d 20 17 f0 8f 	movb   $0x8f,0xf017203d
f01033c3:	c1 e8 10             	shr    $0x10,%eax
f01033c6:	66 a3 3e 20 17 f0    	mov    %ax,0xf017203e

    // interrupt
    SETGATE(idt[T_SYSCALL], 0, GD_KT, handler48, 3);
f01033cc:	b8 da 37 10 f0       	mov    $0xf01037da,%eax
f01033d1:	66 a3 20 21 17 f0    	mov    %ax,0xf0172120
f01033d7:	66 c7 05 22 21 17 f0 	movw   $0x8,0xf0172122
f01033de:	08 00 
f01033e0:	c6 05 24 21 17 f0 00 	movb   $0x0,0xf0172124
f01033e7:	c6 05 25 21 17 f0 ee 	movb   $0xee,0xf0172125
f01033ee:	c1 e8 10             	shr    $0x10,%eax
f01033f1:	66 a3 26 21 17 f0    	mov    %ax,0xf0172126

	// Per-CPU setup 
	trap_init_percpu();
f01033f7:	e8 61 fc ff ff       	call   f010305d <trap_init_percpu>
}
f01033fc:	5d                   	pop    %ebp
f01033fd:	c3                   	ret    

f01033fe <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01033fe:	55                   	push   %ebp
f01033ff:	89 e5                	mov    %esp,%ebp
f0103401:	53                   	push   %ebx
f0103402:	83 ec 0c             	sub    $0xc,%esp
f0103405:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103408:	ff 33                	pushl  (%ebx)
f010340a:	68 22 5a 10 f0       	push   $0xf0105a22
f010340f:	e8 35 fc ff ff       	call   f0103049 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103414:	83 c4 08             	add    $0x8,%esp
f0103417:	ff 73 04             	pushl  0x4(%ebx)
f010341a:	68 31 5a 10 f0       	push   $0xf0105a31
f010341f:	e8 25 fc ff ff       	call   f0103049 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103424:	83 c4 08             	add    $0x8,%esp
f0103427:	ff 73 08             	pushl  0x8(%ebx)
f010342a:	68 40 5a 10 f0       	push   $0xf0105a40
f010342f:	e8 15 fc ff ff       	call   f0103049 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103434:	83 c4 08             	add    $0x8,%esp
f0103437:	ff 73 0c             	pushl  0xc(%ebx)
f010343a:	68 4f 5a 10 f0       	push   $0xf0105a4f
f010343f:	e8 05 fc ff ff       	call   f0103049 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103444:	83 c4 08             	add    $0x8,%esp
f0103447:	ff 73 10             	pushl  0x10(%ebx)
f010344a:	68 5e 5a 10 f0       	push   $0xf0105a5e
f010344f:	e8 f5 fb ff ff       	call   f0103049 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103454:	83 c4 08             	add    $0x8,%esp
f0103457:	ff 73 14             	pushl  0x14(%ebx)
f010345a:	68 6d 5a 10 f0       	push   $0xf0105a6d
f010345f:	e8 e5 fb ff ff       	call   f0103049 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103464:	83 c4 08             	add    $0x8,%esp
f0103467:	ff 73 18             	pushl  0x18(%ebx)
f010346a:	68 7c 5a 10 f0       	push   $0xf0105a7c
f010346f:	e8 d5 fb ff ff       	call   f0103049 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103474:	83 c4 08             	add    $0x8,%esp
f0103477:	ff 73 1c             	pushl  0x1c(%ebx)
f010347a:	68 8b 5a 10 f0       	push   $0xf0105a8b
f010347f:	e8 c5 fb ff ff       	call   f0103049 <cprintf>
}
f0103484:	83 c4 10             	add    $0x10,%esp
f0103487:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010348a:	c9                   	leave  
f010348b:	c3                   	ret    

f010348c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010348c:	55                   	push   %ebp
f010348d:	89 e5                	mov    %esp,%ebp
f010348f:	56                   	push   %esi
f0103490:	53                   	push   %ebx
f0103491:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103494:	83 ec 08             	sub    $0x8,%esp
f0103497:	53                   	push   %ebx
f0103498:	68 c1 5b 10 f0       	push   $0xf0105bc1
f010349d:	e8 a7 fb ff ff       	call   f0103049 <cprintf>
	print_regs(&tf->tf_regs);
f01034a2:	89 1c 24             	mov    %ebx,(%esp)
f01034a5:	e8 54 ff ff ff       	call   f01033fe <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01034aa:	83 c4 08             	add    $0x8,%esp
f01034ad:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01034b1:	50                   	push   %eax
f01034b2:	68 dc 5a 10 f0       	push   $0xf0105adc
f01034b7:	e8 8d fb ff ff       	call   f0103049 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01034bc:	83 c4 08             	add    $0x8,%esp
f01034bf:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01034c3:	50                   	push   %eax
f01034c4:	68 ef 5a 10 f0       	push   $0xf0105aef
f01034c9:	e8 7b fb ff ff       	call   f0103049 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01034ce:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01034d1:	83 c4 10             	add    $0x10,%esp
f01034d4:	83 f8 13             	cmp    $0x13,%eax
f01034d7:	77 09                	ja     f01034e2 <print_trapframe+0x56>
		return excnames[trapno];
f01034d9:	8b 14 85 a0 5d 10 f0 	mov    -0xfefa260(,%eax,4),%edx
f01034e0:	eb 10                	jmp    f01034f2 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01034e2:	83 f8 30             	cmp    $0x30,%eax
f01034e5:	b9 a6 5a 10 f0       	mov    $0xf0105aa6,%ecx
f01034ea:	ba 9a 5a 10 f0       	mov    $0xf0105a9a,%edx
f01034ef:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01034f2:	83 ec 04             	sub    $0x4,%esp
f01034f5:	52                   	push   %edx
f01034f6:	50                   	push   %eax
f01034f7:	68 02 5b 10 f0       	push   $0xf0105b02
f01034fc:	e8 48 fb ff ff       	call   f0103049 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103501:	83 c4 10             	add    $0x10,%esp
f0103504:	3b 1d a0 27 17 f0    	cmp    0xf01727a0,%ebx
f010350a:	75 1a                	jne    f0103526 <print_trapframe+0x9a>
f010350c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103510:	75 14                	jne    f0103526 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103512:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103515:	83 ec 08             	sub    $0x8,%esp
f0103518:	50                   	push   %eax
f0103519:	68 14 5b 10 f0       	push   $0xf0105b14
f010351e:	e8 26 fb ff ff       	call   f0103049 <cprintf>
f0103523:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103526:	83 ec 08             	sub    $0x8,%esp
f0103529:	ff 73 2c             	pushl  0x2c(%ebx)
f010352c:	68 23 5b 10 f0       	push   $0xf0105b23
f0103531:	e8 13 fb ff ff       	call   f0103049 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103536:	83 c4 10             	add    $0x10,%esp
f0103539:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010353d:	75 49                	jne    f0103588 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010353f:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103542:	89 c2                	mov    %eax,%edx
f0103544:	83 e2 01             	and    $0x1,%edx
f0103547:	ba c0 5a 10 f0       	mov    $0xf0105ac0,%edx
f010354c:	b9 b5 5a 10 f0       	mov    $0xf0105ab5,%ecx
f0103551:	0f 44 ca             	cmove  %edx,%ecx
f0103554:	89 c2                	mov    %eax,%edx
f0103556:	83 e2 02             	and    $0x2,%edx
f0103559:	ba d2 5a 10 f0       	mov    $0xf0105ad2,%edx
f010355e:	be cc 5a 10 f0       	mov    $0xf0105acc,%esi
f0103563:	0f 45 d6             	cmovne %esi,%edx
f0103566:	83 e0 04             	and    $0x4,%eax
f0103569:	be ec 5b 10 f0       	mov    $0xf0105bec,%esi
f010356e:	b8 d7 5a 10 f0       	mov    $0xf0105ad7,%eax
f0103573:	0f 44 c6             	cmove  %esi,%eax
f0103576:	51                   	push   %ecx
f0103577:	52                   	push   %edx
f0103578:	50                   	push   %eax
f0103579:	68 31 5b 10 f0       	push   $0xf0105b31
f010357e:	e8 c6 fa ff ff       	call   f0103049 <cprintf>
f0103583:	83 c4 10             	add    $0x10,%esp
f0103586:	eb 10                	jmp    f0103598 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103588:	83 ec 0c             	sub    $0xc,%esp
f010358b:	68 f4 56 10 f0       	push   $0xf01056f4
f0103590:	e8 b4 fa ff ff       	call   f0103049 <cprintf>
f0103595:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103598:	83 ec 08             	sub    $0x8,%esp
f010359b:	ff 73 30             	pushl  0x30(%ebx)
f010359e:	68 40 5b 10 f0       	push   $0xf0105b40
f01035a3:	e8 a1 fa ff ff       	call   f0103049 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01035a8:	83 c4 08             	add    $0x8,%esp
f01035ab:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01035af:	50                   	push   %eax
f01035b0:	68 4f 5b 10 f0       	push   $0xf0105b4f
f01035b5:	e8 8f fa ff ff       	call   f0103049 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01035ba:	83 c4 08             	add    $0x8,%esp
f01035bd:	ff 73 38             	pushl  0x38(%ebx)
f01035c0:	68 62 5b 10 f0       	push   $0xf0105b62
f01035c5:	e8 7f fa ff ff       	call   f0103049 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01035ca:	83 c4 10             	add    $0x10,%esp
f01035cd:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01035d1:	74 25                	je     f01035f8 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01035d3:	83 ec 08             	sub    $0x8,%esp
f01035d6:	ff 73 3c             	pushl  0x3c(%ebx)
f01035d9:	68 71 5b 10 f0       	push   $0xf0105b71
f01035de:	e8 66 fa ff ff       	call   f0103049 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01035e3:	83 c4 08             	add    $0x8,%esp
f01035e6:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01035ea:	50                   	push   %eax
f01035eb:	68 80 5b 10 f0       	push   $0xf0105b80
f01035f0:	e8 54 fa ff ff       	call   f0103049 <cprintf>
f01035f5:	83 c4 10             	add    $0x10,%esp
	}
}
f01035f8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035fb:	5b                   	pop    %ebx
f01035fc:	5e                   	pop    %esi
f01035fd:	5d                   	pop    %ebp
f01035fe:	c3                   	ret    

f01035ff <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01035ff:	55                   	push   %ebp
f0103600:	89 e5                	mov    %esp,%ebp
f0103602:	53                   	push   %ebx
f0103603:	83 ec 04             	sub    $0x4,%esp
f0103606:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103609:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010360c:	ff 73 30             	pushl  0x30(%ebx)
f010360f:	50                   	push   %eax
f0103610:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f0103615:	ff 70 48             	pushl  0x48(%eax)
f0103618:	68 38 5d 10 f0       	push   $0xf0105d38
f010361d:	e8 27 fa ff ff       	call   f0103049 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103622:	89 1c 24             	mov    %ebx,(%esp)
f0103625:	e8 62 fe ff ff       	call   f010348c <print_trapframe>
	env_destroy(curenv);
f010362a:	83 c4 04             	add    $0x4,%esp
f010362d:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103633:	e8 f8 f8 ff ff       	call   f0102f30 <env_destroy>
}
f0103638:	83 c4 10             	add    $0x10,%esp
f010363b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010363e:	c9                   	leave  
f010363f:	c3                   	ret    

f0103640 <trap>:

}

void
trap(struct Trapframe *tf)
{
f0103640:	55                   	push   %ebp
f0103641:	89 e5                	mov    %esp,%ebp
f0103643:	57                   	push   %edi
f0103644:	56                   	push   %esi
f0103645:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103648:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103649:	9c                   	pushf  
f010364a:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010364b:	f6 c4 02             	test   $0x2,%ah
f010364e:	74 19                	je     f0103669 <trap+0x29>
f0103650:	68 93 5b 10 f0       	push   $0xf0105b93
f0103655:	68 47 56 10 f0       	push   $0xf0105647
f010365a:	68 e7 00 00 00       	push   $0xe7
f010365f:	68 ac 5b 10 f0       	push   $0xf0105bac
f0103664:	e8 37 ca ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103669:	83 ec 08             	sub    $0x8,%esp
f010366c:	56                   	push   %esi
f010366d:	68 b8 5b 10 f0       	push   $0xf0105bb8
f0103672:	e8 d2 f9 ff ff       	call   f0103049 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103677:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010367b:	83 e0 03             	and    $0x3,%eax
f010367e:	83 c4 10             	add    $0x10,%esp
f0103681:	66 83 f8 03          	cmp    $0x3,%ax
f0103685:	75 31                	jne    f01036b8 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103687:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f010368c:	85 c0                	test   %eax,%eax
f010368e:	75 19                	jne    f01036a9 <trap+0x69>
f0103690:	68 d3 5b 10 f0       	push   $0xf0105bd3
f0103695:	68 47 56 10 f0       	push   $0xf0105647
f010369a:	68 ed 00 00 00       	push   $0xed
f010369f:	68 ac 5b 10 f0       	push   $0xf0105bac
f01036a4:	e8 f7 c9 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01036a9:	b9 11 00 00 00       	mov    $0x11,%ecx
f01036ae:	89 c7                	mov    %eax,%edi
f01036b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01036b2:	8b 35 88 1f 17 f0    	mov    0xf0171f88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01036b8:	89 35 a0 27 17 f0    	mov    %esi,0xf01727a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno) {
f01036be:	8b 46 28             	mov    0x28(%esi),%eax
f01036c1:	83 f8 0e             	cmp    $0xe,%eax
f01036c4:	74 0c                	je     f01036d2 <trap+0x92>
f01036c6:	83 f8 30             	cmp    $0x30,%eax
f01036c9:	74 23                	je     f01036ee <trap+0xae>
f01036cb:	83 f8 03             	cmp    $0x3,%eax
f01036ce:	75 3f                	jne    f010370f <trap+0xcf>
f01036d0:	eb 0e                	jmp    f01036e0 <trap+0xa0>
        case T_PGFLT:
            page_fault_handler(tf);
f01036d2:	83 ec 0c             	sub    $0xc,%esp
f01036d5:	56                   	push   %esi
f01036d6:	e8 24 ff ff ff       	call   f01035ff <page_fault_handler>
f01036db:	83 c4 10             	add    $0x10,%esp
f01036de:	eb 6a                	jmp    f010374a <trap+0x10a>
            break;
        case T_BRKPT:
            monitor(tf);
f01036e0:	83 ec 0c             	sub    $0xc,%esp
f01036e3:	56                   	push   %esi
f01036e4:	e8 f5 d0 ff ff       	call   f01007de <monitor>
f01036e9:	83 c4 10             	add    $0x10,%esp
f01036ec:	eb 5c                	jmp    f010374a <trap+0x10a>
			break;
        case T_SYSCALL:
            tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f01036ee:	83 ec 08             	sub    $0x8,%esp
f01036f1:	ff 76 04             	pushl  0x4(%esi)
f01036f4:	ff 36                	pushl  (%esi)
f01036f6:	ff 76 10             	pushl  0x10(%esi)
f01036f9:	ff 76 18             	pushl  0x18(%esi)
f01036fc:	ff 76 14             	pushl  0x14(%esi)
f01036ff:	ff 76 1c             	pushl  0x1c(%esi)
f0103702:	e8 ea 00 00 00       	call   f01037f1 <syscall>
f0103707:	89 46 1c             	mov    %eax,0x1c(%esi)
f010370a:	83 c4 20             	add    $0x20,%esp
f010370d:	eb 3b                	jmp    f010374a <trap+0x10a>
                            tf->tf_regs.reg_edi,
                            tf->tf_regs.reg_esi);
            break;
        default:
        // Unexpected trap: The user process or the kernel has a bug.
        print_trapframe(tf);
f010370f:	83 ec 0c             	sub    $0xc,%esp
f0103712:	56                   	push   %esi
f0103713:	e8 74 fd ff ff       	call   f010348c <print_trapframe>
        if (tf->tf_cs == GD_KT)
f0103718:	83 c4 10             	add    $0x10,%esp
f010371b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103720:	75 17                	jne    f0103739 <trap+0xf9>
            panic("unhandled trap in kernel");
f0103722:	83 ec 04             	sub    $0x4,%esp
f0103725:	68 da 5b 10 f0       	push   $0xf0105bda
f010372a:	68 d4 00 00 00       	push   $0xd4
f010372f:	68 ac 5b 10 f0       	push   $0xf0105bac
f0103734:	e8 67 c9 ff ff       	call   f01000a0 <_panic>
        else {
            env_destroy(curenv);
f0103739:	83 ec 0c             	sub    $0xc,%esp
f010373c:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103742:	e8 e9 f7 ff ff       	call   f0102f30 <env_destroy>
f0103747:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010374a:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f010374f:	85 c0                	test   %eax,%eax
f0103751:	74 06                	je     f0103759 <trap+0x119>
f0103753:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103757:	74 19                	je     f0103772 <trap+0x132>
f0103759:	68 5c 5d 10 f0       	push   $0xf0105d5c
f010375e:	68 47 56 10 f0       	push   $0xf0105647
f0103763:	68 ff 00 00 00       	push   $0xff
f0103768:	68 ac 5b 10 f0       	push   $0xf0105bac
f010376d:	e8 2e c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103772:	83 ec 0c             	sub    $0xc,%esp
f0103775:	50                   	push   %eax
f0103776:	e8 05 f8 ff ff       	call   f0102f80 <env_run>
f010377b:	90                   	nop

f010377c <handler0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0, T_DIVIDE)
f010377c:	6a 00                	push   $0x0
f010377e:	6a 00                	push   $0x0
f0103780:	eb 5e                	jmp    f01037e0 <_alltraps>

f0103782 <handler1>:
TRAPHANDLER_NOEC(handler1, T_DEBUG)
f0103782:	6a 00                	push   $0x0
f0103784:	6a 01                	push   $0x1
f0103786:	eb 58                	jmp    f01037e0 <_alltraps>

f0103788 <handler2>:
TRAPHANDLER_NOEC(handler2, T_NMI)
f0103788:	6a 00                	push   $0x0
f010378a:	6a 02                	push   $0x2
f010378c:	eb 52                	jmp    f01037e0 <_alltraps>

f010378e <handler3>:
TRAPHANDLER_NOEC(handler3, T_BRKPT)
f010378e:	6a 00                	push   $0x0
f0103790:	6a 03                	push   $0x3
f0103792:	eb 4c                	jmp    f01037e0 <_alltraps>

f0103794 <handler4>:
TRAPHANDLER_NOEC(handler4, T_OFLOW)
f0103794:	6a 00                	push   $0x0
f0103796:	6a 04                	push   $0x4
f0103798:	eb 46                	jmp    f01037e0 <_alltraps>

f010379a <handler5>:
TRAPHANDLER_NOEC(handler5, T_BOUND)
f010379a:	6a 00                	push   $0x0
f010379c:	6a 05                	push   $0x5
f010379e:	eb 40                	jmp    f01037e0 <_alltraps>

f01037a0 <handler6>:
TRAPHANDLER_NOEC(handler6, T_ILLOP)
f01037a0:	6a 00                	push   $0x0
f01037a2:	6a 06                	push   $0x6
f01037a4:	eb 3a                	jmp    f01037e0 <_alltraps>

f01037a6 <handler7>:
TRAPHANDLER_NOEC(handler7, T_DEVICE)
f01037a6:	6a 00                	push   $0x0
f01037a8:	6a 07                	push   $0x7
f01037aa:	eb 34                	jmp    f01037e0 <_alltraps>

f01037ac <handler8>:
TRAPHANDLER(handler8, T_DBLFLT)
f01037ac:	6a 08                	push   $0x8
f01037ae:	eb 30                	jmp    f01037e0 <_alltraps>

f01037b0 <handler10>:
// 9 deprecated since 386
TRAPHANDLER(handler10, T_TSS)
f01037b0:	6a 0a                	push   $0xa
f01037b2:	eb 2c                	jmp    f01037e0 <_alltraps>

f01037b4 <handler11>:
TRAPHANDLER(handler11, T_SEGNP)
f01037b4:	6a 0b                	push   $0xb
f01037b6:	eb 28                	jmp    f01037e0 <_alltraps>

f01037b8 <handler12>:
TRAPHANDLER(handler12, T_STACK)
f01037b8:	6a 0c                	push   $0xc
f01037ba:	eb 24                	jmp    f01037e0 <_alltraps>

f01037bc <handler13>:
TRAPHANDLER(handler13, T_GPFLT)
f01037bc:	6a 0d                	push   $0xd
f01037be:	eb 20                	jmp    f01037e0 <_alltraps>

f01037c0 <handler14>:
TRAPHANDLER(handler14, T_PGFLT)
f01037c0:	6a 0e                	push   $0xe
f01037c2:	eb 1c                	jmp    f01037e0 <_alltraps>

f01037c4 <handler16>:
// 15 reserved by intel
TRAPHANDLER_NOEC(handler16, T_FPERR)
f01037c4:	6a 00                	push   $0x0
f01037c6:	6a 10                	push   $0x10
f01037c8:	eb 16                	jmp    f01037e0 <_alltraps>

f01037ca <handler17>:
TRAPHANDLER(handler17, T_ALIGN)
f01037ca:	6a 11                	push   $0x11
f01037cc:	eb 12                	jmp    f01037e0 <_alltraps>

f01037ce <handler18>:
TRAPHANDLER_NOEC(handler18, T_MCHK)
f01037ce:	6a 00                	push   $0x0
f01037d0:	6a 12                	push   $0x12
f01037d2:	eb 0c                	jmp    f01037e0 <_alltraps>

f01037d4 <handler19>:
TRAPHANDLER_NOEC(handler19, T_SIMDERR)
f01037d4:	6a 00                	push   $0x0
f01037d6:	6a 13                	push   $0x13
f01037d8:	eb 06                	jmp    f01037e0 <_alltraps>

f01037da <handler48>:
// system call (interrupt)
TRAPHANDLER_NOEC(handler48, T_SYSCALL)
f01037da:	6a 00                	push   $0x0
f01037dc:	6a 30                	push   $0x30
f01037de:	eb 00                	jmp    f01037e0 <_alltraps>

f01037e0 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
pushl %ds
f01037e0:	1e                   	push   %ds
pushl %es
f01037e1:	06                   	push   %es
pushal
f01037e2:	60                   	pusha  

movw $GD_KD, %ax
f01037e3:	66 b8 10 00          	mov    $0x10,%ax
movw %ax, %ds
f01037e7:	8e d8                	mov    %eax,%ds
movw %ax, %es
f01037e9:	8e c0                	mov    %eax,%es
pushl %esp
f01037eb:	54                   	push   %esp
call trap
f01037ec:	e8 4f fe ff ff       	call   f0103640 <trap>

f01037f1 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01037f1:	55                   	push   %ebp
f01037f2:	89 e5                	mov    %esp,%ebp
f01037f4:	83 ec 18             	sub    $0x18,%esp
f01037f7:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");

    int32_t retVal = 0;
    switch (syscallno) {
f01037fa:	83 f8 01             	cmp    $0x1,%eax
f01037fd:	74 48                	je     f0103847 <syscall+0x56>
f01037ff:	83 f8 01             	cmp    $0x1,%eax
f0103802:	72 13                	jb     f0103817 <syscall+0x26>
f0103804:	83 f8 02             	cmp    $0x2,%eax
f0103807:	0f 84 a6 00 00 00    	je     f01038b3 <syscall+0xc2>
f010380d:	83 f8 03             	cmp    $0x3,%eax
f0103810:	74 3c                	je     f010384e <syscall+0x5d>
f0103812:	e9 a6 00 00 00       	jmp    f01038bd <syscall+0xcc>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
    user_mem_assert(curenv, s, len, PTE_U);
f0103817:	6a 04                	push   $0x4
f0103819:	ff 75 10             	pushl  0x10(%ebp)
f010381c:	ff 75 0c             	pushl  0xc(%ebp)
f010381f:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103825:	e8 e3 f0 ff ff       	call   f010290d <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010382a:	83 c4 0c             	add    $0xc,%esp
f010382d:	ff 75 0c             	pushl  0xc(%ebp)
f0103830:	ff 75 10             	pushl  0x10(%ebp)
f0103833:	68 f0 5d 10 f0       	push   $0xf0105df0
f0103838:	e8 0c f8 ff ff       	call   f0103049 <cprintf>
f010383d:	83 c4 10             	add    $0x10,%esp
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

    int32_t retVal = 0;
f0103840:	b8 00 00 00 00       	mov    $0x0,%eax
f0103845:	eb 7b                	jmp    f01038c2 <syscall+0xd1>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103847:	e8 77 cc ff ff       	call   f01004c3 <cons_getc>
    case SYS_cputs:
        sys_cputs((const char *)a1, a2);
        break;
    case SYS_cgetc:
        retVal = sys_cgetc();
        break;
f010384c:	eb 74                	jmp    f01038c2 <syscall+0xd1>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010384e:	83 ec 04             	sub    $0x4,%esp
f0103851:	6a 01                	push   $0x1
f0103853:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103856:	50                   	push   %eax
f0103857:	ff 75 0c             	pushl  0xc(%ebp)
f010385a:	e8 75 f1 ff ff       	call   f01029d4 <envid2env>
f010385f:	83 c4 10             	add    $0x10,%esp
f0103862:	85 c0                	test   %eax,%eax
f0103864:	78 5c                	js     f01038c2 <syscall+0xd1>
		return r;
	if (e == curenv)
f0103866:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103869:	8b 15 88 1f 17 f0    	mov    0xf0171f88,%edx
f010386f:	39 d0                	cmp    %edx,%eax
f0103871:	75 15                	jne    f0103888 <syscall+0x97>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103873:	83 ec 08             	sub    $0x8,%esp
f0103876:	ff 70 48             	pushl  0x48(%eax)
f0103879:	68 f5 5d 10 f0       	push   $0xf0105df5
f010387e:	e8 c6 f7 ff ff       	call   f0103049 <cprintf>
f0103883:	83 c4 10             	add    $0x10,%esp
f0103886:	eb 16                	jmp    f010389e <syscall+0xad>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103888:	83 ec 04             	sub    $0x4,%esp
f010388b:	ff 70 48             	pushl  0x48(%eax)
f010388e:	ff 72 48             	pushl  0x48(%edx)
f0103891:	68 10 5e 10 f0       	push   $0xf0105e10
f0103896:	e8 ae f7 ff ff       	call   f0103049 <cprintf>
f010389b:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010389e:	83 ec 0c             	sub    $0xc,%esp
f01038a1:	ff 75 f4             	pushl  -0xc(%ebp)
f01038a4:	e8 87 f6 ff ff       	call   f0102f30 <env_destroy>
f01038a9:	83 c4 10             	add    $0x10,%esp
	return 0;
f01038ac:	b8 00 00 00 00       	mov    $0x0,%eax
    case SYS_cgetc:
        retVal = sys_cgetc();
        break;
    case SYS_env_destroy:
        retVal = sys_env_destroy(a1);
        break;
f01038b1:	eb 0f                	jmp    f01038c2 <syscall+0xd1>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01038b3:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
f01038b8:	8b 40 48             	mov    0x48(%eax),%eax
    case SYS_env_destroy:
        retVal = sys_env_destroy(a1);
        break;
    case SYS_getenvid:
        retVal = sys_getenvid();
        break;
f01038bb:	eb 05                	jmp    f01038c2 <syscall+0xd1>
    default:
        retVal = -E_INVAL;
f01038bd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    }
    return retVal;
}
f01038c2:	c9                   	leave  
f01038c3:	c3                   	ret    

f01038c4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01038c4:	55                   	push   %ebp
f01038c5:	89 e5                	mov    %esp,%ebp
f01038c7:	57                   	push   %edi
f01038c8:	56                   	push   %esi
f01038c9:	53                   	push   %ebx
f01038ca:	83 ec 14             	sub    $0x14,%esp
f01038cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038d0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01038d3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01038d6:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01038d9:	8b 1a                	mov    (%edx),%ebx
f01038db:	8b 01                	mov    (%ecx),%eax
f01038dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038e0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01038e7:	eb 7f                	jmp    f0103968 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01038e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01038ec:	01 d8                	add    %ebx,%eax
f01038ee:	89 c6                	mov    %eax,%esi
f01038f0:	c1 ee 1f             	shr    $0x1f,%esi
f01038f3:	01 c6                	add    %eax,%esi
f01038f5:	d1 fe                	sar    %esi
f01038f7:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01038fa:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038fd:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103900:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103902:	eb 03                	jmp    f0103907 <stab_binsearch+0x43>
			m--;
f0103904:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103907:	39 c3                	cmp    %eax,%ebx
f0103909:	7f 0d                	jg     f0103918 <stab_binsearch+0x54>
f010390b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010390f:	83 ea 0c             	sub    $0xc,%edx
f0103912:	39 f9                	cmp    %edi,%ecx
f0103914:	75 ee                	jne    f0103904 <stab_binsearch+0x40>
f0103916:	eb 05                	jmp    f010391d <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103918:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010391b:	eb 4b                	jmp    f0103968 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010391d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103920:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103923:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103927:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010392a:	76 11                	jbe    f010393d <stab_binsearch+0x79>
			*region_left = m;
f010392c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010392f:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103931:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103934:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010393b:	eb 2b                	jmp    f0103968 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010393d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103940:	73 14                	jae    f0103956 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103942:	83 e8 01             	sub    $0x1,%eax
f0103945:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103948:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010394b:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010394d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103954:	eb 12                	jmp    f0103968 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103956:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103959:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010395b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010395f:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103961:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103968:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010396b:	0f 8e 78 ff ff ff    	jle    f01038e9 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103971:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103975:	75 0f                	jne    f0103986 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103977:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010397a:	8b 00                	mov    (%eax),%eax
f010397c:	83 e8 01             	sub    $0x1,%eax
f010397f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103982:	89 06                	mov    %eax,(%esi)
f0103984:	eb 2c                	jmp    f01039b2 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103986:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103989:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010398b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010398e:	8b 0e                	mov    (%esi),%ecx
f0103990:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103993:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103996:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103999:	eb 03                	jmp    f010399e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010399b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010399e:	39 c8                	cmp    %ecx,%eax
f01039a0:	7e 0b                	jle    f01039ad <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01039a2:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01039a6:	83 ea 0c             	sub    $0xc,%edx
f01039a9:	39 df                	cmp    %ebx,%edi
f01039ab:	75 ee                	jne    f010399b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01039ad:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01039b0:	89 06                	mov    %eax,(%esi)
	}
}
f01039b2:	83 c4 14             	add    $0x14,%esp
f01039b5:	5b                   	pop    %ebx
f01039b6:	5e                   	pop    %esi
f01039b7:	5f                   	pop    %edi
f01039b8:	5d                   	pop    %ebp
f01039b9:	c3                   	ret    

f01039ba <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01039ba:	55                   	push   %ebp
f01039bb:	89 e5                	mov    %esp,%ebp
f01039bd:	57                   	push   %edi
f01039be:	56                   	push   %esi
f01039bf:	53                   	push   %ebx
f01039c0:	83 ec 3c             	sub    $0x3c,%esp
f01039c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01039c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01039c9:	c7 03 28 5e 10 f0    	movl   $0xf0105e28,(%ebx)
	info->eip_line = 0;
f01039cf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01039d6:	c7 43 08 28 5e 10 f0 	movl   $0xf0105e28,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01039dd:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01039e4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01039e7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01039ee:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01039f4:	0f 87 8a 00 00 00    	ja     f0103a84 <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
        if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) < 0) {
f01039fa:	6a 04                	push   $0x4
f01039fc:	6a 10                	push   $0x10
f01039fe:	68 00 00 20 00       	push   $0x200000
f0103a03:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103a09:	e8 6b ee ff ff       	call   f0102879 <user_mem_check>
f0103a0e:	83 c4 10             	add    $0x10,%esp
f0103a11:	85 c0                	test   %eax,%eax
f0103a13:	0f 88 2d 02 00 00    	js     f0103c46 <debuginfo_eip+0x28c>
            return -1;
        }
		stabs = usd->stabs;
f0103a19:	a1 00 00 20 00       	mov    0x200000,%eax
f0103a1e:	89 c1                	mov    %eax,%ecx
f0103a20:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103a23:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0103a29:	a1 08 00 20 00       	mov    0x200008,%eax
f0103a2e:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103a31:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0103a37:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
if (user_mem_check(curenv, (void *)stabs, stab_end-stabs, PTE_U) < 0) {
f0103a3a:	6a 04                	push   $0x4
f0103a3c:	89 f8                	mov    %edi,%eax
f0103a3e:	29 c8                	sub    %ecx,%eax
f0103a40:	c1 f8 02             	sar    $0x2,%eax
f0103a43:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103a49:	50                   	push   %eax
f0103a4a:	51                   	push   %ecx
f0103a4b:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103a51:	e8 23 ee ff ff       	call   f0102879 <user_mem_check>
f0103a56:	83 c4 10             	add    $0x10,%esp
f0103a59:	85 c0                	test   %eax,%eax
f0103a5b:	0f 88 ec 01 00 00    	js     f0103c4d <debuginfo_eip+0x293>
            return -1;
        }
        if (user_mem_check(curenv, (void *)stabstr, stabstr_end-stabstr, PTE_U) < 0) {
f0103a61:	6a 04                	push   $0x4
f0103a63:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103a66:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103a69:	29 ca                	sub    %ecx,%edx
f0103a6b:	52                   	push   %edx
f0103a6c:	51                   	push   %ecx
f0103a6d:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f0103a73:	e8 01 ee ff ff       	call   f0102879 <user_mem_check>
f0103a78:	83 c4 10             	add    $0x10,%esp
f0103a7b:	85 c0                	test   %eax,%eax
f0103a7d:	79 1f                	jns    f0103a9e <debuginfo_eip+0xe4>
f0103a7f:	e9 d0 01 00 00       	jmp    f0103c54 <debuginfo_eip+0x29a>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103a84:	c7 45 bc 2b 04 11 f0 	movl   $0xf011042b,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103a8b:	c7 45 b8 9d d9 10 f0 	movl   $0xf010d99d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103a92:	bf 9c d9 10 f0       	mov    $0xf010d99c,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103a97:	c7 45 c0 40 60 10 f0 	movl   $0xf0106040,-0x40(%ebp)
            return -1;
        }
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a9e:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103aa1:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103aa4:	0f 83 b1 01 00 00    	jae    f0103c5b <debuginfo_eip+0x2a1>
f0103aaa:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103aae:	0f 85 ae 01 00 00    	jne    f0103c62 <debuginfo_eip+0x2a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103ab4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103abb:	2b 7d c0             	sub    -0x40(%ebp),%edi
f0103abe:	c1 ff 02             	sar    $0x2,%edi
f0103ac1:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0103ac7:	83 e8 01             	sub    $0x1,%eax
f0103aca:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103acd:	83 ec 08             	sub    $0x8,%esp
f0103ad0:	56                   	push   %esi
f0103ad1:	6a 64                	push   $0x64
f0103ad3:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103ad6:	89 d1                	mov    %edx,%ecx
f0103ad8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103adb:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103ade:	89 f8                	mov    %edi,%eax
f0103ae0:	e8 df fd ff ff       	call   f01038c4 <stab_binsearch>
	if (lfile == 0)
f0103ae5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103ae8:	83 c4 10             	add    $0x10,%esp
f0103aeb:	85 c0                	test   %eax,%eax
f0103aed:	0f 84 76 01 00 00    	je     f0103c69 <debuginfo_eip+0x2af>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103af3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103af6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103af9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103afc:	83 ec 08             	sub    $0x8,%esp
f0103aff:	56                   	push   %esi
f0103b00:	6a 24                	push   $0x24
f0103b02:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103b05:	89 d1                	mov    %edx,%ecx
f0103b07:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103b0a:	89 f8                	mov    %edi,%eax
f0103b0c:	e8 b3 fd ff ff       	call   f01038c4 <stab_binsearch>

	if (lfun <= rfun) {
f0103b11:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b14:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103b17:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103b1a:	83 c4 10             	add    $0x10,%esp
f0103b1d:	39 d0                	cmp    %edx,%eax
f0103b1f:	7f 2b                	jg     f0103b4c <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103b21:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b24:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103b27:	8b 11                	mov    (%ecx),%edx
f0103b29:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103b2c:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103b2f:	39 fa                	cmp    %edi,%edx
f0103b31:	73 06                	jae    f0103b39 <debuginfo_eip+0x17f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103b33:	03 55 b8             	add    -0x48(%ebp),%edx
f0103b36:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103b39:	8b 51 08             	mov    0x8(%ecx),%edx
f0103b3c:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103b3f:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103b41:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103b44:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103b47:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103b4a:	eb 0f                	jmp    f0103b5b <debuginfo_eip+0x1a1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103b4c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103b4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b52:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103b55:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b58:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103b5b:	83 ec 08             	sub    $0x8,%esp
f0103b5e:	6a 3a                	push   $0x3a
f0103b60:	ff 73 08             	pushl  0x8(%ebx)
f0103b63:	e8 8f 08 00 00       	call   f01043f7 <strfind>
f0103b68:	2b 43 08             	sub    0x8(%ebx),%eax
f0103b6b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103b6e:	83 c4 08             	add    $0x8,%esp
f0103b71:	56                   	push   %esi
f0103b72:	6a 44                	push   $0x44
f0103b74:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103b77:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103b7a:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b7d:	89 f8                	mov    %edi,%eax
f0103b7f:	e8 40 fd ff ff       	call   f01038c4 <stab_binsearch>
	  if (lline <= rline) {
f0103b84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b87:	83 c4 10             	add    $0x10,%esp
f0103b8a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103b8d:	0f 8f dd 00 00 00    	jg     f0103c70 <debuginfo_eip+0x2b6>
	      info->eip_line = stabs[lline].n_desc;
f0103b93:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b96:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103b99:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103b9d:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103ba0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ba3:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103ba7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103baa:	eb 0a                	jmp    f0103bb6 <debuginfo_eip+0x1fc>
f0103bac:	83 e8 01             	sub    $0x1,%eax
f0103baf:	83 ea 0c             	sub    $0xc,%edx
f0103bb2:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103bb6:	39 c7                	cmp    %eax,%edi
f0103bb8:	7e 05                	jle    f0103bbf <debuginfo_eip+0x205>
f0103bba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bbd:	eb 47                	jmp    f0103c06 <debuginfo_eip+0x24c>
	       && stabs[lline].n_type != N_SOL
f0103bbf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103bc3:	80 f9 84             	cmp    $0x84,%cl
f0103bc6:	75 0e                	jne    f0103bd6 <debuginfo_eip+0x21c>
f0103bc8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bcb:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103bcf:	74 1c                	je     f0103bed <debuginfo_eip+0x233>
f0103bd1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103bd4:	eb 17                	jmp    f0103bed <debuginfo_eip+0x233>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103bd6:	80 f9 64             	cmp    $0x64,%cl
f0103bd9:	75 d1                	jne    f0103bac <debuginfo_eip+0x1f2>
f0103bdb:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103bdf:	74 cb                	je     f0103bac <debuginfo_eip+0x1f2>
f0103be1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103be4:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103be8:	74 03                	je     f0103bed <debuginfo_eip+0x233>
f0103bea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103bed:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103bf0:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103bf3:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103bf6:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103bf9:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103bfc:	29 f0                	sub    %esi,%eax
f0103bfe:	39 c2                	cmp    %eax,%edx
f0103c00:	73 04                	jae    f0103c06 <debuginfo_eip+0x24c>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103c02:	01 f2                	add    %esi,%edx
f0103c04:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c06:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103c09:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c0c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c11:	39 f2                	cmp    %esi,%edx
f0103c13:	7d 67                	jge    f0103c7c <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
f0103c15:	83 c2 01             	add    $0x1,%edx
f0103c18:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103c1b:	89 d0                	mov    %edx,%eax
f0103c1d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103c20:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103c23:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103c26:	eb 04                	jmp    f0103c2c <debuginfo_eip+0x272>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103c28:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103c2c:	39 c6                	cmp    %eax,%esi
f0103c2e:	7e 47                	jle    f0103c77 <debuginfo_eip+0x2bd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103c30:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103c34:	83 c0 01             	add    $0x1,%eax
f0103c37:	83 c2 0c             	add    $0xc,%edx
f0103c3a:	80 f9 a0             	cmp    $0xa0,%cl
f0103c3d:	74 e9                	je     f0103c28 <debuginfo_eip+0x26e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c44:	eb 36                	jmp    f0103c7c <debuginfo_eip+0x2c2>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
        if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) < 0) {
            return -1;
f0103c46:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c4b:	eb 2f                	jmp    f0103c7c <debuginfo_eip+0x2c2>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
if (user_mem_check(curenv, (void *)stabs, stab_end-stabs, PTE_U) < 0) {
            return -1;
f0103c4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c52:	eb 28                	jmp    f0103c7c <debuginfo_eip+0x2c2>
        }
        if (user_mem_check(curenv, (void *)stabstr, stabstr_end-stabstr, PTE_U) < 0) {
            return -1;
f0103c54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c59:	eb 21                	jmp    f0103c7c <debuginfo_eip+0x2c2>
        }
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103c5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c60:	eb 1a                	jmp    f0103c7c <debuginfo_eip+0x2c2>
f0103c62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c67:	eb 13                	jmp    f0103c7c <debuginfo_eip+0x2c2>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103c69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c6e:	eb 0c                	jmp    f0103c7c <debuginfo_eip+0x2c2>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	  if (lline <= rline) {
	      info->eip_line = stabs[lline].n_desc;
	  } else {
	      return -1;
f0103c70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c75:	eb 05                	jmp    f0103c7c <debuginfo_eip+0x2c2>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c77:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c7f:	5b                   	pop    %ebx
f0103c80:	5e                   	pop    %esi
f0103c81:	5f                   	pop    %edi
f0103c82:	5d                   	pop    %ebp
f0103c83:	c3                   	ret    

f0103c84 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103c84:	55                   	push   %ebp
f0103c85:	89 e5                	mov    %esp,%ebp
f0103c87:	57                   	push   %edi
f0103c88:	56                   	push   %esi
f0103c89:	53                   	push   %ebx
f0103c8a:	83 ec 1c             	sub    $0x1c,%esp
f0103c8d:	89 c7                	mov    %eax,%edi
f0103c8f:	89 d6                	mov    %edx,%esi
f0103c91:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c94:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c9a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103c9d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103ca0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103ca5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103ca8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103cab:	39 d3                	cmp    %edx,%ebx
f0103cad:	72 05                	jb     f0103cb4 <printnum+0x30>
f0103caf:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103cb2:	77 45                	ja     f0103cf9 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103cb4:	83 ec 0c             	sub    $0xc,%esp
f0103cb7:	ff 75 18             	pushl  0x18(%ebp)
f0103cba:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cbd:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103cc0:	53                   	push   %ebx
f0103cc1:	ff 75 10             	pushl  0x10(%ebp)
f0103cc4:	83 ec 08             	sub    $0x8,%esp
f0103cc7:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103cca:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ccd:	ff 75 dc             	pushl  -0x24(%ebp)
f0103cd0:	ff 75 d8             	pushl  -0x28(%ebp)
f0103cd3:	e8 48 09 00 00       	call   f0104620 <__udivdi3>
f0103cd8:	83 c4 18             	add    $0x18,%esp
f0103cdb:	52                   	push   %edx
f0103cdc:	50                   	push   %eax
f0103cdd:	89 f2                	mov    %esi,%edx
f0103cdf:	89 f8                	mov    %edi,%eax
f0103ce1:	e8 9e ff ff ff       	call   f0103c84 <printnum>
f0103ce6:	83 c4 20             	add    $0x20,%esp
f0103ce9:	eb 18                	jmp    f0103d03 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103ceb:	83 ec 08             	sub    $0x8,%esp
f0103cee:	56                   	push   %esi
f0103cef:	ff 75 18             	pushl  0x18(%ebp)
f0103cf2:	ff d7                	call   *%edi
f0103cf4:	83 c4 10             	add    $0x10,%esp
f0103cf7:	eb 03                	jmp    f0103cfc <printnum+0x78>
f0103cf9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103cfc:	83 eb 01             	sub    $0x1,%ebx
f0103cff:	85 db                	test   %ebx,%ebx
f0103d01:	7f e8                	jg     f0103ceb <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103d03:	83 ec 08             	sub    $0x8,%esp
f0103d06:	56                   	push   %esi
f0103d07:	83 ec 04             	sub    $0x4,%esp
f0103d0a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d0d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d10:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d13:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d16:	e8 35 0a 00 00       	call   f0104750 <__umoddi3>
f0103d1b:	83 c4 14             	add    $0x14,%esp
f0103d1e:	0f be 80 32 5e 10 f0 	movsbl -0xfefa1ce(%eax),%eax
f0103d25:	50                   	push   %eax
f0103d26:	ff d7                	call   *%edi
}
f0103d28:	83 c4 10             	add    $0x10,%esp
f0103d2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d2e:	5b                   	pop    %ebx
f0103d2f:	5e                   	pop    %esi
f0103d30:	5f                   	pop    %edi
f0103d31:	5d                   	pop    %ebp
f0103d32:	c3                   	ret    

f0103d33 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103d33:	55                   	push   %ebp
f0103d34:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103d36:	83 fa 01             	cmp    $0x1,%edx
f0103d39:	7e 0e                	jle    f0103d49 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103d3b:	8b 10                	mov    (%eax),%edx
f0103d3d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103d40:	89 08                	mov    %ecx,(%eax)
f0103d42:	8b 02                	mov    (%edx),%eax
f0103d44:	8b 52 04             	mov    0x4(%edx),%edx
f0103d47:	eb 22                	jmp    f0103d6b <getuint+0x38>
	else if (lflag)
f0103d49:	85 d2                	test   %edx,%edx
f0103d4b:	74 10                	je     f0103d5d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103d4d:	8b 10                	mov    (%eax),%edx
f0103d4f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d52:	89 08                	mov    %ecx,(%eax)
f0103d54:	8b 02                	mov    (%edx),%eax
f0103d56:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d5b:	eb 0e                	jmp    f0103d6b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103d5d:	8b 10                	mov    (%eax),%edx
f0103d5f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d62:	89 08                	mov    %ecx,(%eax)
f0103d64:	8b 02                	mov    (%edx),%eax
f0103d66:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103d6b:	5d                   	pop    %ebp
f0103d6c:	c3                   	ret    

f0103d6d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103d6d:	55                   	push   %ebp
f0103d6e:	89 e5                	mov    %esp,%ebp
f0103d70:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103d73:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103d77:	8b 10                	mov    (%eax),%edx
f0103d79:	3b 50 04             	cmp    0x4(%eax),%edx
f0103d7c:	73 0a                	jae    f0103d88 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103d7e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103d81:	89 08                	mov    %ecx,(%eax)
f0103d83:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d86:	88 02                	mov    %al,(%edx)
}
f0103d88:	5d                   	pop    %ebp
f0103d89:	c3                   	ret    

f0103d8a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103d8a:	55                   	push   %ebp
f0103d8b:	89 e5                	mov    %esp,%ebp
f0103d8d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103d90:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103d93:	50                   	push   %eax
f0103d94:	ff 75 10             	pushl  0x10(%ebp)
f0103d97:	ff 75 0c             	pushl  0xc(%ebp)
f0103d9a:	ff 75 08             	pushl  0x8(%ebp)
f0103d9d:	e8 05 00 00 00       	call   f0103da7 <vprintfmt>
	va_end(ap);
}
f0103da2:	83 c4 10             	add    $0x10,%esp
f0103da5:	c9                   	leave  
f0103da6:	c3                   	ret    

f0103da7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103da7:	55                   	push   %ebp
f0103da8:	89 e5                	mov    %esp,%ebp
f0103daa:	57                   	push   %edi
f0103dab:	56                   	push   %esi
f0103dac:	53                   	push   %ebx
f0103dad:	83 ec 2c             	sub    $0x2c,%esp
f0103db0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103db3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103db6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103db9:	eb 12                	jmp    f0103dcd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103dbb:	85 c0                	test   %eax,%eax
f0103dbd:	0f 84 89 03 00 00    	je     f010414c <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103dc3:	83 ec 08             	sub    $0x8,%esp
f0103dc6:	53                   	push   %ebx
f0103dc7:	50                   	push   %eax
f0103dc8:	ff d6                	call   *%esi
f0103dca:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103dcd:	83 c7 01             	add    $0x1,%edi
f0103dd0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103dd4:	83 f8 25             	cmp    $0x25,%eax
f0103dd7:	75 e2                	jne    f0103dbb <vprintfmt+0x14>
f0103dd9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103ddd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103de4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103deb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103df2:	ba 00 00 00 00       	mov    $0x0,%edx
f0103df7:	eb 07                	jmp    f0103e00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103df9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103dfc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e00:	8d 47 01             	lea    0x1(%edi),%eax
f0103e03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e06:	0f b6 07             	movzbl (%edi),%eax
f0103e09:	0f b6 c8             	movzbl %al,%ecx
f0103e0c:	83 e8 23             	sub    $0x23,%eax
f0103e0f:	3c 55                	cmp    $0x55,%al
f0103e11:	0f 87 1a 03 00 00    	ja     f0104131 <vprintfmt+0x38a>
f0103e17:	0f b6 c0             	movzbl %al,%eax
f0103e1a:	ff 24 85 bc 5e 10 f0 	jmp    *-0xfefa144(,%eax,4)
f0103e21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103e24:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103e28:	eb d6                	jmp    f0103e00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e32:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103e35:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103e38:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103e3c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103e3f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103e42:	83 fa 09             	cmp    $0x9,%edx
f0103e45:	77 39                	ja     f0103e80 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103e47:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103e4a:	eb e9                	jmp    f0103e35 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103e4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e4f:	8d 48 04             	lea    0x4(%eax),%ecx
f0103e52:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103e55:	8b 00                	mov    (%eax),%eax
f0103e57:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103e5d:	eb 27                	jmp    f0103e86 <vprintfmt+0xdf>
f0103e5f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e62:	85 c0                	test   %eax,%eax
f0103e64:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e69:	0f 49 c8             	cmovns %eax,%ecx
f0103e6c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e72:	eb 8c                	jmp    f0103e00 <vprintfmt+0x59>
f0103e74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103e77:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103e7e:	eb 80                	jmp    f0103e00 <vprintfmt+0x59>
f0103e80:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103e83:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103e86:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e8a:	0f 89 70 ff ff ff    	jns    f0103e00 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103e90:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e93:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e96:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103e9d:	e9 5e ff ff ff       	jmp    f0103e00 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103ea2:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ea5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103ea8:	e9 53 ff ff ff       	jmp    f0103e00 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103ead:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eb0:	8d 50 04             	lea    0x4(%eax),%edx
f0103eb3:	89 55 14             	mov    %edx,0x14(%ebp)
f0103eb6:	83 ec 08             	sub    $0x8,%esp
f0103eb9:	53                   	push   %ebx
f0103eba:	ff 30                	pushl  (%eax)
f0103ebc:	ff d6                	call   *%esi
			break;
f0103ebe:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ec1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103ec4:	e9 04 ff ff ff       	jmp    f0103dcd <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103ec9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ecc:	8d 50 04             	lea    0x4(%eax),%edx
f0103ecf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ed2:	8b 00                	mov    (%eax),%eax
f0103ed4:	99                   	cltd   
f0103ed5:	31 d0                	xor    %edx,%eax
f0103ed7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103ed9:	83 f8 06             	cmp    $0x6,%eax
f0103edc:	7f 0b                	jg     f0103ee9 <vprintfmt+0x142>
f0103ede:	8b 14 85 14 60 10 f0 	mov    -0xfef9fec(,%eax,4),%edx
f0103ee5:	85 d2                	test   %edx,%edx
f0103ee7:	75 18                	jne    f0103f01 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103ee9:	50                   	push   %eax
f0103eea:	68 4a 5e 10 f0       	push   $0xf0105e4a
f0103eef:	53                   	push   %ebx
f0103ef0:	56                   	push   %esi
f0103ef1:	e8 94 fe ff ff       	call   f0103d8a <printfmt>
f0103ef6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103efc:	e9 cc fe ff ff       	jmp    f0103dcd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103f01:	52                   	push   %edx
f0103f02:	68 59 56 10 f0       	push   $0xf0105659
f0103f07:	53                   	push   %ebx
f0103f08:	56                   	push   %esi
f0103f09:	e8 7c fe ff ff       	call   f0103d8a <printfmt>
f0103f0e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f11:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f14:	e9 b4 fe ff ff       	jmp    f0103dcd <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103f19:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f1c:	8d 50 04             	lea    0x4(%eax),%edx
f0103f1f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f22:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103f24:	85 ff                	test   %edi,%edi
f0103f26:	b8 43 5e 10 f0       	mov    $0xf0105e43,%eax
f0103f2b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103f2e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103f32:	0f 8e 94 00 00 00    	jle    f0103fcc <vprintfmt+0x225>
f0103f38:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103f3c:	0f 84 98 00 00 00    	je     f0103fda <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f42:	83 ec 08             	sub    $0x8,%esp
f0103f45:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f48:	57                   	push   %edi
f0103f49:	e8 5f 03 00 00       	call   f01042ad <strnlen>
f0103f4e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103f51:	29 c1                	sub    %eax,%ecx
f0103f53:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103f56:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103f59:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103f5d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f60:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103f63:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f65:	eb 0f                	jmp    f0103f76 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103f67:	83 ec 08             	sub    $0x8,%esp
f0103f6a:	53                   	push   %ebx
f0103f6b:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f6e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f70:	83 ef 01             	sub    $0x1,%edi
f0103f73:	83 c4 10             	add    $0x10,%esp
f0103f76:	85 ff                	test   %edi,%edi
f0103f78:	7f ed                	jg     f0103f67 <vprintfmt+0x1c0>
f0103f7a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103f7d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103f80:	85 c9                	test   %ecx,%ecx
f0103f82:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f87:	0f 49 c1             	cmovns %ecx,%eax
f0103f8a:	29 c1                	sub    %eax,%ecx
f0103f8c:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f8f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f92:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f95:	89 cb                	mov    %ecx,%ebx
f0103f97:	eb 4d                	jmp    f0103fe6 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103f99:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103f9d:	74 1b                	je     f0103fba <vprintfmt+0x213>
f0103f9f:	0f be c0             	movsbl %al,%eax
f0103fa2:	83 e8 20             	sub    $0x20,%eax
f0103fa5:	83 f8 5e             	cmp    $0x5e,%eax
f0103fa8:	76 10                	jbe    f0103fba <vprintfmt+0x213>
					putch('?', putdat);
f0103faa:	83 ec 08             	sub    $0x8,%esp
f0103fad:	ff 75 0c             	pushl  0xc(%ebp)
f0103fb0:	6a 3f                	push   $0x3f
f0103fb2:	ff 55 08             	call   *0x8(%ebp)
f0103fb5:	83 c4 10             	add    $0x10,%esp
f0103fb8:	eb 0d                	jmp    f0103fc7 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103fba:	83 ec 08             	sub    $0x8,%esp
f0103fbd:	ff 75 0c             	pushl  0xc(%ebp)
f0103fc0:	52                   	push   %edx
f0103fc1:	ff 55 08             	call   *0x8(%ebp)
f0103fc4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103fc7:	83 eb 01             	sub    $0x1,%ebx
f0103fca:	eb 1a                	jmp    f0103fe6 <vprintfmt+0x23f>
f0103fcc:	89 75 08             	mov    %esi,0x8(%ebp)
f0103fcf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103fd2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103fd5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103fd8:	eb 0c                	jmp    f0103fe6 <vprintfmt+0x23f>
f0103fda:	89 75 08             	mov    %esi,0x8(%ebp)
f0103fdd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103fe0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103fe3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103fe6:	83 c7 01             	add    $0x1,%edi
f0103fe9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103fed:	0f be d0             	movsbl %al,%edx
f0103ff0:	85 d2                	test   %edx,%edx
f0103ff2:	74 23                	je     f0104017 <vprintfmt+0x270>
f0103ff4:	85 f6                	test   %esi,%esi
f0103ff6:	78 a1                	js     f0103f99 <vprintfmt+0x1f2>
f0103ff8:	83 ee 01             	sub    $0x1,%esi
f0103ffb:	79 9c                	jns    f0103f99 <vprintfmt+0x1f2>
f0103ffd:	89 df                	mov    %ebx,%edi
f0103fff:	8b 75 08             	mov    0x8(%ebp),%esi
f0104002:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104005:	eb 18                	jmp    f010401f <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104007:	83 ec 08             	sub    $0x8,%esp
f010400a:	53                   	push   %ebx
f010400b:	6a 20                	push   $0x20
f010400d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010400f:	83 ef 01             	sub    $0x1,%edi
f0104012:	83 c4 10             	add    $0x10,%esp
f0104015:	eb 08                	jmp    f010401f <vprintfmt+0x278>
f0104017:	89 df                	mov    %ebx,%edi
f0104019:	8b 75 08             	mov    0x8(%ebp),%esi
f010401c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010401f:	85 ff                	test   %edi,%edi
f0104021:	7f e4                	jg     f0104007 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104023:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104026:	e9 a2 fd ff ff       	jmp    f0103dcd <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010402b:	83 fa 01             	cmp    $0x1,%edx
f010402e:	7e 16                	jle    f0104046 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104030:	8b 45 14             	mov    0x14(%ebp),%eax
f0104033:	8d 50 08             	lea    0x8(%eax),%edx
f0104036:	89 55 14             	mov    %edx,0x14(%ebp)
f0104039:	8b 50 04             	mov    0x4(%eax),%edx
f010403c:	8b 00                	mov    (%eax),%eax
f010403e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104041:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104044:	eb 32                	jmp    f0104078 <vprintfmt+0x2d1>
	else if (lflag)
f0104046:	85 d2                	test   %edx,%edx
f0104048:	74 18                	je     f0104062 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010404a:	8b 45 14             	mov    0x14(%ebp),%eax
f010404d:	8d 50 04             	lea    0x4(%eax),%edx
f0104050:	89 55 14             	mov    %edx,0x14(%ebp)
f0104053:	8b 00                	mov    (%eax),%eax
f0104055:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104058:	89 c1                	mov    %eax,%ecx
f010405a:	c1 f9 1f             	sar    $0x1f,%ecx
f010405d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104060:	eb 16                	jmp    f0104078 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104062:	8b 45 14             	mov    0x14(%ebp),%eax
f0104065:	8d 50 04             	lea    0x4(%eax),%edx
f0104068:	89 55 14             	mov    %edx,0x14(%ebp)
f010406b:	8b 00                	mov    (%eax),%eax
f010406d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104070:	89 c1                	mov    %eax,%ecx
f0104072:	c1 f9 1f             	sar    $0x1f,%ecx
f0104075:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104078:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010407b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010407e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104083:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104087:	79 74                	jns    f01040fd <vprintfmt+0x356>
				putch('-', putdat);
f0104089:	83 ec 08             	sub    $0x8,%esp
f010408c:	53                   	push   %ebx
f010408d:	6a 2d                	push   $0x2d
f010408f:	ff d6                	call   *%esi
				num = -(long long) num;
f0104091:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104094:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104097:	f7 d8                	neg    %eax
f0104099:	83 d2 00             	adc    $0x0,%edx
f010409c:	f7 da                	neg    %edx
f010409e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01040a1:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01040a6:	eb 55                	jmp    f01040fd <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01040a8:	8d 45 14             	lea    0x14(%ebp),%eax
f01040ab:	e8 83 fc ff ff       	call   f0103d33 <getuint>
			base = 10;
f01040b0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01040b5:	eb 46                	jmp    f01040fd <vprintfmt+0x356>

		// (unsigned) octal
	        case 'o':
			num = getuint(&ap, lflag);
f01040b7:	8d 45 14             	lea    0x14(%ebp),%eax
f01040ba:	e8 74 fc ff ff       	call   f0103d33 <getuint>
			base = 8;
f01040bf:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01040c4:	eb 37                	jmp    f01040fd <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01040c6:	83 ec 08             	sub    $0x8,%esp
f01040c9:	53                   	push   %ebx
f01040ca:	6a 30                	push   $0x30
f01040cc:	ff d6                	call   *%esi
			putch('x', putdat);
f01040ce:	83 c4 08             	add    $0x8,%esp
f01040d1:	53                   	push   %ebx
f01040d2:	6a 78                	push   $0x78
f01040d4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01040d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01040d9:	8d 50 04             	lea    0x4(%eax),%edx
f01040dc:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01040df:	8b 00                	mov    (%eax),%eax
f01040e1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01040e6:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01040e9:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01040ee:	eb 0d                	jmp    f01040fd <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01040f0:	8d 45 14             	lea    0x14(%ebp),%eax
f01040f3:	e8 3b fc ff ff       	call   f0103d33 <getuint>
			base = 16;
f01040f8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01040fd:	83 ec 0c             	sub    $0xc,%esp
f0104100:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104104:	57                   	push   %edi
f0104105:	ff 75 e0             	pushl  -0x20(%ebp)
f0104108:	51                   	push   %ecx
f0104109:	52                   	push   %edx
f010410a:	50                   	push   %eax
f010410b:	89 da                	mov    %ebx,%edx
f010410d:	89 f0                	mov    %esi,%eax
f010410f:	e8 70 fb ff ff       	call   f0103c84 <printnum>
			break;
f0104114:	83 c4 20             	add    $0x20,%esp
f0104117:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010411a:	e9 ae fc ff ff       	jmp    f0103dcd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010411f:	83 ec 08             	sub    $0x8,%esp
f0104122:	53                   	push   %ebx
f0104123:	51                   	push   %ecx
f0104124:	ff d6                	call   *%esi
			break;
f0104126:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104129:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010412c:	e9 9c fc ff ff       	jmp    f0103dcd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104131:	83 ec 08             	sub    $0x8,%esp
f0104134:	53                   	push   %ebx
f0104135:	6a 25                	push   $0x25
f0104137:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104139:	83 c4 10             	add    $0x10,%esp
f010413c:	eb 03                	jmp    f0104141 <vprintfmt+0x39a>
f010413e:	83 ef 01             	sub    $0x1,%edi
f0104141:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104145:	75 f7                	jne    f010413e <vprintfmt+0x397>
f0104147:	e9 81 fc ff ff       	jmp    f0103dcd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010414c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010414f:	5b                   	pop    %ebx
f0104150:	5e                   	pop    %esi
f0104151:	5f                   	pop    %edi
f0104152:	5d                   	pop    %ebp
f0104153:	c3                   	ret    

f0104154 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104154:	55                   	push   %ebp
f0104155:	89 e5                	mov    %esp,%ebp
f0104157:	83 ec 18             	sub    $0x18,%esp
f010415a:	8b 45 08             	mov    0x8(%ebp),%eax
f010415d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104160:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104163:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104167:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010416a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104171:	85 c0                	test   %eax,%eax
f0104173:	74 26                	je     f010419b <vsnprintf+0x47>
f0104175:	85 d2                	test   %edx,%edx
f0104177:	7e 22                	jle    f010419b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104179:	ff 75 14             	pushl  0x14(%ebp)
f010417c:	ff 75 10             	pushl  0x10(%ebp)
f010417f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104182:	50                   	push   %eax
f0104183:	68 6d 3d 10 f0       	push   $0xf0103d6d
f0104188:	e8 1a fc ff ff       	call   f0103da7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010418d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104190:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104193:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104196:	83 c4 10             	add    $0x10,%esp
f0104199:	eb 05                	jmp    f01041a0 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010419b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01041a0:	c9                   	leave  
f01041a1:	c3                   	ret    

f01041a2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01041a2:	55                   	push   %ebp
f01041a3:	89 e5                	mov    %esp,%ebp
f01041a5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01041a8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01041ab:	50                   	push   %eax
f01041ac:	ff 75 10             	pushl  0x10(%ebp)
f01041af:	ff 75 0c             	pushl  0xc(%ebp)
f01041b2:	ff 75 08             	pushl  0x8(%ebp)
f01041b5:	e8 9a ff ff ff       	call   f0104154 <vsnprintf>
	va_end(ap);

	return rc;
}
f01041ba:	c9                   	leave  
f01041bb:	c3                   	ret    

f01041bc <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01041bc:	55                   	push   %ebp
f01041bd:	89 e5                	mov    %esp,%ebp
f01041bf:	57                   	push   %edi
f01041c0:	56                   	push   %esi
f01041c1:	53                   	push   %ebx
f01041c2:	83 ec 0c             	sub    $0xc,%esp
f01041c5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01041c8:	85 c0                	test   %eax,%eax
f01041ca:	74 11                	je     f01041dd <readline+0x21>
		cprintf("%s", prompt);
f01041cc:	83 ec 08             	sub    $0x8,%esp
f01041cf:	50                   	push   %eax
f01041d0:	68 59 56 10 f0       	push   $0xf0105659
f01041d5:	e8 6f ee ff ff       	call   f0103049 <cprintf>
f01041da:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01041dd:	83 ec 0c             	sub    $0xc,%esp
f01041e0:	6a 00                	push   $0x0
f01041e2:	e8 4f c4 ff ff       	call   f0100636 <iscons>
f01041e7:	89 c7                	mov    %eax,%edi
f01041e9:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01041ec:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01041f1:	e8 2f c4 ff ff       	call   f0100625 <getchar>
f01041f6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01041f8:	85 c0                	test   %eax,%eax
f01041fa:	79 18                	jns    f0104214 <readline+0x58>
			cprintf("read error: %e\n", c);
f01041fc:	83 ec 08             	sub    $0x8,%esp
f01041ff:	50                   	push   %eax
f0104200:	68 30 60 10 f0       	push   $0xf0106030
f0104205:	e8 3f ee ff ff       	call   f0103049 <cprintf>
			return NULL;
f010420a:	83 c4 10             	add    $0x10,%esp
f010420d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104212:	eb 79                	jmp    f010428d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104214:	83 f8 08             	cmp    $0x8,%eax
f0104217:	0f 94 c2             	sete   %dl
f010421a:	83 f8 7f             	cmp    $0x7f,%eax
f010421d:	0f 94 c0             	sete   %al
f0104220:	08 c2                	or     %al,%dl
f0104222:	74 1a                	je     f010423e <readline+0x82>
f0104224:	85 f6                	test   %esi,%esi
f0104226:	7e 16                	jle    f010423e <readline+0x82>
			if (echoing)
f0104228:	85 ff                	test   %edi,%edi
f010422a:	74 0d                	je     f0104239 <readline+0x7d>
				cputchar('\b');
f010422c:	83 ec 0c             	sub    $0xc,%esp
f010422f:	6a 08                	push   $0x8
f0104231:	e8 df c3 ff ff       	call   f0100615 <cputchar>
f0104236:	83 c4 10             	add    $0x10,%esp
			i--;
f0104239:	83 ee 01             	sub    $0x1,%esi
f010423c:	eb b3                	jmp    f01041f1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010423e:	83 fb 1f             	cmp    $0x1f,%ebx
f0104241:	7e 23                	jle    f0104266 <readline+0xaa>
f0104243:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104249:	7f 1b                	jg     f0104266 <readline+0xaa>
			if (echoing)
f010424b:	85 ff                	test   %edi,%edi
f010424d:	74 0c                	je     f010425b <readline+0x9f>
				cputchar(c);
f010424f:	83 ec 0c             	sub    $0xc,%esp
f0104252:	53                   	push   %ebx
f0104253:	e8 bd c3 ff ff       	call   f0100615 <cputchar>
f0104258:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010425b:	88 9e 40 28 17 f0    	mov    %bl,-0xfe8d7c0(%esi)
f0104261:	8d 76 01             	lea    0x1(%esi),%esi
f0104264:	eb 8b                	jmp    f01041f1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104266:	83 fb 0a             	cmp    $0xa,%ebx
f0104269:	74 05                	je     f0104270 <readline+0xb4>
f010426b:	83 fb 0d             	cmp    $0xd,%ebx
f010426e:	75 81                	jne    f01041f1 <readline+0x35>
			if (echoing)
f0104270:	85 ff                	test   %edi,%edi
f0104272:	74 0d                	je     f0104281 <readline+0xc5>
				cputchar('\n');
f0104274:	83 ec 0c             	sub    $0xc,%esp
f0104277:	6a 0a                	push   $0xa
f0104279:	e8 97 c3 ff ff       	call   f0100615 <cputchar>
f010427e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104281:	c6 86 40 28 17 f0 00 	movb   $0x0,-0xfe8d7c0(%esi)
			return buf;
f0104288:	b8 40 28 17 f0       	mov    $0xf0172840,%eax
		}
	}
}
f010428d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104290:	5b                   	pop    %ebx
f0104291:	5e                   	pop    %esi
f0104292:	5f                   	pop    %edi
f0104293:	5d                   	pop    %ebp
f0104294:	c3                   	ret    

f0104295 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104295:	55                   	push   %ebp
f0104296:	89 e5                	mov    %esp,%ebp
f0104298:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010429b:	b8 00 00 00 00       	mov    $0x0,%eax
f01042a0:	eb 03                	jmp    f01042a5 <strlen+0x10>
		n++;
f01042a2:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01042a5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01042a9:	75 f7                	jne    f01042a2 <strlen+0xd>
		n++;
	return n;
}
f01042ab:	5d                   	pop    %ebp
f01042ac:	c3                   	ret    

f01042ad <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01042ad:	55                   	push   %ebp
f01042ae:	89 e5                	mov    %esp,%ebp
f01042b0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042b3:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01042b6:	ba 00 00 00 00       	mov    $0x0,%edx
f01042bb:	eb 03                	jmp    f01042c0 <strnlen+0x13>
		n++;
f01042bd:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01042c0:	39 c2                	cmp    %eax,%edx
f01042c2:	74 08                	je     f01042cc <strnlen+0x1f>
f01042c4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01042c8:	75 f3                	jne    f01042bd <strnlen+0x10>
f01042ca:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01042cc:	5d                   	pop    %ebp
f01042cd:	c3                   	ret    

f01042ce <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01042ce:	55                   	push   %ebp
f01042cf:	89 e5                	mov    %esp,%ebp
f01042d1:	53                   	push   %ebx
f01042d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01042d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01042d8:	89 c2                	mov    %eax,%edx
f01042da:	83 c2 01             	add    $0x1,%edx
f01042dd:	83 c1 01             	add    $0x1,%ecx
f01042e0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01042e4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01042e7:	84 db                	test   %bl,%bl
f01042e9:	75 ef                	jne    f01042da <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01042eb:	5b                   	pop    %ebx
f01042ec:	5d                   	pop    %ebp
f01042ed:	c3                   	ret    

f01042ee <strcat>:

char *
strcat(char *dst, const char *src)
{
f01042ee:	55                   	push   %ebp
f01042ef:	89 e5                	mov    %esp,%ebp
f01042f1:	53                   	push   %ebx
f01042f2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01042f5:	53                   	push   %ebx
f01042f6:	e8 9a ff ff ff       	call   f0104295 <strlen>
f01042fb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01042fe:	ff 75 0c             	pushl  0xc(%ebp)
f0104301:	01 d8                	add    %ebx,%eax
f0104303:	50                   	push   %eax
f0104304:	e8 c5 ff ff ff       	call   f01042ce <strcpy>
	return dst;
}
f0104309:	89 d8                	mov    %ebx,%eax
f010430b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010430e:	c9                   	leave  
f010430f:	c3                   	ret    

f0104310 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104310:	55                   	push   %ebp
f0104311:	89 e5                	mov    %esp,%ebp
f0104313:	56                   	push   %esi
f0104314:	53                   	push   %ebx
f0104315:	8b 75 08             	mov    0x8(%ebp),%esi
f0104318:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010431b:	89 f3                	mov    %esi,%ebx
f010431d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104320:	89 f2                	mov    %esi,%edx
f0104322:	eb 0f                	jmp    f0104333 <strncpy+0x23>
		*dst++ = *src;
f0104324:	83 c2 01             	add    $0x1,%edx
f0104327:	0f b6 01             	movzbl (%ecx),%eax
f010432a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010432d:	80 39 01             	cmpb   $0x1,(%ecx)
f0104330:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104333:	39 da                	cmp    %ebx,%edx
f0104335:	75 ed                	jne    f0104324 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104337:	89 f0                	mov    %esi,%eax
f0104339:	5b                   	pop    %ebx
f010433a:	5e                   	pop    %esi
f010433b:	5d                   	pop    %ebp
f010433c:	c3                   	ret    

f010433d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010433d:	55                   	push   %ebp
f010433e:	89 e5                	mov    %esp,%ebp
f0104340:	56                   	push   %esi
f0104341:	53                   	push   %ebx
f0104342:	8b 75 08             	mov    0x8(%ebp),%esi
f0104345:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104348:	8b 55 10             	mov    0x10(%ebp),%edx
f010434b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010434d:	85 d2                	test   %edx,%edx
f010434f:	74 21                	je     f0104372 <strlcpy+0x35>
f0104351:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104355:	89 f2                	mov    %esi,%edx
f0104357:	eb 09                	jmp    f0104362 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104359:	83 c2 01             	add    $0x1,%edx
f010435c:	83 c1 01             	add    $0x1,%ecx
f010435f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104362:	39 c2                	cmp    %eax,%edx
f0104364:	74 09                	je     f010436f <strlcpy+0x32>
f0104366:	0f b6 19             	movzbl (%ecx),%ebx
f0104369:	84 db                	test   %bl,%bl
f010436b:	75 ec                	jne    f0104359 <strlcpy+0x1c>
f010436d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010436f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104372:	29 f0                	sub    %esi,%eax
}
f0104374:	5b                   	pop    %ebx
f0104375:	5e                   	pop    %esi
f0104376:	5d                   	pop    %ebp
f0104377:	c3                   	ret    

f0104378 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104378:	55                   	push   %ebp
f0104379:	89 e5                	mov    %esp,%ebp
f010437b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010437e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104381:	eb 06                	jmp    f0104389 <strcmp+0x11>
		p++, q++;
f0104383:	83 c1 01             	add    $0x1,%ecx
f0104386:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104389:	0f b6 01             	movzbl (%ecx),%eax
f010438c:	84 c0                	test   %al,%al
f010438e:	74 04                	je     f0104394 <strcmp+0x1c>
f0104390:	3a 02                	cmp    (%edx),%al
f0104392:	74 ef                	je     f0104383 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104394:	0f b6 c0             	movzbl %al,%eax
f0104397:	0f b6 12             	movzbl (%edx),%edx
f010439a:	29 d0                	sub    %edx,%eax
}
f010439c:	5d                   	pop    %ebp
f010439d:	c3                   	ret    

f010439e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010439e:	55                   	push   %ebp
f010439f:	89 e5                	mov    %esp,%ebp
f01043a1:	53                   	push   %ebx
f01043a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043a8:	89 c3                	mov    %eax,%ebx
f01043aa:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01043ad:	eb 06                	jmp    f01043b5 <strncmp+0x17>
		n--, p++, q++;
f01043af:	83 c0 01             	add    $0x1,%eax
f01043b2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01043b5:	39 d8                	cmp    %ebx,%eax
f01043b7:	74 15                	je     f01043ce <strncmp+0x30>
f01043b9:	0f b6 08             	movzbl (%eax),%ecx
f01043bc:	84 c9                	test   %cl,%cl
f01043be:	74 04                	je     f01043c4 <strncmp+0x26>
f01043c0:	3a 0a                	cmp    (%edx),%cl
f01043c2:	74 eb                	je     f01043af <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01043c4:	0f b6 00             	movzbl (%eax),%eax
f01043c7:	0f b6 12             	movzbl (%edx),%edx
f01043ca:	29 d0                	sub    %edx,%eax
f01043cc:	eb 05                	jmp    f01043d3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01043ce:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01043d3:	5b                   	pop    %ebx
f01043d4:	5d                   	pop    %ebp
f01043d5:	c3                   	ret    

f01043d6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01043d6:	55                   	push   %ebp
f01043d7:	89 e5                	mov    %esp,%ebp
f01043d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01043dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01043e0:	eb 07                	jmp    f01043e9 <strchr+0x13>
		if (*s == c)
f01043e2:	38 ca                	cmp    %cl,%dl
f01043e4:	74 0f                	je     f01043f5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01043e6:	83 c0 01             	add    $0x1,%eax
f01043e9:	0f b6 10             	movzbl (%eax),%edx
f01043ec:	84 d2                	test   %dl,%dl
f01043ee:	75 f2                	jne    f01043e2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01043f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043f5:	5d                   	pop    %ebp
f01043f6:	c3                   	ret    

f01043f7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01043f7:	55                   	push   %ebp
f01043f8:	89 e5                	mov    %esp,%ebp
f01043fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01043fd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104401:	eb 03                	jmp    f0104406 <strfind+0xf>
f0104403:	83 c0 01             	add    $0x1,%eax
f0104406:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104409:	38 ca                	cmp    %cl,%dl
f010440b:	74 04                	je     f0104411 <strfind+0x1a>
f010440d:	84 d2                	test   %dl,%dl
f010440f:	75 f2                	jne    f0104403 <strfind+0xc>
			break;
	return (char *) s;
}
f0104411:	5d                   	pop    %ebp
f0104412:	c3                   	ret    

f0104413 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104413:	55                   	push   %ebp
f0104414:	89 e5                	mov    %esp,%ebp
f0104416:	57                   	push   %edi
f0104417:	56                   	push   %esi
f0104418:	53                   	push   %ebx
f0104419:	8b 7d 08             	mov    0x8(%ebp),%edi
f010441c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010441f:	85 c9                	test   %ecx,%ecx
f0104421:	74 36                	je     f0104459 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104423:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104429:	75 28                	jne    f0104453 <memset+0x40>
f010442b:	f6 c1 03             	test   $0x3,%cl
f010442e:	75 23                	jne    f0104453 <memset+0x40>
		c &= 0xFF;
f0104430:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104434:	89 d3                	mov    %edx,%ebx
f0104436:	c1 e3 08             	shl    $0x8,%ebx
f0104439:	89 d6                	mov    %edx,%esi
f010443b:	c1 e6 18             	shl    $0x18,%esi
f010443e:	89 d0                	mov    %edx,%eax
f0104440:	c1 e0 10             	shl    $0x10,%eax
f0104443:	09 f0                	or     %esi,%eax
f0104445:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104447:	89 d8                	mov    %ebx,%eax
f0104449:	09 d0                	or     %edx,%eax
f010444b:	c1 e9 02             	shr    $0x2,%ecx
f010444e:	fc                   	cld    
f010444f:	f3 ab                	rep stos %eax,%es:(%edi)
f0104451:	eb 06                	jmp    f0104459 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104453:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104456:	fc                   	cld    
f0104457:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104459:	89 f8                	mov    %edi,%eax
f010445b:	5b                   	pop    %ebx
f010445c:	5e                   	pop    %esi
f010445d:	5f                   	pop    %edi
f010445e:	5d                   	pop    %ebp
f010445f:	c3                   	ret    

f0104460 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104460:	55                   	push   %ebp
f0104461:	89 e5                	mov    %esp,%ebp
f0104463:	57                   	push   %edi
f0104464:	56                   	push   %esi
f0104465:	8b 45 08             	mov    0x8(%ebp),%eax
f0104468:	8b 75 0c             	mov    0xc(%ebp),%esi
f010446b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010446e:	39 c6                	cmp    %eax,%esi
f0104470:	73 35                	jae    f01044a7 <memmove+0x47>
f0104472:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104475:	39 d0                	cmp    %edx,%eax
f0104477:	73 2e                	jae    f01044a7 <memmove+0x47>
		s += n;
		d += n;
f0104479:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010447c:	89 d6                	mov    %edx,%esi
f010447e:	09 fe                	or     %edi,%esi
f0104480:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104486:	75 13                	jne    f010449b <memmove+0x3b>
f0104488:	f6 c1 03             	test   $0x3,%cl
f010448b:	75 0e                	jne    f010449b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010448d:	83 ef 04             	sub    $0x4,%edi
f0104490:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104493:	c1 e9 02             	shr    $0x2,%ecx
f0104496:	fd                   	std    
f0104497:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104499:	eb 09                	jmp    f01044a4 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010449b:	83 ef 01             	sub    $0x1,%edi
f010449e:	8d 72 ff             	lea    -0x1(%edx),%esi
f01044a1:	fd                   	std    
f01044a2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01044a4:	fc                   	cld    
f01044a5:	eb 1d                	jmp    f01044c4 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01044a7:	89 f2                	mov    %esi,%edx
f01044a9:	09 c2                	or     %eax,%edx
f01044ab:	f6 c2 03             	test   $0x3,%dl
f01044ae:	75 0f                	jne    f01044bf <memmove+0x5f>
f01044b0:	f6 c1 03             	test   $0x3,%cl
f01044b3:	75 0a                	jne    f01044bf <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01044b5:	c1 e9 02             	shr    $0x2,%ecx
f01044b8:	89 c7                	mov    %eax,%edi
f01044ba:	fc                   	cld    
f01044bb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01044bd:	eb 05                	jmp    f01044c4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01044bf:	89 c7                	mov    %eax,%edi
f01044c1:	fc                   	cld    
f01044c2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01044c4:	5e                   	pop    %esi
f01044c5:	5f                   	pop    %edi
f01044c6:	5d                   	pop    %ebp
f01044c7:	c3                   	ret    

f01044c8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01044c8:	55                   	push   %ebp
f01044c9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01044cb:	ff 75 10             	pushl  0x10(%ebp)
f01044ce:	ff 75 0c             	pushl  0xc(%ebp)
f01044d1:	ff 75 08             	pushl  0x8(%ebp)
f01044d4:	e8 87 ff ff ff       	call   f0104460 <memmove>
}
f01044d9:	c9                   	leave  
f01044da:	c3                   	ret    

f01044db <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01044db:	55                   	push   %ebp
f01044dc:	89 e5                	mov    %esp,%ebp
f01044de:	56                   	push   %esi
f01044df:	53                   	push   %ebx
f01044e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01044e3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01044e6:	89 c6                	mov    %eax,%esi
f01044e8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01044eb:	eb 1a                	jmp    f0104507 <memcmp+0x2c>
		if (*s1 != *s2)
f01044ed:	0f b6 08             	movzbl (%eax),%ecx
f01044f0:	0f b6 1a             	movzbl (%edx),%ebx
f01044f3:	38 d9                	cmp    %bl,%cl
f01044f5:	74 0a                	je     f0104501 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01044f7:	0f b6 c1             	movzbl %cl,%eax
f01044fa:	0f b6 db             	movzbl %bl,%ebx
f01044fd:	29 d8                	sub    %ebx,%eax
f01044ff:	eb 0f                	jmp    f0104510 <memcmp+0x35>
		s1++, s2++;
f0104501:	83 c0 01             	add    $0x1,%eax
f0104504:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104507:	39 f0                	cmp    %esi,%eax
f0104509:	75 e2                	jne    f01044ed <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010450b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104510:	5b                   	pop    %ebx
f0104511:	5e                   	pop    %esi
f0104512:	5d                   	pop    %ebp
f0104513:	c3                   	ret    

f0104514 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104514:	55                   	push   %ebp
f0104515:	89 e5                	mov    %esp,%ebp
f0104517:	53                   	push   %ebx
f0104518:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010451b:	89 c1                	mov    %eax,%ecx
f010451d:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104520:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104524:	eb 0a                	jmp    f0104530 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104526:	0f b6 10             	movzbl (%eax),%edx
f0104529:	39 da                	cmp    %ebx,%edx
f010452b:	74 07                	je     f0104534 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010452d:	83 c0 01             	add    $0x1,%eax
f0104530:	39 c8                	cmp    %ecx,%eax
f0104532:	72 f2                	jb     f0104526 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104534:	5b                   	pop    %ebx
f0104535:	5d                   	pop    %ebp
f0104536:	c3                   	ret    

f0104537 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104537:	55                   	push   %ebp
f0104538:	89 e5                	mov    %esp,%ebp
f010453a:	57                   	push   %edi
f010453b:	56                   	push   %esi
f010453c:	53                   	push   %ebx
f010453d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104540:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104543:	eb 03                	jmp    f0104548 <strtol+0x11>
		s++;
f0104545:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104548:	0f b6 01             	movzbl (%ecx),%eax
f010454b:	3c 20                	cmp    $0x20,%al
f010454d:	74 f6                	je     f0104545 <strtol+0xe>
f010454f:	3c 09                	cmp    $0x9,%al
f0104551:	74 f2                	je     f0104545 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104553:	3c 2b                	cmp    $0x2b,%al
f0104555:	75 0a                	jne    f0104561 <strtol+0x2a>
		s++;
f0104557:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010455a:	bf 00 00 00 00       	mov    $0x0,%edi
f010455f:	eb 11                	jmp    f0104572 <strtol+0x3b>
f0104561:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104566:	3c 2d                	cmp    $0x2d,%al
f0104568:	75 08                	jne    f0104572 <strtol+0x3b>
		s++, neg = 1;
f010456a:	83 c1 01             	add    $0x1,%ecx
f010456d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104572:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104578:	75 15                	jne    f010458f <strtol+0x58>
f010457a:	80 39 30             	cmpb   $0x30,(%ecx)
f010457d:	75 10                	jne    f010458f <strtol+0x58>
f010457f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104583:	75 7c                	jne    f0104601 <strtol+0xca>
		s += 2, base = 16;
f0104585:	83 c1 02             	add    $0x2,%ecx
f0104588:	bb 10 00 00 00       	mov    $0x10,%ebx
f010458d:	eb 16                	jmp    f01045a5 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010458f:	85 db                	test   %ebx,%ebx
f0104591:	75 12                	jne    f01045a5 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104593:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104598:	80 39 30             	cmpb   $0x30,(%ecx)
f010459b:	75 08                	jne    f01045a5 <strtol+0x6e>
		s++, base = 8;
f010459d:	83 c1 01             	add    $0x1,%ecx
f01045a0:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01045a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01045aa:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01045ad:	0f b6 11             	movzbl (%ecx),%edx
f01045b0:	8d 72 d0             	lea    -0x30(%edx),%esi
f01045b3:	89 f3                	mov    %esi,%ebx
f01045b5:	80 fb 09             	cmp    $0x9,%bl
f01045b8:	77 08                	ja     f01045c2 <strtol+0x8b>
			dig = *s - '0';
f01045ba:	0f be d2             	movsbl %dl,%edx
f01045bd:	83 ea 30             	sub    $0x30,%edx
f01045c0:	eb 22                	jmp    f01045e4 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01045c2:	8d 72 9f             	lea    -0x61(%edx),%esi
f01045c5:	89 f3                	mov    %esi,%ebx
f01045c7:	80 fb 19             	cmp    $0x19,%bl
f01045ca:	77 08                	ja     f01045d4 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01045cc:	0f be d2             	movsbl %dl,%edx
f01045cf:	83 ea 57             	sub    $0x57,%edx
f01045d2:	eb 10                	jmp    f01045e4 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01045d4:	8d 72 bf             	lea    -0x41(%edx),%esi
f01045d7:	89 f3                	mov    %esi,%ebx
f01045d9:	80 fb 19             	cmp    $0x19,%bl
f01045dc:	77 16                	ja     f01045f4 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01045de:	0f be d2             	movsbl %dl,%edx
f01045e1:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01045e4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01045e7:	7d 0b                	jge    f01045f4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01045e9:	83 c1 01             	add    $0x1,%ecx
f01045ec:	0f af 45 10          	imul   0x10(%ebp),%eax
f01045f0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01045f2:	eb b9                	jmp    f01045ad <strtol+0x76>

	if (endptr)
f01045f4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01045f8:	74 0d                	je     f0104607 <strtol+0xd0>
		*endptr = (char *) s;
f01045fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01045fd:	89 0e                	mov    %ecx,(%esi)
f01045ff:	eb 06                	jmp    f0104607 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104601:	85 db                	test   %ebx,%ebx
f0104603:	74 98                	je     f010459d <strtol+0x66>
f0104605:	eb 9e                	jmp    f01045a5 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104607:	89 c2                	mov    %eax,%edx
f0104609:	f7 da                	neg    %edx
f010460b:	85 ff                	test   %edi,%edi
f010460d:	0f 45 c2             	cmovne %edx,%eax
}
f0104610:	5b                   	pop    %ebx
f0104611:	5e                   	pop    %esi
f0104612:	5f                   	pop    %edi
f0104613:	5d                   	pop    %ebp
f0104614:	c3                   	ret    
f0104615:	66 90                	xchg   %ax,%ax
f0104617:	66 90                	xchg   %ax,%ax
f0104619:	66 90                	xchg   %ax,%ax
f010461b:	66 90                	xchg   %ax,%ax
f010461d:	66 90                	xchg   %ax,%ax
f010461f:	90                   	nop

f0104620 <__udivdi3>:
f0104620:	55                   	push   %ebp
f0104621:	57                   	push   %edi
f0104622:	56                   	push   %esi
f0104623:	53                   	push   %ebx
f0104624:	83 ec 1c             	sub    $0x1c,%esp
f0104627:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010462b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010462f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104633:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104637:	85 f6                	test   %esi,%esi
f0104639:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010463d:	89 ca                	mov    %ecx,%edx
f010463f:	89 f8                	mov    %edi,%eax
f0104641:	75 3d                	jne    f0104680 <__udivdi3+0x60>
f0104643:	39 cf                	cmp    %ecx,%edi
f0104645:	0f 87 c5 00 00 00    	ja     f0104710 <__udivdi3+0xf0>
f010464b:	85 ff                	test   %edi,%edi
f010464d:	89 fd                	mov    %edi,%ebp
f010464f:	75 0b                	jne    f010465c <__udivdi3+0x3c>
f0104651:	b8 01 00 00 00       	mov    $0x1,%eax
f0104656:	31 d2                	xor    %edx,%edx
f0104658:	f7 f7                	div    %edi
f010465a:	89 c5                	mov    %eax,%ebp
f010465c:	89 c8                	mov    %ecx,%eax
f010465e:	31 d2                	xor    %edx,%edx
f0104660:	f7 f5                	div    %ebp
f0104662:	89 c1                	mov    %eax,%ecx
f0104664:	89 d8                	mov    %ebx,%eax
f0104666:	89 cf                	mov    %ecx,%edi
f0104668:	f7 f5                	div    %ebp
f010466a:	89 c3                	mov    %eax,%ebx
f010466c:	89 d8                	mov    %ebx,%eax
f010466e:	89 fa                	mov    %edi,%edx
f0104670:	83 c4 1c             	add    $0x1c,%esp
f0104673:	5b                   	pop    %ebx
f0104674:	5e                   	pop    %esi
f0104675:	5f                   	pop    %edi
f0104676:	5d                   	pop    %ebp
f0104677:	c3                   	ret    
f0104678:	90                   	nop
f0104679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104680:	39 ce                	cmp    %ecx,%esi
f0104682:	77 74                	ja     f01046f8 <__udivdi3+0xd8>
f0104684:	0f bd fe             	bsr    %esi,%edi
f0104687:	83 f7 1f             	xor    $0x1f,%edi
f010468a:	0f 84 98 00 00 00    	je     f0104728 <__udivdi3+0x108>
f0104690:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104695:	89 f9                	mov    %edi,%ecx
f0104697:	89 c5                	mov    %eax,%ebp
f0104699:	29 fb                	sub    %edi,%ebx
f010469b:	d3 e6                	shl    %cl,%esi
f010469d:	89 d9                	mov    %ebx,%ecx
f010469f:	d3 ed                	shr    %cl,%ebp
f01046a1:	89 f9                	mov    %edi,%ecx
f01046a3:	d3 e0                	shl    %cl,%eax
f01046a5:	09 ee                	or     %ebp,%esi
f01046a7:	89 d9                	mov    %ebx,%ecx
f01046a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046ad:	89 d5                	mov    %edx,%ebp
f01046af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046b3:	d3 ed                	shr    %cl,%ebp
f01046b5:	89 f9                	mov    %edi,%ecx
f01046b7:	d3 e2                	shl    %cl,%edx
f01046b9:	89 d9                	mov    %ebx,%ecx
f01046bb:	d3 e8                	shr    %cl,%eax
f01046bd:	09 c2                	or     %eax,%edx
f01046bf:	89 d0                	mov    %edx,%eax
f01046c1:	89 ea                	mov    %ebp,%edx
f01046c3:	f7 f6                	div    %esi
f01046c5:	89 d5                	mov    %edx,%ebp
f01046c7:	89 c3                	mov    %eax,%ebx
f01046c9:	f7 64 24 0c          	mull   0xc(%esp)
f01046cd:	39 d5                	cmp    %edx,%ebp
f01046cf:	72 10                	jb     f01046e1 <__udivdi3+0xc1>
f01046d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01046d5:	89 f9                	mov    %edi,%ecx
f01046d7:	d3 e6                	shl    %cl,%esi
f01046d9:	39 c6                	cmp    %eax,%esi
f01046db:	73 07                	jae    f01046e4 <__udivdi3+0xc4>
f01046dd:	39 d5                	cmp    %edx,%ebp
f01046df:	75 03                	jne    f01046e4 <__udivdi3+0xc4>
f01046e1:	83 eb 01             	sub    $0x1,%ebx
f01046e4:	31 ff                	xor    %edi,%edi
f01046e6:	89 d8                	mov    %ebx,%eax
f01046e8:	89 fa                	mov    %edi,%edx
f01046ea:	83 c4 1c             	add    $0x1c,%esp
f01046ed:	5b                   	pop    %ebx
f01046ee:	5e                   	pop    %esi
f01046ef:	5f                   	pop    %edi
f01046f0:	5d                   	pop    %ebp
f01046f1:	c3                   	ret    
f01046f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046f8:	31 ff                	xor    %edi,%edi
f01046fa:	31 db                	xor    %ebx,%ebx
f01046fc:	89 d8                	mov    %ebx,%eax
f01046fe:	89 fa                	mov    %edi,%edx
f0104700:	83 c4 1c             	add    $0x1c,%esp
f0104703:	5b                   	pop    %ebx
f0104704:	5e                   	pop    %esi
f0104705:	5f                   	pop    %edi
f0104706:	5d                   	pop    %ebp
f0104707:	c3                   	ret    
f0104708:	90                   	nop
f0104709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104710:	89 d8                	mov    %ebx,%eax
f0104712:	f7 f7                	div    %edi
f0104714:	31 ff                	xor    %edi,%edi
f0104716:	89 c3                	mov    %eax,%ebx
f0104718:	89 d8                	mov    %ebx,%eax
f010471a:	89 fa                	mov    %edi,%edx
f010471c:	83 c4 1c             	add    $0x1c,%esp
f010471f:	5b                   	pop    %ebx
f0104720:	5e                   	pop    %esi
f0104721:	5f                   	pop    %edi
f0104722:	5d                   	pop    %ebp
f0104723:	c3                   	ret    
f0104724:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104728:	39 ce                	cmp    %ecx,%esi
f010472a:	72 0c                	jb     f0104738 <__udivdi3+0x118>
f010472c:	31 db                	xor    %ebx,%ebx
f010472e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104732:	0f 87 34 ff ff ff    	ja     f010466c <__udivdi3+0x4c>
f0104738:	bb 01 00 00 00       	mov    $0x1,%ebx
f010473d:	e9 2a ff ff ff       	jmp    f010466c <__udivdi3+0x4c>
f0104742:	66 90                	xchg   %ax,%ax
f0104744:	66 90                	xchg   %ax,%ax
f0104746:	66 90                	xchg   %ax,%ax
f0104748:	66 90                	xchg   %ax,%ax
f010474a:	66 90                	xchg   %ax,%ax
f010474c:	66 90                	xchg   %ax,%ax
f010474e:	66 90                	xchg   %ax,%ax

f0104750 <__umoddi3>:
f0104750:	55                   	push   %ebp
f0104751:	57                   	push   %edi
f0104752:	56                   	push   %esi
f0104753:	53                   	push   %ebx
f0104754:	83 ec 1c             	sub    $0x1c,%esp
f0104757:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010475b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010475f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104763:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104767:	85 d2                	test   %edx,%edx
f0104769:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010476d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104771:	89 f3                	mov    %esi,%ebx
f0104773:	89 3c 24             	mov    %edi,(%esp)
f0104776:	89 74 24 04          	mov    %esi,0x4(%esp)
f010477a:	75 1c                	jne    f0104798 <__umoddi3+0x48>
f010477c:	39 f7                	cmp    %esi,%edi
f010477e:	76 50                	jbe    f01047d0 <__umoddi3+0x80>
f0104780:	89 c8                	mov    %ecx,%eax
f0104782:	89 f2                	mov    %esi,%edx
f0104784:	f7 f7                	div    %edi
f0104786:	89 d0                	mov    %edx,%eax
f0104788:	31 d2                	xor    %edx,%edx
f010478a:	83 c4 1c             	add    $0x1c,%esp
f010478d:	5b                   	pop    %ebx
f010478e:	5e                   	pop    %esi
f010478f:	5f                   	pop    %edi
f0104790:	5d                   	pop    %ebp
f0104791:	c3                   	ret    
f0104792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104798:	39 f2                	cmp    %esi,%edx
f010479a:	89 d0                	mov    %edx,%eax
f010479c:	77 52                	ja     f01047f0 <__umoddi3+0xa0>
f010479e:	0f bd ea             	bsr    %edx,%ebp
f01047a1:	83 f5 1f             	xor    $0x1f,%ebp
f01047a4:	75 5a                	jne    f0104800 <__umoddi3+0xb0>
f01047a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01047aa:	0f 82 e0 00 00 00    	jb     f0104890 <__umoddi3+0x140>
f01047b0:	39 0c 24             	cmp    %ecx,(%esp)
f01047b3:	0f 86 d7 00 00 00    	jbe    f0104890 <__umoddi3+0x140>
f01047b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01047bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01047c1:	83 c4 1c             	add    $0x1c,%esp
f01047c4:	5b                   	pop    %ebx
f01047c5:	5e                   	pop    %esi
f01047c6:	5f                   	pop    %edi
f01047c7:	5d                   	pop    %ebp
f01047c8:	c3                   	ret    
f01047c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01047d0:	85 ff                	test   %edi,%edi
f01047d2:	89 fd                	mov    %edi,%ebp
f01047d4:	75 0b                	jne    f01047e1 <__umoddi3+0x91>
f01047d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01047db:	31 d2                	xor    %edx,%edx
f01047dd:	f7 f7                	div    %edi
f01047df:	89 c5                	mov    %eax,%ebp
f01047e1:	89 f0                	mov    %esi,%eax
f01047e3:	31 d2                	xor    %edx,%edx
f01047e5:	f7 f5                	div    %ebp
f01047e7:	89 c8                	mov    %ecx,%eax
f01047e9:	f7 f5                	div    %ebp
f01047eb:	89 d0                	mov    %edx,%eax
f01047ed:	eb 99                	jmp    f0104788 <__umoddi3+0x38>
f01047ef:	90                   	nop
f01047f0:	89 c8                	mov    %ecx,%eax
f01047f2:	89 f2                	mov    %esi,%edx
f01047f4:	83 c4 1c             	add    $0x1c,%esp
f01047f7:	5b                   	pop    %ebx
f01047f8:	5e                   	pop    %esi
f01047f9:	5f                   	pop    %edi
f01047fa:	5d                   	pop    %ebp
f01047fb:	c3                   	ret    
f01047fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104800:	8b 34 24             	mov    (%esp),%esi
f0104803:	bf 20 00 00 00       	mov    $0x20,%edi
f0104808:	89 e9                	mov    %ebp,%ecx
f010480a:	29 ef                	sub    %ebp,%edi
f010480c:	d3 e0                	shl    %cl,%eax
f010480e:	89 f9                	mov    %edi,%ecx
f0104810:	89 f2                	mov    %esi,%edx
f0104812:	d3 ea                	shr    %cl,%edx
f0104814:	89 e9                	mov    %ebp,%ecx
f0104816:	09 c2                	or     %eax,%edx
f0104818:	89 d8                	mov    %ebx,%eax
f010481a:	89 14 24             	mov    %edx,(%esp)
f010481d:	89 f2                	mov    %esi,%edx
f010481f:	d3 e2                	shl    %cl,%edx
f0104821:	89 f9                	mov    %edi,%ecx
f0104823:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104827:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010482b:	d3 e8                	shr    %cl,%eax
f010482d:	89 e9                	mov    %ebp,%ecx
f010482f:	89 c6                	mov    %eax,%esi
f0104831:	d3 e3                	shl    %cl,%ebx
f0104833:	89 f9                	mov    %edi,%ecx
f0104835:	89 d0                	mov    %edx,%eax
f0104837:	d3 e8                	shr    %cl,%eax
f0104839:	89 e9                	mov    %ebp,%ecx
f010483b:	09 d8                	or     %ebx,%eax
f010483d:	89 d3                	mov    %edx,%ebx
f010483f:	89 f2                	mov    %esi,%edx
f0104841:	f7 34 24             	divl   (%esp)
f0104844:	89 d6                	mov    %edx,%esi
f0104846:	d3 e3                	shl    %cl,%ebx
f0104848:	f7 64 24 04          	mull   0x4(%esp)
f010484c:	39 d6                	cmp    %edx,%esi
f010484e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104852:	89 d1                	mov    %edx,%ecx
f0104854:	89 c3                	mov    %eax,%ebx
f0104856:	72 08                	jb     f0104860 <__umoddi3+0x110>
f0104858:	75 11                	jne    f010486b <__umoddi3+0x11b>
f010485a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010485e:	73 0b                	jae    f010486b <__umoddi3+0x11b>
f0104860:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104864:	1b 14 24             	sbb    (%esp),%edx
f0104867:	89 d1                	mov    %edx,%ecx
f0104869:	89 c3                	mov    %eax,%ebx
f010486b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010486f:	29 da                	sub    %ebx,%edx
f0104871:	19 ce                	sbb    %ecx,%esi
f0104873:	89 f9                	mov    %edi,%ecx
f0104875:	89 f0                	mov    %esi,%eax
f0104877:	d3 e0                	shl    %cl,%eax
f0104879:	89 e9                	mov    %ebp,%ecx
f010487b:	d3 ea                	shr    %cl,%edx
f010487d:	89 e9                	mov    %ebp,%ecx
f010487f:	d3 ee                	shr    %cl,%esi
f0104881:	09 d0                	or     %edx,%eax
f0104883:	89 f2                	mov    %esi,%edx
f0104885:	83 c4 1c             	add    $0x1c,%esp
f0104888:	5b                   	pop    %ebx
f0104889:	5e                   	pop    %esi
f010488a:	5f                   	pop    %edi
f010488b:	5d                   	pop    %ebp
f010488c:	c3                   	ret    
f010488d:	8d 76 00             	lea    0x0(%esi),%esi
f0104890:	29 f9                	sub    %edi,%ecx
f0104892:	19 d6                	sbb    %edx,%esi
f0104894:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104898:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010489c:	e9 18 ff ff ff       	jmp    f01047b9 <__umoddi3+0x69>
