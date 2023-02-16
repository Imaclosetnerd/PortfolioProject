Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..Covid_Deaths
Where continent is not null
Order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of death if you contract Covid in your country.

Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..Covid_Deaths
Where location like '%states%'
order by location,date

--Looking at the total cases vs population
--Shows percentage of population who has gotten Covid

Select Location,date,total_cases,Population, (total_cases/Population)*100 as PercentPopulationAffected
FROM PortfolioProject..Covid_Deaths
--Where location like '%states%'
--Where continent is not null
ORDER BY location,date

--Looking at countries with highest infection rate compared to population

Select Location,Population,MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population))*100 as PercentPopulationAffected
FROM PortfolioProject..Covid_Deaths
--Where location like '%states'
Where continent is not null
group by Location,Population
ORDER BY PercentPopulationAffected desc

--Looking at countries with highest death count per population
--cast is used to changee data type to int (or integer)

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..Covid_Deaths
--Where location like '%states'
Where continent is not null
group by Location
ORDER BY TotalDeathCount desc

--Looking at data based on continent

Select Continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..Covid_Deaths
--Where location like '%states'
Where continent is not null
group by Continent
ORDER BY TotalDeathCount desc


-- Global numbers

--Per Day
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/(SUM(New_cases))*100 
as DeathPercentage
FROM PortfolioProject..Covid_Deaths
--Where location like '%states'
Where continent is not null
group by date
order by 1,2


Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/(SUM(New_cases))*100 
as DeathPercentage
FROM PortfolioProject..Covid_Deaths
--Where location like '%states'
Where continent is not null
--group by date
order by 1,2


--Looking at Total Population vs Vaccinations
-- "dea" is only an alias for CovidDeaths table
-- "vac" is only an alias for CovidVaccinations table

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, 
dea.Date) as RollingNumberofVaccinations
FROM PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--Looking at percent of population that is vaccinated


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, 
dea.Date) as RollingNumberofVaccinations
(RollingNumberofVaccinations/population)*100
FROM PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- Use CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingNumberofVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, 
dea.Date) as RollingNumberofVaccinations
--(RollingNumberofVaccinations/population)*100
FROM PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)
Select *,(RollingNumberofVaccinations/cast(Population as float))*100
FROM PopvsVac


--TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
If Object_ID('tempdb...#PercentPopulationVaccinated') IS NULL
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingNumberofVaccinations numeric,
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, 
dea.Date) as RollingNumberofVaccinations
--(RollingNumberofVaccinations/population)*100
FROM PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

Select *,(RollingNumberofVaccinations/cast(Population as float))*100
FROM #PercentPopulationVaccinated



-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingNumberofVaccinations
--, (RollingNumberofVaccinations/population)*100
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
