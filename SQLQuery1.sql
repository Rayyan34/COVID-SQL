select *
from covid..CovidDeaths
where continent is not null
order by 3,4

select *
from covid..CovidVaccinations
where continent is not null
--order by 3,4

---- Select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from covid..CovidDeaths
where continent is not null
order by 1,2

---- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (cast(total_deaths as decimal) / nullif(cast(total_cases as decimal), 0))*100 as death_rate
from covid..CovidDeaths
where location = 'United States'
and continent is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select location, date,total_cases, population, (total_cases / nullif(population, 0))*100 as PercentofPopulationInfected
from covid..CovidDeaths
where location = 'United States'
and continent is not null
order by 1,2

-- Countries with the highest infection rate compared to population
-- Note: some people may have been infected more than once

select location, population, max(total_cases) as HighestInfectionCount, (max(total_cases) / NULLIF(population, 0)) * 100 as PercentofPopulationInfected
from covid..CovidDeaths
where continent is not null
group by location, population
order by 4 desc

-- Death rate vs Population
select location, max(total_deaths) as TotalDeathCount
from covid..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with the highest death count
select location, max(total_deaths) as TotalDeathCount
from covid..CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc



-- GLOBAL
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/nullif(sum(new_cases),0))*100 as death_percentage
from covid..CovidDeaths
where continent is not null
--group by date
order by 1,2


-- Join vaccinations table

Select * 
from covid..CovidDeaths dea
join covid..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date

-- Total population vs Vaccinations
-- How many people around the world have been vaccinated? Note: Some people may have been vaccinated more than once

-- Using a CTE

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_count_vaccinations)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations-- per day
, SUM(cast(new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations -- rolling sum
from covid..CovidDeaths dea
join covid..CovidVaccinations vac
on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
-- order by 2,3
)

Select *, (rolling_count_vaccinations/population)*100 as percent_vaxxed
from PopvsVac
order by 2,3

-- Temp Table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count_vaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_count_vaccinations
--, (RollingPeopleVaccinated/population)*100
From covid..CovidDeaths dea
Join covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (rolling_count_vaccinations/Population)*100
From #PercentPopulationVaccinated


-- Creating view to store data for visualizations

create view percent_population_vaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_count_vaccinations
--, (RollingPeopleVaccinated/population)*100
From covid..CovidDeaths dea
Join covid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3