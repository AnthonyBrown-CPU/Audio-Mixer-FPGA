/*
 ============================================================================
 Name        : Serial_Loopback.c
 Author      : 
 Version     :
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#include <string.h>

#include <fcntl.h> // Contains file controls like O_RDWR
#include <errno.h> // Error integer and strerror() function
#include <termios.h> // Contains POSIX terminal control definitions
#include <unistd.h> // write(), read(), close()

// CONSTANTS
const char m_head = '#';
const char m_tail = '$';

// Main bus; Command FIFO, Ethernet FIFO
#define FPGA_AXI_BASE 0xC0000000
#define FPGA_AXI_SPAN 0x00001000

// lw bus; Command FIFO CSR, Ethernet FIFO CSR
#define FPGA_LW_BASE 	0xff200000
#define FPGA_LW_SPAN	0x00001000

#define Command_FIFO_IN_OFFSET 0x00   // MAIN
#define Command_FIFO_CSR_OFFSET 0x00  // LW

//#define Ethernet_FIFO_OUT_OFFSET 0x04 // MAIN
//#define Ethernet_FIFO_CSR_OFFSET 0x20 // LW

//#define Output_Enable_OFFSET 0x40	  // LW

// Busus bases
void *h2p_virtual_base;
void *h2p_lw_virtual_base;

// FIFO Pointers
//volatile unsigned int * Ethernet_FIFO_OUT_ptr = NULL; // uint32_t
//volatile unsigned int * Ethernet_FIFO_CSR_ptr = NULL;

volatile unsigned int * Command_FIFO_IN_ptr = NULL; // uint32_t
volatile unsigned int * Command_FIFO_CSR_ptr = NULL;

//volatile unsigned int * Mixer_Output_Enable_ptr = NULL; // uint8_t

// /dev/mem file id
int fd;

// AUDIO INPUTS
#define ADC_ALPHA 0x00
#define ADC_BETA  0x01
#define SIG_GEN_ALPHA 0x02
#define SIG_GEN_BETA  0x03

#define INPUT_COUNT 4
char AUDIO_INPUT_LIST[INPUT_COUNT] = {
	ADC_ALPHA,		// 0x00
	ADC_BETA,		// 0x01
	SIG_GEN_ALPHA,	// 0x02
	SIG_GEN_BETA	// 0x03
};

// AUDIO OUTPUTS
#define DAC_ALPHA     0x05
#define DAC_BETA 	  0x06

#define OUTPUT_COUNT 2
char AUDIO_OUTPUT_LIST[OUTPUT_COUNT] = {
	DAC_ALPHA,		// 0x05
	DAC_BETA		// 0x06
};


struct Audio_Input_t {
	char id;
	char connected;
	uint16_t volume;
	uint8_t pan_amnt;
	char mute;
	char solo;
};

struct Audio_Output_t {
	char id;
	struct Audio_Input_t * Audio_Inputs[INPUT_COUNT];
	uint16_t volume;
	uint8_t pan_amnt;
	char mute;
	char solo;
};

struct Audio_Output_t* Audio_Outputs[OUTPUT_COUNT];

// GLOBAL VARS
int serial_port;

// FUNCTION PROTOTYPES
int serial_connect();
int init_fpga_bridge();
void init_audio_interfaces();

void process_command(char* msg_buf, size_t size);

int C_Get_State();
int C_Connect(uint8_t input_intf_id, uint8_t output_intf_id);
int C_Disconnect(uint8_t input_intf, uint8_t output_intf);
int C_Mute(uint8_t input_intf, uint8_t output_intf);
int C_Unmute(uint8_t input_intf_id, uint8_t output_intf_id);
int C_Solo(uint8_t input_intf, uint8_t output_intf);
int C_Unsolo(uint8_t input_intf_id, uint8_t output_intf_id);
int C_Change_Volume(uint8_t input_intf, uint8_t output_intf, uint16_t vol);
int C_Change_Pan(uint8_t input_intf, uint8_t output_intf, uint8_t bal);
int C_Change_Gain(uint8_t input_intf_id, uint8_t output_intf_id, uint8_t pan_val);


struct Audio_Output_t* get_output_by_id(char audio_intf_id);
struct Audio_Input_t* get_input_by_id(char input_intf_id, struct Audio_Output_t* output_intf);
void print_intf_status(char audio_intf_id);
void fpga_write(uint8_t output_id, uint8_t input_id, uint16_t volume_val);

int serial_port;

// WARNING ########
//
// When sending serial messages through the command line,
// a # char must be appended to the message, or else it will
// not be read properly. Also, the unix serial terminal
// will add on # char when sending a message, so be sure to
// cut off the first char when receiving a message.

// The first response from the ARM should be discarded
// as it includes text from a default linux terminal,
// and I don't know how to disable it.

// A junk message should be sent before any other, and
// all response bytes cleared and ignored before sending
// another message.

int main(void) {
	puts("!!!Hello World!!!"); /* prints !!!Hello World!!! */

	serial_port = serial_connect();

	init_audio_interfaces();

	init_fpga_bridge();


	//print_intf_status(0x05);

	// WRITING
	//unsigned char msg[] = { 'H', 'e', 'l', 'l', 'o', '\r' };
	//write(serial_port, "Hello, world!", sizeof(msg));

	// READING
	int message_buf_i = 0;
	int message_state = 0;
	char message_buf[256];

	char read_buf[256];

	fflush(stdout);
	fflush(stdin);

	puts("INIT SUCCESSFUL");
	puts("Ready when you are.");

	// Simple serial loopback
	while(1){
		int n = read(serial_port, &read_buf, sizeof(read_buf));

		if(n > 0){
			printf("Got something: %i\n", n);
		}

		int i;
		for(i = 0; i < n; i++){
			printf("%c\n", read_buf[i]);
			if(message_state == 2){
				// Receiving message
				if(read_buf[i] == '$'){
					// Tail received, process command
					process_command(message_buf, message_buf_i);

					message_buf_i = 0;
					message_state = 0;
				} else {
					// Save char, increment
					message_buf[message_buf_i] = read_buf[i];
					message_buf_i++;
				}

			} else if(message_state == 0 && read_buf[i] == '#'){
				// First head received
				message_state = 1;
			} else if(message_state == 1 && read_buf[i] == '#'){
				// Second head received, start saving message
				message_state = 2;
			} else {
				// Second head not received, reset state
				message_state = 0;
			}
		}
	}

	// CLOSE
	close(serial_port);

	puts("Successful");
	return EXIT_SUCCESS;
}

