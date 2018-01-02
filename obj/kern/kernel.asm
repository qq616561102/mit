
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 5a 32 00 00       	call   f01032b7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 37 10 f0       	push   $0xf0103760
f010006f:	e8 8a 27 00 00       	call   f01027fe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 7e 10 00 00       	call   f01010f7 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 43 07 00 00       	call   f01007c9 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 37 10 f0       	push   $0xf010377b
f01000b5:	e8 44 27 00 00       	call   f01027fe <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 14 27 00 00       	call   f01027d8 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 07 45 10 f0 	movl   $0xf0104507,(%esp)
f01000cb:	e8 2e 27 00 00       	call   f01027fe <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 ec 06 00 00       	call   f01007c9 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 37 10 f0       	push   $0xf0103793
f01000f7:	e8 02 27 00 00       	call   f01027fe <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 d0 26 00 00       	call   f01027d8 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 07 45 10 f0 	movl   $0xf0104507,(%esp)
f010010f:	e8 ea 26 00 00       	call   f01027fe <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 00 38 10 f0 	movzbl -0xfefc800(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d e0 37 10 f0 	mov    -0xfefc820(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ad 37 10 f0       	push   $0xf01037ad
f010026d:	e8 8c 25 00 00       	call   f01027fe <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 e3 2e 00 00       	call   f0103304 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 b9 37 10 f0       	push   $0xf01037b9
f01005f0:	e8 09 22 00 00       	call   f01027fe <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 00 3a 10 f0       	push   $0xf0103a00
f0100636:	68 1e 3a 10 f0       	push   $0xf0103a1e
f010063b:	68 23 3a 10 f0       	push   $0xf0103a23
f0100640:	e8 b9 21 00 00       	call   f01027fe <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 ec 3a 10 f0       	push   $0xf0103aec
f010064d:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100652:	68 23 3a 10 f0       	push   $0xf0103a23
f0100657:	e8 a2 21 00 00       	call   f01027fe <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 35 3a 10 f0       	push   $0xf0103a35
f0100664:	68 4c 3a 10 f0       	push   $0xf0103a4c
f0100669:	68 23 3a 10 f0       	push   $0xf0103a23
f010066e:	e8 8b 21 00 00       	call   f01027fe <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 56 3a 10 f0       	push   $0xf0103a56
f0100685:	e8 74 21 00 00       	call   f01027fe <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 14 3b 10 f0       	push   $0xf0103b14
f0100697:	e8 62 21 00 00       	call   f01027fe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 3c 3b 10 f0       	push   $0xf0103b3c
f01006ae:	e8 4b 21 00 00       	call   f01027fe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 41 37 10 00       	push   $0x103741
f01006bb:	68 41 37 10 f0       	push   $0xf0103741
f01006c0:	68 60 3b 10 f0       	push   $0xf0103b60
f01006c5:	e8 34 21 00 00       	call   f01027fe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 84 3b 10 f0       	push   $0xf0103b84
f01006dc:	e8 1d 21 00 00       	call   f01027fe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 70 79 11 00       	push   $0x117970
f01006e9:	68 70 79 11 f0       	push   $0xf0117970
f01006ee:	68 a8 3b 10 f0       	push   $0xf0103ba8
f01006f3:	e8 06 21 00 00       	call   f01027fe <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 cc 3b 10 f0       	push   $0xf0103bcc
f010071e:	e8 db 20 00 00       	call   f01027fe <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 ee                	mov    %ebp,%esi
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
f0100735:	68 6f 3a 10 f0       	push   $0xf0103a6f
f010073a:	e8 bf 20 00 00       	call   f01027fe <cprintf>
    while (ebp) {
f010073f:	83 c4 10             	add    $0x10,%esp
f0100742:	eb 74                	jmp    f01007b8 <mon_backtrace+0x8e>
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
f0100744:	83 ec 04             	sub    $0x4,%esp
f0100747:	ff 76 04             	pushl  0x4(%esi)
f010074a:	56                   	push   %esi
f010074b:	68 81 3a 10 f0       	push   $0xf0103a81
f0100750:	e8 a9 20 00 00       	call   f01027fe <cprintf>
f0100755:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100758:	8d 7e 1c             	lea    0x1c(%esi),%edi
f010075b:	83 c4 10             	add    $0x10,%esp
        for (int j = 2; j != 7; ++j) {
            cprintf(" %08x", ebp[j]);  
f010075e:	83 ec 08             	sub    $0x8,%esp
f0100761:	ff 33                	pushl  (%ebx)
f0100763:	68 9a 3a 10 f0       	push   $0xf0103a9a
f0100768:	e8 91 20 00 00       	call   f01027fe <cprintf>
f010076d:	83 c3 04             	add    $0x4,%ebx
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
        for (int j = 2; j != 7; ++j) {
f0100770:	83 c4 10             	add    $0x10,%esp
f0100773:	39 fb                	cmp    %edi,%ebx
f0100775:	75 e7                	jne    f010075e <mon_backtrace+0x34>
            cprintf(" %08x", ebp[j]);  
        }
        cprintf("\n");
f0100777:	83 ec 0c             	sub    $0xc,%esp
f010077a:	68 07 45 10 f0       	push   $0xf0104507
f010077f:	e8 7a 20 00 00       	call   f01027fe <cprintf>
        debuginfo_eip(ebp[1],&info);
f0100784:	83 c4 08             	add    $0x8,%esp
f0100787:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010078a:	50                   	push   %eax
f010078b:	ff 76 04             	pushl  0x4(%esi)
f010078e:	e8 75 21 00 00       	call   f0102908 <debuginfo_eip>
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
f0100793:	83 c4 08             	add    $0x8,%esp
f0100796:	8b 46 04             	mov    0x4(%esi),%eax
f0100799:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010079c:	50                   	push   %eax
f010079d:	ff 75 d8             	pushl  -0x28(%ebp)
f01007a0:	ff 75 dc             	pushl  -0x24(%ebp)
f01007a3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007a6:	ff 75 d0             	pushl  -0x30(%ebp)
f01007a9:	68 a0 3a 10 f0       	push   $0xf0103aa0
f01007ae:	e8 4b 20 00 00       	call   f01027fe <cprintf>
        ebp = (uint32_t *) (*ebp);
f01007b3:	8b 36                	mov    (%esi),%esi
f01007b5:	83 c4 20             	add    $0x20,%esp
{
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
f01007b8:	85 f6                	test   %esi,%esi
f01007ba:	75 88                	jne    f0100744 <mon_backtrace+0x1a>
        debuginfo_eip(ebp[1],&info);
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
        ebp = (uint32_t *) (*ebp);
    }
       return 0;
}
f01007bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007c4:	5b                   	pop    %ebx
f01007c5:	5e                   	pop    %esi
f01007c6:	5f                   	pop    %edi
f01007c7:	5d                   	pop    %ebp
f01007c8:	c3                   	ret    

f01007c9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c9:	55                   	push   %ebp
f01007ca:	89 e5                	mov    %esp,%ebp
f01007cc:	57                   	push   %edi
f01007cd:	56                   	push   %esi
f01007ce:	53                   	push   %ebx
f01007cf:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d2:	68 f8 3b 10 f0       	push   $0xf0103bf8
f01007d7:	e8 22 20 00 00       	call   f01027fe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007dc:	c7 04 24 1c 3c 10 f0 	movl   $0xf0103c1c,(%esp)
f01007e3:	e8 16 20 00 00       	call   f01027fe <cprintf>
f01007e8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007eb:	83 ec 0c             	sub    $0xc,%esp
f01007ee:	68 b0 3a 10 f0       	push   $0xf0103ab0
f01007f3:	e8 68 28 00 00       	call   f0103060 <readline>
f01007f8:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007fa:	83 c4 10             	add    $0x10,%esp
f01007fd:	85 c0                	test   %eax,%eax
f01007ff:	74 ea                	je     f01007eb <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100801:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100808:	be 00 00 00 00       	mov    $0x0,%esi
f010080d:	eb 0a                	jmp    f0100819 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010080f:	c6 03 00             	movb   $0x0,(%ebx)
f0100812:	89 f7                	mov    %esi,%edi
f0100814:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100817:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100819:	0f b6 03             	movzbl (%ebx),%eax
f010081c:	84 c0                	test   %al,%al
f010081e:	74 63                	je     f0100883 <monitor+0xba>
f0100820:	83 ec 08             	sub    $0x8,%esp
f0100823:	0f be c0             	movsbl %al,%eax
f0100826:	50                   	push   %eax
f0100827:	68 b4 3a 10 f0       	push   $0xf0103ab4
f010082c:	e8 49 2a 00 00       	call   f010327a <strchr>
f0100831:	83 c4 10             	add    $0x10,%esp
f0100834:	85 c0                	test   %eax,%eax
f0100836:	75 d7                	jne    f010080f <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100838:	80 3b 00             	cmpb   $0x0,(%ebx)
f010083b:	74 46                	je     f0100883 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010083d:	83 fe 0f             	cmp    $0xf,%esi
f0100840:	75 14                	jne    f0100856 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100842:	83 ec 08             	sub    $0x8,%esp
f0100845:	6a 10                	push   $0x10
f0100847:	68 b9 3a 10 f0       	push   $0xf0103ab9
f010084c:	e8 ad 1f 00 00       	call   f01027fe <cprintf>
f0100851:	83 c4 10             	add    $0x10,%esp
f0100854:	eb 95                	jmp    f01007eb <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100856:	8d 7e 01             	lea    0x1(%esi),%edi
f0100859:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010085d:	eb 03                	jmp    f0100862 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010085f:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100862:	0f b6 03             	movzbl (%ebx),%eax
f0100865:	84 c0                	test   %al,%al
f0100867:	74 ae                	je     f0100817 <monitor+0x4e>
f0100869:	83 ec 08             	sub    $0x8,%esp
f010086c:	0f be c0             	movsbl %al,%eax
f010086f:	50                   	push   %eax
f0100870:	68 b4 3a 10 f0       	push   $0xf0103ab4
f0100875:	e8 00 2a 00 00       	call   f010327a <strchr>
f010087a:	83 c4 10             	add    $0x10,%esp
f010087d:	85 c0                	test   %eax,%eax
f010087f:	74 de                	je     f010085f <monitor+0x96>
f0100881:	eb 94                	jmp    f0100817 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100883:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010088a:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010088b:	85 f6                	test   %esi,%esi
f010088d:	0f 84 58 ff ff ff    	je     f01007eb <monitor+0x22>
f0100893:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100898:	83 ec 08             	sub    $0x8,%esp
f010089b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010089e:	ff 34 85 60 3c 10 f0 	pushl  -0xfefc3a0(,%eax,4)
f01008a5:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a8:	e8 6f 29 00 00       	call   f010321c <strcmp>
f01008ad:	83 c4 10             	add    $0x10,%esp
f01008b0:	85 c0                	test   %eax,%eax
f01008b2:	75 21                	jne    f01008d5 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008b4:	83 ec 04             	sub    $0x4,%esp
f01008b7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ba:	ff 75 08             	pushl  0x8(%ebp)
f01008bd:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008c0:	52                   	push   %edx
f01008c1:	56                   	push   %esi
f01008c2:	ff 14 85 68 3c 10 f0 	call   *-0xfefc398(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c9:	83 c4 10             	add    $0x10,%esp
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	78 25                	js     f01008f5 <monitor+0x12c>
f01008d0:	e9 16 ff ff ff       	jmp    f01007eb <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008d5:	83 c3 01             	add    $0x1,%ebx
f01008d8:	83 fb 03             	cmp    $0x3,%ebx
f01008db:	75 bb                	jne    f0100898 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008dd:	83 ec 08             	sub    $0x8,%esp
f01008e0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e3:	68 d6 3a 10 f0       	push   $0xf0103ad6
f01008e8:	e8 11 1f 00 00       	call   f01027fe <cprintf>
f01008ed:	83 c4 10             	add    $0x10,%esp
f01008f0:	e9 f6 fe ff ff       	jmp    f01007eb <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f8:	5b                   	pop    %ebx
f01008f9:	5e                   	pop    %esi
f01008fa:	5f                   	pop    %edi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <boot_alloc>:

static void *

boot_alloc(uint32_t n)

{
f01008fd:	55                   	push   %ebp
f01008fe:	89 e5                	mov    %esp,%ebp
f0100900:	89 c2                	mov    %eax,%edx

	// the first virtual address that the linker did *not* assign

	// to any kernel code or global variables.

	if (!nextfree) {
f0100902:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100909:	75 0f                	jne    f010091a <boot_alloc+0x1d>

		extern char end[];

		nextfree = (char *)ROUNDUP((char *) end, PGSIZE);
f010090b:	b8 6f 89 11 f0       	mov    $0xf011896f,%eax
f0100910:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100915:	a3 38 75 11 f0       	mov    %eax,0xf0117538

	// LAB 2: Your code here.



    result = nextfree;
f010091a:	a1 38 75 11 f0       	mov    0xf0117538,%eax

    nextfree += ROUNDUP(n, PGSIZE);
f010091f:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100925:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010092b:	01 c2                	add    %eax,%edx
f010092d:	89 15 38 75 11 f0    	mov    %edx,0xf0117538



	return result;

}
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    

f0100935 <check_va2pa>:



	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
f0100935:	89 d1                	mov    %edx,%ecx
f0100937:	c1 e9 16             	shr    $0x16,%ecx
f010093a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010093d:	a8 01                	test   $0x1,%al
f010093f:	74 52                	je     f0100993 <check_va2pa+0x5e>

		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100941:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100946:	89 c1                	mov    %eax,%ecx
f0100948:	c1 e9 0c             	shr    $0xc,%ecx
f010094b:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100951:	72 1b                	jb     f010096e <check_va2pa+0x39>

static physaddr_t

check_va2pa(pde_t *pgdir, uintptr_t va)

{
f0100953:	55                   	push   %ebp
f0100954:	89 e5                	mov    %esp,%ebp
f0100956:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100959:	50                   	push   %eax
f010095a:	68 84 3c 10 f0       	push   $0xf0103c84
f010095f:	68 4f 06 00 00       	push   $0x64f
f0100964:	68 34 44 10 f0       	push   $0xf0104434
f0100969:	e8 1d f7 ff ff       	call   f010008b <_panic>

		return ~0;

	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));

	if (!(p[PTX(va)] & PTE_P))
f010096e:	c1 ea 0c             	shr    $0xc,%edx
f0100971:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100977:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010097e:	89 c2                	mov    %eax,%edx
f0100980:	83 e2 01             	and    $0x1,%edx

		return ~0;

	return PTE_ADDR(p[PTX(va)]);
f0100983:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100988:	85 d2                	test   %edx,%edx
f010098a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010098f:	0f 44 c2             	cmove  %edx,%eax
f0100992:	c3                   	ret    

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))

		return ~0;
f0100993:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

		return ~0;

	return PTE_ADDR(p[PTX(va)]);

}
f0100998:	c3                   	ret    

f0100999 <check_page_free_list>:

static void

check_page_free_list(bool only_low_memory)

{
f0100999:	55                   	push   %ebp
f010099a:	89 e5                	mov    %esp,%ebp
f010099c:	57                   	push   %edi
f010099d:	56                   	push   %esi
f010099e:	53                   	push   %ebx
f010099f:	83 ec 2c             	sub    $0x2c,%esp

	struct PageInfo *pp;

	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009a2:	84 c0                	test   %al,%al
f01009a4:	0f 85 72 02 00 00    	jne    f0100c1c <check_page_free_list+0x283>
f01009aa:	e9 7f 02 00 00       	jmp    f0100c2e <check_page_free_list+0x295>



	if (!page_free_list)

		panic("'page_free_list' is a null pointer!");
f01009af:	83 ec 04             	sub    $0x4,%esp
f01009b2:	68 a8 3c 10 f0       	push   $0xf0103ca8
f01009b7:	68 d5 04 00 00       	push   $0x4d5
f01009bc:	68 34 44 10 f0       	push   $0xf0104434
f01009c1:	e8 c5 f6 ff ff       	call   f010008b <_panic>

		// list, since entry_pgdir does not map all pages.

		struct PageInfo *pp1, *pp2;

		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009c6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009c9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009cc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009cf:	89 55 e4             	mov    %edx,-0x1c(%ebp)

		for (pp = page_free_list; pp; pp = pp->pp_link) {

			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009d2:	89 c2                	mov    %eax,%edx
f01009d4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01009da:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009e0:	0f 95 c2             	setne  %dl
f01009e3:	0f b6 d2             	movzbl %dl,%edx

			*tp[pagetype] = pp;
f01009e6:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009ea:	89 01                	mov    %eax,(%ecx)

			tp[pagetype] = &pp->pp_link;
f01009ec:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)

		struct PageInfo *pp1, *pp2;

		struct PageInfo **tp[2] = { &pp1, &pp2 };

		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009f0:	8b 00                	mov    (%eax),%eax
f01009f2:	85 c0                	test   %eax,%eax
f01009f4:	75 dc                	jne    f01009d2 <check_page_free_list+0x39>

			tp[pagetype] = &pp->pp_link;

		}

		*tp[1] = 0;
f01009f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

		*tp[0] = pp2;
f01009ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a02:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a05:	89 10                	mov    %edx,(%eax)

		page_free_list = pp1;
f0100a07:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a0a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

{

	struct PageInfo *pp;

	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a0f:	be 01 00 00 00       	mov    $0x1,%esi

	// if there's a page that shouldn't be on the free list,

	// try to make sure it eventually causes trouble.

	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a14:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a1a:	eb 53                	jmp    f0100a6f <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a1c:	89 d8                	mov    %ebx,%eax
f0100a1e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a24:	c1 f8 03             	sar    $0x3,%eax
f0100a27:	c1 e0 0c             	shl    $0xc,%eax

		if (PDX(page2pa(pp)) < pdx_limit)
f0100a2a:	89 c2                	mov    %eax,%edx
f0100a2c:	c1 ea 16             	shr    $0x16,%edx
f0100a2f:	39 f2                	cmp    %esi,%edx
f0100a31:	73 3a                	jae    f0100a6d <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a33:	89 c2                	mov    %eax,%edx
f0100a35:	c1 ea 0c             	shr    $0xc,%edx
f0100a38:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a3e:	72 12                	jb     f0100a52 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a40:	50                   	push   %eax
f0100a41:	68 84 3c 10 f0       	push   $0xf0103c84
f0100a46:	6a 52                	push   $0x52
f0100a48:	68 40 44 10 f0       	push   $0xf0104440
f0100a4d:	e8 39 f6 ff ff       	call   f010008b <_panic>

			memset(page2kva(pp), 0x97, 128);
f0100a52:	83 ec 04             	sub    $0x4,%esp
f0100a55:	68 80 00 00 00       	push   $0x80
f0100a5a:	68 97 00 00 00       	push   $0x97
f0100a5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a64:	50                   	push   %eax
f0100a65:	e8 4d 28 00 00       	call   f01032b7 <memset>
f0100a6a:	83 c4 10             	add    $0x10,%esp

	// if there's a page that shouldn't be on the free list,

	// try to make sure it eventually causes trouble.

	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a6d:	8b 1b                	mov    (%ebx),%ebx
f0100a6f:	85 db                	test   %ebx,%ebx
f0100a71:	75 a9                	jne    f0100a1c <check_page_free_list+0x83>

			memset(page2kva(pp), 0x97, 128);



	first_free_page = (char *) boot_alloc(0);
f0100a73:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a78:	e8 80 fe ff ff       	call   f01008fd <boot_alloc>
f0100a7d:	89 45 cc             	mov    %eax,-0x34(%ebp)

	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a80:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx

		// check that we didn't corrupt the free list itself

		assert(pp >= pages);
f0100a86:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx

		assert(pp < pages + npages);
f0100a8c:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100a91:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a94:	8d 3c c1             	lea    (%ecx,%eax,8),%edi

		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a97:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

	struct PageInfo *pp;

	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;

	int nfree_basemem = 0, nfree_extmem = 0;
f0100a9a:	be 00 00 00 00       	mov    $0x0,%esi
f0100a9f:	89 5d d0             	mov    %ebx,-0x30(%ebp)



	first_free_page = (char *) boot_alloc(0);

	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aa2:	e9 30 01 00 00       	jmp    f0100bd7 <check_page_free_list+0x23e>

		// check that we didn't corrupt the free list itself

		assert(pp >= pages);
f0100aa7:	39 ca                	cmp    %ecx,%edx
f0100aa9:	73 19                	jae    f0100ac4 <check_page_free_list+0x12b>
f0100aab:	68 4e 44 10 f0       	push   $0xf010444e
f0100ab0:	68 5a 44 10 f0       	push   $0xf010445a
f0100ab5:	68 09 05 00 00       	push   $0x509
f0100aba:	68 34 44 10 f0       	push   $0xf0104434
f0100abf:	e8 c7 f5 ff ff       	call   f010008b <_panic>

		assert(pp < pages + npages);
f0100ac4:	39 fa                	cmp    %edi,%edx
f0100ac6:	72 19                	jb     f0100ae1 <check_page_free_list+0x148>
f0100ac8:	68 6f 44 10 f0       	push   $0xf010446f
f0100acd:	68 5a 44 10 f0       	push   $0xf010445a
f0100ad2:	68 0b 05 00 00       	push   $0x50b
f0100ad7:	68 34 44 10 f0       	push   $0xf0104434
f0100adc:	e8 aa f5 ff ff       	call   f010008b <_panic>

		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae1:	89 d0                	mov    %edx,%eax
f0100ae3:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ae6:	a8 07                	test   $0x7,%al
f0100ae8:	74 19                	je     f0100b03 <check_page_free_list+0x16a>
f0100aea:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0100aef:	68 5a 44 10 f0       	push   $0xf010445a
f0100af4:	68 0d 05 00 00       	push   $0x50d
f0100af9:	68 34 44 10 f0       	push   $0xf0104434
f0100afe:	e8 88 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b03:	c1 f8 03             	sar    $0x3,%eax
f0100b06:	c1 e0 0c             	shl    $0xc,%eax



		// check a few pages that shouldn't be on the free list

		assert(page2pa(pp) != 0);
f0100b09:	85 c0                	test   %eax,%eax
f0100b0b:	75 19                	jne    f0100b26 <check_page_free_list+0x18d>
f0100b0d:	68 83 44 10 f0       	push   $0xf0104483
f0100b12:	68 5a 44 10 f0       	push   $0xf010445a
f0100b17:	68 13 05 00 00       	push   $0x513
f0100b1c:	68 34 44 10 f0       	push   $0xf0104434
f0100b21:	e8 65 f5 ff ff       	call   f010008b <_panic>

		assert(page2pa(pp) != IOPHYSMEM);
f0100b26:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b2b:	75 19                	jne    f0100b46 <check_page_free_list+0x1ad>
f0100b2d:	68 94 44 10 f0       	push   $0xf0104494
f0100b32:	68 5a 44 10 f0       	push   $0xf010445a
f0100b37:	68 15 05 00 00       	push   $0x515
f0100b3c:	68 34 44 10 f0       	push   $0xf0104434
f0100b41:	e8 45 f5 ff ff       	call   f010008b <_panic>

		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b46:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b4b:	75 19                	jne    f0100b66 <check_page_free_list+0x1cd>
f0100b4d:	68 00 3d 10 f0       	push   $0xf0103d00
f0100b52:	68 5a 44 10 f0       	push   $0xf010445a
f0100b57:	68 17 05 00 00       	push   $0x517
f0100b5c:	68 34 44 10 f0       	push   $0xf0104434
f0100b61:	e8 25 f5 ff ff       	call   f010008b <_panic>

		assert(page2pa(pp) != EXTPHYSMEM);
f0100b66:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b6b:	75 19                	jne    f0100b86 <check_page_free_list+0x1ed>
f0100b6d:	68 ad 44 10 f0       	push   $0xf01044ad
f0100b72:	68 5a 44 10 f0       	push   $0xf010445a
f0100b77:	68 19 05 00 00       	push   $0x519
f0100b7c:	68 34 44 10 f0       	push   $0xf0104434
f0100b81:	e8 05 f5 ff ff       	call   f010008b <_panic>

		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b86:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b8b:	76 3f                	jbe    f0100bcc <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8d:	89 c3                	mov    %eax,%ebx
f0100b8f:	c1 eb 0c             	shr    $0xc,%ebx
f0100b92:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b95:	77 12                	ja     f0100ba9 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b97:	50                   	push   %eax
f0100b98:	68 84 3c 10 f0       	push   $0xf0103c84
f0100b9d:	6a 52                	push   $0x52
f0100b9f:	68 40 44 10 f0       	push   $0xf0104440
f0100ba4:	e8 e2 f4 ff ff       	call   f010008b <_panic>
f0100ba9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bae:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bb1:	76 1e                	jbe    f0100bd1 <check_page_free_list+0x238>
f0100bb3:	68 24 3d 10 f0       	push   $0xf0103d24
f0100bb8:	68 5a 44 10 f0       	push   $0xf010445a
f0100bbd:	68 1b 05 00 00       	push   $0x51b
f0100bc2:	68 34 44 10 f0       	push   $0xf0104434
f0100bc7:	e8 bf f4 ff ff       	call   f010008b <_panic>



		if (page2pa(pp) < EXTPHYSMEM)

			++nfree_basemem;
f0100bcc:	83 c6 01             	add    $0x1,%esi
f0100bcf:	eb 04                	jmp    f0100bd5 <check_page_free_list+0x23c>

		else

			++nfree_extmem;
f0100bd1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)



	first_free_page = (char *) boot_alloc(0);

	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd5:	8b 12                	mov    (%edx),%edx
f0100bd7:	85 d2                	test   %edx,%edx
f0100bd9:	0f 85 c8 fe ff ff    	jne    f0100aa7 <check_page_free_list+0x10e>
f0100bdf:	8b 5d d0             	mov    -0x30(%ebp),%ebx

	}



	assert(nfree_basemem > 0);
f0100be2:	85 f6                	test   %esi,%esi
f0100be4:	7f 19                	jg     f0100bff <check_page_free_list+0x266>
f0100be6:	68 c7 44 10 f0       	push   $0xf01044c7
f0100beb:	68 5a 44 10 f0       	push   $0xf010445a
f0100bf0:	68 2b 05 00 00       	push   $0x52b
f0100bf5:	68 34 44 10 f0       	push   $0xf0104434
f0100bfa:	e8 8c f4 ff ff       	call   f010008b <_panic>

	assert(nfree_extmem > 0);
f0100bff:	85 db                	test   %ebx,%ebx
f0100c01:	7f 42                	jg     f0100c45 <check_page_free_list+0x2ac>
f0100c03:	68 d9 44 10 f0       	push   $0xf01044d9
f0100c08:	68 5a 44 10 f0       	push   $0xf010445a
f0100c0d:	68 2d 05 00 00       	push   $0x52d
f0100c12:	68 34 44 10 f0       	push   $0xf0104434
f0100c17:	e8 6f f4 ff ff       	call   f010008b <_panic>

	char *first_free_page;



	if (!page_free_list)
f0100c1c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c21:	85 c0                	test   %eax,%eax
f0100c23:	0f 85 9d fd ff ff    	jne    f01009c6 <check_page_free_list+0x2d>
f0100c29:	e9 81 fd ff ff       	jmp    f01009af <check_page_free_list+0x16>
f0100c2e:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c35:	0f 84 74 fd ff ff    	je     f01009af <check_page_free_list+0x16>

