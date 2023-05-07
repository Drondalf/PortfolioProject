/*
Cleaning data in SQL Queries
*/
SELECT *
FROM PortfolioProject..NashvilleHousing



/*
Standardize Date Format
*/
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

-- Тип данных не изменился
--UPDATE PortfolioProject..NashvilleHousing
--SET SaleDate = CONVERT(Date, SaleDate)

-- Добавление нового столбца с типом данных Date, без значений (NULL)
ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date;

-- Изменение значений в столбце SaleDateConverted
UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)



/*
Populate Property Address data
*/

SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

-- Выбор адресов со значением NULL
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Обновление значений адреса на адрес из строки с такимже ParceID но разным UniqueID
-- Как вариант вместо NULL указать "Адрес не указан"
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



/*
Breaking out address into individual columns (Address, City, State)
*/

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

-- Разбивка строки с адресом на по символу ","
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

-- Добавление нового столбца
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

-- Обновление значений
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Проверка результата
SELECT *
FROM PortfolioProject..NashvilleHousing

-- Другой способ
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

-- Разбивка строки с помощью PARSNAME (видимо есть нюанс, если часть имени превысит 128 символов, то вернется NULL, т.к. функция предназначена для работы с именами объектов)
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

-- Добавление нового столбца
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255);

-- Обновление значений
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Проверка
SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing

SELECT *
FROM PortfolioProject..NashvilleHousing



/*
Change Y and N to Yes and No in "Sold as Vacant" field
*/

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Список условий для замены символов
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject..NashvilleHousing

-- Изменение данных
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- Проверка
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

/*
Remove Duplicates (удаление данных не самая лучая идея как мне кажется, но нужна практика)
*/

-- Использование CTE и функции ROW_NUMBER для поиска одинаковых строк с разным UniqueID
WITH RowNumCTE
AS
(
SELECT *
, ROW_NUMBER()
OVER (
	PARTITION BY
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY
			UniqueID
) row_num
FROM PortfolioProject..NashvilleHousing
)

-- Проверка поиска
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Удаление строк
--DELETE
--FROM RowNumCTE
--WHERE row_num > 1



/*
Delete unused columns (удаление данных не самая лучая идея как мне кажется, но нужна практика)
*/

SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate
