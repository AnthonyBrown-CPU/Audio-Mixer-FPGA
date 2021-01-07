using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.IO.Ports;
using System.Threading;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;

namespace Proto_Gui
{
    public partial class Form1 : Form
    {
        private SerialPort _serialPort;
        private byte[] txBuffer = new byte[100];
        
        //byte[] byteHeader = { 0x23, 0x23 };
        //byte[] byteFooter = { 0x24 };

        string MSG_HEADER = "###";
        string MSG_FOOTER = "$";

        byte C_GET_STATE =  0x00;
        byte C_CONNECT =    0x01;
        byte C_DISCONNECT = 0x02;
        byte C_MUTE =       0x03;
        byte C_UNMUTE =     0x04;
        byte C_SOLO =       0x05;
        byte C_UNSOLO =     0x06;
        byte C_VOLUME =     0x07;
        byte C_PAN =        0x08;
        byte C_GAIN =       0x09;


        //byte[] getState = { 0x00 };

        //byte[] byteGetState = { 0x00 };
        //byte[] byteConnect = { 0x01 };
        //byte[] byteDisconnect = { 0x02 };
        //byte[] byteMute = { 0x03 };
        //byte[] byteUnmute = { 0x04 };
        //byte[] byteSolo = { 0x05 };
        //byte[] byteUnsolo = { 0x06 };
        //byte[] byteVolume = { 0x07 };
        //byte[] bytePan = { 0x08 };
        //byte[] byteGain = { 0x09 };

        //byte[] ADC_ALPHA = { 0x00 };
        //byte[] ADC_BETA = { 0x01 };
        //byte[] SIG_GEN_ALPHA = { 0x02 };
        //byte[] SIG_GEN_BETA = { 0x03 };

        // INPUTS
        byte OUTPUT_SPECIFIER = 0x00; // Refers to the output
        byte ADC_ALPHA =        0x01;
        byte ADC_BETA =         0x02;
        byte SIG_GEN_ALPHA =    0x03;
        byte SIG_GEN_BETA =     0x04;
        byte ETHERNET_IN =      0x05;
        byte BLUETOOTH_IN =     0x06;

        //byte[] DAC_ALPHA = { 0x05 };
        //byte[] DAC_BETA = { 0x06 };

        // OUTPUTS
        byte DAC_ALPHA =     0x01;
        byte DAC_BETA =      0x02;
        byte ETHERNET_OUT =  0x03;
        byte BLUETOOTH_OUT = 0x04;

        int MAX_VOLUME_VAL = 300;

        public Form1()
        {
            InitializeComponent();
            o1i1Value.Text = MAX_VOLUME_VAL.ToString();
            o1i2Value.Text = MAX_VOLUME_VAL.ToString();
            o1MValue.Text =  MAX_VOLUME_VAL.ToString();
            o2i1Value.Text = MAX_VOLUME_VAL.ToString();
            o2i2Value.Text = MAX_VOLUME_VAL.ToString();
            o2MValue.Text =  MAX_VOLUME_VAL.ToString();

            string[] ports = SerialPort.GetPortNames();
            portComboBox.Items.AddRange(ports);         
            if (ports != null)
                portComboBox.SelectedIndex = 0;  

            string[] baudItems = new string[] { "300", "600", "1200", "2400", "4800", "9600", "57600", "115200" };
            baudRateComboBox.DataSource = baudItems;
            baudRateComboBox.SelectedIndex = 6;

            _serialPort = new SerialPort();
        }

        // CONCATINATE FUNCTION FOR COMMANDS WITH DATA

        //public byte[] concatDataByte(byte[] commandByte, byte[] inputByte, byte[] outputByte, byte[] dataByte)
        //{
        //  List<byte> list1 = new List<byte>(byteHeader);
        //  List<byte> list2 = new List<byte>(commandByte);
        //  List<byte> list3 = new List<byte>(inputByte);
        //  List<byte> list4 = new List<byte>(outputByte);
        //  List<byte> list5 = new List<byte>(dataByte);
        //  List<byte> list6 = new List<byte>(byteFooter);
        //  list1.AddRange(list2);
        //  list1.AddRange(list3);
        //  list1.AddRange(list4);
        //  list1.AddRange(list5);
        //  list1.AddRange(list6);
        //  byte[] tempByte = list1.ToArray();
        //
        //  return tempByte;
        //}