{

	struct PageInfo *pp;

	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c3b:	be 00 04 00 00       	mov    $0x400,%esi
f0100c40:	e9 cf fd ff ff       	jmp    f0100a14 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);

	assert(nfree_extmem > 0);

}
f0100c45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c48:	5b                   	pop    %ebx
f0100c49:	5e                   	pop    %esi
f0100c4a:	5f                   	pop    %edi
f0100c4b:	5d                   	pop    %ebp
f0100c4c:	c3                   	ret    

f0100c4d <page_init>:

void

page_init(void)

{
f0100c4d:	55                   	push   %ebp
f0100c4e:	89 e5                	mov    %esp,%ebp
f0100c50:	57                   	push   %edi
f0100c51:	56                   	push   %esi
f0100c52:	53                   	push   %ebx
f0100c53:	83 ec 0c             	sub    $0xc,%esp

	size_t i;

    uint32_t pa;

    page_free_list = NULL;
f0100c56:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0100c5d:	00 00 00 



    for(i = 0; i<npages; i++)
f0100c60:	be 00 00 00 00       	mov    $0x0,%esi
f0100c65:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c6a:	e9 eb 00 00 00       	jmp    f0100d5a <page_init+0x10d>

    {

        if(i == 0)
f0100c6f:	85 db                	test   %ebx,%ebx
f0100c71:	75 16                	jne    f0100c89 <page_init+0x3c>

        {

            pages[0].pp_ref = 1;
f0100c73:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100c78:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)

            pages[0].pp_link = NULL;
f0100c7e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

            continue;
f0100c84:	e9 cb 00 00 00       	jmp    f0100d54 <page_init+0x107>

        }

        else if(i < npages_basemem)
f0100c89:	3b 1d 40 75 11 f0    	cmp    0xf0117540,%ebx
f0100c8f:	73 25                	jae    f0100cb6 <page_init+0x69>

        {

            // used for base memory

            pages[i].pp_ref = 0;
f0100c91:	89 f0                	mov    %esi,%eax
f0100c93:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100c99:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

            pages[i].pp_link = page_free_list;
f0100c9f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ca5:	89 10                	mov    %edx,(%eax)

            page_free_list = &pages[i];
f0100ca7:	89 f0                	mov    %esi,%eax
f0100ca9:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100caf:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100cb4:	eb 56                	jmp    f0100d0c <page_init+0xbf>

        }

        else if(i <= (EXTPHYSMEM/PGSIZE) || i < (((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT))
f0100cb6:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100cbc:	76 16                	jbe    f0100cd4 <page_init+0x87>
f0100cbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc3:	e8 35 fc ff ff       	call   f01008fd <boot_alloc>
f0100cc8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ccd:	c1 e8 0c             	shr    $0xc,%eax
f0100cd0:	39 c3                	cmp    %eax,%ebx
f0100cd2:	73 15                	jae    f0100ce9 <page_init+0x9c>

        {

            //used for IO memory

            pages[i].pp_ref++;
f0100cd4:	89 f0                	mov    %esi,%eax
f0100cd6:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cdc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

            pages[i].pp_link = NULL;
f0100ce1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ce7:	eb 23                	jmp    f0100d0c <page_init+0xbf>

        else

        {

            pages[i].pp_ref = 0;
f0100ce9:	89 f0                	mov    %esi,%eax
f0100ceb:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cf1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

            pages[i].pp_link = page_free_list;
f0100cf7:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100cfd:	89 10                	mov    %edx,(%eax)

            page_free_list = &pages[i];
f0100cff:	89 f0                	mov    %esi,%eax
f0100d01:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d07:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d0c:	89 f7                	mov    %esi,%edi
f0100d0e:	c1 ff 03             	sar    $0x3,%edi
f0100d11:	c1 e7 0c             	shl    $0xc,%edi

        pa = page2pa(&pages[i]);



        if((pa == 0 || (pa < IOPHYSMEM && pa <= ((uint32_t)boot_alloc(0) - KERNBASE) >> PGSHIFT)) && (pages[i].pp_ref == 0))
f0100d14:	85 ff                	test   %edi,%edi
f0100d16:	74 1e                	je     f0100d36 <page_init+0xe9>
f0100d18:	81 ff ff ff 09 00    	cmp    $0x9ffff,%edi
f0100d1e:	77 34                	ja     f0100d54 <page_init+0x107>
f0100d20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d25:	e8 d3 fb ff ff       	call   f01008fd <boot_alloc>
f0100d2a:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d2f:	c1 e8 0c             	shr    $0xc,%eax
f0100d32:	39 f8                	cmp    %edi,%eax
f0100d34:	72 1e                	jb     f0100d54 <page_init+0x107>
f0100d36:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100d3b:	66 83 7c 30 04 00    	cmpw   $0x0,0x4(%eax,%esi,1)
f0100d41:	75 11                	jne    f0100d54 <page_init+0x107>

        {

            cprintf("page error : i %d\n",i);
f0100d43:	83 ec 08             	sub    $0x8,%esp
f0100d46:	53                   	push   %ebx
f0100d47:	68 ea 44 10 f0       	push   $0xf01044ea
f0100d4c:	e8 ad 1a 00 00       	call   f01027fe <cprintf>
f0100d51:	83 c4 10             	add    $0x10,%esp

    page_free_list = NULL;



    for(i = 0; i<npages; i++)
f0100d54:	83 c3 01             	add    $0x1,%ebx
f0100d57:	83 c6 08             	add    $0x8,%esi
f0100d5a:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100d60:	0f 82 09 ff ff ff    	jb     f0100c6f <page_init+0x22>

        }

    }

}
f0100d66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d69:	5b                   	pop    %ebx
f0100d6a:	5e                   	pop    %esi
f0100d6b:	5f                   	pop    %edi
f0100d6c:	5d                   	pop    %ebp
f0100d6d:	c3                   	ret    

f0100d6e <page_alloc>:

struct PageInfo *

page_alloc(int alloc_flags)

{
f0100d6e:	55                   	push   %ebp
f0100d6f:	89 e5                	mov    %esp,%ebp
f0100d71:	53                   	push   %ebx
f0100d72:	83 ec 04             	sub    $0x4,%esp

    struct PageInfo* pp = NULL;

    if (!page_free_list)
f0100d75:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d7b:	85 db                	test   %ebx,%ebx
f0100d7d:	74 52                	je     f0100dd1 <page_alloc+0x63>

    pp = page_free_list;



    page_free_list = page_free_list->pp_link;
f0100d7f:	8b 03                	mov    (%ebx),%eax
f0100d81:	a3 3c 75 11 f0       	mov    %eax,0xf011753c



    if(alloc_flags & ALLOC_ZERO)
f0100d86:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d8a:	74 45                	je     f0100dd1 <page_alloc+0x63>
f0100d8c:	89 d8                	mov    %ebx,%eax
f0100d8e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d94:	c1 f8 03             	sar    $0x3,%eax
f0100d97:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d9a:	89 c2                	mov    %eax,%edx
f0100d9c:	c1 ea 0c             	shr    $0xc,%edx
f0100d9f:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100da5:	72 12                	jb     f0100db9 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da7:	50                   	push   %eax
f0100da8:	68 84 3c 10 f0       	push   $0xf0103c84
f0100dad:	6a 52                	push   $0x52
f0100daf:	68 40 44 10 f0       	push   $0xf0104440
f0100db4:	e8 d2 f2 ff ff       	call   f010008b <_panic>

    {

        memset(page2kva(pp), 0, PGSIZE);
f0100db9:	83 ec 04             	sub    $0x4,%esp
f0100dbc:	68 00 10 00 00       	push   $0x1000
f0100dc1:	6a 00                	push   $0x0
f0100dc3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dc8:	50                   	push   %eax
f0100dc9:	e8 e9 24 00 00       	call   f01032b7 <memset>
f0100dce:	83 c4 10             	add    $0x10,%esp



	return pp;

}
f0100dd1:	89 d8                	mov    %ebx,%eax
f0100dd3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dd6:	c9                   	leave  
f0100dd7:	c3                   	ret    

f0100dd8 <page_free>:

void

page_free(struct PageInfo *pp)

{
f0100dd8:	55                   	push   %ebp
f0100dd9:	89 e5                	mov    %esp,%ebp
f0100ddb:	83 ec 08             	sub    $0x8,%esp
f0100dde:	8b 45 08             	mov    0x8(%ebp),%eax

	// pp->pp_link is not NULL.



    assert(pp->pp_ref == 0 || pp->pp_link == NULL);
f0100de1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100de6:	74 1e                	je     f0100e06 <page_free+0x2e>
f0100de8:	83 38 00             	cmpl   $0x0,(%eax)
f0100deb:	74 19                	je     f0100e06 <page_free+0x2e>
f0100ded:	68 6c 3d 10 f0       	push   $0xf0103d6c
f0100df2:	68 5a 44 10 f0       	push   $0xf010445a
f0100df7:	68 c9 02 00 00       	push   $0x2c9
f0100dfc:	68 34 44 10 f0       	push   $0xf0104434
f0100e01:	e8 85 f2 ff ff       	call   f010008b <_panic>



    pp->pp_link = page_free_list;
f0100e06:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e0c:	89 10                	mov    %edx,(%eax)

    page_free_list = pp;
f0100e0e:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

}
f0100e13:	c9                   	leave  
f0100e14:	c3                   	ret    

f0100e15 <page_decref>:

void

page_decref(struct PageInfo* pp)

{
f0100e15:	55                   	push   %ebp
f0100e16:	89 e5                	mov    %esp,%ebp
f0100e18:	83 ec 08             	sub    $0x8,%esp
f0100e1b:	8b 55 08             	mov    0x8(%ebp),%edx

	if (--pp->pp_ref == 0)
f0100e1e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e22:	83 e8 01             	sub    $0x1,%eax
f0100e25:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e29:	66 85 c0             	test   %ax,%ax
f0100e2c:	75 0c                	jne    f0100e3a <page_decref+0x25>

		page_free(pp);
f0100e2e:	83 ec 0c             	sub    $0xc,%esp
f0100e31:	52                   	push   %edx
f0100e32:	e8 a1 ff ff ff       	call   f0100dd8 <page_free>
f0100e37:	83 c4 10             	add    $0x10,%esp

}
f0100e3a:	c9                   	leave  
f0100e3b:	c3                   	ret    

f0100e3c <pgdir_walk>:

pte_t *

pgdir_walk(pde_t *pgdir, const void *va, int create)

{
f0100e3c:	55                   	push   %ebp
f0100e3d:	89 e5                	mov    %esp,%ebp
f0100e3f:	57                   	push   %edi
f0100e40:	56                   	push   %esi
f0100e41:	53                   	push   %ebx
f0100e42:	83 ec 0c             	sub    $0xc,%esp
f0100e45:	8b 5d 0c             	mov    0xc(%ebp),%ebx

    struct PageInfo *pp = NULL;



    pde = &pgdir[PDX(va)];
f0100e48:	89 de                	mov    %ebx,%esi
f0100e4a:	c1 ee 16             	shr    $0x16,%esi
f0100e4d:	c1 e6 02             	shl    $0x2,%esi
f0100e50:	03 75 08             	add    0x8(%ebp),%esi



    if(*pde & PTE_P)
f0100e53:	8b 06                	mov    (%esi),%eax
f0100e55:	a8 01                	test   $0x1,%al
f0100e57:	74 2f                	je     f0100e88 <pgdir_walk+0x4c>

    {

        pgtable = (KADDR(PTE_ADDR(*pde)));
f0100e59:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e5e:	89 c2                	mov    %eax,%edx
f0100e60:	c1 ea 0c             	shr    $0xc,%edx
f0100e63:	39 15 64 79 11 f0    	cmp    %edx,0xf0117964
f0100e69:	77 15                	ja     f0100e80 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e6b:	50                   	push   %eax
f0100e6c:	68 84 3c 10 f0       	push   $0xf0103c84
f0100e71:	68 33 03 00 00       	push   $0x333
f0100e76:	68 34 44 10 f0       	push   $0xf0104434
f0100e7b:	e8 0b f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100e80:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100e86:	eb 77                	jmp    f0100eff <pgdir_walk+0xc3>

    else

    {

        if(!create ||
f0100e88:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e8c:	74 7f                	je     f0100f0d <pgdir_walk+0xd1>
f0100e8e:	83 ec 0c             	sub    $0xc,%esp
f0100e91:	6a 01                	push   $0x1
f0100e93:	e8 d6 fe ff ff       	call   f0100d6e <page_alloc>
f0100e98:	83 c4 10             	add    $0x10,%esp
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	74 75                	je     f0100f14 <pgdir_walk+0xd8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9f:	89 c1                	mov    %eax,%ecx
f0100ea1:	2b 0d 6c 79 11 f0    	sub    0xf011796c,%ecx
f0100ea7:	c1 f9 03             	sar    $0x3,%ecx
f0100eaa:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ead:	89 ca                	mov    %ecx,%edx
f0100eaf:	c1 ea 0c             	shr    $0xc,%edx
f0100eb2:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100eb8:	72 12                	jb     f0100ecc <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eba:	51                   	push   %ecx
f0100ebb:	68 84 3c 10 f0       	push   $0xf0103c84
f0100ec0:	6a 52                	push   $0x52
f0100ec2:	68 40 44 10 f0       	push   $0xf0104440
f0100ec7:	e8 bf f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ecc:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100ed2:	89 fa                	mov    %edi,%edx

            !(pp = page_alloc(ALLOC_ZERO)) ||
f0100ed4:	85 ff                	test   %edi,%edi
f0100ed6:	74 43                	je     f0100f1b <pgdir_walk+0xdf>

        }



        pp->pp_ref++;
f0100ed8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100edd:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100ee3:	77 15                	ja     f0100efa <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ee5:	57                   	push   %edi
f0100ee6:	68 94 3d 10 f0       	push   $0xf0103d94
f0100eeb:	68 4b 03 00 00       	push   $0x34b
f0100ef0:	68 34 44 10 f0       	push   $0xf0104434
f0100ef5:	e8 91 f1 ff ff       	call   f010008b <_panic>

        *pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0100efa:	83 c9 07             	or     $0x7,%ecx
f0100efd:	89 0e                	mov    %ecx,(%esi)

    }



	return &pgtable[PTX(va)];
f0100eff:	c1 eb 0a             	shr    $0xa,%ebx
f0100f02:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100f08:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100f0b:	eb 13                	jmp    f0100f20 <pgdir_walk+0xe4>

            !(pgtable = (pte_t *)page2kva(pp)))

        {

            return NULL;
f0100f0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f12:	eb 0c                	jmp    f0100f20 <pgdir_walk+0xe4>
f0100f14:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f19:	eb 05                	jmp    f0100f20 <pgdir_walk+0xe4>
f0100f1b:	b8 00 00 00 00       	mov    $0x0,%eax



	return &pgtable[PTX(va)];

}
f0100f20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f23:	5b                   	pop    %ebx
f0100f24:	5e                   	pop    %esi
f0100f25:	5f                   	pop    %edi
f0100f26:	5d                   	pop    %ebp
f0100f27:	c3                   	ret    

f0100f28 <boot_map_region>:

static void

boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)

{
f0100f28:	55                   	push   %ebp
f0100f29:	89 e5                	mov    %esp,%ebp
f0100f2b:	57                   	push   %edi
f0100f2c:	56                   	push   %esi
f0100f2d:	53                   	push   %ebx
f0100f2e:	83 ec 1c             	sub    $0x1c,%esp
f0100f31:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f34:	89 d7                	mov    %edx,%edi
f0100f36:	89 cb                	mov    %ecx,%ebx

    ROUNDUP(size, PGSIZE);



    assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f0100f38:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f0100f3e:	75 1b                	jne    f0100f5b <boot_map_region+0x33>
f0100f40:	c1 eb 0c             	shr    $0xc,%ebx
f0100f43:	89 5d e4             	mov    %ebx,-0x1c(%ebp)

    int temp = 0;



    for(temp = 0; temp < size/PGSIZE; temp++)
f0100f46:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100f49:	be 00 00 00 00       	mov    $0x0,%esi

    {

        pte = pgdir_walk(pgdir, (void*)va_next, 1);
f0100f4e:	29 df                	sub    %ebx,%edi

        }



        *pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0100f50:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f53:	83 c8 01             	or     $0x1,%eax
f0100f56:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f59:	eb 5c                	jmp    f0100fb7 <boot_map_region+0x8f>

    ROUNDUP(size, PGSIZE);



    assert(size % PGSIZE == 0 || cprintf("size : %x \n", size));
f0100f5b:	83 ec 08             	sub    $0x8,%esp
f0100f5e:	51                   	push   %ecx
f0100f5f:	68 fd 44 10 f0       	push   $0xf01044fd
f0100f64:	e8 95 18 00 00       	call   f01027fe <cprintf>
f0100f69:	83 c4 10             	add    $0x10,%esp
f0100f6c:	85 c0                	test   %eax,%eax
f0100f6e:	75 d0                	jne    f0100f40 <boot_map_region+0x18>
f0100f70:	68 b8 3d 10 f0       	push   $0xf0103db8
f0100f75:	68 5a 44 10 f0       	push   $0xf010445a
f0100f7a:	68 81 03 00 00       	push   $0x381
f0100f7f:	68 34 44 10 f0       	push   $0xf0104434
f0100f84:	e8 02 f1 ff ff       	call   f010008b <_panic>

    for(temp = 0; temp < size/PGSIZE; temp++)

    {

        pte = pgdir_walk(pgdir, (void*)va_next, 1);
f0100f89:	83 ec 04             	sub    $0x4,%esp
f0100f8c:	6a 01                	push   $0x1
f0100f8e:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f91:	50                   	push   %eax
f0100f92:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f95:	e8 a2 fe ff ff       	call   f0100e3c <pgdir_walk>



        if(!pte)
f0100f9a:	83 c4 10             	add    $0x10,%esp
f0100f9d:	85 c0                	test   %eax,%eax
f0100f9f:	74 1b                	je     f0100fbc <boot_map_region+0x94>

        }



        *pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0100fa1:	89 da                	mov    %ebx,%edx
f0100fa3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100fa9:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100fac:	89 10                	mov    %edx,(%eax)

        pa_next += PGSIZE;
f0100fae:	81 c3 00 10 00 00    	add    $0x1000,%ebx

    int temp = 0;



    for(temp = 0; temp < size/PGSIZE; temp++)
f0100fb4:	83 c6 01             	add    $0x1,%esi
f0100fb7:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fba:	75 cd                	jne    f0100f89 <boot_map_region+0x61>

        va_next += PGSIZE;

    }

}
f0100fbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fbf:	5b                   	pop    %ebx
f0100fc0:	5e                   	pop    %esi
f0100fc1:	5f                   	pop    %edi
f0100fc2:	5d                   	pop    %ebp
f0100fc3:	c3                   	ret    

f0100fc4 <page_lookup>:

struct PageInfo *

page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)

{
f0100fc4:	55                   	push   %ebp
f0100fc5:	89 e5                	mov    %esp,%ebp
f0100fc7:	83 ec 0c             	sub    $0xc,%esp

	// Fill this function in

    pte_t * pte = pgdir_walk(pgdir, va, 0);
f0100fca:	6a 00                	push   $0x0
f0100fcc:	ff 75 0c             	pushl  0xc(%ebp)
f0100fcf:	ff 75 08             	pushl  0x8(%ebp)
f0100fd2:	e8 65 fe ff ff       	call   f0100e3c <pgdir_walk>



    if(!pte)
f0100fd7:	83 c4 10             	add    $0x10,%esp
f0100fda:	85 c0                	test   %eax,%eax
f0100fdc:	74 31                	je     f010100f <page_lookup+0x4b>

    }



    *pte_store = pte;
f0100fde:	8b 55 10             	mov    0x10(%ebp),%edx
f0100fe1:	89 02                	mov    %eax,(%edx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe3:	8b 00                	mov    (%eax),%eax
f0100fe5:	c1 e8 0c             	shr    $0xc,%eax
f0100fe8:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fee:	72 14                	jb     f0101004 <page_lookup+0x40>
		panic("pa2page called with invalid pa");
f0100ff0:	83 ec 04             	sub    $0x4,%esp
f0100ff3:	68 ec 3d 10 f0       	push   $0xf0103dec
f0100ff8:	6a 4b                	push   $0x4b
f0100ffa:	68 40 44 10 f0       	push   $0xf0104440
f0100fff:	e8 87 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101004:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f010100a:	8d 04 c2             	lea    (%edx,%eax,8),%eax



	return pa2page(PTE_ADDR(*pte));
f010100d:	eb 05                	jmp    f0101014 <page_lookup+0x50>

    if(!pte)

    {

        return NULL;
f010100f:	b8 00 00 00 00       	mov    $0x0,%eax



	return pa2page(PTE_ADDR(*pte));

}
f0101014:	c9                   	leave  
f0101015:	c3                   	ret    

f0101016 <page_remove>:

void

page_remove(pde_t *pgdir, void *va)

{
f0101016:	55                   	push   %ebp
f0101017:	89 e5                	mov    %esp,%ebp
f0101019:	56                   	push   %esi
f010101a:	53                   	push   %ebx
f010101b:	83 ec 14             	sub    $0x14,%esp
f010101e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101021:	8b 5d 0c             	mov    0xc(%ebp),%ebx

	// Fill this function in

    pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101024:	6a 00                	push   $0x0
f0101026:	53                   	push   %ebx
f0101027:	56                   	push   %esi
f0101028:	e8 0f fe ff ff       	call   f0100e3c <pgdir_walk>
f010102d:	89 45 f4             	mov    %eax,-0xc(%ebp)

    pte_t ** pte_store = &pte;



    struct PageInfo *pp = page_lookup(pgdir, va, pte_store);
f0101030:	83 c4 0c             	add    $0xc,%esp
f0101033:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101036:	50                   	push   %eax
f0101037:	53                   	push   %ebx
f0101038:	56                   	push   %esi
f0101039:	e8 86 ff ff ff       	call   f0100fc4 <page_lookup>



    if(!pp)
f010103e:	83 c4 10             	add    $0x10,%esp
f0101041:	85 c0                	test   %eax,%eax
f0101043:	74 18                	je     f010105d <page_remove+0x47>

    }



    page_decref(pp);
f0101045:	83 ec 0c             	sub    $0xc,%esp
f0101048:	50                   	push   %eax
f0101049:	e8 c7 fd ff ff       	call   f0100e15 <page_decref>

    **pte_store = 0;
f010104e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101051:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101057:	0f 01 3b             	invlpg (%ebx)
f010105a:	83 c4 10             	add    $0x10,%esp

    tlb_invalidate(pgdir, va);

}
f010105d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101060:	5b                   	pop    %ebx
f0101061:	5e                   	pop    %esi
f0101062:	5d                   	pop    %ebp
f0101063:	c3                   	ret    

f0101064 <page_insert>:

int

page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)

{
f0101064:	55                   	push   %ebp
f0101065:	89 e5                	mov    %esp,%ebp
f0101067:	57                   	push   %edi
f0101068:	56                   	push   %esi
f0101069:	53                   	push   %ebx
f010106a:	83 ec 10             	sub    $0x10,%esp
f010106d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101070:	8b 7d 10             	mov    0x10(%ebp),%edi

	// Fill this function in

    pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101073:	6a 00                	push   $0x0
f0101075:	57                   	push   %edi
f0101076:	ff 75 08             	pushl  0x8(%ebp)
f0101079:	e8 be fd ff ff       	call   f0100e3c <pgdir_walk>

    physaddr_t ppa = page2pa(pp);



    if(pte)
f010107e:	83 c4 10             	add    $0x10,%esp
f0101081:	85 c0                	test   %eax,%eax
f0101083:	74 27                	je     f01010ac <page_insert+0x48>
f0101085:	89 c6                	mov    %eax,%esi

    {

        if(*pte & PTE_P)
f0101087:	f6 00 01             	testb  $0x1,(%eax)
f010108a:	74 0f                	je     f010109b <page_insert+0x37>

        {

            page_remove(pgdir, va);
f010108c:	83 ec 08             	sub    $0x8,%esp
f010108f:	57                   	push   %edi
f0101090:	ff 75 08             	pushl  0x8(%ebp)
f0101093:	e8 7e ff ff ff       	call   f0101016 <page_remove>
f0101098:	83 c4 10             	add    $0x10,%esp

        }



        if(page_free_list == pp)
f010109b:	3b 1d 3c 75 11 f0    	cmp    0xf011753c,%ebx
f01010a1:	75 20                	jne    f01010c3 <page_insert+0x5f>

        {

            page_free_list = page_free_list->pp_link;
f01010a3:	8b 03                	mov    (%ebx),%eax
f01010a5:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f01010aa:	eb 17                	jmp    f01010c3 <page_insert+0x5f>

    else

    {

        pte = pgdir_walk(pgdir, va, 1);
f01010ac:	83 ec 04             	sub    $0x4,%esp
f01010af:	6a 01                	push   $0x1
f01010b1:	57                   	push   %edi
f01010b2:	ff 75 08             	pushl  0x8(%ebp)
f01010b5:	e8 82 fd ff ff       	call   f0100e3c <pgdir_walk>
f01010ba:	89 c6                	mov    %eax,%esi

        if(!pte)
f01010bc:	83 c4 10             	add    $0x10,%esp
f01010bf:	85 c0                	test   %eax,%eax
f01010c1:	74 27                	je     f01010ea <page_insert+0x86>

    }



    *pte = page2pa(pp) | PTE_P | perm;
f01010c3:	89 d8                	mov    %ebx,%eax
f01010c5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01010cb:	c1 f8 03             	sar    $0x3,%eax
f01010ce:	c1 e0 0c             	shl    $0xc,%eax
f01010d1:	8b 55 14             	mov    0x14(%ebp),%edx
f01010d4:	83 ca 01             	or     $0x1,%edx
f01010d7:	09 d0                	or     %edx,%eax
f01010d9:	89 06                	mov    %eax,(%esi)



    pp->pp_ref++;
f01010db:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
f01010e0:	0f 01 3f             	invlpg (%edi)

    tlb_invalidate(pgdir, va);

	return 0;
f01010e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e8:	eb 05                	jmp    f01010ef <page_insert+0x8b>

        if(!pte)

        {

            return -E_NO_MEM;
f01010ea:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax

    tlb_invalidate(pgdir, va);

	return 0;

}
f01010ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010f2:	5b                   	pop    %ebx
f01010f3:	5e                   	pop    %esi
f01010f4:	5f                   	pop    %edi
f01010f5:	5d                   	pop    %ebp
f01010f6:	c3                   	ret    

f01010f7 <mem_init>:

void

mem_init(void)

{
f01010f7:	55                   	push   %ebp
f01010f8:	89 e5                	mov    %esp,%ebp
f01010fa:	57                   	push   %edi
f01010fb:	56                   	push   %esi
f01010fc:	53                   	push   %ebx
f01010fd:	83 ec 38             	sub    $0x38,%esp

nvram_read(int r)

{

	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101100:	6a 15                	push   $0x15
f0101102:	e8 90 16 00 00       	call   f0102797 <mc146818_read>
f0101107:	89 c3                	mov    %eax,%ebx
f0101109:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101110:	e8 82 16 00 00       	call   f0102797 <mc146818_read>

	// Use CMOS calls to measure available base & extended memory.

	// (CMOS calls return results in kilobytes.)

	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101115:	c1 e0 08             	shl    $0x8,%eax
f0101118:	09 d8                	or     %ebx,%eax
f010111a:	c1 e0 0a             	shl    $0xa,%eax
f010111d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101123:	85 c0                	test   %eax,%eax
f0101125:	0f 48 c2             	cmovs  %edx,%eax
f0101128:	c1 f8 0c             	sar    $0xc,%eax
f010112b:	a3 40 75 11 f0       	mov    %eax,0xf0117540

nvram_read(int r)

{

	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101130:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101137:	e8 5b 16 00 00       	call   f0102797 <mc146818_read>
f010113c:	89 c3                	mov    %eax,%ebx
f010113e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101145:	e8 4d 16 00 00       	call   f0102797 <mc146818_read>

	// (CMOS calls return results in kilobytes.)

	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;

	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010114a:	c1 e0 08             	shl    $0x8,%eax
f010114d:	09 d8                	or     %ebx,%eax
f010114f:	c1 e0 0a             	shl    $0xa,%eax
f0101152:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101158:	83 c4 10             	add    $0x10,%esp
f010115b:	85 c0                	test   %eax,%eax
f010115d:	0f 48 c2             	cmovs  %edx,%eax
f0101160:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base

	// and extended memory.

	if (npages_extmem)
f0101163:	85 c0                	test   %eax,%eax
f0101165:	74 0e                	je     f0101175 <mem_init+0x7e>

		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101167:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010116d:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f0101173:	eb 0c                	jmp    f0101181 <mem_init+0x8a>

	else

		npages = npages_basemem;
f0101175:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f010117b:	89 15 64 79 11 f0    	mov    %edx,0xf0117964



	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101181:	c1 e0 0c             	shl    $0xc,%eax
f0101184:	c1 e8 0a             	shr    $0xa,%eax
f0101187:	50                   	push   %eax
f0101188:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010118d:	c1 e0 0c             	shl    $0xc,%eax
f0101190:	c1 e8 0a             	shr    $0xa,%eax
f0101193:	50                   	push   %eax
f0101194:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101199:	c1 e0 0c             	shl    $0xc,%eax
f010119c:	c1 e8 0a             	shr    $0xa,%eax
f010119f:	50                   	push   %eax
f01011a0:	68 0c 3e 10 f0       	push   $0xf0103e0c
f01011a5:	e8 54 16 00 00       	call   f01027fe <cprintf>

	//////////////////////////////////////////////////////////////////////

	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011aa:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011af:	e8 49 f7 ff ff       	call   f01008fd <boot_alloc>
f01011b4:	a3 68 79 11 f0       	mov    %eax,0xf0117968

	memset(kern_pgdir, 0, PGSIZE);
f01011b9:	83 c4 0c             	add    $0xc,%esp
f01011bc:	68 00 10 00 00       	push   $0x1000
f01011c1:	6a 00                	push   $0x0
f01011c3:	50                   	push   %eax
f01011c4:	e8 ee 20 00 00       	call   f01032b7 <memset>



	// Permissions: kernel R, user R

	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01011c9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011ce:	83 c4 10             	add    $0x10,%esp
f01011d1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01011d6:	77 15                	ja     f01011ed <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011d8:	50                   	push   %eax
f01011d9:	68 94 3d 10 f0       	push   $0xf0103d94
f01011de:	68 19 01 00 00       	push   $0x119
f01011e3:	68 34 44 10 f0       	push   $0xf0104434
f01011e8:	e8 9e ee ff ff       	call   f010008b <_panic>
f01011ed:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011f3:	83 ca 05             	or     $0x5,%edx
f01011f6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)

	// Your code goes here:



    pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01011fc:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101201:	c1 e0 03             	shl    $0x3,%eax
f0101204:	e8 f4 f6 ff ff       	call   f01008fd <boot_alloc>
f0101209:	a3 6c 79 11 f0       	mov    %eax,0xf011796c

	memset(pages, 0, npages * sizeof(struct PageInfo));
f010120e:	83 ec 04             	sub    $0x4,%esp
f0101211:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101217:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010121e:	52                   	push   %edx
f010121f:	6a 00                	push   $0x0
f0101221:	50                   	push   %eax
f0101222:	e8 90 20 00 00       	call   f01032b7 <memset>

	// particular, we can now map memory using boot_map_region

	// or page_insert

	page_init();
f0101227:	e8 21 fa ff ff       	call   f0100c4d <page_init>



	check_page_free_list(1);
f010122c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101231:	e8 63 f7 ff ff       	call   f0100999 <check_page_free_list>

	int i;



	if (!pages)
f0101236:	83 c4 10             	add    $0x10,%esp
f0101239:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f0101240:	75 17                	jne    f0101259 <mem_init+0x162>

		panic("'pages' is a null pointer!");
f0101242:	83 ec 04             	sub    $0x4,%esp
f0101245:	68 09 45 10 f0       	push   $0xf0104509
f010124a:	68 4f 05 00 00       	push   $0x54f
f010124f:	68 34 44 10 f0       	push   $0xf0104434
f0101254:	e8 32 ee ff ff       	call   f010008b <_panic>



	// check number of free pages

	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101259:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010125e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101263:	eb 05                	jmp    f010126a <mem_init+0x173>

		++nfree;
f0101265:	83 c3 01             	add    $0x1,%ebx



	// check number of free pages

	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101268:	8b 00                	mov    (%eax),%eax
f010126a:	85 c0                	test   %eax,%eax
f010126c:	75 f7                	jne    f0101265 <mem_init+0x16e>

	// should be able to allocate three pages

	pp0 = pp1 = pp2 = 0;

	assert((pp0 = page_alloc(0)));
f010126e:	83 ec 0c             	sub    $0xc,%esp
f0101271:	6a 00                	push   $0x0
f0101273:	e8 f6 fa ff ff       	call   f0100d6e <page_alloc>
f0101278:	89 c7                	mov    %eax,%edi
f010127a:	83 c4 10             	add    $0x10,%esp
f010127d:	85 c0                	test   %eax,%eax
f010127f:	75 19                	jne    f010129a <mem_init+0x1a3>
f0101281:	68 24 45 10 f0       	push   $0xf0104524
f0101286:	68 5a 44 10 f0       	push   $0xf010445a
f010128b:	68 5f 05 00 00       	push   $0x55f
f0101290:	68 34 44 10 f0       	push   $0xf0104434
f0101295:	e8 f1 ed ff ff       	call   f010008b <_panic>

	assert((pp1 = page_alloc(0)));
f010129a:	83 ec 0c             	sub    $0xc,%esp
f010129d:	6a 00                	push   $0x0
f010129f:	e8 ca fa ff ff       	call   f0100d6e <page_alloc>
f01012a4:	89 c6                	mov    %eax,%esi
f01012a6:	83 c4 10             	add    $0x10,%esp
f01012a9:	85 c0                	test   %eax,%eax
f01012ab:	75 19                	jne    f01012c6 <mem_init+0x1cf>
f01012ad:	68 3a 45 10 f0       	push   $0xf010453a
f01012b2:	68 5a 44 10 f0       	push   $0xf010445a
f01012b7:	68 61 05 00 00       	push   $0x561
f01012bc:	68 34 44 10 f0       	push   $0xf0104434
f01012c1:	e8 c5 ed ff ff       	call   f010008b <_panic>

	assert((pp2 = page_alloc(0)));
f01012c6:	83 ec 0c             	sub    $0xc,%esp
f01012c9:	6a 00                	push   $0x0
f01012cb:	e8 9e fa ff ff       	call   f0100d6e <page_alloc>
f01012d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012d3:	83 c4 10             	add    $0x10,%esp
f01012d6:	85 c0                	test   %eax,%eax
f01012d8:	75 19                	jne    f01012f3 <mem_init+0x1fc>
f01012da:	68 50 45 10 f0       	push   $0xf0104550
f01012df:	68 5a 44 10 f0       	push   $0xf010445a
f01012e4:	68 63 05 00 00       	push   $0x563
f01012e9:	68 34 44 10 f0       	push   $0xf0104434
f01012ee:	e8 98 ed ff ff       	call   f010008b <_panic>



	assert(pp0);

	assert(pp1 && pp1 != pp0);
f01012f3:	39 f7                	cmp    %esi,%edi
f01012f5:	75 19                	jne    f0101310 <mem_init+0x219>
f01012f7:	68 66 45 10 f0       	push   $0xf0104566
f01012fc:	68 5a 44 10 f0       	push   $0xf010445a
f0101301:	68 69 05 00 00       	push   $0x569
f0101306:	68 34 44 10 f0       	push   $0xf0104434
f010130b:	e8 7b ed ff ff       	call   f010008b <_panic>

	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101310:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101313:	39 c6                	cmp    %eax,%esi
f0101315:	74 04                	je     f010131b <mem_init+0x224>
f0101317:	39 c7                	cmp    %eax,%edi
f0101319:	75 19                	jne    f0101334 <mem_init+0x23d>
f010131b:	68 48 3e 10 f0       	push   $0xf0103e48
f0101320:	68 5a 44 10 f0       	push   $0xf010445a
f0101325:	68 6b 05 00 00       	push   $0x56b
f010132a:	68 34 44 10 f0       	push   $0xf0104434
f010132f:	e8 57 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101334:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx

	assert(page2pa(pp0) < npages*PGSIZE);
f010133a:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0101340:	c1 e2 0c             	shl    $0xc,%edx
f0101343:	89 f8                	mov    %edi,%eax
f0101345:	29 c8                	sub    %ecx,%eax
f0101347:	c1 f8 03             	sar    $0x3,%eax
f010134a:	c1 e0 0c             	shl    $0xc,%eax
f010134d:	39 d0                	cmp    %edx,%eax
f010134f:	72 19                	jb     f010136a <mem_init+0x273>
f0101351:	68 78 45 10 f0       	push   $0xf0104578
f0101356:	68 5a 44 10 f0       	push   $0xf010445a
f010135b:	68 6d 05 00 00       	push   $0x56d
f0101360:	68 34 44 10 f0       	push   $0xf0104434
f0101365:	e8 21 ed ff ff       	call   f010008b <_panic>

	assert(page2pa(pp1) < npages*PGSIZE);
f010136a:	89 f0                	mov    %esi,%eax
f010136c:	29 c8                	sub    %ecx,%eax
f010136e:	c1 f8 03             	sar    $0x3,%eax
f0101371:	c1 e0 0c             	shl    $0xc,%eax
f0101374:	39 c2                	cmp    %eax,%edx
f0101376:	77 19                	ja     f0101391 <mem_init+0x29a>
f0101378:	68 95 45 10 f0       	push   $0xf0104595
f010137d:	68 5a 44 10 f0       	push   $0xf010445a
f0101382:	68 6f 05 00 00       	push   $0x56f
f0101387:	68 34 44 10 f0       	push   $0xf0104434
f010138c:	e8 fa ec ff ff       	call   f010008b <_panic>

	assert(page2pa(pp2) < npages*PGSIZE);
f0101391:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101394:	29 c8                	sub    %ecx,%eax
f0101396:	c1 f8 03             	sar    $0x3,%eax
f0101399:	c1 e0 0c             	shl    $0xc,%eax
f010139c:	39 c2                	cmp    %eax,%edx
f010139e:	77 19                	ja     f01013b9 <mem_init+0x2c2>
f01013a0:	68 b2 45 10 f0       	push   $0xf01045b2
f01013a5:	68 5a 44 10 f0       	push   $0xf010445a
f01013aa:	68 71 05 00 00       	push   $0x571
f01013af:	68 34 44 10 f0       	push   $0xf0104434
f01013b4:	e8 d2 ec ff ff       	call   f010008b <_panic>



	// temporarily steal the rest of the free pages

	fl = page_free_list;
f01013b9:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01013be:	89 45 d0             	mov    %eax,-0x30(%ebp)

	page_free_list = 0;
f01013c1:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01013c8:	00 00 00 



	// should be no free memory

	assert(!page_alloc(0));
f01013cb:	83 ec 0c             	sub    $0xc,%esp
f01013ce:	6a 00                	push   $0x0
f01013d0:	e8 99 f9 ff ff       	call   f0100d6e <page_alloc>
f01013d5:	83 c4 10             	add    $0x10,%esp
f01013d8:	85 c0                	test   %eax,%eax
f01013da:	74 19                	je     f01013f5 <mem_init+0x2fe>
f01013dc:	68 cf 45 10 f0       	push   $0xf01045cf
f01013e1:	68 5a 44 10 f0       	push   $0xf010445a
f01013e6:	68 7f 05 00 00       	push   $0x57f
f01013eb:	68 34 44 10 f0       	push   $0xf0104434
f01013f0:	e8 96 ec ff ff       	call   f010008b <_panic>



	// free and re-allocate?

	page_free(pp0);
f01013f5:	83 ec 0c             	sub    $0xc,%esp
f01013f8:	57                   	push   %edi
f01013f9:	e8 da f9 ff ff       	call   f0100dd8 <page_free>

	page_free(pp1);
f01013fe:	89 34 24             	mov    %esi,(%esp)
f0101401:	e8 d2 f9 ff ff       	call   f0100dd8 <page_free>

	page_free(pp2);
f0101406:	83 c4 04             	add    $0x4,%esp
f0101409:	ff 75 d4             	pushl  -0x2c(%ebp)
f010140c:	e8 c7 f9 ff ff       	call   f0100dd8 <page_free>

	pp0 = pp1 = pp2 = 0;

	assert((pp0 = page_alloc(0)));
f0101411:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101418:	e8 51 f9 ff ff       	call   f0100d6e <page_alloc>
f010141d:	89 c6                	mov    %eax,%esi
f010141f:	83 c4 10             	add    $0x10,%esp
f0101422:	85 c0                	test   %eax,%eax
f0101424:	75 19                	jne    f010143f <mem_init+0x348>
f0101426:	68 24 45 10 f0       	push   $0xf0104524
f010142b:	68 5a 44 10 f0       	push   $0xf010445a
f0101430:	68 8d 05 00 00       	push   $0x58d
f0101435:	68 34 44 10 f0       	push   $0xf0104434
f010143a:	e8 4c ec ff ff       	call   f010008b <_panic>

	assert((pp1 = page_alloc(0)));
f010143f:	83 ec 0c             	sub    $0xc,%esp
f0101442:	6a 00                	push   $0x0
f0101444:	e8 25 f9 ff ff       	call   f0100d6e <page_alloc>
f0101449:	89 c7                	mov    %eax,%edi
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	85 c0                	test   %eax,%eax
f0101450:	75 19                	jne    f010146b <mem_init+0x374>
f0101452:	68 3a 45 10 f0       	push   $0xf010453a
f0101457:	68 5a 44 10 f0       	push   $0xf010445a
f010145c:	68 8f 05 00 00       	push   $0x58f
f0101461:	68 34 44 10 f0       	push   $0xf0104434
f0101466:	e8 20 ec ff ff       	call   f010008b <_panic>

	assert((pp2 = page_alloc(0)));
f010146b:	83 ec 0c             	sub    $0xc,%esp
f010146e:	6a 00                	push   $0x0
f0101470:	e8 f9 f8 ff ff       	call   f0100d6e <page_alloc>
f0101475:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101478:	83 c4 10             	add    $0x10,%esp
f010147b:	85 c0                	test   %eax,%eax
f010147d:	75 19                	jne    f0101498 <mem_init+0x3a1>
f010147f:	68 50 45 10 f0       	push   $0xf0104550
f0101484:	68 5a 44 10 f0       	push   $0xf010445a
f0101489:	68 91 05 00 00       	push   $0x591
f010148e:	68 34 44 10 f0       	push   $0xf0104434
f0101493:	e8 f3 eb ff ff       	call   f010008b <_panic>

	assert(pp0);

	assert(pp1 && pp1 != pp0);
f0101498:	39 fe                	cmp    %edi,%esi
f010149a:	75 19                	jne    f01014b5 <mem_init+0x3be>
f010149c:	68 66 45 10 f0       	push   $0xf0104566
f01014a1:	68 5a 44 10 f0       	push   $0xf010445a
f01014a6:	68 95 05 00 00       	push   $0x595
f01014ab:	68 34 44 10 f0       	push   $0xf0104434
f01014b0:	e8 d6 eb ff ff       	call   f010008b <_panic>

	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014b8:	39 c7                	cmp    %eax,%edi
f01014ba:	74 04                	je     f01014c0 <mem_init+0x3c9>
f01014bc:	39 c6                	cmp    %eax,%esi
f01014be:	75 19                	jne    f01014d9 <mem_init+0x3e2>
f01014c0:	68 48 3e 10 f0       	push   $0xf0103e48
f01014c5:	68 5a 44 10 f0       	push   $0xf010445a
f01014ca:	68 97 05 00 00       	push   $0x597
f01014cf:	68 34 44 10 f0       	push   $0xf0104434
f01014d4:	e8 b2 eb ff ff       	call   f010008b <_panic>

	assert(!page_alloc(0));
f01014d9:	83 ec 0c             	sub    $0xc,%esp
f01014dc:	6a 00                	push   $0x0
f01014de:	e8 8b f8 ff ff       	call   f0100d6e <page_alloc>
f01014e3:	83 c4 10             	add    $0x10,%esp
f01014e6:	85 c0                	test   %eax,%eax
f01014e8:	74 19                	je     f0101503 <mem_init+0x40c>
f01014ea:	68 cf 45 10 f0       	push   $0xf01045cf
f01014ef:	68 5a 44 10 f0       	push   $0xf010445a
f01014f4:	68 99 05 00 00       	push   $0x599
f01014f9:	68 34 44 10 f0       	push   $0xf0104434
f01014fe:	e8 88 eb ff ff       	call   f010008b <_panic>
f0101503:	89 f0                	mov    %esi,%eax
f0101505:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010150b:	c1 f8 03             	sar    $0x3,%eax
f010150e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101511:	89 c2                	mov    %eax,%edx
f0101513:	c1 ea 0c             	shr    $0xc,%edx
f0101516:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010151c:	72 12                	jb     f0101530 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010151e:	50                   	push   %eax
f010151f:	68 84 3c 10 f0       	push   $0xf0103c84
f0101524:	6a 52                	push   $0x52
f0101526:	68 40 44 10 f0       	push   $0xf0104440
f010152b:	e8 5b eb ff ff       	call   f010008b <_panic>



	// test flags

	memset(page2kva(pp0), 1, PGSIZE);
f0101530:	83 ec 04             	sub    $0x4,%esp
f0101533:	68 00 10 00 00       	push   $0x1000
f0101538:	6a 01                	push   $0x1
f010153a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010153f:	50                   	push   %eax
f0101540:	e8 72 1d 00 00       	call   f01032b7 <memset>

	page_free(pp0);
f0101545:	89 34 24             	mov    %esi,(%esp)
f0101548:	e8 8b f8 ff ff       	call   f0100dd8 <page_free>

	assert((pp = page_alloc(ALLOC_ZERO)));
f010154d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101554:	e8 15 f8 ff ff       	call   f0100d6e <page_alloc>
f0101559:	83 c4 10             	add    $0x10,%esp
f010155c:	85 c0                	test   %eax,%eax
f010155e:	75 19                	jne    f0101579 <mem_init+0x482>
f0101560:	68 de 45 10 f0       	push   $0xf01045de
f0101565:	68 5a 44 10 f0       	push   $0xf010445a
f010156a:	68 a3 05 00 00       	push   $0x5a3
f010156f:	68 34 44 10 f0       	push   $0xf0104434
f0101574:	e8 12 eb ff ff       	call   f010008b <_panic>

	assert(pp && pp0 == pp);
f0101579:	39 c6                	cmp    %eax,%esi
f010157b:	74 19                	je     f0101596 <mem_init+0x49f>
f010157d:	68 fc 45 10 f0       	push   $0xf01045fc
f0101582:	68 5a 44 10 f0       	push   $0xf010445a
f0101587:	68 a5 05 00 00       	push   $0x5a5
f010158c:	68 34 44 10 f0       	push   $0xf0104434
f0101591:	e8 f5 ea ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101596:	89 f0                	mov    %esi,%eax
f0101598:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010159e:	c1 f8 03             	sar    $0x3,%eax
f01015a1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015a4:	89 c2                	mov    %eax,%edx
f01015a6:	c1 ea 0c             	shr    $0xc,%edx
f01015a9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01015af:	72 12                	jb     f01015c3 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015b1:	50                   	push   %eax
f01015b2:	68 84 3c 10 f0       	push   $0xf0103c84
f01015b7:	6a 52                	push   $0x52
f01015b9:	68 40 44 10 f0       	push   $0xf0104440
f01015be:	e8 c8 ea ff ff       	call   f010008b <_panic>
f01015c3:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015c9:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax

	c = page2kva(pp);

	for (i = 0; i < PGSIZE; i++)

		assert(c[i] == 0);
f01015cf:	80 38 00             	cmpb   $0x0,(%eax)
f01015d2:	74 19                	je     f01015ed <mem_init+0x4f6>
f01015d4:	68 0c 46 10 f0       	push   $0xf010460c
f01015d9:	68 5a 44 10 f0       	push   $0xf010445a
f01015de:	68 ab 05 00 00       	push   $0x5ab
f01015e3:	68 34 44 10 f0       	push   $0xf0104434
f01015e8:	e8 9e ea ff ff       	call   f010008b <_panic>
f01015ed:	83 c0 01             	add    $0x1,%eax

	assert(pp && pp0 == pp);

	c = page2kva(pp);

	for (i = 0; i < PGSIZE; i++)
f01015f0:	39 d0                	cmp    %edx,%eax
f01015f2:	75 db                	jne    f01015cf <mem_init+0x4d8>



	// give free list back

	page_free_list = fl;
f01015f4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015f7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c



	// free the pages we took

	page_free(pp0);
f01015fc:	83 ec 0c             	sub    $0xc,%esp
f01015ff:	56                   	push   %esi
f0101600:	e8 d3 f7 ff ff       	call   f0100dd8 <page_free>

	page_free(pp1);
f0101605:	89 3c 24             	mov    %edi,(%esp)
f0101608:	e8 cb f7 ff ff       	call   f0100dd8 <page_free>

	page_free(pp2);
f010160d:	83 c4 04             	add    $0x4,%esp
f0101610:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101613:	e8 c0 f7 ff ff       	call   f0100dd8 <page_free>



	// number of free pages should be the same

	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101618:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010161d:	83 c4 10             	add    $0x10,%esp
f0101620:	eb 05                	jmp    f0101627 <mem_init+0x530>

		--nfree;
f0101622:	83 eb 01             	sub    $0x1,%ebx



	// number of free pages should be the same

	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101625:	8b 00                	mov    (%eax),%eax
f0101627:	85 c0                	test   %eax,%eax
f0101629:	75 f7                	jne    f0101622 <mem_init+0x52b>

		--nfree;

	assert(nfree == 0);
f010162b:	85 db                	test   %ebx,%ebx
f010162d:	74 19                	je     f0101648 <mem_init+0x551>
f010162f:	68 16 46 10 f0       	push   $0xf0104616
f0101634:	68 5a 44 10 f0       	push   $0xf010445a
f0101639:	68 c5 05 00 00       	push   $0x5c5
f010163e:	68 34 44 10 f0       	push   $0xf0104434
f0101643:	e8 43 ea ff ff       	call   f010008b <_panic>



	cprintf("check_page_alloc() succeeded!\n");
f0101648:	83 ec 0c             	sub    $0xc,%esp
f010164b:	68 68 3e 10 f0       	push   $0xf0103e68
f0101650:	e8 a9 11 00 00       	call   f01027fe <cprintf>

	// should be able to allocate three pages

	pp0 = pp1 = pp2 = 0;

	assert((pp0 = page_alloc(0)));
f0101655:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010165c:	e8 0d f7 ff ff       	call   f0100d6e <page_alloc>
f0101661:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101664:	83 c4 10             	add    $0x10,%esp
f0101667:	85 c0                	test   %eax,%eax
f0101669:	75 19                	jne    f0101684 <mem_init+0x58d>
f010166b:	68 24 45 10 f0       	push   $0xf0104524
f0101670:	68 5a 44 10 f0       	push   $0xf010445a
f0101675:	68 77 06 00 00       	push   $0x677
f010167a:	68 34 44 10 f0       	push   $0xf0104434
f010167f:	e8 07 ea ff ff       	call   f010008b <_panic>

	assert((pp1 = page_alloc(0)));
f0101684:	83 ec 0c             	sub    $0xc,%esp
f0101687:	6a 00                	push   $0x0
f0101689:	e8 e0 f6 ff ff       	call   f0100d6e <page_alloc>
f010168e:	89 c3                	mov    %eax,%ebx
f0101690:	83 c4 10             	add    $0x10,%esp
f0101693:	85 c0                	test   %eax,%eax
f0101695:	75 19                	jne    f01016b0 <mem_init+0x5b9>
f0101697:	68 3a 45 10 f0       	push   $0xf010453a
f010169c:	68 5a 44 10 f0       	push   $0xf010445a
f01016a1:	68 79 06 00 00       	push   $0x679
f01016a6:	68 34 44 10 f0       	push   $0xf0104434
f01016ab:	e8 db e9 ff ff       	call   f010008b <_panic>

	assert((pp2 = page_alloc(0)));
f01016b0:	83 ec 0c             	sub    $0xc,%esp
f01016b3:	6a 00                	push   $0x0
f01016b5:	e8 b4 f6 ff ff       	call   f0100d6e <page_alloc>
f01016ba:	89 c6                	mov    %eax,%esi
f01016bc:	83 c4 10             	add    $0x10,%esp
f01016bf:	85 c0                	test   %eax,%eax
f01016c1:	75 19                	jne    f01016dc <mem_init+0x5e5>
f01016c3:	68 50 45 10 f0       	push   $0xf0104550
f01016c8:	68 5a 44 10 f0       	push   $0xf010445a
f01016cd:	68 7b 06 00 00       	push   $0x67b
f01016d2:	68 34 44 10 f0       	push   $0xf0104434
f01016d7:	e8 af e9 ff ff       	call   f010008b <_panic>



	assert(pp0);

	assert(pp1 && pp1 != pp0);
f01016dc:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016df:	75 19                	jne    f01016fa <mem_init+0x603>
f01016e1:	68 66 45 10 f0       	push   $0xf0104566
f01016e6:	68 5a 44 10 f0       	push   $0xf010445a
f01016eb:	68 81 06 00 00       	push   $0x681
f01016f0:	68 34 44 10 f0       	push   $0xf0104434
f01016f5:	e8 91 e9 ff ff       	call   f010008b <_panic>

	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016fa:	39 c3                	cmp    %eax,%ebx
f01016fc:	74 05                	je     f0101703 <mem_init+0x60c>
f01016fe:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101701:	75 19                	jne    f010171c <mem_init+0x625>
f0101703:	68 48 3e 10 f0       	push   $0xf0103e48
f0101708:	68 5a 44 10 f0       	push   $0xf010445a
f010170d:	68 83 06 00 00       	push   $0x683
f0101712:	68 34 44 10 f0       	push   $0xf0104434
f0101717:	e8 6f e9 ff ff       	call   f010008b <_panic>



	// temporarily steal the rest of the free pages

	fl = page_free_list;
f010171c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101721:	89 45 d0             	mov    %eax,-0x30(%ebp)

	page_free_list = 0;
f0101724:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010172b:	00 00 00 



	// should be no free memory

	assert(!page_alloc(0));
f010172e:	83 ec 0c             	sub    $0xc,%esp
f0101731:	6a 00                	push   $0x0
f0101733:	e8 36 f6 ff ff       	call   f0100d6e <page_alloc>
f0101738:	83 c4 10             	add    $0x10,%esp
f010173b:	85 c0                	test   %eax,%eax
f010173d:	74 19                	je     f0101758 <mem_init+0x661>
f010173f:	68 cf 45 10 f0       	push   $0xf01045cf
f0101744:	68 5a 44 10 f0       	push   $0xf010445a
f0101749:	68 91 06 00 00       	push   $0x691
f010174e:	68 34 44 10 f0       	push   $0xf0104434
f0101753:	e8 33 e9 ff ff       	call   f010008b <_panic>



	// there is no page allocated at address 0

	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101758:	83 ec 04             	sub    $0x4,%esp
f010175b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010175e:	50                   	push   %eax
f010175f:	6a 00                	push   $0x0
f0101761:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101767:	e8 58 f8 ff ff       	call   f0100fc4 <page_lookup>
f010176c:	83 c4 10             	add    $0x10,%esp
f010176f:	85 c0                	test   %eax,%eax
f0101771:	74 19                	je     f010178c <mem_init+0x695>
f0101773:	68 88 3e 10 f0       	push   $0xf0103e88
f0101778:	68 5a 44 10 f0       	push   $0xf010445a
f010177d:	68 97 06 00 00       	push   $0x697
f0101782:	68 34 44 10 f0       	push   $0xf0104434
f0101787:	e8 ff e8 ff ff       	call   f010008b <_panic>



	// there is no free memory, so we can't allocate a page table

	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010178c:	6a 02                	push   $0x2
f010178e:	6a 00                	push   $0x0
f0101790:	53                   	push   %ebx
f0101791:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101797:	e8 c8 f8 ff ff       	call   f0101064 <page_insert>
f010179c:	83 c4 10             	add    $0x10,%esp
f010179f:	85 c0                	test   %eax,%eax
f01017a1:	78 19                	js     f01017bc <mem_init+0x6c5>
f01017a3:	68 c0 3e 10 f0       	push   $0xf0103ec0
f01017a8:	68 5a 44 10 f0       	push   $0xf010445a
f01017ad:	68 9d 06 00 00       	push   $0x69d
f01017b2:	68 34 44 10 f0       	push   $0xf0104434
f01017b7:	e8 cf e8 ff ff       	call   f010008b <_panic>



	// free pp0 and try again: pp0 should be used for page table

	page_free(pp0);
f01017bc:	83 ec 0c             	sub    $0xc,%esp
f01017bf:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017c2:	e8 11 f6 ff ff       	call   f0100dd8 <page_free>

	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017c7:	6a 02                	push   $0x2
f01017c9:	6a 00                	push   $0x0
f01017cb:	53                   	push   %ebx
f01017cc:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017d2:	e8 8d f8 ff ff       	call   f0101064 <page_insert>
f01017d7:	83 c4 20             	add    $0x20,%esp
f01017da:	85 c0                	test   %eax,%eax
f01017dc:	74 19                	je     f01017f7 <mem_init+0x700>
f01017de:	68 f0 3e 10 f0       	push   $0xf0103ef0
f01017e3:	68 5a 44 10 f0       	push   $0xf010445a
f01017e8:	68 a5 06 00 00       	push   $0x6a5
f01017ed:	68 34 44 10 f0       	push   $0xf0104434
f01017f2:	e8 94 e8 ff ff       	call   f010008b <_panic>

	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017f7:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017fd:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101802:	89 c1                	mov    %eax,%ecx
f0101804:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101807:	8b 17                	mov    (%edi),%edx
f0101809:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010180f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101812:	29 c8                	sub    %ecx,%eax
f0101814:	c1 f8 03             	sar    $0x3,%eax
f0101817:	c1 e0 0c             	shl    $0xc,%eax
f010181a:	39 c2                	cmp    %eax,%edx
f010181c:	74 19                	je     f0101837 <mem_init+0x740>
f010181e:	68 20 3f 10 f0       	push   $0xf0103f20
f0101823:	68 5a 44 10 f0       	push   $0xf010445a
f0101828:	68 a7 06 00 00       	push   $0x6a7
f010182d:	68 34 44 10 f0       	push   $0xf0104434
f0101832:	e8 54 e8 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101837:	ba 00 00 00 00       	mov    $0x0,%edx
f010183c:	89 f8                	mov    %edi,%eax
f010183e:	e8 f2 f0 ff ff       	call   f0100935 <check_va2pa>
f0101843:	89 da                	mov    %ebx,%edx
f0101845:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101848:	c1 fa 03             	sar    $0x3,%edx
f010184b:	c1 e2 0c             	shl    $0xc,%edx
f010184e:	39 d0                	cmp    %edx,%eax
f0101850:	74 19                	je     f010186b <mem_init+0x774>
f0101852:	68 48 3f 10 f0       	push   $0xf0103f48
f0101857:	68 5a 44 10 f0       	push   $0xf010445a
f010185c:	68 a9 06 00 00       	push   $0x6a9
f0101861:	68 34 44 10 f0       	push   $0xf0104434
f0101866:	e8 20 e8 ff ff       	call   f010008b <_panic>

	assert(pp1->pp_ref == 1);
f010186b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101870:	74 19                	je     f010188b <mem_init+0x794>
f0101872:	68 21 46 10 f0       	push   $0xf0104621
f0101877:	68 5a 44 10 f0       	push   $0xf010445a
f010187c:	68 ab 06 00 00       	push   $0x6ab
f0101881:	68 34 44 10 f0       	push   $0xf0104434
f0101886:	e8 00 e8 ff ff       	call   f010008b <_panic>

	assert(pp0->pp_ref == 1);
f010188b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010188e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101893:	74 19                	je     f01018ae <mem_init+0x7b7>
f0101895:	68 32 46 10 f0       	push   $0xf0104632
f010189a:	68 5a 44 10 f0       	push   $0xf010445a
f010189f:	68 ad 06 00 00       	push   $0x6ad
f01018a4:	68 34 44 10 f0       	push   $0xf0104434
f01018a9:	e8 dd e7 ff ff       	call   f010008b <_panic>



	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table

	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018ae:	6a 02                	push   $0x2
f01018b0:	68 00 10 00 00       	push   $0x1000
f01018b5:	56                   	push   %esi
f01018b6:	57                   	push   %edi
f01018b7:	e8 a8 f7 ff ff       	call   f0101064 <page_insert>
f01018bc:	83 c4 10             	add    $0x10,%esp
f01018bf:	85 c0                	test   %eax,%eax
f01018c1:	74 19                	je     f01018dc <mem_init+0x7e5>
f01018c3:	68 78 3f 10 f0       	push   $0xf0103f78
f01018c8:	68 5a 44 10 f0       	push   $0xf010445a
f01018cd:	68 b3 06 00 00       	push   $0x6b3
f01018d2:	68 34 44 10 f0       	push   $0xf0104434
f01018d7:	e8 af e7 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018dc:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018e1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01018e6:	e8 4a f0 ff ff       	call   f0100935 <check_va2pa>
f01018eb:	89 f2                	mov    %esi,%edx
f01018ed:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01018f3:	c1 fa 03             	sar    $0x3,%edx
f01018f6:	c1 e2 0c             	shl    $0xc,%edx
f01018f9:	39 d0                	cmp    %edx,%eax
f01018fb:	74 19                	je     f0101916 <mem_init+0x81f>
f01018fd:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0101902:	68 5a 44 10 f0       	push   $0xf010445a
f0101907:	68 b5 06 00 00       	push   $0x6b5
f010190c:	68 34 44 10 f0       	push   $0xf0104434
f0101911:	e8 75 e7 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 1);
f0101916:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010191b:	74 19                	je     f0101936 <mem_init+0x83f>
f010191d:	68 43 46 10 f0       	push   $0xf0104643
f0101922:	68 5a 44 10 f0       	push   $0xf010445a
f0101927:	68 b7 06 00 00       	push   $0x6b7
f010192c:	68 34 44 10 f0       	push   $0xf0104434
f0101931:	e8 55 e7 ff ff       	call   f010008b <_panic>



	// should be no free memory

	assert(!page_alloc(0));
f0101936:	83 ec 0c             	sub    $0xc,%esp
f0101939:	6a 00                	push   $0x0
f010193b:	e8 2e f4 ff ff       	call   f0100d6e <page_alloc>
f0101940:	83 c4 10             	add    $0x10,%esp
f0101943:	85 c0                	test   %eax,%eax
f0101945:	74 19                	je     f0101960 <mem_init+0x869>
f0101947:	68 cf 45 10 f0       	push   $0xf01045cf
f010194c:	68 5a 44 10 f0       	push   $0xf010445a
f0101951:	68 bd 06 00 00       	push   $0x6bd
f0101956:	68 34 44 10 f0       	push   $0xf0104434
f010195b:	e8 2b e7 ff ff       	call   f010008b <_panic>



	// should be able to map pp2 at PGSIZE because it's already there

	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101960:	6a 02                	push   $0x2
f0101962:	68 00 10 00 00       	push   $0x1000
f0101967:	56                   	push   %esi
f0101968:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010196e:	e8 f1 f6 ff ff       	call   f0101064 <page_insert>
f0101973:	83 c4 10             	add    $0x10,%esp
f0101976:	85 c0                	test   %eax,%eax
f0101978:	74 19                	je     f0101993 <mem_init+0x89c>
f010197a:	68 78 3f 10 f0       	push   $0xf0103f78
f010197f:	68 5a 44 10 f0       	push   $0xf010445a
f0101984:	68 c3 06 00 00       	push   $0x6c3
f0101989:	68 34 44 10 f0       	push   $0xf0104434
f010198e:	e8 f8 e6 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101993:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101998:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010199d:	e8 93 ef ff ff       	call   f0100935 <check_va2pa>
f01019a2:	89 f2                	mov    %esi,%edx
f01019a4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019aa:	c1 fa 03             	sar    $0x3,%edx
f01019ad:	c1 e2 0c             	shl    $0xc,%edx
f01019b0:	39 d0                	cmp    %edx,%eax
f01019b2:	74 19                	je     f01019cd <mem_init+0x8d6>
f01019b4:	68 b4 3f 10 f0       	push   $0xf0103fb4
f01019b9:	68 5a 44 10 f0       	push   $0xf010445a
f01019be:	68 c5 06 00 00       	push   $0x6c5
f01019c3:	68 34 44 10 f0       	push   $0xf0104434
f01019c8:	e8 be e6 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 1);
f01019cd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019d2:	74 19                	je     f01019ed <mem_init+0x8f6>
f01019d4:	68 43 46 10 f0       	push   $0xf0104643
f01019d9:	68 5a 44 10 f0       	push   $0xf010445a
f01019de:	68 c7 06 00 00       	push   $0x6c7
f01019e3:	68 34 44 10 f0       	push   $0xf0104434
f01019e8:	e8 9e e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list

	// could happen in ref counts are handled sloppily in page_insert

	assert(!page_alloc(0));
f01019ed:	83 ec 0c             	sub    $0xc,%esp
f01019f0:	6a 00                	push   $0x0
f01019f2:	e8 77 f3 ff ff       	call   f0100d6e <page_alloc>
f01019f7:	83 c4 10             	add    $0x10,%esp
f01019fa:	85 c0                	test   %eax,%eax
f01019fc:	74 19                	je     f0101a17 <mem_init+0x920>
f01019fe:	68 cf 45 10 f0       	push   $0xf01045cf
f0101a03:	68 5a 44 10 f0       	push   $0xf010445a
f0101a08:	68 cf 06 00 00       	push   $0x6cf
f0101a0d:	68 34 44 10 f0       	push   $0xf0104434
f0101a12:	e8 74 e6 ff ff       	call   f010008b <_panic>



	// check that pgdir_walk returns a pointer to the pte

	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a17:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101a1d:	8b 02                	mov    (%edx),%eax
f0101a1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a24:	89 c1                	mov    %eax,%ecx
f0101a26:	c1 e9 0c             	shr    $0xc,%ecx
f0101a29:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101a2f:	72 15                	jb     f0101a46 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a31:	50                   	push   %eax
f0101a32:	68 84 3c 10 f0       	push   $0xf0103c84
f0101a37:	68 d5 06 00 00       	push   $0x6d5
f0101a3c:	68 34 44 10 f0       	push   $0xf0104434
f0101a41:	e8 45 e6 ff ff       	call   f010008b <_panic>
f0101a46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a4e:	83 ec 04             	sub    $0x4,%esp
f0101a51:	6a 00                	push   $0x0
f0101a53:	68 00 10 00 00       	push   $0x1000
f0101a58:	52                   	push   %edx
f0101a59:	e8 de f3 ff ff       	call   f0100e3c <pgdir_walk>
f0101a5e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101a61:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a64:	83 c4 10             	add    $0x10,%esp
f0101a67:	39 d0                	cmp    %edx,%eax
f0101a69:	74 19                	je     f0101a84 <mem_init+0x98d>
f0101a6b:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101a70:	68 5a 44 10 f0       	push   $0xf010445a
f0101a75:	68 d7 06 00 00       	push   $0x6d7
f0101a7a:	68 34 44 10 f0       	push   $0xf0104434
f0101a7f:	e8 07 e6 ff ff       	call   f010008b <_panic>



	// should be able to change permissions too.

	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a84:	6a 06                	push   $0x6
f0101a86:	68 00 10 00 00       	push   $0x1000
f0101a8b:	56                   	push   %esi
f0101a8c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a92:	e8 cd f5 ff ff       	call   f0101064 <page_insert>
f0101a97:	83 c4 10             	add    $0x10,%esp
f0101a9a:	85 c0                	test   %eax,%eax
f0101a9c:	74 19                	je     f0101ab7 <mem_init+0x9c0>
f0101a9e:	68 24 40 10 f0       	push   $0xf0104024
f0101aa3:	68 5a 44 10 f0       	push   $0xf010445a
f0101aa8:	68 dd 06 00 00       	push   $0x6dd
f0101aad:	68 34 44 10 f0       	push   $0xf0104434
f0101ab2:	e8 d4 e5 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ab7:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101abd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac2:	89 f8                	mov    %edi,%eax
f0101ac4:	e8 6c ee ff ff       	call   f0100935 <check_va2pa>
f0101ac9:	89 f2                	mov    %esi,%edx
f0101acb:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101ad1:	c1 fa 03             	sar    $0x3,%edx
f0101ad4:	c1 e2 0c             	shl    $0xc,%edx
f0101ad7:	39 d0                	cmp    %edx,%eax
f0101ad9:	74 19                	je     f0101af4 <mem_init+0x9fd>
f0101adb:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0101ae0:	68 5a 44 10 f0       	push   $0xf010445a
f0101ae5:	68 df 06 00 00       	push   $0x6df
f0101aea:	68 34 44 10 f0       	push   $0xf0104434
f0101aef:	e8 97 e5 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 1);
f0101af4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101af9:	74 19                	je     f0101b14 <mem_init+0xa1d>
f0101afb:	68 43 46 10 f0       	push   $0xf0104643
f0101b00:	68 5a 44 10 f0       	push   $0xf010445a
f0101b05:	68 e1 06 00 00       	push   $0x6e1
f0101b0a:	68 34 44 10 f0       	push   $0xf0104434
f0101b0f:	e8 77 e5 ff ff       	call   f010008b <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b14:	83 ec 04             	sub    $0x4,%esp
f0101b17:	6a 00                	push   $0x0
f0101b19:	68 00 10 00 00       	push   $0x1000
f0101b1e:	57                   	push   %edi
f0101b1f:	e8 18 f3 ff ff       	call   f0100e3c <pgdir_walk>
f0101b24:	83 c4 10             	add    $0x10,%esp
f0101b27:	f6 00 04             	testb  $0x4,(%eax)
f0101b2a:	75 19                	jne    f0101b45 <mem_init+0xa4e>
f0101b2c:	68 64 40 10 f0       	push   $0xf0104064
f0101b31:	68 5a 44 10 f0       	push   $0xf010445a
f0101b36:	68 e3 06 00 00       	push   $0x6e3
f0101b3b:	68 34 44 10 f0       	push   $0xf0104434
f0101b40:	e8 46 e5 ff ff       	call   f010008b <_panic>

	assert(kern_pgdir[0] & PTE_U);
f0101b45:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b4a:	f6 00 04             	testb  $0x4,(%eax)
f0101b4d:	75 19                	jne    f0101b68 <mem_init+0xa71>
f0101b4f:	68 54 46 10 f0       	push   $0xf0104654
f0101b54:	68 5a 44 10 f0       	push   $0xf010445a
f0101b59:	68 e5 06 00 00       	push   $0x6e5
f0101b5e:	68 34 44 10 f0       	push   $0xf0104434
f0101b63:	e8 23 e5 ff ff       	call   f010008b <_panic>



	// should be able to remap with fewer permissions

	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b68:	6a 02                	push   $0x2
f0101b6a:	68 00 10 00 00       	push   $0x1000
f0101b6f:	56                   	push   %esi
f0101b70:	50                   	push   %eax
f0101b71:	e8 ee f4 ff ff       	call   f0101064 <page_insert>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	74 19                	je     f0101b96 <mem_init+0xa9f>
f0101b7d:	68 78 3f 10 f0       	push   $0xf0103f78
f0101b82:	68 5a 44 10 f0       	push   $0xf010445a
f0101b87:	68 eb 06 00 00       	push   $0x6eb
f0101b8c:	68 34 44 10 f0       	push   $0xf0104434
f0101b91:	e8 f5 e4 ff ff       	call   f010008b <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b96:	83 ec 04             	sub    $0x4,%esp
f0101b99:	6a 00                	push   $0x0
f0101b9b:	68 00 10 00 00       	push   $0x1000
f0101ba0:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ba6:	e8 91 f2 ff ff       	call   f0100e3c <pgdir_walk>
f0101bab:	83 c4 10             	add    $0x10,%esp
f0101bae:	f6 00 02             	testb  $0x2,(%eax)
f0101bb1:	75 19                	jne    f0101bcc <mem_init+0xad5>
f0101bb3:	68 98 40 10 f0       	push   $0xf0104098
f0101bb8:	68 5a 44 10 f0       	push   $0xf010445a
f0101bbd:	68 ed 06 00 00       	push   $0x6ed
f0101bc2:	68 34 44 10 f0       	push   $0xf0104434
f0101bc7:	e8 bf e4 ff ff       	call   f010008b <_panic>

	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bcc:	83 ec 04             	sub    $0x4,%esp
f0101bcf:	6a 00                	push   $0x0
f0101bd1:	68 00 10 00 00       	push   $0x1000
f0101bd6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bdc:	e8 5b f2 ff ff       	call   f0100e3c <pgdir_walk>
f0101be1:	83 c4 10             	add    $0x10,%esp
f0101be4:	f6 00 04             	testb  $0x4,(%eax)
f0101be7:	74 19                	je     f0101c02 <mem_init+0xb0b>
f0101be9:	68 cc 40 10 f0       	push   $0xf01040cc
f0101bee:	68 5a 44 10 f0       	push   $0xf010445a
f0101bf3:	68 ef 06 00 00       	push   $0x6ef
f0101bf8:	68 34 44 10 f0       	push   $0xf0104434
f0101bfd:	e8 89 e4 ff ff       	call   f010008b <_panic>



	// should not be able to map at PTSIZE because need free page for page table

	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c02:	6a 02                	push   $0x2
f0101c04:	68 00 00 40 00       	push   $0x400000
f0101c09:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c0c:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c12:	e8 4d f4 ff ff       	call   f0101064 <page_insert>
f0101c17:	83 c4 10             	add    $0x10,%esp
f0101c1a:	85 c0                	test   %eax,%eax
f0101c1c:	78 19                	js     f0101c37 <mem_init+0xb40>
f0101c1e:	68 04 41 10 f0       	push   $0xf0104104
f0101c23:	68 5a 44 10 f0       	push   $0xf010445a
f0101c28:	68 f5 06 00 00       	push   $0x6f5
f0101c2d:	68 34 44 10 f0       	push   $0xf0104434
f0101c32:	e8 54 e4 ff ff       	call   f010008b <_panic>



	// insert pp1 at PGSIZE (replacing pp2)

	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c37:	6a 02                	push   $0x2
f0101c39:	68 00 10 00 00       	push   $0x1000
f0101c3e:	53                   	push   %ebx
f0101c3f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c45:	e8 1a f4 ff ff       	call   f0101064 <page_insert>
f0101c4a:	83 c4 10             	add    $0x10,%esp
f0101c4d:	85 c0                	test   %eax,%eax
f0101c4f:	74 19                	je     f0101c6a <mem_init+0xb73>
f0101c51:	68 3c 41 10 f0       	push   $0xf010413c
f0101c56:	68 5a 44 10 f0       	push   $0xf010445a
f0101c5b:	68 fb 06 00 00       	push   $0x6fb
f0101c60:	68 34 44 10 f0       	push   $0xf0104434
f0101c65:	e8 21 e4 ff ff       	call   f010008b <_panic>

	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c6a:	83 ec 04             	sub    $0x4,%esp
f0101c6d:	6a 00                	push   $0x0
f0101c6f:	68 00 10 00 00       	push   $0x1000
f0101c74:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c7a:	e8 bd f1 ff ff       	call   f0100e3c <pgdir_walk>
f0101c7f:	83 c4 10             	add    $0x10,%esp
f0101c82:	f6 00 04             	testb  $0x4,(%eax)
f0101c85:	74 19                	je     f0101ca0 <mem_init+0xba9>
f0101c87:	68 cc 40 10 f0       	push   $0xf01040cc
f0101c8c:	68 5a 44 10 f0       	push   $0xf010445a
f0101c91:	68 fd 06 00 00       	push   $0x6fd
f0101c96:	68 34 44 10 f0       	push   $0xf0104434
f0101c9b:	e8 eb e3 ff ff       	call   f010008b <_panic>



	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...

	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ca0:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101ca6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cab:	89 f8                	mov    %edi,%eax
f0101cad:	e8 83 ec ff ff       	call   f0100935 <check_va2pa>
f0101cb2:	89 c1                	mov    %eax,%ecx
f0101cb4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cb7:	89 d8                	mov    %ebx,%eax
f0101cb9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101cbf:	c1 f8 03             	sar    $0x3,%eax
f0101cc2:	c1 e0 0c             	shl    $0xc,%eax
f0101cc5:	39 c1                	cmp    %eax,%ecx
f0101cc7:	74 19                	je     f0101ce2 <mem_init+0xbeb>
f0101cc9:	68 78 41 10 f0       	push   $0xf0104178
f0101cce:	68 5a 44 10 f0       	push   $0xf010445a
f0101cd3:	68 03 07 00 00       	push   $0x703
f0101cd8:	68 34 44 10 f0       	push   $0xf0104434
f0101cdd:	e8 a9 e3 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ce2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce7:	89 f8                	mov    %edi,%eax
f0101ce9:	e8 47 ec ff ff       	call   f0100935 <check_va2pa>
f0101cee:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cf1:	74 19                	je     f0101d0c <mem_init+0xc15>
f0101cf3:	68 a4 41 10 f0       	push   $0xf01041a4
f0101cf8:	68 5a 44 10 f0       	push   $0xf010445a
f0101cfd:	68 05 07 00 00       	push   $0x705
f0101d02:	68 34 44 10 f0       	push   $0xf0104434
f0101d07:	e8 7f e3 ff ff       	call   f010008b <_panic>

	// ... and ref counts should reflect this

	assert(pp1->pp_ref == 2);
f0101d0c:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d11:	74 19                	je     f0101d2c <mem_init+0xc35>
f0101d13:	68 6a 46 10 f0       	push   $0xf010466a
f0101d18:	68 5a 44 10 f0       	push   $0xf010445a
f0101d1d:	68 09 07 00 00       	push   $0x709
f0101d22:	68 34 44 10 f0       	push   $0xf0104434
f0101d27:	e8 5f e3 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 0);
f0101d2c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d31:	74 19                	je     f0101d4c <mem_init+0xc55>
f0101d33:	68 7b 46 10 f0       	push   $0xf010467b
f0101d38:	68 5a 44 10 f0       	push   $0xf010445a
f0101d3d:	68 0b 07 00 00       	push   $0x70b
f0101d42:	68 34 44 10 f0       	push   $0xf0104434
f0101d47:	e8 3f e3 ff ff       	call   f010008b <_panic>



	// pp2 should be returned by page_alloc

	assert((pp = page_alloc(0)) && pp == pp2);
f0101d4c:	83 ec 0c             	sub    $0xc,%esp
f0101d4f:	6a 00                	push   $0x0
f0101d51:	e8 18 f0 ff ff       	call   f0100d6e <page_alloc>
f0101d56:	83 c4 10             	add    $0x10,%esp
f0101d59:	85 c0                	test   %eax,%eax
f0101d5b:	74 04                	je     f0101d61 <mem_init+0xc6a>
f0101d5d:	39 c6                	cmp    %eax,%esi
f0101d5f:	74 19                	je     f0101d7a <mem_init+0xc83>
f0101d61:	68 d4 41 10 f0       	push   $0xf01041d4
f0101d66:	68 5a 44 10 f0       	push   $0xf010445a
f0101d6b:	68 11 07 00 00       	push   $0x711
f0101d70:	68 34 44 10 f0       	push   $0xf0104434
f0101d75:	e8 11 e3 ff ff       	call   f010008b <_panic>



	// unmapping pp1 at 0 should keep pp1 at PGSIZE

	page_remove(kern_pgdir, 0x0);
f0101d7a:	83 ec 08             	sub    $0x8,%esp
f0101d7d:	6a 00                	push   $0x0
f0101d7f:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d85:	e8 8c f2 ff ff       	call   f0101016 <page_remove>

	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d8a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d90:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d95:	89 f8                	mov    %edi,%eax
f0101d97:	e8 99 eb ff ff       	call   f0100935 <check_va2pa>
f0101d9c:	83 c4 10             	add    $0x10,%esp
f0101d9f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101da2:	74 19                	je     f0101dbd <mem_init+0xcc6>
f0101da4:	68 f8 41 10 f0       	push   $0xf01041f8
f0101da9:	68 5a 44 10 f0       	push   $0xf010445a
f0101dae:	68 19 07 00 00       	push   $0x719
f0101db3:	68 34 44 10 f0       	push   $0xf0104434
f0101db8:	e8 ce e2 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc2:	89 f8                	mov    %edi,%eax
f0101dc4:	e8 6c eb ff ff       	call   f0100935 <check_va2pa>
f0101dc9:	89 da                	mov    %ebx,%edx
f0101dcb:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dd1:	c1 fa 03             	sar    $0x3,%edx
f0101dd4:	c1 e2 0c             	shl    $0xc,%edx
f0101dd7:	39 d0                	cmp    %edx,%eax
f0101dd9:	74 19                	je     f0101df4 <mem_init+0xcfd>
f0101ddb:	68 a4 41 10 f0       	push   $0xf01041a4
f0101de0:	68 5a 44 10 f0       	push   $0xf010445a
f0101de5:	68 1b 07 00 00       	push   $0x71b
f0101dea:	68 34 44 10 f0       	push   $0xf0104434
f0101def:	e8 97 e2 ff ff       	call   f010008b <_panic>

	assert(pp1->pp_ref == 1);
f0101df4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101df9:	74 19                	je     f0101e14 <mem_init+0xd1d>
f0101dfb:	68 21 46 10 f0       	push   $0xf0104621
f0101e00:	68 5a 44 10 f0       	push   $0xf010445a
f0101e05:	68 1d 07 00 00       	push   $0x71d
f0101e0a:	68 34 44 10 f0       	push   $0xf0104434
f0101e0f:	e8 77 e2 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 0);
f0101e14:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e19:	74 19                	je     f0101e34 <mem_init+0xd3d>
f0101e1b:	68 7b 46 10 f0       	push   $0xf010467b
f0101e20:	68 5a 44 10 f0       	push   $0xf010445a
f0101e25:	68 1f 07 00 00       	push   $0x71f
f0101e2a:	68 34 44 10 f0       	push   $0xf0104434
f0101e2f:	e8 57 e2 ff ff       	call   f010008b <_panic>



	// test re-inserting pp1 at PGSIZE

	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e34:	6a 00                	push   $0x0
f0101e36:	68 00 10 00 00       	push   $0x1000
f0101e3b:	53                   	push   %ebx
f0101e3c:	57                   	push   %edi
f0101e3d:	e8 22 f2 ff ff       	call   f0101064 <page_insert>
f0101e42:	83 c4 10             	add    $0x10,%esp
f0101e45:	85 c0                	test   %eax,%eax
f0101e47:	74 19                	je     f0101e62 <mem_init+0xd6b>
f0101e49:	68 1c 42 10 f0       	push   $0xf010421c
f0101e4e:	68 5a 44 10 f0       	push   $0xf010445a
f0101e53:	68 25 07 00 00       	push   $0x725
f0101e58:	68 34 44 10 f0       	push   $0xf0104434
f0101e5d:	e8 29 e2 ff ff       	call   f010008b <_panic>

	assert(pp1->pp_ref);
f0101e62:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e67:	75 19                	jne    f0101e82 <mem_init+0xd8b>
f0101e69:	68 8c 46 10 f0       	push   $0xf010468c
f0101e6e:	68 5a 44 10 f0       	push   $0xf010445a
f0101e73:	68 27 07 00 00       	push   $0x727
f0101e78:	68 34 44 10 f0       	push   $0xf0104434
f0101e7d:	e8 09 e2 ff ff       	call   f010008b <_panic>

	assert(pp1->pp_link == NULL);
f0101e82:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e85:	74 19                	je     f0101ea0 <mem_init+0xda9>
f0101e87:	68 98 46 10 f0       	push   $0xf0104698
f0101e8c:	68 5a 44 10 f0       	push   $0xf010445a
f0101e91:	68 29 07 00 00       	push   $0x729
f0101e96:	68 34 44 10 f0       	push   $0xf0104434
f0101e9b:	e8 eb e1 ff ff       	call   f010008b <_panic>



	// unmapping pp1 at PGSIZE should free it

	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ea0:	83 ec 08             	sub    $0x8,%esp
f0101ea3:	68 00 10 00 00       	push   $0x1000
f0101ea8:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101eae:	e8 63 f1 ff ff       	call   f0101016 <page_remove>

	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eb3:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101eb9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ebe:	89 f8                	mov    %edi,%eax
f0101ec0:	e8 70 ea ff ff       	call   f0100935 <check_va2pa>
f0101ec5:	83 c4 10             	add    $0x10,%esp
f0101ec8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ecb:	74 19                	je     f0101ee6 <mem_init+0xdef>
f0101ecd:	68 f8 41 10 f0       	push   $0xf01041f8
f0101ed2:	68 5a 44 10 f0       	push   $0xf010445a
f0101ed7:	68 31 07 00 00       	push   $0x731
f0101edc:	68 34 44 10 f0       	push   $0xf0104434
f0101ee1:	e8 a5 e1 ff ff       	call   f010008b <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101ee6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eeb:	89 f8                	mov    %edi,%eax
f0101eed:	e8 43 ea ff ff       	call   f0100935 <check_va2pa>
f0101ef2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ef5:	74 19                	je     f0101f10 <mem_init+0xe19>
f0101ef7:	68 54 42 10 f0       	push   $0xf0104254
f0101efc:	68 5a 44 10 f0       	push   $0xf010445a
f0101f01:	68 33 07 00 00       	push   $0x733
f0101f06:	68 34 44 10 f0       	push   $0xf0104434
f0101f0b:	e8 7b e1 ff ff       	call   f010008b <_panic>

	assert(pp1->pp_ref == 0);
f0101f10:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f15:	74 19                	je     f0101f30 <mem_init+0xe39>
f0101f17:	68 ad 46 10 f0       	push   $0xf01046ad
f0101f1c:	68 5a 44 10 f0       	push   $0xf010445a
f0101f21:	68 35 07 00 00       	push   $0x735
f0101f26:	68 34 44 10 f0       	push   $0xf0104434
f0101f2b:	e8 5b e1 ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 0);
f0101f30:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f35:	74 19                	je     f0101f50 <mem_init+0xe59>
f0101f37:	68 7b 46 10 f0       	push   $0xf010467b
f0101f3c:	68 5a 44 10 f0       	push   $0xf010445a
f0101f41:	68 37 07 00 00       	push   $0x737
f0101f46:	68 34 44 10 f0       	push   $0xf0104434
f0101f4b:	e8 3b e1 ff ff       	call   f010008b <_panic>



	// so it should be returned by page_alloc

	assert((pp = page_alloc(0)) && pp == pp1);
