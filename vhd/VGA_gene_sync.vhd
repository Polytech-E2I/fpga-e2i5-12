library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity VGA_GeneSync is
    Port (
        -- Clock
        clk : in std_logic; -- Attention horloge à 100MHz dans ce circuit

        -- Outputs
        hsync : out std_logic ;
        vsync : out std_logic ;
        blank : out std_logic ;
        x     : out unsigned ( 9 downto 0 ) ;
        y     : out unsigned ( 8 downto 0 )
    );
end entity;


architecture Behavioral of VGA_GeneSync is
    -- comptX est le compteur horizontal :
    -- Donne la position dans la phase horizontale actuelle. Ce signal est initialisé à la valeur 0.
    signal comptX : unsigned (9 downto 0) := (others=>'0');

    -- comptY est le compteur vertical
    signal comptY : unsigned (8 downto 0) := (others=>'0');

    -- comptCLK est le compteur utilisé pour générer des signaux d'activation à 25MHz à partir de l'horloge entrante à 100MHz
    signal comptCLK : unsigned (2 downto 0) := (others=>'0');

    -- comptI compte les phases horizontales du protocole VGA.
    -- Il passe dans l'ordre par les phases pulse ("00"), back porch("01"), display("10") puis front porch ("11")
    signal comptI : unsigned (1 downto 0) := "00";
    -- idem pour les phases verticales.
    signal comptJ : unsigned (1 downto 0) := "00";

    -- On notera qu'une valeur de bit est encadrée par des '' tandis qu'une valeur de vecteur de bits est encadrée par des ""

    -- Le type boolean peut être utilisé pour contenir des conditions et permet une syntaxe
    -- plus légère que son équivalent avec un std_logic.

    -- Signaux d'activations et de remise à zéro des compteurs X et Y
    signal resX, resY, enY, enX : boolean;


    -- Définition de type tableau de 4 éléments pour stocker les paramètres de temporisation.
    type param_synchroX is array (natural range 0 to 3) of natural range 0 to 1023;
    type param_synchroY is array (natural range 0 to 3) of natural range 0 to 511;
    -- Le type natural est un sous-type du type integer désignant les entiers positifs

    -- Les tableaux de constantes ci-dessous contiennent les durées de chacunes
    -- des phases du protocole VGA (pulse, back porch, display, front porch).
    -- Les valeurs sont extraites de la documentation (Figure 11) pour une
    -- résolution 640x480 avec une horloge à 25MHz et une fréquence de
    -- rafraîchissement de 60Hz.
    -- Toutes les valeurs ont été décrémentées car on compte à partir de 0.

    -- paramètres pour la synchronisation horizontale
    -- Ce tableau de constante doit être inféré en une ROM de 4X10bits
    constant synchro_X: param_synchroX := (
        0 => 95,  -- HS pulse width
        1 => 47,  -- horizontal back porch
        2 => 639, -- horizontal display time
        3 => 15   -- horizontal front porch
    );

    -- Paramètres pour la synchronisation verticale
    -- Ce tableau de constante doit être inféré en une ROM de 4X9bits
    constant synchro_Y: param_synchroY := (
        0 => 1,   -- VS pulse width
        1 => 28,  -- vertical back porch
        2 => 479, -- vertical display time
        3 => 9    -- vertical front porch
    );

begin

-- Comme vous l'avez déjà compris, les différentes tâches d'une description
-- VHDL s'exécutent en parallèle. Ces tâches (affectations concurrentes,
-- instanciation de composants, affectations concurrentes conditionnelles) sont
-- en fait des processus déclarés implicitement. Il est possible de déclarer
-- explicitement un processus avec le mot-clé process.  A l'intérieur d'un process,
-- les instructions sont traitées séquentiellement. Par ailleurs, un process se
-- comporte comme une boucle infinie : une fois arrivée à l'instruction "end
-- process", le processus continuera son exécution sur l'instruction suivant son
-- "begin". Le processus n'est réveillé que lorsque qu'un changement survient sur
-- un des signaux de sa liste de sensibilité. Cette liste de sensibilité est donnée
-- entre parenthèses juste après le mot-clé process.
-- Ici, il s'agit d'un processus qui ne réagit qu'à l'horloge. Ce processus décrit
-- donc de la logique séquentielle.
-- Dans le TP précédent, les éléments de logique séquentielle étaient cachés dans
-- des composants (bascule_d.vhd).
-- N'hésitez pas à y jeter un oeil pour mieux comprendre ce qui se trame dans ce
-- process.

    process (clk) -- un processus qui ne dépend que de l'horloge : logique séquentielle
    begin
        if (clk'event and clk='1')then -- détection d'un front montant
            if enX = false then -- enX est un booléen. Par un type std_logic, il aurait fallu écrire enX = '0'
                comptCLK <= comptCLK+1; -- compteur 3 bits activé à tous les cycles et mis à zéro par NON enX.
            else -- le front d'horloge nous intéresse
                comptCLK <= (others=>'0');
                if resX then --comprendre resX = true
                    comptX <= (others=>'0');
                    comptI <= comptI+1; -- compteur 2bits activé par resX
                else
                    comptX <= comptX+1; -- compteur 10bits activé par enX et mis à zéro par enX ET resX
                end if;
                if enY then
                    if resY then
                        comptY <= (others=>'0');
                        comptJ <= comptJ+1; -- compteur 2bits activé par resY
                    else
                        comptY <= comptY+1; -- compteur 9bits activé par enY et mis à zéro par enY ET resY
                    end if;
                end if;
            end if;
        end if;
    end process;


-- La fonction to_integer permet de convertir un type unsigned ou signed en integer.
-- Les signaux/constantes/variables de type array ne s'adressent qu'avec des integers.
    resX <= comptX = synchro_X(to_integer(comptI)); -- comparateur d'égalité 10bits entre comptX et la constante de durée de la phase en cours. Le résultat de type booléen indique la fin de la phase en cours. Il faut passer à la suivante et réinitialiser comptX, d'où l'affectation à resX.
    resY <= comptY = synchro_Y(to_integer(comptJ)); -- comparateur 9bits - idem
    enX  <= to_integer(comptCLK)=3; --détection d'égalité à 3. Permet à comptCLK de compter de 0 à 3 et de créer une activation à la fréquence de 25MHz
    enY  <= to_integer(comptI)=0 and to_integer(comptX)=0 ; --enY permet de détecter qu'une ligne vient d'être traitée. C'est le cas lorsqu'on détecte le début de la phase pulse de la progression horizontale. Ce signal permet d'incrémenter comptY.

    hsync <= comptI(0) or comptI(1); -- résultat à 1 si comptI différent de "00" (phase pulse)
    vsync <= comptJ(0) or comptJ(1); -- idem
    --img   <= '1' when to_integer(comptI)=2 and to_integer(comptJ)=2 else '0'; -- on autorise l'affichage uniquement quand on est dans la phase display horizontalement et verticalement.
    blank <= '0' when to_integer(comptI)=2 and to_integer(comptJ)=2 else '1'; -- on autorise l'affichage uniquement quand on est dans la phase display horizontalement et verticalement.
    x     <= comptX;
    y     <= comptY;

end architecture;
