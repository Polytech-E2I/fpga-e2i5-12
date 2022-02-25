#include <cep_platform.h>
#ifdef ENV_QEMU
#include <stdio.h>
#endif

static volatile uint32_t *led          = (volatile uint32_t *)REG_LEDS_ADDR; // IP led
static volatile uint32_t *push         = (volatile uint32_t *)REG_PIN_ADDR;  // IP push
static volatile uint64_t *timer        = (volatile uint64_t *)CLINT_TIMER;
static volatile uint64_t *timer_cmp    = (volatile uint64_t *)CLINT_TIMER_CMP;
static volatile uint32_t *timer_hi     = (volatile uint32_t *)CLINT_TIMER_HI;
static volatile uint32_t *timer_lo     = (volatile uint32_t *)CLINT_TIMER_LOW;
static volatile uint32_t *timer_cmp_hi = (volatile uint32_t *)CLINT_TIMER_CMP_HI;
static volatile uint32_t *timer_cmp_lo = (volatile uint32_t *)CLINT_TIMER_CMP_LO;

void display_timer()
{
#ifdef ENV_QEMU
    printf("mtimehi : 0x%x\n", *timer_hi);
    printf("mtimelo : 0x%x\n", *timer_lo);
    printf("mtimecmphi : 0x%x\n", *timer_cmp_hi);
    printf("mtimecmplo : 0x%x\n", *timer_cmp_lo);
#else
#endif
}

// function to set the timer to be reached in period*time/TIMER_RATIO in the future
void timer_set(uint32_t period, uint32_t time)
{
    //display_timer();
    uint64_t now = *timer;
    *timer_cmp = now + ((uint64_t)period/TIMER_RATIO * time);
    //display_timer();
}


// function to wait for timer zero value
void timer_wait(void)
{
    while(*timer <=  *timer_cmp);
}

void timer_set_and_wait(uint32_t period, uint32_t time)
{
    timer_set(period, time);
    timer_wait();
}

// function to set the value displayed on leds
void led_set(uint32_t value)
{
    *led = value;
}

// function to get the pressed button or the event to quit
uint32_t push_button_get()
{
    return (*push) >> 16;
}