f0101f50:	83 ec 0c             	sub    $0xc,%esp
f0101f53:	6a 00                	push   $0x0
f0101f55:	e8 14 ee ff ff       	call   f0100d6e <page_alloc>
f0101f5a:	83 c4 10             	add    $0x10,%esp
f0101f5d:	39 c3                	cmp    %eax,%ebx
f0101f5f:	75 04                	jne    f0101f65 <mem_init+0xe6e>
f0101f61:	85 c0                	test   %eax,%eax
f0101f63:	75 19                	jne    f0101f7e <mem_init+0xe87>
f0101f65:	68 7c 42 10 f0       	push   $0xf010427c
f0101f6a:	68 5a 44 10 f0       	push   $0xf010445a
f0101f6f:	68 3d 07 00 00       	push   $0x73d
f0101f74:	68 34 44 10 f0       	push   $0xf0104434
f0101f79:	e8 0d e1 ff ff       	call   f010008b <_panic>



	// should be no free memory

	assert(!page_alloc(0));
f0101f7e:	83 ec 0c             	sub    $0xc,%esp
f0101f81:	6a 00                	push   $0x0
f0101f83:	e8 e6 ed ff ff       	call   f0100d6e <page_alloc>
f0101f88:	83 c4 10             	add    $0x10,%esp
f0101f8b:	85 c0                	test   %eax,%eax
f0101f8d:	74 19                	je     f0101fa8 <mem_init+0xeb1>
f0101f8f:	68 cf 45 10 f0       	push   $0xf01045cf
f0101f94:	68 5a 44 10 f0       	push   $0xf010445a
f0101f99:	68 43 07 00 00       	push   $0x743
f0101f9e:	68 34 44 10 f0       	push   $0xf0104434
f0101fa3:	e8 e3 e0 ff ff       	call   f010008b <_panic>



	// forcibly take pp0 back

	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fa8:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101fae:	8b 11                	mov    (%ecx),%edx
