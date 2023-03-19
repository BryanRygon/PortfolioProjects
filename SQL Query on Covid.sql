-- Select Data that we are going to be using, information extracted accurate as at 15 March 2023.

Select location, date, total_cases, new_cases, total_deaths, population
From dbo.CovidDeaths
Where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths (Error shows up as total cases and total deaths are NVARCHAR)

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)
From dbo.CovidDeaths
Where continent is not null
order by 1,2

-- Resolving issue with Cast, and casting them as FLOAT (Could not use INT as the decimal places will be cut off, resulting in inaccurate results)
-- Added in location being Singapore, shows likelihood of dying if contracted Covid in Singapore
SELECT location, date, total_cases, total_deaths, 
       (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM dbo.CovidDeaths
Where location like '%Singap%' and continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select location, date, population, total_cases,
	(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))*100 AS InfectionPercentage
From dbo.CovidDeaths
Where location like '%Singap%' and continent is not null
ORDER BY 1,2

-- Looking at Countries with highest infection rate compared to Population

Select location, population, MAX(total_cases) as HighestInfectionCount,
	MAX((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)))*100 AS InfectionPercentage
From dbo.CovidDeaths
Where continent is not null
Group BY Location, Population
ORDER BY InfectionPercentage DESC


-- Showing countries with Highest Death Count per Population (Cast as int as it is in nvarchar)

Select Location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
From dbo.CovidDeaths
Where continent is not null
Group BY Location
ORDER BY TotalDeathCount DESC

-- Break things down by Continent
-- Showing the Continent with the Highest Death Count

Select Continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
From dbo.CovidDeaths
Where continent is not null
Group BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers (had to use a Case statement here as there were values being divided by 0)
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE (SUM(new_deaths) / SUM(new_cases)) * 100
    END AS DeathPercentage
FROM CovidProject..CovidDeaths
--Where location like '%Singap%'
Where continent is not null
ORDER BY 1,2


--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as FLOAT)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated,
	(Rolling_People_Vaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date =vac.date
Where dea.continent is not null
ORDER BY 2,3


-- USE CTE
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as FLOAT)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date =vac.date
Where dea.continent is not null
--ORDER BY 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100 as 
From PopvsVac

-- Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as FLOAT)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date =vac.date
Where dea.continent is not null
--ORDER BY 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for visualisation (Note to create more views for tableau visualisation)

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as FLOAT)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date =vac.date
Where dea.continent is not null
--ORDER BY 2,3


Select *
From PercentPopulationVaccinated