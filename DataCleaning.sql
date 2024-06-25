--=============================================================================================================
--=============================================================================================================

-- Nashville Housing dataset, data cleaning by SQL :


-- Cleaning Data in SQL queries:

select * from portfolio..NashvilleHousing


-- Standardize Date Format

select Saledate, Convert(Date, saledate)
from portfolio..NashvilleHousing

Update NashvilleHousing 
SET Saledate = CONVERT(Date, Saledate)


-- OR We can add the new column and delete saledate later: 

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = Convert(Date, saledate)

--=================================================================================


-- Populate Property Address Data: 

--Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.propertyaddress, b.PropertyAddress)
--from portfolio..NashvilleHousing a
--join portfolio..NashvilleHousing b
--	on a.ParcelID = b.ParcelID
--where a.PropertyAddress is null
--and a.[UniqueID ] <> b.[UniqueID ]


Update c
SET c.propertyaddress = ISNULL(c.propertyaddress, b.propertyaddress)
from NashvilleHousing c
join NashvilleHousing b 
	on c.ParcelID = b.ParcelID
	and c.PropertyAddress is null
where c.[UniqueID ] <> b.[UniqueID ]


--==============================================================================


-- Breaking Address into different columns(Address, City, State)

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as Address
From portfolio.dbo.NashvilleHousing

-- Now the edit of table is like below, just execute alter and update seperately: 

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))



-- Splitting Owner address with ParsName:

Select OwnerAddress
From portfolio.dbo.NashvilleHousing

Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
From portfolio.dbo.NashvilleHousing



ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)


ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)



--=========================================================================


-- Change Y and N to Yes and No in "Sold as Vacant" field

select Distinct(SoldasVacant), Count(SoldasVacant)
from portfolio.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2



Select SoldasVacant 
, CASE when SoldasVacant = 'Y' Then 'Yes'
	   when SoldasVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From portfolio.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE when SoldasVacant = 'Y' Then 'Yes'
	   when SoldasVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END


--=======================================================================


-- Remove Duplicates: 
WITH RowNumCTE AS(

Select *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
						UniqueID
						) row_num

From portfolio.dbo.NashvilleHousing
--order by ParcelID
)
--DELETE
select *
From RowNumCTE
where row_num > 1


--=========================================================================


-- Delete Unused Columns: 

Select * 
From portfolio.dbo.NashvilleHousing


ALTER TABLE portfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