        // ** CONVERTS ARRAY OF BYTES e.g. { 0x33, 0xAB, 0xCD } TO HEXADECIMAL STRING e.g. "33ABCD"
        // COMMANDS NEED TO BE CONVERTED BEFORE SENT TO MIXER
        // COMMANDS DO NOT INCLUDE THE HEADER AND FOOTER
        public static string ByteArrayToString(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

        // CONCATINATE FUNCTION FOR COMMANDS
        private void sendCommand(byte COMMAND, byte OUTPUT_ID, byte INPUT_ID, byte[] VALUE = null)
        {
            // I think this works, I haven't tested it.
            byte[] cmd_packet = {COMMAND, OUTPUT_ID, INPUT_ID};

            if(VALUE != null)
                cmd_packet = cmd_packet.Concat(VALUE).ToArray();

            string cmd_msg = MSG_HEADER + ByteArrayToString(cmd_packet) + MSG_FOOTER;

            // Send the command to the mixer
            if (_serialPort.IsOpen)
                _serialPort.Write(cmd_msg.ToCharArray(), 0, cmd_msg.Length);
            
            Console.WriteLine("SENT " + cmd_msg + " TO MIXER");
        }


        //public byte[] concatByte(byte[] commandByte, byte[] inputByte, byte[] outputByte)
        //{
        //    List<byte> list1 = new List<byte>(byteHeader);
        //    List<byte> list2 = new List<byte>(commandByte);
        //    List<byte> list3 = new List<byte>(inputByte);
        //    List<byte> list4 = new List<byte>(outputByte);
        //    List<byte> list5 = new List<byte>(byteFooter);
        //    list1.AddRange(list2);
        //    list1.AddRange(list3);
        //    list1.AddRange(list4);
        //    list1.AddRange(list5);
        //    byte[] tempByte = list1.ToArray();
        //
        //    return tempByte;
        //}

        // Fixed point data conversion

        /* public byte[] fixedPointConvert(int ogNumber)
        {
            double calculateFixed1 = Convert.ToDouble(ogNumber);
            calculateFixed1 = calculateFixed1 / 100;
            double calculateFixed2 = Math.Pow(2, 12);
            calculateFixed1 = (calculateFixed1 * calculateFixed2);
            calculateFixed1 = Math.Round(calculateFixed1);
            byte[] tempByte = BitConverter.GetBytes(calculateFixed1);
            if (tempByte.Length < 2)
            {
                List<byte> list1 = new List<byte>(0x00);
                List<byte> list2 = new List<byte>(tempByte);
                list1.AddRange(list2);
                tempByte = list1.ToArray();
            }
            else if (tempByte.Length > 2)
            {
                List<byte> list3 = new List<byte>(tempByte);
                list3.RemoveAt(0);
                tempByte = list3.ToArray();
            }
            return tempByte;
        } */
		
		public static byte[] fixedPointConvert(int ogNumber)
		{
			double calculateFixed1 = Convert.ToDouble(ogNumber);
			calculateFixed1 = calculateFixed1 / 100; // Convert from percentage to integer
			double calculateFixed2 = Math.Pow(2, 12);
			calculateFixed1 = (calculateFixed1 * calculateFixed2); // Floating point left shift 12 places
			calculateFixed1 = Math.Round(calculateFixed1); // Remove any decimal component
			
			// We won't care about overflow or truncation atm
			ushort fixedEquiv = Convert.ToUInt16(calculateFixed1);
			
			// Because ushort is 2 bytes, BitConverter will always return 2 bytes.
			byte[] tempByte = BitConverter.GetBytes(fixedEquiv);
			
			// Convert from le to be (Little Endian to Big Endian)
			Array.Reverse(tempByte);
			
			return tempByte;
		}

        // CLOSE PROGRAM

        private void exitButton_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }



        //STATUS WINDOW AND SERIAL PORTS