void process_command(char* msg_buf, size_t size){
	// For the moment, we assume all commands are received without error

	puts("ENTERED PROCESS COMMAND");
	printf("GOT COMMAND: ");

	char cmd = msg_buf[0];
	char input_intf = msg_buf[1];
	char output_intf = msg_buf[2];
	int r;

	switch(cmd){
	case 0x00:
		// GET STATE
		printf("GET STATE\n");
		r = C_Get_State();
		break;

	case 0x01:
		// CONNECT
		printf("CONNECT\n");
		r = C_Connect(input_intf, output_intf);
		break;

	case 0x02:
		// DISCONNECT
		printf("DISCONNECT\n");
		r = C_Disconnect(input_intf, output_intf);
		break;

	case 0x03:
		// MUTE
		printf("MUTE\n");
		r = C_Mute(input_intf, output_intf);
		break;

	case 0x04:
		// UNMUTE
		printf("UNMUTE\n");
		r = C_Unmute(input_intf, output_intf);
		break;

	case 0x05:
		// SOLO
		printf("SOLO\n");
		r = C_Solo(input_intf, output_intf);
		break;

	case 0x06:
		// UNSOLO
		printf("UNSOLO\n");
		r = C_Unsolo(input_intf, output_intf);
		break;

	case 0x07:
		//VOLUME - 2 bytes data
	{
		printf("VOLUME\n");
		uint16_t vol = (msg_buf[3] << 8) | msg_buf[4];
		r = C_Change_Volume(input_intf, output_intf, vol);
		break;
	}

	case 0x08:
		// PANNING - 1 bytes data
	{
		printf("PANNING\n");
		uint8_t bal = msg_buf[3];
		r = C_Change_Pan(input_intf, output_intf, bal);
		break;
	}

	case 0x09:
		// INPUT GAIN - 1 bytes data (MIC INPUT, 6.35 INPUT)
	{
		printf("GAIN\n");
		uint8_t gain = msg_buf[3];
		r = C_Change_Gain(input_intf, output_intf, gain);
		break;
	}

	default:
		// INVALID COMMAND
		printf("INVALID\n");
		r = -1;
		break;

	}


	// ERROR HANDLING
	char * response;
	if(r == 0){
		puts("OK");
		response = "OK";
	} else if(r == -1){
		puts("ERROR");
		response = "ERROR";
	}

	char r_buf[256];
	int r_size = sprintf(r_buf, "##%s$", response);

	printf("Sending %i bytes\n", r_size);
	printf("Sent: %.*s\n", r_size, r_buf);

	write(serial_port, r_buf, r_size);
}

