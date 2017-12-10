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

	-------------------------------------------------
	-- CENÁRIO
	-------------------------------------------------
	SIGNAL BORDER : vector_screen;
	SIGNAL MOUNTAINS : vector_screen;
	SIGNAL DISPLAY : vector_screen;

	SIGNAL CLOUDS : vector_screen;
	SIGNAL CLOUDS_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CLOUDS_OFFSET : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL CLOUDS_DELAY : STD_LOGIC(31 DOWNTO 0);

	SIGNAL INDEX_SCENERY : integer;
	SIGNAL POSITION_SCENERY : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-------------------------------------------------
	-- FLIPPY
	-------------------------------------------------
	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Posição atual
	SIGNAL FLIPPY_POS_PREV  : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Posição anterior
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FLIPPY_COLOR : STD_LOGIC_VECTOR(3 DOWNTO 0);
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
	SIGNAL PIPE_VECTOR : vector_pos;
	SIGNAL PIPE_VECTOR_PREV : vector_pos;

	-- Variáveis para percorrer/desenhar vetor do cano
	SIGNAL PIPE_INDEX  	 : integer;
	SIGNAL PIPE_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL PIPE_OFFSET   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Estado atual do cano
	SIGNAL PIPE_STATE : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- Delay do cano
	SIGNAL PIPE_DELAY : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- Flag para mudar tipo de cano
	SIGNAL PIPE_TYPE : integer;

	-------------------------------------------------
	-- TEXTOS
	-------------------------------------------------
	-- Game Over
	SIGNAL GAME_OVER : vector;
	SIGNAL INDEX_GAMEOVER  	 : integer;
	SIGNAL POSITION_GAMEOVER   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Flippy Title
	SIGNAL TITLE : vector;
	SIGNAL INDEX_TITLE  	 : integer;
	SIGNAL POSITION_TITLE   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- Scoreboard
	SIGNAL SCORE : vector;
	SIGNAL INDEX_SCORE  	 : integer;
	SIGNAL POSITION_SCORE   : STD_LOGIC_VECTOR(15 DOWNTO 0);

	--DESENHAR ARRAY
	-------------------------------------------------

-------------------------------------------------
-- GAME LOOP
-------------------------------------------------
BEGIN

