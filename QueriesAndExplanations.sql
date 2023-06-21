/*
TABLOLAR

Regions(Bölgeler)
Vehicles(Taþýtlar)
Services1(Hizmettler) => Taþýt ve bölge ücretlerini toplayýp hizmet ücreti oluþturur.
Tours(Turlar) => Tur isimleri ve turla ilgili servis ücretlerinden tur ücretini oluþtur.
Guides(Rehberler)
Tourists(Turistler)
TourSales(Tur Satýþlarý) => Turlar, turistler, rehber ve satýþ tarhilerini barýndýrýr.
Invoices(Faturalar) => Satýþý yapýlan turlarý ve satýþ tarihlerini oluþturur.
*/


--TABLOLARDA OLUÞTURULAN SATIRLAR ÝÇÝN ÖRNEK SORGULAR

-- Düzenlenen turlar bölgeleri ve taþýt bilgisi.
SELECT t.tour_name, r.region_name, v.vehicle_name
FROM Services1 s
JOIN Tours t ON s.tour_id = t.tour_id
JOIN Regions r ON s.region_id = r.region_id
JOIN Vehicles v ON s.vehicle_id = v.vehicle_id


-- 'Historical Gems Excursion' turuna kayýtlý turistler.
SELECT tr.tourist_name, tr.tourist_surname
FROM Tourists tr
JOIN TourSales ts ON tr.tourist_id = ts.tourist_id
JOIN Tours t ON ts.tour_id = t.tour_id
WHERE t.tour_name = 'Historical Gems Excursion'


-- 300 TL den fazla olan turlarýn rehberlerinin bilgileri. cinsiyet | isim
SELECT DISTINCT g.gender, g.guide_name
FROM TourSales ts
JOIN Tours t ON ts.tour_id = t.tour_id
JOIN Guides g ON ts.guide_id = g.guide_id
WHERE t.tour_fee > 300




/*
PROSEDÜRLER
	--Mevcut kayýrlarý deðiþtirme yeni kayýt ekleme ve kayýt silme iþlemleri yapýlan prosedürler
		UpdateVehicles
		UpdateRegions
		UpdateGuides
		UpdateTourists
		UpdateTour
	
	--Satýþ iþlemleri ve faturalama yapan prosedürler
		CreateInvoice => Yapýlan satýþýn fatura bilgisini Invoices tablosuna ekler.
					  => Satýþ için fatura bilgisini barýndýran txt metin dosyasý oluþturur.
						 dosya adý Faturanýn adýný ve tablodaki sýralama bilgisini içerir.

		InsertTourSale => Satýþ yapmayý saðlar. Kayýtlý turistler isim soyisim bilgisi ile sistemden bulunabilir.
						  Yeni müþteriler sisteme kaydedilir. Satýþ sýrasýnda CreateInvoice prosedürü ile fatura oluþturulur.
*/


--PROSEDÜRLERÝN ÖRNEK KULLANIMI

	--UpdateRegions(@action, @region_name, @region_fee)

EXEC dbo.UpdateRegions 'insert', 'Beþiktaþ', 55.00;

EXEC dbo.UpdateRegions 'delete', 'Beþiktaþ';

EXEC dbo.UpdateRegions 'change', 'Beþiktaþ', 45.00;


	--UpdateVehicles(@action, @vehicle_name, @vehicle_capacity, @vehicle_fee)

EXEC dbo.UpdateVehicles 'insert', 'Tour Bus', 40, 120.00;


	--UpdateTour(@action, @tour_name, @vehicle_name, @region1_name, @region2_name, @region3_name)

EXEC dbo.UpdateTour 'delete', 'Sunset Cruise Adventure', NULL, NULL, NULL, NULL;
EXEC dbo.UpdateTour 'change', 'Golden City Tour', 'Bus', 'Bosphorus', 'Sultanahmet', 'Kadýköy';


	--UpdateGuides(@action, @guide_name, @guide_surname, @gender, @phone_number, @languages)

EXEC dbo.UpdateGuides 'change', 'Matthew', 'Tmpson', 'E', '541-2369', 'English, Franch';



	--UpdateTourists(@action, @tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country)

EXEC dbo.UpdateTourists 'delete', 'Benjamin', 'Hill', NULL, NULL, NULL, NULL;
EXEC dbo.UpdateTourists 'change', 'Ahmet', 'Yýlmaz', 'E', '1999-02-26', 'Garman', 'Germany'  


	--InsertTourSale(tour_name, tourist_name, tourist_surname, gender, birth_date, nationality, country, sale_date, guide_id)


EXEC dbo.InsertTourSale 'Cultural Delights Exploration', 'ssse', 'Aslan', 'K', '1996-11-23', 'Turkish', 'Turkey', '2023-07-11', 2;


	--Toplu satýþ yapmak için bu yöntem kullanýlabilir. Birden fazla turun birden fazla kayýtlý/kayýtsýz turiste satýþý yapýlýr.
DECLARE @operations TABLE (
    tour_name VARCHAR(150),
    tourist_name VARCHAR(20),
    tourist_surname VARCHAR(40),
    gender CHAR(1),
    birth_date DATE,
    nationality VARCHAR(50),
    country VARCHAR(50),
    sale_date DATE,
    guide_id INT
);

INSERT INTO @operations (tour_name, tourist_name, tourist_surname, gender, birth_date, nationality, country, sale_date, guide_id)
VALUES
    ('Golden City Tour', 'Sofi', 'Kiean', 'K', '1996-11-23', 'German', 'Germany', '2023-06-21', 2),
	('Cultural Delights Exploration', 'Ahmet', 'Yakut', 'E', '1987-11-23', 'Turkish', 'Turkey', '2023-07-11', 1),
    ('Golden City Tour', 'Ayse', 'Aslan', 'K', '1996-01-08', 'Turkish', 'Turkey', '2023-08-01', 3)
  
DECLARE @tour_name VARCHAR(150), @tourist_name VARCHAR(20), @tourist_surname VARCHAR(40), @gender CHAR(1), @birth_date DATE, @nationality VARCHAR(50), @country VARCHAR(50), @sale_date DATE, @guide_id INT;

DECLARE operations_cursor CURSOR FOR
    SELECT tour_name, tourist_name, tourist_surname, gender, birth_date, nationality, country, sale_date, guide_id
    FROM @operations;

OPEN operations_cursor;

FETCH NEXT FROM operations_cursor INTO @tour_name, @tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country, @sale_date, @guide_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.InsertTourSale @tour_name, @tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country, @sale_date, @guide_id;

    FETCH NEXT FROM operations_cursor INTO @tour_name, @tourist_name, @tourist_surname, @gender, @birth_date, @nationality, @country, @sale_date, @guide_id;
END;

CLOSE operations_cursor;
DEALLOCATE operations_cursor;

