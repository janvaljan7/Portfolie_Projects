
-- Looking at Total cases vs Total Deaths
-- Show likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, ((CONVERT(DECIMAL(15,3),total_deaths)/CONVERT(DECIMAL(15,3),total_cases))*100) AS DeathPercentage
FROM portfolio..CovidDeaths
Where location like '%states%'
ORDER BY 1,2

-- Looking at Total cases vs Population
-- Shows what percentate of population got covid

SELECT Location, date, Population, total_cases, ((CONVERT(DECIMAL(15,3),total_cases)/CONVERT(DECIMAL(15,3),population))*100) AS InfectionPercentage
FROM portfolio..CovidDeaths
Where location like '%states%'
ORDER BY 1,2

-- Looking at Max of covid cases and their Infection Rate based on Country: 

SELECT Location, Population, MAX(CONVERT(DECIMAL(15,3),total_cases)) as Highest_Cases, MAX((CONVERT(DECIMAL(15,3),total_cases)/CONVERT(DECIMAL(15,3),population))*100) AS HighestInfectionPercentage
FROM portfolio..CovidDeaths

Group by location, Population
ORDER BY HighestInfectionPercentage desc

-- Show Highest Deaths by continent: 
SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM portfolio..CovidDeaths
Where continent is null
Group by location
ORDER BY TotalDeathCount desc

-- Wrong Continet Deaths, Just for Tableu visualization- Max country in each continent:
SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM portfolio..CovidDeaths
Where continent is not null
Group by continent
ORDER BY TotalDeathCount desc


--Showing Countrie with Highest Death Count per Country: 
SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM portfolio..CovidDeaths
Where continent is not null
Group by Location
ORDER BY TotalDeathCount desc

-- Global Numbers

SELECT SUM(new_cases) as total_cases, SUM(Cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM portfolio..CovidDeaths
Where continent is not null
ORDER BY 1,2


-- Looking at Total population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(decimal(15,3),vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as RollingPeopleVaccinated 
FROM portfolio..CovidDeaths dea
Join portfolio..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE : 

with popVSvac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(decimal(15,3),vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as RollingPeopleVaccinated 
FROM portfolio..CovidDeaths dea
Join portfolio..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(RollingPeopleVaccinated/population)*100
from popVSvac



-- Temp Table: 

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(decimal(15,3),vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as RollingPeopleVaccinated 
FROM portfolio..CovidDeaths dea
Join portfolio..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3


select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated




-- Creating View to store data for later visualizations


DROP VIEW PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated 
as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(decimal(15,3),vac.new_vaccinations)) over (partition by dea.location order by dea.location
, dea.date) as RollingPeopleVaccinated 
FROM portfolio..CovidDeaths dea
Join portfolio..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

SELECT * FROM PercentPopulationVaccinated





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








