-- Kayýt ekleme düzenleme satýþ yapma gibi prosedürleri oluþturur.
USE TourCompany0
GO


sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE PROCEDURE dbo.UpdateRegions(
	@action VARCHAR(10),
	@region_name VARCHAR(30) = NULL,
	@region_fee DECIMAL(10,2) = NULL
)
AS
BEGIN
	IF @action = 'insert'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Regions WHERE region_name = @region_name)
		BEGIN
			INSERT INTO Regions (region_name, region_fee)
			VALUES (@region_name, @region_fee);
		END
		ELSE
		BEGIN
			PRINT 'Eklenmek istenen bölge adý zaten var. Ekleme yapýlmadý. ';
		END
	END
	ELSE IF @action = 'delete'
	BEGIN
		IF EXISTS (SELECT * FROM Regions WHERE region_name = @region_name)
		BEGIN
			DELETE FROM Regions WHERE region_name = @region_name;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen bölge adý bulunamadýðýndan silme iþlemi yapýlamadý.';
		END
	END
	ELSE IF @action = 'change'
	BEGIN
		IF EXISTS (SELECT * FROM Regions WHERE region_name = @region_name)
		BEGIN
			UPDATE Regions SET region_fee = @region_fee WHERE region_name = @region_name;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen bölge adý bulunamadýðýndan güncelleme yapýlamadý.';
		END
	END
	ELSE
	BEGIN
		PRINT 'incorrect enter! Please enter a valid actions. insert / delete / change';
	END;
END;
GO





CREATE PROCEDURE dbo.UpdateVehicles(
	@action VARCHAR(10),
	@vehicle_name VARCHAR(30) = NULL,
	@vehicle_capacity INT =	NULL,
	@vehicle_fee DECIMAL(10,2) = NULL
)
AS
BEGIN
	IF @action = 'insert'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Vehicles WHERE @vehicle_name = vehicle_name)
		BEGIN
			INSERT INTO Vehicles (vehicle_name, vehicle_capacity, vehicle_fee)
			VALUES (@vehicle_name, @vehicle_capacity, @vehicle_fee);
		END
		ELSE
		BEGIN
			PRINT 'Eklenmek istenen araç adý zaten var. Ekleme yapýlmadý. ';
		END
	END
	ELSE IF @action = 'delete'
	BEGIN
		IF EXISTS (SELECT * FROM Vehicles WHERE @vehicle_name = vehicle_name)
		BEGIN
			DELETE from Vehicles WHERE @vehicle_name = vehicle_name;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen araç adý bulunamadýðýndan silme iþlemi yapýlamadý.';
		END
	END
	ELSE IF @action = 'change'
	BEGIN
		IF EXISTS (SELECT * FROM Vehicles WHERE vehicle_name = @vehicle_name)
		BEGIN
			UPDATE Vehicles SET vehicle_fee = @vehicle_fee, vehicle_capacity = @vehicle_capacity WHERE vehicle_name = @vehicle_name;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen araç adý bulunamadýðýndan güncelleme yapýlamadý.';
		END
	END
	ELSE
	BEGIN
		PRINT 'incorrect enter! Please enter a valid actions. insert / delete / change';
	END;
END;
GO




CREATE PROCEDURE dbo.UpdateTour(
	@action VARCHAR(10),
	@tour_name VARCHAR(150) = NULL,
	@vehicle_name VARCHAR(30) =	NULL,
	@region1_name VARCHAR(30) =	NULL,
	@region2_name VARCHAR(30) =	NULL,
	@region3_name VARCHAR(30) =	NULL
)
AS
BEGIN

