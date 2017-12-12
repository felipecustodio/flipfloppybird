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
		);

END  notepad ;

ARCHITECTURE a OF notepad IS

	-------------------------------------------------
	-- VÍDEO
	-------------------------------------------------
	-- Sinal de vídeo - escrever na tela
	SIGNAL VIDEOE      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- VECTOR PARA DESENHAR AN TELA
	TYPE vector IS ARRAY(0 to 255) of STD_LOGIC_VECTOR(7 DOWNTO 0); -- Vetor de char (charmap)
	TYPE vector_pos IS ARRAY(0 to 255) of STD_LOGIC_VECTOR(15 DOWNTO 0); -- Vetor de posições
	TYPE vector_screen IS ARRAY(0 to 1200) of STD_LOGIC_VECTOR(15 DOWNTO 0); -- Vetor de posições da tela inteira
	
	-- Resetar tela
	SIGNAL RESET_POS : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Armazena 1 posição

	-------------------------------------------------
	-- FLIPPY
	-------------------------------------------------
	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Posição atual
	SIGNAL FLIPPY_POS_PREV  : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Posição anterior
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Charmap
	SIGNAL FLIPPY_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Cor
	SIGNAL FLIPPY_FLAG  : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Vivo 0 / Morto 1

	-- Estado atual do Flippy
	SIGNAL FLIPPY_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Delay do Flippy
	SIGNAL FLIPPY_DELAY      : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	-- Variáveis para checar colisão
	SIGNAL I : integer; -- Controle de laço
	
	-------------------------------------------------
	-- CANOS
	-------------------------------------------------
	-- Armazenar posições do cano
	SIGNAL PIPE1_VECTOR : vector_pos;
	SIGNAL PIPE2_VECTOR : vector_pos;
	SIGNAL PIPE3_VECTOR : vector_pos;
	SIGNAL PIPE4_VECTOR : vector_pos;
	SIGNAL PIPE5_VECTOR : vector_pos;
	
	-- Limpar canto da tela (lixo do cano)
	SIGNAL CLEAR_VECTOR : vector_pos;
	SIGNAL INDEX_CLEAR : integer;

	-- Variáveis para percorrer/desenhar vetor do cano
	SIGNAL PIPE1_INDEX  	 : integer;
	SIGNAL PIPE2_INDEX  	 : integer;
	SIGNAL PIPE3_INDEX  	 : integer;
	SIGNAL PIPE4_INDEX  	 : integer;
	SIGNAL PIPE5_INDEX  	 : integer;
	
	-- Movimentação
	SIGNAL PIPE_OFFSET   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Estado atual do cano
	SIGNAL PIPE_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- Delay do cano
	SIGNAL PIPE_DELAY : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- Flag para mudar tipo de cano
	SIGNAL PIPE_TYPE : integer;

	-- Flag de vitória
	SIGNAL FLIPPY_VICTORY : integer;

	-------------------------------------------------
	-- TEXTOS
	-------------------------------------------------
	-- Game Over
	SIGNAL GAME_OVER : vector;
	SIGNAL INDEX_GAMEOVER  	 : integer;
	SIGNAL POSITION_GAMEOVER   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Flippy
	SIGNAL TITLE : vector;
	SIGNAL INDEX_TITLE  	 : integer;
	SIGNAL POSITION_TITLE   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Vitória
	SIGNAL VICTORY : vector;
	SIGNAL INDEX_VICTORY : integer;
	SIGNAL POSITION_VICTORY : STD_LOGIC_VECTOR(15 DOWNTO 0);

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
		FLIPPY_COLOR <= "1110"; -- Cor do Fundo / Passarinho preto
		FLIPPY_POS <= x"0261";
		FLIPPY_DELAY <= x"00000000";
		FLIPPY_STATE <= x"00";
		FLIPPY_FLAG <= x"00"; -- 0: VIVO / 1: MORTO
		FLIPPY_VICTORY <= 0; -- 0: JOGANDO / 1: GANHOU

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
						FLIPPY_CHAR <= "00000001";
						FLIPPY_POS <= x"0261";
						FLIPPY_DELAY <= x"00000000";
						FLIPPY_STATE <= x"00";
						FLIPPY_FLAG <= x"00"; -- PARA SABER QUANDO ACABAR O JOGO 0: VIVO / 1: MORTO
						FLIPPY_VICTORY <= 0;
						FLIPPY_STATE <= x"02";
					WHEN OTHERS =>
				END CASE;
			
			-- Checar colisão com posições do cano
			
			CASE PIPE_TYPE IS
			
				WHEN 1 =>
					for I in 0 to 58 loop
						if (FLIPPY_POS = PIPE1_VECTOR(I) - PIPE_OFFSET) then
							-- COLIDIU!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03";
						end if;
					end loop;
				
				WHEN 2 =>
					for I in 0 to 57 loop
						if (FLIPPY_POS = PIPE2_VECTOR(I) - PIPE_OFFSET) then
							-- COLIDIU!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03";
						end if;
					end loop;
					
				WHEN 3 =>
					for I in 0 to 63 loop
						if (FLIPPY_POS = PIPE3_VECTOR(I) - PIPE_OFFSET) then
							-- COLIDIU!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03";
						end if;
					end loop;
				
				WHEN 4 =>
					for I in 0 to 66 loop
						if (FLIPPY_POS = PIPE4_VECTOR(I) - PIPE_OFFSET) then
							-- COLIDIU!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03";
						end if;
					end loop;
				
				WHEN 5 =>
					for I in 0 to 74 loop
						if (FLIPPY_POS = PIPE5_VECTOR(I) - PIPE_OFFSET) then
							-- COLIDIU!
							FLIPPY_FLAG <= x"01"; -- MORTO
							FLIPPY_STATE <= x"03";
						end if;
					end loop;
					
				WHEN OTHERS =>
	
			END CASE;
							
			WHEN x"02" => -- Delay
				-- Delay máximo, voltar à ação
				IF FLIPPY_DELAY >=  x"00000EFF" THEN
					FLIPPY_DELAY <= x"00000000";
					FLIPPY_STATE <= x"00";
				ELSE
				-- Aumentar delay
					FLIPPY_DELAY <= FLIPPY_DELAY + x"01";
				END IF;

			WHEN x"03" => -- Estado Game Over
				FLIPPY_CHAR <= "00000010";
				FLIPPY_STATE <= x"02"; -- Ir para próximo estado (delay)

			WHEN OTHERS =>
		END CASE;
	END IF;
