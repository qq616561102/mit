
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 e0 18 10 f0       	push   $0xf01018e0
f0100050:	e8 3c 09 00 00       	call   f0100991 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0a 07 00 00       	call   f0100785 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 05 09 00 00       	call   f0100991 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 99 13 00 00       	call   f010144a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 c9 08 00 00       	call   f0100991 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 43 07 00 00       	call   f0100824 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 32 19 10 f0       	push   $0xf0101932
f0100110:	e8 7c 08 00 00       	call   f0100991 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 4c 08 00 00       	call   f010096b <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100126:	e8 66 08 00 00       	call   f0100991 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 ec 06 00 00       	call   f0100824 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 4a 19 10 f0       	push   $0xf010194a
f0100152:	e8 3a 08 00 00       	call   f0100991 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 08 08 00 00       	call   f010096b <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f010016a:	e8 22 08 00 00       	call   f0100991 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a c0 19 10 f0 	movzbl -0xfefe640(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 64 19 10 f0       	push   $0xf0101964
f01002c8:	e8 c4 06 00 00       	call   f0100991 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 1b 10 00 00       	call   f0101497 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 70 19 10 f0       	push   $0xf0101970
f010064b:	e8 41 03 00 00       	call   f0100991 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 c0 1b 10 f0       	push   $0xf0101bc0
f0100691:	68 de 1b 10 f0       	push   $0xf0101bde
f0100696:	68 e3 1b 10 f0       	push   $0xf0101be3
f010069b:	e8 f1 02 00 00       	call   f0100991 <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 ac 1c 10 f0       	push   $0xf0101cac
f01006a8:	68 ec 1b 10 f0       	push   $0xf0101bec
f01006ad:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006b2:	e8 da 02 00 00       	call   f0100991 <cprintf>
f01006b7:	83 c4 0c             	add    $0xc,%esp
f01006ba:	68 f5 1b 10 f0       	push   $0xf0101bf5
f01006bf:	68 0c 1c 10 f0       	push   $0xf0101c0c
f01006c4:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006c9:	e8 c3 02 00 00       	call   f0100991 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	68 16 1c 10 f0       	push   $0xf0101c16
f01006e0:	e8 ac 02 00 00       	call   f0100991 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e5:	83 c4 08             	add    $0x8,%esp
f01006e8:	68 0c 00 10 00       	push   $0x10000c
f01006ed:	68 d4 1c 10 f0       	push   $0xf0101cd4
f01006f2:	e8 9a 02 00 00       	call   f0100991 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 0c 00 10 00       	push   $0x10000c
f01006ff:	68 0c 00 10 f0       	push   $0xf010000c
f0100704:	68 fc 1c 10 f0       	push   $0xf0101cfc
f0100709:	e8 83 02 00 00       	call   f0100991 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 d1 18 10 00       	push   $0x1018d1
f0100716:	68 d1 18 10 f0       	push   $0xf01018d1
f010071b:	68 20 1d 10 f0       	push   $0xf0101d20
f0100720:	e8 6c 02 00 00       	call   f0100991 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 00 23 11 00       	push   $0x112300
f010072d:	68 00 23 11 f0       	push   $0xf0112300
f0100732:	68 44 1d 10 f0       	push   $0xf0101d44
f0100737:	e8 55 02 00 00       	call   f0100991 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 44 29 11 00       	push   $0x112944
f0100744:	68 44 29 11 f0       	push   $0xf0112944
f0100749:	68 68 1d 10 f0       	push   $0xf0101d68
f010074e:	e8 3e 02 00 00       	call   f0100991 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100753:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	83 c4 08             	add    $0x8,%esp
f0100760:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100765:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076b:	85 c0                	test   %eax,%eax
f010076d:	0f 48 c2             	cmovs  %edx,%eax
f0100770:	c1 f8 0a             	sar    $0xa,%eax
f0100773:	50                   	push   %eax
f0100774:	68 8c 1d 10 f0       	push   $0xf0101d8c
f0100779:	e8 13 02 00 00       	call   f0100991 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
f0100788:	57                   	push   %edi
f0100789:	56                   	push   %esi
f010078a:	53                   	push   %ebx
f010078b:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010078e:	89 ee                	mov    %ebp,%esi
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
f0100790:	68 2f 1c 10 f0       	push   $0xf0101c2f
f0100795:	e8 f7 01 00 00       	call   f0100991 <cprintf>
    while (ebp) {
f010079a:	83 c4 10             	add    $0x10,%esp
f010079d:	eb 74                	jmp    f0100813 <mon_backtrace+0x8e>
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
f010079f:	83 ec 04             	sub    $0x4,%esp
f01007a2:	ff 76 04             	pushl  0x4(%esi)
f01007a5:	56                   	push   %esi
f01007a6:	68 41 1c 10 f0       	push   $0xf0101c41
f01007ab:	e8 e1 01 00 00       	call   f0100991 <cprintf>
f01007b0:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007b3:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007b6:	83 c4 10             	add    $0x10,%esp
        for (int j = 2; j != 7; ++j) {
            cprintf(" %08x", ebp[j]);  
f01007b9:	83 ec 08             	sub    $0x8,%esp
f01007bc:	ff 33                	pushl  (%ebx)
f01007be:	68 5a 1c 10 f0       	push   $0xf0101c5a
f01007c3:	e8 c9 01 00 00       	call   f0100991 <cprintf>
f01007c8:	83 c3 04             	add    $0x4,%ebx
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
        cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
        for (int j = 2; j != 7; ++j) {
f01007cb:	83 c4 10             	add    $0x10,%esp
f01007ce:	39 fb                	cmp    %edi,%ebx
f01007d0:	75 e7                	jne    f01007b9 <mon_backtrace+0x34>
            cprintf(" %08x", ebp[j]);  
        }
        cprintf("\n");
f01007d2:	83 ec 0c             	sub    $0xc,%esp
f01007d5:	68 6e 19 10 f0       	push   $0xf010196e
f01007da:	e8 b2 01 00 00       	call   f0100991 <cprintf>
        debuginfo_eip(ebp[1],&info);
f01007df:	83 c4 08             	add    $0x8,%esp
f01007e2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007e5:	50                   	push   %eax
f01007e6:	ff 76 04             	pushl  0x4(%esi)
f01007e9:	e8 ad 02 00 00       	call   f0100a9b <debuginfo_eip>
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
f01007ee:	83 c4 08             	add    $0x8,%esp
f01007f1:	8b 46 04             	mov    0x4(%esi),%eax
f01007f4:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007f7:	50                   	push   %eax
f01007f8:	ff 75 d8             	pushl  -0x28(%ebp)
f01007fb:	ff 75 dc             	pushl  -0x24(%ebp)
f01007fe:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100801:	ff 75 d0             	pushl  -0x30(%ebp)
f0100804:	68 60 1c 10 f0       	push   $0xf0101c60
f0100809:	e8 83 01 00 00       	call   f0100991 <cprintf>
        ebp = (uint32_t *) (*ebp);
f010080e:	8b 36                	mov    (%esi),%esi
f0100810:	83 c4 20             	add    $0x20,%esp
{
    // Your code here.
    struct Eipdebuginfo info;
    uint32_t *ebp = (uint32_t *) read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp) {
f0100813:	85 f6                	test   %esi,%esi
f0100815:	75 88                	jne    f010079f <mon_backtrace+0x1a>
        debuginfo_eip(ebp[1],&info);
        cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,ebp[1]-info.eip_fn_addr);
        ebp = (uint32_t *) (*ebp);
    }
       return 0;
}
f0100817:	b8 00 00 00 00       	mov    $0x0,%eax
f010081c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010081f:	5b                   	pop    %ebx
f0100820:	5e                   	pop    %esi
f0100821:	5f                   	pop    %edi
f0100822:	5d                   	pop    %ebp
f0100823:	c3                   	ret    

f0100824 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100824:	55                   	push   %ebp
f0100825:	89 e5                	mov    %esp,%ebp
f0100827:	57                   	push   %edi
f0100828:	56                   	push   %esi
f0100829:	53                   	push   %ebx
f010082a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010082d:	68 b8 1d 10 f0       	push   $0xf0101db8
f0100832:	e8 5a 01 00 00       	call   f0100991 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100837:	c7 04 24 dc 1d 10 f0 	movl   $0xf0101ddc,(%esp)
f010083e:	e8 4e 01 00 00       	call   f0100991 <cprintf>
f0100843:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100846:	83 ec 0c             	sub    $0xc,%esp
f0100849:	68 70 1c 10 f0       	push   $0xf0101c70
f010084e:	e8 a0 09 00 00       	call   f01011f3 <readline>
f0100853:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100855:	83 c4 10             	add    $0x10,%esp
f0100858:	85 c0                	test   %eax,%eax
f010085a:	74 ea                	je     f0100846 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010085c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100863:	be 00 00 00 00       	mov    $0x0,%esi
f0100868:	eb 0a                	jmp    f0100874 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010086a:	c6 03 00             	movb   $0x0,(%ebx)
f010086d:	89 f7                	mov    %esi,%edi
f010086f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100872:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100874:	0f b6 03             	movzbl (%ebx),%eax
f0100877:	84 c0                	test   %al,%al
f0100879:	74 63                	je     f01008de <monitor+0xba>
f010087b:	83 ec 08             	sub    $0x8,%esp
f010087e:	0f be c0             	movsbl %al,%eax
f0100881:	50                   	push   %eax
f0100882:	68 74 1c 10 f0       	push   $0xf0101c74
f0100887:	e8 81 0b 00 00       	call   f010140d <strchr>
f010088c:	83 c4 10             	add    $0x10,%esp
f010088f:	85 c0                	test   %eax,%eax
f0100891:	75 d7                	jne    f010086a <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100893:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100896:	74 46                	je     f01008de <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100898:	83 fe 0f             	cmp    $0xf,%esi
f010089b:	75 14                	jne    f01008b1 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010089d:	83 ec 08             	sub    $0x8,%esp
f01008a0:	6a 10                	push   $0x10
f01008a2:	68 79 1c 10 f0       	push   $0xf0101c79
f01008a7:	e8 e5 00 00 00       	call   f0100991 <cprintf>
f01008ac:	83 c4 10             	add    $0x10,%esp
f01008af:	eb 95                	jmp    f0100846 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008b1:	8d 7e 01             	lea    0x1(%esi),%edi
f01008b4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008b8:	eb 03                	jmp    f01008bd <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008ba:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008bd:	0f b6 03             	movzbl (%ebx),%eax
f01008c0:	84 c0                	test   %al,%al
f01008c2:	74 ae                	je     f0100872 <monitor+0x4e>
f01008c4:	83 ec 08             	sub    $0x8,%esp
f01008c7:	0f be c0             	movsbl %al,%eax
f01008ca:	50                   	push   %eax
f01008cb:	68 74 1c 10 f0       	push   $0xf0101c74
f01008d0:	e8 38 0b 00 00       	call   f010140d <strchr>
f01008d5:	83 c4 10             	add    $0x10,%esp
f01008d8:	85 c0                	test   %eax,%eax
f01008da:	74 de                	je     f01008ba <monitor+0x96>
f01008dc:	eb 94                	jmp    f0100872 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008de:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008e5:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008e6:	85 f6                	test   %esi,%esi
f01008e8:	0f 84 58 ff ff ff    	je     f0100846 <monitor+0x22>
f01008ee:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f3:	83 ec 08             	sub    $0x8,%esp
f01008f6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f9:	ff 34 85 20 1e 10 f0 	pushl  -0xfefe1e0(,%eax,4)
f0100900:	ff 75 a8             	pushl  -0x58(%ebp)
f0100903:	e8 a7 0a 00 00       	call   f01013af <strcmp>
f0100908:	83 c4 10             	add    $0x10,%esp
f010090b:	85 c0                	test   %eax,%eax
f010090d:	75 21                	jne    f0100930 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f010090f:	83 ec 04             	sub    $0x4,%esp
f0100912:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100915:	ff 75 08             	pushl  0x8(%ebp)
f0100918:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010091b:	52                   	push   %edx
f010091c:	56                   	push   %esi
f010091d:	ff 14 85 28 1e 10 f0 	call   *-0xfefe1d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100924:	83 c4 10             	add    $0x10,%esp
f0100927:	85 c0                	test   %eax,%eax
f0100929:	78 25                	js     f0100950 <monitor+0x12c>
f010092b:	e9 16 ff ff ff       	jmp    f0100846 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100930:	83 c3 01             	add    $0x1,%ebx
f0100933:	83 fb 03             	cmp    $0x3,%ebx
f0100936:	75 bb                	jne    f01008f3 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	ff 75 a8             	pushl  -0x58(%ebp)
f010093e:	68 96 1c 10 f0       	push   $0xf0101c96
f0100943:	e8 49 00 00 00       	call   f0100991 <cprintf>
f0100948:	83 c4 10             	add    $0x10,%esp
f010094b:	e9 f6 fe ff ff       	jmp    f0100846 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100950:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100953:	5b                   	pop    %ebx
f0100954:	5e                   	pop    %esi
f0100955:	5f                   	pop    %edi
f0100956:	5d                   	pop    %ebp
f0100957:	c3                   	ret    

f0100958 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100958:	55                   	push   %ebp
f0100959:	89 e5                	mov    %esp,%ebp
f010095b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010095e:	ff 75 08             	pushl  0x8(%ebp)
f0100961:	e8 f5 fc ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f0100966:	83 c4 10             	add    $0x10,%esp
f0100969:	c9                   	leave  
f010096a:	c3                   	ret    

f010096b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010096b:	55                   	push   %ebp
f010096c:	89 e5                	mov    %esp,%ebp
f010096e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100971:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100978:	ff 75 0c             	pushl  0xc(%ebp)
f010097b:	ff 75 08             	pushl  0x8(%ebp)
f010097e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100981:	50                   	push   %eax
f0100982:	68 58 09 10 f0       	push   $0xf0100958
f0100987:	e8 52 04 00 00       	call   f0100dde <vprintfmt>
	return cnt;
}
f010098c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010098f:	c9                   	leave  
f0100990:	c3                   	ret    