        private void serialOpenButton_Click(object sender, EventArgs e)
        {
            if (_serialPort.IsOpen == true)
            {
                _serialPort.Close();
                statusTextBox.AppendText("Serial port closed \r\n");
                serialRadioButton.Checked = false;
            }
            else
            {

                _serialPort.PortName = portComboBox.SelectedItem.ToString();
                _serialPort.BaudRate = int.Parse(baudRateComboBox.SelectedItem.ToString());
                _serialPort.Parity = Parity.None;
                _serialPort.DataBits = 8;
                _serialPort.StopBits = StopBits.One;
                _serialPort.Handshake = Handshake.None;

                try
                {
                    _serialPort.Open();

                    if (_serialPort.IsOpen)
                    {
                        statusTextBox.AppendText("Serial port opened\r\n");
                        statusTextBox.AppendText(portComboBox.SelectedItem.ToString());
                        statusTextBox.AppendText(" ");
                        statusTextBox.AppendText(baudRateComboBox.SelectedItem.ToString());
                        statusTextBox.AppendText(" baud, 8 data bits, 1 stop bit\r\n");
                        serialRadioButton.Checked = true;
                    }
                }
                catch (Exception)
                {

                    statusTextBox.AppendText("Error cannot open serial port \r\n");
                }
            }
        }


        // TRANSMIT PING FOR TROUBLESHOOTING

        private void transmitButton_Click(object sender, EventArgs e)
        {
            statusTextBox.AppendText("Communication test: \r\n");
            sendCommand(C_GET_STATE, DAC_ALPHA, ADC_ALPHA); // I need to add a new command for ping purposes only
            // ###OK$ should appear in the msg box

            //List<byte> list1 = new List<byte>(byteHeader);
            //List<byte> list2 = new List<byte>(0x00);
            //List<byte> list3 = new List<byte>(byteFooter);
            //list1.AddRange(list2);
            //list1.AddRange(list3);
            //byte[] tempByte2 = list1.ToArray();

            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
        }



        // RECEIVER CHECKS SERIAL PORT FOR BYTES TO READ

        private void serialTimer_Tick(object sender, EventArgs e)
        {           
            if (_serialPort.IsOpen)
            { 
                 int bytes = _serialPort.BytesToRead;
                 byte[] buffer = new byte[bytes];
                 _serialPort.Read(buffer, 0, bytes);
                 string rxString = Encoding.ASCII.GetString(buffer);
                 rxString = (rxString.Trim(new Char[] { '#', '$' }));
                 dataRX.Text = rxString;
                 statusTextBox.AppendText(rxString);
            }
        }
        



        // VOLUME COMMANDS