f0101fb0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fb6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101fbf:	c1 f8 03             	sar    $0x3,%eax
f0101fc2:	c1 e0 0c             	shl    $0xc,%eax
f0101fc5:	39 c2                	cmp    %eax,%edx
f0101fc7:	74 19                	je     f0101fe2 <mem_init+0xeeb>
f0101fc9:	68 20 3f 10 f0       	push   $0xf0103f20
f0101fce:	68 5a 44 10 f0       	push   $0xf010445a
f0101fd3:	68 49 07 00 00       	push   $0x749
f0101fd8:	68 34 44 10 f0       	push   $0xf0104434
f0101fdd:	e8 a9 e0 ff ff       	call   f010008b <_panic>

	kern_pgdir[0] = 0;
f0101fe2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)

	assert(pp0->pp_ref == 1);
f0101fe8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101feb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ff0:	74 19                	je     f010200b <mem_init+0xf14>
f0101ff2:	68 32 46 10 f0       	push   $0xf0104632
f0101ff7:	68 5a 44 10 f0       	push   $0xf010445a
f0101ffc:	68 4d 07 00 00       	push   $0x74d
f0102001:	68 34 44 10 f0       	push   $0xf0104434
f0102006:	e8 80 e0 ff ff       	call   f010008b <_panic>

	pp0->pp_ref = 0;
f010200b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010200e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)



	// check pointer arithmetic in pgdir_walk

	page_free(pp0);
f0102014:	83 ec 0c             	sub    $0xc,%esp
f0102017:	50                   	push   %eax
f0102018:	e8 bb ed ff ff       	call   f0100dd8 <page_free>

	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);

	ptep = pgdir_walk(kern_pgdir, va, 1);
f010201d:	83 c4 0c             	add    $0xc,%esp
f0102020:	6a 01                	push   $0x1
f0102022:	68 00 10 40 00       	push   $0x401000
f0102027:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010202d:	e8 0a ee ff ff       	call   f0100e3c <pgdir_walk>
f0102032:	89 c7                	mov    %eax,%edi
f0102034:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102037:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010203c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010203f:	8b 40 04             	mov    0x4(%eax),%eax
f0102042:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102047:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010204d:	89 c2                	mov    %eax,%edx
f010204f:	c1 ea 0c             	shr    $0xc,%edx
f0102052:	83 c4 10             	add    $0x10,%esp
f0102055:	39 ca                	cmp    %ecx,%edx
f0102057:	72 15                	jb     f010206e <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102059:	50                   	push   %eax
f010205a:	68 84 3c 10 f0       	push   $0xf0103c84
f010205f:	68 5b 07 00 00       	push   $0x75b
f0102064:	68 34 44 10 f0       	push   $0xf0104434
f0102069:	e8 1d e0 ff ff       	call   f010008b <_panic>

	assert(ptep == ptep1 + PTX(va));
f010206e:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102073:	39 c7                	cmp    %eax,%edi
f0102075:	74 19                	je     f0102090 <mem_init+0xf99>
f0102077:	68 be 46 10 f0       	push   $0xf01046be
f010207c:	68 5a 44 10 f0       	push   $0xf010445a
f0102081:	68 5d 07 00 00       	push   $0x75d
f0102086:	68 34 44 10 f0       	push   $0xf0104434
f010208b:	e8 fb df ff ff       	call   f010008b <_panic>

	kern_pgdir[PDX(va)] = 0;
f0102090:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102093:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	pp0->pp_ref = 0;
f010209a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020a3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01020a9:	c1 f8 03             	sar    $0x3,%eax
f01020ac:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020af:	89 c2                	mov    %eax,%edx
f01020b1:	c1 ea 0c             	shr    $0xc,%edx
f01020b4:	39 d1                	cmp    %edx,%ecx
f01020b6:	77 12                	ja     f01020ca <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020b8:	50                   	push   %eax
f01020b9:	68 84 3c 10 f0       	push   $0xf0103c84
f01020be:	6a 52                	push   $0x52
f01020c0:	68 40 44 10 f0       	push   $0xf0104440
f01020c5:	e8 c1 df ff ff       	call   f010008b <_panic>



	// check that new page tables get cleared

	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020ca:	83 ec 04             	sub    $0x4,%esp
f01020cd:	68 00 10 00 00       	push   $0x1000
f01020d2:	68 ff 00 00 00       	push   $0xff
f01020d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020dc:	50                   	push   %eax
f01020dd:	e8 d5 11 00 00       	call   f01032b7 <memset>

	page_free(pp0);
f01020e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020e5:	89 3c 24             	mov    %edi,(%esp)
f01020e8:	e8 eb ec ff ff       	call   f0100dd8 <page_free>

	pgdir_walk(kern_pgdir, 0x0, 1);
f01020ed:	83 c4 0c             	add    $0xc,%esp
f01020f0:	6a 01                	push   $0x1
f01020f2:	6a 00                	push   $0x0
f01020f4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01020fa:	e8 3d ed ff ff       	call   f0100e3c <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020ff:	89 fa                	mov    %edi,%edx
f0102101:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102107:	c1 fa 03             	sar    $0x3,%edx
f010210a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010210d:	89 d0                	mov    %edx,%eax
f010210f:	c1 e8 0c             	shr    $0xc,%eax
f0102112:	83 c4 10             	add    $0x10,%esp
f0102115:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f010211b:	72 12                	jb     f010212f <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010211d:	52                   	push   %edx
f010211e:	68 84 3c 10 f0       	push   $0xf0103c84
f0102123:	6a 52                	push   $0x52
f0102125:	68 40 44 10 f0       	push   $0xf0104440
f010212a:	e8 5c df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010212f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax

	ptep = (pte_t *) page2kva(pp0);
f0102135:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102138:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx

	for(i=0; i<NPTENTRIES; i++)

		assert((ptep[i] & PTE_P) == 0);
f010213e:	f6 00 01             	testb  $0x1,(%eax)
f0102141:	74 19                	je     f010215c <mem_init+0x1065>
f0102143:	68 d6 46 10 f0       	push   $0xf01046d6
f0102148:	68 5a 44 10 f0       	push   $0xf010445a
f010214d:	68 71 07 00 00       	push   $0x771
f0102152:	68 34 44 10 f0       	push   $0xf0104434
f0102157:	e8 2f df ff ff       	call   f010008b <_panic>
f010215c:	83 c0 04             	add    $0x4,%eax

	pgdir_walk(kern_pgdir, 0x0, 1);

	ptep = (pte_t *) page2kva(pp0);

	for(i=0; i<NPTENTRIES; i++)
f010215f:	39 d0                	cmp    %edx,%eax
f0102161:	75 db                	jne    f010213e <mem_init+0x1047>

		assert((ptep[i] & PTE_P) == 0);

	kern_pgdir[0] = 0;
f0102163:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102168:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	pp0->pp_ref = 0;
f010216e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102171:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)



	// give free list back

	page_free_list = fl;
f0102177:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010217a:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c



	// free the pages we took

	page_free(pp0);
f0102180:	83 ec 0c             	sub    $0xc,%esp
f0102183:	50                   	push   %eax
f0102184:	e8 4f ec ff ff       	call   f0100dd8 <page_free>

	page_free(pp1);
f0102189:	89 1c 24             	mov    %ebx,(%esp)
f010218c:	e8 47 ec ff ff       	call   f0100dd8 <page_free>

	page_free(pp2);
f0102191:	89 34 24             	mov    %esi,(%esp)
f0102194:	e8 3f ec ff ff       	call   f0100dd8 <page_free>



	cprintf("check_page() succeeded!\n");
f0102199:	c7 04 24 ed 46 10 f0 	movl   $0xf01046ed,(%esp)
f01021a0:	e8 59 06 00 00       	call   f01027fe <cprintf>

	// Your code goes here:



    boot_map_region(kern_pgdir,
f01021a5:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021aa:	83 c4 10             	add    $0x10,%esp
f01021ad:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021b2:	77 15                	ja     f01021c9 <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021b4:	50                   	push   %eax
f01021b5:	68 94 3d 10 f0       	push   $0xf0103d94
f01021ba:	68 67 01 00 00       	push   $0x167
f01021bf:	68 34 44 10 f0       	push   $0xf0104434
f01021c4:	e8 c2 de ff ff       	call   f010008b <_panic>

                    UPAGES,

                    ROUNDUP((sizeof(struct PageInfo) * npages), PGSIZE),
f01021c9:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01021cf:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx

	// Your code goes here:



    boot_map_region(kern_pgdir,
f01021d6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01021dc:	83 ec 08             	sub    $0x8,%esp
f01021df:	6a 05                	push   $0x5
f01021e1:	05 00 00 00 10       	add    $0x10000000,%eax
f01021e6:	50                   	push   %eax
f01021e7:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021ec:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021f1:	e8 32 ed ff ff       	call   f0100f28 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021f6:	83 c4 10             	add    $0x10,%esp
f01021f9:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01021fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102203:	77 15                	ja     f010221a <mem_init+0x1123>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102205:	50                   	push   %eax
f0102206:	68 94 3d 10 f0       	push   $0xf0103d94
f010220b:	68 8b 01 00 00       	push   $0x18b
f0102210:	68 34 44 10 f0       	push   $0xf0104434
f0102215:	e8 71 de ff ff       	call   f010008b <_panic>

	// Your code goes here:

    

    boot_map_region(kern_pgdir,
f010221a:	83 ec 08             	sub    $0x8,%esp
f010221d:	6a 03                	push   $0x3
f010221f:	68 00 d0 10 00       	push   $0x10d000
f0102224:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102229:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010222e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102233:	e8 f0 ec ff ff       	call   f0100f28 <boot_map_region>

	// Permissions: kernel RW, user NONE

	// Your code goes here:

    boot_map_region(kern_pgdir,
f0102238:	83 c4 08             	add    $0x8,%esp
f010223b:	6a 03                	push   $0x3
f010223d:	6a 00                	push   $0x0
f010223f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102244:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102249:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010224e:	e8 d5 ec ff ff       	call   f0100f28 <boot_map_region>

	pde_t *pgdir;



	pgdir = kern_pgdir;
f0102253:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi



	// check pages array

	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102259:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010225e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102261:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102268:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010226d:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	for (i = 0; i < n; i += PGSIZE)

		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102270:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102276:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102279:	83 c4 10             	add    $0x10,%esp

	// check pages array

	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);

	for (i = 0; i < n; i += PGSIZE)
f010227c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102281:	eb 55                	jmp    f01022d8 <mem_init+0x11e1>

		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102283:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102289:	89 f0                	mov    %esi,%eax
f010228b:	e8 a5 e6 ff ff       	call   f0100935 <check_va2pa>
f0102290:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102297:	77 15                	ja     f01022ae <mem_init+0x11b7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102299:	57                   	push   %edi
f010229a:	68 94 3d 10 f0       	push   $0xf0103d94
f010229f:	68 f5 05 00 00       	push   $0x5f5
f01022a4:	68 34 44 10 f0       	push   $0xf0104434
f01022a9:	e8 dd dd ff ff       	call   f010008b <_panic>
f01022ae:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01022b5:	39 c2                	cmp    %eax,%edx
f01022b7:	74 19                	je     f01022d2 <mem_init+0x11db>
f01022b9:	68 a0 42 10 f0       	push   $0xf01042a0
f01022be:	68 5a 44 10 f0       	push   $0xf010445a
f01022c3:	68 f5 05 00 00       	push   $0x5f5
f01022c8:	68 34 44 10 f0       	push   $0xf0104434
f01022cd:	e8 b9 dd ff ff       	call   f010008b <_panic>

	// check pages array

	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);

	for (i = 0; i < n; i += PGSIZE)
f01022d2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022d8:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01022db:	77 a6                	ja     f0102283 <mem_init+0x118c>



	// check phys mem

	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022dd:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022e0:	c1 e7 0c             	shl    $0xc,%edi
f01022e3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01022e8:	eb 30                	jmp    f010231a <mem_init+0x1223>

		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022ea:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01022f0:	89 f0                	mov    %esi,%eax
f01022f2:	e8 3e e6 ff ff       	call   f0100935 <check_va2pa>
f01022f7:	39 c3                	cmp    %eax,%ebx
f01022f9:	74 19                	je     f0102314 <mem_init+0x121d>
f01022fb:	68 d4 42 10 f0       	push   $0xf01042d4
f0102300:	68 5a 44 10 f0       	push   $0xf010445a
f0102305:	68 ff 05 00 00       	push   $0x5ff
f010230a:	68 34 44 10 f0       	push   $0xf0104434
f010230f:	e8 77 dd ff ff       	call   f010008b <_panic>



	// check phys mem

	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102314:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010231a:	39 fb                	cmp    %edi,%ebx
f010231c:	72 cc                	jb     f01022ea <mem_init+0x11f3>
f010231e:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx

	// check kernel stack

	for (i = 0; i < KSTKSIZE; i += PGSIZE)

		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102323:	89 da                	mov    %ebx,%edx
f0102325:	89 f0                	mov    %esi,%eax
f0102327:	e8 09 e6 ff ff       	call   f0100935 <check_va2pa>
f010232c:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102332:	39 c2                	cmp    %eax,%edx
f0102334:	74 19                	je     f010234f <mem_init+0x1258>
f0102336:	68 fc 42 10 f0       	push   $0xf01042fc
f010233b:	68 5a 44 10 f0       	push   $0xf010445a
f0102340:	68 07 06 00 00       	push   $0x607
f0102345:	68 34 44 10 f0       	push   $0xf0104434
f010234a:	e8 3c dd ff ff       	call   f010008b <_panic>
f010234f:	81 c3 00 10 00 00    	add    $0x1000,%ebx



	// check kernel stack

	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102355:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f010235b:	75 c6                	jne    f0102323 <mem_init+0x122c>

		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010235d:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102362:	89 f0                	mov    %esi,%eax
f0102364:	e8 cc e5 ff ff       	call   f0100935 <check_va2pa>
f0102369:	83 f8 ff             	cmp    $0xffffffff,%eax
f010236c:	74 51                	je     f01023bf <mem_init+0x12c8>
f010236e:	68 44 43 10 f0       	push   $0xf0104344
f0102373:	68 5a 44 10 f0       	push   $0xf010445a
f0102378:	68 09 06 00 00       	push   $0x609
f010237d:	68 34 44 10 f0       	push   $0xf0104434
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions

	for (i = 0; i < NPDENTRIES; i++) {

		switch (i) {
f0102387:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010238c:	72 36                	jb     f01023c4 <mem_init+0x12cd>
f010238e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102393:	76 07                	jbe    f010239c <mem_init+0x12a5>
f0102395:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010239a:	75 28                	jne    f01023c4 <mem_init+0x12cd>

		case PDX(KSTACKTOP-1):

		case PDX(UPAGES):

			assert(pgdir[i] & PTE_P);
f010239c:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01023a0:	0f 85 83 00 00 00    	jne    f0102429 <mem_init+0x1332>
f01023a6:	68 06 47 10 f0       	push   $0xf0104706
f01023ab:	68 5a 44 10 f0       	push   $0xf010445a
f01023b0:	68 19 06 00 00       	push   $0x619
f01023b5:	68 34 44 10 f0       	push   $0xf0104434
f01023ba:	e8 cc dc ff ff       	call   f010008b <_panic>

	for (i = 0; i < KSTKSIZE; i += PGSIZE)

		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023bf:	b8 00 00 00 00       	mov    $0x0,%eax

			break;

		default:

			if (i >= PDX(KERNBASE)) {
f01023c4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023c9:	76 3f                	jbe    f010240a <mem_init+0x1313>

				assert(pgdir[i] & PTE_P);
f01023cb:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01023ce:	f6 c2 01             	test   $0x1,%dl
f01023d1:	75 19                	jne    f01023ec <mem_init+0x12f5>
f01023d3:	68 06 47 10 f0       	push   $0xf0104706
f01023d8:	68 5a 44 10 f0       	push   $0xf010445a
f01023dd:	68 21 06 00 00       	push   $0x621
f01023e2:	68 34 44 10 f0       	push   $0xf0104434
f01023e7:	e8 9f dc ff ff       	call   f010008b <_panic>

				assert(pgdir[i] & PTE_W);
f01023ec:	f6 c2 02             	test   $0x2,%dl
f01023ef:	75 38                	jne    f0102429 <mem_init+0x1332>
f01023f1:	68 17 47 10 f0       	push   $0xf0104717
f01023f6:	68 5a 44 10 f0       	push   $0xf010445a
f01023fb:	68 23 06 00 00       	push   $0x623
f0102400:	68 34 44 10 f0       	push   $0xf0104434
f0102405:	e8 81 dc ff ff       	call   f010008b <_panic>

			} else

				assert(pgdir[i] == 0);
f010240a:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010240e:	74 19                	je     f0102429 <mem_init+0x1332>
f0102410:	68 28 47 10 f0       	push   $0xf0104728
f0102415:	68 5a 44 10 f0       	push   $0xf010445a
f010241a:	68 27 06 00 00       	push   $0x627
f010241f:	68 34 44 10 f0       	push   $0xf0104434
f0102424:	e8 62 dc ff ff       	call   f010008b <_panic>



	// check PDE permissions

	for (i = 0; i < NPDENTRIES; i++) {
f0102429:	83 c0 01             	add    $0x1,%eax
f010242c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102431:	0f 86 50 ff ff ff    	jbe    f0102387 <mem_init+0x1290>

		}

	}

	cprintf("check_kern_pgdir() succeeded!\n");
f0102437:	83 ec 0c             	sub    $0xc,%esp
f010243a:	68 74 43 10 f0       	push   $0xf0104374
f010243f:	e8 ba 03 00 00       	call   f01027fe <cprintf>

	// If the machine reboots at this point, you've probably set up your

	// kern_pgdir wrong.

	lcr3(PADDR(kern_pgdir));
f0102444:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102449:	83 c4 10             	add    $0x10,%esp
f010244c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102451:	77 15                	ja     f0102468 <mem_init+0x1371>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102453:	50                   	push   %eax
f0102454:	68 94 3d 10 f0       	push   $0xf0103d94
f0102459:	68 c1 01 00 00       	push   $0x1c1
f010245e:	68 34 44 10 f0       	push   $0xf0104434
f0102463:	e8 23 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102468:	05 00 00 00 10       	add    $0x10000000,%eax
f010246d:	0f 22 d8             	mov    %eax,%cr3



	check_page_free_list(0);
f0102470:	b8 00 00 00 00       	mov    $0x0,%eax
f0102475:	e8 1f e5 ff ff       	call   f0100999 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010247a:	0f 20 c0             	mov    %cr0,%eax
f010247d:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102480:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102485:	0f 22 c0             	mov    %eax,%cr0

	// check that we can read and write installed pages

	pp1 = pp2 = 0;

	assert((pp0 = page_alloc(0)));
f0102488:	83 ec 0c             	sub    $0xc,%esp
f010248b:	6a 00                	push   $0x0
f010248d:	e8 dc e8 ff ff       	call   f0100d6e <page_alloc>
f0102492:	89 c3                	mov    %eax,%ebx
f0102494:	83 c4 10             	add    $0x10,%esp
f0102497:	85 c0                	test   %eax,%eax
f0102499:	75 19                	jne    f01024b4 <mem_init+0x13bd>
f010249b:	68 24 45 10 f0       	push   $0xf0104524
f01024a0:	68 5a 44 10 f0       	push   $0xf010445a
f01024a5:	68 a7 07 00 00       	push   $0x7a7
f01024aa:	68 34 44 10 f0       	push   $0xf0104434
f01024af:	e8 d7 db ff ff       	call   f010008b <_panic>

	assert((pp1 = page_alloc(0)));
f01024b4:	83 ec 0c             	sub    $0xc,%esp
f01024b7:	6a 00                	push   $0x0
f01024b9:	e8 b0 e8 ff ff       	call   f0100d6e <page_alloc>
f01024be:	89 c7                	mov    %eax,%edi
f01024c0:	83 c4 10             	add    $0x10,%esp
f01024c3:	85 c0                	test   %eax,%eax
f01024c5:	75 19                	jne    f01024e0 <mem_init+0x13e9>
f01024c7:	68 3a 45 10 f0       	push   $0xf010453a
f01024cc:	68 5a 44 10 f0       	push   $0xf010445a
f01024d1:	68 a9 07 00 00       	push   $0x7a9
f01024d6:	68 34 44 10 f0       	push   $0xf0104434
f01024db:	e8 ab db ff ff       	call   f010008b <_panic>

	assert((pp2 = page_alloc(0)));
f01024e0:	83 ec 0c             	sub    $0xc,%esp
f01024e3:	6a 00                	push   $0x0
f01024e5:	e8 84 e8 ff ff       	call   f0100d6e <page_alloc>
f01024ea:	89 c6                	mov    %eax,%esi
f01024ec:	83 c4 10             	add    $0x10,%esp
f01024ef:	85 c0                	test   %eax,%eax
f01024f1:	75 19                	jne    f010250c <mem_init+0x1415>
f01024f3:	68 50 45 10 f0       	push   $0xf0104550
f01024f8:	68 5a 44 10 f0       	push   $0xf010445a
f01024fd:	68 ab 07 00 00       	push   $0x7ab
f0102502:	68 34 44 10 f0       	push   $0xf0104434
f0102507:	e8 7f db ff ff       	call   f010008b <_panic>

	page_free(pp0);
f010250c:	83 ec 0c             	sub    $0xc,%esp
f010250f:	53                   	push   %ebx
f0102510:	e8 c3 e8 ff ff       	call   f0100dd8 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102515:	89 f8                	mov    %edi,%eax
f0102517:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010251d:	c1 f8 03             	sar    $0x3,%eax
f0102520:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102523:	89 c2                	mov    %eax,%edx
f0102525:	c1 ea 0c             	shr    $0xc,%edx
f0102528:	83 c4 10             	add    $0x10,%esp
f010252b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102531:	72 12                	jb     f0102545 <mem_init+0x144e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102533:	50                   	push   %eax
f0102534:	68 84 3c 10 f0       	push   $0xf0103c84
f0102539:	6a 52                	push   $0x52
f010253b:	68 40 44 10 f0       	push   $0xf0104440
f0102540:	e8 46 db ff ff       	call   f010008b <_panic>

	memset(page2kva(pp1), 1, PGSIZE);
f0102545:	83 ec 04             	sub    $0x4,%esp
f0102548:	68 00 10 00 00       	push   $0x1000
f010254d:	6a 01                	push   $0x1
f010254f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102554:	50                   	push   %eax
f0102555:	e8 5d 0d 00 00       	call   f01032b7 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010255a:	89 f0                	mov    %esi,%eax
f010255c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102562:	c1 f8 03             	sar    $0x3,%eax
f0102565:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102568:	89 c2                	mov    %eax,%edx
f010256a:	c1 ea 0c             	shr    $0xc,%edx
f010256d:	83 c4 10             	add    $0x10,%esp
f0102570:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102576:	72 12                	jb     f010258a <mem_init+0x1493>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102578:	50                   	push   %eax
f0102579:	68 84 3c 10 f0       	push   $0xf0103c84
f010257e:	6a 52                	push   $0x52
f0102580:	68 40 44 10 f0       	push   $0xf0104440
f0102585:	e8 01 db ff ff       	call   f010008b <_panic>

	memset(page2kva(pp2), 2, PGSIZE);
f010258a:	83 ec 04             	sub    $0x4,%esp
f010258d:	68 00 10 00 00       	push   $0x1000
f0102592:	6a 02                	push   $0x2
f0102594:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102599:	50                   	push   %eax
f010259a:	e8 18 0d 00 00       	call   f01032b7 <memset>

	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010259f:	6a 02                	push   $0x2
f01025a1:	68 00 10 00 00       	push   $0x1000
f01025a6:	57                   	push   %edi
f01025a7:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025ad:	e8 b2 ea ff ff       	call   f0101064 <page_insert>

	assert(pp1->pp_ref == 1);
f01025b2:	83 c4 20             	add    $0x20,%esp
f01025b5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025ba:	74 19                	je     f01025d5 <mem_init+0x14de>
f01025bc:	68 21 46 10 f0       	push   $0xf0104621
f01025c1:	68 5a 44 10 f0       	push   $0xf010445a
f01025c6:	68 b5 07 00 00       	push   $0x7b5
f01025cb:	68 34 44 10 f0       	push   $0xf0104434
f01025d0:	e8 b6 da ff ff       	call   f010008b <_panic>

	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025d5:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025dc:	01 01 01 
f01025df:	74 19                	je     f01025fa <mem_init+0x1503>
f01025e1:	68 94 43 10 f0       	push   $0xf0104394
f01025e6:	68 5a 44 10 f0       	push   $0xf010445a
f01025eb:	68 b7 07 00 00       	push   $0x7b7
f01025f0:	68 34 44 10 f0       	push   $0xf0104434
f01025f5:	e8 91 da ff ff       	call   f010008b <_panic>

	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01025fa:	6a 02                	push   $0x2
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	56                   	push   %esi
f0102602:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102608:	e8 57 ea ff ff       	call   f0101064 <page_insert>

	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010260d:	83 c4 10             	add    $0x10,%esp
f0102610:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102617:	02 02 02 
f010261a:	74 19                	je     f0102635 <mem_init+0x153e>
f010261c:	68 b8 43 10 f0       	push   $0xf01043b8
f0102621:	68 5a 44 10 f0       	push   $0xf010445a
f0102626:	68 bb 07 00 00       	push   $0x7bb
f010262b:	68 34 44 10 f0       	push   $0xf0104434
f0102630:	e8 56 da ff ff       	call   f010008b <_panic>

	assert(pp2->pp_ref == 1);
f0102635:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010263a:	74 19                	je     f0102655 <mem_init+0x155e>
f010263c:	68 43 46 10 f0       	push   $0xf0104643
f0102641:	68 5a 44 10 f0       	push   $0xf010445a
f0102646:	68 bd 07 00 00       	push   $0x7bd
f010264b:	68 34 44 10 f0       	push   $0xf0104434
f0102650:	e8 36 da ff ff       	call   f010008b <_panic>

	assert(pp1->pp_ref == 0);
f0102655:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010265a:	74 19                	je     f0102675 <mem_init+0x157e>
f010265c:	68 ad 46 10 f0       	push   $0xf01046ad
f0102661:	68 5a 44 10 f0       	push   $0xf010445a
f0102666:	68 bf 07 00 00       	push   $0x7bf
f010266b:	68 34 44 10 f0       	push   $0xf0104434
f0102670:	e8 16 da ff ff       	call   f010008b <_panic>

	*(uint32_t *)PGSIZE = 0x03030303U;
f0102675:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010267c:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010267f:	89 f0                	mov    %esi,%eax
f0102681:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102687:	c1 f8 03             	sar    $0x3,%eax
f010268a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010268d:	89 c2                	mov    %eax,%edx
f010268f:	c1 ea 0c             	shr    $0xc,%edx
f0102692:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102698:	72 12                	jb     f01026ac <mem_init+0x15b5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010269a:	50                   	push   %eax
f010269b:	68 84 3c 10 f0       	push   $0xf0103c84
f01026a0:	6a 52                	push   $0x52
f01026a2:	68 40 44 10 f0       	push   $0xf0104440
f01026a7:	e8 df d9 ff ff       	call   f010008b <_panic>

	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026ac:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026b3:	03 03 03 
f01026b6:	74 19                	je     f01026d1 <mem_init+0x15da>
f01026b8:	68 dc 43 10 f0       	push   $0xf01043dc
f01026bd:	68 5a 44 10 f0       	push   $0xf010445a
f01026c2:	68 c3 07 00 00       	push   $0x7c3
f01026c7:	68 34 44 10 f0       	push   $0xf0104434
f01026cc:	e8 ba d9 ff ff       	call   f010008b <_panic>

	page_remove(kern_pgdir, (void*) PGSIZE);
f01026d1:	83 ec 08             	sub    $0x8,%esp
f01026d4:	68 00 10 00 00       	push   $0x1000
f01026d9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01026df:	e8 32 e9 ff ff       	call   f0101016 <page_remove>

	assert(pp2->pp_ref == 0);
f01026e4:	83 c4 10             	add    $0x10,%esp
f01026e7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026ec:	74 19                	je     f0102707 <mem_init+0x1610>
f01026ee:	68 7b 46 10 f0       	push   $0xf010467b
f01026f3:	68 5a 44 10 f0       	push   $0xf010445a
f01026f8:	68 c7 07 00 00       	push   $0x7c7
f01026fd:	68 34 44 10 f0       	push   $0xf0104434
f0102702:	e8 84 d9 ff ff       	call   f010008b <_panic>



	// forcibly take pp0 back

	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102707:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f010270d:	8b 11                	mov    (%ecx),%edx
f010270f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102715:	89 d8                	mov    %ebx,%eax
f0102717:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010271d:	c1 f8 03             	sar    $0x3,%eax
f0102720:	c1 e0 0c             	shl    $0xc,%eax
f0102723:	39 c2                	cmp    %eax,%edx
f0102725:	74 19                	je     f0102740 <mem_init+0x1649>
f0102727:	68 20 3f 10 f0       	push   $0xf0103f20
f010272c:	68 5a 44 10 f0       	push   $0xf010445a
f0102731:	68 cd 07 00 00       	push   $0x7cd
f0102736:	68 34 44 10 f0       	push   $0xf0104434
f010273b:	e8 4b d9 ff ff       	call   f010008b <_panic>

	kern_pgdir[0] = 0;
f0102740:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)

	assert(pp0->pp_ref == 1);
f0102746:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010274b:	74 19                	je     f0102766 <mem_init+0x166f>
f010274d:	68 32 46 10 f0       	push   $0xf0104632
f0102752:	68 5a 44 10 f0       	push   $0xf010445a
f0102757:	68 d1 07 00 00       	push   $0x7d1
f010275c:	68 34 44 10 f0       	push   $0xf0104434
f0102761:	e8 25 d9 ff ff       	call   f010008b <_panic>

	pp0->pp_ref = 0;
f0102766:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)



	// free the pages we took

	page_free(pp0);
f010276c:	83 ec 0c             	sub    $0xc,%esp
f010276f:	53                   	push   %ebx
f0102770:	e8 63 e6 ff ff       	call   f0100dd8 <page_free>



	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102775:	c7 04 24 08 44 10 f0 	movl   $0xf0104408,(%esp)
f010277c:	e8 7d 00 00 00       	call   f01027fe <cprintf>

	// Some more checks, only possible after kern_pgdir is installed.

	check_page_installed_pgdir();

}
f0102781:	83 c4 10             	add    $0x10,%esp
f0102784:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102787:	5b                   	pop    %ebx
f0102788:	5e                   	pop    %esi
f0102789:	5f                   	pop    %edi
f010278a:	5d                   	pop    %ebp
f010278b:	c3                   	ret    