-------------------------------------------------
-- NUVEM
-------------------------------------------------
PROCESS (clk, reset)

	BEGIN

	IF RESET = '1' THEN
		CLOUDS_DELAY <= x"00000000";
		CLOUD_STATE <= x"00";
		CLOUDS_OFFSET <= x"0000";
		
	ELSIF (clk'event) and (clk = '1') THEN

		CASE CLOUDS_STATE IS

			WHEN x"00" => -- Estado de movimentação
				-- Ir para esquerda
				CLOUDS_OFFSET <= CLOUDS_OFFSET + x"01"; -- Movimentar offset para a esquerda
				CASE key IS
					WHEN x"0D" => -- ENTER = RESET
						CLOUDS_DELAY <= x"00000000";
						CLOUDS_STATE <= x"00";
						CLOUDS_OFFSET <= x"0000";
					WHEN OTHERS =>
				END CASE;
				
				IF (CLOUDS_OFFSET > x"0027") THEN -- Limite esquerdo
					CLOUDS_OFFSET <= x"0000"; -- Resetar
				END IF;
				
				CLOUDS_STATE <= x"02";

			WHEN x"02" => -- Delay
				-- Delay máximo, voltar à ação
				IF CLOUDS_DELAY >=  x"0000EFFF" THEN
					CLOUDS_DELAY <= x"00000000";
					CLOUDS_STATE <= x"00";
				ELSE
				-- Aumentar delay
					CLOUDS_DELAY <= CLOUDS_DELAY + x"01";
				END IF;

			WHEN OTHERS =>
		END CASE;
	END IF;
END PROCESS;

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
						FLIPPY_STATE <= x"02";
					WHEN OTHERS =>
				END CASE;
			
			-- Checar colisão com posições do cano
			for I in 0 to 8 loop
				if (FLIPPY_POS = PIPE_VECTOR(I) - PIPE_OFFSET) then
					-- COLIDIU!
					FLIPPY_FLAG <= x"01"; -- MORTO
					FLIPPY_STATE <= x"03";
				end if;
			end loop;

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
				FLIPPY_COLOR <= "1001"; -- Vermelho
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
					WHEN OTHERS =>
				END CASE;
				
				IF (PIPE_OFFSET > x"0027") THEN -- Limite esquerdo
					PIPE_OFFSET <= x"0000"; -- Resetar
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
		VIDEOE <= x"00";
		videoflag <= '0';

		-------------------------------------------------
		-- Inicializar Flippy
		-------------------------------------------------
		FLIPPY_POS_PREV <= x"0000";

		-------------------------------------------------
		-- Inicializar Cenário
		-------------------------------------------------

		-- Montanhas
		MOUNTAIN_VECTOR(0) <= x"0396";
		MOUNTAIN_VECTOR(1) <= x"0397";
		MOUNTAIN_VECTOR(2) <= x"039b";
		MOUNTAIN_VECTOR(3) <= x"039c";
		MOUNTAIN_VECTOR(4) <= x"039d";
		MOUNTAIN_VECTOR(5) <= x"039e";
		MOUNTAIN_VECTOR(6) <= x"039f";
		MOUNTAIN_VECTOR(7) <= x"03a9";
		MOUNTAIN_VECTOR(8) <= x"03aa";
		MOUNTAIN_VECTOR(9) <= x"03ab";
		MOUNTAIN_VECTOR(10) <= x"03ac";
		MOUNTAIN_VECTOR(11) <= x"03ad";
		MOUNTAIN_VECTOR(12) <= x"03ae";
		MOUNTAIN_VECTOR(13) <= x"03b5";
		MOUNTAIN_VECTOR(14) <= x"03b6";
		MOUNTAIN_VECTOR(15) <= x"03b7";
		MOUNTAIN_VECTOR(16) <= x"03b8";
		MOUNTAIN_VECTOR(17) <= x"03b9";
		MOUNTAIN_VECTOR(18) <= x"03bd";
		MOUNTAIN_VECTOR(19) <= x"03be";
		MOUNTAIN_VECTOR(20) <= x"03bf";
		MOUNTAIN_VECTOR(21) <= x"03c1";
		MOUNTAIN_VECTOR(22) <= x"03c2";
		MOUNTAIN_VECTOR(23) <= x"03c3";
		MOUNTAIN_VECTOR(24) <= x"03c4";
		MOUNTAIN_VECTOR(25) <= x"03c5";
		MOUNTAIN_VECTOR(26) <= x"03c6";
		MOUNTAIN_VECTOR(27) <= x"03c7";
		MOUNTAIN_VECTOR(28) <= x"03c8";
		MOUNTAIN_VECTOR(29) <= x"03c9";
		MOUNTAIN_VECTOR(30) <= x"03cf";
		MOUNTAIN_VECTOR(31) <= x"03d0";
		MOUNTAIN_VECTOR(32) <= x"03d1";
		MOUNTAIN_VECTOR(33) <= x"03d2";
		MOUNTAIN_VECTOR(34) <= x"03d3";
		MOUNTAIN_VECTOR(35) <= x"03d4";
		MOUNTAIN_VECTOR(36) <= x"03d5";
		MOUNTAIN_VECTOR(37) <= x"03d6";
		MOUNTAIN_VECTOR(38) <= x"03d7";
		MOUNTAIN_VECTOR(39) <= x"03d8";
		MOUNTAIN_VECTOR(40) <= x"03db";
		MOUNTAIN_VECTOR(41) <= x"03dc";
		MOUNTAIN_VECTOR(42) <= x"03dd";
		MOUNTAIN_VECTOR(43) <= x"03de";
		MOUNTAIN_VECTOR(44) <= x"03df";
		MOUNTAIN_VECTOR(45) <= x"03e0";
		MOUNTAIN_VECTOR(46) <= x"03e1";
		MOUNTAIN_VECTOR(47) <= x"03e2";
		MOUNTAIN_VECTOR(48) <= x"03e3";
		MOUNTAIN_VECTOR(49) <= x"03e4";
		MOUNTAIN_VECTOR(50) <= x"03e5";
		MOUNTAIN_VECTOR(51) <= x"03e6";
		MOUNTAIN_VECTOR(52) <= x"03e7";
		MOUNTAIN_VECTOR(53) <= x"03e8";
		MOUNTAIN_VECTOR(54) <= x"03e9";
		MOUNTAIN_VECTOR(55) <= x"03ea";
		MOUNTAIN_VECTOR(56) <= x"03eb";
		MOUNTAIN_VECTOR(57) <= x"03ec";
		MOUNTAIN_VECTOR(58) <= x"03ed";
		MOUNTAIN_VECTOR(59) <= x"03ee";
		MOUNTAIN_VECTOR(60) <= x"03ef";
		MOUNTAIN_VECTOR(61) <= x"03f0";
		MOUNTAIN_VECTOR(62) <= x"03f1";
		MOUNTAIN_VECTOR(63) <= x"03f2";
		MOUNTAIN_VECTOR(64) <= x"03f6";
		MOUNTAIN_VECTOR(65) <= x"03f7";
		MOUNTAIN_VECTOR(66) <= x"03f8";
		MOUNTAIN_VECTOR(67) <= x"03f9";
		MOUNTAIN_VECTOR(68) <= x"03fa";
		MOUNTAIN_VECTOR(69) <= x"03fb";
		MOUNTAIN_VECTOR(70) <= x"03fc";
		MOUNTAIN_VECTOR(71) <= x"03fd";
		MOUNTAIN_VECTOR(72) <= x"03fe";
		MOUNTAIN_VECTOR(73) <= x"03ff";
		MOUNTAIN_VECTOR(74) <= x"0400";
		MOUNTAIN_VECTOR(75) <= x"0401";
		MOUNTAIN_VECTOR(76) <= x"0402";
		MOUNTAIN_VECTOR(77) <= x"0403";
		MOUNTAIN_VECTOR(78) <= x"0404";
		MOUNTAIN_VECTOR(79) <= x"0405";
		MOUNTAIN_VECTOR(80) <= x"0406";
		MOUNTAIN_VECTOR(81) <= x"0407";
		MOUNTAIN_VECTOR(82) <= x"0408";
		MOUNTAIN_VECTOR(83) <= x"0409";
		MOUNTAIN_VECTOR(84) <= x"040a";
		MOUNTAIN_VECTOR(85) <= x"040b";
		MOUNTAIN_VECTOR(86) <= x"040c";
		MOUNTAIN_VECTOR(87) <= x"040d";
		MOUNTAIN_VECTOR(88) <= x"040e";
		MOUNTAIN_VECTOR(89) <= x"040f";
		MOUNTAIN_VECTOR(90) <= x"0410";
		MOUNTAIN_VECTOR(91) <= x"0411";
		MOUNTAIN_VECTOR(92) <= x"0412";
		MOUNTAIN_VECTOR(93) <= x"0413";
		MOUNTAIN_VECTOR(94) <= x"0414";
		MOUNTAIN_VECTOR(95) <= x"0415";
		MOUNTAIN_VECTOR(96) <= x"0416";
		MOUNTAIN_VECTOR(97) <= x"0417";
		MOUNTAIN_VECTOR(98) <= x"0418";
		MOUNTAIN_VECTOR(99) <= x"0419";
		MOUNTAIN_VECTOR(100) <= x"041a";
		MOUNTAIN_VECTOR(101) <= x"041b";
		MOUNTAIN_VECTOR(102) <= x"041c";
		MOUNTAIN_VECTOR(103) <= x"041d";
		MOUNTAIN_VECTOR(104) <= x"041e";
		MOUNTAIN_VECTOR(105) <= x"041f";
		MOUNTAIN_VECTOR(106) <= x"0420";
		MOUNTAIN_VECTOR(107) <= x"0421";
		MOUNTAIN_VECTOR(108) <= x"0422";
		MOUNTAIN_VECTOR(109) <= x"0423";
		MOUNTAIN_VECTOR(110) <= x"0424";
		MOUNTAIN_VECTOR(111) <= x"0425";
		MOUNTAIN_VECTOR(112) <= x"0426";
		MOUNTAIN_VECTOR(113) <= x"0427";
		MOUNTAIN_VECTOR(114) <= x"0428";
		MOUNTAIN_VECTOR(115) <= x"0429";
		MOUNTAIN_VECTOR(116) <= x"042a";
		MOUNTAIN_VECTOR(117) <= x"042b";
		MOUNTAIN_VECTOR(118) <= x"042c";
		MOUNTAIN_VECTOR(119) <= x"042d";
		MOUNTAIN_VECTOR(120) <= x"042e";
		MOUNTAIN_VECTOR(121) <= x"042f";
		MOUNTAIN_VECTOR(122) <= x"0430";
		MOUNTAIN_VECTOR(123) <= x"0431";
		MOUNTAIN_VECTOR(124) <= x"0432";
		MOUNTAIN_VECTOR(125) <= x"0433";
		MOUNTAIN_VECTOR(126) <= x"0434";
		MOUNTAIN_VECTOR(127) <= x"0435";
		MOUNTAIN_VECTOR(128) <= x"0436";
		MOUNTAIN_VECTOR(129) <= x"0437";
		MOUNTAIN_VECTOR(130) <= x"0438";
		MOUNTAIN_VECTOR(131) <= x"0439";
		MOUNTAIN_VECTOR(132) <= x"043a";
		MOUNTAIN_VECTOR(133) <= x"043b";
		MOUNTAIN_VECTOR(134) <= x"043c";
		MOUNTAIN_VECTOR(135) <= x"043d";
		MOUNTAIN_VECTOR(136) <= x"043e";
		MOUNTAIN_VECTOR(137) <= x"043f";
		MOUNTAIN_VECTOR(138) <= x"0440";
		MOUNTAIN_VECTOR(139) <= x"0441";
		MOUNTAIN_VECTOR(140) <= x"0442";
		MOUNTAIN_VECTOR(141) <= x"0443";
		MOUNTAIN_VECTOR(142) <= x"0444";
		MOUNTAIN_VECTOR(143) <= x"0445";
		MOUNTAIN_VECTOR(144) <= x"0446";
		MOUNTAIN_VECTOR(145) <= x"0447";
		MOUNTAIN_VECTOR(146) <= x"0448";
		MOUNTAIN_VECTOR(147) <= x"0449";
		MOUNTAIN_VECTOR(148) <= x"044a";
		MOUNTAIN_VECTOR(149) <= x"044b";
		MOUNTAIN_VECTOR(150) <= x"044c";
		MOUNTAIN_VECTOR(151) <= x"044d";
		MOUNTAIN_VECTOR(152) <= x"044e";
		MOUNTAIN_VECTOR(153) <= x"044f";
		MOUNTAIN_VECTOR(154) <= x"0450";
		MOUNTAIN_VECTOR(155) <= x"0451";
		MOUNTAIN_VECTOR(156) <= x"0452";
		MOUNTAIN_VECTOR(157) <= x"0453";
		MOUNTAIN_VECTOR(158) <= x"0454";
		MOUNTAIN_VECTOR(159) <= x"0455";
		MOUNTAIN_VECTOR(160) <= x"0456";
		MOUNTAIN_VECTOR(161) <= x"0457";
		MOUNTAIN_VECTOR(162) <= x"0458";
		MOUNTAIN_VECTOR(163) <= x"0459";
		MOUNTAIN_VECTOR(164) <= x"045a";
		MOUNTAIN_VECTOR(165) <= x"045b";
		MOUNTAIN_VECTOR(166) <= x"045c";
		MOUNTAIN_VECTOR(167) <= x"045d";
		MOUNTAIN_VECTOR(168) <= x"045e";
		MOUNTAIN_VECTOR(169) <= x"045f";
		MOUNTAIN_VECTOR(170) <= x"0460";
		MOUNTAIN_VECTOR(171) <= x"0461";
		MOUNTAIN_VECTOR(172) <= x"0462";
		MOUNTAIN_VECTOR(173) <= x"0463";
		MOUNTAIN_VECTOR(174) <= x"0464";
		MOUNTAIN_VECTOR(175) <= x"0465";
		MOUNTAIN_VECTOR(176) <= x"0466";
		MOUNTAIN_VECTOR(177) <= x"0467";
		MOUNTAIN_VECTOR(178) <= x"0468";
		MOUNTAIN_VECTOR(179) <= x"0469";
		MOUNTAIN_VECTOR(180) <= x"046a";
		MOUNTAIN_VECTOR(181) <= x"046b";
		MOUNTAIN_VECTOR(182) <= x"046c";
		MOUNTAIN_VECTOR(183) <= x"046d";
		MOUNTAIN_VECTOR(184) <= x"046e";
		MOUNTAIN_VECTOR(185) <= x"046f";
		MOUNTAIN_VECTOR(186) <= x"0470";
		MOUNTAIN_VECTOR(187) <= x"0471";
		MOUNTAIN_VECTOR(188) <= x"0472";
		MOUNTAIN_VECTOR(189) <= x"0473";
		MOUNTAIN_VECTOR(190) <= x"0474";
		MOUNTAIN_VECTOR(191) <= x"0475";
		MOUNTAIN_VECTOR(192) <= x"0476";
		MOUNTAIN_VECTOR(193) <= x"0477";
		MOUNTAIN_VECTOR(194) <= x"0478";
		MOUNTAIN_VECTOR(195) <= x"0479";
		MOUNTAIN_VECTOR(196) <= x"047a";
		MOUNTAIN_VECTOR(197) <= x"047b";
		MOUNTAIN_VECTOR(198) <= x"047c";
		MOUNTAIN_VECTOR(199) <= x"047d";
		MOUNTAIN_VECTOR(200) <= x"047e";
		MOUNTAIN_VECTOR(201) <= x"047f";
		MOUNTAIN_VECTOR(202) <= x"0480";
		MOUNTAIN_VECTOR(203) <= x"0481";
		MOUNTAIN_VECTOR(204) <= x"0482";
		MOUNTAIN_VECTOR(205) <= x"0483";
		MOUNTAIN_VECTOR(206) <= x"0484";
		MOUNTAIN_VECTOR(207) <= x"0485";
		MOUNTAIN_VECTOR(208) <= x"0486";
		MOUNTAIN_VECTOR(209) <= x"0487";
		MOUNTAIN_VECTOR(210) <= x"0488";
		MOUNTAIN_VECTOR(211) <= x"0489";
		MOUNTAIN_VECTOR(212) <= x"048a";
		MOUNTAIN_VECTOR(213) <= x"048b";
		MOUNTAIN_VECTOR(214) <= x"048c";
		MOUNTAIN_VECTOR(215) <= x"048d";
		MOUNTAIN_VECTOR(216) <= x"048e";
		MOUNTAIN_VECTOR(217) <= x"048f";
		MOUNTAIN_VECTOR(218) <= x"0490";
		MOUNTAIN_VECTOR(219) <= x"0491";
		MOUNTAIN_VECTOR(220) <= x"0492";
		MOUNTAIN_VECTOR(221) <= x"0493";
		MOUNTAIN_VECTOR(222) <= x"0494";
		MOUNTAIN_VECTOR(223) <= x"0495";
		MOUNTAIN_VECTOR(224) <= x"0496";
		MOUNTAIN_VECTOR(225) <= x"0497";
		MOUNTAIN_VECTOR(226) <= x"0498";
		MOUNTAIN_VECTOR(227) <= x"0499";
		MOUNTAIN_VECTOR(228) <= x"049a";
		MOUNTAIN_VECTOR(229) <= x"049b";
		MOUNTAIN_VECTOR(230) <= x"049c";
		MOUNTAIN_VECTOR(231) <= x"049d";
		MOUNTAIN_VECTOR(232) <= x"049e";
		MOUNTAIN_VECTOR(233) <= x"049f";
		MOUNTAIN_VECTOR(234) <= x"04a0";
		MOUNTAIN_VECTOR(235) <= x"04a1";
		MOUNTAIN_VECTOR(236) <= x"04a2";
		MOUNTAIN_VECTOR(237) <= x"04a3";
		MOUNTAIN_VECTOR(238) <= x"04a4";
		MOUNTAIN_VECTOR(239) <= x"04a5";
		MOUNTAIN_VECTOR(240) <= x"04a6";
		MOUNTAIN_VECTOR(241) <= x"04a7";
		MOUNTAIN_VECTOR(242) <= x"04a8";
		MOUNTAIN_VECTOR(243) <= x"04a9";
		MOUNTAIN_VECTOR(244) <= x"04aa";
		MOUNTAIN_VECTOR(245) <= x"04ab";
		MOUNTAIN_VECTOR(246) <= x"04ac";
		MOUNTAIN_VECTOR(247) <= x"04ad";
		MOUNTAIN_VECTOR(248) <= x"04ae";
		MOUNTAIN_VECTOR(249) <= x"04af";

		-- Nuvens
		CLOUD_VECTOR(0) <= x"0071";
		CLOUD_VECTOR(1) <= x"0072";
		CLOUD_VECTOR(2) <= x"0073";
		CLOUD_VECTOR(3) <= x"0074";
		CLOUD_VECTOR(4) <= x"007d";
		CLOUD_VECTOR(5) <= x"007e";
		CLOUD_VECTOR(6) <= x"007f";
		CLOUD_VECTOR(7) <= x"0080";
		CLOUD_VECTOR(8) <= x"0081";
		CLOUD_VECTOR(9) <= x"0098";
		CLOUD_VECTOR(10) <= x"0099";
		CLOUD_VECTOR(11) <= x"009a";
		CLOUD_VECTOR(12) <= x"009b";
		CLOUD_VECTOR(13) <= x"009c";
		CLOUD_VECTOR(14) <= x"009d";
		CLOUD_VECTOR(15) <= x"00a3";
		CLOUD_VECTOR(16) <= x"00a4";
		CLOUD_VECTOR(17) <= x"00a5";
		CLOUD_VECTOR(18) <= x"00a6";
		CLOUD_VECTOR(19) <= x"00a7";
		CLOUD_VECTOR(20) <= x"00a8";
		CLOUD_VECTOR(21) <= x"00a9";
		CLOUD_VECTOR(22) <= x"00aa";
		CLOUD_VECTOR(23) <= x"00c1";
		CLOUD_VECTOR(24) <= x"00c2";
		CLOUD_VECTOR(25) <= x"00c3";
		CLOUD_VECTOR(26) <= x"00c4";
		CLOUD_VECTOR(27) <= x"00ca";
		CLOUD_VECTOR(28) <= x"00cb";
		CLOUD_VECTOR(29) <= x"00cc";
		CLOUD_VECTOR(30) <= x"00cd";
		CLOUD_VECTOR(31) <= x"00ce";
		CLOUD_VECTOR(32) <= x"00cf";
		CLOUD_VECTOR(33) <= x"00d0";
		CLOUD_VECTOR(34) <= x"00d1";
		CLOUD_VECTOR(35) <= x"00d2";
		CLOUD_VECTOR(36) <= x"00d3";
		CLOUD_VECTOR(37) <= x"00df";
		CLOUD_VECTOR(38) <= x"00e0";
		CLOUD_VECTOR(39) <= x"00e1";
		CLOUD_VECTOR(40) <= x"00e2";
		CLOUD_VECTOR(41) <= x"00e3";
		CLOUD_VECTOR(42) <= x"00ea";
		CLOUD_VECTOR(43) <= x"00eb";
		CLOUD_VECTOR(44) <= x"00f3";
		CLOUD_VECTOR(45) <= x"00f4";
		CLOUD_VECTOR(46) <= x"00f5";
		CLOUD_VECTOR(47) <= x"00f6";
		CLOUD_VECTOR(48) <= x"00f7";
		CLOUD_VECTOR(49) <= x"00f8";
		CLOUD_VECTOR(50) <= x"00f9";
		CLOUD_VECTOR(51) <= x"00fa";
		CLOUD_VECTOR(52) <= x"00fb";
		CLOUD_VECTOR(53) <= x"00fc";
		CLOUD_VECTOR(54) <= x"0106";
		CLOUD_VECTOR(55) <= x"0107";
		CLOUD_VECTOR(56) <= x"0108";
		CLOUD_VECTOR(57) <= x"0109";
		CLOUD_VECTOR(58) <= x"010a";
		CLOUD_VECTOR(59) <= x"010b";
		CLOUD_VECTOR(60) <= x"010c";
		CLOUD_VECTOR(61) <= x"011d";
		CLOUD_VECTOR(62) <= x"011e";
		CLOUD_VECTOR(63) <= x"011f";
		CLOUD_VECTOR(64) <= x"0120";
		CLOUD_VECTOR(65) <= x"0121";
		CLOUD_VECTOR(66) <= x"0122";
		CLOUD_VECTOR(67) <= x"0123";
		CLOUD_VECTOR(68) <= x"012c";
		CLOUD_VECTOR(69) <= x"012d";
		CLOUD_VECTOR(70) <= x"012e";
		CLOUD_VECTOR(71) <= x"012f";
		CLOUD_VECTOR(72) <= x"0130";
		CLOUD_VECTOR(73) <= x"0131";
		CLOUD_VECTOR(74) <= x"0132";
		CLOUD_VECTOR(75) <= x"0133";
		CLOUD_VECTOR(76) <= x"0134";
		CLOUD_VECTOR(77) <= x"0135";
		CLOUD_VECTOR(78) <= x"0153";
		CLOUD_VECTOR(79) <= x"0154";
		CLOUD_VECTOR(80) <= x"0155";
		CLOUD_VECTOR(81) <= x"0156";
		CLOUD_VECTOR(82) <= x"0157";
		CLOUD_VECTOR(83) <= x"0158";
		CLOUD_VECTOR(84) <= x"0159";
		CLOUD_VECTOR(85) <= x"015a";
		CLOUD_VECTOR(86) <= x"015b";
		CLOUD_VECTOR(87) <= x"015c";
		CLOUD_VECTOR(88) <= x"015d";
		CLOUD_VECTOR(89) <= x"015e";
		CLOUD_VECTOR(90) <= x"017c";
		CLOUD_VECTOR(91) <= x"017d";
		CLOUD_VECTOR(92) <= x"017e";
		CLOUD_VECTOR(93) <= x"017f";
		CLOUD_VECTOR(94) <= x"0180";
		CLOUD_VECTOR(95) <= x"0181";
		CLOUD_VECTOR(96) <= x"0182";
		CLOUD_VECTOR(97) <= x"0183";
		CLOUD_VECTOR(98) <= x"0184";
		CLOUD_VECTOR(99) <= x"0185";
		CLOUD_VECTOR(100) <= x"0186";
		CLOUD_VECTOR(101) <= x"01a5";
		CLOUD_VECTOR(102) <= x"01a6";
		CLOUD_VECTOR(103) <= x"01a7";
		CLOUD_VECTOR(104) <= x"01a8";
		CLOUD_VECTOR(105) <= x"01a9";
		CLOUD_VECTOR(106) <= x"01aa";
		CLOUD_VECTOR(107) <= x"01ab";
		CLOUD_VECTOR(108) <= x"01ac";
		CLOUD_VECTOR(109) <= x"01ad";

		-- Display / Borda
		BORDER(0) <= x"0000";
		BORDER(1) <= x"0001";
		BORDER(2) <= x"0002";
		BORDER(3) <= x"0003";
		BORDER(4) <= x"0004";
		BORDER(5) <= x"0005";
		BORDER(6) <= x"0006";
		BORDER(7) <= x"0007";
		BORDER(8) <= x"0008";
		BORDER(9) <= x"0009";
		BORDER(10) <= x"000a";
		BORDER(11) <= x"000b";
		BORDER(12) <= x"000c";
		BORDER(13) <= x"000d";
		BORDER(14) <= x"000e";
		BORDER(15) <= x"000f";
		BORDER(16) <= x"0010";
		BORDER(17) <= x"0011";
		BORDER(18) <= x"0012";
		BORDER(19) <= x"0013";
		BORDER(20) <= x"0014";
		BORDER(21) <= x"0015";
		BORDER(22) <= x"0016";
		BORDER(23) <= x"0017";
		BORDER(24) <= x"0018";
		BORDER(25) <= x"0019";
		BORDER(26) <= x"001a";
		BORDER(27) <= x"001b";
		BORDER(28) <= x"001c";
		BORDER(29) <= x"001d";
		BORDER(30) <= x"001e";
		BORDER(31) <= x"001f";
		BORDER(32) <= x"0020";
		BORDER(33) <= x"0021";
		BORDER(34) <= x"0022";
		BORDER(35) <= x"0023";
		BORDER(36) <= x"0024";
		BORDER(37) <= x"0025";
		BORDER(38) <= x"0026";
		BORDER(39) <= x"0027";
		BORDER(40) <= x"0028";
		BORDER(41) <= x"0029";
		BORDER(42) <= x"002a";
		BORDER(43) <= x"002b";
		BORDER(44) <= x"002c";
		BORDER(45) <= x"002d";
		BORDER(46) <= x"002e";
		BORDER(47) <= x"002f";
		BORDER(48) <= x"0030";
		BORDER(49) <= x"0031";
		BORDER(50) <= x"0032";
		BORDER(51) <= x"0033";
		BORDER(52) <= x"0034";
		BORDER(53) <= x"0035";
		BORDER(54) <= x"0036";
		BORDER(55) <= x"0037";
		BORDER(56) <= x"0038";
		BORDER(57) <= x"0039";
		BORDER(58) <= x"003a";
		BORDER(59) <= x"003b";
		BORDER(60) <= x"003c";
		BORDER(61) <= x"003d";
		BORDER(62) <= x"003e";
		BORDER(63) <= x"003f";
		BORDER(64) <= x"0040";
		BORDER(65) <= x"0041";
		BORDER(66) <= x"0042";
		BORDER(67) <= x"0043";
		BORDER(68) <= x"0044";
		BORDER(69) <= x"0045";
		BORDER(70) <= x"0046";
		BORDER(71) <= x"0047";
		BORDER(72) <= x"0048";
		BORDER(73) <= x"0049";
		BORDER(74) <= x"004a";
		BORDER(75) <= x"004b";
		BORDER(76) <= x"004c";
		BORDER(77) <= x"004d";
		BORDER(78) <= x"004e";
		BORDER(79) <= x"004f";
		BORDER(80) <= x"0050";
		BORDER(81) <= x"0051";
		BORDER(82) <= x"0052";
		BORDER(83) <= x"0053";
		BORDER(84) <= x"0054";
		BORDER(85) <= x"0055";
		BORDER(86) <= x"0056";
		BORDER(87) <= x"0057";
		BORDER(88) <= x"0058";
		BORDER(89) <= x"0059";
		BORDER(90) <= x"005a";
		BORDER(91) <= x"005b";
		BORDER(92) <= x"005c";
		BORDER(93) <= x"005d";
		BORDER(94) <= x"005e";
		BORDER(95) <= x"005f";
		BORDER(96) <= x"0060";
		BORDER(97) <= x"0061";
		BORDER(98) <= x"0062";
		BORDER(99) <= x"0063";
		BORDER(100) <= x"0064";
		BORDER(101) <= x"0065";
		BORDER(102) <= x"0066";
		BORDER(103) <= x"0067";
		BORDER(104) <= x"0068";
		BORDER(105) <= x"0069";
		BORDER(106) <= x"006a";
		BORDER(107) <= x"006b";
		BORDER(108) <= x"006c";
		BORDER(109) <= x"006d";
		BORDER(110) <= x"006e";
		BORDER(111) <= x"006f";
		BORDER(112) <= x"0070";
		BORDER(113) <= x"0071";
		BORDER(114) <= x"0072";
		BORDER(115) <= x"0073";
		BORDER(116) <= x"0074";
		BORDER(117) <= x"0075";
		BORDER(118) <= x"0076";
		BORDER(119) <= x"0077";
		BORDER(120) <= x"0078";
		BORDER(121) <= x"0079";
		BORDER(122) <= x"007a";
		BORDER(123) <= x"009d";
		BORDER(124) <= x"009e";
		BORDER(125) <= x"009f";
		BORDER(126) <= x"00a0";
		BORDER(127) <= x"00a1";
		BORDER(128) <= x"00a2";
		BORDER(129) <= x"00c5";
		BORDER(130) <= x"00c6";
		BORDER(131) <= x"00c7";
		BORDER(132) <= x"00c8";
		BORDER(133) <= x"00c9";
		BORDER(134) <= x"00ca";
		BORDER(135) <= x"00ed";
		BORDER(136) <= x"00ee";
		BORDER(137) <= x"00ef";
		BORDER(138) <= x"00f0";
		BORDER(139) <= x"00f1";
		BORDER(140) <= x"00f2";
		BORDER(141) <= x"0115";
		BORDER(142) <= x"0116";
		BORDER(143) <= x"0117";
		BORDER(144) <= x"0118";
		BORDER(145) <= x"0119";
		BORDER(146) <= x"011a";
		BORDER(147) <= x"013d";
		BORDER(148) <= x"013e";
		BORDER(149) <= x"013f";
		BORDER(150) <= x"0140";
		BORDER(151) <= x"0141";
		BORDER(152) <= x"0142";
		BORDER(153) <= x"0165";
		BORDER(154) <= x"0166";
		BORDER(155) <= x"0167";
		BORDER(156) <= x"0168";
		BORDER(157) <= x"0169";
		BORDER(158) <= x"016a";
		BORDER(159) <= x"018d";
		BORDER(160) <= x"018e";
		BORDER(161) <= x"018f";
		BORDER(162) <= x"0190";
		BORDER(163) <= x"0191";
		BORDER(164) <= x"0192";
		BORDER(165) <= x"01b5";
		BORDER(166) <= x"01b6";
		BORDER(167) <= x"01b7";
		BORDER(168) <= x"01b8";
		BORDER(169) <= x"01b9";
		BORDER(170) <= x"01ba";
		BORDER(171) <= x"01dd";
		BORDER(172) <= x"01de";
		BORDER(173) <= x"01df";
		BORDER(174) <= x"01e0";
		BORDER(175) <= x"01e1";
		BORDER(176) <= x"01e2";
		BORDER(177) <= x"0205";
		BORDER(178) <= x"0206";
		BORDER(179) <= x"0207";
		BORDER(180) <= x"0208";
		BORDER(181) <= x"0209";
		BORDER(182) <= x"020a";
		BORDER(183) <= x"022d";
		BORDER(184) <= x"022e";
		BORDER(185) <= x"022f";
		BORDER(186) <= x"0230";
		BORDER(187) <= x"0231";
		BORDER(188) <= x"0232";
		BORDER(189) <= x"0255";
		BORDER(190) <= x"0256";
		BORDER(191) <= x"0257";
		BORDER(192) <= x"0258";
		BORDER(193) <= x"0259";
		BORDER(194) <= x"025a";
		BORDER(195) <= x"027d";
		BORDER(196) <= x"027e";
		BORDER(197) <= x"027f";
		BORDER(198) <= x"0280";
		BORDER(199) <= x"0281";
		BORDER(200) <= x"0282";
		BORDER(201) <= x"02a5";
		BORDER(202) <= x"02a6";
		BORDER(203) <= x"02a7";
		BORDER(204) <= x"02a8";
		BORDER(205) <= x"02a9";
		BORDER(206) <= x"02aa";
		BORDER(207) <= x"02cd";
		BORDER(208) <= x"02ce";
		BORDER(209) <= x"02cf";
		BORDER(210) <= x"02d0";
		BORDER(211) <= x"02d1";
		BORDER(212) <= x"02d2";
		BORDER(213) <= x"02f5";
		BORDER(214) <= x"02f6";
		BORDER(215) <= x"02f7";
		BORDER(216) <= x"02f8";
		BORDER(217) <= x"02f9";
		BORDER(218) <= x"02fa";
		BORDER(219) <= x"031d";
		BORDER(220) <= x"031e";
		BORDER(221) <= x"031f";
		BORDER(222) <= x"0320";
		BORDER(223) <= x"0321";
		BORDER(224) <= x"0322";
		BORDER(225) <= x"0345";
		BORDER(226) <= x"0346";
		BORDER(227) <= x"0347";
		BORDER(228) <= x"0348";
		BORDER(229) <= x"0349";
		BORDER(230) <= x"034a";
		BORDER(231) <= x"036d";
		BORDER(232) <= x"036e";
		BORDER(233) <= x"036f";
		BORDER(234) <= x"0370";
		BORDER(235) <= x"0371";
		BORDER(236) <= x"0372";
		BORDER(237) <= x"0395";
		BORDER(238) <= x"0396";
		BORDER(239) <= x"0397";
		BORDER(240) <= x"0398";
		BORDER(241) <= x"0399";
		BORDER(242) <= x"039a";
		BORDER(243) <= x"03bd";
		BORDER(244) <= x"03be";
		BORDER(245) <= x"03bf";
		BORDER(246) <= x"03c0";
		BORDER(247) <= x"03c1";
		BORDER(248) <= x"03c2";
		BORDER(249) <= x"03e5";
		BORDER(250) <= x"03e6";
		BORDER(251) <= x"03e7";
		BORDER(252) <= x"03e8";
		BORDER(253) <= x"03e9";
		BORDER(254) <= x"03ea";
		BORDER(255) <= x"040d";
		BORDER(256) <= x"040e";
		BORDER(257) <= x"040f";
		BORDER(258) <= x"0410";
		BORDER(259) <= x"0411";
		BORDER(260) <= x"0412";
		BORDER(261) <= x"0435";
		BORDER(262) <= x"0436";
		BORDER(263) <= x"0437";
		BORDER(264) <= x"0438";
		BORDER(265) <= x"0439";
		BORDER(266) <= x"043a";
		BORDER(267) <= x"043b";
		BORDER(268) <= x"043c";
		BORDER(269) <= x"043d";
		BORDER(270) <= x"043e";
		BORDER(271) <= x"043f";
		BORDER(272) <= x"0440";
		BORDER(273) <= x"0441";
		BORDER(274) <= x"0442";
		BORDER(275) <= x"0443";
		BORDER(276) <= x"0444";
		BORDER(277) <= x"0445";
		BORDER(278) <= x"0446";
		BORDER(279) <= x"0447";
		BORDER(280) <= x"0448";
		BORDER(281) <= x"0449";
		BORDER(282) <= x"044a";
		BORDER(283) <= x"044b";
		BORDER(284) <= x"044c";
		BORDER(285) <= x"044d";
		BORDER(286) <= x"044e";
		BORDER(287) <= x"044f";
		BORDER(288) <= x"0450";
		BORDER(289) <= x"0451";
		BORDER(290) <= x"0452";
		BORDER(291) <= x"0453";
		BORDER(292) <= x"0454";
		BORDER(293) <= x"0455";
		BORDER(294) <= x"0456";
		BORDER(295) <= x"0457";
		BORDER(296) <= x"0458";
		BORDER(297) <= x"0459";
		BORDER(298) <= x"045a";
		BORDER(299) <= x"045b";
		BORDER(300) <= x"045c";
		BORDER(301) <= x"045d";
		BORDER(302) <= x"045e";
		BORDER(303) <= x"045f";
		BORDER(304) <= x"0460";
		BORDER(305) <= x"0461";
		BORDER(306) <= x"0462";
		BORDER(307) <= x"0463";
		BORDER(308) <= x"0464";
		BORDER(309) <= x"0465";
		BORDER(310) <= x"0466";
		BORDER(311) <= x"0467";
		BORDER(312) <= x"0468";
		BORDER(313) <= x"0469";
		BORDER(314) <= x"046a";
		BORDER(315) <= x"046b";
		BORDER(316) <= x"046c";
		BORDER(317) <= x"046d";
		BORDER(318) <= x"046e";
		BORDER(319) <= x"046f";
		BORDER(320) <= x"0470";
		BORDER(321) <= x"0471";
		BORDER(322) <= x"0472";
		BORDER(323) <= x"0473";
		BORDER(324) <= x"0474";
		BORDER(325) <= x"0475";
		BORDER(326) <= x"0476";
		BORDER(327) <= x"0477";
		BORDER(328) <= x"0478";
		BORDER(329) <= x"0479";
		BORDER(330) <= x"047a";
		BORDER(331) <= x"047b";
		BORDER(332) <= x"047c";
		BORDER(333) <= x"047d";
		BORDER(334) <= x"047e";
		BORDER(335) <= x"047f";
		BORDER(336) <= x"0480";
		BORDER(337) <= x"0481";
		BORDER(338) <= x"0482";
		BORDER(339) <= x"0483";
		BORDER(340) <= x"0484";
		BORDER(341) <= x"0485";
		BORDER(342) <= x"0486";
		BORDER(343) <= x"0487";
		BORDER(344) <= x"0488";
		BORDER(345) <= x"0489";
		BORDER(346) <= x"048a";
		BORDER(347) <= x"048b";
		BORDER(348) <= x"048c";
		BORDER(349) <= x"048d";
		BORDER(350) <= x"048e";
		BORDER(351) <= x"048f";
		BORDER(352) <= x"0490";
		BORDER(353) <= x"0491";
		BORDER(354) <= x"0492";
		BORDER(355) <= x"0493";
		BORDER(356) <= x"0494";
		BORDER(357) <= x"0495";
		BORDER(358) <= x"0496";
		BORDER(359) <= x"0497";
		BORDER(360) <= x"0498";
		BORDER(361) <= x"0499";
		BORDER(362) <= x"049a";
		BORDER(363) <= x"049b";
		BORDER(364) <= x"049c";
		BORDER(365) <= x"049d";
		BORDER(366) <= x"049e";
		BORDER(367) <= x"049f";
		BORDER(368) <= x"04a0";
		BORDER(369) <= x"04a1";
		BORDER(370) <= x"04a2";
		BORDER(371) <= x"04a3";
		BORDER(372) <= x"04a4";
		BORDER(373) <= x"04a5";
		BORDER(374) <= x"04a6";
		BORDER(375) <= x"04a7";
		BORDER(376) <= x"04a8";
		BORDER(377) <= x"04a9";
		BORDER(378) <= x"04aa";
		BORDER(379) <= x"04ab";
		BORDER(380) <= x"04ac";
		BORDER(381) <= x"04ad";
		BORDER(382) <= x"04ae";
		BORDER(383) <= x"04af";

		-- Índice e posição inicial
		INDEX_SCENERY <= 0;
		POSITION_SCENERY <= x"0000";

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
		POSITION_GAMEOVER <= x"0235"; -- Meio da tela
		
		-- TÍTULO / BANNER
		TITLE <= (OTHERS=>"00000000");
		TITLE(0) <= "01000110" -- f
		TITLE(1) <= "01001100" -- l
		TITLE(2) <= "01001001" -- i
		TITLE(3) <= "01010000" -- p
		TITLE(4) <= "01010000" -- p
		TITLE(5) <= "01011001" -- y
		TITLE(6) <= "00000000" --  
		TITLE(7) <= "01000110" -- f
		TITLE(8) <= "01001100" -- l
		TITLE(9) <= "01001111" -- o
		TITLE(10) <= "01010000" -- p
		TITLE(11) <= "01010000" -- p
		TITLE(12) <= "01011001" -- y
		TITLE(13) <= "00000000" --  
		TITLE(14) <= "01000010" -- b
		TITLE(15) <= "01001001" -- i
		TITLE(16) <= "01010010" -- r
		TITLE(17) <= "01000100" -- d

		--SETAR INDEX E POS INICIAL
		INDEX_TITLE <= 0;
		POSITION_TITLE <= x"002C"; -- Topo da tela

		-- INITIALIZE score
		SCORE(0) <= "01010011" -- s
		SCORE(1) <= "01000011" -- c
		SCORE(2) <= "01001111" -- o
		SCORE(3) <= "01010010" -- r
		SCORE(4) <= "01000101" -- e

		--SETAR INDEX E POS INICIAL
		INDEX_SCORE <= 0;
		POSITION_SCORE <= x"0464"; -- Base da tela
		
		-------------------------------------------------
		-- Inicializar Cano
		-------------------------------------------------
		PIPE_VECTOR <= (OTHERS=>x"0027");
		-- Cano Tipo 1 --
		-- Cima --
		PIPE_VECTOR(0) <= x"0027"; -- 39
		PIPE_VECTOR(1) <= x"004F"; -- 79
		PIPE_VECTOR(2) <= x"0077"; -- 119
		PIPE_VECTOR(3) <= x"009F"; -- 159
		-- Baixo --
		PIPE_VECTOR(4) <= x"04AF"; -- 1199
		PIPE_VECTOR(5) <= x"0487"; -- 1159
		PIPE_VECTOR(6) <= x"045F"; -- 1119
		PIPE_VECTOR(7) <= x"0437"; -- 1079
		-- Cano Tipo 2 --
		-- Cima --
		-- Baixo --
		-- Cano Tipo 3 --
		-- Cima --
		-- Baixo --
		
		PIPE_INDEX <= 0;
		
	ELSIF (clkvideo'event) and (clkvideo = '1') THEN
		CASE VIDEOE IS

			-------------------------------------------------
			-- Reset
			-------------------------------------------------

			WHEN x"00" =>
				-- Apagar toda a tela
				IF (RESET = '1') THEN
					vga_char(15 downto 12) <= "0000";		
					vga_char(11 downto 8) <= "0000"; -- Cor branca
					vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;
					vga_pos(15 downto 0) <= POSITION_SCENERY;
					videoflag <= '1';
					VIDEOE <= x"01";
				END IF;

			WHEN x"01" => -- Continuar apagando a tela
				IF (POSITION_SCENERY < x"4af") THEN
					POSITION_SCENERY <= POSITION_SCENERY + x"01";
					VIDEOE <= x"00";
				ELSE
					VIDEOE <= x"02"; -- Ir p/ loop de desenho

			-------------------------------------------------
			-- Desenhar Nuvens
			-------------------------------------------------

			-- Desenhar em Posição(Índice)
			WHEN x"06" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "0000"; -- Cor branca
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0)	<= CLOUD_VECTOR(INDEX_SCENERY) - CLOUDS_OFFSET;
				videoflag <= '1';

				VIDEOE <= x"07";
			
			-- Intermediário
			WHEN x"07" =>
				IF(INDEX_SCENERY < 110) THEN -- Tamanho do vetor de posições das nuvens
					INDEX_SCENERY <= INDEX_SCENERY + 1;
					VIDEOE <= x"06";
				ELSE
					INDEX_SCENERY <= 0;
					VIDEOE <= x"08";
				END IF;

			-- Transição
			WHEN x"08" =>
				VIDEOE <= x"09";
			
			-- Apagar Nuvens
			WHEN x"09" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0)	<= CLOUD_VECTOR(INDEX_SCENERY) - CLOUDS_OFFSET + x"01"; -- Apagar posição anterior
				videoflag <= '1';

				VIDEOE <= x"10";
			
			-- Transição
			WHEN x"10" =>
				IF(INDEX_SCENERY < 8) THEN -- Ainda não terminou de apagar
					INDEX_SCENERY <= INDEX_SCENERY + 1;
					VIDEOE <= x"09"; -- Continuar apagando
				ELSE
					INDEX_SCENERY <= 0; -- Terminou de apagar
					VIDEOE <= x"00";
				END IF;

			-------------------------------------------------
			-- Desenhar Montanhas
			-------------------------------------------------

			-- Desenhar em Posição(Índice)
			WHEN x"06" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "0011"; -- Cor amarelo escuro
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0) 	<= MOUNTAIN_VECTOR(INDEX_SCENERY);
				videoflag <= '1';

				VIDEOE <= x"07";
			
			-- Intermediário
			WHEN x"07" =>
				IF(INDEX_SCENERY < 250) THEN -- Tamanho do vetor de posições das montanhas
					INDEX_SCENERY <= INDEX_SCENERY + 1;
					VIDEOE <= x"06";
				ELSE
					INDEX_SCENERY <= 0;
					VIDEOE <= x"08";
				END IF;

			-- Transição
			WHEN x"08" =>
				VIDEOE <= x"00";
			
			-------------------------------------------------
			-- Desenhar Flippy
			-------------------------------------------------

			-- Apagar Flippy
			WHEN x"00" =>

				if(FLIPPY_POS_PREV = FLIPPY_POS) then -- Apenas apagar quando muda de posição
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
				-- SE GAME OVER, DESENHAR TEXTO NA TELA
				
				VIDEOE <= x"06";

			-------------------------------------------------
			-- Desenhar Textos
			-------------------------------------------------

			WHEN x"04" => -- Desenha GAME OVER NA TELA

				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1001";
				vga_char(7 downto 0) <= GAME_OVER(INDEX_GAMEOVER);				
				vga_pos(15 downto 0)	<= POSITION_GAMEOVER;

				videoflag <= '1';

				VIDEOE <= x"05";

			-- Intermediário Game Over -> Canos
			WHEN x"05" =>
				videoflag <= '0';

				IF(POSITION_GAMEOVER > x"003B") THEN
					POSITION_GAMEOVER <= x"0032";
					INDEX_GAMEOVER <= 0;
				ELSE
					POSITION_GAMEOVER <= POSITION_GAMEOVER + x"01";
					INDEX_GAMEOVER <= INDEX_GAMEOVER + 1;
					VIDEOE <= x"04";
				END IF;

				VIDEOE <= x"06";

			-------------------------------------------------
			-- Desenhar Canos
			-------------------------------------------------
			
			-- Desenhar na vertical
			WHEN x"06" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "0010";
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0)	<= PIPE_VECTOR(PIPE_INDEX) - PIPE_OFFSET;
				videoflag <= '1';

				VIDEOE <= x"07";
			
			-- Intermediário
			WHEN x"07" =>
				IF(PIPE_INDEX < 8) THEN
					PIPE_INDEX <= PIPE_INDEX + 1;
					VIDEOE <= x"06";
				ELSE
					PIPE_INDEX <= 0;
					VIDEOE <= x"08";
				END IF;

			-- Transição
			WHEN x"08" =>
				VIDEOE <= x"09";
			
			-- Apagar na Vertical
			WHEN x"09" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "1110"; -- Azul - Cor do Fundo
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0)	<= PIPE_VECTOR(PIPE_INDEX) - PIPE_OFFSET + x"01"; -- Apagar posição anterior
				videoflag <= '1';

				VIDEOE <= x"10";
			
			-- Transição
			WHEN x"10" =>
				IF(PIPE_INDEX < 8) THEN -- Ainda não terminou de apagar
					PIPE_INDEX <= PIPE_INDEX + 1;
					VIDEOE <= x"09"; -- Continuar apagando
				ELSE
					PIPE_INDEX <= 0; -- Terminou de apagar, volta para ciclo do Flippy
					VIDEOE <= x"00";
				END IF;
			
			WHEN OTHERS =>
				videoflag <= '0';
				VIDEOE <= x"00";

			-------------------------------------------------
			-- Desenhar Telinha
			-------------------------------------------------

			-- Desenhar em Posição(Índice)
			WHEN x"06" =>
				vga_char(15 downto 12) <= "0000";		
				vga_char(11 downto 8) <= "0000"; -- Cor preta
				vga_char(7 downto 0) <= "00000000"; -- Primeiro char - quadrado;				
				vga_pos(15 downto 0) 	<= BORDER(INDEX_SCENERY);
				videoflag <= '1';

				VIDEOE <= x"07";
			
			-- Intermediário
			WHEN x"07" =>
				IF(INDEX_SCENERY < 250) THEN -- Tamanho do vetor de posições das montanhas
					INDEX_SCENERY <= INDEX_SCENERY + 1;
					VIDEOE <= x"06";
				ELSE
					INDEX_SCENERY <= 0;
					VIDEOE <= x"08";
				END IF;

			-- Transição
			WHEN x"08" =>
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