f0100991 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100991:	55                   	push   %ebp
f0100992:	89 e5                	mov    %esp,%ebp
f0100994:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100997:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010099a:	50                   	push   %eax
f010099b:	ff 75 08             	pushl  0x8(%ebp)
f010099e:	e8 c8 ff ff ff       	call   f010096b <vcprintf>
	va_end(ap);

	return cnt;
}
f01009a3:	c9                   	leave  
f01009a4:	c3                   	ret    

f01009a5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a5:	55                   	push   %ebp
f01009a6:	89 e5                	mov    %esp,%ebp
f01009a8:	57                   	push   %edi
f01009a9:	56                   	push   %esi
f01009aa:	53                   	push   %ebx
f01009ab:	83 ec 14             	sub    $0x14,%esp
f01009ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009b1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009b4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009b7:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ba:	8b 1a                	mov    (%edx),%ebx
f01009bc:	8b 01                	mov    (%ecx),%eax
f01009be:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009c8:	eb 7f                	jmp    f0100a49 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009cd:	01 d8                	add    %ebx,%eax
f01009cf:	89 c6                	mov    %eax,%esi
f01009d1:	c1 ee 1f             	shr    $0x1f,%esi
f01009d4:	01 c6                	add    %eax,%esi
f01009d6:	d1 fe                	sar    %esi
f01009d8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009db:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009de:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009e1:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e3:	eb 03                	jmp    f01009e8 <stab_binsearch+0x43>
			m--;
f01009e5:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e8:	39 c3                	cmp    %eax,%ebx
f01009ea:	7f 0d                	jg     f01009f9 <stab_binsearch+0x54>
f01009ec:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009f0:	83 ea 0c             	sub    $0xc,%edx
f01009f3:	39 f9                	cmp    %edi,%ecx
f01009f5:	75 ee                	jne    f01009e5 <stab_binsearch+0x40>
f01009f7:	eb 05                	jmp    f01009fe <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009f9:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009fc:	eb 4b                	jmp    f0100a49 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009fe:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a01:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a04:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a08:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a0b:	76 11                	jbe    f0100a1e <stab_binsearch+0x79>
			*region_left = m;
f0100a0d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a10:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a12:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a15:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a1c:	eb 2b                	jmp    f0100a49 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a1e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a21:	73 14                	jae    f0100a37 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a23:	83 e8 01             	sub    $0x1,%eax
f0100a26:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a29:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a2c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a2e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a35:	eb 12                	jmp    f0100a49 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a37:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a3a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a3c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a40:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a42:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a49:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a4c:	0f 8e 78 ff ff ff    	jle    f01009ca <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a52:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a56:	75 0f                	jne    f0100a67 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a5b:	8b 00                	mov    (%eax),%eax
f0100a5d:	83 e8 01             	sub    $0x1,%eax
f0100a60:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a63:	89 06                	mov    %eax,(%esi)
f0100a65:	eb 2c                	jmp    f0100a93 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a67:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a6a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a6c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a6f:	8b 0e                	mov    (%esi),%ecx
f0100a71:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a74:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a77:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7a:	eb 03                	jmp    f0100a7f <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a7c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7f:	39 c8                	cmp    %ecx,%eax
f0100a81:	7e 0b                	jle    f0100a8e <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a83:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a87:	83 ea 0c             	sub    $0xc,%edx
f0100a8a:	39 df                	cmp    %ebx,%edi
f0100a8c:	75 ee                	jne    f0100a7c <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a8e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a91:	89 06                	mov    %eax,(%esi)
	}
}
f0100a93:	83 c4 14             	add    $0x14,%esp
f0100a96:	5b                   	pop    %ebx
f0100a97:	5e                   	pop    %esi
f0100a98:	5f                   	pop    %edi
f0100a99:	5d                   	pop    %ebp
f0100a9a:	c3                   	ret    

f0100a9b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a9b:	55                   	push   %ebp
f0100a9c:	89 e5                	mov    %esp,%ebp
f0100a9e:	57                   	push   %edi
f0100a9f:	56                   	push   %esi
f0100aa0:	53                   	push   %ebx
f0100aa1:	83 ec 3c             	sub    $0x3c,%esp
f0100aa4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aa7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aaa:	c7 03 44 1e 10 f0    	movl   $0xf0101e44,(%ebx)
	info->eip_line = 0;
f0100ab0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ab7:	c7 43 08 44 1e 10 f0 	movl   $0xf0101e44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100abe:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ac5:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ac8:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100acf:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ad5:	76 11                	jbe    f0100ae8 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ad7:	b8 1f 73 10 f0       	mov    $0xf010731f,%eax
f0100adc:	3d 01 5a 10 f0       	cmp    $0xf0105a01,%eax
f0100ae1:	77 19                	ja     f0100afc <debuginfo_eip+0x61>
f0100ae3:	e9 aa 01 00 00       	jmp    f0100c92 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ae8:	83 ec 04             	sub    $0x4,%esp
f0100aeb:	68 4e 1e 10 f0       	push   $0xf0101e4e
f0100af0:	6a 7f                	push   $0x7f
f0100af2:	68 5b 1e 10 f0       	push   $0xf0101e5b
f0100af7:	e8 ea f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afc:	80 3d 1e 73 10 f0 00 	cmpb   $0x0,0xf010731e
f0100b03:	0f 85 90 01 00 00    	jne    f0100c99 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b09:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b10:	b8 00 5a 10 f0       	mov    $0xf0105a00,%eax
f0100b15:	2d 7c 20 10 f0       	sub    $0xf010207c,%eax
f0100b1a:	c1 f8 02             	sar    $0x2,%eax
f0100b1d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b23:	83 e8 01             	sub    $0x1,%eax
f0100b26:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b29:	83 ec 08             	sub    $0x8,%esp
f0100b2c:	56                   	push   %esi
f0100b2d:	6a 64                	push   $0x64
f0100b2f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b32:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b35:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100b3a:	e8 66 fe ff ff       	call   f01009a5 <stab_binsearch>
	if (lfile == 0)
