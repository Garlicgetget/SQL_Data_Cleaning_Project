USE Data_Cleaning;

SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`;


#Standardize date format
SELECT 
    SaleDate
FROM
    Data_Cleaning.`nashville housing data`;

UPDATE Data_Cleaning.`nashville housing data` 
SET 
    SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y');

SELECT 
    SaleDate
FROM
    Data_Cleaning.`nashville housing data`;


#Investigate the empty cells under Propertyaddress column
SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`
ORDER BY ParcelID;

SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`
WHERE PropertyAddress =''
ORDER BY ParcelID;

SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`
WHERE
    ParcelID = '025 07 0 031.00';


#It seems we have multiple records under the same ParcelID-- we can populate the propertyaddress by referencing related rows that shared the same ParcelID with them
UPDATE Data_Cleaning.`nashville housing data`
SET PropertyAddress = NULL
WHERE PropertyAddress =''; 

SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM
    Data_Cleaning.`nashville housing data` a
        JOIN
    Data_Cleaning.`nashville housing data` b ON a.ParcelID = b.ParcelID
        AND a.UniqueID != b.UniqueID
WHERE
    a.PropertyAddress IS NULL;

UPDATE Data_Cleaning.`nashville housing data` a
        JOIN
    Data_Cleaning.`nashville housing data` b ON a.ParcelID = b.ParcelID
        AND a.UniqueID != b.UniqueID 
SET 
    a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE
    a.PropertyAddress IS NULL;


#Breaking out property address into individual columns(address, city, state)
SELECT 
    PropertyAddress
FROM
    Data_Cleaning.`nashville housing data`;

SELECT 
    SUBSTRING(PropertyAddress, 1,
        POSITION(',' IN PropertyAddress) - 1) AS Address_1,
    SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, CHAR_LENGTH(PropertyAddress)) AS Address_2
FROM
    Data_Cleaning.`nashville housing data`;

ALTER TABLE Data_Cleaning.`nashville housing data`
ADD Property_Address NVARCHAR(255);

UPDATE Data_Cleaning.`nashville housing data`
SET Property_Address = SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1);

ALTER TABLE Data_Cleaning.`nashville housing data`
ADD Property_City NVARCHAR(255);

UPDATE Data_Cleaning.`nashville housing data`
SET Property_City = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, CHAR_LENGTH(PropertyAddress));

SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`;


#---------------------Apply Second Method to Conduct Same Procedure ON Owneraddress Column---------------------------
Select OwnerAddress
FROM
    Data_Cleaning.`nashville housing data`;

SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1),
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
    SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM
    Data_Cleaning.`nashville housing data`;

ALTER TABLE Data_Cleaning.`nashville housing data`
ADD Owner_Address NVARCHAR(255);

UPDATE Data_Cleaning.`nashville housing data`
SET Owner_Address = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE Data_Cleaning.`nashville housing data`
ADD Owner_City NVARCHAR(255);

UPDATE Data_Cleaning.`nashville housing data`
SET Owner_City = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE Data_Cleaning.`nashville housing data`
ADD Owner_State NVARCHAR(255);

UPDATE Data_Cleaning.`nashville housing data`
SET Owner_State = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`;


#Modify unaligned "Y" and "N" in "Sold as Vacant" field
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM
    Data_Cleaning.`nashville housing data`
GROUP BY SoldAsVacant
ORDER BY Count(SoldAsVacant);

Select SoldAsVacant,
 CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM
    Data_Cleaning.`nashville housing data`;
    
UPDATE Data_Cleaning.`nashville housing data`
SET SoldAsVacant = 
CASE 
       WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
END;

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM
    Data_Cleaning.`nashville housing data`
GROUP BY SoldAsVacant
ORDER BY Count(SoldAsVacant); 

#remove duplicates
SELECT * FROM Data_Cleaning.`nashville housing data`;

WITH RowNum AS (Select *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,SalePrice, SaleDate, LegalReference
				 ORDER BY UniqueID) row_num
FROM Data_Cleaning.`nashville housing data`)
SELECT * FROM RowNum
WHERE row_num >1
ORDER BY PropertyAddress;

WITH RowNum AS (Select *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,SalePrice, SaleDate, LegalReference) row_num
FROM Data_Cleaning.`nashville housing data`)
DELETE FROM RowNum
WHERE row_num >1;#not updatable              

CREATE VIEW nashville_housing_data_cleaned AS
SELECT 
    *
FROM
    Data_Cleaning.`nashville housing data`
WHERE
    UniqueID NOT IN (SELECT 
    t1.UniqueID
FROM
    Data_Cleaning.`nashville housing data` t1
        JOIN
    Data_Cleaning.`nashville housing data` t2 ON t1.ParcelID = t2.ParcelID
        AND t1.PropertyAddress = t2.PropertyAddress
        AND t1.SalePrice = t2.SalePrice
        AND t1.SaleDate = t2.SaleDate
        AND t1.LegalReference = t2.LegalReference
        AND t1.UniqueID < t2.UniqueID);
        
SELECT * FROM nashville_housing_data_cleaned;

#remove unused columns
AlTER VIEW nashville_housing_data_cleaned AS 
SELECT UniqueID, ParcelID, LandUse, Property_Address, Property_City,SaleDate, SalePrice, 
       LegalReference, SoldAsVacant, OwnerName, Owner_Address, Owner_City, Owner_State, Acreage, 
	   LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath FROM Data_Cleaning.`nashville housing data`
WHERE
    UniqueID NOT IN (SELECT 
    t1.UniqueID
FROM
    Data_Cleaning.`nashville housing data` t1
        JOIN
    Data_Cleaning.`nashville housing data` t2 ON t1.ParcelID = t2.ParcelID
        AND t1.PropertyAddress = t2.PropertyAddress
        AND t1.SalePrice = t2.SalePrice
        AND t1.SaleDate = t2.SaleDate
        AND t1.LegalReference = t2.LegalReference
        AND t1.UniqueID < t2.UniqueID);