f010278c <tlb_invalidate>:

void

tlb_invalidate(pde_t *pgdir, void *va)

{
f010278c:	55                   	push   %ebp
f010278d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010278f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102792:	0f 01 38             	invlpg (%eax)

	// For now, there is only one address space, so always invalidate.

	invlpg(va);

}
f0102795:	5d                   	pop    %ebp
f0102796:	c3                   	ret    

f0102797 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102797:	55                   	push   %ebp
f0102798:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010279a:	ba 70 00 00 00       	mov    $0x70,%edx
f010279f:	8b 45 08             	mov    0x8(%ebp),%eax
f01027a2:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01027a3:	ba 71 00 00 00       	mov    $0x71,%edx
f01027a8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01027a9:	0f b6 c0             	movzbl %al,%eax
}
f01027ac:	5d                   	pop    %ebp
f01027ad:	c3                   	ret    

f01027ae <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01027ae:	55                   	push   %ebp
f01027af:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027b1:	ba 70 00 00 00       	mov    $0x70,%edx
f01027b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01027b9:	ee                   	out    %al,(%dx)
f01027ba:	ba 71 00 00 00       	mov    $0x71,%edx
f01027bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027c2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01027c3:	5d                   	pop    %ebp
f01027c4:	c3                   	ret    

f01027c5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01027c5:	55                   	push   %ebp
f01027c6:	89 e5                	mov    %esp,%ebp
f01027c8:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01027cb:	ff 75 08             	pushl  0x8(%ebp)
f01027ce:	e8 2d de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01027d3:	83 c4 10             	add    $0x10,%esp
f01027d6:	c9                   	leave  
f01027d7:	c3                   	ret    

f01027d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01027d8:	55                   	push   %ebp
f01027d9:	89 e5                	mov    %esp,%ebp
f01027db:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01027de:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01027e5:	ff 75 0c             	pushl  0xc(%ebp)
f01027e8:	ff 75 08             	pushl  0x8(%ebp)
f01027eb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01027ee:	50                   	push   %eax
f01027ef:	68 c5 27 10 f0       	push   $0xf01027c5
f01027f4:	e8 52 04 00 00       	call   f0102c4b <vprintfmt>
	return cnt;
}
f01027f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01027fc:	c9                   	leave  
f01027fd:	c3                   	ret    

f01027fe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01027fe:	55                   	push   %ebp
f01027ff:	89 e5                	mov    %esp,%ebp
f0102801:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102804:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102807:	50                   	push   %eax
f0102808:	ff 75 08             	pushl  0x8(%ebp)
f010280b:	e8 c8 ff ff ff       	call   f01027d8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102810:	c9                   	leave  
f0102811:	c3                   	ret    

f0102812 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102812:	55                   	push   %ebp
f0102813:	89 e5                	mov    %esp,%ebp
f0102815:	57                   	push   %edi
f0102816:	56                   	push   %esi
f0102817:	53                   	push   %ebx
f0102818:	83 ec 14             	sub    $0x14,%esp
f010281b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010281e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102821:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102824:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102827:	8b 1a                	mov    (%edx),%ebx
f0102829:	8b 01                	mov    (%ecx),%eax
f010282b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010282e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102835:	eb 7f                	jmp    f01028b6 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102837:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010283a:	01 d8                	add    %ebx,%eax
f010283c:	89 c6                	mov    %eax,%esi
f010283e:	c1 ee 1f             	shr    $0x1f,%esi
f0102841:	01 c6                	add    %eax,%esi
f0102843:	d1 fe                	sar    %esi
f0102845:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102848:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010284b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010284e:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102850:	eb 03                	jmp    f0102855 <stab_binsearch+0x43>
			m--;
f0102852:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102855:	39 c3                	cmp    %eax,%ebx
f0102857:	7f 0d                	jg     f0102866 <stab_binsearch+0x54>
f0102859:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010285d:	83 ea 0c             	sub    $0xc,%edx
f0102860:	39 f9                	cmp    %edi,%ecx
f0102862:	75 ee                	jne    f0102852 <stab_binsearch+0x40>
f0102864:	eb 05                	jmp    f010286b <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102866:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102869:	eb 4b                	jmp    f01028b6 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010286b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010286e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102871:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102875:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102878:	76 11                	jbe    f010288b <stab_binsearch+0x79>
			*region_left = m;
f010287a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010287d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010287f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102882:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102889:	eb 2b                	jmp    f01028b6 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010288b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010288e:	73 14                	jae    f01028a4 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102890:	83 e8 01             	sub    $0x1,%eax
f0102893:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102896:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102899:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010289b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028a2:	eb 12                	jmp    f01028b6 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01028a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028a7:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01028a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01028ad:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01028b6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01028b9:	0f 8e 78 ff ff ff    	jle    f0102837 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01028bf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01028c3:	75 0f                	jne    f01028d4 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01028c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028c8:	8b 00                	mov    (%eax),%eax
f01028ca:	83 e8 01             	sub    $0x1,%eax
f01028cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028d0:	89 06                	mov    %eax,(%esi)
f01028d2:	eb 2c                	jmp    f0102900 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028d7:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01028d9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028dc:	8b 0e                	mov    (%esi),%ecx
f01028de:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01028e1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01028e4:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028e7:	eb 03                	jmp    f01028ec <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01028e9:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028ec:	39 c8                	cmp    %ecx,%eax
f01028ee:	7e 0b                	jle    f01028fb <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01028f0:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01028f4:	83 ea 0c             	sub    $0xc,%edx
f01028f7:	39 df                	cmp    %ebx,%edi
f01028f9:	75 ee                	jne    f01028e9 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01028fb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028fe:	89 06                	mov    %eax,(%esi)
	}
}
f0102900:	83 c4 14             	add    $0x14,%esp
f0102903:	5b                   	pop    %ebx
f0102904:	5e                   	pop    %esi
f0102905:	5f                   	pop    %edi
f0102906:	5d                   	pop    %ebp
f0102907:	c3                   	ret    

f0102908 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102908:	55                   	push   %ebp
f0102909:	89 e5                	mov    %esp,%ebp
f010290b:	57                   	push   %edi
f010290c:	56                   	push   %esi
f010290d:	53                   	push   %ebx
f010290e:	83 ec 3c             	sub    $0x3c,%esp
f0102911:	8b 75 08             	mov    0x8(%ebp),%esi
f0102914:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102917:	c7 03 36 47 10 f0    	movl   $0xf0104736,(%ebx)
	info->eip_line = 0;
f010291d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102924:	c7 43 08 36 47 10 f0 	movl   $0xf0104736,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010292b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102932:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102935:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010293c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102942:	76 11                	jbe    f0102955 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102944:	b8 9a c0 10 f0       	mov    $0xf010c09a,%eax
f0102949:	3d e9 a2 10 f0       	cmp    $0xf010a2e9,%eax
f010294e:	77 19                	ja     f0102969 <debuginfo_eip+0x61>
f0102950:	e9 aa 01 00 00       	jmp    f0102aff <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102955:	83 ec 04             	sub    $0x4,%esp
f0102958:	68 40 47 10 f0       	push   $0xf0104740
f010295d:	6a 7f                	push   $0x7f
f010295f:	68 4d 47 10 f0       	push   $0xf010474d
f0102964:	e8 22 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102969:	80 3d 99 c0 10 f0 00 	cmpb   $0x0,0xf010c099
f0102970:	0f 85 90 01 00 00    	jne    f0102b06 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102976:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010297d:	b8 e8 a2 10 f0       	mov    $0xf010a2e8,%eax
f0102982:	2d 6c 49 10 f0       	sub    $0xf010496c,%eax
f0102987:	c1 f8 02             	sar    $0x2,%eax
f010298a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102990:	83 e8 01             	sub    $0x1,%eax
f0102993:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102996:	83 ec 08             	sub    $0x8,%esp
f0102999:	56                   	push   %esi
f010299a:	6a 64                	push   $0x64
f010299c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010299f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01029a2:	b8 6c 49 10 f0       	mov    $0xf010496c,%eax
f01029a7:	e8 66 fe ff ff       	call   f0102812 <stab_binsearch>
	if (lfile == 0)
f01029ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029af:	83 c4 10             	add    $0x10,%esp
f01029b2:	85 c0                	test   %eax,%eax
f01029b4:	0f 84 53 01 00 00    	je     f0102b0d <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01029ba:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01029bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029c0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01029c3:	83 ec 08             	sub    $0x8,%esp
f01029c6:	56                   	push   %esi
f01029c7:	6a 24                	push   $0x24
f01029c9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01029cc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01029cf:	b8 6c 49 10 f0       	mov    $0xf010496c,%eax
f01029d4:	e8 39 fe ff ff       	call   f0102812 <stab_binsearch>

	if (lfun <= rfun) {
f01029d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029dc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01029df:	83 c4 10             	add    $0x10,%esp
f01029e2:	39 d0                	cmp    %edx,%eax
f01029e4:	7f 40                	jg     f0102a26 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01029e6:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01029e9:	c1 e1 02             	shl    $0x2,%ecx
f01029ec:	8d b9 6c 49 10 f0    	lea    -0xfefb694(%ecx),%edi
f01029f2:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01029f5:	8b b9 6c 49 10 f0    	mov    -0xfefb694(%ecx),%edi
f01029fb:	b9 9a c0 10 f0       	mov    $0xf010c09a,%ecx
f0102a00:	81 e9 e9 a2 10 f0    	sub    $0xf010a2e9,%ecx
f0102a06:	39 cf                	cmp    %ecx,%edi
f0102a08:	73 09                	jae    f0102a13 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102a0a:	81 c7 e9 a2 10 f0    	add    $0xf010a2e9,%edi
f0102a10:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102a13:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a16:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102a19:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102a1c:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102a1e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102a21:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a24:	eb 0f                	jmp    f0102a35 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102a26:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102a29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102a2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a32:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102a35:	83 ec 08             	sub    $0x8,%esp
f0102a38:	6a 3a                	push   $0x3a
f0102a3a:	ff 73 08             	pushl  0x8(%ebx)
f0102a3d:	e8 59 08 00 00       	call   f010329b <strfind>
f0102a42:	2b 43 08             	sub    0x8(%ebx),%eax
f0102a45:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102a48:	83 c4 08             	add    $0x8,%esp
f0102a4b:	56                   	push   %esi
f0102a4c:	6a 44                	push   $0x44
f0102a4e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102a51:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102a54:	b8 6c 49 10 f0       	mov    $0xf010496c,%eax
f0102a59:	e8 b4 fd ff ff       	call   f0102812 <stab_binsearch>
	  if (lline <= rline) {
f0102a5e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a61:	83 c4 10             	add    $0x10,%esp
f0102a64:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102a67:	0f 8f a7 00 00 00    	jg     f0102b14 <debuginfo_eip+0x20c>
	      info->eip_line = stabs[lline].n_desc;
f0102a6d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a70:	8d 04 85 6c 49 10 f0 	lea    -0xfefb694(,%eax,4),%eax
f0102a77:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102a7b:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a7e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102a81:	eb 06                	jmp    f0102a89 <debuginfo_eip+0x181>
f0102a83:	83 ea 01             	sub    $0x1,%edx
f0102a86:	83 e8 0c             	sub    $0xc,%eax
f0102a89:	39 d6                	cmp    %edx,%esi
f0102a8b:	7f 34                	jg     f0102ac1 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0102a8d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a91:	80 f9 84             	cmp    $0x84,%cl
f0102a94:	74 0b                	je     f0102aa1 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a96:	80 f9 64             	cmp    $0x64,%cl
f0102a99:	75 e8                	jne    f0102a83 <debuginfo_eip+0x17b>
f0102a9b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a9f:	74 e2                	je     f0102a83 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102aa1:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102aa4:	8b 14 85 6c 49 10 f0 	mov    -0xfefb694(,%eax,4),%edx
f0102aab:	b8 9a c0 10 f0       	mov    $0xf010c09a,%eax
f0102ab0:	2d e9 a2 10 f0       	sub    $0xf010a2e9,%eax
f0102ab5:	39 c2                	cmp    %eax,%edx
f0102ab7:	73 08                	jae    f0102ac1 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102ab9:	81 c2 e9 a2 10 f0    	add    $0xf010a2e9,%edx
f0102abf:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ac1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ac4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ac7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102acc:	39 f2                	cmp    %esi,%edx
f0102ace:	7d 50                	jge    f0102b20 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0102ad0:	83 c2 01             	add    $0x1,%edx
f0102ad3:	89 d0                	mov    %edx,%eax
f0102ad5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102ad8:	8d 14 95 6c 49 10 f0 	lea    -0xfefb694(,%edx,4),%edx
f0102adf:	eb 04                	jmp    f0102ae5 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102ae1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ae5:	39 c6                	cmp    %eax,%esi
f0102ae7:	7e 32                	jle    f0102b1b <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ae9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102aed:	83 c0 01             	add    $0x1,%eax
f0102af0:	83 c2 0c             	add    $0xc,%edx
f0102af3:	80 f9 a0             	cmp    $0xa0,%cl
f0102af6:	74 e9                	je     f0102ae1 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102af8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102afd:	eb 21                	jmp    f0102b20 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102aff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b04:	eb 1a                	jmp    f0102b20 <debuginfo_eip+0x218>
f0102b06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b0b:	eb 13                	jmp    f0102b20 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102b0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b12:	eb 0c                	jmp    f0102b20 <debuginfo_eip+0x218>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	  if (lline <= rline) {
	      info->eip_line = stabs[lline].n_desc;
	  } else {
	      return -1;
f0102b14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b19:	eb 05                	jmp    f0102b20 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b20:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b23:	5b                   	pop    %ebx
f0102b24:	5e                   	pop    %esi
f0102b25:	5f                   	pop    %edi
f0102b26:	5d                   	pop    %ebp
f0102b27:	c3                   	ret    

f0102b28 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102b28:	55                   	push   %ebp
f0102b29:	89 e5                	mov    %esp,%ebp
f0102b2b:	57                   	push   %edi
f0102b2c:	56                   	push   %esi
f0102b2d:	53                   	push   %ebx
f0102b2e:	83 ec 1c             	sub    $0x1c,%esp
f0102b31:	89 c7                	mov    %eax,%edi
f0102b33:	89 d6                	mov    %edx,%esi
f0102b35:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b38:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b3b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b3e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102b41:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102b44:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b49:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102b4c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102b4f:	39 d3                	cmp    %edx,%ebx
f0102b51:	72 05                	jb     f0102b58 <printnum+0x30>
f0102b53:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102b56:	77 45                	ja     f0102b9d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102b58:	83 ec 0c             	sub    $0xc,%esp
f0102b5b:	ff 75 18             	pushl  0x18(%ebp)
f0102b5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b61:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102b64:	53                   	push   %ebx
f0102b65:	ff 75 10             	pushl  0x10(%ebp)
f0102b68:	83 ec 08             	sub    $0x8,%esp
f0102b6b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b6e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b71:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b74:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b77:	e8 44 09 00 00       	call   f01034c0 <__udivdi3>
f0102b7c:	83 c4 18             	add    $0x18,%esp
f0102b7f:	52                   	push   %edx
f0102b80:	50                   	push   %eax
f0102b81:	89 f2                	mov    %esi,%edx
f0102b83:	89 f8                	mov    %edi,%eax
f0102b85:	e8 9e ff ff ff       	call   f0102b28 <printnum>
f0102b8a:	83 c4 20             	add    $0x20,%esp
f0102b8d:	eb 18                	jmp    f0102ba7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b8f:	83 ec 08             	sub    $0x8,%esp
f0102b92:	56                   	push   %esi
f0102b93:	ff 75 18             	pushl  0x18(%ebp)
f0102b96:	ff d7                	call   *%edi
f0102b98:	83 c4 10             	add    $0x10,%esp
f0102b9b:	eb 03                	jmp    f0102ba0 <printnum+0x78>
f0102b9d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ba0:	83 eb 01             	sub    $0x1,%ebx
f0102ba3:	85 db                	test   %ebx,%ebx
f0102ba5:	7f e8                	jg     f0102b8f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ba7:	83 ec 08             	sub    $0x8,%esp
f0102baa:	56                   	push   %esi
f0102bab:	83 ec 04             	sub    $0x4,%esp
f0102bae:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102bb1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bb4:	ff 75 dc             	pushl  -0x24(%ebp)
f0102bb7:	ff 75 d8             	pushl  -0x28(%ebp)
f0102bba:	e8 31 0a 00 00       	call   f01035f0 <__umoddi3>
f0102bbf:	83 c4 14             	add    $0x14,%esp
f0102bc2:	0f be 80 5b 47 10 f0 	movsbl -0xfefb8a5(%eax),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	ff d7                	call   *%edi
}
f0102bcc:	83 c4 10             	add    $0x10,%esp
f0102bcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bd2:	5b                   	pop    %ebx
f0102bd3:	5e                   	pop    %esi
f0102bd4:	5f                   	pop    %edi
f0102bd5:	5d                   	pop    %ebp
f0102bd6:	c3                   	ret    

f0102bd7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102bd7:	55                   	push   %ebp
f0102bd8:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102bda:	83 fa 01             	cmp    $0x1,%edx
f0102bdd:	7e 0e                	jle    f0102bed <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102bdf:	8b 10                	mov    (%eax),%edx
f0102be1:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102be4:	89 08                	mov    %ecx,(%eax)
f0102be6:	8b 02                	mov    (%edx),%eax
f0102be8:	8b 52 04             	mov    0x4(%edx),%edx
f0102beb:	eb 22                	jmp    f0102c0f <getuint+0x38>
	else if (lflag)
f0102bed:	85 d2                	test   %edx,%edx
f0102bef:	74 10                	je     f0102c01 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102bf1:	8b 10                	mov    (%eax),%edx
f0102bf3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102bf6:	89 08                	mov    %ecx,(%eax)
f0102bf8:	8b 02                	mov    (%edx),%eax
f0102bfa:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bff:	eb 0e                	jmp    f0102c0f <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102c01:	8b 10                	mov    (%eax),%edx
f0102c03:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c06:	89 08                	mov    %ecx,(%eax)
f0102c08:	8b 02                	mov    (%edx),%eax
f0102c0a:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102c0f:	5d                   	pop    %ebp
f0102c10:	c3                   	ret    

f0102c11 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c11:	55                   	push   %ebp
f0102c12:	89 e5                	mov    %esp,%ebp
f0102c14:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c17:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102c1b:	8b 10                	mov    (%eax),%edx
f0102c1d:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c20:	73 0a                	jae    f0102c2c <sprintputch+0x1b>
		*b->buf++ = ch;
f0102c22:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c25:	89 08                	mov    %ecx,(%eax)
f0102c27:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c2a:	88 02                	mov    %al,(%edx)
}
f0102c2c:	5d                   	pop    %ebp
f0102c2d:	c3                   	ret    

f0102c2e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102c2e:	55                   	push   %ebp
f0102c2f:	89 e5                	mov    %esp,%ebp
f0102c31:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102c34:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102c37:	50                   	push   %eax
f0102c38:	ff 75 10             	pushl  0x10(%ebp)
f0102c3b:	ff 75 0c             	pushl  0xc(%ebp)
f0102c3e:	ff 75 08             	pushl  0x8(%ebp)
f0102c41:	e8 05 00 00 00       	call   f0102c4b <vprintfmt>
	va_end(ap);
}
f0102c46:	83 c4 10             	add    $0x10,%esp
f0102c49:	c9                   	leave  
f0102c4a:	c3                   	ret    