f0100b3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b42:	83 c4 10             	add    $0x10,%esp
f0100b45:	85 c0                	test   %eax,%eax
f0100b47:	0f 84 53 01 00 00    	je     f0100ca0 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b4d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b53:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b56:	83 ec 08             	sub    $0x8,%esp
f0100b59:	56                   	push   %esi
f0100b5a:	6a 24                	push   $0x24
f0100b5c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b5f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b62:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100b67:	e8 39 fe ff ff       	call   f01009a5 <stab_binsearch>

	if (lfun <= rfun) {
f0100b6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b6f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b72:	83 c4 10             	add    $0x10,%esp
f0100b75:	39 d0                	cmp    %edx,%eax
f0100b77:	7f 40                	jg     f0100bb9 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b79:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b7c:	c1 e1 02             	shl    $0x2,%ecx
f0100b7f:	8d b9 7c 20 10 f0    	lea    -0xfefdf84(%ecx),%edi
f0100b85:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b88:	8b b9 7c 20 10 f0    	mov    -0xfefdf84(%ecx),%edi
f0100b8e:	b9 1f 73 10 f0       	mov    $0xf010731f,%ecx
f0100b93:	81 e9 01 5a 10 f0    	sub    $0xf0105a01,%ecx
f0100b99:	39 cf                	cmp    %ecx,%edi
f0100b9b:	73 09                	jae    f0100ba6 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b9d:	81 c7 01 5a 10 f0    	add    $0xf0105a01,%edi
f0100ba3:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ba6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ba9:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bac:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100baf:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bb1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bb4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bb7:	eb 0f                	jmp    f0100bc8 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bbf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bc8:	83 ec 08             	sub    $0x8,%esp
f0100bcb:	6a 3a                	push   $0x3a
f0100bcd:	ff 73 08             	pushl  0x8(%ebx)
f0100bd0:	e8 59 08 00 00       	call   f010142e <strfind>
f0100bd5:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bd8:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bdb:	83 c4 08             	add    $0x8,%esp
f0100bde:	56                   	push   %esi
f0100bdf:	6a 44                	push   $0x44
f0100be1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100be4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100be7:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100bec:	e8 b4 fd ff ff       	call   f01009a5 <stab_binsearch>
	  if (lline <= rline) {
f0100bf1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100bf4:	83 c4 10             	add    $0x10,%esp
f0100bf7:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100bfa:	0f 8f a7 00 00 00    	jg     f0100ca7 <debuginfo_eip+0x20c>
	      info->eip_line = stabs[lline].n_desc;
f0100c00:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c03:	8d 04 85 7c 20 10 f0 	lea    -0xfefdf84(,%eax,4),%eax
f0100c0a:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100c0e:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c11:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c14:	eb 06                	jmp    f0100c1c <debuginfo_eip+0x181>
f0100c16:	83 ea 01             	sub    $0x1,%edx
f0100c19:	83 e8 0c             	sub    $0xc,%eax
f0100c1c:	39 d6                	cmp    %edx,%esi
f0100c1e:	7f 34                	jg     f0100c54 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0100c20:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c24:	80 f9 84             	cmp    $0x84,%cl
f0100c27:	74 0b                	je     f0100c34 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c29:	80 f9 64             	cmp    $0x64,%cl
f0100c2c:	75 e8                	jne    f0100c16 <debuginfo_eip+0x17b>
f0100c2e:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c32:	74 e2                	je     f0100c16 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c34:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c37:	8b 14 85 7c 20 10 f0 	mov    -0xfefdf84(,%eax,4),%edx
f0100c3e:	b8 1f 73 10 f0       	mov    $0xf010731f,%eax
f0100c43:	2d 01 5a 10 f0       	sub    $0xf0105a01,%eax
f0100c48:	39 c2                	cmp    %eax,%edx
f0100c4a:	73 08                	jae    f0100c54 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c4c:	81 c2 01 5a 10 f0    	add    $0xf0105a01,%edx
f0100c52:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c54:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c57:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c5a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c5f:	39 f2                	cmp    %esi,%edx
f0100c61:	7d 50                	jge    f0100cb3 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0100c63:	83 c2 01             	add    $0x1,%edx
f0100c66:	89 d0                	mov    %edx,%eax
f0100c68:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c6b:	8d 14 95 7c 20 10 f0 	lea    -0xfefdf84(,%edx,4),%edx
f0100c72:	eb 04                	jmp    f0100c78 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c74:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c78:	39 c6                	cmp    %eax,%esi
f0100c7a:	7e 32                	jle    f0100cae <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c7c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c80:	83 c0 01             	add    $0x1,%eax
f0100c83:	83 c2 0c             	add    $0xc,%edx
f0100c86:	80 f9 a0             	cmp    $0xa0,%cl
f0100c89:	74 e9                	je     f0100c74 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c90:	eb 21                	jmp    f0100cb3 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c97:	eb 1a                	jmp    f0100cb3 <debuginfo_eip+0x218>
f0100c99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c9e:	eb 13                	jmp    f0100cb3 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca5:	eb 0c                	jmp    f0100cb3 <debuginfo_eip+0x218>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	  if (lline <= rline) {
	      info->eip_line = stabs[lline].n_desc;
	  } else {
	      return -1;
f0100ca7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cac:	eb 05                	jmp    f0100cb3 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cae:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb6:	5b                   	pop    %ebx
f0100cb7:	5e                   	pop    %esi
f0100cb8:	5f                   	pop    %edi
f0100cb9:	5d                   	pop    %ebp
f0100cba:	c3                   	ret    

f0100cbb <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cbb:	55                   	push   %ebp
f0100cbc:	89 e5                	mov    %esp,%ebp
f0100cbe:	57                   	push   %edi
f0100cbf:	56                   	push   %esi
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 1c             	sub    $0x1c,%esp
f0100cc4:	89 c7                	mov    %eax,%edi
f0100cc6:	89 d6                	mov    %edx,%esi
f0100cc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ccb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cce:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cd1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cd7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cdc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100cdf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ce2:	39 d3                	cmp    %edx,%ebx
f0100ce4:	72 05                	jb     f0100ceb <printnum+0x30>
f0100ce6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ce9:	77 45                	ja     f0100d30 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ceb:	83 ec 0c             	sub    $0xc,%esp
f0100cee:	ff 75 18             	pushl  0x18(%ebp)
f0100cf1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cf4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cf7:	53                   	push   %ebx
f0100cf8:	ff 75 10             	pushl  0x10(%ebp)
f0100cfb:	83 ec 08             	sub    $0x8,%esp
f0100cfe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d01:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d04:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d07:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0a:	e8 41 09 00 00       	call   f0101650 <__udivdi3>
f0100d0f:	83 c4 18             	add    $0x18,%esp
f0100d12:	52                   	push   %edx
f0100d13:	50                   	push   %eax
f0100d14:	89 f2                	mov    %esi,%edx
f0100d16:	89 f8                	mov    %edi,%eax
f0100d18:	e8 9e ff ff ff       	call   f0100cbb <printnum>
f0100d1d:	83 c4 20             	add    $0x20,%esp
f0100d20:	eb 18                	jmp    f0100d3a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d22:	83 ec 08             	sub    $0x8,%esp
f0100d25:	56                   	push   %esi
f0100d26:	ff 75 18             	pushl  0x18(%ebp)
f0100d29:	ff d7                	call   *%edi
f0100d2b:	83 c4 10             	add    $0x10,%esp
f0100d2e:	eb 03                	jmp    f0100d33 <printnum+0x78>
f0100d30:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d33:	83 eb 01             	sub    $0x1,%ebx
f0100d36:	85 db                	test   %ebx,%ebx
f0100d38:	7f e8                	jg     f0100d22 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d3a:	83 ec 08             	sub    $0x8,%esp
f0100d3d:	56                   	push   %esi
f0100d3e:	83 ec 04             	sub    $0x4,%esp
f0100d41:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d44:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d47:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d4a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d4d:	e8 2e 0a 00 00       	call   f0101780 <__umoddi3>
f0100d52:	83 c4 14             	add    $0x14,%esp
f0100d55:	0f be 80 69 1e 10 f0 	movsbl -0xfefe197(%eax),%eax
f0100d5c:	50                   	push   %eax
f0100d5d:	ff d7                	call   *%edi
}
f0100d5f:	83 c4 10             	add    $0x10,%esp
f0100d62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d65:	5b                   	pop    %ebx
f0100d66:	5e                   	pop    %esi
f0100d67:	5f                   	pop    %edi
f0100d68:	5d                   	pop    %ebp
f0100d69:	c3                   	ret    

f0100d6a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d6a:	55                   	push   %ebp
f0100d6b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d6d:	83 fa 01             	cmp    $0x1,%edx
f0100d70:	7e 0e                	jle    f0100d80 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d72:	8b 10                	mov    (%eax),%edx
f0100d74:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d77:	89 08                	mov    %ecx,(%eax)
f0100d79:	8b 02                	mov    (%edx),%eax
f0100d7b:	8b 52 04             	mov    0x4(%edx),%edx
f0100d7e:	eb 22                	jmp    f0100da2 <getuint+0x38>
	else if (lflag)
f0100d80:	85 d2                	test   %edx,%edx
f0100d82:	74 10                	je     f0100d94 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d84:	8b 10                	mov    (%eax),%edx
f0100d86:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d89:	89 08                	mov    %ecx,(%eax)
f0100d8b:	8b 02                	mov    (%edx),%eax
f0100d8d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d92:	eb 0e                	jmp    f0100da2 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d94:	8b 10                	mov    (%eax),%edx
f0100d96:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d99:	89 08                	mov    %ecx,(%eax)
f0100d9b:	8b 02                	mov    (%edx),%eax
f0100d9d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da2:	5d                   	pop    %ebp
f0100da3:	c3                   	ret    

f0100da4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da4:	55                   	push   %ebp
f0100da5:	89 e5                	mov    %esp,%ebp
f0100da7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100daa:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100dae:	8b 10                	mov    (%eax),%edx
f0100db0:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db3:	73 0a                	jae    f0100dbf <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db5:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100db8:	89 08                	mov    %ecx,(%eax)
f0100dba:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dbd:	88 02                	mov    %al,(%edx)
}
f0100dbf:	5d                   	pop    %ebp
f0100dc0:	c3                   	ret    

f0100dc1 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc1:	55                   	push   %ebp
f0100dc2:	89 e5                	mov    %esp,%ebp
f0100dc4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dca:	50                   	push   %eax
f0100dcb:	ff 75 10             	pushl  0x10(%ebp)
f0100dce:	ff 75 0c             	pushl  0xc(%ebp)
f0100dd1:	ff 75 08             	pushl  0x8(%ebp)
f0100dd4:	e8 05 00 00 00       	call   f0100dde <vprintfmt>
	va_end(ap);
}
f0100dd9:	83 c4 10             	add    $0x10,%esp
f0100ddc:	c9                   	leave  
f0100ddd:	c3                   	ret    

