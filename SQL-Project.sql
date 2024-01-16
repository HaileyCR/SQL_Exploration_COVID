--These queries were performed in Google BigQuery to explore and join data tables on COVID Deaths and Vaccinations


SELECT *
FROM `case-study-409701.Covid.covid_deaths` 
WHERE continent is not null 
ORDER BY 3,4;

--SELECT * 
--FROM `case-study-409701.Covid.covid_vaccines` 
--ORDER BY 3,4;

--Selecting Data that we will be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM `case-study-409701.Covid.covid_deaths` 
WHERE continent is not null 
ORDER BY 1,2;

--Looking at total cases vs total deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `case-study-409701.Covid.covid_deaths` 
ORDER BY 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
FROM `case-study-409701.Covid.covid_deaths` 
--Where location like '%states%'
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM `case-study-409701.Covid.covid_deaths` 
--Where location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc;

-- Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM `case-study-409701.Covid.covid_deaths` 
--Where location like '%states%'
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount desc;

-- Breaking down by continent

-- Showing contintents with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM `case-study-409701.Covid.covid_deaths` 
--Where location like '%states%'
WHERE continent is null 
GROUP BY location
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM `case-study-409701.Covid.covid_deaths` 
--Where location like '%states%'
WHERE continent is not null 
--Group By date
ORDER BY 1,2;

--Joining our tables

SELECT *
FROM `case-study-409701.Covid.covid_deaths` dea
JOIN `case-study-409701.Covid.covid_vaccines` vac
  ON dea.location = vac.location
  and dea.date = vac.date

--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM `case-study-409701.Covid.covid_deaths` dea
JOIN `case-study-409701.Covid.covid_vaccines` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null 

-- Using CTE

WITH RECURSIVE
PopvsVac as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM `case-study-409701.Covid.covid_deaths` dea
JOIN `case-study-409701.Covid.covid_vaccines` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (rolling_vaccinations/population)*100
FROM PopvsVac

-- Temp Table

CREATE TEMP TABLE
percent_population_vaccinated
(
continent string,
location string,
date date,
new_vaccinations float64,
population float64,
rolling_vaccinations float64
);

INSERT INTO percent_population_vaccinated
(
SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM `case-study-409701.Covid.covid_deaths` dea
JOIN `case-study-409701.Covid.covid_vaccines` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null 
);

SELECT *, (rolling_vaccinations/population)*100
FROM percent_population_vaccinated

--Creating view to store visualizations

Create View Covid.percent_population_vaccinated as 
SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM `case-study-409701.Covid.covid_deaths` dea
JOIN `case-study-409701.Covid.covid_vaccines` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null 

SELECT*
FROM Covid.percent_population_vaccinated
