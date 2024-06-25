
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




