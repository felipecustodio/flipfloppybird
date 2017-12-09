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
		-- VGA
		clkvideo, clk, reset  : IN	STD_LOGIC;
		videoflag	: out std_LOGIC; -- ligar desenho
		vga_pos		: out STD_LOGIC_VECTOR(15 downto 0); -- posição na tela
		vga_char	: out STD_LOGIC_VECTOR(15 downto 0); -- charmap a ser desenhado
		-- Keyboard
		key			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0)	-- teclado
		-- Memory Chips
		-- Obstacles
		-- map_in : IN STD_LOGIC; -- recebe conteúdo da memória
		-- map_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) -- enviar posição de memória a ser acessada
		);

END  notepad ;


-- DICAS: ALFABETO COMECA NO 66 --(A)



ARCHITECTURE a OF notepad IS

	-------------------------------------------------
	-- VÍDEO
	-------------------------------------------------
	-------------------------------------------------
	-- Sinal de vídeo - escrever na tela
	SIGNAL VIDEOE      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- VECTOR PARA DESENHAR AN TELA
	TYPE vector IS ARRAY(0 to 255) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE vector_pos IS ARRAY(0 to 255) of STD_LOGIC_VECTOR(15 DOWNTO 0);
	-------------------------------------------------

	-------------------------------------------------
	-- FLIPPY
	-------------------------------------------------
	-------------------------------------------------
	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_POSA  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FLIPPY_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL FLIPPY_FLAG  : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Estado atual do Flippy
	SIGNAL FLIPPY_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Delay do Flippy
	SIGNAL DELAY1      : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-------------------------------------------------
	-- CENÁRIO / CANOS
	-------------------------------------------------
	---------------------------------------------------
	SIGNAL VECTOR_CANO : vector_pos;
	SIGNAL INDEX_CANO1  	 : integer;
	SIGNAL POSITION_CANO1   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL CANO1_POS  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL CANO1_POSA  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL CANO1_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CANO1_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL CANO1_FLAG  : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- Estado atual do CANO 1
	SIGNAL CANO1_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Delay do CANO 1
	SIGNAL DELAY_CANO1      : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-------------------------------------------------
	-- TEXTOS
	-------------------------------------------------
	-- Game Over
	SIGNAL GAME_OVER : vector;

	--DESENHAR ARRAY
	SIGNAL INDEX  	 : integer;
	SIGNAL POSITION   : STD_LOGIC_VECTOR(15 DOWNTO 0);

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
		FLIPPY_CHAR <= "00000001";
		FLIPPY_COLOR <= "1111"; -- Branco
		FLIPPY_POS <= x"0261";
		DELAY1 <= x"00000000";
		FLIPPY_STATE <= x"00";
		FLIPPY_FLAG <= x"00"; -- 0: VIVO / 1: MORTO

	ELSIF (clk'event) and (clk = '1') THEN

		CASE FLIPPY_STATE IS

			WHEN x"00" => -- Estado de movimentação
				-- Sempre caindo
				IF (FLIPPY_POS < 1159) THEN   -- não está na ultima linha
					FLIPPY_POS <= FLIPPY_POS + x"28";  -- CAI 40
					FLIPPY_STATE <= x"02";
				END IF;

				IF (FLIPPY_POS > 1119) THEN -- bateu na última linha
					FLIPPY_FLAG <= x"01"; -- Morreu
					FLIPPY_STATE <= x"03"; -- Ir para Game Over
				END IF;

				-- Movimentação
				CASE key IS
					WHEN x"20" => -- ESPACO = PULO
						IF (FLIPPY_POS > 40) AND (FLIPPY_FLAG = x"00") THEN
						-- Não bateu no teto, pode pular!
							FLIPPY_POS <= FLIPPY_POS - x"28";  -- SOBE 40
							FLIPPY_STATE <= x"02";
						ELSE
						-- Flippy atingiu o teto!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03"; -- Ir para Game Over
						END IF;
					-- Resetar jogo
					WHEN x"0D" => -- ENTER = RESET
						FLIPPY_COLOR <= "1111"; -- Branco
						FLIPPY_CHAR <= "00000001";
						FLIPPY_POS <= x"0261";
						DELAY1 <= x"00000000";
						FLIPPY_STATE <= x"00";
						FLIPPY_FLAG <= x"00"; -- PARA SABER QUANDO ACABAR O JOGO 0: VIVO / 1: MORTO
						FLIPPY_STATE <= x"02";
					WHEN OTHERS =>
				END CASE;

			WHEN x"02" => -- Delay
				-- Delay máximo, voltar à ação
				IF DELAY1 >=  x"00000EFF" THEN
					DELAY1 <= x"00000000";
					FLIPPY_STATE <= x"00";
				ELSE
				-- Aumentar delay
					DELAY1 <= DELAY1 + x"01";
				END IF;

			WHEN x"03" => -- Estado Game Over
				FLIPPY_CHAR <= "00000010";
				FLIPPY_COLOR <= "1011"; -- Amarelo
				FLIPPY_STATE <= x"02"; -- Ir para próximo estado (delay)

			WHEN OTHERS =>
		END CASE;
	END IF;
END PROCESS;

-------------------------------------------------
-- CANO 1 (EM CIMA/EM BAIXO)
-------------------------------------------------
PROCESS (clk, reset)

BEGIN
--
IF RESET = '1' THEN
	CANO1_CHAR <= "00000000"; -- Bloco Sólido
	CANO1_COLOR <= "1010"; -- Verde
	CANO1_POS <= x"0028"; -- Canto superior direito
	DELAY_CANO1 <= x"00000000";
	CANO1_STATE <= x"00";
	CANO1_FLAG <= x"00"; -- 0: ANDANDO / 1: PARADO

	ELSIF (clk'event) and (clk = '1') THEN

		CASE CANO1_STATE IS

			WHEN x"00" => -- ESTADO DE MOVIMENTACAO
				-- INDO PARA ESQUERDA
				IF (CANO1_POS > x"0002") THEN   -- não está na parede da esquerda
					CANO1_POS <= CANO1_POS - x"01";  -- Anda para a esquerda
					CANO1_STATE <= x"02";
				ELSE
					CANO1_POS <= x"0028";
					CANO1_STATE <= x"02";
				END IF;

				-- BOTAO DE RESETAR
				CASE key IS
					-- Resetar jogo
					WHEN x"0D" => -- ENTER = RESET
						CANO1_COLOR <= "1111"; -- Branco
						CANO1_CHAR <= "00000000";
						CANO1_POS <= x"0028";
						DELAY_CANO1 <= x"00000000";
						CANO1_STATE <= x"00";
						CANO1_FLAG <= x"00"; -- PARA SABER QUANDO ACABAR O JOGO 0: VIVO / 1: MORTO
						CANO1_STATE <= x"02";
					WHEN OTHERS =>
				END CASE;

			WHEN x"02" => -- Delay
				-- Delay máximo, voltar à ação
				IF DELAY_CANO1 >=  x"00000FFF" THEN
					DELAY_CANO1 <= x"00000000";
					CANO1_STATE <= x"00";
				ELSE
				-- Aumentar delay
					DELAY_CANO1 <= DELAY_CANO1 + x"01";
				END IF;

			WHEN OTHERS =>
		END CASE;
	END IF;
END PROCESS;

-------------------------------------------------
-- VIDEO LOOP
-------------------------------------------------
-- Escreve na Tela
PROCESS (clkvideo, reset)

BEGIN
	IF RESET = '1' THEN
		VIDEOE <= x"00";
		videoflag <= '0';
		FLIPPY_POSA <= x"0000";
		CANO1_POSA <= x"0000";

		-- INICIALIZAR TEXTOS
		GAME_OVER <= (OTHERS=>"00000000");
		GAME_OVER(0) <= "01000111"; -- G
		GAME_OVER(1) <= "01000001"; -- A
		GAME_OVER(2) <= "01001101"; -- M
		GAME_OVER(3) <= "01000101"; -- E
		GAME_OVER(5) <= "01001111"; -- O
		GAME_OVER(6) <= "01010110"; -- V
		GAME_OVER(7) <= "01000101"; -- E
		GAME_OVER(8) <= "01010010"; -- R

		--SETAR INDEX E POS INICIAL
		INDEX <= 0;
		POSITION <= x"01A9";
		-- POSITION <= x"00B9";

	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS

			-------------------------------------------------
			-- Desenhar Flippy
			-------------------------------------------------

			-- Apagar Flippy
			WHEN x"00" =>

				if(FLIPPY_POSA = FLIPPY_POS) then -- Apenas apagar quando muda de posição
					IF (FLIPPY_FLAG = x"01") THEN -- Se estiver morto, ir p/ desenhar Game Over
						VIDEOE <= x"04";
					ELSE
						VIDEOE <= x"00";
					END IF;
				else

				-- Apagar
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= "1110"; -- Pintar de azul (fundo)
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado

				vga_pos(15 downto 0) <= FLIPPY_POSA;
				videoflag <= '1';
				VIDEOE <= x"01";

				end if;

			-- Intermediário Apagar->Desenhar
			WHEN x"01" =>
				videoflag <= '0';
				VIDEOE <= x"02";

			-- Desenhar Flippy
			WHEN x"02" =>

				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= FLIPPY_COLOR;
				vga_char(7 downto 0) <= FLIPPY_CHAR;

				vga_pos(15 downto 0) <= FLIPPY_POS;
				FLIPPY_POSA <= FLIPPY_POS; -- Atualizar posição

				videoflag <= '1';
				VIDEOE <= x"03";

			-- Intermediário Desenhar->Textos
			WHEN x"03" =>
				videoflag <= '0';
				-- SE GAME OVER, DESENHAR TEXTO NA TELA

				VIDEOE <= x"06";

			-------------------------------------------------
			-- Desenhar Textos
			-------------------------------------------------

			WHEN x"04" => -- Desenha GAME OVER NA TELA

				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= "1001";
				vga_char(7 downto 0) <= GAME_OVER(INDEX);
				vga_pos(15 downto 0)	<= POSITION;

				videoflag <= '1';

				VIDEOE <= x"05";


			-- Intermediário PALAVRA->Apagar CANO1
			WHEN x"05" =>
				videoflag <= '0';


				IF(POSITION > x"01B2") THEN
					POSITION <= x"01A9";
					INDEX <= 0;
				ELSE
					POSITION <= POSITION + x"01";
					INDEX <= INDEX + 1;
					VIDEOE <= x"04";
				END IF;

				VIDEOE <= x"06";

			-------------------------------------------------
			-- Desenhar Canos
			-------------------------------------------------

			-- APAGAR CANO 1
			WHEN x"06" =>

				if(CANO1_POSA = CANO1_POS) then -- Apenas apagar quando muda de posição
				--	VIDEOE <= x"00";
				else

				-- Apagar
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= "1110"; -- Pintar de azul (fundo)
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado

				--APAGANDO A POSICAO ANTERIOR DO CANO 1
				vga_pos(15 downto 0) <= CANO1_POSA;
				videoflag <= '1';
				VIDEOE <= x"07";

				end if;

			-- Intermediário APAGAR CANO1 -> DESENHAR CANO 1
			WHEN x"07" =>
				videoflag <= '0';
				VIDEOE <= x"08";

			-- DESENHANDO CANO1
			WHEN x"08" =>

				-- AJUSTAR VARIAVEIS PARA CANO 1
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= CANO1_COLOR;
				vga_char(7 downto 0) <= CANO1_CHAR;

				vga_pos(15 downto 0) <= CANO1_POS;
				CANO1_POSA <= CANO1_POS; -- Atualizar posição

				videoflag <= '1';
				VIDEOE <= x"09";


				-- Intermediário DESENHAR CANO 1 -> APAGAR FLIPPY
			WHEN x"09" =>
				videoflag <= '0';
				VIDEOE <= x"00"; -- VOLTANDO PARA O APAGAR FLIPPY

			-------------------------------------------------
			-- Desenhar Cenário
			-------------------------------------------------

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
