Exec sp_help idsp_123;

SELECT * FROM aqi_123
SELECT * FROM idsp_123;
SELECT * FROM vahan_123;
SELECT * FROM population_projection_123;
 
--1. List the top 5 and bottom 5 areas with highest average AQI. (Consider areas 
--which contains data from last 6 months: December 2024 to May 2025) 



-- Top 5 highest AQI
SELECT area,Avg_AQI,'Top 5' As Category
FROM(
	SELECT TOP 5
				area,
				AVG(aqi_value) AS Avg_AQI
	FROM aqi_123
	WHERE date BETWEEN '2024-12-01' AND '2025-05-31'
			AND  aqi_value IS NOT NULL
	GROUP BY area
	ORDER BY Avg_AQI DESC
	) AS Top5

UNION ALL

-- Bottom 5 lowest AQI
SELECT  area,Avg_AQI,'Bottom 5' AS Category
FROM  (
		SELECT TOP 5
				 area,
				 AVG(aqi_value) AS Avg_AQI
		FROM 
			aqi_123
		WHERE
			  date BETWEEN '2024-12-01' AND '2025-05-31'
			  AND  aqi_value IS NOT NULL
		GROUP BY 
				area
		ORDER BY 
			  Avg_AQI ASC
) AS Bottom5

ORDER BY  Avg_AQI DESC;


--2. List out top 2 and bottom 2 prominent pollutants for each state of southern India. 
--(Consider data post covid: 2022 onwards)

WITH Pollutants as(
	SELECT 
	       state,
		   prominent_pollutants,
		   COUNT(*) As total_count,
		   ROW_NUMBER() OVER(PARTITION BY state ORDER BY count(*) DESC) AS rank_desc,
		   ROW_NUMBER() OVER(PARTITION BY state ORDER BY count(*) ASC) AS rank_asc
       
	FROM 
	    aqi_123
	where 
	    YEAR(date)>2022
	    AND state IN('Tamil Nadu','Kerala','Karnataka','Andhra Pradesh')
	    AND prominent_pollutants IS NOT NULL
	GROUP BY 
	    state,
		prominent_pollutants
	)
	
	SELECT state,
	       prominent_pollutants,
		   total_count, 
			CASE
			   WHEN rank_desc<= 2 THEN 'Top Pollutant'
			   WHEN rank_asc <= 2 THEN 'Bottom Pollutant'
			   END AS Pollutant_Category
	FROM Pollutants
	WHERE 
	      rank_desc<= 2 OR 
		  rank_asc <=2
	ORDER BY
	      state ASC,
		  total_count DESC;


--3. Does AQI improve on weekends vs weekdays in Indian metro cities (Delhi, 
--Mumbai, Chennai, Kolkata, Bengaluru, Hyderabad, Ahmedabad, Pune)? 
--(Consider data from last 1 year)

   select * from aqi_123;


SELECT area,
    CASE
	   WHEN DATENAME(WEEKDAY,date) IN('Saturday','Sunday') THEN 'Weekend'
	   ELSE 'WeekDay'
	   END AS Day_type,
    AVG(aqi_value) AS Avg_aqi
FROM 
    aqi_123
WHERE 
    area IN ('Delhi', 'Mumbai', 'Chennai', 'Kolkata', 'Bengaluru', 'Hyderabad', 'Ahmedabad', 'Pune')
    AND date>=DATEADD(YEAR,-1,CAST(GETDATE() AS date))
GROUP BY 
        area,
		CASE
		  WHEN DATENAME(WEEKDAY,date) IN('Saturday','Sunday') THEN 'Weekend'
		ELSE 'WeekDay'
   	    END
ORDER BY 
       Avg_aqi DESC ;

--4. Which months consistently show the worst air quality across Indian states — 
--(Consider top 10 states with high distinct areas)



WITH top_states AS(
				SELECT TOP 10
					   state,
					   COUNT(distinct area)AS total_areas
				FROM aqi_123
				GROUP BY state
				ORDER BY  total_areas DESC
),
 monthly_avg_aqi AS(
         select
		     state,
			 MONTH(date) as month_num,
			 DATENAME(MONTH,date) As month_name,
			 AVG(aqi_value) AS Avg_aqi
            FROM aqi_123
			where state in(select state from top_states)
			group by state,MONTH(date),DATENAME(MONTH,date)
),

monthwise_overall_avg AS (
          select 
		      month_num,
			  month_Name,
			  ROUND(AVG(Avg_aqi),2) AS overall_avg_aqi
          FROM monthly_avg_aqi
		  GROUP BY month_num,month_name
)
   
select* 
from 
    monthwise_overall_avg
ORDER BY
    overall_avg_aqi DESC;

--5. For the city of Bengaluru, how many days fell under each air quality category 
--(e.g., Good, Moderate, Poor, etc.) between March and May 2025?

select  
      air_quality_status,
	  DATENAME( MONTH,date) AS month_name,
     COUNT( Distinct date) as total_days
from 
     aqi_123
where 
     area ='Bengaluru'
     and date between '2025-03-01' and '2025-05-31'
	 and air_quality_status is not null
group by 
     air_quality_status,DATENAME( MONTH,date)
order by 
     total_days desc


--6. List the top two most reported disease illnesses in each state over the past three 
--years, along with the corresponding average Air Quality Index (AQI) for that period. 

	 select * from aqi_123
	 select * from idsp_123;

