--Procedura wstawiajaca nowa gre do tabeli gry i nastepnie wstawiajaca id i nazwe gracza do odpowiedniej tabeli (albo gracze_gry albo graczezawodowi_gry)
CREATE PROCEDURE wstaw_gre (
@gracz VARCHAR(20),
@pro CHAR(1),
@rezultat VARCHAR(4),
@zabojstwa SMALLINT,
@smierci SMALLINT,
@asysty SMALLINT,
@creep_score SMALLINT,
@zdobyte_zloto INT,
@czas_gry TIME(0),
@zadane_obrazenia INT,
@strona VARCHAR(4),
@zabojstwa_druzyny SMALLINT = NULL,
@zgony_druzyny SMALLINT = NULL,
@bohater VARCHAR(20))
AS
BEGIN
    DECLARE @id INT;
    INSERT INTO gry (rezultat, zabojstwa, smierci, asysty, creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia, zabojstwa_druzyny, zgony_druzyny, strona, bohaterowie_nazwa)
    VALUES (@rezultat, @zabojstwa, @smierci, @asysty, @creep_score, @zdobyte_zloto, @czas_gry, @zabojstwa, @zabojstwa, @zgony_druzyny, @strona, @bohater);
    SET @id = SCOPE_IDENTITY();

	IF @pro = 'T'
	BEGIN
		INSERT INTO graczezawodowi_gry (gry_id_meczu, gracze_zawodowi_nick)
		VALUES (@id, @gracz);
	END;
	IF @pro = 'N'
	BEGIN
		INSERT INTO gracze_gry (gry_id_meczu, gracze_nick)
		VALUES (@id, @gracz);
	END;
END;
GO
--Przykladowe wywolania
--EXEC wstaw_gre 'Sloik', 'N', 'WIN', 69, 69, 69, 420, 1000, '00:21:37', 12345, 'BLUE';
--EXEC wstaw_gre 'Jankos', 'T', 'WIN', 69, 69, 69, 420, 1000, '00:21:37', 12345, 'BLUE';


CREATE PROCEDURE register(
@nick VARCHAR(20),
@haslo VARCHAR(100),
@dywizja VARCHAR(15),
@poziom SMALLINT,
@ulubiony_bohater VARCHAR(20))
AS
BEGIN
	INSERT INTO gracze(nick, dywizja, poziom, ulubiony_bohater) VALUES (@nick, @dywizja, @poziom, @ulubiony_bohater);
	INSERT INTO dane_logowania(nick, haslo, rola) VALUES (@nick, @haslo, 'User');
END;
GO

-------------------------------------------------------------------------------------------------------------------

-- Procedura znajdujaca komponenty danego przedmiotu (wszystkie)
CREATE PROCEDURE znajdz_komponenty (@id_przed INT)
AS
BEGIN
WITH ItemComponents AS (
SELECT k.id, p.id_przed, p.nazwa, 0 as [Level]
FROM przedmioty p
JOIN komponenty_przedmiotow k ON p.id_przed = k.id_komponentu
WHERE k.id_przed = @id_przed

UNION ALL

SELECT k.id, p.id_przed, p.nazwa, [Level] + 1
FROM przedmioty p
JOIN komponenty_przedmiotow k ON p.id_przed = k.id_komponentu
JOIN ItemComponents c ON k.id_przed = c.id_przed
)
SELECT id, id_przed, nazwa, [Level]
FROM ItemComponents;
END;
GO

--Przykladowe wywolanie
--EXEC znajdz_komponenty 3078;

-------------------------------------------------------------------------------------------------------------------

-- Procedura znajdujaca komponenty danego przedmiotu (tylko te z których dany przedmiot bezpośrednio się składa)
CREATE PROCEDURE znajdz_komponenty2(@id_przed INT)
AS
BEGIN
	SELECT id_przed, nazwa, ikona
	FROM przedmioty p
	WHERE id_przed IN (SELECT id_komponentu FROM komponenty_przedmiotow kp WHERE kp.id_przed = @id_przed) 
END;
GO
--Przykladowe wywolanie
--EXEC znajdz_komponenty2 3078;

-------------------------------------------------------------------------------------------------------------------

-- Procedura znajdujaca przedmioty zakupione w grze o podanym id
CREATE PROCEDURE znajdz_zakupione_przedmioty(@id_meczu INT)
AS
BEGIN
SELECT id_przed, nazwa, ikona
FROM przedmioty INNER JOIN gry_zakupioneprzedmioty ON id_zakupionego_przedmiotu = id_przed
WHERE id_meczu = @id_meczu;
END;
GO
--Przykladowe wywolanie
--EXEC znajdz_zakupione_przedmioty 123;

-------------------------------------------------------------------------------------------------------------------

--Procedura zwracajaca zawodnikow danej druzyny
CREATE PROCEDURE znajdz_graczy_druzyny(@p_team_id VARCHAR(6))
AS
BEGIN
SET NOCOUNT ON;
    SELECT nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny, ulubiony_bohater
    FROM gracze_zawodowi
    WHERE id_druzyny = @p_team_id
     ORDER BY
            CASE
                WHEN rola = 'Top Laner' THEN 1
                WHEN rola = 'Jungler'   THEN 2
                WHEN rola = 'Mid Laner' THEN 3
                WHEN rola = 'Bot Laner' THEN 4
                ELSE 5
            END;
END;
GO
-------------------------------------------------------------------------------------------------------------------

-- Funkcja obliczajaca procent wygranych gracza o podanym nicku

CREATE FUNCTION win_rate (@pNick VARCHAR(20), @pro CHAR(1))
RETURNS FLOAT AS
BEGIN
    DECLARE @vWinRate FLOAT;
    DECLARE @vWins FLOAT = 0;
    DECLARE @vLoses FLOAT = 0;
    DECLARE @vGames FLOAT = 0;
    DECLARE @vGame_rezultat VARCHAR(200);
    
	IF @pro = 'T'
	BEGIN
		SELECT @vWins = SUM(CASE WHEN rezultat = 'WIN' THEN 1 ELSE 0 END)
		FROM graczezawodowi_gry g
		INNER JOIN gry m ON g.gry_id_meczu = m.id_meczu
		WHERE gracze_zawodowi_nick = @pNick;
    
		SET @vLoses = (SELECT COUNT(*) 
					   FROM graczezawodowi_gry g 
					   INNER JOIN gry m ON g.gry_id_meczu = m.id_meczu 
					   WHERE gracze_zawodowi_nick = @pNick) - @vWins;
	END
	ELSE
	BEGIN
		SELECT @vWins = SUM(CASE WHEN rezultat = 'WIN' THEN 1 ELSE 0 END)
		FROM gracze_gry g
		INNER JOIN gry m ON g.gry_id_meczu = m.id_meczu
		WHERE gracze_nick = @pNick;
    
		SET @vLoses = (SELECT COUNT(*) 
					   FROM gracze_gry g 
					   INNER JOIN gry m ON g.gry_id_meczu = m.id_meczu 
					   WHERE gracze_nick = @pNick) - @vWins;
	END;

	SET @vGames = @vWins + @vLoses;
		
	IF @vGames > 0
	BEGIN
		SET @vWinRate = @vWins / @vGames * 100;
	END
	ELSE
	BEGIN
		SET @vWinRate = 0;
	END;
    
    RETURN @vWinRate;
END;
GO
-- Przykladowe wywolania:
--SELECT dbo.win_rate('Sloik', 'N')
--SELECT dbo.win_rate('Jankos', 'T')

-------------------------------------------------------------------------------------------------------------------

-- Funckja obliczajaca KDA dla gry o podanym ID

CREATE FUNCTION KDA (@id_meczu INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @vK INT;
    DECLARE @vD INT;
    DECLARE @vA INT;
	DECLARE @vKDA FLOAT;

    SELECT @vK = zabojstwa, @vD = smierci, @vA = asysty
    FROM Gry
    WHERE id_meczu = @id_meczu;

	IF @vD > 0
	BEGIN
		SET @vKda = ROUND(CAST((@vK + @vA) AS FLOAT) / CAST(@vD AS FLOAT),2)
	END
	ELSE
	BEGIN
		SET @vKda = (@vK + @vA)
	END;

    RETURN @vKda;
END;
GO
--Przykladowe wywolanie
--SELECT dbo.KDA(123)

-------------------------------------------------------------------------------------------------------------------

-- Funckja obliczajaca srednie KDA dla gracza o podanym nicku

CREATE FUNCTION srednie_KDA(@pNick VARCHAR(20), @pro CHAR(1))
RETURNS FLOAT AS
BEGIN
	DECLARE @vSrednieKDA FLOAT;

	IF @pro = 'T'
	BEGIN
		SELECT @vSrednieKDA = ROUND((CAST((SUM(zabojstwa) + SUM(asysty)) AS FLOAT)) / CAST(SUM(smierci) AS FLOAT),2)
		FROM gry WHERE id_meczu IN (SELECT gry_id_meczu FROM graczezawodowi_gry WHERE gracze_zawodowi_nick = @pNick);
	END
	ELSE
	BEGIN 
		SELECT @vSrednieKDA = ROUND((CAST((SUM(zabojstwa) + SUM(asysty)) AS FLOAT)) / CAST(SUM(smierci) AS FLOAT),2)
		FROM gry WHERE id_meczu IN (SELECT gry_id_meczu FROM gracze_gry WHERE gracze_nick = @pNick);
	END;

	RETURN @vSrednieKDA;
END;
GO
--Przykladowe wywolanie
--SELECT dbo.srednie_KDA('Jankos', 'T')
--SELECT dbo.srednie_KDA('Quavenox', 'N')

-------------------------------------------------------------------------------------------------------------------

-- Procedura zwracajaca 3 najczesciej rozgrywanych bohaterow danego gracza

CREATE PROCEDURE top3_rozgrywani_bohaterowie(@pNick VARCHAR(20), @pro CHAR(1))
AS
BEGIN
	IF @pro = 'T'
	BEGIN
		SELECT TOP 3 bohaterowie_nazwa
		FROM gry
		WHERE id_meczu IN (SELECT gry_id_meczu FROM graczezawodowi_gry WHERE gracze_zawodowi_nick = @pNick)
		GROUP BY bohaterowie_nazwa
		ORDER BY COUNT(*) DESC;
	END
	ELSE
	BEGIN
		SELECT TOP 3 bohaterowie_nazwa
		FROM gry
		WHERE id_meczu IN (SELECT gry_id_meczu FROM gracze_gry WHERE gracze_nick = @pNick)
		GROUP BY bohaterowie_nazwa
		ORDER BY COUNT(*) DESC;
	END;
END;
GO
--Przykladowe wywolanie
--EXEC top3_rozgrywani_bohaterowie 'Jankos', 'T'
--EXEC top3_rozgrywani_bohaterowie 'Quavenox', 'N'

-------------------------------------------------------------------------------------------------------------------

-- Procedura zwracajaca najczesciej rozgrywanego bohatera danego gracza

CREATE PROCEDURE top1_rozgrywani_bohaterowie(@pNick VARCHAR(20), @pro CHAR(1))
AS
BEGIN
	IF @pro = 'T'
	BEGIN
		SELECT TOP 1 bohaterowie_nazwa
		FROM gry
		WHERE id_meczu IN (SELECT gry_id_meczu FROM graczezawodowi_gry WHERE gracze_zawodowi_nick = @pNick)
		GROUP BY bohaterowie_nazwa
		ORDER BY COUNT(*) DESC;
	END
	ELSE
	BEGIN
		SELECT TOP 1 bohaterowie_nazwa
		FROM gry
		WHERE id_meczu IN (SELECT gry_id_meczu FROM gracze_gry WHERE gracze_nick = @pNick)
		GROUP BY bohaterowie_nazwa
		ORDER BY COUNT(*) DESC;
	END;
END;
GO
--Przykladowe wywolanie
--EXEC top1_rozgrywani_bohaterowie 'Jankos', 'T'
--EXEC top1_rozgrywani_bohaterowie 'Quavenox', 'N'

-------------------------------------------------------------------------------------------------------------------

--Procedura zwracjaca wszystkie turnieje w ktorych brala udzial druzynya o podanym id

CREATE PROCEDURE turnieje_druzyny(@pId VARCHAR(6))
AS
BEGIN
	SELECT *
	FROM turnieje
	WHERE id_druzyny = @pId;
END;
GO
--Przykladowe wywolanie
--EXEC turnieje_druzyny 'AST'

-------------------------------------------------------------------------------------------------------------------

--Procedura dodająca przedmiot o podanej nazwie do danego meczu
CREATE PROCEDURE dodaj_przedmiot_do_gry (@pIdMeczu BIGINT, @pNazwaPrzedmiotu CHAR(100))
AS
BEGIN
DECLARE @idPrzed INT;
DECLARE @liczbaPrzed INT;

SELECT @idPrzed = id_przed
FROM przedmioty
WHERE nazwa = @pNazwaPrzedmiotu;

IF @idPrzed IS NOT NULL
BEGIN
	SELECT @liczbaPrzed = COUNT(*)
	FROM gry_zakupioneprzedmioty
	WHERE id_meczu = @pIdMeczu;
	IF @liczbaPrzed < 6
	BEGIN
		INSERT INTO gry_zakupioneprzedmioty(id_meczu, id_zakupionego_przedmiotu)
		VALUES (@pIdMeczu, @idPrzed);
	END;
END;
END;
GO
--Przykladowe wywolanie
--EXEC dodaj_przedmiot_do_gry 201, 'Złodziej Esencji';

CREATE TABLE bohaterowie (
    nazwa       VARCHAR(20) NOT NULL,
    tytuł       VARCHAR(30) NOT NULL,
    krotki_opis VARCHAR(max) NOT NULL,
    atak        SMALLINT NOT NULL CHECK(atak BETWEEN 0 AND 10),
    obrona      SMALLINT NOT NULL CHECK(obrona BETWEEN 0 AND 10), 
    magia       SMALLINT NOT NULL CHECK(magia BETWEEN 0 AND 10),
    trudnosc    SMALLINT NOT NULL CHECK(trudnosc BETWEEN 0 AND 10),
    obraz       VARCHAR(max) NOT NULL,
	ikona		VARCHAR(max) NOT NULL,
    klasa       VARCHAR(20) NOT NULL CHECK(klasa IN ('Assassin', 'Fighter', 'Mage', 'Marksman', 'Support', 'Tank'))
);

CREATE INDEX bohaterowie__idx ON
    bohaterowie (
        nazwa
    ASC );

ALTER TABLE bohaterowie ADD CONSTRAINT bohaterowie_pk PRIMARY KEY ( nazwa );

CREATE TABLE dane_logowania (
    nick                        VARCHAR(20) NOT NULL,
    haslo                       VARCHAR(100) NOT NULL,
    rola 						VARCHAR(30) NOT NULL
);

ALTER TABLE dane_logowania ADD CONSTRAINT dane_logowania_pk PRIMARY KEY ( nick );

CREATE TABLE druzyny (
    id_druzyny         VARCHAR(6) NOT NULL,
    nazwa              VARCHAR(50) NOT NULL,
	opis			   VARCHAR(max) NOT NULL,
    liga             VARCHAR(20) NOT NULL CHECK (liga IN ('LCK', 'LPL', 'LCS', 'LEC', 'PCS', 'VCS', 'CBLOL', 'LJL', 'LLA')),
    logo               VARCHAR(max) NOT NULL,
    zdjecie_zawodnikow VARCHAR(max)
);

ALTER TABLE druzyny ADD CONSTRAINT druzyny_pk PRIMARY KEY ( id_druzyny );

CREATE TABLE gracze (
    nick             VARCHAR(20) NOT NULL,
    dywizja          VARCHAR(15) NOT NULL CHECK (dywizja IN ('Challenger','Grand Master','Master',
	'Diamond I','Diamond II','Diamond III','Diamond IV','Platinum I','Platinum II','Platinum III',
		'Platinum IV','Gold I','Gold II','Gold III','Gold IV','Silver I','Silver II','Silver III',
		'Silver IV','Bronze I','Bronze II','Bronze III','Bronze IV','Iron I','Iron II','Iron III',
		'Iron IV','Unranked')),
    poziom           SMALLINT NOT NULL CHECK(poziom > 0),
    ulubiony_bohater VARCHAR(20)
);

ALTER TABLE gracze ADD CONSTRAINT gracze_pk PRIMARY KEY ( nick );

CREATE TABLE gracze_gry (
    gracze_nick  VARCHAR(20) NOT NULL,
    gry_id_meczu BIGINT NOT NULL
);

ALTER TABLE gracze_gry ADD CONSTRAINT gracze_gry_pk PRIMARY KEY ( gracze_nick,
                                                                  gry_id_meczu );

CREATE TABLE gracze_zawodowi (
    nick             VARCHAR(20) NOT NULL,
    imie_i_nazwisko  VARCHAR(50) NOT NULL,
    kraj             VARCHAR(30) NOT NULL,
    rola             VARCHAR(9) NOT NULL CHECK (rola IN ('Top Laner', 'Support', 'Jungler', 'Mid Laner', 'Bot Laner')),
    rezydencja       VARCHAR(20) NOT NULL CHECK (rezydencja IN ('North America', 'EMEA', 'Europe', 'Turkey', 'CIS', 'Korea
', 'China', 'PCS', 'Brazil', 'Japan', 'Latin America', 'Oceania', 'Vietnam')),
    zdjecie          VARCHAR(max),
    data_urodzin     DATETIME2(0),
    id_druzyny       VARCHAR(6),
    ulubiony_bohater VARCHAR(20)
);

CREATE INDEX gracze_zawodowi__idx ON
    gracze_zawodowi (
        nick
    ASC );

ALTER TABLE gracze_zawodowi ADD CONSTRAINT gracze_zawodowi_pk PRIMARY KEY ( nick );

CREATE TABLE graczezawodowi_gry (
    gracze_zawodowi_nick VARCHAR(20) NOT NULL,
    gry_id_meczu         BIGINT NOT NULL
);

ALTER TABLE graczezawodowi_gry ADD CONSTRAINT graczezawodowi_gry_pk PRIMARY KEY ( gracze_zawodowi_nick,
                                                                                  gry_id_meczu );

CREATE TABLE gry (
    id_meczu          BIGINT NOT NULL IDENTITY,
    rezultat          VARCHAR(4) NOT NULL CHECK (rezultat IN ('WIN', 'LOSE')),
    zabojstwa         SMALLINT NOT NULL CHECK (zabojstwa >= 0),
    smierci           SMALLINT NOT NULL CHECK (smierci >= 0),
    asysty            SMALLINT NOT NULL CHECK (asysty >= 0),
    creep_score       SMALLINT NOT NULL CHECK (creep_score >= 0),
    zdobyte_zloto     INT NOT NULL CHECK (zdobyte_zloto >= 0),
    czas_gry          TIME(0) NOT NULL,
    zadane_obrazenia  INT NOT NULL CHECK (zadane_obrazenia >= 0),
    zabojstwa_druzyny SMALLINT CHECK (zabojstwa_druzyny >= 0),
    zgony_druzyny     SMALLINT CHECK (zgony_druzyny >= 0),
    strona            VARCHAR(4) NOT NULL CHECK (strona IN ('RED','BLUE')),
    bohaterowie_nazwa VARCHAR(20),
    PRIMARY KEY (id_meczu)
);
    
CREATE TABLE gry_zakupioneprzedmioty (
	id 						  BIGINT NOT NULL IDENTITY,
    id_meczu                  BIGINT NOT NULL,
    id_zakupionego_przedmiotu INT NOT NULL
	PRIMARY KEY(id)
);

CREATE TABLE komponenty_przedmiotow (
    id            BIGINT NOT NULL IDENTITY,
    id_przed      INT NOT NULL,
    id_komponentu INT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX komponenty_przedmiotow__idx ON
    komponenty_przedmiotow (
        id_przed
    ASC,
        id_komponentu
    ASC );

CREATE TABLE kontry (
    bohater VARCHAR(20) NOT NULL,
    kontra  VARCHAR(20) NOT NULL
);

ALTER TABLE kontry ADD CONSTRAINT kontry_pk PRIMARY KEY ( bohater,
                                                          kontra );

CREATE TABLE przedmioty (
    id_przed          INT NOT NULL,
    nazwa             CHAR(100) NOT NULL,
    statystyki         VARCHAR(max) NOT NULL,
    ikona             VARCHAR(max) NOT NULL,
    cena              SMALLINT CHECK(cena >= 0),
    wartosc_sprzedazy SMALLINT CHECK (wartosc_sprzedazy >= 0)
);

CREATE INDEX przedmioty__idx ON
    przedmioty (
        id_przed
    ASC );

ALTER TABLE przedmioty ADD CONSTRAINT przedmioty_pk PRIMARY KEY ( id_przed );

CREATE TABLE turnieje (
    nazwa_turnieju     VARCHAR(70) NOT NULL,
    rodzaj             VARCHAR(8) NOT NULL CHECK (rodzaj IN ('ONLINE', 'OFFLINE')),
    data               DATETIME2(0) NOT NULL,
    zajete_miejsce     SMALLINT NOT NULL,
    ostatni_wynik      VARCHAR(10) NOT NULL,
    nagroda            DECIMAL(10, 5),
    id_druzyny VARCHAR(6) NOT NULL
);

ALTER TABLE turnieje ADD CONSTRAINT turnieje_pk PRIMARY KEY ( nazwa_turnieju,
                                                              id_druzyny );

ALTER TABLE gracze_zawodowi
    ADD CONSTRAINT bohaterowienazwapro_fk FOREIGN KEY ( ulubiony_bohater )
        REFERENCES bohaterowie ( nazwa )
        ON DELETE SET NULL;

ALTER TABLE gracze
    ADD CONSTRAINT bohaterowienazwareg_fk FOREIGN KEY ( ulubiony_bohater )
        REFERENCES bohaterowie ( nazwa )
		ON DELETE SET NULL;

ALTER TABLE dane_logowania
    ADD CONSTRAINT dane_logowania_gracze_fk FOREIGN KEY ( nick )
        REFERENCES gracze ( nick );

ALTER TABLE gracze_zawodowi
    ADD CONSTRAINT druzynyidpro_fk FOREIGN KEY ( id_druzyny )
        REFERENCES druzyny ( id_druzyny )
		ON DELETE SET NULL;

ALTER TABLE turnieje
    ADD CONSTRAINT druzynyidtur_fk FOREIGN KEY ( id_druzyny )
        REFERENCES druzyny ( id_druzyny )
		ON DELETE CASCADE;

ALTER TABLE gracze_gry
    ADD CONSTRAINT gracznick_fk FOREIGN KEY ( gracze_nick )
        REFERENCES gracze ( nick )
		ON DELETE CASCADE;

ALTER TABLE graczezawodowi_gry
    ADD CONSTRAINT graczzawodowynick_fk FOREIGN KEY ( gracze_zawodowi_nick )
        REFERENCES gracze_zawodowi ( nick )
		ON DELETE CASCADE;

ALTER TABLE gracze_gry
    ADD CONSTRAINT gragracz_fk FOREIGN KEY ( gry_id_meczu )
        REFERENCES gry ( id_meczu )
		ON DELETE CASCADE;

ALTER TABLE graczezawodowi_gry
    ADD CONSTRAINT gragraczzawodowy_fk FOREIGN KEY ( gry_id_meczu )
        REFERENCES gry ( id_meczu )
		ON DELETE CASCADE;

ALTER TABLE gry_zakupioneprzedmioty
    ADD CONSTRAINT graidmeczu_fk FOREIGN KEY ( id_meczu )
        REFERENCES gry ( id_meczu )
		ON DELETE CASCADE;

ALTER TABLE gry
    ADD CONSTRAINT gry_bohaterowie_fk FOREIGN KEY ( bohaterowie_nazwa )
        REFERENCES bohaterowie ( nazwa )
		ON DELETE SET NULL;

ALTER TABLE kontry
    ADD CONSTRAINT kontry_bohaterowie_fk FOREIGN KEY ( bohater )
        REFERENCES bohaterowie ( nazwa )
		ON DELETE CASCADE;

ALTER TABLE kontry
    ADD CONSTRAINT kontry_bohaterowie_fkv1 FOREIGN KEY ( kontra )
        REFERENCES bohaterowie ( nazwa )

ALTER TABLE komponenty_przedmiotow
    ADD CONSTRAINT przedmiotyid1_fk FOREIGN KEY ( id_przed )
        REFERENCES przedmioty ( id_przed )
		ON DELETE CASCADE;

ALTER TABLE komponenty_przedmiotow
    ADD CONSTRAINT przedmiotyid2_fk FOREIGN KEY ( id_komponentu )
        REFERENCES przedmioty ( id_przed );

ALTER TABLE gry_zakupioneprzedmioty
    ADD CONSTRAINT przedmiotid3_fk FOREIGN KEY ( id_zakupionego_przedmiotu )
        REFERENCES przedmioty ( id_przed )
		ON DELETE CASCADE;

INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Aatrox', 'Ostrze Darkinów', 'Aatrox i jego pobratymcy, kiedyś szanowani obrońcy Shurimy przed Pustką, ostatecznie stali się jeszcze większym zagrożeniem dla Runeterry niż sama Pustka i zostali pokonani tylko dzięki przebiegłym czarom śmiertelników. Lecz po latach spędzonych w więzieniu Aatrox był pierwszym, który ponownie wydostał się na wolność, spaczając i przemieniając wszystkich wystarczająco głupich, by spróbować władania magiczną bronią, która zawierała jego esencję. Teraz wędruje po Runeterze z ukradzioną powłoką skrzywioną na brutalne podobieństwo swej poprzedniej postaci i pragnie apokaliptycznej zemsty, której powinien był dokonać już dawno.', 8, 4, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Aatrox_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Aatrox.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ahri', 'Lisica o Dziewięciu Ogonach', 'Ahri to Vastajanka naturalnie połączona z magią krążącą po Runeterze, która może zmieniać energię magiczną w kule czystej energii. Uwielbia bawić się swoimi ofiarami i manipulować ich emocjami, aby później pożreć ich esencję życiową. Pomimo drapieżnej natury Ahri odczuwa empatię, ponieważ wraz z pochłanianymi duszami otrzymuje przebłyski ich wspomnień.', 3, 4, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ahri_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ahri.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Akali', 'Skryta Zabójczyni', 'Opuściwszy Zakon Kinkou i wyzbywszy się tytułu Pięści Cienia, Akali działa w pojedynkę, gotowa stać się śmiercionośną bronią, której jej lud tak bardzo potrzebował. Choć nie wyrzekła się wiedzy, którą przekazał jej mistrz Shen, poprzysięgła zabijać wrogów Ionii jednego po drugim. Akali uderza wprawdzie w niczym niezmąconej ciszy, ale jej przesłanie rozbrzmiewa z wielką mocą: bój się zabójczyni bez mistrza.', 5, 3, 8, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Akali_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Akali.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Akshan', 'Zbuntowany Strażnik', 'Ledwie unoszący brew w obliczu niebezpieczeństwa Akshan walczy ze złem, wykorzystując swoją oszałamiającą charyzmę, pragnienie dokonania słusznej zemsty i rzucający się w oczy brak jakiejkolwiek koszuli. Wyróżnia się niesamowitymi umiejętnościami prowadzenia walki z ukrycia — potrafi unikać spojrzeń wrogów, by wyłonić się przed nimi, gdy najmniej się tego spodziewają. Wraz ze swoim gorliwym poczuciem sprawiedliwości oraz legendarną bronią potrafiącą odwrócić śmierć Akshan naprawia krzywdy wyrządzone przez zamieszkujących Runeterrę nikczemników. Sam żyje według własnego kodu moralnego, który brzmi: „Nie bądź dupkiem”.', 0, 0, 0, 0, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Akshan_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Akshan.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Alistar', 'Minotaur', 'Jako potężny wojownik z przerażającą reputacją, Alistar chce zemścić się za wytępienie jego klanu przez noxiańskie imperium. Pomimo że zniewolono go i zmuszono do walk na arenie, jego niezłomna wola powstrzymywała go od stania się bestią. Teraz, wolny od łańcuchów starych panów, walczy w imię uciskanych i ubogich. Wściekłość jest jego bronią tak samo jak rogi, kopyta i pięści.', 6, 9, 5, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Alistar_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Alistar.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Amumu', 'Smutna Mumia', 'Legenda mówi, że Amumu to samotna i melancholijna istota z antycznej Shurimy, przemierzająca świat w poszukiwaniu przyjaciela. Na wieczną samotność skazała go starożytna klątwa, w wyniku której jego dotyk przynosi śmierć, a jego sympatia — zgubę. Ci, którzy twierdzą, że widzieli Amumu, opisują go jako żywego trupa o niewielkiej posturze, całkowicie owiniętego odłażącymi bandażami. Nikt jednak nie wie, jaki naprawdę jest Amumu. Prawda i fikcja przeplatają się ze sobą wśród przekazywanych z pokolenia na pokolenie mitów, bajań i pieśni zainspirowanych jego postacią.', 2, 6, 8, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Amumu_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Amumu.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Anivia', 'Kriofeniks', 'Anivia to dobrotliwy, skrzydlaty duch, który stawia czoło niekończącym się cyklom życia, śmierci i odrodzenia, by chronić Freljord. Półbogini zrodzona z bezlitosnego lodu i wichrów, posiada moce żywiołów, które zatrzymają każdego, kto zakłóci spokój jej ojczyzny. Anivia strzeże i chroni plemiona z mroźnej północy, które czczą ją jako symbol nadziei i znak wielkich zmian. Walczy każdą cząstką siebie, bo wie, że dzięki jej poświęceniu jej pamięć przetrwa, a ona sama odrodzi się w nowym dniu.', 1, 4, 10, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Anivia_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Anivia.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Annie', 'Dziecko Ciemności', 'Niebezpieczna, lecz przedwcześnie dojrzała Annie, jest dzieckiem o nieprawdopodobnych zdolnościach związanych z piromanią. Nawet w cieniach gór na północ od Noxusu jest magicznym ewenementem. Jej naturalne zamiłowanie do ognia uzewnętrzniło się wcześnie pod postacią nieprzewidywalnych wybuchów emocji. Z czasem jednak nauczyła się kontrolować te „sztuczki”. Do jej ulubionych czynności należy przyzywanie ukochanego misia, Tibbersa, jako ognistego obrońcy. Zagubiona w wiecznej, dziecięcej niewinności, Annie przemierza ciemne lasy, zawsze poszukując kogoś do zabawy.', 2, 3, 10, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Annie_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Annie.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Aphelios', 'Broń Wiernych', 'Wychodząc z bronią w ręce z cienia rzucanego przez księżyc, Aphelios zabija wrogów swojej wiary w złowrogiej ciszy — przemawia tylko poprzez niesamowitą celność i strzały z pistoletów. Choć napędza go trucizna czyniąca z niego niemowę, to kieruje nim jego siostra Alune. Z odległego świątynnego sanktuarium wpycha arsenał broni z kamienia księżycowego w jego ręce. Albowiem tak długo, jak księżyc świeci nad jego głową, Aphelios nigdy nie będzie sam.', 6, 2, 1, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Aphelios_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Aphelios.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ashe', 'Lodowa Łuczniczka', 'Córa Lodu i wojmatka avarosańskiego plemienia, Ashe włada najliczniejszą hordą na całej północy. Stoicka, inteligentna i idealistyczna, lecz nie czująca się pewnie w swej roli przywódczyni, czerpie z magii przodków, by władać łukiem Prawdziwego Lodu. Skoro jej ludzie wierzą, że to ona jest wcieleniem mitycznej bohaterki Avarosy, Ashe ma nadzieję na wtórne zjednoczenie Freljordu poprzez ponowne zajęcie starożytnych ziem jej plemienia.', 7, 3, 2, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ashe_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ashe.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Aurelion Sol', 'Architekt Gwiazd', 'Aurelion Sol niegdyś ozdabiał nieprzebraną pustkę kosmosu astralnymi cudami swojego autorstwa. Teraz musi wykorzystywać swoją straszliwą moc, by usługiwać kosmicznemu imperium, które podstępem go zniewoliło. Pragnąc powrócić do czasów, gdy tworzył gwiazdy, Aurelion Sol gotów jest zedrzeć je z nieba — byle tylko odzyskać wolność.', 2, 3, 8, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/AurelionSol_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/AurelionSol.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Azir', 'Imperator Pustyni', 'Azir był śmiertelnym imperatorem Shurimy w dawnych czasach, dumnym mężczyzną, który był o krok od zyskania nieśmiertelności. Jego arogancka duma doprowadziła do tego, że zdradzono i zamordowano go w chwili największego triumfu. Jednak teraz, wiele tysiącleci później, odrodził się jako Wyniesiona istota o bezgranicznej mocy. Jego pogrzebane wśród piasków miasto raz jeszcze powstało, a Azir pragnie przywrócić imperium Shurimy dawną chwałę.', 6, 3, 8, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Azir_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Azir.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Bard', 'Wędrujący Opiekun', 'Podróżnik spoza gwiazd, Bard, jest patronem szczęśliwych przypadków, walczącym, by zachować równowagę, dzięki której życie może przetrwać obojętność chaosu. Wielu mieszkańców Runeterry śpiewa piosenki, które wychwalają jego niecodzienny charakter, lecz wszyscy zgadzają się, że ten kosmiczny włóczykij ma pociąg do artefaktów o wielkiej mocy. Bard zwykle jest otoczony przez rozradowany chór pomocnych meepów i nie można przyjąć jego czynów za złe, ponieważ on zawsze służy większemu dobru... na swój własny, dziwny sposób.', 4, 4, 5, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Bard_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Bard.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Bel''Veth', 'Cesarzowa Pustki', 'Bel''Veth, koszmarna cesarzowa zrodzona z czystej esencji pochłoniętego w całości miasta, zwiastuje koniec obecnej Runeterry… i początek potwornej rzeczywistości, którą tworzy wedle własnego uznania. Milenia przeinaczania historii, wiedzy i wspomnień ze świata powyżej każą jej nieustannie karmić swoją wiecznie rosnącą potrzebę poznawania nowych doświadczeń i emocji, więc pochłania wszystko, co stanie jej na drodze. Jeden świat nie wystarczy jednak, aby zaspokoić jej żądze, a więc Bel''Veth kieruje swoje wygłodniałe spojrzenie ku dawnym panom Pustki…', 4, 2, 7, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Belveth_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Belveth.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Blitzcrank', 'Wielki Golem Parowy', 'Blitzcrank to ogromny, prawie niezniszczalny automat z Zaun, zbudowany w celu pozbywania się radioaktywnych odpadów. Pewnego dnia stwierdził, że jego zadanie nadto go ogranicza, więc zmodyfikował się, by lepiej służyć delikatnym ludziom ze Slumsów. Blitzcrank bezinteresownie używa swojej siły i wytrzymałości w ramach pomagania innym. Wyciąga pomocną pięść lub eksplozję energii do okiełznania wszystkich rzezimieszków.', 4, 8, 5, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Blitzcrank_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Blitzcrank.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Brand', 'Płomień Zemsty', 'Kiedyś członek plemienia lodowego Freljordu, imieniem Kegan Rodhe, istota znana jako Brand jest lekcją na temat pokus większej mocy. Podczas poszukiwania jednej z legendarnych Run Świata, Kegan zdradził swoich towarzyszy i zgarnął ją dla siebie — po chwili już go nie było. Jego dusza się wypaliła, a ciało stało się nośnikiem żywego ognia. Brand wędruje teraz po Valoranie, szukając innych Run i poprzysiągł zemstę za krzywdy, których nie mógłby doświadczyć nawet w ciągu parunastu śmiertelnych żyć.', 2, 2, 9, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Brand_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Brand.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Braum', 'Serce Freljordu', 'Dzięki potężnym bicepsom i jeszcze większemu sercu Braum jest ukochanym bohaterem Freljordu. Cały miód pitny na północ od Mroźnej Przystani jest wypijany za jego legendarną siłę, o której mówi się, że jest zdolna do powalenia całego dębowego lasu w ciągu jednej nocy i obrócenia góry w proch. Dzierżąc zaklęte drzwi skarbca jako tarczę, Braum, prawdziwy przyjaciel dla tych w biedzie, wędruje po mroźnej północy z wąsatym uśmiechem na twarzy tak dużym jak jego mięśnie.', 3, 9, 4, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Braum_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Braum.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Caitlyn', 'Szeryf Piltover', 'Znana jako najlepsza rozjemczyni, Caitlyn jest również najlepszą szansą Piltover na pozbycie się nieuchwytnych elementów kryminalnych z miasta. Często w parze z Vi, jest przystanią spokoju w porównaniu z żywiołowym charakterem jej partnerki. Pomimo tego, że korzysta z jedynego w swoim rodzaju karabinu pulsarowego, najpotężniejszą bronią Caitlyn jest jej ponadprzeciętna inteligencja, która pozwala jej na zastawianie skomplikowanych pułapek na przestępców na tyle głupich, by działać w Mieście Postępu.', 8, 2, 2, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Caitlyn_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Caitlyn.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Camille', 'Stalowy Cień', 'Wyposażona, aby działać poza granicami prawa, Camille jest główną wywiadowczynią rodu Ferros oraz elegancką i elitarną agentką, która upewnia się, że maszyna Piltover oraz jej zauńskie podbrzusze działają prawidłowo. Zdolna do przystosowywania się oraz przykładania uwagi do szczegółów, uważa wszelkie przejawy zaniedbania za wstyd, który trzeba zmazać. Camille posiada umysł równie ostry, co ostrza, których używa, a ciągłe ulepszanie ciała za pomocą hextechowych wzmocnień sprawiło, że wiele osób się zastanawia, czy nie stała się bardziej maszyną niż kobietą.', 8, 6, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Camille_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Camille.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Cassiopeia', 'Wężowy Uścisk', 'Cassiopeia jest śmiertelną istotą zdeterminowaną, by manipulować innymi zgodnie z jej niegodziwą wolą. Najmłodsza i najpiękniejsza córka szlachetnej, noxiańskiej rodziny Du Couteau, odbyła wyprawę w poszukiwaniu mocy głęboko do krypt pod Shurimą. Została tam ugryziona przez przerażającego strażnika grobowca, którego jad zmienił ją w żmiję drapieżnika. Przebiegła i zwinna, Cassiopeia pełza pod osłoną nocy, by obracać przeciwników w kamień swym zgubnym spojrzeniem.', 2, 3, 9, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Cassiopeia_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Cassiopeia.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Cho''Gath', 'Postrach Pustki', 'Od momentu, w którym Cho''Gath pierwszy raz wynurzył się na ostre światło słońca Runeterry, napędza go najczystszy i niezaspokojony głód. Cho''Gath jest przykładowym wyrazem żądzy Pustki do pożerania wszystkiego, co żyje, a jego skomplikowana biologia szybko przetwarza materię na rozrost ciała, zwiększając masę i gęstość mięśni lub czyniąc jego zewnętrzny pancerz twardym jak diament. Kiedy rośnięcie nie pasuje pomiotowi Pustki, wymiotuje nadmiar materiału pod postacią ostrych jak brzytwa kolców, które przebijają ofiary, przygotowując je na późniejszą ucztę.', 3, 7, 7, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Chogath_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Chogath.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Corki', 'Dzielny Bombardier', 'Yordlowy pilot Corki najbardziej kocha dwie rzeczy: latanie i swoje olśniewające wąsy... choć niekoniecznie w tej kolejności. Po opuszczeniu Bandle City osiedlił się w Piltover i zakochał się w niezwykłych maszynach, które tam znalazł. Poświęcił się rozwojowi swoich latających wynalazków, przewodząc obronnym siłom powietrznym złożonym z zaprawionych weteranów, znanych jako Wrzeszczące Węże. Spokojny nawet pod ostrzałem, Corki patroluje niebo wokół swojego przybranego domu i nigdy nie napotyka takiego problemu, którego nie dałoby się rozwiązać za pomocą dobrego ognia zaporowego.', 8, 3, 6, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Corki_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Corki.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Darius', 'Ręka Noxusu', 'Nie ma lepszego symbolu noxiańskiej siły niż Darius, siejący strach w sercach całego narodu i najbardziej zaprawiony w bojach dowódca. Zaczynał skromnie, by w końcu zostać Ręką Noxusu i za pomocą topora rozprawiać się z wrogami imperium, którzy czasami okazują się być Noxianami. Wiedząc, że Darius nigdy nie wątpi w nieomylność swojej sprawy i nigdy nie waha się, gdy jego topór jest w górze, ci, którzy przeciwstawiają się liderowi Legionu Tryfariańskiego, nie mogą liczyć na litość.', 9, 5, 1, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Darius_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Darius.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Diana', 'Pogarda Księżyca', 'Diana, wyposażona w zakrzywione, księżycowe ostrze, jest wojowniczką Lunari – członków wyznania, które praktycznie już nie istnieje na terenach otaczających Górę Targon. Odziana w lśniącą zbroję w kolorze nocnego śniegu, jest żywym ucieleśnieniem mocy srebrnego księżyca. Przepełniona esencją Aspektu spoza szczytu Targonu, Diana nie jest już w pełni człowiekiem i stara się pojąć swoją moc i cel egzystencji na tym świecie.', 7, 6, 8, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Diana_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Diana.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Draven', 'Wielki Oprawca', 'W Noxusie wojownicy znani jako walecznicy mierzą się ze sobą na arenach, gdzie przelewa się krew, a siłę poddaje się próbie. Jednakże żaden z nich nie był tak sławny jak Draven. Były żołnierz doszedł do wniosku, że tłum docenia jego smykałkę do dramatyczności, jak i niedościgniony kunszt, z jakim włada wirującymi toporami. Uzależniony od pokazu bezczelnej perfekcji, Draven poprzysiągł pokonać wszystkich, by to jego imię wiecznie powtarzano w całym imperium.', 9, 3, 1, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Draven_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Draven.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Dr Mundo', 'Szaleniec z Zaun', 'Doszczętnie oszalały, tragicznie zabójczy i przerażająco fioletowy Dr Mundo jest przyczyną, dla której wielu mieszkańców Zaun nie opuszcza swoich domów w szczególnie ciemne noce. Ten samozwańczy lekarz był niegdyś pacjentem niesławnego ośrodka opieki dla obłąkanych. Po „uleczeniu” całego personelu placówki Dr Mundo założył własną przychodnię w opustoszałych salach szpitalnych, w których to na nim kiedyś przeprowadzano okrutne terapie. Zaczął w niej odtwarzać wysoce nieetyczne zabiegi, które przeżył na własnej skórze. Korzystając z pełnego dostępu do leków i zerowego wykształcenia medycznego, z każdym podanym sobie zastrzykiem Mundo zmienia się w coraz okropniejsze monstrum i terroryzuje nieszczęsnych „pacjentów”, którzy trafiają zbyt blisko jego gabinetu.', 5, 7, 6, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/DrMundo_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/DrMundo.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ekko', 'Chłopiec, który ujarzmił czas', 'Ekko, geniusz wychowany na ulicach Zaun, manipuluje czasem, aby każda sytuacja potoczyła się po jego myśli. Korzystając ze swojego własnego wynalazku, Napędu Zero, Ekko odkrywa nieskończone możliwości czasoprzestrzeni, aby stworzyć idealny moment. Choć ceni sobie swoją wolność ponad wszystko, to nie zawaha się pomóc przyjaciołom, gdy są w potrzebie. Dla przybyszów Ekko wydaje się dokonywać niemożliwych rzeczy za pierwszym razem, przy każdej rzeczy, którą robi.', 5, 3, 7, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ekko_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ekko.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Elise', 'Królowa Pająków', 'Elise jest niebezpiecznym drapieżnikiem, który siedzibę ma w zamkniętym i mrocznym pałacu, mieszczącym się głęboko w najstarszym mieście Noxusu. Kiedyś była śmiertelniczką, damą z potężnego rodu, ale ukąszenie nikczemnego pajęczego półboga zmieniło ją w coś pięknego, lecz całkowicie nieludzkiego — w pajęcze stworzenie, wabiące niespodziewające się ofiary w swoją sieć. Aby zachować wieczną młodość, poluje na naiwnych i niewiernych ludzi, a tylko nieliczni są w stanie oprzeć się jej sztuce uwodzenia.', 6, 5, 7, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Elise_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Elise.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Evelynn', 'Uścisk Śmierci', 'W mrocznych zakątkach Runeterry demoniczna Evelynn poszukuje następnej ofiary. Wabi ją, przyjmując ludzką, ponętną postać kobiety, a gdy ta ulegnie jej wdziękom, pokazuje swoje prawdziwe ja. Następnie poddaje ją niewyobrażalnym mękom, zaspokajając się jej bólem. Dla demonicznej Evelynn tego typu przygody to jedynie niewinne romanse. Natomiast dla reszty Runeterry to makabryczne opowieści o pożądaniu, które wymknęło się spod kontroli, i przerażające przypomnienie o tym, do czego mogą doprowadzić nieokiełznane żądze.', 4, 2, 7, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Evelynn_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Evelynn.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ezreal', 'Odkrywca z Powołania', 'Ezreal, prężny poszukiwacz przygód, nieświadomy swojego daru magicznego, przeszukuje dawno zaginione katakumby, zadziera ze starożytnymi klątwami i z łatwością radzi sobie z na pierwszy rzut oka niemożliwymi do pokonania przeszkodami. Jego odwaga i zuchwałość nie znają granic, a on sam woli wychodzić z nieciekawych sytuacji drogą improwizacji, częściowo polegając na sprycie, ale głównie na mistycznej, shurimańskiej rękawicy, której używa, by wyzwalać niszczycielskie, magiczne wybuchy. Jedno jest pewne — kiedy Ezreal jest w pobliżu, kłopoty nie pozostają daleko w tyle. Nie wybiegają też zbyt daleko w przód. W sumie to pewnie są wszędzie.', 7, 2, 6, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ezreal_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ezreal.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Fiddlesticks', 'Prastary Strach', 'Coś zbudziło się w Runeterze. Coś prastarego. Okropnego. Ponadczasowa potworność, znana jako Fiddlesticks, grasuje wśród śmiertelników. Przyciągają ją obszary pełne paranoi, gdzie żeruje na przerażonych ofiarach. To dzierżące kosę szpetne, wyglądające jakby miało się rozpaść stworzenie, zbiera owoc strachu i doprowadza do szaleństwa nieszczęśników, którym udało się przetrwać spotkanie z nim. Wystrzegajcie się krakania i szeptów kształtu <i>przypominającego</i> ludzki... Fiddlesticks powrócił.', 2, 3, 9, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Fiddlesticks_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Fiddlesticks.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Fiora', 'Mistrzyni Fechtunku', 'Fiora to fechmistrzyni, o której słyszano w całym Valoranie. Zasłynęła zarówno niezłomnością i ciętym językiem, jak i mistrzostwem w szermierce. Będąc córką domu Laurent z Demacii, Fiora przejęła kontrolę nad swoim rodem od ojca w obliczu skandalu, który niemal ich zniszczył. Choć reputacja domu Laurent została zszargana, Fiora robi wszystko, co tylko możliwe, aby przywrócić jego utracony honor i należyte miejsce wśród wielkich i wspaniałych rodów Demacii.', 10, 4, 2, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Fiora_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Fiora.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Fizz', 'Szachraj Sztormów', 'Fizz jest amfibiotycznym Yordlem, który żyje pośród raf otaczających Bilgewater. Często wyławia i zwraca dziesięciny wrzucane do morza przez przesądnych kapitanów, ale nawet najbardziej doświadczeni z żeglarzy wiedzą, żeby mu się nie sprzeciwiać — wszak jest wiele opowieści o tych, którzy nie docenili tej nieuchwytnej postaci. Często mylony z wcieleniem kapryśnego ducha oceanu, sprawia wrażenie, że potrafi dowodzić ogromną, mięsożerną bestią z otchłani, i czerpie przyjemność z wprowadzania w zakłopotanie tak samo sojuszników, jak i wrogów.', 6, 4, 7, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Fizz_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Fizz.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Galio', 'Kolos', 'Kamienny kolos Galio strzeże lśniącego miasta zwanego Demacia. Zbudowany w celu obrony przed wrogimi magami, często stoi bez ruchu przez wiele dekad, dopóki obecność potężnej magii go nie ożywi. Gdy to nastąpi, Galio wykorzystuje ten czas jak najlepiej, rozkoszując się walką i ciesząc, że może bronić krajan. Jednakże jego sukcesy nie niosą radości, ponieważ magia, którą zwalcza, jest powodem jego ożywienia i po każdym zwycięstwie ponownie zapada w sen.', 1, 10, 6, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Galio_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Galio.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Gangplank', 'Postrach Siedmiu Mórz', 'Równie nieprzewidywalny, co brutalny, zdetronizowany król łupieżców Gangplank wzbudza strach na całym świecie. Kiedyś dowodził miastem portowym Bilgewater, i choć jego panowanie się skończyło, są tacy, którzy twierdzą, że uczyniło go to jeszcze bardziej niebezpiecznym. Gangplank raczej by utopił Bilgewater we krwi, niż oddał je komuś innemu. Teraz, uzbrojony w pistolet, kordelas i beczki prochu, jest zdeterminowany, by odebrać to, co utracił.', 7, 6, 4, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Gangplank_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Gangplank.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Garen', 'Potęga Demacii', 'Dumny i szlachetny wojownik, Garen jest jednym z członków Nieustraszonej Gwardii. Jego koledzy cenią go, a przeciwnicy szanują — zwłaszcza, że jest potomkiem szanowanego rodu Obrońców Korony, któremu powierzono trzymanie pieczy nad Demacią i jej ideałami. Odziany w zbroję odporną na magię, Garen i jego potężny miecz są gotowi stawić czoła magom i czarodziejom na polu bitwy w prawdziwym wirze prawej stali.', 7, 7, 1, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Garen_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Garen.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Gnar', 'Brakujące Ogniwo', 'Gnar jest pierwotnym Yordlem, którego dziecinne wygłupy mogą w mgnieniu oka przerodzić się w wybuch gniewu, zmieniając go w ogromną bestię zdeterminowaną, by niszczyć. Zamrożony w Prawdziwym Lodzie przez tysiąclecia, to ciekawskie stworzenie wydostało się zeń i teraz skacze po świecie pełnym zmian, który postrzega jako egzotyczny i niezwykły. Czerpiąc przyjemność z niebezpieczeństwa, Gnar rzuca w przeciwników czymkolwiek tylko może — kościanym bumerangiem lub pobliskim budynkiem.', 6, 5, 5, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Gnar_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Gnar.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Gragas', 'Karczemny Zabijaka', 'Równie wesoły, co okazały, Gragas jest ogromnym, bitnym piwowarem, który poszukuje perfekcyjnego kufla piwa. Jego pochodzenie jest nieznane, ale wiadomo, że teraz szuka rzadkich składników po nieskalanych pustkowiach Freljordu, próbując każdego przepisu po drodze. Często pijany i ekstremalnie impulsywny, przeszedł do legendy za wszczynane przez siebie bójki, które często kończą się na całonocnych imprezach i rozległych zniszczeniach mienia. Każde pojawienie się Gragasa z pewnością zwiastuje popijawę i zniszczenie — w tej kolejności.', 4, 7, 6, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Gragas_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Gragas.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Graves', 'Banita', 'Malcolm Graves jest znanym najemnikiem, szulerem i złodziejem, w dodatku jest poszukiwany w każdym mieście i imperium, jakie odwiedził. Pomimo że ma wybuchowy temperament, kieruje się złodziejskim honorem, który często pokazuje za pomocą swojej dwulufowej strzelby zwanej Losem. Ostatnimi laty zakopał topór wojenny z Twisted Fate''em i znów prosperują w zamęcie kryminalnego podbrzusza Bilgewater.', 8, 5, 3, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Graves_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Graves.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Gwen', 'Mglista Krawczyni', 'Gwen, niegdyś lalka, a teraz przemienione i dzięki magii powołane do życia dziewczę, dzierży te same narzędzia, które ją stworzyły. Z każdym krokiem niesie miłość swojej twórczyni i niczego nie uznaje za oczywistość. Włada Uświęconą Mgłą — pradawną magią ochronną, którą pobłogosławione zostały jej nożyce, igły i nici. Gwen nadal nie rozumie większości praw, jakimi rządzi się ten okrutny świat, a mimo to, nie utraciwszy pogody ducha, postanowiła podjąć się walki w imię wciąż obecnego w nim dobra.', 7, 4, 5, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Gwen_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Gwen.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Hecarim', 'Cień Wojny', 'Hecarim jest upiornym połączeniem człowieka i bestii, przeklętym, by przez całą wieczność gonić za duszami żyjących. Kiedy Błogosławione Wyspy pochłonął cień, ten dumny rycerz, z całą swoją kawalerią i wierzchowcami, został rozniesiony przez niszczące siły Zrujnowania. Teraz, kiedy Czarna Mgła rozpościera się przez całą Runeterrę, przewodzi ich niszczycielskiej szarży, karmiąc się rzezią i tratując wrogów swoimi opancerzonymi kopytami.', 8, 6, 4, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Hecarim_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Hecarim.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Heimerdinger', 'Wielbiony Wynalazca', 'Równie genialny, co ekscentryczny yordlowy naukowiec, Profesor Cecil B. Heimerdinger jest jednym z najbystrzejszych i uznanych naukowców, jakich znał Piltover. Pogrążony w pracy tak bardzo, że stała się jego obsesją, dąży do znalezienia odpowiedzi na najbardziej nieprzeniknione pytania wszechświata. Choć jego teorie często wydają się mgliste i tajemnicze, Heimerdinger stworzył jedne z najcudowniejszych, i zabójczych, maszyn Piltover. Ciągle grzebie przy swoich wynalazkach, by uczynić je jeszcze bardziej efektywnymi.', 2, 6, 8, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Heimerdinger_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Heimerdinger.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Illaoi', 'Kapłanka Krakena', 'Potężna budowa ciała Illaoi jest przyćmiona jedynie przez jej niezłomną wiarę. Jako prorok Wielkiego Krakena używa wielkiego, złotego posążka do wyrywania dusz wrogów z ich ciał, tym samym zaburzając ich postrzeganie rzeczywistości. Wszyscy, którzy odważą się przeciwstawić „Zwiastunce Prawdy Nagakabourossy”, wkrótce przekonają się, że Illaoi nigdy nie walczy w pojedynkę — bogini z Wysp Węży walczy u jej boku.', 8, 6, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Illaoi_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Illaoi.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Irelia', 'Tańcząca z Ostrzami', 'Ioniańska ziemia zrodziła wielu bohaterów pod noxiańską okupacją, ale żaden z nich nie był bardziej nadzwyczajny niż młoda Irelia z Navori. Została wyszkolona w starożytnej sztuce tańców swojej prowincji, a potem przystosowała ją do potrzeb wojny — wykorzystując dokładnie wyćwiczone, pełne wdzięku ruchy, by unosić w powietrzu szereg śmiercionośnych ostrzy. Gdy udowodniła swą wartość jako wojowniczka, postawiono ją w roli przywódczyni ruchu oporu i wzoru do naśladowania. Do dziś jest oddana ochronie ojczyzny.', 7, 4, 5, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Irelia_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Irelia.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ivern', 'Zielony Ojciec', 'Ivern Krzewobrody, znany też jako Zielony Ojciec, to jedyny w swoim rodzaju półczłowiek, półdrzewo. Wędruje przez lasy Runeterry, na każdym kroku starając się pielęgnować życie. Dobrze zna sekrety natury i przyjaźni się ze wszystkimi latającymi, biegającymi i rosnącymi w ziemi istotami. Ivern przemierza dzicz i dzieli się swoją niezwykłą wiedzą z każdym, kogo napotka, ubogaca las, a czasem nawet zdradza swoje sekrety wszędobylskim motylom.', 3, 5, 7, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ivern_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ivern.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Janna', 'Szał Burzy', 'Janna, uzbrojona w potęgę wichur Runeterry, jest tajemniczym duchem wiatru, który ochrania poszkodowanych z Zaun. Niektórzy ludzie uważają, że została zrodzona z błagań żeglarzy z Runeterry, którzy modlili się o przyjazne wiatry, gdy pływali po zdradliwych wodach i mierzyli się z potężnymi wichurami. Jej przychylność oraz ochrona zawitały w końcu do Zaun, gdzie stała się źródłem nadziei dla potrzebujących. Nikt nie wie, gdzie lub kiedy się pojawi, ale na ogół przybywa na pomoc.', 3, 5, 7, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Janna_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Janna.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Jarvan IV', 'Wzór dla Demacian', 'Książę Jarvan, potomek dynastii Promiennej Tarczy, jest następcą praw do tronu Demacii. Wychowany, by stać się przykładem cnót swojego narodu, jest zmuszony do żonglowania pomiędzy oczekiwaniami jego rodziców, a jego wolą do walki w pierwszej linii. Na polu walki inspiruje swoje oddziały zagrzewającą do boju odwagą i determinacją, pod niebiosa wynosząc barwy swojego rodu. To tam ujawnia się jego prawdziwa siła i zdolności przywódcze.', 6, 8, 3, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/JarvanIV_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/JarvanIV.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Jax', 'Mistrz Broni', 'Niedościgniony we władaniu wyjątkowymi broniami i w używaniu ciętego sarkazmu, Jax jest ostatnim znanym mistrzem broni z Icathii. Po tym jak jego ojczyzna w swojej aroganckiej dumie uwolniła Pustkę i została przez to zniszczona, Jax i jego pobratymcy przysięgli bronić tego, co zostało. Skoro magia zaczyna powracać do tego świata, a to zagrożenie ponownie czyha, Jax wędruje po Valoranie, niosąc ostatnie światło Icathii i poddając próbie wszystkich wojowników, których spotka, aby sprawdzić, czy są wystarczająco silni, by stanąć u jego boku...', 7, 5, 7, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Jax_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Jax.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Jayce', 'Obrońca Jutra', 'Jayce to genialny wynalazca, który poświęcił się obronie Piltover i nieugiętej służbie postępowi. Dzierżąc swój zmiennokształtny hextechowy młot, Jayce korzysta ze swej siły, odwagi i inteligencji, by chronić swoje miasto. Mieszkańcy uważają go za bohatera, ale nie podoba mu się to, że znalazł się na świeczniku. Mimo to, Jayce ma szczere chęci; nawet ci, którzy zazdroszczą mu umiejętności, są wdzięczni za to, że chroni Miasto Postępu.', 8, 4, 3, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Jayce_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Jayce.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Jhin', 'Wirtuoz', 'Jhin jest skrupulatnym, zbrodniczym psychopatą, który wierzy, że mordowanie jest sztuką. Niegdyś był więźniem w Ionii, lecz został uwolniony przez szemranych członków tamtejszej rady rządzącej, by teraz służyć im w ich intrygach w roli zabójcy. Jego pistolet jest mu jak pędzel, którego używa do tworzenia prac pełnych artystycznej brutalności, przerażając swe ofiary oraz obserwatorów. Jego makabryczny teatr sprawia mu okrutną przyjemność, co czyni z niego idealnego doręczyciela najmocniejszego z przekazów: przerażenia.', 10, 2, 6, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Jhin_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Jhin.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Jinx', 'Wystrzałowa Wariatka', 'Jinx to maniakalna i porywcza kryminalistka z Zaun, która lubi siać zniszczenie bez przejmowania się konsekwencjami. Wyposażona w arsenał morderczych broni, wywołuje najgłośniejsze wybuchy i najjaśniejsze eksplozje, pozostawiając za sobą chaos i panikę. Jinx nienawidzi nudy i radośnie rozsiewa pandemonium wszędzie, gdzie się uda.', 9, 2, 4, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Jinx_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Jinx.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kai''Sa', 'Córa Pustki', 'Kai''Sa, dziewczyna porwana przez Pustkę, kiedy była jeszcze dzieckiem, przetrwała tylko dzięki wytrwałości i sile woli. Jej przeżycia sprawiły, że stała się zabójczą łowczynią, choć dla niektórych jest zwiastunką przyszłości, której nie chcieliby dożyć. Wdawszy się w niestabilną symbiozę z żywym pancerzem z Pustki, w końcu będzie musiała zdecydować, czy wybaczyć śmiertelnikom, którzy nazywają ją potworem, i wspólnie z nimi pokonać nadchodzącą ciemność... czy może po prostu zapomnieć, a wtedy Pustka pożre świat, który się od niej odwrócił.', 8, 5, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kaisa_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kaisa.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kalista', 'Włócznia Zemsty', 'Kalista jest widmem przepełnionym gniewem i poszukującym odwetu, wiecznym duchem zemsty, zbrojnym koszmarem, który został przyzwany z Wysp Cienia, aby niszczyć oszustów i zdrajców. Wszyscy, którzy zostali zdradzeni, mogą wołać o pomstę, lecz Kalista odpowiada jedynie tym gotowym zapłacić swoimi duszami. Ci, którzy staną się obiektami gniewu Kalisty, powinni spisać swój testament, gdyż każdy układ zawarty z tą ponurą łowczynią może prowadzić jedynie do jej włóczni przeszywających dusze swym przenikliwym zimnem.', 8, 2, 4, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kalista_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kalista.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Karma', 'Oświecona', 'Żaden śmiertelnik nie obrazuje duchowych tradycji Ionii tak jak Karma. To uosobienie starożytnej duszy, która niezliczone razy powracała do życia, niosąc wszystkie zebrane wspomnienia w każde z nich. Jest obdarzona mocą, którą jedynie nieliczni są zdolni pojąć. W obliczu niedawnego kryzysu Karma czyni wszystko, co w jej mocy, by właściwie kierować ludźmi, choć dobrze wie, że pokój i harmonia zawsze mają wysoką cenę — zarówno dla niej samej, jak i dla krainy, która tak wiele dla niej znaczy.', 1, 7, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Karma_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Karma.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Karthus', 'Piewca Śmierci', 'Zwiastun nicości, Karthus, jest wiecznym duchem, nękającym swymi straszliwymi pieśniami. A są one jedynie wstępem do jego przerażającego wyglądu. Żywi lękają się wieczności nieumarłych, ale Karthus dostrzega w ich objęciach jedynie czystość i piękno, doskonałe zjednoczenie życia i śmierci. Jako orędownik nieumarłych, Karthus wyłania się z Wysp Cienia, aby sprowadzać radość śmierci na śmiertelników.', 2, 2, 10, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Karthus_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Karthus.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kassadin', 'Wędrowiec Pustki', 'Wycinając palące pasma pośród najmroczniejszych miejsc na świecie, Kassadin zrozumiał, że jego dni są policzone. Choć był obeznanym w świecie przewodnikiem i poszukiwaczem przygód z Shurimy, wybrał spokojne życie z rodziną pośród południowych plemion — do czasu, aż jego osada została pochłonięta przez Pustkę. Poprzysiągł zemstę. W trudną podróż zabrał wiele magicznych artefaktów i zakazanych wynalazków. Wreszcie Kassadin podążył w stronę pustkowi Icathii, gotowy stawić czoła wszelakim potworom z Pustki na drodze do odnalezienia ich samozwańczego proroka Malzahara.', 3, 5, 8, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kassadin_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kassadin.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Katarina', 'Złowieszcze Ostrze', 'Stanowcza w osądzie i zabójcza w walce, Katarina jest noxiańską zabójczynią największego kalibru. Najstarsza córka legendarnego generała Du Couteau, wsławiła się  talentami do szybkiego zabijania niczego niepodejrzewających wrogów. Jej ognisty zapał sprawił, że wybiera dobrze strzeżone cele, często ryzykując życiem sojuszników. Lecz niezależnie od zadania, Katarina nie będzie wahała się dopełnić obowiązku pośród wichury ząbkowanych sztyletów.', 4, 3, 9, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Katarina_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Katarina.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kayle', 'Sprawiedliwa', 'Kayle, córka targońskiego Aspektu urodzona w punkcie kulminacyjnym Wojen Runicznych, uhonorowała dziedzictwo swojej matki, wznosząc się na skrzydłach gorejących boskim ogniem, by walczyć o sprawiedliwość. Wraz ze swoją bliźniaczką Morganą latami były obrończyniami Demacii — dopóki Kayle nie rozczarowała się powtarzającymi się potknięciami śmiertelników i całkowicie opuściła ich wymiar. Mimo to legendy o tym, jak karała nieprawych swoimi ognistymi mieczami, wciąż są opowiadane, a wielu wierzy, że pewnego dnia powróci...', 6, 6, 7, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kayle_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kayle.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kayn', 'Żniwiarz Cienia', 'Niemający sobie równych w praktykowaniu zabójczej magii cienia, Shieda Kayn toczy boje o swoje prawdziwe przeznaczenie — czyli o to, by pewnego dnia poprowadzić Zakon Cienia ku nowej erze ioniańskiej dominacji. Posługuje się żywą bronią Darkinów zwaną Rhaastem, niezrażony tym, że powoli wypacza ona jego ciało i umysł. Ta sytuacja ma tylko dwa możliwe rozwiązania: albo Kayn zmusi broń do posłuszeństwa... albo złowieszcze ostrze pochłonie go całkowicie, doprowadzając do zniszczenia Runeterry.', 10, 6, 1, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kayn_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kayn.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kennen', 'Serce Nawałnicy', 'Kennen jest kimś więcej niż błyskawicznie szybkim stróżem ioniańskiej równowagi, jest jedynym yordlowym członkiem zakonu Kinkou. Mimo że jest małym i włochatym stworzeniem, chętnie stawi czoła wszystkim zagrożeniom za pomocą wirującej burzy shurikenów i dzięki niekończącemu się entuzjazmowi. U boku swojego mistrza Shena, Kennen patroluje duchowy wymiar, używając niszczącej elektrycznej energii, by zabijać wrogów.', 6, 4, 7, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kennen_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kennen.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kha''Zix', 'Łowca Pustki', 'Pustka rośnie, Pustka ewoluuje — to Kha''Zix spośród jej niezliczonych tworów jest najlepszym tego przykładem. Ewolucja napędza tego mutującego potwora, stworzonego do przetrwania wszystkiego i zabijania silnych. Jeśli mu się to nie udaje, wykształca nowe, bardziej efektywne sposoby radzenia sobie z ofiarami. Choć z początku był bezmyślną bestią, inteligencja Kha''Zixa rozwinęła się tak bardzo jak jego postać. Teraz, to stworzenie tworzy plany polowań i nawet wykorzystuje pierwotny strach, jaki sieje wśród ofiar.', 9, 4, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Khazix_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Khazix.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kindred', 'Wieczni Łowcy', 'Pojedynczo, ale nigdy oddzielnie, Kindred reprezentują bliźniacze esencje śmierci. Strzała Owcy oferuje szybki koniec dla tych, którzy pogodzili się ze swoim losem. Wilk poluje zaś na tych, którzy uciekają przed przeznaczeniem, brutalnie pozbawiając ofiary wszelkiej nadziei. Choć interpretacje tego, czym Kindred są, różnią się w całej Runeterze, każdy śmiertelnik musi wybrać oblicze swojej śmierci.', 8, 2, 2, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kindred_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kindred.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kled', 'Swarliwy Rajtar', 'Yordle Kled to wojownik równie nieustraszony, co uparty, uosabia zażartą brawurę Noxusu. Jest ukochaną przez żołnierzy ikoną, której nie ufają oficerowie, a arystokracja wręcz nim pogardza. Liczni utrzymują, że Kled walczył w każdej kampanii prowadzonej przez legiony Noxusu, „zdobył” wszystkie możliwe tytuły wojskowe i nigdy, ale to przenigdy nie wycofał się z walki. I choć wiarygodność tej sprawy częstokroć jest co najmniej wątpliwa, to jego legenda zawiera w sobie ziarno prawdy: szarżując do bitwy na Skaarl, czyli swej nie do końca godnej zaufania szkapie, Kled broni swej własności i stara się jak najwięcej zdobyć.', 8, 2, 2, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Kled_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Kled.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Kog''Maw', 'Paszcza Otchłani', 'Wypluty z gnijącego miejsca wtargnięcia Pustki, głęboko na pustkowiach Icathii, Kog''Maw jest ciekawską, lecz wstrętną istotą ze zjadliwą, rozwartą paszczą. Ten Pomiot Pustki musi obgryźć i zaślinić wszystko, co ma pod ręką, by dogłębnie to zrozumieć. Choć nie jest złośliwy z natury, urzekająca naiwność Kog''Mawa jest niebezpieczna, bo często poprzedza szał jedzenia — nie dla przetrwania, lecz dla zaspokojenia ciekawości.', 8, 2, 5, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/KogMaw_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/KogMaw.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('K''Sante', 'Duma Nazumah', 'Nieustępliwy i odważny K''Sante walczy z potężnymi bestiami i bezwzględnymi Wyniesionymi, by chronić swój dom, miasto Nazumah, cudowną oazę pośród piasków Shurimy. Po kłótni ze swoim byłym partnerem K''Sante zdaje sobie sprawę, że by zostać wojownikiem godnym przewodzić swojemu ludowi, musi utemperować swoje egoistyczne ambicje. Dopiero wtedy będzie mógł uniknąć stania się ofiarą swojej własnej pychy i odnaleźć mądrość potrzebną, by pokonać nikczemne stwory zagrażające jego pobratymcom.', 8, 8, 7, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/KSante_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/KSante.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('LeBlanc', 'Oszustka', 'Tajemnicza nawet dla innych członków kliki Czarnej Róży, LeBlanc jest jednym z wielu imion bladej kobiety, która manipulowała ludźmi i wydarzeniami od zarania Noxusu. Używając magii, by tworzyć swoje lustrzane kopie, ta czarodziejka może pojawić się każdemu, wszędzie i nawet w wielu miejscach naraz. Zawsze knując tuż poza zasięgiem wzroku, prawdziwe pobudki LeBlanc są tak nieprzeniknione jak jej zmienna osobowość.', 1, 4, 10, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Leblanc_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Leblanc.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lee Sin', 'Ślepy Mnich', 'Mistrz sztuk walki Ionii, Lee Sin, jest kierującym się zasadami wojownikiem, który czerpie z esencji duszy smoka, by stawić czoła wszelkim wyzwaniom. Chociaż stracił wzrok wiele lat temu, ten mnich-wojownik poświęca swoje życie, by bronić swoją ojczyznę przed wszystkimi, którzy chcieliby zakłócić jej spokój. Wrogowie, którzy zlekceważą jego oddany medytacji sposób bycia, boleśnie przekonają się o sile jego płonących pięści i kopnięć z półobrotu.', 8, 5, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/LeeSin_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/LeeSin.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Leona', 'Promyk Jutrzenki', 'Leona, dysponująca mocą słońca, jest świętą wojowniczką Solari, która stoi na straży Góry Targon, wyposażona w Ostrze Zenitu i Pawęż Brzasku. Jej skóra lśni blaskiem gwiazd, a oczy płoną mocą Aspektu, który zamieszkuje jej wnętrze. Przyodziana w złoty pancerz i nosząca straszne brzemię w postaci starożytnej wiedzy, Leona niesie niektórym oświecenie, a innym — śmierć.', 4, 8, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Leona_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Leona.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lillia', 'Lękliwy Rozkwit', 'Nieśmiała i płochliwa Lillia, wróżkowa sarenka, snuje się po lasach Ionii. Ukrywa się przed śmiertelnikami, których tajemnicza natura już dawno ją urzekła, ale i przestraszyła. Ma nadzieję odkryć, dlaczego ich marzenia nie trafiają już do Śniącego Drzewa. Przemierza teraz Ionię z magiczną gałązką w ręku, próbując odnaleźć niespełnione sny ludzi. Tylko wtedy Lillia będzie w stanie rozkwitnąć oraz pomóc innym pozbyć się obaw, by rozpalić wewnętrzną iskrę. Iip!', 0, 2, 10, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Lillia_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Lillia.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lissandra', 'Wiedźma Lodu', 'Magia Lissandry przekształca czysty potencjał lodu w coś mrocznego i potwornego. Mocą jej czarnego lodu nie tylko zamraża przeciwników, ale ich nadziewa i miażdży. Przerażeni mieszkańcy północy znają ją tylko jako „Wiedźmę Lodu”. Prawda jest dużo bardziej złowieszcza: Lissandra zatruwa naturę i chce spowodować epokę lodowcową na całym świecie.', 2, 5, 8, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Lissandra_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Lissandra.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lucian', 'Kleryk Broni', 'Lucian, dawniej Strażnik Światła, stał się ponurym łowcą nieumarłych duchów. Jest bezwzględny w ściganiu i zabijaniu ich swoimi bliźniaczymi starożytnymi pistoletami. Gdy nikczemny upiór Thresh zabił jego żonę, Lucian zapragnął zemsty. Jednak nawet po jej powrocie do żywych, nie jest w stanie wyzbyć się gniewu. Bezwzględny i zaślepiony, nie cofnie się przed niczym, aby obronić żyjących przed nieumarłymi koszmarami Czarnej Mgły.', 8, 5, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Lucian_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Lucian.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lulu', 'Wróżkowa Czarodziejka', 'Yordlowa czarodziejka Lulu znana jest z tworzenia wyśnionych iluzji i niestworzonych stworzeń, przemierzając Runeterrę wraz ze swoim duszkiem towarzyszem Pixem. Lulu potrafi momentalnie zniekształcić rzeczywistość, zakrzywiając materiał świata i to, co uważa za kajdany tego nudnego, fizycznego wymiaru. Niektórzy uważają jej magię za nienaturalną w najlepszym wypadku, a za niebezpieczną w najgorszym. Lulu wierzy, że każdy potrzebuje trochę zaczarowania.', 4, 5, 7, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Lulu_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Lulu.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Lux', 'Pani Jasności', 'Obrończyni Korony Luxanna pochodzi z Demacii, krainy, w której do zdolności magicznych podchodzi się z dystansem i strachem. Z powodu umiejętności władania światłem, dorastała w strachu przed tym, że ktoś odkryje jej zdolności i ją wygna. Musiała trzymać swoją moc w tajemnicy, by zachować stan szlachecki swojej rodziny. Niemniej jednak, optymizm i wytrwałość Lux pozwoliły jej na pogodzenie się ze swoim wyjątkowym talentem, którego teraz potajemnie używa, służąc ojczyźnie.', 2, 4, 9, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Lux_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Lux.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Malphite', 'Okruch Monolitu', 'Ogromna istota z żyjącego kamienia, Malphite stara się narzucić błogosławiony porządek chaotycznemu światu. Urodzony jako okruch-sługa obeliskowi z innego świata znanemu jako Monolit, używał swojej ogromnej mocy żywiołów, by chronić i dbać o swojego prekursora, lecz ostatecznie poniósł klęskę. Jedyny ocalały ze zniszczenia jakie nastąpiło, Malphite zmaga się z miękkim ludem Runeterry i jego płynnymi nastrojami, szukając nowego zadania godnego dla siebie — ostatniego z rasy.', 5, 9, 7, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Malphite_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Malphite.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Malzahar', 'Prorok Pustki', 'Malzahar, religijny wieszcz, który poświęca się zrównaniu wszystkiego, co żyje, szczerze wierzy, że nowo powstała Pustka jest drogą do zbawienia Runeterry. Na pustynnych pustkowiach Shurimy podążył za szeptami w swojej głowie, które przywiodły go do pradawnej Icathii. Pośród zrujnowanych ziem tamtej krainy spojrzał prosto w mroczne serce Pustki i otrzymał nową moc i cel życia. Odtąd uważa siebie za pasterza, prowadzącego innych do zagrody... lub wypuszczającego stworzenia, które kłębią się pod nią.', 2, 2, 9, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Malzahar_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Malzahar.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Maokai', 'Spaczony Drzewiec', 'Maokai to olbrzymi drzewiec przepełniony gniewem, który walczy z koszmarami z Wysp Cienia. Gdy magiczny kataklizm zniszczył jego dom, stał się ucieleśnieniem zemsty, opierając się nieśmierci tylko dzięki wodom życia, które w nim płynęły. Niegdyś Maokai był spokojnym duchem natury, ale teraz walczy zawzięcie, aby pozbyć się klątwy ciążącej na Wyspach Cienia i przywrócić dawne piękno swojemu domowi.', 3, 8, 6, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Maokai_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Maokai.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Master Yi', 'Szermierz Wuju', 'Master Yi tak długo trenował ciało i umysł, że myśli i działanie niemal stały się jednością. Mimo że woli używać siły tylko w ostateczności, zwinność i szybkość, z jakimi posługuje się ostrzem, sprawiają, że konflikt zawsze kończy się szybko. Jako jedna z ostatnich żywych osób znających ioniańską sztukę Wuju, Master Yi poświęcił życie, by pielęgnować tradycje swojego ludu — bacznie przygląda się potencjalnym nowym uczniom swoimi Siedmioma Soczewkami Przenikliwości, by sprawdzić, który z nich będzie najbardziej godny stania się adeptem Wuju.', 10, 4, 2, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/MasterYi_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/MasterYi.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Miss Fortune', 'Łowczyni Nagród', 'Pani kapitan Bilgewater, znana ze swojego wdzięku, lecz siejąca strach przez swoją bezwzględność, Sarah Fortune jest surową postacią górującą nad zatwardziałymi kryminalistami miasta portowego. Jako dziecko była świadkiem, jak król łupieżców Gangplank zamordował jej rodzinę — czyn, który brutalnie odpłaciła lata później, wysadzając jego okręt flagowy, kiedy Gangplank znajdował się na jego pokładzie. Ci, którzy jej nie docenią, spotkają się z urzekającym i nieprzewidywalnym przeciwnikiem... i pewnie z kulą, lub dwiema, w swoich trzewiach.', 8, 2, 5, 1, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/MissFortune_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/MissFortune.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Wukong', 'Małpi Król', 'Wukong to vastajański żartowniś, który wykorzystuje siłę, zwinność i inteligencję, aby oszukać przeciwników i zyskać przewagę. Po znalezieniu przyjaciela na całe życie w osobie wojownika znanego jako Master Yi, Wukong stał się ostatnim uczniem starożytnej sztuki walki znanej jako Wuju. Wukong, uzbrojony w magiczny kostur, pragnie ochronić Ionię przed zniszczeniem.', 8, 5, 2, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/MonkeyKing_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/MonkeyKing.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Mordekaiser', 'Żelazny Upiór', 'Dwa razy zabity i trzy razy zrodzony, Mordekaiser to okrutny watażka z zamierzchłej epoki, który wykorzystuje moc nekromancji, aby pętać dusze na wieczną służbę. Niewielu już pamięta jego dawne podboje i zdaje sobie sprawę z pełni jego mocy. Istnieją jednak starożytne dusze, które obawiają się dnia jego nadejścia. Dnia, w którym roztoczy swe panowanie nad żywymi i umarłymi.', 4, 6, 7, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Mordekaiser_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Mordekaiser.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Morgana', 'Upadła', 'Rozdarta pomiędzy naturą astralną a naturą śmiertelniczki, Morgana związała swoje skrzydła, by otworzyć ramiona na ludzkość, i zadaje wszystkim nieszczerym i zwyrodniałym ból, jaki sama odczuwa. Odrzuca prawa i tradycje, o których myśli, że są niesprawiedliwe, i walczy o prawdę z cieni Demacii — nawet gdy inni próbują ją stłamsić — rzucając tarcze i łańcuchy z mrocznego ognia. Morgana z całego serca wierzy, że nawet wypędzeni i wygnani mogą pewnego dnia podnieść się z kolan.', 1, 6, 8, 1, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Morgana_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Morgana.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nami', 'Władczyni Przypływów', 'Nami, nieustępliwa, młoda przedstawicielka Vastajów pochodzących z mórz, była pierwszą z plemienia Marajów, która porzuciła fale i zapuściła się na suchy ląd, kiedy ich starożytne porozumienie z Targonianami zostało zerwane. Nie mając innego wyboru, wzięła na swoje barki dokończenie świętego rytuału, który zapewniłby jej ludowi bezpieczeństwo. Pośród chaosu nowej ery, Nami odważnie i zdeterminowanie walczy z niepewną przyszłością, używając swojego Kosturu Władczyni Przypływów, by przywoływać potęgę oceanów.', 4, 3, 7, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nami_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nami.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nasus', 'Kustosz Pustyni', 'Nasus jest majestatycznym, Wyniesionym bytem o głowie szakala, wywodzącym się z przedwiecznej Shurimy. Herosem, którego ludzie pustyni uważali za półboga. Jego wyjątkowa inteligencja sprawiła, że był opiekunem wiedzy i niezrównanym strategiem, a jego mądrość prowadziła pradawne imperium Shurimy do wielkości przez całe stulecia. Po upadku imperium sam narzucił sobie wygnanie, stając się niczym więcej niż tylko legendą. Teraz, gdy antyczne miasto Shurima raz jeszcze powstało z piasków pustyni, Nasus powrócił i jest gotów poświęcić całą swą determinację, aby nie dopuścić do jej ponownego upadku.', 7, 5, 6, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nasus_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nasus.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nautilus', 'Tytan Głębin', 'Opancerzony goliat znany jako Nautilus, samotna legenda, stara jak pierwsze pomosty postawione w Bilgewater, włóczy się po mrocznych wodach u wybrzeża Wysp Niebieskiego Płomienia. Napędzany zapomnianą zdradą uderza bez ostrzeżenia, wymachując swoją ogromną kotwicą, by ratować potrzebujących, a chciwych ściągać na dno ku zagładzie. Podobno przychodzi po tych, którzy zapominają zapłacić „dziesięciny Bilgewater” i wciąga ich pod taflę oceanu. Jest okutym w żelazo przypomnieniem, że nikt nie ucieknie przed głębinami.', 4, 6, 6, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nautilus_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nautilus.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Neeko', 'Ciekawski Kameleon', 'Neeko, pochodząca z dawno utraconego plemienia Vastajów, potrafi wtopić się w każdy tłum, pożyczając wygląd innych, a nawet wchłaniając coś pokroju ich stanu emocjonalnego, by w mgnieniu oka odróżnić wroga od przyjaciela. Nikt nie może być nigdy pewien, gdzie — ani kim — jest Neeko, ale ci, którzy chcą ją skrzywdzić, szybko poznają jej prawdziwą naturę i poczują na sobie całą potęgę jej pierwotnego ducha.', 1, 1, 9, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Neeko_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Neeko.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nidalee', 'Zwierzęca Łowczyni', 'Wychowana w najgłębszej dżungli, Nidalee jest mistrzowską tropicielką, która na zawołanie potrafi przemienić się w pumę. Nie jest w pełni kobietą ani bestią. Zaciekle broni swojego terytorium przed wszystkimi intruzami za pomocą rozmyślnie umieszczonych pułapek i wprawnych rzutów oszczepem. Unieruchamia swoją zdobycz, zanim skoczy na nią w kociej formie. Ci szczęściarze, którzy przetrwają, opowiadają historie o dzikiej kobiecie z wyostrzonymi zmysłami i ostrymi pazurami...', 5, 4, 7, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nidalee_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nidalee.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nilah', 'Nieokiełznana radość', 'Nilah to ascetyczna wojowniczka z odległej krainy, poszukująca jak najgroźniejszych i najpotężniejszych przeciwników, aby rzucać im wyzwania. Swoją potęgę posiadła dzięki pojedynkowi z długo więzionym demonem radości, a jedyną emocją, jaka jej pozostała, jest nieprzerwana euforia. Zapłaciła więc niewielką cenę za ogromną siłę, którą teraz dysponuje. Nilah koncentruje płynną postać demona w ostrze o niezrównanej mocy, aby bronić świat przed dawno zapomnianymi, starożytnymi zagrożeniami.', 8, 4, 4, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nilah_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nilah.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nocturne', 'Wieczny Koszmar', 'Demoniczne wcielenie, stworzone z koszmarów nawiedzających wszystkie umysły, jest znane jako Nocturne — przedwieczna siła czystego zła. Jego forma jest płynnym chaosem, cieniem bez twarzy z zimnymi oczami, uzbrojonym w złowieszczo wyglądające ostrza. Po uwolnieniu się z duchowego wymiaru, Nocturne zaczął grasować po świecie, by żerować na rodzaju strachu, który istnieje tylko w całkowitej ciemności.', 9, 5, 2, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nocturne_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nocturne.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Nunu i Willump', 'Chłopiec i Jego Yeti', 'Dawno, dawno temu był sobie chłopiec, który chciał dowieść, że jest bohaterem, zabijając straszliwego potwora. Zamiast tego odkrył jedynie, że ten stwór, samotny i magiczny yeti, po prostu potrzebował przyjaciela. Zbratani starożytną mocą i wspólną miłością do śnieżek, Nunu i Willump tułają się teraz po Freljordzie, wcielając w życie zmyślone przygody. Mają nadzieję, że znajdą gdzieś tam matkę Nunu. Jeżeli uda im się ją uratować, być może w końcu zostaną bohaterami...', 4, 6, 7, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Nunu_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Nunu.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Olaf', 'Berserker', 'Niepowstrzymana siła zniszczenia, dzierżący topory Olaf nie chce nic więcej poza chwalebną śmiercią w boju. Pochodzi z Lokfaru, surowego freljordzkiego półwyspu. Kiedyś przepowiedziano mu spokojną śmierć — los tchórza i ogromna ujma pośród jego ludu. Napędzany gniewem Olaf pustoszył ziemie w poszukiwaniu śmierci, zabijając niezliczone ilości wspaniałych wojowników i legendarnych potworów. Szukał przeciwnika, który mógłby go zatrzymać. Teraz jest brutalnym wykidajłą Zimowego Szponu, szukającym swojego kresu w zapowiadanych wielkich wojnach.', 9, 5, 3, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Olaf_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Olaf.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Orianna', 'Mechaniczna Baletnica', 'Kiedyś dziewczyna z krwi i kości, Orianna jest teraz cudem techniki w całości skonstruowanym z mechanicznych części. Po wypadku w niższych dzielnicach Zaun śmiertelnie zachorowała, a jej konające ciało musiało zostać wyjątkowo uważnie zastąpione, kawałek po kawałku. Mając u boku niezwykłą mosiężną kulę, którą zbudowała dla towarzystwa i ochrony, Orianna może dowolnie odkrywać cuda Piltover i nie tylko.', 4, 3, 9, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Orianna_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Orianna.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ornn', 'Ogień z Wnętrza Góry', 'Ornn to duch Freljordu, opiekun kowali i rzemieślników. Pracuje w samotności w ogromnej kuźni wykutej w magmowych jaskiniach skrytych we wnętrzu wulkanu zwanego Palenisko. Zajmuje się podsycaniem ognia pod kotłami z płynną lawą, by uszlachetniać kruszce i tworzyć z nich przedmioty o niezrównanej jakości. Za każdym razem, gdy inne bóstwa — a szczególnie Volibear — stawiają stopę na ziemi i wtrącają się w ludzkie sprawy, Ornn pokazuje zapalczywym istotom, gdzie jest ich miejsce, wspomagając się swoim zaufanym młotem lub ognistą potęgą gór.', 5, 9, 3, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ornn_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ornn.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Pantheon', 'Niezniszczalna Włócznia', 'Atreus, niegdyś oporny nośnik Aspektu Wojny, przeżył, gdy boska moc została w nim zgładzona, i nie ugiął się pod ciosem, który zdarł gwiazdy z nieboskłonu. Z czasem otworzył się na moc własnej śmiertelności i wytrwałość, która się z nią wiąże. Teraz Atreus sprzeciwia się boskości jako odrodzony Pantheon, a na polu bitwy jego niezłomna wola przepełnia broń upadłego Aspektu.', 9, 4, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Pantheon_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Pantheon.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Poppy', 'Strażniczka Młota', 'W krainie Runeterry nie brakuje dzielnych bohaterów, ale niewielu spośród nich jest tak nieustępliwych jak Poppy. Dzierżąc legendarny młot Orlona, broń dwa razy większą od niej, ta zdeterminowana Yordlka spędziła już wiele lat na poszukiwaniu mitycznego „Bohatera Demacii”, który według opowieści jest prawowitym właścicielem broni. Dopóki to nie nastąpi, dzielnie rzuca się do walki, odpychając wrogów królestwa każdym wirującym uderzeniem.', 6, 7, 2, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Poppy_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Poppy.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Pyke', 'Rozpruwacz z Krwawego Portu', 'Pyke, znany harpunnik z Doków Rzezi w Bilgewater, powinien był umrzeć w żołądku ryby giganta... ale jednak powrócił. Teraz nawiedza zawilgotniałe uliczki oraz zakamarki swojego dawnego miasta i używa swych nowych nadnaturalnych darów, by nieść szybką i okrutną śmierć wszystkim, którzy zbijają fortunę, wykorzystując innych. W ten sposób miasto, które szczyci się polowaniem na potwory, samo znalazło się w pozycji ofiary potwora.', 9, 3, 1, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Pyke_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Pyke.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Qiyana', 'Cesarzowa Żywiołów', 'W położonym w dżungli mieście Ixaocan Qiyana bez skrupułów planuje własną ścieżkę na tron Yun Tal. Jest ostatnia w kolejce do odziedziczenia władzy po rodzicach, ale mierzy się ze wszystkimi na swojej drodze z bezczelną pewnością siebie i niespotykanym wcześniej opanowaniem magii żywiołów. Sama ziemia słucha każdego jej rozkazu, więc Qiyana postrzega siebie jako największą mistrzynię żywiołów w historii Ixaocanu — i z tego tytułu uważa, że zasługuje nie tylko na miasto, ale i całe imperium.', 0, 2, 4, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Qiyana_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Qiyana.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Quinn', 'Skrzydła Demacii', 'Quinn to elitarna zwiadowczyni rycerstwa z Demacii, która wykonuje niebezpieczne misje głęboko na terytorium wroga. Ją i jej legendarnego orła Valora łączy wyjątkowa, nierozerwalna więź, dzięki której tworzą tak skuteczny duet, że ich przeciwnicy giną, zanim się zorientują, że nie walczą z jednym, lecz dwoma bohaterami Demacii. Zwinna i akrobatyczna, kiedy zajdzie taka potrzeba, Quinn używa kuszy, a Valor oznacza nieuchwytne cele z góry, co czyni ich zabójczą parą na polu walki.', 9, 4, 2, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Quinn_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Quinn.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rakan', 'Uwodziciel', 'Równie energiczny, co czarujący, Rakan to słynny vastajański mąciciel i najwspanialszy tancerz bitewny w historii plemienia Lhotlan. Ludzie z wyżyn Ionii od dawna kojarzą jego imię z dzikimi zabawami, nieokiełznanymi imprezami i anarchistyczną muzyką. Niewielu mogłoby podejrzewać, że ten pełen energii podróżujący artysta jest partnerem buntowniczki Xayah i sprzyja jej sprawie.', 2, 4, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Rakan_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Rakan.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rammus', 'Pancerznik', 'Idol dla wielu, wyrzutek w oczach nielicznych, i wielka tajemnica dla wszystkich. Mowa o Rammusie, osobliwym stworzeniu, będącym prawdziwą zagadką. Na temat pochodzenia tej skrywającej swoje oblicze pod kolczastą skorupą istoty istnieje wiele sprzecznych teorii. Jedni nazywają go półbogiem, drudzy — świętą wyrocznią, a inni zrodzonym z magii potworem. Bez względu na to, jaka jest prawda, Rammus nie zdradza nikomu swych sekretów i nie przerywa swojej wędrówki przez pustynię Shurimy na niczyją prośbę.', 4, 10, 5, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Rammus_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Rammus.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rek''Sai', 'Furia Pustki', 'Rek''Sai to bezlitosny Pomiot Pustki, idealna drapieżniczka, kopiąca tunele pod ziemią, by chwytać i pożerać nic niepodejrzewające ofiary. Jej nienasycony głód odpowiada za zniszczenie całych regionów niegdyś wspaniałego imperium Shurimy — kupcy, handlarze, a nawet uzbrojone karawany nadłożą setki kilometrów drogi, by ominąć ziemie, na których poluje ona i jej potomstwo. Wszyscy wiedzą, że kiedy zauważy się Rek''Sai na horyzoncie, śmierć spod ziemi jest nieunikniona.', 8, 5, 2, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/RekSai_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/RekSai.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rell', 'Żelazna Mścicielka', 'Rell, produkt brutalnych eksperymentów Czarnej Róży, to zbuntowana żywa broń, której celem jest obalenie Noxusu. Jej dzieciństwo pełne było nędzy i okrucieństwa — przetrwała niewyobrażalne zabiegi mające na celu udoskonalenie oraz opanowanie jej magicznej kontroli nad metalem… aż do gwałtownej ucieczki, podczas której zabiła wielu swoich oprawców. Teraz, okrzyknięta mianem kryminalistki, bez zastanowienia napada na noxiańskich żołnierzy. Szuka ocalałych z dawnej „akademii”, broni słabszych i jednocześnie zadaje swoim byłym przełożonym brutalną śmierć.', 0, 0, 0, 0, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Rell_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Rell.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Renata Glasc', 'Chembaronessa', 'Renata Glasc powstała z popiołów swego rodzinnego domu. Nie miała niczego poza nazwiskiem i alchemicznymi badaniami swoich rodziców. W ciągu kolejnych dziesięcioleci stała się najbogatszą chembaronessą w Zaun i magnatką biznesu, która zbudowała swoją potęgę dzięki wiązaniu interesów innych z własnymi. Działaj z nią, a nagrodom nie będzie końca. Działaj przeciwko niej, a pożałujesz swojej decyzji. Ostatecznie jednak każdy i tak przechodzi na jej stronę.', 2, 6, 9, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Renata_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Renata.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Renekton', 'Pustynny Rzeźnik', 'Wywodzący się ze spalonych słońcem pustyń Shurimy Renekton jest przerażającym, Wyniesionym bytem, którego napędza furia. Niegdyś był wojownikiem cieszącym się największą estymą w całym imperium i prowadził armie swojego państwa ku niezliczonym wiktoriom. Gdy jednak imperium upadło, został pogrzebany pod jego piaskami i powoli, w miarę jak zmieniał się świat, Renekton popadł w szaleństwo. Teraz, odzyskawszy wolność, jest całkowicie pochłonięty chęcią odnalezienia i uśmiercenia swego brata Nasusa, którego w swym szaleństwie obwinia o spędzone w mroku stulecia.', 8, 5, 2, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Renekton_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Renekton.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rengar', 'Łowca', 'Rengar to dziki vastajański łowca trofeów, który żyje dla polowań na niebezpieczne stworzenia. Przemierza świat w poszukiwaniu najstraszniejszych bestii, jakie może znaleźć. Szczególnie zależy mu na śladach Kha''Zixa, stworzenia z Pustki, które pozbawiło go oka. Rengar nie śledzi ofiar ze względu na pożywienie czy chwałę, ale dla samego piękna pościgu.', 7, 4, 2, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Rengar_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Rengar.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Riven', 'Wygnaniec', 'Kiedyś Riven była mistrzynią miecza w noxiańskim korpusie wojennym, a teraz jest wygnańcem na ziemi, którą kiedyś chciała podbić. Siła jej przekonania i brutalna efektywność zapewniły jej szybki awans i nagrodę — legendarne runiczne ostrze i własny oddział. Jednakże na froncie wojny z Ionią wiara Riven w ojczyznę została poddana próbie i ostatecznie złamana. Odciąwszy się kompletnie od imperium, Riven szuka teraz swojego miejsca w zniszczonym świecie, choć pojawiają się pogłoski o tym, że sam Noxus został... przekuty.', 8, 5, 1, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Riven_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Riven.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Rumble', 'Zmechanizowany Zabijaka', 'Rumble to młody, temperamentny wynalazca. Używając tylko swoich rąk i kupy złomu, ten zadziorny Yordle zbudował ogromnego mecha, wyposażonego w arsenał elektroharpunów i rakiet zapalających. Rumble''owi nie przeszkadza, że ktoś pogardza jego tworami ze złomowiska — koniec końców, to on ma ogniopluj.', 3, 6, 8, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Rumble_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Rumble.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ryze', 'Mag Run', 'Ryze jest pradawnym, nadzwyczaj zawziętym arcymagiem, powszechnie uważanym za jednego z najznamienitszych przedstawicieli tejże profesji w świecie Runeterry. I nosi na swych barkach niewyobrażalnie ciężkie brzemię. Uzbrojony w niczym nieograniczoną, ezoteryczną moc i twardy charakter, niestrudzenie poszukuje Run Świata — fragmentów czystej magii, która niegdyś uformowała świat z nicości. Musi je odszukać, nim wpadną w niewłaściwe ręce, ponieważ Ryze wie, jakie koszmary mogą uwolnić na Runeterrę.', 2, 2, 10, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ryze_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ryze.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Samira', 'Róża Pustyni', 'Samira z niezachwianą pewnością siebie patrzy śmierci prosto w oczy i szuka dreszczyku emocji, gdziekolwiek zmierza. Jej dom w Shurimie zniszczono, gdy była jeszcze dzieckiem. Niedługo później odkryła swoje prawdziwe powołanie w Noxusie, gdzie zapracowała na reputację stylowej i nieustraszonej wojowniczki, podejmującej się niebezpiecznych misji najwyższego kalibru. Samira dzierży pistolety i specjalnie zaprojektowany miecz. Nic więc dziwnego, że najlepiej radzi sobie w sytuacjach na granicy życia i śmierci, z błyskiem i rozmachem eliminując każdego, kto stanie jej na drodze.', 8, 5, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Samira_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Samira.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sejuani', 'Gniew Północy', 'Sejuani jest brutalną, surową zrodzoną z lodu matką wojny Zimowego Szponu, jednego z najstraszniejszych plemion Freljordu. Jej ludzie toczą bój o przetrwanie z żywiołami, zmuszając ich do najeżdżania Noxian, Demacian i Avarosan, by przeżyć srogie zimy. Sejuani przewodzi najniebezpieczniejszym z tych ataków z siodła swojego ogromnego dzika Bristle''a i używa korbacza z Prawdziwego Lodu, by zamrażać i roztrzaskiwać przeciwników.', 5, 7, 6, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sejuani_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sejuani.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Senna', 'Odkupicielka', 'Senna, na której od dziecka ciąży klątwa powodująca prześladowanie przez nienaturalną Czarną Mgłę, dołączyła do świętego zakonu o nazwie Strażnicy Światła i zawzięcie stawiała jej opór. Umarła jednak, a jej dusza została uwięziona w latarni przez okrutnego upiora, Thresha. Nie tracąc nadziei, Senna nauczyła się wykorzystywać Mgłę i gdy wydostała się na wolność, była odmieniona na zawsze. Teraz jako broń wykorzystuje i ciemność, i światło. Chce położyć kres Czarnej Mgle, zwracając ją przeciw sobie samej — każdym wystrzałem swojego reliktowego działa odkupuje zagubione w niej dusze.', 7, 2, 6, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Senna_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Senna.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Seraphine', 'Rozmarzona Piosenkarka', 'Seraphine, urodzona w Piltover w zauńskiej rodzinie, słyszy dusze innych — świat śpiewa do niej, a ona mu odpowiada. Choć te dźwięki przytłaczały ją w młodości, teraz czerpie z nich inspirację, zamieniając chaos w symfonię. Występuje w siostrzanych miastach, aby przypomnieć mieszkańcom, że nie są sami, że razem są silniejsi i że w jej oczach ich potencjał jest nieograniczony.', 0, 0, 0, 0, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Seraphine_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Seraphine.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sett', 'Szef', 'Sett, przywódca rozwijającego się ioniańskiego półświatka, zyskał sławę w następstwie wojny z Noxusem. Mimo że zaczynał jako skromny pretendent w nielegalnych walkach w Navori, szybko zyskał złą sławę, w czym pomogły mu jego zwierzęca siła oraz wytrzymałość. Sett wdrapał się po szczeblach hierarchii miejscowych wojowników aż na sam jej szczyt, a następnie zawładnął areną, na której sam kiedyś występował.', 8, 5, 1, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sett_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sett.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Shaco', 'Demoniczny Błazen', 'Stworzony dawno temu jako zabawka dla samotnego księcia, zaczarowana marionetka Shaco czerpie przyjemność z mordowania i siania zniszczenia. Spaczony przez czarną magię i utratę ukochanego właściciela, ta kiedyś miła pacynka delektuje się tylko cierpieniem biednych dusz, które dręczy. Zabójczo używa zabawek i prostych sztuczek, a skutki swoich krwawych „gierek” uważa za prześmieszne. Ci, którzy usłyszeli mroczny śmiech w ciemną noc, mogą czuć się naznaczeni przez Demonicznego Błazna — będzie się nimi bawił.', 8, 4, 6, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Shaco_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Shaco.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Shen', 'Oko Zmierzchu', 'Shen Oko Zmierzchu jest przywódcą pośród sekretnego zakonu wojowników znanych jako Kinkou. Pragnąc pozostać wolnym od wprowadzających zamęt emocji, uprzedzeń i ego, nieustannie stara się podążać ukrytą ścieżką chłodnego, beznamiętnego osądu pomiędzy światem duchowym a rzeczywistym. Shen, na którego barki spadło zadanie utrzymywania równowagi pomiędzy tymi światami, nie zawaha się użyć stalowych ostrzy, przepełnionych tajemną energią przeciwko każdemu, kto mu w tym przeszkodzi.', 3, 9, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Shen_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Shen.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Shyvana', 'Półsmok', 'Shyvana to stworzenie, w którego sercu płonie magiczny odłamek runy. Chociaż często przybiera humanoidalną postać, w każdej chwili może zmienić się w groźnego smoka, który spopiela wrogów ognistym oddechem. Uratowawszy koronnemu księciu Jarvanowi IV życie, Shyvana służy teraz w szeregach jego królewskiej straży i niezmiennie stara się, by nieufni Demacianie przyjęli ją taką, jaka jest.', 8, 6, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Shyvana_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Shyvana.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Singed', 'Szalony Chemik', 'Singed jest zauńskim alchemikiem o niedoścignionej inteligencji, który poświęcił życie, by poszerzać granice wiedzy za każdą cenę. Sam zapłacił najwyższą z nich — oszalał. Czy w jego szaleństwie jest metoda? Jego mikstury rzadko okazują się być trefne, ale wielu uważa, że Singed stracił wszelkie poczucie człowieczeństwa i pozostawia za sobą szlak cierpienia i terroru, gdziekolwiek się pojawi.', 4, 8, 7, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Singed_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Singed.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sion', 'Nieumarły Niszczyciel', 'Bohater wojenny minionej epoki, Sion był czczony w Noxusie za własnoręczne uduszenie króla Demacii, lecz nie było mu dane popaść w zapomnienie — został wskrzeszony, aby mógł służyć imperium nawet po śmierci. Rzeź, którą rozpętał, pochłonęła wszystkich niezależnie od przynależności, co dowiodło, że nie zostało w nim nic ludzkiego. Nawet teraz, mając prymitywną zbroję przykręconą do gnijącego ciała, Sion rzuca się w każdy bój, niewiele o tym myśląc, i pomiędzy atakami wykonywanymi swoją potężną siekierą próbuje sobie przypomnieć, jaki był kiedyś.', 5, 9, 3, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sion_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sion.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sivir', 'Pani Wojny', 'Sivir jest znaną poszukiwaczką skarbów i przywódczynią najemników, która oferuje swoje usługi na pustyniach Shurimy. Uzbrojona w legendarną, zdobioną klejnotami broń, stoczyła i wygrała niezliczoną liczbę bitew dla tych, których stać na pokrycie jej wygórowanego honorarium. Znana ze swej nieustraszonej determinacji i nieskończonej ambicji, z dumą trudzi się odzyskiwaniem pogrzebanych skarbów z niebezpiecznych grobowców Shurimy — rzecz jasna za cenę sowitej nagrody. Teraz, kiedy pradawne siły na nowo trzęsą Shurimą w podstawach, Sivir znalazła się w sytuacji rozdarcia między kolidującymi ze sobą ścieżkami przeznaczenia.', 9, 3, 1, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sivir_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sivir.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Skarner', 'Kryształowy Strażnik', 'Skarner to olbrzymi kryształowy skorpion pochodzący z ukrytej doliny w Shurimie. Należy do starożytnej rasy Brackernów, która słynie z wyjątkowej mądrości i głębokiej więzi z ziemią. Dusze Brackernów są połączone z potężnymi kryształami mieszczącymi w sobie myśli i wspomnienia ich przodków. Wieki temu przedstawiciele tej rasy zapadli w sen, który uchronił ich przed niechybną śmiercią w wyniku potężnych magicznych zawirowań, jednak złowieszcze wydarzenia niedawnych dni przebudziły Skarnera. Jako jedyny przebudzony Brackern, Skarner stara się bronić swych pobratymców przed wszelkimi zagrożeniami.', 7, 6, 5, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Skarner_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Skarner.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sona', 'Wirtuozka Strun', 'Sona jest najprzedniejszą wirtuozką etwahlu w Demacii. Za pomocą swojego instrumentu przemawia pełnymi wdzięku akordami i niesamowitymi ariami. Dzięki swoim dystyngowanym manierom zjednała sobie serca szlachty, lecz niektórzy podejrzewają, że jej czarujące melodie emanują magią, która jest zakazana w Demacii. Cicha dla nieznajomych, jakoś rozumiana przez bliskich towarzyszy, Sona wygrywa harmonie nie tylko po to, by nieść ukojenie rannym sojusznikom, ale i by powalać niczego niespodziewających się wrogów.', 5, 2, 8, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sona_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sona.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Soraka', 'Gwiezdne Dziecko', 'Wędrowniczka z astralnych wymiarów ponad Górą Targon, Soraka porzuciła nieśmiertelność na rzecz obrony ras śmiertelników przed ich własnymi, bardziej brutalnymi instynktami. Przemierza świat, by dzielić się cnotami współczucia i litości ze wszystkim napotkanymi ludźmi, lecząc nawet tych, którzy jej złorzeczą. Pomimo całego zła, które widziała, Soraka dalej wierzy, że ludzie z Runeterry wciąż nie osiągnęli swojego potencjału.', 2, 5, 7, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Soraka_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Soraka.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Swain', 'Wielki Generał Noxusu', 'Jericho Swain jest wizjonerskim przywódcą Noxusu, ekspansjonistycznego narodu, który uznaje tylko siłę. Mimo że podczas wojen z Ionią doznał poważnego uszczerbku na zdrowiu, zarówno fizycznym — jego lewa ręka została odcięta — jak i psychicznym, udało mu się przejąć władzę nad imperium dzięki bezwzględnej determinacji... i nowej, demonicznej dłoni. Dziś Swain wydaje rozkazy z pierwszej linii, maszerując naprzeciw nadchodzącej ciemności, którą tylko on może zobaczyć w krótkich, pourywanych wizjach zbieranych przez mroczne kruki z ciał poległych wokół niego. W wirze ofiar i tajemnic największym misterium jest fakt, że prawdziwy wróg siedzi w nim samym.', 2, 6, 9, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Swain_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Swain.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Sylas', 'Wyzwolony z Kajdan', 'Wychowany w jednym z gorszych regionów Demacii, Sylas z Ochłapiska stał się symbolem mrocznej strony Wielkiego Miasta. Kiedy był chłopcem, jego zdolność do odszukiwania ukrytej magii przykuła uwagę słynnych łowców magów, którzy ostatecznie wtrącili go do więzienia za obrócenie tej mocy przeciwko nim. Wydostawszy się na wolność, Sylas wiedzie życie zahartowanego rewolucjonisty i używa magii znajdujących się wokół niego osób, by niszczyć królestwo, któremu kiedyś służył... a grono jego wyznawców złożone z wygnanych magów zdaje się rosnąć z dnia na dzień.', 3, 4, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Sylas_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Sylas.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Syndra', 'Mroczna Władczyni', 'Syndra to siejąca strach ioniańska czarodziejka, dysponująca ogromną mocą. Kiedy była dzieckiem, jej nieujarzmiona, dzika magia budziła niepokój w sercach członków starszyzny wioski. Została odesłana, by nauczyć się nad nią panować, ale z czasem odkryła, że jej mentor osłabiał jej zdolności. Przekształcając poczucie zdrady i cierpienie w mroczne kule energii, Syndra poprzysięgła zniszczyć wszystkich, którzy choćby spróbowali ją kontrolować.', 2, 3, 9, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Syndra_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Syndra.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Tahm Kench', 'Rzeczny Król', 'Demon Tahm Kench, znany pod wieloma innymi imionami, podróżuje drogami wodnymi Runeterry, karmiąc swój niezaspokojony głód cierpieniem innych. Choć może się wydawać niezwykle czarujący i dumny, kroczy przez fizyczny świat jak włóczęga w poszukiwaniu niczego niepodejrzewających ofiar. Smagnięcie jego języka ogłuszy nawet ciężkozbrojnego wojownika z odległości tuzina kroków, a trafić do jego burczącego brzucha to jakby wpaść do otchłani, z której niepodobna się wydostać.', 3, 9, 6, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/TahmKench_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/TahmKench.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Taliyah', 'Tkaczka Skał', 'Taliyah to wędrowna czarodziejka z Shurimy, rozdarta pomiędzy młodzieńczym zachwytem a dorosłą odpowiedzialnością. Przemierzyła prawie cały Valoran podczas podróży, której celem jest nauka panowania nad jej rosnącymi mocami, choć ostatnio powróciła, by chronić swoje plemię. Niektórzy odczytali jej skłonność do współczucia jako oznakę słabości i gorzko zapłacili za ten błąd. Pod młodzieńczą postawą Taliyah kryje się wola mogąca przenosić góry i duch tak niezłomny, że aż ziemia drży pod jej stopami.', 1, 7, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Taliyah_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Taliyah.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Talon', 'Cień Ostrza', 'Talon jest nożem kryjącym się w ciemności, bezlitosnym zabójcą, gotowym uderzyć bez ostrzeżenia i uciec, zanim ktokolwiek się zorientuje. Zdobył niebezpieczną reputację na brutalnych ulicach Noxusu, gdzie zmuszony był walczyć, zabijać i kraść, by przeżyć. Przygarnięty przez słynną rodzinę Du Couteau, korzysta teraz ze swoich zabójczych umiejętności na rozkaz imperium, zabijając wrogich dowódców, kapitanów i bohaterów... jak i wszystkich Noxian wystarczająco głupich, by splamić swój honor w oczach panów.', 9, 3, 1, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Talon_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Talon.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Taric', 'Tarcza Valoranu', 'Taric jest Aspektem Protektora, obdarzonym niezwykłą mocą strażnikiem życia, miłości i piękna na Runeterze. Zniesławiony za porzucenie obowiązków i wygnany z Demacii, swojej ojczyzny, wspiął się na Górę Targon, aby znaleźć odkupienie, ale zamiast tego odkrył wyższe powołanie pośród gwiazd. Taric Tarcza Valoranu, przepełniony mocą starożytnego Targonu, stoi na straży, aby chronić ludzi przed spaczeniem Pustki.', 4, 8, 5, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Taric_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Taric.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Teemo', 'Chyży Zwiadowca', 'Nie bacząc na najbardziej niebezpieczne przeszkody, Teemo przemierza świat z niekończącym się entuzjazmem i radością. Jako Yordle z niezachwianym poczuciem moralności, jest dumny z przestrzegania Kodeksu Harcerza Bandle, czasami do takiego stopnia, że nie zdaje sobie sprawy z konsekwencji jego czynów. Niektórzy mówią, że istnienie Zwiadowców jest wątpliwe, lecz jedna rzecz jest pewna: z osądem Teemo nie można dyskutować.', 5, 3, 7, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Teemo_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Teemo.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Thresh', 'Strażnik Łańcuchów', 'Sadystyczny i przebiegły Thresh jest ambitnym i niespokojnym duchem Wysp Cienia. Niegdyś opiekun niezliczonych magicznych tajemnic, został zniszczony przez moce potężniejsze niż życie czy śmierć, a teraz istnieje tylko dzięki swojej straszliwej inwencji twórczej w powolnym zadawaniu cierpienia. Ofiary Thresha cierpią daleko poza moment samej śmierci, albowiem rujnuje on ich dusze, więżąc je w swej nikczemnej latarni, by następnie torturować je przez całą wieczność.', 5, 6, 6, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Thresh_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Thresh.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Tristana', 'Dumna Kanonierka', 'Inni Yordlowie wykorzystują własną energię, by być odkrywcami, wynalazcami lub po prostu psotnikami. Tristanę zawsze pociągały przygody wielkich wojowników. Słyszała wiele o Runeterze, jej frakcjach oraz wojnach i wierzyła, że tacy jak ona też mogą stać się godnymi legend. Postawiwszy pierwszy krok w tym świecie, złapała za swoje wierne działo — Boomera, i teraz rzuca się do walki z niezłomną odwagą i optymizmem.', 9, 3, 5, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Tristana_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Tristana.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Trundle', 'Król Trolli', 'Trundle to duży i przebiegły troll o prawdziwie podłych tendencjach, zmusi wszystko do kapitulacji — nawet sam Freljord. Zawzięcie broni swojego terytorium, więc dopadnie każdego głupca, który na nie wkroczy. Potem, z pomocą swojej maczugi z Prawdziwego Lodu, zamraża przeciwników do szpiku kości i nabija ich na ostre, lodowe kolumny, śmiejąc się, kiedy ich krew barwi śnieg.', 7, 6, 2, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Trundle_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Trundle.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Tryndamere', 'Król Barbarzyńców', 'Napędzany nieokiełznanym gniewem, Tryndamere kiedyś przeszedł przez cały Freljord, otwarcie wyzywając do walki najlepszych wojowników północy, by przygotować się na nadchodzące czarne dni. Ten gniewny barbarzyńca od dawien dawna chciał zemścić się za ludobójstwo dokonane na jego klanie, choć ostatnio znalazł miejsce oraz dom u boku Ashe, avarosańskiej matki wojny, i jej plemienia. Prawie nieludzka siła i hart ducha Tryndamere''a są legendarne i zapewniły jemu i jego nowym sojusznikom niezliczone zwycięstwa nawet w najgorszych sytuacjach.', 10, 5, 2, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Tryndamere_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Tryndamere.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Twisted Fate', 'Mistrz Kart', 'Twisted Fate to niesławny szuler i oszust, który wszystko, co chce, zdobywa hazardem i urokiem. Zapracował sobie przez to zarówno na wrogość, jak i podziw bogatych i głupich. Rzadko kiedy zachowuje powagę, witając każdy dzień prześmiewczym uśmieszkiem i niefrasobliwym nadęciem. W każdym możliwym znaczeniu tego słowa, Twisted Fate zawsze ma asa w rękawie.', 6, 2, 6, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/TwistedFate_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/TwistedFate.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Twitch', 'Szczur Zarazy', 'Zauński szczur zarazy z urodzenia, lecz koneser obrzydlistw z pasji, Twitch nie boi ubrudzić sobie łap. Wymierza swoją zasilaną chemikaliami kuszę w złocone serce Piltover i przysięga dowieść wszystkim w mieście wyżej, jak bardzo są plugawi. Zawsze szczwanie szczwany, a kiedy nie kręci się po Slumsach, pewnie tkwi po pas w śmieciach innych ludzi, szukając wyrzuconych skarbów... i spleśniałych kanapek.', 9, 2, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Twitch_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Twitch.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Udyr', 'Duchowy Wędrowca', 'Udyr, najpotężniejszy z żyjących duchowych wędrowców, obcuje ze wszystkimi widmami Freljordu — czy to poprzez empatyczne zrozumienie ich potrzeb, czy też kierowanie i przekształcanie ich eterycznej energii w swój własny, pierwotny styl walki. Szuka wewnętrznej równowagi, aby jego umysł nie zagubił się wśród innych, jednak dąży również do harmonii poza granicami samego siebie — mistyczny krajobraz Freljordu może się rozwijać tylko dzięki wzrostowi, który wynika z konfliktu i walki, a Udyr wie, że aby utrzymać pokojową stagnację, trzeba ponosić ofiary.', 8, 7, 4, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Udyr_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Udyr.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Urgot', 'Motor Agonii', 'Dawno temu potężny noxiański kat o imieniu Urgot został zdradzony przez imperium, w którego służbie odebrał tak wiele żyć. Skuty żelaznymi kajdanami zmuszony był poznać prawdziwą siłę w Czeluści, więziennej kopalni głęboko pod Zaun. Uwolniony w wyniku katastrofy, która sprowadziła chaos na całe miasto, stanowi teraz cień ciążący nad przestępczym półświatkiem. Dążąc do oczyszczenia swojego nowego domu z tych, którzy według niego nie zasługują na życie, unosi swoje ofiary na tych samych łańcuchach, które niegdyś pętały jego ciało, skazując je na niewyobrażalne cierpienie.', 8, 5, 3, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Urgot_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Urgot.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Varus', 'Strzała Odkupienia', 'Varus, jeden ze starożytnych Darkinów, był śmiertelnie niebezpiecznym zabójcą, który uwielbiał gnębić ofiary, doprowadzając je do granic szaleństwa przed wykończeniem ich za pomocą strzał. Został uwięziony pod koniec Wielkiej Wojny Darkinów, ale wiele wieków później udało mu się uciec w odmienionym ciele dwóch ioniańskich łowców, którzy bezwiednie go wyzwolili i zostali przeklęci, by nieść łuk, który zawierał jego esencję. Varus poluje teraz na tych, którzy go uwięzili, aby dokonać na nich brutalnej zemsty, jednakże powiązane z nim dusze śmiertelników przeciwstawiają mu się na każdym kroku.', 7, 3, 4, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Varus_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Varus.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Vayne', 'Nocna Łowczyni', 'Shauna Vayne, pochodząca z Demacii, to bezlitosna łowczyni potworów, która poprzysięgła, że zniszczy demona, który wymordował jej rodzinę. Uzbrojona w przymocowaną do nadgarstka kuszę, z sercem wypełnionym żądzą zemsty, odnajduje szczęście jedynie w zabijaniu sług i stworów ciemności za pomocą wystrzeliwanych z cienia srebrnych bełtów.', 10, 1, 1, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Vayne_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Vayne.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Veigar', 'Panicz Zła', 'Entuzjastyczny mistrz czarnej magii, Veigar poznał moce, z którymi niewielu śmiertelników chce się zaznajomić. Jako niezależny mieszkaniec Bandle City, chciał wyjść poza granice yordlowej magii, więc zaczął zajmować się magicznymi wolumenami, które pozostawały ukryte przez tysiące lat. Teraz jest upartym stworzeniem, z niekończącą się fascynacją na punkcie tajemnic wszechświata. Veigar jest często niedoceniany przez innych — choć sam wierzy, że jest prawdziwie zły, posiada wewnętrzny zmysł moralności, przez który inni kwestionują jego pobudki.', 2, 2, 10, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Veigar_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Veigar.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Vel''Koz', 'Oko Pustki', 'Nie wiadomo czy Vel''Koz był pierwszym Pomiotem Pustki, który pojawił się w Runeterze, ale na pewno żaden inny Pomiot nie doścignął poziomu jego chłodnego, wykalkulowanego rozumowania świata. Choć jego pobratymcy pożerają lub profanują wszystko wokół, on woli analizować i przyglądać się fizycznemu wymiarowi — oraz dziwnym, wojowniczym istotom, które go zamieszkują — szukając słabości, które Pustka mogłaby wykorzystać. Lecz Vel''Koz bynajmniej nie przygląda się biernie temu wszystkiemu, atakuje zagrażające mu osobniki, wystrzeliwując zabójczą plazmę i przerywając materiał świata.', 2, 2, 10, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Velkoz_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Velkoz.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Vex', 'Ponuraczka', 'W czarnym sercu Wysp Cienia samotna Yordlka brnie przez widmową mgłę zadowolona ze swojej mrocznej niedoli. Vex dysponuje bezbrzeżnymi pokładami nastoletniego buntu i potężnym cieniem, z których pomocą chce wykroić dla siebie kawałek mroku z dala od wstrętnej radości świata „normików”. Może brakuje jej ambicji, ale błyskawicznie burzy wszelkie przejawy koloru i szczęśliwości oraz powstrzymuje natrętów swoim magicznym marazmem.', 0, 0, 0, 0, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Vex_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Vex.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Vi', 'Stróż Prawa z Piltover', 'Vi, wiodąca niegdyś przestępcze życie na posępnych ulicach Zaun, jest impulsywną, gwałtowną i nieustraszoną kobietą, niemającą zbyt wiele szacunku do przedstawicieli władz. Dorastając w samotności, do perfekcji rozwinęła instynkt przetrwania, a także szorstkie poczucie humoru. Pracując dla Strażników Piltover w walce o pokój, nosi potężne, hextechowe rękawice, mogące z równą łatwością przebijać się przez ściany, jak i wbijać rozum do głowy przestępcom.', 8, 5, 3, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Vi_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Vi.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Viego', 'Zniszczony Król', 'Viego, niegdyś władca dawno utraconego królestwa, zginął ponad tysiąc lat temu, gdy jego próba przywrócenia żony do życia spowodowała magiczną katastrofę znaną jako Zrujnowanie. Przekształcony w potężnego, nieżywego upiora, którego torturuje obsesyjna tęsknota za swoją nieżyjącą od wieków królową, Viego stał się Zniszczonym Królem. Kontroluje śmiercionośne Harrowing, przemierzając Runeterrę w poszukiwaniu czegokolwiek, co może kiedyś przywrócić do życia jego ukochaną, i niszcząc wszystko na swojej drodze, ponieważ Czarna Mgła wylewa się bez końca z jego okrutnego, złamanego serca.', 6, 4, 2, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Viego_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Viego.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Viktor', 'Zwiastun Maszyn', 'Zwiastun wielkiej nowej ery technologii, Viktor poświęcił swoje życie na udoskonalanie gatunku ludzkiego. Idealista, który chce wynieść ludzi Zaun na nowe poziomy rozumienia, wierzy, że tylko poddając się wielkiej ewolucji technologii ludzkość może osiągnąć swój maksymalny potencjał. Viktor, którego ciało zostało ulepszone dzięki stali i nauce, gorliwie dąży do spełnienia swoich marzeń o świetlanej przyszłości.', 2, 4, 10, 9, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Viktor_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Viktor.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Vladimir', 'Krwiożerczy Żniwiarz', 'Potwór pragnący krwi śmiertelników, Vladimir wpływa na sprawy Noxusu od zarania imperium. Poza nienaturalnym wydłużaniem swojego życia, jego mistrzowskie władanie krwią pozwala mu na kontrolowanie umysłów i ciał innych, jakby były jego własnymi. Umożliwiło mu to stworzenie fanatycznego kultu własnej osoby na krzykliwych salonach noxiańskiej arystokracji. Ta zdolność potrafi również sprawić, że w najciemniejszych zaułkach jego wrogowie wykrwawiają się na śmierć.', 2, 6, 8, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Vladimir_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Vladimir.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Volibear', 'Bezlitosny Grom', 'Ci, którzy wciąż czczą Volibeara, uznają go za uosobienie burzy. Ten niszczycielski, dziki i niewzruszony stwór istniał, zanim śmiertelnicy postawili stopę we freljordzkiej tundrze i z dzikością broni krainy, którą stworzył wraz ze swoimi półboskimi pobratymcami. Pielęgnując w sobie głęboką nienawiść do cywilizacji i słabości, jaką ta za sobą pociągnęła, Volibear walczy o powrót do dawnych zwyczajów — do czasu, kiedy kraina nie była okiełznana, a rozlew krwi nie był niczym ograniczony — i ochoczo stawia czoła wszystkim swoim oponentom przy pomocy szponów, kłów i piorunującej dominacji.', 7, 7, 4, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Volibear_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Volibear.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Warwick', 'Rozkiełznany Gniew Zaun', 'Warwick to potwór, który poluje w mrocznych zaułkach Zaun. Przeszedł przemianę w wyniku bolesnych eksperymentów, a jego ciało połączono ze skomplikowanym systemem pomp i zbiorników, które wypełniają jego ciało alchemicznym gniewem. Kryjąc się w cieniach poluje na przestępców, którzy terroryzują mieszkańców miasta. Zapach krwi doprowadza go do szaleństwa. Nikt, kto ją przelewa, nie jest w stanie przed nim uciec.', 9, 5, 3, 3, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Warwick_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Warwick.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Xayah', 'Buntowniczka', 'Niebezpieczna i dokładna Xayah to vastajańska rewolucjonistka, która toczy prywatną wojnę, aby ocalić swój lud. Wykorzystuje swoją szybkość, przebiegłość i ostre jak brzytwa ostrza, aby pozbyć się każdego, kto stanie jej na drodze. Xayah walczy u boku partnera i kochanka, Rakana, aby chronić swoje wymierające plemię i przywrócić swojej rasie dawną chwałę.', 10, 6, 1, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Xayah_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Xayah.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Xerath', 'Wyniesiony Mag', 'Xerath jest Wyniesionym Magiem ze starożytnej Shurimy, istotą o tajemnej energii, żyjącą wśród wirujących szczątków magicznego sarkofagu. Przez tysiące lat uwięziony był pod piaskami pustyni, lecz odrodzenie Shurimy uwolniło go z prastarego więzienia. Doprowadzony do szaleństwa przez swoją potęgę, chciałby stworzyć na swój wzór cywilizację, która opanuje świat i wyprze wszystkie inne.', 1, 3, 10, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Xerath_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Xerath.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Xin Zhao', 'Seneszal Demacii', 'Xin Zhao jest stanowczym wojownikiem lojalnym panującej Dynastii Promiennej Tarczy. Kiedyś skazany na walkę jako gladiator na noxiańskich arenach, przetrwał niezliczone ilości pojedynków, a gdy został wyzwolony przez siły Demacii, przysiągł wieczną wierność swoim wybawicielom. Uzbrojony w swoją ulubioną włócznię o trzech szponach, Xin Zhao walczy teraz dla swojego przybranego królestwa, zuchwale stawiając czoła każdemu wrogowi.', 8, 6, 3, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/XinZhao_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/XinZhao.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Yasuo', 'Pokutnik', 'Yasuo, Ioniańczyk o wielkiej determinacji, jest zwinnym szermierzem, który używa wiatru przeciwko wrogom. Kiedy był dumnym młodzieńcem, niesłusznie oskarżono go o zamordowanie mistrza. Jako że nie mógł dowieść swojej niewinności, przyszło mu zabić własnego brata w akcie samoobrony. Nawet po tym, jak ujawniono prawdziwego zabójcę jego mistrza, Yasuo wciąż nie potrafił wybaczyć sobie tego, co zrobił. Teraz włóczy się po ojczyźnie, mając u swego boku tylko wiatr, który kieruje jego ostrzem.', 8, 4, 4, 10, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Yasuo_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Yasuo.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Yone', 'Wiecznie Żywy', 'Za życia był Yone — przybranym bratem Yasuo i szanowanym uczniem w pobliskiej szkole miecza. Jednak po śmierci z rąk brata nawiedziła go złowroga istota, którą zmuszony był zgładzić przy użyciu jej własnego miecza. Teraz Yone, przeklęty i zmuszony do noszenia na twarzy demonicznej maski, niestrudzenie poluje na wszystkie podobne stworzenia, by zrozumieć, czym się stał.', 8, 4, 4, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Yone_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Yone.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Yorick', 'Pasterz Dusz', 'Yorick, ostatni ocalały z dawno zapomnianego zakonu religijnego, jest zarówno błogosławiony, jak i przeklęty mocą władania nad nieumarłymi. Uwięziony na Wyspach Cienia, jego jedynymi towarzyszami są gnijące zwłoki i wyjące duchy, które gromadzi u swego boku. Potworne działania Yoricka skrywają jednak szlachetny cel — chce uwolnić swój dom od klątwy Zrujnowania.', 6, 6, 4, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Yorick_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Yorick.png', 'Fighter');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Yuumi', 'Magiczna Kotka', 'Yuumi, magiczna kotka z Bandle City, była niegdyś chowańcem yordlowej czarodziejki, Norry. Gdy jej pani zniknęła w tajemniczych okolicznościach, Yuumi stała się Strażniczką żywej Księgi Wrót Norry, podróżując przez portale na jej stronach w poszukiwaniu swej właścicielki. Pragnąc miłości, Yuumi poszukuje przyjaznych towarzyszy, którzy wspomogliby ją w podróży, i chroni ich za pomocą świetlistych tarcz oraz swojej nieposkromionej odwagi. Podczas gdy Książka próbuje trzymać się wyznaczonego zadania, Yuumi często oddaje się przyziemnym przyjemnościom takim jak drzemki czy jedzenie ryb. Zawsze powraca jednak do poszukiwań swojej przyjaciółki.', 5, 1, 8, 2, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Yuumi_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Yuumi.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zac', 'Tajna Broń', 'Zac powstał w wyniku kontaktu toksycznego szlamu z chemtechem, który następnie osiadł w jaskini w głębi slumsów Zaun. Mimo takich narodzin Zac ewoluował z prymitywnego szlamu w istotę myślącą, która zamieszkuje kanalizację miejską, co jakiś czas wynurzając się, aby pomóc tym, którzy nie dają sobie rady sami, albo by odbudować zniszczoną infrastrukturę Zaun.', 3, 7, 7, 8, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zac_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zac.png', 'Tank');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zed', 'Władca Cieni', 'Całkowicie bezwzględny i pozbawiony litości, Zed jest przywódcą Zakonu Cienia, czyli organizacji, którą stworzył, kierując się zmilitaryzowaniem sztuk walki Ionii, by wypędzić noxiańskich najeźdźców. Podczas wojny desperacja sprawiła, że odnalazł sekretną formę cienia — nikczemną magię ducha, równie niebezpieczną i wypaczającą, co potężną. Zed stał się mistrzem tych zakazanych technik, by niszczyć wszystko, co mogłoby zagrażać jego narodowi lub nowemu zakonowi.', 9, 2, 1, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zed_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zed.png', 'Assassin');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zeri', 'Iskierka Zaun', 'Zeri — nieustępliwa, charakterna młoda kobieta wywodząca się z klasy robotniczej Zaun — korzysta ze swojej elektrycznej magii, aby ładować samą siebie i swoją niestandardową, stworzoną specjalnie dla niej broń. Jej niestabilna moc odzwierciedla jej emocje, a otaczające ją iskry obrazują błyskawicznie szybkie podejście do życia. Zeri jest pełna współczucia względem innych, a miłość do rodziny i domu towarzyszy jej w każdej walce. Chociaż jej szczere chęci pomocy przynoszą czasami odwrotny skutek, Zeri wierzy w jedno: stań murem za swoją społecznością, a społeczność stanie murem za tobą.', 8, 5, 3, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zeri_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zeri.png', 'Marksman');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Ziggs', 'Hextechowy Saper', 'Yordle Ziggs, miłośnik dużych bomb i krótkich lontów, jest chodzącym wybuchowym kataklizmem. Będąc asystentem wynalazcy w Piltover, stał się znudzony swoim przepełnionym rutyną życiem, więc zaprzyjaźnił się z szaloną niebieskowłosą wariatką z bombami zwaną Jinx. Po szalonej nocy na mieście, Ziggs posłuchał się jej i przeprowadził do Zaun, gdzie teraz może swobodnie zgłębiać swoje pasje, terroryzując po równo chembaronów i zwykłych obywateli, by dać upust swojej żądzy wybuchów.', 2, 4, 9, 4, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Ziggs_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Ziggs.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zilean', 'Strażnik Czasu', 'Kiedyś potężny mag z Icathii, Zilean zaczął niezdrowo fascynować się upływem czasu, po tym jak był świadkiem zniszczeń, jakie dokonała Pustka na jego ojczyźnie. Nie mogąc poświęcić nawet minuty, by opłakać tę katastrofalną stratę, przywołał starożytną magię temporalną, by dzięki niej odgadnąć wszystkie możliwości. Stawszy się praktycznie nieśmiertelnym, Zilean przemierza przeszłość, teraźniejszość oraz przyszłość, naginając i zakrzywiając przepływ czasu. Bezustannie poszukuje tej nieuchwytnej chwili, która cofnie zegar i odwróci zniszczenie Icathii.', 2, 5, 8, 6, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zilean_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zilean.png', 'Support');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zoe', 'Aspekt Zmierzchu', 'Jako uosobienie psotliwości, wyobraźni i zmiany, Zoe jest kosmicznym posłańcem Targonu, który zwiastuje ważne wydarzenia zmieniające całe światy. Sama jej obecność zakrzywia prawa fizyki, co czasami prowadzi do kataklizmów, lecz nie jest to zamierzone działanie. Być może wyjaśnia to nonszalancję, z jaką Zoe traktuje swoje obowiązki, co daje jej mnóstwo czasu na igraszki, strojenie sobie żartów ze śmiertelników i dostarczanie sobie rozrywki na inne sposoby. Spotkanie z Zoe może być przyjemnym i pozytywnym doświadczeniem, lecz zawsze kryje się w tym coś więcej i nierzadko jest to coś bardzo niebezpiecznego.', 1, 7, 8, 5, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zoe_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zoe.png', 'Mage');
INSERT INTO bohaterowie(nazwa, tytuł, krotki_opis, atak, obrona, magia, trudnosc, obraz, ikona, klasa)VALUES ('Zyra', 'Wiedźma Cierni', 'Urodzona w starożytnej, magicznej katastrofie, Zyra jest uosobieniem gniewu. Natura nadała jej kształt powabnej hybrydy rośliny i człowieka, która sieje życie z każdym krokiem. Postrzega śmiertelników Valoranu jako coś trochę lepszego od nawozu dla jej ziarna-potomstwa i bez problemu zabija ich swoimi śmiercionośnymi kolcami. Choć jej prawdziwe zamiary pozostają tajemnicą, Zyra wędruje po świecie, dając upust swoim pierwotnym żądzom — kolonizuje i wydusza życie ze wszystkiego, co stanie jej na drodze.', 4, 3, 8, 7, 'http://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zyra_0.jpg','http://ddragon.leagueoflegends.com/cdn/13.1.1/img/champion/Zyra.png', 'Mage');

INSERT INTO kontry(bohater, kontra) VALUES ('Aatrox', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Aatrox', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Aatrox', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Ahri', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Ahri', 'Veigar');
INSERT INTO kontry(bohater, kontra) VALUES ('Ahri', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Akali', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Akali', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Akali', 'Galio');
INSERT INTO kontry(bohater, kontra) VALUES ('Alistar', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Alistar', 'Janna');
INSERT INTO kontry(bohater, kontra) VALUES ('Alistar', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Amumu', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Amumu', 'Dr Mundo');
INSERT INTO kontry(bohater, kontra) VALUES ('Amumu', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Anivia', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Anivia', 'Vel''Koz');
INSERT INTO kontry(bohater, kontra) VALUES ('Anivia', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Annie', 'Zilean');
INSERT INTO kontry(bohater, kontra) VALUES ('Annie', 'Varus');
INSERT INTO kontry(bohater, kontra) VALUES ('Annie', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Aphelios', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Aphelios', 'Samira');
INSERT INTO kontry(bohater, kontra) VALUES ('Aphelios', 'Kai''Sa');
INSERT INTO kontry(bohater, kontra) VALUES ('Ashe', 'Draven');
INSERT INTO kontry(bohater, kontra) VALUES ('Ashe', 'Blitzcrank');
INSERT INTO kontry(bohater, kontra) VALUES ('Ashe', 'Nami');
INSERT INTO kontry(bohater, kontra) VALUES ('Aurelion Sol', 'Zed');
INSERT INTO kontry(bohater, kontra) VALUES ('Aurelion Sol', 'Fizz');
INSERT INTO kontry(bohater, kontra) VALUES ('Aurelion Sol', 'Sylas');
INSERT INTO kontry(bohater, kontra) VALUES ('Azir', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Azir', 'Annie');
INSERT INTO kontry(bohater, kontra) VALUES ('Azir', 'Orianna');
INSERT INTO kontry(bohater, kontra) VALUES ('Bard', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Bard', 'Blitzcrank');
INSERT INTO kontry(bohater, kontra) VALUES ('Bard', 'Vel''Koz');
INSERT INTO kontry(bohater, kontra) VALUES ('Blitzcrank', 'Alistar');
INSERT INTO kontry(bohater, kontra) VALUES ('Blitzcrank', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Blitzcrank', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Brand', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Brand', 'Fizz');
INSERT INTO kontry(bohater, kontra) VALUES ('Brand', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Braum', 'Zilean');
INSERT INTO kontry(bohater, kontra) VALUES ('Braum', 'Rakan');
INSERT INTO kontry(bohater, kontra) VALUES ('Braum', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Caitlyn', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Caitlyn', 'Twitch');
INSERT INTO kontry(bohater, kontra) VALUES ('Caitlyn', 'Jhin');
INSERT INTO kontry(bohater, kontra) VALUES ('Camille', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Camille', 'Jax');
INSERT INTO kontry(bohater, kontra) VALUES ('Camille', 'Warwick');
INSERT INTO kontry(bohater, kontra) VALUES ('Cassiopeia', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Cassiopeia', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Cassiopeia', 'Neeko');
INSERT INTO kontry(bohater, kontra) VALUES ('Cho''Gath', 'Mordekaiser');
INSERT INTO kontry(bohater, kontra) VALUES ('Cho''Gath', 'Ornn');
INSERT INTO kontry(bohater, kontra) VALUES ('Cho''Gath', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Corki', 'Anivia');
INSERT INTO kontry(bohater, kontra) VALUES ('Corki', 'Kassadin');
INSERT INTO kontry(bohater, kontra) VALUES ('Corki', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Darius', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Darius', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Darius', 'Teemo');
INSERT INTO kontry(bohater, kontra) VALUES ('Diana', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Diana', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Diana', 'Fiddlesticks');
INSERT INTO kontry(bohater, kontra) VALUES ('Draven', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Draven', 'Jhin');
INSERT INTO kontry(bohater, kontra) VALUES ('Draven', 'Swain');
INSERT INTO kontry(bohater, kontra) VALUES ('Dr Mundo', 'Kindred');
INSERT INTO kontry(bohater, kontra) VALUES ('Dr Mundo', 'Ekko');
INSERT INTO kontry(bohater, kontra) VALUES ('Dr Mundo', 'Shen');
INSERT INTO kontry(bohater, kontra) VALUES ('Ekko', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Ekko', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Ekko', 'Elise');
INSERT INTO kontry(bohater, kontra) VALUES ('Elise', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Elise', 'Fiddlesticks');
INSERT INTO kontry(bohater, kontra) VALUES ('Elise', 'Rammus');
INSERT INTO kontry(bohater, kontra) VALUES ('Evelynn', 'Nunu i Willump');
INSERT INTO kontry(bohater, kontra) VALUES ('Evelynn', 'Xin Zhao');
INSERT INTO kontry(bohater, kontra) VALUES ('Evelynn', 'Rengar');
INSERT INTO kontry(bohater, kontra) VALUES ('Ezreal', 'Jhin');
INSERT INTO kontry(bohater, kontra) VALUES ('Ezreal', 'Vayne');
INSERT INTO kontry(bohater, kontra) VALUES ('Ezreal', 'Tristana');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiddlesticks', 'Zac');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiddlesticks', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiddlesticks', 'Nautilus');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiora', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiora', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Fiora', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Fizz', 'Sylas');
INSERT INTO kontry(bohater, kontra) VALUES ('Fizz', 'Kassadin');
INSERT INTO kontry(bohater, kontra) VALUES ('Fizz', 'Swain');
INSERT INTO kontry(bohater, kontra) VALUES ('Galio', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Galio', 'Janna');
INSERT INTO kontry(bohater, kontra) VALUES ('Galio', 'Varus');
INSERT INTO kontry(bohater, kontra) VALUES ('Gangplank', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Gangplank', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Gangplank', 'Nasus');
INSERT INTO kontry(bohater, kontra) VALUES ('Garen', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Garen', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Garen', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Gnar', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Gnar', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Gnar', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Gragas', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Gragas', 'Lee Sin');
INSERT INTO kontry(bohater, kontra) VALUES ('Gragas', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Graves', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Graves', 'Elise');
INSERT INTO kontry(bohater, kontra) VALUES ('Graves', 'Kindred');
INSERT INTO kontry(bohater, kontra) VALUES ('Gwen', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Gwen', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Gwen', 'Jax');
INSERT INTO kontry(bohater, kontra) VALUES ('Hecarim', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Hecarim', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Hecarim', 'Fiddlesticks');
INSERT INTO kontry(bohater, kontra) VALUES ('Heimerdinger', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Heimerdinger', 'Aatrox');
INSERT INTO kontry(bohater, kontra) VALUES ('Heimerdinger', 'Jayce');
INSERT INTO kontry(bohater, kontra) VALUES ('Illaoi', 'Shen');
INSERT INTO kontry(bohater, kontra) VALUES ('Illaoi', 'Kled');
INSERT INTO kontry(bohater, kontra) VALUES ('Illaoi', 'Garen');
INSERT INTO kontry(bohater, kontra) VALUES ('Irelia', 'Riven');
INSERT INTO kontry(bohater, kontra) VALUES ('Irelia', 'Shen');
INSERT INTO kontry(bohater, kontra) VALUES ('Irelia', 'Jax');
INSERT INTO kontry(bohater, kontra) VALUES ('Ivern', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Ivern', 'Fiddlesticks');
INSERT INTO kontry(bohater, kontra) VALUES ('Ivern', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Janna', 'Sona');
INSERT INTO kontry(bohater, kontra) VALUES ('Janna', 'Bard');
INSERT INTO kontry(bohater, kontra) VALUES ('Janna', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Jarvan IV', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Jarvan IV', 'Fiddlesticks');
INSERT INTO kontry(bohater, kontra) VALUES ('Jarvan IV', 'Zac');
INSERT INTO kontry(bohater, kontra) VALUES ('Jax', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Jax', 'Riven');
INSERT INTO kontry(bohater, kontra) VALUES ('Jax', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Jayce', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Jayce', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Jayce', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Jhin', 'Vayne');
INSERT INTO kontry(bohater, kontra) VALUES ('Jhin', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Jhin', 'Tristana');
INSERT INTO kontry(bohater, kontra) VALUES ('Jinx', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Jinx', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Jinx', 'Swain');
INSERT INTO kontry(bohater, kontra) VALUES ('Kai''Sa', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Kai''Sa', 'Vayne');
INSERT INTO kontry(bohater, kontra) VALUES ('Kai''Sa', 'Samira');
INSERT INTO kontry(bohater, kontra) VALUES ('Kalista', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Kalista', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Kalista', 'Tristana');
INSERT INTO kontry(bohater, kontra) VALUES ('Karma', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Karma', 'Rakan');
INSERT INTO kontry(bohater, kontra) VALUES ('Karma', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Karthus', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Karthus', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Karthus', 'Vel''Koz');
INSERT INTO kontry(bohater, kontra) VALUES ('Kassadin', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Kassadin', 'Pantheon');
INSERT INTO kontry(bohater, kontra) VALUES ('Kassadin', 'Rumble');
INSERT INTO kontry(bohater, kontra) VALUES ('Katarina', 'Galio');
INSERT INTO kontry(bohater, kontra) VALUES ('Katarina', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Katarina', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayle', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayle', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayle', 'Yorick');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayn', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayn', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Kayn', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Kennen', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Kennen', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Kennen', 'Brand');
INSERT INTO kontry(bohater, kontra) VALUES ('Kha''Zix', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Kha''Zix', 'Master Yi');
INSERT INTO kontry(bohater, kontra) VALUES ('Kha''Zix', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Kindred', 'Xin Zhao');
INSERT INTO kontry(bohater, kontra) VALUES ('Kindred', 'Master Yi');
INSERT INTO kontry(bohater, kontra) VALUES ('Kindred', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Kled', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Kled', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Kled', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Kog''Maw', 'Jhin');
INSERT INTO kontry(bohater, kontra) VALUES ('Kog''Maw', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Kog''Maw', 'Sivir');
INSERT INTO kontry(bohater, kontra) VALUES ('LeBlanc', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('LeBlanc', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('LeBlanc', 'Zyra');
INSERT INTO kontry(bohater, kontra) VALUES ('Lee Sin', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Lee Sin', 'Rek''Sai');
INSERT INTO kontry(bohater, kontra) VALUES ('Lee Sin', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Leona', 'Bard');
INSERT INTO kontry(bohater, kontra) VALUES ('Leona', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Leona', 'Seraphine');
INSERT INTO kontry(bohater, kontra) VALUES ('Lillia', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Lillia', 'Hecarim');
INSERT INTO kontry(bohater, kontra) VALUES ('Lillia', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Lissandra', 'Fizz');
INSERT INTO kontry(bohater, kontra) VALUES ('Lissandra', 'Veigar');
INSERT INTO kontry(bohater, kontra) VALUES ('Lissandra', 'Viktor');
INSERT INTO kontry(bohater, kontra) VALUES ('Lucian', 'Vayne');
INSERT INTO kontry(bohater, kontra) VALUES ('Lucian', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Lucian', 'Caitlyn');
INSERT INTO kontry(bohater, kontra) VALUES ('Lulu', 'Seraphine');
INSERT INTO kontry(bohater, kontra) VALUES ('Lulu', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Lulu', 'Xerath');
INSERT INTO kontry(bohater, kontra) VALUES ('Lux', 'Yuumi');
INSERT INTO kontry(bohater, kontra) VALUES ('Lux', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Lux', 'Zilean');
INSERT INTO kontry(bohater, kontra) VALUES ('Malphite', 'Sylas');
INSERT INTO kontry(bohater, kontra) VALUES ('Malphite', 'Mordekaiser');
INSERT INTO kontry(bohater, kontra) VALUES ('Malphite', 'Shen');
INSERT INTO kontry(bohater, kontra) VALUES ('Malzahar', 'Talon');
INSERT INTO kontry(bohater, kontra) VALUES ('Malzahar', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Malzahar', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Maokai', 'Yuumi');
INSERT INTO kontry(bohater, kontra) VALUES ('Maokai', 'Viego');
INSERT INTO kontry(bohater, kontra) VALUES ('Maokai', 'Jarvan IV');
INSERT INTO kontry(bohater, kontra) VALUES ('Master Yi', 'Udyr');
INSERT INTO kontry(bohater, kontra) VALUES ('Master Yi', 'Rammus');
INSERT INTO kontry(bohater, kontra) VALUES ('Master Yi', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Miss Fortune', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Miss Fortune', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Miss Fortune', 'Karma');
INSERT INTO kontry(bohater, kontra) VALUES ('Mordekaiser', 'Fiora');
INSERT INTO kontry(bohater, kontra) VALUES ('Mordekaiser', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Mordekaiser', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Morgana', 'Nami');
INSERT INTO kontry(bohater, kontra) VALUES ('Morgana', 'Seraphine');
INSERT INTO kontry(bohater, kontra) VALUES ('Morgana', 'Nidalee');
INSERT INTO kontry(bohater, kontra) VALUES ('Nami', 'Zyra');
INSERT INTO kontry(bohater, kontra) VALUES ('Nami', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Nami', 'Sona');
INSERT INTO kontry(bohater, kontra) VALUES ('Nasus', 'Sylas');
INSERT INTO kontry(bohater, kontra) VALUES ('Nasus', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Nasus', 'Elise');
INSERT INTO kontry(bohater, kontra) VALUES ('Nautilus', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Nautilus', 'Alistar');
INSERT INTO kontry(bohater, kontra) VALUES ('Nautilus', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Neeko', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Neeko', 'Bard');
INSERT INTO kontry(bohater, kontra) VALUES ('Neeko', 'Seraphine');
INSERT INTO kontry(bohater, kontra) VALUES ('Nidalee', 'Hecarim');
INSERT INTO kontry(bohater, kontra) VALUES ('Nidalee', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Nidalee', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Nocturne', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Nocturne', 'Dr Mundo');
INSERT INTO kontry(bohater, kontra) VALUES ('Nocturne', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Nunu i Willump', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Nunu i Willump', 'Master Yi');
INSERT INTO kontry(bohater, kontra) VALUES ('Nunu i Willump', 'Xin Zhao');
INSERT INTO kontry(bohater, kontra) VALUES ('Olaf', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Olaf', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Olaf', 'Shaco');
INSERT INTO kontry(bohater, kontra) VALUES ('Orianna', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Orianna', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Orianna', 'Galio');
INSERT INTO kontry(bohater, kontra) VALUES ('Ornn', 'Shen');
INSERT INTO kontry(bohater, kontra) VALUES ('Ornn', 'Viego');
INSERT INTO kontry(bohater, kontra) VALUES ('Ornn', 'Trundle');
INSERT INTO kontry(bohater, kontra) VALUES ('Pantheon', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Pantheon', 'Nautilus');
INSERT INTO kontry(bohater, kontra) VALUES ('Pantheon', 'Rakan');
INSERT INTO kontry(bohater, kontra) VALUES ('Poppy', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Poppy', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Poppy', 'Nasus');
INSERT INTO kontry(bohater, kontra) VALUES ('Pyke', 'Thresh');
INSERT INTO kontry(bohater, kontra) VALUES ('Pyke', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Pyke', 'Yuumi');
INSERT INTO kontry(bohater, kontra) VALUES ('Qiyana', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Qiyana', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Qiyana', 'Fizz');
INSERT INTO kontry(bohater, kontra) VALUES ('Quinn', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Quinn', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Quinn', 'Maokai');
INSERT INTO kontry(bohater, kontra) VALUES ('Rakan', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Rakan', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Rakan', 'Zilean');
INSERT INTO kontry(bohater, kontra) VALUES ('Rammus', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Rammus', 'Amumu');
INSERT INTO kontry(bohater, kontra) VALUES ('Rammus', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Rek''Sai', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Rek''Sai', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Rek''Sai', 'Graves');
INSERT INTO kontry(bohater, kontra) VALUES ('Rell', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Rell', 'Janna');
INSERT INTO kontry(bohater, kontra) VALUES ('Rell', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Renekton', 'Jax');
INSERT INTO kontry(bohater, kontra) VALUES ('Renekton', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Renekton', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Rengar', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Rengar', 'Rammus');
INSERT INTO kontry(bohater, kontra) VALUES ('Rengar', 'Master Yi');
INSERT INTO kontry(bohater, kontra) VALUES ('Riven', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Riven', 'Viego');
INSERT INTO kontry(bohater, kontra) VALUES ('Riven', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Rumble', 'Master Yi');
INSERT INTO kontry(bohater, kontra) VALUES ('Rumble', 'Kayn');
INSERT INTO kontry(bohater, kontra) VALUES ('Rumble', 'Camille');
INSERT INTO kontry(bohater, kontra) VALUES ('Ryze', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Ryze', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Ryze', 'Zed');
INSERT INTO kontry(bohater, kontra) VALUES ('Samira', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Samira', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Samira', 'Jhin');
INSERT INTO kontry(bohater, kontra) VALUES ('Sejuani', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Sejuani', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Sejuani', 'Olaf');
INSERT INTO kontry(bohater, kontra) VALUES ('Senna', 'Blitzcrank');
INSERT INTO kontry(bohater, kontra) VALUES ('Senna', 'Nautilus');
INSERT INTO kontry(bohater, kontra) VALUES ('Senna', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Seraphine', 'Yuumi');
INSERT INTO kontry(bohater, kontra) VALUES ('Seraphine', 'Nami');
INSERT INTO kontry(bohater, kontra) VALUES ('Seraphine', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Sett', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Sett', 'Yorick');
INSERT INTO kontry(bohater, kontra) VALUES ('Sett', 'Ornn');
INSERT INTO kontry(bohater, kontra) VALUES ('Shaco', 'Xin Zhao');
INSERT INTO kontry(bohater, kontra) VALUES ('Shaco', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Shaco', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Shen', 'Riven');
INSERT INTO kontry(bohater, kontra) VALUES ('Shen', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Shen', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Shyvana', 'Nocturne');
INSERT INTO kontry(bohater, kontra) VALUES ('Shyvana', 'Olaf');
INSERT INTO kontry(bohater, kontra) VALUES ('Shyvana', 'Nunu i Willump');
INSERT INTO kontry(bohater, kontra) VALUES ('Singed', 'Darius');
INSERT INTO kontry(bohater, kontra) VALUES ('Singed', 'Aatrox');
INSERT INTO kontry(bohater, kontra) VALUES ('Singed', 'Garen');
INSERT INTO kontry(bohater, kontra) VALUES ('Sion', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Sion', 'Aatrox');
INSERT INTO kontry(bohater, kontra) VALUES ('Sion', 'Sett');
INSERT INTO kontry(bohater, kontra) VALUES ('Sivir', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Sivir', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Sivir', 'Karthus');
INSERT INTO kontry(bohater, kontra) VALUES ('Skarner', 'Jarvan IV');
INSERT INTO kontry(bohater, kontra) VALUES ('Skarner', 'Hecarim');
INSERT INTO kontry(bohater, kontra) VALUES ('Skarner', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Sona', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Sona', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Sona', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Soraka', 'Yuumi');
INSERT INTO kontry(bohater, kontra) VALUES ('Soraka', 'Sona');
INSERT INTO kontry(bohater, kontra) VALUES ('Soraka', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Swain', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Swain', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Swain', 'Karma');
INSERT INTO kontry(bohater, kontra) VALUES ('Sylas', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Sylas', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Sylas', 'Galio');
INSERT INTO kontry(bohater, kontra) VALUES ('Syndra', 'Kassadin');
INSERT INTO kontry(bohater, kontra) VALUES ('Syndra', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Syndra', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Tahm Kench', 'Mordekaiser');
INSERT INTO kontry(bohater, kontra) VALUES ('Tahm Kench', 'Yorick');
INSERT INTO kontry(bohater, kontra) VALUES ('Tahm Kench', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Taliyah', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Taliyah', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Taliyah', 'Zed');
INSERT INTO kontry(bohater, kontra) VALUES ('Talon', 'Annie');
INSERT INTO kontry(bohater, kontra) VALUES ('Talon', 'Akali');
INSERT INTO kontry(bohater, kontra) VALUES ('Talon', 'Swain');
INSERT INTO kontry(bohater, kontra) VALUES ('Taric', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Taric', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Taric', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Teemo', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Teemo', 'Aatrox');
INSERT INTO kontry(bohater, kontra) VALUES ('Teemo', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Thresh', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Thresh', 'Nami');
INSERT INTO kontry(bohater, kontra) VALUES ('Thresh', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Tristana', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Tristana', 'Kog''Maw');
INSERT INTO kontry(bohater, kontra) VALUES ('Tristana', 'Samira');
INSERT INTO kontry(bohater, kontra) VALUES ('Trundle', 'Mordekaiser');
INSERT INTO kontry(bohater, kontra) VALUES ('Trundle', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Trundle', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Tryndamere', 'Urgot');
INSERT INTO kontry(bohater, kontra) VALUES ('Tryndamere', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Tryndamere', 'Sion');
INSERT INTO kontry(bohater, kontra) VALUES ('Twisted Fate', 'Lux');
INSERT INTO kontry(bohater, kontra) VALUES ('Twisted Fate', 'Seraphine');
INSERT INTO kontry(bohater, kontra) VALUES ('Twisted Fate', 'Vel''Koz');
INSERT INTO kontry(bohater, kontra) VALUES ('Twitch', 'Kai''Sa');
INSERT INTO kontry(bohater, kontra) VALUES ('Twitch', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Twitch', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Udyr', 'Kha''Zix');
INSERT INTO kontry(bohater, kontra) VALUES ('Udyr', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Udyr', 'Zac');
INSERT INTO kontry(bohater, kontra) VALUES ('Urgot', 'Malphite');
INSERT INTO kontry(bohater, kontra) VALUES ('Urgot', 'Sion');
INSERT INTO kontry(bohater, kontra) VALUES ('Urgot', 'Garen');
INSERT INTO kontry(bohater, kontra) VALUES ('Varus', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Varus', 'Tristana');
INSERT INTO kontry(bohater, kontra) VALUES ('Varus', 'Kog''Maw');
INSERT INTO kontry(bohater, kontra) VALUES ('Vayne', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Vayne', 'Ashe');
INSERT INTO kontry(bohater, kontra) VALUES ('Vayne', 'Kog''Maw');
INSERT INTO kontry(bohater, kontra) VALUES ('Veigar', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Veigar', 'Kennen');
INSERT INTO kontry(bohater, kontra) VALUES ('Veigar', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Vel''Koz', 'Thresh');
INSERT INTO kontry(bohater, kontra) VALUES ('Vel''Koz', 'Akali');
INSERT INTO kontry(bohater, kontra) VALUES ('Vel''Koz', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Vi', 'Hecarim');
INSERT INTO kontry(bohater, kontra) VALUES ('Vi', 'Poppy');
INSERT INTO kontry(bohater, kontra) VALUES ('Vi', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Viego', 'Nunu i Willump');
INSERT INTO kontry(bohater, kontra) VALUES ('Viego', 'Elise');
INSERT INTO kontry(bohater, kontra) VALUES ('Viego', 'Udyr');
INSERT INTO kontry(bohater, kontra) VALUES ('Viktor', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Viktor', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Viktor', 'Corki');
INSERT INTO kontry(bohater, kontra) VALUES ('Vladimir', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Vladimir', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Vladimir', 'Gnar');
INSERT INTO kontry(bohater, kontra) VALUES ('Volibear', 'Nasus');
INSERT INTO kontry(bohater, kontra) VALUES ('Volibear', 'Diana');
INSERT INTO kontry(bohater, kontra) VALUES ('Volibear', 'Ekko');
INSERT INTO kontry(bohater, kontra) VALUES ('Warwick', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Warwick', 'Ekko');
INSERT INTO kontry(bohater, kontra) VALUES ('Warwick', 'Rammus');
INSERT INTO kontry(bohater, kontra) VALUES ('Xayah', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Xayah', 'Samira');
INSERT INTO kontry(bohater, kontra) VALUES ('Xayah', 'Senna');
INSERT INTO kontry(bohater, kontra) VALUES ('Xerath', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Xerath', 'Zilean');
INSERT INTO kontry(bohater, kontra) VALUES ('Xerath', 'Annie');
INSERT INTO kontry(bohater, kontra) VALUES ('Xin Zhao', 'Volibear');
INSERT INTO kontry(bohater, kontra) VALUES ('Xin Zhao', 'Hecarim');
INSERT INTO kontry(bohater, kontra) VALUES ('Xin Zhao', 'Warwick');
INSERT INTO kontry(bohater, kontra) VALUES ('Yasuo', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Yasuo', 'Lissandra');
INSERT INTO kontry(bohater, kontra) VALUES ('Yasuo', 'Yone');
INSERT INTO kontry(bohater, kontra) VALUES ('Yone', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Yone', 'Anivia');
INSERT INTO kontry(bohater, kontra) VALUES ('Yone', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Yorick', 'Wukong');
INSERT INTO kontry(bohater, kontra) VALUES ('Yorick', 'Cho''Gath');
INSERT INTO kontry(bohater, kontra) VALUES ('Yorick', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Yuumi', 'Lulu');
INSERT INTO kontry(bohater, kontra) VALUES ('Yuumi', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Yuumi', 'Thresh');
INSERT INTO kontry(bohater, kontra) VALUES ('Zac', 'Morgana');
INSERT INTO kontry(bohater, kontra) VALUES ('Zac', 'Amumu');
INSERT INTO kontry(bohater, kontra) VALUES ('Zac', 'Nunu i Willump');
INSERT INTO kontry(bohater, kontra) VALUES ('Zed', 'Vladimir');
INSERT INTO kontry(bohater, kontra) VALUES ('Zed', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Zed', 'Ekko');
INSERT INTO kontry(bohater, kontra) VALUES ('Ziggs', 'Malzahar');
INSERT INTO kontry(bohater, kontra) VALUES ('Ziggs', 'LeBlanc');
INSERT INTO kontry(bohater, kontra) VALUES ('Ziggs', 'Samira');
INSERT INTO kontry(bohater, kontra) VALUES ('Zilean', 'Bard');
INSERT INTO kontry(bohater, kontra) VALUES ('Zilean', 'Janna');
INSERT INTO kontry(bohater, kontra) VALUES ('Zilean', 'Jinx');
INSERT INTO kontry(bohater, kontra) VALUES ('Zoe', 'Katarina');
INSERT INTO kontry(bohater, kontra) VALUES ('Zoe', 'Ahri');
INSERT INTO kontry(bohater, kontra) VALUES ('Zoe', 'Yasuo');
INSERT INTO kontry(bohater, kontra) VALUES ('Zyra', 'Xerath');
INSERT INTO kontry(bohater, kontra) VALUES ('Zyra', 'Leona');
INSERT INTO kontry(bohater, kontra) VALUES ('Zyra', 'Rakan');

INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1001, 'Buty', '<mainText><stats><attention>25</attention> jedn. prędkości ruchu</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1001.png', 300, 210);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1004, 'Amulet Wróżki', '<mainText><stats><attention>50%</attention> podstawowej regeneracji many</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1004.png', 250, 175);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1006, 'Koralik Odrodzenia', '<mainText><stats><attention>100%</attention> podstawowej regeneracji zdrowia</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1006.png', 300, 120);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1011, 'Pas Giganta', '<mainText><stats><attention>350 pkt.</attention> zdrowia</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1011.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1018, 'Płaszcz Zręczności', '<mainText><stats><attention>15%</attention> szansy na trafienie krytyczne</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1018.png', 600, 420);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1026, 'Różdżka Zniszczenia', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1026.png', 850, 595);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1027, 'Szafirowy Kryształ', '<mainText><stats><attention>250 pkt.</attention> many</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1027.png', 350, 245);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1028, 'Rubinowy Kryształ', '<mainText><stats><attention>150 pkt.</attention> zdrowia</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1028.png', 400, 280);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1029, 'Lekka Szata', '<mainText><stats><attention>15 pkt.</attention> pancerza</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1029.png', 300, 210);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1031, 'Kamizelka Kolcza', '<mainText><stats><attention>40 pkt.</attention> pancerza</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1031.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1033, 'Opończa Antymagiczna', '<mainText><stats><attention>25 pkt.</attention> odporności na magię</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1033.png', 450, 315);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1035, 'Żaronóż', '<mainText><stats></stats><li><passive>Przypalenie:</passive> Zadawanie obrażeń potworom podpala je na określony czas.<li><passive>Wyzywająca Ścieżka:</passive> Użycie Porażenia 5 razy zużywa ten przedmiot i ulepsza Porażenie do <attention>Wyzywającego Porażenia</attention>, które zadaje potworom zwiększone obrażenia. Wyzywające Porażenie oznacza bohaterów. W tym czasie zadajesz im przy trafieniu dodatkowe obrażenia nieuchronne i otrzymujesz od nich mniejsze obrażenia.<li><passive>Łowca:</passive> Zabijanie dużych potworów zapewnia dodatkowe doświadczenie.<li><passive>Odzyskiwanie:</passive> Regenerujesz manę, gdy znajdujesz się w dżungli lub w rzece. <br><br><rules><status>Zużycie</status> tego przedmiotu na stałe przyznaje wszystkie jego efekty oraz zwiększa obrażenia zadawane potworom przez Porażenie. W przypadku zdobycia większej liczby szt. złota ze stworów niż z potworów z dżungli ilość złota i doświadczenia zdobywanego ze stworów jest znacznie zmniejszona. Leczenie nie jest zmniejszone przy atakach obszarowych. Jeśli bohater posiada poziom niższy o 2 od średniego poziomu bohaterów w grze, zabijanie potworów daje mu dodatkowe pkt. doświadczenia. </rules><br><br><rules>Tylko ataki i umiejętności nakładają efekt podpalenia Wyzywającego Porażenia.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1035.png', 350, 140);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1036, 'Długi Miecz', '<mainText><stats><attention>10 pkt.</attention> obrażeń od ataku</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1036.png', 350, 245);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1037, 'Kilof', '<mainText><stats><attention>25 pkt.</attention> obrażeń od ataku</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1037.png', 875, 613);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1038, 'K. W. Miecz', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1038.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1039, 'Gradoostrze', '<mainText><stats></stats><li><passive>Przypalenie:</passive> Zadawanie obrażeń potworom podpala je na określony czas.<li><passive>Mrożąca Ścieżka:</passive> Użycie Porażenia 5 razy zużywa ten przedmiot i ulepsza Porażenie do <attention>Mrożącego Porażenia</attention>, które zadaje potworom zwiększone obrażenia. Gdy używasz Mrożącego Porażenia na bohaterach, zadajesz im obrażenia nieuchronne i wykradasz ich prędkość ruchu.<li><passive>Łowca:</passive> Zabijanie dużych potworów zapewnia dodatkowe pkt. doświadczenia.<li><passive>Odzyskiwanie:</passive> Regenerujesz manę, gdy znajdujesz się w dżungli lub w rzece. <br><br><rules><status>Zużycie</status> tego przedmiotu na stałe przyznaje wszystkie jego efekty oraz zwiększa obrażenia zadawane potworom przez Porażenie. W przypadku zdobycia większej liczby szt. złota ze stworów niż z potworów z dżungli ilość złota i doświadczenia zdobywanego ze stworów jest znacznie zmniejszona. Leczenie nie jest zmniejszone przy atakach obszarowych. Jeśli bohater posiada poziom niższy o 2 od średniego poziomu bohaterów w grze, zabijanie potworów daje mu dodatkowe pkt. doświadczenia. </rules><br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1039.png', 350, 140);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1040, 'Obsydianowe Ostrze', '<mainText><stats></stats><li><passive>Przypalenie:</passive> Zadawanie obrażeń potworom podpala je na określony czas.<li><passive>Autościeżka:</passive> Użycie Porażenia 5 razy zużywa ten przedmiot i ulepsza Porażenie do Ataku-Porażenia, zwiększając jego obrażenia przeciwko potworom.<li><passive>Łowca:</passive> Zabijanie dużych potworów daje dodatkowe pkt. doświadczenia.<li><passive>Odzyskiwanie:</passive> Regenerujesz manę, gdy znajdujesz się w dżungli lub w rzece. <br><br><rules><status>Zużycie</status> tego przedmiotu na stałe przyznaje wszystkie jego efekty oraz zwiększa obrażenia zadawane potworom przez Porażenie. W przypadku zdobycia większej liczby szt. złota ze stworów niż z potworów z dżungli ilość złota i doświadczenia zdobywanego ze stworów jest znacznie zmniejszona. Leczenie nie jest zmniejszone przy atakach obszarowych. Jeśli bohater posiada poziom niższy o 2 od średniego poziomu bohaterów w grze, zabijanie potworów daje mu dodatkowe pkt. doświadczenia. </rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1040.png', 350, 140);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1042, 'Sztylet', '<mainText><stats><attention>12%</attention> prędkości ataku</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1042.png', 300, 210);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1043, 'Wygięty Łuk', '<mainText><stats><attention>25%</attention> prędkości ataku</stats><br><li><passive>Stalowy Czubek:</passive> Ataki zadają obrażenia fizyczne przy trafieniu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1043.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1052, 'Wzmacniająca Księga', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1052.png', 435, 305);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1053, 'Wampiryczny Kostur', '<mainText><stats><attention>15 pkt.</attention> obrażeń od ataku<br><attention>7%</attention> kradzieży życia</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1053.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1054, 'Tarcza Dorana', '<mainText><stats><attention>80 pkt.</attention> zdrowia</stats><br><li><passive>Skupienie:</passive> Ataki zadają dodatkowe obrażenia stworom.<li><passive>Regeneracja:</passive> Przywraca zdrowie z upływem czasu.<li><passive>Przetrwanie:</passive> Przywraca zdrowie po otrzymaniu obrażeń od bohatera, dużego potwora z dżungli lub potężnego potwora z dżungli. Efektywność przywracania zwiększa się, gdy masz mało zdrowia.<br><br><rules><passive>Przetrwanie</passive> jest skuteczne w 66%, gdy posiadacz tego przedmiotu jest bohaterem walczącym z dystansu albo gdy otrzyma obrażenia obszarowe lub rozłożone w czasie.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1054.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1055, 'Ostrze Dorana', '<mainText><stats><attention>8 pkt.</attention> obrażeń od ataku<br><attention>80 pkt.</attention> zdrowia</stats><br><li><passive>Watażka:</passive> Zyskujesz wszechwampiryzm.<br><br><rules>Wszechwampiryzm jest skuteczny w 33% w przypadku obrażeń obszarowych i obrażeń zadawanych przez zwierzątka.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1055.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1056, 'Pierścień Dorana', '<mainText><stats><attention>15 pkt.</attention> mocy umiejętności<br><attention>70 pkt.</attention> zdrowia</stats><br><li><passive>Skupienie:</passive> Ataki zadają dodatkowe obrażenia stworom. <li><passive>Czerpanie:</passive> Co sekundę przywraca manę. Zadawanie obrażeń wrogiemu bohaterowi zwiększa tę wartość. Jeśli nie możesz zyskać many, przywraca ci zdrowie. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1056.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1057, 'Płaszcz Negacji', '<mainText><stats><attention>50 pkt.</attention> odporności na magię</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1057.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1058, 'Absurdalnie Wielka Różdżka', '<mainText><stats><attention>60 pkt.</attention> mocy umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1058.png', 1250, 875);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1082, 'Tajemnicza Pieczęć', '<mainText><stats><attention>15 pkt.</attention> mocy umiejętności<br><attention>40 pkt.</attention> zdrowia</stats><br><li><passive>Chwała:</passive> Zabójstwo bohatera zapewnia ci następującą liczbę ładunków: 2, podczas gdy asysta gwarantuje ci ładunki w liczbie: 1 (łącznie do 10 ładunków). Tracisz następującą liczbę ładunków po śmierci: 5.<li><passive>Postrach:</passive> Zapewnia <scaleAP>4 pkt. mocy umiejętności</scaleAP> za każdy ładunek <passive>Chwały</passive>.<br><br><rules>Zdobyte ładunki <passive>Chwały</passive> są zachowane pomiędzy tym przedmiotem i <rarityLegendary>Wykradaczem Dusz Mejai</rarityLegendary>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1082.png', 350, 140);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1083, 'Kosa', '<mainText><stats><attention>7 pkt.</attention> obrażeń od ataku</stats><br><li>Ataki przywracają zdrowie za każde trafienie.<li><passive>Skoszenie:</passive> Zabicie stwora w alei zapewnia dodatkowo <goldGain>1 szt.</goldGain> złota. Zabicie 100 stworów w alei zapewnia <goldGain>350 szt.</goldGain> dodatkowego złota oraz wyłącza <passive>Skoszenie</passive>.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1083.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1101, 'Szczeniak Żaroszpona', '<mainText><stats></stats><li><passive>Towarzysze dżungli:</passive> Przyzwij <font color=''#DD2E2E''>Żaroszpona</font>, by towarzyszył ci w dżungli.<li><passive>Cięcie Żaroszpona:</passive> Gdy twój towarzysz dorośnie, czasami nasyci twój następny efekt zadający obrażenia, by <status>spowalniał</status> i zadawał <passive>obrażenia</passive> wrogim bohaterom.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1101.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1102, 'Pisklę Podmuszka', '<mainText><stats></stats><li><passive>Towarzysze dżungli:</passive> Przyzwij <font color=''#38A8E8''>Podmuszka</font>, by towarzyszył ci w dżungli.<li><passive>Chód Podmuszka:</passive> Gdy twój towarzysz dorośnie, zapewni <speed>prędkość ruchu</speed> po wchodzeniu w zarośla lub zabijaniu potworów.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1102.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1103, 'Sadzonka Mchściciela', '<mainText><stats></stats><li><passive>Towarzysze dżungli:</passive> Przywołaj <font color=''#1CA935''>Mchściciela</font>, by towarzyszył ci w dżungli. <li><passive>Odwaga Mchściciela:</passive> Gdy twój towarzysz dorośnie, zapewni <shield>trwałą tarczę</shield>, która odnawia się po zabijaniu potworów lub poza walką. Podczas gdy tarcza jest aktywna, zyskaj 20% nieustępliwości i odporności na spowolnienia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1103.png', 450, 180);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1104, 'Oko Herolda', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zniszcz Oko Herolda, by go przyzwać. Herold zacznie się przemieszczać wzdłuż najbliższej alei, zadając ogromne obrażenia wieżom, które spotka na swojej drodze.<br><br><passive>Przebłysk Pustki:</passive> Zapewnia Wzmocnienie.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1104.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1500, 'Pociski Penetrujące', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1500.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1501, 'Fortyfikacja', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1501.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1502, 'Wzmocniona Zbroja', '<mainText><stats></stats><unique>UNIKALNE Bierne — Wzmocniony Pancerz:</unique> Zmniejsza otrzymywane obrażenia o 0% i sprawia, że wieża jest niewrażliwa na obrażenia nieuchronne, kiedy w pobliżu nie ma wrogich stworów.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1502.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1503, 'Oko Strażnika', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1503.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1504, 'Awangarda', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1504.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1505, 'Piorunochron', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1505.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1506, 'Wzmocniona Zbroja', '<mainText><stats></stats><unique>UNIKALNE Bierne — Wzmocniony Pancerz Wieży w Bazie:</unique> Zmniejsza otrzymywane obrażenia o 0% i sprawia, że wieża jest niewrażliwa na obrażenia nieuchronne, kiedy w pobliżu nie ma wrogich stworów. Wieże w bazie posiadają regenerację zdrowia, ale jest ona ograniczona przez segmenty. Te segmenty znajdują się na 33%, 66% i 100% zdrowia w przypadku wież w bazie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1506.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1507, 'Przeładowanie', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1507.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1508, 'Skarpety Przeciwwieżowe', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1508.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1509, 'Werwa', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1509.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1510, 'Cudaczna Werwa', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1510.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1511, 'Mechaniczny Superpancerz', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1511.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1512, 'Mechaniczne Superpole Mocy', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1512.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1515, 'Opancerzenie Wieży', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1515.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1516, 'Struktura Nagród', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1516.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1517, 'Struktura Nagród', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1517.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1518, 'Struktura Nagród', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1518.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1519, 'Struktura Nagród', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1519.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(1520, 'Przeładowanie', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/1520.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2003, 'Mikstura Zdrowia', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Wypij tę miksturę, by przywrócić <healing>120 pkt. zdrowia</healing> w ciągu 15 sek.<br><br><rules>Możesz mieć ze sobą maksymalnie 5 Mikstur Zdrowia.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2003.png', 50, 20);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2010, 'Ciastko Nieustającej Woli Totalbiscuita', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zjedz ciastko, by przywrócić <healing>8% brakującego zdrowia</healing> oraz <scaleMana>many</scaleMana> w ciągu 5 sek. Zjedzenie lub sprzedanie ciastka na stałe zapewni ci <scaleMana>40 pkt. maks. many</scaleMana>. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2010.png', 50, 5);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2015, 'Odłamek Kircheis', '<mainText><stats><attention>15%</attention> prędkości ataku</stats><br><li><passive>Naładowanie:</passive> Poruszanie się i trafianie atakami generuje Naładowany atak.<li><passive>Iskra:</passive> Twoje naładowane ataki zadają dodatkowe obrażenia magiczne.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2015.png', 700, 490);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2031, 'Odnawialna Mikstura', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zużywa ładunek i przywraca <healing>100 pkt. zdrowia</healing> w ciągu 12 sek. Przechowuje do 2 ładunków, które odnawiają się, ilekroć odwiedzisz sklep.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2031.png', 150, 60);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2033, 'Mikstura Skażenia', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zużywa ładunek i przywraca <healing>100 pkt. zdrowia</healing> oraz <scaleMana>75 pkt. many</scaleMana> w ciągu 12 sek. Użyte w tym czasie zadające obrażenia ataki oraz umiejętności podpalają wrogich bohaterów, przez co otrzymują oni <magicDamage>15 (20 pkt., jeśli nie możesz zyskać many) pkt. obrażeń magicznych</magicDamage> w ciągu 3 sek. Przechowuje do 3 ładunków, które odnawiają się, ilekroć odwiedzisz sklep.<br><br><rules>Obrażenia skażenia zmniejszają się do 50%, gdy zostanie ono nałożone przez obrażenia obszarowe lub rozłożone w czasie.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2033.png', 500, 200);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2051, 'Róg Strażnika', '<mainText><stats><attention>150 pkt.</attention> zdrowia</stats><br><li><passive>Regeneracja:</passive> Przywraca zdrowie z upływem czasu.<li><passive>Niewzruszenie: </passive> Blokuje obrażenia od ataków i zaklęć bohaterów.<li><passive>Legendarny:</passive> Ten przedmiot zalicza się jako <rarityLegendary>legendarny</rarityLegendary>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2051.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2052, 'Poro-Chrupki', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Serwuje przepyszną porcję pobliskiemu Poro, zwiększając jego rozmiary.<br><br><flavorText>Ta mieszanka avarosańskich kur z wolnego wybiegu i organicznych, niemodyfikowanych freljordzkich ziół zawiera kluczowe składniki potrzebne, by twój Poro mruczał z radości.<br><br>Zyski ze sprzedaży trafią na cel walki z noxiańską przemocą wobec zwierząt. </flavorText></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2052.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2055, 'Totem Kontroli', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Umieszcza potężny Totem Kontroli, który zapewnia wizję na pobliskim obszarze. To urządzenie ujawni także <keywordStealth>niewidzialne</keywordStealth> pułapki i <keywordStealth>zakamuflowanych</keywordStealth> bohaterów, a także wrogie Totemy Ukrycia, które dodatkowo wyłączy. <br><br><rules>Możesz mieć ze sobą do 2 Totemów Kontroli. Totemy Kontroli nie wyłączają innych Totemów Kontroli.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2055.png', 75, 30);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2065, 'Pieśń Bitewna Shurelyi', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności<br><attention>200 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br><br><active>Użycie —</active> <active>Inspiracja:</active> Zapewnia pobliskim sojusznikom prędkość ruchu.<li><passive>Motywacja:</passive> Wzmocnienie lub ochronienie innego sojuszniczego bohatera zapewni obu sojusznikom prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2065.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2138, 'Eliksir Żelaza', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Wypij, by zyskać <scaleHealth>300 pkt. zdrowia</scaleHealth>, 25% nieustępliwości oraz zwiększony rozmiar bohatera na 3 min. Gdy ten efekt jest aktywny, podczas poruszania się pozostawiasz ścieżkę, która zapewnia sojusznikom <speed>15% dodatkowej prędkości ruchu</speed>.<br><br><rules>Wypicie innego eliksiru zastąpi efekt istniejącego.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2138.png', 500, 200);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2139, 'Eliksir Czarnoksięstwa', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Wypij, by zyskać <scaleAP>50 pkt. mocy umiejętności</scaleAP> oraz <scaleMana>15% regeneracji many</scaleMana> na 3 min. Gdy ten efekt jest aktywny, trafienie bohatera lub wieży zadaje <trueDamage>25 pkt. dodatkowych obrażeń nieuchronnych</trueDamage> (5 sek. odnowienia).<br><br><rules>Wymagany <attention>9.</attention> lub wyższy poziom do zakupu. Efekt Eliksiru Czarnoksięstwa zadający obrażenia nieuchronne nie ma czasu odnowienia, gdy atakujesz wieże. Wypicie innego Eliksiru zastąpi efekt istniejącego.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2139.png', 500, 200);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2140, 'Eliksir Gniewu', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Wypij, by zyskać <scaleAD>30 pkt. obrażeń od ataku</scaleAD> oraz <lifeSteal>12% fizycznego wampiryzmu</lifeSteal> (przeciwko bohaterom) na 3 min.<br><br><rules>Wypicie innego eliksiru zastąpi efekt istniejącego.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2140.png', 500, 200);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2403, 'Dematerializator Stworów', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zabij wybranego stwora w alei (10sek. )</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2403.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2419, 'Uruchamianie Stopera', '<mainText><stats></stats><li>Po 14 min. zmienia się w <rarityGeneric>Stoper</rarityGeneric>. Udziały w zabójstwach skracają ten czas o 2 min. Ten <rarityGeneric>Stoper</rarityGeneric> wnosi 250 szt. złota do przedmiotów, których jest składnikiem.<br><br><rules>Normalnie wnosi 750 szt. złota.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2419.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2420, 'Stoper', '<mainText><stats></stats><active>Użycie —</active> <active>Inercja:</active> Po jednokrotnym użyciu zyskujesz <status>niewrażliwość</status> i <status>nie można obrać cię na cel</status> przez 2.5 sek. Podczas trwania tego efektu nie możesz wykonywać żadnych innych czynności (przemienia się w <rarityGeneric>Zepsuty Stoper</rarityGeneric>).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2420.png', 750, 300);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2421, 'Zepsuty Stoper', '<mainText><stats></stats><br><li><passive>Ujarzmiony Czas:</passive> Stoper jest zepsuty, ale wciąż może zostać ulepszony.<br><br><rules>Po zepsuciu jednego Stopera handlarz sprzeda ci jedynie <rarityGeneric>Zepsute Stopery.</rarityGeneric></rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2421.png', 750, 300);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2422, 'Lekko Magiczne Obuwie', '<mainText><stats><attention>25</attention> jedn. prędkości ruchu</stats><br><li>Zapewniają dodatkowo <speed>10 jedn. prędkości ruchu</speed>. Buty, które powstaną z Lekko Magicznego Obuwia, zachowają dodatkową prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2422.png', 300, 210);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2423, 'Stoper o Idealnym Wyczuciu Czasu', '<mainText><stats></stats><active>Użycie —</active> <active>Inercja:</active> Po jednokrotnym użyciu zyskujesz <status>niewrażliwość</status> i <status>nie można obrać cię na cel</status> przez 2.5 sek. Podczas trwania tego efektu nie możesz wykonywać żadnych innych czynności (przemienia się w <rarityGeneric>Zepsuty Stoper</rarityGeneric>).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2423.png', 750, 300);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(2424, 'Zepsuty Stoper', '<mainText><stats></stats><br><li><passive>Ujarzmiony Czas:</passive> Stoper jest zepsuty, ale wciąż może zostać ulepszony.<br><br><rules>Po zepsuciu jednego Stopera handlarz sprzeda ci jedynie <rarityGeneric>Zepsute Stopery.</rarityGeneric></rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/2424.png', 750, 300);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3001, 'Zasłona Równości', '<mainText><stats><attention>200 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię</stats><br><li><passive>Iskrzenie:</passive> Po <status>unieruchomieniu</status> bohaterów lub gdy bohater sam zostanie <status>unieruchomiony</status>, zwiększa obrażenia otrzymywane przez cel i wszystkich pobliskich wrogich bohaterów.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention> Pancerz i odporność na magię</attention></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3001.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3003, 'Kostur Archanioła', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>500 pkt.</attention> many<br><attention>200 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Podziw:</passive> Zyskujesz moc umiejętności równą dodatkowej manie.<li><passive>Doładowanie Many:</passive> Traf cel umiejętnością, by pochłonąć doładowanie i zyskać 3 pkt. dodatkowej many. Pkt. dodatkowej many są podwojone, jeżeli cel jest bohaterem. Zapewnia maks. 360 pkt. many, po czym przemienia się w <rarityLegendary>Uścisk Serafina</rarityLegendary>.<br><br><rules>Zyskujesz nowe <passive>Doładowanie Many</passive> co 8 sek. (maks. 4).</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3003.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3004, 'Manamune', '<mainText><stats><attention>35 pkt.</attention> obrażeń od ataku<br><attention>500 pkt.</attention> many<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Podziw:</passive> Zyskujesz dodatkowe <scaleAD>obrażenia od ataku równe maksymalnej liczbie pkt. many</scaleAD>. <li><passive>Doładowanie Many:</passive> Traf cel umiejętnością lub atakiem, by pochłonąć doładowanie i zyskać <scaleMana>3 pkt. dodatkowej many</scaleMana>, podwojone, gdy cel jest bohaterem. Zapewnia maks. 360 pkt. many, po czym przemienia się w <rarityLegendary>Muramanę</rarityLegendary>.<br><br><rules>Zyskujesz nowe <passive>Doładowanie Many</passive> co 8 sek. (maks. 4).</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3004.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3006, 'Nagolenniki Berserkera', '<mainText><stats><attention>35%</attention> prędkości ataku<br><attention>45</attention> jedn. prędkości ruchu</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3006.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3009, 'Buty Prędkości', '<mainText><stats><attention>60</attention> jedn. prędkości ruchu</stats><br><li>Efekty spowalniające prędkość ruchu są osłabione o 25%.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3009.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3011, 'Chemtechowy Skaziciel', '<mainText><stats><attention>60 pkt.</attention> mocy umiejętności<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Gnijąca Toksyna:</passive> Zadawanie wrogim bohaterom obrażeń magicznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek. Uleczenie lub osłonięcie innego sojusznika tarczą wzmocni was, sprawiając, że przy następnym trafieniu wroga nałożycie na cel <status>Głębokie Rany o wartości 40%</status>.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3011.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3020, 'Obuwie Maga', '<mainText><stats><attention>18 pkt.</attention> przebicia odporności na magię<br><attention>45</attention> jedn. prędkości ruchu</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3020.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3024, 'Mroźny Puklerz', '<mainText><stats><attention>20 pkt.</attention> pancerza<br><attention>250 pkt.</attention> many<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3024.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3026, 'Anioł Stróż', '<mainText><stats><attention>45 pkt.</attention> obrażeń od ataku<br><attention>40 pkt.</attention> pancerza</stats><br><li><passive>Zbawienie:</passive> Po otrzymaniu śmiertelnych obrażeń przywraca <healing>50% podstawowego zdrowia</healing> i <scaleMana>30% maksymalnej many</scaleMana> po 4 sek. inercji (300 sek. odnowienia).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3026.png', 3000, 1200);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3031, 'Ostrze Nieskończoności', '<mainText><stats><attention>70 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Perfekcja:</passive> Jeśli masz co najmniej 60% szansy na trafienie krytyczne, zyskujesz 35% obrażeń trafienia krytycznego.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3031.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3033, 'Śmiertelne Przypomnienie', '<mainText><stats><attention>35 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>7%</attention> prędkości ruchu</stats><br><li><passive>Sepsa:</passive> Zadawanie wrogim bohaterom obrażeń fizycznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek. Trafienie tego bohatera atakami z rzędu wzmocni efekt <status>Głębokich Ran do 40%</status> przeciwko temu bohaterowi, dopóki efekt pozostanie aktywny.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3033.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3035, 'Ostatni Szept', '<mainText><stats><attention>20 pkt.</attention> obrażeń od ataku<br><attention>18%</attention> przebicia pancerza</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3035.png', 1450, 1015);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3036, 'Pozdrowienia Lorda Dominika', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>30%</attention> przebicia pancerza</stats><br><li><passive>Pogromca Olbrzymów:</passive> Zadaje dodatkowe obrażenia fizyczne przeciwko bohaterom, którzy maja więcej maksymalnego zdrowia od ciebie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3036.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3040, 'Uścisk Serafina', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>860 pkt.</attention> many<br><attention>250 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Podziw:</passive> Zyskujesz moc umiejętności zależną od many.<li><passive>Linia Życia:</passive> Przy otrzymaniu obrażeń, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę o wytrzymałości zależnej od aktualnego poziomu many.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3040.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3041, 'Wykradacz Dusz Mejai', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności<br><attention>100 pkt.</attention> zdrowia</stats><br><li><passive>Chwała:</passive> Zabójstwo bohatera zapewnia ci następującą liczbę ładunków: 4, podczas gdy asysta gwarantuje ci ładunki w liczbie: 2 (łącznie do 25 ładunków). Tracisz następującą liczbę ładunków po śmierci: 10.<li><passive>Postrach:</passive> Zapewnia <scaleAP>5 pkt. mocy umiejętności</scaleAP> za każdy ładunek <passive>Chwały</passive>. Zyskujesz <speed>10% prędkości ruchu</speed>, jeżeli masz co najmniej 10 ładunków.<br><br><rules>Zdobyte ładunki <passive>Chwały</passive> są zachowane pomiędzy tym przedmiotem i <rarityGeneric>Tajemniczą Pieczęcią</rarityGeneric>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3041.png', 1600, 1120);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3042, 'Muramana', '<mainText><stats><attention>35 pkt.</attention> obrażeń od ataku<br><attention>860 pkt.</attention> many<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Podziw:</passive> Zyskujesz dodatkowe obrażenia od ataku w zależności od many. <li><passive>Szok:</passive> Ataki wymierzone w bohaterów zadają dodatkowe obrażenia fizyczne.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3042.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3044, 'Pożeracz', '<mainText><stats><attention>15 pkt.</attention> obrażeń od ataku<br><attention>200 pkt.</attention> zdrowia</stats><br><li><passive>Solidność:</passive> Po zadaniu bohaterowi obrażeń fizycznych przywracasz sobie zdrowie.<br><br><rules>Efektywność przywracania zdrowia zmniejszona w przypadku bohaterów walczących z dystansu.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3044.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3046, 'Widmowy Tancerz', '<mainText><stats><attention>20 pkt.</attention> obrażeń od ataku<br><attention>25%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>7%</attention> prędkości ruchu</stats><br><li><passive>Widmowy Walc:</passive> Ataki zapewniają <status>przenikanie</status> i zwiększoną, kumulującą się prędkość ruchu. Ponadto zaatakowanie 4 razy powoduje, że Widmowy Walc zapewnia również prędkość ataku.<br><br><rules><status>Przenikanie</status> pozwala na unikanie zderzania się z innymi jednostkami.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3046.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3047, 'Pancerniaki', '<mainText><stats><attention>20 pkt.</attention> pancerza<br><attention>45</attention> jedn. prędkości ruchu</stats><br><li>Zmniejsza obrażenia otrzymywane od ataków o 12%.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3047.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3050, 'Konwergencja Zeke''a', '<mainText><stats><attention>250 pkt.</attention> zdrowia<br><attention>35 pkt.</attention> pancerza<br><attention>250 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Przewodnik:</active> Wyznacz <attention>Wspólnika</attention>.<br><li><passive>Konwergencja:</passive> Po <status>unieruchomieniu</status> wroga, ataki i umiejętności twojego <attention>Wspólnika</attention> zadają temu wrogowi dodatkowe obrażenia.<br><br><rules>Bohaterów może łączyć tylko jedna Konwergencja Zeke''a naraz.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3050.png', 2400, 1680);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3051, 'Ogniolubny Topór', '<mainText><stats><attention>15 pkt.</attention> obrażeń od ataku<br><attention>15%</attention> prędkości ataku</stats><br><li><passive>Zwinność:</passive> Atakowanie jednostki zapewnia dodatkową prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3051.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3053, 'Gruboskórność Steraka', '<mainText><stats><attention>400 pkt.</attention> zdrowia</stats><br><li><passive>Pazury do Chwytania:</passive> Zyskujesz premię równą swoim podstawowym obrażeniom od ataku jako dodatkowe obrażenia od ataku.<li><passive>Linia Życia:</passive> Przy otrzymaniu obrażeń, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę, która stopniowo zanika.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3053.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3057, 'Blask', '<mainText><stats></stats><li><passive>Czaroostrze:</passive> Twój następny atak po użyciu umiejętności jest wzmocniony i zadaje dodatkowe obrażenia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3057.png', 700, 490);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3065, 'Oblicze Ducha', '<mainText><stats><attention>450 pkt.</attention> zdrowia<br><attention>50 pkt.</attention> odporności na magię<br><attention>10</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji zdrowia</stats><br><li><passive>Nieograniczona Żywotność:</passive> Wzmacnia skuteczność otrzymywanego leczenia i tarcz.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3065.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3066, 'Skrzydlaty Księżycowy Pancerz', '<mainText><stats><attention>150 pkt.</attention> zdrowia</stats><br><li><passive>Lot:</passive> Zapewnia <speed>5% prędkości ruchu</speed>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3066.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3067, 'Rozgrzany Klejnot', '<mainText><stats><attention>200 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3067.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3068, 'Słoneczna Egida', '<mainText><stats><attention>500 pkt.</attention> zdrowia<br><attention>50 pkt.</attention> pancerza</stats><br><li><passive>Pożoga:</passive> Zadanie lub otrzymanie obrażeń sprawia, że zadajesz pobliskim wrogom <magicDamage> (15 + 1.75% dodatkowego zdrowia) pkt. obrażeń magicznych</magicDamage> na sekundę (zwiększonych o 25% przeciwko stworom) przez 3 sek. Zadawanie obrażeń bohaterom lub potężnym potworom za pomocą tego efektu zapewnia ładunek zwiększający dalsze obrażenia <passive>Pożogi</passive> o 10% na 5 sek. (maks. liczba ładunków: 6).<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3068.png', 2700, 1890);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3070, 'Łza Bogini', '<mainText><stats><attention>240 pkt.</attention> many</stats><br><li><passive>Skupienie:</passive> Ataki zadają dodatkowe obrażenia fizyczne stworom.<li><passive>Doładowanie Many:</passive> Traf cel umiejętnością, by pochłonąć doładowanie i zyskać <scaleMana>3 pkt. dodatkowej many</scaleMana>, podwojone, gdy cel jest bohaterem. Zapewnia maks. 360 pkt. many.<br><br><rules>Zyskujesz nowe <passive>Doładowanie Many</passive> co 8 sek. (maks. 4).</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3070.png', 400, 280);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3071, 'Czarny Tasak', '<mainText><stats><attention>45 pkt.</attention> obrażeń od ataku<br><attention>350 pkt.</attention> zdrowia<br><attention>30</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Drążenie:</passive> Zadanie obrażeń fizycznych bohaterowi nakłada ładunek redukcji pancerza.<li><passive>Szał:</passive> Zadawanie obrażeń fizycznych bohaterom zapewnia prędkość ruchu za każdy nałożony na nich ładunek <unique>Drążenia</unique>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3071.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3072, 'Krwiopijec', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>18%</attention> kradzieży życia</stats><br><li><passive>Tarcza Boskiej Krwi:</passive> Kradzież życia z ataków może przeleczyć cię ponad maksymalny poziom zdrowia. Nadwyżka zdrowia tworzy tarczę, która zacznie się zmniejszać, jeżeli nie zadasz lub nie otrzymasz obrażeń.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3072.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3074, 'Krwiożercza Hydra', '<mainText><stats><attention>65 pkt.</attention> obrażeń od ataku<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>10%</attention> wszechwampiryzmu</stats><br><li><passive>Rozpłatanie:</passive> Ataki i umiejętności zadają obrażenia fizyczne pozostałym pobliskim wrogom.<br><li><passive>Mięsożerność:</passive> Zyskujesz obrażenia od ataku za każde zabójstwo stwora. Wartość ta zostaje zwiększona 2 razy za zabicie bohatera, dużego potwora lub stwora oblężniczego. Śmierć powoduje utratę 60% ładunków.<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3074.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3075, 'Kolczasta Kolczuga', '<mainText><stats><attention>350 pkt.</attention> zdrowia<br><attention>60 pkt.</attention> pancerza</stats><br><li><passive>Kolce:</passive> Gdy jesteś celem ataku, zadajesz obrażenia atakującemu i nakładasz na niego <status>Głębokie Rany</status> o wartości 25%, jeżeli jest bohaterem. Unieruchomienie wrogich bohaterów nakłada również <status>Głębokie Rany</status> o wartości 40%.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3075.png', 2700, 1890);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3076, 'Kamizelka Cierniowa', '<mainText><stats><attention>30 pkt.</attention> pancerza</stats><br><li><passive>Kolce:</passive> Gdy jesteś celem ataku, zadajesz obrażenia atakującemu i nakładasz na niego Głębokie Rany o wartości 25%, jeżeli jest bohaterem.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3076.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3077, 'Tiamat', '<mainText><stats><attention>25 pkt.</attention> obrażeń od ataku</stats><br><li><passive>Rozpłatanie:</passive> Ataki zadają obrażenia fizyczne innym pobliskim wrogom. <br><br>Rozpłatanie nie aktywuje się na budowlach.<br><br>Efektywność tego przedmiotu jest różna w przypadku bohaterów walczących w zwarciu i z dystansu.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3077.png', 1200, 840);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3078, 'Moc Trójcy', '<mainText><stats><attention>35 pkt.</attention> obrażeń od ataku<br><attention>30%</attention> prędkości ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Potrójne Uderzenie:</passive> Ataki zapewniają prędkość ruchu. Jeśli cel jest bohaterem, zwiększasz swoje podstawowe obrażenia od ataku. Ten efekt kumuluje się.<li><passive>Czaroostrze:</passive> Po użyciu umiejętności następny atak podstawowy jest wzmocniony i zadaje dodatkowe obrażenia.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Obrażenia od ataku, przyspieszenie umiejętności i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3078.png', 3333, 2333);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3082, 'Zbroja Strażnika', '<mainText><stats><attention>40 pkt.</attention> pancerza</stats><br><li><passive>Twardy jak Skała:</passive> Zmniejsza obrażenia otrzymywane od ataków.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3082.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3083, 'Plemienna Zbroja', '<mainText><stats><attention>800 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności<br><attention>200%</attention> podstawowej regeneracji zdrowia</stats><br><li><passive>Serce Plemienia:</passive> Gdy masz co najmniej 1100 pkt. dodatkowego zdrowia, przywracasz sobie maksymalne zdrowie na sekundę, jeśli twój bohater nie otrzymał obrażeń przez ostatnie 6 sek.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3083.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3084, 'Stalowe Serce', '<mainText><stats><attention>800 pkt.</attention> zdrowia<br><attention>200%</attention> podstawowej regeneracji zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Kolosalna Konsumpcja:</passive> Przygotuj potężny atak przeciwko bohaterowi przez 3 sek., znajdując się w promieniu 700 jedn. od niego. Naładowany atak zadaje dodatkowe obrażenia fizyczne równe 125 pkt. + <scalehealth>6%</scalehealth> twojego maks. zdrowia i zapewnia ci 10% tej wartości w formie trwałego maks. zdrowia. (30 sek.) czasu odnowienia na cel.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention> 1%</attention> więcej zdrowia i <attention>6%</attention> rozmiaru bohatera.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3084.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3085, 'Huragan Runaana', '<mainText><stats><attention>45%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>7%</attention> prędkości ruchu</stats><br><li><passive>Furia Wiatru:</passive> Gdy atakujesz, wystrzeliwujesz pociski w kierunku maks. 2 wrogów w pobliżu celu. Pociski nakładają efekty przy trafieniu i mogą trafić krytycznie.<br><br><rules>Przedmiot wyłącznie dla bohaterów walczących z dystansu.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3085.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3086, 'Zapał', '<mainText><stats><attention>18%</attention> prędkości ataku<br><attention>15%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Gorliwość:</passive> Zyskujesz <speed>7% prędkości ruchu</speed>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3086.png', 1050, 735);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3089, 'Zabójczy Kapelusz Rabadona', '<mainText><stats><attention>120 pkt.</attention> mocy umiejętności</stats><br><li><passive>Magiczne Dzieło:</passive> Zwiększ swoją całkowitą <scaleAP>moc umiejętności o 35%</scaleAP>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3089.png', 3600, 2520);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3091, 'Koniec Rozumu', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku<br><attention>40%</attention> prędkości ataku<br><attention>40 pkt.</attention> odporności na magię</stats><br><li><passive>Bitwa:</passive> Ataki zadają obrażenia magiczne przy trafieniu i zapewniają prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3091.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3094, 'Ognista Armata', '<mainText><stats><attention>35%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>7%</attention> prędkości ruchu</stats><br><li><passive>Naładowanie:</passive> Poruszanie się i trafianie atakami generuje Naładowany atak.<li><passive>Strzelec Wyborowy:</passive> Twoje naładowane ataki zadają dodatkowe obrażenia. Ponadto zasięg twoich naładowanych ataków zostaje zwiększony.<br><br><rules>Zasięg ataku może zostać zwiększony o maks. 150 jedn.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3094.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3095, 'Klinga Burzy', '<mainText><stats><attention>45 pkt.</attention> obrażeń od ataku<br><attention>15%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Naładowanie:</passive> Poruszanie się i trafianie atakami generuje Naładowany atak.<li><passive>Paraliż:</passive> Twoje naładowane ataki zadają dodatkowe obrażenia magiczne. Ponadto naładowane ataki spowalniają wrogów.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3095.png', 2700, 1890);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3100, 'Zmora Licza', '<mainText><stats><attention>75 pkt.</attention> mocy umiejętności<br><attention>15</attention> jedn. przyspieszenia umiejętności<br><attention>8%</attention> prędkości ruchu</stats><br><li><passive>Czaroostrze:</passive> Twój następny atak po użyciu umiejętności jest wzmocniony i zadaje dodatkowe obrażenia magiczne.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3100.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3102, 'Całun Banshee', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>45 pkt.</attention> odporności na magię<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Uchylenie:</passive> Zapewnia tarczę magii, która blokuje kolejną umiejętność wroga.<br><br><rules>Otrzymanie obrażeń od bohaterów resetuje czas odnowienia tego przedmiotu.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3102.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3105, 'Egida Legionu', '<mainText><stats><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3105.png', 1200, 840);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3107, 'Odkupienie', '<mainText><stats><attention>16%</attention> siły leczenia i tarcz<br><attention>200 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br><br><active>Użycie —</active> <active>Interwencja:</active> Wybierz obszar wewnątrz. Po 2,5 sek. uderzy promień światła, który przywróci sojusznikom zdrowie i zada obrażenia wrogim bohaterom.<br><br><rules>Przedmiot może zostać użyty po śmierci. Obrażenia i leczenie są zmniejszone o 50%, jeśli cel został niedawno objęty działaniem innej <active>Interwencji</active>. Wartość efektów zwiększających się z poziomem jest zależna od poziomu sojusznika.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3107.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3108, 'Czarci Kodeks', '<mainText><stats><attention>35 pkt.</attention> mocy umiejętności<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3108.png', 900, 630);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3109, 'Przysięga Rycerska', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>200%</attention> podstawowej regeneracji zdrowia</stats><br><br><active>Użycie —</active> <active>Ślubowanie:</active> Wyznacz sojusznika, który jest <attention>Godzien</attention>.<br><li><passive>Poświęcenie:</passive> Gdy w pobliżu znajduje się twój <attention>Godzien</attention> sojusznik, przekierowujesz otrzymywane przez niego obrażenia na siebie i leczysz się o wartość zależną od obrażeń zadawanych przez <attention>Godnego</attention> sojusznika bohaterom.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3109.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3110, 'Mroźne Serce', '<mainText><stats><attention>90 pkt.</attention> pancerza<br><attention>400 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Pieszczoty Zimy:</passive> Zmniejsza <attackSpeed>prędkość ataku</attackSpeed> pobliskich wrogów.<li><passive>Twardy jak Skała:</passive> Zmniejsza obrażenia otrzymywane od ataków.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3110.png', 2700, 1890);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3111, 'Obuwie Merkurego', '<mainText><stats><attention>25 pkt.</attention> odporności na magię<br><attention>45</attention> jedn. prędkości ruchu<br><attention>30%</attention> nieustępliwości</stats><br><br><rules>Nieustępliwość skraca czas działania efektów <status>ogłuszenia</status>, <status>spowolnienia</status>, <status>prowokacji</status>, <status>przestraszenia</status>, <status>uciszenia</status>, <status>oślepienia</status>, <status>polimorfii</status> i <status>unieruchomienia</status>. Nie wpływa na efekty <status>wyrzucenia w powietrze</status> i <status>przygwożdżenia</status>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3111.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3112, 'Kula Strażnika', '<mainText><stats><attention>50 pkt.</attention> mocy umiejętności<br><attention>150 pkt.</attention> zdrowia</stats><br><li><passive>Regeneracja:</passive> Przywraca manę z upływem czasu. Jeśli nie możesz zyskać many, przywraca zdrowie.<li><passive>Legendarny:</passive> Ten przedmiot zalicza się jako <rarityLegendary>legendarny</rarityLegendary>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3112.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3113, 'Eteryczny Duszek', '<mainText><stats><attention>30 pkt.</attention> mocy umiejętności</stats><br><li><passive>Szybowanie:</passive> Zyskujesz <speed>5% prędkości ruchu</speed>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3113.png', 850, 595);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3114, 'Bluźnierczy Bożek', '<mainText><stats><attention>50%</attention> podstawowej regeneracji many<br><attention>8%</attention> siły leczenia i tarcz</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3114.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3115, 'Ząb Nashora', '<mainText><stats><attention>100 pkt.</attention> mocy umiejętności<br><attention>50%</attention> prędkości ataku</stats><br><li><passive>Icathiańskie Ukąszenie:</passive> Ataki zadają obrażenia magiczne <OnHit>przy trafieniu</OnHit>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3115.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3116, 'Kryształowy Kostur Rylai', '<mainText><stats><attention>75 pkt.</attention> mocy umiejętności<br><attention>400 pkt.</attention> zdrowia</stats><br><li><passive>Zmarzlina:</passive> Umiejętności zadające obrażenia <status>spowalniają</status> wrogów.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3116.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3117, 'Buty Mobilności', '<mainText><stats></stats><attention>25 jedn.</attention> prędkości ruchu <li>Gdy przebywasz poza walką przez co najmniej 5 sek., efekt tego przedmiotu zwiększa się do <attention>115 jedn.</attention></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3117.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3119, 'Nadejście Zimy', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>500 pkt.</attention> many<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Podziw:</passive> Zyskujesz dodatkowe <scaleHealth>zdrowie równe całkowitej manie</scaleHealth>.<li><passive>Doładowanie Many:</passive> Traf cel umiejętnością lub atakiem, by zużyć ładunek i zyskać <scaleMana>3 pkt. dodatkowej many</scaleMana>. Efekt jest podwojony, jeśli cel jest bohaterem. Zapewnia maks. 360 pkt. many, po czym przemienia się w <rarityLegendary>Wielką Zimę</rarityLegendary>.<br><br><rules>Zyskujesz nowe <passive>Doładowanie Many</passive> co 8 sek. (maks. 4 ładunków).</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3119.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3121, 'Wielka Zima', '<mainText><stats><attention>350 pkt.</attention> zdrowia<br><attention>860 pkt.</attention> many<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><li><passive>Podziw:</passive> Zyskujesz dodatkowe zdrowie w zależności od many.<li><passive>Nieprzemijalność:</passive> <status>Unieruchomienie</status> lub <status>spowolnienie</status> wrogiego bohatera zużywa aktualną manę i zapewnia tarczę. Tarcza zostaje wzmocniona, jeśli w pobliżu znajduje się więcej niż jeden wróg.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3121.png', 2700, 1890);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3123, 'Wezwanie Kata', '<mainText><stats><attention>20 pkt.</attention> obrażeń od ataku</stats><br><li><passive>Rozerwanie:</passive> Zadawanie bohaterom obrażeń fizycznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3123.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3124, 'Ostrze Gniewu Guinsoo', '<mainText><stats><attention>45%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Gniew:</passive> Twoja szansa na trafienie krytyczne jest zmieniana w obrażenia <OnHit>przy trafieniu</OnHit>. Zyskujesz <physicalDamage>40 pkt.</physicalDamage> obrażeń fizycznych <OnHit>przy trafieniu</OnHit> za każde zmienione 20% szans na trafienie krytyczne.<li><passive>Wrzące Uderzenie:</passive> Każdy co trzeci atak dwukrotnie nakłada efekty przy trafieniu.<br><br><rules><passive>Gniew</passive> nie może korzystać z więcej niż 100% szans na trafienie krytyczne. Mnożniki obrażeń trafienia krytycznego mają wpływ na konwersję obrażeń przy trafieniu <passive>Gniewu</passive>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3124.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3133, 'Młot Bojowy Caulfielda', '<mainText><stats><attention>25 pkt.</attention> obrażeń od ataku<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3133.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3134, 'Ząbkowany Sztylet', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku</stats><br><li><passive>Dłuto:</passive> Zyskujesz <scaleLethality>10 pkt. destrukcji</scaleLethality>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3134.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3135, 'Kostur Pustki', '<mainText><stats><attention>65 pkt.</attention> mocy umiejętności<br><attention>40%</attention> przebicia odporności na magię</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3135.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3139, 'Rtęciowy Bułat', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>40 pkt.</attention> odporności na magię</stats><br><br><active>Użycie —</active> <active>Żywe Srebro:</active> Usuwa wszystkie efekty kontroli tłumu i zapewnia dodatkową prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3139.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3140, 'Rtęciowa Szarfa', '<mainText><stats><attention>30 pkt.</attention> odporności na magię</stats><br><br><active>Użycie —</active> <active>Żywe Srebro:</active> Usuwa wszystkie efekty kontroli tłumu (z wyjątkiem <status>wyrzucenia w powietrze</status>).<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3140.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3142, 'Widmowe Ostrze Youmuu', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>18 pkt.</attention> destrukcji<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br> <br><active>Użycie —</active><active>Upiorny Krok:</active> Zyskujesz prędkość ruchu i przenikanie.<br><li><passive>Nawiedzenie:</passive> Zyskujesz dodatkową prędkość ruchu poza walką.<br><br><rules><status>Przenikanie</status> pozwala na unikanie zderzania się z innymi jednostkami.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3142.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3143, 'Omen Randuina', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>60 pkt.</attention> pancerza</stats><br><br><active>Użycie —</active> <active>Pokora:</active> <status>Spowalnia</status> pobliskich wrogów.<br><li><passive>Twardy jak Skała</passive>: Zmniejsza obrażenia zadawane przez ataki.<li><passive>Krytyczna Wytrzymałość</passive>: Trafienia krytyczne zadają o 20% mniej obrażeń posiadaczowi przedmiotu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3143.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3145, 'Alternator Hextech', '<mainText><stats><attention>25 pkt.</attention> mocy umiejętności<br><attention>150 pkt.</attention> zdrowia</stats><br><li><passive>Wysokie Obroty:</passive> Trafienie wroga zadaje dodatkowe obrażenia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3145.png', 1050, 735);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3152, 'Hextechowy Pas Rakietowy', '<mainText><stats><attention>90 pkt.</attention> mocy umiejętności<br><attention>6 pkt.</attention> przebicia odporności na magię<br><attention>250 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active><active>Ponaddźwiękowość:</active> Doskakujesz w wybranym kierunku, wystrzeliwując łuk magicznych pocisków, które zadają obrażenia. Następnie, gdy poruszasz się w kierunku wrogiego bohatera, zyskujesz dodatkową prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie odporności na magię.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3152.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3153, 'Ostrze Zniszczonego Króla', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku<br><attention>25%</attention> prędkości ataku<br><attention>8%</attention> kradzieży życia</stats><br><li><passive>Ostrze Mgły:</passive> Ataki zadają dodatkowe obrażenia fizyczne na podstawie aktualnego zdrowia celu. <li><passive>Syfon:</passive> Trzykrotne zaatakowanie wrogiego bohatera zadaje obrażenia magiczne i wykrada prędkość ruchu.<br><br>Efektywność tego przedmiotu jest różna w przypadku bohaterów walczących w zwarciu i z dystansu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3153.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3155, 'Pochłaniacz Uroków', '<mainText><stats><attention>25 pkt.</attention> obrażeń od ataku<br><attention>35 pkt.</attention> odporności na magię</stats><br><li><passive>Linia Życia:</passive> Przy otrzymaniu obrażeń magicznych, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę pochłaniającą obrażenia magiczne.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3155.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3156, 'Paszcza Malmortiusa', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>50 pkt.</attention> odporności na magię<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Linia Życia:</passive> Przy otrzymaniu obrażeń magicznych, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę pochłaniającą obrażenia magiczne. Gdy aktywuje się <passive>Linia Życia</passive>, zyskujesz wszechwampiryzm do końca walki.  </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3156.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3157, 'Klepsydra Zhonyi', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>45 pkt.</attention> pancerza<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Inercja:</active> Zyskujesz <status>niewrażliwość</status> i <status>nie można obrać cię na cel</status> przez 2.5 sek. Podczas trwania tego efektu nie możesz wykonywać żadnych innych czynności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3157.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3158, 'Ioniańskie Buty Jasności Umysłu', '<mainText><stats><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>45</attention> jedn. prędkości ruchu</stats><br><li>Zyskujesz 12 jedn. przyspieszenia czarów przywoływacza.<br><br><flavorText>„Przedmiot ten stworzono na cześć zwycięstwa Ionii nad Noxusem w starciu rewanżowym o prowincje południowe, 10 grudnia 20 CLE”.</flavorText></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3158.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3161, 'Włócznia Shojin', '<mainText><stats><attention>65 pkt.</attention> obrażeń od ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Siła Smoka:</passive> Wszystkie twoje umiejętności poza superumiejętnością zyskują (8 (+0.08 za każde 100 pkt. obrażeń od ataku) |  6 (+0.06 za każde 100 pkt. obrażeń od ataku)) jedn. przyspieszenia umiejętności, zmniejszonej do ( 4 (+0.04 za każde 100 pkt. obrażeń od ataku) |  3 (+0.03 za każde 100 pkt. obrażeń od ataku)) jedn. przyspieszenia umiejętności dla zaklęć unieruchamiających.<li><passive>Paląca Konieczność:</passive> Zyskujesz do (0.15 | 0.1) jedn. prędkości ruchu, w zależności od brakującego zdrowia (maksymalna wartość, gdy zdrowie spadnie poniżej 33%).<br><br>Efektywność tego przedmiotu jest różna w przypadku bohaterów walczących w zwarciu i z dystansu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3161.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3165, 'Morellonomicon', '<mainText><stats><attention>90 pkt.</attention> mocy umiejętności<br><attention>300 pkt.</attention> zdrowia</stats><br><li><passive>Choroba:</passive> Zadawanie wrogim bohaterom obrażeń magicznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek. Jeśli cel ma mniej niż 50% zdrowia, <status>wartość Głębokich Ran zwiększa się do 40%</status>.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3165.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3177, 'Ostrze Strażnika', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku<br><attention>150 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Legendarny:</passive> Ten przedmiot zalicza się jako <rarityLegendary>legendarny</rarityLegendary>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3177.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3179, 'Glewia Umbry', '<mainText><stats><attention>50 pkt.</attention> obrażeń od ataku<br><attention>10 pkt.</attention> destrukcji<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Zaciemnienie:</passive> Jeśli ujawni cię wrogi totem, odkrywasz pułapki i wyłączasz totemy wokół siebie. Twoje ataki natychmiast niszczą odkryte pułapki i zadają potrójne obrażenia totemom.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3179.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3181, 'Kadłubołamacz', '<mainText><stats><attention>50 pkt.</attention> obrażeń od ataku<br><attention>400 pkt.</attention> zdrowia<br><attention>150%</attention> podstawowej regeneracji zdrowia</stats><br><br><li><passive>Załoga Abordażowa:</passive> Jeśli w pobliżu nie ma sojuszniczych bohaterów, otrzymujesz <scaleArmor>pancerz</scaleArmor> oraz <scaleMR>odporność na magię</scaleMR>, a ataki zadają większe obrażenia wieżom. Duże stwory znajdujące się w pobliżu zyskują <scaleArmor>pancerz</scaleArmor> oraz <scaleMR>odporność na magię</scaleMR> i zadają większe obrażenia wieżom. <br><br><rules>Pancerz i odporność na magię otrzymywane z Załogi Abordażowej zanikają w ciągu 3 sekund, jeśli sojusznik podejdzie zbyt blisko.</rules><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3181.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3184, 'Młot Strażnika', '<mainText><stats><attention>25 pkt.</attention> obrażeń od ataku<br><attention>150 pkt.</attention> zdrowia<br><attention>7%</attention> kradzieży życia</stats><br><li><passive>Legendarny:</passive> Ten przedmiot zalicza się jako <rarityLegendary>legendarny</rarityLegendary>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3184.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3190, 'Naszyjnik Żelaznych Solari', '<mainText><stats><attention>200 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię</stats><br> <br><active>Użycie —</active><active>Oddanie:</active> Zapewniasz pobliskim sojusznikom <shield>tarczę</shield>, która z czasem zanika.<br><li><passive>Konsekracja:</passive> Zapewnia pobliskim sojuszniczym bohaterom pancerz i <scaleMR>odporność na magię</scaleMR>. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Dodatkowy pancerz i odporność na magię do efektu <passive>Konsekracji</passive>.<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3190.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3191, 'Naramiennik Poszukiwacza', '<mainText><stats><attention>30 pkt.</attention> mocy umiejętności<br><attention>15 pkt.</attention> pancerza</stats><br><li><passive>Ścieżka Wiedźmy:</passive> Zabicie jednostki zapewnia <scaleArmor>0.5 pkt. pancerza</scaleArmor> (maks. <scaleArmor>15 pkt.</scaleArmor>).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3191.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3193, 'Kamienna Płyta Gargulca', '<mainText><stats><attention>60 pkt.</attention> pancerza<br><attention>60 pkt.</attention> odporności na magię<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br> <br><active>Użycie —</active><active>Niezłomność:</active> Zyskujesz zanikającą tarczę i zwiększasz swój rozmiar.<br><li><passive>Umocnienie:</passive> Otrzymywanie obrażeń od bohaterów zapewnia ładunek <scaleArmor>dodatkowego pancerza</scaleArmor> i <scaleMR>odporności na magię</scaleMR>.<br><br><rules>Maks. 5 ładunków, 1 ładunek na bohatera.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3193.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3211, 'Widmowa Osłona', '<mainText><stats><attention>250 pkt.</attention> zdrowia<br><attention>25 pkt.</attention> odporności na magię</stats><br><li><passive>Bezcielesność:</passive> Regeneruje zdrowie po otrzymaniu obrażeń od wrogiego bohatera.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3211.png', 1250, 875);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3222, 'Błogosławieństwo Mikaela', '<mainText><stats><attention>16%</attention> siły leczenia i tarcz<br><attention>50 pkt.</attention> odporności na magię<br><attention>15</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br> <br><active>Użycie —</active><active>Oczyszczenie:</active> Regeneruje zdrowie i usuwa wszystkie efekty kontroli tłumu z sojuszniczego bohatera (poza <status>podrzuceniem</status> oraz <status>przygwożdżeniem</status>).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3222.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3330, 'Kukła Stracha na Wróble', '<mainText><stats></stats><br><active>Użycie — Talizman:</active> Umieszcza kukłę, która dla wrogów wygląda dokładnie jak Fiddlesticks. Gromadzi maks. 2 ładunki.<br><br>Wrodzy bohaterowie, którzy zbliżą się do Kukły, aktywują ją, co sprawi, że uda ona wykonanie losowego działania, a następnie się rozpadnie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3330.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3340, 'Totem Ukrycia', '<mainText><stats></stats><active>Użycie — Talizman:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 2 Totemów Ukrycia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3340.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3363, 'Zmiana Dalekowidzenia', '<mainText><stats></stats><active>Użycie — Talizman:</active> Odkrywa dany obszar oraz umieszcza widoczny, delikatny Totem w odległości do 4000 jedn.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3363.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3364, 'Soczewka Wyroczni', '<mainText><stats></stats><active>Użycie — Talizman:</active> Przeszukuje obszar dookoła ciebie, ostrzegając przed ukrytymi wrogimi jednostkami i ujawniając niewidzialne pułapki, a także pobliskie wrogie Totemy Ukrycia (które na krótki czas wyłącza).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3364.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3400, 'Twoja Działka', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zyskujesz 0 szt. złota.<br><br><rules>Dodatkowe złoto przyznawane sojusznikowi, kiedy Pyke wykończy wrogiego bohatera swoją superumiejętnością. Jeśli żaden sojusznik nie wziął udziału w zabójstwie, Pyke zachowa dodatkową Działkę!</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3400.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3504, 'Ognisty Trybularz', '<mainText><stats><attention>60 pkt.</attention> mocy umiejętności<br><attention>8%</attention> siły leczenia i tarcz<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Uświęcenie:</passive> Uleczenie lub osłonięcie tarczą innego sojusznika wzmacnia zarówno jego, jak i ciebie, zapewniając wam dodatkową prędkość ataku i obrażenia magiczne <OnHit>przy trafieniu</OnHit>. <br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3504.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3508, 'Złodziej Esencji', '<mainText><stats><attention>45 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Czaroostrze:</passive> Po użyciu umiejętności twój następny atak zadaje dodatkowe obrażenia magiczne i regeneruje manę.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3508.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3513, 'Oko Herolda', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Zniszcz Oko Herolda, by go przyzwać. Herold zacznie się przemieszczać wzdłuż najbliższej alei, zadając ogromne obrażenia wieżom, które spotka na swojej drodze.<br><br><passive>Przebłysk Pustki:</passive> Zapewnia Wzmocnienie.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3513.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3599, 'Czarna Włócznia Kalisty', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Nawiąż więź z sojusznikiem do końca gry, by zostać Zaprzysiężonymi Sojusznikami. Przysięga wzmocni was, gdy znajdziecie się blisko siebie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3599.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3600, 'Czarna Włócznia Kalisty', '<mainText><stats></stats><active>Użycie — Zużyj:</active> Nawiąż więź z sojusznikiem do końca gry, by zostać Zaprzysiężonymi Sojusznikami. Przysięga wzmocni was, gdy znajdziecie się blisko siebie.<br><br><rules>Potrzebne do użycia superumiejętności <attention>Kalisty</attention>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3600.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3742, 'Pancerz Umrzyka', '<mainText><stats><attention>300 pkt.</attention> zdrowia<br><attention>45 pkt.</attention> pancerza<br><attention>5%</attention> prędkości ruchu</stats><li><passive>Niszczyciel Statków:</passive> Poruszając się, zyskujesz dodatkową prędkość ruchu. Twój następny atak rozładuje skumulowaną prędkość ruchu, by zadać obrażenia. Jeśli obrażenia zostały zadane przez bohatera walczącego w zwarciu przy maks. prędkości, ten atak dodatkowo <status>spowolni</status> cel.<br><br><flavorText>„Jest tylko jeden sposób na odebranie mi tej zbroi…” — Zapomniany imiennik</flavorText></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3742.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3748, 'Kolosalna Hydra', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku<br><attention>500 pkt.</attention> zdrowia</stats><br><li><passive>Kolos:</passive> Zyskujesz <scaleAD>dodatkowe obrażenia od ataku zależne od dodatkowego zdrowia</scaleAD>.<li><passive>Rozpłatanie:</passive> Ataki zadają dodatkowe obrażenia <OnHit>przy trafieniu</OnHit>, tworząc falę uderzeniową, która zadaje obrażenia wrogom znajdującym się za celem.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3748.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3801, 'Kryształowy Karwasz', '<mainText><stats><attention>200 pkt.</attention> zdrowia<br><attention>100%</attention> podstawowej regeneracji zdrowia</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3801.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3802, 'Zaginiony Rozdział', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności<br><attention>300 pkt.</attention> many<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Oświecenie:</passive> Ilekroć zdobywasz poziom, odzyskujesz <scaleMana>20% maks. many</scaleMana> w ciągu 3 sek.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3802.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3803, 'Katalizator Eonów', '<mainText><stats><attention>225 pkt.</attention> zdrowia<br><attention>300 pkt.</attention> many</stats><br><li><passive>Wieczność:</passive> Przywraca manę równą wartości 7% czystych obrażeń otrzymanych od bohaterów oraz zdrowie równe 25% zużytej many, maks. 20 pkt. zdrowia na użycie, na sekundę.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3803.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3814, 'Ostrze Nocy', '<mainText><stats><attention>50 pkt.</attention> obrażeń od ataku<br><attention>10 pkt.</attention> destrukcji<br><attention>325 pkt.</attention> zdrowia</stats><br><li><passive>Uchylenie:</passive> Zyskujesz tarczę magii, która blokuje następną umiejętność wroga.<br><br><rules>Otrzymanie obrażeń resetuje czas odnowienia tego przedmiotu.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3814.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3850, 'Ostrze Złodziejki Czarów', '<mainText><stats><attention>8 pkt.</attention> mocy umiejętności<br><attention>10 pkt.</attention> zdrowia<br><attention>50%</attention> podstawowej regeneracji many<br><attention>2 szt.</attention> złota co 10 sek.</stats><br><li><passive>Danina:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, umiejętności zadające obrażenia i ataki użyte przeciwko wrogom lub budowlom zapewniają 20 szt. złota. Efekt może wystąpić do 3 razy w ciągu 30 sek.<li><passive>Zadanie:</passive> Zdobądź 500 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityGeneric>Lodowy Kieł</rarityGeneric> i zyskać <active>Użycie —</active> <active>Umieszczanie Totemów</active>.<br><br><rules>Ten przedmiot zapewnia zmniejszoną ilość złota ze stworów, jeśli zabijesz ich zbyt wiele.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3850.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3851, 'Lodowy Kieł', '<mainText><stats><attention>15 pkt.</attention> mocy umiejętności<br><attention>70 pkt.</attention> zdrowia<br><attention>75%</attention> podstawowej regeneracji many<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 3 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. <br><br><br><br><li><passive>Danina:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, umiejętności zadające obrażenia i ataki użyte przeciwko bohaterom lub budowlom zapewniają 20 szt. złota. Efekt może wystąpić do 3 razy w ciągu 30 sek.<li><passive>Zadanie:</passive> Zdobądź 1000 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityLegendary>Odłamek Prawdziwego Lodu</rarityLegendary>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3851.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3853, 'Odłamek Prawdziwego Lodu', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności<br><attention>75 pkt.</attention> zdrowia<br><attention>115%</attention> podstawowej regeneracji many<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 4 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3853.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3854, 'Stalowe Naramienniki', '<mainText><stats><attention>3 pkt.</attention> obrażeń od ataku<br><attention>30 pkt.</attention> zdrowia<br><attention>25%</attention> podstawowej regeneracji zdrowia<br><attention>2 szt.</attention> złota co 10 sek.</stats><li><passive>Łupy Wojenne:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, twoje ataki wykańczają stwory, których poziom zdrowia w przypadku bohaterów walczących w zwarciu wynosi mniej niż 50% (30% w przypadku bohaterów walczących z dystansu) ich maks. zdrowia. Zabicie stwora przyznaje tyle samo szt. złota najbliższemu sojuszniczemu bohaterowi. Te efekty odnawiają się co 3 sek. (maks. liczba ładunków: 35).<li><passive>Zadanie:</passive> Zdobądź 500 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityGeneric>Ochraniacze z Runicznej Stali</rarityGeneric> i zyskać <active>Użycie —</active> <active>Umieszczanie Totemów</active>.<br><br><rules>Ten przedmiot zapewnia zmniejszoną ilość złota ze stworów, jeśli zabijesz ich zbyt wiele.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3854.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3855, 'Ochraniacze z Runicznej Stali', '<mainText><stats><attention>6 pkt.</attention> obrażeń od ataku<br><attention>100 pkt.</attention> zdrowia<br><attention>50%</attention> podstawowej regeneracji zdrowia<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 3 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. <br><li><passive>Łupy Wojenne:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, twoje ataki wykańczają stwory, które mają mniej niż 50% maks. zdrowia. Zabicie stwora przyznaje tyle samo szt. złota najbliższemu sojuszniczemu bohaterowi. Te efekty odnawiają się co 35 sek. (maks. liczba ładunków: 3).<li><passive>Zadanie:</passive> Zdobądź 1000 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityLegendary>Bastion Góry</rarityLegendary>. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3855.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3857, 'Naramienniki spod Białej Skały', '<mainText><stats><attention>15 pkt.</attention> obrażeń od ataku<br><attention>250 pkt.</attention> zdrowia<br><attention>100%</attention> podstawowej regeneracji zdrowia<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 4 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3857.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3858, 'Reliktowa Tarcza', '<mainText><stats><attention>5 pkt.</attention> mocy umiejętności<br><attention>30 pkt.</attention> zdrowia<br><attention>25%</attention> podstawowej regeneracji zdrowia<br><attention>2 szt.</attention> złota co 10 sek.</stats><li><passive>Łupy Wojenne:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, twoje ataki wykańczają stwory, których poziom zdrowia w przypadku bohaterów walczących w zwarciu wynosi mniej niż 50% (30% w przypadku bohaterów walczących z dystansu) ich maks. zdrowia. Zabicie stwora przyznaje tyle samo szt. złota najbliższemu sojuszniczemu bohaterowi. Te efekty odnawiają się co 3 sek. (maks. liczba ładunków: 35).<li><passive>Zadanie:</passive> Zdobądź 500 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityGeneric>Puklerz Targonu</rarityGeneric> i zyskać <active>Użycie —</active> <active>Umieszczanie Totemów</active>.<br><br><rules>Ten przedmiot zapewnia zmniejszoną ilość złota ze stworów, jeśli zabijesz ich zbyt wiele.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3858.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3859, 'Puklerz Targonu', '<mainText><stats><attention>10 pkt.</attention> mocy umiejętności<br><attention>100 pkt.</attention> zdrowia<br><attention>50%</attention> podstawowej regeneracji zdrowia<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 3 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. <br><li><passive>Łupy Wojenne:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, twoje ataki wykańczają stwory, które mają mniej niż 50% maks. zdrowia. Zabicie stwora przyznaje tyle samo szt. złota najbliższemu sojuszniczemu bohaterowi. Te efekty odnawiają się co 35 sek. (maks. liczba ładunków: 3).<li><passive>Zadanie:</passive> Zdobądź 1000 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityLegendary>Bastion Góry</rarityLegendary>. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3859.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3860, 'Bastion Góry', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności<br><attention>250 pkt.</attention> zdrowia<br><attention>100%</attention> podstawowej regeneracji zdrowia<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 4 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3860.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3862, 'Widmowy Sierp', '<mainText><stats><attention>5 pkt.</attention> obrażeń od ataku<br><attention>10 pkt.</attention> zdrowia<br><attention>25%</attention> podstawowej regeneracji many<br><attention>2 szt.</attention> złota co 10 sek.</stats><br><li><passive>Danina:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, umiejętności zadające obrażenia i ataki użyte przeciwko wrogom lub budowlom zapewniają 20 szt. złota. Efekt może wystąpić do 3 razy w ciągu 30 sek.<li><passive>Zadanie:</passive> Zdobądź 500 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityGeneric>Półksiężycowe Ostrze Harrowing</rarityGeneric> i zyskać <active>Użycie —</active> <active>Umieszczanie Totemów</active>.<br><br><rules>Ten przedmiot zapewnia zmniejszoną ilość złota ze stworów, jeśli zabijesz ich zbyt wiele.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3862.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3863, 'Półksiężycowe Ostrze Harrowing', '<mainText><stats><attention>10 pkt.</attention> obrażeń od ataku<br><attention>60 pkt.</attention> zdrowia<br><attention>50%</attention> podstawowej regeneracji many<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><li><passive>Danina:</passive> Gdy znajdujesz się w pobliżu sojuszniczego bohatera, umiejętności zadające obrażenia i ataki użyte przeciwko wrogom lub budowlom zapewniają 20 szt. złota. Efekt może wystąpić do 3 razy w ciągu 30 sek.<li><passive>Zadanie:</passive> Zdobądź 1000 szt. złota przy użyciu tego przedmiotu, by przemienić go w <rarityLegendary>Kosę Czarnej Mgły</rarityLegendary> i zyskać Umieszczanie Totemów.<br><br><rules>Ten przedmiot zapewnia zmniejszoną ilość złota ze stworów, jeśli zabijesz ich zbyt wiele.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3863.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3864, 'Kosa Czarnej Mgły', '<mainText><stats><attention>20 pkt.</attention> obrażeń od ataku<br><attention>75 pkt.</attention> zdrowia<br><attention>100%</attention> podstawowej regeneracji many<br><attention>3 szt.</attention> złota co 10 sek.</stats><br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 0 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzisz sklep. <br><br><active>Użycie —</active> <active>Umieszczanie Totemów:</active> Umieszczasz na ziemi <keywordStealth>niewidoczny</keywordStealth> dla wrogów Totem Ukrycia, który zapewnia twojej drużynie wizję na pobliskim obszarze. Przechowuje do 4 Totemów Ukrycia, które odnawiają się, ilekroć odwiedzasz sklep. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3864.png', 400, 160);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(3916, 'Kula Zagłady', '<mainText><stats><attention>35 pkt.</attention> mocy umiejętności</stats><br><li><passive>Klątwa:</passive> Zadawanie wrogim bohaterom obrażeń magicznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/3916.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4005, 'Imperialny Mandat', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności<br><attention>200 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Skoordynowany Ogień:</passive> Umiejętności, które <status>spowalniają</status> lub <status>unieruchamiają</status> bohatera, zadają mu dodatkowe obrażenia i oznaczają go. Zadane przez sojusznika obrażenia detonują te oznaczenie, zadając dodatkowe obrażenia i zapewniając wam prędkość ruchu. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Moc umiejętności. <br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4005.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4401, 'Siła Natury', '<mainText><stats><attention>350 pkt.</attention> zdrowia<br><attention>70 pkt.</attention> odporności na magię<br><attention>5%</attention> prędkości ruchu</stats><br><li><passive>Pochłonięcie:</passive> Otrzymanie <magicDamage>obrażeń magicznych</magicDamage> od wrogiego bohatera zapewnia ładunek <attention>Niewzruszenia</attention>. Wrogie efekty <status>unieruchamiające</status> zapewniają dodatkowe ładunki.<li><passive>Rozproszenie:</passive> Mając maksymalną liczbę ładunków <attention>Niewzruszenia</attention>, otrzymujesz mniejsze obrażenia magiczne i zyskujesz prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4401.png', 2900, 2030);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4403, 'Złota Szpatułka', '<mainText><stats><attention>70 pkt.</attention> obrażeń od ataku<br><attention>120 pkt.</attention> mocy umiejętności<br><attention>50%</attention> prędkości ataku<br><attention>30%</attention> szansy na trafienie krytyczne<br><attention>250 pkt.</attention> zdrowia<br><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię<br><attention>250 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>10%</attention> prędkości ruchu<br><attention>10%</attention> kradzieży życia<br><attention>100%</attention> podstawowej regeneracji zdrowia<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Robi Coś:</passive> Stale igrasz z ogniem!</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4403.png', 7187, 5031);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4628, 'Skupienie Horyzontalne', '<mainText><stats><attention>100 pkt.</attention> mocy umiejętności<br><attention>150 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Hiperstrzał:</passive> Zadanie bohaterowi obrażeń umiejętnością niemierzoną z odległości ponad 700 jedn. lub <status>spowolnienie albo unieruchomienie</status> go <keywordStealth>ujawnia</keywordStealth> cel i zwiększa zadawane mu przez ciebie obrażenia. <br><br><rules>Umiejętność, która aktywuje <passive>Hiperstrzał</passive>, również zadaje zwiększone obrażenia. Zwierzątka i nieunieruchamiające pułapki nie aktywują tego efektu. Tylko początkowe ustawienie umiejętności tworzących pola aktywuje ten efekt. Odległość jest liczona od miejsca użycia umiejętności. </rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4628.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4629, 'Kosmiczny Impuls', '<mainText><stats><attention>65 pkt.</attention> mocy umiejętności<br><attention>200 pkt.</attention> zdrowia<br><attention>30</attention> jedn. przyspieszenia umiejętności<br><attention>5%</attention> prędkości ruchu</stats><br><li><passive>Czarowny Pląs:</passive> Zadanie obrażeń bohaterowi za pomocą następującej liczby oddzielnych ataków lub zaklęć: 3 zapewnia dodatkową prędkość ruchu oraz moc umiejętności aż do zakończenia walki z bohaterami.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4629.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4630, 'Klejnot Rozpadu', '<mainText><stats><attention>25 pkt.</attention> mocy umiejętności<br><attention>13%</attention> przebicia odporności na magię</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4630.png', 1250, 875);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4632, 'Roślinna Bariera', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności<br><attention>25 pkt.</attention> odporności na magię</stats><br><li><passive>Adaptacyjnie:</passive> Zabicie jednostki zapewnia <scaleMR>0.3 pkt. odporności na magię</scaleMR> (maks. <scaleMR>9 pkt.</scaleMR>).<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4632.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4633, 'Szczelinotwórca', '<mainText><stats><attention>70 pkt.</attention> mocy umiejętności<br><attention>300 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności<br><attention>7%</attention> wszechwampiryzmu</stats><br><li><passive>Spaczenie Pustki:</passive> Za każdą sekundę zadawania obrażeń wrogim bohaterom zadajesz dodatkowe obrażenia. Przy maksymalnej wartości dodatkowe obrażenia zostają zadane jako <trueDamage>obrażenia nieuchronne</trueDamage>. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Wszechwampiryzm i moc umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4633.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4635, 'Wysysające Spojrzenie', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności<br><attention>250 pkt.</attention> zdrowia<br><attention>5%</attention> wszechwampiryzmu</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4635.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4636, 'Nocny Żniwiarz', '<mainText><stats><attention>90 pkt.</attention> mocy umiejętności<br><attention>300 pkt.</attention> zdrowia<br><attention>25</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Rozerwanie Duszy:</passive> Zadawanie obrażeń bohaterowi zadaje dodatkowe obrażenia magiczne i zapewnia ci prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4636.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4637, 'Demoniczny Uścisk', '<mainText><stats><attention>75 pkt.</attention> mocy umiejętności<br><attention>350 pkt.</attention> zdrowia</stats><br><li><passive>Spojrzenie Azakana:</passive> Zadawanie bohaterom obrażeń za pomocą umiejętności podpala ich, przez co otrzymują oni dodatkowo co sekundę obrażenia magiczne zależne od ich maksymalnego zdrowia.<li><passive>Mroczny Pakt:</passive> Zyskaj <scaleHealth>dodatkowe zdrowie</scaleHealth> jako <scaleAP>moc umiejętności</scaleAP>. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4637.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4638, 'Czujny Kamienny Totem', '<mainText><stats><attention>150 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Tajemna Skrytka:</passive> Ten przedmiot może przechowywać do 3 zakupionych Totemów Kontroli.<br><br>Po ukończeniu <keywordMajor>misji dla wspierających</keywordMajor> i osiągnięciu poziomu 13. przemienia się w <rarityLegendary>Baczny Kamienny Totem</rarityLegendary>.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4638.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4641, 'Pasjonujący Kamienny Totem', '<mainText><stats><attention>100 pkt.</attention> zdrowia<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><li><passive>Tajemna Skrytka:</passive> Ten przedmiot może przechowywać do 3 zakupionych Totemów Kontroli.<li><passive>Rozkwitające Imperium:</passive> Ten przedmiot przemienia się w <rarityLegendary>Czujny Kamienny Totem</rarityLegendary> po umieszczeniu 15 Totemów Ukrycia.<br><br><rules>Totemy Ukrycia są umieszczane przy użyciu Talizmanu Totemów Ukrycia i ulepszonych przedmiotów: <attention>Unikalne: Wsparcie</attention>.</rules><br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4641.png', 1200, 480);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4642, 'Lustro ze Szkła Bandle', '<mainText><stats><attention>20 pkt.</attention> mocy umiejętności<br><attention>10</attention> jedn. przyspieszenia umiejętności<br><attention>50%</attention> podstawowej regeneracji many</stats></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4642.png', 950, 665);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4643, 'Baczny Kamienny Totem', '<mainText><stats><attention>150 pkt.</attention> zdrowia<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Tajemna Skrytka:</passive> Ten przedmiot może przechowywać do 3 zakupionych Totemów Kontroli.<li><passive>Wejrzenie:</passive> Zwiększa limity ustawionych Totemów Ukrycia i Totemów Kontroli o 1.<li><passive>Błogosławieństwo Ixtal:</passive> Zapewnia premię do dodatkowego zdrowia, dodatkowych obrażeń od ataku, przyspieszenia umiejętności i mocy umiejętności w wysokości 12%.<br><br><rules>Pochodzi z ulepszenia <rarityLegendary>Czujnego Kamienia Widzenia</rarityLegendary>.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4643.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4644, 'Korona Roztrzaskanej Królowej', '<mainText><stats><attention>70 pkt.</attention> mocy umiejętności<br><attention>250 pkt.</attention> zdrowia<br><attention>600 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Boska Osłona:</passive> Zapewnia <keywordMajor>Osłonę</keywordMajor>, która zmniejsza obrażenia otrzymywane od bohaterów. <keywordMajor>Osłona</keywordMajor> utrzymuje się przez 1.5 sek. po otrzymaniu obrażeń od bohaterów. <li><passive>Boski Dar:</passive> Podczas utrzymywania się <keywordMajor>Osłony</keywordMajor> i przez 3 sek. po jej zniszczeniu zyskujesz dodatkową moc umiejętności. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu i moc umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4644.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(4645, 'Płomień Cienia', '<mainText><stats><attention>100 pkt.</attention> mocy umiejętności<br><attention>200 pkt.</attention> zdrowia</stats><br><li><passive>Rozkwit Żaru:</passive> Obrażenia zadawane bohaterom zyskują dodatkowe <keywordStealth>przebicie odporności na magię</keywordStealth> w zależności od <scaleHealth>aktualnego zdrowia</scaleHealth> celu. Zyskujesz maksymalną korzyść, jeśli cel był ostatnio pod wpływem działania tarcz. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/4645.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6029, 'Żelazny Bicz', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku</stats><br><br><active>Użycie —</active> <active>Półksiężyc:</active> Zadaj obrażenia przeciwnikom znajdującym się w pobliżu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6029.png', 1100, 770);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6035, 'Świt Srebrzystej', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>40 pkt.</attention> odporności na magię</stats><br><br><active>Użycie —</active> <active>Żywe Srebro:</active> Usuwa wszystkie efekty kontroli tłumu; zyskujesz nieustępliwość i odporność na spowolnienia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6035.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6333, 'Taniec Śmierci', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>45 pkt.</attention> pancerza<br><attention>15</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Ignorowany Ból:</passive> Otrzymywane przez ciebie obrażenia są rozłożone w czasie.<li><passive>Przeciwstawienie:</passive> Udziały w zabójstwach bohaterów oczyszczają pulę obrażeń <passive>Ignorowanego Bólu</passive> i przywracają zdrowie wraz z upływem czasu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6333.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6609, 'Chempunkowy Łańcuchowy Miecz', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>250 pkt.</attention> zdrowia<br><attention>25</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Złamany Róg:</passive> Zadawanie wrogim bohaterom obrażeń fizycznych nakłada na nich <status>Głębokie Rany o wartości 25%</status> na 3 sek. Jeśli cel ma mniej niż 50% zdrowia, wartość <status>Głębokich Ran</status> zwiększa się do 40%.<br><br><rules><status>Głębokie Rany</status> osłabiają efektywność leczenia i regeneracji.</rules></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6609.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6616, 'Kostur Płynącej Wody', '<mainText><stats><attention>50 pkt.</attention> mocy umiejętności<br><attention>8%</attention> siły leczenia i tarcz<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Fale:</passive> Uleczenie lub osłonięcie innego sojusznika tarczą zapewnia wam dodatkową moc umiejętności i przyspieszenie umiejętności.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6616.png', 2300, 1610);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6617, 'Odnowienie Kamienia Księżycowego', '<mainText><stats><attention>40 pkt.</attention> mocy umiejętności<br><attention>200 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>100%</attention> podstawowej regeneracji many</stats><br><li><passive>Łaska Gwiazd:</passive> Trafianie bohaterów atakami lub umiejętnościami podczas walki przywraca zdrowie najpoważniej zranionemu sojusznikowi w pobliżu. Każda sekunda spędzona w walce z bohaterami zwiększa twoją siłę leczenia i tarcz.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom zwiększenie leczenia <passive>Łaski Gwiazd</passive>.<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6617.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6630, 'Chłeptacz Posoki', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności<br><attention>8%</attention> wszechwampiryzmu</stats><br><br><active>Użycie —</active> <active>Spragnione Cięcie:</active> Zadaje obrażenia pobliskim wrogom. Przywracasz sobie zdrowie za każdego trafionego bohatera.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6630.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6631, 'Łamacz Falangi', '<mainText><stats><attention>50 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> prędkości ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br> <br><active>Użycie —</active><active>Zatrzymujące Cięcie:</active> Zadaje obrażenia pobliskim wrogom, <status>spowalniając</status> ich. Może zostać użyte w ruchu.<br><li><passive>Heroiczny Krok:</passive> Zadawanie obrażeń fizycznych zapewnia prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6631.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6632, 'Boski Łamacz', '<mainText><stats><attention>40 pkt.</attention> obrażeń od ataku<br><attention>300 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><li><passive>Czaroostrze:</passive> Twój następny atak po użyciu umiejętności jest wzmocniony i zadaje dodatkowe obrażenia <OnHit>przy trafieniu</OnHit>. Jeśli cel jest bohaterem, uleczysz się.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie pancerza i przebicie odporności na magię.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6632.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6653, 'Cierpienie Liandry''ego', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>600 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Agonia:</passive> Zadaje dodatkowe obrażenia magiczne bohaterom w zależności od dodatkowego zdrowia celu.<li><passive>Udręka:</passive> Zadawanie obrażeń umiejętnościami podpala wrogów na określony czas.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6653.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6655, 'Nawałnica Luden', '<mainText><stats><attention>80 pkt.</attention> mocy umiejętności<br><attention>6 pkt.</attention> przebicia odporności na magię<br><attention>600 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Echo:</passive> Umiejętności zadające obrażenia zadają obrażenia magiczne celowi i 3 pobliskim wrogom oraz zapewniają ci prędkość ruchu. Zadawanie obrażeń bohaterom za pomocą umiejętności skraca czas odnowienia tego przedmiotu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie odporności na magię. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6655.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6656, 'Wieczna Zmarzlina', '<mainText><stats><attention>70 pkt.</attention> mocy umiejętności<br><attention>250 pkt.</attention> zdrowia<br><attention>600 pkt.</attention> many<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Oblodzenie:</active> Zadaje obrażenia w stożku, <status>spowalniając</status> trafionych wrogów. Wrogowie znajdujący się w centrum stożka zostają <status>unieruchomieni</status>.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Moc umiejętności. <br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6656.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6657, 'Różdżka Wieków', '<mainText><stats><attention>60 pkt.</attention> mocy umiejętności<br><attention>400 pkt.</attention> zdrowia<br><attention>400 pkt.</attention> many</stats><br><br>Przedmiot co 60 sek. zyskuje 20 pkt. zdrowia, 20 pkt. many i 4 pkt. mocy umiejętności, maksymalnie 10 razy. Maksymalnie można zyskać 200 pkt. zdrowia, 200 pkt. many i 40 pkt. mocy umiejętności. Po uzyskaniu maksymalnej liczby ładunków zyskujesz poziom, a wszystkie efekty Wieczności zostają zwiększone o 50%.<br><li><passive>Wieczność:</passive> Przywraca manę równą wartości 7% czystych obrażeń otrzymanych od bohaterów oraz zdrowie równe 25% zużytej many, maks. 20 pkt. zdrowia na użycie, na sekundę. Za każde przywrócone w ten sposób 200 pkt. zdrowia lub many zyskujesz <speed>35% zanikającej prędkości ruchu</speed> na 3 sek.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>5 jedn. przyspieszenia umiejętności.</attention></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6657.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6660, 'Żar Bami', '<mainText><stats><attention>300 pkt.</attention> zdrowia</stats><br><li><passive>Pożoga:</passive> Zadanie lub otrzymanie obrażeń sprawia, że zadajesz pobliskim wrogom obrażenia magiczne co sekundę (które zostają zwiększone przeciwko stworom i potworom).</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6660.png', 1000, 700);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6662, 'Lodowa Rękawica', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>50 pkt.</attention> pancerza<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Czaroostrze:</passive> Po użyciu umiejętności następny atak jest wzmocniony: zadaje dodatkowe obrażenia i tworzy pole lodowe na 2.5 sek. Wrogowie, którzy przejdą przez pole, zostaną <status>spowolnieni</status>. Główny cel zostaje osłabiony, co nakłada na niego o 100% większe spowolnienie i zmniejsza zadawane ci przez niego obrażenia o 10% na 2.5 sek. (1.5sek. ).<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>50 pkt. zdrowia</attention>, <attention>5%</attention> nieustępliwości i <attention>5%</attention> odporności na spowolnienia.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6662.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6664, 'Turbochemiczny Pojemnik', '<mainText><stats><attention>500 pkt.</attention> zdrowia<br><attention>50 pkt.</attention> odporności na magię<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br> <br><active>Użycie —</active><active>Superdoładowanie:</active> Zapewnia dodatkową prędkość ruchu przy poruszaniu się w stronę wrogów lub wrogich wież. Gdy znajdziesz się w pobliżu wroga (lub po upływie 4 sek.), wypuszczona zostanie fala uderzeniowa, która <status>spowolni</status> pobliskich bohaterów.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6664.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6665, 'Jak''Sho Zmienny', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Wytrzymałość Dzieci Pustki:</passive> Za każdą sekundę w walce z bohaterami zyskujesz ładunek zapewniający 2 pkt. <scaleArmor>pancerza</scaleArmor> i <scaleMR>odporności na magię</scaleMR>. Maksymalna liczba ładunków: 8. Po osiągnięciu maksymalnej liczby ładunków przedmiot zostaje wzmocniony, natychmiast czerpiąc zdrowie od pobliskich wrogów, zadając im 0 pkt. obrażeń magicznych i lecząc cię o taką samą wartość, oraz zwiększa twój dodatkowy pancerz i odporność na magię o 20% do końca walki.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>5 pkt.pancerza i odporności na magię</attention>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6665.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6667, 'Świetlista Cnota', '<mainText><stats><attention>400 pkt.</attention> zdrowia<br><attention>30 pkt.</attention> pancerza<br><attention>30 pkt.</attention> odporności na magię<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Przewodnie Światło:</passive> Po użyciu superumiejętności zyskujesz Transcendencję, zwiększając swoje maks. zdrowie o 10% na 9 sek. Podczas Transcendencji ty i twoi sojusznicy znajdujący się w zasięgu 1200 jedn. zyskujecie 20 jedn. przyspieszenia podstawowych umiejętności i leczycie się o 2% swojego maks. zdrowia co 3 sek. Efekt zostaje zwiększony o do 100% zależnie od brakującego zdrowia bohatera (60sek. czasu odnowienia).<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>100 pkt.</attention> zdrowia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6667.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6670, 'Kołczan Południa', '<mainText><stats><attention>30 pkt.</attention> obrażeń od ataku<br><attention>15%</attention> prędkości ataku</stats><br><li><passive>Precyzja:</passive> Ataki zadają dodatkowe obrażenia stworom i potworom.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6670.png', 1300, 910);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6671, 'Potęga Wichury', '<mainText><stats><attention>60 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><br><active>Użycie —</active> <active>Urwanie Chmury:</active> Doskakujesz w wybranym kierunku, wystrzeliwując 3 pociski w stronę wroga o najniższym poziomie zdrowia w pobliżu miejsca docelowego. Zadaje obrażenia, które zostają zwiększone przeciwko celom o niskim poziomie zdrowia.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6671.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6672, 'Pogromca Krakenów', '<mainText><stats><attention>65 pkt.</attention> obrażeń od ataku<br><attention>25%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Powalenie:</passive> Każdy co trzeci atak zadaje dodatkowe obrażenia nieuchronne.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ataku.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6672.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6673, 'Nieśmiertelny Łuklerz', '<mainText><stats><attention>50 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>7%</attention> kradzieży życia</stats><br><li><passive>Linia Życia:</passive> Po otrzymaniu obrażeń, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę. Dodatkowo zyskujesz obrażenia od ataku.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Obrażenia od ataku i zdrowie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6673.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6675, 'Szybkie Ostrza Navori', '<mainText><stats><attention>60 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Transcendencja:</passive> Jeśli masz co najmniej 60% szansy na trafienie krytyczne, twoje ataki skracają czasy odnowienia wszystkich twoich umiejętności z wyjątkiem superumiejętności.<li><passive>Ulotność:</passive> Twoje umiejętności zadają zwiększone obrażenia w zależności od szansy na trafienie krytyczne.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6675.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6676, 'Kolekcjoner', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><attention>12 pkt.</attention> destrukcji</stats><br><li><passive>Śmierć i Podatki:</passive> Zadawanie obrażeń, które pozostawiają wrogich bohaterów z mniejszym poziomem zdrowia niż 5%, zabija ich. Zabójstwa bohaterów zapewniają 25 szt. dodatkowego złota.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6676.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6677, 'Gniewonóż', '<mainText><stats><attention>25%</attention> prędkości ataku</stats><br><li><passive>Gniew:</passive> Twoja szansa na trafienie krytyczne jest zmieniana w obrażenia <OnHit>przy trafieniu</OnHit>. Zyskujesz <physicalDamage>35 pkt. obrażeń fizycznych</physicalDamage> <OnHit>przy trafieniu</OnHit> za każde zmienione 20% szansy na trafienie krytyczne</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6677.png', 800, 560);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6691, 'Mroczne Ostrze Draktharru', '<mainText><stats><attention>60 pkt.</attention> obrażeń od ataku<br><attention>18 pkt.</attention> destrukcji<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Nocny Drapieżca:</passive> Trafienie wroga zadaje dodatkowe obrażenia. Jeśli obrażenia zostały zadane przez bohatera walczącego w zwarciu, ten atak dodatkowo <status>spowolni</status> cel.  Gdy zginie bohater, który otrzymał od ciebie obrażenia w ciągu ostatnich 3 sek., czas odnowienia odświeży się i zyskasz <keywordStealth>niewidzialność</keywordStealth>.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności i prędkość ruchu.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6691.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6692, 'Zaćmienie', '<mainText><stats><attention>60 pkt.</attention> obrażeń od ataku<br><attention>12 pkt.</attention> destrukcji<br><attention>7%</attention> wszechwampiryzmu</stats><br><br><li><passive>Wiecznie Wschodzący Księżyc:</passive> Trafienie bohatera 2 różnymi atakami lub umiejętnościami w ciągu 1.5 sek. zadaje dodatkowo obrażenia, zapewnia prędkość ruchu oraz tarczę.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie pancerza i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6692.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6693, 'Szpon Ciemnego Typa', '<mainText><stats><attention>60 pkt.</attention> obrażeń od ataku<br><attention>18 pkt.</attention> destrukcji<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Piaskowe Machnięcie:</active> Doskakujesz przez wybranego wrogiego bohatera, zadając mu obrażenia. Zadajesz większe obrażenia celowi.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Destrukcję i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6693.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6694, 'Uraza Seryldy', '<mainText><stats><attention>45 pkt.</attention> obrażeń od ataku<br><attention>30%</attention> przebicia pancerza<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Przenikliwe Zimno:</passive> Umiejętności zadające obrażenia <status>spowalniają</status> wrogów.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6694.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6695, 'Wężowy Kieł', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>12 pkt.</attention> destrukcji</stats><br><li><passive>Łupieżca Tarcz:</passive> Zadawanie obrażeń wrogim bohaterom obniża wartość nałożonych na nich tarcz. Gdy zadajesz obrażenia wrogowi, który nie jest dotknięty efektem Łupieżcy Tarcz, obniżasz wartość nałożonych na niego tarcz.<br><br>Efektywność tego przedmiotu jest różna w przypadku bohaterów walczących w zwarciu i z dystansu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6695.png', 2600, 1820);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(6696, 'Aksjomatyczny Łuk', '<mainText><stats><attention>55 pkt.</attention> obrażeń od ataku<br><attention>18 pkt.</attention> destrukcji<br><attention>25</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Fluktuacja:</passive> Przywraca 20% całkowitego czasu odnowienia twojej superumiejętności za każdym razem, gdy wrogi bohater zginie w ciągu 3 sek. od zadania mu przez ciebie obrażeń.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/6696.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7000, 'Szpon Piaskowej Dzierżby', '<mainText><stats><ornnBonus>75 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>26 pkt.</ornnBonus> destrukcji<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Piaskowe Machnięcie:</active> Doskakujesz przez wybranego wrogiego bohatera, zadając mu obrażenia. Zadajesz większe obrażenia celowi.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Destrukcję i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7000.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7001, 'Syzygium', '<mainText><stats><ornnBonus>80 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>20 pkt.</ornnBonus> destrukcji<br><ornnBonus>8%</ornnBonus> wszechwampiryzmu</stats><br><br><li><passive>Wiecznie Wschodzący Księżyc:</passive> Trafienie bohatera 2 różnymi atakami lub umiejętnościami w ciągu 1.5 sek. zadaje dodatkowo obrażenia, zapewnia prędkość ruchu oraz tarczę.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie pancerza i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7001.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7002, 'Cieniotwórca Draktharru', '<mainText><stats><ornnBonus>75 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>26 pkt.</ornnBonus> destrukcji<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Nocny Drapieżca:</passive> Trafienie wroga zadaje dodatkowe obrażenia. Jeśli obrażenia zostały zadane przez bohatera walczącego w zwarciu, ten atak dodatkowo <status>spowolni</status> cel.  Gdy zginie bohater, który otrzymał od ciebie obrażenia w ciągu ostatnich 3 sek., czas odnowienia odświeży się i zyskasz <keywordStealth>niewidzialność</keywordStealth>.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności i prędkość ruchu.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7002.png', 3100, 2170);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7005, 'Zamarznięta Pięść', '<mainText><stats><ornnBonus>550 pkt.</ornnBonus> zdrowia<br><ornnBonus>70 pkt.</ornnBonus> pancerza<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Czaroostrze:</passive> Po użyciu umiejętności następny atak jest wzmocniony: zadaje dodatkowe obrażenia i tworzy pole lodowe na 2.5 sek. Wrogowie, którzy przejdą przez pole, zostaną <status>spowolnieni</status>. Główny cel zostaje osłabiony, co nakłada na niego o 100% większe spowolnienie i zmniejsza zadawane ci przez niego obrażenia o 10% na 2.5 sek. (1.5sek. ).<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>50 pkt. zdrowia</attention>, <attention>5%</attention> nieustępliwości i <attention>5%</attention> odporności na spowolnienia.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7005.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7006, 'Tajfun', '<mainText><stats><ornnBonus>80 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>35%</ornnBonus> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><br><active>Użycie —</active> <active>Urwanie Chmury:</active> Doskakujesz w wybranym kierunku, wystrzeliwując 3 pociski w stronę wroga o najniższym poziomie zdrowia w pobliżu miejsca docelowego. Zadaje obrażenia, które zostają zwiększone przeciwko celom o niskim poziomie zdrowia.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7006.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7007, 'Poświęcenie Wężowej Ofiary', '<mainText><stats><ornnBonus>85 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>40%</ornnBonus> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne</stats><br><li><passive>Powalenie:</passive> Każdy co trzeci atak zadaje dodatkowe obrażenia nieuchronne.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ataku.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7007.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7008, 'Krwiochron', '<mainText><stats><ornnBonus>65 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>30%</ornnBonus> prędkości ataku<br><attention>20%</attention> szansy na trafienie krytyczne<br><ornnBonus>8%</ornnBonus> kradzieży życia</stats><br><li><passive>Linia Życia:</passive> Po otrzymaniu obrażeń, które zmniejszyłyby twoje zdrowie do poziomu niższego niż 30%, zyskujesz tarczę. Dodatkowo zyskujesz obrażenia od ataku.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Obrażenia od ataku i zdrowie.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7008.png', 3400, 2380);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7009, 'Klątwa Icathii', '<mainText><stats><ornnBonus>90 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>450 pkt.</ornnBonus> zdrowia<br><ornnBonus>20 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>8%</ornnBonus> wszechwampiryzmu</stats><br><li><passive>Spaczenie Pustki:</passive> Za każdą sekundę zadawania obrażeń wrogim bohaterom zadajesz dodatkowe obrażenia. Przy maksymalnej wartości dodatkowe obrażenia zostają zadane jako <trueDamage>obrażenia nieuchronne</trueDamage>. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Wszechwampiryzm i moc umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7009.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7010, 'Vesperiański Przypływ', '<mainText><stats><ornnBonus>120 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>400 pkt.</ornnBonus> zdrowia<br><ornnBonus>30 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Rozerwanie Duszy:</passive> Zadawanie obrażeń bohaterowi zadaje dodatkowe obrażenia magiczne i zapewnia ci prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7010.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7011, 'Ulepszony Aeropak', '<mainText><stats><ornnBonus>120 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>10 pkt.</ornnBonus> przebicia odporności na magię<br><ornnBonus>350 pkt.</ornnBonus> zdrowia<br><ornnBonus>20 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><br><active>Użycie —</active><active>Ponaddźwiękowość:</active> Doskakujesz w wybranym kierunku, wystrzeliwując łuk magicznych pocisków, które zadają obrażenia. Następnie, gdy poruszasz się w kierunku wrogiego bohatera, zyskujesz dodatkową prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie odporności na magię.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7011.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7012, 'Lament Liandry''ego', '<mainText><stats><ornnBonus>110 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>800 pkt.</ornnBonus> many<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Agonia:</passive> Zadaje dodatkowe obrażenia magiczne bohaterom w zależności od dodatkowego zdrowia celu.<li><passive>Udręka:</passive> Zadawanie obrażeń umiejętnościami podpala wrogów na określony czas.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7012.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7013, 'Oko Luden', '<mainText><stats><ornnBonus>100 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>10 pkt.</ornnBonus> przebicia odporności na magię<br><ornnBonus>800 pkt.</ornnBonus> many<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Echo:</passive> Umiejętności zadające obrażenia zadają obrażenia magiczne celowi i 3 pobliskim wrogom oraz zapewniają ci prędkość ruchu. Zadawanie obrażeń bohaterom za pomocą umiejętności skraca czas odnowienia tego przedmiotu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie odporności na magię. </mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7013.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7014, 'Wieczna Zima', '<mainText><stats><ornnBonus>90 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>350 pkt.</ornnBonus> zdrowia<br><ornnBonus>800 pkt.</ornnBonus> many<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Oblodzenie:</active> Zadaje obrażenia w stożku, <status>spowalniając</status> trafionych wrogów. Wrogowie znajdujący się w centrum stożka zostają <status>unieruchomieni</status>.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Moc umiejętności. <br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7014.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7015, 'Nieustający Głód', '<mainText><stats><ornnBonus>70 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>450 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>12%</ornnBonus> wszechwampiryzmu</stats><br><br><active>Użycie —</active> <active>Spragnione Cięcie:</active> Zadaje obrażenia pobliskim wrogom. Przywracasz sobie zdrowie za każdego trafionego bohatera.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7015.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7016, 'Niszczyciel Marzeń', '<mainText><stats><ornnBonus>60 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>30%</ornnBonus> prędkości ataku<br><ornnBonus>400 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br> <br><active>Użycie —</active><active>Zatrzymujące Cięcie:</active> Zadaje obrażenia pobliskim wrogom, <status>spowalniając</status> ich. Może zostać użyte w ruchu.<br><li><passive>Heroiczny Krok:</passive> Zadawanie obrażeń fizycznych zapewnia prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7016.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7017, 'Bogobójca', '<mainText><stats><ornnBonus>60 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>450 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><li><passive>Czaroostrze:</passive> Twój następny atak po użyciu umiejętności jest wzmocniony i zadaje dodatkowe obrażenia <OnHit>przy trafieniu</OnHit>. Jeśli cel jest bohaterem, uleczysz się.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przebicie pancerza i przebicie odporności na magię.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7017.png', 3300, 2310);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7018, 'Moc Nieskończoności', '<mainText><stats><ornnBonus>45 pkt.</ornnBonus> obrażeń od ataku<br><ornnBonus>40%</ornnBonus> prędkości ataku<br><ornnBonus>400 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Potrójne Uderzenie:</passive> Ataki zapewniają prędkość ruchu. Jeśli cel jest bohaterem, zwiększasz swoje podstawowe obrażenia od ataku. Ten efekt kumuluje się.<li><passive>Czaroostrze:</passive> Po użyciu umiejętności następny atak podstawowy jest wzmocniony i zadaje dodatkowe obrażenia.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Obrażenia od ataku, przyspieszenie umiejętności i prędkość ruchu.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7018.png', 3333, 2333);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7019, 'Relikwiarz Złotej Jutrzenki', '<mainText><stats><ornnBonus>400 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>40 pkt.</ornnBonus> pancerza<br><ornnBonus>40 pkt.</ornnBonus> odporności na magię</stats><br> <br><active>Użycie —</active><active>Oddanie:</active> Zapewniasz pobliskim sojusznikom <shield>tarczę</shield>, która z czasem zanika.<br><li><passive>Konsekracja:</passive> Zapewnia pobliskim sojuszniczym bohaterom pancerz i <scaleMR>odporność na magię</scaleMR>. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Dodatkowy pancerz i odporność na magię do efektu <passive>Konsekracji</passive>.<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7019.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7020, 'Rekwiem Shurelyi', '<mainText><stats><ornnBonus>70 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>300 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>200%</ornnBonus> podstawowej regeneracji many</stats><br><br><active>Użycie —</active> <active>Inspiracja:</active> Zapewnia pobliskim sojusznikom prędkość ruchu.<li><passive>Motywacja:</passive> Wzmocnienie lub ochronienie innego sojuszniczego bohatera zapewni obu sojusznikom prędkość ruchu.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Przyspieszenie umiejętności.<br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7020.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7021, 'Miotacz Gwiazd', '<mainText><stats><ornnBonus>70 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>300 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>200%</ornnBonus> podstawowej regeneracji many</stats><br><li><passive>Łaska Gwiazd:</passive> Trafianie bohaterów atakami lub umiejętnościami podczas walki przywraca zdrowie najpoważniej zranionemu sojusznikowi w pobliżu. Każda sekunda spędzona w walce z bohaterami zwiększa twoją siłę leczenia i tarcz.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom zwiększenie leczenia <passive>Łaski Gwiazd</passive>.<br><br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7021.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7022, 'Siedzisko Dowódcy', '<mainText><stats><ornnBonus>70 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>300 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>200%</ornnBonus> podstawowej regeneracji many</stats><br><li><passive>Skoordynowany Ogień:</passive> Umiejętności, które <status>spowalniają</status> lub <status>unieruchamiają</status> bohatera, zadają mu dodatkowe obrażenia i oznaczają go. Zadane przez sojusznika obrażenia detonują te oznaczenie, zadając dodatkowe obrażenia i zapewniając wam prędkość ruchu. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Moc umiejętności. <br></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7022.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7023, 'Równonoc', '<mainText><stats><ornnBonus>400 pkt.</ornnBonus> zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności<br><ornnBonus>40 pkt.</ornnBonus> pancerza<br><ornnBonus>40 pkt.</ornnBonus> odporności na magię</stats><br><li><passive>Iskrzenie:</passive> Po <status>unieruchomieniu</status> bohaterów lub gdy bohater sam zostanie <status>unieruchomiony</status>, zwiększa obrażenia otrzymywane przez cel i wszystkich pobliskich wrogich bohaterów.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention> Pancerz i odporność na magię</attention></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7023.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7024, 'Cezura', '<mainText><stats><ornnBonus>90 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>350 pkt.</ornnBonus> zdrowia<br><ornnBonus>800 pkt.</ornnBonus> many<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Boska Osłona:</passive> Zapewnia <keywordMajor>Osłonę</keywordMajor>, która zmniejsza obrażenia otrzymywane od bohaterów. <keywordMajor>Osłona</keywordMajor> utrzymuje się przez 1.5 sek. po otrzymaniu obrażeń od bohaterów. <li><passive>Boski Dar:</passive> Podczas utrzymywania się <keywordMajor>Osłony</keywordMajor> i przez 3 sek. po jej zniszczeniu zyskujesz dodatkową moc umiejętności. <br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom Prędkość ruchu i moc umiejętności.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7024.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7025, 'Lewiatan', '<mainText><stats><ornnBonus>1050 pkt.</ornnBonus> zdrowia<br><ornnBonus>300%</ornnBonus> podstawowej regeneracji zdrowia<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Kolosalna Konsumpcja:</passive> Przygotuj potężny atak przeciwko bohaterowi przez 3 sek., znajdując się w promieniu 700 jedn. od niego. Naładowany atak zadaje dodatkowe obrażenia fizyczne równe 125 pkt. + <scalehealth>6%</scalehealth> twojego maks. zdrowia i zapewnia ci 10% tej wartości w formie trwałego maks. zdrowia. (30 sek.) czasu odnowienia na cel.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention> 1%</attention> więcej zdrowia i <attention>6%</attention> rozmiaru bohatera.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7025.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7026, 'Nieopisany Pasożyt', '<mainText><stats><ornnBonus>550 pkt.</ornnBonus> zdrowia<br><ornnBonus>40 pkt.</ornnBonus> pancerza<br><ornnBonus>40 pkt.</ornnBonus> odporności na magię<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Wytrzymałość Dzieci Pustki:</passive> Za każdą sekundę w walce z bohaterami zyskujesz ładunek zapewniający 2 pkt. <scaleArmor>pancerza</scaleArmor> i <scaleMR>odporności na magię</scaleMR>. Maksymalna liczba ładunków: 8. Po osiągnięciu maksymalnej liczby ładunków przedmiot zostaje wzmocniony, natychmiast czerpiąc zdrowie od pobliskich wrogów, zadając im 0 pkt. obrażeń magicznych i lecząc cię o taką samą wartość, oraz zwiększa twój dodatkowy pancerz i odporność na magię o 20% do końca walki.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>5 pkt.pancerza i odporności na magię</attention>.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7026.png', 3200, 2240);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7027, 'Przedwieczny Brzask', '<mainText><stats><ornnBonus>550 pkt.</ornnBonus> zdrowia<br><ornnBonus>40 pkt.</ornnBonus> pancerza<br><ornnBonus>40 pkt.</ornnBonus> odporności na magię<br><ornnBonus>25 jedn.</ornnBonus> przyspieszenia umiejętności</stats><br><li><passive>Przewodnie Światło:</passive> Po użyciu superumiejętności zyskujesz Transcendencję, zwiększając swoje maks. zdrowie o 10% na 9 sek. Podczas Transcendencji ty i twoi sojusznicy znajdujący się w zasięgu 1200 jedn. zyskujecie 20 jedn. przyspieszenia podstawowych umiejętności i leczycie się o 2% swojego maks. zdrowia co 3 sek. Efekt zostaje zwiększony o do 100% zależnie od brakującego zdrowia bohatera (60sek. czasu odnowienia).<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>100 pkt.</attention> zdrowia.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7027.png', 3000, 2100);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7028, 'Nieskończona Konwergencja', '<mainText><stats><ornnBonus>80 pkt.</ornnBonus> mocy umiejętności<br><ornnBonus>550 pkt.</ornnBonus> zdrowia<br><ornnBonus>550 pkt.</ornnBonus> many</stats><br><br>Przedmiot co 60 sek. zyskuje 20 pkt. zdrowia, 20 pkt. many i 4 pkt. mocy umiejętności, maksymalnie 10 razy. Maksymalnie można zyskać 200 pkt. zdrowia, 200 pkt. many i 40 pkt. mocy umiejętności. Po uzyskaniu maksymalnej liczby ładunków zyskujesz poziom, a wszystkie efekty Wieczności zostają zwiększone o 50%.<br><li><passive>Wieczność:</passive> Przywraca manę równą wartości 7% czystych obrażeń otrzymanych od bohaterów oraz zdrowie równe 25% zużytej many, maks. 20 pkt. zdrowia na użycie, na sekundę. Za każde przywrócone w ten sposób 200 pkt. zdrowia lub many zyskujesz <speed>35% zanikającej prędkości ruchu</speed> na 3 sek.<br><br><rarityMythic>Mityczne bierne:</rarityMythic> Zapewnia wszystkim pozostałym <rarityLegendary>legendarnym</rarityLegendary> przedmiotom <attention>5 jedn. przyspieszenia umiejętności.</attention></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7028.png', 2800, 1960);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(7050, 'Gangplank Placeholder', '', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/7050.png', 0, 0);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(8001, 'Łańcuchy Zguby', '<mainText><stats><attention>650 pkt.</attention> zdrowia<br><attention>20</attention> jedn. przyspieszenia umiejętności</stats><br><br><active>Użycie —</active> <active>Przysięga:</active> Wybierz arcywroga, aby zacząć kumulować ładunki Wendety (90 sek.).<br><li><passive>Wendeta:</passive> Otrzymuj mniejsze obrażenia od swojego arcywroga za każdy ładunek Wendety. Z czasem otrzymujesz kolejne ładunki, aż osiągniesz ich maksymalną liczbę po 60 sekundach.<li><passive>Zemsta:</passive> Jeśli posiadasz maksymalną liczbę ładunków, twój arcywróg ma mniejszą nieustępliwość, gdy znajduje się w pobliżu ciebie.<br><br><rules>Może zostać użyte, gdy bohater jest martwy i ma globalny zasięg. Po wybraniu nowego celu tracisz ładunki. Nie można użyć przez 15 sekund w trakcie walki przeciwko bohaterom.</rules><br><br><flavorText>„Przysięgła, że poświęci swoje życie, by go unicestwić — rękawice jej wysłuchały”.</flavorText></mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/8001.png', 2500, 1750);
INSERT INTO przedmioty(id_przed, nazwa, statystyki, ikona, cena, wartosc_sprzedazy) VALUES(8020, 'Maska Otchłani', '<mainText><stats><attention>500 pkt.</attention> zdrowia<br><attention>300 pkt.</attention> many<br><attention>40 pkt.</attention> odporności na magię<br><attention>10</attention> jedn. przyspieszenia umiejętności</stats><br><li><passive>Wieczność:</passive> Przywraca manę równą wartości 7% czystych obrażeń otrzymanych od bohaterów oraz zdrowie równe 25% zużytej many, maksymalnie 20 pkt. zdrowia na użycie, na sekundę.<li><passive>Zatracenie:</passive> Nakłada <status>klątwę</status> na pobliskich wrogich bohaterów, zmniejszając ich odporność na magię. Za każdego <status>przeklętego</status> wroga zyskujesz odporność na magię.</mainText><br>', 'http://ddragon.leagueoflegends.com/cdn/13.1.1/img/item/8020.png', 3000, 2100);

INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3158, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3006, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3009, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3020, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3047, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3111, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3117, 1001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3114, 1004);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4642, 1004);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3109, 1006);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3801, 1006);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3075, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3084, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3083, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3116, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3143, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3748, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4637, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(8001, 1011);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3124, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6676, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3086, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3031, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3036, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3072, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3095, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3139, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3508, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6671, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6672, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6673, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6675, 1018);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3115, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3116, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6655, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3135, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3152, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3165, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4633, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4637, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6657, 1026);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3024, 1027);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3803, 1027);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3802, 1027);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6035, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6609, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(1011, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3066, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3067, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3803, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3044, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3053, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3211, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3814, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3119, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6664, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6665, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3145, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3165, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3742, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3748, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3801, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4401, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4629, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4635, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6660, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6667, 1028);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(1031, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3082, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3076, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3193, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3191, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3024, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3047, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3105, 1029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3068, 1031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 1031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3742, 1031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6333, 1031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6662, 1031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3091, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(1057, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3193, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3105, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3211, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3111, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3140, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3155, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4632, 1033);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3071, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(1053, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3004, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3179, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3035, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3044, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3046, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3051, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3814, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3123, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3133, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3134, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3155, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6670, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6692, 1036);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6035, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3077, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3091, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6676, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3031, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3053, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3139, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3153, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6029, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3181, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6333, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6671, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6672, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6675, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6695, 1037);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3031, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3072, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3095, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3161, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 1038);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(1043, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3124, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6677, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3085, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(2015, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3086, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3006, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3051, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6670, 1042);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3115, 1043);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3153, 1043);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6616, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3191, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3108, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3113, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3115, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3116, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3145, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3152, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3504, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3802, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4632, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3916, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4630, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4635, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4636, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4637, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4642, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4644, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6656, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6657, 1052);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3072, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3074, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3153, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6673, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6692, 1053);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6664, 1057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3222, 1057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4401, 1057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3003, 1058);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3089, 1058);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 1058);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4645, 1058);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3041, 1082);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3094, 2015);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3095, 2015);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(2033, 2031);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7020, 2065);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(2420, 2419);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 2419);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 2419);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 2420);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 2420);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 2421);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 2421);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3006, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3047, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3020, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3158, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3111, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3117, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3009, 2422);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 2423);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 2423);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 2424);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3026, 2424);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7023, 3001);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3050, 3024);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3110, 3024);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3036, 3035);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6694, 3035);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3053, 3044);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3181, 3044);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3078, 3051);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6631, 3051);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3091, 3051);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3078, 3057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3100, 3057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3508, 3057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6632, 3057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6662, 3057);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3742, 3066);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4401, 3066);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3065, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(2065, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3071, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3084, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3083, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6630, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6617, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3190, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3001, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3003, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3050, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3078, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3107, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3109, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3119, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6664, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6665, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3161, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4005, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4644, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6631, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6632, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6656, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6662, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6667, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(8001, 3067);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3003, 3070);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3004, 3070);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3119, 3070);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3075, 3076);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3074, 3077);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3748, 3077);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7018, 3078);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3110, 3082);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3143, 3082);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7025, 3084);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3085, 3086);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3033, 3086);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3046, 3086);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3094, 3086);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 3086);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3190, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3193, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3001, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6665, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4403, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6667, 3105);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3100, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3102, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6653, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4628, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4629, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4636, 3108);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3100, 3113);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4629, 3113);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6616, 3114);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3107, 3114);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3222, 3114);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3504, 3114);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6609, 3123);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3033, 3123);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6609, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3071, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3004, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6630, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3074, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3142, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3156, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3161, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3508, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6333, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6632, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6675, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6691, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6693, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6694, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6696, 3133);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3142, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6676, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3179, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3814, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6691, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6692, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6693, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6695, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6696, 3134);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6035, 3140);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3139, 3140);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3152, 3145);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4628, 3145);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4636, 3145);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4645, 3145);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7011, 3152);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3156, 3155);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7019, 3190);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3157, 3191);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3065, 3211);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(8020, 3211);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3084, 3801);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3083, 3801);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3109, 3801);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6655, 3802);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6653, 3802);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4644, 3802);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6656, 3802);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(8020, 3803);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6657, 3803);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3011, 3916);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3165, 3916);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7022, 4005);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3135, 4630);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3102, 4632);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7009, 4633);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4633, 4635);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7010, 4636);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4643, 4638);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(2065, 4642);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6617, 4642);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3011, 4642);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(4005, 4642);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7024, 4644);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6630, 6029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6631, 6029);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7021, 6617);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7015, 6630);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7016, 6631);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7017, 6632);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7012, 6653);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7013, 6655);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7014, 6656);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7028, 6657);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3068, 6660);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7005, 6662);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7026, 6665);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7027, 6667);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6671, 6670);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6672, 6670);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(6673, 6670);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7006, 6671);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7007, 6672);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7008, 6673);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(3124, 6677);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7002, 6691);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7001, 6692);
INSERT INTO komponenty_przedmiotow(id_przed, id_komponentu) VALUES(7000, 6693);

INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('AST','Astralis', 'Astralis is a Danish team.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/2/2e/Astralislogo_profile.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('XL','Excel Esports', 'Excel Esports is a British team. Their name was previously stylized exceL eSports and later exceL Esports.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/91/Excel_Esportslogo_square.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('FNC','Fnatic', 'Fnatic is a professional esports organization consisting of players from around the world across a variety of games. On March 14, 2011, Fnatic entered the League of Legends scene with the acquisition of myRevenge. Fnatic is one of the strongest European teams since the early days of competitive League of Legends, having been the champion of the Riot Season 1 Championship.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/f/fc/Fnaticlogo_square.png', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/7/77/FNC_2023_Winter.png');
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('G2','G2 Esports', 'G2 Esports is a European team. They were previously known as Gamers2.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/7/77/G2_Esportslogo_square.png', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/93/G2_2022_Spring.png');
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('KOI','KOI', 'KOI is a Spanish team formed in December 2021, founded by former LVP caster Ibai Llanos, and FC Barcelona''s player Gerard Piqué.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/a/a5/KOI_%28Spanish_Team%29logo_square.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('MAD','MAD Lions', 'MAD Lions is a Spanish team. They were previously known as Splyce. For the LVP SLO team that went by the same name, now known as MAD Lions Madrid, see here. The organization has teams in League of Legends, Clash Royale, CS:GO, and FIFA.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/e5/MAD_Lionslogo_profile.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('SK','SK Gaming', 'SK Gaming is a German team that has been part of the esports community since 1997. The organization entered the League of Legends scene in September 2010.', 'LEC', 'https://cdn.royaleapi.com/static/img/team/logo/sk-gaming.png', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/b/b5/SK_2022_Spring.jpg');
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('BDS','Team BDS', 'Team BDS is a Swiss esports organization, based in Geneva. The team used to compete in the LFL but bought a spot in the LEC in June 2021.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/0/06/Team_BDSlogo_profile.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('HRT','Team Heretics', 'Team Heretics is a Spanish esports organization founded in August 2016 by YouTube user Jorge ''Goorgo'' Orejudo. They first entered the League of Legends scene in January 2017.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/b/bf/Team_Hereticslogo_square.png', NULL);
INSERT INTO druzyny(id_druzyny, nazwa, opis, liga, logo, zdjecie_zawodnikow) VALUES('VIT','Team Vitality', 'Team Vitality is a French team.', 'LEC', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/8/86/Team_Vitalitylogo_square.png', NULL);

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Finn', 'Finn Wiestål', 'Sweden', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/96/XL_Finn_2022_Split_2.png', '1999-06-03', 'AST');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('113', 'Doğukan Balcı', 'Turkey', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/c/ce/KC_113_2022_Split_1.png', '2004-08-12', 'AST');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Dajor', 'Oliver Ryppa', 'Germany', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/eb/AST_Dajor_2022_Split_2.png', '2003-04-18', 'AST');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Kobbe', 'Kasper Kobberup', 'Denmark', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/1/1d/AST_Kobbe_2022_Split_2.png', '1996-09-21', 'AST');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('JeongHoon', 'Lee Jeong-hoon', 'South Korea', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/f/f1/AST_JeongHoon_2022_Split_2.png', '2000-02-22', 'AST');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Odoamne', 'Andrei Pascu', 'Romania', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/1/18/RGE_Odoamne_2022_Split_2.png', '1995-01-18', 'XL');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Xerxe', 'Andrei Dragomir', 'Romania', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/1/14/AST_Xerxe_2022_Split_2.png', '1999-11-05', 'XL');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Vetheo', 'Vincent Berrié', 'France', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/d/d9/MSF_Vetheo_2022_Split_2.png', '2002-07-26', 'XL');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Patrik', 'Patrik Jírů', 'Czech Republic', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/92/XL_Patrik_2022_Split_2.png', '2000-04-07', 'XL');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Targamas', 'Raphaël Crabbé', 'Belgium', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/5/51/G2_Targamas_2022_Split_2.png', '2000-06-30', 'XL');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Wunder', 'Martin Nordahl Hansen', 'Denmark', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/f/f9/FNC_Wunder_2022_Split_2.png', '1998-11-09', 'FNC');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Razork', 'Iván Martín Díaz', 'Spain', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/2/20/FNC_Razork_2022_Split_2.png', '2000-10-07', 'FNC');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Humanoid', 'Marek Brázda', 'Czech Republic', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/97/FNC_Humanoid_2022_Split_2.png', '2000-03-14', 'FNC');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Rekkles', 'Carl Martin Erik Larsson', 'Sweden', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/7/70/KC_Rekkles_2022_Split_2.png', '1996-09-20', 'FNC');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Rhuckz', 'Rúben Barbosa', 'Portugal', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/b/ba/FNTQ_Rhuckz_2022_Split_2.png', '1996-08-28', 'FNC');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('BrokenBlade', 'Sergen Çelik', 'German', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/f/f4/G2_BrokenBlade_2022_Split_2.png', '2000-01-19', 'G2');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Yike', 'Martin Sundelin', 'Sweden', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/8/83/LDLC_Yike_2022_Split_2.png', '2000-11-11', 'G2');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Caps', 'Rasmus Borregaard Winther', 'Denmark', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/8/8c/G2_caPs_2022_Split_2.png', '1999-11-17', 'G2');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Hans sama', 'Steven Liv', 'France', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/d/d4/TL_Hans_sama_2022_Split_2.png', '1999-09-02', 'G2');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Mikyx', 'Mihael Mehle', 'Slovenia', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/ee/XL_Mikyx_2022_Split_2.png', '1998-11-02', 'G2');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Szygenda', 'Mathias Jensen', 'Denmark', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/0/09/VIT.B_Szygenda_2022_Split_2.png', '2001-04-14', 'KOI');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Malrang', 'Kim Geun-seong', 'South Korea', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/e1/RGE_Malrang_2022_Split_2.png', '2000-02-09', 'KOI');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Larssen', 'Emil Larsson', 'Sweden', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/94/RGE_Larssen_2022_Split_2.png', '2000-03-30', 'KOI');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Comp', 'Markos Stamkopoulos (Μάρκος Σταμκόπουλος)', 'Greece', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/1/13/RGE_Comp_2022_Split_2.png', '2001-12-20', 'KOI');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Trymbi', 'Adrian Trybus', 'Poland', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/2/21/RGE_Trymbi_2022_Split_2.png', '2000-10-20', 'KOI');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Chasy', 'Kim Dong-hyeon', 'South Korea', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/f/f0/X7_Chasy_2022_Split_2.png', '2001-04-20', 'MAD');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Elyoya', 'Javier Prades Batalla', 'Spain', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/0/0f/MAD_Elyoya_2022_Split_2.png', '2000-03-13', 'MAD');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Nisqy', 'Yasin Dinçer', 'Belgium', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/6/61/MAD_Nisqy_2022_Split_2.png', '1998-07-28', 'MAD');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Carzzy', 'Matyáš Orság', 'Czech Republic', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/33/VIT_Carzzy_2022_Split_2.png', '2002-01-31', 'MAD');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Hylissang', 'Zdravets Iliev Galabov', 'Bulgaria', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/0/04/FNC_Hylissang_2022_Split_2.png', '1995-04-30', 'MAD');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Irrelevant', 'Joel Miro Scharoll', 'Germany', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/c/c8/MSF_Irrelevant_2022_Split_2.png', '2001-10-22', 'SK');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Markoon', 'Mark van Woensel', 'Netherlands', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/2/2c/XL_Markoon_2022_Split_2.png', '2002-06-28', 'SK');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Sertuss', 'Daniel Gamani', 'Germany', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/2/2f/SK_Sertuss_2022_Split_2.png', '2001-12-23', 'SK');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Exakick', 'Thomas Foucou', 'France', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/39/LDLC_Exakick_2022_Split_2.png', '2003-09-28', 'SK');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Doss', 'Mads Schwartz', 'Denmark', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/a/ac/LDLC_Doss_2022_Split_2.png', '1999-03-19', 'SK');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Adam', 'Adam Maanane', 'France', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/30/BDS.A_Adam_2022_Split_2.png', '2001-12-30', 'BDS');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Sheo', 'Théo Borile', 'France', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/b/b8/BDS.A_Sheo_2022_Split_2.png', '2001-07-05', 'BDS');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('nuc', 'Ilias Bizriken', 'France', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/92/BDS_NUCLEARINT_2022_Split_2.png', '2002-10-17', 'BDS');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Crownie', 'Juš Marušič', 'Slovenia', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/95/BDS.A_Crownie_2022_Split_2.png', '1998-04-17', 'BDS');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Labrov', 'Labros Papoutsakis', 'Greece', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/0/0b/VIT_Labrov_2022_Split_2.png', '2002-02-12', 'BDS');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Evi', 'Shunsuke Murase', 'Japan', 'Top Laner', 'Japan', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/ee/DFM_Evi_2022_Split_1.png', '1995-11-15', 'HRT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Jankos', 'Marcin Jankowski', 'Poland', 'Jungler', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/31/G2_Jankos_2022_Split_2.png', '1995-07-23', 'HRT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Ruby', 'Lee Sol-min', 'South Korea', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/e5/USE_Ruby_2022_Split_1.png', '1998-08-11', 'HRT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Jackspektra', 'Jakob Gullvag Kepple', 'Norway', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/c/cc/HRTS_Jackspektra_2022_Split_2.png', '2000-12-05', 'HRT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Mersa', 'Mertai Sari', 'Greece', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/a/ab/MSF_Mersa_2022_Split_2.png', '2002-08-22', 'HRT');

INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Neon', 'Matúš Jakubčíkć', 'Slovakia', 'Bot Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/1/19/MSF_Neon_2022_Split_2.png', '1998-09-30', 'VIT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Perkz', 'Luka Perković', 'Croatia', 'Mid Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/33/VIT_Perkz_2022_Split_2.png', '1998-09-30', 'VIT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Kaiser', 'Norman Kaiser', 'Germany', 'Support', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/e/e5/MAD_Kaiser_2022_Split_2.png', '1998-11-19', 'VIT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Bo', 'Zhou Yang-Bo', 'China', 'Jungler', 'China', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/3/38/FPX_Bo_2021_Split_1.png', '2002-04-22', 'VIT');
INSERT INTO gracze_zawodowi(nick, imie_i_nazwisko, kraj, rola, rezydencja, zdjecie, data_urodzin, id_druzyny) VALUES('Photon', 'Kyeong Gyu-tae', 'South Korea', 'Top Laner', 'EMEA', 'https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/9/9b/T1.C_Photon_2022_Split_1.png', '2001-11-30', 'VIT');

INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 1, '12-6 RR', 'G2');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 2, '12-6 RR', 'MAD');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 3, '11-7 RR', 'KOI');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 4, '10-8 RR', 'HRT');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 5, '10-8 RR', 'FNC');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 6, '9-9 RR', 'XL');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 7, '9-9 RR', 'VIT');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 8, '7-11 RR', 'SK');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 9, '7-11 RR', 'AST');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer', 'OFFLINE', '2022-08-14', 10, '3-15 RR', 'BDS');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 1, '14-4 RR', 'KOI');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 2, '13-5 RR', 'FNC');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 3, '12-6 RR', 'HRT');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 4, '11-7 RR', 'G2');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 5, '9-9 RR', 'XL');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 6, '9-9 RR', 'VIT');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 7, '8-10 RR', 'MAD');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 8, '7-11 RR', 'SK');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 9, '4-14 RR', 'BDS');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Spring', 'OFFLINE', '2022-03-06', 10, '3-15 RR', 'AST');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 1, '3-0 G2', 'KOI');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 2, '0-3 KOI', 'G2');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 3, '1-3 KOI', 'FNC');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 4, '1-3 FNC', 'MAD');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 5, '0-3 FNC', 'HRT');
INSERT INTO turnieje(nazwa_turnieju, rodzaj, data, zajete_miejsce, ostatni_wynik, id_druzyny) VALUES('LEC 2022 Summer Playoffs', 'OFFLINE', '2022-09-10', 6, '2-3 FNC', 'XL');

INSERT INTO gracze(nick, dywizja, poziom, ulubiony_bohater) VALUES ('Sloik', 'Platinum IV', 200, 'Quinn');
INSERT INTO gracze(nick, dywizja, poziom, ulubiony_bohater) VALUES ('Quavenox', 'Diamond IV', 300, 'Thresh');

INSERT INTO gry(rezultat, zabojstwa, smierci, asysty, creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 5, 192, 9900, '00:28:24', 13300,21,20, 'BLUE', 'Graves');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty, creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 2, 128, 7000, '00:40:19', 3400,14,17, 'RED', 'Bel''Veth');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 1, 163, 8500, '00:40:29', 5700,18,15, 'BLUE', 'Lee Sin');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 3, 9, 263, 14500, '00:46:59', 15800,26,25, 'RED', 'Graves');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 13, 158, 9800, '00:35:41', 8800,28,19, 'RED', 'Sejuani');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 7, 147, 8600, '00:32:08', 8000,23,19, 'BLUE', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 1, 111, 7000, '00:45:18', 4100,15,13, 'RED', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 3, 188, 12200, '00:37:17', 9400,21,25, 'BLUE', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 1, 131, 8600, '00:25:34', 8400,21,15, 'BLUE', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 7, 125, 8700, '00:43:20', 4400,26,25, 'RED', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 3, 7, 192, 12100, '00:20:46', 8100,29,29, 'RED', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 2, 5, 156, 11400, '00:32:41', 6500,20,12, 'BLUE', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 0, 8, 174, 12000, '00:30:07', 14300,27,22, 'RED', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 5, 14, 175, 14000, '00:20:19', 18400,38,36, 'BLUE', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 0, 138, 7200, '00:30:01', 3600,15,11, 'RED', 'Vi');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 0, 16, 199, 12400, '00:30:01', 12700,42,40, 'BLUE', 'Nocturne');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 10, 1, 7, 187, 14500, '00:32:21', 18800,30,29, 'RED', 'Pantheon');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 3, 12, 147, 9700, '00:44:43', 5300,27,25, 'BLUE', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 13, 166, 12400, '00:36:07', 12900,31,25, 'BLUE', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 4, 12, 180, 12300, '00:47:55', 15200,34,37, 'RED', 'Pantheon');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 3, 13, 159, 11500, '00:27:29', 8700,40,39, 'RED', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 1, 138, 7700, '00:21:21', 6700,16,17, 'BLUE', 'Viego');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 10, 165, 11500, '00:32:31', 13200,32,28, 'RED', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 2, 7, 226, 14800, '00:37:42', 18300,35,34, 'RED', 'Xin Zhao');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 3, 190, 12100, '00:29:28', 6800,23,22, 'BLUE', 'Viego');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 7, 2, 8, 204, 13900, '00:43:29', 18300,33,27, 'RED', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 5, 140, 9000, '00:38:19', 7800,22,21, 'BLUE', 'Volibear');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 2, 152, 9000, '00:24:11', 8400,15,18, 'BLUE', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 4, 196, 11400, '00:35:04', 11500,19,13, 'RED', 'Volibear');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 2, 13, 172, 12300, '00:24:34', 16200,36,32, 'RED', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 5, 4, 193, 11200, '00:36:01', 7600,29,32, 'BLUE', 'Vi');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 3, 12, 176, 11800, '00:20:41', 8700,29,25, 'BLUE', 'Volibear');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 11, 182, 11300, '00:20:31', 12300,36,30, 'BLUE', 'Diana');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 1, 13, 195, 12500, '00:44:41', 17000,29,24, 'BLUE', 'Trundle');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 3, 104, 5600, '00:37:53', 6700,19,17, 'BLUE', 'Nocturne');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 4, 2, 145, 9600, '00:27:20', 5300,20,21, 'BLUE', 'Viego');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 6, 112, 6400, '00:22:22', 3300,19,15, 'RED', 'Jarvan IV');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 4, 222, 12100, '00:29:04', 9600,28,28, 'RED', 'Nocturne');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 4, 2, 149, 9300, '00:23:07', 11800,27,22, 'BLUE', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 4, 2, 157, 8300, '00:39:45', 5200,25,21, 'BLUE', 'Graves');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 4, 150, 8800, '00:40:17', 5100,19,17, 'RED', 'Poppy');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 1, 182, 8000, '00:42:00', 2400,18,16, 'RED', 'Viego');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 3, 172, 8500, '00:37:39', 5000,27,28, 'BLUE', 'Viego');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 10, 0, 5, 199, 12300, '00:37:38', 11900,33,28, 'RED', 'Graves');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 2, 9, 194, 12000, '00:45:07', 9000,30,23, 'BLUE', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 7, 191, 12500, '00:44:30', 10500,30,30, 'BLUE', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 8, 1, 7, 250, 15700, '00:42:25', 17700,36,29, 'RED', 'Diana');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 10, 146, 10300, '00:41:45', 8500,37,35, 'RED', 'Sejuani');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 4, 8, 191, 12200, '00:25:15', 10900,29,29, 'BLUE', 'Wukong');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 8, 2, 11, 166, 11700, '00:25:29', 19700,35,29, 'BLUE', 'Nidalee');

INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 1);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 2);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 3);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 4);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 5);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 6);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 7);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 8);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 9);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 10);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 11);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 12);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 13);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 14);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 15);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 16);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 17);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 18);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 19);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 20);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 21);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 22);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 23);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 24);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 25);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 26);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 27);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 28);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 29);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 30);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 31);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 32);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 33);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 34);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 35);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 36);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 37);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 38);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 39);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 40);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 41);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 42);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 43);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 44);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 45);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 46);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 47);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 48);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 49);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Jankos', 50);


INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 4, 1, 201, 9600, '00:23:29', 19400,21,20, 'BLUE', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 0, 189, 8100, '00:41:42', 7700,17,10, 'RED', 'Swain');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 1, 292, 11900, '00:30:45', 12900,22,23, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 3, 7, 296, 14500, '00:39:25', 9900,23,22, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 1, 6, 223, 11600, '00:22:38', 16300,32,24, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 5, 260, 9900, '00:21:37', 9100,19,14, 'BLUE', 'Seraphine');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 2, 2, 229, 9800, '00:37:30', 8500,21,13, 'RED', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 4, 368, 15800, '00:41:52', 19700,30,23, 'BLUE', 'Lissandra');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 2, 282, 11100, '00:36:39', 16300,20,22, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 1, 8, 236, 13100, '00:49:40', 25100,30,24, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 6, 310, 13700, '00:42:51', 21700,21,21, 'RED', 'Varus');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 3, 294, 13700, '00:28:48', 12300,24,24, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 0, 7, 240, 11700, '00:42:45', 8200,29,28, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 4, 17, 373, 18900, '00:35:32', 41800,35,31, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 2, 229, 9500, '00:33:19', 9900,17,11, 'RED', 'Twisted Fate');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 12, 0, 12, 275, 15900, '00:33:41', 34800,36,26, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 0, 3, 14, 275, 13000, '00:24:47', 18700,30,28, 'RED', 'Lissandra');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 8, 0, 6, 272, 14500, '00:30:51', 22800,29,23, 'BLUE', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 1, 9, 305, 15700, '00:44:04', 21000,33,32, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 3, 12, 265, 13700, '00:49:06', 18500,34,34, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 14, 237, 11700, '00:29:38', 15800,32,32, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 6, 2, 202, 8700, '00:47:40', 16500,18,16, 'BLUE', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 4, 6, 264, 12100, '00:45:03', 14200,23,19, 'RED', 'Swain');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 0, 5, 391, 16900, '00:23:04', 16100,24,19, 'RED', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 1, 305, 13600, '00:41:08', 15700,23,19, 'BLUE', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 7, 5, 6, 328, 17300, '00:23:51', 30400,29,29, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 7, 3, 271, 11200, '00:28:18', 26600,23,27, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 1, 1, 374, 15900, '00:25:05', 22700,12,3, 'BLUE', 'Corki');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 7, 5, 278, 15900, '00:24:12', 28600,32,30, 'RED', 'Zoe');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 3, 17, 252, 13200, '00:48:27', 23800,39,34, 'RED', 'Swain');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 8, 6, 4, 301, 15100, '00:26:03', 31100,28,26, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 9, 1, 7, 345, 17000, '00:47:27', 27100,32,25, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 3, 7, 241, 12000, '00:39:58', 11300,28,25, 'BLUE', 'Yasuo');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 2, 4, 262, 14500, '00:33:21', 34400,27,27, 'BLUE', 'Zoe');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 6, 2, 133, 6000, '00:22:36', 9400,18,17, 'BLUE', 'Zoe');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 5, 2, 270, 12100, '00:30:38', 12200,16,14, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 4, 2, 152, 7400, '00:27:50', 5000,24,26, 'RED', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 5, 4, 263, 13500, '00:26:56', 10400,31,35, 'RED', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 1, 214, 8800, '00:42:36', 8400,15,9, 'BLUE', 'Anivia');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 1, 156, 7700, '00:48:47', 6500,26,28, 'BLUE', 'LeBlanc');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 2, 359, 15300, '00:33:46', 11700,18,12, 'RED', 'Corki');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 3, 195, 9100, '00:49:56', 12800,18,21, 'RED', 'LeBlanc');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 2, 3, 225, 10000, '00:32:48', 10600,21,16, 'BLUE', 'LeBlanc');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 9, 2, 8, 215, 12400, '00:41:29', 17900,38,36, 'RED', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 9, 311, 15900, '00:31:17', 18400,37,31, 'BLUE', 'LeBlanc');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 1, 12, 245, 14900, '00:45:59', 20000,42,35, 'BLUE', 'Zoe');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 9, 359, 17600, '00:30:47', 18400,25,26, 'RED', 'Yasuo');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 0, 7, 229, 13400, '00:20:32', 16500,26,25, 'RED', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 2, 5, 320, 15200, '00:43:30', 32600,32,25, 'BLUE', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 3, 16, 150, 10400, '00:43:27', 11200,30,25, 'BLUE', 'Twisted Fate');

INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 51);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 52);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 53);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 54);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 55);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 56);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 57);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 58);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 59);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 60);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 61);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 62);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 63);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 64);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 65);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 66);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 67);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 68);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 69);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 70);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 71);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 72);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 73);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 74);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 75);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 76);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 77);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 78);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 79);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 80);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 81);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 82);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 83);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 84);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 85);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 86);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 87);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 88);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 89);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 90);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 91);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 92);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 93);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 94);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 95);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 96);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 97);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 98);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 99);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Caps', 100);

INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 3, 186, 8900, '00:48:36', 14000,16,12, 'BLUE', 'Maokai');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 5, 214, 9700, '00:20:37', 12600,21,20, 'BLUE', 'Maokai');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 1, 227, 9800, '00:41:38', 13300,15,18, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 1, 184, 8800, '00:35:08', 12700,13,15, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 2, 189, 8000, '00:48:34', 8000,15,15, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 6, 1, 234, 10500, '00:47:38', 11600,15,12, 'RED', 'Rumble');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 4, 7, 256, 12700, '00:42:16', 22700,21,22, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 11, 237, 12000, '00:31:58', 13100,28,28, 'BLUE', 'Maokai');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 5, 289, 14100, '00:40:21', 14200,24,19, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 0, 14, 215, 12900, '00:46:57', 24800,35,26, 'BLUE', 'Maokai');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 1, 3, 232, 11300, '00:42:16', 11300,14,11, 'BLUE', 'Aatrox');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 10, 334, 17500, '00:43:20', 19600,33,26, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 10, 237, 12600, '00:24:26', 14400,26,25, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 13, 268, 14100, '00:34:44', 14900,38,36, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 8, 283, 13800, '00:41:15', 13000,30,28, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 0, 4, 292, 15500, '00:30:32', 15100,23,22, 'BLUE', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 1, 236, 9900, '00:27:50', 12700,16,17, 'BLUE', 'Aatrox');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 4, 184, 7400, '00:40:15', 9300,29,23, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 4, 321, 13600, '00:43:04', 12600,16,13, 'BLUE', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 4, 237, 9800, '00:44:23', 9100,23,23, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 4, 6, 271, 15800, '00:47:55', 21100,24,24, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 10, 178, 10100, '00:30:52', 11000,28,22, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 2, 253, 10100, '00:25:30', 8200,19,21, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 2, 6, 290, 15200, '00:49:29', 12800,28,26, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 4, 297, 13400, '00:48:18', 11400,20,18, 'BLUE', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 12, 249, 11800, '00:35:30', 10300,35,33, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 3, 260, 11500, '00:46:28', 21500,20,19, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 0, 12, 280, 14500, '00:40:49', 19400,31,21, 'BLUE', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 1, 0, 258, 11800, '00:47:40', 13600,20,15, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 3, 323, 14100, '00:41:26', 16700,24,17, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 6, 3, 244, 10500, '00:34:33', 12100,23,26, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 6, 4, 7, 369, 19600, '00:31:51', 29500,33,33, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 1, 296, 13400, '00:39:37', 18100,16,15, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 6, 363, 19200, '00:31:26', 37600,26,24, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 0, 11, 284, 13400, '00:39:20', 16600,27,17, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 0, 6, 279, 12600, '00:43:28', 10100,25,18, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 6, 236, 12600, '00:35:41', 20300,22,20, 'BLUE', 'Zac');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 7, 302, 15900, '00:40:08', 18800,24,16, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 6, 284, 15000, '00:37:00', 24900,29,29, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 9, 1, 5, 331, 19500, '00:43:46', 27000,29,21, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 0, 4, 4, 258, 12600, '00:34:30', 18900,24,19, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 2, 176, 7800, '00:24:44', 9800,19,15, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 3, 251, 10600, '00:43:57', 12500,26,22, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 4, 296, 14800, '00:27:43', 26100,26,30, 'RED', 'Jayce');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 5, 285, 13200, '00:37:43', 18200,19,14, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 4, 4, 249, 12000, '00:47:25', 20200,23,19, 'BLUE', 'Rumble');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 0, 6, 183, 9800, '00:29:21', 11400,23,15, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 0, 11, 181, 9200, '00:45:14', 8700,32,31, 'RED', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 4, 13, 246, 12600, '00:29:50', 22000,31,32, 'RED', 'Jayce');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 5, 1, 254, 12000, '00:30:57', 13200,20,19, 'BLUE', 'Gnar');

INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 101);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 102);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 103);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 104);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 105);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 106);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 107);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 108);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 109);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 110);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 111);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 112);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 113);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 114);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 115);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 116);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 117);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 118);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 119);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 120);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 121);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 122);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 123);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 124);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 125);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 126);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 127);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 128);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 129);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 130);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 131);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 132);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 133);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 134);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 135);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 136);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 137);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 138);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 139);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 140);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 141);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 142);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 143);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 144);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 145);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 146);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 147);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 148);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 149);
INSERT INTO graczezawodowi_gry(gracze_zawodowi_nick, gry_id_meczu) VALUES('Odoamne', 150);
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 4, 325, 15400, '00:42:51', 22500,26,29, 'BLUE', 'Viktor');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 0, 236, 9300, '00:47:20', 9000,13,8, 'RED', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 5, 1, 252, 12700, '00:34:12', 21800,19,14, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 5, 2, 406, 19100, '00:37:37', 43900,23,27, 'RED', 'Viktor');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 1, 4, 306, 15000, '00:22:41', 26000,28,28, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 11, 205, 10900, '00:34:07', 19800,31,30, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 3, 5, 284, 14600, '00:31:17', 20200,27,26, 'RED', 'Ryze');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 0, 3, 6, 293, 14300, '00:45:51', 17900,27,21, 'BLUE', 'Ryze');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 6, 263, 13200, '00:45:09', 19900,22,21, 'BLUE', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 3, 7, 193, 11100, '00:23:55', 20300,34,27, 'RED', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 6, 329, 16600, '00:26:37', 26300,29,25, 'RED', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 7, 326, 15800, '00:32:42', 24400,28,24, 'BLUE', 'Viktor');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 3, 15, 208, 12600, '00:36:25', 30100,36,30, 'RED', 'Viktor');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 3, 5, 156, 8500, '00:47:49', 10000,25,21, 'BLUE', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 3, 1, 182, 11400, '00:47:05', 13600,23,22, 'BLUE', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 0, 1, 9, 200, 9000, '00:40:49', 7000,24,22, 'RED', 'Lissandra');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 0, 202, 9100, '00:24:01', 11600,13,15, 'RED', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 7, 1, 7, 169, 9700, '00:27:57', 12700,33,32, 'BLUE', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 2, 273, 11800, '00:38:09', 6400,16,16, 'RED', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 0, 216, 8600, '00:41:39', 8000,16,12, 'BLUE', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 4, 4, 315, 14100, '00:45:40', 13100,26,25, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 1, 6, 338, 15300, '00:39:06', 7300,30,25, 'BLUE', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 3, 258, 12100, '00:33:58', 13800,22,18, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 6, 326, 13400, '00:27:34', 16000,28,26, 'RED', 'Lissandra');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 2, 7, 203, 10600, '00:44:08', 11700,26,25, 'RED', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 1, 7, 235, 11800, '00:44:30', 19800,34,33, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 10, 233, 12800, '00:24:57', 23200,34,32, 'RED', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 0, 9, 306, 14900, '00:29:57', 21800,29,25, 'BLUE', 'Ahri');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 4, 4, 165, 7600, '00:34:10', 9800,25,22, 'BLUE', 'Swain');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 2, 2, 284, 12500, '00:20:01', 17100,26,27, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 15, 308, 15700, '00:40:22', 23800,41,42, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 1, 293, 13000, '00:45:31', 20000,21,21, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 1, 7, 286, 15200, '00:41:44', 26900,27,20, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 2, 7, 277, 12900, '00:30:47', 17800,28,21, 'RED', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 12, 304, 14000, '00:22:43', 11600,33,29, 'BLUE', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 2, 2, 215, 9200, '00:36:31', 15300,14,12, 'BLUE', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 1, 5, 254, 12100, '00:26:34', 10200,21,12, 'BLUE', 'Twisted Fate');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 2, 11, 293, 13300, '00:24:51', 19400,27,26, 'BLUE', 'Orianna');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 4, 234, 10700, '00:37:52', 9500,21,17, 'RED', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 4, 251, 11500, '00:26:47', 7300,19,19, 'BLUE', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 13, 255, 13100, '00:22:53', 14100,31,25, 'RED', 'Galio');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 2, 4, 298, 14700, '00:25:08', 21600,23,19, 'BLUE', 'Sylas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 3, 1, 312, 13400, '00:37:11', 16500,23,19, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 7, 375, 17400, '00:46:44', 20900,23,14, 'BLUE', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 4, 307, 14700, '00:22:57', 13000,26,23, 'BLUE', 'Taliyah');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 1, 269, 10800, '00:27:36', 12000,16,9, 'BLUE', 'Lissandra');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 1, 7, 311, 15900, '00:20:37', 28900,29,21, 'RED', 'Azir');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 10, 229, 10500, '00:40:06', 18200,26,19, 'RED', 'Seraphine');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 3, 344, 17000, '00:43:15', 21700,21,19, 'BLUE', 'Corki');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 3, 344, 17000, '00:43:15', 21700,17,17, 'BLUE', 'Corki');

INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 151);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 152);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 153);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 154);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 155);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 156);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 157);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 158);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 159);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 160);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 161);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 162);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 163);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 164);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 165);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 166);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 167);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 168);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 169);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 170);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 171);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 172);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 173);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 174);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 175);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 176);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 177);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 178);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 179);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 180);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 181);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 182);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 183);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 184);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 185);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 186);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 187);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 188);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 189);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 190);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 191);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 192);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 193);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 194);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 195);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 196);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 197);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 198);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 199);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Sloik', 200);
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 4, 3, 292, 15600, '00:46:45', 27500,25,26, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 2, 1, 237, 11300, '00:35:59', 10300,18,16, 'RED', 'Fiora');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 1, 7, 150, 10800, '00:39:31', 15800,24,18, 'BLUE', 'Gragas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 3, 5, 5, 328, 16300, '00:22:53', 20800,22,22, 'RED', 'Aatrox');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 5, 274, 14200, '00:28:47', 18700,28,26, 'BLUE', 'Yone');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 16, 147, 9100, '00:44:39', 12600,33,31, 'RED', 'Gragas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 5, 13, 211, 15200, '00:31:04', 30000,32,28, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 6, 3, 6, 290, 15100, '00:28:26', 20200,28,21, 'BLUE', 'Yone');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 6, 288, 13900, '00:47:08', 13700,23,23, 'BLUE', 'Camille');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 8, 4, 7, 220, 13100, '00:21:52', 20700,29,32, 'RED', 'Yone');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 0, 8, 10, 318, 15300, '00:30:21', 30500,28,26, 'RED', 'Jayce');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 2, 7, 336, 18300, '00:35:19', 21600,28,24, 'BLUE', 'Camille');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 10, 2, 4, 266, 16100, '00:23:38', 28900,29,21, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 5, 5, 189, 10300, '00:38:30', 18800,27,27, 'BLUE', 'Jayce');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 3, 3, 266, 12800, '00:37:49', 20000,20,19, 'BLUE', 'Yone');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 9, 218, 11600, '00:20:52', 16900,28,20, 'RED', 'Aatrox');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 5, 200, 10300, '00:40:34', 10400,21,21, 'RED', 'Jax');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 7, 179, 10300, '00:49:54', 14100,31,27, 'BLUE', 'Fiora');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 1, 233, 10700, '00:20:22', 12700,16,13, 'RED', 'Mordekaiser');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 2, 207, 8100, '00:47:06', 14300,18,19, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 4, 4, 256, 11500, '00:34:33', 8800,17,19, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 0, 5, 322, 15500, '00:46:11', 10500,23,18, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 4, 5, 1, 263, 13000, '00:47:12', 11800,22,24, 'BLUE', 'Camille');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 5, 1, 0, 338, 15200, '00:27:32', 14900,20,15, 'RED', 'Aatrox');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 6, 211, 11800, '00:32:40', 16400,23,21, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 5, 12, 161, 8500, '00:39:20', 15900,23,21, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 4, 1, 10, 221, 12700, '00:37:28', 17000,29,20, 'RED', 'Gragas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 12, 244, 11700, '00:29:01', 15800,25,25, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 2, 5, 2, 145, 7800, '00:21:14', 14500,18,13, 'BLUE', 'Sejuani');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 5, 159, 8200, '00:49:36', 11800,18,13, 'RED', 'Sejuani');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 5, 10, 174, 10700, '00:45:04', 14700,24,19, 'BLUE', 'Zac');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 6, 1, 266, 12000, '00:44:05', 18900,15,16, 'RED', 'Renekton');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 2, 5, 237, 10900, '00:26:31', 9000,22,16, 'RED', 'Camille');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 0, 17, 206, 11000, '00:30:04', 15400,31,30, 'RED', 'Sejuani');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 8, 1, 6, 325, 16300, '00:30:53', 22200,36,34, 'BLUE', 'Akali');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 1, 160, 7000, '00:34:46', 8000,17,16, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 3, 1, 312, 12600, '00:35:58', 12800,18,19, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 4, 8, 175, 10300, '00:47:39', 12800,33,27, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 1, 5, 3, 275, 14000, '00:35:54', 20000,20,17, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 1, 4, 276, 15000, '00:23:35', 18900,24,24, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 10, 0, 4, 338, 21100, '00:28:37', 35100,27,22, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 3, 7, 251, 13900, '00:33:38', 16000,31,25, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 3, 2, 272, 12500, '00:30:31', 14400,17,15, 'RED', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 3, 6, 160, 11100, '00:35:51', 12200,22,20, 'BLUE', 'Gragas');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 3, 1, 8, 221, 12400, '00:47:37', 16400,31,26, 'BLUE', 'Ornn');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('LOSE', 0, 5, 2, 268, 12600, '00:49:52', 16400,23,25, 'BLUE', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 2, 2, 8, 310, 15700, '00:23:27', 25000,22,20, 'RED', 'Gangplank');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 5, 0, 5, 264, 13000, '00:37:58', 22000,28,27, 'RED', 'Gnar');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 1, 2, 275, 11600, '00:30:09', 10600,18,17, 'BLUE', 'Gwen');
INSERT INTO gry(rezultat, zabojstwa, smierci, asysty,creep_score, zdobyte_zloto, czas_gry, zadane_obrazenia,zabojstwa_druzyny,zgony_druzyny, strona, bohaterowie_nazwa)VALUES ('WIN', 1, 1, 2, 275, 11600, '00:30:09', 10600,15,12, 'BLUE', 'Gwen');

INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 201);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 202);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 203);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 204);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 205);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 206);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 207);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 208);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 209);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 210);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 211);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 212);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 213);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 214);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 215);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 216);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 217);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 218);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 219);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 220);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 221);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 222);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 223);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 224);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 225);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 226);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 227);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 228);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 229);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 230);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 231);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 232);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 233);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 234);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 235);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 236);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 237);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 238);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 239);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 240);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 241);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 242);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 243);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 244);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 245);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 246);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 247);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 248);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 249);
INSERT INTO gracze_gry(gracze_nick, gry_id_meczu) VALUES('Quavenox', 250);

INSERT INTO dane_logowania(nick, haslo, rola) VALUES('Quavenox', 'admin', 'Administrator');
INSERT INTO dane_logowania(nick, haslo, rola) VALUES('Sloik', 'user', 'User');

EXEC dodaj_przedmiot_do_gry 1, 'Widmowe Ostrze Youmuu'
EXEC dodaj_przedmiot_do_gry 1, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 1, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 1, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 1, 'Widmowy Sierp'
EXEC dodaj_przedmiot_do_gry 1, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 2, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 2, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 2, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 2, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 2, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 2, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 3, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 3, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 3, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 3, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 3, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 3, 'Manamune'
EXEC dodaj_przedmiot_do_gry 4, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 4, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 4, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 4, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 4, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 4, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 5, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 5, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 5, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 5, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 5, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 5, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 6, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 6, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 6, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 6, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 6, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 6, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 7, 'Eteryczny Duszek'
EXEC dodaj_przedmiot_do_gry 7, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 7, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 7, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 7, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 7, 'Klepsydra Zhonyi'
EXEC dodaj_przedmiot_do_gry 8, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 8, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 8, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 8, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 8, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 8, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 9, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 9, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 9, 'Lament Liandry''ego'
EXEC dodaj_przedmiot_do_gry 9, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 9, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 9, 'Lament Liandry''ego'
EXEC dodaj_przedmiot_do_gry 10, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 10, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 10, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 10, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 10, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 10, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 11, 'Całun Banshee'
EXEC dodaj_przedmiot_do_gry 11, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 11, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 11, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 11, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 11, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 12, 'Wysysające Spojrzenie'
EXEC dodaj_przedmiot_do_gry 12, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 12, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 12, 'Blask'
EXEC dodaj_przedmiot_do_gry 12, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 12, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 13, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 13, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 13, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 13, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 13, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 13, 'Cezura'
EXEC dodaj_przedmiot_do_gry 14, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 14, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 14, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 14, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 14, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 14, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 15, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 15, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 15, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 15, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 15, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 15, 'Chempunkowy Łańcuchowy Miecz'
EXEC dodaj_przedmiot_do_gry 16, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 16, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 16, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 16, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 16, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 16, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 17, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 17, 'Miotacz Gwiazd'
EXEC dodaj_przedmiot_do_gry 17, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 17, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 17, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 17, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 18, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 18, 'Lament Liandry''ego'
EXEC dodaj_przedmiot_do_gry 18, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 18, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 18, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 18, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 19, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 19, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 19, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 19, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 19, 'Muramana'
EXEC dodaj_przedmiot_do_gry 19, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 20, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 20, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 20, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 20, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 20, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 20, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 21, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 21, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 21, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 21, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 21, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 21, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 22, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 22, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 22, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 22, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 22, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 22, 'Przedwieczny Brzask'
EXEC dodaj_przedmiot_do_gry 23, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 23, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 23, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 23, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 23, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 23, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 24, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 24, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 24, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 24, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 24, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 24, 'Klepsydra Zhonyi'
EXEC dodaj_przedmiot_do_gry 25, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 25, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 25, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 25, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 25, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 25, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 26, 'Przedwieczny Brzask'
EXEC dodaj_przedmiot_do_gry 26, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 26, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 26, 'Eteryczny Duszek'
EXEC dodaj_przedmiot_do_gry 26, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 26, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 27, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 27, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 27, 'Przedwieczny Brzask'
EXEC dodaj_przedmiot_do_gry 27, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 27, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 27, 'Hextechowy Pas Rakietowy'
EXEC dodaj_przedmiot_do_gry 28, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 28, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 28, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 28, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 28, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 28, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 29, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 29, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 29, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 29, 'Siła Natury'
EXEC dodaj_przedmiot_do_gry 29, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 29, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 30, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 30, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 30, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 30, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 30, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 30, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 31, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 31, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 31, 'Widmowy Sierp'
EXEC dodaj_przedmiot_do_gry 31, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 31, 'Zapał'
EXEC dodaj_przedmiot_do_gry 31, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 32, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 32, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 32, 'Mroźny Puklerz'
EXEC dodaj_przedmiot_do_gry 32, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 32, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 32, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 33, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 33, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 33, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 33, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 33, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 33, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 34, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 34, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 34, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 34, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 34, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 34, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 35, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 35, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 35, 'Wysysające Spojrzenie'
EXEC dodaj_przedmiot_do_gry 35, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 35, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 35, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 36, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 36, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 36, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 36, 'Słoneczna Egida'
EXEC dodaj_przedmiot_do_gry 36, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 36, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 37, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 37, 'Miotacz Gwiazd'
EXEC dodaj_przedmiot_do_gry 37, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 37, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 37, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 37, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 38, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 38, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 38, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 38, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 38, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 38, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 39, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 39, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 39, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 39, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 39, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 39, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 40, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 40, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 40, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 40, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 40, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 40, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 41, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 41, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 41, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 41, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 41, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 41, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 42, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 42, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 42, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 42, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 42, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 42, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 43, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 43, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 43, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 43, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 43, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 43, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 44, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 44, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 44, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 44, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 44, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 44, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 45, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 45, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 45, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 45, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 45, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 45, 'Uścisk Serafina'
EXEC dodaj_przedmiot_do_gry 46, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 46, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 46, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 46, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 46, 'Pasjonujący Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 46, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 47, 'Nieopisany Pasożyt'
EXEC dodaj_przedmiot_do_gry 47, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 47, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 47, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 47, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 47, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 48, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 48, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 48, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 48, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 48, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 48, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 49, 'Pasjonujący Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 49, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 49, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 49, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 49, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 49, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 50, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 50, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 50, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 50, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 50, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 50, 'Oko Luden'
EXEC dodaj_przedmiot_do_gry 51, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 51, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 51, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 51, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 51, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 51, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 52, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 52, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 52, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 52, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 52, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 52, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 53, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 53, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 53, 'Mroczne Ostrze Draktharru'
EXEC dodaj_przedmiot_do_gry 53, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 53, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 53, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 54, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 54, 'Klepsydra Zhonyi'
EXEC dodaj_przedmiot_do_gry 54, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 54, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 54, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 54, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 55, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 55, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 55, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 55, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 55, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 55, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 56, 'Oko Luden'
EXEC dodaj_przedmiot_do_gry 56, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 56, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 56, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 56, 'Buty Prędkości'
EXEC dodaj_przedmiot_do_gry 56, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 57, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 57, 'Buty Prędkości'
EXEC dodaj_przedmiot_do_gry 57, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 57, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 57, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 57, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 58, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 58, 'Manamune'
EXEC dodaj_przedmiot_do_gry 58, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 58, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 58, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 58, 'Widmowy Sierp'
EXEC dodaj_przedmiot_do_gry 59, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 59, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 59, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 59, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 59, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 59, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 60, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 60, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 60, 'Muramana'
EXEC dodaj_przedmiot_do_gry 60, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 60, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 60, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 61, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 61, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 61, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 61, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 61, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 61, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 62, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 62, 'Vesperiański Przypływ'
EXEC dodaj_przedmiot_do_gry 62, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 62, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 62, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 62, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 63, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 63, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 63, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 63, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 63, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 63, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 64, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 64, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 64, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 64, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 64, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 64, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 65, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 65, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 65, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 65, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 65, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 65, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 66, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 66, 'Mroźny Puklerz'
EXEC dodaj_przedmiot_do_gry 66, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 66, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 66, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 66, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 67, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 67, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 67, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 67, 'Żelazny Bicz'
EXEC dodaj_przedmiot_do_gry 67, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 67, 'Chemtechowy Skaziciel'
EXEC dodaj_przedmiot_do_gry 68, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 68, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 68, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 68, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 68, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 68, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 69, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 69, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 69, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 69, 'Egida Legionu'
EXEC dodaj_przedmiot_do_gry 69, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 69, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 70, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 70, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 70, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 70, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 70, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 70, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 71, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 71, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 71, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 71, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 71, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 71, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 72, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 72, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 72, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 72, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 72, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 72, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 73, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 73, 'Wysysające Spojrzenie'
EXEC dodaj_przedmiot_do_gry 73, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 73, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 73, 'Cezura'
EXEC dodaj_przedmiot_do_gry 73, 'Muramana'
EXEC dodaj_przedmiot_do_gry 74, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 74, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 74, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 74, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 74, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 74, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 75, 'Całun Banshee'
EXEC dodaj_przedmiot_do_gry 75, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 75, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 75, 'Żelazny Bicz'
EXEC dodaj_przedmiot_do_gry 75, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 75, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 76, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 76, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 76, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 76, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 76, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 76, 'Siedzisko Dowódcy'
EXEC dodaj_przedmiot_do_gry 77, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 77, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 77, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 77, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 77, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 77, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 78, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 78, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 78, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 78, 'Całun Banshee'
EXEC dodaj_przedmiot_do_gry 78, 'Bastion Góry'
EXEC dodaj_przedmiot_do_gry 78, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 79, 'Pasjonujący Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 79, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 79, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 79, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 79, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 79, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 80, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 80, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 80, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 80, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 80, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 80, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 81, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 81, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 81, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 81, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 81, 'Chempunkowy Łańcuchowy Miecz'
EXEC dodaj_przedmiot_do_gry 81, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 82, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 82, 'Oko Herolda'
EXEC dodaj_przedmiot_do_gry 82, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 82, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 82, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 82, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 83, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 83, 'Widmowe Ostrze Youmuu'
EXEC dodaj_przedmiot_do_gry 83, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 83, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 83, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 83, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 84, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 84, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 84, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 84, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 84, 'Całun Banshee'
EXEC dodaj_przedmiot_do_gry 84, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 85, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 85, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 85, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 85, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 85, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 85, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 86, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 86, 'Uścisk Serafina'
EXEC dodaj_przedmiot_do_gry 86, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 86, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 86, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 86, 'Mroczne Ostrze Draktharru'
EXEC dodaj_przedmiot_do_gry 87, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 87, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 87, 'Żelazny Bicz'
EXEC dodaj_przedmiot_do_gry 87, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 87, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 87, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 88, 'Siła Natury'
EXEC dodaj_przedmiot_do_gry 88, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 88, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 88, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 88, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 88, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 89, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 89, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 89, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 89, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 89, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 89, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 90, 'Roślinna Bariera'
EXEC dodaj_przedmiot_do_gry 90, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 90, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 90, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 90, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 90, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 91, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 91, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 91, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 91, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 91, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 91, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 92, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 92, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 92, 'Płomień Cienia'
EXEC dodaj_przedmiot_do_gry 92, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 92, 'Mroźny Puklerz'
EXEC dodaj_przedmiot_do_gry 92, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 93, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 93, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 93, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 93, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 93, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 93, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 94, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 94, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 94, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 94, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 94, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 94, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 95, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 95, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 95, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 95, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 95, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 95, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 96, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 96, 'Vesperiański Przypływ'
EXEC dodaj_przedmiot_do_gry 96, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 96, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 96, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 96, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 97, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 97, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 97, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 97, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 97, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 97, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 98, 'Blask'
EXEC dodaj_przedmiot_do_gry 98, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 98, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 98, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 98, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 98, 'Bogobójca'
EXEC dodaj_przedmiot_do_gry 99, 'Muramana'
EXEC dodaj_przedmiot_do_gry 99, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 99, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 99, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 99, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 99, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 100, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 100, 'Przedwieczny Brzask'
EXEC dodaj_przedmiot_do_gry 100, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 100, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 100, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 100, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 101, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 101, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 101, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 101, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 101, 'Siedzisko Dowódcy'
EXEC dodaj_przedmiot_do_gry 101, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 102, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 102, 'Zapał'
EXEC dodaj_przedmiot_do_gry 102, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 102, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 102, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 102, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 103, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 103, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 103, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 103, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 103, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 103, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 104, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 104, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 104, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 104, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 104, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 104, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 105, 'Glewia Umbry'
EXEC dodaj_przedmiot_do_gry 105, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 105, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 105, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 105, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 105, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 106, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 106, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 106, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 106, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 106, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 106, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 107, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 107, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 107, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 107, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 107, 'Cezura'
EXEC dodaj_przedmiot_do_gry 107, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 108, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 108, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 108, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 108, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 108, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 108, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 109, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 109, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 109, 'Eteryczny Duszek'
EXEC dodaj_przedmiot_do_gry 109, 'Pasjonujący Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 109, 'Roślinna Bariera'
EXEC dodaj_przedmiot_do_gry 109, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 110, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 110, 'Oko Herolda'
EXEC dodaj_przedmiot_do_gry 110, 'Mroczne Ostrze Draktharru'
EXEC dodaj_przedmiot_do_gry 110, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 110, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 110, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 111, 'Vesperiański Przypływ'
EXEC dodaj_przedmiot_do_gry 111, 'Zapał'
EXEC dodaj_przedmiot_do_gry 111, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 111, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 111, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 111, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 112, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 112, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 112, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 112, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 112, 'Widmowy Sierp'
EXEC dodaj_przedmiot_do_gry 112, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 113, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 113, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 113, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 113, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 113, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 113, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 114, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 114, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 114, 'Eteryczny Duszek'
EXEC dodaj_przedmiot_do_gry 114, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 114, 'Cezura'
EXEC dodaj_przedmiot_do_gry 114, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 115, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 115, 'Łańcuchy Zguby'
EXEC dodaj_przedmiot_do_gry 115, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 115, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 115, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 115, 'Muramana'
EXEC dodaj_przedmiot_do_gry 116, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 116, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 116, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 116, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 116, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 116, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 117, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 117, 'Miotacz Gwiazd'
EXEC dodaj_przedmiot_do_gry 117, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 117, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 117, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 117, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 118, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 118, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 118, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 118, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 118, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 118, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 119, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 119, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 119, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 119, 'Żelazny Bicz'
EXEC dodaj_przedmiot_do_gry 119, 'Łza Bogini'
EXEC dodaj_przedmiot_do_gry 119, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 120, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 120, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 120, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 120, 'Nieopisany Pasożyt'
EXEC dodaj_przedmiot_do_gry 120, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 120, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 121, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 121, 'Manamune'
EXEC dodaj_przedmiot_do_gry 121, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 121, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 121, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 121, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 122, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 122, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 122, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 122, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 122, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 122, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 123, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 123, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 123, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 123, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 123, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 123, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 124, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 124, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 124, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 124, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 124, 'Siedzisko Dowódcy'
EXEC dodaj_przedmiot_do_gry 124, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 125, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 125, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 125, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 125, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 125, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 125, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 126, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 126, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 126, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 126, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 126, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 126, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 127, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 127, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 127, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 127, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 127, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 127, 'Kosmiczny Impuls'
EXEC dodaj_przedmiot_do_gry 128, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 128, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 128, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 128, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 128, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 128, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 129, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 129, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 129, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 129, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 129, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 129, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 130, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 130, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 130, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 130, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 130, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 130, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 131, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 131, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 131, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 131, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 131, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 131, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 132, 'Łza Bogini'
EXEC dodaj_przedmiot_do_gry 132, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 132, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 132, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 132, 'Muramana'
EXEC dodaj_przedmiot_do_gry 132, 'Cezura'
EXEC dodaj_przedmiot_do_gry 133, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 133, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 133, 'Muramana'
EXEC dodaj_przedmiot_do_gry 133, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 133, 'Skrzydlaty Księżycowy Pancerz'
EXEC dodaj_przedmiot_do_gry 133, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 134, 'Lament Liandry''ego'
EXEC dodaj_przedmiot_do_gry 134, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 134, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 134, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 134, 'Egida Legionu'
EXEC dodaj_przedmiot_do_gry 134, 'Kosmiczny Impuls'
EXEC dodaj_przedmiot_do_gry 135, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 135, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 135, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 135, 'Słoneczna Egida'
EXEC dodaj_przedmiot_do_gry 135, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 135, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 136, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 136, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 136, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 136, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 136, 'Oko Herolda'
EXEC dodaj_przedmiot_do_gry 136, 'Cezura'
EXEC dodaj_przedmiot_do_gry 137, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 137, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 137, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 137, 'Nieopisany Pasożyt'
EXEC dodaj_przedmiot_do_gry 137, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 137, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 138, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 138, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 138, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 138, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 138, 'Nieopisany Pasożyt'
EXEC dodaj_przedmiot_do_gry 138, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 139, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 139, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 139, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 139, 'Blask'
EXEC dodaj_przedmiot_do_gry 139, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 139, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 140, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 140, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 140, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 140, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 140, 'Widmowe Ostrze Youmuu'
EXEC dodaj_przedmiot_do_gry 140, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 141, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 141, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 141, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 141, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 141, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 141, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 142, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 142, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 142, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 142, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 142, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 142, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 143, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 143, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 143, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 143, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 143, 'Uścisk Serafina'
EXEC dodaj_przedmiot_do_gry 143, 'Muramana'
EXEC dodaj_przedmiot_do_gry 144, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 144, 'Buty Prędkości'
EXEC dodaj_przedmiot_do_gry 144, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 144, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 144, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 144, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 145, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 145, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 145, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 145, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 145, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 145, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 146, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 146, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 146, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 146, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 146, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 146, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 147, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 147, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 147, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 147, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 147, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 147, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 148, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 148, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 148, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 148, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 148, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 148, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 149, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 149, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 149, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 149, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 149, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 149, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 150, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 150, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 150, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 150, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 150, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 150, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 151, 'Blask'
EXEC dodaj_przedmiot_do_gry 151, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 151, 'Eteryczny Duszek'
EXEC dodaj_przedmiot_do_gry 151, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 151, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 151, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 152, 'Syzygium'
EXEC dodaj_przedmiot_do_gry 152, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 152, 'Cezura'
EXEC dodaj_przedmiot_do_gry 152, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 152, 'Uścisk Serafina'
EXEC dodaj_przedmiot_do_gry 152, 'Hextechowy Pas Rakietowy'
EXEC dodaj_przedmiot_do_gry 153, 'Buty Prędkości'
EXEC dodaj_przedmiot_do_gry 153, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 153, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 153, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 153, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 153, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 154, 'Zamarznięta Pięść'
EXEC dodaj_przedmiot_do_gry 154, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 154, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 154, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 154, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 154, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 155, 'Blask'
EXEC dodaj_przedmiot_do_gry 155, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 155, 'Kosmiczny Impuls'
EXEC dodaj_przedmiot_do_gry 155, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 155, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 155, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 156, 'Siła Natury'
EXEC dodaj_przedmiot_do_gry 156, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 156, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 156, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 156, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 156, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 157, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 157, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 157, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 157, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 157, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 157, 'Roślinna Bariera'
EXEC dodaj_przedmiot_do_gry 158, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 158, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 158, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 158, 'Wieczna Zima'
EXEC dodaj_przedmiot_do_gry 158, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 158, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 159, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 159, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 159, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 159, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 159, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 159, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 160, 'Kostur Pustki'
EXEC dodaj_przedmiot_do_gry 160, 'Łza Bogini'
EXEC dodaj_przedmiot_do_gry 160, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 160, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 160, 'Soczewka Wyroczni'
EXEC dodaj_przedmiot_do_gry 160, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 161, 'Egida Legionu'
EXEC dodaj_przedmiot_do_gry 161, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 161, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 161, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 161, 'Płomień Cienia'
EXEC dodaj_przedmiot_do_gry 161, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 162, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 162, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 162, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 162, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 162, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 162, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 163, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 163, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 163, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 163, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 163, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 163, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 164, 'Oko Luden'
EXEC dodaj_przedmiot_do_gry 164, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 164, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 164, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 164, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 164, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 165, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 165, 'Oko Herolda'
EXEC dodaj_przedmiot_do_gry 165, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 165, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 165, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 165, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 166, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 166, 'Kołczan Południa'
EXEC dodaj_przedmiot_do_gry 166, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 166, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 166, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 166, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 167, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 167, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 167, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 167, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 167, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 167, 'Bogobójca'
EXEC dodaj_przedmiot_do_gry 168, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 168, 'Mroczne Ostrze Draktharru'
EXEC dodaj_przedmiot_do_gry 168, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 168, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 168, 'Uścisk Serafina'
EXEC dodaj_przedmiot_do_gry 168, 'Kamizelka Cierniowa'
EXEC dodaj_przedmiot_do_gry 169, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 169, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 169, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 169, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 169, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 169, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 170, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 170, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 170, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 170, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 170, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 170, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 171, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 171, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 171, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 171, 'Siedzisko Dowódcy'
EXEC dodaj_przedmiot_do_gry 171, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 171, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 172, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 172, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 172, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 172, 'Roślinna Bariera'
EXEC dodaj_przedmiot_do_gry 172, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 172, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 173, 'Tajfun'
EXEC dodaj_przedmiot_do_gry 173, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 173, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 173, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 173, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 173, 'Ostrze Gniewu Guinsoo'
EXEC dodaj_przedmiot_do_gry 174, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 174, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 174, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 174, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 174, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 174, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 175, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 175, 'Chempunkowy Łańcuchowy Miecz'
EXEC dodaj_przedmiot_do_gry 175, 'Bastion Góry'
EXEC dodaj_przedmiot_do_gry 175, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 175, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 175, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 176, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 176, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 176, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 176, 'Odłamek Prawdziwego Lodu'
EXEC dodaj_przedmiot_do_gry 176, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 176, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 177, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 177, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 177, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 177, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 177, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 177, 'Obuwie Maga'
EXEC dodaj_przedmiot_do_gry 178, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 178, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 178, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 178, 'Blask'
EXEC dodaj_przedmiot_do_gry 178, 'Klinga Burzy'
EXEC dodaj_przedmiot_do_gry 178, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 179, 'Łańcuchy Zguby'
EXEC dodaj_przedmiot_do_gry 179, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 179, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 179, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 179, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 179, 'Łza Bogini'
EXEC dodaj_przedmiot_do_gry 180, 'Oko Herolda'
EXEC dodaj_przedmiot_do_gry 180, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 180, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 180, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 180, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 180, 'Paszcza Malmortiusa'
EXEC dodaj_przedmiot_do_gry 181, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 181, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 181, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 181, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 181, 'Widmowy Sierp'
EXEC dodaj_przedmiot_do_gry 181, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 182, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 182, 'Naszyjnik Żelaznych Solari'
EXEC dodaj_przedmiot_do_gry 182, 'Aksjomatyczny Łuk'
EXEC dodaj_przedmiot_do_gry 182, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 182, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 182, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 183, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 183, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 183, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 183, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 183, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 183, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 184, 'Bogobójca'
EXEC dodaj_przedmiot_do_gry 184, 'Naramiennik Poszukiwacza'
EXEC dodaj_przedmiot_do_gry 184, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 184, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 184, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 184, 'Wysysające Spojrzenie'
EXEC dodaj_przedmiot_do_gry 185, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 185, 'Taniec Śmierci'
EXEC dodaj_przedmiot_do_gry 185, 'Bastion Góry'
EXEC dodaj_przedmiot_do_gry 185, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 185, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 185, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 186, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 186, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 186, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 186, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 186, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 186, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 187, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 187, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 187, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 187, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 187, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 187, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 188, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 188, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 188, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 188, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 188, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 188, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 189, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 189, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 189, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 189, 'Kula Zagłady'
EXEC dodaj_przedmiot_do_gry 189, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 189, 'Widmowe Ostrze Youmuu'
EXEC dodaj_przedmiot_do_gry 190, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 190, 'Gruboskórność Steraka'
EXEC dodaj_przedmiot_do_gry 190, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 190, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 190, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 190, 'Konwergencja Zeke''a'
EXEC dodaj_przedmiot_do_gry 191, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 191, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 191, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 191, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 191, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 191, 'Glewia Umbry'
EXEC dodaj_przedmiot_do_gry 192, 'Cezura'
EXEC dodaj_przedmiot_do_gry 192, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 192, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 192, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 192, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 192, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 193, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 193, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 193, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 193, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 193, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 193, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 194, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 194, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 194, 'Bogobójca'
EXEC dodaj_przedmiot_do_gry 194, 'Demoniczny Uścisk'
EXEC dodaj_przedmiot_do_gry 194, 'Syzygium'
EXEC dodaj_przedmiot_do_gry 194, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 195, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 195, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 195, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 195, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 195, 'Alternator Hextech'
EXEC dodaj_przedmiot_do_gry 195, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 196, 'Słoneczna Egida'
EXEC dodaj_przedmiot_do_gry 196, 'Omen Randuina'
EXEC dodaj_przedmiot_do_gry 196, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 196, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 196, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 196, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 197, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 197, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 197, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 197, 'Oko Luden'
EXEC dodaj_przedmiot_do_gry 197, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 197, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 198, 'Łańcuchy Zguby'
EXEC dodaj_przedmiot_do_gry 198, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 198, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 198, 'Żelazny Bicz'
EXEC dodaj_przedmiot_do_gry 198, 'Baczny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 198, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 199, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 199, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 199, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 199, 'Oko Luden'
EXEC dodaj_przedmiot_do_gry 199, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 199, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 200, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 200, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 200, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 200, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 200, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 200, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 201, 'Nieustający Głód'
EXEC dodaj_przedmiot_do_gry 201, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 201, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 201, 'Płomień Cienia'
EXEC dodaj_przedmiot_do_gry 201, 'Vesperiański Przypływ'
EXEC dodaj_przedmiot_do_gry 201, 'Lodowa Rękawica'
EXEC dodaj_przedmiot_do_gry 202, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 202, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 202, 'Kryształowy Karwasz'
EXEC dodaj_przedmiot_do_gry 202, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 202, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 202, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 203, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 203, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 203, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 203, 'Młot Strażnika'
EXEC dodaj_przedmiot_do_gry 203, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 203, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 204, 'Imperialny Mandat'
EXEC dodaj_przedmiot_do_gry 204, 'Ognisty Trybularz'
EXEC dodaj_przedmiot_do_gry 204, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 204, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 204, 'Miotacz Gwiazd'
EXEC dodaj_przedmiot_do_gry 204, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 205, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 205, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 205, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 205, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 205, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 205, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 206, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 206, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 206, 'Kula Strażnika'
EXEC dodaj_przedmiot_do_gry 206, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 206, 'Uraza Seryldy'
EXEC dodaj_przedmiot_do_gry 206, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 207, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 207, 'Krwiochron'
EXEC dodaj_przedmiot_do_gry 207, 'Wykradacz Dusz Mejai'
EXEC dodaj_przedmiot_do_gry 207, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 207, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 207, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 208, 'Łza Bogini'
EXEC dodaj_przedmiot_do_gry 208, 'Całun Banshee'
EXEC dodaj_przedmiot_do_gry 208, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 208, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 208, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 208, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 209, 'Świt Srebrzystej'
EXEC dodaj_przedmiot_do_gry 209, 'Kadłubołamacz'
EXEC dodaj_przedmiot_do_gry 209, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 209, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 209, 'Huragan Runaana'
EXEC dodaj_przedmiot_do_gry 209, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 210, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 210, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 210, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 210, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 210, 'Stalowe Serce'
EXEC dodaj_przedmiot_do_gry 210, 'Pogromca Krakenów'
EXEC dodaj_przedmiot_do_gry 211, 'Twoja Działka'
EXEC dodaj_przedmiot_do_gry 211, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 211, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 211, 'Lustro ze Szkła Bandle'
EXEC dodaj_przedmiot_do_gry 211, 'Plemienna Zbroja'
EXEC dodaj_przedmiot_do_gry 211, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 212, 'Krwiopijec'
EXEC dodaj_przedmiot_do_gry 212, 'Cezura'
EXEC dodaj_przedmiot_do_gry 212, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 212, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 212, 'Odnowienie Kamienia Księżycowego'
EXEC dodaj_przedmiot_do_gry 212, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 213, 'Pasjonujący Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 213, 'Vesperiański Przypływ'
EXEC dodaj_przedmiot_do_gry 213, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 213, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 213, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 213, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 214, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 214, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 214, 'Pożeracz'
EXEC dodaj_przedmiot_do_gry 214, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 214, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 214, 'Totem Ukrycia'
EXEC dodaj_przedmiot_do_gry 215, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 215, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 215, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 215, 'Buty Prędkości'
EXEC dodaj_przedmiot_do_gry 215, 'Widmowe Ostrze Youmuu'
EXEC dodaj_przedmiot_do_gry 215, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 216, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 216, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 216, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 216, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 216, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 216, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 217, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 217, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 217, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 217, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 217, 'Wezwanie Kata'
EXEC dodaj_przedmiot_do_gry 217, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 218, 'Ioniańskie Buty Jasności Umysłu'
EXEC dodaj_przedmiot_do_gry 218, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 218, 'Ochraniacze z Runicznej Stali'
EXEC dodaj_przedmiot_do_gry 218, 'Ostrze Nieskończoności'
EXEC dodaj_przedmiot_do_gry 218, 'Chempunkowy Łańcuchowy Miecz'
EXEC dodaj_przedmiot_do_gry 218, 'Ulepszony Aeropak'
EXEC dodaj_przedmiot_do_gry 219, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 219, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 219, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 219, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 219, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 219, 'Nagolenniki Berserkera'
EXEC dodaj_przedmiot_do_gry 220, 'Świetlista Cnota'
EXEC dodaj_przedmiot_do_gry 220, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 220, 'Ząb Nashora'
EXEC dodaj_przedmiot_do_gry 220, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 220, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 220, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 221, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 221, 'Złodziej Esencji'
EXEC dodaj_przedmiot_do_gry 221, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 221, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 221, 'Ostrze Strażnika'
EXEC dodaj_przedmiot_do_gry 221, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 222, 'Widmowy Tancerz'
EXEC dodaj_przedmiot_do_gry 222, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 222, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 222, 'Oblicze Ducha'
EXEC dodaj_przedmiot_do_gry 222, 'Chłeptacz Posoki'
EXEC dodaj_przedmiot_do_gry 222, 'Reliktowa Tarcza'
EXEC dodaj_przedmiot_do_gry 223, 'Zabójczy Kapelusz Rabadona'
EXEC dodaj_przedmiot_do_gry 223, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 223, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 223, 'Ostatni Szept'
EXEC dodaj_przedmiot_do_gry 223, 'Maska Otchłani'
EXEC dodaj_przedmiot_do_gry 223, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 224, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 224, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 224, 'Młot Bojowy Caulfielda'
EXEC dodaj_przedmiot_do_gry 224, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 224, 'Blask'
EXEC dodaj_przedmiot_do_gry 224, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 225, 'Lodowy Kieł'
EXEC dodaj_przedmiot_do_gry 225, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 225, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 225, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 225, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 225, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 226, 'Kosa Czarnej Mgły'
EXEC dodaj_przedmiot_do_gry 226, 'Zmora Licza'
EXEC dodaj_przedmiot_do_gry 226, 'Wężowy Kieł'
EXEC dodaj_przedmiot_do_gry 226, 'Kolekcjoner'
EXEC dodaj_przedmiot_do_gry 226, 'Egida Legionu'
EXEC dodaj_przedmiot_do_gry 226, 'Kostur Archanioła'
EXEC dodaj_przedmiot_do_gry 227, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 227, 'Półksiężycowe Ostrze Harrowing'
EXEC dodaj_przedmiot_do_gry 227, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 227, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 227, 'Gangplank Placeholder'
EXEC dodaj_przedmiot_do_gry 227, 'Kryształowy Kostur Rylai'
EXEC dodaj_przedmiot_do_gry 228, 'Chemtechowy Skaziciel'
EXEC dodaj_przedmiot_do_gry 228, 'Szybkie Ostrza Navori'
EXEC dodaj_przedmiot_do_gry 228, 'Nieskończona Konwergencja'
EXEC dodaj_przedmiot_do_gry 228, 'Rozgrzany Klejnot'
EXEC dodaj_przedmiot_do_gry 228, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 228, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 229, 'Krwiożercza Hydra'
EXEC dodaj_przedmiot_do_gry 229, 'Bluźnierczy Bożek'
EXEC dodaj_przedmiot_do_gry 229, 'Wysysające Spojrzenie'
EXEC dodaj_przedmiot_do_gry 229, 'Nawałnica Luden'
EXEC dodaj_przedmiot_do_gry 229, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 229, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 230, 'Klejnot Rozpadu'
EXEC dodaj_przedmiot_do_gry 230, 'Boski Łamacz'
EXEC dodaj_przedmiot_do_gry 230, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 230, 'Moc Trójcy'
EXEC dodaj_przedmiot_do_gry 230, 'Kosmiczny Impuls'
EXEC dodaj_przedmiot_do_gry 230, 'Muramana'
EXEC dodaj_przedmiot_do_gry 231, 'Żar Bami'
EXEC dodaj_przedmiot_do_gry 231, 'Blask'
EXEC dodaj_przedmiot_do_gry 231, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 231, 'Jak''Sho Zmienny'
EXEC dodaj_przedmiot_do_gry 231, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 231, 'Czarna Włócznia Kalisty'
EXEC dodaj_przedmiot_do_gry 232, 'Cezura'
EXEC dodaj_przedmiot_do_gry 232, 'Zaćmienie'
EXEC dodaj_przedmiot_do_gry 232, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 232, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 232, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 232, 'Niszczyciel Marzeń'
EXEC dodaj_przedmiot_do_gry 233, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 233, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 233, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 233, 'Równonoc'
EXEC dodaj_przedmiot_do_gry 233, 'Pochłaniacz Uroków'
EXEC dodaj_przedmiot_do_gry 233, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 234, 'Blask'
EXEC dodaj_przedmiot_do_gry 234, 'Ostrze Złodziejki Czarów'
EXEC dodaj_przedmiot_do_gry 234, 'Cieniotwórca Draktharru'
EXEC dodaj_przedmiot_do_gry 234, 'Skupienie Horyzontalne'
EXEC dodaj_przedmiot_do_gry 234, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 234, 'Klepsydra Zhonyi'
EXEC dodaj_przedmiot_do_gry 235, 'Ostrze Nocy'
EXEC dodaj_przedmiot_do_gry 235, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 235, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 235, 'Muramana'
EXEC dodaj_przedmiot_do_gry 235, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 235, 'Przedwieczny Brzask'
EXEC dodaj_przedmiot_do_gry 236, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 236, 'Pancerz Umrzyka'
EXEC dodaj_przedmiot_do_gry 236, 'Odkupienie'
EXEC dodaj_przedmiot_do_gry 236, 'Przysięga Rycerska'
EXEC dodaj_przedmiot_do_gry 236, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 236, 'Buty Mobilności'
EXEC dodaj_przedmiot_do_gry 237, 'Stalowe Naramienniki'
EXEC dodaj_przedmiot_do_gry 237, 'Nieopisany Pasożyt'
EXEC dodaj_przedmiot_do_gry 237, 'Poświęcenie Wężowej Ofiary'
EXEC dodaj_przedmiot_do_gry 237, 'Różdżka Wieków'
EXEC dodaj_przedmiot_do_gry 237, 'Widmowa Osłona'
EXEC dodaj_przedmiot_do_gry 237, 'Rtęciowy Bułat'
EXEC dodaj_przedmiot_do_gry 238, 'Pancerniaki'
EXEC dodaj_przedmiot_do_gry 238, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 238, 'Chempunkowy Łańcuchowy Miecz'
EXEC dodaj_przedmiot_do_gry 238, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 238, 'Tiamat'
EXEC dodaj_przedmiot_do_gry 238, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 239, 'Zaginiony Rozdział'
EXEC dodaj_przedmiot_do_gry 239, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 239, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 239, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 239, 'Puklerz Targonu'
EXEC dodaj_przedmiot_do_gry 239, 'Kolczasta Kolczuga'
EXEC dodaj_przedmiot_do_gry 240, 'Cierpienie Liandry''ego'
EXEC dodaj_przedmiot_do_gry 240, 'Relikwiarz Złotej Jutrzenki'
EXEC dodaj_przedmiot_do_gry 240, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 240, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 240, 'Korona Roztrzaskanej Królowej'
EXEC dodaj_przedmiot_do_gry 240, 'Szpon Ciemnego Typa'
EXEC dodaj_przedmiot_do_gry 241, 'Szczelinotwórca'
EXEC dodaj_przedmiot_do_gry 241, 'Nadejście Zimy'
EXEC dodaj_przedmiot_do_gry 241, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 241, 'Ogniolubny Topór'
EXEC dodaj_przedmiot_do_gry 241, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 241, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 242, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 242, 'Mroźne Serce'
EXEC dodaj_przedmiot_do_gry 242, 'Siła Natury'
EXEC dodaj_przedmiot_do_gry 242, 'Błogosławieństwo Mikaela'
EXEC dodaj_przedmiot_do_gry 242, 'Mroźny Puklerz'
EXEC dodaj_przedmiot_do_gry 242, 'Bastion Góry'
EXEC dodaj_przedmiot_do_gry 243, 'Nieśmiertelny Łuklerz'
EXEC dodaj_przedmiot_do_gry 243, 'Ząbkowany Sztylet'
EXEC dodaj_przedmiot_do_gry 243, 'Szpon Piaskowej Dzierżby'
EXEC dodaj_przedmiot_do_gry 243, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 243, 'Rtęciowa Szarfa'
EXEC dodaj_przedmiot_do_gry 243, 'Złota Szpatułka'
EXEC dodaj_przedmiot_do_gry 244, 'Kolosalna Hydra'
EXEC dodaj_przedmiot_do_gry 244, 'Łańcuchy Zguby'
EXEC dodaj_przedmiot_do_gry 244, 'Kamienna Płyta Gargulca'
EXEC dodaj_przedmiot_do_gry 244, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 244, 'Śmiertelne Przypomnienie'
EXEC dodaj_przedmiot_do_gry 244, 'Koniec Rozumu'
EXEC dodaj_przedmiot_do_gry 245, 'Czarci Kodeks'
EXEC dodaj_przedmiot_do_gry 245, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 245, 'Cezura'
EXEC dodaj_przedmiot_do_gry 245, 'Gniewonóż'
EXEC dodaj_przedmiot_do_gry 245, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 245, 'Pozdrowienia Lorda Dominika'
EXEC dodaj_przedmiot_do_gry 246, 'Mroźny Puklerz'
EXEC dodaj_przedmiot_do_gry 246, 'Ostrze Zniszczonego Króla'
EXEC dodaj_przedmiot_do_gry 246, 'Kostur Płynącej Wody'
EXEC dodaj_przedmiot_do_gry 246, 'Łamacz Falangi'
EXEC dodaj_przedmiot_do_gry 246, 'Czujny Kamienny Totem'
EXEC dodaj_przedmiot_do_gry 246, 'Kukła Stracha na Wróble'
EXEC dodaj_przedmiot_do_gry 247, 'Wielka Zima'
EXEC dodaj_przedmiot_do_gry 247, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 247, 'Włócznia Shojin'
EXEC dodaj_przedmiot_do_gry 247, 'Klątwa Icathii'
EXEC dodaj_przedmiot_do_gry 247, 'Lewiatan'
EXEC dodaj_przedmiot_do_gry 247, 'Anioł Stróż'
EXEC dodaj_przedmiot_do_gry 248, 'Potęga Wichury'
EXEC dodaj_przedmiot_do_gry 248, 'Roślinna Bariera'
EXEC dodaj_przedmiot_do_gry 248, 'Zasłona Równości'
EXEC dodaj_przedmiot_do_gry 248, 'Ognista Armata'
EXEC dodaj_przedmiot_do_gry 248, 'Turbochemiczny Pojemnik'
EXEC dodaj_przedmiot_do_gry 248, 'Egida Legionu'
EXEC dodaj_przedmiot_do_gry 249, 'Katalizator Eonów'
EXEC dodaj_przedmiot_do_gry 249, 'Morellonomicon'
EXEC dodaj_przedmiot_do_gry 249, 'Zbroja Strażnika'
EXEC dodaj_przedmiot_do_gry 249, 'Obuwie Merkurego'
EXEC dodaj_przedmiot_do_gry 249, 'Czarny Tasak'
EXEC dodaj_przedmiot_do_gry 249, 'Nocny Żniwiarz'
EXEC dodaj_przedmiot_do_gry 250, 'Rekwiem Shurelyi'
EXEC dodaj_przedmiot_do_gry 250, 'Naramienniki spod Białej Skały'
EXEC dodaj_przedmiot_do_gry 250, 'Wieczna Zmarzlina'
EXEC dodaj_przedmiot_do_gry 250, 'Zmiana Dalekowidzenia'
EXEC dodaj_przedmiot_do_gry 250, 'Moc Nieskończoności'
EXEC dodaj_przedmiot_do_gry 250, 'Krwiochron'