f0102c4b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c4b:	55                   	push   %ebp
f0102c4c:	89 e5                	mov    %esp,%ebp
f0102c4e:	57                   	push   %edi
f0102c4f:	56                   	push   %esi
f0102c50:	53                   	push   %ebx
f0102c51:	83 ec 2c             	sub    $0x2c,%esp
f0102c54:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c5a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c5d:	eb 12                	jmp    f0102c71 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102c5f:	85 c0                	test   %eax,%eax
f0102c61:	0f 84 89 03 00 00    	je     f0102ff0 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102c67:	83 ec 08             	sub    $0x8,%esp
f0102c6a:	53                   	push   %ebx
f0102c6b:	50                   	push   %eax
f0102c6c:	ff d6                	call   *%esi
f0102c6e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c71:	83 c7 01             	add    $0x1,%edi
f0102c74:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c78:	83 f8 25             	cmp    $0x25,%eax
f0102c7b:	75 e2                	jne    f0102c5f <vprintfmt+0x14>
f0102c7d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c81:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c88:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c8f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c96:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c9b:	eb 07                	jmp    f0102ca4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ca0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ca4:	8d 47 01             	lea    0x1(%edi),%eax
f0102ca7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102caa:	0f b6 07             	movzbl (%edi),%eax
f0102cad:	0f b6 c8             	movzbl %al,%ecx
f0102cb0:	83 e8 23             	sub    $0x23,%eax
f0102cb3:	3c 55                	cmp    $0x55,%al
f0102cb5:	0f 87 1a 03 00 00    	ja     f0102fd5 <vprintfmt+0x38a>
f0102cbb:	0f b6 c0             	movzbl %al,%eax
f0102cbe:	ff 24 85 e8 47 10 f0 	jmp    *-0xfefb818(,%eax,4)
f0102cc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102cc8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102ccc:	eb d6                	jmp    f0102ca4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cd1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cd6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102cd9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102cdc:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102ce0:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102ce3:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102ce6:	83 fa 09             	cmp    $0x9,%edx
f0102ce9:	77 39                	ja     f0102d24 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102ceb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102cee:	eb e9                	jmp    f0102cd9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102cf0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf3:	8d 48 04             	lea    0x4(%eax),%ecx
f0102cf6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102cf9:	8b 00                	mov    (%eax),%eax
f0102cfb:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cfe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102d01:	eb 27                	jmp    f0102d2a <vprintfmt+0xdf>
f0102d03:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d06:	85 c0                	test   %eax,%eax
f0102d08:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d0d:	0f 49 c8             	cmovns %eax,%ecx
f0102d10:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d16:	eb 8c                	jmp    f0102ca4 <vprintfmt+0x59>
f0102d18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d1b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d22:	eb 80                	jmp    f0102ca4 <vprintfmt+0x59>
f0102d24:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102d27:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102d2a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d2e:	0f 89 70 ff ff ff    	jns    f0102ca4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102d34:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d37:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d3a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d41:	e9 5e ff ff ff       	jmp    f0102ca4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102d46:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102d4c:	e9 53 ff ff ff       	jmp    f0102ca4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d51:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d54:	8d 50 04             	lea    0x4(%eax),%edx
f0102d57:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d5a:	83 ec 08             	sub    $0x8,%esp
f0102d5d:	53                   	push   %ebx
f0102d5e:	ff 30                	pushl  (%eax)
f0102d60:	ff d6                	call   *%esi
			break;
f0102d62:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102d68:	e9 04 ff ff ff       	jmp    f0102c71 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d70:	8d 50 04             	lea    0x4(%eax),%edx
f0102d73:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d76:	8b 00                	mov    (%eax),%eax
f0102d78:	99                   	cltd   
f0102d79:	31 d0                	xor    %edx,%eax
f0102d7b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d7d:	83 f8 06             	cmp    $0x6,%eax
f0102d80:	7f 0b                	jg     f0102d8d <vprintfmt+0x142>
f0102d82:	8b 14 85 40 49 10 f0 	mov    -0xfefb6c0(,%eax,4),%edx
f0102d89:	85 d2                	test   %edx,%edx
f0102d8b:	75 18                	jne    f0102da5 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102d8d:	50                   	push   %eax
f0102d8e:	68 73 47 10 f0       	push   $0xf0104773
f0102d93:	53                   	push   %ebx
f0102d94:	56                   	push   %esi
f0102d95:	e8 94 fe ff ff       	call   f0102c2e <printfmt>
f0102d9a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102da0:	e9 cc fe ff ff       	jmp    f0102c71 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102da5:	52                   	push   %edx
f0102da6:	68 6c 44 10 f0       	push   $0xf010446c
f0102dab:	53                   	push   %ebx
f0102dac:	56                   	push   %esi
f0102dad:	e8 7c fe ff ff       	call   f0102c2e <printfmt>
f0102db2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102db5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102db8:	e9 b4 fe ff ff       	jmp    f0102c71 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc0:	8d 50 04             	lea    0x4(%eax),%edx
f0102dc3:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dc6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102dc8:	85 ff                	test   %edi,%edi
f0102dca:	b8 6c 47 10 f0       	mov    $0xf010476c,%eax
f0102dcf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102dd2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102dd6:	0f 8e 94 00 00 00    	jle    f0102e70 <vprintfmt+0x225>
f0102ddc:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102de0:	0f 84 98 00 00 00    	je     f0102e7e <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102de6:	83 ec 08             	sub    $0x8,%esp
f0102de9:	ff 75 d0             	pushl  -0x30(%ebp)
f0102dec:	57                   	push   %edi
f0102ded:	e8 5f 03 00 00       	call   f0103151 <strnlen>
f0102df2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102df5:	29 c1                	sub    %eax,%ecx
f0102df7:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102dfa:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102dfd:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e04:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e07:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e09:	eb 0f                	jmp    f0102e1a <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102e0b:	83 ec 08             	sub    $0x8,%esp
f0102e0e:	53                   	push   %ebx
f0102e0f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e12:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e14:	83 ef 01             	sub    $0x1,%edi
f0102e17:	83 c4 10             	add    $0x10,%esp
f0102e1a:	85 ff                	test   %edi,%edi
f0102e1c:	7f ed                	jg     f0102e0b <vprintfmt+0x1c0>
f0102e1e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e21:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102e24:	85 c9                	test   %ecx,%ecx
f0102e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e2b:	0f 49 c1             	cmovns %ecx,%eax
f0102e2e:	29 c1                	sub    %eax,%ecx
f0102e30:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e33:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e36:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e39:	89 cb                	mov    %ecx,%ebx
f0102e3b:	eb 4d                	jmp    f0102e8a <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102e3d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102e41:	74 1b                	je     f0102e5e <vprintfmt+0x213>
f0102e43:	0f be c0             	movsbl %al,%eax
f0102e46:	83 e8 20             	sub    $0x20,%eax
f0102e49:	83 f8 5e             	cmp    $0x5e,%eax
f0102e4c:	76 10                	jbe    f0102e5e <vprintfmt+0x213>
					putch('?', putdat);
f0102e4e:	83 ec 08             	sub    $0x8,%esp
f0102e51:	ff 75 0c             	pushl  0xc(%ebp)
f0102e54:	6a 3f                	push   $0x3f
f0102e56:	ff 55 08             	call   *0x8(%ebp)
f0102e59:	83 c4 10             	add    $0x10,%esp
f0102e5c:	eb 0d                	jmp    f0102e6b <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102e5e:	83 ec 08             	sub    $0x8,%esp
f0102e61:	ff 75 0c             	pushl  0xc(%ebp)
f0102e64:	52                   	push   %edx
f0102e65:	ff 55 08             	call   *0x8(%ebp)
f0102e68:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e6b:	83 eb 01             	sub    $0x1,%ebx
f0102e6e:	eb 1a                	jmp    f0102e8a <vprintfmt+0x23f>
f0102e70:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e73:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e76:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e79:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e7c:	eb 0c                	jmp    f0102e8a <vprintfmt+0x23f>
f0102e7e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e81:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e84:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e87:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e8a:	83 c7 01             	add    $0x1,%edi
f0102e8d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e91:	0f be d0             	movsbl %al,%edx
f0102e94:	85 d2                	test   %edx,%edx
f0102e96:	74 23                	je     f0102ebb <vprintfmt+0x270>
f0102e98:	85 f6                	test   %esi,%esi
f0102e9a:	78 a1                	js     f0102e3d <vprintfmt+0x1f2>
f0102e9c:	83 ee 01             	sub    $0x1,%esi
f0102e9f:	79 9c                	jns    f0102e3d <vprintfmt+0x1f2>
f0102ea1:	89 df                	mov    %ebx,%edi
f0102ea3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ea6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ea9:	eb 18                	jmp    f0102ec3 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102eab:	83 ec 08             	sub    $0x8,%esp
f0102eae:	53                   	push   %ebx
f0102eaf:	6a 20                	push   $0x20
f0102eb1:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102eb3:	83 ef 01             	sub    $0x1,%edi
f0102eb6:	83 c4 10             	add    $0x10,%esp
f0102eb9:	eb 08                	jmp    f0102ec3 <vprintfmt+0x278>
f0102ebb:	89 df                	mov    %ebx,%edi
f0102ebd:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ec0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ec3:	85 ff                	test   %edi,%edi
f0102ec5:	7f e4                	jg     f0102eab <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ec7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102eca:	e9 a2 fd ff ff       	jmp    f0102c71 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ecf:	83 fa 01             	cmp    $0x1,%edx
f0102ed2:	7e 16                	jle    f0102eea <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102ed4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ed7:	8d 50 08             	lea    0x8(%eax),%edx
f0102eda:	89 55 14             	mov    %edx,0x14(%ebp)
f0102edd:	8b 50 04             	mov    0x4(%eax),%edx
f0102ee0:	8b 00                	mov    (%eax),%eax
f0102ee2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ee5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102ee8:	eb 32                	jmp    f0102f1c <vprintfmt+0x2d1>
	else if (lflag)
f0102eea:	85 d2                	test   %edx,%edx
f0102eec:	74 18                	je     f0102f06 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102eee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef1:	8d 50 04             	lea    0x4(%eax),%edx
f0102ef4:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ef7:	8b 00                	mov    (%eax),%eax
f0102ef9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102efc:	89 c1                	mov    %eax,%ecx
f0102efe:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f01:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f04:	eb 16                	jmp    f0102f1c <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102f06:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f09:	8d 50 04             	lea    0x4(%eax),%edx
f0102f0c:	89 55 14             	mov    %edx,0x14(%ebp)
f0102f0f:	8b 00                	mov    (%eax),%eax
f0102f11:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f14:	89 c1                	mov    %eax,%ecx
f0102f16:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f19:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102f1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102f1f:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102f22:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102f27:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102f2b:	79 74                	jns    f0102fa1 <vprintfmt+0x356>
				putch('-', putdat);
f0102f2d:	83 ec 08             	sub    $0x8,%esp
f0102f30:	53                   	push   %ebx
f0102f31:	6a 2d                	push   $0x2d
f0102f33:	ff d6                	call   *%esi
				num = -(long long) num;
f0102f35:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102f38:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f3b:	f7 d8                	neg    %eax
f0102f3d:	83 d2 00             	adc    $0x0,%edx
f0102f40:	f7 da                	neg    %edx
f0102f42:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102f45:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102f4a:	eb 55                	jmp    f0102fa1 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102f4c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f4f:	e8 83 fc ff ff       	call   f0102bd7 <getuint>
			base = 10;
f0102f54:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102f59:	eb 46                	jmp    f0102fa1 <vprintfmt+0x356>

		// (unsigned) octal
	        case 'o':
			num = getuint(&ap, lflag);
f0102f5b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f5e:	e8 74 fc ff ff       	call   f0102bd7 <getuint>
			base = 8;
f0102f63:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102f68:	eb 37                	jmp    f0102fa1 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102f6a:	83 ec 08             	sub    $0x8,%esp
f0102f6d:	53                   	push   %ebx
f0102f6e:	6a 30                	push   $0x30
f0102f70:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f72:	83 c4 08             	add    $0x8,%esp
f0102f75:	53                   	push   %ebx
f0102f76:	6a 78                	push   $0x78
f0102f78:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7d:	8d 50 04             	lea    0x4(%eax),%edx
f0102f80:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f83:	8b 00                	mov    (%eax),%eax
f0102f85:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f8a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f8d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f92:	eb 0d                	jmp    f0102fa1 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f94:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f97:	e8 3b fc ff ff       	call   f0102bd7 <getuint>
			base = 16;
f0102f9c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102fa1:	83 ec 0c             	sub    $0xc,%esp
f0102fa4:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102fa8:	57                   	push   %edi
f0102fa9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102fac:	51                   	push   %ecx
f0102fad:	52                   	push   %edx
f0102fae:	50                   	push   %eax
f0102faf:	89 da                	mov    %ebx,%edx
f0102fb1:	89 f0                	mov    %esi,%eax
f0102fb3:	e8 70 fb ff ff       	call   f0102b28 <printnum>
			break;
f0102fb8:	83 c4 20             	add    $0x20,%esp
f0102fbb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fbe:	e9 ae fc ff ff       	jmp    f0102c71 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102fc3:	83 ec 08             	sub    $0x8,%esp
f0102fc6:	53                   	push   %ebx
f0102fc7:	51                   	push   %ecx
f0102fc8:	ff d6                	call   *%esi
			break;
f0102fca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fd0:	e9 9c fc ff ff       	jmp    f0102c71 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fd5:	83 ec 08             	sub    $0x8,%esp
f0102fd8:	53                   	push   %ebx
f0102fd9:	6a 25                	push   $0x25
f0102fdb:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102fdd:	83 c4 10             	add    $0x10,%esp
f0102fe0:	eb 03                	jmp    f0102fe5 <vprintfmt+0x39a>
f0102fe2:	83 ef 01             	sub    $0x1,%edi
f0102fe5:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102fe9:	75 f7                	jne    f0102fe2 <vprintfmt+0x397>
f0102feb:	e9 81 fc ff ff       	jmp    f0102c71 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ff0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ff3:	5b                   	pop    %ebx
f0102ff4:	5e                   	pop    %esi
f0102ff5:	5f                   	pop    %edi
f0102ff6:	5d                   	pop    %ebp
f0102ff7:	c3                   	ret    

f0102ff8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ff8:	55                   	push   %ebp
f0102ff9:	89 e5                	mov    %esp,%ebp
f0102ffb:	83 ec 18             	sub    $0x18,%esp
f0102ffe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103001:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103004:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103007:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010300b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010300e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103015:	85 c0                	test   %eax,%eax
f0103017:	74 26                	je     f010303f <vsnprintf+0x47>
f0103019:	85 d2                	test   %edx,%edx
f010301b:	7e 22                	jle    f010303f <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010301d:	ff 75 14             	pushl  0x14(%ebp)
f0103020:	ff 75 10             	pushl  0x10(%ebp)
f0103023:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103026:	50                   	push   %eax
f0103027:	68 11 2c 10 f0       	push   $0xf0102c11
f010302c:	e8 1a fc ff ff       	call   f0102c4b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103031:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103034:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103037:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010303a:	83 c4 10             	add    $0x10,%esp
f010303d:	eb 05                	jmp    f0103044 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010303f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103044:	c9                   	leave  
f0103045:	c3                   	ret    

f0103046 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103046:	55                   	push   %ebp
f0103047:	89 e5                	mov    %esp,%ebp
f0103049:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010304c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010304f:	50                   	push   %eax
f0103050:	ff 75 10             	pushl  0x10(%ebp)
f0103053:	ff 75 0c             	pushl  0xc(%ebp)
f0103056:	ff 75 08             	pushl  0x8(%ebp)
f0103059:	e8 9a ff ff ff       	call   f0102ff8 <vsnprintf>
	va_end(ap);

	return rc;
}
f010305e:	c9                   	leave  
f010305f:	c3                   	ret    

f0103060 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103060:	55                   	push   %ebp
f0103061:	89 e5                	mov    %esp,%ebp
f0103063:	57                   	push   %edi
f0103064:	56                   	push   %esi
f0103065:	53                   	push   %ebx
f0103066:	83 ec 0c             	sub    $0xc,%esp
f0103069:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010306c:	85 c0                	test   %eax,%eax
f010306e:	74 11                	je     f0103081 <readline+0x21>
		cprintf("%s", prompt);
f0103070:	83 ec 08             	sub    $0x8,%esp
f0103073:	50                   	push   %eax
f0103074:	68 6c 44 10 f0       	push   $0xf010446c
f0103079:	e8 80 f7 ff ff       	call   f01027fe <cprintf>
f010307e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103081:	83 ec 0c             	sub    $0xc,%esp
f0103084:	6a 00                	push   $0x0
f0103086:	e8 96 d5 ff ff       	call   f0100621 <iscons>
f010308b:	89 c7                	mov    %eax,%edi
f010308d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103090:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103095:	e8 76 d5 ff ff       	call   f0100610 <getchar>
f010309a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010309c:	85 c0                	test   %eax,%eax
f010309e:	79 18                	jns    f01030b8 <readline+0x58>
			cprintf("read error: %e\n", c);
f01030a0:	83 ec 08             	sub    $0x8,%esp
f01030a3:	50                   	push   %eax
f01030a4:	68 5c 49 10 f0       	push   $0xf010495c
f01030a9:	e8 50 f7 ff ff       	call   f01027fe <cprintf>
			return NULL;
f01030ae:	83 c4 10             	add    $0x10,%esp
f01030b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01030b6:	eb 79                	jmp    f0103131 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01030b8:	83 f8 08             	cmp    $0x8,%eax
f01030bb:	0f 94 c2             	sete   %dl
f01030be:	83 f8 7f             	cmp    $0x7f,%eax
f01030c1:	0f 94 c0             	sete   %al
f01030c4:	08 c2                	or     %al,%dl
f01030c6:	74 1a                	je     f01030e2 <readline+0x82>
f01030c8:	85 f6                	test   %esi,%esi
f01030ca:	7e 16                	jle    f01030e2 <readline+0x82>
			if (echoing)
f01030cc:	85 ff                	test   %edi,%edi
f01030ce:	74 0d                	je     f01030dd <readline+0x7d>
				cputchar('\b');
f01030d0:	83 ec 0c             	sub    $0xc,%esp
f01030d3:	6a 08                	push   $0x8
f01030d5:	e8 26 d5 ff ff       	call   f0100600 <cputchar>
f01030da:	83 c4 10             	add    $0x10,%esp
			i--;
f01030dd:	83 ee 01             	sub    $0x1,%esi
f01030e0:	eb b3                	jmp    f0103095 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030e2:	83 fb 1f             	cmp    $0x1f,%ebx
f01030e5:	7e 23                	jle    f010310a <readline+0xaa>
f01030e7:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030ed:	7f 1b                	jg     f010310a <readline+0xaa>
			if (echoing)
f01030ef:	85 ff                	test   %edi,%edi
f01030f1:	74 0c                	je     f01030ff <readline+0x9f>
				cputchar(c);
f01030f3:	83 ec 0c             	sub    $0xc,%esp
f01030f6:	53                   	push   %ebx
f01030f7:	e8 04 d5 ff ff       	call   f0100600 <cputchar>
f01030fc:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030ff:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103105:	8d 76 01             	lea    0x1(%esi),%esi
f0103108:	eb 8b                	jmp    f0103095 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010310a:	83 fb 0a             	cmp    $0xa,%ebx
f010310d:	74 05                	je     f0103114 <readline+0xb4>
f010310f:	83 fb 0d             	cmp    $0xd,%ebx
f0103112:	75 81                	jne    f0103095 <readline+0x35>
			if (echoing)
f0103114:	85 ff                	test   %edi,%edi
f0103116:	74 0d                	je     f0103125 <readline+0xc5>
				cputchar('\n');
f0103118:	83 ec 0c             	sub    $0xc,%esp
f010311b:	6a 0a                	push   $0xa
f010311d:	e8 de d4 ff ff       	call   f0100600 <cputchar>
f0103122:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103125:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010312c:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103131:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103134:	5b                   	pop    %ebx
f0103135:	5e                   	pop    %esi
f0103136:	5f                   	pop    %edi
f0103137:	5d                   	pop    %ebp
f0103138:	c3                   	ret    

f0103139 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103139:	55                   	push   %ebp
f010313a:	89 e5                	mov    %esp,%ebp
f010313c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010313f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103144:	eb 03                	jmp    f0103149 <strlen+0x10>
		n++;
f0103146:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103149:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010314d:	75 f7                	jne    f0103146 <strlen+0xd>
		n++;
	return n;
}
f010314f:	5d                   	pop    %ebp
f0103150:	c3                   	ret    

f0103151 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103151:	55                   	push   %ebp
f0103152:	89 e5                	mov    %esp,%ebp
f0103154:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103157:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010315a:	ba 00 00 00 00       	mov    $0x0,%edx
f010315f:	eb 03                	jmp    f0103164 <strnlen+0x13>
		n++;
f0103161:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103164:	39 c2                	cmp    %eax,%edx
f0103166:	74 08                	je     f0103170 <strnlen+0x1f>
f0103168:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010316c:	75 f3                	jne    f0103161 <strnlen+0x10>
f010316e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103170:	5d                   	pop    %ebp
f0103171:	c3                   	ret    

f0103172 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103172:	55                   	push   %ebp
f0103173:	89 e5                	mov    %esp,%ebp
f0103175:	53                   	push   %ebx
f0103176:	8b 45 08             	mov    0x8(%ebp),%eax
f0103179:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010317c:	89 c2                	mov    %eax,%edx
f010317e:	83 c2 01             	add    $0x1,%edx
f0103181:	83 c1 01             	add    $0x1,%ecx
f0103184:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103188:	88 5a ff             	mov    %bl,-0x1(%edx)
f010318b:	84 db                	test   %bl,%bl
f010318d:	75 ef                	jne    f010317e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010318f:	5b                   	pop    %ebx
f0103190:	5d                   	pop    %ebp
f0103191:	c3                   	ret    

f0103192 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103192:	55                   	push   %ebp
f0103193:	89 e5                	mov    %esp,%ebp
f0103195:	53                   	push   %ebx
f0103196:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103199:	53                   	push   %ebx
f010319a:	e8 9a ff ff ff       	call   f0103139 <strlen>
f010319f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01031a2:	ff 75 0c             	pushl  0xc(%ebp)
f01031a5:	01 d8                	add    %ebx,%eax
f01031a7:	50                   	push   %eax
f01031a8:	e8 c5 ff ff ff       	call   f0103172 <strcpy>
	return dst;
}
f01031ad:	89 d8                	mov    %ebx,%eax
f01031af:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031b2:	c9                   	leave  
f01031b3:	c3                   	ret    

f01031b4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01031b4:	55                   	push   %ebp
f01031b5:	89 e5                	mov    %esp,%ebp
f01031b7:	56                   	push   %esi
f01031b8:	53                   	push   %ebx
f01031b9:	8b 75 08             	mov    0x8(%ebp),%esi
f01031bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031bf:	89 f3                	mov    %esi,%ebx
f01031c1:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031c4:	89 f2                	mov    %esi,%edx
f01031c6:	eb 0f                	jmp    f01031d7 <strncpy+0x23>
		*dst++ = *src;
f01031c8:	83 c2 01             	add    $0x1,%edx
f01031cb:	0f b6 01             	movzbl (%ecx),%eax
f01031ce:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031d1:	80 39 01             	cmpb   $0x1,(%ecx)
f01031d4:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031d7:	39 da                	cmp    %ebx,%edx
f01031d9:	75 ed                	jne    f01031c8 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031db:	89 f0                	mov    %esi,%eax
f01031dd:	5b                   	pop    %ebx
f01031de:	5e                   	pop    %esi
f01031df:	5d                   	pop    %ebp
f01031e0:	c3                   	ret    

f01031e1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031e1:	55                   	push   %ebp
f01031e2:	89 e5                	mov    %esp,%ebp
f01031e4:	56                   	push   %esi
f01031e5:	53                   	push   %ebx
f01031e6:	8b 75 08             	mov    0x8(%ebp),%esi
f01031e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031ec:	8b 55 10             	mov    0x10(%ebp),%edx
f01031ef:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031f1:	85 d2                	test   %edx,%edx
f01031f3:	74 21                	je     f0103216 <strlcpy+0x35>
f01031f5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031f9:	89 f2                	mov    %esi,%edx
f01031fb:	eb 09                	jmp    f0103206 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031fd:	83 c2 01             	add    $0x1,%edx
f0103200:	83 c1 01             	add    $0x1,%ecx
f0103203:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103206:	39 c2                	cmp    %eax,%edx
f0103208:	74 09                	je     f0103213 <strlcpy+0x32>
f010320a:	0f b6 19             	movzbl (%ecx),%ebx
f010320d:	84 db                	test   %bl,%bl
f010320f:	75 ec                	jne    f01031fd <strlcpy+0x1c>
f0103211:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103213:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103216:	29 f0                	sub    %esi,%eax
}
f0103218:	5b                   	pop    %ebx
f0103219:	5e                   	pop    %esi
f010321a:	5d                   	pop    %ebp
f010321b:	c3                   	ret    

f010321c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010321c:	55                   	push   %ebp
f010321d:	89 e5                	mov    %esp,%ebp
f010321f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103222:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103225:	eb 06                	jmp    f010322d <strcmp+0x11>
		p++, q++;
f0103227:	83 c1 01             	add    $0x1,%ecx
f010322a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010322d:	0f b6 01             	movzbl (%ecx),%eax
f0103230:	84 c0                	test   %al,%al
f0103232:	74 04                	je     f0103238 <strcmp+0x1c>
f0103234:	3a 02                	cmp    (%edx),%al
f0103236:	74 ef                	je     f0103227 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103238:	0f b6 c0             	movzbl %al,%eax
f010323b:	0f b6 12             	movzbl (%edx),%edx
f010323e:	29 d0                	sub    %edx,%eax
}
f0103240:	5d                   	pop    %ebp
f0103241:	c3                   	ret    

f0103242 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103242:	55                   	push   %ebp
f0103243:	89 e5                	mov    %esp,%ebp
f0103245:	53                   	push   %ebx
f0103246:	8b 45 08             	mov    0x8(%ebp),%eax
f0103249:	8b 55 0c             	mov    0xc(%ebp),%edx
f010324c:	89 c3                	mov    %eax,%ebx
f010324e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103251:	eb 06                	jmp    f0103259 <strncmp+0x17>
		n--, p++, q++;
