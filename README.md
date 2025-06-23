# FPGA LCD Camera System

An embedded systems project implementing custom master interfaces for moving large amounts of data between peripherals (camera) and memory, and from memory to display (LCD) using the DE0-Nano-SoC FPGA.

## Project Overview

This project designs custom master interfaces for complex cases where large amounts of data need to be moved from a peripheral (camera) to memory and from memory to a peripheral (display). The system implements a complete interaction between the DE0-Nano-SoC FPGA with camera and LCD components.

## System Architecture

### High Level Components

- **LCD Interaction Module** - Custom IP with master interface to Avalon Bus
- **Camera Interaction Module** - Custom IP with master interface to Avalon Bus  
- **DE0-Nano-SoC FPGA** - Main processing platform
- **LT24 LCD Display** - 240(H)×320(V) display with ILI9341 controller
- **Avalon Bus** - System interconnect

### LCD Interaction Module Components

1. **Registers Avalon Slave** - Interface for NIOS II processor initialization
2. **Avalon Master Controller** - DMA for transferring data from memory to LCD
3. **FIFO Buffer** - Synchronizes asynchronous read/write operations  
4. **LCD Control** - Interfaces with ILI9341 controller

## Register Map

| Address | Register | Description |
|---------|----------|-------------|
| 000 | iReg_Cmd_Adrs [15:0] | ILI9341 command address |
| 001 | iReg_Cmd_Data [15:0] | ILI9341 command data |
| 010 | iReg_LCD_Init [3:0] | LCD control bits |
| 011 | iReg_Ads_Src [31:0] | Source memory address |
| 100 | iReg_Data_Length [15:0] | Data transfer length |
| 101 | iReg_Burst_Cnt [5:0] | Burst count (64) |
| 110 | iReg_LCD_Done | LCD frame completion |
| 111 | iReg_DMA_Done | DMA completion |

### LCD Control Bits (iReg_LCD_Init)
- **Bit 0 (LCD_ON)**: Display on/off control
- **Bit 1 (RESET_N)**: Controller reset (active low)
- **Bit 2 (CS_N)**: Chip select (always 0)
- **Bit 3 (Read_Frame)**: Start reading data from FIFO
- **Bit 4 (R_S)**: Command/data differentiation

## Memory Organization

- **Display Resolution**: 240×320 pixels
- **Pixel Format**: 16 bits (5R, 6G, 5B)
- **Memory Address Width**: 32 bits (2 pixels per address)
- **Total Addresses per Frame**: 38,400
- **Memory Layout**: 160 addresses per row × 240 rows

## DMA Controller

### Finite State Machine States
1. **Idle** - Reset state, waits for LCD_ON and Master_Begin
2. **Look FIFO** - Checks FIFO capacity (waits if usedw ≥ 192)
3. **Prepare Read** - Sets up Avalon read transaction
4. **Get Data** - Transfers 64 words from memory to FIFO
5. **Check Frame Completed** - Verifies complete frame transfer (600 bursts)

### Key Parameters
- **Burst Count**: 64 words per transfer
- **Frame Size**: 600 burst transfers per complete image
- **FIFO Depth**: 256 rows (4 × burst count)

## LCD Controller

### Finite State Machine States
1. **Idle** - Waits for Read_Frame or Change_LCD signals
2. **Reading Data** - Processes pixel data from FIFO or commands from registers
3. **Wait 1** - Timing compliance (WRX low for 1 cycle)
4. **Flip Write** - Toggle WRX signal
5. **Wait 2** - Timing compliance (WRX high for 1 cycle)

### Timing Requirements
- **Write Cycle Duration (twc)**: Minimum 66 ns
- **Write Control Pulse H (twrh)**: Minimum 15 ns  
- **Write Control Pulse L (twrl)**: Minimum 15 ns
- **Clock Period**: 20 ns (requires 4 clock cycles per write)

## FIFO Configuration

- **Width**: 32 bits (write) / 16 bits (read)
- **Depth**: 256 rows
- **FIFO_Almost_Full**: Set when 3 of 4 rows filled
- **FIFO_Almost_Empty**: Set when 1 of 4 rows filled

## Testing

The system was validated through:
- Individual component testbenches (Registers, LCD Controller, DMA Controller)
- Full system simulation
- Hardware testing with image loaded from host filesystem
- Image conversion using LCD-Image-Converter tool

## Authors

- Jason Mina
- Ahmet Avcioglu

**Course**: CS 473: Embedded Systems
