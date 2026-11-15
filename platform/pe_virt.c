/*
 * Darwinos lite6: platform-код для QEMU "virt" (aarch64, Cortex-A57).
 * НЕ ПРОВЕРЕНО НА СБОРКЕ В XNU: интеграцию в pexpert нужно сделать на Mac.
 * Положить в src/xnu/pexpert/arm/pe_virt.c.
 *
 * Карта QEMU virt: UART PL011 0x09000000, GICv2 dist 0x08000000, cpu 0x08010000,
 * RAM 0x40000000. Таймер: generic timer, виртуальный, PPI 27.
 */
#include <stdint.h>

#define VIRT_UART_BASE 0x09000000ull
#define VIRT_GICD_BASE 0x08000000ull
#define VIRT_GICC_BASE 0x08010000ull

#define UART_DR   0x00
#define UART_FR   0x18
#define UART_LCRH 0x2C
#define UART_CR   0x30
#define UART_FR_TXFF (1u << 5)
#define UART_FR_RXFE (1u << 4)

#define GICD_CTLR      0x000
#define GICD_ISENABLER 0x100
#define GICC_CTLR      0x000
#define GICC_PMR       0x004
#define GICC_IAR       0x00C
#define GICC_EOIR      0x010

#define VIRT_TIMER_PPI 27

static inline void mmio_w(uint64_t base, uint32_t off, uint32_t v)
{ *(volatile uint32_t *)(base + off) = v; }
static inline uint32_t mmio_r(uint64_t base, uint32_t off)
{ return *(volatile uint32_t *)(base + off); }

/* До MMU: физические адреса. После: отобразить через ml_io_map(). */
void pe_virt_uart_init(void)
{
	mmio_w(VIRT_UART_BASE, UART_CR, 0);
	mmio_w(VIRT_UART_BASE, UART_LCRH, 0x70);   /* 8n1, FIFO */
	mmio_w(VIRT_UART_BASE, UART_CR, 0x301);    /* UARTEN | TXE | RXE */
}

void pe_virt_putc(int c)
{
	if (c == '\n') pe_virt_putc('\r');
	while (mmio_r(VIRT_UART_BASE, UART_FR) & UART_FR_TXFF) ;
	mmio_w(VIRT_UART_BASE, UART_DR, (uint32_t)c);
}

int pe_virt_getc(void)
{
	if (mmio_r(VIRT_UART_BASE, UART_FR) & UART_FR_RXFE) return -1;
	return (int)(mmio_r(VIRT_UART_BASE, UART_DR) & 0xFF);
}

void pe_virt_gic_init(void)
{
	mmio_w(VIRT_GICD_BASE, GICD_CTLR, 0);
	mmio_w(VIRT_GICC_BASE, GICC_PMR, 0xFF);
	mmio_w(VIRT_GICC_BASE, GICC_CTLR, 1);
	mmio_w(VIRT_GICD_BASE, GICD_CTLR, 1);
}

void pe_virt_irq_enable(uint32_t irq)
{ mmio_w(VIRT_GICD_BASE, GICD_ISENABLER + 4 * (irq / 32), 1u << (irq % 32)); }
uint32_t pe_virt_irq_ack(void) { return mmio_r(VIRT_GICC_BASE, GICC_IAR) & 0x3FF; }
void pe_virt_irq_eoi(uint32_t irq) { mmio_w(VIRT_GICC_BASE, GICC_EOIR, irq); }

/* ---- generic timer (virtual), aarch64 ---- */
static inline uint64_t cntfrq(void)
{ uint64_t v; __asm__ volatile("mrs %0, cntfrq_el0" : "=r"(v)); return v; }
static inline uint64_t cntvct(void)
{ uint64_t v; __asm__ volatile("isb; mrs %0, cntvct_el0" : "=r"(v)); return v; }
static inline void cntv_tval(uint32_t v)
{ __asm__ volatile("msr cntv_tval_el0, %0" :: "r"((uint64_t)v)); }
static inline void cntv_ctl(uint32_t v)
{ __asm__ volatile("msr cntv_ctl_el0, %0" :: "r"((uint64_t)v)); }

void pe_virt_timer_init(void) { pe_virt_irq_enable(VIRT_TIMER_PPI); cntv_ctl(0); }
void pe_virt_timer_set(uint32_t ticks) { cntv_tval(ticks); cntv_ctl(1); }
uint64_t pe_virt_timer_now(void) { return cntvct(); }
uint64_t pe_virt_timer_freq(void) { return cntfrq(); }

void PE_init_platform_virt(void)
{
	pe_virt_uart_init();
	pe_virt_gic_init();
	pe_virt_timer_init();
	const char *s = "Darwinos lite6 (virt)\n";
	while (*s) pe_virt_putc(*s++);
}
