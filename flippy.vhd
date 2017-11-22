-- *************************************************
-- FLIPPY FLOPPY BIRD
-- Felipe Scrochio Custódio - 9442688
-- Gabriel Henrique Scalici - 9292970
-- INSTRUÇÕES:
-- A barra de espaço faz o Flippy pular
-- para cima e para baixo.
-- *************************************************
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY game IS

	PORT(
		clkvideo, clk, reset  : IN	STD_LOGIC;		
		videoflag	: out std_LOGIC;
		vga_pos		: out STD_LOGIC_VECTOR(15 downto 0);
		vga_char	: out STD_LOGIC_VECTOR(15 downto 0);
		key			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0) -- teclado
		);

END game;

-- Definir arquitetura do jogo
ARCHITECTURE a OF game IS

	-- Escreve na tela
	SIGNAL VIDEOE      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	-- Contador de tempo

	-- Flippy
	SIGNAL FLIPPY_POS   : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Variáveis são SIGNAL
	SIGNAL FLIPPY_POSA  : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Registradores construidos com Flip Flops
	SIGNAL FLIPPY_CHAR  : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Todos os processos conseguem ler
	SIGNAL FLIPPY_COR   : STD_LOGIC_VECTOR(3 DOWNTO 0); -- Apenas um processo por vez por clock
	SIGNAL FLIPPY_INC   : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FLIPPY_SINAL	: STD_LOGIC;
	SIGNAL FLIPPY_DELAY : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL FLIPPY_ESTADO : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

-- Processo do Flippy
PROCESS (clk, reset)
	
	-- Variáveis do Processo VARIABLES

	BEGIN
	-- Reseta e começa o jogo
	IF RESET = '1' THEN
		-- Definir cor e símbolo
		FLIPPY_CHAR <= "00000001"; -- Pegar o primeiro x 8 no charmap (indexar no charmap)
		FLIPPY_COR <= "1010"; -- 1010 verde
		FLIPPY_POS <= x"0064"; -- Tela 40x30, indexação linear, começa em 0
		FLIPPY_DELAY <= x"00000000";
		FLIPPY_ESTADO <= x"00"; -- Variável da máquina de estados do Flippy (estado 0)
		
	ELSIF (clk'event) and (clk = '1') THEN

		-- 100khz - 100 mil vezes por segundo
		CASE FLIPPY_ESTADO IS
			-- Estado 0
			WHEN x"00" => -- Estado de movimentação - Verificar se pulou
			
				CASE key IS
					WHEN x"73" => -- (S) BAIXO
						IF (FLIPPY_POS < 1159) THEN   -- nao esta' na ultima linha
							FLIPPY_POS <= FLIPPY_POS + x"28";  -- FLIPPY_POS + 40
						END IF;
					WHEN OTHERS =>
				END CASE;
				-- Mudar de estado (delay)
				FLIPPY_ESTADO <= x"01";

			-- Entra no Delay no próximo ciclo
			-- Estado 1
			WHEN x"01" => -- Delay do Flippy
			 	
				IF FLIPPY_DELAY >= x"00000FFF" THEN
					-- Zerar delay
					FLIPPY_DELAY <= x"00000000";
					-- Voltar pro estado inicial
					FLIPPY_ESTADO <= x"00";
				ELSE
					-- Aumentar delay
					FLIPPY_DELAY <= FLIPPY_DELAY + x"01";
				END IF;
			WHEN OTHERS =>
		END CASE;
	END IF;

END PROCESS;

-- Processo de Vídeo
PROCESS (clkvideo, reset)

BEGIN
	-- Resetar e apagar tudo
	-- Antes de desenhar coisa nova: desenhar fundo no lugar da anterior
	IF RESET = '1' THEN
		VIDEOE <= x"00";
		videoflag <= '0';
		FLIPPY_POSA <= x"0000";
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
				vga_char(11 downto 8) <= FLIPPY_COR;
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
