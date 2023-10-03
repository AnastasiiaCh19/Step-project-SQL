# Завдання 1. Покажіть середню зарплату співробітників за кожен рік, до 2005 року.

SELECT
    YEAR(from_date) AS salary_year,
    AVG(salary) AS avg_salary
FROM salaries
WHERE YEAR(from_date) < 2005
GROUP BY salary_year
ORDER BY salary_year
;


# Завдання 2. Покажіть середню зарплату співробітників по кожному відділу.
-- Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників

# Спосіб 1
SELECT
    d.dept_name AS department,
    AVG(s.salary) AS avg_salary
FROM dept_emp AS de
JOIN departments AS d ON (de.dept_no = d.dept_no) -- об'єднуємо таблиці dept_emp, departments
JOIN salaries AS s ON (de.emp_no = s.emp_no) -- об'єднуємо з salaries для визначення поточного відділу та поточної зарплати кожного співробітника
WHERE CURDATE() BETWEEN de.from_date AND de.to_date
GROUP BY department
ORDER BY department
;-- обчислюємо середню зарплату для кожного відділу і виводимо результати


# Спосіб 2
WITH AvgSalaries_cte AS (
    SELECT
        d.dept_name AS department,
        s.salary,
        AVG(s.salary) OVER (PARTITION BY de.dept_no) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
    WHERE CURDATE() BETWEEN de.from_date AND de.to_date
) -- ми спершу створюємо спільну таблицю з назвами відділів, зарплатами та середньою зарплатою кожного співробітника відділу

SELECT DISTINCT department, avg_salary
FROM AvgSalaries_cte
ORDER BY department
; -- Потім ми вибираємо унікальні комбінації відділів та середніх зарплат, щоб показати середню зарплату для кожного відділу.


# Завдання 3. Покажіть середню зарплату співробітників по кожному відділу за кожний рік

# Спосіб 1

WITH AvgSalaries AS (
    SELECT
        de.dept_no,
        d.dept_name,
        YEAR(s.from_date) AS salary_year,
        AVG(s.salary) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
    GROUP BY de.dept_no, d.dept_name, YEAR(s.from_date)
) -- спершу створюємо спільну таблицю AvgSalaries, де обчислюємо середню зарплату (avg_salary) для кожного відділу (dept_no) за кожний рік (salary_year)

SELECT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year
; -- вибираємо дані з цієї таблиці, щоб показати середню зарплату по відділах за роками


# Спосіб 2 
/* (У цьому запиті використуємо аналітичну функцію AVG() разом із віконною функцією OVER(PARTITION BY de.dept_no, YEAR(s.from_date)), 
 щоб обчислити середню зарплату для кожного відділа (dept_no) і року (salary_year) без використання підзапитів або групування даних.)*/
 
WITH AvgSalaries AS (
    SELECT
        de.dept_no,
        d.dept_name,
        YEAR(s.from_date) AS salary_year,
        s.salary,
        AVG(s.salary) OVER(PARTITION BY de.dept_no, YEAR(s.from_date)) AS avg_salary
    FROM dept_emp AS de
    JOIN departments AS d ON (de.dept_no = d.dept_no)
    JOIN salaries AS s ON (de.emp_no = s.emp_no)
)

SELECT DISTINCT dept_no, dept_name, salary_year, avg_salary
FROM AvgSalaries
ORDER BY dept_no, salary_year
;


# Спосіб 3
SELECT
  YEAR(s.from_date) AS year,
  d.dept_name,
  AVG(s.salary) AS avg_salary
FROM salaries AS s
JOIN dept_emp de ON (s.emp_no = de.emp_no) -- використаємо JOIN для об'єднання таблиць salaries, dept_emp і departments за потрібними полями
JOIN departments d ON (de.dept_no = d.dept_no)
GROUP BY YEAR(s.from_date), d.dept_name
ORDER BY YEAR(s.from_date), d.dept_name
;


# Завдання 4. Покажіть відділи в яких зараз працює більше 15000 співробітників.

# Спосіб 1

WITH count_cte AS (
  SELECT dept_no, COUNT(DISTINCT emp_no) AS count_empl
  FROM dept_emp
  GROUP BY dept_no
) -- обчислюємо кількість співробітників для кожного відділу у підзапиті

SELECT d.dept_no, d.dept_name, c.count_empl
FROM count_cte AS c
JOIN departments d ON (c.dept_no = d.dept_no) -- обчислюємо кількість співробітників для кожного відділу у підзапиті
WHERE c.count_empl > 15000; -- далі ми фільтруємо тільки ті відділи, де кількість співробітників більше 15000


# Спосіб 2
WITH dept_employee_counts AS (
  SELECT
    d.dept_no,
    d.dept_name,
    COUNT(*) AS employee_count
  FROM
    departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
  GROUP BY
    d.dept_no, d.dept_name
)
SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000
;


