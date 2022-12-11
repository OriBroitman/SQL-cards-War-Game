--==================================================================================
--                          WAR CARD GAME in SQL
--Presented By Ori Broitman
--==================================================================================

--Enable creation of a folder in windows using SQL
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE
GO

xp_cmdshell 'MD C:\SQL_WAR_CARD_GAME'
GO
--==================================================================================
CREATE DATABASE [WAR_CARD_GAME]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'LADDERSANDSNAKE', FILENAME = N'C:\SQL_WAR_CARD_GAME\WAR_CARD_GAME.MDF' , SIZE = 8096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'LADDERSANDSNAKE_LOG', FILENAME = N'C:\SQL_WAR_CARD_GAME\WAR_CARD_GAME_LOG.LDF' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
--==================================================================================
USE WAR_CARD_GAME
GO


--Create a table that will contain all the cards in the deck.
CREATE TABLE Cards (
Num INT identity (1,1) NOT NULL, --A unique number to every cards, used to know which card will be used or was used already   
CardNum INT NOT NULL, --The number of the card inside the deck, used to compare cards
CardType VARCHAR(20) NOT NULL, --How the players will see the card based on number, name and type like 7 heart or ace diamond
Distribution INT NOT NULL --Used to distribute the card between players
)
GO
--Create a table that during a game will contain all the cards of player 1.
CREATE TABLE Player1 (
Num INT NOT NULL, --Will get the unique number of the card that was given to player
CardNum INT NOT NULL, --The number of the card inside the deck, used to compare cards
CardType VARCHAR(20) NOT NULL, --How the players will see the card
Distribution INT NOT NULL --Used to distribute the card between players
)
GO
--Create a table that during a game will contain all the cards of player 2.
CREATE TABLE Player2 (
Num INT NOT NULL, --Will get the unique number of the card that was given to player
CardNum INT NOT NULL, --The number of the card inside the deck, used to compare cards
CardType varchar(20) NOT NULL, --How the players will see the card
Distribution INT NOT NULL --Used to distribute the card between players
)
GO

--Create a table that will save the game and the number of moves that was played in the game
CREATE TABLE GamesRecored(
 GameID INT NOT NULL, 
 MovesInTheGame INT   --the number of movs in the game   
)
GO
--Create a table that will save the entire game play by play
CREATE TABLE GamesLogs (
  GameID INT NOT NULL,
  MoveNumber INT,
  WinningPlayer VARCHAR(20),
  WinningCard VARCHAR(20),
  LosingPlayer VARCHAR(20),
  LosingCard VARCHAR(20)
)
GO

INSERT INTO GamesLogs (GameID) --Put the first number in the GamesLogs table to enable it to start working, later this row will be deleted
VALUES (0)

INSERT INTO Cards ( CardNum, CardType, Distribution) --Fill the table cards with the cards of the deck.
VALUES 
		(2, '2 Heart',0), (2, '2 Club',0), (2, '2 Diamond',0), (2, '2 Spade',0),
		(3, '3 Heart',0), (3, '3 Club',0), (3, '3 Diamond',0), (3, '3 Spade',0),
		(4, '4 Heart',0), (4, '4 Club',0), (4, '4 Diamond',0), (4, '4 Spade',0),
		(5, '5 Heart',0), (5, '5 Club',0), (5, '5 Diamond',0), (5, '5 Spade',0),	
		(6, '6 Heart',0), (6, '6 Club',0), (6, '6 Diamond',0), (6, '6 Spade',0),	
		(7, '7 Heart',0), (7, '7 Club',0), (7, '7 Diamond',0), (7, '7 Spade',0),		
		(8, '8 Heart',0), (8, '8 Club',0), (8, '8 Diamond',0), (8, '8 Spade',0),
		(9, '9 Heart',0), (9, '9 Club',0), (9, '9 Diamond',0), (9, '9 Spade',0),
		(10, '10 Heart',0), (10, '10 Club',0), (10, '10 Diamond',0), (10, '10 Spade',0),
		(11, 'Jack Heart',0), (11, 'Jack Club',0), (11, 'Jack Diamond',0), (11, 'Jack Spade' ,0),
		(12, 'Queen Heart',0), (12, 'Queen Club',0), (12, 'Queen Diamond',0), (12, 'Queen Spade',0),	
		(13, 'King Heart',0), (13, 'King Club',0), (13, 'King Diamond',0), (13, 'King Spade',0),
		(14, 'Ace Heart',0), (14, 'Ace Club',0), (14, 'Ace Diamond',0), (14, 'Ace Spade',0)
