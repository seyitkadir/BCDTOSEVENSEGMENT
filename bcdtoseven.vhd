library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  -- to_unsigned ve unsigned tiplerini bu kütüphaneden kullanıyoruz

entity bcdtoseven is
    Port (
        sw 									: in std_logic_vector(13 downto 0);  -- 14-bit switch input (0-9999 arası)
        clk 								: in std_logic;                      -- Clock input for multiplexing the displays
        seg 								: out std_logic_vector(6 downto 0);  -- 7 segment display output (a, b, c, d, e, f, g)
        an 									: out std_logic_vector(3 downto 0)   -- Anode control for 4 digits
    );
end bcdtoseven;

architecture Behavioral of bcdtoseven is
    signal ones, tens, hundreds, thousands : std_logic_vector(3 downto 0); -- Birlik, onlar, yüzler ve binler basamakları
    signal count : integer := 0; -- Hangi basamağın aktif olduğunu belirlemek için sayaç

    -- Clock divider sinyali
    signal slow_clk : std_logic := '0';
    signal clk_divider : integer := 0;

    -- Fonksiyon tanımı
    function binary_to_seven_segment(input : std_logic_vector(3 downto 0)) return std_logic_vector is
        variable seg_output 			   : std_logic_vector(6 downto 0);  -- 7-bit output for seven-segment display (a to g)
    begin
        case input is
            when "0000" 					=> seg_output := "1000000"; -- 0
            when "0001" 					=> seg_output := "1111001"; -- 1
            when "0010" 					=> seg_output := "0100100"; -- 2
            when "0011" 					=> seg_output := "0110000"; -- 3
            when "0100" 					=> seg_output := "0011001"; -- 4
            when "0101" 					=> seg_output := "0010010"; -- 5
            when "0110" 					=> seg_output := "0000010"; -- 6
            when "0111" 					=> seg_output := "1111000"; -- 7
            when "1000" 					=> seg_output := "0000000"; -- 8
            when "1001" 					=> seg_output := "0010000"; -- 9
            when others 					=> seg_output := "1111111"; -- Display off
        end case;
        return seg_output;
    end function;

begin

    -- Clock Divider (Clock'u yavaşlat)
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_divider = 50000 then  -- 100 MHz'den yaklaşık 1 kHz'e düşürmek için
                slow_clk <= not slow_clk;  -- Yavaşlatılmış clock sinyali üret
                clk_divider <= 0;
            else
                clk_divider <= clk_divider + 1;
            end if;
        end if;
    end process;

    -- Binary değeri decimal (BCD) formata çeviren bir süreç
    process(sw)
        variable value_int 					: integer;
    begin
        value_int 							:= to_integer(unsigned(sw));  -- Binary değeri integer'e çevir
        thousands 							<= std_logic_vector(to_unsigned(value_int / 1000, 4)); -- Binler basamağı
        hundreds 							<= std_logic_vector(to_unsigned((value_int / 100) mod 10, 4)); -- Yüzler basamağı
        tens 								<= std_logic_vector(to_unsigned((value_int / 10) mod 10, 4)); -- Onlar basamağı
        ones 								<= std_logic_vector(to_unsigned(value_int mod 10, 4)); -- Birlik basamağı
    end process;
	
    -- Her basamağın hangi değeri göstereceğini seçmek için segment decoder
    process(slow_clk, ones, tens, hundreds, thousands)
    begin
        case count is
            when 0 =>
                an 							<= "1110";  -- İlk basamağı aktif et (birlik)
                seg 						<= binary_to_seven_segment(ones);  -- Fonksiyonu kullanarak birlik basamağını göster
            when 1 =>	
                an 							<= "1101";  -- İkinci basamağı aktif et (onlar)
                seg 						<= binary_to_seven_segment(tens);  -- Fonksiyonu kullanarak onlar basamağını göster
            when 2 =>	
                an 							<= "1011";  -- Üçüncü basamağı aktif et (yüzler)
                seg 						<= binary_to_seven_segment(hundreds);  -- Fonksiyonu kullanarak yüzler basamağını göster
            when 3 =>
                an 							<= "0111";  -- Dördüncü basamağı aktif et (binler)
                seg 						<= binary_to_seven_segment(thousands);  -- Fonksiyonu kullanarak binler basamağını göster
            when others =>
                an 							<= "1111";  -- Hiçbir basamak aktif değil (hepsi kapalı)
        end case;
    end process;
	
	-- Sayaç kontrolü (hangi basamağın aktif olduğunu belirler)
    process(slow_clk)
    begin
        if rising_edge(slow_clk) then
            count <= count + 1;
            if count = 3 then
                count <= 0;
            end if;
        end if;
    end process;
end Behavioral;