f0100dde <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dde:	55                   	push   %ebp
f0100ddf:	89 e5                	mov    %esp,%ebp
f0100de1:	57                   	push   %edi
f0100de2:	56                   	push   %esi
f0100de3:	53                   	push   %ebx
f0100de4:	83 ec 2c             	sub    $0x2c,%esp
f0100de7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ded:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df0:	eb 12                	jmp    f0100e04 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100df2:	85 c0                	test   %eax,%eax
f0100df4:	0f 84 89 03 00 00    	je     f0101183 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100dfa:	83 ec 08             	sub    $0x8,%esp
f0100dfd:	53                   	push   %ebx
f0100dfe:	50                   	push   %eax
f0100dff:	ff d6                	call   *%esi
f0100e01:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e04:	83 c7 01             	add    $0x1,%edi
f0100e07:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e0b:	83 f8 25             	cmp    $0x25,%eax
f0100e0e:	75 e2                	jne    f0100df2 <vprintfmt+0x14>
f0100e10:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e14:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e1b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e22:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e29:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2e:	eb 07                	jmp    f0100e37 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e30:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e33:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e37:	8d 47 01             	lea    0x1(%edi),%eax
f0100e3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e3d:	0f b6 07             	movzbl (%edi),%eax
f0100e40:	0f b6 c8             	movzbl %al,%ecx
f0100e43:	83 e8 23             	sub    $0x23,%eax
f0100e46:	3c 55                	cmp    $0x55,%al
f0100e48:	0f 87 1a 03 00 00    	ja     f0101168 <vprintfmt+0x38a>
f0100e4e:	0f b6 c0             	movzbl %al,%eax
f0100e51:	ff 24 85 f8 1e 10 f0 	jmp    *-0xfefe108(,%eax,4)
f0100e58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e5b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e5f:	eb d6                	jmp    f0100e37 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e64:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e6c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e6f:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e73:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e76:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e79:	83 fa 09             	cmp    $0x9,%edx
f0100e7c:	77 39                	ja     f0100eb7 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e7e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e81:	eb e9                	jmp    f0100e6c <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e83:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e86:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e89:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e8c:	8b 00                	mov    (%eax),%eax
f0100e8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e94:	eb 27                	jmp    f0100ebd <vprintfmt+0xdf>
f0100e96:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e99:	85 c0                	test   %eax,%eax
f0100e9b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ea0:	0f 49 c8             	cmovns %eax,%ecx
f0100ea3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ea9:	eb 8c                	jmp    f0100e37 <vprintfmt+0x59>
f0100eab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eae:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eb5:	eb 80                	jmp    f0100e37 <vprintfmt+0x59>
f0100eb7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100eba:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ebd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ec1:	0f 89 70 ff ff ff    	jns    f0100e37 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100ec7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100eca:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ed4:	e9 5e ff ff ff       	jmp    f0100e37 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ed9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100edf:	e9 53 ff ff ff       	jmp    f0100e37 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ee4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee7:	8d 50 04             	lea    0x4(%eax),%edx
f0100eea:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eed:	83 ec 08             	sub    $0x8,%esp
f0100ef0:	53                   	push   %ebx
f0100ef1:	ff 30                	pushl  (%eax)
f0100ef3:	ff d6                	call   *%esi
			break;
f0100ef5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100efb:	e9 04 ff ff ff       	jmp    f0100e04 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f03:	8d 50 04             	lea    0x4(%eax),%edx
f0100f06:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f09:	8b 00                	mov    (%eax),%eax
f0100f0b:	99                   	cltd   
f0100f0c:	31 d0                	xor    %edx,%eax
f0100f0e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f10:	83 f8 06             	cmp    $0x6,%eax
f0100f13:	7f 0b                	jg     f0100f20 <vprintfmt+0x142>
f0100f15:	8b 14 85 50 20 10 f0 	mov    -0xfefdfb0(,%eax,4),%edx
f0100f1c:	85 d2                	test   %edx,%edx
f0100f1e:	75 18                	jne    f0100f38 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f20:	50                   	push   %eax
f0100f21:	68 81 1e 10 f0       	push   $0xf0101e81
f0100f26:	53                   	push   %ebx
f0100f27:	56                   	push   %esi
f0100f28:	e8 94 fe ff ff       	call   f0100dc1 <printfmt>
f0100f2d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f33:	e9 cc fe ff ff       	jmp    f0100e04 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f38:	52                   	push   %edx
f0100f39:	68 8a 1e 10 f0       	push   $0xf0101e8a
f0100f3e:	53                   	push   %ebx
f0100f3f:	56                   	push   %esi
f0100f40:	e8 7c fe ff ff       	call   f0100dc1 <printfmt>
f0100f45:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4b:	e9 b4 fe ff ff       	jmp    f0100e04 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f50:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f53:	8d 50 04             	lea    0x4(%eax),%edx
f0100f56:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f59:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f5b:	85 ff                	test   %edi,%edi
f0100f5d:	b8 7a 1e 10 f0       	mov    $0xf0101e7a,%eax
f0100f62:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f65:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f69:	0f 8e 94 00 00 00    	jle    f0101003 <vprintfmt+0x225>
f0100f6f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f73:	0f 84 98 00 00 00    	je     f0101011 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f79:	83 ec 08             	sub    $0x8,%esp
f0100f7c:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f7f:	57                   	push   %edi
f0100f80:	e8 5f 03 00 00       	call   f01012e4 <strnlen>
f0100f85:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f88:	29 c1                	sub    %eax,%ecx
f0100f8a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f8d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f90:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f94:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f97:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f9a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f9c:	eb 0f                	jmp    f0100fad <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f9e:	83 ec 08             	sub    $0x8,%esp
f0100fa1:	53                   	push   %ebx
f0100fa2:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa7:	83 ef 01             	sub    $0x1,%edi
f0100faa:	83 c4 10             	add    $0x10,%esp
f0100fad:	85 ff                	test   %edi,%edi
f0100faf:	7f ed                	jg     f0100f9e <vprintfmt+0x1c0>
f0100fb1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fb4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fb7:	85 c9                	test   %ecx,%ecx
f0100fb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbe:	0f 49 c1             	cmovns %ecx,%eax
f0100fc1:	29 c1                	sub    %eax,%ecx
f0100fc3:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fc9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fcc:	89 cb                	mov    %ecx,%ebx
f0100fce:	eb 4d                	jmp    f010101d <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fd4:	74 1b                	je     f0100ff1 <vprintfmt+0x213>
f0100fd6:	0f be c0             	movsbl %al,%eax
f0100fd9:	83 e8 20             	sub    $0x20,%eax
f0100fdc:	83 f8 5e             	cmp    $0x5e,%eax
f0100fdf:	76 10                	jbe    f0100ff1 <vprintfmt+0x213>
					putch('?', putdat);
f0100fe1:	83 ec 08             	sub    $0x8,%esp
f0100fe4:	ff 75 0c             	pushl  0xc(%ebp)
f0100fe7:	6a 3f                	push   $0x3f
f0100fe9:	ff 55 08             	call   *0x8(%ebp)
f0100fec:	83 c4 10             	add    $0x10,%esp
f0100fef:	eb 0d                	jmp    f0100ffe <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100ff1:	83 ec 08             	sub    $0x8,%esp
f0100ff4:	ff 75 0c             	pushl  0xc(%ebp)
f0100ff7:	52                   	push   %edx
f0100ff8:	ff 55 08             	call   *0x8(%ebp)
f0100ffb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ffe:	83 eb 01             	sub    $0x1,%ebx
f0101001:	eb 1a                	jmp    f010101d <vprintfmt+0x23f>
f0101003:	89 75 08             	mov    %esi,0x8(%ebp)
f0101006:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101009:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010100c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010100f:	eb 0c                	jmp    f010101d <vprintfmt+0x23f>
f0101011:	89 75 08             	mov    %esi,0x8(%ebp)
f0101014:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101017:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010101a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010101d:	83 c7 01             	add    $0x1,%edi
f0101020:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101024:	0f be d0             	movsbl %al,%edx
f0101027:	85 d2                	test   %edx,%edx
f0101029:	74 23                	je     f010104e <vprintfmt+0x270>
f010102b:	85 f6                	test   %esi,%esi
f010102d:	78 a1                	js     f0100fd0 <vprintfmt+0x1f2>
f010102f:	83 ee 01             	sub    $0x1,%esi
f0101032:	79 9c                	jns    f0100fd0 <vprintfmt+0x1f2>
f0101034:	89 df                	mov    %ebx,%edi
f0101036:	8b 75 08             	mov    0x8(%ebp),%esi
f0101039:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010103c:	eb 18                	jmp    f0101056 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010103e:	83 ec 08             	sub    $0x8,%esp
f0101041:	53                   	push   %ebx
f0101042:	6a 20                	push   $0x20
f0101044:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101046:	83 ef 01             	sub    $0x1,%edi
f0101049:	83 c4 10             	add    $0x10,%esp
f010104c:	eb 08                	jmp    f0101056 <vprintfmt+0x278>
f010104e:	89 df                	mov    %ebx,%edi
f0101050:	8b 75 08             	mov    0x8(%ebp),%esi
f0101053:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101056:	85 ff                	test   %edi,%edi
f0101058:	7f e4                	jg     f010103e <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010105d:	e9 a2 fd ff ff       	jmp    f0100e04 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101062:	83 fa 01             	cmp    $0x1,%edx
f0101065:	7e 16                	jle    f010107d <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101067:	8b 45 14             	mov    0x14(%ebp),%eax
f010106a:	8d 50 08             	lea    0x8(%eax),%edx
f010106d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101070:	8b 50 04             	mov    0x4(%eax),%edx
f0101073:	8b 00                	mov    (%eax),%eax
f0101075:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101078:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010107b:	eb 32                	jmp    f01010af <vprintfmt+0x2d1>
	else if (lflag)
f010107d:	85 d2                	test   %edx,%edx
f010107f:	74 18                	je     f0101099 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101081:	8b 45 14             	mov    0x14(%ebp),%eax
f0101084:	8d 50 04             	lea    0x4(%eax),%edx
f0101087:	89 55 14             	mov    %edx,0x14(%ebp)
f010108a:	8b 00                	mov    (%eax),%eax
f010108c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010108f:	89 c1                	mov    %eax,%ecx
f0101091:	c1 f9 1f             	sar    $0x1f,%ecx
f0101094:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101097:	eb 16                	jmp    f01010af <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101099:	8b 45 14             	mov    0x14(%ebp),%eax
f010109c:	8d 50 04             	lea    0x4(%eax),%edx
f010109f:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a2:	8b 00                	mov    (%eax),%eax
f01010a4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010a7:	89 c1                	mov    %eax,%ecx
f01010a9:	c1 f9 1f             	sar    $0x1f,%ecx
f01010ac:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010af:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010b2:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010b5:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010ba:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010be:	79 74                	jns    f0101134 <vprintfmt+0x356>
				putch('-', putdat);
f01010c0:	83 ec 08             	sub    $0x8,%esp
f01010c3:	53                   	push   %ebx
f01010c4:	6a 2d                	push   $0x2d
f01010c6:	ff d6                	call   *%esi
				num = -(long long) num;