int C_Get_State(){
	return 0;
}

void update_interface(uint8_t output_intf_id){
	// It would be more efficient to do it for only the parts changed, but this is a simpler method.
	// TODO - implement panning - requires FPGA code update
	//uint16_t output_volume;
	//uint32_t fpga_cmd;
	char output_has_solo = 0;
	char input_has_solo = 0;
	int i;

	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);

	// Check if a output has solo enabled
		// If true, outputs without solo have volume = 0

		// else, calculate gain (volume)

	for(i = 0; i < OUTPUT_COUNT; i++){
		if(Audio_Outputs[i]->solo){
			output_has_solo = 1;
			break;
		}
	}

	if(output_has_solo){
		for(i = 0; i < OUTPUT_COUNT; i++){
			if(Audio_Outputs[i]->solo && output_intf->Audio_Inputs[i]->connected){
				fpga_write(Audio_Outputs[i]->id, Audio_Outputs[i]->id, Audio_Outputs[i]->volume);
			} else {
				fpga_write(Audio_Outputs[i]->id, Audio_Outputs[i]->id, 0);
			}
		}
	} else {
		for(i = 0; i < OUTPUT_COUNT; i++){
			if(Audio_Outputs[i]->mute || !output_intf->Audio_Inputs[i]->connected){
				fpga_write(Audio_Outputs[i]->id, Audio_Outputs[i]->id, 0);
			} else {
				fpga_write(Audio_Outputs[i]->id, Audio_Outputs[i]->id, Audio_Outputs[i]->volume);
			}
		}
	}

	// For all inputs -
		// Check for other soloed inputs on same output
			// if so, input gain = 0
	for(i = 0; i < INPUT_COUNT; i++){
		if(output_intf->Audio_Inputs[i]->solo){
			input_has_solo = 1;
			break;
		}
	}

	if(input_has_solo){
		for(i = 0; i < INPUT_COUNT; i++){
			if(output_intf->Audio_Inputs[i]->solo && output_intf->Audio_Inputs[i]->connected){
				fpga_write(output_intf->id, output_intf->Audio_Inputs[i]->id, output_intf->Audio_Inputs[i]->volume);
			} else {
				fpga_write(output_intf->id, output_intf->Audio_Inputs[i]->id, 0);
			}
		}
	} else {
		for(i = 0; i < INPUT_COUNT; i++){
			if(output_intf->Audio_Inputs[i]->mute || !output_intf->Audio_Inputs[i]->connected){
				fpga_write(output_intf->id, output_intf->Audio_Inputs[i]->id, 0);
			} else {
				fpga_write(output_intf->id, output_intf->Audio_Inputs[i]->id, output_intf->Audio_Inputs[i]->volume);
			}
		}
	}

}

int C_Connect(uint8_t input_intf_id, uint8_t output_intf_id){
	// Connect input to output by setting gain of input to 1, respective of output

	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);

	input_intf->connected = 1; // 0 dB of gain

	update_interface(output_intf_id);

	return 0;
}

int C_Disconnect(uint8_t input_intf_id, uint8_t output_intf_id){
	// Disconnect input from output by setting gain of input to 0, respective of output
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);

	input_intf->connected = 0; // -inf dB of gain

	update_interface(output_intf_id);

	return 0;
}

int C_Mute(uint8_t input_intf_id, uint8_t output_intf_id){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->mute = 1;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->mute = 1;

	}

	update_interface(output_intf_id);

	return 0;
}

int C_Unmute(uint8_t input_intf_id, uint8_t output_intf_id){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->mute = 0;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->mute = 0;

	}

	update_interface(output_intf_id);

	return 0;
}