GO

--Create a procedure the will start by cleaning all the remains of the last game,
--then the procedure will distribute the card of the deck between the two players. 
CREATE PROCEDURE Distribute 
AS 
BEGIN
	UPDATE Cards --Calibration the main deck and ready it for distribution.
	SET Distribution = 0
	where 	Distribution = 1 OR Distribution = 2

	DELETE FROM Player1 --Clear the deck of player1 from cards of the last game and ready it to receive new cards.
	DELETE FROM Player2 --Clear the deck of player2 from cards of the last game and ready it to receive new cards.

	DECLARE @Num INT=0, --Count for the first 26 cards that will be for player 1.
			@Temp VARCHAR(max),--Will used to make sure that the card that was chosen wasn't used already.
			@Rand INT --Will get number of a random card.
	WHILE ( @Num < 26)--count until 26 cards .
	BEGIN
		  SET @Rand= ABS(CHECKSUM(NEWID()))%52+1 --pick a card from the deck.
		  SET @Temp= (SELECT Distribution FROM Cards WHERE Num = @Rand) --Fill @temp for a test if the chosen card wasn't used already.
		 
		 --Check if the chosen card was used already, if it was used it's distribution number will be 1, and a new card will randomly be picked.
		 --If the card wasn't chosen and used it's distribution number will be 0, and action will be made to change it's distribution number to 1.
		  IF (@Temp=0)
		  BEGIN 
				  UPDATE Cards
				  SET Distribution = 1
				  WHERE Num = @Rand
				  SET @Num +=1  
		  END
	END --End of the while.

	--we now got 26 cards with a distribution number 1, all of them will be player 1 deck.
	--All the remain cards got a distribution number 0, and now will change its distribution number to 2.
	UPDATE Cards
	SET Distribution = 2
	WHERE Distribution = 0

	INSERT INTO Player1 (Num,CardNum,CardType,Distribution)--Give player 1 it's deck.
	SELECT * FROM Cards WHERE Distribution =1

	INSERT INTO Player2(Num,CardNum,CardType,Distribution)--Give player 2 it's deck.
	SELECT * FROM Cards WHERE Distribution =2
END
GO

