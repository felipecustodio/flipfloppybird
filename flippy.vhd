-- *************************************************
-- FLIPPY FLOPPY BIRD
-- Gabriel Henrique Scalici
-- Felipe Scrochio Custódio
-- *************************************************
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY notepad IS

	PORT(
		clkvideo, clk, reset  : IN	STD_LOGIC;		
		videoflag	: out std_LOGIC;
		vga_pos		: out STD_LOGIC_VECTOR(15 downto 0);
		vga_char	: out STD_LOGIC_VECTOR(15 downto 0);
		key			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0)	-- teclado
		);

END  notepad ;

ARCHITECTURE a OF notepad IS

	-------------------------------------------------
	-- Sinal de vídeo - escrever na tela
	SIGNAL VIDEOE      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-------------------------------------------------

	-------------------------------------------------
	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_POSA  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FLIPPY_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0);

	-- Estado atual do Flippy
	SIGNAL FLIPPY_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Delay do Flippy
	SIGNAL DELAY1       : STD_LOGIC_VECTOR(31 DOWNTO 0);
	-------------------------------------------------
 

	-------------------------------------------------
	-- Cenário

	-- Vetores gerados pelo script bmp2vhdlvector.py
	map_line0: std_logic_vector(40 downto 0);
	map_line1: std_logic_vector(40 downto 0);
	map_line2: std_logic_vector(40 downto 0);
	map_line3: std_logic_vector(40 downto 0);
	map_line4: std_logic_vector(40 downto 0);
	map_line5: std_logic_vector(40 downto 0);
	map_line6: std_logic_vector(40 downto 0);
	map_line7: std_logic_vector(40 downto 0);
	map_line8: std_logic_vector(40 downto 0);
	map_line9: std_logic_vector(40 downto 0);
	map_line10: std_logic_vector(40 downto 0);
	map_line11: std_logic_vector(40 downto 0);
	map_line12: std_logic_vector(40 downto 0);
	map_line13: std_logic_vector(40 downto 0);
	map_line14: std_logic_vector(40 downto 0);
	map_line15: std_logic_vector(40 downto 0);
	map_line16: std_logic_vector(40 downto 0);
	map_line17: std_logic_vector(40 downto 0);
	map_line18: std_logic_vector(40 downto 0);
	map_line19: std_logic_vector(40 downto 0);
	map_line20: std_logic_vector(40 downto 0);
	map_line21: std_logic_vector(40 downto 0);
	map_line22: std_logic_vector(40 downto 0);
	map_line23: std_logic_vector(40 downto 0);
	map_line24: std_logic_vector(40 downto 0);
	map_line25: std_logic_vector(40 downto 0);
	map_line26: std_logic_vector(40 downto 0);
	map_line27: std_logic_vector(40 downto 0);
	map_line28: std_logic_vector(40 downto 0);
	map_line29: std_logic_vector(40 downto 0);
	map_line0 <= "0000000000000000001111111000000000000000"
	map_line1 <= "0000000000000000001111111000000000000000"
	map_line2 <= "0000000000000000001111111000000000000000"
	map_line3 <= "0000000000000000001111111000000000000000"
	map_line4 <= "0000000000000000001111111000000000000000"
	map_line5 <= "0000000000000000001111111000000000000000"
	map_line6 <= "0000000000000000001111111000000000000000"
	map_line7 <= "0000000000000000000000000000000000000000"
	map_line8 <= "0000000000000000000000000000000000000000"
	map_line9 <= "0000000000000000000000000000000000000000"
	map_line10 <= "0000000000000000000000000000000000000000"
	map_line11 <= "0000000000000000000000000000000000000000"
	map_line12 <= "0000000000000000000000000000000000000000"
	map_line13 <= "0000000000000000000000000000000000000000"
	map_line14 <= "0000000000000000000000000000000000000000"
	map_line15 <= "0000000000000000000000000000000000000000"
	map_line16 <= "0000000000000000001111111000000000000000"
	map_line17 <= "0000000000000000001111111000000000000000"
	map_line18 <= "0000000000000000001111111000000000000000"
	map_line19 <= "0000000000000000001111111000000000000000"
	map_line20 <= "0000000000000000001111111000000000000000"
	map_line21 <= "0000000000000000001111111000000000000000"
	map_line22 <= "0000000000000000001111111000000000000000"
	map_line23 <= "0000000000000000001111111000000000000000"
	map_line24 <= "0000000000000000001111111000000000000000"
	map_line25 <= "0000000000000000001111111000000000000000"
	map_line26 <= "0000000000000000001111111000000000000000"
	map_line27 <= "0000000000000000001111111000000000000000"
	map_line28 <= "0000000000000000001111111000000000000000"
	map_line29 <= "0000000000000000001111111000000000000000"

	-- Posição atual de onde começa o desenho
	SIGNAL MAP_AUX : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Velocidade de movimento do mapa
	SIGNAL MAP_SPEED : STD_LOGIC_VECTOR(4 DOWNTO 0);

	-- Estado
	SIGNAL MAP_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Delay
	SIGNAL DELAY2 : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-------------------------------------------------


-------------------------------------------------
-- GAME LOOP
-------------------------------------------------
BEGIN