int C_Solo(uint8_t input_intf_id, uint8_t output_intf_id){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->solo = 1;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->solo = 1;

	}

	update_interface(output_intf_id);
	return 0;
}

int C_Unsolo(uint8_t input_intf_id, uint8_t output_intf_id){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->solo = 0;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->solo = 0;

	}

	update_interface(output_intf_id);
	return 0;
}

int C_Change_Volume(uint8_t input_intf_id, uint8_t output_intf_id, uint16_t vol_val){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->volume = vol_val;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->volume = vol_val;

	}

	update_interface(output_intf_id);
	return 0;
}

int C_Change_Pan(uint8_t input_intf_id, uint8_t output_intf_id, uint8_t pan_val){
	struct Audio_Output_t* output_intf = get_output_by_id(output_intf_id);
	if(input_intf_id == output_intf_id){
		// Mute output itself
		output_intf->pan_amnt = pan_val;
	} else {
		// Mute input
		struct Audio_Input_t* input_intf = get_input_by_id(input_intf_id, output_intf);
		input_intf->pan_amnt = pan_val;

	}

	update_interface(output_intf_id);
	return 0;
}

int C_Change_Gain(uint8_t input_intf_id, uint8_t output_intf_id, uint8_t pan_val){
	// TODO - Gain setting, not needed until full mixer
	// FPGA needs additional FIFO buffer to handle gain values
	return 0;
}

void fpga_write(uint8_t output_id, uint8_t input_id, uint16_t volume_val){
	// TODO - Send the command to the FIFO interface
	uint32_t fpga_cmd = (output_id << 24) | (input_id << 16) | volume_val;

	printf("0x%02x-0x%02x-0x%04x - ", output_id, input_id, volume_val);

	int i;
	int int_size = 32;
	for(i = 0; i <= (int_size-1); i++){
		fpga_cmd & (1 << ((int_size-1)-i)) ? printf("1") : printf("0");
		if((i+1) % 8 == 0 && i != (int_size-1)){
			printf("-");
		}
	}

	printf("\n");

	(*Command_FIFO_IN_ptr) = fpga_cmd;
	while((*Command_FIFO_CSR_ptr) != 0);

	return;
}

void init_audio_interfaces(){
	int output_i;
	int input_i;

	for(output_i = 0; output_i < OUTPUT_COUNT; output_i++){
		struct Audio_Output_t * audio_out_intf;
		audio_out_intf = (struct Audio_Output_t*) malloc(sizeof(struct Audio_Output_t));

		audio_out_intf->id = AUDIO_OUTPUT_LIST[output_i];
		audio_out_intf->volume = 0x0000; // Disconnected
		audio_out_intf->pan_amnt = 0x80; // Center
		audio_out_intf->mute = 0;
		audio_out_intf->solo = 0;

		for(input_i = 0; input_i < INPUT_COUNT; input_i++){
			struct Audio_Input_t * audio_in_intf;
			audio_in_intf = (struct Audio_Input_t*) malloc(sizeof(struct Audio_Input_t));

			audio_in_intf->id = AUDIO_INPUT_LIST[input_i];
			audio_in_intf->connected = 0;
			audio_in_intf->volume = 0x0000; // Disconnected
			audio_in_intf->pan_amnt = 0x80; // Center
			audio_in_intf->mute = 0;
			audio_in_intf->solo = 0;

			audio_out_intf->Audio_Inputs[input_i] = audio_in_intf;

		}

	Audio_Outputs[output_i] = audio_out_intf;

	}

}

struct Audio_Output_t* get_output_by_id(char output_intf_id){
	int i;
	for(i = 0; i < OUTPUT_COUNT; i++){
		if(Audio_Outputs[i]->id == output_intf_id){
			return Audio_Outputs[i];
		}
	}

	return NULL;

}

struct Audio_Input_t* get_input_by_id(char input_intf_id, struct Audio_Output_t* output_intf){
	int i;
	for(i = 0; i < INPUT_COUNT; i++){
		if(output_intf->Audio_Inputs[i]->id == input_intf_id){
			return output_intf->Audio_Inputs[i];
		}
	}

	return NULL;
}

