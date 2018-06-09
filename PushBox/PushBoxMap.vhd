library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PushBoxMap is
	generic (
		MAP_WIDTH_BITS  : natural := 4;
		MAP_HEIGHT_BITS : natural := 4
	);
	port (
		clk : in  std_logic;
		
		-- Inputs de botão
		btn_cima     : in  std_logic;
		btn_baixo    : in  std_logic;
		btn_esquerda : in  std_logic;
		btn_direita  : in  std_logic;
		
		-- Dados VGA
		display_x         : in unsigned(3 downto 0);
		display_y         : in unsigned(3 downto 0);
		display_pos_value : out unsigned(2 downto 0)
	);
end entity;

architecture archPushBoxMap of PushBoxMap is

-- Matriz do mapa
-- Bit 2: indica se é um objetivo ou não
-- Bits 1 downto 0: indica o que está no local:
--   00: Parede
--   01: Chão
--   10: Jogador
--   11: Caixa
type map_matrix_t is array(2**MAP_WIDTH_BITS-1 downto 0, 2**MAP_HEIGHT_BITS-1 downto 0) of unsigned(2 downto 0);
signal map_matrix : map_matrix_t := (("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
									   
                                       ("100", "100", "100", "100", "100", "100", "000", "000", "000", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "000", "101", "000", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "000", "001", "000", "000", "000", "000", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "000", "000", "000", "011", "001", "011", "101", "000", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "000", "101", "001", "011", "010", "000", "000", "000", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "000", "000", "000", "000", "011", "000", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "000", "101", "000", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "000", "000", "000", "100", "100", "100", "100", "100", "100"),
									   
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"),
                                       ("100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100", "100"));
signal player_pos_x : unsigned(MAP_HEIGHT_BITS-1 downto 0) := "0111";
signal player_pos_y : unsigned(MAP_WIDTH_BITS-1 downto 0)  := "0111";

signal s_btn_cima     : unsigned(2 downto 0) := "000";
signal s_btn_baixo    : unsigned(2 downto 0) := "000";
signal s_btn_esquerda : unsigned(2 downto 0) := "000";
signal s_btn_direita  : unsigned(2 downto 0) := "000";

begin

	display_pos_value <= map_matrix(to_integer(2**MAP_WIDTH_BITS-1 - display_y), to_integer(2**MAP_HEIGHT_BITS-1 - display_x));
	
	-- Debug
	--map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "10";
	
	process (clk)
	begin
		if rising_edge(clk) then
--			s_btn_cima     <= s_btn_cima    (s_btn_cima'left-1 downto 0)     & btn_cima;
--			s_btn_baixo    <= s_btn_baixo   (s_btn_baixo'left-1 downto 0)    & btn_baixo;
--			s_btn_esquerda <= s_btn_esquerda(s_btn_esquerda'left-1 downto 0) & btn_esquerda;
--			s_btn_direita  <= s_btn_direita (s_btn_direita'left-1 downto 0)  & btn_direita;
--			
--			if s_btn_cima(s_btn_cima'left downto s_btn_cima'left-1) = "01" then
--				player_pos_x <= player_pos_x + 1;
--			elsif s_btn_baixo(s_btn_baixo'left downto s_btn_baixo'left-1) = "01" then
--				player_pos_x <= player_pos_x - 1;
--			end if;
--			
--			if s_btn_esquerda(s_btn_esquerda'left downto s_btn_esquerda'left-1) = "01" then
--				player_pos_y <= player_pos_y + 1;
--			elsif s_btn_direita(s_btn_direita'left downto s_btn_direita'left-1) = "01" then
--				player_pos_y <= player_pos_y - 1;
--			end if;
			s_btn_cima     <= s_btn_cima    (1 downto 0) & btn_cima;
			s_btn_baixo    <= s_btn_baixo   (1 downto 0) & btn_baixo;
			s_btn_esquerda <= s_btn_esquerda(1 downto 0) & btn_esquerda;
			s_btn_direita  <= s_btn_direita (1 downto 0) & btn_direita;
			
			if s_btn_cima(2 downto 1) = "10" then
				if map_matrix(to_integer(player_pos_y + 1), to_integer(player_pos_x))(1 downto 0) = "11" and
				   map_matrix(to_integer(player_pos_y + 2), to_integer(player_pos_x))(1 downto 0) = "01" then
				    
					-- Altera posição do player
					map_matrix(to_integer(player_pos_y + 1), to_integer(player_pos_x))(1 downto 0) <= "10";
					-- Altera posição da caixa
					map_matrix(to_integer(player_pos_y + 2), to_integer(player_pos_x))(1 downto 0) <= "11";
					-- Limpa local anterior do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_y <= player_pos_y + 1;
					
				elsif map_matrix(to_integer(player_pos_y + 1), to_integer(player_pos_x))(1 downto 0) = "01" then
					
					-- Altera posição do player
					map_matrix(to_integer(player_pos_y + 1), to_integer(player_pos_x))(1 downto 0) <= "10";
					-- Limpa local anterior do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_y <= player_pos_y + 1;
					
				end if;
			elsif s_btn_baixo(2 downto 1) = "10" then
				if map_matrix(to_integer(player_pos_y - 1), to_integer(player_pos_x))(1 downto 0) = "11" and
				   map_matrix(to_integer(player_pos_y - 2), to_integer(player_pos_x))(1 downto 0) = "01" then
				    
					-- Altera posição do player
					map_matrix(to_integer(player_pos_y - 1), to_integer(player_pos_x))(1 downto 0) <= "10";
					-- Altera posição da caixa
					map_matrix(to_integer(player_pos_y - 2), to_integer(player_pos_x))(1 downto 0) <= "11";
					-- Limpa local anterior do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_y <= player_pos_y - 1;
				
				elsif map_matrix(to_integer(player_pos_y - 1), to_integer(player_pos_x))(1 downto 0) = "01" then
					
					map_matrix(to_integer(player_pos_y - 1), to_integer(player_pos_x))(1 downto 0) <= "10";
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_y <= player_pos_y - 1;
					
				end if;
			end if;
			
			if s_btn_esquerda(2 downto 1) = "10" then
				if map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 1))(1 downto 0) = "11" and
				   map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 2))(1 downto 0) = "01" then
				    
					-- Altera posição do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 1))(1 downto 0) <= "10";
					-- Altera posição da caixa
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 2))(1 downto 0) <= "11";
					-- Limpa local anterior do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_x <= player_pos_x + 1;
					
				elsif map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 1))(1 downto 0) = "01" then
					
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x + 1))(1 downto 0) <= "10";
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_x <= player_pos_x + 1;
					
				end if;
			elsif s_btn_direita(2 downto 1) = "10" then
				if map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 1))(1 downto 0) = "11" and
				   map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 2))(1 downto 0) = "01" then
				    
					-- Altera posição do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 1))(1 downto 0) <= "10";
					-- Altera posição da caixa
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 2))(1 downto 0) <= "11";
					-- Limpa local anterior do player
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_x <= player_pos_x - 1;
					
				elsif map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 1))(1 downto 0) = "01" then
					
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x - 1))(1 downto 0) <= "10";
					map_matrix(to_integer(player_pos_y), to_integer(player_pos_x))(1 downto 0) <= "01";
					player_pos_x <= player_pos_x - 1;
					
				end if;
			end if;
		end if;
	end process;
	
end architecture;