WITH diseaseCounts AS(
     SELECT 
	      state,
		  disease_illness_name,
		  COUNT(*) AS Total_cases
     FROM idsp_123
	 WHERE YEAR(reporting_date_clean) >=YEAR(GETDATE())-3
	 GROUP BY state,disease_illness_name
),
    RankedDiseases AS(
	SELECT
	     state,
		 disease_illness_name,
		 Total_cases,
		 ROW_NUMBER() over(PARTITION BY state ORDER BY Total_cases  DESC) AS rn
    FROM diseaseCounts
),
 
 AverageAQI AS(
     SELECT 
	     state,
		 AVG(aqi_value) AS Avg_AQI
    FROM aqi_123
	WHERE date >=DATEADD(YEAR,-3,GETDATE())
	GROUP BY state
	)
		 
          
SELECT
       r.state,
	   r.disease_illness_name,
	   a.avg_AQI,
	   r.Total_cases
FROM RankedDiseases r
join AverageAQI a on r.state = a.state 
WHERE r.rn <=2
ORDER BY r.state  ,a.Avg_AQI DESC


-- List the top 5 states with high EV adoption and analyse if their average AQI is 
--significantly better compared to states with lower EV adoption


SELECT * FROM aqi_123
select *  from vahan_123;


WITH Total_EV_Adoption AS (
    SELECT
		    state,
			COUNT(*) AS total_EV
	FROM vahan_123
	WHERE fuel 
		 IN (
			'PURE EV',
			'ELECTRIC(BOV)',
			'PLUG-IN HYBRID EV',
			'STRONG HYBRID EV',
			'PETROL/HYBRID',
			'DIESEL/HYBRID'
		) 
	GROUP BY 
	       state
	
),
  AQI_Average AS(
        SELECT 
			state,
			AVG(aqi_value) AS Avg_AQI
		FROM 
		    aqi_123
		GROUP BY 
		    state
),

Top_5 AS (

select top 5
        t_ev.state,
		t_ev.total_EV,
		avg.Avg_AQI,
		'Top_EV_States' as category
FROM AQI_Average avg
join Total_EV_Adoption t_ev on avg.state = t_ev.state
order by t_ev.total_EV desc
),

Bottom_5 AS (
		select top 5
				t_ev.state,
				t_ev.total_EV,
				avg.Avg_AQI,
				'Bottom_EV_States' as category
		FROM AQI_Average avg
		join Total_EV_Adoption t_ev on avg.state = t_ev.state
		order by t_ev.total_EV 
)

select * 
from Top_5
UNION ALL
Select *FROM Bottom_5
order by  total_EV DESC,category DESC;
 



--secondary analysis

--1. Which age group is most affected by air pollution-related health outcomes — and how 
--does this vary by city? 
     --As per my research what i found is the most effected age group by air pollution is
	 --less then  5 years especially leass then one year or  less then three months babies 
	 --are effecting so much and above 60 age also  and approximately 2.1 million deaths attributable to air pollution
	 --in 2021 Among these, 169,400 deaths were children under age five, Roughly half of 
	 --ozone-related COPD deaths globally occurred in India in that year (~237,000 deaths) 
	 --Delhi remains the most impacted city as of 2025.
  --  1.)10-city Lancet model provides strongest mortality estimates for 2021-level data.

  --  2.)Byrnihat and regional cities in Bihar, West Bengal, Assam are exhibiting extreme pollution levels in early 2025, indicating very high potential health burden.

  --  3.)Mortality sensitivity varies—cities like Bengaluru show higher risk per exposure unit even if absolute pollution is lower.



--2. Who are the major competitors in the Indian air purifier market, and what are their key 
--differentiators (e.g., price, filtration stages, smart features)?

--  The key compititors are 1.)Dyson,Philips, Xiamio,honeywell,Coway,Sharp there are the mojor air purifier companies
--if we can see the Dyson charging the high price and more features Xiamio is in lower price but not having some some features
-- we have to add in our product which is lacking  in most of the compnaies are 
-- 1.) app control or alert
-- 2.)provide digital AQI monitor
-- 3.)2in 1 purifier + humidifier(hot  + cool)
-- 4.)Offer universal Carbon filter
-- 5.) price range shoud be 12k to 18K



--3. What is the relationship between a city’s population size and its average AQI — do larger 
--cities always suffer from worse air quality? (Consider 2024 population and AQI data for 
--this) 


select * from aqi_123;
select * from population_projection_123;

WITH HIGH_POPULATION AS(
     SELECT state,
	        SUM(value) as total_papulation
     FROM population_projection_123
	 WHERE gender = 'Total'
	       and year = 2024
	      
	 GROUP BY state
	 ),

    Average_aqi AS(
	  SELECT 
	       state,
		   AVG(aqi_value) AS avg_AQI
     FROM aqi_123
	 where YEAR(date) = 2024
	 GROUP BY state
	 )
 SELECT top 10
        hp.state,
        hp.total_papulation,
        aq.avg_AQI
 FROM HIGH_POPULATION AS hp
 join Average_aqi AS aq 
      on hp.state = aq.state
 ORDER BY
      hp.total_papulation DESC,
	  aq.avg_AQI DESC;







--📊 Recommendation to Client
--Yes — there is a strong and growing need for air purifiers in India, especially in urban Tier 1 and Tier 2 cities.
--However, to succeed, the product must:

--Address real pain points (AQI display, VOC removal, app control)

--Be priced accessibly (₹10k–₹18k range)

--Be tailored to Indian homes (compact, low power, silent)

--Include seasonal or geo-targeted marketing (e.g., Diwali, stubble-burning months)

--	the componenets that you need to fix in the  Air Purifier is HEPA Filters for PM 2.5,PM10
--    and Corbon Filters for Natural Gases
--  you can start  marketing in most polluted area like 
--Byrnihat
--Delhi
--Hajipur
--Bahadurgarh
--Gurugram

-- the High air pollution is  in the months of November To March  so this is the high demand time for the air purifier that we can run our marketing campaigns.



	
	 




	      


    




	