void print_intf_status(char audio_intf_id){
	struct Audio_Output_t* audio_intf = get_output_by_id(audio_intf_id);

	if(audio_intf == NULL){
		printf("Audio Output with ID 0x%02x not found!", audio_intf_id);
		return;
	}

	printf("OUTPUT ID: 0x%02x\n", audio_intf->id);
	printf("Volume: 0x%04x\n", audio_intf->volume);
	printf("Pan: 0x%02x\n", audio_intf->pan_amnt);
	printf("Mute: %i\n", audio_intf->mute);
	printf("Solo: %i\n", audio_intf->solo);

	int i;
	for(i = 0; i < INPUT_COUNT; i++){
		printf("\n");
		printf("INPUT ID: 0x%02x\n", audio_intf->Audio_Inputs[i]->id);
		printf("Volume: 0x%04x\n", audio_intf->Audio_Inputs[i]->volume);
		printf("Pan: 0x%02x\n", audio_intf->Audio_Inputs[i]->pan_amnt);
		printf("Mute: %i\n", audio_intf->Audio_Inputs[i]->mute);
		printf("Solo: %i\n", audio_intf->Audio_Inputs[i]->solo);
	}

	printf("\n");

}

int serial_connect(){
	int serial_port = open("/dev/ttyS0", O_RDWR | O_NDELAY);

	if (serial_port < 0){

		printf("Error %i from open: %s\n", errno, strerror(errno));
	}

	struct termios tty;

	if(tcgetattr(serial_port, &tty) != 0){
		printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
	}

	tty.c_cflag &= ~PARENB; // Clear partiy bit
	tty.c_cflag &= ~CSTOPB; // One stop bit
	tty.c_cflag |= CS8; // 8 bits per byte
	tty.c_cflag &= ~CRTSCTS; // Disable RTS/CTS hardware float control
	tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines

	tty.c_lflag &= ~ICANON; // Disable canonical mode
	tty.c_lflag &= ~ECHO;	// Disable echo
	tty.c_lflag &= ~ECHOE;  // Disable erasure
	tty.c_lflag &= ~ECHONL; // Disable new-line echo
	tty.c_lflag &= ~ISIG;	// Disable interpretation of INTR, QUIT, and SUSP

	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
	tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL); // Diable any special handling of received bytes

	tty.c_oflag &= ~OPOST;
	tty.c_oflag &= ~ONLCR;

	tty.c_cc[VTIME] = 0; // No blocking
	tty.c_cc[VMIN] = 0;

	cfsetispeed(&tty, B115200);
	cfsetospeed(&tty, B115200);

	if(tcsetattr(serial_port, TCSANOW, &tty) != 0){
		printf("Error %i from tcsetattr: %s\n", errno, strerror(errno));
	}

	return serial_port;
}

int map_addresses()
{
	printf("Script will hang until FPGA is programmed. Please initalize FPGA now.\n");

	// === get FPGA addresses ==================
	// Open /dev/mem
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) 	{
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
	printf("/dev/mem open\n");

	//============================================
	// get virtual addr that maps to physical
	// for light weight AXI bus
	h2p_lw_virtual_base = mmap( NULL, FPGA_LW_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_LW_BASE );
	if( h2p_lw_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap1() failed...\n" );
		close( fd );
		return(1);
	}

	// ===========================================
	// get virtual address for
	// AXI bus addr
	h2p_virtual_base = mmap( NULL, FPGA_AXI_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_AXI_BASE);
	if( h2p_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap3() failed...\n" );
		close( fd );
		return(1);
	}

	// Map all pointers to respective positions in memory
	//Ethernet_FIFO_OUT_ptr = 	(unsigned int *)(h2p_virtual_base + Ethernet_FIFO_OUT_OFFSET);
	//Ethernet_FIFO_CSR_ptr = 	(unsigned int *)(h2p_lw_virtual_base + Ethernet_FIFO_CSR_OFFSET);

	Command_FIFO_IN_ptr = 		(unsigned int *)(h2p_virtual_base + Command_FIFO_IN_OFFSET);
	Command_FIFO_CSR_ptr = 		(unsigned int *)(h2p_lw_virtual_base + Command_FIFO_CSR_OFFSET);

	//Mixer_Output_Enable_ptr = 	(unsigned int *)(h2p_lw_virtual_base + Output_Enable_OFFSET);

	return(0);
}
