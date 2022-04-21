/* Cleaning Data in SQL */

SELECT * 
FROM nashvillehousing;

-----------------------------------------------

-- Standardize Date Format

UPDATE nashvillehousing
SET SaleDate = STR_TO_DATE(SaleDate, '%M %D %Y');


ALTER TABLE nashvillehousing 
CHANGE COLUMN `SaleDate` `SaleDate` DATE NULL DEFAULT NULL ;

-----------------------------------------------

-- Populate Property Address Data

SELECT PropertyAddress
FROM nashvillehousing
WHERE PropertyAddress IS NULL
OR PropertyAddress = "";


UPDATE nashvillehousing
SET PropertyAddress = NULLIF(PropertyAddress, '');


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing AS a
JOIN nashvillehousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousing,
	(SELECT IFNULL(a.PropertyAddress, b.PropertyAddress) AS pa
	 FROM nashvillehousing AS a
	 JOIN nashvillehousing AS b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID) AS c
SET PropertyAddress = IFNULL(PropertyAddress, c.pa)
WHERE PropertyAddress IS NULL;

-----------------------------------------------

-- Break out Address into Individual Columns (Address, City, State)

# Property Adress
SELECT SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) -1) AS AddressNumber,
	   SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) +1, LENGTH(PropertyAddress)) AS Address
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD COLUMN PropertyStreetNumber VARCHAR(255);
UPDATE nashvillehousing
SET PropertyStreetNumber = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) -1);

ALTER TABLE nashvillehousing
ADD COLUMN PropertyCity VARCHAR(255);
UPDATE nashvillehousing
SET PropertyCity = SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) +1, LENGTH(PropertyAddress));

# Owner Address
SELECT OwnerAddress
FROM nashvillehousing
WHERE OwnerAddress IS NULL
OR OwnerAddress = "";

UPDATE nashvillehousing
SET OwnerAddress = NULLIF(OwnerAddress, '');

SELECT OwnerAddress
FROM nashvillehousing;

SELECT 	SUBSTRING_INDEX(OwnerAddress, ",", 1) AS street,
		SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1) AS city,
		SUBSTRING_INDEX(OwnerAddress, ",", -1) AS state
FROM nashvillehousing; 

ALTER TABLE nashvillehousing
ADD COLUMN OwnerStreetNumber VARCHAR(255);
UPDATE nashvillehousing
SET OwnerStreetNumber = SUBSTRING_INDEX(OwnerAddress, ",", 1);

ALTER TABLE nashvillehousing
ADD COLUMN OwnerCity VARCHAR(255);
UPDATE nashvillehousing
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1);

ALTER TABLE nashvillehousing
ADD COLUMN OwnerState VARCHAR(255);
UPDATE nashvillehousing
SET OwnerState = SUBSTRING_INDEX(OwnerAddress, ",", -1);

-----------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT DISTINCT SoldAsVacant, 
	CASE WHEN SoldAsVacant = "Y" THEN "Yes"
		 WHEN SoldAsVacant = "N" THEN "No"
         ELSE SoldAsVacant
         END AS SAV
FROM nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = "Y" THEN "Yes"
						WHEN SoldAsVacant = "N" THEN "No"
						ELSE SoldAsVacant
						END;
                        
-----------------------------------------------

-- Remove Duplicates

WITH rownumCTE AS (SELECT UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference,
						   ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
											  ORDER BY UniqueID) AS rownum
				   FROM nashvillehousing
				   ORDER BY ParcelID)
SELECT *
FROM rownumCTE
WHERE rownum > 1
ORDER BY ParcelID;

                    
DELETE t1
FROM nashvillehousing AS t1 
INNER JOIN nashvillehousing AS t2
ON t2.ParcelID = t1.ParcelID AND
   t2.PropertyAddress = t1.PropertyAddress AND
   t2.SalePrice = t1.SalePrice AND
   t2.SaleDate = t1.SaleDate AND
   t2.LegalReference = t1.LegalReference AND 
   t2.UniqueID < t1.UniqueID;