--Procedure to solve a tie(war) in the game.
--The Procedure will receive at start the two card that made the tie.
CREATE PROC War_Dual @ProcWarNum1 VARCHAR(MAX), @ProcWarNum2 VARCHAR(MAX), @GameID INT, @MoveCounter INT
AS
BEGIN
SET NOCOUNT ON --Stops the message that shows the count of the number of rows affected by a Transact-SQL statement or stored procedure from being returned as part of the result set.
	DECLARE  @CardNum1 VARCHAR(MAX),-- Will receive the card number to compare between the players.
			@CardNum2 VARCHAR(MAX),
			@CardShow1 VARCHAR(MAX),-- Will show the number & type of the winning and losing card.
			@CardShow2 VARCHAR(MAX),
			@WarNum1 VARCHAR(MAX),-- Will pick the card to play for the player in the war.
			@WarNum2 VARCHAR(MAX),
			@Three INT =1-- Will move three card from the losing player to the winner.

	SET @WarNum1= (SELECT TOP 1 Num FROM Player1 ORDER BY NEWID())--Pick a card from the deck.
	SET @WarNum2= (SELECT TOP 1 Num FROM Player2 ORDER BY NEWID())
	SET @CardNum1=(SELECT CardNum FROM Player1 WHERE Num=@WarNum1)--Check the number of the card to comparison. 
	SET @CardNum2=(SELECT CardNum FROM Player2 WHERE Num=@WarNum2)
	SET @CardShow1= (SELECT CardType FROM Player1 WHERE Num=@WarNum1)--Take the number & type of the card.
	SET @CardShow2= (SELECT CardType FROM Player2 WHERE Num=@WarNum2)

	IF (@CardNum1>@CardNum2) --If player1 win.
	BEGIN
		PRINT 'Player1 ' + @CardShow1 + ' wins Player2 '+ @CardShow2 + ' and win the WAR!' --Print how player1 won the dual.

		INSERT INTO Player1 --Take the card of the drow before the war and give it to the player that won.
		SELECT * FROM Player2 WHERE Num=@ProcWarNum2 

		DELETE FROM Player2 --Delete the card of the drow before the war from the losing player.
		WHERE Num=@ProcWarNum2

		INSERT INTO Player1 --Take the card that won the war and give it to the player that won.
		SELECT * FROM Player2 WHERE Num=@WarNum2 

		DELETE FROM Player2 --Delete the card that last the war from the losing player.
		WHERE Num=@Warnum2

		INSERT INTO GamesLogs
			VALUES (@GameID,@MoveCounter,'Player1',@CardShow1,'Player2',@CardShow2)

		WHILE (@Three <=3) --Make sure the take three card from the loser and give it to the player that won the war.
		BEGIN
				SET @WarNum1= (SELECT TOP 1 Num FROM Player1 ORDER BY NEWID()) --Pick a card to trade as spoiles  of war.
				INSERT INTO Player1 --Take random card from the loser deck and give it to the player that won.
				SELECT * FROM Player2 WHERE Num=@WarNum2 

				DELETE FROM Player2 --Delete the random card.
				WHERE Num=@WarNum2

				SET @Three +=1 --Count to three cards.
		END
	END
	IF (@CardNum1<@CardNum2)--If player2 win.
	BEGIN
		PRINT 'Player2 ' + @CardShow2 + ' wins Player1 '+ @CardShow1 + ' and win the WAR!' --Print how player2 won the dual.

		INSERT INTO Player2 -- Take the card of the drow before the war and give it to the player that won.
		SELECT * FROM Player1 WHERE Num=@ProcWarNum1

		DELETE FROM Player1  -- Delete the card of the drow before the war from the losing player.
		WHERE Num=@ProcWarNum1

		INSERT INTO Player2  --Take the card that won the war and give it to the player that won.
		SELECT * FROM Player1 WHERE Num=@WarNum1

		DELETE from Player1 --Delete the card that last the war from the losing player.
		WHERE Num=@WarNum1

		INSERT INTO GamesLogs
			VALUES (@GameID,@MoveCounter,'Player2',@CardShow2,'Player1',@CardShow1)

		WHILE (@Three <=3) --Make sure the take three card from the loser and give it to the player that won the war.
		BEGIN
			  SET @WarNum2= (SELECT TOP 1 Num from Player2 ORDER BY NEWID()) --Pick a card to trade as spoiles  of war.
			  INSERT INTO Player2 --Take random card from the loser deck and give it to the player that won.
			  SELECT * FROM Player1 WHERE Num=@WarNum1

			  DELETE FROM Player1 --Delete the random card.
			  WHERE Num=@WarNum1

			  SET @Three +=1 --Count to three cards.
		END
	END
	IF (@CardNum1=@CardNum2) --If we got a tie in the war.
	BEGIN
		PRINT 'we got another WAR!!!'
		EXEC War_Dual @ProcWarNum1 = @ProcWarNum1, @ProcWarNum2 = @ProcWarNum2 ,@GameID=@GameID,@MoveCounter=@MoveCounter--Start the Procedure again inside the Procedure in a recursive way.
	END
END
GO