        private void o1Slide1_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo1i1 = MAX_VOLUME_VAL - o1Slide1.Value;
            o1i1Value.Text = tempo1i1.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, ADC_ALPHA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_ALPHA, ADC_ALPHA, fixedPointConvert(tempo1i1));
        }

        private void o1Slide2_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo1i2 = MAX_VOLUME_VAL - o1Slide2.Value;
            o1i2Value.Text = tempo1i2.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, ADC_BETA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_ALPHA, ADC_BETA, fixedPointConvert(tempo1i2));
        }

        private void o1SlideM_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo1M = MAX_VOLUME_VAL - o1SlideM.Value;
            o1MValue.Text = tempo1M.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, DAC_ALPHA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_ALPHA, OUTPUT_SPECIFIER, fixedPointConvert(tempo1M));
        }

        private void o2Slide1_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo2i1 = MAX_VOLUME_VAL - o2Slide1.Value;
            o2i1Value.Text = tempo2i1.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, ADC_ALPHA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_BETA, ADC_ALPHA, fixedPointConvert(tempo2i1));
        }

        private void o2Slide2_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo2i2 = MAX_VOLUME_VAL - o2Slide2.Value;
            o2i2Value.Text = tempo2i2.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, ADC_BETA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_BETA, ADC_BETA, fixedPointConvert(tempo2i2));
        }

        private void o2SlideM_Scroll(object sender, ScrollEventArgs e)
        {
            int tempo2M = MAX_VOLUME_VAL - o1SlideM.Value;
            o2MValue.Text = tempo2M.ToString();
            //byte[] tempByte2 = concatDataByte(byteVolume, DAC_BETA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_VOLUME, DAC_BETA, OUTPUT_SPECIFIER, fixedPointConvert(tempo2M));
        }


        //PAN COMMANDS

        private void o1i1Pan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o1i1Pan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, ADC_ALPHA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_ALPHA, ADC_ALPHA, pan_value);
        }

        private void o1i2Pan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o1i2Pan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, ADC_BETA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_ALPHA, ADC_BETA, pan_value);
        }

        private void o1MPan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o1MPan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, DAC_ALPHA, DAC_ALPHA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_ALPHA, OUTPUT_SPECIFIER, pan_value);
        }

        private void o2i1Pan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o2i1Pan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, ADC_ALPHA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_BETA, ADC_ALPHA, pan_value);
        }

        private void o2i2Pan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o2i2Pan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, ADC_BETA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_BETA, ADC_BETA, pan_value);
        }

        private void o2MPan_Scroll(object sender, ScrollEventArgs e)
        {
            byte[] pan_value = { Convert.ToByte(o2MPan.Value) };
            //byte[] tempByte2 = concatDataByte(bytePan, DAC_BETA, DAC_BETA, tempByte);
            //_serialPort.Write(tempByte2, 0, tempByte2.Length);
            sendCommand(C_PAN, DAC_BETA, OUTPUT_SPECIFIER, pan_value);
        }


        //MUTE COMMANDS


        private void o1i1Mute_Click(object sender, EventArgs e)
        { 
            //byte[] tempByte = concatByte(byteMute, ADC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_ALPHA, ADC_ALPHA);
        }

        private void o1i2Mute_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteMute, ADC_BETA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_ALPHA, ADC_BETA);
        }

        private void o1MMute_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteMute, DAC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_ALPHA, OUTPUT_SPECIFIER);
        }

        private void o2i1Mute_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteMute, ADC_ALPHA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_BETA, ADC_ALPHA);
        }

        private void o2i2Mute_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteMute, ADC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_BETA, ADC_BETA);
        }

        private void o2MMute_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteMute, DAC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_MUTE, DAC_BETA, OUTPUT_SPECIFIER);
        }

        //SOLO COMMANDS

        private void o1i1Solo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, ADC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_ALPHA, ADC_ALPHA);
        }

        private void o1i2Solo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, ADC_BETA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_ALPHA, ADC_BETA);
        }

        private void o1MSolo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, DAC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_ALPHA, OUTPUT_SPECIFIER);
        }

        private void o2i1Solo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, ADC_ALPHA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_BETA, ADC_ALPHA);
        }

        private void o2i2Solo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, ADC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_BETA, ADC_BETA);
        }

        private void o2MSolo_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteSolo, DAC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_SOLO, DAC_BETA, OUTPUT_SPECIFIER);
        }


        //CONNECT COMMANDS


        private void o1i1Connect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte1 = concatByte(byteConnect, ADC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte1, 0, tempByte1.Length);
            sendCommand(C_CONNECT, DAC_ALPHA, ADC_ALPHA);

            int vol_val = MAX_VOLUME_VAL - o1Slide1.Value;
            o2i1Value.Text = vol_val.ToString();
            //byte[] tempByte2 = BitConverter.GetBytes(tempo2i1);
            //byte[] tempByte3 = concatDataByte(byteVolume, ADC_ALPHA, DAC_ALPHA, tempByte2);
            //_serialPort.Write(tempByte3, 0, tempByte3.Length);
            sendCommand(C_VOLUME, DAC_ALPHA, ADC_ALPHA, fixedPointConvert(vol_val));



        }

        private void o1i2Connect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte1 = concatByte(byteConnect, ADC_BETA, DAC_ALPHA);
            //_serialPort.Write(tempByte1, 0, tempByte1.Length);
            sendCommand(C_CONNECT, DAC_ALPHA, ADC_BETA);

            int vol_val = MAX_VOLUME_VAL - o1Slide2.Value;
            o2i2Value.Text = vol_val.ToString();
            //byte[] tempByte2 = BitConverter.GetBytes(tempo1i2);
            //byte[] tempByte3 = concatDataByte(byteVolume, ADC_BETA, DAC_ALPHA, tempByte2);
            //_serialPort.Write(tempByte3, 0, tempByte3.Length);
            sendCommand(C_VOLUME, DAC_ALPHA, ADC_BETA, fixedPointConvert(vol_val));

        }

        // Outputs cannot be connected to themselves
        //private void o1MConnect_Click(object sender, EventArgs e)
        //{
        //    byte[] tempByte1 = concatByte(byteConnect, DAC_ALPHA, DAC_ALPHA);
        //    _serialPort.Write(tempByte1, 0, tempByte1.Length);
        //
        //    int tempo1M = 255 - o1SlideM.Value;
        //    o2MValue.Text = tempo1M.ToString();
        //    byte[] tempByte2 = BitConverter.GetBytes(tempo1M);
        //    byte[] tempByte3 = concatDataByte(byteVolume, DAC_ALPHA, DAC_ALPHA, tempByte2);
        //    _serialPort.Write(tempByte3, 0, tempByte3.Length);
        //}

        private void o2i1Connect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte1 = concatByte(byteConnect, ADC_ALPHA, DAC_BETA);
            //_serialPort.Write(tempByte1, 0, tempByte1.Length);
            sendCommand(C_CONNECT, DAC_BETA, ADC_ALPHA);

            int vol_val = MAX_VOLUME_VAL - o2Slide1.Value;
            o2i1Value.Text = vol_val.ToString();
            //byte[] tempByte2 = BitConverter.GetBytes(tempo2i1);
            //byte[] tempByte3 = concatDataByte(byteVolume, ADC_ALPHA, DAC_BETA, tempByte2);
            //_serialPort.Write(tempByte3, 0, tempByte3.Length);
            sendCommand(C_VOLUME, DAC_BETA, ADC_ALPHA, fixedPointConvert(vol_val));
        }

        private void o2i2Connect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte1 = concatByte(byteConnect, ADC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte1, 0, tempByte1.Length);
            sendCommand(C_CONNECT, DAC_BETA, ADC_BETA);

            int vol_val = MAX_VOLUME_VAL - o2Slide2.Value;
            o2i2Value.Text = vol_val.ToString();
            //byte[] tempByte2 = BitConverter.GetBytes(tempo2i2);
            //byte[] tempByte3 = concatDataByte(byteVolume, ADC_BETA, DAC_BETA, tempByte2);
            //_serialPort.Write(tempByte3, 0, tempByte3.Length);
            sendCommand(C_VOLUME, DAC_BETA, ADC_BETA, fixedPointConvert(vol_val));
        }

        // Outputs cannot be connected to themselves
        //private void o2MConnect_Click(object sender, EventArgs e)
        //{
        //    byte[] tempByte1 = concatByte(byteConnect, DAC_BETA, DAC_BETA);
        //    _serialPort.Write(tempByte1, 0, tempByte1.Length);
        //
        //    int tempo2M = 255 - o2SlideM.Value;
        //    o2MValue.Text = tempo2M.ToString();
        //    byte[] tempByte2 = BitConverter.GetBytes(tempo2M);
        //    byte[] tempByte3 = concatDataByte(byteVolume, DAC_BETA, DAC_BETA, tempByte2);
        //    _serialPort.Write(tempByte3, 0, tempByte3.Length);
        //}


        //DISCONNECT COMMANDS

        private void o1i1Disconnect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteDisconnect, ADC_ALPHA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_DISCONNECT, DAC_ALPHA, ADC_ALPHA);
        }

        private void o1i2Disconnect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteDisconnect, ADC_BETA, DAC_ALPHA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_DISCONNECT, DAC_ALPHA, ADC_ALPHA);
        }

        // Outputs cannot be disconnected from themseleves
        //private void o1MDisconnect_Click(object sender, EventArgs e)
        //{
        //    byte[] tempByte = concatByte(byteDisconnect, DAC_ALPHA, DAC_ALPHA);
        //    _serialPort.Write(tempByte, 0, tempByte.Length);
        //}

        private void o2i1Disconnect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteDisconnect, ADC_ALPHA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_DISCONNECT, DAC_BETA, ADC_ALPHA);
        }

        private void o2i2Disconnect_Click(object sender, EventArgs e)
        {
            //byte[] tempByte = concatByte(byteDisconnect, ADC_BETA, DAC_BETA);
            //_serialPort.Write(tempByte, 0, tempByte.Length);
            sendCommand(C_DISCONNECT, DAC_BETA, ADC_BETA);
        }

        //private void o2MDisconnect_Click(object sender, EventArgs e)
        //{
        //    byte[] tempByte = concatByte(byteDisconnect, DAC_BETA, DAC_BETA);
        //    _serialPort.Write(tempByte, 0, tempByte.Length);
        //}

    }
}