f01010c8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010cb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010ce:	f7 d8                	neg    %eax
f01010d0:	83 d2 00             	adc    $0x0,%edx
f01010d3:	f7 da                	neg    %edx
f01010d5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010d8:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010dd:	eb 55                	jmp    f0101134 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010df:	8d 45 14             	lea    0x14(%ebp),%eax
f01010e2:	e8 83 fc ff ff       	call   f0100d6a <getuint>
			base = 10;
f01010e7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010ec:	eb 46                	jmp    f0101134 <vprintfmt+0x356>

		// (unsigned) octal
	        case 'o':
			num = getuint(&ap, lflag);
f01010ee:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f1:	e8 74 fc ff ff       	call   f0100d6a <getuint>
			base = 8;
f01010f6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010fb:	eb 37                	jmp    f0101134 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01010fd:	83 ec 08             	sub    $0x8,%esp
f0101100:	53                   	push   %ebx
f0101101:	6a 30                	push   $0x30
f0101103:	ff d6                	call   *%esi
			putch('x', putdat);
f0101105:	83 c4 08             	add    $0x8,%esp
f0101108:	53                   	push   %ebx
f0101109:	6a 78                	push   $0x78
f010110b:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010110d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101110:	8d 50 04             	lea    0x4(%eax),%edx
f0101113:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101116:	8b 00                	mov    (%eax),%eax
f0101118:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010111d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101120:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101125:	eb 0d                	jmp    f0101134 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101127:	8d 45 14             	lea    0x14(%ebp),%eax
f010112a:	e8 3b fc ff ff       	call   f0100d6a <getuint>
			base = 16;
f010112f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101134:	83 ec 0c             	sub    $0xc,%esp
f0101137:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010113b:	57                   	push   %edi
f010113c:	ff 75 e0             	pushl  -0x20(%ebp)
f010113f:	51                   	push   %ecx
f0101140:	52                   	push   %edx
f0101141:	50                   	push   %eax
f0101142:	89 da                	mov    %ebx,%edx
f0101144:	89 f0                	mov    %esi,%eax
f0101146:	e8 70 fb ff ff       	call   f0100cbb <printnum>
			break;
f010114b:	83 c4 20             	add    $0x20,%esp
f010114e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101151:	e9 ae fc ff ff       	jmp    f0100e04 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101156:	83 ec 08             	sub    $0x8,%esp
f0101159:	53                   	push   %ebx
f010115a:	51                   	push   %ecx
f010115b:	ff d6                	call   *%esi
			break;
f010115d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101160:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101163:	e9 9c fc ff ff       	jmp    f0100e04 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101168:	83 ec 08             	sub    $0x8,%esp
f010116b:	53                   	push   %ebx
f010116c:	6a 25                	push   $0x25
f010116e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101170:	83 c4 10             	add    $0x10,%esp
f0101173:	eb 03                	jmp    f0101178 <vprintfmt+0x39a>
f0101175:	83 ef 01             	sub    $0x1,%edi
f0101178:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010117c:	75 f7                	jne    f0101175 <vprintfmt+0x397>
f010117e:	e9 81 fc ff ff       	jmp    f0100e04 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101183:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101186:	5b                   	pop    %ebx
f0101187:	5e                   	pop    %esi
f0101188:	5f                   	pop    %edi
f0101189:	5d                   	pop    %ebp
f010118a:	c3                   	ret    

f010118b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010118b:	55                   	push   %ebp
f010118c:	89 e5                	mov    %esp,%ebp
f010118e:	83 ec 18             	sub    $0x18,%esp
f0101191:	8b 45 08             	mov    0x8(%ebp),%eax
f0101194:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101197:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010119a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010119e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011a8:	85 c0                	test   %eax,%eax
f01011aa:	74 26                	je     f01011d2 <vsnprintf+0x47>
f01011ac:	85 d2                	test   %edx,%edx
f01011ae:	7e 22                	jle    f01011d2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011b0:	ff 75 14             	pushl  0x14(%ebp)
f01011b3:	ff 75 10             	pushl  0x10(%ebp)
f01011b6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011b9:	50                   	push   %eax
f01011ba:	68 a4 0d 10 f0       	push   $0xf0100da4
f01011bf:	e8 1a fc ff ff       	call   f0100dde <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011c7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011cd:	83 c4 10             	add    $0x10,%esp
f01011d0:	eb 05                	jmp    f01011d7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011d7:	c9                   	leave  
f01011d8:	c3                   	ret    

f01011d9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011d9:	55                   	push   %ebp
f01011da:	89 e5                	mov    %esp,%ebp
f01011dc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011df:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011e2:	50                   	push   %eax
f01011e3:	ff 75 10             	pushl  0x10(%ebp)
f01011e6:	ff 75 0c             	pushl  0xc(%ebp)
f01011e9:	ff 75 08             	pushl  0x8(%ebp)
f01011ec:	e8 9a ff ff ff       	call   f010118b <vsnprintf>
	va_end(ap);

	return rc;
}
f01011f1:	c9                   	leave  
f01011f2:	c3                   	ret    

f01011f3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011f3:	55                   	push   %ebp
f01011f4:	89 e5                	mov    %esp,%ebp
f01011f6:	57                   	push   %edi
f01011f7:	56                   	push   %esi
f01011f8:	53                   	push   %ebx
f01011f9:	83 ec 0c             	sub    $0xc,%esp
f01011fc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011ff:	85 c0                	test   %eax,%eax
f0101201:	74 11                	je     f0101214 <readline+0x21>
		cprintf("%s", prompt);
f0101203:	83 ec 08             	sub    $0x8,%esp
f0101206:	50                   	push   %eax
f0101207:	68 8a 1e 10 f0       	push   $0xf0101e8a
f010120c:	e8 80 f7 ff ff       	call   f0100991 <cprintf>
f0101211:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101214:	83 ec 0c             	sub    $0xc,%esp
f0101217:	6a 00                	push   $0x0
f0101219:	e8 5e f4 ff ff       	call   f010067c <iscons>
f010121e:	89 c7                	mov    %eax,%edi
f0101220:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101223:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101228:	e8 3e f4 ff ff       	call   f010066b <getchar>
f010122d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010122f:	85 c0                	test   %eax,%eax
f0101231:	79 18                	jns    f010124b <readline+0x58>
			cprintf("read error: %e\n", c);
f0101233:	83 ec 08             	sub    $0x8,%esp
f0101236:	50                   	push   %eax
f0101237:	68 6c 20 10 f0       	push   $0xf010206c
f010123c:	e8 50 f7 ff ff       	call   f0100991 <cprintf>
			return NULL;
f0101241:	83 c4 10             	add    $0x10,%esp
f0101244:	b8 00 00 00 00       	mov    $0x0,%eax
f0101249:	eb 79                	jmp    f01012c4 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010124b:	83 f8 08             	cmp    $0x8,%eax
f010124e:	0f 94 c2             	sete   %dl
f0101251:	83 f8 7f             	cmp    $0x7f,%eax
f0101254:	0f 94 c0             	sete   %al
f0101257:	08 c2                	or     %al,%dl
f0101259:	74 1a                	je     f0101275 <readline+0x82>
f010125b:	85 f6                	test   %esi,%esi
f010125d:	7e 16                	jle    f0101275 <readline+0x82>
			if (echoing)
f010125f:	85 ff                	test   %edi,%edi
f0101261:	74 0d                	je     f0101270 <readline+0x7d>
				cputchar('\b');
f0101263:	83 ec 0c             	sub    $0xc,%esp
f0101266:	6a 08                	push   $0x8
f0101268:	e8 ee f3 ff ff       	call   f010065b <cputchar>
f010126d:	83 c4 10             	add    $0x10,%esp
			i--;
f0101270:	83 ee 01             	sub    $0x1,%esi
f0101273:	eb b3                	jmp    f0101228 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101275:	83 fb 1f             	cmp    $0x1f,%ebx
f0101278:	7e 23                	jle    f010129d <readline+0xaa>
f010127a:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101280:	7f 1b                	jg     f010129d <readline+0xaa>
			if (echoing)
f0101282:	85 ff                	test   %edi,%edi
f0101284:	74 0c                	je     f0101292 <readline+0x9f>
				cputchar(c);
f0101286:	83 ec 0c             	sub    $0xc,%esp
f0101289:	53                   	push   %ebx
f010128a:	e8 cc f3 ff ff       	call   f010065b <cputchar>
f010128f:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101292:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101298:	8d 76 01             	lea    0x1(%esi),%esi
f010129b:	eb 8b                	jmp    f0101228 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010129d:	83 fb 0a             	cmp    $0xa,%ebx
f01012a0:	74 05                	je     f01012a7 <readline+0xb4>
f01012a2:	83 fb 0d             	cmp    $0xd,%ebx
f01012a5:	75 81                	jne    f0101228 <readline+0x35>
			if (echoing)
f01012a7:	85 ff                	test   %edi,%edi
f01012a9:	74 0d                	je     f01012b8 <readline+0xc5>
				cputchar('\n');
f01012ab:	83 ec 0c             	sub    $0xc,%esp
f01012ae:	6a 0a                	push   $0xa
f01012b0:	e8 a6 f3 ff ff       	call   f010065b <cputchar>
f01012b5:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012b8:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012bf:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012c7:	5b                   	pop    %ebx
f01012c8:	5e                   	pop    %esi
f01012c9:	5f                   	pop    %edi
f01012ca:	5d                   	pop    %ebp
f01012cb:	c3                   	ret    

f01012cc <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012cc:	55                   	push   %ebp
f01012cd:	89 e5                	mov    %esp,%ebp
f01012cf:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d7:	eb 03                	jmp    f01012dc <strlen+0x10>
		n++;
f01012d9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012dc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012e0:	75 f7                	jne    f01012d9 <strlen+0xd>
		n++;
	return n;
}
f01012e2:	5d                   	pop    %ebp
f01012e3:	c3                   	ret    

f01012e4 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012e4:	55                   	push   %ebp
f01012e5:	89 e5                	mov    %esp,%ebp
f01012e7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012ea:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01012f2:	eb 03                	jmp    f01012f7 <strnlen+0x13>
		n++;
f01012f4:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012f7:	39 c2                	cmp    %eax,%edx
f01012f9:	74 08                	je     f0101303 <strnlen+0x1f>
f01012fb:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012ff:	75 f3                	jne    f01012f4 <strnlen+0x10>
f0101301:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101303:	5d                   	pop    %ebp
f0101304:	c3                   	ret    