END PROCESS;

-------------------------------------------------
-- CANO
-------------------------------------------------
PROCESS (clk, reset)

	BEGIN

	IF RESET = '1' THEN
		PIPE_DELAY <= x"00000000";
		PIPE_STATE <= x"00";
		PIPE_OFFSET <= x"0000";
		PIPE_TYPE <= 0;
		
	ELSIF (clk'event) and (clk = '1') THEN

		CASE PIPE_STATE IS

			WHEN x"00" => -- Estado de movimentação
				-- Ir para esquerda
				PIPE_OFFSET <= PIPE_OFFSET + x"01"; -- Movimentar offset para a esquerda
				CASE key IS
					WHEN x"0D" => -- ENTER = RESET
						PIPE_DELAY <= x"00000000";
						PIPE_STATE <= x"00";
						PIPE_OFFSET <= x"0000";
						PIPE_TYPE <= 0;
					WHEN OTHERS =>
				END CASE;
				
				IF (PIPE_OFFSET > x"0022") THEN -- Limite esquerdo
				
					IF (PIPE_TYPE = 4) THEN -- Máximo de canos, vitória
						FLIPPY_VICTORY <= 1;
						PIPE_TYPE <= 0;
					ELSE
						PIPE_TYPE <= PIPE_TYPE + 1; -- Mudar tipo de cano
					END IF;
					PIPE_OFFSET <= x"0000"; -- Resetar OFFSET
				END IF;
				
				PIPE_STATE <= x"02";

			WHEN x"02" => -- Delay
				-- Delay máximo, voltar à ação
				IF PIPE_DELAY >=  x"00000FFF" THEN
					PIPE_DELAY <= x"00000000";
					PIPE_STATE <= x"00";
				ELSE
				-- Aumentar delay
					PIPE_DELAY <= PIPE_DELAY + x"01";
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

		-------------------------------------------------
		-- Inicializar Vídeo
		-------------------------------------------------
		VIDEOE <= x"30";
		videoflag <= '0';
		RESET_POS <= x"0000";

		-------------------------------------------------
		-- Inicializar Flippy
		-------------------------------------------------
		FLIPPY_POS_PREV <= x"0000";

		-------------------------------------------------
		-- Inicializar Textos
		-------------------------------------------------
		-- GAME OVER
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
		INDEX_GAMEOVER <= 0;
		POSITION_GAMEOVER <= x"023F"; -- Meio da tela

		-- YOU WIN
		VICTORY(0) <= "01011001" -- y
		VICTORY(1) <= "01001111" -- o
		VICTORY(2) <= "01010101" -- u
		VICTORY(3) <= "00000000" --  
		VICTORY(4) <= "01010111" -- w
		VICTORY(5) <= "01001001" -- i
		VICTORY(6) <= "01001110" -- n

		--SETAR INDEX E POS INICIAL
		INDEX_VICTORY <= 0;
		POSITION_VICTORY <= x"0240"; -- Meio da tela

		-- TÍTULO / BANNER
		TITLE <= (OTHERS=>"00000000");
		TITLE(0) <= "01000110"; -- f
		TITLE(1) <= "01001100"; -- l
		TITLE(2) <= "01001001"; -- i
		TITLE(3) <= "01010000"; -- p
		TITLE(4) <= "01010000"; -- p
		TITLE(5) <= "01011001"; -- y
		TITLE(6) <= "00000000"; --  
		TITLE(7) <= "01000110"; -- f
		TITLE(8) <= "01001100"; -- l
		TITLE(9) <= "01001111"; -- o
		TITLE(10) <= "01010000"; -- p
		TITLE(11) <= "01010000"; -- p
		TITLE(12) <= "01011001";-- y
		TITLE(13) <= "00000000"; --  
		TITLE(14) <= "01000010"; -- b
		TITLE(15) <= "01001001"; -- i
		TITLE(16) <= "01010010"; -- r
		TITLE(17) <= "01000100"; -- d

		--SETAR INDEX E POS INICIAL
		INDEX_TITLE <= 0;
		POSITION_TITLE <= x"002C"; -- Topo da tela
		
		-------------------------------------------------
		-- Inicializar Canos
		-------------------------------------------------
		
		-- Cano Tipo 1 --
		PIPE1_VECTOR <= (OTHERS=>x"0024");
		PIPE1_VECTOR(0) <= x"0024";
		PIPE1_VECTOR(1) <= x"0025";
		PIPE1_VECTOR(2) <= x"0026";
		PIPE1_VECTOR(3) <= x"004c";
		PIPE1_VECTOR(4) <= x"004d";
		PIPE1_VECTOR(5) <= x"004e";
		PIPE1_VECTOR(6) <= x"0074";
		PIPE1_VECTOR(7) <= x"0075";
		PIPE1_VECTOR(8) <= x"0076";
		PIPE1_VECTOR(9) <= x"009c";
		PIPE1_VECTOR(10) <= x"009d";
		PIPE1_VECTOR(11) <= x"009e";
		PIPE1_VECTOR(12) <= x"00c4";
		PIPE1_VECTOR(13) <= x"00c5";
		PIPE1_VECTOR(14) <= x"00c6";
		PIPE1_VECTOR(15) <= x"00ec";
		PIPE1_VECTOR(16) <= x"00ed";
		PIPE1_VECTOR(17) <= x"00ee";
		PIPE1_VECTOR(18) <= x"0114";
		PIPE1_VECTOR(19) <= x"0115";
		PIPE1_VECTOR(20) <= x"0116";
		PIPE1_VECTOR(21) <= x"013c";
		PIPE1_VECTOR(22) <= x"013d";
		PIPE1_VECTOR(23) <= x"013e";
		PIPE1_VECTOR(24) <= x"0164";
		PIPE1_VECTOR(25) <= x"0165";
		PIPE1_VECTOR(26) <= x"0166";
		PIPE1_VECTOR(27) <= x"018b";
		PIPE1_VECTOR(28) <= x"018c";
		PIPE1_VECTOR(29) <= x"018d";
		PIPE1_VECTOR(30) <= x"018e";
		PIPE1_VECTOR(31) <= x"018f";
		PIPE1_VECTOR(32) <= x"0393";
		PIPE1_VECTOR(33) <= x"0394";
		PIPE1_VECTOR(34) <= x"0395";
		PIPE1_VECTOR(35) <= x"0396";
		PIPE1_VECTOR(36) <= x"0397";
		PIPE1_VECTOR(37) <= x"03bc";
		PIPE1_VECTOR(38) <= x"03bd";
		PIPE1_VECTOR(39) <= x"03be";
		PIPE1_VECTOR(40) <= x"03e4";
		PIPE1_VECTOR(41) <= x"03e5";
		PIPE1_VECTOR(42) <= x"03e6";
		PIPE1_VECTOR(43) <= x"040c";
		PIPE1_VECTOR(44) <= x"040d";
		PIPE1_VECTOR(45) <= x"040e";
		PIPE1_VECTOR(46) <= x"0434";
		PIPE1_VECTOR(47) <= x"0435";
		PIPE1_VECTOR(48) <= x"0436";
		PIPE1_VECTOR(49) <= x"045c";
		PIPE1_VECTOR(50) <= x"045d";
		PIPE1_VECTOR(51) <= x"045e";
		PIPE1_VECTOR(52) <= x"0484";
		PIPE1_VECTOR(53) <= x"0485";
		PIPE1_VECTOR(54) <= x"0486";
		PIPE1_VECTOR(55) <= x"04ac";
		PIPE1_VECTOR(56) <= x"04ad";
		PIPE1_VECTOR(57) <= x"04ae";
		
		
		-- Cano tipo 2
		PIPE2_VECTOR <= (OTHERS=>x"0025");
		PIPE2_VECTOR(0) <= x"0025";
		PIPE2_VECTOR(1) <= x"0026";
		PIPE2_VECTOR(2) <= x"0027";
		PIPE2_VECTOR(3) <= x"004d";
		PIPE2_VECTOR(4) <= x"004e";
		PIPE2_VECTOR(5) <= x"004f";
		PIPE2_VECTOR(6) <= x"0075";
		PIPE2_VECTOR(7) <= x"0076";
		PIPE2_VECTOR(8) <= x"0077";
		PIPE2_VECTOR(9) <= x"0255";
		PIPE2_VECTOR(10) <= x"0256";
		PIPE2_VECTOR(11) <= x"0257";
		PIPE2_VECTOR(12) <= x"027d";
		PIPE2_VECTOR(13) <= x"027e";
		PIPE2_VECTOR(14) <= x"027f";
		PIPE2_VECTOR(15) <= x"02a5";
		PIPE2_VECTOR(16) <= x"02a6";
		PIPE2_VECTOR(17) <= x"02a7";
		PIPE2_VECTOR(18) <= x"02cd";
		PIPE2_VECTOR(19) <= x"02ce";
		PIPE2_VECTOR(20) <= x"02cf";
		PIPE2_VECTOR(21) <= x"02f5";
		PIPE2_VECTOR(22) <= x"02f6";
		PIPE2_VECTOR(23) <= x"02f7";
		PIPE2_VECTOR(24) <= x"031d";
		PIPE2_VECTOR(25) <= x"031e";
		PIPE2_VECTOR(26) <= x"031f";
		PIPE2_VECTOR(27) <= x"0345";
		PIPE2_VECTOR(28) <= x"0346";
		PIPE2_VECTOR(29) <= x"0347";
		PIPE2_VECTOR(30) <= x"036d";
		PIPE2_VECTOR(31) <= x"036e";
		PIPE2_VECTOR(32) <= x"036f";
		PIPE2_VECTOR(33) <= x"0395";
		PIPE2_VECTOR(34) <= x"0396";
		PIPE2_VECTOR(35) <= x"0397";
		PIPE2_VECTOR(36) <= x"03bd";
		PIPE2_VECTOR(37) <= x"03be";
		PIPE2_VECTOR(38) <= x"03bf";
		PIPE2_VECTOR(39) <= x"03e5";
		PIPE2_VECTOR(40) <= x"03e6";
		PIPE2_VECTOR(41) <= x"03e7";
		PIPE2_VECTOR(42) <= x"040d";
		PIPE2_VECTOR(43) <= x"040e";
		PIPE2_VECTOR(44) <= x"040f";
		PIPE2_VECTOR(45) <= x"0435";
		PIPE2_VECTOR(46) <= x"0436";
		PIPE2_VECTOR(47) <= x"0437";
		PIPE2_VECTOR(48) <= x"045d";
		PIPE2_VECTOR(49) <= x"045e";
		PIPE2_VECTOR(50) <= x"045f";
		PIPE2_VECTOR(51) <= x"0485";
		PIPE2_VECTOR(52) <= x"0486";
		PIPE2_VECTOR(53) <= x"0487";
		PIPE2_VECTOR(54) <= x"04ad";
		PIPE2_VECTOR(55) <= x"04ae";
		PIPE2_VECTOR(56) <= x"04af";
		
		-- Cano tipo 3
		PIPE3_VECTOR <= (OTHERS=>x"0025");
		PIPE3_VECTOR(0) <= x"0025";
		PIPE3_VECTOR(1) <= x"0026";
		PIPE3_VECTOR(2) <= x"0027";
		PIPE3_VECTOR(3) <= x"004c";
		PIPE3_VECTOR(4) <= x"004d";
		PIPE3_VECTOR(5) <= x"004e";
		PIPE3_VECTOR(6) <= x"004f";
		PIPE3_VECTOR(7) <= x"0075";
		PIPE3_VECTOR(8) <= x"0076";
		PIPE3_VECTOR(9) <= x"0077";
		PIPE3_VECTOR(10) <= x"009d";
		PIPE3_VECTOR(11) <= x"009e";
		PIPE3_VECTOR(12) <= x"009f";
		PIPE3_VECTOR(13) <= x"00c5";
		PIPE3_VECTOR(14) <= x"00c6";
		PIPE3_VECTOR(15) <= x"00c7";
		PIPE3_VECTOR(16) <= x"00ec";
		PIPE3_VECTOR(17) <= x"00ed";
		PIPE3_VECTOR(18) <= x"00ee";
		PIPE3_VECTOR(19) <= x"00ef";
		PIPE3_VECTOR(20) <= x"0115";
		PIPE3_VECTOR(21) <= x"0116";
		PIPE3_VECTOR(22) <= x"0117";
		PIPE3_VECTOR(23) <= x"013d";
		PIPE3_VECTOR(24) <= x"013e";
		PIPE3_VECTOR(25) <= x"013f";
		PIPE3_VECTOR(26) <= x"0165";
		PIPE3_VECTOR(27) <= x"0166";
		PIPE3_VECTOR(28) <= x"0167";
		PIPE3_VECTOR(29) <= x"018d";
		PIPE3_VECTOR(30) <= x"018e";
		PIPE3_VECTOR(31) <= x"018f";
		PIPE3_VECTOR(32) <= x"01b4";
		PIPE3_VECTOR(33) <= x"01b5";
		PIPE3_VECTOR(34) <= x"01b6";
		PIPE3_VECTOR(35) <= x"01b7";
		PIPE3_VECTOR(36) <= x"01dd";
		PIPE3_VECTOR(37) <= x"01de";
		PIPE3_VECTOR(38) <= x"01df";
		PIPE3_VECTOR(39) <= x"0205";
		PIPE3_VECTOR(40) <= x"0206";
		PIPE3_VECTOR(41) <= x"0207";
		PIPE3_VECTOR(42) <= x"022d";
		PIPE3_VECTOR(43) <= x"022e";
		PIPE3_VECTOR(44) <= x"022f";
		PIPE3_VECTOR(45) <= x"0255";
		PIPE3_VECTOR(46) <= x"0256";
		PIPE3_VECTOR(47) <= x"0257";
		PIPE3_VECTOR(48) <= x"027c";
		PIPE3_VECTOR(49) <= x"027d";
		PIPE3_VECTOR(50) <= x"027e";
		PIPE3_VECTOR(51) <= x"027f";
		PIPE3_VECTOR(52) <= x"045c";
		PIPE3_VECTOR(53) <= x"045d";
		PIPE3_VECTOR(54) <= x"045e";
		PIPE3_VECTOR(55) <= x"045f";
		PIPE3_VECTOR(56) <= x"0485";
		PIPE3_VECTOR(57) <= x"0486";
		PIPE3_VECTOR(58) <= x"0487";
		PIPE3_VECTOR(59) <= x"04ac";
		PIPE3_VECTOR(60) <= x"04ad";
		PIPE3_VECTOR(61) <= x"04ae";
		PIPE3_VECTOR(62) <= x"04af";
		
		-- Cano tipo 4
		PIPE4_VECTOR <= (OTHERS=>x"0025");
		PIPE4_VECTOR(0) <= x"0025";
		PIPE4_VECTOR(1) <= x"0026";
		PIPE4_VECTOR(2) <= x"0027";
		PIPE4_VECTOR(3) <= x"004d";
		PIPE4_VECTOR(4) <= x"004e";
		PIPE4_VECTOR(5) <= x"004f";
		PIPE4_VECTOR(6) <= x"0075";
		PIPE4_VECTOR(7) <= x"0076";
		PIPE4_VECTOR(8) <= x"0077";
		PIPE4_VECTOR(9) <= x"009d";
		PIPE4_VECTOR(10) <= x"009e";
		PIPE4_VECTOR(11) <= x"009f";
		PIPE4_VECTOR(12) <= x"00c5";
		PIPE4_VECTOR(13) <= x"00c6";
		PIPE4_VECTOR(14) <= x"00c7";
		PIPE4_VECTOR(15) <= x"00ed";
		PIPE4_VECTOR(16) <= x"00ee";
		PIPE4_VECTOR(17) <= x"00ef";
		PIPE4_VECTOR(18) <= x"0115";
		PIPE4_VECTOR(19) <= x"0116";
		PIPE4_VECTOR(20) <= x"0117";
		PIPE4_VECTOR(21) <= x"013d";
		PIPE4_VECTOR(22) <= x"013e";
		PIPE4_VECTOR(23) <= x"013f";
		PIPE4_VECTOR(24) <= x"0165";
		PIPE4_VECTOR(25) <= x"0166";
		PIPE4_VECTOR(26) <= x"0167";
		PIPE4_VECTOR(27) <= x"018d";
		PIPE4_VECTOR(28) <= x"018e";
		PIPE4_VECTOR(29) <= x"018f";
		PIPE4_VECTOR(30) <= x"01b5";
		PIPE4_VECTOR(31) <= x"01b6";
		PIPE4_VECTOR(32) <= x"01b7";
		PIPE4_VECTOR(33) <= x"031d";
		PIPE4_VECTOR(34) <= x"031e";
		PIPE4_VECTOR(35) <= x"031f";
		PIPE4_VECTOR(36) <= x"0345";
		PIPE4_VECTOR(37) <= x"0346";
		PIPE4_VECTOR(38) <= x"0347";
		PIPE4_VECTOR(39) <= x"036d";
		PIPE4_VECTOR(40) <= x"036e";
		PIPE4_VECTOR(41) <= x"036f";
		PIPE4_VECTOR(42) <= x"0395";
		PIPE4_VECTOR(43) <= x"0396";
		PIPE4_VECTOR(44) <= x"0397";
		PIPE4_VECTOR(45) <= x"03bd";
		PIPE4_VECTOR(46) <= x"03be";
		PIPE4_VECTOR(47) <= x"03bf";
		PIPE4_VECTOR(48) <= x"03e5";
		PIPE4_VECTOR(49) <= x"03e6";
		PIPE4_VECTOR(50) <= x"03e7";
		PIPE4_VECTOR(51) <= x"040d";
		PIPE4_VECTOR(52) <= x"040e";
		PIPE4_VECTOR(53) <= x"040f";
		PIPE4_VECTOR(54) <= x"0435";
		PIPE4_VECTOR(55) <= x"0436";
		PIPE4_VECTOR(56) <= x"0437";
		PIPE4_VECTOR(57) <= x"045d";
		PIPE4_VECTOR(58) <= x"045e";
		PIPE4_VECTOR(59) <= x"045f";
		PIPE4_VECTOR(60) <= x"0485";
		PIPE4_VECTOR(61) <= x"0486";
		PIPE4_VECTOR(62) <= x"0487";
		PIPE4_VECTOR(63) <= x"04ad";
		PIPE4_VECTOR(64) <= x"04ae";
		PIPE4_VECTOR(65) <= x"04af";
		
		-- Cano tipo 5
		PIPE5_VECTOR <= (OTHERS=>x"0025");
		PIPE5_VECTOR(0) <= x"0025";
		PIPE5_VECTOR(1) <= x"0026";
		PIPE5_VECTOR(2) <= x"0027";
		PIPE5_VECTOR(3) <= x"004c";
		PIPE5_VECTOR(4) <= x"004d";
		PIPE5_VECTOR(5) <= x"004e";
		PIPE5_VECTOR(6) <= x"004f";
		PIPE5_VECTOR(7) <= x"0075";
		PIPE5_VECTOR(8) <= x"0076";
		PIPE5_VECTOR(9) <= x"0077";
		PIPE5_VECTOR(10) <= x"01b5";
		PIPE5_VECTOR(11) <= x"01b6";
		PIPE5_VECTOR(12) <= x"01b7";
		PIPE5_VECTOR(13) <= x"01dc";
		PIPE5_VECTOR(14) <= x"01dd";
		PIPE5_VECTOR(15) <= x"01de";
		PIPE5_VECTOR(16) <= x"01df";
		PIPE5_VECTOR(17) <= x"0205";
		PIPE5_VECTOR(18) <= x"0206";
		PIPE5_VECTOR(19) <= x"0207";
		PIPE5_VECTOR(20) <= x"022d";
		PIPE5_VECTOR(21) <= x"022e";
		PIPE5_VECTOR(22) <= x"022f";
		PIPE5_VECTOR(23) <= x"0254";
		PIPE5_VECTOR(24) <= x"0255";
		PIPE5_VECTOR(25) <= x"0256";
		PIPE5_VECTOR(26) <= x"0257";
		PIPE5_VECTOR(27) <= x"027d";
		PIPE5_VECTOR(28) <= x"027e";
		PIPE5_VECTOR(29) <= x"027f";
		PIPE5_VECTOR(30) <= x"02a5";
		PIPE5_VECTOR(31) <= x"02a6";
		PIPE5_VECTOR(32) <= x"02a7";
		PIPE5_VECTOR(33) <= x"02cc";
		PIPE5_VECTOR(34) <= x"02cd";
		PIPE5_VECTOR(35) <= x"02ce";
		PIPE5_VECTOR(36) <= x"02cf";
		PIPE5_VECTOR(37) <= x"02f5";
		PIPE5_VECTOR(38) <= x"02f6";
		PIPE5_VECTOR(39) <= x"02f7";
		PIPE5_VECTOR(40) <= x"031d";
		PIPE5_VECTOR(41) <= x"031e";
		PIPE5_VECTOR(42) <= x"031f";
		PIPE5_VECTOR(43) <= x"0344";
		PIPE5_VECTOR(44) <= x"0345";
		PIPE5_VECTOR(45) <= x"0346";
		PIPE5_VECTOR(46) <= x"0347";
		PIPE5_VECTOR(47) <= x"036d";
		PIPE5_VECTOR(48) <= x"036e";
		PIPE5_VECTOR(49) <= x"036f";
		PIPE5_VECTOR(50) <= x"0395";
		PIPE5_VECTOR(51) <= x"0396";
		PIPE5_VECTOR(52) <= x"0397";
		PIPE5_VECTOR(53) <= x"03bd";
		PIPE5_VECTOR(54) <= x"03be";
		PIPE5_VECTOR(55) <= x"03bf";
		PIPE5_VECTOR(56) <= x"03e5";
		PIPE5_VECTOR(57) <= x"03e6";
		PIPE5_VECTOR(58) <= x"03e7";
		PIPE5_VECTOR(59) <= x"040d";
		PIPE5_VECTOR(60) <= x"040e";
		PIPE5_VECTOR(61) <= x"040f";
		PIPE5_VECTOR(62) <= x"0435";
		PIPE5_VECTOR(63) <= x"0436";
		PIPE5_VECTOR(64) <= x"0437";
		PIPE5_VECTOR(65) <= x"045d";
		PIPE5_VECTOR(66) <= x"045e";
		PIPE5_VECTOR(67) <= x"045f";
		PIPE5_VECTOR(68) <= x"0485";
		PIPE5_VECTOR(69) <= x"0486";
		PIPE5_VECTOR(70) <= x"0487";
		PIPE5_VECTOR(71) <= x"04ad";
		PIPE5_VECTOR(72) <= x"04ae";
		PIPE5_VECTOR(73) <= x"04af";
		
		PIPE1_INDEX <= 0;
		PIPE2_INDEX <= 0;
		PIPE3_INDEX <= 0;
		PIPE4_INDEX <= 0;
		PIPE5_INDEX <= 0;
		
		-- Inicializar vetor de limpar tela
		CLEAR_VECTOR(0) <= x"0000";
		CLEAR_VECTOR(1) <= x"0001";
		CLEAR_VECTOR(2) <= x"0002";
		CLEAR_VECTOR(3) <= x"0003";
		CLEAR_VECTOR(4) <= x"0004";
		CLEAR_VECTOR(5) <= x"0005";
		CLEAR_VECTOR(6) <= x"0028";
		CLEAR_VECTOR(7) <= x"0029";
		CLEAR_VECTOR(8) <= x"002a";
		CLEAR_VECTOR(9) <= x"002b";
		CLEAR_VECTOR(10) <= x"002c";
		CLEAR_VECTOR(11) <= x"002d";
		CLEAR_VECTOR(12) <= x"0050";
		CLEAR_VECTOR(13) <= x"0051";
		CLEAR_VECTOR(14) <= x"0052";
		CLEAR_VECTOR(15) <= x"0053";
		CLEAR_VECTOR(16) <= x"0054";
		CLEAR_VECTOR(17) <= x"0055";
		CLEAR_VECTOR(18) <= x"0078";
		CLEAR_VECTOR(19) <= x"0079";
		CLEAR_VECTOR(20) <= x"007a";
		CLEAR_VECTOR(21) <= x"007b";
		CLEAR_VECTOR(22) <= x"007c";
		CLEAR_VECTOR(23) <= x"007d";
		CLEAR_VECTOR(24) <= x"00a0";
		CLEAR_VECTOR(25) <= x"00a1";
		CLEAR_VECTOR(26) <= x"00a2";
		CLEAR_VECTOR(27) <= x"00a3";
		CLEAR_VECTOR(28) <= x"00a4";
		CLEAR_VECTOR(29) <= x"00a5";
		CLEAR_VECTOR(30) <= x"00c8";
		CLEAR_VECTOR(31) <= x"00c9";
		CLEAR_VECTOR(32) <= x"00ca";
		CLEAR_VECTOR(33) <= x"00cb";
		CLEAR_VECTOR(34) <= x"00cc";
		CLEAR_VECTOR(35) <= x"00cd";
		CLEAR_VECTOR(36) <= x"00f0";
		CLEAR_VECTOR(37) <= x"00f1";
		CLEAR_VECTOR(38) <= x"00f2";
		CLEAR_VECTOR(39) <= x"00f3";
		CLEAR_VECTOR(40) <= x"00f4";
		CLEAR_VECTOR(41) <= x"00f5";
		CLEAR_VECTOR(42) <= x"0118";
		CLEAR_VECTOR(43) <= x"0119";
		CLEAR_VECTOR(44) <= x"011a";
		CLEAR_VECTOR(45) <= x"011b";
		CLEAR_VECTOR(46) <= x"011c";
		CLEAR_VECTOR(47) <= x"011d";
		CLEAR_VECTOR(48) <= x"0140";
		CLEAR_VECTOR(49) <= x"0141";
		CLEAR_VECTOR(50) <= x"0142";
		CLEAR_VECTOR(51) <= x"0143";
		CLEAR_VECTOR(52) <= x"0144";
		CLEAR_VECTOR(53) <= x"0145";
		CLEAR_VECTOR(54) <= x"0168";
		CLEAR_VECTOR(55) <= x"0169";
		CLEAR_VECTOR(56) <= x"016a";
		CLEAR_VECTOR(57) <= x"016b";
		CLEAR_VECTOR(58) <= x"016c";
		CLEAR_VECTOR(59) <= x"016d";
		CLEAR_VECTOR(60) <= x"0190";
		CLEAR_VECTOR(61) <= x"0191";
		CLEAR_VECTOR(62) <= x"0192";
		CLEAR_VECTOR(63) <= x"0193";
		CLEAR_VECTOR(64) <= x"0194";
		CLEAR_VECTOR(65) <= x"0195";
		CLEAR_VECTOR(66) <= x"01b8";
		CLEAR_VECTOR(67) <= x"01b9";
		CLEAR_VECTOR(68) <= x"01ba";
		CLEAR_VECTOR(69) <= x"01bb";
		CLEAR_VECTOR(70) <= x"01bc";
		CLEAR_VECTOR(71) <= x"01bd";
		CLEAR_VECTOR(72) <= x"01e0";
		CLEAR_VECTOR(73) <= x"01e1";
		CLEAR_VECTOR(74) <= x"01e2";
		CLEAR_VECTOR(75) <= x"01e3";
		CLEAR_VECTOR(76) <= x"01e4";
		CLEAR_VECTOR(77) <= x"01e5";
		CLEAR_VECTOR(78) <= x"0208";
		CLEAR_VECTOR(79) <= x"0209";
		CLEAR_VECTOR(80) <= x"020a";
		CLEAR_VECTOR(81) <= x"020b";
		CLEAR_VECTOR(82) <= x"020c";
		CLEAR_VECTOR(83) <= x"020d";
		CLEAR_VECTOR(84) <= x"0230";
		CLEAR_VECTOR(85) <= x"0231";
		CLEAR_VECTOR(86) <= x"0232";
		CLEAR_VECTOR(87) <= x"0233";
		CLEAR_VECTOR(88) <= x"0234";
		CLEAR_VECTOR(89) <= x"0235";
		CLEAR_VECTOR(90) <= x"0258";
		CLEAR_VECTOR(91) <= x"0259";
		CLEAR_VECTOR(92) <= x"025a";
		CLEAR_VECTOR(93) <= x"025b";
		CLEAR_VECTOR(94) <= x"025c";
		CLEAR_VECTOR(95) <= x"025d";
		CLEAR_VECTOR(96) <= x"0280";
		CLEAR_VECTOR(97) <= x"0281";
		CLEAR_VECTOR(98) <= x"0282";
		CLEAR_VECTOR(99) <= x"0283";
		CLEAR_VECTOR(100) <= x"0284";
		CLEAR_VECTOR(101) <= x"0285";
		CLEAR_VECTOR(102) <= x"02a8";
		CLEAR_VECTOR(103) <= x"02a9";
		CLEAR_VECTOR(104) <= x"02aa";
		CLEAR_VECTOR(105) <= x"02ab";
		CLEAR_VECTOR(106) <= x"02ac";
		CLEAR_VECTOR(107) <= x"02ad";
		CLEAR_VECTOR(108) <= x"02d0";
		CLEAR_VECTOR(109) <= x"02d1";
		CLEAR_VECTOR(110) <= x"02d2";
		CLEAR_VECTOR(111) <= x"02d3";
		CLEAR_VECTOR(112) <= x"02d4";
		CLEAR_VECTOR(113) <= x"02d5";
		CLEAR_VECTOR(114) <= x"02f8";
		CLEAR_VECTOR(115) <= x"02f9";
		CLEAR_VECTOR(116) <= x"02fa";
		CLEAR_VECTOR(117) <= x"02fb";
		CLEAR_VECTOR(118) <= x"02fc";
		CLEAR_VECTOR(119) <= x"02fd";
		CLEAR_VECTOR(120) <= x"0320";
		CLEAR_VECTOR(121) <= x"0321";
		CLEAR_VECTOR(122) <= x"0322";
		CLEAR_VECTOR(123) <= x"0323";
		CLEAR_VECTOR(124) <= x"0324";
		CLEAR_VECTOR(125) <= x"0325";
		CLEAR_VECTOR(126) <= x"0348";
		CLEAR_VECTOR(127) <= x"0349";
		CLEAR_VECTOR(128) <= x"034a";
		CLEAR_VECTOR(129) <= x"034b";
		CLEAR_VECTOR(130) <= x"034c";
		CLEAR_VECTOR(131) <= x"034d";
		CLEAR_VECTOR(132) <= x"0370";
		CLEAR_VECTOR(133) <= x"0371";
		CLEAR_VECTOR(134) <= x"0372";
		CLEAR_VECTOR(135) <= x"0373";
		CLEAR_VECTOR(136) <= x"0374";
		CLEAR_VECTOR(137) <= x"0375";
		CLEAR_VECTOR(138) <= x"0398";
		CLEAR_VECTOR(139) <= x"0399";
		CLEAR_VECTOR(140) <= x"039a";
		CLEAR_VECTOR(141) <= x"039b";
		CLEAR_VECTOR(142) <= x"039c";
		CLEAR_VECTOR(143) <= x"039d";
		CLEAR_VECTOR(144) <= x"03c0";
		CLEAR_VECTOR(145) <= x"03c1";
		CLEAR_VECTOR(146) <= x"03c2";
		CLEAR_VECTOR(147) <= x"03c3";
		CLEAR_VECTOR(148) <= x"03c4";
		CLEAR_VECTOR(149) <= x"03c5";
		CLEAR_VECTOR(150) <= x"03e8";
		CLEAR_VECTOR(151) <= x"03e9";
		CLEAR_VECTOR(152) <= x"03ea";
		CLEAR_VECTOR(153) <= x"03eb";
		CLEAR_VECTOR(154) <= x"03ec";
		CLEAR_VECTOR(155) <= x"03ed";
		CLEAR_VECTOR(156) <= x"0410";
		CLEAR_VECTOR(157) <= x"0411";
		CLEAR_VECTOR(158) <= x"0412";
		CLEAR_VECTOR(159) <= x"0413";
		CLEAR_VECTOR(160) <= x"0414";
		CLEAR_VECTOR(161) <= x"0415";
		CLEAR_VECTOR(162) <= x"0438";
		CLEAR_VECTOR(163) <= x"0439";
		CLEAR_VECTOR(164) <= x"043a";
		CLEAR_VECTOR(165) <= x"043b";
		CLEAR_VECTOR(166) <= x"043c";
		CLEAR_VECTOR(167) <= x"043d";
		CLEAR_VECTOR(168) <= x"0460";
		CLEAR_VECTOR(169) <= x"0461";
		CLEAR_VECTOR(170) <= x"0462";
		CLEAR_VECTOR(171) <= x"0463";
		CLEAR_VECTOR(172) <= x"0464";
		CLEAR_VECTOR(173) <= x"0465";
		CLEAR_VECTOR(174) <= x"0488";
		CLEAR_VECTOR(175) <= x"0489";
		CLEAR_VECTOR(176) <= x"048a";
		CLEAR_VECTOR(177) <= x"048b";
		CLEAR_VECTOR(178) <= x"048c";
		CLEAR_VECTOR(179) <= x"048d";
		
		INDEX_CLEAR <= 0;
		
	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS
			
			-------------------------------------------------
			-- Resetar tela
			-------------------------------------------------
			WHEN x"30" => -- Apaga tela

				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= "00000000";	-- Quadrado preenchido			
				vga_pos(15 downto 0)	<= RESET_POS;
				videoflag <= '1';

				VIDEOE <= x"31";

			-- Intermediário Reset
			WHEN x"31" =>
				videoflag <= '0';

				IF(RESET_POS > x"04AF") THEN
					RESET_POS <= x"0000";
					VIDEOE <= x"00";
				ELSE
					RESET_POS <= RESET_POS + x"01";
					VIDEOE <= x"30";
				END IF;
			
			-------------------------------------------------
			-- Desenhar Flippy
			-------------------------------------------------

			-- Apagar Flippy
			WHEN x"00" =>

				if(FLIPPY_POS_PREV = FLIPPY_POS) then -- Apenas apagar quando muda de posição

					-- Checar vitória
					IF (FLIPPY_VICTORY = 1) THEN
						VIDEOE <= x"34";
					ELSE
						-- Checar game over
						IF (FLIPPY_FLAG = x"01") THEN -- Se estiver morto, ir p/ desenhar Game Over
							VIDEOE <= x"04";
						ELSE
							VIDEOE <= x"00";
						END IF;
					END IF;
					
				else

				-- Apagar
				vga_char(15 downto 12) <= "0000";
				vga_char(11 downto 8) <= "1110"; -- Pintar de azul (fundo)
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado
				vga_pos(15 downto 0) <= FLIPPY_POS_PREV;
				
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
				FLIPPY_POS_PREV <= FLIPPY_POS; -- Atualizar posição

				videoflag <= '1';
				VIDEOE <= x"03";

			-- Intermediário Desenhar->Textos
			WHEN x"03" =>
				videoflag <= '0';				
				VIDEOE <= x"06";

			-------------------------------------------------
			-- Desenhar Textos
			-------------------------------------------------
			WHEN x"04" => -- Desenha GAME OVER NA TELA

				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= GAME_OVER(INDEX_GAMEOVER);				
				vga_pos(15 downto 0)	<= POSITION_GAMEOVER;
				
				videoflag <= '1';
				
				IF (FLIPPY_FLAG = x"00") THEN -- Flippy reviveu, resetar tela
					VIDEOE <= x"30";
				ELSE
					VIDEOE <= x"05";
				END IF;

			-- Intermediário
			WHEN x"05" =>
				videoflag <= '0';

				IF(POSITION_GAMEOVER > x"0247") THEN
					POSITION_GAMEOVER <= x"023F";
					INDEX_GAMEOVER <= 0;
				ELSE
					POSITION_GAMEOVER <= POSITION_GAMEOVER + x"01";
					INDEX_GAMEOVER <= INDEX_GAMEOVER + 1;
					VIDEOE <= x"04";
				END IF;
				VIDEOE <= x"04";

			WHEN x"34" => -- Desenha YOU WIN na tela

				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= VICTORY(INDEX_VICTORY);				
				vga_pos(15 downto 0)	<= POSITION_VICTORY;
				
				videoflag <= '1';
				
				IF (FLIPPY_VICTORY = x"00") THEN -- Flippy reviveu, resetar tela
					VIDEOE <= x"30";
				ELSE
					VIDEOE <= x"35";
				END IF;

			-- Intermediário Victory -> Resetar Tela
			WHEN x"35" =>
				videoflag <= '0';

				IF(POSITION_VICTORY > x"0246") THEN
					POSITION_VICTORY <= x"0240";
					INDEX_VICTORY <= 0;
				ELSE
					POSITION_VICTORY <= POSITION_VICTORY + x"01";
					INDEX_VICTORY <= INDEX_VICTORY + 1;
					VIDEOE <= x"34";
				END IF;
				VIDEOE <= x"34";

			-------------------------------------------------
			-- Desenhar Canos
			-------------------------------------------------
			
			-- Desenhar na vertical
			WHEN x"06" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "0010";
				
				CASE PIPE_TYPE IS
					
					WHEN 1 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE1_VECTOR(PIPE1_INDEX) - PIPE_OFFSET;
						
					WHEN 2 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE2_VECTOR(PIPE2_INDEX) - PIPE_OFFSET;
				
					WHEN 3 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE3_VECTOR(PIPE3_INDEX) - PIPE_OFFSET;
					
					WHEN 4 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE4_VECTOR(PIPE4_INDEX) - PIPE_OFFSET;
						
					WHEN 5 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE5_VECTOR(PIPE5_INDEX) - PIPE_OFFSET;
			
					WHEN OTHERS =>
					
				END CASE;

				videoflag <= '1';

				VIDEOE <= x"07";
			
			-- Intermediário
			WHEN x"07" =>
			
				CASE PIPE_TYPE IS
				
					WHEN 1 =>
							IF(PIPE1_INDEX < 58) THEN
								PIPE1_INDEX <= PIPE1_INDEX + 1;
								VIDEOE <= x"06";
							ELSE
								PIPE1_INDEX <= 0;
								VIDEOE <= x"08";
							END IF;

					WHEN 2 =>
							IF(PIPE2_INDEX < 57) THEN
								PIPE2_INDEX <= PIPE2_INDEX + 1;
								VIDEOE <= x"06";
							ELSE
								PIPE2_INDEX <= 0;
								VIDEOE <= x"08";
							END IF;
					
					WHEN 3 =>
							IF(PIPE3_INDEX < 63) THEN
								PIPE3_INDEX <= PIPE3_INDEX + 1;
								VIDEOE <= x"06";
							ELSE
								PIPE3_INDEX <= 0;
								VIDEOE <= x"08";
							END IF;
					
					WHEN 4 =>
							IF(PIPE4_INDEX < 66) THEN
								PIPE4_INDEX <= PIPE4_INDEX + 1;
								VIDEOE <= x"06";
							ELSE
								PIPE4_INDEX <= 0;
								VIDEOE <= x"08";
							END IF;
					
					WHEN 5 =>
							IF(PIPE5_INDEX < 74) THEN
								PIPE5_INDEX <= PIPE5_INDEX + 1;
								VIDEOE <= x"06";
							ELSE
								PIPE5_INDEX <= 0;
								VIDEOE <= x"08";
							END IF;
							
					WHEN OTHERS =>
				
				END CASE;
			
			-- Transição
			WHEN x"08" =>
				VIDEOE <= x"09";
			
			-- Apagar na Vertical
			WHEN x"09" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				
				CASE PIPE_TYPE IS
					
					WHEN 1 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE1_VECTOR(PIPE1_INDEX) - PIPE_OFFSET + x"03"; -- Apagar posição anterior
						
					WHEN 2 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE2_VECTOR(PIPE2_INDEX) - PIPE_OFFSET + x"03"; -- Apagar posição anterior
				
					WHEN 3 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE3_VECTOR(PIPE3_INDEX) - PIPE_OFFSET + x"03"; -- Apagar posição anterior
					
					WHEN 4 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE4_VECTOR(PIPE4_INDEX) - PIPE_OFFSET + x"03"; -- Apagar posição anterior
						
					WHEN 5 =>
						vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
						vga_pos(15 downto 0)	<= PIPE5_VECTOR(PIPE5_INDEX) - PIPE_OFFSET + x"03"; -- Apagar posição anterior
			
					WHEN OTHERS =>
			
				END CASE;
				
				videoflag <= '1';

				VIDEOE <= x"10";
			
			-- Transição
			WHEN x"10" =>
			
				CASE PIPE_TYPE IS
				
					WHEN 1 =>
							IF(PIPE1_INDEX < 58) THEN
								PIPE1_INDEX <= PIPE1_INDEX + 1;
								VIDEOE <= x"09";
							ELSE
								PIPE1_INDEX <= 0;
								VIDEOE <= x"32";
							END IF;

					WHEN 2 =>
							IF(PIPE2_INDEX < 57) THEN
								PIPE2_INDEX <= PIPE2_INDEX + 1;
								VIDEOE <= x"09";
							ELSE
								PIPE2_INDEX <= 0;
								VIDEOE <= x"32";
							END IF;
					
					WHEN 3 =>
							IF(PIPE3_INDEX < 63) THEN
								PIPE3_INDEX <= PIPE3_INDEX + 1;
								VIDEOE <= x"09";
							ELSE
								PIPE3_INDEX <= 0;
								VIDEOE <= x"32";
							END IF;
					
					WHEN 4 =>
							IF(PIPE4_INDEX < 66) THEN
								PIPE4_INDEX <= PIPE4_INDEX + 1;
								VIDEOE <= x"09";
							ELSE
								PIPE4_INDEX <= 0;
								VIDEOE <= x"32";
							END IF;
					
					WHEN 5 =>
							IF(PIPE5_INDEX < 74) THEN
								PIPE5_INDEX <= PIPE5_INDEX + 1;
								VIDEOE <= x"09";
							ELSE
								PIPE5_INDEX <= 0;
								VIDEOE <= x"32";
							END IF;
							
					WHEN OTHERS =>
				
				END CASE;
			
			-- Apagar tela
			WHEN x"32" => -- Apagar canto da tela (lixo do cano)
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= "00000000";			
				vga_pos(15 downto 0)	<= CLEAR_VECTOR(INDEX_CLEAR);	
				
				videoflag <= '1';
				
				VIDEOE <= x"33";
				
			-- Transição Apagar / Início
			WHEN x"33" =>
				IF (INDEX_CLEAR > 179) THEN -- Terminou de apagar, voltar
					INDEX_CLEAR <= 0;
					VIDEOE <= x"00";
				ELSE
					INDEX_CLEAR <= INDEX_CLEAR + 1; -- Continuar apagando
					VIDEOE <= x"32";
				END IF;
										
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