-- girilen deðerler varlýk kontrolü
    IF @tour_name = NULL
    BEGIN
        -- Tur adý bulunmadýðý durumda hata mesajý döndür
        RAISERROR('Geçerli Tur adý giriniz.', 16, 1)
        RETURN;
    END

	IF @action = 'insert'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Vehicles WHERE vehicle_name = @vehicle_name) OR @vehicle_name = NULL
		BEGIN
			-- Taþýt adý bulunamadýðý durumda hata mesajý döndür
			RAISERROR('Geçerli araç adý giriniz.', 16, 1)
			RETURN;
		END
		IF NOT EXISTS (SELECT * FROM Regions WHERE region_name = @region1_name) OR @region1_name = NULL
		BEGIN
			-- Bölge adý bulunamadýðý durumda hata mesajý döndür
			RAISERROR('Geçerli bölge adý giriniz.', 16, 1)
			RETURN;
		END
		INSERT INTO Tours(tour_name)
		VALUES (@tour_name);
		INSERT INTO Services1(tour_id, region_id, vehicle_id)
		VALUES (
			(SELECT tour_id FROM Tours WHERE tour_name = @tour_name),
			(SELECT region_id FROM Regions WHERE region_name = @region1_name),
			(SELECT vehicle_id FROM Vehicles WHERE vehicle_name = @vehicle_name)
		)
		IF @region2_name IS NOT NULL
		BEGIN
			INSERT INTO Services1(tour_id, region_id, vehicle_id)
			VALUES (
				(SELECT tour_id FROM Tours WHERE tour_name = @tour_name),
				(SELECT region_id FROM Regions WHERE region_name = @region2_name),
				(SELECT vehicle_id FROM Vehicles WHERE vehicle_name = @vehicle_name)
			)
		END
		IF @region3_name IS NOT NULL
		BEGIN
			INSERT INTO Services1(tour_id, region_id, vehicle_id)
			VALUES (
				(SELECT tour_id FROM Tours WHERE tour_name = @tour_name),
				(SELECT region_id FROM Regions WHERE region_name = @region3_name),
				(SELECT vehicle_id FROM Vehicles WHERE vehicle_name = @vehicle_name)
			)
		END
		-- Services fiyat oluþturmak için bölge ve araç ücretlerini toplama
		UPDATE Services1
		SET service_fee = (
			SELECT (V.vehicle_fee + R.region_fee)
			FROM Vehicles AS V
			JOIN Regions AS R ON Services1.region_id = R.region_id
			WHERE Services1.vehicle_id = V.vehicle_id
		)

		-- Tour_fee deðerini service_fee deðerlerinden oluþturma
		UPDATE Tours
		SET tour_fee = (
			SELECT SUM(service_fee)
			FROM Services1
			WHERE Services1.tour_id = Tours.tour_id
			GROUP BY tour_id
		)
	END
	ELSE IF @action = 'delete'
	BEGIN
		-- FK__Invoices__sale_i__4AB81AF0 kýsýtýný devre dýþý býrakma
		ALTER TABLE Invoices
		NOCHECK CONSTRAINT FK__Invoices__sale_i__4AB81AF0;

		-- FK__TourSales__tour___45F365D3 kýsýtýný devre dýþý býrakma
		ALTER TABLE TourSales
		NOCHECK CONSTRAINT FK__TourSales__tour___45F365D3;

		DELETE FROM Services1 WHERE tour_id IN (SELECT tour_id FROM Tours WHERE tour_name = @tour_name);
		DELETE FROM Tours WHERE tour_name = @tour_name;

		-- FK__Invoices__sale_i__4AB81AF0 kýsýtýný yeniden etkinleþtirme
		ALTER TABLE Invoices
		CHECK CONSTRAINT FK__Invoices__sale_i__4AB81AF0;

		-- FK__TourSales__tour___45F365D3 kýsýtýný yeniden etkinleþtirme
		ALTER TABLE TourSales
		CHECK CONSTRAINT FK__TourSales__tour___45F365D3;


	END
	ELSE IF @action = 'change'
	BEGIN
		IF EXISTS (SELECT * FROM Tours WHERE tour_name = @tour_name)
		BEGIN
			EXEC dbo.UpdateTour 'delete', @tour_name, @vehicle_name, @region1_name, @region2_name, @region3_name;
			EXEC dbo.UpdateTour 'insert', @tour_name, @vehicle_name, @region1_name, @region2_name, @region3_name;
		END
		ELSE
		BEGIN
		    -- Tur adý bulunmadýðý durumda hata mesajý döndür
			RAISERROR('Geçerli Tur adý giriniz.', 16, 1)
			RETURN;
		END
	END
	ELSE
	BEGIN
		PRINT 'incorrect enter! Please enter a valid actions. insert / delete / change';
	END;
END;
GO








-- Rehber Düzenleme procedure