# Спосіб 3
WITH dept_employee_counts AS (
  SELECT
    d.dept_no,
    d.dept_name,
    COUNT(*) OVER (PARTITION BY d.dept_no) AS employee_count
  FROM
    departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
) -- за допомогою віконної функції COUNT(*) OVER обчислюємо кількість співробітників для кожного відділу
SELECT dept_no, dept_name, employee_count
FROM dept_employee_counts
WHERE employee_count > 15000
; -- Потім ми вибираємо тільки ті рядки, де кількість співробітників більше 15000.


# Спосіб 4 з вікорістання перемінної
-- Встановимо значення змінної для порівняння
SET @employee_threshold = 15000;

-- Знайдемо відділи з більшою кількістю співробітників
SELECT d.dept_no, d.dept_name, COUNT(*) AS employee_count
FROM dept_emp AS de
JOIN departments AS d ON de.dept_no = d.dept_no
GROUP BY d.dept_no, d.dept_name
HAVING employee_count > @employee_threshold;


# Завдання 5. Для менеджера який працює найдовше покажіть його номер, відділ, дату прийому на роботу, прізвище

# Спосіб 1
SELECT dm.emp_no, dm.dept_no, dp.dept_name, e.hire_date, e.last_name
FROM dept_manager AS dm
INNER JOIN employees AS e ON (dm.emp_no = e.emp_no)
LEFT JOIN departments AS dp ON (dm.dept_no = dp.dept_no)
ORDER BY DATEDIFF(dm.to_date, dm.from_date) DESC
LIMIT 1
;


# Спосіб 2
SELECT
    dm.emp_no AS manager_emp_no,
    dm.dept_no,
    DATEDIFF(MAX(dm.to_date), MIN(dm.from_date)) AS experience
FROM dept_manager AS dm
GROUP BY dm.emp_no, dm.dept_no
ORDER BY experience DESC
LIMIT 1;

# Спосіб 3 (за допомогою одного СТЕ)
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(MAX(dm.to_date), MIN(dm.from_date)) AS experience
    FROM dept_manager AS dm
    GROUP BY dm.emp_no, dm.dept_no
) -- для кожного менеджера розраховуємо тривалість його роботи в департаменті

SELECT
    me.manager_emp_no,
    me.dept_no,
    me.experience,
    e.last_name AS manager_last_name,
    d.dept_name
FROM ManagerExperience AS me
INNER JOIN employees AS e ON me.manager_emp_no = e.emp_no
INNER JOIN departments AS d ON me.dept_no = d.dept_no
ORDER BY me.experience DESC
LIMIT 1
; -- вибираємо менеджера з найдовшим досвідом та виводимо його номер, відділ, дату прийому на роботу та прізвище


# Спосіб 4 (вирішення за допопмогою 2х CTE)
WITH ManagerExperience AS (
    SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        DATEDIFF(dm.to_date, dm.from_date) AS experience
    FROM dept_manager AS dm 
), -- розраховуємо досвід менеджерів

LongestManager AS (
    SELECT
        me.manager_emp_no,
        me.dept_no,
        me.experience,
        e.hire_date,
        e.last_name
    FROM ManagerExperience AS me
    JOIN employees AS e ON me.manager_emp_no = e.emp_no
    ORDER BY me.experience DESC
    LIMIT 1
) -- визначаємо менеджера з найдовшим досвідом

SELECT
    lm.manager_emp_no,
    lm.dept_no,
    dp.dept_name,
    lm.hire_date,
    lm.last_name
FROM LongestManager AS lm
LEFT JOIN departments AS dp ON lm.dept_no = dp.dept_no
; -- Остаточний запит виводить інформацію про цього менеджера разом із відділом.


# Завдання 6. Покажіть топ-10 діючих співробітників компанії з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.

WITH Avg_dep_sal AS (
  SELECT de.dept_no, AVG(salary) AS avg_dep_salary
  FROM salaries AS s
  JOIN dept_emp de USING (emp_no)
  WHERE CURDATE() BETWEEN de.from_date AND de.to_date
  GROUP BY de.dept_no
),
	Cur_sal AS (
SELECT emp_no, salary AS current_salary
FROM salaries
WHERE CURDATE() BETWEEN from_date AND to_date
)

SELECT e.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS Full_name, cs.current_salary, adv.avg_dep_salary,
(cs.current_salary - adv.avg_dep_salary) AS diff_sal,
DENSE_RANK() OVER (ORDER BY (cs.current_salary - adv.avg_dep_salary) DESC )  'TOP_10 '
FROM employees AS e
JOIN Cur_sal AS cs USING(emp_no)
JOIN dept_emp AS de ON (e.emp_no = de.emp_no)
JOIN Avg_dep_sal AS adv ON (adv.dept_no = de.dept_no)
ORDER BY diff_sal DESC
LIMIT 10
;


# Завдання 7. Для кожного відділу покажіть другого по порядку менеджера. 
-- Необхідно вивести відділ, прізвище ім’я менеджера, дату прийому на роботу менеджера і дату коли він став менеджером відділу