-------------------------------------------------
-- FLIPPY
-------------------------------------------------
PROCESS (clk, reset)
	
	BEGIN
		
	IF RESET = '1' THEN
		
		MAP_AUX <= x"00000000"
		DELAY1 <= x"00000000";
		FLIPPY_STATE <= x"00";
		
	ELSIF (clk'event) and (clk = '1') THEN

		CASE FLIPPY_STATE IS
			

			WHEN x"00" => -- Estado de movimentação
			
				-- Sempre caindo
				IF (FLIPPY_POS < 1159) THEN   -- não está na ultima linha
					FLIPPY_POS <= FLIPPY_POS + x"28";  -- CAI 40
				END IF;
						
				IF (FLIPPY_POS > 1159) THEN -- bateu na última linha
					FLIPPY_COLOR <= "1010";
					FLIPPY_POS <= FLIPPY_POS - x"28"; -- SOBE 40
				END IF;
			
				CASE key IS

					WHEN x"20" => -- (ESPAÇO) (PULO)
						IF (FLIPPY_POS > 39) THEN   -- nao está na primeira linha
							FLIPPY_POS <= FLIPPY_POS - x"78";  -- SOBE 120
						END IF;

					WHEN OTHERS =>
				END CASE;
				FLIPPY_STATE <= x"01"; -- Ir para próximo estado (delay)

			
			WHEN x"01" => -- Delay para movimentar Flippy
			 
				IF DELAY1 >= x"00000FFF" THEN
					DELAY1 <= x"00000000";
					FLIPPY_STATE <= x"00";
				ELSE
					DELAY1 <= DELAY1 + x"01";
				END IF;
				
			WHEN OTHERS =>
		END CASE;
	END IF;

END PROCESS;

-------------------------------------------------
-- MAP
-------------------------------------------------
PROCESS (clk, reset)

BEGIN 
		
	IF RESET = '1' THEN
		MAP_AUX <= x"00"; -- Resetar posição de desenho
		MAP_STATE <= x"00"; -- Resetar estado
		DELAY2 <= x"00000000"; -- Resetar delay

	ELSIF (clk'event) and (clk = '1') THEN

		CASE MAP_STATE IS
			
			WHEN x"00" => -- Estado de movimentação
				
				MAP_AUX <= MAP_AUX + MAP_SPEED; -- Mover cenário para esquerda	

				-- Checar por colisões

				MAP_STATE <= x"01"; -- Ir para próximo estado (delay)

			WHEN x"01" => -- Delay
			 	-- Mexer com esses valores
				IF DELAY2 >= x"00000FFF" THEN
					DELAY2 <= x"00000000";
					MAP_STATE <= x"00";
				ELSE
					DELAY2 <= DELAY2 + x"01";
				END IF;
				
			WHEN OTHERS =>
		END CASE;

	END IF;

END PROCESS;

-------------------------------------------------
-- VIDEO LOOP
-------------------------------------------------
PROCESS (clkvideo, reset)

BEGIN
	IF RESET = '1' THEN
		VIDEOE <= x"00";
		videoflag <= '0';
		FLIPPY_POSA <= x"0000";
	
	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS
		FLIPPY_POSA <= x"0000";
	
	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS			

			WHEN x"00" => -- Apaga Bolinha
				else
										
						vga_char(15 downto 12) <= "0000";
						vga_char(11 downto 8) <= "0000";
						vga_char(7 downto 0) <= "00000000";
				
					vga_pos(15 downto 0)	<= BOLAPOSA;
					
					videoflag <= '1';
					VIDEOE <= x"01";
					
				end if;
			

			WHEN x"01" =>
				videoflag <= '0';
				VIDEOE <= x"02";
			

			WHEN x"02" => -- Desenha Bolinha
							
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= BOLACOR;
				vga_char(7 downto 0) <= BOLACHAR;
					
				
				vga_pos(15 downto 0)	<= BOLAPOS;
				
				BOLAPOSA <= BOLAPOS;   -- Pos Anterior = Pos Atual
				videoflag <= '1';
				VIDEOE <= x"03";
			

			WHEN x"03" =>
				videoflag <= '0';
				VIDEOE <= x"04";
			
			
			WHEN x"04" => -- Apaga Flippy
				if(FLIPPY_POSA = FLIPPY_POS) then
					VIDEOE <= x"00";
				else
									
					vga_char(15 downto 12) <= "0000";
					vga_char(11 downto 8) <= "0000";
					vga_char(7 downto 0) <= "00000000";
					
					vga_pos(15 downto 0)	<= FLIPPY_POSA;
					
					videoflag <= '1';
					VIDEOE <= x"05";
				end if;

			
			WHEN x"05" =>
				videoflag <= '0';
				VIDEOE <= x"06";

			
			WHEN x"06" => -- Desenha Flippy
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= FLIPPY_COLOR;
				vga_char(7 downto 0) <= FLIPPY_CHAR;
				
				vga_pos(15 downto 0)	<= FLIPPY_POS;
				
				FLIPPY_POSA <= FLIPPY_POS;
				videoflag <= '1';
				VIDEOE <= x"07";
			

			WHEN x"07" =>
				videoflag <= '0';
				VIDEOE <= x"00";
			
			

			WHEN OTHERS =>
				videoflag <= '0';
				VIDEOE <= x"00";	
		

		END CASE;
	END IF;
END PROCESS;
	
--PROCESS (videoflag, video_set)
--BEGIN
--  IF video_set = '1' THEN video_ready <= '0';
--  ELSIF videoflag'EVENT and videoflag = '1' THEN video_ready <= '1';
--  END IF;
--END PROCESS;

END a;
