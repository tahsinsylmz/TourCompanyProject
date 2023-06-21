-- Ayný isimde database var mý kontrol edilir
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TourCompany0')
BEGIN
	-- Database yoksa yaratýlýr
	CREATE DATABASE TourCompany0
END
GO

-- Database kullanýlýr
USE TourCompany0
GO

-- Tablolar yoksa yaratýlýr
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Tours')
BEGIN
    
	-- Tablolar, kolonlarý, ve PRIMARY-FOREIGN KEY baðlantýlarý oluþturulur.
	-- Her tablonun id kolonunda identity specification(1,1) aktif yapýlýr.

	-- Turlar tablosunu oluþturma
	CREATE TABLE Tours (
		tour_id INT IDENTITY(1, 1) PRIMARY KEY,
		tour_name VARCHAR(150),
		tour_fee DECIMAL(10, 2)
	);

	-- Bölgeler tablosunu oluþturma
	CREATE TABLE Regions (
		region_id INT IDENTITY(1, 1) PRIMARY KEY,
		region_name VARCHAR(30),
		region_fee DECIMAL(10, 2)
	);

	-- Taþýtlar tablosu oluþturma
	CREATE TABLE Vehicles (
		vehicle_id INT IDENTITY(1, 1) PRIMARY KEY,
		vehicle_name VARCHAR(30),
		vehicle_capacity INT,
		vehicle_fee DECIMAL(10, 2)
	);

	-- Hizmetler tablosunu oluþturma

	CREATE TABLE Services1 (
		service_id INT IDENTITY(1, 1) PRIMARY KEY,
		tour_id INT,
		region_id INT,
		vehicle_id INT,
		service_fee DECIMAL(10, 2),
		FOREIGN KEY (tour_id) REFERENCES Tours(tour_id),
		FOREIGN KEY (region_id) REFERENCES Regions(region_id),
		FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)
	);

	-- Rehberler tablosunu oluþturma
	CREATE TABLE Guides (
		guide_id INT IDENTITY(1, 1) PRIMARY KEY,
		guide_name VARCHAR(20),
		guide_surname VARCHAR(40),
		gender CHAR(1),
		phone_number VARCHAR(20),
		languages VARCHAR(100)
	);

	-- Turistler tablosunu oluþturma
	CREATE TABLE Tourists (
		tourist_id INT IDENTITY(1, 1) PRIMARY KEY,
		tourist_name VARCHAR(20),
		tourist_surname VARCHAR(40),
		gender CHAR(1),
		birth_date DATE,
		nationality VARCHAR(50),
		country VARCHAR(50)
	);

	-- Tur Satýþlarý tablosunu oluþturma
	CREATE TABLE TourSales (
		sale_id INT IDENTITY(1, 1) PRIMARY KEY,
		tour_id INT,
		tourist_id INT,
		sale_date DATE,
		guide_id INT,
		FOREIGN KEY (tour_id) REFERENCES Tours(tour_id),
		FOREIGN KEY (tourist_id) REFERENCES Tourists(tourist_id),
		FOREIGN KEY (guide_id) REFERENCES Guides(guide_id)
	);

	-- Faturalar tablosunu oluþturma
	CREATE TABLE Invoices (
		invoice_id INT IDENTITY(1, 1) PRIMARY KEY,
		sale_id INT,
		invoice_date DATE,
		total_amount DECIMAL(10, 2),
		FOREIGN KEY (sale_id) REFERENCES TourSales(sale_id)
	);

END
GO