f0101305 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101305:	55                   	push   %ebp
f0101306:	89 e5                	mov    %esp,%ebp
f0101308:	53                   	push   %ebx
f0101309:	8b 45 08             	mov    0x8(%ebp),%eax
f010130c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010130f:	89 c2                	mov    %eax,%edx
f0101311:	83 c2 01             	add    $0x1,%edx
f0101314:	83 c1 01             	add    $0x1,%ecx
f0101317:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010131b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010131e:	84 db                	test   %bl,%bl
f0101320:	75 ef                	jne    f0101311 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101322:	5b                   	pop    %ebx
f0101323:	5d                   	pop    %ebp
f0101324:	c3                   	ret    

f0101325 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101325:	55                   	push   %ebp
f0101326:	89 e5                	mov    %esp,%ebp
f0101328:	53                   	push   %ebx
f0101329:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010132c:	53                   	push   %ebx
f010132d:	e8 9a ff ff ff       	call   f01012cc <strlen>
f0101332:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101335:	ff 75 0c             	pushl  0xc(%ebp)
f0101338:	01 d8                	add    %ebx,%eax
f010133a:	50                   	push   %eax
f010133b:	e8 c5 ff ff ff       	call   f0101305 <strcpy>
	return dst;
}
f0101340:	89 d8                	mov    %ebx,%eax
f0101342:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101345:	c9                   	leave  
f0101346:	c3                   	ret    

f0101347 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	56                   	push   %esi
f010134b:	53                   	push   %ebx
f010134c:	8b 75 08             	mov    0x8(%ebp),%esi
f010134f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101352:	89 f3                	mov    %esi,%ebx
f0101354:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101357:	89 f2                	mov    %esi,%edx
f0101359:	eb 0f                	jmp    f010136a <strncpy+0x23>
		*dst++ = *src;
f010135b:	83 c2 01             	add    $0x1,%edx
f010135e:	0f b6 01             	movzbl (%ecx),%eax
f0101361:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101364:	80 39 01             	cmpb   $0x1,(%ecx)
f0101367:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010136a:	39 da                	cmp    %ebx,%edx
f010136c:	75 ed                	jne    f010135b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010136e:	89 f0                	mov    %esi,%eax
f0101370:	5b                   	pop    %ebx
f0101371:	5e                   	pop    %esi
f0101372:	5d                   	pop    %ebp
f0101373:	c3                   	ret    

f0101374 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	56                   	push   %esi
f0101378:	53                   	push   %ebx
f0101379:	8b 75 08             	mov    0x8(%ebp),%esi
f010137c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010137f:	8b 55 10             	mov    0x10(%ebp),%edx
f0101382:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101384:	85 d2                	test   %edx,%edx
f0101386:	74 21                	je     f01013a9 <strlcpy+0x35>
f0101388:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010138c:	89 f2                	mov    %esi,%edx
f010138e:	eb 09                	jmp    f0101399 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101390:	83 c2 01             	add    $0x1,%edx
f0101393:	83 c1 01             	add    $0x1,%ecx
f0101396:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101399:	39 c2                	cmp    %eax,%edx
f010139b:	74 09                	je     f01013a6 <strlcpy+0x32>
f010139d:	0f b6 19             	movzbl (%ecx),%ebx
f01013a0:	84 db                	test   %bl,%bl
f01013a2:	75 ec                	jne    f0101390 <strlcpy+0x1c>
f01013a4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013a6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013a9:	29 f0                	sub    %esi,%eax
}
f01013ab:	5b                   	pop    %ebx
f01013ac:	5e                   	pop    %esi
f01013ad:	5d                   	pop    %ebp
f01013ae:	c3                   	ret    

f01013af <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013af:	55                   	push   %ebp
f01013b0:	89 e5                	mov    %esp,%ebp
f01013b2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013b5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013b8:	eb 06                	jmp    f01013c0 <strcmp+0x11>
		p++, q++;
f01013ba:	83 c1 01             	add    $0x1,%ecx
f01013bd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013c0:	0f b6 01             	movzbl (%ecx),%eax
f01013c3:	84 c0                	test   %al,%al
f01013c5:	74 04                	je     f01013cb <strcmp+0x1c>
f01013c7:	3a 02                	cmp    (%edx),%al
f01013c9:	74 ef                	je     f01013ba <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013cb:	0f b6 c0             	movzbl %al,%eax
f01013ce:	0f b6 12             	movzbl (%edx),%edx
f01013d1:	29 d0                	sub    %edx,%eax
}
f01013d3:	5d                   	pop    %ebp
f01013d4:	c3                   	ret    

f01013d5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013d5:	55                   	push   %ebp
f01013d6:	89 e5                	mov    %esp,%ebp
f01013d8:	53                   	push   %ebx
f01013d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01013dc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013df:	89 c3                	mov    %eax,%ebx
f01013e1:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013e4:	eb 06                	jmp    f01013ec <strncmp+0x17>
		n--, p++, q++;
f01013e6:	83 c0 01             	add    $0x1,%eax
f01013e9:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013ec:	39 d8                	cmp    %ebx,%eax
f01013ee:	74 15                	je     f0101405 <strncmp+0x30>
f01013f0:	0f b6 08             	movzbl (%eax),%ecx
f01013f3:	84 c9                	test   %cl,%cl
f01013f5:	74 04                	je     f01013fb <strncmp+0x26>
f01013f7:	3a 0a                	cmp    (%edx),%cl
f01013f9:	74 eb                	je     f01013e6 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013fb:	0f b6 00             	movzbl (%eax),%eax
f01013fe:	0f b6 12             	movzbl (%edx),%edx
f0101401:	29 d0                	sub    %edx,%eax
f0101403:	eb 05                	jmp    f010140a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101405:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010140a:	5b                   	pop    %ebx
f010140b:	5d                   	pop    %ebp
f010140c:	c3                   	ret    

f010140d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010140d:	55                   	push   %ebp
f010140e:	89 e5                	mov    %esp,%ebp
f0101410:	8b 45 08             	mov    0x8(%ebp),%eax
f0101413:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101417:	eb 07                	jmp    f0101420 <strchr+0x13>
		if (*s == c)
f0101419:	38 ca                	cmp    %cl,%dl
f010141b:	74 0f                	je     f010142c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010141d:	83 c0 01             	add    $0x1,%eax
f0101420:	0f b6 10             	movzbl (%eax),%edx
f0101423:	84 d2                	test   %dl,%dl
f0101425:	75 f2                	jne    f0101419 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101427:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010142c:	5d                   	pop    %ebp
f010142d:	c3                   	ret    

f010142e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010142e:	55                   	push   %ebp
f010142f:	89 e5                	mov    %esp,%ebp
f0101431:	8b 45 08             	mov    0x8(%ebp),%eax
f0101434:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101438:	eb 03                	jmp    f010143d <strfind+0xf>
f010143a:	83 c0 01             	add    $0x1,%eax
f010143d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101440:	38 ca                	cmp    %cl,%dl
f0101442:	74 04                	je     f0101448 <strfind+0x1a>
f0101444:	84 d2                	test   %dl,%dl
f0101446:	75 f2                	jne    f010143a <strfind+0xc>
			break;
	return (char *) s;
}
f0101448:	5d                   	pop    %ebp
f0101449:	c3                   	ret    

f010144a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010144a:	55                   	push   %ebp
f010144b:	89 e5                	mov    %esp,%ebp
f010144d:	57                   	push   %edi
f010144e:	56                   	push   %esi
f010144f:	53                   	push   %ebx
f0101450:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101453:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101456:	85 c9                	test   %ecx,%ecx
f0101458:	74 36                	je     f0101490 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010145a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101460:	75 28                	jne    f010148a <memset+0x40>
f0101462:	f6 c1 03             	test   $0x3,%cl
f0101465:	75 23                	jne    f010148a <memset+0x40>
		c &= 0xFF;
f0101467:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010146b:	89 d3                	mov    %edx,%ebx
f010146d:	c1 e3 08             	shl    $0x8,%ebx
f0101470:	89 d6                	mov    %edx,%esi
f0101472:	c1 e6 18             	shl    $0x18,%esi
f0101475:	89 d0                	mov    %edx,%eax
f0101477:	c1 e0 10             	shl    $0x10,%eax
f010147a:	09 f0                	or     %esi,%eax
f010147c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010147e:	89 d8                	mov    %ebx,%eax
f0101480:	09 d0                	or     %edx,%eax
f0101482:	c1 e9 02             	shr    $0x2,%ecx
f0101485:	fc                   	cld    
f0101486:	f3 ab                	rep stos %eax,%es:(%edi)
f0101488:	eb 06                	jmp    f0101490 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010148a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010148d:	fc                   	cld    
f010148e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101490:	89 f8                	mov    %edi,%eax
f0101492:	5b                   	pop    %ebx
f0101493:	5e                   	pop    %esi
f0101494:	5f                   	pop    %edi
f0101495:	5d                   	pop    %ebp
f0101496:	c3                   	ret    

f0101497 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101497:	55                   	push   %ebp
f0101498:	89 e5                	mov    %esp,%ebp
f010149a:	57                   	push   %edi
f010149b:	56                   	push   %esi
f010149c:	8b 45 08             	mov    0x8(%ebp),%eax
f010149f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014a2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014a5:	39 c6                	cmp    %eax,%esi
f01014a7:	73 35                	jae    f01014de <memmove+0x47>
f01014a9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014ac:	39 d0                	cmp    %edx,%eax
f01014ae:	73 2e                	jae    f01014de <memmove+0x47>
		s += n;
		d += n;
f01014b0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b3:	89 d6                	mov    %edx,%esi
f01014b5:	09 fe                	or     %edi,%esi
f01014b7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014bd:	75 13                	jne    f01014d2 <memmove+0x3b>
f01014bf:	f6 c1 03             	test   $0x3,%cl
f01014c2:	75 0e                	jne    f01014d2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014c4:	83 ef 04             	sub    $0x4,%edi
f01014c7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014ca:	c1 e9 02             	shr    $0x2,%ecx
f01014cd:	fd                   	std    
f01014ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014d0:	eb 09                	jmp    f01014db <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014d2:	83 ef 01             	sub    $0x1,%edi
f01014d5:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014d8:	fd                   	std    
f01014d9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014db:	fc                   	cld    
f01014dc:	eb 1d                	jmp    f01014fb <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014de:	89 f2                	mov    %esi,%edx
f01014e0:	09 c2                	or     %eax,%edx
f01014e2:	f6 c2 03             	test   $0x3,%dl
f01014e5:	75 0f                	jne    f01014f6 <memmove+0x5f>
f01014e7:	f6 c1 03             	test   $0x3,%cl
f01014ea:	75 0a                	jne    f01014f6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014ec:	c1 e9 02             	shr    $0x2,%ecx
f01014ef:	89 c7                	mov    %eax,%edi
f01014f1:	fc                   	cld    
f01014f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014f4:	eb 05                	jmp    f01014fb <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014f6:	89 c7                	mov    %eax,%edi
f01014f8:	fc                   	cld    
f01014f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014fb:	5e                   	pop    %esi
f01014fc:	5f                   	pop    %edi
f01014fd:	5d                   	pop    %ebp
f01014fe:	c3                   	ret    

