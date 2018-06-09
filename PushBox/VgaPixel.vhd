library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VgaPixel is
	generic (
		MAP_START_COL   : natural := 144; -- (800 - 512) / 2
		MAP_END_COL     : natural := 656; -- Anterior + 512
		MAP_START_ROW   : natural := 44;  -- (600 - 512) / 2
		MAP_END_ROW     : natural := 556; -- Anterior + 512
		
		-- Shift a ser realizado para pegar a posição no tabuleiro
		-- Se a imagem de um quadrado tem 32x32 pixels (2^5 x 2^5),
		-- então calculamos a posição x e y por meio da conta:
		-- map_x_pos = (col - MAP_START_COL) >> 5
		-- map_y_pos = (row - MAP_START_ROW) >> 5
		MAP_SQUARESIZE_BITS : natural := 5
	);
	port (
		-- Sinais de VGA
		reset       : in  std_logic;
		clock       : in  std_logic;
		disp_enable : in  std_logic;
		row         : in  unsigned(9 downto 0);
		column      : in  unsigned(10 downto 0);
		r_out       : out unsigned(3 downto 0);
		g_out       : out unsigned(3 downto 0);
		b_out       : out unsigned(3 downto 0);
		
		-- Sinais para ler o mapa do jogo
		map_pos_value : in  unsigned(2 downto 0);
		map_x_pos     : out unsigned(3 downto 0);
		map_y_pos     : out unsigned(3 downto 0)
	);
end entity;

architecture archVgaPixel of VgaPixel is

-- Imagens das tiles
type image_array_t is array(15 downto 0, 15 downto 0) of unsigned(11 downto 0);
constant tile_box           : image_array_t := ((X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0"),
                                                (X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"fb0",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"960",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0"),
												(X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0",X"fb0"));

constant tile_box_objective : image_array_t := ((X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0"),
                                                (X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"dc0",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"ab1",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0"),
												(X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0",X"dc0"));

constant tile_floor         : image_array_t := ((X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
                                                (X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"));

constant tile_objective     : image_array_t := ((X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
                                                (X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"2b4",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"));

constant tile_player        : image_array_t := ((X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"),
                                                (X"ba7",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"e12",X"e12",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"e12",X"e12",X"e12",X"e12",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"e12",X"e12",X"e12",X"e12",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"e12",X"e12",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"333",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"dcb"),
												(X"ba7",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"666",X"dcb"),
												(X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb",X"ba7",X"dcb",X"dcb",X"dcb"));

constant tile_wall          : image_array_t := ((X"fff",X"fff",X"fff",X"fff",X"fff",X"fff",X"fff",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
                                                (X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"777",X"777",X"777",X"777",X"777",X"777",X"777",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"fff",X"fff",X"fff",X"fff",X"fff",X"fff",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"),
												(X"777",X"777",X"777",X"777",X"777",X"777",X"777",X"777",X"fff",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"ccc",X"777"));

-- Índices para os pixels das tiles
signal s_x_image : unsigned(3 downto 0);
signal s_y_image : unsigned(3 downto 0);

-- Sinais de cor
signal s_rgb_prev : unsigned(11 downto 0);
signal s_rgb_next : unsigned(11 downto 0);

begin

	-- Aplica o valor da cor se estiver em um pixel da região ativa
	r_out <= s_rgb_prev(11 downto 8) when disp_enable = '1' else x"0";
	g_out <= s_rgb_prev(7 downto 4) when disp_enable = '1' else x"0";
	b_out <= s_rgb_prev(3 downto 0) when disp_enable = '1' else x"0";
	
	-- Define a posição de leitura do mapa do jogo
	map_x_pos <= unsigned((column - MAP_START_COL) srl MAP_SQUARESIZE_BITS)(3 downto 0);
	map_y_pos <= unsigned((row    - MAP_START_ROW) srl MAP_SQUARESIZE_BITS)(3 downto 0);
	
	-- Define a posição de leitura da tile (15 - valor porque o matlab fez invertido)
	s_x_image <= 15 - unsigned((column - MAP_START_COL))(4 downto 1);
	s_y_image <= 15 - unsigned((row    - MAP_START_ROW))(4 downto 1);
	
	-- Pega a cor correspondente (DEBUG)
--	s_rgb_next <= x"000" when column < MAP_START_COL or
--	                          column >= MAP_END_COL  or
--	                          row < MAP_START_ROW or
--	                          row >= MAP_END_ROW else
--                              x"007" when map_pos_value = "000" else
--                              x"00F" when map_pos_value = "001" else
--                              x"0F0" when map_pos_value = "010" else
--                              x"0FF" when map_pos_value = "011" else
--                              x"F00" when map_pos_value = "100" else
--                              x"F0F" when map_pos_value = "101" else
--                              x"FF0" when map_pos_value = "110" else
--                              x"FFF" when map_pos_value = "111" else
--                              x"000";
	s_rgb_next <= x"000" when column < MAP_START_COL or
	                          column >= MAP_END_COL  or
	                          row < MAP_START_ROW or
	                          row >= MAP_END_ROW else
	              tile_box(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "000" else
				  tile_box_objective(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "001" else
				  tile_floor(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "010" else
				  tile_objective(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "011" else
				  tile_player(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "100" else
				  tile_wall(to_integer(s_x_image), to_integer(s_y_image)) when map_pos_value = "101" else
				  x"000";
	
	-- Atualiza o registrador de cor
	process (clock, reset)
	begin
	
		if (reset = '1') then
			s_rgb_prev <= (others => '0');
		elsif rising_edge(clock) then
			s_rgb_prev <= s_rgb_next;
		end if;
	
	end process;

end architecture;
