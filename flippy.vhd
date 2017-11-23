-- *************************************************
-- FLIPPY FLOPPY BIRD
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

	-- Sinal de vídeo - escrever na tela
	SIGNAL VIDEOE      : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_POSA  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FLIPPY_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0);

	-- Estado atual do Flippy
	SIGNAL FLIPPY_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Delay do Flippy
	SIGNAL DELAY1      : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

-- Flippy
PROCESS (clk, reset)
	
	BEGIN
		
	IF RESET = '1' THEN
		FLIPPY_CHAR <= "00000001";
		FLIPPY_COLOR <= "1111"; -- Branco
		FLIPPY_POS <= x"0294";
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

<<<<<<< Updated upstream
-- Bolinha
PROCESS (clk, reset)

BEGIN
		
	IF RESET = '1' THEN
		BOLACHAR <= "00000010";
		BOLACOR <= "1001"; -- 1001 Vermelho
		BOLAPOS <= x"006E";
		INCBOLA <= x"29";
		SINAL <= '0';	
		DELAY2 <= x"00000000";
		B_ESTADO <= x"00";
		
	ELSIF (clk'event) and (clk = '1') THEN

				CASE B_ESTADO iS
					

					WHEN x"00" =>
						-- INCREMENTA A POS DA BOLA
							IF (SINAL = '0') THEN BOLAPOS <= BOLAPOS + INCBOLA;
							ELSE BOLAPOS <= BOLAPOS - INCBOLA; END IF;
							
							B_ESTADO <= x"01";
						
					
					WHEN x"01" => -- Bola esta' subindo e chegou na linha de cima : SINAL = 1
						IF (BOLAPOS < 40) THEN
							IF (INCBOLA = 41) THEN INCBOLA <= x"27"; SINAL <= '0'; END IF;
							IF (INCBOLA = 40) THEN INCBOLA <= x"28"; SINAL <= '0'; END IF;
							IF (INCBOLA = 39) THEN INCBOLA <= x"29"; SINAL <= '0'; END IF;
						end if;							

						B_ESTADO <= x"02";


					WHEN x"02" => -- Bola esta' descendo e chegou na linha de baixo : SINAL = 0
						IF (BOLAPOS > 1159) THEN
							IF (INCBOLA = 41) THEN INCBOLA <= x"27"; SINAL <= '1'; END IF;
							IF (INCBOLA = 40) THEN INCBOLA <= x"28"; SINAL <= '1'; END IF;
							IF (INCBOLA = 39) THEN INCBOLA <= x"29"; SINAL <= '1'; END IF;
						end if;

						B_ESTADO <= x"03";
	
					
					WHEN x"03" => -- Bola esta' indo para direita e chegou na extrema direita: SINAL = ? 
						IF ((conv_integer(BOLAPOS) MOD 40) = 39) THEN
							IF (INCBOLA = 39) THEN INCBOLA <= x"29"; SINAL <= '1'; END IF;
							IF (INCBOLA = 1) THEN INCBOLA <= x"01"; SINAL <= '1'; END IF;
							IF (INCBOLA = 41) THEN INCBOLA <= x"27"; SINAL <= '0'; END IF;
						end if;							

						B_ESTADO <= x"04";
	
					
					WHEN x"04" => -- Bola esta' indo para esquerda e chegou na extrema esquerda: SINAL = ? 
						IF ((conv_integer(BOLAPOS) MOD 40) = 0) THEN
							IF (INCBOLA = 39) THEN INCBOLA <= x"29"; SINAL <= '0'; END IF;
							IF (INCBOLA = 1) THEN INCBOLA <= x"01"; SINAL <= '0'; END IF;
							IF (INCBOLA = 41) THEN INCBOLA <= x"27"; SINAL <= '1'; END IF;
						end if;							
-- Cenário
PROCESS ()

END PROCESS;

-- Escreve na Tela
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