f01014ff <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014ff:	55                   	push   %ebp
f0101500:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101502:	ff 75 10             	pushl  0x10(%ebp)
f0101505:	ff 75 0c             	pushl  0xc(%ebp)
f0101508:	ff 75 08             	pushl  0x8(%ebp)
f010150b:	e8 87 ff ff ff       	call   f0101497 <memmove>
}
f0101510:	c9                   	leave  
f0101511:	c3                   	ret    

f0101512 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101512:	55                   	push   %ebp
f0101513:	89 e5                	mov    %esp,%ebp
f0101515:	56                   	push   %esi
f0101516:	53                   	push   %ebx
f0101517:	8b 45 08             	mov    0x8(%ebp),%eax
f010151a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010151d:	89 c6                	mov    %eax,%esi
f010151f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101522:	eb 1a                	jmp    f010153e <memcmp+0x2c>
		if (*s1 != *s2)
f0101524:	0f b6 08             	movzbl (%eax),%ecx
f0101527:	0f b6 1a             	movzbl (%edx),%ebx
f010152a:	38 d9                	cmp    %bl,%cl
f010152c:	74 0a                	je     f0101538 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010152e:	0f b6 c1             	movzbl %cl,%eax
f0101531:	0f b6 db             	movzbl %bl,%ebx
f0101534:	29 d8                	sub    %ebx,%eax
f0101536:	eb 0f                	jmp    f0101547 <memcmp+0x35>
		s1++, s2++;
f0101538:	83 c0 01             	add    $0x1,%eax
f010153b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010153e:	39 f0                	cmp    %esi,%eax
f0101540:	75 e2                	jne    f0101524 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101542:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101547:	5b                   	pop    %ebx
f0101548:	5e                   	pop    %esi
f0101549:	5d                   	pop    %ebp
f010154a:	c3                   	ret    

f010154b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
f010154e:	53                   	push   %ebx
f010154f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101552:	89 c1                	mov    %eax,%ecx
f0101554:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101557:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010155b:	eb 0a                	jmp    f0101567 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010155d:	0f b6 10             	movzbl (%eax),%edx
f0101560:	39 da                	cmp    %ebx,%edx
f0101562:	74 07                	je     f010156b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101564:	83 c0 01             	add    $0x1,%eax
f0101567:	39 c8                	cmp    %ecx,%eax
f0101569:	72 f2                	jb     f010155d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010156b:	5b                   	pop    %ebx
f010156c:	5d                   	pop    %ebp
f010156d:	c3                   	ret    

f010156e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010156e:	55                   	push   %ebp
f010156f:	89 e5                	mov    %esp,%ebp
f0101571:	57                   	push   %edi
f0101572:	56                   	push   %esi
f0101573:	53                   	push   %ebx
f0101574:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101577:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010157a:	eb 03                	jmp    f010157f <strtol+0x11>
		s++;
f010157c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010157f:	0f b6 01             	movzbl (%ecx),%eax
f0101582:	3c 20                	cmp    $0x20,%al
f0101584:	74 f6                	je     f010157c <strtol+0xe>
f0101586:	3c 09                	cmp    $0x9,%al
f0101588:	74 f2                	je     f010157c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010158a:	3c 2b                	cmp    $0x2b,%al
f010158c:	75 0a                	jne    f0101598 <strtol+0x2a>
		s++;
f010158e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101591:	bf 00 00 00 00       	mov    $0x0,%edi
f0101596:	eb 11                	jmp    f01015a9 <strtol+0x3b>
f0101598:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010159d:	3c 2d                	cmp    $0x2d,%al
f010159f:	75 08                	jne    f01015a9 <strtol+0x3b>
		s++, neg = 1;
f01015a1:	83 c1 01             	add    $0x1,%ecx
f01015a4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015a9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015af:	75 15                	jne    f01015c6 <strtol+0x58>
f01015b1:	80 39 30             	cmpb   $0x30,(%ecx)
f01015b4:	75 10                	jne    f01015c6 <strtol+0x58>
f01015b6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015ba:	75 7c                	jne    f0101638 <strtol+0xca>
		s += 2, base = 16;
f01015bc:	83 c1 02             	add    $0x2,%ecx
f01015bf:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015c4:	eb 16                	jmp    f01015dc <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015c6:	85 db                	test   %ebx,%ebx
f01015c8:	75 12                	jne    f01015dc <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015ca:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015cf:	80 39 30             	cmpb   $0x30,(%ecx)
f01015d2:	75 08                	jne    f01015dc <strtol+0x6e>
		s++, base = 8;
f01015d4:	83 c1 01             	add    $0x1,%ecx
f01015d7:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01015e1:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015e4:	0f b6 11             	movzbl (%ecx),%edx
f01015e7:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015ea:	89 f3                	mov    %esi,%ebx
f01015ec:	80 fb 09             	cmp    $0x9,%bl
f01015ef:	77 08                	ja     f01015f9 <strtol+0x8b>
			dig = *s - '0';
f01015f1:	0f be d2             	movsbl %dl,%edx
f01015f4:	83 ea 30             	sub    $0x30,%edx
f01015f7:	eb 22                	jmp    f010161b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015f9:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015fc:	89 f3                	mov    %esi,%ebx
f01015fe:	80 fb 19             	cmp    $0x19,%bl
f0101601:	77 08                	ja     f010160b <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101603:	0f be d2             	movsbl %dl,%edx
f0101606:	83 ea 57             	sub    $0x57,%edx
f0101609:	eb 10                	jmp    f010161b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010160b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010160e:	89 f3                	mov    %esi,%ebx
f0101610:	80 fb 19             	cmp    $0x19,%bl
f0101613:	77 16                	ja     f010162b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101615:	0f be d2             	movsbl %dl,%edx
f0101618:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010161b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010161e:	7d 0b                	jge    f010162b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101620:	83 c1 01             	add    $0x1,%ecx
f0101623:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101627:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101629:	eb b9                	jmp    f01015e4 <strtol+0x76>

	if (endptr)
f010162b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010162f:	74 0d                	je     f010163e <strtol+0xd0>
		*endptr = (char *) s;
f0101631:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101634:	89 0e                	mov    %ecx,(%esi)
f0101636:	eb 06                	jmp    f010163e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101638:	85 db                	test   %ebx,%ebx
f010163a:	74 98                	je     f01015d4 <strtol+0x66>
f010163c:	eb 9e                	jmp    f01015dc <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010163e:	89 c2                	mov    %eax,%edx
f0101640:	f7 da                	neg    %edx
f0101642:	85 ff                	test   %edi,%edi
f0101644:	0f 45 c2             	cmovne %edx,%eax
}
f0101647:	5b                   	pop    %ebx
f0101648:	5e                   	pop    %esi
f0101649:	5f                   	pop    %edi
f010164a:	5d                   	pop    %ebp
f010164b:	c3                   	ret    
f010164c:	66 90                	xchg   %ax,%ax
f010164e:	66 90                	xchg   %ax,%ax