-- Database var mý kontrol edilir
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'TourCompany0')
BEGIN
	-- Tablolar var mý kontrol edilir
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Tours')
	BEGIN
		-- Database kullanýlýr
		USE TourCompany0
		
		-- Tablonun baþlangýç deðerleri yoksa oluþturulur.
		IF NOT EXISTS (SELECT * FROM Tours WHERE tour_id = 1)
		BEGIN
		
			-- Bölgeler için baþlangýç verileri ekleme
			INSERT INTO Regions (region_name, region_fee)
			VALUES 
				('Sultanahmet', 50.00),
				('Taksim', 30.00),
				('Kadýköy', 40.00),
				('Beyoðlu', 35.00),
				('Eminönü', 25.00),
				('Bosphorus', 60.00),
				('Topkapý', 20.00),
				('Hagia Sophia', 30.00),
				('Grand Bazaar', 25.00),
				('Galata Tower', 40.00);

			-- Taþýtlar için baþlangýç verileri ekleme
			INSERT INTO Vehicles (vehicle_name, vehicle_capacity, vehicle_fee)
			VALUES 
				('Bus', 30, 90.00),
				('Minivan', 15, 50.00),
				('Sedan', 5, 25.00),
				('Van', 20, 70.00),
				('Coach', 50, 150.00);


			-- Tur isimleri için baþlangýç verileri ekleme
			INSERT INTO Tours (tour_name)
			VALUES 
				('Golden City Tour'),
				('Sunset Cruise Adventure'),
				('Historical Gems Excursion'),
				('Mystical Bosphorus Journey'),
				('Cultural Delights Exploration'),
				('Epic Landmarks Expedition');

			-- Services için fiyatlarý hariç bölgeler ve araçlarý turlarla eþleþtiren veriler ekleme
			INSERT INTO Services1 (tour_id, region_id, vehicle_id)
			VALUES
				(1, 1, 2),
				(1, 2, 2),
				(2, 3, 1),
				(3, 1, 4),
				(3, 4, 4),
				(3, 5, 4),
				(4, 1, 3),
				(4, 2, 3),
				(4, 3, 3),
				(5, 2, 5),
				(6, 4, 1),
				(6, 5, 1),
				(6, 6, 1);

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


			-- Turistler için baþlangýç deðerlerini oluþturma

			INSERT INTO Tourists (tourist_name, tourist_surname, gender, birth_date, nationality, country)
			VALUES
				('John', 'Doe', 'E', '1990-05-15', 'American', 'USA'),
				('Emma', 'Smith', 'K', '1992-08-21', 'British', 'UK'),
				('Michael', 'Johnson', 'E', '1985-11-02', 'Canadian', 'Canada'),
				('Sophia', 'Brown', 'K', '1988-04-18', 'Australian', 'Australia'),
				('Daniel', 'Taylor', 'E', '1993-07-10', 'German', 'Germany'),
				('Olivia', 'Anderson', 'K', '1991-09-27', 'French', 'France'),
				('James', 'Wilson', 'E', '1987-12-04', 'Italian', 'Italy'),
				('Emily', 'Martinez', 'K', '1994-03-12', 'Spanish', 'Spain'),
				('Matthew', 'Thompson', 'E', '1990-06-25', 'Mexican', 'Mexico'),
				('Ava', 'Garcia', 'K', '1992-10-08', 'Brazilian', 'Brazil'),
				('David', 'Lee', 'E', '1986-01-17', 'Chinese', 'China'),
				('Mia', 'Lopez', 'K', '1989-05-03', 'Japanese', 'Japan'),
				('Joseph', 'Harris', 'E', '1995-08-19', 'Indian', 'India'),
				('Amelia', 'Clark', 'K', '1993-11-07', 'Russian', 'Russia'),
				('Daniel', 'Lewis', 'E', '1988-02-23', 'Turkish', 'Turkey'),
				('Elizabeth', 'Walker', 'K', '1991-07-15', 'Greek', 'Greece'),
				('Andrew', 'Green', 'E', '1987-10-30', 'Swedish', 'Sweden'),
				('Sofia', 'Young', 'K', '1994-01-12', 'Dutch', 'Netherlands'),
				('William', 'Turner', 'E', '1990-04-26', 'Swiss', 'Switzerland'),
				('Charlotte', 'Scott', 'K', '1992-09-14', 'Polish', 'Poland'),
				('Christopher', 'Hall', 'E', '1985-12-01', 'Portuguese', 'Portugal'),
				('Ella', 'King', 'K', '1988-03-18', 'Argentinian', 'Argentina'),
				('Daniel', 'Baker', 'E', '1993-06-30', 'Chilean', 'Chile'),
				('Grace', 'Ward', 'K', '1991-10-07', 'Peruvian', 'Peru'),
				('Benjamin', 'Hill', 'E', '1987-01-21', 'Colombian', 'Colombia');


			-- Rehberler(Guides) için baþlangýç deðerlerini oluþturma

			INSERT INTO Guides (guide_name, guide_surname, gender, phone_number, languages)
			VALUES
				('John', 'Doe', 'E', '555-1234', 'English'),
				('Emma', 'Smith', 'K', '555-5678', 'French'),
				('Michael', 'Johnson', 'E', '555-9876', 'Spanish'),
				('Sophia', 'Brown', 'K', '555-4321', 'German'),
				('Daniel', 'Taylor', 'E', '555-8765', 'Italian'),
				('Olivia', 'Anderson', 'K', '555-3456', 'Russian'),
				('James', 'Wilson', 'E', '555-6543', 'Chinese'),
				('Emily', 'Martinez', 'K', '555-7890', 'Japanese'),
				('Matthew', 'Thompson', 'E', '555-2345', 'English'),
				('Ava', 'Garcia', 'K', '555-6789', 'Greek');


			-- TourSales için baþlangýç deðerleri oluþturma

			INSERT INTO TourSales (tour_id, tourist_id, sale_date, guide_id)
			VALUES
			  (1, 3, '2022-05-15', 2),
			  (1, 8, '2022-05-15', 2),
			  (1, 13, '2022-05-15', 2),
			  (1, 20, '2022-05-15', 2),
			  (1, 25, '2022-05-15', 2),
			  (1, 2, '2022-05-15', 2),
			  (1, 1, '2022-05-15', 2),
			  (1, 21, '2022-05-15', 2),
			  (1, 22, '2022-05-15', 2),
			  (2, 6, '2022-08-21', 5),
			  (2, 11, '2022-08-21', 5),
			  (2, 16, '2022-08-21', 5),
			  (2, 21, '2022-08-21', 5),
			  (2, 24, '2022-08-21', 5),
			  (3, 2, '2023-01-02', 7),
			  (3, 9, '2023-01-02', 7),
			  (3, 14, '2023-01-02', 7),
			  (3, 19, '2023-01-02', 7),
			  (3, 22, '2023-01-02', 7),
			  (3, 11, '2023-01-02', 7),
			  (3, 18, '2023-01-02', 7),
			  (3, 4, '2023-01-02', 7),
			  (3, 24, '2023-01-02', 7),
			  (3, 6, '2023-01-02', 7),
			  (3, 7, '2023-01-02', 7),
			  (3, 5, '2023-01-02', 7),
			  (3, 20, '2023-01-02', 7),
			  (3, 15, '2023-01-02', 7),
			  (3, 8, '2023-01-02', 7),
			  (4, 5, '2023-04-18', 3),
			  (4, 12, '2023-04-18', 3),
			  (4, 17, '2023-04-18', 3),
			  (4, 23, '2023-04-18', 3),
			  (4, 25, '2023-04-18', 3),
			  (4, 4, '2023-04-18', 3),
			  (4, 1, '2023-04-18', 3),
			  (4, 11, '2023-04-18', 3),
			  (4, 9, '2023-04-18', 3),
			  (4, 13, '2023-04-18', 3),
			  (4, 18, '2023-04-18', 3),
			  (2, 17, '2023-05-21', 5),
			  (2, 21, '2023-05-21', 5),
			  (2, 3, '2023-05-21', 5),
			  (2, 7, '2023-05-21', 5),
			  (2, 3, '2023-05-21', 5),
			  (2, 13, '2023-05-21', 5),
			  (2, 23, '2023-05-21', 5),
			  (2, 8, '2023-05-21', 5);


			-- Geçmiþ faturalar için baþlangýç deðerleri oluþturma 
			-- (faturalar turlarýn düzenlendiði tarihten 1 ay önce oluþturuldu.)

			INSERT INTO Invoices (sale_id, invoice_date, total_amount)
			SELECT ts.sale_id, DATEADD(MONTH, -1, ts.sale_date), t.tour_fee
			FROM TourSales ts
			JOIN Tours t ON ts.tour_id = t.tour_id;
		END
	END
END

