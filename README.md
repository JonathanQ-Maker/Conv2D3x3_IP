# Convolution 2D 3x3 (Conv2D3x3) IP
This repository contains the FPGA softcore for 2-dimentional convolution optimized for deep learning inference.


## Description
The Convolution 2D 3x3 (Conv2D3x3) IP provides high-bandwidth 2-dimentional convolution against fixed 3x3 filter size. It is optimized for deep learning inference against high channel count input images and kernels. The Conv2D3x3 IP uses AXI4 stream for both data ingress and egress allowing for a cascading configuration.

## Key Features and Benefits
- AXI4 compliant
- Async kernel and input image loading with seperate AXI4-Stream ports
- Uses Block RAM for line buffers and kernel buffers
- Tree adder for logarithmic complexity
- Customizable image height, image width, pixel channels.
- Customizable kernel filter count
- Customizable AXI4-Stream width and word width
- Fixed point arithmatic 

| IP Facts Table      |         |
|---------------------|---------|
| Design Files        | Verilog |
| Test Bench          | Verilog |
| Simulation tool     | Vivado  |
| Supported Synthesis | Vivado  |


## User Guide
### Port Descriptions
Table: I/O Ports of the Conv2D3x3 module.

| Signal Name       | Signal Type   | Description                                   |
|-------------------|---------------|-----------------------------------------------|
| i_aclk            | Input         | global clock                                  |
| i_aresetn         | Input         | synchronous global reset signal, active low   |
|                   |               |                                               |
| i_tvalid          | Input         | Slave AXI4-Stream TVALID for input image data |
| o_tready          | Output        | Slave AXI4-Stream TREADY for input image data |
| i_tdata           | Input         | Slave AXI4-Stream TDATA for input image data  |
|                   |               |                                               |
| i_kernel_tvalid   | Input         | Slave AXI4-Stream TVALID for kernel data      |
| o_kernel_tready   | Output        | Slave AXI4-Stream TREADY for kernel data      |
| i_kernel_tdata    | Input         | Slave AXI4-Stream TDATA for kernel data       |
|                   |               |                                               |
| o_tvalid          | Output        | Master AXI4-Stream TVALID for result data     |
| i_tready          | Input         | Master AXI4-Stream TREADY for result data     |
| o_tdata           | Output        | Master AXI4-Stream TDATA for result data      |

### Paremeter Descriptions
Table: Parameter constants of the Conv2D3x3 module. Constants must be defined following the listed requirements.

| Paremeter Name    | Requirements                                              | Description                       |
|-------------------|-----------------------------------------------------------|-----------------------------------|
| IN_HEIGHT         | IN_HEIGHT >= 3                                            | Input image height in pixels      |
| IN_WIDTH          | IN_WIDTH >= 3                                             | Input image width in pixels       |
| IN_CHANNEL        | IN_CHANNEL % WORDS == 0                                   | Input image channels in words     |
| WORDS             | WORDS >= 1                                                | Number of words per transfer      |
| WORD_WIDTH        | WORD_WIDTH >= 1                                           | Width of each word                |
| FILTERS           | FILTERS % (KERNEL_BUF_WIDTH / (WORDS \* WORD_WIDTH)) == 0 | Number of filters in the kernel   |
| KERNEL_BUF_WIDTH  | KERNEL_BUF_WIDTH % (WORDS \* WORD_WIDTH) == 0             | Width of the kernel buffer port   |