CREATE PROCEDURE dbo.UpdateGuides(
	@action VARCHAR(10),
	@guide_name VARCHAR(20) = NULL,
	@guide_surname VARCHAR(40) = NULL,
	@gender CHAR(1) =	NULL,
	@phone_number VARCHAR(20) =	NULL,
	@languages VARCHAR(100) = NULL
)
AS
BEGIN
	IF @action = 'insert'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Guides WHERE @guide_name = guide_name) AND NOT EXISTS (SELECT * FROM Guides WHERE @guide_surname = guide_surname)
		BEGIN
			INSERT INTO Guides(guide_name, guide_surname, gender, phone_number, languages)
			VALUES (@guide_name, @guide_surname, @gender, @phone_number, @languages);
		END
		ELSE
		BEGIN
			PRINT 'Eklenmek istenen rehber zaten var. Ekleme yapýlmadý. ';
		END
	END
	ELSE IF @action = 'delete'
	BEGIN
		IF EXISTS (SELECT * FROM Guides WHERE @guide_name = guide_name) AND EXISTS (SELECT * FROM Guides WHERE @guide_surname = guide_surname)
		BEGIN
			DELETE FROM Guides WHERE @guide_name = guide_name AND @guide_surname = guide_surname;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen rehber bulunamadýðýndan silme iþlemi yapýlamadý.';
		END
	END
	ELSE IF @action = 'change'
	BEGIN
		IF EXISTS (SELECT * FROM Guides WHERE @guide_name = guide_name) AND EXISTS (SELECT * FROM Guides WHERE @guide_surname = guide_surname)
		BEGIN
			UPDATE Guides SET gender = @gender, phone_number = @phone_number, languages = @languages WHERE guide_name = @guide_name AND guide_surname = @guide_surname;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen rehber bulunamadýðýndan güncelleme yapýlamadý.';
		END
	END
	ELSE
	BEGIN
		PRINT 'incorrect enter! Please enter a valid actions. insert / delete / change';
	END;
END;
GO




-- Turist Düzenleme procedure

CREATE PROCEDURE dbo.UpdateTourists(
	@action VARCHAR(10),
	@tourist_name VARCHAR(20) = NULL,
	@tourist_surname VARCHAR(40) = NULL,
	@gender CHAR(1) =	NULL,
	@birth_date DATE =	NULL,
	@nationality VARCHAR(50) = NULL,
	@country VARCHAR(50) = NULL
)
AS
BEGIN
	IF @action = 'insert'
	BEGIN
		IF NOT EXISTS (SELECT * FROM Tourists WHERE @tourist_name = tourist_name) AND NOT EXISTS (SELECT * FROM Tourists WHERE @tourist_surname = tourist_surname)
		BEGIN
			INSERT INTO Tourists(tourist_name, tourist_surname, gender, birth_date, nationality, country)
			VALUES (@tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country);
		END
		ELSE
		BEGIN
			PRINT 'Eklenmek istenen turist zaten var. Ekleme yapýlmadý. ';
		END
	END
	ELSE IF @action = 'delete'
	BEGIN
		IF EXISTS (SELECT * FROM Tourists WHERE @tourist_name = tourist_name) AND EXISTS (SELECT * FROM Tourists WHERE @tourist_surname = tourist_surname)
		BEGIN
			-- FK__Invoices__sale_i__4AB81AF0 kýsýtýný devre dýþý býrakma
			ALTER TABLE Invoices
			NOCHECK CONSTRAINT FK__Invoices__sale_i__4AB81AF0;

			-- FK__TourSales__tour___45F365D3 kýsýtýný devre dýþý býrakma
			ALTER TABLE TourSales
			NOCHECK CONSTRAINT FK__TourSales__tour___45F365D3;		
			
			DELETE FROM TourSales WHERE tourist_id IN (SELECT tourist_id FROM Tourists WHERE tourist_name = @tourist_name AND tourist_surname = @tourist_surname)	
			DELETE FROM Tourists WHERE @tourist_name = tourist_name AND @tourist_surname = tourist_surname;
		
			-- FK__Invoices__sale_i__4AB81AF0 kýsýtýný yeniden etkinleþtirme
			ALTER TABLE Invoices
			CHECK CONSTRAINT FK__Invoices__sale_i__4AB81AF0;

			-- FK__TourSales__tour___45F365D3 kýsýtýný yeniden etkinleþtirme
			ALTER TABLE TourSales
			CHECK CONSTRAINT FK__TourSales__tour___45F365D3;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen turist bulunamadýðýndan silme iþlemi yapýlamadý.';
		END
	END
	ELSE IF @action = 'change'
	BEGIN
		IF EXISTS (SELECT * FROM Tourists WHERE @tourist_name = tourist_name) AND EXISTS (SELECT * FROM Tourists WHERE @tourist_surname = tourist_surname)
		BEGIN
			UPDATE Tourists SET gender = @gender, birth_date = @birth_date, nationality = @nationality, country = @country WHERE tourist_name = @tourist_name AND tourist_surname = @tourist_surname;
		END
		ELSE
		BEGIN
			PRINT 'Belirtilen turist bulunamadýðýndan güncelleme yapýlamadý.';
		END
	END
	ELSE
	BEGIN
		PRINT 'incorrect enter! Please enter a valid actions. insert / delete / change';
	END;