f0103253:	83 c0 01             	add    $0x1,%eax
f0103256:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103259:	39 d8                	cmp    %ebx,%eax
f010325b:	74 15                	je     f0103272 <strncmp+0x30>
f010325d:	0f b6 08             	movzbl (%eax),%ecx
f0103260:	84 c9                	test   %cl,%cl
f0103262:	74 04                	je     f0103268 <strncmp+0x26>
f0103264:	3a 0a                	cmp    (%edx),%cl
f0103266:	74 eb                	je     f0103253 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103268:	0f b6 00             	movzbl (%eax),%eax
f010326b:	0f b6 12             	movzbl (%edx),%edx
f010326e:	29 d0                	sub    %edx,%eax
f0103270:	eb 05                	jmp    f0103277 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103272:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103277:	5b                   	pop    %ebx
f0103278:	5d                   	pop    %ebp
f0103279:	c3                   	ret    

f010327a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010327a:	55                   	push   %ebp
f010327b:	89 e5                	mov    %esp,%ebp
f010327d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103280:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103284:	eb 07                	jmp    f010328d <strchr+0x13>
		if (*s == c)
f0103286:	38 ca                	cmp    %cl,%dl
f0103288:	74 0f                	je     f0103299 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010328a:	83 c0 01             	add    $0x1,%eax
f010328d:	0f b6 10             	movzbl (%eax),%edx
f0103290:	84 d2                	test   %dl,%dl
f0103292:	75 f2                	jne    f0103286 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103294:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103299:	5d                   	pop    %ebp
f010329a:	c3                   	ret    

f010329b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010329b:	55                   	push   %ebp
f010329c:	89 e5                	mov    %esp,%ebp
f010329e:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01032a5:	eb 03                	jmp    f01032aa <strfind+0xf>
f01032a7:	83 c0 01             	add    $0x1,%eax
f01032aa:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01032ad:	38 ca                	cmp    %cl,%dl
f01032af:	74 04                	je     f01032b5 <strfind+0x1a>
f01032b1:	84 d2                	test   %dl,%dl
f01032b3:	75 f2                	jne    f01032a7 <strfind+0xc>
			break;
	return (char *) s;
}
f01032b5:	5d                   	pop    %ebp
f01032b6:	c3                   	ret    

f01032b7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01032b7:	55                   	push   %ebp
f01032b8:	89 e5                	mov    %esp,%ebp
f01032ba:	57                   	push   %edi
f01032bb:	56                   	push   %esi
f01032bc:	53                   	push   %ebx
f01032bd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01032c3:	85 c9                	test   %ecx,%ecx
f01032c5:	74 36                	je     f01032fd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01032c7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01032cd:	75 28                	jne    f01032f7 <memset+0x40>
f01032cf:	f6 c1 03             	test   $0x3,%cl
f01032d2:	75 23                	jne    f01032f7 <memset+0x40>
		c &= 0xFF;
f01032d4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032d8:	89 d3                	mov    %edx,%ebx
f01032da:	c1 e3 08             	shl    $0x8,%ebx
f01032dd:	89 d6                	mov    %edx,%esi
f01032df:	c1 e6 18             	shl    $0x18,%esi
f01032e2:	89 d0                	mov    %edx,%eax
f01032e4:	c1 e0 10             	shl    $0x10,%eax
f01032e7:	09 f0                	or     %esi,%eax
f01032e9:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032eb:	89 d8                	mov    %ebx,%eax
f01032ed:	09 d0                	or     %edx,%eax
f01032ef:	c1 e9 02             	shr    $0x2,%ecx
f01032f2:	fc                   	cld    
f01032f3:	f3 ab                	rep stos %eax,%es:(%edi)
f01032f5:	eb 06                	jmp    f01032fd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032fa:	fc                   	cld    
f01032fb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01032fd:	89 f8                	mov    %edi,%eax
f01032ff:	5b                   	pop    %ebx
f0103300:	5e                   	pop    %esi
f0103301:	5f                   	pop    %edi
f0103302:	5d                   	pop    %ebp
f0103303:	c3                   	ret    

f0103304 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103304:	55                   	push   %ebp
f0103305:	89 e5                	mov    %esp,%ebp
f0103307:	57                   	push   %edi
f0103308:	56                   	push   %esi
f0103309:	8b 45 08             	mov    0x8(%ebp),%eax
f010330c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010330f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103312:	39 c6                	cmp    %eax,%esi
f0103314:	73 35                	jae    f010334b <memmove+0x47>
f0103316:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103319:	39 d0                	cmp    %edx,%eax
f010331b:	73 2e                	jae    f010334b <memmove+0x47>
		s += n;
		d += n;
f010331d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103320:	89 d6                	mov    %edx,%esi
f0103322:	09 fe                	or     %edi,%esi
f0103324:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010332a:	75 13                	jne    f010333f <memmove+0x3b>
f010332c:	f6 c1 03             	test   $0x3,%cl
f010332f:	75 0e                	jne    f010333f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103331:	83 ef 04             	sub    $0x4,%edi
f0103334:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103337:	c1 e9 02             	shr    $0x2,%ecx
f010333a:	fd                   	std    
f010333b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010333d:	eb 09                	jmp    f0103348 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010333f:	83 ef 01             	sub    $0x1,%edi
f0103342:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103345:	fd                   	std    
f0103346:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103348:	fc                   	cld    
f0103349:	eb 1d                	jmp    f0103368 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010334b:	89 f2                	mov    %esi,%edx
f010334d:	09 c2                	or     %eax,%edx
f010334f:	f6 c2 03             	test   $0x3,%dl
f0103352:	75 0f                	jne    f0103363 <memmove+0x5f>
f0103354:	f6 c1 03             	test   $0x3,%cl
f0103357:	75 0a                	jne    f0103363 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103359:	c1 e9 02             	shr    $0x2,%ecx
f010335c:	89 c7                	mov    %eax,%edi
f010335e:	fc                   	cld    
f010335f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103361:	eb 05                	jmp    f0103368 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103363:	89 c7                	mov    %eax,%edi
f0103365:	fc                   	cld    
f0103366:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103368:	5e                   	pop    %esi
f0103369:	5f                   	pop    %edi
f010336a:	5d                   	pop    %ebp
f010336b:	c3                   	ret    

f010336c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010336c:	55                   	push   %ebp
f010336d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010336f:	ff 75 10             	pushl  0x10(%ebp)
f0103372:	ff 75 0c             	pushl  0xc(%ebp)
f0103375:	ff 75 08             	pushl  0x8(%ebp)
f0103378:	e8 87 ff ff ff       	call   f0103304 <memmove>
}
f010337d:	c9                   	leave  
f010337e:	c3                   	ret    

f010337f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010337f:	55                   	push   %ebp
f0103380:	89 e5                	mov    %esp,%ebp
f0103382:	56                   	push   %esi
f0103383:	53                   	push   %ebx
f0103384:	8b 45 08             	mov    0x8(%ebp),%eax
f0103387:	8b 55 0c             	mov    0xc(%ebp),%edx
f010338a:	89 c6                	mov    %eax,%esi
f010338c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010338f:	eb 1a                	jmp    f01033ab <memcmp+0x2c>
		if (*s1 != *s2)
f0103391:	0f b6 08             	movzbl (%eax),%ecx
f0103394:	0f b6 1a             	movzbl (%edx),%ebx
f0103397:	38 d9                	cmp    %bl,%cl
f0103399:	74 0a                	je     f01033a5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010339b:	0f b6 c1             	movzbl %cl,%eax
f010339e:	0f b6 db             	movzbl %bl,%ebx
f01033a1:	29 d8                	sub    %ebx,%eax
f01033a3:	eb 0f                	jmp    f01033b4 <memcmp+0x35>
		s1++, s2++;
f01033a5:	83 c0 01             	add    $0x1,%eax
f01033a8:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01033ab:	39 f0                	cmp    %esi,%eax
f01033ad:	75 e2                	jne    f0103391 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01033af:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033b4:	5b                   	pop    %ebx
f01033b5:	5e                   	pop    %esi
f01033b6:	5d                   	pop    %ebp
f01033b7:	c3                   	ret    

f01033b8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01033b8:	55                   	push   %ebp
f01033b9:	89 e5                	mov    %esp,%ebp
f01033bb:	53                   	push   %ebx
f01033bc:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01033bf:	89 c1                	mov    %eax,%ecx
f01033c1:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01033c4:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033c8:	eb 0a                	jmp    f01033d4 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033ca:	0f b6 10             	movzbl (%eax),%edx
f01033cd:	39 da                	cmp    %ebx,%edx
f01033cf:	74 07                	je     f01033d8 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033d1:	83 c0 01             	add    $0x1,%eax
f01033d4:	39 c8                	cmp    %ecx,%eax
f01033d6:	72 f2                	jb     f01033ca <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033d8:	5b                   	pop    %ebx
f01033d9:	5d                   	pop    %ebp
f01033da:	c3                   	ret    

f01033db <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033db:	55                   	push   %ebp
f01033dc:	89 e5                	mov    %esp,%ebp
f01033de:	57                   	push   %edi
f01033df:	56                   	push   %esi
f01033e0:	53                   	push   %ebx
f01033e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033e4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033e7:	eb 03                	jmp    f01033ec <strtol+0x11>
		s++;
f01033e9:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033ec:	0f b6 01             	movzbl (%ecx),%eax
f01033ef:	3c 20                	cmp    $0x20,%al
f01033f1:	74 f6                	je     f01033e9 <strtol+0xe>
f01033f3:	3c 09                	cmp    $0x9,%al
f01033f5:	74 f2                	je     f01033e9 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033f7:	3c 2b                	cmp    $0x2b,%al
f01033f9:	75 0a                	jne    f0103405 <strtol+0x2a>
		s++;
f01033fb:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033fe:	bf 00 00 00 00       	mov    $0x0,%edi
f0103403:	eb 11                	jmp    f0103416 <strtol+0x3b>
f0103405:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010340a:	3c 2d                	cmp    $0x2d,%al
f010340c:	75 08                	jne    f0103416 <strtol+0x3b>
		s++, neg = 1;
f010340e:	83 c1 01             	add    $0x1,%ecx
f0103411:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103416:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010341c:	75 15                	jne    f0103433 <strtol+0x58>
f010341e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103421:	75 10                	jne    f0103433 <strtol+0x58>
f0103423:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103427:	75 7c                	jne    f01034a5 <strtol+0xca>
		s += 2, base = 16;
f0103429:	83 c1 02             	add    $0x2,%ecx
f010342c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103431:	eb 16                	jmp    f0103449 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103433:	85 db                	test   %ebx,%ebx
f0103435:	75 12                	jne    f0103449 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103437:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010343c:	80 39 30             	cmpb   $0x30,(%ecx)
f010343f:	75 08                	jne    f0103449 <strtol+0x6e>
		s++, base = 8;
f0103441:	83 c1 01             	add    $0x1,%ecx
f0103444:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103449:	b8 00 00 00 00       	mov    $0x0,%eax
f010344e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103451:	0f b6 11             	movzbl (%ecx),%edx
f0103454:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103457:	89 f3                	mov    %esi,%ebx
f0103459:	80 fb 09             	cmp    $0x9,%bl
f010345c:	77 08                	ja     f0103466 <strtol+0x8b>
			dig = *s - '0';
f010345e:	0f be d2             	movsbl %dl,%edx
f0103461:	83 ea 30             	sub    $0x30,%edx
f0103464:	eb 22                	jmp    f0103488 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103466:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103469:	89 f3                	mov    %esi,%ebx
f010346b:	80 fb 19             	cmp    $0x19,%bl
f010346e:	77 08                	ja     f0103478 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103470:	0f be d2             	movsbl %dl,%edx
f0103473:	83 ea 57             	sub    $0x57,%edx
f0103476:	eb 10                	jmp    f0103488 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103478:	8d 72 bf             	lea    -0x41(%edx),%esi
f010347b:	89 f3                	mov    %esi,%ebx
f010347d:	80 fb 19             	cmp    $0x19,%bl
f0103480:	77 16                	ja     f0103498 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103482:	0f be d2             	movsbl %dl,%edx
f0103485:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103488:	3b 55 10             	cmp    0x10(%ebp),%edx
f010348b:	7d 0b                	jge    f0103498 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010348d:	83 c1 01             	add    $0x1,%ecx
f0103490:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103494:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103496:	eb b9                	jmp    f0103451 <strtol+0x76>

	if (endptr)
f0103498:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010349c:	74 0d                	je     f01034ab <strtol+0xd0>
		*endptr = (char *) s;
f010349e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034a1:	89 0e                	mov    %ecx,(%esi)
f01034a3:	eb 06                	jmp    f01034ab <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034a5:	85 db                	test   %ebx,%ebx
f01034a7:	74 98                	je     f0103441 <strtol+0x66>
f01034a9:	eb 9e                	jmp    f0103449 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01034ab:	89 c2                	mov    %eax,%edx
f01034ad:	f7 da                	neg    %edx
f01034af:	85 ff                	test   %edi,%edi
f01034b1:	0f 45 c2             	cmovne %edx,%eax
}
f01034b4:	5b                   	pop    %ebx
f01034b5:	5e                   	pop    %esi
f01034b6:	5f                   	pop    %edi
f01034b7:	5d                   	pop    %ebp
f01034b8:	c3                   	ret    
f01034b9:	66 90                	xchg   %ax,%ax
f01034bb:	66 90                	xchg   %ax,%ax
f01034bd:	66 90                	xchg   %ax,%ax
f01034bf:	90                   	nop

f01034c0 <__udivdi3>:
f01034c0:	55                   	push   %ebp
f01034c1:	57                   	push   %edi
f01034c2:	56                   	push   %esi
f01034c3:	53                   	push   %ebx
f01034c4:	83 ec 1c             	sub    $0x1c,%esp
f01034c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034d7:	85 f6                	test   %esi,%esi
f01034d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034dd:	89 ca                	mov    %ecx,%edx
f01034df:	89 f8                	mov    %edi,%eax
f01034e1:	75 3d                	jne    f0103520 <__udivdi3+0x60>
f01034e3:	39 cf                	cmp    %ecx,%edi
f01034e5:	0f 87 c5 00 00 00    	ja     f01035b0 <__udivdi3+0xf0>
f01034eb:	85 ff                	test   %edi,%edi
f01034ed:	89 fd                	mov    %edi,%ebp
f01034ef:	75 0b                	jne    f01034fc <__udivdi3+0x3c>
f01034f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034f6:	31 d2                	xor    %edx,%edx
f01034f8:	f7 f7                	div    %edi
f01034fa:	89 c5                	mov    %eax,%ebp
f01034fc:	89 c8                	mov    %ecx,%eax
f01034fe:	31 d2                	xor    %edx,%edx
f0103500:	f7 f5                	div    %ebp
f0103502:	89 c1                	mov    %eax,%ecx
f0103504:	89 d8                	mov    %ebx,%eax
f0103506:	89 cf                	mov    %ecx,%edi
f0103508:	f7 f5                	div    %ebp
f010350a:	89 c3                	mov    %eax,%ebx
f010350c:	89 d8                	mov    %ebx,%eax
f010350e:	89 fa                	mov    %edi,%edx
f0103510:	83 c4 1c             	add    $0x1c,%esp
f0103513:	5b                   	pop    %ebx
f0103514:	5e                   	pop    %esi
f0103515:	5f                   	pop    %edi
f0103516:	5d                   	pop    %ebp
f0103517:	c3                   	ret    
f0103518:	90                   	nop
f0103519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103520:	39 ce                	cmp    %ecx,%esi
f0103522:	77 74                	ja     f0103598 <__udivdi3+0xd8>
f0103524:	0f bd fe             	bsr    %esi,%edi
f0103527:	83 f7 1f             	xor    $0x1f,%edi
f010352a:	0f 84 98 00 00 00    	je     f01035c8 <__udivdi3+0x108>
f0103530:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103535:	89 f9                	mov    %edi,%ecx
f0103537:	89 c5                	mov    %eax,%ebp
f0103539:	29 fb                	sub    %edi,%ebx
f010353b:	d3 e6                	shl    %cl,%esi
f010353d:	89 d9                	mov    %ebx,%ecx
f010353f:	d3 ed                	shr    %cl,%ebp
f0103541:	89 f9                	mov    %edi,%ecx
f0103543:	d3 e0                	shl    %cl,%eax
f0103545:	09 ee                	or     %ebp,%esi
f0103547:	89 d9                	mov    %ebx,%ecx
f0103549:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010354d:	89 d5                	mov    %edx,%ebp
f010354f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103553:	d3 ed                	shr    %cl,%ebp
f0103555:	89 f9                	mov    %edi,%ecx
f0103557:	d3 e2                	shl    %cl,%edx
f0103559:	89 d9                	mov    %ebx,%ecx
f010355b:	d3 e8                	shr    %cl,%eax
f010355d:	09 c2                	or     %eax,%edx
f010355f:	89 d0                	mov    %edx,%eax
f0103561:	89 ea                	mov    %ebp,%edx
f0103563:	f7 f6                	div    %esi
f0103565:	89 d5                	mov    %edx,%ebp
f0103567:	89 c3                	mov    %eax,%ebx
f0103569:	f7 64 24 0c          	mull   0xc(%esp)
f010356d:	39 d5                	cmp    %edx,%ebp
f010356f:	72 10                	jb     f0103581 <__udivdi3+0xc1>
f0103571:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103575:	89 f9                	mov    %edi,%ecx
f0103577:	d3 e6                	shl    %cl,%esi
f0103579:	39 c6                	cmp    %eax,%esi
f010357b:	73 07                	jae    f0103584 <__udivdi3+0xc4>
f010357d:	39 d5                	cmp    %edx,%ebp
f010357f:	75 03                	jne    f0103584 <__udivdi3+0xc4>
f0103581:	83 eb 01             	sub    $0x1,%ebx
f0103584:	31 ff                	xor    %edi,%edi
f0103586:	89 d8                	mov    %ebx,%eax
f0103588:	89 fa                	mov    %edi,%edx
f010358a:	83 c4 1c             	add    $0x1c,%esp
f010358d:	5b                   	pop    %ebx
f010358e:	5e                   	pop    %esi
f010358f:	5f                   	pop    %edi
f0103590:	5d                   	pop    %ebp
f0103591:	c3                   	ret    
f0103592:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103598:	31 ff                	xor    %edi,%edi
f010359a:	31 db                	xor    %ebx,%ebx
f010359c:	89 d8                	mov    %ebx,%eax
f010359e:	89 fa                	mov    %edi,%edx
f01035a0:	83 c4 1c             	add    $0x1c,%esp
f01035a3:	5b                   	pop    %ebx
f01035a4:	5e                   	pop    %esi
f01035a5:	5f                   	pop    %edi
f01035a6:	5d                   	pop    %ebp
f01035a7:	c3                   	ret    
f01035a8:	90                   	nop
f01035a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035b0:	89 d8                	mov    %ebx,%eax
f01035b2:	f7 f7                	div    %edi
f01035b4:	31 ff                	xor    %edi,%edi
f01035b6:	89 c3                	mov    %eax,%ebx
f01035b8:	89 d8                	mov    %ebx,%eax
f01035ba:	89 fa                	mov    %edi,%edx
f01035bc:	83 c4 1c             	add    $0x1c,%esp
f01035bf:	5b                   	pop    %ebx
f01035c0:	5e                   	pop    %esi
f01035c1:	5f                   	pop    %edi
f01035c2:	5d                   	pop    %ebp
f01035c3:	c3                   	ret    
f01035c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035c8:	39 ce                	cmp    %ecx,%esi
f01035ca:	72 0c                	jb     f01035d8 <__udivdi3+0x118>
f01035cc:	31 db                	xor    %ebx,%ebx
f01035ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035d2:	0f 87 34 ff ff ff    	ja     f010350c <__udivdi3+0x4c>
f01035d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035dd:	e9 2a ff ff ff       	jmp    f010350c <__udivdi3+0x4c>
f01035e2:	66 90                	xchg   %ax,%ax
f01035e4:	66 90                	xchg   %ax,%ax
f01035e6:	66 90                	xchg   %ax,%ax
f01035e8:	66 90                	xchg   %ax,%ax
f01035ea:	66 90                	xchg   %ax,%ax
f01035ec:	66 90                	xchg   %ax,%ax
f01035ee:	66 90                	xchg   %ax,%ax

f01035f0 <__umoddi3>:
f01035f0:	55                   	push   %ebp
f01035f1:	57                   	push   %edi
f01035f2:	56                   	push   %esi
f01035f3:	53                   	push   %ebx
f01035f4:	83 ec 1c             	sub    $0x1c,%esp
f01035f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103603:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103607:	85 d2                	test   %edx,%edx
f0103609:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010360d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103611:	89 f3                	mov    %esi,%ebx
f0103613:	89 3c 24             	mov    %edi,(%esp)
f0103616:	89 74 24 04          	mov    %esi,0x4(%esp)
f010361a:	75 1c                	jne    f0103638 <__umoddi3+0x48>
f010361c:	39 f7                	cmp    %esi,%edi
f010361e:	76 50                	jbe    f0103670 <__umoddi3+0x80>
f0103620:	89 c8                	mov    %ecx,%eax
f0103622:	89 f2                	mov    %esi,%edx
f0103624:	f7 f7                	div    %edi
f0103626:	89 d0                	mov    %edx,%eax
f0103628:	31 d2                	xor    %edx,%edx
f010362a:	83 c4 1c             	add    $0x1c,%esp
f010362d:	5b                   	pop    %ebx
f010362e:	5e                   	pop    %esi
f010362f:	5f                   	pop    %edi
f0103630:	5d                   	pop    %ebp
f0103631:	c3                   	ret    
f0103632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103638:	39 f2                	cmp    %esi,%edx
f010363a:	89 d0                	mov    %edx,%eax
f010363c:	77 52                	ja     f0103690 <__umoddi3+0xa0>
f010363e:	0f bd ea             	bsr    %edx,%ebp
f0103641:	83 f5 1f             	xor    $0x1f,%ebp
f0103644:	75 5a                	jne    f01036a0 <__umoddi3+0xb0>
f0103646:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010364a:	0f 82 e0 00 00 00    	jb     f0103730 <__umoddi3+0x140>
f0103650:	39 0c 24             	cmp    %ecx,(%esp)
f0103653:	0f 86 d7 00 00 00    	jbe    f0103730 <__umoddi3+0x140>
f0103659:	8b 44 24 08          	mov    0x8(%esp),%eax
f010365d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103661:	83 c4 1c             	add    $0x1c,%esp
f0103664:	5b                   	pop    %ebx
f0103665:	5e                   	pop    %esi
f0103666:	5f                   	pop    %edi
f0103667:	5d                   	pop    %ebp
f0103668:	c3                   	ret    
f0103669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103670:	85 ff                	test   %edi,%edi
f0103672:	89 fd                	mov    %edi,%ebp
f0103674:	75 0b                	jne    f0103681 <__umoddi3+0x91>
f0103676:	b8 01 00 00 00       	mov    $0x1,%eax
f010367b:	31 d2                	xor    %edx,%edx
f010367d:	f7 f7                	div    %edi
f010367f:	89 c5                	mov    %eax,%ebp
f0103681:	89 f0                	mov    %esi,%eax
f0103683:	31 d2                	xor    %edx,%edx
f0103685:	f7 f5                	div    %ebp
f0103687:	89 c8                	mov    %ecx,%eax
f0103689:	f7 f5                	div    %ebp
f010368b:	89 d0                	mov    %edx,%eax
f010368d:	eb 99                	jmp    f0103628 <__umoddi3+0x38>
f010368f:	90                   	nop
f0103690:	89 c8                	mov    %ecx,%eax
f0103692:	89 f2                	mov    %esi,%edx
f0103694:	83 c4 1c             	add    $0x1c,%esp
f0103697:	5b                   	pop    %ebx
f0103698:	5e                   	pop    %esi
f0103699:	5f                   	pop    %edi
f010369a:	5d                   	pop    %ebp
f010369b:	c3                   	ret    
f010369c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036a0:	8b 34 24             	mov    (%esp),%esi
f01036a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01036a8:	89 e9                	mov    %ebp,%ecx
f01036aa:	29 ef                	sub    %ebp,%edi
f01036ac:	d3 e0                	shl    %cl,%eax
f01036ae:	89 f9                	mov    %edi,%ecx
f01036b0:	89 f2                	mov    %esi,%edx
f01036b2:	d3 ea                	shr    %cl,%edx
f01036b4:	89 e9                	mov    %ebp,%ecx
f01036b6:	09 c2                	or     %eax,%edx
f01036b8:	89 d8                	mov    %ebx,%eax
f01036ba:	89 14 24             	mov    %edx,(%esp)
f01036bd:	89 f2                	mov    %esi,%edx
f01036bf:	d3 e2                	shl    %cl,%edx
f01036c1:	89 f9                	mov    %edi,%ecx
f01036c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036cb:	d3 e8                	shr    %cl,%eax
f01036cd:	89 e9                	mov    %ebp,%ecx
f01036cf:	89 c6                	mov    %eax,%esi
f01036d1:	d3 e3                	shl    %cl,%ebx
f01036d3:	89 f9                	mov    %edi,%ecx
f01036d5:	89 d0                	mov    %edx,%eax
f01036d7:	d3 e8                	shr    %cl,%eax
f01036d9:	89 e9                	mov    %ebp,%ecx
f01036db:	09 d8                	or     %ebx,%eax
f01036dd:	89 d3                	mov    %edx,%ebx
f01036df:	89 f2                	mov    %esi,%edx
f01036e1:	f7 34 24             	divl   (%esp)
f01036e4:	89 d6                	mov    %edx,%esi
f01036e6:	d3 e3                	shl    %cl,%ebx
f01036e8:	f7 64 24 04          	mull   0x4(%esp)
f01036ec:	39 d6                	cmp    %edx,%esi
f01036ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036f2:	89 d1                	mov    %edx,%ecx
f01036f4:	89 c3                	mov    %eax,%ebx
f01036f6:	72 08                	jb     f0103700 <__umoddi3+0x110>
f01036f8:	75 11                	jne    f010370b <__umoddi3+0x11b>
f01036fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036fe:	73 0b                	jae    f010370b <__umoddi3+0x11b>
f0103700:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103704:	1b 14 24             	sbb    (%esp),%edx
f0103707:	89 d1                	mov    %edx,%ecx
f0103709:	89 c3                	mov    %eax,%ebx
f010370b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010370f:	29 da                	sub    %ebx,%edx
f0103711:	19 ce                	sbb    %ecx,%esi
f0103713:	89 f9                	mov    %edi,%ecx
f0103715:	89 f0                	mov    %esi,%eax
f0103717:	d3 e0                	shl    %cl,%eax
f0103719:	89 e9                	mov    %ebp,%ecx
f010371b:	d3 ea                	shr    %cl,%edx
f010371d:	89 e9                	mov    %ebp,%ecx
f010371f:	d3 ee                	shr    %cl,%esi
f0103721:	09 d0                	or     %edx,%eax
f0103723:	89 f2                	mov    %esi,%edx
f0103725:	83 c4 1c             	add    $0x1c,%esp
f0103728:	5b                   	pop    %ebx
f0103729:	5e                   	pop    %esi
f010372a:	5f                   	pop    %edi
f010372b:	5d                   	pop    %ebp
f010372c:	c3                   	ret    
f010372d:	8d 76 00             	lea    0x0(%esi),%esi
f0103730:	29 f9                	sub    %edi,%ecx
f0103732:	19 d6                	sbb    %edx,%esi
f0103734:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103738:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010373c:	e9 18 ff ff ff       	jmp    f0103659 <__umoddi3+0x69>