CREATE PROC Play_WAR --Run all the game automatic.
AS
BEGIN
SET NOCOUNT ON --Stops the message that shows the count of the number of rows affected by a Transact-SQL statement or stored procedure from being returned as part of the result set.
	DECLARE @CardNum1 VARCHAR(MAX), -- Will receive the card number to compare between the players.
			@CardNum2 VARCHAR(MAX),
			@Num1 VARCHAR(MAX), -- Will pick the card to play for the player.
			@Num2 VARCHAR(MAX),
			@CardShow1 VARCHAR(MAX),-- Will show the number & type of the winning and losing card.
			@CardShow2 VARCHAR(MAX),
			@MoveCounter INT=1, --Count the number of moves in the game.
			@GameID INT

	SET @GameID = (SELECT TOP 1 GameID FROM GamesLogs ORDER BY GameID DESC) + 1

	DELETE FROM GamesLogs
	WHERE GameID = 0

	--The "while" will check if the got more cards in is deck, when a player run out of card the game will be over.
	WHILE ((SELECT COUNT(*) FROM Player1) <>0) AND ((SELECT COUNT(*) FROM Player2) <>0)
	BEGIN
		SET @Num1= (SELECT TOP 1 Num FROM Player1 ORDER BY NEWID())--Pick a card from the deck.
		SET @Num2= (SELECT TOP 1 Num FROM Player2 ORDER BY NEWID())
		SET @CardNum1=(SELECT CardNum FROM Player1 WHERE Num=@Num1)--Check the number of the card to comparison.
		SET @CardNum2=(SELECT CardNum FROM Player2 WHERE Num=@Num2)
		SET @CardShow1= (SELECT CardType FROM Player1 WHERE Num=@Num1)--Take the number & type of the card.
		SET @CardShow2= (SELECT CardType FROM Player2 WHERE Num=@Num2)
	
		PRINT 'Move Number ' + CONVERT(VARCHAR(10), @MoveCounter)--Print the number of the move.

		IF (@CardNum1>@CardNum2)--If player1 win.
		BEGIN
			PRINT 'Player1 ' + @CardShow1 + ' wins Player2 '+ @CardShow2--Print how player1 won the dual.
			--Move the losing card from player2 to player1.
			INSERT INTO Player1
			SELECT * FROM Player2 WHERE Num=@Num2
			--Delete the losing card from player2.
			DELETE FROM Player2
			WHERE Num=@Num2
			
			INSERT INTO GamesLogs
			VALUES (@GameID,@MoveCounter,'Player1',@CardShow1,'Player2',@CardShow2)

		END
		IF (@CardNum1<@CardNum2)--If player2 win.
		BEGIN
			PRINT 'Player2 ' + @CardShow2 + ' wins Player1 '+ @CardShow1--Print how player2 won the dual.
			--Move the losing card from player1 to player2.
			INSERT INTO Player2
			SELECT * FROM Player1 WHERE Num=@Num1
			--Delete the losing card from player1.
			DELETE FROM Player1
			WHERE Num=@Num1

			INSERT INTO GamesLogs
			VALUES (@GameID,@MoveCounter,'Player2',@CardShow2,'Player1',@CardShow1)
		END
		IF (@CardNum1=@CardNum2)--If the card are tie, activite a procedure that will solve it
		BEGIN
			PRINT 'we got WAR!!!'
			EXEC War_Dual @ProcWarNum1 = @Num1, @ProcWarNum2 = @Num2, @GameID=@GameID, @MoveCounter=@MoveCounter --Start a procedure to solve the tie.
		END
		SET @MoveCounter +=1--Move the counter up.
	END


	IF((SELECT COUNT(*) FROM Player1) = 0) --If player2 won the game.
	BEGIN
			PRINT 'Player2 WIN the WAR!!!' 
			INSERT INTO GamesRecored
			VALUES (@GameID,@MoveCounter)
	END


	IF((select COUNT(*) FROM Player2) =0)  --If player1 won the game.
	BEGIN
			PRINT 'Player1 WIN the WAR!!!' 
			INSERT INTO GamesRecored
			VALUES (@GameID,@MoveCounter)
	END

END
GO


CREATE VIEW V_LongestGames --Create a view to watch the history of the top 10 longest games
AS (
	SELECT GamesRecored.GameID,MoveNumber,WinningPlayer,WinningCard,LosingPlayer,LosingCard 
	FROM GamesLogs JOIN GamesRecored
	ON GamesLogs.GameID = GamesRecored.GameID
	WHERE GamesRecored.GameID IN (SELECT TOP 10 GameID  FROM GamesRecored ORDER BY MovesInTheGame desc)
)
GO

CREATE PROC LongestGames --Create a procedure that will call the view V_LongestGames so we can watch the top 10 longest games
AS
BEGIN
	SELECT * FROM V_LongestGames
END
GO

CREATE VIEW V_AnalysisOfWinningCards--Create a view to analyze the winning cards
AS(
	SELECT WinningCard, COUNT(WinningCard)  AS NumberOfWins 
	FROM GamesLogs JOIN GamesRecored
	ON GamesLogs.GameID= GamesRecored.GameID
	GROUP BY WinningCard
)
GO

CREATE PROC AnalysisOfWinningCards --Create a procedure that will call the view V_AnalysisOfWinningCards so we can analyze the winning cards
AS
BEGIN
	SELECT * FROM V_AnalysisOfWinningCards
	ORDER BY NumberOfWins  DESC
END
GO














