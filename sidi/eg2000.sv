//-------------------------------------------------------------------------------------------------
// EACA EG2000 Colour Genie implementation for SiDi by Kyp
// https://github.com/Kyp069/eg2000
//-------------------------------------------------------------------------------------------------
// Z80 chip module implementation by Sorgelig
// https://github.com/sorgelig/ZX_Spectrum-128K_MIST
//-------------------------------------------------------------------------------------------------
// UM6845R chip module implementation by Sorgelig
// https://github.com/sorgelig/Amstrad_MiST
//-------------------------------------------------------------------------------------------------
// AY chip module implementation by Jotego
// https://github.com/jotego/jt49
//-------------------------------------------------------------------------------------------------
module eg2000
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock27,

	output wire       led,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       ear,
	output wire[ 1:0] audio,

	output wire       ramCk,
	output wire       ramCe,
	output wire       ramCs,
	output wire       ramWe,
	output wire       ramRas,
	output wire       ramCas,
	output wire[ 1:0] ramDqm,
	inout  wire[15:0] ramDQ,
	output wire[ 1:0] ramBA,
	output wire[12:0] ramA,

	input  wire       cfgD0,
	input  wire       spiCk,
	input  wire       spiS2,
	input  wire       spiS3,
	input  wire       spiDi,
	output wire       spiDo
);
//-------------------------------------------------------------------------------------------------

clock Clock
(
	.inclk0 (clock27),
	.c0     (clock  )  // 35.468 MHz
);

//-------------------------------------------------------------------------------------------------

reg[7:0] pw;
wire power = pw[7] & ~status[0];
always @(posedge clock) if(!power) pw <= pw+1'd1;

//-------------------------------------------------------------------------------------------------

wire tape = ~ear;

wire[3:0] color;

glue Glue
(
	.clock  (clock  ),
	.power  (power  ),
	.boot   (boot   ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.pixel  (pixel  ),
	.color  (color  ),
	.tape   (tape   ),
	.sound  (sound  ),
	.ps2    (ps2    ),
	.ramCk  (ramCk  ),
	.ramCe  (ramCe  ),
	.ramCs  (ramCs  ),
	.ramWe  (ramWe  ),
	.ramRas (ramRas ),
	.ramCas (ramCas ),
	.ramDqm (ramDqm ),
	.ramDQ  (ramDQ  ),
	.ramBA  (ramBA  ),
	.ramA   (ramA   )
);

//-------------------------------------------------------------------------------------------------

reg[17:0] palette[15:0];
initial begin
	palette[15] = 18'b111111_111111_111111; // FF FF FF // 16 // white
	palette[14] = 18'b100110_001000_111111; // 98 20 FF //  8 // magenta
	palette[13] = 18'b000111_110001_100011; // 1F C4 8C // 14 // turquise
	palette[12] = 18'b100011_100011_100011; // 8C 8C 8C // 13 // grey
	palette[11] = 18'b100010_011001_111111; // 8A 67 FF // 12 // violet
	palette[10] = 18'b110001_010011_111111; // C7 4E FF // 15 // pink
	palette[ 9] = 18'b101111_110111_111111; // BC DF FF //  9 // light blue
	palette[ 8] = 18'b001011_010100_111111; // 2F 53 FF //  8 // blue
	palette[ 7] = 18'b111010_111111_001001; // EA FF 27 // 11 // yellow/green
	palette[ 6] = 18'b111010_011011_001010; // EB 6F 2B //  5 // orange
	palette[ 5] = 18'b101010_111111_010010; // AB FF 4A //  2 // green
	palette[ 4] = 18'b111111_111100_001111; // FF F2 3D //  4 // yellow
	palette[ 3] = 18'b111010_111010_111010; // EA EA EA //  1 // light grey
	palette[ 2] = 18'b110010_001001_010111; // CB 26 5E //  3 // red
	palette[ 1] = 18'b011011_111111_111010; // 7C FF EA //  7 // cyan
	palette[ 0] = 18'b010111_010111_010111; // 5E 5E 5E // 10 // dark grey
end

wire[17:0] rgbQ = pixel ? palette[color] : 1'd0;

//-------------------------------------------------------------------------------------------------

assign audio = {2{sound}};

//-------------------------------------------------------------------------------------------------

assign led = tape;

//-------------------------------------------------------------------------------------------------

reg scandoubler_toggle;
reg bootd;
always @(posedge clock) begin bootd <= boot; if(!boot && bootd) scandoubler_toggle <= ~scandoubler_toggle; end

localparam CONF_STR =
{
	"EG2000;;",
	"T0,Reset;",
	"O12,Scanlines,None,25%,50%,75%;",
	"V,v1.0"
};

wire[31:0] status;
wire[ 1:0] ps2;

user_io #(.STRLEN(($size(CONF_STR)>>3))) userIo
( 
	.conf_str    (CONF_STR ),
	.clk_sys     (clock    ),
	.SPI_CLK     (spiCk    ),
	.SPI_SS_IO   (cfgD0    ),
	.SPI_MISO    (spiDo    ),
	.SPI_MOSI    (spiDi    ),
	.status      (status   ),
	.ps2_kbd_clk (ps2[0]   ),
	.ps2_kbd_data(ps2[1]   ),
	.scandoubler_disable(scandoubler_disable)
);

mist_video mistVideo
(
	.clk_sys   (clock      ),
	.SPI_SCK   (spiCk      ),
	.SPI_DI    (spiDi      ),
	.SPI_SS3   (spiS3      ),
	.scanlines (status[2:1]),
	.ce_divider(1'b0       ),
	.scandoubler_disable(scandoubler_disable^scandoubler_toggle),
	.no_csync  (1'b0       ),
	.ypbpr     (1'b0       ),
	.rotate    (2'b00      ),
	.blend     (1'b0       ),
	.R         (rgbQ[17:12]),
	.G         (rgbQ[11: 6]),
	.B         (rgbQ[ 5: 0]),
	.HSync     (~hsync     ),
	.VSync     (~vsync     ),
	.VGA_R     (rgb[17:12] ),
	.VGA_G     (rgb[11: 6] ),
	.VGA_B     (rgb[ 5: 0] ),
	.VGA_VS    (sync[1]    ),
	.VGA_HS    (sync[0]    )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