f0101650 <__udivdi3>:
f0101650:	55                   	push   %ebp
f0101651:	57                   	push   %edi
f0101652:	56                   	push   %esi
f0101653:	53                   	push   %ebx
f0101654:	83 ec 1c             	sub    $0x1c,%esp
f0101657:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010165b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010165f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101663:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101667:	85 f6                	test   %esi,%esi
f0101669:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010166d:	89 ca                	mov    %ecx,%edx
f010166f:	89 f8                	mov    %edi,%eax
f0101671:	75 3d                	jne    f01016b0 <__udivdi3+0x60>
f0101673:	39 cf                	cmp    %ecx,%edi
f0101675:	0f 87 c5 00 00 00    	ja     f0101740 <__udivdi3+0xf0>
f010167b:	85 ff                	test   %edi,%edi
f010167d:	89 fd                	mov    %edi,%ebp
f010167f:	75 0b                	jne    f010168c <__udivdi3+0x3c>
f0101681:	b8 01 00 00 00       	mov    $0x1,%eax
f0101686:	31 d2                	xor    %edx,%edx
f0101688:	f7 f7                	div    %edi
f010168a:	89 c5                	mov    %eax,%ebp
f010168c:	89 c8                	mov    %ecx,%eax
f010168e:	31 d2                	xor    %edx,%edx
f0101690:	f7 f5                	div    %ebp
f0101692:	89 c1                	mov    %eax,%ecx
f0101694:	89 d8                	mov    %ebx,%eax
f0101696:	89 cf                	mov    %ecx,%edi
f0101698:	f7 f5                	div    %ebp
f010169a:	89 c3                	mov    %eax,%ebx
f010169c:	89 d8                	mov    %ebx,%eax
f010169e:	89 fa                	mov    %edi,%edx
f01016a0:	83 c4 1c             	add    $0x1c,%esp
f01016a3:	5b                   	pop    %ebx
f01016a4:	5e                   	pop    %esi
f01016a5:	5f                   	pop    %edi
f01016a6:	5d                   	pop    %ebp
f01016a7:	c3                   	ret    
f01016a8:	90                   	nop
f01016a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016b0:	39 ce                	cmp    %ecx,%esi
f01016b2:	77 74                	ja     f0101728 <__udivdi3+0xd8>
f01016b4:	0f bd fe             	bsr    %esi,%edi
f01016b7:	83 f7 1f             	xor    $0x1f,%edi
f01016ba:	0f 84 98 00 00 00    	je     f0101758 <__udivdi3+0x108>
f01016c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	89 c5                	mov    %eax,%ebp
f01016c9:	29 fb                	sub    %edi,%ebx
f01016cb:	d3 e6                	shl    %cl,%esi
f01016cd:	89 d9                	mov    %ebx,%ecx
f01016cf:	d3 ed                	shr    %cl,%ebp
f01016d1:	89 f9                	mov    %edi,%ecx
f01016d3:	d3 e0                	shl    %cl,%eax
f01016d5:	09 ee                	or     %ebp,%esi
f01016d7:	89 d9                	mov    %ebx,%ecx
f01016d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016dd:	89 d5                	mov    %edx,%ebp
f01016df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016e3:	d3 ed                	shr    %cl,%ebp
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	d3 e2                	shl    %cl,%edx
f01016e9:	89 d9                	mov    %ebx,%ecx
f01016eb:	d3 e8                	shr    %cl,%eax
f01016ed:	09 c2                	or     %eax,%edx
f01016ef:	89 d0                	mov    %edx,%eax
f01016f1:	89 ea                	mov    %ebp,%edx
f01016f3:	f7 f6                	div    %esi
f01016f5:	89 d5                	mov    %edx,%ebp
f01016f7:	89 c3                	mov    %eax,%ebx
f01016f9:	f7 64 24 0c          	mull   0xc(%esp)
f01016fd:	39 d5                	cmp    %edx,%ebp
f01016ff:	72 10                	jb     f0101711 <__udivdi3+0xc1>
f0101701:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	d3 e6                	shl    %cl,%esi
f0101709:	39 c6                	cmp    %eax,%esi
f010170b:	73 07                	jae    f0101714 <__udivdi3+0xc4>
f010170d:	39 d5                	cmp    %edx,%ebp
f010170f:	75 03                	jne    f0101714 <__udivdi3+0xc4>
f0101711:	83 eb 01             	sub    $0x1,%ebx
f0101714:	31 ff                	xor    %edi,%edi
f0101716:	89 d8                	mov    %ebx,%eax
f0101718:	89 fa                	mov    %edi,%edx
f010171a:	83 c4 1c             	add    $0x1c,%esp
f010171d:	5b                   	pop    %ebx
f010171e:	5e                   	pop    %esi
f010171f:	5f                   	pop    %edi
f0101720:	5d                   	pop    %ebp
f0101721:	c3                   	ret    
f0101722:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101728:	31 ff                	xor    %edi,%edi
f010172a:	31 db                	xor    %ebx,%ebx
f010172c:	89 d8                	mov    %ebx,%eax
f010172e:	89 fa                	mov    %edi,%edx
f0101730:	83 c4 1c             	add    $0x1c,%esp
f0101733:	5b                   	pop    %ebx
f0101734:	5e                   	pop    %esi
f0101735:	5f                   	pop    %edi
f0101736:	5d                   	pop    %ebp
f0101737:	c3                   	ret    
f0101738:	90                   	nop
f0101739:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101740:	89 d8                	mov    %ebx,%eax
f0101742:	f7 f7                	div    %edi
f0101744:	31 ff                	xor    %edi,%edi
f0101746:	89 c3                	mov    %eax,%ebx
f0101748:	89 d8                	mov    %ebx,%eax
f010174a:	89 fa                	mov    %edi,%edx
f010174c:	83 c4 1c             	add    $0x1c,%esp
f010174f:	5b                   	pop    %ebx
f0101750:	5e                   	pop    %esi
f0101751:	5f                   	pop    %edi
f0101752:	5d                   	pop    %ebp
f0101753:	c3                   	ret    
f0101754:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101758:	39 ce                	cmp    %ecx,%esi
f010175a:	72 0c                	jb     f0101768 <__udivdi3+0x118>
f010175c:	31 db                	xor    %ebx,%ebx
f010175e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101762:	0f 87 34 ff ff ff    	ja     f010169c <__udivdi3+0x4c>
f0101768:	bb 01 00 00 00       	mov    $0x1,%ebx
f010176d:	e9 2a ff ff ff       	jmp    f010169c <__udivdi3+0x4c>
f0101772:	66 90                	xchg   %ax,%ax
f0101774:	66 90                	xchg   %ax,%ax
f0101776:	66 90                	xchg   %ax,%ax
f0101778:	66 90                	xchg   %ax,%ax
f010177a:	66 90                	xchg   %ax,%ax
f010177c:	66 90                	xchg   %ax,%ax
f010177e:	66 90                	xchg   %ax,%ax

f0101780 <__umoddi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	53                   	push   %ebx
f0101784:	83 ec 1c             	sub    $0x1c,%esp
f0101787:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010178b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010178f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101793:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101797:	85 d2                	test   %edx,%edx
f0101799:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010179d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017a1:	89 f3                	mov    %esi,%ebx
f01017a3:	89 3c 24             	mov    %edi,(%esp)
f01017a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017aa:	75 1c                	jne    f01017c8 <__umoddi3+0x48>
f01017ac:	39 f7                	cmp    %esi,%edi
f01017ae:	76 50                	jbe    f0101800 <__umoddi3+0x80>
f01017b0:	89 c8                	mov    %ecx,%eax
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	f7 f7                	div    %edi
f01017b6:	89 d0                	mov    %edx,%eax
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	83 c4 1c             	add    $0x1c,%esp
f01017bd:	5b                   	pop    %ebx
f01017be:	5e                   	pop    %esi
f01017bf:	5f                   	pop    %edi
f01017c0:	5d                   	pop    %ebp
f01017c1:	c3                   	ret    
f01017c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017c8:	39 f2                	cmp    %esi,%edx
f01017ca:	89 d0                	mov    %edx,%eax
f01017cc:	77 52                	ja     f0101820 <__umoddi3+0xa0>
f01017ce:	0f bd ea             	bsr    %edx,%ebp
f01017d1:	83 f5 1f             	xor    $0x1f,%ebp
f01017d4:	75 5a                	jne    f0101830 <__umoddi3+0xb0>
f01017d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017da:	0f 82 e0 00 00 00    	jb     f01018c0 <__umoddi3+0x140>
f01017e0:	39 0c 24             	cmp    %ecx,(%esp)
f01017e3:	0f 86 d7 00 00 00    	jbe    f01018c0 <__umoddi3+0x140>
f01017e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017f1:	83 c4 1c             	add    $0x1c,%esp
f01017f4:	5b                   	pop    %ebx
f01017f5:	5e                   	pop    %esi
f01017f6:	5f                   	pop    %edi
f01017f7:	5d                   	pop    %ebp
f01017f8:	c3                   	ret    
f01017f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101800:	85 ff                	test   %edi,%edi
f0101802:	89 fd                	mov    %edi,%ebp
f0101804:	75 0b                	jne    f0101811 <__umoddi3+0x91>
f0101806:	b8 01 00 00 00       	mov    $0x1,%eax
f010180b:	31 d2                	xor    %edx,%edx
f010180d:	f7 f7                	div    %edi
f010180f:	89 c5                	mov    %eax,%ebp
f0101811:	89 f0                	mov    %esi,%eax
f0101813:	31 d2                	xor    %edx,%edx
f0101815:	f7 f5                	div    %ebp
f0101817:	89 c8                	mov    %ecx,%eax
f0101819:	f7 f5                	div    %ebp
f010181b:	89 d0                	mov    %edx,%eax
f010181d:	eb 99                	jmp    f01017b8 <__umoddi3+0x38>
f010181f:	90                   	nop
f0101820:	89 c8                	mov    %ecx,%eax
f0101822:	89 f2                	mov    %esi,%edx
f0101824:	83 c4 1c             	add    $0x1c,%esp
f0101827:	5b                   	pop    %ebx
f0101828:	5e                   	pop    %esi
f0101829:	5f                   	pop    %edi
f010182a:	5d                   	pop    %ebp
f010182b:	c3                   	ret    
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	8b 34 24             	mov    (%esp),%esi
f0101833:	bf 20 00 00 00       	mov    $0x20,%edi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	29 ef                	sub    %ebp,%edi
f010183c:	d3 e0                	shl    %cl,%eax
f010183e:	89 f9                	mov    %edi,%ecx
f0101840:	89 f2                	mov    %esi,%edx
f0101842:	d3 ea                	shr    %cl,%edx
f0101844:	89 e9                	mov    %ebp,%ecx
f0101846:	09 c2                	or     %eax,%edx
f0101848:	89 d8                	mov    %ebx,%eax
f010184a:	89 14 24             	mov    %edx,(%esp)
f010184d:	89 f2                	mov    %esi,%edx
f010184f:	d3 e2                	shl    %cl,%edx
f0101851:	89 f9                	mov    %edi,%ecx
f0101853:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101857:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010185b:	d3 e8                	shr    %cl,%eax
f010185d:	89 e9                	mov    %ebp,%ecx
f010185f:	89 c6                	mov    %eax,%esi
f0101861:	d3 e3                	shl    %cl,%ebx
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 d0                	mov    %edx,%eax
f0101867:	d3 e8                	shr    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	09 d8                	or     %ebx,%eax
f010186d:	89 d3                	mov    %edx,%ebx
f010186f:	89 f2                	mov    %esi,%edx
f0101871:	f7 34 24             	divl   (%esp)
f0101874:	89 d6                	mov    %edx,%esi
f0101876:	d3 e3                	shl    %cl,%ebx
f0101878:	f7 64 24 04          	mull   0x4(%esp)
f010187c:	39 d6                	cmp    %edx,%esi
f010187e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101882:	89 d1                	mov    %edx,%ecx
f0101884:	89 c3                	mov    %eax,%ebx
f0101886:	72 08                	jb     f0101890 <__umoddi3+0x110>
f0101888:	75 11                	jne    f010189b <__umoddi3+0x11b>
f010188a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010188e:	73 0b                	jae    f010189b <__umoddi3+0x11b>
f0101890:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101894:	1b 14 24             	sbb    (%esp),%edx
f0101897:	89 d1                	mov    %edx,%ecx
f0101899:	89 c3                	mov    %eax,%ebx
f010189b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010189f:	29 da                	sub    %ebx,%edx
f01018a1:	19 ce                	sbb    %ecx,%esi
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 f0                	mov    %esi,%eax
f01018a7:	d3 e0                	shl    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	d3 ea                	shr    %cl,%edx
f01018ad:	89 e9                	mov    %ebp,%ecx
f01018af:	d3 ee                	shr    %cl,%esi
f01018b1:	09 d0                	or     %edx,%eax
f01018b3:	89 f2                	mov    %esi,%edx
f01018b5:	83 c4 1c             	add    $0x1c,%esp
f01018b8:	5b                   	pop    %ebx
f01018b9:	5e                   	pop    %esi
f01018ba:	5f                   	pop    %edi
f01018bb:	5d                   	pop    %ebp
f01018bc:	c3                   	ret    
f01018bd:	8d 76 00             	lea    0x0(%esi),%esi
f01018c0:	29 f9                	sub    %edi,%ecx
f01018c2:	19 d6                	sbb    %edx,%esi
f01018c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018cc:	e9 18 ff ff ff       	jmp    f01017e9 <__umoddi3+0x69>