END;
GO






-- Fatura oluþturmak için Stored Procedure
CREATE PROCEDURE CreateInvoice
	@sale_id INT,
	@invoice_date DATE,
	@total_amount DECIMAL(10, 2)
AS
BEGIN
	-- Fatura numarasýný oluþtur
	DECLARE @invoice_number VARCHAR(20);

	SELECT @invoice_number = 'FTR' + CONVERT(VARCHAR(8), @invoice_date, 112) + RIGHT('000' + CAST((SELECT COUNT(*) + 1 FROM Invoices) AS VARCHAR(3)), 3);
	
	-- Fatura bilgilerini sisteme ekle
	INSERT INTO Invoices (sale_id, invoice_date, total_amount)
	VALUES (@sale_id, @invoice_date, @total_amount);
	
	-- Fatura bilgilerini metin dosyasýna yaz
	DECLARE @invoice_text VARCHAR(MAX);
	
	SET @invoice_text = ('Fatura No: ' + @invoice_number + CHAR(9) +  CHAR(9) +
					   'Fatura Kesilme Tarihi: ' + CONVERT(VARCHAR(10), @invoice_date, 104) + CHAR(9) + CHAR(9) +
					   'Turist: ' + (SELECT tourist_name + ' ' + tourist_surname FROM TourSales ts INNER JOIN Tourists t ON ts.tourist_id = t.tourist_id WHERE sale_id = @sale_id) + CHAR(9) + CHAR(9) +
					   'Toplam tutar: ' + CONVERT(VARCHAR(10), @total_amount));
	
	-- Fatura bilgilerini metin dosyasýna yaz
	DECLARE @file_path VARCHAR(100) = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\Fatura\' + @invoice_number + '.txt';
	
	-- Dosyaya yazma iþlemi
	DECLARE @sql VARCHAR(MAX) = 'EXEC xp_cmdshell ''echo ' + @invoice_text + ' > "' + @file_path + '"''';
	EXEC (@sql);
END;
GO



-- Tur satýþýný sisteme eklemek için Stored Procedure
CREATE PROCEDURE InsertTourSale
	@tour_name VARCHAR(150),
	@tourist_name VARCHAR(20),
	@tourist_surname VARCHAR(40),
	@gender CHAR(1),
	@birth_date DATE,
	@nationality VARCHAR(50),
	@country VARCHAR(50),
	@sale_date DATE,
	@guide_id INT
AS
BEGIN
	-- Turisti kontrol et ve varsa turiste ekle, yoksa yeni turist kaydý oluþtur
	DECLARE @tourist_id INT;

	IF EXISTS (SELECT * FROM Tourists WHERE tourist_name = @tourist_name AND tourist_surname = @tourist_surname)
	BEGIN
		SET @tourist_id = (SELECT tourist_id FROM Tourists WHERE tourist_name = @tourist_name AND tourist_surname = @tourist_surname);
	END
	ELSE
	BEGIN
		INSERT INTO Tourists (tourist_name, tourist_surname, gender, birth_date, nationality, country)
		VALUES (@tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country);
		
		SET @tourist_id = SCOPE_IDENTITY();
	END

	-- Tur satýþýný ve ilgili bilgileri sisteme ekle
	DECLARE @tour_id INT;
	DECLARE @total_amount DECIMAL(10, 2);

	SELECT @tour_id = tour_id FROM Tours WHERE tour_name = @tour_name;

	INSERT INTO TourSales (tour_id, tourist_id, sale_date, guide_id)
	VALUES (@tour_id, @tourist_id, @sale_date, @guide_id);

	-- Toplam tutarý hesapla	
	DECLARE @sale_id INT;
	SET @sale_id = SCOPE_IDENTITY();

	SELECT @total_amount = SUM (t.tour_fee) FROM Tours t JOIN TourSales ts on t.tour_id = ts.tour_id WHERE ts.sale_id = @sale_id;

	DECLARE @invoice_date DATE;
	SET @invoice_date = GETDATE();
	-- Fatura oluþtur
	EXEC CreateInvoice @sale_id = @sale_id, @invoice_date = @invoice_date, @total_amount = @total_amount;
END;
GO







