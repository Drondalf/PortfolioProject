-- Select all data
SELECT *
FROM PortfolioProject..CovidDeaths$
ORDER BY 3,4

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1, 2

-- Изменение типа данных столбцов total_cases and deaths из nvarchar в float (из-за символа ".")
--SELECT *
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'CovidDeaths$'
--AND COLUMN_NAME = 'total_deaths'

--ALTER TABLE PortfolioProject..CovidDeaths$
--ALTER COLUMN total_deaths float

-- Loocking at total_cases vs total_deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at total_cases vs population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
ORDER BY 1, 2

-- Looking at Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with highest death count per population
SELECT location, MAX(CAST(total_deaths AS bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
WHERE continent IS not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Showing contintents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--WHERE location like 'United States'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Изменение типа данных столбца new_cases и new_deaths из nvarchar в float (из-за символа ".")
--SELECT *
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'CovidDeaths$'
--AND COLUMN_NAME = 'new_deaths'

--ALTER TABLE PortfolioProject..CovidDeaths$
--ALTER COLUMN new_deaths float

-- GLOBAL NUMBERS
SELECT SUM(new_cases) NewCases, SUM(new_deaths) NewDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
AND new_cases <> 0 -- интересное поведение, см. ANSI_NULLS в случае NULL и еще допустимо !=
--GROUP BY date
ORDER BY 1



-- Looking at total population vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--USE CTE (common table expression)
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
-- в итоге есть страны с количеством привитого населения больше чем само население! Где-то ошибка

-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated
