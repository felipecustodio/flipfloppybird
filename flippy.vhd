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
		FLIPPY_FLAG <= 0; -- PARA SABER QUANDO ACABAR O JOGO 0: VIVO/ 1: MORTO

	ELSIF (clk'event) and (clk = '1') THEN

		CASE FLIPPY_STATE IS

			-- ## ESTADO PARA ANALISAR O MOVIMENTO DE DESCIDA FLIPPY
			WHEN x"00" => -- ESTADO 0: DESCIDA

				-- Sempre caindo
				IF (FLIPPY_POS < 1159) AND (FLAG = 0) THEN   -- Nao esta na ultima linha, e esta vivo
					FLIPPY_POS <= FLIPPY_POS + x"28";  -- CAI 40
				END IF;

				-- VERIFICANDO SE ENCOSTOU NO CHAO
				IF (FLIPPY_POS > 1159) THEN -- BATEU NO CHAO
					FLIPPY_COLOR <= "1010"; -- MUDA A COR

					-- FAZER O JOGO ACABAR QUANDO O PERSONAGEM CAIR
					FLIPPY_POS <= x"0294"; -- VOLTA PARA O MEIO DA TELA
					FLIPPY_FLAG <= 1; -- MOSTRANDO QUE ESTA MORTO
					-- ######### IR PARA O ESTADO "GAME OVER" ####################
 				END IF;

				-- PARAR DE CAIR SOMENTE COM MOVIMENTO DE PULO
				CASE key IS

					WHEN x"20" => -- ESPACO == PULO
						IF(FLIPPY_FLAG = 0) THEN -- SE ESTIVER VIVO
							FLIPPY_STATE <= x"01"
						END IF;


					WHEN OTHERS =>
				END CASE;
				FLIPPY_STATE <= x"02"; -- Ir para próximo estado (delay)


				-- ## ESTADO PARA ANALISAR O MOVIMENTO DE SUBIDA FLIPPY
				WHEN x"01" => -- ESTADO 01: SUBIDA

				-- PULO VALIDO QUANDO O FLIPPY NAO MORRE
				IF (FLIPPY_POS > 195) AND (FLIPPY_FLAG = 0) THEN   -- NAO ESTA NAS 5 PRIMEIRAS LINHAS
					FLIPPY_POS <= FLIPPY_POS - x"00C8";  -- SOBE 200
				ELSE
				-- FLIPPY PULOU MAIS DO QUE DEVERIA PULAR, ENTAO MORRE
					FLIPPY_FLAG <= 1; -- MORTO
				-- ######### IR PARA O ESTADO "GAME OVER" ####################
					-- PARAR DE CAIR SOMENTE COM MOVIMENTO DE PULO
					FLIPPY_STATE <= x"02"; -- Ir para próximo estado (delay)


			-- ## ESTADO DELAY PARA O JOGO FICAR JOGAVEL
			WHEN x"02" => -- Delay para movimentar Flippy

				IF DELAY1 >= x"00000FFF" THEN
					DELAY1 <= x"00000000";
					FLIPPY_STATE <= x"00"; -- VAI PARA O ESTADO 01 DE QUALQUER JEITO
				ELSE
					DELAY1 <= DELAY1 + x"01";
				END IF;

			WHEN OTHERS =>
		END CASE;
	END IF;

END PROCESS;


-- Escreve na Tela
PROCESS (clkvideo, reset)

BEGIN
	IF RESET = '1' THEN
		VIDEOE <= x"00";
		videoflag <= '0';
		FLIPPY_POSA <= x"0000";
		BolAPOSA <= x"0000";

	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS


			WHEN x"00" => -- Apaga Bolinha
				if(BOLAPOSA = BOLAPOS) then
					VIDEOE <= x"04";
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
